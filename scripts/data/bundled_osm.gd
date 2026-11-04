class_name BundledOsm
extends RefCounted

## Immutable Overpass snapshots for exact preset origins. Each entry is
## [latitude, longitude, layer, query version, OSM timestamp, inflated bytes, SHA-256].
## Missing layers deliberately use the ordinary network/cache fallback.
const ENTRIES := {
	"new_york_detailed": [40.7060, -74.0040, "detailed", 12, "2026-11-04T13:18:25", 16752176, "961c08765d6877fd1aa6e511b6872b6db02b8c8990f5d712f296483380b0828e"],
	"san_francisco_detailed": [37.8040, -122.4195, "detailed", 12, "2026-11-04T13:16:20", 10341950, "10b158204da607694e7eea89616211d3c72251f3e2e04c63bfcd35bb749fb253"],
	"helsinki_far": [60.1680, 24.9530, "far", 3, "2026-11-04T14:47:51", 19509450, "0a4b68952ddcd3ed19d697480431bcc5d41defcfdbbf1d393beb06b259774777"],
	"stockholm_far": [59.3207, 18.0604, "far", 3, "2026-11-04T14:07:04", 14767350, "e8bc59790a3c35798a19cb6149e3d50e9baa744c453e43118bd7591f5b56be26"],
}
const DIRECTORY := "res://assets/osm_snapshots/"
const MAX_BYTES := 32 * 1024 * 1024
static var _refreshing: Dictionary = {}

static func entry_for(lat: float, lon: float, layer: String, version: int) -> String:
	for key in ENTRIES:
		var entry: Array = ENTRIES[key]
		if absf(lat - float(entry[0])) < 0.0000001 and absf(lon - float(entry[1])) < 0.0000001 \
				and layer == entry[2] and version == entry[3]:
			return key
	return ""

## An older device cache must not hide the snapshot. A missing snapshot
## never disqualifies an otherwise usable cache.
static func cache_is_newer(path: String, key: String) -> bool:
	if key == "" or not FileAccess.file_exists(DIRECTORY + key + ".json.gz"):
		return true
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	return _response_is_newer(file.get_as_text(), key)

static func _response_is_newer(text: String, key: String) -> bool:
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("elements", null) is Array \
			or str(data.get("remark", "")).strip_edges() != "":
		return false
	var metadata: Variant = data.get("osm3s", {})
	if not metadata is Dictionary:
		return false
	var stamp := str(metadata.get("timestamp_osm_base", "")).trim_suffix("Z")
	return stamp != "" and stamp >= str(ENTRIES[key][4])

static func read(key: String) -> String:
	if not ENTRIES.has(key):
		return ""
	var path := DIRECTORY + key + ".json.gz"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var raw := file.get_buffer(file.get_length()).decompress_dynamic(MAX_BYTES, FileAccess.COMPRESSION_GZIP)
	if raw.size() != int(ENTRIES[key][5]):
		return ""
	var text := raw.get_string_from_utf8()
	if text.sha256_text() != ENTRIES[key][6]:
		return ""
	if not OsmFetcher._payload_usable(text):
		return ""
	if ENTRIES[key][2] == "detailed" and (not OsmQuery.is_current(text) or not OsmFetcher._mentions_buildings(text)):
		return ""
	return text

## Detached from the pipeline so finishing the world cannot cancel a refresh.
## At most one request per snapshot is in flight and only validated data is saved.
static func refresh(tree: SceneTree, key: String, path: String, body: String,
		validate: Callable, endpoints: Array[String]) -> void:
	if tree == null or key == "" or _refreshing.has(key):
		return
	_refreshing[key] = true
	var req := OverpassRequest.new(60.0)
	var started := int(Time.get_unix_time_from_system())
	tree.root.add_child(req)
	req.answered.connect(func(text: String) -> void:
		if not FileAccess.file_exists(path) or FileAccess.get_modified_time(path) <= started:
			OsmFetcher._write_cache(path, text)
		_refreshing.erase(key)
		req.queue_free())
	req.exhausted.connect(func(_reason: String, _attempts: int) -> void:
		_refreshing.erase(key)
		req.queue_free())
	var checked := func(text: String) -> String:
		if not _response_is_newer(text, key):
			return "response is older than the bundled snapshot"
		if ENTRIES[key][2] == "detailed" and not OsmQuery.is_current(text):
			return "response has an incompatible query version"
		return str(validate.call(text))
	req.run(body, checked, endpoints.slice(0, 1))
