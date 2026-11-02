class_name VectorTileFetcher
extends Node

## Raw tile bytes for the vector map (design system Map style): OpenFreeMap
## vector tiles (OpenMapTiles schema, gzip-encoded MVT) or AWS Terrarium
## DEM PNGs for hillshade. Same discipline as TileFetcher: kept-alive
## connections, centre-out queue, only visible tiles, on-device cache.
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
## The TileJSON request rides a connection under this sentinel "tile".
const TILEJSON_KEY := Vector3i(-1, -1, -1)
## After a failed TileJSON request, ask again after this long.
const TILEJSON_RETRY_MS := 30000

var kind := Kind.VECTOR
## Bundled tiles, looked up before the disk cache.
var pack: MapPack

var _pool: Array[TileConnection] = []
var _queue: Array[Vector3i] = []
var _pending: Dictionary = {}  # Vector3i -> true, queued or in flight
## "/planet/<build>/%d/%d/%d.pbf" once known; "" until the TileJSON lands.
var _tiles_path := ""
var _tilejson_state := 0  # 0 not asked, 1 in flight, 2 done, 3 failed
var _tilejson_retry_ms := 0

func _init(tile_kind: Kind = Kind.VECTOR) -> void:
	kind = tile_kind
	pack = MapPack.shared(MapPack.OMT if kind == Kind.VECTOR else MapPack.DEM)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
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
		return "%s/omt_%d_%d_%d.pbf" % [CACHE_DIR, z, x, y]
	return "%s/dem_%d_%d_%d.png" % [CACHE_DIR, z, x, y]

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
		return
	if pack.has_tile(z, x, y):
		tile_ready.emit(z, x, y, pack.get_tile(z, x, y))
		return
	var path := cache_path(z, x, y)
	if FileAccess.file_exists(path):
		var body := FileAccess.get_file_as_bytes(path)
		if not body.is_empty():
			tile_ready.emit(z, x, y, body)
			return
	_pending[key] = true
	_queue.append(key)
	_pump()

## Drop queued and in-flight tiles outside `keep` (Vector3i z/x/y) and
## serve the survivors in `keep` order, as TileFetcher does.
func discard_queued_except(keep: Array) -> void:
	var keep_set: Dictionary = {}
	for k in keep:
		keep_set[k] = true
	keep_set[TILEJSON_KEY] = true
	for conn in _pool:
		if conn.busy and not keep_set.has(conn.tile):
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
		if _tilejson_state == 0 and not _queue.is_empty():
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
			_done(t, bool(res[0]), int(res[1]), res[2])
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

## Whether a 200 body is really a tile (not, say, a captive portal's page).
static func looks_like_tile(tile_kind: Kind, body: PackedByteArray) -> bool:
	if body.size() < 2:
		return false
	if tile_kind == Kind.DEM:
		return body[0] == 0x89 and body[1] == 0x50  # PNG
	return (body[0] == 0x1f and body[1] == 0x8b) or body[0] == 0x1a  # gzip, or an MVT layer

func _done(t: Vector3i, ok: bool, code: int, body: PackedByteArray) -> void:
	_pending.erase(t)
	if ok and code == 404 and kind == Kind.VECTOR and _tilejson_state != 2:
		# The cached build may have been retired: ask the TileJSON again and
		# retry the tile under whatever path it names.
		_tiles_path = ""
		_tilejson_state = 0
		_pending[t] = true
		_queue.push_front(t)
		return
	if ok and (code == 204 or (code == 200 and body.is_empty())) and kind == Kind.VECTOR:
		tile_ready.emit(t.x, t.y, t.z, PackedByteArray())  # an empty tile: open sea
		return
	if not ok or code != 200 or not looks_like_tile(kind, body):
		tile_failed.emit(t.x, t.y, t.z)
		return
	var f := FileAccess.open(cache_path(t.x, t.y, t.z), FileAccess.WRITE)
	if f != null:
		f.store_buffer(body)
	tile_ready.emit(t.x, t.y, t.z, body)
