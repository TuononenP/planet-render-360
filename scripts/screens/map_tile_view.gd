class_name MapTileView
extends Control

## Real OSM tile map centred on the selected location.
## Navigation: drag (mouse or one finger) pans, mouse wheel / trackpad
## magnify / two-finger pinch zooms at the pointer, double-click or
## double-tap zooms in, a short tap places the pin, arrow keys pan and
## +/- zoom when focused. Falls back to a plain background until tiles
## arrive (offline first run). Attribution is always visible.

signal picked(lat: float, lon: float)

const MIN_ZOOM := 4
const MAX_ZOOM := 15
const TAP_MAX_PX := 14.0

var centre_lat := 48.8566
var centre_lon := 2.3522
var zoom_level := 12

var _fetcher: TileFetcher
var _textures: Dictionary = {}  # "z/x/y" -> Texture2D

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

func _ready() -> void:
	custom_minimum_size = Vector2(0, 240)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	_fetcher = TileFetcher.new()
	add_child(_fetcher)
	_fetcher.tile_ready.connect(func(z: int, x: int, y: int, tex: Texture2D) -> void:
		_textures["%d/%d/%d" % [z, x, y]] = tex
		queue_redraw())
	refresh_tiles()

func set_lat_lon(lat: float, lon: float) -> void:
	centre_lat = lat
	centre_lon = lon
	refresh_tiles()
	queue_redraw()

func pin_lat_lon() -> Vector2:
	return Vector2(centre_lat, centre_lon)

func zoom_in() -> void:
	zoom_at(size / 2.0, 1)

func zoom_out() -> void:
	zoom_at(size / 2.0, -1)

## Zoom by whole tile steps, keeping the place under `at` under `at`.
func zoom_at(at: Vector2, steps: int) -> void:
	var new_zoom := clampi(zoom_level + steps, MIN_ZOOM, MAX_ZOOM)
	if new_zoom == zoom_level:
		return
	var anchor := TileFetcher.lat_lon_from_pixel(
		TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level) + (at - size / 2.0),
		zoom_level)
	var anchor_px := TileFetcher.global_pixel(anchor.x, anchor.y, new_zoom)
	zoom_level = new_zoom
	_set_centre_from_pixel(anchor_px - (at - size / 2.0))
	refresh_tiles()
	picked.emit(centre_lat, centre_lon)

func pan_by_pixels(delta: Vector2) -> void:
	# Dragging right should pull the map right: the centre moves the
	# opposite way in global pixel space.
	_set_centre_from_pixel(
		TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level) - delta)
	queue_redraw()

func refresh_tiles() -> void:
	if _fetcher == null:
		return
	var centre_px := TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level)
	var tile_centre := Vector2i(centre_px / 256.0)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			_fetcher.request_tile(zoom_level, tile_centre.x + dx, tile_centre.y + dy)

func _set_centre_from_pixel(px: Vector2) -> void:
	var ll := TileFetcher.lat_lon_from_pixel(px, zoom_level)
	centre_lat = clampf(ll.x, -85.0, 85.0)
	centre_lon = clampf(ll.y, -180.0, 180.0)

func _pick_at(at: Vector2) -> void:
	_set_centre_from_pixel(
		TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level) + (at - size / 2.0))
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
	if _is_double_tap(at):
		zoom_at(at, 1)
	else:
		_pick_at(at)

func _gui_input(event: InputEvent) -> void:
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
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		_magnify_accum *= mg.factor
		if _magnify_accum > 1.18:
			_magnify_accum = 1.0
			zoom_at(mg.position, 1)
		elif _magnify_accum < 0.85:
			_magnify_accum = 1.0
			zoom_at(mg.position, -1)
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
				_pinch_base = _touch_distance()
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
			var dist := _touch_distance()
			if _pinch_base > 0.0 and dist / _pinch_base > 1.22:
				_pinch_base = dist
				zoom_at(_touch_midpoint(), 1)
			elif _pinch_base > 0.0 and dist / _pinch_base < 0.82:
				_pinch_base = dist
				zoom_at(_touch_midpoint(), -1)
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

func _touch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])

func _touch_midpoint() -> Vector2:
	if _touches.is_empty():
		return size / 2.0
	var pts: Array = _touches.values()
	return pts[0] if pts.size() == 1 else ((pts[0] as Vector2) + (pts[1] as Vector2)) / 2.0

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.92, 0.93, 0.90))
	var centre_px := TileFetcher.global_pixel(centre_lat, centre_lon, zoom_level)
	var tile_centre := Vector2i(centre_px / 256.0)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var tx := tile_centre.x + dx
			var ty := tile_centre.y + dy
			var key := "%d/%d/%d" % [zoom_level, tx, ty]
			if not _textures.has(key):
				continue
			var tile_origin := Vector2(tx * 256.0, ty * 256.0)
			var pos := tile_origin - centre_px + size / 2.0
			draw_texture_rect(_textures[key], Rect2(pos, Vector2(256, 256)), false)
	# Centre pin
	var p := size / 2.0
	draw_circle(p + Vector2(0, -14), 11, UiTheme.TEAL)
	draw_circle(p + Vector2(0, -14), 4.5, Color.WHITE)
	draw_colored_polygon(PackedVector2Array(
		[p + Vector2(-7, -8), p + Vector2(7, -8), p]), UiTheme.TEAL)
	# Attribution, bottom-right and never hidden (tile usage policy)
	var font := get_theme_default_font()
	var text := "© OpenStreetMap contributors"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_rect(Rect2(size - text_size - Vector2(12, 20), text_size + Vector2(8, 4)),
		Color(1, 1, 1, 0.85))
	draw_string(font, size - text_size - Vector2(8, 6), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.25, 0.27, 0.25))
