class_name ViewInput
extends RefCounted

## Mouse, wheel, trackpad magnify, touch pinch/drag, and wake-input handling
## delegated from View360 so view_360.gd stays compact under the 1000-line gate.

static func gui_input(v: View360, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			v._rig.handle_zoom(1.12)
			v.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			v._rig.handle_zoom(1.0 / 1.12)
			v.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			v._walk.cancel_tap()
			v._rig.reset_zoom()
			v.accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and not v._drone.on:
			if mb.pressed:
				v._walk.press(mb.position)
			else:
				v._walk.release(v, mb.position)
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		v._magnify_accum *= mg.factor
		if v._magnify_accum > 1.15:
			v._magnify_accum = 1.0
			v._rig.handle_zoom(1.18)
		elif v._magnify_accum < 0.87:
			v._magnify_accum = 1.0
			v._rig.handle_zoom(1.0 / 1.18)
		v.accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			v._touches[st.index] = st.position
			if v._touches.size() == 2:
				v._pinch_base = touch_distance(v._touches)
				v._walk.cancel_tap()
			elif not v._drone.on:
				v._walk.press(st.position)
		else:
			if v._touches.size() == 1 and not v._drone.on:
				v._walk.release(v, st.position)
			v._touches.erase(st.index)
		v.accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if v._touches.has(sd.index):
			v._touches[sd.index] = sd.position
		if v._touches.size() >= 2:
			var dist := touch_distance(v._touches)
			if v._pinch_base > 1.0 and dist > 1.0:
				v._rig.handle_zoom(dist / v._pinch_base)
				v._pinch_base = dist
		else:
			v._rig.handle_drag(sd.relative)
			v._on_look_changed()
		v.accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		v._rig.handle_drag(event.relative)
		v._on_look_changed()

static func global_input(v: View360, event: InputEvent) -> void:
	if OS.has_environment("PR360_TRACE_MOVEMENT") and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_E, KEY_Q]:
		var owner := v.get_viewport().gui_get_focus_owner()
		print("MOVEMENT TRACE key=", event.keycode, " physical=", event.physical_keycode,
			" held=", Input.is_key_pressed(event.keycode), " free=", ViewWalk.keys_free(v),
			" focus=", owner, " ctrl=", Input.is_key_pressed(KEY_CTRL),
			" alt=", Input.is_key_pressed(KEY_ALT), " meta=", Input.is_key_pressed(KEY_META),
			" visible=", v.is_visible_in_tree(), " drone=", v._drone.on,
			" position=", v._rig.position if v._rig != null else "no rig")
	if v.is_visible_in_tree() and (event is InputEventMouseMotion or event is InputEventMouseButton \
			or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventKey):
		ViewChrome.wake(v)

static func touch_distance(touches: Dictionary) -> float:
	if touches.size() < 2:
		return 0.0
	var pts: Array = touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])
