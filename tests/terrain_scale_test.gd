extends SceneTree

## Terrain Y-scale regression: godot --headless --script tests/terrain_scale_test.gd
## Real DEM heights are metres ASL while XZ is metres x metres_to_units
## (identity since the T7.0 metre cutover). Rendered relief must be scaled by
## the same factor and rebased to the viewpoint datum, or flat Paris
## renders with ~4x vertical exaggeration (diag-2026-10-28-terrain-scale).
## Legacy/procedural fixtures (water_level == -3.0 sentinel) are already
## in render units and must pass through unchanged.

func _init() -> void:
	_run()

func _asl_data() -> LocationData:
	var data := LocationData.new()
	data.grid_size = 8
	data.heights.resize(64)
	# 100 m ASL at the west edge, rising 2 m per post eastward.
	for z in 8:
		for x in 8:
			data.heights[z * 8 + x] = 100.0 + float(x) * 2.0
	data.centre_elevation_m = 108.0
	data.water_level = 90.0
	data.relief_metres = 14.0
	data.seed_value = 42
	return data

func _run() -> void:
	var failures: Array[String] = []
	var m2u := WorldScale.metres_to_units()

	# Datum: the viewpoint post renders at ~0, not at 108 m ASL.
	var ground := GroundTruth.new(_asl_data())
	var centre := ground.height_at_world(0.0, 0.0)
	if absf(centre) > 0.6:
		failures.append("viewpoint should render near Y=0, got %f" % centre)

	# Relief: 14 m of ASL relief over the grid renders as 14 x m2u units.
	var relief := ground.surface_max - ground.surface_min
	# Tolerance: the v1 0.8 units on the 4 m-unit world (edge blur), in
	# metres since the T7.0 cutover.
	if absf(relief - 14.0 * m2u) > 3.2 * m2u:
		failures.append("rendered relief should be %.2f units, got %.2f" % [14.0 * m2u, relief])

	# Slope: rendered rise/run matches the true metre slope
	# (2 m per post over step/m2u metres per post).
	var step_m := (WorldScale.detailed_extent_units() / 7.0) / m2u
	var expect_slope := 2.0 / step_m
	if absf(ground.slope_at(0.0, 0.0) - expect_slope) > 0.004:
		failures.append("slope_at should be %.4f, got %.4f" % [expect_slope, ground.slope_at(0.0, 0.0)])

	# Mesh geometry follows the same proportions (no 4x mounds) and its
	# normals agree with the rendered geometry.
	var mesh := TerrainBuilder._terrain_mesh(_asl_data(), GroundTruth.new(_asl_data()))
	var arrays: Array = mesh.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var dy := absf(verts[4 * 8 + 5].y - verts[4 * 8 + 3].y)
	var dx := absf(verts[4 * 8 + 5].x - verts[4 * 8 + 3].x)
	if dx > 0.0 and dy / dx > expect_slope * 1.6:
		failures.append("mesh slope %.4f exceeds true slope %.4f" % [dy / dx, expect_slope])
	if normals[4 * 8 + 4].x > -0.005 or normals[4 * 8 + 4].x < -0.06:
		failures.append("mesh normal should tilt gently west, got %s" % str(normals[4 * 8 + 4]))
	mesh.free()

	# Far DEM conversion shares the datum/scale.
	if absf(ground.render_y(148.0) - 40.0 * m2u) > 0.01:
		failures.append("render_y(centre+40m) should be %.2f, got %.2f" % [40.0 * m2u, ground.render_y(148.0)])
	if absf(ground.asl_y(ground.render_y(73.0)) - 73.0) > 0.01:
		failures.append("asl_y should invert render_y")

	# Legacy sentinel fixture passes through bit-identical.
	var legacy := LocationData.new()
	legacy.grid_size = 8
	legacy.heights.resize(64)
	for i in 64:
		legacy.heights[i] = 3.0
	legacy.water_level = -3.0
	var lground := GroundTruth.new(legacy)
	if absf(lground.height_at_world(0.0, 0.0) - 3.0) > 0.001:
		failures.append("legacy fixture should stay at 3.0, got %f" % lground.height_at_world(0.0, 0.0))
	if absf(lground.render_y(9.0) - 9.0) > 0.001:
		failures.append("legacy render_y should be identity")

	if failures.is_empty():
		print("TERRAINSCALE OK: ASL relief x %.2f at viewpoint datum, legacy passthrough" % m2u)
		quit(0)
	else:
		for f in failures:
			printerr("TERRAINSCALE FAIL: ", f)
		quit(1)
