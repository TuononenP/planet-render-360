extends SceneTree

## Capture-and-compare run over the golden set (realism v3, R-1.1).
## Windowed, off-screen, never on top:
##   tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 \
##     -- [--tag=name] [--preset=0..3] [--places=id,id] [--times=golden,noon,night,late,roofs,sparkle] [--season=autumn]
##        [--landmarks=type,type]  (build registry landmarks through the real app flow)
##        [--date=YYYY-MM-DD] (explicit solar date, e.g. June white nights)
##        [--refs=morning] (reference subfolder, e.g. matching clear morning photos)
##        [--cold-cache] (isolated empty data cache for a real cold-load measurement)
##        [--pin=lat,lon] (one custom location; --places supplies its output id)
##        [--settle=seconds]  (wait after golden hour is set; default SETTLE_S)
##        [--weather=WMO code]  (forced weather; default 0 clear, 61 rain)
##        [--looks="lat,lon,height_m,bearing,pitch[,zoom];..."]  (candidate eyes, one
##          <id>_look<N>.jpg each: the eye stands height_m over the ground; zoom 0.7-2.8;
##          an eye inside or within 3 m of a building at least as tall as it moves to open ground)
##        [--look_time=late]  (take the looks two hours after sunset, not at golden hour)
##        [--size=WxH]  (frame size; default 1280x800)  [--png]  (lossless PNG, not JPEG)
##        [--frame_scale=2]  (opening eye that many times its usual distance from the landmark)
##        [--eye_min=40]  (opening eye at least that high over the ground, aimed at the landmark)
##
## Runs the real app flow (Main → pipeline → View360, caches first) for
## every quick-pick preset plus generic controls, under fixed conditions
## (summer, clear weather at the place's local golden hour, reduce-motion,
## FPS governor pinned at the preset), and saves the 3D view itself (the
## HUD is not drawn into it)
## to visual-plan/reviews/<tag>-<date>/:
##   <id>_vantage.jpg            opening look at golden hour
##   <id>_h000/090/180/270.jpg   N, E, S, W at golden hour
##   <id>_close1/2.jpg           narrow-FOV close-ups of the opening look
##   <id>_vantage_noon/night.jpg same opening look at noon and at night
##   <id>_vantage_late.jpg       two hours after sunset (--times=late)
##   <id>_roofs.jpg              from 140 m up, looking down the opening look (--times=roofs)
##   <id>_sheet.jpg              render beside the first reference photo
##   stats.json                  luma, saturation, colourfulness per frame
##                               and band, flagged against the references
## With --audit (R-1.4 look audit, a report only):
##   <id>_unshaded.jpg           opening look, albedo only (no light)
##   <id>_agx.jpg                opening look with AgX instead of ACES
##   audit.json                  per place, every StandardMaterial3D's mean
##                               linear albedo, flagged against ALBEDO_RANGES
## With --bake-thumbs (use --times=noon): each preset's opening look, in the afternoon
## (sun at CARD_SUN_DEG), becomes its shipped card picture, res://assets/preset_thumbs/<id>.jpg
## (PlaceThumb.load_preset); a preset in THUMB_LOOKS is shot from its own card look instead
## (<id>_thumb.jpg), framed on the city's best-known landmark. Card bakes run on Ultra.
## --look_time=noon takes candidate --looks at noon.
## With --capital-thumbs: every catalog capital without a picture is built and its noon
## look (aimed at its registry landmark when it has one, from THUMB_LOOKS["cap_<key>"]
## when listed, else the opening look) becomes res://assets/capital_thumbs/<city>_<country>.jpg
## (PlaceThumb.load_capital). Nothing else is captured; --places=berlin_germany,... limits it,
## --limit=N stops after N pictures, --shard=i/n takes every n-th place (run n instances), --redo replaces existing ones. Re-run to retry skipped places.
## Reference photos live in visual-plan/refs/<id>/ (see its README).
## History and user thumbnails are never written; settings are not saved.

const SIZE := Vector2i(1280, 800)
const PLACE_TIMEOUT_S := 600.0
const SETTLE_S := 2.5
## Frames drawn by a place's first settle: enough for SDFGI to converge
## on Ultra. The settles between its later shots (a new hour, the roofs
## look) start from a converged scene and draw SHOT_SETTLE_FRAMES.
const SETTLE_FRAMES := 240
const SHOT_SETTLE_FRAMES := 60
## Height of the --times=roofs look above the opening eye.
const ROOFS_UP_M := 140.0
const STEP := 4  # stats sample every 4th pixel in x and y
## Upper, middle and lower row bands (sky, skyline, ground at a level look).
const BANDS := {"upper": [0.0, 0.35], "middle": [0.35, 0.65], "lower": [0.65, 1.0]}
## A frame is flagged when a whole-frame stat leaves the references'
## range widened by this fraction.
const REF_SLACK := 0.15
const WEATHER_WAIT_S := 20.0
## Measured mean linear albedo per surface class (the R-1.4 ranges); a
## material is classed by the first keyword its cache key contains.
const ALBEDO_RANGES := {
	"glass": [0.08, 0.15], "brick": [0.20, 0.35], "limestone": [0.45, 0.60],
	"concrete": [0.30, 0.45], "terracotta": [0.25, 0.40], "asphalt": [0.06, 0.12],
	"grass": [0.15, 0.25], "lawn": [0.15, 0.25],
}

## Generic controls beside the presets: the old Paris pin every past
## baseline used, the old Setagaya Tokyo pin, and places with no preset.
const CONTROLS := [
	{"id": "amsterdam", "name": "Amsterdam, Netherlands", "lat": 52.3717, "lon": 4.8897},
	{"id": "paris_old", "name": "Paris, France", "lat": 48.8566, "lon": 2.3522},
	{"id": "tokyo_setagaya", "name": "Tokyo, Japan", "lat": 35.6762, "lon": 139.6503},
	{"id": "turku", "name": "Turku, Finland", "lat": 60.4518, "lon": 22.2666},
	{"id": "zermatt", "name": "Zermatt, Switzerland", "lat": 46.0207, "lon": 7.7491},
	{"id": "cairo", "name": "Cairo, Egypt", "lat": 30.0444, "lon": 31.2357},
	# Winter in the golden set: snow lying and falling at the Helsinki
	# preset's eye, whatever --season and --weather the run is given.
	{"id": "helsinki_winter", "name": "Helsinki, Finland", "lat": 60.1679, "lon": 24.9525,
		"season": "winter", "weather": 73},
	# The tropics in the golden set: Angkor Wat and its precinct in the wet
	# season, and again at the end of the dry season (straw grass).
	{"id": "angkor_wat", "name": "Angkor Wat, Cambodia", "lat": 13.41249, "lon": 103.86684},
	{"id": "angkor_wat_dry", "name": "Angkor Wat, Cambodia", "lat": 13.41249, "lon": 103.86684,
		"season": "winter"},
]

## --bake-thumbs: card looks [lat, lon, height_m, bearing°, pitch°, zoom] for presets
## whose opening look does not frame the city's best-known landmark well at card size.
## Checked in captures (visual-plan/reviews/thumbcand*-2026-11-15).
const THUMB_LOOKS := {
	# From above the south side of Senate Square, down it to Helsinki Cathedral.
	"helsinki": [60.1683, 24.9522, 45.0, 358.0, -6.0, 1.25],
	# Monteliusvägen, across Riddarfjärden to City Hall.
	"stockholm": [59.3207, 18.0604, 25.0, 335.0, 1.0, 2.8],
	# The Bacino, across to Santa Maria della Salute.
	"venice": [45.4318, 12.3405, 5.0, 258.0, 3.0, 2.2],
	# Gwanghwamun on its axis, closer than the opening look.
	"seoul": [37.574978, 126.976772, 4.0, 0.0, 6.0, 1.9],
	# Surprise Corner, close on the Banff Springs Hotel.
	"banff": [51.1676, -115.5596, 28.0, 203.0, -3.0, 2.5],
	# Over the station side, down onto the Scramble and QFRONT.
	"tokyo": [35.65915, 139.70085, 20.0, 318.0, -15.0, 1.0],
	# Over Russian Hill, out to the Golden Gate Bridge.
	"san_francisco": [37.80195, -122.4196, 40.0, 292.0, 1.0, 2.8],
	# Queen's Walk, across the Thames to Big Ben and Parliament.
	"london": [51.5018, -0.1196, 8.0, 249.0, 7.0, 1.8],
	# Brooklyn Bridge Park, the Lower Manhattan skyline and Brooklyn Bridge.
	"new_york": [40.7030, -73.9975, 6.0, 338.0, 8.0, 1.25],
	# Over the Mall, down Central Park to the Billionaires' Row skyline.
	"central_park": [40.7745, -73.9705, 70.0, 205.0, -4.0, 1.3],
	# Over the port's north shore, onto the Casino's domes and gardens.
	"monaco": [43.7370, 7.4262, 60.0, 33.0, -2.0, 2.8],
	# The opening look, closer on the Eiffel Tower.
	"paris": [48.8622, 2.2887, 6.0, 142.0, 6.0, 1.5],
	# The opening look, up past the mall roofs to Burj Khalifa.
	"dubai": [25.19787, 55.28278, 20.0, 265.0, 20.0, 1.3],
	# Top of the Rock, the Empire State Building centred.
	"new_york_midtown": [40.7588, -73.9795, 240.0, 204.0, -6.0, 1.6],
	# Capitals (--capital-thumbs) whose automatic landmark look is blocked
	# or too far; checked in visual-plan/reviews/capcand*-2026-11-15.
	# Up to the Parthenon on the Acropolis from the north.
	"cap_athens_greece": [37.976, 23.724, 40.0, 154.7, 4.1, 2.48],
	# Parliament House and its flagmast over the lake shore.
	"cap_canberra_australia": [-35.296, 149.1255, 60.0, 183.9, -0.3, 2.8],
	# Cairo Tower from across the Nile (the registry primary is the Giza pyramid, 11 km off).
	"cap_cairo_egypt": [30.0455, 31.23, 30.0, 274.6, 6.6, 1.49],
	# Down onto the Umayyad Mosque's minarets and dome, the mountains behind.
	"cap_damascus_syria": [33.51, 36.305, 90.0, 45.4, -13.1, 1.67],
	# Over the Temple of Literature's courtyards.
	"cap_hanoi_vietnam": [21.03, 105.838, 60.0, 234.2, -11.2, 2.8],
	# From the north over the Royal Palace to the Almudena dome.
	"cap_madrid_spain": [40.42, -3.713, 40.0, 203.4, -4.9, 2.71],
	"cap_havana_cuba": [23.135, -82.365, 50.0, 86.8, -0.4, 2.8],
	# Across Victoria Harbour to the Bank of China Tower.
	"cap_hong_kong_hong_kong": [22.287, 114.169, 30.0, 222.0, 7.5, 1.72],
	# Gran Torre Santiago against the Andes.
	"cap_santiago_chile": [-33.44, -70.63, 150.0, 41.1, 0.0, 2.8],
	# St Peter's Basilica over the colonnades (the registry's primary is the Colosseum).
	"cap_vatican_city_vatican": [41.9022, 12.4605, 40.0, 270.0, 3.0, 1.99],
	"cap_warsaw_poland": [52.23, 21.013, 50.0, 292.8, 7.5, 1.14],
	# Charles Bridge, St Vitus on the castle hill behind.
	"cap_prague_czechia": [50.0855, 14.413, 40.0, 304.0, 0.4, 2.8],
	# Hassan Tower across its esplanade.
	"cap_rabat_morocco": [34.0228, -6.821, 25.0, 311.1, -0.8, 1.95],
	# Taipei 101 over the city, the hills behind.
	"cap_taipei_taiwan": [25.045, 121.545, 150.0, 122.6, 2.5, 2.3],
	# Over KLCC, the Petronas Towers and their skybridge.
	"cap_kuala_lumpur_malaysia": [3.1535, 101.7095, 120.0, 26.3, 11.1, 1.0],
	# Down Kartavya Path to India Gate.
	"cap_new_delhi_india": [28.6129, 77.2262, 25.0, 90.0, -0.7, 2.42],
}

var _out := ""
var _stats := {}
var _audit := {}
## The place's own weather answered (or failed): its UTC offset is set.
var _weather_in := false
## WMO weather code every capture forces (--weather=, default clear).
var _weather_code := 0
## Season every place is shot in (--season=spring|summer|autumn|winter or
## 0..3); -1 keeps the place's own.
var _season := -1
## Candidate eyes (--looks=): [lat, lon, height_m over ground, bearing°, pitch°].
var _looks: Array = []
## Least height (m) of a landmark's opening eye over the ground (--eye_min).
var _eye_min := 0.0
## Frame size every shot is taken at (--size); zero keeps the window's.
var _shot_size := Vector2i.ZERO
## When the --looks are taken: "" golden hour, "late" two hours after sunset.
var _look_time := ""
var _date_override: Dictionary = {}
var _reference_set := ""

func _init() -> void:
	_run()

func _args() -> Dictionary:
	var a := {"tag": "capture", "preset": 2, "places": "", "times": "golden,noon,night"}
	# Card pictures are baked on Ultra (--preset= still overrides it).
	var cmd := OS.get_cmdline_user_args()
	if cmd.has("--bake-thumbs") or cmd.has("--capital-thumbs"):
		a["preset"] = 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
		elif arg == "--audit":
			a["audit"] = true
		elif arg == "--cold-cache":
			a["cold_cache"] = true
		elif arg == "--capital-thumbs":
			a["capital_thumbs"] = true
		elif arg == "--redo":
			a["redo"] = true
	return a

## Capitals still without a shipped picture, as capture places.
func _capital_places(filter: String, redo: bool) -> Array:
	var want := filter.split(",", false)
	var out: Array = []
	var picks := LocationData.quick_picks()
	for i in range(PresetViews.ROWS.size(), picks.size()):
		var pick: Array = picks[i]
		var key := PlaceThumb.capital_slug(str(pick[1]))
		if not want.is_empty() and not want.has(key):
			continue
		if not redo and FileAccess.file_exists(ProjectSettings.globalize_path(PlaceThumb.capital_path(str(pick[1])))):
			continue
		out.append({"id": "cap_" + key, "name": str(pick[1]), "lat": float(pick[2]), "lon": float(pick[3])})
	return out

func _places(filter: String, landmark_types: String = "", pin: String = "") -> Array:
	var all: Array = []
	if pin != "":
		var coords := pin.split(",")
		if coords.size() != 2 or not coords[0].is_valid_float() or not coords[1].is_valid_float():
			push_error("CAPTURE: --pin requires latitude,longitude")
			return []
		return [{"id": filter if filter != "" else "pin", "name": "Custom location",
			"lat": float(coords[0]), "lon": float(coords[1])}]
	if not landmark_types.is_empty():
		for type in landmark_types.split(",", false):
			var entry := LocationData.entry_for_type(type)
			if entry.is_empty():
				printerr("CAPTURE: unknown landmark type ", type)
				continue
			all.append({"id": type, "name": entry["name"], "lat": entry["lat"], "lon": entry["lon"]})
		return all
	for row in PresetViews.ROWS:
		all.append({"id": row["id"], "name": row["name"], "lat": row["lat"], "lon": row["lon"]})
	all.append_array(CONTROLS)
	if filter == "":
		return all
	var want := filter.split(",")
	return all.filter(func(p: Dictionary) -> bool: return want.has(str(p["id"])))

func _run() -> void:
	var a := _args()
	_reference_set = str(a.get("refs", ""))
	_out = ProjectSettings.globalize_path("res://").path_join("visual-plan/reviews/%s-%s" % [
		a["tag"], Time.get_date_string_from_system()])
	DirAccess.make_dir_recursive_absolute(_out)
	CacheStore.eviction_suppressed = true
	if a.has("cold_cache"):
		CacheStore.dir_override = "user://capture-cold-%d" % OS.get_process_id()
		WorldCache.dir_override = CacheStore.dir_override.path_join("worlds")
		DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())
		_write_json("cold-cache.json", {"cache_dir": ProjectSettings.globalize_path(CacheStore.base_dir()),
			"world_cache_dir": ProjectSettings.globalize_path(WorldCache.base_dir())})
	RenderSettings.path_override = "user://capture-settings-%d.json" % OS.get_process_id()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.capture_mode = true
	# Avoid reopening a saved camera: every capture starts from its preset.
	main._store.entries.clear()
	var size := SIZE
	var wh := str(a.get("size", "")).split("x")
	if wh.size() == 2 and wh[0].is_valid_int() and wh[1].is_valid_int():
		size = Vector2i(int(wh[0]), int(wh[1]))
	root.size = size
	await create_timer(0.5).timeout
	root.size = size  # the first resize can be lost to window creation
	if size != SIZE:
		# The UI stretch would cap the 3D view at its logical size: render
		# at the real pixel size instead (the HUD is not in the shot).
		if root.size_changed.is_connected(main._fit_content_scale):
			root.size_changed.disconnect(main._fit_content_scale)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.content_scale_factor = 1.0
	for child in main.get_children():
		if child is OnboardingScreen:
			child.queue_free()
	UiPrefs.reduce_motion = true
	main._settings.preset = int(a["preset"])  # in memory only, never saved
	View360.frame_scale = float(a.get("frame_scale", 1.0))
	_eye_min = float(a.get("eye_min", 0.0))
	_card_sun = float(a.get("card_sun", CARD_SUN_DEG))
	var view: View360 = main._view
	view._governor.set_process(false)
	if size != SIZE:
		# The window can be clamped to the screen (and the container stretch
		# follows its logical size): the 3D view renders at the asked size,
		# re-asserted before every shot (_snap) since a place change resizes it.
		_shot_size = size
		view._container.stretch = false
		view._viewport.size = size
	# Live weather still lands (it carries the place's UTC offset, so the
	# golden hour is local), then each capture forces clear weather.
	view._weather.succeeded.connect(func(_t: float, _l: String, _c: float, _code: int) -> void:
		_weather_in = true)
	view._weather.failed.connect(func(_r: String) -> void: _weather_in = true)
	var times: PackedStringArray = str(a["times"]).split(",")
	_weather_code = int(a.get("weather", 0))
	_look_time = str(a.get("look_time", ""))
	for spec in str(a.get("looks", "")).split(";", false):
		var f := spec.split(",")
		if f.size() >= 5:
			# An optional sixth field zooms the look (CameraRig, 0.7-2.8).
			_looks.append([float(f[0]), float(f[1]), float(f[2]), float(f[3]), float(f[4]),
				float(f[5]) if f.size() >= 6 else 1.0])
	var season_arg := str(a.get("season", ""))
	_date_override = ViewLink.parse_date(str(a.get("date", "")))
	var names := ["spring", "summer", "autumn", "winter"]
	_season = names.find(season_arg) if season_arg in names else (int(season_arg) if season_arg.is_valid_int() else -1)
	var presets := str(a.get("presets", str(a["preset"]))).split(",", false)
	for preset in presets:
		main._settings.preset = int(preset)
		var todo: Array = _capital_places(str(a["places"]), a.has("redo")) if a.has("capital_thumbs") \
			else _places(str(a["places"]), str(a.get("landmarks", "")), str(a.get("pin", "")))
		# --shard=i/n: this instance takes every n-th place, so several can run at once.
		if a.has("shard"):
			var parts := str(a["shard"]).split("/")
			var mine: Array = []
			for k in todo.size():
				if k % int(parts[1]) == int(parts[0]):
					mine.append(todo[k])
			todo = mine
		if a.has("limit"):
			todo = todo.slice(0, int(a["limit"]))
		if a.has("capital_thumbs"):
			print("CAPITAL THUMBS: %d to capture" % todo.size())
		for place in todo:
			var spec: Dictionary = place.duplicate()
			if a.has("presets"):
				spec["id"] = str(place["id"]) + "_p" + preset
			await _capture(main, view, spec, times, a.has("audit"), float(a.get("settle", SETTLE_S)))
			# Preserve completed results if a later location or the renderer
			# stalls during a long golden-set run.
			_write_stats()
			if a.has("audit"):
				_write_json("audit.json", _audit)
	_write_stats()
	if a.has("audit"):
		_write_json("audit.json", _audit)
	print("CAPTURE DONE -> ", _out)
	quit(0)

func _capture(main: Node, view: View360, place: Dictionary, times: PackedStringArray,
		audit: bool, settle_s: float = SETTLE_S) -> void:
	var id := str(place["id"])
	main._picker.selected_name = str(place["name"])
	_weather_in = false
	main._start_generation(float(place["lat"]), float(place["lon"]))
	var start := Time.get_ticks_msec()
	while (main._generating or not view.visible) \
			and Time.get_ticks_msec() - start < int(PLACE_TIMEOUT_S * 1000.0):
		await process_frame
	if not view.visible or main._generating:
		printerr("CAPTURE SKIP %s: no view after %d s" % [id, (Time.get_ticks_msec() - start) / 1000])
		return
	print("CAPTURE %s built in %d s" % [id, (Time.get_ticks_msec() - start) / 1000])
	main._notice.visible = false
	view._governor.set_preset(int(main._settings.preset))
	var wait := Time.get_ticks_msec()
	while not _weather_in and Time.get_ticks_msec() - wait < int(WEATHER_WAIT_S * 1000.0):
		await process_frame
	# Clear captures keep a few clouds; forced weather comes overcast.
	# A place may pin its own season and weather (the winter control).
	var season := _season
	if place.has("season"):
		season = ["spring", "summer", "autumn", "winter"].find(str(place["season"]))
	var weather := int(place.get("weather", _weather_code))
	if season >= 0 and view._data.season != season:
		# Seasons bake into the world: this rebuilds it in that season.
		await ViewConditions._select_season(view, season)
	view._atmos.set_weather(weather, 15.0 if weather == 0 else 100.0)
	ViewConditions._apply_precip(view, weather)
	ViewConditions.apply_surface_state(view)
	if _date_override.is_empty():
		ViewConditions.spawn_golden_hour(view)
	else:
		await ViewConditions.set_date(view, _date_override)
		ViewConditions.set_time_minutes(view, PresetViews.opening_hour(view._data.view, view._atmos.golden_hour()) * 60.0)
	await _settle(settle_s, SETTLE_FRAMES)
	if OS.get_cmdline_user_args().has("--capital-thumbs"):
		if THUMB_LOOKS.has(id):
			_place_eye(view, id, "card", THUMB_LOOKS[id])
		else:
			_aim_landmark_card(view, id)
		_set_card_time(view)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await process_frame
		RenderingServer.force_draw(false)
		var card := view.snapshot()
		card.save_jpg(_out.path_join("%s_card.jpg" % id), 0.88)
		_bake_capital(card, str(place["name"]), id)
		return
	var rig := view._rig
	_lift_eye(view, _eye_min)
	var open := Vector2(rig.yaw, rig.pitch)
	var eye_open := rig.position
	await _snap(view, id, "vantage")
	if OS.get_cmdline_user_args().has("--bank-only"):
		rig.set_look(open.x, open.y - 0.3)
		rig.zoom_factor = 2.0
		rig.handle_zoom(1.0)
		await _snap(view, id, "bank")
		rig.zoom_factor = 1.0
		rig.handle_zoom(1.0)
		rig.set_look(open.x, open.y)
		return
	if audit:
		view._viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		await _snap(view, id, "unshaded")
		view._viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
		var env: Environment = view._atmos.environment
		var tonemap := env.tonemap_mode
		env.tonemap_mode = Environment.TONE_MAPPER_AGX
		await _snap(view, id, "agx")
		env.tonemap_mode = tonemap
		_audit[id] = albedo_audit(view._world_root)
	for bearing in [0, 90, 180, 270]:
		rig.set_look(-deg_to_rad(float(bearing)), -0.06)
		await _snap(view, id, "h%03d" % bearing)
	rig.set_look(open.x, open.y)
	rig.zoom_factor = 2.8
	rig.handle_zoom(1.0)
	await _snap(view, id, "close1")
	rig.set_look(open.x, open.y - 0.3)
	rig.zoom_factor = 2.0
	rig.handle_zoom(1.0)
	await _snap(view, id, "close2")
	rig.reset_zoom()
	rig.set_look(open.x, open.y)
	if times.has("roofs"):
		# Rooftops (clutter, roof forms) are out of sight from the street.
		var eye := rig.position
		rig.position = eye + Vector3(0.0, ROOFS_UP_M, 0.0)
		rig.set_look(open.x, -0.55)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "roofs")
		rig.position = eye
		rig.set_look(open.x, open.y)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
	if times.has("noon"):
		ViewConditions.jump_to(view, "noon")
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_noon")
		if OS.get_cmdline_user_args().has("--bake-thumbs"):
			if THUMB_LOOKS.has(id):
				_place_eye(view, id, "thumb", THUMB_LOOKS[id])
			_set_card_time(view)
			await _settle(1.0, SHOT_SETTLE_FRAMES)
			await _snap(view, id, "thumb")
			rig.reset_zoom()
			rig.position = eye_open
			rig.set_look(open.x, open.y)
			ViewConditions.jump_to(view, "noon")
	if times.has("night"):
		ViewConditions.jump_to(view, "moon")
		# Moonrise can come with the sun still up: then shoot the moonlit
		# night 90 minutes after sunset instead of a grey dusk.
		if view._atmos.night_amount < 0.9:
			ViewConditions.set_time_minutes(view, ViewConditions.sun_times(view).y + 90.0)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_night")
	if times.has("sparkle"):
		# A minute past the first full hour an hour after sunset: the
		# Eiffel Tower sparkles (LandmarkLights) for five minutes then.
		var on := ceilf((ViewConditions.sun_times(view).y + 60.0) / 60.0) * 60.0 + 1.0
		ViewConditions.set_time_minutes(view, on)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_sparkle")
	if times.has("late"):
		# Two hours after sunset: full dark, homes still lit (the moon jump
		# can land in a bright moonlit sky with the windows barely on).
		ViewConditions.set_time_minutes(view, ViewConditions.sun_times(view).y + 120.0)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_late")
	if not _looks.is_empty():
		# --look_time=late: the looks two hours after sunset (lamps, lit
		# windows); otherwise at golden hour.
		if _look_time == "late":
			ViewConditions.set_time_minutes(view, ViewConditions.sun_times(view).y + 120.0)
		elif _look_time == "noon":
			ViewConditions.jump_to(view, "noon")
		else:
			ViewConditions.spawn_golden_hour(view)
		# A clock change can re-show the place's live weather: pin the run's.
		var w := int(place.get("weather", _weather_code))
		view._atmos.set_weather(w, 15.0 if w == 0 else 100.0)
		ViewConditions._apply_precip(view, w)
		ViewConditions.apply_surface_state(view)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
	for k in _looks.size():
		_place_eye(view, id, "look%d" % k, _looks[k])
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "look%d" % k)
	_contact_sheet(id)

## Stands the camera at look `l` ([lat, lon, height_m, bearing°, pitch°, zoom]).
func _place_eye(view: View360, id: String, shot: String, l: Array) -> void:
	var rig := view._rig
	var at := WorldScale.xz_from_latlon(float(l[0]), float(l[1]), view._data.latitude, view._data.longitude)
	# Never shoot from inside a building (AGENTS.md): a blocked eye
	# moves to the nearest open ground.
	var free_at := _open_eye(view._data, at, float(l[2]))
	if free_at != at:
		print("CAPTURE MOVED %s %s: eye inside or against a building, moved %.1f m" % [id, shot, free_at.distance_to(at) / WorldScale.metres_to_units()])
		at = free_at
	var y := view._ground.height_at_world(at.x, at.y) + float(l[2]) * WorldScale.metres_to_units()
	rig.position = Vector3(at.x, y, at.y)
	rig.set_zoom(float(l[5]) if l.size() >= 6 else 1.0)
	rig.set_look(-deg_to_rad(float(l[3])), deg_to_rad(float(l[4])))

## Clearance (m) a capture eye keeps from any building wall: wide enough
## that a moved eye is not left pressed against the facade it escaped.
const EYE_CLEAR_M := 3.0
## How far (m) _open_eye searches for open ground before giving up.
const EYE_SEARCH_M := 40.0
## Assumed height (m) of a building with no height tag.
const EYE_UNKNOWN_HEIGHT_M := 10.0

## `at` (world xz) if it is open ground, else the nearest point on rings
## around it that lies outside every building footprint by EYE_CLEAR_M.
## Only buildings at least as tall as the eye (`eye_m` over the ground)
## count, so an aerial eye over a roof stays put. Unchanged when nothing
## open is found within EYE_SEARCH_M.
func _open_eye(data: LocationData, at: Vector2, eye_m: float) -> Vector2:
	var m := WorldScale.metres_to_units()
	var reach := (EYE_SEARCH_M + EYE_CLEAR_M) * m
	var near: Array = []
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
		if fp.size() < 3:
			continue
		var h := float(b.get("height", 0.0))
		if (h if h > 0.0 else EYE_UNKNOWN_HEIGHT_M) < eye_m:
			continue
		var box := Rect2(fp[0], Vector2.ZERO)
		for v in fp:
			box = box.expand(v)
		if box.grow(reach).has_point(at):
			near.append(fp)
	if not _eye_blocked(near, at, EYE_CLEAR_M * m):
		return at
	var r := 1.0
	while r <= EYE_SEARCH_M:
		# About one candidate per metre of ring, so a narrow lane far out
		# is not stepped over.
		var steps := maxi(24, ceili(TAU * r))
		for a in steps:
			var q := at + Vector2(cos(TAU * a / steps), sin(TAU * a / steps)) * r * m
			if not _eye_blocked(near, q, EYE_CLEAR_M * m):
				return q
		r += 1.0
	printerr("CAPTURE no open ground within %d m of a look eye" % int(EYE_SEARCH_M))
	return at

static func _eye_blocked(footprints: Array, p: Vector2, clear: float) -> bool:
	for fp: PackedVector2Array in footprints:
		if Geometry2D.is_point_in_polygon(p, fp):
			return true
		for i in fp.size():
			var q := Geometry2D.get_closest_point_to_segment(p, fp[i], fp[(i + 1) % fp.size()])
			if p.distance_to(q) < clear:
				return true
	return false

## Waits `seconds` while drawing at least `frames` frames. Off-screen,
## macOS stops redrawing the window (two frames in 30 s), so a plain timer
## left Ultra's SDFGI unconverged: the first place lost its sky and bounce
## light and only later places, after the earlier shots' draws, were lit.
func _settle(seconds: float, frames: int) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	var drawn := 0
	while drawn < frames or Time.get_ticks_msec() < end:
		await process_frame
		RenderingServer.force_draw(false)
		drawn += 1

## The 3D view only: the SubViewport's own texture carries no HUD.
## force_draw renders synchronously, so captures stay fresh even while
## the window sits off-screen.
## --eye_min: a landmark's opening eye at least `metres` over the ground,
## aimed at the model's middle (a far eye in forest otherwise sees only
## the trees round it); 0 leaves the app's own opening look.
func _lift_eye(view: View360, metres: float) -> void:
	var data: LocationData = view._data
	if metres <= 0.0 or data.landmark_type == "none":
		return
	var rig := view._rig
	var floor_y := view._ground.height_at_world(rig.position.x, rig.position.z) + metres
	if rig.position.y >= floor_y:
		return
	rig.position.y = floor_y
	var lp := TerrainBuilder.landmark_world_pos(data)
	var entry := LocationData.entry_for_type(data.landmark_type)
	var target := Vector3(lp.x, view._ground.height_at_world(lp.x, lp.y)
		+ float(entry.get("height_m", 20.0)) * 0.5, lp.y)
	var look := View360.aim(rig.position, target)
	rig.set_look(look.x, look.y)

## Sun elevation (degrees) card pictures are taken at, in the afternoon:
## the noon sun washes them out (--card_sun= overrides it).
const CARD_SUN_DEG := 15.0
var _card_sun := CARD_SUN_DEG

## The morning or afternoon minute the sun stands at _card_sun, whichever
## puts it more behind the camera (the landmark lit from the front, not a
## backlit silhouette); solar noon where it never climbs that high. Call
## once the camera faces the card's look.
func _set_card_time(view: View360) -> void:
	var t := ViewConditions.sun_times(view)
	var noon := (t.x + t.y) / 2.0
	var facing := -view._rig.yaw  # compass bearing, radians
	var best := noon
	var best_off := -1.0
	for step in [5.0, -5.0]:
		var m := noon
		while m > t.x and m < t.y and float(view._atmos.solar_at(m / 60.0)["elevation"]) > _card_sun:
			m += step
		var az := deg_to_rad(float(view._atmos.solar_at(m / 60.0)["azimuth"]))
		var off := absf(angle_difference(az, facing))
		if off > best_off:
			best_off = off
			best = m
	ViewConditions.set_time_minutes(view, best)

## Vertical angle (degrees) a capital's landmark fills on its card.
const CARD_FILL_DEG := 28.0
## Farthest (m) a capital card's eye stands from the world centre, inside
## the detailed extent.
const CARD_EYE_REACH_M := 1100.0

## --capital-thumbs: stands the eye off the place's landmark toward the
## city centre (about 3.5 heights away), over the rooftops, aimed at the
## landmark's middle and zoomed so it fills about CARD_FILL_DEG of the
## frame; leaves the opening look when the place has no landmark.
func _aim_landmark_card(view: View360, id: String) -> void:
	var data: LocationData = view._data
	if data.landmark_type == "none":
		return
	var entry := LocationData.entry_for_type(data.landmark_type)
	var m := WorldScale.metres_to_units()
	var h := float(entry.get("height_m", 20.0))
	var lp := TerrainBuilder.landmark_world_pos(data)
	var toward_centre := -lp.normalized() if lp.length() > m else Vector2(0.0, 1.0)
	var eye := lp + toward_centre * clampf(h * 3.5, 180.0, 700.0) * m
	if eye.length() > CARD_EYE_REACH_M * m:
		eye = eye.normalized() * CARD_EYE_REACH_M * m
	var eye_m := clampf(h * 0.5, 20.0, 80.0)
	eye = _open_eye(data, eye, eye_m)
	var rig := view._rig
	rig.position = Vector3(eye.x, view._ground.height_at_world(eye.x, eye.y) + eye_m * m, eye.y)
	var base_y := TerrainBuilder.site_ground_y(data, view._ground, lp.x, lp.y)
	var dist_m := eye.distance_to(lp) / m
	rig.set_zoom(clampf(CARD_FILL_DEG / rad_to_deg(atan2(h, dist_m)), 1.0, 2.8))
	var look := View360.aim(rig.position, Vector3(lp.x, base_y + h * 0.5 * m, lp.y))
	rig.set_look(look.x, look.y)
	print("CARD %s: %s, %d m off, eye %d m up" % [id, entry.get("name", ""), int(dist_m), int(eye_m)])

func _snap(view: View360, id: String, shot: String) -> void:
	if _shot_size != Vector2i.ZERO and view._viewport.size != _shot_size:
		view._container.stretch = false
		view._viewport.size = _shot_size
		await _settle(0.5, SHOT_SETTLE_FRAMES)
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var img := view.snapshot()
	img.convert(Image.FORMAT_RGB8)
	var path := _out.path_join("%s_%s.jpg" % [id, shot])
	if OS.get_cmdline_user_args().has("--png"):
		img.save_png(path.get_basename() + ".png")
	img.save_jpg(path, 0.88)
	if shot == "thumb" and OS.get_cmdline_user_args().has("--bake-thumbs"):
		_bake_thumb(img, id)
	var s := frame_stats(img)
	var rig := view._rig
	s["camera"] = {
		"world_x": rig.position.x, "world_y": rig.position.y, "world_z": rig.position.z,
		"yaw_rad": rig.yaw, "pitch_rad": rig.pitch, "fov_deg": rig.camera.fov,
		"centre_lat": view._data.latitude, "centre_lon": view._data.longitude,
	}
	var wire_draws := 0
	for wire in view._world_root.find_children("OverheadWires_*", "MeshInstance3D", true, false):
		wire_draws += (wire as MeshInstance3D).mesh.get_surface_count()
	s["wire_draw_calls"] = wire_draws
	s["wire_draw_budget"] = OverheadWires.MAX_DRAW_CALLS
	var boat_draws := 0
	for marina in view._world_root.find_children("Marina", "Node3D", true, false):
		for node in marina.get_children():
			if node is MultiMeshInstance3D:
				boat_draws += node.multimesh.mesh.get_surface_count()
			elif node is MeshInstance3D:
				boat_draws += node.mesh.get_surface_count()
	s["marina_draw_calls"] = boat_draws
	s["marina_draw_budget"] = MarinaBuilder.MAX_DRAW_CALLS
	s["season"] = view._data.season
	s["sun_elevation_deg"] = view._atmos.solar_elevation
	s["local_hour"] = view._time_hour
	s["reference_set"] = _reference_set if _reference_set != "" else "default"
	var refs := _ref_ranges(id)
	if not refs.is_empty():
		s["flags"] = _flags(s, refs)
	_stats["%s_%s" % [id, shot]] = s
	print("SHOT %s_%s luma %.3f sat %.3f colourful %.3f" % [id, shot,
		float(s["all"]["luma"]), float(s["all"]["sat"]), float(s["all"]["colourful"])])

## --bake-thumbs: a preset's opening look at noon, card-sized, into the shipped
## res://assets/preset_thumbs/<id>.jpg its Around the world card shows.
func _bake_thumb(img: Image, id: String) -> void:
	if PresetViews.ROWS.filter(func(r: Dictionary) -> bool: return r["id"] == id).is_empty():
		return
	var small := PlaceThumb.shrink(img)
	if small == null:
		printerr("CAPTURE BAKE %s: blank frame, not written" % id)
		return
	var dir := ProjectSettings.globalize_path(PlaceThumb.BUNDLED_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	small.save_jpg(dir.path_join("%s.jpg" % id), PlaceThumb.QUALITY)

## --capital-thumbs: the noon opening look, card-sized, as the capital's picture.
func _bake_capital(img: Image, place_name: String, id: String) -> void:
	var small := PlaceThumb.shrink(img)
	if small == null:
		printerr("CAPTURE BAKE %s: blank frame, not written" % id)
		return
	var path := ProjectSettings.globalize_path(PlaceThumb.capital_path(place_name))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	small.save_jpg(path, PlaceThumb.QUALITY)
	print("CAPITAL THUMB %s -> %s" % [id, path.get_file()])

## Mean luma (Rec. 709), mean HSV saturation and Hasler–Süsstrunk
## colourfulness (0–1 scale), for the whole frame and per row band.
static func frame_stats(img: Image) -> Dictionary:
	var out := {"all": _band_stats(img, 0.0, 1.0)}
	for band in BANDS:
		var r: Array = BANDS[band]
		out[band] = _band_stats(img, float(r[0]), float(r[1]))
	return out

static func _band_stats(img: Image, top: float, bottom: float) -> Dictionary:
	var y0 := int(top * img.get_height())
	var y1 := int(bottom * img.get_height())
	var n := 0
	var luma := 0.0
	var sat := 0.0
	var rg := 0.0
	var yb := 0.0
	var rg2 := 0.0
	var yb2 := 0.0
	for y in range(y0, y1, STEP):
		for x in range(0, img.get_width(), STEP):
			var c := img.get_pixel(x, y)
			luma += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			var hi := maxf(c.r, maxf(c.g, c.b))
			sat += 0.0 if hi <= 0.0 else (hi - minf(c.r, minf(c.g, c.b))) / hi
			var a := c.r - c.g
			var b := 0.5 * (c.r + c.g) - c.b
			rg += a
			yb += b
			rg2 += a * a
			yb2 += b * b
			n += 1
	if n == 0:
		return {"luma": 0.0, "sat": 0.0, "colourful": 0.0}
	var m_rg := rg / n
	var m_yb := yb / n
	var sd := sqrt(maxf(rg2 / n - m_rg * m_rg, 0.0) + maxf(yb2 / n - m_yb * m_yb, 0.0))
	return {"luma": luma / n, "sat": sat / n,
		"colourful": sd + 0.3 * sqrt(m_rg * m_rg + m_yb * m_yb)}

## Whole-frame stat ranges over the place's reference photos, {} when
## it has none.
func _ref_ranges(id: String) -> Dictionary:
	var out := {}
	for img in _refs(id):
		var s: Dictionary = frame_stats(img)["all"]
		for k in s:
			var r: Vector2 = out.get(k, Vector2(INF, -INF))
			out[k] = Vector2(minf(r.x, float(s[k])), maxf(r.y, float(s[k])))
	return out

func _flags(s: Dictionary, refs: Dictionary) -> Array:
	var flags: Array = []
	for k in refs:
		var r: Vector2 = refs[k]
		var v := float(s["all"][k])
		if v < r.x * (1.0 - REF_SLACK) or v > r.y * (1.0 + REF_SLACK):
			flags.append("%s %.3f outside refs %.3f–%.3f" % [k, v, r.x, r.y])
	return flags

func _refs(id: String) -> Array:
	var dir := ProjectSettings.globalize_path("res://").path_join("visual-plan/refs/%s" % id)
	if _reference_set != "":
		dir = dir.path_join(_reference_set)
	var out: Array = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	var files := DirAccess.get_files_at(dir)
	var has_winter := false
	for f in files:
		if f.get_extension().to_lower() in ["jpg", "jpeg", "png"] and f.to_lower().contains("winter"):
			has_winter = true
	for f in files:
		if has_winter and _season >= 0 and f.to_lower().contains("winter") != (_season == LocationData.Season.WINTER):
			continue
		if f.get_extension().to_lower() in ["jpg", "jpeg", "png"]:
			var img := Image.load_from_file(dir.path_join(f))
			if img != null:
				img.convert(Image.FORMAT_RGB8)
				out.append(img)
	return out

## Vantage render beside the first reference photo, both 400 px tall.
func _contact_sheet(id: String) -> void:
	var refs := _refs(id)
	var shot := Image.load_from_file(_out.path_join("%s_vantage.jpg" % id))
	if refs.is_empty() or shot == null:
		return
	var ref: Image = refs[0]
	for img in [shot, ref]:
		var im := img as Image
		im.resize(int(im.get_width() * 400.0 / im.get_height()), 400, Image.INTERPOLATE_BILINEAR)
	var sheet := Image.create(shot.get_width() + ref.get_width() + 8, 400, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i.ZERO)
	sheet.blit_rect(ref, Rect2i(Vector2i.ZERO, ref.get_size()), Vector2i(shot.get_width() + 8, 0))
	sheet.save_jpg(_out.path_join("%s_sheet.jpg" % id), 0.88)

func _write_stats() -> void:
	_write_json("stats.json", _stats)

func _write_json(file_name: String, value: Variant) -> void:
	var f := FileAccess.open(_out.path_join(file_name), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(value, "  "))

## Every StandardMaterial3D drawn under `root`: mean linear albedo
## (albedo colour × the albedo texture's mean, Rec.709 luma) and how
## many surfaces or instances use it, most-used first, named from the
## material caches and flagged against ALBEDO_RANGES. Vertex colours
## (WallVariety foot shading) and ShaderMaterials are not included.
static func albedo_audit(root: Node) -> Array:
	var names := _material_names()
	var uses := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		var mesh: Mesh = null
		var weight := 1
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			mesh = (n as MultiMeshInstance3D).multimesh.mesh
			weight = (n as MultiMeshInstance3D).multimesh.instance_count
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var m: Material = (n as GeometryInstance3D).material_override
			if m == null and n is MeshInstance3D:
				m = (n as MeshInstance3D).get_surface_override_material(s)
			if m == null:
				m = mesh.surface_get_material(s)
			if m is BaseMaterial3D:
				var id := m.get_instance_id()
				if not uses.has(id):
					uses[id] = [m, 0]
				uses[id][1] = int(uses[id][1]) + weight
	var means := {}
	var rows: Array = []
	for id in uses:
		var m: BaseMaterial3D = uses[id][0]
		var c := m.albedo_color.srgb_to_linear()
		if m.albedo_texture != null:
			var rid := m.albedo_texture.get_rid()
			if not means.has(rid):
				means[rid] = _texture_mean(m.albedo_texture)
			var t: Color = means[rid]
			c = Color(c.r * t.r, c.g * t.g, c.b * t.b)
		var luma := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
		var label := str(names.get(id, m.resource_name if m.resource_name != "" else "unnamed"))
		var row := {"material": label, "uses": uses[id][1], "albedo": snappedf(luma, 0.001),
			"rgb": [snappedf(c.r, 0.001), snappedf(c.g, 0.001), snappedf(c.b, 0.001)]}
		for cls in ALBEDO_RANGES:
			if label.to_lower().contains(cls):
				var r: Array = ALBEDO_RANGES[cls]
				row["class"] = cls
				if luma < float(r[0]) or luma > float(r[1]):
					row["outlier"] = "%s range %.2f–%.2f" % [cls, float(r[0]), float(r[1])]
				break
		rows.append(row)
	rows.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x["uses"]) > int(y["uses"]))
	return rows

## Material instance id -> "<cache>:<key>" over the shared material
## caches (PBR sets, facades, roofs, glass, ground storeys).
static func _material_names() -> Dictionary:
	var out := {}
	var caches := {"pbr": MaterialLibrary._pbr_mats, "facade": FacadeMaterials._facade_cache, "ground_storey": FacadeMaterials._ground_cache,
		"distant": FacadeMaterials._distant_mats, "distant_roof": FacadeMaterials._distant_roof_mats,
		"glass": FacadeMaterials._glass_mats, "roof": FacadeMaterials._roof_mats}
	for cache in caches:
		var d: Dictionary = caches[cache]
		for k in d:
			var v: Variant = d[k]
			for m in (v as Array if v is Array else [v]):
				if m is Material:
					out[(m as Material).get_instance_id()] = "%s:%s" % [cache, str(k)]
	return out

## Mean linear colour of a texture's pixels (sRGB decoded), sampled on
## a grid of at most 64 × 64.
static func _texture_mean(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img == null:
		return Color.WHITE
	if img.is_compressed():
		img.decompress()
	var step := maxi(1, maxi(img.get_width(), img.get_height()) / 64)
	var sum := Color(0, 0, 0)
	var n := 0
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var p := img.get_pixel(x, y).srgb_to_linear()
			sum = Color(sum.r + p.r, sum.g + p.g, sum.b + p.b)
			n += 1
	return Color(sum.r / n, sum.g / n, sum.b / n) if n > 0 else Color.WHITE
