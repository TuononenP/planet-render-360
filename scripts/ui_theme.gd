class_name UiTheme
extends RefCounted

## Shared theme: warm atlas paper, deep-teal ink, one amber accent.
## Sizes are logical points at the 390pt design frame (see Responsive):
## body text never drops below 14pt and touch targets stay >= 48pt tall,
## so controls stay legible on phones and on macOS alike.

const BG := Color(0.937, 0.945, 0.910)
const CARD := Color(1, 1, 1)
const INK := Color(0.07, 0.10, 0.09)
const MUTED := Color(0.38, 0.42, 0.39)
const TEAL := Color(0.16, 0.42, 0.36)
const TEAL_DARK := Color(0.10, 0.32, 0.27)
const TEAL_SOFT := Color(0.87, 0.93, 0.89)
const AMBER := Color(0.93, 0.62, 0.20)
const DARK_PANEL := Color(0.07, 0.12, 0.11, 0.88)
const LINE := Color(0.84, 0.86, 0.82)
const FIELD := Color(0.97, 0.98, 0.96)

static func style(bg: Color, radius: int = 16, border: Color = Color.TRANSPARENT, shadow: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	if border != Color.TRANSPARENT:
		s.border_color = border
		s.set_border_width_all(1)
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.08)
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 4)
	return s

static func label(text: String, size: int, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", style(TEAL, 14, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("hover", style(TEAL_DARK, 14, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("pressed", style(Color(0.07, 0.24, 0.20), 14))
	b.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, 14, AMBER))
	return b

static func ghost_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", TEAL_DARK)
	b.add_theme_color_override("font_hover_color", TEAL_DARK)
	b.add_theme_stylebox_override("normal", style(CARD, 12, LINE, true))
	b.add_theme_stylebox_override("hover", style(TEAL_SOFT, 12, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, 12, TEAL))
	b.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, 12, AMBER))
	return b

static func _chip_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := style(bg, 22, border, true)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

## One-tap place chip for the picker's quick picks.
static func chip_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", TEAL_DARK)
	b.add_theme_color_override("font_hover_color", TEAL_DARK)
	b.add_theme_stylebox_override("normal", _chip_style(CARD, LINE))
	b.add_theme_stylebox_override("hover", _chip_style(TEAL_SOFT, TEAL))
	b.add_theme_stylebox_override("pressed", _chip_style(TEAL_SOFT, TEAL))
	b.add_theme_stylebox_override("focus", _chip_style(Color.TRANSPARENT, AMBER))
	return b

static func section_label(text: String) -> Label:
	return label(text, 13, MUTED, true)

static func field(placeholder: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.custom_minimum_size = Vector2(0, 54)
	f.add_theme_font_size_override("font_size", 16)
	f.add_theme_color_override("font_color", INK)
	f.add_theme_color_override("font_placeholder_color", MUTED)
	f.add_theme_stylebox_override("normal", style(CARD, 12, LINE, true))
	f.add_theme_stylebox_override("focus", style(Color.WHITE, 12, TEAL))
	f.add_theme_stylebox_override("read_only", style(FIELD, 12, LINE))
	return f

static func pill(text: String, size: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color(1, 1, 1, 0.92), 22, Color.TRANSPARENT, true))
	var l := label(text, size, INK, true)
	p.add_child(l)
	p.set_meta("label", l)
	return p

static func icon_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", TEAL_DARK)
	b.add_theme_stylebox_override("normal", style(Color(1, 1, 1, 0.94), 16, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("hover", style(Color.WHITE, 16, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("pressed", style(FIELD, 16, Color.TRANSPARENT, true))
	return b
