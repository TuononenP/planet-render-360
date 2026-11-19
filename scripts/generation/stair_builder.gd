class_name StairBuilder
extends RefCounted

## The stone flights StepsGround kept (GroundTruth.steps): `n` treads from
## the top node's level down to the foot's, each a solid block down to the
## ground under it, so a flight on a slope closes underneath. A tread is
## the paving of the way's own finish (RoadBuilder._material), its riser
## and flanks the same stone a few percent darker. Where the ground beside
## a flight stands more than CHEEK_MIN_M over a tread it gets a cheek wall
## of ashlar up to it, the retaining edge the post grid cannot draw; with
## `handrail` a rail runs along each side. A steps area (a polygon) is cut
## into n bands across its fall, each a slab at its tread height.
## RoadBuilder leaves these ways' ribbons out (skipped_roads).

## Ground this far over a tread, beside a flight, is walled up to (m).
const CHEEK_MIN_M := 0.4
const RAIL_M := 0.9
## A flank starts this far under the tread; deepest a flank is drawn (m).
const FLANK_MAX_M := 8.0
## The foot's last riser reaches the ground, at most this far (m).
const FOOT_MAX_M := 0.6
## A cheek stands on the ground this far beside the tread's edge (m).
const CHEEK_PROBE_M := 0.35
const RISER_TINT := 0.94
## Finishes a stair is laid in (the asphalt shader needs a ribbon's attributes).
const FINISHES: Array[String] = ["paving", "sett", "gravel"]

## Road indices whose ribbons the stairs replace.
static func skipped_roads(ground: GroundTruth) -> Dictionary:
	var out := {}
	for f: Dictionary in ground.steps:
		out[int(f["road"])] = true
	return out

## The ground the flights cover, as [ring, bounds]: a way's strip a little
## wider than its stair, an area's outline. A fence or wall mapped across
## one stops at it (StreetProps).
const FOOTPRINT_MARGIN_M := 0.3

static func footprints(ground: GroundTruth, m2u: float) -> Array:
	var out: Array = []
	for f: Dictionary in ground.steps:
		var rings: Array = []
		if bool(f["area"]):
			rings.append(f["ring"])
		else:
			var pts: PackedVector2Array = f["points"]
			var half := float(f["width"]) * 0.5 + FOOTPRINT_MARGIN_M * m2u
			for i in range(1, pts.size()):
				var seg := pts[i] - pts[i - 1]
				if seg.length() < 0.001:
					continue
				var side := seg.orthogonal().normalized() * half
				rings.append(PackedVector2Array([pts[i - 1] + side, pts[i] + side, pts[i] - side, pts[i - 1] - side]))
		for ring: PackedVector2Array in rings:
			out.append([ring, RingGeometry.aabb(ring)])
	return out

## True when `p` is on one of `footprints`.
static func covers(p: Vector2, footprints: Array) -> bool:
	for fp: Array in footprints:
		if (fp[1] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, fp[0]):
			return true
	return false

## Adds one "Stairs" mesh (a surface per material) to `root`.
static func lay(root: Node3D, data: LocationData, ground: GroundTruth, surf: RoadBuilder._Surface,
		m2u: float) -> void:
	if ground.steps.is_empty():
		return
	var kit := ReliefKit.new()
	var cheek: Material = QuayBuilder.stone_material(data)
	for f: Dictionary in ground.steps:
		var idx := int(f["road"])
		var finish := RoadBuilder.finish_of(data.roads[idx], surf, m2u) if idx < data.roads.size() else "paving"
		if not finish in FINISHES:
			finish = "paving"
		var tread := RoadBuilder._material(finish)
		var riser := _riser_material(finish, tread)
		if bool(f["area"]):
			_area(kit, ground, f, tread, riser, m2u)
		else:
			_way(kit, ground, f, tread, riser, cheek, m2u)
	kit.flush(root, "Stairs")

## `finish`'s material a few percent darker, for risers and flanks. Kept
## with RoadBuilder's own materials, which it rebuilds for each place.
static func _riser_material(finish: String, tread: Material) -> Material:
	var key := "riser_" + finish
	if RoadBuilder._mats.has(key):
		return RoadBuilder._mats[key] as Material
	var m := tread.duplicate() as Material
	if m is ShaderMaterial:
		var t: Variant = (m as ShaderMaterial).get_shader_parameter("tint")
		if t is Vector3:
			(m as ShaderMaterial).set_shader_parameter("tint", (t as Vector3) * RISER_TINT)
	RoadBuilder._mats[key] = m
	return m

# --- Ways ------------------------------------------------------------------

static func _way(kit: ReliefKit, ground: GroundTruth, f: Dictionary, tread: Material,
		riser: Material, cheek: Material, m2u: float) -> void:
	var pts: PackedVector2Array = f["points"]
	var n := maxi(int(f["n"]), 1)
	var y_top: float = f["y_top"]
	var y_bot: float = f["y_bot"]
	var rise := (y_top - y_bot) / float(n)
	var half := float(f["width"]) * 0.5
	var total := _length(pts)
	if total < 0.01 or pts.size() < 2:
		return
	var width_m := float(f["width"]) / m2u
	for j in range(1, n + 1):
		var s0 := total * float(j - 1) / float(n)
		var s1 := total * float(j) / float(n)
		var d := _dir(pts, (s0 + s1) * 0.5)
		var p0 := _at(pts, s0)
		var p1 := _at(pts, s1)
		var side := d.orthogonal() * half
		var yj := y_top - rise * float(j)
		var a_l := p0 + side
		var a_r := p0 - side
		var b_l := p1 + side
		var b_r := p1 - side
		kit.quad(tread, _v3(a_l, yj), _v3(a_r, yj), _v3(b_r, yj), _v3(b_l, yj), Vector3.UP,
			Vector2.ZERO, Vector2(width_m, p0.distance_to(p1) / m2u) * 0.25)
		# The downhill riser; the foot's last one reaches the ground.
		var yb := yj - rise
		if j == n:
			yb = clampf(ground.height_at_world((b_l.x + b_r.x) * 0.5, (b_l.y + b_r.y) * 0.5),
				yj - FOOT_MAX_M * m2u, yj - 0.02 * m2u)
		_face(kit, riser, b_l, yb, b_r, yb, yj, yj, Vector3(d.x, 0.0, d.y), m2u)
		if j == 1:
			var g := ground.height_at_world((a_l.x + a_r.x) * 0.5, (a_l.y + a_r.y) * 0.5)
			if g < yj - 0.02 * m2u:
				_face(kit, riser, a_r, maxf(g, yj - FOOT_MAX_M * m2u), a_l, maxf(g, yj - FOOT_MAX_M * m2u), yj, yj,
					Vector3(-d.x, 0.0, -d.y), m2u)
		# Flanks down to the ground, or a cheek up to it.
		for sign in [1.0, -1.0]:
			var out := d.orthogonal() * float(sign)
			var c0 := p0 + out * half
			var c1 := p1 + out * half
			var g0 := ground.height_at_world(c0.x, c0.y)
			var g1 := ground.height_at_world(c1.x, c1.y)
			if g0 < yj and g1 < yj:
				_face(kit, riser, c0, maxf(g0, yj - FLANK_MAX_M * m2u), c1, maxf(g1, yj - FLANK_MAX_M * m2u), yj, yj,
					Vector3(out.x, 0.0, out.y), m2u)
			var o0 := c0 + out * CHEEK_PROBE_M * m2u
			var o1 := c1 + out * CHEEK_PROBE_M * m2u
			var h0 := ground.height_at_world(o0.x, o0.y)
			var h1 := ground.height_at_world(o1.x, o1.y)
			if maxf(h0, h1) - yj > CHEEK_MIN_M * m2u:
				_face(kit, cheek, c0, yj, c1, yj, maxf(h0, yj), maxf(h1, yj), Vector3(-out.x, 0.0, -out.y), m2u)
	if bool(f["handrail"]):
		_rails(kit, f, half, total, m2u)

## A vertical quad over a→b between its feet (ya0, yb0) and tops (ya1, yb1).
static func _face(kit: ReliefKit, mat: Material, a: Vector2, ya0: float, b: Vector2, yb0: float,
		ya1: float, yb1: float, n: Vector3, m2u: float) -> void:
	if maxf(ya1 - ya0, yb1 - yb0) < 0.01 * m2u:
		return
	var run := a.distance_to(b) / m2u
	var rise := maxf(ya1 - ya0, yb1 - yb0) / m2u
	kit.quad(mat, _v3(a, ya0), _v3(b, yb0), _v3(b, yb1), _v3(a, ya1), n, Vector2.ZERO, Vector2(run, rise) * 0.25)

## A rail up the line of nosings on each side, the iron panel facing out.
static func _rails(kit: ReliefKit, f: Dictionary, half: float, total: float, m2u: float) -> void:
	var pts: PackedVector2Array = f["points"]
	var y_top: float = f["y_top"]
	var y_bot: float = f["y_bot"]
	var inset := half - 0.05 * m2u
	var s := 0.0
	for i in range(1, pts.size()):
		var seg := pts[i] - pts[i - 1]
		var len := seg.length()
		if len < 0.01:
			continue
		var out := seg.normalized().orthogonal()
		var ya := lerpf(y_top, y_bot, s / total)
		var yb := lerpf(y_top, y_bot, (s + len) / total)
		for sign in [1.0, -1.0]:
			var off := out * inset * float(sign)
			kit.rail(_v3(pts[i - 1] + off, ya), _v3(pts[i] + off, yb), RAIL_M * m2u,
				Vector3(out.x, 0.0, out.y) * float(sign))
		s += len

# --- Areas -----------------------------------------------------------------

## A steps area: n bands across its fall (the line top -> bottom of `f`),
## each a slab at its tread height with its outline walled to the ground.
static func _area(kit: ReliefKit, ground: GroundTruth, f: Dictionary, tread: Material,
		riser: Material, m2u: float) -> void:
	var line: PackedVector2Array = f["points"]
	var ring: PackedVector2Array = f["ring"]
	var n := maxi(int(f["n"]), 1)
	var y_top: float = f["y_top"]
	var rise := (y_top - float(f["y_bot"])) / float(n)
	var top := line[0]
	var run := line[1] - line[0]
	var total := run.length()
	if total < 0.01 or ring.size() < 3:
		return
	var d := run / total
	var across := d.orthogonal()
	var reach := (RingGeometry.aabb(ring).size.length() + 1.0) * 2.0
	for j in range(1, n + 1):
		var s0 := total * float(j - 1) / float(n)
		var s1 := total * float(j) / float(n)
		var band := PackedVector2Array([top + d * s0 - across * reach, top + d * s0 + across * reach,
			top + d * s1 + across * reach, top + d * s1 - across * reach])
		var yj := y_top - rise * float(j)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(ring, band):
			if Geometry2D.is_polygon_clockwise(piece) or piece.size() < 3:
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				kit.tri(tread, _v3(piece[idx[t]], yj), _v3(piece[idx[t + 1]], yj), _v3(piece[idx[t + 2]], yj), Vector3.UP)
			for k in piece.size():
				var a := piece[k]
				var b := piece[(k + 1) % piece.size()]
				var sa := (a - top).dot(d)
				var sb := (b - top).dot(d)
				var eps := 0.02 * m2u
				if absf(sa - s0) < eps and absf(sb - s0) < eps:
					continue
				var out := (b - a).normalized().orthogonal() * -1.0
				var foot := yj - rise
				if absf(sa - s1) < eps and absf(sb - s1) < eps:
					if j == n:
						foot = clampf(minf(ground.height_at_world(a.x, a.y), ground.height_at_world(b.x, b.y)),
							yj - FOOT_MAX_M * m2u, yj - 0.02 * m2u)
					_face(kit, riser, a, foot, b, foot, yj, yj, Vector3(out.x, 0.0, out.y), m2u)
					continue
				var ga := ground.height_at_world(a.x, a.y)
				var gb := ground.height_at_world(b.x, b.y)
				if ga < yj or gb < yj:
					_face(kit, riser, a, maxf(minf(ga, yj), yj - FLANK_MAX_M * m2u), b,
						maxf(minf(gb, yj), yj - FLANK_MAX_M * m2u), yj, yj, Vector3(out.x, 0.0, out.y), m2u)

# --- Geometry --------------------------------------------------------------

static func _v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)

static func _length(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in range(1, pts.size()):
		s += pts[i].distance_to(pts[i - 1])
	return s

## The point of `pts` at arc position `s` (clamped).
static func _at(pts: PackedVector2Array, s: float) -> Vector2:
	var run := 0.0
	for i in range(1, pts.size()):
		var len := pts[i].distance_to(pts[i - 1])
		if s <= run + len or i == pts.size() - 1:
			return pts[i - 1].lerp(pts[i], clampf((s - run) / maxf(len, 1e-9), 0.0, 1.0))
		run += len
	return pts[0]

## Unit direction of the segment of `pts` at arc position `s`.
static func _dir(pts: PackedVector2Array, s: float) -> Vector2:
	var run := 0.0
	for i in range(1, pts.size()):
		var len := pts[i].distance_to(pts[i - 1])
		if s <= run + len or i == pts.size() - 1:
			return (pts[i] - pts[i - 1]).normalized()
		run += len
	return Vector2.RIGHT
