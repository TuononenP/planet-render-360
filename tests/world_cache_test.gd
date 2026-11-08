extends SceneTree

## Built-world cache (T7.5). Windowed only — the headless dummy renderer
## keeps no mesh data, so the cache is off there:
## godot --script tests/world_cache_test.gd   (CI: under xvfb-run)
## A first visit builds and saves in the background; the revisit must
## load the same world (same nodes, meshes and bounds) from the cache,
## faster than the build, and the budget must evict oldest-first.

class FailedWriteView extends View360:
	var builds := 0
	func _ready() -> void:
		pass
	func build_location(_data: LocationData, _ground: GroundTruth = null,
			_abort: BuildAbort = null, _wait_save := false) -> Array:
		# A world built successfully, but the cache write produced no files.
		builds += 1
		return [null, Node3D.new()]

class SaveTestPipeline extends GenerationPipeline:
	func _ready() -> void:
		pass
	func ground_for(_data: LocationData) -> GroundTruth:
		return null

class SaveTestMain extends "res://scripts/main.gd":
	var outcome := ""
	func _ready() -> void:
		pass
	func _release_build() -> void:
		_build_abort = null
		_building_world = false
	func _end_save(message: String) -> void:
		outcome = message
	func _save_missing_data(_data: LocationData) -> bool:
		return false
	func _set_generating(_on: bool) -> void:
		pass
	func _show(_screen: Control) -> void:
		pass

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
	if OS.get_cmdline_user_args().has("--save-failure-only"):
		await _save_failure()
		return
	var failures: Array[String] = []
	if not WorldCache.enabled():
		printerr("WORLD CACHE FAIL: run windowed (the cache is off headless)")
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	CacheStore.eviction_suppressed = true
	WorldCache.dir_override = "user://world-cache-test-%d" % OS.get_process_id()
	RenderSettings.path_override = "user://world-cache-test-settings-%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.capture_mode = true
	await process_frame
	main._store.entries.clear()
	await create_timer(1.0).timeout
	# First visit: build, then the background save.
	var t0 := Time.get_ticks_msec()
	main._start_generation(48.8566, 2.3522)
	var cold := await _wait_view(main, t0)
	var data: LocationData = main._view._data
	var first := _summary(main._view._generated)
	var scene := WorldCache.base_dir() + "/" + WorldCache.key(data) + ".scn"
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
	# Budget: a 1-byte cap evicts every entry, the newest too when asked.
	WorldCache.enforce_budget(1)
	if not FileAccess.file_exists(scene):
		failures.append("the default trim should keep the newest world")
	if WorldCache.enforce_budget(1, false) < 1 or FileAccess.file_exists(scene):
		failures.append("budget should evict the oldest world")
	if failures.is_empty():
		print("WORLD CACHE OK: background save, identical cached world + ground, faster revisit, budget eviction")
		quit(0)
	else:
		for f in failures:
			printerr("WORLD CACHE FAIL: ", f)
		quit(1)

func _save_failure() -> void:
	var cache_enabled := WorldCache.enabled()
	var id := str(OS.get_process_id())
	WorldCache.dir_override = "user://world-save-failure-" + id
	CacheStore.history_override = "user://world-save-failure-history-" + id + ".json"
	var main := SaveTestMain.new()
	root.add_child(main)
	var view := FailedWriteView.new()
	main.add_child(view)
	main._view = view
	var pipeline := SaveTestPipeline.new()
	main.add_child(pipeline)
	main._pipeline = pipeline
	main._store = CacheStore.new()
	var data := LocationData.new()
	data.latitude = 40.7060
	data.longitude = -74.0040
	data.place_name = "New York, United States"
	main._generation_deadline_ms = 0
	await main._save_world(data)
	var outcome := main.outcome
	# Without a world cache (headless) there is nothing to write or verify.
	var expected := main.SAVE_WORLD_FAILED if cache_enabled else main.SAVE_DONE
	var builds := view.builds
	var recorded: int = main._store.entries.size()
	# Quitting during the OSM stage must not start a world build.
	var quit_expected := main.SAVE_FAILED
	main._quitting = true
	main._saving = true
	main.outcome = ""
	await main._save_world(data)
	var quit_outcome := main.outcome
	var quit_builds := view.builds - builds
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(CacheStore.history_override)
	WorldCache.dir_override = ""
	CacheStore.history_override = ""
	if outcome != expected or builds != int(cache_enabled):
		printerr("WORLD SAVE FAILURE TEST: unexpected outcome ", outcome)
		quit(1)
	elif recorded != int(not cache_enabled):
		printerr("WORLD SAVE FAILURE TEST: a world reported as not saved reached History")
		quit(1)
	elif quit_outcome != quit_expected or quit_builds != 0:
		printerr("WORLD SAVE FAILURE TEST: quitting during the OSM stage still built: ", quit_outcome)
		quit(1)
	else:
		print("WORLD SAVE FAILURE OK: built world without cache files is not reported as saved")
		quit(0)
