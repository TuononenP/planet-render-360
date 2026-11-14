extends SceneTree

## Native road grading: godot --headless --path . --script tests/road_grader_test.gd
## RoadGrading.grade through RoadGrader (native/, tools/build_native.sh)
## must grade exactly the script's surface: random hilly grids with water
## posts, crossing roads of every width, fine and coarse settings. Skips,
## passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("RoadGrader"):
		print("ROAD_GRADER SKIP: RoadGrader is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var m := WorldScale.metres_to_units()
	for t in 12:
		var size: int = [17, 33, 64][t % 3]
		var step := rng.randf_range(2.0, 9.0) * m
		var surface := PackedFloat32Array()
		var level := PackedFloat32Array()
		for i in size * size:
			surface.append(rng.randf_range(0.0, 40.0) + float(i % size) * 0.7)
			level.append(rng.randf_range(0.0, 5.0) if rng.randf() < 0.08 else -INF)
		var roads: Array = []
		var reach := float(size) * step * 0.5
		for k in 6:
			var pts := PackedVector2Array()
			for j in rng.randi_range(2, 6):
				pts.append(Vector2(rng.randf_range(-reach, reach), rng.randf_range(-reach, reach)))
			roads.append({"points": pts, "class": ["residential", "primary", "service", "footway"][k % 4],
				"width_m": rng.randf_range(0.0, 14.0), "bridge": k == 5 and t % 2 == 0})
		var coarse := t % 2 == 1
		var out := {}
		for native in [true, false]:
			RoadGrading._native = native
			var graded := surface.duplicate()
			if coarse:
				RoadGrading.grade(graded, level, size, step, roads, m, RoadGrading.COARSE_SMOOTH_M, RoadGrading.COARSE_MAX_SHIFT_M)
			else:
				RoadGrading.grade(graded, level, size, step, roads, m)
			out[native] = graded
		if var_to_bytes(out[true]) != var_to_bytes(out[false]):
			failures.append("case %d (size %d, coarse %s)" % [t, size, coarse])
		if var_to_bytes(out[false]) == var_to_bytes(surface):
			failures.append("case %d graded nothing" % t)
	RoadGrading._native = true
	if failures.is_empty():
		print("ROAD_GRADER PASS")
		quit(0)
	else:
		for f in failures:
			push_error("ROAD_GRADER FAIL: " + f)
		quit(1)
