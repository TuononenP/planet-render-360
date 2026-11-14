class_name ViewHint
extends RefCounted

## The controls hint at the foot of the 360 view: how to walk, fly and
## look with the keys or the touch sticks. It shows when a place opens
## and on every mode change, fades once the user looks about (or after
## 6 s), words itself for the sticks the layout shows, and gives way to
## the buttons and badges it would cover. ViewChrome.layout places it.

static func build(v: View360) -> void:
	v._hint = PanelContainer.new()
	v._hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hint.add_theme_stylebox_override("panel", HudStyle.panel(20, 16, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hint.add_child(row)
	row.add_child(UiIcon.rect("move", 18, UiTheme.INK))
	v._hint_label = UiTheme.label(text(v), 14, UiTheme.INK)
	v._hint_label.name = "Text"
	v._hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v._hint_label)
	v._fade.add_child(v._hint)
	v._hint_timer = Timer.new()
	v._hint_timer.one_shot = true
	v._hint_timer.wait_time = 6.0
	v._hint_timer.timeout.connect(v._dismiss_hint)
	v._hud.add_child(v._hint_timer)

static func dismiss(v: View360) -> void:
	if v._hint == null:
		return
	if not v._hint.visible:
		v._hint.set_meta("wanted", false)  # crowded out (clear): stays down
		return
	if v._hint.modulate.a < 1.0:
		return
	if v._hint.has_meta("dismiss") and (v._hint.get_meta("dismiss") as Tween).is_valid():
		return  # Already fading.
	var tw := v.create_tween()
	tw.tween_property(v._hint, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		v._hint.hide()
		v._hint.set_meta("wanted", false))
	v._hint.set_meta("dismiss", tw)

static func show(v: View360) -> void:
	if v._hint == null:
		return
	# A fade still running (the drone moved just before landing) would hide it.
	if v._hint.has_meta("dismiss"):
		(v._hint.get_meta("dismiss") as Tween).kill()
	v._hint.modulate.a = 1.0
	v._hint.set_meta("wanted", true)
	v._hint.visible = not v._hint.get_meta("crowded", false)
	if v._hint_timer.is_inside_tree():
		v._hint_timer.start()
	# The layout words the hint (sync_text) and centres it.
	ViewChrome.layout(v)

static func text(v: View360) -> String:
	# The look stick is named by its rim marks; it is put away when crowded
	# (or with all the sticks, under a sheet).
	var s := v._drone.sticks
	var look := " · Marked stick looks around" if s == null or (s.visible and s.look.visible) else ""
	if not v._drone.on:
		if DroneSticks.wanted():
			return "Left stick walks · Right stick turns" + look
		return "W A S D to walk · Drag to look · Shift to run"
	if DroneSticks.wanted():
		return "Left stick flies · Right stick turns and climbs" + look
	return "W A S D to fly · E and Q to climb · Shift to speed up"

## Words the hint for the sticks this layout shows (the look stick comes
## and goes), a part per line where one line is wider than `room`.
static func sync_text(v: View360, room: float) -> void:
	var words := text(v)
	v._hint_label.text = words  # Label skips an unchanged text
	v._hint.reset_size()
	if v._hint.get_combined_minimum_size().x > room:
		v._hint_label.text = words.replace(" · ", "\n")
		v._hint.reset_size()

## A wide hint on a narrow screen slides left, clear of the button stack
## and the inspector.
static func clear(v: View360, inspector: bool, pad: float) -> void:
	var hint := Rect2(v._hint.position, v._hint.size)
	var blockers: Array[Rect2] = [Rect2(v._zoom_stack.position, v._zoom_stack.size)]
	if inspector and v._sheet.visible:
		blockers.append(Rect2(v._sheet.position, v._sheet.size))
	var limit := INF
	var hit := false
	for b in blockers:
		hit = hit or hint.intersects(b)
		limit = minf(limit, b.position.x)
	if hit:
		v._hint.position.x = maxf(pad, minf(hint.position.x, limit - 8.0 - hint.size.x))
	# No room beside the mini-map on a short screen: above it instead.
	if v._minimap != null and v._minimap.visible \
			and Rect2(v._hint.position, v._hint.size).intersects(v._minimap.get_rect()):
		v._hint.position.y = v._minimap.position.y - 8.0 - hint.size.y
	# A short phone has no room left under the pill and the badge: the
	# hint gives way rather than cover them (the controls show the way).
	# It comes back once they leave room, unless it was dismissed meanwhile.
	var hint_now := Rect2(v._hint.position, v._hint.size)
	var crowded := hint_now.position.y < v._top.get_rect().end.y
	for c: Control in [v._top, v._stream_badge, v._fps, v._exit_btn, v._zoom_stack]:
		if c.visible and hint_now.intersects(c.get_rect()):
			crowded = true
			break
	v._hint.set_meta("crowded", crowded)
	v._hint.visible = not crowded and v._hint.get_meta("wanted", true)
