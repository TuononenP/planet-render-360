extends SceneTree

## Vector map tests: godot --headless --script tests/vector_map_test.gd
## Offline: MVT decoding (hand-built fixture: polygon with a hole, a bridge
## road, a peak, mixed tag types, an unwanted layer), truncated input, the
## TileJSON path, gzip inflate, Map style rules, tile building (fills cut
## around holes, cased roads, labels), dashes and the tile cover.

## A 408-byte MVT encoded with mapbox-vector-tile (extent 4096):
## water: lake square 100..1000 with a 400..600 hole; transportation:
## primary bridge (0,2048)-(2048,2048)-(4096,3000) with an extra "oneway";
## mountain_peak: Matterhorn, ele 4478, at (3000,500); housenumber "12";
## poi: Louvre, museum, rank 1, score 2.5 (double), indoor true.
const FIXTURE := [
	26, 69, 10, 5, 119, 97, 116, 101, 114, 18, 40, 18, 2, 0, 0, 24, 3, 34, 32, 9, 200, 1, 200,
	1, 26, 136, 14, 0, 0, 136, 14, 135, 14, 0, 15, 9, 216, 4, 175, 9, 26, 0, 144, 3, 144, 3, 0,
	0, 143, 3, 15, 26, 5, 99, 108, 97, 115, 115, 34, 6, 10, 4, 108, 97, 107, 101, 40, 128, 32,
	120, 2, 26, 96, 10, 14, 116, 114, 97, 110, 115, 112, 111, 114, 116, 97, 116, 105, 111, 110,
	18, 24, 18, 6, 0, 0, 1, 1, 2, 2, 24, 2, 34, 12, 9, 0, 128, 32, 18, 128, 32, 0, 128, 32,
	240, 14, 26, 5, 99, 108, 97, 115, 115, 26, 7, 98, 114, 117, 110, 110, 101, 108, 26, 6, 111,
	110, 101, 119, 97, 121, 34, 9, 10, 7, 112, 114, 105, 109, 97, 114, 121, 34, 8, 10, 6, 98,
	114, 105, 100, 103, 101, 34, 2, 32, 1, 40, 128, 32, 120, 2, 26, 79, 10, 13, 109, 111, 117,
	110, 116, 97, 105, 110, 95, 112, 101, 97, 107, 18, 17, 18, 6, 0, 0, 1, 1, 2, 2, 24, 1, 34,
	5, 9, 240, 46, 232, 7, 26, 4, 110, 97, 109, 101, 26, 3, 101, 108, 101, 26, 4, 114, 97, 110,
	107, 34, 12, 10, 10, 77, 97, 116, 116, 101, 114, 104, 111, 114, 110, 34, 3, 32, 254, 34,
	34, 2, 32, 1, 40, 128, 32, 120, 2, 26, 50, 10, 11, 104, 111, 117, 115, 101, 110, 117, 109,
	98, 101, 114, 18, 11, 18, 2, 0, 0, 24, 1, 34, 3, 9, 20, 20, 26, 11, 104, 111, 117, 115,
	101, 110, 117, 109, 98, 101, 114, 34, 4, 10, 2, 49, 50, 40, 128, 32, 120, 2, 26, 104, 10,
	3, 112, 111, 105, 18, 19, 18, 10, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 24, 1, 34, 3, 9, 100, 120,
	26, 4, 110, 97, 109, 101, 26, 5, 99, 108, 97, 115, 115, 26, 4, 114, 97, 110, 107, 26, 5,
	115, 99, 111, 114, 101, 26, 6, 105, 110, 100, 111, 111, 114, 34, 8, 10, 6, 76, 111, 117,
	118, 114, 101, 34, 8, 10, 6, 109, 117, 115, 101, 117, 109, 34, 2, 32, 1, 34, 9, 25, 0, 0,
	0, 0, 0, 0, 4, 64, 34, 2, 56, 1, 40, 128, 32, 120, 2
]

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var bytes := PackedByteArray(FIXTURE)
	var wanted := {"water": ["class"], "transportation": ["class", "brunnel"],
		"mountain_peak": ["name", "ele"], "poi": ["name", "class", "rank", "score", "indoor"]}
	var tile := MvtReader.read(bytes, wanted)
	if tile.has("housenumber"):
		failures.append("unwanted layer should be skipped")
	for name in wanted:
		if not tile.has(name):
			failures.append("layer %s missing" % name)
	if not failures.is_empty():
		_finish(failures)
		return
	var water: Dictionary = tile["water"]["features"][0]
	var rings: Array = water["geom"][0]
	if int(water["type"]) != MvtReader.POLYGON or rings.size() != 2:
		failures.append("lake should be one polygon with one hole, got %s" % [water["geom"]])
	elif (rings[0] as PackedVector2Array)[1] != Vector2(1000, 100) \
			or (rings[1] as PackedVector2Array)[0] != Vector2(400, 400):
		failures.append("lake rings decoded wrong: %s" % [rings])
	if MvtReader.ring_area(rings[0]) <= 0.0 or MvtReader.ring_area(rings[rings.size() - 1]) >= 0.0:
		failures.append("outer ring should be positive, hole negative")
	if water["tags"] != {"class": "lake"}:
		failures.append("lake tags: %s" % [water["tags"]])
	var road: Dictionary = tile["transportation"]["features"][0]
	var road_line := PackedVector2Array([Vector2(0, 2048), Vector2(2048, 2048), Vector2(4096, 3000)])
	if (road["geom"][0] as PackedVector2Array) != road_line:
		failures.append("road line decoded wrong: %s" % [road["geom"]])
	if road["tags"].has("oneway") or str(road["tags"].get("brunnel", "")) != "bridge":
		failures.append("road tags should keep only class/brunnel: %s" % [road["tags"]])
	var peak: Dictionary = tile["mountain_peak"]["features"][0]
	if int(peak["tags"].get("ele", 0)) != 4478 \
			or (peak["geom"][0] as PackedVector2Array)[0] != Vector2(3000, 500):
		failures.append("peak decoded wrong: %s" % [peak])
	var poi: Dictionary = tile["poi"]["features"][0]["tags"]
	if absf(float(poi.get("score", 0.0)) - 2.5) > 1e-9 or poi.get("indoor") != true \
			or int(poi.get("rank", 0)) != 1:
		failures.append("double/bool/int values decoded wrong: %s" % [poi])
	# A truncated or corrupt cache file must end, not hang a worker thread.
	for cut in [7, 41, 200, 300]:
		MvtReader.read(bytes.slice(0, cut), wanted)
	var junk := PackedByteArray()
	junk.resize(64)
	junk.fill(0xff)
	MvtReader.read(junk, wanted)

	var tilejson := '{"tiles": ["https://tiles.openfreemap.org/planet/20261025_080012_pt/{z}/{x}/{y}.pbf"]}'
	var path := VectorTileFetcher.tiles_path_from_tilejson(tilejson)
	if path != "/planet/20261025_080012_pt/%d/%d/%d.pbf":
		failures.append("TileJSON path: %s" % path)
	if VectorTileFetcher.tiles_path_from_tilejson("{}") != "" \
			or VectorTileFetcher.tiles_path_from_tilejson("nope") != "":
		failures.append("bad TileJSON should give an empty path")
	if VectorTileFetcher.inflate(bytes.compress(FileAccess.COMPRESSION_GZIP)) != bytes:
		failures.append("gzip body should inflate to the tile")
	if VectorTileFetcher.inflate(bytes) != bytes:
		failures.append("a plain body should pass through inflate")

	var primary: Array = MapStyle.ROADS[5][2]
	if absf(MapStyle.width(primary, 14.0) - 4.5) > 1e-4 or MapStyle.width(primary, 3.0) != 0.6:
		failures.append("primary width stops")
	if MapStyle.width(primary, 12.0) >= MapStyle.width(primary, 13.0):
		failures.append("road width should grow with zoom")
	if MapStyle.group_thousands(4478) != "4,478" or MapStyle.group_thousands(-430) != "-430" \
			or MapStyle.group_thousands(1234567) != "1,234,567":
		failures.append("thousands grouping")
	if not MapStyle.label_for("place", {"class": "country", "rank": 5, "name": "Andorra"}, 4.0).is_empty():
		failures.append("small countries should wait for zoom 5")
	var france := MapStyle.label_for("place", {"class": "country", "rank": 1, "name:en": "France", "name": "France"}, 4.0)
	if france.get("text") != "FRANCE":
		failures.append("country labels are upper case, English name first")
	if MapStyle.label_for("mountain_peak", {"name": "Matterhorn", "ele": 4478}, 9.0).get("sub") != "4,478 m":
		failures.append("peaks carry their elevation")
	if not MapStyle.lines_for("boundary", {"admin_level": 2, "maritime": 1}, 6.0, MapStyle.NIGHT).is_empty():
		failures.append("maritime borders are not drawn")
	var cased := MapStyle.lines_for("transportation", {"class": "primary"}, 13.0, MapStyle.NIGHT)
	if cased.size() != 2 or float(cased[1][0]) >= float(cased[0][0]) \
			or float(cased[1][2]) <= float(cased[0][2]):
		failures.append("cased roads: casing under and wider than the fill, got %s" % [cased])
	if not MapStyle.lines_for("transportation", {"class": "minor"}, 11.0, MapStyle.NIGHT).is_empty():
		failures.append("minor streets wait for zoom 12")

	var built := VectorTileBuilder.build(tile, 13.0, MapStyle.NIGHT, 512.0)
	var fills: Array = built["fills"]
	if fills.size() != 1 or (fills[0]["indices"] as PackedInt32Array).size() != 8 * 3:
		# A square with a square hole bridged into one ring: 8 triangles.
		failures.append("lake should triangulate to 8 triangles around its hole, got %s" % [fills])
	else:
		var pts: PackedVector2Array = fills[0]["points"]
		var idx: PackedInt32Array = fills[0]["indices"]
		for t in idx.size() / 3:
			var c := (pts[idx[t * 3]] + pts[idx[t * 3 + 1]] + pts[idx[t * 3 + 2]]) / 3.0
			if Rect2(50, 50, 25, 25).has_point(c):
				failures.append("a lake triangle covers the island at %s" % c)
				break
	var lines: Array = built["lines"]
	if lines.size() != 2 or float(lines[0]["order"]) < 40.0:
		failures.append("bridge should give casing + fill above surface roads, got %d batches" % lines.size())
	var kinds: Array = (built["labels"] as Array).map(func(l: Dictionary) -> String: return str(l["kind"]))
	if not ("peak" in kinds) or ("landmark" in kinds):
		failures.append("at zoom 13: peak labelled, landmark not yet (zoom 14+): %s" % [kinds])
	var dashes := VectorTileBuilder.dash_segments(
		PackedVector2Array([Vector2.ZERO, Vector2(10, 0), Vector2(10, 10)]), 3.0, 2.0)
	if dashes.size() % 2 != 0 or dashes.size() < 6 or not dashes[0].is_equal_approx(Vector2.ZERO) \
			or not dashes[1].is_equal_approx(Vector2(3, 0)):
		failures.append("dash pattern: %s" % [dashes])

	var cover := VectorMapLayer.tiles_for(Vector2(1000, 1000), Vector2(1280, 800), 6)
	if VectorMapLayer.data_zoom(6) != 5 or cover.is_empty() or (cover[0] as Vector3i).x != 5:
		failures.append("zoom 6 shows data zoom 5")
	elif cover.size() != 12:
		failures.append("1280x800 at (1000,1000) needs 4x3 512px tiles, got %d" % cover.size())
	elif cover[0] != Vector3i(5, 3, 2):
		failures.append("the tile under the view centre comes first, got %s" % cover[0])
	if VectorMapLayer.data_zoom(15) != 14 or VectorMapLayer.data_zoom(16) != 14:
		failures.append("data zoom caps at 14 (overzoom past it)")
	_finish(failures)

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("VECTOR_MAP OK: MVT decode, truncation, TileJSON, inflate, style rules, build, dashes, cover")
		quit(0)
	else:
		for f in failures:
			printerr("VECTOR_MAP FAIL: ", f)
		quit(1)
