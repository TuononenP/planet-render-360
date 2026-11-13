extends SceneTree

## Native grid filters: godot --headless --path . --script tests/grid_filters_test.gd
## BareEarth's rank filter, dilation, box sum and relaxation, UrbanSmooth's
## box pass and GroundTruth's edge blur, through GridFilters (native/,
## tools/build_native.sh), must give exactly the script's bytes on random
## grids of several sizes and radii. Skips, passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("GridFilters"):
		print("GRID_FILTERS SKIP: GridFilters is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for t in 24:
		var size: int = [3, 7, 16, 41][t % 4]
		var r: int = [0, 1, 2, 5, 60][t % 5]
		var heights := PackedFloat32Array()
		var bits := PackedByteArray()
		var holes := PackedInt32Array()
		for i in size * size:
			heights.append(rng.randf_range(-20.0, 300.0))
			bits.append(1 if rng.randf() < 0.1 else 0)
			if rng.randf() < 0.3:
				holes.append(i)
		var out := {}
		for native in [true, false]:
			BareEarth._native = native
			out[native] = [BareEarth._rank_filter(heights, size, r, true), BareEarth._rank_filter(heights, size, r, false),
				BareEarth._dilate(bits, size, r), BareEarth._box_sum(heights, size, r, true),
				BareEarth._box_sum(heights, size, r, false), UrbanSmooth._box(heights, size, maxi(r, 1), true),
				UrbanSmooth._box(heights, size, maxi(r, 1), false), _relaxed(heights, holes, size),
				_blurred(heights, size)]
		for k in (out[true] as Array).size():
			if var_to_bytes(out[true][k]) != var_to_bytes(out[false][k]):
				failures.append("case %d (size %d, r %d): filter %d" % [t, size, r, k])
	BareEarth._native = true
	if failures.is_empty():
		print("GRID_FILTERS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("GRID_FILTERS FAIL: " + f)
		quit(1)

## GroundTruth._blur_pass into a fresh array.
func _blurred(heights: PackedFloat32Array, size: int) -> PackedFloat32Array:
	var dst := PackedFloat32Array()
	dst.resize(size * size)
	GroundTruth._blur_pass(heights, dst, size)
	return dst

## BareEarth.strip's relaxation alone, through its own branch.
func _relaxed(heights: PackedFloat32Array, holes: PackedInt32Array, size: int) -> PackedFloat32Array:
	if BareEarth._native:
		return ClassDB.class_call_static("GridFilters", "relax", heights, holes, size, BareEarth.SWEEPS)
	var filled := heights.duplicate()
	for _s in BareEarth.SWEEPS:
		for i in holes:
			var x := i % size
			@warning_ignore("integer_division")
			var z := i / size
			var sum := 0.0
			var n := 0
			if x > 0:
				sum += filled[i - 1]; n += 1
			if x < size - 1:
				sum += filled[i + 1]; n += 1
			if z > 0:
				sum += filled[i - size]; n += 1
			if z < size - 1:
				sum += filled[i + size]; n += 1
			filled[i] = sum / float(n)
	return filled
