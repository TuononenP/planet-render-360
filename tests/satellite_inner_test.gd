extends SceneTree

## Headless: godot --headless --script tests/satellite_inner_test.gd
## Desktop Ultra's z18 inner mosaic (GroundMaterial.inner_map): the main
## photo's UV maps to the inner mosaic's UV within half a z18 pixel of the
## exact lat/lon → mercator path anywhere over the inner area, north and
## south.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	var z := RenderSettings.SATELLITE_INNER_ZOOM
	var size := float(RenderSettings.SATELLITE_INNER_SPAN * SatelliteFetcher.TILE_PX)
	for place in [[48.8566, 2.3522], [60.4518, 22.2666], [-33.8568, 151.2153]]:
		var d := LocationData.new()
		d.latitude = place[0]
		d.longitude = place[1]
		var centre := TileFetcher.global_pixel(d.latitude, d.longitude, z)
		d.satellite_inner_origin_px = (centre - Vector2(size, size) * 0.5).floor()
		# The main mosaic: z17, 13 tiles a side.
		d.satellite_source = {"source_zoom": 17, "source_span": 13}
		var c17 := TileFetcher.global_pixel(d.latitude, d.longitude, 17)
		d.satellite_origin_px = ((c17 / 256.0).floor() - Vector2(6, 6)) * 256.0
		var map := GroundMaterial.inner_map(d)
		for p in [Vector2(0, 0), Vector2(320, -280), Vector2(-330, 300), Vector2(150, 340)]:
			var w: Vector2 = p * m
			# The exact path in float64 (WorldScale / TileFetcher Vector2s
			# are float32, ~1 m coarse).
			var la := d.latitude - float(w.y) / 110540.0
			var lo := d.longitude + float(w.x) / (111320.0 * cos(deg_to_rad(d.latitude)))
			var n := float(1 << z) * 256.0
			var exact := Vector2(((lo + 180.0) / 360.0 * n - float(d.satellite_inner_origin_px.x)) / size,
				((1.0 - asinh(tan(deg_to_rad(la))) / PI) / 2.0 * n - float(d.satellite_inner_origin_px.y)) / size)
			var uv := TerrainBuilder.satellite_uv(d, w.x, w.y)
			var fit := Vector2(uv.x * map.x + map.z, uv.y * map.y + map.w)
			if (exact - fit).length() * size > 0.5:
				failures.append("lat %.1f, %s m: off by %.2f px" % [d.latitude, p, (exact - fit).length() * size])
	failures.erase(failures[0])
	if failures.is_empty():
		print("SATELLITE INNER OK: inner mosaic UV within half a z18 pixel over the inner area")
		quit(0)
	else:
		for f in failures:
			printerr("SATELLITE INNER FAIL: ", f)
		quit(1)
