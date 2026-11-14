class_name MediaViewer
extends Control

## Full-screen view of one saved photo or video from Gallery
## (MediaLibrary). A photo fits the screen; a video plays through the
## native VideoDecoder with play / pause, a scrubber and its times. Tap
## the picture or press Space to play or pause. The photo decodes on a
## worker thread, like PanoramaViewer's.

signal back_requested
signal deleted(entry: Dictionary)
## The file existed but could not be read (damaged, or no decoder here).
signal open_failed(entry: Dictionary)

var _entry: Dictionary = {}
var _picture: TextureRect
var _caption: Label
var _loading: Label
var _top: PanelContainer
var _bottom: PanelContainer
var _play: Button
var _time: Label
var _length: Label
var _scrub: HSlider
var _fullscreen_btn: Button
var _image: Image
var _texture: ImageTexture
## The video: decoder, clock (µs from the first frame) and state.
var _dec: Object
var _clock_us := 0
var _duration_us := 0
var _playing := false
var _scrubbing := false
var _resume_after_scrub := false
## While dragging, the position to seek to next and when the last seek
## went out: each seek restarts the decode, so a drag seeks at most every
## SCRUB_SEEK_MS and once more where it ends.
var _scrub_to := -1
var _last_seek_ms := 0
const SCRUB_SEEK_MS := 150
## Photo decode on a worker: task id (-1 none) and its result slot.
var _task := -1
var _box: Array = [null]
var _abandoned: Array[int] = []

## "0:07", "1:03", "1:02:09": a video's position and length.
static func clock_text(seconds: float) -> String:
	var s := maxi(0, int(floor(seconds)))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]

func _ready() -> void:
	set_process(false)
	var bg := ColorRect.new()
	bg.color = UiTheme.SKY_000
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_picture = TextureRect.new()
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	_build_top()
	_build_bottom()
	_loading = UiTheme.label("", 16, UiTheme.INK, true)
	_loading.set_anchors_preset(Control.PRESET_CENTER)
	_loading.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loading.grow_vertical = Control.GROW_DIRECTION_BOTH
	_loading.visible = false
	add_child(_loading)
	resized.connect(_layout)
	_layout()

func _build_top() -> void:
	_top = PanelContainer.new()
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true))
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(_top)
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 10)
	_top.add_child(bar)
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
	_fullscreen_btn = UiTheme.icon_button("")
	_fullscreen_btn.pressed.connect(_toggle_fullscreen)
	_fullscreen_btn.visible = not OS.has_feature("mobile")
	bar.add_child(_fullscreen_btn)
	var del := UiTheme.icon_button("")
	UiIcon.apply(del, "trash-2", 20)
	del.tooltip_text = "Delete"
	del.pressed.connect(_confirm_delete)
	bar.add_child(del)
	_sync_fullscreen()

## The video's transport: play / pause, position, scrubber, length.
func _build_bottom() -> void:
	_bottom = PanelContainer.new()
	_bottom.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE, true))
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_bottom.add_child(row)
	_play = UiTheme.icon_button("")
	_play.pressed.connect(toggle_play)
	row.add_child(_play)
	_time = UiTheme.data_label("0:00", 15, UiTheme.INK, true)
	_time.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_time)
	_scrub = HSlider.new()
	_scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scrub.custom_minimum_size = Vector2(0, 44)
	_scrub.step = 0.0
	_scrub.accessibility_name = "Position"
	HudStyle.apply_slider(_scrub)
	_scrub.drag_started.connect(func() -> void:
		_scrubbing = true
		_resume_after_scrub = _playing
		_set_playing(false))
	_scrub.drag_ended.connect(func(_changed: bool) -> void:
		_scrubbing = false
		if _scrub_to >= 0:
			_seek(_scrub_to)
		if _resume_after_scrub:
			_set_playing(true))
	_scrub.value_changed.connect(func(v: float) -> void:
		if _scrubbing:
			_scrub_to = int(v * 1e6)
			_time.text = clock_text(v)
		else:
			_seek(int(v * 1e6)))
	row.add_child(_scrub)
	_length = UiTheme.data_label("0:00", 15, UiTheme.MUTED, true)
	_length.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_length)
	_sync_play()

## Bars clear the notch and the home indicator.
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

## Starts showing `entry`; false when its file is gone. A video shows its
## first frame at once; a photo appears when its decode finishes
## (open_failed if either can't be read).
func open(entry: Dictionary) -> bool:
	close()
	var path := MediaLibrary.path_for(entry)
	if path == "" or not FileAccess.file_exists(path):
		return false
	_entry = entry
	var place := str(entry.get("place", "View"))
	_caption.text = place if not entry.has("timestamp") \
		else "%s · %s" % [place, UiTheme.relative_time(float(entry["timestamp"]))]
	var video := str(entry.get("kind", "")) == MediaLibrary.VIDEO
	_bottom.visible = video
	_sync_fullscreen()
	if video:
		return _open_video(path)
	_loading.text = "Opening photo…"
	_loading.visible = true
	var box: Array = [null]
	_box = box
	_task = WorkerThreadPool.add_task(func() -> void: box[0] = Image.load_from_file(path),
		false, "MediaViewer decode")
	set_process(true)
	return true

func _open_video(path: String) -> bool:
	if not MediaLibrary.can_play():
		_fail.call_deferred()
		return true
	_dec = ClassDB.instantiate("VideoDecoder")
	if not bool(_dec.call("open", path)):
		push_warning("MediaViewer: " + str(_dec.call("get_last_error")))
		_dec = null
		_fail.call_deferred()
		return true
	_duration_us = int(_dec.call("get_duration_usec"))
	_scrub.max_value = maxf(float(_duration_us) / 1e6, 0.01)
	_scrub.set_value_no_signal(0.0)
	_length.text = clock_text(float(_duration_us) / 1e6)
	_clock_us = 0
	_show_frame(_dec.call("poll", 0))
	_sync_time()
	set_process(true)
	_set_playing(true)
	return true

func _fail() -> void:
	var failed := _entry
	close()
	open_failed.emit(failed)

## True while a photo is still decoding.
func is_loading() -> bool:
	return _task != -1

func is_playing() -> bool:
	return _playing

## Stops the video, frees the picture and abandons a photo decode in
## flight without waiting on it.
func close() -> void:
	if _task != -1:
		_abandoned.append(_task)
		_task = -1
	_box = [null]
	if _dec != null:
		_dec.call("close")
		_dec = null
	_playing = false
	_scrubbing = false
	_scrub_to = -1
	_image = null
	_texture = null
	if _picture != null:
		_picture.texture = null
	if _loading != null:
		_loading.visible = false
	_entry = {}
	set_process(not _abandoned.is_empty())
	if _play != null:
		_sync_play()

func toggle_play() -> void:
	if _dec == null:
		return
	if not _playing and _clock_us >= _duration_us:
		_seek(0)  # From the end: play again from the start.
	_set_playing(not _playing)

func _set_playing(on: bool) -> void:
	_playing = on and _dec != null
	_sync_play()

func _sync_play() -> void:
	UiIcon.apply(_play, "pause" if _playing else "play", 22)
	_play.tooltip_text = "Pause (Space)" if _playing else "Play (Space)"
	_play.accessibility_name = "Pause" if _playing else "Play"

func _seek(usec: int) -> void:
	if _dec == null:
		return
	_clock_us = clampi(usec, 0, _duration_us)
	_dec.call("seek", _clock_us)
	_scrub_to = -1
	_last_seek_ms = Time.get_ticks_msec()
	_sync_time()

func _sync_time() -> void:
	_time.text = clock_text(_scrub.value if _scrubbing else float(_clock_us) / 1e6)
	if not _scrubbing:
		_scrub.set_value_no_signal(float(_clock_us) / 1e6)

func _show_frame(frame: PackedByteArray) -> void:
	if frame.is_empty() or _dec == null:
		return
	var w := int(_dec.call("get_width"))
	var h := int(_dec.call("get_height"))
	if _texture == null:
		_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, frame)
		_texture = ImageTexture.create_from_image(_image)
		_picture.texture = _texture
		return
	_image.set_data(w, h, false, Image.FORMAT_RGBA8, frame)
	_texture.update(_image)

func _process(delta: float) -> void:
	for t in _abandoned.duplicate():
		if WorkerThreadPool.is_task_completed(t):
			WorkerThreadPool.wait_for_task_completion(t)
			_abandoned.erase(t)
	if _dec != null:
		_tick_video(delta)
	elif _task != -1 and WorkerThreadPool.is_task_completed(_task):
		_photo_decoded()
	elif _task == -1 and _abandoned.is_empty():
		set_process(false)

func _tick_video(delta: float) -> void:
	if _scrubbing and _scrub_to >= 0 and Time.get_ticks_msec() - _last_seek_ms >= SCRUB_SEEK_MS:
		_seek(_scrub_to)
	if _playing:
		_clock_us = mini(_clock_us + int(delta * 1e6), _duration_us)
	_show_frame(_dec.call("poll", _clock_us))
	if _playing and (bool(_dec.call("is_ended")) or _clock_us >= _duration_us):
		_clock_us = _duration_us
		_set_playing(false)
	if bool(_dec.call("is_failed")):
		push_warning("MediaViewer: " + str(_dec.call("get_last_error")))
		_set_playing(false)
	_sync_time()

func _photo_decoded() -> void:
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_loading.visible = false
	var img: Image = _box[0]
	_box = [null]
	if img == null or img.is_empty():
		_fail()
		return
	_image = img
	_texture = ImageTexture.create_from_image(img)
	_picture.texture = _texture

func _exit_tree() -> void:
	close()
	_join_tasks()

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

func _confirm_delete() -> void:
	if _entry.is_empty():
		return
	var target := _entry
	var video := str(target.get("kind", "")) == MediaLibrary.VIDEO
	SettingsRows.confirm(self, "Delete this video?" if video else "Delete this photo?",
		"“%s” will be deleted from this device." % str(target.get("place", "View")), "Delete",
		func() -> void:
			close()
			MediaLibrary.remove(target)
			deleted.emit(target))

func _gui_input(event: InputEvent) -> void:
	# Clicks arrive as touches too (emulate_touch_from_mouse): one path.
	if event is InputEventScreenTouch and event.pressed and _dec != null:
		toggle_play()
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_SPACE and _dec != null:
		toggle_play()
	elif (k == KEY_LEFT or k == KEY_RIGHT) and _dec != null:
		_seek(_clock_us + (5000000 if k == KEY_RIGHT else -5000000))
	elif k == KEY_F and _fullscreen_btn.visible:
		_toggle_fullscreen()
	else:
		return
	get_viewport().set_input_as_handled()
