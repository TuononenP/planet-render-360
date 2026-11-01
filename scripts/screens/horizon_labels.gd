class_name HorizonLabels
extends Control

## PeakFinder-style names along the skyline: the peaks, towns and lakes
## around the place (HorizonFetcher), each set at its projected spot with
## a leader line, its name and a data line ("3,967 m · 41 km"). Only what
## the terrain does not hide from the camera shows (a coarse line-of-sight
## over the built ground and the far DEM), the most prominent first, at
## most MAX_LABELS and never overlapping. A toggle in the HUD (N); the
## names are fetched the first time it is on for a place.

const MAX_LABELS := 14
const MAX_LABELS_PHONE := 8
const RANGE_M := 48000.0
const MIN_RANGE_M := 120.0
const LOS_STEPS := 24
const LOS_BUDGET := 24  # sites checked per frame
const LIFT_M := {"Peak": 0.0, "City": 60.0, "Town": 30.0, "Village": 15.0, "Lake": 20.0}
const FONT_SIZE := 13
const LEADER_MIN := 18.0
const ROW_GAP := 20.0

var enabled := false
var _view: View360
var _data: LocationData
var _ground: GroundTruth
var _surf := {}
var _fetcher: HorizonFetcher
var _items: Array = []  # {name, kind, ele_m, pos: Vector3, line: String...}
var _fetched_for := Vector2(INF, INF)
var _los := {}  # item index -> bool, for _los_key
var _los_key := Vector2i(1 << 30, 1 << 30)
var _los_pending := false
var _last_cam := Transform3D()
var _last_fov := 0.0
var _drawn: Array = []  # [{rect, name}] of the last frame, for tests

func _init(view: View360) -> void:
	_view = view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

func _ready() -> void:
	_fetcher = HorizonFetcher.new()
	add_child(_fetcher)
	_fetcher.finished.connect(_on_sites)

## A new place: forget the last one's names (fetched again when on).
func set_place(data: LocationData, ground: GroundTruth) -> void:
	_data = data
	_ground = ground
	_surf = {}
	_items.clear()
	_los.clear()
	_fetched_for = Vector2(INF, INF)
	_drawn.clear()
	if _fetcher != null:
		_fetcher.cancel()
	if enabled:
		_request()
	queue_redraw()

func set_enabled(on: bool) -> void:
	enabled = on
	visible = on
	if on:
		_request()
	queue_redraw()

func labels_shown() -> Array:
	return _drawn

func item_count() -> int:
	return _items.size()

func _request() -> void:
	if _data == null or _fetcher == null or not is_inside_tree():
		return
	var at := Vector2(_data.latitude, _data.longitude)
	if _fetched_for == at:
		return
	_fetched_for = at
	_fetcher.fetch(at.x, at.y)

func _on_sites(sites: Array) -> void:
	_items.clear()
	_los.clear()
	if _data == null:
		return
	for s in sites:
		var xz := WorldScale.xz_from_latlon(float(s["lat"]), float(s["lon"]),
			_data.latitude, _data.longitude)
		if xz.length() < MIN_RANGE_M or xz.length() > RANGE_M:
			continue
		var kind := str(s["kind"])
		var y := _terrain_y(xz.x, xz.y) + float(LIFT_M.get(kind, 0.0))
		_items.append({"name": str(s["name"]), "kind": kind, "ele_m": float(s["ele_m"]),
			"pos": Vector3(xz.x, y, xz.y)})
	queue_redraw()

## Rendered terrain height (render Y) at metre position (x, z): the built
## ground inside the detailed extent, the far DEM outside it.
func _terrain_y(x: float, z: float) -> float:
	if _ground == null:
		return 0.0
	if _ground.is_inside(x, z):
		return _ground.height_at_world(x, z)
	if _surf.is_empty():
		_surf = FarTerrainBuilder._surface(_data)
	return FarTerrainBuilder._blend_height(_data, _ground, _surf, x, z)

# --- Line of sight ---

## Whether `target` can be seen from `origin`: no sampled terrain along the
## way stands above the sight line by more than a tolerance that grows
## with distance (the far DEM is coarse). `height` maps (x, z) -> render Y.
static func line_of_sight(origin: Vector3, target: Vector3, height: Callable, steps: int = LOS_STEPS) -> bool:
	var span := target - origin
	var dist := Vector2(span.x, span.z).length()
	for i in range(1, steps):
		var k := float(i) / float(steps)
		# Denser near the camera, where a ridge hides the most.
		k = k * k
		var p := origin + span * k
		var s := dist * k
		if float(height.call(p.x, p.z)) > p.y + 6.0 + 0.012 * s:
			return false
	return true

func _visible(i: int, cam_pos: Vector3) -> bool:
	var key := Vector2i(roundi(cam_pos.x / 8.0), roundi(cam_pos.z / 8.0))
	if key != _los_key:
		_los_key = key
		_los.clear()
	if not _los.has(i):
		_los[i] = line_of_sight(cam_pos, (_items[i] as Dictionary)["pos"], _terrain_y)
	return bool(_los[i])

# --- Layout and drawing ---

func _process(_delta: float) -> void:
	if not enabled or _items.is_empty() or _view._rig == null or _view._rig.camera == null:
		return
	var cam := _view._rig.camera
	if cam.global_transform != _last_cam or not is_equal_approx(cam.fov, _last_fov):
		_last_cam = cam.global_transform
		_last_fov = cam.fov
		queue_redraw()
	elif _los_pending:
		queue_redraw()

## The labels to draw this frame: [{item, anchor, rect, line1, line2}],
## most prominent first, none overlapping each other or the `avoid` rects
## (the controls bar, the mini-map, the sheets).
func layout_labels(cam: Camera3D, area: Vector2, font: Font, data_font: Font, phone: bool,
		avoid: Array = []) -> Array:
	var origin := cam.global_position
	var forward := -cam.global_transform.basis.z
	var cands: Array = []
	var budget := LOS_BUDGET
	_los_pending = false
	for i in _items.size():
		var it: Dictionary = _items[i]
		var pos: Vector3 = it["pos"]
		if cam.is_position_behind(pos):
			continue
		var d := Vector2(pos.x - origin.x, pos.z - origin.z).length()
		if d < MIN_RANGE_M:
			continue
		var pt := cam.unproject_position(pos)
		if pt.x < 12.0 or pt.x > area.x - 12.0 or pt.y < 56.0 or pt.y > area.y - 40.0 \
				or _covered(Rect2(pt - Vector2(6, 6), Vector2(12, 12)), avoid):
			continue
		if not _los.has(i) or _los_key != Vector2i(roundi(origin.x / 8.0), roundi(origin.z / 8.0)):
			if budget <= 0:
				_los_pending = true
				continue
			budget -= 1
		if not _visible(i, origin):
			continue
		var angle := rad_to_deg(atan2(pos.y - origin.y, d))
		cands.append({"i": i, "pt": pt, "dist": d, "score": prominence(it, d, angle),
			"ahead": forward.angle_to((pos - origin).normalized())})
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	var placed: Array = []
	var limit := MAX_LABELS_PHONE if phone else MAX_LABELS
	for c in cands:
		if placed.size() >= limit:
			break
		var it: Dictionary = _items[int(c["i"])]
		var line1 := str(it["name"])
		var line2 := data_line(it, float(c["dist"]))
		var w := maxf(font.get_string_size(line1, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x,
			data_font.get_string_size(line2, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2).x)
		var h := float(FONT_SIZE) * 2.0 + 4.0
		var pt: Vector2 = c["pt"]
		var rect := Rect2()
		var ok := false
		for row in 4:
			var top := pt.y - LEADER_MIN - h - ROW_GAP * float(row)
			rect = Rect2(Vector2(clampf(pt.x - w / 2.0, 6.0, area.x - w - 6.0), maxf(top, 6.0)), Vector2(w, h))
			if not _overlaps(rect, placed) and not _covered(rect, avoid):
				ok = true
				break
		if ok:
			placed.append({"item": it, "anchor": pt, "rect": rect, "line1": line1, "line2": line2})
	return placed

static func _covered(rect: Rect2, avoid: Array) -> bool:
	for a in avoid:
		if rect.intersects(a as Rect2):
			return true
	return false

static func _overlaps(rect: Rect2, placed: Array) -> bool:
	var grown := rect.grow(4.0)
	for p in placed:
		if grown.intersects((p as Dictionary)["rect"] as Rect2):
			return true
	return false

## How worth showing a site is from here: peaks by how high they stand
## in the view (angle above the horizon) and their height, places by size
## and nearness, lakes by nearness.
static func prominence(item: Dictionary, dist_m: float, angle_deg: float) -> float:
	var kind := str(item["kind"])
	var near := 1.0 / (1.0 + dist_m / 8000.0)
	match kind:
		"Peak":
			return 10.0 + angle_deg * 4.0 + maxf(float(item["ele_m"]), 0.0) / 400.0
		"City":
			return 9.0 + 6.0 * near
		"Town":
			return 6.0 + 6.0 * near
		"Lake":
			return 5.0 + 6.0 * near
	return 2.0 + 6.0 * near

## "3,967 m · 41 km": elevation (peaks) and ground distance.
static func data_line(item: Dictionary, dist_m: float) -> String:
	var km := "%.1f km" % (dist_m / 1000.0) if dist_m < 10000.0 else "%d km" % roundi(dist_m / 1000.0)
	if UiTheme.units_imperial:
		var mi := dist_m / 1609.34
		km = "%.1f mi" % mi if mi < 10.0 else "%d mi" % roundi(mi)
	if float(item["ele_m"]) > 0.0:
		return "%s · %s" % [UiTheme.elevation(float(item["ele_m"])), km]
	return km

func _draw() -> void:
	_drawn.clear()
	if not enabled or _items.is_empty() or _view._rig == null or _view._rig.camera == null:
		return
	var font := UiTheme.sans(600)
	var data_font := UiTheme.data(true)
	var phone := Responsive.layout_for_size(_view.size) == Responsive.Layout.COMPACT
	var labels := layout_labels(_view._rig.camera, size, font, data_font, phone, _hud_rects())
	var ink := UiTheme.INK
	var halo := Color(UiTheme.SKY_000, 0.85)
	for l in labels:
		var rect: Rect2 = l["rect"]
		var anchor: Vector2 = l["anchor"]
		var kind := str((l["item"] as Dictionary)["kind"])
		var from := Vector2(clampf(anchor.x, rect.position.x + 4.0, rect.end.x - 4.0), rect.end.y + 2.0)
		draw_line(from, anchor, halo, 3.0, true)
		draw_line(from, anchor, Color(ink, 0.8), 1.0, true)
		_draw_marker(anchor, kind, ink, halo)
		var name_text := str(l["line1"])
		var base1 := rect.position + Vector2(0, float(FONT_SIZE))
		draw_string_outline(font, base1, name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, halo)
		draw_string(font, base1, name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, ink)
		var base2 := rect.position + Vector2(0, float(FONT_SIZE) * 2.0 + 2.0)
		var data_text := str(l["line2"])
		draw_string_outline(data_font, base2, data_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2, 3, halo)
		draw_string(data_font, base2, data_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2, UiTheme.MUTED)
		_drawn.append({"rect": rect, "name": name_text})

## The parts of the HUD that stand over the scene right now.
func _hud_rects() -> Array:
	var out: Array = []
	if _view._fade != null and _view._fade.visible and _view._fade.modulate.a > 0.1:
		for c: Control in [_view._sheet, _view._weather_chip, _view._quality_badge, _view._compass]:
			if c != null and c.is_visible_in_tree():
				out.append(Rect2(c.global_position - _view.global_position, c.size).grow(4.0))
	for c: Control in [_view._minimap, _view._date_picker, _view._landmark_panel]:
		if c != null and c.is_visible_in_tree():
			out.append(Rect2(c.global_position - _view.global_position, c.size).grow(4.0))
	return out

func _draw_marker(at: Vector2, kind: String, ink: Color, halo: Color) -> void:
	if kind == "Peak":
		var tri := PackedVector2Array([at + Vector2(0, -5), at + Vector2(5, 4), at + Vector2(-5, 4)])
		draw_colored_polygon(tri, UiTheme.TEAL)
		draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), halo, 1.5, true)
	else:
		draw_circle(at, 4.0, UiTheme.TEAL, true, -1.0, true)
		draw_circle(at, 4.0, ink, false, 1.5, true)
