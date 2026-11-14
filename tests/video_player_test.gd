extends SceneTree

## Headless: godot --headless --script tests/video_player_test.gd
## Gallery's photos and videos: MediaLibrary's file names, index, import
## and delete, and (where the native library has a platform decoder) the
## VideoDecoder playing back an MP4 the VideoEncoder wrote: its size and
## length, frames in order from time 0, exact seeks, the end, and the
## card thumbnail.

const W := 320
const H := 180
const FPS := 30
const COLORS: Array[Color] = [Color(0.9, 0.1, 0.1), Color(0.1, 0.8, 0.1), Color(0.1, 0.2, 0.9)]

var _failures: Array[String] = []
var _dir := ""

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	_dir = ProjectSettings.globalize_path("user://video_player_test")
	DirAccess.make_dir_recursive_absolute(_dir)
	_test_names()
	_test_library()
	var decoded := false
	if MediaLibrary.can_play() and VideoRecorder.encoder_available():
		var path := _encode()
		if path != "":
			_test_decoder(path)
			_test_thumbnail(path)
			decoded = true
	_cleanup()
	if _failures.is_empty():
		print("VIDEO PLAYER OK: names, library, %s" % ("decoder" if decoded else "decoder skipped (no native build)"))
		quit(0)
	else:
		for f in _failures:
			printerr("VIDEO PLAYER FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _test_names() -> void:
	_check(MediaLibrary.kind_of_name("planet-render-360_paris-france_20261101-1730.png") == MediaLibrary.PHOTO, "a photo")
	_check(MediaLibrary.kind_of_name("planet-render-360_paris-france_20261101-1730.mp4") == MediaLibrary.VIDEO, "a video")
	_check(MediaLibrary.kind_of_name("planet-render-360_paris-france_360_20261101-1730.jpg") == "", "a 360° photo is Gallery's other tab")
	_check(MediaLibrary.kind_of_name("holiday.png") == "", "someone else's picture")
	_check(MediaLibrary.kind_of_name(".planet-render-360-rec123.mp4") == "", "a recording's temporary file")
	var meta := MediaLibrary.parse_file_name("planet-render-360_skywheel-helsinki_20261114-2221.mp4")
	_check(str(meta.get("place", "")) == "Skywheel Helsinki", "place from the name: %s" % meta)
	var want := Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 11, "day": 14, "hour": 22, "minute": 21, "second": 0})
	_check(is_equal_approx(float(meta.get("timestamp", 0.0)), float(want)), "time from the name")
	_check(str(MediaLibrary.parse_file_name("planet-render-360_view_20261114-2221-2.png").get("place", "")) == "View",
		"a second save that minute")
	var user := OS.get_user_data_dir()
	_check(MediaLibrary.stored_path(user + "/videos/a.mp4") == "user://videos/a.mp4", "app files are kept as user://")
	_check(MediaLibrary.stored_path("/Users/x/Movies/a.mp4") == "/Users/x/Movies/a.mp4", "others keep their path")

func _test_library() -> void:
	MediaLibrary.dir_override = _dir.path_join("lib")
	PhotoMode.dir_override = _dir.path_join("saves")
	DirAccess.make_dir_recursive_absolute(PhotoMode.dir_override)
	var photo := PhotoMode.dir_override.path_join("planet-render-360_oslo-norway_20261110-0900.png")
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	img.fill(Color.ORANGE)
	img.save_png(photo)
	# An earlier save is adopted once; a 360° photo and others are not.
	img.save_png(PhotoMode.dir_override.path_join("unrelated.png"))
	_check(MediaLibrary.import_existing() == 1, "one earlier photo adopted")
	_check(MediaLibrary.import_existing() == 0, "nothing adopted twice")
	var rows := MediaLibrary.entries(MediaLibrary.PHOTO)
	_check(rows.size() == 1 and str(rows[0]["place"]) == "Oslo Norway", "the adopted photo: %s" % [rows])
	_check(MediaLibrary.entries(MediaLibrary.VIDEO).is_empty(), "no videos yet")
	# A new save goes first, newest first.
	var second := PhotoMode.dir_override.path_join("planet-render-360_rome-italy_20261111-0900.png")
	img.save_png(second)
	var added := MediaLibrary.add(second, MediaLibrary.PHOTO, "Rome, Italy", {"width": 64, "height": 32})
	_check(not added.is_empty() and int(added["width"]) == 64, "added with its size")
	rows = MediaLibrary.entries()
	_check(rows.size() == 2 and str(rows[0]["place"]) == "Rome, Italy", "newest first")
	_check(MediaLibrary.add(_dir.path_join("missing.png"), MediaLibrary.PHOTO, "X").is_empty(), "a missing file isn't added")
	# Thumbnails come from the file, and teach the size to the index.
	var learnt := MediaLibrary.rebuild_thumb(rows[1])
	_check(bool(learnt.get("ok", false)) and MediaLibrary.has_thumb(rows[1]), "thumbnail made")
	_check(int(learnt.get("width", 0)) == 64, "size learnt: %s" % learnt)
	MediaLibrary.update(rows[1], {"width": 64, "height": 32})
	_check(int(MediaLibrary.entries()[1].get("width", 0)) == 64, "update merges into the row")
	# A file deleted elsewhere drops out; Delete removes the file itself.
	DirAccess.remove_absolute(photo)
	_check(MediaLibrary.entries().size() == 1, "a gone file is pruned")
	_check(MediaLibrary.remove(added) and not FileAccess.file_exists(second), "delete removes the file")
	_check(MediaLibrary.entries().is_empty(), "and its row")
	MediaLibrary.dir_override = ""
	PhotoMode.dir_override = ""

## A 3 s clip: a second each of red, green and blue.
func _encode() -> String:
	var enc: Object = ClassDB.instantiate("VideoEncoder")
	var path := _dir.path_join("clip.mp4")
	if not bool(enc.call("start", path, W, H, FPS, 1000000)):
		_failures.append("encoder start: %s" % enc.call("get_last_error"))
		return ""
	for i in FPS * 3:
		var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
		img.fill(COLORS[i / FPS])
		var tries := 0
		while not bool(enc.call("push_frame", img.get_data(), W, H, i * 1000000 / FPS)) and tries < 400:
			OS.delay_msec(5)
			tries += 1
	if not bool(enc.call("finish")):
		_failures.append("encoder finish: %s" % enc.call("get_last_error"))
		return ""
	return path

## The newest frame due at `usec`, waiting for the decoder to reach it.
func _frame_at(dec: Object, usec: int) -> PackedByteArray:
	var got := PackedByteArray()
	for i in 400:
		var f: PackedByteArray = dec.call("poll", usec)
		if not f.is_empty():
			got = f
		if not got.is_empty() and (int(dec.call("get_frame_pts")) >= usec - 1000000 / FPS or bool(dec.call("is_ended"))):
			# Keep taking frames until the newest one due is handed over.
			OS.delay_msec(20)
			var more: PackedByteArray = dec.call("poll", usec)
			return more if not more.is_empty() else got
		OS.delay_msec(5)
	return got

func _color_of(frame: PackedByteArray) -> Color:
	if frame.size() < W * H * 4:
		return Color.BLACK
	var i := ((H / 2) * W + W / 2) * 4
	return Color8(frame[i], frame[i + 1], frame[i + 2])

func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.12 and absf(a.g - b.g) < 0.12 and absf(a.b - b.b) < 0.12

func _test_decoder(path: String) -> void:
	var dec: Object = ClassDB.instantiate("VideoDecoder")
	_check(not bool(dec.call("open", _dir.path_join("nothing.mp4"))), "a missing file doesn't open")
	_check(str(dec.call("get_last_error")) != "", "and says why")
	_check(bool(dec.call("open", path)), "open: %s" % dec.call("get_last_error"))
	_check(int(dec.call("get_width")) == W and int(dec.call("get_height")) == H,
		"size %dx%d" % [dec.call("get_width"), dec.call("get_height")])
	var dur := int(dec.call("get_duration_usec"))
	_check(dur > 2800000 and dur < 3200000, "length %d µs" % dur)
	var first := _frame_at(dec, 0)
	_check(int(dec.call("get_frame_pts")) == 0, "the first frame is at 0: %d" % dec.call("get_frame_pts"))
	_check(_near(_color_of(first), COLORS[0]), "first frame red: %s" % _color_of(first))
	_check(dec.call("poll", 0).is_empty(), "no newer frame at the same time")
	var mid := _frame_at(dec, 1500000)
	_check(_near(_color_of(mid), COLORS[1]), "1.5 s played on is green: %s" % _color_of(mid))
	# Seeks back and forward land on the frame shown at that time.
	dec.call("seek", 300000)
	var back := _frame_at(dec, 300000)
	_check(_near(_color_of(back), COLORS[0]), "seek back to 0.3 s is red: %s" % _color_of(back))
	_check(absi(int(dec.call("get_frame_pts")) - 300000) <= 1000000 / FPS, "at 0.3 s: %d" % dec.call("get_frame_pts"))
	dec.call("seek", 2500000)
	var fwd := _frame_at(dec, 2500000)
	_check(_near(_color_of(fwd), COLORS[2]), "seek to 2.5 s is blue: %s" % _color_of(fwd))
	_frame_at(dec, dur + 1000000)
	var ended := false
	for i in 200:
		dec.call("poll", dur + 1000000)
		if bool(dec.call("is_ended")):
			ended = true
			break
		OS.delay_msec(5)
	_check(ended, "the end is reached")
	_check(not bool(dec.call("is_failed")), "no failure: %s" % dec.call("get_last_error"))
	dec.call("seek", 0)
	_check(not bool(dec.call("is_ended")), "a seek after the end plays again")
	_check(_near(_color_of(_frame_at(dec, 0)), COLORS[0]), "and starts red")
	dec.call("close")

func _test_thumbnail(path: String) -> void:
	var t: Dictionary = ClassDB.class_call_static("VideoDecoder", "thumbnail", path, 100)
	_check(int(t.get("width", 0)) == 100 and int(t.get("height", 0)) == 56, "thumbnail fits 100: %s×%s" % [t.get("width"), t.get("height")])
	_check((t.get("data", PackedByteArray()) as PackedByteArray).size() == 100 * 56 * 4, "thumbnail pixels")
	_check(ClassDB.class_call_static("VideoDecoder", "thumbnail", _dir.path_join("nothing.mp4"), 100).is_empty(),
		"no thumbnail without a file")
	MediaLibrary.dir_override = _dir.path_join("lib")
	var e := MediaLibrary.add(path, MediaLibrary.VIDEO, "Clip")
	var learnt := MediaLibrary.rebuild_thumb(e)
	_check(bool(learnt.get("ok", false)) and MediaLibrary.has_thumb(e), "a video card thumbnail")
	_check(absf(float(learnt.get("duration_s", 0.0)) - 3.0) < 0.2, "its length: %s" % learnt)
	MediaLibrary.dir_override = ""

func _cleanup() -> void:
	_rm(_dir)

func _rm(d: String) -> void:
	for f in DirAccess.get_files_at(d):
		DirAccess.remove_absolute(d.path_join(f))
	for sub in DirAccess.get_directories_at(d):
		_rm(d.path_join(sub))
	DirAccess.remove_absolute(d)
