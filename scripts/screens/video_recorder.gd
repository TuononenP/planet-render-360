class_name VideoRecorder
extends Node

## Records the 360 view as an H.264 MP4 (Record, R). Like a photo it is
## the scene alone at the viewport's resolution (the HUD is a separate
## layer), scaled to the Video quality setting. Frames are read back from
## the GPU without waiting for it (RenderingDevice.texture_get_data_async)
## at FPS of real time, and the native VideoEncoder (AVFoundation on macOS
## and iOS, MediaCodec on Android) converts, scales and encodes them on its
## own thread into a temporary file; a frame that would hold the game loop
## up is dropped instead. Stop finishes the file and saves it the way
## photos are saved. Lives as a child of the view: it stops by itself when
## another place opens, the view closes, hides or changes size, the app goes
## to the background (phones) or after MAX_S. The view's HUD shows `badge`
## while it records (ViewTools).

## Recording ended (by Stop or by itself); the file is being finished.
signal stopped
## The file is saved at `path`, or `failed`, or "" when the person
## cancelled the save. `note` says why when it stopped by itself; `why`
## is the encoder's reason when the video itself couldn't be finished
## ("" when only the save failed).
signal finished(path: String, failed: bool, note: String, why: String)

enum State { IDLE, RECORDING, SAVING }
## Why start() couldn't record: nothing drawn yet (try again), the video
## size is more than the encoder takes (a lower Video quality may work),
## the device can't record the view at all, the file couldn't be made, or
## a recording is still running or saving.
enum StartError { NONE, NOT_DRAWN, TOO_LARGE, UNSUPPORTED, NO_FILE, BUSY }

const FPS := 30
const MAX_S := 600.0
const MAX_IN_FLIGHT := 2
## Where a recording is written while it runs when the desktop Save
## dialog will pick its place; with no dialog (phones) it is written in the
## videos folder itself, so keeping it is a rename, not a copy across
## volumes. Either way the name starts with TEMP_PREFIX until it is kept.
const TEMP_DIR := "user://recordings"
const TEMP_PREFIX := ".rec-"
## Long side of the video for each Video quality choice (720p, 1080p,
## the viewport's own size up to 4K).
const QUALITY_LONG := [1280, 1920, 3840]
const BITS_PER_PIXEL := 0.1
## Pixel layouts VideoEncoder.push_frame takes (VideoEncoder::Format).
const FORMAT_RGBA8 := 0
const FORMAT_BGRA8 := 1
const RESIZED_NOTE := "Recording stopped when the view changed size"
const PAUSED_NOTE := "Recording stopped when the app was paused"
## The encoder's reason when Stop came before any frame was read back
## (VIDEO_NO_FRAMES).
const NO_FRAMES := "no frames were recorded"
const FAILED_NOTE := "Recording stopped"
## VideoEncoder.get_error_kind (VideoErrorKind).
const KIND_NO_ENCODER := 1
const KIND_TOO_LARGE := 2

## Temporary files are swept once per run: a later sweep could take the
## file of a save still under way (_finish outlives its recorder).
static var _swept := false
const SAVED_INSTEAD := "Saved to your videos folder instead"
const RECOVERED_PLACE := "recovered"

var state := State.IDLE
var badge := RecordBadge.new()
## The reason behind the last StartError, for the log.
var last_error := ""
var _v: View360
var _data: LocationData
var _encoder: Object
var _temp := ""
var _started_us := 0
var _next_us := 0
var _in_flight := 0
var _skipped := 0
## Bumped by every start(): a read-back of an earlier recording that lands
## late is ignored.
var _session := 0
var _rd: RenderingDevice
## The view's size (a change stops the recording) and the video's.
var _src := Vector2i.ZERO
var _out := Vector2i.ZERO
## Draws the view at the video's size; only that is read back.
var _scaler: VideoScaler
## Written straight to its final place (Android's Movies), with nothing
## to move once finished.
var _in_place := false

## The native encoder is built and this platform has one, and frames can
## be read back (a RenderingDevice renderer, a real window).
static func supported() -> bool:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_rendering_device() == null:
		return false
	return encoder_available()

static func encoder_available() -> bool:
	return ClassDB.class_exists("VideoEncoder") \
		and bool(ClassDB.class_call_static("VideoEncoder", "is_supported"))

## Both sides of the video are multiples of this: 16 on Android, whose
## hardware encoders pad odd sizes in ways the NDK can't always report.
static func size_align() -> int:
	return 16 if OS.get_name() == "Android" else 2

## The video's size for a `src` viewport: its aspect, the long side capped
## by `quality` (an index into QUALITY_LONG), both sides rounded down to
## multiples of `align` (never larger than the view).
static func output_size(src: Vector2i, quality: int, align: int = 2) -> Vector2i:
	if src.x <= 0 or src.y <= 0:
		return Vector2i.ZERO
	var cap: int = QUALITY_LONG[clampi(quality, 0, QUALITY_LONG.size() - 1)]
	var long_side := maxi(src.x, src.y)
	var out := src if long_side <= cap else Vector2i(src.x * cap / long_side, src.y * cap / long_side)
	return Vector2i(maxi(16, out.x / align * align), maxi(16, out.y / align * align))

static func bitrate(size: Vector2i, fps: int = FPS) -> int:
	return int(float(size.x * size.y * fps) * BITS_PER_PIXEL)

## The encoder's layout for a RenderingDevice texture format; -1 when it
## takes none.
static func frame_format(rd_format: int) -> int:
	match rd_format:
		RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM, RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB:
			return FORMAT_RGBA8
		RenderingDevice.DATA_FORMAT_B8G8R8A8_UNORM, RenderingDevice.DATA_FORMAT_B8G8R8A8_SRGB:
			return FORMAT_BGRA8
	return -1

## "planet-render-360_paris-france_20261101-1730.mp4".
static func file_name(place: String, when: Dictionary) -> String:
	return PhotoMode.file_name(place, when).get_basename() + ".mp4"

## "4:07": minutes and seconds of a recording (Gallery's clock).
static func clock(seconds: float) -> String:
	return MediaViewer.clock_text(seconds)

## Whether a draw `t` µs into the recording takes the frame due at
## `next_us`: up to a quarter frame early still counts, so a display
## drawing at FPS with a little jitter doesn't skip every other frame,
## while on a 60 Hz display (draws half a frame apart) the draw on time
## always wins over the one before it.
static func is_due(t: int, next_us: int, fps: int = FPS) -> bool:
	return t >= next_us - 250000 / fps

## When the frame after one taken at `t` (due at `next_us`) is due: a
## frame on, or a frame from now when drawing fell behind.
static func next_due(t: int, next_us: int, fps: int = FPS) -> int:
	var frame_us := 1000000 / fps
	var next := next_us + frame_us
	return next if next > t else t + frame_us

## The place the recording (or the save under way) was shot at.
func recorded_place() -> String:
	return _data.place_name if _data != null else ""

func is_recording() -> bool:
	return state == State.RECORDING

func elapsed() -> float:
	return float(Time.get_ticks_usec() - _started_us) / 1e6 if _started_us > 0 else 0.0

## Starts recording `v`'s scene.
func start(v: View360, quality: int) -> StartError:
	last_error = ""
	if state != State.IDLE:
		last_error = "already recording or saving"
		return StartError.BUSY
	_v = v
	_data = v._data
	_rd = RenderingServer.get_rendering_device()
	var src := _frame_source()
	if _data == null or src.is_empty():
		last_error = "the scene isn't drawn yet"
		return StartError.NOT_DRAWN
	_src = src["size"]
	var size := output_size(_src, quality, size_align())
	var dir := temp_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	VideoRecorder.sweep()
	var enc: Object = ClassDB.instantiate("VideoEncoder")
	if enc == null:
		last_error = "no video encoder"
		return StartError.UNSUPPORTED
	# Android: straight into Movies where the platform lets native code
	# create a video there (Android 11+), so the gallery lists it.
	_in_place = false
	var target := shared_target(_data.place_name, _local_now())
	if target != "" and bool(enc.call("start", target, size.x, size.y, FPS, bitrate(size))):
		_temp = target
		_in_place = true
	else:
		_temp = ProjectSettings.globalize_path(dir.path_join("%s%d.mp4" % [TEMP_PREFIX, Time.get_ticks_usec()]))
	if not _in_place and not bool(enc.call("start", _temp, size.x, size.y, FPS, bitrate(size))):
		last_error = str(enc.call("get_last_error"))
		DirAccess.remove_absolute(_temp)
		match int(enc.call("get_error_kind")):
			KIND_NO_ENCODER:
				return StartError.UNSUPPORTED
			KIND_TOO_LARGE:
				return StartError.TOO_LARGE if quality > 0 else StartError.UNSUPPORTED
		return StartError.NO_FILE
	_encoder = enc
	_out = size
	_scaler = VideoScaler.new(v._viewport.get_texture(), _src, size)
	add_child(_scaler)
	_session += 1
	_started_us = Time.get_ticks_usec()
	_next_us = 0
	_in_flight = 0
	_skipped = 0
	state = State.RECORDING
	RenderingServer.frame_post_draw.connect(_on_drawn)
	return StartError.NONE

func _ready() -> void:
	VideoRecorder.sweep()

## Once per run, the temporary files a previous run left: a finished video
## (the app quit while it was being saved) is kept in the videos folder;
## a cut-off one (the app crashed while recording) can't play and goes.
static func sweep() -> void:
	if _swept:
		return
	_swept = true
	for d in [TEMP_DIR, PhotoMode.fallback_video_dir()]:
		for f in temp_files(d):
			var path := ProjectSettings.globalize_path(d.path_join(f))
			if is_finished_mp4(path):
				_keep(path, file_name(RECOVERED_PLACE, Time.get_datetime_dict_from_system()))
			DirAccess.remove_absolute(path)

## The temporary video files in `dir` (hidden: their names start with a dot).
static func temp_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	var da := DirAccess.open(dir)
	if da == null:
		return out
	da.include_hidden = true
	for f in da.get_files():
		if f.begins_with(TEMP_PREFIX):
			out.append(f)
	return out

## An MP4 whose index (the moov box) was written: one that plays. Walks
## the top-level boxes without reading the media.
static func is_finished_mp4(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	f.big_endian = true
	var length := f.get_length()
	var at := 0
	while at + 8 <= length:
		f.seek(at)
		var size := f.get_32()
		var kind := f.get_buffer(4).get_string_from_ascii()
		if kind == "moov":
			return true
		if size == 1 and at + 16 <= length:
			size = f.get_64()
		elif size == 0:
			return false
		if size < 8:
			return false
		at += size
	return false

## Android's Movies folder path for a recording of `place` at `when` (the
## minute's name plus its second, so two in a minute never collide), or ""
## elsewhere: Godot reaches that folder only through MediaStore, which
## won't file a video there, but the native encoder can create one by path.
static func shared_target(place: String, when: Dictionary) -> String:
	if OS.get_name() != "Android" or PhotoMode.dir_override != "":
		return ""
	var movies := OS.get_system_dir(OS.SYSTEM_DIR_MOVIES)
	if not movies.is_absolute_path():
		return ""
	# The place's clock has no seconds: the device's give them.
	var second := int(when.get("second", Time.get_datetime_dict_from_system()["second"]))
	var name := "%s-%02d.mp4" % [file_name(place, when).get_basename(), second]
	return movies.path_join(name)

## Asks Android to index a video written into Movies by path, so the
## gallery lists it now rather than at the next idle rescan
## (MediaScannerConnection, through Godot's Java bridge; nothing elsewhere).
static func index_shared(path: String) -> void:
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return
	var runtime := Engine.get_singleton("AndroidRuntime")
	var activity: Variant = runtime.call("getActivity")
	var scanner: Variant = JavaClassWrapper.wrap("android.media.MediaScannerConnection")
	if activity == null or scanner == null:
		push_warning("VideoRecorder: can't ask Android to index " + path)
		return
	scanner.call("scanFile", activity, PackedStringArray([path]), PackedStringArray(["video/mp4"]), null)

## Where this recording is written while it runs (see TEMP_DIR). Android's
## Movies is shared storage, reached through MediaStore rather than plain
## file paths, so the encoder writes privately there and the finished file
## is copied in.
static func temp_dir() -> String:
	if PhotoMode.has_save_dialog() or OS.get_name() == "Android":
		return TEMP_DIR
	return PhotoMode.fallback_video_dir()

## The view's drawn texture now: {rid, size, format}, or {} when there is
## none. The view's render target is remade whenever it changes size, so
## this is looked up for every frame.
func _frame_source() -> Dictionary:
	if not is_instance_valid(_v) or _v._viewport == null:
		return {}
	return _texture_of(_v._viewport)

## `vp`'s drawn texture as the RenderingDevice holds it, or {}.
func _texture_of(vp: Viewport) -> Dictionary:
	if _rd == null:
		return {}
	var tex := vp.get_texture()
	if tex == null:
		return {}
	var rid := RenderingServer.texture_get_rd_texture(tex.get_rid())
	if not rid.is_valid():
		return {}
	var fmt := _rd.texture_get_format(rid)
	if fmt == null or fmt.width <= 0 or fmt.height <= 0:
		return {}
	return {"rid": rid, "size": Vector2i(fmt.width, fmt.height), "format": frame_format(fmt.format)}

func _on_drawn() -> void:
	if not is_recording():
		return
	var t := Time.get_ticks_usec() - _started_us
	if not is_due(t, _next_us):
		return
	_next_us = next_due(t, _next_us)
	if _in_flight >= MAX_IN_FLIGHT:
		_skipped += 1
		return
	var src := _frame_source()
	if src.is_empty():
		_skipped += 1
		return
	if src["size"] != _src:
		# The rest would be squeezed into the first size: keep what was shot.
		stop.call_deferred(RESIZED_NOTE)
		return
	# The scaled copy at the video's size is what is read back.
	var small := _texture_of(_scaler)
	if small.is_empty() or small["size"] != _out or int(small["format"]) < 0:
		_skipped += 1
		return
	_in_flight += 1
	# Through a weak reference: the recorder may be freed before it lands.
	var err := _rd.texture_get_data_async(small["rid"], 0,
		VideoRecorder._deliver.bind(weakref(self), _session, t, small["format"]))
	if err != OK:
		_in_flight -= 1
		_skipped += 1

static func _deliver(bytes: PackedByteArray, rec: WeakRef, session: int, pts: int, format: int) -> void:
	var r := rec.get_ref() as VideoRecorder
	if r != null:
		r._on_frame(bytes, session, pts, format)

func _on_frame(bytes: PackedByteArray, session: int, pts: int, format: int) -> void:
	if session != _session:
		return
	_in_flight -= 1
	if is_recording() and not bool(_encoder.call("push_frame", bytes, _out.x, _out.y, pts, format)):
		_skipped += 1

func _process(_delta: float) -> void:
	if not is_recording():
		return
	if badge.show_time(elapsed()) and is_instance_valid(_v):
		ViewChrome.layout(_v)
	# Not on a new LocationData: the way-ahead streamer swaps one in every
	# stretch of the same place. Opening a place stops it (show_location).
	if not is_instance_valid(_v) or not _v.is_visible_in_tree():
		stop()
	elif bool(_encoder.call("is_failed")):
		# Say so now, not at Stop minutes later.
		stop(FAILED_NOTE)
	elif elapsed() >= MAX_S:
		stop("Recording stopped at %d minutes" % int(MAX_S / 60.0))

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			# The view's HUD frees the badge it holds; one never shown is ours.
			if is_instance_valid(badge) and not badge.is_inside_tree():
				badge.free()
		NOTIFICATION_APPLICATION_PAUSED:
			# Going to the background (phones): finish now, while the
			# hardware encoder still runs (iOS stops it in the background),
			# and keep the file; the toast waits for the app's return.
			if is_recording():
				var path := _finish_now()
				stopped.emit()
				finished.emit(path, path == "", PAUSED_NOTE, "" if path != "" else "the video encoder failed")
		NOTIFICATION_EXIT_TREE:
			# The view is going away, maybe with the app quitting (when no
			# frame would come for a background finish): finish the file
			# now. A save already under way carries on by itself (_finish).
			if is_recording():
				_finish_now()

## Ends the recording on this thread and keeps the file in the videos
## folder with no dialog: a few queued frames and a rename. The path, or
## "" when nothing could be kept.
func _finish_now() -> String:
	state = State.IDLE
	RenderingServer.frame_post_draw.disconnect(_on_drawn)
	_drop_scaler()
	var enc := _encoder
	_encoder = null
	var path := ""
	if bool(enc.call("finish")):
		if _in_place:
			VideoRecorder.index_shared(_temp)
			return _temp
		path = VideoRecorder._keep(_temp, file_name(_data.place_name if _data != null else "", _local_now()))
	DirAccess.remove_absolute(_temp)
	return path

func _drop_scaler() -> void:
	if is_instance_valid(_scaler):
		_scaler.queue_free()
	_scaler = null

## Finishes the file (on a worker thread) and saves it like a photo:
## the Save dialog on desktop, else the Movies (or Pictures) folder.
## `note` (passed on to `finished`) says why when it stopped by itself.
func stop(note: String = "") -> void:
	if not is_recording():
		return
	state = State.SAVING
	RenderingServer.frame_post_draw.disconnect(_on_drawn)
	_drop_scaler()
	stopped.emit()
	var place := _data.place_name if _data != null else ""
	var enc := _encoder
	_encoder = null
	VideoRecorder._finish(weakref(self), enc, _temp, file_name(place, _local_now()), note, get_tree(),
		_in_place)

## The place's local date and time, for the file name.
func _local_now() -> Dictionary:
	return ViewConditions.place_now(_v) if is_instance_valid(_v) else Time.get_datetime_dict_from_system()

## Moves a finished temporary file into the videos folder under a free
## name; the path, or "" when it couldn't be kept.
static func _keep(temp: String, file: String) -> String:
	var dir := PhotoMode.fallback_video_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := PhotoMode.free_path(dir, file)
	return path if PhotoMode.move_file(temp, path) else ""

## Static, so finishing and saving carry on (and clean up the temporary
## file) when the recorder is freed meanwhile; the outcome reaches it
## through `rec` only while it still exists.
static func _finish(rec: WeakRef, enc: Object, temp: String, file: String, note: String,
		tree: SceneTree, in_place: bool = false) -> void:
	var ok := [false]
	await FrameTask.run(func() -> void: ok[0] = bool(enc.call("finish")), "VideoFinish", tree)
	if not ok[0]:
		var why := str(enc.call("get_last_error"))
		push_warning("VideoRecorder: " + why)
		DirAccess.remove_absolute(temp)
		VideoRecorder._report(rec, "", true, note, why if why != "" else "the video encoder failed")
		return
	if in_place:
		VideoRecorder.index_shared(temp)
		VideoRecorder._report(rec, temp, false, note, "")
		return
	var done := func(path: String, failed: bool) -> void:
		if failed:
			# The picked folder couldn't take it: the videos folder keeps
			# it rather than the recording being lost.
			var kept := VideoRecorder._keep(temp, file)
			if kept != "":
				VideoRecorder._report(rec, kept, false, SAVED_INSTEAD, "")
				return
		# Saved (moved away), cancelled, or not saved anywhere.
		DirAccess.remove_absolute(temp)
		VideoRecorder._report(rec, path, failed, note, "")
	PhotoMode.save_file(temp, file, "mp4", "MP4 video", "Save video", done)

static func _report(rec: WeakRef, path: String, failed: bool, note: String, why: String) -> void:
	var r := rec.get_ref() as VideoRecorder
	if r == null:
		return
	r.state = State.IDLE
	r.finished.emit(path, failed, note, why)

## Frames that couldn't be read or encoded in time.
func skipped() -> int:
	return _skipped
