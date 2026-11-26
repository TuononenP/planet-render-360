"""True-scale, high-detail aircraft and helicopter GLB builder for Planet Render 360.

Builds 5 real-scale models in metres (+X nose, +Y up, +Z right wing in Godot
glTF coordinates; wheels/skids resting on y = 0):
  - wide.glb       Airbus A350 / A330 / Boeing 787 class (L=58.8 m, span=60.3 m)
  - narrow.glb     Airbus A320 / Boeing 737 class        (L=37.6 m, span=35.8 m)
  - turboprop.glb  ATR 72 / Dash 8 Q400 class            (L=31.0 m, span=28.4 m)
  - light.glb      Cessna 172 Skyhawk class              (L=8.3 m,  span=11.0 m)
  - helicopter.glb Airbus H135 / Bell 429 class          (L=12.2 m, rotor=10.4 m)

Each GLB carries named material slots so Godot can override regional airline
or EMS liveries and bind CityLights night emission per instance:
  Body, Belly, Tail, Accent, Glass, CabinGlass, Engine, EngineDark, Chrome,
  Strut, Tire, Gear, PropBlade, NavRed, NavGreen, NavWhite, LandingLight

And separable child objects for animation:
  - BodyMesh    (fuselage, wings, tail, engines, lights)
  - Gear        (landing gear struts & wheels — hidden when retracted in flight)
  - PropLeft    (turboprop port 6-blade propeller — rotated in flight)
  - PropRight   (turboprop starboard 6-blade propeller — rotated in flight)
  - PropMain    (light aircraft nose propeller — rotated in flight)
  - MainRotor   (helicopter 4-blade main rotor — rotated in flight)
  - TailRotor   (helicopter Fenestron multi-blade tail rotor — rotated in flight)

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
    "Body":         ((0.93, 0.94, 0.95, 1.0), 0.28, 0.14),
    "Belly":        ((0.76, 0.79, 0.82, 1.0), 0.34, 0.28),
    "Tail":         ((0.05, 0.18, 0.44, 1.0), 0.30, 0.14),
    "Accent":       ((0.05, 0.18, 0.44, 1.0), 0.30, 0.14),
    "Glass":        ((0.07, 0.11, 0.16, 1.0), 0.06, 0.35),
    "CabinGlass":   ((0.12, 0.17, 0.23, 1.0), 0.12, 0.22),
    "Engine":       ((0.89, 0.91, 0.93, 1.0), 0.26, 0.32),
    "EngineDark":   ((0.10, 0.11, 0.13, 1.0), 0.50, 0.68),
    "Chrome":       ((0.82, 0.84, 0.87, 1.0), 0.18, 0.88),
    "Strut":        ((0.72, 0.75, 0.78, 1.0), 0.40, 0.40),
    "Tire":         ((0.11, 0.12, 0.13, 1.0), 0.86, 0.04),
    "Gear":         ((0.15, 0.16, 0.18, 1.0), 0.75, 0.18),
    "PropBlade":    ((0.14, 0.15, 0.17, 1.0), 0.42, 0.22),
    "NavRed":       ((1.00, 0.10, 0.06, 1.0), 0.15, 0.00),
    "NavGreen":     ((0.10, 1.00, 0.35, 1.0), 0.15, 0.00),
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
# BMesh geometry helpers (Blender coords: +X nose, +Z up, -Y right)
# ---------------------------------------------------------------------------

def _interp_station(stations, x_query):
    """Linearly interpolate (zc, ry, rz) at axial coordinate x_query."""
    if x_query <= stations[0][0]:
        return stations[0][1], stations[0][2], stations[0][3]
    if x_query >= stations[-1][0]:
        return stations[-1][1], stations[-1][2], stations[-1][3]
    for k in range(len(stations) - 1):
        x0, z0, ry0, rz0 = stations[k]
        x1, z1, ry1, rz1 = stations[k + 1]
        if x0 <= x_query <= x1:
            t = (x_query - x0) / max(x1 - x0, 1e-6)
            return (
                z0 + (z1 - z0) * t,
                ry0 + (ry1 - ry0) * t,
                rz0 + (rz1 - rz0) * t,
            )
    return stations[-1][1], stations[-1][2], stations[-1][3]


class PartBuilder:
    def __init__(self, name, mats):
        self.name = name
        self.mats = mats
        self.bm = bmesh.new()
        self.uv_layer = self.bm.loops.layers.uv.verify()
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

    def loft_ellipses(
        self,
        stations,
        segs=28,
        mat_name="Body",
        belly_mat=None,
        cabin_range=None,
        cabin_mat="CabinGlass",
        win_ang=(0.35 * math.pi, 0.45 * math.pi),
        cheatline_mat=None,
        cheatline_range=None,
        uv_x_scale=0.55,
        cap_ends=True,
    ):
        """Loft elliptical cross-sections along X with clean non-sheared CabinGlass UVs.
        stations: list of (x, z_center, ry_half_width, rz_half_height)
        """
        rings = []
        for x, zc, ry, rz in stations:
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                y = -math.sin(a) * ry
                z = zc + math.cos(a) * rz
                ring.append(self.bm.verts.new((x, y, z)))
            rings.append(ring)

        body_idx = self._slot(mat_name)
        belly_idx = self._slot(belly_mat) if belly_mat else body_idx
        cabin_idx = self._slot(cabin_mat) if cabin_range else body_idx
        cheat_idx = self._slot(cheatline_mat) if cheatline_mat else body_idx

        w_lo, w_hi = win_ang
        # Find exact angular span of faces assigned to CabinGlass so V maps 0..1 cleanly
        win_i_port = [
            i for i in range(segs)
            if w_lo < 2.0 * math.pi * (i + 0.5) / segs < w_hi
        ]
        win_i_stbd = [
            i for i in range(segs)
            if (2.0 * math.pi - w_hi) < 2.0 * math.pi * (i + 0.5) / segs < (2.0 * math.pi - w_lo)
        ]
        if not win_i_port:
            # Guarantee at least one crisp band on each side
            mid_i = int(round(0.40 * segs * 0.5))
            win_i_port = [mid_i]
            win_i_stbd = [(segs - 1 - mid_i) % segs]

        port_min, port_max = min(win_i_port), max(win_i_port) + 1
        stbd_min, stbd_max = min(win_i_stbd), max(win_i_stbd) + 1
        # Cheatline sits right below the window band
        cheat_port = {port_max} if cheatline_mat else set()
        cheat_stbd = {(stbd_min - 1) % segs} if cheatline_mat else set()

        for s in range(len(rings) - 1):
            r0, r1 = rings[s], rings[s + 1]
            x0, x1 = stations[s][0], stations[s + 1][0]
            xm = 0.5 * (x0 + x1)
            in_cabin = cabin_range is not None and cabin_range[0] <= xm <= cabin_range[1]
            in_cheat = (
                cheatline_mat is not None
                and (cheatline_range is None or cheatline_range[0] <= xm <= cheatline_range[1])
            )
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                except ValueError:
                    continue
                ang = 2.0 * math.pi * (i + 0.5) / segs
                is_port_win = in_cabin and (i in win_i_port)
                is_stbd_win = in_cabin and (i in win_i_stbd)
                is_cheat = in_cheat and (i in cheat_port or i in cheat_stbd)
                is_belly = belly_mat is not None and (0.64 * math.pi < ang < 1.36 * math.pi)

                if is_port_win or is_stbd_win:
                    f.material_index = cabin_idx
                    u0 = x0 * uv_x_scale
                    u1 = x1 * uv_x_scale
                    if is_port_win:
                        v_top = (i - port_min) / max(port_max - port_min, 1)
                        v_bot = (i + 1 - port_min) / max(port_max - port_min, 1)
                        # Verts: r0[i] (x0, top), r0[j] (x0, bot), r1[j] (x1, bot), r1[i] (x1, top)
                        uvs = [(u0, v_top), (u0, v_bot), (u1, v_bot), (u1, v_top)]
                    else:
                        # Starboard runs bottom->top as i increases
                        v_bot = 1.0 - (i - stbd_min) / max(stbd_max - stbd_min, 1)
                        v_top = 1.0 - (i + 1 - stbd_min) / max(stbd_max - stbd_min, 1)
                        uvs = [(u0, v_bot), (u0, v_top), (u1, v_top), (u1, v_bot)]
                    for loop, uv in zip(f.loops, uvs):
                        loop[self.uv_layer].uv = uv
                elif is_cheat:
                    f.material_index = cheat_idx
                elif is_belly:
                    f.material_index = belly_idx
                else:
                    f.material_index = body_idx
                f.smooth = True

        if cap_ends and len(rings) >= 2:
            for ring, flip in ((rings[0], True), (rings[-1], False)):
                verts = list(reversed(ring)) if flip else list(ring)
                try:
                    f = self.bm.faces.new(verts)
                    f.material_index = body_idx
                    f.smooth = False
                except ValueError:
                    pass

    def flush_windshield(
        self,
        stations,
        x_back,
        x_front,
        phi_max=0.44 * math.pi,
        half_arc_panes=6,
        offset_m=0.03,
        mat_name="Glass",
        frame_mat="Body",
    ):
        """Build a sleek, curved wrap-around cockpit windshield lying 100% flush
        on the nose loft surface (y = -sin(phi)*ry, z = zc + cos(phi)*rz) with
        clean mullion pillars and zero clipping or protrusion."""
        glass_idx = self._slot(mat_name)
        x_steps = 4
        cols = half_arc_panes * 2
        dx_span = x_front - x_back
        grid = []
        for ix in range(x_steps + 1):
            tv = ix / float(x_steps)  # 0 = top brow (aft), 1 = bottom sill (forward)
            row = []
            for ic in range(cols + 1):
                u = -1.0 + 2.0 * ic / float(cols)  # -1 (port) .. +1 (starboard)
                au = abs(u)
                # Center panes sit further forward along the sloping nose; side panes sweep aft
                x_top = x_back + dx_span * 0.45 * (1.0 - au * au)
                x_bot = x_front - dx_span * 0.52 * (au ** 1.6)
                x = x_top + (x_bot - x_top) * tv

                zc, ry, rz = _interp_station(stations, x)
                # Polar angle around the nose ellipse: 0 = top (+Z), +-phi_max = sides
                # Slightly wider azimuth at the bottom sill than the top brow
                phi = u * phi_max * (0.86 + 0.14 * tv)
                # Near the side rear (high au), lift the sill slightly for classic airliner/heli window shape
                y = -math.sin(phi) * ry
                z = zc + math.cos(phi) * rz

                # Estimate axial slope for true outward surface normal
                zc_f, ry_f, rz_f = _interp_station(stations, x + 0.08)
                dz_dx = ((zc_f + math.cos(phi) * rz_f) - z) / 0.08
                ny = y / max(ry * ry, 1e-4)
                nz = (z - zc) / max(rz * rz, 1e-4)
                nx = -dz_dx * nz
                nvec = Vector((nx, ny, nz))
                if nvec.length > 1e-6:
                    nvec.normalize()
                else:
                    nvec = Vector((0.5, 0.0, 0.866))
                pt = Vector((x, y, z)) + nvec * offset_m
                row.append(self.bm.verts.new(pt))
            grid.append(row)

        for ix in range(x_steps):
            for ic in range(cols):
                v00 = grid[ix][ic]
                v01 = grid[ix][ic + 1]
                v11 = grid[ix + 1][ic + 1]
                v10 = grid[ix + 1][ic]
                try:
                    f = self.bm.faces.new((v00, v10, v11, v01))
                    f.material_index = glass_idx
                    f.smooth = True
                except ValueError:
                    pass

        # Thin mullion posts at center and pane dividers
        for ic in (cols // 2, cols // 2 - 2, cols // 2 + 2):
            if 0 < ic < cols:
                for ix in range(x_steps):
                    self.strut_between(grid[ix][ic].co, grid[ix + 1][ic].co, offset_m * 0.85, mat_name=frame_mat, segs=6)

    def airfoil_wing(
        self,
        root_x,
        root_y,
        root_z,
        root_chord,
        root_thick,
        tip_x,
        tip_y,
        tip_z,
        tip_chord,
        tip_thick,
        mat_name="Body",
        le_mat=None,
        mirror_y=True,
        steps=3,
    ):
        """Swept tapered 12-point supercritical airfoil wing with optional Chrome leading edge."""
        prof = [
            (0.000,  0.000),
            (0.035,  0.240),
            (0.110,  0.410),
            (0.260,  0.510),
            (0.480,  0.480),
            (0.740,  0.280),
            (1.000,  0.000),
            (0.740, -0.140),
            (0.480, -0.310),
            (0.260, -0.350),
            (0.110, -0.300),
            (0.035, -0.180),
        ]
        sides = (-1.0, 1.0) if mirror_y else (1.0,)
        idx = self._slot(mat_name)
        le_idx = self._slot(le_mat) if le_mat else idx
        n_prof = len(prof)

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
                for i in range(n_prof):
                    j = (i + 1) % n_prof
                    quad = (r0[i], r0[j], r1[j], r1[i]) if sign > 0 else (r0[j], r0[i], r1[i], r1[j])
                    try:
                        f = self.bm.faces.new(quad)
                        # Leading edge segments: i == 0 or i == n_prof - 1
                        f.material_index = le_idx if (le_mat and (i == 0 or i == n_prof - 1)) else idx
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

    def blended_winglet(self, tip_x, tip_y, tip_z, tip_chord, tip_thick, height, mat_name="Accent"):
        """3-step smoothly curved sharklet / blended winglet on both wingtips."""
        prof = [
            (0.00,  0.00),
            (0.12,  0.42),
            (0.38,  0.50),
            (0.75,  0.26),
            (1.00,  0.00),
            (0.75, -0.26),
            (0.38, -0.50),
            (0.12, -0.42),
        ]
        idx = self._slot(mat_name)
        # Curve from horizontal (0 deg) through 35 deg, 70 deg to 82 deg canted up
        curve = [
            (0.00, 0.00, 0.00, 1.00, 0.00),
            (0.14, 0.28, 0.16, 0.84, 0.55),
            (0.34, 0.44, 0.52, 0.58, 1.20),
            (0.56, 0.54, 1.00, 0.34, 1.42),
        ]
        for sign in (-1.0, 1.0):
            rings = []
            for fx, fy, fz, fc, cant in curve:
                cx = tip_x - tip_chord * fx
                cy = (tip_y + height * fy * 0.42) * sign
                cz = tip_z + height * fz
                ch = tip_chord * fc
                th = tip_thick * max(fc, 0.45)
                # Rotate thickness vector from Z (horizontal wing) toward Y (vertical winglet)
                ny_dir = -math.sin(cant) * sign
                nz_dir = math.cos(cant)
                ring = []
                for u, v in prof:
                    ring.append(self.bm.verts.new((
                        cx - u * ch,
                        cy + v * th * ny_dir,
                        cz + v * th * nz_dir,
                    )))
                rings.append(ring)
            for k in range(len(rings) - 1):
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
            verts = list(reversed(rings[-1])) if sign < 0 else list(rings[-1])
            try:
                f = self.bm.faces.new(verts)
                f.material_index = idx
                f.smooth = False
            except ValueError:
                pass

    def vertical_fin(
        self, base_x, base_z, base_chord, top_x, top_z, top_chord,
        base_thick, top_thick, mat_name="Tail", dorsal_fillet=True,
    ):
        """Swept vertical stabilizer with optional dorsal root fillet."""
        prof = [
            (0.00,  0.00),
            (0.12,  0.42),
            (0.38,  0.50),
            (0.75,  0.26),
            (1.00,  0.00),
            (0.75, -0.26),
            (0.38, -0.50),
            (0.12, -0.42),
        ]
        idx = self._slot(mat_name)
        stations = []
        if dorsal_fillet:
            # Smooth dorsal fairing sweep into fuselage spine
            stations.append((base_x + base_chord * 0.24, base_z - 0.15, base_chord * 1.24, base_thick * 1.15))
            stations.append((base_x + base_chord * 0.05, base_z + (top_z - base_z) * 0.12, base_chord * 0.96, base_thick * 0.92))
        else:
            stations.append((base_x, base_z, base_chord, base_thick))
        stations.append((top_x, top_z, top_chord, top_thick))

        rings = []
        for sx, sz, sc, st in stations:
            rings.append([self.bm.verts.new((sx - u * sc, v * st, sz)) for u, v in prof])
        for k in range(len(rings) - 1):
            r0, r1 = rings[k], rings[k + 1]
            for i in range(len(prof)):
                j = (i + 1) % len(prof)
                try:
                    f = self.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                    f.material_index = idx
                    f.smooth = True
                except ValueError:
                    pass
        for ring, flip in ((rings[0], True), (rings[-1], False)):
            verts = list(reversed(ring)) if flip else list(ring)
            try:
                f = self.bm.faces.new(verts)
                f.material_index = idx
                f.smooth = False
            except ValueError:
                pass

    def nacelle(
        self, x_front, y_pos, z_pos, radius, length,
        mat_name="Engine", dark_mat="EngineDark", lip_mat="Chrome", segs=22, with_fan=True,
    ):
        """High-detail turbofan nacelle: chrome intake lip, recessed dark intake,
        3D radial fan blades + conical spinner, bypass exhaust, and hot-core plug."""
        # Outer cowling profile (nose lip -> bypass duct)
        stations = [
            (x_front + length * 0.03, radius * 0.86, lip_mat),
            (x_front + length * 0.01, radius * 0.96, lip_mat),
            (x_front - length * 0.06, radius * 1.01, mat_name),
            (x_front - length * 0.25, radius * 1.03, mat_name),
            (x_front - length * 0.65, radius * 0.98, mat_name),
            (x_front - length * 0.80, radius * 0.86, mat_name),
            (x_front - length * 0.86, radius * 0.74, lip_mat),
        ]
        rings = []
        for x, r, _ in stations:
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                ring.append(self.bm.verts.new((x, y_pos - math.sin(a) * r, z_pos + math.cos(a) * r)))
            rings.append(ring)

        for s in range(len(rings) - 1):
            r0, r1 = rings[s], rings[s + 1]
            m_idx = self._slot(stations[s][2])
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r1[i], r1[j], r0[j]))
                    f.material_index = m_idx
                    f.smooth = True
                except ValueError:
                    pass

        # Inner intake barrel (lip -> recessed fan plane)
        idx_dark = self._slot(dark_mat)
        idx_lip = self._slot(lip_mat)
        lip_in = []
        fan_ring = []
        fx = x_front - length * 0.16
        for i in range(segs):
            a = 2.0 * math.pi * i / segs
            lip_in.append(self.bm.verts.new((
                x_front - length * 0.02,
                y_pos - math.sin(a) * (radius * 0.80),
                z_pos + math.cos(a) * (radius * 0.80),
            )))
            fan_ring.append(self.bm.verts.new((
                fx,
                y_pos - math.sin(a) * (radius * 0.79),
                z_pos + math.cos(a) * (radius * 0.79),
            )))
        for i in range(segs):
            j = (i + 1) % segs
            try:
                f = self.bm.faces.new((rings[0][i], lip_in[i], lip_in[j], rings[0][j]))
                f.material_index = idx_lip
                f.smooth = True
            except ValueError:
                pass
            try:
                f = self.bm.faces.new((lip_in[i], fan_ring[i], fan_ring[j], lip_in[j]))
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

        if with_fan:
            # Conical spinner + 16 swept fan blades inside intake
            self.cone((fx + radius * 0.22, y_pos, z_pos), radius * 0.24, 0.03, radius * 0.42,
                      mat_name=dark_mat, axis="X", segs=12)
            self.cone((fx + radius * 0.40, y_pos, z_pos), radius * 0.08, 0.015, radius * 0.12,
                      mat_name=lip_mat, axis="X", segs=10)
            n_blades = 16
            blade_r = radius * 0.76
            for k in range(n_blades):
                ang = 2.0 * math.pi * k / n_blades
                by = y_pos - math.sin(ang) * (blade_r * 0.56)
                bz = z_pos + math.cos(ang) * (blade_r * 0.56)
                self.box(
                    (fx + radius * 0.06, by, bz),
                    (radius * 0.05, radius * 0.13, blade_r * 0.72),
                    mat_name=dark_mat,
                    rot_euler=(ang, 0.35, 0.0),
                )

        # Two-stage exhaust: metallic hot-core nozzle + dark inner exhaust plug
        core_stations = [
            (x_front - length * 0.84, radius * 0.56, dark_mat),
            (x_front - length * 0.96, radius * 0.48, lip_mat),
            (x_front - length * 1.06, radius * 0.34, dark_mat),
            (x_front - length * 1.15, radius * 0.06, dark_mat),
        ]
        # Close bypass ring back to core
        c_rings = []
        for x, r, _ in core_stations:
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                ring.append(self.bm.verts.new((x, y_pos - math.sin(a) * r, z_pos + math.cos(a) * r)))
            c_rings.append(ring)
        for i in range(segs):
            j = (i + 1) % segs
            try:
                f = self.bm.faces.new((rings[-1][i], c_rings[0][i], c_rings[0][j], rings[-1][j]))
                f.material_index = idx_dark
                f.smooth = False
            except ValueError:
                pass
        for s in range(len(c_rings) - 1):
            r0, r1 = c_rings[s], c_rings[s + 1]
            m_idx = self._slot(core_stations[s][2])
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r1[i], r1[j], r0[j]))
                    f.material_index = m_idx
                    f.smooth = True
                except ValueError:
                    pass
        try:
            f = self.bm.faces.new(list(reversed(c_rings[-1])))
            f.material_index = idx_dark
            f.smooth = False
        except ValueError:
            pass

    def canoe_fairing(self, x, y, z, radius, length, mat_name="Belly"):
        """Tapered aerodynamic flap-track canoe fairing under wing trailing edge."""
        self.loft_ellipses([
            (x - length * 0.55, z, radius * 0.25, radius * 0.30),
            (x - length * 0.15, z, radius * 0.95, radius * 1.05),
            (x + length * 0.25, z, radius * 0.90, radius * 0.95),
            (x + length * 0.50, z, radius * 0.22, radius * 0.25),
        ], segs=10, mat_name=mat_name)
        # Shift vertices in Y by y (loft_ellipses builds around y=0)
        # Easier: loft directly with offset helper
        pass

    def loft_ellipses_at_y(self, y_off, stations, segs=10, mat_name="Belly"):
        """Loft elliptical cross-sections along X centered at Y = y_off."""
        rings = []
        for x, zc, ry, rz in stations:
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                y = y_off - math.sin(a) * ry
                z = zc + math.cos(a) * rz
                ring.append(self.bm.verts.new((x, y, z)))
            rings.append(ring)
        idx = self._slot(mat_name)
        for s in range(len(rings) - 1):
            r0, r1 = rings[s], rings[s + 1]
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                    f.material_index = idx
                    f.smooth = True
                except ValueError:
                    pass
        for ring, flip in ((rings[0], True), (rings[-1], False)):
            verts = list(reversed(ring)) if flip else list(ring)
            try:
                f = self.bm.faces.new(verts)
                f.material_index = idx
                f.smooth = False
            except ValueError:
                pass

    def tube_path(self, points, radius, mat_name="Gear", segs=10):
        """Sweep a circular tube smoothly along a 3D polyline (for curved skids, pipes)."""
        if len(points) < 2:
            return
        idx = self._slot(mat_name)
        rings = []
        for k, pt in enumerate(points):
            p = Vector(pt)
            if k == 0:
                tang = (Vector(points[1]) - p).normalized()
            elif k == len(points) - 1:
                tang = (p - Vector(points[k - 1])).normalized()
            else:
                tang = (Vector(points[k + 1]) - Vector(points[k - 1])).normalized()
            ref = Vector((0.0, 0.0, 1.0)) if abs(tang.z) < 0.9 else Vector((1.0, 0.0, 0.0))
            u_ax = tang.cross(ref).normalized()
            v_ax = tang.cross(u_ax).normalized()
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                off = (u_ax * math.cos(a) + v_ax * math.sin(a)) * radius
                ring.append(self.bm.verts.new(p + off))
            rings.append(ring)
        for k in range(len(rings) - 1):
            r0, r1 = rings[k], rings[k + 1]
            for i in range(segs):
                j = (i + 1) % segs
                try:
                    f = self.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                    f.material_index = idx
                    f.smooth = True
                except ValueError:
                    pass
        for ring, flip in ((rings[0], True), (rings[-1], False)):
            verts = list(reversed(ring)) if flip else list(ring)
            try:
                f = self.bm.faces.new(verts)
                f.material_index = idx
                f.smooth = False
            except ValueError:
                pass

    def strut_between(self, p0, p1, radius, mat_name="Strut", segs=8):
        """Cylinder connecting arbitrary 3D endpoints p0 and p1."""
        v0, v1 = Vector(p0), Vector(p1)
        diff = v1 - v0
        length = diff.length
        if length < 1e-4:
            return
        mid = (v0 + v1) * 0.5
        rot = Vector((0.0, 0.0, 1.0)).rotation_difference(diff.normalized()).to_matrix().to_4x4()
        mat = Matrix.Translation(mid) @ rot
        ret = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segs,
            radius1=radius, radius2=radius, depth=length, matrix=mat,
        )
        vset = set(ret["verts"])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=True)

    def box(self, center, size, mat_name="Gear", rot_euler=(0.0, 0.0, 0.0)):
        mat = Matrix.Translation(center) @ Euler(rot_euler).to_matrix().to_4x4() @ Matrix.Diagonal((size[0], size[1], size[2], 1.0))
        ret = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat)
        vset = set(ret["verts"])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=False)

    def cylinder(self, center, radius, depth, mat_name="Gear", axis="Z", segs=12):
        self.cone(center, radius, radius, depth, mat_name=mat_name, axis=axis, segs=segs)

    def cone(self, center, r1, r2, depth, mat_name="Gear", axis="Z", segs=12):
        if axis == "X":
            rot = Matrix.Rotation(math.pi * 0.5, 4, "Y")
        elif axis == "Y":
            rot = Matrix.Rotation(math.pi * 0.5, 4, "X")
        else:
            rot = Matrix.Identity(4)
        mat = Matrix.Translation(center) @ rot
        ret = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segs,
            radius1=r1, radius2=r2, depth=depth, matrix=mat,
        )
        vset = set(ret["verts"])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=True)

    def wheel(self, x, y, z, radius, width, tire_mat="Tire", hub_mat="Strut"):
        """Beveled rubber tire with recessed metallic wheel hub."""
        segs = 14
        # Outer tread + beveled sidewalls
        self.cylinder((x, y, z), radius, width * 0.72, mat_name=tire_mat, axis="Y", segs=segs)
        for sy in (-1.0, 1.0):
            self.cone(
                (x, y + sy * width * 0.43, z),
                radius if sy < 0 else radius * 0.82,
                radius * 0.82 if sy < 0 else radius,
                width * 0.14,
                mat_name=tire_mat, axis="Y", segs=segs,
            )
        # Hub cap
        self.cylinder((x, y, z), radius * 0.44, width * 1.02, mat_name=hub_mat, axis="Y", segs=10)

    def sphere(self, center, radius, mat_name="NavWhite", segs=8):
        mat = Matrix.Translation(center)
        ret = bmesh.ops.create_uvsphere(
            self.bm, u_segments=segs, v_segments=max(4, segs // 2),
            radius=radius, matrix=mat,
        )
        vset = set(ret["verts"])
        faces = [f for f in self.bm.faces if all(v in vset for v in f.verts)]
        self._set_faces(faces, mat_name, smooth=True)

    def fenestron_fin(self, cx, cz, outer_r, inner_r, thick, mat_name="Tail", inner_mat="EngineDark", segs=18):
        """Ducted circular Fenestron shroud ring around (cx, 0, cz) in XZ plane."""
        idx_out = self._slot(mat_name)
        idx_in = self._slot(inner_mat)
        # 4 rings: left-outer, right-outer, left-inner, right-inner
        lo, ro, li, ri = [], [], [], []
        ht = thick * 0.5
        for i in range(segs):
            a = 2.0 * math.pi * i / segs
            ca, sa = math.cos(a), math.sin(a)
            lo.append(self.bm.verts.new((cx + ca * outer_r,  ht, cz + sa * outer_r)))
            ro.append(self.bm.verts.new((cx + ca * outer_r, -ht, cz + sa * outer_r)))
            li.append(self.bm.verts.new((cx + ca * inner_r,  ht * 0.88, cz + sa * inner_r)))
            ri.append(self.bm.verts.new((cx + ca * inner_r, -ht * 0.88, cz + sa * inner_r)))
        for i in range(segs):
            j = (i + 1) % segs
            for quad, m_idx in (
                ((lo[i], ro[i], ro[j], lo[j]), idx_out),
                ((ri[i], li[i], li[j], ri[j]), idx_in),
                ((lo[i], lo[j], li[j], li[i]), idx_out),
                ((ro[j], ro[i], ri[i], ri[j]), idx_out),
            ):
                try:
                    f = self.bm.faces.new(quad)
                    f.material_index = m_idx
                    f.smooth = True
                except ValueError:
                    pass

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
# Airliner builder (narrow A320/737 & wide A350/A330/787)
# ---------------------------------------------------------------------------

def build_jet(kind, mats):
    """Build narrow (A320/737) or wide (A350/A330/787) jetliner."""
    if kind == "wide":
        L, D, span = 58.8, 5.64, 60.3
        clear = 2.6
        wing_x, root_c, tip_c, sweep, dih = 5.5, 11.4, 2.4, 17.5, 2.8
        winglet_h = 3.0
        eng_y, eng_r, eng_l, eng_x = 10.6, 1.58, 5.4, 4.4
        fin_x, fin_h, fin_rc, fin_tc = -19.2, 9.8, 10.4, 2.9
        ht_x, ht_span, ht_rc, ht_tc, ht_sweep = -21.5, 19.6, 5.4, 1.65, 5.8
        wheel_r, wheel_w = 0.65, 0.42
        bogie_pairs = 2
        flap_fracs = (0.28, 0.46, 0.64, 0.80)
        uv_x_scale = 0.52
    else:
        L, D, span = 37.6, 3.95, 35.8
        clear = 1.9
        wing_x, root_c, tip_c, sweep, dih = 3.2, 6.9, 1.55, 9.2, 1.65
        winglet_h = 2.2
        eng_y, eng_r, eng_l, eng_x = 5.8, 1.04, 3.7, 2.5
        fin_x, fin_h, fin_rc, fin_tc = -12.4, 6.6, 6.9, 1.95
        ht_x, ht_span, ht_rc, ht_tc, ht_sweep = -14.2, 12.6, 3.5, 1.15, 3.4
        wheel_r, wheel_w = 0.48, 0.32
        bogie_pairs = 1
        flap_fracs = (0.34, 0.56, 0.76)
        uv_x_scale = 0.62

    r = D * 0.5
    cz = r + clear
    half_L = L * 0.5

    root = bpy.data.objects.new(f"Aircraft_{kind}", None)
    bpy.context.collection.objects.link(root)

    body = PartBuilder("BodyMesh", mats)

    # High-resolution fuselage loft (tail -> ogive radome nose)
    stations = [
        (-half_L,             cz + r * 0.36, 0.10,     0.12),
        (-half_L + L * 0.025, cz + r * 0.34, r * 0.24, r * 0.28),
        (-half_L + L * 0.08,  cz + r * 0.27, r * 0.48, r * 0.54),
        (-half_L + L * 0.15,  cz + r * 0.18, r * 0.70, r * 0.75),
        (-half_L + L * 0.23,  cz + r * 0.07, r * 0.90, r * 0.93),
        (-half_L + L * 0.31,  cz + r * 0.01, r * 0.99, r * 1.03),
        (-half_L + L * 0.36,  cz,            r,        r * 1.04),
        ( half_L - L * 0.17,  cz,            r,        r * 1.04),
        ( half_L - L * 0.13,  cz - r * 0.02, r * 0.96, r * 0.98),
        ( half_L - L * 0.095, cz - r * 0.07, r * 0.86, r * 0.86),
        ( half_L - L * 0.065, cz - r * 0.13, r * 0.71, r * 0.68),
        ( half_L - L * 0.038, cz - r * 0.19, r * 0.50, r * 0.47),
        ( half_L - L * 0.016, cz - r * 0.23, r * 0.26, r * 0.25),
        ( half_L,             cz - r * 0.25, 0.05,     0.05),
    ]
    body.loft_ellipses(
        stations,
        segs=28,
        mat_name="Body",
        belly_mat="Belly",
        cabin_range=(-half_L + L * 0.25, half_L - L * 0.145),
        cabin_mat="CabinGlass",
        win_ang=(0.36 * math.pi, 0.44 * math.pi),
        cheatline_mat="Accent",
        cheatline_range=(-half_L + L * 0.18, half_L - L * 0.08),
        uv_x_scale=uv_x_scale,
    )

    # Metallic APU exhaust nozzle at tailcone tip
    body.cone((-half_L - 0.18, 0.0, cz + r * 0.36), 0.13, 0.09, 0.42, mat_name="Chrome", axis="X", segs=12)
    body.cylinder((-half_L - 0.36, 0.0, cz + r * 0.36), 0.07, 0.12, mat_name="EngineDark", axis="X", segs=10)

    # Dorsal satcom / Wi-Fi radome hump & VHF blade antennas
    body.loft_ellipses([
        ( half_L * 0.02, cz + r * 1.02, r * 0.12, 0.04),
        ( half_L * 0.12, cz + r * 1.05, r * 0.22, 0.18),
        ( half_L * 0.24, cz + r * 1.05, r * 0.20, 0.16),
        ( half_L * 0.32, cz + r * 1.01, r * 0.08, 0.04),
    ], segs=10, mat_name="Body")
    for ax in (half_L * 0.48, -half_L * 0.28):
        body.vertical_fin(ax, cz + r * 1.01, 0.45, ax - 0.16, cz + r * 1.01 + 0.36, 0.18, 0.04, 0.02,
                          mat_name="Body", dorsal_fillet=False)

    # Belly wing-box fairing
    fairing_z = cz - r * 0.80
    body.loft_ellipses([
        (wing_x - root_c * 1.28, fairing_z + 0.18, r * 0.28, r * 0.12),
        (wing_x - root_c * 0.85, fairing_z,        r * 0.92, r * 0.36),
        (wing_x + root_c * 0.06, fairing_z,        r * 0.88, r * 0.34),
        (wing_x + root_c * 0.46, fairing_z + 0.20, r * 0.26, r * 0.12),
    ], segs=14, mat_name="Belly")

    # Flush contoured wrap-around 6-pane cockpit windshield (zero protruding boxes!)
    body.flush_windshield(
        stations,
        x_back=half_L - L * 0.135,
        x_front=half_L - L * 0.055,
        phi_max=0.42 * math.pi,
        half_arc_panes=6,
        offset_m=0.045,
        mat_name="Glass",
        frame_mat="Body",
    )

    # Main swept wings with dihedral & Chrome leading-edge anti-ice strips
    wing_z = cz - r * 0.46
    half_span = span * 0.5
    body.airfoil_wing(
        wing_x, r * 0.72, wing_z, root_c, root_c * 0.115,
        wing_x - sweep, half_span, wing_z + dih, tip_c, tip_c * 0.09,
        mat_name="Body", le_mat="Chrome", mirror_y=True, steps=3,
    )
    # Blended curved sharklets / winglets
    body.blended_winglet(
        wing_x - sweep, half_span, wing_z + dih, tip_c, tip_c * 0.085,
        winglet_h, mat_name="Accent",
    )
    # Tapered aerodynamic canoe flap-track fairings
    for sign in (-1.0, 1.0):
        for frac in flap_fracs:
            ch = root_c * (1.0 - frac) + tip_c * frac
            fx = wing_x - sweep * frac - ch * 0.82
            fy = (r * 0.72 + (half_span - r * 0.72) * frac) * sign
            fz = wing_z + dih * frac - 0.22
            flen = (2.4 if kind == "narrow" else 3.6) * (1.15 - frac * 0.45)
            frad = (0.16 if kind == "narrow" else 0.22) * (1.10 - frac * 0.35)
            body.loft_ellipses_at_y(fy, [
                (fx - flen * 0.55, fz, frad * 0.22, frad * 0.28),
                (fx - flen * 0.12, fz, frad,        frad * 1.15),
                (fx + flen * 0.28, fz, frad * 0.85, frad * 0.90),
                (fx + flen * 0.52, fz, frad * 0.20, frad * 0.22),
            ], segs=8, mat_name="Belly")

    # Vertical tail fin with dorsal root fillet (livery Tail colour)
    body.vertical_fin(
        fin_x, cz + r * 0.62, fin_rc,
        fin_x - fin_rc * 0.58, cz + r * 0.62 + fin_h, fin_tc,
        0.50 if kind == "narrow" else 0.72,
        0.16 if kind == "narrow" else 0.24,
        mat_name="Tail", dorsal_fillet=True,
    )

    # Horizontal stabilizer with dihedral & Chrome leading edge
    ht_z = cz + r * 0.24
    body.airfoil_wing(
        ht_x, r * 0.30, ht_z, ht_rc, ht_rc * 0.09,
        ht_x - ht_sweep, ht_span * 0.5, ht_z + 0.75, ht_tc, ht_tc * 0.07,
        mat_name="Body", le_mat="Chrome", mirror_y=True, steps=2,
    )

    # High-detail turbofan engines & sculpted pylons
    eng_z = wing_z + dih * ((eng_y - r * 0.72) / (half_span - r * 0.72)) - eng_r * 1.10
    for sign in (-1.0, 1.0):
        body.nacelle(
            eng_x, eng_y * sign, eng_z, eng_r, eng_l,
            mat_name="Engine", dark_mat="EngineDark", lip_mat="Chrome", segs=22, with_fan=True,
        )
        # Sculpted aerodynamic pylon sweeping nacelle up into wing underside
        body.loft_ellipses_at_y(eng_y * sign, [
            (eng_x - eng_l * 1.08, eng_z + eng_r * 0.95, eng_r * 0.14, eng_r * 0.26),
            (eng_x - eng_l * 0.68, eng_z + eng_r * 0.90, eng_r * 0.22, eng_r * 0.58),
            (eng_x - eng_l * 0.22, eng_z + eng_r * 0.80, eng_r * 0.18, eng_r * 0.44),
            (eng_x - eng_l * 0.05, eng_z + eng_r * 0.68, eng_r * 0.10, eng_r * 0.22),
        ], segs=8, mat_name="Belly")

    # Navigation, strobe, beacon & landing lights
    tip_x_pos = wing_x - sweep - tip_c * 0.16
    tip_z_pos = wing_z + dih + 0.10
    body.sphere((tip_x_pos,  half_span, tip_z_pos), 0.20, mat_name="NavRed")
    body.sphere((tip_x_pos, -half_span, tip_z_pos), 0.20, mat_name="NavGreen")
    body.sphere((-half_L + 0.15, 0.0, cz + r * 0.42), 0.18, mat_name="NavWhite")
    body.sphere((fin_x - fin_rc * 0.58 - fin_tc * 0.5, 0.0, cz + r * 0.62 + fin_h + 0.12), 0.18, mat_name="NavWhite")
    # Anti-collision red belly & crown beacons
    body.sphere((wing_x - root_c * 0.25, 0.0, cz + r * 1.05), 0.15, mat_name="NavRed")
    body.sphere((wing_x - root_c * 0.40, 0.0, fairing_z - r * 0.34), 0.15, mat_name="NavRed")
    # Wing-root landing lights
    for sign in (-1.0, 1.0):
        body.sphere((wing_x + 0.08, (r * 1.08) * sign, wing_z + 0.04), 0.20, mat_name="LandingLight")

    body.finish(root)

    # Separate retractable landing gear (Strut + Chrome oleo + Tire + gear doors)
    gear = PartBuilder("Gear", mats)
    # Nose gear
    nx = half_L - L * 0.13
    n_wr = wheel_r * 0.78
    nh = cz - r * 0.86 - n_wr
    gear.cylinder((nx, 0.0, n_wr + nh * 0.68), 0.15, nh * 0.64, mat_name="Strut", axis="Z", segs=10)
    gear.cylinder((nx, 0.0, n_wr + nh * 0.24), 0.11, nh * 0.46, mat_name="Chrome", axis="Z", segs=10)
    gear.cylinder((nx, 0.0, n_wr), 0.08, wheel_w * 2.1, mat_name="Strut", axis="Y", segs=8)
    # Nose gear taxi light & bay doors
    gear.sphere((nx + 0.18, 0.0, n_wr + nh * 0.35), 0.11, mat_name="LandingLight")
    for sy in (-1.0, 1.0):
        gear.box((nx - 0.15, sy * 0.36, cz - r * 0.96), (1.1, 0.06, 0.52), mat_name="Belly")
    for wy in (-wheel_w * 0.72, wheel_w * 0.72):
        gear.wheel(nx, wy, n_wr, n_wr, wheel_w * 0.84, tire_mat="Tire", hub_mat="Strut")

    # Main gear
    mx = wing_x - root_c * 0.52
    track = r * 1.48 if kind == "narrow" else r * 1.68
    mh = wing_z - wheel_r
    for sign in (-1.0, 1.0):
        gear.cylinder((mx, track * sign, wheel_r + mh * 0.68), 0.19, mh * 0.66, mat_name="Strut", axis="Z", segs=10)
        gear.cylinder((mx, track * sign, wheel_r + mh * 0.22), 0.14, mh * 0.44, mat_name="Chrome", axis="Z", segs=10)
        # Diagonal side-stay brace
        gear.strut_between(
            (mx, track * sign, wheel_r + mh * 0.42),
            (mx, r * 0.68 * sign, wing_z - 0.10),
            0.09, mat_name="Strut", segs=8,
        )
        # Main gear door
        gear.box((mx, (track + 0.32) * sign, wheel_r + mh * 0.62), (1.2, 0.07, mh * 0.58), mat_name="Belly")
        if bogie_pairs == 2:
            # 4-wheel bogie beam
            gear.box((mx, track * sign, wheel_r), (1.85, 0.24, 0.22), mat_name="Strut")
        for bx in ([-0.78, 0.78] if bogie_pairs == 2 else [0.0]):
            gear.cylinder((mx + bx, track * sign, wheel_r), 0.10, wheel_w * 2.2, mat_name="Strut", axis="Y", segs=8)
            for wy in (-wheel_w * 0.85, wheel_w * 0.85):
                gear.wheel(mx + bx, track * sign + wy, wheel_r, wheel_r, wheel_w, tire_mat="Tire", hub_mat="Strut")
    gear.finish(root)
    return root


# ---------------------------------------------------------------------------
# Turboprop builder (ATR 72 / Dash 8 Q400)
# ---------------------------------------------------------------------------

def _build_propeller_part(name, mats, hub_loc, n_blades, radius, root_chord, tip_chord, parent):
    """Build a separable propeller node with conical chrome spinner & swept scimitar blades."""
    pr = PartBuilder(name, mats)
    # Conical spinner pointing along +X
    pr.cone((0.18, 0.0, 0.0), 0.26, 0.04, 0.52, mat_name="Chrome", axis="X", segs=14)
    pr.cylinder((-0.08, 0.0, 0.0), 0.25, 0.16, mat_name="EngineDark", axis="X", segs=12)
    for k in range(n_blades):
        ang = 2.0 * math.pi * k / float(n_blades)
        ca, sa = math.cos(ang), math.sin(ang)
        # Build tapered twisted blade from hub out to radius in YZ plane
        steps = 4
        blade_rings = []
        for s in range(steps + 1):
            t = s / float(steps)
            dist = 0.20 + (radius - 0.20) * t
            ch = root_chord * (1.0 - t * 0.35) if t < 0.75 else tip_chord * (1.0 - (t - 0.75) * 1.4)
            ch = max(ch, 0.06)
            th = 0.032 * (1.0 - t * 0.55)
            # Blade pitch twist decreases from root to tip
            pitch = 0.58 - 0.36 * t
            cp, sp = math.cos(pitch), math.sin(pitch)
            # Radial unit vector and tangential unit vector in YZ plane
            ry, rz = -sa, ca
            ty, tz = -ca, -sa
            # 4-point diamond airfoil cross-section
            pts = [
                ( cp * ch * 0.5,  sp * ch * 0.5),
                (-sp * th,        cp * th),
                (-cp * ch * 0.5, -sp * ch * 0.5),
                ( sp * th,       -cp * th),
            ]
            ring = []
            for dx, dt in pts:
                ring.append(pr.bm.verts.new((
                    dx,
                    ry * dist + ty * dt,
                    rz * dist + tz * dt,
                )))
            blade_rings.append(ring)
        idx_blade = pr._slot("PropBlade")
        idx_tip = pr._slot("Accent")
        for s in range(steps):
            r0, r1 = blade_rings[s], blade_rings[s + 1]
            m_idx = idx_tip if s == steps - 1 else idx_blade
            for i in range(4):
                j = (i + 1) % 4
                try:
                    f = pr.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                    f.material_index = m_idx
                    f.smooth = True
                except ValueError:
                    pass
        try:
            f = pr.bm.faces.new(blade_rings[-1])
            f.material_index = idx_tip
            f.smooth = False
        except ValueError:
            pass
    obj = pr.finish(parent)
    obj.location = hub_loc
    return obj


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
        (-half_L,             cz + r * 0.44, 0.08,     0.10),
        (-half_L + L * 0.06,  cz + r * 0.36, r * 0.30, r * 0.36),
        (-half_L + L * 0.15,  cz + r * 0.22, r * 0.60, r * 0.66),
        (-half_L + L * 0.26,  cz + r * 0.08, r * 0.88, r * 0.92),
        (-half_L + L * 0.35,  cz,            r,        r * 1.02),
        ( half_L - L * 0.16,  cz,            r,        r * 1.02),
        ( half_L - L * 0.11,  cz - r * 0.04, r * 0.90, r * 0.90),
        ( half_L - L * 0.07,  cz - r * 0.11, r * 0.74, r * 0.72),
        ( half_L - L * 0.035, cz - r * 0.18, r * 0.46, r * 0.44),
        ( half_L,             cz - r * 0.22, 0.06,     0.06),
    ]
    body.loft_ellipses(
        stations,
        segs=24,
        mat_name="Body",
        belly_mat="Belly",
        cabin_range=(-half_L + L * 0.25, half_L - L * 0.15),
        cabin_mat="CabinGlass",
        win_ang=(0.35 * math.pi, 0.45 * math.pi),
        cheatline_mat="Accent",
        cheatline_range=(-half_L + L * 0.18, half_L - L * 0.09),
        uv_x_scale=0.68,
    )

    # Flush contoured wrap-around cockpit windshield (fixes the protruding cheek boxes!)
    body.flush_windshield(
        stations,
        x_back=half_L - L * 0.140,
        x_front=half_L - L * 0.055,
        phi_max=0.43 * math.pi,
        half_arc_panes=6,
        offset_m=0.035,
        mat_name="Glass",
        frame_mat="Body",
    )

    # Belly main-gear sponson pods (iconic ATR 72 / Dash 8 look)
    body.loft_ellipses([
        (-2.8, cz - r * 0.78, r * 0.55, r * 0.25),
        (-1.2, cz - r * 0.72, r * 1.24, r * 0.42),
        ( 2.2, cz - r * 0.72, r * 1.24, r * 0.42),
        ( 3.6, cz - r * 0.78, r * 0.50, r * 0.22),
    ], segs=12, mat_name="Belly")

    # High straight tapered wing with Chrome leading edge
    wing_x, wing_z = 2.6, cz + r * 0.88
    body.airfoil_wing(
        wing_x, r * 0.40, wing_z, 3.2, 0.36,
        wing_x - 0.9, span * 0.5, wing_z - 0.12, 1.50, 0.18,
        mat_name="Body", le_mat="Chrome", mirror_y=True, steps=2,
    )

    # T-tail vertical fin + high horizontal stabilizer
    fin_x, fin_h = -10.8, 5.2
    body.vertical_fin(
        fin_x, cz + r * 0.65, 4.4, fin_x - 2.6, cz + r * 0.65 + fin_h, 1.8,
        0.34, 0.14, mat_name="Tail", dorsal_fillet=True,
    )
    body.airfoil_wing(
        fin_x - 2.2, 0.15, cz + r * 0.65 + fin_h - 0.22, 2.2, 0.20,
        fin_x - 3.2, 4.5, cz + r * 0.65 + fin_h - 0.22, 1.0, 0.10,
        mat_name="Body", le_mat="Chrome", mirror_y=True, steps=1,
    )

    # Twin turboprop nacelles (exhaust pipes + intake scoop)
    prop_locs = {}
    for sign, pname in ((1.0, "PropLeft"), (-1.0, "PropRight")):
        ey = 4.6 * sign
        ez = wing_z - 0.36
        body.loft_ellipses_at_y(ey, [
            (wing_x - 2.9, ez + 0.08, 0.20, 0.22),
            (wing_x - 1.5, ez + 0.02, 0.50, 0.52),
            (wing_x + 0.8, ez,        0.52, 0.54),
            (wing_x + 1.5, ez,        0.34, 0.36),
        ], segs=14, mat_name="Engine")
        # Intake scoop under spinner + metallic exhaust pipe
        body.box((wing_x + 1.1, ey, ez - 0.36), (0.65, 0.34, 0.22), mat_name="EngineDark")
        body.cone((wing_x - 2.6, ey, ez - 0.10), 0.14, 0.10, 0.55, mat_name="Chrome", axis="X", segs=10)
        prop_locs[pname] = (wing_x + 1.62, ey, ez)

    # Nav & landing lights
    body.sphere((wing_x - 0.9,  span * 0.5, wing_z - 0.10), 0.17, mat_name="NavRed")
    body.sphere((wing_x - 0.9, -span * 0.5, wing_z - 0.10), 0.17, mat_name="NavGreen")
    body.sphere((-half_L + 0.15, 0.0, cz + r * 0.44), 0.16, mat_name="NavWhite")
    body.sphere((half_L - L * 0.14, 0.0, cz - r * 0.85), 0.16, mat_name="LandingLight")
    body.finish(root)

    # Separable 6-blade scimitar propellers for live spinning animation
    for pname, loc in prop_locs.items():
        _build_propeller_part(pname, mats, loc, n_blades=6, radius=1.95, root_chord=0.22, tip_chord=0.14, parent=root)

    # Retractable landing gear
    gear = PartBuilder("Gear", mats)
    nx = half_L - L * 0.12
    nh = cz - r * 0.85 - 0.32
    gear.cylinder((nx, 0.0, 0.32 + nh * 0.65), 0.10, nh * 0.68, mat_name="Strut", axis="Z", segs=8)
    gear.cylinder((nx, 0.0, 0.32 + nh * 0.22), 0.07, nh * 0.40, mat_name="Chrome", axis="Z", segs=8)
    for wy in (-0.22, 0.22):
        gear.wheel(nx, wy, 0.32, 0.32, 0.22, tire_mat="Tire", hub_mat="Strut")
    for sign in (-1.0, 1.0):
        mh = cz - r * 0.55 - 0.40
        gear.cylinder((0.6, r * 1.15 * sign, 0.40 + mh * 0.65), 0.12, mh * 0.68, mat_name="Strut", axis="Z", segs=8)
        gear.cylinder((0.6, r * 1.15 * sign, 0.40 + mh * 0.22), 0.08, mh * 0.40, mat_name="Chrome", axis="Z", segs=8)
        for wy in (-0.26, 0.26):
            gear.wheel(0.6, r * 1.15 * sign + wy, 0.40, 0.40, 0.28, tire_mat="Tire", hub_mat="Strut")
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
        (-half_L,             cz + 0.12, 0.06,     0.08),
        (-half_L + L * 0.24,  cz + 0.10, r * 0.34, r * 0.40),
        (-half_L + L * 0.44,  cz + 0.06, r * 0.62, r * 0.68),
        (-half_L + L * 0.56,  cz + 0.03, r * 0.96, r * 1.06),
        ( half_L - L * 0.25,  cz + 0.01, r,        r * 1.04),
        ( half_L - L * 0.14,  cz - 0.06, r * 0.80, r * 0.68),
        ( half_L - L * 0.05,  cz - 0.08, r * 0.58, r * 0.48),
        ( half_L,             cz - 0.09, r * 0.34, r * 0.30),
    ]
    body.loft_ellipses(
        stations, segs=18, mat_name="Body", belly_mat="Accent",
        cabin_range=(-0.3, 1.7), cabin_mat="Glass",
        win_ang=(0.24 * math.pi, 0.46 * math.pi),
    )

    # Flush front windshield
    body.flush_windshield(
        stations,
        x_back=1.40,
        x_front=2.65,
        phi_max=0.42 * math.pi,
        half_arc_panes=4,
        offset_m=0.024,
        mat_name="Glass",
        frame_mat="Body",
    )

    # High straight wing + faired diagonal struts
    wing_x, wing_z = 1.5, cz + r * 0.96
    body.airfoil_wing(
        wing_x, 0.22, wing_z, 1.55, 0.20,
        wing_x - 0.15, span * 0.5, wing_z + 0.18, 1.18, 0.14,
        mat_name="Body", le_mat="Chrome", mirror_y=True, steps=2,
    )
    for sign in (-1.0, 1.0):
        body.strut_between(
            (0.8, r * 0.78 * sign, cz - r * 0.52),
            (0.8, 2.75 * sign, wing_z - 0.04),
            0.038, mat_name="Strut", segs=8,
        )

    # Tail surfaces
    body.vertical_fin(-2.45, cz + 0.18, 1.48, -3.30, cz + 1.58, 0.66, 0.14, 0.06, mat_name="Tail", dorsal_fillet=True)
    body.airfoil_wing(-2.95, 0.08, cz + 0.15, 1.02, 0.10, -3.20, 1.72, cz + 0.15, 0.72, 0.07,
                      mat_name="Body", mirror_y=True, steps=1)

    # Cowling air intake + nav lights
    body.box((half_L - 0.05, 0.0, cz - 0.22), (0.14, 0.34, 0.10), mat_name="EngineDark")
    body.sphere((wing_x - 0.15,  span * 0.5, wing_z + 0.18), 0.09, mat_name="NavRed")
    body.sphere((wing_x - 0.15, -span * 0.5, wing_z + 0.18), 0.09, mat_name="NavGreen")
    body.sphere((-half_L, 0.0, cz + 0.14), 0.09, mat_name="NavWhite")
    body.sphere((wing_x + 0.02, 1.65, wing_z - 0.02), 0.08, mat_name="LandingLight")
    body.finish(root)

    # Separable 2-blade nose propeller
    _build_propeller_part("PropMain", mats, (half_L + 0.08, 0.0, cz - 0.08),
                          n_blades=2, radius=0.94, root_chord=0.12, tip_chord=0.07, parent=root)

    # Fixed tricycle gear with streamlined wheel pants
    gear = PartBuilder("Gear", mats)
    gear.cylinder((half_L - 0.75, 0.0, 0.44), 0.045, 0.48, mat_name="Chrome", axis="Z", segs=8)
    gear.wheel(half_L - 0.75, 0.0, 0.20, 0.20, 0.14, tire_mat="Tire", hub_mat="Strut")
    for sign in (-1.0, 1.0):
        gear.strut_between((0.25, 0.45 * sign, cz - r * 0.65), (0.25, 1.15 * sign, 0.24), 0.045, mat_name="Strut", segs=8)
        gear.wheel(0.25, 1.15 * sign, 0.22, 0.22, 0.16, tire_mat="Tire", hub_mat="Strut")
        # Streamlined wheel pant fairing
        gear.loft_ellipses_at_y(1.15 * sign, [
            (-0.20, 0.26, 0.05, 0.06),
            ( 0.25, 0.28, 0.13, 0.17),
            ( 0.62, 0.25, 0.06, 0.08),
        ], segs=8, mat_name="Body")
    gear.finish(root)
    return root


# ---------------------------------------------------------------------------
# Helicopter builder (Airbus H135 / Bell 429 EMS & Executive)
# ---------------------------------------------------------------------------

def build_helicopter(mats):
    # Overall length ~12.2 m, main rotor diameter 10.4 m, cabin height ~3.4 m
    root = bpy.data.objects.new("Aircraft_helicopter", None)
    bpy.context.collection.objects.link(root)

    body = PartBuilder("BodyMesh", mats)
    cz = 1.66

    # Sculpted 24-segment teardrop fuselage + smooth rounded nose
    cabin_stations = [
        (-1.60, cz + 0.16, 0.46, 0.56),
        (-0.85, cz + 0.08, 0.84, 0.84),
        ( 0.00, cz + 0.02, 1.02, 0.96),
        ( 1.00, cz,        1.06, 0.98),
        ( 2.00, cz - 0.02, 1.02, 0.94),
        ( 2.85, cz - 0.12, 0.88, 0.80),
        ( 3.55, cz - 0.24, 0.68, 0.60),
        ( 4.10, cz - 0.36, 0.42, 0.36),
        ( 4.45, cz - 0.42, 0.14, 0.12),
    ]
    body.loft_ellipses(
        cabin_stations,
        segs=24,
        mat_name="Body",
        belly_mat="Accent",
        cabin_range=(-0.15, 2.35),
        cabin_mat="CabinGlass",
        win_ang=(0.24 * math.pi, 0.46 * math.pi),
        uv_x_scale=0.85,
    )

    # Flush contoured wrap-around panoramic cockpit canopy (zero protruding boxes!)
    body.flush_windshield(
        cabin_stations,
        x_back=2.15,
        x_front=3.85,
        phi_max=0.46 * math.pi,
        half_arc_panes=6,
        offset_m=0.032,
        mat_name="Glass",
        frame_mat="Body",
    )

    # Top twin-turbine engine cowling, front intake scoops & metallic exhaust shrouds
    body.loft_ellipses([
        (-1.65, cz + 0.86, 0.32, 0.22),
        (-0.70, cz + 0.96, 0.62, 0.38),
        ( 0.45, cz + 0.98, 0.68, 0.40),
        ( 1.50, cz + 0.90, 0.58, 0.32),
        ( 2.20, cz + 0.76, 0.28, 0.16),
    ], segs=16, mat_name="Tail")
    for sy in (-0.34, 0.34):
        # Front turbine air intake scoops
        body.cylinder((1.62, sy, cz + 0.88), 0.15, 0.34, mat_name="EngineDark", axis="X", segs=10)
        # Rear metallic exhaust nozzles
        body.cone((-1.62, sy, cz + 0.92), 0.15, 0.12, 0.52, mat_name="Chrome", axis="X", segs=10)
        body.cylinder((-1.86, sy, cz + 0.92), 0.10, 0.12, mat_name="EngineDark", axis="X", segs=10)

    # Wire-strike cutter blades (top canopy & lower chin) + nose FLIR/searchlight pod
    body.vertical_fin(2.55, cz + 0.78, 0.34, 2.38, cz + 1.14, 0.08, 0.03, 0.015, mat_name="EngineDark", dorsal_fillet=False)
    body.sphere((3.95, 0.0, cz - 0.62), 0.16, mat_name="EngineDark", segs=10)
    body.sphere((4.08, 0.0, cz - 0.62), 0.09, mat_name="LandingLight", segs=8)

    # Smooth tapered tail boom
    body.loft_ellipses([
        (-6.85, cz + 0.34, 0.16, 0.22),
        (-5.20, cz + 0.28, 0.23, 0.30),
        (-3.20, cz + 0.22, 0.35, 0.44),
        (-1.40, cz + 0.16, 0.50, 0.58),
    ], segs=14, mat_name="Tail")

    # Ducted Fenestron shrouded tail fin + upper swept fin + lower tail bumper skid
    fen_x, fen_z = -7.05, cz + 0.46
    body.fenestron_fin(fen_x, fen_z, outer_r=0.72, inner_r=0.46, thick=0.22, mat_name="Tail", inner_mat="EngineDark", segs=18)
    # Upper swept tail fin above Fenestron shroud
    body.vertical_fin(fen_x + 0.28, fen_z + 0.52, 0.92, fen_x - 0.52, fen_z + 1.56, 0.54, 0.18, 0.08,
                      mat_name="Tail", dorsal_fillet=False)
    # Lower ventral fin & tail bumper
    body.vertical_fin(fen_x + 0.20, fen_z - 0.96, 0.58, fen_x + 0.25, fen_z - 0.52, 0.76, 0.10, 0.16,
                      mat_name="Accent", dorsal_fillet=False)

    # Horizontal stabilators with vertical endplate fins
    stab_x, stab_z = -5.10, cz + 0.28
    body.airfoil_wing(stab_x, 0.20, stab_z, 0.62, 0.08, stab_x - 0.12, 1.38, stab_z, 0.48, 0.06,
                      mat_name="Accent", mirror_y=True, steps=1)
    for sign in (-1.0, 1.0):
        body.box((stab_x - 0.34, 1.38 * sign, stab_z + 0.04), (0.56, 0.04, 0.48), mat_name="Tail")

    # Main rotor mast + transmission collar
    body.cylinder((0.75, 0.0, cz + 1.30), 0.22, 0.24, mat_name="Strut", axis="Z", segs=12)
    body.cylinder((0.75, 0.0, cz + 1.50), 0.11, 0.46, mat_name="Chrome", axis="Z", segs=12)

    # Continuous curved tubular landing skids + boarding steps + cross-tube struts
    for sign in (-1.0, 1.0):
        sy = 1.08 * sign
        skid_pts = [
            (-1.05, sy, 0.08),
            ( 0.00, sy, 0.08),
            ( 2.25, sy, 0.08),
            ( 3.10, sy, 0.09),
            ( 3.45, sy, 0.18),
            ( 3.72, sy, 0.34),
            ( 3.88, sy, 0.48),
        ]
        body.tube_path(skid_pts, 0.068, mat_name="Gear", segs=10)
        # Boarding step bar along cabin door
        body.box((1.15, (1.16) * sign, 0.48), (1.35, 0.16, 0.04), mat_name="Strut")
        for sx in (0.05, 2.20):
            body.strut_between((sx, sy, 0.08), (sx, 0.64 * sign, cz - 0.72), 0.055, mat_name="Gear", segs=8)

    # Nav lights & anti-collision beacon
    body.sphere((0.75,  1.08, cz - 0.18), 0.09, mat_name="NavRed")
    body.sphere((0.75, -1.08, cz - 0.18), 0.09, mat_name="NavGreen")
    body.sphere((fen_x - 0.52, 0.0, fen_z + 1.62), 0.10, mat_name="NavWhite")
    body.sphere((-3.20, 0.0, cz + 0.68), 0.08, mat_name="NavRed")
    body.finish(root)

    # Separate MainRotor centered at hub so Godot rotates cleanly about +Y
    rotor_hub = (0.75, 0.0, cz + 1.72)
    mr = PartBuilder("MainRotor", mats)
    # Sculpted rotor head cap + swashplate + blade grips
    mr.cone((0.0, 0.0, 0.06), 0.30, 0.16, 0.16, mat_name="EngineDark", axis="Z", segs=14)
    mr.cylinder((0.0, 0.0, -0.06), 0.24, 0.08, mat_name="Chrome", axis="Z", segs=12)
    for k in range(4):
        ang = k * math.pi * 0.5 + 0.25
        ca, sa = math.cos(ang), math.sin(ang)
        # Blade grip collar
        mr.box((ca * 0.42, sa * 0.42, 0.0), (0.36, 0.14, 0.09), mat_name="Strut", rot_euler=(0.0, 0.0, ang))
        # Tapered airfoil main rotor blade + high-vis tip band
        mr.box((ca * 2.55, sa * 2.55, 0.02), (4.15, 0.28, 0.042), mat_name="PropBlade", rot_euler=(0.0, 0.0, ang))
        mr.box((ca * 4.86, sa * 4.86, 0.02), (0.50, 0.24, 0.036), mat_name="Accent", rot_euler=(0.0, 0.0, ang))
    mr_obj = mr.finish(root)
    mr_obj.location = rotor_hub

    # Separate TailRotor centered inside Fenestron duct (rotates about Godot +Z -> Blender -Y)
    tr = PartBuilder("TailRotor", mats)
    tr.cylinder((0.0, 0.0, 0.0), 0.12, 0.22, mat_name="Chrome", axis="Y", segs=12)
    for k in range(6):
        ang = 2.0 * math.pi * k / 6.0
        tr.box((math.cos(ang) * 0.24, 0.0, math.sin(ang) * 0.24),
               (0.32, 0.03, 0.075), mat_name="PropBlade", rot_euler=(0.0, -ang, 0.0))
    tr_obj = tr.finish(root)
    tr_obj.location = (fen_x, 0.0, fen_z)
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


def _setup_preview_scene():
    reset_scene()
    mats = make_materials()
    bpy.ops.mesh.primitive_plane_add(size=400.0, location=(0.0, 10.0, -0.02))
    gmat = bpy.data.materials.new("Ground")
    gmat.use_nodes = True
    gmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.38, 0.40, 0.42, 1.0)
    gmat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    bpy.context.active_object.data.materials.append(gmat)

    sun_data = bpy.data.lights.new("Sun", type="SUN")
    sun_data.energy = 4.2
    sun_obj = bpy.data.objects.new("Sun", sun_data)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(48), math.radians(15), math.radians(36))

    world = bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.62, 0.74, 0.88, 1.0)
        bg.inputs[1].default_value = 0.75

    scene = bpy.context.scene
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "CYCLES"):
        try:
            scene.render.engine = eng
            break
        except TypeError:
            continue
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    return mats, scene


def render_preview(out_png):
    """Render 5-aircraft lineup preview + close-up detail shot."""
    mats, scene = _setup_preview_scene()
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

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 38.0
    cam_obj = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam_obj)
    cam_obj.location = (82.0, 74.0, 44.0)
    direction = Vector((0.0, 8.0, 4.0)) - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam_obj

    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)

    # Close-up of helicopter + turboprop + narrow nose/engine
    closeup_png = os.path.join(os.path.dirname(out_png), "aircraft_closeup.png")
    cam_data.lens = 45.0
    cam_obj.location = (32.0, 78.0, 12.0)
    direction = Vector((8.0, 46.0, 2.8)) - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = closeup_png
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
