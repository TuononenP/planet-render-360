#!/usr/bin/env python3
"""
Builds the real laser-scanned Havis Amanda bronze figure & sea lion .glb assets
(from Finnish Geospatial Research Institute / Aalto University, Zenodo 3768777, CC-BY-4.0)
and the sculpted craggy Baroque travertine reef for Trevi Fountain (CC0) in Blender 5.3.
"""

import bpy
import bmesh
import math
import os
from mathutils import Euler, Vector, noise

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "statues")
HAVIS_FBX = "/tmp/statue_scans_cache/havis_amanda/HavisAmanda.fbx"
PREVIEW_DIR = os.environ.get("STATUE_PREVIEW_DIR", "")


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def finalize_and_export(obj, name, target_tris, rot_deg=(0.0, 0.0, 0.0), norm_axis="Z", keep_world_scale=False):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    if any(abs(a) > 1e-4 for a in rot_deg):
        obj.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), "XYZ")
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    n_polys = len(obj.data.polygons)
    if n_polys > target_tris:
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = float(target_tris) / float(n_polys)
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)

    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-4)
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")

    verts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    mn = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
    mx = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
    sz = mx - mn
    cx, cy = (mn.x + mx.x) * 0.5, (mn.y + mx.y) * 0.5
    if keep_world_scale:
        obj.location = (-cx, -cy, -mn.z)
    else:
        dim = sz.z if norm_axis == "Z" else sz.y
        sc = 1.0 / max(dim, 1e-5)
        obj.location = (-cx * sc, -cy * sc, -mn.z * sc)
        obj.scale = (sc, sc, sc)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    mesh = obj.data
    mesh.polygons.foreach_set("use_smooth", [True] * len(mesh.polygons))
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv_layer = mesh.uv_layers.active.data
    for poly in mesh.polygons:
        n = poly.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for li in poly.loop_indices:
            co = mesh.vertices[mesh.loops[li].vertex_index].co
            if az >= ax and az >= ay:
                uv_layer[li].uv = (co.x, co.y)
            elif ax >= ay:
                uv_layer[li].uv = (co.y, co.z)
            else:
                uv_layer[li].uv = (co.x, co.z)
    obj.data.materials.clear()

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{name}.glb")
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_normals=True,
        export_texcoords=True,
        export_materials="NONE",
        export_apply=True,
    )
    kb = os.path.getsize(out_path) // 1024
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    print(f"[export] {name}.glb -> {tris} tris, {kb} KB", flush=True)

    if PREVIEW_DIR:
        os.makedirs(PREVIEW_DIR, exist_ok=True)
        scene = bpy.context.scene
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.render.resolution_x = 512
        scene.render.resolution_y = 512
        cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
        scene.collection.objects.link(cam)
        scene.camera = cam
        verts = [obj.matrix_world @ v.co for v in obj.data.vertices]
        mx_d = max(
            max(v.x for v in verts) - min(v.x for v in verts),
            max(v.y for v in verts) - min(v.y for v in verts),
            max(v.z for v in verts) - min(v.z for v in verts),
            0.1,
        )
        mid_z = 0.5 * (min(v.z for v in verts) + max(v.z for v in verts))
        for tag, pos in [("front", (0.0, -mx_d * 2.1, mid_z + mx_d * 0.15)),
                         ("side", (mx_d * 1.6, -mx_d * 1.4, mid_z + mx_d * 0.2))]:
            cam.location = pos
            cam.rotation_euler = (Vector((0.0, 0.0, mid_z)) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(PREVIEW_DIR, f"{name}_{tag}.png")
            bpy.ops.render.render(write_still=True)


def extract_havis_amanda():
    """Crop the real mermaid + 4 bronze fish and one real bronze sea lion from the Helsinki laser scan."""
    # 1. Real Havis Amanda bronze mermaid + 4 spouting sea-fish (z >= 2.70 m above scan base, r <= 1.25 m)
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=HAVIS_FBX)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    verts = [v.co for v in obj.data.vertices]
    zmin = min(v.z for v in verts)
    cx = 0.5 * (min(v.x for v in verts) + max(v.x for v in verts))
    cy = 0.5 * (min(v.y for v in verts) + max(v.y for v in verts))

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    del_verts = [v for v in bm.verts if (v.co.z - zmin) < 2.66 or math.hypot(v.co.x - cx, v.co.y - cy) > 1.25]
    bmesh.ops.delete(bm, geom=del_verts, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()

    # Keep only largest connected island so no floating stray triangles remain
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    # Find highest vertex (crown of Amanda's head) and select linked
    top_idx = max(range(len(obj.data.vertices)), key=lambda i: obj.data.vertices[i].co.z)
    obj.data.vertices[top_idx].select = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_linked()
    bpy.ops.mesh.select_all(action="INVERT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")

    finalize_and_export(obj, "havis_amanda_figure", target_tris=12000, rot_deg=(0.0, 0.0, 0.0), norm_axis="Z")

    # 2. One REAL Ville Vallgren bronze sea lion from the +45 deg rim pedestal
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=HAVIS_FBX)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    del_verts = []
    for v in bm.verts:
        h = v.co.z - zmin
        dx, dy = v.co.x - cx, v.co.y - cy
        r = math.hypot(dx, dy)
        ang = math.degrees(math.atan2(dy, dx))
        # Keep the sea lion at angle ~45 deg above its granite plinth top (h >= 1.16 m)
        if not (1.16 <= h <= 2.35 and 4.1 <= r <= 6.2 and 25.0 <= ang <= 65.0):
            del_verts.append(v)
    bmesh.ops.delete(bm, geom=del_verts, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()

    # Keep only largest connected island (the sea lion itself)
    top_idx = max(range(len(obj.data.vertices)), key=lambda i: obj.data.vertices[i].co.z)
    obj.data.vertices[top_idx].select = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_linked()
    bpy.ops.mesh.select_all(action="INVERT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")

    # The +45 deg sea lion faces INWARD toward (-cos45, -sin45); rotate +45 deg around Z
    # so it faces exact -Y in Blender (= +Z forward in Godot!).
    finalize_and_export(obj, "sea_lion", target_tris=6000, rot_deg=(0.0, 0.0, 45.0), norm_axis="Y")


def build_trevi_reef():
    """Sculpts a craggy, stratified Baroque Roman travertine reef for Trevi Fountain.
    Keeps flat-topped rocky ledges at y = 2.15 m for the horses & Tritons so ZERO statues are buried!"""
    clear_scene()
    bm = bmesh.new()

    def add_crag(center, size, seed, flat_top=False):
        ret = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0)
        cx, cy, cz = center
        sx, sy, sz = size
        for v in ret["verts"]:
            p = v.co.copy()
            # Stratified horizontal travertine cliff ledges + sharp angular fracture planes
            n1 = noise.noise(Vector((p.x * 1.9 + seed, p.y * 1.9 - seed, p.z * 3.8)))
            n2 = noise.noise(Vector((p.x * 4.2 - seed, p.y * 4.2 + seed, p.z * 5.2)))
            terracing = 0.08 * math.sin(p.z * 11.0 + n1 * 2.0)
            disp = 1.0 + 0.24 * n1 + 0.11 * n2 + terracing
            x = cx + p.x * sx * disp
            y = cy + p.y * sy * disp
            # Only upper hemisphere rises above base; clamp bottom to z = 0
            z_raw = cz + p.z * sz * (0.95 + 0.22 * n1 + 0.08 * n2)
            if flat_top and z_raw > cz + sz * 0.78:
                z_raw = cz + sz * 0.78 + (z_raw - (cz + sz * 0.78)) * 0.15
            z = max(0.0, z_raw)
            v.co = Vector((x, y, z))

    # Blender coords: X = left/right (-22..+22 m), Y = depth (-Y is +Z forward toward basin!), Z = height
    # 1. Central stepped travertine cliff under Oceanus's shell chariot (rises to Z = 3.85 m)
    add_crag((0.0, 0.8, 0.8), (4.6, 3.2, 3.3), seed=1.1, flat_top=True)
    add_crag((0.0, -1.6, 0.5), (5.2, 2.8, 2.1), seed=2.3, flat_top=True)
    add_crag((-2.8, -0.4, 0.6), (3.4, 2.8, 2.5), seed=3.7, flat_top=True)
    add_crag((2.8, -0.4, 0.6), (3.4, 2.8, 2.5), seed=4.9, flat_top=True)

    # 2. Dedicated flat-topped craggy rock shelves at exact Z = 2.05 m under the two rearing sea-horses
    # and two Tritons (at X = +-4.5..+-8.5, Y = -3.4..-4.2 -> Godot Z = f + 8.6..9.4 m)
    for s in (-1.0, 1.0):
        add_crag((s * 5.0, -2.6, 0.4), (3.8, 3.2, 2.15), seed=10.1 + s * 2.0, flat_top=True)
        add_crag((s * 8.4, -2.4, 0.35), (3.6, 3.0, 2.10), seed=14.5 + s * 3.0, flat_top=True)
        # Stepped outer cascades & craggy wing boulders meeting Palazzo Poli rustication
        add_crag((s * 12.6, -1.4, 0.3), (4.2, 3.4, 2.25), seed=21.2 + s * 1.7, flat_top=False)
        add_crag((s * 16.8, -0.6, 0.25), (4.0, 3.2, 2.05), seed=27.8 + s * 2.4, flat_top=False)
        add_crag((s * 20.4,  0.4, 0.2), (3.6, 2.8, 1.85), seed=33.1 + s * 1.3, flat_top=False)
        # Low rocky shoreline boulders splashing at the waterline
        add_crag((s * 3.2, -4.6, 0.1), (2.4, 1.8, 1.15), seed=41.0 + s, flat_top=False)
        add_crag((s * 9.8, -4.4, 0.1), (2.6, 1.8, 1.05), seed=45.0 + s, flat_top=False)
        add_crag((s * 15.2, -3.5, 0.1), (2.5, 1.6, 0.95), seed=49.0 + s, flat_top=False)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("TreviReef")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("TreviReef", mesh)
    bpy.context.scene.collection.objects.link(obj)
    finalize_and_export(obj, "trevi_reef", target_tris=8500, keep_world_scale=True)


if __name__ == "__main__":
    extract_havis_amanda()
    build_trevi_reef()
    print("HAVIS AMANDA REAL SCAN + TREVI REEF BUILT", flush=True)
