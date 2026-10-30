extends SceneTree

## Headless settings test: godot --headless --script tests/settings_test.gd
## Covers the render-quality presets: budgets rise with quality, the
## preset sizes the DEM grids, the choice persists, the settings screen
## applies it, and the FPS governor never exceeds the chosen ceiling.

func _init() -> void:
	_run()

func _flat_data(preset_value: int, building_count: int) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset_value)
	data.grid_size = 8  # small grid for a fast build; preset checked separately
	data.heights.resize(64)
	for i in 64:
		data.heights[i] = 3.0
	data.far_heights = PackedFloat32Array()
	data.water_level = -3.0
	data.seed_value = 42
	for i in building_count:
		data.buildings.append({
			"x": -100.0 + float(i % 20) * 10.0, "z": -100.0 + float(i / 20) * 10.0,
			"size_x": 4.0, "size_z": 4.0, "height": 10.0, "name": "t"})
	return data

func _run() -> void:
	var failures: Array[String] = []

	# Budgets strictly rise Fast < Balanced < High < Ultra; clamping is safe.
	for values in [
			[RenderSettings.terrain_mesh_posts_for(0), RenderSettings.terrain_mesh_posts_for(1), RenderSettings.terrain_mesh_posts_for(2), RenderSettings.terrain_mesh_posts_for(3)],
			[RenderSettings.max_buildings_for(0), RenderSettings.max_buildings_for(1), RenderSettings.max_buildings_for(2), RenderSettings.max_buildings_for(3)],
			[RenderSettings.vegetation_count_for(0, false), RenderSettings.vegetation_count_for(1, false), RenderSettings.vegetation_count_for(2, false), RenderSettings.vegetation_count_for(3, false)]]:
		if not (values[0] < values[1] and values[1] < values[2] and values[2] < values[3]):
			failures.append("budgets should rise with quality, got %s" % str(values))
	if RenderSettings.clamp_preset(-5) != 0 or RenderSettings.clamp_preset(99) != 3:
		failures.append("preset clamping failed")
	if RenderSettings.shadows_for(0) or not RenderSettings.shadows_for(1):
		failures.append("only Fast should disable shadows")
	if not (RenderSettings.render_scale_for(0) < RenderSettings.render_scale_for(2)):
		failures.append("render scale should rise with quality")
	if not (RenderSettings.render_scale_for(3) > RenderSettings.render_scale_for(2)):
		failures.append("Ultra should supersample above High render scale")
	if not (RenderSettings.shadow_distance_for(3) > RenderSettings.shadow_distance_for(2)):
		failures.append("Ultra shadows should reach farther than High")
	if not (RenderSettings.shadow_blur_for(3) < RenderSettings.shadow_blur_for(2)):
		failures.append("Ultra shadows should be sharper than High")
	if RenderSettings.preset_name(3) != "Ultra":
		failures.append("preset 3 should be Ultra")

	# T7.0/T7.1 (AC-12): the DEM/GroundTruth and far grids are preset-
	# independent (every object sits on the same surface on every
	# preset); only the terrain mesh density is a per-preset LOD.
	var sized := LocationData.new()
	for p in [0, 1, 2, 3]:
		RenderSettings.apply_preset(sized, p)
		if sized.grid_size != RenderSettings.GROUND_POSTS or sized.far_grid_size != 128 \
				or sized.quality_preset != p:
			failures.append("preset %d should size %d/128 grids, got %d/%d"
				% [p, RenderSettings.GROUND_POSTS, sized.grid_size, sized.far_grid_size])

	# High is the default preset for fresh installs.
	if RenderSettings.new().preset != RenderSettings.Preset.HIGH:
		failures.append("default preset should be High")
	# Persistence round-trip, then restore the default for the device.
	var saved := RenderSettings.new()
	saved.set_preset(RenderSettings.Preset.HIGH)
	var reloaded := RenderSettings.new()
	reloaded.load_settings()
	if reloaded.preset != RenderSettings.Preset.HIGH:
		failures.append("preset should persist across instances")
	saved.set_preset(RenderSettings.Preset.HIGH)

	# The governor honours the ceiling in both directions.
	var governor := QualityGovernor.new()
	var viewport := SubViewport.new()
	var sun := DirectionalLight3D.new()
	root.add_child(viewport)
	root.add_child(sun)
	governor.viewport = viewport
	governor.sun = sun
	governor.set_preset(RenderSettings.Preset.FAST)
	if governor.step != 0 or governor.ceiling_step != 0:
		failures.append("Fast should cap the governor at step 0")
	if absf(viewport.scaling_3d_scale - RenderSettings.render_scale_for(0)) > 0.001:
		failures.append("Fast render scale not applied, got %f" % viewport.scaling_3d_scale)
	if sun.shadow_enabled:
		failures.append("Fast should disable shadows")
	governor.set_preset(RenderSettings.Preset.HIGH)
	if governor.step != 2 or not sun.shadow_enabled:
		failures.append("High should restore step 2 with shadows")
	governor.set_preset(RenderSettings.Preset.ULTRA)
	if governor.step != 3 or governor.ceiling_step != 3 or not sun.shadow_enabled:
		failures.append("Ultra should cap the governor at step 3 with shadows")
	if absf(viewport.scaling_3d_scale - RenderSettings.render_scale_for(3)) > 0.001:
		failures.append("Ultra render scale not applied, got %f" % viewport.scaling_3d_scale)
	governor.free()
	sun.free()
	viewport.free()

	# Building budget: Fast builds fewer meshes than High from the
	# same 400-building input, and Ultra builds the most.
	var fast_world := TerrainBuilder.build_world(_flat_data(RenderSettings.Preset.FAST, 400))
	var high_world := TerrainBuilder.build_world(_flat_data(RenderSettings.Preset.HIGH, 400))
	var ultra_world := TerrainBuilder.build_world(_flat_data(RenderSettings.Preset.ULTRA, 400))
	if fast_world.get_child_count() >= high_world.get_child_count():
		failures.append("Fast should build fewer nodes than High (%d vs %d)" % [
			fast_world.get_child_count(), high_world.get_child_count()])
	if high_world.get_child_count() >= ultra_world.get_child_count():
		failures.append("Ultra should build more nodes than High (%d vs %d)" % [
			ultra_world.get_child_count(), high_world.get_child_count()])
	fast_world.free()
	high_world.free()
	ultra_world.free()

	# Settings screen: tapping a preset applies, saves, and announces it.
	var settings := RenderSettings.new()
	settings.preset = RenderSettings.Preset.BALANCED
	var screen := SettingsScreen.new()
	screen.bind_settings(settings)
	var announced: Array[int] = []
	screen.preset_changed.connect(func(p: int) -> void: announced.append(p))
	root.add_child(screen)
	await process_frame
	await process_frame
	if screen._preset_btns.size() != 4:
		failures.append("settings screen should offer 4 presets")
	else:
		screen._preset_btns[0].pressed.emit()
		await process_frame
		if settings.preset != RenderSettings.Preset.FAST or announced != [0]:
			failures.append("tapping Fast should apply and announce it")
		if not screen._preset_btns[0].button_pressed or screen._preset_btns[1].button_pressed:
			failures.append("only the chosen preset button should stay pressed")
		if not screen._summary_label.text.contains("%d×" % RenderSettings.terrain_mesh_posts_for(0)):
			failures.append("summary should describe the Fast budget, got: %s" % screen._summary_label.text)
		screen._preset_btns[3].pressed.emit()
		await process_frame
		if settings.preset != RenderSettings.Preset.ULTRA or announced != [0, 3]:
			failures.append("tapping Ultra should apply and announce it")
		if not screen._summary_label.text.contains("%d×" % RenderSettings.terrain_mesh_posts_for(3)):
			failures.append("summary should describe the Ultra budget, got: %s" % screen._summary_label.text)
		# T7.4: the tier shows its PRD fidelity level and §3.1 wait.
		if not (screen._summary_label.text.contains("Fidelity 3") and screen._summary_label.text.contains(RenderSettings.FIRST_BUILD[3])):
			failures.append("Ultra summary should state Fidelity 3 and its ~1–2 min first build: %s" % screen._summary_label.text)
	if Array(RenderSettings.FIDELITY) != [1, 2, 2, 3]:
		failures.append("presets should map to PRD Fidelity 1/2/2/3")
	for p in 4:
		if not RenderSettings.PRESET_BLURBS[p].begins_with("Fidelity %d" % RenderSettings.FIDELITY[p]) \
				or not RenderSettings.PRESET_BLURBS[p].contains(RenderSettings.FIRST_BUILD[p]):
			failures.append("preset %d copy should state its fidelity and first-build budget" % p)
	# The governor reports reductions under the user's tier, never a tier of its own.
	if QualityGovernor.step_label(2, 2) != "High" or not QualityGovernor.step_label(2, 0).begins_with("High · 65% res"):
		failures.append("governor label should be the tier plus any reduction: %s / %s"
			% [QualityGovernor.step_label(2, 2), QualityGovernor.step_label(2, 0)])
	# Offline storage management: size is readable, label reports it.
	if screen._storage_label == null or not screen._storage_label.text.contains("MB"):
		failures.append("settings should report offline cache size")
	if OfflineDownloader.cache_size_bytes() < 0:
		failures.append("cache size should be readable")
	if OfflineDownloader.JOBS != 4:
		failures.append("offline download should cover DEM, far DEM, OSM, satellite")
	screen.queue_free()
	settings.set_preset(RenderSettings.Preset.HIGH)

	if failures.is_empty():
		print("SETTINGS OK: preset budgets, grid sizing, persistence, governor ceiling, settings screen")
		quit(0)
	else:
		for f in failures:
			printerr("SETTINGS FAIL: ", f)
		quit(1)
