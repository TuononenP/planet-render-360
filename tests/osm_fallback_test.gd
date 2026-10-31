extends SceneTree

## Offline test of the Overpass fallbacks: OSM API bbox URL + XML→Overpass
## JSON conversion, nearby-cache lookup, and the fetcher's cache fallback
## order (never touches the network).
## godot --headless --script tests/osm_fallback_test.gd

const LAT := 48.8566
const LON := 2.3522

const API_XML := """<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6">
 <bounds minlat="48.85" minlon="2.34" maxlat="48.86" maxlon="2.36"/>
 <node id="1" lat="48.8566123" lon="2.3522456" version="1"/>
 <node id="2" lat="48.8566123" lon="2.3526456" version="1"/>
 <node id="3" lat="48.8569123" lon="2.3526456" version="1"/>
 <node id="4" lat="48.8569123" lon="2.3522456" version="1"/>
 <node id="5" lat="48.8575" lon="2.3530" version="1">
  <tag k="natural" v="tree"/>
  <tag k="leaf_type" v="broadleaved"/>
 </node>
 <node id="6" lat="48.8580" lon="2.3540" version="1"/>
 <node id="7" lat="48.8580" lon="2.3550" version="1"/>
 <node id="8" lat="48.8590" lon="2.3550" version="1"/>
 <node id="9" lat="48.8590" lon="2.3540" version="1"/>
 <way id="10" version="1">
  <nd ref="1"/><nd ref="2"/><nd ref="3"/><nd ref="4"/><nd ref="1"/>
  <tag k="building" v="apartments"/>
  <tag k="building:levels" v="5"/>
 </way>
 <way id="11" version="1">
  <nd ref="6"/><nd ref="7"/><nd ref="8"/>
 </way>
 <way id="12" version="1">
  <nd ref="8"/><nd ref="9"/><nd ref="6"/><nd ref="999"/>
 </way>
 <relation id="20" version="1">
  <member type="way" ref="11" role="outer"/>
  <member type="way" ref="12" role="outer"/>
  <member type="node" ref="5" role="label"/>
  <tag k="type" v="multipolygon"/>
  <tag k="natural" v="water"/>
 </relation>
 <relation id="21" version="1">
  <member type="way" ref="10" role=""/>
  <tag k="type" v="route"/>
  <tag k="route" v="bus"/>
 </relation>
</osm>"""

## Nothing here is a usable building: building=no, a way with two
## resolved nodes, and a building relation whose members have no geometry.
const EMPTY_XML := """<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6">
 <node id="1" lat="48.8566" lon="2.3522"/>
 <node id="2" lat="48.8566" lon="2.3526"/>
 <node id="3" lat="48.8569" lon="2.3526"/>
 <way id="10"><nd ref="1"/><nd ref="2"/><nd ref="3"/><nd ref="1"/>
  <tag k="building" v="no"/></way>
 <way id="11"><nd ref="1"/><nd ref="2"/><tag k="building" v="yes"/></way>
 <relation id="20">
  <member type="way" ref="900" role="outer"/>
  <tag k="type" v="multipolygon"/><tag k="building" v="yes"/>
 </relation>
</osm>"""

const CACHED_PAYLOAD := """{"elements":[
 {"type":"way","id":1,"tags":{"building":"yes"},
  "geometry":[{"lat":48.8566,"lon":2.3522},{"lat":48.8566,"lon":2.3526},
              {"lat":48.8569,"lon":2.3526},{"lat":48.8566,"lon":2.3522}]}]}"""

var _ok := false
var _failed_reason := ""
var _detail := ""
var _partial := false

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	_url_checks(failures)
	_convert_checks(failures)
	_nearby_checks(failures)
	_api_checks(failures)
	await _fallback_flow_checks(failures)
	if failures.is_empty():
		print("OSM FALLBACK OK: api url, xml convert, nearby cache, cache fallback order")
		quit(0)
	else:
		for f in failures:
			printerr("OSM FALLBACK FAIL: ", f)
		quit(1)

func _url_checks(failures: Array[String]) -> void:
	var url := OsmApiFallback.url_for(LAT, LON, 1200)
	if not url.begins_with("https://api.openstreetmap.org/api/0.6/map?bbox="):
		failures.append("bbox url wrong: %s" % url)
	var box := url.get_slice("bbox=", 1).split(",")
	if box.size() != 4:
		failures.append("bbox needs 4 numbers: %s" % url)
		return
	# bbox order is left,bottom,right,top; 1200 m is ±0.01078° lat and
	# ±0.01638° lon at 48.8566°.
	var d_lat := (float(box[3]) - float(box[1])) / 2.0
	var d_lon := (float(box[2]) - float(box[0])) / 2.0
	if absf(d_lat - 0.010780) > 0.00005 or absf(d_lon - 0.016380) > 0.0001:
		failures.append("bbox half-widths wrong: lat %f lon %f" % [d_lat, d_lon])
	if absf((float(box[0]) + float(box[2])) / 2.0 - LON) > 0.000001:
		failures.append("bbox not centred on lon")
	if OsmApiFallback.RADII_M[0] != OsmFetcher.DETAILED_RADIUS_M:
		failures.append("first API radius should match the detailed radius")
	for i in OsmApiFallback.RADII_M.size() - 1:
		if OsmApiFallback.RADII_M[i + 1] >= OsmApiFallback.RADII_M[i]:
			failures.append("API radii must shrink")

func _convert_checks(failures: Array[String]) -> void:
	var res := OsmApiFallback.to_overpass_json(API_XML.to_utf8_buffer())
	if int(res["buildings"]) != 1:
		failures.append("expected 1 building, got %s" % res["buildings"])
	var js: Variant = JSON.parse_string(res["json"])
	if not (js is Dictionary):
		failures.append("converted payload is not a JSON object")
		return
	var types := {}
	for el in js["elements"]:
		types[str(el["type"]) + ":" + str(int(el["id"]))] = el
	# Untagged ways, the route relation and untagged nodes are not emitted.
	for key in ["way:11", "way:12", "relation:21", "node:1"]:
		if types.has(key):
			failures.append("%s must not be emitted" % key)
	for key in ["way:10", "node:5", "relation:20"]:
		if not types.has(key):
			failures.append("%s missing from converted payload" % key)
	if not types.has("way:10"):
		return
	var g: Array = types["way:10"]["geometry"]
	if g.size() != 5 or absf(float(g[0]["lat"]) - 48.8566123) > 1e-9 \
			or absf(float(g[0]["lon"]) - 2.3522456) > 1e-9:
		failures.append("way geometry lost precision or nodes: %s" % [g])
	# Relation members carry geometry; the unknown node 999 is skipped.
	var members: Array = types["relation:20"]["members"]
	if members.size() != 2 or (members[0]["geometry"] as Array).size() != 3 \
			or (members[1]["geometry"] as Array).size() != 3:
		failures.append("relation members wrong: %s" % [members])
	# The existing parser consumes the converted payload unchanged.
	var parsed := OsmParser.parse_features(res["json"], LAT, LON)
	if (parsed["buildings"] as Array).size() != 1:
		failures.append("parser saw %d buildings" % (parsed["buildings"] as Array).size())
	if (parsed["trees"] as Array).size() != 1:
		failures.append("parser saw %d trees" % (parsed["trees"] as Array).size())
	var water := 0
	for l in parsed["land"]:
		if str(l["class"]) == "water":
			water += 1
	if water != 1:
		failures.append("parser saw %d water polygons, expected the stitched relation" % water)
	if int(OsmApiFallback.to_overpass_json(PackedByteArray())["buildings"]) != 0:
		failures.append("empty body must convert to zero buildings")

func _api_checks(failures: Array[String]) -> void:
	if int(OsmApiFallback.to_overpass_json(EMPTY_XML.to_utf8_buffer())["buildings"]) != 0:
		failures.append("building=no, 2-node ways and geometry-less relations are not buildings")
	for code in [400, 429, 509]:
		if not OsmApiFallback.steps_down(HTTPRequest.RESULT_SUCCESS, code):
			failures.append("HTTP %d must step down to a smaller box" % code)
	for code in [200, 404, 500]:
		if OsmApiFallback.steps_down(HTTPRequest.RESULT_SUCCESS, code):
			failures.append("HTTP %d must not step down" % code)
	if OsmApiFallback.steps_down(HTTPRequest.RESULT_CANT_CONNECT, 400):
		failures.append("a transport error is not an HTTP answer to step down on")
	# The lossy API payload never takes the key a fresh Overpass answer uses.
	var api := CacheStore.osm_api_path(LAT, LON, 1200)
	if api == CacheStore.osm_path(LAT, LON, 1200) or CacheStore.layer_of(api) != "osm":
		failures.append("API cache key must differ from the Overpass key but stay in the osm layer")
	_with_cache_dir({
		"osm_v2_48857_2352_api1200.json": CACHED_PAYLOAD,
		"osm_v2_48857_2352_r800.json": CACHED_PAYLOAD,
	})
	var order := OsmNearbyCache.candidates(LAT, LON, OsmFetcher.SAME_PLACE_M)
	if order.size() != 2 or not order[0].ends_with("_r800.json"):
		failures.append("an Overpass payload goes before an API one at the same spot: %s" % [order])
	var d := OsmNearbyCache.distance_m(order[0], LAT, LON)
	if d < 20.0 or d > 80.0 or OsmNearbyCache.distance_m("osm_v2_1_2_ring1600.json", LAT, LON) >= 0.0:
		failures.append("distance_m wrong: %s" % d)
	CacheStore.dir_override = ""

func _with_cache_dir(files: Dictionary) -> String:
	var dir := "user://osm_fallback_test_cache"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute("%s/%s" % [dir, f])
	for name in files:
		var h := FileAccess.open("%s/%s" % [dir, name], FileAccess.WRITE)
		h.store_string(files[name])
	CacheStore.dir_override = dir
	return dir

func _nearby_checks(failures: Array[String]) -> void:
	# ~330 m north (+0.003°), ~7 km north, and a ring file at the place.
	_with_cache_dir({
		"osm_v2_48857_2352_r800.json": CACHED_PAYLOAD,
		"osm_v2_48860_2352_r1200.json": CACHED_PAYLOAD,
		"osm_v2_48920_2352_r1200.json": CACHED_PAYLOAD,
		"osm_v2_48857_2352_ring1600.json": CACHED_PAYLOAD,
		"osm_v2_25205_55271_farcity12000.json": CACHED_PAYLOAD,
	})
	var same := OsmNearbyCache.candidates(LAT, LON, OsmFetcher.SAME_PLACE_M)
	if same.size() != 1 or not same[0].ends_with("osm_v2_48857_2352_r800.json"):
		failures.append("same-place candidates wrong: %s" % [same])
	var near := OsmNearbyCache.candidates(LAT, LON, OsmFetcher.NEARBY_M)
	if near.size() != 2 or not near[0].ends_with("_r800.json") \
			or not near[1].ends_with("osm_v2_48860_2352_r1200.json"):
		failures.append("nearby candidates must be nearest first, no ring/far/farcity: %s" % [near])
	CacheStore.dir_override = ""

func _run_fetch(files: Dictionary) -> void:
	_with_cache_dir(files)
	_ok = false
	_failed_reason = ""
	_detail = ""
	_partial = false
	var f := OsmFetcher.new()
	root.add_child(f)
	await process_frame
	f.offline_mode = true
	f.succeeded.connect(func(_b, _r, _l, _lm) -> void: _ok = true)
	f.failed.connect(func(reason: String) -> void: _failed_reason = reason)
	f.fallback_used.connect(func(detail: String, partial: bool) -> void:
		_detail = detail
		_partial = partial)
	f.fetch(LAT, LON, 0)
	for i in 600:
		if _ok or _failed_reason != "":
			break
		await process_frame
	f.queue_free()
	CacheStore.dir_override = ""

func _fallback_flow_checks(failures: Array[String]) -> void:
	# Same place cached at a smaller radius: served.
	await _run_fetch({"osm_v2_48857_2352_r800.json": CACHED_PAYLOAD})
	if not _ok:
		failures.append("same-place r800 cache not served (failed: %s)" % _failed_reason)
	if _detail != "Offline copy" or _partial:
		failures.append("a same-place copy is an offline copy, not partial: %s/%s" % [_detail, _partial])
	# Only a neighbour ~330 m away: served after the API step is skipped.
	await _run_fetch({"osm_v2_48860_2352_r1200.json": CACHED_PAYLOAD})
	if not _ok:
		failures.append("nearby cache not served (failed: %s)" % _failed_reason)
	if not _detail.begins_with("Nearby · ") or not _detail.ends_with(" m") or not _partial:
		failures.append("a neighbouring cache must be reported as partial: %s/%s" % [_detail, _partial])
	# Only a far-away entry: fails and names the OSM API step.
	await _run_fetch({"osm_v2_48920_2352_r1200.json": CACHED_PAYLOAD})
	if _ok or not _failed_reason.contains("OSM API"):
		failures.append("far cache must fail via the OSM API step, got ok=%s reason=%s" % [_ok, _failed_reason])
