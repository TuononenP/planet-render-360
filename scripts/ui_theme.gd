class_name UiTheme
extends RefCounted

## Shared theme: warm atlas paper, deep-teal ink, one amber accent.
## Sizes are logical points at the 390pt design frame (see Responsive):
## body text never drops below 14pt and touch targets stay >= 48pt tall,
## so controls stay legible on phones and on macOS alike.
##
## Palette colours are mutable so the picker can offer UI colour
## choices (see apply_palette). Every factory below reads the current
## values, and each apply_* helper can re-skin an existing control
## after a palette change. INK/MUTED never change: body text contrast
## must hold in every palette.

static var BG := Color(0.937, 0.945, 0.910)
static var CARD := Color(1, 1, 1)
static var INK := Color(0.07, 0.10, 0.09)
static var MUTED := Color(0.38, 0.42, 0.39)
static var TEAL := Color(0.16, 0.42, 0.36)
static var TEAL_DARK := Color(0.10, 0.32, 0.27)
static var TEAL_SOFT := Color(0.87, 0.93, 0.89)
static var AMBER := Color(0.93, 0.62, 0.20)
static var DARK_PANEL := Color(0.07, 0.12, 0.11, 0.88)
static var LINE := Color(0.84, 0.86, 0.82)
static var FIELD := Color(0.97, 0.98, 0.96)

static var theme_index := 0
static var theme_names: Array[String] = ["Teal", "Ocean", "Sunset", "Forest"]

## Switch the accent/background palette. Controls created afterwards
## pick the new colours up automatically; existing controls need an
## apply_* pass (MapPicker does this on selection).
static func apply_palette(index: int) -> void:
	theme_index = clampi(index, 0, theme_names.size() - 1)
	match theme_index:
		1:  # Ocean
			BG = Color(0.905, 0.935, 0.965)
			TEAL = Color(0.10, 0.38, 0.62)
			TEAL_DARK = Color(0.06, 0.27, 0.45)
			TEAL_SOFT = Color(0.85, 0.91, 0.96)
			AMBER = Color(0.95, 0.55, 0.22)
			LINE = Color(0.79, 0.85, 0.90)
			FIELD = Color(0.96, 0.98, 1.0)
		2:  # Sunset
			BG = Color(0.970, 0.930, 0.880)
			TEAL = Color(0.76, 0.32, 0.18)
			TEAL_DARK = Color(0.56, 0.22, 0.12)
			TEAL_SOFT = Color(0.96, 0.88, 0.82)
			AMBER = Color(0.90, 0.52, 0.14)
			LINE = Color(0.89, 0.82, 0.75)
			FIELD = Color(0.99, 0.97, 0.94)
		3:  # Forest
			BG = Color(0.915, 0.945, 0.885)
			TEAL = Color(0.20, 0.48, 0.24)
			TEAL_DARK = Color(0.13, 0.34, 0.16)
			TEAL_SOFT = Color(0.86, 0.92, 0.84)
			AMBER = Color(0.88, 0.58, 0.18)
			LINE = Color(0.80, 0.86, 0.78)
			FIELD = Color(0.96, 0.98, 0.95)
		_:  # Teal (default)
			BG = Color(0.937, 0.945, 0.910)
			TEAL = Color(0.16, 0.42, 0.36)
			TEAL_DARK = Color(0.10, 0.32, 0.27)
			TEAL_SOFT = Color(0.87, 0.93, 0.89)
			AMBER = Color(0.93, 0.62, 0.20)
			LINE = Color(0.84, 0.86, 0.82)
			FIELD = Color(0.97, 0.98, 0.96)
	CARD = Color(1, 1, 1)
	DARK_PANEL = Color(0.07, 0.12, 0.11, 0.88)

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

static func apply_primary(b: Button) -> void:
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	b.add_theme_stylebox_override("normal", style(TEAL, 14, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("hover", style(TEAL_DARK, 14, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("pressed", style(TEAL_DARK.darkened(0.25), 14))
	b.add_theme_stylebox_override("focus", style(TEAL, 14, AMBER))

static func primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 17)
	apply_primary(b)
	return b

static func apply_ghost(b: Button) -> void:
	b.add_theme_color_override("font_color", TEAL_DARK)
	b.add_theme_color_override("font_hover_color", TEAL_DARK)
	b.add_theme_color_override("font_pressed_color", TEAL_DARK)
	b.add_theme_color_override("font_focus_color", TEAL_DARK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", style(CARD, 12, LINE, true))
	b.add_theme_stylebox_override("hover", style(TEAL_SOFT, 12, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, 12, TEAL))
	b.add_theme_stylebox_override("focus", style(CARD, 12, AMBER))

static func ghost_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 16)
	apply_ghost(b)
	return b

## Skin an OptionButton and its popup. Both need explicit colours for
## every state: without font_hover_color the engine default renders
## near-white text on the near-white hover box (the "Auto layout"
## label vanished on hover), and the unstyled popup did the same.
static func apply_option(b: OptionButton) -> void:
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", style(FIELD, 12, LINE))
	b.add_theme_stylebox_override("hover", style(Color.WHITE, 12, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, 12, TEAL))
	b.add_theme_stylebox_override("focus", style(FIELD, 12, AMBER))
	b.add_theme_stylebox_override("disabled", style(FIELD, 12, LINE))
	var popup := b.get_popup()
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", Color.WHITE)
	popup.add_theme_color_override("font_disabled_color", MUTED)
	popup.add_theme_color_override("font_separator_color", LINE)
	popup.add_theme_stylebox_override("panel", style(CARD, 12, LINE, true))
	popup.add_theme_stylebox_override("hover", style(TEAL, 8))
	popup.add_theme_stylebox_override("separator", style(LINE, 0))

static func _chip_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := style(bg, 22, border, true)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

## Re-skin a quick-pick chip. The selected chip gets the accent fill
## with white text in every state, so the active place stays obvious
## after the tap (chips are toggle buttons; see chip_button).
static func apply_chip(b: Button, selected: bool = false) -> void:
	if selected:
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.add_theme_stylebox_override("normal", _chip_style(TEAL, TEAL_DARK))
		b.add_theme_stylebox_override("hover", _chip_style(TEAL_DARK, TEAL_DARK))
		b.add_theme_stylebox_override("pressed", _chip_style(TEAL, TEAL_DARK))
		b.add_theme_stylebox_override("focus", _chip_style(TEAL, AMBER))
	else:
		b.add_theme_color_override("font_color", TEAL_DARK)
		b.add_theme_color_override("font_hover_color", TEAL_DARK)
		b.add_theme_color_override("font_pressed_color", TEAL_DARK)
		b.add_theme_color_override("font_focus_color", TEAL_DARK)
		b.add_theme_stylebox_override("normal", _chip_style(CARD, LINE))
		b.add_theme_stylebox_override("hover", _chip_style(TEAL_SOFT, TEAL))
		b.add_theme_stylebox_override("pressed", _chip_style(TEAL_SOFT, TEAL))
		b.add_theme_stylebox_override("focus", _chip_style(CARD, AMBER))

## One-tap place chip for the picker's quick picks. Toggle mode lets
## the tapped chip stay pressed as the visible selection.
static func chip_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 13)
	apply_chip(b)
	return b

static func section_label(text: String) -> Label:
	return label(text, 13, MUTED, true)

static func apply_field(f: LineEdit) -> void:
	f.add_theme_color_override("font_color", INK)
	f.add_theme_color_override("font_placeholder_color", MUTED)
	f.add_theme_stylebox_override("normal", style(CARD, 12, LINE, true))
	f.add_theme_stylebox_override("focus", style(Color.WHITE, 12, TEAL))
	f.add_theme_stylebox_override("read_only", style(FIELD, 12, LINE))

static func field(placeholder: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.custom_minimum_size = Vector2(0, 54)
	f.add_theme_font_size_override("font_size", 16)
	apply_field(f)
	return f

static func pill(text: String, size: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color(1, 1, 1, 0.92), 22, Color.TRANSPARENT, true))
	var l := label(text, size, INK, true)
	p.add_child(l)
	p.set_meta("label", l)
	return p

static func apply_icon(b: Button) -> void:
	b.add_theme_color_override("font_color", TEAL_DARK)
	b.add_theme_color_override("font_hover_color", TEAL_DARK)
	b.add_theme_color_override("font_pressed_color", TEAL_DARK)
	b.add_theme_color_override("font_focus_color", TEAL_DARK)
	b.add_theme_stylebox_override("normal", style(Color(1, 1, 1, 0.94), 16, Color.TRANSPARENT, true))
	b.add_theme_stylebox_override("hover", style(Color.WHITE, 16, TEAL, true))
	b.add_theme_stylebox_override("pressed", style(FIELD, 16, TEAL, true))
	b.add_theme_stylebox_override("focus", style(Color(1, 1, 1, 0.94), 16, AMBER))

static func icon_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_font_size_override("font_size", 22)
	apply_icon(b)
	return b
