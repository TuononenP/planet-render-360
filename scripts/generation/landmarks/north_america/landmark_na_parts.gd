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
