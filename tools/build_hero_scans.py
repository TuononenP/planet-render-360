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
import sys
from mathutils import Euler, Matrix, Vector, noise

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
    obj.data.validate()

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


def _smoothstep(edge0, edge1, x):
    d = edge1 - edge0
    if abs(d) < 1e-8:
        return 1.0 if x >= edge1 else 0.0
    t = max(0.0, min(1.0, (x - edge0) / d))
    return t * t * (3.0 - 2.0 * t)


def _gauss2(x, y, cx, cy, sx, sy):
    dx = (x - cx) / max(sx, 1e-6)
    dy = (y - cy) / max(sy, 1e-6)
    return math.exp(-0.5 * (dx * dx + dy * dy))


def _gauss3(p, c, s):
    dx = (p.x - c[0]) / s[0]
    dy = (p.y - c[1]) / s[1]
    dz = (p.z - c[2]) / s[2]
    return math.exp(-0.5 * (dx * dx + dy * dy + dz * dz))


def _decimate_obj(obj, target_tris, vg_name=None):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    tri_count = sum(max(len(p.vertices) - 2, 1) for p in obj.data.polygons)
    if tri_count > target_tris:
        dec = obj.modifiers.new("Decimate", "DECIMATE")
        dec.decimate_type = "COLLAPSE"
        dec.ratio = float(target_tris) / float(tri_count)
        if vg_name:
            dec.vertex_group = vg_name
            dec.vertex_group_factor = 1.0
        dec.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=dec.name)


def _catmull_rom(pts, samples_per_seg=8):
    """Smooth Catmull-Rom interpolation through control points for flowing Art Nouveau locks."""
    p = [Vector(v) for v in pts]
    if len(p) < 2:
        return p
    ext = [p[0] + (p[0] - p[1])] + p + [p[-1] + (p[-1] - p[-2])]
    out = []
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        n = samples_per_seg if i < len(ext) - 3 else samples_per_seg + 1
        for k in range(n):
            t = float(k) / float(samples_per_seg)
            t2, t3 = t * t, t * t * t
            pt = 0.5 * (
                (2.0 * p1)
                + (-p0 + p2) * t
                + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
                + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
            )
            out.append(pt)
    return out


def _add_embedded_wave_tress(bm, ctrl_pts, r_width, r_thick, segs=20, ridges=4, ridge_amp=0.15, sink=0.56):
    """Sculpts a combed Art Nouveau bronze wave lock sunk into the skull coiffure."""
    pts = _catmull_rom(ctrl_pts, samples_per_seg=8)
    n_pts = len(pts)
    if n_pts < 2:
        return
    rings = []
    prev_n = None
    for idx, pt in enumerate(pts):
        t = float(idx) / float(n_pts - 1)
        taper = math.sin(min(1.0, max(0.0, t)) * math.pi) ** 0.58
        rw = r_width * (0.18 + 0.82 * taper)
        rt = r_thick * (0.18 + 0.82 * taper)
        if idx == 0:
            tang = (pts[1] - pts[0]).normalized()
        elif idx == n_pts - 1:
            tang = (pts[-1] - pts[-2]).normalized()
        else:
            tang = (pts[idx + 1] - pts[idx - 1]).normalized()
        radial = Vector((pt.x, pt.y - 0.010, pt.z)).normalized() if pt.length > 1e-4 else Vector((0.0, 0.0, 1.0))
        n_out = radial - tang * radial.dot(tang)
        if n_out.length < 1e-4:
            n_out = prev_n if prev_n is not None else Vector((0.0, 0.0, 1.0))
        n_out.normalize()
        if prev_n is not None and n_out.dot(prev_n) < 0.0:
            n_out = -n_out
        n_side = tang.cross(n_out).normalized()
        prev_n = n_out
        center_shifted = pt - n_out * (rt * sink)
        ring = []
        for s in range(segs):
            a = 2.0 * math.pi * s / segs
            outer_w = max(0.0, math.sin(a))
            strand = 1.0 + ridge_amp * outer_w * math.cos(math.cos(a) * ridges * math.pi + t * 1.6)
            offset = n_side * (math.cos(a) * rw * strand) + n_out * (math.sin(a) * rt * strand)
            ring.append(bm.verts.new(center_shifted + offset))
        rings.append(ring)

    for j in range(len(rings) - 1):
        for s in range(segs):
            s2 = (s + 1) % segs
            bm.faces.new((rings[j][s], rings[j][s2], rings[j + 1][s2], rings[j + 1][s]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])


def _add_tube_loft(bm, points, radii, segs=18, oval_aspect=1.0, cap_start=True, cap_end=True, tip_round=True):
    """Lofts a smooth closed organic limb/finger tube with rounded hemispherical tips."""
    pts = [Vector(p) for p in points]
    rads = list(radii)
    if tip_round and len(pts) >= 2:
        t0 = (pts[0] - pts[1]).normalized()
        r0 = rads[0]
        pts = [pts[0] + t0 * (r0 * 0.78), pts[0] + t0 * (r0 * 0.40)] + pts
        rads = [r0 * 0.25, r0 * 0.78] + rads
        t1 = (pts[-1] - pts[-2]).normalized()
        r1 = rads[-1]
        pts = pts + [pts[-1] + t1 * (r1 * 0.40), pts[-1] + t1 * (r1 * 0.80)]
        rads = rads + [r1 * 0.78, r1 * 0.24]

    rings = []
    prev_n = None
    for idx, (pt, rad) in enumerate(zip(pts, rads)):
        if idx == 0:
            tang = (pts[1] - pts[0]).normalized()
        elif idx == len(pts) - 1:
            tang = (pts[-1] - pts[-2]).normalized()
        else:
            tang = (pts[idx + 1] - pts[idx - 1]).normalized()
        if prev_n is None:
            ref = Vector((0.0, 0.0, 1.0)) if abs(tang.z) < 0.85 else Vector((1.0, 0.0, 0.0))
            n1 = tang.cross(ref).normalized()
        else:
            n1 = prev_n - tang * prev_n.dot(tang)
            if n1.length < 1e-6:
                n1 = tang.cross(Vector((0.0, 1.0, 0.0)))
            n1.normalize()
        n2 = tang.cross(n1).normalized()
        prev_n = n1
        ring = []
        for s in range(segs):
            a = 2.0 * math.pi * s / segs
            offset = (n1 * math.cos(a) * rad) + (n2 * math.sin(a) * rad * oval_aspect)
            ring.append(bm.verts.new(pt + offset))
        rings.append(ring)

    for j in range(len(rings) - 1):
        for s in range(segs):
            s2 = (s + 1) % segs
            bm.faces.new((rings[j][s], rings[j][s2], rings[j + 1][s2], rings[j + 1][s]))
    if cap_start:
        bm.faces.new(rings[0][::-1])
    if cap_end:
        bm.faces.new(rings[-1])


def _extract_ordered_neck_loop(body_obj, z_min=5.25):
    bm = bmesh.new()
    bm.from_mesh(body_obj.data)
    b_edges = [e for e in bm.edges if e.is_boundary and 0.5 * (e.verts[0].co.z + e.verts[1].co.z) >= z_min]
    adj = {}
    for e in b_edges:
        v0, v1 = e.verts[0], e.verts[1]
        adj.setdefault(v0, []).append(v1)
        adj.setdefault(v1, []).append(v0)

    start_v = next(iter(adj.keys()))
    ordered = [start_v]
    prev_v = None
    cur_v = start_v
    while True:
        nbrs = [n for n in adj[cur_v] if n != prev_v]
        if not nbrs or nbrs[0] == start_v:
            break
        prev_v = cur_v
        cur_v = nbrs[0]
        ordered.append(cur_v)

    pts = [v.co.copy() for v in ordered]
    bm.free()

    ctr = sum(pts, Vector((0.0, 0.0, 0.0))) / len(pts)
    signed_area = 0.0
    for i in range(len(pts)):
        p0 = pts[i] - ctr
        p1 = pts[(i + 1) % len(pts)] - ctr
        signed_area += p0.x * p1.y - p1.x * p0.y
    if signed_area < 0.0:
        pts.reverse()
    return pts


def _build_loop_lofted_neck(loop_pts, bisect_no, head_loc, head_rot, head_scale):
    """Lofts a C1-tangent continuous neck solid directly from `HavisBody`'s ordered boundary loop
    with a slender concave feminine front/side waist, subtle right SCM relief, smooth submental
    throat reach, and a broad continuous sloping back trapezius rising into the low chignon."""
    bm = bmesh.new()
    n_seg = len(loop_pts)
    ctr0 = sum(loop_pts, Vector((0.0, 0.0, 0.0))) / float(n_seg)

    loop_smooth = [p.copy() for p in loop_pts]
    for _ in range(20):
        old = [p.copy() for p in loop_smooth]
        for i in range(n_seg):
            loop_smooth[i] = old[i] * 0.40 + (old[(i - 1) % n_seg] + old[(i + 1) % n_seg]) * 0.30

    R = head_rot.to_matrix()
    skull_anchor = head_loc + R @ (Vector((-0.002, 0.014, 0.014)) * head_scale)
    chin_dir_w = (R @ Vector((0.0, -1.0, 0.0))).xy.normalized()
    waist_ctr = ctr0.lerp(skull_anchor, 0.44) + Vector((0.008, 0.006, 0.0))
    h_up = R @ Vector((0.0, 0.0, 1.0))

    waist_pts = []
    upper_pts = []
    for p in loop_smooth:
        rel = p - ctr0
        ang = math.atan2(rel.y, rel.x)
        ca, sa = math.cos(ang), math.sin(ang)
        dir2 = Vector((ca, sa))

        scm = 0.0038 * math.exp(-0.5 * ((ang - (-2.05)) / 0.42) ** 2)
        hollow = -0.0024 * math.exp(-0.5 * ((ang - (-1.30)) / 0.35) ** 2)
        back_full = 0.020 * (max(0.0, sa) ** 1.15)

        rx_w = 0.052 + scm + 0.004 * max(0.0, -ca)
        ry_w = 0.050 + scm + hollow + back_full
        waist_pts.append(Vector((waist_ctr.x + ca * rx_w, waist_ctr.y + sa * ry_w, waist_ctr.z)))

        toward_chin = max(0.0, dir2.dot(chin_dir_w))
        submental_reach = 0.020 * (toward_chin ** 1.6)
        rx_u = 0.056 + submental_reach * abs(chin_dir_w.x)
        ry_u = 0.058 + 0.010 * max(0.0, sa) + submental_reach * abs(chin_dir_w.y)
        radial_w = Vector((ca * rx_u, sa * ry_u, 0.0)) + Vector((chin_dir_w.x, chin_dir_w.y, 0.0)) * (submental_reach * 0.50)
        radial_tilted = radial_w - h_up * (radial_w.dot(h_up) * 0.55)
        upper_pts.append(skull_anchor + radial_tilted)

    s_levels = [-0.08, 0.0, 0.06, 0.14, 0.24, 0.36, 0.50, 0.65, 0.80, 0.90, 1.00]
    rings = []
    for s in s_levels:
        ring = []
        if s <= 0.0:
            for p in loop_pts:
                rel_xy = Vector((p.x - ctr0.x, p.y - ctr0.y, 0.0))
                pt = p + bisect_no * (s * 0.10) - rel_xy * (s * 0.20)
                ring.append(bm.verts.new(pt))
        else:
            w_decrinkle = _smoothstep(0.0, 0.16, s)
            s_curve = 0.65 * s + 0.35 * _smoothstep(0.0, 0.85, s)
            om = 1.0 - s_curve
            for p_raw, p_sm, p_mid, p_hi in zip(loop_pts, loop_smooth, waist_pts, upper_pts):
                p_base = p_raw.lerp(p_sm, w_decrinkle)
                pt = (p_base * (om * om)) + (p_mid * (2.0 * om * s_curve)) + (p_hi * (s_curve * s_curve))
                pt.z = p_base.z * (1.0 - s) + p_hi.z * s
                ring.append(bm.verts.new(pt))
        rings.append(ring)

    for j in range(len(rings) - 1):
        for i in range(n_seg):
            i2 = (i + 1) % n_seg
            bm.faces.new((rings[j][i], rings[j][i2], rings[j + 1][i2], rings[j + 1][i]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    m = bpy.data.meshes.new("HavisNeckCore")
    bm.to_mesh(m)
    bm.free()
    o = bpy.data.objects.new("HavisNeckCore", m)
    bpy.context.scene.collection.objects.link(o)
    return o


def _eval_havis_head_and_hair_point(ux, uy, uz):
    """Evaluates Ville Vallgren's youthful 19-year-old Parisian Belle Epoque face AND skull-hugging
    1908 Art Nouveau wavy coiffure on ONE continuous surface (eliminating any hairline seam)."""
    parietal_w = _smoothstep(-0.15, 0.55, uy)
    rx = 0.0630 + 0.0055 * parietal_w
    ry = 0.0835
    rz = 0.090 if uz >= 0.0 else 0.082

    if uz < 0.0:
        t_low = min(1.0, -uz)
        front_w = _smoothstep(0.22, -0.45, uy)
        jaw_taper = 1.0 - 0.24 * (t_low ** 1.52) - 0.08 * front_w * _smoothstep(0.18, 0.78, t_low)
        rx *= max(0.42, jaw_taper)
        if uy > -0.15:
            ry *= 1.0 - 0.30 * (t_low ** 1.22) * _smoothstep(-0.15, 0.58, uy)
    else:
        t_hi = min(1.0, uz)
        front_hi = _smoothstep(0.12, -0.50, uy)
        rx *= 1.0 - 0.04 * front_hi * (t_hi ** 1.45)
        if uz > 0.05 and uy > 0.0:
            ry *= 1.0 + 0.05 * _smoothstep(0.05, 0.65, uz) * _smoothstep(0.0, 0.72, uy)

    x, y, z = ux * rx, uy * ry, uz * rz
    ax = abs(x)

    gonial_arch = 0.015 * _smoothstep(0.010, 0.056, ax)
    jaw_floor = -0.072 + 0.026 * _smoothstep(-0.070, 0.025, y) + 0.020 * _smoothstep(0.015, 0.078, y) + gonial_arch
    k_sm = 0.0075 + 0.0125 * _smoothstep(-0.046, 0.012, y)
    dz_j = (z - jaw_floor) / k_sm
    if dz_j < 12.0:
        z = jaw_floor + k_sm * math.log(1.0 + math.exp(max(-20.0, dz_j)))
        t_under = _smoothstep(jaw_floor + 0.026, jaw_floor, z)
        x *= 1.0 - 0.14 * t_under * _smoothstep(-0.045, 0.028, y)

    front_mask = _smoothstep(0.16, -0.30, uy)
    if front_mask > 0.001:
        y -= 0.0044 * _gauss2(x, z, 0.0, 0.040, 0.044, 0.024) * front_mask

        chin = _gauss2(x, z, 0.0, -0.062, 0.0180, 0.0122) * front_mask
        y -= 0.0122 * chin
        z -= 0.0010 * chin
        jaw_z = -0.064 + 0.028 * _smoothstep(0.012, 0.054, ax)
        jaw_rim = math.exp(-0.5 * ((z - jaw_z) / 0.0115) ** 2) * _smoothstep(0.058, 0.012, ax) * _smoothstep(0.012, -0.038, y)
        y -= 0.0016 * jaw_rim
        y += 0.0042 * _gauss2(x, z, 0.0, -0.0445, 0.0145, 0.0048) * front_mask

        y -= 0.0022 * _gauss2(x, z, 0.0, -0.0295, 0.019, 0.010) * front_mask
        lip_w = _smoothstep(0.0170, 0.0042, ax)
        bow = 0.0014 * math.sin(min(1.0, ax / 0.0052) * math.pi * 0.5) * _smoothstep(0.012, 0.0026, ax) - 0.0008 * math.exp(-0.5 * (ax / 0.0022) ** 2)
        smile = 0.0016 * ((ax / 0.0170) ** 2)
        up_z = -0.0262 + bow + smile * 0.45
        y -= 0.0045 * math.exp(-0.5 * ((z - up_z) / 0.0025) ** 2) * lip_w * front_mask
        lo_z = -0.0342 + smile
        y -= 0.0049 * math.exp(-0.5 * ((z - lo_z) / 0.0031) ** 2) * _smoothstep(0.0148, 0.004, ax) * front_mask
        part_z = -0.0302 + smile * 0.65
        y += 0.0038 * math.exp(-0.5 * ((z - part_z) / 0.0013) ** 2) * _smoothstep(0.0155, 0.0030, ax) * front_mask
        y += 0.0022 * _gauss2(ax, z, 0.0170, -0.0292, 0.0034, 0.0030) * front_mask
        y += 0.0010 * _gauss2(x, z, 0.0, -0.0205, 0.0022, 0.0032) * front_mask

        y += 0.0024 * _gauss2(x, z, 0.0, 0.0155, 0.0085, 0.0055) * front_mask
        nose_band = _smoothstep(0.022, 0.009, z) * _smoothstep(-0.0175, -0.009, z)
        bridge_w = 0.0035 + 0.0017 * _smoothstep(0.014, -0.011, z)
        bridge = math.exp(-0.5 * (x / bridge_w) ** 2) * nose_band * front_mask
        t_br = max(0.0, min(1.0, (0.015 - z) / 0.026))
        y -= (0.0032 + 0.0074 * t_br) * bridge
        tip = _gauss2(x, z, 0.0, -0.0112, 0.0055, 0.0049) * front_mask
        y -= 0.0048 * tip
        z += 0.0009 * tip
        y -= 0.0030 * _gauss2(ax, z, 0.0075, -0.0138, 0.0035, 0.0029) * front_mask
        y += 0.0014 * _gauss2(ax, z, 0.0110, -0.0138, 0.0020, 0.0028) * front_mask
        y -= 0.0016 * _gauss2(x, z, 0.0, -0.0154, 0.0020, 0.0022) * front_mask
        y += 0.0014 * _gauss2(ax, z, 0.0045, -0.0158, 0.0015, 0.0012) * front_mask

        ex = (ax - 0.0226) / 0.0124
        ez = z - 0.0092
        y += 0.0064 * _gauss2(ax, z, 0.0226, 0.0102, 0.0135, 0.0088) * front_mask
        if abs(ex) < 1.35 and abs(ez) < 0.015:
            almond_w = max(0.0, 1.0 - ex * ex)
            r_eb = math.hypot((ax - 0.0226) / 0.0106, ez / 0.0074)
            if r_eb < 1.0:
                y -= 0.0036 * math.sqrt(max(0.0, 1.0 - r_eb * r_eb)) * front_mask
            tilt = 0.0007 * ex
            lid_up_z = 0.0038 * (almond_w ** 0.62) + tilt
            lid_lo_z = -0.0030 * (almond_w ** 0.68) + tilt
            canthus_fade = _smoothstep(1.16, 0.16, abs(ex))

            up_rim = math.exp(-0.5 * ((ez - (lid_up_z + 0.0013)) / 0.0014) ** 2) * canthus_fade
            y -= 0.0034 * up_rim * front_mask
            crease = math.exp(-0.5 * ((ez - (lid_up_z + 0.0040)) / 0.0011) ** 2) * canthus_fade
            y += 0.0018 * crease * front_mask
            lo_rim = math.exp(-0.5 * ((ez - (lid_lo_z - 0.0010)) / 0.0013) ** 2) * canthus_fade
            y -= 0.0019 * lo_rim * front_mask

            in_open = _smoothstep(lid_lo_z - 0.0003, lid_lo_z + 0.0008, ez) * _smoothstep(lid_up_z + 0.0003, lid_up_z - 0.0008, ez) * _smoothstep(1.0, 0.12, abs(ex))
            lash_shadow = math.exp(-0.5 * ((ez - (lid_up_z - 0.0005)) / 0.0007) ** 2) * _smoothstep(1.0, 0.12, abs(ex))
            y += 0.0013 * lash_shadow * front_mask
            r_iris = math.hypot((ax - 0.0222) / 0.0046, (ez - 0.0005) / 0.0042)
            if r_iris < 1.15:
                iris_cup = math.cos(min(1.0, r_iris / 1.05) * math.pi * 0.5) ** 1.3
                pupil_pit = math.exp(-0.5 * (r_iris / 0.38) ** 2)
                y += (0.0010 * iris_cup + 0.0008 * pupil_pit) * in_open * front_mask

        brow_t = max(0.0, min(1.0, (ax - 0.0075) / 0.036))
        brow_z = 0.0226 + 0.0048 * math.sin(brow_t * math.pi * 0.84)
        brow_w = _smoothstep(0.0065, 0.014, ax) * _smoothstep(0.046, 0.032, ax)
        y -= 0.0024 * math.exp(-0.5 * ((z - brow_z) / 0.0034) ** 2) * brow_w * front_mask

        cheek = _gauss2(ax, z, 0.031, -0.006, 0.020, 0.018) * front_mask
        y -= 0.0058 * cheek
        x += math.copysign(0.0032 * cheek, ux)
        buccal = _gauss2(ax, z, 0.034, -0.033, 0.018, 0.018) * front_mask
        y -= 0.0022 * buccal
        x += math.copysign(0.0014 * buccal, ux)

    ear_mask = _smoothstep(0.049, 0.059, ax) * math.exp(-0.5 * ((y - 0.012) / 0.011) ** 2) * math.exp(-0.5 * ((z - (-0.014)) / 0.011) ** 2)
    if ear_mask > 0.01:
        er = math.hypot((y - 0.012) / 0.008, (z - (-0.014)) / 0.010)
        lobe = math.exp(-0.5 * (er / 0.75) ** 2) * ear_mask
        x += math.copysign(0.0040 * lobe, ux)

    part_dip = -0.005 * math.exp(-0.5 * ((x + 0.010) / 0.012) ** 2)
    scallop = 0.0028 * math.sin(x * 92.0 + 0.6)
    hl_front = 0.045 + part_dip + scallop - 0.040 * (min(1.0, ax / 0.058) ** 1.55)
    hl_z = hl_front - 0.102 * _smoothstep(-0.015, 0.050, y)

    cov = _smoothstep(hl_z - 0.008, hl_z + 0.012, z)
    if y < -0.025 and z < hl_front - 0.008:
        cov = 0.0

    if cov > 0.001:
        pomp_up = _gauss2(x, z, 0.016, 0.062, 0.026, 0.020) * _smoothstep(0.010, -0.075, y)
        side_l = _gauss2(x, z, 0.056, -0.004, 0.016, 0.026) * _smoothstep(-0.035, 0.060, y)
        side_r = _gauss2(x, z, -0.056, -0.004, 0.016, 0.026) * _smoothstep(-0.035, 0.060, y)
        nape_low = _gauss2(x, z, 0.0, -0.034, 0.046, 0.032) * _smoothstep(0.018, 0.082, y)

        rise = (cov ** 1.25) * (
            0.0056 + 0.014 * pomp_up + 0.013 * (side_l + side_r) + 0.012 * nape_low
        )
        s_warp = 1.6 * math.sin(y * 62.0 + x * 58.0)
        ph_wave = z * 142.0 + y * 84.0 + s_warp
        ph_comb = x * 295.0 - y * 120.0 + 1.1 * math.sin(z * 145.0)
        waves = (0.0038 * math.sin(ph_wave) + 0.0012 * math.sin(ph_comb)) * (cov ** 1.55)

        n_dir = Vector((ux / 0.063, uy / 0.084, uz / 0.090)).normalized()
        crest_vec = Vector((0.004, -0.004, 0.015)) * (pomp_up * (cov ** 1.25))
        return Vector((x, y, z)) + n_dir * (rise + waves) + crest_vec

    return Vector((x, y, z))


def _build_havis_head_and_neck(head_loc, head_rot, head_scale, neck_core_obj, bisect_co, bisect_no):
    """Sculpts Havis Amanda's graceful 19-year-old Parisian oval face, open classical bronze almond
    eyes, petite nose, softly parted Cupid's-bow lips, and silky 1908 Art Nouveau wavy coiffure +
    low chignon on a continuous subdivision-7 surface unified with `neck_core_obj`."""
    parts = []

    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=7, radius=1.0)
    for v in bm.verts:
        v.co = _eval_havis_head_and_hair_point(v.co.x, v.co.y, v.co.z)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    head_mesh = bpy.data.meshes.new("HavisHeadCore")
    bm.to_mesh(head_mesh)
    bm.free()
    head_obj = bpy.data.objects.new("HavisHeadCore", head_mesh)
    bpy.context.scene.collection.objects.link(head_obj)
    parts.append(head_obj)

    bm_locks = bmesh.new()

    _add_embedded_wave_tress(bm_locks, [
        (-0.008, -0.050, 0.058), (0.012, -0.060, 0.076), (0.032, -0.056, 0.076),
        (0.048, -0.034, 0.054), (0.058, -0.002, 0.028), (0.060, 0.034, 0.004),
    ], r_width=0.017, r_thick=0.011, ridges=4, ridge_amp=0.14, sink=0.58)

    _add_embedded_wave_tress(bm_locks, [
        (-0.012, -0.042, 0.074), (0.010, -0.048, 0.093), (0.028, -0.038, 0.092),
        (0.042, -0.008, 0.072), (0.044, 0.032, 0.044), (0.028, 0.072, 0.010),
    ], r_width=0.017, r_thick=0.011, ridges=4, ridge_amp=0.14, sink=0.60)

    _add_embedded_wave_tress(bm_locks, [
        (-0.010, -0.058, 0.052), (-0.036, -0.048, 0.036), (-0.056, -0.018, 0.016),
        (-0.064, 0.016, 0.000), (-0.058, 0.052, -0.016), (-0.028, 0.086, -0.036),
    ], r_width=0.017, r_thick=0.011, ridges=4, ridge_amp=0.15, sink=0.58)

    ret_rc = bmesh.ops.create_icosphere(bm_locks, subdivisions=3, radius=1.0)
    for v in ret_rc["verts"]:
        v.co = Vector((-0.060 + v.co.x * 0.018, 0.026 + v.co.y * 0.021, -0.001 + v.co.z * 0.020))
    rosette_pts = []
    for k in range(15):
        a = k * (math.pi * 2.5 / 14.0)
        r = 0.020 * (1.0 - 0.55 * (k / 14.0))
        rosette_pts.append((-0.069 + 0.003 * (k / 14.0), 0.026 + r * math.cos(a), -0.001 + r * math.sin(a)))
    _add_embedded_wave_tress(bm_locks, rosette_pts, r_width=0.011, r_thick=0.0085, ridges=3, ridge_amp=0.16, sink=0.50)

    _add_embedded_wave_tress(bm_locks, [
        (0.022, -0.056, 0.045), (0.046, -0.040, 0.026), (0.061, -0.010, 0.008),
        (0.067, 0.022, -0.004), (0.073, 0.048, 0.002), (0.060, 0.070, 0.008), (0.028, 0.088, -0.024),
    ], r_width=0.017, r_thick=0.011, ridges=4, ridge_amp=0.15, sink=0.54)

    ret_bun = bmesh.ops.create_icosphere(bm_locks, subdivisions=4, radius=1.0)
    for v in ret_bun["verts"]:
        ux, uy, uz = v.co.x, v.co.y, v.co.z
        ang = math.atan2(uz, ux)
        rad_r = math.hypot(ux, uz)
        groove = 1.0 + 0.10 * math.sin(rad_r * 13.0 + ang * 2.0)
        v.co = Vector((-0.008 + ux * 0.035 * groove, 0.092 + uy * 0.028 * groove, -0.041 + uz * 0.028 * groove))
    chig_pts = []
    for k in range(15):
        a = k * (math.pi * 2.4 / 14.0)
        r = 0.029 * (1.0 - 0.45 * (k / 14.0))
        chig_pts.append((-0.008 + r * math.cos(a) * 1.08, 0.103 + 0.007 * math.sin(a), -0.041 + r * math.sin(a) * 0.92))
    _add_embedded_wave_tress(bm_locks, chig_pts, r_width=0.013, r_thick=0.0095, ridges=4, ridge_amp=0.15, sink=0.55)

    bmesh.ops.recalc_face_normals(bm_locks, faces=bm_locks.faces)
    locks_mesh = bpy.data.meshes.new("HavisHairAccents")
    bm_locks.to_mesh(locks_mesh)
    bm_locks.free()
    locks_obj = bpy.data.objects.new("HavisHairAccents", locks_mesh)
    bpy.context.scene.collection.objects.link(locks_obj)
    parts.append(locks_obj)

    head_xform = Matrix.Translation(head_loc) @ head_rot.to_matrix().to_4x4() @ Matrix.Scale(head_scale, 4)
    head_inv = head_xform.inverted()
    for o in parts:
        o.matrix_world = head_xform
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    parts.append(neck_core_obj)
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = head_obj
    bpy.ops.object.join()
    full_head = bpy.context.view_layer.objects.active
    full_head.name = "HavisHeadNeck"

    rem = full_head.modifiers.new("HeadVoxel", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.00105
    rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)

    vg_melt = full_head.vertex_groups.new(name="NeckJawMelt")
    vg_silk = full_head.vertex_groups.new(name="HairSilk")
    vg_face = full_head.vertex_groups.new(name="FaceMicroPolish")
    vg_prot = full_head.vertex_groups.new(name="FaceHairProtect")
    for v in full_head.data.vertices:
        pl = head_inv @ v.co
        in_features = (pl.y < -0.035 and -0.046 <= pl.z <= 0.028 and abs(pl.x) < 0.042)
        in_face = (pl.y < 0.005 and -0.072 <= pl.z <= 0.044 and abs(pl.x) < 0.056)
        is_chin_tip = (pl.y < -0.052 and pl.z > -0.069 and abs(pl.x) < 0.018)

        if 5.280 <= v.co.z <= 5.405 and pl.z < -0.020 and not is_chin_tip and pl.y < 0.068:
            w_n = _smoothstep(5.280, 5.306, v.co.z) * _smoothstep(-0.018, -0.044, pl.z)
            vg_melt.add([v.index], 0.95 * w_n, "REPLACE")
        if not in_face and pl.z >= -0.046:
            vg_silk.add([v.index], 0.42, "REPLACE")
        if in_face:
            vg_face.add([v.index], 0.25, "REPLACE")

        if in_features:
            vg_prot.add([v.index], 0.05, "REPLACE")
        elif in_face:
            vg_prot.add([v.index], 0.11, "REPLACE")
        elif v.co.z > 5.33:
            vg_prot.add([v.index], 0.24, "REPLACE")
        else:
            vg_prot.add([v.index], 0.62, "REPLACE")

    sm_fc = full_head.modifiers.new("FacePolish", "SMOOTH")
    sm_fc.factor = 0.26
    sm_fc.iterations = 2
    sm_fc.vertex_group = "FaceMicroPolish"
    bpy.ops.object.modifier_apply(modifier=sm_fc.name)

    sm_hn = full_head.modifiers.new("NeckJawSmooth", "SMOOTH")
    sm_hn.factor = 0.55
    sm_hn.iterations = 14
    sm_hn.vertex_group = "NeckJawMelt"
    bpy.ops.object.modifier_apply(modifier=sm_hn.name)

    sm_sk = full_head.modifiers.new("HairSilkSmooth", "SMOOTH")
    sm_sk.factor = 0.40
    sm_sk.iterations = 3
    sm_sk.vertex_group = "HairSilk"
    bpy.ops.object.modifier_apply(modifier=sm_sk.name)

    _decimate_obj(full_head, 34000, vg_name="FaceHairProtect")

    vg_post = full_head.vertex_groups.new(name="PostDecimateSilk")
    for v in full_head.data.vertices:
        pl = head_inv @ v.co
        if pl.y < -0.032 and -0.048 <= pl.z <= 0.030 and abs(pl.x) < 0.044:
            vg_post.add([v.index], 0.20, "REPLACE")
    sm_pd = full_head.modifiers.new("PostFaceSilk", "SMOOTH")
    sm_pd.factor = 0.22
    sm_pd.iterations = 1
    sm_pd.vertex_group = "PostDecimateSilk"
    bpy.ops.object.modifier_apply(modifier=sm_pd.name)

    bm_cut = bmesh.new()
    bm_cut.from_mesh(full_head.data)
    bmesh.ops.bisect_plane(
        bm_cut,
        geom=bm_cut.verts[:] + bm_cut.edges[:] + bm_cut.faces[:],
        plane_co=bisect_co + bisect_no * 0.008,
        plane_no=bisect_no,
        clear_inner=True,
    )
    bmesh.ops.recalc_face_normals(bm_cut, faces=bm_cut.faces)
    bm_cut.to_mesh(full_head.data)
    bm_cut.free()
    return full_head


def _build_left_hand_under_chin(chin_world, body_obj):
    """Sculpts Havis Amanda's lyrically open, upward-cradling Belle Epoque LEFT HAND rising smoothly
    out of her real scan left forearm so four graceful feminine fingers cradle beneath `chin_world`."""
    bm = bmesh.new()

    def forearm_slice(z0):
        pts = [v.co for v in body_obj.data.vertices if abs(v.co.z - z0) < 0.010 and v.co.x > 0.080 and v.co.y < -0.050]
        if pts:
            mx = 0.5 * (min(p.x for p in pts) + max(p.x for p in pts))
            my = 0.5 * (min(p.y for p in pts) + max(p.y for p in pts))
            rx = 0.5 * (max(p.x for p in pts) - min(p.x for p in pts))
            return Vector((mx, my, z0)), max(0.022, min(0.031, rx * 0.90))
        return Vector((0.126, -0.108, z0)), 0.024

    c_23, _r_23 = forearm_slice(5.230)
    for v in body_obj.data.vertices:
        p = v.co
        if 5.230 <= p.z <= 5.285 and p.x > 0.082 and p.y < -0.048:
            t_w = _smoothstep(5.230, 5.256, p.z)
            v.co.x += (c_23.x - p.x) * 0.68 * t_w
            v.co.y += (c_23.y + 0.008 - p.y) * 0.68 * t_w
    body_obj.data.update()

    c_20, r_20 = forearm_slice(5.202)
    c_22, r_22 = forearm_slice(5.224)
    wrist = Vector((c_22.x + 0.004, c_22.y + 0.016, 5.248))

    mcp_idx  = Vector((chin_world.x - 0.015, chin_world.y - 0.032, chin_world.z - 0.024))
    palm_idx = wrist.lerp(mcp_idx, 0.52) + Vector((-0.002, -0.004, 0.002))

    u_step = Vector((0.0058, 0.0042, -0.0052))
    mcp_mid = mcp_idx + u_step * 0.95
    mcp_rng = mcp_idx + u_step * 1.88
    mcp_pnk = mcp_idx + u_step * 2.75

    palm_mid = palm_idx + u_step * 0.58
    palm_rng = palm_idx + u_step * 1.15
    palm_pnk = palm_idx + u_step * 1.68

    _add_tube_loft(bm, [c_20, c_22, wrist, palm_idx, mcp_idx], [r_20 * 0.88, r_22 * 0.92, 0.0205, 0.0162, 0.0104], segs=22, oval_aspect=0.80)
    _add_tube_loft(bm, [c_22, wrist + u_step * 0.28, palm_mid, mcp_mid], [r_22 * 0.80, 0.0182, 0.0154, 0.0102], segs=18, oval_aspect=0.80)
    _add_tube_loft(bm, [wrist + u_step * 0.55, palm_rng, mcp_rng], [0.0158, 0.0138, 0.0094], segs=16, oval_aspect=0.80)
    _add_tube_loft(bm, [wrist + u_step * 0.80, palm_pnk, mcp_pnk], [0.0135, 0.0118, 0.0082], segs=16, oval_aspect=0.80)
    _add_tube_loft(bm, [mcp_idx, mcp_mid, mcp_rng, mcp_pnk], [0.0094, 0.0098, 0.0090, 0.0076], segs=14, oval_aspect=0.86)

    def add_lyrical_finger(palm_p, mcp, pip, dip, tip, r0):
        _add_tube_loft(
            bm,
            [palm_p.lerp(mcp, 0.35), mcp, pip, dip, tip],
            [r0 * 1.15, r0, r0 * 0.85, r0 * 0.72, r0 * 0.56],
            segs=16, oval_aspect=0.93,
        )

    tip_idx = chin_world + Vector((-0.003, 0.002, 0.001))
    pip_idx = mcp_idx.lerp(tip_idx, 0.48) + Vector((-0.002, -0.009, 0.004))
    dip_idx = mcp_idx.lerp(tip_idx, 0.78) + Vector((-0.001, -0.004, 0.002))
    add_lyrical_finger(palm_idx, mcp_idx, pip_idx, dip_idx, tip_idx, 0.0076)

    tip_mid = chin_world + Vector((0.006, 0.010, -0.001))
    pip_mid = mcp_mid.lerp(tip_mid, 0.48) + Vector((0.000, -0.009, 0.004))
    dip_mid = mcp_mid.lerp(tip_mid, 0.78) + Vector((0.000, -0.004, 0.002))
    add_lyrical_finger(palm_mid, mcp_mid, pip_mid, dip_mid, tip_mid, 0.0074)

    tip_rng = chin_world + Vector((0.013, 0.017, -0.006))
    pip_rng = mcp_rng.lerp(tip_rng, 0.48) + Vector((0.002, -0.008, 0.003))
    dip_rng = mcp_rng.lerp(tip_rng, 0.78) + Vector((0.001, -0.004, 0.002))
    add_lyrical_finger(palm_rng, mcp_rng, pip_rng, dip_rng, tip_rng, 0.0069)

    tip_pnk = chin_world + Vector((0.019, 0.020, -0.015))
    pip_pnk = mcp_pnk.lerp(tip_pnk, 0.50) + Vector((0.003, -0.007, 0.003))
    dip_pnk = mcp_pnk.lerp(tip_pnk, 0.80) + Vector((0.002, -0.003, 0.001))
    add_lyrical_finger(palm_pnk, mcp_pnk, pip_pnk, dip_pnk, tip_pnk, 0.0060)

    th_cmc = wrist.lerp(palm_idx, 0.55) + Vector((-0.011, 0.005, 0.002))
    th_mcp = palm_idx.lerp(mcp_idx, 0.65) + Vector((-0.013, 0.008, 0.003))
    th_tip = mcp_idx + Vector((-0.012, 0.020, 0.016))
    _add_tube_loft(bm, [wrist + Vector((-0.005, 0.004, 0.0)), th_cmc, th_mcp, th_tip], [0.0110, 0.0098, 0.0082, 0.0064], segs=16, oval_aspect=0.92)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new("HavisLeftHand")
    bm.to_mesh(m)
    bm.free()
    o = bpy.data.objects.new("HavisLeftHand", m)
    bpy.context.scene.collection.objects.link(o)

    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    rem = o.modifiers.new("HandVoxel", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.0010
    rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)

    sm = o.modifiers.new("HandSmooth", "SMOOTH")
    sm.factor = 0.44
    sm.iterations = 5
    bpy.ops.object.modifier_apply(modifier=sm.name)
    _decimate_obj(o, 4200)
    return o


def _select_only_two_largest_boundary_loops(obj, z_min, z_max):
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(obj.data)
    for f in bm.faces:
        f.select = False
    for e in bm.edges:
        e.select = False
    for v in bm.verts:
        v.select = False

    cand_edges = set()
    for e in bm.edges:
        if e.is_boundary:
            zc = 0.5 * (e.verts[0].co.z + e.verts[1].co.z)
            if z_min <= zc <= z_max:
                cand_edges.add(e)

    loops = []
    visited = set()
    for e in cand_edges:
        if e in visited:
            continue
        comp = []
        stack = [e]
        visited.add(e)
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for v in cur.verts:
                for ne in v.link_edges:
                    if ne in cand_edges and ne not in visited:
                        visited.add(ne)
                        stack.append(ne)
        loops.append(comp)

    loops.sort(key=len, reverse=True)
    for comp in loops[:2]:
        for e in comp:
            e.select = True
            e.verts[0].select = True
            e.verts[1].select = True
    bmesh.update_edit_mesh(obj.data)


def _boolean_weld_hand(main_obj, hand_obj, wrist_center, wrist_radius):
    """Topologically unions `hand_obj` onto `main_obj` and smooths the wrist seam."""
    bpy.ops.object.select_all(action="DESELECT")
    main_obj.select_set(True)
    bpy.context.view_layer.objects.active = main_obj
    mod = main_obj.modifiers.new(f"Weld_{hand_obj.name}", "BOOLEAN")
    mod.operation = "UNION"
    mod.object = hand_obj
    for solver in ("FLOAT", "EXACT"):
        try:
            mod.solver = solver
            break
        except Exception:
            pass
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(hand_obj, do_unlink=True)

    wc = Vector(wrist_center)
    vg = main_obj.vertex_groups.new(name=f"Smooth_{wc.z:.2f}")
    for v in main_obj.data.vertices:
        d = (v.co - wc).length
        if d < wrist_radius:
            w = _smoothstep(wrist_radius, wrist_radius * 0.35, d)
            vg.add([v.index], 0.88 * w, "REPLACE")
    sm = main_obj.modifiers.new("WristWeldSmooth", "SMOOTH")
    sm.factor = 0.52
    sm.iterations = 8
    sm.vertex_group = vg.name
    bpy.ops.object.modifier_apply(modifier=sm.name)


def _add_profiled_loft(bm, ctrl_pts, rx_list, rz_list, segs=26, up_hint=Vector((0.0, 0.0, 1.0)), belly_flat=0.0, samples_per_seg=12):
    """Lofts a smooth organic body along `ctrl_pts` with C1-interpolated `(rx, rz)` cross-sections."""
    pts = _catmull_rom(ctrl_pts, samples_per_seg=samples_per_seg)
    n_pts = len(pts)
    n_ctrl = len(rx_list)
    rings = []
    prev_side = None
    for idx, pt in enumerate(pts):
        u = float(idx) / float(max(1, n_pts - 1)) * float(n_ctrl - 1)
        i0 = min(n_ctrl - 2, int(u))
        f = u - i0
        f_sm = f * f * (3.0 - 2.0 * f)
        rx = rx_list[i0] * (1.0 - f_sm) + rx_list[i0 + 1] * f_sm
        rz = rz_list[i0] * (1.0 - f_sm) + rz_list[i0 + 1] * f_sm
        if idx == 0:
            tang = (pts[1] - pts[0]).normalized()
        elif idx == len(pts) - 1:
            tang = (pts[-1] - pts[-2]).normalized()
        else:
            tang = (pts[idx + 1] - pts[idx - 1]).normalized()
        side = tang.cross(up_hint)
        if side.length < 1e-4:
            side = prev_side if prev_side is not None else Vector((1.0, 0.0, 0.0))
        side.normalize()
        if prev_side is not None and side.dot(prev_side) < 0.0:
            side = -side
        prev_side = side
        up_v = side.cross(tang).normalized()
        ring = []
        for s in range(segs):
            a = 2.0 * math.pi * s / segs
            ca, sa = math.cos(a), math.sin(a)
            if belly_flat > 0.0 and sa < 0.0:
                sa *= (1.0 - belly_flat)
            ring.append(bm.verts.new(pt + side * (ca * rx) + up_v * (sa * rz)))
        rings.append(ring)
    for j in range(len(rings) - 1):
        for s in range(segs):
            s2 = (s + 1) % segs
            bm.faces.new((rings[j][s], rings[j][s2], rings[j + 1][s2], rings[j + 1][s]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])


def _add_ribbed_fin(bm, root_pts, tip_pts, thickness=0.016, n_rays=7, camber_sign=1.0):
    """Sculpts a ribbed Art Nouveau bronze fin or overarching kelp leaf with scalloped webbing."""
    r_curve = _catmull_rom(root_pts, samples_per_seg=8)
    t_curve = _catmull_rom(tip_pts, samples_per_seg=8)
    n_u = min(len(r_curve), len(t_curve))
    n_v = 10
    grid_pos = []
    grid_neg = []
    for iu in range(n_u):
        su = float(iu) / float(max(1, n_u - 1))
        p_root = r_curve[iu]
        p_tip = t_curve[iu]
        iu0 = max(0, iu - 1)
        iu1 = min(n_u - 1, iu + 1)
        tang_u = (t_curve[iu1] - t_curve[iu0] + r_curve[iu1] - r_curve[iu0]).normalized()
        span_v = p_tip - p_root
        span_dir = span_v.normalized() if span_v.length > 1e-5 else Vector((1.0, 0.0, 0.0))
        nrm = tang_u.cross(span_dir)
        if nrm.length < 1e-5:
            nrm = Vector((0.0, 1.0, 0.0))
        nrm.normalize()

        ray_phase = su * float(n_rays - 1) * math.pi
        ray_ridge = abs(math.cos(ray_phase)) ** 1.35
        scallop = 1.0 - 0.14 * (1.0 - ray_ridge) * _smoothstep(0.0, 0.10, su) * _smoothstep(1.0, 0.90, su)
        edge_taper = math.sin(su * math.pi) ** 0.28

        row_p, row_n = [], []
        for iv in range(n_v):
            sv = float(iv) / float(n_v - 1)
            camber = camber_sign * 0.018 * math.sin(sv * math.pi)
            pt = p_root.lerp(p_root + span_v * scallop, sv) + nrm * camber
            th = thickness * (1.0 - 0.58 * (sv ** 0.85)) * (0.48 + 0.52 * edge_taper) * (0.38 + 1.05 * ray_ridge)
            row_p.append(bm.verts.new(pt + nrm * th))
            row_n.append(bm.verts.new(pt - nrm * th))
        grid_pos.append(row_p)
        grid_neg.append(row_n)

    for iu in range(n_u - 1):
        for iv in range(n_v - 1):
            bm.faces.new((grid_pos[iu][iv], grid_pos[iu + 1][iv], grid_pos[iu + 1][iv + 1], grid_pos[iu][iv + 1]))
            bm.faces.new((grid_neg[iu][iv], grid_neg[iu][iv + 1], grid_neg[iu + 1][iv + 1], grid_neg[iu + 1][iv]))
        bm.faces.new((grid_pos[iu][-1], grid_pos[iu + 1][-1], grid_neg[iu + 1][-1], grid_neg[iu][-1]))
        bm.faces.new((grid_neg[iu][0], grid_neg[iu + 1][0], grid_pos[iu + 1][0], grid_pos[iu][0]))
    for iv in range(n_v - 1):
        bm.faces.new((grid_neg[0][iv], grid_pos[0][iv], grid_pos[0][iv + 1], grid_neg[0][iv + 1]))
        bm.faces.new((grid_pos[-1][iv], grid_neg[-1][iv], grid_neg[-1][iv + 1], grid_pos[-1][iv + 1]))


def _build_single_sea_fish(azimuth_deg):
    """Sculpts one Ville Vallgren grotesque Art Nouveau sea-fish (4-fold Rudier-foundry symmetry)
    with sinuous S-curved body, flared grotesque upper snout, wide-hinged roaring lower jaw,
    deep hollow throat cavity, sharp-moated bulging eyes, layered rounded opercula, bold ribbed
    dorsal/pectoral/pelvic fins, and scrolled bilobed upturned tail."""
    bm = bmesh.new()

    spine = [
        (0.86,  0.36, 2.86),
        (0.79,  0.29, 2.69),
        (0.61,  0.19, 2.74),
        (0.44,  0.09, 2.89),
        (0.34,  0.01, 3.07),
        (0.36, -0.05, 3.25),
        (0.46, -0.095, 3.35),
        (0.55, -0.125, 3.355),
    ]
    rx_body = [0.024, 0.048, 0.076, 0.106, 0.128, 0.138, 0.132, 0.098]
    rz_body = [0.028, 0.054, 0.082, 0.112, 0.134, 0.144, 0.136, 0.102]
    _add_profiled_loft(bm, spine, rx_body, rz_body, segs=28, up_hint=Vector((0.0, 0.0, 1.0)), belly_flat=0.10, samples_per_seg=14)

    head_c = Vector((0.50, -0.105, 3.355))
    fwd = Vector((0.91, -0.24, -0.34)).normalized()
    up_h = Vector((-0.32, 0.08, 0.944)).normalized()
    side_h = fwd.cross(up_h).normalized()
    up_h = side_h.cross(fwd).normalized()

    def hpt(f_d, s_d, u_d):
        return head_c + fwd * f_d + side_h * s_d + up_h * u_d

    # Broad grotesque sea-dragon / catfish upper snout with upturned flared front lip (`357da6f1.jpg`)
    upper_jaw_pts = [
        hpt(-0.07, 0.0, 0.024),
        hpt( 0.03, 0.0, 0.042),
        hpt( 0.115, 0.0, 0.034),
        hpt( 0.180, 0.0, 0.020),
        hpt( 0.212, 0.0, 0.022),
    ]
    _add_profiled_loft(bm, upper_jaw_pts, [0.132, 0.124, 0.106, 0.078, 0.048], [0.092, 0.086, 0.068, 0.046, 0.028], segs=24, up_hint=up_h, belly_flat=0.24)

    # Flared curled upper lip & muscular cheek-hinge commissures + snout nostril bosses
    for sg in (-1.0, 1.0):
        cheek_bridge = [
            hpt(-0.01, sg * 0.086, 0.002),
            hpt( 0.045, sg * 0.080, -0.034),
            hpt( 0.065, sg * 0.070, -0.074),
        ]
        _add_profiled_loft(bm, cheek_bridge, [0.038, 0.034, 0.028], [0.040, 0.036, 0.032], segs=14, up_hint=up_h)

        ulip = [
            hpt(0.210, sg * 0.024, 0.018),
            hpt(0.168, sg * 0.066, 0.004),
            hpt(0.102, sg * 0.086, -0.018),
            hpt(0.048, sg * 0.086, -0.052),
        ]
        _add_profiled_loft(bm, ulip, [0.018, 0.022, 0.023, 0.019], [0.017, 0.021, 0.021, 0.018], segs=14, up_hint=up_h)

        # Raised Art Nouveau snout ridge / nostril boss on top of upper snout
        snout_ridge = [
            hpt(0.192, sg * 0.032, 0.034),
            hpt(0.145, sg * 0.046, 0.044),
            hpt(0.098, sg * 0.058, 0.052),
        ]
        _add_profiled_loft(bm, snout_ridge, [0.013, 0.016, 0.014], [0.012, 0.015, 0.013], segs=12, up_hint=up_h)

    # Wide-hinged roaring lower jaw dropping steeply (~52 deg) with curled chin hook (`357da6f1.jpg`)
    lower_jaw_pts = [
        hpt(-0.01, 0.0, -0.050),
        hpt( 0.048, 0.0, -0.092),
        hpt( 0.105, 0.0, -0.128),
        hpt( 0.142, 0.0, -0.134),
        hpt( 0.148, 0.0, -0.156),
    ]
    _add_profiled_loft(bm, lower_jaw_pts, [0.094, 0.080, 0.060, 0.040, 0.022], [0.048, 0.042, 0.034, 0.026, 0.018], segs=20, up_hint=up_h)

    for sg in (-1.0, 1.0):
        llip = [
            hpt(0.140, sg * 0.020, -0.130),
            hpt(0.098, sg * 0.054, -0.110),
            hpt(0.050, sg * 0.076, -0.068),
        ]
        _add_profiled_loft(bm, llip, [0.015, 0.019, 0.018], [0.015, 0.018, 0.017], segs=12, up_hint=up_h)

    # Bulging grotesque eyes + heavy arched supraorbital brows + layered rounded gill covers (opercula)
    eye_centers = []
    gill_centers = []
    for sg in (-1.0, 1.0):
        eye_c = hpt(0.094, sg * 0.080, 0.054)
        eye_centers.append((eye_c, sg))
        ret_e = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=0.027)
        for v in ret_e["verts"]:
            v.co += eye_c
        brow_pts = [
            hpt(0.136, sg * 0.060, 0.054),
            hpt(0.094, sg * 0.086, 0.080),
            hpt(0.046, sg * 0.096, 0.060),
        ]
        _add_profiled_loft(bm, brow_pts, [0.016, 0.022, 0.017], [0.016, 0.022, 0.017], segs=12, up_hint=up_h)

        gill_c = hpt(-0.022, sg * 0.112, 0.002)
        gill_centers.append((gill_c, sg))
        ret_g = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0)
        for v in ret_g["verts"]:
            p = v.co
            v.co = gill_c + fwd * (p.x * 0.076) + side_h * (p.y * 0.048) + up_h * (p.z * 0.084)

        # Secondary branchiostegal gill-arch fold behind/under main operculum (`357da6f1.jpg` left fish)
        gill_fold = [
            hpt(-0.055, sg * 0.108, 0.045),
            hpt(-0.082, sg * 0.118, -0.018),
            hpt(-0.068, sg * 0.094, -0.078),
        ]
        _add_profiled_loft(bm, gill_fold, [0.016, 0.021, 0.016], [0.016, 0.020, 0.015], segs=12, up_hint=up_h)

    # Radial dorsal fin crest bridging the curved neck into the central kelp rock (no floating wing gap!)
    dorsal_root = [
        (0.45, -0.09, 3.39),
        (0.37, -0.05, 3.33),
        (0.33,  0.00, 3.20),
        (0.33,  0.03, 3.05),
    ]
    dorsal_tip = [
        (0.28, -0.07, 3.46),
        (0.22, -0.03, 3.41),
        (0.20,  0.01, 3.27),
        (0.22,  0.04, 3.10),
    ]
    _add_ribbed_fin(bm, dorsal_root, dorsal_tip, thickness=0.020, n_rays=8, camber_sign=1.0)

    # Prominent scalloped pectoral fins flaring outward & slightly forward below the rounded opercula (`357da6f1.jpg`)
    for sg in (-1.0, 1.0):
        pec_root = [
            hpt(-0.05, sg * 0.108, -0.032),
            hpt(-0.10, sg * 0.106, -0.082),
            hpt(-0.15, sg * 0.096, -0.132),
        ]
        pec_tip = [
            hpt(-0.07, sg * 0.215, -0.042),
            hpt(-0.16, sg * 0.228, -0.125),
            hpt(-0.23, sg * 0.182, -0.215),
        ]
        _add_ribbed_fin(bm, pec_root, pec_tip, thickness=0.018, n_rays=6, camber_sign=sg * 0.85)

    pelv_root = [(0.50, 0.13, 2.91), (0.62, 0.20, 2.81)]
    pelv_tip  = [(0.60, 0.10, 2.99), (0.72, 0.18, 2.88)]
    _add_ribbed_fin(bm, pelv_root, pelv_tip, thickness=0.016, n_rays=5, camber_sign=0.7)

    # Lush scrolled Art Nouveau caudal tail fluke curling upward near the saucer rim
    tail_root = [
        (0.73, 0.25, 2.71),
        (0.81, 0.31, 2.77),
        (0.86, 0.36, 2.87),
    ]
    tail_tip = [
        (0.81, 0.36, 2.67),
        (0.94, 0.44, 2.80),
        (0.90, 0.40, 2.97),
    ]
    _add_ribbed_fin(bm, tail_root, tail_tip, thickness=0.017, n_rays=7, camber_sign=1.1)
    # Inner counter-curling tail scroll lobe (`357da6f1.jpg` bottom-left foreground tail curl)
    tail_scroll = [
        (0.76, 0.28, 2.75),
        (0.82, 0.30, 2.86),
        (0.78, 0.25, 2.94),
    ]
    _add_profiled_loft(bm, tail_scroll, [0.026, 0.020, 0.011], [0.018, 0.014, 0.008], segs=14, up_hint=Vector((0.0, 0.0, 1.0)))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new("SeaFishRaw")
    bm.to_mesh(m)
    bm.free()
    fish_obj = bpy.data.objects.new("SeaFish", m)
    bpy.context.scene.collection.objects.link(fish_obj)

    bpy.ops.object.select_all(action="DESELECT")
    fish_obj.select_set(True)
    bpy.context.view_layer.objects.active = fish_obj
    rem = fish_obj.modifiers.new("FishVoxel", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.0046
    rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)

    # Deep hollow roaring throat cavity carved between the upturned upper snout and dropped lower jaw
    bm_cut = bmesh.new()
    mouth_entry = hpt(0.175, 0.0, -0.052)
    throat_deep = hpt(0.028, 0.0, -0.028)
    cut_pts = [
        mouth_entry + fwd * 0.07,
        mouth_entry,
        mouth_entry.lerp(throat_deep, 0.50),
        throat_deep,
    ]
    _add_profiled_loft(bm_cut, cut_pts, [0.052, 0.048, 0.040, 0.022], [0.062, 0.056, 0.042, 0.022], segs=22, up_hint=up_h)
    bmesh.ops.recalc_face_normals(bm_cut, faces=bm_cut.faces)
    cm = bpy.data.meshes.new("MouthCutter")
    bm_cut.to_mesh(cm)
    bm_cut.free()
    cutter = bpy.data.objects.new("MouthCutter", cm)
    bpy.context.scene.collection.objects.link(cutter)

    bmod = fish_obj.modifiers.new("CarveMouth", "BOOLEAN")
    bmod.operation = "DIFFERENCE"
    bmod.object = cutter
    for solver in ("FLOAT", "EXACT"):
        try:
            bmod.solver = solver
            break
        except Exception:
            pass
    bpy.ops.object.modifier_apply(modifier=bmod.name)
    bpy.data.objects.remove(cutter, do_unlink=True)

    sm = fish_obj.modifiers.new("FishPolish", "SMOOTH")
    sm.factor = 0.34
    sm.iterations = 2
    bpy.ops.object.modifier_apply(modifier=sm.name)

    # Post-smooth analytical bronze relief pass: crisp circular orbital moats around eyeballs,
    # sharp operculum rear undercut groove, and nostril pits so dark bronze catches bold highlights!
    for v in fish_obj.data.vertices:
        p = v.co
        for eye_c, sg in eye_centers:
            dv = p - eye_c
            r_e = dv.length
            if 0.012 < r_e < 0.044:
                n_out = (side_h * sg * 0.82 + up_h * 0.42 + fwd * 0.38).normalized()
                # Ring moat right around eyeball perimeter (`r_e ~ 0.027`) + extra eyeball pop (`r_e < 0.022`)
                moat = math.exp(-0.5 * ((r_e - 0.0275) / 0.0048) ** 2)
                pop = math.exp(-0.5 * (r_e / 0.017) ** 2)
                v.co += n_out * (0.0055 * pop - 0.0065 * moat)
        for gill_c, sg in gill_centers:
            rel = p - gill_c
            df = rel.dot(fwd)
            du = rel.dot(up_h)
            ds = rel.dot(side_h) * sg
            # Rear/lower arc of the rounded operculum (`df ~ -0.055`)
            r_arc = math.hypot(df / 0.074, du / 0.082)
            if df < 0.01 and ds > 0.015 and 0.72 < r_arc < 1.28:
                groove = math.exp(-0.5 * ((r_arc - 1.02) / 0.09) ** 2) * _smoothstep(0.01, -0.025, df)
                v.co -= side_h * (sg * 0.0075 * groove)
        for sg in (-1.0, 1.0):
            nost_c = hpt(0.172, sg * 0.036, 0.036)
            dn = (p - nost_c).length
            if dn < 0.022:
                v.co -= (up_h * 0.7 + side_h * sg * 0.5 + fwd * 0.5).normalized() * (0.0055 * math.exp(-0.5 * (dn / 0.0075) ** 2))
    fish_obj.data.update()

    # Protect head & fin relief during decimation
    vg_f = fish_obj.vertex_groups.new(name="FishDetail")
    for v in fish_obj.data.vertices:
        if (v.co - head_c).length < 0.24:
            vg_f.add([v.index], 0.22, "REPLACE")
        else:
            vg_f.add([v.index], 0.65, "REPLACE")
    _decimate_obj(fish_obj, 5400, vg_name="FishDetail")

    rot_z = Matrix.Rotation(math.radians(azimuth_deg), 4, "Z")
    fish_obj.matrix_world = rot_z
    bpy.ops.object.select_all(action="DESELECT")
    fish_obj.select_set(True)
    bpy.context.view_layer.objects.active = fish_obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Water pour emerges from inside the gaping jaws and arcs steeply downward
    mouth_local = hpt(0.132, 0.0, -0.052)
    pour_dir_local = (fwd * 0.80 - up_h * 0.60).normalized()
    mouth_world = rot_z @ mouth_local
    dir_world = (rot_z.to_3x3() @ pour_dir_local).normalized()
    return fish_obj, mouth_world, dir_world


def _build_kelp_rock_and_sea_fish():
    """Builds the sculpted bronze kelp-draped rocky base + 4 Art Nouveau sea-fish (`z = 2.66..3.64 m`)."""
    bm = bmesh.new()

    # Central kelp-draped rock column rising up to z = 3.64 m so it merges seamlessly into
    # Havis Amanda's foot-rock (`z = 3.38..3.64`) with ZERO dark shadow gap above the fish necks!
    ret_r = bmesh.ops.create_icosphere(bm, subdivisions=5, radius=1.0)
    for v in ret_r["verts"]:
        p = v.co.copy()
        ang = math.atan2(p.y, p.x)
        t_h = 0.5 * (p.z + 1.0)
        n1 = noise.noise(Vector((p.x * 2.4 + 1.3, p.y * 2.4 - 0.8, p.z * 2.8)))
        n2 = noise.noise(Vector((p.x * 5.2 - 2.1, p.y * 5.2 + 1.7, p.z * 5.0)))
        kelp_flutes = 0.038 * math.sin(ang * 9.0 + t_h * 6.5 + n1 * 1.6) * _smoothstep(0.92, 0.10, t_h)
        wave_crest = 0.046 * math.exp(-0.5 * ((t_h - 0.28) / 0.14) ** 2) * (0.5 + 0.5 * math.cos(ang * 4.0 + 3.14))
        base_r = 0.49 - 0.16 * _smoothstep(0.0, 0.72, t_h) - 0.09 * _smoothstep(0.72, 1.0, t_h)
        rad = base_r * (1.0 + 0.10 * n1 + 0.04 * n2) + kelp_flutes + wave_crest
        z = 2.66 + t_h * 0.98
        v.co = Vector((p.x * rad, p.y * rad, max(2.66, z)))

    ret_b = bmesh.ops.create_icosphere(bm, subdivisions=5, radius=1.0)
    for v in ret_b["verts"]:
        p = v.co.copy()
        n1 = noise.noise(Vector((p.x * 3.0, p.y * 3.0, p.z * 2.0)))
        v.co = Vector((p.x * (0.85 + 0.04 * n1), p.y * (0.85 + 0.04 * n1), max(2.66, 2.675 + p.z * 0.050)))

    # Broad, rock-fused Art Nouveau swirling wave & bull-kelp scrolls between the 4 fish (`357da6f1.jpg` bottom-center!)
    # Rooted solidly inside the rock surface (no freestanding stalks or air gaps!) with overarching wave crests.
    for k in range(4):
        base_ang = math.radians(-88.0 + 90.0 * k)
        kelp_specs = [
            (-0.28,  0.18, 0.54, 0.44, 2.98, 0.072, 0.038),
            (-0.10,  0.26, 0.56, 0.45, 3.05, 0.082, 0.042),
            ( 0.08,  0.20, 0.55, 0.44, 3.00, 0.076, 0.040),
            ( 0.24, -0.16, 0.53, 0.43, 2.92, 0.068, 0.036),
        ]
        for da0, swirl, r0, r_top, z_top, w0, th0 in kelp_specs:
            a0 = base_ang + da0
            a1 = a0 + swirl * 0.45
            a2 = a0 + swirl * 0.95
            a3 = a0 + swirl * 1.30
            pts_k = [
                (math.cos(a0) * r0, math.sin(a0) * r0, 2.665),
                (math.cos(a1) * (0.5 * (r0 + r_top)), math.sin(a1) * (0.5 * (r0 + r_top)), 2.665 + (z_top - 2.665) * 0.48),
                (math.cos(a2) * r_top, math.sin(a2) * r_top, z_top),
                (math.cos(a3) * (r_top + 0.042), math.sin(a3) * (r_top + 0.042), z_top - 0.048),
            ]
            out_dir = Vector((math.cos(a1), math.sin(a1), 0.12)).normalized()
            _add_profiled_loft(
                bm, pts_k,
                [w0, w0 * 0.88, w0 * 0.68, w0 * 0.36],
                [th0, th0 * 0.92, th0 * 0.78, th0 * 0.45],
                segs=18, up_hint=out_dir, samples_per_seg=10,
            )

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new("KelpRockBase")
    bm.to_mesh(m)
    bm.free()
    rock_obj = bpy.data.objects.new("KelpRockBase", m)
    bpy.context.scene.collection.objects.link(rock_obj)

    bpy.ops.object.select_all(action="DESELECT")
    rock_obj.select_set(True)
    bpy.context.view_layer.objects.active = rock_obj
    rem = rock_obj.modifiers.new("RockVoxel", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.0065
    rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)

    sm = rock_obj.modifiers.new("RockSmooth", "SMOOTH")
    sm.factor = 0.40
    sm.iterations = 3
    bpy.ops.object.modifier_apply(modifier=sm.name)
    _decimate_obj(rock_obj, 6200)

    fish_objs = []
    fish_spouts = []
    for az in (-42.0, -132.0, 138.0, 48.0):
        fo, mp, md = _build_single_sea_fish(az)
        fish_objs.append(fo)
        fish_spouts.append((az, mp, md))

    bpy.ops.object.select_all(action="DESELECT")
    for o in [rock_obj] + fish_objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = rock_obj
    bpy.ops.object.join()
    base_assembly = bpy.context.view_layer.objects.active
    base_assembly.name = "HavisFishKelpBase"
    return base_assembly, fish_spouts


def _build_right_hand_on_hip():
    """Sculpts Havis Amanda's graceful RIGHT HAND resting softly over her right hip drapery."""
    bm = bmesh.new()
    arm_hi = Vector((-0.213, -0.068, 4.685))
    arm_lo = Vector((-0.210, -0.075, 4.632))
    wrist  = Vector((-0.202, -0.090, 4.585))
    palm_c = Vector((-0.186, -0.122, 4.544))

    mcp_idx = Vector((-0.162, -0.144, 4.512))
    mcp_mid = Vector((-0.173, -0.141, 4.503))
    mcp_rng = Vector((-0.184, -0.135, 4.494))
    mcp_pnk = Vector((-0.194, -0.126, 4.486))

    _add_tube_loft(bm, [arm_hi, arm_lo, wrist, palm_c, (mcp_idx + mcp_mid) * 0.5], [0.017, 0.021, 0.022, 0.022, 0.0165], segs=22, oval_aspect=0.76)
    _add_tube_loft(bm, [arm_lo + Vector((-0.004, 0.004, -0.004)), wrist + Vector((-0.004, 0.004, -0.004)), palm_c + Vector((-0.007, 0.006, -0.006)), (mcp_mid + mcp_rng) * 0.5], [0.019, 0.021, 0.0205, 0.0165], segs=16, oval_aspect=0.76)
    _add_tube_loft(bm, [wrist + Vector((-0.008, 0.008, -0.008)), palm_c + Vector((-0.014, 0.010, -0.012)), mcp_pnk], [0.0175, 0.0165, 0.0135], segs=14, oval_aspect=0.78)
    _add_tube_loft(
        bm,
        [mcp_idx + Vector((0.0, 0.005, 0.005)), mcp_mid + Vector((0.0, 0.005, 0.005)), mcp_rng + Vector((0.0, 0.005, 0.005)), mcp_pnk + Vector((0.0, 0.004, 0.005))],
        [0.0155, 0.0165, 0.0155, 0.0125],
        segs=14, oval_aspect=0.84,
    )

    th_cmc = palm_c + Vector((0.014, -0.007, 0.008))
    th_mcp = Vector((-0.155, -0.153, 4.526))
    th_ip  = Vector((-0.138, -0.156, 4.508))
    th_tip = Vector((-0.126, -0.148, 4.492))
    _add_tube_loft(bm, [wrist + Vector((0.010, -0.004, -0.014)), th_cmc, th_mcp, th_ip, th_tip], [0.0165, 0.0145, 0.0125, 0.0102, 0.0080], segs=14, oval_aspect=0.92)

    fingers = [
        (mcp_idx, Vector((-0.144, -0.150, 4.484)), Vector((-0.133, -0.140, 4.460)), Vector((-0.128, -0.125, 4.442)), 1.02),
        (mcp_mid, Vector((-0.155, -0.147, 4.472)), Vector((-0.146, -0.134, 4.448)), Vector((-0.142, -0.118, 4.432)), 1.04),
        (mcp_rng, Vector((-0.167, -0.140, 4.464)), Vector((-0.159, -0.127, 4.442)), Vector((-0.155, -0.112, 4.428)), 0.96),
        (mcp_pnk, Vector((-0.178, -0.130, 4.458)), Vector((-0.171, -0.118, 4.440)), Vector((-0.167, -0.105, 4.428)), 0.86),
    ]
    for mcp, pip, dip, tip, rs in fingers:
        _add_tube_loft(
            bm,
            [palm_c.lerp(mcp, 0.35), mcp, pip, dip, tip],
            [0.0128 * rs, 0.0106 * rs, 0.0092 * rs, 0.0080 * rs, 0.0064 * rs],
            segs=16, oval_aspect=0.94,
        )

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new("HavisRightHand")
    bm.to_mesh(m)
    bm.free()
    o = bpy.data.objects.new("HavisRightHand", m)
    bpy.context.scene.collection.objects.link(o)

    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    rem = o.modifiers.new("RHandVoxel", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.0013
    rem.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rem.name)

    sm = o.modifiers.new("RHandSmooth", "SMOOTH")
    sm.factor = 0.45
    sm.iterations = 3
    bpy.ops.object.modifier_apply(modifier=sm.name)
    _decimate_obj(o, 3600)
    return o


def _refine_havis_body(body, bisect_co, bisect_no):
    """Subdivides & refines the real Havis Amanda body from HavisAmanda.fbx with high-res front
    torso subdivision for sculpted classical breasts, areolae, bronze nipples, vertical-oval
    belly button, and collarbones while preserving her authentic stance, seaweed & 4 sea-fish."""
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-4)
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    body.data.validate()

    sub = body.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    bpy.ops.object.modifier_apply(modifier=sub.name)

    # Extra local high-res subdivision on front torso (breasts/nipples + belly/navel + collarbones)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for poly in body.data.polygons:
        c = poly.center
        if (4.66 <= c.z <= 5.23 and -0.21 <= c.x <= 0.12 and c.y < -0.06):
            poly.select = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.subdivide(number_cuts=2, smoothness=0.65)
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")

    vg = body.vertex_groups.new(name="WomanSkin")
    vg.add([v.index for v in body.data.vertices if 3.58 <= v.co.z <= 5.26], 1.0, "REPLACE")
    sm = body.modifiers.new("SkinSmooth", "CORRECTIVE_SMOOTH")
    sm.factor = 0.52
    sm.iterations = 5
    sm.smooth_type = "LENGTH_WEIGHTED"
    sm.vertex_group = "WomanSkin"
    bpy.ops.object.modifier_apply(modifier=sm.name)

    vg_fl = body.vertex_groups.new(name="FrontLeftThroatSmooth")
    for v in body.data.vertices:
        if v.co.z >= 5.215 and v.co.x > 0.035 and v.co.y < 0.020:
            vg_fl.add([v.index], 1.0, "REPLACE")
    sm_fl = body.modifiers.new("FLSmooth", "SMOOTH")
    sm_fl.factor = 0.55
    sm_fl.iterations = 10
    sm_fl.vertex_group = "FrontLeftThroatSmooth"
    bpy.ops.object.modifier_apply(modifier=sm_fl.name)

    bm = bmesh.new()
    bm.from_mesh(body.data)
    bmesh.ops.bisect_plane(
        bm,
        geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
        plane_co=bisect_co - bisect_no * 0.002,
        plane_no=bisect_no,
        clear_outer=True,
    )
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(body.data)
    bm.free()

    vg_heal = body.vertex_groups.new(name="TorsoHeal")
    for v in body.data.vertices:
        p = v.co
        in_belly = (4.68 <= p.z <= 4.86 and -0.12 <= p.x <= 0.05 and p.y < -0.10)
        in_axilla = (4.94 <= p.z <= 5.20 and 0.03 <= p.x <= 0.11 and -0.22 <= p.y <= -0.08)
        if in_belly or in_axilla:
            vg_heal.add([v.index], 1.0, "REPLACE")
    sm_h = body.modifiers.new("TorsoHealSmooth", "SMOOTH")
    sm_h.factor = 0.50
    sm_h.iterations = 8
    sm_h.vertex_group = "TorsoHeal"
    bpy.ops.object.modifier_apply(modifier=sm_h.name)

    def find_front_pt(x0, z0, rx=0.022, rz=0.022, ymax=-0.09, ymin=-0.22):
        cands = [v.co for v in body.data.vertices if abs(v.co.x - x0) <= rx and abs(v.co.z - z0) <= rz and ymin <= v.co.y <= ymax]
        if not cands:
            return Vector((x0, -0.16, z0))
        cands.sort(key=lambda p: p.y)
        top = cands[:max(3, len(cands) // 6)]
        return sum(top, Vector((0, 0, 0))) / len(top)

    rb_peak = find_front_pt(-0.106, 5.048, rx=0.022, rz=0.022, ymax=-0.10, ymin=-0.19)
    lb_peak = find_front_pt( 0.015, 5.044, rx=0.014, rz=0.022, ymax=-0.11, ymin=-0.19)
    navel_pt = find_front_pt(-0.036, 4.752, rx=0.020, rz=0.020, ymax=-0.12, ymin=-0.22)

    rb_dir = Vector((-0.22, -0.97, -0.03)).normalized()
    lb_dir = Vector(( 0.14, -0.99, -0.03)).normalized()

    # Pass 1: Silky spherical-teardrop classical breasts (smooth hemispherical dome, no conical point)
    for v in body.data.vertices:
        p = v.co
        if p.z < 4.88 or p.z > 5.22 or p.y >= -0.05:
            continue
        for b_pk, b_dir, b_amp, b_rx in ((rb_peak, rb_dir, 0.030, 0.054), (lb_peak, lb_dir, 0.028, 0.050)):
            dx = (p.x - b_pk.x) / b_rx
            dz_raw = p.z - (b_pk.z - 0.006)
            sz = 0.062 if dz_raw > 0 else 0.044
            dz = dz_raw / sz
            r = math.hypot(dx, dz)
            if r < 1.35 and abs(p.y - b_pk.y) < 0.065:
                u = min(1.0, r / 1.25)
                dome = math.cos(u * math.pi * 0.5) ** 1.35
                v.co += b_dir * (b_amp * dome)
        for b_pk, b_rx, side_s in ((rb_peak, 0.050, -1.0), (lb_peak, 0.046, 1.0)):
            if abs(p.x - b_pk.x) < 0.068 and abs(p.y - b_pk.y) < 0.060:
                ux_b = (p.x - b_pk.x) / b_rx
                crease_z = (b_pk.z - 0.058) + 0.018 * (ux_b * ux_b)
                inner_fade = _smoothstep(-0.045, -0.082, p.x) if side_s < 0 else _smoothstep(-0.038, -0.002, p.x)
                crease = math.exp(-0.5 * ((p.z - crease_z) / 0.016) ** 2) * math.exp(-0.5 * (ux_b / 1.08) ** 2) * inner_fade
                v.co.y += 0.010 * crease
        cleav = _gauss3(p, (-0.044, -0.145, 5.048), (0.026, 0.050, 0.050))
        v.co.y += 0.007 * cleav
    body.data.update()

    vg_chest = body.vertex_groups.new(name="ChestPolish")
    for v in body.data.vertices:
        if 4.92 <= v.co.z <= 5.19 and -0.19 <= v.co.x <= 0.08 and v.co.y < -0.09:
            vg_chest.add([v.index], 1.0, "REPLACE")
    sm_c = body.modifiers.new("ChestSmooth", "SMOOTH")
    sm_c.factor = 0.45
    sm_c.iterations = 4
    sm_c.vertex_group = "ChestPolish"
    bpy.ops.object.modifier_apply(modifier=sm_c.name)

    # Pass 2: Re-sample smoothed breast apices & carve crisp areolae, nipples, navel & collarbones
    rb_apex = find_front_pt(-0.106, 5.044, rx=0.020, rz=0.020, ymax=-0.12, ymin=-0.24)
    lb_apex = find_front_pt( 0.016, 5.040, rx=0.015, rz=0.020, ymax=-0.12, ymin=-0.24)
    rn_c = Vector((rb_apex.x - 0.005, rb_apex.y, rb_apex.z - 0.002))
    ln_c = Vector((lb_apex.x + 0.002, lb_apex.y, lb_apex.z - 0.002))

    for v in body.data.vertices:
        p = v.co
        if p.z < 3.70 or p.z > 5.23:
            continue
        if p.y < -0.05:
            for nc, ndir in ((rn_c, rb_dir), (ln_c, lb_dir)):
                d_xz = math.hypot(p.x - nc.x, p.z - nc.z)
                if d_xz < 0.034 and abs(p.y - nc.y) < 0.055:
                    areola = math.exp(-0.5 * (d_xz / 0.0145) ** 2)
                    nip = math.exp(-0.5 * (d_xz / 0.0056) ** 2)
                    v.co += ndir * (0.0034 * areola + 0.0068 * nip)

            dn_x = (p.x - navel_pt.x)
            dn_z = (p.z - navel_pt.z)
            if abs(dn_x) < 0.038 and abs(dn_z) < 0.045 and abs(p.y - navel_pt.y) < 0.045:
                pit = math.exp(-0.5 * ((dn_x / 0.0078) ** 2 + (dn_z / 0.0108) ** 2))
                hood = math.exp(-0.5 * ((dn_x / 0.0135) ** 2 + ((dn_z - 0.0130) / 0.0055) ** 2))
                v.co.y += 0.0150 * pit - 0.0028 * hood
                v.co.z -= 0.0015 * pit

            if 5.14 <= p.z <= 5.23:
                if -0.14 <= p.x <= -0.01:
                    clav_z = 5.188 + (-p.x - 0.01) * 0.16
                    clav = math.exp(-0.5 * ((p.z - clav_z) / 0.008) ** 2) * _smoothstep(-0.145, -0.11, p.x) * _smoothstep(-0.005, -0.025, p.x)
                    v.co.y -= 0.0038 * clav
                notch = _gauss3(p, (-0.005, -0.095, 5.195), (0.018, 0.045, 0.016))
                v.co.y += 0.0045 * notch

            v.co.y -= 0.005 * _gauss3(p, (0.032, -0.350, 4.185), (0.036, 0.040, 0.038))
        if p.y > 0.05 and 4.65 <= p.z <= 5.16:
            spine_x = -0.045 + 0.04 * (p.z - 4.70) / 0.45
            spine = math.exp(-0.5 * ((p.x - spine_x) / 0.018) ** 2) * _smoothstep(4.65, 4.75, p.z) * _smoothstep(5.16, 5.05, p.z)
            v.co.y -= 0.005 * spine
    body.data.update()
    return rn_c, ln_c, navel_pt


def extract_havis_amanda():
    """Builds the high-detail real-life Havis Amanda mermaid + 4 sea-fish (`havis_amanda_figure.glb`),
    the sculpted dark-bronze rocky pedestal + drum (`havis_amanda_pedestal.glb`), and the real
    bronze rim sea lion (`sea_lion.glb`) from the Helsinki laser scan."""
    # 1. High-detail Havis Amanda mermaid + 4 spouting sea-fish (z >= 2.66 m above scan base, r <= 1.25 m)
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=HAVIS_FBX)
    body = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    body.name = "HavisBody"
    bpy.context.view_layer.objects.active = body
    body.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    verts = [v.co for v in body.data.vertices]
    zmin = min(v.z for v in verts)
    cx = 0.5 * (min(v.x for v in verts) + max(v.x for v in verts))
    cy = 0.5 * (min(v.y for v in verts) + max(v.y for v in verts))
    for v in body.data.vertices:
        v.co = Vector((v.co.x - cx, v.co.y - cy, v.co.z - zmin))
    body.data.update()

    bm = bmesh.new()
    bm.from_mesh(body.data)
    del_verts = [v for v in bm.verts if v.co.z < 3.36 or math.hypot(v.co.x, v.co.y) > 0.85]
    bmesh.ops.delete(bm, geom=del_verts, context="VERTS")
    res_bot = bmesh.ops.bisect_plane(
        bm,
        geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
        plane_co=Vector((0.0, 0.0, 3.38)),
        plane_no=Vector((0.0, 0.0, 1.0)),
        clear_inner=True,
    )
    cut_bot = [g for g in res_bot["geom_cut"] if isinstance(g, bmesh.types.BMEdge)]
    if cut_bot:
        bmesh.ops.holes_fill(bm, edges=cut_bot, sides=200)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(body.data)
    bm.free()

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    top_idx = max(range(len(body.data.vertices)), key=lambda i: body.data.vertices[i].co.z)
    body.data.vertices[top_idx].select = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_linked()
    bpy.ops.mesh.select_all(action="INVERT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")

    # Smoothly tuck any outer melted fish remnants below Havis Amanda's ankles (`z = 3.38..3.53`)
    # inside the sculpted kelp rock column so there are ZERO jagged edges or seams!
    for v in body.data.vertices:
        p = v.co
        if p.z <= 3.53:
            r_xy = math.hypot(p.x, p.y)
            r_cap = 0.24 + 0.15 * _smoothstep(3.38, 3.53, p.z)
            if r_xy > r_cap and r_xy > 1e-5:
                s_in = r_cap / r_xy
                v.co.x *= s_in
                v.co.y *= s_in
        if p.z >= 5.238 and p.x > 0.056 and p.y < 0.005:
            lh_m = _smoothstep(5.238, 5.276, p.z) * _smoothstep(0.056, 0.105, p.x) * _smoothstep(0.005, -0.045, p.y)
            v.co.x += (0.058 - v.co.x) * 0.85 * lh_m
            v.co.y += (-0.005 - v.co.y) * 0.85 * lh_m
        if 4.36 <= p.z <= 4.62 and p.x < -0.10 and p.y < -0.04:
            rh_m = _smoothstep(4.36, 4.43, p.z) * _smoothstep(4.62, 4.55, p.z) * _smoothstep(-0.10, -0.16, p.x) * _smoothstep(-0.04, -0.09, p.y)
            if rh_m > 0.005:
                v.co.y += 0.050 * rh_m
                v.co.x += 0.030 * rh_m
    body.data.update()

    bisect_co = Vector((0.04, 0.03, 5.286))
    bisect_no = Vector((0.16, -0.14, 1.0)).normalized()

    bm = bmesh.new()
    bm.from_mesh(body.data)
    bmesh.ops.bisect_plane(
        bm,
        geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
        plane_co=bisect_co,
        plane_no=bisect_no,
        clear_outer=True,
    )
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(body.data)
    bm.free()

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    chest_idx = min(range(len(body.data.vertices)), key=lambda i: (body.data.vertices[i].co - Vector((0.0, 0.0, 4.8))).length)
    body.data.vertices[chest_idx].select = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_linked()
    bpy.ops.mesh.select_all(action="INVERT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")

    rn_c, ln_c, navel_pt = _refine_havis_body(body, bisect_co, bisect_no)

    vg_dec = body.vertex_groups.new(name="WomanProtect")
    for v in body.data.vertices:
        p = v.co
        near_rn = (math.hypot(p.x - rn_c.x, p.z - rn_c.z) < 0.055 and p.y < -0.10)
        near_ln = (math.hypot(p.x - ln_c.x, p.z - ln_c.z) < 0.055 and p.y < -0.10)
        near_nv = (math.hypot(p.x - navel_pt.x, p.z - navel_pt.z) < 0.036 and p.y < -0.10)
        if near_rn or near_ln or near_nv or p.z >= 5.22:
            vg_dec.add([v.index], 0.05, "REPLACE")
        elif p.z >= 3.55:
            vg_dec.add([v.index], 0.35, "REPLACE")
        else:
            vg_dec.add([v.index], 0.80, "REPLACE")
    _decimate_obj(body, 21000, vg_name="WomanProtect")

    head_scale = 1.33
    head_rot = Euler((math.radians(8.5), math.radians(12.5), math.radians(55.0)), "XYZ")
    head_loc = Vector((0.106, 0.024, 5.394))

    loop_pts = _extract_ordered_neck_loop(body, z_min=5.24)
    neck_core = _build_loop_lofted_neck(loop_pts, bisect_no, head_loc, head_rot, head_scale)
    head_neck = _build_havis_head_and_neck(head_loc, head_rot, head_scale, neck_core, bisect_co, bisect_no)

    R_inv = head_rot.to_matrix().inverted()
    chin_cands = []
    for v in head_neck.data.vertices:
        pl = (R_inv @ (v.co - head_loc)) / head_scale
        if abs(pl.x) < 0.016 and -0.076 <= pl.z <= -0.056 and pl.y < -0.045:
            chin_cands.append(v.co.copy())
    if chin_cands:
        chin_world = min(chin_cands, key=lambda p: p.z - 0.20 * p.x)
    else:
        chin_world = head_loc + (head_rot.to_matrix() @ (Vector((0.0, -0.068, -0.068)) * head_scale))

    lhand = _build_left_hand_under_chin(chin_world, body)
    rhand = _build_right_hand_on_hip()
    fish_kelp_base, fish_spouts = _build_kelp_rock_and_sea_fish()

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    head_neck.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    welded = bpy.context.view_layer.objects.active

    _select_only_two_largest_boundary_loops(welded, 5.245, 5.348)
    bpy.ops.mesh.bridge_edge_loops(type="PAIRS", number_cuts=3, interpolation="SURFACE", smoothness=0.85)
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")

    vg_weld = welded.vertex_groups.new(name="NeckWeld")
    for v in welded.data.vertices:
        pl = (R_inv @ (v.co - head_loc)) / head_scale
        is_chin = (pl.y < -0.044 and pl.z > -0.073)
        is_bun = (pl.y > 0.068 and pl.z > -0.068)
        if 5.225 <= v.co.z <= 5.355 and not is_chin and not is_bun:
            w = _smoothstep(5.225, 5.265, v.co.z) * _smoothstep(5.358, 5.322, v.co.z)
            vg_weld.add([v.index], w, "REPLACE")
    sm_w = welded.modifiers.new("NeckWeldSmooth", "SMOOTH")
    sm_w.factor = 0.55
    sm_w.iterations = 16
    sm_w.vertex_group = "NeckWeld"
    bpy.ops.object.modifier_apply(modifier=sm_w.name)

    _boolean_weld_hand(welded, lhand, (0.126, -0.105, 5.228), 0.044)
    _boolean_weld_hand(welded, rhand, (-0.210, -0.075, 4.655), 0.048)

    bpy.ops.object.select_all(action="DESELECT")
    welded.select_set(True)
    fish_kelp_base.select_set(True)
    bpy.context.view_layer.objects.active = welded
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active

    # Compute exact pre-normalization bounds so we can print normalized Godot fish mouth coords!
    all_vs = [v.co.copy() for v in obj.data.vertices]
    mn_f = Vector((min(v.x for v in all_vs), min(v.y for v in all_vs), min(v.z for v in all_vs)))
    mx_f = Vector((max(v.x for v in all_vs), max(v.y for v in all_vs), max(v.z for v in all_vs)))
    sc_f = 1.0 / max(mx_f.z - mn_f.z, 1e-5)
    cx_f, cy_f = 0.5 * (mn_f.x + mx_f.x), 0.5 * (mn_f.y + mx_f.y)
    for az, mp, md in fish_spouts:
        mp_n = Vector(((mp.x - cx_f) * sc_f, (mp.z - mn_f.z) * sc_f, -(mp.y - cy_f) * sc_f))
        md_n = Vector((md.x, md.z, -md.y)).normalized()
        print(f"[fish_spout] az={az:+6.1f} mouth_godot=({mp_n.x:+.4f}, {mp_n.y:+.4f}, {mp_n.z:+.4f}) dir_godot=({md_n.x:+.4f}, {md_n.y:+.4f}, {md_n.z:+.4f})", flush=True)

    finalize_and_export(obj, "havis_amanda_figure", target_tris=96000, rot_deg=(0.0, 0.0, 0.0), norm_axis="Z")

    # 2. Real sculpted dark-bronze rocky seaweed pedestal + fluted drum + beaded capital frieze (z = 0.58..2.38 m)
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=HAVIS_FBX)
    ped = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = ped
    ped.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    bm = bmesh.new()
    bm.from_mesh(ped.data)
    del_verts = [
        v for v in bm.verts
        if (v.co.z - zmin) < 0.58 or (v.co.z - zmin) > 2.38 or math.hypot(v.co.x - cx, v.co.y - cy) > 1.22
    ]
    bmesh.ops.delete(bm, geom=del_verts, context="VERTS")
    bm.to_mesh(ped.data)
    bm.free()

    # Keep only the main connected pedestal island (drop any stray floating fragments)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    mid_idx = min(range(len(ped.data.vertices)), key=lambda i: (ped.data.vertices[i].co - Vector((cx, cy, zmin + 1.5))).length)
    ped.data.vertices[mid_idx].select = True
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_linked()
    bpy.ops.mesh.select_all(action="INVERT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")

    finalize_and_export(ped, "havis_amanda_pedestal", target_tris=8500, rot_deg=(0.0, 0.0, 0.0), norm_axis="Z")

    # 3. One REAL Ville Vallgren bronze sea lion from the +45 deg rim pedestal
    # The granite rim top sits at h = 0.98 m; crop cleanly at h = 1.00 m so the full
    # belly, front flippers, rear flippers and curled tail stay 100% intact above the granite!
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
        # Keep the full sea lion at angle ~45 deg above its granite rim top (h >= 0.985 m)
        if not (0.985 <= h <= 2.35 and 4.45 <= r <= 6.05 and 38.0 <= ang <= 52.0):
            del_verts.append(v)
    bmesh.ops.delete(bm, geom=del_verts, context="VERTS")
    # Clean flat bottom cut right at the granite rim top (zmin + 1.005 m) and cap cleanly
    res = bmesh.ops.bisect_plane(
        bm,
        geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
        plane_co=Vector((cx, cy, zmin + 1.005)),
        plane_no=Vector((0.0, 0.0, 1.0)),
        clear_inner=True,
    )
    cut_edges = [g for g in res["geom_cut"] if isinstance(g, bmesh.types.BMEdge)]
    if cut_edges:
        bmesh.ops.holes_fill(bm, edges=cut_edges, sides=200)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()

    # Keep only largest connected island (the sea lion itself)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
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
    # Print normalized bounds & mouth tip (highest-Z front vertex) for exact spout alignment
    svs = [v.co for v in obj.data.vertices]
    mouth_v = max(svs, key=lambda v: v.z - v.y * 0.25)
    print(f"[sea_lion] bounds x=[{min(v.x for v in svs):.3f},{max(v.x for v in svs):.3f}] y=[{min(v.y for v in svs):.3f},{max(v.y for v in svs):.3f}] z=[{min(v.z for v in svs):.3f},{max(v.z for v in svs):.3f}] mouth_godot=({mouth_v.x:.3f}, {mouth_v.z:.3f}, {-mouth_v.y:.3f})", flush=True)


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
    if "--only-havis" not in sys.argv:
        build_trevi_reef()
    print("HAVIS AMANDA REAL SCAN BUILT", flush=True)
