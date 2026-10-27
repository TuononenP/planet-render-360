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
	if failures.is_empty():
		print("SEARCH OK: parse, short name, empty, encoding")
		quit(0)
	else:
		for f in failures:
			printerr("SEARCH FAIL: ", f)
		quit(1)
