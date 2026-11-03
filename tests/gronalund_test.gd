extends SceneTree

## A grouped skyline must have the real ride positions and preserve nearby
## buildings between the separate cleared footprints, without extra draws.
func _init() -> void:
	var errors: Array[String] = []
	var root := LandmarkBuilder.build("grona_lund_eclipse")
	var parts := LandmarkBuilder.parts(root)
	var fritt_top := 0.0
	var ikaros_top := 0.0
	var coaster: MeshInstance3D = null
	for part in parts:
		if str(part.name) == "CoasterTrack":
			coaster = part
		var vertices: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for v in vertices:
			if Vector2(v.x, v.z).distance_to(Vector2(38.33, -29.69)) < 8.0:
				fritt_top = maxf(fritt_top, v.y)
			if Vector2(v.x, v.z).distance_to(Vector2(-54.85, -25.30)) < 8.0:
				ikaros_top = maxf(ikaros_top, v.y)
	if absf(fritt_top - 80.0) > 0.5 or absf(ikaros_top - 95.0) > 0.5:
		errors.append("ride positions/heights: Fritt %.1f m, Ikaros %.1f m" % [fritt_top, ikaros_top])
	if coaster == null or coaster.mesh.get_aabb().end.y < 30.0 or coaster.mesh.get_aabb().end.y > 35.0:
		errors.append("Monster should contain track up to approximately 34 m")
	if parts.size() > 10:
		errors.append("park geometry should stay merged (got %d parts)" % parts.size())
	root.free()

	var entry := LocationData.entry_for_type("grona_lund_eclipse")
	var fritt := Vector2(38.33, -29.69)
	var ikaros := Vector2(-54.85, -25.30)
	for point in [Vector2.ZERO, fritt, ikaros]:
		if LandmarkSites.span_dist(point, Vector2.ZERO, entry) > 0.01:
			errors.append("expected separate cleared footprint at %s" % point)
	if LandmarkSites.span_dist(Vector2(20, -15), Vector2.ZERO, entry) < LandmarkSites.clear_m(entry):
		errors.append("space between the ride footprints should remain available")
	var rotated := {"clear_offsets_m": [[10.0, 0.0]], "yaw_deg": 90.0}
	if LandmarkSites.span_dist(Vector2(100, 210), Vector2(100, 200), rotated) > 0.01:
		errors.append("clearance offsets should follow the landmark yaw")

	var data := LocationData.new()
	data.latitude = 59.3207
	data.longitude = 18.0604
	data.landmark_type = "stockholm_city_hall"
	data.quality_preset = 3
	var selected := LandmarkSites.select(data, []).filter(
		func(e: Dictionary) -> bool: return str(e["type"]) == "grona_lund_eclipse")
	if selected.size() != 1 or (selected[0].get("clear_offsets_m", []) as Array).size() != 2:
		errors.append("selected registry model must retain both footprint offsets")
	if errors.is_empty():
		print("GRONA LUND OK")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
