extends SceneTree

## Regression: a second generation must not start while one is already
## generating/building. Overlapping world builds run on two threads
## over shared static material/tree caches and can stall the build
## after the buildings census (observed as "Building world" at 100%
## with no 360 view). godot --headless --script tests/build_guard_test.gd

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# Busy (pipeline running or world building): start must be ignored.
	main._generating = true
	var gen_before: int = main._gen_id
	main._start_generation(48.8566, 2.3522)
	if main._gen_id != gen_before:
		failures.append("start while busy bumped _gen_id (%d -> %d)"
			% [gen_before, main._gen_id])
	if main._loading.visible:
		failures.append("start while busy showed the loading screen")

	main.free()
	if failures.is_empty():
		print("BUILD GUARD OK: second start ignored while busy")
		quit(0)
	else:
		for f in failures:
			printerr("BUILD GUARD FAIL: ", f)
		quit(1)
