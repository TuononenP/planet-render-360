class_name LandmarkWhKit
extends RefCounted

## Gothic and castle helpers shared by the western historic batch, in
## true metres on LandmarkMesh: pointed lancet panels, rose windows,
## pinnacles, flying buttresses, crenellated walls and round towers
## under conical roofs. Plan frame: +X east, -Z north, y = 0 ground.

## Horizontal unit vector `r` along a wall whose outward normal is `n`.
static func along(n: Vector3) -> Vector3:
	return Vector3(n.z, 0, -n.x)

## Flat pointed-arch panel on a wall face: bottom centre `c`, outward
## normal `n` (horizontal), width w, straight part h, parabolic pointed
## head `head` high (defaults to 0.9 w).
static func lancet(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, w: float, h: float,
		head: float = -1.0, steps: int = 4) -> void:
	var hd := head if head >= 0.0 else w * 0.9
	var r := along(n)
	var up := Vector3.UP
	lm.quad(key, c - r * w * 0.5, c + r * w * 0.5, c + r * w * 0.5 + up * h, c - r * w * 0.5 + up * h, n)
	for i in steps:
		var s0 := float(i) / float(steps)
		var s1 := float(i + 1) / float(steps)
		var x0 := w * 0.5 * (1.0 - s0 * s0)
		var x1 := w * 0.5 * (1.0 - s1 * s1)
		var y0 := h + hd * s0
		var y1 := h + hd * s1
		var l0 := c - r * x0 + up * y0
		var r0 := c + r * x0 + up * y0
		var l1 := c - r * x1 + up * y1
		var r1 := c + r * x1 + up * y1
		lm.tri(key, l0, r0, r1, n, n, n, Vector2(-x0, -y0), Vector2(x0, -y0), Vector2(x1, -y1))
		if i < steps - 1:
			lm.tri(key, l0, r1, l1, n, n, n, Vector2(-x0, -y0), Vector2(x1, -y1), Vector2(-x1, -y1))

## Flat round-headed (semicircular) opening: bottom centre `c`, outward
## normal `n`, width w, straight part h, then the half-round head.
static func arch_round(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, w: float, h: float,
		steps: int = 6) -> void:
	var r := along(n)
	var rad := w * 0.5
	lm.quad(key, c - r * rad, c + r * rad, c + r * rad + Vector3.UP * h, c - r * rad + Vector3.UP * h, n)
	var top := c + Vector3.UP * h
	for i in steps:
		var a0 := PI * float(i) / float(steps)
		var a1 := PI * float(i + 1) / float(steps)
		var p0 := top + r * cos(a0) * rad + Vector3.UP * sin(a0) * rad
		var p1 := top + r * cos(a1) * rad + Vector3.UP * sin(a1) * rad
		lm.tri(key, top, p0, p1, n, n, n, Vector2.ZERO, Vector2(cos(a0), -sin(a0)) * rad,
			Vector2(cos(a1), -sin(a1)) * rad)

## Row of `count` lancets along a wall from p0 to p1 (ground points),
## all bottoms at height y0.
static func lancet_row(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, n: Vector3,
		count: int, w: float, h: float, y0: float, head: float = -1.0) -> void:
	for i in count:
		var p := p0.lerp(p1, (float(i) + 0.5) / float(count))
		lancet(lm, key, Vector3(p.x, y0, p.z) + n * 0.12, n, w, h, head)

## Rose window: the traceried rose of LandmarkWhGothic.
static func rose(lm: LandmarkMesh, glass: String, stone: String, c: Vector3, n: Vector3, rad: float,
		spokes: int = 12) -> void:
	LandmarkWhGothic.rose(lm, glass, stone, c, n, rad, spokes)

## Pinnacle: the crocketed pinnacle of LandmarkWhGothic, base-anchored.
static func pinnacle(lm: LandmarkMesh, key: String, base: Vector3, hw: float, shaft: float,
		cap: float) -> void:
	LandmarkWhGothic.pinnacle(lm, key, base, hw, shaft, cap)

## Flying buttress from the pier top `a` to the wall `b`: an arched
## soffit under a straight raking coping, joined by a pierced spandrel
## of short struts.
static func flyer(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float,
		bulge: float = 1.2) -> void:
	var prev := a
	var top := Vector3.UP * (bulge + w * 0.9)
	for i in 6:
		var t := float(i + 1) / 6.0
		var p := a.lerp(b, t) + Vector3.UP * bulge * sin(PI * t)
		lm.beam(key, prev, p, w, w * 0.8)
		if i < 5:
			lm.beam(key, p, a.lerp(b, t) + top, w * 0.5, w * 0.3)
		prev = p
	lm.beam(key, a + Vector3.UP * w * 0.9, b + top, w * 0.9, w * 0.6)

## Straight crenellated wall from a to b (ground points), `h` high.
static func crenel_wall(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float,
		thick: float, step: float = 2.6, merlon_h: float = 1.2) -> void:
	var d := b - a
	lm.box(key, (a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(thick, h, d.length()),
		Basis(Vector3.UP, atan2(d.x, d.z)))
	LandmarkWestKit.merlons(lm, key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), step,
		step * 0.5, merlon_h, thick * 0.9)

## Ring of merlons round a circle of radius `rad` at height base.y.
static func crenel_ring(lm: LandmarkMesh, key: String, base: Vector3, rad: float, count: int,
		w: float, h: float, thick: float) -> void:
	for i in count:
		var a := TAU * (float(i) + 0.5) / float(count)
		lm.box(key, base + Vector3(cos(a) * rad, h * 0.5, sin(a) * rad), Vector3(thick, h, w),
			Basis(Vector3.UP, -a))

## Round tower: battered foot, shaft (r0 at the foot, r1 at the top), a
## string course, the crown ring on a machicolation corbel table and a
## conical roof of `roof_h` over a small overhang with its finial.
static func round_tower(lm: LandmarkMesh, wall: String, roof: String, base: Vector3, r0: float,
		r1: float, h: float, roof_h: float, seg: int = 14) -> void:
	lm.frustum(wall, base, r0, r1, h, seg)
	# Battered foot, a string course, the crown ring on its corbels.
	lm.frustum(wall, base, r0 * 1.14, r0 * 1.0, minf(h * 0.18, 4.0), seg)
	lm.frustum(wall, base + Vector3(0, h * 0.55, 0), lerpf(r0, r1, 0.55) * 1.03, lerpf(r0, r1, 0.55) * 1.03,
		0.4, seg)
	lm.frustum(wall, base + Vector3(0, h - 0.8, 0), r1 * 1.12, r1 * 1.12, 1.0, seg)
	LandmarkWhGothic.machicolation_ring(lm, wall, base + Vector3(0, h - 2.0, 0), r1, 1.4, 1.6)
	lm.lathe(roof, base + Vector3(0, h + 0.2, 0), PackedVector2Array([Vector2(r1 * 1.22, 0),
		Vector2(r1 * 0.5, roof_h * 0.7), Vector2(0.0, roof_h)]), seg)
	# Finial (épi) on the cone.
	lm.frustum(roof, base + Vector3(0, h + 0.2 + roof_h * 0.92, 0), r1 * 0.05, r1 * 0.03, roof_h * 0.18, 6)
	lm.lathe(roof, base + Vector3(0, h + 0.2 + roof_h * 1.06, 0), LandmarkWestKit.ball(r1 * 0.05), 6)

## Gold ball finial.
static func ball(lm: LandmarkMesh, key: String, base: Vector3, r: float) -> void:
	lm.lathe(key, base, LandmarkWestKit.ball(r), 8)

## Octagonal openwork spire: a solid core cone with `ribs` corner ribs
## and `rings` stage bands, base apothem `hw`, height `h`, tip radius ~0.
static func open_spire(lm: LandmarkMesh, core: String, rib: String, base: Vector3, hw: float,
		h: float, ribs: int = 8, rings: int = 6) -> void:
	var k := 1.0 / cos(PI / float(ribs))
	lm.lathe(core, base, PackedVector2Array([Vector2(hw * k * 0.78, 0), Vector2(hw * k * 0.2, h * 0.9),
		Vector2(0.0, h)]), ribs, 1.0, 1.0, PI / float(ribs), false)
	for i in ribs:
		var a := TAU * (float(i) + 0.5) / float(ribs)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam(rib, base + d * hw * k * 0.96, base + Vector3(0, h, 0) + d * 0.1, 0.5, 0.5)
	for j in rings:
		var f := float(j) / float(rings)
		var rr := hw * k * (1.0 - f) * 0.96
		lm.frustum(rib, base + Vector3(0, h * f, 0), rr + 0.25, rr, 0.5, ribs, PI / float(ribs))

## Lean-to aisle roof between x0 and x1 on side `sz` (+1 south, -1
## north) of the axis z = oz: from the outer wall top (z_out, y_out) up
## to the clerestory wall (z_in, y_in).
static func leanto(lm: LandmarkMesh, key: String, x0: float, x1: float, sz: float, z_out: float,
		y_out: float, z_in: float, y_in: float, oz: float = 0.0) -> void:
	var n := Vector3(0, absf(z_out - z_in), sz * (y_in - y_out)).normalized()
	lm.quad(key, Vector3(x0, y_out, oz + sz * z_out), Vector3(x1, y_out, oz + sz * z_out),
		Vector3(x1, y_in, oz + sz * z_in), Vector3(x0, y_in, oz + sz * z_in), n)

## Aisled Gothic body along X between x0 and x1 on the axis z = oz:
## clerestory (half-width hc, wall to hc_h) under a low gabled roof of
## `rise`, aisles (half-width ha, wall to ha_h) under lean-to roofs, one
## window of each kind per bay, and a pinnacled buttress with a flyer
## between the bays.
static func aisled_body(lm: LandmarkMesh, stone: String, roof: String, glass: String, x0: float,
		x1: float, hc: float, hc_h: float, ha: float, ha_h: float, rise: float, bays: int,
		oz: float = 0.0) -> void:
	var cx := (x0 + x1) * 0.5
	var len := x1 - x0
	var bay := len / float(bays)
	LandmarkWestKit.blk(lm, stone, cx, 0, oz, len, hc_h, hc * 2.0)
	LandmarkWestKit.blk(lm, stone, cx, 0, oz, len, ha_h, ha * 2.0)
	lm.gable(roof, Vector3(cx, hc_h, oz), hc * 2.0, len, rise, Basis(Vector3.UP, PI * 0.5), 0.3, stone)
	var y_in := ha_h + (ha - hc) * 0.5
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		leanto(lm, roof, x0, x1, sz, ha + 0.3, ha_h, hc, y_in, oz)
		LandmarkWhGothic.window_row(lm, glass, stone, Vector3(x0, 0, oz + sz * ha), Vector3(x1, 0, oz + sz * ha), n,
			bays, bay * 0.4, ha_h * 0.46, ha_h * 0.26, bay * 0.2, 2)
		LandmarkWhGothic.window_row(lm, glass, stone, Vector3(x0, 0, oz + sz * hc), Vector3(x1, 0, oz + sz * hc), n,
			bays, bay * 0.46, (hc_h - y_in) * 0.55, y_in + 1.0, bay * 0.18, 3)
		# Parapets on the aisle and clerestory walls, a string course under the sills.
		LandmarkWhGothic.parapet(lm, stone, Vector3(x0, ha_h, oz + sz * ha), Vector3(x1, ha_h, oz + sz * ha), n, 1.0,
			2.0)
		LandmarkWhGothic.parapet(lm, stone, Vector3(x0, hc_h, oz + sz * hc), Vector3(x1, hc_h, oz + sz * hc), n, 1.2,
			2.0)
		LandmarkWestKit.blk(lm, stone, (x0 + x1) * 0.5, ha_h * 0.24, oz + sz * (ha + 0.1), x1 - x0, 0.35, 0.5)
		for k in bays + 1:
			var x := x0 + bay * float(k)
			LandmarkWhGothic.buttress(lm, stone, Vector3(x, 0, oz + sz * ha), n, 1.4, 2.4, ha_h + 1.5, 3)
			pinnacle(lm, stone, Vector3(x, ha_h + 1.5, oz + sz * (ha + 0.6)), 0.55, 1.2, 2.8)
			flyer(lm, stone, Vector3(x, ha_h + 2.0, oz + sz * (ha + 0.5)),
				Vector3(x, hc_h - 3.0, oz + sz * (hc + 0.1)), 0.8, 0.8)
			LandmarkWhGothic.buttress(lm, stone, Vector3(x, y_in, oz + sz * hc), n, 1.0, 0.8, hc_h - y_in - 1.0, 2)

## Square Perpendicular tower: shaft of side `size` from c.y to h with
## string courses and clasping corner buttresses, two traceried
## windows per stage on each of `faces` (horizontal outward normals)
## above y_vis, a pierced parapet and four corner pinnacles. Returns the height of the highest pinnacle tip.
static func square_tower(lm: LandmarkMesh, stone: String, glass: String, c: Vector3, size: float,
		h: float, y_vis: float, faces: Array, pin_shaft: float = 2.5, pin_cap: float = 3.2) -> float:
	LandmarkWestKit.blk(lm, stone, c.x, c.y, c.z, size, h - c.y, size)
	var span := h - y_vis
	for k in 3:
		LandmarkWestKit.blk(lm, stone, c.x, y_vis + span * float(k) * 0.34, c.z, size + 0.6, 0.6, size + 0.6)
	# Clasping buttresses up each corner, set back stage by stage.
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		for ax in [Vector3(q.x, 0, 0), Vector3(0, 0, q.y)]:
			var o: Vector3 = ax
			var side: Vector3 = Vector3(0, 0, q.y) if o.x != 0.0 else Vector3(q.x, 0, 0)
			LandmarkWhGothic.buttress(lm, stone, Vector3(c.x, c.y, c.z) + o * size * 0.5 + side * (size * 0.5 - 0.6),
				o, 1.2, 1.4, h - c.y - 1.0, 4)
	for f in faces:
		var fn: Vector3 = f
		var fp := c + fn * (size * 0.5)
		var half := along(fn) * size * 0.2
		LandmarkWhGothic.window_row(lm, glass, stone, fp - half, fp + half, fn, 2, size * 0.15, span * 0.28,
			y_vis + span * 0.06, size * 0.1, 2)
		LandmarkWhGothic.window_row(lm, glass, stone, fp - half, fp + half, fn, 2, size * 0.17, span * 0.3,
			y_vis + span * 0.46, size * 0.12, 2)
		var hw := along(fn) * (size * 0.5 + 0.4)
		LandmarkWhGothic.parapet(lm, stone, fp - hw + Vector3(0, h + 0.8, 0), fp + hw + Vector3(0, h + 0.8, 0), fn,
			1.4, 1.5)
	LandmarkWestKit.blk(lm, stone, c.x, h, c.z, size + 0.8, 0.8, size + 0.8)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		pinnacle(lm, stone, Vector3(c.x + q.x * size * 0.5, h + 0.8, c.z + q.y * size * 0.5), 0.7,
			pin_shaft, pin_cap)
	return h + 0.8 + pin_shaft + pin_cap

## Dormer window: a box with a glazed front and a gable, standing on a
## roof slope at `base`, facing the horizontal `n`.
static func dormer(lm: LandmarkMesh, wall: String, glass: String, base: Vector3, n: Vector3,
		w: float = 2.4, h: float = 3.6) -> void:
	var basis := Basis(Vector3.UP, atan2(n.x, n.z))
	lm.box(wall, base + Vector3(0, h * 0.5, 0), Vector3(w, h, 1.6), basis)
	lm.gable(wall, base + Vector3(0, h, 0), w, 1.6, w * 0.9, basis, 0.0, wall)
	lm.box(glass, base + n * 0.85 + Vector3(0, h * 0.5, 0), Vector3(w * 0.5, h * 0.66, 0.15), basis)

## Shifts every vertex emitted so far by `d`, to re-centre a plan on
## its footprint before commit (the model origin is the cleared circle's
## centre).
static func shift(lm: LandmarkMesh, d: Vector3) -> void:
	for surf in lm._surfs.values():
		var sf: LandmarkMesh.Surf = surf
		for i in sf.v.size():
			sf.v[i] += d
