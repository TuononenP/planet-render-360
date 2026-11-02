extends SceneTree

## World cache key: godot --headless --script tests/world_cache_key_test.gd
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
	if failures.is_empty():
		print("WORLD CACHE KEY PASS")
		quit(0)
	else:
		for f in failures:
			printerr("WORLD CACHE KEY FAIL: ", f)
		quit(1)
