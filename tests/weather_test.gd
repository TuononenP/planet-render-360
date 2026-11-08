extends SceneTree

## Weather parser test (offline): godot --headless --script tests/weather_test.gd

const FIXTURE := """
{"current":{"temperature_2m":16.4,"weather_code":3,"cloud_cover":100}}
"""

func _init() -> void:
	var failures: Array[String] = []
	var w := WeatherFetcher.parse_current(FIXTURE)
	if w.is_empty():
		failures.append("fixture did not parse")
	else:
		if absf(float(w["temp"]) - 16.4) > 0.01:
			failures.append("temp wrong: %s" % w)
		if str(w["label"]) != "Overcast":
			failures.append("code 3 should be Overcast, got %s" % w["label"])
	if WeatherFetcher.label_for_code(61) != "Rain" \
			or WeatherFetcher.label_for_code(71) != "Snow" \
			or WeatherFetcher.label_for_code(0) != "Clear" \
			or WeatherFetcher.label_for_code(45) != "Fog":
		failures.append("WMO code mapping wrong")
	var tz := WeatherFetcher.parse_current('{"utc_offset_seconds":7200,"current":{"weather_code":0}}')
	if int(tz.get("utc_offset_s", -1)) != 7200:
		failures.append("utc_offset_seconds should parse for the true sun's clock: %s" % tz)
	if w.has("utc_offset_s"):
		failures.append("missing utc_offset_seconds must stay absent")
	if WeatherFetcher.label_for_code(56) != "Freezing drizzle" \
			or WeatherFetcher.label_for_code(66) != "Freezing rain" \
			or WeatherFetcher.label_for_code(96) != "Thunderstorm":
		failures.append("freezing / storm labels wrong")
	# Visibility by intensity, and only thunderstorms are storms.
	var vis := func(c: int) -> float: return float(WeatherLook.for_code(c, 100.0)["visibility_m"])
	if not (vis.call(61) > vis.call(63) and vis.call(63) > vis.call(65) and vis.call(65) > vis.call(45)):
		failures.append("rain visibility should fall with intensity, fog lowest")
	if WeatherLook.for_code(65, 100.0)["storm"] or not WeatherLook.for_code(95, 100.0)["storm"]:
		failures.append("storm flag wrong")
	# Rain and snow fall at terminal velocity, snow far slower.
	var rain_p := WeatherLook.particle_params(WeatherLook.for_code(65, 100.0))
	var snow_p := WeatherLook.particle_params(WeatherLook.for_code(75, 100.0))
	if float(rain_p["speed"]) < 7.0 or float(rain_p["speed"]) > 10.0:
		failures.append("heavy rain should fall at about 9 m/s: %s" % rain_p)
	if float(snow_p["speed"]) > 2.0 or float(snow_p["speed"]) >= float(rain_p["speed"]):
		failures.append("snow should drift down near 1 m/s: %s" % snow_p)
	# Precipitation is visible from anywhere the eye looks.
	var parent := Node3D.new()
	var fall := Precipitation.build(parent, RenderSettings.Preset.HIGH)
	if fall.visibility_aabb.size.x < 2.0 * Precipitation.RAIN_BOX.x:
		failures.append("the culling box must hold the whole fall: %s" % fall.visibility_aabb)
	Precipitation.apply(fall, WeatherLook.for_code(65, 100.0))
	if not fall.emitting or not fall.visible or absf(fall.lifetime - Precipitation.RAIN_TRAVEL_M / float(rain_p["speed"])) > 0.01:
		failures.append("rain should live for its travel distance, got %f" % fall.lifetime)
	Precipitation.apply(fall, WeatherLook.for_code(71, 100.0))
	if fall.preprocess * float(fall.fixed_fps) > 120.0:
		failures.append("the snow preroll must stay cheap: %f s at %d fps" % [fall.preprocess, fall.fixed_fps])
	# Night snow goes dark with the sky instead of glowing.
	Precipitation.set_light(fall, Color(0.02, 0.02, 0.03), true)
	var flake: Color = ((fall.draw_pass_1 as QuadMesh).material as ShaderMaterial).get_shader_parameter("tint")
	if flake.r > 0.1:
		failures.append("night snow must follow the dark sky: %s" % flake)
	Precipitation.apply(fall, WeatherLook.for_code(0, 15.0))
	if fall.emitting or fall.visible:
		failures.append("clear skies must stop the fall")
	Precipitation.apply(fall, WeatherLook.for_code(65, 100.0))
	if not fall.emitting or not fall.visible:
		failures.append("rain after clear skies must fall again")
	# A quality change while it rains re-dresses the fall instead of emptying the air.
	Precipitation.apply(fall, WeatherLook.for_code(65, 100.0))
	Precipitation.set_quality(fall, RenderSettings.Preset.ULTRA)
	if fall.amount != int(Precipitation.AMOUNT[RenderSettings.Preset.ULTRA]) or not fall.emitting or fall.preprocess <= 0.0:
		failures.append("a quality change must keep the rain falling and prerolled")
	Precipitation.apply(fall, WeatherLook.for_code(0, 15.0))
	if fall.is_processing():
		failures.append("clear weather must not process the precipitation every frame")
	Precipitation.apply(fall, WeatherLook.for_code(65, 100.0))
	if not fall.is_processing():
		failures.append("rain must follow the eye")
	# The rig turns with the view; the weather only follows its position.
	# World transforms need the tree running, which _init starts before.
	await process_frame
	root.add_child(parent)
	parent.position = Vector3(5.0, 2.0, -7.0)
	parent.rotation = Vector3(-1.2, 0.8, 0.0)
	fall._process(0.0)
	var eye_up := parent.global_position + Vector3(0.0, Precipitation.BOX_UP_M, 0.0)
	if not fall.global_transform.basis.is_equal_approx(Basis.IDENTITY) or not fall.global_position.is_equal_approx(eye_up):
		failures.append("precipitation must follow the eye without turning: %s" % fall.global_transform)
	if not (fall.get_node("Veil0") as Node3D).global_transform.basis.is_equal_approx(Basis.IDENTITY):
		failures.append("the far sheets must stay upright as the view turns")
	parent.free()
	if not WeatherFetcher.parse_current("{}").is_empty():
		failures.append("missing current must be empty")
	if failures.is_empty():
		print("WEATHER OK: parse, WMO labels, empty guard")
		quit(0)
	else:
		for f in failures:
			printerr("WEATHER FAIL: ", f)
		quit(1)
