class_name FpsCounter
extends PanelContainer

## An optional frames-per-second readout for the 360 viewer: a small glass
## pill with the rate in mono, refreshed twice a second while visible
## (it does not process while hidden).

const REFRESH := 0.5

var _value: Label
var _elapsed := 0.0

func _init() -> void:
	visible = false
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	add_theme_stylebox_override("panel", st)
	_value = UiTheme.data_label("", 14, UiTheme.INK)
	add_child(_value)
	_refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= REFRESH:
		_elapsed = 0.0
		_refresh()

func _refresh() -> void:
	_value.text = "%d FPS" % int(Performance.get_monitor(Performance.TIME_FPS))

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)
		if visible:
			_elapsed = 0.0
			_refresh()
