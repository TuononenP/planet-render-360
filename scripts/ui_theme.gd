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
## The other horizon-* stops (sun-arc track); decorative, same in every theme.
const HORIZON_DAWN := Color("d98a8f")
const HORIZON_DAY := Color("7fb8e6")
const HORIZON_DUSK := Color("b8607e")

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
## The live theme's accents (Night is luminous, Day deep), in swatch order.
static var ACCENTS: Array[Color] = NIGHT_ACCENTS.duplicate()
const NIGHT_ACCENTS: Array[Color] = [
	Color("8cc8ff"),  # Glacier (default)
	Color("6fe3a5"),  # Aurora
	Color("ffa46e"),  # Dusk
	Color("f5a3c3"),  # Dawn
	Color("cddc7a"),  # Lichen
]
const DAY_ACCENTS: Array[Color] = [
	Color("1d5fa8"), Color("0b7148"), Color("a8410f"), Color("ad3767"), Color("566510"),
]

## Night (the default and the reference) and Day: the same token names,
## so components never branch on the theme (design system Colour).
const NIGHT := {
	"sky_000": Color("06090f"), "sky_100": Color("0b1019"), "sky_200": Color("121925"),
	"sky_300": Color("1b2433"), "line": Color(0.929, 0.945, 0.965, 0.10),
	"line_strong": Color("6a7584"), "glass": Color(0.043, 0.063, 0.098, 0.66),
	"glass_strong": Color(0.043, 0.063, 0.098, 0.84), "glass_edge": Color(0.929, 0.945, 0.965, 0.14),
	"ink": Color("edf1f6"), "ink_muted": Color("a4aebd"), "ink_faint": Color("828c9c"),
	"on_accent": Color("07101a"), "signal_good": Color("7cc0ff"), "signal_caution": Color("f2c36b"),
	"signal_error": Color("ff8f66"), "focus": Color("f4f7fb"),
}
const DAY := {
	"sky_000": Color("e6eaef"), "sky_100": Color("f2f4f7"), "sky_200": Color("ffffff"),
	"sky_300": Color("e3e8ee"), "line": Color(0.051, 0.078, 0.125, 0.10),
	"line_strong": Color("7a8494"), "glass": Color(0.969, 0.977, 0.984, 0.74),
	"glass_strong": Color(0.969, 0.977, 0.984, 0.92), "glass_edge": Color(1.0, 1.0, 1.0, 0.70),
	"ink": Color("0d1420"), "ink_muted": Color("465163"), "ink_faint": Color("576274"),
	"on_accent": Color("ffffff"), "signal_good": Color("1a5fa3"), "signal_caution": Color("8a5600"),
	"signal_error": Color("b23c12"), "focus": Color("0d1420"),
}
## 0 Night, 1 Day, 2 Match system (Settings → Appearance → Theme).
static var theme_mode := 0
static var is_day := false

## Points every colour token at Night or Day ("Match system" asks the
## OS), then applies Solid panels and Increase contrast (UiPrefs).
## Screens built afterwards pick the palette up; Main rebuilds the
## screens after a switch, which is instant (no glide).
static func apply_mode(mode: int) -> void:
	theme_mode = mode
	is_day = mode == 1 or (mode == 2 and DisplayServer.is_dark_mode_supported()
		and not DisplayServer.is_dark_mode())
	var t: Dictionary = DAY if is_day else NIGHT
	SKY_000 = t["sky_000"]
	BG = t["sky_100"]
	SURFACE = t["sky_200"]
	FIELD = t["sky_300"]
	LINE = t["line"]
	LINE_STRONG = t["line_strong"]
	GLASS_FILL = t["glass"]
	DARK_PANEL = t["glass"]
	CARD = t["glass_strong"]
	GLASS_EDGE = t["glass_edge"]
	INK = t["ink"]
	MUTED = t["ink_muted"]
	FAINT = t["ink_faint"]
	ON_ACCENT = t["on_accent"]
	SIGNAL_GOOD = t["signal_good"]
	SIGNAL_CAUTION = t["signal_caution"]
	SIGNAL_ERROR = t["signal_error"]
	FOCUS = t["focus"]
	if UiPrefs.solid_panels:
		GLASS_FILL = Color(SURFACE, 0.96)
		DARK_PANEL = GLASS_FILL
		CARD = Color(SURFACE, 1.0)
	if UiPrefs.high_contrast:
		MUTED = INK
		LINE = LINE_STRONG
		GLASS_EDGE = Color(INK, 0.45)
	ACCENTS = (DAY_ACCENTS if is_day else NIGHT_ACCENTS).duplicate()
	HudStyle.sync_palette()
	set_accent(ACCENTS[clampi(theme_index, 0, ACCENTS.size() - 1)])

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

## The Instrument Sans file itself, for callers that wrap it in their own
## FontVariation (map labels), through the same import fallback.
static func sans_file() -> Font:
	return _font(FONT_SANS)

## Root theme: Instrument Sans at 15pt (body) for every Control.
static func base_theme() -> Theme:
	var t := Theme.new()
	t.default_font = sans()
	t.default_font_size = 15
	# Ink by default, so a control without its own colours still reads in
	# both themes.
	for type in ["Label", "Button", "LineEdit", "OptionButton", "PopupMenu"]:
		t.set_color("font_color", type, INK)
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
	TEAL_SOFT = Color(TEAL, 0.12 if is_day else 0.16)
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
		s.shadow_color = Color(0.09, 0.137, 0.22, 0.16) if is_day else Color(0, 0, 0, 0.40)
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
## Motion tokens (design system Motion), in seconds.
const DURATION := {"instant": 0.09, "quick": 0.16, "standard": 0.24,
	"gentle": 0.38, "slow": 0.6, "descent": 2.4}

## The type scale by token name: [family, size, weight]. Family is
## "display" (Instrument Serif), "sans" (Instrument Sans) or "mono"
## (IBM Plex Mono, tabular figures).
const TYPE := {
	"display-xl": ["display", 48, 400], "display-l": ["display", 36, 400],
	"display-m": ["display", 28, 400], "display-s": ["display", 22, 400],
	"title": ["sans", 20, 600], "headline": ["sans", 17, 600], "body": ["sans", 15, 400],
	"body-s": ["sans", 14, 400], "label": ["sans", 14, 600], "caption": ["sans", 12, 500],
	"data-l": ["mono", 24, 500], "data": ["mono", 15, 400], "data-s": ["mono", 13, 500],
	"eyebrow": ["mono", 12, 500],
}

## A label set in a named text style ("body-s", "data-l", ...).
static func text(value: String, style_name: String, color: Color = INK) -> Label:
	var t: Array = TYPE[style_name]
	match str(t[0]):
		"display":
			return display_label(value, int(t[1]), color)
		"mono":
			return data_label(value, int(t[1]), color, int(t[2]) >= 500)
	var l := label(value, int(t[1]), color)
	if int(t[2]) != 400:
		l.add_theme_font_override("font", sans(int(t[2])))
	return l

## Text size from Settings → Appearance (85%–200%). Every label scales;
## display styles stop at 130% so a place name never pushes Explore off
## screen (design system Accessibility → Large text).
static var text_scale := 1.0
const DISPLAY_SCALE_CAP := 1.3

static func label(text: String, size: int, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", roundi(size * text_scale))
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", sans(600 if bold else 400))
	return l

## Coordinates as the design system sets them: 4 decimals, hemisphere
## letter, two spaces between ("45.9763° N  7.6586° E").
static func coords(lat: float, lon: float) -> String:
	if units_dms:
		return "%s %s  %s %s" % [_dms(lat), "N" if lat >= 0.0 else "S",
			_dms(lon), "E" if lon >= 0.0 else "W"]
	return "%.4f° %s  %.4f° %s" % [absf(lat), "N" if lat >= 0.0 else "S",
		absf(lon), "E" if lon >= 0.0 else "W"]

## Settings → Units (RenderSettings persists them): imperial elevation,
## degrees-minutes-seconds coordinates, 12-hour clock.
static var units_imperial := false
static var units_dms := false
static var units_12h := false

static func _dms(v: float) -> String:
	var a := absf(v)
	var d := int(a)
	var m := int((a - d) * 60.0)
	var sec := (a - d - m / 60.0) * 3600.0
	return "%d° %02d′ %04.1f″" % [d, m, sec]

## Thousands grouped with commas ("4,478").
static func grouped(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out

## Elevation with locale grouping and a space before the unit:
## "4,478 m" or "14,692 ft".
static func elevation(metres: float) -> String:
	if units_imperial:
		return "%s ft" % grouped(roundi(metres * 3.28084))
	return "%s m" % grouped(roundi(metres))

## Local clock time, 24-hour unless Settings asks for 12.
static func clock(hour_f: float) -> String:
	var minutes := roundi(fposmod(hour_f, 24.0) * 60.0) % 1440
	var h := int(minutes / 60.0)
	var m := minutes % 60
	if units_12h:
		return "%d:%02d %s" % [(h + 11) % 12 + 1, m, "AM" if h < 12 else "PM"]
	return "%02d:%02d" % [h, m]

## "UTC+1", "UTC−3:30", "UTC" from an offset in seconds.
static func utc_label(offset_s: int) -> String:
	if offset_s == 0:
		return "UTC"
	var a := absi(offset_s)
	var hrs := int(a / 3600.0)
	var mins := int((a % 3600) / 60.0)
	var sign := "+" if offset_s > 0 else "−"
	return "UTC%s%d" % [sign, hrs] if mins == 0 else "UTC%s%d:%02d" % [sign, hrs, mins]

## Cache size: whole megabytes under 1 GB ("86 MB"), one decimal above
## ("1.4 GB").
static func cache_size(bytes: int) -> String:
	var mb := float(bytes) / 1048576.0
	if mb < 1024.0:
		return "%d MB" % roundi(mb)
	return "%.1f GB" % (mb / 1024.0)

const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

## When something happened, in the device's local time: "Today, 09:12",
## "Yesterday", "3 Oct" ("3 Oct 2025" in an earlier year). `now` is for tests.
static func relative_time(unix: float, now: float = -1.0) -> String:
	if now < 0.0:
		now = Time.get_unix_time_from_system()
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var at := int(unix) + bias
	var days := floori(float(int(now) + bias) / 86400.0) - floori(float(at) / 86400.0)
	var d := Time.get_datetime_dict_from_unix_time(at)
	if days <= 0:
		return "Today, %02d:%02d" % [d["hour"], d["minute"]]
	if days == 1:
		return "Yesterday"
	var today := Time.get_datetime_dict_from_unix_time(int(now) + bias)
	var date := "%d %s" % [d["day"], MONTHS[int(d["month"]) - 1]]
	return date if d["year"] == today["year"] else "%s %d" % [date, d["year"]]

## Place names and arrival titles in Instrument Serif.
static func display_label(text: String, size: int, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_size_override("font_size", roundi(size * minf(text_scale, DISPLAY_SCALE_CAP)))
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

## Panel glass's lit top (glass-sheen): a 24pt gradient inside the top
## edge, from the sheen colour to clear, kept off the rounded corners.
static func add_sheen(panel: Control, radius: int) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.55 if is_day else 0.08))
	g.set_color(1, Color(1, 1, 1, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 24
	# Drawn on the panel itself: a child would be stretched over the whole
	# content rect by the container (a tinted box behind the content).
	panel.draw.connect(func() -> void:
		panel.draw_texture_rect(tex, Rect2(radius, 1, maxf(panel.size.x - 2.0 * radius, 0.0), 24), false))
	panel.queue_redraw()

## The focus-ring token: a 2pt gap, then a 2pt solid `focus` ring that
## follows the control's radius. Keyboard focus only (project setting
## gui/common/show_focus_state_on_pointer_event is off).
static func _focus_ring(radius: int) -> StyleBoxFlat:
	var f := style(Color.TRANSPARENT, mini(radius + 4, RADIUS_PILL), FOCUS)
	f.draw_center = false
	f.set_border_width_all(2)
	f.set_expand_margin_all(4)
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
	# Round glyph buttons: the glyph sits in the middle, no text padding.
	for state in ["normal", "hover", "pressed"]:
		(b.get_theme_stylebox(state) as StyleBoxFlat).set_content_margin_all(0)

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
