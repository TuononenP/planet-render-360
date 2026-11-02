extends SceneTree

## Headless: godot --headless --script tests/road_decals_test.gd
## Street ironwork decals (RoadDecals, desktop Ultra): covers in the lanes
## and grates at the kerbs of urban streets, none off Ultra, the same
## street always dressed the same way, nearest kept under the cap; leaf
## litter under near street trees, thickest in autumn.

func _init() -> void:
	_run()

func _data(preset: int) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, preset)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.seed_value = 7
	d.latitude = 48.8566
	d.longitude = 2.3522
	d.land_polygons = [{"class": "urban", "points": PackedVector2Array([Vector2(-400, -400),
		Vector2(400, -400), Vector2(400, 400), Vector2(-400, 400)]), "holes": []}]
	d.roads = [{"class": "residential", "width_m": 8.0, "lanes": 2,
		"points": PackedVector2Array([Vector2(-150, 0), Vector2(150, 0)])}]
	return d

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	var ultra := _data(RenderSettings.Preset.ULTRA)
	var ground := GroundTruth.new(ultra)
	var root := Node3D.new()
	var n := RoadDecals.build(root, ultra, ground)
	if not RenderQuality.ultra_desktop(ultra.quality_preset):
		print("ROAD DECALS SKIP: no Forward+ here")
		root.free()
		quit(0)
		return
	if ground.land_class_at(0.0, 0.0) != "urban":
		failures.append("fixture should read as urban")
	var covers := 0
	var drains := 0
	for d: Decal in root.get_node("RoadDecals").get_children() if n > 0 else []:
		var off := absf(d.position.z) / m
		if d.size.x == d.size.z:
			covers += 1
			if off > 2.1:
				failures.append("a cover should sit in the lanes, %.1f m off the axis" % off)
		else:
			drains += 1
			if absf(off - 3.55) > 0.1:
				failures.append("a grate should sit at the kerb, %.1f m off the axis" % off)
	# 300 m of street: ~8 covers, ~12 grates.
	if covers < 5 or covers > 11 or drains < 9 or drains > 14:
		failures.append("300 m of street: %d covers, %d grates" % [covers, drains])
	var again := Node3D.new()
	RoadDecals.build(again, ultra, ground)
	if n > 0 and (again.get_node("RoadDecals").get_child(0) as Decal).position \
			!= (root.get_node("RoadDecals").get_child(0) as Decal).position:
		failures.append("the same street should get the same ironwork")
	var high := Node3D.new()
	if RoadDecals.build(high, _data(RenderSettings.Preset.HIGH), ground) != 0:
		failures.append("decals are desktop Ultra only")
	# Leaf litter under mapped street trees, thicker in autumn.
	var mix := {}
	for season in [LocationData.Season.SUMMER, LocationData.Season.AUTUMN]:
		var td := _data(RenderSettings.Preset.ULTRA)
		td.season = season
		td.trees = [{"x": 20.0 * m, "z": 8.0 * m}, {"x": -40.0 * m, "z": -8.0 * m}, {"x": 600.0 * m, "z": 0.0}]
		var tr := Node3D.new()
		RoadDecals.build(tr, td, GroundTruth.new(td))
		var litter := 0
		for dd: Decal in tr.get_node("RoadDecals").get_children():
			if dd.texture_albedo == RoadDecals.litter_texture():
				litter += 1
				mix[season] = dd.albedo_mix
		if litter != 2:
			failures.append("the two near trees should get litter, got %d" % litter)
		tr.free()
	if float(mix.get(LocationData.Season.AUTUMN, 0.0)) <= float(mix.get(LocationData.Season.SUMMER, 1.0)):
		failures.append("autumn litter should be thicker than summer's: %s" % mix)
	root.free()
	again.free()
	high.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("ROAD DECALS OK: lane covers + kerb grates on urban streets, Ultra only, deterministic")
		quit(0)
	else:
		for f in failures:
			printerr("ROAD DECALS FAIL: ", f)
		quit(1)
