extends SceneTree

## Exit + far-pan tile test: godot --headless --script tests/exit_tile_test.gd
## Offline. Guards two reported bugs:
## 1) no clear way to exit the (full-screen) app from the picker, and
## 2) moving the map far from the default area loads slowly because
##    downloads for the old area stayed ahead of / occupied the pool
##    slots for the new area. The fetcher must drop and cancel stale
##    work and serve the kept tiles in the caller's (centre-first)
##    order.

func _run() -> void:
	var failures: Array[String] = []

	# --- 1) Picker offers a clear, tappable Exit that asks to exit ---
	var picker := MapPicker.new()
	root.add_child(picker)
	picker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picker.size = Vector2(390, 844)
	await process_frame
	await process_frame
	var exit_btn: Button = picker.get("_exit_btn")
	if exit_btn == null:
		failures.append("picker should have an exit button (_exit_btn)")
	else:
		# Icon-only in the nav pill: the name lives in the tooltip.
		if not exit_btn.tooltip_text.contains("Exit"):
			failures.append("exit button should be named Exit, got tooltip '%s'" % exit_btn.tooltip_text)
		if not exit_btn.visible or exit_btn.custom_minimum_size.y < 48.0:
			failures.append("exit button should be visible with a >=48pt touch target")
		var got_exit := [false]
		picker.exit_requested.connect(func() -> void: got_exit[0] = true)
		exit_btn.pressed.emit()
		if not got_exit[0]:
			failures.append("pressing the exit button should emit exit_requested")
	picker.queue_free()
	await process_frame

	# Main wires the picker's exit request to its quit handler.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	if not main.has_method("_request_exit"):
		failures.append("Main should handle exit via _request_exit")
	elif not (main._picker as MapPicker).exit_requested.is_connected(
			Callable(main, "_request_exit")):
		failures.append("Main should connect picker.exit_requested to _request_exit")
	main.queue_free()
	await process_frame
	await process_frame

	# --- 2a) Queued tiles are served in the caller's order ---
	# Queue edge-first, then keep only two in centre-first order: the
	# dropped tile goes and the survivors are reordered centre-first.
	var offline := TileFetcher.new()  # not added: no pool, queue inspectable
	var a := Vector3i(15, 30000, 12000)
	var b := Vector3i(15, 30001, 12000)
	var c := Vector3i(15, 30002, 12000)
	offline.request_tile(a.x, a.y, a.z)
	offline.request_tile(b.x, b.y, b.z)
	offline.request_tile(c.x, c.y, c.z)
	offline.discard_queued_except([c, a])
	if offline._queue != [c, a]:
		failures.append("kept queue should be reordered to caller order [c, a], got %s" % str(offline._queue))
	offline.free()

	# --- 2b) In-flight downloads for a stale area are cancelled ---
	var live := TileFetcher.new()
	root.add_child(live)
	await process_frame
	for i in 6:
		live.request_tile(15, 31000 + i, 13000)  # fills every pool slot
	if live._pending.size() < 6:
		failures.append("expected 6 tiles in flight, got %d" % live._pending.size())
	live.discard_queued_except([Vector3i(15, 2000, 2000)])
	if not live._pending.is_empty():
		failures.append("stale in-flight tiles should be cancelled, pending=%s" % str(live._pending.keys()))
	for conn in live._pool:
		if conn.busy:
			failures.append("cancelled downloads should free their pool slot")
			break
	live.queue_free()
	await process_frame

	if failures.is_empty():
		print("EXIT_TILE OK: clear exit button wired to quit; stale tiles cancelled, queue centre-first")
		quit(0)
	else:
		for f in failures:
			printerr("EXIT_TILE FAIL: ", f)
		quit(1)

func _init() -> void:
	_run()
