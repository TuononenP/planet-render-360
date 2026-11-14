extends SceneTree

## Native landmark primitives: godot --headless --path . --script tests/landmark_kernels_test.gd
## LandmarkMesh.boxes through LandmarkKernels (native/, tools/build_native.sh)
## must give exactly box()'s bytes, one box at a time: sharp and chamfered,
## thin and thick, axis-aligned and rotated, scaled and degenerate bases.
## Skips, passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("LandmarkKernels"):
		print("LANDMARK_KERNELS SKIP: LandmarkKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var bases: Array[Basis] = [Basis(), Basis(Vector3.UP, 0.7), Basis(Vector3(1, 2, 3).normalized(), 1.3),
		Basis.from_scale(Vector3(2.0, 0.5, 1.5)) * Basis(Vector3.RIGHT, 0.4),
		Basis(Vector3.ZERO, Vector3.UP, Vector3.BACK)]
	for t in 60:
		var basis: Basis = bases[t % bases.size()]
		var bevel: float = [-1.0, 0.0, 0.05, 0.2][t % 4]
		var centers := PackedVector3Array()
		var sizes := PackedVector3Array()
		for i in rng.randi_range(0, 12):
			centers.append(Vector3(rng.randf_range(-900, 900), rng.randf_range(-20, 60), rng.randf_range(-900, 900)))
			sizes.append(Vector3(rng.randf_range(0.05, 4.0), rng.randf_range(0.0, 30.0), rng.randf_range(0.05, 4.0)))
		var script := LandmarkMesh.new()
		script.use("K", null)
		for i in centers.size():
			script.box("K", centers[i], sizes[i], basis, bevel)
		var native := LandmarkMesh.new()
		native.use("K", null)
		native.boxes("K", centers, sizes, basis, bevel)
		var a: LandmarkMesh.Surf = script._surfs["K"]
		var b: LandmarkMesh.Surf = native._surfs["K"]
		if var_to_bytes(a.v) != var_to_bytes(b.v) or var_to_bytes(a.n) != var_to_bytes(b.n) \
				or var_to_bytes(a.uv) != var_to_bytes(b.uv):
			failures.append("case %d (%d boxes, bevel %.2f)" % [t, centers.size(), bevel])
	if failures.is_empty():
		print("LANDMARK_KERNELS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("LANDMARK_KERNELS FAIL: " + f)
		quit(1)
