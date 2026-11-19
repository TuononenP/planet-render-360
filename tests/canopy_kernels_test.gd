extends SceneTree

## Native far-canopy probes: godot --headless --path . --script tests/canopy_kernels_test.gd
## FarCanopy._probes_native (CanopyKernels, native/, tools/build_native.sh)
## must give exactly the script's probes: random drapes (one or two, the
## finest first, some probes past their edge), random cells at every step
## distance, places at several latitudes, thresholds and budgets. Skips,
## passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("CanopyKernels"):
		print("CANOPY_KERNELS SKIP: CanopyKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var kept_total := 0
	for t in 24:
		var data := LocationData.new()
		data.latitude = rng.randf_range(-60.0, 65.0)
		data.longitude = rng.randf_range(-170.0, 170.0)
		# The last cases: either pole's edge (the latitude clamp), then a place whose
		# drapes are one that is no image, one that is mipmapped RGBA, or none.
		if t == 20:
			data.latitude = 84.99
		elif t == 21:
			data.latitude = -84.99
		data.far_drapes = []
		if t == 22:
			data.far_drapes.append({"zoom": 15, "origin_px": Vector2.ZERO, "size_px": Vector2i(64, 64),
				"texture": null, "image": null, "reach_m": 1000.0})
		for k in (0 if t == 23 else 1 + (t % 2)):
			var zoom := 14 + k + (t % 3)
			var size := Vector2i(rng.randi_range(200, 420), rng.randi_range(200, 420))
			var rgba := t % 4 == 3
			var img := Image.create(size.x, size.y, rgba, Image.FORMAT_RGBA8 if rgba else Image.FORMAT_RGB8)
			for y in size.y:
				for x in size.x:
					var v := rng.randf_range(0.05, 0.6)
					img.set_pixel(x, y, Color(v * rng.randf_range(0.6, 1.0), v, v * rng.randf_range(0.5, 1.0)))
			# The drape covers the place, so most probes land on it; the
			# finest (k = 0) is smaller, so some fall to the second or past both.
			var centre := FarSurface.global_px(data, 0.0, 0.0, zoom)
			var cover := Vector2(size) * (0.5 if k == 0 else 1.0)
			data.far_drapes.append({"zoom": zoom, "origin_px": centre - cover, "size_px": size,
				"texture": null, "image": img, "reach_m": 5000.0})
		var bytes := SettlementMap.drape_bytes(data)
		var cells: Array = []
		for c in 120:
			var centre := Vector2(rng.randf_range(-6000.0, 6000.0), rng.randf_range(-6000.0, 6000.0))
			cells.append([centre, centre.length()])
		cells.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))
		var dark := rng.randf_range(0.2, 0.5)
		for budget in [0, 37, 100000]:
			var want := FarCanopy._probes_script(data, bytes, cells, dark, budget)
			var got := FarCanopy._probes_native(data, bytes, cells, dark, budget)
			kept_total += (want["x"] as PackedFloat64Array).size()
			for key in ["x", "z", "rgb", "widen"]:
				if var_to_bytes(want[key]) != var_to_bytes(got[key]):
					failures.append("case %d, budget %d: %s differs (%d against %d probes)" % [t, budget, key,
						(want["x"] as PackedFloat64Array).size(), (got["x"] as PackedFloat64Array).size()])
	if kept_total < 1500:
		failures.append("the cases barely exercise the kernel: %d probes kept" % kept_total)
	if failures.is_empty():
		print("CANOPY_KERNELS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("CANOPY_KERNELS FAIL: " + f)
		quit(1)
