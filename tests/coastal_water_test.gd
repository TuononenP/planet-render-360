extends SceneTree

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	for pool in [false, true]:
		var data := LocationData.new()
		data.climate = {"t_cold_c": 3.0, "t_warm_c": 22.0}
		data.grid_size = 32
		data.heights.resize(32 * 32)
		data.heights.fill(17.0)
		data.water_level = 0.5
		data.land_polygons = [{"class": "water", "tidal": not pool, "still_pool": pool,
			"points": PackedVector2Array([Vector2(-200, -200), Vector2(200, -200), Vector2(200, 200), Vector2(-200, 200)])}]
		var ground := GroundTruth.new(data)
		var water := WaterBuilder.build_water(data, ground)
		var found := false
		for child in water.get_children():
			if not (child is MeshInstance3D) or not child.material_override is ShaderMaterial:
				continue
			var mesh := (child as MeshInstance3D).mesh
			var mat := child.material_override as ShaderMaterial
			if absf(float(mat.get_shader_parameter("temperate_sea")) - 1.0) > 0.001:
				failures.append("water must receive the place's temperate sea factor")
			if pool:
				found = found or absf(float(mat.get_shader_parameter("wave_amp")) - 0.08) < 0.001
			else:
				var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					if absf(ground.asl_y(vertex.y) - 0.5) < 0.1:
						found = true
		if not found:
			failures.append("calm pool shader" if pool else "tidal surface must share the sea datum")
		water.free()
	if not OsmTags.tidal({"natural": "bay"}) or OsmTags.tidal({"water": "lake"}) \
			or not OsmTags.still_pool({"artificial": "yes"}) or OsmTags.still_pool({"water": "lake"}):
		failures.append("OSM tidal/pool interpretation")
	var climate := LocationData.new()
	climate.climate = {"t_cold_c": 24.0, "t_warm_c": 30.0}
	if WaterSurface.temperate_sea(climate) > 0.001:
		failures.append("tropical climate should retain the warm-sea colour")
	climate.climate = {}
	climate.latitude = -50.0
	if WaterSurface.temperate_sea(climate) < 0.999:
		failures.append("cold-latitude fallback should use the temperate sea colour")
	var place := LocationData.new()
	place.latitude = 40.706
	place.longitude = -74.004
	var ny := WaterSurface.sea_palette(place)
	if not bool(ny["harbour"]) or bool(ny["brackish"]) or (ny["shallow"] as Vector3).z >= 0.08:
		failures.append("New York harbour should use muted grey-green absorption")
	place.latitude = 60.17
	place.longitude = 24.95
	if not bool(WaterSurface.sea_palette(place)["brackish"]):
		failures.append("Baltic locations must keep their brackish palette")
	place.latitude = 20.0
	place.longitude = -157.0
	if bool(WaterSurface.sea_palette(place)["harbour"]) or bool(WaterSurface.sea_palette(place)["brackish"]):
		failures.append("tropical coasts must not inherit the harbour palette")
	if WaterSurface.sea_ramp_m(20.0, 20.0, 5.0) != 30.0 \
			or WaterSurface.sea_ramp_m(1000.0, 20.0, 5.0) != 150.0:
		failures.append("hard shores need a shorter shelf; natural shores keep the long one")
	if failures.is_empty():
		print("COASTAL WATER OK: tidal sea datum, calm ornamental pools, OSM semantics")
		quit(0)
	else:
		for failure in failures:
			printerr("COASTAL WATER FAIL: ", failure)
		quit(1)
