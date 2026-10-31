class_name SettingsScreen
extends Control

## Settings: one choice that matters — render quality. Picking a preset
## trades accuracy for render time (see RenderSettings for the budgets
## behind each name) and is saved on-device for the next launch.

signal back_requested
signal preset_changed(preset: int)
signal accent_changed(index: int)
## 0 Auto, 1 Compact, 2 Wide: forces the stacked or two-column layout.
signal layout_changed(index: int)

var _settings: RenderSettings
var _preset_btns: Array[Button] = []
var _summary_label: Label
var _storage_label: Label
var _margin: MarginContainer
var _grid: GridContainer
var _accent_btns: Array[Button] = []
var _layout_btns: Array[Button] = []
var _layout_index := 0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	_margin.add_child(outer)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	outer.add_child(header)
	var back := UiTheme.icon_button("←")
	back.tooltip_text = "Back to map"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var title := UiTheme.label("Settings", 34, UiTheme.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	col.add_child(UiTheme.section_label("Appearance"))
	var look := PanelContainer.new()
	look.add_theme_stylebox_override("panel", UiTheme.glass_panel(UiTheme.RADIUS_L))
	col.add_child(look)
	var look_col := VBoxContainer.new()
	look_col.add_theme_constant_override("separation", 10)
	look.add_child(look_col)
	look_col.add_child(UiTheme.label("Accent", 15, UiTheme.INK, true))
	_choice_row(look_col, UiTheme.theme_names + ["Auto"], _accent_btns,
		func(i: int) -> void:
			if i == UiTheme.AUTO_CHIP:
				UiTheme.auto_mode = true
			else:
				UiTheme.apply_palette(i)
			accent_changed.emit(i))
	look_col.add_child(UiTheme.label("Layout", 15, UiTheme.INK, true))
	_choice_row(look_col, ["Auto", "Compact", "Wide"], _layout_btns,
		func(i: int) -> void:
			_layout_index = i
			layout_changed.emit(i))
	var look_note := UiTheme.label(
		"Auto follows the window. Compact and Wide force the phone or tablet arrangement on any screen.",
		14, UiTheme.MUTED)
	look_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	look_col.add_child(look_note)

	col.add_child(UiTheme.section_label("Render quality"))
	var subtitle := UiTheme.label(
		"Higher quality renders terrain and places more accurately, but takes longer to build and more power to draw.",
		15, UiTheme.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(subtitle)
	_grid = GridContainer.new()
	_grid.columns = 1
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	col.add_child(_grid)
	var group := ButtonGroup.new()
	for p in RenderSettings.PRESET_NAMES.size():
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = group
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 124)
		btn.add_theme_font_size_override("font_size", 15)
		_style_preset(btn)
		var level := "●".repeat(p + 1) + "○".repeat(RenderSettings.PRESET_NAMES.size() - p - 1)
		var tag := "  ·  Recommended" if p == int(RenderSettings.Preset.HIGH) else ""
		btn.text = "%s%s\n%s\n%s" % [RenderSettings.preset_name(p), tag, level, RenderSettings.PRESET_BLURBS[p]]
		var preset_value := p
		btn.pressed.connect(func() -> void: _select(preset_value))
		_preset_btns.append(btn)
		_grid.add_child(btn)
	_summary_label = UiTheme.label("", 14, UiTheme.TEAL, true)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_summary_label)
	var note := UiTheme.label(
		"Applies to the next place you render. A place already open keeps its terrain, but its render scale and shadows update straight away.",
		14, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)

	var storage := PanelContainer.new()
	storage.add_theme_stylebox_override("panel", UiTheme.glass_panel(24))
	col.add_child(storage)
	var storage_col := VBoxContainer.new()
	storage_col.add_theme_constant_override("separation", 12)
	storage.add_child(storage_col)
	storage_col.add_child(UiTheme.section_label("Offline storage"))
	_storage_label = UiTheme.label("", 14, UiTheme.MUTED)
	_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	storage_col.add_child(_storage_label)
	var clear_cache_btn := UiTheme.ghost_button("Clear downloaded cache")
	clear_cache_btn.custom_minimum_size = Vector2(0, 48)
	clear_cache_btn.pressed.connect(func() -> void:
		OfflineDownloader.clear_cache()
		_refresh_storage())
	storage_col.add_child(clear_cache_btn)
	resized.connect(_on_resized)
	_on_resized()
	_refresh()

## Preset card: quiet glass until chosen, then an accent edge and tint
## (the pressed state doubles as the selected state).
func _style_preset(btn: Button) -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, UiTheme.INK)
	var base := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_L, UiTheme.LINE)
	base.set_content_margin_all(18)
	btn.add_theme_stylebox_override("normal", base)
	var hover := UiTheme.style(UiTheme.FIELD, UiTheme.RADIUS_L, Color(UiTheme.TEAL, 0.6))
	hover.set_content_margin_all(18)
	btn.add_theme_stylebox_override("hover", hover)
	var chosen := UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_L, UiTheme.TEAL, true)
	chosen.set_content_margin_all(18)
	chosen.set_border_width_all(2)
	chosen.shadow_color = Color(UiTheme.TEAL, 0.18)
	chosen.shadow_size = 12
	btn.add_theme_stylebox_override("pressed", chosen)
	btn.add_theme_stylebox_override("hover_pressed", chosen)
	var focus := UiTheme.style(Color.TRANSPARENT, 20, UiTheme.TEAL)
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", focus)

## A wrapping row of exclusive chips; `pick(index)` runs on a choice.
func _choice_row(parent: Control, names: Array, into: Array[Button], pick: Callable) -> Array[Button]:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	parent.add_child(flow)
	var group := ButtonGroup.new()
	for i in names.size():
		var chip := UiTheme.chip_button(str(names[i]))
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		chip.custom_minimum_size = Vector2(96, 44)
		chip.button_group = group
		var index := i
		chip.pressed.connect(func() -> void:
			pick.call(index)
			_refresh_appearance())
		into.append(chip)
		flow.add_child(chip)
	return into

func _refresh_appearance() -> void:
	for i in _accent_btns.size():
		var chosen := i == UiTheme.AUTO_CHIP if UiTheme.auto_mode else i == UiTheme.theme_index
		var chip := _accent_btns[i]
		chip.set_pressed_no_signal(chosen)
		UiTheme.apply_chip(chip, chosen)
		# Each chip shows its colour; the chosen one shows a check on its fill.
		if chosen:
			UiIcon.apply(chip, "check", 16, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
		elif i == UiTheme.AUTO_CHIP:
			chip.icon = null
		else:
			chip.icon = UiTheme.dot(UiTheme.ACCENTS[i])
			chip.expand_icon = false
			for key in ["icon_normal_color", "icon_hover_color", "icon_focus_color",
					"icon_pressed_color", "icon_hover_pressed_color"]:
				chip.add_theme_color_override(key, Color.WHITE)
	for i in _layout_btns.size():
		_layout_btns[i].set_pressed_no_signal(i == _layout_index)
		UiTheme.apply_chip(_layout_btns[i], i == _layout_index)

## Re-skin after an accent change (preset cards bake the palette in).
func refresh_theme() -> void:
	_refresh_appearance()
	for btn in _preset_btns:
		_style_preset(btn)
	if _summary_label != null:
		_summary_label.add_theme_color_override("font_color", UiTheme.TEAL)

func _on_resized() -> void:
	if _margin == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	var pad := Responsive.page_padding(layout)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad + 8)
	_margin.add_theme_constant_override("margin_bottom", pad)
	if _grid != null:
		_grid.columns = 4 if layout == Responsive.Layout.EXPANDED \
			else (2 if layout == Responsive.Layout.MEDIUM else 1)

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
		else int(RenderSettings.Preset.HIGH)
	for i in _preset_btns.size():
		_preset_btns[i].set_pressed_no_signal(i == current)
	if _summary_label != null:
		_summary_label.text = RenderSettings.summary_for(current)
	_refresh_appearance()
	_refresh_storage()

func _refresh_storage() -> void:
	if _storage_label != null:
		var mb := float(OfflineDownloader.cache_size_bytes()) / 1048576.0
		_storage_label.text = "Downloaded places use %.1f MB on this device. Clearing frees the space; saved places stay in History and re-download when opened." % mb
