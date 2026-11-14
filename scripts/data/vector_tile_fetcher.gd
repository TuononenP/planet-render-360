class_name VectorTileFetcher
extends Node

## Raw tile bytes for the vector map (design system Map style): OpenFreeMap
## vector tiles (OpenMapTiles schema, gzip-encoded MVT) or AWS Terrarium
## DEM PNGs for hillshade. Same discipline as TileFetcher: kept-alive
## connections, centre-out queue, on-device cache. Visible tiles come
## first; a capped low-priority warm-up (prefetch_tile) fills the disk cache
## around a newly picked place on at most PREFETCH_CONNECTIONS connections,
## without emitting, so zooming there later reads from disk.
## OpenFreeMap tiles live under a dated path that its TileJSON names. The
## TileJSON is asked for on every start (old builds are retired); until it
## answers, and offline, the last path from disk serves. Cached tiles are
## keyed by z/x/y alone, so they outlive a new planet build. Tiles in
## the bundled MapPack (the zoomed-out levels) never touch the network.

signal tile_ready(z: int, x: int, y: int, body: PackedByteArray)
signal tile_failed(z: int, x: int, y: int)

enum Kind { VECTOR, DEM }

const VECTOR_HOST := "tiles.openfreemap.org"
const TILEJSON_PATH := "/planet"
const DEM_HOST := "s3.amazonaws.com"
const DEM_PATH := "/elevation-tiles-prod/terrarium/%d/%d/%d.png"
const VECTOR_MAX_ZOOM := 14
const DEM_MAX_ZOOM := 15
const CACHE_DIR := "user://cache/vector"
const PATH_CACHE := "user://cache/vector/tiles_path.txt"
const CONNECTIONS := 6
## Connections the warm-up may hold at once; the rest stay free for the view.
const PREFETCH_CONNECTIONS := 2
## The TileJSON request rides a connection under this sentinel "tile".
const TILEJSON_KEY := Vector3i(-1, -1, -1)
## After a failed TileJSON request, ask again after this long.
const TILEJSON_RETRY_MS := 30000

var kind := Kind.VECTOR
## Where tiles are cached; tests point it at a scratch folder.
var cache_dir := CACHE_DIR
## Bundled tiles, looked up before the disk cache.
var pack: MapPack

var _pool: Array[TileConnection] = []
var _queue: Array[Vector3i] = []
var _pending: Dictionary = {}  # Vector3i -> true, queued or in flight
var _prefetch: Array[Vector3i] = []  # warm-up queue, served after _queue
var _prefetch_only: Dictionary = {}  # Vector3i -> true, asked for only by the warm-up
## "/planet/<build>/%d/%d/%d.pbf" once known; "" until the TileJSON lands.
var _tiles_path := ""
var _tilejson_state := 0  # 0 not asked, 1 in flight, 2 done, 3 failed
var _tilejson_retry_ms := 0

func _init(tile_kind: Kind = Kind.VECTOR) -> void:
	kind = tile_kind
	pack = MapPack.shared(MapPack.OMT if kind == Kind.VECTOR else MapPack.DEM)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(cache_dir)
	for i in CONNECTIONS:
		var conn := TileConnection.new()
		conn.host = VECTOR_HOST if kind == Kind.VECTOR else DEM_HOST
		_pool.append(conn)
	if kind == Kind.VECTOR and FileAccess.file_exists(PATH_CACHE):
		_tiles_path = FileAccess.get_file_as_string(PATH_CACHE).strip_edges()
	set_process(false)

func _exit_tree() -> void:
	for conn in _pool:
		conn.close()

func max_zoom() -> int:
	return VECTOR_MAX_ZOOM if kind == Kind.VECTOR else DEM_MAX_ZOOM

func cache_path(z: int, x: int, y: int) -> String:
	if kind == Kind.VECTOR:
		return "%s/omt_%d_%d_%d.pbf" % [cache_dir, z, x, y]
	return "%s/dem_%d_%d_%d.png" % [cache_dir, z, x, y]

## Marker for a vector tile the server answered as empty (open sea), so
## neither the view nor the warm-up asks for it again.
func sea_path(z: int, x: int, y: int) -> String:
	return "%s/omt_%d_%d_%d.sea" % [cache_dir, z, x, y]

## The dated tile path from a TileJSON body, as a printf template, or ""
## when the body has no usable tiles URL. Static so tests can pin it.
static func tiles_path_from_tilejson(text: String) -> String:
	var json: Variant = JSON.parse_string(text)
	if not (json is Dictionary) or not (json as Dictionary).has("tiles"):
		return ""
	var tiles: Variant = (json as Dictionary)["tiles"]
	if not (tiles is Array) or (tiles as Array).is_empty():
		return ""
	var url := str((tiles as Array)[0])
	var host_at := url.find(VECTOR_HOST)
	if host_at < 0 or not url.contains("{z}/{x}/{y}"):
		return ""
	return url.substr(host_at + VECTOR_HOST.length()).replace("{z}/{x}/{y}", "%d/%d/%d")

## Gzip-encoded bodies (OpenFreeMap serves Content-Encoding: gzip, which
## HTTPClient does not undo) come back inflated; anything else unchanged.
static func inflate(body: PackedByteArray) -> PackedByteArray:
	if body.size() > 2 and body[0] == 0x1f and body[1] == 0x8b:
		return body.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return body

func request_tile(z: int, x: int, y: int) -> void:
	var max_tile := 1 << z
	if z < 0 or z > max_zoom() or x < 0 or y < 0 or x >= max_tile or y >= max_tile:
		return
	var key := Vector3i(z, x, y)
	if _pending.has(key):
		if _prefetch_only.has(key):
			# The view wants a warm-up tile: emit it when it lands, and serve
			# it next if it has not started yet.
			_prefetch_only.erase(key)
			if _prefetch.has(key):
				_prefetch.erase(key)
				_queue.push_front(key)
				_pump()
		return
	if pack.has_tile(z, x, y):
		tile_ready.emit(z, x, y, pack.get_tile(z, x, y))
		return
	var path := cache_path(z, x, y)
	if FileAccess.file_exists(path):
		var body := FileAccess.get_file_as_bytes(path)
		if not body.is_empty():
			CacheStore.note_read(path, -1.0, body.size())
			tile_ready.emit(z, x, y, body)
			return
	if kind == Kind.VECTOR and FileAccess.file_exists(sea_path(z, x, y)):
		CacheStore.note_read(sea_path(z, x, y), -1.0, 0)
		tile_ready.emit(z, x, y, PackedByteArray())
		return
	_pending[key] = true
	_queue.append(key)
	_pump()

## Download (z, x, y) into the disk cache at low priority, without emitting.
## Tiles bundled, cached or already pending are skipped.
func prefetch_tile(z: int, x: int, y: int) -> void:
	var max_tile := 1 << z
	if z < 0 or z > max_zoom() or x < 0 or y < 0 or x >= max_tile or y >= max_tile:
		return
	var key := Vector3i(z, x, y)
	if _pending.has(key) or pack.has_tile(z, x, y) or _cached(z, x, y):
		return
	_pending[key] = true
	_prefetch_only[key] = true
	_prefetch.append(key)
	_pump()

## A usable cache file or sea marker, as request_tile reads them (an
## empty tile file is missing).
func _cached(z: int, x: int, y: int) -> bool:
	if kind == Kind.VECTOR and FileAccess.file_exists(sea_path(z, x, y)):
		return true
	var path := cache_path(z, x, y)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	return f != null and f.get_length() > 0

## Write to the disk cache and tell CacheStore, so the Settings size limit
## evicts map tiles too.
func _store(path: String, body: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_buffer(body)
	f.close()
	CacheStore.note_written(path)

## Forget the queued warm-up (a new place was picked); downloads already
## running finish into the cache.
func clear_prefetch() -> void:
	for t in _prefetch:
		_pending.erase(t)
		_prefetch_only.erase(t)
	_prefetch.clear()

## Drop queued and in-flight tiles outside `keep` (Vector3i z/x/y) and
## serve the survivors in `keep` order, as TileFetcher does. The warm-up
## is left alone.
func discard_queued_except(keep: Array) -> void:
	var keep_set: Dictionary = {}
	for k in keep:
		keep_set[k] = true
	keep_set[TILEJSON_KEY] = true
	for conn in _pool:
		if conn.busy and not keep_set.has(conn.tile) and not _prefetch_only.has(conn.tile):
			_pending.erase(conn.tile)
			conn.cancel()
	var kept: Array[Vector3i] = []
	for k in keep:
		if _queue.has(k):
			kept.append(k)
	for t in _queue:
		if not keep_set.has(t):
			_pending.erase(t)
	_queue = kept
	_pump()

func _pump() -> void:
	if kind == Kind.VECTOR:
		if _tilejson_state == 3 and Time.get_ticks_msec() >= _tilejson_retry_ms:
			_tilejson_state = 0
		if _tilejson_state == 0 and not (_queue.is_empty() and _prefetch.is_empty()):
			for conn in _pool:
				if not conn.busy:
					_tilejson_state = 1
					conn.start(TILEJSON_KEY, TILEJSON_PATH, _headers())
					break
		if _tiles_path == "" and _tilejson_state == 3:
			_fail_queue()
	if kind == Kind.DEM or _tiles_path != "":
		for conn in _pool:
			if not conn.busy and not _queue.is_empty():
				var t: Vector3i = _queue.pop_front()
				conn.start(t, _path_for(t), _headers())
		# Still waiting view tiles take the warm-up's connections: its tiles
		# go back to the front of its queue and start again later.
		for conn in _pool:
			if _queue.is_empty():
				break
			if conn.busy and _prefetch_only.has(conn.tile):
				_prefetch.push_front(conn.tile)
				conn.cancel()
				var t: Vector3i = _queue.pop_front()
				conn.start(t, _path_for(t), _headers())
		var warming := 0
		for conn in _pool:
			if conn.busy and _prefetch_only.has(conn.tile):
				warming += 1
		for conn in _pool:
			if warming >= PREFETCH_CONNECTIONS or _prefetch.is_empty():
				break
			if not conn.busy:
				var t: Vector3i = _prefetch.pop_front()
				conn.start(t, _path_for(t), _headers())
				warming += 1
	set_process(_pool.any(func(c: TileConnection) -> bool: return c.busy))

func _path_for(t: Vector3i) -> String:
	if kind == Kind.VECTOR:
		return _tiles_path % [t.x, t.y, t.z]
	return DEM_PATH % [t.x, t.y, t.z]

## Vector tiles ask for gzip: without it the server sends them inflated
## (a dense Paris z14 tile: 1.1 MB instead of 0.64 MB). inflate() undoes it.
func _headers() -> PackedStringArray:
	var headers := PackedStringArray(["User-Agent: %s" % TileFetcher.USER_AGENT])
	if kind == Kind.VECTOR:
		headers.append("Accept-Encoding: gzip")
	return headers

func _process(_delta: float) -> void:
	for conn in _pool:
		var t := conn.tile
		var res := conn.poll()
		if res.is_empty():
			continue
		if t == TILEJSON_KEY:
			_on_tilejson(bool(res[0]) and int(res[1]) == 200, res[2])
		else:
			_done(t, bool(res[0]), int(res[1]), res[2], int(res[3]) if res.size() > 3 else -1)
	_pump()

func _on_tilejson(ok: bool, body: PackedByteArray) -> void:
	var path := tiles_path_from_tilejson(inflate(body).get_string_from_utf8()) if ok else ""
	if path == "":
		_tilejson_state = 3
		_tilejson_retry_ms = Time.get_ticks_msec() + TILEJSON_RETRY_MS
		push_warning("VectorTileFetcher: OpenFreeMap TileJSON unavailable")
		return
	_tiles_path = path
	_tilejson_state = 2
	var f := FileAccess.open(PATH_CACHE, FileAccess.WRITE)
	if f != null:
		f.store_string(path)

func _fail_queue() -> void:
	for t in _queue:
		_pending.erase(t)
		tile_failed.emit(t.x, t.y, t.z)
	_queue.clear()
	clear_prefetch()

## Whether a 200 body is really a tile (not, say, a captive portal's page).
static func looks_like_tile(tile_kind: Kind, body: PackedByteArray) -> bool:
	if body.size() < 2:
		return false
	if tile_kind == Kind.DEM:
		return body[0] == 0x89 and body[1] == 0x50  # PNG
	return (body[0] == 0x1f and body[1] == 0x8b) or body[0] == 0x1a  # gzip, or an MVT layer

## `declared` is the response's Content-Length (-1 when none was sent): a
## body shorter than it was cut off, and is neither cached nor shown.
func _done(t: Vector3i, ok: bool, code: int, body: PackedByteArray, declared: int = -1) -> void:
	_pending.erase(t)
	var warm_up := _prefetch_only.has(t)
	_prefetch_only.erase(t)
	if ok and code == 404 and kind == Kind.VECTOR and _tilejson_state != 2:
		# The cached build may have been retired: ask the TileJSON again and
		# retry the tile under whatever path it names.
		_tiles_path = ""
		_tilejson_state = 0
		_pending[t] = true
		if warm_up:
			_prefetch_only[t] = true
			_prefetch.push_front(t)
		else:
			_queue.push_front(t)
		return
	if ok and (code == 204 or (code == 200 and body.is_empty() and declared <= 0)) and kind == Kind.VECTOR:
		# Open sea. Remembered only when the server said so outright (204 or
		# Content-Length 0): an empty body alone may be a dropped download.
		if code == 204 or declared == 0:
			_store(sea_path(t.x, t.y, t.z), PackedByteArray())
		if not warm_up:
			tile_ready.emit(t.x, t.y, t.z, PackedByteArray())
		return
	var complete := declared < 0 or body.size() == declared
	var valid := ok and code == 200 and complete and looks_like_tile(kind, body)
	if valid:
		_store(cache_path(t.x, t.y, t.z), body)
	if warm_up:
		return  # cache only: nobody is looking at this tile yet
	if valid:
		tile_ready.emit(t.x, t.y, t.z, body)
	else:
		tile_failed.emit(t.x, t.y, t.z)
