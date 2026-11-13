class_name HelsinkiDemFetcher
extends Node

## Downloads the HelsinkiDem window for a viewpoint and decodes it. The
## response is cached under user://cache (CacheStore.base_dir) so a revisit
## works offline. No key, no account; see docs/data-source-register.md.

signal finished(raster: Dictionary)

const TIMEOUT_S := 20.0

var _http: HTTPRequest
var _path := ""
var _miss := ""
## Window size; a variant ("relief": DemRelief) caches apart.
var half_m := HelsinkiDem.HALF_M
var cells := HelsinkiDem.CELLS
var variant := ""
## Largest missing share accepted (a harbour window is half sea).
var max_missing := HelsinkiDem.MAX_MISSING
## Whether the last fetch failed on the network or the server (not on
## coverage): only that is an elevation outage worth telling the user.
var outage := false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_S
	add_child(_http)
	_http.request_completed.connect(_on_completed)

static func cache_path(lat: float, lon: float, var_name: String = "") -> String:
	return "%s/hkidem%s_v1_%d_%d.tif" % [CacheStore.base_dir(), var_name, CacheStore.quant(lat), CacheStore.quant(lon)]

## Marker for a window the city answered but has (almost) no data for
## (Espoo, Vantaa, open sea): a revisit skips the request and its wait.
static func miss_path(lat: float, lon: float, var_name: String = "") -> String:
	return "%s/hkidem%s_v1_%d_%d.miss" % [CacheStore.base_dir(), var_name, CacheStore.quant(lat), CacheStore.quant(lon)]

## Whether the city already answered "no data" for this window.
static func known_miss(lat: float, lon: float) -> bool:
	return FileAccess.file_exists(miss_path(lat, lon))

## Emits `finished` with the decoded raster, {} when the window is
## unavailable (network, format, or mostly outside the city's data).
func fetch(lat: float, lon: float, offline: bool = false) -> void:
	_path = cache_path(lat, lon, variant)
	_miss = miss_path(lat, lon, variant)
	outage = false
	if FileAccess.file_exists(_miss):
		finished.emit({})
		return
	if FileAccess.file_exists(_path):
		var cached := _decoded(FileAccess.get_file_as_bytes(_path), max_missing)
		if not cached.is_empty():
			CacheStore.note_read(_path)
			finished.emit(cached)
			return
	if offline:
		finished.emit({})
		return
	var err := _http.request(HelsinkiDem.request_url(lat, lon, half_m, cells), ["User-Agent: " + Brand.USER_AGENT])
	if err != OK:
		outage = true
		finished.emit({})

func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("Helsinki elevation model unavailable (result=%d code=%d)" % [result, code])
		outage = true
		finished.emit({})
		return
	var raster := _decoded(body, max_missing)
	if raster.is_empty():
		var decoded := HelsinkiDem.decode(body)
		if not decoded.is_empty():
			# A valid answer, mostly outside the city's data: remember it.
			var m := FileAccess.open(_miss, FileAccess.WRITE)
			if m != null:
				m.close()
				CacheStore.note_written(_miss)
		finished.emit({})
		return
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(body)
		f.close()
		CacheStore.note_written(_path)
	finished.emit(raster)

## The decoded raster when it is usable, else {}.
static func _decoded(bytes: PackedByteArray, max_share: float = HelsinkiDem.MAX_MISSING) -> Dictionary:
	var raster := HelsinkiDem.decode(bytes)
	if raster.is_empty() or HelsinkiDem.missing_share(raster) > max_share:
		return {}
	return raster
