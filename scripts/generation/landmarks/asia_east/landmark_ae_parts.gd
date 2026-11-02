class_name LandmarkAeParts
extends RefCounted

## Shared parts for the east-Asia landmark batch, in true metres on
## LandmarkMesh: slanted round tubes, spheres, lofted towers (stacked
## rings with a twist and a taper), battered boxes and the concave
## upswept hip roof of East Asian halls.

## Round tube from a to b (radius ra at a, rb at b), `seg` sides.
static func tube(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, ra: float, rb: float,
		seg: int = 10) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	var len := a.distance_to(b)
	for i in seg:
		var t0 := TAU * float(i) / seg
		var t1 := TAU * float(i + 1) / seg
		var d0 := u * cos(t0) + v * sin(t0)
		var d1 := u * cos(t1) + v * sin(t1)
		var arc := TAU * maxf(ra, rb) / seg
		lm.tri(key, a + d0 * ra, a + d1 * ra, b + d1 * rb, d0, d1, d1,
			Vector2(arc * i, 0), Vector2(arc * (i + 1), 0), Vector2(arc * (i + 1), len))
		lm.tri(key, a + d0 * ra, b + d1 * rb, b + d0 * rb, d0, d1, d0,
			Vector2(arc * i, 0), Vector2(arc * (i + 1), len), Vector2(arc * i, len))

## Sphere of radius r centred at c (a lathe of a half circle).
static func ball(lm: LandmarkMesh, key: String, c: Vector3, r: float, seg: int = 20,
		rings: int = 10) -> void:
	var prof := PackedVector2Array()
	for j in rings + 1:
		var phi := PI * float(j) / rings
		prof.append(Vector2(r * sin(phi), -r * cos(phi)))
	lm.lathe(key, c, prof, seg)

## Closed ring of `n` points of the polar shape r(theta) = shape.call(theta)
## turned by `twist`, centred at (cx, y, cz).
static func ring(n: int, y: float, shape: Callable, twist: float = 0.0, cx: float = 0.0,
		cz: float = 0.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in n:
		var th := TAU * float(i) / n
		var r: float = shape.call(th)
		var a := th + twist
		out.append(Vector3(cx + r * cos(a), y, cz + r * sin(a)))
	return out

## Skin between consecutive closed rings (smooth radial normals) and a
## fan cap on the last ring; rings share a point count.
static func loft(lm: LandmarkMesh, key: String, rings: Array, cap_top: bool = true) -> void:
	var n := (rings[0] as PackedVector3Array).size()
	for j in rings.size() - 1:
		var r0: PackedVector3Array = rings[j]
		var r1: PackedVector3Array = rings[j + 1]
		var c0 := _centre(r0)
		var c1 := _centre(r1)
		var u := 0.0
		for i in n:
			var k := (i + 1) % n
			var n0 := _radial(r0[i], c0)
			var n1 := _radial(r0[k], c0)
			var m0 := _radial(r1[i], c1)
			var m1 := _radial(r1[k], c1)
			var e := r0[i].distance_to(r0[k])
			var h := r0[i].distance_to(r1[i])
			lm.tri(key, r0[i], r0[k], r1[k], n0, n1, m1, Vector2(u, 0), Vector2(u + e, 0), Vector2(u + e, h))
			lm.tri(key, r0[i], r1[k], r1[i], n0, m1, m0, Vector2(u, 0), Vector2(u + e, h), Vector2(u, h))
			u += e
	if cap_top:
		var top: PackedVector3Array = rings[rings.size() - 1]
		var c := _centre(top)
		for i in n:
			lm.tri(key, c, top[i], top[(i + 1) % n], Vector3.UP, Vector3.UP, Vector3.UP,
				Vector2(c.x, c.z), Vector2(top[i].x, top[i].z), Vector2(top[(i + 1) % n].x, top[(i + 1) % n].z))

static func _centre(r: PackedVector3Array) -> Vector3:
	var s := Vector3.ZERO
	for p in r:
		s += p
	return s / float(r.size())

static func _radial(p: Vector3, c: Vector3) -> Vector3:
	return Vector3(p.x - c.x, 0.0, p.z - c.z).normalized()

## Rectangular frustum (battered box) centred on (cx, cz): footprint w0 x d0
## at y0 narrowing to w1 x d1 at y1, top capped.
static func batter(lm: LandmarkMesh, key: String, cx: float, cz: float, w0: float, d0: float,
		w1: float, d1: float, y0: float, y1: float) -> void:
	var b: Array[Vector3] = []
	var t: Array[Vector3] = []
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var cv := c as Vector2
		b.append(Vector3(cx + cv.x * w0 * 0.5, y0, cz + cv.y * d0 * 0.5))
		t.append(Vector3(cx + cv.x * w1 * 0.5, y1, cz + cv.y * d1 * 0.5))
	var mid := Vector3(cx, (y0 + y1) * 0.5, cz)
	for i in 4:
		var k := (i + 1) % 4
		var n := (b[k] - b[i]).cross(t[i] - b[i]).normalized()
		if n.dot((b[i] + b[k] + t[i] + t[k]) * 0.25 - mid) < 0.0:
			n = -n
		lm.quad(key, b[i], b[k], t[k], t[i], n)
	lm.quad(key, t[0], t[1], t[2], t[3], Vector3.UP)

## Concave hip roof from an eave rectangle (centred on x, z = 0 at height y)
## up to a ridge rectangle `top`, `rise` high, corners swept up by `lift`.
static func hip_roof(lm: LandmarkMesh, key: String, c: Vector3, eave: Vector2, top: Vector2,
		rise: float, lift: float = 0.8) -> void:
	var rows: Array = []
	for k in 7:
		var t := float(k) / 6.0
		var f := 1.0 - pow(1.0 - t, 1.8)
		var hx := lerpf(eave.x * 0.5, top.x * 0.5, f)
		var hz := lerpf(eave.y * 0.5, top.y * 0.5, f)
		var ring: Array = []
		for cc in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			var cv := cc as Vector2
			ring.append(c + Vector3(cv.x * hx, rise * t + (1.0 - t) * (1.0 - t) * lift, cv.y * hz))
		rows.append(ring)
	for side in 4:
		var strip: Array = []
		for k in rows.size():
			var r := rows[k] as Array
			var line := PackedVector3Array()
			for q in 7:
				var p := (r[side] as Vector3).lerp(r[side + 1], float(q) / 6.0)
				var edge := absf(float(q) / 6.0 - 0.5) * 2.0
				line.append(p + Vector3(0, pow(edge, 3.0) * lift * 0.75 * (1.0 - float(k) / 6.0), 0))
			strip.append(line)
		lm.grid(key, strip, c - Vector3(0, 50.0, 0), true)
	var last: Array = rows[rows.size() - 1]
	var cap := PackedVector2Array()
	for i in 4:
		var v: Vector3 = last[i]
		cap.append(Vector2(v.x, v.z))
	var cy: float = (last[0] as Vector3).y
	lm.poly_prism(key, cap, cy - 0.2, cy)
