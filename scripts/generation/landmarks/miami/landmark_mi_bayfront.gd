class_name LandmarkMiBayfront
extends RefCounted

## Skyviews Miami Observation Wheel, Bayside Pavilions & Bayfront Amphitheatre — MI-2A.6
## Site: 401 Biscayne Blvd, OSM way 648127409 + rel 7417722 (25.778315, -80.186289, yaw_deg 0.0).
## Measured envelope & components (Commons front/quarter/side, height_m = 60.0):
##   - Skyviews Miami 60.0 m (196 ft) observation wheel centred at (0, 0, 0) built via
##     LandmarkWheel.build(lm, 60.0, 52.8), dressed with twin cyan (#00E5FF) & magenta (#FF2EA6)
##     Lit LED rim rings and radial spoke light bars for Miami's bayfront night skyline.
##   - Two flanking open-air Bayside Marketplace waterfront pavilions (y = 0..10.5 m) to the
##     NW and SW with crisp white stucco colonnades, teak promenade decks, BAYSIDE entry portal,
##     and terracotta gabled/barrel-tile roofs.
##   - Bayfront Park tensile-inspired white amphitheatre stage shell (y = 0..18.5 m) and slender
##     white steel laser/lighting lattice tower (28.0 m) to the south (+Z).

const HEIGHT_M := 60.0
const WHEEL_DIAM := 52.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkWheel.build(lm, HEIGHT_M, WHEEL_DIAM)
	lm.use("CyanLamp", LandmarkMaterials.lit("#00E5FF", 0.90))
	lm.use("MagentaLamp", LandmarkMaterials.lit("#FF2EA6", 0.85))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#F4F1EA", 3.5))
	lm.use("Terracotta", LandmarkMaterials.pbr("terracotta", "#BA5B3C", 2.2))
	lm.use("Teak", LandmarkMaterials.pbr("wood", "#826142", 2.5))
	lm.use("PalmTrunk", LandmarkMaterials.pbr("concrete", "#B9B3A7", 2.0))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#356B2E", 2.0))

	_build_wheel_led_tubes(lm)
	_build_bayside_pavilions(lm)
	_build_amphitheatre_and_laser_tower(lm)
	lm.commit(model)

	var cyan := Color(0.20, 0.88, 1.0)
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.0, 1.8, -18.0), Vector3(0.0, 31.5, 0.0), 54.0, 1.15, 58.0, cyan],
		[Vector3(-16.0, 1.8, 18.0), Vector3(0.0, 31.5, 0.0), 54.0, 1.15, 58.0, cyan],
		[Vector3(-6.0, 1.8, -34.0), Vector3(-24.0, 6.5, -34.0), 52.0, 0.95, 36.0, warm],
		[Vector3(-6.0, 1.8, 32.0), Vector3(-24.0, 6.5, 32.0), 52.0, 0.95, 36.0, warm],
		[Vector3(-6.0, 1.8, 44.0), Vector3(-6.0, 11.0, 64.0), 54.0, 1.10, 40.0, warm],
	])

static func _build_wheel_led_tubes(lm: LandmarkMesh) -> void:
	var r := WHEEL_DIAM * 0.5
	var cs := clampf(WHEEL_DIAM * 0.035, 1.2, 5.0)
	var hub_y := maxf(HEIGHT_M - r - cs * 1.1, r + cs * 1.5)
	var hub := Vector3(0.0, hub_y, 0.0)
	var rim_off := clampf(WHEEL_DIAM * 0.04, 0.8, 4.0)

	# Outer cyan LED rim rings & inner magenta LED concentric ring + alternating radial spoke bars
	var seg := 48
	var inner_r := r * 0.42
	for k in seg:
		var a0 := TAU * float(k) / float(seg)
		var a1 := TAU * float(k + 1) / float(seg)
		var d0 := Vector3(0.0, cos(a0), sin(a0))
		var d1 := Vector3(0.0, cos(a1), sin(a1))
		for sx in [-1.0, 1.0]:
			var off := Vector3(sx * (rim_off + 0.16), 0.0, 0.0)
			lm.beam("CyanLamp", hub + d0 * r + off, hub + d1 * r + off, 0.16, 0.16)
			lm.beam("MagentaLamp", hub + d0 * inner_r + off, hub + d1 * inner_r + off, 0.14, 0.14)
		if k % 3 == 0:
			var col_key := "CyanLamp" if (k % 6 == 0) else "MagentaLamp"
			for sx in [-1.0, 1.0]:
				var off := Vector3(sx * (rim_off + 0.12), 0.0, 0.0)
				lm.beam(col_key, hub + d0 * 2.8 + off, hub + d0 * (r - 0.3) + off, 0.11, 0.11)

	# Top beacon finial cap on the apex gondola hanger reaching exact HEIGHT_M = 60.0 m
	lm.box("Steel", Vector3(0.0, HEIGHT_M - 0.08, 0.0), Vector3(0.95, 0.16, 0.55), Basis(), 0.0)

static func _build_bayside_pavilions(lm: LandmarkMesh) -> void:
	# Waterfront timber boardwalk promenade linking the wheel plaza and both market wings
	lm.box("Concrete", Vector3(-12.0, -0.10, -1.0), Vector3(36.0, 0.40, 96.0))
	lm.box("Teak", Vector3(-6.0, 0.14, -1.0), Vector3(22.0, 0.08, 92.0), Basis(), 0.0)

	# North & South two-storey open-air Bayside Marketplace pavilions (y = 0..10.5 m)
	_market_wing(lm, Vector3(-24.0, 0.0, -34.0), 22.0, 34.0)
	_market_wing(lm, Vector3(-24.0, 0.0, 32.0), 22.0, 34.0)

	# Signature white steel & aqua-glass BAYSIDE waterfront portal frame between the two wings (quarter.jpg)
	var px := -20.0
	for sz in [-6.5, 6.5]:
		lm.box("Stucco", Vector3(px, 4.2, -1.0 + sz), Vector3(1.6, 8.4, 1.6))
	lm.box("Steel", Vector3(px, 8.6, -1.0), Vector3(1.8, 0.9, 15.2))
	lm.gable("Capsule", Vector3(px, 9.05, -1.0), 2.8, 15.4, 1.35, Basis(), 0.4, "Steel")

	# Marina-edge Royal Palms
	for z in [-48.0, -16.0, 14.0, 46.0]:
		LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", Vector3(4.5, 0.1, z), 13.5, z * 0.2)

static func _market_wing(lm: LandmarkMesh, c: Vector3, w: float, l: float) -> void:
	# Two-level open-air retail pavilion with shaded colonnade, upper dining deck & terracotta roof (top = 10.5 m)
	lm.box("Stucco", c + Vector3(-1.8, 3.9, 0.0), Vector3(w - 3.6, 7.8, l - 2.0))
	lm.box("Capsule", c + Vector3(w * 0.5 - 3.55, 2.2, 0.0), Vector3(0.30, 3.4, l - 5.0), Basis(), 0.0)
	lm.box("Capsule", c + Vector3(w * 0.5 - 3.55, 5.9, 0.0), Vector3(0.30, 2.6, l - 5.0), Basis(), 0.0)
	# Upper veranda deck slab + perimeter colonnade posts along waterfront (+X)
	lm.box("Concrete", c + Vector3(0.0, 4.15, 0.0), Vector3(w, 0.36, l))
	lm.box("Stucco", c + Vector3(0.0, 7.85, 0.0), Vector3(w + 0.4, 0.40, l + 0.4))
	var posts := 7
	for i in posts:
		var pz := c.z - l * 0.45 + l * 0.90 * (float(i) / float(posts - 1))
		var px := c.x + w * 0.46
		lm.box("Stucco", Vector3(px, 3.9, pz), Vector3(0.58, 7.8, 0.58))
		if i < posts - 1:
			var pz_next := c.z - l * 0.45 + l * 0.90 * (float(i + 1) / float(posts - 1))
			lm.beam("Steel", Vector3(px, 5.15, pz), Vector3(px, 5.15, pz_next), 0.08, 0.08)

	# Pitched clay barrel-tile market roof reaching y = 10.5 m
	lm.gable("Terracotta", c + Vector3(0.0, 8.05, 0.0), w, l, 2.45, Basis(), 0.75, "Stucco")
	LandmarkMiKit.barrel_tile_strip(lm, "Terracotta",
		Vector2(c.x + w * 0.48, c.z - l * 0.48), Vector2(c.x + w * 0.48, c.z + l * 0.48),
		4.05, 4.85, 2.4, Vector2(1.0, 0.0))

static func _build_amphitheatre_and_laser_tower(lm: LandmarkMesh) -> void:
	# Crisp white tensile-inspired Bayfront Park amphitheatre stage shell to the south (+Z)
	var sc := Vector3(-6.0, 0.0, 64.0)
	lm.box("Concrete", sc + Vector3(0.0, 0.85, 0.0), Vector3(28.0, 1.7, 18.0))
	lm.box("Stucco", sc + Vector3(0.0, 5.2, 5.8), Vector3(18.0, 7.0, 4.5))

	# Sweeping hyperbolic-paraboloid white tensile stage canopy (y = 8.5..18.5 m)
	var rows: Array = []
	var nu := 9
	var nv := 7
	for j in nv:
		var v := float(j) / float(nv - 1)
		var z := lerpf(-9.5, 9.5, v)
		var span_x := lerpf(16.5, 10.5, v)
		var row := PackedVector3Array()
		for i in nu:
			var u := -1.0 + 2.0 * (float(i) / float(nu - 1))
			var arch := lerpf(18.5, 11.2, v) - (u * u) * lerpf(5.4, 2.2, v)
			row.append(sc + Vector3(u * span_x, arch, z))
		rows.append(row)
	lm.grid("Stucco", rows, Vector3.UP)

	# Inclined white steel perimeter masts & tie-back cables supporting the tensile canopy
	for sx in [-1.0, 1.0]:
		var m_foot := sc + Vector3(sx * 17.5, 0.2, -8.5)
		var m_top := sc + Vector3(sx * 16.5, 17.2, -9.5)
		var anchor := sc + Vector3(sx * 21.0, 0.2, -13.5)
		lm.beam("Steel", m_foot, m_top, 0.42, 0.42)
		lm.beam("Cable", m_top, anchor, 0.10, 0.10)
		lm.beam("Steel", sc + Vector3(sx * 11.0, 0.2, 8.8), sc + Vector3(sx * 10.5, 11.4, 9.5), 0.34, 0.34)

	# Slender 28.0 m white steel Bayfront laser/lighting lattice tower at (10.0, 0.0, 74.0)
	var tc := Vector3(10.0, 0.0, 74.0)
	lm.box("Concrete", tc + Vector3(0.0, 0.6, 0.0), Vector3(3.4, 1.2, 3.4))
	var tiers := 7
	for t in tiers:
		var y0 := 1.2 + float(t) * 3.6
		var y1 := y0 + 3.6
		var hw0 := lerpf(1.15, 0.52, float(t) / float(tiers))
		var hw1 := lerpf(1.15, 0.52, float(t + 1) / float(tiers))
		for side in 4:
			var a0 := float(side) * PI * 0.5 + PI * 0.25
			var a1 := float(side + 1) * PI * 0.5 + PI * 0.25
			var p0 := tc + Vector3(cos(a0) * hw0 * 1.414, y0, sin(a0) * hw0 * 1.414)
			var p1 := tc + Vector3(cos(a1) * hw0 * 1.414, y0, sin(a1) * hw0 * 1.414)
			var q0 := tc + Vector3(cos(a0) * hw1 * 1.414, y1, sin(a0) * hw1 * 1.414)
			var q1 := tc + Vector3(cos(a1) * hw1 * 1.414, y1, sin(a1) * hw1 * 1.414)
			lm.beam("Steel", p0, q0, 0.16, 0.16)
			lm.lattice_panel("Steel", p0, p1, q0, q1, 0.09, 1, true)
	# Lighting gallery head & beacon mast reaching 28.0 m
	lm.box("Steel", tc + Vector3(0.0, 26.65, 0.0), Vector3(1.6, 0.50, 1.6))
	lm.box("CyanLamp", tc + Vector3(0.0, 27.15, 0.0), Vector3(1.2, 0.45, 1.2))
	lm.beam("Steel", tc + Vector3(0.0, 27.35, 0.0), tc + Vector3(0.0, 28.0, 0.0), 0.12, 0.12, Vector3.RIGHT, true)
