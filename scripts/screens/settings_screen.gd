class_name SettingsScreen
extends Control

## Settings: one choice that matters — render quality. Picking a preset
## trades accuracy for render time (see RenderSettings for the budgets
## behind each name) and is saved on-device for the next launch.

signal back_requested
signal preset_changed(preset: int)

var _settings: RenderSettings
var _preset_btns: Array[Button] = []
var _summary_label: Label
var _margin: MarginContainer

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_margin.add_child(col)
	col.add_child(UiTheme.label("⚙  Settings", 34, UiTheme.INK, true))
	var subtitle := UiTheme.label(
		"Higher quality renders terrain and places more accurately, but takes longer to build and more power to draw.",
		15, UiTheme.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(subtitle)
	col.add_child(UiTheme.section_label("Render quality"))
	var group := ButtonGroup.new()
	for p in RenderSettings.PRESET_NAMES.size():
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = group
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 72)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", UiTheme.INK)
		btn.add_theme_color_override("font_hover_color", UiTheme.INK)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.add_theme_stylebox_override("normal", UiTheme.style(UiTheme.CARD, 14, UiTheme.LINE, true))
		btn.add_theme_stylebox_override("hover", UiTheme.style(Color.WHITE, 14, UiTheme.TEAL))
		btn.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.TEAL, 14, Color.TRANSPARENT, true))
		btn.text = "%s\n%s" % [RenderSettings.preset_name(p), RenderSettings.PRESET_BLURBS[p]]
		var preset_value := p
		btn.pressed.connect(func() -> void: _select(preset_value))
		_preset_btns.append(btn)
		col.add_child(btn)
	_summary_label = UiTheme.label("", 14, UiTheme.TEAL_DARK, true)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_summary_label)
	var note := UiTheme.label(
		"Applies to the next place you render. A place already open keeps its terrain, but its render scale and shadows update straight away.",
		14, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var back := UiTheme.ghost_button("← Back to map")
	back.pressed.connect(func() -> void: back_requested.emit())
	col.add_child(back)
	resized.connect(_on_resized)
	_on_resized()
	_refresh()

func _on_resized() -> void:
	if _margin == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	var pad := Responsive.page_padding(layout)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad + 8)
	_margin.add_theme_constant_override("margin_bottom", pad)

func bind_settings(settings: RenderSettings) -> void:
	_settings = settings
	_refresh()

func _select(preset_value: int) -> void:
	if _settings == null:
		_settings = RenderSettings.new()
	_settings.set_preset(preset_value)
	_refresh()
	preset_changed.emit(_settings.preset)

func _refresh() -> void:
	var current := _settings.preset if _settings != null \
		else int(RenderSettings.Preset.BALANCED)
	for i in _preset_btns.size():
		_preset_btns[i].set_pressed_no_signal(i == current)
	if _summary_label != null:
		_summary_label.text = RenderSettings.summary_for(current)
