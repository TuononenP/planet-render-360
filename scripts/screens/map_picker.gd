class_name MapPicker
extends Control

## The map home (design system: MapHome). The map is full-bleed; one
## glass surface holds everything you act on: brand, search, the
## selected place, Explore, and an "Around the world" shelf. Wide
## windows get a left side panel, phones and tablets a bottom sheet
## under a floating search bar. Layout moves live in MapChrome.

signal render_requested(lat: float, lon: float)
signal history_requested
signal gallery_requested
signal settings_requested
## A render quality was picked from the dropdown beside Explore.
signal quality_selected(preset: int)
signal download_requested(lat: float, lon: float)
signal exit_requested
## A pasted view link was opened: its ViewLink state (main renders it).
signal view_link_requested(state: Dictionary)

# Helsinki is the starting place (its quick pick starts selected), so
# the first Explore opens on its curated view.
var _lat := float(PresetViews.default_row()["lat"])
var _lon := float(PresetViews.default_row()["lon"])
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
var _side_scroll: ScrollContainer
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
var _map_wrap: Control
var _zoom_rail: PanelContainer
var _history_btn: Button
var _gallery_btn: Button
var _settings_btn: Button
var _download_btn: Button
var _exit_btn: Button
var _download_status: Label
var _download_bar: ProgressBar
var _download_phase: Label
## Last Explore outcome (a timeout); separate from the download line so
## neither overwrites the other.
var _render_status: Label
var _tip: Label
var _quality_hint: Label
var _quality_title: Label
var _quality_bar: SegmentedControl
var _quality_box: VBoxContainer
var _quality := 2  # RenderSettings.Preset of the footer label (cache keys follow it)
var _cached_chip: HBoxContainer
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
var _quick_places: Array = []
## Continent key of each quick pick, by its index in _quick_places.
var _quick_continents: Array[String] = []
## Built cards by quick-pick index: a continent's cards are built when it is
## first opened, so the shelf can hold them in any order.
var _quick_by_index := {}
var _continent_filter: ContinentFilter
var _shelf_key := CapitalContinents.FEATURED
## Bumped on every shelf change so a build that was left behind stops.
var _shelf_build := 0
var _selected_quick := -1
var _forced_layout := -1  # -1 = Auto, else Responsive.Layout value
var _current_layout: int = Responsive.Layout.COMPACT
var _focus_queued := false
var selected_name := ""
## The landmark a marker tap selected (LandmarkVisit site), {} for none.
## Explore renders from its standoff, facing it.
var selected_landmark: Dictionary = {}
# Landmark markers and details (MapLandmarkHome).
var _wiki: WikiFetcher
var _landmark_timer: Timer
var _landmark_key := ""
var _landmark_card: LandmarkCard
var _landmark_box: MarginContainer
var _searcher: SearchFetcher
var _search_busy: TextureRect
var _search_busy_timer: Timer
var _search_busy_tween: Tween
# Selected place's real data (MapFacts), search modes (MapSearch) and
# home states (MapHome).
var _facts_fetcher: WeatherFetcher
var _facts_timer: Timer
var _facts_box: MarginContainer
var _elev_readout: Readout
var _time_readout: Readout
var _weather_readout: Readout
var _facts_offset_s := -1
var _mode_btn: Button
var _coord_mode := false
var _store: CacheStore
var _recent_box: VBoxContainer
var _recent_row: HBoxContainer
var _first_note: Label
var _offline_badge: Button
var _offline := false
var _toast: Toast
var _globe: GlobeView
var _globe_btn: Button
var _collapse_btn: Button
var _side_rail: VBoxContainer
# Pinned Explore bars, shown while Explore is scrolled out of sight.
var _side_explore: Button
var _sheet_explore: Button
var _side_collapsed := false
# Phone sheet detents (MapSheet).
var _grabber: Control
var _sheet_scroll: ScrollContainer
var _scrim: ColorRect
var _detent: int = MapSheet.Detent.HALF
var _sheet_tween: Tween
var _drag := {}

## Container that never eats clicks: the map underneath must stay
## draggable in every gap between floating controls.
func _passive(node: Control) -> Control:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

## The glass panels and the scroll areas in them pass zoom input to the map
## under them (MapTileView.panel_zoom_input); their taps stay with them.
## With `scroll_zooms` off (the side panel) the wheel and trackpad scroll
## stay with the panel; only pinches reach the map.
func _wire_zoom(node: Control, scroll_zooms := true) -> void:
	if node is PanelContainer or node is ScrollContainer:
		node.gui_input.connect(func(event: InputEvent) -> void:
			if not scroll_zooms and (event is InputEventMouseButton or event is InputEventPanGesture):
				return
			_canvas.panel_zoom_input(event, node))
	for child in node.get_children():
		if child is Control:
			_wire_zoom(child as Control, scroll_zooms)

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
	# A tap or drag on the map is not a new destination: no zoom warm-up.
	_canvas.picked.connect(func(la: float, lo: float) -> void: _on_picked(la, lo, false))
	_map_wrap.add_child(_canvas)
	_canvas.set_lat_lon(_lat, _lon)
	_zoom_in_btn = UiIcon.button("plus", "Zoom in")
	_zoom_in_btn.pressed.connect(func() -> void:
		if MapHome.globe_shown(self):
			MapHome.show_globe(self, false)
		else:
			_canvas.zoom_in())
	_zoom_out_btn = UiIcon.button("minus", "Zoom out")
	_zoom_out_btn.pressed.connect(func() -> void: _canvas.zoom_out())
	# Globe / flat: the map offers the globe below its widest zoom.
	_globe_btn = UiIcon.button("globe", "Globe")
	_globe_btn.pressed.connect(func() -> void:
		MapHome.show_globe(self, not MapHome.globe_shown(self)))
	_zoom_rail = UiTheme.rail([_zoom_in_btn, _zoom_out_btn, _globe_btn], true)
	_zoom_rail.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_zoom_rail.anchor_top = 0.40
	_zoom_rail.anchor_bottom = 0.40
	_zoom_rail.grow_vertical = Control.GROW_DIRECTION_BOTH
	_zoom_rail.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # wider than 48: keep the gutter
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
	_wordmark = Brand.rect(Brand.wordmark(), 36)
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
	_gallery_btn = UiIcon.button("rotate-3d", "Gallery: saved 360° photos")
	_gallery_btn.pressed.connect(func() -> void: gallery_requested.emit())
	_settings_btn = UiIcon.button("settings", "Settings")
	_settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	_exit_btn = UiIcon.button("x", "Exit the app")
	_exit_btn.pressed.connect(func() -> void: exit_requested.emit())
	_nav = UiTheme.rail([_history_btn, _gallery_btn, _settings_btn, _exit_btn])
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

	# Around the world: one tap to a wow place, no typing first run.
	# A shelf of small cards: a sideways rail on phones and tablets,
	# a scrolling 3-column grid in the side panel.
	_quick_box = _vbox(8)
	_quick_label = UiTheme.section_label("Around the world")
	_quick_box.add_child(_quick_label)
	_continent_filter = ContinentFilter.new()
	_continent_filter.selected.connect(_set_shelf)
	_quick_box.add_child(_continent_filter)
	_quick_scroll = ScrollContainer.new()
	_quick_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTheme.apply_scroll(_quick_scroll)
	_quick_box.add_child(_quick_scroll)
	_quick_grid = GridContainer.new()
	_quick_grid.add_theme_constant_override("h_separation", 8)
	_quick_grid.add_theme_constant_override("v_separation", 8)
	_quick_scroll.add_child(_quick_grid)
	_quick_places = LocationData.quick_picks()
	for place in _quick_places:
		_quick_continents.append(CapitalContinents.of_place(str(place[1])))
	_continent_filter.set_available(_quick_continents)
	for qi in PresetViews.ROWS.size():
		_add_quick_card(qi)
	# Helsinki is the starting place, so its card starts out selected.
	_set_selected_quick(PresetViews.default_index())

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
	_name_label = UiTheme.display_label("Helsinki", 36)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_col.add_child(_name_label)
	_region_label = UiTheme.label("Finland", 14, UiTheme.MUTED)
	_info_col.add_child(_region_label)
	_cached_chip = MapChrome.make_cached_chip()
	_info_col.add_child(_cached_chip)
	_coords_box = MarginContainer.new()
	_coords_box.add_theme_constant_override("margin_top", 10)
	_info_col.add_child(_coords_box)
	var coords_col := _vbox(2)
	_coords_box.add_child(coords_col)
	_coords_label = UiTheme.section_label("Coordinates")
	coords_col.add_child(_coords_label)
	_coord_label = UiTheme.data_label("", 15, UiTheme.INK)
	coords_col.add_child(_coord_label)
	MapFacts.build(self)
	_info_col.add_child(_facts_box)
	MapLandmarkHome.build(self)
	MapChrome.build_quality_bar(self, _action_col)
	_btn_row = BoxContainer.new()
	_btn_row.add_theme_constant_override("separation", 8)
	_action_col.add_child(_btn_row)
	_render_btn = UiTheme.primary_button("Explore in 360°")
	_render_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiIcon.apply(_render_btn, "globe", 22, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	_render_btn.pressed.connect(func() -> void: render_requested.emit(_lat, _lon))
	var explore_row := HBoxContainer.new()
	explore_row.add_theme_constant_override("separation", 6)
	_btn_row.add_child(explore_row)
	explore_row.add_child(_render_btn)
	_download_btn = UiTheme.ghost_button("Save for offline")
	_download_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiIcon.apply(_download_btn, "hard-drive", 20)
	_download_btn.tooltip_text = "Save for offline"
	_download_btn.pressed.connect(func() -> void: download_requested.emit(_lat, _lon))
	_btn_row.add_child(_download_btn)
	_download_status = UiTheme.text("", "body-s", UiTheme.MUTED)
	_download_status.visible = false
	_action_col.add_child(_download_status)
	_download_bar = ProgressBar.new()
	_download_bar.show_percentage = false
	_download_bar.custom_minimum_size = Vector2(0, 4)
	_download_bar.visible = false
	_action_col.add_child(_download_bar)
	_download_phase = UiTheme.text("", "body-s", UiTheme.MUTED)
	_download_phase.visible = false
	_action_col.add_child(_download_phase)
	MapChrome.style_download_bar(self)
	_render_status = UiTheme.text("", "body-s", UiTheme.MUTED)
	_render_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_render_status.visible = false
	_action_col.add_child(_render_status)
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 8)
	_tip = UiTheme.label("© OpenStreetMap contributors · © OpenMapTiles · OpenFreeMap · Terrain: AWS Terrain Tiles", 12, UiTheme.MUTED)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(_tip)

	# Bottom sheet (compact / medium) and side panel (expanded).
	_sheet = PanelContainer.new()
	_sheet.add_theme_stylebox_override("panel", UiTheme.glass_panel())
	_sheet_body = _vbox(14)
	_sheet.add_child(_sheet_body)
	_side = PanelContainer.new()
	_side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_side.add_theme_stylebox_override("panel", _side_style())
	# Scrolls when the window is too short for it (a phone on its side).
	_side_scroll = ScrollContainer.new()
	_side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	UiTheme.apply_scroll(_side_scroll)
	_side.add_child(_side_scroll)
	_side_col = _vbox(16, Control.SIZE_EXPAND_FILL)
	_side_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_scroll.add_child(_side_col)
	UiTheme.add_sheen(_sheet, UiTheme.RADIUS_XL)
	UiTheme.add_sheen(_side, UiTheme.RADIUS_L)
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

	MapSearch.build_mode_toggle(self)
	MapHome.build(self)
	MapSheet.build(self)
	MapHome.build_explore_bars(self)
	MapHome.build_globe(self)
	MapHome.build_rail(self)
	_quick_box.add_child(_recent_box)
	_quick_box.move_child(_recent_box, 0)
	_quick_box.add_child(_first_note)
	_quick_box.move_child(_first_note, 2)
	_wire_zoom(_sheet)
	_wire_zoom(_side, false)
	resized.connect(_on_resized)
	for node in [_sheet, _side, _top_col]:
		node.resized.connect(_queue_focus_update)
	_apply_layout(Responsive.layout_for_width(size.x))
	_refresh_labels()
	MapHome.refresh_recent(self)
	MapFacts.request(self)


# --- Delegators: implementation in MapChrome / MapSearch. ---
func _side_style() -> StyleBoxFlat:
	return MapChrome._side_style(self)

func _suggest_style() -> StyleBoxFlat:
	return MapChrome._suggest_style(self)

func _on_resized() -> void:
	MapChrome._on_resized(self)
	if _toast != null:
		MapHome.apply_offline(self)
		MapHome.place_toast(self)

## History for the Recent places rail and the first-launch state.
func bind_store(store: CacheStore) -> void:
	_store = store
	MapHome.refresh_recent(self)

func refresh_recent() -> void:
	MapHome.refresh_recent(self)

## Settings → Units: reformat coordinates and the place's readouts.
func refresh_units() -> void:
	_refresh_labels()
	MapFacts.request(self)

func set_offline(on: bool) -> void:
	MapHome.set_offline(self, on)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and is_visible_in_tree() \
			and MapHome.handle_key(self, key):
		get_viewport().set_input_as_handled()

func _on_layout_selected(index: int) -> void:
	MapChrome._on_layout_selected(self, index)

## Settings → Appearance: 0 Auto, 1 Compact, 2 Wide.
func set_layout_override(index: int) -> void:
	MapChrome._on_layout_selected(self, index)

## Re-skin every control after an accent change (see UiTheme.apply_palette).
func refresh_theme() -> void:
	MapChrome._apply_theme(self)
	MapSearch.set_coord_mode(self, _coord_mode)

func _add_quick_card(qi: int) -> void:
	var quick: Array = _quick_places[qi]
	var qname := str(quick[1])
	# "Paris, France" -> the country under the name; a single-word name
	# (Monaco) is its own country and keeps an empty line.
	var card := PlaceCard.make(str(quick[0]), 56, UiTheme.split_place(qname)[1])
	var qlat := float(quick[2])
	var qlon := float(quick[3])
	card.set_meta("lat", qlat)
	card.set_meta("lon", qlon)
	card.set_meta("quick_index", qi)
	var qphoto := PlaceThumb.load_preset(str(PresetViews.ROWS[qi]["id"])) \
		if qi < PresetViews.ROWS.size() else PlaceThumb.load_capital(qlat, qlon)
	if qphoto != null:
		card.set_photo(qphoto)
	card.pressed.connect(func() -> void:
		_select_suggestion(qname, qlat, qlon)
		_set_selected_quick(qi))
	_quick_chips.append(card)
	_quick_by_index[qi] = card
	_quick_grid.add_child(card)

## Cards built per frame when a continent opens.
const CARDS_PER_FRAME := 12

## The quick picks a shelf holds, in order: Featured keeps the curated order,
## a continent lists its places A to Z by card name.
func _shelf_indices(key: String) -> Array[int]:
	var out: Array[int] = []
	for qi in _quick_places.size():
		var in_shelf := qi < PresetViews.ROWS.size() if key == CapitalContinents.FEATURED \
			else _quick_continents[qi] == key
		if in_shelf:
			out.append(qi)
	if key != CapitalContinents.FEATURED:
		out.sort_custom(func(a: int, b: int) -> bool:
			return str(_quick_places[a][0]).naturalnocasecmp_to(str(_quick_places[b][0])) < 0)
	return out

## Show one shelf: the curated places or a continent. Only the cards of that
## shelf are built, a few a frame (all the capitals at once would freeze a
## phone and push the panel's footer thousands of pixels down).
func _set_shelf(key: String) -> void:
	_shelf_key = key
	_continent_filter.select(key)
	_quick_scroll.scroll_horizontal = 0
	_shelf_build += 1
	var build := _shelf_build
	_apply_shelf()
	var built := 0
	for qi in _shelf_indices(key):
		if _quick_by_index.has(qi):
			continue
		_add_quick_card(qi)
		built += 1
		if built % CARDS_PER_FRAME == 0:
			_settle_shelf()
			await get_tree().process_frame
			if not is_inside_tree() or build != _shelf_build:
				return
	_settle_shelf()

func _settle_shelf() -> void:
	_apply_shelf()
	_set_selected_quick(_selected_quick)
	MapHome.apply_offline(self)

## Show the cards of the open shelf and name it. First launch keeps to three
## featured places and no filter.
func _apply_shelf() -> void:
	var first := _first_note != null and _first_note.visible
	var featured := _shelf_key == CapitalContinents.FEATURED
	var shelf := _shelf_indices(_shelf_key)
	for card in _quick_chips:
		var qi := int(card.get_meta("quick_index"))
		card.visible = qi < 3 if first else qi in shelf
	# Cards are built as a shelf opens, so put the built ones in shelf order.
	var at := 0
	for qi in shelf:
		if _quick_by_index.has(qi):
			_quick_grid.move_child(_quick_by_index[qi], at)
			at += 1
	_continent_filter.visible = not first
	var title := "Around the world"
	if not featured and not first:
		title = "%s · %d %s" % [CapitalContinents.label_of(_shelf_key), shelf.size(),
			"place" if shelf.size() == 1 else "places"]
	_quick_label.text = title.to_upper()
	MapChrome.fit_quick_cards(self)

func _set_selected_quick(index: int) -> void:
	MapChrome._set_selected_quick(self, index)

func set_download_status(text: String) -> void:
	MapHome.set_save_label(self, text)

## A bar and the step under the Save button while it works; a negative
## `fraction` takes both away.
func set_download_progress(fraction: float, phase: String = "") -> void:
	MapChrome.set_download_progress(self, fraction, phase)

## `finishing`: a cancelled scene is still winding down, so say so.
func set_render_status(text: String) -> void:
	MapChrome.set_render_status(self, text)

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
	MapSheet.apply_layout(self)
	MapHome.apply_rail(self)

func _queue_focus_update() -> void:
	MapChrome._queue_focus_update(self)

func _update_focus() -> void:
	MapChrome._update_focus(self)

func _update_explore_bar() -> void:
	MapHome.update_explore_bar(self)

func _on_search_text_changed(text: String) -> void:
	MapSearch.on_text_changed(self, text)

func _hide_suggestions() -> void:
	MapSearch.hide_suggestions(self)

func _select_suggestion(place: String, lat: float, lon: float) -> void:
	MapSearch.select(self, place, lat, lon)

func _on_search(text: String) -> void:
	MapSearch.submit(self, text)

func _ensure_searcher() -> void:
	MapSearch.ensure_searcher(self)

func _on_picked(lat: float, lon: float, warm: bool = true) -> void:
	_hide_suggestions()
	set_download_status("")  # a search or save message was about the last place
	set_render_status("")
	_set_selected_quick(-1)
	selected_name = ""
	MapLandmarkHome.clear(self)
	_lat = lat
	_lon = lon
	# Keep the map centred on the choice: search and quick picks arrive
	# without a map tap, so without this the pin stayed on the old place.
	if _canvas != null:
		_canvas.set_lat_lon(lat, lon, warm)
	if _globe != null:
		_globe.pin = Vector2(lat, lon)
		_globe.queue_redraw()
	_refresh_labels()
	MapFacts.request(self)
	MapLandmarkHome.request(self)
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
	MapHome.queue_explore_bar(self)

func _refresh_labels() -> void:
	_show_place(selected_name if selected_name != "" \
		else LocationData.known_place(_lat, _lon))
	_coord_label.text = UiTheme.coords(_lat, _lon)
	MapChrome.refresh_cached(self)
