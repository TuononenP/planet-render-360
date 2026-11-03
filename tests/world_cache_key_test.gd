extends SceneTree

## World cache key and save pump: godot --headless --script tests/world_cache_key_test.gd
## A world built after a far DEM / far-field fetch fell back (procedural
## backdrop, no rings, no drapes) must not share a key with the world
## built from the real far data, or a revisit on a good connection would
## load the degraded one.

func _init() -> void:
	_run()

func _data() -> LocationData:
	var d := LocationData.new()
	d.latitude = 37.775
	d.longitude = -122.419
	d.climate = {"t_warm_c": 15.0}
	return d

func _run() -> void:
	var failures: Array[String] = []
	var good := _data()
	good.far_heights = PackedFloat32Array([1.0, 2.0, 3.0])
	good.dem_rings = [{"zoom": 10}]
	good.far_drapes = [{"zoom": 10}]
	var bare := _data()
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("world without far heights, rings and drapes shares the key of one with them")
	for layer in ["far_heights", "dem_rings", "far_drapes"]:
		var d := _data()
		d.far_heights = good.far_heights
		d.dem_rings = good.dem_rings
		d.far_drapes = good.far_drapes
		d.set(layer, PackedFloat32Array() if layer == "far_heights" else [])
		if WorldCache.key(d) == WorldCache.key(good):
			failures.append("dropping only %s leaves the key unchanged" % layer)
	if WorldCache.key(good) != WorldCache.key(good):
		failures.append("key is not stable for the same data")
	good.far_towers = [{"height": 50.0}]
	bare.far_towers = [{"height": 51.0}]
	bare.far_heights = good.far_heights
	bare.dem_rings = good.dem_rings
	bare.far_drapes = good.far_drapes
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different far-city payloads of the same size must not share a world")
	bare.far_towers = good.far_towers
	good.pois = [{"name": "First"}]
	bare.pois = [{"name": "Second"}]
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different POIs of the same size must not share a world")
	bare.pois = good.pois
	for layer in ["trees", "barriers", "railways", "street_furniture", "piers", "landmark_candidates"]:
		good.set(layer, [{"x": 1.0}])
		bare.set(layer, [{"x": 2.0}])
		if WorldCache.key(good) == WorldCache.key(bare):
			failures.append("different %s payloads of the same size must not share a world" % layer)
		bare.set(layer, good.get(layer))
	good.seed_value = 10
	bare.seed_value = 11
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different generation seeds must not share a world")
	bare.seed_value = good.seed_value
	good.view = {"eye_lat": 48.85, "eye_lon": 2.35, "bearing": 0.0}
	bare.view = {"eye_lat": 48.86, "eye_lon": 2.35, "bearing": 0.0}
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different placement centres must not share a world")
	bare.view = good.view.duplicate()
	bare.view["bearing"] = 90.0
	if WorldCache.key(good) != WorldCache.key(bare):
		failures.append("a camera bearing alone must not change the world key")
	bare.focus = {"name": "landmark"}
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("focus presence can change the prop placement centre")
	bare.focus = {}
	good.landcover_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([50]))
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("a world missing land cover must not share the populated key")
	bare.landcover_image = Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([10]))
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("different raster contents must not share a world key")
	good.landcover_image = Image.create_from_data(1, 2, false, Image.FORMAT_L8, PackedByteArray([10, 50]))
	bare.landcover_image = Image.create_from_data(2, 1, false, Image.FORMAT_L8, PackedByteArray([10, 50]))
	if WorldCache.key(good) == WorldCache.key(bare):
		failures.append("raster dimensions must participate in the world key")
	WorldCache.dir_override = "user://isolated-world-cache"
	var paths := WorldCache._paths(good)
	if not str(paths["scene"]).begins_with(WorldCache.dir_override + "/") \
			or not str(paths["ground"]).begins_with(WorldCache.dir_override + "/"):
		failures.append("test cache override must contain both files")
	WorldCache.dir_override = ""
	# Save pump: a slow frame gets a bigger slice, a quit takes the most.
	if WorldCache.pump_budget_us(7000) != WorldCache.PUMP_US:
		failures.append("a fast frame should keep the base pump slice")
	if WorldCache.pump_budget_us(28000) <= WorldCache.PUMP_US:
		failures.append("a 28 ms frame should pump longer than the base slice")
	if WorldCache.pump_budget_us(10000000) != WorldCache.PUMP_MAX_US:
		failures.append("the pump slice should be capped")
	WorldCache.hurry = true
	if WorldCache.pump_budget_us(7000) != WorldCache.HURRY_US:
		failures.append("quitting should take the hurry slice")
	WorldCache.hurry = false
	if failures.is_empty():
		print("WORLD CACHE KEY PASS")
		quit(0)
	else:
		for f in failures:
			printerr("WORLD CACHE KEY FAIL: ", f)
		quit(1)
