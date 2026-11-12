class_name SettingsPages
extends RefCounted

## The Settings pages (design system Screens → SettingsScreen; Privacy is PrivacyPage):
## each builder returns one category's page, wires its controls to the
## SettingsScreen `s` that owns them, and keeps the handles `s` needs to
## refresh and re-skin them. SettingsScreen shows one page at a time.

const SOURCES := [
	["Map data", "© OpenStreetMap contributors · ODbL", "https://www.openstreetmap.org/copyright"],
	["Map tiles", "OpenFreeMap © OpenMapTiles · MIT", "https://openfreemap.org/"],
	["Globe tiles", "OpenStreetMap tile service", "https://operations.osmfoundation.org/policies/tiles/"],
	["Elevation", "AWS Terrain Tiles · EU-DEM / Copernicus, USGS 3DEP, SRTM", "https://github.com/tilezen/joerd/blob/master/docs/attribution.md"],
	["Elevation, Helsinki", "© City of Helsinki, Elevation model 2021 · CC BY 4.0", "https://hri.fi/data/en/dataset/helsingin-korkeusmalli"],
	["Imagery", "Esri, Vantor, Earthstar Geographics", "https://www.esri.com/en-us/legal/terms/web-site-service"],
	["Land cover", "© ESA WorldCover project 2021 · contains modified Copernicus Sentinel data processed by the ESA WorldCover consortium · CC BY 4.0", "https://esa-worldcover.org/"],
	["Canopy height", "© Meta and World Resources Institute · source imagery © 2016 Vantor · CC BY 4.0", "https://registry.opendata.aws/dataforgood-fb-forestsv2/"],
	["Climate", "CHELSA V2.1 (Karger et al.) · CC BY 4.0", "https://chelsa-climate.org/"],
	["Climate fallback", "ERA5 (Copernicus) via Open-Meteo · CC BY 4.0", "https://open-meteo.com/en/license"],
	["Weather", "Open-Meteo · CC BY 4.0", "https://open-meteo.com/en/license"],
	["Place search", "Nominatim · ODbL", "https://operations.osmfoundation.org/policies/nominatim/"],
	["Capital locations", "GeoNames · CC BY 4.0", "https://www.geonames.org/about.html"],
	["Landmark details", "Wikipedia · CC BY-SA 4.0", "https://en.wikipedia.org/wiki/Wikipedia:Copyrights"],
	["Landmark photos", "Wikimedia Commons · credited on each photo", "https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia"],
	["Textures", "Poly Haven · CC0", "https://polyhaven.com/license"],
]
const LICENCES := [
	["Instrument Sans", "SIL Open Font License", "https://openfontlicense.org/"],
	["IBM Plex Mono", "SIL Open Font License", "https://openfontlicense.org/"],
	["Lucide icons", "ISC License", "https://lucide.dev/license"],
]
const LICENCE_DIR := "res://licenses/"
const LICENCE_FILES := ["instrument-sans-OFL.txt", "ibm-plex-mono-OFL.txt", "lucide-LICENSE.txt"]
const TEXT_SCALES := [0.85, 1.0, 1.3, 1.5, 2.0]
## One short line per preset card; the fidelity and first build sit
## beside it as dots and a number.
const PRESET_LINES := [
	"Coarser terrain, nearby detail only, no shadows.",
	"Balanced detail and speed, with shadows.",
	"Fine terrain, sharp imagery, shadows.",
	"Finest terrain, widest detail, far shadows. Needs a fast device.",
]
## Live samples under each unit row (Units page).
const SAMPLE_ELEVATION := 4478.0
const SAMPLE_LAT := 45.9763
const SAMPLE_LON := 7.6586
const SAMPLE_HOUR := 14.5334

## A page: the category's own groups, `space-6` apart.
static func _page() -> VBoxContainer:
	var p := VBoxContainer.new()
	p.add_theme_constant_override("separation", 24)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p

## An eyebrow-labelled section holding `body`, with an optional note.
static func _section(page: Control, eyebrow: String, body: Control, note: String = "") -> VBoxContainer:
	var sect := VBoxContainer.new()
	sect.add_theme_constant_override("separation", 8)
	if eyebrow != "":
		var e := UiTheme.section_label(eyebrow)
		sect.add_child(_inset(e))
	sect.add_child(body)
	if note != "":
		var n := UiTheme.label(note, 14, UiTheme.MUTED)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sect.add_child(_inset(n))
	page.add_child(sect)
	return sect

static func _inset(c: Control) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 4)
	m.add_theme_constant_override("margin_right", 4)
	m.add_child(c)
	return m

static func _pad(c: Control, h: int = 16, v: int = 12) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, h)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, v)
	m.add_child(c)
	return m

static func appearance(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var look := SettingsRows.group()
	s._theme_seg = SegmentedControl.new(["Night", "Day", "Match system"])
	s._theme_seg.custom_minimum_size.x = 300
	s._theme_seg.item_selected.connect(s._on_theme)
	SettingsRows.add(look, SettingsRows.row("Theme", s._theme_seg))
	var accent_box := VBoxContainer.new()
	accent_box.add_theme_constant_override("separation", 8)
	var accent_text := VBoxContainer.new()
	accent_text.add_theme_constant_override("separation", 0)
	accent_box.add_child(accent_text)
	accent_text.add_child(UiTheme.label("Accent", 15, UiTheme.INK))
	var hint := UiTheme.label("Auto follows the sun at the place you are looking at.", 14, UiTheme.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	accent_text.add_child(hint)
	s._choice_row(accent_box, UiTheme.theme_names + ["Auto"], s._accent_btns,
		func(i: int) -> void:
			if i == UiTheme.AUTO_CHIP:
				UiTheme.auto_mode = true
			else:
				UiTheme.apply_palette(i)
			if s._settings != null:
				s._settings.set_accent(UiTheme.theme_index, UiTheme.auto_mode)
			s.accent_changed.emit(i))
	SettingsRows.add(look, _pad(accent_box))
	_section(page, "", look)
	var advanced := SettingsRows.group()
	s._layout_seg = SegmentedControl.new(["Auto", "Compact", "Wide"])
	s._layout_seg.custom_minimum_size.x = 260
	s._layout_seg.item_selected.connect(func(i: int) -> void:
		s._layout_index = i
		if s._settings != null:
			s._settings.set_layout(i)
		s.layout_changed.emit(i)
		s._on_resized())
	s._layout_btns = s._layout_seg._buttons
	SettingsRows.add(advanced, SettingsRows.row("Layout", s._layout_seg,
		"Auto follows the window. Compact and Wide force the phone or tablet arrangement."))
	_section(page, "Advanced", advanced)
	return page

static func accessibility(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var group := SettingsRows.group()
	s._text_seg = SegmentedControl.new(["85%", "100%", "130%", "150%", "200%"])
	s._text_seg.custom_minimum_size.x = 300
	s._text_seg.item_selected.connect(func(i: int) -> void:
		if s._settings != null:
			s._settings.set_pref("text_scale", TEXT_SCALES[i])
			s._rebuild_app())
	SettingsRows.add(group, SettingsRows.row("Text size", s._text_seg))
	for t in [["reduce_motion", "Reduce motion", "Cross-fades instead of camera flights, springs and morphs."],
			["solid_panels", "Solid panels", "Opaque panels instead of glass over the map and the scene."],
			["high_contrast", "Increase contrast", "Stronger text, lines and glass edges."]]:
		var key: String = t[0]
		var tog := SettingsRows.toggle(t[1], false, func(on: bool) -> void: s._on_access(key, on), t[2])
		s._toggles[key] = tog
		SettingsRows.add(group, tog)
	_section(page, "", group)
	return page

## Render quality: the four preset cards (two columns when there is
## room), then the chosen preset's budget as Readouts.
static func quality(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	s._grid = GridContainer.new()
	s._grid.columns = 2
	s._grid.add_theme_constant_override("h_separation", 12)
	s._grid.add_theme_constant_override("v_separation", 12)
	page.add_child(s._grid)
	var group := ButtonGroup.new()
	for p in RenderSettings.PRESET_NAMES.size():
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = group
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.tooltip_text = "%s · Fidelity %d of 3" % [RenderSettings.preset_name(p), RenderSettings.fidelity_for(p)]
		style_preset(btn)
		var card := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			card.add_theme_constant_override("margin_" + side, 18)
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override("separation", 6)
		card.add_child(lines)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		lines.add_child(top)
		var name_l := UiTheme.text(RenderSettings.preset_name(p), "headline")
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_l)
		top.add_child(UiTheme.data_label(RenderSettings.FIRST_BUILD[p], 13, UiTheme.MUTED, true))
		var check := UiIcon.rect("check", 14, UiTheme.ON_ACCENT)
		var check_bg := PanelContainer.new()
		check_bg.add_theme_stylebox_override("panel", check_style())
		check_bg.custom_minimum_size = Vector2(22, 22)
		check_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var check_mid := CenterContainer.new()
		check_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_mid.add_child(check)
		check_bg.add_child(check_mid)
		top.add_child(check_bg)
		s._preset_checks.append(check_bg)
		var level := HBoxContainer.new()
		level.add_theme_constant_override("separation", 8)
		level.add_child(_dots(RenderSettings.fidelity_for(p)))
		var level_l := UiTheme.label("Fidelity %d" % RenderSettings.fidelity_for(p), 13, UiTheme.MUTED)
		level_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level.add_child(level_l)
		lines.add_child(level)
		var blurb := UiTheme.label(PRESET_LINES[p], 14, UiTheme.MUTED)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines.add_child(blurb)
		if p == int(RenderSettings.Preset.HIGH):
			var badge := _badge("Recommended")
			badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			lines.add_child(badge)
		for l in [lines, top] + lines.get_children() + top.get_children():
			(l as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		SettingsRows._fill_button(btn, card, 96)
		var preset_value := p
		btn.pressed.connect(func() -> void: s._select(preset_value))
		s._preset_btns.append(btn)
		s._grid.add_child(btn)
	var specs := GridContainer.new()
	s._specs_grid = specs
	specs.columns = 3
	specs.add_theme_constant_override("h_separation", 24)
	specs.add_theme_constant_override("v_separation", 16)
	for k in [["terrain", "Terrain"], ["buildings", "Buildings"], ["trees", "Trees"],
			["shadows", "Shadows"], ["scale", "Render scale"], ["revisit", "Revisit"]]:
		var r := Readout.new(k[1])
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s._specs[k[0]] = r
		specs.add_child(r)
	var spec_group := SettingsRows.group()
	SettingsRows.add(spec_group, _pad(specs, 18, 16))
	var sect := _section(page, "", spec_group,
		"Applies to the next place you render. A place already open keeps its terrain; render scale and shadows update straight away.")
	s._specs_title = UiTheme.section_label("")
	sect.add_child(_inset(s._specs_title))
	sect.move_child(sect.get_child(sect.get_child_count() - 1), 0)
	var fps_group := SettingsRows.group()
	var fps := SettingsRows.toggle("FPS counter", false,
		func(on: bool) -> void: s._on_viewer_pref("fps_counter", on),
		"Shows the frame rate in the corner of the 360° view (J).")
	s._toggles["fps_counter"] = fps
	SettingsRows.add(fps_group, fps)
	_section(page, "", fps_group)
	return page

## The accent disc behind the chosen card's check.
static func check_style() -> StyleBoxFlat:
	var st := UiTheme.style(UiTheme.TEAL, 11)
	st.set_content_margin_all(0)
	return st

## The chosen preset's budget, in the Readouts under the cards.
static func show_specs(s: SettingsScreen, p: int) -> void:
	if s._specs.is_empty():
		return
	s._specs_title.text = ("%s in detail" % RenderSettings.preset_name(p)).to_upper()
	var posts := RenderSettings.terrain_mesh_posts_for(p)
	(s._specs["terrain"] as Readout).set_value("%d × %d" % [posts, posts])
	(s._specs["buildings"] as Readout).set_value(UiTheme.grouped(RenderSettings.max_buildings_for(p)))
	(s._specs["trees"] as Readout).set_value(UiTheme.grouped(RenderSettings.vegetation_count_for(p, false)))
	(s._specs["shadows"] as Readout).set_value("On" if RenderSettings.shadows_for(p) else "Off")
	(s._specs["scale"] as Readout).set_value("%.0f %%" % (RenderSettings.render_scale_for(p) * 100.0))
	(s._specs["revisit"] as Readout).set_value(RenderSettings.REVISIT[p])

## Fidelity as three dots: filled ink, empty ink-muted rings.
static func _dots(n: int) -> Control:
	var d := Control.new()
	d.custom_minimum_size = Vector2(32, 10)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func() -> void:
		for i in 3:
			var c := Vector2(4.0 + i * 12.0, 5.0)
			if i < n:
				d.draw_circle(c, 4.0, UiTheme.INK, true, -1.0, true)
			else:
				d.draw_circle(c, 3.25, UiTheme.MUTED, false, 1.5, true))
	return d

## A neutral StatusBadge: ink-muted outline and word.
static func _badge(word: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_XS, UiTheme.MUTED)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", st)
	p.add_child(UiTheme.label(word, 13, UiTheme.MUTED, true))
	return p

## Preset card: solid sky-200 until chosen, then accent-soft with a 2px
## accent edge (the pressed state doubles as the selected state).
static func style_preset(btn: Button) -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, UiTheme.INK)
	var base := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_L, UiTheme.LINE)
	btn.add_theme_stylebox_override("normal", base)
	var hover := UiTheme.style(UiTheme.FIELD, UiTheme.RADIUS_L, Color(UiTheme.TEAL, 0.6))
	btn.add_theme_stylebox_override("hover", hover)
	var chosen := UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_L, UiTheme.TEAL)
	chosen.set_border_width_all(2)
	btn.add_theme_stylebox_override("pressed", chosen)
	btn.add_theme_stylebox_override("hover_pressed", chosen)
	var focus := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_L, UiTheme.FOCUS)
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", focus)

static func units(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var group := SettingsRows.group()
	for u in [["imperial", "Elevation", ["Metric", "Imperial"]],
			["dms", "Coordinates", ["Decimal", "Degrees, minutes, seconds"]],
			["clock_12h", "Time", ["24-hour", "12-hour"]]]:
		var key: String = u[0]
		var seg := SegmentedControl.new(u[2])
		seg.custom_minimum_size.x = 300
		seg.item_selected.connect(func(i: int) -> void: s._on_unit(key, i == 1))
		s._unit_segs[key] = seg
		var r := SettingsRows.row(u[1], seg, " ")
		s._unit_samples[key] = _row_description(r)
		SettingsRows.add(group, r)
	_section(page, "", group)
	return page

## The description label of a SettingsRows.row, for live samples.
static func _row_description(r: Control) -> Label:
	var text := r.get_child(0).get_child(0) as VBoxContainer
	return text.get_child(1) as Label

## The unit rows' samples, written in the chosen formats.
static func show_unit_samples(s: SettingsScreen) -> void:
	if s._unit_samples.is_empty():
		return
	(s._unit_samples["imperial"] as Label).text = UiTheme.elevation(SAMPLE_ELEVATION)
	(s._unit_samples["dms"] as Label).text = UiTheme.coords(SAMPLE_LAT, SAMPLE_LON)
	(s._unit_samples["clock_12h"] as Label).text = UiTheme.clock(SAMPLE_HOUR)

static func photos(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var group := SettingsRows.group()
	var stamp := SettingsRows.toggle("Stamp photos", true,
		func(on: bool) -> void: s._on_viewer_pref("photo_stamp", on),
		"Adds the place, coordinates, time and data credit to photos saved from the 360° view.")
	s._toggles["photo_stamp"] = stamp
	SettingsRows.add(group, stamp)
	_section(page, "", group)
	return page

## Storage: how much the cache holds in total (no size limit — nothing
## is removed automatically), a per-place list to clear one place at a
## time, then Clear cache for everything in its own group.
static func storage(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var group := SettingsRows.group()
	var usage := VBoxContainer.new()
	usage.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	usage.add_child(head)
	s._usage = Readout.new("Downloaded places", true)
	s._usage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(s._usage)
	SettingsRows.add(group, _pad(usage, 16, 16))
	_section(page, "", group, "Everything you open is kept on this device until you clear it. Nothing is removed automatically.")
	s._places_group = SettingsRows.group()
	s._places_note = UiTheme.label("", 14, UiTheme.MUTED)
	s._places_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s._places_note.visible = false
	var places_sect := _section(page, "Places", s._places_group,
		"Clearing a place frees its downloaded data and built world. The place stays in Saved places and downloads again when you open it.")
	places_sect.add_child(_inset(s._places_note))
	var clear := SettingsRows.group()
	var clear_col := VBoxContainer.new()
	clear_col.add_theme_constant_override("separation", 12)
	var clear_text := UiTheme.label("Saved places stay in History and download again when you open them.",
		14, UiTheme.MUTED)
	clear_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clear_col.add_child(clear_text)
	var clear_btn := SettingsRows.destructive("Clear cache")
	clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	clear_btn.pressed.connect(s._confirm_clear)
	clear_col.add_child(clear_btn)
	SettingsRows.add(clear, _pad(clear_col, 16, 16))
	_section(page, "", clear)
	return page

static func sources(_s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var group := SettingsRows.group()
	for src in SOURCES:
		SettingsRows.add(group, SettingsRows.link(src[0], src[1], src[2]))
	_section(page, "", group)
	return page

static func about(s: SettingsScreen) -> VBoxContainer:
	var page := _page()
	var group := SettingsRows.group()
	var engine := Engine.get_version_info()
	SettingsRows.add(group, SettingsRows.row("Planet Render 360",
		UiTheme.data_label(s.version_text(), 15, UiTheme.MUTED),
		"Built with Godot Engine %s" % engine.get("string", "")))
	SettingsRows.add(group, SettingsRows.link("Privacy policy",
		"The public page for the policy under Settings → Privacy", Brand.PRIVACY_URL))
	for lic in LICENCES:
		SettingsRows.add(group, SettingsRows.link(lic[0], lic[1], lic[2]))
	_licence_toggle(group, "Fonts and icons", "OFL and ISC · show the licence texts",
		_font_licence_text())
	_licence_toggle(group, "Godot Engine", "MIT License · show the licence text",
		Engine.get_license_text())
	_section(page, "", group)
	return page

## The licence texts shipped in licenses/ (the OFL asks for its text and
## copyright to travel with the fonts), one after another.
static func _font_licence_text() -> String:
	var parts: Array[String] = []
	for file in LICENCE_FILES:
		parts.append(FileAccess.get_file_as_string(LICENCE_DIR + file).strip_edges())
	return "\n\n\n".join(parts)

## A row that shows or hides a block of licence text under it.
static func _licence_toggle(group: PanelContainer, label: String, description: String, text: String) -> void:
	var pad := MarginContainer.new()
	SettingsRows.add(group, SettingsRows.toggle(label, false, func(on: bool) -> void:
		pad.visible = on, description))
	var body := UiTheme.text(text, "caption", UiTheme.MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pad.visible = false
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	pad.add_child(body)
	SettingsRows.add(group, pad)
