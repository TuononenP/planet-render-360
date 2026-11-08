extends SceneTree

var failures := 0
var finished := false
var count := 0

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _run() -> void:
	var valid_entry := [10.0, 20.0, "far", 3, "2026-11-03T00:00:00", 12, "a".repeat(64)]
	check(BundledOsm._valid_manifest_row(valid_entry), "valid capital manifest row must be accepted")
	check(not BundledOsm._valid_manifest_row([10.0, 20.0]), "short manifest row must be rejected")
	var invalid := valid_entry.duplicate()
	invalid[0] = "bad latitude"
	check(not BundledOsm._valid_manifest_row(invalid), "invalid coordinates must be rejected")
	invalid = valid_entry.duplicate()
	invalid[2] = "unknown"
	check(not BundledOsm._valid_manifest_row(invalid), "unknown layer must be rejected")
	invalid = valid_entry.duplicate()
	invalid[4] = ""
	check(not BundledOsm._valid_manifest_row(invalid), "missing source timestamp must be rejected")
	invalid = valid_entry.duplicate()
	invalid[6] = "x".repeat(64)
	check(not BundledOsm._valid_manifest_row(invalid), "invalid hash must be rejected")
	invalid = valid_entry.duplicate()
	invalid[5] = BundledOsm.MAX_BYTES + 1
	check(not BundledOsm._valid_manifest_row(invalid), "oversized payload must be rejected")
	var rows := [
		[40.7060, -74.0040, "detailed", 12],
		[37.8040, -122.4195, "detailed", 12],
		[60.1680, 24.9530, "far", 3],
		[59.3207, 18.0604, "far", 3],
		[60.1680, 24.9530, "detailed", 12],
		[59.3207, 18.0604, "detailed", 12],
		[60.1680, 24.9530, "ring1600", 1],
		[60.1680, 24.9530, "ring2500", 1],
		[60.1680, 24.9530, "poi", 1],
		[59.3207, 18.0604, "ring1600", 1],
		[59.3207, 18.0604, "ring2500", 1],
		[59.3207, 18.0604, "poi", 1],
		[40.7060, -74.0040, "far", 3],
		[37.8040, -122.4195, "far", 3],
		[40.7060, -74.0040, "ring1600", 1],
		[40.7060, -74.0040, "ring2500", 1],
		[40.7060, -74.0040, "poi", 1],
		[37.8040, -122.4195, "ring1600", 1],
		[37.8040, -122.4195, "ring2500", 1],
		[37.8040, -122.4195, "poi", 1],
	]
	for row in rows:
		var key := BundledOsm.entry_for(row[0], row[1], row[2], row[3])
		check(key != "", "preset snapshot must match")
		var rounded := Vector2(row[0], row[1])
		check(BundledOsm.entry_for(rounded.x, rounded.y, row[2], row[3]) == key,
			"preset snapshot must match coordinates passed through Vector2")
		var text := BundledOsm.read(key)
		check(text != "", "%s should load" % key)
		# The header shortcut must agree with the full parse on real payloads.
		check(BundledOsm.header_stamp(text) != "", "%s should have its timestamp in the header" % key)
		check(BundledOsm._response_is_newer(text, key) == BundledOsm._response_is_newer_parsed(text, key),
			"%s: header and full-parse freshness should agree" % key)
		if row[2] == "detailed":
			var parsed := OsmFetcher.parse_features(text, row[0], row[1])
			check((parsed.buildings as Array).size() > 100, "%s should contain buildings" % key)
		elif row[2] == "far":
			var parsed := FarCityFetcher.parse(text, row[0], row[1])
			check((parsed.get("towers", []) as Array).size() > 0, "%s should contain towers" % key)
		check(BundledOsm.entry_for(row[0], row[1], row[2], row[3] + 1) == "", "wrong version must not match")
		check(BundledOsm.entry_for(row[0] + 0.0002, row[1], row[2], row[3]) == "", "nearby point must not match")
	check(BundledOsm.read("missing") == "", "missing snapshot must be ignored")
	_header_checks()
	await _fetch_checks()
	print("bundled_osm_test: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _header_checks() -> void:
	var key := BundledOsm.entry_for(40.7060, -74.0040, "detailed", OsmQuery.QUERY_VERSION)
	var newer := '{"version":0.6,"osm3s":{"timestamp_osm_base":"2030-01-01T00:00:00Z"},"elements":[]}'
	var older := '{"version":0.6,"osm3s":{"timestamp_osm_base":"2020-01-01T00:00:00Z"},"elements":[]}'
	check(BundledOsm.header_stamp(newer) == "2030-01-01T00:00:00", "header stamp should drop the Z")
	check(BundledOsm._response_is_newer(newer, key), "a newer header should win")
	check(not BundledOsm._response_is_newer(older, key), "an older header should not")
	# Not a normal response: these take the full parse, and must still be refused.
	var remark := '{"osm3s":{"timestamp_osm_base":"2030-01-01T00:00:00Z"},"elements":[],"remark":"runtime error"}'
	check(not BundledOsm._response_is_newer(remark, key), "a response with a remark must not win")
	var no_elements := '{"osm3s":{"timestamp_osm_base":"2030-01-01T00:00:00Z"}}'
	check(not BundledOsm._response_is_newer(no_elements, key), "a response without elements must not win")
	check(BundledOsm.header_stamp("{}") == "" and BundledOsm.header_stamp("") == "", "no header, no stamp")
	check(BundledOsm.header_stamp('{"osm3s":{"timestamp_osm_base"') == "", "a cut-off header gives no stamp")
	var late := '{"elements":[],"osm3s":{"timestamp_osm_base":"2030-01-01T00:00:00Z"}}'
	check(BundledOsm._response_is_newer(late, key), "a timestamp after the elements still counts, via the full parse")

func _fetch_checks() -> void:
	var dir := "user://bundled_osm_test"
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	CacheStore.eviction_suppressed = true
	var cache := CacheStore.osm_path(40.7060, -74.0040, 1200)
	var key := BundledOsm.entry_for(40.7060, -74.0040, "detailed", OsmQuery.QUERY_VERSION)
	var file := FileAccess.open(cache, FileAccess.WRITE)
	file.store_string('{"elements":[],"osm3s":{"timestamp_osm_base":"2020-01-01T00:00:00Z"}}')
	file = null
	check(not BundledOsm.cache_is_newer(cache, key), "older cache must not hide snapshot")
	file = FileAccess.open(cache, FileAccess.WRITE)
	file.store_string('{"elements":[],"osm3s":{"timestamp_osm_base":"2030-01-01T00:00:00Z"}}')
	file = null
	check(BundledOsm.cache_is_newer(cache, key), "newer valid cache must win")
	DirAccess.remove_absolute(cache)
	await _refresh_check(cache, key)
	for row in [[40.7060, -74.0040], [37.8040, -122.4195], [60.1680, 24.9530], [59.3207, 18.0604]]:
		finished = false
		count = 0
		var osm := OsmFetcher.new()
		root.add_child(osm)
		osm.offline_mode = true
		osm.succeeded.connect(func(buildings: Array, _roads: Array, _land: Array, _landmarks: Array) -> void:
			count = buildings.size()
			finished = true)
		osm.failed.connect(func(_reason: String) -> void: finished = true)
		var origin := Vector2(row[0], row[1])
		osm.fetch(origin.x, origin.y, 2)
		var deadline := Time.get_ticks_msec() + 30000
		while not finished and Time.get_ticks_msec() < deadline:
			await process_frame
		check(osm._ring_text != "", "offline fetch must load the bundled ring")
		check(finished and count > 100, "offline detailed fetch must use snapshot")
		check(osm._poi_text != "" and osm.pois.size() > 0, "offline fetch must load bundled POIs")
		osm.queue_free()
	for row in [[60.1680, 24.9530], [59.3207, 18.0604], [40.7060, -74.0040], [37.8040, -122.4195]]:
		finished = false
		count = 0
		var far := FarCityFetcher.new()
		root.add_child(far)
		far.offline_mode = true
		far.finished.connect(func(_landuse: Array, towers: Array) -> void:
			count = towers.size()
			finished = true)
		var origin := Vector2(row[0], row[1])
		far.fetch(origin.x, origin.y)
		var deadline := Time.get_ticks_msec() + 30000
		while not finished and Time.get_ticks_msec() < deadline:
			await process_frame
		check(finished and count > 0, "offline far-city fetch must use snapshot")
		far.queue_free()
	CacheStore.finish()
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	DirAccess.remove_absolute(dir)

func _refresh_check(path: String, key: String) -> void:
	var server := TCPServer.new()
	var error := server.listen(0, "127.0.0.1")
	check(error == OK, "refresh test server must start")
	if error != OK:
		return
	var endpoint: Array[String] = ["http://127.0.0.1:%d/" % server.get_local_port()]
	var payload := '{"elements":[{"type":"pr360_q12"}],"osm3s":{"timestamp_osm_base":"2030-01-01T00:00:00Z"}}'
	for success in [true, false]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		BundledOsm.refresh(self, key, path, "data=test", func(_text: String) -> String: return "", endpoint)
		var deadline := Time.get_ticks_msec() + 5000
		var peer: StreamPeerTCP
		while not server.is_connection_available() and Time.get_ticks_msec() < deadline:
			await process_frame
		if server.is_connection_available():
			peer = server.take_connection()
			while peer.get_available_bytes() == 0 and Time.get_ticks_msec() < deadline:
				peer.poll()
				await process_frame
			var status := "200 OK" if success else "503 Service Unavailable"
			var body := payload if success else "unavailable"
			peer.put_data(("HTTP/1.1 %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [status, body.to_utf8_buffer().size(), body]).to_utf8_buffer())
		while BundledOsm._refreshing.has(key) and Time.get_ticks_msec() < deadline:
			await process_frame
		check(not BundledOsm._refreshing.has(key), "refresh must finish")
		check(FileAccess.file_exists(path) == success, "only successful refreshes should write cache")
	server.stop()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
