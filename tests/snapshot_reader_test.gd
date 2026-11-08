extends SceneTree

## Headless: godot --headless --script tests/snapshot_reader_test.gd
## Bundled snapshots load on workers: the text matches a direct read, reads
## in flight do not mix up their results, an empty key never suspends, and a
## fetch cancelled (or replaced) while its snapshot loads emits nothing
## stale. Offline mode and an isolated cache keep it off the network.

var _failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()

func _wait(box: Dictionary, field: String, ms: int = 30000) -> void:
	var deadline := Time.get_ticks_msec() + ms
	while not box.has(field) and Time.get_ticks_msec() < deadline:
		await process_frame

func _run() -> void:
	var dir := "user://snapshot-reader-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	CacheStore.eviction_suppressed = true

	var key_a := BundledOsm.entry_for(40.7060, -74.0040, "detailed", OsmQuery.QUERY_VERSION)
	var key_b := BundledOsm.entry_for(60.1680, 24.9530, "far", FarCityFetcher.QUERY_VERSION)
	if key_a == "" or key_b == "":
		_failures.append("the preset snapshots this test needs are missing")

	# Same text as a direct read; two reads at once keep their own results.
	var reader := SnapshotReader.new()
	root.add_child(reader)
	var out := {}
	var read_into := func(name: String, key: String) -> void:
		out[name] = await reader.read(key)
	read_into.call("a", key_a)
	read_into.call("b", key_b)
	read_into.call("none", "")
	read_into.call("unknown", "no_such_snapshot")
	if not out.has("none") or out["none"] != "":
		_failures.append("an empty key should return \"\" without suspending")
	await _wait(out, "a")
	await _wait(out, "b")
	await _wait(out, "unknown")
	if out.get("a", "") != BundledOsm.read(key_a) or out.get("a", "") == "":
		_failures.append("the detailed snapshot differs from a direct read")
	if out.get("b", "") != BundledOsm.read(key_b) or out.get("b", "") == "":
		_failures.append("the far snapshot differs from a direct read")
	if out.get("a", "") == out.get("b", "x"):
		_failures.append("two reads in flight must not swap their results")
	if out.get("unknown", "x") != "":
		_failures.append("an unknown snapshot should read as \"\"")
	reader.free()

	# Cancelled while the snapshot loads: nothing is emitted for it, and the
	# next fetch on the same fetcher completes normally.
	var osm := OsmFetcher.new()
	root.add_child(osm)
	osm.offline_mode = true
	var seen := {"count": 0}
	osm.succeeded.connect(func(_b: Array, _r: Array, _l: Array, _m: Array) -> void: seen["count"] += 1)
	osm.fetch(40.7060, -74.0040, 2)
	osm.cancel()
	var until := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < until:
		await process_frame
	if seen["count"] != 0:
		_failures.append("a cancelled fetch emitted %d result(s)" % seen["count"])
	osm.fetch(60.1680, 24.9530, 2)
	osm.fetch(40.7060, -74.0040, 2)  # replaces the one just started
	until = Time.get_ticks_msec() + 30000
	while seen["count"] == 0 and Time.get_ticks_msec() < until:
		await process_frame
	var settle := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < settle:
		await process_frame
	if seen["count"] != 1:
		_failures.append("two fetches in a row should give exactly one result (the second), got %d" % seen["count"])
	osm.free()

	# Same for the far city.
	var far := FarCityFetcher.new()
	root.add_child(far)
	far.offline_mode = true
	var far_seen := {"count": 0}
	far.finished.connect(func(_landuse: Array, _towers: Array) -> void: far_seen["count"] += 1)
	far.fetch(60.1680, 24.9530)
	far.cancel()
	until = Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < until:
		await process_frame
	if far_seen["count"] != 0:
		_failures.append("a cancelled far-city fetch emitted %d result(s)" % far_seen["count"])
	far.fetch(60.1680, 24.9530)
	until = Time.get_ticks_msec() + 30000
	while far_seen["count"] == 0 and Time.get_ticks_msec() < until:
		await process_frame
	if far_seen["count"] != 1:
		_failures.append("the far-city fetch after a cancel should give one result, got %d" % far_seen["count"])

	# Freed while a read is in flight: joined, nothing emitted, no crash.
	var gone := OsmFetcher.new()
	root.add_child(gone)
	gone.offline_mode = true
	gone.fetch(40.7060, -74.0040, 2)
	gone.free()
	for i in 20:
		await process_frame
	far.free()

	CacheStore.finish()
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	_failures.erase(_failures[0])
	if _failures.is_empty():
		print("SNAPSHOT READER OK: matches direct read, concurrent reads, cancel, replace, freed mid-read")
		quit(0)
	else:
		for f in _failures:
			printerr("SNAPSHOT READER FAIL: ", f)
		quit(1)
