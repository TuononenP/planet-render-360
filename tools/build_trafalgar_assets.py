#!/usr/bin/env python3
"""
Reproducible Blender 5.3 hero sculpt pipeline for Trafalgar Square (London).

Generates normalized, smooth-shaded, UV-mapped binary .glb hero components under
assets/landmarks/trafalgar/:
  - landseer_lion.glb             (length=1.0 m along Z; true reclining Edwin Landseer bronze lion)
  - nelson_statue.glb             (height=1.0 m; Admiral Horatio Nelson in naval cloak & bicorne hat)
  - corinthian_capital_bronze.glb (height=1.0 m; cast-bronze Corinthian capital with acanthus & volutes)
  - nelson_relief_panel.glb       (1.0 x 1.0 face; framed bronze Trafalgar naval battle bas-relief)
  - lutyens_fountain_group.glb    (real metres; radial dolphin/mermaid/triton bronze sculpture cluster)
  - george_iv_equestrian.glb      (height=1.0 m; Francis Chantrey equestrian King George IV)
  - general_plinth_statue.glb     (height=1.0 m; Victorian standing general for SE/SW plinths)
  - fourth_plinth_sculpture.glb   (height=1.0 m; contemporary monumental bronze sculpture for NW plinth)
  - trafalgar_lantern.glb         (height=1.0 m; iconic octagonal Trafalgar Square bronze lamp standard)

Coordinate convention in exported glTF / Godot space:
  - Y-up, resting on y = 0.0
  - Front faces +Z (which is -Y in Blender Z-up space)

Usage:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/build_trafalgar_assets.py
"""

import bpy
import bmesh
import json
import math
import os
import urllib.request
from mathutils import Euler, Matrix, Vector

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "landmarks", "trafalgar")
CACHE_DIR = "/tmp/statue_scans_cache"


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def ensure_polyhaven_horse():
    sub = os.path.join(CACHE_DIR, "horse")
    os.makedirs(sub, exist_ok=True)
    out_gltf = os.path.join(sub, "horse_statue_01.gltf")
    if os.path.exists(out_gltf):
        return out_gltf
    req = urllib.request.Request(
        "https://api.polyhaven.com/files/horse_statue_01",
        headers={"User-Agent": "Mozilla/5.0"},
    )
    files = json.loads(urllib.request.urlopen(req, timeout=30).read().decode())
    gltf_info = files["gltf"]["1k"]["gltf"]
    urllib.request.urlretrieve(gltf_info["url"], out_gltf)
    for rel, meta in gltf_info.get("include", {}).items():
        if rel.endswith(".bin"):
            dest = os.path.join(sub, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            urllib.request.urlretrieve(meta["url"], dest)
    return out_gltf


def join_objects(objs, name="Asset"):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    if obj.data.shape_keys:
        obj.shape_key_clear()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def add_meta_capsule(mball, p0, p1, r0, r1, steps=6, stiffness=2.0):
    v0, v1 = Vector(p0), Vector(p1)
    for i in range(steps):
        t = i / max(steps - 1, 1)
        p = v0.lerp(v1, t)
        r = r0 + (r1 - r0) * t
        el = mball.elements.new(type="BALL")
        el.co = p
        el.radius = r
        el.stiffness = stiffness


def meta_to_mesh(mball_obj, decimate_target=4000, smooth_iters=2):
    bpy.ops.object.select_all(action="DESELECT")
    mball_obj.select_set(True)
    bpy.context.view_layer.objects.active = mball_obj
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.view_layer.objects.active
    if smooth_iters > 0:
        sm = obj.modifiers.new("Smooth", "SMOOTH")
        sm.factor = 0.45
        sm.iterations = smooth_iters
        bpy.ops.object.modifier_apply(modifier=sm.name)
    decimate_to(obj, decimate_target)
    return obj


def decimate_to(obj, target_tris):
    bpy.context.view_layer.objects.active = obj
    tri_count = sum(max(len(p.vertices) - 2, 1) for p in obj.data.polygons)
    if tri_count > target_tris:
        dec = obj.modifiers.new("Decimate", "DECIMATE")
        dec.ratio = max(0.02, float(target_tris) / float(tri_count))
        bpy.ops.object.modifier_apply(modifier=dec.name)


def finish_and_export(obj, filename, norm_mode="height", target_tris=0, smooth_angle_deg=42.0):
    """Normalizes, UVs, shades smooth, and exports .glb (Y-up)."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    if target_tris > 0:
        decimate_to(obj, target_tris)

    # Compute world bounds
    verts = [v.co for v in obj.data.vertices]
    min_x = min(v.x for v in verts)
    max_x = max(v.x for v in verts)
    min_y = min(v.y for v in verts)
    max_y = max(v.y for v in verts)
    min_z = min(v.z for v in verts)
    max_z = max(v.z for v in verts)

    cx = 0.5 * (min_x + max_x)
    cy = 0.5 * (min_y + max_y)
    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z

    if norm_mode == "height":
        s = 1.0 / max(dz, 1e-4)
    elif norm_mode == "length":
        s = 1.0 / max(dy, 1e-4)
    elif norm_mode == "width":
        s = 1.0 / max(dx, 1e-4)
    else:
        s = 1.0

    for v in obj.data.vertices:
        v.co = Vector(((v.co.x - cx) * s, (v.co.y - cy) * s, (v.co.z - min_z) * s))
    obj.data.update()

    # Triangulate & fix normals
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()

    # Smooth shading & box-projected UVs (robust for every geometry)
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

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_normals=True,
        export_texcoords=True,
        export_materials="NONE",
    )
    tris = len(mesh.polygons)
    sz = os.path.getsize(out_path) / 1024.0
    print(f"[trafalgar] {filename}: {tris} tris, {sz:.1f} KB", flush=True)


# ---------------------------------------------------------------------------
# 1. Edwin Landseer Reclining (Couchant) Bronze Lion
# ---------------------------------------------------------------------------
def build_landseer_lion():
    clear_scene()
    mb = bpy.data.metaballs.new("LandseerLionMB")
    mb.resolution = 0.085
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("LandseerLionMB", mb)
    bpy.context.collection.objects.link(mobj)

    # Facing -Y in Blender (+Z in Godot), length ~6.0 m before length=1.0 normalization.
    # Massive reclined torso & broad chest
    add_meta_capsule(mb, (0.0, -0.75, 0.95), (0.0, 0.85, 0.82), 0.78, 0.68, steps=8)
    add_meta_capsule(mb, (0.0, 0.75, 0.78), (0.0, 1.95, 0.64), 0.68, 0.56, steps=6)
    # Muscular shoulders & raised chest
    add_meta_capsule(mb, (-0.36, -0.95, 1.05), (0.36, -0.95, 1.05), 0.64, 0.64, steps=5)
    add_meta_capsule(mb, (0.0, -1.15, 1.25), (0.0, -1.35, 1.82), 0.74, 0.66, steps=6)

    # Iconic Landseer outstretched parallel forelegs & monumental paws resting flat on plinth
    for sx in (-1.0, 1.0):
        # Upper arm -> elbow -> forearm -> massive paw reaching -Y
        add_meta_capsule(mb, (sx * 0.52, -0.95, 0.96), (sx * 0.50, -1.55, 0.42), 0.36, 0.28, steps=6)
        add_meta_capsule(mb, (sx * 0.50, -1.55, 0.34), (sx * 0.48, -2.85, 0.24), 0.28, 0.25, steps=8)
        # Wide sculpted paw with toes
        add_meta_capsule(mb, (sx * 0.48, -2.82, 0.22), (sx * 0.48, -3.22, 0.18), 0.28, 0.24, steps=4)
        for toe in (-0.12, 0.0, 0.12):
            el = mb.elements.new(type="BALL")
            el.co = Vector((sx * 0.48 + toe, -3.28, 0.15))
            el.radius = 0.13

        # Tucked reclining hind haunches & thighs
        add_meta_capsule(mb, (sx * 0.48, 1.35, 0.78), (sx * 0.62, 1.85, 0.42), 0.46, 0.36, steps=5)
        add_meta_capsule(mb, (sx * 0.62, 1.75, 0.34), (sx * 0.58, 0.65, 0.22), 0.32, 0.22, steps=6)
        add_meta_capsule(mb, (sx * 0.58, 0.65, 0.20), (sx * 0.60, 0.15, 0.18), 0.24, 0.20, steps=4)

    # Proud raised head, broad muzzle, brow ridge, jaw & ears
    add_meta_capsule(mb, (0.0, -1.45, 1.98), (0.0, -1.95, 2.02), 0.52, 0.38, steps=6)
    add_meta_capsule(mb, (0.0, -1.92, 1.92), (0.0, -2.35, 1.82), 0.34, 0.25, steps=5)  # snout
    add_meta_capsule(mb, (0.0, -1.95, 1.72), (0.0, -2.28, 1.66), 0.24, 0.18, steps=4)  # lower jaw
    for sx in (-1.0, 1.0):
        # Brow ridge & cheek
        el = mb.elements.new(type="BALL")
        el.co = Vector((sx * 0.22, -1.98, 2.12))
        el.radius = 0.17
        # Rounded ears tucked into mane
        el = mb.elements.new(type="BALL")
        el.co = Vector((sx * 0.34, -1.55, 2.34))
        el.radius = 0.15

    # Rich layered Victorian bronze mane locks flowing over shoulders & chest
    for ring_i, (y_off, z_off, rad, n_locks, r_lock) in enumerate([
        (-1.55, 2.02, 0.52, 12, 0.24),
        (-1.25, 1.78, 0.66, 14, 0.29),
        (-0.92, 1.48, 0.74, 14, 0.32),
        (-0.62, 1.28, 0.66, 10, 0.28),
    ]):
        for k in range(n_locks):
            ang = 2.0 * math.pi * k / n_locks + ring_i * 0.25
            if math.sin(ang) < -0.55 and ring_i == 0:
                continue  # keep face clear
            el = mb.elements.new(type="BALL")
            el.co = Vector((math.cos(ang) * rad, y_off + math.sin(ang) * 0.14, z_off + math.sin(ang) * rad * 0.78))
            el.radius = r_lock

    # Long tail curling cleanly around right flank onto the plinth
    tail_pts = [
        (0.0, 2.15, 0.65),
        (0.45, 2.28, 0.42),
        (0.78, 1.95, 0.22),
        (0.84, 1.25, 0.17),
        (0.80, 0.55, 0.16),
    ]
    for i in range(len(tail_pts) - 1):
        add_meta_capsule(mb, tail_pts[i], tail_pts[i + 1], 0.14, 0.12, steps=5)
    el = mb.elements.new(type="BALL")
    el.co = Vector((0.79, 0.42, 0.17))
    el.radius = 0.20  # tail tuft

    obj = meta_to_mesh(mobj, decimate_target=4200, smooth_iters=2)

    # Flatten underside cleanly at z_min + 0.04 so paws & belly sit flush on the plinth
    min_z = min(v.co.z for v in obj.data.vertices)
    cut_z = min_z + 0.05
    for v in obj.data.vertices:
        if v.co.z < cut_z:
            v.co.z = cut_z
    obj.data.update()

    finish_and_export(obj, "landseer_lion.glb", norm_mode="length")


# ---------------------------------------------------------------------------
# 2. Admiral Horatio Nelson (Craigleith Sandstone, 5.5 m atop Column)
# ---------------------------------------------------------------------------
def build_nelson_statue():
    clear_scene()
    mb = bpy.data.metaballs.new("NelsonMB")
    mb.resolution = 0.055
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("NelsonMB", mb)
    bpy.context.collection.objects.link(mobj)

    # Standing naval officer facing -Y, height ~5.5 m before normalization
    # Plinth foot base
    add_meta_capsule(mb, (-0.42, 0.0, 0.18), (0.42, 0.0, 0.18), 0.36, 0.36, steps=5)
    # Coiled mooring rope support behind right leg (iconic real detail)
    for k in range(5):
        z = 0.28 + k * 0.22
        add_meta_capsule(mb, (0.28, 0.32, z), (0.58, 0.26, z), 0.18, 0.18, steps=4)

    # Legs in naval breeches & boots (contrapposto)
    add_meta_capsule(mb, (-0.24, -0.06, 0.25), (-0.22, -0.02, 1.45), 0.21, 0.24, steps=6)
    add_meta_capsule(mb, (-0.22, -0.02, 1.45), (-0.20, 0.02, 2.55), 0.26, 0.30, steps=6)
    add_meta_capsule(mb, (0.24, 0.08, 0.25), (0.26, 0.04, 1.45), 0.21, 0.24, steps=6)
    add_meta_capsule(mb, (0.26, 0.04, 1.45), (0.20, 0.02, 2.55), 0.26, 0.30, steps=6)

    # Naval frock coat & torso
    add_meta_capsule(mb, (0.0, 0.0, 2.45), (0.0, -0.04, 4.05), 0.44, 0.52, steps=8)
    # Coat skirts flaring slightly at hips
    add_meta_capsule(mb, (-0.34, 0.14, 1.75), (0.34, 0.14, 1.75), 0.32, 0.32, steps=5)
    add_meta_capsule(mb, (-0.36, 0.10, 2.35), (0.36, 0.10, 2.35), 0.36, 0.36, steps=5)

    # Flowing boat-cloak draped over left shoulder and cascading down back
    add_meta_capsule(mb, (-0.42, 0.05, 4.15), (-0.52, 0.22, 1.35), 0.34, 0.42, steps=10)
    add_meta_capsule(mb, (-0.18, 0.26, 4.05), (-0.22, 0.36, 1.15), 0.34, 0.44, steps=10)
    add_meta_capsule(mb, (0.20, 0.24, 4.00), (0.18, 0.32, 1.55), 0.32, 0.38, steps=8)

    # Left arm resting on sword hilt at left hip
    add_meta_capsule(mb, (-0.54, -0.02, 3.92), (-0.64, -0.14, 3.05), 0.20, 0.17, steps=5)
    add_meta_capsule(mb, (-0.64, -0.14, 3.05), (-0.44, -0.34, 2.65), 0.16, 0.14, steps=5)
    # Sword scabbard angled down-back
    add_meta_capsule(mb, (-0.48, -0.25, 2.60), (-0.68, 0.45, 0.95), 0.09, 0.06, steps=7)

    # Pinned-up empty right sleeve across chest (Nelson's hallmark silhouette!)
    add_meta_capsule(mb, (0.52, -0.02, 3.92), (0.50, -0.18, 3.35), 0.20, 0.16, steps=5)
    add_meta_capsule(mb, (0.50, -0.18, 3.35), (0.16, -0.34, 3.32), 0.15, 0.11, steps=4)

    # Neck, head & iconic fore-and-aft naval bicorne hat
    add_meta_capsule(mb, (0.0, -0.05, 4.18), (0.0, -0.06, 4.48), 0.18, 0.17, steps=3)
    add_meta_capsule(mb, (0.0, -0.08, 4.55), (0.0, -0.10, 4.92), 0.26, 0.24, steps=4)
    # Bicorne hat (wide crescent peak fore-and-aft along X, tall crest)
    add_meta_capsule(mb, (-0.48, -0.08, 5.02), (0.48, -0.08, 5.02), 0.18, 0.18, steps=7)
    add_meta_capsule(mb, (-0.28, -0.08, 5.26), (0.28, -0.08, 5.26), 0.22, 0.22, steps=5)

    obj = meta_to_mesh(mobj, decimate_target=3200, smooth_iters=2)
    finish_and_export(obj, "nelson_statue.glb", norm_mode="height")


# ---------------------------------------------------------------------------
# 3. Cast-Bronze Corinthian Capital (Acanthus Leaves + Volutes + Abacus)
# ---------------------------------------------------------------------------
def build_corinthian_capital():
    clear_scene()
    parts = []

    # Astragal neck ring & flared kalathos bell (h = 2.8 m before norm)
    bm = bmesh.new()
    rings = [
        (0.0, 1.00), (0.14, 1.08), (0.26, 0.98),
        (0.95, 1.06), (1.75, 1.24), (2.35, 1.48), (2.52, 1.54),
    ]
    segs = 24
    prev = None
    for z, r in rings:
        ring_v = [bm.verts.new((math.cos(2 * math.pi * i / segs) * r,
                                math.sin(2 * math.pi * i / segs) * r, z)) for i in range(segs)]
        if prev:
            for i in range(segs):
                j = (i + 1) % segs
                bm.faces.new((prev[i], prev[j], ring_v[j], ring_v[i]))
        prev = ring_v
    bmesh.ops.contextual_create(bm, geom=prev)
    bell_mesh = bpy.data.meshes.new("Bell")
    bm.to_mesh(bell_mesh)
    bm.free()
    bell = bpy.data.objects.new("Bell", bell_mesh)
    bpy.context.collection.objects.link(bell)
    parts.append(bell)

    # Two staggered tiers of 8 sculpted curled acanthus leaves
    for tier, (z0, h, r_base, r_tip, n_leaves, phase) in enumerate([
        (0.18, 1.25, 1.04, 1.38, 8, 0.0),
        (0.85, 1.48, 1.15, 1.62, 8, math.pi / 8.0),
    ]):
        for k in range(n_leaves):
            ang = 2.0 * math.pi * k / n_leaves + phase
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            leaf = bpy.context.active_object
            # Sculpt curved acanthus leaf profile in local coords
            bm_l = bmesh.new()
            bmesh.ops.create_grid(bm_l, x_segments=4, y_segments=6, size=0.5)
            for v in bm_l.verts:
                u = v.co.x * 2.0  # -1..1 width
                t = (v.co.y + 0.5)  # 0..1 height
                width = (0.38 if tier == 0 else 0.42) * math.sin(max(0.08, t * 0.92) * math.pi)
                curl = 0.28 * (t ** 2.2) - 0.14 * max(0.0, t - 0.72) ** 2 * 10.0
                rib = 0.07 * math.cos(u * math.pi * 0.5) * (1.0 - abs(u) * 0.3)
                lx = u * width
                ly = r_base + (r_tip - r_base) * (t ** 1.3) + curl + rib
                lz = z0 + t * h
                v.co = Vector((lx, ly, lz))
            bmesh.ops.solidify(bm_l, geom=bm_l.faces[:], thickness=0.09)
            bm_l.to_mesh(leaf.data)
            bm_l.free()
            leaf.rotation_euler = Euler((0.0, 0.0, ang), "XYZ")
            parts.append(leaf)

    # Four pairs of corner volute scrolls supporting the abacus corners
    for k in range(4):
        ang = math.pi * 0.25 + k * math.pi * 0.5
        for side in (-1.0, 1.0):
            bpy.ops.mesh.primitive_torus_add(
                major_radius=0.26, minor_radius=0.095,
                major_segments=14, minor_segments=8,
            )
            vol = bpy.context.active_object
            d = Vector((math.cos(ang), math.sin(ang), 0.0))
            t_dir = Vector((-d.y, d.x, 0.0))
            vol.location = d * 1.72 + t_dir * (side * 0.22) + Vector((0.0, 0.0, 2.34))
            vol.rotation_euler = Euler((math.pi * 0.5, 0.0, ang + side * 0.35), "XYZ")
            parts.append(vol)

    # Concave-sided moulded Corinthian abacus + 4 central fleuron rosettes
    bm_ab = bmesh.new()
    ab_n = 32
    ab_rings = [(2.50, 1.65), (2.62, 1.78), (2.78, 1.84), (2.86, 1.80)]
    prev = None
    for z, half_w in ab_rings:
        rv = []
        for i in range(ab_n):
            a = 2.0 * math.pi * i / ab_n
            # Square with concave inward bow on each of the 4 faces
            ca, sa = math.cos(a), math.sin(a)
            m = max(abs(ca), abs(sa), 1e-4)
            sx, sy = ca / m, sa / m
            face_pos = min(abs(sx), abs(sy))  # 0 at face centre, 1 at corner
            bow = 1.0 - 0.14 * (1.0 - face_pos ** 2)
            rv.append(bm_ab.verts.new((sx * half_w * bow, sy * half_w * bow, z)))
        if prev:
            for i in range(ab_n):
                j = (i + 1) % ab_n
                bm_ab.faces.new((prev[i], prev[j], rv[j], rv[i]))
        prev = rv
    bmesh.ops.contextual_create(bm_ab, geom=prev)
    ab_mesh = bpy.data.meshes.new("Abacus")
    bm_ab.to_mesh(ab_mesh)
    bm_ab.free()
    ab = bpy.data.objects.new("Abacus", ab_mesh)
    bpy.context.collection.objects.link(ab)
    parts.append(ab)

    # 4 fleuron rosettes centered on each concave abacus face
    for k in range(4):
        ang = k * math.pi * 0.5
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.18)
        fl = bpy.context.active_object
        fl.scale = (1.0, 0.55, 1.0)
        fl.location = Vector((math.cos(ang) * 1.56, math.sin(ang) * 1.56, 2.66))
        fl.rotation_euler = Euler((0.0, 0.0, ang + math.pi * 0.5), "XYZ")
        parts.append(fl)

    obj = join_objects(parts, "CorinthianCapital")
    finish_and_export(obj, "corinthian_capital_bronze.glb", norm_mode="height", target_tris=3600)


# ---------------------------------------------------------------------------
# 4. Framed Bronze Trafalgar Battle Bas-Relief Panel (4 pedestal faces)
# ---------------------------------------------------------------------------
def build_nelson_relief_panel():
    clear_scene()
    parts = []

    # Backplate + deep moulded outer frame (4.2 x 4.2 m before width=1.0 norm, front faces -Y)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    plate = bpy.context.active_object
    plate.scale = (4.2, 0.12, 4.2)
    plate.location = (0.0, 0.0, 2.1)
    parts.append(plate)

    # Raised stepped moulding frame around all 4 edges
    for (loc, sc) in [
        ((0.0, -0.10, 0.16), (4.32, 0.22, 0.32)),
        ((0.0, -0.10, 4.04), (4.32, 0.22, 0.32)),
        ((-2.00, -0.10, 2.10), (0.32, 0.22, 4.00)),
        ((2.00, -0.10, 2.10), (0.32, 0.22, 4.00)),
    ]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        b = bpy.context.active_object
        b.scale = sc
        b.location = loc
        parts.append(b)

    # Sculpted high-relief battle composition (Victory deck, billowing sails, cannon, grouped officers)
    # Central fallen Nelson & supporting officers group
    relief_figures = [
        (-1.25, 1.35, 0.28, 1.55),
        (-0.78, 1.48, 0.30, 1.72),
        (-0.28, 1.25, 0.32, 1.48),
        (0.18, 1.32, 0.34, 1.58),
        (0.68, 1.52, 0.30, 1.76),
        (1.18, 1.40, 0.28, 1.60),
    ]
    for fx, fz, fw, fh in relief_figures:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=1.0)
        fig = bpy.context.active_object
        fig.scale = (fw, 0.14, fh * 0.52)
        fig.location = (fx, -0.14, fz)
        parts.append(fig)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.14)
        hd = bpy.context.active_object
        hd.scale = (1.0, 0.72, 1.1)
        hd.location = (fx, -0.18, fz + fh * 0.56)
        parts.append(hd)

    # Diagonal mast, yardarm & billowing sails in upper relief
    for (loc, sc, rot_y) in [
        ((-0.85, -0.10, 2.95), (1.35, 0.11, 0.85), 0.18),
        ((0.72, -0.10, 3.05), (1.45, 0.11, 0.78), -0.14),
        ((0.0, -0.12, 2.80), (0.14, 0.12, 2.15), 0.08),
        ((-0.25, -0.12, 3.35), (2.85, 0.10, 0.12), -0.16),
    ]:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.5)
        s = bpy.context.active_object
        s.scale = sc
        s.location = loc
        s.rotation_euler = Euler((0.0, rot_y, 0.0), "XYZ")
        parts.append(s)

    # Ship gunwale & cannon barrels in lower foreground
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    deck = bpy.context.active_object
    deck.scale = (3.7, 0.16, 0.34)
    deck.location = (0.0, -0.12, 0.52)
    parts.append(deck)

    obj = join_objects(parts, "NelsonReliefPanel")
    finish_and_export(obj, "nelson_relief_panel.glb", norm_mode="width", target_tris=1800)


# ---------------------------------------------------------------------------
# 5. Lutyens Fountain Sculptural Group (Dolphins, Mermaids & Tritons)
# ---------------------------------------------------------------------------
def build_lutyens_fountain_group():
    clear_scene()
    mb = bpy.data.metaballs.new("LutyensGroupMB")
    mb.resolution = 0.095
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("LutyensGroupMB", mb)
    bpy.context.collection.objects.link(mobj)

    # Built in REAL METRES (norm_mode="none") centered at fountain axis, resting on y=0.0
    # 4 arched leaping bronze dolphins at 0/90/180/270 deg (radius 4.6 m)
    for k in range(4):
        ang = k * math.pi * 0.5
        ca, sa = math.cos(ang), math.sin(ang)
        pts = [
            (ca * 5.6, sa * 5.6, 0.22),
            (ca * 5.2, sa * 5.2, 1.05),
            (ca * 4.4, sa * 4.4, 1.55),
            (ca * 3.6, sa * 3.6, 1.15),
            (ca * 3.2, sa * 3.2, 0.55),
        ]
        radii = [0.22, 0.36, 0.42, 0.34, 0.24]
        for i in range(len(pts) - 1):
            add_meta_capsule(mb, pts[i], pts[i + 1], radii[i], radii[i + 1], steps=5)
        # Flared tail fin
        tx, ty = -sa, ca
        add_meta_capsule(mb, (ca * 5.75 - tx * 0.42, sa * 5.75 - ty * 0.42, 0.32),
                         (ca * 5.75 + tx * 0.42, sa * 5.75 + ty * 0.42, 0.32), 0.16, 0.16, steps=4)

    # 4 Triton & Mermaid figures perched on diagonal inner plinths (45/135/225/315 deg, radius 4.8 m)
    for k in range(4):
        ang = math.pi * 0.25 + k * math.pi * 0.5
        ca, sa = math.cos(ang), math.sin(ang)
        tx, ty = -sa, ca
        bx, by = ca * 4.85, sa * 4.85
        # Curled fish tail base + reclining/rising torso + raised conch-blowing arms
        add_meta_capsule(mb, (bx + ca * 0.65, by + sa * 0.65, 0.22), (bx, by, 0.65), 0.24, 0.36, steps=5)
        add_meta_capsule(mb, (bx, by, 0.65), (bx - ca * 0.18, by - sa * 0.18, 1.58), 0.32, 0.28, steps=6)
        # Head facing inward toward fountain center
        el = mb.elements.new(type="BALL")
        el.co = Vector((bx - ca * 0.22, by - sa * 0.22, 1.88))
        el.radius = 0.22
        # Raised arms holding conch shell
        for s in (-1.0, 1.0):
            add_meta_capsule(
                mb,
                (bx - ca * 0.15 + tx * s * 0.32, by - sa * 0.15 + ty * s * 0.32, 1.50),
                (bx - ca * 0.55 + tx * s * 0.12, by - sa * 0.55 + ty * s * 0.12, 1.82),
                0.14, 0.12, steps=4,
            )

    obj = meta_to_mesh(mobj, decimate_target=4800, smooth_iters=2)
    finish_and_export(obj, "lutyens_fountain_group.glb", norm_mode="none")


# ---------------------------------------------------------------------------
# 6. Francis Chantrey's Equestrian King George IV (NE Plinth)
# ---------------------------------------------------------------------------
def build_george_iv_equestrian():
    clear_scene()
    horse_path = ensure_polyhaven_horse()
    bpy.ops.import_scene.gltf(filepath=horse_path)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    horse = join_objects(objs, "Charger")

    # Slice off the circular tabletop figurine base (lowest 12% of Z)
    zs = [v.co.z for v in horse.data.vertices]
    z_cut = min(zs) + (max(zs) - min(zs)) * 0.125
    bm = bmesh.new()
    bm.from_mesh(horse.data)
    bmesh.ops.bisect_plane(
        bm,
        geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
        plane_co=Vector((0.0, 0.0, z_cut)),
        plane_no=Vector((0.0, 0.0, 1.0)),
        clear_inner=True,
    )
    bm.to_mesh(horse.data)
    bm.free()

    # Normalize horse to ~2.4 m height facing -Y
    vs = [v.co for v in horse.data.vertices]
    cx = 0.5 * (min(v.x for v in vs) + max(v.x for v in vs))
    cy = 0.5 * (min(v.y for v in vs) + max(v.y for v in vs))
    mz = min(v.z for v in vs)
    hz = max(v.z for v in vs) - mz
    sc = 2.4 / max(hz, 1e-4)
    for v in horse.data.vertices:
        v.co = Vector(((v.co.x - cx) * sc, (v.co.y - cy) * sc, (v.co.z - mz) * sc))
    horse.data.update()
    decimate_to(horse, 2800)

    # Sculpt seated King George IV in Roman cloak atop charger
    mb = bpy.data.metaballs.new("RiderMB")
    mb.resolution = 0.065
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("RiderMB", mb)
    bpy.context.collection.objects.link(mobj)

    add_meta_capsule(mb, (0.0, 0.05, 1.55), (0.0, 0.02, 2.55), 0.30, 0.34, steps=6)  # torso
    add_meta_capsule(mb, (0.0, 0.0, 2.62), (0.0, -0.02, 2.95), 0.19, 0.18, steps=4)  # head
    add_meta_capsule(mb, (-0.18, 0.22, 2.48), (-0.12, 0.42, 1.55), 0.26, 0.30, steps=6)  # toga cloak
    for sx in (-1.0, 1.0):
        add_meta_capsule(mb, (sx * 0.34, 0.0, 1.62), (sx * 0.42, -0.14, 0.92), 0.16, 0.13, steps=5)  # legs
        add_meta_capsule(mb, (sx * 0.34, 0.0, 2.38), (sx * 0.32, -0.45, 2.02), 0.13, 0.10, steps=5)  # arms

    rider = meta_to_mesh(mobj, decimate_target=1600, smooth_iters=2)
    combined = join_objects([horse, rider], "GeorgeIVEquestrian")
    finish_and_export(combined, "george_iv_equestrian.glb", norm_mode="height", target_tris=4400)


# ---------------------------------------------------------------------------
# 7. Standing Victorian General (Havelock / Napier SE & SW Plinths)
# ---------------------------------------------------------------------------
def build_general_statue():
    clear_scene()
    mb = bpy.data.metaballs.new("GeneralMB")
    mb.resolution = 0.055
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("GeneralMB", mb)
    bpy.context.collection.objects.link(mobj)

    add_meta_capsule(mb, (-0.30, 0.0, 0.12), (0.30, 0.0, 0.12), 0.24, 0.24, steps=4)
    add_meta_capsule(mb, (-0.18, -0.05, 0.18), (-0.16, 0.0, 1.72), 0.16, 0.20, steps=7)
    add_meta_capsule(mb, (0.18, 0.06, 0.18), (0.16, 0.0, 1.72), 0.16, 0.20, steps=7)
    add_meta_capsule(mb, (0.0, 0.0, 1.65), (0.0, -0.02, 2.85), 0.34, 0.38, steps=7)
    add_meta_capsule(mb, (-0.25, 0.16, 2.80), (-0.28, 0.24, 0.95), 0.26, 0.34, steps=7)  # military cloak
    add_meta_capsule(mb, (-0.38, 0.0, 2.75), (-0.42, -0.22, 1.95), 0.14, 0.11, steps=5)
    add_meta_capsule(mb, (0.38, 0.0, 2.75), (0.48, -0.35, 2.35), 0.14, 0.11, steps=5)  # pointing/telescope arm
    add_meta_capsule(mb, (0.0, -0.02, 2.95), (0.0, -0.04, 3.35), 0.19, 0.18, steps=4)  # head

    obj = meta_to_mesh(mobj, decimate_target=2200, smooth_iters=2)
    finish_and_export(obj, "general_plinth_statue.glb", norm_mode="height")


# ---------------------------------------------------------------------------
# 8. Contemporary Bronze Monumental Sculpture (Fourth Plinth, NW)
# ---------------------------------------------------------------------------
def build_fourth_plinth_sculpture():
    clear_scene()
    parts = []
    # Sculpted monumental organic bronze heraldic vessel / abstract modern commission
    bpy.ops.mesh.primitive_torus_add(major_radius=0.85, minor_radius=0.22, major_segments=24, minor_segments=12)
    t1 = bpy.context.active_object
    t1.rotation_euler = Euler((math.pi * 0.5, 0.0, 0.25), "XYZ")
    t1.location = (0.0, 0.0, 1.45)
    parts.append(t1)

    bpy.ops.mesh.primitive_torus_add(major_radius=0.62, minor_radius=0.18, major_segments=20, minor_segments=12)
    t2 = bpy.context.active_object
    t2.rotation_euler = Euler((math.pi * 0.38, 0.55, -0.45), "XYZ")
    t2.location = (0.0, 0.0, 1.75)
    parts.append(t2)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.62, radius2=0.32, depth=0.75)
    base = bpy.context.active_object
    base.location = (0.0, 0.0, 0.375)
    parts.append(base)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.34)
    core = bpy.context.active_object
    core.location = (0.0, 0.0, 1.55)
    parts.append(core)

    obj = join_objects(parts, "FourthPlinthSculpture")
    finish_and_export(obj, "fourth_plinth_sculpture.glb", norm_mode="height", target_tris=2000)


# ---------------------------------------------------------------------------
# 9. Iconic Trafalgar Square Octagonal Bronze Lamp Standard
# ---------------------------------------------------------------------------
def build_trafalgar_lantern():
    clear_scene()
    parts = []

    # Stepped octagonal base + fluted shaft + scrolled collar + octagonal lantern crown (h = 4.6 m)
    profile = [
        (0.0, 0.42), (0.35, 0.40), (0.45, 0.30), (0.95, 0.26),
        (1.08, 0.20), (3.15, 0.13), (3.30, 0.24), (3.42, 0.18),
        (3.55, 0.36), (3.62, 0.38),
    ]
    bm = bmesh.new()
    segs = 8
    prev = None
    for z, r in profile:
        rv = [bm.verts.new((math.cos(2 * math.pi * i / segs) * r,
                            math.sin(2 * math.pi * i / segs) * r, z)) for i in range(segs)]
        if prev:
            for i in range(segs):
                j = (i + 1) % segs
                bm.faces.new((prev[i], prev[j], rv[j], rv[i]))
        prev = rv
    bmesh.ops.contextual_create(bm, geom=prev)
    sm = bpy.data.meshes.new("LampShaft")
    bm.to_mesh(sm)
    bm.free()
    shaft = bpy.data.objects.new("LampShaft", sm)
    bpy.context.collection.objects.link(shaft)
    parts.append(shaft)

    # 8 slender octagonal lantern ribs + stepped bronze canopy + finial spike
    for k in range(8):
        ang = 2.0 * math.pi * k / 8.0
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.025, depth=0.72)
        rib = bpy.context.active_object
        rib.location = (math.cos(ang) * 0.34, math.sin(ang) * 0.34, 3.96)
        parts.append(rib)

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.44, radius2=0.14, depth=0.36)
    cap = bpy.context.active_object
    cap.location = (0.0, 0.0, 4.46)
    parts.append(cap)

    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.06, radius2=0.01, depth=0.30)
    fin = bpy.context.active_object
    fin.location = (0.0, 0.0, 4.78)
    parts.append(fin)

    obj = join_objects(parts, "TrafalgarLantern")
    finish_and_export(obj, "trafalgar_lantern.glb", norm_mode="height", target_tris=750)


if __name__ == "__main__":
    print("=== Building Trafalgar Square Hero Assets (Blender 5.3) ===", flush=True)
    build_landseer_lion()
    build_nelson_statue()
    build_corinthian_capital()
    build_nelson_relief_panel()
    build_lutyens_fountain_group()
    build_george_iv_equestrian()
    build_general_statue()
    build_fourth_plinth_sculpture()
    build_trafalgar_lantern()
    print("=== Trafalgar Square Hero Assets Complete ===", flush=True)
