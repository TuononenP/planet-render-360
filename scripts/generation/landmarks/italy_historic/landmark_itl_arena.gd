class_name LandmarkItlArena
extends RefCounted

## The Verona Arena (c. 30 AD) in true metres: the pink and white Verona
## limestone amphitheatre with the surviving "ala" of its outer ring.

const BAYS := 72
const INNER_A := 69.5
const INNER_B := 55.0
const OUTER_A := 76.2
const OUTER_B := 61.7
const FLOOR_A := 38.5
const FLOOR_B := 23.0
const PODIUM := 3.8
const ALA_BAY := 37
const TIERS := [[0.0, 11.2], [11.2, 21.0], [21.0, 29.0]]
## Arch openings of the outer ring per storey: [width share, springing
## share of the storey]; the openings stand 7.10, 6.30 and 4.50 m.
const ALA_ARCH := [[0.62, 0.47], [0.62, 0.45], [0.5, 0.375]]
const SEAT_ROWS := 44

## The Arena built along +X (turn it with yaw_deg onto the real NW-SE
## major axis): the oval of 72 arches of the inner ring (139 x 110 m, two
## arcaded storeys with pilaster strips and keystones, a ragged top)
## round the cavea of 44 rows of stone seats cut by the vomitoria, the
## podium wall with its gates, the sand floor (75.7 x 44.4 m), and the
## "ala": the four bays of the three-storey outer ring (152 x 123 m,
## 31 m) that survive, their rusticated piers, cornices and the ragged
## stumps either side.
static func verona_arena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5B9A1", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6D5C3", 2.5))
	lm.use("Seat", LandmarkMaterials.pbr("limestone", "#C7AF99", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463C34", 3.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#BFA880", 4.0))
	for i in BAYS:
		_inner_bay(lm, i)
		var dist := i - ALA_BAY
		var tiers := 3 if dist >= -2 and dist <= 1 else (2 if dist == -3 or dist == 2 else (1 if dist == -4 or dist == 3
			else 0))
		if tiers > 0:
			_ala_bay(lm, i, tiers)
	_cavea(lm)
	_arena(lm)
	lm.commit(model)

static func _pt(a: float, b: float, i: float, y: float = 0.0) -> Vector3:
	var t := TAU * i / float(BAYS)
	return Vector3(cos(t) * a, y, sin(t) * b)

static func _outward(p: Vector3, a: float, b: float) -> Vector3:
	return Vector3(p.x / (a * a), 0, p.z / (b * b)).normalized()

## Cornice band along a bay edge, offset just outside the wall.
static func _band(lm: LandmarkMesh, p0: Vector3, p1: Vector3, a: float, b: float, y: float, thick: float) -> void:
	var o0 := _outward(p0, a, b) * 0.5
	var o1 := _outward(p1, a, b) * 0.5
	lm.beam("Trim", p0 + o0 + Vector3(0, y, 0), p1 + o1 + Vector3(0, y, 0), thick, 1.3, Vector3.UP)

## One bay of the inner ring: two arcaded storeys, pilaster strips,
## keystones, cornices, then the ragged broken top.
static func _inner_bay(lm: LandmarkMesh, i: int) -> void:
	var p0 := _pt(INNER_A, INNER_B, float(i))
	var p1 := _pt(INNER_A, INNER_B, float(i + 1))
	var mid := (p0 + p1) * 0.5
	var out := _outward(mid, INNER_A, INNER_B)
	var along := (p1 - p0).normalized()
	var basis := Basis(along, Vector3.UP, out)
	var w := p0.distance_to(p1)
	for t in 2:
		var y0: float = TIERS[t][0]
		var y1: float = TIERS[t][1]
		LandmarkColosseum.arch_bay(lm, "Stone", "Shadow", p0, p1, y0, y1 - y0, 0.55, 0.52, 2.2)
		_band(lm, p0, p1, INNER_A, INNER_B, y1 - 0.3, 0.7)
		# Pilaster strip at the bay's start, keystone and impost band.
		lm.box("Stone", p0 + _outward(p0, INNER_A, INNER_B) * 0.2 + Vector3(0, (y0 + y1) * 0.5 - 0.3, 0),
			Vector3(1.1, y1 - y0 - 0.6, 0.4), basis)
		var ow := w * 0.55
		var spring := y0 + (y1 - y0) * 0.52
		var r := minf(ow * 0.5, (y1 - spring) * 0.85)
		lm.box("Trim", mid + out * 0.15 + Vector3(0, spring + r + 0.15, 0), Vector3(0.6, 0.9, 0.3), basis)
		for s in [-1.0, 1.0]:
			lm.box("Trim", mid + along * float(s) * (ow * 0.5 + 0.3) + out * 0.1 + Vector3(0, spring - 0.15, 0),
				Vector3(0.7, 0.3, 0.2), basis, 0.0)
	var rag := 0.5 + 2.6 * absf(sin(float(i) * 2.31))
	lm.box("Stone", mid + Vector3(0, TIERS[1][1] + rag * 0.5, 0), Vector3(w, rag, 1.8), basis)
	if rag > 1.8:
		var r2 := rag * 0.4
		lm.box("Stone", mid + along * w * 0.2 + Vector3(0, TIERS[1][1] + rag + r2 * 0.5, 0), Vector3(w * 0.5, r2, 1.4),
			basis)

## One bay of the outer ring with `tiers` storeys: rusticated piers,
## arches of the right height per storey, cornices, the vault floors
## linking it to the inner ring.
static func _ala_bay(lm: LandmarkMesh, i: int, tiers: int) -> void:
	var p0 := _pt(OUTER_A, OUTER_B, float(i))
	var p1 := _pt(OUTER_A, OUTER_B, float(i + 1))
	var q0 := _pt(INNER_A, INNER_B, float(i))
	var q1 := _pt(INNER_A, INNER_B, float(i + 1))
	var o0 := _outward(p0, OUTER_A, OUTER_B)
	var along := (p1 - p0).normalized()
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP).normalized() * signf(along.cross(Vector3.UP).dot(o0)))
	for t in tiers:
		var y0: float = TIERS[t][0]
		var y1: float = TIERS[t][1]
		LandmarkColosseum.arch_bay(lm, "Stone", "Shadow", p0, p1, y0, y1 - y0, ALA_ARCH[t][0], ALA_ARCH[t][1], 2.6)
		_band(lm, p0, p1, OUTER_A, OUTER_B, y1 - 0.3, 0.8)
		lm.quad("Shadow", p0 + Vector3(0, y1 - 0.7, 0), p1 + Vector3(0, y1 - 0.7, 0),
			q1 + Vector3(0, y1 - 0.7, 0), q0 + Vector3(0, y1 - 0.7, 0), Vector3.DOWN)
		# Rusticated pier at the bay's start; the last full bay closes with one.
		LandmarkItlParts.rustic_pier(lm, "Stone", p0 + o0 * 0.05 + Vector3(0, y0, 0), along, o0, 1.7, y1 - y0 - 0.9, 0.62,
			0.3)
		if i == ALA_BAY + 1 or tiers < 3:
			var o1 := _outward(p1, OUTER_A, OUTER_B)
			LandmarkItlParts.rustic_pier(lm, "Stone", p1 + o1 * 0.05 + Vector3(0, y0, 0), along, o1, 1.7, y1 - y0 - 0.9,
				0.62, 0.3)
		# Voussoir keystone over the arch.
		var w := p0.distance_to(p1)
		var ow := w * float(ALA_ARCH[t][0])
		var spring := y0 + (y1 - y0) * float(ALA_ARCH[t][1])
		var r := minf(ow * 0.5, (y1 - spring) * 0.85)
		var mid := (p0 + p1) * 0.5
		lm.box("Trim", mid + o0 * 0.2 + Vector3(0, spring + r + 0.2, 0), Vector3(0.7, 1.0, 0.4), basis)
	if tiers == 3:
		_band(lm, p0, p1, OUTER_A, OUTER_B, 30.0, 2.0)
	else:
		var rag := 1.0 + 1.6 * absf(sin(float(i) * 1.9))
		var y: float = TIERS[tiers - 1][1]
		lm.box("Stone", (p0 + p1) * 0.5 + Vector3(0, y + rag * 0.5, 0), Vector3(p0.distance_to(p1) * 0.7, rag, 2.2), basis)

## Raked cavea: 44 rows of stepped seats from the podium up to the inner
## ring, with the vomitoria opening in the rows.
static func _cavea(lm: LandmarkMesh) -> void:
	var a1 := 67.2
	var b1 := 52.8
	var rise := 17.4
	for k in SEAT_ROWS:
		var f0 := float(k) / float(SEAT_ROWS)
		var f1 := float(k + 1) / float(SEAT_ROWS)
		var y0 := PODIUM + rise * f0
		var y1 := PODIUM + rise * f1
		var ra0 := lerpf(FLOOR_A, a1, f0)
		var rb0 := lerpf(FLOOR_B, b1, f0)
		var ra1 := lerpf(FLOOR_A, a1, f1)
		var rb1 := lerpf(FLOOR_B, b1, f1)
		for i in BAYS:
			var p0 := _pt(ra0, rb0, float(i))
			var p1 := _pt(ra0, rb0, float(i + 1))
			var n0 := -_outward(p0, ra0, rb0)
			var vom := (k == 14 or k == 15 or k == 29 or k == 30) and i % 9 == (0 if k < 20 else 4)
			lm.quad("Shadow" if vom else "Seat", p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0), p1 + Vector3(0, y1, 0),
				p0 + Vector3(0, y1, 0), n0)
			var u0 := _pt(ra1, rb1, float(i))
			var u1 := _pt(ra1, rb1, float(i + 1))
			lm.quad("Seat", p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0), u1 + Vector3(0, y1, 0),
				u0 + Vector3(0, y1, 0), Vector3.UP)
	# Vomitoria mouths: framed openings on the rake.
	for k in [14, 29]:
		var f := float(k) / float(SEAT_ROWS)
		var ra := lerpf(FLOOR_A, a1, f)
		var rb := lerpf(FLOOR_B, b1, f)
		for i in BAYS:
			if i % 9 != (0 if k < 20 else 4):
				continue
			var p0 := _pt(ra, rb, float(i))
			var p1 := _pt(ra, rb, float(i + 1))
			var n0 := -_outward(p0, ra, rb)
			var y := PODIUM + rise * f
			var basis := Basis((p1 - p0).normalized(), Vector3.UP, n0)
			for e in [p0, p1]:
				lm.box("Trim", (e as Vector3) + Vector3(0, y + 0.6, 0) - n0 * 0.3, Vector3(0.4, 1.2, 1.2), basis, 0.0)

## Podium wall with its cornice and gates, and the sand floor.
static func _arena(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array()
	for i in BAYS:
		var p := _pt(FLOOR_A, FLOOR_B, float(i))
		poly.append(Vector2(p.x, p.z))
	poly.reverse()
	lm.poly_prism("Sand", poly, 0.0, 0.15)
	for i in BAYS:
		var p0 := _pt(FLOOR_A, FLOOR_B, float(i))
		var p1 := _pt(FLOOR_A, FLOOR_B, float(i + 1))
		var n := -_outward(p0, FLOOR_A, FLOOR_B)
		var gate := i == 0 or i == BAYS / 2
		lm.quad("Shadow" if gate else "Trim", p0 + Vector3(0, 0.15, 0), p1 + Vector3(0, 0.15, 0),
			p1 + Vector3(0, PODIUM, 0), p0 + Vector3(0, PODIUM, 0), n)
		lm.beam("Trim", p0 + n * 0.2 + Vector3(0, PODIUM - 0.15, 0), p1 + n * 0.2 + Vector3(0, PODIUM - 0.15, 0), 0.3, 0.6,
			Vector3.UP)
		if gate:
			var basis := Basis((p1 - p0).normalized(), Vector3.UP, n)
			LandmarkDetail.arch(lm, "Trim", (p0 + p1) * 0.5 + Vector3(0, 1.4, 0), n, p0.distance_to(p1) * 0.9, 0.35, 0.3)
			lm.box("Trim", (p0 + p1) * 0.5 + n * 0.1 + Vector3(0, PODIUM + 0.4, 0), Vector3(p0.distance_to(p1), 0.8, 0.4),
				basis)
