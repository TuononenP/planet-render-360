class_name TowerSpec
extends RefCounted

## Data-driven skyscrapers on the SkyKit: a NycTowerSpecs* row gives a facade
## finish and a short list of ops, so most of New York's towers are rows of
## data, not code. Plan coordinates are metres in the model's frame (+X its
## long axis, as the row's yaw_deg turns it); y is metres above the ground.
##   finish, bay, floor, trim, rib  the "Facade" wall and the tier trim; the
##          surfaces Trim, Roof, Gap, Louvre, Slope and Gold always exist
##   walls  more facade surfaces {key: [finish, bay_m, floor_m]}
##   mats   more surfaces {key: [kind, hex, ...]}: paint (roughness?,
##          metallic?), glass, gold, lit (energy?) or a PbrCatalog set
##          (tile_m?), such as stone, limestone, copper
##   ops    in order, each an Array [op, ...]:
##     ["use", key]                      later walls in facade surface `key`
##     ["tier", y0, y1, w, d, cx?, cz?]  a box tier with its trim band and roof
##     ["notch", y0, y1, w, d, n]        a tier with re-entrant corners
##     ["shape", kind, y0, y1, w, d, cut, w1?, d1?, cx?, cz?]  a plan of
##          `kind` (see plan()), lofted to w1 x d1 at y1 when they are given
##     ["poly", y0, y1, pts, k1?]        an explicit plan [[x, z], ...], scaled
##          by k1 about its centre at y1 (a taper) when given
##     ["gap", y0, y1, w, d, cx?, cz?]   a dark recessed plant storey
##     ["louvre", y0, y1, w, d]          a louvred screen round a flat top
##     ["pyramid", key, y, w, d, h, top_k?, cx?, cz?]  a hipped roof on a
##          rectangle (top_k: the flat top's fraction of the base)
##     ["hip", key, y, h, pts, top_k?]   a hipped roof on a convex plan
##     ["solid", key, y0, y1, pts]       a windowless mass in surface `key`
##     ["steps", key, y, w, d, n, step_h, inset]  a ziggurat of n steps
##     ["spire", key, y, hw, h, top_hw?, sides?, x?, z?]
##     ["box", key, x, y, z, sx, sy, sz]  a box standing on y
##     ["dome", key, y, r, h, x?, z?]
##     ["pediment", key, y, w, d, rise, gap]  a gable across the +X long
##          sides, its ridge along Z, broken by a `gap` wide notch (550 Madison)
##     ["diagrid", key, y0, y1, w, d, cell_h, n, cx?, cz?]  diagonal members
##          over a w x d box, n diamonds across each face, cell_h tall (Hearst)
##     ["slope", y_low, y_high, w, d]    a roof cut from y_low on -Z up to
##          y_high on +Z (Citigroup Center)
##     ["ribs", key, y0, y1, w, d, spacing, cx?, cz?]

const OPS := ["use", "tier", "notch", "shape", "poly", "gap", "louvre", "pyramid", "hip", "solid", "steps",
	"spire", "box", "dome", "slope", "ribs", "pediment", "diagrid"]
const SHAPES := ["rect", "chamfer", "ellipse", "round", "hex", "tri"]

## Builds `spec` under `model`.
static func build(model: Node3D, spec: Dictionary) -> void:
	var kit := SkyKit.tower(str(spec.get("finish", "clear_fin")), float(spec.get("bay", 3.0)),
		float(spec.get("floor", 4.0)), [], str(spec.get("trim", "#8b8e90")))
	var lm := kit.lm
	lm.use("Gap", LandmarkMaterials.paint("#26282b", 0.6, 0.1))
	lm.use("Louvre", LandmarkMaterials.paint("#4f5356", 0.5, 0.5))
	lm.use("Slope", LandmarkMaterials.paint("#a9adb1", 0.35, 0.8))
	lm.use("Gold", LandmarkMaterials.gold())
	var walls: Dictionary = spec.get("walls", {})
	for key in walls:
		var w := walls[key] as Array
		kit.wall(str(key), str(w[0]), float(w[1]), float(w[2]))
	var mats: Dictionary = spec.get("mats", {})
	for key in mats:
		lm.use(str(key), material(mats[key] as Array))
	var rib := float(spec.get("rib", 0.0))
	var face := "Facade"
	for o in spec.get("ops", []):
		var op := o as Array
		match str(op[0]):
			"use":
				face = str(op[1])
			"tier":
				var plan := SkyKit.rect(float(op[3]), float(op[4]), _f(op, 5), _f(op, 6))
				_walls(kit, face, plan, plan, float(op[1]), float(op[2]), rib, true)
			"notch":
				var plan := SkyKit.notched(float(op[3]), float(op[4]), float(op[5]))
				_walls(kit, face, plan, plan, float(op[1]), float(op[2]), 0.0, false)
			"shape":
				var w0 := float(op[4])
				var d0 := float(op[5])
				var cut := _f(op, 6)
				var low := plan(str(op[1]), w0, d0, cut, _f(op, 9), _f(op, 10))
				var high := plan(str(op[1]), _f(op, 7, w0), _f(op, 8, d0), cut, _f(op, 9), _f(op, 10))
				_walls(kit, face, low, high, float(op[2]), float(op[3]), rib, false)
			"poly":
				var low := _pts(op[3] as Array)
				var high := scaled(low, _f(op, 4, 1.0))
				_walls(kit, face, low, high, float(op[1]), float(op[2]), 0.0, false)
			"gap":
				lm.poly_prism("Gap", SkyKit.rect(float(op[3]), float(op[4]), _f(op, 5), _f(op, 6)),
					float(op[1]), float(op[2]), false)
			"louvre":
				lm.poly_prism("Louvre", SkyKit.rect(float(op[3]), float(op[4])), float(op[1]), float(op[2]), false)
			"pyramid":
				pyramid(lm, str(op[1]), float(op[2]), float(op[3]), float(op[4]), float(op[5]), _f(op, 6),
					_f(op, 7), _f(op, 8))
			"hip":
				hip(lm, str(op[1]), float(op[2]), float(op[3]), _pts(op[4] as Array), _f(op, 5))
			"solid":
				lm.poly_prism(str(op[1]), _pts(op[4] as Array), float(op[2]), float(op[3]))
			"steps":
				var w := float(op[3])
				var d := float(op[4])
				var y := float(op[2])
				for i in int(op[5]):
					lm.poly_prism(str(op[1]), SkyKit.rect(w, d), y, y + float(op[6]))
					y += float(op[6])
					w -= float(op[7]) * 2.0
					d -= float(op[7]) * 2.0
			"spire":
				lm.spire(str(op[1]), Vector3(_f(op, 7), float(op[2]), _f(op, 8)), float(op[3]), float(op[4]),
					_f(op, 5), int(_f(op, 6, 4.0)))
			"box":
				lm.box(str(op[1]), Vector3(float(op[2]), float(op[3]) + float(op[6]) * 0.5, float(op[4])),
					Vector3(float(op[5]), float(op[6]), float(op[7])), Basis(), 0.0)
			"dome":
				var prof := PackedVector2Array()
				for i in 7:
					var a := float(i) / 6.0 * PI * 0.5
					prof.append(Vector2(cos(a) * float(op[3]), sin(a) * float(op[4])))
				lm.lathe(str(op[1]), Vector3(_f(op, 5), float(op[2]), _f(op, 6)), prof, 16)
			"slope":
				_slope(kit, face, float(op[1]), float(op[2]), float(op[3]), float(op[4]))
			"pediment":
				pediment(lm, str(op[1]), float(op[2]), float(op[3]), float(op[4]), float(op[5]), float(op[6]))
			"diagrid":
				diagrid(lm, str(op[1]), float(op[2]), float(op[3]), float(op[4]), float(op[5]), float(op[6]),
					int(op[7]), Vector3(_f(op, 8), 0.0, _f(op, 9)))
			"ribs":
				kit.rib_all(str(op[1]), SkyKit.rect(float(op[4]), float(op[5]), _f(op, 7), _f(op, 8)),
					float(op[2]), float(op[3]), float(op[6]))
	lm.commit(model)

## Walls from `low` at y0 to `high` at y1 with a roof over `high`; a trim
## band under the roof line and ribs every `rib` metres when asked.
static func _walls(kit: SkyKit, face: String, low: PackedVector2Array, high: PackedVector2Array,
		y0: float, y1: float, rib: float, band: bool) -> void:
	if low == high:
		kit.prism(face, low, y0, y1, "Roof")
	else:
		kit.loft(face, low, high, y0, y1)
		kit.roof("Roof", high, y1)
	if band:
		kit.band("Trim", high, y1 - 0.5, y1 + 0.4, 0.3)
	if rib > 0.0 and low == high:
		kit.rib_all("Trim", low, y0, y1, rib)

## A plan of `kind`, w x d centred on (cx, cz):
##   rect     a rectangle
##   chamfer  corners cut by `cut` metres
##   round    corners rounded to radius `cut`
##   ellipse  an ellipse (`cut` sides, 24 when 0)
##   hex      a long hexagon, its ends pointed by `cut` metres
##   tri      a triangle with its corners cut by `cut`, apex on +X
static func plan(kind: String, w: float, d: float, cut: float = 0.0, cx: float = 0.0,
		cz: float = 0.0) -> PackedVector2Array:
	var x := w * 0.5
	var z := d * 0.5
	var c := Vector2(cx, cz)
	var out := PackedVector2Array()
	match kind:
		"chamfer":
			var k := minf(cut, minf(x, z) * 0.95)
			for p in [Vector2(-x + k, -z), Vector2(x - k, -z), Vector2(x, -z + k), Vector2(x, z - k),
					Vector2(x - k, z), Vector2(-x + k, z), Vector2(-x, z - k), Vector2(-x, -z + k)]:
				out.append(c + (p as Vector2))
		"round":
			var r := minf(cut, minf(x, z) * 0.98)
			for q in 4:
				var corner := Vector2(x - r if q == 0 or q == 3 else -x + r, z - r if q < 2 else -z + r)
				for i in 4:
					var a := (float(q) + float(i) / 3.0) * PI * 0.5
					out.append(c + corner + Vector2(cos(a), sin(a)) * r)
		"ellipse":
			var n := int(cut) if cut >= 6.0 else 24
			for i in n:
				var a := TAU * float(i) / float(n)
				out.append(c + Vector2(cos(a) * x, sin(a) * z))
		"hex":
			for p in [Vector2(-x, 0), Vector2(-x + cut, -z), Vector2(x - cut, -z), Vector2(x, 0),
					Vector2(x - cut, z), Vector2(-x + cut, z)]:
				out.append(c + (p as Vector2))
		"tri":
			var corners := [Vector2(x, 0), Vector2(-x, z), Vector2(-x, -z)]
			for i in 3:
				var p: Vector2 = corners[i]
				var prev: Vector2 = corners[(i + 2) % 3]
				var next: Vector2 = corners[(i + 1) % 3]
				out.append(c + p + (prev - p).normalized() * cut)
				out.append(c + p + (next - p).normalized() * cut)
		_:
			out = SkyKit.rect(w, d, cx, cz)
	return out

## `poly` scaled by k about its vertex mean.
static func scaled(poly: PackedVector2Array, k: float) -> PackedVector2Array:
	if is_equal_approx(k, 1.0):
		return poly
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	var out := PackedVector2Array()
	for p in poly:
		out.append(c + (p - c) * k)
	return out

## A hipped roof over a w x d rectangle from y, h high; top_k > 0 leaves a
## flat top that fraction of the base.
static func pyramid(lm: LandmarkMesh, key: String, y: float, w: float, d: float, h: float,
		top_k: float = 0.0, cx: float = 0.0, cz: float = 0.0) -> void:
	var r := maxf(w, d) * 0.5
	lm.lathe(key, Vector3(cx, y, cz), PackedVector2Array([Vector2(r * sqrt(2.0), 0), Vector2(r * sqrt(2.0) * top_k, h)]),
		4, w * 0.5 / r, d * 0.5 / r, PI * 0.25, false)

## A hipped roof on convex `poly` from y, h high, its top `poly` shrunk to
## top_k about its centre (a point at 0, a flat top above).
static func hip(lm: LandmarkMesh, key: String, y: float, h: float, poly: PackedVector2Array,
		top_k: float = 0.0) -> void:
	var top := scaled(poly, maxf(top_k, 0.0001))
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	for i in poly.size():
		var j := (i + 1) % poly.size()
		var a := Vector3(poly[i].x, y, poly[i].y)
		var b := Vector3(poly[j].x, y, poly[j].y)
		var t0 := Vector3(top[i].x, y + h, top[i].y)
		var t1 := Vector3(top[j].x, y + h, top[j].y)
		var n := (b - a).cross(t0 - a).normalized()
		var mid := (poly[i] + poly[j]) * 0.5 - c
		if n.dot(Vector3(mid.x, 0.0, mid.y)) < 0.0:
			n = -n
		var la := Vector2(0, 0)
		var lb := Vector2(a.distance_to(b), 0)
		lm.tri(key, a, b, t1, n, n, n, la, lb, Vector2(lb.x, h))
		if top_k > 0.0:
			lm.tri(key, a, t1, t0, n, n, n, la, Vector2(lb.x, h), Vector2(0, h))
	if top_k > 0.0:
		var idx := Geometry2D.triangulate_polygon(top)
		for t in range(0, idx.size(), 3):
			var p0 := top[idx[t]]
			var p1 := top[idx[t + 1]]
			var p2 := top[idx[t + 2]]
			lm.tri(key, Vector3(p0.x, y + h, p0.y), Vector3(p1.x, y + h, p1.y), Vector3(p2.x, y + h, p2.y),
				Vector3.UP, Vector3.UP, Vector3.UP, p0, p1, p2)

## A gable over w x d from y, `rise` high at its ridge on x = 0 (running
## along Z), cut by a notch `gap` wide down to half the rise: two sloped
## wedges with their end triangles and the notch's inner faces.
static func pediment(lm: LandmarkMesh, key: String, y: float, w: float, d: float, rise: float,
		gap: float) -> void:
	var x := w * 0.5
	var z := d * 0.5
	var g := gap * 0.5
	var inner := rise * (1.0 - g / x)
	var cut := minf(inner, rise * 0.5)
	for side in [-1.0, 1.0]:
		var o := Vector3(side * x, y, 0)
		var i0 := Vector3(side * g, y, 0)
		var top := Vector3(side * g, y + inner, 0)
		var low := Vector3(side * g, y + cut, 0)
		# Sloped roof from the eave to the notch.
		lm.quad(key, o + Vector3(0, 0, -z), top + Vector3(0, 0, -z), top + Vector3(0, 0, z), o + Vector3(0, 0, z),
			Vector3(side * rise / x, 1.0, 0).normalized())
		# The notch's face down to its floor, and the floor.
		lm.quad(key, top + Vector3(0, 0, -z), low + Vector3(0, 0, -z), low + Vector3(0, 0, z), top + Vector3(0, 0, z),
			Vector3(-side, 0, 0))
		for e in [-1.0, 1.0]:
			var n := Vector3(0, 0, e)
			lm.tri(key, o + n * z, i0 + n * z, top + n * z, n, n, n, Vector2.ZERO, Vector2(x - g, 0), Vector2(x - g, inner))
	lm.quad(key, Vector3(-g, y + cut, -z), Vector3(g, y + cut, -z), Vector3(g, y + cut, z), Vector3(-g, y + cut, z),
		Vector3.UP)
	for e in [-1.0, 1.0]:
		var n := Vector3(0, 0, e)
		lm.quad(key, Vector3(-g, y, e * z), Vector3(g, y, e * z), Vector3(g, y + cut, e * z), Vector3(-g, y + cut, e * z), n)

## Diagonal members over the faces of a w x d box from y0 to y1: `n`
## diamonds across each face, each `cell_h` tall, standing just proud.
static func diagrid(lm: LandmarkMesh, key: String, y0: float, y1: float, w: float, d: float, cell_h: float,
		n: int, at: Vector3 = Vector3.ZERO) -> void:
	var x := w * 0.5
	var z := d * 0.5
	var faces := [[Vector3(-x, 0, z + 0.4), Vector3(x, 0, z + 0.4)], [Vector3(x, 0, -z - 0.4), Vector3(-x, 0, -z - 0.4)],
		[Vector3(x + 0.4, 0, z), Vector3(x + 0.4, 0, -z)], [Vector3(-x - 0.4, 0, -z), Vector3(-x - 0.4, 0, z)]]
	var rows := maxi(1, roundi((y1 - y0) / cell_h))
	var h := (y1 - y0) / float(rows)
	for f in faces:
		var a: Vector3 = (f[0] as Vector3) + at
		var b: Vector3 = (f[1] as Vector3) + at
		for r in rows:
			var ya := y0 + h * float(r)
			for k in n:
				var p0 := a.lerp(b, float(k) / float(n)) + Vector3(0, ya, 0)
				var p1 := a.lerp(b, float(k + 1) / float(n)) + Vector3(0, ya + h, 0)
				var q0 := a.lerp(b, float(k + 1) / float(n)) + Vector3(0, ya, 0)
				var q1 := a.lerp(b, float(k) / float(n)) + Vector3(0, ya + h, 0)
				lm.beam(key, p0, p1, 0.9, 0.6)
				lm.beam(key, q0, q1, 0.9, 0.6)

## Citigroup's cut: walls to y_low all round, the +Z wall on to y_high, two
## triangular sides and the slope between.
static func _slope(kit: SkyKit, face: String, y_low: float, y_high: float, w: float, d: float) -> void:
	var lm := kit.lm
	var x := w * 0.5
	var z := d * 0.5
	var a := Vector3(-x, y_low, -z)
	var b := Vector3(x, y_low, -z)
	var c := Vector3(x, y_low, z)
	var e := Vector3(-x, y_low, z)
	var c2 := Vector3(x, y_high, z)
	var e2 := Vector3(-x, y_high, z)
	kit.face(face, Vector2(-x, z), Vector2(x, z), y_low, y_high, Vector3.BACK)
	var up := (c2 - b).cross(a - b).normalized()
	if up.y < 0.0:
		up = -up
	lm.tri("Slope", a, b, c2, up, up, up, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	lm.tri("Slope", a, c2, e2, up, up, up, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	kit.wall_tri(face, b, c, c2, b, Vector3.BACK, y_high)
	kit.wall_tri(face, a, e, e2, a, Vector3.BACK, y_high)

## A `mats` surface: [kind, hex, ...] (see the header).
static func material(m: Array) -> StandardMaterial3D:
	var hex := str(m[1])
	match str(m[0]):
		"paint":
			return LandmarkMaterials.paint(hex, _f(m, 2, 0.45), _f(m, 3, 0.4))
		"glass":
			return LandmarkMaterials.glass(hex)
		"gold":
			return LandmarkMaterials.gold()
		"lit":
			return LandmarkMaterials.lit(hex, _f(m, 2, 0.6))
	return LandmarkMaterials.pbr(str(m[0]), hex, _f(m, 2, 4.0))

static func _pts(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in raw:
		out.append(Vector2(float((p as Array)[0]), float((p as Array)[1])))
	return out

static func _f(a: Array, i: int, fallback: float = 0.0) -> float:
	return float(a[i]) if a.size() > i else fallback
