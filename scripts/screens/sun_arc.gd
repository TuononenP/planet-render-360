class_name SunArc
extends VBoxContainer

## The viewer's time-of-day scrubber (design system SunArc): the sun's
## path for the place and date over a horizon line, the track coloured by
## the horizon-* stops so the bar reads as a day, sunrise / noon / sunset
## ticks, and the sun as an accent disc with an ink outline on a soft
## halo (hollow below the horizon); the sun is the only accent fill. The
## header holds the local time in data-l and its UTC offset, Now (outlined,
## off live time), the time-lapse speed and play, and in the desktop
## inspector the chevron that hides the controls. Under it the day chip
## (the season's own day or the picked date; it opens the day and season
## sheet) and the sun's elevation. Four jumps under the arc each show
## their time. Dragging anywhere on the arc scrubs. The view supplies
## minutes since local midnight and the solar values (set_state); the arc
## only emits what the user asked for.

signal scrubbed(minutes: float)
signal jump_requested(kind: String)
signal now_requested
## Time-lapse play / pause and its speed (1×, 2×, 4×).
signal lapse_toggled
signal lapse_speed_requested
## The day chip (opens the day and season sheet) and the inspector's chevron.
signal day_requested
signal collapse_requested

const PAD_X := 18.0
const JUMPS := [["sunrise", "Sunrise"], ["sun", "Noon"], ["sunset", "Sunset"], ["moon", "Night"]]
const SEASON_ICONS := ["flower-2", "sun", "leaf", "snowflake"]  # Spring .. Winter

var minutes := 720.0
var sunrise := 390.0
var sunset := 1170.0
var elevation := 0.0
var live := false
var time_label: Label
var day_btn: Button
var _zone_label: Label
var _elev_label: Label
var _day_chevron: TextureRect
var _collapse_btn: Button
var _play_btn: Button
var _speed_btn: Button
var _lapse_playing := false
var _compact := false
var _now_btn: Button
var _arc: Control
var _jumps: Array[Button] = []
var _arc_height := 96.0

func _init() -> void:
	add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	add_child(head)
	time_label = UiTheme.data_label("12:00", 24, UiTheme.INK, true)
	head.add_child(time_label)
	_zone_label = UiTheme.label("", 14, UiTheme.MUTED)
	_zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_zone_label.visible = false
	head.add_child(_zone_label)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	_now_btn = TouchButton.new()
	_now_btn.text = "Now"
	_now_btn.tooltip_text = "Follow the place's live clock"
	_now_btn.custom_minimum_size = Vector2(0, 32)
	_now_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_now_btn.pressed.connect(func() -> void: now_requested.emit())
	head.add_child(_now_btn)
	_speed_btn = TouchButton.new()
	_speed_btn.text = "1×"
	_speed_btn.tooltip_text = "Time-lapse speed"
	_speed_btn.custom_minimum_size = Vector2(0, 32)
	_speed_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_speed_btn.visible = false
	_speed_btn.pressed.connect(func() -> void: lapse_speed_requested.emit())
	head.add_child(_speed_btn)
	_play_btn = Button.new()
	_play_btn.custom_minimum_size = Vector2(40, 40)
	_play_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_play_btn.pressed.connect(func() -> void: lapse_toggled.emit())
	head.add_child(_play_btn)
	_collapse_btn = Button.new()
	_collapse_btn.custom_minimum_size = Vector2(40, 40)
	_collapse_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_collapse_btn.tooltip_text = "Hide controls (I)"
	_collapse_btn.accessibility_name = "Hide controls"
	_collapse_btn.visible = false
	_collapse_btn.pressed.connect(func() -> void: collapse_requested.emit())
	head.add_child(_collapse_btn)
	# The day chip and the sun's elevation.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	day_btn = TouchButton.new()
	day_btn.custom_minimum_size = Vector2(0, 32)
	day_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	day_btn.tooltip_text = "Pick a day or season"
	day_btn.pressed.connect(func() -> void: day_requested.emit())
	row.add_child(day_btn)
	_day_chevron = TextureRect.new()
	_day_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_chevron.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_day_chevron.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_day_chevron.offset_left = -24.0
	_day_chevron.offset_right = -6.0
	day_btn.add_child(_day_chevron)
	var row_gap := Control.new()
	row_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(row_gap)
	_elev_label = UiTheme.label("", 14, UiTheme.MUTED)
	_elev_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_elev_label)
	_arc = Control.new()
	_arc.custom_minimum_size = Vector2(0, _arc_height)
	_arc.mouse_filter = Control.MOUSE_FILTER_STOP
	_arc.mouse_default_cursor_shape = Control.CURSOR_DRAG
	_arc.tooltip_text = "Drag to move the sun"
	_arc.draw.connect(_draw_arc)
	_arc.gui_input.connect(_on_arc_input)
	add_child(_arc)
	var marks := HBoxContainer.new()
	marks.add_theme_constant_override("separation", 4)
	add_child(marks)
	for j in JUMPS:
		var b := Button.new()
		b.tooltip_text = str(j[1])
		b.custom_minimum_size = Vector2(44, 48)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		b.set_meta("icon", j[0])
		var kind: String = j[0]
		b.pressed.connect(func() -> void: jump_requested.emit(kind))
		marks.add_child(b)
		_jumps.append(b)
	set_day(LocationData.Season.SUMMER, "")
	restyle()

## Height of the drawn arc (shorter on low windows).
func set_arc_height(h: float) -> void:
	_arc_height = h
	_arc.custom_minimum_size.y = h

## A narrow bar keeps the elevation's number only.
func set_compact(compact: bool) -> void:
	_compact = compact
	_elev_label.text = _elev_text()

## The desktop inspector's chevron that hides the controls (I).
func set_collapsible(on: bool) -> void:
	_collapse_btn.visible = on

## The place's UTC offset after the time ("UTC+2", "UTC+5:30"); hidden
## until the offset is known.
func set_zone(hours: float, known: bool) -> void:
	_zone_label.visible = known
	_zone_label.text = zone_text(hours)

static func zone_text(hours: float) -> String:
	var mins := roundi(absf(hours) * 60.0)
	var sgn := "−" if hours < 0.0 else "+"
	if mins == 0:
		return "UTC"
	return "UTC%s%d" % [sgn, mins / 60] if mins % 60 == 0 else "UTC%s%d:%02d" % [sgn, mins / 60, mins % 60]

func set_state(at_minutes: float, rise: float, set_m: float, elev: float, is_live: bool) -> void:
	minutes = fposmod(at_minutes, 1440.0)
	sunrise = rise
	sunset = set_m
	elevation = elev
	live = is_live
	time_label.text = "%02d:%02d" % [int(minutes / 60.0), int(fmod(minutes, 60.0) + 0.001)]
	var deg := roundi(elev)
	_elev_label.text = _elev_text()
	_now_btn.visible = not live and not _lapse_playing
	_label_jumps()
	# An adjustable control for screen readers: "Sun, 14:30, 38° above horizon".
	_arc.accessibility_name = "Sun, %s, %d° %s horizon" % [time_label.text, absi(deg),
		"above" if _is_up() else "below"]
	_arc.queue_redraw()

## The narrow bar keeps the number only (the arc's hollow sun says "below").
func _elev_text() -> String:
	var deg := roundi(elevation)
	var num := "%s%d°" % ["+" if deg > 0 else "", deg]
	return num if _compact else "%s %s" % [num, "above horizon" if _is_up() else "below horizon"]

## The day chip: the picked date ("21 Dec", with its year when it is
## not this one) and the calendar, or the season's name and icon for the
## season's own day (`date_text` "").
func set_day(season: int, date_text: String) -> void:
	var picked := date_text != ""
	day_btn.text = date_text if picked else LocationData.SEASON_NAMES[clampi(season, 0, 3)]
	day_btn.set_meta("icon", "calendar" if picked else SEASON_ICONS[clampi(season, 0, 3)])
	day_btn.accessibility_name = "Day and season: %s" % day_btn.text
	_style_day()

## Sunrise, noon and sunset show their times; Night (the moon's highest
## point, found by the view on the jump) keeps its word.
func _label_jumps() -> void:
	var times := [sunrise, _noon(), sunset]
	var changed := false
	for i in _jumps.size():
		var jump_name := str(JUMPS[i][1])
		var on := false
		if i < times.size():
			var m := fposmod(float(times[i]), 1440.0)
			_jumps[i].text = "%02d:%02d" % [int(m / 60.0), int(fmod(m, 60.0))]
			_jumps[i].accessibility_name = "%s, %s" % [jump_name, _jumps[i].text]
			on = absf(fposmod(minutes - m + 720.0, 1440.0) - 720.0) < 3.0
		else:
			_jumps[i].text = jump_name
			_jumps[i].accessibility_name = jump_name
		if bool(_jumps[i].get_meta("on", false)) != on:
			_jumps[i].set_meta("on", on)
			changed = true
	# Restyle only when the lit jump moves, not on every time-lapse frame.
	if changed:
		_style_jumps()

## Time-lapse playing (the button pauses, the speed shows) and its speed.
func set_lapse(playing: bool, speed: int) -> void:
	_lapse_playing = playing
	_speed_btn.visible = playing
	_speed_btn.text = "%d×" % speed
	_now_btn.visible = not live and not playing
	_style_play()

## Play is ink, never accent: the sun is the instrument's one accent fill.
func _style_play() -> void:
	var icon := "pause" if _lapse_playing else "play"
	_play_btn.tooltip_text = "Pause time-lapse" if _lapse_playing else "Play the day"
	_play_btn.accessibility_name = _play_btn.tooltip_text
	UiIcon.apply(_play_btn, icon, 20, UiTheme.INK, UiTheme.INK)

## The day chip: line-strong outline, the icon, the label and a chevron.
func _style_day() -> void:
	var chip := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL, UiTheme.LINE_STRONG)
	chip.content_margin_left = 10
	chip.content_margin_right = 28
	chip.content_margin_top = 0
	chip.content_margin_bottom = 0
	var lit := chip.duplicate() as StyleBoxFlat
	lit.bg_color = UiTheme.LINE
	day_btn.add_theme_stylebox_override("normal", chip)
	day_btn.add_theme_stylebox_override("hover", lit)
	day_btn.add_theme_stylebox_override("pressed", lit)
	day_btn.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	day_btn.add_theme_font_override("font", UiTheme.sans(600))
	day_btn.add_theme_font_size_override("font_size", 14)
	UiTheme._set_font_colors(day_btn, UiTheme.INK)
	UiIcon.apply(day_btn, str(day_btn.get_meta("icon", "calendar")), 16, UiTheme.INK, UiTheme.INK)
	day_btn.add_theme_constant_override("h_separation", 6)
	_day_chevron.texture = UiIcon.texture("chevron-down", 14)
	_day_chevron.modulate = UiTheme.MUTED

## Jumps: the icon over its time in data-s, ink-muted; the one the clock
## stands on is ink on a line fill.
func _style_jumps() -> void:
	for b in _jumps:
		var on := bool(b.get_meta("on", false))
		var tile := UiTheme.style(UiTheme.LINE if on else Color.TRANSPARENT, UiTheme.RADIUS_S)
		tile.set_content_margin_all(2)
		var lit := tile.duplicate() as StyleBoxFlat
		lit.bg_color = UiTheme.LINE
		b.add_theme_stylebox_override("normal", tile)
		b.add_theme_stylebox_override("hover", lit)
		b.add_theme_stylebox_override("pressed", lit)
		b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_S))
		var ink := UiTheme.INK if on else UiTheme.MUTED
		for key in ["font_color", "font_focus_color"]:
			b.add_theme_color_override(key, ink)
		b.add_theme_color_override("font_hover_color", UiTheme.INK)
		b.add_theme_color_override("font_pressed_color", UiTheme.INK)
		b.add_theme_font_override("font", UiTheme.data(true))
		UiIcon.apply(b, str(b.get_meta("icon")), 18, ink, UiTheme.INK)
		b.add_theme_color_override("icon_hover_color", UiTheme.INK)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("h_separation", 2)

func restyle() -> void:
	UiTheme._set_font_colors(_now_btn, UiTheme.INK)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_speed_btn.add_theme_color_override(key, UiTheme.TEAL)
	for b: Button in [_now_btn, _speed_btn]:
		b.add_theme_font_override("font", UiTheme.sans(600))
		b.add_theme_font_size_override("font_size", 14)
	_speed_btn.add_theme_font_override("font", UiTheme.data(true))
	_style_play()
	UiIcon.apply(_collapse_btn, "chevron-right", 20, UiTheme.MUTED, UiTheme.INK)
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	clear.content_margin_left = 12
	clear.content_margin_right = 12
	clear.content_margin_top = 0
	clear.content_margin_bottom = 0
	var lit := clear.duplicate() as StyleBoxFlat
	lit.bg_color = UiTheme.LINE
	for b: Button in [_now_btn, _speed_btn, _play_btn, _collapse_btn]:
		b.add_theme_stylebox_override("normal", clear)
		b.add_theme_stylebox_override("pressed", lit)
		b.add_theme_stylebox_override("hover", lit)
		b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	# Now is outlined: a quiet way back to the live clock.
	var outlined := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL, UiTheme.LINE_STRONG)
	outlined.content_margin_left = 12
	outlined.content_margin_right = 12
	outlined.content_margin_top = 0
	outlined.content_margin_bottom = 0
	var outlined_lit := outlined.duplicate() as StyleBoxFlat
	outlined_lit.bg_color = UiTheme.LINE
	_now_btn.add_theme_stylebox_override("normal", outlined)
	_now_btn.add_theme_stylebox_override("hover", outlined_lit)
	_now_btn.add_theme_stylebox_override("pressed", outlined_lit)
	_style_day()
	_style_jumps()
	_arc.queue_redraw()

# --- Geometry (the reference rendering's curve, scaled to the width) ---

func _x(m: float) -> float:
	return PAD_X + m / 1440.0 * (_arc.size.x - 2.0 * PAD_X)

func _noon() -> float:
	return (sunrise + sunset) / 2.0

func _y(m: float) -> float:
	var c := _arc_height * 0.46
	var amp := _arc_height / 3.0
	return c - amp * cos((m - _noon()) / 720.0 * PI)

func _is_up() -> bool:
	return elevation > -0.833

func _minutes_at(x: float) -> float:
	var span := maxf(_arc.size.x - 2.0 * PAD_X, 1.0)
	return clampf((x - PAD_X) / span, 0.0, 1.0) * 1439.0

func _on_arc_input(event: InputEvent) -> void:
	var at := -1.0
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		at = (event as InputEventMouseButton).position.x
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT):
		at = (event as InputEventMouseMotion).position.x
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		at = (event as InputEventScreenTouch).position.x
	elif event is InputEventScreenDrag:
		at = (event as InputEventScreenDrag).position.x
	if at >= 0.0:
		scrubbed.emit(_minutes_at(at))
		_arc.accept_event()

## Track colour at minute m: the horizon-* stops as the reference
## gradient places them around sunrise and sunset.
func _track_color(m: float) -> Color:
	var stops := [[0.0, UiTheme.HORIZON_NIGHT], [sunrise - 40.0, UiTheme.HORIZON_NIGHT],
		[sunrise, UiTheme.HORIZON_DAWN], [sunrise + 90.0, UiTheme.HORIZON_DAY],
		[sunset - 90.0, UiTheme.HORIZON_DAY], [sunset - 20.0, UiTheme.AMBER],
		[sunset + 20.0, UiTheme.HORIZON_DUSK], [sunset + 70.0, UiTheme.HORIZON_NIGHT],
		[1440.0, UiTheme.HORIZON_NIGHT]]
	for i in range(1, stops.size()):
		var a: Array = stops[i - 1]
		var b: Array = stops[i]
		if m <= float(b[0]):
			var span := maxf(float(b[0]) - float(a[0]), 0.001)
			return (a[1] as Color).lerp(b[1], clampf((m - float(a[0])) / span, 0.0, 1.0))
	return UiTheme.HORIZON_NIGHT

func _draw_arc() -> void:
	if _arc.size.x < 2.0 * PAD_X + 10.0:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var m := 0.0
	while m <= 1440.0:
		pts.append(Vector2(_x(m), _y(m)))
		cols.append(_track_color(m))
		m += 15.0
	# Dashed horizon line at the sunrise height.
	var hy := clampf(_y(sunrise), 2.0, _arc_height - 4.0)
	var x := PAD_X
	while x < _arc.size.x - PAD_X:
		_arc.draw_line(Vector2(x, hy), Vector2(minf(x + 2.0, _arc.size.x - PAD_X), hy), UiTheme.LINE_STRONG, 1.0)
		x += 6.0
	_arc.draw_polyline(pts, UiTheme.LINE_STRONG, 9.0, true)
	_arc.draw_polyline_colors(pts, cols, 6.0, true)
	# Unlabelled ticks on the horizon: the times live on the jumps below.
	for mark in [sunrise, _noon(), sunset]:
		var mx := _x(clampf(mark, 0.0, 1440.0))
		_arc.draw_line(Vector2(mx, hy - 5.0), Vector2(mx, hy + 5.0), UiTheme.MUTED, 1.5)
	var sun := Vector2(_x(minutes), _y(minutes))
	_arc.draw_circle(sun, 13.0, UiTheme.TEAL_SOFT, true, -1.0, true)
	_arc.draw_circle(sun, 13.0, UiTheme.TEAL, false, 1.0, true)
	if _is_up():
		_arc.draw_circle(sun, 8.0, UiTheme.TEAL, true, -1.0, true)
		_arc.draw_circle(sun, 8.0, UiTheme.INK, false, 2.0, true)
	else:
		_arc.draw_circle(sun, 8.0, UiTheme.BG, true, -1.0, true)
		_arc.draw_circle(sun, 8.0, UiTheme.TEAL, false, 2.0, true)
