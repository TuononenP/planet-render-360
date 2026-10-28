extends SceneTree

## Landmark test: godot --headless --script tests/landmark_test.gd
## Offline. Guards the on-the-fly landmark contract:
## 1) searched names and city centres resolve to the right landmark,
## 2) every registry type builds a multi-part procedural model,
## 3) Turku Cathedral is a tall brick model (tower/spire present),
## 4) models stand at the site's true bearing, clamped into the
##    terrain, and 5) the landmark's generic OSM box is suppressed.

func _flat_data() -> LocationData:
	var data := LocationData.new()
	data.grid_size = 8
	data.heights.resize(64)
	for i in 64:
		data.heights[i] = 3.0
	data.water_level = -3.0
	data.seed_value = 42
	return data

func _run() -> void:
	var failures: Array[String] = []

	# --- 1) Detection: by searched name, and by city centre ---
	var by_name := {
		"Turun tuomiokirkko, 1": "turku_cathedral",
		"Eiffel Tower": "eiffel",
		"Big Ben": "big_ben",
		"Colosseum": "colosseum",
		"Statue of Liberty": "statue_liberty",
		"Sydney Opera House": "sydney_opera",
	}
	for name in by_name:
		if LocationData.landmark_for(0.0, 0.0, name) != by_name[name]:
			failures.append("name '%s' should give %s" % [name, by_name[name]])
	var by_place := {
		Vector2(48.8566, 2.3522): "eiffel",       # Paris centre
		Vector2(60.4518, 22.2666): "turku_cathedral",  # Turku centre
		Vector2(60.1699, 24.9384): "helsinki_cathedral",
		Vector2(51.5074, -0.1278): "big_ben",     # London centre
		Vector2(41.9028, 12.4964): "colosseum",   # Rome centre
		Vector2(41.3874, 2.1686): "sagrada",      # Barcelona centre
		Vector2(30.0444, 31.2357): "pyramid",     # Cairo centre
		Vector2(40.7128, -74.0060): "statue_liberty",  # New York centre
		Vector2(-33.8688, 151.2093): "sydney_opera",
		Vector2(35.6762, 139.6503): "tokyo",      # Tokyo centre
	}
	for coords in by_place:
		var got := LocationData.landmark_for(coords.x, coords.y, "")
		if got != by_place[coords]:
			failures.append("place %s should give %s, got %s" % [coords, by_place[coords], got])
	if LocationData.landmark_for(51.1789, -115.5708, "Banff, Canada") != "none":
		failures.append("Banff should have no landmark")

	# --- 2) Every registry type builds a multi-part model ---
	for entry in LocationData.landmarks():
		var model := LandmarkBuilder.build(str(entry["type"]))
		if model.get_child_count() < 8:
			failures.append("%s should have >=8 parts, got %d"
				% [entry["type"], model.get_child_count()])
		model.free()

	# --- 2b) Eiffel GLB parts are flattened ownerless: reparented
	# asset parts must not keep the asset root as owner, or Godot
	# warns "will make owner 'eiffel' inconsistent" on every part.
	# The warning itself only shows on stderr; the stderr of this
	# test run must stay free of it.
	var eiffel := LandmarkBuilder.build("eiffel")
	var part_names: Array = eiffel.get_children().map(
		func(c: Node) -> String: return c.name)
	if not part_names.has("Brace"):
		failures.append("eiffel should use the GLB asset parts, got %s" % [part_names])
	for part in eiffel.get_children():
		if part.owner != null:
			failures.append("eiffel part %s should be ownerless, owner is %s"
				% [part.name, part.owner])
	eiffel.free()

	# --- 3) Turku Cathedral reads tall: spire parts above y=18 ---
	var turku := LandmarkBuilder.build("turku_cathedral")
	var top := 0.0
	for child in turku.get_children():
		if child is Node3D:
			top = maxf(top, (child as Node3D).position.y)
	if top < 18.0:
		failures.append("turku cathedral tower/spire should reach y>=18, top part at %f" % top)
	turku.free()

	# --- 4) Placement: true bearing, clamped, never inside the model ---
	var at_site := _flat_data()
	at_site.latitude = 60.4524
	at_site.longitude = 22.2781
	at_site.landmark_type = "turku_cathedral"
	at_site.has_landmark_site = true
	at_site.landmark_lat = 60.4524
	at_site.landmark_lon = 22.2781
	var pos_at := TerrainBuilder.landmark_world_pos(at_site)
	if absf(pos_at.length() - 38.0) > 0.1:
		failures.append("viewpoint at the site should push the model to 38 units, got %f" % pos_at.length())
	var paris := _flat_data()
	paris.latitude = 48.8566
	paris.longitude = 2.3522
	paris.landmark_type = "eiffel"
	paris.has_landmark_site = true
	paris.landmark_lat = 48.8584
	paris.landmark_lon = 2.2945
	var pos_paris := TerrainBuilder.landmark_world_pos(paris)
	if absf(pos_paris.length() - 95.0) > 0.1 or pos_paris.x > -80.0:
		failures.append("Eiffel from Paris centre should clamp to 95 units west, got %s" % str(pos_paris))

	# --- 5) The cathedral's generic OSM box must not duplicate it ---
	var dup := _flat_data()
	dup.latitude = 60.4524
	dup.longitude = 22.2781
	dup.landmark_type = "turku_cathedral"
	dup.has_landmark_site = true
	dup.landmark_lat = 60.4524
	dup.landmark_lon = 22.2781
	dup.buildings = [{"x": 0.0, "z": 0.0, "size_x": 10.0, "size_z": 8.0, "height": 20.0, "name": "Turun tuomiokirkko"}]
	var world := TerrainBuilder.build_world(dup)
	var has_landmark := false
	for child in world.get_children():
		if child.name.begins_with("Landmark_"):
			has_landmark = true
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			var p := (child as MeshInstance3D).position
			if absf(p.x) < 1.0 and absf(p.z) < 1.0:
				failures.append("generic OSM box at the cathedral site should be suppressed")
	if not has_landmark:
		failures.append("build_world should add the Landmark_ node")
	world.free()

	if failures.is_empty():
		print("LANDMARK OK: registry detection, multi-part models, true-bearing placement, OSM suppression")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK FAIL: ", f)
		quit(1)

func _init() -> void:
	_run()
