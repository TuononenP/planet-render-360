extends SceneTree

## Generation timeout (offline): godot --headless --script tests/generation_timeout_test.gd
## A place that takes longer than Main.generation_timeout_s (10 minutes in
## the app) is stopped: the run is superseded, the user is back on the
## picker with a plain message, and a world build in progress is asked to
## stop at its next stage. A stopped build returns [] and is never cached.

func _init() -> void:
	_run()

func _flat() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.FAST)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.seed_value = 7
	data.latitude = 48.8566
	data.longitude = 2.3522
	return data

func _run() -> void:
	await process_frame
	var failures: Array[String] = []
	if not is_equal_approx(load("res://scripts/main.gd").GENERATION_TIMEOUT_S, 600.0):
		failures.append("the app timeout should be 10 minutes")

	# Builder: an abort request stops build_world at the next stage.
	var stop := BuildAbort.new()
	stop.requested = true
	var partial := TerrainBuilder.build_world(_flat(), null, stop)
	var names: Array[String] = []
	for c in partial.get_children():
		names.append(str(c.name))
	if partial.get_child_count() != 1:
		failures.append("aborted build should stop after the far terrain, got %s" % [names])
	partial.free()
	# Per build: another build's request never stops this one.
	var other := TerrainBuilder.build_world(_flat(), null, BuildAbort.new())
	if other.get_child_count() <= 1:
		failures.append("a build without its own stop request should run every stage")
	other.free()

	# Main: a run still going after the timeout returns to the picker.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.generation_timeout_s = 0.2
	main.abort_grace_s = 0.6
	main._set_generating(true)
	main._building_world = true
	var abort := BuildAbort.new()
	main._build_abort = abort
	main._gen_id += 1
	var gen: int = main._gen_id
	main._arm_timeout(gen)
	await create_timer(0.5).timeout
	if main._gen_id == gen:
		failures.append("timed-out run should be superseded (gen id bumped)")
	if not main._picker.visible:
		failures.append("timed-out run should return to the picker")
	if main._picker._render_status.text != main.TIMEOUT_MESSAGE \
			or not main._picker._render_status.visible:
		failures.append("picker should tell the user the place timed out")
	if not abort.requested:
		failures.append("a world build in progress should be asked to stop")
	# A stage that never returns: the picker is released after the grace.
	if not main._generating:
		failures.append("picker should show Finishing… until the build stops or the grace ends")
	await create_timer(0.6).timeout
	if main._generating or main._build_abort != null:
		failures.append("a build that never stops must not lock Explore past abort_grace_s")
	# A finished run never fires its old timer.
	main._building_world = false
	main._set_generating(false)
	main._picker.set_render_status("")
	main._gen_id += 1
	main._arm_timeout(main._gen_id)
	await create_timer(0.5).timeout
	if main._picker._render_status.text != "":
		failures.append("a run that already finished must not report a timeout")
	main.queue_free()
	await process_frame

	if failures.is_empty():
		print("GENERATION TIMEOUT OK: 10 min cap, picker message, per-build stop at the next stage, grace release")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)
