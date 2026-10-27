extends Control

## Screen manager: MapPicker -> Loading -> View360, plus History.
## Godot owns all UI and rendering; no Flutter, no backend, no paywall.

var _picker: MapPicker
var _loading: LoadingScreen
var _view: View360
var _history: HistoryScreen
var _pipeline: GenerationPipeline
var _store: CacheStore
var _pending: Vector2 = Vector2(48.8566, 2.3522)

func _ready() -> void:
	_store = CacheStore.new()
	_store.load_store()
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
	add_child(_picker)

	_loading = LoadingScreen.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.cancel_requested.connect(func() -> void: _pipeline.cancel())
	add_child(_loading)

	_view = View360.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.back_requested.connect(func() -> void: _show(_picker))
	add_child(_view)

	_history = HistoryScreen.new()
	_history.set_anchors_preset(Control.PRESET_FULL_RECT)
	_history.bind_store(_store)
	_history.back_requested.connect(func() -> void: _show(_picker))
	_history.place_selected.connect(func(lat: float, lon: float) -> void:
		_picker.selected_name = ""
		_start_generation(lat, lon))
	add_child(_history)

	_show(_picker)

func _show(screen: Control) -> void:
	for s in [_picker, _loading, _view, _history]:
		s.visible = s == screen

func _start_generation(lat: float, lon: float) -> void:
	_pending = Vector2(lat, lon)
	var display_name := _picker.selected_name
	if display_name == "":
		display_name = LocationData.known_place(lat, lon)
	_loading.begin(display_name)
	_show(_loading)
	_pipeline.run(lat, lon, _picker.selected_name)

func _on_generation_finished(data: LocationData) -> void:
	_store.add_entry(data.place_name, data.latitude, data.longitude)
	_view.show_location(data)
	_show(_view)
