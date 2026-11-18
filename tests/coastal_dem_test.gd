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
	_grid_matches_brute_force(failures)
	if failures.is_empty():
		print("COASTAL DEM OK: sea registration, fine rings, coarse fallback, idempotence, confidence guards")
		quit(0)
	else:
		for failure in failures:
			printerr("COASTAL DEM FAIL: ", failure)
		quit(1)

## SegmentGrid answers exactly what testing every segment would, ties
## (a point nearest a vertex two segments share) included.
func _grid_matches_brute_force(failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var segments: Array = []
	var at := Vector2(-900, -900)
	for i in 400:  # a wandering coastline, and a few long straight cuts
		var next := at + Vector2(rng.randf_range(-60, 90), rng.randf_range(-60, 90))
		segments.append([at, next])
		at = next
	segments.append([Vector2(-2000, 300), Vector2(2500, -400)])
	segments.append([Vector2(0, -3000), Vector2(120, 3000)])
	var grid := CoastalDem.SegmentGrid.new(segments, 150.0)
	var mismatches := 0
	for k in 3000:
		var p := Vector2(rng.randf_range(-3000, 3000), rng.randf_range(-3000, 3000))
		if k < 40:
			p = segments[k * 7][1]  # exactly on a shared vertex
		if grid.open_water(p, 60.0) != _brute_open_water(p, segments, 60.0):
			mismatches += 1
	if mismatches > 0:
		failures.append("the segment grid disagreed with brute force at %d of 3000 points" % mismatches)
	if CoastalDem.SegmentGrid.new([], 150.0).open_water(Vector2.ZERO, 60.0):
		failures.append("no coastline is no open water")

static func _brute_open_water(p: Vector2, segments: Array, minimum: float) -> bool:
	var best := INF
	var water := false
	for segment in segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(q)
		if d < best:
			best = d
			var dir := b - a
			water = (p - q).dot(Vector2(-dir.y, dir.x)) > 0.0
	return water and best >= minimum
