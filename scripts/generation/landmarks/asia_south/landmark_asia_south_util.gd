class_name LandmarkAsiaSouthUtil
extends RefCounted

## Shared parts of the south and south-east Asian landmark batch, in true
## metres on LandmarkMesh: domes, onion domes, finials, kiosks (chhatri),
## arched wall blocks and fluted tapering shafts. Every part takes the
## material KEYS to draw with (registered by the caller with lm.use).

## Hemispherical (or flattened, h < r) dome on `base`, `seg` sides.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 24, steps: int = 8) -> void:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * cos(a), h * sin(a)))
	lm.lathe(key, base, p, seg)

## Mughal onion (bulbous) dome: neck, widest belly, tapering to the tip.
static func onion(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 24) -> void:
	var t := [[0.74, 0.0], [0.97, 0.1], [1.0, 0.26], [0.9, 0.43], [0.62, 0.6],
		[0.34, 0.76], [0.13, 0.9], [0.0, 1.0]]
	var p := PackedVector2Array()
	for e in t:
		p.append(Vector2(r * float(e[0]), h * float(e[1])))
	lm.lathe(key, base, p, seg)

## Slim ringed finial (kalash / mast): bulbs up a thin stem, height h.
static func finial(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float = 0.4) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.6, 0), Vector2(r * 1.2, h * 0.12),
		Vector2(r * 0.5, h * 0.2), Vector2(r * 1.5, h * 0.38), Vector2(r * 0.4, h * 0.5),
		Vector2(r * 0.9, h * 0.66), Vector2(r * 0.25, h * 0.8), Vector2(r * 0.12, h)]), 10)

## Open dome-roofed kiosk: four pillars, a slab and an onion dome.
## Height = pillar_h + 0.5 + dome_h.
static func chhatri(lm: LandmarkMesh, wall: String, roof: String, base: Vector3, w: float,
		pillar_h: float, dome_h: float) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(wall, base + Vector3(sx * w * 0.4, pillar_h * 0.5, sz * w * 0.4),
				Vector3(w * 0.14, pillar_h, w * 0.14))
	lm.box(wall, base + Vector3(0, pillar_h + 0.25, 0), Vector3(w, 0.5, w))
	onion(lm, roof, base + Vector3(0, pillar_h + 0.5, 0), w * 0.46, dome_h, 14)

## Wall block facing local +Z (basis turns it), floor centre at `base`:
## width x height x depth with a round-headed passage open_w wide and
## open_h tall through it (front and back faces, jambs, soffit). A
## `rise` > open_w / 2 gives a pointed head that rise above the springing.
static func arch_wall(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, width: float,
		height: float, depth: float, open_w: float, open_h: float, steps: int = 10,
		rise: float = -1.0) -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var r := open_w * 0.5
	var spring := open_h - (rise if rise > 0.0 else r)
	var curve: Array[Vector2] = []
	if rise > 0.0:
		for q in pointed_curve(r, rise, steps):
			curve.append(Vector2(q.x, spring + q.y))
		steps = curve.size() - 1
	else:
		for i in steps + 1:
			var a := PI * (1.0 - float(i) / steps)
			curve.append(Vector2(r * cos(a), spring + r * sin(a)))
	for side in [1.0, -1.0]:
		var z: float = hd * side
		var n: Vector3 = basis * Vector3(0, 0, side)
		_q(lm, key, base, basis, Vector3(-hw, 0, z), Vector3(-r, 0, z), Vector3(-r, height, z),
			Vector3(-hw, height, z), n)
		_q(lm, key, base, basis, Vector3(r, 0, z), Vector3(hw, 0, z), Vector3(hw, height, z),
			Vector3(r, height, z), n)
		for i in steps:
			var c0 := curve[i]
			var c1 := curve[i + 1]
			_q(lm, key, base, basis, Vector3(c0.x, c0.y, z), Vector3(c1.x, c1.y, z),
				Vector3(c1.x, height, z), Vector3(c0.x, height, z), n)
	# Jambs and the arched soffit between front and back faces.
	for sx in [-1.0, 1.0]:
		var n: Vector3 = basis * Vector3(-sx, 0, 0)
		_q(lm, key, base, basis, Vector3(sx * r, 0, -hd), Vector3(sx * r, 0, hd),
			Vector3(sx * r, spring, hd), Vector3(sx * r, spring, -hd), n)
		_q(lm, key, base, basis, Vector3(sx * hw, 0, -hd), Vector3(sx * hw, 0, hd),
			Vector3(sx * hw, height, hd), Vector3(sx * hw, height, -hd), -n)
	for i in steps:
		var c0 := curve[i]
		var c1 := curve[i + 1]
		var mid := (c0 + c1) * 0.5
		var n := basis * Vector3(-mid.x, spring - mid.y, 0).normalized()
		_q(lm, key, base, basis, Vector3(c0.x, c0.y, -hd), Vector3(c0.x, c0.y, hd),
			Vector3(c1.x, c1.y, hd), Vector3(c1.x, c1.y, -hd), n)
	_q(lm, key, base, basis, Vector3(-hw, height, -hd), Vector3(-hw, height, hd),
		Vector3(hw, height, hd), Vector3(hw, height, -hd), basis * Vector3.UP)

## One local-frame quad placed at `base` turned by `basis`.
static func _q(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3, n: Vector3) -> void:
	lm.quad(key, base + basis * a, base + basis * b, base + basis * c, base + basis * d, n)

## Tapering shaft of `flutes` rounded ribs from radius r0 at base to r1
## at the top, `seg` facets per flute; depth is the rib relief (m).
static func fluted_shaft(lm: LandmarkMesh, key: String, base: Vector3, r0: float, r1: float,
		h: float, flutes: int, relief: float, rings: int = 2, seg: int = 3) -> void:
	var n := flutes * seg
	for j in rings:
		var t0 := float(j) / rings
		var t1 := float(j + 1) / rings
		var ra := lerpf(r0, r1, t0)
		var rb := lerpf(r0, r1, t1)
		for i in n:
			var a0 := TAU * float(i) / n
			var a1 := TAU * float(i + 1) / n
			var q0 := ra + relief * 0.5 * (1.0 + cos(a0 * flutes))
			var q1 := ra + relief * 0.5 * (1.0 + cos(a1 * flutes))
			var q2 := rb + relief * 0.5 * (1.0 + cos(a1 * flutes))
			var q3 := rb + relief * 0.5 * (1.0 + cos(a0 * flutes))
			var am := (a0 + a1) * 0.5
			var nn := Vector3(cos(am), (r0 - r1) / h, sin(am)).normalized()
			lm.quad(key, base + Vector3(cos(a0) * q0, h * t0, sin(a0) * q0),
				base + Vector3(cos(a1) * q1, h * t0, sin(a1) * q1),
				base + Vector3(cos(a1) * q2, h * t1, sin(a1) * q2),
				base + Vector3(cos(a0) * q3, h * t1, sin(a0) * q3), nn)

## Row of small dark recesses (windows, Buddha niches) on the four sides
## of a square block of half-width hw, `count` per side from y0..y1.
static func niche_rows(lm: LandmarkMesh, key: String, c: Vector3, hw: float, y: float,
		size: Vector3, count: int) -> void:
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in count:
			var x := -hw * 0.82 + hw * 1.64 * (float(k) + 0.5) / count
			lm.box(key, c + b * Vector3(x, y, hw + size.z * 0.4), size, b)

## Two-centred pointed arch from (-r, 0) over the apex (0, rise) to
## (r, 0); rise == r gives a round arch. `steps` segments in all.
static func pointed_curve(r: float, rise: float, steps: int = 10) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var half := maxi(steps / 2, 2)
	if rise <= r * 1.01:
		for i in half * 2 + 1:
			var a := PI * (1.0 - float(i) / float(half * 2))
			out.append(Vector2(r * cos(a), rise * sin(a)))
		return out
	# Arc radius R with its centre on the springing line at x = R - r.
	var big := (rise * rise + r * r) / (2.0 * r)
	var cx := big - r
	var a_top := acos(clampf(-cx / big, -1.0, 1.0))
	for i in half + 1:
		var a := lerpf(PI, a_top, float(i) / float(half))
		out.append(Vector2(cx + big * cos(a), big * sin(a)))
	for i in range(half - 1, -1, -1):
		var p: Vector2 = out[i]
		out.append(Vector2(-p.x, p.y))
	return out

## A wall panel pw x ph (local +Z out of the face, bottom centre at
## `base`, `depth` thick from z = 0 back on the mass to z = depth) with a
## real opening ow wide cut through it: from `sill` up to the springing
## line `spring`, then a pointed (or round, rise = ow / 2) head. Jamb,
## sill and soffit reveals run back to the mass, where `back` closes the
## niche (a dark recess, a door or a lattice screen).
static func niche(lm: LandmarkMesh, key: String, back: String, base: Vector3, basis: Basis,
		pw: float, ph: float, ow: float, sill: float, spring: float, rise: float, depth: float,
		steps: int = 8) -> void:
	var hw := pw * 0.5
	var r := ow * 0.5
	var d := depth
	var curve := pointed_curve(r, rise, steps)
	var n := basis * Vector3(0, 0, 1)
	var top := spring + rise
	# Front face around the opening.
	_q(lm, key, base, basis, Vector3(-hw, 0, d), Vector3(-r, 0, d), Vector3(-r, ph, d), Vector3(-hw, ph, d), n)
	_q(lm, key, base, basis, Vector3(r, 0, d), Vector3(hw, 0, d), Vector3(hw, ph, d), Vector3(r, ph, d), n)
	if sill > 0.0:
		_q(lm, key, base, basis, Vector3(-r, 0, d), Vector3(r, 0, d), Vector3(r, sill, d), Vector3(-r, sill, d), n)
	if top < ph:
		for i in curve.size() - 1:
			var c0: Vector2 = curve[i]
			var c1: Vector2 = curve[i + 1]
			_q(lm, key, base, basis, Vector3(c0.x, spring + c0.y, d), Vector3(c1.x, spring + c1.y, d),
				Vector3(c1.x, ph, d), Vector3(c0.x, ph, d), n)
	# Reveals: jambs, sill, soffit.
	for sx in [-1.0, 1.0]:
		_q(lm, key, base, basis, Vector3(sx * r, sill, 0), Vector3(sx * r, sill, d),
			Vector3(sx * r, spring, d), Vector3(sx * r, spring, 0), basis * Vector3(-sx, 0, 0))
	_q(lm, key, base, basis, Vector3(-r, sill, 0), Vector3(r, sill, 0), Vector3(r, sill, d),
		Vector3(-r, sill, d), basis * Vector3.UP)
	for i in curve.size() - 1:
		var c0: Vector2 = curve[i]
		var c1: Vector2 = curve[i + 1]
		var mid := (c0 + c1) * 0.5
		var sn := basis * Vector3(-mid.x, -mid.y, 0).normalized()
		_q(lm, key, base, basis, Vector3(c0.x, spring + c0.y, 0), Vector3(c1.x, spring + c1.y, 0),
			Vector3(c1.x, spring + c1.y, d), Vector3(c0.x, spring + c0.y, d), sn)
	# Back of the niche, just proud of the mass face.
	var bz := 0.02
	_q(lm, back, base, basis, Vector3(-r, sill, bz), Vector3(r, sill, bz), Vector3(r, spring, bz),
		Vector3(-r, spring, bz), n)
	for i in curve.size() - 1:
		var c0: Vector2 = curve[i]
		var c1: Vector2 = curve[i + 1]
		var a := base + basis * Vector3(0, spring, bz)
		var b := base + basis * Vector3(c0.x, spring + c0.y, bz)
		var c := base + basis * Vector3(c1.x, spring + c1.y, bz)
		lm.tri(back, a, b, c, n, n, n, Vector2.ZERO, Vector2(c0.x, c0.y), Vector2(c1.x, c1.y))
	# Returns at the panel edges and its top.
	for sx in [-1.0, 1.0]:
		_q(lm, key, base, basis, Vector3(sx * hw, 0, 0), Vector3(sx * hw, 0, d), Vector3(sx * hw, ph, d),
			Vector3(sx * hw, ph, 0), basis * Vector3(sx, 0, 0))
	_q(lm, key, base, basis, Vector3(-hw, ph, 0), Vector3(hw, ph, 0), Vector3(hw, ph, d),
		Vector3(-hw, ph, d), basis * Vector3.UP)

## A row of `count` niche panels side by side along local X, filling
## width w (a blind or open arcade), centred on `base`.
static func arcade(lm: LandmarkMesh, key: String, back: String, base: Vector3, basis: Basis, w: float,
		h: float, count: int, open_frac: float, sill: float, spring: float, rise_frac: float,
		depth: float, steps: int = 8) -> void:
	var pitch := w / float(count)
	var ow := pitch * open_frac
	for k in count:
		var x := -w * 0.5 + pitch * (float(k) + 0.5)
		niche(lm, key, back, base + basis * Vector3(x, 0, 0), basis, pitch, h, ow, sill, spring,
			ow * 0.5 * rise_frac, depth, steps)

## Rectangular moulded frame of beams (the Mughal alfiz round a portal)
## w x h, bottom centre at `base` on a face, `t` thick, standing `out`.
static func frame(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, w: float, h: float,
		t: float, out: float) -> void:
	var z := Vector3(0, 0, out * 0.5)
	var hw := w * 0.5
	lm.box(key, base + basis * (Vector3(-hw, h * 0.5, 0) + z), Vector3(t, h, out), basis)
	lm.box(key, base + basis * (Vector3(hw, h * 0.5, 0) + z), Vector3(t, h, out), basis)
	lm.box(key, base + basis * (Vector3(0, h, 0) + z), Vector3(w + t, t, out), basis)
	lm.box(key, base + basis * (Vector3(0, 0, 0) + z), Vector3(w + t, t, out), basis)

## Octagonal kiosk (chhatri) of eight slender columns with bracket
## capitals, a sloping chhajja eave, a drum and an onion dome with a
## finial; base at `base`, overall radius r. Height = col_h + dome_h +
## r * 0.9 (eave, drum and finial).
static func chhatri8(lm: LandmarkMesh, wall: String, roof: String, tip: String, base: Vector3,
		r: float, col_h: float, dome_h: float) -> void:
	lm.lathe(wall, base, PackedVector2Array([Vector2(r * 1.08, 0), Vector2(r * 1.08, r * 0.12),
		Vector2(r * 0.98, r * 0.18)]), 8, 1.0, 1.0, PI / 8.0, false)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var p := base + Vector3(cos(a), 0, sin(a)) * r * 0.82 + Vector3(0, r * 0.18, 0)
		lm.lathe(wall, p, PackedVector2Array([Vector2(r * 0.1, 0), Vector2(r * 0.1, col_h * 0.12),
			Vector2(r * 0.065, col_h * 0.16), Vector2(r * 0.06, col_h * 0.84), Vector2(r * 0.1, col_h * 0.92),
			Vector2(r * 0.13, col_h)]), 8)
	var e := base + Vector3(0, r * 0.18 + col_h, 0)
	# Lintel, the chhajja sloping down and out, and the dome's drum.
	lm.frustum(wall, e, r * 0.95, r * 0.95, r * 0.14, 8, PI / 8.0)
	lm.lathe(wall, e + Vector3(0, r * 0.14, 0), PackedVector2Array([Vector2(r * 1.25, -r * 0.12),
		Vector2(r * 1.25, -r * 0.06), Vector2(r * 0.9, r * 0.14), Vector2(r * 0.72, r * 0.16)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	var db := e + Vector3(0, r * 0.3, 0)
	lm.frustum(wall, db, r * 0.72, r * 0.72, r * 0.16, 16)
	lm.lathe(roof, db + Vector3(0, r * 0.16, 0), LandmarkKits.onion_profile(r * 0.7, dome_h), 16)
	finial(lm, tip, db + Vector3(0, r * 0.16 + dome_h * 0.94, 0), r * 0.5, r * 0.06)

## Merlons along a-b on the level of a and b (a crenellated or kangura
## parapet): `n` small blocks w wide, h tall, with pointed caps.
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, w: float,
		h: float) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box(key, p + Vector3(0, h * 0.35, 0), Vector3(w, h * 0.7, w * 0.5), basis, 0.0)
		lm.lathe(key, p + Vector3(0, h * 0.7, 0), PackedVector2Array([Vector2(w * 0.4, 0),
			Vector2(0.0, h * 0.3)]), 4, 1.0, 1.0, PI / 4.0, false)

## Redented square plan (the indented corners of Khmer, Thai and
## Javanese towers): half-width hw, each corner stepped `teeth` times
## by `step`. Counter-clockwise from the +X side.
static func redent(hw: float, step: float, teeth: int = 2) -> PackedVector2Array:
	var p := PackedVector2Array()
	for side in 4:
		var rot := PI * 0.5 * float(side)
		var pts: Array[Vector2] = []
		# The run of one quadrant from the +X axis to the +Z axis.
		var x := hw
		var z := 0.0
		pts.append(Vector2(x, z))
		var zc := hw - step * float(teeth)
		pts.append(Vector2(x, zc))
		for t in teeth:
			x -= step
			pts.append(Vector2(x, zc + step * float(t)))
			pts.append(Vector2(x, zc + step * float(t + 1)))
		for q in pts:
			p.append(q.rotated(rot))
	# Drop the duplicate axis points.
	var out := PackedVector2Array()
	for q in p:
		if out.is_empty() or out[out.size() - 1].distance_to(q) > 0.001:
			out.append(q)
	return out

## Prism between two scaled copies of `poly` (around c): s0 at y0, s1 at
## y1, outward normals, top cap when `cap`.
static func plan_frustum(lm: LandmarkMesh, key: String, c: Vector3, poly: PackedVector2Array, s0: float,
		s1: float, y0: float, y1: float, cap: bool = true) -> void:
	var m := poly.size()
	for i in m:
		var p := poly[i]
		var q := poly[(i + 1) % m]
		var a := c + Vector3(p.x * s0, y0, p.y * s0)
		var b := c + Vector3(q.x * s0, y0, q.y * s0)
		var t1 := c + Vector3(q.x * s1, y1, q.y * s1)
		var t0 := c + Vector3(p.x * s1, y1, p.y * s1)
		var nn := (b - a).cross(t0 - a).normalized()
		var mid := (a + b) * 0.5 - c
		if nn.dot(Vector3(mid.x, 0, mid.z)) < 0.0:
			nn = -nn
		lm.quad(key, a, b, t1, t0, nn)
	if cap:
		var sc := PackedVector2Array()
		for q in poly:
			sc.append(q * s1)
		var idx := Geometry2D.triangulate_polygon(sc)
		for t in range(0, idx.size(), 3):
			var a2 := sc[idx[t]]
			var b2 := sc[idx[t + 1]]
			var c2 := sc[idx[t + 2]]
			lm.tri(key, c + Vector3(a2.x, y1, a2.y), c + Vector3(b2.x, y1, b2.y), c + Vector3(c2.x, y1, c2.y),
				Vector3.UP, Vector3.UP, Vector3.UP, a2, b2, c2)

## Diagonal lattice (jali) screen w x h on a face: two families of thin
## crossing bars at `pitch` inside a frame, centred at `c` facing `basis` Z.
static func jali(lm: LandmarkMesh, key: String, c: Vector3, basis: Basis, w: float, h: float,
		pitch: float, bar: float) -> void:
	var hw := w * 0.5
	var hh := h * 0.5
	var n := int((w + h) / pitch)
	for s in [-1.0, 1.0]:
		for i in n:
			# Line x - s*y = k clipped to the rectangle.
			var k := -hw - hh + pitch * (float(i) + 0.5)
			var pts: Array[Vector2] = []
			for y in [-hh, hh]:
				var x: float = k + s * y
				if x >= -hw and x <= hw:
					pts.append(Vector2(x, y))
			for x in [-hw, hw]:
				var y: float = (x - k) * s
				if y > -hh and y < hh:
					pts.append(Vector2(x, y))
			if pts.size() >= 2:
				lm.beam(key, c + basis * Vector3(pts[0].x, pts[0].y, 0), c + basis * Vector3(pts[1].x, pts[1].y, 0),
					bar, bar, basis * Vector3.RIGHT)
	frame(lm, key, c - basis * Vector3(0, hh, 0), basis, w, h, bar * 1.6, bar * 1.4)

## A wall ring on `poly` (around c) from y0 to y1: the outer face at
## scale s_out, the inner face (facing in) at s_in, the top between.
static func plan_ring(lm: LandmarkMesh, key: String, c: Vector3, poly: PackedVector2Array, s_out: float,
		s_in: float, y0: float, y1: float) -> void:
	plan_frustum(lm, key, c, poly, s_out, s_out, y0, y1, false)
	var m := poly.size()
	for i in m:
		var p := poly[i]
		var q := poly[(i + 1) % m]
		var a := c + Vector3(p.x * s_in, y0, p.y * s_in)
		var b := c + Vector3(q.x * s_in, y0, q.y * s_in)
		var mid := (a + b) * 0.5 - c
		lm.quad(key, a, b, b + Vector3(0, y1 - y0, 0), a + Vector3(0, y1 - y0, 0), -Vector3(mid.x, 0, mid.z).normalized())
		lm.quad(key, c + Vector3(p.x * s_in, y1, p.y * s_in), c + Vector3(q.x * s_in, y1, q.y * s_in),
			c + Vector3(q.x * s_out, y1, q.y * s_out), c + Vector3(p.x * s_out, y1, p.y * s_out), Vector3.UP)

## The convex (outward-pointing) corners of a counter-clockwise plan.
static func convex_corners(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var m := poly.size()
	for i in m:
		var a := poly[(i + m - 1) % m]
		var b := poly[i]
		var c := poly[(i + 1) % m]
		if (b - a).cross(c - b) > 0.001:
			out.append(b)
	return out
