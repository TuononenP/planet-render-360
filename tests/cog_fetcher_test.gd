extends SceneTree

const Fetcher = preload("res://scripts/data/cog_fetcher.gd")

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var fetcher := Fetcher.new()
	root.add_child(fetcher)
	await process_frame
	var results: Array = []
	fetcher.finished.connect(func(result: Dictionary) -> void: results.append(result))
	fetcher.fetch_tile("http://127.0.0.1:1/unused.tif", 0, 0)
	fetcher.cancel()
	for i in 4:
		await process_frame
	if not results.is_empty():
		failures.append("a cancelled request must not emit a result")
	if OS.get_environment("COG_FETCH_LIVE") == "1":
		for spec in [[LandcoverSource.worldcover(48.8566, 2.3522), 1.0, 36000],
				[LandcoverSource.canopy(48.8566, 2.3522), 4.0, 8192]]:
			var source: Dictionary = spec[0]
			var pixel: Vector2i = source["pixel"]
			fetcher.fetch_tile(source["url"], pixel.x, pixel.y, spec[1])
			var deadline := Time.get_ticks_msec() + 60000
			while results.is_empty() and Time.get_ticks_msec() < deadline:
				await process_frame
			if results.is_empty():
				failures.append("live source timed out: %s" % source["tile"])
				fetcher.cancel()
				continue
			var tile: Dictionary = results.pop_front()
			if tile.is_empty() or int(tile.get("ifd", {}).get("width", 0)) != int(spec[2]) \
					or (tile.get("pixels", PackedByteArray()) as PackedByteArray).is_empty():
				failures.append("live COG tile or overview missing: %s" % source["tile"])
	fetcher.free()
	if failures.is_empty():
		print("COG FETCHER OK: cancellation%s" % (" and two live range sources" if OS.get_environment("COG_FETCH_LIVE") == "1" else ""))
		quit(0)
	else:
		for failure in failures:
			printerr("COG FETCHER FAIL: ", failure)
		quit(1)
