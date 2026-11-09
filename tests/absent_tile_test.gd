extends SceneTree

## A tile counts as missing from the source only after it answered 404
## twice (CacheStore.note_absent): godot --headless --script tests/absent_tile_test.gd

func _init() -> void:
	var failures: Array[String] = []
	var path := "user://cache/sat_v2_absent_test.jpg"
	if CacheStore.is_absent(path):
		failures.append("an unseen tile is not absent")
	CacheStore.note_absent(path)
	if CacheStore.is_absent(path):
		failures.append("one 404 may be a hiccup: the save must still retry the tile")
	CacheStore.note_absent(path)
	if not CacheStore.is_absent(path):
		failures.append("a second 404 means the source does not have the tile")
	if failures.is_empty():
		print("ABSENT TILE OK: absent after two 404s, not one")
		quit(0)
	else:
		for f in failures:
			printerr("ABSENT TILE FAIL: ", f)
		quit(1)
