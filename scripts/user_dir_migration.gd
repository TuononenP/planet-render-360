class_name UserDirMigration
extends RefCounted

## The app's data moved when the project took its own user directory
## (application/config/use_custom_user_dir: "…/Application Support/Planet
## Render 360" instead of Godot's "…/Godot/app_userdata/Planet Render 360").
## On the first launch after, the old directory's contents (History,
## settings, the data and tile caches, built worlds, thumbnails, photos)
## move across, so nothing looks lost and no stale copy is left taking
## space. Moves are renames inside one volume: instant even for a gigabyte
## of worlds.
##
## The new directory may already hold a little: what Godot opens at start-up
## (logs), and whatever tests or a run before this move wrote there. So:
## folders merge entry by entry (a file present on both sides, a cache
## index or a thumbnail, keeps the newer copy); History merges by place; any other top-level file (the
## settings) is the old one, the person's long-standing choice, over what
## the new directory gained in the short while since the switch. Desktop
## only: on phones the user directory is the app's own sandbox, never moved.

## Written into the new directory once the move was tried, so it runs once.
const MARKER := ".moved_from_app_userdata"

## Godot's default user directory for this project.
static func legacy_dir() -> String:
	var godot := "godot" if OS.get_name() in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"] else "Godot"
	return OS.get_data_dir().path_join(godot).path_join("app_userdata") \
		.path_join(str(ProjectSettings.get_setting("application/config/name", "")))

## Moves the old directory's contents once; returns how many entries moved.
static func run() -> int:
	if OS.has_feature("mobile") or OS.has_feature("web") \
			or not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)):
		return 0
	var to := ProjectSettings.globalize_path("user://")
	if FileAccess.file_exists(to.path_join(MARKER)):
		return 0
	var moved := migrate(legacy_dir(), to)
	var f := FileAccess.open(to.path_join(MARKER), FileAccess.WRITE)
	if f != null:
		f.store_string("%d entries moved from %s\n" % [moved, legacy_dir()])
	if moved > 0:
		print("UserDirMigration: moved %d entries from %s" % [moved, legacy_dir()])
	return moved

## Moves directory `from`'s entries (hidden ones too) into `to` by the
## rules above; `top` is false inside a folder being merged. `from` is
## removed when it ends up empty. Returns the number of entries moved.
static func migrate(from: String, to: String, top: bool = true) -> int:
	var src := from.trim_suffix("/")
	var dst := to.trim_suffix("/")
	if src == "" or src.simplify_path() == dst.simplify_path() or not DirAccess.dir_exists_absolute(src):
		return 0
	var dir := DirAccess.open(src)
	if dir == null:
		return 0
	DirAccess.make_dir_recursive_absolute(dst)
	dir.include_hidden = true
	var names: Array[String] = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			names.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	var moved := 0
	for n in names:
		var from_path := src.path_join(n)
		var target := dst.path_join(n)
		var target_dir := DirAccess.dir_exists_absolute(target)
		var target_file := FileAccess.file_exists(target)
		if DirAccess.dir_exists_absolute(from_path):
			if target_dir:
				moved += migrate(from_path, target, false)
			elif not target_file and DirAccess.rename_absolute(from_path, target) == OK:
				moved += 1
		elif not target_dir and not target_file:
			if DirAccess.rename_absolute(from_path, target) == OK:
				moved += 1
		elif target_file and top and n == HISTORY:
			moved += _merge_history(from_path, target)
		elif target_file and (top or FileAccess.get_modified_time(from_path) > FileAccess.get_modified_time(target)):
			if DirAccess.remove_absolute(target) == OK and DirAccess.rename_absolute(from_path, target) == OK:
				moved += 1
		elif target_file:
			DirAccess.remove_absolute(from_path)  # the newer copy is already there
	if _is_empty(src):
		DirAccess.remove_absolute(src)
	return moved

const HISTORY := "history.json"

## History from both sides, one entry per place: the most recent visit's,
## keeping a favourite star and a saved camera from either. Newest first,
## at most CacheStore.MAX_ENTRIES. Returns 1 when the old file was merged.
static func _merge_history(from_path: String, target: String) -> int:
	# An unreadable side would merge as empty and then be replaced or
	# deleted: keep a copy of it first, beside the history that lives on.
	if not _parses(from_path):
		DirAccess.copy_absolute(from_path, target + ".from-old.bak")
	if not _parses(target):
		AtomicFile.keep_backup(target)
	var old_entries := _entries(from_path)
	var new_entries := _entries(target)
	var by_place := {}
	for e: Dictionary in old_entries + new_entries:
		var key := "%d_%d" % [roundi(float(e.get("lat", 0.0)) * 10000.0), roundi(float(e.get("lon", 0.0)) * 10000.0)]
		var had: Dictionary = by_place.get(key, {})
		var keep := e.duplicate()
		if not had.is_empty():
			if float(had.get("timestamp", 0.0)) > float(e.get("timestamp", 0.0)):
				keep = had.duplicate()
			keep["favourite"] = bool(had.get("favourite", false)) or bool(e.get("favourite", false))
			if not keep.has("camera"):
				var cam: Variant = e.get("camera", had.get("camera", {}))
				if cam is Dictionary and not (cam as Dictionary).is_empty():
					keep["camera"] = cam
		by_place[key] = keep
	var merged: Array = by_place.values()
	merged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("timestamp", 0.0)) > float(b.get("timestamp", 0.0)))
	merged = merged.slice(0, CacheStore.MAX_ENTRIES)
	# The current layout, written whole: the old file goes only once it is safe.
	if not AtomicFile.write_text(target, JSON.stringify({"version": CacheStore.HISTORY_VERSION, "entries": merged})):
		return 0
	DirAccess.remove_absolute(from_path)
	return 1

## Whether a history file holds a readable list of entries (an empty file
## holds nothing worth keeping).
static func _parses(path: String) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return true
	var parsed: Variant = JSON.parse_string(text)
	var items: Variant = parsed.get("entries") if parsed is Dictionary else parsed
	return items is Array

static func _entries(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var out: Array = []
	# CacheStore's layout is {"version", "entries"}; older files a bare array.
	var items: Variant = parsed.get("entries") if parsed is Dictionary else parsed
	if items is Array:
		for e in items:
			if e is Dictionary:
				out.append(e)
	return out

static func _is_empty(path: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			dir.list_dir_end()
			return false
		name = dir.get_next()
	dir.list_dir_end()
	return true
