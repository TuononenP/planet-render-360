class_name MapPin
extends Control

## The selected point on the map picker (design system: MapHome →
## Selection): a needle pin. An accent head in an ink ring with an
## on-accent core, on a thin ink stem down to a small accent dot at
## the exact point, with a soft shadow on the map. Flat: no gloss, no
## outline. Built as SVG in the live accent and rasterised at the
## screen's real pixel density (2x, mipmapped), so it stays crisp on
## hi-DPI. Placing a point drops the needle in over duration-gentle and
## sends one ripple out from the point. Then it rests: nothing loops
## (Motion).

## Logical px per SVG unit.
const UNIT := 0.9
## Needle artwork: 80 x 80 units, point at (40, 60), head at (40, 28).
const PIN_SIZE := Vector2(80, 80)
const PIN_TIP := Vector2(40, 60)
const HEAD_Y := 28.0
## Ground artwork: 80 x 32 units, centred on the point.
const GROUND_SIZE := Vector2(80, 32)
const SUPERSAMPLE := 2.0
## Ping timing (seconds), the drop height and the ripple reach (px).
const DROP := 0.38
const DROP_PX := 22.0
const RIPPLE := 0.8
const RIPPLE_R := Vector2(8.0, 26.0)
const RIPPLE_SQUASH := 0.38

const PIN_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
<rect x="38.9" y="34" width="2.2" height="26" rx="1.1" fill="{ink}"/>
<circle cx="40" cy="60" r="2.2" fill="{accent}"/>
<circle cx="40" cy="28" r="11" fill="{ink}"/>
<circle cx="40" cy="28" r="8.6" fill="{accent}"/>
<circle cx="40" cy="28" r="3.2" fill="{core}"/>
</svg>"""

const GROUND_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="80" height="32" viewBox="0 0 80 32">
<defs>
<radialGradient id="shade" cx="40" cy="16" r="10" gradientTransform="translate(0 9.92) scale(1 0.38)" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="{key}" stop-opacity="0.6"/>
<stop offset="1" stop-color="{key}" stop-opacity="0"/></radialGradient>
</defs>
<ellipse cx="40" cy="16" rx="10" ry="3.8" fill="url(#shade)"/>
</svg>"""

## Where the pin's tip sits, in this control's coordinates.
var point := Vector2.ZERO:
	set(v):
		point = v
		queue_redraw()

var _t := -1.0  # seconds since the last ping; < 0 means at rest
var _key := ""
var _pin_tex: Texture2D
var _ground_tex: Texture2D

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)

## Replay the placement drop.
func ping() -> void:
	_t = 0.0
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= DROP + RIPPLE:
		_t = -1.0
		set_process(false)
	queue_redraw()

## ease-enter, cubic-bezier(0.05, 0.7, 0.1, 1), close enough for a pin.
static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 4.0)

static func _raster(svg: String, scale: float) -> Texture2D:
	var img := Image.new()
	if img.load_svg_from_string(svg, scale) != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## Rebuild both textures when the accent or the screen density changes.
func _ensure_textures() -> void:
	var accent := UiTheme.TEAL
	var density := get_viewport().get_screen_transform().get_scale().x \
		* get_global_transform().get_scale().x
	var px_scale := UNIT * maxf(density, 1.0) * SUPERSAMPLE
	var key := "%s@%.2f" % [accent.to_html(false), px_scale]
	if key == _key:
		return
	# Cached even when a raster fails: _draw then shows the fallback
	# instead of rasterising again every frame.
	_key = key
	var subs := {
		"accent": "#" + accent.to_html(false),
		"ink": "#" + UiTheme.INK.to_html(false),
		"core": "#" + UiTheme.ON_ACCENT.to_html(false),
		"key": "#" + UiTheme.SKY_000.to_html(false),
	}
	_pin_tex = _raster(PIN_SVG.format(subs, "{_}"), px_scale)
	_ground_tex = _raster(GROUND_SVG.format(subs, "{_}"), px_scale)

func _draw() -> void:
	_ensure_textures()
	if _pin_tex == null or _ground_tex == null:
		_draw_fallback()
		return
	var p := point
	var drop := 1.0 if _t < 0.0 else _ease_out(_t / DROP)
	# Ground: the shadow tightens as the needle lands, then one ripple
	var land := lerpf(0.35, 1.0, drop)
	var g := GROUND_SIZE * UNIT * lerpf(1.4, 1.0, drop)
	draw_texture_rect(_ground_tex, Rect2(p - g / 2.0, g), false, Color(1, 1, 1, land))
	if _t >= DROP:
		var k := (_t - DROP) / RIPPLE
		draw_set_transform(p, 0.0, Vector2(1.0, RIPPLE_SQUASH))
		draw_arc(Vector2.ZERO, lerpf(RIPPLE_R.x, RIPPLE_R.y, _ease_out(k)), 0.0, TAU, 64,
			Color(UiTheme.TEAL, 0.8 * (1.0 - k)), 2.0 / RIPPLE_SQUASH, true)
		draw_set_transform(Vector2.ZERO)
	var tip := p + Vector2(0, -(1.0 - drop) * DROP_PX)
	var size_px := PIN_SIZE * UNIT
	draw_texture_rect(_pin_tex, Rect2(tip - PIN_TIP * UNIT, size_px), false)

## SVG raster unavailable (no SVG module, bad colour): a plain accent
## needle, so the selection marker never disappears.
func _draw_fallback() -> void:
	var head := point + Vector2(0, -(PIN_TIP.y - HEAD_Y) * UNIT)
	draw_line(head, point, UiTheme.INK, 2.2 * UNIT, true)
	draw_circle(head, 11.0 * UNIT, UiTheme.INK, true, -1.0, true)
	draw_circle(head, 8.6 * UNIT, UiTheme.TEAL, true, -1.0, true)
	draw_circle(head, 3.2 * UNIT, UiTheme.ON_ACCENT, true, -1.0, true)
