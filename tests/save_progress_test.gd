extends SceneTree

## Save for offline's progress bar: godot --headless --script tests/save_progress_test.gd
## One bar over download, build and write: it only moves forward, keeps
## drifting inside a long step, and never passes the end of its step.

func _init() -> void:
	var failures: Array[String] = []
	var p := SaveProgress.new()
	p.rows = 4
	var last := 0.0
	for i in 200:
		p.tick(0.1)
		if p.shown < last:
			failures.append("the bar went back at tick %d" % i)
		last = p.shown
	if p.shown <= 0.0 or p.shown >= SaveProgress.DOWNLOAD_END / 4.0:
		failures.append("a stalled first row should drift inside its slice, got %.3f" % p.shown)
	p.imagery_fraction = 0.5
	var tile_floor := SaveProgress.DOWNLOAD_END * 0.5 / 4.0
	if not is_equal_approx(p.floor_at(), tile_floor):
		failures.append("imagery tiles should contribute to download progress")
	p.imagery_fraction = 0.0
	p.rows_done = 4
	p.phase = SaveProgress.Phase.BUILD
	p.build_step = BuildAbort.Step.BUILDINGS
	p.tick(0.1)
	var floor_b := SaveProgress.DOWNLOAD_END + (SaveProgress.BUILD_END - SaveProgress.DOWNLOAD_END) \
		* BuildAbort.fraction_before(BuildAbort.Step.BUILDINGS)
	if p.shown <= last or p.shown >= floor_b:
		failures.append("the build should catch up smoothly to its step, got %.3f" % p.shown)
	for i in 600:
		p.tick(0.1)
	var ceil_b := SaveProgress.DOWNLOAD_END + (SaveProgress.BUILD_END - SaveProgress.DOWNLOAD_END) \
		* BuildAbort.fraction_before(BuildAbort.Step.BUILDINGS + 1)
	if p.shown >= ceil_b or p.shown < floor_b + 0.5 * (ceil_b - floor_b):
		failures.append("a long step should drift most of the way, not past it: %.3f in [%.3f, %.3f)" % [p.shown, floor_b, ceil_b])
	p.phase = SaveProgress.Phase.WRITE
	for i in 600:
		p.tick(0.1)
	if p.shown < SaveProgress.BUILD_END or p.shown >= 1.0:
		failures.append("writing should sit between %.2f and 1.0, got %.3f" % [SaveProgress.BUILD_END, p.shown])
	if p.phase_text() == "" or p.percent() > 99:
		failures.append("write text/percent wrong: '%s' %d" % [p.phase_text(), p.percent()])
	if failures.is_empty():
		print("SAVE PROGRESS OK: forward only, drifts inside a step, never past it")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)
