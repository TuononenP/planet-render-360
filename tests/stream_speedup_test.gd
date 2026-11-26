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
	_test_governor_pause_down()
	_test_impostor_rasterize_parity()
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

func _test_governor_pause_down() -> void:
	var gov := QualityGovernor.new()
	var vp := SubViewport.new()
	gov.viewport = vp
	gov.set_preset(RenderSettings.Preset.ULTRA)
	var busy := [true]
	gov.pause_down = func() -> bool: return busy[0]
	for _i in 20:
		gov._process(0.25)  # 4 FPS while streaming/saving busy
	_check(gov.step == RenderSettings.Preset.ULTRA and gov.effects_step == QualityGovernor.EFFECTS_MAX,
		"QualityGovernor must not step down while pause_down is true")
	busy[0] = false
	for _i in 6:
		gov._process(0.25)  # 1.5 s inside BUSY_SETTLE_S (2.0 s)
	_check(gov.step == RenderSettings.Preset.ULTRA and gov.effects_step == QualityGovernor.EFFECTS_MAX,
		"QualityGovernor must hold Ultra through BUSY_SETTLE_S cooldown")
	gov.free()
	vp.free()

func _test_impostor_rasterize_parity() -> void:
	if not ClassDB.class_exists(&"FarKernels"):
		return
	var verts := PackedVector3Array([
		Vector3(-4, 0, -2), Vector3(4, 0, -2), Vector3(0, 12, 0),
		Vector3(4, 0, -2), Vector3(4, 0, 2), Vector3(0, 12, 0),
		Vector3(-4, 0, 2), Vector3(4, 0, 2), Vector3(0, 12, 0),
	])
	var batches := [{
		"v": verts, "n": PackedVector3Array(), "idx": PackedInt32Array(),
		"color": Color(0.75, 0.55, 0.40), "cols": PackedColorArray(),
	}]
	var center := Vector3(0, 6, 0)
	var key_dir := LandmarkImpostor.RELIEF_KEY.normalized()
	var native_views: Array = FarKernels.rasterize_impostor_views(
		batches, center, 12.4, 12.8, 8.4, 4.4, key_dir, 64)
	_check(native_views.size() == 4, "FarKernels.rasterize_impostor_views returns 4 views")
	var normals: Array[Vector3] = [
		Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
	var rights: Array[Vector3] = [
		Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1)]
	var widths: Array[float] = [8.4, 4.4, 8.4, 4.4]
	for vi in 4:
		var nv: PackedByteArray = native_views[vi]
		var non_zero := 0
		for p in range(3, nv.size(), 4):
			if nv[p] == 255:
				non_zero += 1
		_check(non_zero > 200, "impostor view %d has solid silhouette (%d px)" % [vi, non_zero])
		# Also verify full-size bake matches GDScript _rasterize_view closely.
	var full_nv: PackedByteArray = FarKernels.rasterize_impostor_views(
		batches, center, 12.4, 12.8, 8.4, 4.4, key_dir, LandmarkImpostor.SIZE)[0]
	var full_gd := LandmarkImpostor._rasterize_view(
		batches, center, 12.4, 12.8, normals[0], rights[0], widths[0] * 0.5, key_dir)
	var diff_px := 0
	for i in range(0, full_gd.size(), 4):
		if absi(int(full_nv[i]) - int(full_gd[i])) > 1 or absi(int(full_nv[i + 3]) - int(full_gd[i + 3])) > 0:
			diff_px += 1
	_check(diff_px <= 16, "native impostor rasterizer matches GDScript (diff_px=%d)" % diff_px)
