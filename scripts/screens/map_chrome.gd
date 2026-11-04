class_name MapChrome
extends RefCounted

## Theme, layout and focus handling for MapPicker: style boxes,
## palette application, responsive layout moves and focus updates.
## Operates on the picker's controls via `p` (screens stay stateful;
## this class is the stateless layout engine).

const EXPLORE := "Explore in 360°"
const FINISHING := "Finishing last scene…"
const SAVE := "Save for offline"
const RAIL_CARD_W := 124

static func _side_style(p: MapPicker) -> StyleBoxFlat:
	var st := UiTheme.glass_panel(UiTheme.RADIUS_L)
	st.set_content_margin_all(24)
	return st

static func _suggest_style(p: MapPicker) -> StyleBoxFlat:
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	return st

## Through the picker's own _apply_layout, so the sheet detents and the
## side rail follow every layout pass too.
static func _on_resized(p: MapPicker) -> void:
	if p._forced_layout >= 0:
		p._apply_layout(p._forced_layout)
	else:
		p._apply_layout(Responsive.layout_for_size(p.size))

static func _on_layout_selected(p: MapPicker, index: int) -> void:
	p._forced_layout = Responsive.override_layout(index)
	_on_resized(p)

## The rail around the nav icons is glass on the map; in the side panel
## the icons sit bare in the brand row.
static func _nav_style(p: MapPicker) -> StyleBox:
	if p._current_layout == Responsive.Layout.EXPANDED:
		return StyleBoxEmpty.new()
	var st := UiTheme.style(UiTheme.GLASS_FILL, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE, true)
	st.set_content_margin_all(4)
	return st

## Re-skin every picker control after a palette change. Factories read
## the palette at creation time, so existing controls need this pass.
static func _apply_theme(p: MapPicker) -> void:
	if p._bg != null:
		p._bg.color = UiTheme.BG
	p._name_label.add_theme_color_override("font_color", UiTheme.INK)
	p._region_label.add_theme_color_override("font_color", UiTheme.MUTED)
	style_cached_chip(p._cached_chip)
	p._coord_label.add_theme_color_override("font_color", UiTheme.INK)
	for section in [p._quick_label, p._selected_label, p._coords_label, p._tip,
			p._quality_label, p._download_status, p._download_phase, p._render_status]:
		section.add_theme_color_override("font_color", UiTheme.MUTED)
	UiTheme.apply_field(p._search, true)
	p._suggest_panel.add_theme_stylebox_override("panel", _suggest_style(p))
	for child in p._suggest_list.get_children():
		if child is Button:
			MapSearch.style_row(child as Button)
	p._sheet.add_theme_stylebox_override("panel", UiTheme.glass_panel())
	p._side.add_theme_stylebox_override("panel", _side_style(p))
	UiTheme.apply_primary(p._render_btn)
	UiTheme.apply_ghost(p._download_btn)
	style_download_bar(p)
	UiIcon.apply(p._render_btn, "globe", 22, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	for bar in [p._side_explore, p._sheet_explore]:
		UiTheme.apply_primary(bar)
		UiIcon.apply(bar, "globe", 22, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	UiIcon.apply(p._download_btn, "hard-drive", 20)
	for btn in [p._history_btn, p._settings_btn, p._exit_btn, p._zoom_in_btn, p._zoom_out_btn, p._globe_btn]:
		UiTheme.apply_rail_icon(btn)
	p._nav.add_theme_stylebox_override("panel", _nav_style(p))
	var rail_st := UiTheme.style(UiTheme.GLASS_FILL, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE, true)
	rail_st.set_content_margin_all(4)
	p._zoom_rail.add_theme_stylebox_override("panel", rail_st)
	for card in p._quick_chips:
		(card as PlaceCard).restyle()
	p._canvas.refresh_style()
	UiTheme.apply_scroll(p._quick_scroll)
	_set_selected_quick(p, p._selected_quick)

## Mark one place card as the active place (accent ring, pressed) and
## clear the rest. -1 clears all: the place no longer comes from a card.
static func _set_selected_quick(p: MapPicker, index: int) -> void:
	p._selected_quick = index
	for i in p._quick_chips.size():
		p._quick_chips[i].set_pressed_no_signal(i == index)

## Offline-download feedback under the buttons (progress, then the
## outcome), so the button row keeps its shape in every layout.
static func set_download_status(p: MapPicker, text: String) -> void:
	if p._download_status != null:
		p._download_status.text = text
		p._download_status.visible = text != ""

## The save bar, in the loading screen's accent bar on a quiet track.
static func style_download_bar(p: MapPicker) -> void:
	var track := UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL)
	track.set_content_margin_all(0)
	var fill := UiTheme.style(UiTheme.TEAL, UiTheme.RADIUS_PILL)
	fill.set_content_margin_all(0)
	p._download_bar.add_theme_stylebox_override("background", track)
	p._download_bar.add_theme_stylebox_override("fill", fill)

static func set_download_progress(p: MapPicker, fraction: float, phase: String) -> void:
	if p._download_bar == null:
		return
	p._download_bar.visible = fraction >= 0.0
	p._download_phase.visible = fraction >= 0.0 and phase != ""
	if fraction >= 0.0:
		p._download_bar.value = fraction * 100.0
		p._download_phase.text = phase

## Explore outcome under the buttons (a timed-out place), on its own
## line so download progress never overwrites it, or it the progress.
static func set_render_status(p: MapPicker, text: String) -> void:
	if p._render_status != null:
		p._render_status.text = text
		p._render_status.visible = text != ""

## "Cached" badge under the region (design system: Badge, accent-soft):
## the place's layers are on the device, so Explore opens without waiting.
static func make_cached_chip() -> HBoxContainer:
	var row := HBoxContainer.new()
	var chip := PanelContainer.new()
	chip.name = "Chip"
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	chip.add_child(inner)
	var glyph := TextureRect.new()
	glyph.name = "Glyph"
	glyph.texture = UiIcon.texture("hard-drive", 14)
	glyph.custom_minimum_size = Vector2(14, 14)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(glyph)
	inner.add_child(UiTheme.label("Cached", 12, UiTheme.TEAL))
	row.add_child(chip)
	row.visible = false
	style_cached_chip(row)
	return row

static func style_cached_chip(row: Control) -> void:
	var chip: PanelContainer = row.get_node("Chip")
	var st := UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_PILL)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	chip.add_theme_stylebox_override("panel", st)
	(chip.find_child("Glyph", true, false) as TextureRect).modulate = UiTheme.TEAL
	for l in chip.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", UiTheme.TEAL)

## Show the badge when every layer of the selected place is on the device.
static func refresh_cached(p: MapPicker) -> void:
	if p._cached_chip != null:
		p._cached_chip.visible = CacheStore.keys_fully_cached(
			CacheStore.place_cache_keys(p._lat, p._lon, p._quality))

## Locks Explore while a generation is still running (including a
## cancelled world build that has not wound down), so a press is not
## silently swallowed. The label only changes when a previous scene is
## really still finishing; otherwise it is the same button, dimmed.
static func set_render_busy(p: MapPicker, busy: bool, finishing: bool) -> void:
	if p._render_btn != null:
		p._render_btn.disabled = busy
		p._render_btn.text = FINISHING if busy and finishing else EXPLORE
		MapHome.queue_explore_bar(p)

## Locks Save for offline while a download runs; a second press would
## otherwise retarget the pending history entry.
static func set_download_busy(p: MapPicker, busy: bool) -> void:
	if p._download_btn != null:
		p._download_btn.disabled = busy
	if not busy:
		refresh_cached(p)  # a finished download makes the place cached

## Shows the chosen preset in the footer and on the settings button's
## tooltip, so the current quality is visible before opening the menu.
static func set_quality_preset(p: MapPicker, preset_value: int) -> void:
	p._quality = preset_value
	refresh_cached(p)
	if p._quality_label != null:
		p._quality_label.text = "Quality · %s" % RenderSettings.preset_name(preset_value)
	if p._settings_btn != null:
		p._settings_btn.tooltip_text = "Settings — %s quality" % RenderSettings.preset_name(preset_value)

static func effective_layout(p: MapPicker) -> int:
	return p._current_layout

static func _move(node: Control, parent: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	parent.add_child(node)

static func _move_all(nodes: Array, parent: Node) -> void:
	for node in nodes:
		_move(node, parent)

static func _apply_layout(p: MapPicker, layout: Responsive.Layout) -> void:
	if p._stack == null or p._side_col == null:
		return  # not ready yet; _ready applies the initial layout
	p._current_layout = layout
	_move(p._suggest_panel, p._search_box)
	if not p._coord_mode:
		p._search.placeholder_text = MapSearch.placeholder(p)
	# The layout override lives in Settings, so any forced layout stays
	# reversible from there. Phones keep the coordinates: the sheet's
	# peek detent shows the name, coordinates and Explore.
	var compact := layout == Responsive.Layout.COMPACT
	var expanded := layout == Responsive.Layout.EXPANDED
	p._brand_pill.visible = not compact
	p._name_label.add_theme_font_size_override("font_size", 36 if expanded else 28)
	var pad := Responsive.page_padding(layout)
	var safe := Responsive.safe_insets(p)
	p._overlay.add_theme_constant_override("margin_left", pad + int(safe[0]))
	p._overlay.add_theme_constant_override("margin_right", pad + int(safe[2]))
	p._overlay.add_theme_constant_override("margin_top", pad + int(safe[1]))
	p._overlay.add_theme_constant_override("margin_bottom", pad + int(safe[3]))
	p._nav.add_theme_stylebox_override("panel", _nav_style(p))
	# Buttons: Explore + a full-width Save below in the panel and on
	# tablets; on phones Save is an icon beside Explore.
	p._btn_row.vertical = not compact
	p._download_btn.text = "" if compact else SAVE
	p._download_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact \
		else HORIZONTAL_ALIGNMENT_LEFT
	p._download_btn.size_flags_horizontal = Control.SIZE_SHRINK_END if compact \
		else Control.SIZE_EXPAND_FILL
	p._download_btn.custom_minimum_size = Vector2(56, 56) if compact else Vector2(0, 48)
	# Around the world: a sideways rail in the sheet, a grid in the panel.
	p._quick_grid.columns = 3 if expanded else maxi(1, p._quick_chips.size())
	p._quick_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if expanded \
		else ScrollContainer.SCROLL_MODE_AUTO
	# The panel grid shows whole cards; the side panel itself scrolls
	# (an inner scroll area cut the last row in half above the footer).
	p._quick_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p._quick_scroll.custom_minimum_size = Vector2.ZERO if expanded else Vector2(0, 104)
	p._quick_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expanded else Control.SIZE_SHRINK_BEGIN
	p._quick_box.size_flags_vertical = Control.SIZE_EXPAND_FILL if expanded else Control.SIZE_SHRINK_BEGIN
	for card in p._quick_chips:
		card.custom_minimum_size.x = 0.0 if expanded else float(RAIL_CARD_W)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expanded else Control.SIZE_SHRINK_BEGIN
	if expanded:
		p._stack.visible = false
		p._split.visible = true
		# Park the stacked-layout containers in the hidden stack:
		# left parentless they were orphan nodes, leaked as
		# CanvasItem RIDs and ObjectDB instances on quit.
		_move_all([p._top_col, p._stack_gap, p._sheet], p._stack)
		_move_all([p._side, p._right_col], p._split)
		p._side.custom_minimum_size = Vector2(Responsive.sidebar_width(layout), 0)
		p._side.size_flags_vertical = Control.SIZE_FILL
		p._brand_pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_move(p._nav, p._brand)
		p._nav.size_flags_horizontal = Control.SIZE_SHRINK_END
		_move_all([p._brand_pill, p._search_box, p._sheet_cols, p._quick_box, p._footer], p._side_col)
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
		_move_all([p._side, p._right_col], p._split)
		_move_all([p._top_col, p._stack_gap, p._sheet], p._stack)
		p._side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if compact:
			_move_all([p._search_box, p._nav], p._top_row)
			# Predictions run the full width under the top row: in the
			# field's column the no-results card squeezed the row wider
			# than the phone.
			_move(p._suggest_panel, p._top_col)
			_move(p._brand_pill, p._side_col)  # parked, hidden: phones have no brand row
		else:
			var pill_style := UiTheme.style(UiTheme.GLASS_FILL, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE, true)
			pill_style.content_margin_top = 4
			pill_style.content_margin_bottom = 4
			p._brand_pill.add_theme_stylebox_override("panel", pill_style)
			_move_all([p._brand_pill, p._search_box, p._nav], p._top_row)
		p._nav.size_flags_horizontal = Control.SIZE_SHRINK_END
		p._sheet_cols.vertical = compact
		p._sheet_cols.add_theme_constant_override("separation", 20)
		_move_all([p._sheet_cols, p._quick_box, p._footer], p._sheet_body)
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
	p._zoom_rail.visible = true
	p._zoom_rail.anchor_top = 0.40
	p._zoom_rail.anchor_bottom = 0.40
	if p._current_layout == Responsive.Layout.EXPANDED:
		if p._side.visible and p._side.is_inside_tree():
			var left := p._side.get_global_rect().end.x - origin.x
			want = Vector2((left + p._canvas.size.x) / 2.0, centre.y)
	elif p._sheet.is_inside_tree() and p._top_col.is_inside_tree():
		var top := p._top_col.get_global_rect().end.y - origin.y
		var bottom := p._sheet.get_global_rect().position.y - origin.y
		if bottom > top + 80.0:
			want = Vector2(centre.x, (top + bottom) / 2.0)
		# The zoom rail stays in the map strip between the top bar and the
		# sheet (it overlapped the sheet's top), and steps aside when the
		# sheet leaves it no room.
		var rail_h := p._zoom_rail.get_combined_minimum_size().y
		var lo := top + 12.0 + rail_h / 2.0
		var hi := bottom - 12.0 - rail_h / 2.0
		p._zoom_rail.visible = hi >= lo
		var at := clampf(p._canvas.size.y * 0.40, lo, maxf(hi, lo)) / maxf(p._canvas.size.y, 1.0)
		p._zoom_rail.anchor_top = at
		p._zoom_rail.anchor_bottom = at
	p._canvas.focus_offset = (want - centre).round()
	if p._globe != null:
		p._globe.focus_offset = p._canvas.focus_offset
		p._globe.queue_redraw()
