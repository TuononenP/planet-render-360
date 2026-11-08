extends SceneTree

## Headless responsive test: godot --headless --script tests/responsive_test.gd
## Covers the mobile-first contract: breakpoint thresholds, the picker
## switching stacked <-> split (and filling its height, no dead band),
## the layout override, history grid columns, and readable type floors.

func _init() -> void:
	_run()

func _fail(failures: Array[String], msg: String) -> void:
	failures.append(msg)

func _centre_in(c: Control, scroll: ScrollContainer) -> bool:
	var mid := c.get_global_rect().get_center().y
	var view := scroll.get_global_rect()
	return mid >= view.position.y and mid <= view.end.y

## Explore sits above the Around the world shelf. With the panel scrolled
## down to the shelf, a pick keeps the scroll (the card stays in view) and
## a pinned Explore bar for the place starts the scene.
func _check_explore_bar(failures: Array[String], picker: MapPicker, win: Vector2, label: String) -> void:
	# A returning user sees the whole shelf (first launch shows three cards).
	for chip in picker._quick_chips:
		chip.visible = true
	# Measured without the optional elevation, time and weather rows
	# (no timer, so a pick doesn't bring their placeholders back).
	picker._facts_timer = null
	MapFacts.hide_facts(picker)
	picker.size = win
	picker._on_resized()
	await process_frame
	await process_frame
	var expanded := picker.effective_layout() == Responsive.Layout.EXPANDED
	var scroll: ScrollContainer = picker._side_scroll if expanded else picker._sheet_scroll
	var bar: Button = picker._side_explore if expanded else picker._sheet_explore
	if bar.is_visible_in_tree():
		_fail(failures, "%s: the Explore bar should hide while Explore is in view" % label)
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	for i in 3:
		await process_frame
	if _centre_in(picker._render_btn, scroll):
		_fail(failures, "%s: test window should be short enough to scroll Explore away" % label)
		return
	if not bar.is_visible_in_tree():
		_fail(failures, "%s: the Explore bar should show while Explore is scrolled away" % label)
	var card := picker._quick_grid.get_child(4) as Button  # Tokyo, on the shelf
	scroll.ensure_control_visible(card)
	for i in 2:
		await process_frame
	var kept := scroll.scroll_vertical
	card.pressed.emit()
	for i in 3:
		await process_frame
	if scroll.scroll_vertical != kept or not _centre_in(card, scroll):
		_fail(failures, "%s: a shelf pick should keep the picked card in view" % label)
	if not bar.is_visible_in_tree() or bar.text != "Explore Tokyo in 360°":
		_fail(failures, "%s: the bar should offer the picked place, got '%s'" % [label, bar.text])
	var got: Array[float] = []
	var on_render := func(lat: float, _lon: float) -> void: got.append(lat)
	picker.render_requested.connect(on_render)
	bar.pressed.emit()
	picker.render_requested.disconnect(on_render)
	if got.size() != 1 or absf(got[0] - float(LocationData.quick_picks()[4][2])) > 0.01:
		_fail(failures, "%s: the Explore bar should start Tokyo, got %s" % [label, str(got)])
	scroll.scroll_vertical = 0
	for i in 3:
		await process_frame
	if bar.is_visible_in_tree():
		_fail(failures, "%s: the bar should hide once Explore scrolls back into view" % label)

func _run() -> void:
	var failures: Array[String] = []

	# Startup window: full screen at the real screen size, with stretch
	# that expands the logical viewport to fill it responsively.
	if int(ProjectSettings.get_setting("display/window/size/mode", 0)) \
			!= DisplayServer.WINDOW_MODE_FULLSCREEN:
		_fail(failures, "app should start full screen (display/window/size/mode)")
	if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "canvas_items" \
			or str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) != "expand":
		_fail(failures, "stretch should be canvas_items/expand to fill any screen")

	# Breakpoint thresholds
	if Responsive.layout_for_width(390.0) != Responsive.Layout.COMPACT:
		_fail(failures, "390pt should be COMPACT")
	if Responsive.layout_for_width(599.0) != Responsive.Layout.COMPACT:
		_fail(failures, "599pt should be COMPACT")
	if Responsive.layout_for_width(600.0) != Responsive.Layout.MEDIUM:
		_fail(failures, "600pt should be MEDIUM")
	if Responsive.layout_for_width(1023.0) != Responsive.Layout.MEDIUM:
		_fail(failures, "1023pt should be MEDIUM")
	if Responsive.layout_for_width(1024.0) != Responsive.Layout.EXPANDED:
		_fail(failures, "1024pt should be EXPANDED")
	if Responsive.history_columns(Responsive.Layout.COMPACT) != 2 \
			or Responsive.history_columns(Responsive.Layout.MEDIUM) != 3 \
			or Responsive.history_columns(Responsive.Layout.EXPANDED) != 4:
		_fail(failures, "history columns should be 2/3/4 by layout")
	if Responsive.page_padding(Responsive.Layout.COMPACT) >= Responsive.page_padding(Responsive.Layout.EXPANDED):
		_fail(failures, "padding should grow with layout")

	# Phones and tablets rotate freely (an integer: 6 is Sensor).
	var orientation: Variant = ProjectSettings.get_setting("display/window/handheld/orientation")
	if typeof(orientation) != TYPE_INT or int(orientation) != DisplayServer.SCREEN_SENSOR:
		_fail(failures, "handheld orientation should be the Sensor integer, got %s" % str(orientation))
	# Real devices (pixels, pixels per point): one logical unit is one point,
	# whatever the design frame fits to.
	for device: Array in [[Vector2(750, 1334), 2.0, Vector2(375, 667), Responsive.Layout.COMPACT],
			[Vector2(1170, 2532), 3.0, Vector2(390, 844), Responsive.Layout.COMPACT],
			[Vector2(2532, 1170), 3.0, Vector2(844, 390), Responsive.Layout.EXPANDED],
			[Vector2(1488, 2266), 2.0, Vector2(744, 1133), Responsive.Layout.MEDIUM],
			[Vector2(1640, 2360), 2.0, Vector2(820, 1180), Responsive.Layout.MEDIUM],
			[Vector2(2360, 1640), 2.0, Vector2(1180, 820), Responsive.Layout.EXPANDED],
			# Android: Godot reports a capped 1.35 here; the 480 dpi is the truth.
			[Vector2(1080, 2400), Responsive.points_for(true, 1.35, 480), Vector2(360, 800), Responsive.Layout.COMPACT],
			[Vector2(1170, 2532), Responsive.points_for(false, 3.0, 460), Vector2(390, 844), Responsive.Layout.COMPACT]]:
		var win: Vector2 = device[0]
		var fit := minf(win.x / 390.0, win.y / 844.0)
		var logical := win / (fit * Responsive.content_scale_factor(win, device[1]))
		if not logical.is_equal_approx(device[2]):
			_fail(failures, "%s at %sx should be %s points, got %s" % [str(win), str(device[1]), str(device[2]), str(logical)])
		if Responsive.layout_for_size(logical) != device[3]:
			_fail(failures, "%s should take layout %d" % [str(logical), device[3]])
	# A control shorter than size-touch still takes taps just outside it.
	var touch := TouchButton.new()
	touch.size = Vector2(60, 32)
	if not touch._has_point(Vector2(30, -5)) or not touch._has_point(Vector2(30, 37)) \
			or touch._has_point(Vector2(30, -7)):
		_fail(failures, "TouchButton should grow its hit area to 44pt")
	touch.free()

	# Readable floors at the 390pt design frame
	var field := UiTheme.field("x")
	if field.get_theme_font_size("font_size") < 16:
		_fail(failures, "field font below 16pt")
	if field.custom_minimum_size.y < 48.0:
		_fail(failures, "field touch target below 48pt")
	var primary := UiTheme.primary_button("x")
	if primary.custom_minimum_size.y < 52.0:
		_fail(failures, "primary button below 52pt")

	# Picker: compact fills the screen, wide splits, override forces compact
	var picker := MapPicker.new()
	root.add_child(picker)
	picker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picker.size = Vector2(390, 844)
	picker._on_resized()
	await process_frame
	await process_frame
	if picker.effective_layout() != Responsive.Layout.COMPACT:
		_fail(failures, "picker at 390pt should be COMPACT, got %d" % picker.effective_layout())
	# Quality is a four-step bar above Explore: the tier is visible without a menu.
	var bar: SegmentedControl = picker._quality_bar
	if bar == null or bar.item_count != RenderSettings.PRESET_NAMES.size():
		_fail(failures, "the quality bar should have one segment per tier")
	else:
		picker.set_quality_preset(RenderSettings.Preset.ULTRA)
		if bar.selected != RenderSettings.Preset.ULTRA or picker._quality_hint.text != RenderSettings.tier_hint(3):
			_fail(failures, "the quality bar should show the chosen tier and what it trades")
		var got: Array[int] = []
		picker.quality_selected.connect(func(t: int) -> void: got.append(t))
		bar._buttons[0].pressed.emit()
		if got != [0] or bar.selected != 0:
			_fail(failures, "tapping a segment should pick that tier, got %s" % str(got))
		picker._render_btn.disabled = true
		MapChrome._lock_quality_menu(picker)
		if not bar._buttons[1].disabled:
			_fail(failures, "the quality bar should lock while Explore is busy")
		picker._render_btn.disabled = false
		MapChrome._lock_quality_menu(picker)
		picker.set_quality_preset(RenderSettings.Preset.HIGH)
	if picker._quick_chips.size() != PresetViews.ROWS.size():
		_fail(failures, "the shelf should start with the featured places, got %d" % picker._quick_chips.size())
	if picker._canvas == null or picker._canvas.size.y < 240.0:
		_fail(failures, "compact map should fill leftover height, got %s" % str(picker._canvas.size))
	# Night Atlas: the map is full-bleed and the sheet is anchored to
	# the bottom edge, so no band of dead space sits below it.
	var sheet_bottom := picker._sheet.get_global_rect().end.y
	if sheet_bottom < 800.0:
		_fail(failures, "compact sheet should sit on the bottom edge: ends at y=%.0f of 844" % sheet_bottom)
	if picker._canvas.size.y < 800.0:
		_fail(failures, "compact map should be full-bleed, got %s" % str(picker._canvas.size))
	if not picker._sheet_cols.vertical:
		_fail(failures, "phone sheet should stack its columns")
	if picker._history_btn.get_global_rect().end.y > 120.0:
		_fail(failures, "nav icons should sit in the top bar on a phone")
	if picker._stack.size.x > 390.0:
		_fail(failures, "compact picker column should fit 390pt, got %s" % str(picker._stack.size))
	if picker._brand_pill.visible:
		_fail(failures, "phones have no brand row; the wordmark pill belongs to wider layouts")
	if picker._download_btn.text != "":
		_fail(failures, "phone Save for offline is an icon beside Explore, got '%s'" % picker._download_btn.text)

	picker.size = Vector2(1280, 800)
	picker._on_resized()
	await process_frame
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "picker at 1280pt should be EXPANDED, got %d" % picker.effective_layout())
	if not picker._split.visible or picker._stack.visible:
		_fail(failures, "wide picker should show split, hide stack")
	if picker._canvas.size.x < 600.0:
		_fail(failures, "wide map should take the larger pane, got %s" % str(picker._canvas.size))

	picker._on_layout_selected(1)  # force Compact
	await process_frame
	if picker.effective_layout() != Responsive.Layout.COMPACT or picker._split.visible:
		_fail(failures, "Compact override should force stacked layout on a wide window")
	# The override lives in Settings → Appearance; Auto must restore the
	# automatic layout from there.
	picker.set_layout_override(0)  # back to Auto, as Settings does
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "Auto should restore EXPANDED on a wide window")
	picker._on_layout_selected(2)  # force Wide
	await process_frame
	if picker.effective_layout() != Responsive.Layout.MEDIUM or picker._split.visible \
			or picker._sheet_cols.vertical:
		_fail(failures, "Wide override should force the tablet two-column sheet on a wide window")
	picker.set_layout_override(0)  # back to Auto, as Settings does
	await process_frame
	if picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "Auto should restore EXPANDED after Wide")

	# Around the world: one tap selects the place and centres the map on it
	if picker._quick_box == null or picker._quick_grid == null:
		_fail(failures, "picker should offer one-tap places (Around the world)")
	else:
		var quick_row := picker._quick_grid
		if quick_row.get_child_count() < 3:
			_fail(failures, "Around the world should offer at least 3 places")
		else:
			(quick_row.get_child(2) as Button).pressed.emit()  # Banff
			await process_frame
			if abs(picker._lat - 51.1789) > 0.01 or picker.selected_name != "Banff, Canada":
				_fail(failures, "place card should select Banff, got %f / %s" % [picker._lat, picker.selected_name])
			if abs(picker._canvas.centre_lat - 51.1789) > 0.01:
				_fail(failures, "place card should centre the map on Banff, got %f" % picker._canvas.centre_lat)
			if picker._name_label.text != "Banff" or picker._region_label.text != "Canada":
				_fail(failures, "selected place should read name over region, got '%s' / '%s'"
					% [picker._name_label.text, picker._region_label.text])
			# Tokyo must visibly stay selected (regression: cards were
			# momentary, so the tap left no active state).
			(quick_row.get_child(4) as Button).pressed.emit()  # Tokyo
			await process_frame
			var tokyo_chip := quick_row.get_child(4) as Button
			if abs(picker._lat - float(LocationData.quick_picks()[4][2])) > 0.01 or picker.selected_name != "Tokyo, Japan":
				_fail(failures, "place card should select Tokyo, got %f / %s" % [picker._lat, picker.selected_name])
			if not tokyo_chip.button_pressed:
				_fail(failures, "Tokyo card should stay pressed after tapping it")
			var tokyo_ring: Color = (tokyo_chip.get_theme_stylebox("pressed") as StyleBoxFlat).border_color
			if tokyo_ring != UiTheme.TEAL:
				_fail(failures, "selected card should wear the accent ring, got %s" % str(tokyo_ring))
			if (quick_row.get_child(0) as Button).button_pressed:
				_fail(failures, "only the tapped place card should stay pressed")
			# A manual map pick clears the selection.
			picker._on_picked(48.8566, 2.3522)
			await process_frame
			if tokyo_chip.button_pressed:
				_fail(failures, "manual map pick should clear the Tokyo selection")
	await _check_explore_bar(failures, picker, Vector2(1280, 600), "side panel")
	await _check_explore_bar(failures, picker, Vector2(390, 560), "phone sheet")
	picker.size = Vector2(1280, 800)
	picker._on_resized()
	await process_frame
	await process_frame
	# A pasted "lat, lon" selects that point, no separate fields needed.
	picker._on_search("46.5, 7.9")
	if abs(picker._lat - 46.5) > 0.001 or abs(picker._lon - 7.9) > 0.001:
		_fail(failures, "search should take pasted coordinates, got %f, %f" % [picker._lat, picker._lon])
	if picker._coord_label.text != "46.5000° N  7.9000° E":
		_fail(failures, "coordinates should read like an instrument, got '%s'" % picker._coord_label.text)

	# Busy Explore: dimmed, relabelled only while a cancelled scene is still finishing.
	picker.set_render_busy(true)
	if not picker._render_btn.disabled or picker._render_btn.text != MapChrome.EXPLORE:
		_fail(failures, "a normal busy Explore should only dim, got '%s'" % picker._render_btn.text)
	picker.set_render_busy(true, true)
	if picker._render_btn.text != MapChrome.FINISHING:
		_fail(failures, "a winding-down scene should say so, got '%s'" % picker._render_btn.text)
	picker.set_render_busy(false)
	if picker._render_btn.disabled or picker._render_btn.text != MapChrome.EXPLORE:
		_fail(failures, "Explore should return to normal when idle")

	# Cached badge: shown only when every layer of the place is on the device.
	var cache_dir := "user://responsive_cache"
	DirAccess.make_dir_recursive_absolute(cache_dir)
	CacheStore.dir_override = cache_dir
	MapChrome.refresh_cached(picker)
	if picker._cached_chip.visible:
		_fail(failures, "a place with nothing on the device must not wear the Cached badge")
	var cache_keys := CacheStore.place_cache_keys(picker._lat, picker._lon, picker._quality)
	var written: Array[String] = []
	for layer in ["dem", "sat", "osm"]:
		for k in cache_keys[layer]:
			FileAccess.open(str(k), FileAccess.WRITE).store_string("x")
			written.append(str(k))
	MapChrome.refresh_cached(picker)
	if picker._cached_chip.visible:
		_fail(failures, "a place missing land cover must not wear the Cached badge")
	for k in cache_keys["landcover"]:
		FileAccess.open(str(k), FileAccess.WRITE).store_string("x")
		written.append(str(k))
	MapChrome.refresh_cached(picker)
	if not picker._cached_chip.visible:
		_fail(failures, "a fully cached place should wear the Cached badge")
	for k in written:
		DirAccess.remove_absolute(k)
	CacheStore.dir_override = ""

	# Hover contrast: text must stay readable on every hover box
	# (regression: OptionButton had no font_hover_color, so Godot's
	# default made the label nearly invisible on hover).
	var probe := OptionButton.new()
	UiTheme.apply_option(probe)
	if probe.get_theme_color("font_hover_color") != UiTheme.INK:
		_fail(failures, "option button hover text should stay light ink on its dark hover box")
	var popup := probe.get_popup()
	if popup.get_theme_color("font_hover_color") != UiTheme.ON_ACCENT:
		_fail(failures, "option popup hover text should be dark on the accent hover box")
	var popup_hover: Color = (popup.get_theme_stylebox("hover") as StyleBoxFlat).bg_color
	if popup_hover != UiTheme.TEAL:
		_fail(failures, "option popup hover box should use the accent colour, got %s" % str(popup_hover))
	probe.free()

	# Accent choices live in Settings → Appearance: five of them, and
	# picking one recolours the picker (accent ring and background).
	var settings := SettingsScreen.new()
	root.add_child(settings)
	await process_frame
	if settings._accent_btns.size() < 5:
		_fail(failures, "Settings should offer the five accents, got %d" % settings._accent_btns.size())
	else:
		var teal_before: Color = UiTheme.TEAL
		var picked := [-1]
		settings.accent_changed.connect(func(i: int) -> void: picked[0] = i)
		settings._accent_btns[1].pressed.emit()  # Glacier
		picker.refresh_theme()
		await process_frame
		if picked[0] != 1 or UiTheme.TEAL == teal_before:
			_fail(failures, "choosing Glacier should change the accent and say so")
		if picker._bg.color != UiTheme.BG:
			_fail(failures, "choosing an accent should recolour the picker background")
		var ring: Color = ((picker._quick_grid.get_child(0) as Button).get_theme_stylebox("pressed") as StyleBoxFlat).border_color
		if ring != UiTheme.TEAL:
			_fail(failures, "place cards should follow the chosen accent, got %s" % str(ring))
		var layout_seen := [-1]
		settings.layout_changed.connect(func(i: int) -> void: layout_seen[0] = i)
		settings._layout_btns[2].pressed.emit()  # Wide
		if layout_seen[0] != 2:
			_fail(failures, "Settings should offer the layout override")
		settings._layout_btns[0].pressed.emit()
		settings._accent_btns[0].pressed.emit()  # restore Aurora for later checks
		picker.refresh_theme()
		await process_frame
	# Two panes never overflow, down to a small phone on its side.
	settings.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for fit_size in [Vector2(360, 800), Vector2(390, 844), Vector2(633, 844), Vector2(667, 375), Vector2(844, 390), Vector2(820, 1180)]:
		settings.size = fit_size
		settings._on_resized()
		for group: Array in SettingsScreen.CATEGORIES:
			for category: Array in group[1]:
				settings.open_category(str(category[0]))
				await process_frame
				await process_frame
				var needs: float = settings._page_margin.get_combined_minimum_size().x \
					+ (0.0 if settings._compact else settings._rail.get_combined_minimum_size().x)
				if needs > fit_size.x:
					_fail(failures, "Settings %s should fit %s, needs %.0f" % [category[0], str(fit_size), needs])
	Responsive.safe_override = [59.0, 0.0, 59.0, 21.0]
	settings.size = Vector2(844, 390)
	settings._on_resized()
	if settings._rail.custom_minimum_size.x != float(SettingsScreen.RAIL_W_MEDIUM) + 59.0 \
			or settings._page_margin.get_theme_constant("margin_right") < 59:
		_fail(failures, "Settings should keep clear of the notch on a phone on its side")
	Responsive.safe_override = []
	settings.queue_free()
	picker._show_all_capitals()
	if picker._quick_chips.size() != LocationData.quick_picks().size() or picker._quick_more.visible:
		_fail(failures, "Show all capitals should add every capital and then hide")
	picker.queue_free()

	# History grid follows the window width
	var history := HistoryScreen.new()
	root.add_child(history)
	history.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# An empty history is one full-width card; the grid needs a place
	var store := CacheStore.new()
	store.entries.append({"name": "Paris", "lat": 48.8566, "lon": 2.3522})
	history._store = store
	history.size = Vector2(390, 844)
	history._on_resized()
	await process_frame
	# Design system: 2 columns on phones, 3–5 on wider windows.
	if history._list.columns != 2:
		_fail(failures, "history at 390pt should be 2 columns")
	history.size = Vector2(834, 1112)
	history._on_resized()
	await process_frame
	if history._list.columns != 3:
		_fail(failures, "history at 834pt should be 3 columns")
	history.size = Vector2(1280, 800)
	history._on_resized()
	await process_frame
	if history._list.columns != 4:
		_fail(failures, "history at 1280pt should be 4 columns")
	# Touch: tablet cards show Remove, list rows and a phone on its side leave
	# it out (nothing hides on hover, so nothing invisible can be tapped).
	var has_trash := func(root_node: Node) -> bool:
		for b in root_node.find_children("*", "Button", true, false):
			if (b as Button).tooltip_text == "Remove from cache" and (b as Button).modulate.a > 0.5:
				return true
		return false
	var trash_count := func(root_node: Node) -> int:
		return root_node.find_children("*", "Button", true, false).filter(
			func(b: Node) -> bool: return (b as Button).tooltip_text == "Remove from cache").size()
	var place: Dictionary = store.entries[0]
	history._touch = true
	history.size = Vector2(834, 1112)
	history._on_resized()
	var tablet_card: Button = history._card(place)
	if not has_trash.call(tablet_card):
		_fail(failures, "a tablet's touch card should show Remove from cache")
	tablet_card.free()
	var touch_row: Button = history._row(place)
	if trash_count.call(touch_row) != 0:
		_fail(failures, "a touch list row should remove by swipe, with no button")
	touch_row.free()
	history.size = Vector2(844, 390)
	history._on_resized()
	var side_card: Button = history._card(place)
	if trash_count.call(side_card) != 0:
		_fail(failures, "a phone on its side has no room for Remove on its cards")
	side_card.free()
	history._touch = false
	# Hidden, a rotation only marks the cards; they rebuild when shown.
	history.size = Vector2(390, 844)
	history._on_resized()
	await process_frame
	history.visible = false
	history.size = Vector2(834, 1112)
	history._on_resized()
	if not history._stale_cards:
		_fail(failures, "a hidden History should wait to rebuild its cards")
	history.visible = true
	if history._stale_cards:
		_fail(failures, "History should rebuild its cards when shown")
	Responsive.safe_override = [0.0, 59.0, 0.0, 34.0]
	history.size = Vector2(390, 844)
	history._on_resized()
	if history._margin.get_theme_constant("margin_top") != 16 + 8 + 59 \
			or history._margin.get_theme_constant("margin_bottom") != 16 + 34:
		_fail(failures, "History should keep clear of the notch and home indicator")
	Responsive.safe_override = []
	history.size = Vector2(1280, 800)
	history._on_resized()
	await process_frame
	history.toast("Still finishing the last scene.")
	if not history._toast.visible or history._toast_label.text != "Still finishing the last scene.":
		_fail(failures, "history toast should show its message")
	history.queue_free()

	# Loading card is capped and centred on wide screens, full-bleed on phones
	var loading := LoadingScreen.new()
	root.add_child(loading)
	loading.set_anchors_preset(Control.PRESET_TOP_LEFT)
	loading.size = Vector2(1280, 800)
	loading._on_resized()
	await process_frame
	await process_frame
	# Wide windows: the stage card is a size-panel (376pt) column beside the lens.
	if loading._card.size.x > 420.0 or loading._card.size.x < 340.0:
		_fail(failures, "wide loading stage card should be ~376pt, got %s" % str(loading._card.size))
	if loading._card.get_global_rect().position.x <= loading._preview.get_global_rect().end.x:
		_fail(failures, "wide loading stage card should sit right of the lens")
	if loading._rows.size() != GenerationPipeline.STAGES.size():
		_fail(failures, "loading should show one row per pipeline stage")
	loading.begin("Banff, Canada")
	loading.set_progress(0.6, "Placing landmarks")
	if loading._percent_label == null or loading._percent_label.text != "60%":
		_fail(failures, "loading should show a live percent, got %s" % str(loading._percent_label.text if loading._percent_label else null))
	loading.set_stage(0, GenerationPipeline.STAGES[0], "in_progress")
	if not loading._rows[0]["active"]:
		_fail(failures, "loading should track the active stage for its pulse")
	# Whole card fits the window at phone, desktop, and short-window
	# heights: every stage row and Cancel stay on screen (the preview
	# shrinks first). Regression: the card used to overflow ~630pt
	# windows and clip its lower half.
	for fit_size in [Vector2(390, 844), Vector2(1280, 800), Vector2(1024, 630), Vector2(390, 667),
			Vector2(375, 667), Vector2(667, 375), Vector2(844, 390)]:
		loading.size = fit_size
		loading._on_resized()
		# The preview fit converges over a few deferred passes.
		for _i in 6:
			await process_frame
		var card_rect := loading._card.get_global_rect()
		if card_rect.position.y < -1.0 or card_rect.end.y > fit_size.y + 1.0:
			_fail(failures, "loading card should fit %s, got %s" % [str(fit_size), str(card_rect)])
		var cancel_rect := loading._cancel_btn.get_global_rect()
		if cancel_rect.end.y > fit_size.y + 1.0:
			_fail(failures, "loading Cancel should stay on screen at %s, got %s" % [str(fit_size), str(cancel_rect)])
	loading.size = Vector2(390, 844)
	loading._on_resized()
	for _i in 6:
		await process_frame
	if not loading._preview.visible:
		_fail(failures, "loading preview should stay visible at phone height 844")
	loading.queue_free()

	# Main scene: the whole screen chain relayouts when the window
	# size changes (as it does entering full screen on screens of
	# different sizes).
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920, 1080)
	await process_frame
	await process_frame
	if main._picker.effective_layout() != Responsive.Layout.EXPANDED:
		_fail(failures, "main at 1920pt should be EXPANDED, got %d" % main._picker.effective_layout())
	if main._picker.size != Vector2(1920, 1080):
		_fail(failures, "picker should fill the window, got %s" % str(main._picker.size))
	main.size = Vector2(390, 844)
	await process_frame
	await process_frame
	if main._picker.effective_layout() != Responsive.Layout.COMPACT:
		_fail(failures, "main at 390pt should be COMPACT, got %d" % main._picker.effective_layout())
	# A half turn keeps the window size: only the safe-area check sees the
	# notch change sides.
	Responsive.safe_override = [59.0, 0.0, 0.0, 21.0]
	main._check_safe_area()
	if main._picker._overlay.get_theme_constant("margin_left") != 16 + 59:
		_fail(failures, "screens should relayout when the notch appears on the left")
	Responsive.safe_override = [0.0, 0.0, 59.0, 21.0]
	main._check_safe_area()
	if main._picker._overlay.get_theme_constant("margin_left") != 16 \
			or main._picker._overlay.get_theme_constant("margin_right") != 16 + 59:
		_fail(failures, "screens should relayout when the notch moves to the other side")
	Responsive.safe_override = []
	main._check_safe_area()
	main.queue_free()
	# queue_free is deferred; let it run before quitting.
	await process_frame
	await process_frame

	if failures.is_empty():
		print("RESPONSIVE OK: breakpoints, stacked/split picker, layout override, history grid, type floors")
		quit(0)
	else:
		for f in failures:
			printerr("RESPONSIVE FAIL: ", f)
		quit(1)
