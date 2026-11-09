class_name RoadGlyphs
extends RefCounted

## Painted symbols on the road: turn arrows from `turn:lanes` and bicycles
## in mapped bike lanes. Each is a few flat polygons in the paint layer's
## solid "marking" finish, so it wears and weathers as a stop line does.
##
## A glyph is drawn in its own frame: (across, along) in metres, across
## positive to the right of travel, along positive in the direction of
## travel, the tail at along 0.

## Arrow: length, shaft half width, head length and half width, and where
## a turn branches off the shaft.
const ARROW_LEN_M := 5.0
const SHAFT_HALF_M := 0.1
const HEAD_LEN_M := 1.7
const HEAD_HALF_M := 0.45
const BRANCH_AT_M := 2.2
const BRANCH_REACH_M := 1.5
const BRANCH_NECK_M := 0.8
## Arrow tails start this far back from the junction, clear of the apron,
## and move further back until the arrow is clear of any crossing or stop
## line by ARROW_CLEAR_M. A second arrow follows SECOND_GAP_M behind on a
## long approach.
const TAIL_BACK_M := 16.0
const ARROW_CLEAR_M := 2.0
const SEARCH_STEP_M := 2.0
const SEARCH_MAX_M := 70.0
const SECOND_GAP_M := 29.0
const MIN_LANE_M := 2.2
## Bicycles: spacing along a bike lane, and the clear stretch at each end.
const BIKE_EVERY_M := 45.0
const BIKE_END_CLEAR_M := 16.0
const BIKE_SIDE_INSET_M := 0.75

## The polygons of an arrow for a lane's `turns` (OsmTags.turn_lanes);
## empty for a lane with nothing painted on it.
static func arrow_parts(turns: Array) -> Array:
	var through := turns.has("through")
	var left := turns.has("left")
	var right := turns.has("right")
	var out: Array = []
	if not through and not left and not right:
		return out
	var hw := SHAFT_HALF_M
	if through:
		var neck := ARROW_LEN_M - HEAD_LEN_M
		out.append(PackedVector2Array([Vector2(-hw, 0.0), Vector2(hw, 0.0), Vector2(hw, neck),
			Vector2(HEAD_HALF_M, neck), Vector2(0.0, ARROW_LEN_M), Vector2(-HEAD_HALF_M, neck), Vector2(-hw, neck)]))
	else:
		out.append(PackedVector2Array([Vector2(-hw, 0.0), Vector2(hw, 0.0),
			Vector2(hw, BRANCH_AT_M + hw), Vector2(-hw, BRANCH_AT_M + hw)]))
	if left:
		out.append(_branch(-1.0))
	if right:
		out.append(_branch(1.0))
	return out

## An arm off the shaft, starting at its edge so nothing is painted twice.
static func _branch(s: float) -> PackedVector2Array:
	var hw := SHAFT_HALF_M
	var b := BRANCH_AT_M
	return PackedVector2Array([Vector2(s * hw, b - hw), Vector2(s * BRANCH_NECK_M, b - hw),
		Vector2(s * BRANCH_NECK_M, b - HEAD_HALF_M), Vector2(s * BRANCH_REACH_M, b),
		Vector2(s * BRANCH_NECK_M, b + HEAD_HALF_M), Vector2(s * BRANCH_NECK_M, b + hw), Vector2(s * hw, b + hw)])

## A bicycle seen from the side, front toward along +: [ring, hole] pairs,
## the hole empty for a solid part.
static func bike_parts() -> Array:
	var out: Array = []
	for along: float in [-0.55, 0.55]:
		out.append([_circle(Vector2(0.0, along), 0.3), _circle(Vector2(0.0, along), 0.22)])
	var seat := Vector2(0.28, -0.12)
	var bars := Vector2(0.32, 0.4)
	var crank := Vector2(0.0, 0.0)
	for bar: Array in [[Vector2(0.0, -0.55), seat], [seat, bars], [bars, Vector2(0.0, 0.55)],
			[Vector2(0.0, -0.55), crank], [crank, seat], [crank, bars]]:
		out.append([_bar(bar[0], bar[1], 0.035), PackedVector2Array()])
	return out

static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 14:
		var a := TAU * float(k) / 14.0
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out

static func _bar(a: Vector2, b: Vector2, hw: float) -> PackedVector2Array:
	var n := (b - a).normalized().orthogonal() * hw
	return PackedVector2Array([a + n, b + n, b - n, a - n])

## Offset (right of travel positive) of lane `k` of `count`, counted from
## the left, on a road `w` wide. A two-way road's lanes in this direction
## take the half its traffic drives on; `strips` is (left, right of travel)
## kept clear by parking. NAN when the lanes would be too narrow to mark.
static func lane_offset(w: float, k: int, count: int, oneway: bool, left_traffic: bool, strips: Vector2 = Vector2.ZERO) -> float:
	var lo := -w * 0.5 + strips.x
	var hi := w * 0.5 - strips.y
	if not oneway:
		if left_traffic:
			hi = minf(hi, 0.0)
		else:
			lo = maxf(lo, 0.0)
	var lane := (hi - lo) / float(maxi(count, 1))
	if lane < MIN_LANE_M:
		return NAN
	return lo + (float(k) + 0.5) * lane

## Metres from the start of `pts` to its end.
static func _length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	return total

## Point and travel direction `back` units before the end of `pts`.
static func _before_end(pts: PackedVector2Array, back: float) -> Array:
	var left := back
	for i in range(pts.size() - 1, 0, -1):
		var seg := pts[i - 1].distance_to(pts[i])
		if seg > 0.0 and left <= seg:
			var t := (pts[i] - pts[i - 1]) / seg
			return [pts[i] - t * left, t]
		left -= seg
	return []

## Adds the glyphs of `data`'s roads to `batches`; returns how many.
static func lay(batches: Dictionary, data: LocationData, surf: RoadBuilder._Surface, m2u: float,
		plan: RoadMarkings.Plan = null) -> int:
	var nodes := RoadSurface.carriageway_nodes(data)
	var painted := _paint_grid(plan, m2u)
	var lht := RoadSurface.left_traffic(data)
	var lift := RoadBuilder.lift_for_layer(RoadPaint.LAYER) * m2u
	var count := 0
	for line: Variant in data.roads:
		if not RoadPaint._paintable(line, surf, m2u) or not (line is Dictionary):
			continue
		var road: Dictionary = line
		var pts := RoadSurface._points(line)
		var oneway := int(road.get("oneway", 0))
		var travel := pts.duplicate()
		if oneway < 0:
			travel.reverse()
		var strips := RoadPaint.parking_strips(road)
		if oneway < 0:
			strips = Vector2(strips.y, strips.x)
		count += _approach(batches, travel, road.get("turn_forward", []), road, oneway != 0, lht, strips, nodes, surf, lift, m2u, painted)
		if oneway == 0:
			var back := pts.duplicate()
			back.reverse()
			count += _approach(batches, back, road.get("turn_backward", []), road, false, lht, Vector2(strips.y, strips.x), nodes, surf, lift, m2u, painted)
		count += _bikes(batches, pts, road, surf, lift, m2u)
	return count

## Crossing and stop-line paint bucketed: [a, b, half depth].
static func _paint_grid(plan: RoadMarkings.Plan, m2u: float) -> Dictionary:
	var grid := {}
	if plan == null:
		return grid
	for i: int in plan.by_road:
		var entry: Dictionary = plan.by_road[i]
		for run: PackedVector2Array in entry.get("runs", []):
			RoadMarkings._grid_add(grid, run[0], run[run.size() - 1],
				[run[0], run[run.size() - 1], float(entry["width_m"]) * m2u * 0.5], m2u)
	for stop: PackedVector2Array in plan.stops:
		RoadMarkings._grid_add(grid, stop[0], stop[stop.size() - 1],
			[stop[0], stop[stop.size() - 1], RoadMarkings.STOP_DEPTH_M * m2u * 0.5], m2u)
	for c: PackedVector2Array in plan.inferred:
		RoadMarkings._grid_add(grid, c[0], c[c.size() - 1],
			[c[0], c[c.size() - 1], RoadMarkings.INFERRED_DEPTH_M * m2u * 0.5], m2u)
	return grid

## Whether an arrow with its tail `back` before the end of `pts` keeps clear of `painted`.
static func _arrow_clear(pts: PackedVector2Array, back: float, painted: Dictionary, m2u: float) -> bool:
	var clear := ARROW_CLEAR_M * m2u
	var s := 0.0
	while s <= ARROW_LEN_M * m2u:
		var at := _before_end(pts, back - s)
		if at.is_empty():
			return false
		var p: Vector2 = at[0]
		for seg: Array in RoadMarkings._grid_near(painted, p, RoadMarkings.ON_ROAD_REACH_M * m2u, m2u):
			if Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) <= float(seg[2]) + clear:
				return false
		s += m2u
	return true

## Distances back from the end of `pts` of its arrows' tails: the nearest
## clear of other paint, and one more behind it on a long approach.
static func arrow_backs(pts: PackedVector2Array, painted: Dictionary, m2u: float) -> Array[float]:
	var out: Array[float] = []
	var length := _length(pts)
	var back := TAIL_BACK_M * m2u
	while back <= SEARCH_MAX_M * m2u and back <= length:
		if _arrow_clear(pts, back, painted, m2u):
			out.append(back)
			var second := back + SECOND_GAP_M * m2u
			if second <= length and _arrow_clear(pts, second, painted, m2u):
				out.append(second)
			break
		back += SEARCH_STEP_M * m2u
	return out

## The arrows of one direction of travel along `pts`, into a junction at its end.
static func _approach(batches: Dictionary, pts: PackedVector2Array, lanes: Array, road: Dictionary, oneway: bool, lht: bool,
		strips: Vector2, nodes: Dictionary, surf: RoadBuilder._Surface, lift: float, m2u: float, painted: Dictionary) -> int:
	if lanes.is_empty() or not nodes.has(RoadSurface.node_key(pts[pts.size() - 1])):
		return 0
	var backs := arrow_backs(pts, painted, m2u)
	var w := float(road.get("width_m", 0.0))
	var count := 0
	for back in backs:
		var at := _before_end(pts, back)
		if at.is_empty():
			continue
		for k in lanes.size():
			var offset := lane_offset(w, k, lanes.size(), oneway, lht, strips)
			if is_nan(offset):
				continue
			var parts := arrow_parts(lanes[k])
			for part: PackedVector2Array in parts:
				_place(batches, part, PackedVector2Array(), at[0], at[1], offset, surf, lift, m2u)
			count += 1 if not parts.is_empty() else 0
	return count

## Bicycles down each mapped bike lane, along the way's own direction.
static func _bikes(batches: Dictionary, pts: PackedVector2Array, road: Dictionary, surf: RoadBuilder._Surface, lift: float, m2u: float) -> int:
	var sides := int(road.get("cycle_lane", 0))
	if sides == 0:
		return 0
	var reversed := pts.duplicate()
	reversed.reverse()
	var w := float(road.get("width_m", 0.0))
	var strips := RoadPaint.parking_strips(road)
	var length := _length(pts)
	var count := 0
	var along := BIKE_END_CLEAR_M * m2u
	while along <= length - BIKE_END_CLEAR_M * m2u:
		var at := _before_end(pts, length - along)
		if not at.is_empty():
			for side: Array in [[1, -(w * 0.5 - strips.x - BIKE_SIDE_INSET_M)], [2, w * 0.5 - strips.y - BIKE_SIDE_INSET_M]]:
				if sides & int(side[0]):
					for part: Array in bike_parts():
						_place(batches, part[0], part[1], at[0], at[1], float(side[1]), surf, lift, m2u)
					count += 1
		along += BIKE_EVERY_M * m2u
	return count

## Lays one polygon of a glyph whose tail is `offset` across from `origin`.
static func _place(batches: Dictionary, ring: PackedVector2Array, hole: PackedVector2Array, origin: Vector2, travel: Vector2,
		offset: float, surf: RoadBuilder._Surface, lift: float, m2u: float) -> void:
	var holes: Array = []
	if not hole.is_empty():
		holes.append(_world(hole, origin, travel, offset, m2u))
	RoadBuilder._area(RoadBuilder._batch(batches, "marking"), _world(ring, origin, travel, offset, m2u), holes, surf,
		lift, m2u, RoadPaint.LAYER)

## A glyph polygon in world XZ.
static func _world(local: PackedVector2Array, origin: Vector2, travel: Vector2, offset: float, m2u: float) -> PackedVector2Array:
	# x east, z south: the right of travel.
	var right := Vector2(-travel.y, travel.x)
	var out := PackedVector2Array()
	out.resize(local.size())
	for i in local.size():
		out[i] = origin + right * ((local[i].x + offset) * m2u) + travel * (local[i].y * m2u)
	return out
