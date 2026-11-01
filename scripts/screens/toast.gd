class_name Toast
extends PanelContainer

## A brief, non-blocking message (design system Toast): float glass,
## radius-m, 56pt minimum and at most 380 wide, with a tone icon, a
## 15/600 title, an optional body-s message and one optional text action
## in accent. It enters over duration-standard and dismisses itself after
## 4 s (6 s with an action); error toasts stay until dismissed. One at a
## time: a new message replaces the old. The host places it (phones:
## above the bottom bar, centred; desktop: bottom-right) via `place`.

signal action_pressed

const MAX_W := 380.0
const TONE_ICON := {"good": "check", "caution": "triangle-alert", "error": "triangle-alert", "neutral": "info"}

var _icon: TextureRect
var _title: Label
var _message: Label
var _action: Button
var _tween: Tween
var _timer: Timer

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 56)
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 16
	st.content_margin_right = 8
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	_icon = UiIcon.rect("info", 20, UiTheme.MUTED)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)
	_title = UiTheme.label("", 15, UiTheme.INK, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_title)
	_message = UiTheme.label("", 14, UiTheme.MUTED)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_message)
	_action = Button.new()
	_action.custom_minimum_size = Vector2(0, 44)
	_action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_action.add_theme_font_size_override("font_size", 14)
	_action.add_theme_font_override("font", UiTheme.sans(600))
	_action.pressed.connect(func() -> void:
		action_pressed.emit()
		dismiss())
	row.add_child(_action)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(dismiss)
	add_child(_timer)

## Shows a message; `action` is the one optional text action.
func show_message(title: String, message: String = "", tone: String = "neutral",
		action: String = "") -> void:
	_icon.texture = UiIcon.texture(str(TONE_ICON.get(tone, "info")), 20)
	_icon.modulate = HudParts.tone_color(tone)
	_title.text = title
	_message.text = message
	_message.visible = message != ""
	_action.text = action
	_action.visible = action != ""
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_action.add_theme_color_override(key, UiTheme.TEAL)
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	clear.content_margin_left = 12
	clear.content_margin_right = 12
	var lit := clear.duplicate() as StyleBoxFlat
	lit.bg_color = UiTheme.LINE
	_action.add_theme_stylebox_override("normal", clear)
	_action.add_theme_stylebox_override("hover", lit)
	_action.add_theme_stylebox_override("pressed", lit)
	_action.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	visible = true
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, UiPrefs.motion(0.24))
	_timer.stop()
	if tone != "error":
		_timer.start(6.0 if action != "" else 4.0)

func dismiss() -> void:
	if not visible:
		return
	_timer.stop()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.16)
	_tween.tween_callback(hide)

func title_text() -> String:
	return _title.text

## Phones: centred above `bottom_y`; wider windows: bottom-right.
func place(host_size: Vector2, pad: float, bottom_y: float, phone: bool) -> void:
	var w := minf(MAX_W, host_size.x - pad * 2.0)
	custom_minimum_size.x = w
	# Wrapped text needs its width before it can report its height.
	var text_w := w - 16.0 - 8.0 - 20.0 - 12.0 - (_action.get_combined_minimum_size().x + 12.0 if _action.visible else 0.0)
	for l: Label in [_title, _message]:
		l.custom_minimum_size.x = text_w
		l.size = Vector2(text_w, l.size.y)
	_settle(host_size, pad, bottom_y, phone, w)
	# Labels report their wrapped height after a layout pass: settle again.
	if is_inside_tree():
		await get_tree().process_frame
		_settle(host_size, pad, bottom_y, phone, w)

func _settle(host_size: Vector2, pad: float, bottom_y: float, phone: bool, w: float) -> void:
	var h := get_combined_minimum_size().y
	size = Vector2(w, h)
	if phone:
		position = Vector2(roundf((host_size.x - w) / 2.0), bottom_y - h - 12.0)
	else:
		position = Vector2(host_size.x - pad - w, host_size.y - pad - h)
