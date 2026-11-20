class_name StoOuterTele2Arena
extends RefCounted

## Tele2 Arena (3Arena since 2024; 2013, Johanneshov beside Globen), the
## 30,000-seat arena with its retractable roof. True metres from the OSM
## outline of way 193461738 (x east, z south from its centroid, no yaw:
## registry `yaw_deg` 0); the top is the OSM `height` 52 m.
##
## Spec, from visual-plan/refs/landmarks/tele2_arena/ (front at night,
## aerial by day):
## - A raised concourse deck (the mapped outline) at 6-8.5 m on a forest of
##   round concrete piers with a dark glazed ground storey set back behind
##   them, a white fascia band round its rim and a lit entrance glazing.
## - On it a rounded lens-shaped shell, swelling past the deck rim at 15 m
##   and closing in an oval roof at 52 m, clad in a diagonal lattice of
##   silver perforated-aluminium diamonds: two sets of ribs twisting round
##   the shell in opposite directions over a dark grey skin. The lattice
##   glows coloured at night in the front photo; the model lights the
##   concourse band and shell skin warm white instead.
## - A small plant cabin on the crown over the roof opening.
## The plan is the mapped outline, rounded by two Chaikin passes; rib count
## and twist are scaled from the photos.
## Surfaces (6): Deck, Pier, Skin, Rib, Glass, Lamp.

const RING := [Vector2(14.8, -111.6), Vector2(31.4, -107.6), Vector2(40.9, -103.6), Vector2(46.3, -99.5),
	Vector2(50.8, -95.9), Vector2(57.8, -86.6), Vector2(63.0, -76.0), Vector2(73.5, -43.0), Vector2(78.4, -26.5),
	Vector2(97.0, 36.1), Vector2(96.8, 48.9), Vector2(94.4, 61.9), Vector2(90.6, 70.7), Vector2(77.7, 86.3),
	Vector2(53.3, 104.1), Vector2(23.5, 114.6), Vector2(-2.9, 115.6), Vector2(-12.1, 113.4), Vector2(-26.7, 108.6),
	Vector2(-39.9, 100.7), Vector2(-48.2, 87.8), Vector2(-100.8, -17.9), Vector2(-102.8, -32.0),
	Vector2(-101.3, -41.3), Vector2(-98.8, -57.2), Vector2(-95.1, -62.4), Vector2(-84.3, -77.6),
	Vector2(-62.2, -94.2), Vector2(-42.1, -103.7), Vector2(-23.6, -109.4), Vector2(-2.5, -111.6)]
## Shell rows: height, plan scale about the deck's centre.
const ROWS := [[8.5, 0.88], [12.0, 0.95], [18.0, 0.98], [25.0, 0.95], [32.0, 0.88], [38.0, 0.77],
	[43.0, 0.62], [47.0, 0.45], [50.0, 0.24], [51.8, 0.07]]
const TOP := 52.0
const DECK_Y0 := 6.0
const DECK_Y1 := 8.5
## Rib every RIB_STEP shell points, twisting TWIST points over the height.
const POINTS := 96
const RIB_STEP := 3
const TWIST := 22

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#B8B6B0", 4.0))
	lm.use("Pier", LandmarkMaterials.pbr("concrete", "#8F8E8B", 3.0))
	lm.use("Skin", LandmarkMaterials.paint("#808C94", 0.4, 0.7))
	lm.use("Rib", LandmarkMaterials.paint("#D4D9DC", 0.28, 0.85))
	lm.use("Glass", LandmarkMaterials.glass("#2A3438"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B8", 0.4))
	var plan := _even(_smooth(PackedVector2Array(RING), 2), POINTS)
	_deck(lm, plan)
	var rows := _shell(lm, plan)
	_ribs(lm, rows)
	lm.commit(model, "Tele2_arena_")

## Chaikin corner cutting, `passes` times, on a closed polygon.
static func _smooth(poly: PackedVector2Array, passes: int) -> PackedVector2Array:
	var p := poly
	for _i in passes:
		var q := PackedVector2Array()
		for i in p.size():
			var a := p[i]
			var b := p[(i + 1) % p.size()]
			q.append(a.lerp(b, 0.25))
			q.append(a.lerp(b, 0.75))
		p = q
	return p

## `poly` (closed) resampled to `n` points evenly spaced along its length.
static func _even(poly: PackedVector2Array, n: int) -> PackedVector2Array:
	var total := 0.0
	for i in poly.size():
		total += poly[i].distance_to(poly[(i + 1) % poly.size()])
	var out := PackedVector2Array()
	var seg := 0
	var seg_start := 0.0
	for k in n:
		var d := total * float(k) / float(n)
		while seg_start + poly[seg].distance_to(poly[(seg + 1) % poly.size()]) < d:
			seg_start += poly[seg].distance_to(poly[(seg + 1) % poly.size()])
			seg += 1
		var a := poly[seg]
		var b := poly[(seg + 1) % poly.size()]
		out.append(a.lerp(b, (d - seg_start) / maxf(a.distance_to(b), 0.001)))
	return out

## Concourse deck on piers with its glazed ground storey, white fascia
## and lit rim band.
static func _deck(lm: LandmarkMesh, plan: PackedVector2Array) -> void:
	lm.poly_prism("Glass", F.offset(plan, -9.0), 0.0, DECK_Y0, false)
	lm.poly_prism("Deck", plan, DECK_Y0, DECK_Y1, true)
	lm.poly_prism("Lamp", F.offset(plan, 0.15), DECK_Y0 + 0.3, DECK_Y0 + 0.9, false)
	lm.poly_prism("Rib", F.offset(plan, 0.3), DECK_Y1 - 0.9, DECK_Y1, false)
	var ring := F.offset(plan, -3.0)
	for i in range(0, ring.size(), 6):
		var c := ring[i]
		lm.frustum("Pier", Vector3(c.x, 0.0, c.y), 0.9, 0.9, DECK_Y0, 10)

## The shell skin as a smooth grid of rings; returns the rows of points.
static func _shell(lm: LandmarkMesh, plan: PackedVector2Array) -> Array:
	var rows: Array = []
	for r in ROWS:
		var y: float = r[0]
		var s: float = r[1]
		var row := PackedVector3Array()
		for p in plan:
			row.append(Vector3(p.x * s, y, p.y * s))
		row.append(row[0])
		rows.append(row)
	lm.grid("Skin", rows, Vector3(0.0, 20.0, 0.0), true)
	var cap := PackedVector2Array()
	var last: PackedVector3Array = rows[rows.size() - 1]
	for i in last.size() - 1:
		cap.append(Vector2(last[i].x, last[i].z))
	lm.poly_prism("Rib", cap, TOP - 0.2, TOP, true)
	return rows

## Two sets of diagonal ribs winding round the shell in opposite senses.
static func _ribs(lm: LandmarkMesh, rows: Array) -> void:
	var n := (rows[0] as PackedVector3Array).size() - 1
	for dir in [-1, 1]:
		for k in range(0, n, RIB_STEP):
			for r in rows.size() - 1:
				var i0 := posmod(k + int(round(float(dir * TWIST) * float(r) / float(rows.size() - 1))), n)
				var i1 := posmod(k + int(round(float(dir * TWIST) * float(r + 1) / float(rows.size() - 1))), n)
				var a: Vector3 = (rows[r] as PackedVector3Array)[i0]
				var b: Vector3 = (rows[r + 1] as PackedVector3Array)[i1]
				var nrm := Vector3(a.x, 0.0, a.z).normalized() * 0.35
				lm.beam("Rib", a + nrm, b + nrm, 0.8, 0.55)

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
