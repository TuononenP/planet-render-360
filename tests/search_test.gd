extends SceneTree

## Search parser test (offline): godot --headless --script tests/search_test.gd

const FIXTURE := """
[{"display_name":"Eiffel Tower, Champ de Mars, Paris, France",
  "lat":"48.8583701","lon":"2.2944813"},
 {"display_name":"Second Result, Elsewhere","lat":"1.0","lon":"2.0"}]
"""

func _init() -> void:
	var failures: Array[String] = []
	var first := SearchFetcher.parse_first(FIXTURE)
	if first.is_empty():
		failures.append("fixture did not parse")
	else:
		if SearchFetcher.short_name(str(first["name"])) != "Eiffel Tower, Champ de Mars":
			failures.append("short name wrong: %s" % first["name"])
		if absf(float(first["lat"]) - 48.8583701) > 0.0001:
			failures.append("lat wrong: %s" % first["lat"])
	if not SearchFetcher.parse_first("[]").is_empty():
		failures.append("empty array must give empty result")
	if not SearchFetcher.build_url("a b&c").contains("a%20b%26c"):
		failures.append("query not URL-encoded")
	var ll := MapSearch.parse_coordinates("123, 400")
	if ll != Vector2(90.0, 180.0):
		failures.append("typed coordinates not clamped: %s" % str(ll))
	if MapSearch.parse_coordinates("60.17, 24.94") != Vector2(60.17, 24.94):
		failures.append("valid coordinates changed")
	var ranked := GenerationPipeline.rank_landmarks([
		{"x": 10.0, "z": 0.0}, {"x": 500.0, "z": 0.0, "monument": true},
		{"x": 99999.0, "z": 0.0, "monument": true}, {"x": 20.0, "z": 0.0}])
	if ranked.map(func(c: Dictionary) -> float: return c["x"]) != [500.0, 10.0, 20.0, 99999.0]:
		failures.append("monument in range must rank first: %s" % str(ranked))
	if failures.is_empty():
		print("SEARCH OK: parse, short name, empty, encoding")
		quit(0)
	else:
		for f in failures:
			printerr("SEARCH FAIL: ", f)
		quit(1)
