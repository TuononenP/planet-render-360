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
var _env: WorldEnvironment
var _governor: QualityGovernor
var _quality_label: Label
var _weather: WeatherFetcher
var _weather_label: Label
var _top: HBoxContainer
var _sheet: PanelContainer
var _bottom_root: HBoxContainer
var _time_label: Label
var _now_btn: Button
var _live_time := true
var _setting_time := false
var _time_hour := 12.0
var _sky_mat: ProceduralSkyMaterial
var _cloud_cover := 0.0
var _touches: Dictionary = {}
var _pinch_base := 0.0
var _magnify_accum := 1.0

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
	_governor.quality_changed.connect(func(step_name: String, fps: float) -> void:
		if _quality_label != null:
			_quality_label.text = "%s · %d fps" % [step_name, int(round(fps))])
	_weather = WeatherFetcher.new()
	add_child(_weather)
	_weather.succeeded.connect(_on_weather)
	_weather.failed.connect(func(_r: String) -> void:
		if _weather_label != null:
			_weather_label.text = "")

	# Top bar: frosted pills matching approved mockup, sized in points.
	_top = HBoxContainer.new()
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.add_theme_constant_override("separation", 10)
	_top.offset_left = 16
	_top.offset_top = 16
	_top.offset_right = -16
	add_child(_top)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel",
		UiTheme.style(Color(1, 1, 1, 0.92), 22, Color.TRANSPARENT, true))
	_place_pill = UiTheme.label("📍 Paris, France", 17, UiTheme.INK, true)
	pill.add_child(_place_pill)
	_top.add_child(pill)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top.add_child(spacer)
	_compass = UiTheme.label("N ↑", 17, UiTheme.TEAL_DARK, true)
	var compass_pill := PanelContainer.new()
	compass_pill.custom_minimum_size = Vector2(72, 48)
	compass_pill.add_theme_stylebox_override("panel",
		UiTheme.style(Color(1, 1, 1, 0.92), 22, Color.TRANSPARENT, true))
	compass_pill.add_child(_compass)
	_top.add_child(compass_pill)

	# Bottom sheet: dark frosted panel so white text stays readable over
	# bright terrain/snow (previously white-on-white at the screen edge).
	_bottom_root = HBoxContainer.new()
	_bottom_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_root.offset_left = 16
	_bottom_root.offset_right = -16
	_bottom_root.offset_top = -380
	_bottom_root.offset_bottom = -16
	add_child(_bottom_root)
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_root.add_child(left_spacer)
	_sheet = PanelContainer.new()
	_sheet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sheet.size_flags_vertical = Control.SIZE_SHRINK_END
	_sheet.add_theme_stylebox_override("panel",
		UiTheme.style(Color(0.07, 0.09, 0.08, 0.78), 20, Color.TRANSPARENT, true))
	_bottom_root.add_child(_sheet)
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_root.add_child(right_spacer)

	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	_sheet.add_child(bottom)
	var hint := UiTheme.label("Drag to look around · scroll or pinch to zoom", 15, Color.WHITE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(hint)
	_weather_label = UiTheme.label("", 14, Color(1, 1, 1, 0.92))
	_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_weather_label)
	var sun_row := HBoxContainer.new()
	sun_row.add_theme_constant_override("separation", 8)
	bottom.add_child(sun_row)
	sun_row.add_child(UiTheme.label("☀", 16, Color.WHITE))
	var prev_btn := Button.new()
	prev_btn.text = "‹"
	prev_btn.custom_minimum_size = Vector2(40, 44)
	prev_btn.add_theme_font_size_override("font_size", 20)
	prev_btn.add_theme_color_override("font_color", Color.WHITE)
	prev_btn.add_theme_stylebox_override("normal", UiTheme.style(Color(1, 1, 1, 0.14), 10, Color(1, 1, 1, 0.3)))
	prev_btn.add_theme_stylebox_override("hover", UiTheme.style(Color(1, 1, 1, 0.22), 10, Color(1, 1, 1, 0.3)))
	prev_btn.pressed.connect(func() -> void: set_time_of_day(wrapi(int(floor(_time_hour)) - 1, 0, 24)))
	sun_row.add_child(prev_btn)
	_sun_slider = HSlider.new()
	_sun_slider.min_value = 0.0
	_sun_slider.max_value = 23.0
	_sun_slider.step = 1.0
	_sun_slider.tick_count = 24
	_sun_slider.ticks_on_borders = true
	_sun_slider.value = 12
	_sun_slider.custom_minimum_size = Vector2(0, 40)
	_sun_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sun_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sun_slider.value_changed.connect(_on_time_slider_changed)
	sun_row.add_child(_sun_slider)
	var next_btn := Button.new()
	next_btn.text = "›"
	next_btn.custom_minimum_size = Vector2(40, 44)
	next_btn.add_theme_font_size_override("font_size", 20)
	next_btn.add_theme_color_override("font_color", Color.WHITE)
	next_btn.add_theme_stylebox_override("normal", UiTheme.style(Color(1, 1, 1, 0.14), 10, Color(1, 1, 1, 0.3)))
	next_btn.add_theme_stylebox_override("hover", UiTheme.style(Color(1, 1, 1, 0.22), 10, Color(1, 1, 1, 0.3)))
	next_btn.pressed.connect(func() -> void: set_time_of_day(wrapi(int(floor(_time_hour)) + 1, 0, 24)))
	sun_row.add_child(next_btn)
	_time_label = UiTheme.label("12:00", 16, Color.WHITE, true)
	_time_label.custom_minimum_size = Vector2(56, 0)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sun_row.add_child(_time_label)
	_now_btn = Button.new()
	_now_btn.text = "Use current time"
	_now_btn.custom_minimum_size = Vector2(0, 46)
	_now_btn.add_theme_font_size_override("font_size", 15)
	_now_btn.add_theme_color_override("font_color", Color.WHITE)
	_now_btn.add_theme_stylebox_override("normal", UiTheme.style(Color(1, 1, 1, 0.14), 12, Color(1, 1, 1, 0.35)))
	_now_btn.add_theme_stylebox_override("hover", UiTheme.style(Color(1, 1, 1, 0.22), 12, Color(1, 1, 1, 0.35)))
	_now_btn.add_theme_stylebox_override("pressed", UiTheme.style(Color(1, 1, 1, 0.22), 12, Color(1, 1, 1, 0.35)))
	_now_btn.pressed.connect(use_live_time)
	bottom.add_child(_now_btn)
	_quality_label = UiTheme.label("High · 60 fps", 12, Color(1, 1, 1, 0.85))
	_quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_quality_label)
	_attribution_label = UiTheme.label("", 11, Color(1, 1, 1, 0.8))
	_attribution_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attribution_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(_attribution_label)
	var back := Button.new()
	back.text = "← Back to map"
	back.custom_minimum_size = Vector2(0, 50)
	back.add_theme_font_size_override("font_size", 16)
	back.add_theme_color_override("font_color", Color.WHITE)
	back.add_theme_stylebox_override("normal", UiTheme.style(Color(1, 1, 1, 0.14), 12, Color(1, 1, 1, 0.35)))
	back.add_theme_stylebox_override("hover", UiTheme.style(Color(1, 1, 1, 0.22), 12, Color(1, 1, 1, 0.35)))
	back.add_theme_stylebox_override("pressed", UiTheme.style(Color(1, 1, 1, 0.22), 12, Color(1, 1, 1, 0.35)))
	back.pressed.connect(func() -> void: back_requested.emit())
	bottom.add_child(back)

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

func _on_resized() -> void:
	if _top == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	var pad := Responsive.page_padding(layout)
	_top.offset_left = pad
	_top.offset_right = -pad
	_top.offset_top = pad
	_bottom_root.offset_left = pad
	_bottom_root.offset_right = -pad
	_bottom_root.offset_bottom = -pad
	var sheet_width := int(size.x) - pad * 2
	if Responsive.is_split(layout):
		sheet_width = mini(sheet_width, 680)
	_sheet.custom_minimum_size = Vector2(maxi(sheet_width, 280), 0)

func _build_3d() -> void:
	_world_root = Node3D.new()
	_viewport.add_child(_world_root)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-52, -38, 0)
	_sun.shadow_enabled = true
	_world_root.add_child(_sun)
	_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = Color(0.62, 0.76, 0.86)
	_sky_mat.sky_horizon_color = Color(0.98, 0.88, 0.72)
	_sky_mat.ground_bottom_color = Color(0.55, 0.52, 0.45)
	_sky_mat.ground_horizon_color = Color(0.92, 0.84, 0.70)
	sky.sky_material = _sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.environment = env
	_world_root.add_child(_env)
	_rig = CameraRig.new()
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	_rig.add_child(cam)
	_rig.position = Vector3(0, 14, 0)
	_world_root.add_child(_rig)

func show_location(data: LocationData) -> void:
	_place_pill.text = "📍 %s" % data.place_name
	if _attribution_label != null:
		_attribution_label.text = data.attribution
	for child in _world_root.get_children():
		if child.name == "GeneratedWorld":
			child.queue_free()
	_world_root.add_child(TerrainBuilder.build_world(data))
	_rig.position.y = data.height_at(data.grid_size / 2, data.grid_size / 2) + 22.0
	_rig.set_look(0.6, -0.16)
	if _weather != null:
		_weather.fetch(data.latitude, data.longitude)

func _on_weather(temp_c: float, label: String, cloud_cover: float, code: int) -> void:
	if _weather_label != null:
		_weather_label.text = "%.0f°C · %s" % [temp_c, label]
	_cloud_cover = cloud_cover
	_apply_time(_time_hour)
	if _env != null and _env.environment != null:
		var foggy := code in [45, 48, 51, 53, 55, 61, 63, 65, 71, 73, 75]
		_env.environment.fog_enabled = foggy
		_env.environment.fog_density = 0.012 if foggy else 0.0

# --- Time of day: 24 hourly slots, or live current time ---

func set_time_of_day(hour: int) -> void:
	_live_time = false
	_time_hour = float(clampi(hour, 0, 23))
	_apply_time(_time_hour)
	_sync_time_ui()

func use_live_time() -> void:
	_live_time = true
	_apply_current_time()

func _apply_current_time() -> void:
	var now := Time.get_time_dict_from_system()
	_time_hour = float(now.get("hour", 12)) + float(now.get("minute", 0)) / 60.0
	_apply_time(_time_hour)
	_sync_time_ui()

func _on_time_slider_changed(value: float) -> void:
	if _setting_time:
		return
	set_time_of_day(int(value))

func _sync_time_ui() -> void:
	if _sun_slider == null:
		return
	_setting_time = true
	_sun_slider.value = floor(_time_hour)
	_setting_time = false
	if _live_time:
		var now := Time.get_time_dict_from_system()
		_time_label.text = "%02d:%02d" % [int(now.get("hour", 0)), int(now.get("minute", 0))]
		_now_btn.text = "● Now — current time (live)"
	else:
		_time_label.text = "%02d:00" % int(_time_hour)
		_now_btn.text = "Use current time"

func _apply_time(hour_f: float) -> void:
	if _sun == null:
		return
	var cloud := lerpf(1.0, 0.55, clampf(_cloud_cover, 0.0, 100.0) / 100.0)
	var arc := sin(PI * (hour_f - 6.0) / 12.0)  # >0 by day, <0 at night
	if arc > -0.08:
		var day_t := clampf((hour_f - 6.0) / 12.0, 0.0, 1.0)
		_sun.rotation_degrees = Vector3(-maxf(arc, 0.02) * 62.0, lerpf(-95.0, 95.0, day_t), 0)
		_sun.light_energy = (0.30 + 1.0 * maxf(arc, 0.0)) * cloud
		_sun.light_color = Color(1, 0.62, 0.38).lerp(
			Color(1, 0.97, 0.92), clampf(arc * 1.7, 0.0, 1.0))
	else:
		# Moonlight: fixed cool light so night scenes stay readable.
		_sun.rotation_degrees = Vector3(-38, 35, 0)
		_sun.light_energy = 0.12 * cloud
		_sun.light_color = Color(0.62, 0.72, 0.95)
	if _sky_mat != null:
		_sky_mat.sky_top_color = _keyframed(hour_f, [
			[0.0, Color(0.04, 0.07, 0.15)], [5.0, Color(0.07, 0.10, 0.20)],
			[7.5, Color(0.45, 0.60, 0.80)], [12.0, Color(0.62, 0.76, 0.86)],
			[17.0, Color(0.55, 0.68, 0.82)], [19.0, Color(0.35, 0.38, 0.55)],
			[21.0, Color(0.06, 0.08, 0.17)], [24.0, Color(0.04, 0.07, 0.15)]])
		_sky_mat.sky_horizon_color = _keyframed(hour_f, [
			[0.0, Color(0.10, 0.12, 0.20)], [5.0, Color(0.16, 0.16, 0.22)],
			[7.5, Color(0.98, 0.75, 0.52)], [12.0, Color(0.94, 0.90, 0.80)],
			[17.0, Color(0.95, 0.82, 0.64)], [19.0, Color(0.92, 0.58, 0.42)],
			[21.0, Color(0.12, 0.12, 0.20)], [24.0, Color(0.10, 0.12, 0.20)]])

static func _keyframed(hour_f: float, keys: Array) -> Color:
	for i in keys.size() - 1:
		var h0 := float(keys[i][0])
		var h1 := float(keys[i + 1][0])
		if hour_f >= h0 and hour_f <= h1:
			var t := 0.0 if h1 == h0 else (hour_f - h0) / (h1 - h0)
			return (keys[i][1] as Color).lerp(keys[i + 1][1], t)
	return keys[keys.size() - 1][1]

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
			_compass.text = "%s ↑" % _rig.compass_text()
		accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_rig.handle_drag(event.relative)
		_compass.text = "%s ↑" % _rig.compass_text()

func _touch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])
