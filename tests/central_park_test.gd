extends SceneTree

## Central Park: the preset and its bundled layers, the five landmark
## models at their registered heights, the park's own tree mix, mapped
## rock that stands up as mounds (park outcrops only), and a landmark
## selection that always keeps the park's own landmarks and replaces the
## mapped decks of its bridges.

const PARK := ["bethesda_fountain", "bow_bridge", "gapstow_bridge", "belvedere_castle", "cleopatras_needle"]

func _init() -> void:
	var failures: Array[String] = []
	var row := {}
	for r in PresetViews.ROWS:
		if str(r["id"]) == "central_park":
			row = r
	if row.is_empty():
		failures.append("no central_park preset")
	else:
		for layer in ["detailed", "ring1600", "ring2500", "poi", "far"]:
			var version := OsmQuery.QUERY_VERSION if layer == "detailed" else (FarCityFetcher.QUERY_VERSION \
				if layer == "far" else (OsmQuery.POI_VERSION if layer == "poi" else OsmQuery.RING_VERSION))
			var key := BundledOsm.entry_for(float(row["lat"]), float(row["lon"]), layer, version)
			if key == "" or BundledOsm.read(key) == "":
				failures.append("central_park %s layer is not bundled" % layer)
	for type in PARK:
		var entry := LocationData.entry_for_type(type)
		if entry.is_empty():
			failures.append("%s is not registered" % type)
			continue
		var model := LandmarkBuilder.build(type)
		var bounds := AABB()
		var first := true
		for m in LandmarkBuilder.parts(model):
			bounds = m.mesh.get_aabb() if first else bounds.merge(m.mesh.get_aabb())
			first = false
		model.free()
		if first:
			failures.append("%s builds no mesh" % type)
		elif absf(bounds.end.y - float(entry["height_m"])) > float(entry["height_m"]) * 0.05 + 0.2:
			failures.append("%s tops out at %.1f m, not %.1f m" % [type, bounds.end.y, float(entry["height_m"])])
	if str(HeritageZones.rule_at(40.7743, -73.9708).get("tree_mix", "")) != "nyc_park":
		failures.append("Bethesda Terrace is not in the nyc_park tree zone")
	var species := TreeSpecies.mix("nyc_park", "park").map(func(s: Array) -> String: return str(s[0]))
	if not "zelkova" in species or not "oak" in species or not "plane" in species:
		failures.append("the nyc_park mix lacks elm, oak or plane: %s" % str(species))
	if str(TreeSpecies.GENUS["ulmus"]) != "zelkova":
		failures.append("a mapped elm is not drawn in the elm form")
	_rock_checks(failures)
	_selection_checks(failures)
	for f in failures:
		printerr("CENTRAL PARK FAIL: ", f)
	print("central_park_test: %s" % ("FAIL" if not failures.is_empty() else "PASS"))
	quit(1 if not failures.is_empty() else 0)

func _rock_checks(failures: Array[String]) -> void:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, 3)
	data.latitude = 40.776
	data.longitude = -73.970
	data.heights.resize(data.grid_size * data.grid_size)
	data.heights.fill(30.0)
	data.land_polygons = [
		{"class": "rock", "points": PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(22, 18), Vector2(0, 20)])},
		{"class": "rock", "points": PackedVector2Array([Vector2(-400, -400), Vector2(-200, -400),
			Vector2(-200, -200), Vector2(-400, -200)])},
		{"class": "grass", "points": PackedVector2Array([Vector2(100, 100), Vector2(120, 100), Vector2(120, 120)])},
	]
	var ground := GroundTruth.new(data)
	var root := Node3D.new()
	var n := RockOutcrops.build(root, data, ground)
	if n != 1:
		failures.append("RockOutcrops raised %d mounds, expected only the park-sized rock" % n)
	root.free()

func _selection_checks(failures: Array[String]) -> void:
	for preset in [0, 3]:
		var data := LocationData.new()
		data.latitude = 40.7760
		data.longitude = -73.9700
		data.quality_preset = preset
		var picked := LandmarkSites.select(data, [])
		var types := picked.map(func(c: Dictionary) -> String: return str(c.get("type", "")))
		for type in PARK:
			if not type in types:
				failures.append("preset %d does not build %s" % [preset, type])
		data.landmark_candidates = picked
		var spans := LandmarkSites.bridge_spans(data).map(func(s: Array) -> String:
			return str((s[1] as Dictionary).get("type", "")))
		if not "bow_bridge" in spans:
			failures.append("preset %d keeps the mapped Bow Bridge deck under the model" % preset)
