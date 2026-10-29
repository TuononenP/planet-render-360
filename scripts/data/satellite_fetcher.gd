class_name SatelliteFetcher
extends Node

## Real aerial imagery (Esri World Imagery) draped over the detailed
## terrain: the roofs, roads, rivers, and fields people actually
## recognise a place by. Free service, no key, direct from device;
## tiles cached in user://cache under versioned v2 keys
## (CacheStore.sat_path) so revisits work offline. Legacy sat_ files
## are ignored (contract V18). Imagery:
## Esri, Vantor, Earthstar Geographics — see docs/data-source-register.md.
## Optional layer: failure emits `failed` and the terrain keeps its
## vertex-colour dressing.
##
## T2.2: zoom + span are preset-driven (RenderSettings.satellite_zoom_for /
## satellite_span_for). T7.0: the span is latitude-aware so every mosaic
## covers the 2400 m detailed extent (Paris z16 s7, z17 s13), so only
## detail improves, never the layout. Fallback order per the register:
## requested mosaic → lower-zoom whole mosaic → per-tile cache (tried
## first for every tile) → failed signal (vertex-colour dressing).
## Whole-mosaic fallback, never mixed zooms in one mosaic: mixed pixel
## scales would break the single-origin UV math (same rule as DemFetcher).

signal succeeded(texture: Texture2D, image: Image, origin_px: Vector2, zoom: int)
signal failed(reason: String)

const URL_TEMPLATE := "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/%d/%d/%d"  # z/y/x
const USER_AGENT := "PlanetRender360/0.1"
const CACHE_DIR := "user://cache"
const TILE_PX := 256
const POOL_SIZE := 8  # parallel tile downloads; Ultra fetches 169 tiles
const TILE_TIMEOUT := 20.0
## Web-mercator metres per pixel at the equator for zoom 0.
const M_PX_Z0 := 156543.03392

## TRANSITIONAL (T2.2; T3.2 migrates the reader): mosaic span in tiles of
## the last successful fetch (3/7/13). Was a fixed const (contract V10);
## the frozen TerrainBuilder.satellite_uv still reads it (terrain_builder
## is not T2.2-owned), so it stays correct across the cutover. Updated on
## success only; single-flight callers (pipeline, offline download).
static var SPAN := 3

var _pool: Array[HTTPRequest] = []
var _images: Dictionary = {}  # Vector2i -> Image
var _tiles: Array[Vector2i] = []
var _remaining := 0
var _zoom := 16
var _span := 3
var _requested_zoom := 16
var _requested_span := 3
var _pending_lat := 0.0
var _pending_lon := 0.0
var _centre_tile := Vector2i.ZERO
var _emitted := false
## Contract §2.3 source record, set on every success: {zoom, span,
## tile_count, metres_per_px, source_zoom, source_span}. source_* differ
## from requested after a lower-zoom fallback. Cleared at fetch start.
var satellite_source: Dictionary = {}
## Test hook: serve the on-device cache only, never the network. A cache
## miss fails fast instead of downloading (offline-degradation tests).
var offline_mode := false

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	for i in POOL_SIZE:
		var http := HTTPRequest.new()
		http.timeout = TILE_TIMEOUT
		add_child(http)
		_pool.append(http)

## Web-mercator metres per pixel at a latitude/zoom (z16 ≈ 2.39 m/px at
## the equator, ≈ 1.57 at Paris; z17 halves that, z18 quarters it).
static func metres_per_px(lat: float, zoom: int) -> float:
	return M_PX_Z0 * cos(deg_to_rad(lat)) / float(1 << zoom)

## span x span tiles around the viewpoint tile. The 3-argument form keeps
## the v1 3x3 layout for existing callers (scenery_test); new callers
## pass the preset span explicitly.
static func mosaic_tiles(lat: float, lon: float, zoom: int,
		span: int = 3) -> Array[Vector2i]:
	var centre := DemFetcher.tile_xy(lat, lon, zoom)
	var out: Array[Vector2i] = []
	var max_tile := 1 << zoom
	var half := span / 2
	for dy in range(-half, half + 1):
		for dx in range(-half, half + 1):
			out.append(Vector2i(clampi(centre.x + dx, 0, max_tile - 1),
				clampi(centre.y + dy, 0, max_tile - 1)))
	return out

## Lower-zoom whole mosaic to try after (zoom, span) came back
## incomplete, as (zoom, span); (-1, -1) means the chain is exhausted.
## Same ground: half the tiles a side (rounded up to odd) one zoom down.
static func fallback_for(zoom: int, span: int) -> Vector2i:
	if zoom < 17:
		return Vector2i(-1, -1)
	var s := int(ceil(float(span) / 2.0))
	if s % 2 == 0:
		s += 1
	return Vector2i(zoom - 1, maxi(s, 3))

func fetch(lat: float, lon: float, zoom: int = 16, span: int = 3) -> void:
	_pending_lat = lat
	_pending_lon = lon
	_requested_zoom = zoom
	_requested_span = span
	satellite_source = {}
	_start_mosaic(zoom, span)

func _start_mosaic(zoom: int, span: int) -> void:
	_zoom = zoom
	_span = span
	_centre_tile = DemFetcher.tile_xy(_pending_lat, _pending_lon, zoom)
	_tiles = mosaic_tiles(_pending_lat, _pending_lon, zoom, span)
	_images.clear()
	_remaining = _tiles.size()
	_emitted = false
	for t in _tiles:
		_load_tile(t)

## Tiles in the current (or last) mosaic; the pipeline sizes its wait
## budget from this. 0 before the first fetch.
func pending_tile_count() -> int:
	return _tiles.size()

func _cache_path(t: Vector2i) -> String:
	return CacheStore.sat_path(_zoom, t.x, t.y)

func _load_tile(t: Vector2i, attempt: int = 0) -> void:
	var path := _cache_path(t)
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			CacheStore.note_read(path)
			_tile_done(t, img)
			return
	if offline_mode:
		_tile_done(t, null)
		return
	var http := _free_http()
	if http == null:
		# Pool busy: retry on the next process frame until a slot frees.
		get_tree().create_timer(0.25).timeout.connect(func() -> void: _load_tile(t, attempt))
		return
	var done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		http.set_meta("busy", false)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not body.is_empty():
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(body)
				CacheStore.note_written(path)
			var img := Image.new()
			if img.load_jpg_from_buffer(body) == OK:
				_tile_done(t, img)
				return
		if attempt < 1:
			# One retry: a single transient blip must not fail a
			# 169-tile Ultra mosaic (or force a full lower-zoom refetch).
			get_tree().create_timer(0.5).timeout.connect(func() -> void: _load_tile(t, attempt + 1))
		else:
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
	if _images.size() < _tiles.size():
		var next := fallback_for(_zoom, _span)
		if next.x > 0:
			print("Satellite z%d mosaic incomplete (%d/%d tiles), falling back to z%d" % [
				_zoom, _images.size(), _tiles.size(), next.x])
			_start_mosaic(next.x, next.y)
			return
		failed.emit("Satellite imagery unavailable")
		return
	var size := TILE_PX * _span
	var half := _span / 2
	var mosaic := Image.create(size, size, false, Image.FORMAT_RGB8)
	mosaic.fill(Color(0.32, 0.36, 0.28))
	for t in _tiles:
		if _images.has(t):
			var src: Image = _images[t]
			if src.get_format() != Image.FORMAT_RGB8:
				src.convert(Image.FORMAT_RGB8)
			var dst := Vector2i((t.x - (_centre_tile.x - half)) * TILE_PX,
				(t.y - (_centre_tile.y - half)) * TILE_PX)
			mosaic.blit_rect(src, Rect2i(0, 0, TILE_PX, TILE_PX), dst)
	mosaic.generate_mipmaps()
	SPAN = _span
	var origin := Vector2((_centre_tile.x - half) * TILE_PX, (_centre_tile.y - half) * TILE_PX)
	satellite_source = {
		"zoom": _requested_zoom,
		"span": _requested_span,
		"tile_count": _tiles.size(),
		"metres_per_px": metres_per_px(_pending_lat, _zoom),
		"source_zoom": _zoom,
		"source_span": _span,
	}
	succeeded.emit(ImageTexture.create_from_image(mosaic), mosaic, origin, _zoom)
