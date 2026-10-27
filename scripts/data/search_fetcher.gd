class_name SearchFetcher
extends Node

## Place search via Nominatim, per the OSMF Nominatim Usage Policy:
## identifying User-Agent, max 1 request at a time per channel, results
## cached on device, ODbL attribution. Predictions are debounced by the
## caller (never per-keystroke), capped at 5, and answered instantly
## from the on-device gazetteer first, so most typing sends nothing.
## Endpoint is a single constant so it can be switched.

signal succeeded(display_name: String, lat: float, lon: float)
signal failed(reason: String)
signal suggestions_ready(query: String, results: Array)

const ENDPOINT := "https://nominatim.openstreetmap.org/search"
const CACHE_DIR := "user://cache"
const USER_AGENT := "PlanetRender360/0.1"

var _http: HTTPRequest
var _busy := false
var _suggest_http: HTTPRequest
var _suggest_busy := false
var _suggest_query := ""
var _suggest_queued := ""
var _suggest_cache := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_suggest_http = HTTPRequest.new()
	_suggest_http.timeout = 15.0
	add_child(_suggest_http)
	_suggest_http.request_completed.connect(_on_suggest_done)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

static func build_url(query: String) -> String:
	return "%s?format=jsonv2&limit=1&q=%s" % [ENDPOINT, query.uri_encode()]

static func build_suggest_url(query: String) -> String:
	return "%s?format=jsonv2&limit=5&q=%s" % [ENDPOINT, query.uri_encode()]

static func parse_results(text: String) -> Array:
	var out: Array = []
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				out.append({
					"name": short_name(str(item.get("display_name", ""))),
					"lat": float(item.get("lat", 0.0)),
					"lon": float(item.get("lon", 0.0)),
				})
	return out

static func parse_first(text: String) -> Dictionary:
	var results := parse_results(text)
	return results[0] if not results.is_empty() else {}

static func short_name(display_name: String) -> String:
	var parts := display_name.split(",")
	if parts.size() >= 2:
		return "%s, %s" % [parts[0].strip_edges(), parts[1].strip_edges()]
	return display_name.strip_edges()

func search(query: String) -> void:
	if _busy:
		return
	var cleaned := query.strip_edges().to_lower()
	if cleaned.is_empty():
		return
	var cache_path := "%s/search_%s.json" % [CACHE_DIR,
		cleaned.sha1_text().substr(0, 12)]
	if FileAccess.file_exists(cache_path):
		var f := FileAccess.open(cache_path, FileAccess.READ)
		if f != null:
			_emit_parsed(f.get_as_text())
			return
	_busy = true
	_pending_cache = cache_path
	var err := _http.request(build_url(cleaned),
		["User-Agent: %s" % USER_AGENT, "Accept: application/json"])
	if err != OK:
		_busy = false
		failed.emit("Search request failed to start: %s" % err)

var _pending_cache := ""

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Search failed (result=%d code=%d)" % [result, code])
		return
	var text := body.get_string_from_utf8()
	var f := FileAccess.open(_pending_cache, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
	_emit_parsed(text)

func _emit_parsed(text: String) -> void:
	var first := parse_first(text)
	if first.is_empty():
		failed.emit("No results for that search")
		return
	succeeded.emit(short_name(str(first["name"])),
		float(first["lat"]), float(first["lon"]))

## Debounced predictions (caller waits ~450ms after the last keystroke).
## One request at a time; a newer query replaces any queued one. Cached
## queries answer with no network at all.
func suggest(query: String) -> void:
	var cleaned := query.strip_edges().to_lower()
	if cleaned.length() < 2:
		return
	if _suggest_busy:
		_suggest_queued = cleaned
		return
	var cache_path := "%s/suggest_%s.json" % [CACHE_DIR,
		cleaned.sha1_text().substr(0, 12)]
	if FileAccess.file_exists(cache_path):
		var f := FileAccess.open(cache_path, FileAccess.READ)
		if f != null:
			suggestions_ready.emit(cleaned, parse_results(f.get_as_text()))
			return
	_suggest_busy = true
	_suggest_query = cleaned
	_suggest_cache = cache_path
	var err := _suggest_http.request(build_suggest_url(cleaned),
		["User-Agent: %s" % USER_AGENT, "Accept: application/json"])
	if err != OK:
		_suggest_busy = false
		suggestions_ready.emit(cleaned, [])

func _on_suggest_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_suggest_busy = false
	var query := _suggest_query
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var text := body.get_string_from_utf8()
		var f := FileAccess.open(_suggest_cache, FileAccess.WRITE)
		if f != null:
			f.store_string(text)
		suggestions_ready.emit(query, parse_results(text))
	else:
		suggestions_ready.emit(query, [])
	if _suggest_queued != "" and _suggest_queued != query:
		var next := _suggest_queued
		_suggest_queued = ""
		suggest(next)
	else:
		_suggest_queued = ""
