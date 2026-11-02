class_name LandmarkGtUtil
extends RefCounted

## Shared parts of the Greece and Turkey landmark batch (true metres on
## LandmarkMesh): fluted Doric columns, solid pediments, lying column
## drums, half domes, Ottoman minarets and a stateless scatter. Each
## takes the material KEY to draw with.

## Stateless 0..1 scatter of index `i`: a model is identical every build.
static func hash01(i: int, salt: int = 0) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

## Axis box from its extents (x0..x1, y0..y1, z0..z1).
static func block(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float,
		z0: float, z1: float) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(x1 - x0, y1 - y0, z1 - z0))

## Fluted Doric column of total height h standing on `base`: faceted
## entasis shaft (the facets read as flutes), echinus and square abacus.
static func doric(lm: LandmarkMesh, key: String, base: Vector3, h: float, r0: float,
		r1: float, flutes: int = 20) -> void:
	var cap := minf(h * 0.1, r0 * 0.9)
	var shaft := h - cap
	var prof := PackedVector2Array()
	for k in 4:
		var t := float(k) / 3.0
		prof.append(Vector2(lerpf(r0, r1, t) + r0 * 0.03 * sin(PI * t), shaft * t))
	lm.lathe(key, base, prof, flutes, 1.0, 1.0, 0.0, false)
	lm.lathe(key, base + Vector3(0, shaft, 0), PackedVector2Array([Vector2(r1, 0),
		Vector2(r1 * 1.12, cap * 0.1), Vector2(r1 * 1.5, cap * 0.55)]), 12)
	lm.box(key, base + Vector3(0, shaft + cap * 0.78, 0), Vector3(r0 * 2.3, cap * 0.44, r0 * 2.3))

## Solid cylinder (or frustum, ra to rb) between two arbitrary points:
## lying column drums, beams of any heading.
static func cylinder(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, ra: float,
		rb: float, seg: int = 10) -> void:
	var axis := (b - a).normalized()
	var s := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var t := axis.cross(s)
	for i in seg:
		var d0 := s * cos(TAU * float(i) / float(seg)) + t * sin(TAU * float(i) / float(seg))
		var d1 := s * cos(TAU * float(i + 1) / float(seg)) + t * sin(TAU * float(i + 1) / float(seg))
		lm.quad(key, a + d0 * ra, a + d1 * ra, b + d1 * rb, b + d0 * rb, (d0 + d1).normalized())
		lm.tri(key, a, a + d1 * ra, a + d0 * ra, -axis, -axis, -axis, Vector2.ZERO,
			Vector2(d1.x, d1.z) * ra, Vector2(d0.x, d0.z) * ra)
		lm.tri(key, b, b + d0 * rb, b + d1 * rb, axis, axis, axis, Vector2.ZERO,
			Vector2(d0.x, d0.z) * rb, Vector2(d1.x, d1.z) * rb)

## Solid triangular pediment. `c` is the middle of the outer base edge,
## `out` the horizontal unit normal of the tympanum (drawn with `tymp`),
## the sloped roof faces and the rear are `key`; `depth` runs toward -out.
static func pediment(lm: LandmarkMesh, key: String, tymp: String, c: Vector3, out: Vector3,
		width: float, rise: float, depth: float) -> void:
	var hw := Vector3.UP.cross(out).normalized() * width * 0.5
	var back := -out * depth
	var apex := c + Vector3(0, rise, 0)
	lm.tri(tymp, c - hw, c + hw, apex, out, out, out, Vector2.ZERO, Vector2(width, 0),
		Vector2(width * 0.5, -rise))
	lm.tri(key, c - hw + back, c + hw + back, apex + back, -out, -out, -out, Vector2.ZERO,
		Vector2(width, 0), Vector2(width * 0.5, -rise))
	for sgn in [-1.0, 1.0]:
		var p0: Vector3 = c + hw * sgn
		var n := (apex - p0).cross(back).normalized()
		if n.y < 0.0:
			n = -n
		lm.quad(key, p0, apex, apex + back, p0 + back, n)

## Stack of `n` centred steps of `rise` each, the top one `size` (x, z)
## wide with its top face at `top_y`; every step below grows by `tread`.
static func steps(lm: LandmarkMesh, key: String, center: Vector2, size: Vector2, top_y: float,
		n: int, rise: float, tread: float) -> void:
	for k in n:
		var g := tread * 2.0 * float(k)
		lm.box(key, Vector3(center.x, top_y - rise * (float(k) + 0.5), center.y),
			Vector3(size.x + g, rise, size.y + g))

## Same stack for a circular building: top radius r, each step grows by tread.
static func ring_steps(lm: LandmarkMesh, key: String, center: Vector3, r: float, top_y: float,
		n: int, rise: float, tread: float, seg: int = 32) -> void:
	for k in n:
		lm.frustum(key, center + Vector3(0, top_y - rise * float(k + 1), 0), r + tread * float(k),
			r + tread * float(k), rise, seg)

## Half dome (quarter-ellipse profile) opening toward +dir: radius r at
## the base circle centre `c`, h tall, closed over the half plan only.
static func half_dome(lm: LandmarkMesh, key: String, c: Vector3, r: float, h: float,
		dir: Vector3, rings: int = 8, seg: int = 14) -> void:
	var side := Vector3.UP.cross(dir).normalized()
	var rows: Array = []
	for j in rings + 1:
		var lat := PI * 0.4925 * float(j) / float(rings)
		var row := PackedVector3Array()
		for i in seg + 1:
			var a := -PI * 0.5 + PI * float(i) / float(seg)
			var d := dir * cos(a) + side * sin(a)
			row.append(c + d * (r * cos(lat)) + Vector3(0, h * sin(lat), 0))
		rows.append(row)
	lm.grid(key, rows, c, true)

## Ottoman minaret `h` tall to the finial tip: square plinth, tapering
## round shaft, balconies at the given fractions of h and a lead cap.
static func minaret(lm: LandmarkMesh, stone: String, cap: String, base: Vector3, r: float,
		h: float, balconies: Array) -> void:
	var plinth := h * 0.09
	var cap_h := h * 0.15
	var top := h - cap_h
	lm.box(stone, base + Vector3(0, plinth * 0.5, 0), Vector3(r * 3.4, plinth, r * 3.4))
	lm.lathe(stone, base + Vector3(0, plinth, 0), PackedVector2Array([Vector2(r * 1.1, 0),
		Vector2(r * 0.8, top - plinth)]), 16)
	for f in balconies:
		var y: float = h * float(f)
		lm.lathe(stone, base + Vector3(0, y, 0), PackedVector2Array([Vector2(r * 0.8, -r * 0.5),
			Vector2(r * 1.6, 0), Vector2(r * 1.75, 0), Vector2(r * 1.75, r), Vector2(r * 1.5, r)]),
			16, 1.0, 1.0, 0.0, false)
	lm.lathe(cap, base + Vector3(0, top, 0), PackedVector2Array([Vector2(r * 1.05, 0),
		Vector2(r * 0.85, cap_h * 0.04), Vector2(r * 0.62, cap_h * 0.16), Vector2(r * 0.4, cap_h * 0.55),
		Vector2(r * 0.14, cap_h * 0.92), Vector2(0, cap_h)]), 16)
