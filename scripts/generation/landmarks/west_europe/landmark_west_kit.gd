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

## Points of a pointed (equilateral) arch of span w springing at y = 0,
## left to right in the (x, y) plane; `steps` per side.
static func pointed_pts(w: float, steps: int = 5, sharp: float = 1.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	var r := w * sharp
	var xc := r - w * 0.5
	var a1 := acos(-xc / r)
	for i in steps + 1:
		var a := PI - (PI - a1) * float(i) / float(steps)
		p.append(Vector2(xc + r * cos(a), r * sin(a)))
	for i in range(steps - 1, -1, -1):
		var q := p[i]
		p.append(Vector2(-q.x, q.y))
	return p

## Gothic lancet window: an opening w x h (to the arch apex) centred on
## `c` (bottom centre on the wall face facing `n`): moulded jambs and a
## pointed hood, glass set back, a central mullion and, when `tracery`,
## a pierced roundel in the head over two sub-lights.
static func lancet(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, n: Vector3, w: float,
		h: float, tracery: bool = true, depth: float = 0.3) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var spring := h - w * 0.87
	var fw := clampf(w * 0.12, 0.12, 0.5)
	var basis := Basis(r, Vector3.UP, nn)
	for s in [-1.0, 1.0]:
		lm.box(frame, c + r * (w * 0.5 + fw * 0.5) * float(s) + Vector3(0, spring * 0.5, 0) + nn * depth * 0.5,
			Vector3(fw, spring, depth), basis, 0.0)
	var pts := pointed_pts(w + fw, 5)
	var top := c + Vector3(0, spring, 0) + nn * depth * 0.5
	for i in pts.size() - 1:
		lm.beam(frame, top + r * pts[i].x + Vector3(0, pts[i].y, 0), top + r * pts[i + 1].x + Vector3(0, pts[i + 1].y, 0),
			fw, depth, nn)
	# Glass: the rectangle and the pointed head as a fan.
	var g := c + nn * 0.03
	lm.quad(glass, g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + Vector3(0, spring, 0),
		g - r * w * 0.5 + Vector3(0, spring, 0), nn)
	var gp := pointed_pts(w, 5)
	var gc := g + Vector3(0, spring, 0)
	for i in gp.size() - 1:
		lm.tri(glass, gc, gc + r * gp[i].x + Vector3(0, gp[i].y, 0), gc + r * gp[i + 1].x + Vector3(0, gp[i + 1].y, 0),
			nn, nn, nn, Vector2.ZERO, gp[i], gp[i + 1])
	if tracery and w > 1.2:
		var mw := fw * 0.6
		lm.box(frame, c + Vector3(0, spring * 0.5 + w * 0.15, 0) + nn * 0.12, Vector3(mw, spring + w * 0.3, 0.2), basis, 0.0)
		var rc := c + Vector3(0, spring + w * 0.42, 0) + nn * 0.12
		var rr := w * 0.22
		for i in 8:
			var a0 := TAU * float(i) / 8.0
			var a1 := TAU * float(i + 1) / 8.0
			lm.beam(frame, rc + (r * cos(a0) + Vector3.UP * sin(a0)) * rr, rc + (r * cos(a1) + Vector3.UP * sin(a1)) * rr,
				mw, 0.2, nn)

## Gothic pinnacle on `base`: square shaft 2*hw wide, four gablets, an
## octagonal crocketed needle and a finial; total height h.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, hw: float, h: float) -> void:
	var sh := h * 0.4
	lm.box(key, base + Vector3(0, sh * 0.5, 0), Vector3(hw * 2.0, sh, hw * 2.0))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.gable(key, base + Vector3(0, sh, 0) + b * Vector3(0, 0, hw * 0.5), hw * 2.0, hw, hw * 1.4, b, 0.0)
	var nb := base + Vector3(0, sh, 0)
	var nh := h - sh
	lm.spire(key, nb, hw * 0.8, nh * 0.94, 0.0, 8)
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		for j in 3:
			var t := 0.2 + 0.25 * float(j)
			lm.box(key, nb + d * hw * 0.8 * (1.0 - t) * 1.08 + Vector3(0, nh * 0.94 * t, 0),
				Vector3(hw * 0.35, hw * 0.25, hw * 0.35), Basis(Vector3.UP, -a), 0.0)
	lm.box(key, nb + Vector3(0, nh * 0.97, 0), Vector3(hw * 0.5, nh * 0.06, hw * 0.15), Basis(), 0.0)
	lm.box(key, nb + Vector3(0, nh * 0.97, 0), Vector3(hw * 0.15, nh * 0.06, hw * 0.5), Basis(), 0.0)

## Stepped buttress standing on `base`, projecting along `out` from the
## wall: w wide, d deep at the foot, h tall, with `steps` sloped set-offs.
static func buttress(lm: LandmarkMesh, key: String, base: Vector3, out: Vector3, w: float, d: float,
		h: float, steps: int = 2) -> void:
	var o := out.normalized()
	var b := Basis(o.cross(Vector3.UP).normalized(), Vector3.UP, o)
	var y := 0.0
	for k in steps + 1:
		var dk := d * (1.0 - 0.28 * float(k))
		var hk := h / float(steps + 1)
		lm.box(key, base + o * dk * 0.5 + Vector3(0, y + hk * 0.5, 0), Vector3(w, hk, dk), b)
		# Sloped weathering at each set-off.
		var top := base + Vector3(0, y + hk, 0)
		var dn := d * (1.0 - 0.28 * float(k + 1)) if k < steps else 0.0
		lm.quad(key, top + o * dk - b.x * w * 0.5, top + o * dk + b.x * w * 0.5,
			top + o * dn + b.x * w * 0.5 + Vector3(0, w * 0.5, 0), top + o * dn - b.x * w * 0.5 + Vector3(0, w * 0.5, 0),
			(o + Vector3.UP).normalized())
		y += hk

## Flying buttress: an arched flyer from the pier top `a` up to the
## clerestory wall `b`, w wide, with a straight coping on top.
static func flyer(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float, segs: int = 5) -> void:
	var span := Vector3(b.x - a.x, 0, b.z - a.z)
	var dir := span.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var prev := a
	for i in segs:
		var t := float(i + 1) / float(segs)
		var p := a.lerp(b, t) - Vector3(0, sin(PI * t) * span.length() * 0.18 + (1.0 - t) * 0.0, 0)
		lm.beam(key, prev, p, w, w * 0.9, side)
		prev = p
	lm.beam(key, a + Vector3(0, w * 0.9, 0), b + Vector3(0, w * 0.6, 0), w * 0.8, w * 0.5, side)

## Rose window of radius r on a wall facing n: glass disc, moulded outer
## ring, `spokes` radiating mullions, an inner ring and a ring of
## roundels between the spokes.
static func rose(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, n: Vector3, r: float,
		spokes: int = 12) -> void:
	var nn := n.normalized()
	var u := nn.cross(Vector3.UP if absf(nn.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := nn.cross(u)
	lm.disc(glass, c, nn, r, 32)
	var ring := func(rr: float, bw: float, d: float, seg: int) -> void:
		for i in seg:
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			lm.beam(frame, c + (u * cos(a0) + v * sin(a0)) * rr + nn * d * 0.5,
				c + (u * cos(a1) + v * sin(a1)) * rr + nn * d * 0.5, bw, d, nn)
	ring.call(r * 1.04, r * 0.1, 0.5, 32)
	ring.call(r * 0.32, r * 0.06, 0.3, 16)
	for i in spokes:
		var a := TAU * float(i) / float(spokes)
		var d := u * cos(a) + v * sin(a)
		lm.beam(frame, c + d * r * 0.32 + nn * 0.15, c + d * r + nn * 0.15, r * 0.04, 0.3, nn)
		var a2 := a + PI / float(spokes)
		var rc := c + (u * cos(a2) + v * sin(a2)) * r * 0.7 + nn * 0.15
		var rr := r * 0.16
		for k in 6:
			var b0 := TAU * float(k) / 6.0
			var b1 := TAU * float(k + 1) / 6.0
			lm.beam(frame, rc + (u * cos(b0) + v * sin(b0)) * rr, rc + (u * cos(b1) + v * sin(b1)) * rr,
				r * 0.03, 0.25, nn)

## Recessed portal: `rings` receding archivolts (pointed when `pointed`,
## else round) round a door w wide, h to the apex, cut into a wall facing
## n at bottom centre c; door leaf at the back, tympanum above it.
static func portal(lm: LandmarkMesh, key: String, door: String, c: Vector3, n: Vector3, w: float,
		h: float, rings: int = 4, pointed: bool = true) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var basis := Basis(r, Vector3.UP, nn)
	var band := w * 0.08
	for k in rings:
		var wk := w + band * 2.0 * float(k)
		var dk := band * 1.2 * float(k + 1)
		var spring := h - (wk * 0.87 if pointed else wk * 0.5) + band * float(k) * 0.4
		var base := c + nn * dk
		for s in [-1.0, 1.0]:
			lm.frustum(key, base + r * (wk * 0.5 + band * 0.5) * float(s), band * 0.45, band * 0.42, spring, 6)
		var pts: PackedVector2Array
		if pointed:
			pts = pointed_pts(wk + band, 5)
		else:
			pts = PackedVector2Array()
			for i in 11:
				var a := PI - PI * float(i) / 10.0
				pts.append(Vector2(cos(a), sin(a)) * (wk + band) * 0.5)
		var top := base + Vector3(0, spring, 0)
		for i in pts.size() - 1:
			lm.beam(key, top + r * pts[i].x + Vector3(0, pts[i].y, 0), top + r * pts[i + 1].x + Vector3(0, pts[i + 1].y, 0),
				band, band, nn)
	var lintel := h * 0.55
	lm.box(door, c + Vector3(0, lintel * 0.5, 0) + nn * 0.05, Vector3(w, lintel, 0.1), basis, 0.0)
	lm.box(key, c + Vector3(0, lintel * 0.5, 0) + nn * 0.3, Vector3(band * 0.8, lintel, band), basis, 0.0)
	lm.box(key, c + Vector3(0, lintel + band * 0.5, 0) + nn * 0.2, Vector3(w, band, band * 2.0), basis, 0.0)

## Ogee / bell cap profile (radius, y): swells, pinches, ends in a point.
static func ogee_prof(r: float, h: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	var pts := [[1.0, 0.0], [1.06, 0.1], [1.0, 0.25], [0.8, 0.42], [0.5, 0.58], [0.3, 0.72], [0.18, 0.85],
		[0.08, 0.95], [0.0, 1.0]]
	for q in pts:
		p.append(Vector2(r * float(q[0]), h * float(q[1])))
	return p

## Roof dormer on a roof plane: a small front wall w x h with a window,
## cheeks back into the roof and a little gabled roof; `c` is the bottom
## centre of the front, facing n.
static func dormer(lm: LandmarkMesh, wall: String, roof: String, glass: String, c: Vector3, n: Vector3,
		w: float, h: float, d: float = 2.0) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var b := Basis(r, Vector3.UP, nn)
	lm.box(wall, c + Vector3(0, h * 0.5, 0) - nn * d * 0.5, Vector3(w, h, d), b)
	lm.box(glass, c + Vector3(0, h * 0.45, 0) + nn * 0.02, Vector3(w * 0.55, h * 0.6, 0.05), b, 0.0)
	lm.gable(roof, c + Vector3(0, h, 0) - nn * d * 0.5, w, d, w * 0.45, b, 0.15, wall)

## Chimney stack w x d x h standing on `base` with a cap and two pots.
static func chimney(lm: LandmarkMesh, key: String, base: Vector3, w: float, d: float, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.5, 0), Vector3(w, h, d))
	lm.box(key, base + Vector3(0, h + 0.15, 0), Vector3(w + 0.3, 0.3, d + 0.3))
	for s in [-1.0, 1.0]:
		lm.frustum(key, base + Vector3(float(s) * w * 0.25, h + 0.3, 0), 0.18, 0.15, 0.6, 6)

## Rough standing stone: an irregular, slightly bulging 7-sided block
## w x d at the foot, h tall, tapered and rounded on top; `seed`
## varies the facets.
static func rough_stone(lm: LandmarkMesh, key: String, base: Vector3, w: float, d: float, h: float,
		yaw: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var prof := PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.03, h * 0.15), Vector2(1.04, h * 0.35),
		Vector2(1.0, h * 0.55), Vector2(0.95, h * 0.72), Vector2(0.88, h * 0.85), Vector2(0.74, h * 0.94),
		Vector2(0.48, h * 0.99), Vector2(0.0, h)])
	var sides := 7
	var rows: Array = []
	for j in prof.size():
		var ring := PackedVector3Array()
		for i in sides + 1:
			var a := TAU * float(i % sides) / float(sides)
			rng.seed = seed * 31 + (i % sides) * 7 + j
			var jit := 1.0 + rng.randf_range(-0.12, 0.12) if j < prof.size() - 1 else 1.0
			var lx := cos(a) * w * 0.5 * prof[j].x * jit
			var lz := sin(a) * d * 0.5 * prof[j].x * jit
			ring.append(base + Basis(Vector3.UP, yaw) * Vector3(lx, prof[j].y, lz))
		rows.append(ring)
	lm.grid(key, rows, base + Vector3(0, h * 0.4, 0), true)

## Classical facade bay run: along p0 -> p1 (wall face line at y = p0.y)
## facing n, `bays` windows per storey at heights `sills` (window sill
## heights) with sizes `sizes` (Vector2 per storey, y < 0 marks arched),
## pilasters between bays from y0 to y0 + ph when ph > 0.
static func bay_run(lm: LandmarkMesh, frame: String, glass: String, p0: Vector3, p1: Vector3, n: Vector3,
		bays: int, sills: Array, sizes: Array, ph: float = 0.0, pw: float = 0.9) -> void:
	var nn := n.normalized()
	var r := (p1 - p0).normalized()
	var b := Basis(r, Vector3.UP, nn)
	for i in bays:
		var p := p0.lerp(p1, (float(i) + 0.5) / float(bays))
		for k in sills.size():
			var s: Vector2 = sizes[k]
			var hh := absf(s.y)
			LandmarkDetail.window(lm, frame, glass, p + Vector3(0, float(sills[k]) + hh * 0.5, 0), nn, s.x, hh, s.y < 0.0)
	if ph > 0.0:
		for i in bays + 1:
			var p := p0.lerp(p1, float(i) / float(bays))
			lm.box(frame, p + Vector3(0, ph * 0.5, 0) + nn * 0.2, Vector3(pw, ph, 0.4), b)

## Light parapet railing along a-b: posts every `step` metres under a
## moulded coping, h tall.
static func rail(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.0,
		step: float = 1.2) -> void:
	merlons(lm, key, a, b, step, 0.22, h, 0.22)
	lm.beam(key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), 0.35, 0.18)
	lm.beam(key, a + Vector3(0, 0.08, 0), b + Vector3(0, 0.08, 0), 0.3, 0.16)

## Small statue seen from afar (a niche saint, a king, an apostle): a
## robed body tapering to the shoulders and a head, h tall on `base`.
static func figure(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(h * 0.16, 0), Vector2(h * 0.14, h * 0.35),
		Vector2(h * 0.12, h * 0.62), Vector2(h * 0.15, h * 0.76), Vector2(h * 0.06, h * 0.82)]), 8, 1.0, 0.75)
	lm.lathe(key, base + Vector3(0, h * 0.82, 0), PackedVector2Array([Vector2(h * 0.05, 0),
		Vector2(h * 0.07, h * 0.08), Vector2(h * 0.0, h * 0.18)]), 8)

## Plain column (shaft with a little entasis, moulded base and a simple
## capital) for arcades seen from a distance: r lower radius, h total.
static func shaft(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 10) -> void:
	lm.box(key, base + Vector3(0, r * 0.25, 0), Vector3(r * 2.6, r * 0.5, r * 2.6))
	lm.lathe(key, base + Vector3(0, r * 0.5, 0), PackedVector2Array([Vector2(r * 1.2, 0), Vector2(r, r * 0.3),
		Vector2(r * 0.97, h * 0.5), Vector2(r * 0.86, h - r * 1.6), Vector2(r * 1.25, h - r * 1.0)]), seg)
	lm.box(key, base + Vector3(0, h - r * 0.5, 0), Vector3(r * 2.7, r * 1.0, r * 2.7))

## Round arch drawn as a light archivolt band of `segs` beams over a
## span (springing centre c, wall facing n).
static func round_arch(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, span: float, bw: float,
		depth: float = 0.4, segs: int = 8) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var rad := span * 0.5 + bw * 0.5
	for i in segs:
		var t0 := PI * float(i) / float(segs)
		var t1 := PI * float(i + 1) / float(segs)
		lm.beam(key, c + (r * cos(t0) + Vector3.UP * sin(t0)) * rad + nn * depth * 0.5,
			c + (r * cos(t1) + Vector3.UP * sin(t1)) * rad + nn * depth * 0.5, bw, depth, nn)

## Small dome on a drum for turrets and side domes (lighter than
## LandmarkKits.dome_on_drum): drum with cornice and windows, ribbed
## shell, small lantern; total height drum_h + dome_h + lantern_h.
static func small_dome(lm: LandmarkMesh, wall: String, dome: String, glass: String, base: Vector3,
		r: float, drum_h: float, dome_h: float, lantern_h: float, wins: int = 8, point: float = 1.0) -> void:
	lm.frustum(wall, base, r, r, drum_h, 16)
	lm.frustum(wall, base + Vector3(0, drum_h - 0.5, 0), r * 1.08, r * 1.08, 0.5, 16)
	for i in wins:
		var a := TAU * (float(i) + 0.5) / float(wins)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box(glass, base + d * (r + 0.02) + Vector3(0, drum_h * 0.5, 0), Vector3(r * 0.35, drum_h * 0.5, 0.06),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
		round_arch(lm, wall, base + d * r + Vector3(0, drum_h * 0.75, 0), d, r * 0.35, r * 0.08, 0.2, 4)
	var prof := dome_prof(r * 1.02, dome_h, 7, point)
	lm.lathe(dome, base + Vector3(0, drum_h, 0), prof, 16)
	for i in 8:
		var d := Vector3(cos(TAU * float(i) / 8.0), 0, sin(TAU * float(i) / 8.0))
		for j in prof.size() - 2:
			lm.beam(dome, base + Vector3(0, drum_h, 0) + d * (prof[j].x + 0.06) + Vector3(0, prof[j].y, 0),
				base + Vector3(0, drum_h, 0) + d * (prof[j + 1].x + 0.06) + Vector3(0, prof[j + 1].y, 0), r * 0.06, r * 0.04)
	if lantern_h > 0.0:
		var t := base + Vector3(0, drum_h + dome_h * 0.97, 0)
		lm.frustum(wall, t, r * 0.22, r * 0.22, lantern_h * 0.55, 8)
		lm.lathe(dome, t + Vector3(0, lantern_h * 0.55, 0), dome_prof(r * 0.26, lantern_h * 0.45, 4, 1.4), 8)
