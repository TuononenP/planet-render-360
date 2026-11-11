extends SceneTree

## Map warm-up tests: godot --headless --script tests/map_prefetch_test.gd
## Offline: the per-zoom prefetch plan around a picked place, and the
## fetcher's low-priority queue (a fetcher outside the tree has no
## connections, so nothing is downloaded).

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var view := Vector2(1280, 800)
	var focus := view / 2.0
	var current := 12
	var plan := VectorMapLayer.prefetch_plan(60.17, 24.94, view, focus, current)
	var vector: Array = plan["vector"]
	var dem: Array = plan["dem"]
	var zooms: Dictionary = {}
	var seen: Dictionary = {}
	for t in vector:
		zooms[t.x] = true
		if seen.has(t):
			failures.append("duplicate prefetch tile %s" % t)
		seen[t] = true
	for z in range(MapTileView.MIN_ZOOM, MapTileView.MAX_ZOOM + 1):
		var d := VectorMapLayer.data_zoom(z)
		if d == VectorMapLayer.data_zoom(current):
			if zooms.has(d):
				failures.append("the current zoom is the view's job, not the warm-up's")
		elif not zooms.has(d):
			failures.append("data zoom %d missing from the plan" % d)
	if vector.is_empty() or vector[0].x != VectorMapLayer.data_zoom(current + 1):
		failures.append("the nearest zoom should come first")
	for t in dem:
		if t.x > MapStyle.SHADE_MAX_ZOOM:
			failures.append("DEM tile %s past the hillshade zoom" % t)
	if dem.is_empty():
		failures.append("hillshade zooms should be warmed too")
	var far_zoom := current - VectorMapLayer.PREFETCH_FULL_STEPS - 1
	var far_d := VectorMapLayer.data_zoom(far_zoom)
	var far_full := VectorMapLayer.tiles_for(
		TileFetcher.global_pixel(60.17, 24.94, far_zoom) - focus, view, far_zoom, 0.0).size()
	var far_planned := vector.filter(func(t: Vector3i) -> bool: return t.x == far_d).size()
	if far_planned == 0 or far_planned > far_full:
		failures.append("far zooms should warm part of the view, got %d of %d" % [far_planned, far_full])
	var small :=VectorMapLayer.prefetch_plan(60.17, 24.94, Vector2(300, 300), Vector2(150, 150), current)
	if (small["vector"] as Array).size() >= vector.size():
		failures.append("a smaller view should warm fewer tiles")

	var f := VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	f.prefetch_tile(14, 0, 0)
	f.prefetch_tile(14, 1, 0)
	if f._prefetch.size() != 2 or f._queue.size() != 0:
		failures.append("prefetch should use its own queue")
	f.discard_queued_except([])
	if f._prefetch.size() != 2:
		failures.append("discarding view tiles must keep the warm-up")
	f.request_tile(14, 1, 0)
	if f._queue != [Vector3i(14, 1, 0)] or f._prefetch.has(Vector3i(14, 1, 0)) \
			or f._prefetch_only.has(Vector3i(14, 1, 0)):
		failures.append("a view request should promote a queued warm-up tile")
	f.clear_prefetch()
	if not f._prefetch.is_empty() or f._pending.has(Vector3i(14, 0, 0)) \
			or not f._pending.has(Vector3i(14, 1, 0)):
		failures.append("clear_prefetch should drop only the warm-up")
	if f.pack.has_tile(0, 0, 0):
		f.prefetch_tile(0, 0, 0)
		if f._prefetch.has(Vector3i(0, 0, 0)):
			failures.append("bundled tiles must not be downloaded")
	f.free()
	_finish(failures)

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("MAP_PREFETCH OK: plan per zoom, nearest first, DEM cap, own queue, promote, clear")
		quit(0)
	else:
		for f in failures:
			printerr("MAP_PREFETCH FAIL: ", f)
		quit(1)
