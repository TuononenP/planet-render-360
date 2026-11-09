class_name PrivacyHero
extends Control

## The banner of Settings → Privacy: a small planet lit by a rising sun,
## wrapped in a 360° orbit, drawn in the horizon-* stops and the live
## accent. The meridians turn and the sun circles slowly, and both hold
## still under Reduce motion or while the page is out of view.

const HEIGHT := 176.0
const PLANET_R := 50.0
const TEX_PX := 192
const SPIN_PER_S := 0.04
const SUN := Color("ffa46e")

static var _disc: Texture2D

var _spin := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	visibility_changed.connect(_sync)
	_sync()

func _sync() -> void:
	set_process(is_visible_in_tree() and not UiPrefs.reduce_motion)

func _process(delta: float) -> void:
	_spin = fposmod(_spin + delta * SPIN_PER_S, 1.0)
	queue_redraw()

func refresh_theme() -> void:
	queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y / 2.0)
	var r := minf(PLANET_R, size.y * 0.3)
	for i in 6:
		draw_circle(c, r * (2.0 - 0.15 * float(i)), Color(UiTheme.HORIZON_DUSK, 0.05))
	_draw_orbit(c, r + 26.0)
	draw_texture_rect(_disc_texture(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)
	var mesh := Color(UiTheme.TEAL, 0.5)
	for k in 4:
		var phase := fposmod(float(k) / 4.0 + _spin, 1.0)
		_ellipse(c, r * absf(cos(phase * PI)), r, mesh)
	for lat in [-0.55, 0.0, 0.55]:
		var half := r * sqrt(1.0 - lat * lat)
		_ellipse(c + Vector2(0, r * lat), half, half * 0.2, Color(UiTheme.TEAL, 0.32))
	draw_arc(c, r, 0.0, TAU, 72, Color(UiTheme.TEAL, 0.75), 1.5, true)
	var a := -PI / 2.0 + 0.5 + _spin * TAU
	var sun := c + Vector2(cos(a), sin(a)) * (r + 26.0)
	draw_circle(sun, 15.0, Color(SUN, 0.18), true, -1.0, true)
	draw_circle(sun, 10.0, Color(SUN, 0.32), true, -1.0, true)
	draw_circle(sun, 6.0, SUN, true, -1.0, true)

func _draw_orbit(c: Vector2, radius: float) -> void:
	var dashes := 72
	for i in dashes:
		var a := TAU * float(i) / float(dashes)
		draw_arc(c, radius, a, a + 0.03, 3, Color(UiTheme.LINE_STRONG, 0.6), 1.5, true)

func _ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var t := TAU * float(i) / 48.0
		pts.append(c + Vector2(cos(t) * rx, sin(t) * ry))
	draw_polyline(pts, color, 1.2, true)

## The planet's body: night at the far limb, dusk rose, then the golden
## sunward face, with a one-pixel soft edge. Built once; the stops are
## the same in every theme.
static func _disc_texture() -> Texture2D:
	if _disc != null:
		return _disc
	var img := Image.create(TEX_PX, TEX_PX, false, Image.FORMAT_RGBA8)
	var lit := Vector2(0.55, -0.5)
	for y in TEX_PX:
		for x in TEX_PX:
			var p := Vector2((float(x) + 0.5) / float(TEX_PX) * 2.0 - 1.0,
				(float(y) + 0.5) / float(TEX_PX) * 2.0 - 1.0)
			var alpha := clampf((1.0 - p.length()) * float(TEX_PX) / 2.0, 0.0, 1.0)
			var t := clampf(p.distance_to(lit) / 1.6, 0.0, 1.0)
			var col: Color
			if t < 0.35:
				col = UiTheme.AMBER.lerp(UiTheme.HORIZON_DUSK, t / 0.35)
			else:
				col = UiTheme.HORIZON_DUSK.lerp(UiTheme.HORIZON_NIGHT, (t - 0.35) / 0.65)
			img.set_pixel(x, y, Color(col, alpha))
	_disc = ImageTexture.create_from_image(img)
	return _disc
