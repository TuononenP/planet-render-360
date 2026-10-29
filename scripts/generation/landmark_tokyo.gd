class_name LandmarkTokyo
extends RefCounted

## Tokyo Tower in true metres (332.9 m): four splayed lattice legs on an
## ~80 m square that merge at ~48 m into one tapering square shaft,
## the two-storey Main Deck (145/150 m), the Top Deck (250 m) and the
## antenna lattice and mast. Painted in the aviation scheme of
## international orange (#E8501E) and white bands; Foot Town fills the
## space between the legs. Members are merged lattice bars, one surface
## per part/colour.

const MERGE_Y := 48.0
const MAIN_Y := 140.0
const TOP_DECK_Y := 248.0
const LATTICE_TOP := 296.0
const HEIGHT := 332.9

static var OUTER := PackedVector2Array([Vector2(0, 40.0), Vector2(24, 31.0),
	Vector2(48, 24.0), Vector2(90, 17.5), Vector2(140, 12.5), Vector2(200, 8.0),
	Vector2(248, 5.0), Vector2(270, 2.8), Vector2(296, 1.8)])
static var INNER := PackedVector2Array([Vector2(0, 27.0), Vector2(20, 16.0),
	Vector2(38, 7.0), Vector2(48, 0.0)])

## White bands (everything else on the steel is international orange).
const WHITE := [[96.0, 112.0], [156.0, 170.0], [184.0, 198.0], [212.0, 226.0],
	[256.0, 266.0], [276.0, 286.0], [304.0, 314.0], [322.0, 328.0]]

static func outer(y: float) -> float:
	return LandmarkMesh.profile_at(OUTER, y)

static func _is_white(y: float) -> bool:
	for b in WHITE:
		if y >= float(b[0]) and y < float(b[1]):
			return true
	return false

static func build(model: Node3D) -> void:
	var orange := LandmarkMaterials.paint("#E8501E", 0.55, 0.2)
	var white := LandmarkMaterials.paint("#ECEAE4", 0.55, 0.2)
	var lm := LandmarkMesh.new()
	for k in ["LegN", "LegE", "LegS", "LegW", "ShaftOrange", "AntennaOrange"]:
		lm.use(k, orange)
	for k in ["ShaftWhite", "AntennaWhite", "MainDeck", "TopDeck"]:
		lm.use(k, white)
	lm.use("DeckGlass", LandmarkMaterials.glass("#6F8590"))
	lm.use("FootTown", LandmarkMaterials.pbr("render", "#D8D6D0", 4.0))
	var legs := {"LegS": Vector2(1, 1), "LegE": Vector2(1, -1),
		"LegN": Vector2(-1, -1), "LegW": Vector2(-1, 1)}
	for key in legs:
		_leg(lm, key, legs[key])
	_shaft(lm)
	_decks(lm)
	_foot_town(lm)
	lm.commit(model)

## Levels that land exactly on every band edge and deck.
static func _levels(y_from: float, y_to: float) -> PackedFloat32Array:
	var cuts: Array[float] = [y_from, y_to, MAIN_Y, MAIN_Y + 16.0, TOP_DECK_Y, TOP_DECK_Y + 8.0]
	for b in WHITE:
		cuts.append(float(b[0]))
		cuts.append(float(b[1]))
	cuts.sort()
	var ys := PackedFloat32Array()
	for i in cuts.size() - 1:
		var a := cuts[i]
		var b := cuts[i + 1]
		if b <= y_from or a >= y_to or b - a < 0.5:
			continue
		a = maxf(a, y_from)
		b = minf(b, y_to)
		var n := maxi(1, int(round((b - a) / clampf(outer(a) * 0.8, 4.0, 12.0))))
		for k in n:
			ys.append(a + (b - a) * float(k) / float(n))
	ys.append(y_to)
	return ys

## A splayed leg below the merge: four chords, X-lattice on every face.
static func _leg(lm: LandmarkMesh, key: String, q: Vector2) -> void:
	var ys := _levels(0.0, MERGE_Y)
	for li in ys.size() - 1:
		var c0 := _pier_corners(q, ys[li])
		var c1 := _pier_corners(q, ys[li + 1])
		for k in 4:
			lm.beam(key, c0[k], c1[k], 2.2, 2.2)
			var k2 := (k + 1) % 4
			lm.lattice_panel(key, c0[k], c0[k2], c1[k], c1[k2], 0.8, 2)
	# Base arch girder across each face between the leg feet.
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		var prev := Vector3.ZERO
		for s in 17:
			var u := -1.0 + 2.0 * float(s) / 16.0
			var y := 4.0 + 26.0 * sqrt(maxf(1.0 - u * u, 0.0))
			var i := LandmarkMesh.profile_at(INNER, y)
			var p := rot * Vector3(u * maxf(i, 0.5), y, outer(y) - 0.8)
			if s > 0:
				lm.beam(key, prev, p, 1.1, 1.4)
			prev = p

static func _pier_corners(q: Vector2, y: float) -> Array:
	var o := outer(y)
	var i := maxf(LandmarkMesh.profile_at(INNER, y), 0.0)
	return [Vector3(q.x * i, y, q.y * i), Vector3(q.x * o, y, q.y * i),
		Vector3(q.x * o, y, q.y * o), Vector3(q.x * i, y, q.y * o)]

## Merged square shaft and antenna lattice, banded orange/white.
static func _shaft(lm: LandmarkMesh) -> void:
	var ys := _levels(MERGE_Y, LATTICE_TOP)
	for li in ys.size() - 1:
		var y0 := ys[li]
		var y1 := ys[li + 1]
		var mid := (y0 + y1) * 0.5
		var antenna := y0 >= TOP_DECK_Y
		var key := ("Antenna" if antenna else "Shaft") + ("White" if _is_white(mid) else "Orange")
		var o0 := outer(y0)
		var o1 := outer(y1)
		var c0 := [Vector3(o0, y0, o0), Vector3(-o0, y0, o0), Vector3(-o0, y0, -o0), Vector3(o0, y0, -o0)]
		var c1 := [Vector3(o1, y1, o1), Vector3(-o1, y1, o1), Vector3(-o1, y1, -o1), Vector3(o1, y1, -o1)]
		var chord := lerpf(2.2, 0.7, y0 / LATTICE_TOP)
		var w := lerpf(0.85, 0.35, y0 / LATTICE_TOP)
		for k in 4:
			lm.beam(key, c0[k], c1[k], chord, chord)
			var k2 := (k + 1) % 4
			lm.lattice_panel(key, c0[k], c0[k2], c1[k], c1[k2], w, 2 if y0 < TOP_DECK_Y else 1)
	# Antenna mast above the lattice, banded.
	var y := LATTICE_TOP
	var seg := 6.0
	while y < HEIGHT - 0.1:
		var y1 := minf(y + seg, HEIGHT)
		var key := "AntennaWhite" if _is_white((y + y1) * 0.5) else "AntennaOrange"
		var t0 := (y - LATTICE_TOP) / (HEIGHT - LATTICE_TOP)
		var t1 := (y1 - LATTICE_TOP) / (HEIGHT - LATTICE_TOP)
		lm.frustum(key, Vector3(0, y, 0), lerpf(1.1, 0.25, t0), lerpf(1.1, 0.25, t1), y1 - y, 8)
		y = y1

## Main Deck (two glazed storeys at 145/150 m) and the Top Deck.
static func _decks(lm: LandmarkMesh) -> void:
	_deck(lm, MAIN_Y, 16.0, outer(MAIN_Y) + 5.5, "MainDeck")
	_deck(lm, TOP_DECK_Y, 8.0, outer(TOP_DECK_Y) + 3.0, "TopDeck")

static func _deck(lm: LandmarkMesh, y: float, h: float, r: float, key: String) -> void:
	var b := Vector3(0, y, 0)
	lm.frustum(key, b, r * 0.8, r, h * 0.18, 8, PI / 8.0)
	lm.frustum("DeckGlass", b + Vector3(0, h * 0.18, 0), r, r * 1.02, h * 0.30, 8, PI / 8.0)
	lm.frustum(key, b + Vector3(0, h * 0.48, 0), r * 1.03, r * 1.03, h * 0.08, 8, PI / 8.0)
	lm.frustum("DeckGlass", b + Vector3(0, h * 0.56, 0), r * 0.98, r * 0.96, h * 0.30, 8, PI / 8.0)
	lm.frustum(key, b + Vector3(0, h * 0.86, 0), r * 0.97, r * 0.75, h * 0.14, 8, PI / 8.0)

## Foot Town: the four/five-storey podium building between the legs.
static func _foot_town(lm: LandmarkMesh) -> void:
	lm.box("FootTown", Vector3(0, 9.0, 0), Vector3(50.0, 18.0, 50.0))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 4:
			lm.box("DeckGlass", r * Vector3(0, 2.6 + float(k) * 4.2, 25.05), Vector3(46.0, 1.8, 0.2), r)
