extends SceneTree

## Native photo reads: godot --headless --path . --script tests/photo_sampler_test.gd
## PhotoSampler (native/, tools/build_native.sh) must read exactly what
## GroundCover._photo_at and _green_around do, at random points on and off
## a synthetic mosaic, for several latitudes, zooms and source overrides.
## Skips, passing, when the library is not built.

func _init() -> void:
	if not ClassDB.class_exists("PhotoSampler"):
		print("PHOTO_SAMPLER SKIP: PhotoSampler is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var img := Image.create(768, 768, false, Image.FORMAT_RGB8)
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, Color(rng.randf() * 0.5, rng.randf(), rng.randf() * 0.4))
	for place in [[45.437, 12.335, 17, {}], [60.17, 24.94, 16, {}], [-33.86, 151.21, 18, {}],
			[48.857, 2.352, 16, {"source_zoom": 17, "source_span": 2}]]:
		var data := LocationData.new()
		data.latitude = place[0]
		data.longitude = place[1]
		data.satellite_zoom = place[2]
		data.satellite_source = place[3]
		data.satellite_image = img
		var zoom: int = int((place[3] as Dictionary).get("source_zoom", place[2]))
		var centre := TileFetcher.global_pixel(data.latitude, data.longitude, zoom)
		var mosaic := float(TerrainBuilder.satellite_span_tiles(data) * SatelliteFetcher.TILE_PX)
		data.satellite_origin_px = centre - Vector2.ONE * mosaic * 0.5
		var sampler := GroundCover._photo_sampler(data)
		var bad := 0
		for k in 3000:
			var x := rng.randf_range(-700.0, 700.0)
			var z := rng.randf_range(-700.0, 700.0)
			if var_to_bytes(sampler.photo(x, z)) != var_to_bytes(GroundCover._photo_at(data, x, z)) \
					or GroundCover._green_near(sampler, data, x, z) != GroundCover._green_around(data, x, z):
				bad += 1
		if bad > 0:
			failures.append("%s: %d of 3000 points differ" % [str(place.slice(0, 3)), bad])
	if failures.is_empty():
		print("PHOTO_SAMPLER PASS")
		quit(0)
	else:
		for f in failures:
			push_error("PHOTO_SAMPLER FAIL: " + f)
		quit(1)
