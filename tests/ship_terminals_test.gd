extends SceneTree

## Ship terminals test: godot --headless --script tests/ship_terminals_test.gd
## Offline. The principal passenger terminals (LandmarkRegistryShipTerminals)
## are secondary "Ferry terminal" / "Cruise terminal" landmarks (never a
## city's primary icon): each has a clear_rect_m covering its halls, a kit
## model (LandmarkSetShipTerminals) reaching its height_m, and a name that
## resolves to its own type.

const MIN_TERMINALS := 10
const KINDS := ["Ferry terminal", "Cruise terminal"]

func _init() -> void:
	var failures: Array[String] = []
	var rows: Array = LandmarkRegistryShipTerminals.entries()
	if rows.size() < MIN_TERMINALS:
		failures.append("only %d ship terminals (want %d)" % [rows.size(), MIN_TERMINALS])
	var seen := {}
	for e in rows:
		var t := str(e["type"])
		if seen.has(t):
			failures.append("%s is listed twice" % t)
		seen[t] = true
		if not bool(e.get("secondary", false)):
			failures.append("%s should be secondary" % t)
		if str(e.get("kind", "")) not in KINDS:
			failures.append("%s should be a Ferry or Cruise terminal" % t)
		if (e.get("clear_rect_m", []) as Array).size() != 4:
			failures.append("%s lacks clear_rect_m" % t)
		if (e.get("outline_m", []) as Array).size() < 3:
			failures.append("%s has no measured outline" % t)
		if not LandmarkBuilder.is_bespoke(t):
			failures.append("%s has no kit model" % t)
			continue
		var got := LocationData.landmark_for(float(e["lat"]), float(e["lon"]), str(e["name"]))
		if got != t:
			failures.append("searching '%s' should give %s, got %s" % [e["name"], t, got])
		var root := LandmarkBuilder.build(t)
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for m in LandmarkBuilder.parts(root):
			var box := m.transform * m.mesh.get_aabb()
			lo = lo.min(box.position)
			hi = hi.max(box.end)
		var h := float(e["height_m"])
		if absf(hi.y - h) > maxf(2.0, h * 0.03):
			failures.append("%s should stand %.1f m tall, got %.1f m" % [t, h, hi.y])
		var rect: Array = e.get("clear_rect_m", [])
		if rect.size() == 4:
			var x0 := float(rect[0]) - float(rect[2])
			var x1 := float(rect[0]) + float(rect[2])
			var z0 := float(rect[1]) - float(rect[3])
			var z1 := float(rect[1]) + float(rect[3])
			if lo.x < x0 - 1.0 or hi.x > x1 + 1.0 or lo.z < z0 - 1.0 or hi.z > z1 + 1.0:
				failures.append("%s model spans x %.0f..%.0f z %.0f..%.0f outside clear_rect_m x %.0f..%.0f z %.0f..%.0f"
					% [t, lo.x, hi.x, lo.z, hi.z, x0, x1, z0, z1])
		root.free()
	if failures.is_empty():
		print("ship_terminals_test: PASS (%d terminals)" % rows.size())
		quit(0)
	else:
		for f in failures:
			printerr("ship_terminals_test FAIL: ", f)
		quit(1)
