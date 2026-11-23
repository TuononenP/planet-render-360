class_name LandmarkMiFlaglerMonument
extends RefCounted

## Flagler Memorial Monument — Flagler Monument Island, Biscayne Bay MI-4D
## Site: circular island in Biscayne Bay (25.783600, -80.153600, yaw_deg = 0.0).
## Erected by Carl G. Fisher & John B. Orr (1920), sculptor Harry P. Pedersen, in memory of Henry M. Flagler.
## Measured envelope (18.0 x 18.0 m plaza court, height_m = 33.5 / 110 ft):
##   - Octagonal pale oolitic limestone & grey granite terrace plaza (y = -0.35..0.55 m) with perimeter
##     stone bollards and bronze chains, rising in 3 granite steps to the central ashlar die (y = 0.55..5.40 m).
##   - Four projecting corner buttress pedestals inscribed INDUSTRY, PROSPERITY, EDUCATION, PIONEER,
##     each carrying a 4.75 m sculpted allegorical classical figure (y = 5.10..9.85 m) flanking the base.
##   - Slender tapering white oolitic limestone obelisk shaft (y = 5.40..31.35 m) crowned by a steep
##     classical pyramidion reaching exact y = 33.50 m, warmly floodlit across Biscayne Bay at night.

const HEIGHT_M := 33.5
const SHAFT_BASE_Y := 5.40
const PYRAMIDION_BASE_Y := 31.35

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("ObeliskStone", LandmarkMaterials.pbr("limestone", "#EEE9DD", 2.8))
	lm.use("PedestalStone", LandmarkMaterials.pbr("limestone", "#DFD8C8", 2.4))
	lm.use("GraniteStep", LandmarkMaterials.pbr("stone", "#B6B3AC", 3.0))
	lm.use("StatueStone", LandmarkMaterials.pbr("limestone", "#E6E0D3", 2.0, 0.78))
	lm.use("Bronze", LandmarkMaterials.paint("#594937", 0.44, 0.62))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A6", 0.95))

	_build_octagonal_plaza_and_steps(lm)
	_build_pedestal_and_buttresses(lm)
	_build_allegorical_figures(lm)
	_build_obelisk_shaft_and_pyramidion(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.87, 0.60)
	var gold := Color(1.0, 0.82, 0.50)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(7.2, 0.85, 7.2), Vector3(0.0, 18.5, 0.0), 46.0, 1.25, 42.0, warm],
		[Vector3(-7.2, 0.85, 7.2), Vector3(0.0, 18.5, 0.0), 46.0, 1.25, 42.0, warm],
		[Vector3(7.2, 0.85, -7.2), Vector3(0.0, 18.5, 0.0), 46.0, 1.25, 42.0, warm],
		[Vector3(-7.2, 0.85, -7.2), Vector3(0.0, 18.5, 0.0), 46.0, 1.25, 42.0, warm],
		[Vector3(0.0, 1.10, 8.2), Vector3(0.0, 8.0, 2.2), 26.0, 1.10, 48.0, gold],
		[Vector3(0.0, 1.10, -8.2), Vector3(0.0, 8.0, -2.2), 26.0, 1.10, 48.0, gold],
	])

static func _build_octagonal_plaza_and_steps(lm: LandmarkMesh) -> void:
	# 17.6 x 17.6 m octagonal island monument plaza (y = -0.35..0.55 m)
	var plaza := TowerSpec.plan("chamfer", 17.6, 17.6, 4.8, 0.0, 0.0)
	lm.poly_prism("GraniteStep", plaza, -0.35, 0.55)
	var inlay := TowerSpec.plan("chamfer", 15.2, 15.2, 4.2, 0.0, 0.0)
	lm.poly_prism("PedestalStone", inlay, 0.55, 0.64)

	# Three crisp stepped dark-grey/pale granite plinth risers (side.jpg)
	lm.box("GraniteStep", Vector3(0.0, 0.86, 0.0), Vector3(11.6, 0.44, 11.6), Basis(), 0.02)
	lm.box("GraniteStep", Vector3(0.0, 1.30, 0.0), Vector3(9.8, 0.44, 9.8), Basis(), 0.02)
	lm.box("GraniteStep", Vector3(0.0, 1.74, 0.0), Vector3(8.2, 0.44, 8.2), Basis(), 0.02)

	# Eight octagonal perimeter stone bollards with bronze chain swags & 4 uplight housings
	var post_pts := PackedVector3Array()
	for i: int in 8:
		var a := (float(i) + 0.5) * PI * 0.25
		var p := Vector3(cos(a) * 7.8, 0.64, sin(a) * 7.8)
		lm.box("PedestalStone", p + Vector3(0.0, 0.52, 0.0), Vector3(0.46, 1.04, 0.46), Basis(), 0.02)
		lm.spire("PedestalStone", p + Vector3(0.0, 1.04, 0.0), 0.25, 0.22, 0.04, 4)
		post_pts.append(p + Vector3(0.0, 0.82, 0.0))
	for i: int in 8:
		var pa: Vector3 = post_pts[i]
		var pb: Vector3 = post_pts[(i + 1) % 8]
		var pm := (pa + pb) * 0.5 - Vector3(0.0, 0.16, 0.0)
		lm.beam("Bronze", pa, pm, 0.05, 0.05)
		lm.beam("Bronze", pm, pb, 0.05, 0.05)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var lp := Vector3(sx * 6.2, 0.68, sz * 6.2)
			lm.box("Bronze", lp, Vector3(0.54, 0.18, 0.54), Basis(), 0.0)
			lm.disc("Lamp", lp + Vector3(0.0, 0.10, 0.0), Vector3.UP, 0.20, 10)

static func _build_pedestal_and_buttresses(lm: LandmarkMesh) -> void:
	# Central ashlar limestone die (y = 1.96..5.40 m) with FLAGLER bronze dedication plaques
	lm.box("PedestalStone", Vector3(0.0, 2.30, 0.0), Vector3(5.6, 0.68, 5.6), Basis(), 0.03)
	lm.box("PedestalStone", Vector3(0.0, 3.85, 0.0), Vector3(4.6, 2.45, 4.6), Basis(), 0.03)
	lm.box("ObeliskStone", Vector3(0.0, 5.24, 0.0), Vector3(5.0, 0.34, 5.0), Basis(), 0.02)

	for side: int in 4:
		var ang := float(side) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var b := Basis(t3, Vector3.UP, n3)
		# Inscribed FLAGLER dedication tablet on each cardinal face
		lm.box("Bronze", Vector3(0.0, 2.32, 0.0) + n3 * 2.83, Vector3(1.85, 0.36, 0.08), b, 0.0)
		lm.box("Bronze", Vector3(0.0, 3.85, 0.0) + n3 * 2.33, Vector3(1.65, 0.95, 0.08), b, 0.0)

	# Four projecting corner statue pedestals & stepped obelisk backing buttresses (side.jpg)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var cx := sx * 2.45
			var cz := sz * 2.45
			lm.box("PedestalStone", Vector3(cx, 2.32, cz), Vector3(2.05, 0.72, 2.05), Basis(), 0.02)
			lm.box("PedestalStone", Vector3(cx, 3.72, cz), Vector3(1.76, 2.10, 1.76), Basis(), 0.03)
			lm.box("ObeliskStone", Vector3(cx, 4.94, cz), Vector3(1.96, 0.34, 1.96), Basis(), 0.02)
			# Bronze title frieze plaque (PROSPERITY / INDUSTRY / EDUCATION / PIONEER)
			var out_d := Vector3(sx, 0.0, sz).normalized()
			var out_t := Vector3(-out_d.z, 0.0, out_d.x)
			lm.box("Bronze", Vector3(cx, 4.42, cz) + out_d * 0.90,
				Vector3(1.10, 0.24, 0.08), Basis(out_t, Vector3.UP, out_d), 0.0)
			# Stepped stone backing pier behind each allegorical figure (y = 5.10..10.15 m)
			var bx := sx * 1.62
			var bz := sz * 1.62
			lm.box("PedestalStone", Vector3(bx, 7.50, bz), Vector3(1.35, 4.80, 1.35), Basis(), 0.02)
			lm.spire("ObeliskStone", Vector3(bx, 9.90, bz), 0.68, 0.55, 0.18, 4)

static func _build_allegorical_figures(lm: LandmarkMesh) -> void:
	# Four 4.7 m sculpted pale-limestone allegorical statues at the four diagonal corners (y = 5.11..9.82 m):
	# 0: Industry (+X,+Z), 1: Prosperity (-X,+Z), 2: Education (-X,-Z), 3: Pioneer (+X,-Z)
	var corners: Array[Vector2] = [
		Vector2(2.48, 2.48),
		Vector2(-2.48, 2.48),
		Vector2(-2.48, -2.48),
		Vector2(2.48, -2.48),
	]
	for idx: int in corners.size():
		var c2: Vector2 = corners[idx]
		var base := Vector3(c2.x, 5.11, c2.y)
		var out_n := Vector3(c2.x, 0.0, c2.y).normalized()
		var side_t := Vector3(-out_n.z, 0.0, out_n.x)
		# Statue plinth socle
		lm.box("StatueStone", base + Vector3(0.0, 0.16, 0.0), Vector3(1.28, 0.32, 1.28), Basis(), 0.02)
		# Classical draped robe / figure silhouette (height ~4.35 m above socle -> y = 9.78 m)
		var fig_base := base + Vector3(0.0, 0.32, 0.0)
		lm.lathe("StatueStone", fig_base, PackedVector2Array([
			Vector2(0.56, 0.0), Vector2(0.52, 0.85), Vector2(0.46, 1.85),
			Vector2(0.50, 2.65), Vector2(0.54, 3.25), Vector2(0.24, 3.55),
			Vector2(0.28, 3.92), Vector2(0.22, 4.22), Vector2(0.0, 4.36)]), 12, 1.0, 0.88, atan2(out_n.z, out_n.x), false)
		# Draped vertical folds & shoulder mantle
		for f: float in [-0.22, 0.0, 0.22]:
			lm.beam("StatueStone", fig_base + out_n * 0.36 + side_t * f + Vector3(0.0, 0.15, 0.0),
				fig_base + out_n * 0.30 + side_t * (f * 0.85) + Vector3(0.0, 2.75, 0.0), 0.16, 0.14)

		# Distinct sculptural attributes per allegorical figure (matching side.jpg insets!)
		var chest := fig_base + Vector3(0.0, 2.85, 0.0) + out_n * 0.34
		if idx == 0:
			# INDUSTRY: cogwheel cradled against chest + vertical hammer at side
			lm.disc("StatueStone", chest + out_n * 0.14, out_n, 0.42, 12)
			lm.beam("StatueStone", chest + side_t * 0.42, fig_base + side_t * 0.45 + Vector3(0.0, 1.25, 0.0), 0.14, 0.14)
		elif idx == 1:
			# PROSPERITY: overflowing horn of plenty (cornucopia) raised on left shoulder
			lm.beam("StatueStone", chest - side_t * 0.20, chest + side_t * 0.44 + Vector3(0.0, 0.78, 0.0), 0.26, 0.26)
			lm.frustum("StatueStone", chest + side_t * 0.44 + Vector3(0.0, 0.68, 0.0), 0.14, 0.30, 0.48, 8)
		elif idx == 2:
			# EDUCATION: open tablet/tome held forward in right arm + scroll in left
			var b_book := Basis(side_t, Vector3.UP, out_n)
			lm.box("StatueStone", chest + side_t * 0.24 + out_n * 0.10, Vector3(0.48, 0.56, 0.22), b_book, 0.0)
			lm.beam("StatueStone", chest - side_t * 0.36, chest - side_t * 0.42 - Vector3(0.0, 0.72, 0.0), 0.16, 0.16)
		else:
			# PIONEER: left arm raised shading brow + right hand resting on upright shovel (side.jpg!)
			lm.beam("StatueStone", chest + side_t * 0.36,
				fig_base + side_t * 0.16 + out_n * 0.26 + Vector3(0.0, 4.18, 0.0), 0.16, 0.16)
			lm.beam("StatueStone", fig_base - side_t * 0.42, fig_base - side_t * 0.42 + Vector3(0.0, 2.55, 0.0), 0.11, 0.11)
			lm.box("StatueStone", fig_base - side_t * 0.42 + Vector3(0.0, 0.30, 0.0), Vector3(0.32, 0.52, 0.10), Basis(), 0.0)

static func _build_obelisk_shaft_and_pyramidion(lm: LandmarkMesh) -> void:
	# Moulded base collar & ashlar necking band on lower obelisk (y = 5.40..10.20 m)
	lm.spire("ObeliskStone", Vector3(0.0, SHAFT_BASE_Y, 0.0), 1.82, 0.55, 1.72, 4)
	lm.box("PedestalStone", Vector3(0.0, 10.12, 0.0), Vector3(3.26, 0.22, 3.26), Basis(), 0.0)

	# Slender tapering 4-sided white limestone obelisk shaft (y = 5.95..31.35 m, hw 1.72 -> 0.94 m)
	lm.spire("ObeliskStone", Vector3(0.0, 5.95, 0.0), 1.72, PYRAMIDION_BASE_Y - 5.95, 0.94, 4)
	# Subtle upper necking fillet right below the pyramidion
	lm.box("PedestalStone", Vector3(0.0, PYRAMIDION_BASE_Y - 0.10, 0.0), Vector3(1.94, 0.18, 1.94), Basis(), 0.0)

	# Classical steep pyramidion cap rising from 31.35 m to exact tip y = HEIGHT_M (33.50 m)
	lm.spire("ObeliskStone", Vector3(0.0, PYRAMIDION_BASE_Y, 0.0), 0.94, HEIGHT_M - PYRAMIDION_BASE_Y, 0.0, 4)
