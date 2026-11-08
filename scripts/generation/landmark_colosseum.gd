class_name LandmarkColosseum
extends RefCounted

## The Colosseum in true metres: a 189 x 156 m ellipse, 48 m high, laid out
## from the OSM outline of the ruin (relation 1834818): the long axis runs
## 107.5 deg from north, and the surviving outer wall is the NORTH half,
## parametric angles 2-168 deg from the east end of the long axis. It keeps
## all four storeys between two cut faces (11.5 and 168.2 deg, 34 bays) —
## three travertine arcades of 80 round-headed bays, each arch under a
## moulded archivolt and keystone springing from impost blocks, framed by
## engaged half-columns (Tuscan, Ionic and Corinthian, with their capitals)
## and a three-part entablature per storey, the upper two with a waist-high
## sill across each opening — under the attic with its Corinthian pilasters,
## small windows in alternate bays and three corbels per bay that carried the
## velarium masts. At both ends the wall breaks off: the cut shows the
## concrete core with rubble on top, two lower storeys continue beyond it and
## a sloping brick wedge (Stern's 1807 buttress in the east, 13 m deep;
## Valadier's of 1826 in the west, a thinner hooked plan, both as mapped)
## shores up the full-height end. To the south the lower inner ring — a
## closed 163 x 125 m ellipse, 13 m inside the outer wall — stands exposed,
## three arcades high and ragged along its crown. Inside, the ruined cavea of
## radial brick walls rakes down to the podium, the arena floor is partly
## rebuilt over the open hypogeum maze. Stone colours are sampled from a
## photograph: warm tan travertine, darker where stained, near-black arches.

const A := 94.5
const B := 78.0
const BAYS := 80
const TIERS := [[0.0, 10.5], [10.5, 22.3], [22.3, 33.9]]
const ATTIC := [33.9, 48.0]
## Outer face of the inner ring, fitted to the OSM outline (semi-axes).
const IA := 81.5
const IB := 62.5
## Outer ring survives for bay indices in [INTACT_FROM, INTACT_TO)
## (bay 0 points to the east end of the long axis, indices run through
## north at negative Z to the west end at bay 40).
const INTACT_FROM := 1
const INTACT_TO := 39
## Boundary indices where the full-height wall starts (east) and ends (west):
## OSM puts its cut faces at parametric 11.5 and 168.2 deg. Bays outside
## them, to INTACT_FROM / INTACT_TO, are the two-storey footing of the
## buttress wedges.
const EAST_FACE := 3
const WEST_FACE := 37
## Footprint of the west (Valadier, 1826) buttress as mapped in OSM, as
## [share of the outer ellipse, parametric angle in deg]: the cut face, the
## hooked inner edge, then back along the outer face.
const WEST_PLAN := [[0.982, 168.2], [0.937, 168.2], [0.902, 168.4], [0.899, 172.3],
	[0.897, 176.1], [0.852, 176.6], [0.982, 176.6], [0.982, 172.3]]
## Surviving entrance numbers on the north ground storey (OSM / the park:
## XXIII to LIV), carved 34 cm high; bays NUM_FROM.. take 23, 24, ...
const NUM_FROM := 4
const NUM_FIRST := 23
const NUM_COUNT := 32
## Local +X is the long axis: 107.5 deg from north (OSM), so -17.5 about Y.
const YAW_DEG := -17.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#B39577", 3.0))
	lm.use("TravertineLight", LandmarkMaterials.pbr("limestone", "#C9AE92", 3.0))
	lm.use("TravertineDark", LandmarkMaterials.pbr("limestone", "#927760", 3.0))
	lm.use("InnerRing", LandmarkMaterials.pbr("limestone", "#A08568", 3.0))
	lm.use("InnerRingDark", LandmarkMaterials.pbr("limestone", "#826A55", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6E57", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#7A5644", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#85705F", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#2A211E", 4.0))
	lm.use("Arena", LandmarkMaterials.pbr("rock", "#9C8667", 5.0))
	lm.use("Floor", LandmarkMaterials.pbr("wood", "#8A6E50", 2.0))
	_outer_ring(lm)
	_inner_ring(lm)
	_cavea(lm)
	_arena(lm)
	lm.commit(model)
	model.rotation.y = deg_to_rad(YAW_DEG)

static func _pt(a: float, b: float, i: float, y: float = 0.0) -> Vector3:
	var t := TAU * i / float(BAYS)
	return Vector3(cos(t) * a, y, -sin(t) * b)

## Deterministic 0..1 noise for bay i (stains, ragged edges).
static func _h(i: float, salt: float) -> float:
	return fposmod(sin(i * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

## Floor and roof height (x, y) of storey t: the three arcades, then the attic.
static func _tier_y(t: int) -> Vector2:
	var r: Array = TIERS[t] if t < 3 else ATTIC
	return Vector2(float(r[0]), float(r[1]))

## Outward unit normal of the ellipse (a, b) at p.
static func _out_at(p: Vector3, a: float, b: float) -> Vector3:
	return Vector3(p.x / (a * a), 0, p.z / (b * b)).normalized()

## Basis whose X axis runs along p0 -> p1 (boxes laid along a wall).
static func _along(p0: Vector3, p1: Vector3) -> Basis:
	return Basis(Vector3.UP, atan2(-(p1.z - p0.z), p1.x - p0.x))

## Stone of the outer wall at bay i, storey t: mostly the base tan, some
## bays paler (cleaned) and some darker (stained), as on the real wall.
static func _trav(i: int, t: int) -> String:
	var r := _h(float(i), 11.0 + float(t))
	if r < 0.2:
		return "TravertineLight"
	if r > 0.78:
		return "TravertineDark"
	return "Travertine"

static func _ikey(i: int, t: int) -> String:
	return "InnerRingDark" if _h(float(i), 21.0 + float(t)) > 0.65 else "InnerRing"

## How many storeys the outer ring keeps at bay i (4 = full height): full
## between the two cut faces, and two storeys (the wedges' footing) for the
## bays beyond them.
static func _outer_storeys(i: int) -> int:
	if i < INTACT_FROM or i >= INTACT_TO:
		return 0
	if i >= EAST_FACE and i < WEST_FACE:
		return 4
	if i == INTACT_FROM:
		return 2 if _h(float(i), 5.0) > 0.4 else 1
	return 2

static func _outer_ring(lm: LandmarkMesh) -> void:
	for i in BAYS:
		var keep := _outer_storeys(i)
		if keep == 0:
			continue
		var p0 := _pt(A, B, float(i))
		var p1 := _pt(A, B, float(i + 1))
		var q0 := _pt(IA, IB, float(i))
		var q1 := _pt(IA, IB, float(i + 1))
		for t in mini(keep, 3):
			var ty := _tier_y(t)
			var tk := _trav(i, t)
			arch_bay(lm, tk, "Shadow", p0, p1, ty.x, ty.y - ty.x, 0.62, 0.5, 2.4)
			_order(lm, p0, p1, ty.x, ty.y, t, tk)
			# Vaulted ambulatory floors behind the arcades read dark.
			var yf := ty.y - 0.6
			lm.quad("Shadow", p0 + Vector3(0, yf, 0), p1 + Vector3(0, yf, 0),
				q1 + Vector3(0, yf, 0), q0 + Vector3(0, yf, 0), Vector3.DOWN)
			if t == 0 and i >= NUM_FROM and i < NUM_FROM + NUM_COUNT:
				_numeral(lm, p0, p1, NUM_FIRST + i - NUM_FROM)
		# Two travertine steps round the foot of the standing wall.
		var o0 := _out_at(p0, A, B)
		var o1 := _out_at(p1, A, B)
		lm.beam("Travertine", p0 + o0 * 2.0 + Vector3(0, 0.25, 0), p1 + o1 * 2.0 + Vector3(0, 0.25, 0),
			0.5, 3.0, Vector3.UP)
		lm.beam("Travertine", p0 + o0 * 3.8 + Vector3(0, 0.1, 0), p1 + o1 * 3.8 + Vector3(0, 0.1, 0),
			0.2, 3.0, Vector3.UP)
		if keep == 4:
			_attic(lm, p0, p1, i)
		else:
			# The broken top: rubble over the concrete core of the last storey.
			_rubble(lm, A, B, i, _tier_y(keep - 1).y, 5.0, 31.0)
	_breaks(lm)
	_buttress(lm)
	_west_buttress(lm)

## A lump of core masonry on top of a broken wall at bay i of ring (a, b).
static func _rubble(lm: LandmarkMesh, a: float, b: float, i: int, y: float,
		depth: float, salt: float) -> void:
	var p0 := _pt(a, b, float(i))
	var p1 := _pt(a, b, float(i + 1))
	var mid := (p0 + p1) * 0.5
	var out := _out_at(mid, a, b)
	var h := 0.7 + _h(float(i), salt) * 2.6
	var key := "BrickDark" if _h(float(i), salt + 3.0) > 0.6 else "Concrete"
	lm.box(key, mid - out * depth * 0.5 + Vector3(0, y + h * 0.5, 0),
		Vector3(p0.distance_to(p1) * 0.9, h, depth), _along(p0, p1), 0.0)

## Where a storey ends beside a lower bay, the wall is cut off: show the
## concrete core across the wall's full depth, from the outer face to the
## inner ring, for every storey the neighbour has lost.
static func _breaks(lm: LandmarkMesh) -> void:
	for i in range(INTACT_FROM, INTACT_TO):
		var keep := _outer_storeys(i)
		var p0 := _pt(A, B, float(i))
		var p1 := _pt(A, B, float(i + 1))
		var q0 := _pt(IA, IB, float(i))
		var q1 := _pt(IA, IB, float(i + 1))
		for side: int in [-1, 1]:
			var nk := _outer_storeys(i + side)
			if nk >= keep:
				continue
			var pe := p0 if side < 0 else p1
			var qe := q0 if side < 0 else q1
			var tang := (p1 - p0).normalized() * float(side)
			for t in range(nk, keep):
				var ty := _tier_y(t)
				lm.quad("Concrete", pe + Vector3(0, ty.x, 0), qe + Vector3(0, ty.x, 0),
					qe + Vector3(0, ty.y, 0), pe + Vector3(0, ty.y, 0), tang)

## One triangle with a metre-scale UV (the winding follows the normal).
static func _tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3,
		n: Vector3) -> void:
	lm.tri(key, a, b, c, n, n, n, Vector2(a.x + a.z, a.y), Vector2(b.x + b.z, b.y),
		Vector2(c.x + c.z, c.y))

## The sloping brick wedge at the east end of the full-height wall (Stern,
## 1807): it stands on the two-storey bays beside the cut face, as wide as the
## wall is deep (13 m, to the inner ring), and falls from the attic line to the
## roof of the second storey over two bays.
static func _buttress(lm: LandmarkMesh) -> void:
	var face_i := EAST_FACE
	var pe := _pt(A + 0.4, B + 0.4, float(face_i))
	var qe := _pt(IA + 1.0, IB + 1.0, float(face_i))
	var pn := _pt(A + 0.4, B + 0.4, float(face_i) - 1.0)
	var tw := (pn - pe).normalized()
	var yb: float = TIERS[1][1]
	var yt := 45.0
	var reach := pe.distance_to(pn) * 2.0
	var up := Vector3.UP
	var pe1 := pe + tw * reach
	var qe1 := qe + tw * reach
	var slope_n := (qe1 - pe1).cross(up * (yt - yb) - tw * reach).normalized()
	if slope_n.dot(up + tw) < 0.0:
		slope_n = -slope_n
	lm.quad("Brick", pe1 + up * yb, qe1 + up * yb, qe + up * yt, pe + up * yt, slope_n)
	var out_n := (pe - qe).normalized()
	_tri(lm, "Brick", pe + up * yb, pe1 + up * yb, pe + up * yt, out_n)
	_tri(lm, "Brick", qe + up * yb, qe1 + up * yb, qe + up * yt, -out_n)
	# A dark masonry cap along the crest and a broken edge down the slope.
	lm.box("BrickDark", (pe + qe) * 0.5 + up * (yt + 0.6),
		Vector3(pe.distance_to(qe) * 0.92, 1.2, 2.4), _along(qe, pe), 0.0)
	for k in 4:
		var f := (float(k) + 0.5) / 4.0
		var c := (pe + qe) * 0.5 + tw * (reach * f) + up * (lerpf(yt, yb, f) + 0.35)
		lm.box("BrickDark", c, Vector3(pe.distance_to(qe) * (0.5 + 0.12 * float(k % 2)), 0.7, 1.6),
			_along(qe, pe), 0.0)

## The west buttress (Valadier, 1826) on the mapped footprint (WEST_PLAN): a
## thinner wedge with a hooked inner edge, its top falling from the attic line
## at the cut face to the second storey's roof at the far end. The plan is
## turned 1.7 deg so its cut face meets the end of the full-height bay.
static func _west_buttress(lm: LandmarkMesh) -> void:
	var shift := 168.2 - 4.5 * float(WEST_FACE)
	var poly := PackedVector2Array()
	var heights := PackedFloat32Array()
	var yb: float = TIERS[1][1]
	for r in WEST_PLAN:
		var t_deg: float = float(r[1]) - shift
		var p := _pt(A * float(r[0]), B * float(r[0]), t_deg / 4.5)
		poly.append(Vector2(p.x, p.z))
		heights.append(lerpf(45.0, yb, clampf((float(r[1]) - 168.2) / 8.4, 0.0, 1.0)))
	var area := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		area += a.x * b.y - b.x * a.y
	# Sides: a quad per edge up to the sloping top.
	for i in poly.size():
		var j := (i + 1) % poly.size()
		var e := poly[j] - poly[i]
		var n := Vector3(e.y, 0, -e.x).normalized() * (1.0 if area > 0.0 else -1.0)
		lm.quad("Brick", Vector3(poly[i].x, yb, poly[i].y), Vector3(poly[j].x, yb, poly[j].y),
			Vector3(poly[j].x, heights[j], poly[j].y), Vector3(poly[i].x, heights[i], poly[i].y), n)
	# Sloping top, triangulated from the plan with each corner at its height.
	var idx := Geometry2D.triangulate_polygon(poly)
	for k in range(0, idx.size(), 3):
		var v: Array[Vector3] = []
		for m in 3:
			var q := poly[idx[k + m]]
			v.append(Vector3(q.x, heights[idx[k + m]], q.y))
		var n := (v[1] - v[0]).cross(v[2] - v[0]).normalized()
		if n.y < 0.0:
			n = -n
		_tri(lm, "Brick", v[0], v[1], v[2], n)
	# Dark cap along the cut-face crest.
	var c0 := Vector3(poly[0].x, heights[0], poly[0].y)
	var c1 := Vector3(poly[2].x, heights[2], poly[2].y)
	lm.box("BrickDark", (c0 + c1) * 0.5 + Vector3(0, 0.6, 0),
		Vector3(c0.distance_to(c1) * 0.95, 1.2, 2.2), _along(c0, c1), 0.0)

## Roman numeral `n` carved 34 cm high on the frieze above a ground-storey
## arch, centred on the bay (the surviving entrances are numbered XXIII-LIV).
static func _numeral(lm: LandmarkMesh, p0: Vector3, p1: Vector3, n: int) -> void:
	var text := ""
	var rest := n
	for pair in [[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while rest >= int(pair[0]):
			text += str(pair[1])
			rest -= int(pair[0])
	var mid := (p0 + p1) * 0.5
	var out := _out_at(mid, A, B)
	var dir := (p1 - p0).normalized()
	var h := 0.34
	var adv := 0.34
	var x := -adv * float(text.length()) * 0.5
	for ch in text:
		for seg in _glyph(ch):
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			var pa := mid + out * 0.1 + dir * (x + a.x * 0.24) + Vector3(0, 8.55 + a.y * h, 0)
			var pb := mid + out * 0.1 + dir * (x + b.x * 0.24) + Vector3(0, 8.55 + b.y * h, 0)
			lm.beam("TravertineDark", pa, pb, 0.05, 0.04, out)
		x += adv

## Stroke segments of a Roman numeral glyph in a unit box (x right, y up).
static func _glyph(ch: String) -> Array:
	match ch:
		"I":
			return [[Vector2(0.5, 0), Vector2(0.5, 1)]]
		"V":
			return [[Vector2(0, 1), Vector2(0.5, 0)], [Vector2(1, 1), Vector2(0.5, 0)]]
		"X":
			return [[Vector2(0, 1), Vector2(1, 0)], [Vector2(0, 0), Vector2(1, 1)]]
		"L":
			return [[Vector2(0, 1), Vector2(0, 0)], [Vector2(0, 0), Vector2(1, 0)]]
	return []

## Engaged half-column at each pier (base, shaft, the tier's capital),
## the impost blocks and moulded archivolt of the bay's arch, and the
## tier's entablature: architrave, frieze and projecting cornice. `tk` is
## the stone surface key of the bay.
static func _order(lm: LandmarkMesh, p0: Vector3, p1: Vector3, y0: float, y1: float, tier: int,
		tk: String = "Travertine") -> void:
	var out := Vector3(p0.x / (A * A), 0, p0.z / (B * B)).normalized()
	var o1 := Vector3(p1.x / (A * A), 0, p1.z / (B * B)).normalized()
	var face := Basis(Vector3.UP, atan2(out.x, out.z))
	var col := p0 + out * 0.55
	var ent := 1.3 if tier < 2 else 1.6
	var ch := y1 - y0 - ent
	# Pedestal-plinth and Attic base (Ionic and Corinthian storeys).
	var base_h := 0.0 if tier == 0 else 0.9
	if tier > 0:
		lm.box(tk, col + Vector3(0, y0 + 0.45, 0), Vector3(1.9, 0.9, 1.9), face)
	lm.lathe(tk, col + Vector3(0, y0 + base_h, 0), PackedVector2Array([Vector2(0.85, 0),
		Vector2(0.88, 0.15), Vector2(0.76, 0.32), Vector2(0.72, 0.45)]), 12)
	var sh := ch - 1.1 - base_h
	lm.lathe(tk, col + Vector3(0, y0 + base_h + 0.45, 0), PackedVector2Array([Vector2(0.72, 0),
		Vector2(0.71, sh * 0.35), Vector2(0.66, sh * 0.75), Vector2(0.62, sh - 0.45)]), 12)
	var cb := col + Vector3(0, y0 + base_h + sh, 0)
	match tier:
		0:
			# Tuscan: necking, echinus, square abacus.
			lm.frustum(tk, cb, 0.64, 0.64, 0.25, 12)
			lm.lathe(tk, cb + Vector3(0, 0.25, 0), PackedVector2Array([Vector2(0.64, 0),
				Vector2(0.8, 0.2), Vector2(0.88, 0.4)]), 12)
			lm.box(tk, cb + Vector3(0, 0.75, 0), Vector3(1.85, 0.45, 1.85), face)
		1:
			# Ionic: echinus, the volute pair and abacus.
			lm.frustum(tk, cb, 0.66, 0.72, 0.3, 12)
			for sv in [-1.0, 1.0]:
				var side := face * Vector3(float(sv) * 0.72, 0, 0)
				lm.disc(tk, cb + side + Vector3(0, 0.5, 0) + face * Vector3(0, 0, 0.56), out, 0.3, 10)
				lm.beam(tk, cb + side + Vector3(0, 0.5, 0) - face * Vector3(0, 0, 0.55),
					cb + side + Vector3(0, 0.5, 0) + face * Vector3(0, 0, 0.55), 0.55, 0.5)
			lm.box(tk, cb + Vector3(0, 0.88, 0), Vector3(1.9, 0.3, 1.6), face)
		_:
			# Corinthian: bell with two tiers of leaves, corner volutes,
			# concave abacus.
			lm.lathe(tk, cb, PackedVector2Array([Vector2(0.62, 0), Vector2(0.64, 0.5),
				Vector2(0.76, 0.95)]), 12)
			for row in 2:
				for i in 6:
					var a := TAU * (float(i) + 0.5 * float(row)) / 6.0
					var d := Vector3(cos(a), 0, sin(a))
					lm.beam(tk, cb + d * 0.6 + Vector3(0, 0.05 + 0.35 * float(row), 0),
						cb + d * 0.82 + Vector3(0, 0.45 + 0.35 * float(row), 0), 0.28, 0.08, d.cross(Vector3.UP))
			for i in 4:
				var a := TAU * (float(i) + 0.5) / 4.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.beam(tk, cb + d * 0.6 + Vector3(0, 0.6, 0), cb + d * 1.0 + Vector3(0, 0.98, 0), 0.14)
			lm.box(tk, cb + Vector3(0, 1.05, 0), Vector3(1.95, 0.2, 1.95), face)
	# Impost blocks and the archivolt round the arch.
	var along := p1 - p0
	var w := along.length()
	var dir := along / w
	var ow := w * 0.62
	var spring := y0 + (y1 - y0) * 0.5
	var r := minf(ow * 0.5, (y1 - spring) * 0.85)
	var c := (p0 + p1) * 0.5 + out * 0.15
	for sv in [-1.0, 1.0]:
		lm.box(tk, c + dir * float(sv) * (ow * 0.5 + 0.1) + Vector3(0, spring - 0.15, 0),
			Vector3(0.7, 0.35, 0.45), face)
	var prev := c - dir * (ow * 0.5 + 0.25) + Vector3(0, spring, 0)
	for k in range(1, 9):
		var t := PI - PI * float(k) / 8.0
		var q := c + dir * cos(t) * (ow * 0.5 + 0.25) + Vector3(0, spring + sin(t) * (r + 0.25), 0)
		lm.beam(tk, prev, q, 0.45, 0.3, out)
		prev = q
	# Keystone at the crown, and above the ground storey a waist-high sill
	# across the opening (the upper arches are windows, not doorways).
	lm.box(tk, c + out * 0.1 + Vector3(0, spring + r + 0.3, 0), Vector3(0.7, 1.0, 0.55), face, 0.0)
	if tier > 0:
		lm.box(tk, (p0 + p1) * 0.5 + out * 0.2 + Vector3(0, y0 + 0.55, 0),
			Vector3(ow + 0.4, 1.1, 0.5), _along(p0, p1), 0.0)
	# Entablature: architrave, frieze, cornice (projecting, moulded).
	var e0 := p0 + Vector3(0, y1 - ent, 0)
	var e1 := p1 + Vector3(0, y1 - ent, 0)
	lm.beam(tk, e0 + out * 0.5 + Vector3(0, ent * 0.17, 0), e1 + o1 * 0.5 + Vector3(0, ent * 0.17, 0),
		ent * 0.34, 1.2, Vector3.UP)
	lm.beam(tk, e0 + out * 0.4 + Vector3(0, ent * 0.5, 0), e1 + o1 * 0.4 + Vector3(0, ent * 0.5, 0),
		ent * 0.32, 1.0, Vector3.UP)
	LandmarkDetail.cornice(lm, tk, e0 + out * 0.9 + Vector3(0, ent * 0.66, 0),
		e1 + o1 * 0.9 + Vector3(0, ent * 0.66, 0), (out + o1).normalized(), ent * 0.34, false)

## Attic storey: solid wall, Corinthian pilasters, a window in every
## other bay, consoles for the velarium masts and the crowning cornice.
static func _attic(lm: LandmarkMesh, p0: Vector3, p1: Vector3, i: int) -> void:
	var y0: float = ATTIC[0]
	var y1: float = ATTIC[1]
	var tk := _trav(i, 3)
	var out := Vector3(p0.x / (A * A), 0, p0.z / (B * B)).normalized()
	lm.quad(tk, p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0),
		p1 + Vector3(0, y1, 0), p0 + Vector3(0, y1, 0), out)
	var in0 := p0 - out * 2.4
	var in1 := p1 - out * 2.4
	lm.quad(tk, in0 + Vector3(0, y0, 0), in1 + Vector3(0, y0, 0),
		in1 + Vector3(0, y1, 0), in0 + Vector3(0, y1, 0), -out)
	lm.quad(tk, p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0),
		in1 + Vector3(0, y1, 0), in0 + Vector3(0, y1, 0), Vector3.UP)
	var face := Basis(Vector3.UP, atan2(out.x, out.z))
	# Plinth course, Corinthian pilaster with base and capital.
	lm.beam(tk, p0 + out * 0.2 + Vector3(0, y0 + 0.6, 0), p1 + out * 0.2 + Vector3(0, y0 + 0.6, 0),
		1.2, 0.4, Vector3.UP)
	lm.box(tk, p0 + out * 0.3 + Vector3(0, y0 + 1.6, 0), Vector3(1.5, 0.8, 0.6), face)
	lm.beam(tk, p0 + out * 0.3 + Vector3(0, y0 + 2.0, 0),
		p0 + out * 0.3 + Vector3(0, y1 - 3.2, 0), 1.2, 0.6)
	lm.box(tk, p0 + out * 0.38 + Vector3(0, y1 - 2.7, 0), Vector3(1.5, 1.0, 0.75), face)
	for k in 3:
		lm.box(tk, p0 + out * 0.62 + Vector3(-0.0, y1 - 3.0 + 0.3 * float(k), 0),
			Vector3(1.25 + 0.08 * float(k), 0.22, 0.2), face, 0.0)
	# Three corbels per bay that carried the velarium masts.
	for k in 3:
		var cp := p0.lerp(p1, (float(k) + 0.5) / 3.0) + out * 0.35
		lm.box(tk, cp + Vector3(0, y0 + 2.2, 0), Vector3(0.7, 0.9, 0.8), face)
	if i % 2 == 0:
		# Small window: a real opening through the attic wall.
		var m := (p0 + p1) * 0.5
		var dirb := (p1 - p0).normalized()
		var hw := 1.1
		var wy0 := y0 + 4.6
		var wy1 := wy0 + 2.8
		var inb := -out * 2.4
		for sv in [-1.0, 1.0]:
			var e := m + dirb * float(sv) * hw
			lm.quad("Shadow", e + Vector3(0, wy0, 0) + out * 0.02, e + Vector3(0, wy1, 0) + out * 0.02,
				e + Vector3(0, wy1, 0) + inb, e + Vector3(0, wy0, 0) + inb, -dirb * float(sv))
		lm.quad("Shadow", m - dirb * hw + Vector3(0, wy0, 0) + out * 0.02, m + dirb * hw + Vector3(0, wy0, 0) + out * 0.02,
			m + dirb * hw + Vector3(0, wy0, 0) + inb, m - dirb * hw + Vector3(0, wy0, 0) + inb, Vector3.UP)
		lm.quad("Shadow", m - dirb * hw + Vector3(0, wy1, 0) + out * 0.02, m + dirb * hw + Vector3(0, wy1, 0) + out * 0.02,
			m + dirb * hw + Vector3(0, wy1, 0) + inb, m - dirb * hw + Vector3(0, wy1, 0) + inb, Vector3.DOWN)
		lm.box("Shadow", m + Vector3(0, (wy0 + wy1) * 0.5, 0) + out * 0.03, Vector3(2.2, 2.8, 0.06), face, 0.0)
		lm.box(tk, m + Vector3(0, wy0 - 0.15, 0) + out * 0.25, Vector3(2.8, 0.3, 0.5), face, 0.0)
	var o1 := Vector3(p1.x / (A * A), 0, p1.z / (B * B)).normalized()
	lm.beam(tk, p0 + out * 0.5 + Vector3(0, y1 - 0.6, 0),
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

## How high the inner ring stands at bay i: full height behind the standing
## outer wall, and in the south (bay 60) lower and ragged, rising toward the
## break ends where it meets the outer wall again, in broken chunks of three
## bays.
static func _inner_top(i: int) -> float:
	if _outer_storeys(i) >= 2:
		return 30.0
	var d := absf(fposmod(float(i) - 60.0 + 40.0, 80.0) - 40.0)
	var base := lerpf(23.5, 31.5, clampf(d / 22.0, 0.0, 1.0))
	var chunk := floorf(float(i) / 3.0)
	return maxf(22.8, base + (_h(chunk, 8.0) - 0.5) * 7.0)

## The lower inner ring (2nd ambulatory wall): three arcaded storeys, the
## face the city sees where the outer ring has fallen, ragged along the crown
## where its upper arcade is gone.
static func _inner_ring(lm: LandmarkMesh) -> void:
	for i in BAYS:
		var p0 := _pt(IA, IB, float(i))
		var p1 := _pt(IA, IB, float(i + 1))
		var top := _inner_top(i)
		var tiers := 3 if top >= 29.0 else 2
		for t in tiers:
			var y0: float = TIERS[t][0]
			var y1: float = TIERS[t][1]
			if t == 2:
				y1 = 30.0
			arch_bay(lm, _ikey(i, t), "Shadow", p0, p1, y0, y1 - y0, 0.56, 0.52, 2.0)
		var base_y := 30.0 if tiers == 3 else 22.3
		var lump := top - base_y if tiers == 2 else 0.4 + 1.8 * _h(float(i), 9.0)
		var mid := (p0 + p1) * 0.5
		var out := _out_at(mid, IA, IB)
		var key := "BrickDark" if _h(float(i), 12.0) > 0.55 else "Concrete"
		lm.box(key, mid - out * 1.0 + Vector3(0, base_y + lump * 0.5, 0),
			Vector3(p0.distance_to(p1) * 0.95, lump, 2.2), _along(p0, p1), 0.0)

## Ruined cavea: radial brick walls raking from the inner ring down to
## the podium, with concentric ring walls and a few seating slabs.
static func _cavea(lm: LandmarkMesh) -> void:
	var rings := [[IA - 3.0, IB - 3.0, 28.0], [IA - 13.0, IB - 11.0, 21.0],
		[IA - 23.0, IB - 19.0, 14.0], [IA - 33.0, IB - 27.0, 8.0]]
	for k in rings.size():
		var r: Array = rings[k]
		var ra: float = r[0]
		var rb: float = r[1]
		var rh: float = r[2]
		for i in BAYS:
			var p0 := _pt(ra, rb, float(i))
			var p1 := _pt(ra, rb, float(i + 1))
			var h := rh * (0.6 + 0.4 * _h(float(i), rh)) * _ruin(i, 0.55)
			var out := (p1 - p0).cross(Vector3.UP).normalized()
			if out.dot(p0) < 0.0:
				out = -out
			var low := 0.0
			# The two outer ring walls are brick arcades (the vaulted
			# corridors under the seating); the inner two are solid.
			if k < 2 and h >= 11.0:
				low = 9.0
				arch_bay(lm, "Brick", "Shadow", p0, p1, 0.0, low, 0.5, 0.55, 1.6)
			lm.quad("Brick", p0 + Vector3(0, low, 0), p1 + Vector3(0, low, 0),
				p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0), out)
			lm.quad("Brick", p0 + Vector3(0, low, 0), p1 + Vector3(0, low, 0),
				p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0), -out)
	# Radial walls: stepped, as the seating's concrete vault remains stand.
	var steps := 6
	for i in range(0, BAYS, 2):
		var outer_p := _pt(IA - 2.0, IB - 2.0, float(i))
		var inner_p := _pt(IA - 33.0, IB - 27.0, float(i))
		var h_out := 28.0 * (0.55 + 0.45 * _h(float(i), 4.0)) * _ruin(i, 0.45)
		var dir := (outer_p - inner_p)
		var len := dir.length()
		var basis := _along(inner_p, outer_p)
		for st in steps:
			var f0 := float(st) / float(steps)
			var f1 := float(st + 1) / float(steps)
			var top := lerpf(4.5, h_out, f1) * (0.85 + 0.3 * _h(float(i * 7 + st), 6.0))
			var c := inner_p + dir * ((f0 + f1) * 0.5)
			lm.box("Brick", c + Vector3(0, top * 0.5, 0), Vector3(len / float(steps) * 1.02, top, 1.4), basis, 0.0)
	# A reconstructed seating sector on the north-west.
	var rows: Array = []
	for k in 6:
		var row := PackedVector3Array()
		var f := float(k) / 5.0
		for i in range(26, 36):
			row.append(_pt(lerpf(IA - 33.0, IA - 3.0, f), lerpf(IB - 27.0, IB - 3.0, f),
				float(i), lerpf(4.5, 28.0, f)))
		rows.append(row)
	lm.grid("InnerRing", rows, Vector3.UP)

## How much of a cavea wall at bay i survives: whole behind the standing
## north wall, down to `floor` in the south where the outer wall is gone.
static func _ruin(i: int, floor_f: float) -> float:
	var south := clampf(1.0 - absf(fposmod(float(i) - 60.0 + 40.0, 80.0) - 40.0) / 24.0, 0.0, 1.0)
	return lerpf(1.0, floor_f + 0.35 * _h(float(i), 14.0), south)

## Podium wall, open hypogeum maze (raised just above grade so the
## terrain cannot swallow it: nothing is sunk below y = 0) and the
## part-rebuilt arena floor.
static func _arena(lm: LandmarkMesh) -> void:
	var a := 41.5
	var b := 24.0
	var poly := PackedVector2Array()
	for i in BAYS:
		var p := _pt(a + 5.0, b + 5.0, float(i))
		poly.append(Vector2(p.x, p.z))
	poly.reverse()
	lm.poly_prism("Arena", poly, 0.0, 0.4)
	for i in BAYS:
		var p0 := _pt(a + 5.0, b + 5.0, float(i))
		var p1 := _pt(a + 5.0, b + 5.0, float(i + 1))
		var n := (p0 - p1).cross(Vector3.UP).normalized()
		lm.quad("Travertine", p0, p1,
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
