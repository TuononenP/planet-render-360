class_name HorizonFetcher
extends Node

## Names for the skyline (HorizonLabels): the named peaks, towns and
## lakes around a place, from ONE aggregated Overpass request per place
## (register rate discipline), cached, best-effort, asked for only when
## the person turns horizon labels on:
##  - natural=peak with a name (and its ele), to RADIUS_PEAK_M;
##  - place=city|town|village with a name, to RADIUS_TOWN_M;
##  - natural=water lake / reservoir with a name, to RADIUS_LAKE_M.
## Absence is graceful: a failed or uncached fetch emits an empty list
## and the view simply has no labels.

signal finished(sites: Array)
signal failed

const RADIUS_PEAK_M := 45000
const RADIUS_TOWN_M := 30000
const RADIUS_LAKE_M := 20000
const CAP := 1500
const ATTEMPT_TIMEOUT := 40.0

var offline_mode := false

var _req: OverpassRequest
var _busy := false
var _lat := 0.0
var _lon := 0.0
var _cache := ""

func _ready() -> void:
	_req = OverpassRequest.new(ATTEMPT_TIMEOUT)
	add_child(_req)
	_req.answered.connect(_on_answered)
	_req.exhausted.connect(func(reason: String, _attempts: int) -> void:
		print("HorizonFetcher: %s; no horizon labels" % reason)
		_emit("")
		failed.emit())

## Main instance first, like the far-city query: no mirror answers
## (2026-11-11, see OsmFetcher.ENDPOINTS).
static func endpoints() -> Array[String]:
	return OsmFetcher.endpoint_order(["//overpass-api.de",
		"private.coffee", "z.overpass-api.de"]).slice(0, 4)

func is_busy() -> bool:
	return _busy

static func cache_path(lat: float, lon: float) -> String:
	# osm_v* prefix: accounted in the osm cache layer (CacheStore.layer_of).
	return "%s/osm_v%d_%d_%d_horizon%d.json" % [CacheStore.base_dir(),
		CacheStore.DATA_VERSION, CacheStore.quant(lat), CacheStore.quant(lon), RADIUS_PEAK_M]

static func build_query(lat: float, lon: float) -> String:
	return "[out:json][timeout:%d];(" % OsmFetcher.OVERPASS_TIMEOUT_S \
		+ 'node["natural"="peak"]["name"](around:%d,%.6f,%.6f);' % [RADIUS_PEAK_M, lat, lon] \
		+ 'node["place"~"^(city|town|village)$"]["name"](around:%d,%.6f,%.6f);' \
			% [RADIUS_TOWN_M, lat, lon] \
		+ 'nwr["natural"="water"]["water"~"^(lake|reservoir)$"]["name"](around:%d,%.6f,%.6f);' \
			% [RADIUS_LAKE_M, lat, lon] \
		+ ");out tags center %d;" % CAP

func cancel() -> void:
	if _req != null:
		_req.cancel()
	_busy = false

func fetch(lat: float, lon: float) -> void:
	cancel()
	_lat = lat
	_lon = lon
	_cache = cache_path(lat, lon)
	_busy = true
	var cached := OsmFetcher._read_cache(_cache)
	if cached != "" and _usable(cached):
		_emit(cached)
		return
	if offline_mode:
		_emit("")
		return
	_req.run("data=" + build_query(lat, lon).uri_encode(),
		func(text: String) -> String: return "" if _usable(text) else "unusable payload",
		endpoints())

func _on_answered(text: String) -> void:
	OsmFetcher._write_cache(_cache, text)
	_emit(text)

static func _usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and (parsed as Dictionary).get("elements", null) is Array

func _emit(text: String) -> void:
	_busy = false
	finished.emit(parse(text))

## Sites {name, kind (Peak|City|Town|Village|Lake), lat, lon, ele_m
## (-1 unknown)} from an Overpass payload; unnamed or duplicate rows
## (same kind and name within ~1 km) are dropped.
static func parse(text: String) -> Array:
	var out: Array = []
	var parsed: Variant = JSON.parse_string(text) if text.strip_edges().begins_with("{") else null
	if not (parsed is Dictionary):
		return out
	var seen := {}
	for el in (parsed as Dictionary).get("elements", []):
		if not (el is Dictionary):
			continue
		var raw_tags: Variant = el.get("tags", {})
		var tags: Dictionary = raw_tags if raw_tags is Dictionary else {}
		var name := str(tags.get("name", "")).strip_edges()
		var kind := kind_of(tags)
		if name == "" or kind == "":
			continue
		var lat := float(el.get("lat", 0.0))
		var lon := float(el.get("lon", 0.0))
		if not el.has("lat") and el.get("center") is Dictionary:
			lat = float((el["center"] as Dictionary).get("lat", 0.0))
			lon = float((el["center"] as Dictionary).get("lon", 0.0))
		elif not el.has("lat"):
			continue
		var key := "%s|%s|%d|%d" % [kind, name, roundi(lat * 100.0), roundi(lon * 100.0)]
		if seen.has(key):
			continue
		seen[key] = true
		out.append({"name": name, "kind": kind, "lat": lat, "lon": lon,
			"ele_m": parse_ele(str(tags.get("ele", "")))})
	return out

static func kind_of(tags: Dictionary) -> String:
	if str(tags.get("natural", "")) == "peak":
		return "Peak"
	match str(tags.get("place", "")):
		"city":
			return "City"
		"town":
			return "Town"
		"village":
			return "Village"
	if str(tags.get("natural", "")) == "water" and str(tags.get("water", "")) in ["lake", "reservoir"]:
		return "Lake"
	return ""

## "3967", "3 967", "1,200.5 m", "4000;4010" -> metres, -1 when unreadable.
static func parse_ele(raw: String) -> float:
	var s := raw.split(";")[0].replace(" ", "").replace("m", "").replace("M", "")
	# "1,200.5" groups thousands; "1200,5" is a decimal comma.
	s = s.replace(",", "") if s.contains(".") else s.replace(",", ".")
	return s.to_float() if s.is_valid_float() else -1.0
