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
## is not repeated: z.overpass-api.de (same operator, separate pool)
## answered a live probe (2026-10-31) while the main one timed out. The
## OSM-FR instance (global data, free fair-use) answered while the main
## one reported "at capacity" (HTTP 502), so it is the first fallback.
## A later probe (2026-10-31, Helsinki 1200 m) had private.coffee
## answering nothing, not even a one-node query, so it is tried last.
## When all of these fail, OsmApiFallback (the OSM API bbox) is next.
const ENDPOINTS: Array[String] = [
	"https://overpass-api.de/api/interpreter",
	"https://overpass.openstreetmap.fr/api/interpreter",
	"https://maps.mail.ru/osm/tools/overpass/api/interpreter",
	"https://z.overpass-api.de/api/interpreter",
	"https://overpass.private.coffee/api/interpreter",
]

## Per-attempt HTTP timeout. The query's own [timeout:30] fires
## first on a healthy connection; this only bounds a hung one.
## Single source for the retry budget below and for _http.timeout,
## so the two can never drift apart. Raised 35→60 s in T2.3: a full
## Paris 800 m response is ≈8 MB and measured 25–47 s end to end.
const ATTEMPT_TIMEOUT := 60.0

## Worst-case seconds for both fetch phases (detailed and the
## best-effort ring, now concurrent, so this is a generous bound): one
## attempt timeout per endpoint per phase, plus slack each. Callers
## waiting on succeeded/failed must wait at least this long or a late
## rescue is dropped. Typical is far lower (a fast 502 moves on in ~1 s,
## a silent mirror in OverpassRequest.FIRST_BYTE_TIMEOUT).
## Plus one OSM API attempt (a 400 steps down a radius in ~1 s).
static func retry_budget_seconds() -> float:
	return 2.0 * (float(ENDPOINTS.size()) * ATTEMPT_TIMEOUT + 5.0) \
		+ ATTEMPT_TIMEOUT + 5.0

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
## area. If every endpoint fails, the cache and the OSM API step in
## (see _detailed_fallback).
const DETAILED_RADIUS_M := 1200
## Cache fallback reach (metres): quantised keys of the same place, then
## neighbouring cached spots once the OSM API has failed too.
const SAME_PLACE_M := 150.0
const NEARBY_M := 500.0
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

## OSM API fallback only; Overpass goes through the two requests below.
var _http: HTTPRequest
var _detailed_req: OverpassRequest
var _ring_req: OverpassRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = ATTEMPT_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_api_done)
	_detailed_req = OverpassRequest.new()
	add_child(_detailed_req)
	_detailed_req.answered.connect(_on_detailed_answered)
	_detailed_req.exhausted.connect(_on_detailed_exhausted)
	_ring_req = OverpassRequest.new()
	add_child(_ring_req)
	_ring_req.answered.connect(_on_ring_answered)
	_ring_req.exhausted.connect(_on_ring_exhausted)
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

## Abandon any request still in flight. HTTPRequest serves one request at
## a time and answers ERR_BUSY (44) to a second one; a cancelled or
## restarted generation left its Overpass request running, so the next
## fetch burned every retry on 44 and then lost the real response's
## state. cancel_request() emits no request_completed, so nothing stale
## reaches the handlers.
func cancel() -> void:
	# A parse still running off-thread belongs to the abandoned fetch.
	_parse_gen += 1
	if _http != null:
		_http.cancel_request()
	if _detailed_req != null:
		_detailed_req.cancel()
	if _ring_req != null:
		_ring_req.cancel()

## The parse task must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_parse()

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
	_detailed_text = ""
	_ring_text = ""
	_detailed_ready = false
	_ring_pending = false
	_tried = 1
	var want_ring := ring > radius
	if want_ring:
		_pending_ring_cache = CacheStore.osm_ring_path(lat, lon, ring)
	# Each phase serves from its own cache entry independently; a phase
	# with no usable cache goes live while the other stays cached.
	# A cache entry was validated (_payload_has_buildings) before it was
	# written, so it is not re-parsed here (T7.5: that probe was a second
	# full parse on the main thread); _on_parsed falls back to the live
	# query if a damaged entry parses to no buildings.
	_detailed_cached = false
	var dcached := _read_cache(_pending_cache)
	if dcached != "":
		_detailed_text = dcached
		_detailed_cached = true
	if want_ring:
		_ring_text = _read_cache(_pending_ring_cache)
	if offline_mode:
		if _detailed_text != "":
			_detailed_done()
		else:
			_detailed_fallback("OSM not cached (offline mode)")
		return
	# Both phases go live at once; _try_finish waits for the pair.
	if want_ring and _ring_text == "":
		_ring_pending = true
		_ring_req.run("data=" + build_ring_query(lat, lon, ring).uri_encode(),
			_check_ring)
	if _detailed_text != "":
		_detailed_done()
	else:
		_detailed_req.run(_pending_body, _check_detailed)

var _pending_lat := 0.0
var _pending_lon := 0.0
var _pending_cache := ""
var _pending_body := ""
var _pending_ring_cache := ""
var _detailed_text := ""
var _detailed_cached := false
var _detailed_ready := false
var _ring_text := ""
var _ring_pending := false
var _parse_task := -1
var _parse_gen := 0
var _tried := 1
var _api_tier := 0
var _api_reason := ""

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

## Next attempt index for a failed attempt, or -1 to give up.
static func next_attempt(attempt: int, retryable: bool) -> int:
	return attempt + 1 if retryable and attempt + 1 < ENDPOINTS.size() else -1

## One instance returning no buildings is not authoritative: it may lag
## replication or hold a partial extract, so OverpassRequest tries the
## next instance (a genuinely empty area just pays a few fast empty
## responses). This also covers corrupt payloads, which parse to nothing.
func _check_detailed(text: String) -> String:
	if _payload_has_buildings(text, _pending_lat, _pending_lon):
		return ""
	return "Overpass returned no buildings"

func _check_ring(text: String) -> String:
	return "" if _payload_usable(text) else "Overpass ring query returned an unusable payload"

func _on_detailed_answered(text: String) -> void:
	_detailed_text = text
	_detailed_cached = false
	_write_cache(_pending_cache, text)
	_detailed_done()

func _on_detailed_exhausted(reason: String, attempts: int) -> void:
	_tried = attempts
	_detailed_fallback(reason)

func _on_ring_answered(text: String) -> void:
	_ring_text = text
	_write_cache(_pending_ring_cache, text)
	_ring_pending = false
	_try_finish()

## The ring is best-effort garnish: its failure degrades to the detailed
## data, never to a failed fetch.
func _on_ring_exhausted(reason: String, _attempts: int) -> void:
	push_warning("OsmFetcher: ring query failed (%s); detailed data only" % reason)
	_ring_text = ""
	_ring_pending = false
	_try_finish()

func _detailed_done() -> void:
	_detailed_ready = true
	_try_finish()

func _try_finish() -> void:
	if _detailed_ready and not _ring_pending:
		_finish()

## Detailed phase out of live Overpass options. Register fallback order:
## same-place cache (any radius) → OSM API bbox → nearby cache → procedural.
func _detailed_fallback(reason: String) -> void:
	if _use_cached(reason, SAME_PLACE_M):
		return
	if offline_mode:
		_api_failed("skipped (offline mode)", reason)
		return
	_api_tier = 0
	_api_reason = reason
	_request_api()

## Serve the nearest cached payload within max_m that holds buildings.
func _use_cached(reason: String, max_m: float) -> bool:
	for path in OsmNearbyCache.candidates(_pending_lat, _pending_lon, max_m).slice(0, 3):
		var text := _read_cache(path)
		if text != "" and _payload_has_buildings(text, _pending_lat, _pending_lon):
			print("OsmFetcher: %s; using cached %s" % [reason, path.get_file()])
			_detailed_text = text
			_detailed_cached = false
			_detailed_done()
			return true
	return false

func _request_api() -> void:
	var radius := OsmApiFallback.RADII_M[_api_tier]
	var err := _http.request(OsmApiFallback.url_for(_pending_lat, _pending_lon, radius),
		["User-Agent: PlanetRender360/0.1"])
	if err != OK:
		_api_failed("failed to start: %s" % err, _api_reason)

func _api_failed(why: String, reason: String) -> void:
	var full := "%s; OSM API %s" % [reason, why]
	if not _use_cached(full, NEARBY_M):
		_ring_req.cancel()
		failed.emit("%s (tried %d endpoint(s))" % [full, _tried])

func _on_api_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 400 \
			and _api_tier + 1 < OsmApiFallback.RADII_M.size():
		_api_tier += 1  # over the API's 50 000-node cap: try a smaller box
		_request_api()
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_api_failed("failed (result=%d code=%d)" % [result, code], _api_reason)
		return
	_join_parse()
	var gen := _parse_gen
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		_on_api_converted.call_deferred(gen, OsmApiFallback.to_overpass_json(body)))

func _on_api_converted(gen: int, converted: Dictionary) -> void:
	_join_parse()
	if gen != _parse_gen:
		return
	if int(converted["buildings"]) == 0:
		_api_failed("returned no buildings", _api_reason)
		return
	_detailed_text = converted["json"]
	_detailed_cached = false
	_write_cache(CacheStore.osm_path(_pending_lat, _pending_lon,
		OsmApiFallback.RADII_M[_api_tier]), _detailed_text)
	_detailed_done()

## Merge the detailed + ring payloads, parse once, and emit both signals:
## v1 shapes on the frozen 4-arg signal, §2.5/§2.6 extras on succeeded_v2.
## The parse (seconds on a dense city) runs on a worker thread so the
## loading screen keeps drawing and cancel stays immediate (T7.5).
func _finish() -> void:
	_join_parse()
	var gen := _parse_gen
	var detailed := _detailed_text
	var ring := _ring_text
	var lat := _pending_lat
	var lon := _pending_lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		var parsed := parse_features(merge_payloads(detailed, ring), lat, lon)
		_on_parsed.call_deferred(gen, parsed))

func _join_parse() -> void:
	if _parse_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_parse_task)
		_parse_task = -1

func _on_parsed(gen: int, parsed: Dictionary) -> void:
	_join_parse()
	if gen != _parse_gen:
		return
	if _detailed_cached and (parsed["buildings"] as Array).is_empty():
		# Damaged cache entry: query live instead (offline: fail).
		push_warning("OsmFetcher: cached payload has no buildings; refetching")
		_detailed_cached = false
		_detailed_text = ""
		_detailed_ready = false
		if offline_mode:
			_detailed_fallback("OSM cache unusable (offline mode)")
		else:
			_detailed_req.run(_pending_body, _check_detailed)
		return
	succeeded_v2.emit(parsed["roads"], parsed["waterways"],
		parsed["trees"], parsed["barriers"])
	succeeded.emit(parsed["buildings"], roads_to_v1(parsed["roads"]),
		parsed["land"], parsed.get("landmarks", []))
