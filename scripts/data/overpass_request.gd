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
## so walking the list only delayed the cache and OSM API fallbacks. A
## paused instance (a rate limit, an outage another query just hit, or a
## failed status check) is skipped without a request; a later instance in
## the list is used only when OverpassProbe confirmed it answering, and a
## failed query moves on to such a confirmed instance even past
## max_attempts: it answered seconds ago, so trying it costs little. While a
## status check runs, run() waits for it.

signal answered(text: String)
## `attempts` is the number of requests actually sent (0 when every
## instance was paused), not the instances looked at.
signal exhausted(reason: String, attempts: int)

## An instance that has not started answering after this many seconds is
## abandoned for the fallbacks. Live probe (2026-10-31, Helsinki 1200 m
## detailed query): healthy instances started in 1–8 s, a queued one in
## 32 s, and a dead one never — which used to cost the full attempt
## timeout. 15 s leaves a healthy instance room; one queued longer than
## that is not worth the wait now that the cache and OSM API follow at
## once (it was 35 s until 2026-11-11). A slow body that has started is
## left to finish; only the attempt timeout bounds it.
const FIRST_BYTE_TIMEOUT := 15.0
## First-byte wait for a caller that already holds an older copy of the
## answer (first_byte_timeout): just past the 1–8 s a healthy instance
## takes, the copy is served instead of waiting on a queue.
const FALLBACK_FIRST_BYTE_S := 10.0
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
## endpoint -> Time.get_ticks_msec() until which OverpassProbe's answer
## stands. Only a confirmed instance is used in place of a paused one.
static var _confirmed_until: Dictionary = {}
## endpoints whose current pause came from a status check. Only those are
## lifted by a good status answer: the status page loading proves nothing
## about /api/interpreter after a real query failed there.
static var _cooldown_probe: Dictionary = {}

var _http: HTTPRequest
## Child node, so a pending first-byte check is freed with this request.
var _watchdog: Timer
var _endpoints: Array[String] = []
var _body := ""
var _validate: Callable
var _attempt := 0
## Requests sent before giving up (see the class note). The offline pack,
## which saves layers in bulk, raises it to walk its own mirror pair; with
## more than one allowed, a later instance needs no confirmation.
var max_attempts := 1
var _sent := 0
## Seconds an instance may take to start answering; callers holding an
## older copy lower it to FALLBACK_FIRST_BYTE_S.
var first_byte_timeout := FIRST_BYTE_TIMEOUT
## When the current request was sent: the watchdog checks the wall clock,
## as its timer counts frame time and a stalled frame would fire it early.
var _sent_msec := 0
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
		now_msec: int = Time.get_ticks_msec(), why: String = "rate limited",
		from_probe: bool = false) -> void:
	var until := now_msec + int(seconds * 1000.0)
	# The pause that ends later decides where the pause came from.
	if until >= int(_cooldown_until.get(endpoint, 0)) or not is_cooling(endpoint, now_msec):
		_cooldown_probe[endpoint] = from_probe
		_cooldown_until[endpoint] = until
		_cooldown_why[endpoint] = why
	_confirmed_until.erase(endpoint)

## OverpassProbe found `endpoint` answering with a free slot: lift a pause a
## status check set, and let queries use it in place of a paused instance.
## A pause a real query set stands, and the instance is not confirmed.
static func confirm(endpoint: String, now_msec: int = Time.get_ticks_msec()) -> void:
	if is_cooling(endpoint, now_msec):
		if not bool(_cooldown_probe.get(endpoint, false)):
			return
	_cooldown_until.erase(endpoint)
	_cooldown_why.erase(endpoint)
	_cooldown_probe.erase(endpoint)
	_confirmed_until[endpoint] = now_msec + int(OverpassProbe.REUSE_S * 1000.0)

static func is_confirmed(endpoint: String, now_msec: int = Time.get_ticks_msec()) -> bool:
	return int(_confirmed_until.get(endpoint, 0)) > now_msec

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
	_confirmed_until.clear()
	_cooldown_probe.clear()

## `endpoints` without repeats, in order: a list from the remote config
## cannot hold one twice, but a repeat must never skew a count.
static func unique(endpoints: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for endpoint in endpoints:
		if not out.has(endpoint):
			out.append(endpoint)
	return out

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

## Start `body` (a url-encoded data= form) on the first usable instance of
## `endpoints`, after a status check in flight (OverpassProbe) has finished.
## validate(text) returns "" to accept a 200 payload, or the reason to
## give up on it. It runs on a worker thread (payloads are megabytes), so
## it must not touch scene state.
func run(body: String, validate: Callable, endpoints: Array[String]) -> void:
	cancel()
	_body = body
	_validate = validate
	_endpoints = unique(endpoints)
	_attempt = 0
	_sent = 0
	var token := _token
	var probe := OverpassProbe.waiting()
	if probe != null:
		await probe.settled
		if token != _token:
			return
	_start()

## cancel_request() emits no request_completed, so nothing stale is
## reported after this.
func cancel() -> void:
	_token += 1
	_watchdog.stop()
	_http.cancel_request()

## Whether the instance at `index` may take this request: not paused, and
## either first in the list, confirmed by the status check, or reached by a
## request allowed more than one send.
func _usable(index: int) -> bool:
	var endpoint := _endpoints[index]
	return not is_cooling(endpoint) and (index == 0 or max_attempts > 1 or is_confirmed(endpoint))

func _start() -> void:
	_token += 1
	var paused := ""
	while _attempt < _endpoints.size() and not _usable(_attempt):
		if is_cooling(_endpoints[_attempt]) and paused == "":
			paused = "Overpass %s paused (%s)" % [host_of(_endpoints[_attempt]),
				str(_cooldown_why.get(_endpoints[_attempt], "rate limited"))]
		_attempt += 1
	if _attempt >= _endpoints.size():
		# No instance may take it. Report it later, so callers that
		# connect their signals after run() still hear about it.
		var token := _token
		var attempts := _sent
		var reason := paused if paused != "" else "Overpass has no usable instance"
		(func() -> void:
			if token == _token:
				exhausted.emit(reason, attempts)).call_deferred()
		return
	_sent += 1
	var err := _http.request(_endpoints[_attempt],
		["Content-Type: application/x-www-form-urlencoded",
			"User-Agent: " + Brand.USER_AGENT],
		HTTPClient.METHOD_POST, _body)
	if err != OK:
		_fail("Overpass request failed to start: %s" % err, true)
		return
	_sent_msec = Time.get_ticks_msec()
	if is_inside_tree():
		_watchdog.start(first_byte_timeout)

func _on_watchdog() -> void:
	var left := first_byte_timeout - (Time.get_ticks_msec() - _sent_msec) / 1000.0
	if left > 0.0:
		_watchdog.start(left)
		return
	if _http.get_http_client_status() in _WAITING:
		_http.cancel_request()
		var reason := "Overpass %s sent no response in %d s" % [
			host_of(_endpoints[_attempt]), int(first_byte_timeout)]
		# A short wait (the caller has a copy) says nothing about an outage.
		if first_byte_timeout >= FIRST_BYTE_TIMEOUT:
			start_cooldown(_endpoints[_attempt], OUTAGE_PAUSE_S, Time.get_ticks_msec(), reason)
		_fail(reason, true)

## A later instance the status check confirmed and that is not paused now.
func _next_confirmed() -> bool:
	for i in range(_attempt + 1, _endpoints.size()):
		if is_confirmed(_endpoints[i]) and not is_cooling(_endpoints[i]):
			return true
	return false

func _fail(reason: String, retryable: bool) -> void:
	_watchdog.stop()
	if retryable and _attempt + 1 < _endpoints.size() \
			and (_sent < max_attempts or _next_confirmed()):
		_attempt += 1
		_start()
	else:
		exhausted.emit(reason, _sent)

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
