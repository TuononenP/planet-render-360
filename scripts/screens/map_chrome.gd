class_name MapChrome
extends RefCounted

## Theme, layout and focus handling for MapPicker: style boxes,
## palette application, responsive layout moves and focus updates.
## Operates on the picker's controls via `p` (screens stay stateful;
## this class is the stateless layout engine).
static func _side_style(p: MapPicker) -> StyleBoxFlat:
	var st := UiTheme.glass_panel(28)
	st.content_margin_left = 24
	st.content_margin_right = 24
	st.content_margin_top = 24
	st.content_margin_bottom = 24
	return st

static func _suggest_style(p: MapPicker) -> StyleBoxFlat:
	var st := UiTheme.style(Color(0.04, 0.08, 0.09, 0.97), 16, Color(UiTheme.TEAL, 0.35), true)
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	return st

static func _on_resized(p: MapPicker) -> void:
	if p._forced_layout >= 0:
		_apply_layout(p, p._forced_layout)
	else:
		_apply_layout(p, Responsive.layout_for_width(p.size.x))

static func _on_layout_selected(p: MapPicker, index: int) -> void:
	match index:
		1:
			p._forced_layout = Responsive.Layout.COMPACT
		2:
			p._forced_layout = Responsive.Layout.MEDIUM
		_:
			p._forced_layout = -1
	_on_resized(p)

static func _on_theme_selected(p: MapPicker, index: int) -> void:
	UiTheme.apply_palette(index)
	_apply_theme(p)
	p.palette_changed.emit(index)

## Re-skin every picker control after a palette change. Factories read
## the palette at creation time, so existing controls need this pass.
static func _apply_theme(p: MapPicker) -> void:
	if p._bg != null:
		p._bg.color = UiTheme.BG
	p._title_label.add_theme_color_override("font_color", UiTheme.INK)
	p._tagline_label.add_theme_color_override("font_color", UiTheme.MUTED)
	for section in [p._quick_label, p._selected_label, p._coords_label, p._tip, p._quality_label]:
		section.add_theme_color_override("font_color", UiTheme.MUTED)
	p._name_label.add_theme_color_override("font_color", UiTheme.INK)
	p._coord_label.add_theme_color_override("font_color", UiTheme.MUTED)
	p._ready_label.add_theme_color_override("font_color", UiTheme.TEAL)
	UiTheme.apply_option(p._layout_btn)
	UiTheme.apply_option(p._theme_btn)
	UiTheme.apply_field(p._search)
	UiTheme.apply_field(p._lat_field)
	UiTheme.apply_field(p._lon_field)
	p._suggest_panel.add_theme_stylebox_override("panel", _suggest_style(p))
	for child in p._suggest_list.get_children():
		if child is Button:
			p._style_suggestion_row(child as Button)
	p._sheet.add_theme_stylebox_override("panel", UiTheme.glass_panel(28))
	p._side.add_theme_stylebox_override("panel", _side_style(p))
	UiTheme.apply_primary(p._render_btn)
	UiTheme.apply_ghost(p._download_btn)
	for btn in [p._history_btn, p._settings_btn, p._exit_btn, p._zoom_in_btn, p._zoom_out_btn]:
		UiTheme.apply_rail_icon(btn)
	for rail in [p._nav, p._zoom_rail]:
		var st := UiTheme.style(UiTheme.GLASS_FILL, 26, UiTheme.LINE, true)
		st.set_content_margin_all(4)
		rail.add_theme_stylebox_override("panel", st)
	p._canvas.refresh_style()
	_set_selected_quick(p, p._selected_quick)

## Mark one quick pick as the active place (accent fill, pressed) and
## clear the rest. -1 clears all: the place no longer comes from a chip.
static func _set_selected_quick(p: MapPicker, index: int) -> void:
	p._selected_quick = index
	for i in p._quick_chips.size():
		var chip := p._quick_chips[i]
		chip.set_pressed_no_signal(i == index)
		UiTheme.apply_chip(chip, i == index)

## Offline-download feedback on the button itself (progress, then
## the outcome), so no extra status line competes for layout height.
static func set_download_status(p: MapPicker, text: String) -> void:
	if p._download_btn != null:
		p._download_btn.text = text

## Locks Render while a generation is still running (including a
## cancelled world build that has not wound down), so a press is not
## silently swallowed.
static func set_render_busy(p: MapPicker, busy: bool) -> void:
	if p._render_btn != null:
		p._render_btn.disabled = busy
		p._render_btn.text = "Finishing previous render…" if busy else "Render in 360°  →"

## Locks Save for offline while a download runs; a second press would
## otherwise retarget the pending history entry.
static func set_download_busy(p: MapPicker, busy: bool) -> void:
	if p._download_btn != null:
		p._download_btn.disabled = busy

## Shows the chosen preset in the sheet footer and on the settings
## button's tooltip, so the current quality is visible before opening
## the menu.
static func set_quality_preset(p: MapPicker, preset_value: int) -> void:
	if p._quality_label != null:
		p._quality_label.text = "Quality · %s" % RenderSettings.preset_name(preset_value)
	if p._settings_btn != null:
		p._settings_btn.tooltip_text = "Settings — %s quality" % RenderSettings.preset_name(preset_value)

static func effective_layout(p: MapPicker) -> int:
	return p._current_layout

static func _move(p: MapPicker, node: Control, parent: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	parent.add_child(node)

static func _move_all(p: MapPicker, nodes: Array, parent: Node) -> void:
	for node in nodes:
		_move(p, node, parent)

static func _apply_layout(p: MapPicker, layout: Responsive.Layout) -> void:
	if p._stack == null or p._side_col == null:
		return  # not ready yet; _ready applies the initial layout
	p._current_layout = layout
	# Compact is height-tight: the footer already says "tap the map",
	# so the coordinates caption gives its height back to the map. The
	# layout switcher is the only way back from a forced layout, so it
	# always stays visible.
	var compact := layout == Responsive.Layout.COMPACT
	var expanded := layout == Responsive.Layout.EXPANDED
	p._coords_label.visible = not compact
	p._quick_label.visible = expanded
	p._layout_btn.visible = true
	p._brand_pill.visible = not compact
	p._tagline_label.visible = expanded
	p._title_label.add_theme_font_size_override("font_size", 22 if expanded else 17)
	var pad := Responsive.page_padding(layout)
	p._overlay.add_theme_constant_override("margin_left", pad)
	p._overlay.add_theme_constant_override("margin_right", pad)
	p._overlay.add_theme_constant_override("margin_top", pad)
	p._overlay.add_theme_constant_override("margin_bottom", pad)
	if expanded:
		p._stack.visible = false
		p._split.visible = true
		# Park the stacked-layout containers in the hidden stack:
		# left parentless they were orphan nodes, leaked as
		# CanvasItem RIDs and ObjectDB instances on quit.
		_move_all(p, [p._top_col, p._stack_gap, p._sheet], p._stack)
		_move_all(p, [p._side, p._right_col], p._split)
		p._side.custom_minimum_size = Vector2(Responsive.sidebar_width(layout), 0)
		_move_all(p, [p._nav], p._right_col)
		p._nav.size_flags_horizontal = Control.SIZE_SHRINK_END
		p._brand_pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_move_all(p, [p._brand_pill, p._search_box, p._quick_box, p._sheet_cols], p._side_col)
		p._sheet_cols.vertical = true
		p._sheet_cols.add_theme_constant_override("separation", 10)
		p._sheet.custom_minimum_size = Vector2.ZERO
	else:
		p._split.visible = false
		p._stack.visible = true
		# Park the expanded-only containers in the hidden split: left
		# parentless they (and the brand pill parked in p._side_col on
		# compact) were orphan nodes, leaked as CanvasItem RIDs and
		# ObjectDB instances on quit.
		_move_all(p, [p._side, p._right_col], p._split)
		_move_all(p, [p._top_col, p._stack_gap, p._sheet], p._stack)
		if compact:
			_move_all(p, [p._search_box, p._nav], p._top_row)
			_move_all(p, [p._quick_box], p._top_col)
			_move(p, p._brand_pill, p._side_col)  # parked, hidden: phones have no brand row
		else:
			var pill_style := UiTheme.style(UiTheme.GLASS_FILL, 28, UiTheme.LINE, true)
			pill_style.content_margin_top = 8
			pill_style.content_margin_bottom = 8
			p._brand_pill.add_theme_stylebox_override("panel", pill_style)
			_move_all(p, [p._brand_pill, p._search_box, p._nav], p._top_row)
			_move_all(p, [p._quick_box], p._top_col)
		p._nav.size_flags_horizontal = Control.SIZE_SHRINK_END
		p._sheet_cols.vertical = compact
		p._sheet_cols.add_theme_constant_override("separation", 20)
		_move_all(p, [p._sheet_cols], p._sheet)
		# Tablet sheet is a centred two-column card, not full width.
		var sheet_w := 0 if compact else mini(int(p.size.x) - pad * 2, 760)
		p._sheet.custom_minimum_size = Vector2(sheet_w, 0)
		p._sheet.size_flags_horizontal = Control.SIZE_FILL if compact else Control.SIZE_SHRINK_CENTER
	_queue_focus_update(p)

## Keep the pin in the part of the map that is not covered by the
## sheet / side panel. Runs after layout has settled.
static func _queue_focus_update(p: MapPicker) -> void:
	if p._focus_queued:
		return
	p._focus_queued = true
	p.call_deferred("_update_focus")

static func _update_focus(p: MapPicker) -> void:
	p._focus_queued = false
	if p._canvas == null or p.size.x <= 0.0 or p.size.y <= 0.0:
		return
	var origin := p._canvas.get_global_rect().position
	var centre := p._canvas.size / 2.0
	var want := centre
	if p._current_layout == Responsive.Layout.EXPANDED:
		if p._side.visible and p._side.is_inside_tree():
			var left := p._side.get_global_rect().end.x - origin.x
			want = Vector2((left + p._canvas.size.x) / 2.0, centre.y)
	elif p._sheet.is_inside_tree() and p._top_col.is_inside_tree():
		var top := p._top_col.get_global_rect().end.y - origin.y
		var bottom := p._sheet.get_global_rect().position.y - origin.y
		if bottom > top + 80.0:
			want = Vector2(centre.x, (top + bottom) / 2.0)
	p._canvas.focus_offset = (want - centre).round()

