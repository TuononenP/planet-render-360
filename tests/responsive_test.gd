extends SceneTree

## Headless responsive test: godot --headless --script tests/responsive_test.gd
## Covers the mobile-first contract: breakpoint thresholds, the picker
## switching stacked <-> split (and filling its height, no dead band),
## the layout override, history grid columns, and readable type floors.

func _init() -> void:
	_run()

func _fail(failures: Array[String], msg: String) -> void:
	failures.append(msg)

func _run() -> void:
	var failures: Array[String] = []

	# Startup window: full screen at the real screen size, with stretch
	# that expands the logical viewport to fill it responsively.
	if int(ProjectSettings.get_setting("display/window/size/mode", 0)) \
			!= DisplayServer.WINDOW_MODE_FULLSCREEN:
		_fail(failures, "app should start full screen (display/window/size/mode)")
	if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "canvas_items" \
			or str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) != "expand":
		_fail(failures, "stretch should be canvas_items/expand to fill any screen")

	# Breakpoint thresholds
	if Responsive.layout_for_width(390.0) != Responsive.Layout.COMPACT:
		_fail(failures, "390pt should be COMPACT")
	if Responsive.layout_for_width(639.0) != Responsive.Layout.COMPACT:
		_fail(failures, "639pt should be COMPACT")
	if Responsive.layout_for_width(640.0) != Responsive.Layout.MEDIUM:
		_fail(failures, "640pt should be MEDIUM")
	if Responsive.layout_for_width(1099.0) != Responsive.Layout.MEDIUM:
		_fail(failures, "1099pt should be MEDIUM")
	if Responsive.layout_for_width(1100.0) != Responsive.Layout.EXPANDED:
		_fail(failures, "1100pt should be EXPANDED")
	if Responsive.history_columns(Responsive.Layout.COMPACT) != 1 \
			or Responsive.history_columns(Responsive.Layout.MEDIUM) != 2 \
			or Responsive.history_columns(Responsive.Layout.EXPANDED) != 3:
		_fail(failures, "history columns should be 1/2/3 by layout")
	if Responsive.page_padding(Responsive.Layout.COMPACT) >= Responsive.page_padding(Responsive.Layout.EXPANDED):
		_fail(failures, "padding should grow with layout")

	# Readable floors at the 390pt design frame
	var field := UiTheme.field("x")
	if field.get_theme_font_size("font_size") < 16:
		_fail(failures, "field font below 16pt")
	if field.custom_minimum_size.y < 48.0:
		_fail(failures, "field touch target below 48pt")
	var primary := UiTheme.primary_button("x")
	if primary.custom_minimum_size.y < 52.0:
		_fail(failures, "primary button below 52pt")

	# Picker: compact fills the screen, wide splits, override forces compact
	var picker := MapPicker.new()
	root.add_child(picker)
	picker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picker.size = Vector2(390, 844)
	picker._on_resized()
	await process_frame
	await process_frame
	if picker.effective_layout() != Responsive.Layout.COMPACT:
		_fail(failures, "picker at 390pt should be COMPACT, got %d" % picker.effective_layout())
	if picker._canvas == null or picker._canvas.size.y < 240.0:
		_fail(failures, "compact map should fill leftover height, got %s" % str(picker._canvas.size))
	var history_bottom := picker._history_btn.get_global_rect().end.y
	if history_bottom < 700.0:
		_fail(failures, "compact picker leaves dead space: history ends at y=%.0f of 844" % history_bottom)
	if picker._stack.size.x > 390.0:
		_fail(failures, "compact picker column should fit 390pt, got %s" % str(picker._stack.size))
	if picker._layout_btn.visible:
		_fail(failures, "layout override should hide on compact (its min width overflows phones)")

	picker.size = Vector2(1280, 800)
	picker._on_resized()
	await process_frame
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "picker at 1280pt should be EXPANDED, got %d" % picker.effective_layout())
	if not picker._split.visible or picker._stack.visible:
		_fail(failures, "wide picker should show split, hide stack")
	if picker._canvas.size.x < 600.0:
		_fail(failures, "wide map should take the larger pane, got %s" % str(picker._canvas.size))

	picker._on_layout_selected(1)  # force Compact
	await process_frame
	if picker.effective_layout() != Responsive.Layout.COMPACT or picker._split.visible:
		_fail(failures, "Compact override should force stacked layout on a wide window")
	picker._on_layout_selected(0)  # back to Auto
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "Auto should restore EXPANDED on a wide window")

	# Quick picks: one tap selects the place and centres the map on it
	if picker._quick_box == null:
		_fail(failures, "picker should offer one-tap quick picks")
	else:
		var quick_row := picker._quick_box.get_child(1) as HBoxContainer
		if quick_row == null or quick_row.get_child_count() < 3:
			_fail(failures, "quick picks should offer at least 3 places")
		else:
			(quick_row.get_child(2) as Button).pressed.emit()  # Banff
			await process_frame
			if abs(picker._lat - 51.1789) > 0.01 or picker.selected_name != "Banff, Canada":
				_fail(failures, "quick pick should select Banff, got %f / %s" % [picker._lat, picker.selected_name])
			if abs(picker._canvas.centre_lat - 51.1789) > 0.01:
				_fail(failures, "quick pick should centre the map on Banff, got %f" % picker._canvas.centre_lat)
	picker.queue_free()

	# History grid follows the window width
	var history := HistoryScreen.new()
	root.add_child(history)
	history.set_anchors_preset(Control.PRESET_TOP_LEFT)
	history.size = Vector2(390, 844)
	history._on_resized()
	await process_frame
	if history._list.columns != 1:
		_fail(failures, "history at 390pt should be 1 column")
	history.size = Vector2(834, 1112)
	history._on_resized()
	await process_frame
	if history._list.columns != 2:
		_fail(failures, "history at 834pt should be 2 columns")
	history.size = Vector2(1280, 800)
	history._on_resized()
	await process_frame
	if history._list.columns != 3:
		_fail(failures, "history at 1280pt should be 3 columns")
	history.queue_free()

	# Loading card is capped and centred on wide screens, full-bleed on phones
	var loading := LoadingScreen.new()
	root.add_child(loading)
	loading.set_anchors_preset(Control.PRESET_TOP_LEFT)
	loading.size = Vector2(1280, 800)
	loading._on_resized()
	await process_frame
	await process_frame
	if loading._card.size.x > 680.0 or loading._card.size.x < 400.0:
		_fail(failures, "wide loading card should be capped near 640pt, got %s" % str(loading._card.size))
	if loading._rows.size() != GenerationPipeline.STAGES.size():
		_fail(failures, "loading should show one row per pipeline stage")
	loading.begin("Banff, Canada")
	loading.set_progress(0.6, "Placing landmarks")
	if loading._percent_label == null or loading._percent_label.text != "60%":
		_fail(failures, "loading should show a live percent, got %s" % str(loading._percent_label.text if loading._percent_label else null))
	loading.set_stage(0, GenerationPipeline.STAGES[0], "in_progress")
	if loading._active_index != 0:
		_fail(failures, "loading should track the active stage for its pulse")
	# Whole card fits the window at phone, desktop, and short-window
	# heights: every stage row and Cancel stay on screen (the preview
	# shrinks first). Regression: the card used to overflow ~630pt
	# windows and clip its lower half.
	for fit_size in [Vector2(390, 844), Vector2(1280, 800), Vector2(1024, 630), Vector2(390, 667)]:
		loading.size = fit_size
		loading._on_resized()
		# The preview fit converges over a few deferred passes.
		for _i in 6:
			await process_frame
		var card_rect := loading._card.get_global_rect()
		if card_rect.position.y < -1.0 or card_rect.end.y > fit_size.y + 1.0:
			_fail(failures, "loading card should fit %s, got %s" % [str(fit_size), str(card_rect)])
		var cancel_rect := loading._cancel_btn.get_global_rect()
		if cancel_rect.end.y > fit_size.y + 1.0:
			_fail(failures, "loading Cancel should stay on screen at %s, got %s" % [str(fit_size), str(cancel_rect)])
	loading.size = Vector2(390, 844)
	loading._on_resized()
	for _i in 6:
		await process_frame
	if not loading._preview.visible:
		_fail(failures, "loading preview should stay visible at phone height 844")
	loading.queue_free()

	# Main scene: the whole screen chain relayouts when the window
	# size changes (as it does entering full screen on screens of
	# different sizes).
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920, 1080)
	await process_frame
	await process_frame
	if main._picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "main at 1920pt should be EXPANDED, got %d" % main._picker.effective_layout())
	if main._picker.size != Vector2(1920, 1080):
		_fail(failures, "picker should fill the window, got %s" % str(main._picker.size))
	main.size = Vector2(390, 844)
	await process_frame
	await process_frame
	if main._picker.effective_layout() != Responsive.Layout.COMPACT:
		_fail(failures, "main at 390pt should be COMPACT, got %d" % main._picker.effective_layout())
	main.queue_free()
	# queue_free is deferred; let it run before quitting.
	await process_frame
	await process_frame

	if failures.is_empty():
		print("RESPONSIVE OK: breakpoints, stacked/split picker, layout override, history grid, type floors")
		quit(0)
	else:
		for f in failures:
			printerr("RESPONSIVE FAIL: ", f)
		quit(1)
