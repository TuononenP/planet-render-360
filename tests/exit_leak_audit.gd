extends SceneTree

## Real-window off-screen exit-leak & build-timing audit.
## Launches scenes/main.tscn, builds Helsinki at Ultra into a temporary
## WorldCache dir (so the full build + background save + View360 +
## WorldStreamer + WeatherDressing all run), then shuts down via the
## exact app close path (NOTIFICATION_WM_CLOSE_REQUEST -> _request_exit).
##
## Run via:
##   tools/godot_bg.sh --path . --position 4000,4000 --verbose --script tests/exit_leak_audit.gd

func _init() -> void:
	_run()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var lat := 60.1699
	var lon := 24.9384
	var preset := RenderSettings.Preset.ULTRA
	var wait_save := false
	for i in args.size():
		if args[i] == "--lat" and i + 1 < args.size():
			lat = float(args[i + 1])
		elif args[i] == "--lon" and i + 1 < args.size():
			lon = float(args[i + 1])
		elif args[i] == "--high":
			preset = RenderSettings.Preset.HIGH
		elif args[i] == "--wait-save":
			wait_save = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	CacheStore.eviction_suppressed = true
	var tmp_cache := "user://exit-leak-audit-%d" % OS.get_process_id()
	WorldCache.dir_override = tmp_cache
	RenderSettings.path_override = "user://exit-leak-audit-settings-%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.capture_mode = true
	await process_frame
	main._settings.preset = preset
	main._apply_preset(preset)
	main._store.entries.clear()
	await create_timer(0.5).timeout
	var t0 := Time.get_ticks_msec()
	main._start_generation(lat, lon)
	while not main._view.visible and Time.get_ticks_msec() - t0 < 300000:
		await process_frame
	var total_ms := Time.get_ticks_msec() - t0
	print("AUDIT_VIEW_READY ms=%d visible=%s" % [total_ms, str(main._view.visible)])
	# Let View360 / WeatherDressing / WorldStreamer settle for a few frames.
	for _f in 10:
		await process_frame
	if wait_save:
		var data: LocationData = main._view._data
		if data != null and WorldCache.enabled():
			var scene := WorldCache.base_dir() + "/" + WorldCache.key(data) + ".scn"
			var ts := Time.get_ticks_msec()
			while not FileAccess.file_exists(scene) and Time.get_ticks_msec() - ts < 120000:
				await process_frame
			print("AUDIT_WORLD_CACHE_SAVED=%s ms=%d" % [str(FileAccess.file_exists(scene)), Time.get_ticks_msec() - ts])
	var vram_mb := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / (1024.0 * 1024.0)
	print("AUDIT_VRAM_MB=%.1f" % vram_mb)
	# Clean up temporary cache & settings files before exit.
	var abs_cache := ProjectSettings.globalize_path(tmp_cache)
	if DirAccess.dir_exists_absolute(abs_cache):
		var d := DirAccess.open(abs_cache)
		if d != null:
			for f in d.get_files():
				d.remove(f)
		DirAccess.remove_absolute(abs_cache)
	var abs_settings := ProjectSettings.globalize_path(RenderSettings.path_override)
	if FileAccess.file_exists(abs_settings):
		DirAccess.remove_absolute(abs_settings)
	# Shut down via the exact app close path.
	root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
