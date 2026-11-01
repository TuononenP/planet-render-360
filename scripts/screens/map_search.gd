class_name MapSearch
extends RefCounted

## Search and predictions for MapPicker, split out of it like MapChrome:
## stateless statics that operate on the picker's controls via `p`.
## Instant on-device predictions first; remote ones refine the list
## after a debounce pause, so typing does not hit the network per key.
## "46.5, 7.9" typed or pasted selects that point directly, in either
## mode; the hash toggle switches the field to coordinate entry (mono,
## no predictions). A search with no match shows the design system's
## no-results state with "Use coordinates".

static func ensure_searcher(p: MapPicker) -> void:
	if p._searcher != null:
		return
	p._searcher = SearchFetcher.new()
	p.add_child(p._searcher)
	p._searcher.succeeded.connect(func(n: String, la: float, lo: float) -> void:
		p._on_picked(la, lo)
		p.selected_name = n
		p._show_place(n))
	# A failed search keeps the selected place: no match opens the
	# no-results state under the field; no connection is the offline state.
	p._searcher.failed.connect(func(reason: String) -> void:
		if reason == SearchFetcher.UNREACHABLE:
			p.set_offline(true)
		else:
			show_no_results(p, p._search.text.strip_edges()))
	p._searcher.suggestions_ready.connect(func(query: String, results: Array) -> void:
		if query != p._search.text.strip_edges().to_lower():
			return  # stale response for text the user has already changed
		if not results.is_empty():
			show_suggestions(p, results))

static func on_text_changed(p: MapPicker, text: String) -> void:
	var cleaned := text.strip_edges()
	if looks_like_coordinates(cleaned):
		p._suggest_timer.stop()
		hide_suggestions(p)
		var ll := parse_coordinates(cleaned)
		p._on_picked(ll.x, ll.y)
		return
	if cleaned.length() < 2 or p._coord_mode:
		p._suggest_timer.stop()
		hide_suggestions(p)
		return
	show_suggestions(p, LocationData.suggestions_for(cleaned))
	p._suggest_timer.start()

static func looks_like_coordinates(text: String) -> bool:
	if not text.contains(","):
		return false
	var parts := text.split(",")
	return parts.size() == 2 and parts[0].strip_edges().is_valid_float() \
		and parts[1].strip_edges().is_valid_float()

## "lat, lon" clamped to the valid range (x = lat, y = lon).
static func parse_coordinates(text: String) -> Vector2:
	var parts := text.split(",")
	return Vector2(clampf(parts[0].strip_edges().to_float(), -90.0, 90.0),
		clampf(parts[1].strip_edges().to_float(), -180.0, 180.0))

static func request_remote(p: MapPicker) -> void:
	var cleaned := p._search.text.strip_edges()
	if cleaned.length() < 2 or looks_like_coordinates(cleaned):
		return
	ensure_searcher(p)
	p._searcher.suggest(cleaned)

## Suggestion rows share the OptionButton lesson: explicit hover /
## pressed text colours, or the label goes near-invisible on hover.
static func style_row(row: Button) -> void:
	for key in ["font_color", "font_focus_color"]:
		row.add_theme_color_override(key, UiTheme.INK)
	for key in ["font_hover_color", "font_pressed_color"]:
		row.add_theme_color_override(key, UiTheme.ON_ACCENT)
	UiIcon.apply(row, "map-pin", 18, UiTheme.MUTED, UiTheme.ON_ACCENT)
	row.add_theme_color_override("icon_hover_color", UiTheme.ON_ACCENT)
	row.add_theme_stylebox_override("normal", UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_S))
	row.add_theme_stylebox_override("hover", UiTheme.style(UiTheme.TEAL, UiTheme.RADIUS_S))
	row.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.TEAL, UiTheme.RADIUS_S))
	row.add_theme_stylebox_override("focus", UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_S, UiTheme.TEAL))

static func show_suggestions(p: MapPicker, results: Array) -> void:
	for child in p._suggest_list.get_children():
		child.queue_free()
	if results.is_empty():
		p._suggest_panel.visible = false
		return
	for item in results.slice(0, 5):
		var place := str(item.get("name", ""))
		var lat := float(item.get("lat", 0.0))
		var lon := float(item.get("lon", 0.0))
		var row := Button.new()
		row.text = place
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size = Vector2(0, 48)
		row.add_theme_font_size_override("font_size", 15)
		style_row(row)
		row.pressed.connect(func() -> void: select(p, place, lat, lon))
		p._suggest_list.add_child(row)
	p._suggest_panel.visible = true

## The no-results state: what was searched, what to try, and a way
## into coordinate entry.
static func show_no_results(p: MapPicker, query: String) -> void:
	for child in p._suggest_list.get_children():
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 12)
	pad.add_child(box)
	var title := UiTheme.label("No places match \"%s\"" % query, 15, UiTheme.INK, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var hint := UiTheme.label("Try a landmark, a town or coordinates like 46.5, 7.9", 14, UiTheme.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var use := UiTheme.quiet_button("Use coordinates")
	UiIcon.apply(use, "hash", 18, UiTheme.TEAL, UiTheme.TEAL)
	use.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	use.pressed.connect(func() -> void: set_coord_mode(p, true, true))
	box.add_child(use)
	p._suggest_list.add_child(pad)
	p._suggest_panel.visible = true

## The hash toggle inside the field: coordinate entry (mono, a
## coordinate placeholder, no predictions) or place search.
static func build_mode_toggle(p: MapPicker) -> void:
	p._mode_btn = Button.new()
	p._mode_btn.custom_minimum_size = Vector2(44, 44)
	p._mode_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	p._mode_btn.offset_left = -48
	p._mode_btn.offset_right = -4
	p._mode_btn.offset_top = -22
	p._mode_btn.offset_bottom = 22
	p._mode_btn.pressed.connect(func() -> void: set_coord_mode(p, not p._coord_mode, true))
	p._search.add_child(p._mode_btn)
	set_coord_mode(p, false)

## `focus`: the user switched, so put the caret in the field.
static func set_coord_mode(p: MapPicker, on: bool, focus: bool = false) -> void:
	p._coord_mode = on
	hide_suggestions(p)
	p._search.placeholder_text = "46.5197, 6.6323" if on else placeholder(p)
	p._search.add_theme_font_override("font", UiTheme.data() if on else UiTheme.sans())
	p._search.right_icon = UiIcon.texture("hash" if on else "search", 20, 1.0)
	p._mode_btn.tooltip_text = "Search by name" if on else "Enter coordinates"
	UiIcon.apply(p._mode_btn, "search" if on else "hash", 18, UiTheme.MUTED, UiTheme.ON_ACCENT)
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	var lit := UiTheme.style(Color(UiTheme.INK, 0.08), UiTheme.RADIUS_PILL)
	clear.set_content_margin_all(0)
	lit.set_content_margin_all(0)
	p._mode_btn.add_theme_stylebox_override("normal", clear)
	p._mode_btn.add_theme_stylebox_override("hover", lit)
	p._mode_btn.add_theme_stylebox_override("pressed", lit)
	p._mode_btn.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	# Text, clear button and mode icon end before the toggle; the field
	# gives up minimum characters for it so a 390pt phone row still fits.
	p._search.add_theme_constant_override("minimum_character_width", 4)
	for state in ["normal", "focus", "read_only"]:
		var st := (p._search.get_theme_stylebox(state) as StyleBoxFlat).duplicate() as StyleBoxFlat
		st.content_margin_right = 52.0
		st.content_margin_left = 20.0
		p._search.add_theme_stylebox_override(state, st)
	if focus and p.is_inside_tree():
		p._search.grab_focus()

## Place-search hint: the phone's field is too narrow for the full one.
static func placeholder(p: MapPicker) -> String:
	return "Search" if p._current_layout == Responsive.Layout.COMPACT else "Search places or coordinates"

static func hide_suggestions(p: MapPicker) -> void:
	if p._suggest_panel != null:
		p._suggest_panel.visible = false

static func select(p: MapPicker, place: String, lat: float, lon: float) -> void:
	hide_suggestions(p)
	p._suggest_timer.stop()
	p._search.set_block_signals(true)
	p._search.text = place
	p._search.set_block_signals(false)
	p._on_picked(lat, lon)
	p.selected_name = place
	p._show_place(place)

static func submit(p: MapPicker, text: String) -> void:
	var cleaned := text.strip_edges()
	if looks_like_coordinates(cleaned):
		var ll := parse_coordinates(cleaned)
		p._on_picked(ll.x, ll.y)
		return
	for place in LocationData.known_places():
		if cleaned.to_lower() == str(place["name"]).to_lower() \
				or str(place["name"]).to_lower().begins_with(cleaned.to_lower()):
			select(p, str(place["name"]), float(place["lat"]), float(place["lon"]))
			return
	ensure_searcher(p)
	p._searcher.search(cleaned)
