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
const CAP_TOWERS := 3000
## Higher server-side limits leave room for client-side prominence selection.
const CAP_TOWER_CANDIDATES := 12000
const CAP_NEAR_TOWERS := 6000
const CAP_NEAR_PARTS := 8000
const CAP_TOWER_PARTS := 12000
const NEAR_RADIUS_M := 4000
## Bump only this layer when the tower selector changes.
const QUERY_VERSION := 3
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
var _parse_task := -1
## Bumped per fetch and cancel: a parse finishing late is dropped.
var _gen := 0

func _ready() -> void:
	_req = OverpassRequest.new(ATTEMPT_TIMEOUT)
	add_child(_req)
	_req.answered.connect(_on_answered)
	_req.exhausted.connect(func(reason: String, _attempts: int) -> void:
		_fallback(reason))

## The parse task must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_parse()

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
	return "%s/osm_v%d_%d_%d_farcity%d_q%d.json" % [CacheStore.base_dir(),
		CacheStore.DATA_VERSION, CacheStore.quant(lat), CacheStore.quant(lon), RADIUS_M, QUERY_VERSION]

static func legacy_cache_path(lat: float, lon: float) -> String:
	return "%s/osm_v%d_%d_%d_farcity%d.json" % [CacheStore.base_dir(),
		CacheStore.DATA_VERSION, CacheStore.quant(lat), CacheStore.quant(lon), RADIUS_M]

## Select both ways and multipolygon relations, retaining the explicit
## feet conversion rather than treating a feet-tagged height as metres.
static func _tower_selectors(around: String) -> String:
	var out := ""
	for typ in ["way", "relation"]:
		var mp := '["type"="multipolygon"]' if typ == "relation" else ""
		for key in ["building", "building:part"]:
			out += ('%s["%s"]%s["height"!~"([fF][tT]|\u0027) *$"]'
				+ '(if:number(t["height"])>=%d)%s;') % [typ, key, mp, TOWER_MIN_M, around]
			out += ('%s["%s"]%s["height"~"([fF][tT]|\u0027) *$"]'
				+ '(if:number(t["height"])*0.3048>=%d)%s;') % [typ, key, mp, TOWER_MIN_M, around]
			out += '%s["%s"]%s(if:number(t["building:levels"])>=%d)%s;' \
				% [typ, key, mp, TOWER_MIN_LEVELS, around]
	return out

static func build_query(lat: float, lon: float, radius_m: int = RADIUS_M) -> String:
	var around := "(around:%d,%.6f,%.6f)" % [radius_m, lat, lon]
	var near := "(around:%d,%.6f,%.6f)" % [mini(radius_m, NEAR_RADIUS_M), lat, lon]
	# The near set is printed separately before the wider set: Overpass's
	# output cap is ID-ordered, so it must not erase the foreground.
	return "[out:json][timeout:%d];" % OsmFetcher.OVERPASS_TIMEOUT_S \
		+ 'way["landuse"~"%s"]%s;out geom %d;' % [LANDUSE, around, CAP_LANDUSE] \
		+ 'relation["landuse"~"%s"]["type"="multipolygon"]%s;out geom %d;' \
			% [LANDUSE, around, CAP_RELATIONS] \
		+ '(%s)->.near; .near out geom %d;' % [_tower_selectors(near), CAP_NEAR_TOWERS] \
		+ '(%s)->.wide; .wide out geom %d;' % [_tower_selectors(around), CAP_TOWER_CANDIDATES] \
		+ '(way["building:part"]%s;relation["building:part"]["type"="multipolygon"]%s;);out geom %d;' \
			% [near, near, CAP_NEAR_PARTS] \
		+ '(way["building:part"]%s;relation["building:part"]["type"="multipolygon"]%s;);out geom %d;' \
			% [around, around, CAP_TOWER_PARTS]

func cancel() -> void:
	_gen += 1
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
	if cached != "":
		_parse_off_thread(cached, true)
		return
	_request()

func _request() -> void:
	if offline_mode:
		_fallback("offline")
		return
	_req.run("data=" + build_query(_lat, _lon).uri_encode(),
		func(text: String) -> String: return "" if _usable(text) else "unusable payload",
		endpoints())

func _on_answered(text: String) -> void:
	OsmFetcher._write_cache(_cache, text)
	_parse_off_thread(text, false)

## Older payloads are usable offline, but never prevent a live refresh of
## the new query when the network is available.
func _fallback(reason: String) -> void:
	for old_path in [cache_path(_lat, _lon).replace("_q%d.json" % QUERY_VERSION, "_q%d.json" % (QUERY_VERSION - 1)),
			legacy_cache_path(_lat, _lon)]:
		var old := OsmFetcher._read_cache(old_path)
		if old != "" and _usable(old):
			print("FarCityFetcher: %s; using older far-city cache" % reason)
			_parse_off_thread(old, true)
			return
	print("FarCityFetcher: %s; far city from imagery only" % reason)
	_emit(0, false, parse("", _lat, _lon))

static func _usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and (parsed as Dictionary).get("elements", null) is Array

## A city's payload (~10 MB) takes ~0.3 s to check and parse: on a
## worker, so the loading screen keeps drawing. A cached payload that is
## not usable comes back empty and the network is asked instead.
func _parse_off_thread(text: String, cached: bool) -> void:
	_join_parse()
	var gen := _gen
	var lat := _lat
	var lon := _lon
	_parse_task = WorkerThreadPool.add_task(func() -> void:
		var parsed := parse(text, lat, lon) if not cached or _usable(text) else {}
		_on_parsed.call_deferred(gen, text.length(), cached, parsed))

func _join_parse() -> void:
	if _parse_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_parse_task)
		_parse_task = -1

## A stale parse returns before joining: the task id may already be a
## newer parse's (the next _parse_off_thread joined this one).
func _on_parsed(gen: int, bytes: int, cached: bool, parsed: Dictionary) -> void:
	if gen != _gen:
		return
	_join_parse()
	if parsed.is_empty():
		_request()
		return
	_emit(bytes, cached, parsed)

func _emit(bytes: int, cached: bool, parsed: Dictionary) -> void:
	timings = {"ms": Time.get_ticks_msec() - _t0, "bytes": bytes,
		"cached": cached, "landuse": (parsed["landuse"] as Array).size(),
		"towers": (parsed["towers"] as Array).size()}
	_busy = false
	finished.emit(parsed["landuse"], parsed["towers"])

## {landuse, towers} in metre XZ around (c_lat, c_lon). Tall outlines
## retain their own roofs and their mapped parts, including relation rings.
static func parse(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var landuse: Array = []
	var towers: Array = []
	var part_ways: Array = []
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
		if str(tags.get("building", "")) == "construction" or str(tags.get("building:part", "")) == "construction":
			continue
		var lu := str(tags.get("landuse", ""))
		var rings := _rings(el, c_lat, c_lon)
		for ring_data in rings:
			var pts: PackedVector2Array = ring_data[0]
			var holes: Array = ring_data[1]
			var box := RingGeometry.aabb(pts)
			if tags.has("building:part") and not tags.has("building"):
				part_ways.append({"tags": tags, "points": pts, "aabb": box, "holes": holes})
			elif tags.has("building"):
				var tower := OsmTags._building_entry(tags, pts, box)
				tower["holes"] = holes
				towers.append(tower)
			elif lu != "":
				landuse.append({"class": lu, "points": pts, "holes": holes})
	# Match before applying the tower cap: a low podium can own a tall
	# crown, and selecting by its own height would discard the parent.
	_nest_parts(towers, part_ways)
	towers = select_towers(towers, CAP_TOWERS)
	return {"landuse": landuse, "towers": towers}

static func _rings(el: Dictionary, c_lat: float, c_lon: float) -> Array:
	var out: Array = []
	if str(el.get("type", "")) == "relation":
		var members: Array = el.get("members", [])
		var outer := OsmFetcher._join_rings(OsmFetcher._member_segments(members, true, c_lat, c_lon))
		var inner := OsmFetcher._join_rings(OsmFetcher._member_segments(members, false, c_lat, c_lon))
		for ring in outer:
			var holes: Array = []
			for hole in inner:
				if (hole as PackedVector2Array).size() > 0 and (outer.size() == 1 or OsmFetcher._point_in_ring(hole[0], ring)):
					holes.append(hole)
			out.append([ring, holes])
		return out
	var pts := PackedVector2Array()
	for node in el.get("geometry", []):
		if node is Dictionary:
			pts.append(WorldScale.xz_from_latlon(float(node.get("lat", c_lat)),
				float(node.get("lon", c_lon)), c_lat, c_lon))
	if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.01:
		pts.remove_at(pts.size() - 1)
	if pts.size() >= 3:
		out.append([pts, []])
	return out

## Approximate angular prominence; deterministic ties do not depend on OSM id.
static func select_towers(input: Array, cap: int) -> Array:
	var sorted := input.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := Vector2(float(a["x"]), float(a["z"])).length()
		var db := Vector2(float(b["x"]), float(b["z"])).length()
		var sa := _tower_height(a) / sqrt(1.0 + da / 1000.0)
		var sb := _tower_height(b) / sqrt(1.0 + db / 1000.0)
		if not is_equal_approx(sa, sb):
			return sa > sb
		if not is_equal_approx(da, db):
			return da < db
		return float(a["x"]) < float(b["x"]))
	return sorted.slice(0, maxi(0, cap))

## A low mapped podium may carry the tower as a tall building:part.
static func _tower_height(tower: Dictionary) -> float:
	var h := float(tower.get("height", 0.0))
	for part in tower.get("parts", []):
		h = maxf(h, float((part as Dictionary).get("height", 0.0)))
	return h

## Spatial bins bound parent lookup in dense skylines, unlike comparing
## every part with every tower in the 12 km disc.
static func _nest_parts(towers: Array, parts: Array) -> void:
	var cells := {}
	var cell_m := 200.0
	for i in towers.size():
		var box := RingGeometry.aabb(towers[i]["footprint"])
		var lo := Vector2i(floori(box.position.x / cell_m), floori(box.position.y / cell_m))
		var hi := Vector2i(floori(box.end.x / cell_m), floori(box.end.y / cell_m))
		for x in range(lo.x, hi.x + 1):
			for z in range(lo.y, hi.y + 1):
				var key := Vector2i(x, z)
				if not cells.has(key):
					cells[key] = []
				cells[key].append(i)
	for p in parts:
		var pts: PackedVector2Array = p["points"]
		var box: Rect2 = p["aabb"]
		var centre := OsmFetcher._polygon_centroid(pts, box.get_center())
		var cell := Vector2i(floori(centre.x / cell_m), floori(centre.y / cell_m))
		var best := -1
		var best_area := INF
		for i in cells.get(cell, []):
			var parent: Dictionary = towers[i]
			var fp: PackedVector2Array = parent["footprint"]
			var area := absf(RingGeometry.signed_area(fp))
			if area < best_area and OsmFetcher._point_in_ring(centre, fp):
				best = i
				best_area = area
		if best >= 0:
			var parent: Dictionary = towers[best]
			var entry := OsmTags._building_entry(p["tags"], pts, box)
			if str(entry["height_source"]) == "default":
				entry["height"] = parent["height"]
				entry["height_source"] = parent["height_source"]
			entry["holes"] = p["holes"]
			(parent["parts"] as Array).append(entry)
		else:
			var orphan := OsmTags._building_entry(p["tags"], pts, box)
			if float(orphan["height"]) >= TOWER_MIN_M:
				orphan["min_height_m"] = 0.0
				orphan["min_level"] = 0
				orphan["holes"] = p["holes"]
				towers.append(orphan)
