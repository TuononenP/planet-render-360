extends SceneTree

## Headless fountain water shader, geometry kit & flagship landmark tests:
## tools/godot_bg.sh --headless --path . --script tests/fountain_water_test.gd

var failures: Array[String] = []

func _init() -> void:
	_test_shaders_and_materials()
	_test_fountain_kit()
	_test_upgrade_presets_and_idempotency()
	_test_flagship_landmarks()
	_test_impostor_skips_spray_and_keeps_water_color()
	if failures.is_empty():
		print("FOUNTAIN WATER PASS")
		quit(0)
	else:
		for msg in failures:
			printerr("FOUNTAIN WATER FAIL: ", msg)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)

func _test_shaders_and_materials() -> void:
	_check(FountainWater.basin_shader() == FountainWater.basin_shader(), "basin shader deduplicated via SharedShader")
	_check(FountainWater.flow_shader() == FountainWater.flow_shader(), "flow shader deduplicated via SharedShader")
	_check(FountainWater.foam_shader() == FountainWater.foam_shader(), "foam shader deduplicated via SharedShader")
	_check(FountainWater.mist_shader() == FountainWater.mist_shader(), "mist shader deduplicated via SharedShader")
	_check(FountainWater.basin_shader().code.contains("climate_water_ice"), "basin shader includes climate_water_ice")
	_check(FountainWater.flow_shader().code.contains("climate_water_ice"), "flow shader includes climate_water_ice")
	_check(FountainWater.foam_shader().code.contains("climate_water_ice"), "foam shader includes climate_water_ice")
	_check(FountainWater.mist_shader().code.contains("climate_water_ice"), "mist shader includes climate_water_ice")
	var pw := LandmarkMaterials.pool_water("#2C8A96", 0.06)
	_check(pw is StandardMaterial3D, "pool_water stays StandardMaterial3D base for backward compat")
	_check(pw.has_meta(FountainWater.BASIN_META), "pool_water carries fountain_basin metadata")
	_check(str(pw.get_meta("landmark_hex", "")) == "#2C8A96", "pool_water preserves landmark_hex")
	var bm1 := FountainWater.basin_material("#2C8A96", 0.06, RenderSettings.Preset.ULTRA)
	var bm2 := FountainWater.basin_material("#2C8A96", 0.06, RenderSettings.Preset.ULTRA)
	_check(bm1 == bm2, "basin_material caches shared ShaderMaterial per key")
	_check(int(bm1.get_shader_parameter("water_quality")) == 2, "Ultra basin uses water_quality=2")
	var bm_bal := FountainWater.basin_material("#2C8A96", 0.06, RenderSettings.Preset.BALANCED)
	_check(int(bm_bal.get_shader_parameter("water_quality")) == 1, "Balanced basin uses water_quality=1")

func _test_fountain_kit() -> void:
	var fk := FountainKit.new()
	_check(fk.is_empty(), "new FountainKit starts empty")
	fk.jet_plume(Vector3(0.0, 1.0, 0.0), 3.0, 0.14, 0.42)
	fk.arc_stream(Vector3(0.0, 2.0, 0.0), Vector3(2.5, 0.5, 0.0), 0.7)
	fk.bowl_curtain(Vector3.ZERO, 2.0, 3.0, 0.5, 0.5)
	fk.cascade_sheet(Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 0.0), 2.5, 0.5, Vector3.BACK)
	fk.splash_ring(Vector3(2.5, 0.5, 0.0), 1.2)
	fk.splash_strip(Vector3(-3.0, 0.5, 0.5), Vector3(3.0, 0.5, 0.5), Vector3.BACK, 1.5)
	fk.mist_emitter(Vector3(0.0, 0.8, 0.0), 1.8, 1.1, 4)
	_check(not fk.is_empty(), "populated FountainKit is non-empty")
	var host := Node3D.new()
	var nodes := fk.commit(host)
	_check(nodes.size() == 3, "commit emits Flow, Foam and Mist nodes (got %d)" % nodes.size())
	var flow := host.get_node_or_null("FountainFlow") as MeshInstance3D
	var foam := host.get_node_or_null("FountainFoam") as MeshInstance3D
	var mist := host.get_node_or_null("FountainMist") as MultiMeshInstance3D
	_check(flow != null and flow.mesh != null and flow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"FountainFlow built with shadows disabled")
	_check(foam != null and foam.mesh != null and foam.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"FountainFoam built with shadows disabled")
	_check(mist != null and mist.multimesh != null and mist.multimesh.instance_count == 4,
		"FountainMist built with 4 billboard instances")
	_check(bool(flow.get_meta(FountainWater.IMPOSTOR_SKIP_META, false)), "FountainFlow tagged impostor_skip")
	_check(bool(foam.get_meta(FountainWater.IMPOSTOR_SKIP_META, false)), "FountainFoam tagged impostor_skip")
	_check(bool(mist.get_meta(FountainWater.IMPOSTOR_SKIP_META, false)), "FountainMist tagged impostor_skip")
	host.free()

func _test_upgrade_presets_and_idempotency() -> void:
	var low_hero := LandmarkBuilder.build("trevi_fountain")
	var low_n := FountainWater.upgrade(low_hero, RenderSettings.Preset.FAST)
	_check(low_n == 0, "Fast preset leaves basin StandardMaterial3D untouched (got %d)" % low_n)
	var low_mist := _find_by_name(low_hero, "FountainMist") as MultiMeshInstance3D
	_check(low_mist != null and not low_mist.visible, "Fast preset hides FountainMist")
	low_hero.free()

	var bal_hero := LandmarkBuilder.build("trevi_fountain")
	var bal_n := FountainWater.upgrade(bal_hero, RenderSettings.Preset.BALANCED)
	_check(bal_n >= 1, "Balanced preset upgrades Trevi basin water (got %d)" % bal_n)
	var bal_mist := _find_by_name(bal_hero, "FountainMist") as MultiMeshInstance3D
	_check(bal_mist != null and not bal_mist.visible, "Balanced preset hides FountainMist")
	bal_hero.free()

	var ultra_hero := LandmarkBuilder.build("trevi_fountain")
	var u1 := FountainWater.upgrade(ultra_hero, RenderSettings.Preset.ULTRA)
	var u2 := FountainWater.upgrade(ultra_hero, RenderSettings.Preset.ULTRA)
	_check(u1 >= 1, "Ultra preset upgrades Trevi basin water (got %d)" % u1)
	_check(u2 == 0, "FountainWater.upgrade is idempotent on repeat call (got %d)" % u2)
	var ultra_mist := _find_by_name(ultra_hero, "FountainMist") as MultiMeshInstance3D
	_check(ultra_mist != null and ultra_mist.visible, "Ultra preset enables FountainMist")
	# Ensure LandmarkShader.upgrade respects basin override and still weathers stone.
	var stone_n := LandmarkShader.upgrade(ultra_hero)
	_check(stone_n >= 2, "LandmarkShader still upgrades Trevi stone/marble after FountainWater.upgrade")
	ultra_hero.free()

func _test_flagship_landmarks() -> void:
	var types := [
		"trevi_fountain", "piazza_navona", "st_peters_basilica",
		"spanish_steps", "piazza_del_popolo", "pantheon_rome", "altare_della_patria",
		"place_de_la_concorde", "fontaine_de_varsovie", "louvre_pyramid",
		"fondation_louis_vuitton", "trafalgar_square", "havis_amanda", "bethesda_fountain",
	]
	for t in types:
		var hero := LandmarkBuilder.build(t)
		var upgraded := FountainWater.upgrade(hero, RenderSettings.Preset.ULTRA)
		_check(upgraded >= 1, "%s should have animated basin water (upgraded=%d)" % [t, upgraded])
		var flow := _find_by_name(hero, "FountainFlow") as MeshInstance3D
		var foam := _find_by_name(hero, "FountainFoam") as MeshInstance3D
		_check(flow != null and flow.mesh != null, "%s should have FountainFlow geometry" % t)
		_check(foam != null and foam.mesh != null, "%s should have FountainFoam geometry" % t)
		hero.free()

func _test_impostor_skips_spray_and_keeps_water_color() -> void:
	var hero := LandmarkBuilder.build("place_de_la_concorde")
	var surfs: Array = LandmarkImpostor._extract_surfaces(hero)
	var found_water := false
	for s in surfs:
		var c: Color = s["color"]
		if c.b > c.r * 1.15:
			found_water = true
	_check(found_water, "Impostor surface extraction preserves blue-teal basin water color")
	var baked := LandmarkImpostor.bake(hero, 0.0)
	_check(bool(baked.get("ok", false)), "LandmarkImpostor bakes upgraded Concorde cleanly")
	hero.free()
	var sh_mat := FountainWater.basin_material("#2C8A96", 0.06, RenderSettings.Preset.ULTRA)
	var col_info := LandmarkImpostor._surface_color(sh_mat)
	_check((col_info["color"] as Color).is_equal_approx(Color("#2C8A96")),
		"LandmarkImpostor._surface_color reads landmark_hex from ShaderMaterial")

func _find_by_name(root: Node, target: String) -> Node:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name == target:
			return n
		stack.append_array(n.get_children())
	return null
