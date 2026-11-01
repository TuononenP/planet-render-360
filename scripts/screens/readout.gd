class_name Readout
extends VBoxContainer

## A labelled real-data value (design system Readout): the eyebrow label
## over the value in mono with tabular figures, its unit, and an optional
## ink-muted detail ("14:32" + "UTC+1"). `large` sets the value in data-l
## (sheets), otherwise data. Numbers are never truncated.

var _label: Label
var _value: Label
var _detail: Label

func _init(label_text: String = "", large: bool = false) -> void:
	add_theme_constant_override("separation", 2)
	_label = UiTheme.section_label(label_text)
	add_child(_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_value = UiTheme.data_label("", 24 if large else 15, UiTheme.INK, large)
	row.add_child(_value)
	_detail = UiTheme.label("", 14, UiTheme.MUTED)
	_detail.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_detail)

func set_value(value: String, detail: String = "") -> void:
	_value.text = value
	_detail.text = detail
	_detail.visible = detail != ""

func value_text() -> String:
	return _value.text

func restyle() -> void:
	_label.add_theme_color_override("font_color", UiTheme.MUTED)
	_value.add_theme_color_override("font_color", UiTheme.INK)
	_detail.add_theme_color_override("font_color", UiTheme.MUTED)
