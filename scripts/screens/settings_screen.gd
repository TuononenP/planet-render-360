class_name SettingsScreen
extends Control

## Settings (design system Layout → Settings): Appearance (theme,
## accent, the accessibility switches, layout), render quality (a preset
## trades accuracy for render time; see RenderSettings), Cache (size,
## limit, clear), Units, Data sources and About. Every choice applies at
## once and is saved on-device for the next launch. Rows are size-control
## tall on sky-200, separated by `line` (SettingsRows).

signal back_requested
signal preset_changed(preset: int)
signal accent_changed(index: int)
## 0 Auto, 1 Compact, 2 Wide: forces the stacked or two-column layout.
signal layout_changed(index: int)
## Units changed: screens showing numbers reformat them.
signal units_changed

## Set before a theme rebuild so Main reopens Settings afterwards.
static var reopen := false
const SOURCES := [
	["Map data", "© OpenStreetMap contributors · ODbL", "https://www.openstreetmap.org/copyright"],
	["Map tiles", "OpenStreetMap tile service", "https://operations.osmfoundation.org/policies/tiles/"],
	["Elevation", "AWS Terrain Tiles · EU-DEM / Copernicus, USGS 3DEP, SRTM", "https://github.com/tilezen/joerd/blob/master/docs/attribution.md"],
	["Imagery", "Esri, Vantor, Earthstar Geographics", "https://www.esri.com/en-us/legal/terms/web-site-service"],
	["Climate", "CHELSA V2.1 (Karger et al.) · CC BY 4.0", "https://chelsa-climate.org/"],
	["Weather", "Open-Meteo · CC BY 4.0", "https://open-meteo.com/en/license"],
	["Place search", "Nominatim · ODbL", "https://operations.osmfoundation.org/policies/nominatim/"],
	["Landmark details", "Wikipedia · CC BY-SA 4.0", "https://en.wikipedia.org/wiki/Wikipedia:Copyrights"],
	["Landmark photos", "Wikimedia Commons · credited on each photo", "https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia"],
	["Textures", "Poly Haven · CC0", "https://polyhaven.com/license"],
]
const LICENCES := [
	["Instrument Serif and Instrument Sans", "SIL Open Font License", "https://openfontlicense.org/"],
	["IBM Plex Mono", "SIL Open Font License", "https://openfontlicense.org/"],
	["Lucide icons", "ISC License", "https://lucide.dev/license"],
]

var _settings: RenderSettings
var _preset_btns: Array[Button] = []
var _summary_label: Label
var _storage_label: Label
var _margin: MarginContainer
var _grid: GridContainer
var _accent_btns: Array[Button] = []
var _layout_btns: Array[Button] = []
var _layout_index := 0
var _scroll: ScrollContainer
## First row of the Data sources section (show_data_sources).
var _sources_anchor: Control
var _theme_seg: SegmentedControl
var _text_seg: SegmentedControl
const TEXT_SCALES := [0.85, 1.0, 1.3, 1.5, 2.0]
var _layout_seg: SegmentedControl
var _unit_segs: Dictionary = {}  # pref key -> SegmentedControl
var _toggles: Dictionary = {}  # pref key -> Button
var _limit_slider: HSlider
var _limit_label: Label
var _godot_licence: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	_margin.add_child(outer)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	outer.add_child(header)
	var back := UiTheme.icon_button("")
	UiIcon.apply(back, "arrow-left", 22)
	back.tooltip_text = "Back to map"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var title := UiTheme.display_label("Settings", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	col.add_child(UiTheme.section_label("Appearance"))
	var look := SettingsRows.group()
	col.add_child(look)
	_theme_seg = SegmentedControl.new(["Night", "Day", "Match system"])
	_theme_seg.custom_minimum_size.x = 300
	_theme_seg.item_selected.connect(_on_theme)
	SettingsRows.add(look, SettingsRows.row("Theme", _theme_seg))
	var accent_box := VBoxContainer.new()
	accent_box.add_theme_constant_override("separation", 8)
	var accent_pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		accent_pad.add_theme_constant_override("margin_" + side, 16 if side in ["left", "right"] else 12)
	accent_pad.add_child(accent_box)
	accent_box.add_child(UiTheme.label("Accent", 15, UiTheme.INK))
	_choice_row(accent_box, UiTheme.theme_names + ["Auto"], _accent_btns,
		func(i: int) -> void:
			if i == UiTheme.AUTO_CHIP:
				UiTheme.auto_mode = true
			else:
				UiTheme.apply_palette(i)
			if _settings != null:
				_settings.set_accent(UiTheme.theme_index, UiTheme.auto_mode)
			accent_changed.emit(i))
	SettingsRows.add(look, accent_pad)
	for t in [["reduce_motion", "Reduce motion", "Cross-fades instead of camera flights, springs and morphs."],
			["solid_panels", "Solid panels", "Opaque panels instead of glass over the map and the scene."],
			["high_contrast", "Increase contrast", "Stronger text, lines and glass edges."]]:
		var key: String = t[0]
		var tog := SettingsRows.toggle(t[1], false, func(on: bool) -> void: _on_access(key, on), t[2])
		_toggles[key] = tog
		SettingsRows.add(look, tog)
	_text_seg = SegmentedControl.new(["85%", "100%", "130%", "150%", "200%"])
	_text_seg.custom_minimum_size.x = 300
	_text_seg.item_selected.connect(func(i: int) -> void:
		if _settings != null:
			_settings.set_pref("text_scale", TEXT_SCALES[i])
			_rebuild_app())
	SettingsRows.add(look, SettingsRows.row("Text size", _text_seg))
	_layout_seg = SegmentedControl.new(["Auto", "Compact", "Wide"])
	_layout_seg.custom_minimum_size.x = 260
	_layout_seg.item_selected.connect(func(i: int) -> void:
		_layout_index = i
		if _settings != null:
			_settings.set_layout(i)
		layout_changed.emit(i))
	_layout_btns = _layout_seg._buttons
	SettingsRows.add(look, SettingsRows.row("Layout", _layout_seg,
		"Auto follows the window. Compact and Wide force the phone or tablet arrangement."))

	col.add_child(UiTheme.section_label("Render quality"))
	var subtitle := UiTheme.label(
		"Higher quality renders terrain and places more accurately, but takes longer to build and more power to draw.",
		15, UiTheme.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(subtitle)
	_grid = GridContainer.new()
	_grid.columns = 1
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	col.add_child(_grid)
	var group := ButtonGroup.new()
	for p in RenderSettings.PRESET_NAMES.size():
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = group
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 124)
		btn.tooltip_text = RenderSettings.preset_name(p)
		_style_preset(btn)
		# Top-aligned text (a Button centres its own text, so cards with
		# shorter blurbs would drop their titles out of line).
		var level := "●".repeat(p + 1) + "○".repeat(RenderSettings.PRESET_NAMES.size() - p - 1)
		var tag := "  ·  Recommended" if p == int(RenderSettings.Preset.HIGH) else ""
		var card := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			card.add_theme_constant_override("margin_" + side, 18)
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override("separation", 4)
		card.add_child(lines)
		lines.add_child(UiTheme.label(RenderSettings.preset_name(p) + tag, 15, UiTheme.INK, true))
		lines.add_child(UiTheme.label(level, 13, UiTheme.MUTED))
		var blurb := UiTheme.label(RenderSettings.PRESET_BLURBS[p], 14, UiTheme.INK)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines.add_child(blurb)
		for l in lines.get_children():
			(l as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		SettingsRows._fill_button(btn, card, 124)
		var preset_value := p
		btn.pressed.connect(func() -> void: _select(preset_value))
		_preset_btns.append(btn)
		_grid.add_child(btn)
	_summary_label = UiTheme.label("", 14, UiTheme.TEAL, true)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_summary_label)
	var note := UiTheme.label(
		"Applies to the next place you render. A place already open keeps its terrain, but its render scale and shadows update straight away.",
		14, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)

	col.add_child(UiTheme.section_label("Cache"))
	var cache := SettingsRows.group()
	col.add_child(cache)
	_storage_label = UiTheme.label("", 14, UiTheme.MUTED)
	_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var storage_pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		storage_pad.add_theme_constant_override("margin_" + side, 16 if side in ["left", "right"] else 12)
	storage_pad.add_child(_storage_label)
	SettingsRows.add(cache, storage_pad)
	var limit_row := HBoxContainer.new()
	limit_row.add_theme_constant_override("separation", 12)
	_limit_slider = HSlider.new()
	_limit_slider.min_value = 256
	_limit_slider.max_value = 8192
	_limit_slider.step = 256
	_limit_slider.custom_minimum_size = Vector2(200, 44)
	_limit_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HudStyle.apply_slider(_limit_slider)
	_limit_slider.value_changed.connect(func(v: float) -> void:
		_limit_label.text = UiTheme.cache_size(int(v) * 1048576))
	_limit_slider.drag_ended.connect(func(_changed: bool) -> void: _on_cache_limit())
	limit_row.add_child(_limit_slider)
	_limit_label = UiTheme.data_label("", 15, UiTheme.MUTED)
	_limit_label.custom_minimum_size.x = 72
	limit_row.add_child(_limit_label)
	SettingsRows.add(cache, SettingsRows.row("Size limit", limit_row))
	var clear_pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		clear_pad.add_theme_constant_override("margin_" + side, 16 if side in ["left", "right"] else 12)
	var clear_cache_btn := SettingsRows.destructive("Clear cache")
	clear_cache_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	clear_cache_btn.pressed.connect(_confirm_clear)
	clear_pad.add_child(clear_cache_btn)
	SettingsRows.add(cache, clear_pad)

	col.add_child(UiTheme.section_label("Units"))
	var units := SettingsRows.group()
	col.add_child(units)
	for u in [["imperial", "Elevation", ["Metric", "Imperial"]],
			["dms", "Coordinates", ["Decimal", "Degrees, minutes, seconds"]],
			["clock_12h", "Time", ["24-hour", "12-hour"]]]:
		var key: String = u[0]
		var seg := SegmentedControl.new(u[2])
		seg.custom_minimum_size.x = 300
		seg.item_selected.connect(func(i: int) -> void: _on_unit(key, i == 1))
		_unit_segs[key] = seg
		SettingsRows.add(units, SettingsRows.row(u[1], seg))

	col.add_child(UiTheme.section_label("Data sources"))
	var sources := SettingsRows.group()
	col.add_child(sources)
	for src in SOURCES:
		var link := SettingsRows.link(src[0], src[1], src[2])
		SettingsRows.add(sources, link)
		if _sources_anchor == null:
			_sources_anchor = link

	col.add_child(UiTheme.section_label("About"))
	var about := SettingsRows.group()
	col.add_child(about)
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	var engine := Engine.get_version_info()
	SettingsRows.add(about, SettingsRows.row("Planet Render 360",
		UiTheme.data_label(version if version != "" else "Development build", 15, UiTheme.MUTED),
		"Built with Godot Engine %s" % engine.get("string", "")))
	for lic in LICENCES:
		SettingsRows.add(about, SettingsRows.link(lic[0], lic[1], lic[2]))
	var godot_row := SettingsRows.toggle("Godot Engine", false, func(on: bool) -> void:
		_godot_licence.get_parent().visible = on, "MIT License · show the licence text")
	SettingsRows.add(about, godot_row)
	_godot_licence = UiTheme.text(Engine.get_license_text(), "caption", UiTheme.MUTED)
	_godot_licence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lic_pad := MarginContainer.new()
	lic_pad.visible = false
	for side in ["left", "right", "top", "bottom"]:
		lic_pad.add_theme_constant_override("margin_" + side, 16)
	lic_pad.add_child(_godot_licence)
	SettingsRows.add(about, lic_pad)
	resized.connect(_on_resized)
	_on_resized()
	_refresh()

## Preset card: quiet glass until chosen, then an accent edge and tint
## (the pressed state doubles as the selected state).
func _style_preset(btn: Button) -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, UiTheme.INK)
	var base := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_L, UiTheme.LINE)
	base.set_content_margin_all(18)
	btn.add_theme_stylebox_override("normal", base)
	var hover := UiTheme.style(UiTheme.FIELD, UiTheme.RADIUS_L, Color(UiTheme.TEAL, 0.6))
	hover.set_content_margin_all(18)
	btn.add_theme_stylebox_override("hover", hover)
	var chosen := UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_L, UiTheme.TEAL, true)
	chosen.set_content_margin_all(18)
	chosen.set_border_width_all(2)
	chosen.shadow_color = Color(UiTheme.TEAL, 0.18)
	chosen.shadow_size = 12
	btn.add_theme_stylebox_override("pressed", chosen)
	btn.add_theme_stylebox_override("hover_pressed", chosen)
	var focus := UiTheme.style(Color.TRANSPARENT, 20, UiTheme.TEAL)
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", focus)

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
			chip.icon = null
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
		_text_seg.select(TEXT_SCALES.find(float(_settings.pref("text_scale"))))
		for key in _unit_segs:
			(_unit_segs[key] as SegmentedControl).select(1 if bool(_settings.pref(key)) else 0)
		for key in _toggles:
			var on := {"reduce_motion": UiPrefs.reduce_motion, "solid_panels": UiPrefs.solid_panels,
				"high_contrast": UiPrefs.high_contrast}.get(key, false) as bool
			(_toggles[key] as Button).set_pressed_no_signal(on)
			(_toggles[key] as Button).queue_redraw()

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
	if key != "reduce_motion":
		_rebuild_app()

func _rebuild_app() -> void:
	UiPrefs.apply(_settings)
	if is_inside_tree() and get_tree().current_scene != null \
			and get_tree().current_scene.scene_file_path != "":
		reopen = true
		get_tree().reload_current_scene.call_deferred()

func _on_unit(key: String, on: bool) -> void:
	if _settings == null:
		return
	_settings.set_pref(key, on)
	UiPrefs.apply(_settings)
	units_changed.emit()

func _on_cache_limit() -> void:
	if _settings == null:
		return
	_settings.set_pref("cache_limit_mb", int(_limit_slider.value))
	UiPrefs.apply(_settings)
	CacheStore.enforce_size_cap()
	_refresh_storage()

## Clear cache, behind a confirmation that shows what it frees.
func _confirm_clear() -> void:
	SettingsRows.confirm(self, "Clear cache?",
		"This frees %s. Saved places stay in History and download again when you open them."
			% UiTheme.cache_size(OfflineDownloader.cache_size_bytes()),
		"Clear cache", func() -> void:
			OfflineDownloader.clear_cache()
			_refresh_storage())

## Re-skin after an accent change (preset cards bake the palette in).
func refresh_theme() -> void:
	_refresh_appearance()
	for seg in [_theme_seg, _text_seg, _layout_seg] + _unit_segs.values():
		if seg != null:
			(seg as SegmentedControl).restyle()
	for key in _toggles:
		(_toggles[key] as Button).queue_redraw()
	for btn in _preset_btns:
		_style_preset(btn)
	if _summary_label != null:
		_summary_label.add_theme_color_override("font_color", UiTheme.TEAL)

func _on_resized() -> void:
	if _margin == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	var pad := Responsive.page_padding(layout)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad + 8)
	_margin.add_theme_constant_override("margin_bottom", pad)
	if _grid != null:
		_grid.columns = 4 if layout == Responsive.Layout.EXPANDED \
			else (2 if layout == Responsive.Layout.MEDIUM else 1)

## Opened from the viewer's attribution: scroll to Data sources.
func show_data_sources() -> void:
	if _scroll != null and _sources_anchor != null:
		await get_tree().process_frame
		_scroll.ensure_control_visible(_sources_anchor)

func bind_settings(settings: RenderSettings) -> void:
	_settings = settings
	_layout_index = settings.layout
	_refresh()

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
	if _summary_label != null:
		_summary_label.text = RenderSettings.summary_for(current)
	_refresh_appearance()
	_refresh_storage()

func _refresh_storage() -> void:
	if _limit_slider != null and _settings != null:
		_limit_slider.set_value_no_signal(float(_settings.pref("cache_limit_mb")))
		_limit_label.text = UiTheme.cache_size(int(_limit_slider.value) * 1048576)
	if _storage_label != null:
		_storage_label.text = "Downloaded places use %s on this device. Clearing frees the space; saved places stay in History and re-download when opened." \
			% UiTheme.cache_size(OfflineDownloader.cache_size_bytes())
