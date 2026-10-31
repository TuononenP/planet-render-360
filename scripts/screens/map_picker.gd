class_name MapPicker
extends Control

## The map home (design system: MapHome). The map is full-bleed; one
## glass surface holds everything you act on: brand, search, the
## selected place, Explore, and an "Around the world" shelf. Wide
## windows get a left side panel, phones and tablets a bottom sheet
## under a floating search bar. Layout moves live in MapChrome.

signal render_requested(lat: float, lon: float)
signal history_requested
signal settings_requested
signal download_requested(lat: float, lon: float)
signal exit_requested

var _lat := 48.8566
var _lon := 2.3522
var _canvas: MapTileView
var _coord_label: Label
var _name_label: Label
var _region_label: Label

# The map is full-bleed behind everything and the controls float over
# it as glass. Compact and medium use a top bar plus a bottom sheet
# (one column on phones, two on tablets); expanded uses a side panel.
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
var _sheet_body: VBoxContainer
var _sheet_cols: BoxContainer
var _info_col: VBoxContainer
var _action_col: VBoxContainer
var _btn_row: BoxContainer
var _footer: HBoxContainer
var _brand: HBoxContainer
var _brand_pill: PanelContainer
var _wordmark: TextureRect
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
var _download_status: Label
var _tip: Label
var _quality_label: Label
var _quick_box: VBoxContainer
var _quick_scroll: ScrollContainer
var _quick_grid: GridContainer
var _coords_label: Label
var _coords_box: MarginContainer
var _bg: ColorRect
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
var selected_name := ""
var _searcher: SearchFetcher

## Container that never eats clicks: the map underneath must stay
## draggable in every gap between floating controls.
func _passive(node: Control) -> Control:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _vbox(sep: int, flags: int = Control.SIZE_FILL) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.size_flags_horizontal = flags
	return v

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
	_zoom_in_btn = UiIcon.button("plus", "Zoom in")
	_zoom_in_btn.pressed.connect(func() -> void: _canvas.zoom_in())
	_zoom_out_btn = UiIcon.button("minus", "Zoom out")
	_zoom_out_btn.pressed.connect(func() -> void: _canvas.zoom_out())
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

	# Brand: the horizontal wordmark from the design system, in the side
	# panel (with the nav icons) and as a pill on tablets.
	_brand = HBoxContainer.new()
	_brand.add_theme_constant_override("separation", 8)
	_wordmark = Brand.rect(Brand.WORDMARK, 36)
	_wordmark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_brand.add_child(_wordmark)
	var brand_gap := Control.new()
	brand_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_passive(brand_gap)
	_brand.add_child(brand_gap)
	_brand_pill = PanelContainer.new()
	_brand_pill.add_child(_brand)

	# Nav: icon-only History / Settings / Exit. The app starts full
	# screen, so it needs its own way out, always visible on the home
	# screen.
	_history_btn = UiIcon.button("history", "History & saved places")
	_history_btn.pressed.connect(func() -> void: history_requested.emit())
	_settings_btn = UiIcon.button("settings", "Settings")
	_settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	_exit_btn = UiIcon.button("x", "Exit the app")
	_exit_btn.pressed.connect(func() -> void: exit_requested.emit())
	_nav = UiTheme.rail([_history_btn, _settings_btn, _exit_btn])
	_nav.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_search_box = _vbox(6, Control.SIZE_EXPAND_FILL)
	_search = UiTheme.search_field("Search places or coordinates")
	_search.clear_button_enabled = true
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

	# Around the world: one tap to a wow place, no typing first run.
	# A shelf of small cards: a sideways rail on phones and tablets,
	# a scrolling 3-column grid in the side panel.
	_quick_box = _vbox(8)
	_quick_label = UiTheme.section_label("Around the world")
	_quick_box.add_child(_quick_label)
	_quick_scroll = ScrollContainer.new()
	_quick_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTheme.apply_scroll(_quick_scroll)
	_quick_box.add_child(_quick_scroll)
	_quick_grid = GridContainer.new()
	_quick_grid.add_theme_constant_override("h_separation", 8)
	_quick_grid.add_theme_constant_override("v_separation", 8)
	_quick_scroll.add_child(_quick_grid)
	var quicks: Array = LocationData.quick_picks()
	for qi in quicks.size():
		var quick: Array = quicks[qi]
		var card := PlaceCard.make(str(quick[0]))
		var qname := str(quick[1])
		var qlat := float(quick[2])
		var qlon := float(quick[3])
		var qindex := qi
		card.pressed.connect(func() -> void:
			_select_suggestion(qname, qlat, qlon)
			_set_selected_quick(qindex))
		_quick_chips.append(card)
		_quick_grid.add_child(card)
	# Paris is the starting place, so its card starts out selected.
	_set_selected_quick(0)

	# Selected place: info column (name, coordinates) and action column
	# (Explore, offline). Side by side on tablets.
	_sheet_cols = BoxContainer.new()
	_sheet_cols.add_theme_constant_override("separation", 20)
	_info_col = _vbox(2, Control.SIZE_EXPAND_FILL)
	_sheet_cols.add_child(_info_col)
	_action_col = _vbox(8, Control.SIZE_EXPAND_FILL)
	_action_col.size_flags_vertical = Control.SIZE_SHRINK_END
	_sheet_cols.add_child(_action_col)
	_selected_label = UiTheme.section_label("Selected place")
	_info_col.add_child(_selected_label)
	_name_label = UiTheme.display_label("Paris", 36)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_col.add_child(_name_label)
	_region_label = UiTheme.label("France", 14, UiTheme.MUTED)
	_info_col.add_child(_region_label)
	_coords_box = MarginContainer.new()
	_coords_box.add_theme_constant_override("margin_top", 10)
	_info_col.add_child(_coords_box)
	var coords_col := _vbox(2)
	_coords_box.add_child(coords_col)
	_coords_label = UiTheme.section_label("Coordinates")
	coords_col.add_child(_coords_label)
	_coord_label = UiTheme.data_label("", 15, UiTheme.INK)
	coords_col.add_child(_coord_label)
	_btn_row = BoxContainer.new()
	_btn_row.add_theme_constant_override("separation", 8)
	_action_col.add_child(_btn_row)
	_render_btn = UiTheme.primary_button("Explore in 360°")
	_render_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiIcon.apply(_render_btn, "globe", 22, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	_render_btn.pressed.connect(func() -> void: render_requested.emit(_lat, _lon))
	_btn_row.add_child(_render_btn)
	_download_btn = UiTheme.ghost_button("Save for offline")
	_download_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiIcon.apply(_download_btn, "hard-drive", 20)
	_download_btn.tooltip_text = "Save for offline"
	_download_btn.pressed.connect(func() -> void: download_requested.emit(_lat, _lon))
	_btn_row.add_child(_download_btn)
	_download_status = UiTheme.label("", 12, UiTheme.MUTED)
	_download_status.visible = false
	_action_col.add_child(_download_status)
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 8)
	_tip = UiTheme.label("© OpenStreetMap contributors · OpenFreeMap", 12, UiTheme.MUTED)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(_tip)
	_quality_label = UiTheme.label("High", 12, UiTheme.MUTED)
	_quality_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_footer.add_child(_quality_label)

	# Bottom sheet (compact / medium) and side panel (expanded).
	_sheet = PanelContainer.new()
	_sheet.add_theme_stylebox_override("panel", UiTheme.glass_panel())
	_sheet_body = _vbox(14)
	_sheet.add_child(_sheet_body)
	_side = PanelContainer.new()
	_side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_side.add_theme_stylebox_override("panel", _side_style())
	_side_col = _vbox(16)
	_side.add_child(_side_col)
	_top_col = _vbox(10)
	_passive(_top_col)
	_top_row = HBoxContainer.new()
	_top_row.add_theme_constant_override("separation", 10)
	_passive(_top_row)
	_top_col.add_child(_top_row)
	_stack_gap = Control.new()
	_stack_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_passive(_stack_gap)
	_right_col = _vbox(0, Control.SIZE_EXPAND_FILL)
	_passive(_right_col)

	resized.connect(_on_resized)
	for node in [_sheet, _side, _top_col]:
		node.resized.connect(_queue_focus_update)
	_apply_layout(Responsive.layout_for_width(size.x))
	_refresh_labels()


# --- Delegators: implementation in MapChrome / MapSearch. ---
func _side_style() -> StyleBoxFlat:
	return MapChrome._side_style(self)

func _suggest_style() -> StyleBoxFlat:
	return MapChrome._suggest_style(self)

func _on_resized() -> void:
	MapChrome._on_resized(self)

func _on_layout_selected(index: int) -> void:
	MapChrome._on_layout_selected(self, index)

## Settings → Appearance: 0 Auto, 1 Compact, 2 Wide.
func set_layout_override(index: int) -> void:
	MapChrome._on_layout_selected(self, index)

## Re-skin every control after an accent change (see UiTheme.apply_palette).
func refresh_theme() -> void:
	MapChrome._apply_theme(self)

func _set_selected_quick(index: int) -> void:
	MapChrome._set_selected_quick(self, index)

func set_download_status(text: String) -> void:
	MapChrome.set_download_status(self, text)

## `finishing`: a cancelled scene is still winding down, so say so.
func set_render_busy(busy: bool, finishing: bool = false) -> void:
	MapChrome.set_render_busy(self, busy, finishing)

func set_download_busy(busy: bool) -> void:
	MapChrome.set_download_busy(self, busy)

func set_quality_preset(preset_value: int) -> void:
	MapChrome.set_quality_preset(self, preset_value)

func effective_layout() -> int:
	return MapChrome.effective_layout(self)

func _apply_layout(layout: Responsive.Layout) -> void:
	MapChrome._apply_layout(self, layout)

func _queue_focus_update() -> void:
	MapChrome._queue_focus_update(self)

func _update_focus() -> void:
	MapChrome._update_focus(self)

func _on_search_text_changed(text: String) -> void:
	MapSearch.on_text_changed(self, text)

func _request_remote_suggestions() -> void:
	MapSearch.request_remote(self)

func _hide_suggestions() -> void:
	MapSearch.hide_suggestions(self)

func _select_suggestion(place: String, lat: float, lon: float) -> void:
	MapSearch.select(self, place, lat, lon)

func _on_search(text: String) -> void:
	MapSearch.submit(self, text)

func _ensure_searcher() -> void:
	MapSearch.ensure_searcher(self)

func _on_picked(lat: float, lon: float) -> void:
	_hide_suggestions()
	_set_selected_quick(-1)
	selected_name = ""
	_lat = lat
	_lon = lon
	# Keep the map centred on the choice: search and quick picks arrive
	# without a map tap, so without this the pin stayed on the old place.
	if _canvas != null:
		_canvas.set_lat_lon(lat, lon)
	_refresh_labels()
	AccentSun.follow_now(lat, lon)

## The selected point, for the Auto accent when no scene is up.
func selected_point() -> Vector2:
	return Vector2(_lat, _lon)

## Name over region ("Venice" / "Italy"), coordinates as an instrument
## readout. Search results and failures arrive as plain text.
func _show_place(full_name: String) -> void:
	var parts := UiTheme.split_place(full_name)
	_name_label.text = parts[0]
	_region_label.text = parts[1]
	_region_label.visible = parts[1] != ""

func _refresh_labels() -> void:
	_show_place(selected_name if selected_name != "" \
		else LocationData.known_place(_lat, _lon))
	_coord_label.text = UiTheme.coords(_lat, _lon)
