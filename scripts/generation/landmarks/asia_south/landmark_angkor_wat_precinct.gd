class_name LandmarkAngkorWatPrecinct
extends RefCounted

## Angkor Wat's precinct round the central temple (LandmarkSeaTemples),
## in the temple model's frame: origin at the outer gallery's centre, +X
## east, +Z south, true metres. Positions follow the mapped fourth
## enclosure wall (1031 x 822 m), its gates, the moat and the two
## reflecting ponds (OSM, measured 2026-11): the western causeway across
## the moat, the western gopura (235 m, three towers, elephant gates at
## its ends), the raised avenue with its naga balustrades, the two
## libraries, the laterite rims of the ponds, the cruciform Terrace of
## Honour and the stepped laterite banks of the moat. The moat's water
## and the ponds' water are the map's own.

const LT = preload("res://scripts/generation/landmarks/asia_south/landmark_sea_temples.gd")

## Fourth enclosure wall: west, east (x) and north, south (z) faces.
const WALL_X := [-544.7, 486.2]
const WALL_Z := [-409.0, 413.4]
## Moat edges, inner and outer.
const MOAT_IN := Rect2(-586.0, -457.0, 1116.0, 917.0)
const MOAT_OUT := Rect2(-776.0, -647.0, 1496.0, 1297.0)
## Western gopura: wall line x and its north-south extent (z).
const GOPURA_X := -548.0
const GOPURA_Z := [-122.0, 114.0]
## East gate on the east wall: its z extent.
const EAST_GATE_Z := [-11.0, 35.0]
## Raised avenue from the gopura to the Terrace of Honour.
const AVENUE_X := [-528.0, -166.0]
const AVENUE_W := 9.5
const AVENUE_TOP := 1.5
## Outer causeway over the moat, from its western landing to the gopura.
const CAUSEWAY_X := [-800.0, -567.0]
const CAUSEWAY_W := 12.0
const CAUSEWAY_TOP := 1.0
## Libraries north and south of the avenue, and the pond rims (x0, z0, x1, z1).
const LIBRARY_X := -359.5
const LIBRARY_Z := 31.5
const PONDS := [[-283.7, -81.8, -206.8, -35.4], [-283.7, 32.1, -206.8, 81.8]]
const TERRACE_X := -146.5

static func build(lm: LandmarkMesh) -> void:
	_walls(lm)
	_west_gopura(lm)
	_east_gate(lm)
	_causeway(lm)
	_avenue(lm)
	for s in [-1.0, 1.0]:
		_library(lm, Vector3(LIBRARY_X, 0, s * LIBRARY_Z))
	for p in PONDS:
		_rim(lm, Rect2(float(p[0]), float(p[1]), float(p[2]) - float(p[0]), float(p[3]) - float(p[1])),
			2.4, 0.5, -0.5)
	_terrace_of_honour(lm)
	_rim(lm, MOAT_IN, 4.0, 0.3, -3.0)
	_rim(lm, MOAT_OUT, 4.0, 0.3, -3.0)

## Laterite wall run from a to b (xz), 4.5 m above the ground with a
## sandstone coping; its footing runs 1.5 m down so a dip never shows a gap.
static func _wall(lm: LandmarkMesh, a: Vector2, b: Vector2) -> void:
	var d := b - a
	var ln := d.length()
	if ln < 0.5:
		return
	var basis := Basis(Vector3.UP, atan2(d.x, d.y))
	var m := (a + b) * 0.5
	lm.box("Laterite", Vector3(m.x, 1.5, m.y), Vector3(1.6, 6.0, ln), basis)
	lm.box("Sand", Vector3(m.x, 4.65, m.y), Vector3(2.0, 0.3, ln + 0.4), basis)

static func _walls(lm: LandmarkMesh) -> void:
	var w := float(WALL_X[0])
	var e := float(WALL_X[1])
	var n := float(WALL_Z[0])
	var s := float(WALL_Z[1])
	_wall(lm, Vector2(w, n), Vector2(e, n))
	_wall(lm, Vector2(w, s), Vector2(e, s))
	# West face: broken by the gopura; east face: by the east gate.
	_wall(lm, Vector2(w, n), Vector2(w, float(GOPURA_Z[0])))
	_wall(lm, Vector2(w, float(GOPURA_Z[1])), Vector2(w, s))
	_wall(lm, Vector2(e, n), Vector2(e, float(EAST_GATE_Z[0])))
	_wall(lm, Vector2(e, float(EAST_GATE_Z[1])), Vector2(e, s))

## The western entrance: a long gallery on the wall line, the central
## cruciform gopura and two lesser ones under (truncated) towers, and the
## elephant gates at its ends, level with the ground for carts.
static func _west_gopura(lm: LandmarkMesh) -> void:
	var z0 := float(GOPURA_Z[0])
	var z1 := float(GOPURA_Z[1])
	var x := GOPURA_X
	var run := z1 - z0
	var zc := (z0 + z1) * 0.5
	var along := Basis(Vector3.UP, 0.0)
	lm.box("Laterite", Vector3(x, 0.0, zc), Vector3(12.0, 2.0, run + 4.0))
	lm.box("Sand", Vector3(x, 3.5, zc), Vector3(7.0, 5.0, run))
	lm.box("Sand", Vector3(x, 6.2, zc), Vector3(7.6, 0.4, run + 0.6))
	lm.gable("Roof", Vector3(x, 6.4, zc), 7.0, run, 2.4, along, 0.4, "Sand")
	# Pillared half-gallery on the west (outer) face.
	var n := int(run / 3.6)
	for i in n:
		var z := z0 + (float(i) + 0.5) * run / float(n)
		lm.box("Sand", Vector3(x - 5.2, 3.0, z), Vector3(0.7, 4.0, 0.7), Basis(), 0.0)
		lm.box("Shadow", Vector3(x - 3.53, 3.0, z), Vector3(0.04, 2.2, 1.4), Basis(), 0.0)
	lm.box("Sand", Vector3(x - 5.2, 5.2, zc), Vector3(0.9, 0.4, run))
	lm.quad("Roof", Vector3(x - 5.9, 5.4, z0), Vector3(x - 5.9, 5.4, z1), Vector3(x - 3.4, 6.6, z1),
		Vector3(x - 3.4, 6.6, z0), Vector3(-1.0, 1.5, 0.0).normalized())
	# Cruciform central gopura through the gallery, and the towers.
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.box("Sand", Vector3(x, 3.8, 0.0), Vector3(38.0 if k == 0 else 26.0, 5.6, 10.0), b)
		lm.gable("Roof", Vector3(x, 6.6, 0.0), 10.0, 38.0 if k == 0 else 26.0, 3.0,
			b * Basis(Vector3.UP, PI * 0.5), 0.4, "Sand")
	LT._prang(lm, Vector3(x, 1.0, 0.0), 5.0, 19.0)
	for s in [-1.0, 1.0]:
		LT._prang(lm, Vector3(x, 1.0, s * 30.0), 3.6, 14.0)
		LT._pavilion(lm, Vector3(x, 0.0, (z1 + 4.0) if s > 0.0 else (z0 - 4.0)), 7.0, 14.0)
	lm.box("Shadow", Vector3(x - 19.05, 3.0, 0.0), Vector3(0.04, 3.4, 2.4), Basis(), 0.0)

static func _east_gate(lm: LandmarkMesh) -> void:
	var z0 := float(EAST_GATE_Z[0])
	var z1 := float(EAST_GATE_Z[1])
	var x := float(WALL_X[1])
	lm.box("Sand", Vector3(x, 2.6, (z0 + z1) * 0.5), Vector3(6.0, 5.2, z1 - z0))
	lm.gable("Roof", Vector3(x, 5.2, (z0 + z1) * 0.5), 6.0, z1 - z0, 2.2, Basis(), 0.4, "Sand")
	LT._pavilion(lm, Vector3(x, 0.0, (z0 + z1) * 0.5), 8.0, 16.0)

## Naga balustrade along x at side z, deck top y: a serpent body on short
## posts, the raised seven-headed hood at either end.
static func _naga(lm: LandmarkMesh, x0: float, x1: float, z: float, y: float) -> void:
	var ln := x1 - x0
	var n := int(ln / 4.0)
	for i in n + 1:
		var x := x0 + ln * float(i) / float(n)
		lm.box("Sand", Vector3(x, y + 0.45, z), Vector3(0.45, 0.9, 0.45), Basis(), 0.0)
	lm.box("Sand", Vector3((x0 + x1) * 0.5, y + 1.05, z), Vector3(ln, 0.5, 0.55))
	for x in [x0, x1]:
		lm.box("Sand", Vector3(x, y + 1.4, z), Vector3(0.6, 2.8, 2.2))
		lm.box("Sand", Vector3(x, y + 2.9, z), Vector3(0.5, 0.6, 1.4))

## Paved deck along x, `w` wide, top at `top`, its body down into the
## ground (or the moat bed), with naga balustrades both sides.
static func _deck(lm: LandmarkMesh, x0: float, x1: float, w: float, top: float, bottom: float) -> void:
	var mid := (x0 + x1) * 0.5
	lm.box("Laterite", Vector3(mid, (top + bottom) * 0.5 - 0.15, 0.0), Vector3(x1 - x0, top - bottom - 0.3, w + 0.6))
	lm.box("Flag", Vector3(mid, top - 0.15, 0.0), Vector3(x1 - x0, 0.3, w), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		_naga(lm, x0 + 2.0, x1 - 2.0, s * (w * 0.5 - 0.4), top)

## The moat crossing, with its cruciform landing on the far bank.
static func _causeway(lm: LandmarkMesh) -> void:
	var x0 := float(CAUSEWAY_X[0])
	_deck(lm, x0, float(CAUSEWAY_X[1]), CAUSEWAY_W, CAUSEWAY_TOP, -5.0)
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.box("Flag", Vector3(x0 - 6.0, CAUSEWAY_TOP * 0.5 - 0.5, 0.0),
			Vector3(28.0 if k == 0 else 14.0, CAUSEWAY_TOP + 1.0, 14.0 if k == 0 else 34.0), b)
	for s in [-1.0, 1.0]:
		_lion(lm, Vector3(x0 - 18.0, CAUSEWAY_TOP, s * 4.0))

static func _lion(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Sand", p + Vector3(0, 0.3, 0), Vector3(1.6, 0.6, 0.9))
	lm.box("Sand", p + Vector3(0.2, 1.1, 0), Vector3(0.9, 1.2, 0.8))
	lm.box("Sand", p + Vector3(-0.35, 1.9, 0), Vector3(0.7, 0.7, 0.7))

## The raised processional avenue, with stair landings out to either side.
static func _avenue(lm: LandmarkMesh) -> void:
	var x0 := float(AVENUE_X[0])
	var x1 := float(AVENUE_X[1])
	_deck(lm, x0, x1, AVENUE_W, AVENUE_TOP, -1.0)
	for x in [-455.0, -335.0, -225.0]:
		for s in [-1.0, 1.0]:
			lm.box("Flag", Vector3(x, AVENUE_TOP * 0.5 - 0.3, s * (AVENUE_W * 0.5 + 3.0)),
				Vector3(6.0, AVENUE_TOP + 0.6, 6.0))

## Cruciform library on its laterite platform: a gabled hall east-west
## crossed by the porch range, dark doorways at the four ends.
static func _library(lm: LandmarkMesh, p: Vector3) -> void:
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var l := 34.0 if k == 0 else 23.0
		lm.box("Laterite", p + Vector3(0, 0.6, 0), Vector3(l + 4.0, 2.4, 14.0 if k == 0 else 12.0), b)
		lm.box("Sand", p + Vector3(0, 1.85, 0), Vector3(l + 4.4, 0.3, 14.4 if k == 0 else 12.4), b, 0.0)
		lm.box("Sand", p + Vector3(0, 4.7, 0), Vector3(l, 5.4, 9.0 if k == 0 else 7.0), b)
		lm.gable("Roof", p + Vector3(0, 7.4, 0), 9.0 if k == 0 else 7.0, l, 3.2,
			b * Basis(Vector3.UP, PI * 0.5), 0.4, "Sand")
		for s in [-1.0, 1.0]:
			lm.box("Shadow", p + b * Vector3(s * (l * 0.5 + 0.02), 4.0, 0.0), Vector3(0.04, 3.2, 1.6), b, 0.0)

## Stepped laterite rim round rect `r` (xz), `w` wide, top at `top`,
## running down to `bottom`.
static func _rim(lm: LandmarkMesh, r: Rect2, w: float, top: float, bottom: float) -> void:
	var h := top - bottom
	var y := (top + bottom) * 0.5
	var c := r.get_center()
	for s in [-1.0, 1.0]:
		lm.box("Laterite", Vector3(c.x, y, c.y + s * r.size.y * 0.5), Vector3(r.size.x + w, h, w))
		lm.box("Laterite", Vector3(c.x + s * r.size.x * 0.5, y, c.y), Vector3(w, h, r.size.y - w))

## The cruciform Terrace of Honour before the western entrance, raised
## on short columns, naga balustrades round its arms.
static func _terrace_of_honour(lm: LandmarkMesh) -> void:
	var p := Vector3(TERRACE_X, 0.0, 0.0)
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var l := 40.0 if k == 0 else 30.0
		lm.box("Laterite", p + Vector3(0, 0.4, 0), Vector3(l, 1.4, 10.0), b)
		lm.box("Flag", p + Vector3(0, 1.5, 0), Vector3(l, 0.8, 10.0), b)
		for s in [-1.0, 1.0]:
			var q := p + b * Vector3(0, 0, s * 4.6)
			lm.box("Sand", q + Vector3(0, 2.4, 0), Vector3(l - 2.0, 0.45, 0.5), b)
			lm.box("Sand", q + Vector3(0, 2.05, 0), Vector3(l - 2.0, 0.35, 0.3), b, 0.0)
