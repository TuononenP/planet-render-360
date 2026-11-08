class_name HistoryScreen
extends Control

## History and favourites (design system Layout → History): places you
## rendered as PlaceCard size="m" in a grid (2 columns on phones, 3–4 on
## wider windows) or as list rows, switched with a List/Grid control in
## the title row. Each shows its thumbnail (the view as you left it, a
## stand-in until it has one), the name in Instrument Sans, the region, when you were there ("Today, 09:12"),
## its real cache state and size. Favourites pin to the top in their own
## section. Tap opens the place; the star pins it. In the list, swipe
## right to favourite and left to remove from cache; on desktop the same
## actions show on hover and in the context menu. "Clear all cache" sits
## at the bottom behind a confirmation that shows the total size.

signal place_selected(lat: float, lon: float)
signal back_requested

const SWIPE := 80.0
const TINTS := ["1a2350", "b8607e", "7fb8e6", "f0b06a"]  # horizon-* stops

var _list: GridContainer
var _fav_grid: GridContainer
var _store: CacheStore
var _margin: MarginContainer
var _title: Label
var _count_label: Label
var _view_seg: SegmentedControl
var _grid_mode := true
var _current_layout: int = Responsive.Layout.COMPACT
var _col: VBoxContainer
var _clear_btn: Button
var _menu: PopupMenu
var _menu_entry: Dictionary = {}
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	_margin.add_child(col)

	# Title row: back, title + count, List/Grid.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	col.add_child(header)
	var back := UiTheme.icon_button("")
	UiIcon.apply(back, "arrow-left", 22)
	back.tooltip_text = "Back to map"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_title = UiTheme.display_label("Saved places", 28)
	titles.add_child(_title)
	_count_label = UiTheme.label("", 14, UiTheme.MUTED)
	_count_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(_count_label)
	_view_seg = SegmentedControl.new(["Grid", "List"], ["layout-grid", "list"])
	_view_seg.set_icon_only(true)
	_view_seg.select(0)
	_view_seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_view_seg.item_selected.connect(func(i: int) -> void:
		_grid_mode = i == 0
		_on_resized()
		refresh())
	header.add_child(_view_seg)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 16)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_col)
	_list = GridContainer.new()
	_list.columns = 1
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("h_separation", 16)
	_list.add_theme_constant_override("v_separation", 16)
	_col.add_child(_list)
	_clear_btn = SettingsRows.destructive("Clear all cache")
	_clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_clear_btn.pressed.connect(_confirm_clear)
	_col.add_child(_clear_btn)
	_menu = PopupMenu.new()
	_menu.add_item("Add to favourites", 0)
	_menu.add_item("Remove from cache", 1)
	_menu.id_pressed.connect(func(id: int) -> void:
		if id == 0:
			_toggle_favourite(_menu_entry)
		else:
			_remove(_menu_entry))
	add_child(_menu)
	_build_toast()
	resized.connect(_on_resized)
	_on_resized()
	if _store != null:
		refresh()

## Glass pill near the bottom edge for a short message ("Still finishing
## the last scene"); it fades by itself.
func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -28.0
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	_toast.add_theme_stylebox_override("panel", st)
	_toast_label = UiTheme.label("", 15, UiTheme.INK, true)
	_toast.add_child(_toast_label)
	add_child(_toast)

func toast(text: String, seconds: float = 4.0) -> void:
	if _toast == null:
		return
	_toast_label.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.16)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)

func _on_resized() -> void:
	if _title == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	_current_layout = layout
	var pad := Responsive.page_padding(layout)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad + 8)
	_margin.add_theme_constant_override("margin_bottom", pad)
	if _list != null:
		var empty := _store == null or _store.entries.is_empty()
		_list.columns = Responsive.history_columns(layout) if _grid_mode and not empty else 1
		if is_instance_valid(_fav_grid):
			_fav_grid.columns = _list.columns

func bind_store(store: CacheStore) -> void:
	_store = store
	refresh()

func refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	for child in _col.get_children():
		if child != _list and child != _clear_btn:
			child.queue_free()
	var entries: Array = [] if _store == null else _store.entries
	var count := entries.size()
	_count_label.text = "%d place%s on this device" % [count, "" if count == 1 else "s"] \
		if count > 0 else "Places you render wait here, saved on this device."
	_clear_btn.visible = count > 0
	_view_seg.visible = count > 0
	if count == 0:
		_list.columns = 1
		_list.add_child(_empty_card())
		return
	_on_resized()
	var favourites: Array = entries.filter(func(e: Dictionary) -> bool: return bool(e.get("favourite", false)))
	var others: Array = entries.filter(func(e: Dictionary) -> bool: return not bool(e.get("favourite", false)))
	if not favourites.is_empty():
		var fav_label := UiTheme.section_label("Favourites")
		_col.add_child(fav_label)
		_col.move_child(fav_label, 0)
		# A fresh grid like _list (duplicate() also copied the old cards
		# still queued for deletion into Favourites).
		var fav_grid := GridContainer.new()
		_fav_grid = fav_grid
		fav_grid.columns = _list.columns
		fav_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for key in ["h_separation", "v_separation"]:
			fav_grid.add_theme_constant_override(key, 16)
		_col.add_child(fav_grid)
		_col.move_child(fav_grid, 1)
		for e in favourites:
			fav_grid.add_child(_card(e) if _grid_mode else _row(e))
		if not others.is_empty():
			var recent_label := UiTheme.section_label("Recent")
			_col.add_child(recent_label)
			_col.move_child(recent_label, 2)
	for e in others:
		_list.add_child(_card(e) if _grid_mode else _row(e))

func _empty_card() -> PanelContainer:
	var empty_card := PanelContainer.new()
	empty_card.custom_minimum_size = Vector2(0, 240)
	empty_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_card.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_L, UiTheme.LINE))
	var empty_col := VBoxContainer.new()
	empty_col.alignment = BoxContainer.ALIGNMENT_CENTER
	empty_col.add_theme_constant_override("separation", 8)
	empty_card.add_child(empty_col)
	var empty_icon := UiIcon.rect("history", 40, UiTheme.MUTED)
	empty_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	empty_col.add_child(empty_icon)
	var empty_title := UiTheme.label("No places yet", 20, UiTheme.INK, true)
	empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_col.add_child(empty_title)
	var empty := UiTheme.label(
		"Pick a spot on the map and explore it in 360°. It waits for you here, even offline.", 15, UiTheme.MUTED)
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_col.add_child(empty)
	var explore := UiTheme.primary_button("Back to map")
	explore.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	explore.pressed.connect(func() -> void: back_requested.emit())
	empty_col.add_child(explore)
	return empty_card

# --- Cards and rows ---

## Cache state as a StatusBadge: Cached (good), Partial (caution) or
## nothing when no layer is on the device. Returns [word, tone] or [].
func _cache_state(e: Dictionary) -> Array:
	var status := CacheStore.keys_cached_status(CacheStore.entry_cache_keys(e))
	var cached := 0
	var total := 0
	for layer in status:
		cached += int(status[layer]["cached"])
		total += int(status[layer]["total"])
	if total == 0 or cached == 0:
		return []
	return ["Cached", "good"] if cached == total else ["Partial", "caution"]

## Meta line: when, cache state and size, wrapping on narrow cards.
func _badges(e: Dictionary) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if e.has("timestamp"):
		var when := UiTheme.label(UiTheme.relative_time(float(e["timestamp"])), 14, UiTheme.FAINT)
		when.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(when)
	var state := _cache_state(e)
	if not state.is_empty():
		row.add_child(_badge(state[0], state[1], "hard-drive"))
		var bytes := CacheStore.entry_bytes(e)
		if bytes > 0:
			var sz := UiTheme.data_label(UiTheme.cache_size(bytes), 13, UiTheme.MUTED, true)
			sz.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(sz)
	return row

## StatusBadge on a solid surface: 24pt outline, 13/600 word, 14pt icon.
func _badge(word: String, tone: String, icon: String) -> PanelContainer:
	var c := HudParts.tone_color(tone)
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_XS, c)
	st.content_margin_left = 6
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", st)
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 4)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(r)
	var ic := UiIcon.rect(icon, 14, c)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(ic)
	var l := UiTheme.label(word, 13, c, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(l)
	p.custom_minimum_size.y = 24
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p

## The place's own picture when it has one, else the stand-in glyph.
func _thumb(place: String, height: float, e: Dictionary = {}) -> Control:
	var tex := PlaceThumb.load_texture(float(e.get("lat", 0.0)), float(e.get("lon", 0.0))) \
		if not e.is_empty() else null
	if tex != null:
		var photo := RoundedPhoto.new(tex, UiTheme.RADIUS_S)
		photo.custom_minimum_size = Vector2(0, height)
		return photo
	var tint := Color(str(TINTS[abs(place.hash()) % TINTS.size()])).darkened(0.55)
	var thumb := PanelContainer.new()
	thumb.custom_minimum_size = Vector2(0, height)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_theme_stylebox_override("panel", UiTheme.style(tint, UiTheme.RADIUS_S))
	var glyph := UiIcon.rect("mountain", 32, Color(UiTheme.HORIZON_DAY, 0.85))
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.add_child(glyph)
	return thumb

## Star toggle (accent when pinned) and, on hover, Remove from cache
## (left out of phone cards: no hover there, and no room beside the name;
## swipe a list row or use the context menu).
func _actions(e: Dictionary, on_hover: Control, with_trash: bool = true) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var fav := bool(e.get("favourite", false))
	var star := Button.new()
	star.custom_minimum_size = Vector2(44, 44)
	star.tooltip_text = "Remove from favourites" if fav else "Add to favourites"
	UiIcon.apply(star, "star", 20, UiTheme.TEAL if fav else UiTheme.MUTED, UiTheme.TEAL)
	_flat(star)
	star.pressed.connect(func() -> void: _toggle_favourite(e))
	row.add_child(star)
	if not with_trash:
		return row
	var trash := Button.new()
	trash.custom_minimum_size = Vector2(44, 44)
	trash.tooltip_text = "Remove from cache"
	UiIcon.apply(trash, "trash-2", 20, UiTheme.SIGNAL_ERROR, UiTheme.SIGNAL_ERROR)
	_flat(trash)
	trash.pressed.connect(func() -> void: _remove(e))
	trash.modulate.a = 0.0
	on_hover.mouse_entered.connect(func() -> void: trash.modulate.a = 1.0)
	on_hover.mouse_exited.connect(func() -> void: trash.modulate.a = 0.0)
	trash.focus_entered.connect(func() -> void: trash.modulate.a = 1.0)
	row.add_child(trash)
	return row

func _flat(b: Button) -> void:
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	var lit := UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL)
	for st: StyleBoxFlat in [clear, lit]:
		st.set_content_margin_all(0)  # the 20pt glyph fills the 44pt target's centre
	b.add_theme_stylebox_override("normal", clear)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("pressed", lit)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))

## PlaceCard size="m": thumbnail (4:3), name, region, meta line.
func _card(e: Dictionary) -> Button:
	var full := str(e.get("name", "Place"))
	var parts := UiTheme.split_place(full)
	var card := _base_button(e)
	var col := VBoxContainer.new()
	_inset(col)
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var thumb := _thumb(full, 120.0 if _current_layout == Responsive.Layout.COMPACT else 150.0, e)
	col.add_child(thumb)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(names)
	var name_label := UiTheme.display_label(parts[0], 22)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(name_label)
	if parts[1] != "":
		var region := UiTheme.label(parts[1], 14, UiTheme.MUTED)
		region.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Truncate: its full width pushed the card's content past its edge.
		region.clip_text = true
		region.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		names.add_child(region)
	head.add_child(_actions(e, card, _current_layout != Responsive.Layout.COMPACT))
	col.add_child(_badges(e))
	_fit(card, col, 0.0)
	return card

## List row: small thumbnail, name over region, meta, star. Swipe right
## favourites, swipe left removes from cache.
func _row(e: Dictionary) -> Button:
	var full := str(e.get("name", "Place"))
	var parts := UiTheme.split_place(full)
	var row := _base_button(e)
	var r := HBoxContainer.new()
	_inset(r)
	r.add_theme_constant_override("separation", 12)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(r)
	var thumb := _thumb(full, 56.0, e)
	thumb.custom_minimum_size.x = 72
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(thumb)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(texts)
	var title := UiTheme.label(parts[0], 17, UiTheme.INK, true)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(title)
	if parts[1] != "":
		var region := UiTheme.label(parts[1], 14, UiTheme.MUTED)
		region.mouse_filter = Control.MOUSE_FILTER_IGNORE
		region.clip_text = true
		region.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		texts.add_child(region)
	texts.add_child(_badges(e))
	var acts := _actions(e, row)
	acts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(acts)
	_fit(row, r, 76.0)
	row.gui_input.connect(func(ev: InputEvent) -> void: _swipe(row, e, ev))
	return row

## A Button does not size to its children: follow the content's
## minimum height (it is only known once the content is in the tree).
func _fit(b: Button, content: Control, floor_h: float) -> void:
	var sync := func() -> void:
		b.custom_minimum_size.y = maxf(floor_h, content.get_combined_minimum_size().y + 24.0)
	content.minimum_size_changed.connect(sync)
	b.ready.connect(sync)

## Content fills the button inside its 12pt padding.
func _inset(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 12
	c.offset_top = 12
	c.offset_right = -12
	c.offset_bottom = -12

## The tappable surface shared by cards and rows: solid sky-200, opens
## the place, right-click for the context menu.
func _base_button(e: Dictionary) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = str(e.get("name", ""))
	var st := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE)
	st.set_content_margin_all(12)
	var lit := st.duplicate() as StyleBoxFlat
	lit.border_color = UiTheme.LINE_STRONG
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("pressed", lit)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_M))
	var lat := float(e.get("lat", 0.0))
	var lon := float(e.get("lon", 0.0))
	b.pressed.connect(func() -> void:
		if absf(b.position.x - float(b.get_meta("rest_x", b.position.x))) < 4.0:
			place_selected.emit(lat, lon))
	b.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_menu_entry = e
			_menu.set_item_text(0, "Remove from favourites" if bool(e.get("favourite", false)) else "Add to favourites")
			_menu.position = Vector2i(get_screen_position() + get_local_mouse_position())
			_menu.popup())
	return b

## Horizontal drag on a list row: the row follows the finger over the
## action's fill (accent right, signal-error left) and acts past SWIPE.
func _swipe(row: Button, e: Dictionary, ev: InputEvent) -> void:
	if ev is InputEventScreenDrag:
		if not row.has_meta("rest_x"):
			row.set_meta("rest_x", row.position.x)
		var dx := row.position.x - float(row.get_meta("rest_x")) + (ev as InputEventScreenDrag).relative.x
		row.position.x = float(row.get_meta("rest_x")) + dx
		var st := (row.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		st.bg_color = UiTheme.SURFACE.lerp(UiTheme.TEAL if dx > 0.0 else UiTheme.SIGNAL_ERROR,
			clampf(absf(dx) / SWIPE, 0.0, 1.0) * 0.5)
		row.add_theme_stylebox_override("normal", st)
		row.accept_event()
	elif ev is InputEventScreenTouch and not (ev as InputEventScreenTouch).pressed and row.has_meta("rest_x"):
		var dx := row.position.x - float(row.get_meta("rest_x"))
		row.position.x = float(row.get_meta("rest_x"))
		row.remove_meta("rest_x")
		if dx > SWIPE:
			_toggle_favourite(e)
		elif dx < -SWIPE:
			_remove(e)
		else:
			refresh()

func _toggle_favourite(e: Dictionary) -> void:
	if _store == null or e.is_empty():
		return
	_store.set_favourite(e, not bool(e.get("favourite", false)))
	refresh()

func _remove(e: Dictionary) -> void:
	if _store == null or e.is_empty():
		return
	var name_text: String = UiTheme.split_place(str(e.get("name", "")))[0]
	_store.remove_place(e)
	refresh()
	toast("%s removed from cache" % name_text)

func _confirm_clear() -> void:
	SettingsRows.confirm(self, "Clear all cache?",
		"This frees %s. Your places stay listed here and download again when you open them."
			% UiTheme.cache_size(OfflineDownloader.cache_size_bytes()),
		"Clear all cache", func() -> void:
			OfflineDownloader.clear_cache()
			refresh()
			toast("Cache cleared"))
