class_name LandmarkAfhDetail
extends RefCounted

## Masonry details for the historic Africa batch, in true metres on
## LandmarkMesh: framed niches and openings (round, horseshoe, pointed,
## polylobed or square heads) whose projecting frame forms the reveal,
## alfiz frames, sebka lattice panels, stepped merlons, drum-built
## columns and small horseshoe arcades.

## Outline of an opening w wide and h tall as (u, v) points from the
## bottom-left corner round the head to the bottom-right corner, u across
## the face from the centre line, v up from the sill. Heads: "rect",
## "round", "horseshoe" (the arc continues below the springing),
## "pointed" and "lobed" (a round head scalloped into `lobes` foils).
static func outline(shape: String, w: float, h: float, lobes: int = 5) -> PackedVector2Array:
	var hw := w * 0.5
	var p := PackedVector2Array()
	match shape:
		"rect":
			p.append_array([Vector2(-hw, 0), Vector2(-hw, h), Vector2(hw, h), Vector2(hw, 0)])
		"pointed":
			# Two arcs of radius 0.8 w meeting in a point on the centre line.
			var rr := w * 0.8
			var cx := rr - hw
			var phi := acos(cx / rr)
			var spring := maxf(h - rr * sin(phi), 0.0)
			p.append(Vector2(-hw, 0))
			for k in 6:
				var f := phi * float(k) / 5.0
				p.append(Vector2(cx - rr * cos(f), spring + rr * sin(f)))
			for k in range(4, -1, -1):
				var f := phi * float(k) / 5.0
				p.append(Vector2(-(cx - rr * cos(f)), spring + rr * sin(f)))
			p.append(Vector2(hw, 0))
		"horseshoe":
			# Circle of radius 0.56 w whose chord at the springing is w wide.
			var r := w * 0.56
			var drop := sqrt(r * r - hw * hw)
			var cy := h - r
			var a0 := -asin(drop / r)
			p.append(Vector2(-hw, 0))
			for k in 11:
				var a := PI - a0 - (PI - 2.0 * a0) * float(k) / 10.0
				p.append(Vector2(cos(a) * r, cy + sin(a) * r))
			p.append(Vector2(hw, 0))
		"lobed":
			var r := hw
			var cy := h - r
			p.append(Vector2(-hw, 0))
			var steps := lobes * 4
			for k in steps + 1:
				var t := float(k) / float(steps)
				var a := PI * (1.0 - t)
				var scal := 1.0 - 0.16 * absf(sin(PI * t * float(lobes)))
				p.append(Vector2(cos(a) * r * scal, cy + sin(a) * r * scal))
			p.append(Vector2(hw, 0))
		_:
			var r := hw
			var cy := h - r
			p.append(Vector2(-hw, 0))
			for k in 9:
				var a := PI * (1.0 - float(k) / 8.0)
				p.append(Vector2(cos(a) * r, cy + sin(a) * r))
			p.append(Vector2(hw, 0))
	return p

## Framed opening on a vertical face: `c` is the sill centre on the face
## plane, `out` the face normal. A frame `band` wide projects `proj` from
## the face round the head and jambs (its inner side reads as the reveal)
## and the opening itself is a dark panel on the face. `sill` adds the
## bottom bar.
static func niche(lm: LandmarkMesh, frame: String, dark: String, c: Vector3, out: Vector3,
		w: float, h: float, shape: String = "round", band: float = 0.3, proj: float = 0.25,
		sill: bool = true, lobes: int = 5) -> void:
	var o := out.normalized()
	var right := Vector3.UP.cross(o).normalized()
	var pts := outline(shape, w, h, lobes)
	var ctr := Vector2(0, h * 0.5)
	var P := func(q: Vector2, d: float) -> Vector3:
		return c + right * q.x + Vector3.UP * q.y + o * d
	# Dark opening: a fan from the centre.
	for i in pts.size() - 1:
		lm.tri(dark, P.call(ctr, 0.03), P.call(pts[i], 0.03), P.call(pts[i + 1], 0.03), o, o, o,
			ctr, pts[i], pts[i + 1])
	lm.tri(dark, P.call(ctr, 0.03), P.call(pts[pts.size() - 1], 0.03), P.call(pts[0], 0.03), o, o, o,
		ctr, pts[pts.size() - 1], pts[0])
	# Frame members, offset outward from the opening edge by half the band.
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := (b - a).normalized()
		var n2 := Vector2(-d.y, d.x)
		if n2.dot((a + b) * 0.5 - ctr) < 0.0:
			n2 = -n2
		var ext := d * band * 0.5
		lm.beam(frame, P.call(a + n2 * band * 0.5 - ext, proj * 0.5), P.call(b + n2 * band * 0.5 + ext, proj * 0.5),
			proj, band, o)
	if sill:
		lm.beam(frame, P.call(Vector2(-w * 0.5 - band, -band * 0.5), proj * 0.6),
			P.call(Vector2(w * 0.5 + band, -band * 0.5), proj * 0.6), proj * 1.2, band, o)

## Rectangular alfiz frame (w x h, band wide) round an arch on a face:
## `c` the bottom centre on the face plane.
static func alfiz(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, w: float, h: float,
		band: float = 0.25, proj: float = 0.12) -> void:
	var o := out.normalized()
	var right := Vector3.UP.cross(o).normalized()
	var f := c + o * proj * 0.5
	var hw := w * 0.5
	lm.beam(key, f - right * hw + Vector3(0, h, 0), f + right * hw + Vector3(0, h, 0), proj, band, o)
	for s in [-1.0, 1.0]:
		lm.beam(key, f + right * hw * float(s), f + right * hw * float(s) + Vector3(0, h + band * 0.5, 0),
			proj, band, o)

## Sebka panel: a lattice of interlaced lozenges (`cols` across, `rows`
## up) of bars `bar` wide projecting `proj` from a face; `c` the bottom
## centre on the face plane. Dark back fills each lozenge when given.
static func sebka(lm: LandmarkMesh, key: String, dark: String, c: Vector3, out: Vector3, w: float,
		h: float, cols: int, rows: int, bar: float = 0.25, proj: float = 0.15) -> void:
	var o := out.normalized()
	var right := Vector3.UP.cross(o).normalized()
	var cw := w / float(cols)
	var ch := h / float(rows)
	var P := func(u: float, v: float, d: float) -> Vector3:
		return c + right * (u - w * 0.5) + Vector3.UP * v + o * d
	for j in rows:
		for i in cols:
			var u0 := cw * float(i)
			var v0 := ch * float(j)
			var top: Vector3 = P.call(u0 + cw * 0.5, v0 + ch, proj * 0.5)
			var bot: Vector3 = P.call(u0 + cw * 0.5, v0, proj * 0.5)
			var lft: Vector3 = P.call(u0, v0 + ch * 0.55, proj * 0.5)
			var rgt: Vector3 = P.call(u0 + cw, v0 + ch * 0.55, proj * 0.5)
			lm.beam(key, bot, lft, proj, bar, o)
			lm.beam(key, lft, top, proj, bar, o)
			lm.beam(key, top, rgt, proj, bar, o)
			lm.beam(key, rgt, bot, proj, bar, o)
			if dark != "":
				var m: Vector3 = P.call(u0 + cw * 0.5, v0 + ch * 0.55, 0.03)
				var b2 := bot.lerp(m, 0.7) - o * (proj * 0.5 - 0.03)
				var l2 := lft.lerp(m, 0.7) - o * (proj * 0.5 - 0.03)
				var t2 := top.lerp(m, 0.7) - o * (proj * 0.5 - 0.03)
				var r2 := rgt.lerp(m, 0.7) - o * (proj * 0.5 - 0.03)
				lm.quad(dark, b2, r2, t2, l2, o)
	# Outer frame.
	lm.beam(key, P.call(0, 0, proj * 0.5), P.call(w, 0, proj * 0.5), proj, bar, o)
	lm.beam(key, P.call(0, h, proj * 0.5), P.call(w, h, proj * 0.5), proj, bar, o)
	lm.beam(key, P.call(0, 0, proj * 0.5), P.call(0, h, proj * 0.5), proj, bar, o)
	lm.beam(key, P.call(w, 0, proj * 0.5), P.call(w, h, proj * 0.5), proj, bar, o)

## Stepped (Almohad) merlon at `base` on the wall top: three tiers
## narrowing upward with a small pyramid cap, `w` wide, `h` tall, `t`
## thick, its face turned along `along`.
static func stepped_merlon(lm: LandmarkMesh, key: String, base: Vector3, along: Vector3, w: float,
		h: float, t: float) -> void:
	var basis := Basis(Vector3.UP, atan2(along.x, along.z) - PI * 0.5)
	var y := 0.0
	var fr: Array[float] = [1.0, 0.68, 0.38]
	var hs: Array[float] = [0.45, 0.25, 0.18]
	for k in 3:
		lm.box(key, base + Vector3(0, y + h * hs[k] * 0.5, 0), Vector3(w * fr[k], h * hs[k], t), basis, 0.0)
		y += h * hs[k]
	lm.spire(key, base + Vector3(0, y, 0), minf(w * 0.19, t * 0.5), h * 0.12)

## Row of stepped merlons along a..b (wall-top points), one every `pitch`.
static func merlon_row(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float, h: float,
		t: float, pitch: float) -> void:
	var n := maxi(int(a.distance_to(b) / pitch), 1)
	var d := (b - a).normalized()
	for i in n:
		stepped_merlon(lm, key, a.lerp(b, (float(i) + 0.5) / float(n)), d, w, h, t)

## Round column of stone drums: shaft radius r, total height h in `drums`
## courses with a slight groove at each joint, `seg` sides, a square
## base block and impost block when `ends`.
static func drum_column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, drums: int,
		seg: int = 10, ends: bool = true) -> void:
	var y0 := 0.0
	var y1 := h
	if ends:
		lm.box(key, base + Vector3(0, r * 0.35, 0), Vector3(r * 2.5, r * 0.7, r * 2.5), Basis(), 0.0)
		lm.box(key, base + Vector3(0, h - r * 0.35, 0), Vector3(r * 2.7, r * 0.7, r * 2.7), Basis(), 0.0)
		y0 = r * 0.7
		y1 = h - r * 0.7
	var prof := PackedVector2Array([Vector2(r, y0)])
	for k in range(1, drums):
		var y := lerpf(y0, y1, float(k) / float(drums))
		var rr := lerpf(r, r * 0.92, float(k) / float(drums))
		prof.append(Vector2(rr * 0.93, y))
		prof.append(Vector2(rr, y + 0.04))
	prof.append(Vector2(r * 0.92, y1))
	lm.lathe(key, base, prof, seg, 1.0, 1.0, 0.0, true, not ends)

## Small horseshoe arcade on a face: `n` arches between `a` and `b`
## (ground points on the face plane, facing `out`) on round columns,
## spandrel wall up to `h` with the arches springing at `spring`.
static func arcade(lm: LandmarkMesh, wall: String, col: String, a: Vector3, b: Vector3,
		out: Vector3, n: int, spring: float, h: float, depth: float, col_r: float) -> void:
	var o := out.normalized()
	var along := (b - a) / float(n)
	var pitch := along.length()
	var d := along.normalized()
	var basis := Basis(d, Vector3.UP, o)
	for i in n + 1:
		var p := a + along * float(i) - o * depth * 0.5
		drum_column(lm, col, p, col_r, spring, 1, 8)
	for i in n:
		var p0 := a + along * float(i)
		var mid := p0 + along * 0.5
		# Spandrel band over the arch: a horseshoe-cut lintel.
		var w := pitch - col_r * 2.0
		var a0 := -asin(0.35)
		var r := w * 0.5 / cos(a0)
		var cy := spring + r * 0.35
		var pts := PackedVector3Array()
		var steps := 8
		for k in steps + 1:
			var t := PI - a0 - (PI - 2.0 * a0) * float(k) / float(steps)
			pts.append(mid + d * cos(t) * r + Vector3(0, cy + sin(t) * r, 0))
		for face in [0.0, -depth]:
			var fo: Vector3 = o * float(face)
			var nn := o if face == 0.0 else -o
			for k in steps:
				var top0 := Vector3(pts[k].x, h, pts[k].z)
				var top1 := Vector3(pts[k + 1].x, h, pts[k + 1].z)
				lm.quad(wall, pts[k] + fo, pts[k + 1] + fo, top1 + fo, top0 + fo, nn)
			var left := p0 + Vector3(0, spring, 0)
			var right := p0 + along + Vector3(0, spring, 0)
			lm.quad(wall, left + fo, pts[0] + fo, Vector3(pts[0].x, h, pts[0].z) + fo,
				Vector3(left.x, h, left.z) + fo, nn)
			lm.quad(wall, pts[steps] + fo, right + fo, Vector3(right.x, h, right.z) + fo,
				Vector3(pts[steps].x, h, pts[steps].z) + fo, nn)
		# Intrados (the soffit of the arch).
		for k in steps:
			var inward := (mid + Vector3(0, cy, 0) - (pts[k] + pts[k + 1]) * 0.5).normalized()
			lm.quad(wall, pts[k], pts[k + 1], pts[k + 1] - o * depth, pts[k] - o * depth, inward)
	# Top of the spandrel wall.
	lm.box(wall, (a + b) * 0.5 + Vector3(0, h + 0.15, 0) - o * depth * 0.5,
		Vector3(a.distance_to(b) + col_r * 2.0, 0.3, depth + 0.3), basis, 0.0)
