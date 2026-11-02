class_name LandmarkRmLKit
extends RefCounted

## Facade detail for the later-Rome builders (true metres on
## LandmarkMesh): framed window grids cut into a wall skin, arcades of
## real round-arched openings, pilasters with bases and capitals,
## entablatures, light balustrades, pediments on any face, hipped roofs,
## obelisks on moulded pedestals and statue rows. Every helper takes the
## material keys to draw with; faces are given by an `origin` (bottom
## left of the area on the mass face), a unit `right` and the outward
## `normal`.

## Window grid cut into a skin laid over a mass face (see
## LandmarkDetail.pierced_face) with a frame round every opening: jambs,
## lintel, a projecting sill, and a head per `head`: 0 a cornice, 1 a
## triangular pediment, 2 alternating triangular and segmental
## pediments, 3 no head (plain architrave).
static func windows(lm: LandmarkMesh, wall: String, glass: String, frame: String, origin: Vector3,
		right: Vector3, normal: Vector3, w: float, h: float, cols: int, rows: int, win: Vector2,
		sill: float, storey: float, head: int = 0, skin: float = 0.35) -> void:
	LandmarkDetail.pierced_face(lm, wall, glass, origin, right, normal, w, h, cols, rows, win, sill, storey, skin)
	var r := right.normalized()
	var n := normal.normalized()
	var pitch := w / float(cols)
	for j in rows:
		var y := sill + storey * float(j)
		if y + win.y > h - 0.05:
			continue
		for i in cols:
			var c := origin + r * pitch * (float(i) + 0.5) + Vector3(0, y, 0) + n * skin
			var hd := head
			if head == 2:
				hd = 1 if i % 2 == 0 else 4
			frame_opening(lm, frame, c, r, n, win.x, win.y, hd)

## Frame round a rectangular opening whose bottom centre is `c` (on the
## wall face): jambs, lintel, sill and a head (0 cornice, 1 triangular
## pediment, 3 none, 4 segmental pediment).
static func frame_opening(lm: LandmarkMesh, key: String, c: Vector3, r: Vector3, n: Vector3,
		w: float, h: float, head: int = 0) -> void:
	var fw := clampf(w * 0.13, 0.14, 0.5)
	var d := 0.14
	var b := Basis(r, Vector3.UP, n)
	for s in [-1.0, 1.0]:
		lm.box(key, c + r * (w * 0.5 + fw * 0.5) * float(s) + Vector3(0, h * 0.5, 0) + n * d * 0.5,
			Vector3(fw, h, d), b, 0.0)
	lm.box(key, c + Vector3(0, h + fw * 0.5, 0) + n * d * 0.5, Vector3(w + fw * 2.0, fw, d), b, 0.0)
	lm.box(key, c + Vector3(0, -fw * 0.3, 0) + n * d, Vector3(w + fw * 2.6, fw * 0.6, d * 2.0), b, 0.0)
	var top := c + Vector3(0, h + fw, 0)
	match head:
		0:
			lm.box(key, top + Vector3(0, fw * 0.4, 0) + n * d, Vector3(w + fw * 3.0, fw * 0.8, d * 2.0), b, 0.0)
		1:
			lm.box(key, top + Vector3(0, fw * 0.3, 0) + n * d, Vector3(w + fw * 3.0, fw * 0.6, d * 2.0), b, 0.0)
			pediment(lm, key, top + Vector3(0, fw * 0.6, 0), r, n, w + fw * 3.0, w * 0.28, d * 2.0)
		4:
			lm.box(key, top + Vector3(0, fw * 0.3, 0) + n * d, Vector3(w + fw * 3.0, fw * 0.6, d * 2.0), b, 0.0)
			segment(lm, key, top + Vector3(0, fw * 0.6, 0), r, n, w + fw * 3.0, w * 0.22, fw * 0.6, d * 2.0)

## Triangular pediment prism on a face: `c` the centre of its base on the
## wall face, w wide, `rise` high, projecting `depth` along n; a raking
## cornice on both slopes.
static func pediment(lm: LandmarkMesh, key: String, c: Vector3, r: Vector3, n: Vector3, w: float,
		rise: float, depth: float, cornice: bool = false) -> void:
	var a := c - r * w * 0.5
	var b := c + r * w * 0.5
	var t := c + Vector3(0, rise, 0)
	var dn := n * depth
	lm.tri(key, a + dn, b + dn, t + dn, n, n, n, Vector2.ZERO, Vector2(w, 0), Vector2(w * 0.5, -rise))
	var sl := (Vector3.UP * w * 0.5 - r * rise).normalized()
	var sr := (Vector3.UP * w * 0.5 + r * rise).normalized()
	lm.quad(key, a, a + dn, t + dn, t, sl)
	lm.quad(key, t, t + dn, b + dn, b, sr)
	lm.quad(key, a, b, b + dn, a + dn, Vector3.DOWN)
	if cornice:
		var cw := maxf(rise * 0.09, 0.25)
		lm.beam(key, a - r * cw + Vector3(0, cw * 0.4, 0) + dn * 0.5, t + Vector3(0, cw * 0.9, 0) + dn * 0.5,
			cw, depth * 1.25, n)
		lm.beam(key, t + Vector3(0, cw * 0.9, 0) + dn * 0.5, b + r * cw + Vector3(0, cw * 0.4, 0) + dn * 0.5,
			cw, depth * 1.25, n)

## Segmental pediment: a shallow arc band `band` thick over a w span.
static func segment(lm: LandmarkMesh, key: String, c: Vector3, r: Vector3, n: Vector3, w: float,
		rise: float, band: float, depth: float) -> void:
	var rad := (w * w * 0.25 + rise * rise) / (2.0 * rise)
	var ctr := c + Vector3(0, rise - rad, 0) + n * depth * 0.5
	var half := asin(clampf(w * 0.5 / rad, -1.0, 1.0))
	var prev := Vector3.ZERO
	for i in 7:
		var a := -half + 2.0 * half * float(i) / 6.0
		var p := ctr + r * sin(a) * rad + Vector3(0, cos(a) * rad, 0)
		if i > 0:
			lm.beam(key, prev, p, band, depth, n)
		prev = p

## Wall face of `cols` round-arched openings, each `span` wide and
## springing at `spring` above origin, with real reveals `depth` deep and
## a dark back; the wall runs w x h from origin. Piers and spandrels are
## drawn in `wall`, the soffits too; `dark` closes the back.
static func arcade(lm: LandmarkMesh, wall: String, dark: String, origin: Vector3, right: Vector3,
		normal: Vector3, w: float, h: float, cols: int, span: float, spring: float, depth: float = 0.8,
		sill: float = 0.0) -> void:
	var r := right.normalized()
	var n := normal.normalized()
	var u := Vector3.UP
	var p := w / float(cols)
	var rad := span * 0.5
	var top := minf(h, spring + rad + maxf(p - span, 0.4) * 0.5 + 0.3)
	var segs := 10
	var half_k := 5
	var P := func(x: float, y: float, d: float) -> Vector3:
		return origin + r * x + u * y + n * d
	for i in cols:
		var x0 := p * float(i)
		var cx := x0 + p * 0.5
		var xl := cx - rad
		var xr := cx + rad
		# Piers (and the sill wall below the opening).
		lm.quad(wall, P.call(x0, 0.0, depth), P.call(xl, 0.0, depth), P.call(xl, spring, depth),
			P.call(x0, spring, depth), n)
		lm.quad(wall, P.call(xr, 0.0, depth), P.call(x0 + p, 0.0, depth), P.call(x0 + p, spring, depth),
			P.call(xr, spring, depth), n)
		if sill > 0.0:
			lm.quad(wall, P.call(xl, 0.0, depth), P.call(xr, 0.0, depth), P.call(xr, sill, depth),
				P.call(xl, sill, depth), n)
			lm.quad(wall, P.call(xl, sill, depth), P.call(xr, sill, depth), P.call(xr, sill, 0.0),
				P.call(xl, sill, 0.0), u)
		# Spandrels: fans from the top corners to the arch ring.
		var arc: Array[Vector2] = []
		for k in segs + 1:
			var a := PI - PI * float(k) / float(segs)
			arc.append(Vector2(cx + cos(a) * rad, spring + sin(a) * rad))
		lm.tri(wall, P.call(x0, spring, depth), P.call(xl, spring, depth), P.call(x0, top, depth), n, n, n,
			Vector2(x0, -spring), Vector2(xl, -spring), Vector2(x0, -top))
		lm.tri(wall, P.call(x0 + p, spring, depth), P.call(xr, spring, depth), P.call(x0 + p, top, depth), n, n, n,
			Vector2(x0 + p, -spring), Vector2(xr, -spring), Vector2(x0 + p, -top))
		for k in segs:
			var q0 := arc[k]
			var q1 := arc[k + 1]
			var corner := x0 if k < half_k else x0 + p
			lm.tri(wall, P.call(corner, top, depth), P.call(q0.x, q0.y, depth), P.call(q1.x, q1.y, depth),
				n, n, n, Vector2(corner, -top), Vector2(q0.x, -q0.y), Vector2(q1.x, -q1.y))
			# Soffit of the arch.
			var sn := (Vector3(0, 0, 0) - r * (q0.x + q1.x - 2.0 * cx) - u * (q0.y + q1.y - 2.0 * spring)).normalized()
			lm.quad(wall, P.call(q0.x, q0.y, depth), P.call(q1.x, q1.y, depth), P.call(q1.x, q1.y, 0.0),
				P.call(q0.x, q0.y, 0.0), sn)
		lm.tri(wall, P.call(x0, top, depth), P.call(cx, spring + rad, depth), P.call(x0 + p, top, depth), n, n, n,
			Vector2(x0, -top), Vector2(cx, -spring - rad), Vector2(x0 + p, -top))
		# Jambs and the dark back.
		var yb := sill
		lm.quad(wall, P.call(xl, yb, depth), P.call(xl, yb, 0.0), P.call(xl, spring, 0.0), P.call(xl, spring, depth), r)
		lm.quad(wall, P.call(xr, yb, 0.0), P.call(xr, yb, depth), P.call(xr, spring, depth), P.call(xr, spring, 0.0), -r)
		lm.quad(dark, P.call(xl, yb, 0.02), P.call(xr, yb, 0.02), P.call(xr, spring, 0.02), P.call(xl, spring, 0.02), n)
		for k in segs:
			lm.tri(dark, P.call(cx, spring, 0.02), P.call(arc[k].x, arc[k].y, 0.02), P.call(arc[k + 1].x, arc[k + 1].y, 0.02),
				n, n, n, Vector2(cx, -spring), Vector2(arc[k].x, -arc[k].y), Vector2(arc[k + 1].x, -arc[k + 1].y))
	# Wall above the arcade and the returns.
	if h > top + 0.01:
		lm.quad(wall, P.call(0.0, top, depth), P.call(w, top, depth), P.call(w, h, depth), P.call(0.0, h, depth), n)
	lm.quad(wall, P.call(0.0, 0.0, 0.0), P.call(0.0, 0.0, depth), P.call(0.0, h, depth), P.call(0.0, h, 0.0), -r)
	lm.quad(wall, P.call(w, 0.0, depth), P.call(w, 0.0, 0.0), P.call(w, h, 0.0), P.call(w, h, depth), r)
	lm.quad(wall, P.call(0.0, h, depth), P.call(w, h, depth), P.call(w, h, 0.0), P.call(0.0, h, 0.0), u)

## Archivolt over every opening of an arcade laid out like arcade(): a
## moulded band (a chain of `band`-wide segments standing `out` proud of
## the mass face) with a projecting keystone.
static func archivolts(lm: LandmarkMesh, key: String, origin: Vector3, right: Vector3, normal: Vector3,
		w: float, cols: int, span: float, spring: float, out: float, band: float = -1.0) -> void:
	var p := w / float(cols)
	var bw := band if band > 0.0 else clampf(span * 0.1, 0.2, 0.8)
	var rad := span * 0.5 + bw * 0.5
	var r := right.normalized()
	var n := normal.normalized()
	for i in cols:
		var c := origin + r * p * (float(i) + 0.5) + Vector3(0, spring, 0) + n * (out + 0.08)
		var prev := c - r * rad
		for k in 10:
			var a := PI - PI * float(k + 1) / 10.0
			var q := c + r * cos(a) * rad + Vector3(0, sin(a) * rad, 0)
			lm.beam(key, prev, q, bw, 0.16, n)
			prev = q
		lm.box(key, c + Vector3(0, rad, 0) + n * 0.06, Vector3(bw * 0.9, bw * 1.6, 0.3), Basis(r, Vector3.UP, n), 0.0)

## Pilaster on a face: plinth, shaft, moulded capital (Doric when
## `plain`, otherwise a deeper Corinthian block with a necking band).
static func pilaster(lm: LandmarkMesh, key: String, c: Vector3, r: Vector3, n: Vector3, w: float,
		h: float, proj: float, plain: bool = false) -> void:
	var b := Basis(r, Vector3.UP, n)
	var bh := minf(w * 0.6, h * 0.08)
	var ch := minf(w * (0.5 if plain else 1.0), h * 0.12)
	lm.box(key, c + Vector3(0, bh * 0.5, 0) + n * proj * 0.6, Vector3(w * 1.2, bh, proj * 1.2), b, 0.0)
	lm.box(key, c + Vector3(0, h * 0.5, 0) + n * proj * 0.5, Vector3(w, h - bh - ch, proj), b)
	lm.box(key, c + Vector3(0, h - ch * 0.5, 0) + n * proj * 0.6, Vector3(w * 1.12, ch * 0.7, proj * 1.2), b, 0.0)
	lm.box(key, c + Vector3(0, h - ch * 0.08, 0) + n * proj * 0.7, Vector3(w * 1.3, ch * 0.16, proj * 1.4), b, 0.0)
	if not plain:
		lm.box(key, c + Vector3(0, h - ch * 1.05, 0) + n * proj * 0.55, Vector3(w * 1.05, ch * 0.12, proj * 1.1), b, 0.0)

## Light column for small or distant orders (drums, lanterns, belfries):
## square plinth, torus, tapering 12-sided shaft, bell capital and
## abacus, h tall with lower radius r.
static func column_lite(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float) -> void:
	lm.box(key, base + Vector3(0, r * 0.25, 0), Vector3(r * 2.6, r * 0.5, r * 2.6), Basis(), 0.0)
	lm.frustum(key, base + Vector3(0, r * 0.5, 0), r * 1.2, r * 1.05, r * 0.4, 12)
	lm.frustum(key, base + Vector3(0, r * 0.9, 0), r, r * 0.85, h - r * 2.6, 12)
	lm.frustum(key, base + Vector3(0, h - r * 1.7, 0), r * 0.88, r * 1.2, r * 1.3, 12)
	lm.box(key, base + Vector3(0, h - r * 0.2, 0), Vector3(r * 2.7, r * 0.4, r * 2.7), Basis(), 0.0)

## Light Ionic column facing n: an Attic base, the tapering shaft, an
## echinus and the two volute scrolls (rolls with their spiral faces
## toward n and -n) under a thin abacus; h tall, lower radius r.
static func column_ionic(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, n: Vector3) -> void:
	var side := Vector3.UP.cross(n).normalized()
	lm.box(key, base + Vector3(0, r * 0.25, 0), Vector3(r * 2.6, r * 0.5, r * 2.6), Basis(side, Vector3.UP, n), 0.0)
	lm.lathe(key, base + Vector3(0, r * 0.5, 0), PackedVector2Array([Vector2(r * 1.25, 0.0), Vector2(r * 1.2, r * 0.2),
		Vector2(r * 1.05, r * 0.3), Vector2(r * 1.15, r * 0.45), Vector2(r * 1.0, r * 0.6)]), 12)
	lm.frustum(key, base + Vector3(0, r * 1.1, 0), r, r * 0.84, h - r * 2.1, 12)
	var cb := base + Vector3(0, h - r * 1.0, 0)
	lm.frustum(key, cb, r * 0.9, r * 1.08, r * 0.35, 12)
	for s in [-1.0, 1.0]:
		var vc := cb + side * r * 1.0 * float(s) + Vector3(0, r * 0.25, 0)
		lm.beam(key, vc - n * r * 0.9, vc + n * r * 0.9, r * 0.7, r * 0.7, side)
		for f in [-1.0, 1.0]:
			lm.disc(key, vc + n * r * 0.91 * float(f), n * float(f), r * 0.42, 10)
	lm.box(key, cb + Vector3(0, r * 0.5, 0), Vector3(r * 2.4, r * 0.3, r * 1.9), Basis(side, Vector3.UP, n), 0.0)
	lm.box(key, cb + Vector3(0, r * 0.85, 0), Vector3(r * 2.5, r * 0.3, r * 2.5), Basis(side, Vector3.UP, n), 0.0)

## Row of `count` pilasters (or pairs when `pair` > 0, that far apart)
## evenly spaced on a face from origin over width w (centres at the bay
## edges when `edges`, else bay centres).
static func pilaster_row(lm: LandmarkMesh, key: String, origin: Vector3, r: Vector3, n: Vector3,
		w: float, count: int, pw: float, h: float, proj: float, edges: bool = true, pair: float = 0.0) -> void:
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1)) if edges else (float(i) + 0.5) / float(count)
		var c := origin + r * w * t
		if pair > 0.0:
			for s in [-0.5, 0.5]:
				pilaster(lm, key, c + r * pair * float(s), r, n, pw, h, proj)
		else:
			pilaster(lm, key, c, r, n, pw, h, proj)

## Entablature along a-b on a face (a, b at its foot on the wall line):
## architrave, frieze and a moulded cornice, `h` tall in all.
static func entablature(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: Vector3, h: float,
		proj: float = 0.5, dentils: bool = false) -> void:
	var dir := (b - a).normalized()
	var bs := Basis(dir, Vector3.UP, n)
	var mid := (a + b) * 0.5
	var run := a.distance_to(b)
	lm.box(key, mid + Vector3(0, h * 0.17, 0) + n * proj * 0.5, Vector3(run, h * 0.34, proj), bs)
	lm.box(key, mid + Vector3(0, h * 0.5, 0) + n * proj * 0.4, Vector3(run, h * 0.32, proj * 0.8), bs)
	LandmarkDetail.cornice(lm, key, a + Vector3(0, h * 0.66, 0) + n * proj * 0.8,
		b + Vector3(0, h * 0.66, 0) + n * proj * 0.8, n, h * 0.34, dentils)

## Light balustrade along a-b (for long runs): plinth, handrail, square
## pedestals every `bay` metres and six-sided turned balusters.
static func balustrade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.0,
		bay: float = 3.5, pitch: float = -1.0) -> void:
	var dir := (b - a).normalized()
	var dl := a.distance_to(b)
	var bs := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	var w := h * 0.24
	lm.box(key, mid + Vector3(0, h * 0.07, 0), Vector3(dl, h * 0.14, w * 1.3), bs, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.92, 0), Vector3(dl, h * 0.16, w * 1.4), bs, 0.0)
	var piers := maxi(int(round(dl / bay)), 1)
	for i in piers + 1:
		lm.box(key, a.lerp(b, float(i) / float(piers)) + Vector3(0, h * 0.5, 0), Vector3(w * 1.6, h, w * 1.6), bs, 0.0)
	var pt := pitch if pitch > 0.0 else h * 0.5
	var vase := PackedVector2Array([Vector2(w * 0.3, 0), Vector2(w * 0.45, h * 0.25),
		Vector2(w * 0.2, h * 0.55), Vector2(w * 0.32, h * 0.7)])
	var seg := dl / float(piers)
	var per := maxi(int(seg / pt) - 1, 1)
	for i in piers:
		for k in per:
			var t := (float(i) + (float(k) + 1.0) / float(per + 1)) / float(piers)
			lm.lathe(key, a.lerp(b, t) + Vector3(0, h * 0.14, 0), vase, 5)

## Hipped roof over an sx x sz rectangle centred at `c` (eave level),
## rising `rise` to a ridge along the longer side.
static func hip_roof(lm: LandmarkMesh, key: String, c: Vector3, sx: float, sz: float, rise: float,
		over: float = 0.5) -> void:
	var hx := sx * 0.5 + over
	var hz := sz * 0.5 + over
	var e0 := c + Vector3(-hx, 0, -hz)
	var e1 := c + Vector3(hx, 0, -hz)
	var e2 := c + Vector3(hx, 0, hz)
	var e3 := c + Vector3(-hx, 0, hz)
	var along_x := sx >= sz
	var k := minf(hx, hz)
	var r0 := c + (Vector3(-(hx - k), rise, 0) if along_x else Vector3(0, rise, -(hz - k)))
	var r1 := c + (Vector3(hx - k, rise, 0) if along_x else Vector3(0, rise, hz - k))
	if along_x:
		lm.quad(key, e0, e1, r1, r0, Vector3(0, k, -rise).normalized())
		lm.quad(key, e2, e3, r0, r1, Vector3(0, k, rise).normalized())
		lm.tri(key, e3, e0, r0, Vector3.LEFT, Vector3.LEFT, Vector3.UP, Vector2.ZERO, Vector2(sz, 0), Vector2(sz * 0.5, -rise))
		lm.tri(key, e1, e2, r1, Vector3.RIGHT, Vector3.RIGHT, Vector3.UP, Vector2.ZERO, Vector2(sz, 0), Vector2(sz * 0.5, -rise))
	else:
		lm.quad(key, e3, e0, r0, r1, Vector3(-rise, k, 0).normalized())
		lm.quad(key, e1, e2, r1, r0, Vector3(rise, k, 0).normalized())
		lm.tri(key, e0, e1, r0, Vector3.FORWARD, Vector3.FORWARD, Vector3.UP, Vector2.ZERO, Vector2(sx, 0), Vector2(sx * 0.5, -rise))
		lm.tri(key, e2, e3, r1, Vector3.BACK, Vector3.BACK, Vector3.UP, Vector2.ZERO, Vector2(sx, 0), Vector2(sx * 0.5, -rise))

## Obelisk on a moulded pedestal standing on `base`: a stepped plinth,
## the die with base and cap mouldings (`ped_h` in all), the shaft of
## `h` metres (hw half width at the foot) and its pyramidion, then a
## bronze star or cross of `top` metres in `top_key`.
static func obelisk(lm: LandmarkMesh, key: String, ped: String, top_key: String, base: Vector3,
		ped_h: float, h: float, hw: float, top: float) -> void:
	var pw := hw * 2.0 * 1.7
	var s := ped_h / 10.0
	lm.box(ped, base + Vector3(0, s * 0.6, 0), Vector3(pw * 1.7, s * 1.2, pw * 1.7))
	lm.box(ped, base + Vector3(0, s * 1.8, 0), Vector3(pw * 1.45, s * 1.2, pw * 1.45))
	lm.box(ped, base + Vector3(0, s * 3.0, 0), Vector3(pw * 1.25, s * 1.2, pw * 1.25))
	lm.box(ped, base + Vector3(0, s * 6.0, 0), Vector3(pw, s * 4.8, pw))
	lm.box(ped, base + Vector3(0, s * 8.7, 0), Vector3(pw * 1.18, s * 0.6, pw * 1.18))
	lm.box(ped, base + Vector3(0, s * 9.3, 0), Vector3(pw * 1.08, s * 0.6, pw * 1.08))
	# Bronze feet: four astragal blocks under the shaft.
	for k in 4:
		var d := Vector3(1, 0, 0).rotated(Vector3.UP, PI * 0.5 * float(k) + PI * 0.25) * hw * 0.9
		lm.box(top_key, base + d + Vector3(0, ped_h + s * 0.25, 0), Vector3(hw * 0.5, s * 0.5, hw * 0.5))
	var sb := base + Vector3(0, ped_h + s * 0.5, 0)
	lm.spire(key, sb, hw, h * 0.92, hw * 0.72)
	lm.spire(key, sb + Vector3(0, h * 0.92, 0), hw * 0.72, h * 0.08)
	var tb := sb + Vector3(0, h, 0)
	lm.lathe(top_key, tb, PackedVector2Array([Vector2(top * 0.1, 0), Vector2(top * 0.16, top * 0.12),
		Vector2(top * 0.1, top * 0.24), Vector2(top * 0.04, top * 0.3)]), 8)
	lm.box(top_key, tb + Vector3(0, top * 0.65, 0), Vector3(top * 0.07, top * 0.7, top * 0.07))
	lm.box(top_key, tb + Vector3(0, top * 0.78, 0), Vector3(top * 0.36, top * 0.07, top * 0.07))
	# A star of rays round the cross foot (the Chigi / papal star).
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.beam(top_key, tb + Vector3(0, top * 0.42, 0), tb + Vector3(cos(a) * top * 0.18, top * 0.42 + sin(a) * top * 0.18, 0),
			top * 0.04, top * 0.04)

## `count` statues `h` tall on a line a..b (inclusive), each on a small
## pedestal block in `ped` when ped != "".
static func statue_row(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, count: int, h: float,
		ped: String = "") -> void:
	for i in count:
		var p := a.lerp(b, float(i) / float(maxi(count - 1, 1)))
		var y := 0.0
		if ped != "":
			lm.box(ped, p + Vector3(0, h * 0.09, 0), Vector3(h * 0.32, h * 0.18, h * 0.32))
			y = h * 0.18
		LandmarkKits.statue_figure(lm, key, p + Vector3(0, y, 0), h, i % 3 == 1)

## Corner quoins up a vertical edge: alternating long and short blocks
## from y0 to y1 on the two faces meeting at `corner` (n1, n2 outward).
static func quoins(lm: LandmarkMesh, key: String, corner: Vector3, n1: Vector3, n2: Vector3,
		y0: float, y1: float, block: float = 1.2) -> void:
	var count := int((y1 - y0) / block)
	for i in count:
		var y := y0 + block * (float(i) + 0.5)
		var l1 := 1.6 if i % 2 == 0 else 0.9
		var l2 := 2.5 - l1
		lm.box(key, corner + Vector3(0, y, 0) - n2 * l1 * 0.5 + n1 * 0.08, Vector3(l1, block * 0.86, 0.16),
			Basis(n2, Vector3.UP, n1), 0.0)
		lm.box(key, corner + Vector3(0, y, 0) - n1 * l2 * 0.5 + n2 * 0.08, Vector3(l2, block * 0.86, 0.16),
			Basis(n1, Vector3.UP, n2), 0.0)
