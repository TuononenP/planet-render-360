class_name SEuParts
extends RefCounted

## Mid-scale detail parts for the south europe landmarks (true metres on
## LandmarkMesh), light enough to repeat hundreds of times on one model:
## recessed openings with a moulded surround, light classical columns,
## arcades, Gothic pinnacles, small statues and stepped plinths.
## SEuUtil is shared with other batches; new helpers live here.

const RECT := 0
const ROUND := 1
const POINTED := 2
const HORSESHOE := 3

## Outline (u across, v up) of an opening w wide and h tall standing on
## v = 0, from the bottom of the left jamb round the head to the bottom
## of the right jamb.
static func outline(w: float, h: float, shape: int, steps: int = 8) -> PackedVector2Array:
	var hw := w * 0.5
	var p := PackedVector2Array()
	match shape:
		ROUND:
			var hr := maxf(h - hw, 0.05)
			p.append(Vector2(-hw, 0))
			for k in steps + 1:
				var a := PI - PI * float(k) / float(steps)
				p.append(Vector2(cos(a) * hw, hr + sin(a) * hw))
		POINTED:
			var rise := w * 0.866
			var hr := maxf(h - rise, 0.05)
			p.append(Vector2(-hw, 0))
			var half := steps / 2
			for k in half + 1:
				var phi := PI / 3.0 * float(k) / float(half)
				p.append(Vector2(hw - w * cos(phi), hr + w * sin(phi)))
			for k in range(half - 1, -1, -1):
				var phi := PI / 3.0 * float(k) / float(half)
				p.append(Vector2(-hw + w * cos(phi), hr + w * sin(phi)))
		HORSESHOE:
			# A circle swept 30 degrees past the half round each side: it
			# swells wider than the jambs and returns in to meet them.
			var beta := deg_to_rad(30.0)
			var rr := hw / cos(beta)
			var cy := maxf(h - rr, rr * sin(beta) + 0.05)
			p.append(Vector2(-hw, 0))
			for k in steps + 1:
				var a := PI + beta - (PI + 2.0 * beta) * float(k) / float(steps)
				p.append(Vector2(cos(a) * rr, cy + sin(a) * rr))
		_:
			p.append(Vector2(-hw, 0))
			p.append(Vector2(-hw, h))
			p.append(Vector2(hw, h))
	p.append(Vector2(hw, 0))
	return p

## Recessed opening on a wall face: the dark back of the opening flush
## with the face at `o` (bottom centre), and a moulded surround standing
## `depth` proud of the wall, `band` wide, with its reveal running back
## into the opening, so the opening reads deep from any angle. `out` is
## the face normal; shape RECT / ROUND / POINTED / HORSESHOE. A sill
## block closes the bottom when `sill`.
static func niche(lm: LandmarkMesh, frame: String, dark: String, o: Vector3, out: Vector3,
		w: float, h: float, shape: int = ROUND, depth: float = 0.35, band: float = -1.0,
		sill: bool = true) -> void:
	var n := out.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var u := Vector3.UP
	var bw := band if band > 0.0 else clampf(w * 0.12, 0.12, 1.2)
	var pts := outline(w, h, shape, 8 if w < 3.0 else 12)
	var P := func(q: Vector2, d: float) -> Vector3:
		return o + r * q.x + u * q.y + n * d
	# Dark back, fanned from the middle of the opening.
	var ctr := Vector2(0, h * 0.45)
	for i in pts.size() - 1:
		lm.tri(dark, P.call(ctr, 0.02), P.call(pts[i], 0.02), P.call(pts[i + 1], 0.02), n, n, n,
			ctr, pts[i], pts[i + 1])
	lm.tri(dark, P.call(ctr, 0.02), P.call(pts[pts.size() - 1], 0.02), P.call(pts[0], 0.02), n, n, n,
		ctr, pts[pts.size() - 1], pts[0])
	# Per-vertex outward offsets of the outline.
	var offs: Array[Vector2] = []
	for i in pts.size():
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, pts.size() - 1)]
		var e := (b - a).normalized()
		var nn := Vector2(-e.y, e.x)
		if nn.dot(pts[i] - ctr) < 0.0:
			nn = -nn
		if i == 0 or i == pts.size() - 1:
			nn = Vector2(signf(pts[i].x), 0)
		offs.append(nn * bw)
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var ao := a + offs[i]
		var bo := b + offs[i + 1]
		var inward := -(Vector3(0, 0, 0) + r * (offs[i].x + offs[i + 1].x) + u * (offs[i].y + offs[i + 1].y)).normalized()
		lm.quad(frame, P.call(a, 0.0), P.call(b, 0.0), P.call(b, depth), P.call(a, depth), inward)
		lm.quad(frame, P.call(a, depth), P.call(b, depth), P.call(bo, depth), P.call(ao, depth), n)
		lm.quad(frame, P.call(ao, depth), P.call(bo, depth), P.call(bo, 0.0), P.call(ao, 0.0), -inward)
	if sill:
		var sw := w + bw * 2.6
		lm.box(frame, o + n * depth * 0.6 - u * bw * 0.25, Vector3(sw, bw * 0.5, depth * 1.2),
			Basis(r, u, n), 0.0)

## Light classical column of height h, lower radius r: square plinth, a
## torus base, a tapering shaft and a capital. style "tuscan" (echinus
## and abacus) or "corinthian" (flared bell with leaf rings and a
## concave abacus) or "plain" (Romanesque cushion capital).
static func col(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		style: String = "tuscan", seg: int = 10) -> void:
	var bh := r * 0.7
	var ch := r * (2.2 if style == "corinthian" else 0.9)
	lm.box(key, base + Vector3(0, bh * 0.2, 0), Vector3(r * 2.5, bh * 0.4, r * 2.5), Basis(), 0.0)
	lm.lathe(key, base + Vector3(0, bh * 0.4, 0), PackedVector2Array([Vector2(r * 1.2, 0),
		Vector2(r * 1.25, bh * 0.25), Vector2(r * 1.1, bh * 0.5), Vector2(r, bh * 0.6)]), seg, 1.0, 1.0,
		0.0, true, false)
	var sh := h - bh - ch
	var sb := base + Vector3(0, bh, 0)
	lm.lathe(key, sb, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.97, sh * 0.5),
		Vector2(r * 0.85, sh)]), seg, 1.0, 1.0, 0.0, true, false)
	var cb := sb + Vector3(0, sh, 0)
	match style:
		"corinthian":
			lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.95, 0), Vector2(r * 1.12, ch * 0.18),
				Vector2(r * 0.98, ch * 0.32), Vector2(r * 1.2, ch * 0.5), Vector2(r * 1.08, ch * 0.62),
				Vector2(r * 1.38, ch * 0.84)]), seg, 1.0, 1.0, 0.0, true, false)
			lm.box(key, cb + Vector3(0, ch * 0.92, 0), Vector3(r * 2.9, ch * 0.16, r * 2.9), Basis(), 0.0)
		"plain":
			lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.88, 0), Vector2(r * 1.1, ch * 0.5),
				Vector2(r * 1.3, ch * 0.75)]), seg, 1.0, 1.0, 0.0, true, false)
			lm.box(key, cb + Vector3(0, ch * 0.87, 0), Vector3(r * 2.7, ch * 0.26, r * 2.7), Basis(), 0.0)
		_:
			lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.88, 0), Vector2(r * 0.95, ch * 0.15),
				Vector2(r * 1.25, ch * 0.5), Vector2(r * 1.3, ch * 0.7)]), seg, 1.0, 1.0, 0.0, true, false)
			lm.box(key, cb + Vector3(0, ch * 0.85, 0), Vector3(r * 2.6, ch * 0.3, r * 2.6), Basis(), 0.0)

## Arch ring (archivolt) as a chain of beams: a round (or pointed) arch
## spanning `span` between springing points either side of `c` along
## `right`, `band` wide (in the wall plane) and `depth` deep along `out`.
static func arch_ring(lm: LandmarkMesh, key: String, c: Vector3, right: Vector3, out: Vector3,
		span: float, band: float, depth: float, pointed: bool = false, steps: int = 6) -> void:
	var r := right.normalized()
	var n := out.normalized()
	var pts := outline(span + band, (span + band) * (0.866 if pointed else 0.5), POINTED if pointed else ROUND,
		steps)
	for i in range(1, pts.size() - 2):
		var a := c + r * pts[i].x + Vector3.UP * pts[i].y
		var b := c + r * pts[i + 1].x + Vector3.UP * pts[i + 1].y
		lm.beam(key, a, b, depth, band, n)

## Gothic pinnacle on `base`: a square shaft w wide with a gablet on each
## face, a needle spire with crockets up its arrises and a finial knob;
## h tall overall. The statue key, when set, stands a figure on the tip
## (Milan's spires each carry a saint).
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float,
		statue_key: String = "") -> void:
	var shaft_h := h * 0.38
	lm.box(key, base + Vector3(0, shaft_h * 0.5, 0), Vector3(w, shaft_h, w), Basis(), 0.0)
	var top := base + Vector3(0, shaft_h, 0)
	for k in 4:
		var bas := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := bas * Vector3(0, 0, 1)
		var rt := bas * Vector3(1, 0, 0)
		var e := top + out * (w * 0.52)
		var nrm := out
		lm.tri(key, e - rt * w * 0.5, e + rt * w * 0.5, e + Vector3(0, w * 0.9, 0), nrm, nrm, nrm,
			Vector2.ZERO, Vector2(w, 0), Vector2(w * 0.5, -w * 0.9))
	var sp_h := h - shaft_h - (w * 0.6 if statue_key != "" else 0.0)
	lm.spire(key, top, w * 0.5, sp_h, 0.0)
	var n_cr := clampi(int(sp_h / maxf(w * 0.9, 0.3)), 2, 6)
	for i in n_cr:
		var t := (float(i) + 0.6) / float(n_cr + 1)
		var hw := w * 0.5 * (1.0 - t)
		for k in 4:
			var a := PI * 0.25 + PI * 0.5 * float(k)
			var d := Vector3(cos(a), 0, sin(a))
			lm.box(key, top + d * (hw * 1.414 + w * 0.06) + Vector3(0, sp_h * t, 0),
				Vector3(w * 0.14, w * 0.18, w * 0.14), Basis(Vector3.UP, -a), 0.0)
	if statue_key != "":
		figure(lm, statue_key, top + Vector3(0, sp_h - w * 0.1, 0), w * 1.6)

## Small standing statue h tall (for rooflines and colonnade tops): one
## lathe for robe, torso and head, and two arms; about 120 triangles.
static func figure(lm: LandmarkMesh, key: String, base: Vector3, h: float, arm_up: bool = false,
		yaw: float = 0.0) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(h * 0.16, 0), Vector2(h * 0.15, h * 0.1),
		Vector2(h * 0.12, h * 0.42), Vector2(h * 0.1, h * 0.55), Vector2(h * 0.12, h * 0.72),
		Vector2(h * 0.06, h * 0.8), Vector2(h * 0.045, h * 0.84), Vector2(h * 0.06, h * 0.9),
		Vector2(h * 0.045, h * 0.97), Vector2(0.0, h)]), 7, 1.0, 0.8, yaw, true, true)
	var bas := Basis(Vector3.UP, -yaw)
	for s in [-1.0, 1.0]:
		var sh: Vector3 = base + bas * Vector3(float(s) * h * 0.12, h * 0.72, 0)
		var hand: Vector3
		if arm_up and float(s) > 0.0:
			hand = sh + bas * Vector3(h * 0.06, h * 0.26, 0)
		else:
			hand = sh + bas * Vector3(float(s) * h * 0.04, -h * 0.26, h * 0.06)
		lm.beam(key, sh, hand, h * 0.06, h * 0.06)

## Stepped plinth (crepidoma) of `n` steps, each `rise` tall and `tread`
## deep, the top step w x d, centred on `c` at ground.
static func steps_block(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, n: int,
		rise: float, tread: float) -> void:
	for k in n:
		var g := tread * float(n - 1 - k)
		lm.box(key, c + Vector3(0, rise * (float(k) + 0.5), 0), Vector3(w + g * 2.0, rise, d + g * 2.0))

## Ring of `n` round arches on columns round a circle of radius r about
## `c` (both at the column bases): columns h tall, arches springing from
## their tops; the arches are beams so a gallery reads open.
static func arcade_ring(lm: LandmarkMesh, col_key: String, arch_key: String, c: Vector3, r: float,
		n: int, h: float, cr: float, start: float = 0.0, style: String = "corinthian", seg: int = 8) -> void:
	for i in n:
		var a := start + TAU * float(i) / float(n)
		col(lm, col_key, c + Vector3(cos(a), 0, sin(a)) * r, cr, h, style, seg)
	var span := TAU * r / float(n)
	for i in n:
		var a := start + TAU * (float(i) + 0.5) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		arch_ring(lm, arch_key, c + d * r * cos(PI / float(n)) + Vector3(0, h, 0), Vector3.UP.cross(d), d,
			span - cr * 2.0, cr * 0.9, cr * 1.6, false, 4)

## Open arcade wall: the masonry over `n` arches between a and b (both on
## the springing line, the wall face facing `out`), `thick` deep, from
## the springing up to `top` above it. Each bay's opening is `open_w`
## wide (ROUND or POINTED); the piers between are left solid down to the
## springing so the caller stands columns or piers under them. Front,
## back, the arch soffits and the end returns are drawn, so it reads
## open from every side.
static func arcade_wall(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, n: int,
		open_w: float, top: float, thick: float, shape: int = ROUND) -> void:
	var r := (b - a).normalized()
	var u := Vector3.UP
	var nn := out.normalized()
	var length := a.distance_to(b)
	var pitch := length / float(n)
	var hw := open_w * 0.5
	var pts := outline(open_w, open_w * (0.866 if shape == POINTED else 0.5) + 0.02, shape, 8)
	var P := func(x: float, y: float, d: float) -> Vector3:
		return a + r * x + u * y + nn * d
	for i in n:
		var cx := pitch * (float(i) + 0.5)
		for side in [0.0, -thick]:
			var d: float = side
			var fn := nn if d == 0.0 else -nn
			for k in pts.size() - 1:
				var p := pts[k]
				var q := pts[k + 1]
				if q.x - p.x < 0.0005:
					continue
				lm.quad(key, P.call(cx + p.x, p.y, d), P.call(cx + q.x, q.y, d), P.call(cx + q.x, top, d),
					P.call(cx + p.x, top, d), fn, Vector2(cx + p.x, -top))
			lm.quad(key, P.call(cx - pitch * 0.5, 0.0, d), P.call(cx - hw, 0.0, d), P.call(cx - hw, top, d),
				P.call(cx - pitch * 0.5, top, d), fn)
			lm.quad(key, P.call(cx + hw, 0.0, d), P.call(cx + pitch * 0.5, 0.0, d), P.call(cx + pitch * 0.5, top, d),
				P.call(cx + hw, top, d), fn)
		for k in pts.size() - 1:
			var p := pts[k]
			var q := pts[k + 1]
			var mid := (p + q) * 0.5
			var inward := -(r * mid.x + u * (mid.y - pts[1].y)).normalized()
			lm.quad(key, P.call(cx + p.x, p.y, 0.0), P.call(cx + q.x, q.y, 0.0), P.call(cx + q.x, q.y, -thick),
				P.call(cx + p.x, p.y, -thick), inward)
		# Pier soffits (underside of the solid between openings).
		lm.quad(key, P.call(cx - pitch * 0.5, 0.0, 0.0), P.call(cx - hw, 0.0, 0.0), P.call(cx - hw, 0.0, -thick),
			P.call(cx - pitch * 0.5, 0.0, -thick), -u)
		lm.quad(key, P.call(cx + hw, 0.0, 0.0), P.call(cx + pitch * 0.5, 0.0, 0.0),
			P.call(cx + pitch * 0.5, 0.0, -thick), P.call(cx + hw, 0.0, -thick), -u)
	lm.quad(key, P.call(0.0, 0.0, 0.0), P.call(0.0, top, 0.0), P.call(0.0, top, -thick), P.call(0.0, 0.0, -thick), -r)
	lm.quad(key, P.call(length, 0.0, 0.0), P.call(length, top, 0.0), P.call(length, top, -thick),
		P.call(length, 0.0, -thick), r)
	lm.quad(key, P.call(0.0, top, 0.0), P.call(length, top, 0.0), P.call(length, top, -thick),
		P.call(0.0, top, -thick), u)

## Quatrefoil roundel (four lobes round a centre) on a face at `c`,
## facing `out`, `r` across each lobe pair.
static func quatrefoil(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, r: float) -> void:
	var n := out.normalized()
	var rt := Vector3.UP.cross(n).normalized()
	for k in 4:
		var a := PI * 0.5 * float(k) + PI * 0.25
		lm.disc(key, c + (rt * cos(a) + Vector3.UP * sin(a)) * r * 0.42, n, r * 0.4, 8)

## Light balustrade along a-b (both on its base line): plinth, handrail,
## square dies every `bay` metres and six-sided vase balusters between
## (a quarter of LandmarkDetail.balustrade's triangles, for long runs
## seen from afar).
static func rail(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.1, bay: float = 4.0) -> void:
	var dir := (b - a).normalized()
	var dl := a.distance_to(b)
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	var w := h * 0.24
	lm.box(key, mid + Vector3(0, h * 0.06, 0), Vector3(dl, h * 0.12, w * 1.2), basis, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.93, 0), Vector3(dl, h * 0.14, w * 1.4), basis, 0.0)
	var vase := PackedVector2Array([Vector2(w * 0.3, 0), Vector2(w * 0.45, h * 0.3),
		Vector2(w * 0.18, h * 0.62), Vector2(w * 0.3, h * 0.74)])
	var n := int(dl / (h * 0.36))
	var piers := maxi(int(dl / bay), 1)
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		var slot := fmod(t * piers, 1.0)
		if slot < 0.06 or slot > 0.94:
			continue
		lm.lathe(key, a.lerp(b, t) + Vector3(0, h * 0.12, 0), vase, 6, 1.0, 1.0, 0.0, true, false)
	for i in piers + 1:
		lm.box(key, a.lerp(b, float(i) / float(piers)) + Vector3(0, h * 0.5, 0), Vector3(w * 1.6, h, w * 1.6), basis, 0.0)
