extends SceneTree

## Parametric bridge builders: godot --headless --script tests/bridge_param_test.gd
## Offline. One synthetic row for every structure type and option BridgeSpec
## knows (independent of the capital tables) must validate, build 2..16 merged
## parts within BridgeParam.MAX_TRIS triangles, stay out of the water, span its
## length, stand as tall as BridgeSpec.model_top says and be as wide as its row.

var failures: Array[String] = []

func _init() -> void:
	_run()

func _row(id: String, st: String, extra: Dictionary) -> Dictionary:
	var row := {"id": "br_test_" + id, "cc": "FR", "name": "Test " + id, "lat": 48.0, "lon": 2.0,
		"bearing": 90.0, "st": st, "spans": [40.0, 80.0, 40.0], "width": 20.0, "clear": 10.0,
		"material": "steel", "base": "water", "tier": 2, "src": "synthetic", "conf": 3}
	row.merge(extra, true)
	return row

func _rows() -> Array:
	return [
		_row("susp", "susp", {"tower": 45.0}),
		_row("stayed", "stayed", {"spans": [60.0, 120.0, 60.0], "tower": 55.0}),
		_row("stayed_single_lean", "stayed", {"spans": [50.0, 150.0], "tower": 80.0, "pylon": "single",
			"lean": -30.0}),
		_row("stayed_towers", "stayed", {"spans": [75.0, 50.0, 50.0, 300.0], "tower": 160.0, "towers": [3]}),
		_row("extradosed", "extradosed", {"spans": [70.0, 120.0, 70.0], "tower": 24.0}),
		_row("lateral", "lateral", {"spans": [60.0, 120.0, 60.0], "width": 4.0, "clear": 8.0, "tower": 12.0}),
		_row("arch_deck", "arch_deck", {"spans": [60.0, 60.0], "rise": 6.0}),
		_row("arch_through", "arch_through", {"spans": [90.0], "rise": 18.0}),
		_row("arch_tied_centre", "arch_tied", {"spans": [30.0, 90.0, 30.0], "rise": 16.0, "arch_spans": [1]}),
		_row("truss", "truss", {"spans": [70.0, 90.0, 70.0], "rise": 12.0}),
		_row("truss_lower", "truss", {"spans": [60.0, 60.0, 60.0], "rise": 10.0, "lower": 9.0}),
		_row("girder", "girder", {"spans": [30.0, 30.0, 30.0, 30.0]}),
		_row("girder_lower", "girder", {"spans": [40.0, 40.0], "lower": 8.0}),
		_row("haunched", "haunched", {"spans": [60.0, 120.0, 60.0], "clear": 14.0}),
		_row("haunched_legs", "haunched", {"spans": [50.0, 100.0, 50.0], "clear": 25.0, "legs": 14.0}),
		_row("masonry", "masonry", {"spans": [24.0, 24.0, 24.0, 24.0], "clear": 9.0, "rise": 5.0, "material": "stone"}),
		_row("bascule", "bascule", {"spans": [60.0, 60.0, 60.0], "tower": 50.0, "material": "stone"}),
		_row("swing", "swing", {"spans": [40.0, 60.0, 40.0], "moving": 1, "clear": 6.0}),
		_row("swing_truss", "swing", {"spans": [40.0, 60.0, 40.0], "moving": 1, "clear": 6.0, "rise": 9.0}),
		_row("lift", "lift", {"spans": [40.0, 50.0, 40.0], "moving": 1, "clear": 8.0, "tower": 36.0}),
		_row("pontoon", "pontoon", {"spans": [20.0, 20.0, 20.0, 20.0, 20.0], "clear": 2.0, "width": 9.0}),
	]

func _run() -> void:
	for row in _rows():
		var id := str(row["id"])
		for problem in BridgeSpec.validate(row):
			failures.append(problem)
		var root := Node3D.new()
		var model := LandmarkBuilder.model_root(root)
		BridgeParam.build(model, row)
		var parts := LandmarkBuilder.parts(root)
		_check(parts.size() >= 2 and parts.size() <= 16, "%s should be 2..16 parts, got %d" % [id, parts.size()])
		var tris := 0
		var box := AABB()
		var first := true
		for m in parts:
			tris += m.mesh.surface_get_array_len(0) / 3
			var b := m.transform * m.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		_check(tris <= BridgeParam.MAX_TRIS, "%s has %d triangles (max %d)" % [id, tris, BridgeParam.MAX_TRIS])
		_check(box.position.y > -0.05, "%s reaches %.2f m below the water" % [id, box.position.y])
		var top := BridgeSpec.model_top(row)
		_check(absf(box.end.y - top) <= maxf(1.0, top * 0.03), "%s should stand %.1f m, got %.1f m" % [id, top, box.end.y])
		var length := BridgeSpec.length_m(row)
		_check(box.size.x >= length * 0.98 and box.size.x <= length * 1.04 + 2.0,
			"%s should be %.0f m long, got %.0f m" % [id, length, box.size.x])
		_check(box.size.z >= float(row["width"]) * 0.9, "%s should be %.0f m wide, got %.0f m" % [id, row["width"], box.size.z])
		root.free()
	# Invalid rows are caught.
	var bad := [
		_row("bad_swing", "swing", {"moving": 7}),
		_row("bad_lift", "lift", {"moving": 1, "tower": 12.0}),
		_row("bad_pontoon", "pontoon", {"clear": 12.0}),
		_row("bad_arch_spans", "arch_tied", {"rise": 12.0, "arch_spans": [9]}),
		_row("bad_lower", "girder", {"lower": 1.0}),
		_row("bad_lateral", "lateral", {"tower": 10.5}),
	]
	for row in bad:
		_check(not BridgeSpec.validate(row).is_empty(), "%s should be rejected" % row["id"])
	if failures.is_empty():
		print("BRIDGE PARAM OK: %d structure rows" % _rows().size())
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE PARAM FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
