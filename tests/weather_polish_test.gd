extends SceneTree

## Weather polish tests:
##   tools/godot_bg.sh --headless --path . --script tests/weather_polish_test.gd
## Verifies unified GroundShader/FarSurface HEIGHT_FOG_GLSL splice, shopfront
## corner-frost uniform propagation, blowing-snow strength gating, and
## ViewChrome.format_weather_tooltip formatting.

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	# 1. Unified height-integrated fog spliced into GroundShader and FarSurface.
	var gcode := GroundMaterial.shader_code()
	_check(gcode.contains("height_integrated_fog"), "GroundShader includes height_integrated_fog")
	_check(not gcode.contains("// @HEIGHT_FOG"), "GroundShader has no unspliced @HEIGHT_FOG marker")
	_check(WeatherGlsl.HEIGHT_FOG_GLSL.contains("valley_haze_scale"), "HEIGHT_FOG_GLSL defines valley_haze_scale")

	# 2. Shopfront corner frost uniform in FacadeShader & FacadeLiteShader.
	var fmat := StandardMaterial3D.new()
	fmat.set_meta("facade_set", "render")
	fmat.set_meta("shopfront_heat", 1.0)
	fmat.set_meta(CityLights.META, true)
	var ultra_s := FacadeShader.from_standard(fmat)
	var lite_s := FacadeLiteShader.from_standard(fmat)
	_check(is_equal_approx(float(ultra_s.get_shader_parameter("shopfront_heat")), 1.0),
		"FacadeShader propagates shopfront_heat=1.0")
	_check(is_equal_approx(float(lite_s.get_shader_parameter("shopfront_heat")), 1.0),
		"FacadeLiteShader propagates shopfront_heat=1.0")
	_check(WeatherGlsl.FROST_GLSL.contains("shop_heat"), "WeatherGlsl.FROST_GLSL handles shop_heat")

	# 3. Blowing-snow drift gating (> 25 km/h & snow_depth > 0.25).
	_check(WeatherDressing.blowing_snow_strength(0.8, 20.0) == 0.0, "calm wind -> no blowing snow")
	_check(WeatherDressing.blowing_snow_strength(0.1, 45.0) == 0.0, "bare ground -> no blowing snow")
	var strong := WeatherDressing.blowing_snow_strength(0.8, 45.0)
	_check(strong > 0.5 and strong <= 1.0, "45 km/h over deep snow produces strong spindrift: %.2f" % strong)

	# 4. Weather chip live telemetry tooltip formatting.
	var tip := ViewChrome.format_weather_tooltip(-4.2, "Snow", {
		"rh": 88.0, "dew_point_c": -6.0, "wind_kmh": 32.0,
		"snow_depth_m": 0.24, "visibility_m": 1200.0,
	})
	_check(tip.contains("Snow · -4 °C"), "tooltip header formats condition and temp")
	_check(tip.contains("Humidity 88%"), "tooltip shows humidity")
	_check(tip.contains("Dew point -6 °C"), "tooltip shows dew point")
	_check(tip.contains("Wind 32 km/h"), "tooltip shows wind")
	_check(tip.contains("Snow depth 24 cm"), "tooltip shows snow depth in cm")
	_check(tip.contains("Visibility 1.2 km"), "tooltip shows visibility in km")
	_check(tip.ends_with("Pick the weather"), "tooltip ends with action hint")
	var plain := ViewChrome.format_weather_tooltip(18.0, "Clear", {})
	_check(plain == "Clear · 18 °C\nPick the weather", "tooltip omits missing telemetry cleanly")

	StaticCaches.release_all()
	if _failures.is_empty():
		print("WEATHER POLISH PASS")
		quit(0)
	else:
		for f in _failures:
			printerr("WEATHER POLISH FAIL: ", f)
		quit(1)
