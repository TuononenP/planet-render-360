class_name LandmarkSuspensionBridges
extends RefCounted

## The two great suspension bridges in true metres, built along +X with
## y = 0 at the water (LocationData `base: water`): towers, main cables
## sagging between them and down to the anchorages, vertical suspenders
## and the stiffened deck. RoadBuilder leaves the OSM deck out of their
## span (LandmarkSites.outside_spans), so this deck is the road.

## Golden Gate Bridge: 1280 m main span and 343 m side spans, the two
## Art Deco towers 227 m above the water with their stepped legs and
## portal struts, cables 27 m apart, the 67 m deck on its deep
## stiffening truss, all in International Orange.
const GG_MAIN := 1280.0
const GG_SIDE := 343.0
const GG_TOWER_M := 227.0
const GG_DECK_M := 67.0
const GG_HALF_W := 13.7

static func golden_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Orange", LandmarkMaterials.paint("#C0362C", 0.6, 0.3))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B3A8", 4.0))
	var tx := GG_MAIN * 0.5
	var end := tx + GG_SIDE
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		lm.box("Concrete", Vector3(x, 4.0, 0), Vector3(30.0, 12.0, 46.0))
		for side in [-1.0, 1.0]:
			var z: float = side * GG_HALF_W
			# Legs step in at each stage, Art Deco set-backs.
			var stages := [[6.0, 72.0, 10.0, 16.0], [72.0, 140.0, 9.0, 14.0],
				[140.0, 190.0, 8.0, 12.0], [190.0, GG_TOWER_M, 7.0, 10.0]]
			for st in stages:
				var y0 := float(st[0])
				var y1 := float(st[1])
				lm.box("Orange", Vector3(x, (y0 + y1) * 0.5, z), Vector3(float(st[3]), y1 - y0, float(st[2])))
				for f in [-1.0, 1.0]:
					lm.box("Orange", Vector3(x + f * float(st[3]) * 0.5, (y0 + y1) * 0.5, z),
						Vector3(0.8, y1 - y0 - 2.0, float(st[2]) * 0.4))
		# Portal struts between the legs above the deck, and the deck strut.
		for py in [GG_DECK_M - 4.0, 108.0, 150.0, 186.0, GG_TOWER_M - 6.0]:
			lm.box("Orange", Vector3(x, py, 0), Vector3(8.0, 6.0, GG_HALF_W * 2.0))
	# Main cables: catenary-ish parabolas tower to tower and down to the
	# anchorages, with the suspenders every 15 m.
	var top := GG_TOWER_M - 2.0
	for side in [-1.0, 1.0]:
		var z: float = side * GG_HALF_W
		_cable(lm, "Orange", Vector3(-tx, top, z), Vector3(tx, top, z), top - GG_DECK_M - 3.0, 48, 0.95)
		for s in [-1.0, 1.0]:
			_cable(lm, "Orange", Vector3(s * tx, top, z), Vector3(s * end, GG_DECK_M + 4.0, z),
				18.0, 16, 0.95)
		var x := -end + 7.5
		while x < end:
			var cy := _cable_y(x, tx, end, top, GG_DECK_M + 3.0, GG_DECK_M + 4.0, 18.0)
			if cy - GG_DECK_M > 2.0:
				lm.beam("Orange", Vector3(x, GG_DECK_M, z), Vector3(x, cy, z), 0.25, 0.25)
			x += 15.0
	# Deck and its stiffening truss.
	lm.box("Deck", Vector3(0, GG_DECK_M + 0.2, 0), Vector3(end * 2.0, 0.4, GG_HALF_W * 2.0))
	for side in [-1.0, 1.0]:
		var z: float = side * GG_HALF_W
		lm.box("Orange", Vector3(0, GG_DECK_M - 3.8, z), Vector3(end * 2.0, 7.6, 0.6))
		lm.box("Orange", Vector3(0, GG_DECK_M + 0.9, z * 1.02), Vector3(end * 2.0, 1.2, 0.3))
	lm.box("Orange", Vector3(0, GG_DECK_M - 7.4, 0), Vector3(end * 2.0, 0.6, GG_HALF_W * 2.0))
	# Anchorage blocks at both ends.
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * (end + 18.0), GG_DECK_M * 0.5, 0), Vector3(36.0, GG_DECK_M + 6.0, 44.0))
	lm.commit(model)

## Brooklyn Bridge: 486 m main span between the granite towers (84 m),
## each pierced by two pointed Gothic arches over the roadways, four
## main cables with the diagonal stays that web the spans, the deck at
## 41 m falling to the masonry anchorages 283 m beyond each tower.
const BB_MAIN := 486.0
const BB_SIDE := 283.0
const BB_TOWER_M := 84.3
const BB_DECK_M := 41.0
const BB_END_DECK_M := 30.0

static func brooklyn(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B5A894", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#8C8778", 0.55, 0.4))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Shadow", LandmarkMaterials.paint("#2A2A28", 0.9, 0.0))
	var tx := BB_MAIN * 0.5
	var end := tx + BB_SIDE
	var tw := 43.0
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		lm.box("Granite", Vector3(x, BB_DECK_M * 0.5, 0), Vector3(18.0, BB_DECK_M, tw))
		# Three piers round the two arches, the lintel and the cornice.
		var spring := BB_DECK_M + 28.0
		var apex := BB_DECK_M + 35.0
		for pz in [-17.5, 0.0, 17.5]:
			lm.box("Granite", Vector3(x, (BB_DECK_M + apex) * 0.5, pz), Vector3(18.0, apex - BB_DECK_M, 8.0))
		lm.box("Granite", Vector3(x, (apex + BB_TOWER_M) * 0.5, 0), Vector3(18.0, BB_TOWER_M - apex, tw))
		lm.box("Granite", Vector3(x, BB_TOWER_M - 0.6, 0), Vector3(19.2, 1.2, tw + 1.2))
		# Pointed heads of the arches: stone spandrels on both faces.
		for oz in [-8.75, 8.75]:
			var zl: float = oz - 4.75
			var zr: float = oz + 4.75
			for f in [-1.0, 1.0]:
				var fx: float = x + f * 9.0
				var n := Vector3(f, 0, 0)
				lm.tri("Granite", Vector3(fx, spring, zl), Vector3(fx, apex, zl), Vector3(fx, apex, oz),
					n, n, n, Vector2(0, 0), Vector2(0, -7), Vector2(4.75, -7))
				lm.tri("Granite", Vector3(fx, spring, zr), Vector3(fx, apex, zr), Vector3(fx, apex, oz),
					n, n, n, Vector2(0, 0), Vector2(0, -7), Vector2(4.75, -7))
			lm.box("Shadow", Vector3(x, (spring + apex) * 0.5, oz), Vector3(17.6, apex - spring, 0.4))
	# Deck: rises from the anchorages to mid-span (a gentle arch).
	var segs := 40
	for k in segs:
		var xa := -end + 2.0 * end * k / segs
		var xb := -end + 2.0 * end * (k + 1) / segs
		var ya := _bb_deck(xa, end)
		var yb := _bb_deck(xb, end)
		var r := Basis(Vector3.BACK, atan2(yb - ya, xb - xa))
		var c := Vector3((xa + xb) * 0.5, (ya + yb) * 0.5, 0)
		lm.box("Deck", c + Vector3(0, 0.2, 0), Vector3(xb - xa + 0.4, 0.4, 26.0), r)
		lm.box("Steel", c + Vector3(0, -2.4, 0), Vector3(xb - xa + 0.4, 4.4, 26.4), r)
	# Four cables, suspenders every 10 m, and the diagonal stays.
	var top := BB_TOWER_M - 3.0
	for cz in [-12.0, -4.0, 4.0, 12.0]:
		var z: float = cz
		_cable(lm, "Steel", Vector3(-tx, top, z), Vector3(tx, top, z), top - BB_DECK_M - 2.0, 32, 0.4)
		for s in [-1.0, 1.0]:
			_cable(lm, "Steel", Vector3(s * tx, top, z), Vector3(s * end, BB_END_DECK_M + 6.0, z),
				10.0, 14, 0.4)
		var x := -end + 5.0
		while x < end:
			var cy := _cable_y(x, tx, end, top, BB_DECK_M + 2.0, BB_END_DECK_M + 6.0, 10.0)
			if absf(absf(x) - tx) > 10.0:
				lm.beam("Steel", Vector3(x, _bb_deck(x, end), z), Vector3(x, cy, z), 0.12, 0.12)
			x += 10.0
		for s in [-1.0, 1.0]:
			for k in range(1, 9):
				for dirn in [-1.0, 1.0]:
					var dx: float = s * tx + dirn * 17.0 * k
					if absf(dx) > end:
						continue
					lm.beam("Steel", Vector3(s * tx, top - 2.0, z), Vector3(dx, _bb_deck(dx, end) + 0.5, z), 0.1, 0.1)
	# Masonry anchorages.
	for s in [-1.0, 1.0]:
		lm.box("Granite", Vector3(s * (end + 20.0), (BB_END_DECK_M + 6.0) * 0.5, 0),
			Vector3(40.0, BB_END_DECK_M + 6.0, 36.0))
	lm.commit(model)

static func _bb_deck(x: float, end: float) -> float:
	var u := clampf(x / end, -1.0, 1.0)
	return lerpf(BB_DECK_M, BB_END_DECK_M, u * u)

## Height of a main cable at x: a parabola between the towers (±tx) down
## to `low` at mid-span, and a sagging side span to the anchorage (±end,
## `anchor`), `side_sag` below its chord.
static func _cable_y(x: float, tx: float, end: float, top: float, low: float, anchor: float,
		side_sag: float) -> float:
	var ax := absf(x)
	if ax <= tx:
		var u := ax / tx
		return low + (top - low) * u * u
	var t := clampf((ax - tx) / (end - tx), 0.0, 1.0)
	return lerpf(top, anchor, t) - side_sag * 4.0 * t * (1.0 - t)

## A cable from a to b sagging `sag` below their chord at its middle,
## as `n` straight members `w` thick.
static func _cable(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, sag: float, n: int,
		w: float) -> void:
	var prev := a
	for k in range(1, n + 1):
		var t := float(k) / n
		var p := a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		lm.beam(key, prev, p, w, w)
		prev = p
