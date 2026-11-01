class_name ViewChrome
extends RefCounted

## HUD for View360, laid out as the design system's 360° viewer:
## top-left the exit IconButton and the PlacePill (the Compass tape under
## it on phones), top-centre the Compass ring, top-right the weather
## HudChip and the data-quality StatusBadge, and at the bottom a
## glass-strong bar with the SunArc over season / FOV / fullscreen (and
## gyro on mobile). On desktop the same controls sit in a right inspector
## toggled with I. Attribution stays bottom-left. After 3.5 s without
## input everything but the exit button and attribution fades out; any
## input brings it back. Operates on the view's controls via `v`.

const IDLE_S := 3.5
const FADE_OUT_S := 0.6  # duration-slow
const FADE_IN_S := 0.16  # duration-quick
const BAR_MAX := 560
const INSPECTOR_W := 320  # size-inspector
const PILL_MAX := 280
const SEASON_ICONS := ["flower-2", "sun", "leaf", "snowflake"]  # Spring .. Winter

static func build(v: View360) -> void:
	v._hud = _layer()
	v.add_child(v._hud)
	# Scrim vignette behind the HUD over very bright or dark skies: a
	# 160pt gradient from `scrim` to clear at the top and bottom edges,
	# never over the centre of the scene.
	for top in [true, false]:
		var g := Gradient.new()
		g.set_color(0, Color(UiTheme.SKY_000, 0.55))
		g.set_color(1, Color(UiTheme.SKY_000, 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill_from = Vector2(0, 0) if top else Vector2(0, 1)
		tex.fill_to = Vector2(0, 1) if top else Vector2(0, 0)
		tex.width = 4
		tex.height = 160
		var r := TextureRect.new()
		r.texture = tex
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		r.offset_top = 0.0 if top else -160.0
		r.offset_bottom = 160.0 if top else 0.0
		r.visible = false
		v._hud.add_child(r)
		v._scrims.append(r)
	v._fade = _layer()
	v._hud.add_child(v._fade)
	v._callouts = ViewCallouts.new(v)
	v._fade.add_child(v._callouts)
	# The landmark sheet stays up while the HUD idles (on _hud, not _fade).
	v._landmark_panel = LandmarkPanel.new(v._wiki)
	v._hud.add_child(v._landmark_panel)
	v._landmark_panel.go_requested.connect(v.visit)
	v._landmark_panel.closed.connect(func() -> void: layout(v))
	v._landmark_panel.card.minimum_size_changed.connect(func() -> void:
		(func() -> void: layout(v)).call_deferred())
	v._callouts.site_tapped.connect(func(site: Dictionary) -> void:
		v.open_landmark(site)
		layout(v))

	v._top = VBoxContainer.new()
	v._top.add_theme_constant_override("separation", 8)
	v._top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._fade.add_child(v._top)
	var pill := HudParts.place_pill()
	v._place_box = pill[0]
	v._place_pill = pill[1]
	v._place_coords = pill[2]
	v._top.add_child(v._place_box)
	v._compass = CompassDial.new()
	v._compass.north_requested.connect(func() -> void: turn_north(v))
	v._fade.add_child(v._compass)

	v._top_right = HBoxContainer.new()
	v._top_right.add_theme_constant_override("separation", 8)
	v._top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._fade.add_child(v._top_right)
	var chip := HudParts.hud_chip()
	v._weather_chip = chip[0]
	v._weather_icon = chip[1]
	v._weather_value = chip[2]
	v._weather_label = chip[3]
	v._weather_chip.visible = false
	v._top_right.add_child(v._weather_chip)
	v._quality_badge = HudParts.status_badge("High", "good", "gauge")
	v._quality_badge.tooltip_text = "Data quality"
	v._quality_badge.pressed.connect(func() -> void: v.data_quality_requested.emit())
	v._top_right.add_child(v._quality_badge)

	v._hint = PanelContainer.new()
	v._hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hint.add_theme_stylebox_override("panel", HudStyle.panel(20, 16, 8))
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 8)
	hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hint.add_child(hint_row)
	hint_row.add_child(UiIcon.rect("move", 18, UiTheme.INK))
	var hint_label := UiTheme.label("Drag to look around · Pinch or scroll to zoom", 14, UiTheme.INK)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_row.add_child(hint_label)
	v._fade.add_child(v._hint)
	v._hint_timer = Timer.new()
	v._hint_timer.one_shot = true
	v._hint_timer.wait_time = 6.0
	v._hint_timer.timeout.connect(v._dismiss_hint)
	v._hud.add_child(v._hint_timer)

	v._sheet = PanelContainer.new()
	v._sheet.add_theme_stylebox_override("panel", HudStyle.panel(UiTheme.RADIUS_L, 16, 12))
	UiTheme.add_sheen(v._sheet, UiTheme.RADIUS_L)
	v._fade.add_child(v._sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	v._sheet.add_child(col)
	v._sun_arc = SunArc.new()
	v._time_label = v._sun_arc.time_label
	v._sun_arc.scrubbed.connect(func(m: float) -> void: ViewConditions.set_time_minutes(v, m))
	v._sun_arc.jump_requested.connect(func(kind: String) -> void: ViewConditions.jump_to(v, kind))
	v._sun_arc.now_requested.connect(v.use_live_time)
	col.add_child(v._sun_arc)
	var row := HFlowContainer.new()  # wraps in the narrow inspector
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	col.add_child(row)
	v._season_btn = SegmentedControl.new(LocationData.SEASON_NAMES, SEASON_ICONS, true)
	v._season_btn.select(LocationData.Season.SUMMER)
	v._season_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v._season_btn.item_selected.connect(v._on_season_selected)
	row.add_child(v._season_btn)
	var fov_out := HudParts.icon_button("minus", "Zoom out")
	fov_out.pressed.connect(func() -> void: v._rig.handle_zoom(1.0 / 1.12))
	row.add_child(fov_out)
	var fov_in := HudParts.icon_button("plus", "Zoom in")
	fov_in.pressed.connect(func() -> void: v._rig.handle_zoom(1.12))
	row.add_child(fov_in)
	v._fullscreen_btn = HudParts.icon_button("maximize", "Fullscreen")
	v._fullscreen_btn.pressed.connect(func() -> void: toggle_fullscreen(v))
	row.add_child(v._fullscreen_btn)
	if OS.has_feature("mobile"):
		v._gyro_btn = HudParts.icon_button("smartphone", "Gyro look")
		v._gyro_btn.pressed.connect(func() -> void: toggle_gyro(v))
		row.add_child(v._gyro_btn)
	v._quality_label = UiTheme.data_label("", 13, UiTheme.MUTED, true)
	col.add_child(v._quality_label)

	v._exit_btn = HudParts.icon_button("arrow-left", "Back to map")
	v._exit_btn.pressed.connect(func() -> void: v.back_requested.emit())
	v._hud.add_child(v._exit_btn)
	v._attribution = HudParts.attribution()
	v._attribution.pressed.connect(func() -> void: v.data_sources_requested.emit())
	v._hud.add_child(v._attribution)

	v._announcer = Announcer.new(2.0)
	v._hud.add_child(v._announcer)

	v._idle_timer = Timer.new()
	v._idle_timer.one_shot = true
	v._idle_timer.wait_time = IDLE_S
	v._idle_timer.timeout.connect(func() -> void: idle(v))
	v._hud.add_child(v._idle_timer)
	_sync_fullscreen(v)

static func _layer() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# --- Content ---

## A place opened: pill, data-quality badge, attribution and callouts.
static func show_place(v: View360, data: LocationData) -> void:
	var parts := UiTheme.split_place(data.place_name)
	v._place_pill.text = parts[0]
	v._place_box.tooltip_text = data.place_name
	v._place_coords.text = UiTheme.coords(data.latitude, data.longitude).replace("° ", "°\u00a0")
	var q := HudParts.data_quality(data.data_notes)
	HudParts.apply_status_badge(v._quality_badge, q[0], q[1], "gauge")
	v._quality_badge.tooltip_text = "Data quality: %s" % q[0]
	v._attribution.text = HudParts.short_sources(data.attribution)
	v._attribution.tooltip_text = data.attribution
	v._attribution.visible = v._attribution.text != ""
	v._weather_chip.visible = false
	v._callouts.set_place(data, v._ground)
	v._place_box.accessibility_name = data.place_name
	announce(v)
	wake(v)
	v._on_resized.call_deferred()

static func set_weather(v: View360, temp_c: float, label: String, code: int) -> void:
	v._weather_icon.texture = UiIcon.texture(HudParts.weather_icon(code), 18)
	v._weather_value.text = "%d °C" % roundi(temp_c)
	v._weather_label.text = label
	# At 150% text and above, and on phones, the chip keeps the value only.
	v._weather_label.visible = label != "" and UiTheme.text_scale < 1.5 \
		and Responsive.layout_for_size(v.size) != Responsive.Layout.COMPACT
	v._weather_chip.visible = true
	v._on_resized.call_deferred()

static func weather_failed(v: View360) -> void:
	if v._weather_chip != null:
		v._weather_chip.visible = false

## Re-skin after an accent change. Only the accent-painted parts move,
## so a drag on the sun arc survives the Auto accent's glide.
static func refresh_theme(v: View360) -> void:
	if v._hud == null:
		return
	v._season_btn.restyle()
	v._sun_arc.restyle()
	v._compass.queue_redraw()
	if v._gyro_btn != null:
		HudParts.apply_icon_button(v._gyro_btn, v._gyro_on)

## Scrim on for very bright skies (high sun, snow underfoot) and very
## dark ones (night), where glass alone loses its edge.
static func update_scrim(v: View360) -> void:
	if v._atmos == null or v._scrims.is_empty():
		return
	var bright := v._atmos.solar_elevation > 35.0 or v._atmos.snow_ground
	var dark := v._atmos.night_amount > 0.6
	for r in v._scrims:
		(r as Control).visible = bright or dark

# --- Arrival (design system Storyboards → Map → loading → arrival) ---

const DESCENT_S := 2.4  # duration-descent
const DESCENT_RISE_M := 220.0
const TITLE_HOLD_S := 1.2

## The scene cross-fades in over duration-slow while the camera descends
## to eye height (duration-descent, ease-descent); the place name lands
## in display-xl for 1.2 s, then shrinks into the PlacePill, and the HUD
## fades in last. Reduced motion: a 600 ms cross-fade, no flight.
static func arrive(v: View360) -> void:
	v.modulate.a = 0.0
	var fade := v.create_tween()
	fade.tween_property(v, "modulate:a", 1.0, 0.6)
	if v._fade_tween != null:
		v._fade_tween.kill()
	v._fade.modulate.a = 0.0
	if UiPrefs.reduce_motion:
		v._fade.modulate.a = 1.0
		return
	var eye := v._rig.position
	v._rig.position = eye + Vector3(0, DESCENT_RISE_M, 0)
	var fly := v.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(v._rig, "position", eye, DESCENT_S)
	var title := UiTheme.display_label(v._place_pill.text, 48)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	title.add_theme_constant_override("shadow_offset_y", 2)
	v._hud.add_child(title)
	title.reset_size()
	title.pivot_offset = Vector2.ZERO
	title.position = (v.size - title.size) / 2.0
	var target := v._place_box.global_position - v.global_position + Vector2(16, 2)
	var shrink := 19.0 / 48.0
	var land := v.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	land.tween_interval(TITLE_HOLD_S)
	land.set_parallel(true)
	land.tween_property(title, "position", target, 0.38)
	land.tween_property(title, "scale", Vector2(shrink, shrink), 0.38)
	land.set_parallel(false)
	land.tween_callback(title.queue_free)
	land.tween_callback(func() -> void: wake(v))

# --- Hint, heading, idle ---

static func _dismiss_hint(v: View360) -> void:
	if v._hint == null or not v._hint.visible or v._hint.modulate.a < 1.0:
		return
	var tw := v.create_tween()
	tw.tween_property(v._hint, "modulate:a", 0.0, 0.5)
	tw.tween_callback(v._hint.hide)

static func _show_hint(v: View360) -> void:
	if v._hint == null:
		return
	v._hint.modulate.a = 1.0
	v._hint.show()
	if v._hint_timer.is_inside_tree():
		v._hint_timer.start()

static func heading_deg(v: View360) -> float:
	return fposmod(rad_to_deg(-v._rig.yaw), 360.0)

static func _on_look_changed(v: View360) -> void:
	var before := roundi(v._compass.heading / 15.0)
	v._compass.set_heading(heading_deg(v))
	if roundi(v._compass.heading / 15.0) != before:
		announce(v)
	_dismiss_hint(v)

## Screen readers hear the place, heading, time and the landmark in
## view on change, at most once every 2 s (the Announcer throttles).
static func announce(v: View360, landmark: String = "") -> void:
	if v._announcer == null or v._place_pill == null:
		return
	var parts: Array[String] = [v._place_pill.text, "Heading %s" % v._compass.readout()]
	if v._time_label != null:
		parts.append(v._time_label.text)
	if landmark != "":
		parts.append(landmark)
	v._announcer.say(". ".join(parts))

## Turns the view to north over duration-gentle.
static func turn_north(v: View360) -> void:
	var from := v._rig.yaw
	var to := roundf(from / TAU) * TAU
	var tw := v.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(y: float) -> void:
		v._rig.set_look(y, v._rig.pitch)
		v._compass.set_heading(heading_deg(v)), from, to, maxf(UiPrefs.motion(0.38), 0.01))

## Any input: the HUD comes back over duration-quick and the idle clock
## restarts. Hidden with H, it stays hidden until H again.
static func wake(v: View360) -> void:
	if v._fade == null or v._hud_hidden:
		return
	if v._idle_timer.is_inside_tree():
		v._idle_timer.start()
	if v._fade.visible and v._fade.modulate.a >= 1.0:
		return
	if v._fade_tween != null:
		v._fade_tween.kill()
	v._fade.visible = true
	v._fade_tween = v.create_tween()
	v._fade_tween.tween_property(v._fade, "modulate:a", 1.0, UiPrefs.motion(FADE_IN_S))

## Idle (or H): fade to opacity-hud-idle over duration-slow, then stop
## catching input so a tap lands on the scene and only wakes the HUD.
static func idle(v: View360) -> void:
	if v._fade == null or not v._fade.visible:
		return
	if v._fade_tween != null:
		v._fade_tween.kill()
	v._fade_tween = v.create_tween()
	v._fade_tween.tween_property(v._fade, "modulate:a", 0.0, UiPrefs.motion(FADE_OUT_S))
	v._fade_tween.tween_callback(func() -> void: v._fade.visible = false)

static func toggle_hud(v: View360) -> void:
	v._hud_hidden = not v._hud_hidden
	if v._hud_hidden:
		v._idle_timer.stop()
		idle(v)
	else:
		wake(v)

static func toggle_fullscreen(v: View360) -> void:
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full \
		else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_sync_fullscreen(v)

static func _sync_fullscreen(v: View360) -> void:
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	HudParts.set_icon(v._fullscreen_btn, "minimize" if full else "maximize")
	v._fullscreen_btn.tooltip_text = "Exit fullscreen" if full else "Fullscreen"

## Gyro look (mobile): off by default; View360._process applies it.
static func toggle_gyro(v: View360) -> void:
	v._gyro_on = not v._gyro_on
	HudParts.apply_icon_button(v._gyro_btn, v._gyro_on)

# --- Keys (design system viewer keys) ---

## Returns true when the key was the viewer's.
static func handle_key(v: View360, key: InputEventKey) -> bool:
	var fast := key.shift_pressed
	match key.keycode:
		KEY_LEFT, KEY_RIGHT:
			var step := (0.15 if fast else 0.05) * (1.0 if key.keycode == KEY_LEFT else -1.0)
			v._rig.set_look(v._rig.yaw + step, v._rig.pitch)
			v._on_look_changed()
		KEY_UP, KEY_DOWN:
			var step := (0.15 if fast else 0.05) * (1.0 if key.keycode == KEY_UP else -1.0)
			v._rig.set_look(v._rig.yaw, v._rig.pitch + step)
		KEY_PLUS, KEY_EQUAL, KEY_KP_ADD:
			v._rig.handle_zoom(1.12)
		KEY_MINUS, KEY_KP_SUBTRACT:
			v._rig.handle_zoom(1.0 / 1.12)
		KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
			var minutes := (60.0 if fast else 15.0) * (-1.0 if key.keycode == KEY_BRACKETLEFT else 1.0)
			ViewConditions.set_time_minutes(v, v._time_hour * 60.0 + minutes)
		KEY_1, KEY_2, KEY_3, KEY_4:
			# Left to right as the segments read: Spring .. Winter.
			v._on_season_selected(key.keycode - KEY_1)
		KEY_H:
			toggle_hud(v)
		KEY_F:
			toggle_fullscreen(v)
		KEY_I:
			v._inspector_open = not v._inspector_open
			layout(v)
		KEY_ESCAPE:
			return v._landmark_panel.close() or v._callouts.dismiss()
		_:
			return false
	return true

# --- Layout ---

static func _on_resized(v: View360) -> void:
	layout(v)

## Places every HUD part for the window (Responsive layouts): phone
## bar across the bottom, tablet bar centred up to 560, desktop the
## right inspector.
static func layout(v: View360) -> void:
	if v._hud == null or not is_instance_valid(v._hud):
		return
	var w := v.size.x
	var h := v.size.y
	var lay := Responsive.layout_for_size(v.size)
	var pad := float(Responsive.page_padding(lay))
	var safe := Responsive.safe_insets(v)
	var phone := lay == Responsive.Layout.COMPACT
	# Desktop, and a phone on its side: the controls split to the right.
	var inspector := lay == Responsive.Layout.EXPANDED
	var inset := float(HudParts.SIZE_TOUCH - HudParts.SIZE_HUD) / 2.0
	# Safe areas: nothing under the notch or the home indicator.
	w -= safe[2]
	h -= safe[3]
	pad += maxf(safe[0], safe[1])
	v._exit_btn.position = Vector2(pad - inset, pad - inset)
	v._exit_btn.size = Vector2(HudParts.SIZE_TOUCH, HudParts.SIZE_TOUCH)

	# Top-right chips first: the pill takes the room left between.
	v._top_right.reset_size()
	var right_w := v._top_right.get_combined_minimum_size().x
	v._top_right.position = Vector2(w - pad - right_w + inset, pad - inset)
	var pill_left := pad + HudParts.SIZE_HUD + 8.0
	var room := w - pad - right_w - 8.0 - pill_left
	# Compass: ring at top-centre, or the tape under the pill on phones.
	v._compass.set_tape(phone)
	if phone:
		if v._compass.get_parent() != v._top:
			v._compass.reparent(v._top)
	else:
		if v._compass.get_parent() != v._fade:
			v._compass.reparent(v._fade)
		v._compass.position = Vector2(roundf((w - CompassDial.RING) / 2.0), pad - 4.0)
		room = minf(room, v._compass.position.x - 8.0 - pill_left)
	v._place_pill.custom_minimum_size.x = 0.0
	var font := v._place_pill.get_theme_font("font")
	var name_w := font.get_string_size(v._place_pill.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	var coords_w := v._place_coords.get_theme_font("font").get_string_size(v._place_coords.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var pill_w := clampf(maxf(name_w, coords_w) + 34.0, 80.0, minf(PILL_MAX, maxf(room, 80.0)))
	v._place_pill.custom_minimum_size.x = pill_w - 34.0
	v._place_coords.custom_minimum_size.x = pill_w - 34.0
	v._place_coords.size.x = pill_w - 34.0
	v._place_box.custom_minimum_size.x = pill_w
	v._top.position = Vector2(pill_left, pad)
	v._top.reset_size()

	v._attribution.reset_size()
	var attr_h := v._attribution.size.y
	var attr_w := minf(v._attribution.get_theme_font("font").get_string_size(v._attribution.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 40.0, w - pad * 2.0)
	v._attribution.position = Vector2(pad, h - pad - attr_h)
	v._attribution.size.x = attr_w

	# Bar or inspector.
	var bar_w: float = float(INSPECTOR_W) if inspector \
		else (w - pad * 2.0 if phone else minf(float(BAR_MAX), w - pad * 2.0))
	v._sun_arc.set_arc_height(56.0 if h < 500.0 else (72.0 if h < 760.0 else 108.0))
	v._sun_arc.set_compact(bar_w < 380.0 or h < 500.0)
	v._season_btn.set_icon_only(bar_w < 460.0)
	v._quality_label.visible = inspector
	v._sheet.visible = not inspector or v._inspector_open
	v._sheet.custom_minimum_size = Vector2(bar_w, 0)
	v._sheet.reset_size()
	var sheet_h := v._sheet.get_combined_minimum_size().y
	if inspector:
		var top := pad + CompassDial.RING + 8.0
		v._sheet.position = Vector2(w - pad - bar_w, top)
	else:
		v._sheet.position = Vector2(roundf((w - bar_w) / 2.0), h - pad - attr_h - 8.0 - sheet_h)
	v._sheet.size = Vector2(bar_w, sheet_h)

	_place_landmark_panel(v, lay, inspector, pad, w, h, attr_h, bar_w)

	v._hint.reset_size()
	var hint_bottom := v._sheet.position.y - 12.0 if not inspector else h - pad - attr_h - 12.0
	v._hint.position = Vector2(roundf((w - v._hint.size.x) / 2.0), hint_bottom - v._hint.size.y)

## The landmark sheet: a left side panel under the place pill on
## desktop; on phones and tablets a bottom sheet up to half the height,
## in the controls bar's place (the bar steps aside while it is open).
static func _place_landmark_panel(v: View360, lay: Responsive.Layout, inspector: bool,
		pad: float, w: float, h: float, attr_h: float, bar_w: float) -> void:
	var lp := v._landmark_panel
	if lp == null or not lp.is_open():
		return
	var bottom := h - pad - attr_h - 8.0
	if inspector:
		var top := v._top.position.y + v._top.size.y + 12.0
		lp.place(Rect2(pad, top, minf(float(Responsive.sidebar_width(lay)), w - pad * 2.0),
			bottom - top), false)
		return
	v._sheet.visible = false
	var max_h := clampf(h * 0.5, 240.0, bottom - pad)
	lp.place(Rect2(roundf((w - bar_w) / 2.0), bottom - max_h, bar_w, max_h), true)
