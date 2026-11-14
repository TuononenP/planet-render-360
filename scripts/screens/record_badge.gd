class_name RecordBadge
extends PanelContainer

## While a video records: float glass (radius-pill) under the place pill
## with a signal-error dot, the word and the running time in data-s
## ("Recording  0:42"). It sits on the HUD, not the fading layer, so it
## stays up while the HUD idles; the HUD is never in the video. The host
## places it (ViewTools.layout).

var _dot: Panel
var _time: Label

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_dot = Panel.new()
	_dot.custom_minimum_size = Vector2(10, 10)
	_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_dot)
	row.add_child(UiTheme.label("Recording", 14, UiTheme.INK, true))
	_time = UiTheme.data_label("0:00", 13, UiTheme.MUTED)
	row.add_child(_time)
	refresh_theme()

## Re-skin after an accent or theme change.
func refresh_theme() -> void:
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 12
	st.content_margin_right = 14
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	add_theme_stylebox_override("panel", st)
	_dot.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.SIGNAL_ERROR, UiTheme.RADIUS_PILL))

## Shows `seconds` of recording; returns true when its size may change.
func show_time(seconds: float) -> bool:
	var text := VideoRecorder.clock(seconds)
	if _time.text == text:
		return false
	var grew := text.length() != _time.text.length()
	_time.text = text
	return grew
