extends SceneTree

## HelsinkiDem (offline): godot --headless --script tests/helsinki_dem_test.gd
## The GK25 projection, the GeoTIFF reader, the grid resample and the
## BareEarth hand-off.

func _init() -> void:
	_run()

## A 4 x 4 float32 GeoTIFF in one 4 x 4 tile, big-endian like GeoServer's:
## height = 10 + column + 2 * row, cell 5 m, top-left corner (1000, 2000).
func _tiff(tiled: bool, matrix: bool = false) -> PackedByteArray:
	var sp := StreamPeerBuffer.new()
	sp.big_endian = true
	sp.put_data("MM".to_utf8_buffer())
	sp.put_u16(42)
	sp.put_u32(8)
	var entries: Array = [
		[256, 4, 1, 4], [257, 4, 1, 4], [258, 3, 1, 32 << 16], [259, 3, 1, 1 << 16],
		[277, 3, 1, 1 << 16], [339, 3, 1, 3 << 16],
	]
	if tiled:
		entries.append_array([[322, 4, 1, 4], [323, 4, 1, 4], [324, 4, 1, 0]])
	else:
		entries.append_array([[273, 4, 1, 0], [278, 4, 1, 4]])
	if matrix:
		entries.append([34264, 12, 16, 0])
	else:
		entries.append_array([[33550, 12, 3, 0], [33922, 12, 6, 0]])
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var ifd_size := 2 + entries.size() * 12 + 4
	var scale_at := 8 + ifd_size
	var tie_at := scale_at + 24
	var data_at := scale_at + (128 if matrix else 72)
	sp.put_u16(entries.size())
	for e in entries:
		sp.put_u16(e[0])
		sp.put_u16(e[1])
		sp.put_u32(e[2])
		match e[0]:
			324, 273: sp.put_u32(data_at)
			33550: sp.put_u32(scale_at)
			33922, 34264: sp.put_u32(tie_at if e[0] == 33922 else scale_at)
			_: sp.put_u32(e[3])
	sp.put_u32(0)
	if matrix:
		for v in [5.0, 0.0, 0.0, 1000.0, 0.0, -5.0, 0.0, 2000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]:
			sp.put_double(v)
	else:
		for v in [5.0, 5.0, 0.0]:
			sp.put_double(v)
		for v in [0.0, 0.0, 0.0, 1000.0, 2000.0, 0.0]:
			sp.put_double(v)
	for r in 4:
		for c in 4:
			sp.put_float(10.0 + float(c) + 2.0 * float(r))
	return sp.data_array

func _run() -> void:
	var failures: Array[String] = []
	# Finlandia Hall: gdaltransform EPSG:4326 -> EPSG:3879.
	var p := HelsinkiDem.gk25(60.17582, 24.93356)
	if p.distance_to(Vector2(25496312.338, 6673663.445)) > 0.1:
		failures.append("gk25 gave %s, expected 25496312.338, 6673663.445" % p)
	if not HelsinkiDem.covers(60.1680, 24.9530):
		failures.append("the Helsinki preset is not covered")
	if HelsinkiDem.covers(48.8622, 2.2887) or HelsinkiDem.covers(59.3207, 18.0604):
		failures.append("a city outside Helsinki is covered")
	for variant in [[true, false], [false, false], [true, true]]:
		var tiled: bool = variant[0]
		var raster := HelsinkiDem.decode(_tiff(tiled, variant[1]))
		if raster.is_empty():
			failures.append("%s tiff did not decode" % ("tiled" if tiled else "strip"))
			continue
		var v: PackedFloat32Array = raster["values"]
		if v[0] != 10.0 or v[15] != 19.0 or v[6] != 14.0:
			failures.append("values read wrong: %s" % [v])
		if raster["origin"] != Vector2(1000.0, 2000.0) or raster["cell"] != Vector2(5.0, 5.0):
			failures.append("georeference read wrong: %s %s" % [raster["origin"], raster["cell"]])
		# The centre of cell (1, 1) holds 13; halfway to (2, 1) is 13.5.
		var h := HelsinkiDem.sample(raster, 1000.0 + 7.5, 2000.0 - 7.5)
		var mid := HelsinkiDem.sample(raster, 1000.0 + 10.0, 2000.0 - 7.5)
		if absf(h - 13.0) > 0.001 or absf(mid - 13.5) > 0.001:
			failures.append("sample gave %.3f / %.3f, expected 13 / 13.5" % [h, mid])
		if not is_nan(HelsinkiDem.sample(raster, 900.0, 2000.0)):
			failures.append("a point outside the raster has a height")
	if not HelsinkiDem.decode("not a tiff at all, just text".to_utf8_buffer()).is_empty():
		failures.append("garbage decoded")
	# Resample onto a heights grid: a flat 7.5 m raster over the window.
	var d := LocationData.new()
	d.latitude = 60.168
	d.longitude = 24.953
	d.grid_size = 24
	d.heights.resize(24 * 24)
	d.heights.fill(60.0)
	d.centre_elevation_m = 60.0
	d.water_level = 50.0
	d.dem_source = {"source_zoom": 14, "ground_model": "helsinki_2021_1m"}
	var centre := HelsinkiDem.gk25(d.latitude, d.longitude)
	var flat := PackedFloat32Array()
	flat.resize(100 * 100)
	flat.fill(7.5)
	d.ground_model = {"size": Vector2i(100, 100), "values": flat,
		"origin": centre - Vector2(2000.0, -2000.0), "cell": Vector2(40.0, 40.0)}
	if not HelsinkiDem.apply(d) or absf(d.heights[300] - 7.5) > 0.001 \
			or absf(d.centre_elevation_m - 7.5) > 0.001 or d.relief_metres != 0.0:
		failures.append("apply did not replace the heights: %s" % [d.centre_elevation_m])
	if BareEarth.applies(d) or not BareEarth.surface_model(d):
		failures.append("BareEarth still filters a bare-earth model, or lost the surface-model rule")
	d.dem_source = {"source_zoom": 14}
	if not BareEarth.applies(d):
		failures.append("BareEarth no longer applies to ArcticDEM")
	if failures.is_empty():
		print("HELSINKI DEM PASS")
		quit(0)
	else:
		for message in failures:
			printerr("HELSINKI DEM FAIL: ", message)
		quit(1)
