extends SceneTree

const Fetcher = preload("res://scripts/data/landcover_fetcher.gd")

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	for kind in ["landcover", "canopy"]:
		var plan := Fetcher.plan_window(kind, 0.0, 0.0, 16)
		if plan.is_empty() or (plan["groups"] as Array).size() < 4:
			failures.append("window crossing source boundaries lost tiles: %s" % kind)
			continue
		var tiles: Array = []
		var tile_size: int = plan["tile_size"]
		for i in (plan["groups"] as Array).size():
			var tile := PackedByteArray()
			tile.resize(tile_size * tile_size)
			tile.fill(i + 1)
			tiles.append(tile)
		var assembled: PackedByteArray = Fetcher.assemble(plan, tiles)
		if assembled.size() != 256:
			failures.append("sample window did not assemble: %s" % kind)
		else:
			for i in assembled.size():
				if int(assembled[i]) != (int(plan["mapping"][i]) >> 20):
					failures.append("sample mapped to wrong source tile: %s" % kind)
					break
		if not Fetcher.assemble(plan, []).is_empty():
			failures.append("missing tiles must fail closed: %s" % kind)
	if not Fetcher.plan_window("canopy", 90.0, 0.0, 16).is_empty():
		failures.append("unsupported polar window must fail closed")
	var abort := BuildAbort.new()
	abort.requested = true
	if not Fetcher.plan_window("landcover", 48.0, 2.0, 16, abort).is_empty():
		failures.append("a cancelled raster plan must not produce partial data")
	var previous := CacheStore.dir_override
	CacheStore.dir_override = "user://landcover-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.dir_override))
	var cover_path := Fetcher.cache_path("landcover", 48.8566, 2.3522)
	if CacheStore.layer_of(cover_path) != "landcover" or not CacheStore.is_v2_name(cover_path):
		failures.append("raster cache keys must be current and attributed to land cover")
	var high_keys := CacheStore.place_cache_keys(48.8566, 2.3522, RenderSettings.Preset.HIGH)
	var fast_keys := CacheStore.place_cache_keys(48.8566, 2.3522, RenderSettings.Preset.FAST)
	if (high_keys["landcover"] as Array).size() != 2 or not (fast_keys["landcover"] as Array).is_empty():
		failures.append("land-cover cache keys must follow the quality tier")
	var saved := {"lat": 48.8566, "lon": 2.3522, "quality_preset": RenderSettings.Preset.HIGH,
		"cache_keys": {"landcover": ["old-absolute-path"]}}
	if CacheStore.entry_cache_keys(saved)["landcover"] != high_keys["landcover"]:
		failures.append("history must derive cache keys from current paths")
	var img := Image.create(Fetcher.COVER_SIZE, Fetcher.COVER_SIZE, false, Image.FORMAT_L8)
	img.fill(Color(0.2, 0.2, 0.2))
	img.save_png(cover_path)
	var fetcher := Fetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.offline_mode = true
	var result := {"called": false, "cover": null, "canopy": null}
	fetcher.finished.connect(func(cover: Image, canopy: Image) -> void:
		result.merge({"called": true, "cover": cover, "canopy": canopy}, true))
	fetcher.fetch(48.8566, 2.3522)
	if not result["called"] or result["cover"] == null or result["canopy"] != null:
		failures.append("offline cache must serve each source independently")
	result["called"] = false
	fetcher.offline_mode = false
	fetcher.fetch(48.8566, 2.3522)
	fetcher.cancel()
	for i in 4:
		await process_frame
	if result["called"]:
		failures.append("cancelled raster fetch must not emit a stale result")
	if OS.get_environment("LANDCOVER_LIVE") == "1":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(cover_path))
		fetcher.offline_mode = false
		result["called"] = false
		fetcher.fetch(48.8566, 2.3522)
		var deadline := Time.get_ticks_msec() + 180000
		while not result["called"] and Time.get_ticks_msec() < deadline:
			await process_frame
		if not result["called"] or result["cover"] == null or result["canopy"] == null:
			failures.append("live place windows did not both arrive")
		elif (result["cover"] as Image).get_size() != Vector2i(Fetcher.COVER_SIZE, Fetcher.COVER_SIZE) \
				or (result["canopy"] as Image).get_size() != Vector2i(Fetcher.CANOPY_SIZE, Fetcher.CANOPY_SIZE):
			failures.append("live windows have incorrect dimensions")
	fetcher.cancel()
	fetcher.free()
	CacheStore.dir_override = previous
	if failures.is_empty():
		print("LANDCOVER FETCHER OK: source boundaries, tile assembly, offline fallback%s" % (" and live windows" if OS.get_environment("LANDCOVER_LIVE") == "1" else ""))
		quit(0)
	else:
		for failure in failures:
			printerr("LANDCOVER FETCHER FAIL: ", failure)
		quit(1)
