extends SceneTree

## Headless smoke test: godot --headless --script tests/smoke_test.gd
## Covers contracts the UI cannot prove: DEM validity, cache round-trip,
## terrain construction, and known-place lookup.

func _init() -> void:
	var failures: Array[String] = []

	# Known places + coordinate formatting
	if LocationData.known_place(48.8566, 2.3522) != "Paris, France":
		failures.append("Paris gazetteer lookup failed")
	if LocationData.known_place(51.1789, -115.5708) != "Banff, Canada":
		failures.append("Banff gazetteer lookup failed (negative longitude)")
	if LocationData.known_place(36.2704, -121.8081) != "Big Sur, United States":
		failures.append("Big Sur gazetteer lookup failed")
	if LocationData.landmark_for(48.8584, 2.2945, "Paris, France") != "eiffel":
		failures.append("Eiffel coordinates should give the eiffel landmark")
	if LocationData.landmark_for(48.8566, 2.3522, "Paris, France") == "eiffel":
		failures.append("Notre Dame centre must not spawn a misplaced Eiffel Tower")

	# Pipeline DEM (call the builder directly; timers need the main loop)
	var pipeline := GenerationPipeline.new()
	var data := LocationData.new()
	data.latitude = 46.6863
	data.longitude = 7.8632
	data.place_name = LocationData.known_place(data.latitude, data.longitude)
	data.seed_value = 12345
	pipeline._build_dem(data)
	if not data.is_valid():
		failures.append("DEM invalid: heights=%d grid=%d" % [data.heights.size(), data.grid_size])
	var centre := data.height_at(data.grid_size / 2, data.grid_size / 2)
	if is_nan(centre) or is_inf(centre):
		failures.append("DEM centre height not finite")

	# Terrain builds a world without errors
	var world := TerrainBuilder.build_world(data)
	if world == null or world.get_child_count() < 3:
		failures.append("Terrain world has too few children")
	world.free()
	pipeline.free()

	# Cache round-trip in a temp user dir file
	var store := CacheStore.new()
	store.entries.clear()
	store.add_entry("Test Place", 12.5, -45.25)
	var reloaded := CacheStore.new()
	reloaded.load_store()
	if reloaded.entries.is_empty() or str(reloaded.entries[0].get("name")) != "Test Place":
		failures.append("Cache round-trip failed")
	store.clear()

	if failures.is_empty():
		print("SMOKE OK: DEM, terrain, cache, gazetteer")
		quit(0)
	else:
		for f in failures:
			printerr("SMOKE FAIL: ", f)
		quit(1)
