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
	if not WeatherFetcher.parse_current("{}").is_empty():
		failures.append("missing current must be empty")
	if failures.is_empty():
		print("WEATHER OK: parse, WMO labels, empty guard")
		quit(0)
	else:
		for f in failures:
			printerr("WEATHER FAIL: ", f)
		quit(1)
