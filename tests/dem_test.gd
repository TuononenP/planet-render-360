extends SceneTree

## Headless live-source test: godot --headless --script tests/dem_test.gd
## Requires network on first run; afterwards the tile cache serves it.
## Asserts the Terrarium decode yields plausible Paris elevations, then
## (T1.3) that the pipeline's true-metre conversion matches source-tile
## metres and beats the legacy squash on scorecard check (a), then
## (T2.1) that the z14 mosaic beats the z12 mid source on (a) at
## Interlaken/Big Sur, degrades offline without hanging, and records
## stage times against the plan §3.1 budgets.

var _done := false
var _ok := false
var _reason := ""
var _raw: PackedFloat32Array = PackedFloat32Array()

func _init() -> void:
	_run()

func _run() -> void:
	# Tile math is pure and runs offline.
	var tile := DemFetcher.tile_xy(48.8566, 2.3522, 12)
	if tile != Vector2i(2074, 1409):
		printerr("DEM FAIL: unexpected Paris tile ", tile)
		quit(1)
		return

	var fetcher := DemFetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.succeeded.connect(func(heights: PackedFloat32Array, grid: int) -> void:
		var mn := heights[0]
		var mx := heights[0]
		for h in heights:
			mn = minf(mn, h)
			mx = maxf(mx, h)
		_ok = grid == 48 and heights.size() == 48 * 48 \
			and mn > -50.0 and mx < 600.0 and mx - mn > 5.0
		_reason = "range %.1f..%.1f m" % [mn, mx]
		_done = true)
	fetcher.failed.connect(func(reason: String) -> void:
		_reason = reason
		_done = true)
	fetcher.fetch(48.8566, 2.3522, 48)

	var waited := 0.0
	while not _done and waited < 20.0:
		await process_frame
		waited += 1.0 / 60.0

	if not _ok:
		printerr("DEM FAIL: ", _reason if _reason != "" else "timeout")
		quit(1)
		return
	print("DEM OK: Paris tile decoded, ", _reason)

	# Far backdrop: zoom-8 tile sampled whole, viewpoint fraction sane.
	_done = false
	_ok = false
	var far := DemFetcher.new()
	root.add_child(far)
	await process_frame
	far.succeeded.connect(func(heights: PackedFloat32Array, grid: int) -> void:
		var mn := heights[0]
		var mx := heights[0]
		for h in heights:
			mn = minf(mn, h)
			mx = maxf(mx, h)
		_ok = grid == 16 and heights.size() == 16 * 16 \
			and far.far_centre_frac.x >= 0.0 and far.far_centre_frac.x <= 1.0 \
			and far.far_centre_frac.y >= 0.0 and far.far_centre_frac.y <= 1.0 \
			and mn > -100.0 and mx < 1500.0
		_reason = "far range %.1f..%.1f m frac %s" % [mn, mx, str(far.far_centre_frac)]
		_done = true)
	far.failed.connect(func(reason: String) -> void:
		_reason = reason
		_done = true)
	far.fetch_far(48.8566, 2.3522, 16)
	waited = 0.0
	while not _done and waited < 20.0:
		await process_frame
		waited += 1.0 / 60.0
	if not _ok:
		printerr("DEM FAR FAIL: ", _reason if _reason != "" else "timeout")
		quit(1)
		return
	print("DEM FAR OK: Paris zoom-8 tile decoded, ", _reason)
	await _run_true_metre_checks()

## Fetch one near-grid of raw source metres (the fetcher speaks m ASL).
func _fetch_raw(lat: float, lon: float, grid: int) -> bool:
	_done = false
	_ok = false
	_raw = PackedFloat32Array()
	var fetcher := DemFetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.succeeded.connect(func(heights: PackedFloat32Array, g: int) -> void:
		_ok = g == grid and heights.size() == grid * grid
		_raw = heights
		_reason = "grid %d" % g
		_done = true)
	fetcher.failed.connect(func(reason: String) -> void:
		_reason = reason
		_done = true)
	fetcher.fetch(lat, lon, grid)
	var waited := 0.0
	while not _done and waited < 20.0:
		await process_frame
		waited += 1.0 / 60.0
	return _ok

## Fetch one raw far-grid (zoom-8, whole tile) for the identity check.
func _fetch_far_raw(lat: float, lon: float, grid: int) -> bool:
	_done = false
	_ok = false
	_raw = PackedFloat32Array()
	var fetcher := DemFetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.succeeded.connect(func(heights: PackedFloat32Array, g: int) -> void:
		_ok = g == grid and heights.size() == grid * grid
		_raw = heights
		_reason = "far grid %d" % g
		_done = true)
	fetcher.failed.connect(func(reason: String) -> void:
		_reason = reason
		_done = true)
	fetcher.fetch_far(lat, lon, grid)
	var waited := 0.0
	while not _done and waited < 20.0:
		await process_frame
		waited += 1.0 / 60.0
	return _ok

## Scorecard check (a) on 9 sample points (centre + N/E/S/W at 1/3 and
## 2/3 of the grid radius): max/mean |converted − source| in both
## vertical modes. True-metre must pass the tier threshold; legacy is
## expected to fail — the comparison is the evidence true-metre wins.
func _scorecard_a(label: String, raw: PackedFloat32Array, grid: int,
		threshold_m: float) -> bool:
	var c := grid / 2
	var k1 := grid / 6
	var k2 := grid / 3
	var pts: Array[Vector2i] = [Vector2i(c, c),
		Vector2i(c - k1, c), Vector2i(c + k1, c),
		Vector2i(c, c - k1), Vector2i(c, c + k1),
		Vector2i(c - k2, c), Vector2i(c + k2, c),
		Vector2i(c, c - k2), Vector2i(c, c + k2)]
	var conv_true: Dictionary = GenerationPipeline.convert_dem_heights(raw, grid, false)
	var conv_old: Dictionary = GenerationPipeline.convert_dem_heights(raw, grid, true)
	var ht: PackedFloat32Array = conv_true["heights"]
	var ho: PackedFloat32Array = conv_old["heights"]
	var max_true := 0.0
	var sum_true := 0.0
	var max_old := 0.0
	var sum_old := 0.0
	for p in pts:
		var src := raw[p.y * grid + p.x]
		max_true = maxf(max_true, absf(ht[p.y * grid + p.x] - src))
		sum_true += absf(ht[p.y * grid + p.x] - src)
		max_old = maxf(max_old, absf(ho[p.y * grid + p.x] - src))
		sum_old += absf(ho[p.y * grid + p.x] - src)
	var mean_true := sum_true / float(pts.size())
	var mean_old := sum_old / float(pts.size())
	print("SCORECARD(a) %s true-metre: max %.2f m / mean %.2f m (bar ≤ %.1f m) → %s" % [
		label, max_true, mean_true, threshold_m,
		"PASS" if max_true <= threshold_m else "FAIL"])
	print("SCORECARD(a) %s legacy-squash: max %.2f m / mean %.2f m → %s (expected FAIL)" % [
		label, max_old, mean_old, "FAIL" if max_old > threshold_m else "PASS?!"])
	if max_true > threshold_m:
		printerr("DEM FAIL: true-metre (a) exceeds bar at ", label)
		return false
	if max_true >= max_old:
		printerr("DEM FAIL: true-metre (a) did not beat legacy at ", label)
		return false
	return true

func _run_true_metre_checks() -> void:
	# The A/B flag defaults OFF.
	var probe := GenerationPipeline.new()
	if probe.legacy_squash:
		printerr("DEM FAIL: legacy_squash must default OFF")
		quit(1)
		return
	probe.free()

	# Paris centre matches source-tile metres (flat: ≤3 m bar).
	if not await _fetch_raw(48.8566, 2.3522, 48):
		printerr("DEM FAIL: Paris raw fetch: ", _reason)
		quit(1)
		return
	var paris := _raw.duplicate()
	var conv_p: Dictionary = GenerationPipeline.convert_dem_heights(paris, 48, false)
	var hp: PackedFloat32Array = conv_p["heights"]
	print("DEM TRUE-METRE Paris: centre %.1f m ASL, relief %.1f m, water %.1f m ASL" % [
		conv_p["centre_elevation_m"], conv_p["relief_metres"], conv_p["water_level"]])
	if absf(hp[24 * 48 + 24] - paris[24 * 48 + 24]) > 0.01:
		printerr("DEM FAIL: Paris centre %.2f != source %.2f" % [hp[24 * 48 + 24], paris[24 * 48 + 24]])
		quit(1)
		return
	if not _scorecard_a("Paris", paris, 48, 3.0):
		quit(1)
		return

	# Interlaken relief matches source-tile metres (alpine: ≤8 m bar).
	if not await _fetch_raw(46.6863, 7.8632, 48):
		printerr("DEM FAIL: Interlaken raw fetch: ", _reason)
		quit(1)
		return
	var inter := _raw.duplicate()
	var conv_i: Dictionary = GenerationPipeline.convert_dem_heights(inter, 48, false)
	var hi: PackedFloat32Array = conv_i["heights"]
	var rmn := hi[0]
	var rmx := hi[0]
	for h in hi:
		rmn = minf(rmn, h)
		rmx = maxf(rmx, h)
	print("DEM TRUE-METRE Interlaken: centre %.1f m ASL, relief %.1f m, water %.1f m ASL" % [
		conv_i["centre_elevation_m"], conv_i["relief_metres"], conv_i["water_level"]])
	if absf((rmx - rmn) - float(conv_i["relief_metres"])) > 0.01:
		printerr("DEM FAIL: Interlaken converted relief != recorded relief")
		quit(1)
		return
	if not _scorecard_a("Interlaken", inter, 48, 8.0):
		quit(1)
		return

	# Wiring: a real _fetch_dem stores identity heights + the new fields.
	var pipe := GenerationPipeline.new()
	root.add_child(pipe)
	await process_frame
	var pdata := LocationData.new()
	pdata.latitude = 48.8566
	pdata.longitude = 2.3522
	pdata.place_name = "Paris, France"
	pdata.grid_size = 48
	pdata.far_grid_size = 16
	pdata.seed_value = 7
	pipe._far_fetcher.fetch_far(48.8566, 2.3522, 16)
	await pipe._fetch_dem(pdata)
	if not pipe.used_real_dem:
		printerr("DEM FAIL: pipeline wiring needs real DEM (offline with cold cache?)")
		quit(1)
		return
	if absf(pdata.heights[24 * 48 + 24] - pdata.centre_elevation_m) > 0.01:
		printerr("DEM FAIL: wired centre != centre_elevation_m")
		quit(1)
		return
	var wmn := pdata.heights[0]
	var wmx := pdata.heights[0]
	for h in pdata.heights:
		wmn = minf(wmn, h)
		wmx = maxf(wmx, h)
	if absf((wmx - wmn) - pdata.relief_metres) > 0.01:
		printerr("DEM FAIL: wired relief != relief_metres")
		quit(1)
		return
	# T7.0: the true z8 tile span (not the v1 9000-unit × 4 = 36 km).
	if absf(pdata.far_extent_m - FarTerrainBuilder.far_span_m(pdata)) > 0.01:
		printerr("DEM FAIL: far_extent_m should be the z8 span %f, got %f"
			% [FarTerrainBuilder.far_span_m(pdata), pdata.far_extent_m])
		quit(1)
		return
	print("DEM WIRING OK: identity heights + centre %.1f m + relief %.1f m + far_extent_m %.0f" % [
		pdata.centre_elevation_m, pdata.relief_metres, pdata.far_extent_m])

	# Far identity: pipeline far heights equal a fresh raw far fetch.
	if not await _fetch_far_raw(48.8566, 2.3522, 16):
		printerr("DEM FAIL: Paris raw far fetch: ", _reason)
		quit(1)
		return
	var far_raw := _raw.duplicate()
	if pdata.far_heights.size() != far_raw.size():
		printerr("DEM FAIL: far size %d != raw %d" % [pdata.far_heights.size(), far_raw.size()])
		quit(1)
		return
	var far_max := 0.0
	for i in far_raw.size():
		far_max = maxf(far_max, absf(pdata.far_heights[i] - far_raw[i]))
	print("DEM FAR TRUE-METRE: max |pipeline − source| %.3f m over %d posts" % [far_max, far_raw.size()])
	if far_max > 0.01:
		printerr("DEM FAIL: far heights are not source metres")
		quit(1)
		return

	# Legacy A/B mode: squashed centre at 3.0, water at −3.0, but the
	# recorded relief stays true metres.
	var old := GenerationPipeline.new()
	old.legacy_squash = true
	root.add_child(old)
	await process_frame
	var odata := LocationData.new()
	odata.latitude = 48.8566
	odata.longitude = 2.3522
	odata.place_name = "Paris, France"
	odata.grid_size = 48
	odata.far_grid_size = 16
	odata.seed_value = 7
	old._far_fetcher.fetch_far(48.8566, 2.3522, 16)
	await old._fetch_dem(odata)
	if not old.used_real_dem:
		printerr("DEM FAIL: legacy wiring needs real DEM")
		quit(1)
		return
	if absf(odata.heights[24 * 48 + 24] - 3.0) > 0.01:
		printerr("DEM FAIL: legacy centre should be 3.0, got %f" % odata.heights[24 * 48 + 24])
		quit(1)
		return
	if absf(odata.water_level + 3.0) > 0.01:
		printerr("DEM FAIL: legacy water should be −3.0, got %f" % odata.water_level)
		quit(1)
		return
	if absf(odata.relief_metres - pdata.relief_metres) > 0.01:
		printerr("DEM FAIL: legacy relief should still be true metres")
		quit(1)
		return
	print("DEM LEGACY OK: centre 3.0 / water −3.0, relief still %.1f m" % odata.relief_metres)
	print("DEM TRUE-METRE OK: Paris centre + Interlaken relief match source metres; (a) true-metre wins")
	await _run_mosaic_checks()

# --- T2.1: z14 mosaic + z12 mid + offline + stage times ---

## Timed near-mosaic fetch. Returns {ok, heights, dem_source, msec, reason}.
func _fetch_near_timed(lat: float, lon: float, grid: int, offline := false,
		budget := 60.0) -> Dictionary:
	var out := {"ok": false, "heights": PackedFloat32Array(), "dem_source": {},
		"msec": 0, "reason": "", "done": false}
	var fetcher := DemFetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.offline_mode = offline
	var start := Time.get_ticks_msec()
	fetcher.succeeded.connect(func(heights: PackedFloat32Array, g: int) -> void:
		out["ok"] = g == grid and heights.size() == grid * grid
		out["heights"] = heights
		out["dem_source"] = fetcher.dem_source
		out["msec"] = Time.get_ticks_msec() - start
		out["done"] = true)
	fetcher.failed.connect(func(reason: String) -> void:
		out["reason"] = reason
		out["msec"] = Time.get_ticks_msec() - start
		out["done"] = true)
	fetcher.fetch(lat, lon, grid)
	var waited := 0.0
	while not bool(out["done"]) and waited < budget:
		await process_frame
		waited += 1.0 / 60.0
	if not bool(out["done"]):
		out["reason"] = "timeout after %d s" % int(budget)
	fetcher.queue_free()
	return out

## Timed z12 mid fetch (the T1.3 source, for the A/B). Same shape as above.
func _fetch_mid_timed(lat: float, lon: float, grid: int) -> Dictionary:
	var out := {"ok": false, "heights": PackedFloat32Array(), "dem_source": {},
		"msec": 0, "reason": "", "done": false}
	var fetcher := DemFetcher.new()
	root.add_child(fetcher)
	await process_frame
	var start := Time.get_ticks_msec()
	fetcher.succeeded.connect(func(heights: PackedFloat32Array, g: int) -> void:
		out["ok"] = g == grid and heights.size() == grid * grid
		out["heights"] = heights
		out["dem_source"] = fetcher.dem_source
		out["msec"] = Time.get_ticks_msec() - start
		out["done"] = true)
	fetcher.failed.connect(func(reason: String) -> void:
		out["reason"] = reason
		out["msec"] = Time.get_ticks_msec() - start
		out["done"] = true)
	fetcher.fetch_mid(lat, lon, grid)
	var waited := 0.0
	while not bool(out["done"]) and waited < 30.0:
		await process_frame
		waited += 1.0 / 60.0
	if not bool(out["done"]):
		out["reason"] = "timeout after 30 s"
	fetcher.queue_free()
	return out

static func _terrarium(c: Color) -> float:
	return (c.r8 * 256.0 + c.g8 + c.b8 / 256.0) - 32768.0

static func _bilinear(img: Image, fx: float, fy: float) -> float:
	var w := img.get_width()
	var h := img.get_height()
	var cx := clampf(fx, 0.0, float(w - 1))
	var cy := clampf(fy, 0.0, float(h - 1))
	var x0 := int(cx)
	var y0 := int(cy)
	var x1 := mini(x0 + 1, w - 1)
	var y1 := mini(y0 + 1, h - 1)
	var tx := cx - float(x0)
	var ty := cy - float(y0)
	return lerpf(
		lerpf(_terrarium(img.get_pixel(x0, y0)), _terrarium(img.get_pixel(x1, y0)), tx),
		lerpf(_terrarium(img.get_pixel(x0, y1)), _terrarium(img.get_pixel(x1, y1)), tx), ty)

## Scorecard (a) posts: centre + N/E/S/W at 1/3 and 2/3 of grid radius.
static func _scorecard_posts(grid: int) -> Array[Vector2i]:
	var c := grid / 2
	var k1 := grid / 6
	var k2 := grid / 3
	return [Vector2i(c, c),
		Vector2i(c - k1, c), Vector2i(c + k1, c),
		Vector2i(c, c - k1), Vector2i(c, c + k1),
		Vector2i(c - k2, c), Vector2i(c + k2, c),
		Vector2i(c, c - k2), Vector2i(c, c + k2)]

static func _relief_of(h: PackedFloat32Array) -> Vector3:
	# x = min, y = max, z = relief.
	var mn := h[0]
	var mx := h[0]
	for v in h:
		mn = minf(mn, v)
		mx = maxf(mx, v)
	return Vector3(mn, mx, mx - mn)

static func _delete_cache(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

## Independent z14 reference: re-decode the cached tiles fresh from
## user://cache (never the fetcher's in-memory mosaic) with the test's
## own bilinear decode, at the same 9 posts over the same public window
## layout (576 z14 px centred on the viewpoint).
func _z14_reference(lat: float, lon: float, grid: int) -> Dictionary:
	var tiles := DemFetcher.mosaic_tiles(lat, lon, 14)
	var centre := DemFetcher.tile_xy(lat, lon, 14)
	var size := 256 * 3
	var mosaic := Image.create(size, size, false, Image.FORMAT_RGB8)
	for t in tiles:
		var path := "user://cache/dem_14_%d_%d.png" % [t.x, t.y]
		if not FileAccess.file_exists(path):
			return {"ok": false, "reason": "missing cache " + path}
		var img := Image.new()
		if img.load(path) != OK:
			return {"ok": false, "reason": "unreadable cache " + path}
		if img.get_format() != Image.FORMAT_RGB8:
			img.convert(Image.FORMAT_RGB8)
		var dst := Vector2i((t.x - (centre.x - 1)) * 256, (t.y - (centre.y - 1)) * 256)
		mosaic.blit_rect(img, Rect2i(0, 0, 256, 256), dst)
	var n := float(1 << 14)
	var gx := (lon + 180.0) / 360.0 * n
	var lat_rad := deg_to_rad(lat)
	var gy := (1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n
	var cx: float = (1.0 + gx - floor(gx)) * 256.0
	var cy: float = (1.0 + gy - floor(gy)) * 256.0
	var step := 576.0 / float(grid)
	var ref := PackedFloat32Array()
	for p in _scorecard_posts(grid):
		ref.append(_bilinear(mosaic,
			cx + (float(p.x) - float(grid) / 2.0) * step,
			cy + (float(p.y) - float(grid) / 2.0) * step))
	return {"ok": true, "ref": ref}

## Scorecard (a) T2.1: z14-mosaic heights and z12-mid heights (the T1.3
## source) against the independent z14 reference at the same 9 posts.
## The mosaic must pass the tier bar and beat-or-match the mid source.
func _scorecard_a_mosaic(label: String, new_h: PackedFloat32Array,
		mid_h: PackedFloat32Array, lat: float, lon: float, grid: int,
		threshold_m: float) -> bool:
	var r := _z14_reference(lat, lon, grid)
	if not bool(r["ok"]):
		printerr("DEM FAIL: z14 reference unavailable at ", label, ": ", r["reason"])
		return false
	var ref: PackedFloat32Array = r["ref"]
	var pts := _scorecard_posts(grid)
	var max_new := 0.0
	var sum_new := 0.0
	var max_mid := 0.0
	var sum_mid := 0.0
	for i in pts.size():
		var p := pts[i]
		max_new = maxf(max_new, absf(new_h[p.y * grid + p.x] - ref[i]))
		sum_new += absf(new_h[p.y * grid + p.x] - ref[i])
		max_mid = maxf(max_mid, absf(mid_h[p.y * grid + p.x] - ref[i]))
		sum_mid += absf(mid_h[p.y * grid + p.x] - ref[i])
	var mean_new := sum_new / float(pts.size())
	var mean_mid := sum_mid / float(pts.size())
	print("SCORECARD(a) %s z14-mosaic: max %.2f m / mean %.2f m (bar ≤ %.1f m) → %s" % [
		label, max_new, mean_new, threshold_m,
		"PASS" if max_new <= threshold_m else "FAIL"])
	print("SCORECARD(a) %s z12-mid (T1.3 source): max %.2f m / mean %.2f m" % [
		label, max_mid, mean_mid])
	if max_new > threshold_m:
		printerr("DEM FAIL: z14 mosaic (a) exceeds bar at ", label)
		return false
	if max_new > max_mid:
		printerr("DEM FAIL: z14 mosaic (a) did not beat z12 mid at ", label)
		return false
	return true

func _run_mosaic_checks() -> void:
	# 1. Mosaic geometry is pure and runs offline.
	var centre14 := DemFetcher.tile_xy(48.8566, 2.3522, 14)
	if centre14 != Vector2i(8299, 5636):
		printerr("DEM FAIL: unexpected Paris z14 tile ", centre14)
		quit(1)
		return
	var tiles := DemFetcher.mosaic_tiles(48.8566, 2.3522, 14)
	if tiles.size() != 9 or not tiles.has(centre14):
		printerr("DEM FAIL: Paris z14 mosaic is not 9 tiles around the centre")
		quit(1)
		return
	for t in tiles:
		if absi(t.x - centre14.x) > 1 or absi(t.y - centre14.y) > 1:
			printerr("DEM FAIL: mosaic tile outside the 3x3 neighbourhood: ", t)
			quit(1)
			return
	var mpp_paris := DemFetcher.metres_per_px(48.8566, 14)
	var mpp_eq := DemFetcher.metres_per_px(0.0, 14)
	print("DEM MOSAIC geometry OK: Paris z14 centre %s, 9 tiles, %.2f m/px Paris / %.2f m/px equator" % [
		str(centre14), mpp_paris, mpp_eq])
	if mpp_paris < 5.5 or mpp_paris > 7.5 or mpp_eq < 9.5 or mpp_eq > 9.6:
		printerr("DEM FAIL: metres_per_px out of range: Paris %.2f equator %.2f" % [mpp_paris, mpp_eq])
		quit(1)
		return

	# 2. Interlaken near mosaic (cold on first run — a §3.1 data point).
	var inter := await _fetch_near_timed(46.6863, 7.8632, 48)
	if not bool(inter["ok"]):
		printerr("DEM FAIL: Interlaken mosaic: ", inter["reason"])
		quit(1)
		return
	var ds: Dictionary = inter["dem_source"]
	if int(ds.get("zoom_near", 0)) != 14 or int(ds.get("zoom_mid", 0)) != 12 \
			or int(ds.get("zoom_far", 0)) != 8 or int(ds.get("span_near", 0)) != 3 \
			or int(ds.get("tile_count", 0)) != 9 or int(ds.get("source_zoom", 0)) != 14:
		printerr("DEM FAIL: Interlaken dem_source should be 9 z14 tiles, got ", ds)
		quit(1)
		return
	if absf(float(ds.get("metres_per_px", 0.0)) - DemFetcher.metres_per_px(46.6863, 14)) > 0.001:
		printerr("DEM FAIL: Interlaken dem_source metres_per_px wrong: ", ds)
		quit(1)
		return
	var ih: PackedFloat32Array = inter["heights"]
	var ir := _relief_of(ih)
	print("DEM MOSAIC Interlaken: 9 z14 tiles in %d ms, centre %.1f m ASL, relief %.1f m" % [
		int(inter["msec"]), ih[24 * 48 + 24], ir.z])
	if ir.z < 100.0:
		printerr("DEM FAIL: Interlaken mosaic relief %.1f m is not alpine" % ir.z)
		quit(1)
		return

	# 3. Interlaken z12 mid (the T1.3 source) + scorecard (a) A/B.
	var inter_mid := await _fetch_mid_timed(46.6863, 7.8632, 48)
	if not bool(inter_mid["ok"]):
		printerr("DEM FAIL: Interlaken mid: ", inter_mid["reason"])
		quit(1)
		return
	var dsm: Dictionary = inter_mid["dem_source"]
	if int(dsm.get("source_zoom", 0)) != 12 or int(dsm.get("tile_count", 0)) != 1:
		printerr("DEM FAIL: Interlaken mid dem_source should be 1 z12 tile, got ", dsm)
		quit(1)
		return
	var imh: PackedFloat32Array = inter_mid["heights"]
	var imr := _relief_of(imh)
	print("DEM MID Interlaken: z12 tile in %d ms, centre %.1f m ASL, relief %.1f m" % [
		int(inter_mid["msec"]), imh[24 * 48 + 24], imr.z])
	if not _scorecard_a_mosaic("Interlaken", ih, imh, 46.6863, 7.8632, 48, 8.0):
		quit(1)
		return

	# 4. Big Sur near mosaic (cold on first run) + z12 mid + (a) A/B.
	var big := await _fetch_near_timed(36.2704, -121.8081, 48)
	if not bool(big["ok"]):
		printerr("DEM FAIL: Big Sur mosaic: ", big["reason"])
		quit(1)
		return
	var dsb: Dictionary = big["dem_source"]
	if int(dsb.get("source_zoom", 0)) != 14 or int(dsb.get("tile_count", 0)) != 9:
		printerr("DEM FAIL: Big Sur dem_source should be 9 z14 tiles, got ", dsb)
		quit(1)
		return
	var bh: PackedFloat32Array = big["heights"]
	var br := _relief_of(bh)
	print("DEM MOSAIC Big Sur: 9 z14 tiles in %d ms, centre %.1f m ASL, relief %.1f m" % [
		int(big["msec"]), bh[24 * 48 + 24], br.z])
	if br.z < 50.0 or br.x < -50.0 or br.y > 2500.0:
		printerr("DEM FAIL: Big Sur mosaic range implausible: ", br)
		quit(1)
		return
	var big_mid := await _fetch_mid_timed(36.2704, -121.8081, 48)
	if not bool(big_mid["ok"]):
		printerr("DEM FAIL: Big Sur mid: ", big_mid["reason"])
		quit(1)
		return
	var bmh: PackedFloat32Array = big_mid["heights"]
	var bmr := _relief_of(bmh)
	print("DEM MID Big Sur: z12 tile in %d ms, centre %.1f m ASL, relief %.1f m" % [
		int(big_mid["msec"]), bmh[24 * 48 + 24], bmr.z])
	if not _scorecard_a_mosaic("Big Sur", bh, bmh, 36.2704, -121.8081, 48, 8.0):
		quit(1)
		return

	# 5. Offline revisit of cached Paris succeeds from cache, fast.
	var off_warm := await _fetch_near_timed(48.8566, 2.3522, 48, true, 10.0)
	if not bool(off_warm["ok"]):
		printerr("DEM FAIL: cached Paris offline revisit: ", off_warm["reason"])
		quit(1)
		return
	print("DEM OFFLINE OK: cached Paris mosaic from cache in %d ms (no network)" % int(off_warm["msec"]))

	# 6. Uncached spot offline fails fast (no hang) at fetcher level.
	var plat := 0.0
	var plon := -160.0
	for t in DemFetcher.mosaic_tiles(plat, plon, 14):
		_delete_cache("user://cache/dem_14_%d_%d.png" % [t.x, t.y])
	var m12 := DemFetcher.tile_xy(plat, plon, 12)
	_delete_cache("user://cache/dem_12_%d_%d.png" % [m12.x, m12.y])
	var off_cold := await _fetch_near_timed(plat, plon, 48, true, 10.0)
	if bool(off_cold["ok"]):
		printerr("DEM FAIL: uncached offline fetch should fail, not succeed")
		quit(1)
		return
	if str(off_cold["reason"]).contains("timeout"):
		printerr("DEM FAIL: offline fetch hung instead of failing fast")
		quit(1)
		return
	print("DEM OFFLINE OK: uncached mosaic failed fast in %d ms (%s)" % [
		int(off_cold["msec"]), off_cold["reason"]])

	# 7. Pipeline level: offline + uncached degrades to procedural DEM.
	var pipe := GenerationPipeline.new()
	root.add_child(pipe)
	await process_frame
	pipe._fetcher.offline_mode = true
	pipe._far_fetcher.offline_mode = true
	var m8 := DemFetcher.tile_xy(plat, plon, 8)
	_delete_cache("user://cache/dem_8_%d_%d.png" % [m8.x, m8.y])
	var pdata := LocationData.new()
	pdata.latitude = plat
	pdata.longitude = plon
	pdata.place_name = "Pacific Test Spot"
	pdata.grid_size = 48
	pdata.far_grid_size = 16
	pdata.seed_value = 7
	var pstart := Time.get_ticks_msec()
	pipe._far_fetcher.fetch_far(plat, plon, 16)
	await pipe._fetch_dem(pdata)
	var pmsec := Time.get_ticks_msec() - pstart
	if pipe.used_real_dem:
		printerr("DEM FAIL: offline pipeline should use procedural DEM")
		quit(1)
		return
	if not pdata.is_valid():
		printerr("DEM FAIL: procedural fallback grid invalid")
		quit(1)
		return
	if not bool(pdata.dem_source.get("procedural", false)):
		printerr("DEM FAIL: procedural dem_source marker missing: ", pdata.dem_source)
		quit(1)
		return
	if pmsec > 15000:
		printerr("DEM FAIL: offline pipeline fallback took %d ms (hung?)" % pmsec)
		quit(1)
		return
	print("DEM OFFLINE OK: pipeline procedural fallback valid (centre %.1f m, relief %.1f m) in %d ms" % [
		pdata.centre_elevation_m, pdata.relief_metres, pmsec])
	pipe.queue_free()

	# 8. Stage time per tier (cached Paris mosaic — network-free cost).
	var tier_budgets := ["≤20 s cold", "≤45 s cold", "≤75 s cold", "60–120 s cold"]
	for preset in [0, 1, 2, 3]:
		var g := RenderSettings.grid_size_for(preset)
		var tr := await _fetch_near_timed(48.8566, 2.3522, g)
		if not bool(tr["ok"]):
			printerr("DEM FAIL: tier %d (grid %d) cached fetch: " % [preset, g], tr["reason"])
			quit(1)
			return
		print("STAGE TIME %s (budget %s): Paris grid %d cached mosaic in %d ms" % [
			RenderSettings.preset_name(preset), tier_budgets[preset], g, int(tr["msec"])])
		if int(tr["msec"]) > 15000:
			printerr("DEM FAIL: cached tier fetch too slow")
			quit(1)
			return

	print("DEM MOSAIC OK: z14 near + z12 mid + z8 far, (a) improves vs T1.3 at Interlaken/Big Sur, offline degrades without hanging")
	quit(0)
