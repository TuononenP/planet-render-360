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

	# Budgets strictly rise Fast < Balanced < High; clamping is safe.
	for values in [
			[RenderSettings.grid_size_for(0), RenderSettings.grid_size_for(1), RenderSettings.grid_size_for(2)],
			[RenderSettings.max_buildings_for(0), RenderSettings.max_buildings_for(1), RenderSettings.max_buildings_for(2)],
			[RenderSettings.vegetation_count_for(0, false), RenderSettings.vegetation_count_for(1, false), RenderSettings.vegetation_count_for(2, false)]]:
		if not (values[0] < values[1] and values[1] < values[2]):
			failures.append("budgets should rise with quality, got %s" % str(values))
	if RenderSettings.clamp_preset(-5) != 0 or RenderSettings.clamp_preset(99) != 2:
		failures.append("preset clamping failed")
	if RenderSettings.shadows_for(0) or not RenderSettings.shadows_for(1):
		failures.append("only Fast should disable shadows")
	if not (RenderSettings.render_scale_for(0) < RenderSettings.render_scale_for(2)):
		failures.append("render scale should rise with quality")

	# The preset sizes the grids the pipeline fetches/builds.
	var sized := LocationData.new()
	RenderSettings.apply_preset(sized, RenderSettings.Preset.FAST)
	if sized.grid_size != 32 or sized.far_grid_size != 32 or sized.quality_preset != 0:
		failures.append("Fast should size 32x32 grids, got %d/%d" % [sized.grid_size, sized.far_grid_size])
	RenderSettings.apply_preset(sized, RenderSettings.Preset.HIGH)
	if sized.grid_size != 64 or sized.far_grid_size != 64:
		failures.append("High should size 64x64 grids, got %d" % sized.grid_size)

	# Persistence round-trip, then restore the default for the device.
	var saved := RenderSettings.new()
	saved.set_preset(RenderSettings.Preset.HIGH)
	var reloaded := RenderSettings.new()
	reloaded.load_settings()
	if reloaded.preset != RenderSettings.Preset.HIGH:
		failures.append("preset should persist across instances")
	saved.set_preset(RenderSettings.Preset.BALANCED)

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
	governor.free()
	sun.free()
	viewport.free()

	# Building budget: Fast builds fewer meshes than High from the
	# same 400-building input.
	var fast_world := TerrainBuilder.build_world(_flat_data(RenderSettings.Preset.FAST, 400))
	var high_world := TerrainBuilder.build_world(_flat_data(RenderSettings.Preset.HIGH, 400))
	if fast_world.get_child_count() >= high_world.get_child_count():
		failures.append("Fast should build fewer nodes than High (%d vs %d)" % [
			fast_world.get_child_count(), high_world.get_child_count()])
	fast_world.free()
	high_world.free()

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
	if screen._preset_btns.size() != 3:
		failures.append("settings screen should offer 3 presets")
	else:
		screen._preset_btns[0].pressed.emit()
		await process_frame
		if settings.preset != RenderSettings.Preset.FAST or announced != [0]:
			failures.append("tapping Fast should apply and announce it")
		if not screen._preset_btns[0].button_pressed or screen._preset_btns[1].button_pressed:
			failures.append("only the chosen preset button should stay pressed")
		if not screen._summary_label.text.contains("32"):
			failures.append("summary should describe the Fast budget, got: %s" % screen._summary_label.text)
	screen.queue_free()
	settings.set_preset(RenderSettings.Preset.BALANCED)

	if failures.is_empty():
		print("SETTINGS OK: preset budgets, grid sizing, persistence, governor ceiling, settings screen")
		quit(0)
	else:
		for f in failures:
			printerr("SETTINGS FAIL: ", f)
		quit(1)
