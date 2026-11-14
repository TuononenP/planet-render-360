class_name DroneSticks
extends Control

## The on-screen sticks for touch screens: the left flies, or walks
## while the drone is landed (up is forward), the right turns (sideways)
## and, flying, climbs (up), and the look stick beside it turns and tilts
## the view freely (up looks up), flying or walking. Each is
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
## Radians per second a fully pushed look stick tilts the view.
const PITCH_RATE := 1.0
## Room between two wells side by side, or stacked.
const GAP := 12.0

var left: Stick
var right: Stick
var look: Stick
## Look stick deflection, applied to the view each frame.
var look_dir := Vector2.ZERO
var _view: View360

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

func _init(drone: ViewDrone, walk: ViewWalk = null, view: View360 = null) -> void:
	_view = view
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
	look = Stick.new(func(d: Vector2) -> void: look_dir = d, "Look around")
	look.ticks = true
	add_child(left)
	add_child(right)
	add_child(look)

## The look stick's turn and tilt (yaw, pitch) after `delta` seconds
## from `yaw_pitch`: right turns right, up looks up.
static func look_step(yaw_pitch: Vector2, d: Vector2, delta: float) -> Vector2:
	return yaw_pitch + Vector2(-d.x * ViewDrone.YAW_RATE, -d.y * PITCH_RATE) * delta

func _process(delta: float) -> void:
	if look_dir == Vector2.ZERO or _view == null or _view._rig == null or not is_visible_in_tree():
		return
	var to := look_step(Vector2(_view._rig.yaw, _view._rig.pitch), look_dir, delta)
	_view._rig.set_look(to.x, to.y)
	_view._on_look_changed()

## Names the sticks for the mode: flying or walking (no climbing on foot).
func set_flying(flying: bool) -> void:
	left.accessibility_name = "Fly" if flying else "Walk"
	right.accessibility_name = "Turn and climb" if flying else "Turn"

## Whether a thumb is on any stick (a still thumb sends no input, but
## the HUD shouldn't idle out from under it).
func held() -> bool:
	return visible and (left.is_held() or right.is_held() or look.is_held())

## A view hidden, or the app left, under a thumb never hears it lift:
## the sticks let go then, so nothing flies or turns on its own after.
func _notification(what: int) -> void:
	if (what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()) \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset()

## Centres every thumb and stops the sticks' input.
func reset() -> void:
	left.release()
	right.release()
	look.release()

func restyle() -> void:
	left.queue_redraw()
	right.queue_redraw()
	look.queue_redraw()

## Places the wells with their bottom edge at `bottom`, the left one from
## `left_x` and the right one ending at `right_x`; the look well goes
## left of the right one where that leaves the left well clear, else
## above it while its top stays under `ceiling`, else it is put away
## (dragging still looks). Returns the top of the wells.
func place(left_x: float, right_x: float, bottom: float, ceiling := -INF) -> float:
	left.position = Vector2(left_x, bottom - SIZE)
	right.position = Vector2(right_x - SIZE, bottom - SIZE)
	var beside := right.position.x - GAP - SIZE
	var above := right.position.y - GAP - SIZE
	look.visible = beside >= left_x + SIZE + GAP or above >= ceiling
	if not look.visible:
		look.release()
		return bottom - SIZE
	if beside >= left_x + SIZE + GAP:
		look.position = Vector2(beside, right.position.y)
		return bottom - SIZE
	look.position = Vector2(right.position.x, above)
	return above

class Stick extends Control:
	var _out: Callable
	var _touch := -1
	var _mouse := false
	var _thumb := Vector2.ZERO
	## Small marks round the rim tell the look well from the others.
	var ticks := false

	func _init(out: Callable, label: String) -> void:
		_out = out
		custom_minimum_size = Vector2(DroneSticks.SIZE, DroneSticks.SIZE)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		accessibility_name = label

	func is_held() -> bool:
		return is_visible_in_tree() and (_touch >= 0 or _mouse)

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
		if ticks:
			for i in 4:
				var dir := Vector2.from_angle(i * PI / 2.0)
				draw_line(centre + dir * (r - 10.0), centre + dir * (r - 4.0),
					Color(UiTheme.INK, 0.45), 2.0, true)
		var held := _touch >= 0 or _mouse
		var t := centre + _thumb
		var tr := DroneSticks.THUMB / 2.0 - 2.0
		draw_circle(t, tr, UiTheme.TEAL if held else Color(UiTheme.INK, 0.22))
		draw_arc(t, tr - 0.5, 0.0, TAU, 48, UiTheme.GLASS_EDGE, 1.0, true)
