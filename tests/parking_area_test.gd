extends SceneTree

func _init() -> void:
	# A square of its own per element: areas on one outline count as one
	# (OsmParser._drop_duplicate_paved_areas).
	var rings: Array = []
	for i in 10:
		var lon := 0.002 * i
		rings.append([{"lat": 0.0, "lon": lon}, {"lat": 0.0, "lon": lon + 0.001},
			{"lat": 0.001, "lon": lon + 0.001}, {"lat": 0.001, "lon": lon},
			{"lat": 0.0, "lon": lon}])
	var elements := [
		{"type": "way", "id": 1, "tags": {"amenity": "parking", "surface": "asphalt"}, "geometry": rings[1]},
		{"type": "way", "id": 2, "tags": {"amenity": "parking", "parking": "underground"}, "geometry": rings[2]},
		{"type": "way", "id": 3, "tags": {"amenity": "parking", "surface": "grass"}, "geometry": rings[3]},
		{"type": "way", "id": 4, "tags": {"amenity": "parking", "building": "yes"}, "geometry": rings[4]},
		{"type": "relation", "id": 5, "tags": {"amenity": "parking", "type": "multipolygon"},
			"members": [{"type": "way", "role": "outer", "geometry": rings[5]}]},
		# Senate Square's edge: a parking lane, cycle stands and a bus bay.
		{"type": "way", "id": 6, "tags": {"amenity": "parking", "parking": "lane"}, "geometry": rings[6]},
		{"type": "way", "id": 7, "tags": {"amenity": "bicycle_parking"}, "geometry": rings[7]},
		{"type": "way", "id": 8, "tags": {"amenity": "unsigned_tourist_bus_halting"}, "geometry": rings[8]},
		{"type": "way", "id": 9, "tags": {"amenity": "bicycle_parking", "surface": "grass"}, "geometry": rings[9]}]
	var parsed := OsmParser.parse_features(JSON.stringify({"elements": elements}), 0.0, 0.0)
	var areas: Array = parsed["roads"]
	var query := OsmQuery.build_query(0.0, 0.0)
	if areas.size() != 5 or not areas.all(func(area: Dictionary) -> bool:
			return area.get("class") == "parking" and area.get("area") == true) \
			or not query.contains('way["amenity"~"%s"]' % OsmQuery.STANDING_AMENITIES) \
			or not query.contains('relation["amenity"~"%s"]' % OsmQuery.STANDING_AMENITIES):
		printerr("PARKING AREA FAIL: surface car parks, parking lanes, stands and bus bays should be filled, excluding buildings, grass and underground parking: ", areas)
		quit(1)
		return
	var data := LocationData.new()
	data.grid_size = 32
	data.heights.resize(1024)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.roads = [areas[0]]
	var ground := GroundTruth.new(data)
	var roads := RoadBuilder.build_roads(data, ground)
	var surface := roads.get_node_or_null("Road_asphalt") as MeshInstance3D
	if surface == null or surface.mesh.get_aabb().size.x < 50.0:
		printerr("PARKING AREA FAIL: mapped surface should produce a filled asphalt mesh")
		roads.free()
		quit(1)
		return
	roads.free()
	print("PARKING AREA OK: query, mapped surfaces and exclusions")
	quit(0)
