class_name PhotoMode
extends RefCounted

## Photo mode: the 360 view as a picture. The capture is the scene at the
## viewport's full resolution (the HUD is a separate layer, so it is never
## in the frame), optionally stamped with the place name, coordinates,
## time and date, and the data credit (attribution is required anyway),
## then saved: desktop opens the system "Save as" dialog; where there is
## none (phones) the PNG goes to the Pictures folder, or the app's own
## photos folder when the system one is not writable. Handing it to a share
## sheet needs a platform plugin the project does not ship, so mobile
## saves instead of sharing.

const DIR_FALLBACK := "user://photos"
## Test hook: when non-empty, saves with no dialog go here instead.
static var dir_override := ""
const PREFIX := "planet-render-360"
const DRAW_WAIT_MS := 2000

## "paris-france" from "Paris, France": lowercase letters and digits
## joined by single dashes (accented and non-Latin letters are kept).
static func slug(text: String) -> String:
	var out := ""
	var dash := false
	for ch in text.to_lower().strip_edges():
		var code := ch.unicode_at(0)
		if (code >= 97 and code <= 122) or (code >= 48 and code <= 57):
			out += ch
			dash = false
		elif code > 127 and ch.to_lower() != ch.to_upper():
			out += ch
			dash = false
		elif not dash and out != "":
			out += "-"
			dash = true
	return out.trim_suffix("-")

## "planet-render-360_paris-france_20261101-1730.png"; `when` is a
## {year, month, day, hour, minute} dictionary.
static func file_name(place: String, when: Dictionary) -> String:
	var s := slug(place)
	return "%s_%s%s_%04d%02d%02d-%02d%02d.png" % [PREFIX, s, "" if s != "" else "view",
		int(when.get("year", 2026)), int(when.get("month", 1)), int(when.get("day", 1)),
		int(when.get("hour", 0)), int(when.get("minute", 0))]

## The stamp's three lines: place, "coordinates · time, date", credit.
static func stamp_lines(place: String, lat: float, lon: float, time_text: String,
		date_text: String, attribution: String) -> Array[String]:
	var when := time_text if date_text == "" else "%s, %s" % [time_text, date_text]
	var lines: Array[String] = [place, "%s · %s" % [UiTheme.coords(lat, lon), when]]
	if attribution != "":
		lines.append(attribution)
	return lines

## Font size unit of the stamp for a picture `h` pixels tall.
static func stamp_unit(h: int) -> float:
	return clampf(float(h) / 48.0, 14.0, 60.0)

## Where photos go with no save dialog.
static func fallback_dir() -> String:
	if dir_override != "":
		return dir_override
	var pictures := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if pictures != "" and DirAccess.dir_exists_absolute(pictures):
		return pictures
	return DIR_FALLBACK

## `photo` with the stamp rendered over its lower left (needs a window:
## a SubViewport draws the text). Returns `photo` itself if nothing could
## be rendered.
static func stamped(host: Node, photo: Image, lines: Array[String]) -> Image:
	var size := photo.get_size()
	var u := stamp_unit(size.y)
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var pic := TextureRect.new()
	pic.texture = ImageTexture.create_from_image(photo)
	pic.size = Vector2(size)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vp.add_child(pic)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.62))
	var scrim_tex := GradientTexture2D.new()
	scrim_tex.gradient = g
	scrim_tex.fill_from = Vector2(0, 0)
	scrim_tex.fill_to = Vector2(0, 1)
	scrim_tex.width = 4
	scrim_tex.height = 64
	var scrim := TextureRect.new()
	scrim.texture = scrim_tex
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	var scrim_h := minf(float(size.y), u * 9.0)
	scrim.position = Vector2(0, float(size.y) - scrim_h)
	scrim.size = Vector2(float(size.x), scrim_h)
	vp.add_child(scrim)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(u * 0.1))
	col.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.offset_left = u * 1.2
	col.offset_right = -u * 1.2
	col.offset_bottom = -u * 1.0
	vp.add_child(col)
	var white := Color(1, 1, 1, 0.96)
	if lines.size() > 0:
		col.add_child(UiTheme.display_label(lines[0], int(u * 1.9), white))
	if lines.size() > 1:
		var where := UiTheme.data_label(lines[1], int(u * 0.95), Color(white, 0.92), true)
		where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(where)
	if lines.size() > 2:
		var credit := UiTheme.label(lines[2], int(u * 0.7), Color(white, 0.7))
		credit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(credit)
	host.add_child(vp)
	# Two drawn frames; a window that is not drawing (hidden, minimised)
	# gives the plain picture after DRAW_WAIT_MS instead of waiting for ever.
	var drawn := [0]
	var on_draw := func() -> void: drawn[0] += 1
	RenderingServer.frame_post_draw.connect(on_draw)
	var started := Time.get_ticks_msec()
	while drawn[0] < 2 and Time.get_ticks_msec() - started < DRAW_WAIT_MS:
		await host.get_tree().process_frame
	RenderingServer.frame_post_draw.disconnect(on_draw)
	var out: Image = vp.get_texture().get_image() if drawn[0] >= 2 else null
	vp.queue_free()
	if out == null or out.is_empty() or out.get_size() != size:
		return photo
	return out

## `img` as PNG bytes, encoded on a worker thread, a frame at a time:
## encoding a full-size photo is pure CPU work, and on the main thread
## it froze the app (the macOS beachball) between the shutter flash and
## the save dialog. `img` is only read by the worker; the caller must
## not modify it meanwhile.
static func encode_png_async(img: Image, tree: SceneTree) -> PackedByteArray:
	var box: Array = [PackedByteArray()]
	await FrameTask.run(func() -> void: box[0] = img.save_png_to_buffer(), "PhotoEncode", tree)
	return box[0]

## Saves `img` as `file`: the system dialog where there is one, else the
## Pictures / photos folder. `done(path, failed)` gets the saved path; ""
## with failed false when the person cancelled, failed true when the write
## did not succeed (no space, a read-only folder).
static func save(img: Image, file: String, done: Callable) -> void:
	_save(file, "png", "PNG image", "Save photo",
		func(path: String) -> bool: return img.save_png(path) == OK, done)

## The same for a finished file's bytes (a 360° JPEG with its metadata);
## `extension` is "jpg", `kind` the dialog's filter name.
static func save_bytes(bytes: PackedByteArray, file: String, extension: String, kind: String,
		title: String, done: Callable) -> void:
	_save(file, extension, kind, title, func(path: String) -> bool: return _write_bytes(bytes, path), done)

## The extensions a typed name may carry for `extension` ("jpg" also
## accepts "jpeg"); any other name gets `extension` appended.
static func accepted_extensions(extension: String) -> Array[String]:
	var out: Array[String] = [extension]
	if extension == "jpg":
		out.append("jpeg")
	return out

static func _save(file: String, extension: String, kind: String, title: String,
		write: Callable, done: Callable) -> void:
	var accepted := accepted_extensions(extension)
	if dir_override == "" and not OS.has_feature("mobile") \
			and DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var filter := ", ".join(accepted.map(func(e: String) -> String: return "*." + e))
		var err := DisplayServer.file_dialog_show(title, fallback_dir(), file, false,
			DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(["%s ; %s" % [filter, kind]]),
			func(ok: bool, paths: PackedStringArray, _filter: int) -> void:
				if not ok or paths.is_empty():
					done.call("", false)
					return
				var path := paths[0]
				if not path.get_extension().to_lower() in accepted:
					path += "." + extension
				_report(write, path, done))
		if err == OK:
			return
	var dir := fallback_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	_report(write, dir.path_join(file), done)

## Runs the write and reports it to `done(path, failed)`.
static func _report(write: Callable, path: String, done: Callable) -> void:
	var ok: bool = write.call(path)
	done.call(path if ok else "", not ok)

static func _write_bytes(bytes: PackedByteArray, path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	var ok := f.get_error() == OK
	f.close()
	return ok
