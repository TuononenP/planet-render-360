extends SceneTree

func _init() -> void:
	CacheStore.dir_override = "user://cache-capture-safety-%d" % OS.get_process_id()
	CacheStore.eviction_suppressed = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.base_dir()))
	var path := CacheStore.base_dir().path_join("fixture.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("test data with no size limit to fit under")
	file.close()
	CacheStore.note_written(path)
	CacheStore.reconcile_index()
	CacheStore.finish()
	if not FileAccess.file_exists(path):
		printerr("CACHE CAPTURE SAFETY FAIL: reconcile should never delete cache files")
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CACHE CAPTURE SAFETY OK: cache writes are counted, never evicted")
	quit(0)
