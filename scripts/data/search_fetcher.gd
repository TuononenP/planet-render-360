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
const USER_AGENT := Brand.USER_AGENT
## Failure copy in the design system's voice: what still works, no codes.
const UNREACHABLE := "Search is unavailable right now. Coordinates like 46.5, 7.9 still work."
const NO_MATCH := "No places match \"%s\". Try a landmark, a town or coordinates like 46.5, 7.9"

var _http: HTTPRequest
var _busy := false
var _query := ""
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
	# Ask for extra so a city ranked below POIs still makes the top 5.
	return "%s?format=jsonv2&addressdetails=1&limit=10&accept-language=en&q=%s" % [ENDPOINT, query.uri_encode()]

## Settlement kinds, listed ahead of landmarks, streets and the like.
const CITY_TYPES := ["city", "town", "municipality", "village"]

## Cities first (a search can match a place inside the same city), the
## server's own relevance order kept within each group. An address query
## (`address`: it has a street number) keeps the server's order, since
## the house is the answer and a city would only bury it.
static func parse_results(text: String, address: bool = false) -> Array:
	var cities: Array = []
	var others: Array = []
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				var kind := str(item.get("addresstype", item.get("type", "")))
				(cities if kind in CITY_TYPES and not address else others).append({
					"name": result_name(item),
					"lat": float(item.get("lat", 0.0)),
					"lon": float(item.get("lon", 0.0)),
				})
	return cities + others

## "Mannerheimintie 5, Helsinki" for a house, so the city is not lost;
## "Helsinki, Finland" for a settlement, the same as the on-device list
## so the row does not change when the remote answer replaces it;
## everything else is the first two parts of the display name.
static func result_name(item: Dictionary) -> String:
	var addr: Variant = item.get("address", {})
	var kind := str(item.get("addresstype", item.get("type", "")))
	if kind in CITY_TYPES and addr is Dictionary and addr.has("country") \
			and str(item.get("name", "")) != "":
		return "%s, %s" % [str(item["name"]), str(addr["country"]).split(" / ")[-1]]
	if addr is Dictionary and addr.has("house_number"):
		var road := str(addr.get("road", addr.get("pedestrian", "")))
		if road != "":
			var line := "%s %s" % [road, str(addr["house_number"])]
			for key in ["city", "town", "village", "municipality"]:
				if addr.has(key):
					return "%s, %s" % [line, str(addr[key])]
			return line
	return short_name(str(item.get("display_name", "")))

static func has_digit(query: String) -> bool:
	for c in query:
		if c >= "0" and c <= "9":
			return true
	return false

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
	_query = query.strip_edges()
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
		push_warning("SearchFetcher: request failed to start: %s" % err)
		failed.emit(UNREACHABLE)

var _pending_cache := ""

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("SearchFetcher: search failed (result=%d code=%d)" % [result, code])
		failed.emit(UNREACHABLE)
		return
	var text := body.get_string_from_utf8()
	var f := FileAccess.open(_pending_cache, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
	_emit_parsed(text)

func _emit_parsed(text: String) -> void:
	var first := parse_first(text)
	if first.is_empty():
		failed.emit(NO_MATCH % _query)
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
			suggestions_ready.emit(cleaned,
				parse_results(f.get_as_text(), has_digit(cleaned)))
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
		suggestions_ready.emit(query, parse_results(text, has_digit(query)))
	else:
		suggestions_ready.emit(query, [])
	if _suggest_queued != "" and _suggest_queued != query:
		var next := _suggest_queued
		_suggest_queued = ""
		suggest(next)
	else:
		_suggest_queued = ""
