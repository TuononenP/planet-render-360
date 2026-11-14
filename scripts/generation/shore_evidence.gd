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
var features: Array = []
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
	var water_edges := _water_edges(data)
	var abutted: Array = []  # Road bridges standing on abutments.
	for road in data.roads:
		if road is Dictionary and bool(road.get("bridge", false)) and not bool(road.get("tunnel", false)) \
				and _abutments(road, water_edges):
			abutted.append(road.get("points", PackedVector2Array()))
	for road in data.roads:
		if not (road is Dictionary) or bool(road.get("tunnel", false)):
			continue
		if bool(road.get("bridge", false)) and abutted.has(road.get("points", PackedVector2Array())):
			continue
		# A footbridge passing under a road bridge's abutments (a path along
		# the creek under the motorway) does not break them.
		if bool(road.get("bridge", false)) and _under(road.get("points", PackedVector2Array()), abutted):
			continue
		if bool(road.get("bridge", false)):
			_add({"kind": "break", "points": road.get("points", PackedVector2Array()), "area": false,
				"width": maxf(float(road.get("width_m", 0.0)), 0.0) * 0.5,
				"id": str(road.get("osm_id", "bridge:legacy_index:%d" % features.size()))})
			continue
		var cls := str(road.get("class", ""))
		var surface := str(road.get("surface", ""))
		if cls in ["steps", "platform"]:
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
	for structure in data.shore_structures:
		var f: Dictionary = structure.duplicate()
		f["kind"] = "structure"
		f["area"] = false
		_add(f)
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
