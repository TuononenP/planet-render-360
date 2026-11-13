class_name ShorelineModel
extends RefCounted

## Immutable after finish(): shared water ownership, bank evidence and
## canonical shoreline triangles. No builder recomputes this state.
var domains: ShoreDomains
var segments: Array = []
var edge_cells: Dictionary = {}
var patches: Dictionary = {}
var diagnostics: Array = []
var dry := PackedFloat32Array()
var base := PackedFloat32Array()
var land := PackedFloat32Array()
var size := 0
var step := 1.0
var origin := 0.0
var bounds := Rect2()
var depth := 2.0
var ready := false
var _edges: Array = []
var _evidence: ShoreEvidence
var _class_cache := {}
var _segment_cells := {}
var transition_edges: Array = []
var transition_cells := {}
var _vertex_heights := {}
var sampler: Object = null

func _init(data: LocationData = null, ground = null, sea_level: float = NAN, abort: BuildAbort = null) -> void:
	if data == null or ground == null:
		return
	size = ground._size
	step = ground._step_units
	origin = -float(size) * 0.5 * step
	bounds = Rect2(Vector2.ONE * origin, Vector2.ONE * step * float(size - 1))
	dry = ground._surface.duplicate()
	domains = ShoreDomains.new(data, bounds, abort)
	if abort != null and abort.requested:
		return
	domains.estimate(Callable(self, "dry_height"), ground.water_level_m, ground.FREEBOARD_M, sea_level, abort)
	domains.lower_under_bridges(data.roads, Callable(self, "dry_height"))
	_evidence = ShoreEvidence.new(data)
	_index_edges()

func empty() -> bool:
	return domains == null or domains.bodies.is_empty()

func dry_height(x: float, z: float) -> float:
	return _grid_height(dry, Vector2(x, z))

## Corrected dry surface: pre-carve height inside water, the final
## surface elsewhere (roads and grading included), in render units.
func land_height(x: float, z: float) -> float:
	if land.is_empty():
		return dry_height(x, z)
	return _grid_height(land, Vector2(x, z))

func _grid_height(values: PackedFloat32Array, p: Vector2) -> float:
	if size < 2 or values.is_empty():
		return 0.0
	var f := (p - Vector2.ONE * origin) / step
	f = f.clamp(Vector2.ZERO, Vector2.ONE * float(size - 1))
	var x := mini(int(f.x), size - 2)
	var z := mini(int(f.y), size - 2)
	var tx := f.x - float(x)
	var tz := f.y - float(z)
	return lerpf(lerpf(values[z * size + x], values[z * size + x + 1], tx),
		lerpf(values[(z + 1) * size + x], values[(z + 1) * size + x + 1], tx), tz)

func cell_at(p: Vector2) -> Vector2i:
	return Vector2i(clampi(floori((p.x - origin) / step), 0, size - 2),
		clampi(floori((p.y - origin) / step), 0, size - 2))

func cell_box(key: Vector2i) -> Rect2:
	var a := ShoreGeometry.snap(Vector2.ONE * origin + Vector2(key) * step)
	var b := ShoreGeometry.snap(Vector2.ONE * origin + Vector2(key + Vector2i.ONE) * step)
	return Rect2(a, b - a)

func _index_edges() -> void:
	for id in domains.bodies.size():
		var body: Dictionary = domains.bodies[id]
		var rings: Array = [body["points"]]
		rings.append_array(body["holes"])
		for ring in rings:
			for i in ring.size():
				var cut := ShoreGeometry.clip_segment(ring[i], ring[(i + 1) % ring.size()], bounds)
				if cut.size() != 2:
					continue
				# Extent closure edges clip the world; they are not real shores.
				if _extent_edge(cut[0], cut[1]):
					continue
				var index := _edges.size()
				_edges.append({"a": cut[0], "b": cut[1], "body": id})
				var lo := cell_at(cut[0].min(cut[1]) - Vector2.ONE * 0.02)
				var hi := cell_at(cut[0].max(cut[1]) + Vector2.ONE * 0.02)
				for x in range(maxi(0, lo.x), mini(size - 2, hi.x) + 1):
					for z in range(maxi(0, lo.y), mini(size - 2, hi.y) + 1):
						var key := Vector2i(x, z)
						if ShoreGeometry.clip_segment(cut[0], cut[1], cell_box(key)).size() == 2:
							if not edge_cells.has(key):
								edge_cells[key] = []
							(edge_cells[key] as Array).append(index)

func _extent_edge(a: Vector2, b: Vector2) -> bool:
	for axis in 2:
		for edge in [bounds.position[axis], bounds.end[axis]]:
			if absf(a[axis] - edge) < 0.02 and absf(b[axis] - edge) < 0.02:
				return true
	return false

func carve(surface: PackedFloat32Array, levels: PackedFloat32Array) -> void:
	for id in domains.bodies.size():
		var body: Dictionary = domains.bodies[id]
		for index in (body["index"] as PolygonIndex).posts_inside(size, step, float(size) * 0.5):
			var p := Vector2(float(index % size), float(index / size)) * step + Vector2.ONE * origin
			var level := domains.level(id, p)
			surface[index] = minf(surface[index], level - depth)
			levels[index] = maxf(levels[index], level)
	# Scanline interiors can exclude the last row/column of an extent
	# closure. Those boundary posts must agree with the adjacent wet cell.
	for i in size:
		for post in [Vector2i(i, 0), Vector2i(i, size - 1), Vector2i(0, i), Vector2i(size - 1, i)]:
			var p := Vector2(post) * step + Vector2.ONE * origin
			var body := domains.at(p)
			if body >= 0:
				var index: int = post.y * size + post.x
				var level := domains.level(body, p)
				surface[index] = minf(surface[index], level - depth)
				levels[index] = maxf(levels[index], level)

func finish(ground, abort: BuildAbort = null) -> void:
	if abort != null and abort.requested:
		return
	var started := Time.get_ticks_msec()
	depth = ground.CARVE_DEPTH_M * WorldScale.metres_to_units()
	if not is_equal_approx(ground._y_scale, 1.0) or not is_zero_approx(ground.datum_m):
		for i in dry.size():
			dry[i] = ground.render_y(dry[i])
		for body in domains.bodies:
			body["level"] = ground.render_y(float(body["level"]))
			if body.has("level_end"):
				body["level_end"] = ground.render_y(float(body["level_end"]))
	base = ground._surface
	land = dry.duplicate()
	for i in land.size():
		if is_inf(ground._level[i]):
			land[i] = base[i]
	_classify(abort)
	var classified := Time.get_ticks_msec()
	if abort != null and abort.requested:
		return
	_setup_sampler()
	ShoreSurface.build(self, abort)
	ShoreStitch.build(self, abort)
	if abort != null and abort.requested:
		return
	print("SHORE TIMINGS classify=%d patches=%d" % [classified - started, Time.get_ticks_msec() - classified])
	diagnostics.append_array(domains.diagnostics)
	_evidence = null
	_class_cache.clear()
	_vertex_heights.clear()
	_setup_sampler()
	ready = true
	print("SHORELINE bodies=%d edges=%d patches=%d hard=%d diagnostics=%d" % [domains.bodies.size(),
		segments.size(), patches.size(), hard_count(), diagnostics.size()])

func _classify(abort: BuildAbort) -> void:
	var endpoint_tops := {}
	for edge in _edges:
		if abort != null and abort.requested:
			return
		var a: Vector2 = edge["a"]
		var b: Vector2 = edge["b"]
		var dir := (b - a).normalized()
		var n := Vector2(-dir.y, dir.x)
		var count := maxi(1, ceili(a.distance_to(b) / 2.0))
		for i in count:
			if abort != null and abort.requested:
				return
			var start := ShoreGeometry.snap(a.lerp(b, float(i) / float(count)))
			var end := ShoreGeometry.snap(a.lerp(b, float(i + 1) / float(count)))
			var mid := (start + end) * 0.5
			var left := domains.at(mid + n * 0.05)
			var right := domains.at(mid - n * 0.05)
			if (left >= 0) == (right >= 0):
				if left < 0:
					diagnostics.append({"kind": "ambiguous_shore", "body": edge["body"],
						"a": start, "b": end, "reason": "no_resolved_water_side"})
				continue
			var land := -n if left >= 0 else n
			var body: int = left if left >= 0 else right
			var cache_key := Vector3i(floori(mid.x / 10.0), floori(mid.y / 10.0), roundi(land.angle() * 12.0))
			if not _class_cache.has(cache_key):
				_class_cache[cache_key] = _evidence.classify(mid - dir * 5.0, mid + dir * 5.0, land)
			var treatment: Dictionary = (_class_cache[cache_key] as Dictionary).duplicate()
			var hard := str(treatment["kind"]) == "hard"
			var top_a := _bank_top(start, land) if hard else dry_height(start.x, start.y)
			var top_b := _bank_top(end, land) if hard else dry_height(end.x, end.y)
			var road_top := _abutment_top(treatment, mid)
			if hard and not is_nan(road_top):
				# A bridge abutment's top is the road's level at the bridge's end.
				top_a = road_top
				top_b = road_top
			if str(treatment["kind"]) == "hard" and (is_nan(top_a) or is_nan(top_b)):
				treatment = {"kind": "natural", "reason": "insufficient_dry_samples", "sources": []}
			if is_nan(top_a):
				top_a = dry_height(start.x, start.y)
			if is_nan(top_b):
				top_b = dry_height(end.x, end.y)
			treatment.merge({"a": start, "b": end, "land": land, "body": body,
				"top_a": top_a, "top_b": top_b, "water_a": domains.level(body, start), "water_b": domains.level(body, end)})
			var segment_id := segments.size()
			segments.append(treatment)
			var lo := cell_at(start.min(end) - Vector2.ONE * 0.01)
			var hi := cell_at(start.max(end) + Vector2.ONE * 0.01)
			for x in range(lo.x, hi.x + 1):
				for z in range(lo.y, hi.y + 1):
					var cell := Vector2i(x, z)
					if not _segment_cells.has(cell):
						_segment_cells[cell] = []
					(_segment_cells[cell] as Array).append(segment_id)
			if str(treatment["kind"]) == "hard":
				for endpoint in [[start, top_a], [end, top_b]]:
					if not endpoint_tops.has(endpoint[0]):
						endpoint_tops[endpoint[0]] = []
					(endpoint_tops[endpoint[0]] as Array).append(endpoint[1])
			# The raw edge keeps its resolved segments for local height lookup.
			if not edge.has("segments"):
				edge["segments"] = []
			(edge["segments"] as Array).append(segment_id)
	for segment in segments:
		if str(segment["kind"]) != "hard":
			continue
		for item in [["a", "top_a"], ["b", "top_b"]]:
			var values: Array = endpoint_tops[segment[item[0]]]
			var sum := 0.0
			for value in values:
				sum += float(value)
			segment[item[1]] = sum / float(values.size())
	_make_transitions()

func _make_transitions() -> void:
	var ends := {}
	for segment in segments:
		for p in [segment["a"], segment["b"]]:
			if not ends.has(p):
				ends[p] = []
			(ends[p] as Array).append(segment)
	for p in ends:
		var hard := false
		var natural := false
		var land_dir := Vector2.ZERO
		for segment in ends[p]:
			if str(segment["kind"]) == "hard":
				hard = true
				land_dir += segment["land"]
			else:
				natural = true
		if not hard or (not natural and (ends[p] as Array).size() > 1):
			continue
		var a: Vector2 = p
		var b := ShoreGeometry.snap(a + land_dir.normalized() * step)
		var id := transition_edges.size()
		transition_edges.append([a, b])
		var lo := cell_at(a.min(b))
		var hi := cell_at(a.max(b))
		for x in range(lo.x, hi.x + 1):
			for z in range(lo.y, hi.y + 1):
				var key := Vector2i(x, z)
				if not transition_cells.has(key):
					transition_cells[key] = []
				(transition_cells[key] as Array).append(id)

## The road's level (dry ground at the nearer end of the bridge) for a
## bank ShoreEvidence made an abutment, else NAN.
func _abutment_top(treatment: Dictionary, mid: Vector2) -> float:
	for source in treatment.get("sources", []):
		var ends: PackedVector2Array = _evidence.abutment_ends.get(str(source), PackedVector2Array())
		if ends.size() == 2:
			var near0 := ends[0].distance_squared_to(mid) <= ends[1].distance_squared_to(mid)
			var e := ends[0] if near0 else ends[1]
			if domains.at(e) < 0:
				return dry_height(e.x, e.y)
			# A bridge mapped ending over the water: the road's level is the
			# dry ground further out along its line.
			var out := (e - (ends[1] if near0 else ends[0])).normalized()
			var best := NAN
			for k in range(1, 11):
				var q := e + out * 2.0 * float(k) * WorldScale.metres_to_units()
				if bounds.has_point(q) and domains.at(q) < 0:
					best = dry_height(q.x, q.y) if is_nan(best) else maxf(best, dry_height(q.x, q.y))
			return best
	return NAN

func _bank_top(p: Vector2, land: Vector2) -> float:
	var values: Array[float] = []
	for distance in [2.0, 5.0, 10.0, 20.0]:
		var q: Vector2 = p + land * distance
		if bounds.has_point(q) and domains.at(q) < 0 and not _evidence.contains_kind(q, "building"):
			values.append(dry_height(q.x, q.y))
	if values.size() < 3:
		return NAN
	values.sort()
	return (values[(values.size() - 1) / 2] + values[values.size() / 2]) * 0.5

func nearest(p: Vector2, treatment: int = 0) -> Dictionary:
	if sampler != null and sampler.has_method("nearest_bank"):
		var match: Vector4 = sampler.nearest_bank(p, treatment)
		if match.x >= 0.0:
			return {"segment": segments[int(match.x)], "at": Vector2(match.y, match.z), "distance": match.w}
		return {}
	var key := cell_at(p)
	var seen := {}
	var best := INF
	var out := {}
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for id in _segment_cells.get(key + Vector2i(dx, dz), []):
				if seen.has(id):
					continue
				seen[id] = true
				var s: Dictionary = segments[id]
				if (treatment == 1 and str(s["kind"]) != "hard") or (treatment == 2 and str(s["kind"]) == "hard"):
					continue
				var q := Geometry2D.get_closest_point_to_segment(p, s["a"], s["b"])
				var distance := p.distance_to(q)
				if distance < best - 0.00001 or (absf(distance - best) <= 0.00001 and str(s["kind"]) == "hard" \
						and (out.is_empty() or str(out["segment"]["kind"]) != "hard")):
					best = distance
					out = {"segment": s, "at": q, "distance": distance}
	return out

func vertex_height(p: Vector2, body: int, bank: Dictionary = {}) -> float:
	var hard_region := body < 0 and not bank.is_empty() and str(bank["segment"]["kind"]) == "hard"
	var cache_key := Vector3i(roundi(p.x * 100.0), roundi(p.y * 100.0), -2 if hard_region else body)
	if _vertex_heights.has(cache_key):
		return _vertex_heights[cache_key]
	if body >= 0:
		var bed := minf(_grid_height(base, p), domains.level(body, p) - depth)
		_vertex_heights[cache_key] = bed
		return bed
	var h := _grid_height(land, p)
	bank = nearest(p, 1 if hard_region else 2)
	if not bank.is_empty() and float(bank["distance"]) < step:
		var s: Dictionary = bank["segment"]
		var d: Vector2 = s["b"] - s["a"]
		var t := clampf(((bank["at"] as Vector2) - (s["a"] as Vector2)).dot(d) / maxf(d.length_squared(), 0.0001), 0.0, 1.0)
		var rim := lerpf(float(s["top_a"]), float(s["top_b"]), t) if str(s["kind"]) == "hard" \
			else domains.level(int(s["body"]), p)
		h = lerpf(rim, h, clampf(float(bank["distance"]) / step, 0.0, 1.0))
	_vertex_heights[cache_key] = h
	return h

func height(p: Vector2) -> float:
	if sampler != null:
		return sampler.height(p.x, p.y)
	var cell := cell_at(p)
	var f := (p - Vector2.ONE * origin) / step
	var rounded := Vector2i(roundi(f.x), roundi(f.y))
	var edge_x := absf(p.x - (origin + float(rounded.x) * step)) <= 0.006
	var edge_z := absf(p.y - (origin + float(rounded.y) * step)) <= 0.006
	var lo := Vector2i(maxi(0, rounded.x - 1) if edge_x else cell.x, maxi(0, rounded.y - 1) if edge_z else cell.y)
	var hi := Vector2i(mini(size - 2, rounded.x) if edge_x else cell.x, mini(size - 2, rounded.y) if edge_z else cell.y)
	var best := -INF
	for x in range(lo.x, hi.x + 1):
		for z in range(lo.y, hi.y + 1):
			best = maxf(best, _patch_height(p, patches.get(Vector2i(x, z), {})))
	if not is_inf(best):
		return best
	var body := domains.at(p)
	return minf(_grid_height(base, p), domains.level(body, p) - depth) if body >= 0 else _grid_height(base, p)

func _patch_height(p: Vector2, patch: Dictionary) -> float:
	var best := -INF
	if not patch.is_empty():
		var triangles: PackedVector3Array = patch["triangles"]
		for i in range(0, triangles.size(), 3):
			var y := ShoreGeometry.triangle_height(p, triangles[i], triangles[i + 1], triangles[i + 2])
			if not is_nan(y):
				best = maxf(best, y)
	return best

func hard_count() -> int:
	var count := 0
	for segment in segments:
		if str(segment["kind"]) == "hard":
			count += 1
	return count

func state() -> Dictionary:
	return {"bodies": domains.state(), "segments": segments, "edge_cells": edge_cells, "edges": _edges, "segment_cells": _segment_cells,
		"patches": patches, "diagnostics": diagnostics, "dry": dry, "land": land, "base": base, "size": size,
		"step": step, "origin": origin, "bounds": bounds, "depth": depth}

static func from_state(saved: Dictionary):
	if not saved.has_all(["bodies", "segments", "segment_cells", "edges", "edge_cells", "patches", "diagnostics",
		"dry", "land", "base", "size", "step", "origin", "bounds", "depth"]):
		return null
	var count := int(saved["size"]) * int(saved["size"])
	if int(saved["size"]) < 2 or float(saved["step"]) <= 0.0 or saved["base"].size() != count \
			or saved["dry"].size() != count or saved["land"].size() != count:
		return null
	for patch in saved["patches"].values():
		if not (patch is Dictionary) or not patch.has_all(["triangles", "owners", "paving", "hard"]) \
				or patch["triangles"].size() % 3 != 0 or patch["owners"].size() != patch["triangles"].size() / 3 \
				or patch["paving"].size() != patch["owners"].size() or patch["hard"].size() != patch["owners"].size():
			return null
	var model := ShorelineModel.new()
	for field in ["segments", "edge_cells", "patches", "diagnostics", "dry", "land", "base", "size", "step", "origin", "bounds", "depth"]:
		model.set(field, saved[field])
	model._edges = saved["edges"]
	model._restore_indexes()
	model.domains = ShoreDomains.new()
	model.domains.restore(saved["bodies"], model.bounds)
	model._setup_sampler()
	model.ready = true
	return model

func _restore_indexes() -> void:
	edge_cells = {}
	_segment_cells = {}
	for pair in [[_edges, edge_cells], [segments, _segment_cells]]:
		var lines: Array = pair[0]
		var index: Dictionary = pair[1]
		for id in lines.size():
			var a: Vector2 = lines[id]["a"]
			var b: Vector2 = lines[id]["b"]
			var lo := cell_at(a.min(b) - Vector2.ONE * 0.02)
			var hi := cell_at(a.max(b) + Vector2.ONE * 0.02)
			for x in range(lo.x, hi.x + 1):
				for z in range(lo.y, hi.y + 1):
					var key := Vector2i(x, z)
					if ShoreGeometry.clip_segment(a, b, cell_box(key).grow(0.02)).size() != 2:
						continue
					if not index.has(key):
						index[key] = []
					(index[key] as Array).append(id)

func _setup_sampler() -> void:
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShoreSampler"):
		if sampler == null:
			sampler = ClassDB.instantiate("ShoreSampler")
		sampler.setup(base, patches, size, step, origin)
		if sampler.has_method("setup_banks"):
			sampler.setup_banks(segments)
		if sampler.has_method("setup_footing") and domains != null and domains.native != null:
			# Per body: level, level_end, has_end, axis start, axis end.
			var levels := PackedFloat64Array()
			for body: Dictionary in domains.bodies:
				var ends := body.has("level_end")
				var axis: PackedVector2Array = body["axis"] if ends else PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
				levels.append_array([float(body["level"]), float(body.get("level_end", 0.0)), 1.0 if ends else 0.0,
					axis[0].x, axis[0].y, axis[1].x, axis[1].y])
			sampler.setup_footing(domains.native, levels, dry if land.is_empty() else land, domains.bounds, bounds)

## BuildingFoundation's ground reads around one footprint, done natively
## (ShoreSampler.footing); empty without the native sampler.
func footing(ring: PackedVector2Array, centre: Vector2, sea_y: float, edge_step: float, max_n: int) -> PackedFloat64Array:
	if sampler == null or not sampler.has_method("footing"):
		return PackedFloat64Array()
	return sampler.footing(ring, centre, sea_y, edge_step, max_n)
