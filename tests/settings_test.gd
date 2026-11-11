extends SceneTree

## Headless settings test: godot --headless --script tests/settings_test.gd
## Covers the render-quality presets: budgets rise with quality, the
## preset sizes the DEM grids, the choice persists, the settings screen
## applies it, and the FPS governor never exceeds the chosen ceiling.

func _init() -> void:
	RenderSettings.path_override = "user://settings-test-%d.json" % OS.get_process_id()
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

	# Ultra is the default preset for fresh desktop installs.
	if RenderSettings.new().preset != RenderSettings.Preset.ULTRA:
		failures.append("default preset should be Ultra on desktop")
	# Persistence round-trip, then restore the default for the device.
	var saved := RenderSettings.new()
	saved.set_preset(RenderSettings.Preset.HIGH)
	var reloaded := RenderSettings.new()
	reloaded.load_settings()
	if reloaded.preset != RenderSettings.Preset.HIGH:
		failures.append("preset should persist across instances")
	# A file saved before the Ultra default (no version) moves High to Ultra once.
	saved.save_settings({"preset": RenderSettings.Preset.HIGH, "preset_version": 0})
	var migrated := RenderSettings.new()
	migrated.load_settings()
	if migrated.preset != RenderSettings.Preset.ULTRA:
		failures.append("legacy High should migrate to Ultra")
	saved.set_preset(RenderSettings.Preset.HIGH)
	var kept := RenderSettings.new()
	kept.load_settings()
	if kept.preset != RenderSettings.Preset.HIGH:
		failures.append("High chosen after the migration should stay")

	# Appearance persists too, and saving the preset from a fresh
	# instance keeps it; the device's own choices are restored after.
	var device := RenderSettings.new()
	device.load_settings()
	saved.set_accent(3, true)
	saved.set_layout(2)
	RenderSettings.new().set_preset(RenderSettings.Preset.HIGH)
	var looks := RenderSettings.new()
	looks.load_settings()
	if looks.accent != 3 or not looks.accent_auto or looks.layout != 2:
		failures.append("accent/layout should persist, got %d/%s/%d"
			% [looks.accent, looks.accent_auto, looks.layout])
	device.set_accent(device.accent, device.accent_auto)
	device.set_layout(device.layout)

	# Data formatting from the design system.
	if UiTheme.cache_size(86 * 1048576) != "86 MB" \
			or UiTheme.cache_size(int(1.4 * 1073741824.0)) != "1.4 GB":
		failures.append("cache size should read 86 MB / 1.4 GB")
	var now := Time.get_unix_time_from_system()
	if not UiTheme.relative_time(now, now).begins_with("Today, ") \
			or UiTheme.relative_time(now - 86400.0, now) != "Yesterday":
		failures.append("relative time should read Today, hh:mm / Yesterday")
	if LocationData.known_place(10.0, -20.0) != "10.0000° N  20.0000° W":
		failures.append("unnamed points should use the coordinate format")

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
		var fast_posts := RenderSettings.terrain_mesh_posts_for(0)
		if (screen._specs["terrain"] as Readout).value_text() != "%d × %d" % [fast_posts, fast_posts]:
			failures.append("readouts should describe the Fast budget, got: %s" % (screen._specs["terrain"] as Readout).value_text())
		screen._preset_btns[3].pressed.emit()
		await process_frame
		if settings.preset != RenderSettings.Preset.ULTRA or announced != [0, 3]:
			failures.append("tapping Ultra should apply and announce it")
		var ultra_posts := RenderSettings.terrain_mesh_posts_for(3)
		if (screen._specs["terrain"] as Readout).value_text() != "%d × %d" % [ultra_posts, ultra_posts]:
			failures.append("readouts should describe the Ultra budget, got: %s" % (screen._specs["terrain"] as Readout).value_text())
		# T7.4: the tier shows its §3.1 wait in the Render quality row.
		if not screen.summary_for("quality").contains(RenderSettings.FIRST_BUILD[3]):
			failures.append("Ultra summary should state its ~1–2 min first build: %s" % screen.summary_for("quality"))
	if Array(RenderSettings.FIDELITY) != [1, 2, 2, 3]:
		failures.append("presets should map to PRD Fidelity 1/2/2/3")
	# T7.4: each preset card states its fidelity and first-build budget.
	for p in screen._preset_btns.size():
		var words: Array[String] = []
		for l in screen._preset_btns[p].find_children("*", "Label", true, false):
			words.append((l as Label).text)
		if not ("Fidelity %d" % RenderSettings.FIDELITY[p]) in words or not RenderSettings.FIRST_BUILD[p] in words:
			failures.append("preset %d card should state its fidelity and first-build budget: %s" % [p, words])
	# The governor reports reductions under the user's tier, never a tier of its own.
	if QualityGovernor.step_label(2, 2) != "High" or not QualityGovernor.step_label(2, 0).begins_with("High · 65% res"):
		failures.append("governor label should be the tier plus any reduction: %s / %s"
			% [QualityGovernor.step_label(2, 2), QualityGovernor.step_label(2, 0)])
	# Offline storage management: size is readable, label reports it.
	if screen._usage == null or not (screen.summary_for("storage").contains(" MB of ")
			or screen.summary_for("storage").contains(" GB of ")):
		failures.append("settings should report offline cache size")
	if OfflineDownloader.cache_size_bytes() < 0:
		failures.append("cache size should be readable")
	if OfflineDownloader.JOBS != 5:
		failures.append("offline download should cover DEM, far DEM, OSM, satellite and land cover")
	# Categories: phones open one page from the menu and step back to it;
	# wide windows show the rail beside the chosen page.
	screen.size = Vector2(390, 844)
	screen._on_resized()
	screen.step_back()
	if not screen._menu.visible or screen._rail.visible:
		failures.append("phone settings should open on the category menu")
	screen.open_category("units")
	if screen._menu.visible or not screen._pages["units"].visible or screen._pages["appearance"].visible:
		failures.append("a category should replace the menu on phones")
	if not screen.step_back() or not screen._menu.visible:
		failures.append("back on a phone page should return to the menu")
	screen.size = Vector2(1280, 800)
	screen._on_resized()
	if not screen._rail.visible or screen._menu.visible or not screen._pages["units"].visible:
		failures.append("desktop settings should show the rail beside the page")
	if screen.step_back():
		failures.append("desktop settings has no menu to step back to")
	screen.show_data_sources()
	if not screen._pages["sources"].visible or screen._pages["units"].visible:
		failures.append("the attribution should open Settings on Data sources")
	# Narrowing an open two-pane Settings keeps the page; Back from a
	# page opened by the attribution leaves Settings, not to a menu.
	screen.size = Vector2(390, 844)
	screen._on_resized()
	if screen._menu.visible or not screen._pages["sources"].visible:
		failures.append("narrowing Settings should keep the open page")
	if screen.step_back():
		failures.append("Back from the attribution's Data sources should leave Settings")
	screen.visible = false
	screen.visible = true
	if not screen._menu.visible:
		failures.append("each phone visit should start on the menu")
	# Wide never squeezes two panes into a phone-width window.
	screen._layout_index = 2
	screen._on_resized()
	if screen._rail.visible:
		failures.append("Wide should not force the rail into a phone-width window")
	screen._layout_index = 0
	screen.size = Vector2(1280, 800)
	screen._on_resized()
	if screen._grid.columns != 2:
		failures.append("desktop presets should sit in two columns")
	for item in screen._cat_items:
		if (item["summary"] as Label).text == "":
			failures.append("category %s should summarise its values" % item["id"])
	screen.queue_free()
	settings.set_preset(RenderSettings.Preset.HIGH)

	# Renderer features per tier: Ultra on Forward+ carries the full
	# light-transport set, Fast none; Mobile never asks for Forward+-only
	# effects; each tier's features include the tier below's.
	var ultra := RenderQuality.features_for(RenderSettings.Preset.ULTRA, true)
	for k in ["ssao", "ssil", "ssr", "sdfgi", "volumetric_fog", "taa"]:
		if not ultra[k]:
			failures.append("Ultra on Forward+ should enable %s" % k)
		for p in 4:
			if RenderQuality.features_for(p, false)[k]:
				failures.append("Mobile preset %d should not enable Forward+-only %s" % [p, k])
		if RenderQuality.features_for(RenderSettings.Preset.FAST, true)[k]:
			failures.append("Fast should not pay for %s" % k)
		for p in 3:
			if RenderQuality.features_for(p, true)[k] and not RenderQuality.features_for(p + 1, true)[k]:
				failures.append("%s on preset %d should stay on above it" % [k, p])
	if float(ultra["sun_angle"]) <= 0.0 or int(ultra["shadow_atlas"]) <= int(RenderQuality.features_for(2, true)["shadow_atlas"]):
		failures.append("Ultra should have a physical sun penumbra and a larger shadow map than High")
	if int(RenderQuality.features_for(RenderSettings.Preset.ULTRA, false)["shadow_atlas"]) > 4096:
		failures.append("Mobile shadow map should stay within 4096")
	# AC-12: the rig keeps ACES and the haze on every tier; Ultra's
	# volume takes the haze colour.
	var rig := AtmosphereRig.new(RenderSettings.Preset.ULTRA)
	for p in 4:
		rig.set_quality(p)
		if rig.environment.tonemap_mode != Environment.TONE_MAPPER_ACES or not rig.environment.fog_enabled:
			failures.append("preset %d should keep ACES and the exponential haze" % p)
	if not rig.environment.volumetric_fog_albedo.is_equal_approx(rig.haze_color):
		failures.append("volumetric fog should take the haze colour")
	rig.free()
	var fps_prefs := RenderSettings.new()
	if fps_prefs.pref("fps_counter") != false:
		failures.append("the FPS counter should default to off")
	fps_prefs.set_pref("fps_counter", true)
	if fps_prefs.pref("fps_counter") != true:
		failures.append("the FPS counter pref should round-trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RenderSettings.path_override))

	if failures.is_empty():
		print("SETTINGS OK: preset budgets, grid sizing, persistence, governor ceiling, settings screen")
		quit(0)
	else:
		for f in failures:
			printerr("SETTINGS FAIL: ", f)
		quit(1)
