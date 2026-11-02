class_name LandmarkItlAncient
extends RefCounted

## Roman ruins of northern and southern Italy in true metres: the Forum
## of Pompeii and the Verona Arena with its surviving "ala".

# --- Forum of Pompeii -----------------------------------------------------

const FORUM_HX := 19.0
const FORUM_HZ := 70.0

## Origin at the middle of the forum, the Temple of Jupiter at the north
## (-Z) head facing the square (+Z). The ruins as they stand: the 142 x 38 m
## travertine-paved square between the Doric colonnades of the west, east
## and south sides (columns stand ~5 m, most of the upper gallery gone),
## the roofless brick-and-stucco shells of the basilica, Eumachia and
## the Macellum behind them, the temple podium with its stair, cella
## walls and broken portico columns, and the two brick-cored honorific
## arches flanking it (the tallest remains, 10.6 m).
static func pompeii_forum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pave", LandmarkMaterials.pbr("limestone", "#BDB5A3", 4.0))
	lm.use("Col", LandmarkMaterials.pbr("limestone", "#CFC3A8", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9B5A3C", 2.5))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#B98B5E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463C32", 3.0))
	lm.box("Pave", Vector3(0, -0.32, 0), Vector3(FORUM_HX * 2.0 + 14.0, 0.8, FORUM_HZ * 2.0 + 4.0))
	# Colonnades on three sides: Doric columns and a broken architrave.
	for s in [-1.0, 1.0]:
		var x: float = s * 17.2
		SEuUtil.column_row(lm, "Col", Vector3(x, 0, -44.0), Vector3(x, 0, 66.0), 37, 4.8, 0.42, 10)
		for i in 36:
			if i % 7 != 3:
				var z0 := -44.0 + 110.0 * float(i) / 36.0
				lm.beam("Col", Vector3(x, 5.1, z0), Vector3(x, 5.1, z0 + 110.0 / 36.0), 0.9, 0.8, Vector3.RIGHT)
	SEuUtil.column_row(lm, "Col", Vector3(-17.2, 0, 66.0), Vector3(17.2, 0, 66.0), 13, 4.8, 0.42, 10)
	for i in 12:
		var x0 := -17.2 + 34.4 * float(i) / 12.0
		if i % 5 != 2:
			lm.beam("Col", Vector3(x0, 5.1, 66.0), Vector3(x0 + 34.4 / 12.0, 5.1, 66.0), 0.9, 0.8, Vector3.UP)
	# Ruined buildings behind the colonnades.
	LandmarkItlUtil.ruin_ring(lm, "Brick", Vector3(-35.0, 0, 44.0), 24.0, 52.0, 10.0, 1.6, 1.0)
	LandmarkItlUtil.ruin_ring(lm, "Stucco", Vector3(35.0, 0, 44.0), 24.0, 30.0, 7.0, 1.2, 2.0)
	LandmarkItlUtil.ruin_ring(lm, "Brick", Vector3(35.0, 0, -10.0), 22.0, 36.0, 8.0, 1.4, 3.0)
	LandmarkItlUtil.ruin_ring(lm, "Stucco", Vector3(-35.0, 0, -14.0), 22.0, 32.0, 6.5, 1.2, 4.0)
	LandmarkItlUtil.ruin_ring(lm, "Brick", Vector3(-35.0, 0, -50.0), 22.0, 18.0, 5.5, 1.4, 5.0)
	LandmarkItlUtil.ruin_ring(lm, "Stucco", Vector3(35.0, 0, -50.0), 22.0, 18.0, 5.5, 1.4, 6.0)
	# Temple of Jupiter: podium, stair, cella walls and portico stumps.
	lm.box("Pave", Vector3(0, 1.7, -63.5), Vector3(17.4, 3.4, 23.0))
	lm.box("Col", Vector3(0, 3.55, -63.5), Vector3(18.2, 0.3, 23.8))
	SEuUtil.steps_up(lm, "Col", Vector3(0, 0, -52.0), Vector3(0, 0, 1), 8.0, 0.55, 0.42, 8)
	lm.box("Brick", Vector3(-5.8, 6.4, -67.0), Vector3(1.6, 6.0, 14.0))
	lm.box("Brick", Vector3(5.8, 5.8, -67.0), Vector3(1.6, 4.8, 14.0))
	lm.box("Brick", Vector3(0, 6.6, -74.2), Vector3(11.0, 6.4, 1.6))
	lm.box("Brick", Vector3(-4.2, 5.7, -59.4), Vector3(2.8, 4.6, 1.6))
	lm.box("Brick", Vector3(4.2, 5.4, -59.4), Vector3(2.8, 4.0, 1.6))
	var heights := [7.0, 3.0, 5.4, 2.2, 6.2, 3.6]
	for row in 2:
		for i in 6:
			var h: float = heights[(i + row * 3) % 6] - float(row) * 0.8
			lm.frustum("Col", Vector3(-7.5 + 3.0 * float(i), 3.55, -54.0 - 3.6 * float(row)), 0.55, 0.45, h, 12)
	# The two arches beside the temple.
	for s in [-1.0, 1.0]:
		var ax: float = s * 15.0
		LandmarkColosseum.arch_bay(lm, "Brick", "Shadow", Vector3(ax - 4.0, 0, -58.0), Vector3(ax + 4.0, 0, -58.0),
			0.0, 10.6, 0.46, 0.58, 3.6)
	lm.commit(model)

# --- Verona Arena -----------------------------------------------------------

const BAYS := 72
const INNER_A := 69.5
const INNER_B := 55.0
const OUTER_A := 76.2
const OUTER_B := 61.7
const ALA_BAY := 37
const TIERS := [[0.0, 11.2], [11.2, 21.0], [21.0, 29.0]]

## The Arena in true metres, built along +X (turn it with yaw_deg onto
## the real NW-SE major axis): the oval of 72 rusticated arches, the
## pink Verona limestone inner ring (139 x 110 m, two arcaded storeys
## and a ragged top) round a raked cavea of stepped seats, and the "ala"
## -- the only surviving stretch of the three-storey outer ring (152 x 123 m,
## 31 m high), five bays wide at full height, stepping down at both ends.
static func verona_arena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5B9A1", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6D5C3", 2.5))
	lm.use("Seat", LandmarkMaterials.pbr("limestone", "#C7AF99", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463C34", 3.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#BFA880", 4.0))
	for i in BAYS:
		var p0 := _pt(INNER_A, INNER_B, float(i))
		var p1 := _pt(INNER_A, INNER_B, float(i + 1))
		for t in 2:
			var y0: float = TIERS[t][0]
			var y1: float = TIERS[t][1]
			LandmarkColosseum.arch_bay(lm, "Stone", "Shadow", p0, p1, y0, y1 - y0, 0.55, 0.52, 2.2)
			_band(lm, p0, p1, INNER_A, INNER_B, y1 - 0.3, 0.7)
		# Ragged broken top of the inner ring.
		var rag := 0.5 + 2.6 * absf(sin(float(i) * 2.31))
		lm.box("Stone", (p0 + p1) * 0.5 + Vector3(0, TIERS[1][1] + rag * 0.5, 0),
			Vector3(p0.distance_to(p1), rag, 1.8), Basis(Vector3.UP, atan2(p1.z - p0.z, p0.x - p1.x)))
		var dist := absi(i - ALA_BAY)
		var tiers := 3 if dist <= 2 else (2 if dist == 3 else (1 if dist == 4 else 0))
		if tiers > 0:
			_ala_bay(lm, i, tiers)
	_cavea(lm)
	_arena(lm)
	lm.commit(model)

static func _pt(a: float, b: float, i: float, y: float = 0.0) -> Vector3:
	var t := TAU * i / float(BAYS)
	return Vector3(cos(t) * a, y, sin(t) * b)

## Cornice band along a bay edge, offset just outside the wall.
static func _band(lm: LandmarkMesh, p0: Vector3, p1: Vector3, a: float, b: float, y: float, thick: float) -> void:
	var o0 := Vector3(p0.x / (a * a), 0, p0.z / (b * b)).normalized() * 0.5
	var o1 := Vector3(p1.x / (a * a), 0, p1.z / (b * b)).normalized() * 0.5
	lm.beam("Trim", p0 + o0 + Vector3(0, y, 0), p1 + o1 + Vector3(0, y, 0), thick, 1.3, Vector3.UP)

## One bay of the outer ring with `tiers` storeys, its cornice and the
## vault floors linking it to the inner ring.
static func _ala_bay(lm: LandmarkMesh, i: int, tiers: int) -> void:
	var p0 := _pt(OUTER_A, OUTER_B, float(i))
	var p1 := _pt(OUTER_A, OUTER_B, float(i + 1))
	var q0 := _pt(INNER_A, INNER_B, float(i))
	var q1 := _pt(INNER_A, INNER_B, float(i + 1))
	for t in tiers:
		var y0: float = TIERS[t][0]
		var y1: float = TIERS[t][1]
		LandmarkColosseum.arch_bay(lm, "Stone", "Shadow", p0, p1, y0, y1 - y0, 0.58, 0.55, 2.6)
		_band(lm, p0, p1, OUTER_A, OUTER_B, y1 - 0.3, 0.8)
		lm.quad("Shadow", p0 + Vector3(0, y1 - 0.7, 0), p1 + Vector3(0, y1 - 0.7, 0),
			q1 + Vector3(0, y1 - 0.7, 0), q0 + Vector3(0, y1 - 0.7, 0), Vector3.DOWN)
	if tiers == 3:
		_band(lm, p0, p1, OUTER_A, OUTER_B, 30.0, 2.0)

## Raked cavea: stepped seats from the podium up to the inner ring.
static func _cavea(lm: LandmarkMesh) -> void:
	var steps := 14
	var a0 := 38.5
	var b0 := 23.0
	var a1 := 67.2
	var b1 := 52.8
	for k in steps:
		var f0 := float(k) / float(steps)
		var f1 := float(k + 1) / float(steps)
		var y0 := 3.8 + 17.4 * f0
		var y1 := 3.8 + 17.4 * f1
		var ra0 := lerpf(a0, a1, f0)
		var rb0 := lerpf(b0, b1, f0)
		var ra1 := lerpf(a0, a1, f1)
		var rb1 := lerpf(b0, b1, f1)
		for i in BAYS:
			var p0 := _pt(ra0, rb0, float(i))
			var p1 := _pt(ra0, rb0, float(i + 1))
			var n0 := Vector3(-p0.x / (ra0 * ra0), 0, -p0.z / (rb0 * rb0)).normalized()
			lm.quad("Seat", p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0), p1 + Vector3(0, y1, 0),
				p0 + Vector3(0, y1, 0), n0)
			var u0 := _pt(ra1, rb1, float(i))
			var u1 := _pt(ra1, rb1, float(i + 1))
			lm.quad("Seat", p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0), u1 + Vector3(0, y1, 0),
				u0 + Vector3(0, y1, 0), Vector3.UP)

## Podium wall and the sand floor of the arena.
static func _arena(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array()
	for i in BAYS:
		var p := _pt(38.5, 23.0, float(i))
		poly.append(Vector2(p.x, p.z))
	poly.reverse()
	lm.poly_prism("Sand", poly, -1.0, 0.15)
	for i in BAYS:
		var p0 := _pt(38.5, 23.0, float(i))
		var p1 := _pt(38.5, 23.0, float(i + 1))
		var n := Vector3(-p0.x / (38.5 * 38.5), 0, -p0.z / (23.0 * 23.0)).normalized()
		lm.quad("Trim", p0 + Vector3(0, -0.5, 0), p1 + Vector3(0, -0.5, 0), p1 + Vector3(0, 3.8, 0),
			p0 + Vector3(0, 3.8, 0), n)
