class_name FarFieldFetcher
extends Node

## Far-field data for the DEM rings past the detailed extent (T3.7,
## contract docs/world-model-contract.md §2.2 dem_rings / §2.3
## far_drapes): Terrarium DEM windows and Esri World Imagery windows
## sized by REACH in metres around the viewpoint, not by a fixed tile
## span, so coverage is guaranteed at every latitude.
## - DEM rings: ~12.5 m/px (z13 at mid latitudes) to 4 km, ~25 m/px
##   (z12) to 9.5 km, ~100 m/px (z10) to 33 km. Decoded into
##   Mercator-pixel height windows (valley walls 1-4 km need z13: at
##   z12 the river imagery smeared up the Harder cliff at Interlaken).
## - Drapes: ~12 m/px (z13) to 9.5 km, ~50 m/px (z11) to 33 km,
##   ~200 m/px (z9) to 60 km, stitched into mipmapped textures.
## Zoom per layer = the finest zoom whose pixel is no smaller than the
## target metres-per-pixel at the viewpoint latitude, which keeps tile
## counts bounded (~3-7 per axis) from the equator to the Arctic.
## Same sources, cache keys (CacheStore.dem_path / sat_path, shared
## with DemFetcher / SatelliteFetcher tiles) and register rows as the
## near fetchers. Per layer, all-or-nothing: an incomplete window drops
## that layer (never mixed zooms), and builders fall back to the next
## coarser ring, then the z8 far grid / colour ramp.

signal finished(dem_rings: Array, drapes: Array)

const DEM_LAYERS: Array = [
	{"target_mpp": 12.5, "reach_m": 4000.0},
	{"target_mpp": 25.0, "reach_m": 9500.0},
	{"target_mpp": 100.0, "reach_m": 33000.0},
]
const DRAPE_LAYERS: Array = [
	{"target_mpp": 12.0, "reach_m": 9500.0},
	{"target_mpp": 50.0, "reach_m": 33000.0},
	{"target_mpp": 200.0, "reach_m": 60000.0},
]
const TILE_PX := 256
const POOL_SIZE := 12
const TILE_TIMEOUT := 15.0
const USER_AGENT := "PlanetRender360/0.1"
## Extra pixels around each window so bilinear + edge fades never
## read outside it at the exact reach.
const MARGIN_PX := 4

## Test hook: serve the on-device cache only (cache miss = layer absent).
var offline_mode := false
## {fetch_ms, assemble_ms, tiles, cached, failed} of the last fetch.
var timings: Dictionary = {}

var _pool: Array[HTTPRequest] = []
var _queue: Array = []  # [{layer, kind, zoom, tile}]
var _layers: Array = []  # [{kind, zoom, rect, tiles, images, reach_m}]
var _remaining := 0
var _busy := false
var _with_drapes := true
var _t0 := 0
var _cached := 0
var _failed := 0

func _ready() -> void:
	for i in POOL_SIZE:
		var http := HTTPRequest.new()
		http.timeout = TILE_TIMEOUT
		add_child(http)
		_pool.append(http)

func is_busy() -> bool:
	return _busy

## Finest zoom whose pixel is >= target_mpp at this latitude.
static func zoom_for(lat: float, target_mpp: float, max_zoom: int) -> int:
	var eq := DemFetcher.M_PX_Z0 * cos(deg_to_rad(lat))
	var z := int(floor(log(eq / maxf(target_mpp, 0.01)) / log(2.0)))
	return clampi(z, 1, max_zoom)

## Global-pixel window (at zoom) covering +-reach_m around (lat, lon),
## computed from the true corner coordinates (exact Mercator).
static func window_px(lat: float, lon: float, zoom: int, reach_m: float) -> Rect2i:
	var nw := WorldScale.latlon_from_xz(-reach_m, -reach_m, lat, lon)
	var se := WorldScale.latlon_from_xz(reach_m, reach_m, lat, lon)
	var a := TileFetcher.global_pixel(nw.x, nw.y, zoom)
	var b := TileFetcher.global_pixel(se.x, se.y, zoom)
	var limit := (1 << zoom) * TILE_PX
	var x0 := clampi(int(floor(a.x)) - MARGIN_PX, 0, limit - 1)
	var y0 := clampi(int(floor(a.y)) - MARGIN_PX, 0, limit - 1)
	var x1 := clampi(int(ceil(b.x)) + MARGIN_PX, 0, limit - 1)
	var y1 := clampi(int(ceil(b.y)) + MARGIN_PX, 0, limit - 1)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

static func window_tiles(rect: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for ty in range(rect.position.y / TILE_PX, (rect.end.y - 1) / TILE_PX + 1):
		for tx in range(rect.position.x / TILE_PX, (rect.end.x - 1) / TILE_PX + 1):
			out.append(Vector2i(tx, ty))
	return out

## Every cache key this fetch touches for a place (offline warm-up and
## cache-status callers): {"dem": [...], "sat": [...]}.
static func cache_keys(lat: float, lon: float, with_drapes: bool = true) -> Dictionary:
	var dem: Array[String] = []
	var sat: Array[String] = []
	for spec in DEM_LAYERS:
		var z := zoom_for(lat, spec["target_mpp"], 15)
		for t in window_tiles(window_px(lat, lon, z, spec["reach_m"])):
			dem.append(CacheStore.dem_path(z, t.x, t.y))
	if with_drapes:
		for spec in DRAPE_LAYERS:
			var z := zoom_for(lat, spec["target_mpp"], 18)
			for t in window_tiles(window_px(lat, lon, z, spec["reach_m"])):
				sat.append(CacheStore.sat_path(z, t.x, t.y))
	return {"dem": dem, "sat": sat}

func fetch(lat: float, lon: float, with_drapes: bool = true) -> void:
	_busy = true
	_with_drapes = with_drapes
	_t0 = Time.get_ticks_msec()
	_cached = 0
	_failed = 0
	_layers.clear()
	_queue.clear()
	for spec in DEM_LAYERS:
		_add_layer("dem", zoom_for(lat, spec["target_mpp"], 15), lat, lon, spec["reach_m"])
	if with_drapes:
		for spec in DRAPE_LAYERS:
			_add_layer("sat", zoom_for(lat, spec["target_mpp"], 18), lat, lon, spec["reach_m"])
	_remaining = _queue.size()
	if _remaining == 0:
		_finish()
		return
	for job in _queue.duplicate():
		_load(job)

func _add_layer(kind: String, zoom: int, lat: float, lon: float, reach_m: float) -> void:
	var rect := window_px(lat, lon, zoom, reach_m)
	var tiles := window_tiles(rect)
	_layers.append({"kind": kind, "zoom": zoom, "rect": rect, "tiles": tiles,
		"images": {}, "reach_m": reach_m})
	for t in tiles:
		_queue.append({"layer": _layers.size() - 1, "kind": kind, "zoom": zoom,
			"tile": t, "attempt": 0})

func _path(job: Dictionary) -> String:
	var t: Vector2i = job["tile"]
	if job["kind"] == "dem":
		return CacheStore.dem_path(job["zoom"], t.x, t.y)
	return CacheStore.sat_path(job["zoom"], t.x, t.y)

func _url(job: Dictionary) -> String:
	var t: Vector2i = job["tile"]
	if job["kind"] == "dem":
		return DemFetcher.URL_TEMPLATE % [job["zoom"], t.x, t.y]
	return SatelliteFetcher.URL_TEMPLATE % [job["zoom"], t.y, t.x]

func _load(job: Dictionary) -> void:
	var path := _path(job)
	if FileAccess.file_exists(path):
		var cached := Image.new()
		if cached.load(path) == OK:
			CacheStore.note_read(path)
			_cached += 1
			_done(job, cached)
			return
	if offline_mode:
		_done(job, null)
		return
	var http := _free_http()
	if http == null:
		get_tree().create_timer(0.1).timeout.connect(func() -> void: _load(job))
		return
	var cb := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		http.set_meta("busy", false)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not body.is_empty():
			var img := Image.new()
			var err := img.load_png_from_buffer(body) if job["kind"] == "dem" \
				else img.load_jpg_from_buffer(body)
			if err == OK:
				var f := FileAccess.open(path, FileAccess.WRITE)
				if f != null:
					f.store_buffer(body)
					f.close()
					CacheStore.note_written(path)
				_done(job, img)
				return
		if int(job["attempt"]) < 1:
			job["attempt"] = 1
			get_tree().create_timer(0.5).timeout.connect(func() -> void: _load(job))
		else:
			_done(job, null)
	http.request_completed.connect(cb, CONNECT_ONE_SHOT)
	if http.request(_url(job), ["User-Agent: %s" % USER_AGENT]) != OK:
		http.request_completed.disconnect(cb)
		http.set_meta("busy", false)
		_done(job, null)

func _free_http() -> HTTPRequest:
	for http in _pool:
		if not http.get_meta("busy", false):
			http.set_meta("busy", true)
			return http
	return null

func _done(job: Dictionary, img: Image) -> void:
	if img != null:
		_layers[int(job["layer"])]["images"][job["tile"]] = img
	else:
		_failed += 1
	_remaining -= 1
	if _remaining <= 0:
		_finish()

func _finish() -> void:
	var fetch_ms := Time.get_ticks_msec() - _t0
	var t1 := Time.get_ticks_msec()
	var rings: Array = []
	var drapes: Array = []
	for layer in _layers:
		var images: Dictionary = layer["images"]
		if images.size() < (layer["tiles"] as Array).size():
			print("Far-field %s z%d incomplete (%d/%d tiles): layer dropped" % [
				layer["kind"], layer["zoom"], images.size(), (layer["tiles"] as Array).size()])
			continue
		if layer["kind"] == "dem":
			rings.append(_assemble_dem(layer))
		else:
			drapes.append(_assemble_drape(layer))
	timings = {"fetch_ms": fetch_ms, "assemble_ms": Time.get_ticks_msec() - t1,
		"tiles": _queue.size(), "cached": _cached, "failed": _failed}
	_busy = false
	finished.emit(rings, drapes)

## Decodes the window's Terrarium pixels straight from each tile's byte
## buffer (no per-pixel Color allocation) into metres ASL.
func _assemble_dem(layer: Dictionary) -> Dictionary:
	var rect: Rect2i = layer["rect"]
	var w := rect.size.x
	var h := rect.size.y
	var heights := PackedFloat32Array()
	heights.resize(w * h)
	for t in layer["tiles"]:
		var img: Image = layer["images"][t]
		if img.get_format() != Image.FORMAT_RGB8:
			img.convert(Image.FORMAT_RGB8)
		var bytes := img.get_data()
		var tw := img.get_width()
		var tile_rect := Rect2i(t.x * TILE_PX, t.y * TILE_PX, TILE_PX, TILE_PX)
		var inter := tile_rect.intersection(rect)
		for gy in range(inter.position.y, inter.end.y):
			var row_src := (gy - tile_rect.position.y) * tw
			var row_dst := (gy - rect.position.y) * w - rect.position.x
			for gx in range(inter.position.x, inter.end.x):
				var i := (row_src + gx - tile_rect.position.x) * 3
				heights[row_dst + gx] = float(bytes[i]) * 256.0 + float(bytes[i + 1]) \
					+ float(bytes[i + 2]) / 256.0 - 32768.0
	return {"zoom": layer["zoom"], "origin_px": Vector2(rect.position),
		"width": w, "height": h, "heights": heights,
		"reach_m": layer["reach_m"]}

func _assemble_drape(layer: Dictionary) -> Dictionary:
	var tiles: Array = layer["tiles"]
	var first: Vector2i = tiles[0]
	var last: Vector2i = tiles[tiles.size() - 1]
	var nx := last.x - first.x + 1
	var ny := last.y - first.y + 1
	var img := Image.create(nx * TILE_PX, ny * TILE_PX, false, Image.FORMAT_RGB8)
	for t in tiles:
		var src: Image = layer["images"][t]
		if src.get_format() != Image.FORMAT_RGB8:
			src.convert(Image.FORMAT_RGB8)
		img.blit_rect(src, Rect2i(0, 0, TILE_PX, TILE_PX),
			Vector2i((t.x - first.x) * TILE_PX, (t.y - first.y) * TILE_PX))
	img.generate_mipmaps()
	return {"zoom": layer["zoom"], "origin_px": Vector2(first * TILE_PX),
		"size_px": Vector2i(nx * TILE_PX, ny * TILE_PX),
		"texture": ImageTexture.create_from_image(img), "image": img,
		"reach_m": layer["reach_m"]}
