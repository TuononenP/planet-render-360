class_name UiIcon
extends RefCounted

## Lucide icons from the design system (assets/icons/, ISC licence):
## outline, rounded caps, 1.75 stroke, drawn white and tinted through
## the button's icon colours so they follow the tokens. Rasterised at
## 2x the logical size so they stay crisp on Retina and phone screens.

const DIR := "res://assets/icons/"

static var _cache := {}

## `px_scale` 2 for Button icons (shrunk by icon_max_width); 1 for
## nodes that draw a texture at its native size, like LineEdit.right_icon.
static func texture(icon_name: String, size: int, px_scale: float = 2.0) -> Texture2D:
	var key := "%s@%d@%s" % [icon_name, size, px_scale]
	if _cache.has(key):
		return _cache[key]
	var path := "%s%s.svg" % [DIR, icon_name]
	var tex: Texture2D = null
	var svg := FileAccess.get_file_as_string(path)
	if svg != "":
		var img := Image.new()
		if img.load_svg_from_string(svg, size * px_scale / 24.0) == OK:
			tex = ImageTexture.create_from_image(img)
	if tex == null and ResourceLoader.exists(path):
		tex = load(path)  # exported builds ship only the import
	_cache[key] = tex
	return tex

## Put an icon on a button (before its text) and tint it like the text:
## ink at rest, `active_color` while pressed (on-accent on an accent fill).
static func apply(b: Button, icon_name: String, size: int = 22,
		color: Color = UiTheme.INK, active_color: Color = UiTheme.ON_ACCENT) -> void:
	b.icon = texture(icon_name, size)
	# Left of a label, centred when the button is icon-only (centred
	# with a label the engine draws the text on top of the icon).
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT if b.text != "" else HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", size)
	b.add_theme_constant_override("h_separation", 8)
	for key in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		b.add_theme_color_override(key, color)
	for key in ["icon_pressed_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(key, active_color)
	b.add_theme_color_override("icon_disabled_color", Color(color, 0.5))

## A round, text-free icon button for rails and HUDs (44pt hit area).
static func button(icon_name: String, tooltip: String, size: int = 22) -> Button:
	var b := UiTheme.rail_button("", tooltip)
	b.custom_minimum_size = Vector2(48, 48)
	apply(b, icon_name, size, UiTheme.INK, UiTheme.ON_ACCENT)
	return b
