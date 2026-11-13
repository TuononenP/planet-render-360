extends SceneTree

## Native building tints: godot --headless --path . --script tests/tint_kernels_test.gd
## WallVariety.colours and RoofVariety.weathered through TintKernels
## (native/, tools/build_native.sh) must give exactly the script's bytes:
## random walls with and without a foot, flat and pitched roofs, empty
## surfaces. Skips, passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("TintKernels"):
		print("TINT_KERNELS SKIP: TintKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for t in 120:
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		var lift := rng.randf_range(-30.0, 80.0)
		var span: float = [0.0, 0.2, 3.0, 60.0][t % 4]
		for i in rng.randi_range(0, 40):
			verts.append(Vector3(rng.randf_range(-500, 500), lift + rng.randf() * span, rng.randf_range(-500, 500)))
			normals.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized())
		var c := Color(rng.randf_range(0.5, 1.4), rng.randf_range(0.5, 1.4), rng.randf_range(0.5, 1.4), rng.randf())
		var foot: float = [INF, -INF, lift - rng.randf() * 5.0, lift + 2.0][t % 4]
		var ok := true
		for native in [true, false]:
			WallVariety._native = native
			var wall := WallVariety.colours(verts, c, foot)
			var wall_own := WallVariety.colours(verts, c)
			var roof := RoofVariety.weathered(verts, normals, c)
			if native:
				WallVariety._native = false
				ok = var_to_bytes(wall) == var_to_bytes(WallVariety.colours(verts, c, foot)) \
					and var_to_bytes(wall_own) == var_to_bytes(WallVariety.colours(verts, c)) \
					and var_to_bytes(roof) == var_to_bytes(RoofVariety.weathered(verts, normals, c))
				break
		if not ok:
			failures.append("case %d (%d vertices, span %.1f)" % [t, verts.size(), span])
	WallVariety._native = true
	if failures.is_empty():
		print("TINT_KERNELS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("TINT_KERNELS FAIL: " + f)
		quit(1)
