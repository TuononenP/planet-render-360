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
	# Shared caches: a tile one reader decoded is served to another with
	# no request (neighbouring streamed places need the same few tiles).
	var url := "http://127.0.0.1:1/cached.tif"
	var ifd := {"width": 1024, "height": 1024, "tile_width": 512, "tile_height": 512, "bits": 8,
		"compression": 8, "samples": 1, "planar": 1, "predictor": 1,
		"offsets": {"type": 4, "count": 4, "value": 0}, "sizes": {"type": 4, "count": 4, "value": 0}}
	Fetcher._metadata[url] = {"header": PackedByteArray(), "ifds": [ifd]}
	var pixels := PackedByteArray()
	pixels.resize(512 * 512)
	pixels.fill(7)
	Fetcher._remember("%s#%d#%d" % [url, 1024, 3], pixels)
	var other := Fetcher.new()
	root.add_child(other)
	var got: Array = []
	other.finished.connect(func(result: Dictionary) -> void: got.append(result))
	other.fetch_tile(url, 600, 700)
	if got.size() != 1 or int(got[0].get("index", -1)) != 3 \
			or (got[0].get("pixels", PackedByteArray()) as PackedByteArray).size() != 512 * 512 \
			or got[0].get("pixel") != Vector2i(600 - 512, 700 - 512):
		failures.append("a remembered tile must be served at once, from any reader: %s" % [got])
	for i in Fetcher.TILE_CACHE_SIZE + 3:
		Fetcher._remember("%s#x#%d" % [url, i], pixels)
	if Fetcher._tiles.size() != Fetcher.TILE_CACHE_SIZE or Fetcher._tiles.has("%s#%d#%d" % [url, 1024, 3]):
		failures.append("the tile cache must stay bounded, oldest out first")
	Fetcher._tiles.clear()
	Fetcher._tile_order.clear()
	Fetcher._metadata.erase(url)
	other.free()
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
		print("COG FETCHER OK: cancellation, shared tile cache%s" % (" and two live range sources" if OS.get_environment("COG_FETCH_LIVE") == "1" else ""))
		quit(0)
	else:
		for failure in failures:
			printerr("COG FETCHER FAIL: ", failure)
		quit(1)
