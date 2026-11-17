extends SceneTree

## Drone flight frame times: where the hitches come from while flying.
## Windowed (the dummy renderer uploads nothing), off-screen, never on top:
##   tools/godot_bg.sh --path . --script tools/drone_flight_profile.gd \
##     --position 4000,4000 -- [--preset=2] [--place=helsinki] [--seconds=15]
##     [--stream_seconds=40] [--circle=0 to fly only the streaming legs]
##
## Opens the place through the real app flow (the user's caches), takes
## off and flies the drone with its own controls (the left stick held
## forward, Shift for boost) round a 600 m circle, at 100 m and at
## 350 m over the ground, cruising then boosting. Per leg it prints the
## frame-time spread, and every frame over SLOW_MS with what moved that
## frame: the tree LOD rings re-emitted (trees), the near class map
## uploaded (near), the drone re-gathered its nearby buildings (gather)
## or re-measured its floor (floor). Then it times those jobs on their
## own at the last position (TIME lines). Streaming stays off round the
## circle, inside the detailed ground; two last legs fly straight east
## with it on (stream: the streamer changed state, swap: a new world).

const PLACE_TIMEOUT_S := 600.0
const SLOW_MS := 25.0
const RADIUS_M := 600.0

var _view: View360

func _init() -> void:
	_run.call_deferred()

func _args() -> Dictionary:
	var a := {"preset": "2", "place": "helsinki", "seconds": "15", "stream_seconds": "40", "circle": "1"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	return a

func _run() -> void:
	var a := _args()
	var row: Dictionary = {}
	for r in PresetViews.ROWS:
		if str(r["id"]) == str(a["place"]):
			row = r
	if row.is_empty():
		printerr("DRONE no place ", a["place"])
		quit(2)
		return
	RenderSettings.path_override = "user://drone-profile-settings-%d.json" % OS.get_process_id()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.capture_mode = true
	root.size = Vector2i(1280, 800)
	await create_timer(0.5).timeout
	root.size = Vector2i(1280, 800)
	for child in main.get_children():
		if child is OnboardingScreen:
			child.queue_free()
	main._settings.preset = int(a["preset"])
	_view = main._view
	_view._governor.set_process(false)  # the preset stays pinned
	_view._streamer.enabled = false
	main._picker.selected_name = str(row["name"])
	var start := Time.get_ticks_msec()
	main._start_generation(float(row["lat"]), float(row["lon"]))
	while (main._generating or not _view.visible) and Time.get_ticks_msec() - start < int(PLACE_TIMEOUT_S * 1000.0):
		await process_frame
	if main._generating or not _view.visible:
		printerr("DRONE FAIL: no view")
		quit(1)
		return
	main._notice.visible = false
	_view._streamer.enabled = false
	print("DRONE open %s p%d in %.1f s, %d buildings" % [row["id"], int(a["preset"]),
		(Time.get_ticks_msec() - start) / 1000.0, _view._data.buildings.size()])
	# Settle: the first frames after opening are the build's, not the flight's.
	await create_timer(4.0).timeout
	var secs := float(a["seconds"])
	for agl in ([100.0, 350.0] if a["circle"] == "1" else []):
		_take_off(agl)
		await create_timer(2.0).timeout
		for boost in [false, true]:
			await _leg("agl%d_%s" % [int(agl), "boost" if boost else "cruise"], secs, boost)
		if _view._drone.on:
			_view._drone.exit(_view, false)
	# Straight east with streaming on, as the app flies: the world swaps
	# in under the drone (swap) and the streamer fetches and builds
	# meanwhile (stream).
	_view._streamer.enabled = true
	for boost in [false, true]:
		_take_off(120.0)
		await _leg("stream_%s" % ("boost" if boost else "cruise"), float(a["stream_seconds"]), boost, false)
	_view._streamer.enabled = false
	_time_jobs()
	print("DRONE DONE")
	quit(0)

## Up at `agl` metres on the circle, facing along it.
func _take_off(agl: float) -> void:
	var rig := _view._rig
	var p := Vector2(RADIUS_M, 0.0)
	rig.position = Vector3(p.x, _view._ground.height_at_world(p.x, p.y) + agl, p.y)
	rig.set_look(0.0, -0.25)
	_view._drone.enter(_view)
	_view._drone._agl = agl
	_view._drone._resync = false

## Flies the circle for `seconds`, the drone steering itself.
func _leg(tag: String, seconds: float, boost: bool, circle: bool = true) -> void:
	var drone := _view._drone
	var rig := _view._rig
	_shift(boost)
	drone.stick_move = Vector2(0.0, -1.0)
	var times := PackedFloat32Array()
	var slow: Array = []
	var counts := {"trees": 0, "near": 0, "gather": 0, "floor": 0, "stream": 0, "swap": 0}
	var begin := Time.get_ticks_usec()
	var last := begin
	var prev := _marks()
	var vp := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	while Time.get_ticks_usec() - begin < int(seconds * 1e6):
		# Face along the circle (counter-clockwise round the centre).
		var here := Vector2(rig.position.x, rig.position.z)
		var tangent := Vector2(-here.y, here.x).normalized() if circle else Vector2(1.0, 0.0)
		var yaw := atan2(-tangent.x, -tangent.y)
		rig.set_look(yaw, rig.pitch)
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		times.append(ms)
		var marks := _marks()
		var what: Array[String] = []
		for k in counts:
			if marks[k] != prev[k]:
				counts[k] += 1
				what.append(k)
		prev = marks
		if ms > SLOW_MS:
			# Script (process), render-thread CPU and GPU ms, and the
			# streamer's phase: F fetching/building, R ready, I idle, D degraded;
			# +h handing off, +r revealing.
			var st: WorldStreamer = _view._streamer
			var phase: String = "IFRD"[st.state]
			if st._handoff.busy():
				phase += "h"
			if st._reveal.active():
				phase += "r"
			slow.append("%.0f@%.1fs[%s|p%.0f c%.0f g%.0f %s]" % [ms, (now - begin) / 1e6, ",".join(what),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				RenderingServer.viewport_get_measured_render_time_cpu(vp),
				RenderingServer.viewport_get_measured_render_time_gpu(vp), phase])
	drone.stick_move = Vector2.ZERO
	_shift(false)
	var sorted := times.duplicate()
	sorted.sort()
	var at := func(q: float) -> float:
		return sorted[clampi(int(q * (sorted.size() - 1)), 0, sorted.size() - 1)]
	print("DRONE leg %s frames=%d p50=%.1f p95=%.1f p99=%.1f max=%.1f slow=%d speed=%.0f m/s events=%s" % [
		tag, times.size(), at.call(0.5), at.call(0.95), at.call(0.99), sorted[-1], slow.size(),
		drone._vel.length(), JSON.stringify(counts)])
	print("DRONE slow %s %s" % [tag, " ".join(slow)])
	# Drift to a stop before the next leg.
	await create_timer(2.0).timeout

## What has moved: each changes when its job ran.
func _marks() -> Dictionary:
	var v := _view
	return {
		"trees": v._tree_lod.centre() if v._tree_lod != null else Vector2.INF,
		"near": v._near_window.centre() if v._near_window != null else Vector2.INF,
		"gather": v._drone._near_at,
		"floor": v._drone._floor_here,
		"stream": v._streamer.state,
		"swap": v._generated.get_instance_id() if is_instance_valid(v._generated) else 0,
	}

func _shift(down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SHIFT
	ev.physical_keycode = KEY_SHIFT
	ev.pressed = down
	Input.parse_input_event(ev)

## Each suspect job run on its own at the eye, timed (ms), 5 runs each.
func _time_jobs() -> void:
	var v := _view
	var eye := Vector2(v._rig.position.x, v._rig.position.z)
	var data := v._data
	var drone := v._drone
	var spans := ViewDrone.reaches(data.buildings)
	var near := ViewDrone.nearby(data.buildings, spans, eye, View360.CLEAR_RADIUS_M + ViewDrone.NEAR_REFRESH_M
		+ ViewDrone.CRUISE_MPS * ViewDrone.BOOST_MULT * ViewDrone.LOOKAHEAD_S)
	_time("reaches", func() -> void: ViewDrone.reaches(data.buildings))
	_time("nearby", func() -> void: ViewDrone.nearby(data.buildings, spans, eye, 258.0))
	_time("floor_x2 (%d near)" % near.size(), func() -> void:
		ViewDrone.floor_y(near, v._ground, eye)
		ViewDrone.floor_y(near, v._ground, eye + Vector2(80, 0)))
	var tl := v._tree_lod
	if tl != null and is_instance_valid(tl._set):
		var a := TreeLod.assign(tl._st, eye)
		_time("tree_assign (worker)", func() -> void: TreeLod.assign(tl._st, eye))
		_time("tree_emit (%d groups)" % (a["groups"] as Dictionary).size(), func() -> void:
			TreeLod.emit(tl._set, tl._st, a, v._quality_preset))
	var nw := v._near_window
	if nw != null:
		var img := nw._tex.get_image()
		if img != null:
			_time("near_upload %dpx" % img.get_width(), func() -> void: nw._tex.update(img))
	drone._near_at = Vector2.INF

func _time(label: String, job: Callable) -> void:
	var best := INF
	var total := 0.0
	for i in 5:
		var t0 := Time.get_ticks_usec()
		job.call()
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		best = minf(best, ms)
		total += ms
	print("DRONE TIME %-28s best=%.2f ms mean=%.2f ms" % [label, best, total / 5.0])
