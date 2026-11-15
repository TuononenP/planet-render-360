class_name PostpassRequest
extends Node

## One small Postpass query (a layer of a few thousand features at most,
## such as the POIs or the bridge outlines): sends the body, converts the
## GeoJSON answer to Overpass `out geom` JSON (PostpassFallback) and
## reports it, or why there is none. The detailed layer, which runs to
## megabytes, converts off-thread in OsmFetcher instead.

signal answered(text: String)
signal failed(reason: String)

var _http: HTTPRequest
var _token := 0

func _init(timeout_s: float = PostpassFallback.TIMEOUT_S) -> void:
	_http = HTTPRequest.new()
	_http.timeout = timeout_s
	add_child(_http)
	_http.request_completed.connect(_on_done)

## Sends `body` (a PostpassFallback.build_*_body); a request still in
## flight is dropped first.
func run(body: String) -> void:
	cancel()
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
	var json := str(PostpassFallback.to_overpass_json(body)["json"])
	if json == "":
		failed.emit("Postpass answer unreadable")
		return
	answered.emit(json)
