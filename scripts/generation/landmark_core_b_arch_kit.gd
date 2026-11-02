class_name LandmarkCoreBArchKit
extends RefCounted

## Small parts shared by the generic archetype models
## (LandmarkArchetypes): Gothic lancet and rose windows, stepped
## buttresses, pinnacles, crenellated parapets, arrow slits, crosses and
## dome profiles, in true metres on LandmarkMesh.

## Points of a two-centred pointed arch over an opening `w` wide whose
## springing line is centred at `c` on a wall with in-plane `right`,
## from the left springing through the apex to the right springing.
## Each arc's radius is 0.85 w (a lancet a little steeper than
## equilateral); rise = 0.775 w.
static func pointed(c: Vector3, right: Vector3, w: float, seg: int = 5) -> PackedVector3Array:
	var rr := w * 0.85
	var cx := rr - w * 0.5
	var t_apex := acos(-cx / rr)
	var pts := PackedVector3Array()
	for i in seg + 1:
		var t := lerpf(PI, t_apex, float(i) / float(seg))
		pts.append(c + right * (cx + rr * cos(t)) + Vector3.UP * rr * sin(t))
	for i in range(seg - 1, -1, -1):
		var t := lerpf(PI, t_apex, float(i) / float(seg))
		pts.append(c - right * (cx + rr * cos(t)) + Vector3.UP * rr * sin(t))
	return pts

## Rise of `pointed` over its springing line.
static func pointed_rise(w: float) -> float:
	var rr := w * 0.85
	var cx := rr - w * 0.5
	return rr * sin(acos(-cx / rr))

## Gothic lancet window, opening `w` wide and `h` to the apex, its sill
## centred at `foot` on a wall facing `n`: glass on the wall face, a
## moulded frame and sill projecting `depth`, a hood mould over the
## head, and (when `tracery`) a mullion parting two sub-lancets under
## an oculus.
static func lancet(lm: LandmarkMesh, frame: String, glass: String, foot: Vector3, n: Vector3,
		w: float, h: float, depth: float = 0.3, tracery: bool = false) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var rise := pointed_rise(w)
	var sh := maxf(h - rise, 0.1)
	var g := foot + nn * 0.03
	var spring := g + Vector3.UP * sh
	lm.quad(glass, g - right * w * 0.5, g + right * w * 0.5, spring + right * w * 0.5,
		spring - right * w * 0.5, nn)
	var arc := pointed(spring, right, w, 4)
	for i in arc.size() - 1:
		lm.tri(glass, spring, arc[i], arc[i + 1], nn, nn, nn, Vector2.ZERO,
			Vector2(arc[i].x, -arc[i].y), Vector2(arc[i + 1].x, -arc[i + 1].y))
	# Frame: jambs, the arch ring, sill.
	var fw := clampf(w * 0.12, 0.1, 0.5)
	var fc := foot + nn * depth * 0.5
	var ring := pointed(fc + Vector3.UP * sh, right, w + fw, 3)
	for s in [-1.0, 1.0]:
		lm.beam(frame, fc + right * (w + fw) * 0.5 * s, fc + right * (w + fw) * 0.5 * s + Vector3.UP * sh,
			fw, depth, right)
	for i in ring.size() - 1:
		lm.beam(frame, ring[i], ring[i + 1], fw, depth, nn.cross(ring[i + 1] - ring[i]))
	lm.box(frame, foot + nn * depth * 0.7 - Vector3.UP * fw * 0.25, Vector3(w + fw * 3.0, fw * 0.5, depth * 1.4),
		Basis(right, Vector3.UP, nn), 0.0)
	# Hood mould (dripstone) over the head, ending in label stops.
	var hood := pointed(foot + nn * depth * 0.8 + Vector3.UP * sh, right, w + fw * 3.4, 2)
	for i in hood.size() - 1:
		lm.beam(frame, hood[i], hood[i + 1], fw * 0.6, depth * 0.5, nn.cross(hood[i + 1] - hood[i]))
	if tracery and w > 1.0:
		var mb := g + nn * 0.04
		lm.beam(frame, mb, mb + Vector3.UP * (sh + rise * 0.25), fw * 0.6, depth * 0.6, right)
		for s in [-1.0, 1.0]:
			var sub := pointed(mb + right * w * 0.25 * s + Vector3.UP * sh, right, w * 0.5, 2)
			for i in sub.size() - 1:
				lm.beam(frame, sub[i], sub[i + 1], fw * 0.5, depth * 0.5, nn.cross(sub[i + 1] - sub[i]))
		ring_beams(lm, frame, mb + Vector3.UP * (sh + rise * 0.58), nn, w * 0.2, fw * 0.45, 6)

## A ring of `seg` short beams of radius r on a wall facing `n`.
static func ring_beams(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, r: float, bw: float,
		seg: int) -> void:
	var nn := n.normalized()
	var a := Vector3.UP.cross(nn).normalized()
	if a.length() < 0.5:
		a = Vector3.RIGHT
	var b := nn.cross(a)
	for i in seg:
		var t0 := TAU * float(i) / float(seg)
		var t1 := TAU * float(i + 1) / float(seg)
		var p0 := c + (a * cos(t0) + b * sin(t0)) * r
		var p1 := c + (a * cos(t1) + b * sin(t1)) * r
		lm.beam(key, p0, p1, bw, bw, nn.cross(p1 - p0))

## Rose window of radius r centred at `c` on a wall facing `n`: glass
## disc, moulded outer and inner rings, radiating mullions and a ring
## of foiled roundels.
static func rose(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, n: Vector3, r: float) -> void:
	var nn := n.normalized()
	lm.disc(glass, c + nn * 0.03, nn, r, 24)
	var bw := clampf(r * 0.08, 0.12, 0.6)
	var f := c + nn * bw * 0.5
	ring_beams(lm, frame, f, nn, r + bw * 0.5, bw * 1.4, 24)
	ring_beams(lm, frame, f, nn, r * 0.3, bw, 12)
	var a := Vector3.UP.cross(nn).normalized()
	var b := nn.cross(a)
	for i in 12:
		var t := TAU * float(i) / 12.0
		var d := a * cos(t) + b * sin(t)
		lm.beam(frame, f + d * r * 0.3, f + d * r, bw * 0.6, bw * 0.8, nn.cross(d))
		var t2 := t + PI / 12.0
		ring_beams(lm, frame, f + (a * cos(t2) + b * sin(t2)) * r * 0.7, nn, r * 0.13, bw * 0.4, 5)

## Stepped buttress against a wall: foot centred on the wall face at
## `foot`, projecting along `n`, `wd` wide, `depth` deep at the base,
## `h` tall, with two set-offs and sloped weatherings.
static func buttress(lm: LandmarkMesh, key: String, foot: Vector3, n: Vector3, wd: float, depth: float,
		h: float) -> void:
	var nn := n.normalized()
	var right := Vector3.UP.cross(nn).normalized()
	var basis := Basis(right, Vector3.UP, nn)
	var stages := [[0.0, 0.45, 1.0], [0.45, 0.8, 0.72], [0.8, 1.0, 0.45]]
	for st in stages:
		var y0 := h * float(st[0])
		var y1 := h * float(st[1])
		var d := depth * float(st[2])
		lm.box(key, foot + nn * d * 0.5 + Vector3.UP * (y0 + y1) * 0.5, Vector3(wd, y1 - y0, d), basis)
		# Weathering: a sloped cap shedding water off the set-off.
		var top := foot + Vector3.UP * y1
		lm.quad(key, top + nn * d - right * wd * 0.5, top + nn * d + right * wd * 0.5,
			top + right * wd * 0.5 + Vector3.UP * d * 0.6, top - right * wd * 0.5 + Vector3.UP * d * 0.6,
			(nn + Vector3.UP).normalized())
		for s in [-1.0, 1.0]:
			lm.tri(key, top + nn * d + right * wd * 0.5 * s, top + right * wd * 0.5 * s,
				top + right * wd * 0.5 * s + Vector3.UP * d * 0.6, right * s, right * s, right * s,
				Vector2.ZERO, Vector2(d, 0), Vector2(0, -d * 0.6))

## Gothic pinnacle at `base`: square shaft with gablets, crocketed
## needle and a finial knob; `hw` half-width, `h` overall height.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, hw: float, h: float) -> void:
	var shaft := h * 0.4
	lm.box(key, base + Vector3.UP * shaft * 0.5, Vector3(hw * 2.0, shaft, hw * 2.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		lm.gable(key, base + Vector3.UP * shaft + r * Vector3(0, 0, hw * 0.5), hw * 2.0, hw, hw * 0.9, r, 0.05)
	lm.spire(key, base + Vector3.UP * shaft, hw * 0.85, h * 0.6 - hw * 0.2)
	for k in 3:
		var y := shaft + (h * 0.6) * (0.2 + 0.22 * float(k))
		var rr := hw * 0.85 * (1.0 - (0.2 + 0.22 * float(k))) + hw * 0.18
		lm.frustum(key, base + Vector3.UP * y, rr, rr * 0.6, hw * 0.25, 4, PI * 0.25)
	lm.frustum(key, base + Vector3.UP * (h - hw * 0.25), hw * 0.22, hw * 0.05, hw * 0.25, 6)

## Crenellated parapet along a-b (top of the wall, outer face line):
## a breastwork band, merlons `mw` wide every 2 mw, `out` the outward
## normal; optional machicolation corbels under a projecting parapet.
static func battlement(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, thick: float,
		mw: float, mach: bool = false) -> void:
	var dir := (b - a).normalized()
	var o := out.normalized()
	var basis := Basis(dir, Vector3.UP, o)
	var dl := a.distance_to(b)
	var proj := mw * 0.45 if mach else 0.0
	var mid := (a + b) * 0.5 + o * (proj - thick * 0.5)
	if mach:
		# Corbels (brackets) every merlon-width carry the parapet out.
		var nc := maxi(int(dl / mw), 2)
		for i in nc:
			var p := a.lerp(b, (float(i) + 0.5) / float(nc))
			lm.box(key, p + o * proj * 0.5 - Vector3.UP * mw * 0.45, Vector3(mw * 0.35, mw * 0.9, proj), basis, 0.0)
		lm.box(key, mid + Vector3.UP * mw * 0.05, Vector3(dl + proj * 2.0, mw * 0.2, thick), basis)
	lm.box(key, mid + Vector3.UP * mw * 0.55, Vector3(dl + proj * 2.0, mw * 0.9, thick * 0.6), basis)
	var n := maxi(int(dl / (mw * 2.0)), 1)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n)) + o * (proj - thick * 0.5)
		lm.box(key, p + Vector3.UP * mw * 1.45, Vector3(mw, mw * 0.9, thick * 0.6), basis, 0.0)

## Crenellated parapet round a circle (round towers).
static func battlement_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, mw: float,
		mach: bool = false) -> void:
	var proj := mw * 0.45 if mach else 0.0
	var seg := clampi(int(TAU * r / mw), 8, 24)
	if mach:
		lm.lathe(key, c - Vector3.UP * mw * 0.9, PackedVector2Array([Vector2(r, 0), Vector2(r + proj * 0.4, mw * 0.5),
			Vector2(r + proj, mw * 0.9)]), seg, 1.0, 1.0, 0.0, true, false)
		for i in seg:
			var a := TAU * (float(i) + 0.5) / float(seg)
			var d := Vector3(cos(a), 0, sin(a))
			lm.box(key, c + d * (r + proj * 0.5) - Vector3.UP * mw * 0.5, Vector3(mw * 0.3, mw * 0.8, proj),
				Basis.looking_at(d), 0.0)
	lm.frustum(key, c, r + proj, r + proj, mw, seg)
	var nm := maxi(seg / 2, 4)
	for i in nm:
		var a := TAU * float(i) / float(nm)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box(key, c + d * (r + proj - mw * 0.25) + Vector3.UP * mw * 1.45, Vector3(mw, mw * 0.9, mw * 0.5),
			Basis.looking_at(d), 0.0)

## Dark arrow slit (with a cross-oillet) on a wall facing `n`.
static func slit(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, h: float) -> void:
	var nn := n.normalized()
	var r := Vector3.UP.cross(nn).normalized()
	var basis := Basis(r, Vector3.UP, nn)
	lm.box(key, c + nn * 0.03, Vector3(h * 0.12, h, 0.06), basis, 0.0)
	lm.box(key, c + nn * 0.03 + Vector3.UP * h * 0.15, Vector3(h * 0.4, h * 0.1, 0.06), basis, 0.0)

## Latin cross, `h` tall, its foot at `base`.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	var t := maxf(h * 0.08, 0.06)
	lm.box(key, base + Vector3.UP * h * 0.5, Vector3(t, h, t))
	lm.box(key, base + Vector3.UP * h * 0.68, Vector3(h * 0.55, t, t))

## Dome profile (radius, y): a raised half-circle of base radius r
## rising h, closed at the apex.
static func dome(r: float, h: float, steps: int = 8) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in steps + 1:
		var t := PI * 0.5 * float(k) / float(steps)
		pr.append(Vector2(cos(t) * r, sin(t) * h))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr

## Ogee onion profile (radius, y) for Russian onion domes, height h.
static func onion(r: float, h: float) -> PackedVector2Array:
	var pts := [[0.7, 0.0], [0.95, 0.1], [1.05, 0.22], [1.04, 0.33], [0.9, 0.45], [0.62, 0.57],
		[0.34, 0.68], [0.16, 0.78], [0.07, 0.86], [0.0, 0.9]]
	var p := PackedVector2Array()
	for q in pts:
		p.append(Vector2(r * float(q[0]), h * float(q[1])))
	return p
