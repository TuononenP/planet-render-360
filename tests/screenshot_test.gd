extends SceneTree

## Windowed only: godot --script tests/screenshot_test.gd
## Captures every screen at phone, tablet, and desktop sizes so the
## responsive layouts can be compared against the prototype mockups.

func _init() -> void:
	_run()

func _snap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	var dir := DirAccess.open("user://")
	dir.make_dir("shots")
	img.save_png("user://shots/%s.png" % name)
	print("SHOT ", name, " ", img.get_size())

func _resize(w: int, h: int) -> void:
	root.size = Vector2i(w, h)
	await process_frame
	await process_frame

func _wait_view(main: Node, timeout_sec: float) -> void:
	var start := Time.get_ticks_msec()
	while not main._view.visible \
			and Time.get_ticks_msec() - start < int(timeout_sec * 1000.0):
		await process_frame

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _resize(390, 844)
	await create_timer(0.5).timeout
	await _resize(390, 844)  # first resize can be lost to window creation
	await create_timer(5.0).timeout  # let picker tiles arrive
	await _snap("01-picker-phone")
	# Setting LineEdit.text from code emits no signal, so drive the same
	# handler a real keystroke would.
	main._picker._search.text = "par"
	main._picker._on_search_text_changed("par")
	await process_frame
	await _snap("01d-picker-predictions")
	main._picker._search.text = ""
	await _resize(834, 1112)
	await _snap("01b-picker-tablet")
	await _resize(1280, 800)
	await _snap("01c-picker-desktop")
	await _resize(390, 844)
	main._start_generation(48.8566, 2.3522)
	await create_timer(0.8).timeout
	await _snap("02-loading-phone")
	await _resize(1280, 800)
	await _snap("02b-loading-desktop")
	await _wait_view(main, 60.0)
	await create_timer(0.5).timeout
	await _resize(390, 844)
	await _snap("03-view360-phone")
	await _resize(1280, 800)
	await _snap("03b-view360-desktop")
	# History at phone and desktop (Paris was just recorded by the flow).
	await _resize(390, 844)
	main._history.refresh()
	main._show(main._history)
	await _snap("04-history-phone")
	await _resize(1280, 800)
	await _snap("04b-history-desktop")
	print("SHOTS DONE -> ", ProjectSettings.globalize_path("user://shots"))
	quit(0)
