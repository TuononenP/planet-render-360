extends SceneTree

## Sky per season and time of day (AtmosphereRig, offline):
## godot --headless --script tests/sky_test.gd

func _init() -> void:
	var failures: Array[String] = []
	var rig := AtmosphereRig.new()

	# The PRD golden-hour reference grade (the 17:00 keyframes) is the
	# state of a true afternoon sun 12.4° up: Paris, 15 July, 20:19 CEST
	# (T6.2 — the hour is the place's real clock, not a fixed arc).
	rig.set_season(LocationData.Season.SUMMER)
	rig.set_place(48.8566, 2.3522)
	rig.set_utc_offset(2.0)
	rig.set_time(20.31876, 48.8566, {"year": 2026, "month": 7, "day": 15})
	var ref := Color(0.44, 0.62, 0.82)
	var dz := rig.sky_top_color - ref
	if maxf(absf(dz.r), maxf(absf(dz.g), absf(dz.b))) > 0.005:
		failures.append("golden-hour reference zenith drifted: %s" % rig.sky_top_color)
	if absf(-rig.sun.rotation_degrees.x - 12.42) > 0.05:
		failures.append("golden-hour reference sun should sit ~12.4° up, got %f" % -rig.sun.rotation_degrees.x)
	# Sun in the west-north-west (true azimuth ~288°), not a fixed yaw.
	if absf(rig.solar_azimuth - 288.45) > 0.5:
		failures.append("golden-hour azimuth %.2f, want 288.45" % rig.solar_azimuth)
	# Physical sun (air mass + Rayleigh/aerosol extinction): the 12.4°
	# reference is PRD #FFD9A3; noon whiter and brighter, horizon redder.
	var gold := rig.sun.light_color
	if absf(gold.g - 0.851) > 0.02 or absf(gold.b - 0.639) > 0.02:
		failures.append("golden-hour sun should be #FFD9A3, got %s" % gold.to_html(false))
	var noon_t := AtmosphereRig.sun_transmittance(60.0)
	var low_t := AtmosphereRig.sun_transmittance(3.0)
	if not (noon_t.b / noon_t.r > gold.b and low_t.b / low_t.r < 0.3 and noon_t.g > low_t.g * 4.0):
		failures.append("sun extinction: noon %s, 3° %s" % [noon_t, low_t])
	if absf(rig.golden_hour() - 20.25) > 0.26:
		failures.append("Paris July golden hour should be ~20:15 CEST, got %f" % rig.golden_hour())
	rig.set_utc_offset(0.0)
	rig.set_time(12.0, 48.8566)

	# Seasons: lower winter noon sun (real mid-season dates), distinct
	# sky hues.
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
	var sunset := 18.0
	while sunset < 23.0 and float(rig.solar_at(sunset)["elevation"]) > 0.0:
		sunset += 0.05
	rig.set_time(sunset)
	if rig.twilight_amount < 0.5:
		failures.append("sunset (%.2f UTC) should be in twilight, got %f" % [sunset, rig.twilight_amount])
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

	# Weather sets the light, not just the deck (WeatherLook).
	rig.set_season(LocationData.Season.SUMMER)
	rig.set_time(12.0)
	rig.set_weather(0, 5.0)
	var clear_shadow := rig.sun.shadow_opacity
	var clear_ambient := rig.environment.ambient_light_energy
	var clear_fog := rig.environment.fog_density
	var clear_energy := rig.sun.light_energy
	var clear_ground: Color = rig.sky_material.get_shader_parameter("ground_color")
	rig.set_weather(3, 100.0)
	if not (rig.sun.shadow_opacity < clear_shadow * 0.7 and rig.environment.ambient_light_energy > clear_ambient):
		failures.append("overcast should soften shadows (%f) and lift diffuse light (%f)"
			% [rig.sun.shadow_opacity, rig.environment.ambient_light_energy])
	var overcast_shade := rig.cloud_shade_color
	if rig.sun.light_specular > 0.2:
		failures.append("a full deck should drop the sun's specular glint, got %f" % rig.sun.light_specular)
	var fogs := {}
	for code in [61, 65, 45]:
		rig.set_weather(code, 100.0)
		fogs[code] = rig.environment.fog_density
	if not (clear_fog < fogs[61] and fogs[61] < fogs[65] and fogs[65] < fogs[45]):
		failures.append("murk should rise clear < light rain < heavy rain < fog: %f %s" % [clear_fog, fogs])
	if not rig.is_foggy():
		failures.append("fog code 45 should count as foggy")
	rig.set_weather(65, 100.0)
	if rig.sun.light_energy >= clear_energy * 0.6:
		failures.append("heavy rain should dim the sun: %f vs clear %f" % [rig.sun.light_energy, clear_energy])
	rig.set_weather(95, 100.0)
	if rig.cloud_shade_color.get_luminance() >= overcast_shade.get_luminance() * 0.8:
		failures.append("storm bases should be darker than plain overcast")
	if rig.environment.tonemap_exposure <= PostGrade.EXPOSURE:
		failures.append("a storm should lift exposure so the scene stays readable")
	rig.set_weather(73, 100.0)
	var snow_ground: Color = rig.sky_material.get_shader_parameter("ground_color")
	if snow_ground.get_luminance() <= clear_ground.get_luminance() * 1.5:
		failures.append("falling snow should brighten the ground bounce")
	rig.set_weather(-1, AtmosphereRig.DEFAULT_COVER)

	# City skyglow: an overcast city night glows; the countryside stays dark.
	rig.set_time(rig.golden_hour() + 4.0)
	rig.set_weather(61, 100.0)
	rig.set_city_glow(0.0)
	var dark_deck: Color = rig.sky_material.get_shader_parameter("cloud_shade")
	rig.set_city_glow(1.0)
	var lit_deck: Color = rig.sky_material.get_shader_parameter("cloud_shade")
	if lit_deck.get_luminance() < dark_deck.get_luminance() * 2.0 or lit_deck.r <= lit_deck.b:
		failures.append("a city's overcast night should glow warm: %s vs %s" % [lit_deck, dark_deck])
	rig.set_city_glow(0.0)
	rig.set_weather(-1, AtmosphereRig.DEFAULT_COVER)

	# Desktop Ultra's street probes: none off it, box-projected round the eye.
	if not rig._street_probes.is_empty():
		failures.append("street reflection probes are desktop Ultra only")
	rig._set_street_probes(true)
	# A street rising 1 m in 10 to the east, the eye 30 m over it.
	var um := rig.units_per_metre
	rig.ground_at = func(x: float, _z: float) -> float: return x * 0.1
	rig.set_probe_origin(Vector3(10.0, 31.0, 0.0) * um)
	if rig._street_probes.size() != AtmosphereRig.STREET_PROBE_OFFSETS.size() \
			or not rig._street_probes[0].box_projection:
		failures.append("street probes should be box-projected")
	for sp: ReflectionProbe in rig._street_probes:
		var street := sp.position.x * 0.1
		var bottom := sp.position.y - sp.size.y * 0.5
		var capture := sp.position.y + sp.origin_offset.y
		if absf(bottom - (street - AtmosphereRig.STREET_BELOW_M * um)) > 0.01 * um \
				or absf(capture - (street + 30.0 * um)) > 0.01 * um:
			failures.append("a street box should stand on its street and capture at eye height: %s" % sp.position)
			break
	if not is_equal_approx(rig._street_probes[1].position.x, 150.0 * um):
		failures.append("street probes should follow the eye")
	# A drone far up: the capture stays inside its box.
	rig.set_probe_origin(Vector3(10.0, 400.0, 0.0) * um)
	var top_sp := rig._street_probes[0]
	if absf(top_sp.origin_offset.y) > top_sp.size.y * 0.5:
		failures.append("a high eye should keep each street capture inside its box")
	# The view probe: a high eye captures where it is; a walker's eye
	# captures VIEW_CAPTURE_AGL_M over its ground, above trees and walls.
	if not rig.probe.origin_offset.is_zero_approx():
		failures.append("a high eye should capture the view probe where it is: %s" % rig.probe.origin_offset)
	rig.set_probe_origin(Vector3(10.0, 1.0 + 1.7, 0.0) * um)
	var view_capture := rig.probe.position.y + rig.probe.origin_offset.y
	if absf(view_capture - (1.0 + AtmosphereRig.VIEW_CAPTURE_AGL_M) * um) > 0.01 * um:
		failures.append("a walker's view probe should capture %.0f m over the ground, at %f" % [
			AtmosphereRig.VIEW_CAPTURE_AGL_M, view_capture / um])
	if not is_equal_approx(rig.probe.position.y, 2.7 * um):
		failures.append("the view probe's box should stay centred on the eye")
	rig.ground_at = Callable()
	rig._set_street_probes(false)
	if not rig._street_probes.is_empty():
		failures.append("street probes should go when Ultra is left")

	rig.free()
	if failures.is_empty():
		print("SKY OK: golden-hour reference, seasonal sun/hues/clouds, twilight, night")
		quit(0)
	else:
		for f in failures:
			printerr("SKY FAIL: ", f)
		quit(1)
