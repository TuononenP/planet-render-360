extends SceneTree

## Headless geometry/registry contract for the Helsinki hero additions.
func _init() -> void:
	var failures: Array[String] = []
	_skywheel_placement(failures)
	for entry in LandmarkRegistryHelsinkiHero.entries():
		var type := str(entry["type"])
		if not LandmarkBuilder.is_bespoke(type):
			failures.append(type + " must have a bespoke builder")
		var root := LandmarkBuilder.build(type)
		var tris := 0
		var bounds := AABB()
		var first := true
		var parts := LandmarkBuilder.parts(root)
		for part in parts:
			var box := part.transform * part.mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			tris += part.mesh.surface_get_array_len(0) / 3
			var mat := part.mesh.surface_get_material(0) as StandardMaterial3D
			if mat == null or mat.albedo_texture == null:
				failures.append(type + " needs textured materials")
		if parts.size() < 2 or parts.size() > 16 or tris < 500 or tris > 150000:
			failures.append("%s invalid parts/triangles: %d / %d" % [type, parts.size(), tris])
		if absf(bounds.end.y - float(entry["height_m"])) > maxf(2.0, float(entry["height_m"]) * 0.03):
			failures.append("%s height %s expected %s" % [type, bounds.end.y, entry["height_m"]])
		if bounds.position.y < -0.1:
			failures.append(type + " sinks below its base")
		var radius := 0.0
		for i in 8:
			var point := bounds.get_endpoint(i)
			radius = maxf(radius, Vector2(point.x, point.z).length())
		if radius > float(entry["clear_m"]) + 1.0:
			failures.append("%s clear_m %s cannot cover radius %.1f" % [type, entry["clear_m"], radius])
		var lookup := LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), str(entry["name"]))
		if lookup != type:
			failures.append("%s name resolves to %s" % [type, lookup])
		print("HELSINKI HERO %s: %d tris, %.2f m high, radius %.1f m" % [type, tris, bounds.end.y, radius])
		root.free()
	if failures.is_empty():
		print("HELSINKI HERO LANDMARKS OK: ten textured bespoke models, heights, extents, registry lookup")
		quit(0)
	else:
		for failure in failures:
			printerr("HELSINKI HERO FAIL: ", failure)
		quit(1)

func _skywheel_placement(failures: Array[String]) -> void:
	# OSM way 457949936 and adjacent buildings: a dimension-only model
	# test misses a wheel placed inside a correctly dimensioned building.
	var text := FileAccess.get_file_as_string("res://tests/fixtures/helsinki_skywheel.json")
	var raw: Dictionary = JSON.parse_string(text)
	var d := LocationData.new()
	d.latitude = 60.168
	d.longitude = 24.953
	d.quality_preset = RenderSettings.Preset.ULTRA
	d.grid_size = 8
	d.heights.resize(64)
	d.heights.fill(3.0)
	d.water_level = -3.0
	var parsed := OsmParser.parse_features(text, d.latitude, d.longitude)
	d.buildings = parsed["buildings"]
	var selected := LandmarkSites.select(d, parsed["landmarks"])
	var wheel: Dictionary = {}
	for c in selected:
		if str(c.get("type", "")) == "skywheel_helsinki":
			wheel = c
		elif str(c.get("archetype", "")) == "big_wheel":
			failures.append("SkyWheel must replace its generic OSM wheel")
	if wheel.is_empty():
		failures.append("Helsinki must include SkyWheel as a registry candidate")
		return
	var mapped := PackedVector2Array()
	for el in raw["elements"]:
		if int(el["id"]) == 457949936:
			for p in el["geometry"]:
				mapped.append(WorldScale.xz_from_latlon(p["lat"], p["lon"], d.latitude, d.longitude))
	var centre := (mapped[0] + mapped[2]) * 0.5
	var at := Vector2(float(wheel["x"]), float(wheel["z"]))
	if at.distance_to(centre) > 1.0:
		failures.append("SkyWheel centre must follow its mapped footprint within 1 m")
	d.landmark_candidates = [wheel]
	var root := Node3D.new()
	TerrainBuilder._landmark_candidates(root, d, GroundTruth.new(d))
	var model := root.get_child(0) as Node3D
	var axis := Vector2(model.basis.x.x, model.basis.x.z).normalized()
	if absf(axis.dot((mapped[2] - mapped[1]).normalized())) < cos(deg_to_rad(2.0)):
		failures.append("SkyWheel plane must follow its mapped long axis within 2 degrees")
	var bounds := AABB()
	var first := true
	for part in LandmarkBuilder.parts(model):
		var box := part.transform * part.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var footprint := PackedVector2Array()
	for p in [bounds.position, Vector3(bounds.end.x, 0, bounds.position.z),
			bounds.end, Vector3(bounds.position.x, 0, bounds.end.z)]:
		var world: Vector3 = model.transform * p
		footprint.append(Vector2(world.x, world.z))
	d.landmark_candidates = selected
	for el in raw["elements"]:
		if int(el["id"]) == 443717281:
			var venue := OsmParser.parse_features(JSON.stringify({"elements": [el]}), d.latitude, d.longitude)
			if BuildingBuilder._accepted(d, venue["buildings"][0], Vector2.ZERO, 1176.0):
				failures.append("Allas must replace its eastern venue building beside SkyWheel")
		elif int(el["id"]) == 23192809:
			# The office is the bespoke enso_gutzeit_hq model: Allas's clearance
			# must not reach it, and Enso's own clearance replaces it.
			var office := OsmParser.parse_features(JSON.stringify({"elements": [el]}), d.latitude, d.longitude)
			var b: Dictionary = office["buildings"][0]
			var p := Vector2(float(b["x"]), float(b["z"]))
			for c in selected:
				var cd: Dictionary = c
				var inside := LandmarkSites.span_dist(p, Vector2(float(cd["x"]), float(cd["z"])), cd) \
					< LandmarkSites.clear_m(cd)
				if str(cd.get("type", "")) == "allas_sea_pool" and inside:
					failures.append("Allas clearance must not reach the neighbouring Enso-Gutzeit office")
				if str(cd.get("type", "")) == "enso_gutzeit_hq" and not inside:
					failures.append("the bespoke Enso-Gutzeit model must replace its mapped office")
	var retained := 0
	var cleared := 0
	for b in d.buildings:
		if BuildingBuilder._accepted(d, b, Vector2.ZERO, 1176.0):
			retained += 1
			if not Geometry2D.intersect_polygons(footprint, b["footprint"]).is_empty():
				failures.append("SkyWheel intersects a retained neighbouring building")
		else:
			cleared += 1
	if retained == 0 or cleared == 0:
		failures.append("SkyWheel fixture must exercise retained neighbours and cleared site buildings")
	root.free()
