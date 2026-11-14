class_name MapLandmarks
extends Control

## Landmark markers on the map home: a HUD-glass dot with the kind's
## icon in ink at each landmark (curated registry from zoom 6, nearby
## articles from zoom 11). The selected one takes the accent fill with
## an on-accent icon (design system: active state on glass). Hovering
## shows a float-glass name chip, and clicking a marker toggles that
## chip (touch has no hover). Drawn in a child layer of MapTileView
## because the map's own canvas runs the recolour shader. Markers that
## would overlap a better-ranked one are left out, so dense cities stay
## readable. The map hit-tests taps against the placed markers.

const RADIUS := 13.0
const ICON := 15
const HIT_RADIUS := 22.0  # size-touch 44
const SPACING := 30.0
const CURATED_ZOOM := 6
const WIKI_ZOOM := 11

var selected_id := ""
var _map: MapTileView
var _curated: Array = []
var _wiki: Array = []
var _placed: Array = []  # [screen point, site], best ranked first
var _hover_id := ""
## Name chip shown by clicking a marker (touch has no hover): clicking
## the same marker again hides it. Hovering shows the chip regardless.
var _pinned_id := ""

func _init(map: MapTileView) -> void:
	_map = map
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for entry in LocationData.landmarks():
		_curated.append(LandmarkVisit.from_registry(entry))

## Nearby article sites (WikiFetcher.nearby), ranked best first.
func set_sites(sites: Array) -> void:
	_wiki = sites
	queue_redraw()

func sites() -> Array:
	var out := _curated.duplicate() if _map.zoom_level >= CURATED_ZOOM else []
	if _map.zoom_level >= WIKI_ZOOM:
		for s in _wiki:
			if not _near_curated(s):
				out.append(s)
	return out

## An article for a curated landmark is the same place: keep one marker.
func _near_curated(s: Dictionary) -> bool:
	for c in _curated:
		if LocationData.distance_m(float(c["lat"]), float(c["lon"]),
				float(s["lat"]), float(s["lon"])) < 150.0:
			return true
	return false

func screen_point(s: Dictionary) -> Vector2:
	var centre := TileFetcher.global_pixel(_map.centre_lat, _map.centre_lon, _map.zoom_level)
	return TileFetcher.global_pixel(float(s["lat"]), float(s["lon"]), _map.zoom_level) \
		- centre + _map._focus()

## Markers that fit on screen, best ranked first, none closer than SPACING.
func layout() -> Array:
	_placed.clear()
	var area := Rect2(Vector2.ZERO, _map.size).grow(RADIUS)
	for s in sites():
		var p := screen_point(s)
		if not area.has_point(p):
			continue
		var clear := true
		for item in _placed:
			if (item[0] as Vector2).distance_to(p) < SPACING:
				clear = false
				break
		if clear:
			_placed.append([p, s])
	return _placed

## The marker under `pos` (map coordinates), {} for none.
func hit_at(pos: Vector2) -> Dictionary:
	layout()
	var best: Dictionary = {}
	var best_d := HIT_RADIUS
	for item in _placed:
		var d := (item[0] as Vector2).distance_to(pos)
		if d <= best_d:
			best = item[1]
			best_d = d
	return best

## Clicking a marker toggles its name chip: shown when it was hidden,
## hidden when it was the pinned one. Returns whether it is shown now.
func toggle_chip(s: Dictionary) -> bool:
	var id := str(s.get("id", ""))
	if id == "":
		return false
	_pinned_id = "" if _pinned_id == id else id
	queue_redraw()
	return _pinned_id == id

## The marker under `pos` was clicked: toggle its chip, {} for none.
func toggle_at(pos: Vector2) -> Dictionary:
	var s := hit_at(pos)
	if not s.is_empty():
		toggle_chip(s)
	return s

## Whether the name chip for `id` is up (hovered, or pinned by a click).
func chip_shown(id: String) -> bool:
	return id != "" and (id == _hover_id or id == _pinned_id)

## Pointer moved over the map: highlight the marker under it.
func hover_at(pos: Vector2) -> bool:
	var s := hit_at(pos)
	var id := str(s.get("id", ""))
	if id != _hover_id:
		_hover_id = id
		queue_redraw()
	return id != ""

func _draw() -> void:
	var hover: Array = []
	var pinned: Array = []
	for item in layout():
		var s: Dictionary = item[1]
		var p: Vector2 = item[0]
		var on := str(s["id"]) == selected_id
		draw_circle(p + Vector2(0, 2), RADIUS + 1.0, Color(0, 0, 0, 0.28), true, -1.0, true)
		draw_circle(p, RADIUS, UiTheme.TEAL if on else HudStyle.GLASS_STRONG, true, -1.0, true)
		draw_circle(p, RADIUS, UiTheme.GLASS_EDGE, false, 1.0, true)
		var tex := UiIcon.texture(str(s.get("icon", "landmark")), ICON)
		if tex != null:
			draw_texture_rect(tex, Rect2(p - Vector2(ICON, ICON) / 2.0, Vector2(ICON, ICON)),
				false, UiTheme.ON_ACCENT if on else UiTheme.INK)
		if str(s["id"]) == _hover_id:
			hover = item
		elif str(s["id"]) == _pinned_id:
			pinned = item
	var chip := hover if not hover.is_empty() else pinned
	if not chip.is_empty():
		_draw_chip(chip[0], str(chip[1]["name"]))

func _draw_chip(p: Vector2, text: String) -> void:
	var font := UiTheme.sans(600)
	var fs := roundi(14 * UiTheme.text_scale)
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var box := Rect2(p + Vector2(-ts.x / 2.0 - 12.0, -RADIUS - 14.0 - ts.y - 8.0), ts + Vector2(24, 12))
	box.position.x = clampf(box.position.x, 8.0, maxf(size.x - box.size.x - 8.0, 8.0))
	draw_style_box(UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE, true), box)
	draw_string(font, box.position + Vector2(12, 6 + font.get_ascent(fs)), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.INK)
