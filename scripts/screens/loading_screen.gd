class_name LoadingScreen
extends Control

signal cancel_requested

var _title: Label
var _progress: ProgressBar
var _stage_label: Label
var _rows: Array = []  # Array of {icon, name, state} labels per stage
var _card: PanelContainer
var _preview: PanelContainer
var _current_layout: int = Responsive.Layout.COMPACT

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
	col.add_theme_constant_override("separation", 14)
	_card.add_child(col)

	_title = UiTheme.label("Generating…", 26, UiTheme.INK, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title)

	_preview = PanelContainer.new()
	_preview.custom_minimum_size = Vector2(0, 210)
	_preview.add_theme_stylebox_override("panel",
		UiTheme.style(Color(0.78, 0.82, 0.74), 16))
	var preview_label := UiTheme.label("◭  Terrain preview", 16, Color.WHITE)
	_preview.add_child(preview_label)
	col.add_child(_preview)

	_progress = ProgressBar.new()
	_progress.min_value = 0
	_progress.max_value = 100
	_progress.value = 0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 10)
	_progress.add_theme_stylebox_override("background", UiTheme.style(Color(0.88, 0.89, 0.88), 5))
	_progress.add_theme_stylebox_override("fill", UiTheme.style(UiTheme.TEAL, 5))
	col.add_child(_progress)
	_stage_label = UiTheme.label("Starting…", 16, UiTheme.MUTED)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_stage_label)

	for stage in GenerationPipeline.STAGES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.custom_minimum_size = Vector2(0, 44)
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
		_rows.append({"icon": icon, "name": name_label, "state": state_label, "label": stage})
		col.add_child(row)

	var cancel := UiTheme.ghost_button("Cancel")
	cancel.pressed.connect(func() -> void: cancel_requested.emit())
	col.add_child(cancel)

	resized.connect(_on_resized)
	_on_resized()

func _on_resized() -> void:
	if _card == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	_current_layout = layout
	var pad := Responsive.page_padding(layout)
	var width := mini(Responsive.content_max_width(layout), maxi(int(size.x) - pad * 2, 280))
	_card.custom_minimum_size = Vector2(width, 0)
	_preview.custom_minimum_size = Vector2(0, Responsive.preview_height(layout))
	_title.add_theme_font_size_override("font_size", 26 if layout == Responsive.Layout.COMPACT else 30)

func begin(place_name: String) -> void:
	_title.text = place_name
	_progress.value = 0
	for row in _rows:
		row["icon"].text = "○"
		row["icon"].add_theme_color_override("font_color", UiTheme.MUTED)
		row["name"].text = row["label"]
		row["name"].add_theme_color_override("font_color", UiTheme.MUTED)
		row["state"].text = ""
		row["state"].add_theme_color_override("font_color", UiTheme.MUTED)

func set_stage(index: int, label: String, state: String) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row: Dictionary = _rows[index]
	if state == "done":
		row["icon"].text = "✓"
		row["icon"].add_theme_color_override("font_color", UiTheme.TEAL)
		row["name"].add_theme_color_override("font_color", UiTheme.TEAL_DARK)
		row["state"].text = "Done"
		row["state"].add_theme_color_override("font_color", UiTheme.TEAL)
	else:
		row["icon"].text = "◌"
		row["icon"].add_theme_color_override("font_color", UiTheme.TEAL_DARK)
		row["name"].add_theme_color_override("font_color", UiTheme.INK)
		row["state"].text = "In progress"
		row["state"].add_theme_color_override("font_color", UiTheme.TEAL_DARK)

func set_progress(fraction: float, label: String) -> void:
	_progress.value = fraction * 100.0
	_stage_label.text = label
