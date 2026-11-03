extends "res://tools/shoreline_capture.gd"

## Windowed frozen-input stage profile, including the final building merge.
func _capture(_main: Node, view: View360, place: Dictionary, _times: PackedStringArray,
		_audit: bool, _settle_s: float = SETTLE_S) -> void:
	var id := str(place["id"])
	var file := FileAccess.open(str(_args()["inputs"]).path_join(id + ".snap"), FileAccess.READ)
	var saved: Dictionary = file.get_var()
	file.close()
	var data := LocationData.new()
	for property in data.get_property_list():
		var key: String = property["name"]
		if saved.has(key):
			data.set(key, _thaw(saved[key], data.get(key)))
	view.set_quality_preset(data.quality_preset)
	var thread := Thread.new()
	thread.start(func() -> Dictionary:
		var t0 := Time.get_ticks_msec()
		var ground := GroundTruth.new(data)
		var t1 := Time.get_ticks_msec()
		var world := TerrainBuilder.build_world(data, ground, BuildAbort.new())
		var t2 := Time.get_ticks_msec()
		LodRing.merge_buildings(world)
		var t3 := Time.get_ticks_msec()
		var timings := {"ground_ms": t1 - t0, "world_ms": t2 - t1, "merge_ms": t3 - t2, "total_ms": t3 - t0}
		world.free()
		return timings)
	while thread.is_alive():
		await process_frame
	var timings: Dictionary = thread.wait_to_finish()
	_stats[id] = timings
	print("SHORE STAGES ", id, " ", JSON.stringify(timings))
