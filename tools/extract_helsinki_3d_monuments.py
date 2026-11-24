#!/usr/bin/env python3
"""
Blender 5.3 photogrammetry cleanup, shadow de-lighting, atlas re-bake & export
pipeline for City of Helsinki 3D+ City Reality Mesh monuments (CC BY 4.0).

Reads cached leaf tiles from build/helsinki_3d_cache/<id>/manifest.json (produced
by tools/fetch_helsinki_3d_tiles.py), transforms ECEF/RTC coordinates into local
East-North-Up (ENU) metres centered at each monument's (lat, lon), crops the
monument ROI cleanly, removes floating foliage/pedestrian islands, normalizes
ground base to y = 0.0, decimates to target triangle budget, and exports:
  - Mode "textured": repacks multi-tile photographic textures into a single
    compact 512/1024 px shadow-lifted PNG atlas embedded inside
    assets/landmarks/helsinki_3d/<id>.glb
  - Mode "hybrid": slices at pedestal_cut_m and exports clean UV-mapped
    sculpture geometry into assets/landmarks/helsinki_3d/<id>.glb for
    SculptureKit.stamp_path() over razor-sharp LandmarkMesh granite bases.

Usage:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python tools/extract_helsinki_3d_monuments.py -- [--only id1,id2]
"""

import bpy
import bmesh
import json
import math
import os
import sys
from mathutils import Matrix, Vector

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MANIFEST_PATH = os.path.join(REPO_ROOT, "tools", "helsinki_3d_monuments.json")
CACHE_ROOT = os.path.join(REPO_ROOT, "build", "helsinki_3d_cache")
OUT_DIR = os.path.join(REPO_ROOT, "assets", "landmarks", "helsinki_3d")


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def parse_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    only = None
    for i, tok in enumerate(argv):
        if tok == "--only" and i + 1 < len(argv):
            only = set(x.strip() for x in argv[i + 1].split(",") if x.strip())
    return only


def col_major_to_matrix(m16):
    return Matrix((
        (m16[0], m16[4], m16[8], m16[12]),
        (m16[1], m16[5], m16[9], m16[13]),
        (m16[2], m16[6], m16[10], m16[14]),
        (m16[3], m16[7], m16[11], m16[15]),
    ))


def ecef_to_enu_matrix(origin_ecef, east, north, up):
    ox, oy, oz = origin_ecef
    ex, ey, ez = east
    nx, ny, nz = north
    ux, uy, uz = up
    # Maps ECEF (X,Y,Z) -> Blender local ENU (x=East, y=North, z=Up).
    # Note: glTF export converts Blender (x, y, z) -> Godot (x=East, y=Up, z=-North=South)!
    rot = Matrix((
        (ex, ey, ez, 0.0),
        (nx, ny, nz, 0.0),
        (ux, uy, uz, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    ))
    trans = Matrix.Translation(Vector((-ox, -oy, -oz)))
    return rot @ trans


def gltf_yup_to_ecef_zup():
    """3D Tiles glTF uses Y-up inside ECEF Z-up tiles: (x, y, z)_gltf -> (x, -z, y)_ecef."""
    return Matrix((
        (1.0, 0.0, 0.0, 0.0),
        (0.0, 0.0, -1.0, 0.0),
        (0.0, 1.0, 0.0, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    ))


def import_tile_in_enu(glb_path, tile_meta, ecef_to_enu):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=glb_path)
    added = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
    if not added:
        return []

    tile_xf = col_major_to_matrix(tile_meta["transform"])
    rtc = tile_meta.get("rtc_center")
    rtc_mat = Matrix.Translation(Vector(rtc)) if rtc else Matrix.Identity(4)

    # Blender's glTF importer already converts glTF Y-up -> Blender Z-up:
    # (x, y, z)_gltf -> (x, -z, y)_blender, which matches ECEF axis order!
    # Therefore each imported vertex in world space is already in tile-local ECEF orientation.
    full_xf = ecef_to_enu @ tile_xf @ rtc_mat

    # Check whether vertices are already near ECEF magnitude (~6.37e6) vs already shifted by RTC
    for obj in added:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

        # Quick sanity test: transform sample vertex; if wildly far (>50 km), try un-swapped Y-up
        if len(obj.data.vertices) > 0:
            v0 = obj.data.vertices[0].co
            p_a = full_xf @ v0
            if p_a.length > 50000.0:
                alt_xf = ecef_to_enu @ tile_xf @ rtc_mat @ gltf_yup_to_ecef_zup()
                p_b = alt_xf @ v0
                if p_b.length < p_a.length:
                    full_xf = alt_xf

        for v in obj.data.vertices:
            v.co = full_xf @ v.co
        obj.data.update()
    return added


def crop_and_clean(obj, radius_m, z_min_rel, z_max_rel, pedestal_cut_m=0.0):
    bm = bmesh.new()
    bm.from_mesh(obj.data)

    # 1. Estimate local ground elevation from outer ring (0.85*r .. 1.35*r)
    ring_zs = []
    for v in bm.verts:
        d = math.hypot(v.co.x, v.co.y)
        if radius_m * 0.85 <= d <= radius_m * 1.35:
            ring_zs.append(v.co.z)
    if not ring_zs:
        ring_zs = [v.co.z for v in bm.verts if math.hypot(v.co.x, v.co.y) <= radius_m * 1.5]
    if not ring_zs:
        bm.free()
        return False, 0.0
    ring_zs.sort()
    z_ground = ring_zs[max(0, int(len(ring_zs) * 0.15))]

    # 2. Delete vertices outside cylindrical ROI + vertical window
    z_lo = z_ground + max(z_min_rel, pedestal_cut_m)
    z_hi = z_ground + z_max_rel
    to_del = []
    for v in bm.verts:
        if math.hypot(v.co.x, v.co.y) > radius_m or v.co.z < z_lo or v.co.z > z_hi:
            to_del.append(v)
    if to_del:
        bmesh.ops.delete(bm, geom=to_del, context="VERTS")

    if len(bm.faces) < 12:
        bm.free()
        return False, z_ground

    # 3. Connected-component filter: keep main monument mass (drop tiny floating foliage/pedestrian scraps)
    visited = set()
    components = []
    for f in bm.faces:
        if f in visited:
            continue
        stack = [f]
        comp = []
        visited.add(f)
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for e in cur.edges:
                for nf in e.link_faces:
                    if nf not in visited:
                        visited.add(nf)
                        stack.append(nf)
        area = sum(fc.calc_area() for fc in comp)
        components.append((area, comp))
    components.sort(key=lambda item: item[0], reverse=True)
    if components:
        main_area = components[0][0]
        drop_faces = []
        for area, comp in components[1:]:
            if area < main_area * 0.08:
                drop_faces.extend(comp)
        if drop_faces:
            bmesh.ops.delete(bm, geom=drop_faces, context="FACES")

    # 4. Shift so min_z = 0.0 and center X/Y around monument centroid
    if len(bm.verts) < 6:
        bm.free()
        return False, z_ground
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    zs = [v.co.z for v in bm.verts]
    cx = 0.5 * (min(xs) + max(xs))
    cy = 0.5 * (min(ys) + max(ys))
    mz = min(zs)
    for v in bm.verts:
        v.co -= Vector((cx, cy, mz))

    # Preserve original photogrammetry outward winding (do NOT recalc_face_normals on open shells!)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return True, z_ground


def lift_baked_shadows(image, shadow_lift=0.14):
    """Subtle shadow-neutralization pass so baked aerial shadows don't double-darken under Godot sun."""
    px = list(image.pixels[:])
    n = len(px)
    for i in range(0, n, 4):
        r, g, b = px[i], px[i + 1], px[i + 2]
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        if lum < 0.45:
            boost = 1.0 + shadow_lift * (1.0 - lum / 0.45)
            px[i] = min(1.0, r * boost + 0.02)
            px[i + 1] = min(1.0, g * boost + 0.02)
            px[i + 2] = min(1.0, b * boost + 0.02)
    image.pixels[:] = px


def rebake_single_atlas(obj, atlas_px=512, name="Atlas"):
    """Bakes multi-tile photogrammetry diffuse textures onto one clean compact PNG atlas."""
    # Ensure Cycles CPU bake
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    scene.cycles.use_denoising = False

    # Duplicate mesh as clean low-poly target with fresh Smart UV Project
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.duplicate()
    target = bpy.context.active_object
    target.name = obj.name + "_Baked"

    # Unwrap target cleanly
    if not target.data.uv_layers:
        target.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Create target image & single clean Principled BSDF material
    img = bpy.data.images.new(name=name, width=atlas_px, height=atlas_px, alpha=False)
    mat = bpy.data.materials.new(name=name + "_Mat")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out_n = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.78
    bsdf.inputs["Metallic"].default_value = 0.05
    tex_n = nt.nodes.new("ShaderNodeTexImage")
    tex_n.image = img
    nt.links.new(tex_n.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out_n.inputs["Surface"])
    nt.nodes.active = tex_n

    target.data.materials.clear()
    target.data.materials.append(mat)

    # Ensure every source material emits its photographic Base Color texture so Cycles EMIT bake
    # captures 100% of the real Helsinki 3D+ photographic color regardless of KHR_materials_unlit!
    for m in obj.data.materials:
        if m is None or not m.use_nodes:
            continue
        snt = m.node_tree
        img_nodes = [n for n in snt.nodes if n.type == "TEX_IMAGE" and n.image is not None]
        out_nodes = [n for n in snt.nodes if n.type == "OUTPUT_MATERIAL"]
        if img_nodes and out_nodes:
            em = snt.nodes.new("ShaderNodeEmission")
            em.inputs["Strength"].default_value = 1.0
            snt.links.new(img_nodes[0].outputs["Color"], em.inputs["Color"])
            snt.links.new(em.outputs["Emission"], out_nodes[0].inputs["Surface"])

    # Bake Emission (exact raw photographic albedo!)
    scene.render.bake.use_selected_to_active = True
    scene.render.bake.cage_extrusion = 0.12
    scene.render.bake.margin = 4

    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.bake(type="EMIT")

    lift_baked_shadows(img, shadow_lift=0.14)
    img.pack()

    # Remove source high-poly & return baked target
    bpy.data.objects.remove(obj, do_unlink=True)
    return target


def process_monument(mon):
    mid = mon["id"]
    m_dir = os.path.join(CACHE_ROOT, mid)
    m_path = os.path.join(m_dir, "manifest.json")
    if not os.path.exists(m_path):
        print(f"[skip] {mid}: no cached manifest at {m_path}", flush=True)
        return False

    with open(m_path, "r", encoding="utf-8") as f:
        meta = json.load(f)
    if not meta.get("tiles"):
        print(f"[skip] {mid}: 0 tiles in manifest", flush=True)
        return False

    clear_scene()
    ecef_to_enu = ecef_to_enu_matrix(meta["origin_ecef"], meta["east"], meta["north"], meta["up"])

    imported = []
    for t in meta["tiles"]:
        glb_path = os.path.join(m_dir, t["file"])
        if os.path.exists(glb_path):
            imported.extend(import_tile_in_enu(glb_path, t, ecef_to_enu))

    if not imported:
        print(f"[skip] {mid}: no meshes imported", flush=True)
        return False

    bpy.ops.object.select_all(action="DESELECT")
    for o in imported:
        o.select_set(True)
    bpy.context.view_layer.objects.active = imported[0]
    if len(imported) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = mid

    mode = mon.get("mode", "textured")
    ped_cut = float(mon.get("pedestal_cut_m", 0.0)) if mode == "hybrid" else 0.0
    ok, _zg = crop_and_clean(
        obj,
        radius_m=float(mon["radius_m"]),
        z_min_rel=float(mon.get("z_min_rel", 0.1)),
        z_max_rel=float(mon.get("z_max_rel", 12.0)),
        pedestal_cut_m=ped_cut,
    )
    if not ok:
        print(f"[warn] {mid}: crop yielded empty/insufficient geometry", flush=True)
        return False

    # Decimate cleanly to target triangle budget
    target_tris = int(mon.get("target_tris", 7000))
    tri_count = len(obj.data.polygons)
    if tri_count > target_tris:
        dec = obj.modifiers.new("Decimate", "DECIMATE")
        dec.ratio = max(0.03, float(target_tris) / float(tri_count))
        bpy.ops.object.modifier_apply(modifier=dec.name)

    obj.data.polygons.foreach_set("use_smooth", [True] * len(obj.data.polygons))

    if mode == "textured":
        atlas_px = int(mon.get("atlas_px", 512))
        obj = rebake_single_atlas(obj, atlas_px=atlas_px, name=f"{mid}_atlas")
        export_mats = "EXPORT"
    else:
        # Hybrid mode: clean box-projected UVs so LandmarkMaterials bronze/stone shaders tile crisply
        mesh = obj.data
        if not mesh.uv_layers:
            mesh.uv_layers.new(name="UVMap")
        uv_layer = mesh.uv_layers.active.data
        for poly in mesh.polygons:
            n = poly.normal
            ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
            for li in poly.loop_indices:
                co = mesh.vertices[mesh.loops[li].vertex_index].co
                if az >= ax and az >= ay:
                    uv_layer[li].uv = (co.x * 0.4, co.y * 0.4)
                elif ax >= ay:
                    uv_layer[li].uv = (co.y * 0.4, co.z * 0.4)
                else:
                    uv_layer[li].uv = (co.x * 0.4, co.z * 0.4)
        export_mats = "NONE"

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{mid}.glb")
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_normals=True,
        export_texcoords=True,
        export_materials=export_mats,
        export_image_format="AUTO",
    )
    zs = [v.co.z for v in obj.data.vertices]
    h = max(zs) - min(zs) if zs else 0.0
    sz = os.path.getsize(out_path) / 1024.0
    print(f"[h3d] {mid}.glb ({mode}): {len(obj.data.polygons)} tris, h={h:.2f}m, {sz:.1f} KB", flush=True)
    return True


def main():
    only = parse_args()
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    built = 0
    for mon in cfg["monuments"]:
        if only and mon["id"] not in only:
            continue
        if process_monument(mon):
            built += 1
    print(f"=== Helsinki 3D+ Extraction Complete ({built} monuments exported) ===", flush=True)


if __name__ == "__main__":
    main()
