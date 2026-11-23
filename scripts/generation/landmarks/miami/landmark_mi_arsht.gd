class_name LandmarkMiArsht
extends RefCounted

## Adrienne Arsht Center for the Performing Arts — Downtown Miami MI-2A.5
## Site: 1300 Biscayne Blvd, OSM way 314061996 + way 199543159 (25.787514, -80.189653, yaw_deg -3.5).
## Architect: César Pelli / Pelli Clarke Pelli (2006) + historic Sears Tower (1929).
## Two-block campus straddling Biscayne Boulevard (road stays open at x = 42..64 m via model_rects_m):
##   - West Block (x = -58..+32 m, z = -56..+46 m): Sanford and Dolores Ziff Ballet Opera House
##     with 48.0 m tall pale grey-buff granite fly-tower, stepped angular acoustic roof ridges
##     (front.jpg), sweeping sloped blue-green glass lobby curtain, and preserved 1929 buff-cream
##     Art Deco Sears Tower (30.0 m octagonal stepped Deco turret) at the SW corner.
##   - East Block (x = +72..+138 m, z = -52..+26 m): John S. and James L. Knight Concert Hall
##     (38.0 m faceted pale stone & curved sloped glass atrium with illuminated oval balconies
##     and brushed stainless-steel entry canopy, night.jpg).
##   - Carnival Pedestrian Bridge (x = +30..+74 m, y = 9.5..13.5 m): slender stainless-steel &
##     glass skybridge spanning high above the open Biscayne Boulevard carriageway.

const HEIGHT_M := 48.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#ACA8A2", 3.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#DFD9CC", 3.5))
	lm.use("DecoCream", LandmarkMaterials.pbr("render", "#EFE6D0", 3.2))
	lm.use("Glass", LandmarkMaterials.glass("#3A7482"))
	lm.use("Steel", LandmarkMaterials.paint("#D8DDE2", 0.32, 0.72))
	lm.use("Roof", LandmarkMaterials.pbr("roof_concrete", "#C2BFB8", 5.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFCA7A", 0.65))

	_build_ziff_opera_house(lm)
	_build_sears_deco_tower(lm)
	_build_knight_concert_hall(lm)
	_build_carnival_bridge(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.66)
	var cool := Color(0.80, 0.90, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(38.0, 2.0, 14.0), Vector3(-6.0, 30.0, 2.0), 54.0, 1.20, 72.0, cool],
		[Vector3(-12.0, 2.0, 52.0), Vector3(-12.0, 28.0, 10.0), 54.0, 1.10, 68.0, cool],
		[Vector3(-56.0, 2.0, 48.0), Vector3(-45.0, 18.0, 34.0), 46.0, 1.15, 44.0, warm],
		[Vector3(66.0, 2.0, -10.0), Vector3(96.0, 24.0, -12.0), 54.0, 1.20, 65.0, warm],
		[Vector3(105.0, 2.0, 34.0), Vector3(105.0, 22.0, -4.0), 52.0, 1.05, 58.0, cool],
	])

static func _build_ziff_opera_house(lm: LandmarkMesh) -> void:
	# Stepped travertine plaza & lower lobby plinth (x = -56..+32 m, z = -54..+44 m, y = -0.35..8.5 m)
	lm.poly_prism("Travertine", SkyKit.rect(88.0, 98.0, -12.0, -5.0), -0.35, 1.2)
	lm.box("Granite", Vector3(-11.0, 5.2, -5.0), Vector3(82.0, 8.0, 90.0))
	# Horizontal lobby clerestory ribbon windows around base (seen in front.jpg)
	for wy in [3.2, 6.8]:
		lm.box("Glass", Vector3(-11.0, wy, 40.08), Vector3(72.0, 1.35, 0.24), Basis(), 0.0)
		lm.box("Glass", Vector3(30.08, wy, -5.0), Vector3(0.24, 1.35, 80.0), Basis(), 0.0)

	# Stepped angular auditorium tiers rising toward the fly-tower (matching Pelli's folded granite massing in front.jpg)
	lm.box("Granite", Vector3(-10.0, 15.0, -6.0), Vector3(68.0, 11.6, 74.0))
	lm.gable("Granite", Vector3(-10.0, 20.8, -6.0), 66.0, 72.0, 6.4, Basis(), 0.2, "Granite")
	lm.box("Granite", Vector3(-12.0, 25.5, -8.0), Vector3(52.0, 9.5, 56.0))
	lm.gable("Granite", Vector3(-12.0, 30.2, -8.0), 50.0, 54.0, 6.8, Basis(), 0.2, "Granite")

	# Tall 48.0 m Ziff Ballet Opera House stage fly-tower with sloped ridge crest (exact top y = 48.0 m)
	lm.box("Granite", Vector3(-16.0, 38.0, -12.0), Vector3(34.0, 16.0, 36.0))
	var fly_poly := SkyKit.rect(34.0, 36.0, -16.0, -12.0)
	lm.poly_prism("Granite", fly_poly, 44.0, 46.2)
	# Asymmetric Pelli sloped fly-tower crown peaking at exact y = 48.0 m
	var p0 := Vector3(-33.0, 46.2, -30.0)
	var p1 := Vector3(1.0, 46.2, -30.0)
	var p2 := Vector3(1.0, 46.2, 6.0)
	var p3 := Vector3(-33.0, 46.2, 6.0)
	var r0 := Vector3(-20.0, HEIGHT_M, -30.0)
	var r1 := Vector3(-20.0, HEIGHT_M, 6.0)
	lm.quad("Roof", p0, p3, r1, r0)
	lm.quad("Roof", p2, p1, r0, r1)
	lm.tri("Granite", p0, r0, p1, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
		Vector2(0, 0), Vector2(13, 1.8), Vector2(34, 0))
	lm.tri("Granite", p3, p2, r1, Vector3.BACK, Vector3.BACK, Vector3.BACK,
		Vector2(0, 0), Vector2(34, 0), Vector2(13, 1.8))

	# Sweeping sloped blue-green glass lobby curtain pylon on SE/East front (prominent in front.jpg)
	_sloped_glass_prow(lm, Vector3(18.0, 1.2, 22.0), 18.0, 20.0, 23.5, Vector3(1.0, 0.0, 0.35).normalized())
	# East Biscayne Blvd curved glass grand lobby facing Parker & Vann Thomson Plaza (x = +22..+32 m)
	var east_lobe := TowerSpec.plan("ellipse", 18.0, 56.0, 20.0, 25.0, -6.0)
	lm.poly_prism("Glass", east_lobe, 1.2, 21.5)
	lm.poly_prism("Steel", east_lobe, 21.5, 22.4)
	lm.box("WarmLamp", Vector3(23.5, 10.5, -6.0), Vector3(6.0, 15.0, 38.0))
	# Brushed stainless-steel entrance marquee along Biscayne Blvd
	lm.box("Steel", Vector3(31.5, 5.8, -6.0), Vector3(5.2, 0.85, 34.0))

static func _sloped_glass_prow(lm: LandmarkMesh, base: Vector3, w0: float, d0: float, h: float, dir: Vector3) -> void:
	var tang := Vector3(-dir.z, 0.0, dir.x)
	var steps := 6
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var y0 := base.y + h * t0
		var y1 := base.y + h * t1
		var sc := lerpf(1.0, 0.62, (t0 + t1) * 0.5)
		var shift := dir * (-3.8 * (t0 + t1) * 0.5)
		var c := base + shift + Vector3(0.0, (y0 + y1) * 0.5 - base.y, 0.0)
		var b := Basis(tang, Vector3.UP, dir)
		lm.box("Glass", c, Vector3(w0 * sc, y1 - y0 + 0.05, d0 * sc), b, 0.0)
		lm.box("Steel", c + Vector3(0.0, (y1 - y0) * 0.5, 0.0),
			Vector3(w0 * sc + 0.25, 0.22, d0 * sc + 0.25), b, 0.0)

static func _build_sears_deco_tower(lm: LandmarkMesh) -> void:
	# Preserved 1929 Art Deco Sears, Roebuck & Co. Tower at SW corner (x = -45.0, z = +33.0, top = 30.0 m)
	# Visible at bottom-left of front.jpg: buff-cream stucco octagonal stepped turret with vertical Deco ribs!
	var sc := Vector2(-45.0, 33.0)
	lm.box("DecoCream", Vector3(sc.x, 7.0, sc.y), Vector3(14.5, 14.0, 14.5))
	var oct1 := TowerSpec.plan("chamfer", 12.2, 12.2, 3.4, sc.x, sc.y)
	lm.poly_prism("DecoCream", oct1, 14.0, 26.8)
	var oct2 := TowerSpec.plan("chamfer", 9.6, 9.6, 2.7, sc.x, sc.y)
	lm.poly_prism("DecoCream", oct2, 26.8, 29.2)
	var oct3 := TowerSpec.plan("chamfer", 7.2, 7.2, 2.0, sc.x, sc.y)
	lm.poly_prism("Travertine", oct3, 29.2, 30.0)

	# Vertical Deco corner & face pilasters + tall recessed dark casement windows
	for i in 4:
		var ang := float(i) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var b := Basis(t3, Vector3.UP, n3)
		for wy in [10.5, 17.5, 23.0]:
			lm.box("Glass", Vector3(sc.x, wy, sc.y) + n3 * 6.12, Vector3(1.65, 2.8, 0.22), b, 0.0)
		for sg in [-2.2, 2.2]:
			lm.box("Travertine", Vector3(sc.x, 20.5, sc.y) + n3 * 6.15 + t3 * sg,
				Vector3(0.55, 13.5, 0.28), b, 0.0)

static func _build_knight_concert_hall(lm: LandmarkMesh) -> void:
	# East Block across Biscayne Blvd (x = 72..136 m, z = -50..+24 m, top = 38.0 m)
	lm.poly_prism("Travertine", SkyKit.rect(66.0, 76.0, 105.0, -13.0), -0.35, 1.2)
	lm.box("Travertine", Vector3(107.0, 6.2, -13.0), Vector3(58.0, 10.0, 68.0))

	# Faceted stone acoustic concert hall shell rising in stepped Pelli planes to y = 38.0 m
	lm.box("Granite", Vector3(110.0, 18.5, -13.0), Vector3(48.0, 15.0, 56.0))
	lm.box("Granite", Vector3(113.0, 30.5, -13.0), Vector3(36.0, 11.0, 42.0))
	lm.gable("Granite", Vector3(113.0, 35.0, -13.0), 35.0, 41.0, 3.0, Basis(), 0.2, "Granite")

	# Curved sloped glass west lobby facing Biscayne Blvd + illuminated projecting oval balconies (night.jpg!)
	_sloped_glass_prow(lm, Vector3(82.0, 1.2, -13.0), 36.0, 16.0, 29.5, Vector3(-1.0, 0.0, 0.0))
	lm.box("WarmLamp", Vector3(86.0, 13.5, -13.0), Vector3(6.5, 20.0, 24.0))
	for by in [12.5, 20.5]:
		var bal := TowerSpec.plan("ellipse", 7.5, 11.0, 16.0, 74.2, -13.0)
		lm.poly_prism("Steel", bal, by, by + 0.85)
		lm.poly_prism("WarmLamp", TowerSpec.plan("ellipse", 6.8, 10.2, 16.0, 74.2, -13.0), by - 0.18, by)

	# Curved brushed stainless-steel KNIGHT CONCERT HALL marquee canopy on round stone columns (night.jpg)
	var marq := TowerSpec.plan("ellipse", 12.0, 26.0, 20.0, 74.5, -13.0)
	lm.poly_prism("Steel", marq, 5.4, 6.5)
	lm.poly_prism("WarmLamp", TowerSpec.plan("ellipse", 10.6, 24.2, 20.0, 74.5, -13.0), 5.22, 5.4)
	for sz in [-8.5, -3.2, 3.2, 8.5]:
		lm.frustum("Travertine", Vector3(71.5, 1.2, -13.0 + sz), 0.52, 0.48, 4.2, 12)

static func _build_carnival_bridge(lm: LandmarkMesh) -> void:
	# Slender stainless-steel & glass pedestrian bridge over Biscayne Blvd (x = 29.0..75.0 m, y = 9.5..13.5 m)
	# Zero piers between x = 33 and x = 71 m so the 6-lane boulevard below stays completely unobstructed!
	var bz := -11.5
	var x0 := 29.0
	var x1 := 75.0
	var span := x1 - x0
	var xm := (x0 + x1) * 0.5
	# Stainless-steel deck soffit (bottom at y = 9.5 m) & glazed walkway enclosure (y = 10.1..13.0 m)
	lm.box("Steel", Vector3(xm, 9.80, bz), Vector3(span, 0.60, 5.4))
	lm.box("Glass", Vector3(xm, 11.55, bz), Vector3(span - 1.0, 2.90, 4.8))
	# Gently arched stainless-steel roof rib & diagonal structural web mullions reaching y = 13.5 m
	var segs := 10
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var xa := lerpf(x0, x1, t0)
		var xb := lerpf(x0, x1, t1)
		var ya := 13.05 + 0.45 * sin(t0 * PI)
		var yb := 13.05 + 0.45 * sin(t1 * PI)
		lm.beam("Steel", Vector3(xa, ya, bz), Vector3(xb, yb, bz), 5.5, 0.28, Vector3.FORWARD)
		for sz in [-2.55, 2.55]:
			lm.beam("Steel", Vector3(xa, 9.8, bz + sz), Vector3(xa, ya, bz + sz), 0.20, 0.20)
			lm.beam("Steel", Vector3(xa, 9.8, bz + sz), Vector3(xb, yb, bz + sz), 0.14, 0.14)
	# Bridge abutment columns safely inside West & East plazas (outside Biscayne Blvd!)
	for ax in [32.0, 71.5]:
		for sz in [-2.1, 2.1]:
			lm.frustum("Steel", Vector3(ax, 1.2, bz + sz), 0.45, 0.40, 8.4, 12)
