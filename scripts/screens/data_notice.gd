class_name DataNotice
extends Control

## Design-system DataNotice over the 360 view: when live data did not
## arrive (LocationData.data_notes) a float-glass card says what happened
## and what the view does instead, in plain words (never a provider or
## error code). "Dismiss" folds it into a "Partial data" badge that stays
## in the corner and reopens it; "Try again" asks for a fresh generation.
## It sits below the top bar so it never covers the dock or the scene's
## centre, and does not intercept drags anywhere outside itself.

signal retry_requested

const CARD_W := 380
const TOP_BAR_H := 60

var _notes: Array = []
var _on_screen := false
var _open := false
var _card: PanelContainer
var _badge: PanelContainer

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

func _ready() -> void:
	resized.connect(_layout)

## A new view: show its notes (open), or nothing when all data arrived.
func show_notes(notes: Array) -> void:
	_notes = notes
	_open = not notes.is_empty()
	_rebuild()

func clear() -> void:
	show_notes([])

## Only the 360 view carries the notice (Main calls this from _show).
func set_on_screen(on_screen: bool) -> void:
	_on_screen = on_screen
	visible = _on_screen and not _notes.is_empty()

func refresh_theme() -> void:
	_rebuild()

func is_open() -> bool:
	return _open

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_card = null
	_badge = null
	visible = _on_screen and not _notes.is_empty()
	if _notes.is_empty():
		return
	_card = _build_card()
	_badge = _build_badge()
	add_child(_card)
	add_child(_badge)
	_apply_state()
	_layout()

func _tone() -> Color:
	return UiTheme.SIGNAL_ERROR if DataNotes.is_error(_notes) else UiTheme.SIGNAL_CAUTION

func _build_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", HudStyle.panel(UiTheme.RADIUS_M, 16, 14))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	var icon := UiTheme.label("⚠", 20, _tone())
	icon.custom_minimum_size = Vector2(24, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	head.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(text)
	text.add_child(UiTheme.label(DataNotes.title(_notes), 15, UiTheme.INK, true))
	text.add_child(_wrapped(DataNotes.message(_notes), UiTheme.MUTED))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	col.add_child(rows)
	for note in _notes:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var glyph := UiTheme.label(str(note["glyph"]), 14, UiTheme.MUTED)
		glyph.custom_minimum_size = Vector2(18, 0)
		row.add_child(glyph)
		row.add_child(UiTheme.label(str(note["layer"]), 14, UiTheme.INK, true))
		var effect := _wrapped("· %s" % str(note["effect"]), UiTheme.MUTED)
		row.add_child(effect)
		rows.add_child(row)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(actions)
	actions.add_child(_text_button("Dismiss", UiTheme.MUTED, _dismiss))
	actions.add_child(_text_button("Try again", UiTheme.TEAL, func() -> void:
		retry_requested.emit()))
	return card

func _wrapped(text: String, color: Color) -> Label:
	var l := UiTheme.label(text, 14, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(60, 0)
	return l

## Text-only pill action (design system Toast action): 44pt touch target.
func _text_button(text: String, color: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_font_override("font", UiTheme.sans(600))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, color)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	b.pressed.connect(on_press)
	return b

## The StatusBadge ("Partial data", caution tone) inside a glass chip, as
## the design system asks for badges over the scene.
func _build_badge() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.add_theme_stylebox_override("panel", HudStyle.panel(UiTheme.RADIUS_PILL, 6, 4))
	var b := Button.new()
	b.text = "⚠  %s" % ("No live data" if DataNotes.is_error(_notes) else "Partial data")
	b.custom_minimum_size = Vector2(0, 32)
	b.tooltip_text = "Some data was unavailable. Show details."
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_font_override("font", UiTheme.sans(600))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, _tone())
	var outline := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_XS, _tone())
	outline.content_margin_top = 2
	outline.content_margin_bottom = 2
	outline.content_margin_left = 8
	outline.content_margin_right = 8
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, outline)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_XS))
	b.pressed.connect(func() -> void:
		_open = true
		_apply_state())
	chip.add_child(b)
	return chip

func _dismiss() -> void:
	_open = false
	_apply_state()

func _apply_state() -> void:
	if _card != null:
		_card.visible = _open
		_badge.visible = not _open
	_layout()

func _layout() -> void:
	if _card == null:
		return
	var pad := Responsive.page_padding(Responsive.layout_for_width(size.x))
	var w := clampf(size.x - pad * 2.0, 280.0, float(CARD_W))
	_card.custom_minimum_size.x = w
	_card.position = Vector2(roundf((size.x - w) / 2.0), pad + TOP_BAR_H)
	_badge.position = Vector2(pad, pad + TOP_BAR_H)
	# Wrapped labels learn their height only once the width is known.
	_card.reset_size()
	_badge.reset_size()
	_card.size.x = w
	call_deferred("_settle")

func _settle() -> void:
	if _card != null and is_instance_valid(_card):
		_card.size = Vector2(_card.size.x, _card.get_combined_minimum_size().y)
