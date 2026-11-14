extends SceneTree

## Landmark tooltip toggles: godot --headless --script tests/landmark_toggle_test.gd
## Clicking a landmark shows its tooltip (the 360 callout / the map name
## chip), another click hides it, and the callout still shows on its own
## when a landmark sits in the view centre. Offline, like the other
## landmark tests.

const CACHE := "user://landmark_toggle_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	CacheStore.dir_override = CACHE
	DirAccess.make_dir_recursive_absolute(CACHE)
	_callout_toggle()
	await _map_chip_toggle()
	await _view_click_toggle()
	for name in DirAccess.get_files_at(CACHE):
		DirAccess.remove_absolute(CACHE.path_join(name))
	DirAccess.remove_absolute(CACHE)
	CacheStore.dir_override = ""
	if failures.is_empty():
		print("LANDMARK TOGGLE OK: callout toggle, map chip toggle, scene click toggle, auto callout kept")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK TOGGLE FAIL: ", f)
		quit(1)

## The callout itself: shown by a toggle click, hidden by the next, shown
## by a third, with no view to auto-show it meanwhile.
func _callout_toggle() -> void:
	var holder := Control.new()
	root.add_child(holder)
	var callouts := ViewCallouts.new(null)
	holder.add_child(callouts)
	var site := LandmarkVisit.site("Eiffel Tower", 48.8584, 2.2945, "Tower", "curated")
	site["pos"] = Vector3(0, 40, -300)
	callouts._sites.append(site)
	var id := str(site["id"])
	_check(not callouts._cards.has(id), "no callout before any click")
	_check(callouts.toggle_site(site) and callouts._cards.has(id), "a click shows the callout")
	_check(not callouts.toggle_site(site) and not callouts._cards.has(id), "another click hides it")
	_check(callouts.toggle_site(site) and callouts._cards.has(id), "a third click shows it again")
	callouts.clear()
	_check(callouts._cards.is_empty(), "clear removes the callout")
	holder.queue_free()

## The map name chip: hovering still shows it, a marker click pins it,
## and clicking the same marker again hides it. Selecting still happens.
func _map_chip_toggle() -> void:
	var map := MapTileView.new()
	map.size = Vector2(800, 600)
	root.add_child(map)
	map.zoom_level = 14
	map.centre_lat = 48.8584
	map.centre_lon = 2.2945
	await process_frame
	var at := map._focus() + Vector2(6, -4)
	var site := map.landmarks.hit_at(at)
	_check(not site.is_empty(), "the marker is there to click")
	if site.is_empty():
		map.queue_free()
		await process_frame
		return
	var id := str(site["id"])
	var picked := [0]
	map.landmark_picked.connect(func(_s: Dictionary) -> void: picked[0] += 1)
	_check(map.landmarks._pinned_id == "", "no pinned chip before a click")
	map._tap(at)
	_check(map.landmarks._pinned_id == id, "a click shows the name chip")
	map._tap(at)
	_check(map.landmarks._pinned_id == "", "another click hides the name chip")
	map._tap(at)
	_check(map.landmarks._pinned_id == id, "a third click shows it again")
	_check(int(picked[0]) == 3, "marker clicks still select the landmark: %d" % int(picked[0]))
	_check(map.landmarks.hover_at(at) and map.landmarks._hover_id == id, "hover still shows the chip on its own")
	map.queue_free()
	await process_frame

## On a real view: the callout still appears on its own in the view
## centre, a click on the landmark hides it (and it stays hidden while
## still in view), and another click brings it back.
func _view_click_toggle() -> void:
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280, 800)
	view._wiki.offline_mode = true
	view._weather.queue_free()
	view._weather = null
	await process_frame
	var flat := LocationData.new()
	flat.grid_size = 8
	flat.heights.resize(64)
	for i in 64:
		flat.heights[i] = 3.0
	flat.place_name = "Testville"
	flat.latitude = 60.4518
	flat.longitude = 22.2666
	view.show_location(flat)
	await process_frame
	await process_frame
	view._rig.set_look(0.0, 0.0)
	var site := LandmarkVisit.site("Old tower", flat.latitude + 0.004, flat.longitude, "Tower")
	view._callouts.add_sites([site])
	await process_frame
	var stored: Dictionary = view._callouts._find(str(site["name"]),
		WorldScale.xz_from_latlon(float(site["lat"]), float(site["lon"]), flat.latitude, flat.longitude))
	_check(not stored.is_empty(), "the clicked landmark is a callout site")
	if stored.is_empty():
		view.queue_free()
		await process_frame
		return
	var id := str(stored["id"])
	await create_timer(0.7).timeout
	_check(view._callouts._cards.has(id), "the callout still shows automatically in the view centre")
	var cam := view._rig.camera
	var at: Vector2 = cam.unproject_position(stored["pos"])
	var eye_before := view._rig.position
	await _click(view, at)
	_check(not view._callouts._cards.has(id), "clicking the landmark hides its callout")
	_check(view._rig.position.distance_to(eye_before) < 0.5,
		"clicking the landmark does not walk: %s -> %s" % [eye_before, view._rig.position])
	await create_timer(0.6).timeout
	_check(not view._callouts._cards.has(id), "it stays hidden while still in view")
	await _click(view, at)
	_check(view._callouts._cards.has(id), "another click shows it again")
	_check(view._rig.position.distance_to(eye_before) < 0.5, "the second click does not walk either")
	# Clicking the body, not the floating anchor: a curated landmark's
	# anchor sits 60 m up, so a click on its base, 180 m away, lands far
	# below the anchor on screen — it must still pick the landmark.
	var spos: Vector3 = stored["pos"]
	var base_y := spos.y - 20.0  # add_sites lifted this site 20 m
	stored["pos"] = Vector3(spos.x, base_y + 60.0, spos.z)
	view._rig.position = Vector3(spos.x, base_y + 30.0, spos.z + 180.0)
	var aim := View360.aim(view._rig.position, stored["pos"])
	view._rig.set_look(aim.x, aim.y)
	await process_frame
	var base_pt: Vector2 = cam.unproject_position(Vector3(spos.x, base_y + 3.0, spos.z))
	_check(str(view._callouts.site_at(base_pt).get("id", "")) == id,
		"clicking the landmark's base picks it")
	await _click(view, base_pt)
	_check(not view._callouts._cards.has(id), "clicking the landmark's base hides its callout")
	view.queue_free()
	await process_frame

## A real left-button click on the view at `at` (press + release, then
## the tap delay a double click gets).
func _click(view: View360, at: Vector2) -> void:
	for down in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = down
		mb.position = at
		view._gui_input(mb)
	await create_timer(0.5).timeout
