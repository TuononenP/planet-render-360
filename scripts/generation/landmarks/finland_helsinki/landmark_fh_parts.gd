class_name LandmarkFhParts
extends RefCounted

## Facade parts shared by the finland_helsinki builders, in true metres
## on LandmarkMesh: rows of framed windows and Gothic lancets, recessed
## window grids laid over a wall run, pilaster strips, string courses,
## the brick corbel-arch frieze of the Russian and Romanesque churches,
## stepped (crow-stepped) gables and ribbed onion domes. Wall runs go
## from ground point a to b with `out` the horizontal outward normal.

## The four faces of an axis box centred (cx, cz), w (X) by d (Z), as
## [a, b, out] wall runs at ground level, each a..b running left to right
## seen from outside.
static func faces(cx: float, cz: float, w: float, d: float) -> Array:
	var hx := w * 0.5
	var hz := d * 0.5
	return [[Vector3(cx - hx, 0, cz + hz), Vector3(cx + hx, 0, cz + hz), Vector3(0, 0, 1)],
		[Vector3(cx + hx, 0, cz + hz), Vector3(cx + hx, 0, cz - hz), Vector3(1, 0, 0)],
		[Vector3(cx + hx, 0, cz - hz), Vector3(cx - hx, 0, cz - hz), Vector3(0, 0, -1)],
		[Vector3(cx - hx, 0, cz - hz), Vector3(cx - hx, 0, cz + hz), Vector3(-1, 0, 0)]]

## `n` framed windows (LandmarkDetail.window: architrave, sill, head or
## round arch, glazing bars) evenly along a..b, sills `y` up.
static func win_row(lm: LandmarkMesh, frame: String, glass: String, a: Vector3, b: Vector3, out: Vector3,
		y: float, n: int, w: float, h: float, arched: bool = false, depth: float = 0.2) -> void:
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		LandmarkDetail.window(lm, frame, glass, Vector3(p.x, y + h * 0.5, p.z) + out * 0.02, out, w, h, arched, depth)

## Gothic lancet `w` x `h` (to the point) standing on `o` (bottom centre on
## the wall face): splayed jambs, a pointed two-centred head of voussoirs,
## glass set back, a mullion and a transom.
static func lancet(lm: LandmarkMesh, frame: String, glass: String, o: Vector3, out: Vector3, w: float,
		h: float, depth: float = 0.3, mullion: bool = true) -> void:
	var n := out.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	var fw := clampf(w * 0.16, 0.12, 0.45)
	var hw := w * 0.5
	var spring := h - w * 0.87
	var mid := o + n * depth * 0.5
	for s in [-1.0, 1.0]:
		lm.box(frame, mid + r * (hw + fw * 0.5) * float(s) + Vector3(0, spring * 0.5, 0),
			Vector3(fw, spring, depth), basis, 0.0)
	lm.box(frame, o + n * depth * 0.6 - Vector3(0, fw * 0.3, 0), Vector3(w + fw * 2.6, fw * 0.6, depth * 1.2),
		basis, 0.0)
	# Two arcs of radius w (centred on the opposite jamb) meeting at the point.
	var sp := o + Vector3(0, spring, 0)
	var ring := hw + fw * 0.5
	for s in [-1.0, 1.0]:
		var cen := sp - r * hw * float(s) + n * depth * 0.5
		var prev := sp + r * ring * float(s) + n * depth * 0.5
		for k in 5:
			var t := (float(k) + 1.0) / 5.0 * PI / 3.0
			var p := cen + (r * cos(t) * float(s) + Vector3.UP * sin(t)) * (w + fw * 0.5)
			if k == 4:
				p = sp + Vector3(0, w * 0.87 + fw * 0.45, 0) + n * depth * 0.5
			lm.beam(frame, prev, p, fw, depth, n)
			prev = p
	# Glass: the rectangle and the pointed head, then the tracery bars.
	var g := o + n * 0.03
	lm.quad(glass, g - r * hw, g + r * hw, g + r * hw + Vector3(0, spring, 0), g - r * hw + Vector3(0, spring, 0), n)
	var prev_l := g - r * hw + Vector3(0, spring, 0)
	var prev_r := g + r * hw + Vector3(0, spring, 0)
	var top := g + Vector3(0, h, 0)
	for k in 4:
		var t := (float(k) + 1.0) / 4.0 * PI / 3.0
		var pl := g + Vector3(0, spring, 0) + r * hw + (-r * cos(t) + Vector3.UP * sin(t)) * w
		var pr := g + Vector3(0, spring, 0) - r * hw + (r * cos(t) + Vector3.UP * sin(t)) * w
		if k == 3:
			pl = top
			pr = top
		lm.tri(glass, prev_l, pl, top, n, n, n, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		lm.tri(glass, prev_r, top, pr, n, n, n, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		lm.tri(glass, prev_l, top, prev_r, n, n, n, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		prev_l = pl
		prev_r = pr
	if mullion:
		var bar := clampf(w * 0.06, 0.05, 0.14)
		lm.box(frame, o + n * 0.07 + Vector3(0, h * 0.45, 0), Vector3(bar, h * 0.9, bar), basis, 0.0)
		lm.box(frame, o + n * 0.07 + Vector3(0, spring * 0.55, 0), Vector3(w, bar, bar), basis, 0.0)

## `n` lancets evenly along a..b with sills `y` up.
static func lancet_row(lm: LandmarkMesh, frame: String, glass: String, a: Vector3, b: Vector3, out: Vector3,
		y: float, n: int, w: float, h: float, depth: float = 0.3) -> void:
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lancet(lm, frame, glass, Vector3(p.x, y, p.z), out, w, h, depth)

## A wall skin with real recessed window openings over the run a..b from
## y0, `h` tall: `cols` x `rows` openings `win` (w, h), first sill `sill`
## above y0, storeys `storey` apart (LandmarkDetail.pierced_face, with the
## origin end picked so the skin always lands on the run itself).
static func pierce(lm: LandmarkMesh, wall: String, glass: String, a: Vector3, b: Vector3, out: Vector3,
		y0: float, h: float, cols: int, rows: int, win: Vector2, sill: float, storey: float,
		depth: float = 0.3) -> void:
	var n := out.normalized()
	var right := Vector3.UP.cross(n).normalized()
	var o := a
	if (b - a).dot(right) < 0.0:
		o = b
	LandmarkDetail.pierced_face(lm, wall, glass, Vector3(o.x, y0, o.z), right, n, a.distance_to(b), h,
		cols, rows, win, sill, storey, depth)

## `n` pilaster strips evenly from a to b (both ends included), `w` wide,
## projecting `proj`, from y0 up `h`.
static func strips(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, y0: float, h: float,
		n: int, w: float, proj: float) -> void:
	var o := out.normalized()
	var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
	for i in n:
		var t := float(i) / float(maxi(n - 1, 1))
		var p := a.lerp(b, t)
		lm.box(key, Vector3(p.x, y0 + h * 0.5, p.z) + o * proj * 0.5, Vector3(w, h, proj), basis)

## A string course (flat band) along a..b at y, `h` tall, projecting `proj`.
static func band(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, y: float, h: float,
		proj: float) -> void:
	var o := out.normalized()
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var m := (a + b) * 0.5
	lm.box(key, Vector3(m.x, y + h * 0.5, m.z) + o * proj * 0.5, Vector3(a.distance_to(b) + proj * 2.0, h, proj),
		basis)

## Bands round all four faces of an axis box (at y, h tall).
static func box_band(lm: LandmarkMesh, key: String, cx: float, cz: float, w: float, d: float, y: float,
		h: float, proj: float) -> void:
	lm.box(key, Vector3(cx, y + h * 0.5, cz), Vector3(w + proj * 2.0, h, d + proj * 2.0))

## Corbel-arch frieze under an eave along a..b: little round arches on
## corbels, `step` apart, `proj` deep, hanging from y (the arch crowns).
static func arch_frieze(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, y: float,
		step: float = 0.9, proj: float = 0.15) -> void:
	var o := out.normalized()
	var dir := (b - a).normalized()
	var n := maxi(int(a.distance_to(b) / step), 1)
	var s := a.distance_to(b) / float(n)
	var rad := s * 0.38
	var t := s * 0.18
	var basis := Basis(dir, Vector3.UP, o)
	for i in n:
		var c := a + dir * s * (float(i) + 0.5) + Vector3(0, y - rad, 0) + o * proj * 0.5
		var prev := c + dir * rad
		for k in 4:
			var ang := PI * float(k + 1) / 4.0
			var p := c + dir * rad * cos(ang) + Vector3(0, rad * sin(ang), 0)
			lm.beam(key, prev, p, t, proj, o)
			prev = p
		lm.box(key, a + dir * s * float(i) + Vector3(0, y - rad - t * 1.2, 0) + o * proj * 0.5,
			Vector3(t * 1.4, t * 2.4, proj), basis, 0.0)
	lm.box(key, (a + b) * 0.5 + Vector3(0, y + t * 0.5, 0) + o * proj * 0.6,
		Vector3(a.distance_to(b), t, proj * 1.2), basis, 0.0)

## Crow-stepped gable on a wall face: `steps` steps rising from width
## `w` at y0 to the top, `rise` tall, `thick` deep, centred at c (ground
## point on the face), facing out; each step capped by a coping slab.
static func crow_gable(lm: LandmarkMesh, key: String, cap: String, c: Vector3, out: Vector3, w: float,
		y0: float, rise: float, steps: int, thick: float) -> void:
	var o := out.normalized()
	var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
	var sh := rise / float(steps)
	for k in steps:
		var ww := w * (1.0 - float(k) / float(steps)) * 0.98 + 0.6
		lm.box(key, c + Vector3(0, y0 + sh * (float(k) + 0.5), 0), Vector3(ww, sh, thick), basis)
		var cw := ww / float(steps - k) * 0.5 + 0.2
		for s in [-1.0, 1.0]:
			lm.box(cap, c + basis.x * (ww * 0.5 - cw * 0.5) * float(s) + Vector3(0, y0 + sh * (float(k) + 1.0) + 0.06, 0),
				Vector3(cw + 0.1, 0.12, thick + 0.12), basis, 0.0)

## Onion dome with `ribs` raised ribs, radius r, height h, on a short
## neck; the gilded onions of the Orthodox churches.
static func onion(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, ribs: int = 8,
		seg: int = 16) -> void:
	var prof := PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.8, h * 0.06), Vector2(r * 0.97, h * 0.16),
		Vector2(r, h * 0.27), Vector2(r * 0.95, h * 0.38), Vector2(r * 0.78, h * 0.52), Vector2(r * 0.52, h * 0.65),
		Vector2(r * 0.28, h * 0.78), Vector2(r * 0.12, h * 0.9), Vector2(r * 0.05, h * 0.97), Vector2(0, h)])
	lm.lathe(key, base, prof, seg)
	var rw := clampf(r * 0.07, 0.04, 0.3)
	for i in ribs:
		var a := TAU * float(i) / float(ribs)
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			var p0 := base + d * (prof[j].x + rw * 0.3) + Vector3(0, prof[j].y, 0)
			var p1 := base + d * (prof[j + 1].x + rw * 0.3) + Vector3(0, prof[j + 1].y, 0)
			lm.beam(key, p0, p1, rw, rw * 0.6, d.cross(Vector3.UP))

## Orthodox cross of height h on a ball: shaft, three bars (the lowest
## slanted) and a ball at its foot.
static func orthodox_cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	var t := h * 0.05
	lm.lathe(key, base, LandmarkFhUtil.ball(h * 0.09), 10)
	var b := base + Vector3(0, h * 0.16, 0)
	var hh := h * 0.84
	lm.box(key, b + Vector3(0, hh * 0.5, 0), Vector3(t, hh, t), Basis(), 0.0)
	lm.box(key, b + Vector3(0, hh * 0.86, 0), Vector3(hh * 0.28, t, t), Basis(), 0.0)
	lm.box(key, b + Vector3(0, hh * 0.68, 0), Vector3(hh * 0.5, t, t), Basis(), 0.0)
	lm.box(key, b + Vector3(0, hh * 0.3, 0), Vector3(hh * 0.34, t, t), Basis(Vector3.FORWARD, 0.35), 0.0)

## Latin cross of height h (arms at two thirds).
static func latin_cross(lm: LandmarkMesh, key: String, base: Vector3, h: float, out: Vector3 = Vector3.FORWARD) -> void:
	var t := h * 0.08
	var basis := Basis(Vector3.UP.cross(out.normalized()).normalized(), Vector3.UP, out.normalized())
	lm.box(key, base + Vector3(0, h * 0.5, 0), Vector3(t, h, t), basis, 0.0)
	lm.box(key, base + Vector3(0, h * 0.68, 0), Vector3(h * 0.55, t, t), basis, 0.0)

## Round-headed blind arcade along a..b: `n` shallow arched niches from
## y0, `h` tall to the crown, sunk by drawing raised frames (pilasters and
## arches) `proj` proud of the wall.
static func arcade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, y0: float, h: float,
		n: int, proj: float = 0.15) -> void:
	var o := out.normalized()
	var dir := (b - a).normalized()
	var s := a.distance_to(b) / float(n)
	var pw := s * 0.18
	var rad := (s - pw) * 0.5
	var basis := Basis(dir, Vector3.UP, o)
	for i in n + 1:
		var p := a + dir * s * float(i) + o * proj * 0.5
		lm.box(key, p + Vector3(0, y0 + (h - rad) * 0.5, 0), Vector3(pw, h - rad, proj), basis, 0.0)
	for i in n:
		var c := a + dir * s * (float(i) + 0.5) + Vector3(0, y0 + h - rad, 0) + o * proj * 0.5
		var prev := c + dir * (rad + pw * 0.5)
		for k in 6:
			var ang := PI * float(k + 1) / 6.0
			var p := c + (dir * cos(ang) + Vector3.UP * sin(ang)) * (rad + pw * 0.5)
			lm.beam(key, prev, p, pw, proj, o)
			prev = p

## A moulded ring (window surround, rose frame) in the wall plane at c
## facing `normal`: an annulus r0..r1 standing `depth` proud, with its
## outer and inner edges.
static func ring(lm: LandmarkMesh, key: String, c: Vector3, normal: Vector3, r0: float, r1: float,
		depth: float = 0.2, seg: int = 16) -> void:
	var n := normal.normalized()
	var a := Vector3.UP.cross(n).normalized()
	if a == Vector3.ZERO:
		a = Vector3.RIGHT
	var b := n.cross(a)
	for i in seg:
		var t0 := TAU * float(i) / float(seg)
		var t1 := TAU * float(i + 1) / float(seg)
		var d0 := a * cos(t0) + b * sin(t0)
		var d1 := a * cos(t1) + b * sin(t1)
		var f := n * depth
		lm.quad(key, c + d0 * r0 + f, c + d1 * r0 + f, c + d1 * r1 + f, c + d0 * r1 + f, n)
		lm.quad(key, c + d0 * r1, c + d1 * r1, c + d1 * r1 + f, c + d0 * r1 + f, (d0 + d1).normalized())
		lm.quad(key, c + d0 * r0 + f, c + d1 * r0 + f, c + d1 * r0, c + d0 * r0, -(d0 + d1).normalized())

## Vertical ribs (marble fins, mullions) every `step` metres along a..b,
## `w` wide and `proj` proud of the wall, from y0 to y1.
static func ribs(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, y0: float, y1: float,
		step: float, w: float, proj: float) -> void:
	var o := out.normalized()
	var n := maxi(int(a.distance_to(b) / step), 1)
	var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box(key, Vector3(p.x, (y0 + y1) * 0.5, p.z) + o * proj * 0.5, Vector3(w, y1 - y0, proj), basis, 0.0)

## Outward unit normal of polygon edge i (XZ polygon, either winding).
static func edge_out(poly: PackedVector2Array, i: int) -> Vector3:
	var cw := 0.0
	for k in poly.size():
		var p := poly[k]
		var q := poly[(k + 1) % poly.size()]
		cw += p.x * q.y - q.x * p.y
	var e := poly[(i + 1) % poly.size()] - poly[i]
	var n := Vector2(e.y, -e.x).normalized() * (1.0 if cw > 0.0 else -1.0)
	return Vector3(n.x, 0, n.y)

## Sloped roof skirt from polygon `poly` at y0 up to the same outline
## scaled by `s` about `cen` at y1 (a hipped/mansard roof over any
## outline), capped flat at y1.
static func slope_roof(lm: LandmarkMesh, key: String, poly: PackedVector2Array, cen: Vector2, s: float, y0: float,
		y1: float) -> void:
	var inner := PackedVector2Array()
	for p in poly:
		inner.append(cen + (p - cen) * s)
	for i in poly.size():
		var j := (i + 1) % poly.size()
		var o := edge_out(poly, i)
		var n := (o * (y1 - y0) + Vector3.UP * (poly[i] - inner[i]).length()).normalized()
		lm.quad(key, Vector3(poly[i].x, y0, poly[i].y), Vector3(poly[j].x, y0, poly[j].y),
			Vector3(inner[j].x, y1, inner[j].y), Vector3(inner[i].x, y1, inner[i].y), n)
	lm.poly_prism(key, inner, y1 - 0.02, y1)

## Centroid (vertex mean) of an XZ polygon.
static func centre(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	return c / float(poly.size())
