#!/usr/bin/env python3
"""
Reproducible Blender 5.3 Baroque hero sculpt pipeline for Trevi Fountain (Rome).

Generates high-detail, clean-UV binary .glb architectural & sculptural assets under
assets/landmarks/trevi/:
  - trevi_exedra_apse.glb    (real metres; true deep semicircular coffered exedra & rosette half-dome)
  - trevi_baroque_reef.glb   (real metres; chiseled Roman travertine cliff, grotto arches, flat statue
                              plinths & concave waterfall spill lips at documented coordinates)
  - trevi_horse_wild.glb     (height=1.0 m; base-trimmed CC0 horse posed as Rough Sea rearing +22 deg)
  - trevi_horse_calm.glb     (height=1.0 m; base-trimmed CC0 horse posed as Calm Sea placid stride)
  - trevi_shell_chariot.glb  (real metres; deeply fluted Baroque scalloped cockleshell chariot)
  - trevi_relief_agrippa.glb (width=1.0 m; framed carved marble bas-relief panel, Agrippa & aqueduct)
  - trevi_relief_virgo.glb   (width=1.0 m; framed carved marble bas-relief panel, Aqua Virgo maiden)
  - trevi_papal_crest.glb    (real metres; Clement XII escutcheon, triple tiara, crossed keys & reclining Fames)
  - trevi_corner_mask.glb    (height=1.0 m; carved Baroque lion/water-mask basin spout)

Coordinate convention in exported glTF / Godot space:
  - Y-up, resting on y = 0.0
  - Front faces +Z (which is -Y in Blender Z-up space)

Usage:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/build_trevi_assets.py
"""

import bpy
import bmesh
import json
import math
import os
import random
import urllib.request
from mathutils import Euler, Matrix, Vector, noise

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "landmarks", "trevi")
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


def decimate_to(obj, target_tris):
    bpy.context.view_layer.objects.active = obj
    tri_count = sum(max(len(p.vertices) - 2, 1) for p in obj.data.polygons)
    if tri_count > target_tris:
        dec = obj.modifiers.new("Decimate", "DECIMATE")
        dec.ratio = max(0.02, float(target_tris) / float(tri_count))
        bpy.ops.object.modifier_apply(modifier=dec.name)


def add_meta_capsule(mball, p0, p1, r0, r1, steps=6, stiffness=2.0):
    v0, v1 = Vector(p0), Vector(p1)
    for i in range(steps):
        t = i / max(steps - 1, 1)
        el = mball.elements.new(type="BALL")
        el.co = v0.lerp(v1, t)
        el.radius = r0 + (r1 - r0) * t
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


def finish_and_export(obj, filename, norm_mode="none", target_tris=0, preserve_origin=False):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    if target_tris > 0:
        decimate_to(obj, target_tris)

    if not preserve_origin:
        verts = [v.co for v in obj.data.vertices]
        min_x = min(v.x for v in verts)
        max_x = max(v.x for v in verts)
        min_y = min(v.y for v in verts)
        max_y = max(v.y for v in verts)
        min_z = min(v.z for v in verts)
        max_z = max(v.z for v in verts)
        cx = 0.5 * (min_x + max_x)
        cy = 0.5 * (min_y + max_y)
        dx, dy, dz = max_x - min_x, max_y - min_y, max_z - min_z

        if norm_mode == "height":
            s = 1.0 / max(dz, 1e-4)
        elif norm_mode == "width":
            s = 1.0 / max(dx, 1e-4)
        else:
            s = 1.0

        for v in obj.data.vertices:
            v.co = Vector(((v.co.x - cx) * s, (v.co.y - cy) * s, (v.co.z - min_z) * s))
        obj.data.update()

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()

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
                uv_layer[li].uv = (co.x * 0.35, co.y * 0.35)
            elif ax >= ay:
                uv_layer[li].uv = (co.y * 0.35, co.z * 0.35)
            else:
                uv_layer[li].uv = (co.x * 0.35, co.z * 0.35)

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
    print(f"[trevi] {filename}: {tris} tris, {sz:.1f} KB", flush=True)


# ---------------------------------------------------------------------------
# 1. True Deep Semicircular Coffered Exedra Apse & Rosette Half-Dome
# ---------------------------------------------------------------------------
def build_exedra_apse():
    """
    Built in REAL METRES, centered at (0, 0, 0) where front arch plane is Y = 0
    and the semicircular concave apse recesses into +Y (which is -Z in Godot!).
    Springing height Z = 9.0 m, radius R = 4.1 m, apex Z = 13.1 m.
    """
    clear_scene()
    parts = []
    R = 4.10
    H_SPRING = 9.0
    T = 0.45  # wall shell thickness

    # Concave cylindrical lower apse wall (Z = 0..9.0 m, theta = 0..pi into +Y)
    bm = bmesh.new()
    segs_u = 28
    segs_z = 8
    inner_grid = []
    outer_grid = []
    for j in range(segs_z + 1):
        z = H_SPRING * j / segs_z
        row_in, row_out = [], []
        for i in range(segs_u + 1):
            a = math.pi * i / segs_u  # 0 (+X) -> pi (-X), sin(a) >= 0 (+Y recess)
            ca, sa = math.cos(a), math.sin(a)
            row_in.append(bm.verts.new((ca * R, sa * R, z)))
            row_out.append(bm.verts.new((ca * (R + T), sa * (R + T), z)))
        inner_grid.append(row_in)
        outer_grid.append(row_out)

    for j in range(segs_z):
        for i in range(segs_u):
            # Inner concave face (normals point toward center / -Y)
            bm.faces.new((inner_grid[j][i], inner_grid[j + 1][i], inner_grid[j + 1][i + 1], inner_grid[j][i + 1]))
            # Outer backing face
            bm.faces.new((outer_grid[j][i], outer_grid[j][i + 1], outer_grid[j + 1][i + 1], outer_grid[j + 1][i]))
    # Front vertical jamb caps at i=0 and i=segs_u
    for j in range(segs_z):
        bm.faces.new((inner_grid[j][0], outer_grid[j][0], outer_grid[j + 1][0], inner_grid[j + 1][0]))
        bm.faces.new((outer_grid[j][segs_u], inner_grid[j][segs_u], inner_grid[j + 1][segs_u], outer_grid[j + 1][segs_u]))

    # Semicircular concave coffered half-dome (Z = 9.0..13.1 m)
    rings_phi = 14
    dome_in, dome_out = [], []
    for jp in range(rings_phi + 1):
        phi = 0.5 * math.pi * jp / rings_phi  # 0 at springing -> pi/2 at crown
        cp, sp = math.cos(phi), math.sin(phi)
        r_in_row, r_out_row = [], []
        for i in range(segs_u + 1):
            a = math.pi * i / segs_u
            ca, sa = math.cos(a), math.sin(a)
            # Carve real sunken coffers in a 7-column x 4-row grid on the inner half-dome!
            coffer_u = (a / math.pi) * 7.0
            coffer_v = (phi / (0.5 * math.pi)) * 4.0
            fu = coffer_u - math.floor(coffer_u)
            fv = coffer_v - math.floor(coffer_v)
            in_coffer = (0.18 < fu < 0.82) and (0.18 < fv < 0.82) and (jp < rings_phi - 1)
            recess = 0.22 if in_coffer else 0.0
            rr = R + recess
            r_in_row.append(bm.verts.new((ca * cp * rr, sa * cp * rr, H_SPRING + sp * rr)))
            r_out_row.append(bm.verts.new((ca * cp * (R + T), sa * cp * (R + T), H_SPRING + sp * (R + T))))
        dome_in.append(r_in_row)
        dome_out.append(r_out_row)

    for jp in range(rings_phi):
        for i in range(segs_u):
            bm.faces.new((dome_in[jp][i], dome_in[jp + 1][i], dome_in[jp + 1][i + 1], dome_in[jp][i + 1]))
            bm.faces.new((dome_out[jp][i], dome_out[jp][i + 1], dome_out[jp + 1][i + 1], dome_out[jp + 1][i]))
    # Front semicircular archivolt face cap (at i=0 and i=segs_u, Y=0)
    for jp in range(rings_phi):
        bm.faces.new((dome_in[jp][0], dome_out[jp][0], dome_out[jp + 1][0], dome_in[jp + 1][0]))
        bm.faces.new((dome_out[jp][segs_u], dome_in[jp][segs_u], dome_in[jp + 1][segs_u], dome_out[jp + 1][segs_u]))

    apse_mesh = bpy.data.meshes.new("ExedraApse")
    bm.to_mesh(apse_mesh)
    bm.free()
    apse_obj = bpy.data.objects.new("ExedraApse", apse_mesh)
    bpy.context.collection.objects.link(apse_obj)
    parts.append(apse_obj)

    # Raised carved Baroque rosettes centered inside every half-dome coffer
    for row in range(3):
        phi = 0.5 * math.pi * (row + 0.5) / 4.0
        for col in range(7):
            a = math.pi * (col + 0.5) / 7.0
            pos = Vector((math.cos(a) * math.cos(phi) * (R + 0.14),
                          math.sin(a) * math.cos(phi) * (R + 0.14),
                          H_SPRING + math.sin(phi) * (R + 0.14)))
            bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.22)
            ros = bpy.context.active_object
            ros.scale = (1.0, 0.55, 1.0)
            ros.location = pos
            parts.append(ros)

    # Projecting semicircular moulded archivolt & sculpted Baroque keystone on front arch face (Y = -0.25)
    for k in range(24):
        a0 = math.pi * k / 24.0
        a1 = math.pi * (k + 1) / 24.0
        am = 0.5 * (a0 + a1)
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        vous = bpy.context.active_object
        vous.scale = (0.62, 0.65, 0.72)
        vous.location = (math.cos(am) * (R + 0.34), -0.18, H_SPRING + math.sin(am) * (R + 0.34))
        vous.rotation_euler = Euler((0.0, -(am - math.pi * 0.5), 0.0), "XYZ")
        parts.append(vous)

    # Impost cornice ring inside the concave apse at springing height (Z = 8.85 m)
    for k in range(18):
        a = math.pi * (k + 0.5) / 18.0
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        imp = bpy.context.active_object
        imp.scale = (0.85, 0.52, 0.42)
        imp.location = (math.cos(a) * (R - 0.12), math.sin(a) * (R - 0.12), H_SPRING - 0.15)
        imp.rotation_euler = Euler((0.0, 0.0, a + math.pi * 0.5), "XYZ")
        parts.append(imp)

    # Prominent scrolled Baroque keystone at arch crown
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    key = bpy.context.active_object
    key.scale = (0.88, 0.92, 1.35)
    key.location = (0.0, -0.30, H_SPRING + R + 0.38)
    parts.append(key)

    obj = join_objects(parts, "TreviExedraApse")
    finish_and_export(obj, "trevi_exedra_apse.glb", norm_mode="none", target_tris=7200, preserve_origin=True)


# ---------------------------------------------------------------------------
# 2. Chiseled Baroque Roman Travertine Reef & Waterfall Grottoes
# ---------------------------------------------------------------------------
def build_baroque_reef():
    """
    Built in REAL METRES centered at X = 0, Y = 0 (Godot z = f + 6.4), resting on Z = 0.
    Front faces -Y (+Z in Godot).
    Documented exact flat statue/cascade coordinates in Godot local space (offset from reef origin):
      - Central Oceanus shell chariot shelf: (x=0, y=3.85, z=-1.65) -> Blender (0, +1.65, 3.85)
      - Left/Right Horse shelves:            (x=±4.9, y=2.25, z=+2.25) -> Blender (±4.9, -2.25, 2.25)
      - Left/Right Triton shelves:           (x=±8.4, y=2.25, z=+2.05) -> Blender (±8.4, -2.05, 2.25)
    """
    clear_scene()
    rng = random.Random(1762)
    parts = []

    def add_chiseled_rock(loc, scale_xyz, rot_z=0.0, flat_top_z=None, rough=0.38):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.0, location=loc)
        r = bpy.context.active_object
        r.scale = scale_xyz
        r.rotation_euler = Euler((0.0, 0.0, rot_z), "XYZ")
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        # Apply stratified Roman travertine rock displacement (sharp horizontal ledges + angular fractures)
        for v in r.data.vertices:
            wp = r.matrix_world @ v.co
            n1 = noise.noise(wp * 0.42 + Vector((3.1, 1.7, 0.9)))
            n2 = noise.noise(wp * 1.15 + Vector((9.2, 4.4, 2.1)))
            strata = math.sin(wp.z * 2.8 + n1 * 1.6) * 0.18
            disp = (n1 * 0.65 + n2 * 0.35 + strata) * rough
            v.co += v.normal * disp
            # Clamp bottom to Z >= -0.15
            wp_new = r.matrix_world @ v.co
            if wp_new.z < -0.10:
                v.co.z += (-0.10 - wp_new.z)
            # Create flat sculpted architectural pedestal shelf if requested
            if flat_top_z is not None and wp_new.z > flat_top_z:
                v.co.z -= (wp_new.z - flat_top_z) * 0.92
        r.data.update()
        parts.append(r)

    # Central monumental cliff mass under Oceanus (flat top at Z = 3.85 m)
    add_chiseled_rock((0.0, 1.65, 2.10), (4.6, 3.2, 2.15), flat_top_z=3.85, rough=0.34)
    # Stepped central waterfall apron & intermediate catch-pool ledge (Z = 2.35 m)
    add_chiseled_rock((0.0, -0.85, 1.35), (4.2, 2.2, 1.35), flat_top_z=2.35, rough=0.30)
    add_chiseled_rock((0.0, -2.95, 0.72), (5.0, 1.9, 0.90), flat_top_z=1.25, rough=0.28)

    # Flanking sculpted ledges for Left/Right Sea-Horses (flat top at Z = 2.22 m)
    # and Tritons (flat top at Z = 2.22 m), plus dramatic outer travertine cliff wings!
    for s in (-1.0, 1.0):
        # Horse shelf (Blender X = s * 4.9, Y = -2.25)
        add_chiseled_rock((s * 4.9, -2.25, 1.20), (2.4, 2.1, 1.25), rot_z=s * 0.25, flat_top_z=2.22, rough=0.28)
        # Triton shelf (Blender X = s * 8.4, Y = -2.05)
        add_chiseled_rock((s * 8.4, -2.05, 1.22), (2.3, 2.0, 1.25), rot_z=-s * 0.2, flat_top_z=2.22, rough=0.28)
        # Mid cliff rising behind horses into palace basement rustication
        add_chiseled_rock((s * 6.8, 1.35, 1.95), (3.8, 2.8, 2.10), rot_z=s * 0.15, flat_top_z=3.45, rough=0.40)
        # Outer baroque cliff ledges cascading down toward basin corners
        add_chiseled_rock((s * 12.2, 0.25, 1.55), (3.6, 2.9, 1.75), rot_z=s * 0.3, flat_top_z=2.75, rough=0.42)
        add_chiseled_rock((s * 16.5, 1.05, 1.25), (3.4, 2.6, 1.45), rot_z=-s * 0.2, flat_top_z=2.15, rough=0.40)
        add_chiseled_rock((s * 20.6, 2.10, 0.95), (2.9, 2.3, 1.15), rot_z=s * 0.4, flat_top_z=1.55, rough=0.35)
        # Submerged rocky toe boulders peeking above basin waterline
        add_chiseled_rock((s * 11.4, -2.40, 0.55), (2.4, 1.6, 0.78), rot_z=s * 0.5, flat_top_z=1.15, rough=0.30)
        add_chiseled_rock((s * 15.8, -1.65, 0.48), (2.2, 1.5, 0.72), rot_z=-s * 0.35, flat_top_z=1.05, rough=0.28)

    obj = join_objects(parts, "TreviBaroqueReef")
    finish_and_export(obj, "trevi_baroque_reef.glb", norm_mode="none", target_tris=14000, preserve_origin=True)


# ---------------------------------------------------------------------------
# 3. Base-Trimmed Sea-Horses: Rough Sea (Wild Rearing) & Calm Sea (Placid)
# ---------------------------------------------------------------------------
def build_trevi_horses():
    horse_path = ensure_polyhaven_horse()
    for fname, pitch_deg, yaw_twist_deg in [
        ("trevi_horse_wild.glb", -20.0, 6.0),   # Rough Sea: pitched rearing upward (front -Y rises!)
        ("trevi_horse_calm.glb", 4.0, -5.0),    # Calm Sea: placid lowered stride
    ]:
        clear_scene()
        bpy.ops.import_scene.gltf(filepath=horse_path)
        objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        horse = join_objects(objs, "TreviHorse")

        # Slice off the circular tabletop figurine base cleanly (bottom 12.8% of Z)
        zs = [v.co.z for v in horse.data.vertices]
        z_cut = min(zs) + (max(zs) - min(zs)) * 0.128
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

        # Apply distinctive Baroque pose pitch & subtle dynamic twist
        horse.rotation_euler = Euler((math.radians(pitch_deg), 0.0, math.radians(yaw_twist_deg)), "XYZ")
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

        finish_and_export(horse, fname, norm_mode="height", target_tris=4400)


# ---------------------------------------------------------------------------
# 4. Baroque Scalloped Cockleshell Chariot
# ---------------------------------------------------------------------------
def build_shell_chariot():
    """Built in REAL METRES, resting on Z = 0, facing -Y (+Z in Godot)."""
    clear_scene()
    parts = []

    # Sculpted lower volute carriage & ribbed bowl (width ~5.0 m, depth ~3.4 m, height ~1.25 m)
    bm = bmesh.new()
    rings = 10
    segs = 32
    grid = []
    for j in range(rings + 1):
        t = j / rings
        z = t * 1.15
        rx = 0.25 + 2.35 * math.sin(t * math.pi * 0.65)
        ry = 0.20 + 1.65 * math.sin(t * math.pi * 0.65)
        row = []
        for i in range(segs):
            a = 2.0 * math.pi * i / segs
            flute = 1.0 + 0.09 * math.cos(a * 14.0) * math.sin(t * math.pi)
            row.append(bm.verts.new((math.cos(a) * rx * flute, math.sin(a) * ry * flute, z)))
        grid.append(row)
    for j in range(rings):
        for i in range(segs):
            ni = (i + 1) % segs
            bm.faces.new((grid[j][i], grid[j][ni], grid[j + 1][ni], grid[j + 1][i]))
    bmesh.ops.contextual_create(bm, geom=grid[0])
    bmesh.ops.contextual_create(bm, geom=grid[-1])
    bm_m = bpy.data.meshes.new("ShellBase")
    bm.to_mesh(bm_m)
    bm.free()
    base_obj = bpy.data.objects.new("ShellBase", bm_m)
    bpy.context.collection.objects.link(base_obj)
    parts.append(base_obj)

    # Grand rising scalloped cockleshell backrest (9 ribbed fan lobes rising to Z = 3.25 m behind Oceanus)
    for k in range(9):
        u = (k / 8.0) * 2.0 - 1.0  # -1..1
        ang = u * 1.08
        lobe_h = 2.25 + 0.65 * math.cos(u * math.pi * 0.5)
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.34, depth=lobe_h)
        lobe = bpy.context.active_object
        lobe.scale = (1.0, 0.42, 1.0)
        lobe.location = (math.sin(ang) * 1.85, 0.95 + math.cos(ang) * 0.42, 1.10 + lobe_h * 0.44)
        lobe.rotation_euler = Euler((-0.24, ang * 0.35, -ang * 0.35), "XYZ")
        parts.append(lobe)

    # Two curled front scroll volutes framing the chariot prow
    for s in (-1.0, 1.0):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.42, minor_radius=0.14, major_segments=14, minor_segments=8)
        vol = bpy.context.active_object
        vol.location = (s * 1.85, -1.25, 0.72)
        vol.rotation_euler = Euler((0.0, math.pi * 0.5, s * 0.3), "XYZ")
        parts.append(vol)

    obj = join_objects(parts, "TreviShellChariot")
    finish_and_export(obj, "trevi_shell_chariot.glb", norm_mode="none", target_tris=3200, preserve_origin=True)


# ---------------------------------------------------------------------------
# 5. Carved Marble Bas-Relief Panels (Agrippa & Aqua Virgo)
# ---------------------------------------------------------------------------
def build_relief_panel(filename, seed):
    clear_scene()
    rng = random.Random(seed)
    parts = []

    # Recessed framed marble slab (3.8 x 2.5 m before width=1.0 norm, front faces -Y)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    slab = bpy.context.active_object
    slab.scale = (3.8, 0.16, 2.5)
    slab.location = (0.0, 0.0, 1.25)
    parts.append(slab)

    # Moulded architectural frame around all 4 sides
    for (loc, sc) in [
        ((0.0, -0.10, 0.14), (3.96, 0.28, 0.28)),
        ((0.0, -0.10, 2.36), (3.96, 0.28, 0.28)),
        ((-1.84, -0.10, 1.25), (0.28, 0.28, 2.32)),
        ((1.84, -0.10, 1.25), (0.28, 0.28, 2.32)),
    ]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        fr = bpy.context.active_object
        fr.scale = sc
        fr.location = loc
        parts.append(fr)

    # High-relief classical narrative figures (5 Roman figures + background aqueduct arches / trees)
    xs = [-1.22, -0.62, 0.0, 0.64, 1.22]
    for idx, fx in enumerate(xs):
        fh = 1.48 + rng.uniform(-0.14, 0.14)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=1.0)
        body = bpy.context.active_object
        body.scale = (0.24, 0.14, fh * 0.44)
        body.location = (fx, -0.14, 0.34 + fh * 0.44)
        parts.append(body)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.13)
        hd = bpy.context.active_object
        hd.scale = (0.95, 0.72, 1.12)
        hd.location = (fx, -0.17, 0.34 + fh * 0.95)
        parts.append(hd)

    # Background aqueduct piers / drapery swags in shallow relief
    for k in range(3):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.48, minor_radius=0.07, major_segments=12, minor_segments=6)
        arc = bpy.context.active_object
        arc.rotation_euler = Euler((math.pi * 0.5, 0.0, 0.0), "XYZ")
        arc.scale = (1.0, 0.4, 1.0)
        arc.location = (-0.95 + k * 0.95, -0.09, 1.72)
        parts.append(arc)

    obj = join_objects(parts, filename.replace(".glb", ""))
    finish_and_export(obj, filename, norm_mode="width", target_tris=3200)


# ---------------------------------------------------------------------------
# 6. Clement XII Papal Coat of Arms & Reclining Winged Fames
# ---------------------------------------------------------------------------
def build_papal_crest():
    """
    Built in REAL METRES, resting on Z = 0 (mounted at y = 23.6 m to reach 26.3 m exact!).
    Total height = 2.70 m, width = 7.4 m, facing -Y (+Z in Godot).
    """
    clear_scene()
    parts = []

    # Stepped marble plinth base
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    pl = bpy.context.active_object
    pl.scale = (6.8, 1.5, 0.42)
    pl.location = (0.0, 0.0, 0.21)
    parts.append(pl)

    # Scrolled Baroque Corsini escutcheon shield (center, Z = 0.42..2.05 m)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=12, radius=1.0)
    shield = bpy.context.active_object
    shield.scale = (0.98, 0.48, 0.92)
    shield.location = (0.0, -0.15, 1.25)
    parts.append(shield)

    # Ornate cartouche scroll frame around the shield
    for s in (-1.0, 1.0):
        for cz, rad in [(0.78, 0.30), (1.32, 0.26), (1.78, 0.22)]:
            bpy.ops.mesh.primitive_torus_add(major_radius=rad, minor_radius=0.09, major_segments=12, minor_segments=6)
            sc = bpy.context.active_object
            sc.rotation_euler = Euler((math.pi * 0.5, 0.0, s * 0.25), "XYZ")
            sc.location = (s * 1.02, -0.22, cz)
            parts.append(sc)

    # Crossed Keys of St Peter behind the tiara
    for s in (-1.0, 1.0):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.07, depth=1.55)
        key = bpy.context.active_object
        key.location = (0.0, -0.10, 2.02)
        key.rotation_euler = Euler((0.0, s * 0.68, 0.0), "XYZ")
        parts.append(key)

    # Papal Triple Tiara & cross finial reaching Z = 2.70 m
    for tz, r1, r2, h in [
        (2.00, 0.46, 0.42, 0.20),
        (2.20, 0.42, 0.34, 0.20),
        (2.38, 0.34, 0.20, 0.18),
        (2.55, 0.14, 0.04, 0.15),
    ]:
        bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=r1, radius2=r2, depth=h)
        tier = bpy.context.active_object
        tier.location = (0.0, -0.18, tz + h * 0.5)
        parts.append(tier)

    # Two sculpted reclining Winged Fames supporting the papal arms (metaball sculpt)
    mb = bpy.data.metaballs.new("FamesMB")
    mb.resolution = 0.085
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("FamesMB", mb)
    bpy.context.collection.objects.link(mobj)
    for s in (-1.0, 1.0):
        # Reclining draped legs extending outward -> raised torso leaning toward shield -> outstretched wing
        add_meta_capsule(mb, (s * 3.15, -0.10, 0.56), (s * 2.15, -0.15, 0.72), 0.22, 0.30, steps=6)
        add_meta_capsule(mb, (s * 2.15, -0.15, 0.72), (s * 1.55, -0.18, 1.48), 0.30, 0.28, steps=6)
        # Head
        el = mb.elements.new(type="BALL")
        el.co = Vector((s * 1.48, -0.22, 1.78))
        el.radius = 0.20
        # Arm reaching to support shield
        add_meta_capsule(mb, (s * 1.55, -0.18, 1.42), (s * 0.98, -0.24, 1.58), 0.12, 0.10, steps=4)
        # Sweeping sculpted wing arching upward & outward
        add_meta_capsule(mb, (s * 1.75, 0.05, 1.38), (s * 2.95, 0.22, 2.05), 0.22, 0.16, steps=6)
        add_meta_capsule(mb, (s * 2.95, 0.22, 2.05), (s * 3.45, 0.28, 1.55), 0.16, 0.10, steps=4)
    fames = meta_to_mesh(mobj, decimate_target=3200, smooth_iters=2)
    parts.append(fames)

    obj = join_objects(parts, "TreviPapalCrest")
    finish_and_export(obj, "trevi_papal_crest.glb", norm_mode="none", target_tris=5600, preserve_origin=True)


# ---------------------------------------------------------------------------
# 7. Carved Baroque Travertine Lion / Water-Mask Spout
# ---------------------------------------------------------------------------
def build_corner_mask():
    clear_scene()
    mb = bpy.data.metaballs.new("MaskMB")
    mb.resolution = 0.06
    mb.threshold = 0.62
    mobj = bpy.data.objects.new("MaskMB", mb)
    bpy.context.collection.objects.link(mobj)

    # Ornate lion-mask medallion facing -Y
    add_meta_capsule(mb, (0.0, 0.0, 0.48), (0.0, -0.28, 0.48), 0.42, 0.26, steps=5)
    for k in range(10):
        a = 2.0 * math.pi * k / 10.0
        el = mb.elements.new(type="BALL")
        el.co = Vector((math.cos(a) * 0.42, -0.05, 0.48 + math.sin(a) * 0.42))
        el.radius = 0.16
    obj = meta_to_mesh(mobj, decimate_target=1100, smooth_iters=1)
    finish_and_export(obj, "trevi_corner_mask.glb", norm_mode="height")


if __name__ == "__main__":
    print("=== Building Trevi Fountain Baroque Hero Assets (Blender 5.3) ===", flush=True)
    build_exedra_apse()
    build_baroque_reef()
    build_trevi_horses()
    build_shell_chariot()
    build_relief_panel("trevi_relief_agrippa.glb", 1732)
    build_relief_panel("trevi_relief_virgo.glb", 1762)
    build_papal_crest()
    build_corner_mask()
    print("=== Trevi Fountain Baroque Hero Assets Complete ===", flush=True)
