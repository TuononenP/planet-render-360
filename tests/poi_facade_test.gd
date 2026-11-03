extends SceneTree

const PoiIndex = preload("res://scripts/generation/poi_facade_index.gd")

func _init() -> void:
	var failures: Array[String] = []
	var ring := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var points := [
		{"x": 5.0, "z": -2.0, "category": "shop", "kind": "bakery", "name": "Bakery"},
		{"x": 5.0, "z": 13.0, "category": "amenity", "kind": "cafe"},
		{"x": 13.01, "z": 5.0, "category": "shop", "kind": "books"},
		{"x": -1.0, "z": 5.0, "category": "amenity", "kind": "bench"},
		{"category": "shop", "kind": "bad"}]
	var index := PoiIndex.new(points)
	var edges := index.for_ring(ring)
	if edges.size() != 2 or not edges.has(0) or not edges.has(2) \
			or edges[0].get("name") != "Bakery":
		failures.append("businesses must match only facade edges within 3 m: %s" % edges)
	if PoiIndex.colour(points[0]) != PoiIndex.colour(points[0]):
		failures.append("fascia colour must be deterministic")
	var root := Node3D.new()
	var base := StandardMaterial3D.new()
	var shop := StandardMaterial3D.new()
	BuildingWalls._walls(root, ring, 0.0, 4.0, base, 1.0, [], null, false, {0: shop})
	var counts := {}
	for child in root.get_children():
		var mesh := (child as MeshInstance3D).mesh
		counts[(child as MeshInstance3D).material_override] = (MeshArrays.surface(mesh, 0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	if int(counts.get(shop, 0)) != 4 or int(counts.get(base, 0)) != 12:
		failures.append("shop material must affect only its matching edge: %s" % counts)
	root.free()
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.heights.resize(data.grid_size * data.grid_size)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.buildings = [{"x": 5.0, "z": 5.0, "size_x": 10.0, "size_z": 10.0,
		"footprint": ring, "height": 16.0, "height_source": "tag_height", "levels": 4,
		"kind": "apartments", "roof_shape": "flat", "parts": [], "holes": []}]
	data.pois = [points[0]]
	var built := BuildingBuilder.build_buildings(data)
	var look := {"wall_set": "concrete", "ground": "shop", "bay_m": 3.2, "floor_h": 3.3,
		"ground_colour": PoiIndex.colour(points[0])}
	var target := FacadeMaterials.ground_for_building({}, MaterialLibrary.fidelity_for_preset(data.quality_preset), false, look)
	var found := false
	for child in built.get_children():
		if child is MeshInstance3D and child.material_override == target:
			found = true
			for v in (MeshArrays.surface(child.mesh, 0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				if absf(v.z) > 0.01:
					failures.append("POI shop geometry escaped its mapped facade edge")
					break
	if not found:
		failures.append("mapped business did not produce a shop facade in the real building builder")
	built.free()
	FacadeMaterials.begin_build()
	for i in 100:
		var shade := PoiIndex.colour({"name": "Shop %d" % i})
		var shared_look := {"wall_set": "concrete", "ground": "shop", "bay_m": 3.2,
			"floor_h": 3.3, "ground_colour": shade}
		FacadeMaterials.ground_for_building({}, 2, false, shared_look)
	if FacadeMaterials._ground_cache.size() > PoiIndex.COLOURS.size():
		failures.append("shop materials exceeded the shared fascia palette")
	if failures.is_empty():
		print("POI FACADE OK: mapped edge matching, bounded colours and wall materials")
		quit(0)
	else:
		for failure in failures:
			printerr("POI FACADE FAIL: ", failure)
		quit(1)
