class_name StepsGround
extends RefCounted

## Flights of steps for GroundTruth. OSM maps a stair (`highway=steps`, a
## way or a closed area) as a line or outline on the ground, and the
## elevation model records the drop as one smooth ramp: RoadBuilder laid a
## 2 m ribbon on it and the stair read as a slope. Here the stairs of a
## place are joined into systems (steps whose ends meet), each system gets
## the heights its flights really have, and the ground is held to them:
##
## - Levels. A system hangs from one anchor node: a node a street (rank 1+)
##   touches, else its highest. Each flight falls `step_count` risers
##   (RISER_M each; the DEM's difference without a count) from its top
##   node: `incline` (against the way's node order) says which that is, else
##   the DEM, clearly (else the flight is left alone). Only where the DEM
##   shows the drop (DEM_AGREE of it) is the ground dug to it: the 33 steps
##   from Henri IV's terrace come down to the park's level, six metres under
##   it. Where it cannot (the 7 steps round a statue's pedestal on a flat
##   plaza) the system hangs from its lowest node and rises, so no pit is
##   dug. A node never strays more than DEM_CLAMP_M under the DEM or
##   DEM_RISE_M over it (2.5 m: the 33 steps come down more than 2 m under
##   the smooth DEM at their foot), so a mistagged count digs no pit. A
##   ring of flights has no top and is left alone.
## - Ground. The posts under a flight (every corner of every cell its
##   footprint touches: a 9 m cell cannot carry a 2 m stair otherwise) come
##   down to the flight's line, a riser and CLEAR_M under the treads
##   StairBuilder draws on it, and never up. A node holds the ground round it
##   at the node's level, and a park or square at the foot of a system takes
##   the foot's level whole (the Square du Vert-Galant sits at quay level),
##   neither lifting a post more than HOLD_RAISE_M nor touching one under a
##   flight.
## - Left alone. Steps inside a landmark model's rect or stair cut (they
##   keep their own stairs), on a bridge, or in a system that touches one;
##   a system under MIN_SYSTEM_DROP_M and a flight under MIN_FLIGHT_DROP_M
##   keep the plain ribbon.
##
## The flights it kept go back to GroundTruth (`steps`), which StairBuilder
## and RoadBuilder read: a flight here is not drawn as a ribbon.

## Height of a riser a step count is taken at (m), and the steepest and
## shallowest a drawn flight keeps (outside them StairBuilder re-counts).
const RISER_M := 0.165
const MIN_RISER_M := 0.10
const MAX_RISER_M := 0.22
## Room kept between the ground and the treads' underside (LandmarkStairCut).
const CLEAR_M := 0.15
## Ends of steps this close are one node; a steps area's reach is its half width.
const MERGE_M := 0.5
const TOUCH_M := 1.0
## Ground within NODE_HOLD_M of a node takes its level, feathered over FEATHER_M.
const NODE_HOLD_M := 4.0
const FEATHER_M := 6.0
const MIN_SYSTEM_DROP_M := 0.5
const MIN_FLIGHT_DROP_M := 0.3
const MIN_RUN_M := 1.0
const DEM_CLAMP_M := 2.5
## ...and above it no more than this: a top is the terrace, and a ring of
## flights (the steps round a statue's pedestal) must not stack up a mound.
const DEM_RISE_M := 0.5
## A hold lifts no post more than this (a cell corner on a slope below a
## terrace made a pyramid when a stair's cells pulled it up to its line).
const HOLD_RAISE_M := 0.5
## Without an `incline` the DEM must show the flight's drop: its two ends
## apart by this much and by DEM_AGREE of what the step count says. A DEM
## blurred over a flat plaza cannot tell which end of the 7 steps round a
## statue's pedestal is the top, and a wrong guess digs a pit round it; a
## flight the DEM cannot place is left to its ribbon.
const MIN_DEM_STEP_M := 0.8
const DEM_AGREE := 0.4
## Drop of a flight with no step count: the DEM's, within these.
const DROP_RANGE_M := Vector2(0.2, 8.0)
## A park or square whose edge is this near a foot is levelled to it, when
## it is no larger than PARK_MAX_M2, its mean DEM is within PARK_SLACK_M
## of the span from the foot to the top, and the flight's top is no nearer
## it than the foot.
const PARK_REACH_M := 3.0
const PARK_MAX_M2 := 30000.0
const PARK_SLACK_M := 1.0
const PARK_ROADS: Array[String] = ["pedestrian", "footway"]
## A steps area needs at least this DEM slope to say which way it falls.
const AREA_MIN_SLOPE := 0.03
const AREA_SAMPLE_M := 2.0
const AREA_SAMPLES_MAX := 400
const CELL_M := 4.0
## Steps this close to a water body's edge are riverbank/quay stairs and are
## omitted so riverbanks keep a continuous wall instead of misaligned steps.
const SHORE_MARGIN_M := 3.0

## The loops that run over a whole place (the steps among the roads, the ways
## touching a stair's ends, the park levelling) run natively (StepsKernels,
## native/, tools/build_native.sh) when the library is loaded, with the same
## results as the script's below.
static var _native := ClassDB.class_exists("StepsKernels")

## One flight: its ends are nodes of the network.
class _Edge extends RefCounted:
	var road := 0
	var pts := PackedVector2Array()
	var ring := PackedVector2Array()
	var holes: Array = []
	var area := false
	var count := 0
	var incline := ""
	var handrail := false
	var width := 2.0
	var a := -1
	var b := -1
	var top := -1
	var drop := 0.0
	## The DEM shows at least DEM_AGREE of the drop between its ends.
	var agree := true
	var y_top := 0.0
	var y_bot := 0.0

## Steps' ends as merged nodes: positions, a lookup grid and union-find.
class _Net extends RefCounted:
	var pos := PackedVector2Array()
	var parent := PackedInt32Array()
	var cells := {}
	var grid := {}
	var cell := CELL_M
	var bridged := {}
	var anchor_rank := {}

	func _init(m2u: float) -> void:
		cell = CELL_M * m2u

	func key(p: Vector2) -> int:
		return (floori(p.x / cell) + 4096) * 8192 + floori(p.y / cell) + 4096

	## The node within `reach` (at most one cell) of p, else a new one.
	func node(p: Vector2, reach: float) -> int:
		var cx := floori(p.x / cell)
		var cz := floori(p.y / cell)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				for i: int in (cells.get((cx + dx + 4096) * 8192 + cz + dz + 4096, []) as Array):
					if pos[i].distance_to(p) <= reach:
						return i
		pos.append(p)
		parent.append(pos.size() - 1)
		var k := (cx + 4096) * 8192 + cz + 4096
		if not cells.has(k):
			cells[k] = []
		(cells[k] as Array).append(pos.size() - 1)
		return pos.size() - 1

	## Fills the lookup grid: each node in the cells its TOUCH_M box spans.
	func index(m2u: float) -> void:
		grid.clear()
		var r := TOUCH_M * m2u
		for i in pos.size():
			for cx in [pos[i].x - r, pos[i].x + r]:
				for cz in [pos[i].y - r, pos[i].y + r]:
					var k := key(Vector2(cx, cz))
					if not grid.has(k):
						grid[k] = []
					if not (grid[k] as Array).has(i):
						(grid[k] as Array).append(i)

	func find(i: int) -> int:
		while parent[i] != i:
			parent[i] = parent[parent[i]]
			i = parent[i]
		return i

	func union(i: int, j: int) -> void:
		parent[find(i)] = find(j)

## Ground heights of the stairs in `data`, holding `surface` (size x size
## posts, `step` units apart, source metres) to them. `level` marks carved
## water posts (-INF = dry), left alone. Returns the flights kept, in
## source metres: {road (index in data.roads), points (top to bottom),
## y_top, y_bot, n (risers), width, handrail, area, ring}.
static func apply(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		step: float, data: LocationData, m2u: float, shoreline: ShorelineModel = null) -> Array:
	if size < 2 or surface.size() != size * size:
		return []
	var edges := _edges(data, surface, size, step, m2u, shoreline)
	if edges.is_empty():
		return []
	var net := _Net.new(m2u)
	for e: _Edge in edges:
		var reach := MERGE_M * m2u + (minf(e.width * 0.5, 3.0 * m2u) if e.area else 0.0)
		e.a = net.node(e.pts[0], reach)
		e.b = net.node(e.pts[e.pts.size() - 1], reach)
		if e.a != e.b:
			net.union(e.a, e.b)
	_touch(data, net, m2u)
	var dem := PackedFloat32Array()
	for p in net.pos:
		dem.append(_sample(surface, size, step, p))
	var systems := {}
	for e: _Edge in edges:
		if e.a == e.b:
			continue
		var root := net.find(e.a)
		if not systems.has(root):
			systems[root] = []
		(systems[root] as Array).append(e)
	var kept: Array = []
	var node_level := {}
	for root in systems:
		_solve(systems[root], net, dem, kept, node_level)
	if kept.is_empty():
		return []
	# The posts under the flights keep to their lines (_lower): the park and
	# node holds leave them.
	var out: Array = []
	var feet: Array = []
	var under := {}
	for e: _Edge in kept:
		var flight := _flight(e, m2u)
		out.append(flight)
		feet.append(_footprint(size, step, flight))
		under.merge(feet[feet.size() - 1])
	_hold_parks(surface, level, size, step, data, kept, net, node_level, under, m2u)
	_hold_nodes(surface, level, size, step, net, node_level, under, m2u)
	for k in out.size():
		_lower(surface, level, size, step, out[k], feet[k])
	return out

## Every flight of steps in `data` the ground may take: a way or an area,
## on the ground (not a bridge, not below it), clear of landmark stairs and
## riverbank/quay edges.
static func _edges(data: LocationData, surface: PackedFloat32Array, size: int, step: float,
		m2u: float, shoreline: ShorelineModel = null) -> Array:
	var edges: Array = []
	var models := LandmarkSites.model_rect_sites(data)
	var table := LandmarkStairCut.stairs()
	var cuts := LandmarkTerrain._sites(data, table.keys())
	for i: int in _step_roads(data.roads):
		var road: Dictionary = data.roads[i]
		if bool(road.get("tunnel", false)) or bool(road.get("bridge", false)) or int(road.get("layer", 0)) < 0:
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		var is_area := bool(road.get("area", false))
		if pts.size() < (3 if is_area else 2):
			continue
		if _in_landmark(pts, models, cuts, table):
			continue
		if near_shore(pts, shoreline, m2u, is_area):
			continue
		var e: _Edge = null
		if is_area:
			e = _area_edge(road, surface, size, step, m2u)
		elif _length(pts) >= MIN_RUN_M * m2u:
			e = _Edge.new()
			e.pts = pts
			e.width = maxf(float(road.get("width_m", 2.0)) * m2u, 0.4)
		if e == null:
			continue
		e.road = i
		e.count = int(road.get("step_count", 0))
		e.handrail = bool(road.get("handrail", false))
		if not e.area:
			e.incline = str(road.get("incline", ""))
		edges.append(e)
	return edges

## Indices of the roads of class steps.
static func _step_roads(roads: Array) -> PackedInt32Array:
	if _native:
		return ClassDB.class_call_static("StepsKernels", "step_roads", roads)
	var out := PackedInt32Array()
	for i in roads.size():
		var r: Variant = roads[i]
		if r is Dictionary and str((r as Dictionary).get("class", "")) == "steps":
			out.append(i)
	return out

static func _length(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in range(1, pts.size()):
		s += pts[i].distance_to(pts[i - 1])
	return s

static func _in_landmark(pts: PackedVector2Array, models: Array, cuts: Array, table: Dictionary) -> bool:
	for p in pts:
		if not models.is_empty() and LandmarkSites.in_model_rects(p, models):
			return true
		for site: Array in cuts:
			var rect := LandmarkStairCut.rect_m(table[str(site[1]["type"])]).grow(LandmarkStairCut.FEATHER_M)
			if rect.has_point(LandmarkTerrain.local_xz(p, site)):
				return true
	return false

## True when polyline/ring `pts` enters a water body or comes within
## SHORE_MARGIN_M of a shoreline edge in `shoreline`.
static func near_shore(pts: PackedVector2Array, shoreline: ShorelineModel, m2u: float,
		closed: bool = false) -> bool:
	if shoreline == null or shoreline.empty() or pts.is_empty():
		return false
	for p in pts:
		if shoreline.domains.at(p) >= 0:
			return true
	var reach := SHORE_MARGIN_M * m2u
	var box := RingGeometry.aabb(pts).grow(reach + 0.05)
	var lo := shoreline.cell_at(box.position)
	var hi := shoreline.cell_at(box.end)
	var seg_count := pts.size() if closed else pts.size() - 1
	var seen := {}
	for cx in range(lo.x, hi.x + 1):
		for cz in range(lo.y, hi.y + 1):
			for eid: int in shoreline.edge_cells.get(Vector2i(cx, cz), []):
				if seen.has(eid):
					continue
				seen[eid] = true
				var edge: Dictionary = shoreline._edges[eid]
				var ea: Vector2 = edge["a"]
				var eb: Vector2 = edge["b"]
				if seg_count <= 0:
					if Geometry2D.get_closest_point_to_segment(pts[0], ea, eb).distance_to(pts[0]) <= reach:
						return true
				else:
					for i in seg_count:
						var hits := Geometry2D.get_closest_points_between_segments(
							pts[i], pts[(i + 1) % pts.size()], ea, eb)
						if hits[0].distance_to(hits[1]) <= reach:
							return true
	return false

## A steps area as a flight along its steepest line: the DEM plane over
## the polygon gives the way it falls; the line runs through its centre
## from the top edge to the bottom edge. Null when the DEM has no slope.
static func _area_edge(road: Dictionary, surface: PackedFloat32Array, size: int, step: float,
		m2u: float) -> _Edge:
	var ring: PackedVector2Array = road["points"]
	var box := RingGeometry.aabb(ring)
	var sp := maxf(AREA_SAMPLE_M * m2u, sqrt(box.size.x * box.size.y / float(AREA_SAMPLES_MAX)))
	var xs := PackedVector2Array()
	var hs := PackedFloat32Array()
	var x := box.position.x + sp * 0.5
	while x < box.end.x:
		var z := box.position.y + sp * 0.5
		while z < box.end.y:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), ring):
				xs.append(Vector2(x, z))
				hs.append(_sample(surface, size, step, Vector2(x, z)))
			z += sp
		x += sp
	if xs.size() < 3:
		return null
	var mean := Vector2.ZERO
	var mean_h := 0.0
	for k in xs.size():
		mean += xs[k]
		mean_h += hs[k]
	mean /= float(xs.size())
	mean_h /= float(xs.size())
	var sxx := 0.0
	var sxz := 0.0
	var szz := 0.0
	var sxh := 0.0
	var szh := 0.0
	for k in xs.size():
		var d := (xs[k] - mean) / m2u
		var dh := hs[k] - mean_h
		sxx += d.x * d.x
		sxz += d.x * d.y
		szz += d.y * d.y
		sxh += d.x * dh
		szh += d.y * dh
	var det := sxx * szz - sxz * sxz
	if absf(det) < 1e-9:
		return null
	var g := Vector2((sxh * szz - szh * sxz) / det, (szh * sxx - sxh * sxz) / det)
	if g.length() < AREA_MIN_SLOPE:
		return null
	var up := g.normalized()
	var across := up.orthogonal()
	var lo := INF
	var hi := -INF
	var w_lo := INF
	var w_hi := -INF
	for p in ring:
		var q := p - mean
		lo = minf(lo, q.dot(up))
		hi = maxf(hi, q.dot(up))
		w_lo = minf(w_lo, q.dot(across))
		w_hi = maxf(w_hi, q.dot(across))
	if hi - lo < MIN_RUN_M * m2u:
		return null
	var mid := mean + across * (w_lo + w_hi) * 0.5
	var e := _Edge.new()
	e.area = true
	e.ring = ring
	e.holes = road.get("holes", [])
	e.pts = PackedVector2Array([mid + up * hi, mid + up * lo])
	e.width = w_hi - w_lo
	e.incline = "down"
	return e

## Marks the nodes a road touches: a street (rank 1+) on the ground is an
## anchor candidate, a bridge makes its system a bridge's (left alone).
## Only the vertices in a node's cell are looked at.
static func _touch(data: LocationData, net: _Net, m2u: float) -> void:
	var reach := TOUCH_M * m2u
	if _native:
		var hits: Array = ClassDB.class_call_static("StepsKernels", "touch", data.roads, net.pos, net.cell, reach)
		var bridged: PackedByteArray = hits[0]
		for i in net.pos.size():
			if bridged[i] == 1:
				net.bridged[i] = true
			for cls: String in (hits[1][i] as PackedStringArray):
				var rank := RoadBuilder._rank(cls)
				if rank >= 1:
					net.anchor_rank[i] = maxi(int(net.anchor_rank.get(i, 0)), rank)
		return
	net.index(m2u)
	for w: Variant in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		if bool(d.get("area", false)) or bool(d.get("tunnel", false)) or str(d.get("class", "")) == "steps":
			continue
		var bridge := bool(d.get("bridge", false)) or int(d.get("layer", 0)) >= 1
		var rank := RoadBuilder._rank(str(d.get("class", "")))
		if rank < 1 and not bridge:
			continue
		for p in (d.get("points", PackedVector2Array()) as PackedVector2Array):
			var near: Variant = net.grid.get(net.key(p))
			if near == null:
				continue
			for i: int in (near as Array):
				if net.pos[i].distance_to(p) > reach:
					continue
				if bridge:
					net.bridged[i] = true
				else:
					net.anchor_rank[i] = maxi(int(net.anchor_rank.get(i, 0)), rank)

## One system's levels (BFS from its anchor) into `node_level`, its flights
## that stand into `kept` (with y_top, y_bot, drop).
static func _solve(edges: Array, net: _Net, dem: PackedFloat32Array, kept: Array,
		node_level: Dictionary) -> void:
	var adj := {}
	var total := 0.0
	var known: Array = []
	for e: _Edge in edges:
		if net.bridged.has(e.a) or net.bridged.has(e.b):
			return
		var a := dem[e.a]
		var b := dem[e.b]
		if e.incline == "" and absf(a - b) < maxf(MIN_DEM_STEP_M, DEM_AGREE * float(e.count) * RISER_M):
			continue
		known.append(e)
		e.top = e.a if (e.incline == "down" or (e.incline == "" and a >= b)) else e.b
		e.drop = float(e.count) * RISER_M if e.count > 0 else clampf(absf(a - b), DROP_RANGE_M.x, DROP_RANGE_M.y)
		e.agree = dem[e.top] - dem[e.b if e.top == e.a else e.a] >= DEM_AGREE * e.drop
		total += e.drop
		for n: int in [e.a, e.b]:
			if not adj.has(n):
				adj[n] = []
			(adj[n] as Array).append(e)
	if total < MIN_SYSTEM_DROP_M:
		return
	# A flight the DEM cannot place can split the system: each part is a
	# system of its own, with its own anchor and its own ring test.
	var parts := _parts(known)
	if parts.size() > 1:
		for part: Array in parts:
			_solve(part, net, dem, kept, node_level)
		return
	# A ring of flights (the steps round a statue's pedestal) has no top and
	# no foot: more distinct links than a tree has.
	var links := {}
	for e: _Edge in known:
		links[Vector2i(mini(e.a, e.b), maxi(e.a, e.b))] = true
	if links.size() >= adj.size():
		return
	edges = known
	# The anchor: the highest node a street touches, else the highest node,
	# when the DEM shows every flight's drop. Where it cannot (the 7 steps
	# round a pedestal on a flat plaza) nothing is dug: the system hangs from
	# its lowest node and rises from it.
	var agree := true
	for e: _Edge in known:
		agree = agree and e.agree
	var tops := {}
	for e: _Edge in known:
		tops[e.top] = true
	var anchor := -1
	for pass_i in 2:
		for n: int in adj:
			if pass_i == 0 and not net.anchor_rank.has(n):
				continue
			if anchor < 0:
				anchor = n
			elif agree:
				anchor = n if dem[n] > dem[anchor] else anchor
			# Lowest; on level ground the one that is no flight's top.
			elif dem[n] < dem[anchor] - 1e-4 or (absf(dem[n] - dem[anchor]) <= 1e-4 \
					and tops.has(anchor) and not tops.has(n)):
				anchor = n
		if anchor >= 0:
			break
	var level := {anchor: dem[anchor]}
	var queue: Array = [anchor]
	var head := 0
	while head < queue.size():
		var u: int = queue[head]
		head += 1
		for e: _Edge in adj[u]:
			var v := e.b if e.a == u else e.a
			if level.has(v) or (u == e.top and not e.agree):
				continue
			var lv: float = float(level[u]) - e.drop if u == e.top else float(level[u]) + e.drop
			level[v] = clampf(lv, dem[v] - DEM_CLAMP_M, dem[v] + DEM_RISE_M)
			queue.append(v)
	var stood: Array = []
	for e: _Edge in edges:
		if not (level.has(e.a) and level.has(e.b)):
			continue
		var bottom := e.b if e.top == e.a else e.a
		e.y_top = level[e.top]
		e.y_bot = level[bottom]
		if e.y_top - e.y_bot >= MIN_FLIGHT_DROP_M:
			stood.append(e)
	for e: _Edge in stood:
		kept.append(e)
		node_level[e.top] = float(level[e.top])
		node_level[e.b if e.top == e.a else e.a] = float(level[e.b if e.top == e.a else e.a])

## The connected parts of `edges` (flights joined at their nodes), in the
## order of their first flight.
static func _parts(edges: Array) -> Array:
	var root := {}
	var find := func(n: int) -> int:
		while int(root.get(n, n)) != n:
			n = int(root[n])
		return n
	for e: _Edge in edges:
		var ra: int = find.call(e.a)
		var rb: int = find.call(e.b)
		if ra != rb:
			root[ra] = rb
	var parts: Array = []
	var slot := {}
	for e: _Edge in edges:
		var r: int = find.call(e.a)
		if not slot.has(r):
			slot[r] = parts.size()
			parts.append([])
		(parts[slot[r]] as Array).append(e)
	return parts

## `e` as the dict GroundTruth keeps: points from the top node down.
static func _flight(e: _Edge, m2u: float) -> Dictionary:
	var pts := e.pts
	if e.top == e.b:
		pts = PackedVector2Array()
		for i in range(e.pts.size() - 1, -1, -1):
			pts.append(e.pts[i])
	var drop := e.y_top - e.y_bot
	var n := e.count
	if n <= 0 or drop / float(n) < MIN_RISER_M or drop / float(n) > MAX_RISER_M:
		n = maxi(roundi(drop / (RISER_M + 0.005)), 1)
	return {"road": e.road, "points": pts, "y_top": e.y_top, "y_bot": e.y_bot, "n": n,
		"width": e.width, "handrail": e.handrail, "area": e.area, "ring": e.ring, "holes": e.holes}

## Ground holds at a node's level: the feathered disc round it, for the
## posts that stand no more than HOLD_RAISE_M under it nor DEM_CLAMP_M over
## it, and are not under a flight.
static func _hold_nodes(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		step: float, net: _Net, node_level: Dictionary, under: Dictionary, m2u: float) -> void:
	var hs := float(size) * 0.5
	var reach := (NODE_HOLD_M + FEATHER_M) * m2u
	for n: int in node_level:
		var c := net.pos[n]
		for z in range(maxi(floori((c.y - reach) / step + hs), 0), mini(ceili((c.y + reach) / step + hs), size - 1) + 1):
			for x in range(maxi(floori((c.x - reach) / step + hs), 0), mini(ceili((c.x + reach) / step + hs), size - 1) + 1):
				var i := z * size + x
				# Only ground already near the node's level: the terrace a
				# stair comes down from is not cut to its foot.
				var rise: float = float(node_level[n]) - surface[i]
				if not is_inf(level[i]) or under.has(i) or rise > HOLD_RAISE_M or rise < -DEM_CLAMP_M:
					continue
				var d := Vector2((float(x) - hs) * step, (float(z) - hs) * step).distance_to(c) / m2u
				surface[i] = lerpf(surface[i], float(node_level[n]),
					1.0 - smoothstep(NODE_HOLD_M, NODE_HOLD_M + FEATHER_M, d))

## The posts a flight's footprint touches: all four corners of each cell it
## crosses (a post grid cannot carry a stair narrower than a cell otherwise).
static func _footprint(size: int, step: float, f: Dictionary) -> Dictionary:
	var pts: PackedVector2Array = f["points"]
	var half := float(f["width"]) * 0.5
	var hs := float(size) * 0.5
	var posts := {}
	var samples := PackedVector2Array()
	var stride := step * 0.4
	for i in range(1, pts.size()):
		var seg := pts[i] - pts[i - 1]
		var n := maxi(ceili(seg.length() / stride), 1)
		var side := seg.orthogonal().normalized() * half
		for k in n + 1:
			var c := pts[i - 1] + seg * (float(k) / float(n))
			samples.append(c)
			samples.append(c + side)
			samples.append(c - side)
	if bool(f["area"]):
		var ring: PackedVector2Array = f["ring"]
		var box := RingGeometry.aabb(ring)
		var x := box.position.x
		while x <= box.end.x:
			var z := box.position.y
			while z <= box.end.y:
				if Geometry2D.is_point_in_polygon(Vector2(x, z), ring):
					samples.append(Vector2(x, z))
				z += stride
			x += stride
		samples.append_array(ring)
	for s in samples:
		var fx := clampf(s.x / step + hs, 0.0, float(size - 1))
		var fz := clampf(s.y / step + hs, 0.0, float(size - 1))
		var x0 := mini(int(fx), size - 2)
		var z0 := mini(int(fz), size - 2)
		for dz in 2:
			for dx in 2:
				posts[(z0 + dz) * size + x0 + dx] = true
	return posts

## The footprint's posts (`posts`) come down to the line of the treads: a
## riser and CLEAR_M under them; those past an end to that end's level less
## CLEAR_M. Ground already lower stays: a flight never lifts it.
static func _lower(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		step: float, f: Dictionary, posts: Dictionary) -> void:
	var pts: PackedVector2Array = f["points"]
	var y_top: float = f["y_top"]
	var y_bot: float = f["y_bot"]
	var riser := (y_top - y_bot) / float(maxi(int(f["n"]), 1))
	var total := _length(pts)
	var hs := float(size) * 0.5
	for i: int in posts:
		if not is_inf(level[i]):
			continue
		var w := Vector2((float(i % size) - hs) * step, (float(i / size) - hs) * step)
		var hit := _along(pts, w)
		var target: float
		if hit.y > 0.5:
			target = (y_top if hit.y < 1.5 else y_bot) - CLEAR_M
		else:
			target = lerpf(y_top, y_bot, hit.x / maxf(total, 1e-6)) - riser - CLEAR_M
		surface[i] = minf(surface[i], target)

## (arc position, 0 on the line / 1 past its top end / 2 past its bottom end)
## of the point of `pts` nearest `p`.
static func _along(pts: PackedVector2Array, p: Vector2) -> Vector2:
	var best := INF
	var arc := 0.0
	var out := Vector2.ZERO
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var ab := pts[i] - a
		var len2 := maxf(ab.length_squared(), 1e-12)
		var raw := (p - a).dot(ab) / len2
		var t := clampf(raw, 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			var beyond := 0.0
			if i == 1 and raw < 0.0:
				beyond = 1.0
			elif i == pts.size() - 1 and raw > 1.0:
				beyond = 2.0
			out = Vector2(arc + sqrt(len2) * t, beyond)
		arc += sqrt(len2)
	return out

## The park or square at a system's foot takes the foot's level whole. Not
## the terrace a flight comes down from: a ring nearer the flight's top than
## its foot is left to the node holds.
static func _hold_parks(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		step: float, data: LocationData, kept: Array, net: _Net, node_level: Dictionary,
		under: Dictionary, m2u: float) -> void:
	# Feet: bottom nodes no kept flight comes down from.
	var tops := {}
	for e: _Edge in kept:
		tops[e.top] = true
	var feet: Array = []
	for e: _Edge in kept:
		var bottom := e.b if e.top == e.a else e.a
		if not tops.has(bottom):
			feet.append([bottom, e.y_bot, e.y_top, e.top])
	if feet.is_empty():
		return
	var rings: Array = []
	for poly: Variant in data.land_polygons:
		if poly is Dictionary and str((poly as Dictionary).get("class", "")) == "grass":
			rings.append(poly)
	for road: Variant in data.roads:
		if road is Dictionary and bool((road as Dictionary).get("area", false)) \
				and str((road as Dictionary).get("class", "")) in PARK_ROADS \
				and not bool((road as Dictionary).get("bridge", false)):
			rings.append(road)
	if _native:
		var foot_pos := PackedVector2Array()
		var top_pos := PackedVector2Array()
		var foot_levels := PackedFloat64Array()
		for foot: Array in feet:
			foot_pos.append(net.pos[int(foot[0])])
			top_pos.append(net.pos[int(foot[3])])
			foot_levels.append(float(foot[1]))
			foot_levels.append(float(foot[2]))
		var edits: Array = ClassDB.class_call_static("StepsKernels", "hold_parks", surface, level, size, step,
			rings, data.buildings, foot_pos, top_pos, foot_levels, PackedInt32Array(under.keys()),
			PARK_REACH_M * m2u, PARK_MAX_M2 * m2u * m2u, PARK_SLACK_M)
		var at: PackedInt32Array = edits[0]
		var heights: PackedFloat32Array = edits[1]
		for k in at.size():
			surface[at[k]] = heights[k]
		return
	var reach := PARK_REACH_M * m2u
	for poly: Dictionary in rings:
		var ring: PackedVector2Array = poly.get("points", PackedVector2Array())
		if ring.size() < 3 or RoadGrading._area(ring) > PARK_MAX_M2 * m2u * m2u:
			continue
		var box := RingGeometry.aabb(ring).grow(reach)
		var near: Array = []
		var mean := NAN
		var measured := false
		for foot: Array in feet:
			var c := net.pos[int(foot[0])]
			if not box.has_point(c):
				continue
			var gap := _ring_gap(c, ring)
			if gap > reach or _ring_gap(net.pos[int(foot[3])], ring) < gap:
				continue
			if not measured:
				near = _near_buildings(ring, step, data.buildings)
				mean = _mean_inside(surface, level, size, step, ring, near)
				measured = true
			if is_nan(mean) or mean < float(foot[1]) - PARK_SLACK_M or mean > float(foot[2]):
				continue
			_level_polygon(surface, level, size, step, ring, poly.get("holes", []), float(foot[1]), near, under)
			break

## From p to the ring: 0 inside it, else to its nearest edge.
static func _ring_gap(p: Vector2, ring: PackedVector2Array) -> float:
	return 0.0 if Geometry2D.is_point_in_polygon(p, ring) else RoadGrading._ring_distance(p, ring)

## The buildings whose footprint box reaches the posts round `ring`:
## [box (grown a post), footprint, courtyards] each.
static func _near_buildings(ring: PackedVector2Array, step: float, buildings: Array) -> Array:
	var box := RingGeometry.aabb(ring).grow(step * 2.0)
	var out: Array = []
	for b: Variant in buildings:
		if not (b is Dictionary):
			continue
		var fp: Variant = (b as Dictionary).get("footprint", PackedVector2Array())
		if not (fp is PackedVector2Array) or (fp as PackedVector2Array).size() < 3:
			continue
		var fbox := RingGeometry.aabb(fp).grow(step)
		if box.intersects(fbox, true):
			out.append([fbox, fp, (b as Dictionary).get("holes", [])])
	return out

## The mean height of the dry posts inside the ring and outside the
## buildings, NAN when there is none.
static func _mean_inside(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		step: float, ring: PackedVector2Array, near: Array) -> float:
	var hs := float(size) * 0.5
	var box := RingGeometry.aabb(ring)
	var sum := 0.0
	var n := 0
	for z in range(maxi(floori(box.position.y / step + hs), 0), mini(ceili(box.end.y / step + hs), size - 1) + 1):
		for x in range(maxi(floori(box.position.x / step + hs), 0), mini(ceili(box.end.x / step + hs), size - 1) + 1):
			var i := z * size + x
			if not is_inf(level[i]):
				continue
			var w := Vector2((float(x) - hs) * step, (float(z) - hs) * step)
			if Geometry2D.is_point_in_polygon(w, ring) and not _in_building(w, near):
				sum += surface[i]
				n += 1
	return sum / float(n) if n > 0 else NAN

## Posts inside `ring` (not its holes, water, a building or a flight) to
## `target` (lifted at most PARK_SLACK_M), those one post outside easing back
## to the ground. `near`: _near_buildings of the ring.
static func _level_polygon(surface: PackedFloat32Array, level: PackedFloat32Array, size: int,
		step: float, ring: PackedVector2Array, holes: Array, target: float, near: Array,
		under: Dictionary) -> void:
	var hs := float(size) * 0.5
	var box := RingGeometry.aabb(ring).grow(step)
	for z in range(maxi(floori(box.position.y / step + hs), 0), mini(ceili(box.end.y / step + hs), size - 1) + 1):
		for x in range(maxi(floori(box.position.x / step + hs), 0), mini(ceili(box.end.x / step + hs), size - 1) + 1):
			var i := z * size + x
			if not is_inf(level[i]) or under.has(i):
				continue
			var w := Vector2((float(x) - hs) * step, (float(z) - hs) * step)
			var weight := 1.0
			if not Geometry2D.is_point_in_polygon(w, ring):
				var d := RoadGrading._ring_distance(w, ring)
				if d >= step:
					continue
				weight = 1.0 - d / step
			elif _in_hole(w, holes):
				continue
			if _in_building(w, near):
				continue
			surface[i] = lerpf(surface[i], minf(target, surface[i] + PARK_SLACK_M), weight)

static func _in_hole(p: Vector2, holes: Array) -> bool:
	for h: Variant in holes:
		if h is PackedVector2Array and Geometry2D.is_point_in_polygon(p, h):
			return true
	return false

## In a building of `near` (_near_buildings), not in its courtyards.
static func _in_building(p: Vector2, near: Array) -> bool:
	for b: Array in near:
		if (b[0] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, b[1]) and not _in_hole(p, b[2]):
			return true
	return false

## Bilinear surface height at world XZ (source metres).
static func _sample(surface: PackedFloat32Array, size: int, step: float, p: Vector2) -> float:
	var fx := clampf(p.x / step + float(size) * 0.5, 0.0, float(size - 1))
	var fz := clampf(p.y / step + float(size) * 0.5, 0.0, float(size - 1))
	var x0 := mini(int(fx), size - 2)
	var z0 := mini(int(fz), size - 2)
	var a := lerpf(surface[z0 * size + x0], surface[z0 * size + x0 + 1], fx - float(x0))
	var b := lerpf(surface[(z0 + 1) * size + x0], surface[(z0 + 1) * size + x0 + 1], fx - float(x0))
	return lerpf(a, b, fz - float(z0))
