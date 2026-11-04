class_name ShoreDomains
extends RefCounted

## Water ownership and levels, shared by carving, meshes and probes.
## Raw rings keep their holes; a bounded cell index avoids lagoon scans.
const CELL := 64.0
var bodies: Array = []
var cells: Dictionary = {}
var bounds := Rect2()
var diagnostics: Array = []
var native: Object = null

func _init(data: LocationData = null, box: Rect2 = Rect2(), abort: BuildAbort = null) -> void:
	if data == null:
		return
	bounds = box
	for i in data.land_polygons.size():
		if abort != null and abort.requested:
			return
		var poly: Dictionary = data.land_polygons[i]
		if str(poly.get("class", "")) == "water":
			_add(poly.get("points", PackedVector2Array()), poly.get("holes", []),
				{"source": i, "kind": "polygon", "tidal": bool(poly.get("tidal", false)),
				"still_pool": bool(poly.get("still_pool", false))})
	_setup_native()
	for w in data.waterways:
		if abort != null and abort.requested:
			return
		if OsmTags.navigation_waterway(str(w.get("class", ""))):
			continue
		var line: PackedVector2Array = w.get("points", PackedVector2Array())
		var width := float(w.get("width_m", 0.0)) * WorldScale.metres_to_units()
		if line.size() < 2 or width <= 0.0:
			continue
		for i in line.size() - 1:
			var clipped := ShoreGeometry.clip_segment(line[i], line[i + 1], bounds.grow(width))
			if clipped.size() != 2:
				continue
			for run in _outside_polygon_runs(clipped[0], clipped[1]):
				for buffer in Geometry2D.offset_polyline(run, width * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
					_add(buffer, [], {"source": -1, "kind": "channel", "axis": run, "tidal": bool(w.get("tidal", false))})
	for coast in ShoreCoast.domains(data.waterways, bounds, diagnostics):
		_add(coast["points"], coast.get("holes", []), {"source": -1, "kind": "coast", "tidal": true})
	_setup_native()

func _outside_polygon_runs(a: Vector2, b: Vector2) -> Array:
	if native != null and native.has_method("outside_runs"):
		return native.outside_runs(a, b)
	var cuts: Array[float] = [0.0, 1.0]
	var d := b - a
	var box := Rect2(a.min(b), a.max(b) - a.min(b)).grow(0.01)
	for body in bodies:
		if str(body["kind"]) != "polygon" or not (body["box"] as Rect2).intersects(box):
			continue
		var rings: Array = [body["points"]]
		rings.append_array(body["holes"])
		for ring in rings:
			for i in ring.size():
				var hit: Variant = Geometry2D.segment_intersects_segment(a, b, ring[i], ring[(i + 1) % ring.size()])
				if hit is Vector2:
					cuts.append(clampf((hit - a).dot(d) / maxf(d.length_squared(), 0.00001), 0.0, 1.0))
	cuts.sort()
	var out: Array = []
	for i in cuts.size() - 1:
		if cuts[i + 1] - cuts[i] < 0.0000001:
			continue
		var p := a + d * (cuts[i + 1] + cuts[i]) * 0.5
		var covered := false
		for id in cells.get(Vector2i(floori(p.x / CELL), floori(p.y / CELL)), []):
			if str(bodies[id]["kind"]) == "polygon" and (bodies[id]["index"] as PolygonIndex).contains(p):
				covered = true
				break
		if not covered:
			out.append(PackedVector2Array([a + d * cuts[i], a + d * cuts[i + 1]]))
	return out

func _add(outer: PackedVector2Array, holes: Array, meta: Dictionary) -> void:
	if outer.size() < 3:
		return
	var box := RingGeometry.aabb(outer).intersection(bounds)
	if not box.has_area():
		return
	var body: Dictionary = meta.duplicate()
	body["points"] = outer
	body["holes"] = holes
	body["index"] = PolygonIndex.new(outer, holes)
	if not body.has("level"):
		body["level"] = NAN
	body["box"] = box
	var id := bodies.size()
	bodies.append(body)
	for x in range(floori(box.position.x / CELL), floori(box.end.x / CELL) + 1):
		for z in range(floori(box.position.y / CELL), floori(box.end.y / CELL) + 1):
			var key := Vector2i(x, z)
			if not cells.has(key):
				cells[key] = []
			(cells[key] as Array).append(id)

func at(p: Vector2, exclude: int = -1) -> int:
	if bounds.grow(0.01).has_point(p):
		p = p.clamp(bounds.position + Vector2.ONE * 0.001, bounds.end - Vector2.ONE * 0.001)
	if native != null:
		return native.at(p, exclude)
	for id in cells.get(Vector2i(floori(p.x / CELL), floori(p.y / CELL)), []):
		if id != exclude and (bodies[id]["index"] as PolygonIndex).contains(p):
			return id
	return -1

func level(id: int, p: Vector2) -> float:
	var body: Dictionary = bodies[id]
	if body.has("level_end"):
		var axis: PackedVector2Array = body["axis"]
		var d := axis[1] - axis[0]
		var t := clampf((p - axis[0]).dot(d) / maxf(d.length_squared(), 0.0001), 0.0, 1.0)
		return lerpf(float(body["level"]), float(body["level_end"]), t)
	return float(body["level"])

func estimate(dry: Callable, datum: float, freeboard: float, sea_level: float = NAN, abort: BuildAbort = null) -> void:
	for id in bodies.size():
		if abort != null and abort.requested:
			return
		var body: Dictionary = bodies[id]
		if bool(body["tidal"]):
			body["level"] = datum if is_nan(sea_level) else sea_level
			if body.has("axis"):
				body["level_end"] = body["level"]
			continue
		var samples: Array[float] = []
		var inside := INF
		var rings: Array = [body["points"]]
		rings.append_array(body["holes"])
		for ring in rings:
			for i in ring.size():
				var cut := ShoreGeometry.clip_segment(ring[i], ring[(i + 1) % ring.size()], bounds)
				if cut.size() != 2:
					continue
				var d := cut[1] - cut[0]
				var n := Vector2(-d.y, d.x).normalized()
				var count := maxi(1, ceili(d.length() / 20.0))
				for j in count:
					var p := cut[0].lerp(cut[1], (float(j) + 0.5) / float(count))
					inside = minf(inside, float(dry.call(p.x, p.y)))
					for sign in [-1.0, 1.0]:
						var q: Vector2 = p + n * sign * 15.0
						if bounds.has_point(q) and at(q) < 0:
							samples.append(float(dry.call(q.x, q.y)))
		if samples.size() >= 3:
			samples.sort()
			body["level"] = samples[samples.size() / 10] - freeboard
		else:
			body["level"] = inside - freeboard if not is_inf(inside) else datum
			if not is_inf(inside):
				diagnostics.append({"kind": "level_fallback", "body": id})
		if str(body["kind"]) == "channel":
			var axis: PackedVector2Array = body["axis"]
			var d := (axis[1] - axis[0]).normalized()
			var n := Vector2(-d.y, d.x) * 15.0
			body["level"] = minf(float(dry.call(axis[0].x + n.x, axis[0].y + n.y)),
				float(dry.call(axis[0].x - n.x, axis[0].y - n.y))) - freeboard
			body["level_end"] = minf(float(dry.call(axis[1].x + n.x, axis[1].y + n.y)),
				float(dry.call(axis[1].x - n.x, axis[1].y - n.y))) - freeboard
	_merge_levels()
	_join_channel_levels()

func _join_channel_levels() -> void:
	var endpoints := {}
	for body in bodies:
		if not body.has("axis"):
			continue
		var axis: PackedVector2Array = body["axis"]
		for i in 2:
			var p := ShoreGeometry.snap(axis[i])
			var level_value := float(body["level"] if i == 0 else body["level_end"])
			# A channel ending in a mapped basin inherits that endpoint's
			# level. A second dry-bank estimate must not make a step at a
			# tidal canal mouth or at a lake inlet.
			for id in cells.get(Vector2i(floori(p.x / CELL), floori(p.y / CELL)), []):
				var other: Dictionary = bodies[id]
				if str(other["kind"]) != "channel" and (other["index"] as PolygonIndex).contains(p):
					level_value = float(other["level"])
					break
			endpoints[p] = minf(float(endpoints.get(p, INF)), level_value)
	for body in bodies:
		if body.has("axis"):
			body["level"] = endpoints[ShoreGeometry.snap(body["axis"][0])]
			body["level_end"] = endpoints[ShoreGeometry.snap(body["axis"][1])]

func _merge_levels() -> void:
	# Only actually touching/overlapping polygons join. Nearby lake bounds
	# do not establish hydraulic connectivity, and river profiles stay graded.
	var parent: Array[int] = []
	for id in bodies.size():
		parent.append(id)
	for id in bodies.size():
		var body: Dictionary = bodies[id]
		if str(body["kind"]) == "channel":
			continue
		var rings: Array = [body["points"]]
		rings.append_array(body["holes"])
		for ring in rings:
			for i in ring.size():
				var p: Vector2 = (ring[i] + ring[(i + 1) % ring.size()]) * 0.5
				if not bounds.has_point(p):
					continue
				var other := at(p, id)
				if other >= 0 and str(bodies[other]["kind"]) != "channel":
					var a := _root(parent, id)
					var b := _root(parent, other)
					parent[maxi(a, b)] = mini(a, b)
	var levels := {}
	var tidal := {}
	for id in bodies.size():
		var group := _root(parent, id)
		levels[group] = maxf(float(levels.get(group, -INF)), float(bodies[id]["level"]))
		if bool(bodies[id]["tidal"]):
			tidal[group] = float(bodies[id]["level"])
	for id in bodies.size():
		var group := _root(parent, id)
		bodies[id]["level"] = tidal.get(group, levels[group])

static func _root(parent: Array[int], id: int) -> int:
	while parent[id] != id:
		id = parent[id]
	return id

func state() -> Array:
	var out: Array = []
	for body in bodies:
		var saved: Dictionary = body.duplicate()
		saved.erase("index")
		out.append(saved)
	return out

func restore(saved: Array, box: Rect2) -> void:
	bounds = box
	bodies.clear()
	cells.clear()
	for body in saved:
		_add(body["points"], body["holes"], body)
	_setup_native()

func _setup_native() -> void:
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShoreDomainIndex"):
		native = ClassDB.instantiate("ShoreDomainIndex")
		native.setup(bodies, cells)
