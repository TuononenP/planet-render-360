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
	if not WeatherFetcher.parse_current("{}").is_empty():
		failures.append("missing current must be empty")
	if failures.is_empty():
		print("WEATHER OK: parse, WMO labels, empty guard")
		quit(0)
	else:
		for f in failures:
			printerr("WEATHER FAIL: ", f)
		quit(1)
