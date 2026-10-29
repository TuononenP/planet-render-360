class_name OsmFetcher
extends Node

## Real buildings + roads + water + trees from OpenStreetMap via Overpass.
## Free, no key, direct from device; responses cached in user://cache.
## v2 (T2.3): tiered per-layer queries (800 m detailed + a preset-scaled
## low-detail ring), full footprint polygons, and rich tags normalised
## into the LocationData §2.4–§2.6 shapes — generation never sees raw
## OSM JSON. See docs/data-source-register.md.

signal succeeded(buildings: Array, roads: Array, land: Array, landmarks: Array)
## Closure W2 companion: extras the frozen 4-arg signal cannot carry.
signal succeeded_v2(roads_v2: Array, waterways: Array, trees: Array, barriers: Array)
signal failed(reason: String)

## Overpass endpoints, tried in order. The main instance regularly
## times out (result=13) or returns 502 when overloaded; a transient
## failure must not lose the whole fetch. Only full-planet instances
## belong here — regional ones (osm.ch, maprva.org, ...) silently
## return zero buildings outside their extract. The main instance
## is repeated last: overload is usually a busy slot, so a later
## retry often succeeds where the first attempt timed out. The OSM-FR
## instance (global data, free fair-use) answered a live probe while the
## main one reported "at capacity" (HTTP 502), so it is the first fallback.
const ENDPOINTS: Array[String] = [
	"https://overpass-api.de/api/interpreter",
	"https://overpass.openstreetmap.fr/api/interpreter",
	"https://maps.mail.ru/osm/tools/overpass/api/interpreter",
	"https://overpass.private.coffee/api/interpreter",
	"https://overpass-api.de/api/interpreter",
]

## Per-attempt HTTP timeout. The query's own [timeout:30] fires
## first on a healthy connection; this only bounds a hung one.
## Single source for the retry budget below and for _http.timeout,
## so the two can never drift apart. Raised 35→60 s in T2.3: a full
## Paris 800 m response is ≈8 MB and measured 25–47 s end to end.
const ATTEMPT_TIMEOUT := 60.0

## Worst-case seconds for both fetch phases (detailed, then the
## best-effort ring): one attempt timeout per endpoint per phase, plus
## slack each. Callers waiting on succeeded/failed must wait at least
## this long or a late rescue is dropped. Typical is far lower (a fast
## 502 moves on in ~1 s); only hung connections pay the full budget.
static func retry_budget_seconds() -> float:
	return 2.0 * (float(ENDPOINTS.size()) * ATTEMPT_TIMEOUT + 5.0)

const CACHE_DIR := "user://cache"


## Caps and Overpass timeout live in OsmQuery (single source); these
## aliases keep the historical OsmFetcher.* names working.
const OVERPASS_TIMEOUT_S = OsmQuery.OVERPASS_TIMEOUT_S
const CAP_BUILDINGS = OsmQuery.CAP_BUILDINGS
const CAP_PARTS = OsmQuery.CAP_PARTS
const CAP_HIGHWAYS = OsmQuery.CAP_HIGHWAYS
const CAP_WATERWAYS = OsmQuery.CAP_WATERWAYS
const CAP_NATURAL = OsmQuery.CAP_NATURAL
const CAP_LANDUSE = OsmQuery.CAP_LANDUSE
const CAP_LEISURE = OsmQuery.CAP_LEISURE
const CAP_BARRIERS = OsmQuery.CAP_BARRIERS
const CAP_TREE_NODES = OsmQuery.CAP_TREE_NODES
const CAP_RELATIONS = OsmQuery.CAP_RELATIONS
const CAP_RING_HIGHWAYS = OsmQuery.CAP_RING_HIGHWAYS
const CAP_RING_WATERWAYS = OsmQuery.CAP_RING_WATERWAYS
const CAP_RING_COASTLINE = OsmQuery.CAP_RING_COASTLINE
## Detailed-query radius in metres (contract §7 V12: RADIUS_M=420 is
## gone). T7.0 metre cutover: the detailed extent is 2400 m across, so
## the query reaches its 1200 m half-width on every preset (one shared
## cache entry per place; presets differ by LOD, never by data — AC-12).
## T2.3 measured 800 m Paris at ≈6 MB / 25–40 s; 1200 m is ≈2.25× the
## area. If every endpoint fails, a cached FALLBACK_RADIUS_M payload is
## served (register fallback order: smaller radius → cache).
const DETAILED_RADIUS_M := 1200
const FALLBACK_RADIUS_M := 800
static func radius_for_preset(_preset: int) -> int:
	return DETAILED_RADIUS_M

## Low-detail ring radius per preset (RenderSettings.Preset order Fast,
## Balanced, High, Ultra): a second query with major roads + waterways +
## coastline only, merged over the detailed response. Fast is near-ring
## only per §3.1; 0 disables the ring phase entirely.
static func ring_radius_for_preset(preset: int) -> int:
	match preset:
		0:
			return 0
		1:
			return 1600
		2:
			return 1600
		3:
			return 2500
		_:
			return 1600

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = ATTEMPT_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_done)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)


# --- Delegators: implementation lives in the focused class named. ---
static func build_query(lat: float, lon: float, radius_m: int = DETAILED_RADIUS_M) -> String:
	return OsmQuery.build_query(lat, lon, radius_m)

static func build_ring_query(lat: float, lon: float, ring_m: int) -> String:
	return OsmQuery.build_ring_query(lat, lon, ring_m)

static func archetype_for(tags: Dictionary) -> String:
	return OsmTags.archetype_for(tags)

static func land_class(tags: Dictionary) -> String:
	return OsmTags.land_class(tags)

static func local_xz(lat: float, lon: float, c_lat: float, c_lon: float) -> Vector2:
	return WorldScale.xz_from_latlon(lat, lon, c_lat, c_lon)

static func _tag_metres(raw: Variant, lo: float, hi: float) -> float:
	return OsmTags._tag_metres(raw, lo, hi)

static func _tag_int(raw: Variant, lo: int, hi: int) -> int:
	return OsmTags._tag_int(raw, lo, hi)

static func _tag_truthy(raw: Variant) -> bool:
	return OsmTags._tag_truthy(raw)

static func road_class_width(road_class: String) -> float:
	return OsmTags.road_class_width(road_class)

static func waterway_class_width(water_class: String) -> float:
	return OsmTags.waterway_class_width(water_class)

static func _resolve_height(tags: Dictionary, inherit: Dictionary = {}) -> Dictionary:
	return OsmTags._resolve_height(tags, inherit)

static func _polygon_centroid(pts: PackedVector2Array, fallback: Vector2) -> Vector2:
	return OsmGeometry._polygon_centroid(pts, fallback)

static func _point_in_ring(p: Vector2, ring: PackedVector2Array) -> bool:
	return OsmGeometry._point_in_ring(p, ring)

static func _building_entry(tags: Dictionary, pts: PackedVector2Array, aabb: Rect2) -> Dictionary:
	return OsmTags._building_entry(tags, pts, aabb)

static func _building_use(tags: Dictionary) -> String:
	return OsmTags._building_use(tags)

static func _road_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	return OsmTags._road_entry(tags, pts)

static func _member_segments(members: Array, want_outer: bool, c_lat: float, c_lon: float) -> Array:
	return OsmGeometry._member_segments(members, want_outer, c_lat, c_lon)

static func _join_rings(segs: Array) -> Array:
	return OsmGeometry._join_rings(segs)

static func _relation_land(tags: Dictionary, members: Array, c_lat: float, c_lon: float) -> Array:
	return OsmGeometry._relation_land(tags, members, c_lat, c_lon)

static func _waterway_entry(tags: Dictionary, pts: PackedVector2Array, forced_class: String = "") -> Dictionary:
	return OsmTags._waterway_entry(tags, pts, forced_class)

static func parse_features(text: String, c_lat: float, c_lon: float) -> Dictionary:
	return OsmParser.parse_features(text, c_lat, c_lon)

static func _is_closed(poly: PackedVector2Array) -> bool:
	return OsmGeometry._is_closed(poly)

static func _nest_parts(buildings: Array, part_ways: Array) -> void:
	OsmParser._nest_parts(buildings, part_ways)

static func _ring_aabb(ring: PackedVector2Array) -> Rect2:
	return OsmGeometry._ring_aabb(ring)

static func merge_payloads(first: String, second: String) -> String:
	return OsmParser.merge_payloads(first, second)

static func roads_to_v1(roads: Array) -> Array:
	return OsmParser.roads_to_v1(roads)

## Test hook (DEM/Satellite T2.1/T2.2 precedent): when true, fetch()
## serves the on-device cache or fails immediately — never the network.
var offline_mode := false

enum { _PHASE_DETAILED, _PHASE_RING }

## Abandon any request still in flight. HTTPRequest serves one request at
## a time and answers ERR_BUSY (44) to a second one; a cancelled or
## restarted generation left its Overpass request running, so the next
## fetch burned every retry on 44 and then lost the real response's
## state. cancel_request() emits no request_completed, so nothing stale
## reaches _on_done.
func cancel() -> void:
	if _http != null:
		_http.cancel_request()

func fetch(lat: float, lon: float, preset: int = 2) -> void:
	cancel()
	# Default preset 2 is RenderSettings.Preset.HIGH (the app default);
	# out-of-range presets fall back to it, not to Fast.
	var p := preset if preset >= 0 and preset <= 3 else 2
	var radius := radius_for_preset(p)
	var ring := ring_radius_for_preset(p)
	_pending_lat = lat
	_pending_lon = lon
	# Cache key v2 (contract §5): radius suffix keeps preset queries
	# from colliding; the ring keeps its own _ring marker (a different
	# query shape, not the detailed query at a larger radius).
	# Legacy osm3_/osm4_ files are ignored, never migrated (V18).
	_pending_cache = CacheStore.osm_path(lat, lon, radius)
	_pending_body = "data=" + build_query(lat, lon, radius).uri_encode()
	_pending_ring_cache = ""
	_pending_ring_body = ""
	_detailed_text = ""
	_ring_text = ""
	var want_ring := ring > radius
	if want_ring:
		_pending_ring_cache = CacheStore.osm_ring_path(lat, lon, ring)
		_pending_ring_body = "data=" + build_ring_query(lat, lon, ring).uri_encode()
	# Each phase serves from its own cache entry independently; a phase
	# with no usable cache goes live while the other stays cached.
	var dcached := _read_cache(_pending_cache)
	if dcached != "" and _payload_has_buildings(dcached, lat, lon):
		_detailed_text = dcached
	if want_ring:
		_ring_text = _read_cache(_pending_ring_cache)
	if offline_mode:
		if _detailed_text != "":
			_finish()
		else:
			_phase = _PHASE_DETAILED
			_attempt = 0
			_fail_or_retry("OSM not cached (offline mode)", false)
		return
	if _detailed_text != "" and (not want_ring or _ring_text != ""):
		_finish()
		return
	_phase = _PHASE_DETAILED if _detailed_text == "" else _PHASE_RING
	_attempt = 0
	_start_attempt()

var _pending_lat := 0.0
var _pending_lon := 0.0
var _pending_cache := ""
var _pending_body := ""
var _pending_ring_cache := ""
var _pending_ring_body := ""
var _detailed_text := ""
var _ring_text := ""
var _phase := _PHASE_DETAILED
var _attempt := 0

static func _read_cache(path: String) -> String:
	if path == "" or not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	CacheStore.note_read(path)
	return f.get_as_text()

static func _write_cache(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		CacheStore.note_written(path)

## A cached/live detailed payload is usable when it parses to a
## non-empty building set (the cached path pays one extra parse here;
## ≈0.2 s on a 6 MB Paris response, inside the ≤5 s revisit budget).
static func _payload_has_buildings(text: String, lat: float, lon: float) -> bool:
	var probe := parse_features(text, lat, lon)
	return not (probe["buildings"] as Array).is_empty()

## A ring payload is usable when it is valid JSON with an element list
## (empty is fine — the ring carries majors only, never buildings).
static func _payload_usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and parsed.get("elements", null) is Array

## Transient failures are worth another instance: any transport
## error (timeout, cannot connect, ...) or a 429/5xx from an
## overloaded server. A 4xx means the query itself is rejected.
static func is_retryable(result: int, code: int) -> bool:
	if result != HTTPRequest.RESULT_SUCCESS:
		return true
	return code in [429, 500, 502, 503, 504]

func _start_attempt() -> void:
	var headers := ["Content-Type: application/x-www-form-urlencoded",
		"User-Agent: PlanetRender360/0.1"]
	var body := _pending_body if _phase == _PHASE_DETAILED else _pending_ring_body
	var err := _http.request(ENDPOINTS[_attempt], headers,
		HTTPClient.METHOD_POST, body)
	if err != OK:
		_fail_or_retry("Overpass request failed to start: %s" % err, true)

## Next attempt index for a failed attempt, or -1 to give up.
static func next_attempt(attempt: int, retryable: bool) -> int:
	return attempt + 1 if retryable and attempt + 1 < ENDPOINTS.size() else -1

func _fail_or_retry(reason: String, retryable: bool) -> void:
	var next := next_attempt(_attempt, retryable)
	if next >= 0:
		_attempt = next
		_start_attempt()
	elif _phase == _PHASE_RING:
		# The ring is best-effort garnish: its failure degrades to the
		# detailed data, never to a failed fetch.
		push_warning("OsmFetcher: ring query failed (%s); detailed data only" % reason)
		_ring_text = ""
		_finish()
	else:
		# Register fallback order: a cached smaller-radius payload
		# (pre-T7.0 800 m) beats procedural dressing.
		var fb := _read_cache(CacheStore.osm_path(_pending_lat, _pending_lon,
			FALLBACK_RADIUS_M))
		if fb != "" and _payload_has_buildings(fb, _pending_lat, _pending_lon):
			print("OsmFetcher: %s; using cached %d m data" % [reason, FALLBACK_RADIUS_M])
			_detailed_text = fb
			_finish()
			return
		failed.emit("%s (tried %d endpoint(s))" % [reason, _attempt + 1])

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail_or_retry("Overpass failed (result=%d code=%d)" % [result, code],
			is_retryable(result, code))
		return
	var text := body.get_string_from_utf8()
	if _phase == _PHASE_DETAILED:
		if not _payload_has_buildings(text, _pending_lat, _pending_lon):
			# One instance returning no buildings is not authoritative:
			# it may lag replication or hold a partial extract. Try the
			# next instance before giving up (a genuinely empty area
			# just pays a few fast empty responses). This also covers
			# corrupt payloads, which parse to nothing.
			_fail_or_retry("Overpass returned no buildings", true)
			return
		_detailed_text = text
		_write_cache(_pending_cache, text)
		if _pending_ring_body != "" and _ring_text == "":
			_phase = _PHASE_RING
			_attempt = 0
			_start_attempt()
		else:
			_finish()
	else:
		if not _payload_usable(text):
			_fail_or_retry("Overpass ring query returned an unusable payload", true)
			return
		_ring_text = text
		_write_cache(_pending_ring_cache, text)
		_finish()

## Merge the detailed + ring payloads, parse once, and emit both signals:
## v1 shapes on the frozen 4-arg signal, §2.5/§2.6 extras on succeeded_v2.
func _finish() -> void:
	var parsed := parse_features(
		merge_payloads(_detailed_text, _ring_text), _pending_lat, _pending_lon)
	succeeded_v2.emit(parsed["roads"], parsed["waterways"],
		parsed["trees"], parsed["barriers"])
	succeeded.emit(parsed["buildings"], roads_to_v1(parsed["roads"]),
		parsed["land"], parsed.get("landmarks", []))
