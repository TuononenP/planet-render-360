extends SceneTree

## Headless: godot --headless --script tests/utility_poles_test.gd
## Japanese and Korean utility poles: a JP residential street gets a pole
## every ~30 m along one side just past its kerb, clear of junctions; a
## Finnish, pedestrian or tunnel street gets none; poles need High and
## cables desktop Ultra; spans join consecutive poles of one street and
## the build keeps its draw-call budget.

func _init() -> void:
	_run()

func _data(country: String) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = 35.68
	data.longitude = 139.76
	data.country = country
	data.buildings = []
	return data

func _road(tags: Dictionary, a: Vector2, b: Vector2) -> Dictionary:
	return OsmTags._road_entry(tags, PackedVector2Array([a, b]))

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	var data := _data("JP")
	var street := _road({"highway": "residential"}, Vector2(-150, 0) * m, Vector2(150, 0) * m)
	data.roads = [street]
	var ground := GroundTruth.new(data)
	var plan := UtilityPoles.plan(data, ground)
	var poles: Array = plan["poles"]
	if plan != UtilityPoles.plan(data, ground):
		failures.append("pole placement must be deterministic")
	var grid := UtilityPoles.pole_grid(plan)
	var first: Vector3 = (poles[0] as Dictionary)["pos"] if not poles.is_empty() else Vector3.ZERO
	if not UtilityPoles.near_pole(grid, Vector2(first.x + 5.0 * m, first.z)):
		failures.append("a side-street lamp 5 m from a pole should give way to it")
	if UtilityPoles.near_pole(grid, Vector2(0, 80.0 * m)) or UtilityPoles.near_pole({}, Vector2.ZERO):
		failures.append("a lamp far from every pole (or with no poles planned) should stand")
	if poles.size() < 8 or poles.size() > 11:
		failures.append("300 m of residential street should hold ~10 poles: %d" % poles.size())
	var half := float(street["width_m"]) * 0.5
	var sides := {}
	var xs: Array = []
	for p: Dictionary in poles:
		var pos: Vector3 = p["pos"]
		sides[signf(pos.z)] = true
		xs.append(pos.x / m)
		if absf(absf(pos.z / m) - (half + UtilityPoles.KERB_OUT_M)) > 0.05:
			failures.append("a pole off the kerb line at %s (half width %.1f)" % [pos, half])
			break
		if float(p["h"]) < 10.0 or float(p["h"]) > 12.0:
			failures.append("pole height %.1f m outside 10–12 m" % float(p["h"]))
			break
	if sides.size() != 1:
		failures.append("poles should stand along one side only: %s" % [sides.keys()])
	xs.sort()
	for i in xs.size() - 1:
		var gap: float = xs[i + 1] - xs[i]
		if absf(gap - UtilityPoles.SPACING_M) > 8.5:
			failures.append("pole spacing %.1f m, expected ~%.0f" % [gap, UtilityPoles.SPACING_M])
			break
	if not poles.any(func(p: Dictionary) -> bool: return bool(p["transformer"])):
		failures.append("every third or fourth pole should carry a transformer")
	# Spans join consecutive poles of one street, cables pole to pole.
	var spans: Array = plan["spans"]
	if spans.size() != poles.size() - 1:
		failures.append("a straight street of %d poles should have %d spans: %d" % [poles.size(), poles.size() - 1, spans.size()])
	for span: Dictionary in spans:
		var a: Dictionary = poles[int(span["a"])]
		var b: Dictionary = poles[int(span["b"])]
		var pa: Vector3 = a["pos"]
		var pb: Vector3 = b["pos"]
		var cables: Array = span["cables"]
		if int(span["b"]) != int(span["a"]) + 1 or int(a["road"]) != int(b["road"]):
			failures.append("a span between non-consecutive poles %s" % span)
			break
		if cables.size() < 3 or cables.size() > 6:
			failures.append("a span should carry 3–6 cables: %d" % cables.size())
			break
		var ok := true
		for c: Array in cables:
			var ca: Vector3 = c[0]
			var cb: Vector3 = c[1]
			ok = ok and Vector2(ca.x - pa.x, ca.z - pa.z).length() < 1.0 * m \
				and Vector2(cb.x - pb.x, cb.z - pb.z).length() < 1.0 * m \
				and (ca.y - pa.y) / m > 6.5 and (ca.y - pa.y) / m < 11.0
		if not ok:
			failures.append("cables should run from one pole's top to the next: %s" % [cables])
			break
	var sag := UtilityPoles.sag(Vector3.ZERO, Vector3(30, 0, 0), 0.75, 6)
	if absf((sag[3] as Vector3).y + 0.75) > 0.001 or (sag[0] as Vector3) != Vector3.ZERO:
		failures.append("a cable sags its drop at mid-span: %s" % [sag])
	# Junctions stay clear.
	var through := street.duplicate()
	through["points"] = PackedVector2Array([Vector2(-150, 0) * m, Vector2(0, 0), Vector2(150, 0) * m])
	data.roads = [through, _road({"highway": "residential"}, Vector2(0, -80) * m, Vector2(0, 0))]
	for p: Dictionary in UtilityPoles.plan(data, ground)["poles"]:
		var pos: Vector3 = p["pos"]
		if Vector2(pos.x, pos.z).length() < UtilityPoles.JUNCTION_CUT_M * m:
			failures.append("a pole on a junction at %s" % pos)
			break
	# Draw calls, desktop Ultra with cables.
	data.roads = [street, _road({"highway": "tertiary"}, Vector2(-150, 60) * m, Vector2(150, 60) * m),
		_road({"highway": "service"}, Vector2(-60, -200) * m, Vector2(-60, 200) * m),
		_road({"highway": "unclassified"}, Vector2(80, -200) * m, Vector2(80, 200) * m)]
	data.buildings = [{"x": 20.0 * m, "z": 15.0 * m, "height": 9.0, "footprint": PackedVector2Array([
		Vector2(10, 8) * m, Vector2(30, 8) * m, Vector2(30, 22) * m, Vector2(10, 22) * m])}]
	var node := Node3D.new()
	var stats := UtilityPoles.build(node, data, ground)
	if int(stats["poles"]) < 30 or int(stats["cables"]) == 0:
		failures.append("four JP streets should build poles and cables on Ultra: %s" % stats)
	if int(stats["draw_calls"]) > UtilityPoles.MAX_DRAW_CALLS:
		failures.append("utility poles over the draw-call budget: %s" % stats)
	var cable_meshes := 0
	for child in node.get_child(0).get_children():
		if child is MeshInstance3D:
			cable_meshes += 1
	if cable_meshes > 4:
		failures.append("cables should merge into at most four chunks: %d" % cable_meshes)
	node.free()
	for p: Dictionary in UtilityPoles.plan(data, ground)["poles"]:
		var q := Vector2((p["pos"] as Vector3).x, (p["pos"] as Vector3).z)
		if Geometry2D.is_point_in_polygon(q, data.buildings[0]["footprint"]):
			failures.append("a pole inside a building at %s" % q)
			break
	data.buildings = []
	# High: poles, no cables; Balanced: nothing.
	data.quality_preset = RenderSettings.Preset.HIGH
	node = Node3D.new()
	stats = UtilityPoles.build(node, data, ground)
	if int(stats["poles"]) == 0 or int(stats["cables"]) != 0:
		failures.append("High should build poles without cables: %s" % stats)
	node.free()
	data.quality_preset = RenderSettings.Preset.BALANCED
	if not (UtilityPoles.plan(data, ground)["poles"] as Array).is_empty():
		failures.append("Balanced should have no utility poles")
	data.quality_preset = RenderSettings.Preset.ULTRA
	# KR yes, FI none, pedestrian / footway / tunnel / bridge / primary none.
	data.roads = [street]
	data.country = "KR"
	if (UtilityPoles.plan(data, ground)["poles"] as Array).is_empty():
		failures.append("Korean residential streets should have utility poles")
	data.country = "FI"
	if not (UtilityPoles.plan(data, ground)["poles"] as Array).is_empty():
		failures.append("Finland should have no utility poles")
	data.country = "JP"
	var tunnel := street.duplicate()
	tunnel["tunnel"] = true
	var bridge := street.duplicate()
	bridge["bridge"] = true
	for road in [_road({"highway": "pedestrian"}, Vector2(-150, 0) * m, Vector2(150, 0) * m),
			_road({"highway": "footway"}, Vector2(-150, 0) * m, Vector2(150, 0) * m),
			_road({"highway": "primary"}, Vector2(-150, 0) * m, Vector2(150, 0) * m),
			tunnel, bridge]:
		data.roads = [road]
		if not (UtilityPoles.plan(data, ground)["poles"] as Array).is_empty():
			failures.append("no poles along %s (tunnel %s, bridge %s)" % [road.get("class"),
				road.get("tunnel"), road.get("bridge")])
	failures.remove_at(0)
	if failures.is_empty():
		print("UTILITY POLES TEST: PASS")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		print("UTILITY POLES TEST: FAIL (%d)" % failures.size())
		quit(1)
