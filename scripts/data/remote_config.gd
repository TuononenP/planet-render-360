class_name RemoteConfig
extends Node

## Service addresses the app can switch without an update. The Nominatim
## usage policy requires it, and it is how the app moves off a service
## that blocks it or changes its terms. A small JSON file hosted with the
## project's pages (Brand.CONFIG_URL) overrides these built-in defaults:
##
##   {"version": 1,
##    "nominatim_endpoint": "https://…/search",
##    "overpass_endpoints": ["https://…/api/interpreter", …],
##    "postpass_endpoint": "https://…/api/interpreter",
##    "satellite_url_template": "https://…/tile/%d/%d/%d"}
##
## Every key is optional, and a value that fails its check is ignored, so
## a typo in the file cannot take a service away. A fetched file replaces
## all earlier overrides (an empty one clears them); a failed or garbled
## fetch keeps what the device already has. The last good file is cached
## on the device and applied at launch before the fetch finishes. The app
## never waits for it.
##
## The file travels over HTTPS from the project's own pages and only
## carries addresses of the public data services the app already calls.
## Cached tiles from a replaced imagery source stay until the cache
## evicts them.

const SCHEMA := 1
const CACHE_FILE := "remote_config.json"
const MAX_URL_LENGTH := 512
const MAX_OVERPASS_ENDPOINTS := 8
## Keys the file may set. Anything else is ignored.
const KEYS := ["nominatim_endpoint", "overpass_endpoints", "postpass_endpoint",
	"satellite_url_template"]

## Test hook: when non-empty, the cache lives here instead of user://.
static var cache_path_override := ""
## Validated overrides in force; empty means every built-in default.
static var _values: Dictionary = {}

var _http: HTTPRequest

## The override for `key`, or `fallback` when the file does not set it.
static func value(key: String, fallback: Variant) -> Variant:
	return _values.get(key, fallback)

static func cache_path() -> String:
	return cache_path_override if cache_path_override != "" else "user://" + CACHE_FILE

## The validated subset of a parsed file: known keys whose values pass
## their check. Anything that is not a current-schema object gives null,
## which callers treat as "no usable file".
static func sanitize(raw: Variant) -> Variant:
	if not raw is Dictionary:
		return null
	var version: Variant = raw.get("version")
	if not (version is float or version is int) or int(version) != SCHEMA:
		return null
	var out := {}
	var endpoint: Variant = raw.get("nominatim_endpoint")
	if is_https_url(endpoint):
		out["nominatim_endpoint"] = str(endpoint)
	var overpass: Variant = raw.get("overpass_endpoints")
	if overpass is Array and not (overpass as Array).is_empty() \
			and (overpass as Array).size() <= MAX_OVERPASS_ENDPOINTS:
		var urls: Array[String] = []
		for item in overpass:
			if is_https_url(item):
				urls.append(str(item))
		var distinct := {}
		for u in urls:
			distinct[u] = true
		# One mirror listed again would be retried as if it were several.
		if urls.size() == (overpass as Array).size() and distinct.size() == urls.size():
			out["overpass_endpoints"] = urls
	var postpass: Variant = raw.get("postpass_endpoint")
	if is_https_url(postpass):
		out["postpass_endpoint"] = str(postpass)
	var template: Variant = raw.get("satellite_url_template")
	if is_https_url(template) and is_tile_template(str(template)):
		out["satellite_url_template"] = str(template)
	return out

## A plain https address with no spaces or control characters, and a host
## HostPolicy allows (never a Russian-operated service).
static func is_https_url(candidate: Variant) -> bool:
	if not candidate is String:
		return false
	var url: String = candidate
	if url.length() > MAX_URL_LENGTH or not url.begins_with("https://") \
			or url.length() <= "https://".length():
		return false
	for i in url.length():
		if url.unicode_at(i) <= 32 or url.unicode_at(i) == 127:
			return false
	return not url.substr("https://".length()).begins_with("/") and not HostPolicy.is_blocked(url)

## Exactly three %d (zoom, then the two tile coordinates) and no other
## format code, so `template % [z, y, x]` can neither fail nor misplace.
static func is_tile_template(template: String) -> bool:
	return template.count("%d") == 3 and template.count("%") == 3

## Puts a parsed file in force, or returns false and changes nothing.
static func apply(raw: Variant) -> bool:
	var clean: Variant = sanitize(raw)
	if clean == null:
		return false
	_values = clean
	return true

static func clear() -> void:
	_values = {}

## The cached file from the last successful fetch, if there is one.
static func load_cached() -> bool:
	var path := cache_path()
	if not FileAccess.file_exists(path):
		return false
	return apply(JSON.parse_string(FileAccess.get_file_as_string(path)))

## Starts a background refresh. Add this node to the tree first.
func refresh(url: String = Brand.CONFIG_URL) -> void:
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 10.0
		add_child(_http)
		_http.request_completed.connect(_on_done)
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	if _http.request(url, ["User-Agent: " + Brand.USER_AGENT, "Accept: application/json"]) != OK:
		push_warning("RemoteConfig: request failed to start")

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var text := body.get_string_from_utf8()
	if apply(JSON.parse_string(text)) and text != FileAccess.get_file_as_string(cache_path()):
		AtomicFile.write_text(cache_path(), text)
