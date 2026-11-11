class_name OverpassProbe
extends Node

## When a 3D load starts, asks every Overpass instance for its status page
## (`/api/status`: no query runs and no query slot is used) and writes the
## answers into OverpassRequest's shared pause table. The load's queries
## wait for it (OverpassRequest.run), so they go only to an instance that
## answered, and straight to the cache and OSM API when none did, instead
## of finding out by a heavy query failing (2026-11-11: the main instance
## refused connections and private.coffee sent nothing).

## The load's queries may go: the first instance answered, or every
## instance has answered or timed out. A silent mirror then does not hold
## up a load the main instance can serve.
signal settled
signal finished

## A status page is a few hundred bytes: an instance that has not sent it
## in this time is treated as down for this load. Measured on the wall
## clock, not with HTTPRequest.timeout: that timer counts frame time, and a
## load's first frames can stall for seconds (scripts loading, the world
## cache), which timed out healthy instances in 0 ms.
const STATUS_TIMEOUT_S := 4.0
## A finished check stands for this long, so back-to-back loads and a
## reload do not ask again; it is also how long a confirmation lasts.
const REUSE_S := 60.0
## A "next slot in N s" with N up to this is waited out, not treated as an
## outage: the queries are held back N s and then go to the instance. A
## longer wait pauses it for exactly N s. (Queries a reload just cancelled
## can still hold slots for a few seconds; the old 30 s minimum pause sent
## that whole load to the fallbacks.)
const BUSY_WAIT_S := 10.0

## The check in flight, or null. OverpassRequest.run waits on its signal.
static var active: OverpassProbe
## A finished check still holding the queries for a short slot wait.
static var holding: OverpassProbe
static var _checked_msec := -1

var _pending := 0
var _first := ""
var _settled := false
var _started_msec := 0
## Time.get_ticks_msec() until which the queries are held for a slot.
var _hold_until := 0
var _hold: Timer
## Bumped when a check starts or stops, so a result queued for an earlier
## check (a request that failed to start) is dropped.
var _epoch := 0
var _lines: Array[String] = []
var _requests: Array[HTTPRequest] = []
## endpoint -> its HTTPRequest, while no answer has come back.
var _waiting: Dictionary = {}
var _deadline: Timer

## "https://host/api/interpreter" -> "https://host/api/status".
static func status_url(endpoint: String) -> String:
	var slash := endpoint.rfind("/")
	return (endpoint.substr(0, slash) if slash > endpoint.find("://") + 2 else endpoint) + "/status"

## {state: "ok" | "wait" | "busy" | "down", wait_s, slots, why} for one
## status answer. "wait" and "busy" carry the seconds until the IP's next
## free slot: short ones (BUSY_WAIT_S) are waited out, longer ones pause.
static func verdict(result: int, code: int, body: String) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return {"state": "down", "wait_s": 0.0, "slots": 0,
			"why": "status check failed (result=%d code=%d)" % [result, code]}
	var rx := RegEx.new()
	rx.compile("(\\d+) slots? available now")
	var m := rx.search(body)
	if m != null and int(m.get_string(1)) > 0:
		return {"state": "ok", "wait_s": 0.0, "slots": int(m.get_string(1)), "why": ""}
	rx.compile("Rate limit:\\s*0\\b")
	if rx.search(body) != null:
		return {"state": "ok", "wait_s": 0.0, "slots": -1, "why": ""}
	rx.compile("Slot available after:[^\\n]*in (\\d+) seconds?")
	m = rx.search(body)
	if m != null:
		var wait := clampf(float(m.get_string(1)), 1.0, OverpassRequest.MAX_COOLDOWN_S)
		return {"state": "wait" if wait <= BUSY_WAIT_S else "busy", "wait_s": wait,
			"slots": 0, "why": "no free slot"}
	return {"state": "down", "wait_s": 0.0, "slots": 0, "why": "status check unreadable"}

## Write one verdict into the shared table.
static func apply(endpoint: String, v: Dictionary, now_msec: int = Time.get_ticks_msec()) -> void:
	match str(v["state"]):
		"ok", "wait":
			OverpassRequest.confirm(endpoint, now_msec)
		"busy":
			OverpassRequest.start_cooldown(endpoint, float(v["wait_s"]), now_msec,
				str(v["why"]), true)
		_:
			OverpassRequest.start_cooldown(endpoint, OverpassRequest.OUTAGE_PAUSE_S, now_msec,
				str(v["why"]), true)

## The check whose answer queries should wait for, or null.
static func waiting() -> OverpassProbe:
	for probe in [active, holding]:
		if probe != null and not probe.is_settled():
			return probe
	return null

static func reset() -> void:
	_checked_msec = -1

## Check `endpoints` unless a check finished within REUSE_S or one is
## already running.
func start(endpoints: Array[String]) -> void:
	if active != null or endpoints.is_empty():
		return
	var now := Time.get_ticks_msec()
	if _checked_msec >= 0 and now - _checked_msec < int(REUSE_S * 1000.0):
		return
	active = self
	_epoch += 1
	_hold_until = 0
	_started_msec = now
	_lines.clear()
	_waiting.clear()
	_pending = endpoints.size()
	_first = endpoints[0]
	_settled = false
	if _deadline == null:
		_deadline = Timer.new()
		_deadline.one_shot = true
		_deadline.timeout.connect(_on_deadline)
		add_child(_deadline)
	_deadline.start(STATUS_TIMEOUT_S)
	for endpoint in endpoints:
		var http := HTTPRequest.new()
		add_child(http)
		_requests.append(http)
		_waiting[endpoint] = http
		http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray,
				body: PackedByteArray) -> void:
			_on_status(endpoint, result, code, body.get_string_from_utf8()))
		var err := http.request(status_url(endpoint), ["User-Agent: " + Brand.USER_AGENT])
		if err != OK:
			var epoch := _epoch
			(func() -> void:
				if epoch == _epoch:
					_on_status(endpoint, HTTPRequest.RESULT_CANT_CONNECT, 0, "")).call_deferred()

## The timer only wakes the check: what counts is the wall clock, so a
## stalled frame cannot age the requests (see STATUS_TIMEOUT_S).
func _on_deadline() -> void:
	if active != self:
		return
	var left := STATUS_TIMEOUT_S - (Time.get_ticks_msec() - _started_msec) / 1000.0
	if left > 0.0:
		_deadline.start(left)
		return
	for endpoint in _waiting.keys():
		(_waiting[endpoint] as HTTPRequest).cancel_request()
		_on_status(endpoint, HTTPRequest.RESULT_TIMEOUT, 0, "")

func _on_status(endpoint: String, result: int, code: int, body: String) -> void:
	if active != self or not _waiting.has(endpoint):
		return
	_waiting.erase(endpoint)
	var v := verdict(result, code, body)
	apply(endpoint, v)
	if str(v["state"]) == "wait":
		_hold_until = maxi(_hold_until, Time.get_ticks_msec() + int(float(v["wait_s"]) * 1000.0))
	if endpoint == _first and str(v["state"]) in ["ok", "wait"]:
		_settle()
	var ms := Time.get_ticks_msec() - _started_msec
	var host := OverpassRequest.host_of(endpoint)
	match str(v["state"]):
		"ok":
			var slots := int(v["slots"])
			_lines.append("%s ok %s %d ms" % [host, "no limit" if slots < 0 else "%d slots" % slots, ms])
		"wait":
			_lines.append("%s slot in %d s (queries wait), %d ms" % [host, int(v["wait_s"]), ms])
		"busy":
			_lines.append("%s busy, paused %d s, %d ms" % [host, int(v["wait_s"]), ms])
		_:
			_lines.append("%s %s %d ms" % [host, str(v["why"]), ms])
	_pending -= 1
	if _pending <= 0:
		print("OVERPASS STATUS " + "; ".join(PackedStringArray(_lines)))
		_checked_msec = Time.get_ticks_msec()
		_finish()

## Stop a running check. Waiting queries are released (they find the
## table as far as it got), never left hanging.
func cancel() -> void:
	_hold_until = 0
	if active == self:
		_finish()
	elif holding == self:
		_settle()

func is_settled() -> bool:
	return _settled

## Release the queries, once any short slot wait is over.
func _settle() -> void:
	if _settled:
		return
	var left := float(_hold_until - Time.get_ticks_msec()) / 1000.0
	if left > 0.0:
		holding = self
		if _hold == null:
			_hold = Timer.new()
			_hold.one_shot = true
			_hold.timeout.connect(_settle)
			add_child(_hold)
		_hold.start(left)
		return
	_settled = true
	if holding == self:
		holding = null
	settled.emit()

func _finish() -> void:
	active = null
	_epoch += 1
	_settle()
	_waiting.clear()
	if _deadline != null:
		_deadline.stop()
	for http in _requests:
		http.cancel_request()
		http.queue_free()
	_requests.clear()
	finished.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and (active == self or holding == self):
		_hold_until = 0
		if active == self:
			active = null
		_settle()
		finished.emit()
