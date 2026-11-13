extends SceneTree

## HsyCanopy (offline): godot --headless --script tests/hsy_canopy_test.gd
## Coverage, the WMS window matching LandcoverFetcher's canopy grid, and
## composing band images (+ an optional CHM) into L8 canopy heights.

const SIZE := 8

var failures: Array[String] = []

func _init() -> void:
	_coverage()
	_grid()
	_compose()
	if failures.is_empty():
		print("HSY CANOPY OK: coverage, grid, compose")
		quit(0)
	else:
		for f in failures:
			printerr("HSY CANOPY FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _coverage() -> void:
	_check(HsyCanopy.covers(60.1680, 24.9530), "Central Helsinki is covered")
	_check(HsyCanopy.covers(60.1760, 24.8050), "Tapiola is covered")
	_check(not HsyCanopy.covers(60.4518, 22.2666), "Turku is not")
	for i in HsyCanopy.LAYERS.size():
		_check(not HostPolicy.is_blocked(HsyCanopy.band_url(i, 60.168, 24.953, 768)), "Band URLs pass HostPolicy")

## The band request's bbox edges put pixel centres where plan_window
## samples (lat - ((z + 0.5) / size - 0.5) * EXTENT / 110540).
func _grid() -> void:
	var lat := 60.1680
	var lon := 24.9530
	var url := HsyCanopy.band_url(0, lat, lon, 768)
	var bb := url.get_slice("bbox=", 1).split(",")
	var lat0 := bb[0].to_float()
	var lon0 := bb[1].to_float()
	var lat1 := bb[2].to_float()
	var lon1 := bb[3].to_float()
	for z in [0, 383, 767]:
		var want := lat - ((float(z) + 0.5) / 768.0 - 0.5) * LandcoverFetcher.EXTENT_M / 110540.0
		var got := lat1 - (float(z) + 0.5) / 768.0 * (lat1 - lat0)
		_check(absf(want - got) < 1e-6, "Row %d centre must match plan_window (%.8f vs %.8f)" % [z, got, want])
	var lon_scale := 111320.0 * cos(deg_to_rad(lat))
	for x in [0, 767]:
		var want := lon + ((float(x) + 0.5) / 768.0 - 0.5) * LandcoverFetcher.EXTENT_M / lon_scale
		var got := lon0 + (float(x) + 0.5) / 768.0 * (lon1 - lon0)
		_check(absf(want - got) < 1e-6, "Column %d centre must match plan_window" % x)

func _band(hits: Array) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for p in hits:
		img.set_pixel(int(p) % SIZE, int(p) / SIZE, Color(0.1, 0.5, 0.1, 1))
	return img

func _compose() -> void:
	# Pixel 0: band 2–10; 1: 10–15; 2: >20 and 2–10 (highest wins); 3: none.
	var bands := [_band([0, 2]), _band([1]), _band([]), _band([2])]
	var plain := HsyCanopy.compose(bands, null, SIZE)
	_check(plain != null and plain.get_format() == Image.FORMAT_L8, "Bands compose to L8")
	if plain == null:
		return
	var d := plain.get_data()
	_check(d[0] == 6 and d[1] == 12 and d[2] == 24 and d[3] == 0,
		"Band mids, highest band wins, open ground is 0 (got %d %d %d %d)" % [d[0], d[1], d[2], d[3]])
	var chm_bytes := PackedByteArray()
	chm_bytes.resize(SIZE * SIZE)
	chm_bytes.fill(255)
	chm_bytes[0] = 9    # inside 2–10: kept
	chm_bytes[1] = 30   # above 10–15: clamped to 15
	chm_bytes[3] = 18   # CHM says tree, HSY says open: open
	var chm := Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_L8, chm_bytes)
	var refined := HsyCanopy.compose(bands, chm, SIZE).get_data()
	_check(refined[0] == 9 and refined[1] == 15 and refined[2] == 24 and refined[3] == 0,
		"CHM refines within the band, HSY decides presence (got %d %d %d %d)" % [refined[0], refined[1], refined[2], refined[3]])
	_check(HsyCanopy.compose(bands.slice(0, 3), null, SIZE) == null, "A missing band composes to null")
