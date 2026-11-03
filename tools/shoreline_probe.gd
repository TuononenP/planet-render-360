extends "res://tools/shoreline_capture.gd"

## Headless frozen-input level and generation profile.
func _run() -> void:
	var args := _args()
	var file := FileAccess.open(str(args.get("input", "")), FileAccess.READ)
	if file == null:
		quit(2)
		return
	var saved: Dictionary = file.get_var()
	var data := LocationData.new()
	for property in data.get_property_list():
		var key: String = property["name"]
		if saved.has(key):
			data.set(key, _thaw(saved[key], data.get(key)))
	print("SHORE SOURCE datum=", data.centre_elevation_m, " water=", data.water_level, " range=", TerrainBuilder._range_of(data.heights))
	print("SHORE STRUCTURES count=", data.shore_structures.size())
	var evidence := ShoreEvidence.new(data)
	var t := Time.get_ticks_msec()
	var ground := GroundTruth.new(data)
	print("SHORE GROUND ms=", Time.get_ticks_msec() - t, " datum=", ground.datum_m, " water=", ground.water_level_m)
	var model: Variant = ground.get("shoreline")
	if OS.get_cmdline_user_args().has("--world"):
		var world_start := Time.get_ticks_msec()
		var world := TerrainBuilder.build_world(data, ground, BuildAbort.new())
		print("SHORE WORLD ms=", Time.get_ticks_msec() - world_start)
		world.free()
	if model != null and model.ready:
		var levels: Array = []
		for body in model.domains.bodies:
			levels.append(body["level"])
		levels.sort()
		print("SHORE LEVELS min=", levels[0], " median=", levels[levels.size() / 2], " max=", levels[-1])
		for diagnostic in model.diagnostics:
			if str(diagnostic["kind"]) == "patch_failure":
				print("SHORE PATCH FAILURE ", diagnostic)
	for p in [Vector2(16, -8), Vector2(27, 2), Vector2(52, 20), Vector2(0, 0), Vector2(200, 0)]:
		var closest := {}
		for id in evidence.candidates(p, 40):
			var feature: Dictionary = evidence.features[id]
			var nearest := ShoreEvidence._nearest(p, feature)
			var kind := str(feature["kind"])
			if not closest.has(kind) or float(closest[kind]["distance"]) > float(nearest[1]):
				closest[kind] = {"distance": nearest[1], "at": nearest[0], "id": feature.get("id", "")}
		print("SHORE EVIDENCE ", p, " ", closest)
		print("SHORE POINT ", p, " height=", ground.height_at_world(p.x, p.y), " level=", ground.water_level_at(p.x, p.y), " wet=", ground.water_at(p.x, p.y))
		if model != null and model.ready:
			var id: int = model.domains.at(p)
			print("SHORE DETAIL body=", id, " dry=", model.dry_height(p.x, p.y), " nearest=", model.nearest(p))
	quit(0)
