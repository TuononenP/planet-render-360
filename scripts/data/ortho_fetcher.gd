class_name OrthoFetcher
extends Node

## Fetches a city orthophoto mosaic (OrthoSource) on the same slippy-tile
## pixel grid as SatelliteFetcher: span x span tiles round the viewpoint
## tile at `zoom`, asked for as at most 2 x 2 WMS GetMap parts. Each part
## is cached raw (JPEG) per place under user://cache; parts decode and
## stitch on the worker pool. Whole or nothing: a failed or blank part
## fails the mosaic and the caller falls back (InnerImagery).

signal succeeded(texture: Texture2D, image: Image, origin_px: Vector2, zoom: int)
signal failed(reason: String)

const TIMEOUT_S := 30.0
const CACHE_VERSION := 1

## False for a fetch-only run (the streamer warming caches).
var textures := true
var offline := false
## The source of the last success: {src, zoom, span, metres_per_px}.
var source: Dictionary = {}
## A THUMB_PX copy of the last mosaic (colour matching).
var thumbnail: Image
const THUMB_PX := 64

var _pool: Array[HTTPRequest] = []
var _src := ""
var _zoom := 18
var _span := 7
var _lat := 0.0
var _lon := 0.0
var _origin := Vector2.ZERO
var _parts := 1
var _part_px := 0
var _bytes: Array = []  # per part, PackedByteArray or null
var _remaining := 0
var _failed := false
var _gen := 0
var _task := -1

func _ready() -> void:
	for i in 4:
		var http := HTTPRequest.new()
		http.timeout = TIMEOUT_S
		add_child(http)
		_pool.append(http)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join()

static func cache_path(src: String, zoom: int, span: int, lat: float, lon: float, part: int) -> String:
	return "%s/ortho_v%d_%s_z%d_s%d_%d_%d_p%d.jpg" % [CacheStore.base_dir(), CACHE_VERSION, src,
		zoom, span, CacheStore.quant(lat), CacheStore.quant(lon), part]

## Global-pixel origin of the span x span mosaic round (lat, lon).
static func origin_px(lat: float, lon: float, zoom: int, span: int) -> Vector2:
	var centre := DemFetcher.tile_xy(lat, lon, zoom)
	return Vector2((centre.x - span / 2) * OrthoSource.TILE_PX, (centre.y - span / 2) * OrthoSource.TILE_PX)

func cancel() -> void:
	_gen += 1
	for http in _pool:
		http.cancel_request()
	_join()

func fetch(src: String, lat: float, lon: float, zoom: int, span: int) -> void:
	cancel()
	_src = src
	_lat = lat
	_lon = lon
	_zoom = zoom
	_span = span
	_origin = origin_px(lat, lon, zoom, span)
	var size := span * OrthoSource.TILE_PX
	_parts = OrthoSource.parts_for(size)
	_part_px = size / _parts
	_bytes = []
	_bytes.resize(_parts * _parts)
	_remaining = _parts * _parts
	_failed = false
	source = {}
	var gen := _gen
	for i in _parts * _parts:
		var path := cache_path(src, zoom, span, lat, lon, i)
		if FileAccess.file_exists(path):
			CacheStore.note_read(path)
			_part_done(gen, i, FileAccess.get_file_as_bytes(path), false)
			continue
		if offline:
			_part_done(gen, i, PackedByteArray(), false)
			continue
		var http := _pool[i]
		var part_origin := _origin + Vector2(i % _parts, i / _parts) * float(_part_px)
		var url := OrthoSource.part_url(src, part_origin, _part_px, zoom)
		var done := func(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
			var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200 and _is_image(headers)
			_part_done(gen, i, body if ok else PackedByteArray(), ok)
		http.request_completed.connect(done, CONNECT_ONE_SHOT)
		if http.request(url, ["User-Agent: " + Brand.USER_AGENT]) != OK:
			http.request_completed.disconnect(done)
			_part_done(gen, i, PackedByteArray(), false)

## A GeoServer error comes back 200 as XML: only an image body counts.
static func _is_image(headers: PackedStringArray) -> bool:
	for h in headers:
		if h.to_lower().begins_with("content-type:"):
			return h.to_lower().contains("image/")
	return false

func _part_done(gen: int, i: int, body: PackedByteArray, fresh: bool) -> void:
	if gen != _gen:
		return
	if body.is_empty():
		_failed = true
	else:
		_bytes[i] = body
		if fresh:
			var path := cache_path(_src, _zoom, _span, _lat, _lon, i)
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(body)
				f.close()
				CacheStore.note_written(path)
	_remaining -= 1
	if _remaining > 0:
		return
	if _failed:
		failed.emit("Orthophoto unavailable")
		return
	_stitch(gen)

func _stitch(gen: int) -> void:
	var parts := _parts
	var part_px := _part_px
	var bytes := _bytes.duplicate()
	var out := {}
	_task = WorkerThreadPool.add_task(func() -> void:
		var size := parts * part_px
		var mosaic := Image.create(size, size, false, Image.FORMAT_RGB8)
		for i in parts * parts:
			var img := Image.new()
			if img.load_jpg_from_buffer(bytes[i]) != OK or OrthoSource.is_blank(img):
				out["error"] = "part %d unreadable or blank" % i
				_stitched.call_deferred(gen, out)
				return
			if img.get_format() != Image.FORMAT_RGB8:
				img.convert(Image.FORMAT_RGB8)
			if img.get_width() != part_px or img.get_height() != part_px:
				img.resize(part_px, part_px, Image.INTERPOLATE_BILINEAR)
			mosaic.blit_rect(img, Rect2i(0, 0, part_px, part_px), Vector2i(i % parts, i / parts) * part_px)
		var thumb := mosaic.duplicate() as Image
		thumb.resize(THUMB_PX, THUMB_PX, Image.INTERPOLATE_BILINEAR)
		out["thumb"] = thumb
		mosaic.generate_mipmaps()
		out["mosaic"] = mosaic
		_stitched.call_deferred(gen, out), false, "Stitch orthophoto")

func _stitched(gen: int, out: Dictionary) -> void:
	_join()
	if gen != _gen:
		return
	if out.has("error") or not out.has("mosaic"):
		# A blank part is past the data: drop the cached copies too.
		for i in _parts * _parts:
			DirAccess.remove_absolute(cache_path(_src, _zoom, _span, _lat, _lon, i))
		failed.emit("Orthophoto: %s" % str(out.get("error", "no mosaic")))
		return
	var mosaic: Image = out["mosaic"]
	thumbnail = out["thumb"]
	source = {"src": _src, "zoom": _zoom, "span": _span,
		"metres_per_px": SatelliteFetcher.metres_per_px(_lat, _zoom)}
	succeeded.emit(ImageTexture.create_from_image(mosaic) if textures else null, mosaic, _origin, _zoom)

func _join() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
