extends SceneTree

## Thunderstorm lightning (LightningRig + AtmosphereRig, offline, seeded):
## godot --headless --script tests/lightning_test.gd

const STEP := 1.0 / 30.0

func _storm(code: int, season: int, daylight: float, seconds: float, seed: int) -> LightningRig:
	var l := LightningRig.new()
	l.seed_rng(seed)
	l.set_conditions(WeatherLook.for_code(code, 100.0), season, daylight, RenderSettings.Preset.HIGH, 1e-4)
	var t := 0.0
	while t < seconds:
		l.step(STEP)
		t += STEP
	return l

func _init() -> void:
	var failures: Array[String] = []
	var orphans_before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var summer := LocationData.Season.SUMMER

	# Only thunderstorms strike.
	for code in [0, 3, 45, 61, 71]:
		var calm := _storm(code, summer, 0.0, 120.0, 1)
		if calm.active or calm.strike_count > 0:
			failures.append("code %d should never strike (%d)" % [code, calm.strike_count])
		calm.free()

	# Storm strength and season set the rate.
	var storm := _storm(95, summer, 0.0, 600.0, 7)
	var hail := _storm(99, summer, 0.0, 600.0, 7)
	var winter := _storm(95, LocationData.Season.WINTER, 0.0, 600.0, 7)
	if storm.strike_count < 10:
		failures.append("code 95 should strike regularly, got %d in 10 min" % storm.strike_count)
	if hail.strike_count <= storm.strike_count:
		failures.append("hail storm (99) should strike more than 95: %d vs %d" % [hail.strike_count, storm.strike_count])
	if winter.strike_count >= storm.strike_count:
		failures.append("winter storms should strike less: %d vs summer %d" % [winter.strike_count, storm.strike_count])
	if storm.ground_strikes == 0 or storm.ground_strikes >= storm.strike_count:
		failures.append("a storm should mix cloud and ground strikes: %d of %d" % [storm.ground_strikes, storm.strike_count])
	if float(winter.ground_strikes) / maxf(winter.strike_count, 1) >= float(storm.ground_strikes) / storm.strike_count:
		failures.append("thundersnow should be mostly in-cloud")
	# Photosensitivity: never more than 3 distinct flashes in a second.
	for l in [storm, hail, winter]:
		if l.max_flashes_per_s > 3 or l.max_flashes_per_s < 1:
			failures.append("flash rate %d/s outside 1..3" % l.max_flashes_per_s)
	storm.free()
	hail.free()
	winter.free()

	# Flashes dominate the night and stay modest by day.
	var night := _storm(95, summer, 0.0, 0.0, 3)
	var day := _storm(95, summer, 1.0, 0.0, 3)
	night.force_strike(false)
	day.force_strike(false)
	if not (night.flash_energy > day.flash_energy * 3.0 and day.flash_energy > 0.0):
		failures.append("night flash should outshine day: %f vs %f" % [night.flash_energy, day.flash_energy])
	if not night.light.visible or night.flash_dir.y <= 0.0:
		failures.append("flash light should shine down from the cloud")
	# The strike ends: light off, level back to zero.
	for i in 120:
		night.step(STEP)
	if night.flash_level > 0.0 or night.light.visible:
		failures.append("flash should die out after the strike")
	night.free()
	day.free()

	# Bolts by tier: none on the lowest, a forked channel on High.
	for preset in [RenderSettings.Preset.FAST, RenderSettings.Preset.BALANCED, RenderSettings.Preset.HIGH]:
		var l := LightningRig.new()
		l.seed_rng(5)
		l.set_conditions(WeatherLook.for_code(95, 100.0), summer, 0.0, preset, 1e-4)
		l.force_strike(true)
		var verts := 0
		if l.bolt.mesh != null:
			verts = (l.bolt.mesh as ArrayMesh).surface_get_array_len(0)
		if preset == RenderSettings.Preset.FAST and (l.bolt_visible or verts > 0):
			failures.append("lowest tier must not draw a bolt")
		if preset != RenderSettings.Preset.FAST and (not l.bolt_visible or verts == 0):
			failures.append("tier %d ground strike should draw a bolt" % preset)
		if preset == RenderSettings.Preset.HIGH and verts <= (2 ** LightningRig.MAIN_DEPTH) * 6:
			failures.append("High bolt should carry forks (%d verts)" % verts)
		l.free()

	# Rig wiring: a storm lights the sky shader; clearing stops it.
	var rig := AtmosphereRig.new()
	rig.set_time(23.0)
	rig.set_weather(95, 100.0)
	if not rig.lightning.active:
		failures.append("thunderstorm weather should arm the lightning")
	rig.lightning.force_strike(false)
	rig._process(0.016)
	if float(rig.sky_material.get_shader_parameter("flash")) <= 0.0:
		failures.append("a flash should light the clouds")
	rig.set_weather(0, 10.0)
	if rig.lightning.active or float(rig.sky_material.get_shader_parameter("flash")) != 0.0:
		failures.append("clear weather should disarm the lightning and clear the flash")
	rig.free()

	var leaked := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) - orphans_before
	if leaked > 0:
		failures.append("%d orphan nodes left behind" % leaked)
	if failures.is_empty():
		print("LIGHTNING OK: storms only, rate by strength/season, flash ≤3/s, day vs night, bolts by tier, sky wiring")
		quit(0)
	else:
		for f in failures:
			printerr("LIGHTNING FAIL: ", f)
		quit(1)
