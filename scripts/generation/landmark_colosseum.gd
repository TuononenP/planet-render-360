class_name LandmarkColosseum
extends RefCounted

## The Colosseum in true metres: a 189 x 156 m ellipse, 48 m high.
## The surviving northern outer ring keeps all four storeys — three
## travertine arcades of 80 round-headed bays (Tuscan, Ionic and
## Corinthian half-columns with entablatures) under the windowed attic
## — and steps down at both broken ends into the brick buttress wedges;
## to the south the lower inner ring stands exposed. Inside, the ruined
## cavea of radial brick walls rakes down to the podium, the arena floor
## is partly rebuilt over the open hypogeum maze.

const A := 94.5
const B := 78.0
const BAYS := 80
const TIERS := [[0.0, 10.5], [10.5, 22.3], [22.3, 33.9]]
const ATTIC := [33.9, 48.0]
## Outer ring survives for bay indices in [INTACT_FROM, INTACT_TO)
## (bay 0 points east, indices run toward north at negative Z).
const INTACT_FROM := 21
const INTACT_TO := 59

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C7B79A", 3.0))
	lm.use("InnerRing", LandmarkMaterials.pbr("limestone", "#B9A88C", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94664A", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4E453A", 4.0))
	lm.use("Arena", LandmarkMaterials.pbr("rock", "#9C8667", 5.0))
	lm.use("Floor", LandmarkMaterials.pbr("wood", "#8A6E50", 2.0))
	_outer_ring(lm)
	_inner_ring(lm)
	_cavea(lm)
	_arena(lm)
	lm.commit(model)
	model.rotation.y = deg_to_rad(-18.0)

static func _pt(a: float, b: float, i: float, y: float = 0.0) -> Vector3:
	var t := TAU * i / float(BAYS)
	return Vector3(cos(t) * a, y, -sin(t) * b)

## How many storeys the outer ring keeps at bay i (4 = full height):
## full across the intact north, stepping down at the broken ends.
static func _outer_storeys(i: int) -> int:
	if i < INTACT_FROM or i >= INTACT_TO:
		return 0
	var edge := mini(i - INTACT_FROM, INTACT_TO - 1 - i)
	return mini(4, edge + 1)

static func _outer_ring(lm: LandmarkMesh) -> void:
	for i in BAYS:
		var keep := _outer_storeys(i)
		if keep == 0:
			continue
		var p0 := _pt(A, B, float(i))
		var p1 := _pt(A, B, float(i + 1))
		for t in mini(keep, 3):
			var y0: float = TIERS[t][0]
			var y1: float = TIERS[t][1]
			arch_bay(lm, "Travertine", "Shadow", p0, p1, y0, y1 - y0, 0.62, 0.5, 2.4)
			_order(lm, p0, p1, y0, y1, t)
		if keep == 4:
			_attic(lm, p0, p1, i)
		# Vaulted ambulatory floors behind the arcades read dark.
		var q0 := _pt(A - 11.0, B - 11.0, float(i))
		var q1 := _pt(A - 11.0, B - 11.0, float(i + 1))
		for t in mini(keep, 3):
			var yf: float = TIERS[t][1]
			lm.quad("Shadow", p0 + Vector3(0, yf - 0.6, 0), p1 + Vector3(0, yf - 0.6, 0),
				q1 + Vector3(0, yf - 0.6, 0), q0 + Vector3(0, yf - 0.6, 0), Vector3.DOWN)
	# Brick buttress wedges at both broken ends (Stern 1807, Valadier 1820s).
	for end in [INTACT_FROM, INTACT_TO]:
		var p := _pt(A + 1.0, B + 1.0, float(end))
		var q := _pt(A - 14.0, B - 14.0, float(end))
		var dir := (p - _pt(A + 1.0, B + 1.0, float(end) + (-1.0 if end == INTACT_FROM else 1.0))).normalized()
		var base := p + dir * 9.0
		lm.quad("Brick", p, q, q + Vector3(0, 46.0, 0), p + Vector3(0, 46.0, 0))
		var poly := PackedVector2Array([Vector2(p.x, p.z), Vector2(q.x, q.z),
			Vector2(q.x + dir.x * 9.0, q.z + dir.z * 9.0), Vector2(base.x, base.z)])
		lm.poly_prism("Brick", poly, 0.0, 12.0)
		for k in 3:
			var off := dir * (6.0 - float(k) * 2.0)
			lm.box("Brick", (p + q) * 0.5 + off + Vector3(0, 14.0 + float(k) * 10.0, 0),
				Vector3(3.0, 10.0, 14.0), Basis(Vector3.UP, atan2(dir.x, dir.z) + PI * 0.5))

## Engaged half-column at each pier and the tier's entablature.
static func _order(lm: LandmarkMesh, p0: Vector3, p1: Vector3, y0: float, y1: float, tier: int) -> void:
	var out := Vector3(p0.x / (A * A), 0, p0.z / (B * B)).normalized()
	var col := p0 + out * 0.55
	lm.frustum("Travertine", col + Vector3(0, y0 + 0.4, 0), 0.75, 0.65, y1 - y0 - 2.0, 8)
	lm.box("Travertine", col + Vector3(0, y1 - 1.4, 0), Vector3(1.8, 0.7, 1.8),
		Basis(Vector3.UP, atan2(out.x, out.z)))
	var o1 := Vector3(p1.x / (A * A), 0, p1.z / (B * B)).normalized()
	var band := 1.3 if tier < 2 else 1.6
	lm.beam("Travertine", p0 + out * 0.6 + Vector3(0, y1 - band * 0.5, 0),
		p1 + o1 * 0.6 + Vector3(0, y1 - band * 0.5, 0), band, 1.4, Vector3.UP)

## Attic storey: solid wall, Corinthian pilasters, a window in every
## other bay, consoles for the velarium masts and the crowning cornice.
static func _attic(lm: LandmarkMesh, p0: Vector3, p1: Vector3, i: int) -> void:
	var y0: float = ATTIC[0]
	var y1: float = ATTIC[1]
	var out := Vector3(p0.x / (A * A), 0, p0.z / (B * B)).normalized()
	lm.quad("Travertine", p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0),
		p1 + Vector3(0, y1, 0), p0 + Vector3(0, y1, 0), out)
	var in0 := p0 - out * 2.4
	var in1 := p1 - out * 2.4
	lm.quad("Travertine", in0 + Vector3(0, y0, 0), in1 + Vector3(0, y0, 0),
		in1 + Vector3(0, y1, 0), in0 + Vector3(0, y1, 0), -out)
	lm.quad("Travertine", p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0),
		in1 + Vector3(0, y1, 0), in0 + Vector3(0, y1, 0), Vector3.UP)
	lm.beam("Travertine", p0 + out * 0.3 + Vector3(0, y0 + 6.5, 0),
		p0 + out * 0.3 + Vector3(0, y1 - 1.5, 0), 1.2, 0.6)
	if i % 2 == 0:
		var m := (p0 + p1) * 0.5 + out * 0.05
		lm.box("Shadow", m + Vector3(0, y0 + 4.2, 0), Vector3(2.2, 2.6, 0.1),
			Basis(Vector3.UP, atan2(out.x, out.z)))
	var o1 := Vector3(p1.x / (A * A), 0, p1.z / (B * B)).normalized()
	lm.beam("Travertine", p0 + out * 0.5 + Vector3(0, y1 - 0.6, 0),
		p1 + o1 * 0.5 + Vector3(0, y1 - 0.6, 0), 1.2, 1.4, Vector3.UP)

## A round-headed arcade bay between p0 and p1 (ground points), with
## piers, spandrel, intrados and jambs; `open_frac` of the width open,
## springing at `spring_frac` of the height, `depth` thick (inward).
static func arch_bay(lm: LandmarkMesh, key: String, dark: String, p0: Vector3, p1: Vector3,
		y0: float, h: float, open_frac: float, spring_frac: float, depth: float) -> void:
	var along := (p1 - p0)
	var out := along.cross(Vector3.UP).normalized()
	if out.dot(Vector3(p0.x, 0, p0.z)) < 0.0:
		out = -out
	var inward := -out * depth
	var w := along.length()
	var ow := w * open_frac
	var o0 := p0.lerp(p1, 0.5 - open_frac * 0.5)
	var o1 := p0.lerp(p1, 0.5 + open_frac * 0.5)
	var up := Vector3.UP
	var b := Vector3(0, y0, 0)
	var spring := y0 + h * spring_frac
	var r := minf(ow * 0.5, (y0 + h - spring) * 0.85)
	for face in [Vector3.ZERO, inward]:
		var n: Vector3 = out if face == Vector3.ZERO else -out
		lm.quad(key, p0 + b + face, o0 + b + face, o0 + up * (y0 + h) + face,
			p0 + up * (y0 + h) + face, n)
		lm.quad(key, o1 + b + face, p1 + b + face, p1 + up * (y0 + h) + face,
			o1 + up * (y0 + h) + face, n)
	var seg := 6
	var c := (o0 + o1) * 0.5
	var dir := (o1 - o0).normalized()
	var prev := o0 + up * spring
	for k in range(1, seg + 1):
		var t := PI - PI * float(k) / float(seg)
		var pt := c + dir * cos(t) * (ow * 0.5) + up * (spring + sin(t) * r)
		for face in [Vector3.ZERO, inward]:
			var n: Vector3 = out if face == Vector3.ZERO else -out
			var top_prev := Vector3(prev.x, y0 + h, prev.z)
			var top_pt := Vector3(pt.x, y0 + h, pt.z)
			lm.quad(key, prev + face, pt + face, top_pt + face, top_prev + face, n)
		var mid := (prev + pt) * 0.5
		lm.quad(dark, prev, pt, pt + inward, prev + inward, (c + up * spring - mid).normalized())
		prev = pt
	lm.quad(dark, o0 + b, o0 + up * spring, o0 + up * spring + inward, o0 + b + inward, dir)
	lm.quad(dark, o1 + b, o1 + up * spring, o1 + up * spring + inward, o1 + b + inward, -dir)

## The lower inner ring (2nd ambulatory wall): two arcaded storeys all
## round — the face the city sees where the outer ring has fallen.
static func _inner_ring(lm: LandmarkMesh) -> void:
	for i in BAYS:
		var p0 := _pt(A - 11.0, B - 11.0, float(i))
		var p1 := _pt(A - 11.0, B - 11.0, float(i + 1))
		var tiers := 2 if _outer_storeys(i) == 0 else 3
		for t in tiers:
			var y0: float = TIERS[t][0]
			var y1: float = TIERS[t][1]
			if t == 2:
				y1 = 30.0
			arch_bay(lm, "InnerRing", "Shadow", p0, p1, y0, y1 - y0, 0.56, 0.52, 2.0)
		var top := 22.3 if tiers == 2 else 30.0
		# Ruined crown: ragged brick core along the top of the ring.
		var rag := 1.0 + 2.5 * absf(sin(float(i) * 2.17))
		lm.box("Brick", (p0 + p1) * 0.5 + Vector3(0, top + rag * 0.5, 0),
			Vector3(p0.distance_to(p1), rag, 1.6), Basis(Vector3.UP, atan2(p1.z - p0.z, p0.x - p1.x)))

## Ruined cavea: radial brick walls raking from the inner ring down to
## the podium, with concentric ring walls and a few seating slabs.
static func _cavea(lm: LandmarkMesh) -> void:
	var rings := [[A - 15.0, B - 15.0, 26.0], [A - 26.0, B - 26.0, 18.0],
		[A - 37.0, B - 37.0, 11.0], [A - 48.0, B - 48.0, 4.5]]
	for r in rings:
		for i in BAYS:
			var p0 := _pt(float(r[0]), float(r[1]), float(i))
			var p1 := _pt(float(r[0]), float(r[1]), float(i + 1))
			var h: float = float(r[2]) * (0.7 + 0.3 * absf(sin(float(i) * 1.37 + float(r[2]))))
			var out := (p1 - p0).cross(Vector3.UP).normalized()
			lm.quad("Brick", p0, p1, p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0),
				out if out.dot(p0) > 0.0 else -out)
			lm.quad("Brick", p0, p1, p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0),
				-out if out.dot(p0) > 0.0 else out)
	for i in range(0, BAYS, 2):
		var outer_p := _pt(A - 13.0, B - 13.0, float(i))
		var inner_p := _pt(A - 48.0, B - 48.0, float(i))
		var ruin := 0.55 + 0.45 * absf(sin(float(i) * 0.91))
		var h_out := 28.0 * ruin
		var dir := (outer_p - inner_p)
		var side := dir.cross(Vector3.UP).normalized() * 0.7
		var a := inner_p + Vector3(0, 4.5, 0)
		var b := outer_p + Vector3(0, h_out, 0)
		for s in [side, -side]:
			lm.quad("Brick", inner_p + s, outer_p + s, b + s, a + s, s.normalized())
		lm.quad("Brick", a + side, b + side, b - side, a - side, Vector3.UP)
	# A reconstructed seating sector on the north-west.
	var rows: Array = []
	for k in 6:
		var row := PackedVector3Array()
		var f := float(k) / 5.0
		for i in range(26, 36):
			row.append(_pt(lerpf(A - 48.0, A - 16.0, f), lerpf(B - 48.0, B - 16.0, f),
				float(i), lerpf(5.0, 26.0, f)))
		rows.append(row)
	lm.grid("InnerRing", rows, Vector3.UP)

## Podium wall, open hypogeum maze (raised just above grade so the
## terrain cannot swallow it) and the part-rebuilt arena floor.
static func _arena(lm: LandmarkMesh) -> void:
	var a := 41.5
	var b := 24.0
	var poly := PackedVector2Array()
	for i in BAYS:
		var p := _pt(a + 5.0, b + 5.0, float(i))
		poly.append(Vector2(p.x, p.z))
	poly.reverse()
	lm.poly_prism("Arena", poly, -1.0, 0.4)
	for i in BAYS:
		var p0 := _pt(a + 5.0, b + 5.0, float(i))
		var p1 := _pt(a + 5.0, b + 5.0, float(i + 1))
		var n := (p0 - p1).cross(Vector3.UP).normalized()
		lm.quad("Travertine", p0 + Vector3(0, -1.0, 0), p1 + Vector3(0, -1.0, 0),
			p1 + Vector3(0, 4.5, 0), p0 + Vector3(0, 4.5, 0), -n if n.dot(p0) > 0.0 else n)
	# Hypogeum: long walls parallel to the major axis, cross walls.
	for k in 9:
		var z := -b + 3.0 + float(k) * (2.0 * b - 6.0) / 8.0
		var half := a * sqrt(maxf(1.0 - (z * z) / (b * b), 0.0)) - 3.0
		lm.box("Brick", Vector3(0, 1.4, z), Vector3(half * 2.0, 2.0, 0.9))
	for k in 13:
		var x := -a + 6.0 + float(k) * (2.0 * a - 12.0) / 12.0
		var half := b * sqrt(maxf(1.0 - (x * x) / (a * a), 0.0)) - 3.0
		lm.box("Brick", Vector3(x, 1.2, 0), Vector3(0.8, 1.6, half * 2.0))
	# Rebuilt timber stage over the eastern third.
	lm.box("Floor", Vector3(a * 0.62, 2.6, 0), Vector3(a * 0.62, 0.5, b * 1.5))
