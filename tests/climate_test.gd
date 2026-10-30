extends SceneTree

## CHELSA climate layer (ClimateFetcher + ClimateModel):
## godot --headless --script tests/climate_test.gd
## Offline: the GeoTIFF strip decoder on a synthetic strip, the grid
## cell maths, and the model on CHELSA values measured 2026-10-30 at
## the golden locations. CLIMATE_LIVE=1 also reads Paris from the
## CHELSA object store and checks it against those values.

## [name, lat, lon, centre elevation m, t_warm, t_cold, precip, precip_warm, snow_days]
const PLACES := [
	["Paris", 48.8566, 2.3522, 41.6, 18.55, 4.35, 658.8, 165.4, 0.0],
	["Interlaken", 46.6863, 7.8632, 568.0, 18.05, 1.05, 1343.8, 469.2, 0.0],
	["Banff", 51.1789, -115.5708, 1401.0, 13.3, -9.5, 523.0, 207.0, 200.0],
	["Big Sur", 36.2704, -121.8081, 39.8, 15.15, 10.25, 1094.5, 13.7, 0.0],
	["Turku", 60.4518, 22.2666, 26.9, 15.7, -3.8, 750.0, 234.0, 160.0],
	["Cairo", 30.04, 31.24, 23.0, 28.5, 14.5, 19.0, 0.0, 0.0],
]

func _init() -> void:
	_run()

func _data(p: Array) -> LocationData:
	var d := LocationData.new()
	d.latitude = p[1]
	d.longitude = p[2]
	d.centre_elevation_m = p[3]
	d.climate = {"t_warm_c": p[4], "t_cold_c": p[5], "precip_mm": p[6],
		"precip_warm_mm": p[7], "snow_days": p[8]}
	return d

func _run() -> void:
	var failures: Array[String] = []
	_decoder_checks(failures)
	_model_checks(failures)
	if OS.get_environment("CLIMATE_LIVE") == "1":
		await _live_checks(failures)
	if failures.is_empty():
		print("CLIMATE OK: strip decoder + predictor, grid cells, snow lines / treeline / biomes / dryness on 6 places, latitude fallback%s"
			% (", live CHELSA Paris" if OS.get_environment("CLIMATE_LIVE") == "1" else ""))
		quit(0)
	else:
		for f in failures:
			printerr("CLIMATE FAIL: ", f)
		quit(1)

func _decoder_checks(failures: Array[String]) -> void:
	# A full-width row with a horizontal predictor: write deltas, deflate,
	# decode three samples from the middle.
	var want := PackedInt32Array()
	want.resize(ClimateFetcher.WIDTH)
	for i in ClimateFetcher.WIDTH:
		want[i] = 2700 + (i % 37) * 3
	var raw := PackedByteArray()
	raw.resize(ClimateFetcher.WIDTH * 2)
	var prev := 0
	for i in ClimateFetcher.WIDTH:
		raw.encode_u16(i * 2, (want[i] - prev) & 0xffff)
		prev = want[i]
	var strip := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var got := ClimateFetcher.decode_row(strip, 21881, 3, 2)
	if got != [want[21881], want[21882], want[21883]]:
		failures.append("predictor row decode: got %s" % str(got))
	if not ClimateFetcher.decode_row(PackedByteArray([1, 2, 3]), 0, 3, 2).is_empty():
		failures.append("a corrupt strip must decode to nothing, not garbage")
	# Header guard: anything but the CHELSA layout is rejected.
	if not ClimateFetcher.parse_ifd(PackedByteArray([0x4D, 0x4D, 0, 42])).is_empty():
		failures.append("big-endian / short headers must be rejected")
	var cell := ClimateFetcher.cell_of(48.8566, 2.3522)
	if cell != Vector2i(21882, 4217):
		failures.append("Paris cell should be (21882, 4217) like GDAL, got %s" % cell)

func _model_checks(failures: Array[String]) -> void:
	var by := {}
	for p in PLACES:
		by[p[0]] = _data(p)
	var il: LocationData = by["Interlaken"]
	var sl_w := ClimateModel.snowline_m(il, LocationData.Season.WINTER)
	var sl_sp := ClimateModel.snowline_m(il, LocationData.Season.SPRING)
	var sl_s := ClimateModel.snowline_m(il, LocationData.Season.SUMMER)
	var tl := ClimateModel.treeline_m(il)
	# Real Bernese Oberland: winter snow ~0.9–1.2 km, April ~1.6–2.0 km,
	# firn line ~2.8–3.1 km, treeline ~1.9–2.3 km.
	if not (sl_w > 850.0 and sl_w < 1200.0 and sl_sp > 1600.0 and sl_sp < 2100.0
			and sl_s > 2800.0 and sl_s < 3150.0 and tl > 1900.0 and tl < 2300.0):
		failures.append("Interlaken lines winter %.0f / spring %.0f / summer %.0f / treeline %.0f" % [sl_w, sl_sp, sl_s, tl])
	if ClimateModel.snowy_at_viewpoint(il, LocationData.Season.WINTER):
		failures.append("Interlaken's valley floor (568 m) sits below its winter snow line")
	if ClimateModel.snowy_at_viewpoint(by["Paris"], LocationData.Season.WINTER):
		failures.append("Paris must not be snowy in winter")
	for snowy in ["Banff", "Turku"]:
		if not ClimateModel.snowy_at_viewpoint(by[snowy], LocationData.Season.WINTER):
			failures.append("%s should lie under winter snow" % snowy)
	var bt := ClimateModel.treeline_m(by["Banff"])
	if bt < 2100.0 or bt > 2450.0:
		failures.append("Banff treeline %.0f (real ~2200–2300 m)" % bt)
	var expect := {"Paris": "temperate", "Interlaken": "alpine", "Banff": "boreal",
		"Big Sur": "dry_coast", "Turku": "boreal", "Cairo": "arid"}
	for k in expect:
		var b := TreeSpecies.biome_for_data(by[k])
		if b != expect[k]:
			failures.append("%s biome %s, want %s" % [k, b, expect[k]])
	if not ClimateModel.summer_dry(by["Big Sur"]) or ClimateModel.summer_dry(by["Paris"]):
		failures.append("Big Sur summers are dry, Paris summers are not")
	if ClimateModel.grass_tint(by["Big Sur"], LocationData.Season.SUMMER).a <= 0.0 \
			or ClimateModel.grass_tint(by["Paris"], LocationData.Season.SUMMER).a > 0.0:
		failures.append("golden summer grass only where summers are dry")
	if ClimateModel.snow_uniforms(il)["snow_on"] != 0.0:
		failures.append("summer keeps the imagery's own snow (snow_on 0)")
	il.season = LocationData.Season.WINTER
	var u := ClimateModel.snow_uniforms(il)
	if u["snow_on"] != 1.0 or absf(float(u["snow_y"]) - (sl_w - 568.0)) > 0.01:
		failures.append("winter snow uniforms: %s" % u)
	# Without climate data the latitude rules stay in charge.
	var bare := LocationData.new()
	bare.latitude = 46.6863
	if ClimateModel.snowline_m(bare, LocationData.Season.WINTER) != FarSurface.snowline_m(46.6863, LocationData.Season.WINTER) \
			or ClimateModel.biome(bare) != "":
		failures.append("no climate → latitude snow line and regional biome")

func _live_checks(failures: Array[String]) -> void:
	var f := ClimateFetcher.new()
	root.add_child(f)
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ClimateFetcher.cache_path(48.8566, 2.3522)))
	f.fetch(48.8566, 2.3522)
	var c: Dictionary = await f.finished
	if c.is_empty() or absf(float(c.get("t_warm_c", 0.0)) - 18.55) > 0.5 \
			or absf(float(c.get("precip_mm", 0.0)) - 658.8) > 20.0:
		failures.append("live CHELSA Paris: %s %s" % [c, f.timings])
	f.queue_free()
