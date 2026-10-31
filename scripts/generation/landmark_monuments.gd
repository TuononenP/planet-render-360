class_name LandmarkMonuments
extends RefCounted

## Giza pyramid field and the Statue of Liberty, in true metres.

# --- Giza ---

## The Giza plateau around Khufu (registry point): Khufu (230.3 m base,
## 138.5 m now), Khafre (215.3 m, 136.4 m, casing cap kept) and
## Menkaure (103.4 m, 61 m) at their surveyed offsets, sides on the
## compass; Khufu's three queens' pyramids to the east and the Sphinx
## facing east. Stripped faces read as ~40 stepped courses.
static func giza(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#C2A574", 6.0))
	lm.use("Casing", LandmarkMaterials.pbr("limestone", "#DCCDA8", 5.0))
	lm.use("Sphinx", LandmarkMaterials.pbr("limestone", "#B8976A", 3.0))
	_pyramid(lm, Vector3.ZERO, 115.15, 138.5, 146.6, 40, 0.0)
	_pyramid(lm, Vector3(-328.0, 0, 343.0), 107.65, 136.4, 143.5, 38, 0.78)
	_pyramid(lm, Vector3(-588.0, 0, 741.0), 51.7, 61.0, 65.5, 18, 0.0)
	for k in 3:
		_pyramid(lm, Vector3(150.0, 0, -40.0 + float(k) * 55.0), 23.0, 29.0, 30.0, 8, 0.0)
	_sphinx(lm, Vector3(328.0, 0, 431.0))
	lm.commit(model)

## Square pyramid of half-base `hb`, built to `h` (true apex `apex`),
## `steps` stripped courses; `cap` fraction of height up which the
## smooth casing survives (Khafre).
static func _pyramid(lm: LandmarkMesh, c: Vector3, hb: float, h: float, apex: float,
		steps: int, cap: float) -> void:
	var prof := PackedVector2Array()
	var k := sqrt(2.0)
	var cap_y := h * cap if cap > 0.0 else h
	for s in steps:
		var y0 := cap_y * float(s) / float(steps)
		var y1 := cap_y * float(s + 1) / float(steps)
		var r0 := hb * (1.0 - y0 / apex) * k
		var r1 := hb * (1.0 - y1 / apex) * k
		prof.append(Vector2(r0, y0))
		prof.append(Vector2(r0 - 0.35 * k, y1))
		prof.append(Vector2(r1, y1))
	lm.lathe("Limestone", c, prof, 4, 1.0, 1.0, PI * 0.25, false, cap > 0.0)
	var top_r := hb * (1.0 - h / apex) * k
	if cap > 0.0:
		var r_cap := hb * (1.0 - cap_y / apex) * k
		lm.lathe("Casing", c + Vector3(0, cap_y, 0), PackedVector2Array([Vector2(r_cap, 0),
			Vector2(top_r, h - cap_y)]), 4, 1.0, 1.0, PI * 0.25, false)
	else:
		lm.lathe("Limestone", c + Vector3(0, cap_y, 0), PackedVector2Array([Vector2(top_r, 0),
			Vector2(0.0, 0.0)]), 4, 1.0, 1.0, PI * 0.25, false)

## Great Sphinx: 73 m long, 20 m high, facing east (+X).
static func _sphinx(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Sphinx", c + Vector3(-8.0, 5.0, 0), Vector3(48.0, 10.0, 17.0))
	lm.lathe("Sphinx", c + Vector3(-30.0, 0, 0), PackedVector2Array([Vector2(8.0, 0),
		Vector2(8.0, 9.0), Vector2(5.0, 13.0)]), 10, 1.0, 1.0)
	for s in [-1.0, 1.0]:
		lm.box("Sphinx", c + Vector3(24.0, 2.0, s * 5.0), Vector3(20.0, 4.0, 4.5))
	lm.box("Sphinx", c + Vector3(15.0, 9.0, 0), Vector3(10.0, 12.0, 12.0))
	lm.box("Sphinx", c + Vector3(17.5, 15.5, 0), Vector3(7.0, 6.0, 5.0))
	lm.spire("Sphinx", c + Vector3(15.0, 12.0, 0), 6.5, 8.0, 2.0)
	# Rock-cut enclosure around the body.
	lm.box("Limestone", c + Vector3(-2.0, 4.0, 14.0), Vector3(80.0, 8.0, 3.0))
	lm.box("Limestone", c + Vector3(-2.0, 4.0, -14.0), Vector3(80.0, 8.0, 3.0))

# --- Statue of Liberty ---

## Liberty Island: Fort Wood's eleven-point granite star, the stepped
## concrete foundation and the granite pedestal (to 47 m) with its
## loggia, then the 46 m copper statue (verdigris) — draped robe, head
## with the seven-ray crown, raised right arm and gilded torch flame
## at 93 m, tablet in the left arm. She faces south-east.
static func liberty(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("limestone", "#B4A99A", 3.0))
	lm.use("Fort", LandmarkMaterials.pbr("concrete", "#8E8578", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B2A6", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6AA391", 2.0, 0.7, 0.15))
	lm.use("Flame", LandmarkMaterials.gold())
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	_fort(lm)
	_pedestal(lm)
	_statue(lm)
	lm.commit(model)
	model.rotation.y = deg_to_rad(45.0)

static func _fort(lm: LandmarkMesh) -> void:
	var star := PackedVector2Array()
	for k in 22:
		var a := TAU * float(k) / 22.0
		var r := 52.0 if k % 2 == 0 else 34.0
		star.append(Vector2(cos(a) * r, sin(a) * r))
	lm.poly_prism("Fort", star, 0.0, 7.5)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(26.0, 7.5),
		Vector2(26.0, 9.0), Vector2(19.0, 9.0), Vector2(19.0, 14.0), Vector2(14.5, 14.0),
		Vector2(14.5, 20.0)]), 4, 1.0, 1.0, PI * 0.25, false)

static func _pedestal(lm: LandmarkMesh) -> void:
	var k := sqrt(2.0)
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([Vector2(14.0 * k, 20.0),
		Vector2(13.0 * k, 22.0), Vector2(11.5 * k, 23.5), Vector2(10.4 * k, 33.0),
		Vector2(11.2 * k, 34.0), Vector2(9.6 * k, 35.0), Vector2(9.6 * k, 42.5),
		Vector2(10.4 * k, 43.5), Vector2(9.0 * k, 44.5), Vector2(8.0 * k, 47.0)]),
		4, 1.0, 1.0, PI * 0.25, false)
	# Loggia: three openings per side between pilasters, and the
	# shield-studded frieze course above.
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		for j in 3:
			var x := -5.2 + float(j) * 5.2
			lm.box("Windows", rot * Vector3(x, 38.6, 9.62), Vector3(2.2, 5.0, 0.1), rot)
		for j in 4:
			var x := -7.8 + float(j) * 5.2
			lm.box("Granite", rot * Vector3(x, 38.8, 9.75), Vector3(1.0, 7.2, 0.5), rot)
		lm.box("Granite", rot * Vector3(0, 27.0, 10.75), Vector3(7.0, 6.0, 0.5), rot)

## The copper figure: robe as a fluted surface of revolution, torso,
## head, crown rays, arms, torch and tablet.
static func _statue(lm: LandmarkMesh) -> void:
	var b := 47.0
	var prof := [[4.6, 0.0], [4.9, 1.5], [4.4, 8.0], [3.8, 16.0], [3.4, 21.0],
		[3.8, 25.5], [4.1, 28.0], [3.0, 30.0], [1.3, 30.8], [1.2, 31.6]]
	var rows: Array = []
	for p in prof:
		var row := PackedVector3Array()
		for i in 25:
			var a := TAU * float(i) / 24.0
			var y: float = float(p[1])
			var fold := 1.0 + (0.07 if y < 24.0 else 0.02) * sin(a * 9.0 + y * 0.35)
			var r: float = float(p[0]) * fold
			row.append(Vector3(cos(a) * r * 1.05, b + y, sin(a) * r * 0.82))
		rows.append(row)
	lm.grid("Copper", rows, Vector3(0, b + 15.0, 0), true)
	# Head with crown band and the seven rays.
	var head := Vector3(0, b + 34.0, 0.3)
	lm.lathe("Copper", head - Vector3(0, 2.6, 0), PackedVector2Array([Vector2(1.1, 0),
		Vector2(1.8, 1.4), Vector2(1.9, 3.0), Vector2(1.5, 4.4), Vector2(0.6, 5.3),
		Vector2(0.0, 5.5)]), 12)
	lm.frustum("Copper", head + Vector3(0, 1.2, 0), 2.2, 2.0, 1.1, 12)
	for k in 7:
		var a := deg_to_rad(-75.0 + 25.0 * float(k))
		var d := Vector3(sin(a), 0.28, cos(a)).normalized()
		lm.beam("Copper", head + Vector3(0, 1.8, 0) + d * 1.9, head + Vector3(0, 1.8, 0) + d * 4.6,
			0.45, 0.2)
	# Raised right arm (+X side) to the torch.
	var shoulder := Vector3(3.1, b + 29.2, 0.0)
	var elbow := Vector3(3.6, b + 35.5, -0.4)
	var hand := Vector3(3.4, b + 40.4, -0.2)
	lm.beam("Copper", shoulder, elbow, 1.9, 1.7)
	lm.beam("Copper", elbow, hand, 1.5, 1.4)
	lm.frustum("Copper", hand, 0.6, 0.9, 2.2, 8)
	lm.frustum("Flame", hand + Vector3(0, 2.2, 0), 1.6, 1.8, 0.9, 12)
	lm.lathe("Flame", hand + Vector3(0, 3.1, 0), PackedVector2Array([Vector2(1.3, 0),
		Vector2(1.2, 1.2), Vector2(0.6, 2.4), Vector2(0.0, 3.3)]), 10)
	# Left arm and the tablet (JULY IV MDCCLXXVI) held at the side.
	var lsh := Vector3(-3.2, b + 28.6, 0.2)
	var lel := Vector3(-3.9, b + 23.5, 0.9)
	lm.beam("Copper", lsh, lel, 1.6, 1.5)
	lm.beam("Copper", lel, Vector3(-2.6, b + 21.5, 2.6), 1.3, 1.2)
	lm.box("Copper", Vector3(-3.6, b + 23.0, 2.4), Vector3(0.6, 7.2, 4.1),
		Basis(Vector3.BACK, 0.18) * Basis(Vector3.UP, 0.3))

# --- Memorial column and obelisk ---

## Free-standing memorial column (Nelson's Column, Vendome, the Monument):
## stepped granite plinth, tapering Portland-stone shaft, bronze capital
## and a figure on top. Proportions follow Nelson's Column (51.6 m:
## plinth 19 %, shaft 57 %, capital 7 %, figure 10 %). Windowless: OSM
## maps these as `building=yes`, which would otherwise get floors of
## windows like a block of flats.
static func column(lm: LandmarkMesh, h: float) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8A84", 3.0))
	lm.use("Shaft", LandmarkMaterials.pbr("limestone", "#BDB6A6", 4.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E6B52", 0.55, 0.5))
	var plinth := h * 0.19
	var pw := h * 0.1
	var step := h * 0.03
	lm.box("Granite", Vector3(0, step * 0.5, 0), Vector3(pw * 2.3, step, pw * 2.3))
	lm.box("Granite", Vector3(0, step + (plinth - step * 1.6) * 0.5, 0),
		Vector3(pw * 2.0, plinth - step * 1.6, pw * 2.0))
	lm.box("Granite", Vector3(0, plinth - step * 0.3, 0), Vector3(pw * 2.15, step * 0.6, pw * 2.15))
	var r0 := h * 0.033
	var r1 := r0 * 0.85
	var shaft_h := h * 0.57
	lm.frustum("Shaft", Vector3(0, plinth, 0), r0, r1, shaft_h, 28)
	var cap_y := plinth + shaft_h
	var cap_h := h * 0.07
	lm.lathe("Bronze", Vector3(0, cap_y, 0), PackedVector2Array([Vector2(r1, 0),
		Vector2(r1 * 1.2, cap_h * 0.4), Vector2(r1 * 1.5, cap_h * 0.8),
		Vector2(r1 * 1.6, cap_h)]), 24)
	lm.box("Shaft", Vector3(0, cap_y + cap_h + h * 0.01, 0), Vector3(r1 * 3.6, h * 0.02, r1 * 3.6))
	var fig_y := cap_y + cap_h + h * 0.02
	lm.frustum("Granite", Vector3(0, fig_y, 0), r1 * 0.9, r1 * 0.7, h * 0.03, 12)
	lm.lathe("Bronze", Vector3(0, fig_y + h * 0.03, 0), PackedVector2Array([Vector2(r1 * 0.5, 0),
		Vector2(r1 * 0.42, h * 0.04), Vector2(r1 * 0.5, h * 0.06), Vector2(r1 * 0.3, h * 0.075),
		Vector2(r1 * 0.12, h * 0.085)]), 10)

## Obelisk: square tapering shaft on a stepped base, pyramidion on top.
static func obelisk(lm: LandmarkMesh, h: float) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8A84", 3.0))
	lm.use("Shaft", LandmarkMaterials.pbr("limestone", "#C4BBA8", 4.0))
	var hb := h * 0.075
	lm.box("Granite", Vector3(0, h * 0.015, 0), Vector3(hb * 2.4, h * 0.03, hb * 2.4))
	lm.box("Granite", Vector3(0, h * 0.045, 0), Vector3(hb * 2.0, h * 0.03, hb * 2.0))
	lm.spire("Shaft", Vector3(0, h * 0.06, 0), h * 0.05, h * 0.84, h * 0.034)
	lm.spire("Shaft", Vector3(0, h * 0.9, 0), h * 0.034, h * 0.1, 0.0)
