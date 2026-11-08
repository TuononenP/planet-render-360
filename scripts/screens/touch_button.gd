class_name TouchButton
extends Button

## A button whose visible shape is shorter than the size-touch hit area:
## taps just above or below it still land (design system: every tappable
## thing has a 44pt hit area, even when its shape is smaller).

func _has_point(point: Vector2) -> bool:
	var grow := maxf((float(HudParts.SIZE_TOUCH) - size.y) / 2.0, 0.0)
	return Rect2(Vector2.ZERO, size).grow_individual(0.0, grow, 0.0, grow).has_point(point)
