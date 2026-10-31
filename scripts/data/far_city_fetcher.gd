class_name FarCityFetcher
extends Node

## T5.4 — the far city's real data: ONE aggregated Overpass request per
## place (register rate discipline), cached, best-effort.
##  - built-up landuse (residential / commercial / industrial / retail
##    ways + multipolygon relations) to RADIUS_M: where the distant city
##    is and what kind of fabric it is (LocationData.far_landuse);
##  - real tall buildings (height ≥ TOWER_MIN_M or ≥ TOWER_MIN_LEVELS
##    levels) with their footprints: the only source of far modern-tower
##    clusters (LocationData.far_towers) — La Défense appears west of
##    Paris because OSM maps it, never because a rule guessed it.
## Absence is graceful: a failed/uncached fetch emits empty arrays and
## SettlementMap falls back to the far imagery drapes alone. Endpoints
## start at a mirror (endpoints()) so the call never queues behind the
## detailed OsmFetcher request on the main instance.

signal finished(landuse: Array, towers: Array)

const RADIUS_M := 12000
const TOWER_MIN_M := 50
const TOWER_MIN_LEVELS := 15
const CAP_LANDUSE := 6000
const CAP_RELATIONS := 400
const CAP_TOWERS := 1500
const ATTEMPT_TIMEOUT := 45.0
const LANDUSE := "^(residential|commercial|industrial|retail)$"

var offline_mode := false
## {ms, bytes, cached, landuse, towers} of the last fetch.
var timings: Dictionary = {}

var _req: OverpassRequest
var _busy := false
var _lat := 0.0
var _lon := 0.0
var _cache := ""
var _t0 := 0

func _ready() -> void:
	_req = OverpassRequest.new(ATTEMPT_TIMEOUT)
	add_child(_req)
	_req.answered.connect(_on_answered)
	_req.exhausted.connect(func(reason: String, _attempts: int) -> void:
		print("FarCityFetcher: %s; far city from imagery only" % reason)
		_emit("", false))

## Mirrors first, the main instance third (the detailed query starts
## there), four attempts. Named by host so reordering
## OsmFetcher.ENDPOINTS cannot change them.
static func endpoints() -> Array[String]:
	return OsmFetcher.endpoint_order(["openstreetmap.fr", "private.coffee",
		"//overpass-api.de", "mail.ru"]).slice(0, 4)

func is_busy() -> bool:
	return _busy

static func cache_path(lat: float, lon: float) -> String:
	# osm_v* prefix: accounted in the osm cache layer (CacheStore.layer_of).
	return "%s/osm_v%d_%d_%d_farcity%d.json" % [CacheStore.base_dir(),
		CacheStore.DATA_VERSION, CacheStore.quant(lat), CacheStore.quant(lon), RADIUS_M]

static func build_query(lat: float, lon: float, radius_m: int = RADIUS_M) -> String:
	var around := "(around:%d,%.6f,%.6f)" % [radius_m, lat, lon]
	return "[out:json][timeout:%d];" % OsmFetcher.OVERPASS_TIMEOUT_S \
		+ 'way["landuse"~"%s"]%s;out geom %d;' % [LANDUSE, around, CAP_LANDUSE] \
		+ 'relation["landuse"~"%s"]["type"="multipolygon"]%s;out geom %d;' \
			% [LANDUSE, around, CAP_RELATIONS] \
		+ 'way["building"](if:number(t["height"])>=%d||number(t["building:levels"])>=%d)%s;out geom %d;' \
			% [TOWER_MIN_M, TOWER_MIN_LEVELS, around, CAP_TOWERS]

func cancel() -> void:
	if _req != null:
		_req.cancel()
	_busy = false

func fetch(lat: float, lon: float) -> void:
	cancel()
	_lat = lat
	_lon = lon
	_t0 = Time.get_ticks_msec()
	_cache = cache_path(lat, lon)
	_busy = true
	var cached := OsmFetcher._read_cache(_cache)
	if cached != "" and _usable(cached):
		_emit(cached, true)
		return
	if offline_mode:
		_emit("", true)
		return
	_req.run("data=" + build_query(lat, lon).uri_encode(),
		func(text: String) -> String: return "" if _usable(text) else "unusable payload",
		endpoints())

func _on_answered(text: String) -> void:
	OsmFetcher._write_cache(_cache, text)
	_emit(text, false)

static func _usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and (parsed as Dictionary).get("elements", null) is Array

func _emit(text: String, cached: bool) -> void:
	var parsed := parse(text, _lat, _lon)
	timings = {"ms": Time.get_ticks_msec() - _t0, "bytes": text.length(),
		"cached": cached, "landuse": (parsed["landuse"] as Array).size(),
		"towers": (parsed["towers"] as Array).size()}
	_busy = false
	finished.emit(parsed["landuse"], parsed["towers"])

## {landuse: [{class, points, holes}], towers: [{footprint, x, z,
## height, levels}]} in metre XZ around (c_lat, c_lon).
static func parse(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var landuse: Array = []
	var towers: Array = []
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not (parsed is Dictionary):
		return {"landuse": landuse, "towers": towers}
	var seen := {}
	for el in (parsed as Dictionary).get("elements", []):
		if not (el is Dictionary):
			continue
		var key := str(el.get("type", "")) + ":" + str(el.get("id", ""))
		if seen.has(key):
			continue
		seen[key] = true
		var raw_tags: Variant = el.get("tags", {})
		var tags: Dictionary = raw_tags if raw_tags is Dictionary else {}
		var lu := str(tags.get("landuse", ""))
		if str(el.get("type", "")) == "relation":
			if lu == "" or not el.has("members"):
				continue
			var members: Array = el.get("members", [])
			var outers := OsmFetcher._join_rings(
				OsmFetcher._member_segments(members, true, c_lat, c_lon))
			var inners := OsmFetcher._join_rings(
				OsmFetcher._member_segments(members, false, c_lat, c_lon))
			for o in outers:
				var holes: Array = []
				for h in inners:
					if outers.size() == 1 or OsmFetcher._point_in_ring(
							(h as PackedVector2Array)[0], o):
						holes.append(h)
				landuse.append({"class": lu, "points": o, "holes": holes})
			continue
		var geom: Array = el.get("geometry", [])
		if geom.size() < 4:
			continue
		var pts := PackedVector2Array()
		for node in geom:
			if node is Dictionary:
				pts.append(WorldScale.xz_from_latlon(float(node.get("lat", c_lat)),
					float(node.get("lon", c_lon)), c_lat, c_lon))
		if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.01:
			pts.remove_at(pts.size() - 1)
		if pts.size() < 3:
			continue
		if tags.has("building"):
			var res := OsmFetcher._resolve_height(tags)
			var c := OsmFetcher._polygon_centroid(pts, RingGeometry.aabb(pts).get_center())
			towers.append({"footprint": pts, "x": c.x, "z": c.y,
				"height": float(res["height"]), "levels": int(res["levels"]),
				"kind": str(tags.get("building", "yes"))})
		elif lu != "":
			landuse.append({"class": lu, "points": pts, "holes": []})
	return {"landuse": landuse, "towers": towers}
