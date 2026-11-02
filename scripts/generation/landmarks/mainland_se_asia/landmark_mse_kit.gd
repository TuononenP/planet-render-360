class_name LandmarkMseKit
extends RefCounted

## Detail parts of the mainland south-east Asia landmark batch, in true
## metres on LandmarkMesh: the redented ("twelve indented corners") plan
## of Thai chedis, prangs and columns, notched columns with lotus
## capitals, the gilded gable trim of a Thai roof (bargeboards with
## bai raka blades, the chofa finial, hang hong naga tails), stepped and
## layered Thai roofs, flat outline prisms (pediments, steles, bai sema)
## and pointed Thai windows. Like LandmarkMseUtil every part takes
## material KEYS and builds upward from its base point.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

## Square of half-width r with each corner indented in `steps` (1 or 2)
## steps of d: with two, 24 points and 12 outer corners (the Thai "yo
## mum mai sip song" plan); with one, 16 points.
static func redent_ring(r: float, d: float, steps: int = 2) -> PackedVector2Array:
	var q := [Vector2(r, 0), Vector2(r, r - 2.0 * d), Vector2(r - d, r - 2.0 * d), Vector2(r - d, r - d),
		Vector2(r - 2.0 * d, r - d), Vector2(r - 2.0 * d, r)]
	if steps == 1:
		q = [Vector2(r, 0), Vector2(r, r - d), Vector2(r - d, r - d), Vector2(r - d, r)]
	var out := PackedVector2Array()
	for k in 4:
		for p in q:
			var v: Vector2 = p
			out.append(v.rotated(PI * 0.5 * float(k)))
	return out

## Faceted solid of the redented plan through a (half-width, y) profile
## from bottom to top, the indent `notch` of each ring's half-width;
## turned by `rot` about the vertical, `steps` indents per corner.
## Capped on top when the last half-width is not zero.
static func redent_lathe(lm: LandmarkMesh, key: String, base: Vector3, prof: PackedVector2Array,
		notch: float = 0.12, rot: float = 0.0, steps: int = 2) -> void:
	var rings: Array = []
	for p in prof:
		var ring := PackedVector3Array()
		for v: Vector2 in redent_ring(p.x, p.x * notch, steps):
			var w := v.rotated(rot)
			ring.append(base + Vector3(w.x, p.y, w.y))
		rings.append(ring)
	for j in prof.size() - 1:
		var r0: PackedVector3Array = rings[j]
		var r1: PackedVector3Array = rings[j + 1]
		var yc := base.y + (prof[j].y + prof[j + 1].y) * 0.5
		for i in r0.size():
			var k := (i + 1) % r0.size()
			var mid := (r0[i] + r0[k] + r1[i] + r1[k]) * 0.25
			var radial := Vector3(mid.x - base.x, 0, mid.z - base.z)
			if prof[j + 1].x < 0.001:
				var n := (r0[k] - r0[i]).cross(r1[i] - r0[i]).normalized()
				if n.dot(radial) < 0.0:
					n = -n
				lm.tri(key, r0[i], r0[k], r1[i], n, n, n, Vector2.ZERO,
					Vector2(r0[i].distance_to(r0[k]), 0), Vector2(0, -r0[i].distance_to(r1[i])))
				continue
			var e := r0[k] - r0[i] if prof[j].x > 0.001 else r1[k] - r1[i]
			var n2 := e.cross(r1[i] - r0[i]).normalized()
			if n2.dot(radial) < 0.0:
				n2 = -n2
			lm.quad(key, r0[i], r0[k], r1[k], r1[i], n2, Vector2(0, -yc))
	var last := prof.size() - 1
	if prof[last].x > 0.001:
		var top: PackedVector3Array = rings[last]
		var c := base + Vector3(0, prof[last].y, 0)
		var nt := top.size()
		for i in nt:
			lm.tri(key, c, top[i], top[(i + 1) % nt], Vector3.UP, Vector3.UP, Vector3.UP,
				Vector2(c.x, c.z), Vector2(top[i].x, top[i].z), Vector2(top[(i + 1) % nt].x, top[(i + 1) % nt].z))

## Thai pillar w wide and h tall: a stepped plinth, the notched square
## shaft and the gilded lotus-bud capital (bua hua sao) in `cap`.
static func thai_column(lm: LandmarkMesh, key: String, cap: String, base: Vector3, w: float, h: float) -> void:
	var hw := w * 0.5
	redent_lathe(lm, key, base, PackedVector2Array([Vector2(hw * 1.35, 0), Vector2(hw * 1.35, hw * 0.6),
		Vector2(hw, hw * 0.8), Vector2(hw, h - w * 1.2)]), 0.16, 0.0, 1)
	redent_lathe(lm, cap, base + Vector3(0, h - w * 1.2, 0), PackedVector2Array([Vector2(hw, 0),
		Vector2(hw * 1.6, w * 0.8), Vector2(hw * 1.25, w * 1.2)]), 0.16, 0.0, 1)

## Small bell chedi of total height h and bell radius r, light enough to
## stand in rows: plinth rings, bell, harmika, ringed spire, gilded tip.
static func small_chedi(lm: LandmarkMesh, body: String, gold: String, base: Vector3, r: float, h: float) -> void:
	lm.lathe(body, base, PackedVector2Array([Vector2(r * 1.6, 0), Vector2(r * 1.6, h * 0.06), Vector2(r * 1.35, h * 0.08),
		Vector2(r * 1.3, h * 0.14), Vector2(r * 1.1, h * 0.16), Vector2(r * 1.05, h * 0.24), Vector2(r * 0.85, h * 0.33),
		Vector2(r * 0.5, h * 0.4), Vector2(r * 0.42, h * 0.46), Vector2(r * 0.3, h * 0.5), Vector2(r * 0.24, h * 0.58),
		Vector2(r * 0.3, h * 0.6), Vector2(r * 0.18, h * 0.66), Vector2(r * 0.22, h * 0.68), Vector2(r * 0.1, h * 0.78)]), 10)
	lm.lathe(gold, base + Vector3(0, h * 0.78, 0), PackedVector2Array([Vector2(r * 0.1, 0), Vector2(r * 0.12, h * 0.04),
		Vector2(0.0, h * 0.22)]), 6)

## Gilded trim of a swept roof built by U.swept_roof with the same
## arguments: on each gable end the bargeboard (lamyong) riding the
## curved rake with its row of bai raka blades, the chofa hooking up
## from the apex and a hang hong naga tail curling up at each eave
## corner; the ridge cap; and a carved gilded tympanum panel set on the
## gable wall (only when `tympanum`). `ends` limits the trim to the +Z
## (1), -Z (-1) or both (0) ends.
static func gable_trim(lm: LandmarkMesh, key: String, c: Vector3, basis: Basis, w: float, l: float,
		rise: float, lift: float, over: float, chofa_h: float, tympanum: bool = true, ends: int = 0) -> void:
	var hx := w * 0.5 + over
	var hz := l * 0.5 + over * 0.5
	var bw := clampf(w * 0.025, 0.18, 0.45)
	var prev_r := c + basis * Vector3(0, U._roof_y(0.0, -1.0, rise, lift) + bw * 0.4, -hz)
	for i in range(1, 7):
		var s := -1.0 + 2.0 * float(i) / 6.0
		var p := c + basis * Vector3(0, U._roof_y(0.0, s, rise, lift) + bw * 0.4, s * hz)
		lm.beam(key, prev_r, p, bw * 1.2, bw * 1.2, basis.x)
		prev_r = p
	for sgn in [-1.0, 1.0]:
		if ends != 0 and float(ends) != sgn:
			continue
		var z: float = sgn * (hz + 0.05)
		var prev := Vector3.ZERO
		for i in 13:
			var t := -1.0 + 2.0 * float(i) / 12.0
			var p := c + basis * Vector3(t * hx, U._roof_y(t, sgn, rise, lift) + bw * 0.3, z)
			if i > 0:
				lm.beam(key, prev, p, bw * 1.6, bw * 0.8, basis.z)
				if i < 12:
					var m := (prev + p) * 0.5
					lm.beam(key, m, m + basis.y * bw * 2.2 + basis.x * signf(t) * bw * 0.6, bw * 0.5, bw * 0.3, basis.z)
			prev = p
		# Chofa: the slender bird-head finial hooking out from the apex.
		var ap := c + basis * Vector3(0, U._roof_y(0.0, sgn, rise, lift) + bw * 0.5, z)
		var o: Vector3 = basis.z * sgn
		var pts := [ap, ap + basis.y * chofa_h * 0.45 + o * chofa_h * 0.05,
			ap + basis.y * chofa_h * 0.8 + o * chofa_h * 0.2, ap + basis.y * chofa_h + o * chofa_h * 0.45,
			ap + basis.y * chofa_h * 0.9 + o * chofa_h * 0.6]
		for k in pts.size() - 1:
			var ww := bw * (1.6 - 0.3 * float(k))
			lm.beam(key, pts[k], pts[k + 1], ww, ww * 0.6, basis.x)
		# Hang hong: naga tails curling up and out at the two eave corners.
		for sx in [-1.0, 1.0]:
			var e := c + basis * Vector3(sx * hx, U._roof_y(sx, sgn, rise, lift) + bw * 0.3, z)
			var a: Vector3 = basis.x * sx
			var q := [e, e + a * chofa_h * 0.15 + basis.y * chofa_h * 0.25,
				e + a * chofa_h * 0.1 + basis.y * chofa_h * 0.45, e - a * chofa_h * 0.05 + basis.y * chofa_h * 0.5]
			for k in q.size() - 1:
				lm.beam(key, q[k], q[k + 1], bw * (1.3 - 0.3 * float(k)), bw * 0.6, basis.z)
		if tympanum:
			var gz: float = sgn * (l * 0.5 + 0.08)
			var tm := (w * 0.5) / hx
			var ty := U._roof_y(tm, sgn * (l * 0.5) / hz, rise, lift)
			var top_y := U._roof_y(0.0, sgn * (l * 0.5) / hz, rise, lift) - bw * 1.5
			var pa := c + basis * Vector3(-w * 0.42, ty * 0.3 + bw, gz)
			var pb := c + basis * Vector3(w * 0.42, ty * 0.3 + bw, gz)
			var pc := c + basis * Vector3(0, top_y, gz)
			var n: Vector3 = basis.z * sgn
			lm.tri(key, pa, pb, pc, n, n, n, Vector2.ZERO, Vector2(w * 0.84, 0), Vector2(w * 0.42, -top_y))
			lm.disc(key, c + basis * Vector3(0, (ty * 0.3 + top_y) * 0.45, gz + sgn * 0.06), n,
				minf(w * 0.12, top_y * 0.25), 12)

## Green (or other) border along both long eaves of a swept roof: a
## board riding the eave line, as the coloured tile border of Thai roofs.
static func eave_border(lm: LandmarkMesh, key: String, c: Vector3, basis: Basis, w: float, l: float,
		rise: float, lift: float, over: float) -> void:
	var hx := w * 0.5 + over
	var hz := l * 0.5 + over * 0.5
	for sx in [-1.0, 1.0]:
		var prev := Vector3.ZERO
		for i in 7:
			var s := -1.0 + 2.0 * float(i) / 6.0
			var p := c + basis * Vector3(sx * (hx - 0.3), U._roof_y(sx * 0.95, s, rise, lift) + 0.05, s * hz)
			if i > 0:
				lm.beam(key, prev, p, 0.7, 0.3, basis.x * sx)
			prev = p

## One Thai roof piece: tiled swept roof closed by gable walls in
## `wall`, eave border in `border` and gilded trim in `gold`.
static func roof_piece(lm: LandmarkMesh, tile: String, border: String, gold: String, wall: String,
		c: Vector3, basis: Basis, w: float, l: float, rise: float, lift: float, over: float,
		chofa_h: float, ends: int = 0) -> void:
	U.swept_roof(lm, tile, "", wall, c, basis, w, l, rise, lift, over)
	if border != "":
		eave_border(lm, border, c, basis, w, l, rise, lift, over)
	gable_trim(lm, gold, c, basis, w, l, rise, lift, over, chofa_h, true, ends)

## Thai temple roof over a w x l hall (ridge along basis Z), eaves at
## `c`: the main roof, `steps` lower and shorter stepped-down roofs
## (lot chan) at each gable end, `layers` lower skirt roofs (son) on
## the long sides, all tiled with borders and gilded gable trim.
## Returns the height of the main ridge above c.
static func thai_roof(lm: LandmarkMesh, tile: String, border: String, gold: String, wall: String,
		c: Vector3, basis: Basis, w: float, l: float, rise: float, lift: float, steps: int,
		layers: int, chofa_h: float) -> float:
	var main_l := l * (1.0 - 0.14 * float(steps))
	roof_piece(lm, tile, border, gold, wall, c, basis, w, main_l, rise, lift, 0.9, chofa_h)
	var seg := (l - main_l) * 0.5 / maxf(float(steps), 1.0)
	for k in steps:
		var drop := rise * 0.3 * float(k + 1)
		for sgn in [-1.0, 1.0]:
			var zc: float = sgn * (main_l * 0.5 + seg * (float(k) + 0.5))
			roof_piece(lm, tile, border, gold, wall, c + basis * Vector3(0, -drop, zc), basis, w,
				seg + 0.6, rise, lift * 0.6, 0.9, chofa_h * 0.8, int(sgn))
	for j in layers:
		var y := -rise * 0.32 * float(j + 1)
		var wj := w + 3.4 * float(j + 1)
		U.swept_roof(lm, tile, "", "", c + basis * Vector3(0, y, 0), basis, wj, l - 1.0, rise * 0.55,
			lift * 0.5, 1.0)
		if border != "":
			eave_border(lm, border, c + basis * Vector3(0, y, 0), basis, wj, l - 1.0, rise * 0.55, lift * 0.5, 1.0)
	return rise + lift * 0.2

## Convex outline (points in the plane: x along basis X, y up) extruded
## `depth` along basis Z from `c` (the face's centre-line foot): steles,
## pediments, bai sema and boundary stones.
static func outline_prism(lm: LandmarkMesh, key: String, c: Vector3, basis: Basis, pts: PackedVector2Array,
		depth: float) -> void:
	var n := pts.size()
	var hd := depth * 0.5
	for sgn in [-1.0, 1.0]:
		var nz: Vector3 = basis.z * sgn
		for i in range(1, n - 1):
			var a := c + basis * Vector3(pts[0].x, pts[0].y, hd * sgn)
			var b := c + basis * Vector3(pts[i].x, pts[i].y, hd * sgn)
			var d := c + basis * Vector3(pts[i + 1].x, pts[i + 1].y, hd * sgn)
			lm.tri(key, a, b, d, nz, nz, nz, pts[0] * Vector2(1, -1), pts[i] * Vector2(1, -1), pts[i + 1] * Vector2(1, -1))
	for i in n:
		var p := pts[i]
		var q := pts[(i + 1) % n]
		var e := q - p
		var out: Vector3 = basis * Vector3(e.y, -e.x, 0).normalized()
		var ctr := Vector2.ZERO
		for v in pts:
			ctr += v
		ctr /= float(n)
		if (basis * Vector3(p.x - ctr.x, p.y - ctr.y, 0)).dot(out) < 0.0:
			out = -out
		lm.quad(key, c + basis * Vector3(p.x, p.y, -hd), c + basis * Vector3(q.x, q.y, -hd),
			c + basis * Vector3(q.x, q.y, hd), c + basis * Vector3(p.x, p.y, hd), out)

## Pointed (flame) outline w wide and h tall standing on y = 0: the
## sum of Thai windows and the ogee pediments of Bagan.
static func flame_outline(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.46, h * 0.22),
		Vector2(w * 0.34, h * 0.45), Vector2(w * 0.18, h * 0.68), Vector2(w * 0.06, h * 0.88), Vector2(0, h)])

## Thai window or door w x h on a wall facing basis Z at `c` (the
## opening's foot centre on the wall face): a dark recessed leaf, the
## framed jambs, sill and lintel, and the gilded pointed pediment (sum).
static func thai_window(lm: LandmarkMesh, frame: String, dark: String, gold: String, c: Vector3,
		basis: Basis, w: float, h: float) -> void:
	var fw := clampf(w * 0.14, 0.12, 0.4)
	lm.box(dark, c + basis * Vector3(0, h * 0.5, -0.02), Vector3(w, h, 0.1), basis, 0.0)
	for sx in [-1.0, 1.0]:
		lm.box(frame, c + basis * Vector3(sx * (w * 0.5 + fw * 0.5), h * 0.5, 0.06), Vector3(fw, h + fw, 0.24), basis, 0.0)
	lm.box(frame, c + basis * Vector3(0, -fw * 0.4, 0.1), Vector3(w + fw * 3.0, fw * 0.8, 0.32), basis, 0.0)
	lm.box(frame, c + basis * Vector3(0, h + fw * 0.5, 0.08), Vector3(w + fw * 2.6, fw, 0.28), basis, 0.0)
	outline_prism(lm, gold, c + basis * Vector3(0, h + fw, 0.08), basis, flame_outline(w + fw * 2.2, h * 0.75), 0.16)

## Gallery of pillars round a w x d rectangle centred at `c`: thai
## columns every `pitch` m, `h` tall and `cw` wide, with a beam on top.
static func peristyle(lm: LandmarkMesh, key: String, cap: String, c: Vector3, basis: Basis, w: float,
		d: float, h: float, cw: float, pitch: float) -> void:
	var nx := maxi(int(round(w / pitch)), 1)
	var nz := maxi(int(round(d / pitch)), 1)
	for i in nx + 1:
		for sz in [-1.0, 1.0]:
			thai_column(lm, key, cap, c + basis * Vector3(-w * 0.5 + w * float(i) / float(nx), 0, sz * d * 0.5), cw, h)
	for i in range(1, nz):
		for sx in [-1.0, 1.0]:
			thai_column(lm, key, cap, c + basis * Vector3(sx * w * 0.5, 0, -d * 0.5 + d * float(i) / float(nz)), cw, h)
	for sz in [-1.0, 1.0]:
		lm.box(cap, c + basis * Vector3(0, h + 0.2, sz * d * 0.5), Vector3(w + cw, 0.4, cw * 0.9), basis)
	for sx in [-1.0, 1.0]:
		lm.box(cap, c + basis * Vector3(sx * w * 0.5, h + 0.2, 0), Vector3(cw * 0.9, 0.4, d + cw), basis)

## Moulded Thai plinth (than singh) w x d, h tall at `c`: a foot, the
## lion-leg recess, a lotus band and the top slab.
static func plinth(lm: LandmarkMesh, key: String, c: Vector3, basis: Basis, w: float, d: float, h: float) -> void:
	lm.box(key, c + basis * Vector3(0, h * 0.12, 0), Vector3(w + 0.8, h * 0.24, d + 0.8), basis)
	lm.box(key, c + basis * Vector3(0, h * 0.42, 0), Vector3(w - 0.2, h * 0.36, d - 0.2), basis)
	lm.box(key, c + basis * Vector3(0, h * 0.68, 0), Vector3(w + 0.3, h * 0.16, d + 0.3), basis)
	lm.box(key, c + basis * Vector3(0, h * 0.88, 0), Vector3(w + 0.5, h * 0.24, d + 0.5), basis)

## Seated Buddha image of height h (lap to crown) on its pedestal at
## `base`, facing basis Z: crossed legs, body, head with the flame.
static func seated_buddha(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, h: float) -> void:
	lm.box(key, base + basis * Vector3(0, h * 0.1, 0), Vector3(h * 0.85, h * 0.2, h * 0.55), basis, 0.0)
	lm.lathe(key, base + Vector3(0, h * 0.2, 0), PackedVector2Array([Vector2(h * 0.38, 0), Vector2(h * 0.36, h * 0.1),
		Vector2(h * 0.2, h * 0.16), Vector2(h * 0.17, h * 0.3), Vector2(h * 0.2, h * 0.48), Vector2(h * 0.08, h * 0.56)]),
		6, 1.0, 0.75, basis.get_euler().y)
	lm.lathe(key, base + Vector3(0, h * 0.74, 0), PackedVector2Array([Vector2(h * 0.04, 0), Vector2(h * 0.1, h * 0.04),
		Vector2(h * 0.1, h * 0.14), Vector2(h * 0.06, h * 0.2), Vector2(0.0, h * 0.26)]), 6)

## Redented bell chedi (chedi yo mum) of total height h and bell
## half-width r: stepped redented plinths, the lion-throne and lotus
## mouldings, the redented bell, the redented harmika, a ringed round
## spire (pli) and the gilded tip. `body` draws the bell and spire,
## `base_key` the plinths, `gold` the tip.
static func redent_chedi(lm: LandmarkMesh, body: String, base_key: String, gold: String, base: Vector3,
		r: float, h: float, notch: float = 0.12) -> void:
	redent_lathe(lm, base_key, base, PackedVector2Array([Vector2(r * 1.7, 0), Vector2(r * 1.7, h * 0.04),
		Vector2(r * 1.55, h * 0.045), Vector2(r * 1.55, h * 0.08), Vector2(r * 1.42, h * 0.085),
		Vector2(r * 1.42, h * 0.12), Vector2(r * 1.3, h * 0.125), Vector2(r * 1.22, h * 0.15),
		Vector2(r * 1.3, h * 0.17), Vector2(r * 1.15, h * 0.18), Vector2(r * 1.15, h * 0.2)]), notch)
	var prof := PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r * 1.05, h * 0.01), Vector2(r * 1.1, h * 0.025),
		Vector2(r * 1.0, h * 0.035), Vector2(r * 1.04, h * 0.05), Vector2(r * 1.0, h * 0.07),
		Vector2(r * 0.97, h * 0.1), Vector2(r * 0.88, h * 0.14), Vector2(r * 0.72, h * 0.18),
		Vector2(r * 0.52, h * 0.21), Vector2(r * 0.4, h * 0.225), Vector2(r * 0.42, h * 0.235),
		Vector2(r * 0.42, h * 0.26), Vector2(r * 0.48, h * 0.27), Vector2(r * 0.3, h * 0.28)])
	redent_lathe(lm, body, base + Vector3(0, h * 0.2, 0), prof, notch)
	var rp := PackedVector2Array()
	for i in 10:
		var rr := r * 0.27 * (1.0 - float(i) / 11.0)
		var y := h * 0.032 * float(i)
		rp.append(Vector2(rr, y))
		rp.append(Vector2(rr * 1.22, y + h * 0.008))
		rp.append(Vector2(rr * 1.05, y + h * 0.024))
	rp.append(Vector2(r * 0.05, h * 0.33))
	lm.lathe(body, base + Vector3(0, h * 0.48, 0), rp, 12)
	lm.lathe(gold, base + Vector3(0, h * 0.81, 0), PackedVector2Array([Vector2(r * 0.06, 0),
		Vector2(r * 0.1, h * 0.02), Vector2(r * 0.05, h * 0.06), Vector2(r * 0.07, h * 0.08),
		Vector2(r * 0.03, h * 0.12), Vector2(0.0, h * 0.19)]), 8)

## Rattanakosin / Ayutthaya prang of total height h and body half-width
## hw: a redented plinth in three receding tiers, the redented body
## with a porch and doorway on each face, then the ribbed corn-cob
## crown of `tiers` redented storeys (each a moulded band under a row of
## petal antefixes) and the gilded trident needle in `gold`.
static func redent_prang(lm: LandmarkMesh, wall: String, dark: String, gold: String, base: Vector3,
		hw: float, h: float, tiers: int = 6, porches: bool = true) -> void:
	var y := 0.0
	for k in 3:
		var w0 := hw * (1.9 - 0.22 * float(k))
		var th := h * 0.045
		redent_lathe(lm, wall, base + Vector3(0, y, 0), PackedVector2Array([Vector2(w0 * 1.04, 0),
			Vector2(w0, th * 0.25), Vector2(w0, th * 0.75), Vector2(w0 * 1.04, th)]), 0.1)
		y += th
	var bh := h * 0.2
	redent_lathe(lm, wall, base + Vector3(0, y, 0), PackedVector2Array([Vector2(hw * 1.1, 0),
		Vector2(hw, bh * 0.1), Vector2(hw, bh * 0.85), Vector2(hw * 1.12, bh * 0.92), Vector2(hw * 1.12, bh)]), 0.14)
	if porches:
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box(wall, base + b * Vector3(0, y + bh * 0.42, hw * 1.12), Vector3(hw * 0.8, bh * 0.84, hw * 0.4), b)
			lm.box(dark, base + b * Vector3(0, y + bh * 0.3, hw * 1.33), Vector3(hw * 0.36, bh * 0.56, 0.1), b, 0.0)
			outline_prism(lm, wall, base + b * Vector3(0, y + bh * 0.84, hw * 1.22), b,
				flame_outline(hw * 0.9, bh * 0.5), hw * 0.2)
	y += bh
	var top := h * 0.94 - y
	var th2 := top / float(tiers)
	var w := hw * 1.02
	for k in tiers:
		var f := 1.0 - float(k + 1) / float(tiers) * 0.72
		var wn := hw * f
		redent_lathe(lm, wall, base + Vector3(0, y, 0), PackedVector2Array([Vector2(w, 0),
			Vector2(w * 1.06, th2 * 0.12), Vector2(w * 0.96, th2 * 0.24), Vector2((w + wn) * 0.5, th2 * 0.7),
			Vector2(wn * 1.02, th2)]), 0.14)
		# Petal antefixes (bai raka) on the corners of the tier's band.
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side) + PI * 0.25)
			lm.beam(wall, base + b * Vector3(0, y + th2 * 0.2, w * 1.25),
				base + b * Vector3(0, y + th2 * 0.75, w * 1.12), w * 0.22, w * 0.08, b.x)
		y += th2
		w = wn
	lm.lathe(wall, base + Vector3(0, y, 0), PackedVector2Array([Vector2(w, 0), Vector2(w * 0.6, h * 0.02),
		Vector2(w * 0.2, h * 0.035)]), 12)
	lm.beam(gold, base + Vector3(0, y + h * 0.03, 0), base + Vector3(0, h, 0), hw * 0.06, hw * 0.06)
	lm.beam(gold, base + Vector3(-hw * 0.12, h * 0.985, 0), base + Vector3(hw * 0.12, h * 0.985, 0), hw * 0.04, hw * 0.04)

## Wall run a..b `h` tall and `t` thick, crowned by bai sema merlons
## (pointed leaf-shaped crenels) every `step` m.
static func sema_wall(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, t: float,
		step: float = 2.4) -> void:
	var d := b - a
	var length := d.length()
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	lm.box(key, (a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(t, h, length), basis)
	lm.box(key, (a + b) * 0.5 + Vector3(0, h + 0.12, 0), Vector3(t * 1.2, 0.24, length), basis)
	var side := Basis(Vector3.UP, atan2(d.x, d.z) + PI * 0.5)
	var n := int(length / step)
	var leaf := PackedVector2Array([Vector2(-step * 0.3, 0), Vector2(step * 0.3, 0), Vector2(step * 0.3, 0.55),
		Vector2(step * 0.2, 0.95), Vector2(0, 1.25), Vector2(-step * 0.2, 0.95), Vector2(-step * 0.3, 0.55)])
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		outline_prism(lm, key, p + Vector3(0, h + 0.24, 0), side, leaf, t * 0.9)

## Thai ordination hall (ubosot / viharn) at ground point `c`, long
## axis along basis Z with the front at +Z: the moulded plinth, a w x l
## walled body wall_h tall with `bays` pointed windows on each long side
## and three doors at each end, the peristyle of notched columns `peri`
## metres outside the walls (none when 0), and the stepped and layered
## Thai roof. Keys: k = {wall, stone, tile, border, gold, dark, col}.
## Returns the height of the main ridge above the ground.
static func thai_hall(lm: LandmarkMesh, k: Dictionary, c: Vector3, basis: Basis, w: float, l: float,
		wall_h: float, bays: int, peri: float, steps: int, layers: int, rise: float, plinth_h: float = 1.4) -> float:
	var wall: String = k["wall"]
	var dark: String = k["dark"]
	var gold: String = k["gold"]
	var col: String = k.get("col", gold)
	var pw := w + peri * 2.0
	var pl := l + peri * 2.0
	plinth(lm, k["stone"], c, basis, pw + 2.0, pl + 2.0, plinth_h)
	var y0 := plinth_h
	lm.box(wall, c + basis * Vector3(0, y0 + wall_h * 0.5, 0), Vector3(w, wall_h, l), basis)
	lm.box(wall, c + basis * Vector3(0, y0 + 0.3, 0), Vector3(w + 0.4, 0.6, l + 0.4), basis)
	lm.box(gold, c + basis * Vector3(0, y0 + wall_h - 0.35, 0), Vector3(w + 0.3, 0.5, l + 0.3), basis)
	var wh := wall_h * 0.42
	var ww := minf(l / float(bays) * 0.42, 2.2)
	for sx in [-1.0, 1.0]:
		var sb := basis * Basis(Vector3.UP, PI * 0.5 * sx)
		for i in bays:
			var z := -l * 0.5 + l * (float(i) + 0.5) / float(bays)
			thai_window(lm, wall, dark, gold, c + basis * Vector3(sx * (w * 0.5 + 0.02), y0 + wall_h * 0.22, z), sb, ww, wh)
	for sz in [-1.0, 1.0]:
		var eb := basis * Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		for dx in [-w * 0.3, 0.0, w * 0.3]:
			var dw := w * (0.14 if dx == 0.0 else 0.1)
			thai_window(lm, wall, dark, gold, c + basis * Vector3(dx, y0, sz * (l * 0.5 + 0.02)), eb, dw, wall_h * 0.6)
	var ry := y0 + wall_h
	if peri > 0.0:
		var nb := maxi(int(round(pl / 2.6)), 2)
		peristyle(lm, col, gold, c + basis * Vector3(0, y0, 0), basis, pw, pl, wall_h, clampf(peri * 0.28, 0.5, 0.9),
			pl / float(nb))
		ry += 0.4
	var rw := w + peri * 1.2
	return ry + thai_roof(lm, k["tile"], k["border"], gold, wall, c + basis * Vector3(0, ry, 0), basis,
		rw, pl + 1.0, rise, rise * 0.25, steps, layers, clampf(rise * 0.45, 1.0, 3.0))
