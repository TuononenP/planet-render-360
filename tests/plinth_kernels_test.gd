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
		var rings: Array = [_ring(rng, 3 + rng.randi() % 12, 6.0 * m + rng.randf() * 30.0 * m,
			Vector2(rng.randf_range(-400.0, 400.0), rng.randf_range(-400.0, 400.0)), t % 5 == 0)]
		for h in (t % 3):
			rings.append(_ring(rng, 3 + rng.randi() % 5, 1.5 * m + rng.randf() * 3.0 * m, (rings[0] as PackedVector2Array)[0] * 0.9, false))
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
		var edge: PackedVector2Array = rings[0]
		if var_to_bytes(ClassDB.class_call_static("PlinthKernels", "edge_points", edge)) != var_to_bytes(BuildingFoundation._edge_points(edge)):
			failures.append("case %d: edge points differ" % t)
	if faced < 300 or coped < 200:
		failures.append("the cases barely exercise the kernel: %d with a face, %d with a coping" % [faced, coped])
	if failures.is_empty():
		print("PLINTH_KERNELS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("PLINTH_KERNELS FAIL: " + f)
		quit(1)

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
