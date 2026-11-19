class_name LandmarkFtKauppatori
extends RefCounted

## Turku Market Square (Turun kauppatori, 2022 Saariston sydan redevelopment)
## in true metres aligned to the Engel grid (origin 60.451692 N, 22.266896 E,
## yaw_deg -35.3: +X NE Kauppiaskatu, +Z SE Eerikinkatu).
## y = G (0.30 m) matches TerrainBuilder._hero_y datum at the origin;
## conform() drapes granite framing courses per-vertex on GroundTruth and
## seats rigid pavilions, stage, basin, planters, masts and market clusters.

const G := 0.30
const BASE_Y := -0.25

const PAV_AURAKATU := [-60.9, -53.1, -31.5, 0.1]
const PAV_KAUPPIAS := [49.1, 56.8, -29.9, 1.4]
const PAV_EERIKIN_W := [-39.1, -6.5, 54.4, 61.7]
const PAV_EERIKIN_E := [-0.2, 32.3, 54.7, 62.1]

## Walker obstacle rectangles in model metres: [cx, cz, size_x, size_z, kind].
## Leaves the 6.3 m Eerikinkatu breezeway (-6.5 .. -0.2) open for walking.
const SOLID_RECTS := [
	[-57.0, -15.7, 7.8, 31.6, "pavilion"],
	[53.0, -14.2, 7.7, 31.3, "pavilion"],
	[-22.8, 58.1, 32.6, 7.3, "pavilion"],
	[16.05, 58.4, 32.5, 7.4, "pavilion"],
	[33.75, -41.05, 2.2, 2.2, "stage"],
	[-1.6, 12.1, 2.6, 2.6, "mast"],
	[-2.55, -44.5, 28.0, 12.6, "fountain"],
	[-53.8, 11.45, 6.7, 8.3, "planter"],
	[-53.75, 19.05, 6.7, 5.9, "planter"],
	[-53.7, 33.45, 6.7, 6.7, "planter"],
	[-53.65, 42.05, 6.7, 5.3, "planter"],
	[47.55, 11.85, 6.7, 6.7, "planter"],
	[47.55, 19.7, 6.7, 5.8, "planter"],
	[47.45, 34.75, 6.7, 5.5, "planter"],
	[47.3, 42.95, 6.8, 6.1, "planter"],
]

## [Rect2(x0, z0, w, h), anchor Vector2]: vertices inside keep local datum.
const RIGID_ZONES := [
	[Rect2(-65.5, -36.5, 20.5, 42.5), Vector2(-57.0, -15.7)],
	[Rect2(42.5, -35.0, 19.0, 42.5), Vector2(53.0, -14.2)],
	[Rect2(-44.0, 48.0, 82.0, 18.0), Vector2(-3.2, 58.2)],
	[Rect2(25.5, -45.5, 16.5, 12.5), Vector2(33.75, -39.4)],
	[Rect2(-18.0, -52.5, 31.0, 16.0), Vector2(-2.55, -44.5)],
	[Rect2(-59.0, 5.5, 11.0, 19.0), Vector2(-53.8, 15.0)],
	[Rect2(-59.0, 28.5, 11.0, 18.0), Vector2(-53.7, 37.5)],
	[Rect2(42.0, 6.5, 11.0, 18.0), Vector2(47.55, 15.5)],
	[Rect2(42.0, 30.0, 11.0, 18.0), Vector2(47.4, 38.5)],
	[Rect2(-59.5, -42.5, 5.5, 5.5), Vector2(-56.85, -39.95)],
	[Rect2(-58.5, 53.5, 5.5, 5.5), Vector2(-55.75, 56.0)],
	[Rect2(50.5, -42.0, 5.5, 5.5), Vector2(53.15, -39.45)],
	[Rect2(46.8, 56.0, 5.5, 5.5), Vector2(49.45, 58.75)],
	[Rect2(-7.0, 6.8, 10.8, 10.6), Vector2(-1.6, 12.1)],
	[Rect2(-38.0, -29.0, 74.0, 68.0), Vector2(0.0, 2.0)],
]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("RedGranite", LandmarkMaterials.pbr("pavement", "#8E574E", 2.5, 0.72))
	lm.use("DarkGranite", LandmarkMaterials.pbr("pavement", "#54575C", 2.2, 0.68))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#B68454", 2.0, 0.64))
	lm.use("DarkMetal", LandmarkMaterials.paint("#272B30", 0.46, 0.55))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6E5840", 1.8, 0.38, 0.78))
	lm.use("Glass", LandmarkMaterials.glass("#293842"))
	lm.use("BasinWater", LandmarkMaterials.pool_water("#2A5E6B", 0.07))
	lm.use("CanvasCream", LandmarkMaterials.pbr("render", "#EAE3D2", 2.0, 0.85))
	lm.use("CanvasAccent", LandmarkMaterials.pbr("render", "#C65A3A", 2.0, 0.84))
	lm.use("Foliage", LandmarkMaterials.pbr("lawn", "#476838", 1.6, 0.88))
	lm.use("Produce", LandmarkMaterials.pbr("render", "#C98A2C", 1.2, 0.76))
	lm.use("LanternGlow", LandmarkMaterials.lit("#FFF0CE", 2.4))

	_build_granite_grid(lm)
	_build_pavilions(lm)
	_build_stage(lm)
	_build_archipelago_basin(lm)
	_build_planters(lm)
	_build_masts(lm)
	_build_market_life(lm)
	lm.commit(model, "", true)

## Conforms Kauppatori vertices to GroundTruth slope while keeping each
## structure locally level on its anchor.
static func conform(root: Node3D, ground: GroundTruth) -> void:
	var model := root.get_node_or_null("Model") as Node3D
	if model == null or ground == null:
		return
	var to_world := root.transform * model.transform
	var origin_w := to_world * Vector3.ZERO
	if not ground.is_inside(origin_w.x, origin_w.z):
		return
	var m2u := WorldScale.metres_to_units()
	var base_g := ground.height_at_world(origin_w.x, origin_w.z)
	for part in LandmarkBuilder.parts(root):
		if part.mesh == null or part.mesh.get_surface_count() < 1:
			continue
		var arrays := MeshArrays.surface(part.mesh, 0).duplicate(true)
		var verts: PackedVector3Array = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).duplicate()
		var drape_each := String(part.name) == "RedGranite"
		for i in verts.size():
			var v := verts[i]
			var q := Vector2(v.x, v.z)
			if not drape_each:
				q = _anchor_for(q)
			else:
				var aq := _anchor_for(q)
				if q.x < -44.0 or q.x > 42.0 or q.y < -33.0 or q.y > 47.0:
					q = aq
			var w := to_world * Vector3(q.x, 0.0, q.y)
			if ground.is_inside(w.x, w.z):
				v.y += (ground.height_at_world(w.x, w.z) - base_g) / m2u
				verts[i] = v
		arrays[Mesh.ARRAY_VERTEX] = verts
		var nm := ArrayMesh.new()
		nm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		nm.surface_set_material(0, part.mesh.surface_get_material(0))
		MeshArrays.keep_surface(nm, arrays)
		part.mesh = nm

static func _anchor_for(p: Vector2) -> Vector2:
	for row: Array in RIGID_ZONES:
		if (row[0] as Rect2).has_point(p):
			return row[1] as Vector2
	return p

## --- Taivassalo red-granite market bands draped on square surface ------

static func _build_granite_grid(lm: LandmarkMesh) -> void:
	var y := G + 0.055
	for z: float in [-32.0, -14.0, 2.0, 20.0, 38.0, 46.5]:
		_drape_band_x(lm, "RedGranite", -44.5, 42.0, z, 0.72, y)
	for x: float in [-44.5, -24.0, -9.0, 8.0, 25.0, 42.0]:
		_drape_band_z(lm, "RedGranite", x, -32.0, 46.5, 0.68, y)
	_ring_band(lm, "RedGranite", Vector2(-1.6, 12.1), 3.1, 4.7, y, 28)

static func _drape_band_x(lm: LandmarkMesh, key: String, x0: float, x1: float,
		zc: float, hw: float, y: float) -> void:
	var n := maxi(ceili((x1 - x0) / 2.5), 1)
	for i in n:
		var a := lerpf(x0, x1, float(i) / float(n))
		var b := lerpf(x0, x1, float(i + 1) / float(n))
		lm.quad(key, Vector3(a, y, zc + hw), Vector3(b, y, zc + hw),
			Vector3(b, y, zc - hw), Vector3(a, y, zc - hw), Vector3.UP)

static func _drape_band_z(lm: LandmarkMesh, key: String, xc: float, z0: float,
		z1: float, hw: float, y: float) -> void:
	var n := maxi(ceili((z1 - z0) / 2.5), 1)
	for i in n:
		var a := lerpf(z0, z1, float(i) / float(n))
		var b := lerpf(z0, z1, float(i + 1) / float(n))
		lm.quad(key, Vector3(xc - hw, y, b), Vector3(xc + hw, y, b),
			Vector3(xc + hw, y, a), Vector3(xc - hw, y, a), Vector3.UP)

static func _ring_band(lm: LandmarkMesh, key: String, c: Vector2, r0: float,
		r1: float, y: float, seg: int) -> void:
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var p0 := Vector3(c.x + cos(a0) * r0, y, c.y + sin(a0) * r0)
		var p1 := Vector3(c.x + cos(a1) * r0, y, c.y + sin(a1) * r0)
		var q1 := Vector3(c.x + cos(a1) * r1, y, c.y + sin(a1) * r1)
		var q0 := Vector3(c.x + cos(a0) * r1, y, c.y + sin(a0) * r1)
		lm.quad(key, p0, q0, q1, p1, Vector3.UP)

## --- Three 2022 Toripaviljongit (Aurakatu, Kauppiaskatu, Eerikinkatu) --

static func _build_pavilions(lm: LandmarkMesh) -> void:
	# West (Aurakatu): roof pitches UP toward square (+X, slope_x = 1).
	var aura := [-63.9, -50.3, -34.9, 4.0]
	_pavilion_plinth(lm, -63.4, -50.8, -34.2, 3.2)
	_pavilion_core(lm, PAV_AURAKATU[0], PAV_AURAKATU[1], PAV_AURAKATU[2], PAV_AURAKATU[3], aura, G + 4.45, G + 7.25, 1, 0, 2.4)
	_sloped_canopy(lm, aura, G + 4.45, G + 7.25, 1, 0)
	for tz: float in [-26.0, -21.0, -16.0, -11.0, -6.0, -2.0]:
		_cafe_set(lm, -47.6, tz, tz > -14.0)

	# East (Kauppiaskatu): roof pitches UP toward square (-X, slope_x = -1).
	var kaup := [46.2, 59.7, -33.4, 5.5]
	_pavilion_plinth(lm, 46.8, 59.4, -32.6, 4.6)
	_pavilion_core(lm, PAV_KAUPPIAS[0], PAV_KAUPPIAS[1], PAV_KAUPPIAS[2], PAV_KAUPPIAS[3], kaup, G + 4.75, G + 8.60, -1, 0, 2.4)
	_sloped_canopy(lm, kaup, G + 4.75, G + 8.60, -1, 0)
	for tz: float in [-24.0, -19.0, -14.0, -9.0, -4.0, 0.5]:
		_cafe_set(lm, 43.8, tz, tz < -9.0)

	# South (Eerikinkatu): twin glazed wings under one 78.9 m canopy pitching UP toward square (-Z, slope_z = -1).
	var eeri := [-42.7, 36.2, 52.2, 64.2]
	_pavilion_plinth(lm, -42.0, 35.5, 52.6, 63.8)
	_pavilion_core(lm, PAV_EERIKIN_W[0], PAV_EERIKIN_W[1], PAV_EERIKIN_W[2], PAV_EERIKIN_W[3], eeri, G + 4.45, G + 7.05, 0, -1, 2.5)
	_pavilion_core(lm, PAV_EERIKIN_E[0], PAV_EERIKIN_E[1], PAV_EERIKIN_E[2], PAV_EERIKIN_E[3], eeri, G + 4.45, G + 7.05, 0, -1, 2.5)
	_sloped_canopy(lm, eeri, G + 4.45, G + 7.05, 0, -1)
	for tx: float in [-32.0, -26.0, -20.0, -14.0, 6.0, 12.0, 18.0, 24.0]:
		_cafe_set(lm, tx, 50.1, absf(tx) < 22.0)

static func _pavilion_plinth(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float) -> void:
	_box_mm(lm, "RedGranite", x0, x1, z0, z1, BASE_Y, G + 0.14)

static func _canopy_y(rect: Array, y_lo: float, y_hi: float, slope_x: int, slope_z: int, px: float, pz: float) -> float:
	if slope_x > 0:
		return lerpf(y_lo, y_hi, clampf((px - float(rect[0])) / maxf(float(rect[1]) - float(rect[0]), 0.1), 0.0, 1.0))
	if slope_x < 0:
		return lerpf(y_hi, y_lo, clampf((px - float(rect[0])) / maxf(float(rect[1]) - float(rect[0]), 0.1), 0.0, 1.0))
	if slope_z < 0:
		return lerpf(y_hi, y_lo, clampf((pz - float(rect[2])) / maxf(float(rect[3]) - float(rect[2]), 0.1), 0.0, 1.0))
	return lerpf(y_lo, y_hi, clampf((pz - float(rect[2])) / maxf(float(rect[3]) - float(rect[2]), 0.1), 0.0, 1.0))

static func _pavilion_core(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float,
		rect: Array, y_lo: float, y_hi: float, slope_x: int, slope_z: int, bay: float) -> void:
	var bot := G + 0.14
	var t00 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x0, z0) + 0.05
	var t10 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x1, z0) + 0.05
	var t11 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x1, z1) + 0.05
	var t01 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x0, z1) + 0.05
	var min_top := minf(minf(t00, t10), minf(t11, t01))
	# Full-height sloping glazed curtain walls meeting the canopy soffit with no air gap.
	lm.quad("Glass", Vector3(x0, bot, z0), Vector3(x1, bot, z0), Vector3(x1, t10, z0), Vector3(x0, t00, z0), Vector3.FORWARD)
	lm.quad("Glass", Vector3(x1, bot, z0), Vector3(x1, bot, z1), Vector3(x1, t11, z1), Vector3(x1, t10, z0), Vector3.RIGHT)
	lm.quad("Glass", Vector3(x1, bot, z1), Vector3(x0, bot, z1), Vector3(x0, t01, z1), Vector3(x1, t11, z1), Vector3.BACK)
	lm.quad("Glass", Vector3(x0, bot, z1), Vector3(x0, bot, z0), Vector3(x0, t00, z0), Vector3(x0, t01, z1), Vector3.LEFT)
	# Warm timber interior service core & under-eave fascia light band.
	_box_mm(lm, "Timber", x0 + 1.4, x1 - 1.4, z0 + 1.5, z1 - 1.5, bot, min_top - 0.45)
	_box_mm(lm, "LanternGlow", x0 + 0.2, x1 - 0.2, z0 + 0.2, z1 - 0.2, G + 3.95, G + 4.12)
	var nx := maxi(int((x1 - x0) / bay), 2)
	for i in nx + 1:
		var x := lerpf(x0, x1, float(i) / float(nx))
		var tz0 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x, z0) + 0.05
		var tz1 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x, z1) + 0.05
		lm.beam("DarkMetal", Vector3(x, bot, z0), Vector3(x, tz0, z0), 0.14, 0.14)
		lm.beam("DarkMetal", Vector3(x, bot, z1), Vector3(x, tz1, z1), 0.14, 0.14)
	var nz := maxi(int((z1 - z0) / bay), 2)
	for j in nz + 1:
		var z := lerpf(z0, z1, float(j) / float(nz))
		var tx0 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x0, z) + 0.05
		var tx1 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x1, z) + 0.05
		lm.beam("DarkMetal", Vector3(x0, bot, z), Vector3(x0, tx0, z), 0.14, 0.14)
		lm.beam("DarkMetal", Vector3(x1, bot, z), Vector3(x1, tx1, z), 0.14, 0.14)

## Cantilevered glulam soffit, transverse timber rafters & standing-seam canopy.
static func _sloped_canopy(lm: LandmarkMesh, rect: Array,
		y_lo: float, y_hi: float, slope_x: int, slope_z: int) -> void:
	var x0: float = rect[0]
	var x1: float = rect[1]
	var z0: float = rect[2]
	var z1: float = rect[3]
	var t := 0.38
	var h00 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x0, z0)
	var h10 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x1, z0)
	var h11 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x1, z1)
	var h01 := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, x0, z1)
	var b00 := Vector3(x0, h00, z0)
	var b10 := Vector3(x1, h10, z0)
	var b11 := Vector3(x1, h11, z1)
	var b01 := Vector3(x0, h01, z1)
	var u00 := b00 + Vector3(0, t, 0)
	var u10 := b10 + Vector3(0, t, 0)
	var u11 := b11 + Vector3(0, t, 0)
	var u01 := b01 + Vector3(0, t, 0)
	lm.quad("Timber", b00, b10, b11, b01, Vector3.DOWN)
	lm.quad("DarkMetal", u00, u01, u11, u10, Vector3.UP)
	lm.quad("DarkMetal", b00, u00, u10, b10, Vector3.FORWARD)
	lm.quad("DarkMetal", b10, u10, u11, b11, Vector3.RIGHT)
	lm.quad("DarkMetal", b11, u11, u01, b01, Vector3.BACK)
	lm.quad("DarkMetal", b01, u01, u00, b00, Vector3.LEFT)
	# Transverse glulam rafters visible under the canopy (~4.5 m spacing).
	var span := (z1 - z0) if slope_x != 0 else (x1 - x0)
	var nr := maxi(int(span / 4.5), 4)
	for i in range(1, nr):
		var frac := float(i) / float(nr)
		if slope_x != 0:
			var rz := lerpf(z0, z1, frac)
			lm.beam("Timber", Vector3(x0 + 0.3, h00 - 0.10, rz), Vector3(x1 - 0.3, h10 - 0.10, rz), 0.18, 0.28)
		else:
			var rx := lerpf(x0, x1, frac)
			lm.beam("Timber", Vector3(rx, h00 - 0.10, z0 + 0.3), Vector3(rx, h01 - 0.10, z1 - 0.3), 0.18, 0.28)
	# Steel columns along the high square-facing cantilevered apron reaching flush to soffit.
	var cols := 8 if slope_z != 0 else 5
	for i in cols:
		var tcol := (float(i) + 0.4) / (float(cols) - 0.2)
		var cx := lerpf(x0 + 1.5, x1 - 1.5, tcol) if slope_z != 0 else (x1 - 0.9 if slope_x > 0 else x0 + 0.9)
		var cz := lerpf(z0 + 1.5, z1 - 1.5, tcol) if slope_x != 0 else (z0 + 0.9 if slope_z < 0 else z1 - 0.9)
		var htop := _canopy_y(rect, y_lo, y_hi, slope_x, slope_z, cx, cz) + 0.05
		lm.beam("DarkMetal", Vector3(cx, G, cz), Vector3(cx, htop, cz), 0.18, 0.18)

## --- Kanttarelli (chanterelle) timber & glass stage --------------------

static func _build_stage(lm: LandmarkMesh) -> void:
	# Stepped granite podium: x=[27.1..40.4], z=[-43.9..-34.8].
	_box_mm(lm, "DarkGranite", 27.1, 40.4, -43.9, -34.8, BASE_Y, G + 0.35)
	_box_mm(lm, "RedGranite", 28.0, 39.5, -43.1, -35.6, G + 0.35, G + 0.65)
	# Flared Kerto-Q timber post at way:1156832454 (33.75, -41.05).
	var pc := Vector3(33.75, G + 0.65, -41.05)
	lm.lathe("Timber", pc, PackedVector2Array([
		Vector2(0.55, 0.0), Vector2(0.48, 1.4), Vector2(0.95, 2.8), Vector2(2.6, 3.85)]), 10)
	# 12 radial glulam ribs fanning to elliptic chanterelle canopy rim.
	var cc := Vector3(33.75, G + 4.85, -39.4)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var rim := cc + Vector3(cos(a) * 6.5, 0.55 + 0.35 * sin(a), sin(a) * 4.55)
		lm.beam("Timber", pc + Vector3(0, 3.65, 0), rim, 0.18, 0.24)
		var a_next := TAU * float(i + 1) / 12.0
		var rim_n := cc + Vector3(cos(a_next) * 6.5, 0.55 + 0.35 * sin(a_next), sin(a_next) * 4.55)
		lm.beam("DarkMetal", rim, rim_n, 0.14, 0.16)
		var mid := cc + Vector3(cos(a) * 1.4, 0.05, sin(a) * 1.0)
		var mid_n := cc + Vector3(cos(a_next) * 1.4, 0.05, sin(a_next) * 1.0)
		lm.quad("Glass", mid, mid_n, rim_n + Vector3(0, 0.08, 0), rim + Vector3(0, 0.08, 0), Vector3.UP)

## --- Saariston sydan (archipelago water feature) -----------------------

static func _build_archipelago_basin(lm: LandmarkMesh) -> void:
	# Relation member 4: x=[-16.7..11.6], z=[-51.0..-38.0] (28.3 x 13.0 m).
	var x0 := -16.7
	var x1 := 11.6
	var z0 := -51.0
	var z1 := -38.0
	var rt := G + 0.24
	# Dark granite floor & 0.42 m wide coping kerb around basin perimeter.
	_box_mm(lm, "DarkGranite", x0, x1, z0, z1, BASE_Y, G + 0.08)
	_box_mm(lm, "DarkGranite", x0, x1, z0, z0 + 0.44, G + 0.08, rt)
	_box_mm(lm, "DarkGranite", x0, x1, z1 - 0.44, z1, G + 0.08, rt)
	_box_mm(lm, "DarkGranite", x0, x0 + 0.44, z0 + 0.44, z1 - 0.44, G + 0.08, rt)
	_box_mm(lm, "DarkGranite", x1 - 0.44, x1, z0 + 0.44, z1 - 0.44, G + 0.08, rt)
	# Reflecting water sheet.
	lm.quad("BasinWater",
		Vector3(x0 + 0.44, G + 0.16, z1 - 0.44), Vector3(x1 - 0.44, G + 0.16, z1 - 0.44),
		Vector3(x1 - 0.44, G + 0.16, z0 + 0.44), Vector3(x0 + 0.44, G + 0.16, z0 + 0.44), Vector3.UP)
	# Sculpted granite & bronze archipelago skerries + low central mist jets.
	var islands := [
		[-12.2, -45.4, 2.3, 1.5, 0.44, true], [-8.8, -42.5, 1.8, 1.2, 0.38, false],
		[-5.1, -46.2, 2.5, 1.6, 0.52, true], [-1.8, -43.0, 2.9, 1.8, 0.58, false],
		[2.0, -45.6, 2.2, 1.4, 0.48, true], [5.4, -42.8, 1.9, 1.3, 0.42, false],
		[8.6, -45.8, 2.1, 1.4, 0.46, true], [-10.0, -47.2, 1.1, 0.9, 0.30, false],
		[0.4, -47.6, 1.3, 0.9, 0.32, true],
	]
	for isl: Array in islands:
		var key := "RedGranite" if bool(isl[5]) else "Bronze"
		var b := Basis(Vector3.UP, float(isl[0]) * 0.25)
		lm.box(key, Vector3(float(isl[0]), G + float(isl[4]) * 0.5 + 0.08, float(isl[1])),
			Vector3(float(isl[2]), float(isl[4]), float(isl[3])), b, 0.12)
	for jx: float in [-4.5, -1.8, 1.0]:
		lm.frustum("BasinWater", Vector3(jx, G + 0.16, -44.2), 0.18, 0.04, 1.05, 6)

## --- Eight sculpted skerry bench-planters (way:1103029144..51) ---------

static func _build_planters(lm: LandmarkMesh) -> void:
	var planters := [
		[-57.2, -50.3, 7.3, 15.6, 1], [-57.2, -50.3, 16.1, 22.0, 1],
		[-57.2, -50.3, 30.1, 36.8, 1], [-57.2, -50.3, 39.4, 44.7, 1],
		[44.1, 50.9, 8.5, 15.2, -1], [44.1, 50.9, 16.8, 22.6, -1],
		[44.1, 50.9, 32.0, 37.5, -1], [44.1, 50.9, 39.9, 46.0, -1],
	]
	for p: Array in planters:
		var x0: float = p[0]
		var x1: float = p[1]
		var z0: float = p[2]
		var z1: float = p[3]
		var inward: int = p[4]
		_box_mm(lm, "DarkGranite", x0, x1, z0, z1, BASE_Y, G + 0.54, 0.12)
		_box_mm(lm, "Timber", x0 + 0.15, x1 - 0.15, z0 + 0.35, z1 - 0.35, G + 0.42, G + 0.48)
		# Square-facing slatted timber bench ledge along inner edge.
		var bx0 := x1 - 0.1 if inward > 0 else x0 - 0.55
		var bx1 := x1 + 0.55 if inward > 0 else x0 + 0.1
		_box_mm(lm, "Timber", bx0, bx1, z0 + 0.45, z1 - 0.45, G + 0.38, G + 0.46)
		# Multi-tuft pine/shrub mounds inside the granite planter bed.
		var cx := (x0 + x1) * 0.5
		var cz := (z0 + z1) * 0.5
		for dz: float in [-1.6, 0.0, 1.6]:
			if absf(dz) < (z1 - z0) * 0.35:
				lm.lathe("Foliage", Vector3(cx + sin(dz) * 0.6, G + 0.48, cz + dz), PackedVector2Array([
					Vector2(0.05, 0.0), Vector2(1.4, 0.25), Vector2(1.2, 0.72), Vector2(0.25, 1.05)]), 8)

## --- Five 11.0 m multi-lantern candelabra square masts -----------------

static func _build_masts(lm: LandmarkMesh) -> void:
	# Circular bench & granite plinth at central ringed mast (-1.6, 12.1).
	lm.lathe("DarkGranite", Vector3(-1.6, BASE_Y, 12.1), PackedVector2Array([
		Vector2(1.35, 0.0), Vector2(1.35, G - BASE_Y + 0.48)]), 12)
	lm.lathe("Timber", Vector3(-1.6, G + 0.48, 12.1), PackedVector2Array([
		Vector2(1.42, 0.0), Vector2(1.42, 0.08)]), 12)
	var masts := [
		[-56.85, -39.95, 11.0], [-55.75, 56.0, 11.0],
		[53.15, -39.45, 11.0], [49.45, 58.75, 11.0],
		[-1.6, 12.1, 11.0],
	]
	for m: Array in masts:
		var mx: float = m[0]
		var mz: float = m[1]
		var top_y: float = m[2]
		lm.lathe("DarkGranite", Vector3(mx, BASE_Y, mz), PackedVector2Array([
			Vector2(0.55, 0.0), Vector2(0.50, G - BASE_Y + 0.55)]), 8)
		lm.frustum("DarkMetal", Vector3(mx, G + 0.55, mz), 0.24, 0.11, top_y - G - 1.15, 8)
		lm.spire("DarkMetal", Vector3(mx, top_y - 0.60, mz), 0.10, 0.60, 0.0, 6)
		for k in 4:
			var a := PI * 0.25 + PI * 0.5 * float(k)
			var arm_base := Vector3(mx, top_y - 2.1, mz)
			var head := Vector3(mx + cos(a) * 0.95, top_y - 1.35, mz + sin(a) * 0.95)
			lm.beam("DarkMetal", arm_base, head, 0.07, 0.07)
			lm.frustum("LanternGlow", head - Vector3(0, 0.35, 0), 0.14, 0.18, 0.38, 8)
			lm.spire("DarkMetal", head + Vector3(0, 0.03, 0), 0.22, 0.16, 0.0, 8)

## --- Daytime Nordic market tents, produce stalls & two torikahvilat ----

static func _build_market_life(lm: LandmarkMesh) -> void:
	# West aisle (z=-19..29, x=-31..-15): seasonal & local produce tents + wagon.
	for row_z: float in [-20.0, -9.0, 16.0, 27.0]:
		for col_i in 3:
			var cx := -31.0 + float(col_i) * 5.2
			_market_tent(lm, cx, row_z, (col_i + int(absf(row_z))) % 2 == 0, 0.0)
	# East aisle (z=-19..29, x=11..29): flower, berry & bakery tents.
	for row_z: float in [-20.0, -9.0, 20.0, 30.0]:
		for col_i in 3:
			var cx := 12.0 + float(col_i) * 5.2
			_market_tent(lm, cx, row_z, (col_i + int(absf(row_z))) % 2 == 1, 0.0)
	# Traditional market sales wagon near north-central aisle.
	_market_wagon(lm, 0.5, -18.0)
	# Mapped OSM torikahvilat inside central market field:
	# Café Eino (-28.2, 4.3) and Torikahvila Kisälli (18.3, 8.4).
	_torikahvila(lm, -27.5, 4.5, true)
	_torikahvila(lm, 18.0, 8.4, false)

static func _market_tent(lm: LandmarkMesh, cx: float, cz: float, accent: bool, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var hw := 1.45
	var hd := 1.40
	var eave := G + 2.15
	for sx: float in [-hw, hw]:
		for sz: float in [-hd, hd]:
			var p := Vector3(cx, G, cz) + b * Vector3(sx, 0.0, sz)
			lm.beam("DarkMetal", p, p + Vector3(0, 2.15, 0), 0.055, 0.055)
	var ckey := "CanvasAccent" if accent else "CanvasCream"
	lm.gable(ckey, Vector3(cx, eave, cz), hw * 2.0, hd * 2.0, 0.65, b, 0.18, ckey)
	lm.box("Timber", Vector3(cx, G + 0.41, cz), Vector3(2.3, 0.82, 0.92), b, 0.0)
	var top_key := "Foliage" if (int(absf(cx + cz)) % 3 == 0) else "Produce"
	for kx: float in [-0.75, 0.0, 0.75]:
		lm.box(top_key, Vector3(cx, G + 0.93, cz) + b * Vector3(kx, 0.0, 0.0),
			Vector3(0.58, 0.22, 0.66), b, 0.0)

static func _market_wagon(lm: LandmarkMesh, cx: float, cz: float) -> void:
	var b := Basis(Vector3.UP, 0.15)
	lm.box("Timber", Vector3(cx, G + 0.88, cz), Vector3(3.4, 1.1, 1.85), b, 0.0)
	lm.gable("CanvasAccent", Vector3(cx, G + 2.25, cz), 2.1, 3.6, 0.45,
		Basis(Vector3.UP, PI * 0.5 + 0.15), 0.15, "CanvasCream")
	for sx: float in [-1.1, 1.1]:
		for sz: float in [-0.96, 0.96]:
			lm.box("DarkMetal", Vector3(cx, G + 0.32, cz) + b * Vector3(sx, 0.0, sz),
				Vector3(0.58, 0.58, 0.12), b, 0.0)
			lm.beam("DarkMetal", Vector3(cx, G + 1.4, cz) + b * Vector3(sx, 0.0, sz * 0.85),
				Vector3(cx, G + 2.25, cz) + b * Vector3(sx, 0.0, sz * 0.85), 0.06, 0.06)

static func _torikahvila(lm: LandmarkMesh, cx: float, cz: float, west_side: bool) -> void:
	var k_off := -3.2 if west_side else 3.2
	_market_tent(lm, cx + k_off, cz, true, 0.0)
	for dx: float in [-1.6, 1.2]:
		for dz: float in [-2.6, 0.0, 2.6]:
			_cafe_set(lm, cx + dx, cz + dz, true)

static func _cafe_set(lm: LandmarkMesh, cx: float, cz: float, parasol: bool) -> void:
	lm.frustum("DarkMetal", Vector3(cx, G, cz), 0.04, 0.035, 0.72, 6)
	lm.frustum("Timber", Vector3(cx, G + 0.72, cz), 0.42, 0.42, 0.05, 8)
	for side: float in [-0.62, 0.62]:
		lm.box("Timber", Vector3(cx + side, G + 0.42, cz), Vector3(0.36, 0.06, 0.36), Basis(), 0.0)
		lm.box("DarkMetal", Vector3(cx + side, G + 0.21, cz), Vector3(0.32, 0.42, 0.32), Basis(), 0.0)
	if parasol:
		lm.frustum("DarkMetal", Vector3(cx, G + 0.76, cz), 0.025, 0.025, 1.62, 6)
		lm.lathe("CanvasCream", Vector3(cx, G + 2.15, cz), PackedVector2Array([
			Vector2(1.18, 0.0), Vector2(0.02, 0.42)]), 8)

static func _box_mm(lm: LandmarkMesh, key: String, x0: float, x1: float,
		z0: float, z1: float, y0: float, y1: float, bevel: float = -1.0) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(maxf(x1 - x0, 0.05), maxf(y1 - y0, 0.02), maxf(z1 - z0, 0.05)), Basis(), bevel)
