class_name UiTheme
extends RefCounted

## Shared theme from the Planet Render 360 design system (Night):
## a thin layer of glass over the scene, one luminous accent, ink on
## sky. Colour values are the design system's tokens; the old names
## (BG, TEAL, ...) stay so call sites keep reading from here. Sizes
## are logical points at the 390pt design frame (see Responsive): body
## text never drops below 14pt and touch targets stay >= 44pt.
##
## The accent is mutable so the picker can offer the five accents (see
## apply_palette). Every factory below reads the current values, and
## each apply_* helper can re-skin an existing control after a change.
## INK/MUTED never change: body text contrast must hold in every
## accent. TEAL is the live accent in every palette (the name predates
## the design system); ON_ACCENT is the text on it. Plain glass
## (GLASS_FILL) carries INK only; anything with secondary text sits on
## CARD (glass-strong).

const FONT_SANS := "res://assets/fonts/InstrumentSans-Variable.ttf"
const FONT_SERIF := "res://assets/fonts/InstrumentSerif-Regular.ttf"
const FONT_MONO := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const FONT_MONO_MEDIUM := "res://assets/fonts/IBMPlexMono-Medium.ttf"

static var SKY_000 := Color("06090f")  # globe backdrop and the descent
static var BG := Color("0b1019")  # sky-100, the app ground
static var CARD := Color(0.043, 0.063, 0.098, 0.84)  # glass-strong: panels, sheets, popups
static var SURFACE := Color("121925")  # sky-200, solid cards
static var INK := Color("edf1f6")
static var MUTED := Color("a4aebd")  # ink-muted
static var FAINT := Color("828c9c")  # ink-faint: placeholders, timestamps; never on glass
static var TEAL := Color("8cc8ff")  # live accent, default Glacier
static var TEAL_DARK := Color("8cc8ff").darkened(0.25)
static var TEAL_SOFT := Color(0.549, 0.784, 1.0, 0.16)  # accent-soft
static var AMBER := Color("f0b06a")  # horizon-golden: where the sun is
static var ON_ACCENT := Color("07101a")
static var DARK_PANEL := Color(0.043, 0.063, 0.098, 0.66)
static var GLASS_FILL := Color(0.043, 0.063, 0.098, 0.66)  # glass: chips, pills, icon buttons
static var GLASS_EDGE := Color(0.929, 0.945, 0.965, 0.14)
static var LINE := Color(0.929, 0.945, 0.965, 0.10)  # decorative hairline
static var LINE_STRONG := Color("6a7584")  # borders that alone define a control
static var FIELD := Color("1b2433")  # sky-300, inset fields
static var SIGNAL_GOOD := Color("7cc0ff")
static var SIGNAL_CAUTION := Color("f2c36b")
static var FOCUS := Color("f4f7fb")
static var SIGNAL_ERROR := Color("ff8f66")
const HORIZON_NIGHT := Color("1a2350")  # descent glow; same in every theme

const RADIUS_XS := 6
const RADIUS_S := 10
const RADIUS_M := 14
const RADIUS_L := 20
const RADIUS_XL := 28
const RADIUS_PILL := 999

static var theme_index := 0
## Auto accent: the sun picks theme_index (see AccentSun). The Auto chip
## in Settings sits after the five swatches.
static var auto_mode := false
const AUTO_CHIP := 5
static var theme_names: Array[String] = ["Glacier", "Aurora", "Dusk", "Dawn", "Lichen"]
const ACCENTS: Array[Color] = [
	Color("8cc8ff"),  # Glacier (default)
	Color("6fe3a5"),  # Aurora
	Color("ffa46e"),  # Dusk
	Color("f5a3c3"),  # Dawn
	Color("cddc7a"),  # Lichen
]

static var _font_cache := {}

## The imported font when the editor has imported it, else the raw
## file read as a dynamic font, so a fresh checkout still shows the
## design system's type before its first editor import.
static func _font(path: String) -> Font:
	if not _font_cache.has(path):
		var f: Font = load(path) if ResourceLoader.exists(path) else null
		if f == null:
			var raw := FontFile.new()
			if raw.load_dynamic_font(path) == OK:
				f = raw
		_font_cache[path] = f
	return _font_cache[path]

## Root theme: Instrument Sans at 15pt (body) for every Control.
static func base_theme() -> Theme:
	var t := Theme.new()
	t.default_font = sans()
	t.default_font_size = 15
	return t

## Instrument Sans at a weight (400 body, 600 titles, labels and buttons).
static func sans(weight: int = 400) -> Font:
	var key := "sans%d" % weight
	if not _font_cache.has(key):
		var f := FontVariation.new()
		f.base_font = _font(FONT_SANS)
		f.variation_opentype = {"wght": weight}
		_font_cache[key] = f
	return _font_cache[key]

## Instrument Serif: place names and arrival moments only.
static func display() -> Font:
	return _font(FONT_SERIF)

## IBM Plex Mono with tabular figures: coordinates, elevation, time.
static func data(medium: bool = false) -> Font:
	var key := "mono-medium" if medium else "mono"
	if not _font_cache.has(key):
		var f := FontVariation.new()
		f.base_font = _font(FONT_MONO_MEDIUM if medium else FONT_MONO)
		f.opentype_features = {"tnum": 1}
		_font_cache[key] = f
	return _font_cache[key]

## Switch the accent. Controls created afterwards pick the new colours
## up automatically; existing controls need an apply_* pass (MapPicker
## does this on selection, View360 via refresh_theme).
static func apply_palette(index: int) -> void:
	auto_mode = false
	AccentSun.cancel()
	theme_index = clampi(index, 0, theme_names.size() - 1)
	set_accent(ACCENTS[theme_index])

## Repoint the live accent and the colours derived from it.
static func set_accent(c: Color) -> void:
	TEAL = c
	TEAL_DARK = TEAL.darkened(0.25)
	TEAL_SOFT = Color(TEAL, 0.16)
	HudStyle.ACCENT = TEAL

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
		s.shadow_color = Color(0, 0, 0, 0.40)
		s.shadow_size = 14
		s.shadow_offset = Vector2(0, 10)
	return s

## Panel glass: the sheet, side panel and cards. Translucency plus a
## lit 1px edge (glass-edge) and shadow-3, not a blur.
static func glass_panel(radius: int = RADIUS_XL) -> StyleBoxFlat:
	var st := style(CARD, radius, GLASS_EDGE, true)
	st.shadow_color = Color(0, 0, 0, 0.48)
	st.shadow_size = 20
	st.shadow_offset = Vector2(0, -12)
	return st

## Label in Instrument Sans: semibold (600) when `bold`, else regular.
static func label(text: String, size: int, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", sans(600))
	return l

## Coordinates as the design system sets them: 4 decimals, hemisphere
## letter, two spaces between ("45.9763° N  7.6586° E").
static func coords(lat: float, lon: float) -> String:
	return "%.4f° %s  %.4f° %s" % [absf(lat), "N" if lat >= 0.0 else "S",
		absf(lon), "E" if lon >= 0.0 else "W"]

## Place names and arrival titles in Instrument Serif.
static func display_label(text: String, size: int, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", display())
	return l

## Numbers someone might compare, in tabular IBM Plex Mono.
static func data_label(text: String, size: int, color: Color = INK, medium: bool = false) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", data(medium))
	return l

static func _set_font_colors(b: Control, color: Color) -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, color)

static func _focus_ring(radius: int) -> StyleBoxFlat:
	var f := style(Color.TRANSPARENT, radius, FOCUS)
	f.set_border_width_all(2)
	return f

static func apply_primary(b: Button) -> void:
	_set_font_colors(b, ON_ACCENT)
	b.add_theme_color_override("font_disabled_color", Color(ON_ACCENT, 0.6))
	var fill := style(TEAL, RADIUS_PILL)
	b.add_theme_stylebox_override("normal", fill)
	b.add_theme_stylebox_override("hover", style(TEAL.lightened(0.12), RADIUS_PILL))
	b.add_theme_stylebox_override("pressed", style(TEAL_DARK, RADIUS_PILL))
	# opacity-disabled (0.38): busy or unavailable reads as the same button, dimmed.
	b.add_theme_stylebox_override("disabled", style(Color(TEAL, 0.38), RADIUS_PILL))
	b.add_theme_stylebox_override("focus", _focus_ring(RADIUS_PILL))

static func primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)  # size-control-l
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_font_override("font", sans(600))
	apply_primary(b)
	return b

## Secondary glass button: quiet until hovered, then accent-edged.
static func apply_ghost(b: Button) -> void:
	_set_font_colors(b, INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", style(Color(1, 1, 1, 0.04), RADIUS_PILL, LINE_STRONG))
	b.add_theme_stylebox_override("hover", style(TEAL_SOFT, RADIUS_PILL, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, RADIUS_PILL, TEAL))
	b.add_theme_stylebox_override("focus", _focus_ring(RADIUS_PILL))

static func ghost_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)  # size-control
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_font_override("font", sans(600))
	apply_ghost(b)
	return b

## Quiet button: text only until hovered (Cancel, Back to map).
static func apply_quiet(b: Button) -> void:
	_set_font_colors(b, INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	var flat := style(Color.TRANSPARENT, RADIUS_PILL)
	flat.content_margin_top = 0
	flat.content_margin_bottom = 0
	b.add_theme_stylebox_override("normal", flat)
	var hover := flat.duplicate() as StyleBoxFlat
	hover.bg_color = Color(INK, 0.08)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", _focus_ring(RADIUS_PILL))

static func quiet_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)  # size-control
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_font_override("font", sans(600))
	apply_quiet(b)
	return b

## Skin an OptionButton and its popup. Both need explicit colours for
## every state: without font_hover_color the engine default renders
## near-white text on the hover box, and the unstyled popup did the
## same. The popup's hover row is the accent, so its text is dark.
static func apply_option(b: OptionButton) -> void:
	_set_font_colors(b, INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_stylebox_override("normal", style(FIELD, RADIUS_M, LINE_STRONG))
	b.add_theme_stylebox_override("hover", style(FIELD.lightened(0.06), RADIUS_M, TEAL))
	b.add_theme_stylebox_override("pressed", style(TEAL_SOFT, RADIUS_M, TEAL))
	b.add_theme_stylebox_override("focus", _focus_ring(RADIUS_M))
	b.add_theme_stylebox_override("disabled", style(FIELD, RADIUS_M, LINE))
	var popup := b.get_popup()
	popup.add_theme_font_size_override("font_size", 15)
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", ON_ACCENT)
	popup.add_theme_color_override("font_disabled_color", MUTED)
	popup.add_theme_color_override("font_separator_color", LINE)
	var panel := style(CARD, RADIUS_M, GLASS_EDGE, true)
	panel.content_margin_left = 8
	panel.content_margin_right = 8
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	popup.add_theme_stylebox_override("panel", panel)
	popup.add_theme_stylebox_override("hover", style(TEAL, RADIUS_S))
	popup.add_theme_stylebox_override("separator", style(LINE, 0))

static func _chip_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := style(bg, RADIUS_PILL, border)
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
		b.add_theme_stylebox_override("focus", _chip_style(TEAL, FOCUS))
	else:
		_set_font_colors(b, INK)
		b.add_theme_stylebox_override("normal", _chip_style(GLASS_FILL, LINE_STRONG))
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
	b.add_theme_font_override("font", sans(600))
	apply_chip(b)
	return b

static func section_label(text: String) -> Label:
	return data_label(text.to_upper(), 12, MUTED, true)

## Inset field; `pill` for a search bar floating over the scene.
static func apply_field(f: LineEdit, pill: bool = false) -> void:
	var radius := RADIUS_PILL if pill else RADIUS_M
	f.add_theme_color_override("font_color", INK)
	f.add_theme_color_override("font_placeholder_color", FAINT)
	f.add_theme_color_override("caret_color", TEAL)
	f.add_theme_color_override("selection_color", Color(TEAL, 0.35))
	f.add_theme_stylebox_override("normal", style(FIELD, radius, LINE_STRONG))
	f.add_theme_stylebox_override("focus", style(FIELD, radius, TEAL))
	f.add_theme_stylebox_override("read_only", style(FIELD, radius, LINE))

static func field(placeholder: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = placeholder
	f.custom_minimum_size = Vector2(0, 52)  # size-search
	f.add_theme_font_size_override("font_size", 16)
	apply_field(f)
	return f

## The map's search bar: a pill with the search icon at its right end.
static func search_field(placeholder: String) -> LineEdit:
	var f := field(placeholder)
	apply_field(f, true)
	f.right_icon = UiIcon.texture("search", 20, 1.0)
	f.add_theme_color_override("clear_button_color", MUTED)
	f.add_theme_color_override("clear_button_color_pressed", INK)
	f.add_theme_constant_override("minimum_character_width", 8)
	return f

## Thin, quiet scrollbars: a 4pt rounded grabber, no track.
static func apply_scroll(sc: ScrollContainer) -> void:
	for bar in [sc.get_h_scroll_bar(), sc.get_v_scroll_bar()]:
		var empty := StyleBoxEmpty.new()
		bar.add_theme_stylebox_override("scroll", empty)
		bar.add_theme_stylebox_override("scroll_focus", empty)
		for key in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var g := style(Color(LINE_STRONG, 0.7 if key == "grabber" else 1.0), 2)
			g.set_content_margin_all(2)
			bar.add_theme_stylebox_override(key, g)

## A filled circle texture (accent swatches in chips).
static func dot(color: Color, size: int = 14) -> Texture2D:
	var px := size * 2
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) / 2.0
	for y in px:
		for x in px:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			img.set_pixel(x, y, Color(color, clampf(c.x - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

## "Venice, Italy" -> ["Venice", "Italy"]. Names that are only
## coordinates ("48.86, 2.35") are not split.
static func split_place(full: String) -> Array:
	var comma := full.find(",")
	if comma < 0 or full.left(comma).strip_edges().is_valid_float():
		return [full, ""]
	return [full.left(comma).strip_edges(), full.substr(comma + 1).strip_edges()]

static func pill(text: String, size: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(GLASS_FILL, RADIUS_PILL, GLASS_EDGE))
	var l := label(text, size, INK, true)
	p.add_child(l)
	p.set_meta("label", l)
	return p

static func apply_icon(b: Button) -> void:
	_set_font_colors(b, INK)
	b.add_theme_stylebox_override("normal", style(GLASS_FILL, RADIUS_PILL, GLASS_EDGE, true))
	b.add_theme_stylebox_override("hover", style(GLASS_FILL.blend(Color(INK, 0.14)), RADIUS_PILL, GLASS_EDGE, true))
	b.add_theme_stylebox_override("pressed", style(TEAL, RADIUS_PILL))
	for key in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, ON_ACCENT)  # active = accent fill + on-accent glyph
	b.add_theme_stylebox_override("focus", _focus_ring(RADIUS_PILL))

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
	var flat := style(Color.TRANSPARENT, RADIUS_PILL)
	flat.content_margin_left = 4
	flat.content_margin_right = 4
	flat.content_margin_top = 4
	flat.content_margin_bottom = 4
	b.add_theme_stylebox_override("normal", flat)
	var hover := flat.duplicate() as StyleBoxFlat
	hover.bg_color = Color(INK, 0.10)
	b.add_theme_stylebox_override("hover", hover)
	var pressed := flat.duplicate() as StyleBoxFlat
	pressed.bg_color = TEAL_SOFT
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", _focus_ring(RADIUS_PILL))

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
	var st := style(GLASS_FILL, RADIUS_PILL, GLASS_EDGE, true)
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
