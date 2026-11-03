extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	data.latitude = 40.71
	data.longitude = -74.0
	data.heights.resize(data.grid_size * data.grid_size)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.roads = [{"class": "primary", "width_m": 8.0,
		"points": PackedVector2Array([Vector2(-100, 0), Vector2(100, 0)])}]
	data.trees = [{"x": 0.0, "z": 7.0}, {"x": 0.0, "z": 0.0},
		{"x": 0.0, "z": 30.0}, {"x": 60.0, "z": 7.0}]
	data.land_polygons = [{"class": "grass", "points": PackedVector2Array([
		Vector2(55, 4), Vector2(65, 4), Vector2(65, 12), Vector2(55, 12)])}]
	var ground := GroundTruth.new(data)
	var mask := VegetationMask.new(data, ground)
	var pits := TreePits.plan(data, mask, 1.0)
	if pits.size() != 1 or (pits[0][0] as Vector2).distance_to(Vector2(0, 7)) > 0.01:
		failures.append("only the mapped sidewalk tree should get a pit: %s" % [pits])
	var root := Node3D.new()
	if TreePits.build(root, data, ground, mask) != 1 or root.get_node_or_null("TreePits") == null:
		failures.append("the mapped sidewalk pit should render")
	root.free()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	if not TreePits.plan(data, mask, 1.0).is_empty():
		failures.append("tree pits are Ultra-only")
	if failures.is_empty():
		print("TREE PITS OK: mapped sidewalk tree, no road or park pits, Ultra only")
		quit(0)
	else:
		for failure in failures:
			printerr("TREE PITS FAIL: ", failure)
		quit(1)
