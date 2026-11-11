class_name MapTileView
extends Control

## Real OSM tile map centred on the selected location.
## Navigation: drag (mouse or one finger) pans, mouse wheel / trackpad
## magnify / two-finger pinch zooms at the pointer, double-click or
## double-tap zooms in, a short tap places the pin, arrow keys pan and
## +/- zoom when focused. Attribution is always visible.
##
## Drawing: by default the design system Map style from OpenFreeMap vector
## tiles (VectorMapLayer, child of this view). `vector = false` keeps the
## recoloured OSM raster path below, which the raster tests exercise.
##
## Raster progressive rendering, fast first paint: (1) a flat simple style
## (plain tile cells) draws instantly with no network, (2) one coarse
## tile per 4x4 detail block is fetched first and drawn scaled up as a
## blurry preview, (3) full-detail tiles stream in centre-out and
## replace the preview tile by tile. Any cached ancestor tile also
## stands in for a missing detail tile, so pan/zoom never blanks.

signal picked(lat: float, lon: float)
## A tap landed on a landmark marker (MapLandmarks site).
signal landmark_picked(site: Dictionary)
## Zoomed out past MIN_ZOOM: the picker morphs to the globe.
signal zoom_past_min

const MIN_ZOOM := 4
const MAX_ZOOM := 15
const TAP_MAX_PX := 14.0
## Summed trackpad scroll that counts as one zoom step.
const SCROLL_ZOOM_NOTCH := 3.0
## Zoom levels between the coarse preview and full detail.
const PREVIEW_DROP := 2
## How far up the tile pyramid _draw looks for a stand-in texture.
const MAX_ANCESTOR_DROP := 4

## Planet Render 360 map (design system Map style, interim): the standard
## OSM tile recoloured into the `map-*` palette of the live theme. Night
## is a mid-tone dusk slate, lighter than panel glass; Day is a cool
## paper. Colours are classified by hue and rebuilt from lightness, so
## labels, casings and road hierarchy survive. Only Carto's darker,
## saturated motorway/trunk colours keep the one warm road tone;
## primary and secondary roads go neutral (`road_major`). Applied to
## the tile layer only; the pin and attribution live in a child layer.
## The recolour as a function, shared with GlobeView so the globe and
## the flat map read as one surface. Set its uniforms with
## apply_map_palette().
const RECOLOUR := """
uniform vec3 ink;
uniform vec3 muted;
uniform vec3 casing;
uniform vec3 building;
uniform vec3 land;
uniform vec3 road;
uniform vec3 road_major;
uniform vec3 road_warm;
uniform vec3 water;
uniform vec3 water_text;
uniform vec3 park;
uniform vec3 park_deep;
uniform vec3 park_text;

vec3 recolour(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 n = mix(ink, muted, smoothstep(0.0, 0.35, l));
	n = mix(n, casing, smoothstep(0.35, 0.73, l));
	n = mix(n, building, smoothstep(0.73, 0.84, l));
	n = mix(n, land, smoothstep(0.84, 0.94, l));
	n = mix(n, road, smoothstep(0.94, 1.0, l));
	float chroma = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	float is_water = smoothstep(0.06, 0.12, c.b - c.r) * smoothstep(0.0, 0.04, c.b - c.g + 0.04);
	float is_park = smoothstep(0.03, 0.07, c.g - c.r) * smoothstep(0.03, 0.07, c.g - c.b) * (1.0 - is_water);
	float warm = smoothstep(0.12, 0.20, chroma) * (1.0 - is_water) * (1.0 - is_park);
	vec3 h = mix(n, mix(water_text, water, smoothstep(0.45, 0.75, l)), is_water);
	vec3 grass = mix(park_deep, park, smoothstep(0.72, 0.92, l));
	h = mix(h, mix(park_text, grass, smoothstep(0.45, 0.7, l)), is_park);
	// Only Carto's darker motorway/trunk colours stay warm; the lighter
	// primary/secondary fills go neutral, so one road class is warm.
	h = mix(h, mix(road_warm, road_major, smoothstep(0.74, 0.84, l)), warm);
	return clamp(h, 0.0, 1.0);
}
"""
## The `map-*` tokens the recolour targets, per theme (design system
## Map style). Values are sRGB, like COLOR in a 2D shader.
const MAP_PALETTES := {
	"night": {
		"ink": Color("f2f5f8"), "muted": Color("c9d0d9"), "casing": Color("3b4451"),
		"building": Color("555f6e"), "land": Color("47515f"), "road": Color("8e98a6"),
		"road_major": Color("adb5c1"), "road_warm": Color("dcc59a"), "water": Color("263b55"),
		"water_text": Color("9cc0e6"), "park": Color("4a5f55"), "park_deep": Color("465b51"),
		"park_text": Color("b9d3c2"),
	},
	"day": {
		"ink": Color("1f2733"), "muted": Color("4a5463"), "casing": Color("cfd3d8"),
		"building": Color("e1e2dd"), "land": Color("eef0ec"), "road": Color("ffffff"),
		"road_major": Color("ffffff"), "road_warm": Color("f7d79c"), "water": Color("a9cbe8"),
		"water_text": Color("24507a"), "park": Color("d6e6cf"), "park_deep": Color("c4d9bb"),
		"park_text": Color("3d5a46"),
	},
}
const MAP_SHADER := """
shader_type canvas_item;
""" + RECOLOUR + """
void fragment() {
	COLOR = vec4(recolour(COLOR.rgb), COLOR.a);
}
"""

var centre_lat := 48.8566
var centre_lon := 2.3522
var zoom_level := 12
## Draw the vector Map style (VectorMapLayer) instead of recoloured OSM
## raster tiles. Set before the view enters the tree.
var vector := true
## Where the picked place sits, as an offset from the view centre. The
## picker moves it into the part of the map that is not covered by a
## sheet or side panel, so the pin is never hidden behind chrome.
var focus_offset := Vector2.ZERO:
	set(value):
		focus_offset = value
		queue_redraw()
		if _pin != null:
			_pin.point = _focus()

var _fetcher: TileFetcher
var _vector: VectorMapLayer
var _marker: Control
var _pin: MapPin
## Landmark markers (MapLandmarks), fed by the picker.
var landmarks: MapLandmarks
var _textures: Dictionary = {}  # "z/x/y" -> Texture2D
var _requested_tile := Vector2i(1 << 30, 1 << 30)
var _requested_zoom := -1

var _touches: Dictionary = {}  # touch index -> position
var _pinch_base := 0.0
var _touch_down_pos := Vector2.ZERO
var _touch_moved := 0.0
var _mouse_down := false
var _mouse_down_pos := Vector2.ZERO
var _mouse_moved := 0.0
var _last_tap_msec := 0
var _last_tap_pos := Vector2.ZERO
var _magnify_accum := 1.0
var _scroll_accum := 0.0
var _panel_touches: Dictionary = {}  # touch index -> canvas position, for pinches on a panel
var _panel_pinch_base := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 240)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	if vector:
		_vector = VectorMapLayer.new()
		_vector.view = self
		add_child(_vector)
	else:
		var shader := Shader.new()
		shader.code = MAP_SHADER
		var map_mat := ShaderMaterial.new()
		map_mat.shader = shader
		apply_map_palette(map_mat)
		material = map_mat
	# Under the pin, so a selected landmark wears the needle (and above the
	# vector map layer, so landmarks sit over its tiles and labels).
	landmarks = MapLandmarks.new(self)
	add_child(landmarks)
	draw.connect(landmarks.queue_redraw)
	mouse_exited.connect(func() -> void: landmarks.hover_at(Vector2(-1e4, -1e4)))
	_pin = MapPin.new()
	add_child(_pin)
	_pin.point = _focus()
	_marker = Control.new()
	_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.draw.connect(_draw_marker)
	add_child(_marker)
	if not vector:
		_fetcher = TileFetcher.new()
		add_child(_fetcher)
		_fetcher.tile_ready.connect(func(z: int, x: int, y: int, tex: Texture2D) -> void:
			_textures["%d/%d/%d" % [z, x, y]] = tex
			queue_redraw())
	resized.connect(func() -> void:
		refresh_tiles()
		_pin.point = _focus()
		_marker.queue_redraw())
	refresh_tiles()

func set_lat_lon(lat: float, lon: float) -> void:
	centre_lat = lat
	centre_lon = lon
	refresh_tiles()
	if _vector != null:
		# Behind the visible tiles: every other zoom here, so zooming is quick.
		_vector.prefetch_around(lat, lon)
	queue_redraw()
	if _pin != null:
		_pin.ping()

func pin_lat_lon() -> Vector2:
	return Vector2(centre_lat, centre_lon)

func zoom_in() -> void:
	zoom_at(_focus(), 1)

func zoom_out() -> void:
	zoom_at(_focus(), -1)

## Zoom by whole tile steps around the centre; `at` is unused so the picked coordinates stay.
func zoom_at(at: Vector2, steps: int) -> void:
	var new_zoom := clampi(zoom_level + steps, MIN_ZOOM, MAX_ZOOM)
	if new_zoom == zoom_level:
		if steps < 0 and zoom_level == MIN_ZOOM:
			zoom_past_min.emit()
		return
	# The centre (the picked coordinates) stays put: zooming only rescales
	# the map around it, so scrolling never changes the readout.
	zoom_level = new_zoom
	refresh_tiles()
	queue_redraw()
	if _marker != null:
		_marker.queue_redraw()

func pan_by_pixels(delta: Vector2) -> void:
	# Dragging right should pull the map right: the centre moves the
	# opposite way in global pixel space.
	_set_centre_from_pixel(
		TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level) - delta)
	queue_redraw()
	# Fetch as soon as the drag crosses into a new tile: waiting for
	# release left a blank background once the drag outran the old grid.
	var tile_centre := _centre_tile()
	if tile_centre != _requested_tile or zoom_level != _requested_zoom:
		refresh_tiles()

func _centre_tile() -> Vector2i:
	return Vector2i(TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level) / 256.0)

## Tiles needed either side of the centre so the grid always covers
## the whole viewport, whatever its size (the old fixed +/-2 covered
## only 1280px and left wide/desktop layouts blank at the edges).
func _tile_half_extents() -> Vector2i:
	return Vector2i(
		int(ceil(size.x / 512.0)) + 1,
		int(ceil(size.y / 512.0)) + 1)

## Order tiles centre-first so the place the user is looking at paints
## before the edges. Static and pure so tests can pin the order.
static func centre_out_order(tiles: Array, centre: Vector2i) -> Array:
	var ordered := tiles.duplicate()
	ordered.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		var da := Vector2(a.y - centre.x, a.z - centre.y)
		var db := Vector2(b.y - centre.x, b.z - centre.y)
		if da.length_squared() != db.length_squared():
			return da.length_squared() < db.length_squared()
		return a.y < b.y or (a.y == b.y and a.z < b.z))
	return ordered

## Unique coarse preview tiles (PREVIEW_DROP levels up) covering
## `wanted`: roughly one request per 16 detail tiles.
static func preview_tiles_for(wanted: Array, zoom: int) -> Array:
	var pz := maxi(zoom - PREVIEW_DROP, 0)
	var seen: Dictionary = {}
	var preview: Array = []
	for t in wanted:
		var p := TileFetcher.parent_tile(t.x, t.y, t.z, zoom - pz)
		if not seen.has(p):
			seen[p] = true
			preview.append(p)
	return preview

func refresh_tiles() -> void:
	if _vector != null:
		# Remember what was asked for, so a pan refreshes once per tile it
		# crosses (pan_by_pixels), not on every motion event.
		_requested_tile = _centre_tile()
		_requested_zoom = zoom_level
		_vector.refresh()
		return
	if _fetcher == null:
		return
	var tile_centre := _centre_tile()
	var half := _tile_half_extents()
	var wanted: Array = []
	for dy in range(-half.y, half.y + 1):
		for dx in range(-half.x, half.x + 1):
			wanted.append(Vector3i(zoom_level, tile_centre.x + dx, tile_centre.y + dy))
	wanted = centre_out_order(wanted, tile_centre)
	# Coarse preview first: a handful of low-zoom tiles cover the whole
	# viewport long before all detail tiles could arrive. Only tiles
	# whose detail is not already on screen need a preview stand-in.
	var missing: Array = []
	for t in wanted:
		if not _textures.has("%d/%d/%d" % [t.x, t.y, t.z]):
			missing.append(t)
	var preview_centre := TileFetcher.parent_tile(
		zoom_level, tile_centre.x, tile_centre.y, PREVIEW_DROP)
	var preview := centre_out_order(preview_tiles_for(missing, zoom_level),
		Vector2i(preview_centre.y, preview_centre.z))
	var keep := preview.duplicate()
	keep.append_array(wanted)
	_fetcher.discard_queued_except(keep)
	for t in preview:
		if not _textures.has("%d/%d/%d" % [t.x, t.y, t.z]):
			_fetcher.request_tile(t.x, t.y, t.z)
	for t in missing:
		_fetcher.request_tile(t.x, t.y, t.z)
	_requested_tile = tile_centre
	_requested_zoom = zoom_level

func _set_centre_from_pixel(px: Vector2) -> void:
	var ll := TileFetcher.lat_lon_from_pixel(px, zoom_level)
	centre_lat = clampf(ll.x, -85.0, 85.0)
	centre_lon = clampf(ll.y, -180.0, 180.0)

func _pick_at(at: Vector2) -> void:
	_set_centre_from_pixel(
		TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level) + (at - _focus()))
	refresh_tiles()
	queue_redraw()
	picked.emit(centre_lat, centre_lon)

func _is_double_tap(at: Vector2) -> bool:
	var now := Time.get_ticks_msec()
	var double := now - _last_tap_msec < 400 and at.distance_to(_last_tap_pos) < 36.0
	_last_tap_msec = now
	_last_tap_pos = at
	return double

func _tap(at: Vector2) -> void:
	var site := landmarks.hit_at(at) if landmarks != null else {}
	if not site.is_empty():
		_last_tap_msec = 0  # a marker tap never starts a double tap
		landmark_picked.emit(site)
	elif _is_double_tap(at):
		zoom_at(at, 1)
	else:
		_pick_at(at)

func _gui_input(event: InputEvent) -> void:
	# Touch emulated from the mouse (and mouse from touch) arrives beside
	# the real event, so one click tapped twice: a marker tap recentred
	# the map, then the second tap picked the spot the marker had left.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		accept_event()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					zoom_at(mb.position, 1)
					accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					zoom_at(mb.position, -1)
					accept_event()
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT:
				if mb.pressed:
					pan_by_pixels(Vector2(48.0 if mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT else -48.0, 0))
					accept_event()
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					grab_focus()
					_mouse_down = true
					_mouse_down_pos = mb.position
					_mouse_moved = 0.0
				elif _mouse_down:
					_mouse_down = false
					if _mouse_moved <= TAP_MAX_PX:
						_tap(mb.position)
					else:
						refresh_tiles()
						picked.emit(centre_lat, centre_lon)
				accept_event()
	elif event is InputEventMouseMotion and _mouse_down:
		var mm := event as InputEventMouseMotion
		_mouse_moved += mm.relative.length()
		if _mouse_moved > TAP_MAX_PX:
			pan_by_pixels(mm.relative)
	elif event is InputEventMouseMotion and landmarks != null:
		var over := landmarks.hover_at((event as InputEventMouseMotion).position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if over else Control.CURSOR_ARROW
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		magnify(mg.factor, mg.position)
		accept_event()
	elif event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		scroll_zoom(pg.delta.y, pg.position)
		accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			grab_focus()
			_touches[st.index] = st.position
			if _touches.size() == 1:
				_touch_down_pos = st.position
				_touch_moved = 0.0
			elif _touches.size() == 2:
				_pinch_base = _touch_distance(_touches)
		else:
			var was_pinch := _touches.size() >= 2
			_touches.erase(st.index)
			if not was_pinch and _touch_moved <= TAP_MAX_PX:
				_tap(st.position)
			elif not was_pinch:
				refresh_tiles()
				picked.emit(centre_lat, centre_lon)
			if _touches.size() == 1:
				# Remaining finger starts a fresh pan from where it is.
				_touch_down_pos = _touches.values()[0]
				_touch_moved = TAP_MAX_PX + 1.0  # do not turn it into a tap-pick
		accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _touches.has(sd.index):
			return
		_touches[sd.index] = sd.position
		if _touches.size() >= 2:
			var dist := _touch_distance(_touches)
			if pinch_step(dist, _pinch_base, _touch_midpoint(_touches)):
				_pinch_base = dist
			else:
				pan_by_pixels(sd.relative)
		else:
			_touch_moved += sd.relative.length()
			if _touch_moved > TAP_MAX_PX:
				pan_by_pixels(sd.relative)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		match key.keycode:
			KEY_LEFT:
				pan_by_pixels(Vector2(80, 0))
			KEY_RIGHT:
				pan_by_pixels(Vector2(-80, 0))
			KEY_UP:
				pan_by_pixels(Vector2(0, 80))
			KEY_DOWN:
				pan_by_pixels(Vector2(0, -80))
			KEY_EQUAL, KEY_KP_ADD:
				zoom_in()
			KEY_MINUS, KEY_KP_SUBTRACT:
				zoom_out()
			_:
				return
		if key.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			refresh_tiles()
			picked.emit(centre_lat, centre_lon)
		accept_event()

static func _touch_distance(touches: Dictionary) -> float:
	if touches.size() < 2:
		return 0.0
	var pts: Array = touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])

func _touch_midpoint(touches: Dictionary) -> Vector2:
	if touches.is_empty():
		return _focus()
	var pts: Array = touches.values()
	return pts[0] if pts.size() == 1 else ((pts[0] as Vector2) + (pts[1] as Vector2)) / 2.0

## Pinch: whole zoom levels once the fingers have moved apart or together
## by a fifth since `base`. Returns true when it zoomed.
func pinch_step(dist: float, base: float, at: Vector2) -> bool:
	if base <= 0.0:
		return false
	if dist / base > 1.22:
		zoom_at(at, 1)
	elif dist / base < 0.82:
		zoom_at(at, -1)
	else:
		return false
	return true

## Trackpad pinch: whole zoom levels once the accumulated factor passes a
## fifth either way, so a slow gesture steps once per fifth.
func magnify(factor: float, at: Vector2) -> void:
	_magnify_accum *= factor
	if _magnify_accum > 1.18:
		_magnify_accum = 1.0
		zoom_at(at, 1)
	elif _magnify_accum < 0.85:
		_magnify_accum = 1.0
		zoom_at(at, -1)

## A trackpad two-finger scroll arrives as a stream of small pan-gesture
## deltas, not wheel clicks: sum them and zoom a step per notch. Scrolling
## up (negative y) zooms in, like the wheel.
func scroll_zoom(delta_y: float, at: Vector2) -> void:
	_scroll_accum += delta_y
	if _scroll_accum <= -SCROLL_ZOOM_NOTCH:
		_scroll_accum = 0.0
		zoom_at(at, 1)
	elif _scroll_accum >= SCROLL_ZOOM_NOTCH:
		_scroll_accum = 0.0
		zoom_at(at, -1)

## Zoom input from a glass panel or scroll area laid over the map (the
## sheet, the side panel and the lists in them): the wheel, a trackpad
## pinch and a two-finger pinch zoom the map under it, while the panel
## keeps its taps and drags. A scroll area with room to scroll keeps the
## wheel for itself.
func panel_zoom_input(event: InputEvent, from: Control) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or _can_scroll(from):
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(_from_panel(from, mb.position), 1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(_from_panel(from, mb.position), -1)
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		magnify(mg.factor, _from_panel(from, mg.position))
	elif event is InputEventPanGesture:
		if not _can_scroll(from):
			var pg := event as InputEventPanGesture
			scroll_zoom(pg.delta.y, _from_panel(from, pg.position))
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_panel_touches[st.index] = _from_panel(from, st.position)
			if _panel_touches.size() == 2:
				_panel_pinch_base = _touch_distance(_panel_touches)
		else:
			_panel_touches.erase(st.index)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _panel_touches.has(sd.index):
			return
		_panel_touches[sd.index] = _from_panel(from, sd.position)
		if _panel_touches.size() >= 2:
			var dist := _touch_distance(_panel_touches)
			if pinch_step(dist, _panel_pinch_base, _touch_midpoint(_panel_touches)):
				_panel_pinch_base = dist

## A point of `from` (a panel, unscaled) in this canvas's own space.
func _from_panel(from: Control, at: Vector2) -> Vector2:
	return at + from.global_position - global_position

## A scroll area with room to scroll keeps the wheel for itself.
static func _can_scroll(from: Control) -> bool:
	var sc := from as ScrollContainer
	if sc == null or sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var bar := sc.get_v_scroll_bar()
	return bar.max_value > bar.page

## Nearest cached ancestor (Vector3i z/x/y) that can stand in for the
## detail tile (tx, ty), or (-1, -1, -1) when none is loaded yet.
func _find_ancestor(tx: int, ty: int) -> Vector3i:
	for drop in range(1, MAX_ANCESTOR_DROP + 1):
		if zoom_level - drop < 0:
			break
		var p := TileFetcher.parent_tile(zoom_level, tx, ty, drop)
		if _textures.has("%d/%d/%d" % [p.x, p.y, p.z]):
			return p
	return Vector3i(-1, -1, -1)

func _draw() -> void:
	if _vector != null:
		# map-land under the tiles: the map reads as land from frame one.
		draw_rect(Rect2(Vector2.ZERO, size), MapStyle.colors()["land"])
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.949, 0.937, 0.914))
	var centre_px := TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level)
	var tile_centre := Vector2i(centre_px / 256.0)
	var half := _tile_half_extents()
	for dy in range(-half.y, half.y + 1):
		for dx in range(-half.x, half.x + 1):
			var tx := tile_centre.x + dx
			var ty := tile_centre.y + dy
			var tile_origin := Vector2(tx * 256.0, ty * 256.0)
			var pos := tile_origin - centre_px + _focus()
			var dest := Rect2(pos, Vector2(256, 256))
			var key := "%d/%d/%d" % [zoom_level, tx, ty]
			if _textures.has(key):
				draw_texture_rect(_textures[key], dest, false)
				continue
			var ancestor := _find_ancestor(tx, ty)
			if ancestor.x >= 0:
				# Low-detail stand-in: the ancestor's crop for this tile.
				var akey := "%d/%d/%d" % [ancestor.x, ancestor.y, ancestor.z]
				draw_texture_rect_region(_textures[akey], dest,
					TileFetcher.source_rect_for_ancestor(
						Vector3i(zoom_level, tx, ty), ancestor))
				continue
			# Simple style, before any tile arrives: a flat cell with a
			# hairline grid so the map reads as a map from frame one.
			var shade := Color(0.949, 0.937, 0.914) if (tx + ty) % 2 == 0 \
				else Color(0.918, 0.906, 0.882)
			draw_rect(dest, shade)
			draw_rect(dest, Color(0.86, 0.85, 0.83), false, 1.0)

func _focus() -> Vector2:
	return size / 2.0 + focus_offset

## Where the picked place sits on screen (centre plus focus_offset).
func focus_point() -> Vector2:
	return _focus()

## Points a material that includes RECOLOUR at the live theme's map
## palette. Theme switches rebuild the screens, so setting it when the
## material is made keeps it current.
static func apply_map_palette(mat: ShaderMaterial) -> void:
	var palette: Dictionary = MAP_PALETTES["day" if UiTheme.is_day else "night"]
	for key in palette:
		var c: Color = palette[key]
		mat.set_shader_parameter(key, Vector3(c.r, c.g, c.b))

## Redraw the pin and attribution after a palette change.
func refresh_style() -> void:
	if _pin != null:
		_pin.queue_redraw()
	if _marker != null:
		_marker.queue_redraw()

## Attribution, drawn above the recoloured tile layer and the pin
## (MapPin) so it keeps its real colours: a glass-strong chip.
func _draw_marker() -> void:
	# Attribution, bottom-right and never hidden (tile usage policy)
	var font := get_theme_default_font()
	# OpenFreeMap asks for "© OpenMapTiles" + OSM; its own name is optional
	# and lives in the picker's attribution line, so the chip fits a phone.
	var text := "© OpenStreetMap contributors · © OpenMapTiles" if _vector != null \
		else "© OpenStreetMap contributors"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var chip := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_XS, UiTheme.GLASS_EDGE)
	_marker.draw_style_box(chip, Rect2(size - text_size - Vector2(16, 20), text_size + Vector2(12, 8)))
	_marker.draw_string(font, Vector2(size.x - text_size.x - 10, size.y - 16 - font.get_descent(12)), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiTheme.MUTED)
