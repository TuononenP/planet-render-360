extends SceneTree

## "Building world" is the threaded world build after the fetch
## pipeline hits 100%: it must not sit at "100%" (that reads as done
## while Paris builds for ~15-30 s more). It shows an elapsed timer
## instead. godot --headless --script tests/loading_building_test.gd

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var loading := LoadingScreen.new()
	root.add_child(loading)
	await process_frame
	loading.begin("Paris, France")
	loading.set_progress(1.0, "Done")
	loading.set_building()
	if loading._stage_label.text != "Building the scene":
		failures.append("stage should be Building the scene, got %s"
			% loading._stage_label.text)
	if loading._percent_label.text == "100%":
		failures.append("percent must not read 100% while building")
	loading._on_pulse()
	if not loading._percent_label.text.ends_with("s"):
		failures.append("percent should show elapsed seconds, got %s"
			% loading._percent_label.text)
	loading.free()
	if failures.is_empty():
		print("LOADING BUILDING OK: building state shows elapsed, not 100%")
		quit(0)
	else:
		for f in failures:
			printerr("LOADING BUILDING FAIL: ", f)
		quit(1)
