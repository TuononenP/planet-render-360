extends SceneTree

## Built-world cache (T7.5). Windowed only — the headless dummy renderer
## keeps no mesh data, so the cache is off there:
## godot --script tests/world_cache_test.gd   (CI: under xvfb-run)
## A first visit builds and saves in the background; the revisit must
## load the same world (same nodes, meshes and bounds) from the cache,
## faster than the build, and the budget must evict oldest-first.

func _init() -> void:
	_run()

func _wait_view(main: Node, t0: int) -> int:
	while not main._view.visible and Time.get_ticks_msec() - t0 < 400000:
		await process_frame
	return Time.get_ticks_msec() - t0

func _summary(world: Node) -> Dictionary:
	var meshes := 0
	var nodes := 0
	var box := AABB()
	var stack: Array = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		nodes += 1
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			meshes += 1
			var b := (n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()
			box = b if meshes == 1 else box.merge(b)
		stack.append_array(n.get_children())
	return {"nodes": nodes, "meshes": meshes, "box": box}

func _run() -> void:
	var failures: Array[String] = []
	if not WorldCache.enabled():
		printerr("WORLD CACHE FAIL: run windowed (the cache is off headless)")
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for f in DirAccess.get_files_at(WorldCache.DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(WorldCache.DIR + "/" + f))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	# First visit: build, then the background save.
	var t0 := Time.get_ticks_msec()
	main._start_generation(48.8566, 2.3522)
	var cold := await _wait_view(main, t0)
	var data: LocationData = main._view._data
	var first := _summary(main._view._generated)
	var scene := WorldCache.DIR + "/" + WorldCache.key(data) + ".scn"
	var t1 := Time.get_ticks_msec()
	while not FileAccess.file_exists(scene) and Time.get_ticks_msec() - t1 < 600000:
		await process_frame
	if not FileAccess.file_exists(scene):
		failures.append("first visit should save %s" % scene)
	else:
		print("WORLD CACHE saved after %d ms in background" % (Time.get_ticks_msec() - t1))
	# Revisit: from the cache.
	main._show(main._picker)
	await process_frame
	t0 = Time.get_ticks_msec()
	main._start_generation(48.8566, 2.3522)
	var warm := await _wait_view(main, t0)
	var second := _summary(main._view._generated)
	print("WORLD CACHE cold %d ms, cached revisit %d ms" % [cold, warm])
	if second["nodes"] != first["nodes"] or second["meshes"] != first["meshes"]:
		failures.append("cached world differs: %s vs %s" % [second, first])
	elif not (second["box"] as AABB).is_equal_approx(first["box"]):
		failures.append("cached world bounds differ: %s vs %s" % [second["box"], first["box"]])
	if warm >= cold:
		failures.append("cached revisit (%d ms) should beat the build (%d ms)" % [warm, cold])
	var g: GroundTruth = main._view._ground
	if g == null or absf(g.height_at_world(100.0, -200.0) - GroundTruth.new(data).height_at_world(100.0, -200.0)) > 0.001:
		failures.append("restored GroundTruth should sample like a rebuilt one")
	# Budget: a 1-byte cap evicts every entry.
	if WorldCache.enforce_budget(1) < 1 or FileAccess.file_exists(scene):
		failures.append("budget should evict the oldest world")
	if failures.is_empty():
		print("WORLD CACHE OK: background save, identical cached world + ground, faster revisit, budget eviction")
		quit(0)
	else:
		for f in failures:
			printerr("WORLD CACHE FAIL: ", f)
		quit(1)
