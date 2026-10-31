class_name PartyWalls
extends RefCounted

## Shared walls between abutting masses. OSM maps a city block as a row
## of parcels whose footprints share edges; extruded one by one, every
## parcel drew windows on its party walls and sloped its roof down to
## them, so a Paris block read as a row of detached pavilions. Built once
## per build from every real mass that will be extruded
## (BuildingMasses), this answers per wall edge which stretches a
## neighbour covers and how high that neighbour's wall stands: wall below
## the neighbour's top is never seen and is skipped, wall above a lower
## neighbour is a blank firewall, and roofs keep a vertical gable on party
## edges so neighbouring roofs run on as one street roof. It also answers
## whether an exposed edge faces a street (awnings, stoops, signs).

## Widest gap between two walls' lines still read as one shared wall (m).
const TOL_M := 0.8
## Minimum |cos| between the two walls' directions.
const PARALLEL := 0.96
## Shared stretches shorter than this are ignored; exposed slivers between
## two covered stretches narrower than GAP_M are closed (m).
const MIN_COVER_M := 0.6
const GAP_M := 0.9
## Share of an edge a neighbour must cover to make it a party edge.
const PARTY_SHARE := 0.6
## Road (centreline + half width) within this of a wall's foot: street front.
const STREET_M := 9.0
const CELL_M := 32.0
## Exposed piece marker in a partition (no neighbour).
const OPEN := -INF

var _edges := {}
var _edges_added := 0
var _roads := {}

## Index over every mass `accept(b)` keeps (the builder's own skip rules,
## so a removed landmark parcel never hides its neighbours' walls).
static func build(data: LocationData, ground: GroundTruth, ctx: Dictionary,
		accept: Callable = Callable()) -> PartyWalls:
	var pw := PartyWalls.new()
	for b in data.buildings:
		if not (b is Dictionary) or (accept.is_valid() and not bool(accept.call(b))):
			continue
		for m in BuildingMasses.plan(b, ctx):
			pw.add_mass(m, ground)
	for r in data.roads:
		var pts: Variant = r.get("points", null) if r is Dictionary else r
		if not (pts is PackedVector2Array):
			continue
		if r is Dictionary and bool((r as Dictionary).get("tunnel", false)):
			continue
		var hw := float((r as Dictionary).get("width_m", 8.0)) * 0.5 if r is Dictionary else 4.0
		var p := pts as PackedVector2Array
		for i in p.size() - 1:
			pw._insert(pw._roads, p[i], p[i + 1], [p[i], p[i + 1], hw * WorldScale.metres_to_units()])
	return pw

## Registers one planned mass: its outer edges face out, its courtyard
## edges face into the courtyard. A raised part (min_m > 0: arcade,
## overhang) has no wall from the ground up, so a neighbour must not be
## culled against it and is left unregistered.
func add_mass(m: Dictionary, ground: GroundTruth) -> void:
	if float(m.get("min_m", 0.0)) > 0.0:
		return
	var ring: PackedVector2Array = m["ring"]
	# Same base as BuildingBuilder._extrude_polygon: lowest of the centre
	# and the ring vertices, so the registered top is the extruded one.
	var centre: Vector2 = m.get("centre", RingGeometry.centroid(ring))
	var low := ground.height_at_world(centre.x, centre.y)
	for p in ring:
		low = minf(low, ground.height_at_world(p.x, p.y))
	var top := low + float(m["wall_m"]) * WorldScale.metres_to_units()
	_add_ring(ring, str(m["key"]), top, false)
	for h in m["holes"]:
		_add_ring(h as PackedVector2Array, str(m["key"]), top, true)

func _add_ring(ring: PackedVector2Array, key: String, top: float, hole: bool) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a.distance_to(b) < 0.01:
			continue
		_insert(_edges, a, b, [a, b, key, top, outward(ring, i, hole), _edges_added])
		_edges_added += 1

func _insert(grid: Dictionary, a: Vector2, b: Vector2, rec: Array) -> void:
	var c := CELL_M * WorldScale.metres_to_units()
	for ix in range(floori(minf(a.x, b.x) / c), floori(maxf(a.x, b.x) / c) + 1):
		for iz in range(floori(minf(a.y, b.y) / c), floori(maxf(a.y, b.y) / c) + 1):
			var k := Vector2i(ix, iz)
			if not grid.has(k):
				grid[k] = []
			(grid[k] as Array).append(rec)

## Outward unit normal of edge i (away from the building's material: into
## the courtyard for a hole ring), the convention BuildingWalls uses.
static func outward(ring: PackedVector2Array, i: int, hole: bool = false) -> Vector2:
	var e := ring[(i + 1) % ring.size()] - ring[i]
	var n := Vector2(e.y, -e.x).normalized() if RingGeometry.signed_area(ring) > 0.0 \
		else Vector2(-e.y, e.x).normalized()
	return -n if hole else n

## Per-edge partitions of `ring` (Array per edge, see partition()).
func ring_cover(ring: PackedVector2Array, key: String, hole: bool = false) -> Array:
	var out: Array = []
	for i in ring.size():
		out.append(partition(ring[i], ring[(i + 1) % ring.size()],
			outward(ring, i, hole), key))
	return out

## The edge a→b (outward normal n) split into [t0, t1, top_y] pieces over
## t in 0..1: top_y is the highest covering neighbour's wall top, OPEN
## where no neighbour stands against it.
func partition(a: Vector2, b: Vector2, n: Vector2, key: String) -> Array:
	var e := b - a
	var len2 := e.length_squared()
	var m := WorldScale.metres_to_units()
	if len2 < 0.0001:
		return [[0.0, 1.0, OPEN]]
	var tol := TOL_M * m
	var spans: Array = []
	var seen := {}
	var c := CELL_M * m
	for ix in range(floori((minf(a.x, b.x) - tol) / c), floori((maxf(a.x, b.x) + tol) / c) + 1):
		for iz in range(floori((minf(a.y, b.y) - tol) / c), floori((maxf(a.y, b.y) + tol) / c) + 1):
			for rec in _edges.get(Vector2i(ix, iz), []):
				# rec[5] is the record's id: an edge spans several cells.
				var rid: int = rec[5]
				if seen.has(rid) or str(rec[2]) == key:
					continue
				seen[rid] = true
				var on: Vector2 = rec[4]
				if on.dot(n) > -PARALLEL:
					continue
				var p0: Vector2 = rec[0]
				var p1: Vector2 = rec[1]
				if absf((p0 - a).dot(n)) > tol or absf((p1 - a).dot(n)) > tol:
					continue
				var t0 := clampf((p0 - a).dot(e) / len2, 0.0, 1.0)
				var t1 := clampf((p1 - a).dot(e) / len2, 0.0, 1.0)
				if absf(t1 - t0) * sqrt(len2) < MIN_COVER_M * m:
					continue
				spans.append([minf(t0, t1), maxf(t0, t1), float(rec[3])])
	if spans.is_empty():
		return [[0.0, 1.0, OPEN]]
	return _pieces(spans, sqrt(len2) / m)

## Elementary pieces over 0..1 from overlapping covers (highest top wins),
## with exposed slivers under GAP_M between covers closed.
static func _pieces(spans: Array, len_m: float) -> Array:
	var cuts := [0.0, 1.0]
	for s in spans:
		cuts.append(s[0])
		cuts.append(s[1])
	cuts.sort()
	var out: Array = []
	for i in cuts.size() - 1:
		var t0: float = cuts[i]
		var t1: float = cuts[i + 1]
		if t1 - t0 < 0.000001:
			continue
		var mid := (t0 + t1) * 0.5
		var top := OPEN
		for s in spans:
			if mid >= float(s[0]) and mid <= float(s[1]):
				top = maxf(top, float(s[2]))
		if not out.is_empty() and absf(float(out[-1][2]) - top) < 0.05 \
				or (not out.is_empty() and is_inf(top) and is_inf(float(out[-1][2]))):
			out[-1][1] = t1
		else:
			out.append([t0, t1, top])
	for i in range(1, out.size() - 1):
		if is_inf(float(out[i][2])) and not is_inf(float(out[i - 1][2])) \
				and not is_inf(float(out[i + 1][2])) \
				and (float(out[i][1]) - float(out[i][0])) * len_m < GAP_M:
			out[i][2] = minf(float(out[i - 1][2]), float(out[i + 1][2]))
	return out

## Party flags per edge (1 = a neighbour covers PARTY_SHARE of it) from
## ring_cover's output: roofs stand a gable there instead of a slope.
static func party_flags(cover: Array) -> PackedByteArray:
	var out := PackedByteArray()
	for pieces in cover:
		var covered := 0.0
		for p in pieces:
			if not is_inf(float(p[2])):
				covered += float(p[1]) - float(p[0])
		out.append(1 if covered >= PARTY_SHARE else 0)
	return out

## True when an exposed wall a→b (outward n) stands on a street: a road
## runs within STREET_M of its foot, measured from its midpoint.
func faces_street(a: Vector2, b: Vector2, n: Vector2) -> bool:
	var m := WorldScale.metres_to_units()
	var p := (a + b) * 0.5 + n * 1.5 * m
	var reach := STREET_M * m
	var c := CELL_M * m
	for ix in range(floori((p.x - reach) / c), floori((p.x + reach) / c) + 1):
		for iz in range(floori((p.y - reach) / c), floori((p.y + reach) / c) + 1):
			for rec in _roads.get(Vector2i(ix, iz), []):
				var q := Geometry2D.get_closest_point_to_segment(p, rec[0], rec[1])
				# The road must lie in front of the wall, not behind it.
				if q.distance_to(p) < reach + float(rec[2]) and (q - p).dot(n) > -1.0 * m:
					return true
	return false

static var _fire_mats: Dictionary = {}

## Blank firewall material for the wall a building shows above a lower
## neighbour: plain render, a weathered grey-beige (stone towns) or a
## dull brick (brick towns), no windows. One instance per finish, marked
## as a wall so WallVariety's per-building tint and foot shade reach it
## (the material count must not grow with the city, lod_test T7.2).
static func firewall(look: Dictionary) -> Material:
	var set_name := "brick" if str(look.get("wall_set", "")) == "brick" else "render"
	if _fire_mats.has(set_name):
		return _fire_mats[set_name] as Material
	var tint := Color(0.78, 0.72, 0.64) if set_name == "render" else Color(0.8, 0.8, 0.8)
	var m := (MaterialLibrary.pbr_material(set_name, tint) as StandardMaterial3D).duplicate() as StandardMaterial3D
	WallVariety.mark(m)
	_fire_mats[set_name] = m
	return m
