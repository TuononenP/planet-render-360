class_name TramRoute
extends RefCounted

## One run of tram track a tram can stand on (and later travel along):
## mapped tram ways joined end to end where they share a node, with an
## arc-length table over the joined line.
##
## The seam for motion: a train is nothing but an arc length `s` (metres
## from the route's start, 0 .. length_m). pose_at(s) is continuous in
## `s` (position along the line, heading from a chord around it, so a
## vertex turns the car over a metre instead of snapping it) and
## place_train(s, sections) turns one `s` into a transform per body
## section, each section's two supports (bogie centres, or the joint it
## shares with its neighbour) on the line and the body aimed along the
## chord between them. A mover only has to advance `s`.
##
## Tunnel ways never join a route; their ends are kept as `mouths` so
## placement can keep clear of them. Bridge ways join (the line carries
## on) and are flagged per segment.

## Ends within this join (metres); OSM ways share the node exactly, a
## merged extract may not.
const JOIN_M := 0.5
## Ways meeting at a sharper turn than this are a junction, not a line.
const MAX_TURN_DEG := 75.0
## Half length of the chord pose_at() takes its heading from (m).
const HEADING_M := 1.0

## The joined line, world XZ units.
var points := PackedVector2Array()
## Arc length at each point, world units (monotonic, cum[0] = 0).
var cum := PackedFloat32Array()
## The rail dict (OsmTags._rail_entry) of the segment after each point.
var ways: Array = []
## Rail-head height at each point where the track is not laid on the
## ground (a bridge deck), NAN elsewhere; empty when none is.
var heights := PackedFloat32Array()
var length_m := 0.0
var _m2u := 1.0
var _ground: GroundTruth

## Routes over `data`'s track that `carries` accepts (Callable(rail) ->
## bool; default: every tram way), longest first.
static func chains(data: LocationData, ground: GroundTruth, m2u: float,
		carries: Callable = Callable()) -> Array[TramRoute]:
	var lines: Array = []
	for r in data.railways:
		if not (r is Dictionary) or bool((r as Dictionary).get("tunnel", false)):
			continue
		var rail: Dictionary = r
		if carries.is_valid():
			if not bool(carries.call(rail)):
				continue
		elif str(rail.get("class", "")) != "tram":
			continue
		var pts: PackedVector2Array = rail.get("points", PackedVector2Array())
		if pts.size() >= 2:
			lines.append(rail)
	var tol := JOIN_M * m2u
	# Way ends by cell, [way index, at its tail end].
	var ends := {}
	for i in lines.size():
		var pts: PackedVector2Array = (lines[i] as Dictionary)["points"]
		for tail: bool in [false, true]:
			var cell := _cell(pts[pts.size() - 1] if tail else pts[0], tol)
			if not ends.has(cell):
				ends[cell] = []
			(ends[cell] as Array).append([i, tail])
	var used := {}
	var out: Array[TramRoute] = []
	for i in lines.size():
		if used.has(i):
			continue
		used[i] = true
		# Pieces as [way, reversed], in travel order.
		var pieces: Array = [[i, false]]
		for forward: bool in [true, false]:
			while true:
				var edge: Array = pieces[pieces.size() - 1] if forward else pieces[0]
				var pts: PackedVector2Array = (lines[int(edge[0])] as Dictionary)["points"]
				# The chain's open end and the direction it leaves by.
				var at_tail := forward != bool(edge[1])
				var tip := pts[pts.size() - 1] if at_tail else pts[0]
				var before := pts[pts.size() - 2] if at_tail else pts[1]
				var next := _continuation(lines, ends, used, tip, (tip - before).normalized(), tol)
				if next.is_empty():
					break
				used[int(next[0])] = true
				# Joined by its head it runs on as mapped; by its tail, reversed.
				var rev := bool(next[1])
				if forward:
					pieces.append([next[0], rev])
				else:
					pieces.insert(0, [next[0], not rev])
		var route := TramRoute.new()
		route._m2u = m2u
		route._ground = ground
		for piece: Array in pieces:
			var rail: Dictionary = lines[int(piece[0])]
			var pts: PackedVector2Array = rail["points"]
			if bool(piece[1]):
				pts = pts.duplicate()
				pts.reverse()
			for k in pts.size():
				if not route.points.is_empty() and pts[k].distance_to(route.points[route.points.size() - 1]) < 0.01 * m2u:
					continue
				if not route.points.is_empty():
					route.ways.append(rail)
				route.points.append(pts[k])
		if route.points.size() < 2:
			continue
		route.cum.append(0.0)
		for k in range(1, route.points.size()):
			route.cum.append(route.cum[k - 1] + route.points[k].distance_to(route.points[k - 1]))
		route.length_m = route.cum[route.cum.size() - 1] / m2u
		out.append(route)
	out.sort_custom(func(a: TramRoute, b: TramRoute) -> bool:
		return a.length_m > b.length_m)
	return out

## A route over the explicit line `line` (world XZ), `rails` holding the
## rail dict of the segment after each point: for a caller that walks
## the track itself (StationTrains, from a buffer stop back to the first
## switch) instead of joining whole ways. `ys` gives the rail-head
## height at the points on a bridge deck (NAN on the ground).
static func of(line: PackedVector2Array, rails: Array, ground: GroundTruth, m2u: float,
		ys: PackedFloat32Array = PackedFloat32Array()) -> TramRoute:
	var route := TramRoute.new()
	route._m2u = m2u
	route._ground = ground
	route.points = line
	route.ways = rails
	route.heights = ys
	route.cum.append(0.0)
	for k in range(1, line.size()):
		route.cum.append(route.cum[k - 1] + line[k].distance_to(line[k - 1]))
	route.length_m = route.cum[route.cum.size() - 1] / m2u
	return route

## Ends of the tunnel ways `carries` accepts (world XZ units): where
## track dives under.
static func mouths(data: LocationData, carries: Callable = Callable()) -> PackedVector2Array:
	var out := PackedVector2Array()
	for r in data.railways:
		if not (r is Dictionary) or not bool((r as Dictionary).get("tunnel", false)):
			continue
		var rail: Dictionary = r
		if carries.is_valid():
			if not bool(carries.call(rail)):
				continue
		elif str(rail.get("class", "")) != "tram":
			continue
		var pts: PackedVector2Array = rail.get("points", PackedVector2Array())
		if pts.size() >= 2:
			out.append(pts[0])
			out.append(pts[pts.size() - 1])
	return out

static func _cell(p: Vector2, tol: float) -> Vector2i:
	return Vector2i(floori(p.x / (tol * 2.0)), floori(p.y / (tol * 2.0)))

## The unused way that carries on straightest from `tip` (heading
## `dir`): [way index, joined at its tail end], or [].
static func _continuation(lines: Array, ends: Dictionary, used: Dictionary, tip: Vector2,
		dir: Vector2, tol: float) -> Array:
	var best: Array = []
	var best_dot := cos(deg_to_rad(MAX_TURN_DEG))
	var cell := _cell(tip, tol)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for e: Array in ends.get(cell + Vector2i(dx, dz), []):
				if used.has(int(e[0])):
					continue
				var pts: PackedVector2Array = (lines[int(e[0])] as Dictionary)["points"]
				var tail := bool(e[1])
				var at := pts[pts.size() - 1] if tail else pts[0]
				if at.distance_to(tip) > tol:
					continue
				var on := (pts[pts.size() - 2] if tail else pts[1]) - at
				var d := dir.dot(on.normalized())
				if d > best_dot:
					best_dot = d
					best = e
	return best

## Segment index holding arc length `u` (world units).
func _segment(u: float) -> int:
	var lo := 0
	var hi := cum.size() - 2
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if cum[mid] <= u:
			lo = mid
		else:
			hi = mid - 1
	return lo

## Point on the line at `s` metres (clamped to the route), world XZ.
func xz_at(s: float) -> Vector2:
	var u := clampf(s * _m2u, 0.0, cum[cum.size() - 1])
	var i := _segment(u)
	var span := cum[i + 1] - cum[i]
	return points[i].lerp(points[i + 1], (u - cum[i]) / span if span > 0.0 else 0.0)

## The rail dict under `s`.
func way_at(s: float) -> Dictionary:
	return ways[_segment(clampf(s * _m2u, 0.0, cum[cum.size() - 1]))]

## Rail-head height over the ground for `rail`, as RailBuilder lays it
## (metres): flush street rails, a cable car's concrete bed, or rails
## standing on ballast.
static func rail_lift_m(rail: Dictionary) -> float:
	if not bool(rail.get("embedded", false)):
		return RailBuilder.BED_LIFT_M + RailBuilder.RAIL_HEIGHT_M
	if bool(rail.get("cable", false)):
		return RoadBuilder.lift_for_layer(RailBuilder.CABLE_BED_LAYER) + RailBuilder.CABLE_RAIL_CLEAR_M
	return RailBuilder.STREET_RAIL_LIFT_M

## Point on the rail heads at `s` metres, world space.
func point_at(s: float) -> Vector3:
	var p := xz_at(s)
	if not heights.is_empty():
		var u := clampf(s * _m2u, 0.0, cum[cum.size() - 1])
		var i := _segment(u)
		if not is_nan(heights[i]) and not is_nan(heights[i + 1]):
			var span := cum[i + 1] - cum[i]
			return Vector3(p.x, lerpf(heights[i], heights[i + 1], (u - cum[i]) / span if span > 0.0 else 0.0), p.y)
	var y := _ground.height_at_world(p.x, p.y) if _ground != null else 0.0
	return Vector3(p.x, y + rail_lift_m(way_at(s)) * _m2u, p.y)

## Where a wheelset at `s` metres stands: origin on the rail heads, +X
## along the track (pitched with the grade), +Y up. Unscaled; continuous
## in `s`.
func pose_at(s: float) -> Transform3D:
	return _aim(point_at(s - HEADING_M), point_at(s + HEADING_M), point_at(s))

## Basis looking from `back` to `front`, standing at `origin`.
static func _aim(back: Vector3, front: Vector3, origin: Vector3) -> Transform3D:
	var forward := front - back
	if forward.length_squared() < 1e-10:
		forward = Vector3.RIGHT
	forward = forward.normalized()
	var side := forward.cross(Vector3.UP)
	if side.length_squared() < 1e-8:
		side = Vector3.BACK
	side = side.normalized()
	var up := side.cross(forward).normalized()
	return Transform3D(Basis(forward, up, forward.cross(up)), origin)

## One unscaled transform per body section of a train whose middle is at
## `s` metres. Each section is {"at": metres from the train's middle to
## the section's origin, "sup": Vector2(rear, front) support offsets
## along the section's own +X}; its supports are put on the line and
## the body aimed along the chord between them, so articulated sections
## follow a curve and neighbours meet at the joint they share.
func place_train(s: float, sections: Array) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for sec: Dictionary in sections:
		var sup: Vector2 = sec["sup"]
		var at := float(sec["at"])
		var rear := point_at(s + at + sup.x)
		var front := point_at(s + at + sup.y)
		var pose := _aim(rear, front, Vector3.ZERO)
		pose.origin = (rear + front) * 0.5 - pose.basis.x * (sup.x + sup.y) * 0.5
		out.append(pose)
	return out

## Arc length (metres) of the point on the route nearest `p` (world XZ)
## and its distance (metres): Vector2(s, distance).
func nearest(p: Vector2) -> Vector2:
	var best := INF
	var best_s := 0.0
	for i in points.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		var d := p.distance_squared_to(q)
		if d < best:
			best = d
			best_s = cum[i] + points[i].distance_to(q)
	return Vector2(best_s / _m2u, sqrt(best) / _m2u)

## Whether any track between `s0` and `s1` metres is on a bridge.
func bridged(s0: float, s1: float) -> bool:
	var i0 := _segment(clampf(s0 * _m2u, 0.0, cum[cum.size() - 1]))
	var i1 := _segment(clampf(s1 * _m2u, 0.0, cum[cum.size() - 1]))
	for i in range(i0, i1 + 1):
		if bool((ways[i] as Dictionary).get("bridge", false)):
			return true
	return false
