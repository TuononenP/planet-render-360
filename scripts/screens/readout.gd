class_name Readout
extends VBoxContainer

## A labelled real-data value (design system Readout): the eyebrow label
## over the value in mono with tabular figures, its unit, and an optional
## ink-muted detail ("14:32" + "UTC+1"). `large` sets the value in data-l
## (sheets), otherwise data. Numbers are never truncated.

var _label: Label
var _value: Label
var _detail: Label
var _icon: TextureRect

func _init(label_text: String = "", large: bool = false, value_size: int = 0) -> void:
	add_theme_constant_override("separation", 2)
	_label = UiTheme.section_label(label_text)
	add_child(_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_icon = UiIcon.rect("cloud", 18, UiTheme.INK)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.visible = false
	row.add_child(_icon)
	_value = UiTheme.data_label("", value_size if value_size > 0 else (24 if large else 15), UiTheme.INK, large)
	row.add_child(_value)
	_detail = UiTheme.label("", 14, UiTheme.MUTED)
	_detail.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_detail)

## Shows a glyph before the value (weather); "" hides it.
func set_icon(icon_name: String) -> void:
	_icon.visible = icon_name != ""
	if icon_name != "":
		_icon.texture = UiIcon.texture(icon_name, 18)

## Replaces the eyebrow text (the weather condition names its slot).
func set_label(text: String) -> void:
	_label.text = text.to_upper()

## Holds the slot with an ink-muted "—" until the real value arrives.
func set_pending() -> void:
	_value.text = "—"
	_detail.visible = false
	_value.add_theme_color_override("font_color", UiTheme.MUTED)
	_icon.modulate = UiTheme.MUTED

func set_value(value: String, detail: String = "") -> void:
	_value.add_theme_color_override("font_color", UiTheme.INK)
	_icon.modulate = UiTheme.INK
	_value.text = value
	_detail.text = detail
	_detail.visible = detail != ""

func value_text() -> String:
	return _value.text

func restyle() -> void:
	_label.add_theme_color_override("font_color", UiTheme.MUTED)
	_value.add_theme_color_override("font_color", UiTheme.INK)
	_detail.add_theme_color_override("font_color", UiTheme.MUTED)
	_icon.modulate = UiTheme.INK
