class_name GlobeView
extends Control

## The map home's hero (design system MapHome): the Earth as a globe.
## A canvas shader draws an orthographic sphere that samples a Web
## Mercator world image built from the OSM z2 tiles (16 tiles, cached on
## device like every picker tile) and recolours it like the flat map, so
## the globe and the map read as one surface. Drag turns it, a tap picks
## the point under it, and zooming in hands over to the flat map
## (`zoom_to_map`). `spin` turns it slowly on its own (onboarding).

signal picked(lat: float, lon: float)
signal zoom_to_map(lat: float, lon: float)

const ZOOM := 2
const TILES := 4  # 1 << ZOOM
const SHADER := """
shader_type canvas_item;
uniform sampler2D world : filter_linear, repeat_enable;
uniform vec2 centre;  // radians: latitude, longitude
uniform vec2 rect_size;
uniform vec2 disc_centre;  // local points
uniform float radius;
uniform vec4 backdrop : source_color;
uniform vec4 halo : source_color;
uniform bool day = false;
""" + MapTileView.RECOLOUR + """
void fragment() {
	vec4 tint = COLOR;  // modulate, so the globe can cross-fade
	vec2 p = (UV * rect_size - disc_centre) / radius;
	float r2 = dot(p, p);
	if (r2 > 1.0) {
		float glow = smoothstep(1.12, 1.0, sqrt(r2));
		COLOR = mix(backdrop, halo, glow * halo.a) * tint;
	} else {
		vec3 v = vec3(p.x, -p.y, sqrt(1.0 - r2));
		float cp = cos(centre.x), sp = sin(centre.x);
		float cl = cos(centre.y), sl = sin(centre.y);
		vec3 a = vec3(v.x, v.y * cp + v.z * sp, -v.y * sp + v.z * cp);
		vec3 w = vec3(a.x * cl + a.z * sl, a.y, -a.x * sl + a.z * cl);
		float lat = asin(clamp(w.y, -1.0, 1.0));
		float lon = atan(w.x, w.z);
		float merc = log(tan(0.7853982 + clamp(lat, -1.4835, 1.4835) * 0.5));
		vec2 uv = vec2((lon + 3.1415927) / 6.2831853, clamp((1.0 - merc / 3.1415927) * 0.5, 0.0, 1.0));
		vec3 c = recolour(texture(world, uv).rgb);
		// Limb darkening so it reads as a sphere, not a disc.
		c = mix(c, backdrop.rgb, pow(1.0 - v.z, 2.0) * 0.55);
		COLOR = vec4(c, 1.0) * tint;
	}
}
"""

var centre := Vector2(48.8566, 2.3522)  # degrees: lat, lon
var pin := Vector2(48.8566, 2.3522)
var spin := 0.0  # degrees per second
## Moves the disc into the part of the map no panel covers (as
## MapTileView.focus_offset does for the pin).
var focus_offset := Vector2.ZERO
var _image: Image
var _texture: ImageTexture
var _fetcher: TileFetcher
var _mat: ShaderMaterial
var _drag_moved := 0.0
var _down := false
var _touches: Dictionary = {}  # touch index -> position
var _pinch_base := 0.0
var _pin_layer: Control  # unshaded: the material would shade the pin as sphere

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_image = Image.create(256 * TILES, 256 * TILES, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0.6, 0.75, 0.88))  # sea until tiles land
	_texture = ImageTexture.create_from_image(_image)
	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("world", _texture)
	_mat.set_shader_parameter("day", UiTheme.is_day)
	_mat.set_shader_parameter("backdrop", UiTheme.SKY_000)
	_mat.set_shader_parameter("halo", Color(UiTheme.HORIZON_DAY, 0.35))
	material = _mat
	_pin_layer = Control.new()
	_pin_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_layer.draw.connect(_draw_pin)
	add_child(_pin_layer)
	visibility_changed.connect(_load_tiles)
	_load_tiles()

## The world image's tiles, fetched the first time the globe shows.
func _load_tiles() -> void:
	if _fetcher != null or not is_visible_in_tree():
		return
	_fetcher = TileFetcher.new()
	add_child(_fetcher)
	_fetcher.tile_ready.connect(_on_tile)
	for y in TILES:
		for x in TILES:
			_fetcher.request_tile(ZOOM, x, y)

func _on_tile(z: int, x: int, y: int, tex: Texture2D) -> void:
	if z != ZOOM or tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	img.convert(Image.FORMAT_RGBA8)
	_image.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x * 256, y * 256))
	_texture.update(_image)

func _radius() -> float:
	return minf(size.x, size.y) * 0.38

func _disc_centre() -> Vector2:
	return size / 2.0 + focus_offset

func _process(delta: float) -> void:
	if spin != 0.0 and is_visible_in_tree():
		centre.y = wrapf(centre.y + spin * delta, -180.0, 180.0)
		queue_redraw()

func _draw() -> void:
	_mat.set_shader_parameter("centre", Vector2(deg_to_rad(centre.x), deg_to_rad(centre.y)))
	_mat.set_shader_parameter("rect_size", size)
	_mat.set_shader_parameter("disc_centre", _disc_centre())
	_mat.set_shader_parameter("radius", _radius())
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
	if _pin_layer != null:
		_pin_layer.queue_redraw()

func _draw_pin() -> void:
	var at := project(pin)
	if at.x >= 0.0:
		_pin_layer.draw_circle(at, 16.0, UiTheme.TEAL_SOFT, true, -1.0, true)
		_pin_layer.draw_circle(at, 6.0, UiTheme.TEAL, true, -1.0, true)
		_pin_layer.draw_circle(at, 6.0, UiTheme.SKY_000, false, 2.0, true)

## Screen point of (lat, lon) in degrees, or (-1, -1) on the far side.
func project(ll: Vector2) -> Vector2:
	var la := deg_to_rad(ll.x)
	var lo := deg_to_rad(ll.y)
	var w := Vector3(cos(la) * sin(lo), sin(la), cos(la) * cos(lo))
	var l0 := deg_to_rad(centre.y)
	var p0 := deg_to_rad(centre.x)
	var a := Vector3(w.x * cos(l0) - w.z * sin(l0), w.y, w.x * sin(l0) + w.z * cos(l0))
	var v := Vector3(a.x, a.y * cos(p0) - a.z * sin(p0), a.y * sin(p0) + a.z * cos(p0))
	if v.z <= 0.0:
		return Vector2(-1, -1)
	return _disc_centre() + Vector2(v.x, -v.y) * _radius()

## (lat, lon) in degrees under a screen point, or NAN off the disc.
func unproject(at: Vector2) -> Vector2:
	var p := (at - _disc_centre()) / _radius()
	var r2 := p.length_squared()
	if r2 > 1.0:
		return Vector2(NAN, NAN)
	var v := Vector3(p.x, -p.y, sqrt(1.0 - r2))
	var p0 := deg_to_rad(centre.x)
	var l0 := deg_to_rad(centre.y)
	var a := Vector3(v.x, v.y * cos(p0) + v.z * sin(p0), -v.y * sin(p0) + v.z * cos(p0))
	var w := Vector3(a.x * cos(l0) + a.z * sin(l0), a.y, -a.x * sin(l0) + a.z * cos(l0))
	return Vector2(rad_to_deg(asin(clampf(w.y, -1.0, 1.0))), rad_to_deg(atan2(w.x, w.z)))

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_to_map.emit(centre.x, centre.y)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_down = true
				_drag_moved = 0.0
			elif _down:
				_down = false
				if _drag_moved < 6.0:
					var ll := unproject(mb.position)
					if not is_nan(ll.x):
						pin = ll
						queue_redraw()
						picked.emit(ll.x, ll.y)
		accept_event()
	elif event is InputEventMouseMotion and _down:
		_turn((event as InputEventMouseMotion).relative)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() == 2:
				_pinch_base = _spread()
		else:
			_touches.erase(st.index)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touches.has(sd.index):
			_touches[sd.index] = sd.position
		if _touches.size() == 2 and _pinch_base > 0.0 and _spread() / _pinch_base > 1.22:
			# Fingers apart: the same hand-over as a wheel-up or a trackpad pinch.
			_pinch_base = 0.0
			zoom_to_map.emit(centre.x, centre.y)
		else:
			_turn(sd.relative)
	elif event is InputEventMagnifyGesture and (event as InputEventMagnifyGesture).factor > 1.05:
		zoom_to_map.emit(centre.x, centre.y)

## Distance between the two touches on the globe.
func _spread() -> float:
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])

func _turn(rel: Vector2) -> void:
	_drag_moved += rel.length()
	var deg_per_px := rad_to_deg(1.0 / _radius())
	centre = Vector2(clampf(centre.x + rel.y * deg_per_px, -80.0, 80.0),
		wrapf(centre.y - rel.x * deg_per_px, -180.0, 180.0))
	queue_redraw()
	accept_event()
