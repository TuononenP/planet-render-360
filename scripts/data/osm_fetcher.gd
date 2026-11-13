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
## Emitted just before `succeeded` when the answer is not a fresh full
## Overpass reply: `detail` is the loading row's short mono text ("Nearby ·
## 450 m", "Offline copy", "Within 800 m"), `partial` whether part of the
## view is left without map data.
signal fallback_used(detail: String, partial: bool)

## Overpass endpoints. Each live query uses one instance, the first that
## is not paused (OverpassRequest.max_attempts): a failure goes straight
## to the cache and OSM API fallbacks instead of waiting on mirrors that
## rarely answer. private.coffee is only reached while the main instance
## is paused and a caller allows a second instance (the offline pack).
## Only full-planet instances belong here — regional ones (osm.ch,
## maprva.org, ...) silently return zero buildings outside their extract.
## The OSM-FR instance refuses unlisted clients (HTTP 403, live probe
## 2026-11-04). A probe (2026-10-31, Helsinki 1200 m) had private.coffee
## answering nothing, not even a one-node query; on 2026-11-11 it still
## accepted connections but sent nothing for 40 s. z.overpass-api.de
## refuses connections since 2026-11-11 (port 443 and 80, live probe) and
## was removed.
## No Russian-operated instance belongs here (see HostPolicy); the
## Russian-hosted mirror that used to be listed was removed for that reason.
## When all of these fail, PostpassFallback (a PostGIS copy of OSM on a
## separate server) is next, then OsmApiFallback (the OSM API bbox).
## The reason both tiers give for a valid but empty answer (open sea,
## wilderness); DataNotes.osm_outage matches on it.
const NO_BUILDINGS := "returned no buildings"
const ENDPOINTS: Array[String] = [
	"https://overpass-api.de/api/interpreter",
	"https://overpass.private.coffee/api/interpreter",
]

## ENDPOINTS with the instances whose URL contains one of `first` moved
## to the front, in that order; the rest keep ENDPOINTS order. Callers
## name hosts instead of indexing, so reordering ENDPOINTS cannot
## silently change another query's mirrors.
static func endpoint_order(first: Array[String]) -> Array[String]:
	var all := active_endpoints()
	var out: Array[String] = []
	for host in first:
		for ep in all:
			if ep.contains(host) and not out.has(ep):
				out.append(ep)
	for ep in all:
		if not out.has(ep):
			out.append(ep)
	return out

## The instances in use: ENDPOINTS unless RemoteConfig replaces them.
static func active_endpoints() -> Array[String]:
	return RemoteConfig.value("overpass_endpoints", ENDPOINTS)

## The ring runs alongside the detailed query. It used to start on a
## mirror to keep the main instance's per-IP slots for the detailed
## query, but no mirror answers (2026-11-11), so it starts on the main
## instance too (a 429 there: OverpassRequest.RATE_LIMIT_CODES).
static func ring_endpoints() -> Array[String]:
	return endpoint_order(["//overpass-api.de"])

## Seconds the best-effort ring may still run once the detailed data is
## ready; past this the fetch finishes with the detailed data alone.
const RING_GRACE_S := 10.0

## Per-attempt HTTP timeout. The query's own [timeout:30] fires
## first on a healthy connection; this only bounds a hung one.
## Single source for the retry budget below and for _http.timeout,
## so the two can never drift apart. Raised 35→60 s in T2.3: a full
## Paris 800 m response is ≈8 MB and measured 25–47 s end to end.
const ATTEMPT_TIMEOUT := 60.0

## Worst-case seconds for both fetch phases (detailed and the
## best-effort ring, now concurrent, so this is a generous bound): one
## attempt timeout per phase (each query uses one instance), plus slack
## each. Callers waiting on succeeded/failed must wait at least this long
## or a late rescue is dropped. Typical is far lower (a failure falls back
## at once, a silent instance after OverpassRequest.FIRST_BYTE_TIMEOUT).
## Plus one Postpass attempt, one OSM API attempt, and a second's worth of
## each step down to a smaller box (OsmApiFallback.STEP_DOWN_CODES) so a
## late result lands.
static func retry_budget_seconds() -> float:
	return 2.0 * (ATTEMPT_TIMEOUT + 5.0) + PostpassFallback.TIMEOUT_S + 5.0 \
		+ ATTEMPT_TIMEOUT + 5.0 + OsmApiFallback.extra_budget_seconds()

## How long a place where Overpass and the OSM API both found nothing is
## not asked again (CacheStore.osm_empty_path).
const EMPTY_TTL_S := 7 * 24 * 3600

static func _known_empty(lat: float, lon: float) -> bool:
	var path := CacheStore.osm_empty_path(lat, lon)
	return FileAccess.file_exists(path) \
		and Time.get_unix_time_from_system() - FileAccess.get_modified_time(path) < EMPTY_TTL_S

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
var _postpass_http: HTTPRequest
var _detailed_req: OverpassRequest
var _ring_req: OverpassRequest
var _poi_req: OverpassRequest
var _bridge_req: OverpassRequest
var _bridge_postpass: HTTPRequest
var _ring_grace: Timer

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = ATTEMPT_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_api_done)
	_postpass_http = HTTPRequest.new()
	_postpass_http.timeout = PostpassFallback.TIMEOUT_S
	add_child(_postpass_http)
	_postpass_http.request_completed.connect(_on_postpass_done)
	_detailed_req = OverpassRequest.new(ATTEMPT_TIMEOUT)
	add_child(_detailed_req)
	_detailed_req.answered.connect(_on_detailed_answered)
	_detailed_req.exhausted.connect(_on_detailed_exhausted)
	_ring_req = OverpassRequest.new(ATTEMPT_TIMEOUT)
	add_child(_ring_req)
	_ring_req.answered.connect(_on_ring_answered)
	_ring_req.exhausted.connect(_on_ring_exhausted)
	_poi_req = OverpassRequest.new(15.0)
	add_child(_poi_req)
	_poi_req.answered.connect(_on_poi_answered)
	_poi_req.exhausted.connect(_on_poi_exhausted)
	_bridge_req = OverpassRequest.new(15.0)
	add_child(_bridge_req)
	_bridge_req.answered.connect(_on_bridges_answered)
	_bridge_req.exhausted.connect(_on_bridges_exhausted)
	_bridge_postpass = HTTPRequest.new()
	_bridge_postpass.timeout = PostpassFallback.TIMEOUT_S
	add_child(_bridge_postpass)
	_bridge_postpass.request_completed.connect(_on_bridges_postpass)
	_ring_grace = Timer.new()
	_ring_grace.one_shot = true
	_ring_grace.wait_time = RING_GRACE_S
	_ring_grace.timeout.connect(_on_ring_grace)
	add_child(_ring_grace)
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
## ISO 3166-1 alpha-2 country of the last parsed viewpoint ("" unknown:
## API fallback, or a payload cached before the query asked for it).
var country := ""
## Railway dicts of the last parsed payload (OsmTags._rail_entry).
var railways: Array = []
## Street furniture nodes of the last success (OsmParser.furniture_kind).
var furniture: Array = []
## Tram and bus stop nodes {x, z, name} of the last success (empty for
## payloads cached before the query asked for them).
var tram_stops: Array = []
var bus_stops: Array = []
## Railway platform outlines {points} and mainline station nodes
## {x, z, name} of the last success (empty for older payloads).
var rail_platforms: Array = []
var rail_stations: Array = []
## Shop, amenity, office, tourism, craft and advertising nodes.
var pois: Array = []
## Pier / pontoon ways of the last success (width_m NaN when untagged).
var piers: Array = []
var shore_structures: Array = []
## man_made=bridge outlines of the last parse (OsmParser._bridge_area).
var bridge_areas: Array = []

## Abandon any request still in flight. HTTPRequest serves one request at
## a time and answers ERR_BUSY (44) to a second one; a cancelled or
## restarted generation left its Overpass request running, so the next
## fetch burned every retry on 44 and then lost the real response's
## state. cancel_request() emits no request_completed, so nothing stale
## reaches the handlers.
func cancel() -> void:
	# A parse still running off-thread belongs to the abandoned fetch.
	_parse_gen += 1
	# So does any step of the OSM API fallback.
	_api_tier = 0
	if _http != null:
		_http.cancel_request()
	if _postpass_http != null:
		_postpass_http.cancel_request()
	if _detailed_req != null:
		_detailed_req.cancel()
	if _ring_req != null:
		_ring_req.cancel()
	if _poi_req != null:
		_poi_req.cancel()
	if _bridge_req != null:
		_bridge_req.cancel()
	if _bridge_postpass != null:
		_bridge_postpass.cancel_request()
	if _ring_grace != null:
		_ring_grace.stop()

## The parse task must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_parse()

## Bundled snapshots load on workers; created on first use.
var _snapshots: SnapshotReader

func _reader() -> SnapshotReader:
	if _snapshots == null:
		_snapshots = SnapshotReader.new()
		add_child(_snapshots)
	return _snapshots

func fetch(lat: float, lon: float, preset: int = 2, include_pois: bool = true) -> void:
	cancel()
	# Reading a snapshot suspends this function; a newer fetch (or cancel)
	# bumps _parse_gen and this one stops where it is.
	var gen := _parse_gen
	# Default preset 2 is RenderSettings.Preset.HIGH (the phone default);
	# out-of-range presets fall back to it, not to Fast.
	var p := preset if preset >= 0 and preset <= 3 else 2
	_poi_enabled = include_pois and p > RenderSettings.Preset.FAST
	var radius := radius_for_preset(p)
	var ring := ring_radius_for_preset(p)
	_pending_lat = lat
	_pending_lon = lon
	country = ""
	railways = []
	tram_stops = []
	bus_stops = []
	rail_platforms = []
	rail_stations = []
	shore_structures = []
	bridge_areas = []
	pois = []
	# Cache key v2 (contract §5): radius suffix keeps preset queries
	# from colliding; the ring keeps its own _ring marker (a different
	# query shape, not the detailed query at a larger radius).
	# Legacy osm3_/osm4_ files are ignored, never migrated (V18).
	_pending_cache = CacheStore.osm_path(lat, lon, radius)
	_pending_body = "data=" + build_query(lat, lon, radius).uri_encode()
	_pending_ring_cache = ""
	_detailed_text = ""
	_ring_text = ""
	_transit_text = ""
	_poi_text = ""
	_poi_started = false
	_poi_pending = false
	_poi_cache = CacheStore.osm_poi_path(lat, lon)
	_bridge_text = ""
	_bridge_started = false
	_bridge_pending = false
	_bridge_cache = CacheStore.osm_bridge_path(lat, lon)
	_detailed_ready = false
	_ring_pending = false
	_tried = 1
	_api_reason = ""
	_fallback_detail = ""
	_fallback_partial = false
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
	var snapshot := BundledOsm.entry_for(lat, lon, "detailed", OsmQuery.QUERY_VERSION)
	var dcached := _read_cache(_pending_cache) if BundledOsm.cache_is_newer(_pending_cache, snapshot) else ""
	# Older builds keyed all query revisions to the same filename. Reuse a
	# matching current payload without another network request, while keeping
	# the old file intact for offline fallback.
	if dcached == "":
		var legacy := _read_cache(CacheStore.osm_legacy_path(lat, lon, radius))
		if legacy != "" and OsmQuery.is_current(legacy) and BundledOsm.cache_is_newer(
				CacheStore.osm_legacy_path(lat, lon, radius), snapshot):
			dcached = legacy
			_write_cache(_pending_cache, legacy)
	# A payload from an older query (no railways/squares) goes live once;
	# _detailed_fallback still serves it if the network fails.
	if dcached != "" and OsmQuery.is_current(dcached):
		_detailed_text = dcached
		_detailed_cached = true
	if _detailed_text == "":
		_detailed_text = await _reader().read(snapshot)
		if gen != _parse_gen:
			return
		if _detailed_text != "":
			_detailed_cached = true
			_transit_text = await _reader().read(BundledOsm.entry_for(lat, lon, "transit", OsmQuery.TRANSIT_VERSION))
			if gen != _parse_gen:
				return
	if want_ring:
		var ring_key := BundledOsm.entry_for(lat, lon, "ring%d" % ring, OsmQuery.RING_VERSION)
		_ring_text = _read_cache(_pending_ring_cache) if BundledOsm.cache_is_newer(_pending_ring_cache, ring_key) else ""
		if _ring_text != "" and not _payload_usable(_ring_text):
			_ring_text = ""
		if _ring_text == "":
			_ring_text = await _reader().read(ring_key)
			if gen != _parse_gen:
				return
	if offline_mode:
		if _detailed_text != "":
			_detailed_done()
		else:
			_detailed_fallback("OSM not cached (offline mode)")
		return
	var known_empty := _detailed_text == "" and _known_empty(lat, lon)
	# Both phases go live at once; _try_finish waits for the pair.
	if want_ring and _ring_text == "" and not known_empty:
		_ring_pending = true
		_ring_req.run("data=" + build_ring_query(lat, lon, ring).uri_encode(),
			_check_ring, ring_endpoints())
	if _detailed_text != "":
		_detailed_done()
	elif known_empty:
		print("OsmFetcher: no buildings here on the last check; not asking Overpass again")
		_api_failed(NO_BUILDINGS, "Overpass " + NO_BUILDINGS)
	else:
		# With an older copy of this place on hand, a queued instance is
		# not worth the full first-byte wait.
		_detailed_req.first_byte_timeout = OverpassRequest.FALLBACK_FIRST_BYTE_S \
			if not OsmNearbyCache.candidates(lat, lon, SAME_PLACE_M).is_empty() \
			else OverpassRequest.FIRST_BYTE_TIMEOUT
		_detailed_req.run(_pending_body, _detailed_check(lat, lon), active_endpoints())

var _pending_lat := 0.0
var _pending_lon := 0.0
var _pending_cache := ""
var _pending_body := ""
var _pending_ring_cache := ""
var _detailed_text := ""
var _detailed_cached := false
var _detailed_ready := false
var _ring_text := ""
## The bundled transit layer, read only when a bundled snapshot stands in for
## the detailed answer (a live answer already carries these stops).
var _transit_text := ""
var _poi_text := ""
var _poi_cache := ""
var _poi_started := false
var _poi_pending := false
var _poi_enabled := true
## The bridge outline layer (OsmQuery.build_bridge_area_query): its own
## request and cache file, asked for alongside the POIs. Without it
## BridgeStructures falls back to grouping the bridge ways.
var _bridge_text := ""
var _bridge_cache := ""
var _bridge_started := false
var _bridge_pending := false
var _ring_pending := false
var _parse_task := -1
var _parse_gen := 0
var _tried := 1
var _api_tier := 0
var _api_reason := ""
var _fallback_detail := ""
var _fallback_partial := false

static func _read_cache(path: String) -> String:
	if path == "" or not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	CacheStore.note_read(path)
	return f.get_as_text()

static func _write_cache(path: String, text: String) -> bool:
	if not AtomicFile.write_text(path, text):
		return false
	CacheStore.note_written(path)
	OsmNearbyCache.note(path)
	return true

## A cached/live detailed payload is usable when it parses to a
## non-empty building set (the cached path pays one extra parse here;
## ≈0.2 s on a 6 MB Paris response, inside the ≤5 s revisit budget).
static func _payload_has_buildings(text: String, lat: float, lon: float) -> bool:
	var probe := parse_features(text, lat, lon)
	return not (probe["buildings"] as Array).is_empty()

## A mapped natural shore is useful even when there are no houses.
## Preserve it on live requests and offline revisits alike.
static func _has_shore_data(parsed: Dictionary) -> bool:
	if not (parsed.get("waterways", []) as Array).is_empty() \
			or not (parsed.get("shore_structures", []) as Array).is_empty():
		return true
	for poly in parsed.get("land", []):
		if str(poly.get("class", "")) == "water":
			return true
	return false

static func _mentions_shores(text: String) -> bool:
	for tag in ["\"water\"", "\"waterway\"", "\"coastline\"", "\"quay\"", "\"retaining_wall\"", "\"embankment\""]:
		if text.contains(tag):
			return true
	return false

## Cheap stand-in for _payload_has_buildings on payloads that were
## validated before they were cached: no parse on the main thread, and
## the full parse then happens once, in _finish().
static func _mentions_buildings(text: String) -> bool:
	return text.contains("\"building\"")

## A ring payload is usable when it is valid JSON with an element list
## (empty is fine — the ring carries majors only, never buildings).
static func _payload_usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and parsed.get("elements", null) is Array \
		and str(parsed.get("remark", "")).strip_edges() == ""

## Transient failures are worth another instance: any transport
## error (timeout, cannot connect, ...) or a 429/5xx from an
## overloaded server. A 403 is an instance's access policy, and a 406 is
## Overpass's rate limit, so try a different public mirror; malformed
## queries (400) still stop.
static func is_retryable(result: int, code: int) -> bool:
	if result != HTTPRequest.RESULT_SUCCESS:
		return true
	return code in [403, 406, 429, 500, 502, 503, 504]

## One instance returning neither buildings nor shore geometry is not authoritative: it may lag
## replication or hold a partial extract, so the payload is rejected and
## the OSM API asked instead; when that finds nothing too, the place is
## marked empty (CacheStore.osm_empty_path). This also covers corrupt
## payloads, which parse to nothing.
## Runs on OverpassRequest's worker thread, so it captures the centre
## instead of reading this node's state.
static func _detailed_check(lat: float, lon: float) -> Callable:
	return func(text: String) -> String:
		var error := OverpassRequest.payload_error(text)
		if error != "":
			return error
		var parsed := parse_features(text, lat, lon)
		if not (parsed["buildings"] as Array).is_empty() or _has_shore_data(parsed):
			return ""
		return "Overpass " + NO_BUILDINGS

static func _check_ring(text: String) -> String:
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
	_ring_grace.stop()
	_ring_text = text
	_write_cache(_pending_ring_cache, text)
	_ring_pending = false
	_try_finish()

## The ring is best-effort garnish: its failure degrades to the detailed
## data, never to a failed fetch.
func _on_ring_exhausted(reason: String, _attempts: int) -> void:
	_ring_grace.stop()
	push_warning("OsmFetcher: ring query failed (%s); detailed data only" % reason)
	_ring_text = ""
	_ring_pending = false
	_try_finish()

func _detailed_done() -> void:
	_detailed_ready = true
	if _ring_pending:
		_ring_grace.start()
	_try_finish()

func _on_ring_grace() -> void:
	if _detailed_ready and _ring_pending:
		_ring_req.cancel()
		_on_ring_exhausted("no answer %d s after the detailed data" % int(RING_GRACE_S), 0)

func _try_finish() -> void:
	if not _detailed_ready or _ring_pending:
		return
	if not _bridge_started:
		_bridge_started = true
		_bridge_text = _read_cache(_bridge_cache)
		if _bridge_text != "" and not _payload_usable(_bridge_text):
			_bridge_text = ""
		if _bridge_text == "" and not offline_mode:
			_bridge_pending = true
			_bridge_req.run("data=" + OsmQuery.build_bridge_area_query(_pending_lat, _pending_lon,
				DETAILED_RADIUS_M).uri_encode(), _check_ring, ring_endpoints().slice(0, 1))
	if not _poi_started:
		_poi_started = true
		var poi_key := BundledOsm.entry_for(_pending_lat, _pending_lon, "poi", OsmQuery.POI_VERSION)
		_poi_text = _read_cache(_poi_cache) if _poi_enabled and BundledOsm.cache_is_newer(_poi_cache, poi_key) else ""
		if _poi_text != "" and not _payload_usable(_poi_text):
			_poi_text = ""
		if _poi_enabled and _poi_text == "":
			# Reading the snapshot counts as the POI step still pending, so
			# another caller of _try_finish cannot finish without it.
			_poi_pending = true
			var gen := _parse_gen
			_poi_text = await _reader().read(poi_key)
			if gen != _parse_gen:
				return
			_poi_pending = false
		if _poi_text == "" and _poi_enabled and not offline_mode:
			_poi_pending = true
			_poi_req.run("data=" + OsmQuery.build_poi_query(_pending_lat, _pending_lon).uri_encode(),
				_check_ring, ring_endpoints().slice(0, 1))
			return
	if not _poi_pending and not _bridge_pending:
		_finish()

func _on_bridges_answered(text: String) -> void:
	_bridge_text = text
	_write_cache(_bridge_cache, text)
	_bridge_pending = false
	_try_finish()

## Overpass is out (a rate limit, a paused instance): Postpass has the
## same outlines.
func _on_bridges_exhausted(reason: String, _attempts: int) -> void:
	var err := _bridge_postpass.request(PostpassFallback.endpoint(),
		["User-Agent: " + Brand.USER_AGENT, "Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST, PostpassFallback.build_bridge_body(_pending_lat, _pending_lon, DETAILED_RADIUS_M))
	if err != OK:
		_bridges_unavailable("%s; Postpass failed to start: %s" % [reason, err])
	else:
		_bridge_reason = reason

var _bridge_reason := ""

func _on_bridges_postpass(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if not _bridge_pending:
		return
	var json := ""
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		json = str(PostpassFallback.to_overpass_json(body)["json"])
	if json == "":
		_bridges_unavailable("%s; Postpass result=%d code=%d" % [_bridge_reason, result, code])
		return
	_on_bridges_answered(json)

func _bridges_unavailable(reason: String) -> void:
	print("OsmFetcher: bridge outlines unavailable (%s); grouping bridge ways instead" % reason)
	_bridge_pending = false
	_try_finish()

func _on_poi_answered(text: String) -> void:
	_poi_text = text
	_write_cache(_poi_cache, text)
	_poi_pending = false
	_try_finish()

func _on_poi_exhausted(reason: String, _attempts: int) -> void:
	print("OsmFetcher: POIs unavailable (%s); using other map data" % reason)
	_poi_pending = false
	_try_finish()

## Detailed phase out of live Overpass options. Register fallback order:
## same-place cache (any radius) → Postpass → OSM API bbox → nearby cache
## → procedural.
func _detailed_fallback(reason: String) -> void:
	if _use_cached(reason, SAME_PLACE_M):
		return
	if offline_mode:
		_api_failed("skipped (offline mode)", reason)
		return
	_api_reason = reason
	var err := _postpass_http.request(PostpassFallback.endpoint(),
		["User-Agent: " + Brand.USER_AGENT, "Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST,
		PostpassFallback.build_body(_pending_lat, _pending_lon, DETAILED_RADIUS_M))
	if err != OK:
		_postpass_failed("failed to start: %s" % err)

## Postpass gave nothing usable: on to the OSM API.
func _postpass_failed(why: String) -> void:
	print("OsmFetcher: %s; Postpass %s; trying the OSM API" % [_api_reason, why])
	_api_tier = 0
	_request_api()

func _on_postpass_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_postpass_failed("failed (result=%d code=%d)" % [result, code])
		return
	_join_parse()
	var gen := _parse_gen
	var lat := _pending_lat
	var lon := _pending_lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		_on_postpass_converted.call_deferred(gen,
			_with_shores(PostpassFallback.to_overpass_json(body), lat, lon)))

## Marks a converted fallback payload with no buildings that still maps a
## shore (a harbour, a lake edge), which Overpass's own check accepts too.
## Parses only then, as a payload without buildings is small. Thread-safe.
static func _with_shores(converted: Dictionary, lat: float, lon: float) -> Dictionary:
	converted["shores"] = int(converted["buildings"]) == 0 and str(converted["json"]) != "" \
		and _has_shore_data(parse_features(converted["json"], lat, lon))
	return converted

func _on_postpass_converted(gen: int, converted: Dictionary) -> void:
	_join_parse()
	if gen != _parse_gen:
		return
	# Nothing mapped (open sea, wilderness, a garbled answer): the OSM API
	# decides, so the known-empty marker still needs both sources to agree.
	if int(converted["buildings"]) == 0 and not converted["shores"]:
		_postpass_failed(NO_BUILDINGS)
		return
	_detailed_text = converted["json"]
	_detailed_cached = false
	# Under the OSM API key, not osm_path: it is not the Overpass query's
	# answer, so Overpass is asked again next time.
	_write_cache(CacheStore.osm_api_path(_pending_lat, _pending_lon, DETAILED_RADIUS_M),
		_detailed_text)
	_detailed_done()

## Serve the nearest cached payload within max_m that holds mapped geometry,
## and say so: a payload keyed more than SAME_PLACE_M away leaves part of
## the view empty ("Nearby"), a closer one is only a stale copy.
## Stops waiting on the network for the detailed layer (a streamed
## build ran out of time): a nearby cached copy if there is one, else
## failed. Live requests are dropped so no late answer lands.
func give_up(reason: String) -> void:
	cancel()
	# The ring, bridge and POI steps settle with what is at hand: none of
	# them may hold the finish or ask Overpass again.
	_ring_pending = false
	_bridge_started = true
	_bridge_pending = false
	_poi_started = true
	_poi_pending = false
	if not _use_cached(reason, NEARBY_M):
		failed.emit(reason)

func _use_cached(reason: String, max_m: float) -> bool:
	for path in OsmNearbyCache.candidates(_pending_lat, _pending_lon, max_m).slice(0, 3):
		var text := _read_cache(path)
		if text != "" and (_mentions_buildings(text) or _mentions_shores(text)):
			print("OsmFetcher: %s; using cached %s" % [reason, path.get_file()])
			var d := OsmNearbyCache.distance_m(path, _pending_lat, _pending_lon)
			var incomplete := OverpassRequest.payload_error(text) != ""
			_fallback_partial = d > SAME_PLACE_M or incomplete
			_fallback_detail = "Nearby · %d m" % snappedi(int(d), 10) \
				if d > SAME_PLACE_M else ("Partial offline copy" if incomplete else "Offline copy")
			_detailed_text = text
			_detailed_cached = false
			_detailed_done()
			return true
	return false

func _request_api() -> void:
	var radius := OsmApiFallback.RADII_M[_api_tier]
	var err := _http.request(OsmApiFallback.url_for(_pending_lat, _pending_lon, radius),
		["User-Agent: " + Brand.USER_AGENT])
	if err != OK:
		_api_failed("failed to start: %s" % err, _api_reason)

func _api_failed(why: String, reason: String) -> void:
	var full := "%s; OSM API %s" % [reason, why]
	if not _use_cached(full, NEARBY_M):
		_ring_req.cancel()
		failed.emit("%s (tried %d endpoint(s))" % [full, _tried])

func _on_api_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if OsmApiFallback.steps_down(result, code) \
			and _api_tier + 1 < OsmApiFallback.RADII_M.size():
		_api_tier += 1  # over the node cap or throttled: try a smaller box
		_request_api()
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_api_failed("failed (result=%d code=%d)" % [result, code], _api_reason)
		return
	_join_parse()
	var gen := _parse_gen
	var lat := _pending_lat
	var lon := _pending_lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		_on_api_converted.call_deferred(gen,
			_with_shores(OsmApiFallback.to_overpass_json(body), lat, lon)))

func _on_api_converted(gen: int, converted: Dictionary) -> void:
	_join_parse()
	if gen != _parse_gen:
		return
	if int(converted["buildings"]) == 0 and not converted["shores"]:
		# Both sources agree over the whole view: remember it, so the next
		# load does not ask either again (a smaller box proves nothing).
		if _api_reason == "Overpass " + NO_BUILDINGS \
				and OsmApiFallback.RADII_M[_api_tier] >= DETAILED_RADIUS_M:
			_write_cache(CacheStore.osm_empty_path(_pending_lat, _pending_lon), '{"elements":[]}')
		_api_failed(NO_BUILDINGS, _api_reason)
		return
	_detailed_text = converted["json"]
	_detailed_cached = false
	# Not under osm_path: that key means "a fresh Overpass answer", and
	# this payload is lossy, so Overpass is asked again next time.
	var radius: int = OsmApiFallback.RADII_M[_api_tier]
	_write_cache(CacheStore.osm_api_path(_pending_lat, _pending_lon, radius),
		_detailed_text)
	if radius < DETAILED_RADIUS_M:
		_fallback_detail = "Within %d m" % radius
		_fallback_partial = true
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
	var poi := _poi_text
	# Small next to the city, so joined with the POIs rather than re-parsing
	# the merged city once more.
	if _transit_text != "":
		poi = merge_payloads(poi, _transit_text)
	if _bridge_text != "":
		poi = merge_payloads(poi, _bridge_text)
	var lat := _pending_lat
	var lon := _pending_lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		var parsed := parse_features(merge_payloads(merge_payloads(detailed, ring), poi), lat, lon)
		_on_parsed.call_deferred(gen, parsed))

func _join_parse() -> void:
	if _parse_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_parse_task)
		_parse_task = -1

func _on_parsed(gen: int, parsed: Dictionary) -> void:
	_join_parse()
	if gen != _parse_gen:
		return
	if _detailed_cached and (parsed["buildings"] as Array).is_empty() and not _has_shore_data(parsed):
		# No usable buildings or shore geometry: retry the damaged entry.
		push_warning("OsmFetcher: cached payload has no buildings; refetching")
		_detailed_cached = false
		_detailed_text = ""
		_detailed_ready = false
		if offline_mode:
			_detailed_fallback("OSM cache unusable (offline mode)")
		else:
			_detailed_req.run(_pending_body, _detailed_check(_pending_lat, _pending_lon),
				active_endpoints())
		return
	if _fallback_detail != "":
		fallback_used.emit(_fallback_detail, _fallback_partial)
	country = str(parsed.get("country", ""))
	railways = parsed.get("railways", [])
	furniture = parsed.get("furniture", [])
	tram_stops = parsed.get("tram_stops", [])
	bus_stops = parsed.get("bus_stops", [])
	rail_platforms = parsed.get("rail_platforms", [])
	rail_stations = parsed.get("rail_stations", [])
	pois = parsed.get("pois", [])
	piers = parsed.get("piers", [])
	shore_structures = parsed.get("shore_structures", [])
	bridge_areas = parsed.get("bridge_areas", [])
	succeeded_v2.emit(parsed["roads"], parsed["waterways"],
		parsed["trees"], parsed["barriers"])
	succeeded.emit(parsed["buildings"], roads_to_v1(parsed["roads"]),
		parsed["land"], parsed.get("landmarks", []))
