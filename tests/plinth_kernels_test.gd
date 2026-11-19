extends SceneTree

## Native plinth edges: godot --headless --path . --script tests/plinth_kernels_test.gd
## BuildingFoundation.plinth_arrays through PlinthKernels (native/,
## tools/build_native.sh) must give exactly the script's arrays: random
## footprints (convex and concave, either winding, some with holes and
## repeated corners), random ground tables, with and without tangents
## (batch mode), and the corner-and-midpoint list the ground is read at.
## Skips, passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("PlinthKernels"):
		print("PLINTH_KERNELS SKIP: PlinthKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var m := WorldScale.metres_to_units()
	var coped := 0
	var faced := 0
	for t in 400:
		# Every 7th footprint has two corners, every 11th one; every 4th hole too.
		var corners := 3 + rng.randi() % 12
		if t % 7 == 0:
			corners = 2
		elif t % 11 == 0:
			corners = 1
		var rings: Array = [_ring(rng, corners, 6.0 * m + rng.randf() * 30.0 * m,
			Vector2(rng.randf_range(-400.0, 400.0), rng.randf_range(-400.0, 400.0)), t % 5 == 0 and corners > 2)]
		for h in (t % 3):
			rings.append(_ring(rng, 1 + rng.randi() % 5 if t % 4 == 0 else 3 + rng.randi() % 5, 1.5 * m + rng.randf() * 3.0 * m,
				(rings[0] as PackedVector2Array)[0] * 0.9, false))
		var ccw := PackedByteArray()
		var grounds: Array = []
		var floor_y := rng.randf_range(-20.0, 60.0) * m
		for ri in rings.size():
			var ring: PackedVector2Array = rings[ri]
			if rng.randf() < 0.5:
				ring.reverse()
				rings[ri] = ring
			ccw.append(1 if RingGeometry.signed_area(ring) > 0.0 else 0)
			var g := PackedFloat64Array()
			for k in ring.size() * 2:
				# Mostly well under the floor (a face, often a coping), some within the gap.
				g.append(floor_y - rng.randf_range(-0.4, 5.0) * m)
			grounds.append(g)
		for ring_i in rings.size():
			if (rings[ring_i] as PackedVector2Array).size() != (grounds[ring_i] as PackedFloat64Array).size() / 2:
				failures.append("case %d: ground table size" % t)
		for tangents in [true, false]:
			var batch := MassBatch.new()
			BuildingBuilder._batch = null if tangents else batch
			var script_out := BuildingFoundation.plinth_arrays_script(rings, grounds, ccw, floor_y)
			var params := PackedFloat64Array([m, floor_y, BuildingFoundation.SINK_M, BuildingFoundation.EDGE_GAP_M,
				PlinthStyle.COPING_MIN_M, PlinthStyle.COPING_DEPTH_M, PlinthStyle.COPING_PROUD_M])
			var native_out: Array = ClassDB.class_call_static("PlinthKernels", "plinth", rings, grounds, ccw, params, tangents)
			BuildingBuilder._batch = null
			if var_to_bytes(script_out) != var_to_bytes(native_out):
				failures.append("case %d (%d rings, tangents %s): plinth arrays differ" % [t, rings.size(), tangents])
			if tangents:
				faced += 1 if not (script_out[0][4] as PackedInt32Array).is_empty() else 0
				coped += 1 if not (script_out[1][4] as PackedInt32Array).is_empty() else 0
		# plinth_arrays chooses the native loop and the script loop alike.
		BuildingFoundation._native_plinth = false
		var via_script := BuildingFoundation.plinth_arrays(rings, grounds, ccw, floor_y)
		BuildingFoundation._native_plinth = true
		var via_native := BuildingFoundation.plinth_arrays(rings, grounds, ccw, floor_y)
		if var_to_bytes(via_script) != var_to_bytes(via_native):
			failures.append("case %d: plinth_arrays differs between the script and the native loop" % t)
		var edge: PackedVector2Array = rings[0]
		if var_to_bytes(ClassDB.class_call_static("PlinthKernels", "edge_points", edge)) != var_to_bytes(BuildingFoundation._edge_points(edge)):
			failures.append("case %d: edge points differ" % t)
	_check_ground_table(failures, rng)
	if faced < 300 or coped < 200:
		failures.append("the cases barely exercise the kernel: %d with a face, %d with a coping" % [faced, coped])
	if failures.is_empty():
		print("PLINTH_KERNELS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("PLINTH_KERNELS FAIL: " + f)
		quit(1)

## The ground table (corners then midpoints) is the same list of grounds either
## way the points are made, where the shoreline sampler has none to read.
func _check_ground_table(failures: Array[String], rng: RandomNumberGenerator) -> void:
	var d := LocationData.new()
	d.grid_size = 64
	d.heights.resize(64 * 64)
	for z in 64:
		for x in 64:
			d.heights[z * 64 + x] = 20.0 + 0.5 * float(x) + rng.randf()
	d.water_level = -3.0
	var ground := GroundTruth.new(d)
	for n in [1, 2, 3, 7, 12]:
		var ring := _ring(rng, n, 30.0, Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-100.0, 100.0)), false)
		BuildingFoundation._native_plinth = false
		var want := BuildingFoundation._ground_table(ground, ring)
		BuildingFoundation._native_plinth = true
		var got := BuildingFoundation._ground_table(ground, ring)
		if want.size() != n * 2 or var_to_bytes(want) != var_to_bytes(got):
			failures.append("ground table of a %d-corner ring differs or has the wrong size" % n)
		var read_by_script: bool = ground.shoreline == null or not ground.shoreline.ready
		for k in (n if read_by_script else 0):
			if want[k] != BuildingFoundation._edge_ground(ground, ring[k]):
				failures.append("ground table corner %d of %d is not the ground there" % [k, n])
				break

## A star-shaped ring of `n` corners round `c`; `repeat` doubles one corner.
func _ring(rng: RandomNumberGenerator, n: int, radius: float, c: Vector2, repeat: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var r := radius * rng.randf_range(0.5, 1.0)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	if repeat:
		out.insert(1, out[0])
	return out
