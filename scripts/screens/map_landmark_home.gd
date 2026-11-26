class_name MapLandmarkHome
extends RefCounted

## Landmarks on the map home. Nearby articles are asked for once the map
## settles (the same pause as MapFacts), over the visible area out to
## 10 km, and drawn as MapLandmarks markers. Tapping one selects it like
## any place, and its LandmarkCard (no header, no Go: the panel names the
## selection and Explore stays the one primary) joins the selected place.
## Explore then renders from LandmarkVisit's 50 m arrival, facing it (main).
## Operates on the picker via `p`.

const PAUSE_S := 0.6
## A tapped landmark is shown at least this close.
const SELECT_ZOOM := 13
## The marker key lists the categories on screen, first-ranked first.
const LEGEND_ICON := 18
const LEGEND_EMPTY := "Zoom in to see landmarks."

static func build(p: MapPicker) -> void:
	build_legend(p)
	p._wiki = WikiFetcher.new()
	p.add_child(p._wiki)
	p._wiki.nearby_ready.connect(func(_lat: float, _lon: float, _r: int, sites: Array) -> void:
		p._canvas.landmarks.set_sites(sites))
	p._landmark_timer = Timer.new()
	p._landmark_timer.one_shot = true
	p._landmark_timer.wait_time = PAUSE_S
	p._landmark_timer.timeout.connect(func() -> void: _fetch(p))
	p.add_child(p._landmark_timer)
	p._canvas.landmark_picked.connect(func(site: Dictionary) -> void: select(p, site))
	p._landmark_card = LandmarkCard.new(p._wiki, false, false)
	p._landmark_card.visible = false
	var gap := MarginContainer.new()
	gap.add_theme_constant_override("margin_top", 12)
	gap.add_child(p._landmark_card)
	p._landmark_box = gap
	p._landmark_box.visible = false
	p._info_col.add_child(gap)
	request(p)  # the opening view, before any pan

## The map moved or a place was picked: ask again after the pause.
static func request(p: MapPicker) -> void:
	if p._landmark_timer != null:
		p._landmark_timer.start()

static func _fetch(p: MapPicker) -> void:
	var map := p._canvas
	if map.zoom_level < MapLandmarks.WIKI_ZOOM or map.size == Vector2.ZERO:
		return
	var cell := Vector2(roundf(map.centre_lat * 100.0) / 100.0, roundf(map.centre_lon * 100.0) / 100.0)
	var radius := search_radius_m(map.centre_lat, map.zoom_level, map.size)
	var key := "%.2f,%.2f,%d" % [cell.x, cell.y, radius]
	if key == p._landmark_key:
		return
	p._landmark_key = key
	p._wiki.nearby(cell.x, cell.y, radius)

## Metres from the map centre to its corner, in 1 km steps (so nearby
## views share a cached answer), at most GeoSearch's 10 km.
static func search_radius_m(lat: float, zoom: int, view: Vector2) -> int:
	var m_per_px := 156543.03 * cos(deg_to_rad(lat)) / pow(2.0, zoom)
	var r := view.length() / 2.0 * m_per_px
	return clampi(int(ceil(r / 1000.0)) * 1000, 1000, 10000)

## Select a tapped landmark: the pin, name and readouts follow it, the
## map zooms in to SELECT_ZOOM if it is further out, and its details load
## into the card.
static func select(p: MapPicker, site: Dictionary) -> void:
	# Small islands (Suomenlinna) are missing from the map data below this
	# zoom, which left the pin in open water.
	p._canvas.zoom_level = maxi(p._canvas.zoom_level, SELECT_ZOOM)
	p._on_picked(float(site["lat"]), float(site["lon"]))
	p.selected_name = str(site["name"])
	p.selected_landmark = site
	p._refresh_labels()
	p._canvas.landmarks.selected_id = str(site["id"])
	p._canvas.landmarks.queue_redraw()
	p._landmark_box.visible = true
	p._landmark_card.visible = true
	p._landmark_card.show_site(site)

## The marker key: a toggle in the map's bottom-left corner opening the
## categories the placed markers use right now (first-ranked first),
## rebuilt on every opening so it mirrors the map. The attribution
## keeps the bottom-right.
static func build_legend(p: MapPicker) -> void:
	# The sheet covers the map's left and bottom in the stacked
	# layouts, so the key lives on the right edge, under the zoom rail:
	# the one map corner that stays visible everywhere.
	p._legend_btn = UiIcon.button("list", "Marker key")
	p._legend_btn.anchor_left = 1.0
	p._legend_btn.anchor_right = 1.0
	p._legend_btn.anchor_top = 0.62
	p._legend_btn.anchor_bottom = 0.62
	p._legend_btn.offset_left = -64.0
	p._legend_btn.offset_top = -24.0
	p._legend_btn.offset_right = -16.0
	p._legend_btn.offset_bottom = 24.0
	p._legend_btn.pressed.connect(func() -> void: toggle_legend(p))
	p._map_wrap.add_child(p._legend_btn)
	p._legend_panel = PanelContainer.new()
	p._legend_panel.add_theme_stylebox_override("panel",
		UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true))
	p._legend_panel.visible = false
	p._legend_rows = VBoxContainer.new()
	p._legend_rows.add_theme_constant_override("separation", 8)
	p._legend_panel.add_child(_legend_margin(p._legend_rows))
	p._map_wrap.add_child(p._legend_panel)
	p._canvas.resized.connect(func() -> void:
		if p._legend_panel.visible:
			_place_legend(p))
	# The rows' minimum size settles after the layout pass, so the
	# first opening re-seats the panel once it does.
	p._legend_panel.minimum_size_changed.connect(func() -> void:
		if p._legend_panel.visible:
			_place_legend(p))

static func _legend_margin(rows: Control) -> Control:
	var pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 14)
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 10)
	pad.add_child(rows)
	return pad

## The panel sits above the attribution chip, against the right
## gutter, sized to its rows.
static func _place_legend(p: MapPicker) -> void:
	var panel := p._legend_panel
	panel.size = panel.get_combined_minimum_size()
	panel.position = Vector2(
		p._map_wrap.size.x - 16.0 - panel.size.x,
		maxf(0.0, p._canvas.size.y - 48.0 - 8.0 - panel.size.y))

## Open or close the key, rebuilding its rows from the markers placed
## now; closing leaves the toggle where it was.
static func toggle_legend(p: MapPicker) -> void:
	if p._legend_panel.visible:
		p._legend_panel.visible = false
		return
	for child in p._legend_rows.get_children():
		p._legend_rows.remove_child(child)
		child.queue_free()
	var cats := p._canvas.landmarks.visible_categories()
	if cats.is_empty():
		p._legend_rows.add_child(UiTheme.text(LEGEND_EMPTY, "body-s", UiTheme.MUTED))
	else:
		for c in cats.slice(0, 10):
			p._legend_rows.add_child(_legend_row(str(c[0]), str(c[1])))
		if cats.size() > 10:
			var more := UiTheme.text("+%d more" % (cats.size() - 10), "body-s", UiTheme.MUTED)
			more.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p._legend_rows.add_child(more)
	p._legend_panel.visible = true
	_place_legend(p)

static func _legend_row(kind: String, icon: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := UiIcon.rect(icon, LEGEND_ICON, UiTheme.INK)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	var label := UiTheme.text(kind, "body-s")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	return row

## Any other pick drops the landmark selection.
static func clear(p: MapPicker) -> void:
	p.selected_landmark = {}
	if p._landmark_box != null:
		p._landmark_box.visible = false
	if p._canvas != null and p._canvas.landmarks != null and p._canvas.landmarks.selected_id != "":
		p._canvas.landmarks.selected_id = ""
		p._canvas.landmarks.queue_redraw()
