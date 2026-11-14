class_name DroneSticks
extends Control

## The two on-screen sticks for touch screens: the left flies, or walks
## while the drone is landed (up is forward), the right turns (sideways)
## and, flying, climbs (up). Each is
## a round HUD glass well with a thumb that follows the finger and
## springs back on release; the thumb takes the accent fill while held.
## The layer itself passes input through, so only touches that start on
## a stick are the stick's and the rest still turn the view. Each stick
## writes its deflection into the drone while it flies, else into
## walking (ViewDrone / ViewWalk stick_move and stick_aux).

const SIZE := 120.0
const THUMB := float(HudParts.SIZE_TOUCH)
## Deflection under this fraction of the reach reads as centred.
const DEAD_ZONE := 0.12

var left: Stick
var right: Stick

## Tests and captures show the sticks without a touch screen.
static var forced := false

## Whether the sticks are offered: on touch screens only; the keyboard
## flies elsewhere. The project emulates touch from the mouse, which
## makes every desktop report a touchscreen, so that report alone
## doesn't count.
static func wanted() -> bool:
	return forced or OS.has_feature("mobile") or (DisplayServer.is_touchscreen_available()
		and not Input.is_emulating_touch_from_mouse())

## Stick output (-1..1 per axis) for a thumb `offset` px from the centre
## of a well whose thumb can travel `reach` px: a dead zone, then eased
## so small moves stay fine.
static func deflection(offset: Vector2, reach: float) -> Vector2:
	if reach <= 0.0:
		return Vector2.ZERO
	var m := minf(offset.length() / reach, 1.0)
	if m <= DEAD_ZONE:
		return Vector2.ZERO
	var k := (m - DEAD_ZONE) / (1.0 - DEAD_ZONE)
	return offset.normalized() * pow(k, 1.5)

func _init(drone: ViewDrone, walk: ViewWalk = null) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	left = Stick.new(func(d: Vector2) -> void:
		if drone.on or walk == null:
			drone.stick_move = d
		else:
			walk.stick_move = d, "Fly")
	right = Stick.new(func(d: Vector2) -> void:
		if drone.on or walk == null:
			drone.stick_aux = d
		else:
			walk.stick_aux = d, "Turn and climb")
	add_child(left)
	add_child(right)

## Names the sticks for the mode: flying or walking (no climbing on foot).
func set_flying(flying: bool) -> void:
	left.accessibility_name = "Fly" if flying else "Walk"
	right.accessibility_name = "Turn and climb" if flying else "Turn"

## Centres both thumbs and stops the drone's stick input.
func reset() -> void:
	left.release()
	right.release()

func restyle() -> void:
	left.queue_redraw()
	right.queue_redraw()

## Places the wells with their bottom edge at `bottom`, the left one from
## `left_x` and the right one ending at `right_x`.
func place(left_x: float, right_x: float, bottom: float) -> void:
	left.position = Vector2(left_x, bottom - SIZE)
	right.position = Vector2(right_x - SIZE, bottom - SIZE)

class Stick extends Control:
	var _out: Callable
	var _touch := -1
	var _mouse := false
	var _thumb := Vector2.ZERO

	func _init(out: Callable, label: String) -> void:
		_out = out
		custom_minimum_size = Vector2(DroneSticks.SIZE, DroneSticks.SIZE)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		accessibility_name = label

	func reach() -> float:
		return (DroneSticks.SIZE - DroneSticks.THUMB) / 2.0

	func release() -> void:
		_touch = -1
		_mouse = false
		_move_to(Vector2.ZERO)

	func _move_to(offset: Vector2) -> void:
		_thumb = offset.limit_length(reach())
		_out.call(DroneSticks.deflection(_thumb, reach()))
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var centre := size / 2.0
		if event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed and _touch < 0:
				_touch = st.index
				_move_to(st.position - centre)
			elif not st.pressed and st.index == _touch:
				release()
			accept_event()
		elif event is InputEventScreenDrag:
			var sd := event as InputEventScreenDrag
			if sd.index == _touch:
				_move_to(sd.position - centre)
			accept_event()
		elif _touch < 0 and event is InputEventMouseButton \
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			# A mouse on a touch-screen laptop (touches also arrive as mouse
			# events, so those are left to the touch branch above).
			_mouse = (event as InputEventMouseButton).pressed
			if _mouse:
				_move_to((event as InputEventMouseButton).position - centre)
			else:
				release()
			accept_event()
		elif _mouse and event is InputEventMouseMotion:
			_move_to((event as InputEventMouseMotion).position - centre)
			accept_event()

	func _draw() -> void:
		var centre := size / 2.0
		var r := DroneSticks.SIZE / 2.0
		draw_circle(centre, r, UiTheme.GLASS_FILL)
		draw_arc(centre, r - 0.5, 0.0, TAU, 64, UiTheme.GLASS_EDGE, 1.0, true)
		var held := _touch >= 0 or _mouse
		var t := centre + _thumb
		var tr := DroneSticks.THUMB / 2.0 - 2.0
		draw_circle(t, tr, UiTheme.TEAL if held else Color(UiTheme.INK, 0.22))
		draw_arc(t, tr - 0.5, 0.0, TAU, 48, UiTheme.GLASS_EDGE, 1.0, true)
