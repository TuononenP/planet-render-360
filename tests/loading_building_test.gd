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
	# Imagery tiles move the row count and the bar through the stage's quarter.
	loading.begin("Paris, France")
	loading.set_stage(1, "Imagery", "in_progress")
	loading.set_stage_progress(1, 0, 169)
	loading.set_stage_progress(1, 84, 169)
	var half: float = loading._progress.value
	if loading._rows[1]["detail"].text != "84 / 169 tiles":
		failures.append("imagery row should count tiles, got %s" % loading._rows[1]["detail"].text)
	if absf(half - (1.0 + 84.0 / 169.0) / 4.0 * 100.0) > 0.01:
		failures.append("bar should sit inside the imagery quarter, got %.2f" % half)
	loading.set_stage_progress(1, 9, 49)  # lower-zoom retry restarts its count
	if loading._progress.value < half:
		failures.append("the bar must not go backwards on a retry")
	loading.set_stage_progress(0, 5, 10)  # not the active stage: ignored
	if loading._rows[0]["detail"].text != "":
		failures.append("progress for an inactive stage should be ignored")
	# A layer fetched alongside earlier stages shows its own fetch time even
	# when the stage had nothing left to wait for.
	loading.begin("Paris, France")
	for i in [1, 3]:
		loading.set_stage(i, "", "in_progress")
		loading.set_stage_took(i, 2.4)
		loading.set_stage(i, "", "done")
		if loading._rows[i]["detail"].text != "2.4 s":
			failures.append("row %d should show its fetch time, got %s" % [i, loading._rows[i]["detail"].text])
	# The active stage counts the seconds its layer has been fetching (from
	# the run's start), then gives way to the real time, or to nothing.
	loading.begin("Paris, France")
	loading.set_stage(0, "", "in_progress")
	loading._run_started_msec -= 7000
	loading.set_stage(0, "", "done")
	loading.set_stage(2, "", "in_progress")
	if loading._rows[2]["detail"].text != "7 s":
		failures.append("the active buildings row should count from the run start, got '%s'"
			% loading._rows[2]["detail"].text)
	loading._run_started_msec -= 2000
	loading._on_pulse()
	if loading._rows[2]["detail"].text != "9 s":
		failures.append("the counter should keep running on each pulse, got '%s'"
			% loading._rows[2]["detail"].text)
	loading.set_stage_took(2, 9.4)
	loading.set_stage(2, "", "done")
	if loading._rows[2]["detail"].text != "9.4 s":
		failures.append("the finished row should show its real time, got '%s'"
			% loading._rows[2]["detail"].text)
	loading.set_stage(3, "", "in_progress")
	loading._on_pulse()
	loading.set_stage(3, "", "done")  # nothing left to wait for: no stale count
	if loading._rows[3]["detail"].text != "":
		failures.append("a stage done with no time should drop its count, got '%s'"
			% loading._rows[3]["detail"].text)
	# Tiles and "Nearby · 450 m" are never overwritten by the count.
	loading.begin("Paris, France")
	loading.set_stage(1, "", "in_progress")
	loading._run_started_msec -= 5000
	loading.set_stage_progress(1, 3, 49)
	loading._on_pulse()
	if loading._rows[1]["detail"].text != "3 / 49 tiles":
		failures.append("tile counts should stay over the clock, got '%s'" % loading._rows[1]["detail"].text)
	loading.set_layer_detail("map", "Nearby · 450 m", false)
	loading.set_stage(2, "", "in_progress")
	loading._on_pulse()
	if loading._rows[2]["detail"].text != "Nearby · 450 m":
		failures.append("a layer's source should stay over the clock, got '%s'" % loading._rows[2]["detail"].text)
	# The preset being built is named under the coordinates.
	loading.begin("Paris, France", 48.8622, 2.2887, RenderSettings.Preset.ULTRA)
	if not loading._quality_row.visible or loading._quality_label.text != "Quality · Ultra":
		failures.append("loading should name the quality, got '%s'" % loading._quality_label.text)
	loading.begin("Paris, France")
	if loading._quality_row.visible:
		failures.append("no preset given: no quality line")
	loading.free()
	if failures.is_empty():
		print("LOADING BUILDING OK: build bar follows phases, not 100%")
		quit(0)
	else:
		for f in failures:
			printerr("LOADING BUILDING FAIL: ", f)
		quit(1)
