class_name SatelliteFetcher
extends Node

## Real aerial imagery (Esri World Imagery) draped over the detailed
## terrain: the roofs, roads, rivers, and fields people actually
## recognise a place by. Free service, no key, direct from device;
## tiles cached in user://cache so revisits work offline. Imagery:
## Esri, Maxar, Earthstar Geographics — see docs/data-source-register.md.
## Optional layer: failure emits `failed` and the terrain keeps its
## vertex-colour dressing.

signal succeeded(texture: Texture2D, image: Image, origin_px: Vector2, zoom: int)
signal failed(reason: String)

const URL_TEMPLATE := "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/%d/%d/%d"  # z/y/x
const USER_AGENT := "PlanetRender360/0.1"
const CACHE_DIR := "user://cache"
const TILE_PX := 256
const SPAN := 3  # 3x3 tiles: ~1.2 km at zoom 16, terrain spans 880 m
const POOL_SIZE := 4

var _pool: Array[HTTPRequest] = []
var _images: Dictionary = {}  # Vector2i -> Image
var _tiles: Array[Vector2i] = []
var _remaining := 0
var _zoom := 16
var _centre_tile := Vector2i.ZERO
var _emitted := false

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	for i in POOL_SIZE:
		var http := HTTPRequest.new()
		http.timeout = 20.0
		add_child(http)
		_pool.append(http)

static func mosaic_tiles(lat: float, lon: float, zoom: int) -> Array[Vector2i]:
	var centre := DemFetcher.tile_xy(lat, lon, zoom)
	var out: Array[Vector2i] = []
	var max_tile := 1 << zoom
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			out.append(Vector2i(clampi(centre.x + dx, 0, max_tile - 1),
				clampi(centre.y + dy, 0, max_tile - 1)))
	return out

func fetch(lat: float, lon: float, zoom: int = 16) -> void:
	_zoom = zoom
	_centre_tile = DemFetcher.tile_xy(lat, lon, zoom)
	_tiles = mosaic_tiles(lat, lon, zoom)
	_images.clear()
	_remaining = _tiles.size()
	_emitted = false
	for t in _tiles:
		_load_tile(t)

func _cache_path(t: Vector2i) -> String:
	return "%s/sat_%d_%d_%d.jpg" % [CACHE_DIR, _zoom, t.x, t.y]

func _load_tile(t: Vector2i) -> void:
	var path := _cache_path(t)
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			_tile_done(t, img)
			return
	var http := _free_http()
	if http == null:
		# Pool busy: retry on the next process frame until a slot frees.
		get_tree().create_timer(0.25).timeout.connect(func() -> void: _load_tile(t))
		return
	var done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		http.set_meta("busy", false)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not body.is_empty():
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(body)
			var img := Image.new()
			if img.load_jpg_from_buffer(body) == OK:
				_tile_done(t, img)
				return
		_tile_done(t, null)
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	var url := URL_TEMPLATE % [_zoom, t.y, t.x]
	var err := http.request(url, ["User-Agent: %s" % USER_AGENT])
	if err != OK:
		http.request_completed.disconnect(done)
		http.set_meta("busy", false)
		_tile_done(t, null)

func _free_http() -> HTTPRequest:
	for http in _pool:
		if not http.get_meta("busy", false):
			http.set_meta("busy", true)
			return http
	return null

func _tile_done(t: Vector2i, img: Image) -> void:
	if img != null:
		_images[t] = img
	_remaining -= 1
	if _remaining <= 0 and not _emitted:
		_emitted = true
		_stitch()

func _stitch() -> void:
	if _images.is_empty():
		failed.emit("Satellite imagery unavailable")
		return
	var size := TILE_PX * SPAN
	var mosaic := Image.create(size, size, false, Image.FORMAT_RGB8)
	mosaic.fill(Color(0.32, 0.36, 0.28))
	for t in _tiles:
		if _images.has(t):
			var src: Image = _images[t]
			if src.get_format() != Image.FORMAT_RGB8:
				src.convert(Image.FORMAT_RGB8)
			var dst := Vector2i((t.x - (_centre_tile.x - 1)) * TILE_PX,
				(t.y - (_centre_tile.y - 1)) * TILE_PX)
			mosaic.blit_rect(src, Rect2i(0, 0, TILE_PX, TILE_PX), dst)
	mosaic.generate_mipmaps()
	var origin := Vector2((_centre_tile.x - 1) * TILE_PX, (_centre_tile.y - 1) * TILE_PX)
	succeeded.emit(ImageTexture.create_from_image(mosaic), mosaic, origin, _zoom)
