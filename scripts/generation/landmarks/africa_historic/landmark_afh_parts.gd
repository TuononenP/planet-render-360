class_name LandmarkAfhParts
extends RefCounted

## Small shared shapes for the historic Africa landmark batch, in true
## metres on LandmarkMesh: outward-facing quads, tapered prisms in any
## frame, merlon rings, flat panels on tower faces and a stable hash.

## Flat quad a-b-c-d whose normal is flipped to face `outward`.
static func quad_out(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, outward: Vector3) -> void:
	var n := (b - a).cross(d - a).normalized()
	if n == Vector3.ZERO:
		n = (c - b).cross(a - b).normalized()
	if n.dot(outward) < 0.0:
		n = -n
	lm.quad(key, a, b, c, d, n)

## Rectangular prism along the local Y axis of `xf` (X = width, Z = depth)
## tapering from w0 x d0 at local height y0 to w1 x d1 at y1; the top is
## capped (and the bottom when asked).
static func tapered(lm: LandmarkMesh, key: String, xf: Transform3D, y0: float, y1: float,
		w0: float, d0: float, w1: float, d1: float, cap_top: bool = true,
		cap_bottom: bool = false) -> void:
	var sx: Array[float] = [-1.0, 1.0, 1.0, -1.0]
	var sz: Array[float] = [-1.0, -1.0, 1.0, 1.0]
	var lo: Array[Vector3] = []
	var hi: Array[Vector3] = []
	for i in 4:
		lo.append(xf * Vector3(sx[i] * w0 * 0.5, y0, sz[i] * d0 * 0.5))
		hi.append(xf * Vector3(sx[i] * w1 * 0.5, y1, sz[i] * d1 * 0.5))
	var mid := xf * Vector3(0, (y0 + y1) * 0.5, 0)
	for i in 4:
		var j := (i + 1) % 4
		quad_out(lm, key, lo[i], lo[j], hi[j], hi[i],
			(lo[i] + lo[j] + hi[i] + hi[j]) * 0.25 - mid)
	var up := xf.basis.y.normalized()
	if cap_top:
		quad_out(lm, key, hi[0], hi[1], hi[2], hi[3], up)
	if cap_bottom:
		quad_out(lm, key, lo[0], lo[1], lo[2], lo[3], -up)

## Ring of square merlons (size m, height h) round a rectangle of
## half-sizes hx, hz centred on `c` at the wall-top level.
static func merlon_ring(lm: LandmarkMesh, key: String, c: Vector3, hx: float, hz: float,
		m: float, h: float) -> void:
	var nx := maxi(roundi(hx / m), 1)
	var nz := maxi(roundi(hz / m), 1)
	for i in nx:
		var x := -hx + (float(i) + 0.5) * 2.0 * hx / float(nx)
		for s in [-1.0, 1.0]:
			lm.box(key, c + Vector3(x, h * 0.5, s * (hz - m * 0.5)), Vector3(m, h, m))
	for i in nz:
		var z := -hz + (float(i) + 0.5) * 2.0 * hz / float(nz)
		for s in [-1.0, 1.0]:
			lm.box(key, c + Vector3(s * (hx - m * 0.5), h * 0.5, z), Vector3(m, h, m))

## Flat panel w wide and h tall on a vertical face: `c` is a point on the
## face plane (its y is ignored), `out` the face normal, `u` the offset
## along the face and `y` the panel's bottom; pushed `off` clear of the wall.
static func face_quad(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, u: float,
		y: float, w: float, h: float, off: float = 0.05) -> void:
	var right := Vector3.UP.cross(out).normalized()
	var p := Vector3(c.x, 0.0, c.z) + out * off + right * u + Vector3(0, y, 0)
	var lift := Vector3(0, h, 0)
	lm.quad(key, p - right * w * 0.5, p + right * w * 0.5, p + right * w * 0.5 + lift,
		p - right * w * 0.5 + lift, out)

## Row of up-pointing triangles (zigzag band) along a vertical face of
## half-width hw centred on `c`: `n` triangles, base at y, apex `h` above.
static func zigzag(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, hw: float,
		y: float, h: float, n: int) -> void:
	var right := Vector3.UP.cross(out).normalized()
	var cell := 2.0 * hw * 0.9 / float(n)
	var base := Vector3(c.x, y, c.z) + out * 0.05
	for i in n:
		var u := (float(i) - float(n - 1) * 0.5) * cell
		var p0 := base + right * (u - cell * 0.5)
		var p1 := base + right * (u + cell * 0.5)
		var p2 := base + right * u + Vector3(0, h, 0)
		lm.tri(key, p0, p1, p2, out, out, out, Vector2(0, 0), Vector2(cell, 0), Vector2(cell * 0.5, -h))

## Stable pseudo-random number in 0..1 from two integers.
static func hash01(a: int, b: int = 0) -> float:
	return fmod(absf(sin(float(a) * 12.9898 + float(b) * 78.233) * 43758.5453), 1.0)
