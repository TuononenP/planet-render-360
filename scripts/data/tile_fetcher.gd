class_name TileFetcher
extends Node

## OSM raster tiles for the picker map, per the OSMF Tile Usage Policy:
## HTTPS tile.openstreetmap.org, identifying User-Agent, visible
## attribution (in MapTileView), on-device caching, no bulk prefetch —
## only the tiles visible in the picker are ever requested.

signal tile_ready(z: int, x: int, y: int, texture: Texture2D)
signal tile_failed(z: int, x: int, y: int)

const URL_TEMPLATE := "https://tile.openstreetmap.org/%d/%d/%d.png"
const CACHE_DIR := "user://cache/tiles"
const USER_AGENT := "PlanetRender360/0.1"

var _pool: Array[HTTPRequest] = []
var _queue: Array[Vector3i] = []
var _busy: Dictionary = {}
var _pending: Dictionary = {}  # Vector3i -> bool, queued or in flight
var _inflight: Dictionary = {}  # HTTPRequest -> Vector3i being downloaded
var _callbacks: Dictionary = {}  # HTTPRequest -> its request_completed callable

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	for i in 6:
		var http := HTTPRequest.new()
		http.timeout = 20.0
		add_child(http)
		_pool.append(http)

static func global_pixel(lat: float, lon: float, zoom: int) -> Vector2:
	var n := float(1 << zoom) * 256.0
	var px := (lon + 180.0) / 360.0 * n
	var lat_rad := deg_to_rad(clampf(lat, -85.0, 85.0))
	var py := (1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n
	return Vector2(px, py)

static func lat_lon_from_pixel(px: Vector2, zoom: int) -> Vector2:
	var n := float(1 << zoom) * 256.0
	var lon := px.x / n * 360.0 - 180.0
	var merc := PI * (1.0 - 2.0 * px.y / n)
	var lat := rad_to_deg(atan(sinh(merc)))
	return Vector2(lat, lon)

## Coarser tile `drop` zoom levels above (z, x, y): the one tile that
## covers it at the lower zoom. Used for the instant low-detail preview.
static func parent_tile(z: int, x: int, y: int, drop: int) -> Vector3i:
	var d := clampi(drop, 0, z)
	return Vector3i(z - d, x >> d, y >> d)

## Sub-rect (in pixels of a 256px tile image) of `tile` inside its
## ancestor `ancestor` (both Vector3i z/x/y). Drawing that crop scaled
## up fills the tile's area with blurry but correct geography.
static func source_rect_for_ancestor(tile: Vector3i, ancestor: Vector3i) -> Rect2:
	var drop := tile.x - ancestor.x
	if drop <= 0:
		return Rect2(0, 0, 256, 256)
	var scale := 1 << drop
	var side := 256.0 / float(scale)
	var offset := Vector2(
		float(tile.y - (ancestor.y << drop)) * side,
		float(tile.z - (ancestor.z << drop)) * side)
	return Rect2(offset, Vector2(side, side))

func request_tile(z: int, x: int, y: int) -> void:
	var max_tile := 1 << z
	if x < 0 or y < 0 or x >= max_tile or y >= max_tile:
		return
	var key := Vector3i(z, x, y)
	if _pending.has(key):
		return  # already queued or downloading; duplicates bury new tiles
	var cache_path := "%s/%d_%d_%d.png" % [CACHE_DIR, z, x, y]
	if FileAccess.file_exists(cache_path):
		var img := Image.new()
		if img.load(cache_path) == OK:
			tile_ready.emit(z, x, y, ImageTexture.create_from_image(img))
			return
	_pending[key] = true
	_queue.append(key)
	_pump()

## Drop work outside `keep` (Vector3i z/x/y) and serve the survivors
## in `keep` order (the caller lists preview, then detail centre-out).
## Queued stale tiles are removed; in-flight stale downloads are
## cancelled outright — after a far pan they otherwise occupied every
## pool slot until they finished or timed out, which is what made a
## new area load so slowly.
func discard_queued_except(keep: Array) -> void:
	var keep_set: Dictionary = {}
	for k in keep:
		keep_set[k] = true
	for http in _inflight.keys():
		var tile: Vector3i = _inflight[http]
		if not keep_set.has(tile):
			var done: Callable = _callbacks.get(http, Callable())
			if done.is_valid() and http.request_completed.is_connected(done):
				http.request_completed.disconnect(done)
			_inflight.erase(http)
			_callbacks.erase(http)
			_busy[http] = false
			_pending.erase(tile)
			http.cancel_request()
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
	for http in _pool:
		if not bool(_busy.get(http, false)) and not _queue.is_empty():
			var t: Vector3i = _queue.pop_front()
			_fetch(http, t)

func _fetch(http: HTTPRequest, t: Vector3i) -> void:
	_busy[http] = true
	_inflight[http] = t
	var url := URL_TEMPLATE % [t.x, t.y, t.z]
	var done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		_busy[http] = false
		_inflight.erase(http)
		_callbacks.erase(http)
		_pending.erase(t)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var cache_path := "%s/%d_%d_%d.png" % [CACHE_DIR, t.x, t.y, t.z]
			var f := FileAccess.open(cache_path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(body)
			var img := Image.new()
			if img.load_png_from_buffer(body) == OK:
				tile_ready.emit(t.x, t.y, t.z, ImageTexture.create_from_image(img))
				_pump()
				return
		tile_failed.emit(t.x, t.y, t.z)
		_pump()
	_callbacks[http] = done
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	var err := http.request(url, ["User-Agent: %s" % USER_AGENT])
	if err != OK:
		# request_completed never fires on a refused request: free the
		# pool slot now or six such failures would kill the fetcher.
		http.request_completed.disconnect(done)
		_busy[http] = false
		_inflight.erase(http)
		_callbacks.erase(http)
		_pending.erase(t)
		tile_failed.emit(t.x, t.y, t.z)
		_pump()
