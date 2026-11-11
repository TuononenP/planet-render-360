extends SceneTree

## Viewer tools: godot --headless --script tests/viewer_tools_test.gd
## View links and the camera kept per place, thumbnails, photo naming and
## stamp text, the time-lapse, the date picker's calendar, the horizon
## labels' data and line of sight, the mini-map's tile maths, tap-to-walk,
## and the real View360 wiring (restore, HUD buttons, keys). Offline: the
## view's weather and horizon fetchers never reach the network, and every
## cache lives in a temp directory.

const CACHE := "user://viewer_tools_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	CacheStore.dir_override = CACHE
	PlaceThumb.dir_override = CACHE + "/thumbs"
	DirAccess.make_dir_recursive_absolute(CACHE)
	_view_link()
	_seasons()
	_store_camera()
	_thumbs()
	_photo_names()
	_time_lapse()
	_calendar()
	_horizon_data()
	_line_of_sight()
	_minimap_maths()
	_walk_maths()
	await _search_link()
	await _view_wiring()
	_clean(CACHE)
	CacheStore.dir_override = ""
	PlaceThumb.dir_override = ""
	if failures.is_empty():
		print("VIEWER TOOLS OK: links, camera per place, thumbnails, photo, time-lapse, calendar, horizon labels, mini-map, walking, HUD wiring")
		quit(0)
	else:
		for f in failures:
			printerr("VIEWER TOOLS FAIL: ", f)
		quit(1)

static func _clean(dir_path: String) -> void:
	for f in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_clean(dir_path.path_join(d))
	DirAccess.remove_absolute(dir_path)

# --- View links ---

func _view_link() -> void:
	var state := {"lat": 48.8622, "lon": 2.2887, "eye_lat": 48.8625, "eye_lon": 2.2891,
		"eye_m": 6.0, "bearing": 142.0, "pitch": 4.0, "zoom": 1.5, "minutes": 1050.0,
		"season": 2, "date": {"year": 2026, "month": 6, "day": 21}}
	var link := ViewLink.encode(state)
	_check(link.begins_with("pr360://view?lat=48.86220&lon=2.28870"), "link starts with the scheme and origin: " + link)
	_check(ViewLink.looks_like_link("  " + link + "\n"), "a pasted link with spaces is recognised")
	var back := ViewLink.parse(link)
	_check(not back.is_empty(), "the link parses")
	for key in ["lat", "lon", "eye_lat", "eye_lon", "eye_m", "bearing", "pitch"]:
		_check(absf(float(back.get(key, 1e9)) - float(state[key])) < 0.001, "round trip %s: %s" % [key, back.get(key)])
	_check(absf(float(back["zoom"]) - 1.5) < 0.01 and int(back["minutes"]) == 1050 and int(back["season"]) == 2,
		"zoom, minutes and season survive")
	_check(back["date"] == {"year": 2026, "month": 6, "day": 21}, "the picked date survives: %s" % [back.get("date")])
	var bare := ViewLink.parse(ViewLink.encode({"lat": 10.0, "lon": 20.0, "eye_m": 30.0, "bearing": 0.0, "pitch": 0.0}))
	_check(not bare.has("eye_lat") and not bare.has("zoom") and not bare.has("date"), "optional fields stay out when unset")
	_check(ViewLink.parse("https://example.com").is_empty(), "other text is not a link")
	_check(ViewLink.parse("pr360://view?lon=2").is_empty(), "no latitude, no view")
	_check(ViewLink.parse("pr360://view?lat=95&lon=2").is_empty(), "latitude out of range")
	_check(ViewLink.parse("pr360://view?lat=x&lon=2").is_empty(), "a non-number is refused")
	var odd := ViewLink.parse("pr360://view?lat=1&lon=2&h=9999&p=200&z=9&d=2026-02-30")
	_check(float(odd["eye_m"]) <= 400.0 and float(odd["pitch"]) <= 68.0 and float(odd["zoom"]) <= 2.8,
		"wild numbers are clamped")
	_check(not odd.has("date"), "February 30th is not a date")
	_check(ViewLink.parse_date("2024-02-29") == {"year": 2024, "month": 2, "day": 29}, "leap day")
	_check(ViewLink.parse_date("2026-02-29").is_empty(), "no leap day in 2026")
	var view := ViewLink.to_view(back)
	_check(bool(view["restore"]) and not bool(view["clear"]) and float(view["eye_m"]) == 6.0,
		"to_view restores exactly, without the clearance lift")
	_check(PresetViews.eye_xz(view, 48.8622, 2.2887).length() > 1.0, "the eye offset resolves through PresetViews")
	var far := ViewLink.parse("pr360://view?lat=48.86&lon=2.29&el=10&eo=100&h=6&b=0&p=0")
	_check(not far.is_empty() and not far.has("eye_lat") and not far.has("eye_lon"),
		"an eye thousands of km from the origin is dropped: the view opens at its origin: %s" % [far])
	var edge := WorldScale.latlon_from_xz(0.0, -1300.0, 48.86, 2.29)
	_check(not ViewLink.parse("pr360://view?lat=48.86&lon=2.29&el=%.5f&eo=%.5f" % [edge.x, edge.y]).has("eye_lat"),
		"an eye just past the built ground is dropped too")
	var inside := WorldScale.latlon_from_xz(300.0, -900.0, 48.86, 2.29)
	_check(ViewLink.parse("pr360://view?lat=48.86&lon=2.29&el=%.5f&eo=%.5f" % [inside.x, inside.y]).has("eye_lat"),
		"an eye on the built ground is kept")
	_check(not ViewLink.to_view({"lat": 48.86, "lon": 2.29, "eye_lat": 10.0, "eye_lon": 100.0}).has("eye_lat"),
		"to_view drops a far eye as well")
	for row in PresetViews.ROWS:
		if row.has("eye_lat"):
			_check(ViewLink.to_view(row).has("eye_lat"), "%s: a curated eye is within reach" % row["id"])

func _seasons() -> void:
	var d := func(m: int) -> Dictionary: return {"year": 2026, "month": m, "day": 15}
	_check(ViewLink.season_for_date(d.call(1), 50.0) == LocationData.Season.WINTER, "January is winter in the north")
	_check(ViewLink.season_for_date(d.call(4), 50.0) == LocationData.Season.SPRING, "April is spring in the north")
	_check(ViewLink.season_for_date(d.call(7), 50.0) == LocationData.Season.SUMMER, "July is summer in the north")
	_check(ViewLink.season_for_date(d.call(10), 50.0) == LocationData.Season.AUTUMN, "October is autumn in the north")
	_check(ViewLink.season_for_date(d.call(12), 50.0) == LocationData.Season.WINTER, "December is winter in the north")
	_check(ViewLink.season_for_date(d.call(1), -33.0) == LocationData.Season.SUMMER, "January is summer in the south")
	_check(ViewLink.season_for_date(d.call(7), -33.0) == LocationData.Season.WINTER, "July is winter in the south")
	_check(ViewLink.season_for_date(d.call(10), -33.0) == LocationData.Season.SPRING, "October is spring in the south")
	_check(ViewLink.days_in_month(2100, 2) == 28 and ViewLink.days_in_month(2000, 2) == 29, "century leap rules")

# --- Camera per place (History) ---

func _store_camera() -> void:
	var store := CacheStore.new()
	store.add_entry("Paris, France", 48.8622, 2.2887)
	_check(store.camera_for(48.8622, 2.2887).is_empty(), "a new entry has no camera")
	var cam := {"lat": 48.8622, "lon": 2.2887, "eye_m": 31.0, "bearing": 200.0, "pitch": -3.0, "zoom": 1.2}
	store.set_camera(48.8622, 2.2887, cam)
	_check(float(store.camera_for(48.8622, 2.2887)["bearing"]) == 200.0, "the camera is kept on its entry")
	_check(store.camera_for(10.0, 10.0).is_empty(), "another place has none")
	store.add_entry("Paris, France", 48.8622, 2.2887)
	_check(float(store.camera_for(48.8622, 2.2887).get("bearing", -1.0)) == 200.0,
		"visiting again keeps the saved camera")
	var reloaded := CacheStore.new()
	reloaded.load_store()
	_check(float(reloaded.camera_for(48.8622, 2.2887).get("pitch", 99.0)) == -3.0, "the camera survives a reload")
	_check(reloaded.entries.size() == 1, "one entry per place")
	store.clear()

# --- Thumbnails ---

func _thumbs() -> void:
	var wide := Image.create(1600, 600, false, Image.FORMAT_RGBA8)
	wide.fill(Color(0.2, 0.5, 0.8))
	var black := Image.create(800, 500, false, Image.FORMAT_RGBA8)
	black.fill(Color.BLACK)
	_check(PlaceThumb.shrink(black) == null and not PlaceThumb.save(black, 5.0, 6.0),
		"a black frame (read back right after a resize) is never saved")
	var night := Image.create(800, 500, false, Image.FORMAT_RGBA8)
	night.fill(Color(0.01, 0.012, 0.02))
	night.fill_rect(Rect2i(0, 300, 800, 40), Color(0.12, 0.1, 0.2))  # the horizon glow
	_check(PlaceThumb.shrink(night) != null, "a dark night scene with its sky glow is a picture")
	var s := PlaceThumb.shrink(wide)
	_check(s != null and s.get_width() == PlaceThumb.WIDTH and s.get_height() == PlaceThumb.HEIGHT,
		"a wide capture is cropped and shrunk to card size")
	var tall := Image.create(300, 900, false, Image.FORMAT_RGB8)
	tall.fill(Color(0.6, 0.7, 0.5))
	var t := PlaceThumb.shrink(tall)
	_check(t != null and t.get_width() == PlaceThumb.WIDTH and t.get_height() == PlaceThumb.HEIGHT, "a tall one too")
	_check(PlaceThumb.shrink(null) == null and PlaceThumb.shrink(Image.new()) == null, "nothing to shrink, nothing saved")
	_check(not PlaceThumb.save(null, 1.0, 2.0) and not PlaceThumb.exists(1.0, 2.0), "a null picture saves nothing")
	_check(PlaceThumb.save(wide, 48.8622, 2.2887) and PlaceThumb.exists(48.8622, 2.2887), "a picture is saved per place")
	var tex := PlaceThumb.load_texture(48.8622, 2.2887)
	_check(tex != null and tex.get_width() == PlaceThumb.WIDTH, "and loads back at card size")
	_check(PlaceThumb.load_texture(0.5, 0.5) == null, "a place without one has none")
	_check(PlaceThumb.path(48.8622, 2.2887) == PlaceThumb.path(48.86224, 2.28871), "the key is the quantised place")
	PlaceThumb.remove(48.8622, 2.2887)
	_check(not PlaceThumb.exists(48.8622, 2.2887), "removed with its place")
	var poly := RoundedPhoto.outline(100.0, 60.0, 10.0, false)
	_check(poly.size() == 4 * (RoundedPhoto.SEGMENTS + 1), "four rounded corners: %d points" % poly.size())
	var top := RoundedPhoto.outline(100.0, 60.0, 10.0, true)
	_check(top.has(Vector2(100.0, 60.0)) and top.has(Vector2(0.0, 60.0)), "top-only keeps the bottom corners square")
	var uvs := RoundedPhoto.cover_uvs(PackedVector2Array([Vector2(0, 0), Vector2(100, 50)]), 100.0, 50.0, 400.0, 100.0)
	_check(absf(uvs[0].x - 0.25) < 0.001 and absf(uvs[1].x - 0.75) < 0.001 and absf(uvs[0].y) < 0.001 and absf(uvs[1].y - 1.0) < 0.001,
		"a wide photo in a card crops its sides: %s" % [uvs])
	# A store entry's removal drops its picture.
	var store := CacheStore.new()
	store.add_entry("Thumbed", 12.0, 34.0)
	PlaceThumb.save(wide, 12.0, 34.0)
	store.remove_place(store.entries[0])
	_check(not PlaceThumb.exists(12.0, 34.0), "remove_place deletes the picture")

# --- Photo ---

func _photo_names() -> void:
	_check(PhotoMode.slug("Paris, France") == "paris-france", "slug: " + PhotoMode.slug("Paris, France"))
	_check(PhotoMode.slug("  --Big   Sur!! ") == "big-sur", "slug trims and joins: " + PhotoMode.slug("  --Big   Sur!! "))
	_check(PhotoMode.slug("!!!") == "", "nothing left of punctuation")
	_check(PhotoMode.file_name("Rome, Italy", {"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 5})
		== "planet-render-360_rome-italy_20261101-1705.png", "file name: " + PhotoMode.file_name("Rome, Italy", {"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 5}))
	_check(PhotoMode.file_name("", {}).contains("_view_"), "an unnamed place still gets a name")
	var lines := PhotoMode.stamp_lines("Venice, Italy", 45.4318, 12.329, "17:30", "21 Jun 2026", "© OpenStreetMap contributors")
	_check(lines.size() == 3 and lines[0] == "Venice, Italy", "three stamp lines")
	_check(lines[1].contains("45.4318° N") and lines[1].contains("17:30, 21 Jun 2026"), "coordinates, time and date: " + lines[1])
	_check(PhotoMode.stamp_lines("X", 0.0, 0.0, "09:00", "", "").size() == 2, "no credit, no third line")
	_check(PhotoMode.stamp_lines("X", 0.0, 0.0, "09:00", "", "")[1].ends_with("09:00"), "no date, just the time")
	_check(PhotoMode.stamp_unit(1080) > PhotoMode.stamp_unit(480) and PhotoMode.stamp_unit(100) == 14.0,
		"the stamp scales with the picture")

# --- Time-lapse ---

func _time_lapse() -> void:
	var m := TimeLapse.advance(360.0, 1.0, 360.0, 1080.0, 1)
	_check(absf(m - (360.0 + 720.0 / TimeLapse.DAY_S)) < 0.001, "one second moves a twentieth of the daylight: %s" % m)
	_check(absf(TimeLapse.advance(360.0, 1.0, 360.0, 1080.0, 4) - 360.0 - 4.0 * 720.0 / TimeLapse.DAY_S) < 0.001, "4x is four times as fast")
	var wrapped := TimeLapse.advance(1070.0, 1.0, 360.0, 1080.0, 1)
	_check(wrapped >= 360.0 and wrapped < 400.0, "past sunset it loops to sunrise: %s" % wrapped)
	_check(TimeLapse.advance(100.0, 0.0, 360.0, 1080.0, 1) == 360.0, "from the night it starts at sunrise")
	_check(TimeLapse.window(720.0, 720.0) == Vector2(0, 1440), "polar night plays the whole day")
	_check(TimeLapse.window(0.0, 1440.0) == Vector2(0, 1440), "polar day plays the whole day")
	var full := 0.0
	for i in 20:
		full = TimeLapse.advance(full, 1.0, 720.0, 720.0, 1)
	_check(absf(full - 1440.0 * 0.0) < 1440.0, "stays inside the day")
	var lapse := TimeLapse.new()
	_check(lapse.tick(1.0, false) < 0.0, "paused: nothing to apply")
	lapse.play()
	_check(lapse.tick(0.01, false) < 0.0, "between applied frames: nothing yet")
	var dt := lapse.tick(0.05, false)
	_check(absf(dt - 0.06) < 0.0001, "an applied frame carries the time since the last: %s" % dt)
	_check(TimeLapse.advance(600.0, dt, 360.0, 1080.0, lapse.speed()) > 600.0, "and moves the clock")
	lapse.stop()
	lapse.play()
	_check(lapse.tick(0.5, true) < 0.0, "reduced motion waits for its step")
	var step := TimeLapse.advance(600.0, lapse.tick(0.6, true), 360.0, 1080.0, lapse.speed())
	_check(step - 600.0 > 20.0, "reduced motion jumps a coarse step: %s" % step)
	_check(lapse.speed() == 1 and lapse.cycle_speed() == 2 and lapse.cycle_speed() == 4 and lapse.cycle_speed() == 1,
		"speeds cycle 1x, 2x, 4x")

# --- Calendar ---

func _calendar() -> void:
	_check(DatePicker.first_column(2026, 6) == 0, "1 June 2026 is a Monday")
	_check(DatePicker.first_column(2026, 11) == 6, "1 November 2026 is a Sunday")
	var cells := DatePicker.cells(2024, 2)
	_check(cells.size() == DatePicker.first_column(2024, 2) + 29, "February 2024 has 29 days")
	_check(cells[cells.size() - 1] == 29 and cells[DatePicker.first_column(2024, 2)] == 1,
		"cells run 1 .. days after the blanks (0)")
	var picker := DatePicker.new()
	root.add_child(picker)
	var got: Array = []
	picker.date_picked.connect(func(d: Dictionary) -> void: got.append(d))
	picker.open_for({}, {"year": 2026, "month": 11, "day": 1})
	_check(picker.visible and picker.shown_month() == Vector2i(2026, 11), "opens on today's month")
	picker._step_month(1)
	_check(picker.shown_month() == Vector2i(2026, 12), "next month")
	picker._step_month(1)
	_check(picker.shown_month() == Vector2i(2027, 1), "December rolls into January")
	picker._step_year(-2)
	_check(picker.shown_month() == Vector2i(2025, 1), "year stepper")
	picker._quick("jun")
	_check(got.size() == 1 and got[0] == {"year": 2025, "month": 6, "day": 21} and not picker.visible,
		"the June solstice quick pick picks 21 June of the shown year and closes: %s" % [got])
	picker.open_for({"year": 2026, "month": 3, "day": 9}, {"year": 2026, "month": 11, "day": 1})
	_check(picker.shown_month() == Vector2i(2026, 3), "reopens on the picked date's month")
	picker.free()

# --- Horizon labels ---

func _horizon_data() -> void:
	var text := JSON.stringify({"elements": [
		{"type": "node", "lat": 46.55, "lon": 8.0, "tags": {"natural": "peak", "name": "Finsteraarhorn", "ele": "4274"}},
		{"type": "node", "lat": 46.55, "lon": 8.0, "tags": {"natural": "peak", "name": "Finsteraarhorn", "ele": "4274"}},
		{"type": "node", "lat": 46.7, "lon": 7.9, "tags": {"place": "town", "name": "Interlaken"}},
		{"type": "node", "lat": 46.6, "lon": 7.7, "tags": {"place": "hamlet", "name": "Skipped"}},
		{"type": "node", "lat": 46.6, "lon": 7.7, "tags": {"natural": "peak"}},
		{"type": "way", "center": {"lat": 46.69, "lon": 7.85}, "tags": {"natural": "water", "water": "lake", "name": "Thunersee"}},
		{"type": "way", "tags": {"natural": "water", "water": "lake", "name": "No centre"}},
		{"type": "node", "lat": 46.7, "lon": 7.9, "tags": {"place": "city", "name": "Bern"}}]})
	var sites := HorizonFetcher.parse(text)
	var names := sites.map(func(s: Dictionary) -> String: return "%s:%s" % [s["kind"], s["name"]])
	_check(names == ["Peak:Finsteraarhorn", "Town:Interlaken", "Lake:Thunersee", "City:Bern"],
		"peaks, towns and lakes in, duplicates, unnamed and hamlets out: %s" % [names])
	_check(float(sites[0]["ele_m"]) == 4274.0 and float(sites[1]["ele_m"]) < 0.0, "ele read, unknown is -1")
	_check(HorizonFetcher.parse_ele("3 967") == 3967.0 and HorizonFetcher.parse_ele("1,200.5 m") == 1200.5
		and HorizonFetcher.parse_ele("4000;4010") == 4000.0 and HorizonFetcher.parse_ele("high") < 0.0, "elevation formats")
	_check(HorizonFetcher.parse("not json").is_empty() and HorizonFetcher.parse("").is_empty(), "garbage gives no sites")
	_check(HorizonFetcher.build_query(46.0, 7.0).contains('"natural"="peak"') and HorizonFetcher.build_query(46.0, 7.0).contains("out tags center"),
		"the query asks for peaks and a centre for lakes")
	_check(HorizonFetcher.cache_path(46.0, 7.0).contains("osm_v2_") and HorizonFetcher.cache_path(46.0, 7.0).ends_with(".json"),
		"cached in the osm layer")
	var peak := {"kind": "Peak", "ele_m": 4000.0}
	var town := {"kind": "Town", "ele_m": -1.0}
	_check(HorizonLabels.prominence(peak, 20000.0, 8.0) > HorizonLabels.prominence(town, 3000.0, 0.0), "a high peak outranks a town")
	_check(HorizonLabels.prominence(peak, 20000.0, 8.0) > HorizonLabels.prominence(peak, 20000.0, 2.0), "a peak standing higher in view outranks a lower one")
	_check(HorizonLabels.prominence({"kind": "City", "ele_m": -1.0}, 5000.0, 0.0) > HorizonLabels.prominence({"kind": "Village", "ele_m": -1.0}, 5000.0, 0.0),
		"a city outranks a village")
	_check(HorizonLabels.data_line(peak, 41000.0) == "4,000 m · 41 km", "peak data line: " + HorizonLabels.data_line(peak, 41000.0))
	_check(HorizonLabels.data_line(town, 2400.0) == "2.4 km", "place data line: " + HorizonLabels.data_line(town, 2400.0))
	UiTheme.units_imperial = true
	_check(HorizonLabels.data_line(peak, 41000.0).begins_with("13,123 ft"), "imperial elevation: " + HorizonLabels.data_line(peak, 41000.0))
	UiTheme.units_imperial = false

func _line_of_sight() -> void:
	var flat := func(_x: float, _z: float) -> float: return 0.0
	var origin := Vector3(0, 30, 0)
	_check(HorizonLabels.line_of_sight(origin, Vector3(0, 500, -20000), flat), "open ground: the peak is in view")
	# A 400 m ridge 3 km north hides a 300 m summit 20 km away, not a 4000 m one.
	var ridge := func(_x: float, z: float) -> float: return 400.0 if absf(z + 3000.0) < 600.0 else 0.0
	_check(not HorizonLabels.line_of_sight(origin, Vector3(0, 300, -20000), ridge), "a ridge hides a low summit behind it")
	_check(HorizonLabels.line_of_sight(origin, Vector3(0, 4000, -20000), ridge), "a tall summit shows over it")
	_check(not HorizonLabels.line_of_sight(origin, Vector3(0, 100, -20000), func(_x: float, z: float) -> float:
		return 200.0 if z < -10.0 else 0.0), "a rise right in front hides everything behind it")

# --- Mini-map ---

func _minimap_maths() -> void:
	_check(absf(MiniMap.metres_per_pixel(0.0, 14) - 9.5546) < 0.01, "equator metres per pixel at z14: %s" % MiniMap.metres_per_pixel(0.0, 14))
	_check(MiniMap.metres_per_pixel(60.0, 14) < MiniMap.metres_per_pixel(0.0, 14) * 0.51, "half as many metres per pixel at 60°")
	var c := MiniMap.camera_pixel(Vector2(1000, 2000), 100.0, -50.0, 5.0)
	_check(c == Vector2(1020, 1990), "east moves right, north moves up: %s" % c)
	var inside := MiniMap.wanted_tiles(Vector2(128, 128), 100.0, 14)
	_check(inside.size() == 1 and inside[0] == Vector3i(14, 0, 0), "a window inside one tile wants one: %s" % [inside])
	var corner := MiniMap.wanted_tiles(Vector2(256, 256), 100.0, 14)
	_check(corner.size() == 4, "on a tile corner it wants four: %d" % corner.size())
	_check(absf(MiniMap.horizontal_fov(70.0, 16.0 / 9.0) - 102.0) < 1.5, "wide-screen horizontal field of view: %s" % MiniMap.horizontal_fov(70.0, 16.0 / 9.0))
	_check(absf(MiniMap.horizontal_fov(70.0, 1.0) - 70.0) < 0.01, "square: the same")

# --- Walking ---

func _walk_maths() -> void:
	_check(ViewWalk.is_tap(Vector2(10, 10), Vector2(13, 12), 120), "a short press is a tap")
	_check(not ViewWalk.is_tap(Vector2(10, 10), Vector2(60, 10), 120), "a drag is not")
	_check(not ViewWalk.is_tap(Vector2(10, 10), Vector2(10, 10), 900), "a long press is not")
	_check(ViewWalk.glide_seconds(5.0) == ViewWalk.GLIDE_MIN_S and ViewWalk.glide_seconds(5000.0) == ViewWalk.GLIDE_MAX_S,
		"glides take between the minimum and the maximum")
	_check(ViewWalk.ground_hit(Vector3(0, 30, 0), Vector3(0, 0.1, -1), null) == Vector2.INF, "no ground, no hit")
	_check(is_equal_approx(ViewWalk.lifted(0.0, 1, 1.0), ViewWalk.RISE_MPS), "E climbs RISE_MPS a second")
	_check(ViewWalk.lifted(0.0, -1, 1.0) == 0.0, "Q never goes below the eye level")
	_check(ViewWalk.lifted(ViewWalk.LIFT_MAX_M, 1, 5.0) == ViewWalk.LIFT_MAX_M, "the climb stops at the ceiling")
	_check(ViewWalk.lifted(0.0, 1, 1.0, true) > ViewWalk.lifted(0.0, 1, 1.0), "Shift climbs faster")

# --- Search: a pasted link opens its view ---

func _search_link() -> void:
	var picker := MapPicker.new()
	root.add_child(picker)
	picker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picker.size = Vector2(390, 844)
	await process_frame
	await process_frame
	var got: Array = []
	picker.view_link_requested.connect(func(state: Dictionary) -> void: got.append(state))
	var link := ViewLink.encode({"lat": 46.69, "lon": 7.858, "eye_m": 4.0, "bearing": 147.0, "pitch": -4.0})
	picker._search.text = link
	picker._on_search_text_changed(link)
	await process_frame
	_check(picker._suggest_panel.visible and picker._suggest_list.get_child_count() == 1,
		"a pasted link offers one row")
	var row := picker._suggest_list.get_child(0) as Button
	_check(row != null and row.text.begins_with("Shared view · 46.6900° N"), "the row names the shared view: %s" % (row.text if row != null else "-"))
	if row != null:
		row.pressed.emit()
	_check(got.size() == 1 and absf(float(got[0]["lat"]) - 46.69) < 0.001 and float(got[0]["bearing"]) == 147.0,
		"tapping it opens that view: %s" % [got])
	MapSearch.submit(picker, "  " + link + " ")
	_check(got.size() == 2, "Enter opens it too")
	MapSearch.submit(picker, "pr360://view?lat=x&lon=1")
	_check(got.size() == 2, "a broken link opens nothing")
	var near := MapSearch.looks_like_coordinates(link)
	_check(not near, "a link is not read as coordinates")
	picker.queue_free()
	await process_frame

# --- The real view ---

func _flat(lat: float, lon: float, name: String) -> LocationData:
	var flat := LocationData.new()
	flat.grid_size = 8
	flat.heights.resize(64)
	for i in 64:
		flat.heights[i] = 3.0
	flat.place_name = name
	flat.latitude = lat
	flat.longitude = lon
	return flat

func _view_wiring() -> void:
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280, 800)
	await process_frame
	view._wiki.offline_mode = true
	view._horizon._fetcher.offline_mode = true
	view._weather.queue_free()
	view._weather = null
	var data := _flat(60.4518, 22.2666, "Testville")
	data.view = ViewLink.to_view({"lat": 60.4518, "lon": 22.2666, "eye_m": 31.0, "bearing": 200.0,
		"pitch": -6.0, "zoom": 1.4, "minutes": 480.0, "season": 0,
		"date": {"year": 2026, "month": 4, "day": 20}})
	data.season = 0
	view.show_location(data)
	await process_frame
	await process_frame
	# A phone on its side: the ring keeps clear of the inspector, which
	# scrolls (and only then clips); a landmark behind it waits.
	for phone_size: Vector2 in [Vector2(667, 375), Vector2(844, 390)]:
		view.size = phone_size
		ViewChrome.layout(view)
		var ring := Rect2(view._compass.position, Vector2(CompassDial.RING, CompassDial.RING))
		_check(not ring.intersects(Rect2(view._sheet.position, view._sheet.size)),
			"the compass clears the inspector at %s" % phone_size)
		_check(view._sheet_scroll.clip_contents, "a tight inspector scrolls and clips at %s" % phone_size)
	var eye := view._rig.camera
	var sheet_mid := view._sheet.get_global_rect().get_center()
	_check(view._callouts._behind_sheet(eye, {"pos": eye.project_position(sheet_mid, 50.0)}),
		"a landmark behind the inspector waits")
	_check(not view._callouts._behind_sheet(eye, {"pos": eye.project_position(Vector2(100, 200), 50.0)}),
		"a landmark in the open shows")
	# Near the panel's edge: a new card waits, one already up stays.
	var near_edge := {"id": "edge", "pos": eye.project_position(view._sheet.get_global_rect().position + Vector2(10, 40), 50.0)}
	_check(view._callouts._behind_sheet(eye, near_edge), "a new landmark at the panel's edge waits")
	var held := Control.new()
	view._callouts._cards["edge"] = held
	_check(not view._callouts._behind_sheet(eye, near_edge), "a card already up stays at the panel's edge")
	view._callouts._cards.erase("edge")
	held.free()
	var minimap_was := UiPrefs.minimap
	UiPrefs.minimap = true
	ViewChrome.layout(view)
	_check(view._minimap.visible and not Rect2(view._hint.position, view._hint.size).intersects(view._minimap.get_rect()),
		"the hint keeps off the mini-map on a phone on its side")
	UiPrefs.minimap = minimap_was
	var fps_was := UiPrefs.fps_counter
	UiPrefs.fps_counter = false
	var fps_events := []
	view.pref_changed.connect(func(k: String, val: Variant) -> void: fps_events.append([k, val]))
	ViewTools.toggle_fps(view)
	_check(UiPrefs.fps_counter and view._fps.visible and fps_events == [["fps_counter", true]],
		"the FPS counter switches on and reports the pref")
	_check(not view._fps.get_rect().intersects(view._top_right.get_rect()), "the FPS counter sits clear of the top-right chips")
	_check(view._fps.is_processing(), "the FPS counter processes while shown")
	var side_size := view.size
	view.size = Vector2(844, 390)
	ViewChrome.layout(view)
	_check(not view._fps.get_rect().intersects(view._sheet.get_rect()) and not view._fps.get_rect().intersects(view._top_right.get_rect()),
		"the FPS counter keeps off the inspector on a phone on its side")
	view.size = side_size
	ViewChrome.layout(view)
	ViewTools.toggle_fps(view)
	_check(not UiPrefs.fps_counter and not view._fps.visible and not view._fps.is_processing(), "and off again, idle")
	UiPrefs.fps_counter = fps_was
	view.size = Vector2(1280, 800)
	ViewChrome.layout(view)
	_check(not view._sheet_scroll.clip_contents, "a roomy inspector doesn't clip focus rings")
	_check(absf(rad_to_deg(-view._rig.yaw) - 200.0) < 0.01 or absf(fposmod(rad_to_deg(-view._rig.yaw), 360.0) - 200.0) < 0.01,
		"the saved bearing is restored: %s" % rad_to_deg(-view._rig.yaw))
	_check(absf(rad_to_deg(view._rig.pitch) + 6.0) < 0.01, "a pitch below the horizon is kept: %s" % rad_to_deg(view._rig.pitch))
	_check(absf(view._rig.zoom_factor - 1.4) < 0.001, "the zoom is restored")
	var ground_y := view._ground.height_at_world(view._rig.position.x, view._rig.position.z)
	_check(absf(view._rig.position.y - ground_y - 31.0) < 0.01, "the eye stands where it did: %s" % (view._rig.position.y - ground_y))
	_check(view._date == {"year": 2026, "month": 4, "day": 20}, "the date is restored: %s" % [view._date])
	_check(absf(view._time_hour - 8.0) < 0.001, "and the time: %s" % view._time_hour)
	_check(view._atmos.solar_date() == {"year": 2026, "month": 4, "day": 20}, "the sun is computed for that day")
	var this_year := int(Time.get_date_dict_from_system().get("year", 0))
	_check(view._sun_arc.day_btn.text == ("20 Apr" if this_year == 2026 else "20 Apr 2026"),
		"the day chip names the date: %s" % view._sun_arc.day_btn.text)
	_check(ViewConditions.date_text(view._date) == "20 Apr 2026" and ViewConditions.date_text(view._date, false) == "20 Apr",
		"the label reads with or without its year")
	var back := view.camera_state()
	_check(absf(float(back["bearing"]) - 200.0) < 0.01 and absf(float(back["eye_m"]) - 31.0) < 0.01
		and absf(float(back["zoom"]) - 1.4) < 0.001 and not back.has("eye_lat"),
		"camera_state captures the camera: %s" % [back])
	var link := ViewTools.current_link(view)
	var linked := ViewLink.parse(link)
	_check(int(linked["minutes"]) == 480 and int(linked["season"]) == 0 and linked["date"] == view._date,
		"the copied link carries time, season and date: " + link)

	# HUD tools exist, the keys reach them.
	for key in ["date", "photo", "link", "labels", "map"]:
		_check(view._tool_btns.has(key) and (view._tool_btns[key] as Button).tooltip_text != "", "tool button: " + key)
	_check(view._sun_arc._play_btn != null and view._sun_arc._play_btn.tooltip_text == "Play the day", "the arc has a play button")
	_check(view._season_btn == view._date_picker.seasons and view._season_btn.item_count == 4,
		"the seasons live in the day and season sheet")
	var noon_jump := view._sun_arc._jumps[1]
	_check(noon_jump.text.length() == 5 and noon_jump.text[2] == ":" and noon_jump.accessibility_name.begins_with("Noon, "),
		"the jumps show their times: %s" % noon_jump.text)
	_check(view._tool_btns["photo"].text == "Save photo" and view._tool_btns["link"].text == "Copy link",
		"photo and link are labelled")
	var emitted: Array = []
	view.pref_changed.connect(func(k: String, v: Variant) -> void: emitted.append([k, v]))
	var press := func(code: Key) -> void:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.pressed = true
		ViewChrome.handle_key(view, ev)
	press.call(KEY_N)
	_check(view._horizon.enabled and UiPrefs.horizon_labels and emitted.has(["horizon_labels", true]), "N turns the horizon labels on and saves it")
	press.call(KEY_N)
	_check(not view._horizon.enabled, "and off")
	(view._tool_btns["labels"] as Button).pressed.emit()
	_check(view._horizon.enabled and UiPrefs.horizon_labels, "the labels button turns labels on")
	var camera := view._rig.camera
	var forward := -camera.global_transform.basis.z
	var target := camera.global_position + Vector3(forward.x, 0.0, forward.z).normalized() * 1000.0
	view._horizon._items = [{"name": "Test peak", "kind": "Peak", "ele_m": 100.0, "pos": target}]
	var laid_out := view._horizon.layout_labels(camera, view.size, UiTheme.sans(600), UiTheme.data(true), false)
	_check(laid_out.size() == 1 and laid_out[0]["line1"] == "Test peak", "a visible site gets a label")
	view._horizon._fetcher._req.exhausted.emit("test failure", 1)
	_check(view._horizon._fetched_for == Vector2(INF, INF), "a failed label request can be retried")
	(view._tool_btns["labels"] as Button).pressed.emit()
	_check(not view._horizon.enabled, "the labels button turns labels off")
	press.call(KEY_M)
	_check(UiPrefs.minimap and view._minimap.visible, "M shows the mini-map")
	press.call(KEY_M)
	_check(not view._minimap.visible, "and hides it")
	# A sheet hides the inset for the moment; M still switches the
	# preference, both ways, and the button tells the truth.
	press.call(KEY_M)
	view._landmark_panel.open_list([])
	ViewChrome.layout(view)
	_check(UiPrefs.minimap and not view._minimap.visible, "an open landmark sheet hides the on mini-map")
	press.call(KEY_M)
	_check(not UiPrefs.minimap and emitted.has(["minimap", false]), "M switches it off even while a sheet hides it")
	_check(not (view._tool_btns["map"] as Button).get_meta("selected", true),
		"the map chip goes off with it")
	press.call(KEY_M)
	_check(UiPrefs.minimap and not view._minimap.visible, "M switches it back on, still hidden by the sheet")
	_check((view._tool_btns["map"] as Button).get_meta("selected", false)
		and (view._tool_btns["map"] as Button).get_theme_stylebox("normal").bg_color.is_equal_approx(UiTheme.TEAL_SOFT),
		"and the chip is selected though the inset is hidden")
	view._landmark_panel.close()
	ViewChrome.layout(view)
	_check(view._minimap.visible, "closing the sheet brings it back")
	press.call(KEY_M)
	press.call(KEY_T)
	_check(view._lapse.playing and not view._live_time, "T plays the time-lapse and leaves live time")
	_check(view._sun_arc._speed_btn.visible and view._sun_arc._play_btn.tooltip_text == "Pause time-lapse", "the arc shows pause and the speed")
	view._process(0.2)
	var after := view._time_hour * 60.0
	_check(absf(after - 480.0) > 1.0, "a frame moves the sun: %s" % after)
	ViewConditions.set_time_minutes(view, 600.0)
	_check(not view._lapse.playing, "scrubbing the arc stops the time-lapse")
	press.call(KEY_T)
	ViewConditions.cycle_lapse_speed(view)
	_check(view._lapse.speed() == 2 and view._sun_arc._speed_btn.text == "2×", "the speed button cycles")
	ViewConditions.toggle_lapse(view)
	# Date: pick a winter day; the season follows, the sun moves.
	var before_elev := view._atmos.solar_elevation
	await ViewConditions.set_date(view, {"year": 2026, "month": 12, "day": 21})
	_check(view._date == {"year": 2026, "month": 12, "day": 21} and view._data.season == LocationData.Season.WINTER,
		"a December day makes it winter")
	_check(view._season_btn.selected == LocationData.Season.WINTER, "the season control follows")
	_check(view._atmos.solar_elevation < before_elev, "the winter sun stands lower: %s -> %s" % [before_elev, view._atmos.solar_elevation])
	ViewConditions._on_season_selected(view, LocationData.Season.SUMMER)
	var date_cleared: bool = view._date.is_empty()
	while view._season_building:
		await process_frame
	_check(date_cleared and view._sun_arc.day_btn.text == "Summer", "a season returns to the season's own day")
	ViewConditions.use_live_time(view)
	_check(view._live_time and view._date.is_empty(), "Now clears the date")
	ViewTools.toggle_date(view)
	_check(view._date_picker.visible, "the date button opens the picker")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	_check(ViewChrome.handle_key(view, esc) and not view._date_picker.visible, "Esc closes the picker")

	# Weather: the Conditions sheet picks a preset over the live weather.
	var picker := view._date_picker
	_check(picker.weather_rows.size() == 2 and picker.weather_rows[0].item_count == 4
		and picker.weather_rows[1].item_count == 4, "the sheet has two rows of four weather segments")
	for w in DatePicker.WEATHER:
		_check(FileAccess.file_exists("res://assets/icons/%s.svg" % w[1]), "weather icon ships: %s" % w[1])
	_check(HudParts.weather_icon(45) == "cloud-fog" and HudParts.weather_icon(53) == "cloud-drizzle"
		and HudParts.weather_icon(63) == "cloud-rain" and HudParts.weather_icon(95) == "cloud-lightning",
		"the live chip's glyphs match the presets")
	ViewConditions._on_weather(view, 21.0, "Clear", 5.0, 0)
	_check(view._weather_pick == 0 and view._atmos.weather_code == 0 and view._weather_value.visible,
		"live weather shows while Live is on")
	picker.weather_rows[1].item_selected.emit(2)
	_check(view._weather_pick == 6 and view._atmos.weather_code == 73
		and view._precip != null and view._precip.emitting, "Snow forces snowfall")
	_check(picker.weather_rows[0].selected == -1 and picker.weather_rows[1].selected == 2,
		"one weather segment is on across both rows")
	_check(view._weather_chip.visible and not view._weather_value.visible and view._weather_label.text == "Snow",
		"the chip names the picked weather without a temperature")
	ViewConditions._on_weather(view, 22.0, "Clear", 5.0, 0)
	_check(view._atmos.weather_code == 73 and float(view._live_weather[0]) == 22.0,
		"live weather landing later keeps the pick")
	ViewConditions.pick_weather(view, 7)
	_check(bool(view._atmos.weather_look["storm"]), "Storm brings the thunderstorm")
	ViewConditions.pick_weather(view, 0)
	_check(view._atmos.weather_code == 0 and not view._precip.emitting and view._weather_value.visible
		and picker.weather_rows[0].selected == 0, "Live returns to the real weather")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	view._weather_chip.gui_input.emit(click)
	_check(picker.visible, "the weather chip opens the Conditions sheet")
	picker.close_picker()
	# A phone: the live chip keeps the value only, and no chip runs past
	# the right gutter, picked or not (the window may resize after it filled).
	view.size = Vector2(390, 844)
	ViewChrome.layout(view)
	await process_frame
	_check(not view._weather_label.visible, "the live chip drops its word on a phone")
	for pick in [1, 5, 7, 0]:
		ViewConditions.pick_weather(view, pick)
		ViewChrome.layout(view)
		await process_frame
		var right := view._weather_chip.global_position.x + view._weather_chip.size.x
		_check(right <= 390.0 - 16.0 + 0.5, "the weather chip stays inside the phone's gutter (pick %d): %s" % [pick, right])
	view.size = Vector2(1280, 800)
	ViewChrome.layout(view)
	await process_frame
	_check(view._weather_label.visible, "the live chip shows its word on a desktop")
	ViewConditions.pick_weather(view, 4)
	ViewConditions.reset_weather(view)
	_check(view._weather_pick == 0 and view._live_weather.is_empty() and picker.weather == 0
		and view._atmos.weather_code == -1, "a new place opens on Live")

	# Walking: a tap on the ground glides there, far taps are refused.
	var cam := view._rig.camera
	var hit := ViewWalk.ground_hit(cam.global_position, Vector3(0.0, -0.5, -1.0).normalized(), view._ground)
	_check(hit != Vector2.INF, "a ray looking down meets the ground")
	if hit != Vector2.INF:
		var expect := cam.global_position.z - (cam.global_position.y
			- view._ground.height_at_world(cam.global_position.x, cam.global_position.z)) / 0.5
		_check(absf(hit.y - expect) < 3.0, "at the right distance: %s vs %s" % [hit.y, expect])
	_check(ViewWalk.ground_hit(cam.global_position, Vector3(0, 0.3, -1).normalized(), view._ground) == Vector2.INF, "a ray at the sky meets nothing")
	var here := Vector2(view._rig.position.x, view._rig.position.z)
	_check(view._walk.walk_to(view, here + Vector2(0, -40)), "walking 40 m is allowed")
	await create_timer(ViewWalk.GLIDE_MAX_S + 0.5).timeout
	_check(absf(view._rig.position.z - (here.y - 40.0)) < 0.5, "and arrives: %s" % view._rig.position)
	_check(not view._walk.walk_to(view, Vector2(0, 5000)), "5 km is past the built area")
	_check(view._walk.walk_to(view, here + Vector2(0, -20)), "a click can start a glide")
	var walk_key := InputEventKey.new()
	walk_key.keycode = KEY_W
	walk_key.pressed = true
	Input.parse_input_event(walk_key)
	Input.flush_buffered_events()
	view._walk.process_keys(view, 0.1)
	_check(not view._visit_tween.is_running(), "walking interrupts a click-to-walk glide")
	var walk_release := InputEventKey.new()
	walk_release.keycode = KEY_W
	Input.parse_input_event(walk_release)
	Input.flush_buffered_events()
	view._walk.process_keys(view, 0.01)

	# Photo with no picture (headless): a plain message, no crash.
	ViewTools.photo(view)
	_check(view._toast.visible and view._toast.title_text() == "Couldn't take the photo", "no picture: a plain message")
	ViewTools.copy_link(view)
	_check(view._toast.title_text() == "View link copied", "copying a link says so")

	# A photo that cannot be written says so; a cancelled dialog says nothing.
	var saved: Array = []
	var record := func(path: String, failed: bool) -> void: saved.append([path, failed])
	PhotoMode.dir_override = "/nonexistent-dir-pr360"
	PhotoMode.save(Image.create(4, 4, false, Image.FORMAT_RGB8), "x.png", record)
	_check(saved == [["", true]], "a failed write is reported as a failure: %s" % [saved])
	saved.clear()
	var photo_dir := ProjectSettings.globalize_path(CACHE)
	PhotoMode.dir_override = photo_dir
	PhotoMode.save(Image.create(4, 4, false, Image.FORMAT_RGB8), "photo.png", record)
	var ok_path := photo_dir.path_join("photo.png")
	_check(saved == [[ok_path, false]] and FileAccess.file_exists(ok_path), "a written photo reports its path")
	PhotoMode.dir_override = ""

	# A restored camera beyond the walking circle can walk back inside.
	view._rig.position = Vector3(0, view._rig.position.y, -View360.IN_PLACE_M - 10.0)
	view._rig.set_look(0.0, 0.0)
	var back_key := InputEventKey.new()
	back_key.keycode = KEY_S
	back_key.pressed = true
	Input.parse_input_event(back_key)
	Input.flush_buffered_events()
	view._walk.process_keys(view, 0.5)
	_check(view._rig.position.z > -View360.IN_PLACE_M - 10.0, "walk back toward the boundary from outside")
	var back_release := InputEventKey.new()
	back_release.keycode = KEY_S
	Input.parse_input_event(back_release)
	Input.flush_buffered_events()
	view._walk.process_keys(view, 0.01)

	# At the edge, holding an outward direction must not suppress climbing.
	view._rig.position = Vector3(0, View360.eye_y(data, view._ground, Vector2(0, -View360.IN_PLACE_M), false),
		-View360.IN_PLACE_M)
	for code in [KEY_W, KEY_E]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.pressed = true
		Input.parse_input_event(ev)
	Input.flush_buffered_events()
	var before_climb := view._rig.position.y
	view._walk.process_keys(view, 0.5)
	_check(view._rig.position.y > before_climb + 1.0, "climb while walking against the edge")
	for code in [KEY_W, KEY_E]:
		var ev := InputEventKey.new()
		ev.keycode = code
		Input.parse_input_event(ev)
	Input.flush_buffered_events()
	view._walk.process_keys(view, 0.01)

	# The letter keys are not the view's while a text field has the keyboard.
	_check(ViewWalk.keys_free(view), "bare keys walk")
	var field := LineEdit.new()
	view.add_child(field)
	field.grab_focus()
	_check(not ViewWalk.keys_free(view), "a focused text field keeps W A S D")
	field.queue_free()

	# The History picture is only re-taken when the view changed.
	var key := view.look_key()
	_check(not key.is_empty() and key == view.look_key(), "an unchanged view has an unchanged look")
	view._rig.set_look(view._rig.yaw + 0.3, view._rig.pitch)
	_check(key != view.look_key(), "turning changes it")
	key = view.look_key()
	ViewConditions.set_time_minutes(view, view._time_hour * 60.0 + 30.0)
	_check(key != view.look_key(), "so does the time")

	# Phones: with the controls tucked away, the round tab never sits on a
	# sheet that takes the bar's place.
	view.size = Vector2(390, 844)
	view._inspector_open = false
	ViewChrome.layout(view)
	_check(view._sheet_tab.visible, "controls hidden on a phone: the tab offers them back")
	_check(not view._fullscreen_btn.visible and not view._zoom_stack.get_node("Zoom").visible,
		"phones leave out fullscreen and the zoom buttons")
	view._landmark_panel.open_list([])
	ViewChrome.layout(view)
	_check(not view._sheet_tab.visible, "the landmark sheet in the bar's place hides the tab")
	view._landmark_panel.close()
	ViewChrome.layout(view)
	ViewTools.toggle_date(view)
	_check(not view._sheet_tab.visible, "so does the date sheet")
	ViewTools.toggle_date(view)
	_check(view._sheet_tab.visible, "and it returns when the sheet closes")
	view.queue_free()
	await process_frame
