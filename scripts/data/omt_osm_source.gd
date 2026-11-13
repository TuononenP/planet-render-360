class_name OmtOsmSource
extends Node

## Fetches the z14 vector tiles around a place (OpenFreeMap, through the
## map's VectorTileFetcher and its disk cache) and turns them into the
## detailed map layer's terrain-shaping features (OmtToOverpass), so a
## place Overpass does not answer for still gets its water, buildings and
## roads. Started alongside the Overpass query; OsmFetcher uses the result
## only when Overpass and its fallbacks come back empty.
##
## A tile that fails is left out and the result marked partial; nothing
## at all is "" (failed).

signal finished(text: String)

enum State { IDLE, RUNNING, READY, FAILED }

## Bound on the whole fetch; the tiles are a CDN's, usually seconds.
const TIMEOUT_S := 20.0

var state := State.IDLE
## The converted payload once READY ("" otherwise).
var text := ""
## Whether some tiles were missing from `text`.
var partial := false
## Serve only tiles already on disk (tests, and the offline warm path).
var offline_mode := false

var _fetcher: VectorTileFetcher
var _gen := 0
var _tiles: Array[Vector2i] = []
var _bodies: Dictionary = {}
var _left := 0
var _missing := 0
var _task := -1

func _ready() -> void:
	_fetcher = VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	add_child(_fetcher)
	_fetcher.tile_ready.connect(_on_tile)
	_fetcher.tile_failed.connect(func(z: int, x: int, y: int) -> void:
		_on_tile(z, x, y, PackedByteArray(), false))

## Where tiles are read from and cached; tests point it at a fixture folder.
func set_cache_dir(dir: String) -> void:
	_fetcher.cache_dir = dir

func cancel() -> void:
	_gen += 1
	_left = 0
	state = State.IDLE
	text = ""
	partial = false
	if _fetcher != null:
		_fetcher.discard_queued_except([])

func start(lat: float, lon: float, radius_m: float) -> void:
	cancel()
	var gen := _gen
	state = State.RUNNING
	_tiles = OmtToOverpass.tiles_for(lat, lon, radius_m)
	_bodies = {}
	_missing = 0
	_left = _tiles.size()
	if _left == 0:
		_convert()
		return
	if is_inside_tree():
		get_tree().create_timer(TIMEOUT_S).timeout.connect(func() -> void:
			if gen == _gen and state == State.RUNNING and _left > 0:
				print("OmtOsmSource: timed out (%d/%d tiles)" % [_bodies.size(), _tiles.size()])
				_missing += _left
				_left = 0
				_convert())
	for t in _tiles.duplicate():
		if gen != _gen or _left <= 0:
			return
		if offline_mode and not _fetcher._cached(OmtToOverpass.ZOOM, t.x, t.y):
			_on_tile(OmtToOverpass.ZOOM, t.x, t.y, PackedByteArray(), false)
		else:
			_fetcher.request_tile(OmtToOverpass.ZOOM, t.x, t.y)

func _on_tile(z: int, x: int, y: int, body: PackedByteArray, ok: bool = true) -> void:
	var t := Vector2i(x, y)
	if state != State.RUNNING or _left <= 0 or z != OmtToOverpass.ZOOM or not _tiles.has(t) \
			or _bodies.has(t):
		return
	# An empty body is open sea only when the server said so (the fetcher
	# then leaves a sea marker); otherwise it may be a dropped download.
	if ok and (not body.is_empty() or FileAccess.file_exists(_fetcher.sea_path(z, x, y))):
		_bodies[t] = body
	else:
		_missing += 1
	_left -= 1
	if _left == 0:
		_convert()

## MVT decoding and polygon joins take a dense city a moment: off the
## main thread.
func _convert() -> void:
	_join()
	var gen := _gen
	if _bodies.is_empty():
		_settle(gen, "")
		return
	var tiles := _tiles.duplicate()
	var bodies := _bodies.duplicate()
	_task = WorkerThreadPool.add_task(func() -> void:
		_settle.call_deferred(gen, OmtToOverpass.convert(tiles, bodies)))

func _settle(gen: int, result: String) -> void:
	# A stale result must not wait on a newer conversion (_task may be
	# one by now); its own task was joined by the _convert that replaced it.
	if gen != _gen:
		return
	_join()
	text = result
	partial = _missing > 0
	state = State.READY if result != "" else State.FAILED
	if result == "":
		print("OmtOsmSource: no vector map data (%d of %d tiles missing)" % [_missing, _tiles.size()])
	finished.emit(result)

func _join() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1

## The conversion must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join()
