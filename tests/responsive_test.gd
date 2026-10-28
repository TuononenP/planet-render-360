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
	# Night Atlas: the map is full-bleed and the sheet is anchored to
	# the bottom edge, so no band of dead space sits below it.
	var sheet_bottom := picker._sheet.get_global_rect().end.y
	if sheet_bottom < 800.0:
		_fail(failures, "compact sheet should sit on the bottom edge: ends at y=%.0f of 844" % sheet_bottom)
	if picker._canvas.size.y < 800.0:
		_fail(failures, "compact map should be full-bleed, got %s" % str(picker._canvas.size))
	if not picker._sheet_cols.vertical:
		_fail(failures, "phone sheet should stack its columns")
	if picker._history_btn.get_global_rect().end.y > 120.0:
		_fail(failures, "nav icons should sit in the top bar on a phone")
	if picker._stack.size.x > 390.0:
		_fail(failures, "compact picker column should fit 390pt, got %s" % str(picker._stack.size))
	if not picker._layout_btn.visible:
		_fail(failures, "layout switcher should stay visible on compact so the choice is reversible")

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
	# Regression: forcing Compact hid the layout switcher itself, so the
	# choice could not be undone from the UI. The switcher must stay
	# visible in every forced layout, and switching back through the
	# actual control must restore the automatic layout.
	if not picker._layout_btn.visible:
		_fail(failures, "layout switcher should stay visible while Compact is forced")
	picker._layout_btn.item_selected.emit(0)  # back to Auto via the control
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "Auto should restore EXPANDED on a wide window")
	picker._on_layout_selected(2)  # force Wide
	await process_frame
	if picker.effective_layout() != Responsive.Layout.MEDIUM or picker._split.visible \
			or picker._sheet_cols.vertical:
		_fail(failures, "Wide override should force the tablet two-column sheet on a wide window")
	if not picker._layout_btn.visible:
		_fail(failures, "layout switcher should stay visible while Wide is forced")
	picker._layout_btn.item_selected.emit(0)  # back to Auto via the control
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "Auto should restore EXPANDED after Wide")

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
			# Tokyo quick pick must visibly stay selected (regression:
			# chips were momentary, so the tap left no active state).
			(quick_row.get_child(4) as Button).pressed.emit()  # Tokyo
			await process_frame
			var tokyo_chip := quick_row.get_child(4) as Button
			if abs(picker._lat - 35.6762) > 0.01 or picker.selected_name != "Tokyo, Japan":
				_fail(failures, "quick pick should select Tokyo, got %f / %s" % [picker._lat, picker.selected_name])
			if not tokyo_chip.button_pressed:
				_fail(failures, "Tokyo chip should stay pressed after tapping it")
			var tokyo_bg: Color = (tokyo_chip.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
			if tokyo_bg != UiTheme.TEAL:
				_fail(failures, "Tokyo chip should use the selected (accent) style, got %s" % str(tokyo_bg))
			if (quick_row.get_child(0) as Button).button_pressed:
				_fail(failures, "only the tapped quick pick should stay pressed")
			# A manual map pick clears the quick-pick selection.
			picker._on_picked(48.8566, 2.3522)
			await process_frame
			if tokyo_chip.button_pressed:
				_fail(failures, "manual map pick should clear the Tokyo selection")

	# Hover contrast: text must stay readable on every hover box
	# (regression: OptionButton had no font_hover_color, so Godot's
	# default made the layout label nearly invisible on hover).
	if picker._layout_btn.get_theme_color("font_hover_color") != UiTheme.INK:
		_fail(failures, "layout button hover text should stay light ink on its dark hover box")
	var popup := picker._layout_btn.get_popup()
	if popup.get_theme_color("font_hover_color") != UiTheme.ON_ACCENT:
		_fail(failures, "layout popup hover text should be dark on the accent hover box")
	var popup_hover: Color = (popup.get_theme_stylebox("hover") as StyleBoxFlat).bg_color
	if popup_hover != UiTheme.TEAL:
		_fail(failures, "layout popup hover box should use the accent colour, got %s" % str(popup_hover))

	# UI colour choices: at least three palettes, and picking one
	# recolours the picker (background + accent follow the palette).
	if picker._theme_btn == null or picker._theme_btn.item_count < 3:
		_fail(failures, "picker should offer at least 3 UI colour choices")
	else:
		var teal_before: Color = UiTheme.TEAL
		picker._on_theme_selected(1)  # Ocean
		await process_frame
		if UiTheme.TEAL == teal_before:
			_fail(failures, "choosing Ocean should change the accent colour")
		if picker._bg.color != UiTheme.BG:
			_fail(failures, "choosing a UI colour should recolour the picker background")
		if (picker._layout_btn.get_popup().get_theme_stylebox("hover") as StyleBoxFlat).bg_color != UiTheme.TEAL:
			_fail(failures, "popup hover should follow the chosen UI colour")
		picker._on_theme_selected(0)  # restore default for later checks
		await process_frame
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
