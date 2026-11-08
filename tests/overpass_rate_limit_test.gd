extends SceneTree

## Headless: godot --headless --script tests/overpass_rate_limit_test.gd
## After a 429/406 an Overpass instance is left alone for at least 30 s
## (longer when Retry-After says so), and a request whose every instance
## is cooling reports itself exhausted without sending anything.

var _failures: Array[String] = []

func _init() -> void:
	OverpassRequest.clear_cooldowns()
	_test_seconds()
	_test_cooldown()
	await _test_all_cooling()
	OverpassRequest.clear_cooldowns()
	if _failures.is_empty():
		print("OVERPASS RATE LIMIT OK: Retry-After, cooldown, exhausted when all cooling")
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
