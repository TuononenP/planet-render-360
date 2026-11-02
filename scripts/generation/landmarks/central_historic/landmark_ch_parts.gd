class_name LandmarkChParts
extends RefCounted

## Small shared parts for the central_historic landmark batch, in true
## metres on LandmarkMesh: pointed and round-arched openings drawn flat
## on a facade, wall segments between two plan points, corner turrets,
## sliding cornice bands and finials. Each takes the material KEY to
## draw with; `b` turns the part so its local +Z faces outwards.

## Point `x` along, `y` up and `z` out of a facade whose origin is `at`.
static func at(origin: Vector3, b: Basis, x: float, y: float, z: float = 0.0) -> Vector3:
	return origin + b * Vector3(x, y, z)

## Flat Gothic opening (pointed head) w wide, h tall to the apex,
## standing on `base` just proud of the wall.
static func pointed(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float,
		b: Basis = Basis(), lift: float = 0.08) -> void:
	var rise := minf(w * 0.9, h * 0.55)
	var sh := h - rise
	var n := b.z
	var hw := w * 0.5
	lm.quad(key, at(base, b, -hw, 0, lift), at(base, b, hw, 0, lift), at(base, b, hw, sh, lift),
		at(base, b, -hw, sh, lift), n)
	lm.tri(key, at(base, b, -hw, sh, lift), at(base, b, hw, sh, lift), at(base, b, 0, h, lift),
		n, n, n, Vector2(0, 0), Vector2(w, 0), Vector2(hw, rise))

## Flat round-arched opening (semicircular head) w wide, h tall.
static func round_arch(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float,
		b: Basis = Basis(), lift: float = 0.08) -> void:
	var rad := w * 0.5
	var sh := maxf(h - rad, 0.05)
	var n := b.z
	lm.quad(key, at(base, b, -rad, 0, lift), at(base, b, rad, 0, lift), at(base, b, rad, sh, lift),
		at(base, b, -rad, sh, lift), n)
	var c := at(base, b, 0, sh, lift)
	for i in 6:
		var a0 := PI * float(i) / 6.0
		var a1 := PI * float(i + 1) / 6.0
		lm.tri(key, c, at(base, b, cos(a0) * rad, sh + sin(a0) * rad, lift),
			at(base, b, cos(a1) * rad, sh + sin(a1) * rad, lift), n, n, n,
			Vector2(0, 0), Vector2(cos(a0) * rad, sin(a0) * rad), Vector2(cos(a1) * rad, sin(a1) * rad))

## A row of `count` openings along the facade, centred on `base`;
## `gothic` picks pointed over round heads.
static func row(lm: LandmarkMesh, key: String, base: Vector3, count: int, step: float, w: float,
		h: float, b: Basis = Basis(), gothic: bool = true, lift: float = 0.08) -> void:
	for i in count:
		var o := at(base, b, step * (float(i) - float(count - 1) * 0.5), 0.0, 0.0)
		if gothic:
			pointed(lm, key, o, w, h, b, lift)
		else:
			round_arch(lm, key, o, w, h, b, lift)

## Vertical wall slab between two plan points `p` and `q` (y ignored),
## from y0 to y1, `thick` metres through.
static func wall(lm: LandmarkMesh, key: String, p: Vector3, q: Vector3, y0: float, y1: float,
		thick: float) -> void:
	var d := q - p
	d.y = 0.0
	var l := d.length()
	if l < 0.01:
		return
	var mid := (p + q) * 0.5
	lm.box(key, Vector3(mid.x, (y0 + y1) * 0.5, mid.z), Vector3(l, y1 - y0, thick),
		Basis(Vector3.UP, atan2(-d.z, d.x)))

## Slender polygonal corner turret: shaft of radius r and height h with
## a pointed cap `cap_h` high (sides 8 unless set).
static func turret(lm: LandmarkMesh, wall_key: String, cap_key: String, base: Vector3, r: float,
		h: float, cap_h: float, sides: int = 8) -> void:
	lm.lathe(wall_key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.9, h)]), sides,
		1.0, 1.0, PI / float(sides), false)
	lm.lathe(cap_key, base + Vector3(0, h, 0), PackedVector2Array([Vector2(r * 1.15, 0),
		Vector2(0.0, cap_h)]), sides, 1.0, 1.0, PI / float(sides), false)

## Thin cornice or string course round a square plan of half-width hw.
static func band(lm: LandmarkMesh, key: String, y: float, hw_x: float, hw_z: float, h: float = 0.8,
		out: float = 0.5, c: Vector3 = Vector3.ZERO) -> void:
	lm.box(key, c + Vector3(0, y + h * 0.5, 0), Vector3(hw_x * 2.0 + out * 2.0, h, hw_z * 2.0 + out * 2.0))

## Ball and rod finial reaching `h` above `base`.
static func finial(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float = 0.5) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 0.6, 0), Vector2(r, h * 0.2),
		Vector2(r * 0.4, h * 0.34), Vector2(r * 0.12, h * 0.5), Vector2(0.04, h)]), 8)

## Stepped octagon-to-dome swell profile (radius, y) for copper domes.
static func swell(r: float, h: float, bulge: float = 1.12) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		var rr := r * (1.0 - t * t) + r * (bulge - 1.0) * sin(PI * minf(t * 2.0, 1.0))
		p.append(Vector2(maxf(rr, 0.0), h * sin(t * PI * 0.5)))
	return p

## Gothic lancet window: opening w wide, h from the sill (`sill`, centre
## of its bottom edge on a wall facing `n`) to the apex of an
## equilateral pointed head: a moulded frame proud of the wall, glass,
## `mullions` dividing the lights and a round tracery eye in the head.
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
	var head := pointed_arc(w * 0.5, 4)
	for i in head.size() - 1:
		lm.tri(glass, gs, gs + r * head[i].x + up * head[i].y, gs + r * head[i + 1].x + up * head[i + 1].y,
			nn, nn, nn, Vector2.ZERO, head[i], head[i + 1])
	var fc := sill + nn * depth * 0.5
	var wo := w * 0.5 + fw * 0.5
	for s in [-1.0, 1.0]:
		lm.beam(frame, fc + r * wo * float(s), fc + r * wo * float(s) + up * spring, fw, depth, r)
	var arc := pointed_arc(wo, 4)
	for i in arc.size() - 1:
		lm.beam(frame, fc + up * spring + r * arc[i].x + up * arc[i].y,
			fc + up * spring + r * arc[i + 1].x + up * arc[i + 1].y, fw, depth, nn)
	lm.box(frame, fc + nn * depth * 0.2 - up * fw * 0.3, Vector3(w + fw * 3.0, fw * 0.6, depth * 1.4),
		Basis(r, up, nn), 0.0)
	var bar := fw * 0.6
	for m in mullions:
		var x := w * ((float(m) + 1.0) / float(mullions + 1) - 0.5)
		lm.beam(frame, fc + r * x, fc + r * x + up * (spring + w * 0.12), bar, depth * 0.7, r)
	if w > 1.0:
		var ec := fc + up * (spring + w * 0.42)
		var er := w * 0.2
		for k in 6:
			var a0 := TAU * float(k) / 6.0
			var a1 := TAU * float(k + 1) / 6.0
			lm.beam(frame, ec + (r * cos(a0) + up * sin(a0)) * er, ec + (r * cos(a1) + up * sin(a1)) * er,
				bar, depth * 0.7, nn)

## Equilateral pointed arch of half-span hs as (x, y) points from the
## left springer (-hs, 0) over the apex to (hs, 0).
static func pointed_arc(hs: float, steps: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var t := PI - (PI / 3.0) * float(i) / float(steps)
		p.append(Vector2(hs + cos(t) * hs * 2.0, sin(t) * hs * 2.0))
	for i in range(steps - 1, -1, -1):
		var q := p[i]
		p.append(Vector2(-q.x, q.y))
	return p

## Gothic pinnacle w square and h tall from `base`: shaft, gablets
## crossing at its head, a crocketed needle and a cross-flower.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, w: float, h: float) -> void:
	var sh := h * 0.42
	lm.box(key, base + Vector3(0, sh * 0.5, 0), Vector3(w, sh, w))
	var gb := base + Vector3(0, sh, 0)
	lm.gable(key, gb, w, w, w * 0.75, Basis(), 0.04, key)
	lm.gable(key, gb, w, w, w * 0.75, Basis(Vector3.UP, PI * 0.5), 0.04, key)
	var nh := h - sh - w * 0.35
	lm.spire(key, gb, w * 0.36, nh)
	var n := clampi(int(nh / maxf(w * 0.6, 0.3)), 2, 5)
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

## Gothic wimperg: open triangular gable w wide and h tall over an
## opening, its foot centred at `c` on a wall facing `n`, crocketed rakes
## and a finial.
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

## Stepped Gothic buttress at `foot` (on the wall face) projecting `d`
## along `out`, w wide, h tall in `steps` set-backs with sloped weatherings.
static func buttress(lm: LandmarkMesh, key: String, foot: Vector3, out: Vector3, w: float, d: float,
		h: float, steps: int = 2) -> void:
	var o := out.normalized()
	var r := Vector3.UP.cross(o).normalized()
	var basis := Basis(r, Vector3.UP, o)
	var sh := h / float(steps)
	for s in steps:
		var dd := d * (1.0 - 0.3 * float(s))
		var dn := d * (1.0 - 0.3 * float(s + 1)) if s < steps - 1 else d * 0.15
		var y := sh * float(s)
		lm.box(key, foot + o * dd * 0.5 + Vector3(0, y + sh * 0.5, 0), Vector3(w, sh, dd), basis)
		var top := foot + Vector3(0, y + sh, 0)
		var rise := (dd - dn) * 0.9
		lm.quad(key, top + o * dd - r * w * 0.5, top + o * dd + r * w * 0.5,
			top + o * dn + r * w * 0.5 + Vector3(0, rise, 0), top + o * dn - r * w * 0.5 + Vector3(0, rise, 0),
			(o + Vector3.UP).normalized())
		for sg in [-1.0, 1.0]:
			var e := r * w * 0.5 * float(sg)
			lm.tri(key, top + o * dd + e, top + o * dn + e, top + o * dn + e + Vector3(0, rise, 0),
				r * float(sg), r * float(sg), r * float(sg), Vector2(0, 0), Vector2(dd - dn, 0), Vector2(dd - dn, rise))

## Corbel table along a-b (wall face line at the corbels' top): a corbel
## every `step` projecting `out` and h tall, little arches between them.
static func corbels(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, step: float,
		h: float) -> void:
	var o := out.normalized()
	var dl := a.distance_to(b)
	var dir := (b - a).normalized()
	var n := maxi(int(dl / step), 1)
	var basis := Basis(dir, Vector3.UP, o)
	var d := out.length()
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box(key, p + o * d * 0.5 - Vector3(0, h * 0.5, 0), Vector3(minf(step * 0.3, 0.5), h, d), basis, 0.0)
	for i in n:
		var p0 := a.lerp(b, float(i) / float(n)) + o * d * 0.85 - Vector3(0, h * 0.25, 0)
		var p1 := a.lerp(b, float(i + 1) / float(n)) + o * d * 0.85 - Vector3(0, h * 0.25, 0)
		var pm := (p0 + p1) * 0.5 - Vector3(0, h * 0.25, 0)
		lm.beam(key, p0, pm, h * 0.2, d * 0.3, o)
		lm.beam(key, pm, p1, h * 0.2, d * 0.3, o)

## Open tracery parapet along a-b at its foot level, h tall: sill and
## coping rails with posts every `step` and a pointed trefoil in each panel.
static func tracery_parapet(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float,
		step: float = 1.2, thick: float = 0.25) -> void:
	var dir := (b - a).normalized()
	var o := dir.cross(Vector3.UP).normalized()
	var basis := Basis(dir, Vector3.UP, o)
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box(key, mid + Vector3(0, h * 0.06, 0), Vector3(dl, h * 0.12, thick * 1.2), basis, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.94, 0), Vector3(dl + thick, h * 0.12, thick * 1.4), basis, 0.0)
	var n := maxi(int(dl / step), 1)
	for i in n + 1:
		lm.box(key, a.lerp(b, float(i) / float(n)) + Vector3(0, h * 0.5, 0), Vector3(thick, h * 0.8, thick), basis, 0.0)
	for i in n:
		var c := a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, h * 0.18, 0)
		var hs := dl / float(n) * 0.5 - thick * 0.5
		var arc := pointed_arc(hs, 2)
		var sc := minf(1.0, (h * 0.66) / maxf(arc[2].y, 0.01))
		for k in arc.size() - 1:
			lm.beam(key, c + dir * arc[k].x + Vector3(0, arc[k].y * sc, 0),
				c + dir * arc[k + 1].x + Vector3(0, arc[k + 1].y * sc, 0), thick * 0.5, thick * 0.6, o)

## Classical half-column (engaged) on a wall facing `n`: square plinth,
## torus, plain tapering shaft and a Tuscan capital; h tall, r radius.
static func half_column(lm: LandmarkMesh, key: String, base: Vector3, n: Vector3, r: float, h: float) -> void:
	var nn := n.normalized()
	var basis := Basis(Vector3.UP.cross(nn).normalized(), Vector3.UP, nn)
	var p := base + nn * r * 0.2
	lm.box(key, p + Vector3(0, r * 0.25, 0), Vector3(r * 2.6, r * 0.5, r * 1.6), basis, 0.0)
	lm.frustum(key, p + Vector3(0, r * 0.5, 0), r * 1.2, r * 1.05, r * 0.35, 10)
	lm.frustum(key, p + Vector3(0, r * 0.85, 0), r, r * 0.86, h - r * 1.7, 10)
	lm.frustum(key, p + Vector3(0, h - r * 0.85, 0), r * 0.9, r * 1.25, r * 0.45, 10)
	lm.box(key, p + Vector3(0, h - r * 0.2, 0), Vector3(r * 2.6, r * 0.4, r * 1.7), basis, 0.0)

## Round-arched window with a proud moulded frame: jambs, an arch of
## beams, a sill, glass at the wall. Sill centre `sill` on a face `n`.
static func arched_window(lm: LandmarkMesh, frame: String, glass: String, sill: Vector3, n: Vector3,
		w: float, h: float, depth: float = 0.25, segs: int = 6) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var up := Vector3.UP
	var oh := maxf(h - w * 0.5, 0.1)
	var g := sill + nn * 0.03
	lm.quad(glass, g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + up * oh, g - r * w * 0.5 + up * oh, nn)
	var gc := g + up * oh
	for i in segs:
		var t0 := PI * float(i) / float(segs)
		var t1 := PI * float(i + 1) / float(segs)
		lm.tri(glass, gc, gc + (r * cos(t0) + up * sin(t0)) * w * 0.5, gc + (r * cos(t1) + up * sin(t1)) * w * 0.5,
			nn, nn, nn, Vector2.ZERO, Vector2(cos(t0), sin(t0)) * w * 0.5, Vector2(cos(t1), sin(t1)) * w * 0.5)
	var fw := clampf(w * 0.12, 0.1, 0.5)
	var fc := sill + nn * depth * 0.5
	var wo := w * 0.5 + fw * 0.5
	for s in [-1.0, 1.0]:
		lm.beam(frame, fc + r * wo * float(s), fc + r * wo * float(s) + up * oh, fw, depth, r)
	var prev := fc + up * oh + r * wo
	for i in segs:
		var t := PI * float(i + 1) / float(segs)
		var q := fc + up * oh + (r * cos(t) + up * sin(t)) * wo
		lm.beam(frame, prev, q, fw, depth, nn)
		prev = q
	lm.box(frame, fc + nn * depth * 0.2 - up * fw * 0.3, Vector3(w + fw * 2.6, fw * 0.6, depth * 1.4),
		Basis(r, up, nn), 0.0)

## Slender colonnette (arcades, twin windows): round base, plain shaft
## and a cushion capital with its abacus; r shaft radius, h tall.
static func colonnette(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float) -> void:
	lm.frustum(key, base, r * 1.5, r * 1.3, r * 1.2, 8)
	lm.frustum(key, base + Vector3(0, r * 1.2, 0), r, r * 0.9, h - r * 3.4, 8)
	lm.frustum(key, base + Vector3(0, h - r * 2.2, 0), r * 0.95, r * 1.5, r * 1.6, 8, PI / 8.0)
	lm.box(key, base + Vector3(0, h - r * 0.3, 0), Vector3(r * 3.4, r * 0.6, r * 3.4), Basis(), 0.0)

## Light stone-framed window w x h centred at `c` on a face `n`: glass,
## jambs, sill and a projecting head (the economical cousin of
## LandmarkDetail.window for long facades).
static func frame_window(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, n: Vector3, w: float,
		h: float, fw: float = 0.2, depth: float = 0.15) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var basis := Basis(r, Vector3.UP, nn)
	var g := c + nn * 0.02
	lm.quad(glass, g - r * w * 0.5 - Vector3(0, h * 0.5, 0), g + r * w * 0.5 - Vector3(0, h * 0.5, 0),
		g + r * w * 0.5 + Vector3(0, h * 0.5, 0), g - r * w * 0.5 + Vector3(0, h * 0.5, 0), nn)
	var fc := c + nn * depth * 0.5
	for s in [-1.0, 1.0]:
		lm.box(frame, fc + r * (w + fw) * 0.5 * float(s), Vector3(fw, h, depth), basis, 0.0)
	lm.box(frame, fc - Vector3(0, (h + fw) * 0.5, 0) + nn * depth * 0.3, Vector3(w + fw * 3.0, fw, depth * 1.6), basis, 0.0)
	lm.box(frame, fc + Vector3(0, (h + fw) * 0.5, 0) + nn * depth * 0.3, Vector3(w + fw * 3.0, fw * 1.4, depth * 1.6),
		basis, 0.0)

## Round arch band (archivolt) of `segs` beams over an opening `span`
## wide springing at `c` on a face `n`; bw wide, `depth` proud.
static func arch_band(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, span: float, bw: float,
		depth: float, segs: int = 8) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var rad := span * 0.5 + bw * 0.5
	var fc := c + nn * depth * 0.5
	var prev := fc + r * rad
	for i in segs:
		var t := PI * float(i + 1) / float(segs)
		var q := fc + (r * cos(t) + Vector3.UP * sin(t)) * rad
		lm.beam(key, prev, q, bw, depth, nn)
		prev = q

## Slender Renaissance arcade column: square plinth, torus base, plain
## tapering shaft, necking, echinus and abacus; r shaft radius, h tall.
static func ren_column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float) -> void:
	lm.box(key, base + Vector3(0, r * 0.35, 0), Vector3(r * 2.8, r * 0.7, r * 2.8), Basis(), 0.0)
	lm.lathe(key, base + Vector3(0, r * 0.7, 0), PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r * 1.35, r * 0.25),
		Vector2(r * 1.1, r * 0.5)]), 12)
	lm.frustum(key, base + Vector3(0, r * 1.2, 0), r, r * 0.85, h - r * 2.6, 12)
	lm.lathe(key, base + Vector3(0, h - r * 1.4, 0), PackedVector2Array([Vector2(r * 0.95, 0), Vector2(r * 0.95, r * 0.3),
		Vector2(r * 1.2, r * 0.7), Vector2(r * 1.45, r * 0.95)]), 12)
	lm.box(key, base + Vector3(0, h - r * 0.22, 0), Vector3(r * 3.0, r * 0.45, r * 3.0), Basis(), 0.0)

## Long roofline balustrade along a-b at its foot level, h tall: plinth,
## handrail, double-bellied balusters (two short frustums each) and a
## square pedestal every `bay` metres; lighter than
## LandmarkDetail.balustrade for runs of tens of metres.
static func roof_balustrade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.2,
		bay: float = 4.0) -> void:
	var dir := (b - a).normalized()
	var dl := a.distance_to(b)
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	var w := h * 0.24
	lm.box(key, mid + Vector3(0, h * 0.07, 0), Vector3(dl, h * 0.14, w * 1.3), basis, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.92, 0), Vector3(dl, h * 0.16, w * 1.4), basis, 0.0)
	var piers := maxi(int(dl / bay), 1)
	var n := int(dl / (h * 0.36))
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		var slot := fmod(t * piers, 1.0)
		if slot < 0.07 or slot > 0.93:
			continue
		var p := a.lerp(b, t) + Vector3(0, h * 0.14, 0)
		lm.frustum(key, p, w * 0.42, w * 0.2, h * 0.36, 6)
		lm.frustum(key, p + Vector3(0, h * 0.36, 0), w * 0.2, w * 0.36, h * 0.34, 6)
	for i in piers + 1:
		lm.box(key, a.lerp(b, float(i) / float(piers)) + Vector3(0, h * 0.5, 0), Vector3(w * 1.6, h, w * 1.6), basis)
