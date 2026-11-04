extends SceneTree

## Navigation routes must never become dark ribbons or carved channels.
func _init() -> void:
	var failures: Array[String] = []
	var line := PackedVector2Array([Vector2(-80, 0), Vector2(80, 0)])
	var data := LocationData.new()
	data.grid_size = 49
	data.heights.resize(49 * 49)
	data.heights.fill(4.0)
	data.water_level = -3.0
	for kind in ["fairway", "link"]:
		var parsed := OsmTags._waterway_entry({"waterway": kind, "width": "80"}, line)
		if float(parsed["width_m"]) != 0.0 or parsed["points"] != line:
			failures.append("%s must retain its route geometry without a physical width" % kind)
		# Existing parsed/cached data can still contain the old positive width.
		data.waterways.append({"class": kind, "width_m": 80.0, "points": line})
	if not WaterBuilder._channels(data).is_empty():
		failures.append("navigation-only routes must not reach the legacy ribbon renderer")
	var ground := GroundTruth.new(data)
	if not ground.shoreline.domains.bodies.is_empty() or ground.water_at(0, 0) > 0.0 \
			or absf(ground.height_at_world(0, 0) - 4.0) > 0.01:
		failures.append("navigation-only routes must not define water ownership or carve terrain")
	var water := WaterBuilder.build_water(data, ground)
	if water.get_child_count() != 0:
		failures.append("navigation-only routes must not create a water mesh")
	water.free()
	for kind in ["river", "canal", "stream", "ditch", "drain"]:
		var parsed := OsmTags._waterway_entry({"waterway": kind, "width": "12"}, line)
		if float(parsed["width_m"]) != 12.0:
			failures.append("%s must retain its mapped channel width" % kind)
	data.waterways.append({"class": "canal", "width_m": 20.0, "points": line})
	var canal_ground := GroundTruth.new(data)
	if WaterBuilder._channels(data).size() != 1 or canal_ground.water_at(0, 0) <= 0.0:
		failures.append("a physical canal beside navigation routes must still carve and render")
	if failures.is_empty():
		print("NAVIGATION WATERWAYS OK: routes do not carve or render; real channels retained")
		quit(0)
	else:
		for failure in failures:
			printerr("NAVIGATION WATERWAYS FAIL: ", failure)
		quit(1)
