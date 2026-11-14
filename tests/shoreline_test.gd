extends SceneTree

## Offline shared-shoreline contracts. Always run with --headless.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _data() -> LocationData:
	var data := LocationData.new()
	data.grid_size = 32
	data.heights.resize(32 * 32)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array([
		Vector2(0, -600), Vector2(600, -600), Vector2(600, 600), Vector2(0, 600)]), "holes": []}]
	return data

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	_check(ground.shoreline != null and ground.shoreline.ready, "shared model should be finalized")
	_check(ground.water_at(10, 0) >= 1.99, "mapped water should cover its bed at a sub-post shoreline")
	_check(is_zero_approx(ground.water_at(-1, 0)), "mapped dry side should not flood through interpolation")
	_check(ground.height_at_world(0.1, 0) <= ground.water_level_at(0.1, 0) - 1.99, "no exposed ramp inside water")
	_check(absf(ground.dry_height_at_world(10, 0) - 3.0) < 0.05, "dry height inside water should be the pre-carve bank, not the bed")
	_check(absf(ground.dry_height_at_world(-10, 0) - 3.0) < 0.05, "dry height on land should match the final surface")
	_check(ground.shoreline.hard_count() == 0, "unmapped rural bank should remain natural")
	for diagnostic in ground.shoreline.diagnostics:
		_check(str(diagnostic["kind"]) != "patch_failure", "natural patch must cover its complete cell")
	_check(absf(float(WaterBuilder._poly_levels(data, ground, ground.water_level_m)[0]) - ground.water_level_at(10, 0)) < 0.001,
		"carving and water builder should use the identical level")
	# Query the actual stored triangles, not a second implementation of carving.
	for key in ground.shoreline.patches:
		var patch: Dictionary = ground.shoreline.patches[key]
		var triangles: PackedVector3Array = patch["triangles"]
		for i in range(0, triangles.size(), 3):
			var c := (triangles[i] + triangles[i + 1] + triangles[i + 2]) / 3.0
			_check(absf(ground.height_at_world(c.x, c.z) - c.y) < 0.05, "placement and patch triangle should agree")
	# Islands are dry even if the DEM puts them below the water datum.
	data.land_polygons[0]["holes"] = [PackedVector2Array([
		Vector2(150, -70), Vector2(250, -70), Vector2(250, 70), Vector2(150, 70)])]
	var island := GroundTruth.new(data)
	_check(is_zero_approx(island.water_at(200, 0)), "water domains should preserve an island hole")
	# An explicit wall wins over natural cover only on the matching edge.
	data.shore_structures = [{"points": PackedVector2Array([Vector2(0, -500), Vector2(0, 500)]), "kind": "quay", "id": "way:wall"}]
	var explicit := GroundTruth.new(data)
	_check(explicit.shoreline.hard_count() > 0, "mapped quay should generate hard-bank constraints")
	_check(absf(explicit.height_at_world(-0.01, 0) - 3.0) < 0.05, "hard bank should retain its dry top")
	_check(absf(explicit.height_at_world(0, 0) - 3.0) < 0.05, "exact hard-shore query on a grid edge should select the land-side top")
	_check(explicit.height_at_world(0.1, 0) < -4.9, "hard bank should have a submerged bed beside its wall")
	_water_packing_fixture(data, explicit)
	_check(not ShoreBankMesh.transition_caps(explicit.shoreline).is_empty(), "hard-to-natural bank changes should have closed masonry returns")
	var crossed_caps: Array = []
	ShoreBankMesh._append_cap(crossed_caps, Vector3(0, 2, 0), Vector3(1, 0, 0), Vector3.ZERO, Vector3(1, 2, 0), Vector3.FORWARD)
	_check(crossed_caps.size() == 2, "crossing surface heights should split a transition cap at the crossing")
	var restored: ShorelineModel = ShorelineModel.from_state(explicit.shoreline.state())
	var cache_path := "user://shoreline-contract-%d.bin" % OS.get_process_id()
	var cache_file := FileAccess.open(cache_path, FileAccess.WRITE)
	cache_file.store_buffer(var_to_bytes(WorldCache._ground_state(explicit)))
	cache_file.close()
	var cached_ground := WorldCache._load_ground(cache_path, data)
	_check(cached_ground != null and cached_ground.shoreline.hard_count() == explicit.shoreline.hard_count(), "world ground payload should restore shared classification")
	if cached_ground != null:
		_check(absf(cached_ground.height_at_world(0, 0) - explicit.height_at_world(0, 0)) < 0.001, "restored ground should select the same exact bank top")
		_check(absf(cached_ground.water_at(80, 80) - explicit.water_at(80, 80)) < 0.001, "restored domains must retain authoritative water levels and depth")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cache_path))
	var dry_data := _data()
	dry_data.land_polygons.clear()
	dry_data.heights.fill(-10.0)
	var dry_ground := GroundTruth.new(dry_data)
	cache_file = FileAccess.open(cache_path, FileAccess.WRITE)
	cache_file.store_buffer(var_to_bytes(WorldCache._ground_state(dry_ground)))
	cache_file.close()
	var cached_dry := WorldCache._load_ground(cache_path, dry_data)
	_check(cached_dry != null and cached_dry.water_at(0, 0) == dry_ground.water_at(0, 0), "a cached dry depression must retain authoritative absence of water")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cache_path))
	_check(ShorelineModel.from_state({"patches": {}}) == null, "incomplete legacy shoreline cache must be rejected")
	_check(restored.hard_count() == explicit.shoreline.hard_count(), "cache should preserve bank classification")
	ShoreGeometry.force_script = true
	var script_copy: ShorelineModel = ShorelineModel.from_state(explicit.shoreline.state())
	ShoreGeometry.force_script = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 521
	for i in 2000:
		var p := Vector2(rng.randf_range(-150, 300), rng.randf_range(-550, 550))
		_check(absf(restored.height(p) - script_copy.height(p)) < 0.01, "indexed native and script patch sampling must select equivalent triangles")
	for p in [Vector2(-0.1, 0), Vector2(0.1, 0), Vector2(200, 0), Vector2(80, 80)]:
		_check(absf(restored.height(p) - explicit.height_at_world(p.x, p.y)) < 0.001, "cache should preserve corrected surface")
	# Conservative evidence uses actual footprints and paving, not a city zone.
	data.shore_structures.clear()
	data.buildings = [{"x": -15.0, "z": 0.0, "size_x": 10.0, "size_z": 100.0}]
	data.roads = [{"class": "pedestrian", "surface": "paving_stones", "width_m": 3.0,
		"points": PackedVector2Array([Vector2(-4, -100), Vector2(-4, 100)])}]
	var inferred := GroundTruth.new(data)
	_check(inferred.shoreline.hard_count() > 0, "nearby paving plus frontage should support inference")
	for surface in ["unhewn_cobblestone", "bricks", "concrete:plates"]:
		data.roads[0]["surface"] = surface
		for force_script in [false, true]:
			ShoreGeometry.force_script = force_script
			var evidence := ShoreEvidence.new(data)
			var result := evidence.classify(Vector2(0, -10), Vector2(0, 10), Vector2(-1, 0))
			_check(str(result.get("kind", "")) == "hard", "%s should support paving inference (script=%s)" % [surface, force_script])
	ShoreGeometry.force_script = false
	data.roads[0]["surface"] = "paving_stones"
	var urban_only := data.roads.duplicate(true)
	data.roads.clear()
	data.land_polygons.append({"class": "urban", "points": PackedVector2Array([
		Vector2(-100, -100), Vector2(0, -100), Vector2(0, 100), Vector2(-100, 100)])})
	_check(GroundTruth.new(data).shoreline.hard_count() == 0, "urban land use alone must not count as mapped paving")
	data.land_polygons.pop_back()
	data.roads = urban_only
	data.land_polygons.append({"class": "grass", "points": PackedVector2Array([
		Vector2(-100, -100), Vector2(-0.01, -100), Vector2(-0.01, 100), Vector2(-100, 100)])})
	var park := GroundTruth.new(data)
	var grass_edges := 0
	for segment in park.shoreline.segments:
		var mid: Vector2 = (segment["a"] + segment["b"]) * 0.5
		if absf(mid.x) < 0.1 and absf(mid.y) < 90:
			grass_edges += 1
			_check(str(segment["kind"]) == "natural", "explicit grass must veto inferred paving")
	_check(grass_edges > 0, "fixture should exercise mapped grass at the shoreline")
	# True hole-aware script fallback: exact area, not centroid filtering.
	var outer := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var holes := [PackedVector2Array([Vector2(3, 3), Vector2(7, 3), Vector2(7, 7), Vector2(3, 7)])]
	var native := ShoreGeometry.triangulate(outer, holes)
	ShoreGeometry.force_script = true
	var script := ShoreGeometry.triangulate(outer, holes)
	ShoreGeometry.force_script = false
	_check(absf(ShoreGeometry.area(script) - 84.0) < 0.001, "script triangulation should preserve holes")
	_check(absf(ShoreGeometry.area(script) - ShoreGeometry.area(native)) < 0.001, "native and script should preserve equivalent area")
	# Two open coastline runs bound a dry peninsula. Independent water
	# closures would union across it and flood the centre of Stockholm.
	var coast_diagnostics: Array = []
	var coasts := ShoreCoast.domains([
		{"class": "coastline", "points": PackedVector2Array([Vector2(-20, -100), Vector2(-20, 100)])},
		{"class": "coastline", "points": PackedVector2Array([Vector2(20, 100), Vector2(20, -100)])}],
		Rect2(-100, -100, 200, 200), coast_diagnostics)
	var wet_centre := false
	var wet_left := false
	var wet_right := false
	for coast in coasts:
		var index := PolygonIndex.new(coast["points"], coast["holes"])
		wet_centre = wet_centre or index.contains(Vector2.ZERO)
		wet_left = wet_left or index.contains(Vector2(-60, 0))
		wet_right = wet_right or index.contains(Vector2(60, 0))
	_check(not wet_centre and wet_left and wet_right, "shared coast topology must preserve a peninsula")
	_check(coast_diagnostics.is_empty(), "valid peninsula should have closed coast domains")
	# A partial OSM extract may include closed islands and a mainland
	# coastline that ends inside the extent. It cannot establish open sea
	# across the entire extent.
	var island_ring := PackedVector2Array([Vector2(-10, -10), Vector2(-10, 10), Vector2(10, 10), Vector2(10, -10), Vector2(-10, -10)])
	var partial_diagnostics: Array = []
	var partial := ShoreCoast.domains([
		{"class": "coastline", "points": island_ring},
		{"class": "coastline", "points": PackedVector2Array([Vector2(-50, -100), Vector2(-50, 0)])}],
		Rect2(-100, -100, 200, 200), partial_diagnostics)
	_check(partial.is_empty() and not partial_diagnostics.is_empty(), "incomplete mainland must not turn closed islands into an extent-wide sea")
	var partial_with_outer := ShoreCoast.domains([
		{"class": "coastline", "points": island_ring},
		{"class": "coastline", "points": PackedVector2Array([Vector2(40, -100), Vector2(40, 100)])},
		{"class": "coastline", "points": PackedVector2Array([Vector2(-50, -100), Vector2(-50, 0)])}],
		Rect2(-100, -100, 200, 200), [])
	_check(partial_with_outer.is_empty(), "incomplete mainland must also veto otherwise closed sea domains")
	# A run the OSM query clipped a few metres short of the extent edge still
	# closes (Lauttasaari: 11.6 m short dropped the whole near sea).
	var short_diagnostics: Array = []
	var short := ShoreCoast.domains([
		{"class": "coastline", "points": PackedVector2Array([Vector2(20, -100), Vector2(20, 100 - 11.6 * WorldScale.metres_to_units())])}],
		Rect2(-100, -100, 200, 200), short_diagnostics)
	var short_wet := false
	var short_dry := true
	for coast in short:
		var index := PolygonIndex.new(coast["points"], coast["holes"])
		short_wet = short_wet or index.contains(Vector2(-50, 0))
		short_dry = short_dry and not index.contains(Vector2(60, 0))
	_check(short_diagnostics.is_empty() and short_wet and short_dry, "a coastline ending just short of the edge must still close its sea")
	var complete := ShoreCoast.domains([{"class": "coastline", "points": island_ring}], Rect2(-100, -100, 200, 200), [])
	_check(complete.size() == 1 and (PolygonIndex.new(complete[0]["points"], complete[0]["holes"]) as PolygonIndex).contains(Vector2(50, 50)), "complete island-only coast should retain surrounding sea")
	var cancelled := BuildAbort.new()
	cancelled.requested = true
	var stopped := GroundTruth.new(_data(), cancelled)
	_check(stopped.shoreline == null or not stopped.shoreline.ready, "cancelled shoreline must never be finalized")
	var raw := {"elements": []}
	for entry in [["quay", {"man_made": "quay", "material": "stone", "height": "2.5"}],
		["retaining_wall", {"barrier": "retaining_wall"}], ["embankment", {"embankment": "yes"}]]:
		raw["elements"].append({"type": "way", "id": raw["elements"].size() + 1, "tags": entry[1],
			"geometry": [{"lat": 48.0, "lon": 2.0}, {"lat": 48.0001, "lon": 2.0}]})
	var parsed := OsmParser.parse_features(JSON.stringify(raw), 48.0, 2.0)
	_check(parsed["shore_structures"].size() == 3, "OSM should normalize all three shore structure kinds")
	_check(parsed["shore_structures"][0]["id"] == "way:1" and absf(parsed["shore_structures"][0]["height_m"] - 2.5) < 0.001,
		"OSM shore structures should retain source identity and measured height")
	_check(OsmParser.parse_features("{}", 0, 0)["shore_structures"].is_empty(), "old OSM payloads should default to no explicit structures")
	var coast_payload := JSON.stringify({"elements": [{"type": "way", "id": 9,
		"tags": {"natural": "coastline"}, "geometry": [{"lat": 48.0, "lon": 2.0}, {"lat": 48.0001, "lon": 2.0}]}]})
	var coast_features := OsmParser.parse_features(coast_payload, 48.0, 2.0)
	_check(OsmFetcher._detailed_check(48.0, 2.0).call(coast_payload) == "", "a mapped natural coast must be usable without buildings")
	var fetcher := OsmFetcher.new()
	fetcher.offline_mode = true
	fetcher._detailed_cached = true
	var delivered := [false]
	fetcher.succeeded.connect(func(_b, _r, _l, _m) -> void: delivered[0] = true)
	fetcher._on_parsed(fetcher._parse_gen, coast_features)
	_check(delivered[0], "offline cached coast-only payloads must retain their water geometry")
	fetcher.free()
	var canal := _data()
	canal.land_polygons.clear()
	canal.waterways = [{"class": "canal", "width_m": 20.0,
		"points": PackedVector2Array([Vector2(-300, 0), Vector2(0, 0), Vector2(0, 300)])}]
	var curved := GroundTruth.new(canal)
	_check(curved.water_at(6, -6) > 0.0, "width-aware channels must keep their outside corner connected")
	_check(curved.water_at(30, -30) == 0.0, "channel bends must retain land beyond their mapped width")
	_water_packing_fixture(canal, curved)
	var pond := _data()
	pond.land_polygons[0]["points"] = PackedVector2Array([Vector2(3, 3), Vector2(4, 3), Vector2(4, 4), Vector2(3, 4)])
	var tiny := GroundTruth.new(pond)
	_check(tiny.water_at(3.5, 3.5) >= 1.99 and tiny.water_at(4.5, 3.5) == 0.0, "sub-post ponds should be carved only inside their outline")
	var reference := _data()
	var accelerated := GroundTruth.new(reference)
	ShoreGeometry.force_script = true
	var fallback := GroundTruth.new(reference)
	ShoreGeometry.force_script = false
	for p in [Vector2(-1, 0), Vector2(1, 0), Vector2(50, 100), Vector2(599, 0), Vector2(601, 0)]:
		_check(absf(accelerated.height_at_world(p.x, p.y) - fallback.height_at_world(p.x, p.y)) < 0.01,
			"native-disabled shoreline should preserve the same surface")
		_check(absf(accelerated.water_at(p.x, p.y) - fallback.water_at(p.x, p.y)) < 0.01,
			"native-disabled shoreline should preserve the same water coverage")
	_topology_fixtures()
	_stitch_fixture()
	_rendered_surface_fixture()
	_bridge_and_far_fixture()
	_area_packing_fixture()
	if failures.is_empty():
		print("SHORELINE OK: exact coverage, natural and hard banks, evidence, queries, cache, hole fallback")
		quit(0)
	else:
		for failure in failures:
			printerr("SHORELINE FAIL: ", failure)
		quit(1)

func _topology_fixtures() -> void:
	var diagonal := PackedVector2Array([Vector2(-100, -100), Vector2(100, 100), Vector2(300, -100)])
	var d := _data()
	d.land_polygons[0]["points"] = diagonal
	var forward := GroundTruth.new(d)
	diagonal.reverse()
	d.land_polygons[0]["points"] = diagonal
	var reversed := GroundTruth.new(d)
	for p in [Vector2(70, 0), Vector2(140, -40), Vector2(-80, 70)]:
		_check(is_equal_approx(forward.water_at(p.x, p.y), reversed.water_at(p.x, p.y)), "polygon winding must not change shore coverage")
	d.land_polygons = [
		{"class": "water", "points": PackedVector2Array([Vector2(-200, -200), Vector2(0, -200), Vector2(0, 200), Vector2(-200, 200)])},
		{"class": "water", "points": PackedVector2Array([Vector2(0, -200), Vector2(200, -200), Vector2(200, 200), Vector2(0, 200)])}]
	var joined := GroundTruth.new(d)
	for s in joined.shoreline.segments:
		_check(not (absf(s["a"].x) < 0.01 and absf(s["b"].x) < 0.01), "adjoining water pieces must not generate an internal bank")
	_check(absf(joined.water_level_at(-1, 0) - joined.water_level_at(1, 0)) < 0.001, "adjoining basins must share a level")
	d.land_polygons[0]["points"] = PackedVector2Array([
		Vector2(-500, -80), Vector2(-300, -80), Vector2(-300, 80), Vector2(-500, 80)])
	d.land_polygons[1]["points"] = PackedVector2Array([
		Vector2(300, -80), Vector2(500, -80), Vector2(500, 80), Vector2(300, 80)])
	for z in d.grid_size:
		for x in d.grid_size:
			d.heights[z * d.grid_size + x] = 3.0 + float(x) * 20.0 / float(d.grid_size - 1)
	var lakes := GroundTruth.new(d)
	_check(lakes.water_level_at(400, 0) - lakes.water_level_at(-400, 0) > 3.0, "independent inland lakes must retain legitimate elevation differences")
	d.heights.fill(-2.0)
	d.water_level = 0.5
	d.centre_elevation_m = -2.0
	d.land_polygons[1]["tidal"] = true
	var polder := GroundTruth.new(d)
	_check(polder.asl_y(polder.water_level_at(-400, 0)) < -2.0, "a disconnected inland basin below sea level must not be clamped to the sea datum")
	_check(absf(polder.asl_y(polder.water_level_at(400, 0)) - 0.5) < 0.001, "the adjacent tidal basin must retain its authoritative sea level")
	d = _data()
	d.shore_structures = [{"points": PackedVector2Array([Vector2(600, -600), Vector2(600, 600)]), "kind": "quay", "id": "way:boundary"}]
	var boundary := GroundTruth.new(d)
	for p in [Vector2(1, -1199), Vector2(1, 1124)]:
		_check(boundary.shoreline.domains.at(p) < 0, "unmapped extent strips must remain dry")
	for s in boundary.shoreline.segments:
		_check(not boundary.shoreline._extent_edge(s["a"], s["b"]), "extent closures must never produce wall runs")
	# Concave land notch must survive a local cell subdivision.
	d.land_polygons[0]["points"] = PackedVector2Array([Vector2(-80, -80), Vector2(80, -80),
		Vector2(80, 0), Vector2(0, 0), Vector2(0, 80), Vector2(-80, 80)])
	var concave := GroundTruth.new(d)
	_check(concave.water_at(-20, 20) > 0.0 and concave.water_at(20, 20) == 0.0, "concave shoreline must preserve its dry notch")

func _stitch_fixture() -> void:
	var model := ShorelineModel.new()
	model.size = 3
	model.step = 10.0
	model.origin = 0.0
	model.patches[Vector2i(0, 0)] = {"triangles": PackedVector3Array([
		Vector3.ZERO, Vector3(10, 0, 0), Vector3(10, 0, 10),
		Vector3.ZERO, Vector3(10, 0, 10), Vector3(5, 2, 10),
		Vector3.ZERO, Vector3(5, 2, 10), Vector3(0, 0, 10)]),
		"owners": PackedInt32Array([-1, -1, -1]), "hard": PackedByteArray([0, 0, 0]), "paving": PackedByteArray([0, 0, 0])}
	model.patches[Vector2i(0, 1)] = {"triangles": PackedVector3Array([
		Vector3(0, 0, 10), Vector3(10, 0, 10), Vector3(0, 0, 20),
		Vector3(10, 0, 10), Vector3(10, 0, 20), Vector3(0, 0, 20)]),
		"owners": PackedInt32Array([-1, -1]), "hard": PackedByteArray([0, 0]), "paving": PackedByteArray([0, 0])}
	ShoreStitch.build(model)
	_check(absf(model._patch_height(Vector2(5, 10), model.patches[Vector2i(0, 1)]) - 2.0) < 0.001,
		"adjacent patches must share a curved edge station rather than leaving a T-junction crack")
	var area := 0.0
	for patch in model.patches.values():
		var points: PackedVector3Array = patch["triangles"]
		for i in range(0, points.size(), 3):
			area += ShoreGeometry.area(PackedVector2Array([Vector2(points[i].x, points[i].z),
				Vector2(points[i + 1].x, points[i + 1].z), Vector2(points[i + 2].x, points[i + 2].z)]))
	_check(absf(area - 200.0) < 0.001, "edge stitching must preserve surface coverage")

func _rendered_surface_fixture() -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	for preset in [0, 3]:
		data.quality_preset = preset
		var mesh := TerrainBuilder._terrain_mesh(data, ground)
		var arrays: Array = mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		_check(not vertices.is_empty(), "terrain fixture must inspect real mesh vertices")
		for vertex in vertices:
			_check(ground.shoreline.bounds.grow(0.011).has_point(Vector2(vertex.x, vertex.z)), "terrain posts and patches must share the same extent and spacing")
		for i in range(0, indices.size(), 3):
			var c := (vertices[indices[i]] + vertices[indices[i + 1]] + vertices[indices[i + 2]]) / 3.0
			_check(absf(ground.height_at_world(c.x, c.z) - c.y) < 0.05, "rendered terrain interiors and placement queries must agree")
		var surface := RoadBuilder._Surface.new(data, ground)
		_check(is_equal_approx(surface.mesh_step, ground._step_units), "road draping must use the canonical terrain spacing")
		ShoreGeometry.force_script = true
		var script_mesh := TerrainBuilder._terrain_mesh(data, ground)
		ShoreGeometry.force_script = false
		var reference: Array = script_mesh.mesh.surface_get_arrays(0)
		for attribute in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
			_check(arrays[attribute].size() == reference[attribute].size(), "native patch packing must preserve vertex/attribute counts")
			for i in mini(arrays[attribute].size(), reference[attribute].size()):
				var equal: bool = arrays[attribute][i].is_equal_approx(reference[attribute][i])
				_check(equal, "native patch packing must preserve rendered attributes")
		_check(arrays[Mesh.ARRAY_INDEX] == reference[Mesh.ARRAY_INDEX], "native packing must preserve triangle connectivity")
		script_mesh.free()
		mesh.free()

func _bridge_and_far_fixture() -> void:
	var data := _data()
	data.shore_structures = [{"points": PackedVector2Array([Vector2(0, -500), Vector2(0, 500)]), "kind": "quay", "id": "way:quay"}]
	data.roads = [{"bridge": true, "width_m": 8.0, "osm_id": "way:bridge",
		"points": PackedVector2Array([Vector2(-30, 0), Vector2(30, 0)])}]
	var bridge := GroundTruth.new(data)
	var checked := 0
	for segment in bridge.shoreline.segments:
		var mid: Vector2 = (segment["a"] + segment["b"]) * 0.5
		if absf(mid.x) < 0.01 and absf(mid.y) < 2.0:
			checked += 1
			_check(str(segment["reason"]) == "mapped_access" and str(segment["kind"]) != "hard", "mapped bridges must interrupt masonry runs")
	_check(checked > 0 and bridge.shoreline.hard_count() > 0, "bridge fixture must retain supported quays beyond its crossing")
	data = _data()
	data.land_polygons[0]["points"] = PackedVector2Array([Vector2(0, -2000), Vector2(2000, -2000), Vector2(2000, 2000), Vector2(0, 2000)])
	data.far_grid_size = 4
	data.far_heights.resize(16)
	data.far_heights.fill(50.0)
	var ground := GroundTruth.new(data)
	var surf := FarTerrainBuilder._surface(data)
	var edge: float = ground.shoreline.bounds.end.x
	var inner := FarSampler._blend_height(data, ground, surf, edge - 0.1, 0)
	var outer := FarSampler._blend_height(data, ground, surf, edge + 0.1, 0)
	_check(inner < ground.water_level_at(edge - 0.1, 0) - 1.9, "far overlap must not lift the wet detailed surface back to DEM bank height")
	_check(absf(inner - outer) < 0.01, "corrected detailed terrain must join the far surface continuously")
	if ClassDB.class_exists("FarKernels"):
		var radii: Array[float] = [edge - 0.1]
		var positions := FarSampler.native_ring_positions(data, ground, surf, radii, 4)
		for p in positions:
			_check(absf(p.y - FarSampler._blend_height(data, ground, surf, p.x, p.z)) < 0.01, "native far join must use the same corrected boundary as the script path")

func _water_packing_fixture(data: LocationData, ground: GroundTruth) -> void:
	var native := WaterBuilder.build_water(data, ground)
	ShoreGeometry.force_script = true
	var script := WaterBuilder.build_water(data, ground)
	ShoreGeometry.force_script = false
	var a: Array = []
	var b: Array = []
	for pair in [[native, a], [script, b]]:
		for child in pair[0].get_children():
			if child is MeshInstance3D and child.material_override is ShaderMaterial:
				pair[1].append(child.mesh.surface_get_arrays(0))
	_check(a.size() > 0 and a.size() == b.size(), "water packing fixture must compare matching water batches")
	for batch in mini(a.size(), b.size()):
		for attribute in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV2]:
			_check(a[batch][attribute].size() == b[batch][attribute].size(), "native water packing must preserve vertex counts")
			for i in mini(a[batch][attribute].size(), b[batch][attribute].size()):
				_check(a[batch][attribute][i].is_equal_approx(b[batch][attribute][i]), "native water packing must preserve water position, colour and flow")
		_check(a[batch][Mesh.ARRAY_INDEX] == b[batch][Mesh.ARRAY_INDEX], "native water packing must preserve coverage/connectivity")
	native.free()
	script.free()

func _area_packing_fixture() -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	var accelerated := RoadBuilder._Surface.new(data, ground)
	accelerated.use_native()
	if accelerated.native == null or not accelerated.native.has_method("area"):
		return
	var fallback := RoadBuilder._Surface.new(data, ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	for i in 500:
		var p := Vector2(rng.randf_range(-200, 200), rng.randf_range(-300, 300))
		_check(absf(accelerated.native.height(p.x, p.y) - fallback.height(p.x, p.y)) < 0.05,
			"native road draping must use the same corrected terrain posts as the script path")
	var native_batch := RoadBuilder._Batch.new()
	var script_batch := RoadBuilder._Batch.new()
	var ring := PackedVector2Array([Vector2(-120, -100), Vector2(20, -100), Vector2(20, 100), Vector2(-120, 100)])
	RoadBuilder._area(native_batch, ring, [], accelerated, 0.1, 1.0)
	RoadBuilder._area(script_batch, ring, [], fallback, 0.1, 1.0)
	_check(native_batch.indices == script_batch.indices, "native paved-area clipping must preserve triangle connectivity")
	_check(native_batch.verts.size() == script_batch.verts.size(), "native paved-area clipping must preserve vertex counts")
	var same := true
	for i in mini(native_batch.verts.size(), script_batch.verts.size()):
		if not native_batch.verts[i].is_equal_approx(script_batch.verts[i]) or not native_batch.uvs[i].is_equal_approx(script_batch.uvs[i]):
			same = false
			break
	_check(same, "native paved-area clipping must preserve positions and texture coordinates")
