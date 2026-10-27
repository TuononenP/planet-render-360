class_name UiTheme
extends RefCounted

## Shared light, restrained theme matching the approved MVP mockups.
## Sizes are logical points at the 390pt design frame (see Responsive):
## body text never drops below 14pt and touch targets stay >= 48pt tall,
## so controls stay legible on phones and on macOS alike.

const BG := Color(0.925, 0.937, 0.929)
const CARD := Color(1, 1, 1)
const INK := Color(0.10, 0.11, 0.10)
const MUTED := Color(0.42, 0.45, 0.43)
const TEAL := Color(0.30, 0.47, 0.42)
const TEAL_DARK := Color(0.24, 0.38, 0.34)
const LINE := Color(0.85, 0.87, 0.85)
const FIELD := Color(0.96, 0.97, 0.96)

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
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", style(TEAL, 14))
	b.add_theme_stylebox_override("hover", style(TEAL_DARK, 14))
	b.add_theme_stylebox_override("pressed", style(TEAL_DARK, 14))
	return b

static func ghost_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", TEAL_DARK)
	b.add_theme_stylebox_override("normal", style(Color.TRANSPARENT, 12, LINE))
	b.add_theme_stylebox_override("hover", style(FIELD, 12, LINE))
	b.add_theme_stylebox_override("pressed", style(FIELD, 12, LINE))
	return b

static func field(placeholder: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.custom_minimum_size = Vector2(0, 54)
	f.add_theme_font_size_override("font_size", 16)
	f.add_theme_color_override("font_color", INK)
	f.add_theme_color_override("font_placeholder_color", MUTED)
	f.add_theme_stylebox_override("normal", style(FIELD, 12, LINE))
	f.add_theme_stylebox_override("focus", style(Color.WHITE, 12, TEAL))
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
