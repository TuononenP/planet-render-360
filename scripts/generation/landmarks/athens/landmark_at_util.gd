class_name AtUtil
extends RefCounted

## Helpers shared by the Athens landmark builders (true metres on
## LandmarkMesh): the three Greek orders, stepped platforms, pitched
## temple roofs, caryatids, arched walls and curved seating tiers
## (circular cavea and the horseshoe of a stadium).

# --- Columns ----------------------------------------------------------

## Fluted-looking shaft: a faceted prism tapering r0 to r1 with a slight
## entasis. Left open at both ends (the base and capital hide them).
static func shaft(lm: LandmarkMesh, key: String, base: Vector3, h: float, r0: float,
		r1: float, sides: int = 16) -> void:
	var mid := lerpf(r0, r1, 0.4) * 1.02
	lm.lathe(key, base, PackedVector2Array([Vector2(r0, 0), Vector2(mid, h * 0.4), Vector2(r1, h)]),
		sides, 1.0, 1.0, 0.0, false, false)

## Doric column with no base: fluted shaft, echinus and square abacus.
## `h` is the full height, `r` the lower radius, `rot` turns the abacus.
static func doric(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		sides: int = 16, rot: float = 0.0) -> void:
	var cap := r * 0.6
	var eh := cap * 0.6
	shaft(lm, key, base, h - cap, r, r * 0.78, sides)
	lm.frustum(key, base + Vector3(0, h - cap, 0), r * 0.78, r * 1.08, eh, 12)
	lm.box(key, base + Vector3(0, h - cap + eh + (cap - eh) * 0.5, 0),
		Vector3(r * 2.3, cap - eh, r * 2.3), Basis(Vector3.UP, rot))

## Attic-Ionic base: two tori with a scotia between, 0.7 r tall.
static func _attic_base(lm: LandmarkMesh, key: String, base: Vector3, r: float) -> float:
	var bh := r * 0.7
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.4, 0), Vector2(r * 1.4, bh * 0.35),
		Vector2(r * 1.15, bh * 0.5), Vector2(r * 1.25, bh * 0.8), Vector2(r, bh)]), 12)
	return bh

## Ionic column on an attic base: shaft, echinus, cushion with a volute
## roll at each side and a thin abacus. The volute faces look along the
## local Z axis, turned by `rot` (PI/2 for a facade running north-south).
static func ionic(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		sides: int = 16, rot: float = 0.0) -> void:
	var bh := _attic_base(lm, key, base, r)
	var ch := r * 0.95
	shaft(lm, key, base + Vector3(0, bh, 0), h - bh - ch, r, r * 0.84, sides)
	var b := Basis(Vector3.UP, rot)
	var yc := base.y + h - ch
	lm.frustum(key, Vector3(base.x, yc, base.z), r * 0.84, r * 1.0, r * 0.22, 12)
	lm.box(key, Vector3(base.x, yc + r * 0.22 + r * 0.25, base.z), Vector3(r * 2.9, r * 0.5, r * 1.5), b)
	for s in [-1.0, 1.0]:
		var c: Vector3 = Vector3(base.x, yc + r * 0.5, base.z) + b * Vector3(s * r * 1.2, 0, 0)
		cyl(lm, key, c - b.z * r * 0.75, c + b.z * r * 0.75, r * 0.42, 8)
	lm.box(key, Vector3(base.x, base.y + h - r * 0.07, base.z), Vector3(r * 3.1, r * 0.14, r * 2.2), b)

## Corinthian column on an attic base: shaft, bell of acanthus leaves,
## abacus. The capital is 1.2 diameters tall.
static func corinthian(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float,
		sides: int = 16, rot: float = 0.0) -> void:
	var bh := _attic_base(lm, key, base, r)
	var ch := r * 2.4
	shaft(lm, key, base + Vector3(0, bh, 0), h - bh - ch, r, r * 0.84, sides)
	var yc := Vector3(base.x, base.y + h - ch, base.z)
	lm.lathe(key, yc, PackedVector2Array([Vector2(r * 0.84, 0), Vector2(r * 0.95, ch * 0.12),
		Vector2(r * 0.98, ch * 0.35), Vector2(r * 1.1, ch * 0.6), Vector2(r * 1.3, ch * 0.85),
		Vector2(r * 1.42, ch * 0.92)]), 12, 1.0, 1.0, 0.0, true, false)
	lm.lathe(key, yc, PackedVector2Array([Vector2(r * 0.9, ch * 0.02), Vector2(r * 1.2, ch * 0.2),
		Vector2(r * 1.02, ch * 0.5)]), 8, 1.0, 1.0, 0.0, true, false)
	lm.box(key, yc + Vector3(0, ch * 0.96, 0), Vector3(r * 3.0, ch * 0.08, r * 3.0), Basis(Vector3.UP, rot))

## Round-section member from `a` to `b` (volute rolls, fallen drums).
static func cyl(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r: float,
		seg: int = 10) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	for i in seg:
		var t0 := TAU * float(i) / float(seg)
		var t1 := TAU * float(i + 1) / float(seg)
		var d0 := u * cos(t0) + v * sin(t0)
		var d1 := u * cos(t1) + v * sin(t1)
		lm.quad(key, a + d0 * r, a + d1 * r, b + d1 * r, b + d0 * r, ((d0 + d1) * 0.5).normalized())
	lm.disc(key, a, -axis, r, seg)
	lm.disc(key, b, axis, r, seg)

## Draped maiden of the Erechtheion porch with her basket capital:
## `h` tall in all, `r` the half-width of the robe.
static func caryatid(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.05, 0), Vector2(r, h * 0.38),
		Vector2(r * 0.85, h * 0.5), Vector2(r * 1.1, h * 0.6), Vector2(r * 0.7, h * 0.7),
		Vector2(r * 0.4, h * 0.73)]), 10)
	lm.lathe(key, base + Vector3(0, h * 0.73, 0), SEuUtil.dome(r * 0.5, r * 0.7, 4), 8)
	lm.frustum(key, base + Vector3(0, h * 0.83, 0), r * 0.62, r * 1.0, h * 0.07, 10)
	lm.box(key, base + Vector3(0, h * 0.93, 0), Vector3(r * 2.3, h * 0.14, r * 2.3))

# --- Platforms and roofs ---------------------------------------------

## Stepped platform: `n` steps `rise` high, each `tread` wider than the one
## above; the top step is w x d centred on c with its top at c.y. The
## lowest step reaches `found` metres deeper (foundations).
static func steps(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, n: int,
		rise: float, tread: float, found: float = 2.0) -> void:
	for k in n:
		var g := tread * float(k)
		var h := rise + (found if k == n - 1 else 0.0)
		lm.box(key, Vector3(c.x, c.y - rise * float(k) - h * 0.5, c.z), Vector3(w + 2.0 * g, h, d + 2.0 * g))

## Pitched roof with tympanum triangles and raking cornices at both
## ends: eaves at c.y, `w` across the basis X, `l` along its Z (ridge).
static func roof(lm: LandmarkMesh, roof_key: String, stone_key: String, tymp_key: String,
		c: Vector3, w: float, l: float, rise: float, over: float = 0.3,
		basis: Basis = Basis()) -> void:
	lm.gable(roof_key, c, w, l, rise, basis, over, tymp_key)
	for s in [-1.0, 1.0]:
		var e: Vector3 = c + basis.z * (l * 0.5 + 0.1) * s
		var apex: Vector3 = e + basis.y * rise
		for t in [-1.0, 1.0]:
			lm.beam(stone_key, e + basis.x * (w * 0.5 + over * 0.5) * t, apex, 0.7, 0.45, basis.z)

## `n` small boxes (triglyphs and the like) evenly from a to b.
static func row_boxes(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int,
		size: Vector3, basis: Basis = Basis()) -> void:
	for i in n:
		lm.box(key, a.lerp(b, float(i) / float(maxi(n - 1, 1))), size, basis)

## Wall with a semicircular opening of radius r centred on cx: spandrel
## faces up to top_y on both planes (z0 front, z1 back) and the soffit.
static func arch_wall(lm: LandmarkMesh, key: String, cx: float, spring_y: float, r: float,
		top_y: float, z0: float, z1: float) -> void:
	var prev := Vector3.ZERO
	for k in 11:
		var a := PI * (1.0 - float(k) / 10.0)
		var p := Vector3(cx + r * cos(a), spring_y + r * sin(a), 0)
		if k > 0:
			for z in [z0, z1]:
				var zz: float = z
				lm.quad(key, Vector3(prev.x, prev.y, zz), Vector3(p.x, p.y, zz),
					Vector3(p.x, top_y, zz), Vector3(prev.x, top_y, zz),
					Vector3(0, 0, signf(zz - (z0 + z1) * 0.5)))
			var inward := Vector3(cx - p.x, spring_y - p.y, 0).normalized()
			lm.quad(key, Vector3(prev.x, prev.y, z0), Vector3(p.x, p.y, z0),
				Vector3(p.x, p.y, z1), Vector3(prev.x, prev.y, z1), inward)
		prev = p

# --- Seating ----------------------------------------------------------

## Tiers on a circular arc about c (angles in radians, direction
## (cos a, sin a) in XZ): `rows` tiers from radius r0, each `depth` deep
## and `rise` higher than the one before, the first topping out at
## y0 + rise. Each tier is a prism running down to base_y.
static func cavea(lm: LandmarkMesh, key: String, c: Vector3, r0: float, rows: int,
		depth: float, rise: float, a0: float, a1: float, y0: float, base_y: float) -> void:
	var r_end := r0 + depth * float(rows)
	var segs := maxi(int(ceil(absf(a1 - a0) * r_end / 2.5)), 3)
	for k in rows:
		var ri := r0 + depth * float(k)
		var ro := ri + depth
		var poly := PackedVector2Array()
		for i in segs + 1:
			var a := lerpf(a0, a1, float(i) / float(segs))
			poly.append(Vector2(c.x + cos(a) * ro, c.z + sin(a) * ro))
		for i in range(segs, -1, -1):
			var a := lerpf(a0, a1, float(i) / float(segs))
			poly.append(Vector2(c.x + cos(a) * ri, c.z + sin(a) * ri))
		lm.poly_prism(key, poly, base_y, y0 + rise * float(k + 1))

## Sloped stair strip between two radii on a cavea aisle (centre angle
## `am`, half-width `da` radians), rising from y_in to y_out.
static func aisle(lm: LandmarkMesh, key: String, c: Vector3, am: float, da: float,
		r_in: float, r_out: float, y_in: float, y_out: float) -> void:
	lm.quad(key, c + Vector3(cos(am - da) * r_in, y_in, sin(am - da) * r_in),
		c + Vector3(cos(am + da) * r_in, y_in, sin(am + da) * r_in),
		c + Vector3(cos(am + da) * r_out, y_out, sin(am + da) * r_out),
		c + Vector3(cos(am - da) * r_out, y_out, sin(am - da) * r_out), Vector3.UP)

## A cavea cut into `n` wedges by radial stair aisles `gap` radians wide,
## each aisle a sloped strip in `stair_key`.
static func cavea_wedges(lm: LandmarkMesh, key: String, stair_key: String, c: Vector3,
		r0: float, rows: int, depth: float, rise: float, a0: float, a1: float, y0: float,
		base_y: float, n: int, gap: float) -> void:
	var span := (a1 - a0 - gap * float(n - 1)) / float(n)
	for i in n:
		var w0 := a0 + (span + gap) * float(i)
		cavea(lm, key, c, r0, rows, depth, rise, w0, w0 + span, y0, base_y)
		if i < n - 1:
			aisle(lm, stair_key, c, w0 + span + gap * 0.5, gap * 0.5, r0,
				r0 + depth * float(rows), y0, y0 + rise * float(rows))

## Annular band of a horseshoe (two parallel straights from z_open back
## to z_c, then a semicircle round the centre (0, z_c) toward -Z), between
## half-widths r_in and r_out, as a prism from y0 to y1.
static func u_band(lm: LandmarkMesh, key: String, z_open: float, z_c: float, r_in: float,
		r_out: float, y0: float, y1: float, arc_segs: int = 24) -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(-r_out, z_open))
	for i in range(0, arc_segs + 1):
		var t := PI + PI * float(i) / float(arc_segs)
		poly.append(Vector2(r_out * cos(t), z_c + r_out * sin(t)))
	poly.append(Vector2(r_out, z_open))
	poly.append(Vector2(r_in, z_open))
	for i in range(arc_segs, -1, -1):
		var t := PI + PI * float(i) / float(arc_segs)
		poly.append(Vector2(r_in * cos(t), z_c + r_in * sin(t)))
	poly.append(Vector2(-r_in, z_open))
	lm.poly_prism(key, poly, y0, y1)

## Stadium tiers: `rows` horseshoe bands of width `depth` from half-width
## r0, each `rise` higher than the one before (first top at y0 + rise).
static func u_rows(lm: LandmarkMesh, key: String, z_open: float, z_c: float, r0: float,
		rows: int, depth: float, rise: float, y0: float, base_y: float) -> void:
	for k in rows:
		var ri := r0 + depth * float(k)
		u_band(lm, key, z_open, z_c, ri, ri + depth, base_y, y0 + rise * float(k + 1))
