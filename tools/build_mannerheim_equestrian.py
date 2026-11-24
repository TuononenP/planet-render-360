#!/usr/bin/env python3
"""
High-precision Blender 5.3 builder for Aimo Tukiainen's Equestrian Statue of
Marshal C. G. E. Mannerheim (1960), Mannerheiminaukio, Helsinki.

Exports `assets/landmarks/helsinki_3d/mannerheim_equestrian_bronze.glb` (4.65 m
bronze height atop the 6.45 m smooth Vehmaa granite ashlar monolith = 11.10 m).
"""

import bpy
import bmesh
import math
import os
import urllib.request
import zipfile
from mathutils import Euler, Matrix, Vector, noise
from mathutils.bvhtree import BVHTree

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_PATH = os.path.join(REPO_ROOT, "assets", "landmarks", "helsinki_3d", "mannerheim_equestrian_bronze.glb")
CACHE_DIR = "/tmp/statue_scans_cache"
WT_CACHE = os.path.join(CACHE_DIR, "_watertight_v2")

GT_HORSE_URL = "https://raw.githubusercontent.com/alecjacobson/common-3d-test-models/master/data/horse.obj"
NAPOLEON_URL = "https://threedscans.com/wp-content/uploads/2018/04/NAPOLEON_fix.OBJ.zip"


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0))) if abs(edge1 - edge0) > 1e-8 else 0.0
    return t * t * (3.0 - 2.0 * t)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def join_objects(objs, name="Part"):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def decimate_to(obj, target_tris):
    bpy.context.view_layer.objects.active = obj
    tri_count = sum(max(len(p.vertices) - 2, 1) for p in obj.data.polygons)
    if tri_count > target_tris:
        dec = obj.modifiers.new("Decimate", "DECIMATE")
        dec.ratio = max(0.005, float(target_tris) / float(tri_count))
        bpy.ops.object.modifier_apply(modifier=dec.name)


def voxel_polish(obj, voxel_size=0.010, smooth_iters=2, smooth_factor=0.42, target_tris=20000):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()

    rem = obj.modifiers.new("VoxelRemesh", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = voxel_size
    rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)

    if smooth_iters > 0:
        sm = obj.modifiers.new("Smooth", "SMOOTH")
        sm.factor = smooth_factor
        sm.iterations = smooth_iters
        bpy.ops.object.modifier_apply(modifier=sm.name)

    if target_tris > 0:
        decimate_to(obj, target_tris)


def ensure_gt_horse():
    os.makedirs(CACHE_DIR, exist_ok=True)
    p = os.path.join(CACHE_DIR, "gt_horse.obj")
    if not os.path.exists(p) or os.path.getsize(p) < 100000:
        req = urllib.request.Request(GT_HORSE_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as r, open(p, "wb") as f:
            f.write(r.read())
    return p


def ensure_watertight_portrait_bust():
    os.makedirs(WT_CACHE, exist_ok=True)
    wt_glb = os.path.join(WT_CACHE, "napoleon_wt24k.glb")
    if os.path.exists(wt_glb) and os.path.getsize(wt_glb) > 50000:
        return wt_glb

    sub = os.path.join(CACHE_DIR, "napoleon")
    os.makedirs(sub, exist_ok=True)
    obj_path = None
    for root, _d, files in os.walk(sub):
        for fn in files:
            if fn.lower().endswith(".obj") and not fn.startswith("."):
                obj_path = os.path.join(root, fn)
                break
    if obj_path is None:
        zpath = os.path.join(CACHE_DIR, "napoleon.zip")
        if not os.path.exists(zpath):
            req = urllib.request.Request(NAPOLEON_URL, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=120) as r, open(zpath, "wb") as f:
                f.write(r.read())
        with zipfile.ZipFile(zpath) as zf:
            zf.extractall(sub)
        for root, _d, files in os.walk(sub):
            for fn in files:
                if fn.lower().endswith(".obj") and not fn.startswith("."):
                    obj_path = os.path.join(root, fn)
                    break

    before = set(bpy.context.scene.objects)
    bpy.ops.wm.obj_import(filepath=obj_path)
    added = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
    raw = join_objects(added, "PortraitRaw")
    raw.rotation_euler = Euler((math.pi * 0.5, 0.0, math.pi * 0.5), "XYZ")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    vs = [v.co for v in raw.data.vertices]
    cx = 0.5 * (min(v.x for v in vs) + max(v.x for v in vs))
    cy = 0.5 * (min(v.y for v in vs) + max(v.y for v in vs))
    mz = min(v.z for v in vs)
    sc = 1.0 / max(max(v.z for v in vs) - mz, 1e-4)
    for v in raw.data.vertices:
        v.co = Vector(((v.co.x - cx) * sc, (v.co.y - cy) * sc, (v.co.z - mz) * sc))
    raw.data.update()
    voxel_polish(raw, voxel_size=0.0042, smooth_iters=1, target_tris=24000)
    bpy.ops.object.select_all(action="DESELECT")
    raw.select_set(True)
    bpy.context.view_layer.objects.active = raw
    bpy.ops.export_scene.gltf(
        filepath=wt_glb, export_format="GLB", use_selection=True,
        export_apply=True, export_normals=True, export_materials="NONE",
    )
    bpy.data.objects.remove(raw, do_unlink=True)
    return wt_glb


def loft_tube_mesh(name, pts, radii_xy, segs=18, cap=True, cloth_fold_amp=0.0):
    bm = bmesh.new()
    n = len(pts)
    vecs = [Vector(p) for p in pts]
    tangs = []
    for i in range(n):
        if i == 0:
            t = vecs[1] - vecs[0]
        elif i == n - 1:
            t = vecs[-1] - vecs[-2]
        else:
            t = vecs[i + 1] - vecs[i - 1]
        tangs.append(t.normalized() if t.length > 1e-6 else Vector((0, 0, 1)))

    sides, norms = [], []
    for i in range(n):
        t = tangs[i]
        if i == 0:
            ref = Vector((1, 0, 0)) if abs(t.x) < 0.85 else Vector((0, 1, 0))
            s = (ref - t * ref.dot(t)).normalized()
        else:
            q = tangs[i - 1].rotation_difference(t)
            s = (q @ sides[i - 1])
            s = (s - t * s.dot(t)).normalized()
        sides.append(s)
        norms.append(t.cross(s).normalized())

    rings = []
    for i in range(n):
        ti = i / max(n - 1, 1)
        rx, ry = radii_xy[i]
        c, s, nm = vecs[i], sides[i], norms[i]
        ring = []
        for k in range(segs):
            a = 2.0 * math.pi * k / segs
            p = c + s * (math.cos(a) * rx) + nm * (math.sin(a) * ry)
            if cloth_fold_amp > 0.0:
                fold = cloth_fold_amp * math.sin(ti * 15.0 + math.cos(a) * 3.0) * math.sin(ti * math.pi)
                fold += cloth_fold_amp * 0.50 * noise.noise(p * 7.5)
                out_dir = (p - c).normalized() if (p - c).length > 1e-5 else s
                p += out_dir * fold
            ring.append(bm.verts.new(p))
        rings.append(ring)

    for i in range(n - 1):
        for k in range(segs):
            nk = (k + 1) % segs
            bm.faces.new((rings[i][k], rings[i][nk], rings[i + 1][nk], rings[i + 1][k]))

    if cap:
        p_start = bm.verts.new(vecs[0] - tangs[0] * (min(radii_xy[0]) * 0.40))
        p_end = bm.verts.new(vecs[-1] + tangs[-1] * (min(radii_xy[-1]) * 0.40))
        for k in range(segs):
            nk = (k + 1) % segs
            bm.faces.new((p_start, rings[0][nk], rings[0][k]))
            bm.faces.new((p_end, rings[-1][k], rings[-1][nk]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    bm.free()
    obj = bpy.data.objects.new(name, m)
    bpy.context.collection.objects.link(obj)
    return obj


# ---------------------------------------------------------------------------
# 1. Thoroughbred Mare "Käthy" (Exact World-Space Neck, Poll & 4-Leg Stride)
# ---------------------------------------------------------------------------
def build_kathy_horse(plinth_top_z=0.14):
    path = ensure_gt_horse()
    before = set(bpy.context.scene.objects)
    bpy.ops.wm.obj_import(filepath=path)
    horse = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = horse
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Proper det=+1 rotation: hooves on Z=0, back +Z, nose -Y, left flank +X
    for v in horse.data.vertices:
        c = v.co.copy()
        v.co = Vector((-c.x, -c.z, -c.y))
    horse.data.update()

    vs = [v.co for v in horse.data.vertices]
    mz = min(v.z for v in vs)
    sc = 3.28 / (max(v.z for v in vs) - mz)
    cy = 0.5 * (min(v.y for v in vs) + max(v.y for v in vs))
    barrel_vs = [v for v in vs if -0.25 < (v.y - cy) * sc < 0.45 and 1.5 < (v.z - mz) * sc < 2.3]
    cx = 0.5 * (min(v.x for v in barrel_vs) + max(v.x for v in barrel_vs))
    y_shift = 0.05
    for v in horse.data.vertices:
        v.co = Vector(((v.co.x - cx) * sc, (v.co.y - cy) * sc + y_shift, (v.co.z - mz) * sc))
    horse.data.update()

    # Stage 1A: Lift neck UPWARD to streamlined ~40-deg cavalry carriage!
    neck_pivot = Vector((0.03, -0.42 + y_shift, 1.90))
    for v in horse.data.vertices:
        p = v.co
        if p.y < (-0.18 + y_shift) and p.z > 1.48:
            wy = smoothstep(-0.18 + y_shift, -0.95 + y_shift, p.y)
            wz = smoothstep(1.48, 2.26, p.z)
            w = max(wy * 0.82, wz)
            rel = p - neck_pivot
            rot = Euler((math.radians(-9.5 * w), 0.0, math.radians(-22.5 * w)), "XYZ").to_matrix()
            v.co = neck_pivot + rot @ rel
    horse.data.update()

    # Stage 1B: Collect Käthy's head "on the bit" at the poll/throatlatch!
    ear_vs_pre = [v.co for v in horse.data.vertices if v.co.z > 3.08]
    ear_top_pre = max(ear_vs_pre, key=lambda v: v.z)
    nose_pre = min([v.co for v in horse.data.vertices if v.co.y < (-1.20 + y_shift) and v.co.z > 2.1], key=lambda v: v.y)
    throat_pivot = Vector((ear_top_pre.x * 0.5, ear_top_pre.y + 0.16, ear_top_pre.z - 0.38))
    res_yaw_deg = math.degrees(math.atan2(nose_pre.x - throat_pivot.x, -(nose_pre.y - throat_pivot.y)))
    yaw_fix_deg = -(res_yaw_deg - 3.5)

    for v in horse.data.vertices:
        p = v.co
        s = -(p.y - (throat_pivot.y + 0.12)) * 0.84 + (p.z - (throat_pivot.z - 0.18)) * 0.54
        if s > 0.0 and p.z > 2.10:
            wh = smoothstep(0.0, 0.40, s)
            rel = p - throat_pivot
            rot = Euler((math.radians(20.0 * wh), 0.0, math.radians(yaw_fix_deg * wh)), "XYZ").to_matrix()
            v.co = throat_pivot + rot @ rel
    horse.data.update()

    # Stage 1C: Deterministic World-Space 4-Leg Lateral Stride (Käthy's iconic tölt / käynti)!
    # Right-hand rule around world +X for downward limb (rel.z = z - pivot.z < 0):
    #   y' = rel.y*cos(a) - rel.z*sin(a) = rel.y*cos(a) + |rel.z|*sin(a)
    #   => NEGATIVE a swings leg FORWARD (-Y)! POSITIVE a swings leg BACKWARD (+Y)!
    def limb_joint(is_fore, is_left, z_target, dz=0.07):
        pts = [
            v.co for v in horse.data.vertices
            if ((v.co.y < (-0.10 + y_shift)) if is_fore else (v.co.y > (0.35 + y_shift)))
            and ((v.co.x > 0.05) if is_left else (v.co.x < -0.05))
            and abs(v.co.z - z_target) < dz
        ]
        n = float(max(len(pts), 1))
        return Vector((sum(q.x for q in pts) / n, sum(q.y for q in pts) / n, sum(q.z for q in pts) / n))

    fl_el = limb_joint(True, True, 1.32)
    fl_kn = limb_joint(True, True, 0.84)
    hl_st = limb_joint(False, True, 1.36)
    hr_st = limb_joint(False, False, 1.36)

    for v in horse.data.vertices:
        p = v.co
        # 1) LEFT FORELEG (+X, fore): extend long & forward (-18 deg at elbow, +11 deg slight knee flex)
        if p.x > 0.05 and p.y < (-0.05 + y_shift) and p.z < 1.48:
            w_up = smoothstep(0.05, 0.18, p.x) * smoothstep(1.46, 1.15, p.z)
            if w_up > 1e-4:
                rot_up = Euler((math.radians(-18.0 * w_up), 0.0, 0.0), "XYZ").to_matrix()
                p1 = fl_el + rot_up @ (p - fl_el)
                kn_moved = fl_el + rot_up @ (fl_kn - fl_el)
                w_lo = w_up * smoothstep(fl_kn.z + 0.10, fl_kn.z - 0.10, p.z)
                if w_lo > 1e-4:
                    rot_lo = Euler((math.radians(11.0 * w_lo), 0.0, 0.0), "XYZ").to_matrix()
                    p1 = kn_moved + rot_lo @ (p1 - kn_moved)
                v.co = p1
                continue

        # 2) LEFT HINDLEG (+X, hind): swing FORWARD (-27 deg around stifle) so HL steps ahead under flank!
        if p.x > 0.04 and p.y > (0.35 + y_shift) and p.z < 1.48:
            w_hl = smoothstep(0.04, 0.18, p.x) * smoothstep(1.46, 1.14, p.z)
            if w_hl > 1e-4:
                rot_hl = Euler((math.radians(-27.0 * w_hl), 0.0, 0.0), "XYZ").to_matrix()
                v.co = hl_st + rot_hl @ (p - hl_st)
                continue

        # 3) RIGHT HINDLEG (-X, hind): swing BACKWARD (+15 deg around stifle) as trailing push-off leg!
        if p.x < -0.04 and p.y > (0.35 + y_shift) and p.z < 1.48:
            w_hr = smoothstep(-0.04, -0.18, p.x) * smoothstep(1.46, 1.14, p.z)
            if w_hr > 1e-4:
                rot_hr = Euler((math.radians(15.0 * w_hr), 0.0, 0.0), "XYZ").to_matrix()
                v.co = hr_st + rot_hr @ (p - hr_st)
                continue
    horse.data.update()

    # Seat FR, HL, and HR hooves solidly onto plinth_top_z, and place FL hoof at exact +7.5 cm hover!
    fr_zs = [v.co.z for v in horse.data.vertices if v.co.x < -0.05 and v.co.y < (-0.05 + y_shift)]
    dz_base = plinth_top_z - min(fr_zs) - 0.005
    for v in horse.data.vertices:
        v.co.z += dz_base

    # Seat HL & HR hooves flush with plinth_top_z
    for is_left in (True, False):
        h_vs = [
            v for v in horse.data.vertices
            if v.co.y > (0.30 + y_shift) and ((v.co.x > 0.04) if is_left else (v.co.x < -0.04)) and v.co.z < 1.15
        ]
        if h_vs:
            corr = (plinth_top_z - 0.004) - min(v.co.z for v in h_vs)
            for v in h_vs:
                v.co.z += corr * smoothstep(1.12, 0.30, v.co.z)

    # Set FL hoof sole to hover cleanly +0.075 m above plinth_top_z!
    fl_vs = [v for v in horse.data.vertices if v.co.x > 0.05 and v.co.y < (-0.25 + y_shift) and v.co.z < 1.18]
    if fl_vs:
        fl_corr = (plinth_top_z + 0.075) - min(v.co.z for v in fl_vs)
        for v in fl_vs:
            v.co.z += fl_corr * smoothstep(1.15, 0.35, v.co.z)
    horse.data.update()

    back_vs = [v.co for v in horse.data.vertices if abs(v.co.x) < 0.10 and (-0.10 + y_shift) < v.co.y < (0.45 + y_shift) and v.co.z > 1.8]
    saddle_z = sum(sorted([v.z for v in back_vs], reverse=True)[:12]) / 12.0
    rump_vs = [v.co for v in horse.data.vertices if abs(v.co.x) < 0.14 and v.co.y > (1.05 + y_shift) and v.co.z > 1.7]
    tail_root = max(rump_vs, key=lambda v: v.y)

    # Neat hogged/cropped cavalry mane crest along the proud neck ridge
    crest_pts, crest_r = [], []
    for k in range(9):
        t = k / 8.0
        yc = (-0.28 + y_shift) - t * 0.92
        slice_vs = [v.co for v in horse.data.vertices if abs(v.co.x) < 0.14 and abs(v.co.y - yc) < 0.08 and v.co.z > 2.3]
        if slice_vs:
            top_v = max(slice_vs, key=lambda v: v.z)
            crest_pts.append((top_v.x, top_v.y, top_v.z + 0.012))
            crest_r.append((0.018 + 0.010 * math.sin(t * math.pi), 0.030))
    horse_parts = [horse]
    if len(crest_pts) >= 4:
        horse_parts.append(loft_tube_mesh("CroppedMane", crest_pts, crest_r, segs=12, cloth_fold_amp=0.002))

    # Full sculpted tail arching gracefully from dock and hanging straight down past hock height
    tx0, ty0, tz0 = tail_root.x, tail_root.y - 0.03, tail_root.z - 0.02
    tail = loft_tube_mesh(
        "KathyTail",
        pts=[
            (tx0, ty0, tz0),
            (tx0, ty0 + 0.16, tz0 - 0.06),
            (tx0, ty0 + 0.24, tz0 - 0.34),
            (tx0, ty0 + 0.25, tz0 - 0.72),
            (tx0, ty0 + 0.21, tz0 - 1.06),
            (tx0, ty0 + 0.17, tz0 - 1.26),
        ],
        radii_xy=[(0.074, 0.074), (0.098, 0.088), (0.116, 0.094), (0.104, 0.084), (0.076, 0.062), (0.025, 0.023)],
        segs=16, cloth_fold_amp=0.005,
    )
    horse_parts.append(tail)

    kathy = join_objects(horse_parts, "KathyBronze")
    voxel_polish(kathy, voxel_size=0.010, smooth_iters=2, smooth_factor=0.45, target_tris=23000)

    ear_vs = [v.co for v in kathy.data.vertices if v.co.z > 3.25]
    ear_top = max(ear_vs, key=lambda v: v.z)
    nose_vs = [v.co for v in kathy.data.vertices if v.co.y < (-1.15 + y_shift) and v.co.z > 2.15]
    nose_tip = min(nose_vs, key=lambda v: v.y - 0.45 * v.z)
    poll_behind_ears = Vector((ear_top.x, ear_top.y + 0.12, ear_top.z - 0.25))

    fl_sole_z = min(v.co.z for v in kathy.data.vertices if v.co.x > 0.08 and v.co.y < (-0.70 + y_shift))
    fl_y = min(v.co.y for v in kathy.data.vertices if v.co.x > 0.08 and v.co.z < 0.45)
    fr_y = min(v.co.y for v in kathy.data.vertices if v.co.x < -0.08 and v.co.z < 0.35)
    hl_y = sum(v.co.y for v in kathy.data.vertices if v.co.x > 0.08 and v.co.y > 0.3 and v.co.z < 0.25) / max(1, len([1 for v in kathy.data.vertices if v.co.x > 0.08 and v.co.y > 0.3 and v.co.z < 0.25]))
    hr_y = sum(v.co.y for v in kathy.data.vertices if v.co.x < -0.08 and v.co.y > 0.3 and v.co.z < 0.25) / max(1, len([1 for v in kathy.data.vertices if v.co.x < -0.08 and v.co.y > 0.3 and v.co.z < 0.25]))

    print(
        f"[kathy-v7] saddle_z={saddle_z:.2f}, ear_top={tuple(round(x,2) for x in ear_top)}, "
        f"nose={tuple(round(x,2) for x in nose_tip)}, fl_hover={(fl_sole_z-plinth_top_z)*100:.1f}cm | "
        f"hooves_y: FL={fl_y:.2f} FR={fr_y:.2f} HL={hl_y:.2f} HR={hr_y:.2f}",
        flush=True,
    )
    return kathy, saddle_z, nose_tip, poll_behind_ears, y_shift


# ---------------------------------------------------------------------------
# 2. Marshal C. G. E. Mannerheim (Anatomical Shoulders, Barrel-Clear Boots & Sabre)
# ---------------------------------------------------------------------------
def build_sculpted_m36_tunic(y_seat, hip_z):
    bm = bmesh.new()
    n_u, n_z = 52, 34
    z_bot = hip_z - 0.24
    z_top = hip_z + 1.32
    grid = []

    for j in range(n_z + 1):
        t = j / n_z
        z = z_bot + t * (z_top - z_bot)
        dz = z - hip_z
        # Natural cavalry S-posture: proud sternum, gently rounded upper thoracic back into collar
        yc = y_seat + 0.032 * math.sin(t * math.pi) - 0.022 * smoothstep(0.45, 0.96, dz) + 0.018 * smoothstep(0.92, 1.22, dz)

        if dz < 0.44:
            u_sk = smoothstep(0.44, -0.24, dz)
            rx = 0.242 + 0.138 * (u_sk ** 0.90)
            ry = 0.192 + 0.118 * (u_sk ** 0.90)
            yc -= 0.04 * u_sk
        elif dz < 0.96:
            u_ch = smoothstep(0.44, 0.92, dz)
            blouse = 0.014 * math.exp(-((dz - 0.50) / 0.055) ** 2)
            rx = 0.242 + 0.115 * u_ch + blouse
            ry = 0.192 + 0.058 * math.sin(u_ch * math.pi * 0.85) + blouse
        elif dz < 1.20:
            # Smooth cosine dome across rounded deltoids & sloping trapezius (ZERO tin-man cylinder rim!)
            u_sh = smoothstep(0.96, 1.20, dz)
            dome = math.cos(u_sh * math.pi * 0.5)
            rx = 0.116 + (0.357 - 0.116) * (dome ** 0.85)
            ry = 0.112 + (0.232 - 0.112) * (dome ** 0.90)
        else:
            rx, ry = 0.115, 0.110

        row = []
        for i in range(n_u):
            a = 2.0 * math.pi * i / n_u
            ca, sa = math.cos(a), math.sin(a)
            # Anatomical pectorals (front -Y) & scapulae (back +Y), soft rounded shoulders
            pec = 0.018 * smoothstep(0.58, 0.92, dz) * (1.0 - smoothstep(0.96, 1.15, dz)) * (max(0.0, -sa) ** 2) * (math.sin(2.0 * a) ** 2)
            skirt_w = smoothstep(0.40, -0.22, dz)
            belt_folds = 0.008 * math.exp(-((dz - 0.52) / 0.10) ** 2) * math.sin(a * 10.0)
            folds = 0.009 * skirt_w * math.sin(a * 8.0 + 0.4) + belt_folds + pec
            # Front tunic overlap placket ridge on chest + open vent below belt
            if abs(ca) < 0.18 and sa < -0.85 and 0.44 < dz < 1.16:
                folds += 0.008
            if sa < -0.82 and dz < 0.36:
                folds -= 0.035 * smoothstep(-0.82, -1.0, sa) * smoothstep(0.36, -0.22, dz)
            x = ca * rx + ca * folds
            y = yc + sa * ry + sa * folds
            z_adj = z + (0.035 * skirt_w * max(0.0, -sa) ** 2)
            row.append(bm.verts.new((x, y, z_adj)))
        grid.append(row)

    for j in range(n_z):
        for i in range(n_u):
            ni = (i + 1) % n_u
            bm.faces.new((grid[j][i], grid[j][ni], grid[j + 1][ni], grid[j + 1][i]))

    c_bot = bm.verts.new((0.0, y_seat - 0.03, z_bot + 0.02))
    c_top = bm.verts.new((0.0, y_seat + 0.018, z_top))
    for i in range(n_u):
        ni = (i + 1) % n_u
        bm.faces.new((c_bot, grid[0][ni], grid[0][i]))
        bm.faces.new((grid[n_z][i], grid[n_z][ni], c_top))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new("SculptedTunic")
    bm.to_mesh(m)
    bm.free()
    obj = bpy.data.objects.new("SculptedTunic", m)
    bpy.context.collection.objects.link(obj)
    return obj


def barrel_half_width_at(kathy_obj, y_q, z_q):
    pts = [abs(v.co.x) for v in kathy_obj.data.vertices if abs(v.co.y - y_q) < 0.08 and abs(v.co.z - z_q) < 0.08]
    return max(pts) if pts else 0.36


def build_mannerheim_rider(kathy_obj, saddle_z, y_shift):
    y_seat = 0.12 + y_shift
    hip_z = saddle_z + 0.14  # Heroic 1.09x rider proportion so cap reaches ~4.62m naturally!

    suit_parts = [build_sculpted_m36_tunic(y_seat, hip_z)]
    crisp_parts = []

    # 1) LEFT ARM (+X): smooth 6-point anatomical sleeve curve holding ALL 4 REINS!
    left_hand_pos = Vector((0.085, y_seat - 0.54, hip_z + 0.46))
    sleeve_l = loft_tube_mesh(
        "Sleeve_L",
        [
            (0.25, y_seat + 0.01, hip_z + 1.04),
            (0.34, y_seat - 0.02, hip_z + 0.88),
            (0.35, y_seat - 0.08, hip_z + 0.66),
            (0.32, y_seat - 0.15, hip_z + 0.52),
            (0.21, y_seat - 0.33, hip_z + 0.48),
            (0.125, y_seat - 0.46, hip_z + 0.465),
        ],
        [(0.132, 0.122), (0.118, 0.110), (0.108, 0.102), (0.102, 0.096), (0.092, 0.086), (0.078, 0.072)],
        segs=20, cloth_fold_amp=0.009,
    )
    cuff_l = loft_tube_mesh(
        "Cuff_L",
        [(0.180, y_seat - 0.38, hip_z + 0.475), (0.122, y_seat - 0.47, hip_z + 0.465)],
        [(0.088, 0.082), (0.084, 0.078)], segs=16,
    )
    hand_l = loft_tube_mesh(
        "GlovedHand_L",
        [
            (0.122, y_seat - 0.47, hip_z + 0.465),
            (0.090, y_seat - 0.53, hip_z + 0.455),
            (0.065, y_seat - 0.56, hip_z + 0.440),
        ],
        [(0.060, 0.050), (0.058, 0.054), (0.046, 0.044)], segs=14,
    )
    suit_parts.extend([sleeve_l, cuff_l])
    crisp_parts.append(hand_l)

    # 2) RIGHT ARM (-X): smooth anatomical curve to right thigh grasping MARSHAL'S BATON!
    sleeve_r = loft_tube_mesh(
        "Sleeve_R",
        [
            (-0.25, y_seat + 0.01, hip_z + 1.04),
            (-0.35, y_seat + 0.03, hip_z + 0.86),
            (-0.38, y_seat + 0.03, hip_z + 0.64),
            (-0.37, y_seat - 0.01, hip_z + 0.48),
            (-0.33, y_seat - 0.14, hip_z + 0.34),
            (-0.29, y_seat - 0.25, hip_z + 0.25),
        ],
        [(0.132, 0.122), (0.118, 0.110), (0.108, 0.102), (0.102, 0.096), (0.092, 0.086), (0.078, 0.072)],
        segs=20, cloth_fold_amp=0.009,
    )
    cuff_r = loft_tube_mesh(
        "Cuff_R",
        [(-0.318, y_seat - 0.18, hip_z + 0.30), (-0.288, y_seat - 0.26, hip_z + 0.245)],
        [(0.088, 0.082), (0.084, 0.078)], segs=16,
    )
    hand_r = loft_tube_mesh(
        "GlovedHand_R",
        [
            (-0.288, y_seat - 0.26, hip_z + 0.245),
            (-0.270, y_seat - 0.32, hip_z + 0.215),
            (-0.260, y_seat - 0.36, hip_z + 0.205),
        ],
        [(0.060, 0.052), (0.058, 0.056), (0.046, 0.044)], segs=14,
    )
    baton = loft_tube_mesh(
        "MarshalsBaton",
        [
            (-0.312, y_seat - 0.11, hip_z + 0.165),
            (-0.270, y_seat - 0.32, hip_z + 0.220),
            (-0.220, y_seat - 0.55, hip_z + 0.285),
        ],
        [(0.023, 0.023), (0.021, 0.021), (0.024, 0.024)], segs=14,
    )
    suit_parts.extend([sleeve_r, cuff_r])
    crisp_parts.extend([hand_r, baton])

    # 3) BARREL-CLEAR Continuous Cavalry Legs, Pussihousut Breeches & Tall Riding Boots!
    # Measure Käthy's actual shoulder/barrel half-width at knee & calf so boots sit 100% OUTSIDE the horse!
    y_kn = y_seat - 0.44
    hw_knee = barrel_half_width_at(kathy_obj, y_kn, hip_z - 0.38)
    hw_calf = barrel_half_width_at(kathy_obj, y_seat - 0.41, hip_z - 0.66)
    x_leg_out = max(hw_knee, hw_calf, 0.35) + 0.075  # keeps inner boot surface cleanly hugging saddle flap!

    for sx in (-1.0, 1.0):
        full_leg = loft_tube_mesh(
            f"FullCavalryLeg_{sx}",
            [
                (sx * 0.18, y_seat - 0.02, hip_z + 0.02),
                (sx * (x_leg_out - 0.06), y_seat - 0.18, hip_z - 0.12),
                (sx * (x_leg_out + 0.02), y_seat - 0.32, hip_z - 0.25),   # flared pussihousut thigh!
                (sx * x_leg_out, y_kn, hip_z - 0.38),                      # knee outside shoulder!
                (sx * x_leg_out, y_kn - 0.01, hip_z - 0.43),               # crisp boot top rim
                (sx * x_leg_out, y_seat - 0.42, hip_z - 0.64),             # sculpted calf
                (sx * (x_leg_out - 0.01), y_seat - 0.39, hip_z - 0.88),    # shin
                (sx * (x_leg_out - 0.01), y_seat - 0.37, hip_z - 1.05),    # ankle & heel
                (sx * (x_leg_out - 0.01), y_seat - 0.49, hip_z - 1.07),    # instep on stirrup
                (sx * (x_leg_out - 0.01), y_seat - 0.58, hip_z - 1.06),    # rounded cavalry boot toe
            ],
            [
                (0.155, 0.148),
                (0.175, 0.148),
                (0.182, 0.140),
                (0.098, 0.102),
                (0.106, 0.110),
                (0.098, 0.106),
                (0.082, 0.088),
                (0.072, 0.084),
                (0.064, 0.058),
                (0.048, 0.040),
            ],
            segs=20, cloth_fold_amp=0.005,
        )
        suit_parts.append(full_leg)

        bpy.ops.mesh.primitive_cube_add(size=1.0)
        sb = bpy.context.active_object
        sb.scale = (0.16, 0.068, 0.016)
        sb.location = (sx * 0.22, y_seat + 0.01, hip_z + 1.12)
        sb.rotation_euler = Euler((0.0, sx * 0.30, 0.0), "XYZ")

        bpy.ops.mesh.primitive_cube_add(size=1.0)
        pk = bpy.context.active_object
        pk.scale = (0.115, 0.016, 0.135)
        pk.location = (sx * 0.130, y_seat - 0.215, hip_z + 0.80)
        pk.rotation_euler = Euler((0.06, 0.0, -sx * 0.18), "XYZ")

        bpy.ops.mesh.primitive_cube_add(size=1.0)
        hpk = bpy.context.active_object
        hpk.scale = (0.016, 0.15, 0.055)
        hpk.location = (sx * 0.285, y_seat - 0.04, hip_z + 0.26)
        hpk.rotation_euler = Euler((0.0, sx * 0.18, 0.0), "XYZ")
        suit_parts.extend([sb, pk, hpk])

        xb = x_leg_out - 0.01
        spur = loft_tube_mesh(
            f"Spur_{sx}",
            [(sx * xb, y_seat - 0.30, hip_z - 1.03), (sx * xb, y_seat - 0.21, hip_z - 1.04)],
            [(0.015, 0.011), (0.010, 0.010)], segs=8,
        )
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        cp = bpy.context.active_object
        cp.scale = (0.045, 0.016, 0.050)
        cp.location = (sx * 0.065, y_seat - 0.095, hip_z + 1.24)
        cp.rotation_euler = Euler((0.0, 0.0, -sx * 0.42), "XYZ")

        st_leather = loft_tube_mesh(
            f"StirrupLeather_{sx}",
            [(sx * (xb - 0.03), y_seat - 0.32, hip_z - 0.20), (sx * xb, y_seat - 0.48, hip_z - 0.95)],
            [(0.018, 0.007), (0.016, 0.007)], segs=8,
        )
        stirrup = loft_tube_mesh(
            f"Stirrup_{sx}",
            [
                (sx * (xb - 0.055), y_seat - 0.49, hip_z - 1.09),
                (sx * (xb - 0.045), y_seat - 0.49, hip_z - 0.95),
                (sx * (xb + 0.045), y_seat - 0.49, hip_z - 0.95),
                (sx * (xb + 0.055), y_seat - 0.49, hip_z - 1.09),
                (sx * (xb - 0.055), y_seat - 0.49, hip_z - 1.09),
            ],
            [(0.011, 0.015)] * 5, segs=8, cap=False,
        )
        crisp_parts.extend([spur, cp, st_leather, stirrup])

    suit = join_objects(suit_parts, "MannerheimUniform")
    voxel_polish(suit, voxel_size=0.0072, smooth_iters=3, smooth_factor=0.42, target_tris=16000)
    crisp_parts.append(suit)

    bpy.ops.mesh.primitive_cube_add(size=1.0)
    throat_cr = bpy.context.active_object
    throat_cr.scale = (0.038, 0.016, 0.038)
    throat_cr.location = (0.0, y_seat - 0.112, hip_z + 1.18)
    throat_cr.rotation_euler = Euler((0.0, math.pi * 0.25, 0.0), "XYZ")
    crisp_parts.append(throat_cr)

    for arm_ang in (0.0, math.pi * 0.5):
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        mc = bpy.context.active_object
        mc.scale = (0.072, 0.018, 0.022)
        mc.location = (0.140, y_seat - 0.230, hip_z + 0.82)
        mc.rotation_euler = Euler((0.0, arm_ang, -0.18), "XYZ")
        crisp_parts.append(mc)

    bpy.ops.mesh.primitive_torus_add(major_radius=0.222, minor_radius=0.024, major_segments=32, minor_segments=10)
    belt = bpy.context.active_object
    belt.scale = (1.12, 0.90, 1.25)
    belt.location = (0.0, y_seat, hip_z + 0.44)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    buckle = bpy.context.active_object
    buckle.scale = (0.062, 0.030, 0.074)
    buckle.location = (0.0, y_seat - 0.205, hip_z + 0.44)
    sam = loft_tube_mesh(
        "SamBrowne",
        [(-0.14, y_seat - 0.03, hip_z + 1.14), (-0.03, y_seat - 0.242, hip_z + 0.82), (0.08, y_seat - 0.210, hip_z + 0.46)],
        [(0.022, 0.009)] * 3, segs=8,
    )
    crisp_parts.extend([belt, buckle, sam])

    # 4) Watertight Portrait Head with Tilted Neck Cut (eliminating rear toga collar sliver!)
    wt_glb = ensure_watertight_portrait_bust()
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=wt_glb)
    hd_objs = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
    hd = join_objects(hd_objs, "MannerheimHead")

    bm_h = bmesh.new()
    bm_h.from_mesh(hd.data)
    # Tilted bisect plane (higher in back z=0.60, lower under chin z=0.53) removes 100% of rear toga collar!
    res = bmesh.ops.bisect_plane(
        bm_h, geom=bm_h.verts[:] + bm_h.edges[:] + bm_h.faces[:],
        plane_co=Vector((0.0, 0.0, 0.565)),
        plane_no=Vector((0.0, -0.26, 0.965)).normalized(), clear_inner=True,
    )
    cuts = [g for g in res["geom_cut"] if isinstance(g, bmesh.types.BMEdge)]
    if cuts:
        bmesh.ops.holes_fill(bm_h, edges=cuts, sides=400)
    bmesh.ops.recalc_face_normals(bm_h, faces=bm_h.faces)
    bm_h.to_mesh(hd.data)
    bm_h.free()
    voxel_polish(hd, voxel_size=0.0038, smooth_iters=1, smooth_factor=0.22, target_tris=6500)

    vs = [v.co for v in hd.data.vertices]
    cx = 0.5 * (min(v.x for v in vs) + max(v.x for v in vs))
    cy = 0.5 * (min(v.y for v in vs) + max(v.y for v in vs))
    mz = min(v.z for v in vs)
    sc = 0.45 / (max(v.z for v in vs) - mz)
    for v in hd.data.vertices:
        v.co = Vector(((v.co.x - cx) * sc, (v.co.y - cy) * sc, (v.co.z - mz) * sc))
    hd.data.update()

    head_base = Vector((0.0, y_seat, hip_z + 1.25))
    yaw_head = math.radians(2.0)
    hd.location = head_base
    hd.rotation_euler = Euler((0.0, 0.0, yaw_head), "XYZ")
    bpy.ops.object.select_all(action="DESELECT")
    hd.select_set(True)
    bpy.context.view_layer.objects.active = hd
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    crisp_parts.append(hd)

    h_vs = [v.co for v in hd.data.vertices]
    skull_vs = [v for v in h_vs if v.z > head_base.z + 0.24]
    skull_cx = 0.5 * (min(v.x for v in skull_vs) + max(v.x for v in skull_vs))
    skull_cy = 0.5 * (min(v.y for v in skull_vs) + max(v.y for v in skull_vs))
    skull_top_z = max(v.z for v in h_vs)
    nose_v = min([v for v in h_vs if head_base.z + 0.14 < v.z < head_base.z + 0.29], key=lambda v: v.y)

    must = loft_tube_mesh(
        "Mustache",
        [(-0.048, 0.018, -0.008), (-0.022, 0.004, 0.003), (0.0, 0.0, 0.006), (0.022, 0.004, 0.003), (0.048, 0.018, -0.008)],
        [(0.008, 0.009), (0.015, 0.013), (0.017, 0.015), (0.015, 0.013), (0.008, 0.009)], segs=10,
    )
    must.location = (nose_v.x, nose_v.y + 0.022, nose_v.z - 0.025)
    must.rotation_euler = Euler((0.0, 0.0, yaw_head), "XYZ")
    crisp_parts.append(must)

    hat_base_z = skull_top_z - 0.135
    band = loft_tube_mesh(
        "HatBaseBand",
        [(0.0, 0.008, 0.0), (0.0, 0.010, 0.065), (0.0, 0.012, 0.115)],
        [(0.140, 0.160), (0.146, 0.166), (0.140, 0.158)], segs=32, cloth_fold_amp=0.002,
    )
    front_pad = loft_tube_mesh(
        "HatFrontPad",
        [(-0.112, -0.100, 0.065), (-0.058, -0.142, 0.090), (0.0, -0.154, 0.098), (0.058, -0.142, 0.090), (0.112, -0.100, 0.065)],
        [(0.038, 0.055), (0.048, 0.065), (0.052, 0.068), (0.048, 0.065), (0.038, 0.055)], segs=16, cloth_fold_amp=0.002,
    )
    mid_dome = loft_tube_mesh(
        "HatCrownDome",
        [(0.0, 0.018, 0.04), (0.0, 0.020, 0.125), (0.0, 0.022, 0.190), (0.0, 0.024, 0.212)],
        [(0.138, 0.114), (0.142, 0.118), (0.130, 0.108), (0.094, 0.078)], segs=32, cloth_fold_amp=0.002,
    )
    hat_obj = join_objects([band, front_pad, mid_dome], "Turkislakki")
    voxel_polish(hat_obj, voxel_size=0.0055, smooth_iters=1, smooth_factor=0.35, target_tris=3200)
    hat_obj.location = (skull_cx, skull_cy + 0.008, hat_base_z)
    hat_obj.rotation_euler = Euler((-0.07, 0.0, yaw_head), "XYZ")
    crisp_parts.append(hat_obj)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.023)
    cockade = bpy.context.active_object
    cockade.scale = (0.85, 0.38, 1.15)
    cockade.location = (skull_cx, skull_cy - 0.175, hat_base_z + 0.095)
    crisp_parts.append(cockade)

    # 5) BARREL-CLEAR Vertical 3-Bar Basket-Hilted Cavalry Sabre & Long Scabbard!
    hw_sab = barrel_half_width_at(kathy_obj, y_seat + 0.10, hip_z - 0.45)
    sx_sab = max(hw_sab + 0.045, 0.435)
    sy_sab, sz_sab = y_seat + 0.09, hip_z + 0.06
    sabre_scabbard = loft_tube_mesh(
        "SabreScabbard",
        [(sx_sab, sy_sab, sz_sab), (sx_sab + 0.01, sy_sab + 0.05, sz_sab - 0.74), (sx_sab - 0.01, sy_sab + 0.10, sz_sab - 1.50)],
        [(0.025, 0.013), (0.022, 0.011), (0.017, 0.009)], segs=10,
    )
    sabre_grip = loft_tube_mesh(
        "SabreGrip",
        [(sx_sab, sy_sab, sz_sab), (sx_sab - 0.01, sy_sab - 0.01, sz_sab + 0.21)],
        [(0.020, 0.016), (0.024, 0.020)], segs=10,
    )
    crisp_parts.extend([sabre_scabbard, sabre_grip])
    for b_off in (-0.024, 0.0, 0.024):
        guard = loft_tube_mesh(
            f"SabreBasket_{b_off}",
            [
                (sx_sab + b_off * 0.5, sy_sab, sz_sab + 0.01),
                (sx_sab + b_off, sy_sab - 0.10, sz_sab + 0.105),
                (sx_sab - 0.01, sy_sab - 0.01, sz_sab + 0.205),
            ],
            [(0.008, 0.008)] * 3, segs=8,
        )
        crisp_parts.append(guard)

    return crisp_parts, left_hand_pos


# ---------------------------------------------------------------------------
# 3. BVHTree Skin-Snapped Saddlecloth, Girth, Y-Breastplate, Bridle & Reins
# ---------------------------------------------------------------------------
def snap_polyline_to_bvh(bvh, raw_pts, n_samples=18, offset=0.005):
    vecs = [Vector(p) for p in raw_pts]
    # Resample uniformly along polyline, then snap each sample onto actual horse skin!
    cum = [0.0]
    for i in range(1, len(vecs)):
        cum.append(cum[-1] + (vecs[i] - vecs[i - 1]).length)
    total = max(cum[-1], 1e-6)
    snapped = []
    for k in range(n_samples):
        d = total * (k / max(n_samples - 1, 1))
        idx = 0
        while idx < len(cum) - 2 and cum[idx + 1] < d:
            idx += 1
        seg_len = max(cum[idx + 1] - cum[idx], 1e-6)
        q = vecs[idx].lerp(vecs[idx + 1], (d - cum[idx]) / seg_len)
        loc, norm, _i, _dist = bvh.find_nearest(q)
        if loc is not None and norm is not None:
            snapped.append(tuple(loc + norm * offset))
        else:
            snapped.append(tuple(q))
    return snapped


def build_tack(kathy_obj, saddle_z, nose_tip, poll_behind_ears, left_hand_pos, y_shift):
    parts = []
    y_seat = 0.12 + y_shift
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bvh = BVHTree.FromObject(kathy_obj, depsgraph)

    # Shaped military saddlecloth (shabrack) snapped cleanly onto Käthy's barrel & croup!
    bm = bmesh.new()
    nu, nv = 18, 14
    grid = []
    for j in range(nv + 1):
        tv = j / nv
        y = (y_seat - 0.46) + tv * 1.02
        row = []
        for i in range(nu + 1):
            u = (i / nu) * 2.0 - 1.0
            ang = u * 1.12
            q = Vector((math.sin(ang) * 0.42, y, (saddle_z - 0.36) + math.cos(ang) * 0.42))
            loc, norm, _idx, dist = bvh.find_nearest(q)
            if loc is not None and dist < 0.14:
                p_surf = loc + norm * 0.012
            else:
                p_surf = Vector((math.sin(ang) * 0.36, y, (saddle_z - 0.36) + math.cos(ang) * 0.37))
            row.append(bm.verts.new(p_surf))
        grid.append(row)
    for j in range(nv):
        for i in range(nu):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.020)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    sm = bpy.data.meshes.new("Shabrack")
    bm.to_mesh(sm)
    bm.free()
    shab = bpy.data.objects.new("Shabrack", sm)
    bpy.context.collection.objects.link(shab)
    parts.append(shab)

    cantle = loft_tube_mesh(
        "Cantle",
        [(-0.18, y_seat + 0.25, saddle_z + 0.01), (0.0, y_seat + 0.31, saddle_z + 0.065), (0.18, y_seat + 0.25, saddle_z + 0.01)],
        [(0.034, 0.040), (0.040, 0.048), (0.034, 0.040)], segs=10,
    )
    parts.append(cantle)

    # Skin-tight Girth Strap snapped directly around Käthy's belly via BVHTree (ZERO spikes!)
    girth_y = y_seat - 0.22
    raw_girth = [
        (math.cos(math.pi * k / 16.0) * 0.45, girth_y, (saddle_z - 0.38) - math.sin(math.pi * k / 16.0) * 0.55)
        for k in range(17)
    ]
    g_pts = snap_polyline_to_bvh(bvh, raw_girth, n_samples=20, offset=0.008)
    parts.append(loft_tube_mesh("GirthStrap", g_pts, [(0.048, 0.009)] * len(g_pts), segs=10))

    # Skin-tight Y-Breastplate meeting at central chest ring & curving smoothly along sternum to girth!
    chest_probe = Vector((0.0, -0.95 + y_shift, saddle_z - 0.58))
    c_loc, c_nrm, _, _ = bvh.find_nearest(chest_probe)
    chest_ring_pt = (c_loc + c_nrm * 0.012) if c_loc is not None else Vector((0.0, -0.78 + y_shift, saddle_z - 0.58))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.026, minor_radius=0.007, major_segments=16, minor_segments=8)
    cring = bpy.context.active_object
    cring.location = chest_ring_pt
    cring.rotation_euler = Euler((math.radians(78.0), 0.0, 0.0), "XYZ")
    parts.append(cring)

    for sx in (-1.0, 1.0):
        bp_pts = snap_polyline_to_bvh(
            bvh,
            [(sx * 0.25, y_seat - 0.42, saddle_z - 0.14), (sx * 0.24, -0.62 + y_shift, saddle_z - 0.38), tuple(chest_ring_pt)],
            n_samples=14, offset=0.007,
        )
        parts.append(loft_tube_mesh(f"Breastplate_{sx}", bp_pts, [(0.013, 0.006)] * len(bp_pts), segs=8))

    sternum_pts = snap_polyline_to_bvh(
        bvh,
        [tuple(chest_ring_pt), (0.0, -0.58 + y_shift, saddle_z - 0.85), g_pts[len(g_pts) // 2]],
        n_samples=14, offset=0.007,
    )
    parts.append(loft_tube_mesh("BreastplateSternum", sternum_pts, [(0.012, 0.006)] * len(sternum_pts), segs=8))

    # BVHTree Skin-Snapped Double Bridle (100% flush with Käthy's nasal bridge, forehead & cheeks!)
    head_vec = poll_behind_ears - nose_tip
    head_len = head_vec.length
    head_dir = head_vec.normalized()
    head_right = Vector((1.0, 0.0, 0.0))
    head_front = head_dir.cross(head_right).normalized()
    if head_front.y > 0.0:
        head_front = -head_front

    c_bit = nose_tip + head_dir * (0.20 * head_len)
    c_nose = nose_tip + head_dir * (0.27 * head_len)
    c_brow = nose_tip + head_dir * (0.76 * head_len)   # Well below ears across forehead!
    c_crown = nose_tip + head_dir * (0.90 * head_len)  # Behind base of ears!

    # Cavesson noseband ring snapped tightly around muzzle
    raw_nb = [
        tuple(c_nose + head_right * (math.cos(2.0 * math.pi * k / 16.0) * 0.22) + head_front * (math.sin(2.0 * math.pi * k / 16.0) * 0.22))
        for k in range(17)
    ]
    nb_pts = snap_polyline_to_bvh(bvh, raw_nb, n_samples=20, offset=0.005)
    parts.append(loft_tube_mesh("Noseband", nb_pts, [(0.010, 0.005)] * len(nb_pts), segs=8, cap=False))

    # Browband & Crownpiece snapped smoothly across forehead & poll (ZERO floating tent corners!)
    raw_brow = [
        tuple(c_brow + head_right * (-0.22 * math.cos(math.pi * k / 12.0)) + head_front * (0.22 * math.sin(math.pi * k / 12.0)))
        for k in range(13)
    ]
    brow_pts = snap_polyline_to_bvh(bvh, raw_brow, n_samples=16, offset=0.005)
    parts.append(loft_tube_mesh("Browband", brow_pts, [(0.010, 0.005)] * len(brow_pts), segs=8))

    raw_crown = [
        tuple(c_crown + head_right * (-0.22 * math.cos(math.pi * k / 12.0)) + head_front * (0.22 * math.sin(math.pi * k / 12.0)))
        for k in range(13)
    ]
    crown_pts = snap_polyline_to_bvh(bvh, raw_crown, n_samples=16, offset=0.006)
    parts.append(loft_tube_mesh("Crownpiece", crown_pts, [(0.011, 0.006)] * len(crown_pts), segs=8))

    # Double cheekpieces, S-curb bit shanks & ALL FOUR REINS converging into Mannerheim's LEFT hand!
    for sx_idx, sx in enumerate((-1.0, 1.0)):
        bit_probe = c_bit + head_right * (sx * 0.20) - head_front * 0.04
        b_loc, b_nrm, _, _ = bvh.find_nearest(bit_probe)
        bit_pt = (b_loc + b_nrm * 0.008) if b_loc is not None else (c_bit + head_right * (sx * 0.09))
        top_pt = Vector(crown_pts[-1] if sx > 0 else crown_pts[0])

        for ch_off in (-0.010, 0.010):
            ck_pts = snap_polyline_to_bvh(
                bvh,
                [tuple(bit_pt + head_front * ch_off), tuple(0.5 * (bit_pt + top_pt) + head_right * (sx * 0.08) + head_front * ch_off), tuple(top_pt + head_front * ch_off)],
                n_samples=14, offset=0.005,
            )
            parts.append(loft_tube_mesh(f"Cheek_{sx}_{ch_off}", ck_pts, [(0.008, 0.005)] * len(ck_pts), segs=8))

        shank_bot = bit_pt + Vector((sx * 0.008, 0.045, -0.105))
        parts.append(loft_tube_mesh(
            f"CurbShank_{sx}",
            [tuple(bit_pt + Vector((0, 0, 0.02))), tuple(bit_pt + Vector((sx * 0.006, 0.015, -0.045))), tuple(shank_bot)],
            [(0.013, 0.013), (0.011, 0.011), (0.012, 0.012)], segs=8,
        ))

        for r_idx, (p_start, sag) in enumerate([(bit_pt, 0.14), (shank_bot, 0.22)]):
            p_end = left_hand_pos + Vector((sx * 0.018, 0.01, -r_idx * 0.022))
            rein_pts = []
            for k in range(16):
                t = k / 15.0
                pt = p_start.lerp(p_end, t)
                pt.z -= sag * 4.0 * t * (1.0 - t)
                if sx < 0:
                    pt.x += -0.12 * math.sin(t * math.pi)
                    pt.z += 0.03 * (t ** 2)
                else:
                    pt.x += 0.045 * math.sin(t * math.pi)
                rein_pts.append(tuple(pt))
            parts.append(loft_tube_mesh(f"Rein_{sx}_{r_idx}", rein_pts, [(0.009, 0.006)] * 16, segs=8))

    loop_pts = [
        tuple(left_hand_pos + Vector((0.0, 0.03, -0.02))),
        tuple(left_hand_pos + Vector((0.02, 0.06, -0.13))),
        tuple(left_hand_pos + Vector((-0.01, 0.10, -0.15))),
        tuple(left_hand_pos + Vector((-0.02, 0.05, -0.03))),
    ]
    parts.append(loft_tube_mesh("ReinBightLoop", loop_pts, [(0.009, 0.006)] * 4, segs=8))

    return parts


def main():
    clear_scene()
    plinth_h = 0.14

    bpy.ops.mesh.primitive_cube_add(size=1.0)
    plinth = bpy.context.active_object
    plinth.scale = (2.46, 5.66, plinth_h)
    plinth.location = (0.0, 0.0, plinth_h * 0.5)

    kathy, saddle_z, nose_tip, poll_pt, y_shift = build_kathy_horse(plinth_top_z=plinth_h)
    rider_parts, left_hand_pos = build_mannerheim_rider(kathy, saddle_z=saddle_z, y_shift=y_shift)
    tack_parts = build_tack(
        kathy, saddle_z=saddle_z, nose_tip=nose_tip, poll_behind_ears=poll_pt,
        left_hand_pos=left_hand_pos, y_shift=y_shift,
    )

    all_objs = [plinth, kathy] + rider_parts + tack_parts
    combined = join_objects(all_objs, "MannerheimEquestrianBronze")

    zs = [v.co.z for v in combined.data.vertices]
    mz = min(zs)
    hz = max(zs) - mz
    z_scale = 4.65 / max(hz, 1e-4)
    for v in combined.data.vertices:
        v.co = Vector((v.co.x, v.co.y, (v.co.z - mz) * z_scale))
    combined.data.update()

    bm = bmesh.new()
    bm.from_mesh(combined.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(combined.data)
    bm.free()

    mesh = combined.data
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

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    combined.select_set(True)
    bpy.context.view_layer.objects.active = combined
    bpy.ops.export_scene.gltf(
        filepath=OUT_PATH, export_format="GLB", use_selection=True,
        export_apply=True, export_normals=True, export_texcoords=True,
        export_materials="NONE",
    )
    zs_out = [v.co.z for v in mesh.vertices]
    sz = os.path.getsize(OUT_PATH) / 1024.0
    print(
        f"[mannerheim-v7] {len(mesh.polygons)} tris | raw_h={hz:.2f}m -> h={max(zs_out)-min(zs_out):.2f}m "
        f"| {sz:.1f} KB -> {OUT_PATH}",
        flush=True,
    )


if __name__ == "__main__":
    main()
