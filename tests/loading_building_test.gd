extends SceneTree

## "Building the scene" is the threaded world build after the fetch
## pipeline hits 100%: it must not sit at "100%" (that reads as done
## while Paris builds for ~15-30 s more). The bar follows the build's
## phases instead, with the elapsed seconds beside it. godot --headless --script tests/loading_building_test.gd

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var loading := LoadingScreen.new()
	root.add_child(loading)
	await process_frame
	loading.begin("Paris, France")
	loading.set_progress(1.0, "Done")
	var build := BuildAbort.new()
	loading.set_building(build)
	if loading._stage_label.text != "Building the scene · Distant terrain":
		failures.append("stage should name the scene and its phase, got %s"
			% loading._stage_label.text)
	if loading._progress.value != 0.0:
		failures.append("the bar should restart at 0 for the build")
	# The bar follows the phase, never backwards, never done before the world is.
	var last := 0.0
	for s in BuildAbort.STEPS.size():
		build.step = s
		for i in 600:
			loading._advance_build(1.0 / 60.0)
		var v: float = loading._progress.value
		if v < last or v >= 100.0:
			failures.append("bar at phase %d should rise and stay under 100, got %.1f (was %.1f)"
				% [s, v, last])
		if v < BuildAbort.fraction_before(s) * 100.0:
			failures.append("bar should reach the start of phase %d, got %.1f" % [s, v])
		if loading._stage_label.text != "Building the scene · %s" % BuildAbort.label_of(s):
			failures.append("stage should name phase %d, got %s" % [s, loading._stage_label.text])
		last = v
	if not loading._percent_label.text.ends_with("%") or loading._percent_label.text == "100%":
		failures.append("percent must not read 100%% while building, got %s"
			% loading._percent_label.text)
	loading._on_pulse()
	if not loading._build_row["detail"].text.ends_with(" s"):
		failures.append("the build row should show elapsed seconds, got %s"
			% loading._build_row["detail"].text)
	# Error state: only when nothing could be built.
	var actions := [0, 0]
	loading.retry_requested.connect(func() -> void: actions[0] += 1)
	loading.back_requested.connect(func() -> void: actions[1] += 1)
	loading.show_error("Took too long to build")
	if not loading.is_failed() or loading._cancel_btn.visible or not loading._error_row.visible:
		failures.append("error state should swap Cancel for Try again / Back to map")
	if loading._build_row["dot"].state != StageDot.State.ERROR or not loading._preview.failed:
		failures.append("the failed stage and the lens should turn error")
	for b in loading._error_row.get_children():
		(b as Button).pressed.emit()
	if actions != [1, 1]:
		failures.append("Try again and Back to map should each ask once, got %s" % [actions])
	# A new run clears it; the Weather stage can degrade like the others.
	loading.begin("Paris, France")
	if loading.is_failed() or not loading._cancel_btn.visible:
		failures.append("begin() should clear the error state")
	loading.add_degraded("weather")
	if loading._rows[3]["dot"].state != StageDot.State.DEGRADED:
		failures.append("a missing climate source should degrade the Weather row")
	loading.free()
	if failures.is_empty():
		print("LOADING BUILDING OK: build bar follows phases, not 100%")
		quit(0)
	else:
		for f in failures:
			printerr("LOADING BUILDING FAIL: ", f)
		quit(1)
