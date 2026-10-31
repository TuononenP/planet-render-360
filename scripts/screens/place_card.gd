class_name PlaceCard
extends Button

## Small place card (design system: PlaceCard size="s") for the map
## home's "Around the world" grid: a sky-and-ridge thumbnail over the
## place name in Instrument Serif. A toggle: the selected place gets an
## accent ring (the pressed style). The thumbnail is a stand-in until a
## place has a generated one, picked from the name so it stays stable.

const SKIES := [
	["0a1030", "1a2350", "2c3466", "0c1222", "151d33"],  # night
	["2b3a6b", "b8798c", "f2b08a", "3c3550", "5a4a5c"],  # dawn
	["4f8fcf", "8ec3ec", "d8ecf7", "5b6f7d", "8a9aa3"],  # day
	["2a2c5a", "b8607e", "f0a060", "30263c", "4a3446"],  # dusk
	["a9c9e8", "e6f1fa", "ffffff", "c9d6e2", "f4f8fb"],  # snow
]
const FAR := [[0, 170], [60, 120], [95, 140], [150, 78], [190, 118], [230, 96],
	[290, 150], [340, 118], [400, 150], [400, 240], [0, 240]]
const CAP := [[150, 78], [168, 98], [158, 100], [150, 92], [140, 102], [133, 96]]
const NEAR := [[0, 200], [80, 168], [140, 186], [210, 160], [280, 190], [340, 172],
	[400, 190], [400, 240], [0, 240]]

## Hand-picked skies for the shelf (indexes into SKIES: 0 night, 1 dawn,
## 2 day, 3 dusk, 4 snow); other names pick one from their hash.
const SKY_FOR := {"Paris": 3, "Alps": 4, "Banff": 1, "Big Sur": 2, "Tokyo": 0,
	"New York": 3, "Stockholm": 1, "Monaco": 2, "Dubai": 2, "London": 0,
	"Rome": 3, "Venice": 1, "Seoul": 0}

var _name: Label
var _art: Control

static func make(place_name: String, thumb_height: int = 56) -> PlaceCard:
	var c := PlaceCard.new()
	c.toggle_mode = true
	c.focus_mode = Control.FOCUS_ALL
	c.tooltip_text = place_name
	c.custom_minimum_size = Vector2(0, thumb_height + 38)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(col)
	c._art = _Thumb.new()
	c._art.sky = SKIES[int(SKY_FOR.get(place_name, abs(place_name.hash()) % SKIES.size()))]
	c._art.custom_minimum_size = Vector2(0, thumb_height)
	col.add_child(c._art)
	c._name = UiTheme.display_label(place_name, 18)
	c._name.clip_text = true
	c._name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	c._name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c._name.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c._name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(c._name)
	col.add_child(pad)
	c.restyle()
	return c

## Solid card (sky-200, line edge); selected = 2px accent ring.
func restyle() -> void:
	var base := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE)
	base.set_content_margin_all(0)
	add_theme_stylebox_override("normal", base)
	var hover := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE_STRONG)
	hover.set_content_margin_all(0)
	add_theme_stylebox_override("hover", hover)
	var ring := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.TEAL)
	ring.set_content_margin_all(0)
	ring.set_border_width_all(2)
	add_theme_stylebox_override("pressed", ring)
	add_theme_stylebox_override("hover_pressed", ring)
	var focus := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_M, UiTheme.FOCUS)
	focus.set_content_margin_all(0)
	focus.set_border_width_all(2)
	add_theme_stylebox_override("focus", focus)
	if _name != null:
		_name.add_theme_color_override("font_color", UiTheme.INK)

## Sky gradient with its top corners rounded to the card, two ridges
## and a snow cap; drawn from the design system's Scene stand-in.
class _Thumb extends Control:
	var sky: Array = SKIES[2]

	func _init() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _col(i: int) -> Color:
		return Color(str(sky[i]))

	func _sky_at(y: float) -> Color:
		var t := clampf(y / maxf(size.y, 1.0), 0.0, 1.0)
		if t < 0.55:
			return _col(0).lerp(_col(1), t / 0.55)
		return _col(1).lerp(_col(2), clampf((t - 0.55) / 0.25, 0.0, 1.0))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var r := minf(UiTheme.RADIUS_M - 1.0, minf(w, h) / 2.0)
		var pts := PackedVector2Array([Vector2(0, h)])
		for k in 7:
			var a := PI + (PI / 2.0) * k / 6.0
			pts.append(Vector2(r, r) + Vector2(cos(a), sin(a)) * r)
		for k in 7:
			var a := PI * 1.5 + (PI / 2.0) * k / 6.0
			pts.append(Vector2(w - r, r) + Vector2(cos(a), sin(a)) * r)
		pts.append(Vector2(w, h))
		var colors := PackedColorArray()
		for p in pts:
			colors.append(_sky_at(p.y))
		draw_polygon(pts, colors)
		# viewBox 400 x 240 scaled to cover the card, anchored at the bottom.
		var s := maxf(w / 400.0, h / 240.0)
		var o := Vector2((w - 400.0 * s) / 2.0, h - 240.0 * s)
		draw_colored_polygon(_map(FAR, s, o), Color(_col(3), 0.85))
		draw_colored_polygon(_map(CAP, s, o), Color(_col(4), 0.9))
		draw_colored_polygon(_map(NEAR, s, o), _col(4))

	func _map(src: Array, s: float, o: Vector2) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in src:
			out.append(o + Vector2(p[0], p[1]) * s)
		return out
