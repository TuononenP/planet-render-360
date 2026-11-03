extends SceneTree

func _init() -> void:
	var ring := [{"lat": 0.0, "lon": 0.0}, {"lat": 0.0, "lon": 0.001},
		{"lat": 0.001, "lon": 0.001}, {"lat": 0.001, "lon": 0.0},
		{"lat": 0.0, "lon": 0.0}]
	var elements := [
		{"type": "way", "id": 1, "tags": {"amenity": "parking", "surface": "asphalt"}, "geometry": ring},
		{"type": "way", "id": 2, "tags": {"amenity": "parking", "parking": "underground"}, "geometry": ring},
		{"type": "way", "id": 3, "tags": {"amenity": "parking", "surface": "grass"}, "geometry": ring},
		{"type": "way", "id": 4, "tags": {"amenity": "parking", "building": "yes"}, "geometry": ring},
		{"type": "relation", "id": 5, "tags": {"amenity": "parking", "type": "multipolygon"},
			"members": [{"type": "way", "role": "outer", "geometry": ring}]}]
	var parsed := OsmParser.parse_features(JSON.stringify({"elements": elements}), 0.0, 0.0)
	var areas: Array = parsed["roads"]
	var query := OsmQuery.build_query(0.0, 0.0)
	if areas.size() != 2 or not areas.all(func(area: Dictionary) -> bool:
			return area.get("class") == "parking" and area.get("area") == true) \
			or not query.contains('way["amenity"="parking"]') \
			or not query.contains('relation["amenity"="parking"]'):
		printerr("PARKING AREA FAIL: surface ways/relations should be filled, excluding buildings, grass and underground parking: ", areas)
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
