class_name SegmentedControl
extends PanelContainer

## One choice from two to five options (design system SegmentedControl):
## a pill track, the selected segment an accent fill with an on-accent
## 600 label. `glass` is for the viewer's bar (glass-strong track);
## otherwise the track is sky-300 on solid ground. Mirrors OptionButton's
## select / selected / item_count / item_selected so it can stand in
## for one. `icon_only` keeps each label as the tooltip. `stacked` sets
## each icon over its name in ink on an outlined track (the seasons in
## the Conditions sheet's seasons and weather).

signal item_selected(index: int)

var selected := -1
var icon_only := false
var stacked := false
var font_size := 14
## No track of its own: the rows of a group that draws one outline.
var bare := false
var _glass := false
var _labels: Array = []
var _icons: Array = []
var _buttons: Array[Button] = []

var item_count: int:
	get:
		return _buttons.size()

func _init(labels: Array = [], icons: Array = [], glass: bool = false) -> void:
	_labels = labels
	_icons = icons
	_glass = glass
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	add_child(row)
	for i in labels.size():
		var b := Button.new()
		b.toggle_mode = true
		b.tooltip_text = str(labels[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(44, 42)
		b.add_theme_font_size_override("font_size", 14)
		var index := i
		b.pressed.connect(func() -> void:
			select(index)
			item_selected.emit(index))
		row.add_child(b)
		_buttons.append(b)
	restyle()

func select(index: int) -> void:
	selected = index
	restyle()

func set_stacked(on: bool) -> void:
	stacked = on
	restyle()

## The label size: the weather rows in the Conditions sheet set 13 so
## "Heavy rain" fits a quarter of the sheet.
func set_font_size(px: int) -> void:
	font_size = px
	restyle()

func set_icon_only(on: bool) -> void:
	if on != icon_only:
		icon_only = on
		restyle()

## Re-skin after an accent change; also applies the selection.
func restyle() -> void:
	var track := UiTheme.style(UiTheme.CARD if _glass else UiTheme.FIELD, UiTheme.RADIUS_PILL,
		UiTheme.GLASS_EDGE if _glass else UiTheme.LINE)
	if stacked:
		track = UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_M, UiTheme.LINE_STRONG)
	if bare:
		track = UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_M)
	track.set_content_margin_all(0 if bare else 3)
	add_theme_stylebox_override("panel", track)
	for i in _buttons.size():
		var b := _buttons[i]
		var on := i == selected
		b.set_pressed_no_signal(on)
		var has_icon := i < _icons.size() and str(_icons[i]) != ""
		b.text = "" if icon_only and has_icon else str(_labels[i])
		var text_color := UiTheme.ON_ACCENT if on else (UiTheme.INK if stacked else UiTheme.MUTED)
		for key in ["font_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(key, text_color)
		b.add_theme_color_override("font_hover_color", UiTheme.ON_ACCENT if on else UiTheme.INK)
		b.add_theme_font_override("font", UiTheme.sans(600 if on else 500))
		b.add_theme_font_size_override("font_size", font_size)
		if has_icon:
			UiIcon.apply(b, str(_icons[i]), 18, text_color, UiTheme.ON_ACCENT)
			b.add_theme_constant_override("h_separation", 4)
			if stacked:
				b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size.y = 52 if stacked else 42
		var seg := UiTheme.style(UiTheme.TEAL if on else Color.TRANSPARENT,
			UiTheme.RADIUS_S if stacked else UiTheme.RADIUS_PILL)
		seg.content_margin_left = 4 if stacked else 12
		seg.content_margin_right = 4 if stacked else 12
		if stacked:
			seg.content_margin_top = 6
			seg.content_margin_bottom = 6
		var hover := seg.duplicate() as StyleBoxFlat
		if not on:
			hover.bg_color = Color(UiTheme.INK, 0.06)
		b.add_theme_stylebox_override("normal", seg)
		b.add_theme_stylebox_override("pressed", seg)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("hover_pressed", seg)
		b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_S if stacked else UiTheme.RADIUS_PILL))
