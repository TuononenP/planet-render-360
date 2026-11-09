extends SceneTree

## Capital bridge selection: godot --headless --script tests/bridge_select_test.gd
## Offline. Secondary bridge entries never take an icon's registry slot, are
## chosen by tier and then by how near their span passes the view, are capped
## per quality preset, and a hand-built bridge keeps its old place among the
## extras.

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _bridge(type: String, dlat: float, tier: int, span: float = 200.0) -> Dictionary:
	return {"type": type, "name": type, "lat": 48.86 + dlat, "lon": 2.30, "radius_m": 6000.0,
		"height_m": 10.0, "yaw_deg": 0.0, "span_m": span, "kind": "Bridge", "secondary": true,
		"tier": tier, "aliases": [type + "xx"]}

func _run() -> void:
	var data := LocationData.new()
	data.latitude = 48.86
	data.longitude = 2.30
	data.landmark_type = "none"
	var near_minor := _bridge("near_minor", 0.0005, 3)
	var far_major := _bridge("far_major", 0.02, 2)
	var near_major := _bridge("near_major", 0.004, 2)
	var icon := _bridge("icon", 0.03, 1)
	var hand_built := _bridge("hand_built", 0.001, 2)
	hand_built.erase("secondary")
	var extras: Array = [near_minor, far_major, near_major, icon, hand_built]
	_check(LandmarkSites._is_capital_bridge(near_minor), "a secondary Bridge entry is a capital bridge")
	_check(not LandmarkSites._is_capital_bridge(hand_built), "a hand-built bridge is not")
	var picked := LandmarkSites._nearest_bridges(data, extras, 8)
	var order: Array = picked.map(func(e: Dictionary) -> String: return str(e["type"]))
	_check(order == ["icon", "near_major", "far_major", "near_minor"],
		"bridges should rank by tier then distance, got %s" % str(order))
	_check(LandmarkSites._nearest_bridges(data, extras, 2).size() == 2, "the budget caps the bridges")
	for preset in LandmarkSites.MAX_BRIDGES_BY_PRESET.size():
		_check(LandmarkSites.MAX_BRIDGES_BY_PRESET[preset] > 0, "preset %d keeps some bridges" % preset)
	_check(LandmarkSites.MAX_BRIDGES_BY_PRESET[0] <= LandmarkSites.MAX_BRIDGES_BY_PRESET[3],
		"a higher preset never builds fewer bridges")
	# The span, not the centre, decides: a long bridge whose centre is far
	# but whose deck passes the view outranks a short one nearer in centre.
	var long_bridge := _bridge("long_bridge", 0.009, 2, 2200.0)
	long_bridge["yaw_deg"] = 90.0
	var short_bridge := _bridge("short_bridge", 0.006, 2, 100.0)
	var ranked := LandmarkSites._nearest_bridges(data, [short_bridge, long_bridge], 2)
	_check(str(ranked[0]["type"]) == "long_bridge", "a span passing the view is nearer than a far centre, got %s" % ranked[0]["type"])
	# The real selection: only registry bridges within their view radius, none
	# of them primary, the extras cap untouched.
	for preset in 4:
		data.quality_preset = preset
		var out := LandmarkSites.select(data, [])
		var bridges := out.filter(func(c: Dictionary) -> bool: return str(c["type"]).begins_with("br_"))
		_check(bridges.size() <= LandmarkSites.MAX_BRIDGES_BY_PRESET[preset],
			"preset %d built %d capital bridges (max %d)" % [preset, bridges.size(), LandmarkSites.MAX_BRIDGES_BY_PRESET[preset]])
		_check(out.size() <= LandmarkSites.MAX_BY_PRESET[preset], "preset %d selected %d candidates (cap %d)" % [
			preset, out.size(), LandmarkSites.MAX_BY_PRESET[preset]])
		_check(out.size() - bridges.size() <= LandmarkSites.MAX_REGISTRY_EXTRAS_BY_PRESET[preset] + 1,
			"preset %d extras exceed the registry cap" % preset)
	if failures.is_empty():
		print("BRIDGE SELECT OK")
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE SELECT FAIL: ", f)
		quit(1)
