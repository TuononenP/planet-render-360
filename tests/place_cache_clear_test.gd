extends SceneTree

## Per-place cache clearing + no size limit:
## godot --headless --script tests/place_cache_clear_test.gd

var _fail: Array[String] = []

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail.append(msg)

func _write(path: String, bytes: int = 64) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_fail.append("cannot write fixture %s" % path)
		return
	f.store_string("x".repeat(bytes))
	f.close()

func _write_keys(keys: Dictionary) -> Array:
	var out: Array = []
	for layer in keys:
		for k in keys[layer]:
			_write(str(k))
			out.append(str(k))
	return out

func _init() -> void:
	_run()

func _run() -> void:
	var root_dir := "user://place-cache-clear-test-%d" % OS.get_process_id()
	CacheStore.dir_override = root_dir + "/cache"
	CacheStore.history_override = root_dir + "/history.json"
	WorldCache.dir_override = root_dir + "/worlds"
	PlaceThumb.dir_override = root_dir + "/thumbs"
	CacheStore.reset_lru()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.base_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WorldCache.base_dir()))

	var a := {"name": "Paris, France", "lat": 48.8566, "lon": 2.3522,
		"quality_preset": 2, "favourite": true, "camera": {"yaw": 1.0}, "timestamp": 1000.0}
	var b := {"name": "Near Paris, France", "lat": 48.8570, "lon": 2.3530,
		"quality_preset": 2, "favourite": false, "timestamp": 900.0}
	var store := CacheStore.new()
	store.entries = [a, b]
	store.save_store()

	var a_keys: Array = []
	for p in [0, 2, 3]:
		a_keys.append_array(_write_keys(CacheStore.place_cache_keys(a.lat, a.lon, p)))
	var b_keys: Array = _write_keys(CacheStore.place_cache_keys(b.lat, b.lon, 2))
	var shared := ""
	var b_only := ""
	for k in b_keys:
		if k in a_keys and shared == "":
			shared = k
		if not k in a_keys and b_only == "":
			b_only = k
	_check(shared != "", "fixtures should share a tile between nearby places")
	_check(b_only != "", "fixtures should have an unshared file for B")

	var qa := CacheStore.quant(a.lat)
	var qb := CacheStore.quant(b.lat)
	# quant is per-coordinate; world prefix uses lat_q and lon_q
	var a_world := WorldCache.base_dir() + "/world_%d_%d_p2_s0_deadbeef.scn" % [qa, CacheStore.quant(a.lon)]
	var a_world2 := WorldCache.base_dir() + "/world_%d_%d_p0_s1_cafef00d.scn" % [qa, CacheStore.quant(a.lon)]
	var b_world := WorldCache.base_dir() + "/world_%d_%d_p2_s0_beefdead.scn" % [qb, CacheStore.quant(b.lon)]
	var orphan_world := WorldCache.base_dir() + "/world_%d_%d_p2_s0_01234567.scn" % [CacheStore.quant(10.0), CacheStore.quant(20.0)]
	for w in [a_world, a_world2, b_world, orphan_world]:
		_write(w, 128)
		_write(w.get_basename() + ".ground", 32)
	_write(PlaceThumb.path(a.lat, a.lon), 16)
	_write(PlaceThumb.path(b.lat, b.lon), 16)

	# Report includes worlds and an Other bucket for the orphan world.
	var report: Dictionary = CacheStore.place_cache_report(store.entries)
	var rows: Array = report.get("rows", [])
	_check(rows.size() == 2, "report should have 2 rows, got %d" % rows.size())
	var a_row: Dictionary = rows[0] if rows.size() > 0 else {}
	# rows are largest-first; A has 3 presets + 2 worlds so should be first
	_check(int(a_row.get("world_bytes", 0)) > 0, "A row should count built worlds, got %s" % str(a_row))
	_check(str(a_row.get("state", "")) == "full", "A is fully cached at its own preset, got %s" % str(a_row.get("state", "")))
	_check(int(a_row.get("bytes", 0)) > int(a_row.get("data_bytes", 0)), "A total should exceed data-only bytes")
	_check(int(report.get("other_bytes", 0)) >= 160, "orphan world should land in Other, got %s" % str(report.get("other_bytes", 0)))
	_check(CacheStore.entry_bytes(a) == int(a_row.get("bytes", -1)), "entry_bytes should match report row")
	# A recount after an external deletion must not serve stale world sizes.
	var a_world_bytes := WorldCache.bytes_for_place(a.lat, a.lon)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(a_world))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(a_world.get_basename() + ".ground"))
	WorldCache.enforce_budget()
	_check(WorldCache.bytes_for_place(a.lat, a.lon) == a_world_bytes - 160,
		"recount should drop externally deleted worlds, got %d vs %d"
			% [WorldCache.bytes_for_place(a.lat, a.lon), a_world_bytes - 160])

	# No size limit: a write + reconcile never deletes to fit a cap.
	var big := CacheStore.base_dir() + "/unrelated.bin"
	_write(big, 256)
	CacheStore.note_written(big)
	CacheStore.reconcile_index()
	CacheStore.finish()
	await process_frame
	await process_frame
	_check(FileAccess.file_exists(big), "reconcile should never evict files")

	# Storage Clear: frees A completely, keeps entry/favourite/camera/thumb.
	var res: Dictionary = store.clear_place_cache(a)
	_check(bool(res.get("ok", false)), "clear A should succeed: %s" % str(res))
	_check(int(res.get("bytes", 0)) > 0, "clear A should report freed bytes")
	for k in a_keys:
		_check(not FileAccess.file_exists(k), "A data file should be gone: %s" % k)
	_check(not FileAccess.file_exists(a_world) and not FileAccess.file_exists(a_world2), "A worlds should be gone")
	_check(not FileAccess.file_exists(a_world.get_basename() + ".ground"), "A world ground should be gone")
	_check(FileAccess.file_exists(b_only), "B unshared file should survive")
	_check(FileAccess.file_exists(b_world), "B world should survive")
	_check(shared == "" or not FileAccess.file_exists(shared), "shared tile is deleted (documented sharing rule)")
	_check(FileAccess.file_exists(PlaceThumb.path(a.lat, a.lon)), "Storage clear should keep the thumbnail")
	_check(store.entries.size() == 2 and bool(store.entries[0].get("favourite", false))
		and (store.entries[0].get("camera", {}) as Dictionary).has("yaw"),
		"Storage clear should keep entry, favourite and camera")
	_check(CacheStore.entry_bytes(a) == 0, "A should hold 0 bytes after clear")

	# Settings → Storage list: B's row clears through the confirm sheet,
	# and the place stays in History with its thumbnail.
	var screen := SettingsScreen.new()
	root.add_child(screen)
	screen.bind_store(store)
	await process_frame
	await process_frame
	_check(screen._place_rows.size() == 2, "storage should list both places, got %d" % screen._place_rows.size())
	var b_btn: Button = null
	for i in screen._place_rows.size():
		if str(screen._place_rows[i].get("name", "")).begins_with("Near"):
			b_btn = screen._place_clear_btns[i]
	_check(b_btn != null and not b_btn.disabled, "B's Clear button should be enabled")
	if b_btn != null:
		b_btn.pressed.emit()
		await process_frame
		var go: Button = null
		for node in screen.find_children("*", "Button", true, false):
			if (node as Button).text == "Clear cache":
				go = node
		_check(go != null, "clearing a place should ask for confirmation")
		if go != null:
			go.pressed.emit()
			await process_frame
			await process_frame
	_check(not FileAccess.file_exists(b_only), "storage clear should delete B data")
	_check(not FileAccess.file_exists(b_world), "storage clear should delete B world")
	_check(FileAccess.file_exists(PlaceThumb.path(b.lat, b.lon)), "storage clear should keep B thumbnail")
	_check(store.entries.size() == 2, "storage clear should keep B in History")
	screen.queue_free()
	await process_frame
	# History badges come from one report per refresh, not per-card sizing.
	var history := HistoryScreen.new()
	root.add_child(history)
	history.bind_store(store)
	await process_frame
	_check(history._badge_bytes.size() == 2, "history should size both places from one report, got %d" % history._badge_bytes.size())
	_check(int(history._badge_bytes.get("%s_%s" % [b.lat, b.lon], -1)) == CacheStore.entry_bytes(b),
		"history badge size should match entry_bytes for B")
	history.queue_free()
	await process_frame
	# Busy: a world save in flight for B refuses both verbs, drops nothing.
	_write(b_only)
	var fake_save := Thread.new()
	fake_save.start(func() -> void: OS.delay_msec(500))
	WorldCache._save_threads[WorldCache.base_dir() + "/" + WorldCache.place_prefix(b.lat, b.lon) + "p2_s0_fake.scn"] = fake_save
	var busy_res: Dictionary = store.clear_place_cache(b)
	_check(bool(busy_res.get("busy", false)) and FileAccess.file_exists(b_only),
		"clear should refuse while B is being saved")
	var busy_remove: Dictionary = store.remove_place(b)
	_check(bool(busy_remove.get("busy", false)) and store.entries.size() == 2
		and FileAccess.file_exists(PlaceThumb.path(b.lat, b.lon)),
		"remove should keep entry and thumbnail while B is being saved")
	fake_save.wait_to_finish()
	# Rewrite one B file so History Remove has something of its own to free.
	_write(b_only)

	# History Remove: same file set plus thumbnail and the entry itself.
	store.remove_place(b)
	_check(not FileAccess.file_exists(b_only), "remove should delete B data")
	_check(not FileAccess.file_exists(b_world), "remove should delete B world")
	_check(not FileAccess.file_exists(PlaceThumb.path(b.lat, b.lon)), "remove should delete B thumbnail")
	_check(store.entries.size() == 1, "remove should drop the entry")

	# An empty worlds listing is cached too: a file appearing later is
	# only picked up after a recount invalidates the cache.
	WorldCache.dir_override = root_dir + "/worlds-empty"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WorldCache.base_dir()))
	_check(WorldCache.bytes_for_place(1.0, 2.0) == 0, "empty worlds should size 0")
	_write(WorldCache.base_dir() + "/world_%d_%d_p2_s0_abcdef01.scn" % [CacheStore.quant(1.0), CacheStore.quant(2.0)], 48)
	_check(WorldCache.bytes_for_place(1.0, 2.0) == 0, "empty listing should stay cached until a recount")
	WorldCache.enforce_budget()
	_check(WorldCache.bytes_for_place(1.0, 2.0) == 48, "recount should pick up the new world")

	# First open while the cache index is still loading: History and
	# Settings must not join the parse on the main thread. They build
	# without sizes, then refresh themselves when the index lands.
	CacheStore.reset_lru()
	_write(CacheStore.base_dir() + "/dem_v2_1_2_3.png", 64)
	var lru_file := FileAccess.open(CacheStore._lru_path(), FileAccess.WRITE)
	lru_file.store_string(JSON.stringify({"dem_v2_1_2_3.png": {"bytes": 64, "atime": 1.0}}))
	lru_file.close()
	_check(not CacheStore.index_ready(), "index should start unloaded after a reset")
	var fired := [false]
	CacheStore.ensure_index_async(func() -> void: fired[0] = true)
	_check(not fired[0], "the index waiter should not fire synchronously")
	var history2 := HistoryScreen.new()
	root.add_child(history2)
	history2.bind_store(store)
	history2.refresh()
	_check(history2._badge_bytes.is_empty(), "history should build without badges while the index loads")
	var settings2 := SettingsScreen.new()
	root.add_child(settings2)
	settings2.bind_store(store)
	settings2._refresh_storage()
	_check(settings2._place_rows.is_empty(), "settings should build without place rows while the index loads")
	var waited := 0
	while not fired[0] and waited < 200:
		await process_frame
		waited += 1
	_check(fired[0] and CacheStore.index_ready(), "the index waiter should fire once the index lands")
	_check(int((CacheStore._lru.get("dem_v2_1_2_3.png", {}) as Dictionary).get("bytes", 0)) == 64,
		"the loaded index should hold the written row")
	await process_frame
	await process_frame
	_check(history2._badge_bytes.size() == store.entries.size(),
		"history should refresh its badges when the index lands, got %d" % history2._badge_bytes.size())
	_check(settings2._place_rows.size() == store.entries.size(),
		"settings should refresh its place rows when the index lands, got %d" % settings2._place_rows.size())
	history2.queue_free()
	settings2.queue_free()
	await process_frame

	CacheStore.reset_lru()
	CacheStore.dir_override = ""
	CacheStore.history_override = ""
	WorldCache.dir_override = ""
	PlaceThumb.dir_override = ""
	if _fail.is_empty():
		print("PLACE CACHE CLEAR OK: no-limit reconcile, per-place report, storage clear, history remove")
		quit(0)
	else:
		for m in _fail:
			printerr("PLACE CACHE CLEAR FAIL: ", m)
		quit(1)
