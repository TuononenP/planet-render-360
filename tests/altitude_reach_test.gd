extends SceneTree

## Headless: godot --headless --script tests/altitude_reach_test.gd
## Altitude reach: the boost turns on at 300 m and off below 250 m, only
## after healthy governor windows and never during a hold after a slow
## one; boosted LOD rings reach at least as far as the preset's own and
## still rise with the preset; the boosted far terrain has denser rings;
## a data copy keeps every field but the preset.

var _failures: Array[String] = []

func _init() -> void:
	_test_hysteresis()
	_test_gpu_gate()
	_test_rings()
	_test_far()
	if _failures.is_empty():
		print("ALTITUDE REACH OK: hysteresis, GPU gate and hold, wider rings, denser far terrain")
		quit(0)
	else:
		for f in _failures:
			printerr("ALTITUDE REACH FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _test_hysteresis() -> void:
	_check(not AltitudeReach.wants_boost(299.0, false), "off below 300 m")
	_check(AltitudeReach.wants_boost(300.0, false), "on at 300 m")
	_check(AltitudeReach.wants_boost(260.0, true), "stays on above 250 m")
	_check(not AltitudeReach.wants_boost(249.0, true), "off below 250 m")

func _test_gpu_gate() -> void:
	var r := AltitudeReach.new()
	r.window(60.0, true)
	_check(not r.gpu_ok, "one healthy window is not enough")
	r.window(60.0, true)
	_check(r.gpu_ok, "two healthy windows open the gate")
	r.window(20.0, true)
	_check(not r.gpu_ok, "a slow window closes the gate")
	for i in 5:
		r.window(60.0, true)
	_check(not r.gpu_ok, "held off for HOLD_S after a slow window")
	for i in int(AltitudeReach.HOLD_S / QualityGovernor.WINDOW_S):
		r.window(60.0, true)
	_check(r.gpu_ok, "the gate reopens after the hold")
	r.window(60.0, false)
	_check(not r.gpu_ok, "a governor below its ceiling closes the gate")
	var r2 := AltitudeReach.new()
	r2.window(40.0, true)
	r2.window(40.0, true)
	_check(not r2.gpu_ok, "middling fps never opens the gate")
	var r3 := AltitudeReach.new()
	r3.window(60.0, true)
	r3.window(45.0, true)
	r3.window(60.0, true)
	_check(not r3.gpu_ok, "healthy windows must come in a row")
	r3.window(60.0, true)
	_check(r3.gpu_ok, "two in a row open the gate")
	r3.window(45.0, true)
	_check(r3.gpu_ok, "middling fps keeps an open gate")
	r3.window(AltitudeReach.KEEP_FPS - 5.0, true)
	_check(not r3.gpu_ok, "fps under KEEP_FPS closes the gate")
	var r4 := AltitudeReach.new()
	r4.window(60.0, true)
	r4.window(60.0, true)
	r4.reset(null, false)
	_check(not r4.gpu_ok, "a preset change closes the gate")
	r4.window(60.0, true)
	_check(not r4.gpu_ok, "the new preset needs its own healthy windows")

func _test_rings() -> void:
	var base: Array = []
	for p in 4:
		base.append([LodRing.detail_m(p), LodRing.trees_m(p), LodRing.far_city_m(p)])
	LodRing.altitude_boost = true
	for p in 4:
		var b: Array = base[p]
		_check(LodRing.detail_m(p) >= b[0] and LodRing.trees_m(p) >= b[1]
			and LodRing.far_city_m(p) >= b[2], "boosted rings reach at least preset %d's" % p)
		if p < 3:
			_check(LodRing.detail_m(p) <= LodRing.detail_m(p + 1)
				and LodRing.trees_m(p) <= LodRing.trees_m(p + 1), "boosted rings rise with the preset")
	_check(LodRing.detail_m(RenderSettings.Preset.ULTRA) > float(base[3][0]), "Ultra's detail ring widens")
	var veg := MeshInstance3D.new()
	veg.mesh = BoxMesh.new()
	LodRing.apply_vegetation(veg, RenderSettings.Preset.FAST)
	_check(is_equal_approx(veg.visibility_range_end, LodRing.TREES_M_ALT[0]), "tree swaps range with the boost")
	veg.free()
	LodRing.altitude_boost = false
	_check(is_equal_approx(LodRing.detail_m(0), base[0][0]), "boost off restores the preset's rings")

func _far_data(preset: int) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	var n := data.grid_size
	data.heights.resize(n * n)
	for z in n:
		for x in n:
			data.heights[z * n + x] = 3.0 + 4.0 * sin(float(x) * 0.05)
	data.water_level = -3.0
	data.latitude = 46.0
	data.longitude = 8.0
	var g := data.far_grid_size
	data.far_heights.resize(g * g)
	for z in g:
		for x in g:
			data.far_heights[z * g + x] = 200.0 + 300.0 * sin(float(x) * 0.3) * cos(float(z) * 0.2)
	data.far_centre_frac = Vector2(0.5, 0.5)
	return data

static func _verts(node: Node) -> int:
	var n := 0
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var m := (node as MeshInstance3D).mesh
		for s in m.get_surface_count():
			n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for c in node.get_children():
		n += _verts(c)
	return n

func _test_far() -> void:
	var preset := RenderSettings.Preset.BALANCED
	var data := _far_data(preset)
	var copy := AltitudeReach.data_at(data, AltitudeReach.far_preset(preset))
	_check(copy.quality_preset == RenderSettings.Preset.HIGH, "Balanced builds the boosted far at High")
	_check(copy.far_heights == data.far_heights and copy.latitude == data.latitude
		and copy.far_grid_size == data.far_grid_size, "the copy keeps the place's data")
	_check(data.quality_preset == preset, "the copy leaves the original's preset")
	_check(AltitudeReach.far_preset(RenderSettings.Preset.ULTRA) == RenderSettings.Preset.ULTRA,
		"Ultra keeps its own far preset")
	for p in 4:
		_check(AltitudeReach.far_segs(p) > FarTerrainBuilder.RING_SEGS[p], "denser far rings on preset %d" % p)
	var ground := GroundTruth.new(data)
	var plain := FarTerrainBuilder.build_far(data, ground)
	var dense := FarTerrainBuilder.build_far(data, ground, null, AltitudeReach.far_segs(preset))
	var a := _verts(plain)
	var b := _verts(dense)
	_check(a > 0, "the fixture builds far rings")
	_check(b > a, "boosted far terrain has more vertices (%d vs %d)" % [b, a])
	_check(dense.name == "FarTerrain", "the boosted far keeps the FarTerrain name")
	plain.free()
	dense.free()
