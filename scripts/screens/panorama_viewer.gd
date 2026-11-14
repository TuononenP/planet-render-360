class_name PanoramaViewer
extends Control

## Full-screen look-around for one saved 360° photo: a canvas shader
## inverts PanoramaCapture's equirectangular projection. Drag turns
## (CameraRig's feel), wheel/pinch zooms, double-tap resets. The photo
## opens facing the heading it was captured at. The JPEG decodes on a
## worker thread so "Opening photo…" shows while a large one loads.

signal back_requested
signal deleted(entry: Dictionary)
## The file existed but could not be decoded (damaged JPEG).
signal open_failed(entry: Dictionary)

const SHADER := """
shader_type canvas_item;
uniform sampler2D pano : filter_linear, repeat_enable;
uniform float heading_rad = 0.0;
uniform float pitch_rad = 0.0;
uniform float origin_rad = 0.0;
uniform float tan_fov = 1.0;
uniform float aspect = 1.0;
void fragment() {
	vec2 cam = vec2((UV.x - 0.5) * 2.0 * aspect, (0.5 - UV.y) * 2.0);
	vec3 horiz = vec3(sin(heading_rad), 0.0, -cos(heading_rad));
	vec3 fwd = vec3(horiz.x * cos(pitch_rad), sin(pitch_rad), horiz.z * cos(pitch_rad));
	vec3 right = vec3(-horiz.z, 0.0, horiz.x);
	vec3 up = cross(right, fwd);
	vec3 dir = normalize(fwd + right * cam.x * tan_fov + up * cam.y * tan_fov);
	float heading = atan(dir.x, -dir.z);
	float lat = asin(clamp(dir.y, -1.0, 1.0));
	float rel = mod(heading - origin_rad + PI, TAU) - PI;
	vec2 eq = vec2(0.5 + rel / TAU, 0.5 - lat / PI);
	COLOR = texture(pano, eq);
}
"""

const DRAG_RAD := 0.005  # CameraRig.handle_drag
const PITCH_MAX := 1.553  # 89 degrees: poles reachable, basis stable

var _rect: ColorRect
var _mat: ShaderMaterial
var _caption: Label
var _compass: Label
var _loading: Label
var _toast: Toast
var _entry: Dictionary = {}
var _heading_deg := 0.0
var _origin_deg := 0.0
var _pitch := 0.0
var _fov := 70.0
var _pinch_base := 0.0
var _magnify_accum := 1.0
var _touches: Dictionary = {}
var _fullscreen_btn: Button
var _top: PanelContainer
var _bottom: HBoxContainer
## Bottom-bar buttons and their labels: phones show icons only.
var _bar_buttons: Array[Button] = []
## Background decode: task id (-1 none), its result, and a generation
## so a decode finishing after close/reopen is discarded.
var _task := -1
## The current task's result slot; each task gets its own, so a decode
## finishing after close/reopen can never land in the next photo.
var _box: Array = [null]
## Closed while decoding: still owed a wait_for_task_completion, done
## from _process once finished so closing never blocks the main thread.
var _abandoned: Array[int] = []

# --- Pure maths (headless-tested) ---

static func wrap_deg(d: float) -> float:
	return fposmod(d + 180.0, 360.0) - 180.0

## Compass heading (deg, 0 north clockwise) of a world direction.
static func heading_of(dir: Vector3) -> float:
	return fposmod(rad_to_deg(atan2(dir.x, -dir.z)), 360.0)

static func equirect_uv(dir: Vector3, origin_heading_deg: float) -> Vector2:
	var rel := wrap_deg(heading_of(dir) - origin_heading_deg)
	var lat := asin(clampf(dir.y, -1.0, 1.0))
	return Vector2(0.5 + rel / 360.0, 0.5 - lat / PI)

## World direction for a view pixel. `ndc` is (-1..1, -1..1), y up.
static func direction_for_pixel(ndc: Vector2, heading_deg: float, pitch: float,
		fov_deg: float, aspect: float) -> Vector3:
	var h := deg_to_rad(heading_deg)
	var horiz := Vector3(sin(h), 0.0, -cos(h))
	var fwd := Vector3(horiz.x * cos(pitch), sin(pitch), horiz.z * cos(pitch))
	var right := Vector3(-horiz.z, 0.0, horiz.x)
	var up := right.cross(fwd)
	var t := tan(deg_to_rad(fov_deg) * 0.5)
	return (fwd + right * ndc.x * t * aspect + up * ndc.y * t).normalized()

## Zoom by `factor` (>1 zooms in), clamped to the rig's FOV range.
static func apply_zoom(fov_deg: float, factor: float) -> float:
	return clampf(fov_deg / factor, 25.0, 95.0)

static func apply_drag(heading_deg: float, pitch: float, rel: Vector2) -> Vector2:
	return Vector2(heading_deg + rel.x * rad_to_deg(DRAG_RAD),
		clampf(pitch - rel.y * DRAG_RAD, -PITCH_MAX, PITCH_MAX))

static func compass_text(heading_deg: float) -> String:
	var dirs: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	return dirs[int(round(fposmod(heading_deg, 360.0) / 45.0)) % 8]

# --- UI ---

func _ready() -> void:
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color.WHITE
	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_rect.material = _mat
	add_child(_rect)
	var top := PanelContainer.new()
	_top = top
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_top = 12
	top.offset_right = -12
	add_child(top)
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 10)
	top.add_child(bar)
	var back := UiTheme.icon_button("")
	UiIcon.apply(back, "arrow-left", 22)
	back.tooltip_text = "Back to Gallery"
	back.pressed.connect(func() -> void: back_requested.emit())
	bar.add_child(back)
	_caption = UiTheme.label("", 16, UiTheme.INK, true)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caption.clip_text = true
	_caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bar.add_child(_caption)
	_compass = UiTheme.data_label("", 15, UiTheme.MUTED, true)
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_compass)
	_fullscreen_btn = UiTheme.icon_button("")
	UiIcon.apply(_fullscreen_btn, "maximize", 20)
	_fullscreen_btn.pressed.connect(_toggle_fullscreen)
	_fullscreen_btn.visible = not OS.has_feature("mobile")
	bar.add_child(_fullscreen_btn)
	_sync_fullscreen()
	var bottom := HBoxContainer.new()
	_bottom = bottom
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation", 8)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.offset_bottom = -12
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN  # zero-height: grow up, not off-screen
	bottom.alignment = BoxContainer.ALIGNMENT_END
	add_child(bottom)
	var reset := _bar_button("rotate-ccw", "Reset view")
	reset.pressed.connect(_reset_view)
	bottom.add_child(reset)
	var export_btn := _bar_button("hard-drive", "Export photo")
	export_btn.tooltip_text = "Save a copy (Pictures or a folder you pick)"
	export_btn.pressed.connect(_export)
	bottom.add_child(export_btn)
	var del := _bar_button("trash-2", "Delete")
	del.pressed.connect(_confirm_delete)
	bottom.add_child(del)
	_loading = UiTheme.label("Opening photo…", 16, UiTheme.INK, true)
	_loading.set_anchors_preset(Control.PRESET_CENTER)
	_loading.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loading.grow_vertical = Control.GROW_DIRECTION_BOTH
	_loading.visible = false
	add_child(_loading)
	_toast = Toast.new()
	add_child(_toast)
	resized.connect(_sync_shader)
	resized.connect(_layout)
	_layout()

func _bar_button(icon: String, text: String) -> Button:
	var b := UiTheme.icon_button(text)
	UiIcon.apply(b, icon, 20)
	b.set_meta("label", text)
	b.tooltip_text = text
	_bar_buttons.append(b)
	b.add_theme_stylebox_override("normal", UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true))
	return b

## Starts opening `entry`; false when its file is gone. The picture
## appears once the background decode finishes (open_failed if it can't).
## Bars clear the notch / home indicator; on phones the bottom
## buttons drop their labels so all three fit.
func _layout() -> void:
	if _top == null:
		return
	var safe := Responsive.safe_insets(self)
	_top.offset_left = 12 + safe[0]
	_top.offset_top = 12 + safe[1]
	_top.offset_right = -12 - safe[2]
	_bottom.offset_left = 12 + safe[0]
	_bottom.offset_right = -12 - safe[2]
	_bottom.offset_bottom = -12 - safe[3]
	var compact := Responsive.layout_for_width(size.x) == Responsive.Layout.COMPACT
	for b in _bar_buttons:
		b.text = "" if compact else str(b.get_meta("label"))

func open(entry: Dictionary) -> bool:
	close()
	var path := PanoramaLibrary.path_for(entry)
	if str(entry.get("file", "")) == "" or not FileAccess.file_exists(path):
		return false
	_entry = entry
	_origin_deg = float(entry.get("heading_deg", 0.0))
	_heading_deg = _origin_deg
	_pitch = 0.0
	_fov = 70.0
	var place := str(entry.get("place", "View"))
	_caption.text = place if not entry.has("timestamp") \
		else "%s · %s" % [place, UiTheme.relative_time(float(entry["timestamp"]))]
	_loading.visible = true
	_rect.visible = false
	_sync_fullscreen()
	_sync_shader()
	var box: Array = [null]
	_box = box
	_task = WorkerThreadPool.add_task(func() -> void: box[0] = Image.load_from_file(path),
		false, "PanoramaViewer decode")
	set_process(true)
	return true

## True while a photo is still decoding.
func is_loading() -> bool:
	return _task != -1

func _process(_delta: float) -> void:
	for t in _abandoned.duplicate():
		if WorkerThreadPool.is_task_completed(t):
			WorkerThreadPool.wait_for_task_completion(t)
			_abandoned.erase(t)
	if _task == -1:
		set_process(not _abandoned.is_empty())
		return
	if not WorkerThreadPool.is_task_completed(_task):
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	set_process(not _abandoned.is_empty())
	_loading.visible = false
	var img: Image = _box[0]
	_box = [null]
	if img == null or img.is_empty():
		var failed := _entry
		_entry = {}
		open_failed.emit(failed)
		return
	_mat.set_shader_parameter("pano", ImageTexture.create_from_image(img))
	_rect.visible = true
	_sync_shader()

## Frees the photo and abandons a decode in flight without waiting on it.
func close() -> void:
	if _task != -1:
		_abandoned.append(_task)
		_task = -1
		set_process(true)
	_box = [null]
	if _mat != null:
		_mat.set_shader_parameter("pano", null)
	if _loading != null:
		_loading.visible = false
	_entry = {}

func _exit_tree() -> void:
	close()
	_join_tasks()

## Every decode must still be waited on once: on leaving the tree, and
## when the viewer is freed without ever entering it.
func _join_tasks() -> void:
	if _task != -1:
		_abandoned.append(_task)
		_task = -1
	for t in _abandoned:
		WorkerThreadPool.wait_for_task_completion(t)
	_abandoned.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_tasks()

func _toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full \
		else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_sync_fullscreen()

func _sync_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	UiIcon.apply(_fullscreen_btn, "minimize" if full else "maximize", 20)
	_fullscreen_btn.tooltip_text = "Exit fullscreen (F)" if full else "Fullscreen (F)"

func _reset_view() -> void:
	_heading_deg = _origin_deg
	_pitch = 0.0
	_fov = 70.0
	_sync_shader()

func _sync_shader() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("heading_rad", deg_to_rad(_heading_deg))
	_mat.set_shader_parameter("pitch_rad", _pitch)
	_mat.set_shader_parameter("origin_rad", deg_to_rad(_origin_deg))
	_mat.set_shader_parameter("tan_fov", tan(deg_to_rad(_fov) * 0.5))
	_mat.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	if _compass != null:
		_compass.text = "%s %03d°" % [compass_text(_heading_deg), int(round(fposmod(_heading_deg, 360.0))) % 360]

func _export() -> void:
	if _entry.is_empty():
		return
	var bytes := FileAccess.get_file_as_bytes(PanoramaLibrary.path_for(_entry))
	if bytes.is_empty():
		return
	PhotoMode.save_bytes(bytes, str(_entry.get("file", "panorama.jpg")), "jpg", "JPEG image",
		"Save 360° photo", func(path: String, failed: bool) -> void:
			if failed:
				_say("Couldn't save the photo", "Check there is space and the folder can be written to.", "error")
			elif path != "":
				_say("Photo saved", path.get_file() if path.begins_with("user://") else path))

## Brief message above the bottom bar.
func _say(title: String, message: String, tone: String = "neutral") -> void:
	_toast.show_message(title, message, tone)
	_toast.place(size, 16.0, size.y - 72.0, size.x < 700.0)

func _confirm_delete() -> void:
	if _entry.is_empty():
		return
	var target := _entry  # captured now: the sheet must delete this photo even if state moves on
	SettingsRows.confirm(self, "Delete this 360° photo?",
		"“%s” will be removed from Gallery on this device. A copy you exported elsewhere stays."
		% str(target.get("place", "View")), "Delete", func() -> void:
			PanoramaLibrary.remove(target)
			close()
			deleted.emit(target))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		_magnify_accum *= mg.factor
		if _magnify_accum > 1.15:
			_magnify_accum = 1.0
			_fov = apply_zoom(_fov, 1.18)
			_sync_shader()
		elif _magnify_accum < 0.87:
			_magnify_accum = 1.0
			_fov = apply_zoom(_fov, 1.0 / 1.18)
			_sync_shader()
		accept_event()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and t.double_tap:
			_reset_view()
		if t.pressed:
			_touches[t.index] = t.position
		else:
			_touches.erase(t.index)
		if _touches.size() == 2:
			var pts := _touches.values()
			_pinch_base = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
		accept_event()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touches[d.index] = d.position
		if _touches.size() == 2:
			var pts := _touches.values()
			var dist := (pts[0] as Vector2).distance_to(pts[1] as Vector2)
			if _pinch_base > 0.0 and dist > 0.0:
				_fov = apply_zoom(_fov, dist / _pinch_base)
				_pinch_base = dist
				_sync_shader()
		else:
			_drag(d.relative)
		accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_fov = apply_zoom(_fov, 1.12)
			_sync_shader()
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_fov = apply_zoom(_fov, 1.0 / 1.12)
			_sync_shader()
			accept_event()
		elif mb.pressed and mb.double_click:
			_reset_view()
			accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag(mm.relative)
			accept_event()

func _drag(rel: Vector2) -> void:
	var next := apply_drag(_heading_deg, _pitch, rel)
	_heading_deg = next.x
	_pitch = next.y
	_sync_shader()

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_LEFT:
			_heading_deg -= 15.0
		elif k == KEY_RIGHT:
			_heading_deg += 15.0
		elif k == KEY_UP:
			_pitch = clampf(_pitch + 0.2, -PITCH_MAX, PITCH_MAX)
		elif k == KEY_DOWN:
			_pitch = clampf(_pitch - 0.2, -PITCH_MAX, PITCH_MAX)
		elif k == KEY_F and _fullscreen_btn.visible:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		else:
			return
		_sync_shader()
		get_viewport().set_input_as_handled()
