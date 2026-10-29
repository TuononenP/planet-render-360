class_name DemFetcher
extends Node

## Real elevation from AWS Terrain Tiles (Terrarium PNG), fetched directly
## by the device. No key, no account, no proxy — see docs/data-source-register.md.
## Tiles are cached in user://cache under versioned v2 keys
## (CacheStore.dem_path — the single source for the key format) so
## revisits work offline. Legacy dem_ files are ignored (contract V18).
## Terrarium encoding: height = R*256 + G + B/256 - 32768 (metres).
##
## T2.1 near field: a 3x3 mosaic at zoom 14 (stitched like SatelliteFetcher
## with a bounded pool + per-tile cache), sampled bilinearly over the same
## ground window v1 used (144 z12 px == 576 z14 px), so the layout is
## unchanged and only detail improves. Zoom 12 stays as the mid fallback
## (whole-grid, never mixed zooms in one grid) and zoom 8 stays the far ring.
## Fallback order per the register: z14 mosaic → z12 mid tile → per-tile
## cache (tried first for every tile) → failed signal (the pipeline builds
## its deterministic procedural DEM). The detailed-extent remap to
## DETAILED_EXTENT_M is T3.1's, not this task's: the window is unchanged.

signal succeeded(heights_metres: PackedFloat32Array, grid: int)
signal failed(reason: String)

const URL_TEMPLATE := "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/%d/%d/%d.png"
const ZOOM_NEAR := 14
const ZOOM_MID := 12
## v1 name for the mid zoom; kept for out-of-tree callers (contract V11).
const ZOOM := ZOOM_MID
const FAR_ZOOM := 8  # one tile spans ~100 km: the far-terrain backdrop
const CACHE_DIR := "user://cache"
const TILE_PX := 256
const SPAN_NEAR := 3  # 3x3 z14 tiles around the viewpoint tile
const POOL_SIZE := 4  # parallel tile downloads, like SatelliteFetcher
const TILE_TIMEOUT := 12.0
## v1 sampled a 144 px window of its z12 tile; the same ground is 576 px
## at z14 (this fits the 768 px mosaic; the viewpoint can sit up to half
## a tile off the mosaic centre, so edge posts clamp like v1 did). The
## preset's grid resamples this fixed window, so a finer grid is more
## accurate, not wider — tiers never move the layout (plan invariant 5).
const WINDOW_NEAR_PX := 576.0
## Web-mercator metres per pixel at the equator for zoom 0.
const M_PX_Z0 := 156543.03392

var _http: HTTPRequest
var _pool: Array[HTTPRequest] = []
var _pending_grid := 48
var _pending_lat := 0.0
var _pending_lon := 0.0
var _zoom := ZOOM_MID
## Viewpoint position (0..1) inside the far tile, set by fetch_far so
## the far mesh can be centred on the viewpoint, not the tile centre.
var far_centre_frac := Vector2(0.5, 0.5)
## Contract §2.2 dem_source, set on every near/mid success: {zoom_near,
## zoom_mid, zoom_far, span_near, metres_per_px, tile_count, source_zoom}.
## source_zoom is the zoom actually sampled (14, or 12 after fallback);
## tile_count is the tiles stitched (9 or 1). Cleared at fetch start.
var dem_source: Dictionary = {}
## Test hook: serve the on-device cache only, never the network. A cache
## miss fails fast instead of downloading (offline-degradation tests).
var offline_mode := false
var _mosaic_images: Dictionary = {}  # Vector2i -> Image
var _mosaic_tiles: Array[Vector2i] = []
var _mosaic_remaining := 0
var _mosaic_centre := Vector2i.ZERO
var _mosaic_emitted := false
var _mid_fallback_done := false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	for i in POOL_SIZE:
		var http := HTTPRequest.new()
		http.timeout = TILE_TIMEOUT
		add_child(http)
		_pool.append(http)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

static func tile_xy(lat: float, lon: float, zoom: int) -> Vector2i:
	var n := float(1 << zoom)
	var x := int((lon + 180.0) / 360.0 * n)
	var lat_rad := deg_to_rad(lat)
	var y := int((1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n)
	return Vector2i(clampi(x, 0, int(n) - 1), clampi(y, 0, int(n) - 1))

## 3x3 tiles around the viewpoint tile at the given zoom (same layout as
## SatelliteFetcher.mosaic_tiles, kept local so DEM never depends on it).
static func mosaic_tiles(lat: float, lon: float, zoom: int) -> Array[Vector2i]:
	var centre := tile_xy(lat, lon, zoom)
	var out: Array[Vector2i] = []
	var max_tile := 1 << zoom
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			out.append(Vector2i(clampi(centre.x + dx, 0, max_tile - 1),
				clampi(centre.y + dy, 0, max_tile - 1)))
	return out

## Web-mercator metres per pixel at a latitude/zoom (z14 ≈ 9.6 m/px at
## the equator, ≈ 6.3 m/px at Paris — the register's corrected values).
static func metres_per_px(lat: float, zoom: int) -> float:
	return M_PX_Z0 * cos(deg_to_rad(lat)) / float(1 << zoom)

## Terrarium decode of one pixel, in metres ASL.
static func terrarium_height(c: Color) -> float:
	return (c.r8 * 256.0 + c.g8 + c.b8 / 256.0) - 32768.0

## Fractional position (0..1) of a coordinate inside its tile.
static func tile_frac(lat: float, lon: float, zoom: int) -> Vector2:
	var n := float(1 << zoom)
	var gx := (lon + 180.0) / 360.0 * n
	var lat_rad := deg_to_rad(lat)
	var gy := (1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n
	return Vector2(gx - floor(gx), gy - floor(gy))

## Bilinear Terrarium sample at float pixel coordinates; outside clamps
## to the edge (v1 clamped the same way at tile borders).
static func sample_bilinear(img: Image, fx: float, fy: float) -> float:
	var w := img.get_width()
	var h := img.get_height()
	var cx := clampf(fx, 0.0, float(w - 1))
	var cy := clampf(fy, 0.0, float(h - 1))
	var x0 := int(cx)
	var y0 := int(cy)
	var x1 := mini(x0 + 1, w - 1)
	var y1 := mini(y0 + 1, h - 1)
	var tx := cx - float(x0)
	var ty := cy - float(y0)
	var h00 := terrarium_height(img.get_pixel(x0, y0))
	var h10 := terrarium_height(img.get_pixel(x1, y0))
	var h01 := terrarium_height(img.get_pixel(x0, y1))
	var h11 := terrarium_height(img.get_pixel(x1, y1))
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), ty)

## Near field: 3x3 z14 mosaic, bilinearly sampled. Falls back to the z12
## mid tile when any mosaic tile is missing, else emits failed.
func fetch(lat: float, lon: float, grid: int) -> void:
	_pending_lat = lat
	_pending_lon = lon
	_pending_grid = grid
	_zoom = ZOOM_NEAR
	_mid_fallback_done = false
	dem_source = {}
	_mosaic_centre = tile_xy(lat, lon, ZOOM_NEAR)
	_mosaic_tiles = mosaic_tiles(lat, lon, ZOOM_NEAR)
	_mosaic_images.clear()
	_mosaic_remaining = _mosaic_tiles.size()
	_mosaic_emitted = false
	for t in _mosaic_tiles:
		_load_mosaic_tile(t)

## Mid field / fallback: the v1 single-tile z12 window (nearest sampling).
## Public so tests can run the T1.3-vs-T2.1 A/B on the same grid.
func fetch_mid(lat: float, lon: float, grid: int) -> void:
	_pending_lat = lat
	_pending_lon = lon
	_pending_grid = grid
	_zoom = ZOOM_MID
	dem_source = {}
	_fetch_at_zoom(lat, lon, grid)

## Low-resolution backdrop: the whole zoom-8 tile sampled on a coarse
## grid. Same signals and Terrarium decode as the detailed fetch.
func fetch_far(lat: float, lon: float, grid: int) -> void:
	_zoom = FAR_ZOOM
	_fetch_at_zoom(lat, lon, grid)

func _fetch_mid_internal() -> void:
	if _mid_fallback_done:
		failed.emit("DEM z14 mosaic incomplete and z12 fallback already tried")
		return
	_mid_fallback_done = true
	fetch_mid(_pending_lat, _pending_lon, _pending_grid)

func _mosaic_cache_path(t: Vector2i) -> String:
	return CacheStore.dem_path(ZOOM_NEAR, t.x, t.y)

func _load_mosaic_tile(t: Vector2i) -> void:
	var path := _mosaic_cache_path(t)
	if FileAccess.file_exists(path):
		var cached := Image.new()
		if cached.load(path) == OK:
			CacheStore.note_read(path)
			_mosaic_tile_done(t, cached)
			return
	if offline_mode:
		_mosaic_tile_done(t, null)
		return
	var http := _free_http()
	if http == null:
		# Pool busy: retry on a short timer until a slot frees.
		get_tree().create_timer(0.25).timeout.connect(func() -> void: _load_mosaic_tile(t))
		return
	var done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		http.set_meta("busy", false)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not body.is_empty():
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(body)
				CacheStore.note_written(path)
			var img := Image.new()
			if img.load_png_from_buffer(body) == OK:
				_mosaic_tile_done(t, img)
				return
		_mosaic_tile_done(t, null)
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	var url := URL_TEMPLATE % [ZOOM_NEAR, t.x, t.y]
	var err := http.request(url, ["User-Agent: PlanetRender360/0.1"])
	if err != OK:
		http.request_completed.disconnect(done)
		http.set_meta("busy", false)
		_mosaic_tile_done(t, null)

func _free_http() -> HTTPRequest:
	for http in _pool:
		if not http.get_meta("busy", false):
			http.set_meta("busy", true)
			return http
	return null

func _mosaic_tile_done(t: Vector2i, img: Image) -> void:
	if img != null:
		_mosaic_images[t] = img
	_mosaic_remaining -= 1
	if _mosaic_remaining <= 0 and not _mosaic_emitted:
		_mosaic_emitted = true
		_stitch_mosaic()

func _stitch_mosaic() -> void:
	if _mosaic_images.size() < _mosaic_tiles.size():
		print("DEM z14 mosaic incomplete (%d/%d tiles), falling back to z12 mid tile" % [
			_mosaic_images.size(), _mosaic_tiles.size()])
		_fetch_mid_internal()
		return
	var size := TILE_PX * SPAN_NEAR
	var mosaic := Image.create(size, size, false, Image.FORMAT_RGB8)
	for t in _mosaic_tiles:
		var src: Image = _mosaic_images[t]
		if src.get_format() != Image.FORMAT_RGB8:
			src.convert(Image.FORMAT_RGB8)
		var dst := Vector2i((t.x - (_mosaic_centre.x - 1)) * TILE_PX,
			(t.y - (_mosaic_centre.y - 1)) * TILE_PX)
		mosaic.blit_rect(src, Rect2i(0, 0, TILE_PX, TILE_PX), dst)
	# Viewpoint pixel inside the mosaic: the centre tile starts at (256, 256).
	var frac := tile_frac(_pending_lat, _pending_lon, ZOOM_NEAR)
	var centre := Vector2((1.0 + frac.x) * TILE_PX, (1.0 + frac.y) * TILE_PX)
	var grid := _pending_grid
	var step_px := WINDOW_NEAR_PX / float(maxi(grid, 1))
	var heights := PackedFloat32Array()
	heights.resize(grid * grid)
	for z in grid:
		for x in grid:
			var fx := centre.x + (float(x) - float(grid) / 2.0) * step_px
			var fy := centre.y + (float(z) - float(grid) / 2.0) * step_px
			heights[z * grid + x] = sample_bilinear(mosaic, fx, fy)
	dem_source = {
		"zoom_near": ZOOM_NEAR,
		"zoom_mid": ZOOM_MID,
		"zoom_far": FAR_ZOOM,
		"span_near": SPAN_NEAR,
		"metres_per_px": metres_per_px(_pending_lat, ZOOM_NEAR),
		"tile_count": _mosaic_tiles.size(),
		"source_zoom": ZOOM_NEAR,
	}
	succeeded.emit(heights, grid)

func _fetch_at_zoom(lat: float, lon: float, grid: int) -> void:
	_pending_lat = lat
	_pending_lon = lon
	_pending_grid = grid
	var tile := tile_xy(lat, lon, _zoom)
	var cache_path := CacheStore.dem_path(_zoom, tile.x, tile.y)
	if FileAccess.file_exists(cache_path):
		var img := Image.new()
		if img.load(cache_path) == OK:
			CacheStore.note_read(cache_path)
			_emit_from_image(img)
			return
	if offline_mode:
		failed.emit("DEM tile z%d/%d/%d not cached (offline mode)" % [_zoom, tile.x, tile.y])
		return
	var url := URL_TEMPLATE % [_zoom, tile.x, tile.y]
	var err := _http.request(url, ["User-Agent: PlanetRender360/0.1"])
	if err != OK:
		failed.emit("HTTP request failed to start: %s" % err)

func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("DEM download failed (result=%d code=%d)" % [result, code])
		return
	var tile := tile_xy(_pending_lat, _pending_lon, _zoom)
	var cache_path := CacheStore.dem_path(_zoom, tile.x, tile.y)
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(body)
		CacheStore.note_written(cache_path)
	var img := Image.new()
	if img.load_png_from_buffer(body) != OK:
		failed.emit("DEM tile is not a readable PNG")
		return
	_emit_from_image(img)

func _emit_from_image(img: Image) -> void:
	if img.get_format() != Image.FORMAT_RGB8 and img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var grid := _pending_grid
	var size := img.get_width()
	# Pixel location of the coordinate inside its tile.
	var frac := tile_frac(_pending_lat, _pending_lon, _zoom)
	var heights := PackedFloat32Array()
	heights.resize(grid * grid)
	if _zoom == FAR_ZOOM:
		# Whole tile, evenly: the mesh is positioned via far_centre_frac.
		far_centre_frac = Vector2(frac.x, frac.y)
		for z in grid:
			for x in grid:
				var px := clampi(int(float(x) / float(grid - 1) * float(size - 1)), 0, size - 1)
				var py := clampi(int(float(z) / float(grid - 1) * float(size - 1)), 0, size - 1)
				heights[z * grid + x] = terrarium_height(img.get_pixel(px, py))
	else:
		var centre := Vector2(frac.x * size, frac.y * size)
		# Fixed 144 px window (~110 m/sample at the old 48 grid): the
		# quality preset's grid resamples the same ground extent, so a
		# finer grid is genuinely more accurate, not just wider.
		var step_px := 144.0 / float(maxi(grid, 1))
		for z in grid:
			for x in grid:
				var px := clampi(int(centre.x + (x - grid / 2.0) * step_px), 0, size - 1)
				var py := clampi(int(centre.y + (z - grid / 2.0) * step_px), 0, size - 1)
				heights[z * grid + x] = terrarium_height(img.get_pixel(px, py))
		if _zoom == ZOOM_MID:
			dem_source = {
				"zoom_near": ZOOM_NEAR,
				"zoom_mid": ZOOM_MID,
				"zoom_far": FAR_ZOOM,
				"span_near": SPAN_NEAR,
				"metres_per_px": metres_per_px(_pending_lat, ZOOM_MID),
				"tile_count": 1,
				"source_zoom": ZOOM_MID,
			}
	succeeded.emit(heights, grid)
