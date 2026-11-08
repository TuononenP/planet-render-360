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
## Tiles settled so far (fetched, cached or given up on) of the current
## mosaic. Restarts from 0 when a lower-zoom fallback mosaic begins.
signal tile_progress(done: int, total: int)

const URL_TEMPLATE := "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/%d/%d/%d"  # z/y/x
const USER_AGENT := Brand.USER_AGENT
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
## Bumped per mosaic. Requests still in flight from an earlier mosaic
## (a lower-zoom fallback, or a new fetch while the last one runs) keep
## their tile in the cache but must not settle tiles of this one: they
## would count it complete early and report it incomplete.
var _generation := 0
## Cached tiles decode on the worker pool (a 225-tile Ultra mosaic took
## ~0.5 s on the main thread, several times that on a phone). One group per
## mosaic; its images are handed to _tile_done on the main thread.
var _stitch_task := -1
var _decode_group := -1
var _decode_gen := 0
var _decode_tiles: Array[Vector2i] = []
var _decode_images: Array[Image] = []
## Contract §2.3 source record, set on every success: {zoom, span,
## tile_count, metres_per_px, source_zoom, source_span}. source_* differ
## from requested after a lower-zoom fallback. Cleared at fetch start.
var satellite_source: Dictionary = {}
## Test hook: serve the on-device cache only, never the network. A cache
## miss fails fast instead of downloading (offline-degradation tests).
var offline_mode := false

func _ready() -> void:
	# Polling is only needed while a decode runs; a fetch started before the
	# node was ready already has one.
	set_process(_decode_group >= 0)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	for i in POOL_SIZE:
		var http := HTTPRequest.new()
		http.timeout = TILE_TIMEOUT
		add_child(http)
		_pool.append(http)

## The tile address in use: URL_TEMPLATE unless RemoteConfig replaces it.
static func url_template() -> String:
	return RemoteConfig.value("satellite_url_template", URL_TEMPLATE)

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_decode()
		_join_stitch()

func _start_mosaic(zoom: int, span: int) -> void:
	_join_decode()
	_join_stitch()
	_zoom = zoom
	_span = span
	_centre_tile = DemFetcher.tile_xy(_pending_lat, _pending_lon, zoom)
	_tiles = mosaic_tiles(_pending_lat, _pending_lon, zoom, span)
	_images.clear()
	_remaining = _tiles.size()
	_emitted = false
	_generation += 1
	var gen := _generation
	var cached: Array[Vector2i] = []
	for t in _tiles:
		if FileAccess.file_exists(_cache_path(t)):
			cached.append(t)
		else:
			_load_tile(t, gen)
	# A mosaic that settled inside the loop (offline, every tile missing)
	# may already have started its lower-zoom fallback.
	if gen == _generation:
		_decode_cached(cached, gen)

## Decodes the cached tiles in parallel; _process collects them.
func _decode_cached(cached: Array[Vector2i], gen: int) -> void:
	if cached.is_empty():
		return
	var images: Array[Image] = []
	var paths := PackedStringArray()
	for t in cached:
		images.append(Image.new())
		paths.append(_cache_path(t))
	_decode_tiles = cached
	_decode_images = images
	_decode_gen = gen
	_decode_group = WorkerThreadPool.add_group_task(
		func(i: int) -> void: images[i].load(paths[i]), cached.size(), -1, false, "Decode satellite tiles")
	set_process(true)

func _process(_delta: float) -> void:
	if _decode_group < 0:
		set_process(false)
	elif WorkerThreadPool.is_group_task_completed(_decode_group):
		_finish_decode()

func _finish_decode() -> void:
	var tiles := _decode_tiles
	var images := _decode_images
	var gen := _decode_gen
	_join_decode()
	for i in tiles.size():
		if gen != _generation:
			return  # superseded while decoding; the files stay cached
		if images[i].is_empty():
			_load_tile(tiles[i], gen)  # damaged file: the network path
		else:
			CacheStore.note_read(_cache_path(tiles[i]))
			_tile_done(tiles[i], images[i])

func _join_stitch() -> void:
	if _stitch_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_stitch_task)
		_stitch_task = -1

## Waits for a decode in flight and forgets it. Cheap when none is running.
func _join_decode() -> void:
	if _decode_group >= 0:
		WorkerThreadPool.wait_for_group_task_completion(_decode_group)
		_decode_group = -1
	_decode_tiles = []
	_decode_images = []
	set_process(false)

## Tiles in the current (or last) mosaic; the pipeline sizes its wait
## budget from this. 0 before the first fetch.
func pending_tile_count() -> int:
	return _tiles.size()

func _cache_path(t: Vector2i) -> String:
	return CacheStore.sat_path(_zoom, t.x, t.y)

func _load_tile(t: Vector2i, gen: int, attempt: int = 0) -> void:
	if gen != _generation:
		return
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
		get_tree().create_timer(0.25).timeout.connect(func() -> void: _load_tile(t, gen, attempt))
		return
	var done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		http.set_meta("busy", false)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not body.is_empty():
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(body)
				CacheStore.note_written(path)
			if gen != _generation:
				return
			var img := Image.new()
			if img.load_jpg_from_buffer(body) == OK:
				_tile_done(t, img)
				return
		if attempt < 1:
			# One retry: a single transient blip must not fail a
			# 169-tile Ultra mosaic (or force a full lower-zoom refetch).
			get_tree().create_timer(0.5).timeout.connect(func() -> void: _load_tile(t, gen, attempt + 1))
		elif gen == _generation:
			_tile_done(t, null)
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	var url := url_template() % [_zoom, t.y, t.x]
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
	tile_progress.emit(_tiles.size() - maxi(_remaining, 0), _tiles.size())
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
	# Blitting 225 tiles and building the mipmaps of a 3840 px mosaic took
	# ~60 ms on the main thread; the worker does it and only the texture
	# upload is left here. The images are this mosaic's own: a newer one
	# joins this task before it clears them.
	var gen := _generation
	var tiles := _tiles.duplicate()
	var images := _images.duplicate()
	var size := TILE_PX * _span
	var top_left := _centre_tile - Vector2i.ONE * (_span / 2)
	_stitch_task = WorkerThreadPool.add_task(func() -> void:
		var mosaic := Image.create(size, size, false, Image.FORMAT_RGB8)
		mosaic.fill(Color(0.32, 0.36, 0.28))
		for t: Vector2i in tiles:
			if images.has(t):
				var src: Image = images[t]
				if src.get_format() != Image.FORMAT_RGB8:
					src.convert(Image.FORMAT_RGB8)
				mosaic.blit_rect(src, Rect2i(0, 0, TILE_PX, TILE_PX), (t - top_left) * TILE_PX)
		mosaic.generate_mipmaps()
		_stitched.call_deferred(gen, mosaic))

func _stitched(gen: int, mosaic: Image) -> void:
	_join_stitch()
	if gen != _generation:
		return  # a newer mosaic replaced this one while it was built
	var half := _span / 2
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
