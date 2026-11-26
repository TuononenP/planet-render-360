extends SceneTree

## StreamSteering + PostpassGate.leave_subtree tests:
##   tools/godot_bg.sh --headless --path . --script tests/stream_steering_test.gd

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	var st := StreamSteering.new()
	# 1. Brief reverse near centre does not immediately drop a READY world.
	_check(not st.check_stale(true, false, 0.5), "0.5 s reverse holds READY world")
	_check(not st.check_stale(true, false, 0.5), "1.0 s reverse still holds READY world")
	_check(st.check_stale(true, false, 0.3), "1.3 s reverse drops READY world")
	# Off-both-squares drops immediately.
	_check(st.check_stale(true, true, 0.01), "off-both-squares drops immediately")
	# Reset when no longer stale.
	_check(not st.check_stale(true, false, 0.9), "partial reverse accumulates")
	_check(not st.check_stale(false, false, 0.1), "turning back forward clears timer")
	_check(not st.check_stale(true, false, 0.9), "timer restarted from zero")

	# 2. Angular hysteresis (55 deg cone): gentle 30 deg curve never counts as veer.
	var to_north := Vector2(0, -1000)
	var gentle := Vector2(sin(deg_to_rad(30.0)), -cos(deg_to_rad(30.0))) * 30.0
	var sharp := Vector2(sin(deg_to_rad(75.0)), -cos(deg_to_rad(75.0))) * 30.0
	_check(not StreamSteering.diverged(gentle, to_north), "30 deg curve stays within cone")
	_check(StreamSteering.diverged(sharp, to_north), "75 deg turn diverges past cone")

	# 3. BUILD-phase abort protection: never cancel once fetch finished (in_build = true).
	_check(not StreamSteering.allow_veer_drop(10.0, true, true, sharp, to_north),
		"veer never aborts a generation already in BUILD phase")
	_check(not StreamSteering.allow_veer_drop(2.0, true, false, sharp, to_north),
		"2.0 s veer during FETCH does not drop yet")
	_check(StreamSteering.allow_veer_drop(4.5, true, false, sharp, to_north),
		"4.5 s sharp veer during FETCH drops")
	_check(StreamSteering.allow_veer_drop(3.2, false, false, sharp, to_north),
		"3.2 s sharp veer when READY drops")

	# 4. Drop cooldown prevents immediate thrash restarts unless near edge.
	st.note_drop()
	_check(st.cooling_down(false), "cooling down right after drop")
	_check(not st.cooling_down(true), "near_edge bypasses cooldown")
	st.tick_cooldown(StreamSteering.DROP_COOLDOWN_S + 0.1)
	_check(not st.cooling_down(false), "cooldown expires after DROP_COOLDOWN_S")

	# 5. PostpassGate.leave_subtree releases slot held by a child of a cancelled pipeline.
	PostpassGate.reset()
	var pipe := Node.new()
	var child := Node.new()
	pipe.add_child(child)
	var started := [false]
	PostpassGate.enter(child, func() -> void: started[0] = true, func(_r: String) -> void: pass)
	_check(started[0] and PostpassGate.holds(child), "child holds PostpassGate slot")
	PostpassGate.leave_subtree(pipe)
	_check(not PostpassGate.holds(child), "leave_subtree immediately releases slot")
	pipe.free()
	PostpassGate.reset()

	if _failures.is_empty():
		print("STREAM STEERING PASS")
		quit(0)
	else:
		for f in _failures:
			printerr("STREAM STEERING FAIL: ", f)
		quit(1)
