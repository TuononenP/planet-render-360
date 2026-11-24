#!/usr/bin/env python3
"""
Reproducible Blender 5.3 asset pipeline for Planet Render 360 landmark statues.

Converts public-domain / CC0 museum 3D scans (ThreeDScans.com & Poly Haven CC0)
and Blender-sculpted organic companions (winged angel wings, Art Nouveau sea lion)
into lightweight, normalized, smooth-shaded, UV-mapped binary .glb meshes under
assets/statues/.

Coordinate convention (in exported glTF / Godot space):
  - Y-up, resting on y = 0.0
  - Facing +Z (yaw = 0 in SculptureKit)
  - Standing figures normalized to height = 1.0 m
  - Horizontal animals (couchant_lion, sea_lion, rearing_horse) normalized to length = 1.0 m (along Z)

Usage:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/build_statue_assets.py
"""

import bpy
import bmesh
import math
import os
import sys
import urllib.request
import zipfile
from mathutils import Euler, Matrix, Vector

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "statues")
CACHE_DIR = "/tmp/statue_scans_cache"
PREVIEW_DIR = os.environ.get("STATUE_PREVIEW_DIR", "")

SCAN_SOURCES = {
    "eve": (
        "https://threedscans.com/wp-content/uploads/2016/04/Bootleg_Eve.obj.zip",
        "Bootleg_Eve.obj",
    ),
    "zenobia": (
        "https://threedscans.com/wp-content/uploads/2019/03/Hosmer.OBJ.zip",
        "Hosmer.OBJ",
    ),
    "neptune": (
        "https://threedscans.com/wp-content/uploads/2023/04/Neptune_Iustinian_Funie.obj.zip",
        "Neptune_Iustinian_Funie.obj",
    ),
    "triton": (
        "https://threedscans.com/wp-content/uploads/2020/08/200720_Triton-2.OBJ.zip",
        "200720_Triton 2.OBJ",
    ),
    "lion": (
        "https://threedscans.com/wp-content/uploads/2016/02/Lion.stl.zip",
        "Lion.stl",
    ),
    "oceanus": (
        "https://threedscans.com/wp-content/uploads/2020/07/Oceanus100.stl.zip",
        "Oceanus100.stl",
    ),
}


def ensure_scan(key):
    url, filename = SCAN_SOURCES[key]
    sub = os.path.join(CACHE_DIR, key)
    os.makedirs(sub, exist_ok=True)
    target = os.path.join(sub, filename)
    if os.path.exists(target):
        return target
    zpath = os.path.join(CACHE_DIR, f"{key}.zip")
    if not os.path.exists(zpath):
        print(f"[download] {key} <- {url}", flush=True)
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=90) as r, open(zpath, "wb") as f:
            f.write(r.read())
    with zipfile.ZipFile(zpath) as zf:
        zf.extractall(sub)
    return target


def ensure_polyhaven_horse():
    sub = os.path.join(CACHE_DIR, "horse")
    os.makedirs(sub, exist_ok=True)
    out_gltf = os.path.join(sub, "horse_statue_01.gltf")
    if os.path.exists(out_gltf):
        return out_gltf
    import json
    req = urllib.request.Request("https://api.polyhaven.com/files/horse_statue_01", headers={"User-Agent": "Mozilla/5.0"})
    files = json.loads(urllib.request.urlopen(req, timeout=30).read().decode())
    gltf_info = files["gltf"]["1k"]["gltf"]
    urllib.request.urlretrieve(gltf_info["url"], out_gltf)
    for rel, meta in gltf_info.get("include", {}).items():
        if rel.endswith(".bin"):
            dest = os.path.join(sub, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            urllib.request.urlretrieve(meta["url"], dest)
    return out_gltf


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_mesh(path):
    ext = os.path.splitext(path)[1].lower()
    if ext == ".stl":
        bpy.ops.wm.stl_import(filepath=path)
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=path)
    elif ext in (".gltf", ".glb"):
        bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    if obj.data.shape_keys:
        obj.shape_key_clear()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def clean_and_decimate(obj, target_tris, rot_deg, norm_axis="Z"):
    """Rotate to Blender Z-up / -Y front, decimate, normalize scale, smooth & box-UV."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    # Apply orientation fix
    obj.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), "XYZ")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Decimate high-poly scans cleanly
    n_polys = len(obj.data.polygons)
    if n_polys > target_tris:
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = float(target_tris) / float(n_polys)
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)

    # Weld very close vertices & recalculate outward normals
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-5)
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Normalize so standing on Z=0, centered X/Y, and norm_axis dimension == 1.0
    verts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    mn = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
    mx = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
    sz = mx - mn
    dim = sz.z if norm_axis == "Z" else sz.y
    sc = 1.0 / max(dim, 1e-5)
    cx = (mn.x + mx.x) * 0.5
    cy = (mn.y + mx.y) * 0.5
    obj.location = (-cx * sc, -cy * sc, -mn.z * sc)
    obj.scale = (sc, sc, sc)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Smooth shade & generate clean box-projected UVs (world-metre proportional)
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

    # Strip imported materials so LandmarkMaterials controls bronze/marble PBR
    obj.data.materials.clear()
    return obj


def export_glb(obj, name):
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{name}.glb")
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
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
        cam_data = bpy.data.cameras.new("Cam")
        cam = bpy.data.objects.new("Cam", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
        verts = [obj.matrix_world @ v.co for v in obj.data.vertices]
        mid_z = 0.5 * (min(v.z for v in verts) + max(v.z for v in verts))
        for tag, pos in [("front", (0.0, -2.0, mid_z + 0.08)), ("threeq", (1.35, -1.45, mid_z + 0.12))]:
            cam.location = pos
            cam.rotation_euler = (Vector((0.0, 0.0, mid_z)) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(PREVIEW_DIR, f"{name}_{tag}.png")
            bpy.ops.render.render(write_still=True)


def add_feathered_angel_wings(angel_obj):
    """Attach sculpted multi-tier 3D feathered Neo-Classical wings to a unit-height standing figure."""
    bm = bmesh.new()
    for s in (-1.0, 1.0):
        # Build 3 lush overlapping layers of sculpted feathers per wing (coverts, secondaries, primaries)
        layers = [
            # (count, u_min, u_max, length_scale, y_back_offset, thick)
            (15, 0.04, 0.96, 1.00, 0.000, 0.018),  # long sweeping primary & secondary flight feathers
            (12, 0.04, 0.80, 0.64, -0.016, 0.016), # middle secondary coverts (front layer)
            (9,  0.03, 0.58, 0.38, -0.028, 0.014), # upper shoulder coverts
        ]
        for count, u0, u1, l_sc, y_off, thick in layers:
            for k in range(count):
                t = float(k) / float(max(count - 1, 1))
                u = u0 + (u1 - u0) * t
                # Sweeping arch rising from shoulder blades (z=0.70) up to wing crest (z=1.12)
                root_x = s * (0.045 + pow(u, 0.85) * 0.38)
                root_z = 0.70 + math.sin(u * math.pi * 0.68) * 0.42
                root_y = 0.065 + u * 0.16 + math.sin(u * math.pi) * 0.04 + y_off

                # Individual feather length & wide overlapping vane width
                flen = (0.24 + 0.25 * math.sin(u * math.pi * 0.82)) * l_sc
                fwid = (0.046 + 0.018 * math.sin(u * math.pi)) * (0.85 + 0.25 * l_sc)
                # Feather tip sweeps downward and slightly outward/back
                dx = s * (0.03 + 0.10 * u) * l_sc
                dy = 0.05 * l_sc
                dz = -flen

                # Create a 5-ring cambered tapered feather blade
                rings = []
                for j in range(5):
                    v = float(j) / 4.0
                    cx = root_x + dx * v
                    cy = root_y + dy * v + math.sin(v * math.pi) * 0.012
                    cz = root_z + dz * v
                    w = fwid * math.sin(max(0.06, min(0.98, 0.12 + v * 0.86)) * math.pi)
                    th = thick * (1.0 - 0.72 * v)
                    # 6-point cross section around feather quill
                    ring = []
                    for i in range(6):
                        a = 2.0 * math.pi * float(i) / 6.0
                        ring.append(bm.verts.new((
                            cx + s * math.cos(a) * w * 0.5,
                            cy + math.sin(a) * th * 0.5,
                            cz,
                        )))
                    rings.append(ring)
                for j in range(4):
                    r0, r1 = rings[j], rings[j + 1]
                    for i in range(6):
                        inext = (i + 1) % 6
                        try:
                            bm.faces.new((r0[i], r0[inext], r1[inext], r1[i]))
                        except ValueError:
                            pass
                # Cap root and tip
                try:
                    bm.faces.new(rings[0][::-1])
                    bm.faces.new(rings[-1])
                except ValueError:
                    pass

        # Sculpted muscular wing shoulder arch connecting scapulae to feather roots
        arch_rings = []
        for j in range(9):
            u = float(j) / 8.0
            cx = s * (0.035 + pow(u, 0.85) * 0.36)
            cz = 0.70 + math.sin(u * math.pi * 0.68) * 0.42
            cy = 0.065 + u * 0.15 + math.sin(u * math.pi) * 0.04
            rad = (0.034 * (1.0 - 0.65 * u))
            ring = []
            for i in range(10):
                a = 2.0 * math.pi * float(i) / 10.0
                ring.append(bm.verts.new((cx, cy + math.cos(a) * rad, cz + math.sin(a) * rad)))
            arch_rings.append(ring)
        for j in range(8):
            r0, r1 = arch_rings[j], arch_rings[j + 1]
            for i in range(10):
                inext = (i + 1) % 10
                try:
                    bm.faces.new((r0[i], r0[inext], r1[inext], r1[i]))
                except ValueError:
                    pass

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    w_mesh = bpy.data.meshes.new("AngelWings")
    bm.to_mesh(w_mesh)
    bm.free()
    w_obj = bpy.data.objects.new("AngelWings", w_mesh)
    bpy.context.scene.collection.objects.link(w_obj)

    # Subdivide wings once for smooth organic curvature, then join with figure
    bpy.ops.object.select_all(action="DESELECT")
    w_obj.select_set(True)
    bpy.context.view_layer.objects.active = w_obj
    sub = w_obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    bpy.ops.object.modifier_apply(modifier=sub.name)

    angel_obj.select_set(True)
    bpy.context.view_layer.objects.active = angel_obj
    bpy.ops.object.join()
    return angel_obj


def build_sea_lion():
    """High-resolution Catmull-Clark subdivided organic Art Nouveau sea lion (100% connected!)."""
    clear_scene()
    bm = bmesh.new()

    def add_loft(stations, segs=12, cap=True):
        rings = []
        for idx, (pos, rx, rz, pitch_deg, yaw_deg) in enumerate(stations):
            p = Vector(pos)
            rot = Euler((math.radians(pitch_deg), 0.0, math.radians(yaw_deg)), "XYZ").to_matrix()
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * float(i) / float(segs)
                local = Vector((math.cos(a) * rx, 0.0, math.sin(a) * rz))
                ring.append(bm.verts.new(p + rot @ local))
            rings.append(ring)
        for j in range(len(rings) - 1):
            r0, r1 = rings[j], rings[j + 1]
            for i in range(segs):
                inext = (i + 1) % segs
                bm.faces.new((r0[i], r0[inext], r1[inext], r1[i]))
        if cap:
            bm.faces.new(rings[0][::-1])
            bm.faces.new(rings[-1])

    # Main pinniped body: tail root (+Y) -> haunch -> broad chest -> arched neck -> brow -> upper snout (-Y)
    add_loft([
        ((0.0,  0.54, 0.05), 0.055, 0.032, 0.0, 0.0),
        ((0.0,  0.40, 0.09), 0.115, 0.088, 10.0, 0.0),
        ((0.0,  0.22, 0.15), 0.175, 0.148, 14.0, 0.0),
        ((0.0,  0.02, 0.22), 0.215, 0.188, 18.0, 0.0),
        ((0.0, -0.16, 0.30), 0.220, 0.195, 34.0, 0.0), # broad muscular pectoral chest
        ((0.0, -0.28, 0.44), 0.162, 0.155, 50.0, 0.0), # arched neck
        ((0.0, -0.36, 0.59), 0.122, 0.125, 42.0, 0.0), # upper neck
        ((0.0, -0.43, 0.70), 0.112, 0.110, 18.0, 0.0), # cranium & brow
        ((0.0, -0.52, 0.74), 0.078, 0.068, 8.0, 0.0),  # whiskered snout
        ((0.0, -0.59, 0.75), 0.044, 0.038, 0.0, 0.0),  # rounded nose tip
    ], segs=14)

    # Parted open lower jaw tucked cleanly inside throat (no dorsal poke-through)
    add_loft([
        ((0.0, -0.45, 0.64), 0.056, 0.044, 10.0, 0.0),
        ((0.0, -0.51, 0.64), 0.046, 0.032, -6.0, 0.0),
        ((0.0, -0.57, 0.65), 0.030, 0.020, -4.0, 0.0),
    ], segs=10)

    # Deeply rooted muscular fore-flippers, bilobed hind-flippers, brow/eyes & ear pinnae
    for s in (-1.0, 1.0):
        # Fore-flipper starting deep inside pectoral chest -> broad webbed paddle gripping granite
        add_loft([
            ((s * 0.10, -0.14, 0.24), 0.095, 0.115, 0.0, s * 65.0),
            ((s * 0.22, -0.17, 0.15), 0.088, 0.068, 0.0, s * 78.0),
            ((s * 0.35, -0.15, 0.06), 0.105, 0.032, 0.0, s * 105.0),
            ((s * 0.46, -0.06, 0.03), 0.088, 0.018, 0.0, s * 128.0),
            ((s * 0.50,  0.03, 0.02), 0.042, 0.012, 0.0, s * 145.0),
        ], segs=10)
        # Hind-flipper emerging smoothly from tail root
        add_loft([
            ((s * 0.02, 0.49, 0.05), 0.055, 0.034, 0.0, s * 18.0),
            ((s * 0.11, 0.60, 0.035), 0.072, 0.024, 0.0, s * 28.0),
            ((s * 0.18, 0.72, 0.022), 0.058, 0.015, 0.0, s * 32.0),
        ], segs=10)
        # Small sculpted pinniped ear pinna & eye globe
        add_loft([
            ((s * 0.085, -0.39, 0.69), 0.020, 0.014, 0.0, s * 70.0),
            ((s * 0.122, -0.36, 0.67), 0.008, 0.008, 0.0, s * 70.0),
        ], segs=8)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("SeaLion")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("SeaLion", mesh)
    bpy.context.scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    # Catmull-Clark level 2 -> silky-smooth anatomical bronze surface
    sub = obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    sub.render_levels = 2
    bpy.ops.object.modifier_apply(modifier=sub.name)

    clean_and_decimate(obj, target_tris=4500, rot_deg=(0.0, 0.0, 0.0), norm_axis="Y")
    export_glb(obj, "sea_lion")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(CACHE_DIR, exist_ok=True)

    # 1. Contrapposto Nude (Havis Amanda solo hero) <- Standing Contrapposto Eve
    clear_scene()
    obj = import_mesh(ensure_scan("eve"))
    clean_and_decimate(obj, target_tris=9500, rot_deg=(-90.0, 0.0, 0.0), norm_axis="Z")
    export_glb(obj, "contrapposto_nude")

    # 2. Classical Draped Figure (multi-instance safe) <- Zenobia in Chains (Harriet Hosmer)
    clear_scene()
    obj = import_mesh(ensure_scan("zenobia"))
    clean_and_decimate(obj, target_tris=3600, rot_deg=(-90.0, 0.0, 180.0), norm_axis="Z")
    export_glb(obj, "classical_draped")

    # 3. Winged Angel (Bethesda solo hero) <- Zenobia + Blender-sculpted lush feathered wings
    clear_scene()
    obj = import_mesh(ensure_scan("zenobia"))
    clean_and_decimate(obj, target_tris=6500, rot_deg=(-90.0, 0.0, 180.0), norm_axis="Z")
    obj = add_feathered_angel_wings(obj)
    clean_and_decimate(obj, target_tris=11000, rot_deg=(0.0, 0.0, 0.0), norm_axis="Z")
    export_glb(obj, "winged_angel")

    # 4. Classical Hero / Sea God (Trevi Oceanus & raised-arm figures) <- Neptune
    clear_scene()
    obj = import_mesh(ensure_scan("neptune"))
    clean_and_decimate(obj, target_tris=5200, rot_deg=(-90.0, 0.0, 180.0), norm_axis="Z")
    export_glb(obj, "classical_hero")

    # 5. Baroque Triton blowing conch (multi-instance safe) <- Triton (Ferdinandeum Innsbruck)
    clear_scene()
    obj = import_mesh(ensure_scan("triton"))
    clean_and_decimate(obj, target_tris=4500, rot_deg=(180.0, 0.0, 0.0), norm_axis="Z")
    export_glb(obj, "triton_conch")

    # 6. Baroque River God with water urn <- Oceanus (Ferdinandeum Innsbruck)
    clear_scene()
    obj = import_mesh(ensure_scan("oceanus"))
    clean_and_decimate(obj, target_tris=4800, rot_deg=(-90.0, 0.0, 0.0), norm_axis="Z")
    export_glb(obj, "river_god")

    # 7. Couchant / Seated Lion (Trafalgar Square, Popolo, Navona) <- Lion (normalized by height Z=1)
    clear_scene()
    obj = import_mesh(ensure_scan("lion"))
    clean_and_decimate(obj, target_tris=5200, rot_deg=(180.0, 0.0, -90.0), norm_axis="Z")
    export_glb(obj, "couchant_lion")

    # 8. Rearing Horse (Trevi, Navona, Equestrian) <- Poly Haven CC0 Horse Statue 01 (normalized by height Z=1)
    clear_scene()
    obj = import_mesh(ensure_polyhaven_horse())
    clean_and_decimate(obj, target_tris=5200, rot_deg=(0.0, 0.0, 90.0), norm_axis="Z")
    export_glb(obj, "rearing_horse")

    # 9. Organic Catmull-Clark Sculpted Sea Lion (Havis Amanda rim pedestals)
    build_sea_lion()

    print("ALL STATUE GLB ASSETS BUILT SUCCESSFULLY", flush=True)


if __name__ == "__main__":
    main()
