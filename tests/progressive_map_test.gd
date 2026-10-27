extends SceneTree

## Progressive map test: godot --headless --script tests/progressive_map_test.gd
## Offline. Guards the fast-first-paint contract:
## 1) ancestor (parent-tile) math is exact, 2) detail tiles are ordered
##    centre-out, 3) a viewport collapses to few coarse preview tiles,
## 4) the view requests the coarse preview for its centre, and
## 5) a cached ancestor stands in for a missing detail tile.

func _covered(fetcher: TileFetcher, map: MapTileView, t: Vector3i) -> bool:
	if map._textures.has("%d/%d/%d" % [t.x, t.y, t.z]):
		return true
	return fetcher._pending.has(t) or fetcher._queue.has(t)

func _run() -> void:
	var failures: Array[String] = []

	# --- 1) Ancestor math ---
	if TileFetcher.parent_tile(12, 2074, 1409, 2) != Vector3i(10, 518, 352):
		failures.append("parent_tile(12,2074,1409,2) should be (10,518,352)")
	if TileFetcher.parent_tile(12, 2074, 1409, 0) != Vector3i(12, 2074, 1409):
		failures.append("parent_tile with drop 0 should be the tile itself")
	var rect := TileFetcher.source_rect_for_ancestor(
		Vector3i(12, 2075, 1409), Vector3i(10, 518, 352))
	if rect != Rect2(192, 64, 64, 64):
		failures.append("ancestor crop should be (192,64,64,64), got %s" % str(rect))
	if TileFetcher.source_rect_for_ancestor(
			Vector3i(12, 2075, 1409), Vector3i(12, 2075, 1409)) != Rect2(0, 0, 256, 256):
		failures.append("same-tile ancestor crop should be the full tile")

	# --- 2) Centre-out order: centre first, corners last ---
	var centre := Vector2i(100, 100)
	var tiles: Array = [
		Vector3i(12, 102, 102), Vector3i(12, 100, 100),
		Vector3i(12, 98, 100), Vector3i(12, 101, 100)]
	var ordered := MapTileView.centre_out_order(tiles, centre)
	if ordered[0] != Vector3i(12, 100, 100):
		failures.append("centre tile should sort first, got %s" % str(ordered[0]))
	if ordered[ordered.size() - 1] != Vector3i(12, 102, 102):
		failures.append("corner tile should sort last, got %s" % str(ordered[ordered.size() - 1]))

	# --- 3) Preview collapse: an aligned 4x4 detail block is 1 preview ---
	var block: Array = []
	for y in range(1408, 1412):
		for x in range(2072, 2076):
			block.append(Vector3i(12, x, y))
	var preview := MapTileView.preview_tiles_for(block, 12)
	if preview != [Vector3i(10, 518, 352)]:
		failures.append("4x4 block should collapse to [(10,518,352)], got %s" % str(preview))
	var wide: Array = []
	for y in range(1400, 1412):
		for x in range(2064, 2076):
			wide.append(Vector3i(12, x, y))
	if MapTileView.preview_tiles_for(wide, 12).size() >= wide.size() / 4:
		failures.append("preview should need far fewer tiles than detail")

	# --- 4) + 5) Live view: preview requested, ancestor stands in ---
	var map := MapTileView.new()
	root.add_child(map)
	map.size = Vector2(390, 500)
	await process_frame
	var tile_centre := Vector2i(
		TileFetcher.global_pixel(map.centre_lat, map.centre_lon, map.zoom_level) / 256.0)
	var centre_preview := TileFetcher.parent_tile(
		map.zoom_level, tile_centre.x, tile_centre.y, MapTileView.PREVIEW_DROP)
	if not _covered(map._fetcher, map, centre_preview):
		failures.append("centre preview tile %s should be requested" % str(centre_preview))
	if not _covered(map._fetcher, map, Vector3i(map.zoom_level, tile_centre.x, tile_centre.y)):
		failures.append("centre detail tile should be requested")
	# Inject a coarse texture: it must stand in, nearest level winning.
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	img.fill(Color(0.4, 0.6, 0.4))
	var tex := ImageTexture.create_from_image(img)
	map._textures["%d/%d/%d" % [centre_preview.x, centre_preview.y, centre_preview.z]] = tex
	if map._find_ancestor(tile_centre.x, tile_centre.y) != centre_preview:
		failures.append("_find_ancestor should return the injected preview tile")
	var nearer := TileFetcher.parent_tile(map.zoom_level, tile_centre.x, tile_centre.y, 1)
	map._textures["%d/%d/%d" % [nearer.x, nearer.y, nearer.z]] = tex
	if map._find_ancestor(tile_centre.x, tile_centre.y) != nearer:
		failures.append("_find_ancestor should prefer the nearest ancestor")
	map.queue_free()

	if failures.is_empty():
		print("PROGRESSIVE_MAP OK: ancestor math, centre-out order, preview collapse + stand-in")
		quit(0)
	else:
		for f in failures:
			printerr("PROGRESSIVE_MAP FAIL: ", f)
		quit(1)

func _init() -> void:
	_run()
