class_name BundledOsm
extends RefCounted

## Immutable Overpass snapshots for exact preset origins. Each entry is
## [latitude, longitude, layer, query version, OSM timestamp, inflated bytes, SHA-256].
## Missing layers deliberately use the ordinary network/cache fallback.
const ENTRIES := {
	"san_francisco_far": [37.8040, -122.4195, "far", 3, "2026-11-02T21:21:26", 3389888, "76bd4a396b4f0ee9570354e7c8c94ca185bc750655e65af98f9b8a51bc45f66c"],
	"new_york_far": [40.7060, -74.0040, "far", 3, "2026-10-31T00:00:00", 20182951, "34411c39c87edab6b073f175b5bb959ee17d207758993ba2080aa7ac3e52142a"],
	"new_york_ring1600": [40.7060, -74.0040, "ring1600", 1, "2026-10-31T00:00:00", 527912, "b88cbaaf630dd9a68176988de26a301f67f1683c69a9feadfd3c82c83b47fa50"],
	"new_york_ring2500": [40.7060, -74.0040, "ring2500", 1, "2026-10-31T00:00:00", 630149, "fc2740b00ad16629d0f04b69d552ea042875f94866671a5ec180f23f76dac3a2"],
	"new_york_poi": [40.7060, -74.0040, "poi", 1, "2026-10-31T00:00:00", 452828, "f10d05bb8cce6f9b47485be68802ce883710c12b47e96fc3610aff15de0d4963"],
	"san_francisco_ring1600": [37.8040, -122.4195, "ring1600", 1, "2026-10-31T00:00:00", 290353, "3450e4b284d7a4b201c8d4f796cb8bf523bd1e7f2e02604e579672d35e3b2c92"],
	"san_francisco_ring2500": [37.8040, -122.4195, "ring2500", 1, "2026-10-31T00:00:00", 520242, "8e72644d2c2feafd058d1840c914bcb50e4a757b06c2729dccf26075d7bf171f"],
	"san_francisco_poi": [37.8040, -122.4195, "poi", 1, "2026-10-31T00:00:00", 142554, "6029a520ba637a8a6e7fbf81d119a086e56d7594fa040434fc74c2f3157281c3"],
	"helsinki_detailed": [60.1680, 24.9530, "detailed", 12, "2026-11-02T21:21:26", 14473370, "7fa53acf219303c800828119507e2fb6b2a0e5f65112cc3eb4e39aad8ad9101f"],
	"helsinki_ring1600": [60.1680, 24.9530, "ring1600", 1, "2026-11-02T21:21:26", 1047377, "015deaba1adf3f6b9bc568f8f99ffc00d2265b11a1557bd2769bd034ce3e5190"],
	"helsinki_ring2500": [60.1680, 24.9530, "ring2500", 1, "2026-11-02T21:21:26", 1351289, "948ccfa8b96d664562e9dba0d196f44a7ea092ae6bdbe8b37229618920b643ff"],
	"helsinki_poi": [60.1680, 24.9530, "poi", 1, "2026-11-02T21:21:26", 841295, "03c3ba96cf189dea3a06e7fcd753bb29f6725a5d4049dc1213eff98409d3436f"],
	"stockholm_detailed": [59.3207, 18.0604, "detailed", 12, "2026-11-02T21:21:26", 12094326, "825145148ea4a0051c7cb4395c1d11591d9bd447f365d44128ca33384c823664"],
	"stockholm_ring1600": [59.3207, 18.0604, "ring1600", 1, "2026-11-02T21:21:26", 586043, "a9edd795ac812dc252419252abeb97b4d13ee4ccba74addd6d037be6c0d98867"],
	"stockholm_ring2500": [59.3207, 18.0604, "ring2500", 1, "2026-11-02T21:21:26", 786911, "8a756def7d95094c8a2ec55d550419d8ce4c4eb85868a2d5805602091af59224"],
	"stockholm_poi": [59.3207, 18.0604, "poi", 1, "2026-11-02T21:21:26", 433030, "e7f768f8f5ded0ad3cdd4d4e189483f67466c98f0d2bfbc9a253a966e9d33b53"],
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
		# Preset coordinates pass through Vector2 (32-bit components) before
		# reaching the fetchers. Compare in that representation so the same
		# preset still matches after the round trip, without matching nearby pins.
		if Vector2(lat, lon) == Vector2(float(entry[0]), float(entry[1])) \
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
