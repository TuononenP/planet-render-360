class_name UiTheme
extends RefCounted

## Shared theme "Night Atlas": smoked glass over the map and the scene,
## one glowing accent, light text. Sizes are logical points at the
## 390pt design frame (see Responsive): body text never drops below
## 14pt and touch targets stay >= 44pt, so controls stay legible on
## phones and on macOS alike.
##
## Palette colours are mutable so the picker can offer accent
## choices (see apply_palette). Every factory below reads the current
## values, and each apply_* helper can re-skin an existing control
## after a palette change. INK/MUTED never change: body text contrast
## must hold in every palette. TEAL is the accent in every palette
## (the name predates the other accents); ON_ACCENT is the text on it.

static var BG := Color(0.027, 0.051, 0.059)  # #070D0F
static var CARD := Color(0.039, 0.071, 0.078, 0.80)  # glass panel
static var SURFACE := Color(0.055, 0.090, 0.098)  # opaque card, #0E1719
static var INK := Color(0.949, 0.961, 0.957)  # #F2F5F4
static var MUTED := Color(0.624, 0.690, 0.682)  # #9FB0AE
static var TEAL := Color(0.180, 0.769, 0.714)  # #2EC4B6
static var TEAL_DARK := Color(0.135, 0.577, 0.536)
static var TEAL_SOFT := Color(0.180, 0.769, 0.714, 0.16)
static var AMBER := Color(0.949, 0.706, 0.353)  # sun, #F2B45A
static var ON_ACCENT := Color(0.016, 0.125, 0.114)  # #04201D
static var DARK_PANEL := Color(0.039, 0.071, 0.078, 0.72)
static var GLASS_FILL := Color(0.039, 0.075, 0.082, 0.80)  # chips, pills, icon buttons
static var LINE := Color(1, 1, 1, 0.14)
static var FIELD := Color(0.070, 0.110, 0.118, 0.88)

static var theme_index := 0
static var theme_names: Array[String] = ["Teal", "Ocean", "Sunset", "Forest"]

## Switch the accent. Controls created afterwards pick the new colours
## up automatically; existing controls need an apply_* pass (MapPicker
## does this on selection, View360 via refresh_theme).
static func apply_palette(index: int) -> void:
	theme_index = clampi(index, 0, theme_names.size() - 1)
	match theme_index:
		1:  # Ocean
			TEAL = Color(0.298, 0.659, 1.0)  # #4CA8FF
		2:  # Sunset
			TEAL = Color(0.949, 0.706, 0.353)  # #F2B45A
		3:  # Forest
			TEAL = Color(0.482, 0.847, 0.561)  # #7BD88F
		_:  # Teal (default)
			TEAL = Color(0.180, 0.769, 0.714)  # #2EC4B6
	TEAL_DARK = TEAL.darkened(0.25)
	TEAL_SOFT = Color(TEAL, 0.16)
	HudStyle.ACCENT = TEAL
	HudStyle.ACCENT_GLOW = Color(TEAL, 0.35)

static func style(bg: Color, radius: int = 16, border: Color = Color.TRANSPARENT, shadow: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.anti_aliasing = true
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	if border != Color.TRANSPARENT:
		s.border_color = border
		s.set_border_width_all(1)
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.22)
		s.shadow_size = 8
		s.shadow_offset = Vector2(0, 3)
	return s

## Floating glass panel: the sheet, side panel and cards. A hairline
## accent edge separates it from the map without a heavy shadow.
static func glass_panel(radius: int = 28) -> StyleBoxFlat:
	return style(CARD, radius, Color(TEAL, 0.28), true)

static func label(text: String, size: int, color: Color = INK, _bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func _set_font_colors(b: Control, color: Color) -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, color)

static func _focus_ring(radius: int) -> StyleBoxFlat:
	var f := style(Color.TRANSPARENT, radius, TEAL)
	f.set_border_width_all(2)
	return f

static func apply_primary(b: Button) -> void:
	_set_font_colors(b, ON_ACCENT)
	b.add_theme_color_override("font_disabled_color", Color(ON_ACCENT, 0.6))
	var glow := style(TEAL, 18, Color.TRANSPARENT, true)
	glow.shadow_color = Color(TEAL, 0.35)
	glow.shadow_size = 14
	b.add_theme_stylebox_override("normal", glow)
	var hover := style(TEAL.lightened(0.15), 18, Color.TRANSPARENT, true)
	hover.shadow_color = Color(TEAL, 0.45)
	hover.shadow_size = 16
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", style(TEAL_DARK, 18))
	b.add_theme_stylebox_override("focus", _focus_ring(18))

static func primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 17)
	apply_primary(b)
	return b

## Secondary glass button: quiet until hovered, then accent-edged.
static func apply_ghost(b: Button) -> void:
	_set_font_colors(b, INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", style(Color(1, 1, 1, 0.04), 16, LINE))
	b.add_theme_stylebox_override("hover", style(TEAL_SOFT, 16, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, 16, TEAL))
	b.add_theme_stylebox_override("focus", _focus_ring(16))

static func ghost_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 16)
	apply_ghost(b)
	return b

## Skin an OptionButton and its popup. Both need explicit colours for
## every state: without font_hover_color the engine default renders
## near-white text on the hover box, and the unstyled popup did the
## same. The popup's hover row is the accent, so its text is dark.
static func apply_option(b: OptionButton) -> void:
	_set_font_colors(b, INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", style(FIELD, 14, LINE))
	b.add_theme_stylebox_override("hover", style(Color(0.12, 0.18, 0.19, 0.92), 14, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, 14, TEAL))
	b.add_theme_stylebox_override("focus", _focus_ring(14))
	b.add_theme_stylebox_override("disabled", style(FIELD, 14, LINE))
	var popup := b.get_popup()
	popup.add_theme_font_size_override("font_size", 15)
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", ON_ACCENT)
	popup.add_theme_color_override("font_disabled_color", MUTED)
	popup.add_theme_color_override("font_separator_color", LINE)
	var panel := style(Color(0.04, 0.08, 0.09, 0.97), 16, Color(TEAL, 0.35), true)
	panel.content_margin_left = 8
	panel.content_margin_right = 8
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	popup.add_theme_stylebox_override("panel", panel)
	popup.add_theme_stylebox_override("hover", style(TEAL, 10))
	popup.add_theme_stylebox_override("separator", style(LINE, 0))

static func _chip_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := style(bg, 22, border)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

## Re-skin a quick-pick chip. The selected chip gets the accent fill
## with dark text in every state, so the active place stays obvious
## after the tap (chips are toggle buttons; see chip_button).
static func apply_chip(b: Button, selected: bool = false) -> void:
	if selected:
		_set_font_colors(b, ON_ACCENT)
		b.add_theme_stylebox_override("normal", _chip_style(TEAL, TEAL))
		b.add_theme_stylebox_override("hover", _chip_style(TEAL.lightened(0.15), TEAL))
		b.add_theme_stylebox_override("pressed", _chip_style(TEAL, TEAL))
		b.add_theme_stylebox_override("focus", _chip_style(TEAL, INK))
	else:
		_set_font_colors(b, INK)
		b.add_theme_stylebox_override("normal", _chip_style(GLASS_FILL, LINE))
		b.add_theme_stylebox_override("hover", _chip_style(TEAL_SOFT, TEAL))
		b.add_theme_stylebox_override("pressed", _chip_style(TEAL_SOFT, TEAL))
		b.add_theme_stylebox_override("focus", _chip_style(GLASS_FILL, TEAL))

## One-tap place chip for the picker's quick picks. Toggle mode lets
## the tapped chip stay pressed as the visible selection.
static func chip_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 14)
	apply_chip(b)
	return b

static func section_label(text: String) -> Label:
	return label(text.to_upper(), 12, MUTED, true)

static func apply_field(f: LineEdit) -> void:
	f.add_theme_color_override("font_color", INK)
	f.add_theme_color_override("font_placeholder_color", MUTED)
	f.add_theme_color_override("caret_color", TEAL)
	f.add_theme_color_override("selection_color", Color(TEAL, 0.35))
	f.add_theme_stylebox_override("normal", style(FIELD, 16, LINE))
	f.add_theme_stylebox_override("focus", style(Color(0.10, 0.16, 0.17, 0.95), 16, TEAL))
	f.add_theme_stylebox_override("read_only", style(FIELD, 16, LINE))

static func field(placeholder: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.custom_minimum_size = Vector2(0, 54)
	f.add_theme_font_size_override("font_size", 16)
	apply_field(f)
	return f

static func pill(text: String, size: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(GLASS_FILL, 22, Color(TEAL, 0.28)))
	var l := label(text, size, INK, true)
	p.add_child(l)
	p.set_meta("label", l)
	return p

static func apply_icon(b: Button) -> void:
	_set_font_colors(b, INK)
	b.add_theme_stylebox_override("normal", style(GLASS_FILL, 26, LINE, true))
	b.add_theme_stylebox_override("hover", style(Color(0.12, 0.18, 0.19, 0.92), 26, TEAL, true))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, 26, TEAL))
	b.add_theme_stylebox_override("focus", _focus_ring(26))

static func icon_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_font_size_override("font_size", 22)
	apply_icon(b)
	return b

## Borderless round glyph button for icon rails and nav pills: the
## rail itself is the glass, each button only lights up on hover.
static func apply_rail_icon(b: Button) -> void:
	_set_font_colors(b, INK)
	var flat := style(Color.TRANSPARENT, 22)
	flat.content_margin_left = 4
	flat.content_margin_right = 4
	flat.content_margin_top = 4
	flat.content_margin_bottom = 4
	b.add_theme_stylebox_override("normal", flat)
	var hover := flat.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.10)
	b.add_theme_stylebox_override("hover", hover)
	var pressed := flat.duplicate() as StyleBoxFlat
	pressed.bg_color = TEAL_SOFT
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", _focus_ring(22))

static func rail_button(glyph: String, tooltip: String, font_size: int = 20) -> Button:
	var b := Button.new()
	b.text = glyph
	b.tooltip_text = tooltip
	b.custom_minimum_size = Vector2(48, 48)
	b.add_theme_font_size_override("font_size", font_size)
	apply_rail_icon(b)
	return b

## Wrap rail buttons in a glass capsule (nav pill, zoom rail).
static func rail(buttons: Array, vertical: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	var st := style(GLASS_FILL, 26, LINE, true)
	st.content_margin_left = 4
	st.content_margin_right = 4
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	var box := BoxContainer.new()
	box.vertical = vertical
	box.add_theme_constant_override("separation", 2)
	p.add_child(box)
	for b in buttons:
		box.add_child(b)
	return p
