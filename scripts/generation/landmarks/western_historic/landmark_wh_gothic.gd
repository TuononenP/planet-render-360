class_name LandmarkWhGothic
extends RefCounted

## Gothic and castle detail kits for the western historic batch, in true
## metres on LandmarkMesh: traceried windows standing proud of the wall
## (moulded frame, mullions, sub-arches, oculus, hood mould), traceried
## roses, crocketed pinnacles, stepped buttresses, gablets, pierced
## parapets, arrow slits and machicolation corbel tables. Plan frame as
## LandmarkWhKit: +X east, -Z north, y = 0 ground.

## Points of a pointed (two-centred, approximated as parabolic) arch
## centre line of half-width `hw` springing at height `y` (relative to
## `c`), rising `rise`, `n` segments a side: left springer to apex to
## right springer.
static func _arch_pts(c: Vector3, r: Vector3, hw: float, y: float, rise: float, n: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in n + 1:
		var s := float(i) / float(n)
		out.append(c - r * hw * (1.0 - s * s) + Vector3.UP * (y + rise * s))
	for i in range(n - 1, -1, -1):
		var s := float(i) / float(n)
		out.append(c + r * hw * (1.0 - s * s) + Vector3.UP * (y + rise * s))
	return out

## A moulding run through `pts`, `t` thick in the wall plane, `d` proud.
static func _run(lm: LandmarkMesh, key: String, pts: Array[Vector3], n: Vector3, t: float, d: float) -> void:
	for i in pts.size() - 1:
		lm.beam(key, pts[i] + n * d * 0.5, pts[i + 1] + n * d * 0.5, d, t, n)

## Traceried Gothic window on a wall face: bottom centre `c` on the face,
## outward normal `n`, opening w wide with h of straight jamb and a
## pointed head `head` high. Glass sits on the face; a moulded frame
## stands `fd` proud (jambs, pointed arch, sill), `lights` lights split
## by mullions under their own pointed heads with an oculus above, and a
## hood mould over the arch when `hood`.
static func window(lm: LandmarkMesh, glass: String, stone: String, c: Vector3, n: Vector3, w: float,
		h: float, head: float = -1.0, lights: int = 2, fd: float = 0.3, hood: bool = true) -> void:
	var hd := head if head >= 0.0 else w * 0.9
	var r := LandmarkWhKit.along(n)
	LandmarkWhKit.lancet(lm, glass, c + n * 0.03, n, w, h, hd)
	var fw := clampf(w * 0.09, 0.12, 0.55)
	var seg := 3 if w < 3.0 else 4
	# Frame: jambs and the arch round the opening, a sill with a drip.
	for s in [-1.0, 1.0]:
		var jb: Vector3 = c + r * float(s) * (w * 0.5 + fw * 0.5)
		lm.beam(stone, jb + n * fd * 0.5, jb + Vector3.UP * h + n * fd * 0.5, fd, fw, n)
	_run(lm, stone, _arch_pts(c, r, w * 0.5 + fw * 0.5, h, hd + fw * 0.5, seg), n, fw, fd)
	if c.y > fw:
		lm.box(stone, c + n * fd * 0.6 - Vector3.UP * fw * 0.4, Vector3(w + fw * 3.0, fw * 0.8, fd * 1.2),
			Basis(r, Vector3.UP, n), 0.0)
	if hood and w >= 2.0:
		_run(lm, stone, _arch_pts(c, r, w * 0.5 + fw * 1.6, h, hd + fw * 1.4, seg), n, fw * 0.6, fd * 0.7)
	if lights < 2:
		return
	# Mullions and the lights' own pointed heads.
	var lw := w / float(lights)
	var mt := fw * 0.55
	for i in range(1, lights):
		var mx: Vector3 = c - r * w * 0.5 + r * lw * float(i)
		lm.beam(stone, mx + n * fd * 0.35, mx + Vector3.UP * (h + hd * 0.12) + n * fd * 0.35, fd * 0.7, mt, n)
	for i in lights:
		var lc: Vector3 = c - r * w * 0.5 + r * lw * (float(i) + 0.5)
		_run(lm, stone, _arch_pts(lc, r, lw * 0.5, h, minf(hd * 0.42, lw * 0.9), 2), n, mt, fd * 0.7)
	# Oculus in the head.
	var orad := minf(w * 0.2, hd * 0.24)
	if orad > 0.15:
		var oc := c + Vector3.UP * (h + hd * 0.6)
		var ring: Array[Vector3] = []
		for k in 9:
			var a := TAU * float(k) / 8.0
			ring.append(oc + (r * cos(a) + Vector3.UP * sin(a)) * orad)
		_run(lm, stone, ring, n, mt, fd * 0.7)

## Row of `count` traceried windows along p0 -> p1 (ground points), sills
## at y0.
static func window_row(lm: LandmarkMesh, glass: String, stone: String, p0: Vector3, p1: Vector3, n: Vector3,
		count: int, w: float, h: float, y0: float, head: float = -1.0, lights: int = 2, fd: float = 0.3) -> void:
	for i in count:
		var p := p0.lerp(p1, (float(i) + 0.5) / float(count))
		window(lm, glass, stone, Vector3(p.x, y0, p.z) + n * 0.1, n, w, h, head, lights, fd)

## Traceried rose: glass disc, a moulded outer rim and surround, an inner
## ring, `spokes` radial mullions and a ring of foiled petals between.
static func rose(lm: LandmarkMesh, glass: String, stone: String, c: Vector3, n: Vector3, rad: float,
		spokes: int = 12) -> void:
	var a := LandmarkWhKit.along(n)
	lm.disc(glass, c + n * 0.03, n, rad, 32)
	var t := clampf(rad * 0.07, 0.15, 0.6)
	for ring in [[1.0, t * 1.2, 0.45], [1.12, t * 0.8, 0.3], [0.32, t, 0.35], [0.12, t * 0.8, 0.35]]:
		var rr: float = rad * float(ring[0])
		var pts: Array[Vector3] = []
		for k in 25:
			var th := TAU * float(k) / 24.0
			pts.append(c + (a * cos(th) + Vector3.UP * sin(th)) * rr)
		_run(lm, stone, pts, n, float(ring[1]), float(ring[2]))
	for k in spokes:
		var th := TAU * float(k) / float(spokes)
		var d := a * cos(th) + Vector3.UP * sin(th)
		lm.beam(stone, c + d * rad * 0.32 + n * 0.17, c + d * rad + n * 0.17, 0.34, t * 0.7, n)
		# A foiled petal (small ring) in each light between the spokes.
		var th2 := th + PI / float(spokes)
		var pc := c + (a * cos(th2) + Vector3.UP * sin(th2)) * rad * 0.68
		var pr := rad * minf(0.16, 1.4 / float(spokes))
		var pts: Array[Vector3] = []
		for j in 9:
			var b := TAU * float(j) / 8.0
			pts.append(pc + (a * cos(b) + Vector3.UP * sin(b)) * pr)
		_run(lm, stone, pts, n, t * 0.5, 0.25)

## Crocketed pinnacle: moulded base, shaft, a gablet on each face, a
## pyramid cap with crockets up its arrises and a cross-shaped finial.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, hw: float, shaft: float,
		cap: float) -> void:
	lm.box(key, base + Vector3(0, shaft * 0.07, 0), Vector3(hw * 2.4, shaft * 0.14, hw * 2.4))
	lm.box(key, base + Vector3(0, shaft * 0.5, 0), Vector3(hw * 2.0, shaft, hw * 2.0))
	var top := base + Vector3(0, shaft, 0)
	for f in 4:
		var bs := Basis(Vector3.UP, PI * 0.5 * float(f))
		lm.gable(key, top + bs.z * hw * 0.9 - Vector3(0, hw * 0.25, 0), hw * 1.9, hw * 0.5, hw * 1.3, bs, 0.0, key)
	lm.spire(key, top, hw * 1.15, cap)
	var ck := clampi(int(cap / maxf(hw * 1.2, 0.5)), 2, 3)
	for e in 4:
		var d := Vector3(cos(PI * 0.5 * float(e) + PI * 0.25), 0, sin(PI * 0.5 * float(e) + PI * 0.25)) * 1.414
		for j in ck:
			var t := (float(j) + 0.6) / float(ck + 0.5)
			var p := top + d * hw * 1.15 * (1.0 - t) + Vector3(0, cap * t, 0)
			lm.box(key, p + d * hw * 0.12, Vector3(hw * 0.32, hw * 0.28, hw * 0.32), Basis(Vector3.UP, PI * 0.25), 0.0)
	var tip := top + Vector3(0, cap, 0)
	lm.box(key, tip - Vector3(0, cap * 0.08, 0), Vector3(hw * 0.7, hw * 0.16, hw * 0.16), Basis(), 0.0)
	lm.box(key, tip - Vector3(0, cap * 0.08, 0), Vector3(hw * 0.16, hw * 0.16, hw * 0.7), Basis(), 0.0)

## Stepped buttress against a wall: foot at `base` (on the wall face),
## projecting along `out`, `w` wide, `d` deep at the foot, `h` high, with
## `steps` sloped set-offs (each stage shallower) and a weathered top.
static func buttress(lm: LandmarkMesh, key: String, base: Vector3, out: Vector3, w: float, d: float,
		h: float, steps: int = 3) -> void:
	var o := out.normalized()
	var bs := Basis(o.cross(Vector3.UP).normalized(), Vector3.UP, o)
	var y := 0.0
	for i in steps:
		var sh := h / float(steps)
		var dd := d * (1.0 - 0.28 * float(i))
		lm.box(key, base + o * dd * 0.5 + Vector3(0, y + sh * 0.5, 0), Vector3(w, sh, dd), bs)
		# Sloped weathering at the set-off.
		var nd := d * (1.0 - 0.28 * float(i + 1)) if i < steps - 1 else 0.0
		var y1 := y + sh
		var right := bs.x * w * 0.5
		var p0 := base + o * dd + Vector3(0, y1, 0)
		var p1 := base + o * nd + Vector3(0, y1 + (dd - nd) * 0.8, 0)
		lm.quad(key, p0 - right, p0 + right, p1 + right, p1 - right, (o + Vector3.UP).normalized())
		lm.tri(key, p0 - right, p1 - right, base + o * nd + Vector3(0, y1, 0) - right, -bs.x, -bs.x, -bs.x,
			Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		lm.tri(key, p0 + right, p1 + right, base + o * nd + Vector3(0, y1, 0) + right, bs.x, bs.x, bs.x,
			Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		y = y1

## Pierced parapet along a -> b (top of the wall, outer face line):
## coping, base rail and a row of small pointed openings (blind
## tracery panels) between posts every `pitch` metres.
static func parapet(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, h: float = 1.2,
		pitch: float = 1.2, t: float = 0.35) -> void:
	var dir := (b - a).normalized()
	var o := out.normalized()
	var bs := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5 + o * t * 0.5
	lm.box(key, mid + Vector3(0, h * 0.1, 0), Vector3(dl, h * 0.2, t), bs, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.92, 0), Vector3(dl + t, h * 0.16, t * 1.3), bs, 0.0)
	var cnt := maxi(int(dl / pitch), 1)
	for i in cnt + 1:
		var p := a.lerp(b, float(i) / float(cnt)) + o * t * 0.5
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(t * 0.6, h * 0.64, t), bs, 0.0)
	for i in cnt:
		var p := a.lerp(b, (float(i) + 0.5) / float(cnt)) + o * t * 0.5
		var pts: Array[Vector3] = []
		var hw := dl / float(cnt) * 0.5 - t * 0.3
		for k in 3:
			var s := float(k) / 2.0
			var x := -hw + 2.0 * hw * s
			pts.append(p + dir * x + Vector3(0, h * 0.55 + h * 0.28 * (1.0 - absf(x / hw) * absf(x / hw)), 0))
		_run(lm, key, pts, o, t * 0.4, t * 0.6)

## Machicolation corbels round a tower of radius `rad` at c.y, under
## the projecting crown ring the tower kit draws.
static func machicolation_ring(lm: LandmarkMesh, key: String, c: Vector3, rad: float, h: float = 1.6,
		pitch: float = 1.4) -> void:
	var cnt := maxi(int(TAU * rad / pitch), 8)
	for i in cnt:
		var a := TAU * (float(i) + 0.5) / float(cnt)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box(key, c + d * (rad + h * 0.2) + Vector3(0, h * 0.35, 0), Vector3(h * 0.35, h * 0.7, h * 0.45),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)

## Corbel table along a straight wall top a -> b, projecting along `out`.
static func machicolation_run(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3,
		h: float = 1.6, pitch: float = 1.4) -> void:
	var o := out.normalized()
	var dir := (b - a).normalized()
	var bs := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var cnt := maxi(int(a.distance_to(b) / pitch), 1)
	for i in cnt:
		var p := a.lerp(b, (float(i) + 0.5) / float(cnt))
		lm.box(key, p + o * h * 0.2 + Vector3(0, h * 0.35, 0), Vector3(h * 0.35, h * 0.7, h * 0.45), bs, 0.0)
	lm.box(key, (a + b) * 0.5 + o * h * 0.4 + Vector3(0, h * 0.85, 0), Vector3(a.distance_to(b), h * 0.3, h * 0.5),
		bs, 0.0)

## Arrow slit on a wall face: a dark slot `h` tall with a cross-oillet,
## on the face at `c` (centre) facing `n`.
static func slit(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, h: float = 2.2) -> void:
	var r := LandmarkWhKit.along(n)
	var bs := Basis(r, Vector3.UP, n)
	lm.box(key, c + n * 0.03, Vector3(0.18, h, 0.06), bs, 0.0)
	lm.box(key, c + n * 0.03, Vector3(0.7, 0.16, 0.06), bs, 0.0)

## Slits round a round tower of radius `rad`, `count` per ring at each
## height in `ys`, staggered ring to ring.
static func slit_ring(lm: LandmarkMesh, key: String, c: Vector3, rad: float, count: int, ys: Array,
		h: float = 2.0) -> void:
	var k := 0
	for y in ys:
		for i in count:
			var a := TAU * (float(i) + 0.5 * float(k % 2)) / float(count)
			var d := Vector3(cos(a), 0, sin(a))
			slit(lm, key, c + d * rad + Vector3(0, float(y), 0), d, h)
		k += 1

## Statue niche: a shallow pointed canopy over a figure on a corbel.
static func niche_statue(lm: LandmarkMesh, key: String, base: Vector3, n: Vector3, h: float) -> void:
	var r := LandmarkWhKit.along(n)
	var bs := Basis(r, Vector3.UP, n)
	lm.box(key, base + n * h * 0.1 - Vector3(0, h * 0.06, 0), Vector3(h * 0.4, h * 0.12, h * 0.25), bs, 0.0)
	jamb_figure(lm, key, base + n * h * 0.12, h)
	lm.gable(key, base + Vector3(0, h * 1.12, 0) + n * h * 0.12, h * 0.5, h * 0.3, h * 0.45,
		Basis(Vector3.UP, atan2(n.x, n.z)), 0.0, key)

## Small round window: glass disc in a moulded ring of `rad`, with a
## quatrefoil cross of two bars when `foiled`.
static func oculus(lm: LandmarkMesh, glass: String, stone: String, c: Vector3, n: Vector3, rad: float,
		foiled: bool = true) -> void:
	var a := LandmarkWhKit.along(n)
	lm.disc(glass, c + n * 0.03, n, rad, 16)
	var t := clampf(rad * 0.16, 0.1, 0.5)
	var pts: Array[Vector3] = []
	for k in 13:
		var th := TAU * float(k) / 12.0
		pts.append(c + (a * cos(th) + Vector3.UP * sin(th)) * rad)
	_run(lm, stone, pts, n, t, t * 1.4)
	if foiled:
		lm.beam(stone, c - a * rad + n * t * 0.5, c + a * rad + n * t * 0.5, t * 0.8, t * 0.6, n)
		lm.beam(stone, c - Vector3.UP * rad + n * t * 0.5, c + Vector3.UP * rad + n * t * 0.5, t * 0.8, t * 0.6, n)

## Moulded round archivolt (a cheap run of segments, not voussoir
## blocks) over an opening `span` wide springing at `c`, facing `n`.
static func archivolt(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, span: float, band: float = 0.4,
		depth: float = 0.3) -> void:
	var a := LandmarkWhKit.along(n)
	var rad := span * 0.5 + band * 0.5
	var pts: Array[Vector3] = []
	for k in 11:
		var th := PI * float(k) / 10.0
		pts.append(c + (a * cos(th) + Vector3.UP * sin(th)) * rad)
	_run(lm, key, pts, n, band, depth)
	lm.box(key, c + Vector3.UP * rad + n * depth * 0.6, Vector3(band * 0.9, band * 1.6, depth * 1.2),
		Basis(a, Vector3.UP, n), 0.0)

## Light balustrade along a -> b (both at the walking level): plinth,
## handrail and turned balusters (two-cone vases) every `pitch` metres.
static func balusters(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.0,
		pitch: float = 0.4) -> void:
	var dir := (b - a).normalized()
	var bs := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box(key, mid + Vector3(0, h * 0.07, 0), Vector3(dl, h * 0.14, h * 0.3), bs, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.93, 0), Vector3(dl, h * 0.14, h * 0.34), bs, 0.0)
	var cnt := maxi(int(dl / pitch), 1)
	for i in cnt:
		var p := a.lerp(b, (float(i) + 0.5) / float(cnt)) + Vector3(0, h * 0.14, 0)
		lm.lathe(key, p, PackedVector2Array([Vector2(h * 0.07, 0), Vector2(h * 0.11, h * 0.3),
			Vector2(h * 0.05, h * 0.65), Vector2(h * 0.08, h * 0.72)]), 6, 1.0, 1.0, 0.0, true, false)

## Slim jamb or niche figure of height h (the elongated column statues
## of Gothic portals): a robed body with fold ridges, sloping shoulders
## and a head, in a few hundred triangles rather than a full statue.
static func jamb_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(h * 0.11, 0), Vector2(h * 0.1, h * 0.3),
		Vector2(h * 0.085, h * 0.62), Vector2(h * 0.1, h * 0.74), Vector2(h * 0.05, h * 0.8)]), 8, 1.0, 0.8)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		lm.frustum(key, base + Vector3(cos(a), 0, sin(a) * 0.8) * h * 0.09, h * 0.02, h * 0.012, h * 0.6, 4)
	lm.lathe(key, base + Vector3(0, h * 0.8, 0), PackedVector2Array([Vector2(h * 0.03, 0), Vector2(h * 0.055, h * 0.05),
		Vector2(h * 0.05, h * 0.13), Vector2(0.0, h * 0.2)]), 8)
