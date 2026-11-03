extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var terminal := {"name": "Staten Island Ferry Whitehall Terminal", "use": "ferry_terminal", "x": 0.0, "z": 0.0}
	if not HarbourFerries.terminal(terminal) or HarbourFerries.terminal({"name": "Other Ferry", "use": "ferry_terminal"}):
		errors.append("the mapped Staten Island terminal must identify the ferry scenery")
	var data := LocationData.new()
	data.grid_size = 33
	data.heights.resize(33 * 33)
	data.heights.fill(-5.0)
	data.water_level = 0.0
	data.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array([
		Vector2(-1100, -1100), Vector2(1100, -1100), Vector2(1100, 1100), Vector2(-1100, 1100)])}]
	var wet := GroundTruth.new(data)
	var wet_mask := VegetationMask.new(data, wet)
	if HarbourFerries.berth(terminal, wet, wet_mask).is_empty():
		errors.append("a clear water area must admit a berth")
	data.heights.fill(5.0)
	data.land_polygons = []
	var dry := GroundTruth.new(data)
	var dry_mask := VegetationMask.new(data, dry)
	if not HarbourFerries.berth(terminal, dry, dry_mask).is_empty():
		errors.append("a dry site must not admit a ferry")
	var root := Node3D.new()
	var parts := HarbourFerries.model().commit(root)
	var bounds := AABB()
	for part in parts:
		bounds = bounds.merge(part.mesh.get_aabb())
	if parts.size() < 3 or bounds.size.x < 94.0 or bounds.size.x > 96.0 \
			or bounds.size.z < 21.0 or bounds.size.z > 22.0:
		errors.append("ferry geometry must use the documented vessel envelope")
	root.free()
	if errors.is_empty():
		print("HARBOUR FERRIES OK")
		quit(0)
	else:
		for error in errors:
			printerr("HARBOUR FERRIES FAIL: ", error)
		quit(1)
