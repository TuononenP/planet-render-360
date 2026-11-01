extends Control

## Screen manager: MapPicker -> Loading -> View360, plus History.
## Godot owns all UI and rendering; no Flutter, no backend, no paywall.

var _picker: MapPicker
var _loading: LoadingScreen
var _view: View360
var _notice: DataNotice
var _history: HistoryScreen
var _settings_screen: SettingsScreen
## Where Settings' back button returns (the map, or the viewer when
## its attribution opened Data sources).
var _settings_from: Control
var _pipeline: GenerationPipeline
var _store: CacheStore
var _settings: RenderSettings
var _pending: Vector2 = Vector2(48.8566, 2.3522)
## Landmark the pending run faces (LandmarkVisit site), {} for none.
var _pending_focus: Dictionary = {}
## Saved camera or shared link the pending run reopens, {} for none.
var _pending_view: Dictionary = {}
## The view's look (View360.look_key) when its History picture was last
## taken: leaving an unchanged view skips the read-back and the encode.
var _thumb_key: Array = []
var _downloader: OfflineDownloader
var _download_at := Vector2.ZERO
## Bumped per generation and on cancel, so a world still building on
## its thread is dropped once superseded.
var _gen_id := 0
var _building_world := false
## Stop request of the world build in progress; null when none is ours.
var _build_abort: BuildAbort = null
## Longest the picker stays on "Finishing…" after a stop request. One
## build stage can run much longer (or never return), and must not lock
## Explore for good; its late result is discarded.
const ABORT_GRACE_S := 20.0
var abort_grace_s := ABORT_GRACE_S  # tests shorten it
## True from _start_generation until the view is shown or the run is
## cancelled and drained. A second start while busy would run two
## pipeline/build threads over shared static caches and can stall
## the world build, so starts are ignored until this clears (or until
## ABORT_GRACE_S after a stop request, the one accepted exception).
var _generating := false
## Longest a place may take (fetch + world build) before the run is
## stopped and the user is told, so a pathological area can never leave
## the loading screen up for good.
const GENERATION_TIMEOUT_S := 600.0
const TIMEOUT_MESSAGE := "Stopped after 10 minutes: this place took too long to build. Try a spot nearby."
var generation_timeout_s := GENERATION_TIMEOUT_S  # tests shorten it
## Longest quitting waits for the view's build and cache-save threads
## (a large city's save takes over ten seconds) before quitting anyway.
const QUIT_WAIT_S := 30.0
const CLOSING_TITLE := "Saving this place for next time"
const CLOSING_MESSAGE := "Closing as soon as it's saved."
var _quitting := false

func _fit_content_scale() -> void:
	var win := get_window()
	win.content_scale_factor = Responsive.content_scale_factor(Vector2(win.size))

func _ready() -> void:
	# Before anything reads user://: bring the data across from Godot's
	# default user directory the first time the app runs from its own.
	UserDirMigration.run()
	_store = CacheStore.new()
	_store.load_store()
	_settings = RenderSettings.new()
	_settings.load_settings()
	# Theme, units and accessibility, then the saved accent, so every
	# screen is built in them.
	UiPrefs.apply(_settings)
	UiTheme.apply_palette(_settings.accent)
	UiTheme.auto_mode = _settings.accent_auto
	theme = UiTheme.base_theme()
	get_window().size_changed.connect(_fit_content_scale)
	_fit_content_scale()
	# The window's close button and the app menu's Quit come through
	# _request_exit too, so a world still saving is waited for there.
	get_tree().auto_accept_quit = false
	_pipeline = GenerationPipeline.new()
	add_child(_pipeline)
	_pipeline.stage_changed.connect(
		func(i: int, label: String, state: String) -> void:
			_loading.set_stage(i, label, state))
	_pipeline.progress_changed.connect(
		func(f: float, label: String) -> void: _loading.set_progress(f, label))
	_pipeline.stage_progress.connect(func(i: int, done: int, total: int) -> void:
		_loading.set_stage_progress(i, done, total))
	_pipeline.stage_took.connect(func(i: int, seconds: float) -> void:
		_loading.set_stage_took(i, seconds))
	_pipeline.finished.connect(_on_generation_finished)
	_pipeline.layer_detail.connect(func(layer: String, detail: String, partial: bool) -> void:
		_loading.set_layer_detail(layer, detail, partial))
	_pipeline.degraded_layer.connect(func(layer: String) -> void: _loading.add_degraded(layer))
	_pipeline.stage_data.connect(func(i: int, d: LocationData) -> void: _loading.show_stage_data(i, d))
	_pipeline.cancelled.connect(func() -> void:
		_set_generating(false)
		_show(_picker))

	_picker = MapPicker.new()
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker.render_requested.connect(func(lat: float, lon: float) -> void:
		# A selected landmark is seen from its standoff, not stood on.
		var site := _picker.selected_landmark
		if site.is_empty():
			_start_generation(lat, lon)
			return
		var at := LandmarkVisit.viewpoint(site, LandmarkVisit.default_bearing(lat))
		_start_generation(at.x, at.y, site))
	# A pasted "Copy view link": that exact view, whoever's it was.
	_picker.view_link_requested.connect(func(state: Dictionary) -> void:
		_picker.selected_name = ""
		_start_generation(float(state["lat"]), float(state["lon"]), {}, ViewLink.to_view(state)))
	_picker.history_requested.connect(func() -> void:
		_history.refresh()
		_show(_history))
	_picker.settings_requested.connect(func() -> void:
		_settings_from = _picker
		_show(_settings_screen))
	_downloader = OfflineDownloader.new()
	add_child(_downloader)
	_downloader.progress.connect(func(done: int, total: int) -> void:
		_picker.set_download_status("Saving… %d/%d" % [done, total]))
	_downloader.finished.connect(func(ok_count: int, total: int) -> void:
		if ok_count > 0:
			_store.add_entry(_picker.selected_name if _picker.selected_name != "" \
				else LocationData.known_place(_download_at.x, _download_at.y),
				_download_at.x, _download_at.y)
		_picker.set_download_busy(false)
		_picker.set_download_status(("Saved for offline" if ok_count == total \
			else "Partly saved (%d/%d)" % [ok_count, total]) \
			if ok_count > 0 else "Couldn't save. Try again"))
	_picker.download_requested.connect(func(lat: float, lon: float) -> void:
		if _downloader.is_running():
			return
		_picker.set_download_busy(true)
		_download_at = Vector2(lat, lon)
		_picker.set_download_status("Saving… 0/%d" % OfflineDownloader.JOBS)
		_downloader.download(lat, lon, _settings.preset))
	_picker.exit_requested.connect(_request_exit)
	add_child(_picker)
	_picker.bind_store(_store)
	_picker.set_quality_preset(_settings.preset)
	_picker.set_layout_override(_settings.layout)

	_loading = LoadingScreen.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.cancel_requested.connect(func() -> void:
		_gen_id += 1
		_pipeline.cancel()
		# Past the pipeline (world building) nothing emits cancelled.
		if _building_world:
			_show(_picker)
			_abort_build())
	add_child(_loading)

	_view = View360.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.back_requested.connect(func() -> void: _show(_picker))
	_view.data_sources_requested.connect(func() -> void:
		_settings_from = _view
		_show(_settings_screen)
		_settings_screen.show_data_sources())
	_view.data_quality_requested.connect(func() -> void: _notice.open())
	_view.pref_changed.connect(func(key: String, value: Variant) -> void:
		_settings.set_pref(key, value))
	_view.snapshot_ready.connect(func(lat: float, lon: float, image: Image) -> void:
		if PlaceThumb.save(image, lat, lon):
			_thumb_key = _view.look_key()
		# History rebuilds when it opens; only a visible one needs it now.
		if _history.visible:
			_history.refresh())
	# Go there, beyond the built area: a new scene at the landmark's standoff.
	_view.visit_requested.connect(func(site: Dictionary, lat: float, lon: float) -> void:
		if not _generating:
			_start_generation(lat, lon, site))
	add_child(_view)
	_view.set_quality_preset(_settings.preset)

	# Above the view: plain-language notice when live data did not arrive.
	_notice = DataNotice.new()
	_notice.retry_requested.connect(func() -> void:
		# Keep where the person is looking first, then reopen there.
		_leave_view()
		_start_generation(_pending.x, _pending.y, _pending_focus, _retry_view()))
	add_child(_notice)

	_history = HistoryScreen.new()
	_history.set_anchors_preset(Control.PRESET_FULL_RECT)
	_history.bind_store(_store)
	_history.back_requested.connect(func() -> void: _show(_picker))
	_history.place_selected.connect(func(lat: float, lon: float) -> void:
		if _generating:
			_history.toast("Still finishing the last scene. Try again in a moment.")
			return
		_picker.selected_name = ""
		_start_generation(lat, lon))
	add_child(_history)

	_settings_screen = SettingsScreen.new()
	_settings_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_screen.bind_settings(_settings)
	_settings_screen.back_requested.connect(func() -> void:
		_show(_settings_from if _settings_from != null else _picker))
	AccentSun.refresh = _refresh_accent
	_settings_screen.accent_changed.connect(func(_i: int) -> void:
		var at := _picker.selected_point()
		AccentSun.follow_now(at.x, at.y)
		_refresh_accent())
	_settings_screen.units_changed.connect(func() -> void: _picker.refresh_units())
	_settings_screen.layout_changed.connect(func(i: int) -> void:
		_picker.set_layout_override(i))
	_settings_screen.preset_changed.connect(func(p: int) -> void:
		_picker.set_quality_preset(p)
		_view.set_quality_preset(p))
	add_child(_settings_screen)

	_show(_picker)
	# First launch only (nothing visited, never onboarded): three screens
	# over the turning globe, ending on the map with search focused.
	if _store.entries.is_empty() and not bool(_settings.pref("onboarded")):
		var onboarding := OnboardingScreen.new()
		onboarding.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(onboarding)
		onboarding.finished.connect(func() -> void:
			_settings.set_pref("onboarded", true)
			onboarding.queue_free()
			_picker._search.grab_focus())
	if SettingsScreen.reopen:
		# Rebuilt after a theme switch: back where the person was.
		SettingsScreen.reopen = false
		_settings_from = _picker
		_show(_settings_screen)

## Quit the app. Full screen hides the OS window controls, so the
## picker Exit button and these keys are the way out on desktop.
## A world still saving to the cache (or building) is waited for with
## frames running, at most QUIT_WAIT_S: joining it in the view's
## teardown blocks the main thread for seconds and macOS shows the
## busy cursor.
func _request_exit() -> void:
	if _quitting:
		return
	_quitting = true
	_leave_view()
	if _build_abort != null:
		_build_abort.requested = true
	if _view.has_running_threads():
		_say_closing()
		var deadline := Time.get_ticks_msec() + int(QUIT_WAIT_S * 1000.0)
		while _view.has_running_threads() and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
	CacheStore.flush_lru()
	get_tree().quit()

func _say_closing() -> void:
	if _view.visible:
		ViewTools.say(_view, CLOSING_TITLE, CLOSING_MESSAGE, "neutral")
	elif _picker.visible:
		_picker._toast.show_message(CLOSING_TITLE, CLOSING_MESSAGE)
		MapHome.place_toast(_picker)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_exit()

## Ctrl/Cmd+Q quits anywhere. Esc steps back one screen (the viewer,
## History and Settings return to the map, a Settings page on phones
## returns to its menu, loading cancels) and quits
## only from the map itself.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_Q and (key.ctrl_pressed or key.meta_pressed):
			_request_exit()
		elif key.keycode == KEY_ESCAPE:
			if _picker.visible:
				_request_exit()
			elif _loading.visible:
				_loading.cancel_requested.emit()
			elif _settings_screen.visible and _settings_screen.step_back():
				pass
			elif _settings_screen.visible and _settings_from != null:
				_show(_settings_from)
			else:
				_show(_picker)
		else:
			return
		get_viewport().set_input_as_handled()

## Re-skin every screen after the accent moved (a pick, or the sun).
func _refresh_accent() -> void:
	_picker.refresh_theme()
	_view.refresh_theme()
	_notice.refresh_theme()
	_loading.refresh_theme()
	_history.refresh()
	_settings_screen.refresh_theme()

## Leaving the viewer: History keeps where the person was looking and the
## picture of it, so reopening the place restores both.
func _leave_view() -> void:
	if _view == null or not _view.visible:
		return
	var state := _view.camera_state()
	if state.is_empty():
		return
	_store.set_camera(float(state["lat"]), float(state["lon"]), state)
	# The picture costs a full-size read-back and an encode: only when the
	# view changed since the last one.
	var key := _view.look_key()
	if key != _thumb_key and PlaceThumb.save(_view.snapshot(), float(state["lat"]), float(state["lon"])):
		_thumb_key = key

## What Try again reopens: the camera the person was last at (saved on
## leaving), keeping the time, season and date a shared link carried. A
## landmark visit reopens as it was asked for.
func _retry_view() -> Dictionary:
	if not _pending_focus.is_empty():
		return _pending_view
	var camera := _store.camera_for(_pending.x, _pending.y)
	if camera.is_empty():
		return _pending_view
	var view := _pending_view.duplicate()
	view.erase("eye_lat")
	view.erase("eye_lon")
	view.merge(ViewLink.to_view(camera), true)
	return view

func _show(screen: Control) -> void:
	if screen != _view:
		_leave_view()
	for s in [_picker, _loading, _view, _history, _settings_screen]:
		s.visible = s == screen
	if screen == _picker:
		_picker.refresh_recent()
	_notice.set_on_screen(screen == _view)
	if screen != _view:
		var at := _picker.selected_point()
		AccentSun.follow_now(at.x, at.y)

func _set_generating(busy: bool) -> void:
	_generating = busy
	_picker.set_render_busy(busy)

func _start_generation(lat: float, lon: float, focus: Dictionary = {},
		view: Dictionary = {}) -> void:
	if _generating:
		print("Generation already in progress; ignoring start")
		return
	# Reopening a place restores where the person last looked.
	if view.is_empty() and focus.is_empty():
		var camera := _store.camera_for(lat, lon)
		if not camera.is_empty():
			view = ViewLink.to_view(camera)
	_set_generating(true)
	_gen_id += 1
	var gen := _gen_id
	_arm_timeout(gen)
	_picker.set_render_status("")
	_pending = Vector2(lat, lon)
	_pending_focus = focus
	_pending_view = view
	var display_name := str(focus.get("name", _picker.selected_name)) if not focus.is_empty() \
		else _picker.selected_name
	if display_name == "":
		display_name = LocationData.known_place(lat, lon)
	_loading.begin(display_name, lat, lon, _settings.preset)
	_notice.clear()
	_show(_loading)
	# run() starts every fetcher synchronously (cached satellite tiles
	# decode inline), which would freeze the picker on screen. Let the
	# loading screen draw first.
	await get_tree().process_frame
	await get_tree().process_frame
	if gen != _gen_id:
		_set_generating(false)
		_show(_picker)
		return
	_pipeline.run(lat, lon, display_name if not focus.is_empty() else _picker.selected_name,
		_settings.preset, focus, view)

## Stops generation `gen` if it is still running after
## generation_timeout_s: cancels the fetch, asks a world build to stop at
## its next stage, and returns to the picker with a plain message.
func _arm_timeout(gen: int) -> void:
	await get_tree().create_timer(generation_timeout_s).timeout
	if not _generating or gen != _gen_id:
		return
	print("Generation timed out after %d s" % int(generation_timeout_s))
	_gen_id += 1
	_pipeline.cancel()
	_show(_picker)
	_picker.set_render_status(TIMEOUT_MESSAGE)
	if _building_world:
		_abort_build()

## Asks the world build in progress to stop at its next stage and shows
## "Finishing…" until it does, or until ABORT_GRACE_S at the latest: a
## stage that never returns must not leave Explore disabled for good.
## A build released this way winds down on its own thread.
func _abort_build() -> void:
	var abort := _build_abort
	if abort == null:
		return
	abort.requested = true
	_picker.set_render_busy(true, true)
	await get_tree().create_timer(abort_grace_s).timeout
	if _build_abort == abort:
		_release_build()

func _release_build() -> void:
	_build_abort = null
	_building_world = false
	_set_generating(false)

func _on_generation_finished(data: LocationData) -> void:
	var gen := _gen_id
	var abort := BuildAbort.new()
	_loading.set_building(abort)
	_building_world = true
	_build_abort = abort
	# GroundTruth was built while the far-city and climate stages waited.
	var ground: GroundTruth = await _pipeline.ground_for(data)
	var built := await _view.build_location(data, ground, abort)
	# A build the grace period already released must not touch the
	# state of a newer run.
	if _build_abort == abort:
		_release_build()
	if gen != _gen_id:
		return
	_store.add_entry(data.place_name, data.latitude, data.longitude)
	_view.show_location(data, built)
	_notice.show_notes(data.data_notes)
	_show(_view)
	ViewChrome.arrive(_view)
