class_name LandmarkAngNeakPean
extends RefCounted

## Neak Pean in true metres: the Buddhist island shrine of Jayavarman VII
## in the middle of the Jayatataka baray, set in its square pool with four
## smaller pools at the cardinal points.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const A = preload("res://scripts/generation/landmarks/angkor/landmark_ang_util.gd")

## Surface of the pools; the stepped banks rise from the terrain to meet it.
const WATER_Y := 0.12

## Neak Pean (9.6 m): the 70 m square central pool and the four 24 m pools
## at the north, east, south and west (their stepped laterite banks raised
## from the terrain, the water just above it), each linked to the central pool
## through a small sandstone chapel whose spout is a sculpted head (elephant
## north, human east, horse south, lion west). In the middle the round
## islet of seven laterite tiers (the lotus base), the two nagas Nanda and
## Upananda coiled round it with heads to the east and tails entwined at
## the west, and on top the single-cell sandstone shrine with a porch on
## each side under a lotus-bud tower; the horse Balaha with the
## shipwrecked sailors clinging to it stands in the pool east of the islet.
## Built facing +X (east).
static func neak_pean(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7D5B45", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#827A6B", 3.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#35564F", 6.0, 0.1))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))
	_pool(lm, Vector2.ZERO, 35.0, 35.0)
	for side in 4:
		var b := A.face(side)
		var dir := b * Vector3(0, 0, 1)
		_pool(lm, Vector2(dir.x, dir.z) * 53.0, 12.0, 12.0)
		_chapel(lm, b * Vector3(0, 0, 38.0), b, side)
	# Moss on the corners of the central pool's curb.
	for s in [-1.0, 1.0]:
		var sg: float = s
		for t in [-1.0, 1.0]:
			var tg: float = t
			lm.box("Moss", Vector3(sg * 33.8, 0.64, tg * 33.8), Vector3(2.6, 0.04, 2.6), Basis(), 0.0)
	_islet(lm)
	_balaha(lm, Vector3(17.0, WATER_Y, 0), A.face(1))
	lm.commit(model)

## Pool of half-sizes hx, hz centred on the XZ point c: the water slab inside
## a three-course stepped bank (curb 0.62 m, then 0.42 m and 0.27 m).
static func _pool(lm: LandmarkMesh, c: Vector2, hx: float, hz: float) -> void:
	lm.box("Water", Vector3(c.x, WATER_Y * 0.5, c.y), Vector3(hx * 2.0, WATER_Y, hz * 2.0), Basis(), 0.0)
	var courses := [[0.0, 1.4, 0.62], [1.4, 2.4, 0.42], [2.4, 3.4, 0.27]]
	for course in courses:
		var o0: float = course[0]
		var o1: float = course[1]
		var top: float = course[2]
		var mid := (o0 + o1) * 0.5
		for s in [-1.0, 1.0]:
			var sg: float = s
			lm.box("Laterite", Vector3(c.x, top * 0.5, c.y + sg * (hz - mid)),
				Vector3((hx - o0) * 2.0, top, o1 - o0), Basis(), 0.0)
			lm.box("Laterite", Vector3(c.x + sg * (hx - mid), top * 0.5, c.y),
				Vector3(o1 - o0, top, (hz - o1) * 2.0), Basis(), 0.0)

## Spout chapel on the central pool's bank (local +Z out toward the small
## pool): plinth, sandstone cell with its door facing out, a gabled roof
## under a lotus bud, and on the pool side the animal head of the spout:
## 0 south = horse, 1 east = human, 2 north = elephant, 3 west = lion.
static func _chapel(lm: LandmarkMesh, base: Vector3, b: Basis, side: int) -> void:
	lm.box("Stone", base + b * Vector3(0, 0.3, 0), Vector3(4.6, 0.6, 5.8), b)
	lm.box("Stone", base + b * Vector3(0, 2.0, 0), Vector3(3.4, 2.8, 4.6), b)
	lm.box("Stone", base + b * Vector3(0, 3.55, 0), Vector3(3.9, 0.3, 5.1), b)
	lm.gable("Stone", base + b * Vector3(0, 3.7, 0), 3.9, 5.1, 1.4, b, 0.2, "Stone")
	U.lotus_bud(lm, "Stone", base + b * Vector3(0, 5.1, 0), 0.7, 1.3, 8)
	U.false_door(lm, "Stone", "Dark", base + b * Vector3(0, 0.6, 2.3), b, 1.3, 2.2)
	var head := base + b * Vector3(0, 1.8, -2.75)
	lm.beam("Stone", head, head + b * Vector3(0, 0, 0.6), 0.4, 0.4, b * Vector3.RIGHT)
	lm.box("Stone", head + b * Vector3(0, 0, -0.1), Vector3(0.8, 0.9, 0.8), b)
	match side:
		2:
			lm.beam("Stone", head + b * Vector3(0, 0.1, -0.4), head + b * Vector3(0, -0.9, -0.75), 0.3, 0.26, b * Vector3.RIGHT)
			lm.box("Stone", head + b * Vector3(0.52, 0.1, 0), Vector3(0.1, 0.7, 0.5), b)
			lm.box("Stone", head + b * Vector3(-0.52, 0.1, 0), Vector3(0.1, 0.7, 0.5), b)
		0:
			lm.beam("Stone", head + b * Vector3(0, 0.2, -0.2), head + b * Vector3(0, -0.2, -1.0), 0.5, 0.4, b * Vector3.RIGHT)
		3:
			lm.box("Stone", head + b * Vector3(0, 0, -0.05), Vector3(1.3, 1.3, 0.4), b)
		_:
			lm.spire("Stone", head + b * Vector3(0, 0.45, 0), 0.4, 0.7, 0.05)

## Round islet: seven laterite tiers (the lotus base), the entwined nagas,
## the sandstone plinth and the shrine with four porches under its tower.
static func _islet(lm: LandmarkMesh) -> void:
	for i in 7:
		var r0 := 9.6 - 0.45 * float(i)
		lm.frustum("Laterite", Vector3(0, WATER_Y + 0.4 * float(i), 0), r0, r0 - 0.15, 0.4, 20)
	# Nanda and Upananda: two bodies coiling to the west, heads east.
	var span := PI * 1.12
	for n in 2:
		var sgn := 1.0 if n == 0 else -1.0
		var steps := 22
		for k in steps:
			var a0 := 0.12 + span * float(k) / float(steps)
			var a1 := 0.12 + span * float(k + 1) / float(steps)
			var p0 := _naga_pt(a0, sgn)
			var p1 := _naga_pt(a1, sgn)
			var w := 0.95 - 0.6 * float(k) / float(steps)
			lm.beam("Stone", p0, p1, w, w, Vector3.UP, true)
		U.naga_fan(lm, "Stone", Vector3(10.5, WATER_Y, sgn * 1.5), A.face(1), 3, 1.9)
	# Shrine.
	var y := WATER_Y + 2.8
	lm.box("Stone", Vector3(0, y + 0.25, 0), Vector3(9.0, 0.5, 9.0))
	y += 0.5
	U.prasat(lm, "Stone", "Stone", "Dark", Vector3(0, y, 0), 1.9, 6.2, 2, 0.34)
	for side in 4:
		var b := A.face(side)
		lm.box("Stone", b * Vector3(0, y + 1.4, 3.3), Vector3(2.4, 2.8, 2.4), b)
		lm.box("Dark", b * Vector3(0, y + 1.2, 4.52), Vector3(1.1, 2.0, 0.1), b, 0.0)
		lm.gable("Stone", b * Vector3(0, y + 2.8, 3.3), 2.6, 2.6, 1.0, b, 0.2, "Stone")

## Point of a naga body at angle a round the islet (sgn picks the side it
## leaves the head on); the two bodies undulate against each other.
static func _naga_pt(a: float, sgn: float) -> Vector3:
	var r := 10.3
	return Vector3(cos(a) * r, WATER_Y + 0.55 + 0.14 * sin(a * 4.0 + (0.0 if sgn > 0.0 else PI)),
		sgn * sin(a) * r)

## The horse Balaha on a low plinth, sailors clinging under its belly,
## facing basis +Z.
static func _balaha(lm: LandmarkMesh, base: Vector3, b: Basis) -> void:
	lm.box("Stone", base + b * Vector3(0, 0.35, 0), Vector3(1.4, 0.7, 3.4), b)
	for sx in [-1.0, 1.0]:
		var sg: float = sx
		for sz in [-1.0, 1.0]:
			var zg: float = sz
			lm.beam("Stone", base + b * Vector3(sg * 0.28, 0.7, zg * 0.9), base + b * Vector3(sg * 0.28, 1.6, zg * 0.9), 0.2, 0.2)
	lm.box("Stone", base + b * Vector3(0, 1.95, 0), Vector3(0.8, 0.8, 2.2), b)
	lm.beam("Stone", base + b * Vector3(0, 2.2, 0.9), base + b * Vector3(0, 3.0, 1.35), 0.5, 0.4, b * Vector3.RIGHT)
	lm.beam("Stone", base + b * Vector3(0, 3.0, 1.35), base + b * Vector3(0, 2.75, 1.95), 0.36, 0.32, b * Vector3.RIGHT)
	lm.beam("Stone", base + b * Vector3(0, 2.2, -1.0), base + b * Vector3(0, 1.3, -1.4), 0.22, 0.22, b * Vector3.RIGHT)
	for k in 5:
		lm.box("Stone", base + b * Vector3(0, 1.2, (float(k) - 2.0) * 0.38), Vector3(0.28, 0.7, 0.28), b)
