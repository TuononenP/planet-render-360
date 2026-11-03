extends SceneTree

func _init() -> void:
	var data := LocationData.new()
	data.latitude = 60.168
	data.longitude = 24.953
	data.grid_size = 256
	data.heights.resize(256 * 256)
	data.heights.fill(17.0)
	data.centre_elevation_m = 22.0
	data.water_level = 2.0
	data.dem_source = {"source_zoom": DemFetcher.ZOOM_NEAR}
	data.waterways = [{"class": "coastline", "points": PackedVector2Array([Vector2(0, -1000), Vector2(0, 1000)])}]
	var fine := PackedFloat32Array([17.0, 17.0, 17.0, 17.0])
	var coarse := PackedFloat32Array([5.0, 5.0, 5.0, 5.0])
	data.dem_rings = [{"zoom": 13, "heights": fine}, {"zoom": 8, "heights": coarse}]
	var failures: Array[String] = []
	var estimate := CoastalDem.estimate(data)
	if absf(estimate - 17.0) > 0.01:
		failures.append("coherent water bias should measure 17 m: %s" % estimate)
	CoastalDem.correct(data)
	if absf(data.heights[0]) > 0.01 or absf(data.centre_elevation_m - 5.0) > 0.01:
		failures.append("near grid and centre must share corrected sea registration")
	if float(data.dem_rings[0]["heights"][0]) != 0.0 or float(data.dem_rings[1]["heights"][0]) != 5.0:
		failures.append("fine rings share correction; coarse fallback keeps its datum")
	CoastalDem.correct(data)
	if absf(data.heights[0]) > 0.01:
		failures.append("correction must be idempotent")
	data.dem_source.erase("coast_bias_m")
	data.heights.fill(0.3)
	if CoastalDem.estimate(data) != 0.0:
		failures.append("already registered sea must stay unchanged")
	for i in data.heights.size():
		data.heights[i] = 10.0 + float(i % 17)
	if CoastalDem.estimate(data) != 0.0:
		failures.append("inconsistent samples must not trigger a datum shift")
	data.waterways = []
	if CoastalDem.estimate(data) != 0.0:
		failures.append("inland places have no sea registration")
	if failures.is_empty():
		print("COASTAL DEM OK: sea registration, fine rings, coarse fallback, idempotence, confidence guards")
		quit(0)
	else:
		for failure in failures:
			printerr("COASTAL DEM FAIL: ", failure)
		quit(1)
