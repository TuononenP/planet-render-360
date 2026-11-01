class_name SunArc
extends VBoxContainer

## The viewer's time-of-day scrubber (design system SunArc): the sun's
## path for the place and date over a horizon line, the track coloured by
## the horizon-* stops so the bar reads as a day, sunrise / noon / sunset
## ticks, and the sun as an accent disc with an ink outline on a soft
## halo (hollow below the horizon). The header holds the local time in
## data-l and the sun's elevation; jump buttons sit under the arc and
## fold to icons on narrow phones. Dragging anywhere on the arc scrubs.
## The view supplies minutes since local midnight and the solar values
## (set_state); the arc only emits what the user asked for.

signal scrubbed(minutes: float)
signal jump_requested(kind: String)
signal now_requested

const PAD_X := 18.0
const JUMPS := [["sunrise", "Sunrise"], ["sun", "Noon"], ["sunset", "Sunset"], ["moon", "Night"]]

var minutes := 720.0
var sunrise := 390.0
var sunset := 1170.0
var elevation := 0.0
var live := false
var time_label: Label
var _elev_label: Label
var _now_btn: Button
var _arc: Control
var _jumps: Array[Button] = []
var _arc_height := 108.0

func _init() -> void:
	add_theme_constant_override("separation", 4)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	add_child(head)
	time_label = UiTheme.data_label("12:00", 24, UiTheme.INK, true)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(time_label)
	_now_btn = Button.new()
	_now_btn.text = "Now"
	_now_btn.tooltip_text = "Follow the place's live clock"
	_now_btn.custom_minimum_size = Vector2(0, 32)
	_now_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_now_btn.pressed.connect(func() -> void: now_requested.emit())
	head.add_child(_now_btn)
	_elev_label = UiTheme.label("", 14, UiTheme.MUTED)
	_elev_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_elev_label)
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
		b.text = j[1]
		b.tooltip_text = "Jump to %s" % j[1]
		b.custom_minimum_size = Vector2(44, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 14)
		b.set_meta("icon", j[0])
		var kind: String = j[0]
		b.pressed.connect(func() -> void: jump_requested.emit(kind))
		marks.add_child(b)
		_jumps.append(b)
	restyle()

## Height of the drawn arc (shorter on low windows).
func set_arc_height(h: float) -> void:
	_arc_height = h
	_arc.custom_minimum_size.y = h

## Jump buttons show only their icons (the label stays the tooltip).
func set_compact(compact: bool) -> void:
	for i in _jumps.size():
		_jumps[i].text = "" if compact else str(JUMPS[i][1])

func set_state(at_minutes: float, rise: float, set_m: float, elev: float, is_live: bool) -> void:
	minutes = fposmod(at_minutes, 1440.0)
	sunrise = rise
	sunset = set_m
	elevation = elev
	live = is_live
	time_label.text = "%02d:%02d" % [int(minutes / 60.0), int(fmod(minutes, 60.0) + 0.001)]
	var deg := roundi(elev)
	_elev_label.text = "%s%d° %s" % ["+" if deg > 0 else "", deg,
		"above horizon" if _is_up() else "below horizon"]
	_now_btn.visible = not live
	# An adjustable control for screen readers: "Sun, 14:30, 38° above horizon".
	_arc.accessibility_name = "Sun, %s, %d° %s horizon" % [time_label.text, absi(deg),
		"above" if _is_up() else "below"]
	_arc.queue_redraw()

func restyle() -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_now_btn.add_theme_color_override(key, UiTheme.TEAL)
	_now_btn.add_theme_font_override("font", UiTheme.sans(600))
	_now_btn.add_theme_font_size_override("font_size", 14)
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	clear.content_margin_left = 12
	clear.content_margin_right = 12
	var lit := clear.duplicate() as StyleBoxFlat
	lit.bg_color = UiTheme.LINE
	for b: Button in [_now_btn] + _jumps:
		b.add_theme_stylebox_override("normal", clear)
		b.add_theme_stylebox_override("pressed", lit)
		b.add_theme_stylebox_override("hover", lit)
		b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	for b in _jumps:
		for key in ["font_color", "font_focus_color"]:
			b.add_theme_color_override(key, UiTheme.MUTED)
		b.add_theme_color_override("font_hover_color", UiTheme.INK)
		b.add_theme_color_override("font_pressed_color", UiTheme.INK)
		b.add_theme_font_override("font", UiTheme.sans(500))
		UiIcon.apply(b, str(b.get_meta("icon")), 18, UiTheme.MUTED, UiTheme.INK)
		b.add_theme_color_override("icon_hover_color", UiTheme.INK)
		b.add_theme_constant_override("h_separation", 4)
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
	var hy := clampf(_y(sunrise), 2.0, _arc_height - 24.0)
	var x := PAD_X
	while x < _arc.size.x - PAD_X:
		_arc.draw_line(Vector2(x, hy), Vector2(minf(x + 2.0, _arc.size.x - PAD_X), hy), UiTheme.LINE_STRONG, 1.0)
		x += 6.0
	_arc.draw_polyline(pts, UiTheme.LINE_STRONG, 9.0, true)
	_arc.draw_polyline_colors(pts, cols, 6.0, true)
	var font := UiTheme.data(true)
	for mark in [sunrise, _noon(), sunset]:
		var mx := _x(clampf(mark, 0.0, 1440.0))
		_arc.draw_line(Vector2(mx, _arc_height - 22.0), Vector2(mx, _arc_height - 17.0), UiTheme.MUTED, 1.5)
		var text := "%02d:%02d" % [int(fposmod(mark, 1440.0) / 60.0), int(fmod(fposmod(mark, 1440.0), 60.0))]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_arc.draw_string(font, Vector2(mx - w / 2.0, _arc_height - 3.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiTheme.MUTED)
	var sun := Vector2(_x(minutes), _y(minutes))
	_arc.draw_circle(sun, 13.0, UiTheme.TEAL_SOFT, true, -1.0, true)
	_arc.draw_circle(sun, 13.0, UiTheme.TEAL, false, 1.0, true)
	if _is_up():
		_arc.draw_circle(sun, 8.0, UiTheme.TEAL, true, -1.0, true)
		_arc.draw_circle(sun, 8.0, UiTheme.INK, false, 2.0, true)
	else:
		_arc.draw_circle(sun, 8.0, UiTheme.BG, true, -1.0, true)
		_arc.draw_circle(sun, 8.0, UiTheme.TEAL, false, 2.0, true)
