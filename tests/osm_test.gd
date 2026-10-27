extends SceneTree

## Focused parser test (offline): godot --headless --script tests/osm_test.gd
## Feeds a recorded-shape Overpass JSON through OsmFetcher.parse_features.

const FIXTURE := """
{"elements":[
 {"type":"way","tags":{"building":"yes","building:levels":"5","name":"Test Hall"},
  "geometry":[{"lat":48.8570,"lon":2.3520},{"lat":48.8570,"lon":2.3530},
              {"lat":48.8566,"lon":2.3530},{"lat":48.8566,"lon":2.3520}]},
 {"type":"way","tags":{"highway":"primary","name":"Rue Test"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8570,"lon":2.3540}]},
 {"type":"way","tags":{"landuse":"forest"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8560,"lon":2.3540},
              {"lat":48.8570,"lon":2.3540},{"lat":48.8560,"lon":2.3510}]},
 {"type":"way","tags":{"natural":"water"},
  "geometry":[{"lat":48.8590,"lon":2.3510},{"lat":48.8590,"lon":2.3540},
              {"lat":48.8600,"lon":2.3540},{"lat":48.8590,"lon":2.3510}]},
 {"type":"node","tags":{"name":"No geometry"},"lat":48.8566,"lon":2.3522}
]}
"""

func _init() -> void:
	var failures: Array[String] = []
	var result := OsmFetcher.parse_features(FIXTURE, 48.8566, 2.3522)
	var buildings: Array = result["buildings"]
	var roads: Array = result["roads"]
	if buildings.size() != 1:
		failures.append("expected 1 building, got %d" % buildings.size())
	else:
		var b: Dictionary = buildings[0]
		if str(b["name"]) != "Test Hall":
			failures.append("building name lost: %s" % b)
		if absf(float(b["height"]) - 16.0) > 0.01:
			failures.append("levels->height wrong: %s" % b["height"])
		if float(b["size_x"]) < 3.0 or float(b["size_z"]) < 3.0:
			failures.append("building footprint too small: %s" % b)
	if roads.size() != 1 or (roads[0] as PackedVector2Array).size() != 2:
		failures.append("expected 1 road with 2 points, got %s" % [roads])
	var land: Array = result["land"]
	if land.size() != 2:
		failures.append("expected 2 land polygons, got %d" % land.size())
	else:
		var classes: Array = land.map(func(p: Dictionary) -> String: return str(p["class"]))
		if not classes.has("forest") or not classes.has("water"):
			failures.append("land classes wrong: %s" % [classes])
		var forest_poly: PackedVector2Array = land[0]["points"]
		var centroid := (forest_poly[0] + forest_poly[1] + forest_poly[2]) / 3.0
		if not TerrainBuilder.point_in_polygon(centroid, forest_poly):
			failures.append("point-in-polygon failed at forest centroid")
		if TerrainBuilder.land_color(Vector2(9999, 9999), land, Color.RED) != Color.RED:
			failures.append("land_color must fall back outside polygons")
	var q := OsmFetcher.build_query(48.8566, 2.3522)
	if not q.contains("building") or not q.contains("highway"):
		failures.append("query missing building/highway clauses")

	if failures.is_empty():
		print("OSM OK: parser, levels->height, road polyline, query")
		quit(0)
	else:
		for f in failures:
			printerr("OSM FAIL: ", f)
		quit(1)
