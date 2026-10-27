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

func request_tile(z: int, x: int, y: int) -> void:
	var max_tile := 1 << z
	if x < 0 or y < 0 or x >= max_tile or y >= max_tile:
		return
	var cache_path := "%s/%d_%d_%d.png" % [CACHE_DIR, z, x, y]
	if FileAccess.file_exists(cache_path):
		var img := Image.new()
		if img.load(cache_path) == OK:
			tile_ready.emit(z, x, y, ImageTexture.create_from_image(img))
			return
	_queue.append(Vector3i(z, x, y))
	_pump()

func _pump() -> void:
	for http in _pool:
		if not bool(_busy.get(http, false)) and not _queue.is_empty():
			var t: Vector3i = _queue.pop_front()
			_fetch(http, t)

func _fetch(http: HTTPRequest, t: Vector3i) -> void:
	_busy[http] = true
	var url := URL_TEMPLATE % [t.x, t.y, t.z]
	var done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		_busy[http] = false
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
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	http.request(url, ["User-Agent: %s" % USER_AGENT])
