class_name DemFetcher
extends Node

## Real elevation from AWS Terrain Tiles (Terrarium PNG), fetched directly
## by the device. No key, no account, no proxy — see docs/data-source-register.md.
## Tiles are cached in user://cache so revisits work offline.
## Terrarium encoding: height = R*256 + G + B/256 - 32768 (metres).

signal succeeded(heights_metres: PackedFloat32Array, grid: int)
signal failed(reason: String)

const URL_TEMPLATE := "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/%d/%d/%d.png"
const ZOOM := 12
const FAR_ZOOM := 8  # one tile spans ~100 km: the far-terrain backdrop
const CACHE_DIR := "user://cache"

var _http: HTTPRequest
var _pending_grid := 48
var _pending_lat := 0.0
var _pending_lon := 0.0
var _zoom := ZOOM
## Viewpoint position (0..1) inside the far tile, set by fetch_far so
## the far mesh can be centred on the viewpoint, not the tile centre.
var far_centre_frac := Vector2(0.5, 0.5)

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

static func tile_xy(lat: float, lon: float, zoom: int) -> Vector2i:
	var n := float(1 << zoom)
	var x := int((lon + 180.0) / 360.0 * n)
	var lat_rad := deg_to_rad(lat)
	var y := int((1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n)
	return Vector2i(clampi(x, 0, int(n) - 1), clampi(y, 0, int(n) - 1))

func fetch(lat: float, lon: float, grid: int) -> void:
	_zoom = ZOOM
	_fetch_at_zoom(lat, lon, grid)

## Low-resolution backdrop: the whole zoom-8 tile sampled on a coarse
## grid. Same signals and Terrarium decode as the detailed fetch.
func fetch_far(lat: float, lon: float, grid: int) -> void:
	_zoom = FAR_ZOOM
	_fetch_at_zoom(lat, lon, grid)

func _fetch_at_zoom(lat: float, lon: float, grid: int) -> void:
	_pending_lat = lat
	_pending_lon = lon
	_pending_grid = grid
	var tile := tile_xy(lat, lon, _zoom)
	var cache_path := "%s/dem_%d_%d_%d.png" % [CACHE_DIR, _zoom, tile.x, tile.y]
	if FileAccess.file_exists(cache_path):
		var img := Image.new()
		if img.load(cache_path) == OK:
			_emit_from_image(img)
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
	var cache_path := "%s/dem_%d_%d_%d.png" % [CACHE_DIR, _zoom, tile.x, tile.y]
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(body)
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
	var n := float(1 << _zoom)
	var frac_x: float = ((_pending_lon + 180.0) / 360.0 * n) - floor((_pending_lon + 180.0) / 360.0 * n)
	var lat_rad := deg_to_rad(_pending_lat)
	var merc: float = (1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n
	var frac_y: float = merc - floor(merc)
	var heights := PackedFloat32Array()
	heights.resize(grid * grid)
	if _zoom == FAR_ZOOM:
		# Whole tile, evenly: the mesh is positioned via far_centre_frac.
		far_centre_frac = Vector2(frac_x, frac_y)
		for z in grid:
			for x in grid:
				var px := clampi(int(float(x) / float(grid - 1) * float(size - 1)), 0, size - 1)
				var py := clampi(int(float(z) / float(grid - 1) * float(size - 1)), 0, size - 1)
				var c := img.get_pixel(px, py)
				heights[z * grid + x] = (c.r8 * 256.0 + c.g8 + c.b8 / 256.0) - 32768.0
	else:
		var centre := Vector2(frac_x * size, frac_y * size)
		var step_px := 3  # ~110 m per sample at zoom 12; window covers the tile centre area
		for z in grid:
			for x in grid:
				var px := clampi(int(centre.x + (x - grid / 2.0) * step_px), 0, size - 1)
				var py := clampi(int(centre.y + (z - grid / 2.0) * step_px), 0, size - 1)
				var c := img.get_pixel(px, py)
				heights[z * grid + x] = (c.r8 * 256.0 + c.g8 + c.b8 / 256.0) - 32768.0
	succeeded.emit(heights, grid)
