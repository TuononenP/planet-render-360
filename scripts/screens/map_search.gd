class_name MapSearch
extends RefCounted

## Search and predictions for MapPicker, split out of it like MapChrome:
## stateless statics that operate on the picker's controls via `p`.
## Instant on-device predictions first; remote ones refine the list
## after a debounce pause, so typing does not hit the network per key.
## "46.5, 7.9" typed or pasted selects that point directly.

static func ensure_searcher(p: MapPicker) -> void:
	if p._searcher != null:
		return
	p._searcher = SearchFetcher.new()
	p.add_child(p._searcher)
	p._searcher.succeeded.connect(func(n: String, la: float, lo: float) -> void:
		p._on_picked(la, lo)
		p.selected_name = n
		p._show_place(n))
	p._searcher.failed.connect(func(reason: String) -> void:
		p._show_place(reason))
	p._searcher.suggestions_ready.connect(func(query: String, results: Array) -> void:
		if query != p._search.text.strip_edges().to_lower():
			return  # stale response for text the user has already changed
		if not results.is_empty():
			show_suggestions(p, results))

static func on_text_changed(p: MapPicker, text: String) -> void:
	var cleaned := text.strip_edges()
	if cleaned.length() < 2 or looks_like_coordinates(cleaned):
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
