extends SceneTree

## Södermalm cliff (offline): godot --headless --script tests/stockholm_cliff_test.gd
## Stockholm takes Lantmäteriet's bare earth (GroundModel "lm", through
## Mapterhorn's Terrarium tiles), and the Mariaberget cliff survives the
## whole ground chain: the Monteliusvägen preset eye stands on the cliff
## top, 25 m+ over Riddarfjärden, not at the waterfront road the
## Terrarium surface model and the smoothing left there.
##
## The fixture is a lossless 128 × 128 crop of the real z13 Mapterhorn tile
## 13/4506/2409 (fetched 2026-11-19), its top-left pixel at global z13
## pixel (2307506, 1233613), ~4.9 m a pixel: Riddarfjärden, Söder
## Mälarstrand and the cliff up to Mariaberget.

const FIXTURE := "res://tests/fixtures/mariaberget_terrarium_z13.bin"
const FIXTURE_PX := Vector2i(2307506, 1233613)
const ZOOM := 13
const RIDDARFJARDEN := Vector2(59.3225, 18.0604)

var failures: Array[String] = []

func _init() -> void:
	_sources()
	_cliff()
	if failures.is_empty():
		print("STOCKHOLM CLIFF PASS")
		quit(0)
	else:
		for message in failures:
			printerr("STOCKHOLM CLIFF FAIL: ", message)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _sources() -> void:
	for row in [[59.3207, 18.0604, "lm", "Stockholm"], [57.7089, 11.9746, "lm", "Gothenburg"],
			[55.6050, 13.0038, "lm", "Malmö"], [56.0465, 12.6945, "lm", "Helsingborg"],
			[59.8586, 17.6389, "lm", "Uppsala"], [63.8258, 20.2630, "lm", "Umeå"],
			[67.8558, 20.2253, "lm", "Kiruna"], [57.6348, 18.2948, "lm", "Visby"],
			[55.6761, 12.5683, "", "Copenhagen"], [56.0361, 12.6136, "", "Helsingør"],
			[59.9139, 10.7522, "", "Oslo"], [68.4385, 17.4272, "", "Narvik"],
			[60.1699, 24.9384, "", "Helsinki"], [60.4518, 22.2666, "mml", "Turku"],
			[65.8481, 24.1466, "mml", "Tornio"]]:
		var got := GroundModel.source_for(row[0], row[1])
		_check(got == row[2], "%s is covered by '%s', expected '%s'" % [row[3], got, row[2]])
	_check(GroundModel.SOURCES.has("lm"), "Lantmäteriet has no credit line")
	var url := GroundModelFetcher.MAPTERHORN_URL
	_check(url.begins_with("https://") and not HostPolicy.is_blocked(url), "host policy refuses %s" % url)
	var win := GroundModelFetcher.window(59.3207, 18.0604)
	var tiles := GroundModelFetcher.tile_range(win, GroundModelFetcher.MAPTERHORN_ZOOM)
	_check(tiles.size.x >= 2 and tiles.size.x <= 3 and tiles.size.y >= 2 and tiles.size.y <= 3,
		"the Stockholm window asks for %s z13 tiles" % tiles.size)
	_check(tiles.has_point(Vector2i(4506, 2409)), "the window misses the tile under the eye: %s" % tiles)

## The fixture as a Mercator raster (the mosaic path with one tile).
func _raster() -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(FIXTURE)
	var heights := GroundModel.decode_terrarium(bytes, 128)
	if heights.is_empty():
		return {}
	var span := 2.0 * PI * GroundModel.MERC_R / float(1 << ZOOM) / 512.0
	var edge := PI * GroundModel.MERC_R
	return {"size": Vector2i(128, 128), "values": heights,
		"origin": Vector2(-edge + float(FIXTURE_PX.x) * span, edge - float(FIXTURE_PX.y) * span),
		"cell": Vector2(span, span)}

func _row() -> Dictionary:
	for r in PresetViews.ROWS:
		if str(r["id"]) == "stockholm":
			return r
	return {}

func _cliff() -> void:
	var raster := _raster()
	_check(not raster.is_empty(), "the Mariaberget fixture did not decode")
	if raster.is_empty():
		return
	var row := _row()
	var eye := Vector2(float(row.get("eye_lat", row["lat"])), float(row.get("eye_lon", row["lon"])))
	var em := GroundModel.merc(eye.x, eye.y)
	var wm := GroundModel.merc(RIDDARFJARDEN.x, RIDDARFJARDEN.y)
	var top := GroundModel.sample(raster, em.x, em.y)
	var water := GroundModel.sample(raster, wm.x, wm.y)
	_check(water > -0.5 and water < 2.0, "Riddarfjärden reads %.1f m in the fixture" % water)
	_check(top - water >= 30.0, "the raster puts the eye %.1f m over the water" % (top - water))
	# The whole chain: the grid resample, then GroundTruth's own surface.
	var data := LocationData.new()
	data.latitude = float(row["lat"])
	data.longitude = float(row["lon"])
	data.heights.resize(data.grid_size * data.grid_size)
	data.heights.fill(20.0)
	data.water_level = 4.0
	data.dem_source = {"source_zoom": 14, "ground_model": "lm"}
	data.ground_model = raster
	data.view = row
	data.landmark_type = "stockholm"
	_check(GroundModel.apply(data), "GroundModel.apply refused the Lantmäteriet raster")
	_check(not BareEarth.applies(data), "BareEarth would filter the bare-earth model")
	var ground := GroundTruth.new(data)
	var spawn := View360.spawn_xz(data)
	var w := WorldScale.xz_from_latlon(RIDDARFJARDEN.x, RIDDARFJARDEN.y, data.latitude, data.longitude)
	var g_eye := ground.asl_y(ground.height_at_world(spawn.x, spawn.y))
	var g_water := ground.asl_y(ground.height_at_world(w.x, w.y))
	_check(g_water < 2.5, "the ground at Riddarfjärden stands %.1f m ASL" % g_water)
	_check(g_eye - g_water >= 25.0, "the preset eye's ground is only %.1f m over the water (%.1f m ASL)"
		% [g_eye - g_water, g_eye])
	# The eye stands eye_m over that cliff top; asl_m stays a floor at or
	# below it, so it only acts when the bare-earth model is unavailable.
	var y := ground.asl_y(View360.eye_y(data, ground, spawn))
	_check(absf(y - (g_eye + float(row["eye_m"]))) < 0.5,
		"the eye is %.1f m ASL over %.1f m ground: the asl_m floor took over" % [y, g_eye])
	_check(float(row.get("asl_m", 0.0)) >= g_eye - 2.0,
		"asl_m %.0f no longer holds the Terrarium fallback near the cliff top" % float(row.get("asl_m", 0.0)))
	print("cliff: eye ground %.1f m, water %.1f m, eye %.1f m ASL" % [g_eye, g_water, y])
