class_name LandmarkCeParts
extends RefCounted

## Small shared parts for the central Europe landmark batch, in true
## metres on LandmarkMesh: onion domes, window rows, colonnades and
## battlement teeth. Each takes the material KEY to draw with.

## Onion dome of base radius r and total height h (closed at the tip).
static func onion(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 16, smooth: bool = true) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.85, h * 0.07),
		Vector2(r, h * 0.24), Vector2(r * 0.92, h * 0.42), Vector2(r * 0.58, h * 0.62),
		Vector2(r * 0.22, h * 0.82), Vector2(0.0, h)]), seg, 1.0, 1.0, 0.0, smooth)

## Thin upright cross of total height h standing on `base`.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.beam(key, base, base + Vector3(0, h, 0), h * 0.07, h * 0.07)
	lm.beam(key, base + Vector3(-h * 0.22, h * 0.68, 0), base + Vector3(h * 0.22, h * 0.68, 0),
		h * 0.06, h * 0.06)

## `count` flat window boxes in a row along `along` (unit), centred on
## `origin`; `basis` turns each box to face outwards.
static func windows(lm: LandmarkMesh, key: String, origin: Vector3, along: Vector3, count: int,
		step: float, size: Vector3, basis: Basis = Basis()) -> void:
	for i in count:
		lm.box(key, origin + along * step * (float(i) - float(count - 1) * 0.5), size, basis)

## `count` round columns in a row along `along` from `origin`, r0 at the
## foot to r1 at the top, h tall.
static func colonnade(lm: LandmarkMesh, key: String, origin: Vector3, along: Vector3, count: int,
		step: float, r0: float, r1: float, h: float, seg: int = 12) -> void:
	for i in count:
		lm.frustum(key, origin + along * step * (float(i) - float(count - 1) * 0.5), r0, r1, h, seg)

## Battlement teeth along a straight wall top from `a` to `b` (both at
## the wall-top height): one tooth every `step`, w wide, h tall, d deep.
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, step: float,
		w: float, h: float, d: float) -> void:
	var n := maxi(int(a.distance_to(b) / step), 1)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	for i in n + 1:
		lm.box(key, a.lerp(b, float(i) / n) + Vector3(0, h * 0.5, 0), Vector3(w, h, d), basis)

## Eight-sided (or n-sided) pointed tent / spire of base radius r.
static func tent(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		sides: int = 8, top_r: float = 0.0) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r, 0), Vector2(top_r, h)]), sides,
		1.0, 1.0, PI / float(sides), false)

## Hipped roof over a w (X) by l (Z) rectangle centred at `c` (eave
## level), `rise` high with all four faces sloped; ridge along the
## longer side.
static func hip(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float, rise: float) -> void:
	var swap := w > l
	var u := (l if swap else w) * 0.5
	var v := (w if swap else l) * 0.5
	var r := v - u
	var up := Vector3(0, rise, 0)
	var a := _uv(c, -u, -v, swap)
	var b := _uv(c, u, -v, swap)
	var cc := _uv(c, u, v, swap)
	var d := _uv(c, -u, v, swap)
	var r0 := _uv(c, 0.0, -r, swap) + up
	var r1 := _uv(c, 0.0, r, swap) + up
	var nu := _uv(Vector3.ZERO, rise, 0.0, swap) + Vector3(0, u, 0)
	var nv := _uv(Vector3.ZERO, 0.0, rise, swap) + Vector3(0, u, 0)
	var mu := _uv(Vector3.ZERO, -rise, 0.0, swap) + Vector3(0, u, 0)
	var mv := _uv(Vector3.ZERO, 0.0, -rise, swap) + Vector3(0, u, 0)
	lm.quad(key, b, cc, r1, r0, nu.normalized())
	lm.quad(key, d, a, r0, r1, mu.normalized())
	lm.tri(key, a, b, r0, mv.normalized(), mv.normalized(), mv.normalized(), Vector2(0, 0), Vector2(u * 2.0, 0), Vector2(u, -rise))
	lm.tri(key, cc, d, r1, nv.normalized(), nv.normalized(), nv.normalized(), Vector2(0, 0), Vector2(u * 2.0, 0), Vector2(u, -rise))

## (across, along) offsets to a world point; `swap` runs `along` on X.
static func _uv(c: Vector3, u: float, v: float, swap: bool) -> Vector3:
	return c + (Vector3(v, 0, u) if swap else Vector3(u, 0, v))

## Round dome of base radius r rising h (quarter-ellipse profile), closed.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 20) -> void:
	var p := PackedVector2Array()
	for i in 9:
		var a := PI * 0.5 * float(i) / 8.0
		p.append(Vector2(r * cos(a), h * sin(a)))
	lm.lathe(key, base, p, seg)

## Gothic lancet window: opening w wide, h from the sill (`sill`, the
## centre of its bottom edge on a wall facing `n`) to the apex of an
## equilateral pointed head. A moulded frame stands proud of the wall,
## glass sits just in front of it, `mullions` divide the lights and a
## round tracery eye fills the head.
static func lancet(lm: LandmarkMesh, frame: String, glass: String, sill: Vector3, n: Vector3,
		w: float, h: float, mullions: int = 1, depth: float = 0.35) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var spring := maxf(h - w * 0.866, 0.2)
	var fw := clampf(w * 0.1, 0.12, 0.6)
	var g := sill + nn * 0.03
	var up := Vector3.UP
	lm.quad(glass, g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + up * spring,
		g - r * w * 0.5 + up * spring, nn)
	var gs := g + up * spring
	var head := _pointed(w * 0.5, 5)
	for i in head.size() - 1:
		var a := head[i]
		var b := head[i + 1]
		lm.tri(glass, gs, gs + r * a.x + up * a.y, gs + r * b.x + up * b.y, nn, nn, nn,
			Vector2.ZERO, a, b)
	var fc := sill + nn * depth * 0.5
	var wo := w * 0.5 + fw * 0.5
	for s in [-1.0, 1.0]:
		lm.beam(frame, fc + r * wo * float(s), fc + r * wo * float(s) + up * spring, fw, depth, r)
	var arc := _pointed(wo, 5)
	for i in arc.size() - 1:
		lm.beam(frame, fc + up * spring + r * arc[i].x + up * arc[i].y,
			fc + up * spring + r * arc[i + 1].x + up * arc[i + 1].y, fw, depth, nn)
	lm.box(frame, fc + nn * depth * 0.2 - up * fw * 0.3, Vector3(w + fw * 3.0, fw * 0.6, depth * 1.4),
		Basis(r, up, nn), 0.0)
	var bar := fw * 0.6
	for m in mullions:
		var x := w * ((float(m) + 1.0) / float(mullions + 1) - 0.5)
		lm.beam(frame, fc + r * x, fc + r * x + up * (spring + w * 0.12), bar, depth * 0.7, r)
	# Tracery eye in the head.
	var ec := fc + up * (spring + w * 0.42)
	var er := w * 0.2
	for k in 8:
		var a0 := TAU * float(k) / 8.0
		var a1 := TAU * float(k + 1) / 8.0
		lm.beam(frame, ec + (r * cos(a0) + up * sin(a0)) * er, ec + (r * cos(a1) + up * sin(a1)) * er,
			bar, depth * 0.7, nn)

## One side of an equilateral pointed arch of half-span hs, as (x, y)
## from the left springer (-hs, 0) up to the apex and down to (hs, 0).
static func _pointed(hs: float, steps: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var t := PI - (PI / 3.0) * float(i) / float(steps)
		p.append(Vector2(hs + cos(t) * hs * 2.0, sin(t) * hs * 2.0))
	for i in range(steps - 1, -1, -1):
		var q := p[i]
		p.append(Vector2(-q.x, q.y))
	return p

## Gothic pinnacle w square and h tall from `base`: a shaft, four
## gablets crossing at its head, a crocketed needle and a cross-flower
## finial.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float) -> void:
	var sh := h * 0.42
	lm.box(key, base + Vector3(0, sh * 0.5, 0), Vector3(w, sh, w))
	var gb := base + Vector3(0, sh, 0)
	lm.gable(key, gb, w, w, w * 0.75, Basis(), 0.04, key)
	lm.gable(key, gb, w, w, w * 0.75, Basis(Vector3.UP, PI * 0.5), 0.04, key)
	var nh := h - sh - w * 0.35
	lm.spire(key, gb, w * 0.36, nh)
	# Crockets up the four arrises, then the finial.
	var n := clampi(int(nh / maxf(w * 0.6, 0.3)), 2, 6)
	for e in 4:
		var a := PI * 0.25 + PI * 0.5 * float(e)
		var d := Vector3(cos(a), 0, sin(a))
		for k in n:
			var t := (float(k) + 0.6) / float(n + 0.5)
			var p := gb + d * w * 0.36 * 1.414 * (1.0 - t) + Vector3(0, nh * t, 0)
			lm.box(key, p + d * w * 0.08, Vector3(w * 0.16, w * 0.12, w * 0.16), Basis(Vector3.UP, -a), 0.0)
	var tip := gb + Vector3(0, nh, 0)
	lm.box(key, tip, Vector3(w * 0.34, w * 0.12, w * 0.12), Basis(), 0.0)
	lm.box(key, tip, Vector3(w * 0.12, w * 0.12, w * 0.34), Basis(), 0.0)
	lm.beam(key, tip - Vector3(0, w * 0.1, 0), tip + Vector3(0, w * 0.35, 0), w * 0.1, w * 0.1)

## Gothic wimperg: an open triangular gable `w` wide and `h` tall over a
## window or portal, its foot centred at `c` on a wall facing `n`, with
## crockets on the rakes and a finial.
static func wimperg(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, w: float, h: float,
		depth: float = 0.4) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var b := c + nn * depth * 0.5
	var apex := b + Vector3(0, h, 0)
	var bw := clampf(w * 0.08, 0.15, 0.8)
	for s in [-1.0, 1.0]:
		var foot := b + r * w * 0.5 * float(s)
		lm.beam(key, foot, apex, bw, depth, nn)
		for k in 3:
			var p := foot.lerp(apex, (float(k) + 0.7) / 3.7) + Vector3(0, bw * 0.6, 0)
			lm.box(key, p, Vector3(bw * 0.8, bw * 0.7, depth * 0.8), Basis(r, Vector3.UP, nn), 0.0)
	lm.beam(key, b - r * w * 0.5, b + r * w * 0.5, bw, depth, nn)
	lm.beam(key, apex, apex + Vector3(0, bw * 2.2, 0), bw * 0.9, bw * 0.9)
	lm.box(key, apex + Vector3(0, bw * 1.6, 0), Vector3(bw * 2.0, bw * 0.5, bw * 0.5), Basis(r, Vector3.UP, nn), 0.0)

## Ring of `count` small round-headed openings (drum and gallery windows)
## of w x h around a vertical axis at `c` (sill level), radius r: framed
## by an arch of beams over each, glass on the wall.
static func arched_ring(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, r: float,
		count: int, w: float, h: float, phase: float = 0.0) -> void:
	for i in count:
		var a := phase + TAU * (float(i) + 0.5) / float(count)
		var d := Vector3(cos(a), 0, sin(a))
		var rt := d.cross(Vector3.UP).normalized()
		var p := c + d * (r + 0.03)
		var oh := h - w * 0.5
		lm.quad(glass, p - rt * w * 0.5, p + rt * w * 0.5, p + rt * w * 0.5 + Vector3(0, oh, 0),
			p - rt * w * 0.5 + Vector3(0, oh, 0), d)
		var fw := clampf(w * 0.14, 0.1, 0.5)
		var fc := c + d * (r + fw * 0.4)
		var prev := fc - rt * (w * 0.5 + fw * 0.5)
		lm.beam(frame, prev, prev + Vector3(0, oh, 0), fw, fw, rt)
		prev += Vector3(0, oh, 0)
		for k in 6:
			var t := PI - PI * float(k + 1) / 6.0
			var q := fc + Vector3(0, oh, 0) + (rt * cos(t) + Vector3.UP * sin(t)) * (w * 0.5 + fw * 0.5)
			lm.beam(frame, prev, q, fw, fw, d)
			prev = q
		lm.beam(frame, prev, prev - Vector3(0, oh, 0), fw, fw, rt)
