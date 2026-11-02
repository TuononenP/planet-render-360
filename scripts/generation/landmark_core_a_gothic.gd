class_name LandmarkCoreAGothic
extends RefCounted

## Gothic detail kits for the core landmarks (Turku Cathedral, the
## Palace of Westminster, Sagrada Família), in true metres on
## LandmarkMesh:
##   lancet        - pointed-arch opening with a projecting surround,
##                   real reveals, glass at the back, mullions, tracery
##                   and a hood mould
##   buttress      - stepped buttress with sloped weatherings
##   pinnacle      - square pinnacle: shaft, gablets, crocketed spirelet
##   stepped_gable - Baltic brick stepped gable with blind niches
##   parapet       - panelled parapet with pinnacles on its piers

## Outline of a pointed-arch opening `w` wide, `h` tall to the apex, on
## the local (x right, y up) plane, from the bottom-left corner up, over
## the apex and down to the bottom-right (clockwise). `sharp` 0.5 is a
## round head, 1.0 an equilateral arch; `seg` points per arc.
static func arch_outline(w: float, h: float, sharp: float = 1.0, seg: int = 6) -> PackedVector2Array:
	var a := w * 0.5
	var r := maxf(sharp * w, a)
	var c := r - a
	var rise := sqrt(maxf(r * r - c * c, 0.0))
	var spring := maxf(h - rise, 0.0)
	var pts := PackedVector2Array()
	pts.append(Vector2(-a, 0))
	# Left arc: centre (c, spring), from the springer (angle PI) up to
	# the apex where x = 0.
	var t1 := acos(clampf(c / r, -1.0, 1.0))
	for i in seg + 1:
		var t := lerpf(PI, PI - t1, float(i) / float(seg))
		pts.append(Vector2(c + r * cos(t), spring + r * sin(t)))
	pts[pts.size() - 1] = Vector2(0.0, spring + rise)
	for i in range(seg - 1, -1, -1):
		var p := pts[i + 1]
		pts.append(Vector2(-p.x, p.y))
	pts.append(Vector2(a, 0))
	return pts

## In-plane normal of an outline edge pointing into the opening.
static func _inward(e: Vector2) -> Vector2:
	return Vector2(e.y, -e.x).normalized()

## Pointed-arch opening (window, door or blind niche) whose bottom
## centre is `c` on a wall face facing `normal`: a surround `frame` wide
## standing `depth` proud of the face, reveals back to the face, `glass`
## filling the opening, `lights` lights split by mullions with sub-arches
## and an oculus in the head, and a hood mould over the arch.
static func lancet(lm: LandmarkMesh, wall: String, glass: String, c: Vector3, normal: Vector3,
		w: float, h: float, depth: float = 0.4, lights: int = 2, sharp: float = 1.0,
		hood: bool = true, frame: float = -1.0) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var fw := frame if frame > 0.0 else clampf(w * 0.12, 0.12, 0.8)
	var inner := arch_outline(w, h, sharp)
	var outer := arch_outline(w + fw * 2.0, h + fw, sharp)
	var P := func(q: Vector2, d: float) -> Vector3:
		return c + r * q.x + Vector3.UP * q.y + n * d
	var N := func(q: Vector2) -> Vector3:
		return r * q.x + Vector3.UP * q.y
	for i in inner.size() - 1:
		var i0 := inner[i]
		var i1 := inner[i + 1]
		if i0.distance_to(i1) < 0.001:
			continue
		var o0 := outer[i]
		var o1 := outer[i + 1]
		lm.quad(wall, P.call(o0, depth), P.call(o1, depth), P.call(i1, depth), P.call(i0, depth), n)
		var ni: Vector3 = N.call(_inward(i1 - i0))
		lm.quad(wall, P.call(i0, depth), P.call(i1, depth), P.call(i1, 0.0), P.call(i0, 0.0), ni)
		lm.quad(wall, P.call(o0, 0.0), P.call(o1, 0.0), P.call(o1, depth), P.call(o0, depth), -ni)
	# Sill: a sloped weathering across the bottom of the opening.
	var a := w * 0.5
	lm.quad(wall, P.call(Vector2(-a, 0.0), 0.0), P.call(Vector2(a, 0.0), 0.0),
		P.call(Vector2(a, -fw * 0.4), depth + fw * 0.3), P.call(Vector2(-a, -fw * 0.4), depth + fw * 0.3),
		(n + Vector3.UP).normalized())
	# Glass (or the niche's back) as a fan just in front of the face.
	var g := Vector2(0.0, 0.0)
	for i in inner.size() - 1:
		if inner[i].distance_to(inner[i + 1]) < 0.001:
			continue
		lm.tri(glass, P.call(g, 0.03), P.call(inner[i], 0.03), P.call(inner[i + 1], 0.03), n, n, n,
			g, inner[i], inner[i + 1])
	var bar := fw * 0.45
	var td := depth * 0.45
	if lights >= 2:
		var lw := w / float(lights)
		var top_y := inner[inner.size() / 2].y
		var spring := inner[1].y
		for k in range(1, lights):
			var x := -a + lw * float(k)
			lm.beam(wall, P.call(Vector2(x, 0.0), td), P.call(Vector2(x, spring + lw * 0.5), td), bar, depth * 0.5, n)
		# Sub-arches over each light and an oculus in the head.
		var sub_h := spring + lw * 0.85
		for k in lights:
			var cx := -a + lw * (float(k) + 0.5)
			var so := arch_outline(lw, sub_h, sharp, 4)
			for i in range(1, so.size() - 2):
				lm.beam(wall, P.call(so[i] + Vector2(cx, 0), td), P.call(so[i + 1] + Vector2(cx, 0), td),
					bar * 0.8, depth * 0.4, n)
		var oc := Vector2(0.0, (sub_h + top_y) * 0.5)
		var orad := minf((top_y - sub_h) * 0.38, a * 0.45)
		if orad > 0.2:
			for i in 8:
				var t0 := TAU * float(i) / 8.0
				var t1 := TAU * float(i + 1) / 8.0
				lm.beam(wall, P.call(oc + Vector2(cos(t0), sin(t0)) * orad, td),
					P.call(oc + Vector2(cos(t1), sin(t1)) * orad, td), bar * 0.7, depth * 0.4, n)
	if hood:
		var hd := depth + fw * 0.35
		for i in range(1, outer.size() - 2):
			var off := _inward(outer[i + 1] - outer[i]) * -fw * 0.35
			lm.beam(wall, P.call(outer[i] + off, hd), P.call(outer[i + 1] + off, hd), fw * 0.5, fw * 0.5, n)
		# Label stops.
		for s in [-1.0, 1.0]:
			lm.box(wall, P.call(Vector2(s * (a + fw * 1.2), outer[1].y - fw * 0.3), hd),
				Vector3(fw * 0.6, fw * 0.9, fw * 0.6), Basis(r, Vector3.UP, n), 0.0)

## Stepped buttress against a wall at `base` (on the wall face),
## projecting along `out`: `stages` stages each set back with a sloped
## weathering, `w` wide, `d` deep at the foot, `h` tall.
static func buttress(lm: LandmarkMesh, key: String, base: Vector3, out: Vector3, w: float,
		d: float, h: float, stages: int = 2) -> void:
	var o := out.normalized()
	var r := Vector3.UP.cross(o).normalized()
	var basis := Basis(r, Vector3.UP, o)
	var hs := h / float(stages)
	for k in stages:
		var dk := d * (1.0 - 0.32 * float(k))
		var dn := d * (1.0 - 0.32 * float(k + 1)) if k < stages - 1 else 0.0
		var y0 := hs * float(k)
		var body := hs - dk * 0.35
		lm.box(key, base + o * dk * 0.5 + Vector3(0, y0 + body * 0.5, 0), Vector3(w, body, dk), basis)
		# Weathering: slopes from the stage's face back to the next stage.
		var lo := base + Vector3(0, y0 + body, 0)
		var hi := base + Vector3(0, y0 + hs, 0)
		var rw := r * w * 0.5
		lm.quad(key, lo + o * dk - rw, lo + o * dk + rw, hi + o * dn + rw, hi + o * dn - rw,
			(o * (hs - body) + Vector3.UP * (dk - dn)).normalized())
		for s in [-1.0, 1.0]:
			var sv: Vector3 = r * float(s) * w * 0.5
			lm.tri(key, lo + sv, lo + o * dk + sv, hi + o * dn + sv, r * float(s), r * float(s), r * float(s),
				Vector2.ZERO, Vector2(dk, 0), Vector2(dn, hs - body))
			if dn > 0.0:
				lm.tri(key, lo + sv, hi + o * dn + sv, hi + sv, r * float(s), r * float(s), r * float(s),
					Vector2.ZERO, Vector2(dn, hs - body), Vector2(0, hs - body))

## Square Gothic pinnacle of half-width `hw` and height `h` from `base`:
## panelled shaft, a gablet on each face, crocketed spirelet, finial.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, hw: float, h: float,
		crockets: bool = true) -> void:
	var shaft := h * 0.42
	lm.box(key, base + Vector3(0, shaft * 0.5, 0), Vector3(hw * 2.0, shaft, hw * 2.0))
	lm.box(key, base + Vector3(0, hw * 0.15, 0), Vector3(hw * 2.3, hw * 0.3, hw * 2.3))
	for s in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(s))
		lm.gable(key, base + Vector3(0, shaft, 0) + rot * Vector3(0, 0, hw * 0.55), hw * 2.0, hw * 1.1,
			hw * 1.3, rot, 0.0, key)
	var sp := h - shaft - hw * 0.6
	lm.spire(key, base + Vector3(0, shaft, 0), hw * 0.95, sp)
	if crockets:
		for k in 3:
			var t := 0.25 + 0.22 * float(k)
			var y := shaft + sp * t
			var e := hw * 0.95 * (1.0 - t)
			for s in 4:
				var d := Vector3(1, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(s)).normalized()
				lm.box(key, base + Vector3(0, y, 0) + d * (e * 1.41 + hw * 0.12),
					Vector3(hw * 0.28, hw * 0.22, hw * 0.28), Basis(Vector3.UP, PI * 0.25), 0.0)
	var tip := base + Vector3(0, shaft + sp, 0)
	lm.frustum(key, tip - Vector3(0, hw * 0.3, 0), hw * 0.18, hw * 0.08, hw * 0.9, 6)
	lm.box(key, tip + Vector3(0, hw * 0.25, 0), Vector3(hw * 0.6, hw * 0.12, hw * 0.12), Basis(), 0.0)
	lm.box(key, tip + Vector3(0, hw * 0.25, 0), Vector3(hw * 0.12, hw * 0.12, hw * 0.6), Basis(), 0.0)

## Stepped gable (Baltic brick Gothic) standing on the eave line at `c`
## (centre of the gable's base on the wall face), facing `out`: `w`
## wide, `rise` tall, `thick` deep, `steps` steps a side, and `niches`
## whitewashed pointed blind niches (in `trim`) rising with the steps.
static func stepped_gable(lm: LandmarkMesh, wall: String, trim: String, c: Vector3, out: Vector3,
		w: float, rise: float, thick: float, steps: int, niches: int) -> void:
	var o := out.normalized()
	var r := Vector3.UP.cross(o).normalized()
	var basis := Basis(r, Vector3.UP, o)
	var n_tiers := steps + 1
	var th := rise / float(n_tiers)
	for k in n_tiers:
		var ww := w * (1.0 - float(k) / float(n_tiers))
		lm.box(wall, c + Vector3(0, th * (float(k) + 0.5), 0) - o * thick * 0.5, Vector3(ww, th, thick), basis)
		# Coping on each step.
		lm.box(wall, c + Vector3(0, th * (float(k) + 1.0) + 0.08, 0) - o * thick * 0.5,
			Vector3(ww + 0.2, 0.16, thick + 0.2), basis, 0.0)
	if niches > 0:
		var pitch := w / float(niches + 1)
		for k in niches:
			var x := -w * 0.5 + pitch * (float(k) + 1.0)
			var top_w := w * 0.5 - absf(x) - pitch * 0.25
			var nh := clampf(rise * (top_w / (w * 0.5)) * 0.92, 1.0, rise * 0.85)
			lancet(lm, wall, trim, c + r * x + Vector3(0, th * 0.35, 0), o, pitch * 0.5, nh, 0.2, 1, 0.9,
				false, pitch * 0.08)

## Panelled parapet along a-b on the wall top (face line), `h` tall and
## `thick` deep, with a pier and a small pinnacle every `bay` metres.
static func parapet(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, h: float,
		thick: float, bay: float, pin_h: float = 0.0) -> void:
	var o := out.normalized()
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	lm.box(key, (a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(dl, h, thick), basis)
	lm.box(key, (a + b) * 0.5 + Vector3(0, h + 0.1, 0) + o * 0.05, Vector3(dl + 0.2, 0.2, thick + 0.25), basis, 0.0)
	var n := maxi(int(round(dl / bay)), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box(key, p + Vector3(0, h * 0.6, 0) + o * thick * 0.3, Vector3(thick * 0.9, h * 1.2, thick * 1.4), basis)
		if pin_h > 0.0:
			pinnacle(lm, key, p + Vector3(0, h * 1.2, 0) + o * thick * 0.3, thick * 0.45, pin_h, false)
	# Sunk panels between the piers.
	for i in n:
		var m := a.lerp(b, (float(i) + 0.5) / float(n)) + o * (thick * 0.5 + 0.03)
		lm.box(key, m + Vector3(0, h * 0.5, 0), Vector3(dl / float(n) * 0.6, h * 0.12, 0.06), basis, 0.0)
		lm.box(key, m + Vector3(0, h * 0.2, 0), Vector3(dl / float(n) * 0.6, h * 0.08, 0.06), basis, 0.0)
		lm.box(key, m + Vector3(0, h * 0.8, 0), Vector3(dl / float(n) * 0.6, h * 0.08, 0.06), basis, 0.0)
