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

## Corner point of hip_roof at height fraction t (0 eave, 1 ridge) on
## the corner (sx, sz) = (+-1, +-1); matches hip_roof's swept surface.
static func hip_corner(c: Vector3, eave: Vector2, top: Vector2, rise: float, lift: float, t: float,
		sx: float, sz: float) -> Vector3:
	var f := 1.0 - pow(1.0 - t, 1.8)
	var hx := lerpf(eave.x * 0.5, top.x * 0.5, f)
	var hz := lerpf(eave.y * 0.5, top.y * 0.5, f)
	var y := rise * t + (1.0 - t) * (1.0 - t) * lift + lift * 0.75 * (1.0 - t)
	return c + Vector3(sx * hx, y, sz * hz)

## The four hip ridges of a hip_roof (rolls `w` wide riding the arris)
## and, when `beasts` > 0, the file of glazed ridge beasts led by the
## immortal on a hen at each eave corner (rank by number: the Hall of
## Supreme Harmony alone carries ten).
static func hip_ridges(lm: LandmarkMesh, key: String, c: Vector3, eave: Vector2, top: Vector2,
		rise: float, lift: float, w: float, beasts: int = 0) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var prev := hip_corner(c, eave, top, rise, lift, 0.0, sx, sz) + Vector3(0, w * 0.35, 0)
			for k in range(1, 7):
				var p := hip_corner(c, eave, top, rise, lift, float(k) / 6.0, sx, sz) + Vector3(0, w * 0.35, 0)
				lm.beam(key, prev, p, w, w * 0.8)
				prev = p
			if beasts <= 0:
				continue
			var a := hip_corner(c, eave, top, rise, lift, 0.02, sx, sz)
			var b := hip_corner(c, eave, top, rise, lift, 0.4, sx, sz)
			var dir := (b - a).normalized()
			var flat := Vector3(dir.x, 0, dir.z).normalized()
			var basis := Basis(flat.cross(Vector3.UP).normalized(), Vector3.UP, flat)
			for i in beasts + 1:
				var p := a.lerp(b, (float(i) + 0.5) / float(beasts + 1)) + Vector3(0, w * 0.8, 0)
				var s := w * (1.2 if i == 0 else 1.0)
				lm.box(key, p + Vector3(0, s * 0.45, 0), Vector3(s * 0.55, s * 0.9, s * 0.7), basis, 0.0)
				lm.box(key, p + Vector3(0, s * 1.05, 0) - flat * s * 0.2, Vector3(s * 0.4, s * 0.4, s * 0.55), basis, 0.0)

## Chiwen: the dragon-fish ridge-end ornament, `h` tall, standing at
## `c` with its open jaw biting the ridge toward `inward` (+-1 on x):
## body, swallowing jaw, curled-back tail and the sword hilt behind.
static func chiwen(lm: LandmarkMesh, key: String, c: Vector3, h: float, inward: float) -> void:
	var w := h * 0.28
	lm.box(key, c + Vector3(0, h * 0.35, 0), Vector3(h * 0.55, h * 0.7, w), Basis(), 0.0)
	lm.box(key, c + Vector3(inward * h * 0.3, h * 0.28, 0), Vector3(h * 0.25, h * 0.4, w * 0.9), Basis(), 0.0)
	var prev := c + Vector3(0, h * 0.7, 0)
	for i in 6:
		var a := PI * 0.5 + float(i + 1) / 6.0 * PI * 1.1
		var p := c + Vector3(-inward * (h * 0.12 - cos(a) * h * 0.2), h * 0.72 + sin(a) * h * 0.22, 0)
		lm.beam(key, prev, p, w * 0.7, w * 0.8)
		prev = p
	lm.beam(key, c + Vector3(-inward * h * 0.32, h * 0.5, 0), c + Vector3(-inward * h * 0.36, h * 1.0, 0),
		w * 0.35, w * 0.35)

## Chinese marble balustrade from a to b (on the deck): sill, carved
## square posts with cloud-capped heads every ~pitch m, a pierced panel
## and handrail in each bay; `spout` (a horizontal outward vector, zero
## for none) adds the dragon-head drain spout under every post;
## `end_post` false leaves the post at b to the next run.
static func cn_balustrade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.3,
		pitch: float = 2.0, spout: Vector3 = Vector3.ZERO, end_post: bool = true) -> void:
	var dl := a.distance_to(b)
	if dl < 0.5:
		return
	var dir := (b - a) / dl
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var n := maxi(int(round(dl / pitch)), 1)
	var bay := dl / float(n)
	lm.box(key, (a + b) * 0.5 + Vector3(0, 0.09, 0), Vector3(dl, 0.18, 0.4), basis, 0.0)
	var head := PackedVector2Array([Vector2(0.15, 0), Vector2(0.18, 0.1), Vector2(0.15, 0.26), Vector2(0.0, 0.4)])
	for i in n + (1 if end_post else 0):
		var p := a + dir * bay * float(i)
		lm.box(key, p + Vector3(0, h * 0.4, 0), Vector3(0.24, h * 0.8, 0.24), basis, 0.0)
		lm.lathe(key, p + Vector3(0, h * 0.8, 0), head, 4, 1.0, 1.0, PI * 0.25, false)
		if spout != Vector3.ZERO:
			lm.beam(key, p - Vector3(0, 0.25, 0) + spout * 0.1, p - Vector3(0, 0.3, 0) + spout * 0.9, 0.26, 0.3)
		if i < n:
			var m := p + dir * bay * 0.5
			lm.box(key, m + Vector3(0, h * 0.42, 0), Vector3(bay - 0.24, h * 0.42, 0.12), basis, 0.0)
			lm.box(key, m + Vector3(0, h * 0.7, 0), Vector3(bay - 0.24, 0.11, 0.15), basis, 0.0)

## Balustrade round a closed polygon of deck points (XZ at height y),
## spouts pointing out of the polygon.
static func cn_balustrade_loop(lm: LandmarkMesh, key: String, pts: PackedVector2Array, y: float,
		h: float = 1.3, pitch: float = 2.0, spouts: bool = true) -> void:
	var ctr := Vector2.ZERO
	for p in pts:
		ctr += p
	ctr /= float(pts.size())
	for i in pts.size():
		var p := pts[i]
		var q := pts[(i + 1) % pts.size()]
		var m := (p + q) * 0.5 - ctr
		var e := (q - p).normalized()
		var o := Vector2(e.y, -e.x)
		if o.dot(m) < 0.0:
			o = -o
		cn_balustrade(lm, key, Vector3(p.x, y, p.y), Vector3(q.x, y, q.y), h, pitch,
			Vector3(o.x, 0, o.y) if spouts else Vector3.ZERO)

## Rectangle of corners for a balustrade loop, inset `inset` from a
## w x d deck centred on (cx, cz).
static func rect_pts(cx: float, cz: float, w: float, d: float, inset: float = 0.3) -> PackedVector2Array:
	var hx := w * 0.5 - inset
	var hz := d * 0.5 - inset
	return PackedVector2Array([Vector2(cx - hx, cz - hz), Vector2(cx + hx, cz - hz),
		Vector2(cx + hx, cz + hz), Vector2(cx - hx, cz + hz)])

## Dougong bracket sets every `pitch` m round a w x d rectangle at
## height y (bottom), `h` tall: three tiers of blocks and arms, each
## cantilevering further out, carrying the eave purlin.
static func brackets(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, h: float,
		pitch: float = 1.6) -> void:
	for side in 4:
		var along := Vector3.RIGHT if side < 2 else Vector3.BACK
		var out := (Vector3.BACK if side == 0 else Vector3.FORWARD) if side < 2 else \
			(Vector3.RIGHT if side == 2 else Vector3.LEFT)
		var run := w if side < 2 else d
		var off := (d if side < 2 else w) * 0.5
		var basis := Basis(along, Vector3.UP, out)
		var n := maxi(int(run / pitch), 1)
		for i in n:
			var p := c + along * (run * ((float(i) + 0.5) / float(n) - 0.5)) + out * off
			for k in 3:
				var ky := h * (float(k) + 0.5) / 3.0
				lm.box(key, p + Vector3(0, ky, 0) + out * (0.15 + 0.25 * k),
					Vector3(0.45 + 0.35 * k, h / 3.0 * 0.9, 0.3 + 0.5 * k), basis, 0.0)
	# The purlin they carry.
	lm.box(key, c + Vector3(0, h + 0.15, 0), Vector3(w + 1.6, 0.3, d + 1.6), Basis(), 0.0)

## Flight of `n` steps against a terrace wall: `foot` is the wall's
## foot at the flight's centre line, `out` the unit vector away from
## the wall, `rise` the terrace height, `w` the flight's width. Each
## step is a solid block, the lowest reaching furthest out.
static func steps(lm: LandmarkMesh, key: String, foot: Vector3, out: Vector3, w: float, rise: float,
		n: int, run: float = 0.32) -> void:
	var basis := Basis(out.cross(Vector3.UP).normalized(), Vector3.UP, out)
	for k in n:
		var top := rise * float(n - k) / float(n)
		var depth := run * float(k + 1)
		lm.box(key, foot + Vector3(0, top * 0.5, 0) + out * depth * 0.5, Vector3(w, top, depth), basis, 0.0)

## Thick eave of a hip_roof (same c, eave, lift): a fascia board
## `th` deep riding the swept eave line, and exposed rafter ends every
## `pitch` m running back under it to the wall rectangle `wall`.
static func eave_fascia(lm: LandmarkMesh, key: String, c: Vector3, eave: Vector2, lift: float, th: float,
		wall: Vector2 = Vector2.ZERO, pitch: float = 0.6) -> void:
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[side + 1]
		var pa := c + Vector3(a.x * eave.x * 0.5, lift, a.y * eave.y * 0.5)
		var pb := c + Vector3(b.x * eave.x * 0.5, lift, b.y * eave.y * 0.5)
		var mid := (a + b) * 0.5
		var out := Vector3(mid.x, 0, mid.y).normalized()
		var prev := pa + Vector3(0, lift * 0.75 - th * 0.5, 0)
		for q in range(1, 13):
			var f := float(q) / 12.0
			var e := absf(f - 0.5) * 2.0
			var p := pa.lerp(pb, f) + Vector3(0, pow(e, 3.0) * lift * 0.75 - th * 0.5, 0)
			lm.beam(key, prev, p, th, 0.25, Vector3.UP)
			prev = p
		if wall == Vector2.ZERO:
			continue
		var run := pa.distance_to(pb)
		var n := int(run / pitch)
		var wy := c.y - th * 0.5
		for i in range(1, n):
			var f := float(i) / float(n)
			var e := absf(f - 0.5) * 2.0
			var p := pa.lerp(pb, f) + Vector3(0, pow(e, 3.0) * lift * 0.75 - th, 0) - out * 0.15
			var w := Vector3(p.x, wy, p.z)
			w = Vector3(clampf(w.x, c.x - wall.x * 0.5, c.x + wall.x * 0.5), wy, clampf(w.z, c.z - wall.y * 0.5, c.z + wall.y * 0.5))
			lm.beam(key, w, p, 0.12, 0.16)

## Flat-faced band between two closed XZ polygons (same point count,
## either winding) at y0 and y1: one quad per edge with its true face
## normal, so notched (re-entrant) plans shade correctly.
static func poly_band(lm: LandmarkMesh, key: String, p0: PackedVector2Array, y0: float,
		p1: PackedVector2Array, y1: float) -> void:
	var area := 0.0
	for i in p0.size():
		var q := p0[(i + 1) % p0.size()]
		area += p0[i].x * q.y - q.x * p0[i].y
	var sgn := 1.0 if area > 0.0 else -1.0
	for i in p0.size():
		var k := (i + 1) % p0.size()
		var a := Vector3(p0[i].x, y0, p0[i].y)
		var b := Vector3(p0[k].x, y0, p0[k].y)
		var c := Vector3(p1[k].x, y1, p1[k].y)
		var d := Vector3(p1[i].x, y1, p1[i].y)
		var e := p0[k] - p0[i]
		var out := Vector3(e.y, 0, -e.x).normalized() * sgn
		var n := (b - a).cross(d - a).normalized()
		if n.dot(out) < 0.0:
			n = -n
		lm.quad(key, a, b, c, d, n)
