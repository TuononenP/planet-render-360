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
	var lm := LandmarkMesh.new()
	lm.use("Masonry", StandardMaterial3D.new())
	LandmarkBrManhattan._portal(lm)
	var floor_y := LandmarkBrManhattan._deck_y(LandmarkBrManhattan.PORTAL_X) + 0.6
	var vertices: PackedVector3Array = lm._surfs["Masonry"].v
	for sample in [[0.0, 3.0, false], [0.0, 12.4, true], [6.5, 5.0, true]]:
		var origin := Vector3(LandmarkBrManhattan.PORTAL_X - 10.0, floor_y + float(sample[1]), float(sample[0]))
		var hit := false
		for i in range(0, vertices.size(), 3):
			if Geometry3D.ray_intersects_triangle(origin, Vector3.RIGHT,
					vertices[i], vertices[i + 1], vertices[i + 2]) != null:
				hit = true
				break
		if hit != bool(sample[2]):
			errors.append("portal must have an open roadway and solid crown/pylons: %s" % [sample])
	if LandmarkBrManhattan._half_width(LandmarkBrManhattan.PORTAL_X) * 2.0 >= LandmarkBrManhattan.OPENING_WIDTH:
		errors.append("central approach must fit through the stone entrance")
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
