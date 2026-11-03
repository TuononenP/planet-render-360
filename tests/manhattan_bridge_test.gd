extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var entry := LocationData.entry_for_type("manhattan_bridge")
	if entry.is_empty() or str(entry.get("kind", "")) != "Bridge" \
			or absf(float(entry.get("span_m", 0.0)) - 2140.0) > 0.1:
		errors.append("Manhattan Bridge needs a registered bridge span")
	if not LandmarkBuilder.is_bespoke("manhattan_bridge"):
		errors.append("Manhattan Bridge needs its bespoke model")
	var model := LandmarkBuilder.build("manhattan_bridge")
	var bounds := AABB()
	for part in LandmarkBuilder.parts(model):
		bounds = bounds.merge(part.mesh.get_aabb())
	if bounds.size.x < 2100.0 or bounds.size.x > 2200.0 or bounds.end.y < 103.0 \
			or bounds.end.y > 115.0 or bounds.size.z < 45.0:
		errors.append("Manhattan Bridge bounds do not include towers and portal: %s" % bounds)
	model.free()
	var spans := [[Vector2.ZERO, entry]]
	var axis := LandmarkSites.axis(entry)
	var points := PackedVector2Array([axis * -1250.0, axis * -1150.0, axis * -1000.0,
		Vector2.ZERO, axis * 1000.0, axis * 1150.0, axis * 1250.0])
	var runs := LandmarkSites.outside_spans(points, spans)
	if runs.size() != 2:
		errors.append("bridge deck replacement must preserve only the approaches: %s" % [runs])
	if errors.is_empty():
		print("MANHATTAN BRIDGE OK: model dimensions, registry and deck replacement")
		quit(0)
	else:
		for error in errors:
			printerr("MANHATTAN BRIDGE FAIL: ", error)
		quit(1)
