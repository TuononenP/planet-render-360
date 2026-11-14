extends SceneTree

## Native shore classification: godot --headless --path . --script tests/shore_classifier_test.gd
## ShorelineModel._classify through ShoreClassifier (native/, tools/build_native.sh)
## must leave exactly the script's segments, segment cells, diagnostics and
## edge segment lists: open water by a grass bank and with a mapped quay, an island, a canal
## through paved, built frontage, a road bridge on abutments and sloping
## banks. Skips, passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("ShoreClassifier"):
		print("SHORE_CLASSIFIER SKIP: ShoreClassifier is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var fixtures := _fixtures()
	var reasons := {}
	for name in fixtures:
		var out := {}
		for native in [true, false]:
			ShorelineModel.native_classify = native
			var model = GroundTruth.new(fixtures[name]).shoreline
			out[native] = [model.segments, model._segment_cells, model.diagnostics, model._edges,
				model.transition_edges, model.patches.keys()]
		ShorelineModel.native_classify = true
		var segments: Array = out[false][0]
		if segments.is_empty():
			failures.append("%s: no segments to compare" % name)
		for segment: Dictionary in segments:
			reasons[str(segment["reason"])] = true
			for source in segment["sources"]:
				if str(source).begins_with("abutment:"):
					reasons["abutment"] = true
		for k in (out[true] as Array).size():
			if var_to_bytes(out[true][k]) != var_to_bytes(out[false][k]):
				failures.append("%s: part %d differs" % [name, k])
	for wanted in ["mapped_structure", "natural_cover", "insufficient_evidence", "abutment"]:
		if not reasons.has(wanted):
			failures.append("no fixture exercises %s (saw %s)" % [wanted, str(reasons.keys())])
	if failures.is_empty():
		print("SHORE_CLASSIFIER PASS")
		quit(0)
	else:
		for f in failures:
			push_error("SHORE_CLASSIFIER FAIL: " + f)
		quit(1)

func _base() -> LocationData:
	var data := LocationData.new()
	data.grid_size = 32
	data.heights.resize(32 * 32)
	for i in 32 * 32:
		data.heights[i] = 3.0 + float(i % 32) * 0.15 + float(i / 32) * 0.05
	data.water_level = -3.0
	data.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array([
		Vector2(0, -600), Vector2(600, -600), Vector2(600, 600), Vector2(0, 600)]), "holes": []}]
	return data

func _fixtures() -> Dictionary:
	var open := _base()
	open.land_polygons.append({"class": "grass", "points": PackedVector2Array([
		Vector2(-60, -200), Vector2(0, -200), Vector2(0, 200), Vector2(-60, 200)]), "holes": []})
	var quay := _base()
	quay.shore_structures = [{"points": PackedVector2Array([Vector2(0, -500), Vector2(0, 100)]), "kind": "quay", "id": "way:wall"}]
	quay.land_polygons[0]["holes"] = [PackedVector2Array([
		Vector2(150, -70), Vector2(250, -70), Vector2(250, 70), Vector2(150, 70)])]
	var canal := _base()
	canal.land_polygons = [{"class": "water", "points": PackedVector2Array([
		Vector2(-300, -8), Vector2(300, -8), Vector2(300, 8), Vector2(-300, 8)]), "holes": []}]
	canal.buildings = []
	canal.roads = []
	for k in 12:
		var x := -250.0 + k * 40.0
		for side in [-1.0, 1.0]:
			var z: float = side * 22.0
			canal.buildings.append({"x": x, "z": z, "size_x": 14.0, "size_z": 10.0, "osm_id": "way:%d" % (k * 2 + int(side > 0)),
				"footprint": PackedVector2Array([Vector2(x - 7, z - 5), Vector2(x + 7, z - 5), Vector2(x + 7, z + 5), Vector2(x - 7, z + 5)])})
	for side in [-1.0, 1.0]:
		canal.roads.append({"class": "pedestrian", "surface": "paving_stones", "width_m": 4.0, "osm_id": "way:fond%d" % int(side > 0),
			"points": PackedVector2Array([Vector2(-300, side * 11.0), Vector2(300, side * 11.0)])})
	canal.roads.append({"class": "primary", "bridge": true, "width_m": 10.0, "osm_id": "way:bridge",
		"points": PackedVector2Array([Vector2(60, -30), Vector2(60, 30)])})
	canal.roads.append({"class": "footway", "bridge": true, "width_m": 3.0, "osm_id": "way:foot",
		"points": PackedVector2Array([Vector2(-120, -12), Vector2(-120, 12)])})
	var creek := _base()
	creek.land_polygons = [{"class": "water", "points": PackedVector2Array([
		Vector2(-300, -3), Vector2(300, -3), Vector2(300, 3), Vector2(-300, 3)]), "holes": []}]
	creek.roads = [{"class": "primary", "bridge": true, "width_m": 12.0, "osm_id": "way:road_bridge",
		"points": PackedVector2Array([Vector2(0, -2), Vector2(0, 40)])}]
	return {"open": open, "quay_island": quay, "canal": canal, "creek": creek}
