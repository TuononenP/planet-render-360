extends SceneTree

## User directory move: godot --headless --script tests/user_dir_test.gd
## UserDirMigration.migrate on throwaway directories under user://: entries
## move across (hidden ones too), folders merge, History merges by place,
## the old settings win over what the new directory gained since the
## switch, and the emptied old directory goes. Never touches the real data
## (run() is not called).

const ROOT := "user://user_dir_test"

var failures: Array[String] = []

func _init() -> void:
	var root := ProjectSettings.globalize_path(ROOT)
	_clean(root)
	var from := root.path_join("old")
	var to := root.path_join("new")
	# The old directory: a person's real data.
	_write(from.path_join("history.json"), JSON.stringify([
		{"name": "Paris", "lat": 48.8566, "lon": 2.3522, "timestamp": 100.0, "favourite": true,
			"camera": {"bearing": 200.0}},
		{"name": "Rome", "lat": 41.8916, "lon": 12.4916, "timestamp": 90.0}]))
	_write(from.path_join("settings.json"), '{"onboarded":true,"preset":2}')
	_write(from.path_join(".hidden"), "dot file")
	_write(from.path_join("cache/osm_v2_1_2_r1200.json"), "old osm")
	_write(from.path_join("cache/lru.json"), "old index")
	_write(from.path_join("thumbs/1_2.jpg"), "old jpg")
	_write(from.path_join("worlds/w.scn"), "world")
	_write(from.path_join("logs/godot.log"), "old log")
	# The new directory: what tests and a short run wrote since the switch.
	_write(to.path_join("history.json"), JSON.stringify([
		{"name": "Paris", "lat": 48.8566, "lon": 2.3522, "timestamp": 200.0},
		{"name": "Oslo", "lat": 59.91, "lon": 10.75, "timestamp": 150.0}]))
	_write(to.path_join("settings.json"), '{"preset":2}')
	_write(to.path_join("logs/godot.log"), "new log")
	_write(to.path_join("cache/sat_v2_1_2_3.jpg"), "new sat")
	OS.delay_msec(1100)  # a strictly newer mtime for the new index
	_write(to.path_join("cache/lru.json"), "new index")
	UserDirMigration.migrate(from, to)
	var history: Variant = JSON.parse_string(_read(to.path_join("history.json")))
	var names: Array = (history as Array).map(func(e: Dictionary) -> String: return str(e["name"])) if history is Array else []
	_check(names == ["Paris", "Oslo", "Rome"], "History merges by place, newest first: %s" % [names])
	if names.size() == 3:
		var paris: Dictionary = (history as Array)[0]
		_check(float(paris["timestamp"]) == 200.0, "the latest visit wins")
		_check(bool(paris.get("favourite", false)), "the old favourite star is kept")
		_check(float((paris.get("camera", {}) as Dictionary).get("bearing", 0.0)) == 200.0, "and the saved camera")
	_check(_read(to.path_join("settings.json")) == '{"onboarded":true,"preset":2}',
		"the old settings win over what the switch-over wrote (no second onboarding)")
	_check(_read(to.path_join(".hidden")) == "dot file", "hidden files arrive")
	_check(_read(to.path_join("cache/osm_v2_1_2_r1200.json")) == "old osm", "folders merge: old cache files arrive")
	_check(_read(to.path_join("cache/sat_v2_1_2_3.jpg")) == "new sat", "and the new ones stay")
	_check(_read(to.path_join("cache/lru.json")) == "new index", "a file on both sides keeps the newer copy")
	_check(_read(to.path_join("thumbs/1_2.jpg")) == "old jpg", "a folder only the old side has arrives whole")
	_check(_read(to.path_join("worlds/w.scn")) == "world", "built worlds arrive")
	_check(not DirAccess.dir_exists_absolute(from), "the emptied old directory is removed")
	_check(UserDirMigration.migrate(from, to) == 0, "a second run has nothing to move")
	_check(UserDirMigration.migrate(root.path_join("missing"), to) == 0, "no old directory: nothing to do")
	_check(UserDirMigration.migrate(to, to + "/") == 0, "the same directory is never moved into itself")
	_check(UserDirMigration.legacy_dir().contains("app_userdata") \
		and UserDirMigration.legacy_dir().ends_with(str(ProjectSettings.get_setting("application/config/name"))),
		"the old directory is Godot's app_userdata one: " + UserDirMigration.legacy_dir())
	_clean(root)
	if failures.is_empty():
		print("USER DIR OK: entries move, folders merge, History merges by place, old settings win, emptied directory removed")
		quit(0)
	else:
		for f in failures:
			printerr("USER DIR FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

func _clean(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path.path_join(name)
		if dir.current_is_dir():
			_clean(full)
		else:
			DirAccess.remove_absolute(full)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
