extends SceneTree

## Windowed only: godot --script tests/screenshot_test.gd
## Captures every screen at phone, tablet, and desktop sizes so the
## responsive layouts can be compared against the prototype mockups.
## Add -- --offline-osm to exercise existing map caches during an outage.
## Add -- --golden-yaws for the 3D acceptance loop: each 360 view is
## reset to its spawn golden hour + Clear weather, then captured at
## the spawn look and 4 absolute yaws, so runs compare against each
## other instead of the live clock and weather.
## Add -- --tier-sweep instead for Phase 6: the Eiffel and Paris views,
## each once per preset and staged identically, to judge tier
## separation (AC-12).

## A cold build of a dense city takes about a minute on a loaded machine.
const VIEW_TIMEOUT_S := 180.0

var _shot_dir := ""

func _init() -> void:
	_run()

func _snap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	img.save_png(_shot_dir.path_join("%s.png" % name))
	print("SHOT ", name, " ", img.get_size())

func _resize(w: int, h: int) -> void:
	root.size = Vector2i(w, h)
	await process_frame
	await process_frame

func _wait_view(main: Node, timeout_sec: float) -> bool:
	var start := Time.get_ticks_msec()
	while (main._generating or not main._view.visible) \
			and Time.get_ticks_msec() - start < int(timeout_sec * 1000.0):
		await process_frame
	if main._generating or not main._view.visible:
		printerr("SCREENSHOT FAIL: no completed viewer after %s s" % timeout_sec)
		return false
	return true

## Names the Overpass query would return around Interlaken, injected so the
## shots need no request; the mini-map's tiles and the view's own data still
## come from the cache or the network like the rest of this run.
func _alpine_names() -> Array:
	var sites: Array = []
	for row in [["Eiger", "Peak", 46.5775, 8.0053, 3967.0], ["Mönch", "Peak", 46.5586, 7.9971, 4107.0],
			["Jungfrau", "Peak", 46.5367, 7.9626, 4158.0], ["Schynige Platte", "Peak", 46.6495, 7.9078, 1967.0],
			["Niesen", "Peak", 46.6459, 7.6513, 2362.0], ["Interlaken", "Town", 46.6863, 7.8632, -1.0],
			["Thun", "City", 46.7580, 7.6280, -1.0], ["Brienz", "Village", 46.7545, 8.0384, -1.0],
			["Brienzersee", "Lake", 46.7300, 7.9700, -1.0]]:
		sites.append({"name": row[0], "kind": row[1], "lat": row[2], "lon": row[3], "ele_m": row[4]})
	return sites

## Viewer tools over the alpine view: names on the skyline, the mini-map,
## the date sheet and a stamped photo. UiPrefs are set directly (not via the
## HUD buttons) so the run never saves them to the real settings.
func _viewer_tools(main: Node) -> void:
	var view: View360 = main._view
	view._horizon._on_sites(_alpine_names())
	view._horizon.set_enabled(true)
	UiPrefs.horizon_labels = true
	UiPrefs.minimap = true
	ViewChrome.layout(view)
	ViewTools.toggle_date(view)
	await _resize(1280, 800)
	await create_timer(2.0).timeout  # mini-map tiles
	await _snap("07-viewer-tools-desktop")
	await _resize(390, 844)
	await create_timer(1.0).timeout
	await _snap("07b-viewer-tools-phone")
	ViewTools.toggle_date(view)
	var img := view.snapshot()
	if img != null:
		var lines := PhotoMode.stamp_lines(view._data.place_name, view._data.latitude,
			view._data.longitude, UiTheme.clock(view._time_hour), "", HudParts.short_sources(view._data.attribution))
		var stamped := await PhotoMode.stamped(view, img, lines)
		stamped.save_png(_shot_dir.path_join("07c-photo-stamped.png"))
		print("SHOT 07c-photo-stamped ", stamped.get_size(), " raw ", img.get_size())
	view._horizon.set_enabled(false)
	UiPrefs.horizon_labels = false
	UiPrefs.minimap = false
	ViewChrome.layout(view)

## Deterministic 3D capture: the app's own spawn golden hour (undoing
## any earlier set_time_of_day in this run) + Clear weather (index 1),
## settled, HUD hidden for clean judging frames, then the spawn look
## and 4 absolute yaws at desktop size. The HUD is restored after so
## later steps (viewer tools, history) capture normally.
func _stage_look(main: Node) -> void:
	var view: View360 = main._view
	ViewConditions.spawn_golden_hour(view)
	ViewConditions.pick_weather(view, 1)
	await create_timer(1.5).timeout
	await _resize(1280, 800)

func _golden_yaws(main: Node, tag: String) -> void:
	var view: View360 = main._view
	await _stage_look(main)
	view._hud.visible = false
	await _snap("%s-spawn" % tag)
	for i in 4:
		view._rig.set_look(float(i) * PI * 0.5, -0.08)
		await create_timer(0.5).timeout
		await _snap("%s-yaw%d" % [tag, i * 90])
	view._hud.visible = true

## Tier separation (Phase 6): a view rebuilt at each preset (the world
## cache is preset-keyed, so each tier builds fresh), staged
## identically, spawn look only. Side-by-side the tiers must differ
## only in the tier columns (AC-12). Two subjects: the Eiffel landmark
## view, and the Paris-centre view. (The Paris subject was added hoping
## its bundled OSM far layer would show Fast's true face in an
## Overpass outage; empirically the fetchers prefer the user cache, so
## Fast still needs live data for its far field — see the plan.)
func _tier_sweep(main: Node, lat: float, lon: float, tag: String) -> void:
	for p in 4:
		main._settings.set_preset(p)
		main._apply_preset(p)
		main._start_generation(lat, lon)
		if not await _wait_view(main, VIEW_TIMEOUT_S):
			return
		await _stage_look(main)
		main._view._hud.visible = false
		await _snap("%s-tier-%s-spawn" % [tag, RenderSettings.PRESET_NAMES[p].to_lower()])
		main._view._hud.visible = true

func _maybe_golden_yaws(main: Node, tag: String) -> void:
	if OS.get_cmdline_user_args().has("--golden-yaws"):
		await _golden_yaws(main, tag)

func _run() -> void:
	var test_id := str(OS.get_process_id())
	CacheStore.eviction_suppressed = true
	_shot_dir = "user://shots/screenshot-test-" + test_id
	CacheStore.history_override = "user://screenshot-test-history-" + test_id + ".json"
	PlaceThumb.dir_override = "user://screenshot-test-thumbs-" + test_id
	RenderSettings.path_override = "user://screenshot-test-settings-" + test_id + ".json"
	WorldCache.dir_override = "user://screenshot-test-worlds-" + test_id
	# The app starts full screen (display/window/size/mode); this tool
	# drives window sizes itself, so opt back out to windowed first.
	# Otherwise the resizes below only resize the viewport inside a
	# full-screen window instead of sizing the actual window.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# Isolated empty history triggers first-launch onboarding. These shots
	# target the picker and viewer underneath it, without saving user prefs.
	for child in main.get_children():
		if child is OnboardingScreen:
			child.queue_free()
	if OS.get_cmdline_user_args().has("--offline-osm"):
		main._pipeline._osm.offline_mode = true
		main._pipeline._farcity.offline_mode = true
	if OS.get_cmdline_user_args().has("--tier-sweep"):
		await _tier_sweep(main, 48.8584, 2.2945, "08")
		await _tier_sweep(main, 48.8566, 2.3522, "09")
		print("SHOTS DONE -> ", ProjectSettings.globalize_path(_shot_dir))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CacheStore.history_override))
		quit(0)
		return
	await _resize(390, 844)
	await create_timer(0.5).timeout
	await _resize(390, 844)  # first resize can be lost to window creation
	await create_timer(5.0).timeout  # let picker tiles arrive
	await _snap("01-picker-phone")
	# Setting LineEdit.text from code emits no signal, so drive the same
	# handler a real keystroke would.
	main._picker._search.text = "par"
	main._picker._on_search_text_changed("par")
	await process_frame
	await _snap("01d-picker-predictions")
	main._picker._search.text = ""
	await _resize(834, 1112)
	await _snap("01b-picker-tablet")
	await _resize(1280, 800)
	await _snap("01c-picker-desktop")
	await _resize(390, 844)
	main._start_generation(48.8566, 2.3522)
	await create_timer(0.8).timeout
	await _snap("02-loading-phone")
	await _resize(1280, 800)
	await _snap("02b-loading-desktop")
	if not await _wait_view(main, VIEW_TIMEOUT_S):
		quit(1)
		return
	await create_timer(0.5).timeout
	await _resize(390, 844)
	await _snap("03-view360-phone")
	await _resize(1280, 800)
	await _snap("03b-view360-desktop")
	await _maybe_golden_yaws(main, "03c-paris")
	# Second golden location: alpine terrain at golden hour.
	main._view.set_time_of_day(17)
	main._start_generation(46.6863, 7.8632)
	if not await _wait_view(main, VIEW_TIMEOUT_S):
		quit(1)
		return
	main._view.set_time_of_day(17)
	main._view._rig.set_look(-1.57, -0.04)  # face the Brienz valley ranges
	await create_timer(0.5).timeout
	await _resize(390, 844)
	await _snap("05-view360-interlaken-phone")
	await _resize(1280, 800)
	await _snap("05b-view360-interlaken-desktop")
	await _maybe_golden_yaws(main, "05c-interlaken")
	await _viewer_tools(main)
	# Landmark viewpoint: the Eiffel Tower at its real coordinates.
	main._start_generation(48.8584, 2.2945)
	if not await _wait_view(main, VIEW_TIMEOUT_S):
		quit(1)
		return
	main._view.set_time_of_day(17)
	await create_timer(0.5).timeout
	await _resize(1280, 800)
	await _snap("06-view360-eiffel-desktop")
	await _maybe_golden_yaws(main, "06b-eiffel")
	# History at phone and desktop (Paris was just recorded by the flow).
	await _resize(390, 844)
	main._history.refresh()
	main._show(main._history)
	await _snap("04-history-phone")
	await _resize(1280, 800)
	await _snap("04b-history-desktop")
	print("SHOTS DONE -> ", ProjectSettings.globalize_path(_shot_dir))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CacheStore.history_override))
	quit(0)
