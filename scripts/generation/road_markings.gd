class_name RoadMarkings
extends RefCounted

## Junction surfaces and painted markings derived from the road network,
## laid as real geometry into RoadBuilder's batches. Nothing here is tied
## to a place: every rule reads OSM tags and the shape of the network.
##
## * Apron: one asphalt polygon under each junction, so overlapping
##   ribbons no longer leave wedges of ground in the carriageway.
## * Mapped crossings: their paint style (tags, else the country's habit)
##   and width. Mappers split one crossing into pieces, so width is
##   decided per collinear chain.
## * Inferred crossings: a zebra just beyond the apron on urban arms with
##   no mapped crossing near.
## * Scramble crossings: a ring of signalled crossings with one running
##   through the junction's centre (or crossing:scramble=yes) paints wide.
## * Stop lines: across the lanes arriving at a signalled crossing or a
##   signal node, on the driving side (RoadSurface.left_traffic).

## Junction nodes this near one seed are one junction (dual carriageways).
const CLUSTER_M := 18.0
## How far along each arm the apron reaches: past the widest arm's edge.
const MIN_SETBACK_M := 5.0
const SETBACK_PAD_M := 1.5
const APRON_LAYER := 2.9
const APRON_MAX_M2 := 3500.0
## A ring of crossings around a junction widens its apron to their ends.
const RING_REACH_M := 35.0
const RING_MIN := 3
const RING_MAX_GAP_RAD := 3.5
## A ring member's middle is at least this far from the junction centre.
const RING_MIN_MID_M := 8.0
## A diagonal passes this near the centre, its ends this far out.
const DIAGONAL_M := 6.0
const DIAGONAL_END_M := 8.0
const SCRAMBLE_WIDTH_M := 8.0
## Signalled crossing width from its length, bounded.
const SIGNAL_WIDTH_PER_M := 0.25
const SIGNAL_MAX_M := 6.0
## Pieces of one crossing line up within about 15 degrees.
const CHAIN_COS := 0.966
## An untagged crossing way with less of itself than this over a road is
## a pavement link, and stays unpainted.
const MIN_ON_ROAD := 0.15
const ON_ROAD_PAD_M := 0.5
const ON_ROAD_STEP_M := 2.0
## The widest road's half width: how far a sample looks for a road.
const ON_ROAD_REACH_M := 24.0
const MAPPED_NEAR_M := 12.0
const INFERRED_DEPTH_M := 3.2
const INFERRED_MIN_WIDTH_M := 5.0
const INFERRED_GAP_M := 0.5
const KERB_CLEAR_M := 0.3
const STOP_DEPTH_M := 0.45
const STOP_BACK_M := 2.0
## A road this near a crossing or signal node belongs to it.
const CONTACT_M := 1.5
const SIGNAL_CLEAR_M := 15.0
const ARRIVE_REACH_M := 40.0
const JUNCTION_SKIP_M := 3.0
const CELL_M := 24.0
const PAINT_GRID_M := 4.0

## What RoadBuilder lays: `by_road` {data.roads index: {finish, width_m}}
## for mapped crossings, the rest as geometry; `junctions` are the
## RoadSurface.junction_frac buckets for lane and kerb paint.
class Plan extends RefCounted:
	var by_road := {}
	var aprons: Array = []
	var inferred: Array = []
	var stops: Array = []
	var junctions := {}
	## Debug and test counters.
	var scrambles := 0

## The markings of `data`'s road network.
static func plan(data: LocationData, ground: GroundTruth) -> Plan:
	var out := Plan.new()
	var m := WorldScale.metres_to_units()
	out.junctions = RoadSurface.carriageway_junctions(data)
	var nodes := RoadSurface.carriageway_nodes(data)
	var car_grid := {}
	var at := {}
	for i in data.roads.size():
		var line: Variant = data.roads[i]
		if not RoadSurface.is_carriageway(line) or _elevated(line):
			continue
		var pts := RoadSurface._points(line)
		for j in pts.size():
			var k := RoadSurface.node_key(pts[j])
			if nodes.has(k):
				if not at.has(k):
					at[k] = []
				(at[k] as Array).append([i, j])
			if j + 1 < pts.size():
				_grid_add(car_grid, pts[j], pts[j + 1], [i, j], m)
	var marked_grid := _mapped_grid(data, m)
	var chains := _chains(data, _pavement_links(out, data, m))
	var clusters := _clusters(nodes, at, data, m)
	var centres := {}
	var buildings := _building_grid(data, m)
	for c: Dictionary in clusters:
		var centre: Vector2 = c["centre"]
		var cell := _cell(centre, ARRIVE_REACH_M * m)
		if not centres.has(cell):
			centres[cell] = PackedVector2Array()
		var arr: PackedVector2Array = centres[cell]
		arr.append(centre)
		centres[cell] = arr
		_lay_out_cluster(out, c, chains, buildings, ground, marked_grid, m)
	_assign_crossings(out, data, chains)
	_stop_lines(out, data, chains, car_grid, centres, m)
	return out

## Adds the plan to `batches`, the finished RoadBuilder ribbons alongside.
static func lay(p: Plan, batches: Dictionary, surf: RoadBuilder._Surface, m2u: float) -> void:
	for ring: PackedVector2Array in p.aprons:
		RoadBuilder._area(RoadBuilder._batch(batches, "asphalt"), ring, [], surf,
			RoadBuilder.lift_for_layer(APRON_LAYER) * m2u, m2u, APRON_LAYER)
	for c: PackedVector2Array in p.inferred:
		_across(batches, "crossing", c, INFERRED_DEPTH_M * m2u, surf, m2u)
	for s: PackedVector2Array in p.stops:
		_across(batches, "marking", s, STOP_DEPTH_M * m2u, surf, m2u)

static func _across(batches: Dictionary, finish: String, pts: PackedVector2Array, width: float,
		surf: RoadBuilder._Surface, m2u: float) -> void:
	var layer := RoadBuilder.CROSSING_LAYER
	var dense := RoadBuilder._resample(pts, surf.step * 0.34)
	for run: PackedVector2Array in RoadBuilder._dry_runs(dense, surf):
		RoadBuilder._ribbon(RoadBuilder._batch(batches, finish), RoadBuilder._straighten(run, surf.step),
			width, surf, RoadBuilder.lift_for_layer(layer) * m2u, Color(0.0, 0.0, 0.0, 1.0), {}, layer)

static func _elevated(line: Variant) -> bool:
	if not (line is Dictionary):
		return false
	var r: Dictionary = line
	return bool(r.get("bridge", false)) or int(r.get("layer", 0)) != 0

static func _width(line: Variant, m: float) -> float:
	return (float((line as Dictionary).get("width_m", 6.8)) if line is Dictionary else 6.8) * m

## Mapped crossing ways, painted or not (an unmarked one still says no
## zebra belongs there): grid of their segments.
static func _mapped_grid(data: LocationData, m: float) -> Dictionary:
	var grid := {}
	for line: Variant in data.roads:
		if not (line is Dictionary) or str((line as Dictionary).get("crossing_style", "")) == "":
			continue
		var pts := RoadSurface._points(line)
		for j in pts.size() - 1:
			_grid_add(grid, pts[j], pts[j + 1], [pts[j], pts[j + 1]], m)
	return grid

## Anything vehicles drive on, service roads included.
static func _drivable(line: Variant) -> bool:
	if RoadSurface.is_carriageway(line):
		return true
	if not (line is Dictionary):
		return false
	var r: Dictionary = line
	return str(r.get("class", "")) == "service" and str(r.get("crossing_style", "")) == "" \
		and not bool(r.get("area", false)) and not bool(r.get("tunnel", false))

## Plain surface for footway=crossing ways that say nothing else and lie
## on no road: mappers also use the tag for links across a plaza.
## Returns their data.roads indices as a set.
static func _pavement_links(out: Plan, data: LocationData, m: float) -> Dictionary:
	var links := {}
	var grid := {}
	for line: Variant in data.roads:
		if _drivable(line):
			var pts := RoadSurface._points(line)
			var half := _width(line, m) * 0.5 + ON_ROAD_PAD_M * m
			for j in pts.size() - 1:
				_grid_add(grid, pts[j], pts[j + 1], [pts[j], pts[j + 1], half], m)
	for i in data.roads.size():
		var line: Variant = data.roads[i]
		if not (line is Dictionary):
			continue
		var road: Dictionary = line
		if not bool(road.get("crossing", false)) or bool(road.get("crossing_signal", false)) \
				or str(road.get("crossing_style", "")) != "auto":
			continue
		var pts := RoadSurface._points(line)
		if pts.size() >= 2 and _on_road_share(pts, grid, m) < MIN_ON_ROAD:
			links[i] = true
			out.by_road[i] = {"finish": RoadBuilder._finish(str(road.get("class", "")), str(road.get("surface", "")).to_lower()),
				"width_m": float(road.get("width_m", 0.0))}
	return links

static func _on_road_share(pts: PackedVector2Array, grid: Dictionary, m: float) -> float:
	var total := 0
	var hits := 0
	for j in pts.size() - 1:
		var n := maxi(1, ceili(pts[j].distance_to(pts[j + 1]) / (ON_ROAD_STEP_M * m)))
		for k in n:
			var p := pts[j].lerp(pts[j + 1], (float(k) + 0.5) / float(n))
			total += 1
			for seg: Array in _grid_near(grid, p, ON_ROAD_REACH_M * m, m):
				if Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) <= float(seg[2]):
					hits += 1
					break
	return float(hits) / float(maxi(total, 1))

## Crossing ways joined where they share an end and run on in line:
## [{roads, segs, length, signal, scramble}]; `skip` holds roads to leave out.
static func _chains(data: LocationData, skip: Dictionary = {}) -> Array:
	var ways: Array = []
	var ends := {}
	for i in data.roads.size():
		var line: Variant = data.roads[i]
		if not (line is Dictionary) or not bool((line as Dictionary).get("crossing", false)) or skip.has(i):
			continue
		var pts := RoadSurface._points(line)
		if pts.size() < 2:
			continue
		var id := ways.size()
		ways.append(i)
		for k: Vector2i in [RoadSurface.node_key(pts[0]), RoadSurface.node_key(pts[pts.size() - 1])]:
			if not ends.has(k):
				ends[k] = PackedInt32Array()
			var arr: PackedInt32Array = ends[k]
			arr.append(id)
			ends[k] = arr
	var parent := PackedInt32Array()
	parent.resize(ways.size())
	for i in ways.size():
		parent[i] = i
	for k: Vector2i in ends:
		var ids: PackedInt32Array = ends[k]
		for a in ids.size():
			for b in range(a + 1, ids.size()):
				if _in_line(RoadSurface._points(data.roads[ways[ids[a]]]),
						RoadSurface._points(data.roads[ways[ids[b]]]), k):
					parent[_find(parent, ids[a])] = _find(parent, ids[b])
	var groups := {}
	for i in ways.size():
		var root := _find(parent, i)
		if not groups.has(root):
			groups[root] = {"roads": PackedInt32Array(), "segs": [], "length": 0.0,
				"signal": false, "scramble": false}
		var chain: Dictionary = groups[root]
		var road: Dictionary = data.roads[ways[i]]
		var members: PackedInt32Array = chain["roads"]
		members.append(ways[i])
		chain["roads"] = members
		var pts := RoadSurface._points(road)
		for j in pts.size() - 1:
			(chain["segs"] as Array).append([pts[j], pts[j + 1]])
			chain["length"] = float(chain["length"]) + pts[j].distance_to(pts[j + 1])
		chain["signal"] = bool(chain["signal"]) or bool(road.get("crossing_signal", false))
		chain["scramble"] = bool(chain["scramble"]) or bool(road.get("crossing_scramble", false))
	return groups.values()

## True when the two ways leave `at` in opposite directions (one line).
static func _in_line(a: PackedVector2Array, b: PackedVector2Array, at: Vector2i) -> bool:
	return _out_dir(a, at).dot(_out_dir(b, at)) <= -CHAIN_COS

static func _out_dir(pts: PackedVector2Array, at: Vector2i) -> Vector2:
	if RoadSurface.node_key(pts[0]) == at:
		return (pts[1] - pts[0]).normalized()
	return (pts[pts.size() - 2] - pts[pts.size() - 1]).normalized()

static func _find(parent: PackedInt32Array, i: int) -> int:
	var r := i
	while parent[r] != r:
		r = parent[r]
	while parent[i] != r:
		var next := parent[i]
		parent[i] = r
		i = next
	return r

## Junction nodes grouped around a seed within CLUSTER_M; a cluster's
## extent is bounded so a dense street grid never chains into one blob.
static func _clusters(nodes: Dictionary, at: Dictionary, data: LocationData, m: float) -> Array:
	var seeds := {}
	var out: Array = []
	var radius := CLUSTER_M * m
	var keys: Array = at.keys()
	keys.sort()
	for k: Vector2i in keys:
		var p := Vector2(k) / RoadSurface.NODE_SNAP
		var cell := _cell(p, radius)
		var best := -1
		var best_d := radius
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var near: Variant = seeds.get(cell + Vector2i(dx, dz), null)
				if near == null:
					continue
				for id: int in (near as PackedInt32Array):
					var d: float = (out[id]["seed"] as Vector2).distance_to(p)
					if d < best_d:
						best_d = d
						best = id
		if best < 0:
			best = out.size()
			out.append({"seed": p, "points": PackedVector2Array(), "keys": []})
			var arr: PackedInt32Array = seeds.get(cell, PackedInt32Array())
			arr.append(best)
			seeds[cell] = arr
		var c: Dictionary = out[best]
		var pa: PackedVector2Array = c["points"]
		pa.append(p)
		c["points"] = pa
		(c["keys"] as Array).append(k)
	for c: Dictionary in out:
		var sum := Vector2.ZERO
		var pts: PackedVector2Array = c["points"]
		for p in pts:
			sum += p
		c["centre"] = sum / float(pts.size())
		c["arms"] = _arms(c, nodes, at, data, m)
	return out

## Every way leaving the cluster's nodes:
## [{road, pts, j, dir, width, length, line}].
static func _arms(cluster: Dictionary, nodes: Dictionary, at: Dictionary, data: LocationData, m: float) -> Array:
	var arms: Array = []
	for k: Vector2i in cluster["keys"]:
		for entry: Array in at[k]:
			var i: int = entry[0]
			var j: int = entry[1]
			var pts := RoadSurface._points(data.roads[i])
			for way_dir: int in [1, -1]:
				if j + way_dir < 0 or j + way_dir >= pts.size():
					continue
				arms.append({"road": i, "pts": pts, "j": j, "dir": way_dir, "line": data.roads[i],
					"width": _width(data.roads[i], m), "length": _arm_length(pts, j, way_dir, nodes, k)})
	return arms

## Length of the way from vertex j to the next junction node or its end.
static func _arm_length(pts: PackedVector2Array, j: int, way_dir: int, nodes: Dictionary, start: Vector2i) -> float:
	var total := 0.0
	var i := j
	while i + way_dir >= 0 and i + way_dir < pts.size():
		total += pts[i].distance_to(pts[i + way_dir])
		i += way_dir
		var k := RoadSurface.node_key(pts[i])
		if k != start and nodes.has(k):
			break
	return total

## Point and outward tangent `dist` along an arm (clamped to its way).
static func _along(pts: PackedVector2Array, j: int, way_dir: int, dist: float) -> Array:
	var left := dist
	var i := j
	while i + way_dir >= 0 and i + way_dir < pts.size():
		var a := pts[i]
		var b := pts[i + way_dir]
		var seg := a.distance_to(b)
		var t := (b - a) / maxf(seg, 0.0001)
		if left <= seg or i + way_dir * 2 < 0 or i + way_dir * 2 >= pts.size():
			return [a + t * minf(left, seg), t]
		left -= seg
		i += way_dir
	return [pts[j], Vector2.RIGHT]

## The apron, scramble test and inferred crossings of one junction.
static func _lay_out_cluster(out: Plan, c: Dictionary, chains: Array, buildings: Dictionary,
		ground: GroundTruth, mapped: Dictionary, m: float) -> void:
	var arms: Array = c["arms"]
	if arms.size() < 3:
		return
	var centre: Vector2 = c["centre"]
	var setback := MIN_SETBACK_M * m
	for a: Dictionary in arms:
		setback = maxf(setback, float(a["width"]) * 0.5 + SETBACK_PAD_M * m)
	var edge := PackedVector2Array()
	for a: Dictionary in arms:
		var at: Array = _along(a["pts"], a["j"], a["dir"], minf(setback, float(a["length"])))
		var p: Vector2 = at[0]
		var t: Vector2 = at[1]
		var side := Vector2(t.y, -t.x) * float(a["width"]) * 0.5
		edge.append(p + side)
		edge.append(p - side)
	var ring := _ring(chains, centre, m)
	var with_ring := edge.duplicate()
	for chain: Dictionary in ring["ring"] + ring["diagonals"]:
		for seg: Array in chain["segs"]:
			with_ring.append(seg[0])
			with_ring.append(seg[1])
	var hull := _apron(with_ring, buildings, ground, m)
	if hull.is_empty() and with_ring.size() != edge.size():
		hull = _apron(edge, buildings, ground, m)
	if not hull.is_empty():
		out.aprons.append(hull)
	# Lane paint stops at the ring even where a kiosk inside denies it the apron.
	var clear := Geometry2D.convex_hull(with_ring) if with_ring.size() != edge.size() else hull
	if not clear.is_empty():
		_paint_points(out.junctions, clear, m)
	var tagged := false
	for chain: Dictionary in ring["ring"] + ring["diagonals"]:
		tagged = tagged or bool(chain["scramble"])
	if tagged or ((ring["ring"] as Array).size() >= RING_MIN and not (ring["diagonals"] as Array).is_empty()):
		out.scrambles += 1
		for chain: Dictionary in ring["ring"] + ring["diagonals"]:
			chain["scramble_cluster"] = true
	_infer_crossings(out, arms, centre, setback, ground, mapped, m)

## Crossing chains around `centre`: {"ring": [...], "diagonals": [...]};
## the ring is empty unless it really encloses the junction.
static func _ring(chains: Array, centre: Vector2, m: float) -> Dictionary:
	var ring: Array = []
	var diagonals: Array = []
	var reach := RING_REACH_M * m
	for chain: Dictionary in chains:
		var nearest := INF
		var sum := Vector2.ZERO
		var count := 0
		var segs: Array = chain["segs"]
		for s: Array in segs:
			var a: Vector2 = s[0]
			var b: Vector2 = s[1]
			nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre))
			sum += a + b
			count += 2
		if nearest > reach:
			continue
		var mid := sum / float(count)
		var far_a := _farthest(segs, centre)
		var oa := far_a - centre
		var ob := _farthest(segs, far_a) - centre
		if nearest <= DIAGONAL_M * m and oa.length() >= DIAGONAL_END_M * m and ob.length() >= DIAGONAL_END_M * m \
				and oa.normalized().dot(ob.normalized()) < -0.5:
			diagonals.append(chain)
		elif mid.distance_to(centre) >= RING_MIN_MID_M * m:
			ring.append(chain)
	if ring.size() < RING_MIN:
		return {"ring": [], "diagonals": diagonals}
	var angles: Array[float] = []
	for chain: Dictionary in ring:
		var sum := Vector2.ZERO
		var segs: Array = chain["segs"]
		for s: Array in segs:
			sum += (s[0] as Vector2) + (s[1] as Vector2)
		var d := sum / float(segs.size() * 2) - centre
		angles.append(atan2(d.y, d.x))
	angles.sort()
	var gap := angles[0] + TAU - angles[angles.size() - 1]
	for i in range(1, angles.size()):
		gap = maxf(gap, angles[i] - angles[i - 1])
	if gap > RING_MAX_GAP_RAD:
		return {"ring": [], "diagonals": diagonals}
	return {"ring": ring, "diagonals": diagonals}

## The chain's vertex farthest from `from`.
static func _farthest(segs: Array, from: Vector2) -> Vector2:
	var best: Vector2 = segs[0][0]
	for s: Array in segs:
		for p: Vector2 in s:
			if p.distance_to(from) > best.distance_to(from):
				best = p
	return best

## Convex hull of `pts` as an open counter-clockwise ring, or empty when
## it is too big, wet, or would pave a building.
static func _apron(pts: PackedVector2Array, buildings: Dictionary, ground: GroundTruth, m: float) -> PackedVector2Array:
	var hull := Geometry2D.convex_hull(pts)
	if hull.size() >= 2 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.resize(hull.size() - 1)
	if hull.size() < 3:
		return PackedVector2Array()
	var area := 0.0
	for i in hull.size():
		area += hull[i].cross(hull[(i + 1) % hull.size()])
	if absf(area) * 0.5 > APRON_MAX_M2 * m * m:
		return PackedVector2Array()
	for p in hull:
		if ground.water_at(p.x, p.y) > 0.0:
			return PackedVector2Array()
	var lo := hull[0]
	var hi := hull[0]
	for p in hull:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var c0 := _cell(lo, CELL_M * m)
	var c1 := _cell(hi, CELL_M * m)
	for x in range(c0.x, c1.x + 1):
		for z in range(c0.y, c1.y + 1):
			for b: PackedVector2Array in buildings.get(Vector2i(x, z), []):
				if not Geometry2D.intersect_polygons(hull, b).is_empty():
					return PackedVector2Array()
	return hull

## Building footprints bucketed for the apron overlap test.
static func _building_grid(data: LocationData, m: float) -> Dictionary:
	var grid := {}
	for raw: Variant in data.buildings:
		if not (raw is Dictionary):
			continue
		var b: Dictionary = raw
		var ring: PackedVector2Array
		if b.get("footprint", null) is PackedVector2Array and (b["footprint"] as PackedVector2Array).size() >= 3:
			ring = b["footprint"]
		else:
			var c := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
			var h := Vector2(float(b.get("size_x", 8.0)), float(b.get("size_z", 8.0))) * 0.5
			ring = PackedVector2Array([c - h, c + Vector2(h.x, -h.y), c + h, c + Vector2(-h.x, h.y)])
		var lo := ring[0]
		var hi := ring[0]
		for p in ring:
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
		var c0 := _cell(lo, CELL_M * m)
		var c1 := _cell(hi, CELL_M * m)
		for x in range(c0.x, c1.x + 1):
			for z in range(c0.y, c1.y + 1):
				var k := Vector2i(x, z)
				if not grid.has(k):
					grid[k] = []
				(grid[k] as Array).append(ring)
	return grid

## Fades lane and kerb paint across the whole apron, not only near its node.
static func _paint_points(buckets: Dictionary, hull: PackedVector2Array, m: float) -> void:
	var lo := hull[0]
	var hi := hull[0]
	for p in hull:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var step := PAINT_GRID_M * m
	var pts := hull.duplicate()
	var x := lo.x
	while x <= hi.x:
		var z := lo.y
		while z <= hi.y:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), hull):
				pts.append(Vector2(x, z))
			z += step
		x += step
	for p in pts:
		var cell := Vector2i(floori(p.x / RoadSurface.JUNCTION_M), floori(p.y / RoadSurface.JUNCTION_M))
		var arr: PackedVector2Array = buckets.get(cell, PackedVector2Array())
		arr.append(p)
		buckets[cell] = arr

## A zebra just beyond the apron on each urban arm with none mapped near.
static func _infer_crossings(out: Plan, arms: Array, centre: Vector2, setback: float, ground: GroundTruth,
		mapped: Dictionary, m: float) -> void:
	var depth := INFERRED_DEPTH_M * m
	var dist := setback + depth * 0.5 + INFERRED_GAP_M * m
	var near_r := MAPPED_NEAR_M * m
	for a: Dictionary in arms:
		var width: float = a["width"]
		if width < INFERRED_MIN_WIDTH_M * m or float(a["length"]) < dist + depth:
			continue
		var at: Array = _along(a["pts"], a["j"], a["dir"], dist)
		var p: Vector2 = at[0]
		var start: Vector2 = (a["pts"] as PackedVector2Array)[int(a["j"])]
		if p.distance_to(centre) < start.distance_to(centre) + setback * 0.5:
			continue  # back into the junction
		if ground.land_class_at(p.x, p.y) != "urban" or _mapped_near(mapped, p, near_r, m):
			continue
		var t: Vector2 = at[1]
		var side := Vector2(t.y, -t.x) * (width * 0.5 - KERB_CLEAR_M * m)
		out.inferred.append(PackedVector2Array([p + side, p - side]))

static func _mapped_near(grid: Dictionary, p: Vector2, r: float, m: float) -> bool:
	for seg: Array in _grid_near(grid, p, r, m):
		if Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) <= r:
			return true
	return false

## Finish and width of each mapped crossing way.
static func _assign_crossings(out: Plan, data: LocationData, chains: Array) -> void:
	for chain: Dictionary in chains:
		var tagged := 0.0
		for i in (chain["roads"] as PackedInt32Array):
			var road: Dictionary = data.roads[i]
			if bool(road.get("width_tagged", false)):
				tagged = maxf(tagged, float(road.get("width_m", 0.0)))
		var w := RoadBuilder.CROSSING_MIN_M
		if tagged >= RoadBuilder.CROSSING_MIN_M:
			w = tagged
		elif bool(chain.get("scramble_cluster", false)) or bool(chain["scramble"]):
			w = SCRAMBLE_WIDTH_M
		elif bool(chain["signal"]):
			w = clampf(float(chain["length"]) * SIGNAL_WIDTH_PER_M, RoadBuilder.CROSSING_MIN_M, SIGNAL_MAX_M)
		for i in (chain["roads"] as PackedInt32Array):
			var road: Dictionary = data.roads[i]
			out.by_road[i] = {"finish": RoadSurface.crossing_finish(str(road.get("crossing_style", "auto")),
				bool(road.get("crossing_signal", false)), data), "width_m": w}

## Stop lines for signalled crossings and lone signal nodes.
static func _stop_lines(out: Plan, data: LocationData, chains: Array, car_grid: Dictionary, centres: Dictionary, m: float) -> void:
	var left_traffic := RoadSurface.left_traffic(data)
	var signal_grid := {}
	for chain: Dictionary in chains:
		if not bool(chain["signal"]):
			continue
		var half := float((out.by_road[(chain["roads"] as PackedInt32Array)[0]] as Dictionary)["width_m"]) * m * 0.5
		var best := {}
		for seg: Array in chain["segs"]:
			_grid_add(signal_grid, seg[0], seg[1], seg, m)
			_contacts(best, seg[0], seg[1], car_grid, data, m)
		for i: int in best:
			var hit: Dictionary = best[i]
			var line: Variant = data.roads[i]
			var pts := RoadSurface._points(line)
			var seg_i: int = hit["seg"]
			var d := (pts[seg_i + 1] - pts[seg_i]).normalized()
			var sine := absf(d.cross((hit["other"] as Vector2).normalized()))
			var back := half / maxf(sine, 0.5) + STOP_BACK_M * m
			_arrivals(out, line, pts, seg_i, hit["point"], back, centres, left_traffic, false, m)
	for raw: Variant in data.street_furniture:
		if not (raw is Dictionary) or str((raw as Dictionary).get("kind", "")) != "signals":
			continue
		var p := Vector2(float((raw as Dictionary).get("x", 0.0)), float((raw as Dictionary).get("z", 0.0)))
		var clear := true
		for seg: Array in _grid_near(signal_grid, p, SIGNAL_CLEAR_M * m, m):
			if Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p) <= SIGNAL_CLEAR_M * m:
				clear = false
				break
		if not clear:
			continue
		var hit := {}
		_contacts(hit, p, p, car_grid, data, m)
		for i: int in hit:
			var seg_i: int = (hit[i] as Dictionary)["seg"]
			_arrivals(out, data.roads[i], RoadSurface._points(data.roads[i]), seg_i,
				(hit[i] as Dictionary)["point"], 0.0, centres, left_traffic, true, m)

## Nearest contact per carriageway with segment a-b:
## {road: {seg, point, other (a-b direction)}}.
static func _contacts(best: Dictionary, a: Vector2, b: Vector2, car_grid: Dictionary, data: LocationData, m: float) -> void:
	var seen := {}
	var r := CONTACT_M * m
	var cells := _cells(a, b, r, m)
	for k: Vector2i in cells:
		for entry: Array in car_grid.get(k, []):
			if seen.has(entry):
				continue
			seen[entry] = true
			var i: int = entry[0]
			var j: int = entry[1]
			var pts := RoadSurface._points(data.roads[i])
			var on: PackedVector2Array = Geometry2D.get_closest_points_between_segments(pts[j], pts[j + 1], a, b)
			var d := on[0].distance_to(on[1])
			if d <= r and (not best.has(i) or d < float((best[i] as Dictionary)["d"])):
				best[i] = {"seg": j, "point": on[0], "other": b - a if a != b else Vector2.RIGHT, "d": d}

## The stop bars on `line` for traffic arriving at `at` on segment seg.
## `need_junction`: a lone signal gives no travel direction of its own,
## so without a junction ahead no line is drawn.
static func _arrivals(out: Plan, line: Variant, pts: PackedVector2Array, seg: int, at: Vector2, back: float,
		centres: Dictionary, left_traffic: bool, need_junction: bool, m: float) -> void:
	var oneway: int = int((line as Dictionary).get("oneway", 0)) if line is Dictionary else 0
	var centre := _nearest_centre(centres, at, m)
	if need_junction and (not centre.is_finite() or centre.distance_to(at) <= JUNCTION_SKIP_M * m):
		return
	var hw := _width(line, m) * 0.5 - KERB_CLEAR_M * m
	var arc := at.distance_to(pts[seg])
	for k in seg:
		arc += pts[k].distance_to(pts[k + 1])
	var total := 0.0
	for k in pts.size() - 1:
		total += pts[k].distance_to(pts[k + 1])
	for travel_dir: int in [1, -1]:
		if oneway != 0 and oneway != travel_dir:
			continue
		var from := arc - back if travel_dir > 0 else arc + back
		if from < 0.0 or from > total:
			continue
		var travel: Vector2 = (_point_at(pts, arc)[1] as Vector2) * float(travel_dir)
		if centre.is_finite() and centre.distance_to(at) <= ARRIVE_REACH_M * m and travel.dot(centre - at) <= 0.0:
			continue
		var pose: Array = _point_at(pts, from)
		var q: Vector2 = pose[0]
		var d: Vector2 = (pose[1] as Vector2) * float(travel_dir)
		var left := Vector2(d.y, -d.x)
		if oneway != 0:
			out.stops.append(PackedVector2Array([q + left * hw, q - left * hw]))
		else:
			var side := left if left_traffic else -left
			out.stops.append(PackedVector2Array([q + side * 0.15 * m, q + side * hw]))

## Point and forward tangent at arc length `dist`.
static func _point_at(pts: PackedVector2Array, dist: float) -> Array:
	var left := dist
	for i in pts.size() - 1:
		var seg := pts[i].distance_to(pts[i + 1])
		if left <= seg or i == pts.size() - 2:
			var t := (pts[i + 1] - pts[i]) / maxf(seg, 0.0001)
			return [pts[i] + t * minf(left, seg), t]
		left -= seg
	return [pts[0], Vector2.RIGHT]

## Nearest junction centre within ARRIVE_REACH_M, else Vector2.INF.
static func _nearest_centre(centres: Dictionary, p: Vector2, m: float) -> Vector2:
	var cell := _cell(p, ARRIVE_REACH_M * m)
	var best := Vector2.INF
	var best_d := INF
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var arr: Variant = centres.get(cell + Vector2i(dx, dz), null)
			if arr == null:
				continue
			for c: Vector2 in (arr as PackedVector2Array):
				var d := c.distance_to(p)
				if d < best_d:
					best_d = d
					best = c
	return best

static func _cell(p: Vector2, size: float) -> Vector2i:
	return Vector2i(floori(p.x / size), floori(p.y / size))

static func _cells(a: Vector2, b: Vector2, r: float, m: float) -> Array[Vector2i]:
	var size := CELL_M * m
	var lo := _cell(Vector2(minf(a.x, b.x) - r, minf(a.y, b.y) - r), size)
	var hi := _cell(Vector2(maxf(a.x, b.x) + r, maxf(a.y, b.y) + r), size)
	var out: Array[Vector2i] = []
	for x in range(lo.x, hi.x + 1):
		for z in range(lo.y, hi.y + 1):
			out.append(Vector2i(x, z))
	return out

static func _grid_add(grid: Dictionary, a: Vector2, b: Vector2, value: Variant, m: float) -> void:
	for k in _cells(a, b, 0.0, m):
		if not grid.has(k):
			grid[k] = []
		(grid[k] as Array).append(value)

static func _grid_near(grid: Dictionary, p: Vector2, r: float, m: float) -> Array:
	var out: Array = []
	var seen := {}
	for k in _cells(p, p, r, m):
		for v: Variant in grid.get(k, []):
			if not seen.has(v):
				seen[v] = true
				out.append(v)
	return out
