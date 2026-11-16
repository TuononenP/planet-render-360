extends SceneTree

## Headless: godot --headless --script tests/video_recorder_test.gd
## The video recorder's parts that need no window: the output size and
## bit rate, the file name and clock, saving a finished file with no
## dialog, and the native VideoEncoder writing a real MP4 from synthetic
## frames (where the native library and a platform encoder exist): its
## pixel formats, that a second start leaves a recording alone, that
## queuing a frame doesn't copy it, and that a save outlives its recorder.
## Also frame pacing, late read-backs of an earlier recording and the
## start-error toasts. The Record button only shows with a window, so
## headless it must be absent.

var _failures: Array[String] = []
var _dir := ""

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	_dir = ProjectSettings.globalize_path("user://video_recorder_test")
	_cleanup(_dir)
	DirAccess.make_dir_recursive_absolute(_dir)
	_test_sizes()
	_test_names()
	_test_save_file()
	_test_chosen_folder()
	_test_keep_falls_back()
	_test_pacing()
	_test_formats()
	_test_stale_frames()
	_test_start_errors()
	await _test_toast_dismiss()
	var encoded := _test_encoder()
	if encoded:
		_test_second_start()
		_test_push_cost()
		await _test_save_outlives_recorder()
		await _test_save_to_chosen()
		_test_recover_leftovers()
	_test_headless_unsupported()
	_cleanup(_dir)
	if _failures.is_empty():
		print("VIDEO RECORDER OK: sizes, names, save, pacing, formats, stale frames, %s" % ("encoder" if encoded else "encoder skipped (no native build)"))
		quit(0)
	else:
		for f in _failures:
			printerr("VIDEO RECORDER FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _test_sizes() -> void:
	_check(VideoRecorder.output_size(Vector2i(3840, 2160), 1) == Vector2i(1920, 1080), "4K at 1080p: %s" % VideoRecorder.output_size(Vector2i(3840, 2160), 1))
	_check(VideoRecorder.output_size(Vector2i(2560, 1600), 0) == Vector2i(1280, 800), "1600p at 720p")
	_check(VideoRecorder.output_size(Vector2i(1170, 2532), 1) == Vector2i(886, 1920), "a phone upright stays upright: %s" % VideoRecorder.output_size(Vector2i(1170, 2532), 1))
	_check(VideoRecorder.output_size(Vector2i(1001, 667), 2) == Vector2i(1000, 666), "native keeps the size, rounded even")
	_check(VideoRecorder.output_size(Vector2i(5000, 3000), 2).x == 3840, "native caps at 4K")
	_check(VideoRecorder.output_size(Vector2i.ZERO, 1) == Vector2i.ZERO, "no viewport, no size")
	# Android: multiples of 16, which its encoders take without padding.
	var a := VideoRecorder.output_size(Vector2i(1170, 2532), 1, 16)
	_check(a.x % 16 == 0 and a.y % 16 == 0 and a == Vector2i(880, 1920), "16-aligned upright phone: %s" % a)
	_check(VideoRecorder.output_size(Vector2i(1920, 1080), 1, 16) == Vector2i(1920, 1072), "16-aligned 1080p, never larger")
	_check(VideoRecorder.bitrate(Vector2i(1920, 1080)) == 6220800, "1080p30 bit rate: %d" % VideoRecorder.bitrate(Vector2i(1920, 1080)))

func _test_names() -> void:
	# A relative or missing system folder is never used (iOS answers ".").
	_check(not PhotoMode.usable_dir("."), "a relative folder isn't a save folder")
	_check(not PhotoMode.usable_dir(""), "no folder isn't a save folder")
	_check(not PhotoMode.usable_dir("/no/such/folder"), "a missing folder isn't a save folder")
	_check(PhotoMode.usable_dir(ProjectSettings.globalize_path("user://")), "the app's own folder is")
	var vdir := PhotoMode.fallback_video_dir()
	_check(vdir.begins_with("user://") or vdir.is_absolute_path(), "videos go to an absolute folder: %s" % vdir)
	var when := {"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 30}
	_check(VideoRecorder.file_name("Paris, France", when) == "planet-render-360_paris-france_20261101-1730.mp4",
		"file name: %s" % VideoRecorder.file_name("Paris, France", when))
	_check(VideoRecorder.clock(0.4) == "0:00" and VideoRecorder.clock(62.9) == "1:02" and VideoRecorder.clock(600.0) == "10:00",
		"clock")

func _test_save_file() -> void:
	var src := _dir.path_join("src.mp4")
	var f := FileAccess.open(src, FileAccess.WRITE)
	f.store_buffer(PackedByteArray([1, 2, 3, 4]))
	f.close()
	var out := _dir.path_join("out")
	PhotoMode.dir_override = out
	var got: Array = []
	PhotoMode.save_file(src, "clip.mp4", "mp4", "MP4 video", "Save video",
		func(path: String, failed: bool) -> void: got.append_array([path, failed]))
	PhotoMode.dir_override = ""
	_check(got.size() == 2 and not got[1] and str(got[0]) == out.path_join("clip.mp4"), "save_file reports the path: %s" % [got])
	_check(FileAccess.get_file_as_bytes(out.path_join("clip.mp4")) == PackedByteArray([1, 2, 3, 4]), "save_file copies the bytes")
	_check(not FileAccess.file_exists(src), "save_file moves the file (no copy of a large video)")
	# A second save in the same minute keeps the first.
	var f2 := FileAccess.open(src, FileAccess.WRITE)
	f2.store_buffer(PackedByteArray([5, 6]))
	f2.close()
	PhotoMode.dir_override = out
	got.clear()
	PhotoMode.save_file(src, "clip.mp4", "mp4", "MP4 video", "Save video",
		func(path: String, failed: bool) -> void: got.append_array([path, failed]))
	PhotoMode.dir_override = ""
	_check(got.size() == 2 and str(got[0]) == out.path_join("clip-2.mp4"), "a taken name gets -2: %s" % [got])
	_check(FileAccess.get_file_as_bytes(out.path_join("clip.mp4")) == PackedByteArray([1, 2, 3, 4]), "the first save is kept")

## The folder chosen in Settings counts only while it can be written, and
## then the recording is written there from the start.
func _test_chosen_folder() -> void:
	var chosen := _dir.path_join("chosen")
	DirAccess.make_dir_recursive_absolute(chosen)
	UiPrefs.video_dir = ""
	_check(PhotoMode.chosen_video_dir() == "", "no folder chosen asks every time")
	UiPrefs.video_dir = _dir.path_join("missing")
	_check(PhotoMode.chosen_video_dir() == "", "a missing chosen folder isn't used")
	UiPrefs.video_dir = chosen
	_check(PhotoMode.chosen_video_dir() == chosen, "a writable chosen folder is used")
	_check(VideoRecorder.temp_dir() == chosen, "recordings are written in the chosen folder: %s" % VideoRecorder.temp_dir())
	PhotoMode.dir_override = _dir.path_join("out")
	_check(PhotoMode.chosen_video_dir() == "", "the test hook wins over the chosen folder")
	PhotoMode.dir_override = ""
	UiPrefs.video_dir = ""

## A videos folder that can't take the file: the app's own videos folder
## keeps it rather than the recording being lost.
func _test_keep_falls_back() -> void:
	var blocker := _dir.path_join("blocker")
	var b := FileAccess.open(blocker, FileAccess.WRITE)
	b.close()
	var temp := _dir.path_join(".rec-keep.mp4")
	var f := FileAccess.open(temp, FileAccess.WRITE)
	f.store_buffer(PackedByteArray([7, 8]))
	f.close()
	# A folder under a file can never be made.
	PhotoMode.dir_override = blocker.path_join("videos")
	var name := "planet-render-360_keep-test_20261101-1730.mp4"
	var kept := VideoRecorder._keep(temp, name)
	PhotoMode.dir_override = ""
	_check(kept.get_base_dir() == PhotoMode.VIDEO_DIR_FALLBACK and FileAccess.file_exists(kept),
		"kept in the app's own videos folder: %s" % kept)
	_check(not FileAccess.file_exists(temp), "the temporary file is moved")
	DirAccess.remove_absolute(kept)

func _test_pacing() -> void:
	# A draw a little early still takes the frame; half a frame early does not.
	_check(VideoRecorder.is_due(33300, 33333), "a draw 33 µs early takes the frame")
	_check(not VideoRecorder.is_due(10000, 33333), "a draw a frame early waits")
	_check(VideoRecorder.next_due(33300, 33333) == 66666, "the next frame is a frame on: %d" % VideoRecorder.next_due(33300, 33333))
	_check(VideoRecorder.next_due(200000, 33333) == 233333, "behind: the next frame is a frame from now")
	# A display at FPS with ±2 ms of jitter: every draw is taken.
	var next := 0
	var taken := 0
	for i in 300:
		var t := i * 33333 + (2000 if i % 2 == 0 else -2000)
		if VideoRecorder.is_due(t, next):
			next = VideoRecorder.next_due(t, next)
			taken += 1
	_check(taken == 300, "jittered draws at the frame rate are all taken: %d of 300" % taken)
	# A 60 Hz display with a little jitter: every other draw, evenly spaced.
	next = 0
	var pts: Array[int] = []
	for i in 600:
		var t := i * 16667 + (300 if i % 3 == 0 else -300)
		if VideoRecorder.is_due(t, next):
			next = VideoRecorder.next_due(t, next)
			pts.append(t)
	var uneven := 0
	for i in range(1, pts.size()):
		if absi(pts[i] - pts[i - 1] - 33333) > 2000:
			uneven += 1
	_check(pts.size() == 300 and uneven == 0, "60 Hz draws give even 30 fps frames: %d frames, %d uneven" % [pts.size(), uneven])

func _test_formats() -> void:
	# The GPU scaler's box: one bilinear tap up to 2:1, more for larger cuts.
	_check(VideoScaler.taps_for(1.0) == 1 and VideoScaler.taps_for(2.0) == 1, "1-2x is one tap")
	_check(VideoScaler.taps_for(3.0) == 2 and VideoScaler.taps_for(4.0) == 2, "3-4x is two taps a side")
	_check(VideoScaler.taps_for(20.0) == VideoScaler.MAX_TAPS, "taps are capped")
	_check(VideoRecorder.frame_format(RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM) == VideoRecorder.FORMAT_RGBA8, "RGBA8")
	_check(VideoRecorder.frame_format(RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB) == VideoRecorder.FORMAT_RGBA8, "RGBA8 sRGB")
	_check(VideoRecorder.frame_format(RenderingDevice.DATA_FORMAT_B8G8R8A8_UNORM) == VideoRecorder.FORMAT_BGRA8, "BGRA8")
	_check(VideoRecorder.frame_format(RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT) == -1, "HDR half float is scaled to RGBA8 first")
	_check(VideoRecorder.frame_format(RenderingDevice.DATA_FORMAT_R32_SFLOAT) == -1, "a format the encoder can't take")

## A read-back of an earlier recording landing after a new start neither
## counts against the new one nor reaches its encoder.
func _test_stale_frames() -> void:
	var rec := VideoRecorder.new()
	rec._session = 2
	rec._in_flight = 1
	rec._on_frame(PackedByteArray(), 1, 999999999, VideoRecorder.FORMAT_RGBA8)
	_check(rec._in_flight == 1, "a late frame of an earlier recording is ignored")
	rec._on_frame(PackedByteArray(), 2, 0, VideoRecorder.FORMAT_RGBA8)
	_check(rec._in_flight == 0, "this recording's frame lands")
	# A read-back landing after the recorder is gone goes nowhere.
	var gone: WeakRef = weakref(rec)
	rec.free()
	VideoRecorder._deliver(PackedByteArray(), gone, 2, 0, VideoRecorder.FORMAT_RGBA8)

func _test_start_errors() -> void:
	for e: int in VideoRecorder.StartError.values():
		if e != VideoRecorder.StartError.NONE:
			_check(ViewTools.START_ERRORS.has(e), "a toast for start error %d" % e)
	_check(ViewTools.START_ERRORS[VideoRecorder.StartError.NOT_DRAWN][1] != ViewTools.START_ERRORS[VideoRecorder.StartError.TOO_LARGE][1],
		"too large doesn't say try again in a moment")

## An error toast (one that doesn't time out) has a close button that
## dismisses it; a timed toast has none; a tap dismisses either.
func _test_toast_dismiss() -> void:
	var t := Toast.new()
	root.add_child(t)
	t.show_message("Couldn't start recording", "Check there is space.", "error")
	_check(t._close.visible and t._timer.is_stopped(), "an error toast stays and has a close button")
	t._close.pressed.emit()
	for i in 30:
		await process_frame
	_check(not t.visible, "the close button dismisses it")
	t.show_message("Video saved", "clip.mp4", "good")
	_check(not t._close.visible and not t._timer.is_stopped(), "a timed toast has no close button")
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	t._gui_input(tap)
	for i in 30:
		await process_frame
	_check(not t.visible, "a tap dismisses a toast")
	t.queue_free()

## Two seconds of a moving gradient through the real encoder; the file
## must be an MP4 (an ftyp box first) of a plausible size.
func _test_encoder() -> bool:
	if not VideoRecorder.encoder_available():
		return false
	var enc: Object = ClassDB.instantiate("VideoEncoder")
	var path := _dir.path_join("enc.mp4")
	_check(not bool(enc.call("start", path, 15, 10, 30, 100000)), "odd sizes are refused")
	_check(str(enc.call("get_last_error")) != "", "a refusal says why")
	_check(int(enc.call("get_error_kind")) == 0, "a bad size is not a missing encoder")
	_check(not bool(enc.call("is_failed")) or not bool(enc.call("is_recording")), "a refused start isn't recording")
	var w := 640
	var h := 360
	_check(bool(enc.call("start", path, w, h, 30, 2000000)), "start: %s" % enc.call("get_last_error"))
	var sent := 0
	for i in 60:
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color.from_hsv(float(i) / 60.0, 0.8, 0.9))
		img.fill_rect(Rect2i(i * 16, 100, 120, 120), Color.WHITE)
		# The queue is short: wait for room as a slow frame would.
		var tries := 0
		while not bool(enc.call("push_frame", img.get_data(), w, h, i * 33333)) and tries < 200:
			OS.delay_msec(5)
			tries += 1
		sent += 1 if tries < 200 else 0
	_check(not bool(enc.call("push_frame", PackedByteArray(), w, h, 9999999)), "a short frame is refused")
	var big := PackedByteArray()
	big.resize(w * h * 16)
	_check(not bool(enc.call("push_frame", big, w * 2, h * 2, 9999999)), "a frame not at the video's size is refused")
	var px := PackedByteArray()
	px.resize(w * h * 4)
	_check(not bool(enc.call("push_frame", px, w, h, 0)), "a frame out of order is refused")
	_check(bool(enc.call("finish")), "finish: %s" % enc.call("get_last_error"))
	_check(int(enc.call("get_encoded_frames")) == sent and sent == 60, "encoded %d of %d" % [enc.call("get_encoded_frames"), sent])
	var bytes := FileAccess.get_file_as_bytes(path)
	_check(bytes.size() > 4096, "the MP4 has content: %d bytes" % bytes.size())
	_check(bytes.size() > 8 and bytes.slice(4, 8).get_string_from_ascii() == "ftyp", "the file is an MP4")
	_check(not bool(enc.call("finish")), "finishing twice does nothing")
	return true

## A start while recording is refused and leaves that recording intact.
func _test_second_start() -> void:
	var enc: Object = ClassDB.instantiate("VideoEncoder")
	var path := _dir.path_join("second.mp4")
	_check(bool(enc.call("start", path, 64, 64, 30, 500000)), "first start")
	var px := PackedByteArray()
	px.resize(64 * 64 * 4)
	px.fill(200)
	var pushed := 0
	for i in 10:
		if i == 5:
			_check(not bool(enc.call("start", _dir.path_join("other.mp4"), 64, 64, 30, 500000)), "a second start is refused")
		while not bool(enc.call("push_frame", px, 64, 64, i * 33333)):
			OS.delay_msec(2)
		pushed += 1
	_check(bool(enc.call("finish")), "the first recording still finishes: %s" % enc.call("get_last_error"))
	_check(int(enc.call("get_encoded_frames")) == pushed, "every frame encoded after the refused start")
	_check(not FileAccess.file_exists(_dir.path_join("other.mp4")), "the refused start wrote nothing")

## Queuing a 4K frame shares the array instead of copying 33 MB.
func _test_push_cost() -> void:
	var enc: Object = ClassDB.instantiate("VideoEncoder")
	# Frames come at the video's size (VideoScaler scales on the GPU).
	_check(bool(enc.call("start", _dir.path_join("big.mp4"), 3840, 2160, 30, 8000000)),
		"start for 4K frames: %s" % enc.call("get_last_error"))
	var frames: Array[PackedByteArray] = []
	for i in 4:
		var px := PackedByteArray()
		px.resize(3840 * 2160 * 4)
		px.fill(40 * i)
		frames.append(px)
	var t0 := Time.get_ticks_usec()
	var queued := 0
	for i in 4:
		queued += 1 if bool(enc.call("push_frame", frames[i], 3840, 2160, i * 33333)) else 0
	var each_ms := float(Time.get_ticks_usec() - t0) / 1000.0 / 4.0
	_check(queued >= 1, "4K frames queue")
	_check(each_ms < 1.0, "queuing a 4K frame takes %.2f ms (no copy)" % each_ms)
	enc.call("finish")

## Finishing and saving carry on after the recorder is freed, and still
## report to one that lives.
func _test_save_outlives_recorder() -> void:
	var out := _dir.path_join("out")
	PhotoMode.dir_override = out
	for alive in [false, true]:
		var temp := _dir.path_join("temp-%s.mp4" % alive)
		var enc: Object = ClassDB.instantiate("VideoEncoder")
		enc.call("start", temp, 64, 64, 30, 500000)
		var px := PackedByteArray()
		px.resize(64 * 64 * 4)
		for i in 5:
			while not bool(enc.call("push_frame", px, 64, 64, i * 33333)):
				OS.delay_msec(2)
		var rec := VideoRecorder.new()
		root.add_child(rec)
		rec.state = VideoRecorder.State.SAVING
		var got: Array = []
		rec.finished.connect(func(p: String, f: bool, n: String, why: String) -> void: got.append_array([p, f, n, why]))
		var name := "saved-%s.mp4" % alive
		VideoRecorder._finish(weakref(rec), enc, temp, name, "note", self)
		if not alive:
			rec.free()
		var frames := 0
		while not FileAccess.file_exists(out.path_join(name)) and frames < 600:
			await process_frame
			frames += 1
		await process_frame
		_check(FileAccess.file_exists(out.path_join(name)), "saved with the recorder %s" % ("alive" if alive else "freed"))
		_check(not FileAccess.file_exists(temp), "the temporary file is removed (%s)" % ("alive" if alive else "freed"))
		if alive:
			_check(got == [out.path_join(name), false, "note", ""] and rec.state == VideoRecorder.State.IDLE,
				"a live recorder hears the outcome: %s" % [got])
			rec.queue_free()
	# Stop before any frame: the encoder's reason comes through, so the
	# toast doesn't blame the disk.
	var empty: Object = ClassDB.instantiate("VideoEncoder")
	var empty_temp := _dir.path_join("temp-empty.mp4")
	empty.call("start", empty_temp, 64, 64, 30, 500000)
	var rec2 := VideoRecorder.new()
	root.add_child(rec2)
	var why: Array = []
	rec2.finished.connect(func(p: String, f: bool, _n: String, w: String) -> void: why.append_array([p, f, w]))
	VideoRecorder._finish(weakref(rec2), empty, empty_temp, "empty.mp4", "", self)
	var n := 0
	while why.is_empty() and n < 600:
		await process_frame
		n += 1
	_check(why == ["", true, VideoRecorder.NO_FRAMES], "an empty recording says nothing was recorded: %s" % [why])
	_check(not FileAccess.file_exists(empty_temp), "an empty recording leaves no file")
	_check(VideoRecorder.temp_files(out).is_empty(), "saves leave no temporary files: %s" % [VideoRecorder.temp_files(out)])
	rec2.queue_free()
	PhotoMode.dir_override = ""

## With a folder chosen in Settings the video saves there with no dialog.
func _test_save_to_chosen() -> void:
	var chosen := _dir.path_join("chosen-save")
	DirAccess.make_dir_recursive_absolute(chosen)
	UiPrefs.video_dir = chosen
	var temp := chosen.path_join(VideoRecorder.TEMP_PREFIX + "chosen.mp4")
	var enc: Object = ClassDB.instantiate("VideoEncoder")
	enc.call("start", temp, 64, 64, 30, 500000)
	var px := PackedByteArray()
	px.resize(64 * 64 * 4)
	for i in 5:
		while not bool(enc.call("push_frame", px, 64, 64, i * 33333)):
			OS.delay_msec(2)
	var rec := VideoRecorder.new()
	root.add_child(rec)
	rec.state = VideoRecorder.State.SAVING
	var got: Array = []
	rec.finished.connect(func(p: String, f: bool, n: String, why: String) -> void: got.append_array([p, f, n, why]))
	VideoRecorder._finish(weakref(rec), enc, temp, "chosen.mp4", "", self)
	var n := 0
	while got.is_empty() and n < 600:
		await process_frame
		n += 1
	_check(got == [chosen.path_join("chosen.mp4"), false, "", ""], "saved to the chosen folder: %s" % [got])
	_check(VideoRecorder.temp_files(chosen).is_empty(), "no temporary file is left in the chosen folder")
	rec.queue_free()
	UiPrefs.video_dir = ""

## A run that quit mid-save leaves a finished temporary video: the next
## run keeps it; one cut off mid-recording (no index) can't play and goes.
func _test_recover_leftovers() -> void:
	var finished := _dir.path_join("enc.mp4")
	_check(VideoRecorder.is_finished_mp4(finished), "a finished MP4 has its index")
	var whole := FileAccess.get_file_as_bytes(finished)
	var out := _dir.path_join("leftovers")
	DirAccess.make_dir_recursive_absolute(out)
	var done_temp := out.path_join(VideoRecorder.TEMP_PREFIX + "1.mp4")
	var cut_temp := out.path_join(VideoRecorder.TEMP_PREFIX + "2.mp4")
	var f := FileAccess.open(done_temp, FileAccess.WRITE)
	f.store_buffer(whole)
	f.close()
	# Cut off: the media box header, no index after it.
	f = FileAccess.open(cut_temp, FileAccess.WRITE)
	f.store_buffer(whole.slice(0, 64))
	f.close()
	_check(not VideoRecorder.is_finished_mp4(cut_temp), "a cut-off MP4 has no index")
	PhotoMode.dir_override = out
	VideoRecorder._swept = false
	VideoRecorder.sweep()
	PhotoMode.dir_override = ""
	_check(VideoRecorder.temp_files(out).size() == 0, "no temporary files stay: %s" % [VideoRecorder.temp_files(out)])
	var names := Array(DirAccess.get_files_at(out))
	_check(names.size() == 1 and str(names[0]).contains("_recovered_") and FileAccess.get_file_as_bytes(out.path_join(names[0])) == whole,
		"the finished video is kept: %s" % [names])
	for n in names:
		DirAccess.remove_absolute(out.path_join(n))
	DirAccess.remove_absolute(out)

func _test_headless_unsupported() -> void:
	_check(not VideoRecorder.supported(), "headless has no frames to record")

## Removes the test folder with everything in it (chosen-save, blocker...),
## so a file left by an earlier run cannot rename the next run's saves.
func _cleanup(d: String) -> void:
	for sub in DirAccess.get_directories_at(d):
		_cleanup(d.path_join(sub))
	for f in DirAccess.get_files_at(d):
		DirAccess.remove_absolute(d.path_join(f))
	DirAccess.remove_absolute(d)
