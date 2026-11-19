extends SceneTree

## Multi-city PlazaLife, square deduplication & architectural square paving tests (offline):
## tools/godot_bg.sh --headless --path . --script tests/plaza_life_test.gd

var failures: Array[String] = []

func _init() -> void:
	_test_square_dedup()
	_test_turku()
	_test_helsinki()
	_test_berlin()
	_test_rome()
	if failures.is_empty():
		print("PLAZA LIFE PASS")
		quit(0)
	else:
		for msg in failures:
			printerr("PLAZA LIFE FAIL: ", msg)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)

func _test_square_dedup() -> void:
	var doc := {
		"elements": [
			{"type": "way", "id": 1, "tags": {"place": "square", "name": "Test Market", "amenity": "marketplace"},
				"geometry": [
					{"lat": 60.1670, "lon": 24.9530}, {"lat": 60.1670, "lon": 24.9540},
					{"lat": 60.1676, "lon": 24.9540}, {"lat": 60.1676, "lon": 24.9530},
					{"lat": 60.1670, "lon": 24.9530}]},
			{"type": "relation", "id": 2, "tags": {"type": "multipolygon", "highway": "pedestrian", "surface": "sett"},
				"members": [
					{"type": "way", "ref": 10, "role": "outer", "geometry": [
						{"lat": 60.1670, "lon": 24.9530}, {"lat": 60.1670, "lon": 24.9540},
						{"lat": 60.1676, "lon": 24.9540}, {"lat": 60.1676, "lon": 24.9530},
						{"lat": 60.1670, "lon": 24.9530}]},
					{"type": "way", "ref": 11, "role": "inner", "geometry": [
						{"lat": 60.1672, "lon": 24.9534}, {"lat": 60.1672, "lon": 24.9536},
						{"lat": 60.1674, "lon": 24.9536}, {"lat": 60.1674, "lon": 24.9534},
						{"lat": 60.1672, "lon": 24.9534}]}]},
			{"type": "way", "id": 3, "tags": {"leisure": "outdoor_seating"},
				"geometry": [
					{"lat": 60.1665, "lon": 24.9530}, {"lat": 60.1665, "lon": 24.9532},
					{"lat": 60.1667, "lon": 24.9532}, {"lat": 60.1667, "lon": 24.9530},
					{"lat": 60.1665, "lon": 24.9530}]},
			{"type": "way", "id": 4, "tags": {"leisure": "outdoor_seating", "level": "1"},
				"geometry": [
					{"lat": 60.1665, "lon": 24.9535}, {"lat": 60.1665, "lon": 24.9537},
					{"lat": 60.1667, "lon": 24.9537}, {"lat": 60.1667, "lon": 24.9535},
					{"lat": 60.1665, "lon": 24.9535}]},
		]
	}
	var parsed := OsmParser.parse_features(JSON.stringify(doc), 60.1673, 24.9535)
	var areas: Array = parsed["roads"].filter(func(r: Variant) -> bool: return r is Dictionary and bool((r as Dictionary).get("area", false)))
	_check(areas.size() == 2, "Expected 1 deduped square + 1 ground outdoor_seating, got %d" % areas.size())
	if areas.size() >= 1:
		var sq: Dictionary = areas[0]
		_check((sq.get("holes", []) as Array).size() == 1, "Deduped square keeps inner hole")
		_check(str(sq.get("surface", "")) == "sett", "Deduped square keeps surface=sett")
		_check(bool(sq.get("marketplace", false)), "Deduped square absorbs marketplace=true")
		_check(str(sq.get("name", "")) == "Test Market", "Deduped square absorbs name")

func _build_city(city: String, lat: float, lon: float, primary_type: String, view_lat: float, view_lon: float) -> Dictionary:
	var det_txt := BundledOsm.read(city + "_detailed")
	var poi_txt := BundledOsm.read(city + "_poi")
	_check(det_txt != "", "%s_detailed snapshot readable" % city)
	var merged := OsmParser.merge_payloads(det_txt, poi_txt)
	var parsed := OsmParser.parse_features(merged, lat, lon)
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.quality_preset = RenderSettings.Preset.ULTRA
	data.season = LocationData.Season.SUMMER
	data.grid_size = 8
	data.heights.resize(64)
	data.heights.fill(4.0)
	data.buildings = parsed["buildings"]
	data.roads = parsed["roads"]
	data.land_polygons = OsmGeometry.land_by_priority(parsed["land"])
	data.trees = parsed["trees"]
	data.pois = parsed["pois"]
	data.country = str(parsed.get("country", ""))
	if data.country == "":
		data.country = {"turku": "FI", "helsinki": "FI", "berlin": "DE", "rome": "IT"}.get(city, "")
	data.landmark_type = primary_type
	if primary_type != "none":
		data.has_landmark_site = true
		data.landmark_lat = lat
		data.landmark_lon = lon
	data.landmark_candidates = LandmarkSites.select(data, parsed["landmarks"])
	data.view = {"lat": lat, "lon": lon, "eye_lat": view_lat, "eye_lon": view_lon}
	var ground := GroundTruth.new(data)
	var mask := VegetationMask.new(data, ground)
	var root := Node3D.new()
	var count := PlazaLife.build(root, data, ground, mask, {"preset": data.quality_preset, "m2u": 1.0})
	return {"data": data, "parsed": parsed, "root": root, "count": count}

func _test_turku() -> void:
	var res := _build_city("turku", 60.4518, 22.2666, "turku_cathedral", 60.4518, 22.2666)
	var data: LocationData = res["data"]
	var root: Node3D = res["root"]
	var k_areas := data.roads.filter(func(r: Variant) -> bool:
		return r is Dictionary and bool((r as Dictionary).get("area", false)) \
			and str((r as Dictionary).get("name", "")).to_lower().contains("kauppatori"))
	_check(k_areas.size() == 1, "Turku Kauppatori deduplicated to 1 area (got %d)" % k_areas.size())
	if k_areas.size() == 1:
		_check((k_areas[0].get("holes", []) as Array).size() >= 1, "Turku Kauppatori keeps multipolygon holes")
	var plaza := root.get_node_or_null("PlazaLife")
	_check(plaza != null and plaza.get_child_count() > 0, "Turku outside Kauppatori builds planters/fountains/terraces")
	var k_entry := LocationData.entry_for_type("turku_kauppatori")
	var kaup := WorldScale.xz_from_latlon(float(k_entry["lat"]), float(k_entry["lon"]), data.latitude, data.longitude)
	_check(_count_verts_within(plaza, kaup, 80.0) == 0, "PlazaLife places 0 duplicate vertices inside Turku Kauppatori")
	root.free()

func _test_helsinki() -> void:
	var res := _build_city("helsinki", 60.1680, 24.9530, "helsinki_cathedral", 60.1674, 24.9532)
	var data: LocationData = res["data"]
	var root: Node3D = res["root"]
	var mkt_areas := data.roads.filter(func(r: Variant) -> bool:
		return r is Dictionary and bool((r as Dictionary).get("area", false)) \
			and str((r as Dictionary).get("name", "")) == "Kauppatori")
	_check(mkt_areas.size() == 1, "Helsinki Kauppatori parsed as 1 deduplicated square (got %d)" % mkt_areas.size())
	var count := int(res["count"])
	_check(count >= 5, "Helsinki Kauppatori & Esplanadi produce PlazaLife furnishings (%d)" % count)
	var plaza := root.get_node_or_null("PlazaLife")
	_check(plaza != null, "Helsinki PlazaLife node built")
	var havis := LocationData.entry_for_type("havis_amanda")
	var h_xz := WorldScale.xz_from_latlon(float(havis["lat"]), float(havis["lon"]), data.latitude, data.longitude)
	_check(_count_verts_within(plaza, h_xz, 6.5) == 0, "PlazaLife respects Havis Amanda monument")
	root.free()

func _test_berlin() -> void:
	var res := _build_city("berlin", 52.52437, 13.41053, "none", 52.5208, 13.4094)
	var root: Node3D = res["root"]
	_check(int(res["count"]) >= 4, "Berlin Alexanderplatz/Hackescher Markt builds fountains/stalls/terraces (%d)" % int(res["count"]))
	_check(root.get_node_or_null("PlazaLife") != null, "Berlin PlazaLife node built")
	root.free()

func _test_rome() -> void:
	var res := _build_city("rome", 41.8916, 12.4916, "colosseum", 41.8950, 12.4825)
	var data: LocationData = res["data"]
	var root: Node3D = res["root"]
	_check(int(res["count"]) >= 4, "Rome centro builds plaza fountains/terraces (%d)" % int(res["count"]))
	var plaza := root.get_node_or_null("PlazaLife")
	_check(plaza != null, "Rome PlazaLife node built")
	var trevi := LocationData.entry_for_type("trevi_fountain")
	var t_xz := WorldScale.xz_from_latlon(float(trevi["lat"]), float(trevi["lon"]), data.latitude, data.longitude)
	_check(_count_verts_within(plaza, t_xz, 35.0) == 0, "PlazaLife respects Trevi Fountain clear_m")
	root.free()

func _count_verts_within(node: Node, centre: Vector2, r_m: float) -> int:
	if node == null:
		return 0
	var r2 := r_m * r_m
	var hits := 0
	for c in node.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var arr := (c as MeshInstance3D).mesh.surface_get_arrays(0)
			for v: Vector3 in arr[Mesh.ARRAY_VERTEX]:
				if Vector2(v.x, v.z).distance_squared_to(centre) <= r2:
					hits += 1
	return hits
