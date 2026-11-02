extends SceneTree

## Headless: godot --headless --script tests/height_inference_test.gd
## Untagged heights (BuildingHeights._resolve_total): an office block
## among tagged towers takes their neighbour median, but a retail block,
## warehouse or garage there stays low-rise (LOW_RISE_STOREYS), and a
## tagged height is never capped.

func _init() -> void:
	var failures: Array[String] = []
	var d := LocationData.new()
	d.latitude = 25.1925
	d.longitude = 55.2741
	d.country = "AE"
	var towers: Array = []
	for i in 5:
		towers.append({"x": 40.0 * i, "z": 60.0, "size_x": 30.0, "size_z": 30.0, "height": 150.0,
			"height_source": "tag_height", "kind": "office", "levels": 0})
	d.buildings = towers
	var ctx := BuildingHeights._height_context(d)
	var res := {}
	for kind in ["office", "retail", "warehouse", "parking"]:
		var b := {"x": 80.0, "z": 0.0, "size_x": 70.0, "size_z": 70.0, "height": 10.0,
			"height_source": "default", "kind": kind, "levels": 0}
		var look := BuildingHeights._look_for(b, ctx)
		res[kind] = float(BuildingHeights._resolve_total(b, b, ctx, {}, look)["total_m"])
	if res["office"] < 100.0:
		failures.append("an untagged office among towers should follow them, got %.0f m" % res["office"])
	for kind in ["retail", "warehouse", "parking"]:
		if res[kind] > 20.0:
			failures.append("an untagged %s among towers should stay low-rise, got %.0f m" % [kind, res[kind]])
	var tagged := {"x": 80.0, "z": 0.0, "size_x": 70.0, "size_z": 70.0, "height": 45.0,
		"height_source": "tag_height", "kind": "retail", "levels": 0}
	var tl := BuildingHeights._look_for(tagged, ctx)
	if absf(float(BuildingHeights._resolve_total(tagged, tagged, ctx, {}, tl)["total_m"]) - 45.0) > 0.01:
		failures.append("a tagged retail height must be kept")
	if failures.is_empty():
		print("HEIGHT INFERENCE OK: office follows towers (%.0f m), retail/warehouse/parking stay low, tags kept" % res["office"])
		quit(0)
	else:
		for f in failures:
			printerr("HEIGHT INFERENCE FAIL: ", f)
		quit(1)
