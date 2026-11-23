class_name LandmarkMiAtlantis
extends RefCounted

## The Atlantis on Brickell (2025 Brickell Ave) — Miami MI-3B
## Architect: Arquitectonica (Bernardo Fort-Brescia & Laurinda Spear, 1982), 20 fl, height_m = 64.0.
## Site: OSM way 480909198, centroid 25.752831, -80.198498, yaw_deg = 52.2 (+X SE to Biscayne Bay).
## Footprint: 92.6 x 13.9 m (+X long slab -46.3..+46.3 m, -Z North-East blue-grid face, +Z South-West stucco).
## Envelope:
##   - Slender slab (92.6 x 13.9 m, y = 0.0..59.5 m) pierced cleanly right through by the iconic
##     5-storey square skycourt void (x = +6.0..+21.5 m, y = 33.0..48.5 m):
##     lower block (0..33.0 m), landward & bayward piers (33.0..48.5 m), upper bridge (48.5..59.5 m).
##   - North (-Z) face: deep reflective cyan-blue glass grid (glass("#1E5D88")) with crisp white
##     mullions + projecting bright yellow (#F2C632) right-triangular balcony.
##   - South (+Z) face: crisp white stucco with window bands & 4 stacked bright yellow balconies.
##   - Open skycourt interior: bright crimson-red (#D62828) helical spiral staircase, courtyard
##     LandmarkMiKit.royal_palm, and square turquoise pool_water whirlpool tub.
##   - Signature crimson-red barrel-vaulted rooftop penthouse prism (y = 59.5..64.0 m).

const HEIGHT_M := 64.0
const HALF_X := 46.3
const HALF_Z := 6.95
const HOLE_X0 := 6.0
const HOLE_X1 := 21.5
const HOLE_Y0 := 33.0
const HOLE_Y1 := 48.5
const SLAB_TOP := 59.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteStucco", LandmarkMaterials.pbr("render", "#F4F3EE", 3.5, 0.52))
	lm.use("BlueGlass", LandmarkMaterials.glass("#1E5D88"))
	lm.use("SouthGlass", LandmarkMaterials.glass("#254256"))
	lm.use("CrimsonRed", LandmarkMaterials.paint("#D62828", 0.34, 0.22))
	lm.use("SunYellow", LandmarkMaterials.paint("#F2C632", 0.38, 0.18))
	lm.use("PoolWater", LandmarkMaterials.pool_water("#1DCAD3"))
	lm.use("PalmTrunk", LandmarkMaterials.pbr("limestone", "#9E988D", 2.0))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#3E7032", 2.0, 0.78))
	lm.use("SkyLamp", LandmarkMaterials.lit("#FFF0C8", 1.18))

	_slab_with_skycourt_void(lm)
	_north_blue_glass_grid(lm)
	_south_stucco_and_yellow_balconies(lm)
	_skycourt_stair_palm_and_whirlpool(lm)
	_red_rooftop_vault(lm)
	lm.commit(model)

	var spots: Array = [
		[Vector3(-18.0, 1.4, -18.0), Vector3(-8.0, 34.0, -7.0), 54.0, 1.15, 72.0, Color(0.94, 0.96, 1.0)],
		[Vector3(24.0, 1.4, -18.0), Vector3(16.0, 36.0, -7.0), 54.0, 1.15, 72.0, Color(0.94, 0.96, 1.0)],
		[Vector3(-18.0, 1.4, 18.0), Vector3(-8.0, 34.0, 7.0), 54.0, 1.10, 72.0, Color(1.0, 0.94, 0.84)],
		[Vector3(24.0, 1.4, 18.0), Vector3(16.0, 36.0, 7.0), 54.0, 1.10, 72.0, Color(1.0, 0.94, 0.84)],
		# Dedicated warm theatrical spotlight inside the 5-storey skycourt hole!
		[Vector3(8.5, 33.8, -5.2), Vector3(15.2, 41.5, 0.5), 62.0, 1.35, 22.0, Color(1.0, 0.90, 0.72)],
	]
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _slab_with_skycourt_void(lm: LandmarkMesh) -> void:
	# Ground plinth & recessed glass lobby on pilotis (y = 0.0..4.5 m)
	lm.box("WhiteStucco", Vector3(0.0, 0.22, 0.0), Vector3(92.6, 0.44, 13.9), Basis(), 0.03)
	lm.box("SouthGlass", Vector3(0.0, 2.45, 0.0), Vector3(88.0, 4.10, 11.2), Basis(), 0.0)
	for k in 10:
		var xp := lerpf(-42.0, 42.0, float(k) / 9.0)
		for sz in [-1.0, 1.0]:
			lm.box("WhiteStucco", Vector3(xp, 2.45, float(sz) * 6.2), Vector3(0.95, 4.10, 0.95), Basis(), 0.03)

	# 1) Lower residential slab block: y = 4.5..33.0 m across full 92.6 x 13.9 m
	lm.box("WhiteStucco", Vector3(0.0, (4.5 + HOLE_Y0) * 0.5, 0.0),
		Vector3(92.6, HOLE_Y0 - 4.5, 13.9), Basis(), 0.05)

	# 2) Landward (-X) pier beside skycourt hole: x = -46.3..+6.0 m, y = 33.0..48.5 m
	var w_west := HOLE_X0 - (-HALF_X)
	lm.box("WhiteStucco", Vector3((-HALF_X + HOLE_X0) * 0.5, (HOLE_Y0 + HOLE_Y1) * 0.5, 0.0),
		Vector3(w_west, HOLE_Y1 - HOLE_Y0, 13.9), Basis(), 0.05)

	# 3) Bayward (+X) pier beside skycourt hole: x = +21.5..+46.3 m, y = 33.0..48.5 m
	var w_east := HALF_X - HOLE_X1
	lm.box("WhiteStucco", Vector3((HOLE_X1 + HALF_X) * 0.5, (HOLE_Y0 + HOLE_Y1) * 0.5, 0.0),
		Vector3(w_east, HOLE_Y1 - HOLE_Y0, 13.9), Basis(), 0.05)

	# 4) Upper sky-bridge spanning cleanly over the 15.5 x 15.5 m void: y = 48.5..59.5 m
	lm.box("WhiteStucco", Vector3(0.0, (HOLE_Y1 + SLAB_TOP) * 0.5, 0.0),
		Vector3(92.6, SLAB_TOP - HOLE_Y1, 13.9), Basis(), 0.05)
	# Crisp rooftop parapet coping
	lm.box("WhiteStucco", Vector3(0.0, SLAB_TOP + 0.30, 0.0), Vector3(92.8, 0.60, 14.1), Basis(), 0.03)

	# Rounded bayfront (+X) observation nose glass & curved white balcony slabs facing Biscayne Bay
	lm.lathe("BlueGlass", Vector3(HALF_X - 1.2, 4.5, 0.0), PackedVector2Array([
		Vector2(5.8, 0.0), Vector2(5.8, SLAB_TOP - 4.5)]), 14, 0.65, 1.0)
	for f in 17:
		var yf := 7.6 + float(f) * 3.05
		lm.lathe("WhiteStucco", Vector3(HALF_X - 1.0, yf - 0.14, 0.0), PackedVector2Array([
			Vector2(6.35, 0.0), Vector2(6.35, 0.26)]), 14, 0.72, 1.02)

static func _in_hole(x0: float, x1: float, y0: float, y1: float) -> bool:
	return x1 > HOLE_X0 + 0.05 and x0 < HOLE_X1 - 0.05 and y1 > HOLE_Y0 + 0.05 and y0 < HOLE_Y1 - 0.05

static func _north_blue_glass_grid(lm: LandmarkMesh) -> void:
	# Arquitectonica's famous floating cyan-blue reflective glass curtain wall on the -Z face
	# (inset slightly from ends: x = -43.5..+43.5 m, y = 4.8..59.2 m), cleanly cut around the skycourt!
	var z_glass := -HALF_Z - 0.14
	var z_mul := -HALF_Z - 0.24
	# Four solid glass regions around the hole so the 15.5 x 15.5 m void stays 100% open
	var regions := [
		[-43.5, 43.5, 4.8, HOLE_Y0],
		[-43.5, HOLE_X0, HOLE_Y0, HOLE_Y1],
		[HOLE_X1, 43.5, HOLE_Y0, HOLE_Y1],
		[-43.5, 43.5, HOLE_Y1, 59.2],
	]
	for reg in regions:
		var rx0: float = float(reg[0])
		var rx1: float = float(reg[1])
		var ry0: float = float(reg[2])
		var ry1: float = float(reg[3])
		lm.box("BlueGlass", Vector3((rx0 + rx1) * 0.5, (ry0 + ry1) * 0.5, z_glass),
			Vector3(rx1 - rx0, ry1 - ry0, 0.18), Basis(), 0.0)

	# Crisp white square/rectangular mullion grid over the blue glass screen (skipping skycourt hole!)
	var cols := 24
	var rows := 18
	for r in rows + 1:
		var yr := lerpf(4.8, 59.2, float(r) / float(rows))
		if yr > HOLE_Y0 + 0.15 and yr < HOLE_Y1 - 0.15:
			lm.box("WhiteStucco", Vector3((-43.5 + HOLE_X0) * 0.5, yr, z_mul),
				Vector3(HOLE_X0 + 43.5, 0.24, 0.22), Basis(), 0.0)
			lm.box("WhiteStucco", Vector3((HOLE_X1 + 43.5) * 0.5, yr, z_mul),
				Vector3(43.5 - HOLE_X1, 0.24, 0.22), Basis(), 0.0)
		else:
			lm.box("WhiteStucco", Vector3(0.0, yr, z_mul), Vector3(87.2, 0.24, 0.22), Basis(), 0.0)

	for c in cols + 1:
		var xc := lerpf(-43.5, 43.5, float(c) / float(cols))
		if xc > HOLE_X0 + 0.15 and xc < HOLE_X1 - 0.15:
			lm.box("WhiteStucco", Vector3(xc, (4.8 + HOLE_Y0) * 0.5, z_mul),
				Vector3(0.24, HOLE_Y0 - 4.8, 0.22), Basis(), 0.0)
			lm.box("WhiteStucco", Vector3(xc, (HOLE_Y1 + 59.2) * 0.5, z_mul),
				Vector3(0.24, 59.2 - HOLE_Y1, 0.22), Basis(), 0.0)
		else:
			lm.box("WhiteStucco", Vector3(xc, (4.8 + 59.2) * 0.5, z_mul),
				Vector3(0.24, 54.4, 0.22), Basis(), 0.0)

	# Signature projecting bright yellow (#F2C632) triangular balcony on the blue glass grid!
	# Right-triangle cantilevered balcony + triangular yellow frame on upper-middle north face
	var tri_poly := PackedVector2Array([
		Vector2(-15.5, -HALF_Z - 0.15),
		Vector2(-9.2, -HALF_Z - 0.15),
		Vector2(-12.35, -HALF_Z - 2.85),
	])
	lm.poly_prism("SunYellow", tri_poly, 41.8, 42.25, true)
	# Elevated yellow triangular parapet & sculptural Postmodern triangular wall frame (y = 42.25..47.4 m)
	lm.beam("SunYellow", Vector3(-15.5, 42.3, -HALF_Z - 0.25), Vector3(-12.35, 42.3, -HALF_Z - 2.85), 0.26, 1.05, Vector3.UP)
	lm.beam("SunYellow", Vector3(-12.35, 42.3, -HALF_Z - 2.85), Vector3(-9.2, 42.3, -HALF_Z - 0.25), 0.26, 1.05, Vector3.UP)
	lm.beam("SunYellow", Vector3(-15.5, 42.2, -HALF_Z - 0.35), Vector3(-12.35, 47.6, -HALF_Z - 0.35), 0.42, 0.38, Vector3.FORWARD)
	lm.beam("SunYellow", Vector3(-12.35, 47.6, -HALF_Z - 0.35), Vector3(-9.2, 42.2, -HALF_Z - 0.35), 0.42, 0.38, Vector3.FORWARD)

static func _south_stucco_and_yellow_balconies(lm: LandmarkMesh) -> void:
	# South (+Z) crisp white stucco face with horizontal recessed window bands (skipping skycourt!)
	var z_win := HALF_Z + 0.04
	for f in 17:
		var yf := 6.8 + float(f) * 3.05
		if yf > HOLE_Y0 - 0.6 and yf < HOLE_Y1 + 0.6:
			lm.box("SouthGlass", Vector3((-43.0 + HOLE_X0 - 1.0) * 0.5, yf, z_win),
				Vector3(HOLE_X0 - 1.0 + 43.0, 1.45, 0.12), Basis(), 0.0)
			lm.box("SouthGlass", Vector3((HOLE_X1 + 1.0 + 43.0) * 0.5, yf, z_win),
				Vector3(43.0 - HOLE_X1 - 1.0, 1.45, 0.12), Basis(), 0.0)
		else:
			lm.box("SouthGlass", Vector3(0.0, yf, z_win), Vector3(86.0, 1.45, 0.12), Basis(), 0.0)

	# 4 stacked bright yellow (#F2C632) projecting balconies on the South white stucco facade!
	var yellow_ys := [15.8, 24.9, 34.1, 43.2]
	for yb_val in yellow_ys:
		var yb: float = float(yb_val)
		var bx := -14.0
		lm.box("SunYellow", Vector3(bx, yb - 0.16, HALF_Z + 1.15), Vector3(8.6, 0.32, 2.30), Basis(), 0.02)
		lm.box("SunYellow", Vector3(bx, yb + 0.55, HALF_Z + 2.18), Vector3(8.6, 1.10, 0.24), Basis(), 0.02)
		for sx in [-1.0, 1.0]:
			lm.box("SunYellow", Vector3(bx + float(sx) * 4.18, yb + 0.55, HALF_Z + 1.15),
				Vector3(0.24, 1.10, 2.30), Basis(), 0.02)

static func _skycourt_stair_palm_and_whirlpool(lm: LandmarkMesh) -> void:
	# Skycourt floor tile, jamb windows & glass safety railings (z = ±6.75 m) inside y = 33.0..48.5 m
	var hole_cx := (HOLE_X0 + HOLE_X1) * 0.5
	var hole_w := HOLE_X1 - HOLE_X0
	lm.box("WhiteStucco", Vector3(hole_cx, HOLE_Y0 + 0.12, 0.0), Vector3(hole_w, 0.24, 13.8), Basis(), 0.02)
	for sz in [-1.0, 1.0]:
		lm.box("BlueGlass", Vector3(hole_cx, HOLE_Y0 + 0.78, float(sz) * 6.72),
			Vector3(hole_w, 1.10, 0.12), Basis(), 0.0)
	# Jamb windows looking into the skycourt from West & East apartment piers
	for f in 4:
		var yj := HOLE_Y0 + 2.4 + float(f) * 3.1
		lm.box("SouthGlass", Vector3(HOLE_X0 + 0.04, yj, 0.0), Vector3(0.12, 1.7, 8.6), Basis(), 0.0)
		lm.box("SouthGlass", Vector3(HOLE_X1 - 0.04, yj, 0.0), Vector3(0.12, 1.7, 8.6), Basis(), 0.0)
	# Warm night downlights recessed into the skycourt ceiling soffit at y = 48.46 m
	for lx in [9.5, 13.75, 18.0]:
		lm.disc("SkyLamp", Vector3(float(lx), HOLE_Y1 - 0.04, 0.0), Vector3.DOWN, 0.65, 12)

	# 1) Iconic bright crimson-red (#D62828) helical spiral staircase rising y = 33.0..48.5 m!
	var sc := Vector3(17.6, HOLE_Y0, -1.6)
	var sh := HOLE_Y1 - HOLE_Y0
	lm.frustum("CrimsonRed", sc, 0.44, 0.42, sh, 12)
	var steps := 36
	var turns := 2.25
	var r_outer := 2.05
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var a0 := t0 * turns * TAU
		var a1 := t1 * turns * TAU
		var y0 := HOLE_Y0 + 0.25 + t0 * (sh - 0.4)
		var y1 := HOLE_Y0 + 0.25 + t1 * (sh - 0.4)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		# Cantilevered red tread
		lm.beam("CrimsonRed", Vector3(sc.x, y0, sc.z) + d0 * 0.38,
			Vector3(sc.x, y0, sc.z) + d0 * r_outer, 0.52, 0.14, Vector3.UP)
		# Continuous spiralling outer red stringer ribbon & handrail
		lm.beam("CrimsonRed", Vector3(sc.x, y0, sc.z) + d0 * r_outer,
			Vector3(sc.x, y1, sc.z) + d1 * r_outer, 0.18, 0.42, d0)
		lm.beam("CrimsonRed", Vector3(sc.x, y0 + 0.95, sc.z) + d0 * r_outer,
			Vector3(sc.x, y1 + 0.95, sc.z) + d1 * r_outer, 0.12, 0.14, d0)
		if i % 3 == 0:
			lm.beam("CrimsonRed", Vector3(sc.x, y0, sc.z) + d0 * r_outer,
				Vector3(sc.x, y0 + 0.95, sc.z) + d0 * r_outer, 0.08, 0.08, d0)

	# 2) Skycourt Royal Palm standing silhouettes against the open sky!
	lm.box("WhiteStucco", Vector3(9.8, HOLE_Y0 + 0.42, -0.8), Vector3(2.4, 0.55, 2.4), Basis(), 0.03)
	LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", Vector3(9.8, HOLE_Y0 + 0.65, -0.8), 11.4, 0.85)

	# 3) Square turquoise whirlpool Jacuzzi tub in the skycourt!
	var jc := Vector3(13.2, HOLE_Y0, 2.6)
	lm.box("WhiteStucco", jc + Vector3(0.0, 0.48, 0.0), Vector3(3.5, 0.72, 3.5), Basis(), 0.04)
	lm.box("PoolWater", jc + Vector3(0.0, 0.85, 0.0), Vector3(2.85, 0.06, 2.85), Basis(), 0.0)

static func _red_rooftop_vault(lm: LandmarkMesh) -> void:
	# Signature crimson-red (#D62828) barrel-vaulted rooftop penthouse prism (y = 59.5..64.0 m)!
	var x0 := -14.0
	var x1 := 14.0
	var xc := (x0 + x1) * 0.5
	var xl := x1 - x0
	var r_vault := 4.5
	var base_y := SLAB_TOP
	# Vertical knee wall from 59.5..60.4 m + semicircular barrel vault rising 3.6 m -> exact 64.0 m crown!
	var knee_top := 60.4
	var rise := HEIGHT_M - knee_top
	lm.box("CrimsonRed", Vector3(xc, (base_y + knee_top) * 0.5, 0.0),
		Vector3(xl, knee_top - base_y, r_vault * 2.0), Basis(), 0.03)

	var seg := 14
	var row_a := PackedVector3Array()
	var row_b := PackedVector3Array()
	for i in seg + 1:
		var ang := PI * float(i) / float(seg)
		var z := -cos(ang) * r_vault
		var y := knee_top + sin(ang) * rise
		row_a.append(Vector3(x0, y, z))
		row_b.append(Vector3(x1, y, z))
	lm.grid("CrimsonRed", [row_a, row_b], Vector3.UP)

	# Glazed semicircular end lunettes & crimson arch end-frames at x = x0 and x = x1
	for sx in [-1.0, 1.0]:
		var xe := x1 if sx > 0.0 else x0
		var n := Vector3(float(sx), 0.0, 0.0)
		var c_end := Vector3(xe, knee_top, 0.0)
		for i in seg:
			var a0 := PI * float(i) / float(seg)
			var a1 := PI * float(i + 1) / float(seg)
			var p0 := Vector3(xe, knee_top + sin(a0) * (rise - 0.15), -cos(a0) * (r_vault - 0.15))
			var p1 := Vector3(xe, knee_top + sin(a1) * (rise - 0.15), -cos(a1) * (r_vault - 0.15))
			lm.tri("BlueGlass", c_end, p0, p1, n, n, n, Vector2.ZERO, Vector2(1.0, 0.0), Vector2(0.5, 1.0))
			var r0 := Vector3(xe, knee_top + sin(a0) * (rise - 0.08), -cos(a0) * (r_vault - 0.08))
			var r1 := Vector3(xe, knee_top + sin(a1) * (rise - 0.08), -cos(a1) * (r_vault - 0.08))
			lm.beam("CrimsonRed", r0, r1, 0.24, 0.30, n)
	# Glowing penthouse clerestory lantern strip inside vault base
	lm.box("SkyLamp", Vector3(xc, knee_top + 0.35, 0.0), Vector3(xl - 1.2, 0.28, r_vault * 1.6), Basis(), 0.0)
