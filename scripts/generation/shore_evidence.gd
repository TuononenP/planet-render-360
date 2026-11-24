class_name ShoreEvidence
extends RefCounted

## Indexed, geometry-based waterfront evidence. No place names or imagery.
const CELL := 64.0
## How far beside a road bridge's edge a stream's edge still counts as
## under its abutment, metres.
const ABUTMENT_REACH_M := 3.0
## A footbridge this close to a road bridge on abutments passes under it.
const UNDER_M := 5.0
const NATURAL := ["grass", "park", "beach", "forest", "field", "orchard", "cemetery", "pitch", "wetland", "sand", "rock", "glacier"]
## A mapped wall this far inland of a river's edge, parallel to it, is
## the upper wall of a low quay (QUAY_STATION_M stations, runs of at
## least QUAY_MIN_RUN_M), metres: Paris maps its quays' retaining walls
## along the streets, 5–20 m back from the Seine's edge at their foot.
const QUAY_SETBACK_MIN_M := 3.0
const QUAY_SETBACK_MAX_M := 18.0
const QUAY_STATION_M := 2.0
const QUAY_MIN_RUN_M := 20.0
## A run follows one wall: a station whose wall stands this much farther
## or nearer than the last one's starts a new run, metres (stairs' and
## ramps' walls beside the quay's own zigzagged its upper wall).
const QUAY_JUMP_M := 2.0
## A break this long or shorter in a mapped wall (steps or a ramp down to
## the walk, two ways that stop short of each other) is bridged, metres.
const QUAY_GAP_M := 20.0
## Stairs or a platform this close to a quayed bank are its own, metres.
const QUAY_ACCESS_M := 1.5
## A bank under a bridge is quayed when a station this near along the edge
## has a wall behind it (stations are QUAY_STATION_M apart).
const QUAY_ABUTMENT_SEEK := 20
## An abutment's depth where no wall is mapped behind a bridge's landing, metres.
const QUAY_ABUTMENT_M := 6.0
## Bank this far along the edge either side of a bridge's abutment, with
## no wall of its own mapped, is the abutment too: the street a bridge
## lands on is level with it, metres (the elevation model's blurred river
## left a trough there, a pale slope behind a wall whose top dipped).
const QUAY_APPROACH_M := 20.0
var features: Array = []
## Low quays: {id, shore (stations on the water's edge), wall (the upper
## wall behind each station), land (unit, away from the water)}. Each
## shore run is also a mapped structure, so the bank at the water's edge
## is a wall (ShorelineModel lowers the ground behind it, _make_quays).
var quays: Array = []
## Bank stretches under a bridge landing on a quayed bank, as `quays`
## (id "abutment:<osm id>"): the ground from the water's edge to the wall
## stands at the street's height there.
var abutment_runs: Array = []
## Road bridge id ("abutment:<osm id>") -> its end points: the bank under
## it is an abutment whose top is the road's level there.
var abutment_ends := {}
var cells: Dictionary = {}
var native: Object = null

func _init(data: LocationData = null) -> void:
	if data == null:
		return
	for b in data.buildings:
		if SuomenlinnaSite.fortress(b):
			continue  # Grass-covered defenses are not urban waterfront frontage.
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		if ring.size() < 3:
			var at := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
			var half := Vector2(float(b.get("size_x", 0.0)), float(b.get("size_z", 0.0))) * 0.5
			if half.x <= 0.0 or half.y <= 0.0:
				continue
			ring = PackedVector2Array([at - half, at + Vector2(half.x, -half.y), at + half, at + Vector2(-half.x, half.y)])
		_add({"kind": "building", "points": ring, "holes": b.get("holes", []), "area": true,
			"id": str(b.get("osm_id", "building:legacy_index:%d" % features.size()))})
	for structure in data.shore_structures:
		var f: Dictionary = structure.duplicate()
		f["structure_kind"] = str(structure.get("kind", ""))
		f["kind"] = "structure"
		f["area"] = false
		_add(f)
	var m2u := WorldScale.metres_to_units()
	var vessels := ShipBuilder.vessel_rings(data, 3.0 * m2u)
	var water_edges := _water_edges(data)
	# Bridges standing on abutments: every bridge landing on a quayed bank,
	# and road bridges over streams.
	var abutted: Array = _quay_fronts(data, vessels)
	for road in data.roads:
		if road is Dictionary and bool(road.get("bridge", false)) and not bool(road.get("tunnel", false)) \
				and not ShipBuilder.gangplank(road.get("points", PackedVector2Array()), vessels, m2u) \
				and _abutments(road, water_edges):
			abutted.append(road.get("points", PackedVector2Array()))
	for road in data.roads:
		if not (road is Dictionary) or bool(road.get("tunnel", false)):
			continue
		var rpts: PackedVector2Array = road.get("points", PackedVector2Array())
		if bool(road.get("bridge", false)) and (abutted.has(rpts) or ShipBuilder.gangplank(rpts, vessels, m2u)):
			continue
		# A footbridge passing under a road bridge's abutments (a path along
		# the creek under the motorway) does not break them.
		if bool(road.get("bridge", false)) and _under(rpts, abutted):
			continue
		if bool(road.get("bridge", false)):
			_add({"kind": "break", "points": rpts, "area": false,
				"width": maxf(float(road.get("width_m", 0.0)), 0.0) * 0.5,
				"id": str(road.get("osm_id", "bridge:legacy_index:%d" % features.size()))})
			continue
		var cls := str(road.get("class", ""))
		var surface := str(road.get("surface", ""))
		# Steps never open a shore wall; platforms at a low quay's wall do not either.
		if cls == "platform" and not _at_quay(road.get("points", PackedVector2Array())):
			_add({"kind": "break", "points": road.get("points", PackedVector2Array()), "area": bool(road.get("area", false))})
		if surface in ["asphalt", "paved", "paving_stones", "sett", "cobblestone", "unhewn_cobblestone", "bricks", "concrete", "concrete:plates", "stone"] \
				or (surface == "" and cls in ["pedestrian", "living_street"]):
			_add({"kind": "paved", "points": road.get("points", PackedVector2Array()),
				"area": bool(road.get("area", false)), "holes": road.get("holes", []),
				"width": maxf(float(road.get("width_m", 0.0)), 0.0) * 0.5,
				"id": str(road.get("osm_id", "road:legacy_index:%d" % features.size()))})
	for poly in data.land_polygons:
		var cls := str(poly.get("class", ""))
		if cls in NATURAL:
			_add({"kind": "natural", "points": poly.get("points", PackedVector2Array()),
				"holes": poly.get("holes", []), "area": true,
				"id": str(poly.get("osm_id", "land:legacy_index:%d" % features.size()))})
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShoreEvidenceIndex"):
		native = ClassDB.instantiate("ShoreEvidenceIndex")
		native.setup(features, cells)

## The edges of narrow streams' water polygons (ShoreDomains._stream) as
## [a, b, bounds].
static func _water_edges(data: LocationData) -> Array:
	var out: Array = []
	for poly in data.land_polygons:
		if str(poly.get("class", "")) != "water" \
				or not ShoreDomains._stream({"points": poly.get("points", PackedVector2Array())}):
			continue  # A quayed canal or harbour keeps its masonry run under the bridge.
		var rings: Array = [poly.get("points", PackedVector2Array())]
		rings.append_array(poly.get("holes", []))
		for ring: PackedVector2Array in rings:
			for i in ring.size():
				var a := ring[i]
				var b := ring[(i + 1) % ring.size()]
				out.append([a, b, Rect2(a, Vector2.ZERO).expand(b)])
	return out

## A road bridge (not a footbridge) over a stream stands on abutments: the
## stream's edges under it, within its half width and ABUTMENT_REACH_M,
## become mapped structures, so the bank there is a wall and the land
## keeps the road's height up to the water (ShorelineModel takes the top
## from the bridge's ends). A natural bank sloping away under the bridge
## carved the approaches down to the creek. True when it found any.
func _abutments(road: Dictionary, edges: Array) -> bool:
	if RoadBuilder._rank(str(road.get("class", ""))) < 1:
		return false
	var pts: PackedVector2Array = road.get("points", PackedVector2Array())
	if pts.size() < 2:
		return false
	var m2u := WorldScale.metres_to_units()
	var reach := (float(road.get("width_m", 0.0)) * 0.5 + ABUTMENT_REACH_M) * m2u
	var box := RingGeometry.aabb(pts).grow(reach)
	var id := "abutment:" + str(road.get("osm_id", "bridge:%d" % features.size()))
	var found := false
	for e: Array in edges:
		if not box.intersects(e[2] as Rect2, true):
			continue
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		# Only the stretch of the edge under the bridge: a long bank edge
		# walled from end to end cut off the path along the creek.
		var n := maxi(1, ceili(a.distance_to(b) / m2u))
		var run := PackedVector2Array()
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(n))
			var near := INF
			for i in pts.size() - 1:
				near = minf(near, Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1]).distance_to(p))
			if near <= reach:
				run.append(p)
			elif run.size() >= 2:
				_add({"kind": "structure", "points": run, "area": false, "id": id})
				found = true
				run = PackedVector2Array()
			else:
				run = PackedVector2Array()
		if run.size() >= 2:
			_add({"kind": "structure", "points": run, "area": false, "id": id})
			found = true
	if found:
		abutment_ends[id] = PackedVector2Array([pts[0], pts[pts.size() - 1]])
	return found

## The low quays (`quays`) along every river and basin (not a stream) edge
## inside the detailed area, each also added as a mapped structure. Under
## a bridge the quayed bank is that bridge's abutment instead
## (`abutment_runs`); returns those bridges' points.
func _quay_fronts(data: LocationData, vessels: Array = []) -> Array:
	var abutted: Array = []
	var walls := {}
	for i in features.size():
		var f: Dictionary = features[i]
		# Earthen embankments inland of a river are grassy slopes, not vertical
		# masonry upper walls of a two-level quay.
		if str(f["kind"]) == "structure" and str(f.get("structure_kind", "")) != "embankment" \
				and not str(f.get("id", "")).begins_with("abutment:"):
			walls[i] = true
	if walls.is_empty():
		return abutted
	var m2u := WorldScale.metres_to_units()
	var bridges: Array = []
	for road in data.roads:
		if not (road is Dictionary) or not bool(road.get("bridge", false)) or bool(road.get("tunnel", false)):
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		if pts.size() < 2 or ShipBuilder.gangplank(pts, vessels, m2u):
			continue
		var reach := (float(road.get("width_m", 0.0)) * 0.5 + ABUTMENT_REACH_M) * m2u
		bridges.append({"points": pts, "reach": reach, "box": RingGeometry.aabb(pts).grow(reach),
			"id": "abutment:" + str(road.get("osm_id", "bridge:%d" % bridges.size()))})
	var bound := WorldScale.detailed_extent_units() * 0.5 + 50.0 * m2u
	var runs: Array = []
	var stubs: Array = []
	for poly in data.land_polygons:
		if str(poly.get("class", "")) != "water" \
				or ShoreDomains._stream({"points": poly.get("points", PackedVector2Array())}):
			continue
		var rings: Array = [poly.get("points", PackedVector2Array())]
		rings.append_array(poly.get("holes", []))
		var ring_stations: Array = []
		var poly_quayed := false
		for ring: PackedVector2Array in rings:
			# The ring's stations first: [p, land, the wall's distance behind
			# it or -1, the wall's point, the bridge over it or -1]; a null
			# breaks the runs (outside the detailed area).
			var stations: Array = []
			var last := -1.0
			for i in ring.size():
				var a := ring[i]
				var b := ring[(i + 1) % ring.size()]
				var length := a.distance_to(b)
				var mid := (a + b) * 0.5
				if length < 0.001 or absf(mid.x) > bound or absf(mid.y) > bound:
					stations.append(null)
					last = -1.0
					continue
				var dir := (b - a) / length
				var land := Vector2(-dir.y, dir.x)
				if _inside(mid + land * 0.5 * m2u, poly):
					land = -land
				var count := maxi(1, ceili(length / (QUAY_STATION_M * m2u)))
				for k in count:
					var p := a.lerp(b, float(k) / float(count))
					var hit: Variant = _wall_behind(p, land, dir, walls, last)
					if hit != null and _inside(((hit as Vector2) + p) * 0.5, poly):
						hit = null
					last = p.distance_to(hit) if hit != null else -1.0
					stations.append([p, land, last, hit if hit != null else p, _bridge_over(p, bridges)])
					poly_quayed = poly_quayed or last >= 0.0
			_bridge_wall_gaps(stations, poly)
			_approach_abutments(stations)
			ring_stations.append(stations)
		for stations: Array in ring_stations:
			var last := -1.0
			var run := _quay_run()
			var stub := _quay_run()
			for i in stations.size():
				if stations[i] == null:
					run = _close_quay_run(run, runs)
					stub = _close_stub(stub, stubs)
					last = -1.0
					continue
				var st: Array = stations[i]
				var p: Vector2 = st[0]
				var land: Vector2 = st[1]
				var back := float(st[2])
				var bridge := int(st[4])
				if bridge >= 0:
					# Under a bridge on a quayed bank (its wall often stops short
					# of the bridge): the abutment, as deep as the wall nearby.
					if back < 0.0:
						back = _wall_near(stations, i)
					# On a river with quays a bridge lands on an abutment
					# wherever it lands: without a mapped wall to take its
					# depth, the ground there dipped toward the river and the
					# deck's approach slab ran on over the gap.
					if back < 0.0 and poly_quayed:
						back = QUAY_ABUTMENT_M * m2u
					if back >= 0.0:
						run = _close_quay_run(run, runs)
						if stub.get("bridge", bridge) != bridge:
							stub = _close_stub(stub, stubs)
						stub["bridge"] = bridge
						_quay_station(stub, p, p + land * back, land)
						last = -1.0
						continue
				stub = _close_stub(stub, stubs)
				if back < 0.0:
					run = _close_quay_run(run, runs)
					last = -1.0
					continue
				if last >= 0.0 and absf(back - last) > QUAY_JUMP_M * m2u:
					run = _close_quay_run(run, runs)
				last = back
				_quay_station(run, p, st[3], land)
			_close_quay_run(run, runs)
			_close_stub(stub, stubs)
	for run: Dictionary in runs:
		var id := "quay:%d" % quays.size()
		run["id"] = id
		run["land"] = (run["land"] as Vector2).normalized()
		quays.append(run)
		_add({"kind": "structure", "points": run["shore"], "area": false, "id": id})
	for stub: Dictionary in stubs:
		var bridge: Dictionary = bridges[int(stub["bridge"])]
		var pts: PackedVector2Array = bridge["points"]
		stub["id"] = bridge["id"]
		stub["land"] = (stub["land"] as Vector2).normalized()
		abutment_runs.append(stub)
		_add({"kind": "structure", "points": stub["shore"], "area": false, "id": bridge["id"]})
		abutment_ends[bridge["id"]] = PackedVector2Array([pts[0], pts[pts.size() - 1]])
		if not abutted.has(pts):
			abutted.append(pts)
	return abutted

## The wall's distance behind the station nearest `i` that has one, within
## QUAY_ABUTMENT_SEEK stations either way along the ring; -1 when none.
static func _wall_near(stations: Array, i: int) -> float:
	for d in range(1, QUAY_ABUTMENT_SEEK + 1):
		for k: int in [i - d, i + d]:
			var st: Variant = stations[posmod(k, stations.size())]
			if st != null and float(st[2]) >= 0.0:
				return float(st[2])
	return -1.0

## A wall with a short break in it is one wall: stations along a break up
## to QUAY_GAP_M long take the line between the wall's points either side.
## Left open, the street stood out to the water between two walks as a pier.
static func _bridge_wall_gaps(stations: Array, poly: Dictionary) -> void:
	var n := stations.size()
	var m2u := WorldScale.metres_to_units()
	for i in n:
		var before: Variant = stations[i]
		if before == null or float(before[2]) < 0.0:
			continue
		# Stations i + 1 on without a wall, and how far along the edge each is.
		var along := PackedFloat32Array()
		var length := 0.0
		var after: Variant = null
		for j in range(i + 1, i + n):
			after = stations[j % n]
			if after == null:
				break
			length += (after[0] as Vector2).distance_to(stations[(j - 1) % n][0])
			if float(after[2]) >= 0.0 or int(after[4]) >= 0 or length > QUAY_GAP_M * m2u:
				break
			along.append(length)
		if along.is_empty() or after == null or float(after[2]) < 0.0 or length > QUAY_GAP_M * m2u:
			continue
		var hits := PackedVector2Array()
		for k in along.size():
			var st: Array = stations[(i + 1 + k) % n]
			var hit := (before[3] as Vector2).lerp(after[3], along[k] / length)
			if (hit - (st[0] as Vector2)).dot(st[1]) < QUAY_SETBACK_MIN_M * m2u \
					or _inside((hit + (st[0] as Vector2)) * 0.5, poly):
				break
			hits.append(hit)
		if hits.size() < along.size():
			continue
		for k in along.size():
			var st: Array = stations[(i + 1 + k) % n]
			st[3] = hits[k]
			st[2] = (st[0] as Vector2).distance_to(hits[k])

## Stations without a wall within QUAY_APPROACH_M along the edge of one
## under a bridge take that bridge (their abutment), up to a wall or a break.
static func _approach_abutments(stations: Array) -> void:
	var n := stations.size()
	var reach := QUAY_APPROACH_M * WorldScale.metres_to_units()
	var marks := {}
	for i in n:
		var st: Variant = stations[i]
		if st == null or int(st[4]) < 0:
			continue
		for way: int in [-1, 1]:
			var along := 0.0
			var prev: Array = st
			for k in range(1, n):
				var next: Variant = stations[posmod(i + way * k, n)]
				if next == null or float(next[2]) >= 0.0 or int(next[4]) >= 0:
					break
				along += (next[0] as Vector2).distance_to(prev[0])
				if along > reach:
					break
				marks[posmod(i + way * k, n)] = int(st[4])
				prev = next
	for k: int in marks:
		stations[k][4] = marks[k]

static func _quay_run() -> Dictionary:
	return {"shore": PackedVector2Array(), "wall": PackedVector2Array(), "land": Vector2.ZERO}

## Adds a station to `run` (packed arrays are values: written back).
static func _quay_station(run: Dictionary, p: Vector2, wall_at: Vector2, land: Vector2) -> void:
	var shore: PackedVector2Array = run["shore"]
	var wall: PackedVector2Array = run["wall"]
	shore.append(p)
	wall.append(wall_at)
	run["shore"] = shore
	run["wall"] = wall
	run["land"] = (run["land"] as Vector2) + land

## Keeps an abutment run of two stations or more; a fresh run either way.
static func _close_stub(stub: Dictionary, stubs: Array) -> Dictionary:
	if (stub["shore"] as PackedVector2Array).size() >= 2:
		stubs.append(stub)
	return _quay_run()

## The bridge (index in `bridges`) `p` lies under, else -1.
static func _bridge_over(p: Vector2, bridges: Array) -> int:
	for i in bridges.size():
		var bridge: Dictionary = bridges[i]
		if not (bridge["box"] as Rect2).has_point(p):
			continue
		var pts: PackedVector2Array = bridge["points"]
		for j in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1]).distance_to(p) <= float(bridge["reach"]):
				return i
	return -1

## True when polyline `pts` comes within QUAY_ACCESS_M of a quayed bank.
func _at_quay(pts: PackedVector2Array) -> bool:
	var reach := QUAY_ACCESS_M * WorldScale.metres_to_units()
	for group: Array in [quays, abutment_runs]:
		for q: Dictionary in group:
			var shore: PackedVector2Array = q["shore"]
			if not RingGeometry.aabb(shore).grow(reach).intersects(RingGeometry.aabb(pts), true):
				continue
			for i in pts.size() - 1:
				for j in shore.size() - 1:
					var hits: PackedVector2Array = Geometry2D.get_closest_points_between_segments(pts[i], pts[i + 1], shore[j], shore[j + 1])
					if hits[0].distance_to(hits[1]) <= reach:
						return true
	return false

## Keeps `run` in `runs` when it is long enough and does not duplicate an
## already-recorded run from an overlapping water polygon; a fresh run either way.
static func _close_quay_run(run: Dictionary, runs: Array) -> Dictionary:
	var shore: PackedVector2Array = run["shore"]
	var length := 0.0
	for i in shore.size() - 1:
		length += shore[i].distance_to(shore[i + 1])
	var m2u := WorldScale.metres_to_units()
	if shore.size() >= 2 and length >= QUAY_MIN_RUN_M * m2u:
		var mid := shore[shore.size() / 2]
		var dup := false
		for existing: Dictionary in runs:
			var es: PackedVector2Array = existing["shore"]
			for i in es.size() - 1:
				if Geometry2D.get_closest_point_to_segment(mid, es[i], es[i + 1]).distance_to(mid) <= 2.0 * m2u:
					dup = true
					break
			if dup:
				break
		if not dup:
			runs.append(run)
	return _quay_run()

## Where a mapped wall (`walls`, feature indexes) parallel to `dir` crosses
## the line from `p` inland along `land`, between QUAY_SETBACK_MIN_M and
## QUAY_SETBACK_MAX_M: the nearest crossing, or the one nearest `prefer`
## from `p` when that is not negative (the wall the run follows); null
## when none does.
func _wall_behind(p: Vector2, land: Vector2, dir: Vector2, walls: Dictionary, prefer: float = -1.0) -> Variant:
	var m2u := WorldScale.metres_to_units()
	var reach := QUAY_SETBACK_MAX_M * m2u
	var far := p + land * reach
	var best := INF
	var out: Variant = null
	for i in candidates(p + land * reach * 0.5, reach * 0.5 + 1.0):
		if not walls.has(i):
			continue
		var pts: PackedVector2Array = features[i]["points"]
		for j in pts.size() - 1:
			var d := pts[j + 1] - pts[j]
			if d.length_squared() < 0.0001 or absf(dir.dot(d.normalized())) < 0.8:
				continue
			var hit: Variant = Geometry2D.segment_intersects_segment(p, far, pts[j], pts[j + 1])
			if hit == null:
				continue
			var distance := p.distance_to(hit)
			var score := distance if prefer < 0.0 else absf(distance - prefer)
			if distance >= QUAY_SETBACK_MIN_M * m2u and score < best:
				best = score
				out = hit
	return out

## True when polyline `pts` comes within UNDER_M of any of `lines`.
static func _under(pts: PackedVector2Array, lines: Array) -> bool:
	var reach := UNDER_M * WorldScale.metres_to_units()
	for line: PackedVector2Array in lines:
		for i in pts.size() - 1:
			for j in line.size() - 1:
				var hits: PackedVector2Array = Geometry2D.get_closest_points_between_segments(pts[i], pts[i + 1], line[j], line[j + 1])
				if hits[0].distance_to(hits[1]) <= reach:
					return true
	return false

func _add(f: Dictionary) -> void:
	var points: PackedVector2Array = f.get("points", PackedVector2Array())
	if points.size() < 2:
		return
	var index := features.size()
	features.append(f)
	var box := RingGeometry.aabb(points)
	for x in range(floori(box.position.x / CELL), floori(box.end.x / CELL) + 1):
		for z in range(floori(box.position.y / CELL), floori(box.end.y / CELL) + 1):
			var key := Vector2i(x, z)
			if not cells.has(key):
				cells[key] = []
			(cells[key] as Array).append(index)

func candidates(p: Vector2, radius: float) -> Array:
	var found := {}
	for x in range(floori((p.x - radius) / CELL), floori((p.x + radius) / CELL) + 1):
		for z in range(floori((p.y - radius) / CELL), floori((p.y + radius) / CELL) + 1):
			for i in cells.get(Vector2i(x, z), []):
				found[i] = true
	return found.keys()

func contains_kind(p: Vector2, kind: String) -> bool:
	if native != null:
		return native.contains_kind(p, kind)
	for i in candidates(p, 0.0):
		var f: Dictionary = features[i]
		if str(f["kind"]) == kind and bool(f.get("area", false)) and _inside(p, f):
			return true
	return false

func classify(a: Vector2, b: Vector2, land: Vector2) -> Dictionary:
	if native != null:
		return native.classify(a, b, land)
	var explicit: Array = []
	var votes := 0
	var natural_cover := false
	var ids: Array = []
	var dir := (b - a).normalized()
	for t in [0.0, 0.5, 1.0]:
		var p := a.lerp(b, t)
		var paved := false
		var built := false
		var natural := contains_kind(p + land * 2.0, "natural")
		natural_cover = natural_cover or natural
		for i in candidates(p, 24.0):
			var f: Dictionary = features[i]
			var kind := str(f["kind"])
			if kind == "natural":
				continue
			var nearest := _nearest(p, f)
			var q: Vector2 = nearest[0]
			var distance: float = nearest[1]
			if kind == "structure" and distance <= 3.0 and absf(dir.dot(nearest[2])) >= 0.8:
				explicit.append(f.get("id", "structure"))
			elif kind == "break" and distance <= 1.0:
				return {"kind": "natural", "reason": "mapped_access", "sources": [f.get("id", "break")]}
			elif (q - p).dot(land) >= -0.01:
				if kind == "paved" and distance <= 8.0:
					paved = true
					ids.append(f.get("id", "paved"))
				if kind == "building" and distance <= 20.0:
					built = true
					ids.append(f.get("id", "building"))
		if not natural and paved and built:
			votes += 1
	if not explicit.is_empty():
		return {"kind": "hard", "reason": "mapped_structure", "sources": explicit}
	if natural_cover:
		return {"kind": "natural", "reason": "natural_cover", "sources": []}
	if votes >= 2:
		return {"kind": "hard", "reason": "paving_and_frontage", "sources": ids}
	return {"kind": "natural", "reason": "insufficient_evidence", "sources": []}

static func _inside(p: Vector2, f: Dictionary) -> bool:
	if not Geometry2D.is_point_in_polygon(p, f["points"]):
		return false
	for hole in f.get("holes", []):
		if Geometry2D.is_point_in_polygon(p, hole):
			return false
	return true

static func _nearest(p: Vector2, f: Dictionary) -> Array:
	if bool(f.get("area", false)) and _inside(p, f):
		return [p, 0.0, Vector2.ZERO]
	var points: PackedVector2Array = f["points"]
	var count := points.size() if bool(f.get("area", false)) else points.size() - 1
	var best := INF
	var at := Vector2.ZERO
	var dir := Vector2.ZERO
	for i in count:
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := maxf(0.0, p.distance_to(q) - float(f.get("width", 0.0)))
		if d < best:
			best = d
			at = q
			dir = (b - a).normalized()
	return [at, best, dir]
