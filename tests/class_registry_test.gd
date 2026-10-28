extends SceneTree

## Class-registry guard: godot --headless --script tests/class_registry_test.gd
## Snapshot/reference copies of live scripts must never declare a global
## class_name: a duplicate TerrainBuilder/View360 in visual-plan/best/ once
## won Godot's class registration and broke compilation of the live scripts.
## Snapshots live under non-.gd names so the importer never scans them; this
## test fails if any scanned .gd outside scripts/ declares a global class or
## if two scanned files declare the same one.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var declarations: Dictionary = {}
	_collect("res://", declarations, failures)
	var by_class: Dictionary = {}
	for path in declarations:
		var cls: String = declarations[path]
		if not by_class.has(cls):
			by_class[cls] = []
		(by_class[cls] as Array).append(path)
		if not str(path).begins_with("res://scripts/"):
			failures.append("global class %s declared outside scripts/: %s" % [cls, path])
	for cls in by_class:
		var paths: Array = by_class[cls]
		if paths.size() > 1:
			paths.sort()
			failures.append("duplicate global class %s in: %s" % [cls, ", ".join(paths)])
	if not by_class.has("TerrainBuilder"):
		failures.append("TerrainBuilder not declared by any scanned script")
	if not by_class.has("View360"):
		failures.append("View360 not declared by any scanned script")
	if failures.is_empty():
		print("CLASS REGISTRY OK: %d global classes, all in scripts/" % by_class.size())
		quit(0)
	else:
		for f in failures:
			printerr("CLASS REGISTRY FAIL: ", f)
		quit(1)

func _collect(dir_path: String, declarations: Dictionary, failures: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		failures.append("cannot open %s" % dir_path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if entry != ".godot" and not full.ends_with("/.godot"):
				_collect(full, declarations, failures)
		elif entry.ends_with(".gd"):
			var cls := _class_name_of(full)
			if cls != "":
				declarations[full] = cls
		entry = dir.get_next()
	dir.list_dir_end()

func _class_name_of(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	while not file.eof_reached():
		var line: String = (file.get_line() as String).strip_edges()
		if line.begins_with("class_name "):
			var rest: String = line.trim_prefix("class_name ").strip_edges()
			return rest.split(" ", false, 1)[0]
	return ""
