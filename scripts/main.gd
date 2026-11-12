extends Control

## Screen manager: MapPicker -> Loading -> View360, plus History.
## Godot owns all UI and rendering; no Flutter, no backend, no paywall.

var _picker: MapPicker
var _loading: LoadingScreen
var _view: View360
var _notice: DataNotice
var _history: HistoryScreen
var _gallery: GalleryScreen
var _pano_viewer: PanoramaViewer
var _settings_screen: SettingsScreen
## Where Settings' back button returns (the map, or the viewer when
## its attribution opened Data sources).
var _settings_from: Control
var _pipeline: GenerationPipeline
var _store: CacheStore
## Automated visual reviews use the real pipeline without changing History
## or its thumbnails, including when another app instance is open.
var capture_mode := false
var _settings: RenderSettings
var _pending: Vector2 = Vector2(48.8566, 2.3522)
## Landmark the pending run faces (LandmarkVisit site), {} for none.
var _pending_focus: Dictionary = {}
## Saved camera or shared link the pending run reopens, {} for none.
var _pending_view: Dictionary = {}
## The view's look (View360.look_key) when its History picture was last
## taken: leaving an unchanged view skips the read-back and the encode.
var _thumb_key: Array = []
## True while Save for offline runs the generation and world build
## without showing the place, so a later Explore loads the finished world.
var _saving := false
var _save_progress := SaveProgress.new()
var _save_osm_pack: OfflineOsmPack
var _save_osm_complete := true
var _save_retry_data: LocationData
var _save_retry_degraded: Array[String] = []
var _save_degraded: Array[String] = []
var _save_retry_done := false
var _save_retry_in_progress := false
## Room for one layer to fail on both silent first mirrors (2 x
## OverpassRequest.FIRST_BYTE_TIMEOUT) and the others to arrive from the rest.
const SAVE_OSM_BUDGET_S := 150.0
const SAVE_BUILD_RESERVE_S := 60.0
const SAVE_RETRY_RESERVE_S := 180.0
var _generation_deadline_ms := 0
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
const SAVING := "Saving… %d%%"
const SAVE_DONE := "Saved for offline"
const SAVE_PARTLY := "Partly saved · retry"
const SAVE_FAILED := "Couldn't save. Try again"
const SAVE_WORLD_FAILED := "Couldn't save the view · retry"
const CLOSING_TITLE := "Saving this place for next time"
const CLOSING_MESSAGE := "Closing as soon as it's saved."
var _quitting := false

const SAFE_POLL_S := 0.25
var _safe_seen: Array[float] = []

## A half turn keeps the window's size, so no resize says the notch moved
## to the other side: each screen is told to lay out again when it does.
func _check_safe_area() -> void:
	var safe := Responsive.safe_insets(self)
	if safe == _safe_seen:
		return
	_safe_seen = safe
	for child in get_children():
		if child is Control:
			(child as Control).resized.emit()

func _fit_content_scale() -> void:
	var win := get_window()
	win.content_scale_factor = Responsive.content_scale_factor(Vector2(win.size), Responsive.points_scale())

func _ready() -> void:
	# Before anything reads user://: bring the data across from Godot's
	# default user directory the first time the app runs from its own.
	UserDirMigration.run()
	# Temp files of writes a kill cut short: gone before the cache is indexed.
	AtomicFile.sweep_stale("user://")
	AtomicFile.sweep_stale(CacheStore.base_dir())
	# Service addresses from the last fetch; the refresh below updates them
	# for the next launch and for requests not yet made.
	RemoteConfig.load_cached()
	CacheStore.preload_index()
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
	_safe_seen = Responsive.safe_insets(self)
	if OS.has_feature("mobile"):
		var safe_poll := Timer.new()
		safe_poll.wait_time = SAFE_POLL_S
		safe_poll.autostart = true
		safe_poll.timeout.connect(_check_safe_area)
		add_child(safe_poll)
	# The window's close button and the app menu's Quit come through
	# _request_exit too, so a world still saving is waited for there.
	get_tree().auto_accept_quit = false
	_pipeline = GenerationPipeline.new()
	add_child(_pipeline)
	var remote_config := RemoteConfig.new()
	add_child(remote_config)
	remote_config.refresh()
	_pipeline.stage_changed.connect(
		func(i: int, label: String, state: String) -> void:
			_loading.set_stage(i, label, state)
			# The pipeline reports its overall fraction only at the end; a
			# save follows its rows finishing instead.
			if _saving and not _save_retry_in_progress and state == "done":
				_save_progress.rows_done += 1
				if i == 1:
					_save_progress.imagery_fraction = 0.0)
	_pipeline.progress_changed.connect(
		func(f: float, label: String) -> void: _loading.set_progress(f, label))
	_pipeline.stage_progress.connect(func(i: int, done: int, total: int) -> void:
		_loading.set_stage_progress(i, done, total)
		if _saving and not _save_retry_in_progress and i == 1 and total > 0:
			_save_progress.imagery_fraction = clampf(float(done) / total, 0.0, 1.0))
	_pipeline.stage_took.connect(func(i: int, seconds: float) -> void:
		_loading.set_stage_took(i, seconds))
	_pipeline.finished.connect(_on_generation_finished)
	_pipeline.layer_detail.connect(func(layer: String, detail: String, partial: bool) -> void:
		_loading.set_layer_detail(layer, detail, partial))
	_pipeline.degraded_layer.connect(func(layer: String) -> void: _loading.add_degraded(layer))
	_pipeline.stage_data.connect(func(i: int, d: LocationData) -> void: _loading.show_stage_data(i, d))
	_pipeline.cancelled.connect(func() -> void:
		_set_generating(false)
		if _saving:
			_end_save(SAVE_FAILED)
		_show(_picker))

	_picker = MapPicker.new()
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker.render_requested.connect(func(lat: float, lon: float) -> void:
		var target := _explore_target(lat, lon)
		_start_generation(target["at"].x, target["at"].y, target["site"]))
	# A pasted "Copy view link": that exact view, whoever's it was.
	_picker.view_link_requested.connect(func(state: Dictionary) -> void:
		_picker.selected_name = ""
		_start_generation(float(state["lat"]), float(state["lon"]), {}, ViewLink.to_view(state)))
	_picker.history_requested.connect(func() -> void:
		_history.refresh()
		_show(_history))
	_picker.gallery_requested.connect(func() -> void:
		_gallery.refresh()
		_show(_gallery))
	_picker.settings_requested.connect(func() -> void:
		_settings_from = _picker
		_show(_settings_screen))
	# Save for offline runs the same generation and world build as
	# Explore, so the place it leaves behind opens without either.
	_picker.download_requested.connect(func(lat: float, lon: float) -> void:
		var target := _explore_target(lat, lon)
		_start_generation(target["at"].x, target["at"].y, target["site"], {}, true))
	_picker.exit_requested.connect(_request_exit)
	add_child(_picker)
	_picker.bind_store(_store)
	_picker.set_quality_preset(_settings.preset)
	_picker.quality_selected.connect(func(p: int) -> void:
		_settings.set_preset(p)
		_apply_preset(_settings.preset)
		_settings_screen.bind_settings(_settings))
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
		if capture_mode:
			return
		_store_thumb(image, lat, lon, _view.look_key(), true))
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

	_gallery = GalleryScreen.new()
	_gallery.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gallery.back_requested.connect(func() -> void: _show(_picker))
	_gallery.panorama_selected.connect(func(entry: Dictionary) -> void:
		if _pano_viewer.open(entry):
			_show(_pano_viewer)
		else:
			# open() fails only when the file is gone: drop its stale card.
			_gallery.refresh()
			_gallery.toast("Couldn't find this photo", "It is no longer on this device.", "error"))
	add_child(_gallery)
	_history.gallery_requested.connect(func() -> void:
		_gallery.refresh()
		_show(_gallery))

	_pano_viewer = PanoramaViewer.new()
	_pano_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pano_viewer.back_requested.connect(func() -> void:
		_pano_viewer.close()
		_gallery.refresh()
		_show(_gallery))
	_pano_viewer.deleted.connect(func(_entry: Dictionary) -> void:
		_gallery.refresh()
		_show(_gallery))
	_pano_viewer.open_failed.connect(func(_entry: Dictionary) -> void:
		_show(_gallery)
		_gallery.toast("Couldn't open this photo", "The file may be damaged. It stays in Gallery so you can delete it.", "error"))
	add_child(_pano_viewer)

	_settings_screen = SettingsScreen.new()
	_settings_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_screen.bind_settings(_settings)
	_settings_screen.bind_store(_store)
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
	_settings_screen.preset_changed.connect(_apply_preset)
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
	if _save_osm_pack != null:
		_save_osm_pack.cancel()
	WorldCache.hurry = true
	_leave_view()
	if _build_abort != null:
		_build_abort.requested = true
	# Cache scans stop early; the index still gets its last write.
	CacheStore.stop_scans = true
	if _view.has_running_threads():
		_say_closing()
	var deadline := Time.get_ticks_msec() + int(QUIT_WAIT_S * 1000.0)
	while (_view.has_running_threads() or CacheStore.busy()) \
			and Time.get_ticks_msec() < deadline:
		CacheStore.flush_lru()
		await get_tree().process_frame
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

## The open confirmation veil (SettingsRows.confirm), if any, among the
## screens: Esc closes it instead of navigating.
func _find_modal() -> Control:
	for s in [_picker, _loading, _view, _history, _gallery, _pano_viewer, _settings_screen]:
		if s == null:
			continue
		for child in s.get_children():
			if child.name == "confirm_veil":
				return child
	return null

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
			# An open confirmation sheet consumes Esc first.
			var modal := _find_modal()
			if modal != null:
				modal.queue_free()
			elif _picker.visible:
				_request_exit()
			elif _loading.visible:
				_loading.cancel_requested.emit()
			elif _pano_viewer.visible:
				_pano_viewer.back_requested.emit()
			elif _gallery.visible:
				_show(_picker)
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
	if _gallery != null:
		_gallery.refresh_theme()
	_settings_screen.refresh_theme()

## Leaving the viewer: History keeps where the person was looking and the
## picture of it, so reopening the place restores both.
func _leave_view() -> void:
	if capture_mode or _view == null or not _view.visible:
		return
	var state := _view.camera_state()
	if state.is_empty():
		return
	_store.set_camera(float(state["lat"]), float(state["lon"]), state)
	# The picture costs a full-size read-back and an encode: only when the
	# view changed since the last one.
	var key := _view.look_key()
	if key != _thumb_key:
		_store_thumb(_view.snapshot(), float(state["lat"]), float(state["lon"]), key, false)

## Writes the History picture on a worker, so leaving the view never
## waits on the shrink and the encode. `key` is claimed at once, so the
## view's snapshot timer and leaving cannot save the same look twice; a
## failed write gives it back for the next try. Runs unawaited: the
## callers (leaving, quitting) do not wait for the picture.
func _store_thumb(image: Image, lat: float, lon: float, key: Array, refresh_history: bool) -> void:
	if image == null or image.is_empty():
		return
	if not key.is_empty():
		_thumb_key = key
	var ok := await PlaceThumb.save_async(image, lat, lon, get_tree())
	if not ok and not key.is_empty() and _thumb_key == key:
		_thumb_key = []
	# History rebuilds when it opens; only a visible one needs it now.
	if refresh_history and _history != null and _history.visible:
		_history.refresh()

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

## Push a saved render preset to the picker and the 360 view.
func _apply_preset(p: int) -> void:
	_picker.set_quality_preset(p)
	_view.set_quality_preset(p)

func _show(screen: Control) -> void:
	if screen != _view:
		_leave_view()
	for s in [_picker, _loading, _view, _history, _gallery, _pano_viewer, _settings_screen]:
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

## Where Explore goes for the picker's pin: a selected landmark is seen
## from its standoff, not stood on. {"at": Vector2(lat, lon), "site": {}}.
func _explore_target(lat: float, lon: float) -> Dictionary:
	var site := _picker.selected_landmark
	if site.is_empty():
		return {"at": Vector2(lat, lon), "site": {}}
	return {"at": LandmarkVisit.viewpoint(site, LandmarkVisit.default_bearing(lat)), "site": site}

## `save_only`: Save for offline. Runs the same pipeline and world build
## but keeps the picker up and stops at the saved world.
func _start_generation(lat: float, lon: float, focus: Dictionary = {},
		view: Dictionary = {}, save_only := false) -> void:
	if _generating:
		print("Generation already in progress; ignoring start")
		return
	# Reopening a place restores where the person last looked.
	if view.is_empty() and focus.is_empty():
		var camera := _store.camera_for(lat, lon)
		if not camera.is_empty():
			view = ViewLink.to_view(camera)
	_saving = save_only
	_save_osm_complete = true
	_save_retry_data = null
	_save_retry_degraded.clear()
	_save_degraded.clear()
	_save_retry_done = false
	_save_retry_in_progress = false
	_save_progress = SaveProgress.new()
	_save_progress.rows = GenerationPipeline.STAGES.size() + int(save_only)
	_set_generating(true)
	_gen_id += 1
	var gen := _gen_id
	_generation_deadline_ms = Time.get_ticks_msec() + int(generation_timeout_s * 1000.0)
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
	if save_only:
		_picker.set_download_busy(true)
		_follow_save(gen)
	else:
		_show(_loading)
	# run() starts every fetcher synchronously (cached satellite tiles
	# decode inline), which would freeze the picker on screen. Let the
	# loading screen draw first.
	await get_tree().process_frame
	await get_tree().process_frame
	if gen != _gen_id:
		_set_generating(false)
		if _saving:
			_end_save(SAVE_FAILED)
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
	if _save_osm_pack != null:
		_save_osm_pack.cancel()
	_pipeline.cancel()
	_show(_picker)
	if _saving:
		_end_save(SAVE_FAILED)
	else:
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

## Save for offline, second half: the world is built and written to the
## world cache exactly as Explore would, then dropped unseen.
func _save_world(data: LocationData) -> void:
	var gen := _gen_id
	var pack := OfflineOsmPack.new()
	_save_osm_pack = pack
	add_child(pack)
	pack.start(data.latitude, data.longitude)
	var deadline := mini(Time.get_ticks_msec() + int(SAVE_OSM_BUDGET_S * 1000.0),
		_generation_deadline_ms - int(SAVE_BUILD_RESERVE_S * 1000.0))
	while pack.is_running() and gen == _gen_id and not _quitting and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	pack.cancel()
	if gen != _gen_id or _quitting:
		pack.queue_free()
		if _save_osm_pack == pack:
			_save_osm_pack = null
		# Cancelled or quitting while downloading: no build is running to
		# release the busy state, and the pipeline has already finished.
		_set_generating(false)
		if _saving:
			_end_save(SAVE_FAILED)
		_show(_picker)
		return
	_save_progress.rows_done += 1
	var abort := BuildAbort.new()
	_building_world = true
	_build_abort = abort
	_save_progress.phase = SaveProgress.Phase.BUILD
	var ground: GroundTruth = await _pipeline.ground_for(data)
	var ok := true
	var world_saved := not WorldCache.enabled() or WorldCache.has_world(data)
	# Headless runs have no world cache; an already saved world is not rebuilt.
	if WorldCache.enabled() and not world_saved:
		var built := await _view.build_location(data, ground, abort, true)
		ok = not built.is_empty()
		if ok and built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		world_saved = WorldCache.has_world(data)
	if _build_abort == abort:
		_release_build()
	if gen == _gen_id:
		_save_osm_complete = pack.missing_layers().is_empty()
	pack.queue_free()
	if _save_osm_pack == pack:
		_save_osm_pack = null
	if gen != _gen_id:
		return
	if ok and world_saved:
		_store.add_entry(data.place_name, data.latitude, data.longitude, {}, data.quality_preset)
	if not ok:
		_end_save(SAVE_FAILED)
	elif not world_saved:
		_end_save(SAVE_WORLD_FAILED)
	else:
		_end_save(SAVE_DONE if _save_degraded.is_empty() and _save_osm_complete \
			and not _save_missing_data(data) else SAVE_PARTLY)

## Keeps the bar and the line under the Save button current until the
## save ends.
func _follow_save(gen: int) -> void:
	var dt := 0.1
	while _saving and gen == _gen_id:
		if _build_abort != null:
			_save_progress.build_step = _build_abort.step
			if _build_abort.saving:
				_save_progress.phase = SaveProgress.Phase.WRITE
		_save_progress.tick(dt)
		var label := "Retrying… %d%%" if _save_retry_in_progress else SAVING
		_picker.set_download_status(label % _save_progress.percent())
		_picker.set_download_progress(_save_progress.shown, _save_progress.phase_text())
		await get_tree().create_timer(dt).timeout

func _end_save(text: String) -> void:
	_saving = false
	_save_retry_data = null
	_save_retry_in_progress = false
	_picker.set_download_progress(-1.0)
	_picker.set_download_busy(false)
	_picker.set_download_status(text)

func _retry_save_pipeline(gen: int) -> void:
	if _quitting or gen != _gen_id or not _saving or _save_retry_data == null:
		return
	var data := _save_retry_data
	_pipeline.run(data.latitude, data.longitude, data.place_name, data.quality_preset,
		_pending_focus, _pending_view)

## The pipeline can use a lower-resolution fallback without marking a layer
## degraded. Retry missing requested tiles too, while reusing the cached ones.
## Land cover is optional: places without a source tile never get a file, and
## the world falls back to OSM land cover, so its absence is not a partial save.
## Neither is a tile its source answered 404 for: retrying cannot fetch it.
func _save_missing_data(data: LocationData) -> bool:
	var keys := CacheStore.place_cache_keys(data.latitude, data.longitude, data.quality_preset)
	for layer in ["dem", "sat"]:
		for path in keys.get(layer, []):
			if not FileAccess.file_exists(str(path)) and not CacheStore.is_absent(str(path)):
				return true
	return false

func _on_generation_finished(data: LocationData) -> void:
	if _saving:
		if not _save_retry_done and (not _pipeline.degraded.is_empty() or _save_missing_data(data)) \
				and Time.get_ticks_msec() + int(SAVE_RETRY_RESERVE_S * 1000.0) < _generation_deadline_ms:
			_save_retry_done = true
			_save_retry_in_progress = true
			_save_retry_data = data
			_save_retry_degraded = _pipeline.degraded.duplicate()
			_retry_save_pipeline.call_deferred(_gen_id)
			return
		_save_retry_in_progress = false
		_save_degraded = _pipeline.degraded.duplicate()
		if _save_retry_data != null and _save_retry_degraded.size() < _save_degraded.size():
			data = _save_retry_data
			_save_degraded = _save_retry_degraded.duplicate()
		_save_retry_data = null
		_save_world(data)
		return
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
	if not capture_mode:
		_store.add_entry(data.place_name, data.latitude, data.longitude, {}, data.quality_preset)
	_view.start_flying = not capture_mode
	_view._streamer.enabled = not capture_mode
	_view.show_location(data, built)
	_notice.show_notes(data.data_notes)
	_show(_view)
	ViewChrome.arrive(_view)
