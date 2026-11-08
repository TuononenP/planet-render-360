class_name AtomicFile
extends RefCounted

## Whole-file writes that cannot leave a half-written target behind: the
## bytes go to a sibling temp file first and replace the target only once
## they are all on disk. A crash or a full disk mid-write then leaves the
## previous file intact instead of a truncated one.

const TEMP_SUFFIX := ".tmp"
static var _writes := 0

## A temp file of its own per write, so two writers to one target (a live
## fetch and a save for offline) never interleave in a shared file.
static func temp_path(path: String) -> String:
	_writes += 1
	return "%s.%d-%d%s" % [path, OS.get_process_id(), _writes, TEMP_SUFFIX]

static func write_text(path: String, text: String) -> bool:
	var temp := temp_path(path)
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		return false
	var wrote := f.store_string(text)
	f.flush()
	wrote = wrote and f.get_error() == OK
	f.close()
	var from := ProjectSettings.globalize_path(temp)
	if wrote and DirAccess.rename_absolute(from, ProjectSettings.globalize_path(path)) == OK:
		return true
	DirAccess.remove_absolute(from)
	return false

## Deletes temp files a kill left behind (an app suspended mid-write on a
## phone): each name carries its writer's process id, so a later launch
## never reuses one. Only files untouched for `min_age_s` go, so a write
## another process has in flight is left alone.
static func sweep_stale(dir: String, min_age_s: float = 60.0) -> int:
	var pattern := RegEx.create_from_string("\\.\\d+-\\d+" + TEMP_SUFFIX.replace(".", "\\.") + "$")
	var removed := 0
	var now := Time.get_unix_time_from_system()
	for f in DirAccess.get_files_at(dir):
		var path := dir.path_join(f)
		if pattern.search(f) != null and now - float(FileAccess.get_modified_time(path)) >= min_age_s:
			if DirAccess.remove_absolute(path) == OK:
				removed += 1
	return removed

## Keeps an unreadable file as `<path>.bak` before anything overwrites it,
## so a parse failure never costs the user's data for good. Empty files
## hold nothing worth keeping. Returns whether a copy was made.
static func keep_backup(path: String) -> bool:
	if not FileAccess.file_exists(path) or FileAccess.get_file_as_string(path).is_empty():
		return false
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(path + ".bak")) == OK
