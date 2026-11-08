extends SceneTree

## Headless: godot --headless --script tests/atomic_file_test.gd
## Atomic writes leave no temp file, and an unreadable history.json is kept
## as .bak instead of being silently replaced. Version 0 (bare array) files
## still load.

var _failures: Array[String] = []

func _init() -> void:
	var dir := "user://atomic-file-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	_test_write(dir)
	_test_history(dir)
	_remove_dir(dir)
	if _failures.is_empty():
		print("ATOMIC FILE OK: write, replace, corrupt history backup, legacy array")
		quit(0)
	else:
		for f in _failures:
			printerr("ATOMIC FILE FAIL: ", f)
		quit(1)

func _test_write(dir: String) -> void:
	var path := dir.path_join("data.json")
	if not AtomicFile.write_text(path, "first"):
		_failures.append("write_text failed on a new file")
	if not AtomicFile.write_text(path, "second"):
		_failures.append("write_text failed replacing a file")
	if FileAccess.get_file_as_string(path) != "second":
		_failures.append("write_text did not replace the contents")
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(AtomicFile.TEMP_SUFFIX):
			_failures.append("write_text left its temp file behind: %s" % f)
	if AtomicFile.temp_path(path) == AtomicFile.temp_path(path):
		_failures.append("each write needs a temp file of its own")
	if AtomicFile.write_text(dir.path_join("missing/dir/data.json"), "x"):
		_failures.append("write_text reported success into a missing directory")
	# A kill mid-write leaves a temp file: old ones are swept, fresh ones kept.
	var stale := AtomicFile.temp_path(dir.path_join("stale.json"))
	var fresh := AtomicFile.temp_path(dir.path_join("fresh.json"))
	for t in [stale, fresh]:
		var tf := FileAccess.open(t, FileAccess.WRITE)
		tf.store_string("x")
		tf.close()
	if AtomicFile.sweep_stale(dir, 0.0) != 2 or FileAccess.file_exists(stale):
		_failures.append("sweep_stale should remove orphaned temp files")
	var kept := dir.path_join("keep.json")
	AtomicFile.write_text(kept, "{}")
	var in_flight := AtomicFile.temp_path(dir.path_join("busy.json"))
	var bf := FileAccess.open(in_flight, FileAccess.WRITE)
	bf.store_string("x")
	bf.close()
	if AtomicFile.sweep_stale(dir) != 0 or not FileAccess.file_exists(in_flight) or not FileAccess.file_exists(kept):
		_failures.append("sweep_stale must leave a fresh temp file and real files alone")
	DirAccess.remove_absolute(in_flight)
	if AtomicFile.keep_backup(dir.path_join("absent.json")):
		_failures.append("keep_backup copied a file that does not exist")

func _test_history(dir: String) -> void:
	var path := dir.path_join("history.json")
	CacheStore.history_override = path

	# Unreadable: kept as .bak, and a later save does not touch the copy.
	var corrupt := '{"version": 1, "entries": [{"name": "Paris"'
	_write(path, corrupt)
	var store := CacheStore.new()
	store.load_store()
	if not store.entries.is_empty():
		_failures.append("a corrupt history should load as empty")
	if FileAccess.get_file_as_string(path + ".bak") != corrupt:
		_failures.append("corrupt history.json was not kept as .bak")
	store.entries.append({"name": "Oslo", "lat": 59.9, "lon": 10.7})
	store.save_store()
	if FileAccess.get_file_as_string(path + ".bak") != corrupt:
		_failures.append("saving changed the .bak copy")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not saved is Dictionary or int(saved.get("version", 0)) != CacheStore.HISTORY_VERSION:
		_failures.append("history.json should be saved with its version")
	elif (saved.get("entries", []) as Array).size() != 1:
		_failures.append("saved history lost its entry")

	# Version 0 was a bare array.
	_write(path, JSON.stringify([{"name": "Rome", "lat": 41.9, "lon": 12.5}]))
	var legacy := CacheStore.new()
	legacy.load_store()
	if legacy.entries.size() != 1 or str(legacy.entries[0].get("name")) != "Rome":
		_failures.append("a bare-array history.json should still load")

	# An empty file holds nothing to keep.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	_write(path, "")
	var empty := CacheStore.new()
	empty.load_store()
	if FileAccess.file_exists(path + ".bak"):
		_failures.append("an empty history.json should not be backed up")
	CacheStore.history_override = ""

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _remove_dir(dir: String) -> void:
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
