class_name OverpassRequest
extends Node

## One Overpass query tried across an endpoint list in order. Own
## HTTPRequest, so OsmFetcher runs the detailed and ring queries at the
## same time instead of one after the other (the ring alone measured
## ≈8 s on the main instance, 2026-10-31), and FarCityFetcher shares the
## same retry chain. Each caller passes its own endpoint order (see
## OsmFetcher.endpoint_order), so concurrent queries start on different
## instances instead of taking two per-IP slots on the main one.
## By default only one instance is used (max_attempts): the mirrors have
## been no more reliable than the main instance (2026-11-11: TLS handshake
## failures on the main one, silence or refused connections on the rest),
## so walking the list only delayed the cache and OSM API fallbacks. An
## instance that is paused (a rate limit, or an outage another query just
## hit) uses up that attempt without a request being sent.

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
## First-byte wait for a caller that already holds an older copy of the
## answer (first_byte_timeout): past the 1–8 s a healthy instance takes,
## the copy is served instead of waiting on a queue.
const FALLBACK_FIRST_BYTE_S := 12.0
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
## An instance that failed at the network level (TLS, connect, timeout,
## no first byte) or answered 5xx is left alone this long, so the ring,
## horizon, far-city and POI queries of the same load, and a quick reload,
## go to their fallbacks instead of each repeating the failure.
const OUTAGE_PAUSE_S := 90.0
const OUTAGE_CODES: Array[int] = [500, 502, 503, 504]
## endpoint -> Time.get_ticks_msec() it is left alone until. Shared by
## every request, so one throttled answer also holds back later queries.
static var _cooldown_until: Dictionary = {}
## endpoint -> why it is paused, for the reason a skipped query reports.
static var _cooldown_why: Dictionary = {}

var _http: HTTPRequest
## Child node, so a pending first-byte check is freed with this request.
var _watchdog: Timer
var _endpoints: Array[String] = []
var _body := ""
var _validate: Callable
var _attempt := 0
## Instances used, paused ones included, before giving up (see the class
## note). The offline pack, which saves layers in bulk, raises it to walk
## its own mirror pair.
var max_attempts := 1
## Seconds an instance may take to start answering; callers holding an
## older copy lower it to FALLBACK_FIRST_BYTE_S.
var first_byte_timeout := FIRST_BYTE_TIMEOUT
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
		now_msec: int = Time.get_ticks_msec(), why: String = "rate limited") -> void:
	_cooldown_until[endpoint] = maxi(int(_cooldown_until.get(endpoint, 0)),
		now_msec + int(seconds * 1000.0))
	_cooldown_why[endpoint] = why

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
	_cooldown_why.clear()

## "overpass-api.de" for an interpreter URL, for log lines.
static func host_of(url: String) -> String:
	var rest := url.split("://", true, 1)
	return (rest[rest.size() - 1]).split("/", true, 1)[0]

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

## Instances this request may use.
func _limit() -> int:
	return mini(_endpoints.size(), maxi(max_attempts, 1))

func _start() -> void:
	_token += 1
	var paused := ""
	while _attempt < _limit() and is_cooling(_endpoints[_attempt]):
		paused = "Overpass %s paused (%s)" % [host_of(_endpoints[_attempt]),
			str(_cooldown_why.get(_endpoints[_attempt], "rate limited"))]
		_attempt += 1
	if _attempt >= _limit():
		# Every instance it may use is paused. Report it later, so callers
		# that connect their signals after run() still hear about it.
		var token := _token
		var attempts := _attempt
		var reason := paused if paused != "" else "Overpass has no instances"
		(func() -> void:
			if token == _token:
				exhausted.emit(reason, attempts)).call_deferred()
		return
	var err := _http.request(_endpoints[_attempt],
		["Content-Type: application/x-www-form-urlencoded",
			"User-Agent: " + Brand.USER_AGENT],
		HTTPClient.METHOD_POST, _body)
	if err != OK:
		_fail("Overpass request failed to start: %s" % err, true)
		return
	if is_inside_tree():
		_watchdog.start(first_byte_timeout)

func _on_watchdog() -> void:
	if _http.get_http_client_status() in _WAITING:
		_http.cancel_request()
		var reason := "Overpass %s sent no response in %d s" % [
			host_of(_endpoints[_attempt]), int(first_byte_timeout)]
		# A short wait (the caller has a copy) says nothing about an outage.
		if first_byte_timeout >= FIRST_BYTE_TIMEOUT:
			start_cooldown(_endpoints[_attempt], OUTAGE_PAUSE_S, Time.get_ticks_msec(), reason)
		_fail(reason, true)

func _fail(reason: String, retryable: bool) -> void:
	_watchdog.stop()
	if retryable and _attempt + 1 < _limit():
		_attempt += 1
		_start()
	else:
		exhausted.emit(reason, _attempt + 1)

func _on_done(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_watchdog.stop()
	_token += 1
	var endpoint := _endpoints[_attempt]
	var reason := "Overpass %s failed (%sresult=%d code=%d)" % [host_of(endpoint),
		"TLS handshake, " if result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR else "", result, code]
	if result == HTTPRequest.RESULT_SUCCESS and code in RATE_LIMIT_CODES:
		start_cooldown(endpoint, cooldown_seconds(headers))
	elif result != HTTPRequest.RESULT_SUCCESS or code in OUTAGE_CODES:
		start_cooldown(endpoint, OUTAGE_PAUSE_S, Time.get_ticks_msec(), reason)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail(reason, OsmFetcher.is_retryable(result, code))
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
