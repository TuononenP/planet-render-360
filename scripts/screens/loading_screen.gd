class_name LoadingScreen
extends Control

signal cancel_requested

var _title: Label
var _progress: ProgressBar
var _stage_label: Label
var _percent_label: Label
var _rows: Array = []  # Array of {icon, name, state, panel} per stage
var _card: PanelContainer
var _preview: PanelContainer
var _eta_label: Label
var _cancel_btn: Button
var _current_layout: int = Responsive.Layout.COMPACT
var _active_index := -1
var _pulse_on := false
var _fit_queued := false
var _fit_pass := 0
var _preview_min_h := 56  # measured in _ready: icon + label + padding

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, 20, Color.TRANSPARENT, true))
	center.add_child(_card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_card.add_child(col)

	var eyebrow := UiTheme.label("Building your 360° view of", 14, UiTheme.TEAL, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(eyebrow)
	_title = UiTheme.label("Generating…", 26, UiTheme.INK, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_preview = PanelContainer.new()
	_preview.custom_minimum_size = Vector2(0, 210)
	_preview.add_theme_stylebox_override("panel",
		UiTheme.style(Color(0.10, 0.20, 0.18), 16))
	var preview_col := VBoxContainer.new()
	preview_col.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_col.add_theme_constant_override("separation", 6)
	_preview.add_child(preview_col)
	var preview_icon := UiTheme.label("◭", 44, UiTheme.AMBER, true)
	preview_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_col.add_child(preview_icon)
	var preview_label := UiTheme.label("Terrain, landmarks and light —\nassembled on your device", 15, Color(1, 1, 1, 0.92))
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_col.add_child(preview_label)
	col.add_child(_preview)
	# The preview cannot shrink below its own contents; measure that
	# floor (with no custom minimum in the way) for the fit logic.
	_preview.custom_minimum_size = Vector2.ZERO
	_preview_min_h = int(_preview.get_combined_minimum_size().y)

	_progress = ProgressBar.new()
	_progress.min_value = 0
	_progress.max_value = 100
	_progress.value = 0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 10)
	# UiTheme.style carries card padding; a 10pt bar must not inherit it.
	var bar_bg := UiTheme.style(Color(0.88, 0.89, 0.88), 5)
	bar_bg.content_margin_top = 0
	bar_bg.content_margin_bottom = 0
	var bar_fill := UiTheme.style(UiTheme.TEAL, 5)
	bar_fill.content_margin_top = 0
	bar_fill.content_margin_bottom = 0
	_progress.add_theme_stylebox_override("background", bar_bg)
	_progress.add_theme_stylebox_override("fill", bar_fill)
	col.add_child(_progress)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	col.add_child(progress_row)
	_stage_label = UiTheme.label("Starting…", 16, UiTheme.MUTED)
	_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_row.add_child(_stage_label)
	_percent_label = UiTheme.label("0%", 22, UiTheme.TEAL_DARK, true)
	progress_row.add_child(_percent_label)
	_eta_label = UiTheme.label("Real elevation & map data — usually well under a minute. Yours to keep offline afterwards.", 13, UiTheme.MUTED)
	_eta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_eta_label)

	for stage in GenerationPipeline.STAGES:
		var row_panel := PanelContainer.new()
		row_panel.add_theme_stylebox_override("panel", _row_style(Color.TRANSPARENT))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.custom_minimum_size = Vector2(0, 36)
		var icon := UiTheme.label("○", 20, UiTheme.MUTED)
		icon.custom_minimum_size = Vector2(30, 0)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(icon)
		var name_label := UiTheme.label(stage, 17, UiTheme.MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)
		var state_label := UiTheme.label("", 15, UiTheme.MUTED)
		state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(state_label)
		_rows.append({"icon": icon, "name": name_label, "state": state_label, "label": stage, "panel": row_panel})
		row_panel.add_child(row)
		col.add_child(row_panel)

	var pulse := Timer.new()
	pulse.wait_time = 0.55
	pulse.autostart = true
	pulse.timeout.connect(_on_pulse)
	add_child(pulse)

	_cancel_btn = UiTheme.ghost_button("Cancel")
	_cancel_btn.pressed.connect(func() -> void: cancel_requested.emit())
	col.add_child(_cancel_btn)

	resized.connect(_on_resized)
	# While hidden no layout runs, so fit readings are transient junk;
	# refit from clean readings the moment the screen is shown.
	visibility_changed.connect(func() -> void:
		if visible:
			_on_resized())
	_on_resized()

## Stage rows are display-only: slim vertical padding keeps five of
## them plus Cancel inside short windows (the card style's 14pt
## top/bottom margins alone added 140pt of dead height).
static func _row_style(bg: Color) -> StyleBoxFlat:
	var s := UiTheme.style(bg, 12)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s

func _on_resized() -> void:
	if _card == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	_current_layout = layout
	var pad := Responsive.page_padding(layout)
	var width := mini(Responsive.content_max_width(layout), maxi(int(size.x) - pad * 2, 280))
	_card.custom_minimum_size = Vector2(width, 0)
	_title.add_theme_font_size_override("font_size", 26 if layout == Responsive.Layout.COMPACT else 30)
	# Fit the whole card — every stage and Cancel — inside the window.
	# The preview is decorative, so it gives up height first; the eta
	# line goes next on very short windows. Nothing may fall off-screen:
	# a centred card taller than the window clips top and bottom alike.
	if _eta_label != null:
		_eta_label.visible = size.y >= 680.0
	_preview.visible = true
	_preview.custom_minimum_size = Vector2(0, Responsive.preview_height(layout))
	_fit_pass = 0
	if not _fit_queued and size.y > 0.0:
		_fit_queued = true
		call_deferred("_fit_preview")

## Size the preview from the card's real laid-out height over a few
## frames. Deferred and multi-pass because the first frames after a
## resize are transient (a centred card can briefly report a huge
## minimum height while its labels rewrap), and
## get_combined_minimum_size() prices autowrap labels at their
## longest-word width. Only the last pass may hide the preview.
func _fit_preview() -> void:
	_fit_queued = false
	if _card == null or size.y <= 0.0 or not visible:
		return  # hidden: no real layout yet; showing refits via visibility_changed
	_fit_pass += 1
	var avail := size.y - 24.0
	var preview_now := _preview.size.y if _preview.visible else 0.0
	var fixed := _card.size.y - preview_now
	var room := avail - fixed - (0.0 if _preview.visible else 10.0)
	if room >= float(_preview_min_h):
		_preview.visible = true
		_preview.custom_minimum_size = Vector2(0,
			mini(Responsive.preview_height(_current_layout), int(room)))
	else:
		_preview.custom_minimum_size = Vector2(0, 56)
		if _fit_pass >= 4:
			# Very short window (landscape phone): the stages and
			# Cancel matter, the decorative preview does not.
			_preview.visible = false
	if _fit_pass < 4 and not _fit_queued:
		_fit_queued = true
		call_deferred("_fit_preview")

func begin(place_name: String) -> void:
	_title.text = place_name
	_progress.value = 0
	_active_index = -1
	if _percent_label != null:
		_percent_label.text = "0%"
	if _stage_label != null:
		_stage_label.text = "Starting…"
	for row in _rows:
		row["icon"].text = "○"
		row["icon"].add_theme_color_override("font_color", UiTheme.MUTED)
		row["name"].text = row["label"]
		row["name"].add_theme_color_override("font_color", UiTheme.MUTED)
		row["state"].text = ""
		row["state"].add_theme_color_override("font_color", UiTheme.MUTED)
		row["panel"].add_theme_stylebox_override("panel", _row_style(Color.TRANSPARENT))

func _on_pulse() -> void:
	_pulse_on = not _pulse_on
	if _active_index < 0 or _active_index >= _rows.size():
		return
	var icon: Label = _rows[_active_index]["icon"]
	icon.text = "●" if _pulse_on else "◌"

func set_stage(index: int, label: String, state: String) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row: Dictionary = _rows[index]
	if state == "done":
		if _active_index == index:
			_active_index = -1
		row["icon"].text = "✓"
		row["icon"].add_theme_color_override("font_color", UiTheme.TEAL)
		row["name"].add_theme_color_override("font_color", UiTheme.TEAL_DARK)
		row["state"].text = "Done"
		row["state"].add_theme_color_override("font_color", UiTheme.TEAL)
		row["panel"].add_theme_stylebox_override("panel", _row_style(Color.TRANSPARENT))
	else:
		_active_index = index
		row["icon"].text = "◌"
		row["icon"].add_theme_color_override("font_color", UiTheme.TEAL_DARK)
		row["name"].add_theme_color_override("font_color", UiTheme.INK)
		row["state"].text = "Working…"
		row["state"].add_theme_color_override("font_color", UiTheme.TEAL_DARK)
		row["panel"].add_theme_stylebox_override("panel", _row_style(UiTheme.TEAL_SOFT))

func set_progress(fraction: float, label: String) -> void:
	_progress.value = fraction * 100.0
	_stage_label.text = label
	if _percent_label != null:
		_percent_label.text = "%d%%" % int(round(clampf(fraction, 0.0, 1.0) * 100.0))
