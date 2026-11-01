class_name MapLandmarkHome
extends RefCounted

## Landmarks on the map home. Nearby articles are asked for once the map
## settles (the same pause as MapFacts), over the visible area out to
## 10 km, and drawn as MapLandmarks markers. Tapping one selects it like
## any place, and its LandmarkCard (no header, no Go: the panel names the
## selection and Explore stays the one primary) joins the selected place.
## Explore then renders from LandmarkVisit's standoff, facing it (main).
## Operates on the picker via `p`.

const PAUSE_S := 0.6

static func build(p: MapPicker) -> void:
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

## Select a tapped landmark: the pin, name and readouts follow it, and
## its details load into the card.
static func select(p: MapPicker, site: Dictionary) -> void:
	p._on_picked(float(site["lat"]), float(site["lon"]))
	p.selected_name = str(site["name"])
	p.selected_landmark = site
	p._refresh_labels()
	p._canvas.landmarks.selected_id = str(site["id"])
	p._canvas.landmarks.queue_redraw()
	p._landmark_box.visible = true
	p._landmark_card.visible = true
	p._landmark_card.show_site(site)

## Any other pick drops the landmark selection.
static func clear(p: MapPicker) -> void:
	p.selected_landmark = {}
	if p._landmark_box != null:
		p._landmark_box.visible = false
	if p._canvas != null and p._canvas.landmarks != null and p._canvas.landmarks.selected_id != "":
		p._canvas.landmarks.selected_id = ""
		p._canvas.landmarks.queue_redraw()
