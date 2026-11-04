extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var data := LocationData.new()
	data.grid_size = 33
	data.heights.resize(33 * 33)
	data.heights.fill(5.0)
	data.water_level = -3.0
	var bridge := {"type": "manhattan_bridge", "archetype": "Bridge", "x": 0.0, "z": 0.0,
		"span_m": 2140.0, "clear_m": 24.0, "yaw_deg": 65.0}
	data.landmark_candidates = [bridge]
	var mask := VegetationMask.new(data, GroundTruth.new(data))
	var axis := LandmarkSites.axis(bridge)
	var side := Vector2(-axis.y, axis.x)
	for point in [Vector2.ZERO, axis * 900.0, axis * 500.0 + side * 18.0]:
		if not mask.blocked(point.x, point.y, VegetationMask.ROAD):
			errors.append("bespoke bridge corridor admits a tree at %s" % point)
	for point in [side * 35.0, axis * 1150.0]:
		if mask.blocked(point.x, point.y, VegetationMask.ROAD):
			errors.append("bridge exclusion extends outside its registered corridor at %s" % point)
	data.landmark_candidates = [{"type": "one_wtc", "archetype": "Skyscraper", "span_m": 200.0}]
	if not LandmarkSites.bridge_spans(data).is_empty():
		errors.append("non-bridge landmarks must not cut decks or exclude trees as bridge spans")
	if errors.is_empty():
		print("BRIDGE VEGETATION OK: registered span clearance, surroundings retained, bridges only")
		quit(0)
	else:
		for error in errors:
			printerr("BRIDGE VEGETATION FAIL: ", error)
		quit(1)
