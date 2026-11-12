class_name PanoramaLibrary
extends RefCounted

## App-owned library of saved 360° photos (see PLAN-gallery-360.md).
## "Save 360°" exports a JPEG wherever the system dialog / Pictures folder
## puts it, which the app cannot enumerate afterwards, so every save also
## registers a copy here under user://panoramas/ with a JSON index.
## The Gallery reads only this library; import_existing() adopts older
## saves found in the app's known fallback photo folder.

const DIR := "user://panoramas"
const INDEX_NAME := "index.json"
const DELETED_NAME := "deleted.json"
const THUMB_DIR := "thumbs"

## Set by _read_index when it fell back to scanning the directory:
## entries() then persists the rebuilt index once (self-repair).
static var _rebuilt := false

## Test hook (PlaceThumb.dir_override precedent).
static var dir_override := ""

static func library_dir() -> String:
	return dir_override if dir_override != "" else DIR

static func index_path() -> String:
	return library_dir().path_join(INDEX_NAME)

static func path_for(entry: Dictionary) -> String:
	return library_dir().path_join(str(entry.get("file", "")))

static func thumb_path_for(entry: Dictionary) -> String:
	return library_dir().path_join(THUMB_DIR).path_join(str(entry.get("file", "")) + ".thumb.jpg")

# --- Index ---

## All entries, newest first, with rows whose file is gone pruned (and
## the index rewritten when pruning changed it). A missing or corrupt
## index degrades to a scan of the library directory.
static func entries() -> Array:
	var raw := _read_index()
	var out: Array = []
	var pruned := false
	for item in raw:
		if not item is Dictionary:
			pruned = true
			continue
		var e: Dictionary = item
		if str(e.get("file", "")) == "" or not FileAccess.file_exists(path_for(e)):
			pruned = true
			continue
		out.append(e)
	if raw.is_empty() and not FileAccess.file_exists(index_path()):
		out = _scan(library_dir(), false)
		_rebuilt = true
	if pruned or _rebuilt:
		_rebuilt = false
		_write_index(out)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("timestamp", 0.0)) > float(b.get("timestamp", 0.0)))
	return out

static func _read_index() -> Array:
	var p := index_path()
	if not FileAccess.file_exists(p):
		return []
	var text := FileAccess.get_file_as_string(p).strip_edges()
	if not (text.begins_with("{") or text.begins_with("[")):
		AtomicFile.keep_backup(p)
		_rebuilt = true
		return _scan(library_dir(), false)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and (parsed as Dictionary).get("entries") is Array:
		return (parsed as Dictionary)["entries"]
	if parsed is Array:
		return parsed
	# Corrupt: keep a backup, then rebuild from the files on disk.
	AtomicFile.keep_backup(p)
	_rebuilt = true
	return _scan(library_dir(), false)

static func _write_index(rows: Array) -> bool:
	DirAccess.make_dir_recursive_absolute(library_dir())
	return AtomicFile.write_text(index_path(), JSON.stringify({"version": 1, "entries": rows}))

# --- Deleted tombstones: a deleted photo must not resurrect via import ---

static func _tombstone_key(file: String, byte_count: int) -> String:
	return "%s:%d" % [file, byte_count]

static func tombstones_path() -> String:
	return library_dir().path_join(DELETED_NAME)

static func _tombstones() -> Dictionary:
	var out := {}
	var p := tombstones_path()
	if not FileAccess.file_exists(p):
		return out
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if parsed is Array:
		for k in parsed:
			out[str(k)] = true
	return out

static func _save_tombstones(set: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(library_dir())
	AtomicFile.write_text(tombstones_path(), JSON.stringify(set.keys()))

static func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return int(f.get_length()) if f != null else 0

## Free library file name for `bytes`: `file`, or `file-2`, `file-3`…
## when a different photo already holds the name; the name itself when
## the identical bytes already hold it (idempotent re-add).
static func _collision_name(file: String, bytes: PackedByteArray) -> String:
	var candidate := file
	var n := 1
	while FileAccess.file_exists(library_dir().path_join(candidate)):
		if FileAccess.get_file_as_bytes(library_dir().path_join(candidate)) == bytes:
			return candidate
		n += 1
		candidate = "%s-%d.%s" % [file.get_basename(), n, file.get_extension()]
	return candidate

## Entries built from the JPEGs in `dir` (`copy_in` copies them into the
## library; otherwise they are expected to already live there).
static func _scan(dir: String, copy_in: bool, skip_files: Dictionary = {},
		banned: Dictionary = {}) -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for name in DirAccess.get_files_at(dir):
		if not _is_panorama_name(name) or skip_files.has(name):
			continue
		var src := dir.path_join(name)
		var bytes := FileAccess.get_file_as_bytes(src)
		if bytes.is_empty():
			continue
		if banned.has(_tombstone_key(name, bytes.size())):
			continue  # deleted from Gallery before: never resurrect it
		var dest := name
		if copy_in:
			dest = _collision_name(name, bytes)
			if FileAccess.file_exists(library_dir().path_join(dest)) \
					and FileAccess.get_file_as_bytes(library_dir().path_join(dest)) == bytes:
				continue  # identical photo already in the library
		var meta := parse_file_name(name)
		var entry := _make_entry(dest, str(meta.get("place", "View")),
			0.0, 0.0, PanoramaCapture.heading_from_jpeg(bytes),
			float(meta.get("timestamp", FileAccess.get_modified_time(src))), bytes)
		if copy_in:
			DirAccess.make_dir_recursive_absolute(library_dir())
			if not FileAccess.file_exists(library_dir().path_join(dest)) \
					and not _write_bytes(library_dir().path_join(dest), bytes):
				continue
			_save_thumb(entry, bytes)
		out.append(entry)
	return out

static func _is_panorama_name(name: String) -> bool:
	return name.begins_with(PhotoMode.PREFIX + "_") and name.contains("_360_") \
		and (name.ends_with(".jpg") or name.ends_with(".jpeg"))

## "planet-render-360_paris-france_360_20261101-1730.jpg" ->
## {place: "Paris France", timestamp: <unix>}. Place is a best effort
## from the slug (the original punctuation is not in the file name).
static func parse_file_name(name: String) -> Dictionary:
	var base := name.get_file().get_basename()
	var parts := base.split("_360_")
	if parts.size() != 2:
		return {}
	var slug := parts[0].trim_prefix(PhotoMode.PREFIX + "_")
	var place := slug.replace("-", " ").capitalize() if slug != "" and slug != "view" else "View"
	var stamp := parts[1]  # YYYYMMDD-HHMM
	if stamp.length() < 13:
		return {"place": place}  # no stamp: callers fall back to the file time
	var when := {
		"year": stamp.substr(0, 4).to_int(), "month": stamp.substr(4, 2).to_int(),
		"day": stamp.substr(6, 2).to_int(), "hour": stamp.substr(9, 2).to_int(),
		"minute": stamp.substr(11, 2).to_int(), "second": 0}
	return {"place": place, "timestamp": float(Time.get_unix_time_from_datetime_dict(when))}

static func _make_entry(file: String, place: String, lat: float, lon: float,
		heading: float, timestamp: float, bytes: PackedByteArray) -> Dictionary:
	var img := Image.new()
	if img.load_jpg_from_buffer(bytes) != OK:
		img = null
	return _make_entry_image(file, place, lat, lon, heading, timestamp, img, bytes.size())

static func _make_entry_image(file: String, place: String, lat: float, lon: float,
		heading: float, timestamp: float, img: Image, byte_count: int) -> Dictionary:
	var size := img.get_size() if img != null else Vector2i.ZERO
	return {"file": file, "place": place, "lat": lat, "lon": lon,
		"heading_deg": fposmod(heading, 360.0), "timestamp": timestamp,
		"width": size.x, "height": size.y, "bytes": byte_count}

static func _save_thumb(entry: Dictionary, bytes: PackedByteArray) -> void:
	var img := Image.new()
	if img.load_jpg_from_buffer(bytes) != OK:
		return
	_save_thumb_image(entry, img)

static func _save_thumb_image(entry: Dictionary, img: Image) -> void:
	var small := PlaceThumb.shrink(img)
	if small == null:
		return
	var p := thumb_path_for(entry)
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	small.save_jpg(p, PlaceThumb.QUALITY)

static func _write_bytes(path: String, bytes: PackedByteArray) -> bool:
	var temp := AtomicFile.temp_path(path)
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	var ok := f.get_error() == OK
	f.close()
	if ok and DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),
			ProjectSettings.globalize_path(path)) == OK:
		return true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	return false

# --- Public API ---

## Registers a finished 360° JPEG in the library. Returns the entry, or
## {} when the write failed. Re-adding the same file name replaces its row.
## `decoded` is the picture `bytes` encode, when the caller still has it:
## passing it skips decoding a large JPEG again on the main thread.
static func add(bytes: PackedByteArray, place: String, lat: float, lon: float,
		heading_deg: float, when: Dictionary, decoded_img: Image = null) -> Dictionary:
	if bytes.is_empty():
		return {}
	DirAccess.make_dir_recursive_absolute(library_dir())
	# Two different captures in the same minute share file_name()'s
	# minute resolution: keep both (-2, -3…) instead of overwriting.
	var file := _collision_name(PanoramaCapture.file_name(place, when), bytes)
	# Single decode: entry size and thumbnail both come from this image
	# (PlaceThumb.shrink duplicates before resizing, so reuse is safe).
	var img := decoded_img
	var decoded := img != null and not img.is_empty()
	if not decoded:
		img = Image.new()
		decoded = img.load_jpg_from_buffer(bytes) == OK
	# `when` is the place's wall clock (it names the file); the timestamp is
	# the real moment of saving so sorting and relative times are right
	# whatever time zone the place is in.
	var entry := _make_entry_image(file, place, lat, lon, heading_deg,
		Time.get_unix_time_from_system(), img if decoded else null, bytes.size())
	var existed := FileAccess.file_exists(path_for(entry))
	if not _write_bytes(path_for(entry), bytes):
		return {}
	if decoded:
		_save_thumb_image(entry, img)
	var rows := entries().filter(func(e: Dictionary) -> bool: return str(e.get("file", "")) != file)
	rows.push_front(entry)
	if not _write_index(rows):
		if not existed:
			# Roll back: an unindexed photo would never be listed.
			DirAccess.remove_absolute(path_for(entry))
			DirAccess.remove_absolute(thumb_path_for(entry))
		return {}
	# A deliberate new save of this name clears any delete tombstone.
	var tombs := _tombstones()
	var changed := false
	for k in tombs.keys():
		if str(k).begins_with(file + ":"):
			tombs.erase(k)
			changed = true
	if changed:
		_save_tombstones(tombs)
	return entry

## Adopts older saves from the fallback photo folder. Returns how many
## were newly imported; re-running imports nothing twice.
static func import_existing() -> int:
	var src_dir := PhotoMode.fallback_dir()
	if src_dir == library_dir() or not DirAccess.dir_exists_absolute(src_dir):
		return 0
	# Skip by file name before reading anything: Gallery refresh calls
	# this every time, and decoding every old JPEG to rediscover it is
	# already imported would stall the screen on large photos.
	var rows := entries()
	var known_names := {}
	for e in rows:
		known_names[str(e.get("file", ""))] = true
	# _scan skips identical photos already in the library itself.
	var fresh := _scan(src_dir, true, known_names, _tombstones())
	if fresh.is_empty():
		return 0
	rows.append_array(fresh)
	if not _write_index(rows):
		return 0
	return fresh.size()

## Deletes the library copy (file, thumbnail, index row). Any exported
## copy outside the library is untouched. False when nothing was removed.
static func remove(entry: Dictionary) -> bool:
	var file := str(entry.get("file", ""))
	if file == "":
		return false
	var rows := entries()
	var kept: Array = rows.filter(func(e: Dictionary) -> bool: return str(e.get("file", "")) != file)
	if kept.size() == rows.size() and not FileAccess.file_exists(path_for(entry)):
		return false
	# Tombstone so import_existing() never resurrects this photo from
	# the fallback/Pictures copy that stays on disk.
	var tombs := _tombstones()
	var size := int(entry.get("bytes", 0))
	if size <= 0:
		size = _file_size(path_for(entry))
	tombs[_tombstone_key(file, size)] = true
	_save_tombstones(tombs)
	for p in [path_for(entry), thumb_path_for(entry)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	_write_index(kept)
	return true

static func texture_for(entry: Dictionary) -> Texture2D:
	var p := path_for(entry)
	if not FileAccess.file_exists(p):
		return null
	var img := Image.load_from_file(p)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)

## The card thumbnail, or null when it is missing: decoding the full
## panorama here would stall the Gallery, so callers show a placeholder
## and rebuild it off the main thread with rebuild_thumb().
static func thumb_texture(entry: Dictionary) -> Texture2D:
	var p := thumb_path_for(entry)
	if FileAccess.file_exists(p):
		var img := Image.load_from_file(p)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

static func has_thumb(entry: Dictionary) -> bool:
	return FileAccess.file_exists(thumb_path_for(entry))

## Re-creates a missing thumbnail from the library JPEG. Safe on a
## worker thread (file and Image work only). False when it can't.
static func rebuild_thumb(entry: Dictionary) -> bool:
	var p := path_for(entry)
	if not FileAccess.file_exists(p):
		return false
	var img := Image.load_from_file(p)
	if img == null or img.is_empty():
		return false
	_save_thumb_image(entry, img)
	return has_thumb(entry)
