extends Control

## Screen manager: MapPicker -> Loading -> View360, plus History.
## Godot owns all UI and rendering; no Flutter, no backend, no paywall.

var _picker: MapPicker
var _loading: LoadingScreen
var _view: View360
var _history: HistoryScreen
var _settings_screen: SettingsScreen
var _pipeline: GenerationPipeline
var _store: CacheStore
var _settings: RenderSettings
var _pending: Vector2 = Vector2(48.8566, 2.3522)
var _downloader: OfflineDownloader
var _download_at := Vector2.ZERO

func _ready() -> void:
	_store = CacheStore.new()
	_store.load_store()
	_settings = RenderSettings.new()
	_settings.load_settings()
	_pipeline = GenerationPipeline.new()
	add_child(_pipeline)
	_pipeline.stage_changed.connect(
		func(i: int, label: String, state: String) -> void:
			_loading.set_stage(i, label, state))
	_pipeline.progress_changed.connect(
		func(f: float, label: String) -> void: _loading.set_progress(f, label))
	_pipeline.finished.connect(_on_generation_finished)
	_pipeline.cancelled.connect(func() -> void: _show(_picker))

	_picker = MapPicker.new()
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker.render_requested.connect(_start_generation)
	_picker.history_requested.connect(func() -> void:
		_history.refresh()
		_show(_history))
	_picker.settings_requested.connect(func() -> void: _show(_settings_screen))
	_downloader = OfflineDownloader.new()
	add_child(_downloader)
	_downloader.progress.connect(func(done: int, total: int) -> void:
		_picker.set_download_status("⬇  Downloading… %d/%d" % [done, total]))
	_downloader.finished.connect(func(ok_count: int, total: int) -> void:
		if ok_count > 0:
			_store.add_entry(_picker.selected_name if _picker.selected_name != "" \
				else LocationData.known_place(_download_at.x, _download_at.y),
				_download_at.x, _download_at.y)
		_picker.set_download_status("⬇  Saved for offline (%d/%d)" % [ok_count, total] \
			if ok_count > 0 else "⬇  Download failed — check connection"))
	_picker.download_requested.connect(func(lat: float, lon: float) -> void:
		_download_at = Vector2(lat, lon)
		_picker.set_download_status("⬇  Downloading… 0/%d" % OfflineDownloader.JOBS)
		_downloader.download(lat, lon, _settings.preset))
	_picker.exit_requested.connect(_request_exit)
	add_child(_picker)
	_picker.set_quality_preset(_settings.preset)

	_loading = LoadingScreen.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.cancel_requested.connect(func() -> void: _pipeline.cancel())
	add_child(_loading)

	_view = View360.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.back_requested.connect(func() -> void: _show(_picker))
	add_child(_view)
	_view.set_quality_preset(_settings.preset)

	_history = HistoryScreen.new()
	_history.set_anchors_preset(Control.PRESET_FULL_RECT)
	_history.bind_store(_store)
	_history.back_requested.connect(func() -> void: _show(_picker))
	_history.place_selected.connect(func(lat: float, lon: float) -> void:
		_picker.selected_name = ""
		_start_generation(lat, lon))
	add_child(_history)

	_settings_screen = SettingsScreen.new()
	_settings_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_screen.bind_settings(_settings)
	_settings_screen.back_requested.connect(func() -> void: _show(_picker))
	_settings_screen.preset_changed.connect(func(p: int) -> void:
		_picker.set_quality_preset(p)
		_view.set_quality_preset(p))
	add_child(_settings_screen)

	_show(_picker)

## Quit the app. Full screen hides the OS window controls, so the
## picker Exit button and these keys are the way out on desktop.
func _request_exit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE \
				or (key.keycode == KEY_Q and (key.ctrl_pressed or key.meta_pressed)):
			_request_exit()
			get_viewport().set_input_as_handled()

func _show(screen: Control) -> void:
	for s in [_picker, _loading, _view, _history, _settings_screen]:
		s.visible = s == screen

func _start_generation(lat: float, lon: float) -> void:
	_pending = Vector2(lat, lon)
	var display_name := _picker.selected_name
	if display_name == "":
		display_name = LocationData.known_place(lat, lon)
	_loading.begin(display_name)
	_show(_loading)
	_pipeline.run(lat, lon, _picker.selected_name, _settings.preset)

func _on_generation_finished(data: LocationData) -> void:
	_store.add_entry(data.place_name, data.latitude, data.longitude)
	_view.show_location(data)
	_show(_view)
