"""True-scale, photo-referenced aircraft and helicopter GLB builder for Planet Render 360.

Builds 5 real-scale models in metres (+X nose, +Y up, +Z right wing in Godot
glTF coordinates; wheels/skids resting on y = 0):
  - wide.glb       Airbus A330 / Boeing 787 class (L=58.8 m, span=60.3 m)
  - narrow.glb     Airbus A320 / Boeing 737 class (L=37.6 m, span=35.8 m)
  - turboprop.glb  ATR 72 / Dash 8 Q400 class     (L=31.0 m, span=28.4 m)
  - light.glb      Cessna 172 Skyhawk class       (L=8.3 m,  span=11.0 m)
  - helicopter.glb Airbus H135 / Bell 429 class   (L=12.2 m, rotor=10.4 m)

Each GLB carries named material slots so Godot can override regional airline
or EMS liveries and bind CityLights night emission per instance:
  Body, Belly, Tail, Accent, Glass, CabinGlass, Engine, EngineDark,
  Gear, NavRed, NavGreen, NavWhite, LandingLight

And separable child objects for animation:
  - BodyMesh    (fuselage, wings, tail, engines, lights)
  - Gear        (landing gear struts & wheels — hidden when retracted in flight)
  - MainRotor   (helicopter 4-blade main rotor — rotated in flight)
  - TailRotor   (helicopter tail rotor — rotated in flight)

Note on Blender -> glTF/Godot axis mapping:
  glTF exporter with export_yup=True maps Blender (X, Y, Z) -> glTF (X, Z, -Y).
  So in Blender coordinates:
    +X = nose (forward) -> Godot +X
    +Z = up             -> Godot +Y
    -Y = right wing     -> Godot +Z  (and +Y = left wing -> Godot -Z)

Run:
  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
    --python-exit-code 1 -P assets_src/blender/build_aircraft.py -- \\
    assets_src/blender assets/aircraft
"""
import math
import os
import sys
import bpy
import bmesh
from mathutils import Euler, Matrix, Vector


# ---------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------

MAT_DEFS = {
    "Body":         ((0.92, 0.93, 0.94, 1.0), 0.32, 0.12),
    "Belly":        ((0.76, 0.78, 0.81, 1.0), 0.38, 0.25),
    "Tail":         ((0.06, 0.20, 0.48, 1.0), 0.34, 0.12),
    "Accent":       ((0.06, 0.20, 0.48, 1.0), 0.34, 0.12),
    "Glass":        ((0.12, 0.17, 0.22, 1.0), 0.10, 0.25),
    "CabinGlass":   ((0.16, 0.21, 0.27, 1.0), 0.14, 0.20),
    "Engine":       ((0.88, 0.90, 0.92, 1.0), 0.28, 0.35),
    "EngineDark":   ((0.12, 0.13, 0.15, 1.0), 0.55, 0.65),
    "Gear":         ((0.16, 0.17, 0.19, 1.0), 0.78, 0.15),
    "NavRed":       ((1.00, 0.12, 0.08, 1.0), 0.15, 0.00),
    "NavGreen":     ((0.12, 1.00, 0.35, 1.0), 0.15, 0.00),
    "NavWhite":     ((1.00, 0.98, 0.92, 1.0), 0.15, 0.00),
    "LandingLight": ((1.00, 0.97, 0.88, 1.0), 0.10, 0.00),
}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_materials():
    mats = {}
    for name, (col, rough, metal) in MAT_DEFS.items():
        m = bpy.data.materials.new(name=name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = col
            bsdf.inputs["Roughness"].default_value = rough
            bsdf.inputs["Metallic"].default_value = metal
        mats[name] = m
    return mats


# ---------------------------------------------------------------------------
# BMesh geometry helpers (all in Blender coords: +X nose, +Z up, -Y right)
# ---------------------------------------------------------------------------

class PartBuilder:
    def __init__(self, name, mats):
        self.name = name
        self.mats = mats
        self.bm = bmesh.new()
        self.mat_list = []
        self.mat_idx = {}

    def _slot(self, mat_name):
        if mat_name not in self.mat_idx:
            self.mat_idx[mat_name] = len(self.mat_list)
            self.mat_list.append(self.mats[mat_name])
        return self.mat_idx[mat_name]

    def _set_faces(self, faces, mat_name, smooth=True):
        idx = self._slot(mat_name)
        for f in faces:
            f.material_index = idx
            f.smooth = smooth

    def loft_ellipses(self, stations, segs=20, mat_name="Body", belly_mat=None,
                      cabin_range=None, cabin_mat="CabinGlass", cap_ends=True):
        """Loft elliptical cross-sections along X.
        stations: list of (x, z_center, rx_width_half, rz_height_half)
        """
        rings = []
        for x, zc, ry, rz in stations:
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                # a=0 is +Z (top), a=pi/2 is -Y (right), a=pi is -Z (bottom)
                y = -math.sin(a) * ry
                z = zc + math.cos(a) * rz
                ring.append(self.bm.verts.new((x, y, z)))
            rings.append(ring)

        body_idx = self._slot(mat_name)
        belly_idx = self._slot(belly_mat) if belly_mat else body_idx
        cabin_idx = self._slot(cabin_mat) if cabin_range else body_idx

        for s in range(len(rings) - 1):
            r0, r1 = rings[s], rings[s + 1]
            xm = 0.5 * (stations[s][0] + stations[s + 1][0])
            in_cabin = cabin_range is not None and cabin_range[0] <= xm <= cabin_range[1]
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                except ValueError:
                    continue
                ang = 2.0 * math.pi * (i + 0.5) / segs
                # Window band: slightly above equator on both sides
                is_win = in_cabin and (0.28 * math.pi < ang < 0.46 * math.pi or
                                       1.54 * math.pi < ang < 1.72 * math.pi)
                is_belly = belly_mat is not None and (0.68 * math.pi < ang < 1.32 * math.pi)
                if is_win:
                    f.material_index = cabin_idx
                elif is_belly:
                    f.material_index = belly_idx
                else:
                    f.material_index = body_idx
                f.smooth = True

        if cap_ends and len(rings) >= 2:
            # Cap start (tail) and end (nose)
            for ring, flip in ((rings[0], True), (rings[-1], False)):
                verts = list(reversed(ring)) if flip else list(ring)
                try:
                    f = self.bm.faces.new(verts)
                    f.material_index = body_idx
                    f.smooth = False
                except ValueError:
                    pass

    def airfoil_wing(self, root_x, root_y, root_z, root_chord, root_thick,
                     tip_x, tip_y, tip_z, tip_chord, tip_thick,
                     mat_name="Body", mirror_y=True, steps=1):
        """Swept tapered airfoil wing from root to tip."""
        # Simple clean NACA-like 8-point airfoil profile (u=0 LE, u=1 TE)
        prof = [
            (0.00,  0.00),
            (0.12,  0.42),
            (0.35,  0.52),
            (0.70,  0.32),
            (1.00,  0.00),
            (0.70, -0.18),
            (0.35, -0.34),
            (0.12, -0.30),
        ]
        sides = (-1.0, 1.0) if mirror_y else (1.0,)
        idx = self._slot(mat_name)
        for sign in sides:
            rings = []
            for k in range(steps + 1):
                t = k / float(steps)
                cx = root_x + (tip_x - root_x) * t
                cy = (root_y + (tip_y - root_y) * t) * sign
                cz = root_z + (tip_z - root_z) * t
                ch = root_chord + (tip_chord - root_chord) * t
                th = root_thick + (tip_thick - root_thick) * t
                ring = []
                for u, v in prof:
                    ring.append(self.bm.verts.new((cx - u * ch, cy, cz + v * th)))
                rings.append(ring)
            for k in range(steps):
                r0, r1 = rings[k], rings[k + 1]
                for i in range(len(prof)):
                    j = (i + 1) % len(prof)
                    quad = (r0[i], r0[j], r1[j], r1[i]) if sign > 0 else (r0[j], r0[i], r1[i], r1[j])
                    try:
                        f = self.bm.faces.new(quad)
                        f.material_index = idx
                        f.smooth = True
                    except ValueError:
                        pass
            for ring, flip in ((rings[0], sign > 0), (rings[-1], sign < 0)):
                verts = list(reversed(ring)) if flip else list(ring)
                try:
                    f = self.bm.faces.new(verts)
                    f.material_index = idx
                    f.smooth = False
                except ValueError:
                    pass

    def vertical_fin(self, base_x, base_z, base_chord, top_x, top_z, top_chord,
                     base_thick, top_thick, mat_name="Tail"):
        """Swept vertical stabilizer along XZ plane centered at Y=0."""
        prof = [
            (0.00,  0.00),
            (0.15,  0.48),
            (0.45,  0.50),
            (0.80,  0.25),
            (1.00,  0.00),
            (0.80, -0.25),
            (0.45, -0.50),
            (0.15, -0.48),
        ]
        idx = self._slot(mat_name)
        r0 = [self.bm.verts.new((base_x - u * base_chord, v * base_thick, base_z)) for u, v in prof]
        r1 = [self.bm.verts.new((top_x - u * top_chord, v * top_thick, top_z)) for u, v in prof]
        for i in range(len(prof)):
            j = (i + 1) % len(prof)
            try:
                f = self.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                f.material_index = idx
                f.smooth = True
            except ValueError:
                pass
        for ring, flip in ((r0, True), (r1, False)):
            verts = list(reversed(ring)) if flip else list(ring)
            try:
                f = self.bm.faces.new(verts)
                f.material_index = idx
                f.smooth = False
            except ValueError:
                pass

    def nacelle(self, x_front, y_pos, z_pos, radius, length, mat_name="Engine",
                dark_mat="EngineDark", segs=16):
        """Turbofan nacelle with recessed intake lip, dark fan face, and exhaust cone."""
        stations = [
            (x_front + length * 0.02, radius * 0.84),
            (x_front,                 radius * 0.96),
            (x_front - length * 0.14, radius * 1.02),
            (x_front - length * 0.68, radius * 0.98),
            (x_front - length * 0.88, radius * 0.78),
            (x_front - length * 1.00, radius * 0.56),
        ]
        rings = []
        for x, r in stations:
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                ring.append(self.bm.verts.new((x, y_pos - math.sin(a) * r, z_pos + math.cos(a) * r)))
            rings.append(ring)
        idx_eng = self._slot(mat_name)
        idx_dark = self._slot(dark_mat)
        for s in range(len(rings) - 1):
            r0, r1 = rings[s], rings[s + 1]
            m_idx = idx_dark if s >= len(rings) - 2 else idx_eng
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r1[i], r1[j], r0[j]))
                    f.material_index = m_idx
                    f.smooth = True
                except ValueError:
                    pass
        # Recessed dark fan disc inside front lip
        fan_ring = []
        fx = x_front - length * 0.12
        fr = radius * 0.82
        for i in range(segs):
            a = 2.0 * math.pi * i / segs
            fan_ring.append(self.bm.verts.new((fx, y_pos - math.sin(a) * fr, z_pos + math.cos(a) * fr)))
        for i in range(segs):
            j = (i + 1) % segs
            try:
                f = self.bm.faces.new((rings[0][i], fan_ring[i], fan_ring[j], rings[0][j]))
                f.material_index = idx_dark
                f.smooth = True
            except ValueError:
                pass
        try:
            f = self.bm.faces.new(fan_ring)
            f.material_index = idx_dark
            f.smooth = False
        except ValueError:
            pass
        # Exhaust cap
        try:
            f = self.bm.faces.new(list(reversed(rings[-1])))
            f.material_index = idx_dark
            f.smooth = False
        except ValueError:
            pass

    def box(self, center, size, mat_name="Gear", rot_euler=(0.0, 0.0, 0.0)):
        mat = Matrix.Translation(center) @ Euler(rot_euler).to_matrix().to_4x4() @ Matrix.Diagonal((size[0], size[1], size[2], 1.0))
        ret = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat)
        verts = ret["verts"]
        vset = set(verts)
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=False)

    def cylinder(self, center, radius, depth, mat_name="Gear", axis="Z", segs=12):
        if axis == "X":
            rot = Matrix.Rotation(math.pi * 0.5, 4, "Y")
        elif axis == "Y":
            rot = Matrix.Rotation(math.pi * 0.5, 4, "X")
        else:
            rot = Matrix.Identity(4)
        mat = Matrix.Translation(center) @ rot
        ret = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segs,
            radius1=radius, radius2=radius, depth=depth, matrix=mat,
        )
        vset = set(ret["verts"])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=True)

    def wheel(self, x, y, z, radius, width, mat_name="Gear"):
        self.cylinder((x, y, z), radius, width, mat_name=mat_name, axis="Y", segs=12)

    def sphere(self, center, radius, mat_name="NavWhite", segs=8):
        mat = Matrix.Translation(center)
        ret = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=max(4, segs // 2),
                                        radius=radius, matrix=mat)
        vset = set(ret["verts"])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=True)

    def finish(self, parent=None):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for m in self.mat_list:
            mesh.materials.append(m)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        if parent is not None:
            obj.parent = parent
        return obj


# ---------------------------------------------------------------------------
# Airliner builder (narrow & wide)
# ---------------------------------------------------------------------------

def build_jet(kind, mats):
    """Build narrow (A320/737) or wide (A330/787) jetliner."""
    if kind == "wide":
        L, D, span = 58.8, 5.64, 60.3
        clear = 2.6
        wing_x, root_c, tip_c, sweep, dih = 5.5, 11.2, 2.5, 17.5, 2.6
        winglet_h = 2.8
        eng_y, eng_r, eng_l, eng_x = 10.6, 1.55, 5.2, 4.2
        fin_x, fin_h, fin_rc, fin_tc = -19.5, 9.8, 10.2, 3.0
        ht_x, ht_span, ht_rc, ht_tc, ht_sweep = -21.5, 19.4, 5.4, 1.7, 5.8
        wheel_r, wheel_w = 0.65, 0.42
        bogie_pairs = 2
    else:
        L, D, span = 37.6, 3.95, 35.8
        clear = 1.9
        wing_x, root_c, tip_c, sweep, dih = 3.2, 6.8, 1.55, 9.2, 1.5
        winglet_h = 2.1
        eng_y, eng_r, eng_l, eng_x = 5.8, 1.02, 3.6, 2.4
        fin_x, fin_h, fin_rc, fin_tc = -12.6, 6.6, 6.8, 2.0
        ht_x, ht_span, ht_rc, ht_tc, ht_sweep = -14.2, 12.6, 3.5, 1.15, 3.4
        wheel_r, wheel_w = 0.48, 0.32
        bogie_pairs = 1

    r = D * 0.5
    cz = r + clear
    half_L = L * 0.5

    root = bpy.data.objects.new(f"Aircraft_{kind}", None)
    bpy.context.collection.objects.link(root)

    body = PartBuilder("BodyMesh", mats)

    # Fuselage loft (tail -> nose) with realistic nose droop and upswept tailcone
    stations = [
        (-half_L,            cz + r * 0.36, 0.08,     0.10),
        (-half_L + L * 0.03, cz + r * 0.34, r * 0.22, r * 0.26),
        (-half_L + L * 0.14, cz + r * 0.20, r * 0.62, r * 0.68),
        (-half_L + L * 0.26, cz + r * 0.06, r * 0.92, r * 0.95),
        (-half_L + L * 0.34, cz,            r,        r * 1.04),
        ( half_L - L * 0.16, cz,            r,        r * 1.04),
        ( half_L - L * 0.11, cz - r * 0.03, r * 0.94, r * 0.94),
        ( half_L - L * 0.06, cz - r * 0.12, r * 0.72, r * 0.70),
        ( half_L - L * 0.025,cz - r * 0.20, r * 0.40, r * 0.38),
        ( half_L,            cz - r * 0.24, 0.06,     0.06),
    ]
    body.loft_ellipses(
        stations, segs=20, mat_name="Body", belly_mat="Belly",
        cabin_range=(-half_L + L * 0.24, half_L - L * 0.14), cabin_mat="CabinGlass",
    )

    # Belly wing-box fairing
    fairing_z = cz - r * 0.78
    body.loft_ellipses([
        (wing_x - root_c * 1.25, fairing_z + 0.15, r * 0.30, r * 0.14),
        (wing_x - root_c * 0.85, fairing_z,        r * 0.88, r * 0.34),
        (wing_x + root_c * 0.05, fairing_z,        r * 0.85, r * 0.32),
        (wing_x + root_c * 0.42, fairing_z + 0.18, r * 0.28, r * 0.14),
    ], segs=12, mat_name="Belly")

    # Cockpit wrap-around windshield (dark glass visor flush with upper nose)
    cx_cockpit = half_L - L * 0.088
    cz_cockpit = cz + r * 0.16
    for sy in (-1.0, 1.0):
        body.box((cx_cockpit - L * 0.004, sy * r * 0.42, cz_cockpit),
                 (L * 0.052, r * 0.72, r * 0.34),
                 mat_name="Glass", rot_euler=(0.0, 0.22, sy * -0.48))
    body.box((cx_cockpit + L * 0.022, 0.0, cz_cockpit - r * 0.04),
             (L * 0.032, r * 1.05, r * 0.32),
             mat_name="Glass", rot_euler=(0.0, 0.30, 0.0))

    # Main swept wings with dihedral
    wing_z = cz - r * 0.46
    half_span = span * 0.5
    body.airfoil_wing(
        wing_x, r * 0.72, wing_z, root_c, root_c * 0.11,
        wing_x - sweep, half_span, wing_z + dih, tip_c, tip_c * 0.09,
        mat_name="Body", mirror_y=True, steps=2,
    )
    # Winglets / sharklets (accent livery colour)
    for sign in (-1.0, 1.0):
        body.airfoil_wing(
            wing_x - sweep, half_span * sign, wing_z + dih, tip_c, tip_c * 0.08,
            wing_x - sweep - tip_c * 0.45, (half_span + 0.45) * sign, wing_z + dih + winglet_h,
            tip_c * 0.36, tip_c * 0.04,
            mat_name="Accent", mirror_y=False, steps=1,
        )
        # Flap-track fairings (2 per wing)
        for frac in (0.38, 0.62):
            fx = wing_x - sweep * frac - (root_c * (1.0 - frac) + tip_c * frac) * 0.88
            fy = (r * 0.72 + (half_span - r * 0.72) * frac) * sign
            fz = wing_z + dih * frac - 0.25
            body.cylinder((fx, fy, fz), 0.16, 2.2 if kind == "narrow" else 3.2, mat_name="Belly", axis="X", segs=8)

    # Vertical tail fin (livery Tail colour)
    body.vertical_fin(
        fin_x, cz + r * 0.60, fin_rc,
        fin_x - fin_rc * 0.58, cz + r * 0.60 + fin_h, fin_tc,
        0.48 if kind == "narrow" else 0.70,
        0.16 if kind == "narrow" else 0.24,
        mat_name="Tail",
    )

    # Horizontal stabilizer with dihedral
    ht_z = cz + r * 0.24
    body.airfoil_wing(
        ht_x, r * 0.32, ht_z, ht_rc, ht_rc * 0.09,
        ht_x - ht_sweep, ht_span * 0.5, ht_z + 0.7, ht_tc, ht_tc * 0.07,
        mat_name="Body", mirror_y=True, steps=1,
    )

    # Engines & pylons
    eng_z = wing_z + dih * ((eng_y - r * 0.72) / (half_span - r * 0.72)) - eng_r * 1.12
    for sign in (-1.0, 1.0):
        body.nacelle(eng_x, eng_y * sign, eng_z, eng_r, eng_l, mat_name="Engine", dark_mat="EngineDark")
        # Pylon joining nacelle to wing
        body.box((eng_x - eng_l * 0.58, eng_y * sign, eng_z + eng_r * 0.85),
                 (eng_l * 0.72, eng_r * 0.36, eng_r * 0.95), mat_name="Belly")

    # Navigation & landing lights
    tip_x_pos = wing_x - sweep - tip_c * 0.18
    tip_z_pos = wing_z + dih + 0.08
    # Blender +Y is Godot -Z (port = red); Blender -Y is Godot +Z (starboard = green)
    body.sphere((tip_x_pos,  half_span, tip_z_pos), 0.22, mat_name="NavRed")
    body.sphere((tip_x_pos, -half_span, tip_z_pos), 0.22, mat_name="NavGreen")
    body.sphere((-half_L + 0.2, 0.0, cz + r * 0.38), 0.22, mat_name="NavWhite")
    body.sphere((fin_x - fin_rc * 0.58 - fin_tc * 0.5, 0.0, cz + r * 0.60 + fin_h + 0.12), 0.20, mat_name="NavWhite")
    # Wing-root landing lights
    for sign in (-1.0, 1.0):
        body.sphere((wing_x + 0.1, (r * 1.08) * sign, wing_z + 0.05), 0.22, mat_name="LandingLight")

    body.finish(root)

    # Separate retractable landing gear
    gear = PartBuilder("Gear", mats)
    # Nose gear
    nx = half_L - L * 0.13
    nh = cz - r * 0.88 - wheel_r * 0.8
    gear.cylinder((nx, 0.0, wheel_r * 0.8 + nh * 0.5), 0.14, nh, mat_name="Gear", axis="Z", segs=8)
    for wy in (-wheel_w * 0.75, wheel_w * 0.75):
        gear.wheel(nx, wy, wheel_r * 0.8, wheel_r * 0.8, wheel_w * 0.85, mat_name="Gear")
    # Main gear
    mx = wing_x - root_c * 0.52
    track = r * 1.45 if kind == "narrow" else r * 1.65
    mh = wing_z - wheel_r
    for sign in (-1.0, 1.0):
        gear.cylinder((mx, track * sign, wheel_r + mh * 0.5), 0.18, mh, mat_name="Gear", axis="Z", segs=8)
        for bx in ([-0.75, 0.75] if bogie_pairs == 2 else [0.0]):
            for wy in (-wheel_w * 0.85, wheel_w * 0.85):
                gear.wheel(mx + bx, track * sign + wy, wheel_r, wheel_r, wheel_w, mat_name="Gear")
    gear.finish(root)
    return root


# ---------------------------------------------------------------------------
# Turboprop builder (ATR 72 / Dash 8 Q400)
# ---------------------------------------------------------------------------

def build_turboprop(mats):
    L, D, span = 31.0, 2.75, 28.4
    clear = 1.35
    r = D * 0.5
    cz = r + clear
    half_L = L * 0.5

    root = bpy.data.objects.new("Aircraft_turboprop", None)
    bpy.context.collection.objects.link(root)

    body = PartBuilder("BodyMesh", mats)
    stations = [
        (-half_L,            cz + r * 0.42, 0.06,     0.08),
        (-half_L + L * 0.14, cz + r * 0.24, r * 0.55, r * 0.62),
        (-half_L + L * 0.28, cz + r * 0.06, r * 0.92, r * 0.94),
        (-half_L + L * 0.36, cz,            r,        r * 1.02),
        ( half_L - L * 0.16, cz,            r,        r * 1.02),
        ( half_L - L * 0.09, cz - r * 0.08, r * 0.82, r * 0.82),
        ( half_L - L * 0.03, cz - r * 0.18, r * 0.44, r * 0.42),
        ( half_L,            cz - r * 0.22, 0.06,     0.06),
    ]
    body.loft_ellipses(
        stations, segs=18, mat_name="Body", belly_mat="Belly",
        cabin_range=(-half_L + L * 0.24, half_L - L * 0.15), cabin_mat="CabinGlass",
    )
    # Cockpit wrap-around glass
    body.box((half_L - L * 0.088, 0.0, cz + r * 0.18), (L * 0.055, r * 1.56, r * 0.38),
             mat_name="Glass", rot_euler=(0.0, 0.28, 0.0))

    # High straight tapered wing
    wing_x, wing_z = 2.6, cz + r * 0.88
    body.airfoil_wing(
        wing_x, r * 0.45, wing_z, 3.2, 0.36,
        wing_x - 0.9, span * 0.5, wing_z - 0.15, 1.55, 0.18,
        mat_name="Body", mirror_y=True, steps=1,
    )
    # T-tail vertical fin + high horizontal stabilizer
    fin_x, fin_h = -10.8, 5.2
    body.vertical_fin(fin_x, cz + r * 0.65, 4.4, fin_x - 2.6, cz + r * 0.65 + fin_h, 1.8, 0.34, 0.14, mat_name="Tail")
    body.airfoil_wing(
        fin_x - 2.2, 0.15, cz + r * 0.65 + fin_h - 0.25, 2.2, 0.20,
        fin_x - 3.2, 4.4, cz + r * 0.65 + fin_h - 0.25, 1.0, 0.10,
        mat_name="Body", mirror_y=True, steps=1,
    )
    # Twin turboprop nacelles & 4-blade propellers
    for sign in (-1.0, 1.0):
        ey = 4.6 * sign
        ez = wing_z - 0.38
        body.nacelle(wing_x + 1.5, ey, ez, 0.52, 4.4, mat_name="Engine", dark_mat="EngineDark", segs=12)
        px = wing_x + 1.65
        body.cylinder((px, ey, ez), 0.24, 0.45, mat_name="EngineDark", axis="X", segs=10)
        for ang in (0.0, 0.5 * math.pi):
            body.box((px + 0.05, ey, ez), (0.06, 0.22, 3.8), mat_name="Gear", rot_euler=(ang, 0.0, 0.0))

    # Nav & landing lights
    body.sphere((wing_x - 0.9,  span * 0.5, wing_z - 0.12), 0.18, mat_name="NavRed")
    body.sphere((wing_x - 0.9, -span * 0.5, wing_z - 0.12), 0.18, mat_name="NavGreen")
    body.sphere((-half_L + 0.15, 0.0, cz + r * 0.42), 0.18, mat_name="NavWhite")
    body.sphere((half_L - L * 0.14, 0.0, cz - r * 0.85), 0.16, mat_name="LandingLight")
    body.finish(root)

    # Gear (main gear mounted in belly sponson pods)
    gear = PartBuilder("Gear", mats)
    nx = half_L - L * 0.12
    gear.cylinder((nx, 0.0, (cz - r * 0.85) * 0.5), 0.10, cz - r * 0.85, mat_name="Gear", axis="Z", segs=8)
    gear.wheel(nx, 0.0, 0.32, 0.32, 0.36, mat_name="Gear")
    for sign in (-1.0, 1.0):
        gear.cylinder((0.6, r * 1.15 * sign, (cz - r * 0.5) * 0.5), 0.12, cz - r * 0.5, mat_name="Gear", axis="Z", segs=8)
        gear.wheel(0.6, r * 1.15 * sign, 0.40, 0.40, 0.46, mat_name="Gear")
    gear.finish(root)
    return root


# ---------------------------------------------------------------------------
# Light aircraft builder (Cessna 172 Skyhawk)
# ---------------------------------------------------------------------------

def build_light(mats):
    L, D, span = 8.3, 1.25, 11.0
    clear = 0.58
    r = D * 0.5
    cz = r + clear
    half_L = L * 0.5

    root = bpy.data.objects.new("Aircraft_light", None)
    bpy.context.collection.objects.link(root)

    body = PartBuilder("BodyMesh", mats)
    stations = [
        (-half_L,            cz + 0.10, 0.05,     0.07),
        (-half_L + L * 0.42, cz + 0.06, r * 0.52, r * 0.58),
        (-half_L + L * 0.56, cz + 0.02, r * 0.98, r * 1.06),
        ( half_L - L * 0.24, cz,        r,        r * 1.04),
        ( half_L - L * 0.10, cz - 0.06, r * 0.72, r * 0.62),
        ( half_L,            cz - 0.08, r * 0.35, r * 0.32),
    ]
    body.loft_ellipses(stations, segs=14, mat_name="Body", belly_mat="Accent",
                       cabin_range=(-0.2, 1.6), cabin_mat="Glass")

    # High straight wing + diagonal struts
    wing_x, wing_z = 1.5, cz + r * 0.96
    body.airfoil_wing(
        wing_x, 0.25, wing_z, 1.55, 0.20,
        wing_x - 0.15, span * 0.5, wing_z + 0.18, 1.20, 0.14,
        mat_name="Body", mirror_y=True, steps=1,
    )
    for sign in (-1.0, 1.0):
        # Strut from lower fuselage to mid-wing
        p0 = Vector((0.8, r * 0.75 * sign, cz - r * 0.55))
        p1 = Vector((0.8, 2.7 * sign, wing_z - 0.05))
        mid = (p0 + p1) * 0.5
        diff = p1 - p0
        ang_x = math.atan2(diff.y, diff.z)
        body.box(mid, (0.08, 0.05, diff.length), mat_name="Gear", rot_euler=(-ang_x, 0.0, 0.0))

    # Tail surfaces
    body.vertical_fin(-2.5, cz + 0.18, 1.45, -3.3, cz + 1.55, 0.65, 0.14, 0.06, mat_name="Tail")
    body.airfoil_wing(-3.0, 0.08, cz + 0.15, 1.0, 0.10, -3.2, 1.7, cz + 0.15, 0.72, 0.07,
                      mat_name="Body", mirror_y=True, steps=1)

    # Nose spinner & 2-blade propeller
    body.cylinder((half_L + 0.12, 0.0, cz - 0.08), 0.16, 0.28, mat_name="EngineDark", axis="X", segs=10)
    body.box((half_L + 0.10, 0.0, cz - 0.08), (0.04, 0.12, 1.88), mat_name="Gear")

    # Nav lights
    body.sphere((wing_x - 0.15,  span * 0.5, wing_z + 0.18), 0.10, mat_name="NavRed")
    body.sphere((wing_x - 0.15, -span * 0.5, wing_z + 0.18), 0.10, mat_name="NavGreen")
    body.sphere((-half_L, 0.0, cz + 0.12), 0.10, mat_name="NavWhite")
    body.finish(root)

    # Fixed tricycle gear
    gear = PartBuilder("Gear", mats)
    gear.cylinder((half_L - 0.75, 0.0, 0.42), 0.05, 0.52, mat_name="Gear", axis="Z", segs=8)
    gear.wheel(half_L - 0.75, 0.0, 0.20, 0.20, 0.14, mat_name="Gear")
    for sign in (-1.0, 1.0):
        gear.cylinder((0.25, 1.15 * sign, 0.46), 0.05, 0.60, mat_name="Gear", axis="Z", segs=8)
        gear.wheel(0.25, 1.15 * sign, 0.22, 0.22, 0.16, mat_name="Gear")
    gear.finish(root)
    return root


# ---------------------------------------------------------------------------
# Helicopter builder (Airbus H135 / Bell 429)
# ---------------------------------------------------------------------------

def build_helicopter(mats):
    # Overall length ~12.2 m, main rotor diameter 10.4 m, cabin height ~3.4 m
    root = bpy.data.objects.new("Aircraft_helicopter", None)
    bpy.context.collection.objects.link(root)

    body = PartBuilder("BodyMesh", mats)
    cz = 1.68

    # Sculpted teardrop fuselage + nose
    cabin_stations = [
        (-1.40, cz + 0.12, 0.55, 0.62),
        (-0.50, cz + 0.05, 0.96, 0.92),
        ( 0.80, cz,        1.04, 0.96),
        ( 2.20, cz - 0.02, 1.00, 0.92),
        ( 3.20, cz - 0.16, 0.82, 0.74),
        ( 4.00, cz - 0.34, 0.52, 0.46),
        ( 4.45, cz - 0.44, 0.12, 0.12),
    ]
    body.loft_ellipses(cabin_stations, segs=18, mat_name="Body", belly_mat="Accent",
                       cabin_range=(0.0, 2.5), cabin_mat="CabinGlass")

    # Wrap-around glazed cockpit windshield
    for sy in (-1.0, 1.0):
        body.box((3.05, sy * 0.42, cz + 0.16), (1.35, 0.62, 0.68),
                 mat_name="Glass", rot_euler=(0.0, 0.42, sy * -0.30))
    body.box((3.32, 0.0, cz + 0.12), (0.95, 0.96, 0.64),
             mat_name="Glass", rot_euler=(0.0, 0.55, 0.0))

    # Top engine cowling & twin exhaust nozzles
    body.loft_ellipses([
        (-1.55, cz + 0.88, 0.34, 0.24),
        (-0.20, cz + 0.96, 0.66, 0.38),
        ( 1.25, cz + 0.92, 0.62, 0.34),
        ( 2.05, cz + 0.78, 0.32, 0.18),
    ], segs=14, mat_name="Tail")
    for sy in (-0.30, 0.30):
        body.cylinder((-1.55, sy, cz + 0.94), 0.14, 0.55, mat_name="EngineDark", axis="X", segs=10)

    # Tapered tail boom
    body.loft_ellipses([
        (-7.20, cz + 0.30, 0.14, 0.20),
        (-5.20, cz + 0.26, 0.22, 0.28),
        (-3.00, cz + 0.22, 0.34, 0.42),
        (-1.30, cz + 0.16, 0.52, 0.58),
    ], segs=12, mat_name="Tail")

    # Tail vertical fin + Fenestron-style shroud & horizontal stabilators
    body.vertical_fin(-6.60, cz - 0.25, 1.25, -7.55, cz + 1.65, 0.62, 0.24, 0.12, mat_name="Tail")
    body.airfoil_wing(-5.10, 0.20, cz + 0.28, 0.62, 0.08, -5.25, 1.35, cz + 0.28, 0.48, 0.06,
                      mat_name="Accent", mirror_y=True, steps=1)

    # Main rotor mast
    body.cylinder((0.75, 0.0, cz + 1.38), 0.14, 0.58, mat_name="EngineDark", axis="Z", segs=10)

    # Landing skids (part of BodyMesh — fixed skids, resting cleanly on z=0)
    for sign in (-1.0, 1.0):
        sy = 1.08 * sign
        body.cylinder((1.15, sy, 0.08), 0.075, 4.4, mat_name="Gear", axis="X", segs=10)
        # Upturned front skid tip
        body.box((3.52, sy, 0.22), (0.55, 0.12, 0.12), mat_name="Gear", rot_euler=(0.0, -0.52, 0.0))
        # Two angled cross-tube struts per side
        for sx in (0.0, 2.2):
            p0 = Vector((sx, sy, 0.08))
            p1 = Vector((sx, 0.65 * sign, cz - 0.72))
            mid = (p0 + p1) * 0.5
            diff = p1 - p0
            ang_x = math.atan2(diff.y, diff.z)
            body.box(mid, (0.10, 0.08, diff.length), mat_name="Gear", rot_euler=(-ang_x, 0.0, 0.0))

    # Nav lights & nose searchlight
    body.sphere((0.75,  1.08, cz - 0.20), 0.10, mat_name="NavRed")
    body.sphere((0.75, -1.08, cz - 0.20), 0.10, mat_name="NavGreen")
    body.sphere((-7.55, 0.0, cz + 1.72), 0.11, mat_name="NavWhite")
    body.sphere((4.35, 0.0, cz - 0.52), 0.12, mat_name="LandingLight")
    body.finish(root)

    # Separate MainRotor centered at hub so Godot rotates it cleanly about +Y
    rotor_hub = (0.75, 0.0, cz + 1.66)
    mr = PartBuilder("MainRotor", mats)
    mr.cylinder((0.0, 0.0, 0.0), 0.26, 0.18, mat_name="EngineDark", axis="Z", segs=12)
    for k in range(4):
        ang = k * math.pi * 0.5 + 0.25
        bx = math.cos(ang) * 2.60
        by = math.sin(ang) * 2.60
        mr.box((bx, by, 0.02), (5.05, 0.28, 0.045), mat_name="Gear", rot_euler=(0.0, 0.0, ang))
    mr_obj = mr.finish(root)
    mr_obj.location = rotor_hub

    # Separate TailRotor centered at tail fin hub
    tr = PartBuilder("TailRotor", mats)
    tr.cylinder((0.0, 0.0, 0.0), 0.10, 0.28, mat_name="EngineDark", axis="Y", segs=10)
    for k in range(2):
        ang = k * math.pi * 0.5
        tr.box((0.0, 0.16, 0.0), (1.10, 0.03, 0.10), mat_name="Gear", rot_euler=(0.0, ang, 0.0))
    tr_obj = tr.finish(root)
    tr_obj.location = (-7.10, 0.0, cz + 0.55)
    return root


# ---------------------------------------------------------------------------
# Export & Preview
# ---------------------------------------------------------------------------

def export_glb(filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format="GLB",
        use_selection=False,
        export_yup=True,
        export_apply=True,
        export_materials="EXPORT",
    )


def render_preview(out_png):
    """Render a quick 5-aircraft lineup preview for visual verification."""
    reset_scene()
    mats = make_materials()
    # Place all 5 types side-by-side along Y
    lineup = [
        ("wide",       (-10.0, -52.0, 0.0)),
        ("narrow",     (  2.0,   0.0, 0.0)),
        ("turboprop",  (  4.0,  36.0, 0.0)),
        ("helicopter", ( 12.0,  58.0, 0.0)),
        ("light",      ( 12.0,  72.0, 0.0)),
    ]
    builders = {
        "wide": lambda: build_jet("wide", mats),
        "narrow": lambda: build_jet("narrow", mats),
        "turboprop": lambda: build_turboprop(mats),
        "light": lambda: build_light(mats),
        "helicopter": lambda: build_helicopter(mats),
    }
    for kind, loc in lineup:
        obj = builders[kind]()
        obj.location = loc

    # Ground plane
    bpy.ops.mesh.primitive_plane_add(size=400.0, location=(0.0, 10.0, -0.02))
    gmat = bpy.data.materials.new("Ground")
    gmat.use_nodes = True
    gmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.38, 0.40, 0.42, 1.0)
    gmat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    bpy.context.active_object.data.materials.append(gmat)

    # Sun + Sky
    sun_data = bpy.data.lights.new("Sun", type="SUN")
    sun_data.energy = 4.0
    sun_obj = bpy.data.objects.new("Sun", sun_data)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(52), math.radians(15), math.radians(38))

    world = bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.62, 0.74, 0.88, 1.0)
        bg.inputs[1].default_value = 0.7

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 38.0
    cam_obj = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam_obj)
    cam_obj.location = (82.0, 74.0, 44.0)
    direction = Vector((0.0, 8.0, 4.0)) - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam_obj

    scene = bpy.context.scene
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "CYCLES"):
        try:
            scene.render.engine = eng
            break
        except TypeError:
            continue
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    src_dir, out_dir = argv[0], argv[1]
    builders = {
        "wide": lambda mats: build_jet("wide", mats),
        "narrow": lambda mats: build_jet("narrow", mats),
        "turboprop": lambda mats: build_turboprop(mats),
        "light": lambda mats: build_light(mats),
        "helicopter": lambda mats: build_helicopter(mats),
    }
    for kind, fn in builders.items():
        reset_scene()
        mats = make_materials()
        fn(mats)
        out_path = os.path.join(out_dir, f"{kind}.glb")
        export_glb(out_path)
        print(f"AIRCRAFT EXPORTED: {out_path} ({os.path.getsize(out_path)} bytes)")

    preview_path = os.path.join(src_dir, "aircraft_preview.png")
    render_preview(preview_path)
    print(f"PREVIEW RENDERED: {preview_path}")


if __name__ == "__main__":
    main()
