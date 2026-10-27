class_name MapPicker
extends Control

signal render_requested(lat: float, lon: float)
signal history_requested

var _lat := 48.8566
var _lon := 2.3522
var _canvas: MapTileView
var _coord_label: Label
var _name_label: Label
var _lat_field: LineEdit
var _lon_field: LineEdit

var _margin: MarginContainer
var _stack: VBoxContainer
var _split: HBoxContainer
var _sidebar: PanelContainer
var _side_col: VBoxContainer
var _header: HBoxContainer
var _search: LineEdit
var _search_box: VBoxContainer
var _suggest_panel: PanelContainer
var _suggest_list: VBoxContainer
var _suggest_timer: Timer
var _map_wrap: Control
var _card: PanelContainer
var _history_btn: Button
var _tip: Label
var _quick_box: VBoxContainer
var _ready_label: Label
var _coords_label: Label
var _layout_btn: OptionButton
var _forced_layout := -1  # -1 = Auto, else Responsive.Layout value
var _current_layout: int = Responsive.Layout.COMPACT

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)

	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 10)
	_margin.add_child(_stack)
	_split = HBoxContainer.new()
	_split.add_theme_constant_override("separation", 16)
	_split.visible = false
	_margin.add_child(_split)

	# Header: name + one-line promise, layout option stays quiet.
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 10)
	_header.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UiTheme.label("◭  Planet Render 360", 27, UiTheme.INK, true)
	title_box.add_child(title)
	var tagline := UiTheme.label("Stand anywhere on Earth — see it in 360°", 14, UiTheme.MUTED)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(tagline)
	_header.add_child(title_box)
	_layout_btn = OptionButton.new()
	_layout_btn.add_item("Auto layout", 0)
	_layout_btn.add_item("Compact", 1)
	_layout_btn.add_item("Wide", 2)
	_layout_btn.custom_minimum_size = Vector2(118, 44)
	_layout_btn.add_theme_font_size_override("font_size", 14)
	_layout_btn.add_theme_color_override("font_color", UiTheme.INK)
	_layout_btn.add_theme_stylebox_override("normal", UiTheme.style(UiTheme.FIELD, 12, UiTheme.LINE))
	_layout_btn.add_theme_stylebox_override("hover", UiTheme.style(Color.WHITE, 12, UiTheme.LINE))
	_layout_btn.add_theme_stylebox_override("pressed", UiTheme.style(Color.WHITE, 12, UiTheme.LINE))
	_layout_btn.item_selected.connect(_on_layout_selected)
	_header.add_child(_layout_btn)

	_search_box = VBoxContainer.new()
	_search_box.add_theme_constant_override("separation", 6)
	_search = UiTheme.field("Search a place — try “Banff”")
	_search.text_submitted.connect(func(t: String) -> void:
		_hide_suggestions()
		_on_search(t))
	_search.text_changed.connect(_on_search_text_changed)
	_search_box.add_child(_search)
	_suggest_panel = PanelContainer.new()
	_suggest_panel.visible = false
	_suggest_panel.add_theme_stylebox_override("panel",
		UiTheme.style(UiTheme.CARD, 14, Color.TRANSPARENT, true))
	_suggest_list = VBoxContainer.new()
	_suggest_list.add_theme_constant_override("separation", 2)
	_suggest_panel.add_child(_suggest_list)
	_search_box.add_child(_suggest_panel)
	_suggest_timer = Timer.new()
	_suggest_timer.one_shot = true
	_suggest_timer.wait_time = 0.45
	_suggest_timer.timeout.connect(_request_remote_suggestions)
	add_child(_suggest_timer)

	# Quick picks: one tap to a wow place, no typing needed first run.
	_quick_box = VBoxContainer.new()
	_quick_box.add_theme_constant_override("separation", 6)
	_quick_box.add_child(UiTheme.section_label("Try a place — one tap"))
	var quick_row := HBoxContainer.new()
	quick_row.add_theme_constant_override("separation", 8)
	_quick_box.add_child(quick_row)
	for quick in [
			["Paris", "Paris, France", 48.8566, 2.3522],
			["Alps", "Interlaken, Switzerland", 46.6863, 7.8632],
			["Banff", "Banff, Canada", 51.1789, -115.5708],
			["Big Sur", "Big Sur, United States", 36.2704, -121.8081],
			["Tokyo", "Tokyo, Japan", 35.6762, 139.6503]]:
		var chip := UiTheme.chip_button(str(quick[0]))
		var qname := str(quick[1])
		var qlat := float(quick[2])
		var qlon := float(quick[3])
		chip.pressed.connect(func() -> void: _select_suggestion(qname, qlat, qlon))
		quick_row.add_child(chip)

	# Map fills whatever space the layout gives it (no fixed height, so
	# no dead band below the card on tall or desktop windows).
	_map_wrap = Control.new()
	_map_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_wrap.custom_minimum_size = Vector2(0, 240)
	_canvas = MapTileView.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.picked.connect(_on_picked)
	_map_wrap.add_child(_canvas)
	var zoom_row := HBoxContainer.new()
	zoom_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	zoom_row.offset_left = -124
	zoom_row.offset_top = 14
	zoom_row.offset_right = -14
	zoom_row.offset_bottom = 68
	zoom_row.add_theme_constant_override("separation", 8)
	_map_wrap.add_child(zoom_row)
	var zoom_out := UiTheme.icon_button("−")
	zoom_out.pressed.connect(func() -> void: _canvas.zoom_out())
	zoom_row.add_child(zoom_out)
	var zoom_in := UiTheme.icon_button("+")
	zoom_in.pressed.connect(func() -> void: _canvas.zoom_in())
	zoom_row.add_child(zoom_in)
	# Hint pill floats on the map: guidance where the hand already is,
	# at no layout height cost on compact screens.
	var hint_pill := UiTheme.pill("Tap the map to drop the pin", 13)
	hint_pill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_pill.offset_left = 12
	hint_pill.offset_top = -52
	hint_pill.offset_right = 236
	hint_pill.offset_bottom = -12
	hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_wrap.add_child(hint_pill)
	_tip = hint_pill.get_meta("label") as Label

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, 16, Color.TRANSPARENT, true))
	var card_col := VBoxContainer.new()
	card_col.add_theme_constant_override("separation", 10)
	_card.add_child(card_col)
	card_col.add_child(UiTheme.section_label("Selected place"))
	_name_label = UiTheme.label("Paris, France", 22, UiTheme.INK, true)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_col.add_child(_name_label)
	_coord_label = UiTheme.label("", 15, UiTheme.MUTED)
	card_col.add_child(_coord_label)
	_ready_label = UiTheme.label("● Ready — tap Render and step inside", 14, UiTheme.TEAL, true)
	card_col.add_child(_ready_label)
	_coords_label = UiTheme.section_label("Coordinates — or just tap the map")
	card_col.add_child(_coords_label)
	var fields := HBoxContainer.new()
	fields.add_theme_constant_override("separation", 10)
	card_col.add_child(fields)
	_lat_field = UiTheme.field("Latitude")
	_lon_field = UiTheme.field("Longitude")
	_lat_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lon_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lat_field.text = str(_lat)
	_lon_field.text = str(_lon)
	_lat_field.text_changed.connect(func(_t: String) -> void: _sync_from_fields())
	_lon_field.text_changed.connect(func(_t: String) -> void: _sync_from_fields())
	fields.add_child(_lat_field)
	fields.add_child(_lon_field)
	var render_btn := UiTheme.primary_button("◭  Render this place in 360°")
	render_btn.pressed.connect(func() -> void: render_requested.emit(_lat, _lon))
	card_col.add_child(render_btn)

	_history_btn = UiTheme.ghost_button("◷  History & saved places")
	_history_btn.pressed.connect(func() -> void: history_requested.emit())

	_sidebar = PanelContainer.new()
	_sidebar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_sidebar.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, 18, Color.TRANSPARENT, true))
	_side_col = VBoxContainer.new()
	_side_col.add_theme_constant_override("separation", 12)
	_sidebar.add_child(_side_col)

	resized.connect(_on_resized)
	_apply_layout(Responsive.layout_for_width(size.x))
	_refresh_labels()

func _on_resized() -> void:
	if _forced_layout >= 0:
		_apply_layout(_forced_layout)
	else:
		_apply_layout(Responsive.layout_for_width(size.x))

func _on_layout_selected(index: int) -> void:
	match index:
		1:
			_forced_layout = Responsive.Layout.COMPACT
		2:
			_forced_layout = Responsive.Layout.MEDIUM
		_:
			_forced_layout = -1
	_on_resized()

func effective_layout() -> int:
	return _current_layout

func _move(node: Control, parent: Container) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	parent.add_child(node)

func _apply_layout(layout: Responsive.Layout) -> void:
	if _stack == null:
		return  # not ready yet; _ready applies the initial layout
	_current_layout = layout
	# Compact is height-tight: the map hint already says "tap the map",
	# so the coordinates caption gives its height back to the map.
	if _coords_label != null:
		_coords_label.visible = layout != Responsive.Layout.COMPACT
	# The layout override is a wide-screen convenience; on compact its
	# minimum width alone would push the whole column past the screen.
	if _layout_btn != null:
		_layout_btn.visible = layout != Responsive.Layout.COMPACT
	var pad := Responsive.page_padding(layout)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad)
	_margin.add_theme_constant_override("margin_bottom", pad)
	if Responsive.is_split(layout):
		_stack.visible = false
		_split.visible = true
		_move(_map_wrap, _split)
		_move(_sidebar, _split)
		_sidebar.custom_minimum_size = Vector2(Responsive.sidebar_width(layout), 0)
		_move(_header, _side_col)
		_move(_search_box, _side_col)
		_move(_quick_box, _side_col)
		_move(_card, _side_col)
		_move(_history_btn, _side_col)
	else:
		_split.visible = false
		_stack.visible = true
		_move(_header, _stack)
		_move(_search_box, _stack)
		_move(_quick_box, _stack)
		_move(_map_wrap, _stack)
		_move(_card, _stack)
		_move(_history_btn, _stack)

func _on_picked(lat: float, lon: float) -> void:
	_hide_suggestions()
	selected_name = ""
	_lat = lat
	_lon = lon
	_lat_field.text = "%.4f" % lat
	_lon_field.text = "%.4f" % lon
	# Keep the map centred on the choice: search and quick picks arrive
	# without a map tap, so without this the pin stayed on the old place.
	if _canvas != null:
		_canvas.set_lat_lon(lat, lon)
	_refresh_labels()

func _sync_from_fields() -> void:
	if _lat_field.text.is_valid_float() and _lon_field.text.is_valid_float():
		_lat = clampf(_lat_field.text.to_float(), -90, 90)
		_lon = clampf(_lon_field.text.to_float(), -180, 180)
		_canvas.set_lat_lon(_lat, _lon)
		_refresh_labels()

var selected_name := ""
var _searcher: SearchFetcher

func _ensure_searcher() -> void:
	if _searcher != null:
		return
	_searcher = SearchFetcher.new()
	add_child(_searcher)
	_searcher.succeeded.connect(func(n: String, la: float, lo: float) -> void:
		_on_picked(la, lo)
		selected_name = n
		_name_label.text = n)
	_searcher.failed.connect(func(reason: String) -> void:
		_name_label.text = reason)
	_searcher.suggestions_ready.connect(_on_suggestions_ready)

func _on_search_text_changed(text: String) -> void:
	var cleaned := text.strip_edges()
	if cleaned.length() < 2 or _looks_like_coordinates(cleaned):
		_suggest_timer.stop()
		_hide_suggestions()
		return
	# Instant on-device predictions first; remote ones refine the list
	# after a debounce pause, so typing does not hit the network per key.
	_show_suggestions(LocationData.suggestions_for(cleaned))
	_suggest_timer.start()

func _looks_like_coordinates(text: String) -> bool:
	if not text.contains(","):
		return false
	var parts := text.split(",")
	return parts.size() == 2 and parts[0].strip_edges().is_valid_float() \
		and parts[1].strip_edges().is_valid_float()

func _request_remote_suggestions() -> void:
	var cleaned := _search.text.strip_edges()
	if cleaned.length() < 2 or _looks_like_coordinates(cleaned):
		return
	_ensure_searcher()
	_searcher.suggest(cleaned)

func _on_suggestions_ready(query: String, results: Array) -> void:
	if query != _search.text.strip_edges().to_lower():
		return  # stale response for text the user has already changed
	if not results.is_empty():
		_show_suggestions(results)

func _show_suggestions(results: Array) -> void:
	for child in _suggest_list.get_children():
		child.queue_free()
	if results.is_empty():
		_suggest_panel.visible = false
		return
	for item in results.slice(0, 5):
		var name := str(item.get("name", ""))
		var lat := float(item.get("lat", 0.0))
		var lon := float(item.get("lon", 0.0))
		var row := Button.new()
		row.text = "📍  %s" % name
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size = Vector2(0, 48)
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", UiTheme.INK)
		row.add_theme_stylebox_override("normal", UiTheme.style(Color.TRANSPARENT, 10))
		row.add_theme_stylebox_override("hover", UiTheme.style(UiTheme.FIELD, 10))
		row.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.FIELD, 10))
		row.pressed.connect(func() -> void: _select_suggestion(name, lat, lon))
		_suggest_list.add_child(row)
	_suggest_panel.visible = true

func _hide_suggestions() -> void:
	if _suggest_panel != null:
		_suggest_panel.visible = false

func _select_suggestion(name: String, lat: float, lon: float) -> void:
	_hide_suggestions()
	_suggest_timer.stop()
	_search.set_block_signals(true)
	_search.text = name
	_search.set_block_signals(false)
	_on_picked(lat, lon)
	selected_name = name
	_name_label.text = name

func _on_search(text: String) -> void:
	var cleaned := text.strip_edges()
	if cleaned.contains(","):
		var parts := cleaned.split(",")
		if parts.size() == 2 and parts[0].strip_edges().is_valid_float() \
				and parts[1].strip_edges().is_valid_float():
			_on_picked(parts[0].strip_edges().to_float(),
				parts[1].strip_edges().to_float())
			return
	for place in LocationData.known_places():
		if cleaned.to_lower() == str(place["name"]).to_lower() \
				or str(place["name"]).to_lower().begins_with(cleaned.to_lower()):
			_select_suggestion(str(place["name"]), float(place["lat"]), float(place["lon"]))
			return
	_ensure_searcher()
	_searcher.search(cleaned)

func _refresh_labels() -> void:
	_name_label.text = selected_name if selected_name != "" \
		else LocationData.known_place(_lat, _lon)
	_coord_label.text = "%.4f° N, %.4f° E" % [_lat, _lon] \
		if _lat >= 0 and _lon >= 0 else "%.4f°, %.4f°" % [_lat, _lon]
