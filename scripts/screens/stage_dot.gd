class_name StageDot
extends Control

## Stage marker in the loading screen's stage card (design system:
## StageProgress): a line-strong ring while pending, an accent ring
## with a centre dot while active, an accent disc with an on-accent
## check once done, a signal-error ring with "!" when it failed, and a
## signal-caution ring with a warning triangle when the layer degraded
## (the app never fails a stage outright: layers degrade to estimates).
## Static: progress is shown by real state changes, never a pulse.

enum State { PENDING, ACTIVE, DONE, ERROR, DEGRADED }

var state := State.PENDING:
	set(v):
		state = v
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(20, 20)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c := size / 2.0
	match state:
		State.DONE:
			draw_circle(c, 10.0, UiTheme.TEAL, true, -1.0, true)
			draw_polyline(PackedVector2Array([c + Vector2(-4.5, 0.5),
				c + Vector2(-1.5, 3.5), c + Vector2(4.5, -3.0)]),
				UiTheme.ON_ACCENT, 2.0, true)
		State.ACTIVE:
			draw_arc(c, 9.0, 0.0, TAU, 40, UiTheme.TEAL, 2.0, true)
			draw_circle(c, 3.5, UiTheme.TEAL, true, -1.0, true)
		State.DEGRADED:
			var tri := PackedVector2Array([c + Vector2(0, -5.0), c + Vector2(5.5, 4.0),
				c + Vector2(-5.5, 4.0), c + Vector2(0, -5.0)])
			draw_arc(c, 9.25, 0.0, TAU, 40, UiTheme.SIGNAL_CAUTION, 1.5, true)
			draw_polyline(tri, UiTheme.SIGNAL_CAUTION, 1.5, true)
			draw_line(c + Vector2(0, -1.8), c + Vector2(0, 0.8), UiTheme.SIGNAL_CAUTION, 1.5, true)
			draw_circle(c + Vector2(0, 2.4), 0.8, UiTheme.SIGNAL_CAUTION, true, -1.0, true)
		State.ERROR:
			draw_arc(c, 9.25, 0.0, TAU, 40, UiTheme.SIGNAL_ERROR, 1.5, true)
			draw_line(c + Vector2(0, -4.5), c + Vector2(0, 1.0), UiTheme.SIGNAL_ERROR, 2.0, true)
			draw_circle(c + Vector2(0, 4.0), 1.2, UiTheme.SIGNAL_ERROR, true, -1.0, true)
		_:
			draw_arc(c, 9.25, 0.0, TAU, 40, UiTheme.LINE_STRONG, 1.5, true)
