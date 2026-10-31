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
	var err := _http.request(_endpoints[_attempt],
		["Content-Type: application/x-www-form-urlencoded",
			"User-Agent: PlanetRender360/0.1"],
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

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_watchdog.stop()
	_token += 1
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Overpass failed (result=%d code=%d)" % [result, code],
			OsmFetcher.is_retryable(result, code))
		return
	_join_validate()
	var token := _token
	var validate := _validate
	_validate_task = WorkerThreadPool.add_task(func() -> void:
		var text := body.get_string_from_utf8()
		var why: String = validate.call(text)
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
