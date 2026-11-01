class_name CompassDial
extends Control

## Heading indicator (design system Compass): the 80pt `ring` at
## top-centre on tablet and desktop, the `tape` (a strip with cardinal
## labels) under the place pill on phones. HUD glass with ink ticks, an
## accent index at the view direction and a data-s readout ("214° SW").
## Tapping asks the view to turn north. Redraws only when the rounded
## heading changes.

signal north_requested

const CARDINALS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const RING := 80.0
const TAPE_W := 240.0
const TAPE_H := 52.0

var tape := false
var heading := 0.0
var _shown := -1

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "Turn to north"
	_resize()

func set_tape(on: bool) -> void:
	if on != tape:
		tape = on
		_resize()
		queue_redraw()

func set_heading(deg: float) -> void:
	heading = fposmod(deg, 360.0)
	var r := roundi(heading) % 360
	if r != _shown:
		_shown = r
		accessibility_name = "Heading %s" % readout()
		queue_redraw()

func readout() -> String:
	return "%d° %s" % [roundi(heading) % 360, CARDINALS[roundi(heading / 45.0) % 8]]

func _resize() -> void:
	custom_minimum_size = Vector2(TAPE_W + 24.0, TAPE_H) if tape else Vector2(RING, RING)
	size = custom_minimum_size

func _gui_input(event: InputEvent) -> void:
	var tapped := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event.is_action_pressed("ui_accept"))
	if tapped:
		north_requested.emit()
		accept_event()

func _draw() -> void:
	if tape:
		_draw_tape()
	else:
		_draw_ring()
	if has_focus():
		var focus := UiTheme._focus_ring(UiTheme.RADIUS_PILL if not tape else UiTheme.RADIUS_M)
		draw_style_box(focus, Rect2(Vector2.ZERO, size))

func _draw_ring() -> void:
	var c := size / 2.0
	draw_circle(c, 38.0, UiTheme.GLASS_FILL, true, -1.0, true)
	draw_circle(c, 38.0, UiTheme.GLASS_EDGE, false, 1.0, true)
	var r := 30.0
	for d in range(0, 360, 15):
		var rad := deg_to_rad(float(d) - heading - 90.0)
		var major := d % 90 == 0
		var r1 := r - (7.0 if major else 4.0)
		var dir := Vector2(cos(rad), sin(rad))
		draw_line(c + dir * r1, c + dir * r, UiTheme.INK if major else Color(UiTheme.INK, 0.55),
			1.5 if major else 1.0, true)
	var nr := deg_to_rad(-heading - 90.0)
	var bold := UiTheme.sans(700)
	var npos := c + Vector2(cos(nr), sin(nr)) * 20.0
	var nw := bold.get_string_size("N", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(bold, npos + Vector2(-nw / 2.0, 3.5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UiTheme.INK)
	# Accent index at the view direction (top), outlined in sky-000.
	var tri := PackedVector2Array([Vector2(c.x, 10.0), Vector2(c.x + 5.0, 2.0), Vector2(c.x - 5.0, 2.0)])
	draw_colored_polygon(tri, UiTheme.TEAL)
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), UiTheme.SKY_000, 1.0, true)
	var font := UiTheme.data(true)
	var text := "%d°" % (roundi(heading) % 360)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, c + Vector2(-w / 2.0, 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiTheme.INK)

func _draw_tape() -> void:
	var box := HudParts.glass(UiTheme.RADIUS_M)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var left := (size.x - TAPE_W) / 2.0
	var span := 90.0
	var font := UiTheme.data(true)
	var a := ceilf((heading - span) / 5.0) * 5.0
	while a <= heading + span:
		var x := left + TAPE_W / 2.0 + (a - heading) * (TAPE_W / (2.0 * span))
		var n := roundi(fposmod(a, 360.0)) % 360
		var major := n % 45 == 0
		draw_line(Vector2(x, 10.0 if major else 14.0), Vector2(x, 20.0),
			UiTheme.INK if major else Color(UiTheme.INK, 0.55), 1.5 if major else 1.0)
		if major:
			var label := CARDINALS[int(n / 45.0)]
			var f := UiTheme.data(true) if n != 0 else UiTheme.sans(700)
			var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			draw_string(f, Vector2(x - w / 2.0, 32.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiTheme.INK)
		a += 5.0
	var cx := left + TAPE_W / 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 5.0, 4.0), Vector2(cx + 5.0, 4.0), Vector2(cx, 10.0)]), UiTheme.TEAL)
	var text := readout()
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, Vector2(cx - tw / 2.0, size.y - 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiTheme.INK)
