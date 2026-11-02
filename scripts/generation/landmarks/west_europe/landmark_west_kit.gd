class_name LandmarkWestKit
extends RefCounted

## Small helpers shared by the west Europe landmark batch, in true
## metres on LandmarkMesh: base-anchored boxes, hip roofs, round tubes,
## window and column runs, ogive domes and arched wall blocks.

## Box standing on y0 (not centred), turned by `yaw` about +Y.
static func blk(lm: LandmarkMesh, key: String, cx: float, y0: float, cz: float, w: float,
		h: float, d: float, yaw: float = 0.0) -> void:
	lm.box(key, Vector3(cx, y0 + h * 0.5, cz), Vector3(w, h, d), Basis(Vector3.UP, yaw))

## Hip roof over a w (X) x l (Z) rectangle centred at `base` (eave
## level); the ridge/top is `top` times the eave size (0 = pyramid).
static func hip(lm: LandmarkMesh, key: String, base: Vector3, w: float, l: float, h: float,
		top: float = 0.0) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(1.4142, 0), Vector2(1.4142 * top, h)]),
		4, w * 0.5, l * 0.5, PI * 0.25, false)

## Round tube from a to b (n-sided prism, smooth normals per face).
static func tube(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r: float,
		seg: int = 8) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var d0 := (u * cos(a0) + v * sin(a0))
		var d1 := (u * cos(a1) + v * sin(a1))
		lm.quad(key, a + d0 * r, a + d1 * r, b + d1 * r, b + d0 * r, (d0 + d1).normalized())

## Dome profile (radius, y) bottom to top; point > 1 gives an onion/ogive
## taper, 1 a plain ellipse.
static func dome_prof(r: float, h: float, steps: int = 10, point: float = 1.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / float(steps)
		p.append(Vector2(r * pow(cos(a), point), h * sin(a)))
	p[steps] = Vector2(0.0, h)
	return p

static func ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr

## Row of window boxes along p0 -> p1 on a wall facing `n`, centred at
## each height in `ys`, every `step` metres.
static func win_line(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, n: Vector3,
		step: float, w: float, h: float, ys: Array, proud: float = 0.12) -> void:
	var basis := Basis(Vector3.UP, atan2(n.x, n.z))
	var count := int((p1 - p0).length() / step)
	for i in count:
		var p := p0.lerp(p1, (float(i) + 0.5) / float(count))
		for y in ys:
			lm.box(key, Vector3(p.x, float(y), p.z) + n * proud, Vector3(w, h, 0.25), basis)

## Straight row of n tapered columns from p0 to p1 (base points).
static func col_row(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, n: int,
		r0: float, r1: float, h: float, seg: int = 10) -> void:
	for i in n:
		var p := p0.lerp(p1, float(i) / float(maxi(n - 1, 1)))
		lm.frustum(key, p, r0, r1, h, seg)

## Ring of n columns round `c` at radius `ring_r`.
static func col_ring(lm: LandmarkMesh, key: String, c: Vector3, ring_r: float, n: int,
		r0: float, r1: float, h: float) -> void:
	for i in n:
		var a := TAU * float(i) / float(n)
		lm.frustum(key, c + Vector3(cos(a), 0, sin(a)) * ring_r, r0, r1, h, 8)

## Evenly spaced merlons/pinnacles along a wall top from p0 to p1.
static func merlons(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, step: float,
		w: float, h: float, thick: float) -> void:
	var count := maxi(int(p0.distance_to(p1) / step), 1)
	var basis := Basis(Vector3.UP, atan2(p1.x - p0.x, p1.z - p0.z))
	for i in count:
		var p := p0.lerp(p1, (float(i) + 0.5) / float(count))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(thick, h, w), basis)

## Slim gilt cross standing on `base`, h tall.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.5, 0), Vector3(h * 0.07, h, h * 0.07))
	lm.box(key, base + Vector3(0, h * 0.72, 0), Vector3(h * 0.4, h * 0.07, h * 0.07))

## Wall block with a round-headed passage: `half_w` x `half_d` plan,
## from the passage spring line up to top_y, in the frame `b` at `o`
## (passage runs along local Z, centred on x = 0). Both faces are cut
## by the arch of radius `r`; the soffit and end faces are closed.
static func arch_wall(lm: LandmarkMesh, key: String, b: Basis, o: Vector3, half_w: float,
		half_d: float, r: float, spring_y: float, top_y: float) -> void:
	var f := func(x: float, y: float, z: float) -> Vector3: return o + b * Vector3(x, y, z)
	var steps := 14
	for s in [-1.0, 1.0]:
		var n: Vector3 = b * Vector3(0, 0, s)
		var z: float = s * half_d
		for side in [-1.0, 1.0]:
			lm.quad(key, f.call(side * r, spring_y, z), f.call(side * half_w, spring_y, z),
				f.call(side * half_w, top_y, z), f.call(side * r, top_y, z), n)
		for i in steps:
			var xa := -r + 2.0 * r * float(i) / float(steps)
			var xb := -r + 2.0 * r * float(i + 1) / float(steps)
			lm.quad(key, f.call(xa, spring_y + sqrt(maxf(r * r - xa * xa, 0.0)), z),
				f.call(xb, spring_y + sqrt(maxf(r * r - xb * xb, 0.0)), z),
				f.call(xb, top_y, z), f.call(xa, top_y, z), n)
	for i in steps:
		var t0 := PI * float(i) / float(steps)
		var t1 := PI * float(i + 1) / float(steps)
		var inward: Vector3 = b * Vector3(-cos((t0 + t1) * 0.5), -sin((t0 + t1) * 0.5), 0)
		lm.quad(key, f.call(r * cos(t0), spring_y + r * sin(t0), -half_d),
			f.call(r * cos(t1), spring_y + r * sin(t1), -half_d),
			f.call(r * cos(t1), spring_y + r * sin(t1), half_d),
			f.call(r * cos(t0), spring_y + r * sin(t0), half_d), inward)
	for sx in [-1.0, 1.0]:
		var nx: Vector3 = b * Vector3(sx, 0, 0)
		lm.quad(key, f.call(sx * half_w, spring_y, -half_d), f.call(sx * half_w, spring_y, half_d),
			f.call(sx * half_w, top_y, half_d), f.call(sx * half_w, top_y, -half_d), nx)
	lm.quad(key, f.call(-half_w, top_y, -half_d), f.call(half_w, top_y, -half_d),
		f.call(half_w, top_y, half_d), f.call(-half_w, top_y, half_d), b * Vector3.UP)
