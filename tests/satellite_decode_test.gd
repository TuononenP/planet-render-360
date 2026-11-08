extends SceneTree

## Headless: godot --headless --script tests/satellite_decode_test.gd
## Cached satellite tiles decode on the worker pool: fetch() returns before
## the mosaic is ready, the stitched mosaic puts each tile where it belongs,
## a damaged cache file settles the mosaic like a missing one, and freeing
## the fetcher mid-decode is safe. Offline mode keeps it off the network.

const LAT := 60.1699
const LON := 24.9384
const ZOOM := 16
const SPAN := 3

var _failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()

func _run() -> void:
	var dir := "user://satellite-decode-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	CacheStore.eviction_suppressed = true
	var tiles := SatelliteFetcher.mosaic_tiles(LAT, LON, ZOOM, SPAN)
	if tiles.size() != SPAN * SPAN:
		_failures.append("expected %d tiles, got %d" % [SPAN * SPAN, tiles.size()])
	var colours := {}
	for i in tiles.size():
		var c := Color.from_hsv(float(i) / tiles.size(), 0.8, 0.8)
		colours[tiles[i]] = c
		var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
		img.fill(c)
		img.save_jpg(CacheStore.sat_path(ZOOM, tiles[i].x, tiles[i].y), 0.95)

	# 1. All cached: asynchronous, and every tile lands in its own cell.
	var result := await _fetch(tiles)
	if not result["async"]:
		_failures.append("fetch() should return before the cached tiles are decoded")
	if result["outcome"] != "succeeded":
		_failures.append("a fully cached mosaic should succeed, got %s" % result["outcome"])
	else:
		var mosaic: Image = result["image"]
		if mosaic.get_width() != SPAN * 256 or mosaic.get_height() != SPAN * 256:
			_failures.append("mosaic size should be %d, got %dx%d" % [SPAN * 256, mosaic.get_width(), mosaic.get_height()])
		else:
			var west := tiles[0].x
			var north := tiles[0].y
			for t in tiles:
				var got := mosaic.get_pixel((t.x - west) * 256 + 128, (t.y - north) * 256 + 128)
				var want: Color = colours[t]
				if absf(got.r - want.r) + absf(got.g - want.g) + absf(got.b - want.b) > 0.2:
					_failures.append("tile %s is in the wrong place or wrong colour (%s, wanted %s)" % [t, got, want])

	# 2. One damaged file: the mosaic cannot complete, and (offline, at a
	# zoom with no fallback) reports failure instead of hanging.
	var bad := FileAccess.open(CacheStore.sat_path(ZOOM, tiles[4].x, tiles[4].y), FileAccess.WRITE)
	bad.store_string("this is not a jpeg")
	bad.close()
	result = await _fetch(tiles)
	if result["outcome"] != "failed":
		_failures.append("a damaged tile with no network should fail the mosaic, got %s" % result["outcome"])

	# 3. Freed while decoding: nothing crashes, nothing is emitted afterwards.
	var gone := SatelliteFetcher.new()
	gone.offline_mode = true
	root.add_child(gone)
	var late := {"fired": false}
	gone.succeeded.connect(func(_t: Texture2D, _i: Image, _o: Vector2, _z: int) -> void: late["fired"] = true)
	gone.failed.connect(func(_r: String) -> void: late["fired"] = true)
	gone.fetch(LAT, LON, ZOOM, SPAN)
	gone.free()
	for i in 10:
		await process_frame
	if late["fired"]:
		_failures.append("a freed fetcher should emit nothing")

	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	_failures.erase(_failures[0])
	if _failures.is_empty():
		print("SATELLITE DECODE OK: async decode, tile placement, damaged file, freed mid-decode")
		quit(0)
	else:
		for f in _failures:
			printerr("SATELLITE DECODE FAIL: ", f)
		quit(1)

## Runs one offline fetch of the cached mosaic and reports how it ended and
## whether fetch() returned before it did.
func _fetch(_tiles: Array[Vector2i]) -> Dictionary:
	var fetcher := SatelliteFetcher.new()
	fetcher.offline_mode = true
	root.add_child(fetcher)
	var out := {"outcome": "", "async": false, "image": null}
	fetcher.succeeded.connect(func(_t: Texture2D, image: Image, _o: Vector2, _z: int) -> void:
		out["outcome"] = "succeeded"
		out["image"] = image)
	fetcher.failed.connect(func(_r: String) -> void: out["outcome"] = "failed")
	fetcher.fetch(LAT, LON, ZOOM, SPAN)
	out["async"] = out["outcome"] == ""
	# Wall clock, not frames: headless frames pass far faster than a worker decodes.
	var started := Time.get_ticks_msec()
	while out["outcome"] == "" and Time.get_ticks_msec() - started < 10000:
		await process_frame
	if out["outcome"] == "":
		out["outcome"] = "timed out"
	fetcher.free()
	return out
