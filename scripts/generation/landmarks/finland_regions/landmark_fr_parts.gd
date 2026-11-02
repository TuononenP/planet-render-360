class_name LandmarkFrParts
extends RefCounted

## Architectural details of the finland_regions batch, in true metres on
## LandmarkMesh: framed openings with flat, round or pointed heads, stepped
## buttresses, the white blind niches of the Finnish medieval brick gables,
## gable walls, roof bargeboards and ridges, louvres, dormers, chimneys,
## log-corner ends, board battens, railings and rows of recessed windows.
## Like LandmarkFrKit every helper takes material KEYS opened by the caller.

const HEAD_FLAT := 0
const HEAD_ROUND := 1
const HEAD_POINTED := 2

## Outline of an opening w wide and h tall (to the apex), bottom-left
## first, round the head, ending bottom-right; (x across, y up).
static func outline(w: float, h: float, head: int) -> PackedVector2Array:
	var hw := w * 0.5
	var pts := PackedVector2Array()
	if head == HEAD_ROUND:
		var spring := maxf(h - hw, 0.0)
		pts.append(Vector2(-hw, 0.0))
		for i in 9:
			var t := PI - PI * float(i) / 8.0
			pts.append(Vector2(cos(t) * hw, spring + sin(t) * hw))
		pts.append(Vector2(hw, 0.0))
	elif head == HEAD_POINTED:
		var rise := w * 0.866
		var spring2 := maxf(h - rise, 0.0)
		pts.append(Vector2(-hw, 0.0))
		for i in 5:
			var t := PI - PI / 3.0 * float(i) / 4.0
			pts.append(Vector2(hw + cos(t) * w, spring2 + sin(t) * w))
		for i in range(1, 5):
			var t2 := PI / 3.0 - PI / 3.0 * float(i) / 4.0
			pts.append(Vector2(-hw + cos(t2) * w, spring2 + sin(t2) * w))
		pts.append(Vector2(hw, 0.0))
	else:
		pts.append_array([Vector2(-hw, 0.0), Vector2(-hw, h), Vector2(hw, h), Vector2(hw, 0.0)])
	return pts

## A framed opening on a wall face: `c` the bottom centre on the face,
## `normal` out of the wall, w x h with a flat, round or pointed head; the
## frame (or stone dressing) `fw` wide stands `proud` off the face, the
## glass (or a dark door leaf) sits in it, `bars` vertical mullions and a
## transom when tall. frame "" draws the glass only.
static func opening(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, normal: Vector3, w: float,
		h: float, head: int = HEAD_FLAT, fw: float = 0.18, proud: float = 0.12, bars: int = 0) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var pts := outline(w, h, head)
	var P := func(p: Vector2, d: float) -> Vector3:
		return c + r * p.x + Vector3.UP * p.y + n * d
	var mid := Vector2(0.0, h * 0.45)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		lm.tri(glass, P.call(mid, 0.03), P.call(a, 0.03), P.call(b, 0.03), n, n, n, mid, a, b)
	if frame == "":
		return
	# A door (opening at ground level) gets no sill and no frame below 0.
	var door := c.y < fw
	var last := pts.size() - 2
	for i in pts.size() - 1:
		var a2: Vector3 = P.call(pts[i], proud * 0.5)
		var b2: Vector3 = P.call(pts[i + 1], proud * 0.5)
		var ext := (b2 - a2).normalized() * fw * 0.5
		lm.beam(frame, a2 - (Vector3.ZERO if door and i == 0 else ext), b2 + (Vector3.ZERO if door and i == last else ext),
			proud, fw, n)
	# Sill: wider and deeper than the frame.
	if not door:
		lm.box(frame, c + n * proud * 0.6 - Vector3(0, fw * 0.4, 0), Vector3(w + fw * 2.6, fw * 0.8, proud * 1.2),
			Basis(r, Vector3.UP, n), 0.0)
	var top := h - (w * 0.5 if head == HEAD_ROUND else (w * 0.866 if head == HEAD_POINTED else 0.0))
	for k in bars:
		var x := -w * 0.5 + w * float(k + 1) / float(bars + 1)
		lm.box(frame, c + r * x + Vector3(0, top * 0.5, 0) + n * 0.06, Vector3(fw * 0.35, top, 0.08),
			Basis(r, Vector3.UP, n), 0.0)
	if top > w * 1.6:
		lm.box(frame, c + Vector3(0, top * 0.62, 0) + n * 0.06, Vector3(w, fw * 0.35, 0.08),
			Basis(r, Vector3.UP, n), 0.0)

## `count` openings spaced evenly between a and b (bottom-centre line of
## the openings on the wall face).
static func openings(lm: LandmarkMesh, frame: String, glass: String, a: Vector3, b: Vector3, normal: Vector3,
		count: int, w: float, h: float, head: int = HEAD_FLAT, fw: float = 0.18, proud: float = 0.12,
		bars: int = 0) -> void:
	for i in count:
		var t := (float(i) + 0.5) / float(count)
		opening(lm, frame, glass, a.lerp(b, t), normal, w, h, head, fw, proud, bars)

## A rectangle of facade between p0 and p1 (bottom corners on the mass
## face, y0 the bottom) with a grid of real recessed windows: a skin
## `depth` thick from LandmarkDetail.pierced_face.
static func facade(lm: LandmarkMesh, wall: String, glass: String, p0: Vector3, p1: Vector3, normal: Vector3,
		h: float, cols: int, rows: int, win: Vector2, sill: float, storey: float, depth: float = 0.3) -> void:
	var d := p1 - p0
	d.y = 0.0
	LandmarkDetail.pierced_face(lm, wall, glass, p0, d.normalized(), normal.normalized(), d.length(), h,
		cols, rows, win, sill, storey, depth)

## Stepped buttress against a wall: foot centre `foot` on the wall face,
## projecting along `out`, w wide, d deep at the foot, h tall, `steps`
## set-backs each with a sloped weathering.
static func buttress(lm: LandmarkMesh, key: String, foot: Vector3, out: Vector3, w: float, d: float, h: float,
		steps: int = 2) -> void:
	var o := Vector3(out.x, 0, out.z).normalized()
	var r := Vector3.UP.cross(o).normalized()
	var basis := Basis(r, Vector3.UP, o)
	var stage_h := h / float(steps)
	for s in steps:
		var dd := d * (1.0 - 0.35 * float(s))
		var y0 := stage_h * float(s)
		var body := stage_h * 0.82
		lm.box(key, foot + Vector3(0, y0 + body * 0.5, 0) + o * dd * 0.5, Vector3(w, body, dd), basis)
		wedge(lm, key, foot + Vector3(0, y0 + body, 0), o, w, dd, stage_h - body + dd * 0.35)

## Sloped weathering: a wedge w wide on the wall face at `base`, running
## `d` out along `o` and rising `rise` at the wall.
static func wedge(lm: LandmarkMesh, key: String, base: Vector3, o: Vector3, w: float, d: float,
		rise: float) -> void:
	var r := Vector3.UP.cross(o).normalized() * w * 0.5
	var up := Vector3(0, rise, 0)
	var f := o * d
	var nt := (o * rise + Vector3.UP * d).normalized()
	lm.quad(key, base - r + f, base + r + f, base + r + up, base - r + up, nt)
	lm.quad(key, base - r + f, base + r + f, base + r, base - r, Vector3.DOWN)
	for s: float in [-1.0, 1.0]:
		var e: Vector3 = r * s
		var sn: Vector3 = e.normalized()
		lm.tri(key, base + e, base + e + f, base + e + up, sn, sn, sn, Vector2.ZERO, Vector2(d, 0), Vector2(0, -rise))

## A triangular gable wall `t` thick: base centre `c` (eave level, on the
## gable's face line), `along` the eave direction, `normal` out, w wide and
## `rise` to the apex.
static func gable_wall(lm: LandmarkMesh, key: String, c: Vector3, along: Vector3, normal: Vector3, w: float,
		rise: float, t: float) -> void:
	var a := along.normalized() * w * 0.5
	var n := normal.normalized()
	var top := Vector3(0, rise, 0)
	for s: float in [0.0, 1.0]:
		var off: Vector3 = -n * t * s
		var fn: Vector3 = n if s == 0.0 else -n
		lm.tri(key, c - a + off, c + a + off, c + top + off, fn, fn, fn, Vector2(0, 0), Vector2(w, 0),
			Vector2(w * 0.5, -rise))
	var sl := (a.normalized() * rise + Vector3.UP * w * 0.5).normalized()
	lm.quad(key, c + a, c + top, c + top - n * t, c + a - n * t, sl)
	var sl2 := (-a.normalized() * rise + Vector3.UP * w * 0.5).normalized()
	lm.quad(key, c - a, c + top, c + top - n * t, c - a - n * t, sl2)

## White blind niches in a brick or stone gable (the Finnish medieval
## gable ornament): tall panels set on the gable face whose heights
## follow the raking edges, a top cross niche, and a row of round-headed
## small niches along the base. `c` base centre on the face.
static func gable_niches(lm: LandmarkMesh, key: String, c: Vector3, normal: Vector3, w: float, rise: float,
		count: int = 5) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	var pitch := w * 0.78 / float(count)
	var nw := pitch * 0.55
	for i in count:
		var x := -w * 0.39 + pitch * (float(i) + 0.5)
		var top := rise * (1.0 - absf(x) / (w * 0.5)) - rise * 0.2 - nw * 0.6
		var y0 := rise * 0.12
		if top - y0 < nw:
			continue
		lm.box(key, c + r * x + Vector3(0, (y0 + top) * 0.5, 0) + n * 0.03, Vector3(nw, top - y0, 0.06), basis, 0.0)
		# Pointed head over each niche.
		lm.tri(key, c + r * (x - nw * 0.5) + Vector3(0, top, 0) + n * 0.03,
			c + r * (x + nw * 0.5) + Vector3(0, top, 0) + n * 0.03,
			c + r * x + Vector3(0, top + nw * 0.7, 0) + n * 0.03, n, n, n,
			Vector2(0, 0), Vector2(nw, 0), Vector2(nw * 0.5, -nw * 0.7))
	# Band of small niches along the base and a cross niche near the apex.
	lm.box(key, c + Vector3(0, rise * 0.06, 0) + n * 0.03, Vector3(w * 0.8, rise * 0.03, 0.06), basis, 0.0)
	var cy := rise * 0.78
	lm.box(key, c + Vector3(0, cy, 0) + n * 0.04, Vector3(nw * 0.35, rise * 0.12, 0.07), basis, 0.0)
	lm.box(key, c + Vector3(0, cy + rise * 0.02, 0) + n * 0.04, Vector3(nw * 1.1, nw * 0.3, 0.07), basis, 0.0)

## Bargeboards, eave fascias and ridge board of a LandmarkFrKit.gable roof
## over the same rectangle (same y, rise, over and ridge rule).
static func roof_trim(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y: float,
		rise: float, over: float = 0.5, ridge_x: int = -1, bw: float = 0.3) -> void:
	var along_x := (ridge_x == 1) if ridge_x >= 0 else (x1 - x0 >= z1 - z0)
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	if along_x:
		var ea := x0 - over * 0.5
		var eb := x1 + over * 0.5
		lm.beam(key, Vector3(ea, y + rise + bw * 0.2, cz), Vector3(eb, y + rise + bw * 0.2, cz), bw, bw * 0.8,
			Vector3.FORWARD)
		for x in [ea, eb]:
			for zs in [z0 - over, z1 + over]:
				lm.beam(key, Vector3(x, y - bw * 0.3, zs), Vector3(x, y + rise, cz), bw * 1.4, bw * 0.5, Vector3.RIGHT)
		for zs2 in [z0 - over, z1 + over]:
			lm.beam(key, Vector3(ea, y - bw * 0.3, zs2), Vector3(eb, y - bw * 0.3, zs2), bw * 0.6, bw, Vector3.UP)
	else:
		var fa := z0 - over * 0.5
		var fb := z1 + over * 0.5
		lm.beam(key, Vector3(cx, y + rise + bw * 0.2, fa), Vector3(cx, y + rise + bw * 0.2, fb), bw, bw * 0.8,
			Vector3.RIGHT)
		for z in [fa, fb]:
			for xs in [x0 - over, x1 + over]:
				lm.beam(key, Vector3(xs, y - bw * 0.3, z), Vector3(cx, y + rise, z), bw * 1.4, bw * 0.5, Vector3.BACK)
		for xs2 in [x0 - over, x1 + over]:
			lm.beam(key, Vector3(xs2, y - bw * 0.3, fa), Vector3(xs2, y - bw * 0.3, fb), bw * 0.6, bw, Vector3.UP)

## Horizontal louvre slats filling a w x h opening, bottom centre `c`.
static func louvre(lm: LandmarkMesh, key: String, c: Vector3, normal: Vector3, w: float, h: float,
		slats: int = 6) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	for k in slats:
		var y := h * (float(k) + 0.5) / float(slats)
		lm.box(key, c + Vector3(0, y, 0) + n * 0.05, Vector3(w, 0.06, h / float(slats) * 1.1),
			Basis(r, Vector3.UP, n) * Basis(Vector3.RIGHT, -0.7), 0.0)

## A gabled dormer standing on a roof: front face centre-bottom `c` (on
## the roof plane), facing `normal`, w wide, cheeks h tall, `depth` back
## into the roof, with a window.
static func dormer(lm: LandmarkMesh, wall: String, roof: String, glass: String, c: Vector3, normal: Vector3,
		w: float, h: float, depth: float) -> void:
	var n := Vector3(normal.x, 0, normal.z).normalized()
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	lm.box(wall, c + Vector3(0, h * 0.5, 0) - n * depth * 0.5, Vector3(w, h, depth), basis)
	lm.gable(roof, c + Vector3(0, h, 0) - n * depth * 0.5, w, depth, w * 0.45, Basis(r, Vector3.UP, n), 0.15, wall)
	opening(lm, wall, glass, c + Vector3(0, h * 0.18, 0) + n * 0.01, n, w * 0.5, h * 0.62, HEAD_FLAT, 0.08, 0.06, 1)

## Chimney stack from `base` (on or below the roof) to height `top`, with
## a corbelled cap and a cover slab.
static func chimney(lm: LandmarkMesh, key: String, base: Vector3, top: float, w: float, d: float = -1.0) -> void:
	var dd := w if d < 0.0 else d
	var h := top - base.y
	lm.box(key, base + Vector3(0, h * 0.5 - 0.3, 0), Vector3(w, h - 0.6, dd))
	lm.box(key, Vector3(base.x, top - 0.45, base.z), Vector3(w + 0.24, 0.3, dd + 0.24))
	lm.box(key, Vector3(base.x, top - 0.12, base.z), Vector3(w + 0.1, 0.24, dd + 0.1))

## Log ends crossing out of the corners of a log house (x0..x1, z0..z1),
## one pair per course from y0 to y1, sticking out `proj`.
static func log_corners(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y0: float,
		y1: float, course: float = 0.3, proj: float = 0.35) -> void:
	var n := int((y1 - y0) / course)
	for k in n:
		var y := y0 + course * (float(k) + 0.5)
		for x in [x0, x1]:
			for z in [z0, z1]:
				if k % 2 == 0:
					lm.box(key, Vector3(x, y, z + (proj * 0.5 if z == z1 else -proj * 0.5)),
						Vector3(course * 0.9, course * 0.92, proj + course), Basis(), 0.0)
				else:
					lm.box(key, Vector3(x + (proj * 0.5 if x == x1 else -proj * 0.5), y, z),
						Vector3(proj + course, course * 0.92, course * 0.9), Basis(), 0.0)

## Horizontal log courses on a wall face from a to b (bottom line): a thin
## rounded log every `course` metres up to h, proud of the face.
static func log_courses(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, normal: Vector3, h: float,
		course: float = 0.3) -> void:
	var n := normal.normalized()
	var y := course * 0.5
	while y < h:
		lm.beam(key, a + Vector3(0, y, 0) + n * 0.04, b + Vector3(0, y, 0) + n * 0.04, course * 0.7, 0.1, n)
		y += course

## Vertical board battens on a wall face from a to b (bottom line), h tall,
## one every `pitch` metres.
static func battens(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, normal: Vector3, h: float,
		pitch: float = 0.6, w: float = 0.08) -> void:
	var n := normal.normalized()
	var cnt := int(a.distance_to(b) / pitch)
	for i in cnt + 1:
		var p := a.lerp(b, float(i) / float(maxi(cnt, 1)))
		lm.beam(key, p + n * 0.03, p + Vector3(0, h, 0) + n * 0.03, w, 0.05, n.cross(Vector3.UP))

## Corner boards / pilaster strips at the four corners of a rectangle.
static func corner_strips(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y0: float,
		y1: float, w: float = 0.5, proud: float = 0.12) -> void:
	var ym := (y0 + y1) * 0.5
	for x: float in [x0, x1]:
		for z: float in [z0, z1]:
			var sx := -1.0 if x == x0 else 1.0
			var sz := -1.0 if z == z0 else 1.0
			lm.box(key, Vector3(x + sx * proud * 0.5, ym, z - sz * w * 0.5), Vector3(proud, y1 - y0, w), Basis(), 0.0)
			lm.box(key, Vector3(x - sx * w * 0.5, ym, z + sz * proud * 0.5), Vector3(w, y1 - y0, proud), Basis(), 0.0)

## A band (string course or cornice) round the rectangle at y, h tall,
## projecting `proj`.
static func band(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y: float, h: float,
		proj: float) -> void:
	LandmarkFrKit.rect(lm, key, x0 - proj, x1 + proj, z0 - proj, z1 + proj, y, y + h)

## Moulded eave cornice round the rectangle (LandmarkDetail.cornice on all
## four faces, no dentils).
static func cornice_ring(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y: float,
		h: float) -> void:
	var c := [Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1)]
	var outs := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
	for i in 4:
		LandmarkDetail.cornice(lm, key, c[i] as Vector3, c[(i + 1) % 4] as Vector3, outs[i] as Vector3, h, false)

## Railing from a to b: posts every `pitch`, top rail and a mid rail.
static func railing(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.1,
		pitch: float = 1.5, w: float = 0.06) -> void:
	var cnt := maxi(int(a.distance_to(b) / pitch), 1)
	for i in cnt + 1:
		var p := a.lerp(b, float(i) / float(cnt))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(w, h, w), Basis(), 0.0)
	lm.beam(key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), w * 1.4, w * 1.4)
	lm.beam(key, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), w, w)

## Round railing of radius r at height y about (cx, cz), `posts` posts.
static func ring_railing(lm: LandmarkMesh, key: String, c: Vector3, r: float, h: float = 1.1,
		posts: int = 32, w: float = 0.07) -> void:
	for i in posts:
		var a0 := TAU * float(i) / float(posts)
		var a1 := TAU * float(i + 1) / float(posts)
		var p0 := c + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := c + Vector3(cos(a1) * r, 0, sin(a1) * r)
		lm.box(key, p0 + Vector3(0, h * 0.5, 0), Vector3(w, h, w), Basis(), 0.0)
		lm.beam(key, p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), w * 1.4, w * 1.4)
		lm.beam(key, p0 + Vector3(0, h * 0.5, 0), p1 + Vector3(0, h * 0.5, 0), w, w)

## Ring of `count` openings round a polygonal or round shaft of radius r
## about (cx, cz): bottom at y, w x h, the first at angle a0.
static func ring_openings(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, r: float, count: int,
		w: float, h: float, head: int = HEAD_FLAT, a0: float = 0.0, fw: float = 0.15) -> void:
	for i in count:
		var a := a0 + TAU * float(i) / float(count)
		var n := Vector3(cos(a), 0, sin(a))
		opening(lm, frame, glass, c + n * r, n, w, h, head, fw, 0.1)

## Gun loops (narrow slits with a splayed stone surround) along a to b.
static func gun_loops(lm: LandmarkMesh, frame: String, dark: String, a: Vector3, b: Vector3, normal: Vector3,
		count: int, w: float = 0.35, h: float = 1.0) -> void:
	openings(lm, frame, dark, a, b, normal, count, w, h, HEAD_FLAT, 0.22, 0.1)

## Crenellated parapet along a to b (wall-top line): merlons with a coping.
static func parapet(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, t: float, h: float = 1.6,
		step: float = 2.6) -> void:
	var dir := b - a
	dir.y = 0.0
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	lm.beam(key, a + Vector3(0, h * 0.3, 0), b + Vector3(0, h * 0.3, 0), h * 0.6, t, Vector3.UP)
	var cnt := maxi(int(dir.length() / step), 1)
	for i in cnt:
		var p := a.lerp(b, (float(i) + 0.5) / float(cnt))
		lm.box(key, p + Vector3(0, h * 0.8, 0), Vector3(step * 0.55, h * 0.4, t), basis)
