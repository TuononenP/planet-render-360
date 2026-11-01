class_name MapSheet
extends RefCounted

## The phone sheet's detents (design system Storyboards → Sheet detents):
## peek shows the name, coordinates and Explore; half is 50% of the
## height; full is 92%, with the map dimmed under `scrim`. Dragging the
## grabber moves it; on release it snaps to the next detent in the
## direction of a flick faster than 600 pt/s, otherwise to the nearest,
## springing over duration-gentle without overshoot. Larger layouts keep
## a content-sized sheet. Operates on the picker via `p`.

enum Detent { PEEK, HALF, FULL }

const PEEK_MIN := 132.0  # size-sheet-peek
const HALF := 0.5
const FULL := 0.92
const FLICK := 600.0
const SPRING_S := 0.38  # duration-gentle
const SCRIM := Color(0.0235, 0.0353, 0.0588, 0.55)  # scrim (Night)

static func build(p: MapPicker) -> void:
	p._sheet.remove_child(p._sheet_body)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	p._sheet.add_child(col)
	p._grabber = Control.new()
	p._grabber.custom_minimum_size = Vector2(0, 24)
	p._grabber.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	p._grabber.tooltip_text = "Resize sheet"
	p._grabber.draw.connect(func() -> void:
		var r := Rect2(Vector2((p._grabber.size.x - 36.0) / 2.0, 4.0), Vector2(36, 5))
		p._grabber.draw_style_box(UiTheme.style(UiTheme.LINE_STRONG, 3), r))
	p._grabber.gui_input.connect(func(e: InputEvent) -> void: _on_drag(p, e))
	col.add_child(p._grabber)
	p._sheet_scroll = ScrollContainer.new()
	p._sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p._sheet_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTheme.apply_scroll(p._sheet_scroll)
	col.add_child(p._sheet_scroll)
	p._sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p._sheet_scroll.add_child(p._sheet_body)
	p._scrim = ColorRect.new()
	p._scrim.color = Color(SCRIM, 0.0)
	p._scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p._scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(p._scrim)
	p.move_child(p._scrim, p._map_wrap.get_index() + 1)

## Layout changed: detents on phones, a content-sized sheet elsewhere.
static func apply_layout(p: MapPicker) -> void:
	if p._grabber == null:
		return
	var compact := p._current_layout == Responsive.Layout.COMPACT
	p._grabber.visible = compact
	p._sheet_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if compact \
		else ScrollContainer.SCROLL_MODE_DISABLED
	if compact:
		_set_height(p, height_for(p, p._detent))
	else:
		p._sheet.custom_minimum_size.y = 0.0
		p._scrim.color.a = 0.0

static func heights(p: MapPicker) -> Array[float]:
	var h := p.size.y
	var natural := p._sheet_body.get_combined_minimum_size().y + 24.0 \
		+ p._sheet.get_theme_stylebox("panel").get_minimum_size().y
	var peek := clampf(24.0 + p._sheet.get_theme_stylebox("panel").get_minimum_size().y \
		+ p._sheet_cols.get_combined_minimum_size().y, PEEK_MIN, h * HALF)
	var half := clampf(minf(h * HALF, natural), peek, h * HALF)
	var full := clampf(minf(h * FULL, natural), half, h * FULL)
	return [peek, half, full]

static func height_for(p: MapPicker, detent: int) -> float:
	return heights(p)[clampi(detent, 0, 2)]

static func snap_to(p: MapPicker, detent: int, animate: bool = true) -> void:
	p._detent = clampi(detent, Detent.PEEK, Detent.FULL)
	if p._current_layout != Responsive.Layout.COMPACT:
		return
	var to := height_for(p, p._detent)
	if p._sheet_tween != null:
		p._sheet_tween.kill()
	if not animate or UiPrefs.reduce_motion:
		_set_height(p, to)
		return
	p._sheet_tween = p.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	p._sheet_tween.tween_method(func(v: float) -> void: _set_height(p, v),
		p._sheet.custom_minimum_size.y, to, SPRING_S)

static func _set_height(p: MapPicker, v: float) -> void:
	var hs := heights(p)
	p._sheet.custom_minimum_size.y = clampf(v, hs[0], hs[2])
	var t := clampf((v - hs[1]) / maxf(hs[2] - hs[1], 1.0), 0.0, 1.0)
	p._scrim.color = Color(SCRIM, SCRIM.a * t)
	p._queue_focus_update()

static func _on_drag(p: MapPicker, e: InputEvent) -> void:
	var y := NAN
	var pressed := false
	var released := false
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pressed = (e as InputEventMouseButton).pressed
		released = not pressed
		y = (e as InputEventMouseButton).global_position.y
	elif e is InputEventScreenTouch:
		pressed = (e as InputEventScreenTouch).pressed
		released = not pressed
		y = (e as InputEventScreenTouch).position.y + p._grabber.global_position.y
	elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT):
		y = (e as InputEventMouseMotion).global_position.y
	elif e is InputEventScreenDrag:
		y = (e as InputEventScreenDrag).position.y + p._grabber.global_position.y
	if is_nan(y):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if pressed:
		if p._sheet_tween != null:
			p._sheet_tween.kill()
		p._drag = {"y0": y, "h0": p._sheet.custom_minimum_size.y, "y": y, "t": now, "v": 0.0}
	elif released and not p._drag.is_empty():
		_release(p, float(p._drag["v"]))
		p._drag = {}
	elif not p._drag.is_empty():
		var dt := maxf(now - float(p._drag["t"]), 0.001)
		p._drag["v"] = (y - float(p._drag["y"])) / dt  # + is downward
		p._drag["y"] = y
		p._drag["t"] = now
		_set_height(p, float(p._drag["h0"]) - (y - float(p._drag["y0"])))
	p._grabber.accept_event()

static func _release(p: MapPicker, velocity: float) -> void:
	var hs := heights(p)
	var h := p._sheet.custom_minimum_size.y
	var target := 0
	if absf(velocity) > FLICK:
		# Next detent in the flick's direction (up = taller).
		target = p._detent
		for i in hs.size():
			if velocity < 0.0 and hs[i] > h + 1.0:
				target = i
				break
			if velocity > 0.0 and hs[hs.size() - 1 - i] < h - 1.0:
				target = hs.size() - 1 - i
				break
	else:
		var best := INF
		for i in hs.size():
			if absf(hs[i] - h) < best:
				best = absf(hs[i] - h)
				target = i
	snap_to(p, target)
