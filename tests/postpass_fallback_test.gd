extends SceneTree

## Offline test of the Postpass fallback: the SQL body, GeoJSON→Overpass
## JSON conversion, the parser reading the converted payload, and the
## RemoteConfig override (never touches the network).
## godot --headless --script tests/postpass_fallback_test.gd

const LAT := 60.1680
const LON := 24.9530

## Shapes as Postpass answers them: ways as one-part Multi* geometries,
## an area relation as an assembled MultiPolygon without its `type` tag.
const GEOJSON := """{"postpass_properties": {"generator": "Postpass API 0.2"},
"type": "FeatureCollection", "features": [
{"type": "Feature", "geometry": {"type": "Point", "coordinates": [24.9531, 60.1681]},
 "properties": {"osm_type": "N", "osm_id": 5, "tags": {"natural": "tree"}}},
{"type": "Feature", "geometry": {"type": "MultiPolygon", "coordinates": [[[[24.9530, 60.1680],
 [24.9534, 60.1680], [24.9534, 60.1682], [24.9530, 60.1682], [24.9530, 60.1680]]]]},
 "properties": {"osm_type": "W", "osm_id": 10, "tags": {"building": "apartments", "building:levels": "5"}}},
{"type": "Feature", "geometry": {"type": "MultiLineString", "coordinates": [[[24.9520, 60.1675],
 [24.9540, 60.1675]]]},
 "properties": {"osm_type": "W", "osm_id": 11, "tags": {"highway": "residential"}}},
{"type": "Feature", "geometry": {"type": "MultiPolygon", "coordinates": [[[[24.9540, 60.1690],
 [24.9550, 60.1690], [24.9550, 60.1696], [24.9540, 60.1696], [24.9540, 60.1690]],
 [[24.9543, 60.1692], [24.9547, 60.1692], [24.9547, 60.1694], [24.9543, 60.1692]]]]},
 "properties": {"osm_type": "R", "osm_id": 20, "tags": {"building": "yes", "height": "21"}}},
{"type": "Feature", "geometry": {"type": "MultiLineString", "coordinates": [[[24.95, 60.16], [24.96, 60.17]]]},
 "properties": {"osm_type": "R", "osm_id": 21, "tags": {"route": "bus"}}},
{"type": "Feature", "geometry": {"type": "MultiPolygon", "coordinates": [[[[24.9520, 60.1670],
 [24.9524, 60.1670], [24.9524, 60.1672], [24.9520, 60.1670]]]]},
 "properties": {"osm_type": "W", "osm_id": 12, "tags": {"building": "no"}}},
{"type": "Feature", "geometry": {"type": "Point", "coordinates": [24.95, 60.16]},
 "properties": {"osm_type": "N", "osm_id": 6, "tags": {}}},
{"type": "Feature", "geometry": {"type": "Point", "coordinates": [24.953, 60.168]},
 "properties": {"osm_type": "R", "osm_id": 54224, "tags": {"admin_level": "2", "ISO3166-1": "FI", "name": "Suomi / Finland"}}}
]}"""

## No buildings, only a lake: a shore answer the fallbacks must keep.
const LAKE_ONLY := """{"type": "FeatureCollection", "features": [
{"type": "Feature", "geometry": {"type": "MultiPolygon", "coordinates": [[[[24.950, 60.166],
 [24.956, 60.166], [24.956, 60.170], [24.950, 60.170], [24.950, 60.166]]]]},
 "properties": {"osm_type": "W", "osm_id": 30, "tags": {"natural": "water", "water": "lake"}}}
]}"""

func _init() -> void:
	var failures: Array[String] = []
	_body_checks(failures)
	_convert_checks(failures)
	_garbage_checks(failures)
	_config_checks(failures)
	if failures.is_empty():
		print("POSTPASS FALLBACK OK: sql body, geojson convert, parser, remote config")
		quit(0)
	else:
		for f in failures:
			printerr("POSTPASS FALLBACK FAIL: ", f)
		quit(1)

func _body_checks(failures: Array[String]) -> void:
	var body := PostpassFallback.build_body(LAT, LON, 1200)
	if not body.begins_with("data="):
		failures.append("body must be a data= form field: %s" % body.left(40))
		return
	var sql := body.trim_prefix("data=").uri_decode()
	for needle in ["FROM postpass_pointlinepolygon", "ST_MakePoint(24.953000,60.168000)",
			"::geography, 1200)", "'building:part'", "'natural' = 'tree'", "'tram'",
			"'defensive_works'", "UNION ALL", "ORDER BY geom <->", "'ISO3166-1'",
			"LIMIT %d" % OsmQuery.CAP_TREE_NODES, "LIMIT %d" % OsmQuery.CAP_FURNITURE,
			"::geography, %d)" % OsmQuery.FURNITURE_RADIUS_M, "'lighthouse'"]:
		if not sql.contains(needle):
			failures.append("sql lacks %s" % needle)
	for rail in OsmTags.RAIL_CLASSES:
		if not sql.contains("'%s'" % rail):
			failures.append("sql lacks rail class %s" % rail)
	# Furniture is picked around the preset's eye, not the place.
	var view := PresetViews.for_pin(LAT, LON)
	if view.has("eye_lat") and not sql.contains("ST_MakePoint(%.6f,%.6f)" % [float(view["eye_lon"]), float(view["eye_lat"])]):
		failures.append("furniture should be picked around the eye")
	# 1200 m is ±0.01078° lat and ±0.02156° lon at 60.168°.
	if not sql.contains("ST_MakeEnvelope(24.931") or not sql.contains(",60.157"):
		failures.append("envelope not centred on the place: %s" % sql.get_slice("AND", 0))
	if body.contains(" ") or body.contains("'"):
		failures.append("body is not url-encoded")

func _convert_checks(failures: Array[String]) -> void:
	var res := PostpassFallback.to_overpass_json(GEOJSON.to_utf8_buffer())
	if int(res["buildings"]) != 2:
		failures.append("expected 2 buildings, got %s" % res["buildings"])
	var js: Variant = JSON.parse_string(res["json"])
	if not js is Dictionary:
		failures.append("converted payload is not a JSON object")
		return
	var by_key := {}
	for el in js["elements"]:
		by_key[str(el["type"]) + ":" + str(int(el["id"]))] = el
	for key in ["node:5", "way:10", "way:11", "way:12", "relation:20", "area:3600054224"]:
		if not by_key.has(key):
			failures.append("missing %s" % key)
	for key in ["relation:21", "node:6"]:
		if by_key.has(key):
			failures.append("%s should be left out" % key)
	if failures.size() > 0:
		return
	var tree: Dictionary = by_key["node:5"]
	if absf(float(tree["lat"]) - 60.1681) > 1e-6 or absf(float(tree["lon"]) - 24.9531) > 1e-6:
		failures.append("node lat/lon swapped or lost: %s" % tree)
	var house: Dictionary = by_key["way:10"]
	if (house["geometry"] as Array).size() != 5 or absf(float(house["geometry"][1]["lon"]) - 24.9534) > 1e-6:
		failures.append("building way should keep its closed outer ring")
	if (by_key["way:11"]["geometry"] as Array).size() != 2:
		failures.append("road way should keep its line")
	var rel: Dictionary = by_key["relation:20"]
	if str(rel["tags"].get("type", "")) != "multipolygon":
		failures.append("area relation needs type=multipolygon")
	var roles: Array = (rel["members"] as Array).map(func(m: Dictionary) -> String: return str(m["role"]))
	if roles != ["outer", "inner"]:
		failures.append("relation roles wrong: %s" % [roles])
	var parsed := OsmFetcher.parse_features(res["json"], LAT, LON)
	if (parsed["buildings"] as Array).size() != 2:
		failures.append("parser should read 2 buildings, got %d" % (parsed["buildings"] as Array).size())
	if (parsed["roads"] as Array).is_empty():
		failures.append("parser read no roads")
	if (parsed["trees"] as Array).is_empty():
		failures.append("parser read no trees")
	if str(parsed["country"]) != "FI":
		failures.append("country lookup should give FI, got %s" % parsed["country"])
	var lake := OsmFetcher._with_shores(PostpassFallback.to_overpass_json(LAKE_ONLY.to_utf8_buffer()), LAT, LON)
	if int(lake["buildings"]) != 0 or not lake["shores"]:
		failures.append("a lake-only answer should count as shore data: %s" % [lake.get("shores")])
	var with_houses := OsmFetcher._with_shores(res.duplicate(), LAT, LON)
	if with_houses["shores"]:
		failures.append("an answer with buildings needs no shore check")
	var empty := OsmFetcher._with_shores(PostpassFallback.to_overpass_json("".to_utf8_buffer()), LAT, LON)
	if empty["shores"]:
		failures.append("an unreadable answer has no shores")

func _garbage_checks(failures: Array[String]) -> void:
	for raw in ["", "pq: relation \"nowhere\" does not exist", "[]", "{\"features\": 3}"]:
		var res := PostpassFallback.to_overpass_json((raw as String).to_utf8_buffer())
		if int(res["buildings"]) != 0:
			failures.append("garbage answer %s should give no buildings" % raw)

func _config_checks(failures: Array[String]) -> void:
	RemoteConfig.clear()
	if PostpassFallback.endpoint() != PostpassFallback.URL:
		failures.append("default endpoint should be the built-in URL")
	RemoteConfig.apply({"version": 1, "postpass_endpoint": "https://postpass.example.org/api/interpreter"})
	if PostpassFallback.endpoint() != "https://postpass.example.org/api/interpreter":
		failures.append("remote config should replace the endpoint")
	RemoteConfig.apply({"version": 1, "postpass_endpoint": "https://postpass.example.ru/api/interpreter"})
	if PostpassFallback.endpoint() != PostpassFallback.URL:
		failures.append("a Russian host must not replace the endpoint")
	RemoteConfig.apply({"version": 1, "postpass_endpoint": "http://postpass.example.org/"})
	if PostpassFallback.endpoint() != PostpassFallback.URL:
		failures.append("a non-https endpoint must be ignored")
	RemoteConfig.clear()
