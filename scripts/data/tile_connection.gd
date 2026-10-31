class_name TileConnection
extends RefCounted

## One kept-alive HTTPS connection to the tile host, serving one tile at
## a time. HTTPRequest opens a new TCP + TLS connection for every
## request; reusing one measured 874 → 379 ms per tile (live probe,
## 2026-10-31, 12 z15 tiles). Polled by TileFetcher every frame.

const HOST := "tile.openstreetmap.org"
const TIMEOUT_MS := 20000
## Reads per poll while the body streams in (a tile is 10–40 KB).
const READS_PER_POLL := 8

## Tile in flight; meaningful only while busy.
var tile := Vector3i.ZERO
var busy := false

var _client := HTTPClient.new()
var _path := ""
var _headers: PackedStringArray = []
var _body := PackedByteArray()
var _sent := false
var _retried := false
var _started_ms := 0

func start(t: Vector3i, path: String, headers: PackedStringArray) -> void:
	tile = t
	busy = true
	_path = path
	_headers = headers
	_body = PackedByteArray()
	_sent = false
	_retried = false
	_started_ms = Time.get_ticks_msec()

## Drop the tile in flight. A half-read response cannot be reused, so the
## connection closes; the next tile reconnects.
func cancel() -> void:
	if busy and _sent:
		_client.close()
	busy = false

## Advance the request. Returns [] while pending, else [ok, code, body]
## exactly once per started tile.
func poll() -> Array:
	if not busy:
		return []
	if Time.get_ticks_msec() - _started_ms > TIMEOUT_MS:
		return _fail()
	_client.poll()
	var st := _client.get_status()
	var reads := 0
	while st == HTTPClient.STATUS_BODY and reads < READS_PER_POLL:
		_body.append_array(_client.read_response_body_chunk())
		_client.poll()
		st = _client.get_status()
		reads += 1
	# request() clears the previous response, so a response seen after
	# sending belongs to this tile; CONNECTED again = kept alive.
	if _sent and _client.has_response() \
			and st in [HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_DISCONNECTED]:
		busy = false
		return [true, _client.get_response_code(), _body]
	match st:
		HTTPClient.STATUS_DISCONNECTED:
			if _sent:
				return _retry_or_fail()  # server closed an idle keep-alive
			if _client.connect_to_host(HOST, 443, TLSOptions.client()) != OK:
				return _fail()
		HTTPClient.STATUS_CONNECTED:
			if not _sent:
				if _client.request(HTTPClient.METHOD_GET, _path, _headers) != OK:
					return _retry_or_fail()
				_sent = true
		HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, \
				HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			return _retry_or_fail()
	return []

## A reused connection can be dead by the time it is used (the server
## timed it out): reconnect once before reporting the tile failed.
func _retry_or_fail() -> Array:
	_client.close()
	if _retried:
		return _fail()
	_retried = true
	_sent = false
	_body = PackedByteArray()
	return []

func _fail() -> Array:
	_client.close()
	busy = false
	return [false, 0, PackedByteArray()]
