extends SceneTree

## Headless verification for volumetric haze & god-rays (Feature A):
##   tools/godot_bg.sh --headless --path . --script tests/haze_test.gd
## Covers:
##   1) Preset & renderer gate (Ultra desktop Forward+ only; default auto-on,
##      explicit user preference respected and persisted).
##   2) Display-path invariant (haze OFF restores the exact world container
##      visibility and render_target_update_mode, disabling post viewports).
##   3) QualityGovernor step-down order (haze drops rays -> haze off BEFORE
##      render scale or shadows are reduced, and recovers last).
##   4) Sun projection, weather/solar intensity curve, ease rate (including
##      reduce_motion), and AtmosphereRig.set_haziness unification.
##   5) SettingsScreen UI toggle state across preset switches.

var _failures: Array[String] = []

func _init() -> void:
	RenderSettings.path_override = "user://settings-haze-test-%d.json" % OS.get_process_id()
	_run.call_deferred()

func _run() -> void:
	_test_preset_gate()
	_test_projection_and_curve()
	_test_atmosphere_driver()
	_test_governor_order()
	await _test_display_path_and_ease()
	await _test_settings_ui()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RenderSettings.path_override))
	if _failures.is_empty():
		print("HAZE OK: Ultra gate, governor step-down order, display-path restore, sun projection, settings UI")
		quit(0)
	else:
		for f in _failures:
			printerr("HAZE FAIL: ", f)
		quit(1)

func _test_preset_gate() -> void:
	for p in [RenderSettings.Preset.FAST, RenderSettings.Preset.BALANCED, RenderSettings.Preset.HIGH]:
		if RenderSettings.haze_allowed(p, true) or HazeRig.supported_for(p, true):
			_failures.append("preset %d should not allow haze on Forward+" % p)
	if RenderSettings.haze_allowed(RenderSettings.Preset.ULTRA, false):
		_failures.append("Mobile renderer should not allow Ultra haze pass")
	if not RenderSettings.haze_allowed(RenderSettings.Preset.ULTRA, true):
		_failures.append("Ultra on Forward+ should allow haze")
	var s := RenderSettings.new()
	if s.pref("haze") != null or not s.haze_pref():
		_failures.append("fresh settings should default haze to null (auto -> true)")
	s.set_pref("haze", false)
	var s2 := RenderSettings.new()
	s2.load_settings()
	if s2.haze_pref():
		_failures.append("haze=false should persist across reload")
	s2.set_pref("haze", true)
	var s3 := RenderSettings.new()
	s3.load_settings()
	if not s3.haze_pref():
		_failures.append("haze=true should persist across reload")

func _test_projection_and_curve() -> void:
	var cam := Camera3D.new()
	cam.fov = 75.0
	root.add_child(cam)
	cam.global_transform = Transform3D.IDENTITY  # faces -Z (north)
	# Sun dead ahead along -Z -> UV (0.5, 0.5), full facing.
	var ahead := HazeRig.project_sun(cam, 16.0 / 9.0, Vector3(0.0, 0.0, -1.0))
	if (ahead["uv"] as Vector2).distance_to(Vector2(0.5, 0.5)) > 0.002 or float(ahead["facing"]) < 0.99:
		_failures.append("sun dead ahead should project to (0.5, 0.5) with facing ~1, got %s" % str(ahead))
	# Sun above horizon in front -> UV.y < 0.5 (upper half of screen).
	var high_front := HazeRig.project_sun(cam, 16.0 / 9.0, Vector3(0.0, 0.35, -0.936).normalized())
	if (high_front["uv"] as Vector2).y >= 0.5:
		_failures.append("sun above camera axis should project into upper half (uv.y < 0.5), got %s" % str(high_front))
	# Sun behind camera (+Z) -> facing == 0.
	var behind := HazeRig.project_sun(cam, 16.0 / 9.0, Vector3(0.0, 0.2, 0.98).normalized())
	if float(behind["facing"]) != 0.0:
		_failures.append("sun behind camera should have 0 facing weight, got %s" % str(behind))
	cam.free()

	# Intensity curve: night / below horizon and overcast kill rays; golden hour peaks.
	var night := HazeRig.sky_weights(-8.0, 10.0, 20000.0)
	if float(night["rays"]) != 0.0 or float(night["haziness"]) != 0.0:
		_failures.append("night should zero rays and haziness, got %s" % str(night))
	var overcast := HazeRig.sky_weights(12.0, 95.0, 20000.0)
	if float(overcast["rays"]) > 0.001:
		_failures.append("95%% overcast should kill direct shafts, got %s" % str(overcast))
	var golden := HazeRig.sky_weights(12.0, 20.0, 20000.0)
	var noon := HazeRig.sky_weights(65.0, 20.0, 20000.0)
	if float(golden["rays"]) < 0.8 or float(golden["rays"]) <= float(noon["rays"]):
		_failures.append("golden hour should produce stronger shafts than high noon (%s vs %s)" % [golden, noon])
	var dense_fog := HazeRig.sky_weights(12.0, 20.0, 200.0)
	if float(dense_fog["rays"]) > 0.05 or float(dense_fog["haziness"]) < 0.4:
		_failures.append("200 m visibility fog should suppress crisp shafts while keeping haziness: %s" % str(dense_fog))

func _test_atmosphere_driver() -> void:
	var rig := AtmosphereRig.new(RenderSettings.Preset.ULTRA)
	rig.set_place(48.8566, 2.3522)
	rig.set_time(17.2)
	var base_e := rig.environment.fog_light_energy
	var base_sc := rig.environment.fog_sun_scatter
	var base_th := rig.environment.glow_hdr_threshold
	var base_gi := rig.environment.glow_intensity
	var base_vd := rig.environment.volumetric_fog_density
	rig.set_haziness(1.0)
	if rig.environment.fog_light_energy <= base_e \
			or rig.environment.fog_sun_scatter <= base_sc \
			or rig.environment.glow_hdr_threshold < PostGrade.GLOW_THRESHOLD \
			or rig.environment.glow_intensity <= base_gi \
			or rig.environment.volumetric_fog_density <= base_vd:
		_failures.append("set_haziness(1.0) should thicken fog, sun scatter and volume while keeping glow_hdr_threshold >= 1.0")
	# The glow's per-pixel cap stays low: uncapped, the sun's reflection on a
	# glossy bonnet bloomed into a white blaze across the car and the road.
	if rig.environment.glow_hdr_luminance_cap > 2.0:
		_failures.append("glow_hdr_luminance_cap must stay at or under 2.0 (sun glints on glossy paint blazed)")
	rig.set_haziness(0.0)
	if not is_equal_approx(rig.environment.fog_light_energy, base_e) \
			or not is_equal_approx(rig.environment.fog_sun_scatter, base_sc) \
			or not is_equal_approx(rig.environment.glow_hdr_threshold, base_th) \
			or not is_equal_approx(rig.environment.glow_intensity, base_gi) \
			or not is_equal_approx(rig.environment.volumetric_fog_density, base_vd):
		_failures.append("set_haziness(0.0) must restore exact PostGrade/AtmosphereRig baseline")
	rig.free()

func _test_governor_order() -> void:
	var gov := QualityGovernor.new()
	var vp := SubViewport.new()
	var sun := DirectionalLight3D.new()
	var haze := HazeRig.new()
	root.add_child(vp)
	root.add_child(sun)
	root.add_child(haze)
	gov.viewport = vp
	gov.sun = sun
	gov.haze = haze
	gov.set_preset(RenderSettings.Preset.ULTRA)
	gov.set_haze_ceiling(2)
	haze.set_enabled(true)
	haze.set_conditions(12.0, 180.0, 20.0, 20000.0)
	if gov.step != 3 or gov.haze_step != 2:
		_failures.append("Ultra with haze should start at step=3, haze_step=2")
	# 1st slow window: drops rays only (haze_step 2 -> 1), keeping step=3 (full res + shadows).
	gov.step = gov.adapt(20.0)
	gov._apply()
	if gov.step != 3 or gov.haze_step != 1 or haze.governor_step != 1 or haze.pass_active or gov.at_ceiling():
		_failures.append("1st slow window must drop rays only and report below ceiling (step=%d haze_step=%d pass=%s)" % [
			gov.step, gov.haze_step, haze.pass_active])
	if QualityGovernor.step_label(3, gov.step, gov.haze_step, gov.haze_ceiling) != "Ultra · no rays":
		_failures.append("unexpected 1st step-down label: %s" % QualityGovernor.step_label(3, gov.step, gov.haze_step, gov.haze_ceiling))
	# 2nd slow window: drops thickened haze (haze_step 1 -> 0), still keeping step=3.
	gov.step = gov.adapt(20.0)
	gov._apply()
	if gov.step != 3 or gov.haze_step != 0 or haze.governor_step != 0:
		_failures.append("2nd slow window must drop haze before render scale (step=%d haze_step=%d)" % [gov.step, gov.haze_step])
	# 3rd slow window: now render scale steps down (step 3 -> 2).
	gov.step = gov.adapt(20.0)
	gov._apply()
	if gov.step != 2:
		_failures.append("3rd slow window should step render scale 3 -> 2, got %d" % gov.step)
	# Recovery past hold: step 2 -> 3 recovers BEFORE haze_step climbs 0 -> 1 -> 2.
	for _i in 60:
		gov.step = gov.adapt(90.0)
		if gov.step == 3 and gov.haze_step == 0:
			break
	if gov.step != 3 or gov.haze_step != 0:
		_failures.append("render scale should recover to step 3 before haze re-enables (step=%d haze=%d)" % [gov.step, gov.haze_step])
	for _i in 200:
		gov.step = gov.adapt(90.0)
	if gov.step != 3 or gov.haze_step != 2 or not gov.at_ceiling():
		_failures.append("healthy GPU should eventually recover full haze_step=2 at ceiling (step=%d haze=%d)" % [gov.step, gov.haze_step])
	haze.free()
	sun.free()
	vp.free()
	gov.free()

func _test_display_path_and_ease() -> void:
	var holder := Control.new()
	holder.size = Vector2(640, 360)
	root.add_child(holder)
	var wc := SubViewportContainer.new()
	wc.set_anchors_preset(Control.PRESET_FULL_RECT)
	wc.stretch = true
	holder.add_child(wc)
	var wvp := SubViewport.new()
	wc.add_child(wvp)
	var cam := Camera3D.new()
	wvp.add_child(cam)
	var atmos := AtmosphereRig.new(RenderSettings.Preset.ULTRA)
	atmos.set_place(48.8566, 2.3522)
	atmos.set_time(17.2)
	wvp.add_child(atmos)
	var orig_mode := wvp.render_target_update_mode

	var haze := HazeRig.new()
	holder.add_child(haze)
	haze.attach_view(wvp, wc, cam, atmos)
	await process_frame

	# Fast/Balanced/High keep exact original display path.
	UiPrefs.haze = true
	for p in [RenderSettings.Preset.FAST, RenderSettings.Preset.BALANCED, RenderSettings.Preset.HIGH]:
		haze.sync_gate(p, null, true)
		if haze.enabled or haze.pass_active or not wc.visible or wvp.render_target_update_mode != orig_mode:
			_failures.append("preset %d altered display path" % p)

	# Ultra on Forward+ activates post pass and eases smoothly (no instant snap to 1).
	var sun_dir := SolarPosition.direction(atmos.solar_elevation, atmos.solar_azimuth)
	cam.look_at(cam.global_position + sun_dir, Vector3.UP)
	UiPrefs.reduce_motion = false
	haze.sync_gate(RenderSettings.Preset.ULTRA, null, true)
	haze._process(1.0 / 60.0)
	if not haze.pass_active or not wc.visible or not haze.overlay.visible:
		_failures.append("Ultra haze should activate additive overlay while keeping world container intact")
	if haze.ray_amount <= 0.0 or haze.ray_amount >= 0.5:
		_failures.append("first 60 Hz tick should ease ray_amount gradually, got %f" % haze.ray_amount)

	# Reduce motion eases more gently per tick.
	var normal_step := haze.ray_amount
	haze.set_enabled(false)
	UiPrefs.reduce_motion = true
	haze.sync_gate(RenderSettings.Preset.ULTRA, null, true)
	haze._process(1.0 / 60.0)
	if haze.ray_amount >= normal_step:
		_failures.append("reduce_motion should ease slower (%f vs %f)" % [haze.ray_amount, normal_step])
	UiPrefs.reduce_motion = false

	# Live governor step-down (2 -> 1 while ray_amount > 0) eases out smoothly
	# instead of snapping off on frame 1, then disables rays_vp once settled.
	for _i in 10:
		haze._process(1.0 / 60.0)
	var mid_rays := haze.ray_amount
	haze.set_governor_step(1)
	if not haze.pass_active or haze.ray_amount <= 0.0:
		_failures.append("governor step-down with live rays must ease out, not snap off on frame 1")
	haze._process(1.0 / 60.0)
	if haze.ray_amount >= mid_rays or haze.ray_amount <= 0.0:
		_failures.append("governor step-down should step ray_amount down gradually (%f -> %f)" % [mid_rays, haze.ray_amount])
	for _i in 60:
		haze._process(1.0 / 60.0)
	if haze.pass_active or haze.rays_vp.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_failures.append("once eased to 0 under governor step 1, rays_vp must disable")
	# The ray quad lives in its own 3D world: sharing the city's, it stood in
	# the street at the world origin as a black panel.
	if not haze.rays_vp.own_world_3d:
		_failures.append("rays_vp needs its own 3D world, or the ray quad shows in the city at the origin")
	haze.set_governor_step(2)
	haze._process(1.0 / 60.0)

	# Off-screen pause: hiding the parent view disables rays_vp immediately,
	# and showing it resumes cleanly.
	holder.visible = false
	await process_frame
	if haze.pass_active or haze.rays_vp.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_failures.append("hiding parent view must pause rays_vp off-screen")
	holder.visible = true
	await process_frame
	if not haze.pass_active or haze.rays_vp.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		_failures.append("showing parent view again must resume rays_vp")

	# Looking >90 deg away from the sun eases ray_amount to 0 and disables rays_vp.
	cam.look_at(cam.global_position - sun_dir, Vector3.UP)
	for _i in 60:
		haze._process(1.0 / 60.0)
	if haze.pass_active or haze.rays_vp.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_failures.append("looking away from the sun should disable rays_vp once eased out")

	# Turning haze off restores exact pre-feature display state.
	haze.set_enabled(false)
	if haze.pass_active or not wc.visible or haze.overlay.visible \
			or wvp.render_target_update_mode != orig_mode \
			or haze.rays_vp.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_failures.append("disabling haze failed to restore original world viewport display state")

	holder.free()

func _test_settings_ui() -> void:
	var s := RenderSettings.new()
	s.preset = RenderSettings.Preset.HIGH
	UiPrefs.apply(s)
	var screen := SettingsScreen.new()
	screen.bind_settings(s)
	var events: Array = []
	screen.viewer_pref_changed.connect(func(k: String, v: Variant) -> void: events.append([k, v]))
	root.add_child(screen)
	await process_frame
	var btn := screen._toggles.get("haze") as Button
	if btn == null:
		_failures.append("Settings Render quality page should include the haze toggle")
		screen.free()
		return
	if not btn.disabled or btn.button_pressed:
		_failures.append("High preset should show haze toggle disabled and unchecked")
	if RenderQuality.is_forward_plus():
		screen._preset_btns[RenderSettings.Preset.ULTRA].pressed.emit()
		await process_frame
		if btn.disabled or not btn.button_pressed:
			_failures.append("Ultra on Forward+ should enable and check haze toggle by default")
		btn.toggled.emit(false)
		if s.haze_pref() or UiPrefs.haze or events.is_empty():
			_failures.append("toggling haze off on Ultra should update RenderSettings, UiPrefs and emit signal")
	screen.free()
