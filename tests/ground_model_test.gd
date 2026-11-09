extends SceneTree

## GroundModel (offline): godot --headless --script tests/ground_model_test.gd
## Source coverage, the BIL / GSI PNG / deflate GeoTIFF readers, the hole
## fill, the grid resample and the BareEarth hand-off.

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

## A little-endian float32 GeoTIFF of `rows` (Array of PackedFloat32Array),
## two rows to a strip, origin (1000, 2000), cell 10 m. `predicted`: Adobe
## deflate with the floating-point predictor, as the AHN WCS answers;
## else uncompressed.
func _tiff(rows: Array, predicted: bool) -> PackedByteArray:
	var w: int = rows[0].size()
	var h: int = rows.size()
	var strips: Array = []
	for first in range(0, h, 2):
		var raw := PackedByteArray()
		for r in range(first, mini(first + 2, h)):
			var line := PackedByteArray()
			line.resize(w * 4)
			for c in w:
				line.encode_float(c * 4, rows[r][c])
			if predicted:
				var planes := PackedByteArray()
				planes.resize(w * 4)
				for c in w:
					for k in 4:
						planes[k * w + c] = line[c * 4 + 3 - k]
				var diff := planes.duplicate()
				for i in range(w * 4 - 1, 0, -1):
					diff[i] = (planes[i] - planes[i - 1]) & 0xFF
				raw.append_array(diff)
			else:
				raw.append_array(line)
		strips.append(raw.compress(FileAccess.COMPRESSION_DEFLATE) if predicted else raw)
	var entries: Array = [[256, 4, 1, w], [257, 4, 1, h], [258, 3, 1, 32], [259, 3, 1, 8 if predicted else 1],
		[262, 3, 1, 1], [273, 4, strips.size(), 0], [277, 3, 1, 1], [278, 3, 1, 2],
		[279, 4, strips.size(), 0], [317, 3, 1, 3 if predicted else 1], [339, 3, 1, 3],
		[33550, 12, 3, 0], [33922, 12, 6, 0]]
	var ifd_at := 8
	var extra_at := ifd_at + 2 + entries.size() * 12 + 4
	var offsets_at := extra_at
	var counts_at := offsets_at + 4 * strips.size()
	var scale_at := counts_at + 4 * strips.size()
	var tie_at := scale_at + 24
	var data_at := tie_at + 48
	var sp := StreamPeerBuffer.new()
	sp.big_endian = false
	sp.put_data("II".to_utf8_buffer())
	sp.put_u16(42)
	sp.put_u32(ifd_at)
	sp.put_u16(entries.size())
	for e in entries:
		sp.put_u16(e[0])
		sp.put_u16(e[1])
		sp.put_u32(e[2])
		match e[0]:
			273: sp.put_u32(offsets_at)
			279: sp.put_u32(counts_at)
			33550: sp.put_u32(scale_at)
			33922: sp.put_u32(tie_at)
			_: sp.put_u32(e[3])
	sp.put_u32(0)
	var at := data_at
	for s in strips:
		sp.put_u32(at)
		at += s.size()
	for s in strips:
		sp.put_u32(s.size())
	for v in [10.0, 10.0, 0.0]:
		sp.put_double(v)
	for v in [0.0, 0.0, 0.0, 1000.0, 2000.0, 0.0]:
		sp.put_double(v)
	for s in strips:
		sp.put_data(s)
	return sp.data_array

func _run() -> void:
	_sources()
	_bil()
	_gsi_png()
	_tiff_reader()
	_fill_and_sample()
	_apply()
	_bare_earth_rule()
	_hosts()
	_tiled_tiffs()
	_grids()
	_reproject_and_mosaic()
	_swiss_listing()
	if failures.is_empty():
		print("GROUND MODEL PASS")
		quit(0)
	else:
		for message in failures:
			printerr("GROUND MODEL FAIL: ", message)
		quit(1)

func _sources() -> void:
	for row in [[35.6595, 139.7005, "gsi", "Shibuya"], [34.6937, 135.5023, "gsi", "Osaka"],
			[26.2124, 127.6809, "gsi", "Naha"], [43.0621, 141.3544, "gsi", "Sapporo"],
			[48.8566, 2.3522, "ign", "Paris"], [43.2965, 5.3698, "ign", "Marseille"],
			[52.3740, 4.8897, "ahn", "Amsterdam"], [52.0800, 4.3100, "ahn", "The Hague"],
			[51.2194, 4.4025, "", "Antwerp"], [50.8504, 4.3488, "", "Brussels"],
			[35.1796, 129.0756, "", "Busan"], [37.5665, 126.9780, "", "Seoul"],
			[51.5074, -0.1278, "", "London"], [53.4808, -2.2426, "", "Manchester"],
			[51.4545, -2.5879, "", "Bristol"], [51.4816, -3.1791, "", "Cardiff"],
			[55.9533, -3.1883, "", "Edinburgh"], [46.9480, 7.4474, "swisstopo", "Bern"],
			[47.3769, 8.5417, "swisstopo", "Zurich"], [46.2044, 6.1432, "swisstopo", "Geneva"],
			[46.0037, 8.9511, "swisstopo", "Lugano"], [48.1351, 11.5820, "", "Munich"], [60.1699, 24.9384, "", "Helsinki"],
			[40.7128, -74.0060, "", "New York"]]:
		_check(GroundModel.source_for(row[0], row[1]) == row[2],
			"%s is covered by '%s', expected '%s'" % [row[3], GroundModel.source_for(row[0], row[1]), row[2]])
	GroundModel.enabled = false
	_check(GroundModel.source_for(35.6595, 139.7005) == "", "the test hook did not switch the sources off")
	GroundModel.enabled = true

func _bil() -> void:
	var b := PackedByteArray()
	b.resize(4 * 4 * 4)
	for i in 16:
		b.encode_float(i * 4, 10.0 + float(i))
	b.encode_float(5 * 4, -99999.0)
	var r := GroundModel.decode_bil(b, 4, Vector2(100.0, 200.0), 7.0)
	_check(not r.is_empty(), "BIL did not decode")
	if r.is_empty():
		return
	var v: PackedFloat32Array = r["values"]
	_check(v[0] == 10.0 and v[15] == 25.0 and is_nan(v[5]), "BIL values read wrong: %s" % [v])
	_check(r["origin"] == Vector2(100.0, 200.0) and r["cell"] == Vector2(7.0, 7.0), "BIL georeference wrong")
	_check(GroundModel.decode_bil(b.slice(0, 60), 4, Vector2.ZERO, 1.0).is_empty(), "a short BIL decoded")

func _gsi_png() -> void:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	img.fill(Color8(0, 0, 100))  # 100 cm
	img.set_pixel(1, 0, Color8(0x80, 0, 0))  # 2^23: no data
	img.set_pixel(2, 0, Color8(0xFF, 0xFF, 0xEC))  # -20 cm
	img.set_pixel(3, 0, Color8(0x00, 0x27, 0x10))  # 10000 cm = 100 m
	var px := GroundModel.decode_gsi_png(img.save_png_to_buffer())
	_check(px.size() == 65536, "GSI PNG did not decode")
	if px.size() == 65536:
		_check(absf(px[0] - 1.0) < 0.001 and is_nan(px[1]) and absf(px[2] + 0.2) < 0.001
			and absf(px[3] - 100.0) < 0.001, "GSI PNG heights wrong: %s %s %s %s" % [px[0], px[1], px[2], px[3]])
	_check(GroundModel.decode_gsi_png("junk".to_utf8_buffer()).is_empty(), "junk decoded as a GSI tile")

func _tiff_reader() -> void:
	var rows: Array = []
	for r in 5:
		var line := PackedFloat32Array()
		for c in 6:
			line.append(-2.5 + float(c) * 1.25 + float(r) * 3.0)
		rows.append(line)
	for predicted in [false, true]:
		var raster := GroundTiff.decode(_tiff(rows, predicted))
		_check(not raster.is_empty(), "%s tiff did not decode" % ("deflate" if predicted else "plain"))
		if raster.is_empty():
			continue
		var v: PackedFloat32Array = raster["values"]
		var same := v.size() == 30
		for r in 5:
			for c in 6:
				same = same and absf(v[r * 6 + c] - rows[r][c]) < 0.0001
		_check(same, "tiff values read wrong (predicted %s): %s" % [predicted, v])
		_check(raster["origin"] == Vector2(1000.0, 2000.0) and raster["cell"] == Vector2(10.0, 10.0),
			"tiff georeference wrong: %s %s" % [raster["origin"], raster["cell"]])
	_check(GroundTiff.decode("not a tiff at all, just text".to_utf8_buffer()).is_empty(), "garbage decoded")

func _fill_and_sample() -> void:
	var v := PackedFloat32Array([10.0, NAN, 12.0, NAN, NAN, NAN, 16.0, NAN, 18.0])
	var r := {"size": Vector2i(3, 3), "values": v, "origin": Vector2(0.0, 30.0), "cell": Vector2(10.0, 10.0)}
	_check(absf(GroundModel.missing_share(r) - 5.0 / 9.0) < 0.001, "missing share wrong")
	_check(GroundModel.fill_missing(r), "fill refused a raster with data")
	var f: PackedFloat32Array = r["values"]
	var finite := true
	for h in f:
		finite = finite and not is_nan(h)
	_check(finite and f[0] == 10.0 and absf(f[1] - 11.0) < 0.001, "holes not filled from neighbours: %s" % [f])
	# The centre of cell (0, 0) holds 10; a point past the corner clamps to it.
	_check(absf(GroundModel.sample(r, 5.0, 25.0) - 10.0) < 0.001, "sample at a cell centre wrong")
	_check(absf(GroundModel.sample(r, -50.0, 90.0) - 10.0) < 0.001, "sample outside did not clamp")
	var empty := {"size": Vector2i(2, 2), "values": PackedFloat32Array([NAN, NAN, NAN, NAN]),
		"origin": Vector2.ZERO, "cell": Vector2.ONE}
	_check(not GroundModel.fill_missing(empty), "fill invented heights for an empty raster")

func _data(lat: float, lon: float) -> LocationData:
	var d := LocationData.new()
	d.latitude = lat
	d.longitude = lon
	d.grid_size = 24
	d.heights.resize(24 * 24)
	d.heights.fill(60.0)
	d.centre_elevation_m = 60.0
	d.water_level = 50.0
	d.dem_source = {"source_zoom": 14}
	return d

func _apply() -> void:
	var d := _data(35.6595, 139.7005)
	var c := GroundModel.merc(d.latitude, d.longitude)
	var flat := PackedFloat32Array()
	flat.resize(100 * 100)
	flat.fill(15.0)
	flat[0] = NAN
	d.ground_model = {"size": Vector2i(100, 100), "values": flat,
		"origin": c - Vector2(2000.0, -2000.0), "cell": Vector2(40.0, 40.0)}
	_check(not GroundModel.apply(d), "apply ran without a ground_model marker")
	d.dem_source["ground_model"] = "helsinki_2021_1m"
	_check(not GroundModel.apply(d), "apply took Helsinki's raster")
	d.dem_source["ground_model"] = "gsi"
	_check(GroundModel.apply(d) and absf(d.heights[300] - 15.0) < 0.001 and d.relief_metres == 0.0
		and absf(d.centre_elevation_m - 15.0) < 0.001, "apply did not replace the heights: %s" % [d.centre_elevation_m])
	_check(is_equal_approx(d.water_level, WaterBuilder.SEA_LEVEL_M), "apply left the Terrarium sea level")

func _bare_earth_rule() -> void:
	for row in [[35.6595, 139.7005, true, "Tokyo"], [48.8566, 2.3522, true, "Paris"],
			[45.4215, -75.6972, true, "Ottawa"], [51.5074, -0.1278, false, "London"],
			[53.4808, -2.2426, false, "Manchester"], [55.9533, -3.1883, true, "Edinburgh"], [-33.9249, 18.4241, true, "Cape Town"],
			[60.1699, 24.9384, true, "Helsinki"], [40.7128, -74.0060, false, "New York"],
			[38.9072, -77.0369, false, "Washington"], [37.7749, -122.4194, false, "San Francisco"],
			[21.3069, -157.8583, false, "Honolulu"]]:
		var d := _data(row[0], row[1])
		_check(BareEarth.applies(d) == row[2], "BareEarth.applies at %s is not %s" % [row[3], row[2]])
		d.dem_source["ground_model"] = "gsi"
		_check(not BareEarth.applies(d), "BareEarth filters a bare-earth model at %s" % row[3])
	var procedural := _data(35.6595, 139.7005)
	procedural.dem_source = {"source_zoom": 0, "procedural": true}
	_check(not BareEarth.applies(procedural), "BareEarth filters a procedural grid")

func _hosts() -> void:
	for url in [GroundModelFetcher.ign_url(48.8566, 2.3522), GroundModelFetcher.ahn_url(52.374, 4.8897),
			GroundModelFetcher.GSI_URL]:
		_check(url.begins_with("https://") and not HostPolicy.is_blocked(url), "host policy refuses %s" % url)
	var ign := GroundModelFetcher.ign_url(48.8566, 2.3522)
	_check(ign.contains("CRS=EPSG:3857") and ign.contains("WIDTH=300") and ign.contains("x-bil"), "IGN request wrong: %s" % ign)
	_check(GroundModelFetcher.ahn_url(52.374, 4.8897).contains("dtm_05m"), "AHN coverage wrong")

class _Bits extends RefCounted:
	var out := PackedByteArray()
	var acc := 0
	var bits := 0
	func put(code: int, width: int) -> void:
		acc = (acc << width) | code
		bits += width
		while bits >= 8:
			out.append((acc >> (bits - 8)) & 0xFF)
			bits -= 8
			acc &= (1 << bits) - 1
	func finish() -> PackedByteArray:
		if bits > 0:
			out.append((acc << (8 - bits)) & 0xFF)
		return out

## TIFF LZW, as libtiff writes it: clear first, codes widen one entry early,
## a clear code when the table is full.
func _lzw_encode(data: PackedByteArray) -> PackedByteArray:
	var b := _Bits.new()
	var table := {}
	var next := 258
	var width := 9
	b.put(256, width)
	var cur := -1
	for byte in data:
		if cur == -1:
			cur = byte
			continue
		var key := (cur << 8) | byte
		if table.has(key):
			cur = table[key]
			continue
		b.put(cur, width)
		table[key] = next
		next += 1
		if next == 4094:
			b.put(256, width)
			table.clear()
			next = 258
			width = 9
		elif next == 512 or next == 1024 or next == 2048:
			width += 1
		cur = byte
	b.put(cur, width)
	next += 1
	if next == 512 or next == 1024 or next == 2048:
		width += 1
	b.put(257, width)
	return b.finish()

## A float32 GeoTIFF of `rows` in `tw` x `th` tiles (edge tiles padded with
## zeros), LZW or plain, little- or big-endian, with a pixel scale and
## tiepoint or a ModelTransformation matrix; origin (1000, 2000), cell 10 m.
func _tiled(rows: Array, tw: int, th: int, lzw: bool, big: bool, matrix: bool) -> PackedByteArray:
	var w: int = rows[0].size()
	var h: int = rows.size()
	var tiles: Array = []
	for ty in ceili(float(h) / th):
		for tx in ceili(float(w) / tw):
			var sp := StreamPeerBuffer.new()
			sp.big_endian = big
			for r in th:
				for c in tw:
					var y := ty * th + r
					var x := tx * tw + c
					sp.put_float(rows[y][x] if y < h and x < w else 0.0)
			var raw := sp.data_array
			if lzw:
				# libtiff reads float bytes in the file's order; the encoder
				# only needs the byte stream.
				raw = _lzw_encode(raw)
			tiles.append(raw)
	var entries: Array = [[256, 4, 1, w], [257, 4, 1, h], [258, 3, 1, 32], [259, 3, 1, 5 if lzw else 1],
		[262, 3, 1, 1], [277, 3, 1, 1], [322, 4, 1, tw], [323, 4, 1, th],
		[324, 4, tiles.size(), 0], [325, 4, tiles.size(), 0], [339, 3, 1, 3]]
	if matrix:
		entries.append([34264, 12, 16, 0])
	else:
		entries.append_array([[33550, 12, 3, 0], [33922, 12, 6, 0]])
	entries.sort_custom(func(a: Array, c: Array) -> bool: return a[0] < c[0])
	var extra_at := 8 + 2 + entries.size() * 12 + 4
	var offsets_at := extra_at
	var counts_at := offsets_at + 4 * tiles.size()
	var geo_at := counts_at + 4 * tiles.size()
	var data_at := geo_at + 128
	var sp := StreamPeerBuffer.new()
	sp.big_endian = big
	sp.put_data(("MM" if big else "II").to_utf8_buffer())
	sp.put_u16(42)
	sp.put_u32(8)
	sp.put_u16(entries.size())
	for e in entries:
		sp.put_u16(e[0])
		sp.put_u16(e[1])
		sp.put_u32(e[2])
		match e[0]:
			324: sp.put_u32(offsets_at)
			325: sp.put_u32(counts_at)
			33550, 33922, 34264: sp.put_u32(geo_at if e[0] != 33922 else geo_at + 24)
			_:
				if e[1] == 3:
					if big:
						sp.put_u16(e[3])
						sp.put_u16(0)
					else:
						sp.put_u16(e[3])
						sp.put_u16(0)
				else:
					sp.put_u32(e[3])
	sp.put_u32(0)
	var at := data_at
	for t in tiles:
		sp.put_u32(at)
		at += t.size()
	for t in tiles:
		sp.put_u32(t.size())
	if matrix:
		for v in [10.0, 0.0, 0.0, 1000.0, 0.0, -10.0, 0.0, 2000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]:
			sp.put_double(v)
	else:
		for v in [10.0, 10.0, 0.0, 0.0, 0.0, 0.0, 1000.0, 2000.0, 0.0]:
			sp.put_double(v)
	while sp.data_array.size() < data_at:
		sp.put_u8(0)
	for t in tiles:
		sp.put_data(t)
	return sp.data_array

func _tiled_tiffs() -> void:
	var rows: Array = []
	var seed_value := 7
	for r in 70:
		var line := PackedFloat32Array()
		for c in 100:
			seed_value = (seed_value * 1103515245 + 12345) & 0x7FFFFFFF
			line.append(float(seed_value % 4000) / 10.0 - 50.0)
		rows.append(line)
	for row in [["LZW tiles, little-endian", true, false, false], ["plain tiles, big-endian matrix", false, true, true]]:
		var raster := GroundTiff.decode(_tiled(rows, 64, 64, row[1], row[2], row[3]), row[1])
		_check(not raster.is_empty(), "%s did not decode" % row[0])
		if raster.is_empty():
			continue
		var v: PackedFloat32Array = raster["values"]
		var same := v.size() == 7000
		for r in 70:
			for c in 100:
				same = same and absf(v[r * 100 + c] - rows[r][c]) < 0.0001
		_check(same, "%s: values read wrong" % row[0])
		_check(raster["origin"] == Vector2(1000.0, 2000.0) and raster["cell"] == Vector2(10.0, 10.0),
			"%s: georeference wrong: %s %s" % [row[0], raster["origin"], raster["cell"]])

func _grids() -> void:
	# gdaltransform with the swisstopo definition.
	for row in [[46.9480, 7.4474, 2600667.5, 1199657.3, "Bern"], [47.3769, 8.5417, 2683303.9, 1247925.6, "Zurich"]]:
		var got := NationalGrids.lv95(row[0], row[1])
		_check(got.distance_to(Vector2(row[2], row[3])) < 2.0,
			"%s projects to %s, expected %s, %s" % [row[4], got, row[2], row[3]])

func _reproject_and_mosaic() -> void:
	# A 4 x 4 raster over x 100..140, y 200..160 whose height is x + y / 10.
	var v := PackedFloat32Array()
	for r in 4:
		for c in 4:
			v.append(105.0 + 10.0 * c + (195.0 - 10.0 * r) / 10.0)
	v[0] = NAN
	var src := {"size": Vector2i(4, 4), "values": v, "origin": Vector2(100.0, 200.0), "cell": Vector2(10.0, 10.0)}
	_check(absf(GroundModel.sample_raw(src, 115.0, 185.0) - (115.0 + 18.5)) < 0.001, "sample_raw wrong inside")
	_check(is_nan(GroundModel.sample_raw(src, 90.0, 185.0)), "sample_raw invented a height outside")
	var edge := GroundModel.sample_raw(src, 105.0, 195.0)
	_check(not is_nan(edge), "a missing corner gave NAN instead of the mean of the others")
	var win := {"c": Vector2(0.0, 0.0), "half": 20.0}
	# Native (x, y) = Mercator metres + (120, 180): the window sits on the raster.
	var native := func(lat: float, lon: float) -> Vector2:
		var m := GroundModel.merc(lat, lon)
		return m + Vector2(120.0, 180.0)
	var r := GroundModel.reproject(src, native, win, 4)
	var rv: PackedFloat32Array = r["values"]
	_check(r["size"] == Vector2i(4, 4) and r["origin"] == Vector2(-20.0, 20.0) and r["cell"] == Vector2(10.0, 10.0),
		"reproject georeference wrong")
	# Cell (row 1, col 2): centre (5, 5) -> native (125, 185).
	_check(absf(rv[1 * 4 + 2] - (125.0 + 18.5)) < 0.01, "reproject value wrong: %s" % rv[6])
	var a := {"size": Vector2i(2, 2), "values": PackedFloat32Array([1.0, 2.0, 3.0, 4.0]),
		"origin": Vector2(0.0, 20.0), "cell": Vector2(10.0, 10.0)}
	var b := {"size": Vector2i(2, 2), "values": PackedFloat32Array([5.0, 6.0, 7.0, -9999.0]),
		"origin": Vector2(20.0, 20.0), "cell": Vector2(10.0, 10.0)}
	var m := GroundModelFetcher.mosaic_rasters([a, b])
	var mv: PackedFloat32Array = m["values"]
	_check(m["size"] == Vector2i(4, 2) and mv[0] == 1.0 and mv[2] == 5.0 and mv[5] == 4.0 and mv[7] != mv[7],
		"mosaic wrong: %s" % [mv])

func _swiss_listing() -> void:
	var listing := JSON.stringify({"features": [
		{"id": "swissalti3d_2019_2600-1198", "assets": {
			"a": {"href": "https://data.geo.admin.ch/ch.swisstopo.swissalti3d/swissalti3d_2019_2600-1198/swissalti3d_2019_2600-1198_2_2056_5728.tif"},
			"b": {"href": "https://data.geo.admin.ch/x/swissalti3d_2019_2600-1198_0.5_2056_5728.tif"}}},
		{"id": "swissalti3d_2022_2600-1198", "assets": {
			"a": {"href": "https://data.geo.admin.ch/ch.swisstopo.swissalti3d/swissalti3d_2022_2600-1198/swissalti3d_2022_2600-1198_2_2056_5728.tif"}}},
		{"id": "swissalti3d_2019_2601-1198", "assets": {
			"a": {"href": "https://example.ru/swissalti3d_2019_2601-1198_2_2056_5728.tif"}}}]}).to_utf8_buffer()
	var hrefs := GroundModelFetcher.swiss_tile_hrefs(listing)
	_check(hrefs.size() == 1 and hrefs[0].contains("2022_2600-1198_2_2056"),
		"swiss listing gave %s, expected only the newest 2 m tile from data.geo.admin.ch" % [hrefs])
	_check(GroundModelFetcher.swiss_tile_hrefs("not json".to_utf8_buffer()).is_empty(), "junk listing gave tiles")
	var stac := GroundModelFetcher.stac_url(46.948, 7.4474)
	_check(stac.begins_with("https://") and not HostPolicy.is_blocked(stac) and stac.contains("bbox="),
		"STAC request wrong: %s" % stac)
