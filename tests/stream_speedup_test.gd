extends SceneTree

## Verifies 300 km/h Ultra streaming speedup & coastal terrain fixes:
##   tools/godot_bg.sh --headless --path . --script tests/stream_speedup_test.gd

var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	_test_postpass_promote()
	_test_fast_cooldown()
	_test_scout_notes()
	_test_reveal_wave_meta()
	_test_far_kernels()
	_test_coastal_terrain_mesh()
	_test_suggest_high_prompt()
	if _failures.is_empty():
		print("STREAM SPEEDUP PASS")
		quit(0)
	else:
		for f in _failures:
			printerr("STREAM SPEEDUP FAIL: ", f)
		quit(1)

func _test_postpass_promote() -> void:
	PostpassGate.reset()
	var blocker := Node.new()
	var warm_pipe := Node.new()
	warm_pipe.set_meta(PostpassGate.LOW_META, true)
	var warm_child := Node.new()
	warm_pipe.add_child(warm_child)
	var other_low := Node.new()
	other_low.set_meta(PostpassGate.LOW_META, true)
	var order: Array[String] = []
	PostpassGate.enter(blocker, func() -> void: order.append("blocker"), func(_r: String) -> void: pass)
	PostpassGate.hold_low()
	PostpassGate.enter(other_low, func() -> void: order.append("other_low"), func(_r: String) -> void: pass)
	PostpassGate.enter(warm_child, func() -> void: order.append("warm"), func(_r: String) -> void: pass, true)
	warm_pipe.set_meta(PostpassGate.LOW_META, false)
	PostpassGate.promote_subtree(warm_pipe)
	PostpassGate.leave(blocker)
	_check(PostpassGate.waiting() >= 1, "queue preserves non-promoted low entry")
	PostpassGate.leave_subtree(warm_pipe)
	PostpassGate.leave(other_low)
	blocker.free()
	warm_pipe.free()
	other_low.free()
	PostpassGate.reset()

func _test_fast_cooldown() -> void:
	var st := StreamSteering.new()
	st.note_drop(83.0)
	_check(absf(st.cooldown_s - StreamSteering.FAST_DROP_COOLDOWN_S) < 0.001,
		"300 km/h drop uses short FAST_DROP_COOLDOWN_S")
	st.tick_cooldown(StreamSteering.FAST_DROP_COOLDOWN_S + 0.05)
	_check(not st.cooling_down(false), "fast cooldown clears quickly")
	st.note_drop(10.0)
	_check(absf(st.cooldown_s - StreamSteering.DROP_COOLDOWN_S) < 0.001,
		"low-speed drop keeps standard DROP_COOLDOWN_S")

func _test_scout_notes() -> void:
	var sc := StreamScout.new()
	var ll := Vector2(60.17, 24.94)
	_check(sc.start_note(ll, true, false, true) == ", adopted fetch ahead",
		"adopted warm pipeline logs adopted note")
	_check(sc.take_warm(ll) == null, "take_warm returns null when no warm pipeline runs")

func _test_reveal_wave_meta() -> void:
	var bld := MeshInstance3D.new()
	bld.name = "LodCell_0_0_0"
	bld.set_meta("lod_layer", "Buildings")
	var fc := MeshInstance3D.new()
	fc.name = "FarCity_0"
	fc.set_meta("lod_layer", "FarCity")
	var veg := MeshInstance3D.new()
	veg.name = "VegTrees_0"
	veg.set_meta("lod_layer", "Vegetation")
	var prop := MeshInstance3D.new()
	prop.name = "StreetLamps"
	prop.set_meta("lod_layer", "Props")
	_check(WorldHandoff._reveal_wave(bld) == 0, "Buildings show immediately on swap frame")
	_check(WorldHandoff._reveal_wave(fc) == 1, "FarCity staggers into wave 1 via lod_layer")
	_check(WorldHandoff._reveal_wave(veg) == 2, "Vegetation staggers into wave 2 via lod_layer")
	_check(WorldHandoff._reveal_wave(prop) == 3, "Props stagger into wave 3 via lod_layer")
	bld.free()
	fc.free()
	veg.free()
	prop.free()

func _test_far_kernels() -> void:
	if not ClassDB.class_exists("FarKernels"):
		_check(false, "FarKernels native class not loaded")
		return
	var idx_skirt: PackedInt32Array = ClassDB.class_call_static("FarKernels", "band_indices", 4, 8, true)
	_check(idx_skirt.size() == (3 * 8 + 8) * 6, "band_indices with skirt has exact length")
	var idx_no: PackedInt32Array = ClassDB.class_call_static("FarKernels", "band_indices", 4, 8, false)
	_check(idx_no.size() == 3 * 8 * 6, "band_indices without skirt has exact length")
	var verts := PackedVector3Array([Vector3(100, 0, -200), Vector3(-50, 10, 300)])
	var fine := {"zoom": 13, "origin_px": Vector2(1000.0, 2000.0), "size_px": Vector2i(512, 512)}
	var uv_res: Array = ClassDB.class_call_static("FarKernels", "band_drape_uvs", verts,
		{"lat": 60.17, "lon": 24.94, "m2u": 1.0}, fine, {})
	var data := LocationData.new()
	data.latitude = 60.17
	data.longitude = 24.94
	for i in verts.size():
		var muv := FarSurface.merc_uv(data, verts[i].x, verts[i].z)
		var expected := FarSurface.drape_uv_uv(fine, muv.x, muv.y)
		var got: Vector2 = (uv_res[0] as PackedVector2Array)[i]
		_check(got.distance_to(expected) < 1e-5, "band_drape_uvs matches FarSurface at %d" % i)

func _test_coastal_terrain_mesh() -> void:
	# Exercises TerrainBuilder._terrain_mesh with shore == true and has_sat == true
	# so ShoreDomains.native + FarKernels.terrain_grid_sat are verified end-to-end.
	var data := LocationData.new()
	data.latitude = 60.1724
	data.longitude = 24.9321
	data.quality_preset = RenderSettings.Preset.ULTRA
	data.grid_size = 16
	data.heights.resize(16 * 16)
	for z in 16:
		for x in 16:
			data.heights[z * 16 + x] = -1.0 if x < 8 else 5.0
	data.water_level = 0.0
	data.land_polygons = [{
		"class": "water",
		"tidal": true,
		"points": PackedVector2Array([
			Vector2(-1200, -1200), Vector2(0, -1200), Vector2(0, 1200), Vector2(-1200, 1200)
		]),
		"holes": [],
	}]
	var sat_img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	sat_img.fill(Color(0.3, 0.5, 0.3))
	data.satellite_image = sat_img
	data.satellite_texture = ImageTexture.create_from_image(sat_img)
	data.satellite_zoom = 17
	data.satellite_source = {"source_zoom": 17, "source_span": 3}
	var ground := GroundTruth.new(data)
	_check(ground.shoreline != null and ground.shoreline.ready, "coastal fixture built ready shoreline")
	_check(ground.shoreline.domains != null and ground.shoreline.domains.native != null,
		"ShoreDomains exposes native ShoreDomainIndex")
	var terrain := TerrainBuilder._terrain_mesh(data, ground)
	_check(terrain != null and terrain.name == "Terrain" and terrain.mesh != null,
		"coastal _terrain_mesh built Terrain MeshInstance3D cleanly")
	if terrain != null:
		terrain.free()

func _test_suggest_high_prompt() -> void:
	var gov := QualityGovernor.new()
	var hits := [0]
	gov.suggest_high.connect(func() -> void: hits[0] += 1)
	gov.set_preset(RenderSettings.Preset.ULTRA)
	for i in QualityGovernor.SLOW_SUGGEST_WINDOWS - 1:
		gov.adapt(20.0)
	_check(hits[0] == 0, "brief slow windows do not suggest High yet")
	gov.adapt(60.0)  # healthy window resets consecutive counter
	for i in QualityGovernor.SLOW_SUGGEST_WINDOWS - 1:
		gov.adapt(20.0)
	_check(hits[0] == 0, "counter reset after healthy window")
	gov.adapt(20.0)
	_check(hits[0] == 1, "sustained low FPS on Ultra emits suggest_high once")
	gov.adapt(20.0)
	_check(hits[0] == 1, "suggest_high does not repeat in the same session")
	gov.set_preset(RenderSettings.Preset.HIGH)
	for i in QualityGovernor.SLOW_SUGGEST_WINDOWS + 2:
		gov.adapt(20.0)
	_check(hits[0] == 1, "High preset never emits suggest_high")
	gov.free()
