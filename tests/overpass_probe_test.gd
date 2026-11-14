extends SceneTree

## Headless: godot --headless --script tests/overpass_probe_test.gd
## The status check a 3D load starts with (OverpassProbe): status pages
## read as ok / busy / down, the verdicts land in OverpassRequest's shared
## table, a query waits for a check in flight, and a later instance is
## used in place of a paused first one only once the check confirmed it.
## No network: requests are inspected before they would be sent.

## Records the instance _start would send to, without a transport.
class Recorder extends OverpassRequest:
	var started: Array[String] = []
	func _start() -> void:
		_token += 1
		started.append(_endpoints[_attempt])

const MAIN := "https://overpass-api.de/api/interpreter"
const MIRROR := "https://overpass.private.coffee/api/interpreter"

var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	OverpassRequest.clear_cooldowns()
	OverpassProbe.reset()
	_verdicts()
	_table()
	_choice()
	await _waits()
	_stall()
	_early()
	await _short_wait()
	_stale()
	OverpassRequest.clear_cooldowns()
	if _failures.is_empty():
		print("OVERPASS PROBE OK: status verdicts, shared table, mirror only when confirmed, queries wait for the check")
		quit(0)
	else:
		for f in _failures:
			printerr("OVERPASS PROBE FAIL: ", f)
		quit(1)

func _verdicts() -> void:
	if OverpassProbe.status_url(MAIN) != "https://overpass-api.de/api/status" \
			or OverpassProbe.status_url(MIRROR) != "https://overpass.private.coffee/api/status":
		_failures.append("status_url should swap /interpreter for /status")
	var ok := HTTPRequest.RESULT_SUCCESS
	var cases := [
		[ok, 200, "Connected as: 1\nRate limit: 2\n2 slots available now.\n", "ok"],
		[ok, 200, "Connected as: 1\nRate limit: 0\n", "ok"],
		[ok, 200, "Rate limit: 2\nSlot available after: 2026-11-11T16:00:12Z, in 12 seconds.\n", "busy"],
		[ok, 200, "Rate limit: 2\nSlot available after: 2026-11-11T16:00:04Z, in 4 seconds.\n", "wait"],
		[ok, 200, "Rate limit: 2\n0 slots available now.\nSlot available after: 2026-11-11T16:02:00Z, in 120 seconds.\n", "busy"],
		[HTTPRequest.RESULT_TIMEOUT, 0, "", "down"],
		[HTTPRequest.RESULT_CANT_CONNECT, 0, "", "down"],
		[ok, 404, "Not Found", "down"],
		[ok, 200, "", "down"],
	]
	for c in cases:
		var v := OverpassProbe.verdict(int(c[0]), int(c[1]), str(c[2]))
		if str(v["state"]) != str(c[3]):
			_failures.append("status %s / %s / %s should read %s, got %s" % [c[0], c[1], str(c[2]).c_escape(), c[3], v])
	var short := OverpassProbe.verdict(ok, 200, "Slot available after: x, in 12 seconds.")
	if float(short["wait_s"]) != 12.0:
		_failures.append("a slot wait should pause for exactly the seconds the server gives")
	var long := OverpassProbe.verdict(ok, 200, "Slot available after: x, in 120 seconds.")
	if float(long["wait_s"]) != 120.0:
		_failures.append("a longer slot wait should be honoured")

func _table() -> void:
	var now := 5000
	OverpassProbe.apply(MAIN, OverpassProbe.verdict(HTTPRequest.RESULT_CANT_CONNECT, 0, ""), now)
	if not OverpassRequest.is_cooling(MAIN, now + 1000) or OverpassRequest.is_confirmed(MAIN, now + 1000):
		_failures.append("a failed status check should pause the instance")
	OverpassProbe.apply(MAIN, OverpassProbe.verdict(HTTPRequest.RESULT_SUCCESS, 200, "2 slots available now."), now)
	if OverpassRequest.is_cooling(MAIN, now + 1000) or not OverpassRequest.is_confirmed(MAIN, now + 1000):
		_failures.append("an answering instance should be confirmed and its pause lifted")
	if OverpassRequest.is_confirmed(MAIN, now + int(OverpassProbe.REUSE_S * 1000.0) + 1):
		_failures.append("a confirmation should lapse after REUSE_S")
	OverpassRequest.start_cooldown(MAIN, 30.0, now)
	if OverpassRequest.is_confirmed(MAIN, now + 1000):
		_failures.append("a later failure should drop the confirmation")
	# A good status page must not lift a pause a real query set (a 504 on
	# /api/interpreter), nor confirm the instance meanwhile.
	OverpassRequest.confirm(MAIN, now + 2000)
	if not OverpassRequest.is_cooling(MAIN, now + 2000) or OverpassRequest.is_confirmed(MAIN, now + 2000):
		_failures.append("a status answer must not lift or confirm over a query's pause")
	OverpassRequest.clear_cooldowns()
	# A pause a status check set is lifted by the next good answer.
	OverpassProbe.apply(MAIN, OverpassProbe.verdict(HTTPRequest.RESULT_CANT_CONNECT, 0, ""), now)
	OverpassRequest.confirm(MAIN, now + 2000)
	if OverpassRequest.is_cooling(MAIN, now + 2000) or not OverpassRequest.is_confirmed(MAIN, now + 2000):
		_failures.append("a good status answer should lift a pause a status check set")
	# A query's pause that outlasts a status pause keeps its origin.
	OverpassRequest.clear_cooldowns()
	OverpassProbe.apply(MAIN, OverpassProbe.verdict(HTTPRequest.RESULT_CANT_CONNECT, 0, ""), now)
	OverpassRequest.start_cooldown(MAIN, 300.0, now)
	OverpassRequest.confirm(MAIN, now + 2000)
	if not OverpassRequest.is_cooling(MAIN, now + 2000):
		_failures.append("a longer pause from a query must outlive a status pause")
	OverpassRequest.clear_cooldowns()
	# A slot freeing in seconds is waited out, never paused.
	OverpassProbe.apply(MAIN, OverpassProbe.verdict(HTTPRequest.RESULT_SUCCESS, 200,
		"Slot available after: x, in 4 seconds."), now)
	if OverpassRequest.is_cooling(MAIN, now + 1000) or not OverpassRequest.is_confirmed(MAIN, now + 1000):
		_failures.append("a short slot wait should confirm the instance, not pause it")
	OverpassProbe.apply(MAIN, OverpassProbe.verdict(HTTPRequest.RESULT_SUCCESS, 200,
		"Slot available after: x, in 45 seconds."), now)
	if not OverpassRequest.is_cooling(MAIN, now + 44000) or OverpassRequest.is_cooling(MAIN, now + 45001):
		_failures.append("a long slot wait should pause for exactly that long")
	OverpassRequest.clear_cooldowns()

func _choice() -> void:
	var twice: Array[String] = [MAIN, MIRROR, MAIN]
	if OverpassRequest.unique(twice) != [MAIN, MIRROR]:
		_failures.append("a repeated instance should be asked once, in order")
	var req := OverpassRequest.new()
	var endpoints: Array[String] = [MAIN, MIRROR]
	req._endpoints = endpoints
	if not req._usable(0) or req._usable(1):
		_failures.append("the first instance is used as is, a mirror only once confirmed")
	OverpassRequest.start_cooldown(MAIN, OverpassRequest.OUTAGE_PAUSE_S)
	OverpassRequest.confirm(MIRROR)
	if req._usable(0) or not req._usable(1):
		_failures.append("a paused first instance should give way to a confirmed mirror")
	OverpassRequest.clear_cooldowns()
	req.max_attempts = 2
	if not req._usable(1):
		_failures.append("a request allowed two sends (offline pack) needs no confirmation")
	req.free()

func _waits() -> void:
	var probe := OverpassProbe.new()
	root.add_child(probe)
	OverpassProbe.active = probe
	var req := Recorder.new()
	root.add_child(req)
	var endpoints: Array[String] = [MAIN, MIRROR]
	req.run("data=x", func(_t: String) -> String: return "", endpoints)
	await process_frame
	if not req.started.is_empty():
		_failures.append("a query should wait while the status check runs")
	OverpassProbe.active = null
	probe._settle()
	await process_frame
	if req.started != [MAIN]:
		_failures.append("the query should start once the check finishes: %s" % [req.started])
	# A cancel while waiting must leave nothing to start afterwards.
	OverpassProbe.active = probe
	probe._settled = false
	req.started.clear()
	req.run("data=x", func(_t: String) -> String: return "", endpoints)
	req.cancel()
	OverpassProbe.active = null
	probe._settle()
	await process_frame
	if not req.started.is_empty():
		_failures.append("a query cancelled while waiting should not start")
	# A probe freed mid-check releases its waiters instead of stranding them.
	var doomed := OverpassProbe.new()
	root.add_child(doomed)
	OverpassProbe.active = doomed
	req.run("data=x", func(_t: String) -> String: return "", endpoints)
	doomed.free()
	await process_frame
	if OverpassProbe.active != null or req.started != [MAIN]:
		_failures.append("freeing the check should release the waiting query: %s" % [req.started])
	req.free()
	probe.free()

## A frame that stalls past the deadline must not time the check out:
## only wall-clock time counts (STATUS_TIMEOUT_S).
func _stall() -> void:
	var probe := OverpassProbe.new()
	root.add_child(probe)
	var endpoints: Array[String] = ["http://127.0.0.1:9/api/interpreter"]
	OverpassProbe.reset()
	probe.start(endpoints)
	OverpassProbe.active = probe
	probe._started_msec = Time.get_ticks_msec()
	probe._on_deadline()
	if OverpassProbe.active != probe or not probe._waiting.has(endpoints[0]):
		_failures.append("the deadline timer firing early (a stalled frame) must not end the check")
	probe._started_msec -= int(OverpassProbe.STATUS_TIMEOUT_S * 1000.0) + 1
	probe._on_deadline()
	if OverpassProbe.active != null or not OverpassRequest.is_cooling(endpoints[0]):
		_failures.append("past the wall-clock deadline the instance should be paused as down")
	probe.free()
	OverpassRequest.clear_cooldowns()
	OverpassProbe.reset()

## The first instance answering releases the queries at once; a silent
## mirror keeps only the check itself running.
func _early() -> void:
	var probe := OverpassProbe.new()
	root.add_child(probe)
	var endpoints: Array[String] = ["http://127.0.0.1:9/a/interpreter", "http://127.0.0.1:9/b/interpreter"]
	OverpassProbe.reset()
	probe.start(endpoints)
	probe._on_status(endpoints[0], HTTPRequest.RESULT_SUCCESS, 200, "Rate limit: 2\n2 slots available now.")
	if not probe.is_settled() or OverpassProbe.active != probe:
		_failures.append("the first instance answering should settle the check while the mirror is still asked")
	probe._on_status(endpoints[1], HTTPRequest.RESULT_TIMEOUT, 0, "")
	if OverpassProbe.active != null:
		_failures.append("the check should finish once every instance has answered")
	probe.free()
	OverpassRequest.clear_cooldowns()
	OverpassProbe.reset()

## The main instance's next slot is seconds away: the queries are held back
## for it instead of the instance being paused.
func _short_wait() -> void:
	var probe := OverpassProbe.new()
	root.add_child(probe)
	var endpoints: Array[String] = ["http://127.0.0.1:9/a/interpreter", "http://127.0.0.1:9/b/interpreter"]
	OverpassProbe.reset()
	probe.start(endpoints)
	probe._on_status(endpoints[0], HTTPRequest.RESULT_SUCCESS, 200, "Slot available after: x, in 3 seconds.")
	if probe.is_settled() or OverpassProbe.waiting() != probe:
		_failures.append("a short slot wait should hold the queries until the slot frees")
	if OverpassRequest.is_cooling(endpoints[0]):
		_failures.append("the instance must not be paused for a short slot wait")
	probe._hold_until = Time.get_ticks_msec() - 1
	probe._settle()
	if not probe.is_settled() or OverpassProbe.holding != null:
		_failures.append("the queries should be released when the slot wait is over")
	# A cancel releases at once, whatever is left of the wait.
	OverpassProbe.reset()
	probe._settled = false
	probe.start(endpoints)
	probe._on_status(endpoints[0], HTTPRequest.RESULT_SUCCESS, 200, "Slot available after: x, in 9 seconds.")
	probe.cancel()
	if not probe.is_settled():
		_failures.append("cancel should release the queries without waiting out the slot")
	probe.free()
	OverpassRequest.clear_cooldowns()
	OverpassProbe.reset()

## A result queued for a check that was cancelled must not reach the next one.
func _stale() -> void:
	var probe := OverpassProbe.new()
	root.add_child(probe)
	var endpoints: Array[String] = ["http://127.0.0.1:9/api/interpreter"]
	OverpassProbe.reset()
	probe.start(endpoints)
	var old_epoch := probe._epoch
	probe.cancel()
	probe.start(endpoints)
	if probe._epoch == old_epoch:
		_failures.append("a restarted check should be a new epoch")
	probe.free()
	OverpassRequest.clear_cooldowns()
	OverpassProbe.reset()
