extends SceneTree

## Substitute only the transport; exercise the real completion,
## validation worker, retry and exhaustion paths without live services.
class ReplySequence extends OverpassRequest:
	var replies: Array = []
	var visited: Array[String] = []
	func _start() -> void:
		_token += 1
		visited.append(_endpoints[_attempt])
		var reply: Array = replies[_attempt]
		_on_done.call_deferred(HTTPRequest.RESULT_SUCCESS, int(reply[0]),
			PackedStringArray(), str(reply[1]).to_utf8_buffer())

func _init() -> void:
	_run()

func _run() -> void:
	var errors: Array[String] = []
	var payload := {"elements": [{"type": OsmQuery.QUERY_MARK, "id": 1},
		{"type": "way", "id": 2, "tags": {"building": "yes"}, "geometry": [
			{"lat": 40.706, "lon": -74.004}, {"lat": 40.706, "lon": -74.0039},
			{"lat": 40.7061, "lon": -74.0039}, {"lat": 40.706, "lon": -74.004}]}]}
	var complete := JSON.stringify(payload)
	if OverpassRequest.payload_error(complete) != "" or not OsmQuery.is_current(complete) \
			or not OsmFetcher._payload_usable(complete) or not FarCityFetcher._usable(complete):
		errors.append("complete geometry must remain reusable")
	payload["remark"] = "runtime error: Query run out of memory using about 2048 MB of RAM."
	var partial := JSON.stringify(payload)
	await _retry_checks(complete, partial, errors)
	if OverpassRequest.payload_error(partial) == "" or OsmQuery.is_current(partial) \
			or OsmFetcher._payload_usable(partial) or FarCityFetcher._usable(partial) \
			or OsmFetcher._detailed_check(40.706, -74.004).call(partial) == "":
		errors.append("partial geometry with a current marker must retry instead of appearing complete")
	if (OsmFetcher.parse_features(partial, 40.706, -74.004)["buildings"] as Array).is_empty():
		errors.append("partial geometry must remain readable for offline fallback")
	CacheStore.dir_override = "user://overpass-payload-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())
	var path := CacheStore.osm_path(40.706, -74.004, 1200)
	OsmFetcher._write_cache(path, partial)
	var fetcher := OsmFetcher.new()
	root.add_child(fetcher)
	fetcher.offline_mode = true
	fetcher._pending_lat = 40.706
	fetcher._pending_lon = -74.004
	fetcher._poi_enabled = false
	if not fetcher._use_cached("fixture", OsmFetcher.SAME_PLACE_M) \
			or not fetcher._fallback_partial or fetcher._fallback_detail != "Partial offline copy":
		errors.append("offline partial cache must be retained and identified as partial")
	fetcher.cancel()
	fetcher.queue_free()
	await process_frame
	var far := FarCityFetcher.new()
	root.add_child(far)
	far.offline_mode = true
	var far_lat := 40.7061 # Nearby coordinate has no bundled preset snapshot.
	var far_path := FarCityFetcher.cache_path(far_lat, -74.004)
	OsmFetcher._write_cache(far_path, partial)
	var finished: Array = []
	far.finished.connect(func(_land: Array, towers: Array) -> void: finished.append(towers))
	far.fetch(far_lat, -74.004)
	var start := Time.get_ticks_msec()
	while finished.is_empty() and Time.get_ticks_msec() - start < 3000:
		await process_frame
	if finished.is_empty() or not bool(far.timings.get("partial", false)) or finished[0].is_empty():
		errors.append("far-city partial geometry must remain available offline and be reported as partial")
	far.queue_free()
	await process_frame
	DirAccess.remove_absolute(far_path)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(CacheStore.base_dir())
	CacheStore.dir_override = ""
	var sources := WorldCache._source_files("res://scripts/generation")
	if not sources.has("res://scripts/generation/landmarks/bridges/landmark_br_manhattan.gd"):
		errors.append("world fingerprint must include nested landmark builders")
	if errors.is_empty():
		print("OVERPASS PAYLOAD OK: complete replies, runtime errors, partial offline fallback, nested cache sources")
		quit(0)
	else:
		for error in errors:
			printerr("OVERPASS PAYLOAD FAIL: ", error)
		quit(1)

func _retry_checks(complete: String, partial: String, errors: Array[String]) -> void:
	for test in [
		{"replies": [[403, "white-listed usages only"], [200, partial], [200, complete]],
			"attempts": 3, "accepted": true},
		{"replies": [[400, "invalid query"], [200, complete]], "attempts": 1, "accepted": false},
		{"replies": [[403, "denied"], [403, "denied"]], "attempts": 2, "accepted": false}]:
		var request := ReplySequence.new()
		request.replies = test["replies"]
		root.add_child(request)
		var accepted: Array[String] = []
		var exhausted: Array[int] = []
		request.answered.connect(func(text: String) -> void: accepted.append(text))
		request.exhausted.connect(func(_reason: String, attempts: int) -> void: exhausted.append(attempts))
		var endpoints: Array[String] = []
		for i in request.replies.size():
			endpoints.append("fixture://mirror-%d" % i)
		request.run("data=fixture", func(text: String) -> String:
			return "" if OsmFetcher._payload_usable(text) else "invalid payload", endpoints)
		var start := Time.get_ticks_msec()
		while accepted.is_empty() and exhausted.is_empty() and Time.get_ticks_msec() - start < 3000:
			await process_frame
		if request.visited != endpoints.slice(0, int(test["attempts"])):
			errors.append("retry chain must advance to each remaining public mirror exactly once")
		if bool(test["accepted"]):
			if accepted != [complete] or not exhausted.is_empty():
				errors.append("403 and partial geometry must fall through to the complete reply")
		elif not accepted.is_empty() or exhausted != [int(test["attempts"])]:
			errors.append("invalid queries and exhausted mirrors must fail with the correct attempt count")
		request.queue_free()
		await process_frame
