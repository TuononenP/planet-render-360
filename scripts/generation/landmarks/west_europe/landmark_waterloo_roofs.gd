class_name LandmarkWaterlooRoofs
extends RefCounted

## Waterloo's roofs (LandmarkWaterloo builds the rest): the 1922
## ridge-and-furrow roof over platforms 1-19, lofted between its curved
## west edge and the Station Approach wall so its ridges fan with the
## tracks; the flat concourse roof with its lanterns; and Grimshaw's
## 1993 international shed over platforms 20-24, a tapering asymmetric
## arch glazed on its west side and clad in steel on its east, its blue
## trusses outside the skin.

const D := preload("res://scripts/generation/landmarks/west_europe/landmark_waterloo_data.gd")

## Main roof: ridges across, segments along, gutter and ridge levels.
const SPANS := 16
const ALONG := 10
const VALLEY_Y := 15.0
const RIDGE_Y := 19.5
## Each slope from gutter to ridge: lead, glazing, lead.
const SLOPE_BANDS := [0.0, 0.22, 0.82, 1.0]
## Concourse roof: top level and the lanterns' offsets from the main
## roof's back edge (metres, into the concourse).
const FLAT_Y := 16.0
const LANTERNS := [6.0, 15.0, 24.0, 33.0]
## International shed: stations along, the cross-section's samples
## (0 = west edge, 1 = east) with the apex at APEX_S, and the rise over
## the platforms as a share of the span within its limits.
const INTL_ALONG := 64
const INTL_S := [0.0, 0.04, 0.09, 0.15, 0.21, 0.28, 0.36, 0.45, 0.55, 0.65, 0.75, 0.85, 0.93, 1.0]
const APEX_S := 0.28
const APEX_I := 5
const RISE_SHARE := 0.3
const RISE_MIN := 10.0
const RISE_MAX := 17.0
## The steel side's glazed band (between these samples).
const BAND_S := [0.55, 0.65]

## `n` + 1 points at even arc length along `line`.
static func resample(line: PackedVector2Array, n: int) -> PackedVector2Array:
	var cum := PackedFloat32Array([0.0])
	for i in range(1, line.size()):
		cum.append(cum[i - 1] + line[i - 1].distance_to(line[i]))
	var total := cum[cum.size() - 1]
	var out := PackedVector2Array()
	var seg := 0
	for k in n + 1:
		var d := total * float(k) / float(n)
		while seg < line.size() - 2 and cum[seg + 1] < d:
			seg += 1
		var span := maxf(cum[seg + 1] - cum[seg], 0.001)
		out.append(line[seg].lerp(line[seg + 1], clampf((d - cum[seg]) / span, 0.0, 1.0)))
	return out

## A quad facing upward.
static func _quad_up(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n := (b - a).cross(d - a).normalized()
	if n.y < 0.0:
		n = -n
	lm.quad(key, a, b, c, d, n)

## The main roof: ridge-and-furrow bays lofted between MAIN_LEFT and
## MAIN_RIGHT, glazed gable screens at both ends over lattice girders,
## gutters, ridge rolls, and the brick screen wall on Station Approach.
static func main_shed(lm: LandmarkMesh) -> void:
	var a := resample(D.MAIN_LEFT, ALONG)
	var b := resample(D.MAIN_RIGHT, ALONG)
	var at := func(u: float, j: int, y: float) -> Vector3:
		return D.v3(a[j].lerp(b[j], u), y)
	for i in SPANS:
		var u0 := float(i) / float(SPANS)
		var u1 := float(i + 1) / float(SPANS)
		var um := (u0 + u1) * 0.5
		for j in ALONG:
			for side in [u0, u1]:
				var us: float = side
				for s in SLOPE_BANDS.size() - 1:
					var t0: float = SLOPE_BANDS[s]
					var t1: float = SLOPE_BANDS[s + 1]
					var key := "Glass" if s == 1 else "Lead"
					var ua := lerpf(us, um, t0)
					var ub := lerpf(us, um, t1)
					var ya := lerpf(VALLEY_Y, RIDGE_Y, t0)
					var yb := lerpf(VALLEY_Y, RIDGE_Y, t1)
					_quad_up(lm, key, at.call(ua, j, ya), at.call(ub, j, yb), at.call(ub, j + 1, yb), at.call(ua, j + 1, ya))
			lm.beam("Lead", at.call(um, j, RIDGE_Y + 0.08), at.call(um, j + 1, RIDGE_Y + 0.08), 0.45, 0.25)
		for j in [0, ALONG]:
			_gable_screen(lm, at.call(u0, j, VALLEY_Y), at.call(u1, j, VALLEY_Y), at.call(um, j, RIDGE_Y),
				_end_out(a, b, j))
	for i in SPANS + 1:
		var u := float(i) / float(SPANS)
		lm.beam("Iron", at.call(u, 0, VALLEY_Y), at.call(u, ALONG, VALLEY_Y), 0.6, 0.35)
	for j in [0, ALONG]:
		lm.beam("Iron", at.call(0.0, j, VALLEY_Y - 0.7), at.call(1.0, j, VALLEY_Y - 0.7), 0.5, 1.4)
	_east_wall(lm, b, a)

## Outward horizontal normal at end row `j` of a lofted roof.
static func _end_out(a: PackedVector2Array, b: PackedVector2Array, j: int) -> Vector3:
	var e := b[j] - a[j]
	var n := Vector2(e.y, -e.x).normalized()
	var inner := (a[1] + b[1]) * 0.5 if j == 0 else (a[j - 1] + b[j - 1]) * 0.5
	if n.dot(inner - (a[j] + b[j]) * 0.5) > 0.0:
		n = -n
	return Vector3(n.x, 0, n.y)

## A glazed gable screen p0-p1-top with its iron frame and bars.
static func _gable_screen(lm: LandmarkMesh, p0: Vector3, p1: Vector3, top: Vector3, out: Vector3) -> void:
	lm.tri("Glass", p0, p1, top, out, out, out, Vector2.ZERO, Vector2(p0.distance_to(p1), 0), Vector2(0, 4))
	var o := out * 0.08
	lm.beam("Iron", p0 + o, top + o, 0.25, 0.2)
	lm.beam("Iron", p1 + o, top + o, 0.25, 0.2)
	for k in [0.25, 0.5, 0.75]:
		var t: float = k
		var foot := p0.lerp(p1, t)
		var head := p0.lerp(top, t * 2.0) if t <= 0.5 else top.lerp(p1, t * 2.0 - 1.0)
		lm.beam("Iron", foot + o, head + o, 0.12, 0.1)

## The brick screen wall on Station Approach under the roof's east
## edge: tall round-headed windows, a stone coping.
static func _east_wall(lm: LandmarkMesh, b: PackedVector2Array, a: PackedVector2Array) -> void:
	var p := b[0]
	var q := b[b.size() - 1]
	var dir := (q - p).normalized()
	var n := Vector2(dir.y, -dir.x)
	if n.dot((a[0] + a[a.size() - 1]) * 0.5 - (p + q) * 0.5) > 0.0:
		n = -n
	var out := Vector3(n.x, 0, n.y)
	var right := Vector3(dir.x, 0, dir.y)
	var w := p.distance_to(q)
	var h := VALLEY_Y - D.TRACK_Y
	lm.quad("Brick", D.v3(p, D.TRACK_Y), D.v3(q, D.TRACK_Y), D.v3(q, VALLEY_Y), D.v3(p, VALLEY_Y), -out)
	var cols := int(w / 7.0)
	LandmarkDetail.pierced_face(lm, "Brick", "Glass", D.v3(p, D.TRACK_Y), right, out, w, h, cols, 1,
		Vector2(3.0, 5.0), 3.6, 8.0, 0.4)
	var pitch := w / float(cols)
	for k in cols:
		var c := D.v3(p + dir * pitch * (float(k) + 0.5), D.TRACK_Y + 8.6) + out * 0.42
		LandmarkDetail.arch(lm, "Stone", c, out, 3.0, 0.4, 0.2, 12)
	LandmarkDetail.cornice(lm, "Stone", D.v3(p, VALLEY_Y - 0.6) + out * 0.4, D.v3(q, VALLEY_Y - 0.6) + out * 0.4,
		out, 0.6, false)

## The concourse roof behind the office range, glazed lanterns along
## it, and its outer wall on York Road.
static func concourse(lm: LandmarkMesh) -> void:
	lm.poly_prism("Lead", D.CONCOURSE, FLAT_Y - 0.8, FLAT_Y)
	var bl := D.MAIN_LEFT[0]
	var br := D.MAIN_RIGHT[0]
	var dir := (br - bl).normalized()
	var north := Vector2(dir.y, -dir.x)
	if north.y > 0.0:
		north = -north
	for off in LANTERNS:
		var c := bl + north * float(off)
		var strip := PackedVector2Array([c - dir * 200.0 - north * 1.6, c + dir * 300.0 - north * 1.6,
			c + dir * 300.0 + north * 1.6, c - dir * 200.0 + north * 1.6])
		for piece in Geometry2D.intersect_polygons(D.CONCOURSE, strip):
			var poly: PackedVector2Array = piece
			var inset := Geometry2D.offset_polygon(poly, -0.6)
			if not inset.is_empty():
				lm.poly_prism("Glass", inset[0], FLAT_Y, FLAT_Y + 1.1)
	for i in 2:
		var p := D.CONCOURSE[i]
		var q := D.CONCOURSE[i + 1]
		var o := D.outward(p, q, D.CONCOURSE)
		var out := Vector3(o.x, 0, o.y)
		var w := p.distance_to(q)
		var r := (q - p).normalized()
		lm.quad("Stone", D.v3(p, D.TRACK_Y), D.v3(q, D.TRACK_Y), D.v3(q, FLAT_Y - 0.8), D.v3(p, FLAT_Y - 0.8), out)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", D.v3(p, D.TRACK_Y), Vector3(r.x, 0, r.y), out, w,
			FLAT_Y - 0.8 - D.TRACK_Y, maxi(int(w / 3.6), 1), 3, Vector2(1.5, 2.4), 2.6, 3.6, 0.3)

## The cross-section height at `s` across a span `w` wide.
static func _intl_y(s: float, w: float) -> float:
	var rise := clampf(RISE_SHARE * w, RISE_MIN, RISE_MAX)
	var east := VALLEY_Y - D.PLAT_Y
	if s <= APEX_S:
		return D.PLAT_Y + rise * sin(PI * 0.5 * s / APEX_S)
	var t := (s - APEX_S) / (1.0 - APEX_S)
	return D.PLAT_Y + rise - (rise - east) * t * t

## Grimshaw's shed: the lofted skin, blue bowstring trusses outside its
## steel side every other station, mullions and bars on its glass side,
## glazed end screens, and the walls closing its sides.
static func international(lm: LandmarkMesh) -> void:
	var l := resample(D.INTL_LEFT, INTL_ALONG)
	var r := resample(D.INTL_RIGHT, INTL_ALONG)
	var ns := INTL_S.size()
	var pts: Array = []
	var along := PackedFloat32Array([0.0])
	for k in INTL_ALONG + 1:
		var row := PackedVector3Array()
		var w := l[k].distance_to(r[k])
		for m in ns:
			var s: float = INTL_S[m]
			row.append(D.v3(l[k].lerp(r[k], s), _intl_y(s, w)))
		pts.append(row)
		if k > 0:
			along.append(along[k - 1] + ((l[k] + r[k]) * 0.5).distance_to((l[k - 1] + r[k - 1]) * 0.5))
	var norms := _skin_normals(pts, l, r)
	for k in INTL_ALONG:
		var r0: PackedVector3Array = pts[k]
		var r1: PackedVector3Array = pts[k + 1]
		var n0: PackedVector3Array = norms[k]
		var n1: PackedVector3Array = norms[k + 1]
		for m in ns - 1:
			var mid := (float(INTL_S[m]) + float(INTL_S[m + 1])) * 0.5
			var key := "Glass" if mid < APEX_S or (mid > float(BAND_S[0]) and mid < float(BAND_S[1])) else "Steel"
			var ua := Vector2(r0[m].distance_to(r0[0]), -along[k])
			var ub := Vector2(r0[m + 1].distance_to(r0[0]), -along[k])
			var uc := Vector2(r1[m + 1].distance_to(r1[0]), -along[k + 1])
			var ud := Vector2(r1[m].distance_to(r1[0]), -along[k + 1])
			lm.tri(key, r0[m], r0[m + 1], r1[m + 1], n0[m], n0[m + 1], n1[m + 1], ua, ub, uc)
			lm.tri(key, r0[m], r1[m + 1], r1[m], n0[m], n1[m + 1], n1[m], ua, uc, ud)
	for k in INTL_ALONG + 1:
		var row: PackedVector3Array = pts[k]
		var nrm: PackedVector3Array = norms[k]
		if k % 2 == 0:
			_truss(lm, row, nrm)
		for m in APEX_I:
			lm.beam("Blue", row[m] + nrm[m] * 0.15, row[m + 1] + nrm[m + 1] * 0.15, 0.22, 0.22)
	for m in range(1, APEX_I):
		for k in INTL_ALONG:
			var p0: PackedVector3Array = pts[k]
			var p1: PackedVector3Array = pts[k + 1]
			var q0: PackedVector3Array = norms[k]
			var q1: PackedVector3Array = norms[k + 1]
			lm.beam("Iron", p0[m] + q0[m] * 0.1, p1[m] + q1[m] * 0.1, 0.12, 0.12)
	_end_screen(lm, pts[0] as PackedVector3Array, l, r, 0)
	_end_screen(lm, pts[INTL_ALONG] as PackedVector3Array, l, r, INTL_ALONG)
	_intl_walls(lm, pts, l, r)

## Per-vertex normals of the skin, turned away from the shed's axis.
static func _skin_normals(pts: Array, l: PackedVector2Array, r: PackedVector2Array) -> Array:
	var out: Array = []
	var nk := pts.size()
	for k in nk:
		var row: PackedVector3Array = pts[k]
		var prev: PackedVector3Array = pts[maxi(k - 1, 0)]
		var next: PackedVector3Array = pts[mini(k + 1, nk - 1)]
		var axis := D.v3((l[k] + r[k]) * 0.5, D.PLAT_Y)
		var nrm := PackedVector3Array()
		for m in row.size():
			var across := row[mini(m + 1, row.size() - 1)] - row[maxi(m - 1, 0)]
			var n := across.cross(next[m] - prev[m]).normalized()
			if n.dot(row[m] - axis) < 0.0:
				n = -n
			nrm.append(n)
		out.append(nrm)
	return out

## One blue bowstring truss outside the steel side: a tubular chord
## standing off the skin, posts and diagonals down to it.
static func _truss(lm: LandmarkMesh, row: PackedVector3Array, nrm: PackedVector3Array) -> void:
	var chord := PackedVector3Array()
	for m in range(APEX_I, row.size()):
		var stand := 1.4 * sin(PI * float(m - APEX_I) / float(row.size() - 1 - APEX_I)) + 0.3
		chord.append(row[m] + nrm[m] * stand)
	for i in chord.size() - 1:
		var m := APEX_I + i
		lm.beam("Blue", chord[i], chord[i + 1], 0.45, 0.45)
		lm.beam("Blue", row[m] + nrm[m] * 0.1, chord[i], 0.2, 0.2)
		lm.beam("Blue", row[m + 1] + nrm[m + 1] * 0.1, chord[i], 0.16, 0.16)

## A glazed end screen under the shed's profile, framed in blue.
static func _end_screen(lm: LandmarkMesh, row: PackedVector3Array, l: PackedVector2Array,
		r: PackedVector2Array, k: int) -> void:
	var out := _end_out(l, r, k)
	var foot := D.v3(r[k], D.PLAT_Y)
	var poly := PackedVector2Array()
	var origin := row[0]
	var across := (row[row.size() - 1] - row[0])
	across.y = 0.0
	var ax := across.normalized()
	for p in row:
		poly.append(Vector2((p - origin).dot(ax), p.y))
	poly.append(Vector2((foot - origin).dot(ax), D.PLAT_Y))
	var idx := Geometry2D.triangulate_polygon(poly)
	var to3 := func(q: Vector2) -> Vector3:
		return origin + ax * q.x + Vector3(0, q.y - origin.y, 0) + out * 0.05
	for t in range(0, idx.size(), 3):
		lm.tri("Glass", to3.call(poly[idx[t]]), to3.call(poly[idx[t + 1]]), to3.call(poly[idx[t + 2]]), out, out, out,
			poly[idx[t]], poly[idx[t + 1]], poly[idx[t + 2]])
	for m in row.size() - 1:
		lm.beam("Blue", row[m] + out * 0.1, row[m + 1] + out * 0.1, 0.4, 0.4)
	for m in range(1, row.size() - 1, 2):
		lm.beam("Blue", Vector3(row[m].x, D.PLAT_Y, row[m].z) + out * 0.1, row[m] + out * 0.1, 0.25, 0.25)

## The shed's side walls: a brick plinth under the west glazing up to
## the platforms, and a steel-clad wall on the east past the main roof.
static func _intl_walls(lm: LandmarkMesh, pts: Array, l: PackedVector2Array, r: PackedVector2Array) -> void:
	var main_end := D.MAIN_LEFT[D.MAIN_LEFT.size() - 1].y
	for k in INTL_ALONG:
		var west := Vector3(l[k].x - r[k].x, 0, l[k].y - r[k].y).normalized()
		lm.quad("Brick", D.v3(l[k], D.TRACK_Y), D.v3(l[k + 1], D.TRACK_Y), D.v3(l[k + 1], D.PLAT_Y + 0.05),
			D.v3(l[k], D.PLAT_Y + 0.05), west)
		if r[k].y < main_end:
			continue
		var row0: PackedVector3Array = pts[k]
		var row1: PackedVector3Array = pts[k + 1]
		var top0 := row0[row0.size() - 1].y
		var top1 := row1[row1.size() - 1].y
		lm.quad("Steel", D.v3(r[k], D.TRACK_Y), D.v3(r[k + 1], D.TRACK_Y), D.v3(r[k + 1], top1), D.v3(r[k], top0), -west)
