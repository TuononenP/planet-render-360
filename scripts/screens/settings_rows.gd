class_name SettingsRows
extends RefCounted

## Solid-surface building blocks for Settings and History (design system
## Settings / Toggle / Button): rows `size-control` tall on sky-200,
## separated by `line`; the Toggle switch (sky-300 track with a
## line-strong border when off, accent track with an on-accent thumb
## when on, the whole row the hit target); link rows that open a page;
## and the destructive button.

const ROW_H := 48  # size-control

## A group of rows on sky-200 (radius-m), divided by `line`.
static func group() -> PanelContainer:
	var g := PanelContainer.new()
	var st := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE)
	st.set_content_margin_all(0)
	g.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	g.add_child(col)
	return g

## Adds `row` to the group, with a `line` divider before every row but
## the first.
static func add(group_panel: PanelContainer, row: Control) -> Control:
	var col := group_panel.get_child(0) as VBoxContainer
	if col.get_child_count() > 0:
		var rule := ColorRect.new()
		rule.color = UiTheme.LINE
		rule.custom_minimum_size = Vector2(0, 1)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(rule)
	col.add_child(row)
	return row

## A row: body label (and optional body-s ink-muted description) with a
## trailing control. When the row is too narrow to give the label
## LABEL_MIN_W beside the control, the control drops under the label at
## full width (segmented controls on phones).
const LABEL_MIN_W := 140.0

static func row(label: String, trailing: Control = null, description: String = "") -> BoxContainer:
	var r := BoxContainer.new()
	r.custom_minimum_size = Vector2(0, ROW_H)
	r.add_theme_constant_override("separation", 12)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(pad)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(text)
	var l := UiTheme.label(label, 15, UiTheme.INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(l)
	if description != "":
		var d := UiTheme.label(description, 14, UiTheme.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_child(d)
	if trailing != null:
		var tail := MarginContainer.new()
		tail.add_theme_constant_override("margin_right", 12)
		tail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tail.add_child(trailing)
		r.add_child(tail)
		r.resized.connect(func() -> void: _fit(r, tail))
	return r

## Side by side when the label keeps LABEL_MIN_W, else stacked.
static func _fit(r: BoxContainer, tail: MarginContainer) -> void:
	var stacked := r.size.x < tail.get_combined_minimum_size().x + LABEL_MIN_W + 32.0
	if stacked == r.vertical:
		return
	r.vertical = stacked
	r.add_theme_constant_override("separation", 0 if stacked else 12)
	tail.add_theme_constant_override("margin_left", 16 if stacked else 0)
	tail.add_theme_constant_override("margin_right", 16 if stacked else 12)
	tail.add_theme_constant_override("margin_bottom", 12 if stacked else 0)

## A row laid over a whole-row Button: the button grows with the row's
## wrapped text (descriptions wrap to more lines on narrow screens).
static func _fill_button(b: Button, r: Control, min_h: float = ROW_H) -> void:
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(r)
	var grow := func() -> void:
		b.custom_minimum_size.y = maxf(min_h, r.get_combined_minimum_size().y)
	r.minimum_size_changed.connect(grow)
	grow.call()

## Toggle row: the whole row is one toggle Button; the switch is drawn at
## its trailing edge. The effect applies at once (no Save).
static func toggle(label: String, on: bool, changed: Callable, description: String = "") -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = on
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.tooltip_text = label
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, clear)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_S))
	var r := row(label, null, description)
	# Keep the text clear of the switch drawn at the trailing edge.
	(r.get_child(0) as MarginContainer).add_theme_constant_override("margin_right", 16 + 44 + 12)
	_fill_button(b, r)
	b.draw.connect(func() -> void: _draw_switch(b))
	b.toggled.connect(func(v: bool) -> void:
		b.queue_redraw()
		changed.call(v))
	return b

static func _draw_switch(b: Button) -> void:
	var on := b.button_pressed
	var track := Rect2(Vector2(b.size.x - 16.0 - 44.0, (b.size.y - 26.0) / 2.0), Vector2(44, 26))
	var st := UiTheme.style(UiTheme.TEAL if on else UiTheme.FIELD, 13,
		Color.TRANSPARENT if on else UiTheme.LINE_STRONG)
	b.draw_style_box(st, track)
	var cx := track.end.x - 13.0 if on else track.position.x + 13.0
	b.draw_circle(Vector2(cx, track.get_center().y), 10.0,
		UiTheme.ON_ACCENT if on else UiTheme.MUTED, true, -1.0, true)

## A row that opens `url` in the browser, with a trailing arrow.
static func link(label: String, description: String, url: String) -> Button:
	var b := Button.new()
	b.tooltip_text = url
	b.custom_minimum_size = Vector2(0, ROW_H)
	var clear := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", clear)
	b.add_theme_stylebox_override("hover", UiTheme.style(Color(UiTheme.INK, 0.04), 0))
	b.add_theme_stylebox_override("pressed", UiTheme.style(Color(UiTheme.INK, 0.08), 0))
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_S))
	var arrow := UiIcon.rect("arrow-left", 18, UiTheme.MUTED)
	arrow.flip_h = true
	var r := row(label, arrow, description)
	_fill_button(b, r)
	b.pressed.connect(func() -> void: OS.shell_open(url))
	return b

## Destructive button: signal-error fill with on-accent-dark text.
static func destructive(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.add_theme_font_override("font", UiTheme.sans(600))
	b.add_theme_font_size_override("font_size", 15)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, UiTheme.ON_ACCENT)
	var fill := UiTheme.style(UiTheme.SIGNAL_ERROR, UiTheme.RADIUS_PILL)
	fill.content_margin_left = 20
	fill.content_margin_right = 20
	var hover := fill.duplicate() as StyleBoxFlat
	hover.bg_color = UiTheme.SIGNAL_ERROR.lightened(0.08)
	b.add_theme_stylebox_override("normal", fill)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	UiIcon.apply(b, "trash-2", 20, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	return b

## A confirmation sheet over `host`: title, message, Cancel and the
## destructive action. `confirm` runs on the action; both close it.
static func confirm(host: Control, title: String, message: String, action: String,
		on_confirm: Callable) -> Control:
	var veil := ColorRect.new()
	veil.name = "confirm_veil"
	veil.color = Color(UiTheme.SKY_000, 0.55)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	# Esc closes the sheet instead of falling through to the host
	# screen's navigation (which would orphan the sheet on a hidden
	# screen and resurrect it later over different content).
	veil.focus_mode = Control.FOCUS_ALL
	veil.gui_input.connect(func(ev: InputEvent) -> void:
		var k := ev as InputEventKey
		if k != null and k.pressed and k.keycode == KEY_ESCAPE:
			veil.queue_free()
			veil.accept_event())
	host.add_child(veil)
	veil.call_deferred("grab_focus")
	var sheet := PanelContainer.new()
	var st := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_L, UiTheme.LINE, true)
	st.set_content_margin_all(24)
	sheet.add_theme_stylebox_override("panel", st)
	sheet.set_anchors_preset(Control.PRESET_CENTER)
	sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sheet.grow_vertical = Control.GROW_DIRECTION_BOTH
	sheet.custom_minimum_size = Vector2(minf(420.0, host.size.x - 32.0), 0)
	veil.add_child(sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	sheet.add_child(col)
	col.add_child(UiTheme.label(title, 20, UiTheme.INK, true))
	var msg := UiTheme.label(message, 15, UiTheme.MUTED)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(msg)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(actions)
	var cancel := UiTheme.quiet_button("Cancel")
	cancel.pressed.connect(veil.queue_free)
	actions.add_child(cancel)
	var go := destructive(action)
	go.pressed.connect(func() -> void:
		on_confirm.call()
		veil.queue_free())
	actions.add_child(go)
	return veil
