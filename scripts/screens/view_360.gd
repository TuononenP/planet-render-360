class_name View360
extends Control

signal back_requested

var _viewport: SubViewport
var _container: SubViewportContainer
var _rig: CameraRig
var _world_root: Node3D
var _place_pill: Label
var _attribution_label: Label
var _compass: Label
var _sun_slider: HSlider
var _sun: DirectionalLight3D
var _atmos: AtmosphereRig
var _governor: QualityGovernor
var _quality_label: Label
var _weather: WeatherFetcher
var _weather_label: Label
var _top: HBoxContainer
var _sheet: PanelContainer
var _bottom_root: VBoxContainer
var _hint: PanelContainer
var _hint_timer: Timer
var _sun_icon: Label
var _time_label: Label
var _now_btn: Button
var _live_time := true
var _setting_time := false
var _time_hour := 12.0
## Still on the spawn's golden hour (no hour picked since opening).
var _spawn_golden := false
var _touches: Dictionary = {}
var _quality_preset: int = RenderSettings.Preset.HIGH
var _data: LocationData
var _generated: Node3D
var _ground: GroundTruth
## Season rebuild in flight on its thread / another season picked
## meanwhile (coalesced into one follow-up build).
var _season_building := false
var _season_dirty := false
## Live build_location threads, joined before the view is freed.
var _threads: Array[Thread] = []
var _season_btn: OptionButton
var _precip: GPUParticles3D
var _pinch_base := 0.0
var _magnify_accum := 1.0

## Eye height above ground in metres (PRD §3.3: 25–35 m, ≈8 m above the
## mean roofline). v1's 9.5 units were ≈38 m on the 4 m-unit world.
const EYE_HEIGHT_M := 30.0
## T5.2 framing: a viewpoint closer than FRAME_MIN_M to its landmark
## (e.g. picked on the Eiffel itself) spawns FRAME_READ_M back from it
## (PRD §4.1: the tower is judged from ≈700–900 m), so the camera moves
## — never the landmark.
const FRAME_MIN_M := 400.0
const FRAME_READ_M := 800.0
## Far plane past the 30 km outer terrain ring's corners.
const CAMERA_FAR_M := 45000.0

func _ready() -> void:
	_container = SubViewportContainer.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	# With stretch enabled the container owns the SubViewport size and
	# resizes it with the window. Setting _viewport.size manually is
	# exactly what triggers the engine warning, so it is never done here.
	_container.stretch = true
	add_child(_container)
	_viewport = SubViewport.new()
	_container.add_child(_viewport)
	_build_3d()
	_governor = QualityGovernor.new()
	add_child(_governor)
	_governor.viewport = _viewport
	_governor.sun = _sun
	_governor.set_preset(_quality_preset)
	_governor.quality_changed.connect(func(step_name: String, fps: float) -> void:
		if _quality_label != null:
			_quality_label.text = "%s · %d fps" % [step_name, int(round(fps))])
	_weather = WeatherFetcher.new()
	add_child(_weather)
	_weather.succeeded.connect(_on_weather)
	_weather.failed.connect(func(_r: String) -> void:
		if _weather_label != null:
			_weather_label.text = ""
			_weather_label.visible = false)

	_build_hud()

	var clock := Timer.new()
	clock.wait_time = 15.0
	clock.autostart = true
	clock.timeout.connect(func() -> void:
		if _live_time:
			_apply_current_time())
	add_child(clock)
	use_live_time()

	resized.connect(_on_resized)
	_on_resized()

## Heads-up layer (see HudStyle): smoked-glass pills up top, a slim
## floating dock below and a drag hint that fades once the user looks
## around, so the scene keeps the screen.
func _build_hud() -> void:
	_top = HBoxContainer.new()
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.add_theme_constant_override("separation", 10)
	_top.offset_left = 16
	_top.offset_top = 16
	_top.offset_right = -16
	add_child(_top)
	var back_btn := HudStyle.button("←  Map", Vector2(96, 52), 16, 26)
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	_top.add_child(back_btn)
	var place := PanelContainer.new()
	place.custom_minimum_size = Vector2(0, 52)
	place.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	place.add_theme_stylebox_override("panel", HudStyle.panel(26, 18, 6))
	_top.add_child(place)
	var place_col := VBoxContainer.new()
	place_col.alignment = BoxContainer.ALIGNMENT_CENTER
	place_col.add_theme_constant_override("separation", 0)
	place.add_child(place_col)
	_place_pill = HudStyle.label("◉  Paris, France", 16)
	_place_pill.clip_text = true
	_place_pill.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	place_col.add_child(_place_pill)
	_weather_label = HudStyle.label("", 12, HudStyle.ACCENT)
	_weather_label.visible = false
	place_col.add_child(_weather_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top.add_child(spacer)
	var compass_disc := PanelContainer.new()
	compass_disc.custom_minimum_size = Vector2(56, 56)
	compass_disc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var disc_style := HudStyle.glass(28, HudStyle.ACCENT, HudStyle.GLASS, 0, 4)
	disc_style.set_border_width_all(2)
	compass_disc.add_theme_stylebox_override("panel", disc_style)
	_top.add_child(compass_disc)
	var compass_col := VBoxContainer.new()
	compass_col.alignment = BoxContainer.ALIGNMENT_CENTER
	compass_col.add_theme_constant_override("separation", -4)
	compass_disc.add_child(compass_col)
	var needle := HudStyle.label("▲", 11, HudStyle.ACCENT)
	needle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass_col.add_child(needle)
	_compass = HudStyle.label("N", 15)
	_compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass_col.add_child(_compass)

	# Bottom: drag hint over a slim floating dock, both centred.
	_bottom_root = VBoxContainer.new()
	_bottom_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_root.alignment = BoxContainer.ALIGNMENT_END
	_bottom_root.add_theme_constant_override("separation", 12)
	_bottom_root.offset_left = 16
	_bottom_root.offset_right = -16
	_bottom_root.offset_top = -380
	_bottom_root.offset_bottom = -16
	add_child(_bottom_root)
	_hint = PanelContainer.new()
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_stylebox_override("panel", HudStyle.panel(20, 16, 8))
	var hint_label := HudStyle.label("✥  Drag to look around · Pinch or scroll to zoom", 13, HudStyle.TEXT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_child(hint_label)
	_bottom_root.add_child(_hint)
	_hint_timer = Timer.new()
	_hint_timer.one_shot = true
	_hint_timer.wait_time = 6.0
	_hint_timer.timeout.connect(_dismiss_hint)
	add_child(_hint_timer)
	_sheet = PanelContainer.new()
	_sheet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sheet.add_theme_stylebox_override("panel", HudStyle.panel(28, 18, 14))
	_bottom_root.add_child(_sheet)

	var dock := VBoxContainer.new()
	dock.add_theme_constant_override("separation", 12)
	_sheet.add_child(dock)
	var sun_row := HBoxContainer.new()
	sun_row.add_theme_constant_override("separation", 8)
	dock.add_child(sun_row)
	_sun_icon = HudStyle.label("☀", 20, HudStyle.ACCENT)
	_sun_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sun_row.add_child(_sun_icon)
	var prev_btn := HudStyle.button("‹", Vector2(44, 44), 20, 22)
	prev_btn.pressed.connect(func() -> void: set_time_of_day(wrapi(int(floor(_time_hour)) - 1, 0, 24)))
	sun_row.add_child(prev_btn)
	_sun_slider = HSlider.new()
	_sun_slider.min_value = 0.0
	_sun_slider.max_value = 23.0
	_sun_slider.step = 1.0
	_sun_slider.tick_count = 24
	_sun_slider.ticks_on_borders = true
	_sun_slider.value = 12
	_sun_slider.focus_mode = Control.FOCUS_NONE
	_sun_slider.custom_minimum_size = Vector2(0, 44)
	_sun_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sun_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	HudStyle.apply_slider(_sun_slider)
	_sun_slider.value_changed.connect(_on_time_slider_changed)
	sun_row.add_child(_sun_slider)
	var next_btn := HudStyle.button("›", Vector2(44, 44), 20, 22)
	next_btn.pressed.connect(func() -> void: set_time_of_day(wrapi(int(floor(_time_hour)) + 1, 0, 24)))
	sun_row.add_child(next_btn)
	_time_label = HudStyle.label("12:00", 24)
	_time_label.custom_minimum_size = Vector2(66, 0)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sun_row.add_child(_time_label)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	dock.add_child(mode_row)
	_season_btn = OptionButton.new()
	for i in LocationData.SEASON_NAMES.size():
		_season_btn.add_item("❋  %s" % LocationData.SEASON_NAMES[i], i)
	_season_btn.select(LocationData.Season.SUMMER)
	_season_btn.focus_mode = Control.FOCUS_NONE
	_season_btn.custom_minimum_size = Vector2(0, 44)
	_season_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_season_btn.add_theme_font_size_override("font_size", 15)
	HudStyle.apply_option(_season_btn)
	_season_btn.item_selected.connect(_on_season_selected)
	mode_row.add_child(_season_btn)
	_now_btn = HudStyle.button("Now", Vector2(120, 44), 14, 18)
	_now_btn.pressed.connect(use_live_time)
	mode_row.add_child(_now_btn)

	var rule := ColorRect.new()
	rule.color = HudStyle.EDGE
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(rule)
	_quality_label = HudStyle.label("High · 60 fps", 12, HudStyle.TEXT_DIM)
	_quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dock.add_child(_quality_label)
	_attribution_label = HudStyle.label("", 10, HudStyle.TEXT_FAINT)
	_attribution_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attribution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(_attribution_label)

## Rebuild the HUD after an accent change: its styleboxes bake the
## palette in at creation, so the simplest correct re-skin is a fresh
## build with the visible state carried over.

# --- Delegators: implementation in ViewChrome / ViewConditions. ---
func refresh_theme() -> void:
	ViewChrome.refresh_theme(self)

func _dismiss_hint() -> void:
	ViewChrome._dismiss_hint(self)

func _show_hint() -> void:
	ViewChrome._show_hint(self)

func _fit_place_pill() -> void:
	ViewChrome._fit_place_pill(self)

func _on_look_changed() -> void:
	ViewChrome._on_look_changed(self)

func _on_resized() -> void:
	ViewChrome._on_resized(self)

func _on_season_selected(index: int) -> void:
	ViewConditions._on_season_selected(self, index)

func _build_precip() -> void:
	ViewConditions._build_precip(self)

func _apply_precip(code: int) -> void:
	ViewConditions._apply_precip(self, code)

func _on_weather(temp_c: float, label: String, cloud_cover: float, code: int) -> void:
	ViewConditions._on_weather(self, temp_c, label, cloud_cover, code)

func set_time_of_day(hour: int) -> void:
	ViewConditions.set_time_of_day(self, hour)

func use_live_time() -> void:
	ViewConditions.use_live_time(self)

func _apply_current_time() -> void:
	ViewConditions._apply_current_time(self)

func _on_time_slider_changed(value: float) -> void:
	ViewConditions._on_time_slider_changed(self, value)

func _sync_time_ui() -> void:
	ViewConditions._sync_time_ui(self)

func _apply_time(hour_f: float) -> void:
	ViewConditions._apply_time(self, hour_f)

func _build_3d() -> void:
	_world_root = Node3D.new()
	_viewport.add_child(_world_root)
	# Sun, sky, haze and clouds live in the AtmosphereRig (T6.1); the
	# view only feeds it time, weather, season and quality.
	_atmos = AtmosphereRig.new(_quality_preset)
	_world_root.add_child(_atmos)
	_sun = _atmos.sun
	_rig = CameraRig.new()
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.far = CAMERA_FAR_M
	cam.near = 0.25
	_rig.add_child(cam)
	_rig.position = Vector3(0, EYE_HEIGHT_M, 0)
	_world_root.add_child(_rig)
	_build_precip()

## Caps the FPS governor at the user's preset; terrain accuracy for a
## place is fixed when it was generated, so this only moves the live
## render scale / shadow ceiling.
func set_quality_preset(preset_value: int) -> void:
	_quality_preset = RenderSettings.clamp_preset(preset_value)
	if _atmos != null:
		_atmos.set_quality(_quality_preset)
	if _governor != null:
		_governor.set_preset(_quality_preset)
	# LOD rings re-range in place: nothing rebuilds or moves (AC-12).
	if _generated != null and is_instance_valid(_generated):
		LodRing.apply(_generated, _quality_preset)

## Replace the generated world in place. The old world is tracked by
## reference: same-named siblings get auto-renamed by the engine, so
## the previous name-based cleanup leaked a world per place visited.
func _rebuild_world(prebuilt: Node3D = null) -> void:
	if _data == null or _world_root == null:
		return
	if _generated != null and is_instance_valid(_generated):
		_world_root.remove_child(_generated)
		_generated.queue_free()
	if prebuilt != null:
		_generated = prebuilt
	else:
		if _ground == null:
			_ground = GroundTruth.new(_data)
		_generated = make_world(_data, _ground)
	# Range the near/mid rings for the current preset.
	LodRing.apply(_generated, _quality_preset)
	_world_root.add_child(_generated)

## Detached world build: touches no scene tree, so it may run off the
## main thread (see build_location).
static func make_world(data: LocationData, ground: GroundTruth) -> Node3D:
	var world := TerrainBuilder.build_world(data, ground)
	# T7.1: merge building masses per material/cell (preset-independent).
	LodRing.merge_buildings(world)
	return world

## Builds [ground, world] for `data` on a worker thread. The build takes
## seconds on dense cities; run on the main thread it froze the loading
## screen (macOS beachball), so the caller's screen keeps drawing here.
## Pass the result to show_location. A known `ground` is reused.
func build_location(data: LocationData, ground: GroundTruth = null) -> Array:
	var thread := Thread.new()
	_threads.append(thread)
	thread.start(func() -> Array:
		var g := ground if ground != null else GroundTruth.new(data)
		return [g, make_world(data, g)])
	while thread.is_alive():
		await get_tree().process_frame
	_threads.erase(thread)
	return thread.wait_to_finish()

func _notification(what: int) -> void:
	# A thread outliving its owner aborts the engine on free/quit. The
	# builders make RenderingServer read-backs (surface_get_arrays,
	# get_image) that wait on the main thread, so service them while
	# joining or this deadlocks.
	if what == NOTIFICATION_PREDELETE:
		for t in _threads:
			while t.is_alive():
				RenderingServer.force_sync()
				OS.delay_msec(1)
			if t.is_started():
				var built: Array = t.wait_to_finish()
				if built.size() > 1 and built[1] is Node3D:
					(built[1] as Node3D).free()
		_threads.clear()

func show_location(data: LocationData, prebuilt: Array = []) -> void:
	set_quality_preset(data.quality_preset)
	_data = data
	if _season_btn != null:
		_season_btn.select(data.season)
	_atmos.set_season(data.season)
	_atmos.set_place(data.latitude, data.longitude)
	_place_pill.text = "◉  %s" % data.place_name
	_fit_place_pill()
	_show_hint()
	if _attribution_label != null:
		_attribution_label.text = data.attribution
	if prebuilt.is_empty():
		_ground = GroundTruth.new(data)
		_rebuild_world()
	else:
		_ground = prebuilt[0]
		_rebuild_world(prebuilt[1])
	# Spawn at golden hour (PRD §3.3): the judged condition for every
	# place, now the place's own (T6.2: the hour the true afternoon sun
	# sits at the reference elevation). The slider still leaves it.
	ViewConditions.spawn_golden_hour(self)
	var spawn := spawn_xz(data)
	_rig.position = Vector3(spawn.x,
		_ground.height_at_world(spawn.x, spawn.y) + EYE_HEIGHT_M, spawn.y)
	_rig.set_look(0.6, -0.10)
	if data.landmark_type != "none":
		# Open with the landmark left-of-centre (PRD §4.1: 0.36 W),
		# not dead ahead, so the river/city sweep fills the right. The
		# landmark stands at its true site (T5.2); the look aims at it.
		_rig.set_look(landmark_yaw(data, spawn) - 0.12, -0.08)
	if _weather != null:
		_weather.fetch(data.latitude, data.longitude)

## Camera ground position (metres): the viewpoint itself, unless the
## viewpoint sits on its landmark — then FRAME_READ_M back along the v1
## framing direction (landmark ENE of the camera), inside the extent.
static func spawn_xz(data: LocationData) -> Vector2:
	if data.landmark_type == "none":
		return Vector2.ZERO
	var lp := TerrainBuilder.landmark_world_pos(data)
	if lp.length() >= FRAME_MIN_M:
		return Vector2.ZERO
	return lp - TerrainBuilder.LANDMARK_POS.normalized() * FRAME_READ_M

## Yaw that faces the landmark's true site from `from` (CameraRig:
## forward is -Z rotated by yaw; north = -Z).
static func landmark_yaw(data: LocationData, from: Vector2) -> float:
	var d := TerrainBuilder.landmark_world_pos(data) - from
	return atan2(-d.x, -d.y)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rig.handle_zoom(1.12)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rig.handle_zoom(1.0 / 1.12)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			_rig.reset_zoom()
			accept_event()
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		_magnify_accum *= mg.factor
		if _magnify_accum > 1.15:
			_magnify_accum = 1.0
			_rig.handle_zoom(1.18)
		elif _magnify_accum < 0.87:
			_magnify_accum = 1.0
			_rig.handle_zoom(1.0 / 1.18)
		accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() == 2:
				_pinch_base = _touch_distance()
		else:
			_touches.erase(st.index)
		accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touches.has(sd.index):
			_touches[sd.index] = sd.position
		if _touches.size() >= 2:
			var dist := _touch_distance()
			if _pinch_base > 1.0 and dist > 1.0:
				_rig.handle_zoom(dist / _pinch_base)
				_pinch_base = dist
		else:
			_rig.handle_drag(sd.relative)
			_on_look_changed()
		accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_rig.handle_drag(event.relative)
		_on_look_changed()

func _touch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])
