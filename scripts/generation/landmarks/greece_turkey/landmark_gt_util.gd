class_name LandmarkGtUtil
extends RefCounted

## Shared parts of the Greece and Turkey landmark batch (true metres on
## LandmarkMesh): fluted drums and part-built Doric columns, the Doric
## entablature, solid pediments, lying cylinders, steps, half domes and
## a stateless scatter. Each takes the material KEY to draw with.

## Stateless 0..1 scatter of index `i`: a model is identical every build.
static func hash01(i: int, salt: int = 0) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

## Axis box from its extents (x0..x1, y0..y1, z0..z1).
static func block(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float,
		z0: float, z1: float) -> void:
	lm.box(key, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(x1 - x0, y1 - y0, z1 - z0))

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

## Blocks laid in `n` courses between the extents, joints staggered
## every `l` metres along the long side.
static func courses(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float,
		z0: float, z1: float, n: int, l: float) -> void:
	var ch := (y1 - y0) / float(n)
	var along_x := (x1 - x0) >= (z1 - z0)
	var span := (x1 - x0) if along_x else (z1 - z0)
	for k in n:
		var t := 0.0 if k % 2 == 0 else -l * 0.5
		while t < span - 0.01:
			var u0 := maxf(t, 0.0)
			var u1 := minf(t + l, span)
			if along_x:
				LandmarkGtUtil.block(lm, key, x0 + u0, x0 + u1 - 0.03, y0 + ch * k, y0 + ch * (k + 1) - 0.02, z0, z1)
			else:
				LandmarkGtUtil.block(lm, key, x0, x1, y0 + ch * k, y0 + ch * (k + 1) - 0.02, z0 + u0, z0 + u1 - 0.03)
			t += l

## Fluted drum (or stump) from a to b, radius ra at a and rb at b, with
## `flutes` concave flutes and flat ends: lying column drums and the
## stumps of columns still on the stylobate.
static func fluted(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, ra: float, rb: float,
		flutes: int = 20) -> void:
	var axis := (b - a).normalized()
	var s := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var t := axis.cross(s)
	var per := 3
	var cols := flutes * per
	var rows: Array = []
	for e in [[a, ra], [b, rb]]:
		var c: Vector3 = e[0]
		var r: float = e[1]
		var ring := PackedVector3Array()
		for i in cols + 1:
			var ang := TAU * float(i) / float(cols)
			var depth := sin(PI * float(i % per) / float(per)) * r * 0.05
			ring.append(c + (s * cos(ang) + t * sin(ang)) * (r - depth))
		rows.append(ring)
	lm.grid(key, rows, (a + b) * 0.5, true)
	lm.disc(key, a, -axis, ra * 0.97, flutes)
	lm.disc(key, b, axis, rb * 0.97, flutes)

## Doric entablature along a..b (face line at the column axis, `a`, `b`
## at the architrave soffit), front facing `out`: architrave with its
## taenia, regulae under each triglyph, a frieze of `n` triglyphs (three
## proud glyph bars each) between recessed metopes, and the geison with
## a mutule over every triglyph and metope. `d` is the architrave depth;
## heights arch_h / frieze_h / geison_h. Triglyphs are drawn on the
## front only (`both` draws the back face too).
static func doric_entablature(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3,
		d: float, arch_h: float, frieze_h: float, geison_h: float, n: int, both: bool = false) -> void:
	var dir := (b - a).normalized()
	var o := out.normalized()
	var run := a.distance_to(b)
	var bas := Basis(dir, Vector3.UP, o)
	var mid := (a + b) * 0.5
	lm.box(key, mid + Vector3(0, arch_h * 0.45, 0), Vector3(run, arch_h * 0.9, d), bas)
	lm.box(key, mid + Vector3(0, arch_h * 0.95, 0), Vector3(run + 0.02, arch_h * 0.1, d + 0.08), bas, 0.0)
	var fy := arch_h + frieze_h * 0.5
	lm.box(key, mid + Vector3(0, fy, 0), Vector3(run, frieze_h, d * 0.86), bas)
	var tw := frieze_h * 0.62
	var sides := [1.0, -1.0] if both else [1.0]
	for sg in sides:
		var so: Vector3 = o * float(sg)
		for i in n:
			var p := a.lerp(b, float(i) / float(maxi(n - 1, 1)))
			var face := p + so * d * 0.43
			for k in 3:
				lm.box(key, face + dir * tw * (float(k) - 1.0) * 0.36 + Vector3(0, fy, 0) + so * 0.04,
					Vector3(tw * 0.24, frieze_h * 0.94, 0.08), bas, 0.0)
			lm.box(key, face + Vector3(0, fy + frieze_h * 0.47, 0) + so * 0.05, Vector3(tw * 1.05, frieze_h * 0.07, 0.1),
				bas, 0.0)
			lm.box(key, p + so * (d * 0.5 + 0.03) + Vector3(0, arch_h * 0.84, 0), Vector3(tw, arch_h * 0.06, 0.06),
				bas, 0.0)
	var gy := arch_h + frieze_h
	lm.box(key, mid + Vector3(0, gy + geison_h * 0.6, 0) + o * d * 0.12, Vector3(run + d * 0.5, geison_h * 0.8,
		d * 1.25), bas)
	lm.box(key, mid + Vector3(0, gy + geison_h * 0.08, 0), Vector3(run, geison_h * 0.16, d), bas, 0.0)
	var nm := maxi(n * 2 - 1, 1)
	for i in nm:
		var p2 := a.lerp(b, float(i) / float(maxi(nm - 1, 1)))
		lm.box(key, p2 + o * d * 0.6 + Vector3(0, gy + geison_h * 0.15, 0), Vector3(tw * 0.9, geison_h * 0.12,
			d * 0.18), bas, 0.0)

## Doric column (LandmarkDetail) of total height h and lower radius r at
## `base`, or, when `upto` < h, only the stack of its first drums up to
## that height (a column re-erected part way), the top drum's bed bare.
static func doric_column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		flutes: int = 20, upto: float = -1.0) -> void:
	if upto < 0.0 or upto >= h - 0.01:
		LandmarkDetail.column(lm, key, base, r, h, "doric", flutes)
		return
	var shaft := h - r * 0.9
	var rt := r if upto <= shaft * 0.33 else lerpf(r, r * 0.83, (upto / shaft - 0.33) / 0.67)
	fluted(lm, key, base, base + Vector3(0, upto, 0), r, rt, flutes)
