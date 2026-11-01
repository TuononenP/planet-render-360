extends SceneTree

## Headless zoom/search test: godot --headless --script tests/zoom_search_test.gd
## Map wheel + pinch zoom, 360 wheel zoom, search suggestion parsing,
## local predictions, and the SubViewport following its container
## (stretch owns its size; no manual resize, no engine warning).

func _init() -> void:
	_run()

func _wheel(button: int, pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	ev.position = pos
	return ev

func _run() -> void:
	var failures: Array[String] = []

	# --- Map: scroll wheel zooms, centred on the cursor ---
	var map := MapTileView.new()
	root.add_child(map)
	map.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map.size = Vector2(390, 500)
	await process_frame
	var z0 := map.zoom_level
	map._gui_input(_wheel(MOUSE_BUTTON_WHEEL_UP, Vector2(195, 250)))
	if map.zoom_level != z0 + 1:
		failures.append("map wheel-up should zoom in (was %d, now %d)" % [z0, map.zoom_level])
	map._gui_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN, Vector2(195, 250)))
	map._gui_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN, Vector2(195, 250)))
	if map.zoom_level != z0 - 1:
		failures.append("map wheel-down should zoom out (now %d)" % map.zoom_level)

	# --- Map: pinch (two touches moving apart) zooms in ---
	var t0 := InputEventScreenTouch.new()
	t0.index = 0
	t0.pressed = true
	t0.position = Vector2(170, 250)
	map._gui_input(t0)
	var t1 := InputEventScreenTouch.new()
	t1.index = 1
	t1.pressed = true
	t1.position = Vector2(220, 250)
	map._gui_input(t1)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2(300, 250)
	drag.relative = Vector2(80, 0)
	map._gui_input(drag)
	if map.zoom_level <= z0 - 1:
		failures.append("map pinch-out should zoom in (now %d)" % map.zoom_level)
	# --- Map: mouse drag pans instead of jumping the pin ---
	var lon_before_pan := map.centre_lon
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(195, 250)
	map._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 0)
	motion.position = Vector2(315, 250)
	map._gui_input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(315, 250)
	map._gui_input(release)
	if abs(map.centre_lon - lon_before_pan) < 0.001:
		failures.append("map drag should pan (lon %f -> %f)" % [lon_before_pan, map.centre_lon])

	var up0 := InputEventScreenTouch.new()
	up0.index = 0
	up0.pressed = false
	up0.position = Vector2(170, 250)
	map._gui_input(up0)
	var up1 := InputEventScreenTouch.new()
	up1.index = 1
	up1.pressed = false
	up1.position = Vector2(300, 250)
	map._gui_input(up1)
	map.queue_free()

	# --- 360 view: wheel zooms the camera, viewport follows container ---
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(390, 844)
	await process_frame
	await process_frame
	if view._viewport.size != Vector2i(390, 844):
		failures.append("360 viewport should follow container size, got %s" % str(view._viewport.size))
	var cam: Camera3D = view._rig.get_node("Camera3D")
	var fov0 := cam.fov
	view._gui_input(_wheel(MOUSE_BUTTON_WHEEL_UP, Vector2(195, 400)))
	if cam.fov >= fov0:
		failures.append("360 wheel-up should zoom in (fov %f -> %f)" % [fov0, cam.fov])
	view._gui_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN, Vector2(195, 400)))
	view._gui_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN, Vector2(195, 400)))
	if cam.fov <= fov0:
		failures.append("360 wheel-down should zoom back out (fov %f)" % cam.fov)

	# --- Time of day: the sun arc, distinct sun, live Now mode ---
	if view._sun_arc == null:
		failures.append("the 360 view should offer the sun arc scrubber")
	ViewConditions.set_time_minutes(view, 14 * 60 + 30)
	if view._time_label.text != "14:30" or view._live_time:
		failures.append("scrubbing to 14:30 should read 14:30 and leave live time, got %s" % view._time_label.text)
	var rise_set := ViewConditions.sun_times(view)
	if not (rise_set.x < rise_set.y):
		failures.append("sunrise should come before sunset, got %s" % rise_set)
	view.set_time_of_day(12)
	if view._live_time:
		failures.append("picking an hour slot should leave live mode")
	if view._time_label.text != "12:00":
		failures.append("noon slot should read 12:00, got %s" % view._time_label.text)
	var noon_energy := view._sun.light_energy
	var noon_sky := view._atmos.sky_top_color
	view.set_time_of_day(0)
	if view._sun.light_energy >= noon_energy:
		failures.append("midnight should be darker than noon (%f vs %f)" % [view._sun.light_energy, noon_energy])
	if view._atmos.sky_top_color == noon_sky:
		failures.append("sky should change between noon and midnight")
	view.set_time_of_day(6)
	var dawn_rot := view._sun.rotation_degrees
	view.set_time_of_day(18)
	if view._sun.rotation_degrees == dawn_rot:
		failures.append("sun should move between 06:00 and 18:00")
	# --- World replacement: a second place must not leak the first ---
	var flat := LocationData.new()
	flat.grid_size = 8
	flat.heights.resize(64)
	for i in 64:
		flat.heights[i] = 3.0
	flat.place_name = "Testville"
	view.use_live_time()  # holds today's date, as on app start
	flat.latitude = 60.4518  # high latitude: the season's sun differs from today's
	flat.longitude = 22.2666
	view.show_location(flat)
	# T6.2: the spawn slot is the place's golden hour on the season's
	# date (the view starts in live time, holding today's date).
	if not view._atmos.date.is_empty():
		failures.append("spawn hour slot should use the season date, still holds %s" % view._atmos.date)
	if absf(view._atmos.solar_elevation - AtmosphereRig.GOLDEN_ELEV) > 8.0:
		failures.append("spawn sun %.1f° should sit near the golden-hour %.1f°" % [view._atmos.solar_elevation, AtmosphereRig.GOLDEN_ELEV])
	view.show_location(flat)
	await process_frame
	var worlds := 0
	for child in view._world_root.get_children():
		if str(child.name).begins_with("GeneratedWorld"):
			worlds += 1
	if worlds != 1:
		failures.append("showing a second place should leave exactly 1 generated world, got %d" % worlds)
	# --- Season control recolours the open place ---
	if view._season_btn == null or view._season_btn.item_count != 4:
		failures.append("360 view should offer 4 seasons")
	else:
		view._on_season_selected(LocationData.Season.AUTUMN)
		if flat.season != LocationData.Season.AUTUMN:
			failures.append("season picker should set the place season")
	# --- Precipitation dressing follows the weather code ---
	if view._precip == null:
		failures.append("360 view should own a precipitation system")
	else:
		view._apply_precip(61)  # rain
		if not view._precip.emitting:
			failures.append("rain code should start precipitation")
		view._apply_precip(0)  # clear
		if view._precip.emitting:
			failures.append("clear code should stop precipitation")
	view.use_live_time()
	if not view._live_time:
		failures.append("Now should enable live time")
	# T6.2: live time is the place's own clock (UTC + its offset).
	var place_now := Time.get_datetime_dict_from_unix_time(
		int(Time.get_unix_time_from_system() + view._atmos.utc_offset_h * 3600.0))
	var sys_hour := int(place_now.get("hour", -1))
	if int(floor(view._time_hour)) != sys_hour:
		failures.append("live time should match the place's hour %d, got %f" % [sys_hour, view._time_hour])
	view.queue_free()

	# --- Search suggestions: remote parsing + local predictions ---
	var fixture := "[{\"display_name\":\"Paris, Ile-de-France, France\",\"lat\":\"48.8566\",\"lon\":\"2.3522\"},{\"display_name\":\"Parma, Emilia-Romagna, Italy\",\"lat\":\"44.8015\",\"lon\":\"10.3279\"}]"
	var results := SearchFetcher.parse_results(fixture)
	if results.size() != 2:
		failures.append("parse_results should return 2 suggestions, got %d" % results.size())
	elif str(results[0].get("name", "")) != "Paris, Ile-de-France" or abs(float(results[1].get("lat", 0.0)) - 44.8015) > 0.001:
		failures.append("parse_results fields wrong: %s" % str(results))
	if SearchFetcher.parse_results("not json").size() != 0:
		failures.append("parse_results should tolerate bad JSON")
	var local := LocationData.suggestions_for("par")
	if local.is_empty() or str(local[0].get("name", "")) != "Paris, France":
		failures.append("local suggestions for 'par' should start with Paris, got %s" % str(local))
	if LocationData.suggestions_for("xyz-not-a-place").size() != 0:
		failures.append("local suggestions should be empty for nonsense")

	# --- Picker: typing shows the prediction list, tapping one picks it ---
	root.size = Vector2i(390, 844)
	var picker := MapPicker.new()
	root.add_child(picker)
	picker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picker.size = Vector2(390, 844)
	await process_frame
	await process_frame
	picker._search.text = "par"
	picker._on_search_text_changed("par")
	await process_frame
	if picker._suggest_list == null or picker._suggest_list.get_child_count() == 0:
		failures.append("typing 'par' should show prediction rows")
	elif not picker._suggest_panel.visible:
		failures.append("prediction panel should be visible while typing")
	if picker._suggest_list != null and picker._suggest_list.get_child_count() > 0:
		var first := picker._suggest_list.get_child(0) as Button
		first.pressed.emit()
		await process_frame
		if abs(picker._lat - 48.8566) > 0.01 or picker.selected_name != "Paris, France":
			failures.append("tapping a prediction should select Paris (lat=%f name=%s)" % [picker._lat, picker.selected_name])
		if picker._suggest_panel.visible:
			failures.append("prediction panel should hide after selection")
	picker.queue_free()

	# --- Panels over the map: wheel and pinch in a sheet gap zoom the map under it ---
	var panels := MapPicker.new()
	root.add_child(panels)
	panels.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panels.size = Vector2(390, 844)
	await process_frame
	await process_frame
	var pcanvas := panels._canvas
	var pz0 := pcanvas.zoom_level
	panels._sheet.gui_input.emit(_wheel(MOUSE_BUTTON_WHEEL_UP, Vector2(60, 30)))
	if pcanvas.zoom_level != pz0 + 1:
		failures.append("wheel over the sheet should zoom the map (was %d, now %d)" % [pz0, pcanvas.zoom_level])
	var pz1 := pcanvas.zoom_level
	var pinch_a := InputEventScreenTouch.new()
	pinch_a.index = 0
	pinch_a.pressed = true
	pinch_a.position = Vector2(60, 30)
	panels._sheet.gui_input.emit(pinch_a)
	var pinch_b := InputEventScreenTouch.new()
	pinch_b.index = 1
	pinch_b.pressed = true
	pinch_b.position = Vector2(120, 30)
	panels._sheet.gui_input.emit(pinch_b)
	var pinch_out := InputEventScreenDrag.new()
	pinch_out.index = 1
	pinch_out.position = Vector2(220, 30)
	panels._sheet.gui_input.emit(pinch_out)
	if pcanvas.zoom_level != pz1 + 1:
		failures.append("two fingers spreading on the sheet should zoom in (now %d)" % pcanvas.zoom_level)
	var pz2 := pcanvas.zoom_level
	var magnify := InputEventMagnifyGesture.new()
	magnify.factor = 1.4
	magnify.position = Vector2(100, 200)
	panels._side.gui_input.emit(magnify)
	if pcanvas.zoom_level != pz2 + 1:
		failures.append("trackpad pinch over the side panel should zoom in (now %d)" % pcanvas.zoom_level)
	panels.queue_free()

	# --- A scroll area with room to scroll keeps the wheel; a full one passes it on ---
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(200, 100)
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(200, 400)
	scroll.add_child(tall)
	root.add_child(scroll)
	await process_frame
	await process_frame
	if not MapTileView._can_scroll(scroll):
		failures.append("a scroll area with room to scroll should keep the wheel")
	tall.custom_minimum_size = Vector2(200, 50)
	await process_frame
	await process_frame
	if MapTileView._can_scroll(scroll):
		failures.append("a scroll area that fits should pass the wheel on to the map")
	scroll.queue_free()

	# --- Globe: two fingers spreading zoom into the flat map ---
	var globe := GlobeView.new()
	root.add_child(globe)
	globe.set_anchors_preset(Control.PRESET_TOP_LEFT)
	globe.size = Vector2(390, 844)
	await process_frame
	var globe_zoomed: Array = []
	globe.zoom_to_map.connect(func(_la: float, _lo: float) -> void: globe_zoomed.append(true))
	var g_a := InputEventScreenTouch.new()
	g_a.index = 0
	g_a.pressed = true
	g_a.position = Vector2(150, 400)
	globe._gui_input(g_a)
	var g_b := InputEventScreenTouch.new()
	g_b.index = 1
	g_b.pressed = true
	g_b.position = Vector2(240, 400)
	globe._gui_input(g_b)
	var g_out := InputEventScreenDrag.new()
	g_out.index = 1
	g_out.position = Vector2(330, 400)
	globe._gui_input(g_out)
	if globe_zoomed.size() != 1:
		failures.append("two fingers spreading on the globe should zoom to the map once (got %d)" % globe_zoomed.size())
	globe.queue_free()

	if failures.is_empty():
		print("ZOOM_SEARCH OK: map pan/wheel/pinch, panel and globe zoom, 360 wheel zoom, viewport sizing, search predictions, 24h + live time")
		quit(0)
	else:
		for f in failures:
			printerr("ZOOM_SEARCH FAIL: ", f)
		quit(1)
