class_name SettingsScreen
extends Control

## Settings (design system Screens → SettingsScreen): eight categories
## shown one at a time. Tablet and desktop windows get two panes, a
## category rail on sky-200 beside the chosen page; phones get a menu of
## category rows that opens one page at a time. Every category row
## carries a one-line summary of its current values. The pages are built
## by SettingsPages; every choice applies at once and is saved on-device
## for the next launch.

signal back_requested
signal preset_changed(preset: int)
signal accent_changed(index: int)
## 0 Auto, 1 Compact, 2 Wide: forces the stacked or two-column layout.
signal layout_changed(index: int)
## Units changed: screens showing numbers reformat them.
signal units_changed

## Set before a theme rebuild so Main reopens Settings afterwards.
static var reopen := false
## Where Settings was when a theme switch rebuilt the app (the category,
## and on phones whether its page was open rather than the menu), so the
## rebuilt screen reopens there.
static var last_category := "appearance"
static var last_in_page := false

## [eyebrow, [[id, icon, name, lead], ...]] in rail order.
const CATEGORIES := [
	["Look and feel", [
		["appearance", "palette", "Appearance", "Night or Day, and the one accent that marks what is selected."],
		["access", "eye", "Accessibility", "Larger text, calmer motion and stronger contrast."]]],
	["The view", [
		["quality", "gauge", "Render quality", "Higher quality is more faithful to the real place, but takes longer to build and more power to draw."],
		["units", "ruler", "Units", "How elevation, coordinates and time are written."],
		["photos", "camera", "Photos", "Pictures saved from the 360° view."]]],
	["Data", [
		["storage", "hard-drive", "Storage", "Places you open are kept on this device, so they open instantly next time, even offline."],
		["sources", "layers", "Data sources", "Where the map, terrain, imagery and weather come from. Each opens its licence."],
		["about", "info", "About", "Planet Render 360 and the open work it is built on."]]],
]
const RAIL_W := 300
const RAIL_W_MEDIUM := 248
const PAGE_MAX_W := 680

var _settings: RenderSettings
var _preset_btns: Array[Button] = []
var _preset_checks: Array[Control] = []
var _specs: Dictionary = {}  # key -> Readout
var _specs_title: Label
var _usage: Readout
var _usage_of: Label
var _usage_bar: ProgressBar
var _cache_bytes := 0
var _grid: GridContainer
var _accent_btns: Array[Button] = []
var _layout_btns: Array[Button] = []
var _layout_index := 0
var _theme_seg: SegmentedControl
var _text_seg: SegmentedControl
var _layout_seg: SegmentedControl
var _unit_segs: Dictionary = {}  # pref key -> SegmentedControl
var _unit_samples: Dictionary = {}  # pref key -> Label
var _toggles: Dictionary = {}  # pref key -> Button
var _limit_slider: HSlider
var _limit_label: Label

var _bg: ColorRect
var _rail: PanelContainer
var _rail_margin: MarginContainer
var _rail_foot: Control
var _top: MarginContainer
var _top_title: Label
var _scroll: ScrollContainer
var _page_margin: MarginContainer
var _menu: VBoxContainer
var _page_head: VBoxContainer
var _page_title: Label
var _page_lead: Label
var _pages: Dictionary = {}  # id -> page
## One entry per category row, rail and menu alike:
## {id, button, tile, icon, summary, menu}.
var _cat_items: Array[Dictionary] = []
var _current := ""
var _in_page := false
var _compact := false
## Opened straight on a page from elsewhere (the viewer's attribution):
## Back leaves Settings instead of showing a menu the person never saw.
var _leave_on_back := false
## The next showing keeps `_in_page` (the reopen after a rebuild).
var _keep_page := false
var _specs_grid: GridContainer
var _laid_out := false

func _ready() -> void:
	_current = last_category
	if reopen:
		_in_page = last_in_page
		_keep_page = true
	_bg = ColorRect.new()
	_bg.color = UiTheme.BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 0)
	add_child(split)
	split.add_child(_build_rail())
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 0)
	split.add_child(main)
	_top = MarginContainer.new()
	main.add_child(_top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	_top.add_child(top_row)
	top_row.add_child(_back_button(func() -> void:
		if not step_back():
			back_requested.emit()))
	_top_title = UiTheme.text("Settings", "title")
	_top_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(_top_title)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiTheme.apply_scroll(_scroll)
	main.add_child(_scroll)
	_page_margin = MarginContainer.new()
	_page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_page_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	_page_margin.add_child(col)
	_menu = _build_menu()
	col.add_child(_menu)
	_page_head = VBoxContainer.new()
	_page_head.add_theme_constant_override("separation", 4)
	col.add_child(_page_head)
	_page_title = UiTheme.text("", "title")
	_page_head.add_child(_page_title)
	_page_lead = UiTheme.label("", 15, UiTheme.MUTED)
	_page_lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_head.add_child(_page_lead)
	for pair in [["appearance", SettingsPages.appearance], ["access", SettingsPages.accessibility],
			["quality", SettingsPages.quality], ["units", SettingsPages.units],
			["photos", SettingsPages.photos], ["storage", SettingsPages.storage],
			["sources", SettingsPages.sources], ["about", SettingsPages.about]]:
		var build: Callable = pair[1]
		var page: Control = build.call(self)
		_pages[pair[0]] = page
		col.add_child(page)
	resized.connect(_on_resized)
	visibility_changed.connect(_on_visibility_changed)
	_on_resized()
	_restyle_cats()
	_refresh()

## Each visit starts on the phone menu (except the reopen after a
## rebuild) and reads the cache size afresh.
func _on_visibility_changed() -> void:
	if not visible:
		return
	if not _keep_page:
		_in_page = false
	_keep_page = false
	_leave_on_back = false
	_refresh_storage()
	_show_current()

## The rail: back and title, the grouped category rows, a foot line.
func _build_rail() -> PanelContainer:
	_rail = PanelContainer.new()
	_rail.add_theme_stylebox_override("panel", _rail_style())
	_rail_margin = MarginContainer.new()
	for side in ["left", "right"]:
		_rail_margin.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		_rail_margin.add_theme_constant_override("margin_" + side, 24)
	_rail.add_child(_rail_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	_rail_margin.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	head.add_child(_back_button(func() -> void: back_requested.emit()))
	var title := UiTheme.text("Settings", "title")
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiTheme.apply_scroll(scroll)
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for g in CATEGORIES:
		var eyebrow := MarginContainer.new()
		eyebrow.add_theme_constant_override("margin_left", 12)
		eyebrow.add_theme_constant_override("margin_top", 0 if list.get_child_count() == 0 else 12)
		eyebrow.add_theme_constant_override("margin_bottom", 2)
		eyebrow.add_child(UiTheme.section_label(g[0]))
		list.add_child(eyebrow)
		for c in g[1]:
			list.add_child(_cat_row(c, false))
	var foot := UiTheme.label("Changes apply at once and are kept on this device.", 14, UiTheme.MUTED)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rail_foot = _pad_h(foot, 12)
	col.add_child(_rail_foot)
	return _rail

## Phones: the categories as rows in three solid groups.
func _build_menu() -> VBoxContainer:
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 20)
	for g in CATEGORIES:
		var sect := VBoxContainer.new()
		sect.add_theme_constant_override("separation", 8)
		sect.add_child(_pad_h(UiTheme.section_label(g[0]), 4))
		var group := SettingsRows.group()
		for c in g[1]:
			SettingsRows.add(group, _cat_row(c, true))
		sect.add_child(group)
		menu.add_child(sect)
	var version := UiTheme.label("Planet Render 360 · %s" % version_text(), 14, UiTheme.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(version)
	return menu

## A category row: icon tile, name, the summary of its current values,
## and on phones a trailing chevron.
func _cat_row(c: Array, in_menu: bool) -> Button:
	var b := Button.new()
	b.tooltip_text = str(c[2])
	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 12)
	for side in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(row)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(36, 36)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(center)
	var icon := UiIcon.rect(str(c[1]), 20, UiTheme.MUTED)
	center.add_child(icon)
	row.add_child(tile)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	var name_l := UiTheme.label(str(c[2]), 15, UiTheme.INK, true)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(name_l)
	var summary := UiTheme.label("", 14, UiTheme.MUTED)
	summary.clip_text = true
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(summary)
	if in_menu:
		var chevron := UiIcon.rect("chevron-right", 20, UiTheme.FAINT)
		chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(chevron)
	SettingsRows._fill_button(b, pad, 60 if in_menu else 56)
	var id := str(c[0])
	b.pressed.connect(func() -> void: open_category(id))
	_cat_items.append({"id": id, "button": b, "tile": tile, "icon": icon,
		"summary": summary, "menu": in_menu})
	return b

func _back_button(on_press: Callable) -> Button:
	var back := UiTheme.icon_button("")
	UiIcon.apply(back, "arrow-left", 22)
	back.tooltip_text = "Back"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(on_press)
	return back

func _pad_h(c: Control, px: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", px)
	m.add_theme_constant_override("margin_right", px)
	m.add_child(c)
	return m

## sky-200 with a `line` edge on the page side only.
func _rail_style() -> StyleBoxFlat:
	var st := UiTheme.style(UiTheme.SURFACE, 0, UiTheme.LINE)
	st.set_border_width_all(0)
	st.border_width_right = 1
	st.set_content_margin_all(0)
	return st

## Rail rows: the chosen one is accent-soft with an accent edge and an
## accent tile; menu rows are plain rows that tint on hover.
func _style_cat(item: Dictionary) -> void:
	var b: Button = item["button"]
	var active: bool = not bool(item["menu"]) and str(item["id"]) == _current
	if bool(item["menu"]):
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UiTheme.style(Color(UiTheme.INK, 0.04), 0))
		b.add_theme_stylebox_override("pressed", UiTheme.style(Color(UiTheme.INK, 0.08), 0))
	else:
		var chosen := UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_M, UiTheme.TEAL)
		var rest: StyleBox = chosen if active else StyleBoxEmpty.new()
		b.add_theme_stylebox_override("normal", rest)
		b.add_theme_stylebox_override("hover", chosen if active else UiTheme.style(UiTheme.FIELD, UiTheme.RADIUS_M))
		b.add_theme_stylebox_override("pressed", chosen)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_M))
	var tile := UiTheme.style(UiTheme.TEAL if active else UiTheme.FIELD, UiTheme.RADIUS_S)
	tile.set_content_margin_all(0)
	(item["tile"] as PanelContainer).add_theme_stylebox_override("panel", tile)
	(item["icon"] as TextureRect).modulate = UiTheme.ON_ACCENT if active else UiTheme.MUTED

## Opens a category: the page beside the rail, or on phones the page in
## place of the menu.
func open_category(id: String) -> void:
	if not _pages.has(id):
		return
	_current = id
	_in_page = true
	_leave_on_back = false
	_show_current()
	_restyle_cats()
	if _scroll != null:
		_scroll.scroll_vertical = 0

## Back one level: on phones a page returns to the menu. False when
## there is nothing to step back to (the caller leaves Settings).
func step_back() -> bool:
	if _leave_on_back:
		return false
	if _compact and _in_page:
		_in_page = false
		_show_current()
		return true
	return false

func _show_current() -> void:
	if _menu == null:
		return
	var show_page := not _compact or _in_page
	_menu.visible = not show_page
	_page_head.visible = show_page
	_page_title.visible = not _compact
	for id in _pages:
		(_pages[id] as Control).visible = show_page and id == _current
	var c := _category(_current)
	_page_title.text = str(c[2])
	_page_lead.text = str(c[3])
	_top_title.text = str(c[2]) if show_page else "Settings"

func _restyle_cats() -> void:
	for item in _cat_items:
		_style_cat(item)

func _category(id: String) -> Array:
	for g in CATEGORIES:
		for c in g[1]:
			if c[0] == id:
				return c
	return CATEGORIES[0][1][0]

## Compact forces the phone menu. Wide (a forced tablet layout on the
## map) follows the window here like Auto: two panes need tablet width,
## and a forced rail would leave a phone window a page too narrow for
## its own controls.
func _layout() -> Responsive.Layout:
	if Responsive.override_layout(_layout_index) == Responsive.Layout.COMPACT:
		return Responsive.Layout.COMPACT
	return Responsive.layout_for_size(size)

func _on_resized() -> void:
	if _page_margin == null:
		return
	var layout := _layout()
	var was_compact := _compact
	_compact = layout == Responsive.Layout.COMPACT
	# Narrowing an open two-pane Settings keeps the page in view.
	if _laid_out and _compact and not was_compact and is_visible_in_tree():
		_in_page = true
	_laid_out = true
	_rail.visible = not _compact
	_top.visible = _compact
	var rail_w := RAIL_W if layout == Responsive.Layout.EXPANDED else RAIL_W_MEDIUM
	_rail.custom_minimum_size.x = rail_w
	# Short windows give the foot line's room to the category rows.
	_rail_foot.visible = size.y >= 860.0
	var pad := 16
	var top := 4
	if layout == Responsive.Layout.EXPANDED:
		pad = 48
		top = 40
	elif layout == Responsive.Layout.MEDIUM:
		pad = 32
		top = 40
	var avail := size.x - (0.0 if _compact else float(rail_w))
	_page_margin.add_theme_constant_override("margin_left", pad)
	_page_margin.add_theme_constant_override("margin_right", maxi(pad, int(avail) - PAGE_MAX_W - pad))
	_page_margin.add_theme_constant_override("margin_top", top)
	_page_margin.add_theme_constant_override("margin_bottom", pad)
	var edge := Responsive.page_padding(Responsive.Layout.COMPACT)
	for side in ["left", "right", "bottom"]:
		_top.add_theme_constant_override("margin_" + side, edge)
	_top.add_theme_constant_override("margin_top", edge + 8)
	var page_w := minf(avail - 2.0 * pad, PAGE_MAX_W)
	if _grid != null:
		_grid.columns = 2 if page_w >= 520.0 else 1
	if _specs_grid != null:
		_specs_grid.columns = 3 if page_w >= 340.0 * UiTheme.text_scale else 2
	_show_current()

## Opened from the viewer's attribution: straight to Data sources.
func show_data_sources() -> void:
	open_category("sources")
	_leave_on_back = true

## A wrapping row of exclusive chips; `pick(index)` runs on a choice.
func _choice_row(parent: Control, names: Array, into: Array[Button], pick: Callable) -> Array[Button]:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	parent.add_child(flow)
	var group := ButtonGroup.new()
	for i in names.size():
		var chip := UiTheme.chip_button(str(names[i]))
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		chip.custom_minimum_size = Vector2(96, 44)
		chip.button_group = group
		var index := i
		chip.pressed.connect(func() -> void:
			pick.call(index)
			_refresh_appearance())
		into.append(chip)
		flow.add_child(chip)
	return into

func _refresh_appearance() -> void:
	for i in _accent_btns.size():
		var chosen := i == UiTheme.AUTO_CHIP if UiTheme.auto_mode else i == UiTheme.theme_index
		var chip := _accent_btns[i]
		chip.set_pressed_no_signal(chosen)
		UiTheme.apply_chip(chip, chosen)
		# Each chip shows its colour; the chosen one shows a check on its fill.
		if chosen:
			UiIcon.apply(chip, "check", 16, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
		elif i == UiTheme.AUTO_CHIP:
			UiIcon.apply(chip, "sunrise", 16, UiTheme.INK, UiTheme.ON_ACCENT)
		else:
			chip.icon = UiTheme.dot(UiTheme.ACCENTS[i])
			chip.expand_icon = false
			for key in ["icon_normal_color", "icon_hover_color", "icon_focus_color",
					"icon_pressed_color", "icon_hover_pressed_color"]:
				chip.add_theme_color_override(key, Color.WHITE)
	if _layout_seg != null:
		_layout_seg.select(_layout_index)
	if _settings != null and _theme_seg != null:
		_theme_seg.select(int(_settings.pref("theme")))
		_text_seg.select(SettingsPages.TEXT_SCALES.find(float(_settings.pref("text_scale"))))
		for key in _unit_segs:
			(_unit_segs[key] as SegmentedControl).select(1 if bool(_settings.pref(key)) else 0)
		for key in _toggles:
			var on := {"reduce_motion": UiPrefs.reduce_motion, "solid_panels": UiPrefs.solid_panels,
				"high_contrast": UiPrefs.high_contrast,
				"photo_stamp": UiPrefs.photo_stamp}.get(key, false) as bool
			(_toggles[key] as Button).set_pressed_no_signal(on)
			(_toggles[key] as Button).queue_redraw()
	SettingsPages.show_unit_samples(self)
	_refresh_summaries()

## Each category row's one line of current values.
func _refresh_summaries() -> void:
	for item in _cat_items:
		(item["summary"] as Label).text = summary_for(str(item["id"]))

func summary_for(id: String) -> String:
	match id:
		"appearance":
			var theme_i := int(_settings.pref("theme")) if _settings != null else 0
			var theme_name: String = ["Night", "Day", "Match system"][clampi(theme_i, 0, 2)]
			var accent: String = "Auto" if UiTheme.auto_mode else UiTheme.theme_names[UiTheme.theme_index]
			return "%s · %s" % [theme_name, accent]
		"access":
			var parts: Array[String] = ["Text %d%%" % roundi(UiTheme.text_scale * 100.0)]
			if UiPrefs.reduce_motion:
				parts.append("Reduce motion")
			if UiPrefs.solid_panels:
				parts.append("Solid panels")
			if UiPrefs.high_contrast:
				parts.append("More contrast")
			return " · ".join(parts)
		"quality":
			var p := _settings.preset if _settings != null else int(RenderSettings.Preset.HIGH)
			return "%s · first build %s" % [RenderSettings.preset_name(p),
				RenderSettings.FIRST_BUILD[RenderSettings.clamp_preset(p)]]
		"units":
			return "%s · %s · %s" % ["Imperial" if UiTheme.units_imperial else "Metric",
				"DMS" if UiTheme.units_dms else "Decimal", "12-hour" if UiTheme.units_12h else "24-hour"]
		"photos":
			return "Stamp on" if UiPrefs.photo_stamp else "Stamp off"
		"storage":
			var limit := int(_settings.pref("cache_limit_mb")) if _settings != null else 2048
			return "%s of %s" % [UiTheme.cache_size(_cache_bytes), UiTheme.cache_size(limit * 1048576)]
		"sources":
			return "%d sources and licences" % SettingsPages.SOURCES.size()
		"about":
			var v := version_text()
			return v if v == "Development build" else "Version %s" % v
	return ""

func version_text() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	return version if version != "" else "Development build"

## Theme: saved, then the app rebuilds every screen in the new palette
## and comes back here (an instant switch, no glide).
func _on_theme(index: int) -> void:
	if _settings == null:
		return
	_settings.set_pref("theme", index)
	_rebuild_app()

## Reduce motion applies at once; Solid panels and Increase contrast
## change the palette, so the app rebuilds like a theme switch.
func _on_access(key: String, on: bool) -> void:
	if _settings == null:
		return
	_settings.set_pref(key, on)
	UiPrefs.apply(_settings)
	_refresh_summaries()
	if key != "reduce_motion":
		_rebuild_app()

## Viewer switches apply at once and need no rebuild.
func _on_viewer_pref(key: String, on: bool) -> void:
	if _settings == null:
		return
	_settings.set_pref(key, on)
	UiPrefs.apply(_settings)
	_refresh_summaries()

func _rebuild_app() -> void:
	UiPrefs.apply(_settings)
	last_category = _current
	last_in_page = _in_page
	if is_inside_tree() and get_tree().current_scene != null \
			and get_tree().current_scene.scene_file_path != "":
		reopen = true
		get_tree().reload_current_scene.call_deferred()

func _on_unit(key: String, on: bool) -> void:
	if _settings == null:
		return
	_settings.set_pref(key, on)
	UiPrefs.apply(_settings)
	SettingsPages.show_unit_samples(self)
	_refresh_summaries()
	units_changed.emit()

func _on_cache_limit() -> void:
	if _settings == null:
		return
	_settings.set_pref("cache_limit_mb", int(_limit_slider.value))
	UiPrefs.apply(_settings)
	CacheStore.enforce_size_cap(false)
	_refresh_storage()

## Clear cache, behind a confirmation that shows what it frees.
func _confirm_clear() -> void:
	SettingsRows.confirm(self, "Clear cache?",
		"This frees %s. Saved places stay in History and download again when you open them."
			% UiTheme.cache_size(OfflineDownloader.cache_size_bytes()),
		"Clear cache", func() -> void:
			OfflineDownloader.clear_cache()
			_refresh_storage())

## Re-skin after an accent change (rows, cards and bars bake it in).
func refresh_theme() -> void:
	_refresh_appearance()
	for seg in [_theme_seg, _text_seg, _layout_seg] + _unit_segs.values():
		if seg != null:
			(seg as SegmentedControl).restyle()
	for key in _toggles:
		(_toggles[key] as Button).queue_redraw()
	for btn in _preset_btns:
		SettingsPages.style_preset(btn)
	for check in _preset_checks:
		(check as PanelContainer).add_theme_stylebox_override("panel", SettingsPages.check_style())
	if _usage_bar != null:
		SettingsPages.style_usage_bar(_usage_bar)
	_restyle_cats()

func bind_settings(settings: RenderSettings) -> void:
	_settings = settings
	_layout_index = settings.layout
	_refresh()
	_on_resized()

func _select(preset_value: int) -> void:
	if _settings == null:
		_settings = RenderSettings.new()
	_settings.set_preset(preset_value)
	_refresh()
	preset_changed.emit(_settings.preset)

func _refresh() -> void:
	var current := _settings.preset if _settings != null \
		else int(RenderSettings.Preset.HIGH)
	for i in _preset_btns.size():
		_preset_btns[i].set_pressed_no_signal(i == current)
		_preset_checks[i].visible = i == current
	SettingsPages.show_specs(self, RenderSettings.clamp_preset(current))
	_show_storage()
	_refresh_appearance()

## Reads the cache size from disk (a walk of the cache folders), so it
## runs when Settings is shown and after the cache changes, not on
## every refresh.
func _refresh_storage() -> void:
	_cache_bytes = OfflineDownloader.cache_size_bytes()
	_show_storage()

func _show_storage() -> void:
	var limit_mb := 2048
	if _limit_slider != null and _settings != null:
		_limit_slider.set_value_no_signal(float(_settings.pref("cache_limit_mb")))
		_limit_label.text = UiTheme.cache_size(int(_limit_slider.value) * 1048576)
		limit_mb = int(_limit_slider.value)
	if _usage != null:
		var size_text := UiTheme.cache_size(_cache_bytes)
		var gap := size_text.find(" ")
		_usage.set_value(size_text.substr(0, gap), size_text.substr(gap + 1))
		_usage_of.text = "of %s" % UiTheme.cache_size(limit_mb * 1048576)
		_usage_bar.value = clampf(float(_cache_bytes) / float(limit_mb * 1048576), 0.0, 1.0)
	_refresh_summaries()
