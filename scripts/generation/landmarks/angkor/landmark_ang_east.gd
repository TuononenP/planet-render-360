class_name LandmarkAngEast
extends RefCounted

## Preah Khan of Angkor in true metres, and the enclosure parts the other
## east-Angkor temples share (capped galleries, three-passage gopuras,
## silk-cotton trees). Built facing +X (east); -Z is north.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Preah Khan (17 m): Jayavarman VII's monastery-city temple, here its
## inner three enclosures on the main east-west axis: the cruciform first
## enclosure round the lotus-bud central sanctuary (62 x 55 m), the second
## (85 x 76 m) and the laterite third (200 x 175 m), each with a gopura on
## all four sides and corner towers; the great east gopura of three towers
## and flanking pavilions, the Hall of Dancers, the two-storey building on
## round columns, two libraries, the Hindu satellite shrines north, south
## and west, the four corner ponds, the cruciform terrace and naga
## causeway toward the Jayatataka baray, and silk-cotton trees on the
## walls. Built facing +X (east).
static func preah_khan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#85796A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#968A74", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7A4F37", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	lm.use("Root", LandmarkMaterials.pbr("rock", "#4D4438", 3.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))
	var eb := Basis(Vector3.UP, PI * 0.5)
	var laterite: Array[String] = ["Laterite", "Stone", "Dark"]
	var sand: Array[String] = ["Stone", "Trim", "Dark"]
	# The three enclosure walls.
	gallery(lm, sand, Vector3.ZERO, 31.0, 27.5, 4.4, 1.3, 4.5, 4.5, true, true)
	gallery(lm, sand, Vector3.ZERO, 42.5, 38.0, 4.6, 1.5, 6.5, 6.5, true, true)
	gallery(lm, laterite, Vector3.ZERO, 100.0, 87.5, 4.2, 1.8, 11.0, 11.0, true, false)
	# A gopura on every side of each: dist is the half-size across the axis.
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var odd := i % 2 == 1
		gopura(lm, "Stone", "Trim", "Dark", "Stone", b * Vector3(0, 0, 31.0 if odd else 27.5), b,
			10.0, 5.5, 4.0, 5.5)
		gopura(lm, "Stone", "Trim", "Dark", "Stone", b * Vector3(0, 0, 42.5 if odd else 38.0), b,
			14.0, 7.0, 4.5, 6.5)
		if i == 1:
			gopura(lm, "Laterite", "Stone", "Dark", "Stone", Vector3(100.0, 0, 0), b, 30.0, 14.0, 6.5,
				8.0, true)
		else:
			gopura(lm, "Laterite", "Stone", "Dark", "Stone", b * Vector3(0, 0, 100.0 if odd else 87.5),
				b, 22.0, 9.0, 5.5, 7.0)
	# Cruciform gallery of the first enclosure: two walls down each arm.
	for s in [-1.0, 1.0]:
		for e in [-1.0, 1.0]:
			run(lm, sand, Vector3(e * 8.0, 0, s * 3.0), Vector3(e * 30.0, 0, s * 3.0), 3.8, 1.1, true, true)
			run(lm, sand, Vector3(s * 3.0, 0, e * 8.0), Vector3(s * 3.0, 0, e * 26.5), 3.8, 1.1, true, true)
	# Corner towers of the three enclosures.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			tower(lm, "Stone", "Trim", "Dark", Vector3(sx * 31.0, 4.7, sz * 27.5), 1.6, 6.0, 2, 0.3)
			tower(lm, "Stone", "Trim", "Dark", Vector3(sx * 42.5, 4.9, sz * 38.0), 1.9, 7.0, 2, 0.3)
			tower(lm, "Laterite", "Stone", "Dark", Vector3(sx * 100.0, 4.5, sz * 87.5), 2.4, 8.0,
				2, 0.3)
	# Central sanctuary on its platform, with the corner shrines round it.
	lm.box("Trim", Vector3(0, 0.3, 0), Vector3(15.0, 0.6, 15.0))
	lm.box("Stone", Vector3(0, 1.0, 0), Vector3(13.6, 2.0, 13.6))
	lm.box("Trim", Vector3(0, 1.9, 0), Vector3(14.0, 0.2, 14.0), Basis(), 0.0)
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, 2.0, 0), 3.3, 15.0, 3, 0.28)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			tower(lm, "Stone", "Trim", "Dark", Vector3(sx * 5.2, 2.0, sz * 5.2), 1.3, 6.5, 2, 0.3)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Stone", b * Vector3(0, 2.0 + 1.6, 4.6), Vector3(3.4, 3.2, 3.0), b)
	# Hall of Dancers: four-court gallery on a platform west of the east
	# gopura, a stair at each end; the two-storey building north of it.
	_hall_of_dancers(lm, sand, Vector3(76.0, 0, 0))
	_two_storey(lm, Vector3(72.0, 0, -36.0))
	# Libraries in the courtyard east of the second enclosure.
	for s in [-1.0, 1.0]:
		U.hall(lm, "Stone", "Trim", "Stone", "Trim", Vector3(57.0, 0, s * 16.0), eb, 4.2, 8.0, 0.8,
			3.2, 1.8, 2, 0)
	# Hindu satellite shrines: north, south and west.
	_satellite(lm, Vector3(0, 0, -62.0))
	_satellite(lm, Vector3(0, 0, 62.0))
	_satellite(lm, Vector3(-68.0, 0, 0))
	# Dry ponds in the four corners of the third enclosure.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pond(lm, Vector3(sx * 76.0, 0, sz * 66.0), 26.0, 18.0)
	# Cruciform terrace and the naga causeway toward the baray.
	lm.box("Laterite", Vector3(117.0, 0.45, 0), Vector3(22.0, 0.9, 10.0))
	lm.box("Laterite", Vector3(117.0, 0.45, 0), Vector3(10.0, 0.9, 26.0))
	lm.box("Trim", Vector3(117.0, 0.95, 0), Vector3(22.4, 0.2, 10.4), Basis(), 0.0)
	lm.box("Trim", Vector3(117.0, 0.95, 0), Vector3(10.4, 0.2, 26.4), Basis(), 0.0)
	lm.box("Laterite", Vector3(145.0, 0.45, 0), Vector3(34.0, 0.9, 8.0))
	for s in [-1.0, 1.0]:
		U.naga_rail(lm, "Stone", Vector3(128.0, 0.9, s * 3.6), eb, 32.0, 0.0, 0.0, 0.7, 5)
	# Silk-cotton trees clasping the walls and gopuras.
	tree(lm, Vector3(104.0, 0, 20.0), 2.2, 14.0)
	tree(lm, Vector3(-96.0, 0, 18.0), 2.4, 15.0)
	tree(lm, Vector3(40.0, 0, 82.0), 2.0, 12.0)
	tree(lm, Vector3(-30.0, 0, -86.0), 2.3, 13.0)
	tree(lm, Vector3(-62.0, 0, 44.0), 1.9, 11.0)
	lm.commit(model)

## One capped gallery wall a..b (ground points): `h` tall, `t` thick, a cap
## slab, an optional corbelled vault crown, and (when `windows`) a row of
## dark balustraded window openings through it. `k` is [wall, cap, dark].
static func run(lm: LandmarkMesh, k: Array[String], a: Vector3, b: Vector3, h: float, t: float,
		windows: bool, crown: bool) -> void:
	var d := b - a
	var ln := d.length()
	if ln < 0.5:
		return
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	var m := (a + b) * 0.5
	lm.box(k[0], m + Vector3(0, h * 0.5, 0), Vector3(t, h, ln), basis)
	lm.box(k[1], m + Vector3(0, h + 0.15, 0), Vector3(t + 0.5, 0.3, ln + 0.3), basis)
	if crown:
		lm.box(k[0], m + Vector3(0, h + 0.75, 0), Vector3(t * 0.6, 0.9, maxf(ln - 0.4, 0.2)), basis)
	if windows and ln > 4.0:
		var n := int(ln / 3.4)
		for i in n:
			var z := -ln * 0.5 + ln * (float(i) + 0.5) / float(n)
			lm.box(k[2], m + basis * Vector3(0, h * 0.55, z), Vector3(t + 0.06, h * 0.3, 0.9), basis, 0.0)

## Rectangular gallery ring of half-sizes hx, hz about the ground point c
## (its y is the wall foot), with a `gx`-half-wide opening in the middle of
## the east and west sides and a `gz` one in the north and south sides (0
## or less leaves that side shut).
static func gallery(lm: LandmarkMesh, k: Array[String], c: Vector3, hx: float, hz: float, h: float,
		t: float, gx: float, gz: float, windows: bool, crown: bool) -> void:
	for s in [-1.0, 1.0]:
		_side(lm, k, c + Vector3(-hx, 0, s * hz), c + Vector3(hx, 0, s * hz), gz, h, t, windows, crown)
		_side(lm, k, c + Vector3(s * hx, 0, -hz), c + Vector3(s * hx, 0, hz), gx, h, t, windows, crown)

static func _side(lm: LandmarkMesh, k: Array[String], a: Vector3, b: Vector3, gap: float, h: float,
		t: float, windows: bool, crown: bool) -> void:
	if gap <= 0.0:
		run(lm, k, a, b, h, t, windows, crown)
		return
	var m := (a + b) * 0.5
	var dir := (b - a).normalized()
	run(lm, k, a, m - dir * gap, h, t, windows, crown)
	run(lm, k, m + dir * gap, b, h, t, windows, crown)

## Three-passage gopura on a wall line: `base` is the centre on the wall,
## the basis +Z points out of the temple. A tall central block with false
## doors both ways, lower gabled pavilions to each side, and a lotus-bud
## tower of `tower_h` on the block (three towers when `three`, the middle
## one tallest). `span` is the full width, `depth` the thickness across
## the wall, `wall_h` the central block height.
static func gopura(lm: LandmarkMesh, stone: String, trim: String, dark: String, roof: String,
		base: Vector3, basis: Basis, span: float, depth: float, wall_h: float, tower_h: float,
		three: bool = false) -> void:
	var cw := span * 0.42
	var ww := (span - cw) * 0.5
	var wh := wall_h * 0.9
	var pl := 0.6
	lm.box(trim, base + basis * Vector3(0, pl * 0.5, 0), Vector3(span + 1.2, pl, depth + 1.2), basis)
	lm.box(stone, base + basis * Vector3(0, pl + wall_h * 0.5, 0), Vector3(cw, wall_h, depth), basis)
	lm.box(trim, base + basis * Vector3(0, pl + wall_h + 0.2, 0), Vector3(cw + 0.8, 0.4, depth + 0.8), basis)
	for s in [-1.0, 1.0]:
		var cx: float = s * (cw * 0.5 + ww * 0.5)
		lm.box(stone, base + basis * Vector3(cx, pl + wh * 0.5, 0), Vector3(ww, wh, depth * 0.8), basis)
		lm.box(trim, base + basis * Vector3(cx, pl + wh + 0.15, 0), Vector3(ww + 0.4, 0.3, depth * 0.8 + 0.4), basis)
		lm.gable(roof, base + basis * Vector3(cx, pl + wh + 0.3, 0), ww, depth * 0.8, wh * 0.3, basis,
			0.3, stone)
		for f in [-1.0, 1.0]:
			lm.box(dark, base + basis * Vector3(cx, pl + wh * 0.5, f * depth * 0.4), Vector3(ww * 0.3, wh * 0.42, 0.12),
				basis, 0.0)
	var dw := minf(cw * 0.26, 3.0)
	for f in [-1.0, 1.0]:
		var fb := Basis(basis.y.normalized(), 0.0 if f > 0.0 else PI) * basis
		if span >= 20.0:
			U.false_door(lm, trim, dark, base + basis * Vector3(0, pl, f * depth * 0.5), fb, dw, wall_h * 0.5)
		else:
			lm.box(dark, base + basis * Vector3(0, pl + wall_h * 0.3, f * (depth * 0.5 + 0.03)),
				Vector3(dw, wall_h * 0.6, 0.08), basis, 0.0)
	var top := base + basis * Vector3(0, pl + wall_h + 0.4, 0)
	if three:
		tower(lm, stone, trim, dark, top, cw * 0.17, tower_h, 3, 0.28)
		for s in [-1.0, 1.0]:
			tower(lm, stone, trim, dark, top + basis * Vector3(s * cw * 0.34, 0, 0), cw * 0.12,
				tower_h * 0.7, 2, 0.3)
	else:
		tower(lm, stone, trim, dark, top, cw * 0.36, tower_h, 2 if tower_h < 8.0 else 3, 0.28)

## Lean version of U.prasat for the many minor towers: plain box storeys
## with a redent and a dark doorway on each face, a cornice and a step per
## storey, and the lotus-bud crown taking `crown` of the height h.
static func tower(lm: LandmarkMesh, wall: String, roof: String, dark: String, base: Vector3,
		hw: float, h: float, tiers: int = 3, crown: float = 0.28, shrink: float = 0.8) -> void:
	var crown_h := h * crown
	var body_h := h - crown_h
	var plinth_h := body_h * 0.12
	lm.box(wall, base + Vector3(0, plinth_h * 0.5, 0), Vector3(hw * 2.4, plinth_h, hw * 2.4), Basis(), 0.0)
	var storey_h := (body_h - plinth_h) / float(tiers)
	var y := plinth_h
	var w := hw
	for k in tiers:
		var wall_h := storey_h * 0.7
		lm.box(wall, base + Vector3(0, y + wall_h * 0.5, 0), Vector3(w * 2.0, wall_h, w * 2.0), Basis(), 0.0)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box(wall, base + b * Vector3(0, y + wall_h * 0.5, w + w * 0.06), Vector3(w * 0.9, wall_h, w * 0.12),
				b, 0.0)
			lm.box(dark, base + b * Vector3(0, y + wall_h * 0.4, w + w * 0.13), Vector3(w * 0.36, wall_h * 0.6, 0.06),
				b, 0.0)
		lm.box(roof, base + Vector3(0, y + wall_h + storey_h * 0.1, 0),
			Vector3(w * 2.2, storey_h * 0.2, w * 2.2), Basis(), 0.0)
		lm.box(roof, base + Vector3(0, y + wall_h + storey_h * 0.25, 0),
			Vector3(w * 1.8, storey_h * 0.1, w * 1.8), Basis(), 0.0)
		y += storey_h
		w *= shrink
	U.lotus_bud(lm, roof, base + Vector3(0, y, 0), w * 1.02, crown_h, 8)

## Hall of Dancers: a platform with the ring gallery and its cross walls
## (three corridors and the north-south crossbar), a gabled roof and a stair
## at each end. `c` is the centre on the ground.
static func _hall_of_dancers(lm: LandmarkMesh, k: Array[String], c: Vector3) -> void:
	var hx := 14.0
	var hz := 10.0
	lm.box("Laterite", c + Vector3(0, 0.5, 0), Vector3(hx * 2.0 + 3.0, 1.0, hz * 2.0 + 3.0))
	lm.box("Trim", c + Vector3(0, 1.05, 0), Vector3(hx * 2.0 + 3.4, 0.2, hz * 2.0 + 3.4), Basis(), 0.0)
	gallery(lm, k, c + Vector3(0, 1.0, 0), hx, hz, 3.6, 1.0, 0.0, 0.0, true, false)
	lm.box("Stone", c + Vector3(0, 1.0 + 3.6 + 0.2, 0), Vector3(hx * 2.0 + 1.0, 0.4, hz * 2.0 + 1.0))
	lm.gable("Stone", c + Vector3(0, 1.0 + 3.6 + 0.4, 0), hz * 2.0, hx * 2.0, 2.2,
		Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
	for z in [-3.3, 3.3]:
		run(lm, k, c + Vector3(-hx, 1.0, z), c + Vector3(hx, 1.0, z), 3.6, 0.8, false, false)
	run(lm, k, c + Vector3(0, 1.0, -hz), c + Vector3(0, 1.0, hz), 3.6, 0.8, false, false)
	for side in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, PI * 0.5 * side)
		U.stair(lm, "Stone", c + b * Vector3(0, 0, hx + 1.5), b, 5.0, 3, 0.5, 0.333)

## Two-storey building: a floor of 32 round columns carrying a slab and a
## walled upper storey under a stone roof. `c` is the centre on the ground.
static func _two_storey(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Laterite", c + Vector3(0, 0.3, 0), Vector3(20.0, 0.6, 10.0))
	for ix in 8:
		for iz in 4:
			var p := c + Vector3(-8.4 + 2.4 * float(ix), 0.6, -3.9 + 2.6 * float(iz))
			lm.frustum("Stone", p, 0.42, 0.38, 3.5, 8)
			lm.box("Trim", p + Vector3(0, 3.6, 0), Vector3(1.0, 0.2, 1.0), Basis(), 0.0)
	lm.box("Stone", c + Vector3(0, 4.35, 0), Vector3(18.8, 0.5, 9.4))
	lm.box("Stone", c + Vector3(0, 4.6 + 1.5, 0), Vector3(14.0, 3.0, 5.6))
	for s in [-1.0, 1.0]:
		for i in 4:
			lm.box("Dark", c + Vector3(-5.1 + 3.4 * float(i), 6.1, s * 2.8), Vector3(1.3, 1.5, 0.12),
				Basis(), 0.0)
	lm.box("Trim", c + Vector3(0, 7.8, 0), Vector3(16.0, 0.4, 7.6))
	lm.gable("Stone", c + Vector3(0, 8.0, 0), 6.4, 15.0, 1.6, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")

## Small Hindu satellite temple: a walled court (opening east) round a
## sandstone tower on a low platform.
static func _satellite(lm: LandmarkMesh, c: Vector3) -> void:
	var k: Array[String] = ["Laterite", "Stone", "Dark"]
	gallery(lm, k, c, 9.0, 8.0, 3.4, 1.0, 2.0, 0.0, false, false)
	lm.box("Stone", c + Vector3(0, 0.4, 0), Vector3(8.0, 0.8, 8.0))
	tower(lm, "Stone", "Trim", "Dark", c + Vector3(0, 0.8, 0), 2.2, 10.5, 3, 0.28)

## Pond rim: a low laterite curb round a w x l pond (the water is dry).
static func _pond(lm: LandmarkMesh, c: Vector3, w: float, l: float) -> void:
	for s in [-1.0, 1.0]:
		lm.box("Laterite", c + Vector3(0, 0.25, s * l * 0.5), Vector3(w + 1.2, 0.5, 1.2))
		lm.box("Laterite", c + Vector3(s * w * 0.5, 0.25, 0), Vector3(1.2, 0.5, l - 1.2))

## Silk-cotton mass: a swollen dark trunk with buttress roots spreading to
## the ground and a mossy bulge where it clasps the stone.
static func tree(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Root", base, PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r, h * 0.25),
		Vector2(r * 1.15, h * 0.5), Vector2(r * 0.8, h * 0.75), Vector2(r * 1.0, h * 0.9),
		Vector2(r * 0.4, h)]), 9)
	for i in 7:
		var a := TAU * float(i) / 7.0 + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Root", base + d * r * 0.5 + Vector3(0, h * 0.42, 0), base + d * r * 3.4 + Vector3(0, r * 0.32, 0),
			r * 0.5, r * 0.4, Vector3.UP)
	lm.lathe("Moss", base + Vector3(0, h * 0.6, 0), PackedVector2Array([Vector2(r * 0.9, 0),
		Vector2(r * 1.8, h * 0.12), Vector2(r * 1.4, h * 0.26), Vector2(r * 0.6, h * 0.34)]), 9)
