class_name HudParts
extends RefCounted

## Design-system HUD components for the 360 view, built from the tokens:
## IconButton (round HUD glass, 40 visible inside a 44 hit area),
## PlacePill (serif name over mono coordinates), HudChip (weather),
## StatusBadge (a word plus its icon, in a glass chip over the scene)
## and Attribution (the one caption-sized line). Factories return the
## node; the apply_* helpers re-skin one after an accent change.

const SIZE_HUD := 40
const SIZE_TOUCH := 44
const OPACITY_ATTRIBUTION := 0.72

## HUD glass with the 1px edge and shadow-1, drawn `inset` px inside the
## control so a 44 hit area shows a 40 shape.
static func glass(radius: int, inset: int = 0, fill: Color = UiTheme.GLASS_FILL) -> StyleBoxFlat:
	var s := UiTheme.style(fill, radius, UiTheme.GLASS_EDGE)
	s.shadow_color = Color(0.09, 0.137, 0.22, 0.12) if UiTheme.is_day else Color(0, 0, 0, 0.32)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_expand_margin(side, -inset)
	return s

## Round glass IconButton; `label` is its tooltip and accessible name.
static func icon_button(icon_name: String, label: String) -> Button:
	var b := Button.new()
	b.tooltip_text = label
	b.accessibility_name = label
	b.custom_minimum_size = Vector2(SIZE_TOUCH, SIZE_TOUCH)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("icon", icon_name)
	apply_icon_button(b, false)
	return b

## `active` (toggles such as gyro) is an accent fill with an on-accent icon.
static func apply_icon_button(b: Button, active: bool) -> void:
	var inset := int((SIZE_TOUCH - SIZE_HUD) / 2.0)
	var fill := glass(UiTheme.RADIUS_PILL, inset, UiTheme.TEAL if active else UiTheme.GLASS_FILL)
	fill.set_content_margin_all(0)  # the 22pt icon fills the 40pt disc's centre
	# Just under half the disc: at exactly half (or a pill radius) the
	# anti-aliased 1pt edge draws a dark seam down the middle at 1x.
	fill.set_corner_radius_all(int(SIZE_HUD / 2.0) - 1)
	if active:
		fill.border_color = Color.TRANSPARENT
	var hover := fill.duplicate() as StyleBoxFlat
	if not active:
		hover.bg_color = Color(UiTheme.GLASS_FILL.lerp(UiTheme.INK, 0.12), UiTheme.GLASS_FILL.a)
	for state in ["normal", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, fill)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("hover_pressed", hover)
	var focus := UiTheme._focus_ring(UiTheme.RADIUS_PILL)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		focus.set_expand_margin(side, -inset + 2)
	b.add_theme_stylebox_override("focus", focus)
	var ink := UiTheme.ON_ACCENT if active else UiTheme.INK
	UiIcon.apply(b, str(b.get_meta("icon", "info")), 22, ink, ink)
	b.add_theme_color_override("icon_pressed_color", ink)

## Sets a toggle IconButton's icon and active state together.
static func set_icon(b: Button, icon_name: String, active: bool = false) -> void:
	b.set_meta("icon", icon_name)
	apply_icon_button(b, active)

## Chip (the viewer controls' Show row): 36 visible in a 44 hit row,
## label type and a leading icon. Selected is a check on accent-soft
## with an accent border; the label stays ink, so the sun remains the
## only accent fill in the controls.
static func chip(icon_name: String, label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.accessibility_name = label
	b.custom_minimum_size = Vector2(0, SIZE_TOUCH)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("icon", icon_name)
	b.add_theme_font_override("font", UiTheme.sans(600))
	b.add_theme_font_size_override("font_size", 14)
	apply_chip(b, false)
	return b

static func apply_chip(b: Button, selected: bool) -> void:
	var s := UiTheme.style(UiTheme.TEAL_SOFT if selected else Color.TRANSPARENT, UiTheme.RADIUS_PILL,
		UiTheme.TEAL if selected else UiTheme.LINE_STRONG)
	s.content_margin_left = 8
	s.content_margin_right = 10
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	s.set_expand_margin(SIDE_TOP, -4)
	s.set_expand_margin(SIDE_BOTTOM, -4)
	var hover := s.duplicate() as StyleBoxFlat
	if not selected:
		hover.bg_color = Color(UiTheme.INK, 0.06)
	for state in ["normal", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, s)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("hover_pressed", hover)
	var focus := UiTheme._focus_ring(UiTheme.RADIUS_PILL)
	focus.set_expand_margin(SIDE_TOP, -2)
	focus.set_expand_margin(SIDE_BOTTOM, -2)
	b.add_theme_stylebox_override("focus", focus)
	UiTheme._set_font_colors(b, UiTheme.INK)
	var tint := UiTheme.TEAL if selected else UiTheme.INK
	UiIcon.apply(b, "check" if selected else str(b.get_meta("icon", "info")), 16, tint, tint)
	b.add_theme_constant_override("h_separation", 6)
	b.set_meta("selected", selected)

## The viewer controls' labelled actions (Save photo, Copy link): an icon
## and a verb, outlined in line-strong on the glass, 40 visible in a 44 row.
static func outline_button(icon_name: String, label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, SIZE_TOUCH)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", UiTheme.sans(600))
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_constant_override("h_separation", 8)
	var s := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL, UiTheme.LINE_STRONG)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	s.set_expand_margin(SIDE_TOP, -2)
	s.set_expand_margin(SIDE_BOTTOM, -2)
	var hover := s.duplicate() as StyleBoxFlat
	hover.bg_color = Color(UiTheme.INK, 0.06)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	UiTheme._set_font_colors(b, UiTheme.INK)
	UiIcon.apply(b, icon_name, 18, UiTheme.INK, UiTheme.INK)
	return b

## PlacePill: HUD glass, size-hud tall, at most 280 wide; the name
## truncates, the coordinates sit under it in mono.
## Returns [pill, name_label, coords_label].
static func place_pill() -> Array:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(0, SIZE_HUD)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var st := glass(UiTheme.RADIUS_PILL)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(col)
	var name_label := UiTheme.display_label("", 19)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(name_label)
	# Coordinates never truncate: on a narrow pill they wrap at the gap
	# between latitude and longitude (show_place keeps "48.8566° N" whole).
	var coords := UiTheme.data_label("", 12, UiTheme.INK, true)
	coords.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(coords)
	return [pill, name_label, coords]

## HudChip: HUD glass, size-hud tall: a Lucide glyph, the value in
## data-s mono and the detail in 13/500 sans, all in ink.
## Returns [chip, icon, value_label, detail_label].
static func hud_chip() -> Array:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, SIZE_HUD)
	chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var st := glass(UiTheme.RADIUS_PILL)
	st.content_margin_left = 12
	st.content_margin_right = 12
	chip.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	chip.add_child(row)
	var icon := UiIcon.rect("sun", 18, UiTheme.INK)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var value := UiTheme.data_label("", 13, UiTheme.INK, true)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	var detail := UiTheme.label("", 13, UiTheme.INK)
	detail.add_theme_font_override("font", UiTheme.sans(500))
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(detail)
	return [chip, icon, value, detail]

## Lucide weather glyph for an Open-Meteo weather code.
static func weather_icon(code: int) -> String:
	if code in [0, 1]:
		return "sun"
	if code == 2:
		return "cloud-sun"
	if code in [45, 48]:
		return "cloud-fog"
	if code in [71, 73, 75, 77, 85, 86]:
		return "snowflake"
	if code >= 95:
		return "cloud-lightning"
	if code in [51, 53, 55, 56, 57]:
		return "cloud-drizzle"
	if code >= 51:
		return "cloud-rain"
	return "cloud"

## Tone name -> signal colour ("neutral" is ink-muted).
static func tone_color(tone: String) -> Color:
	match tone:
		"good":
			return UiTheme.SIGNAL_GOOD
		"caution":
			return UiTheme.SIGNAL_CAUTION
		"error":
			return UiTheme.SIGNAL_ERROR
	return UiTheme.MUTED

## StatusBadge in a glass-strong chip, as badges sit over the scene: a
## 24pt outline in the tone colour, 13/600 word and a 14pt icon. The
## chip is a 44pt tall button so the badge can open its detail.
static func status_badge(text: String, tone: String, icon_name: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, SIZE_TOUCH)
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	apply_status_badge(b, text, tone, icon_name)
	return b

static func apply_status_badge(b: Button, text: String, tone: String, icon_name: String) -> void:
	var c := tone_color(tone)
	b.text = text
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_font_override("font", UiTheme.sans(600))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, c)
	UiIcon.apply(b, icon_name, 14, c, c)
	b.add_theme_constant_override("h_separation", 4)
	var inset := int((SIZE_TOUCH - SIZE_HUD) / 2.0)
	var chip := glass(UiTheme.RADIUS_PILL, inset, UiTheme.CARD)
	chip.content_margin_left = 12
	chip.content_margin_right = 12
	var hover := chip.duplicate() as StyleBoxFlat
	hover.border_color = c
	for state in ["normal", "pressed"]:
		b.add_theme_stylebox_override(state, chip)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))

## Data quality from the view's DataNotes: "Full data", "Partial data" or
## "Estimated", always with the gauge icon. Returns [label, tone, tooltip].
static func data_quality(notes: Array) -> Array:
	if notes.is_empty():
		return ["Full data", "good", "All live data arrived for this view"]
	if DataNotes.is_error(notes):
		return ["Estimated", "error", "No live data arrived. Tap for details"]
	return ["Partial data", "caution", "Some data is estimated. Tap for details"]

## Attribution: a tiny HUD-glass pill at opacity-attribution (1 on
## hover or focus), caption type, sources joined with " · ".
static func attribution() -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.modulate.a = OPACITY_ATTRIBUTION
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_font_override("font", UiTheme.sans(500))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, UiTheme.INK)
	UiIcon.apply(b, "info", 14, UiTheme.INK, UiTheme.INK)
	# The text arrives later; centred, the icon was drawn over it.
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", 4)
	var st := glass(UiTheme.RADIUS_PILL)
	st.shadow_size = 0
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, st)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	b.mouse_entered.connect(func() -> void: b.modulate.a = 1.0)
	b.mouse_exited.connect(func() -> void:
		if not b.has_focus():
			b.modulate.a = OPACITY_ATTRIBUTION)
	b.focus_entered.connect(func() -> void: b.modulate.a = 1.0)
	b.focus_exited.connect(func() -> void: b.modulate.a = OPACITY_ATTRIBUTION)
	return b

## Short source names for the pill ("Map data: © OpenStreetMap
## contributors" -> "© OpenStreetMap contributors"); the full credit
## stays in the tooltip and in Settings → Data sources.
static func short_sources(attribution_text: String) -> String:
	var out: Array[String] = []
	for part in attribution_text.split(" · ", false):
		var s := part.strip_edges()
		var colon := s.find(": ")
		if colon >= 0 and colon < 16:
			s = s.substr(colon + 2)
		var paren := s.find(" (")
		if paren >= 0:
			s = s.left(paren)
		var dash := s.find(" — ")
		if dash >= 0:
			s = s.left(dash)
		if s != "" and not out.has(s):
			out.append(s)
	return " · ".join(out)
