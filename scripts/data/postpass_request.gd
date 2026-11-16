class_name PostpassRequest
extends Node

## One Postpass layer query (the POIs, the bridge outlines, or a wider
## layer through LayerRequest): sends the body, converts the GeoJSON answer
## to Overpass `out geom` JSON (PostpassFallback) on a worker, as the far
## city's runs to megabytes, and reports it, or why there is none. The
## detailed layer converts off-thread in OsmFetcher.

signal answered(text: String)
signal failed(reason: String)

var _http: HTTPRequest
var _token := 0
var _check := Callable()
var _task := -1

func _init(timeout_s: float = PostpassFallback.TIMEOUT_S) -> void:
	_http = HTTPRequest.new()
	_http.timeout = timeout_s
	add_child(_http)
	_http.request_completed.connect(_on_done)

## The conversion must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join()

func _join() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1

## Sends `body` (a PostpassFallback.build_*_body); a request still in
## flight is dropped first. `check`, when given, runs on the worker too and
## returns "" for a usable converted answer, or why it is not.
func run(body: String, check: Callable = Callable()) -> void:
	cancel()
	_check = check
	var err := _http.request(PostpassFallback.endpoint(), PostpassFallback.headers(),
		HTTPClient.METHOD_POST, body)
	if err != OK:
		var token := _token
		(func() -> void:
			if token == _token:
				failed.emit("Postpass failed to start: %s" % err)).call_deferred()

## cancel_request() emits no request_completed, so nothing stale lands.
func cancel() -> void:
	_token += 1
	_http.cancel_request()

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Postpass result=%d code=%d" % [result, code])
		return
	_join()
	var token := _token
	var check := _check
	_task = WorkerThreadPool.add_task(func() -> void:
		var json := str(PostpassFallback.to_overpass_json(body)["json"])
		var why := "Postpass answer unreadable" if json == "" \
			else ("" if not check.is_valid() else str(check.call(json)))
		_converted.call_deferred(token, json, why))

## A stale conversion returns before joining: the task id may already be a
## newer one's.
func _converted(token: int, json: String, why: String) -> void:
	if token != _token:
		return
	_join()
	if why != "":
		failed.emit(why if why.begins_with("Postpass") else "Postpass " + why)
	else:
		answered.emit(json)
