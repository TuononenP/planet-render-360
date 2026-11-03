class_name MapHome
extends RefCounted

## Map home states from the design system (MapHome): the Recent places
## rail, the first-launch state (three featured places and one line of
## copy), offline (a Toast, an "Offline" badge in the search field, and
## only cached places tappable), the Toast itself, Save for offline
## carrying its progress on its label, and the map keys (/ or ⌘F search,
## Enter explores, Esc leaves the field). Operates on the picker via `p`.

const FIRST_LAUNCH := "Pick any point on the map, or start with one of these."
const OFFLINE_TITLE := "You're offline. Cached places still open."
const OPACITY_DISABLED := 0.38
const RECENT_MAX := 8

static func build(p: MapPicker) -> void:
	p._recent_box = VBoxContainer.new()
	p._recent_box.add_theme_constant_override("separation", 8)
	p._recent_box.visible = false
	p._recent_box.add_child(UiTheme.section_label("Recent places"))
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 104)
	UiTheme.apply_scroll(scroll)
	p._recent_box.add_child(scroll)
	p._recent_row = HBoxContainer.new()
	p._recent_row.add_theme_constant_override("separation", 8)
	scroll.add_child(p._recent_row)
	p._first_note = UiTheme.label(FIRST_LAUNCH, 15, UiTheme.MUTED)
	p._first_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._first_note.visible = false
	p._offline_badge = HudParts.status_badge("Offline", "error", "wifi-off")
	p._offline_badge.focus_mode = Control.FOCUS_NONE
	p._offline_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p._offline_badge.visible = false
	p._offline_badge.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	p._search.add_child(p._offline_badge)
	p._toast = Toast.new()
	p.add_child(p._toast)

## History moved: rebuild the Recent rail and the first-launch state.
static func refresh_recent(p: MapPicker) -> void:
	if p._recent_row == null:
		return
	for child in p._recent_row.get_children():
		child.queue_free()
	var entries: Array = p._store.entries if p._store != null else []
	for e in entries.slice(0, RECENT_MAX):
		var full := str(e.get("name", ""))
		var lat := float(e.get("lat", 0.0))
		var lon := float(e.get("lon", 0.0))
		var card := PlaceCard.make(UiTheme.split_place(full)[0])
		card.toggle_mode = false
		card.custom_minimum_size.x = float(MapChrome.RAIL_CARD_W)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.set_meta("lat", lat)
		card.set_meta("lon", lon)
		var photo := PlaceThumb.load_texture(lat, lon)
		if photo != null:
			card.set_photo(photo)
		card.pressed.connect(func() -> void: p._select_suggestion(full, lat, lon))
		p._recent_row.add_child(card)
	p._recent_box.visible = not entries.is_empty()
	# First launch: three featured places and one line of copy.
	var first := entries.is_empty()
	p._first_note.visible = first
	for i in p._quick_chips.size():
		p._quick_chips[i].visible = not first or i < 3
		# A snapshot taken since the picker was built replaces the shipped one.
		var chip := p._quick_chips[i] as PlaceCard
		var photo := PlaceThumb.load_preset(str(PresetViews.ROWS[i]["id"]),
			float(chip.get_meta("lat")), float(chip.get_meta("lon")))
		if photo != null:
			chip.set_photo(photo)
	apply_offline(p)

## Offline: say so once, badge the field, dim what cannot open.
static func set_offline(p: MapPicker, on: bool) -> void:
	if on == p._offline:
		return
	p._offline = on
	if on:
		p._toast.show_message(OFFLINE_TITLE, "", "error")
		place_toast(p)
	else:
		p._toast.dismiss()
	apply_offline(p)

static func apply_offline(p: MapPicker) -> void:
	if p._offline_badge == null:
		return
	p._offline_badge.visible = p._offline
	p._offline_badge.reset_size()
	p._offline_badge.position = Vector2(p._search.size.x - 52.0 - p._offline_badge.size.x,
		(p._search.size.y - p._offline_badge.size.y) / 2.0)
	var cards: Array = p._quick_chips.duplicate()
	if p._recent_row != null:
		cards.append_array(p._recent_row.get_children())
	for card in cards:
		var c := card as Button
		var cached := not p._offline or _point_cached(p, c)
		c.disabled = not cached
		c.modulate.a = 1.0 if cached else OPACITY_DISABLED

static func _point_cached(p: MapPicker, c: Button) -> bool:
	var lat := float(c.get_meta("lat", NAN))
	var lon := float(c.get_meta("lon", NAN))
	if is_nan(lat):
		return false
	return CacheStore.keys_fully_cached(CacheStore.place_cache_keys(lat, lon, p._quality))

## Phones: centred above the sheet; wider windows: bottom-right.
static func place_toast(p: MapPicker) -> void:
	if p._toast == null or not p._toast.visible:
		return
	var compact := p._current_layout == Responsive.Layout.COMPACT
	var pad := float(Responsive.page_padding(p._current_layout))
	var bottom := p.size.y - pad
	if compact and p._sheet.is_inside_tree():
		bottom = p._sheet.get_global_rect().position.y - p.get_global_position().y
	p._toast.place(p.size, pad, bottom, compact)

## Save for offline carries its progress and outcome on its label (the
## phone's icon-only button keeps the line under it instead).
static func set_save_label(p: MapPicker, text: String) -> void:
	var icon_only := p._current_layout == Responsive.Layout.COMPACT
	if icon_only:
		MapChrome.set_download_status(p, text)
		p._download_btn.tooltip_text = text if text != "" else MapChrome.SAVE
		return
	MapChrome.set_download_status(p, "")
	p._download_btn.text = text if text != "" else MapChrome.SAVE

## The globe hero: zooming out past the flat map's widest zoom turns
## the map into the globe, zooming in on the globe turns it back; one
## cross-fade over duration-gentle at the threshold (the reduced-motion
## form of the morph).
static func build_globe(p: MapPicker) -> void:
	p._globe = GlobeView.new()
	p._globe.set_anchors_preset(Control.PRESET_FULL_RECT)
	p._globe.visible = false
	p._map_wrap.add_child(p._globe)
	p._map_wrap.move_child(p._globe, p._canvas.get_index() + 1)
	p._canvas.zoom_past_min.connect(func() -> void: show_globe(p, true))
	p._globe.zoom_to_map.connect(func(_la: float, _lo: float) -> void: show_globe(p, false))
	p._globe.picked.connect(func(la: float, lo: float) -> void: p._on_picked(la, lo))

static func show_globe(p: MapPicker, on: bool) -> void:
	if p._globe.visible == on and p._canvas.visible != on:
		return
	var from: Control = p._canvas if on else p._globe
	var to: Control = p._globe if on else p._canvas
	if on:
		p._globe.centre = Vector2(p._lat, p._lon)
		p._globe.pin = Vector2(p._lat, p._lon)
	to.visible = true
	to.modulate.a = 0.0
	var tw := p.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var t := maxf(UiPrefs.motion(0.38), 0.6 if UiPrefs.reduce_motion else 0.0)
	tw.tween_property(to, "modulate:a", 1.0, t)
	tw.tween_property(from, "modulate:a", 0.0, t)
	tw.chain().tween_callback(func() -> void: from.visible = false)
	p._globe_btn.tooltip_text = "Flat map" if on else "Globe"
	p._globe_btn.accessibility_name = p._globe_btn.tooltip_text

static func globe_shown(p: MapPicker) -> bool:
	return p._globe != null and p._globe.visible and not p._canvas.visible

## Desktop: the left side panel collapses to a 64pt rail (expand,
## search, history, settings) so the map gets the window.
const RAIL_W := 64

static func build_rail(p: MapPicker) -> void:
	p._collapse_btn = UiIcon.button("chevron-left", "Collapse panel")
	p._collapse_btn.pressed.connect(func() -> void: set_collapsed(p, true))
	p._brand.add_child(p._collapse_btn)
	p._brand.move_child(p._collapse_btn, p._brand.get_child_count() - 1)
	p._side_rail = VBoxContainer.new()
	p._side_rail.add_theme_constant_override("separation", 8)
	p._side_rail.visible = false
	var expand := UiIcon.button("chevron-right", "Expand panel")
	expand.pressed.connect(func() -> void: set_collapsed(p, false))
	p._side_rail.add_child(expand)
	var search := UiIcon.button("search", "Search")
	search.pressed.connect(func() -> void:
		set_collapsed(p, false)
		p._search.grab_focus())
	p._side_rail.add_child(search)
	var history := UiIcon.button("history", "History & saved places")
	history.pressed.connect(func() -> void: p.history_requested.emit())
	p._side_rail.add_child(history)
	var settings := UiIcon.button("settings", "Settings")
	settings.pressed.connect(func() -> void: p.settings_requested.emit())
	p._side_rail.add_child(settings)
	p._side.add_child(p._side_rail)

static func set_collapsed(p: MapPicker, on: bool) -> void:
	p._side_collapsed = on
	apply_rail(p)

## After every layout pass: the collapsed rail only exists in the side
## panel arrangement.
static func apply_rail(p: MapPicker) -> void:
	if p._side_rail == null:
		return
	var expanded := p._current_layout == Responsive.Layout.EXPANDED
	var collapsed := expanded and p._side_collapsed
	p._side_rail.visible = collapsed
	p._side_scroll.visible = not collapsed
	p._collapse_btn.visible = expanded
	if expanded:
		p._side.custom_minimum_size.x = RAIL_W if collapsed \
			else float(Responsive.sidebar_width(p._current_layout))
		# The rail hugs its four buttons; the open panel runs full height.
		p._side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if collapsed else Control.SIZE_FILL
		var st := (p._side.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		st.set_content_margin_all(8 if collapsed else 24)
		p._side.add_theme_stylebox_override("panel", st)
	p._queue_focus_update()
	queue_explore_bar(p)

## Explore sits above the Around the world shelf, so scrolling down to
## the shelf hides it. While it is out of sight, a pinned "Explore
## <place> in 360°" bar sits at the bottom of the side panel / phone
## sheet; the scroll stays put, so the picked card stays in view.
static func build_explore_bars(p: MapPicker) -> void:
	var side_body := VBoxContainer.new()
	side_body.add_theme_constant_override("separation", 12)
	p._side.remove_child(p._side_scroll)
	p._side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_body.add_child(p._side_scroll)
	p._side.add_child(side_body)
	p._side_explore = _explore_bar(p)
	side_body.add_child(p._side_explore)
	p._sheet_explore = _explore_bar(p)
	p._sheet_scroll.get_parent().add_child(p._sheet_explore)
	for scroll: ScrollContainer in [p._side_scroll, p._sheet_scroll]:
		var bar := scroll.get_v_scroll_bar()
		bar.value_changed.connect(func(_v: float) -> void: queue_explore_bar(p))
		bar.changed.connect(func() -> void: queue_explore_bar(p))
		scroll.resized.connect(func() -> void: queue_explore_bar(p))

static func _explore_bar(p: MapPicker) -> Button:
	var b := UiTheme.primary_button(MapChrome.EXPLORE)
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiIcon.apply(b, "globe", 22, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	b.visible = false
	b.pressed.connect(func() -> void: p.render_requested.emit(p._lat, p._lon))
	return b

static func queue_explore_bar(p: MapPicker) -> void:
	if p._side_explore != null and p.is_inside_tree():
		p.call_deferred("_update_explore_bar")

static func update_explore_bar(p: MapPicker) -> void:
	var text := p._render_btn.text
	if not p._render_btn.disabled and p._name_label.text != "":
		text = "Explore %s in 360°" % p._name_label.text
	for bar: Button in [p._side_explore, p._sheet_explore]:
		var scroll: ScrollContainer = p._side_scroll if bar == p._side_explore else p._sheet_scroll
		bar.visible = _explore_hidden(p, scroll)
		bar.text = text
		bar.disabled = p._render_btn.disabled

## Explore is in this scroll area (the layout put it there) but scrolled
## more than halfway out of it. The bottom edge is the parent's, as if the
## bar were hidden: the bar's own height must not keep it showing.
static func _explore_hidden(p: MapPicker, scroll: ScrollContainer) -> bool:
	if not scroll.is_visible_in_tree() or not scroll.is_ancestor_of(p._render_btn):
		return false
	var mid := p._render_btn.get_global_rect().get_center().y
	return mid < scroll.get_global_rect().position.y \
		or mid > scroll.get_parent_control().get_global_rect().end.y

## / or ⌘F / Ctrl+F focus search, Enter explores the selected place,
## Esc leaves the search field (before Main's Esc would quit).
static func handle_key(p: MapPicker, key: InputEventKey) -> bool:
	var in_search := p._search.has_focus()
	if key.keycode == KEY_ESCAPE and in_search:
		p._search.release_focus()
		p._hide_suggestions()
		return true
	if in_search:
		return false
	if key.keycode == KEY_SLASH or (key.keycode == KEY_F and (key.ctrl_pressed or key.meta_pressed)):
		p._search.grab_focus()
		return true
	if key.keycode in [KEY_ENTER, KEY_KP_ENTER] and not p._render_btn.disabled \
			and p.get_viewport().gui_get_focus_owner() == null:
		p.render_requested.emit(p._lat, p._lon)
		return true
	return false
