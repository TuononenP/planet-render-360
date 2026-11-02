class_name LandmarkNaParts
extends RefCounted

## Small pieces shared by the North America landmark builders, in true
## metres on LandmarkMesh.

## Rows x cols of window boxes on a wall. `c` is the wall's centre at
## ground level, `r` turns the local +Z (outward) onto the wall normal.
static func windows(lm: LandmarkMesh, key: String, c: Vector3, r: Basis, span: float,
		y0: float, y1: float, rows: int, cols: int, size: Vector2, out: float = 0.1) -> void:
	for j in rows:
		var y := y0 + (y1 - y0) * (float(j) + 0.5) / float(rows)
		for i in cols:
			var x := -span * 0.5 + span * (float(i) + 0.5) / float(cols)
			lm.box(key, c + r * Vector3(x, y, out), Vector3(size.x, size.y, 0.25), r)

## `n` tapered columns from `a` to `b` (base points), each `h` tall.
static func columns(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, r0: float,
		r1: float, h: float, seg: int = 10) -> void:
	for i in n:
		var t: float = 0.5 if n == 1 else float(i) / float(n - 1)
		lm.frustum(key, a.lerp(b, t), r0, r1, h, seg)

## Hipped roof with a flat top (k of the eave size) over an hx x hz eave
## rectangle at `c`, turned by `r`.
static func hip(lm: LandmarkMesh, key: String, c: Vector3, r: Basis, hx: float, hz: float,
		k: float, rise: float) -> void:
	var eave: Array[Vector3] = []
	var top: Array[Vector3] = []
	for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var v: Vector2 = q
		eave.append(c + r * Vector3(v.x * hx, 0, v.y * hz))
		top.append(c + r * Vector3(v.x * hx * k, rise, v.y * hz * k))
	for i in 4:
		var j := (i + 1) % 4
		var n := (eave[j] - eave[i]).cross(top[i] - eave[i]).normalized()
		var mid := (eave[i] + eave[j]) * 0.5 - c
		if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
			n = -n
		lm.quad(key, eave[i], eave[j], top[j], top[i], n)
	lm.quad(key, top[0], top[1], top[2], top[3], Vector3.UP)

## Flat triangle facing away from `inside`.
static func flat_tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3,
		inside: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.dot((a + b + c) / 3.0 - inside) < 0.0:
		n = -n
	lm.tri(key, a, b, c, n, n, n, Vector2(0, 0), Vector2(a.distance_to(b), 0),
		Vector2(a.distance_to(b) * 0.5, -a.distance_to(c)))

## Hollow ring (a rail, a flange, a balcony fascia) of radius r around
## +Y at `base`: `t` thick radially, `h` tall, open in the middle.
static func ring(lm: LandmarkMesh, key: String, base: Vector3, r: float, t: float, h: float,
		seg: int = 32) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r - t * 0.5, 0.0), Vector2(r + t * 0.5, 0.0),
		Vector2(r + t * 0.5, h), Vector2(r - t * 0.5, h), Vector2(r - t * 0.5, 0.0)]), seg,
		1.0, 1.0, 0.0, false, false)

## `n` vertical members (mullions, posts, fins) round a circle of radius
## r at `base`, `h` tall, `w` wide tangentially and `d` deep radially.
static func ring_posts(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, n: int,
		w: float, d: float, phase: float = 0.0) -> void:
	for i in n:
		var a := TAU * (float(i) + phase) / float(n)
		var dir := Vector3(cos(a), 0, sin(a))
		lm.box(key, base + dir * r + Vector3(0, h * 0.5, 0), Vector3(w, h, d),
			Basis.looking_at(dir), 0.0)

## Railing round a circle: posts every ~`pitch` m and a top rail.
static func ring_rail(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float = 1.1,
		pitch: float = 2.5) -> void:
	var n := maxi(8, int(TAU * r / pitch))
	ring_posts(lm, key, base, r, h, n, 0.08, 0.08)
	ring(lm, key, base + Vector3(0, h - 0.06, 0), r, 0.1, 0.08, maxi(24, n))
	ring(lm, key, base + Vector3(0, h * 0.5, 0), r, 0.06, 0.05, maxi(24, n))

## Radius of a lathe profile (radius, y), bottom to top, at height y
## (linear between the profile points, clamped at the ends).
static func radius_at(prof: PackedVector2Array, y: float) -> float:
	if y <= prof[0].y:
		return prof[0].x
	for i in prof.size() - 1:
		if y <= prof[i + 1].y:
			return lerpf(prof[i].x, prof[i + 1].x, (y - prof[i].y) / maxf(prof[i + 1].y - prof[i].y, 0.001))
	return prof[prof.size() - 1].x

## Lighter classical column for long rows seen from afar (dome
## peristyles, loggias): square plinth, torus base, shaft with entasis,
## a flared bell capital (`bell` > 0, Corinthian/Composite) or an
## echinus (Doric/Tuscan, bell 0) and the abacus. About 240 triangles
## against the full LandmarkDetail.column's ~900.
static func column_lite(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		bell: float = 1.0, seg: int = 12) -> void:
	var cap_h := r * (2.2 if bell > 0.0 else 0.9)
	var base_h := r * 0.7
	lm.box(key, base + Vector3(0, base_h * 0.2, 0), Vector3(r * 2.6, base_h * 0.4, r * 2.6), Basis(), 0.0)
	lm.lathe(key, base + Vector3(0, base_h * 0.4, 0), PackedVector2Array([Vector2(r * 1.25, 0.0),
		Vector2(r * 1.2, base_h * 0.35), Vector2(r * 1.02, base_h * 0.6)]), seg)
	var sh := h - cap_h - base_h
	lm.lathe(key, base + Vector3(0, base_h, 0), PackedVector2Array([Vector2(r, 0.0),
		Vector2(r * 0.98, sh * 0.4), Vector2(r * 0.85, sh)]), seg)
	var cb := base + Vector3(0, base_h + sh, 0)
	if bell > 0.0:
		lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.9, 0.0), Vector2(r * 1.0, cap_h * 0.35),
			Vector2(r * 1.2, cap_h * 0.6), Vector2(r * 1.45, cap_h * 0.82)]), seg)
	else:
		lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.88, 0.0), Vector2(r * 1.2, cap_h * 0.4),
			Vector2(r * 1.4, cap_h * 0.7)]), seg)
	lm.box(key, cb + Vector3(0, cap_h * 0.86, 0), Vector3(r * 2.8, cap_h * 0.28, r * 2.8), Basis(), 0.0)

## Roof balustrade along a-b, lighter than LandmarkDetail.balustrade
## for long runs: plinth, balusters every `pitch` m (lathed vases when
## `vase`, square posts otherwise), a pedestal every `bay` m and the
## handrail.
static func balusters(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.0,
		pitch: float = 0.5, bay: float = 4.6, vase: bool = false) -> void:
	var dir := (b - a).normalized()
	var dl := a.distance_to(b)
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	lm.box(key, mid + Vector3(0, h * 0.08, 0), Vector3(dl, h * 0.16, h * 0.4), basis, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.92, 0), Vector3(dl, h * 0.16, h * 0.45), basis, 0.0)
	var w := h * 0.16
	var prof := PackedVector2Array([Vector2(w * 0.6, 0.0), Vector2(w * 1.1, h * 0.2),
		Vector2(w * 0.55, h * 0.5), Vector2(w * 0.8, h * 0.68)])
	var n := int(dl / pitch)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, h * 0.16, 0)
		if vase:
			lm.lathe(key, p, prof, 6, 1.0, 1.0, 0.0, true, false)
		else:
			lm.box(key, p + Vector3(0, h * 0.34, 0), Vector3(w, h * 0.68, w), basis, 0.0)
	var piers := maxi(1, int(dl / bay))
	for i in piers + 1:
		lm.box(key, a.lerp(b, float(i) / float(piers)) + Vector3(0, h * 0.5, 0), Vector3(h * 0.4, h, h * 0.4),
			basis, 0.0)
