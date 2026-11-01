class_name MiniMap
extends Control

## "Where am I looking": a small north-up map tile in a corner of the
## viewer, centred on the camera (it follows a walk), with the view cone
## drawn from the camera's heading and field of view. The tiles are the
## same OSM raster tiles and on-device cache as the picker's raster map,
## requested only for the few under the inset (tile usage policy), and
## recoloured into the live theme's map palette. Tapping it returns to the
## map (open_requested). The OpenStreetMap credit is the viewer's own
## attribution pill, always on screen.

signal open_requested

const ZOOM := 14
const SIZE_DESKTOP := 128.0
const SIZE_PHONE := 96.0
const CONE_R := 0.42  # of the inset's half-width
const SHADER := """
shader_type canvas_item;
""" + MapTileView.RECOLOUR + """
uniform vec2 box;
uniform float radius;
varying vec2 local;
void vertex() {
	local = VERTEX;
}
void fragment() {
	vec2 q = abs(local - box * 0.5) - (box * 0.5 - vec2(radius));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	COLOR = vec4(recolour(COLOR.rgb), COLOR.a * (1.0 - smoothstep(-1.0, 0.5, d)));
}
"""

var _view: View360
var _fetcher: TileFetcher
var _tiles: Dictionary = {}  # "z/x/y" -> Texture2D
var _layer: Control
var _over: Control
var _material: ShaderMaterial
var _origin_px := Vector2.ZERO
var _mpp := 1.0
var _last_px := Vector2(INF, INF)
var _last_heading := -1.0
var _last_fov := -1.0
var _has_place := false

func _init(view: View360) -> void:
	_view = view
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "Open the map"
	visible = false
	set_box(SIZE_DESKTOP)
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_layer.material = _material
	_layer.draw.connect(_draw_tiles)
	add_child(_layer)
	# Cone, camera and ring above the recoloured tiles, unrecoloured.
	_over = Control.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)
	focus_entered.connect(_over.queue_redraw)
	focus_exited.connect(_over.queue_redraw)
	restyle()

func _ready() -> void:
	_fetcher = TileFetcher.new()
	add_child(_fetcher)
	_fetcher.tile_ready.connect(func(z: int, x: int, y: int, tex: Texture2D) -> void:
		_tiles["%d/%d/%d" % [z, x, y]] = tex
		_layer.queue_redraw())

func set_box(px: float) -> void:
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	if _material != null:
		_material.set_shader_parameter("box", Vector2(px, px))

func restyle() -> void:
	MapTileView.apply_map_palette(_material)
	_material.set_shader_parameter("box", size)
	_material.set_shader_parameter("radius", float(UiTheme.RADIUS_M))
	if _layer != null:
		_layer.queue_redraw()
		_over.queue_redraw()

## A new place: the tile window is relative to its origin.
func set_place(data: LocationData) -> void:
	_has_place = data != null
	_tiles.clear()
	_last_px = Vector2(INF, INF)
	if data == null:
		return
	_origin_px = TileFetcher.global_pixel(data.latitude, data.longitude, ZOOM)
	_mpp = metres_per_pixel(data.latitude, ZOOM)

## Ground metres per tile pixel at `lat` (Web Mercator).
static func metres_per_pixel(lat: float, zoom: int) -> float:
	return 156543.03392 * cos(deg_to_rad(clampf(lat, -85.0, 85.0))) / float(1 << zoom)

## Global pixel of the camera: the place's origin plus its metres offset.
static func camera_pixel(origin_px: Vector2, east_m: float, south_m: float, mpp: float) -> Vector2:
	return origin_px + Vector2(east_m, south_m) / maxf(mpp, 0.001)

## Tiles (z, x, y) whose pixels fall in a `box`-wide window at `centre_px`.
static func wanted_tiles(centre_px: Vector2, box: float, zoom: int) -> Array[Vector3i]:
	var lo := (centre_px - Vector2(box, box) / 2.0) / 256.0
	var hi := (centre_px + Vector2(box, box) / 2.0) / 256.0
	var out: Array[Vector3i] = []
	for ty in range(int(floorf(lo.y)), int(floorf(hi.y)) + 1):
		for tx in range(int(floorf(lo.x)), int(floorf(hi.x)) + 1):
			out.append(Vector3i(zoom, tx, ty))
	return out

## Horizontal field of view (degrees) from the camera's vertical one.
static func horizontal_fov(vertical_deg: float, aspect: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(vertical_deg) / 2.0) * aspect))

func _cam_px() -> Vector2:
	var p := _view._rig.position
	return camera_pixel(_origin_px, p.x, p.z, _mpp)

func _process(_delta: float) -> void:
	if not visible or not _has_place or _view._rig == null or _view._rig.camera == null:
		return
	var px := _cam_px()
	if px.distance_to(_last_px) > 0.5:
		_last_px = px
		for t in wanted_tiles(px, size.x, ZOOM):
			if not _tiles.has("%d/%d/%d" % [t.x, t.y, t.z]):
				_fetcher.request_tile(t.x, t.y, t.z)
		_layer.queue_redraw()
	var heading := fposmod(rad_to_deg(-_view._rig.yaw), 360.0)
	var fov := _view._rig.camera.fov
	if absf(heading - _last_heading) > 0.5 or not is_equal_approx(fov, _last_fov) \
			or px != _last_px:
		_last_heading = heading
		_last_fov = fov
		accessibility_name = "Mini-map, facing %s. Opens the map" % _view._compass.readout()
		_over.queue_redraw()

func _draw_tiles() -> void:
	_layer.draw_rect(Rect2(Vector2.ZERO, size), Color(0.949, 0.937, 0.914))
	if not _has_place or _view._rig == null:
		return
	var px := _cam_px()
	var centre := size / 2.0
	for t in wanted_tiles(px, size.x, ZOOM):
		var key := "%d/%d/%d" % [t.x, t.y, t.z]
		if _tiles.has(key):
			var at := Vector2(t.y * 256.0, t.z * 256.0) - px + centre
			_layer.draw_texture_rect(_tiles[key], Rect2(at.snapped(Vector2.ONE), Vector2(256, 256)), false)

func _draw_over() -> void:
	var c := size / 2.0
	if _has_place and _view._rig != null and _view._rig.camera != null:
		var cam := _view._rig.camera
		var aspect := float(_view._viewport.size.x) / maxf(float(_view._viewport.size.y), 1.0)
		var half := deg_to_rad(horizontal_fov(cam.fov, aspect)) / 2.0
		var bearing := -_view._rig.yaw
		var r := size.x * CONE_R
		var pts := PackedVector2Array([c])
		for k in 9:
			var a := bearing - half + 2.0 * half * float(k) / 8.0
			pts.append(c + Vector2(sin(a), -cos(a)) * r)
		_over.draw_colored_polygon(pts, Color(UiTheme.TEAL, 0.38))
		_over.draw_polyline(PackedVector2Array([pts[1], c, pts[pts.size() - 1]]), UiTheme.TEAL, 1.5, true)
	_over.draw_circle(c, 5.0, UiTheme.TEAL, true, -1.0, true)
	_over.draw_circle(c, 5.0, UiTheme.INK, false, 2.0, true)
	var bold := UiTheme.sans(700)
	var halo := Color(UiTheme.SKY_000, 0.85)
	_over.draw_string_outline(bold, Vector2(c.x - 3.5, 14.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, halo)
	_over.draw_string(bold, Vector2(c.x - 3.5, 14.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiTheme.INK)
	# Glass edge over the tile corners.
	_over.draw_style_box(UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE),
		Rect2(Vector2.ZERO, size))
	if has_focus():
		_over.draw_style_box(UiTheme._focus_ring(UiTheme.RADIUS_M), Rect2(Vector2.ZERO, size))

func _gui_input(event: InputEvent) -> void:
	var tapped := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or event.is_action_pressed("ui_accept")
	if tapped:
		open_requested.emit()
		accept_event()
