extends SceneTree

## Railways, squares, underpasses, high-latitude DEM window (offline):
## godot --headless --script tests/rail_square_test.gd
## - Overpass ways parse into filled squares (highway area=yes,
##   place=square) and railway dicts (gauge, street tram, tunnel), and the
##   query carries its mark so older cached payloads are refetched;
## - RoadBuilder fills a square and RailBuilder lays ballast and rails
##   (street tram: rails only), rails standing on the ground;
## - a road under a bridge is cut to the deck's clearance, the bridge's
##   ends stay on their banks;
## - above ~63°N the DEM window and mosaic widen so the terrain still
##   registers instead of stretching.

func _init() -> void:
	_run()

const PAYLOAD := """{"elements": [
 {"type": "way", "id": 1, "tags": {"highway": "pedestrian", "area": "yes", "surface": "sett"},
  "geometry": [{"lat": 60.1700, "lon": 24.9400}, {"lat": 60.1700, "lon": 24.9410},
   {"lat": 60.1705, "lon": 24.9410}, {"lat": 60.1705, "lon": 24.9400}, {"lat": 60.1700, "lon": 24.9400}]},
 {"type": "way", "id": 2, "tags": {"place": "square"},
  "geometry": [{"lat": 60.1690, "lon": 24.9400}, {"lat": 60.1690, "lon": 24.9405},
   {"lat": 60.1693, "lon": 24.9405}, {"lat": 60.1690, "lon": 24.9400}]},
 {"type": "way", "id": 3, "tags": {"railway": "tram", "gauge": "1000"},
  "geometry": [{"lat": 60.1699, "lon": 24.9380}, {"lat": 60.1699, "lon": 24.9420}]},
 {"type": "way", "id": 4, "tags": {"railway": "rail", "gauge": "1524"},
  "geometry": [{"lat": 60.1680, "lon": 24.9380}, {"lat": 60.1720, "lon": 24.9380}]},
 {"type": "way", "id": 5, "tags": {"railway": "subway", "tunnel": "yes"},
  "geometry": [{"lat": 60.1680, "lon": 24.9390}, {"lat": 60.1720, "lon": 24.9390}]},
 {"type": "way", "id": 6, "tags": {"railway": "platform"},
  "geometry": [{"lat": 60.1680, "lon": 24.9391}, {"lat": 60.1720, "lon": 24.9391}]},
 {"type": "way", "id": 7, "tags": {"building": "yes"},
  "geometry": [{"lat": 60.1710, "lon": 24.9430}, {"lat": 60.1710, "lon": 24.9432},
   {"lat": 60.1711, "lon": 24.9432}, {"lat": 60.1710, "lon": 24.9430}]},
 {"type": "MARK", "id": 1}
]}"""

func _run() -> void:
	var failures: Array[String] = []
	_check_parse(failures)
	_check_build(failures)
	_check_underpass(failures)
	_check_window(failures)
	if failures.is_empty():
		print("RAIL SQUARE PASS")
		quit(0)
	else:
		for f in failures:
			printerr("RAIL SQUARE FAIL: ", f)
		quit(1)

func _check_parse(failures: Array[String]) -> void:
	var parsed := OsmParser.parse_features(PAYLOAD, 60.1699, 24.9384)
	var areas := (parsed["roads"] as Array).filter(func(r: Dictionary) -> bool:
		return bool(r.get("area", false)))
	if areas.size() != 2:
		failures.append("expected 2 filled squares, got %d" % areas.size())
	for a in areas:
		var ring: PackedVector2Array = a["points"]
		if ring[0].distance_to(ring[ring.size() - 1]) < 0.01:
			failures.append("square ring keeps its closing vertex")
	var rails: Array = parsed.get("railways", [])
	if rails.size() != 3:
		failures.append("expected 3 railway ways (platform not track), got %d" % rails.size())
	for r in rails:
		match str(r["class"]):
			"tram":
				if not bool(r["embedded"]) or absf(float(r["gauge_m"]) - 1.0) > 0.001:
					failures.append("tram not street track at 1000 mm: %s" % r)
			"rail":
				if bool(r["embedded"]) or absf(float(r["gauge_m"]) - 1.524) > 0.001:
					failures.append("rail not on its bed at 1524 mm: %s" % r)
			"subway":
				if not bool(r["tunnel"]):
					failures.append("subway tunnel not flagged")
	var q := OsmQuery.build_query(60.1699, 24.9384)
	if not q.contains('way["railway"~') or not q.contains('"place"="square"'):
		failures.append("query lacks the railway/square statements")
	# A cached payload carries the query's current mark (MARK above).
	if not OsmQuery.is_current(q) or not OsmQuery.is_current(PAYLOAD.replace("MARK", OsmQuery.QUERY_MARK)) \
			or OsmQuery.is_current('{"elements": []}'):
		failures.append("query mark not recognised")

func _flat(size: int) -> LocationData:
	var d := LocationData.new()
	d.grid_size = size
	d.heights.resize(size * size)
	d.heights.fill(10.0)
	d.water_level = 0.0
	d.quality_preset = 3
	return d

func _check_build(failures: Array[String]) -> void:
	var d := _flat(64)
	var parsed := OsmParser.parse_features(PAYLOAD, 60.1699, 24.9384)
	d.roads = parsed["roads"]
	d.railways = parsed["railways"]
	d.buildings = parsed["buildings"]
	var ground := GroundTruth.new(d)
	var root := RoadBuilder.build_roads(d, ground)
	var names := {}
	for c in root.get_children():
		names[c.name] = c
	for want in ["Rail_ballast", "Rail_rail", "Road_sett"]:
		if not names.has(want):
			failures.append("no %s mesh (got %s)" % [want, names.keys()])
	if names.has("Road_sett"):
		# The square's fill spans its ~55 x 55 m, not a 6 m outline strip.
		var aabb: AABB = (names["Road_sett"] as MeshInstance3D).mesh.get_aabb()
		var verts: PackedVector3Array = (names["Road_sett"] as MeshInstance3D).mesh \
			.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var inner := 0
		var c := Vector2(aabb.get_center().x, aabb.get_center().z)
		for v in verts:
			if Vector2(v.x, v.z).distance_to(c) < aabb.size.x * 0.2:
				inner += 1
		if aabb.size.x < 40.0 * WorldScale.metres_to_units() or inner == 0:
			failures.append("square not filled (aabb %s, %d inner verts)" % [aabb, inner])
	if names.has("Rail_rail"):
		var verts: PackedVector3Array = (names["Rail_rail"] as MeshInstance3D).mesh \
			.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var low := 0
		for v in verts:
			if v.y < ground.height_at_world(v.x, v.z) - 0.01:
				low += 1
		if low > 0:
			failures.append("%d rail vertices under the ground" % low)
	root.free()

func _check_underpass(failures: Array[String]) -> void:
	var d := _flat(256)  # the cut is a post wide: a real 9.4 m grid
	var m2u := WorldScale.metres_to_units()
	var c := Vector2(400.0, 400.0) * m2u
	d.roads = [
		{"points": PackedVector2Array([c + Vector2(-300, 0) * m2u, c + Vector2(300, 0) * m2u]),
			"class": "secondary", "width_m": 8.0, "bridge": false, "tunnel": false, "layer": 0},
		{"points": PackedVector2Array([c + Vector2(0, -40) * m2u, c + Vector2(0, 40) * m2u]),
			"class": "residential", "width_m": 6.0, "bridge": true, "tunnel": false, "layer": 1},
	]
	var ground := GroundTruth.new(d)
	var far := ground.height_at_world(c.x - 200.0 * m2u, c.y)
	var under := ground.height_at_world(c.x, c.y)
	var drop := (far - under) / m2u
	var want := RoadBuilder.DECK_DEPTH_M + Underpasses.CLEAR_ROAD_M
	if absf(drop - want) > 0.6:
		failures.append("underpass cut %.2f m, want ~%.2f m" % [drop, want])
	var bank := ground.height_at_world(c.x, c.y + 40.0 * m2u)
	if absf(bank - far) > 0.05 * m2u:
		failures.append("bridge end moved %.2f m" % ((far - bank) / m2u))

func _check_window(failures: Array[String]) -> void:
	if DemFetcher.window_px(48.8566) != DemFetcher.WINDOW_NEAR_PX \
			or DemFetcher.span_for(48.8566) != 3 \
			or DemFetcher.window_px(48.8566, DemFetcher.ZOOM_MID) != 144.0:
		failures.append("mid-latitude window changed")
	var extent_m := WorldScale.detailed_extent_units() / WorldScale.metres_to_units()
	for lat in [64.5, 69.65, 78.22]:
		var w := DemFetcher.window_px(lat)
		var span := DemFetcher.span_for(lat)
		if w * DemFetcher.metres_per_px(lat, DemFetcher.ZOOM_NEAR) < extent_m:
			failures.append("%.2f°N window %.0f px short of the extent" % [lat, w])
		if float(span - 1) * 256.0 < w or span % 2 == 0:
			failures.append("%.2f°N span %d cannot hold a %.0f px window" % [lat, span, w])
		if DemFetcher.mosaic_tiles(lat, 18.95, DemFetcher.ZOOM_NEAR).size() != span * span:
			failures.append("%.2f°N mosaic is not %d²" % [lat, span])
		var d := LocationData.new()
		d.latitude = lat
		d.dem_source = {"source_zoom": DemFetcher.ZOOM_NEAR, "window_px": w,
			"metres_per_px": DemFetcher.metres_per_px(lat, DemFetcher.ZOOM_NEAR)}
		if GroundTruth._extent_span_frac(d) >= 0.9999:
			failures.append("%.2f°N terrain still unregistered" % lat)
