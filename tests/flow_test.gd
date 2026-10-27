extends SceneTree

## Headless flow test: godot --headless --script tests/flow_test.gd
## Drives the real Main scene: start generation for Paris, wait for the
## pipeline, assert the 360 view is shown with a generated world + history.

func _init() -> void:
	_run()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		printerr("FLOW FAIL: cannot load main scene")
		quit(1)
		return
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main._start_generation(48.8566, 2.3522)
	await process_frame
	if not main._loading.visible:
		printerr("FLOW FAIL: loading screen not visible after start")
		quit(1)
		return

	# DEM is cached after first run; OSM may take up to ~32s cold.
	# Real time, not frame counting: headless frames run faster than 60fps.
	var start_msec := Time.get_ticks_msec()
	while not main._view.visible \
			and Time.get_ticks_msec() - start_msec < 60000:
		await process_frame

	if not main._view.visible:
		printerr("FLOW FAIL: view never became visible")
		quit(1)
		return
	var world_found := false
	for child in main._view._world_root.get_children():
		if child.name == "GeneratedWorld" and child.get_child_count() >= 3:
			world_found = true
	if not world_found:
		printerr("FLOW FAIL: no GeneratedWorld in 360 view")
		quit(1)
		return
	if main._store.entries.is_empty() \
			or str(main._store.entries[0].get("name")) != "Paris, France":
		printerr("FLOW FAIL: history not recorded for Paris")
		quit(1)
		return
	print("FLOW OK: picker -> loading -> 360 view + history for Paris")
	print("FLOW INFO: used_real_dem=%s used_osm=%s" % [
		main._pipeline.used_real_dem, main._pipeline.used_osm])
	quit(0)
