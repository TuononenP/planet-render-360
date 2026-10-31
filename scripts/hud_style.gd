class_name HudStyle
extends RefCounted

## Heads-up styling for the 360 view, from the Planet Render 360 design
## system: HUD glass (translucent sky with a lit 1px edge) and one
## luminous accent, so controls float over any terrain (snow, night
## sky, satellite imagery) without blocking the scene. The accent
## follows the chosen palette (UiTheme.apply_palette). Plain glass
## carries ink only; secondary text goes on GLASS_STRONG.

static var ACCENT := Color("8cc8ff")  # Glacier, follows UiTheme.apply_palette
const GLASS := Color(0.043, 0.063, 0.098, 0.66)  # glass
const GLASS_STRONG := Color(0.043, 0.063, 0.098, 0.84)  # glass-strong
const GLASS_HOVER := Color(0.145, 0.176, 0.225, 0.78)
const EDGE := Color(0.929, 0.945, 0.965, 0.14)  # glass-edge
const TEXT := Color("edf1f6")  # ink
const TEXT_DIM := Color("a4aebd")  # ink-muted, glass-strong only
const TEXT_FAINT := Color("828c9c")  # ink-faint, placeholders and disabled

static func glass(radius: int, border: Color = EDGE, bg: Color = GLASS,
		margin_x: int = 16, margin_y: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.anti_aliasing = true
	s.border_color = border
	s.set_border_width_all(1)
	s.content_margin_left = margin_x
	s.content_margin_right = margin_x
	s.content_margin_top = margin_y
	s.content_margin_bottom = margin_y
	s.shadow_color = Color(0, 0, 0, 0.32)  # shadow-1
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	return s

## Floating panel (dock, pills): glass-strong with the lit edge, so
## secondary text stays legible over any scene.
static func panel(radius: int = 26, margin_x: int = 18, margin_y: int = 14) -> StyleBoxFlat:
	return glass(radius, EDGE, GLASS_STRONG, margin_x, margin_y)

## Glass button with accent hover/press and a visible focus ring.
static func apply_button(b: Button, radius: int, margin_x: int = 14, margin_y: int = 8) -> void:
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(state, TEXT)
	# Active (toggled) state on plain glass: accent fill, on-accent glyph.
	b.add_theme_color_override("font_pressed_color", UiTheme.ON_ACCENT)
	b.add_theme_color_override("font_hover_pressed_color", UiTheme.ON_ACCENT)
	b.add_theme_color_override("font_disabled_color", TEXT_FAINT)
	b.add_theme_stylebox_override("normal", glass(radius, EDGE, GLASS, margin_x, margin_y))
	b.add_theme_stylebox_override("hover", glass(radius, ACCENT, GLASS_HOVER, margin_x, margin_y))
	b.add_theme_stylebox_override("pressed", glass(radius, ACCENT, ACCENT, margin_x, margin_y))
	b.add_theme_stylebox_override("hover_pressed", glass(radius, ACCENT, ACCENT, margin_x, margin_y))
	b.add_theme_stylebox_override("disabled", glass(radius, EDGE, GLASS, margin_x, margin_y))
	var focus := glass(radius, UiTheme.FOCUS, Color.TRANSPARENT, margin_x, margin_y)
	focus.shadow_size = 0
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus)

static func button(text: String, min_size: Vector2, font_size: int = 15, radius: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	apply_button(b, radius)
	return b

## Live-time chip: accent-filled while following the clock, plain
## glass otherwise, so the mode is readable at a glance.
static func apply_live_chip(b: Button, live: bool) -> void:
	apply_button(b, 18)
	if live:
		b.add_theme_color_override("font_color", UiTheme.ON_ACCENT)
		b.add_theme_color_override("font_hover_color", UiTheme.ON_ACCENT)
		b.add_theme_stylebox_override("normal", glass(18, ACCENT, ACCENT, 14, 8))
		b.add_theme_stylebox_override("hover", glass(18, TEXT, ACCENT.lightened(0.12), 14, 8))

static func apply_option(b: OptionButton) -> void:
	apply_button(b, 18)
	b.add_theme_color_override("font_pressed_color", TEXT)
	b.add_theme_color_override("font_hover_pressed_color", TEXT)
	# An open dropdown is not a toggled state: keep glass, not accent fill.
	b.add_theme_stylebox_override("pressed", glass(18, ACCENT, GLASS_HOVER))
	b.add_theme_stylebox_override("hover_pressed", glass(18, ACCENT, GLASS_HOVER))
	var popup := b.get_popup()
	popup.add_theme_font_size_override("font_size", 15)
	popup.add_theme_color_override("font_color", TEXT)
	popup.add_theme_color_override("font_hover_color", UiTheme.ON_ACCENT)
	popup.add_theme_color_override("font_separator_color", EDGE)
	var pop_panel := glass(UiTheme.RADIUS_M, EDGE, GLASS_STRONG, 8, 8)
	popup.add_theme_stylebox_override("panel", pop_panel)
	var pop_hover := glass(10, Color.TRANSPARENT, ACCENT, 8, 6)
	pop_hover.shadow_size = 0
	popup.add_theme_stylebox_override("hover", pop_hover)
	popup.add_theme_constant_override("v_separation", 10)

## Flat slim track (solid accent fill, no glow) with the design system's
## knob: an ink disc in a 3px accent ring. Hour ticks stay faint so the
## 24 slots read as a scale, not as noise.
static func apply_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(TEXT, 0.20)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = ACCENT
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	# The grabber must be a texture, which steps at hi-DPI: reserve its
	# 24pt slot with a clear one and draw the knob as an anti-aliased
	# circle on top of the slider instead.
	var clear := Image.create(KNOB, 2, false, Image.FORMAT_RGBA8)
	var slot := ImageTexture.create_from_image(clear)
	s.add_theme_icon_override("grabber", slot)
	s.add_theme_icon_override("grabber_highlight", slot)
	var tick := Image.create(2, 6, false, Image.FORMAT_RGBA8)
	tick.fill(Color(TEXT, 0.22))
	s.add_theme_icon_override("tick", ImageTexture.create_from_image(tick))
	if not s.draw.is_connected(_draw_knob.bind(s)):
		s.draw.connect(_draw_knob.bind(s))
		s.value_changed.connect(func(_v: float) -> void: s.queue_redraw())

const KNOB := 24

static func _draw_knob(s: HSlider) -> void:
	var span := maxf(s.max_value - s.min_value, 0.0001)
	var ratio := clampf((s.value - s.min_value) / span, 0.0, 1.0)
	var c := Vector2(ratio * (s.size.x - KNOB) + KNOB / 2.0, s.size.y / 2.0)
	var ring := ACCENT.lightened(0.15) if s.has_focus() else ACCENT
	s.draw_circle(c, KNOB / 2.0, ring, true, -1.0, true)
	s.draw_circle(c, KNOB / 2.0 - 3.0, TEXT, true, -1.0, true)

static func label(text: String, size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l
