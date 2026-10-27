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
	loading.queue_free()

	if failures.is_empty():
		print("RESPONSIVE OK: breakpoints, stacked/split picker, layout override, history grid, type floors")
		quit(0)
	else:
		for f in failures:
			printerr("RESPONSIVE FAIL: ", f)
		quit(1)
