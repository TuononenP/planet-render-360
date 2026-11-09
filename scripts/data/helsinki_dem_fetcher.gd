class_name HelsinkiDemFetcher
extends Node

## Downloads the HelsinkiDem window for a viewpoint and decodes it. The
## response is cached under user://cache (CacheStore.base_dir) so a revisit
## works offline. No key, no account; see docs/data-source-register.md.

signal finished(raster: Dictionary)

const TIMEOUT_S := 20.0

var _http: HTTPRequest
var _path := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_S
	add_child(_http)
	_http.request_completed.connect(_on_completed)

static func cache_path(lat: float, lon: float) -> String:
	return "%s/hkidem_v1_%d_%d.tif" % [CacheStore.base_dir(), CacheStore.quant(lat), CacheStore.quant(lon)]

## Emits `finished` with the decoded raster, {} when the window is
## unavailable (network, format, or mostly outside the city's data).
func fetch(lat: float, lon: float, offline: bool = false) -> void:
	_path = cache_path(lat, lon)
	if FileAccess.file_exists(_path):
		var cached := _decoded(FileAccess.get_file_as_bytes(_path))
		if not cached.is_empty():
			CacheStore.note_read(_path)
			finished.emit(cached)
			return
	if offline:
		finished.emit({})
		return
	var err := _http.request(HelsinkiDem.request_url(lat, lon), ["User-Agent: " + Brand.USER_AGENT])
	if err != OK:
		finished.emit({})

func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("Helsinki elevation model unavailable (result=%d code=%d)" % [result, code])
		finished.emit({})
		return
	var raster := _decoded(body)
	if raster.is_empty():
		finished.emit({})
		return
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(body)
		f.close()
		CacheStore.note_written(_path)
	finished.emit(raster)

## The decoded raster when it is usable, else {}.
static func _decoded(bytes: PackedByteArray) -> Dictionary:
	var raster := HelsinkiDem.decode(bytes)
	if raster.is_empty() or HelsinkiDem.missing_share(raster) > HelsinkiDem.MAX_MISSING:
		return {}
	return raster
