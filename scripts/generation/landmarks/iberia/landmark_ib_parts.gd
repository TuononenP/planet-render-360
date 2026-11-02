class_name LandmarkIbParts
extends RefCounted

## Detail parts for the Iberia landmark builders (true metres on
## LandmarkMesh), lighter than the LandmarkDetail kits where a facade
## repeats them hundreds of times: framed window rows, pilasters with
## base and capital, a light balustrade for long runs, urn finials,
## stepped Andalusian merlons, framed horseshoe and round-arched
## openings with real depth, buttresses with set-offs, and a slate
## "chapitel" spire of the Madrid kind. Every part takes the material
## KEYS it draws with; the caller registers them with lm.use.

## `n` framed windows (LandmarkDetail.window) along a wall face: `o` is
## the face centre at ground level, `right` the wall direction, `out` the
## face normal; openings w x h centred `y` above ground on pitch `pitch`;
## those closer than `gap` to the centre are left out.
static func window_row(lm: LandmarkMesh, frame: String, glass: String, o: Vector3, right: Vector3,
		out: Vector3, y: float, n: int, pitch: float, w: float, h: float, arched: bool = false,
		gap: float = 0.0) -> void:
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		if absf(s) < gap:
			continue
		LandmarkDetail.window(lm, frame, glass, o + right * s + Vector3(0, y, 0), out, w, h, arched, 0.25)

## Pilaster w wide, d proud of the wall, from y0 to y1 at `p` (the foot
## on the wall face): a moulded base, the shaft and a capital with its
## abacus, in the order of a giant pilaster.
static func pilaster(lm: LandmarkMesh, key: String, p: Vector3, right: Vector3, out: Vector3,
		w: float, d: float, y0: float, y1: float) -> void:
	var basis := Basis(right, Vector3.UP, out)
	var h := y1 - y0
	var bh := minf(h * 0.06, 1.0)
	var ch := minf(h * 0.06, 1.0)
	lm.box(key, p + out * (d * 0.6) + Vector3(0, y0 + bh * 0.5, 0), Vector3(w * 1.25, bh, d * 1.2), basis)
	lm.box(key, p + out * (d * 0.5) + Vector3(0, y0 + h * 0.5, 0), Vector3(w, h - bh - ch, d), basis)
	lm.box(key, p + out * (d * 0.65) + Vector3(0, y1 - ch * 0.5, 0), Vector3(w * 1.25, ch, d * 1.3), basis)

## Row of `n` pilasters along a face (see `pilaster`), centred on `o`,
## skipping those within `gap` of the centre.
static func pilaster_row(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		n: int, pitch: float, w: float, d: float, y0: float, y1: float, gap: float = 0.0) -> void:
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		if absf(s) < gap:
			continue
		pilaster(lm, key, o + right * s, right, out, w, d, y0, y1)

## Light balustrade a..b (both at its foot) h tall: plinth, tapered
## square balusters every 0.45 h, handrail, and a pedestal every `bay` metres
## (an urn on each when `urns`). For long cornice runs, where the lathed
## LandmarkDetail balustrade would cost too much.
static func rail(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.2,
		bay: float = 7.0, urns: bool = false) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.2:
		return
	var dir := d / length
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	var w := h * 0.3
	lm.box(key, mid + Vector3(0, h * 0.08, 0), Vector3(length, h * 0.16, w * 1.3), basis)
	lm.box(key, mid + Vector3(0, h * 0.92, 0), Vector3(length, h * 0.16, w * 1.4), basis)
	var vase := PackedVector2Array([Vector2(w * 0.3, 0), Vector2(w * 0.22, h * 0.68)])
	var n := int(length / (h * 0.45))
	var piers := maxi(int(length / bay), 1)
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		var slot := fmod(t * piers, 1.0)
		if slot * length / piers < w or (1.0 - slot) * length / piers < w:
			continue
		lm.lathe(key, a.lerp(b, t) + Vector3(0, h * 0.16, 0), vase, 4, 1.0, 1.0, PI * 0.25, false, false)
	for i in piers + 1:
		var p := a.lerp(b, float(i) / float(piers))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(w * 1.8, h, w * 1.8), basis)
		if urns:
			urn(lm, key, p + Vector3(0, h, 0), h * 0.9)

## Round arch ring over an opening `span` wide springing at `c` (the
## centre of the springing line) on a wall facing `out`: `steps`
## voussoir beams `band` deep radially and `d` thick, with a keystone.
static func arch_ring(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, span: float,
		band: float, d: float, steps: int = 9) -> void:
	var n := out.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var rad := span * 0.5 + band * 0.5
	var prev := c + r * rad
	for i in steps:
		var t := PI * float(i + 1) / float(steps)
		var p := c + (r * cos(t) + Vector3.UP * sin(t)) * rad
		lm.beam(key, prev, p, band, d, n)
		prev = p
	lm.box(key, c + Vector3(0, rad, 0) + n * 0.05, Vector3(band * 0.8, band * 1.4, d + 0.1), Basis(r, Vector3.UP, n), 0.0)

## Plain column of height h on `base`, shaft radius r: a square plinth,
## a torus, the tapering shaft, an echinus and the abacus (the light
## stand-in for LandmarkDetail.column in long arcades).
static func post(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 10) -> void:
	lm.box(key, base + Vector3(0, r * 0.25, 0), Vector3(r * 2.6, r * 0.5, r * 2.6), Basis(), 0.0)
	lm.lathe(key, base + Vector3(0, r * 0.5, 0), PackedVector2Array([Vector2(r * 1.2, 0),
		Vector2(r * 1.25, r * 0.2), Vector2(r * 1.05, r * 0.4)]), seg, 1.0, 1.0, 0.0, true, false)
	lm.lathe(key, base + Vector3(0, r * 0.9, 0), PackedVector2Array([Vector2(r, 0),
		Vector2(r * 0.97, (h - r * 2.0) * 0.4), Vector2(r * 0.84, h - r * 2.0)]), seg, 1.0, 1.0, 0.0, true, false)
	lm.lathe(key, base + Vector3(0, h - r * 1.1, 0), PackedVector2Array([Vector2(r * 0.84, 0),
		Vector2(r * 0.9, r * 0.15), Vector2(r * 1.3, r * 0.6)]), seg, 1.0, 1.0, 0.0, true, false)
	lm.box(key, base + Vector3(0, h - r * 0.25, 0), Vector3(r * 2.7, r * 0.5, r * 2.7), Basis(), 0.0)

## Stone urn finial h tall on `base`: foot, bowl, lid and knob.
static func urn(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(h * 0.2, 0), Vector2(h * 0.2, h * 0.08),
		Vector2(h * 0.1, h * 0.16), Vector2(h * 0.26, h * 0.42), Vector2(h * 0.22, h * 0.62),
		Vector2(h * 0.12, h * 0.7), Vector2(h * 0.14, h * 0.78), Vector2(h * 0.05, h * 0.9),
		Vector2(0.0, h)]), 8)

## Stepped Andalusian merlons ("almenas escalonadas") along a..b at the
## wall top: each a stack of three set-back blocks ending in a little
## pyramid, `m` wide, one every 2 m, `t` thick.
static func stepped_merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, m: float,
		h: float, t: float) -> void:
	var d := b - a
	var count := maxi(int(d.length() / (m * 2.0)), 1)
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		lm.box(key, p + Vector3(0, h * 0.25, 0), Vector3(t, h * 0.5, m), basis, 0.0)
		lm.box(key, p + Vector3(0, h * 0.62, 0), Vector3(t, h * 0.24, m * 0.66), basis, 0.0)
		lm.box(key, p + Vector3(0, h * 0.83, 0), Vector3(t, h * 0.18, m * 0.34), basis, 0.0)
		lm.spire(key, p + Vector3(0, h * 0.92, 0), minf(t, m) * 0.17, h * 0.12)

## Recessed opening on a wall facing `out`: `o` the bottom centre on the
## face, w x h; a reveal frame `d` deep standing proud of the face (jambs
## and an arched or flat head of voussoir beams), a dark back panel and,
## when `alfiz`, the rectangular moulded frame of Moorish portals.
## kind: 0 flat lintel, 1 round arch, 2 horseshoe arch, 3 pointed arch.
static func portal(lm: LandmarkMesh, frame: String, dark: String, o: Vector3, right: Vector3,
		out: Vector3, w: float, h: float, kind: int = 1, d: float = 0.5, alfiz: bool = false) -> void:
	var r := right.normalized()
	var n := out.normalized()
	var fw := clampf(w * 0.14, 0.18, 1.2)
	var basis := Basis(r, Vector3.UP, n)
	var arc := _arc(w * 0.5 + fw * 0.5, kind)
	var spring := h - (arc[arc.size() / 2].y if kind != 0 else 0.0)
	spring = maxf(spring, 0.3)
	var fc := o + n * d * 0.5
	for s in [-1.0, 1.0]:
		lm.box(frame, fc + r * (w * 0.5 + fw * 0.5) * float(s) + Vector3(0, spring * 0.5, 0),
			Vector3(fw, spring, d), basis)
	if kind == 0:
		lm.box(frame, fc + Vector3(0, spring + fw * 0.5, 0), Vector3(w + fw * 2.0, fw, d), basis)
	else:
		var top := fc + Vector3(0, spring, 0)
		for i in arc.size() - 1:
			lm.beam(frame, top + r * arc[i].x + Vector3(0, arc[i].y, 0),
				top + r * arc[i + 1].x + Vector3(0, arc[i + 1].y, 0), fw, d, n)
	# Dark back panel: rectangle to the spring, a fan over the head.
	var g := o + n * 0.03
	var ih := _arc(w * 0.5, kind)
	lm.quad(dark, g - r * w * 0.5, g + r * w * 0.5, g + r * w * 0.5 + Vector3(0, spring, 0),
		g - r * w * 0.5 + Vector3(0, spring, 0), n)
	if kind != 0:
		var gc := g + Vector3(0, spring, 0)
		for i in ih.size() - 1:
			lm.tri(dark, gc, gc + r * ih[i].x + Vector3(0, ih[i].y, 0), gc + r * ih[i + 1].x + Vector3(0, ih[i + 1].y, 0),
				n, n, n, Vector2.ZERO, ih[i], ih[i + 1])
	if alfiz:
		var aw := w + fw * 4.0
		var ah := h + fw * 2.0
		var fd := d * 0.7
		lm.box(frame, o + n * fd * 0.5 + Vector3(0, ah, 0), Vector3(aw + fw, fw * 0.8, fd), basis)
		for s in [-1.0, 1.0]:
			lm.box(frame, o + n * fd * 0.5 + r * (aw * 0.5) * float(s) + Vector3(0, ah * 0.5, 0),
				Vector3(fw * 0.8, ah, fd), basis)

## Head profile (x across, y up from the spring) of half-span hs:
## kind 1 semicircle, 2 horseshoe (swelling past the half circle), 3
## pointed (equilateral). The middle point is the apex.
static func _arc(hs: float, kind: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	var steps := 10
	for i in steps + 1:
		var t := float(i) / float(steps)
		match kind:
			2:
				var rr := hs / 0.94
				var a := deg_to_rad(-20.0 + 220.0 * (1.0 - t))
				p.append(Vector2(rr * cos(a), rr * sin(a) + rr * sin(deg_to_rad(20.0))))
			3:
				if t <= 0.5:
					var a := PI - (PI / 3.0) * (t * 2.0)
					p.append(Vector2(hs + cos(a) * hs * 2.0, sin(a) * hs * 2.0))
				else:
					var a := (PI / 3.0) * ((1.0 - t) * 2.0)
					p.append(Vector2(-hs + cos(a) * hs * 2.0, sin(a) * hs * 2.0))
			_:
				var a := PI * (1.0 - t)
				p.append(Vector2(hs * cos(a), hs * sin(a)))
	return p

## Buttress at `p` (foot on the wall face, facing `out`): w wide, `d`
## deep at the foot, h tall, with two weathered set-offs.
static func buttress(lm: LandmarkMesh, key: String, p: Vector3, out: Vector3, w: float, d: float,
		h: float) -> void:
	var basis := Basis(Vector3.UP.cross(out).normalized(), Vector3.UP, out)
	var y := 0.0
	var dd := d
	for k in 3:
		var hh: float = h * float([0.42, 0.33, 0.25][k])
		lm.box(key, p + out * (dd * 0.5) + Vector3(0, y + hh * 0.5, 0), Vector3(w, hh, dd), basis)
		y += hh
		dd *= 0.7

## Madrid slate spire ("chapitel"): a square pyramid of half-width hw
## rising h1, a neck, a slate bulb, a slender needle and a gilt ball
## with a vane; total height h.
static func chapitel(lm: LandmarkMesh, slate: String, gilt: String, base: Vector3, hw: float,
		h: float) -> void:
	var h1 := h * 0.5
	lm.spire(slate, base, hw, h1, hw * 0.22)
	var nb := base + Vector3(0, h1, 0)
	var nr := hw * 0.24
	lm.lathe(slate, nb, PackedVector2Array([Vector2(nr, 0), Vector2(nr * 0.8, h * 0.04),
		Vector2(nr * 1.6, h * 0.1), Vector2(nr * 1.5, h * 0.16), Vector2(nr * 0.6, h * 0.21),
		Vector2(nr * 0.35, h * 0.24)]), 8)
	lm.frustum(slate, nb + Vector3(0, h * 0.24, 0), nr * 0.35, nr * 0.08, h * 0.2, 8)
	lm.lathe(gilt, nb + Vector3(0, h * 0.43, 0), SEuUtil.dome(nr * 0.35, nr * 0.35, 4), 8)
	lm.box(gilt, nb + Vector3(0, h * 0.47, 0), Vector3(nr * 0.12, h * 0.06, nr * 0.12), Basis(), 0.0)

## Statue on a pedestal: a block plinth p_h tall, then a robed figure.
static func statue(lm: LandmarkMesh, stone: String, fig: String, base: Vector3, p_h: float,
		h: float, arm_up: bool = false) -> void:
	lm.box(stone, base + Vector3(0, p_h * 0.5, 0), Vector3(h * 0.42, p_h, h * 0.42))
	LandmarkKits.statue_figure(lm, fig, base + Vector3(0, p_h, 0), h, arm_up)

## Horizontal band (string course / cornice) along a face: `o` face
## centre at ground, `right`, `out`; `length` long, at height y, h tall,
## projecting `proj`.
static func band(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		length: float, y: float, h: float, proj: float) -> void:
	lm.box(key, o + out * (proj * 0.5) + Vector3(0, y, 0), Vector3(length, h, proj),
		Basis(right, Vector3.UP, out))
