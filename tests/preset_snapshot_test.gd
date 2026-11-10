extends SceneTree

## Every curated view should have independently loadable offline OSM layers.
func _init() -> void:
	_run.call_deferred()

func _places() -> Array:
	var places: Array = PresetViews.ROWS.duplicate()
	places.append({"id": "berlin", "lat": 52.52437, "lon": 13.41053, "country": "DE"})
	# The manifest is published last. Snapshot it before reading provenance so
	# an in-progress preparation cannot introduce a place halfway through a run.
	var entries := BundledOsm._entries()
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/osm_snapshots/capital_provenance.json"))
	if provenance is Dictionary:
		for key in entries:
			if not str(key).begins_with("capital_") or not str(key).ends_with("_detailed"):
				continue
			var id := str(key).trim_suffix("_detailed")
			if not provenance.has(id):
				continue
			var row: Dictionary = provenance[id]
			places.append({"id": id, "lat": row["coordinates"][0], "lon": row["coordinates"][1], "country": row["country"]})
	return places

func _run() -> void:
	var errors: Array[String] = []
	var countries := {"paris": "FR", "alps": "CH", "banff": "CA", "big_sur": "US",
		"tokyo": "JP", "new_york": "US", "new_york_midtown": "US", "stockholm": "SE", "monaco": "MC",
		"dubai": "AE", "london": "GB", "rome": "IT", "venice": "IT",
		"seoul": "KR", "san_francisco": "US", "helsinki": "FI", "espoo": "FI"}
	var places := _places()
	for row in places:
		var pos := Vector2(float(row["lat"]), float(row["lon"]))
		for layer in ["detailed", "ring1600", "ring2500", "poi", "far"]:
			var version := OsmQuery.QUERY_VERSION if layer == "detailed" else (FarCityFetcher.QUERY_VERSION if layer == "far" else (OsmQuery.POI_VERSION if layer == "poi" else OsmQuery.RING_VERSION))
			var key := BundledOsm.entry_for(pos.x, pos.y, layer, version)
			if key == "":
				errors.append("%s: missing %s" % [row["id"], layer])
				continue
			var text := BundledOsm.read(key)
			if text == "":
				errors.append("%s: unreadable %s" % [row["id"], layer])
				continue
			if layer == "detailed":
				var parsed := OsmFetcher.parse_features(text, pos.x, pos.y)
				if (parsed["buildings"] as Array).is_empty() and not OsmFetcher._has_shore_data(parsed):
					errors.append("%s: detailed data contains no buildings or shores" % row["id"])
				if str(parsed["country"]) != str(row.get("country", countries.get(row["id"], ""))):
					errors.append("%s: unexpected country %s" % [row["id"], parsed["country"]])
			if layer == "far":
				var parsed := FarCityFetcher.parse(text, pos.x, pos.y)
				if parsed.is_empty():
					errors.append("%s: far data could not be parsed" % row["id"])
	await _offline_checks(errors, places)
	if errors.is_empty():
		print("PRESET SNAPSHOTS OK: %d presets, five layers each" % places.size())
		quit(0)
	else:
		for error in errors:
			printerr("PRESET SNAPSHOTS FAIL: ", error)
		quit(1)

## Exercise the complete async fetch path for every preset, including
## live-query snapshots, extract-derived places and sparse rural data.
func _offline_checks(errors: Array[String], places: Array) -> void:
	var dir := "user://preset-snapshot-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	CacheStore.eviction_suppressed = true
	for row in places:
		var id := str(row["id"])
		var pos := Vector2(row["lat"], row["lon"])
		var fetcher := OsmFetcher.new()
		root.add_child(fetcher)
		fetcher.offline_mode = true
		var result: Array = []
		fetcher.succeeded.connect(func(b: Array, _r: Array, _l: Array, _m: Array) -> void:
			result.append(b.size()))
		fetcher.failed.connect(func(_reason: String) -> void: result.append(-1))
		fetcher.fetch(pos.x, pos.y, 2)
		var deadline := Time.get_ticks_msec() + 30000
		while result.is_empty() and Time.get_ticks_msec() < deadline:
			await process_frame
		if result.is_empty() or result[0] < 1 or fetcher._ring_text == "" or fetcher._poi_text == "":
			errors.append("%s: offline detailed/ring/POI fetch failed" % id)
		fetcher.queue_free()
		var far := FarCityFetcher.new()
		root.add_child(far)
		far.offline_mode = true
		var far_done: Array = []
		far.finished.connect(func(_land: Array, _towers: Array) -> void: far_done.append(true))
		far.fetch(pos.x, pos.y)
		deadline = Time.get_ticks_msec() + 30000
		while far_done.is_empty() and Time.get_ticks_msec() < deadline:
			await process_frame
		if far_done.is_empty() or not bool(far.timings.get("cached", false)):
			errors.append("%s: offline far-city fetch failed" % id)
		far.queue_free()
	CacheStore.finish()
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	DirAccess.remove_absolute(dir)
