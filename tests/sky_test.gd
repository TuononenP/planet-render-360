extends SceneTree

## Sky per season and time of day (AtmosphereRig, offline):
## godot --headless --script tests/sky_test.gd

func _init() -> void:
	var failures: Array[String] = []
	var rig := AtmosphereRig.new()

	# Summer 17:00 is the PRD golden-hour reference and must not drift.
	rig.set_season(LocationData.Season.SUMMER)
	rig.set_time(17.0)
	if not rig.sky_top_color.is_equal_approx(Color(0.44, 0.62, 0.82)):
		failures.append("summer 17:00 zenith drifted: %s" % rig.sky_top_color)
	if absf(-rig.sun.rotation_degrees.x - 12.42) > 0.05:
		failures.append("summer 17:00 sun should sit ~12.4° up, got %f" % -rig.sun.rotation_degrees.x)

	# Seasons: lower winter noon sun, distinct sky hues.
	var noon_elev := {}
	var noon_zenith := {}
	for season in [LocationData.Season.SPRING, LocationData.Season.SUMMER,
			LocationData.Season.AUTUMN, LocationData.Season.WINTER]:
		rig.set_season(season)
		rig.set_time(12.0)
		noon_elev[season] = -rig.sun.rotation_degrees.x
		noon_zenith[season] = rig.sky_top_color
	if not (noon_elev[LocationData.Season.WINTER] < noon_elev[LocationData.Season.SPRING]
			and noon_elev[LocationData.Season.SPRING] < noon_elev[LocationData.Season.SUMMER]):
		failures.append("noon sun should climb winter < spring < summer: %s" % noon_elev)
	if noon_zenith[LocationData.Season.WINTER].is_equal_approx(noon_zenith[LocationData.Season.SUMMER]) \
			or noon_zenith[LocationData.Season.AUTUMN].is_equal_approx(noon_zenith[LocationData.Season.SUMMER]):
		failures.append("winter/autumn noon sky should differ from summer")

	# Day / twilight / night phases.
	rig.set_season(LocationData.Season.SUMMER)
	rig.set_time(12.0)
	if rig.night_amount > 0.0 or rig.twilight_amount > 0.01:
		failures.append("noon should have no stars or twilight bands")
	rig.set_time(18.0)
	if rig.twilight_amount < 0.5:
		failures.append("18:00 should be in twilight, got %f" % rig.twilight_amount)
	rig.set_time(0.0)
	if rig.night_amount < 0.99:
		failures.append("midnight should show the full night sky, got %f" % rig.night_amount)
	var night_lum := rig.sky_top_color.get_luminance()
	for season in [LocationData.Season.WINTER, LocationData.Season.SPRING]:
		rig.set_season(season)
		if absf(rig.sky_top_color.get_luminance() - night_lum) > 0.02:
			failures.append("season tint must not brighten the night zenith (season %d)" % season)

	# Season shapes the cloud deck and haze.
	rig.set_season(LocationData.Season.WINTER)
	var winter_stretch := float(rig.sky_material.get_shader_parameter("cloud_stretch"))
	var winter_fog := rig.environment.fog_density
	rig.set_season(LocationData.Season.AUTUMN)
	if winter_stretch <= 1.0:
		failures.append("winter clouds should be stretched stratus")
	if rig.environment.fog_density <= winter_fog:
		failures.append("autumn haze should be denser than crisp winter air")

	rig.free()
	if failures.is_empty():
		print("SKY OK: golden-hour reference, seasonal sun/hues/clouds, twilight, night")
		quit(0)
	else:
		for f in failures:
			printerr("SKY FAIL: ", f)
		quit(1)
