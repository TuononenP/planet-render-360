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
	var small := VectorMapLayer.prefetch_plan(60.17, 24.94, Vector2(300, 300), Vector2(150, 150), current)
	if (small["vector"] as Array).size() >= vector.size():
		failures.append("a smaller view should warm fewer tiles")

	if VectorMapLayer.warm_up_enabled:
		failures.append("--script runs (tests, captures) must not warm the map cache")
	# A scratch cache, so tiles already on this machine cannot skew the queues.
	var scratch := "user://map_prefetch_test"
	_remove_dir(scratch)
	DirAccess.make_dir_recursive_absolute(scratch)
	CacheStore.dir_override = scratch
	CacheStore.eviction_suppressed = true
	var f := VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	f.cache_dir = scratch
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

	# Open sea is remembered only when the server says so outright.
	var g := VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	g.cache_dir = scratch
	g._done(Vector3i(14, 2, 0), true, 200, PackedByteArray(), -1)
	if FileAccess.file_exists(g.sea_path(14, 2, 0)):
		failures.append("an empty body without Content-Length may be a dropped download, not sea")
	g._done(Vector3i(14, 3, 0), true, 204, PackedByteArray(), -1)
	if not FileAccess.file_exists(g.sea_path(14, 3, 0)) or not g._cached(14, 3, 0):
		failures.append("a 204 should leave a sea marker the warm-up counts as cached")
	g._done(Vector3i(14, 4, 0), true, 200, PackedByteArray([0x1f, 0x8b, 0, 0]), 900)
	if FileAccess.file_exists(g.cache_path(14, 4, 0)):
		failures.append("a body shorter than its Content-Length must not be cached")
	g._done(Vector3i(14, 5, 0), true, 200, PackedByteArray([0x1f, 0x8b, 0, 0]), 4)
	if not g._cached(14, 5, 0):
		failures.append("a complete tile should be cached")

	# A waiting view tile takes a warm-up connection. Connections are only
	# started, never polled, so nothing is sent.
	g._tiles_path = "/planet/test/%d/%d/%d.pbf"
	g._tilejson_state = 2
	for i in VectorTileFetcher.PREFETCH_CONNECTIONS:
		g._pool.append(TileConnection.new())
	g.prefetch_tile(14, 6, 0)
	g.prefetch_tile(14, 7, 0)
	g.prefetch_tile(14, 8, 0)
	if not g._pool.all(func(c: TileConnection) -> bool: return c.busy):
		failures.append("the warm-up should fill its connections")
	g.request_tile(14, 9, 0)
	if not g._pool.any(func(c: TileConnection) -> bool: return c.busy and c.tile == Vector3i(14, 9, 0)):
		failures.append("a view tile should take a warm-up connection when none is free")
	if g._prefetch.size() != 2 or not g._pending.has(g._prefetch[0]):
		failures.append("the displaced warm-up tile should wait at the front of its queue")
	for c in g._pool:
		c.close()
	g.free()
	CacheStore.finish()
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	_remove_dir(scratch)
	_finish(failures)

func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		dir.remove(name)
	DirAccess.remove_absolute(path)

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("MAP_PREFETCH OK: plan per zoom, nearest first, DEM cap, own queue, promote, clear, sea markers, cut-off bodies, view preempts")
		quit(0)
	else:
		for f in failures:
			printerr("MAP_PREFETCH FAIL: ", f)
		quit(1)
