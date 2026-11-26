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
const MAX_RETRIES := 1
const RETRY_DELAY_S := 0.5

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
var _fresh := PackedByteArray()  # 1 when downloaded this run, 0 when from cache
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
	_fresh.resize(_parts * _parts)
	_fresh.fill(0)
	_remaining = _parts * _parts
	_failed = false
	source = {}
	var gen := _gen
	for i in _parts * _parts:
		var path := cache_path(src, zoom, span, lat, lon, i)
		if FileAccess.file_exists(path):
			var cached := PackedByteArray([1]) if not textures else FileAccess.get_file_as_bytes(path)
			if not cached.is_empty():
				CacheStore.note_read(path)
				_part_done(gen, i, cached, false)
				continue
			DirAccess.remove_absolute(path)
		if offline:
			_part_done(gen, i, PackedByteArray(), false)
			continue
		_request_part(gen, i, 0)

func _request_part(gen: int, i: int, attempt: int) -> void:
	if gen != _gen:
		return
	var http := _pool[i]
	var part_origin := _origin + Vector2(i % _parts, i / _parts) * float(_part_px)
	var url := OrthoSource.part_url(_src, part_origin, _part_px, _zoom)
	var done := func(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
		if gen != _gen:
			return
		var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200 and _is_image(headers) and not body.is_empty()
		if ok:
			_part_done(gen, i, body, true)
			return
		var transient := result != HTTPRequest.RESULT_SUCCESS or code >= 500 or code == 429 or (code == 200 and not _is_image(headers))
		if transient and attempt < MAX_RETRIES and is_inside_tree():
			get_tree().create_timer(RETRY_DELAY_S).timeout.connect(func() -> void:
				_request_part(gen, i, attempt + 1), CONNECT_ONE_SHOT)
			return
		print("OrthoFetcher: %s part %d failed (result=%d code=%d bytes=%d)" % [_src, i, result, code, body.size()])
		_part_done(gen, i, PackedByteArray(), false)
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	if http.request(url, ["User-Agent: " + Brand.USER_AGENT]) != OK:
		http.request_completed.disconnect(done)
		_part_done(gen, i, PackedByteArray(), false)

## Decodes a WMS image part (PNG when the server sends a PNG header, else JPEG).
static func _decode_part(img: Image, body: PackedByteArray) -> Error:
	if body.size() >= 4 and body[0] == 0x89 and body[1] == 0x50 and body[2] == 0x4E and body[3] == 0x47:
		return img.load_png_from_buffer(body)
	var err := img.load_jpg_from_buffer(body)
	return err if err == OK else img.load_png_from_buffer(body)

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
		_bytes[i] = PackedByteArray()
		_fresh[i] = 0
	else:
		_bytes[i] = body
		_fresh[i] = 1 if fresh else 0
	_remaining -= 1
	if _remaining > 0:
		return
	var any_body := false
	for b in _bytes:
		if b is PackedByteArray and not (b as PackedByteArray).is_empty():
			any_body = true
			break
	if not any_body:
		failed.emit("Orthophoto unavailable")
		return
	if not textures:
		_validate_warm(gen)
		return
	_stitch(gen)

func _validate_warm(gen: int) -> void:
	var has_fresh := false
	for i in _fresh.size():
		if _fresh[i] != 0:
			has_fresh = true
			break
	if not has_fresh:
		source = _make_source()
		succeeded.emit(null, null, _origin, _zoom)
		return
	var parts := _parts
	var bytes := _bytes.duplicate()
	var fresh_flags := _fresh.duplicate()
	var out := {}
	_task = WorkerThreadPool.add_task(func() -> void:
		var valid := 0
		var bad: Array[int] = []
		for i in parts * parts:
			if fresh_flags[i] == 0:
				if bytes[i] is PackedByteArray and not (bytes[i] as PackedByteArray).is_empty():
					valid += 1
				continue
			var img := Image.new()
			if _decode_part(img, bytes[i]) != OK:
				bad.append(i)
			elif OrthoSource.is_blank(img):
				# Blank sea/edge quadrant: keep cached on partial mosaics so revisits skip WMS.
				if parts == 1:
					bad.append(i)
			else:
				valid += 1
		out["bad_parts"] = bad
		out["ok"] = valid > 0
		if valid == 0:
			out["error"] = "part %d unreadable or blank" % bad[0] if not bad.is_empty() else "all parts blank"
		_warm_validated.call_deferred(gen, out), false, "Validate orthophoto")

func _warm_validated(gen: int, out: Dictionary) -> void:
	_join()
	if gen != _gen:
		return
	for bp: int in out.get("bad_parts", []):
		if bp < _fresh.size():
			_fresh[bp] = 0
		DirAccess.remove_absolute(cache_path(_src, _zoom, _span, _lat, _lon, bp))
	if not bool(out.get("ok", false)):
		failed.emit("Orthophoto: %s" % str(out.get("error", "unreadable")))
		return
	_write_fresh_parts()
	source = _make_source()
	succeeded.emit(null, null, _origin, _zoom)

func _write_fresh_parts() -> void:
	for i in _parts * _parts:
		if i >= _fresh.size() or _fresh[i] == 0:
			continue
		var body: Variant = _bytes[i]
		if not (body is PackedByteArray) or (body as PackedByteArray).is_empty():
			continue
		var path := cache_path(_src, _zoom, _span, _lat, _lon, i)
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_buffer(body)
			f.close()
			CacheStore.note_written(path)

func _make_source() -> Dictionary:
	return {"src": _src, "zoom": _zoom, "span": _span,
		"metres_per_px": SatelliteFetcher.metres_per_px(_lat, _zoom)}

func _stitch(gen: int) -> void:
	var parts := _parts
	var part_px := _part_px
	var bytes := _bytes.duplicate()
	var out := {}
	_task = WorkerThreadPool.add_task(func() -> void:
		var total_parts := parts * parts
		var decoded: Array = []
		decoded.resize(total_parts)
		var bad: Array[int] = []
		var valid_count := 0
		var first_valid: Image = null
		for i in total_parts:
			var b: Variant = bytes[i]
			var img := Image.new()
			if not (b is PackedByteArray) or (b as PackedByteArray).is_empty() \
					or _decode_part(img, b) != OK:
				bad.append(i)
				continue
			if OrthoSource.is_blank(img):
				if total_parts == 1:
					bad.append(i)
				continue
			if img.get_width() != part_px or img.get_height() != part_px:
				img.resize(part_px, part_px, Image.INTERPOLATE_BILINEAR)
			decoded[i] = img
			valid_count += 1
			if first_valid == null:
				first_valid = img
		if valid_count == 0:
			out["error"] = "part %d unreadable or blank" % (bad[0] if not bad.is_empty() else 0)
			out["bad_parts"] = bad
			_stitched.call_deferred(gen, out)
			return
		var size := parts * part_px
		var partial := valid_count < total_parts
		var fmt := Image.FORMAT_RGBA8 if partial else Image.FORMAT_RGB8
		var mosaic := Image.create(size, size, false, fmt)
		if partial:
			var fill := first_valid.get_pixel(first_valid.get_width() / 2, first_valid.get_height() / 2)
			mosaic.fill(Color(fill.r, fill.g, fill.b, 0.0))
		for i in total_parts:
			var img: Image = decoded[i]
			if img == null:
				continue
			if img.get_format() != fmt:
				img.convert(fmt)
			mosaic.blit_rect(img, Rect2i(0, 0, part_px, part_px), Vector2i(i % parts, i / parts) * part_px)
		var thumb_src: Image = first_valid.duplicate() as Image if partial else mosaic.duplicate() as Image
		if thumb_src.get_format() != Image.FORMAT_RGB8:
			thumb_src.convert(Image.FORMAT_RGB8)
		thumb_src.resize(THUMB_PX, THUMB_PX, Image.INTERPOLATE_BILINEAR)
		out["thumb"] = thumb_src
		out["bad_parts"] = bad
		mosaic.generate_mipmaps()
		out["mosaic"] = mosaic
		_stitched.call_deferred(gen, out), false, "Stitch orthophoto")

func _stitched(gen: int, out: Dictionary) -> void:
	_join()
	if gen != _gen:
		return
	for bp: int in out.get("bad_parts", []):
		if bp < _fresh.size():
			_fresh[bp] = 0
		DirAccess.remove_absolute(cache_path(_src, _zoom, _span, _lat, _lon, bp))
	if out.has("error") or not out.has("mosaic"):
		failed.emit("Orthophoto: %s" % str(out.get("error", "no mosaic")))
		return
	_write_fresh_parts()
	var mosaic: Image = out["mosaic"]
	thumbnail = out["thumb"]
	source = _make_source()
	succeeded.emit(ImageTexture.create_from_image(mosaic) if textures else null, mosaic, _origin, _zoom)

func _join() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
