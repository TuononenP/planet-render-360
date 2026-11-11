extends SceneTree

## Headless: godot --headless --script tests/overpass_rate_limit_test.gd
## After a 429/406 an Overpass instance is left alone for at least 30 s
## (longer when Retry-After says so), and a request whose every instance
## is cooling reports itself exhausted without sending anything. A
## network failure or 5xx pauses the instance for later queries, a
## paused first instance sends a single-attempt request straight to its
## fallback, and a place both sources found empty is not asked again.

var _failures: Array[String] = []

func _init() -> void:
	OverpassRequest.clear_cooldowns()
	_test_seconds()
	_test_cooldown()
	await _test_all_cooling()
	OverpassRequest.clear_cooldowns()
	_test_outage()
	await _test_paused_first()
	OverpassRequest.clear_cooldowns()
	_test_empty_marker()
	if _failures.is_empty():
		print("OVERPASS RATE LIMIT OK: Retry-After, cooldown, outage pause, single attempt, empty places")
		quit(0)
	else:
		for f in _failures:
			printerr("OVERPASS RATE LIMIT FAIL: ", f)
		quit(1)

func _test_seconds() -> void:
	var none := PackedStringArray(["Content-Type: text/html"])
	if OverpassRequest.cooldown_seconds(none) != 30.0:
		_failures.append("no Retry-After should give the 30 s default")
	if OverpassRequest.cooldown_seconds(PackedStringArray(["Retry-After: 5"])) != 30.0:
		_failures.append("a short Retry-After should not shorten the 30 s pause")
	if OverpassRequest.cooldown_seconds(PackedStringArray(["retry-after:  90 "])) != 90.0:
		_failures.append("a longer Retry-After should be honoured, any case")
	if OverpassRequest.cooldown_seconds(PackedStringArray(["Retry-After: 99999"])) != OverpassRequest.MAX_COOLDOWN_S:
		_failures.append("Retry-After should be capped")
	if OverpassRequest.cooldown_seconds(PackedStringArray(["Retry-After: Wed, 21 Oct 2026 07:28:00 GMT"])) != 30.0:
		_failures.append("an HTTP-date Retry-After should give the default")

func _test_cooldown() -> void:
	var url := "https://example.test/api/interpreter"
	if OverpassRequest.is_cooling(url, 1000):
		_failures.append("an untouched instance should not be cooling")
	OverpassRequest.start_cooldown(url, 30.0, 1000)
	if not OverpassRequest.is_cooling(url, 30999):
		_failures.append("the instance should cool for the full 30 s")
	if OverpassRequest.is_cooling(url, 31001):
		_failures.append("the instance should be usable once the pause ends")
	if OverpassRequest.is_cooling("https://other.test/api/interpreter", 1000):
		_failures.append("cooling one instance should not affect another")
	var pair: Array[String] = [url, "https://other.test/api/interpreter"]
	OverpassRequest.clear_cooldowns()
	if OverpassRequest.cooldown_left(pair, 1000) != 0.0:
		_failures.append("one free instance means no wait")
	OverpassRequest.start_cooldown(pair[0], 10.0, 1000)
	OverpassRequest.start_cooldown(pair[1], 20.0, 1000)
	if not is_equal_approx(OverpassRequest.cooldown_left(pair, 1000), 10.0):
		_failures.append("the wait should end with the first instance to recover")
	OverpassRequest.clear_cooldowns()
	if not OsmFetcher.is_retryable(HTTPRequest.RESULT_SUCCESS, 406):
		_failures.append("406 should move on to the next instance")

func _test_all_cooling() -> void:
	var urls: Array[String] = ["https://a.test/api", "https://b.test/api"]
	for u in urls:
		OverpassRequest.start_cooldown(u, 30.0)
	var req := OverpassRequest.new()
	root.add_child(req)
	var seen := {"reason": "", "attempts": -1, "answered": false}
	req.exhausted.connect(func(reason: String, attempts: int) -> void:
		seen["reason"] = reason
		seen["attempts"] = attempts)
	req.answered.connect(func(_t: String) -> void: seen["answered"] = true)
	req.run("data=x", func(_t: String) -> String: return "", urls)
	await process_frame
	await process_frame
	if str(seen["reason"]) == "":
		_failures.append("a request with every instance cooling should report exhausted")
	if bool(seen["answered"]):
		_failures.append("a request with every instance cooling should not answer")
	req.free()

## Feed one completion straight into a request, as HTTPRequest would.
func _complete(url: String, result: int, code: int) -> String:
	var req := OverpassRequest.new()
	var seen := [""]
	req.exhausted.connect(func(reason: String, _attempts: int) -> void: seen[0] = reason)
	var endpoints: Array[String] = [url]
	req._endpoints = endpoints
	req._attempt = 0
	req._on_done(result, code, PackedStringArray(), PackedByteArray())
	req.free()
	return seen[0]

func _test_outage() -> void:
	if OverpassRequest.host_of("https://overpass-api.de/api/interpreter") != "overpass-api.de":
		_failures.append("host_of should give the bare host")
	var tls := "https://tls.test/api/interpreter"
	var reason := _complete(tls, HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR, 0)
	if not reason.contains("tls.test") or not reason.contains("TLS handshake"):
		_failures.append("a TLS failure should name the host and the cause: %s" % reason)
	if not OverpassRequest.is_cooling(tls):
		_failures.append("a network failure should pause the instance for later queries")
	var busy := "https://busy.test/api/interpreter"
	_complete(busy, HTTPRequest.RESULT_SUCCESS, 502)
	if not OverpassRequest.is_cooling(busy):
		_failures.append("a 502 should pause the instance")
	var bad := "https://bad.test/api/interpreter"
	_complete(bad, HTTPRequest.RESULT_SUCCESS, 400)
	if OverpassRequest.is_cooling(bad):
		_failures.append("a malformed query (400) says nothing about the instance")

func _test_paused_first() -> void:
	var urls: Array[String] = ["https://down.test/api", "https://free.test/api"]
	OverpassRequest.start_cooldown(urls[0], OverpassRequest.OUTAGE_PAUSE_S,
		Time.get_ticks_msec(), "Overpass down.test failed (result=5 code=0)")
	var req := OverpassRequest.new()
	root.add_child(req)
	var seen := {"reason": "", "attempts": -1}
	req.exhausted.connect(func(reason: String, attempts: int) -> void:
		seen["reason"] = reason
		seen["attempts"] = attempts)
	req.run("data=x", func(_t: String) -> String: return "", urls)
	var sent := req._http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED
	await process_frame
	await process_frame
	# free.test was never confirmed by a status check, so it is not used either.
	if sent or not str(seen["reason"]).contains("down.test paused") or int(seen["attempts"]) != 2:
		_failures.append("a paused first instance should go to the fallback without a request: %s" % [seen])
	req.free()

func _test_empty_marker() -> void:
	CacheStore.eviction_suppressed = true
	CacheStore.dir_override = "user://overpass-empty-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())
	var path := CacheStore.osm_empty_path(12.0, 34.0)
	if OsmFetcher._known_empty(12.0, 34.0):
		_failures.append("a place with no marker should be asked")
	OsmFetcher._write_cache(path, '{"elements":[]}')
	if not OsmFetcher._known_empty(12.0, 34.0):
		_failures.append("a fresh empty marker should skip the live queries")
	if OsmNearbyCache.distance_m(path, 12.0, 34.0) >= 0.0:
		_failures.append("the empty marker must not read as a cached detailed payload")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(CacheStore.base_dir())
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
