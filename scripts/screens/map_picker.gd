class_name MapPicker
extends Control

signal render_requested(lat: float, lon: float)
signal history_requested
signal settings_requested
signal download_requested(lat: float, lon: float)
signal exit_requested
signal palette_changed(index: int)

var _lat := 48.8566
var _lon := 2.3522
var _canvas: MapTileView
var _coord_label: Label
var _name_label: Label
var _lat_field: LineEdit
var _lon_field: LineEdit

# Night Atlas layout: the map is full-bleed behind everything and the
# controls float over it as glass. Compact and medium use a top bar
# plus a bottom sheet (one column on phones, two on tablets); expanded
# uses a floating side panel and a top-right nav pill.
var _overlay: MarginContainer
var _stack: VBoxContainer
var _split: HBoxContainer
var _top_col: VBoxContainer
var _top_row: HBoxContainer
var _stack_gap: Control
var _right_col: VBoxContainer
var _side: PanelContainer
var _side_col: VBoxContainer
var _sheet: PanelContainer
var _sheet_cols: BoxContainer
var _info_col: VBoxContainer
var _action_col: VBoxContainer
var _brand: HBoxContainer
var _brand_pill: PanelContainer
var _nav: PanelContainer
var _search: LineEdit
var _search_box: VBoxContainer
var _suggest_panel: PanelContainer
var _suggest_list: VBoxContainer
var _suggest_timer: Timer
var _map_wrap: Control
var _zoom_rail: PanelContainer
var _history_btn: Button
var _settings_btn: Button
var _download_btn: Button
var _exit_btn: Button
var _tip: Label
var _quality_label: Label
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
var _quick_chips: Array[Button] = []
var _selected_quick := -1
var _forced_layout := -1  # -1 = Auto, else Responsive.Layout value
var _current_layout: int = Responsive.Layout.COMPACT
var _focus_queued := false

## Container that never eats clicks: the map underneath must stay
## draggable in every gap between floating controls.
func _passive(node: Control) -> Control:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.color = UiTheme.BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# Map: full-bleed, behind every control.
	_map_wrap = Control.new()
	_map_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_map_wrap)
	_canvas = MapTileView.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.picked.connect(_on_picked)
	_map_wrap.add_child(_canvas)
	_zoom_out_btn = UiTheme.rail_button("−", "Zoom out", 24)
	_zoom_out_btn.pressed.connect(func() -> void: _canvas.zoom_out())
	_zoom_in_btn = UiTheme.rail_button("+", "Zoom in", 24)
	_zoom_in_btn.pressed.connect(func() -> void: _canvas.zoom_in())
	_zoom_rail = UiTheme.rail([_zoom_in_btn, _zoom_out_btn], true)
	_zoom_rail.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_zoom_rail.anchor_top = 0.40
	_zoom_rail.anchor_bottom = 0.40
	_zoom_rail.grow_vertical = Control.GROW_DIRECTION_BOTH
	_zoom_rail.offset_left = -64
	_zoom_rail.offset_right = -16
	_map_wrap.add_child(_zoom_rail)

	_overlay = MarginContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_passive(_overlay)
	add_child(_overlay)
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 10)
	_passive(_stack)
	_overlay.add_child(_stack)
	_split = HBoxContainer.new()
	_split.add_theme_constant_override("separation", 16)
	_split.visible = false
	_passive(_split)
	_overlay.add_child(_split)

	# Brand: shown in the side panel and as a pill on tablets.
	_brand = HBoxContainer.new()
	_brand.add_theme_constant_override("separation", 12)
	var logo := UiTheme.label("◉", 22, UiTheme.TEAL)
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_brand.add_child(logo)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label = UiTheme.label("Planet Render 360", 22, UiTheme.INK, true)
	title_box.add_child(_title_label)
	_tagline_label = UiTheme.label("Stand anywhere on Earth. Look around.", 14, UiTheme.MUTED)
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(_tagline_label)
	_brand.add_child(title_box)
	# Glass pill on tablets (floats over the map); bare in the side panel.
	_brand_pill = PanelContainer.new()
	_brand_pill.add_child(_brand)

	# Nav: icon-only History / Settings / Exit. The app starts full
	# screen, so it needs its own way out, always visible on the home
	# screen.
	_history_btn = UiTheme.rail_button("◷", "History & saved places")
	_history_btn.pressed.connect(func() -> void: history_requested.emit())
	_settings_btn = UiTheme.rail_button("⚙", "Settings")
	_settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	_exit_btn = UiTheme.rail_button("✕", "Exit the app")
	_exit_btn.pressed.connect(func() -> void: exit_requested.emit())
	_nav = UiTheme.rail([_history_btn, _settings_btn, _exit_btn])
	_nav.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# Layout + accent choices: each OptionButton keeps its full
	# minimum width instead of squeezing the sheet.
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
		_theme_btn.add_item("Accent: %s" % UiTheme.theme_names[i], i)
	_theme_btn.select(UiTheme.theme_index)
	_theme_btn.custom_minimum_size = Vector2(150, 44)
	_theme_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_theme_btn.add_theme_font_size_override("font_size", 14)
	UiTheme.apply_option(_theme_btn)
	_theme_btn.item_selected.connect(_on_theme_selected)
	_options_row.add_child(_theme_btn)

	_search_box = VBoxContainer.new()
	_search_box.add_theme_constant_override("separation", 6)
	_search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search = UiTheme.field("Search a place — try “Banff”")
	_search.text_submitted.connect(func(t: String) -> void:
		_hide_suggestions()
		_on_search(t))
	_search.text_changed.connect(_on_search_text_changed)
	_search_box.add_child(_search)
	_suggest_panel = PanelContainer.new()
	_suggest_panel.visible = false
	_suggest_panel.add_theme_stylebox_override("panel", _suggest_style())
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
	_quick_box.add_theme_constant_override("separation", 8)
	_quick_label = UiTheme.section_label("Quick picks")
	_quick_box.add_child(_quick_label)
	var quick_row := GridContainer.new()
	quick_row.columns = 3
	quick_row.add_theme_constant_override("h_separation", 8)
	quick_row.add_theme_constant_override("v_separation", 8)
	_quick_box.add_child(quick_row)
	var quicks: Array = LocationData.quick_picks()
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

	# Selected place: info column (name, coordinates) and action column
	# (render, offline, options, footer). Side by side on tablets.
	_sheet_cols = BoxContainer.new()
	_sheet_cols.add_theme_constant_override("separation", 20)
	_info_col = VBoxContainer.new()
	_info_col.add_theme_constant_override("separation", 10)
	_info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_cols.add_child(_info_col)
	_action_col = VBoxContainer.new()
	_action_col.add_theme_constant_override("separation", 10)
	_action_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_cols.add_child(_action_col)
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 8)
	_info_col.add_child(head_row)
	_selected_label = UiTheme.section_label("Selected place")
	_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(_selected_label)
	_ready_label = UiTheme.label("● Ready", 13, UiTheme.TEAL, true)
	head_row.add_child(_ready_label)
	_name_label = UiTheme.label("Paris, France", 26, UiTheme.INK, true)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_col.add_child(_name_label)
	_coord_label = UiTheme.label("", 15, UiTheme.MUTED)
	_info_col.add_child(_coord_label)
	_coords_label = UiTheme.section_label("Coordinates — or tap the map")
	_info_col.add_child(_coords_label)
	var fields := HBoxContainer.new()
	fields.add_theme_constant_override("separation", 10)
	_info_col.add_child(fields)
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
	_render_btn = UiTheme.primary_button("Render in 360°  →")
	_render_btn.pressed.connect(func() -> void: render_requested.emit(_lat, _lon))
	_action_col.add_child(_render_btn)
	_download_btn = UiTheme.ghost_button("⬇  Save for offline")
	_download_btn.custom_minimum_size = Vector2(0, 48)
	_download_btn.pressed.connect(func() -> void: download_requested.emit(_lat, _lon))
	_action_col.add_child(_download_btn)
	_action_col.add_child(_options_row)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	_action_col.add_child(footer)
	_tip = UiTheme.label("Tap the map to drop the pin · © OpenStreetMap contributors", 12, UiTheme.MUTED)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_tip)
	_quality_label = UiTheme.label("High", 12, UiTheme.MUTED)
	_quality_label.size_flags_vertical = Control.SIZE_SHRINK_END
	footer.add_child(_quality_label)

	# Bottom sheet (compact / medium) and side panel (expanded).
	_sheet = PanelContainer.new()
	_sheet.add_theme_stylebox_override("panel", UiTheme.glass_panel(28))
	_side = PanelContainer.new()
	_side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_side.add_theme_stylebox_override("panel", _side_style())
	_side_col = VBoxContainer.new()
	_side_col.add_theme_constant_override("separation", 16)
	_side.add_child(_side_col)
	_top_col = VBoxContainer.new()
	_top_col.add_theme_constant_override("separation", 10)
	_passive(_top_col)
	_top_row = HBoxContainer.new()
	_top_row.add_theme_constant_override("separation", 10)
	_passive(_top_row)
	_top_col.add_child(_top_row)
	_stack_gap = Control.new()
	_stack_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_passive(_stack_gap)
	_right_col = VBoxContainer.new()
	_right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_passive(_right_col)

	resized.connect(_on_resized)
	for node in [_sheet, _side, _top_col]:
		node.resized.connect(_queue_focus_update)
	_apply_layout(Responsive.layout_for_width(size.x))
	_refresh_labels()


# --- Delegators: implementation in MapChrome. ---
func _side_style() -> StyleBoxFlat:
	return MapChrome._side_style(self)

func _suggest_style() -> StyleBoxFlat:
	return MapChrome._suggest_style(self)

func _on_resized() -> void:
	MapChrome._on_resized(self)

func _on_layout_selected(index: int) -> void:
	MapChrome._on_layout_selected(self, index)

func _on_theme_selected(index: int) -> void:
	MapChrome._on_theme_selected(self, index)

func _apply_theme() -> void:
	MapChrome._apply_theme(self)

func _set_selected_quick(index: int) -> void:
	MapChrome._set_selected_quick(self, index)

func set_download_status(text: String) -> void:
	MapChrome.set_download_status(self, text)

func set_quality_preset(preset_value: int) -> void:
	MapChrome.set_quality_preset(self, preset_value)

func effective_layout() -> int:
	return MapChrome.effective_layout(self)

func _move(node: Control, parent: Node) -> void:
	MapChrome._move(self, node, parent)

func _move_all(nodes: Array, parent: Node) -> void:
	MapChrome._move_all(self, nodes, parent)

func _apply_layout(layout: Responsive.Layout) -> void:
	MapChrome._apply_layout(self, layout)

func _queue_focus_update() -> void:
	MapChrome._queue_focus_update(self)

func _update_focus() -> void:
	MapChrome._update_focus(self)

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
	row.add_theme_color_override("font_hover_color", UiTheme.ON_ACCENT)
	row.add_theme_color_override("font_pressed_color", UiTheme.ON_ACCENT)
	row.add_theme_color_override("font_focus_color", UiTheme.INK)
	row.add_theme_stylebox_override("normal", UiTheme.style(Color.TRANSPARENT, 10))
	row.add_theme_stylebox_override("hover", UiTheme.style(UiTheme.TEAL, 10))
	row.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.TEAL, 10))
	row.add_theme_stylebox_override("focus", UiTheme.style(Color.TRANSPARENT, 10, UiTheme.TEAL))

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
