extends SceneTree

func _init() -> void:
	CacheStore.dir_override = "user://cache-capture-safety-%d" % OS.get_process_id()
	CacheStore.eviction_suppressed = true
	CacheStore.max_cache_bytes = 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.base_dir()))
	var path := CacheStore.base_dir().path_join("fixture.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("test data larger than the configured limit")
	file.close()
	CacheStore.note_written(path)
	CacheStore.enforce_size_cap()
	if CacheStore._scan_task >= 0 or not FileAccess.file_exists(path):
		printerr("CACHE CAPTURE SAFETY FAIL: suppressed eviction should not start a trim")
		quit(1)
		return
	CacheStore.finish()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CACHE CAPTURE SAFETY OK: cache writes do not schedule eviction")
	quit(0)
