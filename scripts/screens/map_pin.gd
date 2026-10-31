class_name MapPin
extends Control

## The selected point on the map picker (design system: MapHome →
## Selection): a 12pt accent dot with a 2pt sky-000 keyline and a 32pt
## accent-soft halo, ringed by a thin compass ring with N/E/S/W ticks
## and a north caret (the Compass family). Placing a point plays one
## ping: the ring settles in from wide over duration-gentle and two
## sonar rings expand and fade. Then it rests: nothing loops (Motion).

const DOT_R := 6.0
const KEYLINE := 2.0
const HALO_R := 16.0
const RING_R := 22.0
const TICK := 5.0
const NORTH_TICK := 8.0
## Ping timing (seconds): ring settle, sonar ring life and the stagger
## of the second ring.
const SETTLE := 0.38
const SONAR := 1.1
const SONAR_STAGGER := 0.22
const SONAR_MAX_R := 52.0

## Where the pin sits, in this control's coordinates.
var point := Vector2.ZERO:
	set(v):
		point = v
		queue_redraw()

var _t := -1.0  # seconds since the last ping; < 0 means at rest

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

## Replay the placement ping.
func ping() -> void:
	_t = 0.0
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= SONAR + SONAR_STAGGER:
		_t = -1.0
		set_process(false)
	queue_redraw()

## ease-enter, cubic-bezier(0.05, 0.7, 0.1, 1), close enough for a ring.
static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 4.0)

func _draw() -> void:
	var p := point
	var accent := UiTheme.TEAL
	var key := UiTheme.SKY_000
	var settle := 1.0 if _t < 0.0 else _ease_out(_t / SETTLE)
	# Sonar rings, under everything else
	if _t >= 0.0:
		for i in 2:
			var k := (_t - i * SONAR_STAGGER) / SONAR
			if k <= 0.0 or k >= 1.0:
				continue
			var r := lerpf(DOT_R + KEYLINE, SONAR_MAX_R, _ease_out(k))
			var a := (1.0 - k) * 0.7
			draw_arc(p, r, 0.0, TAU, 64, Color(key, a * 0.35), 3.5, true)
			draw_arc(p, r, 0.0, TAU, 64, Color(accent, a), 1.5, true)
	draw_circle(p, HALO_R, Color(accent, 0.16 + 0.14 * (1.0 - settle)), true, -1.0, true)
	# Compass ring: settles in from wide and faint
	var ring_r := RING_R * lerpf(1.45, 1.0, settle)
	var ring_a := settle
	draw_arc(p, ring_r, 0.0, TAU, 72, Color(key, 0.45 * ring_a), 3.5, true)
	draw_arc(p, ring_r, 0.0, TAU, 72, Color(accent, ring_a), 1.5, true)
	for i in 4:
		var dir := Vector2.UP.rotated(i * TAU / 4.0)
		var tick_len := NORTH_TICK if i == 0 else TICK
		var a0 := p + dir * (ring_r + 2.0)
		var a1 := p + dir * (ring_r + 2.0 + tick_len)
		draw_line(a0, a1, Color(key, 0.45 * ring_a), 4.0, true)
		draw_line(a0, a1, Color(accent, ring_a), 2.0, true)
	# North caret, just outside the north tick
	var tip := p + Vector2(0, -(ring_r + NORTH_TICK + 9.0))
	var caret := PackedVector2Array([tip, tip + Vector2(4.5, 6.0), tip + Vector2(-4.5, 6.0)])
	var caret_edge := PackedVector2Array([tip + Vector2(0, -1.6), tip + Vector2(6.3, 7.0),
		tip + Vector2(-6.3, 7.0)])
	draw_colored_polygon(caret_edge, Color(key, 0.45 * ring_a))
	draw_colored_polygon(caret, Color(accent, ring_a))
	# The dot
	draw_circle(p, DOT_R + KEYLINE, key, true, -1.0, true)
	draw_circle(p, DOT_R, accent, true, -1.0, true)
