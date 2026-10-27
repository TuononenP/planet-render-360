extends SceneTree

## Map pan regression test: godot --headless --script tests/map_pan_test.gd
## Offline. Guards the "map disappears while moving" bug:
## 1) panning must request tiles for the new centre during the drag,
##    not only on release, 2) the requested/drawn tile range must cover
##    a viewport wider/taller than the old fixed 5x5 grid, and
## 3) TileFetcher must not queue the same tile over and over (stale
##    duplicates buried newly needed tiles behind them in the FIFO).

func _tile_covered(fetcher: TileFetcher, map: MapTileView, t: Vector3i) -> bool:
	if map._textures.has("%d/%d/%d" % [t.x, t.y, t.z]):
		return true
	# Queued or in flight both count as "requested".
	if fetcher._pending.has(t):
		return true
	return fetcher._queue.has(t)

func _run() -> void:
	var failures: Array[String] = []

	# --- Fetcher: duplicate requests collapse to one pending entry ---
	var offline := TileFetcher.new()  # not added: no pool, queue is inspectable
	for i in 3:
		offline.request_tile(15, 16383, 16383)  # remote ocean tile, uncached
	if offline._queue.size() != 1:
		failures.append("duplicate tile requests should queue once, got %d" % offline._queue.size())
	# Stale queued tiles can be dropped, keeping only the live viewport.
	offline.request_tile(15, 16384, 16383)
	offline.request_tile(15, 16385, 16383)
	if offline.has_method("discard_queued_except"):
		offline.discard_queued_except([Vector3i(15, 16385, 16383)])
		if offline._queue != [Vector3i(15, 16385, 16383)]:
			failures.append("discard_queued_except should keep only live tiles, got %s" % str(offline._queue))
	else:
		failures.append("TileFetcher should offer discard_queued_except")
	offline.free()

	# --- View: a wide viewport needs tiles beyond the old +/-2 range ---
	var map := MapTileView.new()
	root.add_child(map)
	map.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map.size = Vector2(1600, 1200)
	await process_frame
	var centre_px := TileFetcher.global_pixel(map.centre_lat, map.centre_lon, map.zoom_level)
	var tile_centre := Vector2i(centre_px / 256.0)
	var corner := Vector3i(map.zoom_level, tile_centre.x + 4, tile_centre.y + 3)
	if not _tile_covered(map._fetcher, map, corner):
		failures.append("wide viewport corner tile %s should be requested" % str(corner))

	# --- Pan: dragging far must request the new centre before release ---
	map.size = Vector2(390, 500)
	await process_frame
	map.pan_by_pixels(Vector2(-900, 0))  # drag left: centre moves ~3.5 tiles
	var new_px := TileFetcher.global_pixel(map.centre_lat, map.centre_lon, map.zoom_level)
	var new_centre := Vector2i(new_px / 256.0)
	var needed := Vector3i(map.zoom_level, new_centre.x, new_centre.y)
	if not _tile_covered(map._fetcher, map, needed):
		failures.append("pan should request new centre tile %s during the drag" % str(needed))
	map.queue_free()

	if failures.is_empty():
		print("MAP_PAN OK: pan requests tiles mid-drag, wide viewport covered, no duplicate queueing")
		quit(0)
	else:
		for f in failures:
			printerr("MAP_PAN FAIL: ", f)
		quit(1)

func _init() -> void:
	_run()
