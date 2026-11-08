class_name ViewChrome
extends RefCounted

## HUD for View360, laid out as the design system's 360° viewer:
## top-left the exit IconButton and the PlacePill (the Compass tape under
## it on phones), top-centre the Compass ring, top-right the weather
## HudChip, the data-quality StatusBadge and fullscreen. The controls
## (ViewerControls) are one glass-strong panel: the SunArc (time, play,
## the day chip, the arc, four jumps), then the Show chips and the photo
## and link actions; a bottom sheet on phones and tablets, the right
## inspector on desktop (I, or its chevron, hides it). Zoom (and gyro on
## mobile) is a glass stack on the scene's edge beside the controls.
## Attribution stays bottom-left. After 3.5 s without input everything but
## the exit button and attribution fades out; any input brings it back.
## Operates on the view's controls via `v`.

const IDLE_S := 3.5
const FADE_OUT_S := 0.6  # duration-slow
const FADE_IN_S := 0.16  # duration-quick
const BAR_MAX := 560
const INSPECTOR_W := 320  # size-inspector
const PILL_MAX := 280

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
	v._landmark_panel.closer_requested.connect(v.visit.bind(true))
	v._landmark_panel.closed.connect(func() -> void: layout(v))
	v._landmark_panel.content_resized.connect(func() -> void:
		(func() -> void: layout(v)).call_deferred())
	v._landmark_panel.state_changed.connect(func() -> void: sync_nearby(v))
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
	# Phones: the heading tape and the weather chip share the row under the pill.
	v._tape_row = HBoxContainer.new()
	v._tape_row.add_theme_constant_override("separation", 8)
	v._tape_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._tape_row.visible = false
	v._top.add_child(v._tape_row)
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
	# A tap opens the Conditions sheet, where the weather is picked.
	v._weather_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	v._weather_chip.gui_input.connect(func(e: InputEvent) -> void:
		# A tap arrives as an emulated mouse click too, so only the mouse
		# event is read: reading the touch as well would toggle twice.
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
				and not e.is_pressed():
			v._weather_chip.accept_event()
			ViewTools.toggle_date(v))
	v._top_right.add_child(v._weather_chip)
	v._quality_badge = HudParts.status_badge("Full data", "good", "gauge")
	v._quality_badge.tooltip_text = "Data quality"
	v._quality_badge.pressed.connect(func() -> void: v.data_quality_requested.emit())
	v._top_right.add_child(v._quality_badge)
	v._fullscreen_btn = HudParts.icon_button("maximize", "Fullscreen (F)")
	v._fullscreen_btn.pressed.connect(func() -> void: toggle_fullscreen(v))
	v._top_right.add_child(v._fullscreen_btn)

	v._hint = PanelContainer.new()
	v._hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hint.add_theme_stylebox_override("panel", HudStyle.panel(20, 16, 8))
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 8)
	hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hint.add_child(hint_row)
	hint_row.add_child(UiIcon.rect("move", 18, UiTheme.INK))
	var hint_label := UiTheme.label(hint_text(v), 14, UiTheme.INK)
	hint_label.name = "Text"
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_row.add_child(hint_label)
	v._fade.add_child(v._hint)
	v._hint_timer = Timer.new()
	v._hint_timer.one_shot = true
	v._hint_timer.wait_time = 6.0
	v._hint_timer.timeout.connect(v._dismiss_hint)
	v._hud.add_child(v._hint_timer)

	v._sheet = PanelContainer.new()
	# 16 at the sides so the three Show chips share one row at 320.
	v._sheet.add_theme_stylebox_override("panel", HudStyle.panel(UiTheme.RADIUS_L, 16, 16))
	UiTheme.add_sheen(v._sheet, UiTheme.RADIUS_L)
	v._fade.add_child(v._sheet)
	# Scrolls only when the inspector is taller than the window (_fit_inspector).
	v._sheet_scroll = ScrollContainer.new()
	v._sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v._sheet_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiTheme.apply_scroll(v._sheet_scroll)
	v._sheet.add_child(v._sheet_scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v._sheet_scroll.add_child(col)
	# Phones and tablets: the grabber on top hides the sheet; on desktop the
	# arc's chevron does. The round tab brings it back.
	v._sheet_grip = Button.new()
	v._sheet_grip.flat = true
	v._sheet_grip.focus_mode = Control.FOCUS_ALL
	v._sheet_grip.custom_minimum_size = Vector2(0, 20)
	v._sheet_grip.tooltip_text = "Hide controls"
	v._sheet_grip.accessibility_name = "Hide controls"
	v._sheet_grip.pressed.connect(func() -> void: toggle_sheet(v))
	v._sheet_grip.draw.connect(func() -> void:
		var g := v._sheet_grip
		g.draw_style_box(UiTheme.style(UiTheme.LINE_STRONG, 3),
			Rect2(roundf((g.size.x - 36.0) / 2.0), roundf((g.size.y - 5.0) / 2.0), 36.0, 5.0)))
	col.add_child(v._sheet_grip)
	v._sheet_tab = HudParts.icon_button("chevron-up", "Show controls")
	v._sheet_tab.visible = false
	v._sheet_tab.pressed.connect(func() -> void: toggle_sheet(v))
	v._fade.add_child(v._sheet_tab)
	v._sun_arc = SunArc.new()
	v._time_label = v._sun_arc.time_label
	v._sun_arc.scrubbed.connect(func(m: float) -> void: ViewConditions.set_time_minutes(v, m))
	v._sun_arc.jump_requested.connect(func(kind: String) -> void: ViewConditions.jump_to(v, kind))
	v._sun_arc.now_requested.connect(v.use_live_time)
	v._sun_arc.lapse_toggled.connect(func() -> void: ViewConditions.toggle_lapse(v))
	v._sun_arc.lapse_speed_requested.connect(func() -> void: ViewConditions.cycle_lapse_speed(v))
	v._sun_arc.day_requested.connect(func() -> void: ViewTools.toggle_date(v))
	v._sun_arc.collapse_requested.connect(func() -> void: toggle_sheet(v))
	col.add_child(v._sun_arc)
	var rule := ColorRect.new()
	rule.color = UiTheme.LINE
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)
	var show_col := VBoxContainer.new()
	show_col.add_theme_constant_override("separation", 4)
	col.add_child(show_col)
	show_col.add_child(UiTheme.text("SHOW", "eyebrow", UiTheme.MUTED))
	var chips := HFlowContainer.new()  # wraps on the narrowest phones
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 0)
	show_col.add_child(chips)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	col.add_child(actions)

	# Drone, gyro (mobile) and zoom on the scene's edge: scroll, pinch and = / -
	# zoom too, so phones leave the buttons out.
	v._zoom_stack = VBoxContainer.new()
	v._zoom_stack.add_theme_constant_override("separation", 8)
	v._fade.add_child(v._zoom_stack)
	v._drone.button = HudParts.icon_button("drone", "Drone (G)")
	v._drone.button.pressed.connect(func() -> void: toggle_drone(v))
	v._zoom_stack.add_child(v._drone.button)
	if OS.has_feature("mobile"):
		v._gyro_btn = HudParts.icon_button("smartphone", "Gyro look")
		v._gyro_btn.pressed.connect(func() -> void: toggle_gyro(v))
		v._zoom_stack.add_child(v._gyro_btn)
	var zoom := PanelContainer.new()
	zoom.name = "Zoom"
	var inset := int((HudParts.SIZE_TOUCH - HudParts.SIZE_HUD) / 2.0)
	var stack_glass := HudParts.glass(int(HudParts.SIZE_HUD / 2.0) - 1, inset)
	stack_glass.set_content_margin_all(0)
	zoom.add_theme_stylebox_override("panel", stack_glass)
	v._zoom_stack.add_child(zoom)
	var zoom_col := VBoxContainer.new()
	zoom_col.add_theme_constant_override("separation", 0)
	zoom.add_child(zoom_col)
	for z in [["plus", "Zoom in (=)", 1.12], ["minus", "Zoom out (−)", 1.0 / 1.12]]:
		var b := HudParts.icon_button(str(z[0]), str(z[1]))
		var clear := StyleBoxEmpty.new()
		for state in ["normal", "pressed", "disabled", "hover", "hover_pressed"]:
			b.add_theme_stylebox_override(state, clear)
		var factor: float = z[2]
		b.pressed.connect(func() -> void: v._rig.handle_zoom(factor))
		zoom_col.add_child(b)

	_build_drone(v)

	v._exit_btn = HudParts.icon_button("arrow-left", "Back to map")
	v._exit_btn.pressed.connect(func() -> void: v.back_requested.emit())
	v._hud.add_child(v._exit_btn)
	v._attribution = HudParts.attribution()
	v._attribution.pressed.connect(func() -> void: v.data_sources_requested.emit())
	v._hud.add_child(v._attribution)

	v._announcer = Announcer.new(2.0)
	v._hud.add_child(v._announcer)
	ViewTools.build(v, chips, actions)

	v._idle_timer = Timer.new()
	v._idle_timer.one_shot = true
	v._idle_timer.wait_time = IDLE_S
	v._idle_timer.timeout.connect(func() -> void: idle(v))
	v._hud.add_child(v._idle_timer)
	_sync_fullscreen(v)

## Drone mode's readout (altitude over the ground and speed, on float
## glass since it carries eyebrow labels) and its touch sticks. The
## sticks sit outside the fading layer so an idle HUD never takes them
## from under a thumb.
static func _build_drone(v: View360) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", HudStyle.panel(UiTheme.RADIUS_M, 16, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	v._drone.altitude = Readout.new("Altitude")
	v._drone.speed = Readout.new("Speed")
	row.add_child(v._drone.altitude)
	row.add_child(v._drone.speed)
	panel.visible = false
	v._drone.panel = panel
	v._fade.add_child(panel)
	v._drone.sticks = DroneSticks.new(v._drone)
	v._drone.sticks.visible = false
	v._hud.add_child(v._drone.sticks)

static func _layer() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# --- Content ---

## Hide or show the controls sheet (phone sheet, desktop inspector).
static func toggle_sheet(v: View360) -> void:
	v._inspector_open = not v._inspector_open
	layout(v)

## A place opened: pill, data-quality badge, attribution and callouts.
static func show_place(v: View360, data: LocationData) -> void:
	var parts := UiTheme.split_place(data.place_name)
	v._place_pill.text = parts[0]
	v._place_box.tooltip_text = data.place_name
	v._place_coords.text = UiTheme.coords(data.latitude, data.longitude).replace("° ", "°\u00a0")
	var q := HudParts.data_quality(data.data_notes)
	HudParts.apply_status_badge(v._quality_badge, q[0], q[1], "gauge")
	v._quality_badge.tooltip_text = q[2]
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
	v._weather_value.visible = true
	v._weather_label.text = label
	v._weather_chip.tooltip_text = "Pick the weather"
	sync_weather_label(v)
	v._weather_chip.visible = true
	v._on_resized.call_deferred()

## At 150% text and above, and on phones, the live chip keeps the value
## only. Re-run on every layout: the window can resize after the weather
## arrived. A picked preset has no value, so its name always stays.
static func sync_weather_label(v: View360) -> void:
	if v._weather_label == null:
		return
	var phone := Responsive.layout_for_size(v.size) == Responsive.Layout.COMPACT
	var show := v._weather_label.text != "" and UiTheme.text_scale < 1.5 and not phone
	if v._weather_pick != 0 and v._weather_label.text != "":
		# The name is all a picked chip says: it stays unless, on a phone,
		# it would run past the gutter after the heading tape.
		show = true
		if phone:
			var name_w := v._weather_label.get_theme_font("font").get_string_size(
				v._weather_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				v._weather_label.get_theme_font_size("font_size")).x
			var pad := float(Responsive.page_padding(Responsive.Layout.COMPACT))
			var chip_w := name_w + 12.0 + 18.0 + 8.0 + 12.0
			var room := v.size.x - pad - (pad + HudParts.SIZE_HUD + 8.0) - (CompassDial.TAPE_W + 24.0) - 8.0
			show = chip_w <= room
	v._weather_label.visible = show

## A weather preset is on: its glyph and name alone, no temperature (a
## live reading beside a picked condition would misreport the place).
## `live` names the real weather for the tooltip ("12 °C Clear"; "" when
## it has not arrived).
static func set_weather_picked(v: View360, label: String, icon_name: String, live: String) -> void:
	v._weather_icon.texture = UiIcon.texture(icon_name, 18)
	v._weather_value.visible = false
	v._weather_label.text = label
	v._weather_label.visible = true
	v._weather_chip.tooltip_text = "Weather you picked" + (". Live: %s" % live if live != "" else "")
	v._weather_chip.visible = true
	v._on_resized.call_deferred()

## No live weather: the chip goes, unless a picked preset holds it.
static func weather_failed(v: View360) -> void:
	if v._weather_chip != null and v._weather_pick == 0:
		v._weather_chip.visible = false

## Re-skin after an accent change. Only the accent-painted parts move,
## so a drag on the sun arc survives the Auto accent's glide.
static func refresh_theme(v: View360) -> void:
	if v._hud == null:
		return
	v._season_btn.restyle()
	v._sun_arc.restyle()
	v._sheet_grip.queue_redraw()
	ViewTools.sync(v)
	v._minimap.restyle()
	v._compass.queue_redraw()
	if v._gyro_btn != null:
		HudParts.apply_icon_button(v._gyro_btn, v._gyro_on)
	HudParts.apply_icon_button(v._drone.button, v._drone.on)
	v._drone.sticks.restyle()

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
	title.position = (v.size - title.size) / 2.0 - v._hud.position
	var target := v._place_box.global_position - v._hud.global_position + Vector2(16, 2)
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
	(v._hint.find_child("Text", true, false) as Label).text = hint_text(v)
	v._hint.modulate.a = 1.0
	v._hint.show()
	if v._hint_timer.is_inside_tree():
		v._hint_timer.start()

static func hint_text(v: View360) -> String:
	if not v._drone.on:
		return "Drag to look around · Pinch to zoom" if OS.has_feature("mobile") \
			else "Drag to look around · Pinch or scroll to zoom"
	if DroneSticks.wanted():
		return "Left stick flies · Right stick turns and climbs"
	return "W A S D to fly · E and Q to climb · Shift to speed up"

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

## The nearby-landmarks list (button and L): up when it is down, down
## when it is up. It lists what stands around the camera now. Opened
## with the key, focus goes to its first row.
static func toggle_nearby(v: View360, by_key: bool = false) -> void:
	var lp := v._landmark_panel
	if lp.is_listing():
		lp.close()
	else:
		lp.open_list(v._callouts.nearest(), v._nearby_pending)
		if by_key:
			lp.focus_list()
	layout(v)

## The Nearby chip is selected while the list is up.
static func sync_nearby(v: View360) -> void:
	if v._nearby_btn != null:
		HudParts.apply_chip(v._nearby_btn, v._landmark_panel.is_listing())

## Nearby articles arrived while the panel is up: the list takes them
## now, or when Back returns to it from a card.
static func refresh_nearby(v: View360) -> void:
	if v._landmark_panel != null and v._landmark_panel.is_open():
		v._landmark_panel.update_list(v._callouts.nearest(), v._nearby_pending)

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
	v._fullscreen_btn.tooltip_text = "Exit fullscreen (F)" if full else "Fullscreen (F)"

## Drone mode on or off: it takes off from the camera, and lands back
## inside the walking area.
static func toggle_drone(v: View360) -> void:
	if v._drone.on:
		v._drone.exit(v)
		ViewTools.say(v, "Drone landed")
	else:
		v._drone.enter(v)
		ViewTools.say(v, "Drone flying")

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
			toggle_sheet(v)
		KEY_L:
			# One press, bare: not a held key repeating, not Cmd/Ctrl/Alt+L.
			if key.echo or key.ctrl_pressed or key.meta_pressed or key.alt_pressed:
				return false
			toggle_nearby(v, true)
		KEY_P, KEY_C, KEY_N, KEY_M, KEY_T, KEY_G:
			# One press, bare: Cmd/Ctrl+C and the like belong to the system.
			if key.echo or key.ctrl_pressed or key.meta_pressed or key.alt_pressed:
				return false
			match key.keycode:
				KEY_P:
					ViewTools.photo(v)
				KEY_C:
					ViewTools.copy_link(v)
				KEY_N:
					ViewTools.toggle_labels(v)
				KEY_M:
					ViewTools.toggle_minimap(v)
				KEY_G:
					toggle_drone(v)
				_:
					ViewConditions.toggle_lapse(v)
		KEY_ESCAPE:
			if v._date_picker.visible:
				v._date_picker.close_picker()
				return true
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
	# Safe areas: nothing under the notch or the home indicator. The HUD
	# layer starts inside them, so everything below measures from its edges.
	_inset_hud(v, Vector2(safe[0], safe[1]))
	w -= safe[0] + safe[2]
	h -= safe[1] + safe[3]
	v._exit_btn.position = Vector2(pad - inset, pad - inset)
	v._exit_btn.size = Vector2(HudParts.SIZE_TOUCH, HudParts.SIZE_TOUCH)

	# Phones keep the weather chip beside the heading tape, so the pill
	# shares the top row with the quality badge only.
	var chip_home: Control = v._tape_row if phone else v._top_right
	if v._weather_chip.get_parent() != chip_home:
		v._weather_chip.reparent(chip_home)
		if not phone:
			chip_home.move_child(v._weather_chip, 0)
	v._tape_row.visible = phone
	sync_weather_label(v)
	# Fullscreen is the window's: not on phones and tablets.
	v._fullscreen_btn.visible = not phone and not OS.has_feature("mobile")
	# Top-right chips first: the pill takes the room left between.
	v._top_right.reset_size()
	var right_w := v._top_right.get_combined_minimum_size().x
	v._top_right.position = Vector2(w - pad - right_w + inset, pad - inset)
	var pill_left := pad + HudParts.SIZE_HUD + 8.0
	var room := w - pad - right_w - 8.0 - pill_left
	# Compass: ring at top-centre, or the tape under the pill on phones.
	v._compass.set_tape(phone)
	if phone:
		if v._compass.get_parent() != v._tape_row:
			v._compass.reparent(v._tape_row)
			v._tape_row.move_child(v._compass, 0)
	else:
		if v._compass.get_parent() != v._fade:
			v._compass.reparent(v._fade)
		# Centred, unless the top-right chips (or, on a phone on its side,
		# the inspector tucked under them) reach that far.
		var ring_limit := v._top_right.position.x
		if inspector and h < 500.0 and v._inspector_open:
			ring_limit = minf(ring_limit, w - pad - float(INSPECTOR_W))
		v._compass.position = Vector2(minf(roundf((w - CompassDial.RING) / 2.0),
			ring_limit - 8.0 - CompassDial.RING), pad - 4.0)
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
	v._sun_arc.set_arc_height(56.0 if h < 500.0 else (72.0 if h < 760.0 or phone else 96.0))
	v._sun_arc.set_compact(bar_w < 380.0 or h < 500.0)
	# The inspector hides by the arc's chevron, the sheet by its grabber.
	v._sun_arc.set_collapsible(inspector)
	v._sheet_grip.visible = not inspector
	v._sheet.visible = v._inspector_open
	v._sheet_tab.visible = not v._inspector_open
	UiIcon.apply(v._sheet_tab, "chevron-left" if inspector else "chevron-up", 22, UiTheme.INK, UiTheme.INK)
	# A phone on its side tucks the inspector under the chips, not the ring.
	var inspector_top := pad + (float(HudParts.SIZE_HUD) if h < 500.0 else float(CompassDial.RING)) + 8.0
	_fit_inspector(v, inspector, h - pad - attr_h - 8.0 - inspector_top)
	v._sheet.custom_minimum_size = Vector2(bar_w, 0)
	v._sheet.reset_size()
	var sheet_h := v._sheet.get_combined_minimum_size().y
	if inspector:
		var top := inspector_top
		v._sheet.position = Vector2(w - pad - bar_w, top)
	else:
		v._sheet.position = Vector2(roundf((w - bar_w) / 2.0), h - pad - attr_h - 8.0 - sheet_h)
	v._sheet.size = Vector2(bar_w, sheet_h)

	_place_landmark_panel(v, lay, inspector, pad, w, h, attr_h, bar_w)

	ViewTools.layout(v, lay, inspector, pad, w, h, attr_h, Rect2(v._sheet.position, v._sheet.size))
	_place_zoom_stack(v, phone, inspector, pad, inset, w, h, attr_h)

	v._hint.reset_size()
	# A sheet in the bar's place (the landmark sheet, the date sheet) covers
	# the spot the round tab would take: the tab waits until it closes.
	var bar_taken: bool = not inspector and ((v._landmark_panel != null and v._landmark_panel.is_open())
		or (v._date_picker != null and v._date_picker.visible))
	v._sheet_tab.visible = not v._inspector_open and not bar_taken
	var tab_y := h - pad - attr_h - 8.0 - HudParts.SIZE_TOUCH
	v._sheet_tab.size = Vector2(HudParts.SIZE_TOUCH, HudParts.SIZE_TOUCH)
	v._sheet_tab.position = Vector2(w - pad - HudParts.SIZE_TOUCH + inset if inspector \
		else roundf((w - HudParts.SIZE_TOUCH) / 2.0), tab_y)
	var hint_bottom := v._sheet.position.y - 12.0 if not inspector else h - pad - attr_h - 12.0
	if v._sheet_tab.visible and not inspector:
		hint_bottom = tab_y - 8.0
	_place_drone(v, inspector, bar_taken, pad, w, h, attr_h, hint_bottom, tab_y)
	if v._drone.panel.visible:
		hint_bottom = v._drone.panel.position.y - 8.0
	v._hint.position = Vector2(roundf((w - v._hint.size.x) / 2.0), hint_bottom - v._hint.size.y)
	_clear_hint(v, inspector, pad)

## A wide hint on a narrow screen slides left, clear of the button stack
## and the inspector.
static func _clear_hint(v: View360, inspector: bool, pad: float) -> void:
	var hint := Rect2(v._hint.position, v._hint.size)
	var blockers: Array[Rect2] = [Rect2(v._zoom_stack.position, v._zoom_stack.size)]
	if inspector and v._sheet.visible:
		blockers.append(Rect2(v._sheet.position, v._sheet.size))
	var limit := INF
	var hit := false
	for b in blockers:
		hit = hit or hint.intersects(b)
		limit = minf(limit, b.position.x)
	if hit:
		v._hint.position.x = maxf(pad, minf(hint.position.x, limit - 8.0 - hint.size.x))
	# No room beside the mini-map on a short screen: above it instead.
	if v._minimap != null and v._minimap.visible \
			and Rect2(v._hint.position, v._hint.size).intersects(v._minimap.get_rect()):
		v._hint.position.y = v._minimap.position.y - 8.0 - hint.size.y

## The inspector scrolls inside `room` when it is taller than that.
static func _fit_inspector(v: View360, inspector: bool, room: float) -> void:
	var scroll := v._sheet_scroll
	var inner := room - v._sheet.get_theme_stylebox("panel").get_minimum_size().y
	var tight := inspector and (scroll.get_child(0) as Control).get_combined_minimum_size().y > inner
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if tight \
		else ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = inner if tight else 0.0
	# Clipping would cut the focus rings of full-width controls.
	scroll.clip_contents = tight

## Move the HUD layer inside the safe area; what must stay full-bleed
## (the edge scrims, things pinned to the scene) moves back out of it.
static func _inset_hud(v: View360, at: Vector2) -> void:
	v._hud.position = at
	v._callouts.position = -at
	for i in v._scrims.size():
		var scrim := v._scrims[i] as Control
		var edge := 0.0 if i == 0 else -160.0  # top scrim first, then bottom
		scrim.offset_left = -at.x
		scrim.offset_right = -at.x
		scrim.offset_top = edge - at.y
		scrim.offset_bottom = edge + 160.0 - at.y
	if v._horizon != null:
		v._horizon.position = -at

## Drone sticks above the controls bar, its round tab and the
## attribution, the right well short of the zoom stack (and the
## inspector beside it); a sheet in the bar's place (landmark, date)
## puts them away until it closes. The readout is centred at `bottom`,
## or above the wells while they show.
static func _place_drone(v: View360, inspector: bool, bar_taken: bool, pad: float, w: float,
		h: float, attr_h: float, bottom: float, tab_y: float) -> void:
	var show := v._drone.on and DroneSticks.wanted() and not bar_taken
	if v._drone.sticks.visible and not show:
		v._drone.sticks.reset()  # a held thumb lets go
	v._drone.sticks.visible = show
	if v._drone.sticks.visible:
		var well := h - pad - attr_h - 8.0
		if v._sheet.visible and not inspector:
			well = minf(well, v._sheet.position.y - 12.0)
		if v._sheet_tab.visible and not inspector:
			well = minf(well, tab_y - 8.0)
		v._drone.sticks.place(pad, v._zoom_stack.position.x - 8.0, well)
		bottom = minf(bottom, well - DroneSticks.SIZE - 8.0)
	if v._drone.panel.visible:
		v._drone.panel.reset_size()
		var ps := v._drone.panel.get_combined_minimum_size()
		v._drone.panel.size = ps
		v._drone.panel.position = Vector2(roundf((w - ps.x) / 2.0), bottom - ps.y)

## The zoom stack (and gyro): bottom-right on the scene's edge; beside
## the inspector, or above the controls sheet, where it would meet them.
## Phones zoom by pinch, so only gyro stays there.
static func _place_zoom_stack(v: View360, phone: bool, inspector: bool, pad: float, inset: float,
		w: float, h: float, attr_h: float) -> void:
	var zoom := v._zoom_stack.get_node("Zoom") as Control
	zoom.visible = not phone
	v._zoom_stack.visible = true  # the drone button stays on phones too
	v._zoom_stack.reset_size()
	var zs := v._zoom_stack.get_combined_minimum_size()
	v._zoom_stack.size = zs
	var at := Vector2(w - pad - zs.x + inset, h - pad - zs.y + inset)
	if phone or Rect2(at, zs).intersects(Rect2(v._attribution.position, v._attribution.size)):
		at.y = h - pad - attr_h - 8.0 - zs.y + inset
	var sheet := Rect2(v._sheet.position, v._sheet.size).grow(8.0)
	if v._sheet.visible and Rect2(at, zs).intersects(sheet):
		if inspector:
			at.x = v._sheet.position.x - 8.0 - zs.x + inset  # beside the inspector
		else:
			at.y = v._sheet.position.y - 8.0 - zs.y + inset  # above the sheet
	v._zoom_stack.position = at

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
