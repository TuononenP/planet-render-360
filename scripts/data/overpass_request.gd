class_name OverpassRequest
extends Node

## One Overpass query tried across OsmFetcher.ENDPOINTS in order. Own
## HTTPRequest, so OsmFetcher runs the detailed and ring queries at the
## same time instead of one after the other (the ring alone measured
## ≈8 s on the main instance, 2026-10-31).

signal answered(text: String)
signal exhausted(reason: String, attempts: int)

## A mirror that has not started answering after this many seconds is
## abandoned for the next one. Live probe (2026-10-31, Helsinki 1200 m
## detailed query): healthy instances started in 1–8 s, a queued one in
## 32 s, and a dead one never — which used to cost the full
## ATTEMPT_TIMEOUT per phase. A slow body that has started is left to
## finish; only ATTEMPT_TIMEOUT bounds it.
const FIRST_BYTE_TIMEOUT := 20.0
const _WAITING: Array[int] = [HTTPClient.STATUS_RESOLVING,
	HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_REQUESTING]

var _http: HTTPRequest
var _body := ""
var _validate: Callable
var _attempt := 0
## Bumped on every start, completion and cancel: a stale watchdog timer
## must never cancel a later attempt.
var _token := 0

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = OsmFetcher.ATTEMPT_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_done)

## Start `body` (a url-encoded data= form) on the first endpoint.
## validate(text) returns "" to accept a 200 payload, or the reason to
## try the next instance instead.
func run(body: String, validate: Callable) -> void:
	cancel()
	_body = body
	_validate = validate
	_attempt = 0
	_start()

## cancel_request() emits no request_completed, so nothing stale is
## reported after this.
func cancel() -> void:
	_token += 1
	if _http != null:
		_http.cancel_request()

func _start() -> void:
	_token += 1
	var token := _token
	var err := _http.request(OsmFetcher.ENDPOINTS[_attempt],
		["Content-Type: application/x-www-form-urlencoded",
			"User-Agent: PlanetRender360/0.1"],
		HTTPClient.METHOD_POST, _body)
	if err != OK:
		_fail("Overpass request failed to start: %s" % err, true)
		return
	if is_inside_tree():
		get_tree().create_timer(FIRST_BYTE_TIMEOUT).timeout.connect(func() -> void:
			if token == _token and _http.get_http_client_status() in _WAITING:
				_http.cancel_request()
				_fail("Overpass sent no response in %d s" % int(FIRST_BYTE_TIMEOUT), true))

func _fail(reason: String, retryable: bool) -> void:
	var next := OsmFetcher.next_attempt(_attempt, retryable)
	if next >= 0:
		_attempt = next
		_start()
	else:
		exhausted.emit(reason, _attempt + 1)

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_token += 1
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Overpass failed (result=%d code=%d)" % [result, code],
			OsmFetcher.is_retryable(result, code))
		return
	var text := body.get_string_from_utf8()
	var why: String = _validate.call(text)
	if why != "":
		_fail(why, true)
		return
	answered.emit(text)
