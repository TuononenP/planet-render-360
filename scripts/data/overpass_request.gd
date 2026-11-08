class_name OverpassRequest
extends Node

## One Overpass query tried across an endpoint list in order. Own
## HTTPRequest, so OsmFetcher runs the detailed and ring queries at the
## same time instead of one after the other (the ring alone measured
## ≈8 s on the main instance, 2026-10-31), and FarCityFetcher shares the
## same retry chain. Each caller passes its own endpoint order (see
## OsmFetcher.endpoint_order), so concurrent queries start on different
## instances instead of taking two per-IP slots on the main one.

signal answered(text: String)
signal exhausted(reason: String, attempts: int)

## A mirror that has not started answering after this many seconds is
## abandoned for the next one. Live probe (2026-10-31, Helsinki 1200 m
## detailed query): healthy instances started in 1–8 s, a queued one in
## 32 s, and a dead one never — which used to cost the full attempt
## timeout. 35 s lets that queued-but-healthy instance answer. A slow
## body that has started is left to finish; only the attempt timeout
## bounds it.
const FIRST_BYTE_TIMEOUT := 35.0
## Still waiting for the server to start answering (CONNECTED covers the
## moment between connecting and sending the request, and redirect hops).
const _WAITING: Array[int] = [HTTPClient.STATUS_RESOLVING,
	HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_CONNECTED,
	HTTPClient.STATUS_REQUESTING]
## The Overpass usage guidance asks clients that get HTTP 429 or 406 to
## pause 30 s before sending that instance anything else. A longer
## Retry-After is honoured up to MAX_COOLDOWN_S.
const RATE_LIMIT_CODES: Array[int] = [406, 429]
const DEFAULT_COOLDOWN_S := 30.0
const MAX_COOLDOWN_S := 300.0
## endpoint -> Time.get_ticks_msec() it is left alone until. Shared by
## every request, so one throttled answer also holds back later queries.
static var _cooldown_until: Dictionary = {}

var _http: HTTPRequest
## Child node, so a pending first-byte check is freed with this request.
var _watchdog: Timer
var _endpoints: Array[String] = []
var _body := ""
var _validate: Callable
var _attempt := 0
## Bumped on every start, completion and cancel: a stale watchdog or
## validation result must never act on a later attempt.
var _token := 0
var _validate_task := -1

## A later statement can fail after Overpass has printed valid geometry.
## HTTP 200 must not turn that partial reply into a complete cached map.
static func payload_error(text: String) -> String:
	if not text.contains('"remark"'):
		return ""
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var remark := str(parsed.get("remark", "")).strip_edges()
		if remark != "":
			return "Overpass incomplete response: " + remark
	return ""

## Seconds to leave an instance alone after a rate-limit answer: its
## Retry-After in seconds when that is longer than the default (an
## HTTP-date, or no header, gives the default).
static func cooldown_seconds(headers: PackedStringArray) -> float:
	for header in headers:
		var parts := header.split(":", true, 1)
		if parts.size() == 2 and parts[0].strip_edges().to_lower() == "retry-after":
			var value := parts[1].strip_edges()
			if value.is_valid_float():
				return clampf(value.to_float(), DEFAULT_COOLDOWN_S, MAX_COOLDOWN_S)
	return DEFAULT_COOLDOWN_S

static func start_cooldown(endpoint: String, seconds: float,
		now_msec: int = Time.get_ticks_msec()) -> void:
	_cooldown_until[endpoint] = now_msec + int(seconds * 1000.0)

static func is_cooling(endpoint: String, now_msec: int = Time.get_ticks_msec()) -> bool:
	return int(_cooldown_until.get(endpoint, 0)) > now_msec

## Seconds until the first of `endpoints` takes requests again; 0 when one
## already does.
static func cooldown_left(endpoints: Array[String], now_msec: int = Time.get_ticks_msec()) -> float:
	var soonest := INF
	for endpoint in endpoints:
		soonest = minf(soonest, maxf(float(int(_cooldown_until.get(endpoint, 0)) - now_msec) / 1000.0, 0.0))
	return 0.0 if is_inf(soonest) else soonest

static func clear_cooldowns() -> void:
	_cooldown_until.clear()

## attempt_timeout bounds one attempt end to end (HTTPRequest.timeout).
func _init(attempt_timeout: float = 60.0) -> void:
	_http = HTTPRequest.new()
	_http.timeout = attempt_timeout
	_http.request_completed.connect(_on_done)
	_watchdog = Timer.new()
	_watchdog.one_shot = true
	_watchdog.wait_time = FIRST_BYTE_TIMEOUT
	_watchdog.timeout.connect(_on_watchdog)

func _ready() -> void:
	add_child(_http)
	add_child(_watchdog)

## The validation task must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_validate()

## Start `body` (a url-encoded data= form) on endpoints[0]. validate(text)
## returns "" to accept a 200 payload, or the reason to try the next
## instance instead. It runs on a worker thread (payloads are megabytes),
## so it must not touch scene state.
func run(body: String, validate: Callable, endpoints: Array[String]) -> void:
	cancel()
	_body = body
	_validate = validate
	_endpoints = endpoints
	_attempt = 0
	_start()

## cancel_request() emits no request_completed, so nothing stale is
## reported after this.
func cancel() -> void:
	_token += 1
	_watchdog.stop()
	_http.cancel_request()

func _start() -> void:
	_token += 1
	while _attempt < _endpoints.size() and is_cooling(_endpoints[_attempt]):
		_attempt += 1
	if _attempt >= _endpoints.size():
		# Every instance asked us to wait. Report it later, so callers that
		# connect their signals after run() still hear about it.
		var token := _token
		var attempts := _attempt
		(func() -> void:
			if token == _token:
				exhausted.emit("Overpass is rate limiting requests", attempts)).call_deferred()
		return
	var err := _http.request(_endpoints[_attempt],
		["Content-Type: application/x-www-form-urlencoded",
			"User-Agent: " + Brand.USER_AGENT],
		HTTPClient.METHOD_POST, _body)
	if err != OK:
		_fail("Overpass request failed to start: %s" % err, true)
		return
	if is_inside_tree():
		_watchdog.start()

func _on_watchdog() -> void:
	if _http.get_http_client_status() in _WAITING:
		_http.cancel_request()
		_fail("Overpass sent no response in %d s" % int(FIRST_BYTE_TIMEOUT), true)

func _fail(reason: String, retryable: bool) -> void:
	_watchdog.stop()
	if retryable and _attempt + 1 < _endpoints.size():
		_attempt += 1
		_start()
	else:
		exhausted.emit(reason, _attempt + 1)

func _on_done(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_watchdog.stop()
	_token += 1
	if result == HTTPRequest.RESULT_SUCCESS and code in RATE_LIMIT_CODES:
		start_cooldown(_endpoints[_attempt], cooldown_seconds(headers))
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Overpass failed (result=%d code=%d)" % [result, code],
			OsmFetcher.is_retryable(result, code))
		return
	_join_validate()
	var token := _token
	var validate := _validate
	_validate_task = WorkerThreadPool.add_task(func() -> void:
		var text := body.get_string_from_utf8()
		var why := payload_error(text)
		if why == "":
			why = validate.call(text)
		_on_validated.call_deferred(token, text, why))

func _on_validated(token: int, text: String, why: String) -> void:
	_join_validate()
	if token != _token:
		return
	if why != "":
		_fail(why, true)
		return
	answered.emit(text)

func _join_validate() -> void:
	if _validate_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_validate_task)
		_validate_task = -1
