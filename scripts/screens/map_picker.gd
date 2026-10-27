class_name MapPicker
extends Control

signal render_requested(lat: float, lon: float)
signal history_requested
signal settings_requested
signal exit_requested
signal palette_changed(index: int)

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
var _settings_btn: Button
var _exit_btn: Button
var _tip: Label
var _quick_box: VBoxContainer
var _ready_label: Label
var _coords_label: Label
var _layout_btn: OptionButton
var _theme_btn: OptionButton
var _options_row: HBoxContainer
var _bg: ColorRect
var _title_label: Label
var _tagline_label: Label
var _quick_label: Label
var _selected_label: Label
var _render_btn: Button
var _zoom_out_btn: Button
var _zoom_in_btn: Button
var _hint_pill: PanelContainer
var _quick_chips: Array[Button] = []
var _selected_quick := -1
var _forced_layout := -1  # -1 = Auto, else Responsive.Layout value
var _current_layout: int = Responsive.Layout.COMPACT

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.color = UiTheme.BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

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
	_title_label = UiTheme.label("◭  Planet Render 360", 27, UiTheme.INK, true)
	title_box.add_child(_title_label)
	_tagline_label = UiTheme.label("Stand anywhere on Earth — see it in 360°", 14, UiTheme.MUTED)
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(_tagline_label)
	_header.add_child(title_box)
	# The app starts full screen, so it needs its own way out: a clear
	# Exit in the header, always visible on the home screen.
	_exit_btn = UiTheme.ghost_button("✕  Exit")
	_exit_btn.tooltip_text = "Exit the app"
	_exit_btn.custom_minimum_size = Vector2(96, 48)
	_exit_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_exit_btn.pressed.connect(func() -> void: exit_requested.emit())
	_header.add_child(_exit_btn)

	# Layout + UI colour choices on their own row: each OptionButton
	# keeps its full minimum width instead of squeezing the title.
	_options_row = HBoxContainer.new()
	_options_row.add_theme_constant_override("separation", 8)
	_layout_btn = OptionButton.new()
	_layout_btn.add_item("Auto layout", 0)
	_layout_btn.add_item("Compact", 1)
	_layout_btn.add_item("Wide", 2)
	_layout_btn.custom_minimum_size = Vector2(118, 44)
	_layout_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layout_btn.add_theme_font_size_override("font_size", 14)
	UiTheme.apply_option(_layout_btn)
	_layout_btn.item_selected.connect(_on_layout_selected)
	_options_row.add_child(_layout_btn)
	_theme_btn = OptionButton.new()
	for i in UiTheme.theme_names.size():
		_theme_btn.add_item("UI colour: %s" % UiTheme.theme_names[i], i)
	_theme_btn.select(UiTheme.theme_index)
	_theme_btn.custom_minimum_size = Vector2(150, 44)
	_theme_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_theme_btn.add_theme_font_size_override("font_size", 14)
	UiTheme.apply_option(_theme_btn)
	_theme_btn.item_selected.connect(_on_theme_selected)
	_options_row.add_child(_theme_btn)

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
	_quick_label = UiTheme.section_label("Try a place — one tap")
	_quick_box.add_child(_quick_label)
	var quick_row := HBoxContainer.new()
	quick_row.add_theme_constant_override("separation", 8)
	_quick_box.add_child(quick_row)
	var quicks: Array = [
			["Paris", "Paris, France", 48.8566, 2.3522],
			["Alps", "Interlaken, Switzerland", 46.6863, 7.8632],
			["Banff", "Banff, Canada", 51.1789, -115.5708],
			["Big Sur", "Big Sur, United States", 36.2704, -121.8081],
			["Tokyo", "Tokyo, Japan", 35.6762, 139.6503]]
	for qi in quicks.size():
		var quick: Array = quicks[qi]
		var chip := UiTheme.chip_button(str(quick[0]))
		var qname := str(quick[1])
		var qlat := float(quick[2])
		var qlon := float(quick[3])
		var qindex := qi
		chip.pressed.connect(func() -> void:
			_select_suggestion(qname, qlat, qlon)
			_set_selected_quick(qindex))
		_quick_chips.append(chip)
		quick_row.add_child(chip)
	# Paris is the starting place, so its chip starts out selected.
	_set_selected_quick(0)

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
	_zoom_out_btn = UiTheme.icon_button("−")
	_zoom_out_btn.pressed.connect(func() -> void: _canvas.zoom_out())
	zoom_row.add_child(_zoom_out_btn)
	_zoom_in_btn = UiTheme.icon_button("+")
	_zoom_in_btn.pressed.connect(func() -> void: _canvas.zoom_in())
	zoom_row.add_child(_zoom_in_btn)
	# Hint pill floats on the map: guidance where the hand already is,
	# at no layout height cost on compact screens.
	_hint_pill = UiTheme.pill("Tap the map to drop the pin", 13)
	_hint_pill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint_pill.offset_left = 12
	_hint_pill.offset_top = -52
	_hint_pill.offset_right = 236
	_hint_pill.offset_bottom = -12
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_wrap.add_child(_hint_pill)
	_tip = _hint_pill.get_meta("label") as Label

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, 16, Color.TRANSPARENT, true))
	var card_col := VBoxContainer.new()
	card_col.add_theme_constant_override("separation", 10)
	_card.add_child(card_col)
	_selected_label = UiTheme.section_label("Selected place")
	card_col.add_child(_selected_label)
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
	_render_btn = UiTheme.primary_button("◭  Render this place in 360°")
	_render_btn.pressed.connect(func() -> void: render_requested.emit(_lat, _lon))
	card_col.add_child(_render_btn)

	_history_btn = UiTheme.ghost_button("◷  History & saved places")
	_history_btn.pressed.connect(func() -> void: history_requested.emit())

	_settings_btn = UiTheme.ghost_button("⚙  Settings — Balanced quality")
	_settings_btn.pressed.connect(func() -> void: settings_requested.emit())

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

func _on_theme_selected(index: int) -> void:
	UiTheme.apply_palette(index)
	_apply_theme()
	palette_changed.emit(index)

## Re-skin every picker control after a palette change. Factories read
## the palette at creation time, so existing controls need this pass.
func _apply_theme() -> void:
	if _bg != null:
		_bg.color = UiTheme.BG
	if _title_label != null:
		_title_label.add_theme_color_override("font_color", UiTheme.INK)
	if _tagline_label != null:
		_tagline_label.add_theme_color_override("font_color", UiTheme.MUTED)
	for section in [_quick_label, _selected_label, _coords_label]:
		if section != null:
			section.add_theme_color_override("font_color", UiTheme.MUTED)
	if _name_label != null:
		_name_label.add_theme_color_override("font_color", UiTheme.INK)
	if _coord_label != null:
		_coord_label.add_theme_color_override("font_color", UiTheme.MUTED)
	if _ready_label != null:
		_ready_label.add_theme_color_override("font_color", UiTheme.TEAL)
	if _layout_btn != null:
		UiTheme.apply_option(_layout_btn)
	if _theme_btn != null:
		UiTheme.apply_option(_theme_btn)
	if _search != null:
		UiTheme.apply_field(_search)
	if _lat_field != null:
		UiTheme.apply_field(_lat_field)
	if _lon_field != null:
		UiTheme.apply_field(_lon_field)
	if _suggest_panel != null:
		_suggest_panel.add_theme_stylebox_override("panel",
			UiTheme.style(UiTheme.CARD, 14, Color.TRANSPARENT, true))
	for child in _suggest_list.get_children():
		if child is Button:
			_style_suggestion_row(child as Button)
	if _card != null:
		_card.add_theme_stylebox_override("panel",
			UiTheme.style(UiTheme.CARD, 16, Color.TRANSPARENT, true))
	if _sidebar != null:
		_sidebar.add_theme_stylebox_override("panel",
			UiTheme.style(UiTheme.CARD, 18, Color.TRANSPARENT, true))
	if _render_btn != null:
		UiTheme.apply_primary(_render_btn)
	if _history_btn != null:
		UiTheme.apply_ghost(_history_btn)
	if _settings_btn != null:
		UiTheme.apply_ghost(_settings_btn)
	if _exit_btn != null:
		UiTheme.apply_ghost(_exit_btn)
	if _zoom_out_btn != null:
		UiTheme.apply_icon(_zoom_out_btn)
	if _zoom_in_btn != null:
		UiTheme.apply_icon(_zoom_in_btn)
	if _tip != null:
		_tip.add_theme_color_override("font_color", UiTheme.INK)
	_set_selected_quick(_selected_quick)

## Mark one quick pick as the active place (accent fill, pressed) and
## clear the rest. -1 clears all: the place no longer comes from a chip.
func _set_selected_quick(index: int) -> void:
	_selected_quick = index
	for i in _quick_chips.size():
		var chip := _quick_chips[i]
		chip.set_pressed_no_signal(i == index)
		UiTheme.apply_chip(chip, i == index)

## Shows the chosen preset on the settings entry point, so the current
## quality is visible before opening the menu.
func set_quality_preset(preset_value: int) -> void:
	if _settings_btn != null:
		_settings_btn.text = "⚙  Settings — %s quality" % RenderSettings.preset_name(preset_value)

func effective_layout() -> int:
	return _current_layout

func _move(node: Control, parent: Container) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	parent.add_child(node)

func _move_all(nodes: Array, parent: Container) -> void:
	for node in nodes:
		_move(node, parent)

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
		_move_all([_map_wrap, _sidebar], _split)
		_sidebar.custom_minimum_size = Vector2(Responsive.sidebar_width(layout), 0)
		_move_all([_header, _options_row, _search_box, _quick_box, _card, _history_btn, _settings_btn], _side_col)
	else:
		_split.visible = false
		_stack.visible = true
		_move_all([_header, _options_row, _search_box, _quick_box, _map_wrap, _card, _history_btn, _settings_btn], _stack)

func _on_picked(lat: float, lon: float) -> void:
	_hide_suggestions()
	_set_selected_quick(-1)
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
		_set_selected_quick(-1)
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

## Suggestion rows share the OptionButton lesson: explicit hover /
## pressed text colours, or the label goes near-invisible on hover.
func _style_suggestion_row(row: Button) -> void:
	row.add_theme_color_override("font_color", UiTheme.INK)
	row.add_theme_color_override("font_hover_color", UiTheme.INK)
	row.add_theme_color_override("font_pressed_color", UiTheme.INK)
	row.add_theme_color_override("font_focus_color", UiTheme.INK)
	row.add_theme_stylebox_override("normal", UiTheme.style(Color.TRANSPARENT, 10))
	row.add_theme_stylebox_override("hover", UiTheme.style(UiTheme.TEAL_SOFT, 10))
	row.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.TEAL_SOFT, 10))
	row.add_theme_stylebox_override("focus", UiTheme.style(Color.TRANSPARENT, 10, UiTheme.AMBER))

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
		_style_suggestion_row(row)
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
