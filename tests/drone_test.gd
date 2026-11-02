extends SceneTree

## Drone mode: godot --headless --script tests/drone_test.gd
## The steering, roam edge, hover bob, stick and readout maths, then a
## real View360: G takes off, the sticks fly and climb, the drone keeps
## over the ground and under its ceiling, taps don't walk, and G lands
## back inside the walking area. Offline: the view's fetchers never reach
## the network, and every cache lives in a temp directory.

const CACHE := "user://drone_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	CacheStore.dir_override = CACHE
	PlaceThumb.dir_override = CACHE + "/thumbs"
	DirAccess.make_dir_recursive_absolute(CACHE)
	_maths()
	await _flight()
	_clean(CACHE)
	CacheStore.dir_override = ""
	PlaceThumb.dir_override = ""
	if failures.is_empty():
		print("drone_test: PASS")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)

static func _clean(dir_path: String) -> void:
	for f in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_clean(dir_path.path_join(d))
	DirAccess.remove_absolute(dir_path)

func _flat(lat: float, lon: float, name: String) -> LocationData:
	var flat := LocationData.new()
	flat.grid_size = 8
	flat.heights.resize(64)
	for i in 64:
		flat.heights[i] = 3.0
	flat.place_name = name
	flat.latitude = lat
	flat.longitude = lon
	return flat

func _maths() -> void:
	var vel := Vector2.ZERO
	for i in 120:
		vel = ViewDrone.steer(vel, Vector2(0, -1), 1.0 / 60.0)
	_check(absf(vel.length() - ViewDrone.CRUISE_MPS) < 1.0, "two seconds held reach cruise: %s" % vel)
	_check(vel.y < 0.0 and absf(vel.x) < 0.001, "in the wished direction")
	var boosted := Vector2.ZERO
	for i in 240:
		boosted = ViewDrone.steer(boosted, Vector2(0, -1), 1.0 / 60.0, true)
	_check(absf(boosted.length() - ViewDrone.CRUISE_MPS * ViewDrone.BOOST_MULT) < 1.0,
		"Shift boosts threefold: %s" % boosted.length())
	var drift := vel
	for i in 180:
		drift = ViewDrone.steer(drift, Vector2.ZERO, 1.0 / 60.0)
	_check(drift.length() > 0.0 and drift.length() < vel.length() * 0.05,
		"let go, it drifts to a stop: %s" % drift.length())

	var ground := GroundTruth.new(_flat(60.0, 25.0, "Flat"))
	var here := Vector2(0, -1090)
	_check(ViewDrone.clamp_roam(here, Vector2(0, -1080), ground) == Vector2(0, -1080), "inside the edge it flies")
	var slid := ViewDrone.clamp_roam(here, Vector2(10, -1110), ground)
	_check(slid.length() <= ViewDrone.EDGE_M + 0.01 and slid.x > 5.0,
		"at the edge it slides along: %s" % slid)
	_check(ViewDrone.clamp_roam(here, Vector2(0, -1200), ground).length() <= ViewDrone.EDGE_M + 0.01,
		"never past the edge")
	# Pressing on along the edge glides round it, frame after frame.
	var at := Vector2(0, -ViewDrone.EDGE_M)
	for i in 300:
		at = ViewDrone.clamp_roam(at, at + Vector2(1.0, -0.5), ground)
	_check(at.x > 200.0 and at.length() <= ViewDrone.EDGE_M + 0.01 and at.length() > ViewDrone.EDGE_M - 1.0,
		"pressing out along the edge keeps gliding round it: %s" % at)
	_check(not ViewDrone.can_roam(Vector2(0, 1500), ground) and not ViewDrone.can_roam(Vector2.ZERO, null),
		"no roaming off the ground or without one")

	var was := UiPrefs.reduce_motion
	UiPrefs.reduce_motion = false
	_check(absf(ViewDrone.bob(0.25 / ViewDrone.BOB_HZ) - ViewDrone.BOB_M) < 0.001, "the hover bobs")
	UiPrefs.reduce_motion = true
	_check(ViewDrone.bob(0.25 / ViewDrone.BOB_HZ) == 0.0, "but not under Reduce motion")
	UiPrefs.reduce_motion = was

	_check(DroneSticks.deflection(Vector2(3, 0), 38.0) == Vector2.ZERO, "a stick barely off centre is centred")
	_check(DroneSticks.deflection(Vector2(0, -38), 38.0).is_equal_approx(Vector2(0, -1)), "full up is -1")
	_check(DroneSticks.deflection(Vector2(0, -400), 38.0).is_equal_approx(Vector2(0, -1)), "and never past it")
	var half := DroneSticks.deflection(Vector2(19, 0), 38.0).x
	_check(half > 0.0 and half < 0.5, "half way is eased below half: %s" % half)

	var tower := {"x": 0.0, "z": -400.0, "height": 80.0, "footprint": PackedVector2Array([
		Vector2(-100, -415), Vector2(100, -415), Vector2(100, -385), Vector2(-100, -385)])}
	var shed := {"x": 900.0, "z": 900.0, "height": 4.0, "footprint": PackedVector2Array([
		Vector2(895, 895), Vector2(905, 895), Vector2(905, 905), Vector2(895, 905)])}
	_check(ViewDrone.nearby([tower, shed], ViewDrone.reaches([tower, shed]), Vector2(0, -250), 60.0) == [tower],
		"a wide building's edge counts as near, a far shed doesn't")
	_check(ViewDrone.floor_y([tower], ground, Vector2(0, -400)) > 80.0, "the floor clears the roof")

	var imperial := UiTheme.units_imperial
	UiTheme.units_imperial = false
	_check(UiTheme.speed(15.0) == "54 km/h", "metric speed: " + UiTheme.speed(15.0))
	UiTheme.units_imperial = true
	_check(UiTheme.speed(15.0) == "34 mph", "imperial speed: " + UiTheme.speed(15.0))
	UiTheme.units_imperial = imperial

func _flight() -> void:
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280, 800)
	await process_frame
	view._wiki.offline_mode = true
	view._horizon._fetcher.offline_mode = true
	view._weather.queue_free()
	view._weather = null
	var data := _flat(60.4518, 22.2666, "Testville")
	view.show_location(data)
	await process_frame
	await process_frame
	var press := func(code: Key) -> void:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.pressed = true
		ViewChrome.handle_key(view, ev)

	_check(view._drone.button != null and view._drone.button.tooltip_text == "Drone (G)", "the HUD offers the drone")
	press.call(KEY_G)
	_check(view._drone.on and view._drone.panel.visible, "G takes off and shows the readout")
	_check(view._drone.button.tooltip_text == "Land (G)", "the button now lands")
	_check(view._toast.title_text() == "Drone flying", "and says so")
	_check(ViewChrome.hint_text(view).begins_with("Left stick flies" if DroneSticks.wanted() else "W A S D to fly"),
		"the hint says how to fly: " + ViewChrome.hint_text(view))
	_check(view._drone.sticks.visible == DroneSticks.wanted(), "the sticks show on touch screens only")
	_check(OS.has_feature("mobile") or not DroneSticks.wanted(), "a desktop flies by keyboard")

	# Reflections: a short hop keeps the last capture, a long one retakes it.
	var dt := 1.0 / 30.0
	var hop := func(seconds: float) -> void:
		view._drone.stick_move = Vector2(0, -1)
		for i in int(seconds * 30.0):
			view._drone.process(view, dt)
		view._drone.stick_move = Vector2.ZERO
		for i in 30 * 4:
			view._drone.process(view, dt)
	var probe_was := view._atmos.probe.position
	hop.call(0.4)
	_check(view._atmos.probe.position == probe_was, "a short hop keeps the reflections")
	hop.call(5.0)
	_check(view._atmos.probe.position != probe_was
		and view._atmos.probe.position.distance_to(view._rig.position) < 1.0,
		"a long one re-captures them where it settles")

	var start := view._rig.position
	view._drone.stick_move = Vector2(0, -1)
	for i in 90:
		view._drone.process(view, dt)
	var p := view._rig.position
	var forward := Vector2(-sin(view._rig.yaw), -cos(view._rig.yaw))
	var moved := Vector2(p.x - start.x, p.z - start.z)
	_check(moved.dot(forward) > 20.0, "the left stick flies forward: %s" % moved)
	_check(view._drone.speed.value_text().ends_with("km/h") or view._drone.speed.value_text().ends_with("mph"),
		"the readout shows the speed: " + view._drone.speed.value_text())
	view._drone.stick_move = Vector2.ZERO

	# Climb to the ceiling and come back down to the floor.
	view._drone.stick_aux = Vector2(0, -1)
	for i in 30 * 80:
		view._drone.process(view, dt)
	var agl := view._rig.position.y - view._ground.height_at_world(view._rig.position.x, view._rig.position.z)
	_check(agl <= ViewDrone.AGL_MAX_M + ViewDrone.BOB_M + 0.5 and agl > ViewDrone.AGL_MAX_M - 5.0,
		"the climb stops at the ceiling: %s" % agl)
	view._drone.stick_aux = Vector2(0, 1)
	for i in 30 * 80:
		view._drone.process(view, dt)
	var xz := Vector2(view._rig.position.x, view._rig.position.z)
	_check(view._rig.position.y >= ViewDrone.floor_y(data.buildings, view._ground, xz) - ViewDrone.BOB_M - 0.5,
		"and the descent stops at the floor: %s" % (view._rig.position.y - view._ground.height_at_world(xz.x, xz.y)))
	view._drone.stick_aux = Vector2.ZERO

	# Fly out past the walking area, to the roam edge, low and boosted
	# straight at a tower across the way: never inside it.
	var roof := view._ground.height_at_world(0.0, -400.0) + 80.0
	data.buildings.append({"x": 0.0, "z": -400.0, "height": 80.0, "footprint": PackedVector2Array([
		Vector2(-300, -415), Vector2(300, -415), Vector2(300, -385), Vector2(-300, -385)])})
	view._rig.set_look(0.0, 0.0)
	view._drone.stick_move = Vector2(0, -1)
	var shift := InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.pressed = true
	Input.parse_input_event(shift)
	Input.flush_buffered_events()
	_check(Input.is_key_pressed(KEY_SHIFT), "Shift is held for the boosted run")
	var lowest := INF
	for i in 30 * 120:
		view._drone.process(view, dt)
		var q := view._rig.position
		if absf(q.z + 400.0) <= 15.0 and absf(q.x) <= 300.0:
			lowest = minf(lowest, q.y - roof)
	view._drone.stick_move = Vector2.ZERO
	shift.pressed = false
	Input.parse_input_event(shift)
	Input.flush_buffered_events()
	_check(lowest != INF and lowest >= 1.0, "flying low at a tower clears its roof: %s m" % lowest)
	xz = Vector2(view._rig.position.x, view._rig.position.z)
	_check(xz.length() > View360.IN_PLACE_M and xz.length() <= ViewDrone.EDGE_M + 0.01,
		"the drone roams past the walking area, up to its edge: %s" % xz.length())

	# Phone, controls sheet open and the sticks showing: everything stays
	# on screen, the wells clear of each other and of the drone button.
	view.size = Vector2(390, 844)
	view._inspector_open = true
	DroneSticks.forced = true
	ViewChrome.layout(view)
	_check(view._drone.sticks.visible, "forced, the sticks show")
	var screen := Rect2(Vector2.ZERO, view.size)
	var stack := Rect2(view._zoom_stack.position, view._zoom_stack.size)
	var lw := Rect2(view._drone.sticks.left.position, view._drone.sticks.left.size)
	var rw := Rect2(view._drone.sticks.right.position, view._drone.sticks.right.size)
	var ro := Rect2(view._drone.panel.position, view._drone.panel.size)
	_check(screen.encloses(stack), "the drone button stays on a phone screen: %s" % stack)
	_check(screen.encloses(lw) and screen.encloses(rw), "so do the sticks: %s %s" % [lw, rw])
	_check(not lw.intersects(rw) and not rw.intersects(stack), "the wells clear each other and the button")
	_check(screen.encloses(ro) and not ro.intersects(lw) and not ro.intersects(rw), "the readout sits above the wells: %s" % ro)
	# A short landscape window keeps the side inspector: the drone
	# button stays on screen beside it.
	view.size = Vector2(600, 450)
	ViewChrome.layout(view)
	screen = Rect2(Vector2.ZERO, view.size)
	stack = Rect2(view._zoom_stack.position, view._zoom_stack.size)
	_check(screen.encloses(stack) and not stack.intersects(Rect2(view._sheet.position, view._sheet.size)),
		"a short landscape window keeps the drone button beside the inspector: %s" % stack)
	# Phone with the controls tucked away: the wells clear the round tab;
	# a landmark sheet in the bar's place puts them away.
	view.size = Vector2(390, 844)
	view._inspector_open = false
	ViewChrome.layout(view)
	var tab := Rect2(view._sheet_tab.position, view._sheet_tab.size)
	lw = Rect2(view._drone.sticks.left.position, view._drone.sticks.left.size)
	rw = Rect2(view._drone.sticks.right.position, view._drone.sticks.right.size)
	_check(view._sheet_tab.visible and not lw.intersects(tab) and not rw.intersects(tab),
		"the wells clear the sheet tab: %s %s %s" % [lw, rw, tab])
	view._drone.stick_move = Vector2(0, -1)
	view._landmark_panel.open_list([])
	ViewChrome.layout(view)
	_check(not view._drone.sticks.visible and view._drone.stick_move == Vector2.ZERO,
		"a landmark sheet puts the sticks away and lets go")
	view._landmark_panel.close()
	ViewChrome.layout(view)
	_check(view._drone.sticks.visible, "and they come back when it closes")
	view._inspector_open = true
	DroneSticks.forced = false
	view.size = Vector2(1280, 800)
	ViewChrome.layout(view)

	# A tap on the scene does not walk while flying.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(640, 600)
	view._gui_input(click)
	_check(view._walk._tap_ms < 0, "taps don't walk while flying")

	press.call(KEY_G)
	_check(not view._drone.on and not view._drone.panel.visible, "G lands")
	_check(view._toast.title_text() == "Drone landed", "and says so")
	await create_timer(ViewWalk.GLIDE_MAX_S + 0.5).timeout
	xz = Vector2(view._rig.position.x, view._rig.position.z)
	_check(View360.can_move_in_place(xz, view._ground), "landing comes back inside the walking area: %s" % xz.length())
	_check(view._rig.camera.rotation.z == 0.0, "level again")

	# A new scene opens on foot.
	press.call(KEY_G)
	view.show_location(data)
	_check(not view._drone.on, "a new place opens walking")
	view.queue_free()
	await process_frame
