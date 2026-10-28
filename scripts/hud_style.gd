class_name HudStyle
extends RefCounted

## Heads-up styling for the 360 view: smoked-glass surfaces with a
## glowing cyan-teal accent, so controls float over any terrain (snow,
## night sky, satellite imagery) without blocking the scene. The accent
## follows the chosen palette (UiTheme.apply_palette) and reads on dark glass.

static var ACCENT := Color(0.18, 0.77, 0.71)  # #2EC4B6, follows UiTheme.apply_palette
static var ACCENT_GLOW := Color(0.18, 0.77, 0.71, 0.35)
const GLASS := Color(0.04, 0.07, 0.08, 0.58)
const GLASS_HOVER := Color(0.08, 0.16, 0.17, 0.72)
const GLASS_PRESSED := Color(0.10, 0.30, 0.29, 0.80)
const EDGE := Color(1, 1, 1, 0.14)
const TEXT := Color(1, 1, 1, 0.96)
const TEXT_DIM := Color(1, 1, 1, 0.62)
const TEXT_FAINT := Color(1, 1, 1, 0.45)

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
	s.shadow_color = Color(0, 0, 0, 0.16)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	return s

## Floating panel (dock, pills): glass with a hairline accent edge.
static func panel(radius: int = 26, margin_x: int = 18, margin_y: int = 14) -> StyleBoxFlat:
	return glass(radius, Color(ACCENT, 0.28), GLASS, margin_x, margin_y)

## Glass button with accent hover/press and a visible focus ring.
static func apply_button(b: Button, radius: int, margin_x: int = 14, margin_y: int = 8) -> void:
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, TEXT)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", TEXT_FAINT)
	b.add_theme_stylebox_override("normal", glass(radius, EDGE, GLASS, margin_x, margin_y))
	b.add_theme_stylebox_override("hover", glass(radius, ACCENT, GLASS_HOVER, margin_x, margin_y))
	b.add_theme_stylebox_override("pressed", glass(radius, ACCENT, GLASS_PRESSED, margin_x, margin_y))
	b.add_theme_stylebox_override("hover_pressed", glass(radius, ACCENT, GLASS_PRESSED, margin_x, margin_y))
	b.add_theme_stylebox_override("disabled", glass(radius, EDGE, GLASS, margin_x, margin_y))
	var focus := glass(radius, ACCENT, Color.TRANSPARENT, margin_x, margin_y)
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
		b.add_theme_color_override("font_color", Color(0.02, 0.10, 0.09))
		b.add_theme_color_override("font_hover_color", Color(0.02, 0.10, 0.09))
		b.add_theme_stylebox_override("normal", glass(18, ACCENT, ACCENT, 14, 8))
		b.add_theme_stylebox_override("hover", glass(18, Color.WHITE, ACCENT.lightened(0.15), 14, 8))

static func apply_option(b: OptionButton) -> void:
	apply_button(b, 18)
	b.add_theme_color_override("font_pressed_color", TEXT)
	var popup := b.get_popup()
	popup.add_theme_font_size_override("font_size", 15)
	popup.add_theme_color_override("font_color", TEXT)
	popup.add_theme_color_override("font_hover_color", Color(0.02, 0.10, 0.09))
	popup.add_theme_color_override("font_separator_color", EDGE)
	var pop_panel := glass(16, Color(ACCENT, 0.35), Color(0.04, 0.08, 0.09, 0.94), 8, 8)
	popup.add_theme_stylebox_override("panel", pop_panel)
	var pop_hover := glass(10, Color.TRANSPARENT, ACCENT, 8, 6)
	pop_hover.shadow_size = 0
	popup.add_theme_stylebox_override("hover", pop_hover)
	popup.add_theme_constant_override("v_separation", 10)

## Slim glowing track with a luminous knob; hour ticks stay faint so
## the 24 slots read as a scale, not as noise.
static func apply_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.16)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = ACCENT
	fill.shadow_color = ACCENT_GLOW
	fill.shadow_size = 6
	s.add_theme_stylebox_override("grabber_area", fill)
	var fill_hi := fill.duplicate() as StyleBoxFlat
	fill_hi.bg_color = ACCENT.lightened(0.2)
	s.add_theme_stylebox_override("grabber_area_highlight", fill_hi)
	s.add_theme_icon_override("grabber", _knob(ACCENT))
	s.add_theme_icon_override("grabber_highlight", _knob(ACCENT.lightened(0.3)))
	var tick := Image.create(2, 6, false, Image.FORMAT_RGBA8)
	tick.fill(Color(1, 1, 1, 0.22))
	s.add_theme_icon_override("tick", ImageTexture.create_from_image(tick))

static func _knob(ring: Color) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 0.5, 0.62, 0.72, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color.WHITE, ring, ring,
		Color(ring, 0.30), Color(ring, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 30
	t.height = 30
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

static func label(text: String, size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l
