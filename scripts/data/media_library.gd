class_name MediaLibrary
extends RefCounted

## The photos and videos the viewer saved, for Gallery's Photos and
## Videos tabs. Unlike PanoramaLibrary it keeps no copy: a video is too
## large to store twice, so each save registers the file where it landed
## (the picked folder on desktop, Pictures / Movies or the app's own
## folders elsewhere) in a JSON index under user://media/, with a small
## thumbnail. import_existing() adopts earlier saves from the folders
## saves go to without a dialog. Deleting removes the file itself.

const DIR := "user://media"
const INDEX_NAME := "index.json"
const THUMB_DIR := "thumbs"
const PHOTO := "photo"
const VIDEO := "video"
## Longest side of a video thumbnail's decoded frame (PlaceThumb crops it).
const VIDEO_THUMB_PX := 640

## Test hook (PanoramaLibrary.dir_override precedent).
static var dir_override := ""

static func library_dir() -> String:
	return dir_override if dir_override != "" else DIR

static func index_path() -> String:
	return library_dir().path_join(INDEX_NAME)

## The file's path to open: entries keep files under the app's data
## folder as user:// (its absolute path changes when iOS reinstalls).
static func path_for(entry: Dictionary) -> String:
	var p := str(entry.get("path", ""))
	return ProjectSettings.globalize_path(p) if p.begins_with("user://") else p

static func thumb_path_for(entry: Dictionary) -> String:
	return library_dir().path_join(THUMB_DIR).path_join(str(entry.get("path", "")).md5_text() + ".jpg")

## `path` as an entry stores it: user:// inside the app's data folder.
static func stored_path(path: String) -> String:
	if path.begins_with("user://"):
		return path
	var user := OS.get_user_data_dir()
	if user != "" and path.begins_with(user + "/"):
		return "user://" + path.substr(user.length() + 1)
	return path

## True where the native VideoDecoder exists (macOS, iOS, Android builds).
static func can_play() -> bool:
	return ClassDB.class_exists("VideoDecoder") \
		and bool(ClassDB.class_call_static("VideoDecoder", "is_supported"))

# --- Index ---

## Entries of `kind` ("" for all), newest first. A row whose file is gone
## from its folder is pruned (and the index rewritten); one whose folder
## can't be reached (an unmounted drive) is only hidden until it is back.
static func entries(kind: String = "") -> Array:
	var rows := _read_index()
	var kept: Array = []
	var shown: Array = []
	for item in rows:
		if not (item is Dictionary) or str(item.get("path", "")) == "":
			continue
		var path := path_for(item)
		if FileAccess.file_exists(path):
			kept.append(item)
			shown.append(item)
		elif not DirAccess.dir_exists_absolute(path.get_base_dir()):
			kept.append(item)
	if kept.size() != rows.size():
		_write_index(kept)
	var out := shown.filter(func(e: Dictionary) -> bool: return kind == "" or str(e.get("kind", "")) == kind)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("timestamp", 0.0)) > float(b.get("timestamp", 0.0)))
	return out

static func _read_index() -> Array:
	var p := index_path()
	if not FileAccess.file_exists(p):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if parsed is Dictionary and (parsed as Dictionary).get("entries") is Array:
		return (parsed as Dictionary)["entries"]
	# Corrupt: keep a backup; import_existing() finds the saves again.
	AtomicFile.keep_backup(p)
	return []

static func _write_index(rows: Array) -> bool:
	DirAccess.make_dir_recursive_absolute(library_dir())
	return AtomicFile.write_text(index_path(), JSON.stringify({"version": 1, "entries": rows}))

static func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return int(f.get_length()) if f != null else 0

# --- File names ---

## A photo or video the viewer saved: "planet-render-360_<place>_<stamp>"
## with .png or .mp4 (not a 360° photo, and not a recording's hidden
## temporary file).
static func kind_of_name(name: String) -> String:
	if not name.begins_with(PhotoMode.PREFIX + "_") or name.contains("_360_"):
		return ""
	match name.get_extension().to_lower():
		"png":
			return PHOTO
		"mp4":
			return VIDEO
	return ""

## "planet-render-360_paris-france_20261101-1730.png" -> {place, timestamp}
## (PanoramaLibrary.parse_file_name's rules, without the _360_ part).
static func parse_file_name(name: String) -> Dictionary:
	var base := name.get_file().get_basename().trim_prefix(PhotoMode.PREFIX + "_")
	var cut := base.rfind("_")
	if cut < 0:
		return {}
	var slug := base.substr(0, cut)
	var stamp := base.substr(cut + 1)
	var place := slug.replace("-", " ").capitalize() if slug != "" and slug != "view" else "View"
	if stamp.length() < 13 or stamp[8] != "-":
		return {"place": place}
	var when := {
		"year": stamp.substr(0, 4).to_int(), "month": stamp.substr(4, 2).to_int(),
		"day": stamp.substr(6, 2).to_int(), "hour": stamp.substr(9, 2).to_int(),
		"minute": stamp.substr(11, 2).to_int(), "second": 0}
	return {"place": place, "timestamp": float(Time.get_unix_time_from_datetime_dict(when))}

# --- Public API ---

## Registers a saved file. `info` may carry width, height and (videos)
## duration_s. Re-adding a path replaces its row. Returns the entry, or
## {} when the file is missing or the index can't be written.
static func add(path: String, kind: String, place: String, info: Dictionary = {}) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var entry := {"kind": kind, "path": stored_path(path), "place": place,
		"timestamp": Time.get_unix_time_from_system(), "bytes": _file_size(path)}
	for k in ["width", "height", "duration_s"]:
		if info.has(k):
			entry[k] = info[k]
	var rows := _read_index().filter(func(e: Variant) -> bool:
		return e is Dictionary and str(e.get("path", "")) != entry["path"])
	rows.push_front(entry)
	return entry if _write_index(rows) else {}

## Merges `fields` into the row of `entry` (a thumbnail rebuild learning
## a size or duration).
static func update(entry: Dictionary, fields: Dictionary) -> void:
	if fields.is_empty():
		return
	var rows := _read_index()
	for e in rows:
		if e is Dictionary and str(e.get("path", "")) == str(entry.get("path", "")):
			e.merge(fields, true)
			_write_index(rows)
			return

## Adopts earlier saves from the folders photos and videos go to with no
## dialog (also the one chosen in Settings and the app's own videos
## folder). Returns how many were added; re-running adds nothing twice.
static func import_existing() -> int:
	var rows := _read_index()
	var known := {}
	for e in rows:
		if e is Dictionary:
			known[str(e.get("path", ""))] = true
	var fresh := 0
	var dirs := {PhotoMode.fallback_dir(): true, PhotoMode.fallback_video_dir(): true,
		PhotoMode.chosen_video_dir(): true, PhotoMode.VIDEO_DIR_FALLBACK: true}
	for d: String in dirs.keys():
		if d == "" or not DirAccess.dir_exists_absolute(d):
			continue
		for name in DirAccess.get_files_at(d):
			var kind := kind_of_name(name)
			var path := d.path_join(name)
			if kind == "" or known.has(stored_path(path)):
				continue
			if kind == VIDEO and not VideoRecorder.is_finished_mp4(ProjectSettings.globalize_path(path)):
				continue
			var meta := parse_file_name(name)
			# The name's stamp is the place's local time, not UTC: the
			# file's own time sorts it with saves stamped when they're made.
			var modified := FileAccess.get_modified_time(path)
			rows.append({"kind": kind, "path": stored_path(path), "place": str(meta.get("place", "View")),
				"timestamp": float(modified) if modified > 0 else float(meta.get("timestamp", 0.0)),
				"bytes": _file_size(path)})
			known[stored_path(path)] = true
			fresh += 1
	if fresh > 0 and not _write_index(rows):
		return 0
	return fresh

## Deletes the file, its thumbnail and its row. False when nothing was removed.
static func remove(entry: Dictionary) -> bool:
	var key := str(entry.get("path", ""))
	if key == "":
		return false
	var rows := _read_index()
	var kept := rows.filter(func(e: Variant) -> bool: return e is Dictionary and str(e.get("path", "")) != key)
	var removed := kept.size() != rows.size()
	for p in [path_for(entry), thumb_path_for(entry)]:
		if FileAccess.file_exists(p):
			removed = DirAccess.remove_absolute(p) == OK or removed
	_write_index(kept)
	return removed

# --- Thumbnails ---

static func has_thumb(entry: Dictionary) -> bool:
	return FileAccess.file_exists(thumb_path_for(entry))

## The card thumbnail, or null when it is missing (rebuild_thumb makes it
## off the main thread).
static func thumb_texture(entry: Dictionary) -> Texture2D:
	var p := thumb_path_for(entry)
	if FileAccess.file_exists(p):
		var img := Image.load_from_file(p)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

## Makes the thumbnail from the file. Safe on a worker thread (files and
## Image only). Returns what it learnt for update() (width, height,
## duration_s), with "ok" false when no thumbnail could be made.
static func rebuild_thumb(entry: Dictionary) -> Dictionary:
	var img: Image = null
	var learnt := {}
	if str(entry.get("kind", "")) == VIDEO:
		if not can_play():
			return {"ok": false}
		var frame: Dictionary = ClassDB.class_call_static("VideoDecoder", "thumbnail",
			path_for(entry), VIDEO_THUMB_PX)
		if frame.is_empty():
			return {"ok": false}
		img = Image.create_from_data(int(frame["width"]), int(frame["height"]), false,
			Image.FORMAT_RGBA8, frame["data"])
		learnt["duration_s"] = float(frame["duration_usec"]) / 1e6
	else:
		img = Image.load_from_file(path_for(entry))
		if img != null and not img.is_empty():
			learnt["width"] = img.get_width()
			learnt["height"] = img.get_height()
	var small := PlaceThumb.shrink(img)
	if small == null:
		return {"ok": false}
	var p := thumb_path_for(entry)
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	learnt["ok"] = small.save_jpg(p, PlaceThumb.QUALITY) == OK
	return learnt
