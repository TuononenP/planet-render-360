class_name MapLandmarks
extends Control

## Landmark markers on the map home: a HUD-glass dot with the kind's
## icon in ink at each landmark (curated registry from zoom 6, nearby
## articles from zoom 11). The selected one takes the accent fill with
## an on-accent icon (design system: active state on glass). Hovering
## shows a float-glass chip with the name and a "kind · provenance"
## line, and clicking a marker toggles that chip (touch has no hover).
## Drawn in a child layer of MapTileView because the map's own canvas
## runs the recolour shader. Markers that would overlap a
## better-ranked one are left out, so dense cities stay readable. The
## map hit-tests taps against the placed markers.

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

## What a screen reader says for the hovered marker: the chip's lines
## as one line, "" when nothing is hovered (the map keeps its default).
func hover_text() -> String:
	if _hover_id == "":
		return ""
	for item in _placed:
		if str((item[1] as Dictionary).get("id", "")) == _hover_id:
			var lines := chip_lines(item[1])
			return "%s, %s" % [str(lines[0]), str(lines[1])]
	return ""

## The placed markers' categories, first-ranked first, one row each:
## what the map legend names. Only markers on screen count, so the
## legend mirrors the map.
func visible_categories() -> Array:
	var out: Array = []
	var seen := {}
	for item in layout():
		var s := item[1] as Dictionary
		var key := "%s|%s" % [str(s.get("kind", "")), str(s.get("icon", ""))]
		if not seen.has(key):
			seen[key] = true
			out.append([str(s.get("kind", "Landmark")), str(s.get("icon", "landmark"))])
	return out

## Pointer moved over the map: highlight the marker under it.
func hover_at(pos: Vector2) -> bool:
	var s := hit_at(pos)
	var id := str(s.get("id", ""))
	if id != _hover_id:
		_hover_id = id
		queue_redraw()
	return id != ""

## Markers the open chip covers read dimmed, so the chip's text
## stays legible where markers crowd.
const DIM_ALPHA := 0.3

func _draw() -> void:
	var hover: Array = []
	var pinned: Array = []
	var placed := layout()
	for item in placed:
		var s: Dictionary = item[1]
		if str(s["id"]) == _hover_id:
			hover = item
		elif str(s["id"]) == _pinned_id:
			pinned = item
	var chip := hover if not hover.is_empty() else pinned
	var cover := Rect2(-100000.0, -100000.0, 0.0, 0.0)
	if not chip.is_empty():
		cover = _chip_rect(chip[0], chip_lines(chip[1]))
	for item in placed:
		var s: Dictionary = item[1]
		var p: Vector2 = item[0]
		var on := str(s["id"]) == selected_id
		var a := DIM_ALPHA if cover.has_point(p) else 1.0
		draw_circle(p + Vector2(0, 2), RADIUS + 1.0, Color(0, 0, 0, 0.28 * a), true, -1.0, true)
		draw_circle(p, RADIUS, Color(UiTheme.TEAL if on else HudStyle.GLASS_STRONG, a), true, -1.0, true)
		draw_circle(p, RADIUS, Color(UiTheme.GLASS_EDGE, a), false, 1.0, true)
		var tex := UiIcon.texture(str(s.get("icon", "landmark")), ICON)
		if tex != null:
			draw_texture_rect(tex, Rect2(p - Vector2(ICON, ICON) / 2.0, Vector2(ICON, ICON)),
				false, Color(UiTheme.ON_ACCENT if on else UiTheme.INK, a))
	if not chip.is_empty():
		_draw_chip(chip[0], chip[1], cover)

## Where a site's marker data comes from, as the chip names it: the
## curated registry, a Wikipedia article, or OpenStreetMap.
static func provenance(s: Dictionary) -> String:
	match str(s.get("source", "")):
		"curated":
			return "Curated landmark"
		"wiki":
			return "Wikipedia"
		"osm":
			return "OpenStreetMap"
	return ""

## The hover chip's lines: the name, then "kind · provenance" (kind
## alone when the source is unknown, so a bare site still reads).
static func chip_lines(s: Dictionary) -> Array:
	var meta := str(s.get("kind", "Landmark"))
	var src := provenance(s)
	if src != "":
		meta += " · " + src
	return [str(s.get("name", "")), meta]

func _chip_rect(p: Vector2, lines: Array) -> Rect2:
	var title_font := UiTheme.sans(600)
	var meta_font := UiTheme.sans(400)
	var title_fs := roundi(14 * UiTheme.text_scale)
	var meta_fs := roundi(12 * UiTheme.text_scale)
	var title_ts := title_font.get_string_size(str(lines[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs)
	var meta_ts := meta_font.get_string_size(str(lines[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, meta_fs)
	var wide := maxf(title_ts.x, meta_ts.x)
	var box := Rect2(
		p + Vector2(-wide / 2.0 - 12.0, -RADIUS - 14.0 - (title_ts.y + 4.0 + meta_ts.y) - 12.0),
		Vector2(wide + 24.0, title_ts.y + 4.0 + meta_ts.y + 12.0))
	box.position.x = clampf(box.position.x, 8.0, maxf(size.x - box.size.x - 8.0, 8.0))
	return box

func _draw_chip(p: Vector2, s: Dictionary, box: Rect2) -> void:
	var lines := chip_lines(s)
	var title_font := UiTheme.sans(600)
	var meta_font := UiTheme.sans(400)
	var title_fs := roundi(14 * UiTheme.text_scale)
	var meta_fs := roundi(12 * UiTheme.text_scale)
	var title_ts := title_font.get_string_size(str(lines[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs)
	draw_style_box(UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true), box)
	draw_string(title_font, box.position + Vector2(12, 6 + title_font.get_ascent(title_fs)), str(lines[0]),
		HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, UiTheme.INK)
	draw_string(meta_font, box.position + Vector2(12, 6 + title_ts.y + 4.0 + meta_font.get_ascent(meta_fs)),
		str(lines[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, meta_fs, UiTheme.MUTED)

