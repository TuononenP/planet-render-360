extends SceneTree

## Nearby landmarks over the 360 view: godot --headless --script tests/landmark_list_test.gd
## Ranking and direction, the list's rows, the panel's list -> card -> Back
## flow, and the HUD button / L key on a real View360. Offline: the view's
## weather fetcher is removed and the wiki fetcher answers from an empty
## temp cache only, so nothing here touches the network.

const CACHE := "user://landmark_list_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	CacheStore.dir_override = CACHE
	DirAccess.make_dir_recursive_absolute(CACHE)
	_rank()
	await _rows()
	await _large_text()
	await _callout_ids()
	await _panel_flow()
	await _view_wiring()
	for name in DirAccess.get_files_at(CACHE):
		DirAccess.remove_absolute(CACHE.path_join(name))
	DirAccess.remove_absolute(CACHE)
	CacheStore.dir_override = ""
	if failures.is_empty():
		print("LANDMARK LIST OK: ranking, rows, ids, list -> card -> back, late rows, focus, button and L key")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK LIST FAIL: ", f)
		quit(1)

func _site(site_name: String, pos: Vector3, kind: String = "Building") -> Dictionary:
	var s := LandmarkVisit.site(site_name, 0.0, 0.0, kind, "osm")
	s["id"] = "test:" + site_name
	s["pos"] = pos
	return s

## Three sites round a camera at (0, 30, 0): 200 m east, 900 m south, 3 km north.
func _around() -> Array:
	return [_site("Far tower", Vector3(0, 30, -3000)),
		_site("Near chapel", Vector3(200, 30, 0), "Chapel"),
		{"id": "test:no pos", "name": "No position", "kind": "Landmark"},
		_site("Mid bridge", Vector3(0, 30, 900), "Bridge")]

func _rank() -> void:
	var rows := LandmarkList.rank(_around(), Vector3(0, 30, 0))
	var names := rows.map(func(r: Dictionary) -> String: return str(r["site"]["name"]))
	_check(names == ["Near chapel", "Mid bridge", "Far tower"],
		"nearest first, a site without a position left out: %s" % [names])
	if rows.size() == 3:
		_check(absf(float(rows[0]["distance_m"]) - 200.0) < 0.01, "distance to the chapel: %s" % rows[0]["distance_m"])
		_check(LandmarkList.direction(float(rows[0]["bearing_deg"])) == "E", "the chapel lies east")
		_check(LandmarkList.direction(float(rows[1]["bearing_deg"])) == "S", "the bridge lies south")
		_check(LandmarkList.direction(float(rows[2]["bearing_deg"])) == "N", "the tower lies north")
		_check(LandmarkList.distance_text(rows[0]) == "200 m E", "row distance text: " + LandmarkList.distance_text(rows[0]))
	_check(LandmarkList.rank(_around(), Vector3.ZERO, 2).size() == 2, "the limit caps the rows")
	_check(LandmarkList.rank([], Vector3.ZERO).is_empty(), "no sites, no rows")
	_check(LandmarkList.direction(350.0) == "N" and LandmarkList.direction(-10.0) == "N", "north wraps round 360")
	_check(LandmarkList.direction(135.0) == "SE" and LandmarkList.direction(225.0) == "SW", "diagonals")
	_check(LandmarkList.distance_text({"distance_m": 6200.0, "bearing_deg": 45.0}) == "6.2 km NE",
		"a kilometre and more reads in km")

func _labels(node: Node, out: Array = []) -> Array:
	if node is Label:
		out.append((node as Label).text)
	for c in node.get_children():
		_labels(c, out)
	return out

func _open_button(list: LandmarkList, i: int) -> Button:
	return (list.get_child(i) as HBoxContainer).get_child(0) as Button

func _go_button(list: LandmarkList, i: int) -> Button:
	return (list.get_child(i) as HBoxContainer).get_child(1) as Button

func _rows() -> void:
	var list := LandmarkList.new()
	root.add_child(list)
	list.size = Vector2(360, 0)
	_check(list.row_count() == 0 and _labels(list) == [LandmarkList.EMPTY], "empty: one plain line, no rows: %s" % [_labels(list)])
	_check(not LandmarkList.EMPTY.contains("!") and not LandmarkList.EMPTY.to_lower().contains("error"), "calm copy")
	list.set_rows(LandmarkList.rank(_around(), Vector3(0, 30, 0)))
	await process_frame
	_check(list.row_count() == 3, "three rows: %d" % list.row_count())
	var texts := _labels(list)
	for want in ["Near chapel", "Place of worship", "200 m E", "Mid bridge", "900 m S", "3.0 km N"]:
		_check(texts.has(want), "row text '%s' in %s" % [want, texts])
	_check(_open_button(list, 0).size.y >= LandmarkList.ROW_H, "a row is a 56 pt target: %s" % _open_button(list, 0).size)
	_check(_go_button(list, 0).size.y >= 44.0 and _go_button(list, 0).size.x >= 44.0, "Go there is a 44 pt target")
	_check(_open_button(list, 0).accessibility_name.contains("Near chapel")
		and _open_button(list, 0).accessibility_name.contains("200 m E"), "row is named for screen readers")
	var picked := []
	var went := []
	list.site_picked.connect(func(s: Dictionary, d: float) -> void: picked.append([s, d]))
	list.go_requested.connect(func(s: Dictionary) -> void: went.append(s))
	_open_button(list, 1).pressed.emit()
	_check(picked.size() == 1 and picked[0][0]["name"] == "Mid bridge" and absf(float(picked[0][1]) - 900.0) < 0.01,
		"a row opens its landmark with its distance: %s" % [picked])
	_check(went.is_empty(), "opening does not go")
	_go_button(list, 2).pressed.emit()
	_check(went.size() == 1 and went[0]["name"] == "Far tower", "the row's Go there visits it")
	list.set_rows([])
	_check(list.row_count() == 0, "rows are replaced, not added to")
	# Not found yet is not none: the line says it is still looking.
	list.set_rows([], true)
	_check(_labels(list) == [LandmarkList.PENDING], "pending: the list says it is looking: %s" % [_labels(list)])
	list.set_rows([], false)
	_check(_labels(list) == [LandmarkList.EMPTY], "answered with nothing: the final line: %s" % [_labels(list)])
	for t in [LandmarkList.PENDING, LandmarkList.EMPTY]:
		_check(not t.contains("!") and not t.to_lower().contains("error"), "calm copy: " + t)

	# A refresh that changes nothing leaves the rows (and their focus) alone.
	var rows := LandmarkList.rank(_around(), Vector3(0, 30, 0))
	list.set_rows(rows)
	var first := _open_button(list, 0)
	first.grab_focus()
	list.set_rows(LandmarkList.rank(_around(), Vector3(0, 30, 0)))
	_check(_open_button(list, 0) == first and first.is_inside_tree() and first.has_focus(),
		"the same rows are not rebuilt, so focus stays")
	list.set_rows(rows.slice(0, 2))
	_check(not first.is_inside_tree() and list.row_count() == 2, "different rows are rebuilt")
	list.set_rows(LandmarkList.rank(_around(), Vector3(0, 30, 400)))
	var moved := _open_button(list, 0)
	list.set_rows(LandmarkList.rank(_around(), Vector3(0, 30, 0)))
	_check(not moved.is_inside_tree(), "the same sites at new distances are rebuilt")
	# Focus goes to a row by position or by the landmark it opened.
	list.focus_row(1)
	_check(root.gui_get_focus_owner() == _open_button(list, 1), "focus_row(1) focuses the second row")
	list.focus_site("test:Far tower")
	_check(root.gui_get_focus_owner() == _open_button(list, 2), "focus_site finds the row of a landmark")
	list.focus_site("test:gone")
	_check(root.gui_get_focus_owner() == _open_button(list, 0), "an unknown landmark falls back to the first row")
	list.queue_free()
	await process_frame

## At the largest text size a row grows with its text and nothing spills
## out of it or under the Go there button.
func _large_text() -> void:
	var was := UiTheme.text_scale
	UiTheme.text_scale = 2.0
	var list := LandmarkList.new()
	root.add_child(list)
	list.size = Vector2(300, 0)
	list.set_rows(LandmarkList.rank([
		_site("A landmark with a name too long for one line", Vector3(300, 30, 0), "Chapel")], Vector3(0, 30, 0)))
	for i in 4:
		await process_frame
	var open := _open_button(list, 0)
	var edge := open.get_global_rect()
	_check(open.size.y > LandmarkList.ROW_H, "a row grows past 56 pt at 200%% text: %s" % open.size.y)
	_check(open.size.y >= (open.get_child(0) as Control).get_combined_minimum_size().y, "the row holds its text")
	for l in _label_nodes(open):
		var r := (l as Label).get_global_rect()
		_check(r.end.y <= edge.end.y + 0.5 and r.end.x <= edge.end.x + 0.5 and r.position.x >= edge.position.x - 0.5,
			"'%s' stays inside its row: %s in %s" % [(l as Label).text, r, edge])
		if (l as Label).text == "300 m E":
			_check(l.size.x >= l.get_minimum_size().x, "the distance is never squeezed: %s" % l.size)
	var meta_texts := _labels(open)
	_check(meta_texts.has("300 m E"), "the distance is on the row: %s" % [meta_texts])
	list.queue_free()
	UiTheme.text_scale = was
	await process_frame

func _label_nodes(node: Node, out: Array = []) -> Array:
	if node is Label:
		out.append(node)
	for c in node.get_children():
		_label_nodes(c, out)
	return out

## OSM candidates are made at 0, 0 and placed later: each must come out
## with its own id (the card, callouts and article fetch are keyed by it).
func _callout_ids() -> void:
	var data := LocationData.new()
	data.latitude = 60.4518
	data.longitude = 22.2666
	data.landmark_candidates = [
		{"name": "Old tower", "x": 120.0, "z": -40.0, "archetype": "tower", "height": 30.0},
		{"name": "Mill chapel", "x": -300.0, "z": 220.0, "archetype": "chapel", "height": 12.0}]
	var callouts := ViewCallouts.new(null)
	callouts.set_place(data, null)
	var sites := callouts.sites()
	_check(sites.size() == 2, "both candidates became sites: %d" % sites.size())
	if sites.size() == 2:
		_check(str(sites[0]["id"]) != str(sites[1]["id"]), "each landmark has its own id: %s, %s" % [sites[0]["id"], sites[1]["id"]])
		for s in sites:
			_check(str(s["id"]) == "osm:%.5f,%.5f" % [float(s["lat"]), float(s["lon"])] and float(s["lat"]) != 0.0,
				"the id names where the landmark stands: %s at %s, %s" % [s["id"], s["lat"], s["lon"]])
	# So an article for one never lands on the other's card.
	var wiki := WikiFetcher.new()
	wiki.offline_mode = true
	root.add_child(wiki)
	var card := LandmarkCard.new(wiki)
	root.add_child(card)
	if sites.size() == 2:
		card.show_site(sites[1])
		await process_frame
		wiki.info_ready.emit(str(sites[0]["id"]), {"extract": "The old tower.", "description": "", "url": ""})
		_check(card._extract.text == "", "another landmark's article stays off this card: '%s'" % card._extract.text)
	card.queue_free()
	wiki.queue_free()
	callouts.free()
	await process_frame

func _panel_flow() -> void:
	var wiki := WikiFetcher.new()
	wiki.offline_mode = true
	root.add_child(wiki)
	var panel := LandmarkPanel.new(wiki)
	root.add_child(panel)
	var rows := LandmarkList.rank(_around(), Vector3(0, 30, 0))
	var states := [0]
	var went := []
	panel.state_changed.connect(func() -> void: states[0] += 1)
	panel.go_requested.connect(func(s: Dictionary) -> void: went.append(s))
	var closer := []
	panel.closer_requested.connect(func(s: Dictionary) -> void: closer.append(s))

	panel.open_list(rows)
	_check(panel.is_listing() and panel.is_open() and panel.list.visible and not panel.card.visible,
		"the list opens, the card waits")
	_check(not panel._back.visible and panel._title.text == LandmarkPanel.LIST_TITLE, "titled, nothing to go back to")
	_open_button(panel.list, 0).pressed.emit()
	await process_frame
	_check(not panel.is_listing() and panel.is_open() and panel.card.visible and not panel.list.visible,
		"a row opens the card in the same panel")
	_check(panel._back.visible, "the card offers Back to the list")
	_check(str(panel.card.site.get("name", "")) == "Near chapel", "the card shows the picked landmark")
	_check(panel.card._distance.value_text() == "200 m", "the card shows the distance from here: " + panel.card._distance.value_text())
	_check(panel._title.text == "", "the card names itself")
	_check(root.gui_get_focus_owner() == panel._back, "picking a row puts focus on Back")
	panel.update_list(rows.slice(0, 1))
	_check(panel.list.row_count() == 3, "new rows wait while a card is up")
	panel._back.pressed.emit()
	_check(panel.is_listing() and panel.list.visible and not panel.card.visible and not panel._back.visible,
		"Back returns to the list")
	_check(panel.list.row_count() == 1, "Back shows the rows that arrived meanwhile, not a stale list")
	_check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner() == _open_button(panel.list, 0),
		"Back returns focus to a row, not nowhere")
	panel.update_list(rows.slice(0, 2))
	_check(panel.list.row_count() == 2, "late rows join an open list")
	panel.update_list([], true)
	_check(_labels(panel.list) == [LandmarkList.PENDING], "the panel passes the pending state to the list")
	panel.update_list(rows.slice(0, 2))
	# Back lands on the row of the landmark just read.
	_open_button(panel.list, 1).pressed.emit()
	panel._back.pressed.emit()
	_check(root.gui_get_focus_owner() == _open_button(panel.list, 1), "Back focuses the row it came from")

	_open_button(panel.list, 1).pressed.emit()
	panel.card.go_requested.emit(panel.card.site)
	_check(not panel.is_open() and went.size() == 1 and went[0]["name"] == "Mid bridge", "Go there from the card closes and visits")
	panel.open_list(rows)
	_go_button(panel.list, 0).pressed.emit()
	_check(not panel.is_open() and went.size() == 2 and went[1]["name"] == "Near chapel", "Go there from a row closes and visits")

	_open_button(panel.list, 1).pressed.emit()
	panel.card._closer.pressed.emit()
	_check(not panel.is_open() and closer.size() == 1 and closer[0]["name"] == "Mid bridge" and went.size() == 2,
		"Get closer from the card closes and visits closer, not as Go there")

	# A tapped callout opens the card with nothing to go back to.
	panel.open(rows[0]["site"], 120.0)
	_check(panel.card.visible and not panel._back.visible and not panel.is_listing(), "a callout opens the bare card")
	_check(panel.card._distance.value_text() == "120 m", "callout distance")
	_check(panel.close() and not panel.close(), "close reports whether it was open")
	_check(states[0] >= 8, "every open, switch and close announces itself: %d" % states[0])

	# Placement: content height, capped at the room it is given.
	panel.open_list(rows)
	await process_frame
	await process_frame
	panel.place(Rect2(20, 80, 376, 600), false)
	_check(panel.size.x == 376.0 and panel.size.y > 100.0 and panel.size.y < 600.0, "three rows take their own height: %s" % panel.size)
	var many: Array = []
	for i in 12:
		many.append(_site("Place %d" % i, Vector3(100 * (i + 1), 30, 0)))
	panel.open_list(LandmarkList.rank(many, Vector3(0, 30, 0)))
	await process_frame
	await process_frame
	panel.place(Rect2(20, 80, 376, 400), false)
	_check(is_equal_approx(panel.size.y, 400.0), "twelve rows fill the room and scroll: %s" % panel.size)
	panel.place(Rect2(20, 80, 376, 400), true)
	_check(is_equal_approx(panel.position.y + panel.size.y, 480.0), "a bottom sheet sits on the room's bottom edge")
	panel.queue_free()
	wiki.queue_free()
	await process_frame

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e

func _view_wiring() -> void:
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280, 800)
	view._wiki.offline_mode = true
	# No weather request: nothing in this test may reach the network.
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
	var btn: Button = view._nearby_btn
	_check(btn != null and btn.tooltip_text.contains("Nearby landmarks"), "the controls offer a Nearby landmarks button")
	var panel: LandmarkPanel = view._landmark_panel
	# Nothing found, and the nearby articles still on their way: "looking",
	# then, once they answer with nothing, "none found".
	_check(not view._nearby_pending, "the (offline) nearby answer has cleared the pending flag")
	view._nearby_pending = true
	ViewChrome.toggle_nearby(view)
	_check(_labels(panel.list) == [LandmarkList.PENDING], "opened before the answer: still looking: %s" % [_labels(panel.list)])
	view._wiki.nearby_ready.emit(flat.latitude, flat.longitude, 10000, [])
	_check(not view._nearby_pending and _labels(panel.list) == [LandmarkList.EMPTY],
		"the answer settles it: none found: %s" % [_labels(panel.list)])
	view._nearby_pending = true
	view._wiki.nearby_ready.emit(flat.latitude + 1.0, flat.longitude, 10000, [])
	_check(view._nearby_pending, "an answer for another place does not settle this one")
	view._nearby_pending = false
	ViewChrome.toggle_nearby(view)
	view._callouts.add_sites([
		LandmarkVisit.site("Old chapel", flat.latitude, flat.longitude + 0.01, "Chapel"),
		LandmarkVisit.site("Old tower", flat.latitude + 0.002, flat.longitude, "Tower")])
	btn.pressed.emit()
	await process_frame
	_check(panel.is_listing() and panel.list.row_count() == 2, "the button lists the landmarks around the camera: %d" % panel.list.row_count())
	var names := _labels(panel.list)
	_check(names.find("Old tower") != -1 and names.find("Old tower") < names.find("Old chapel"),
		"the nearer one comes first: %s" % [names])
	_check((btn.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == UiTheme.TEAL, "the button lights while the list is up")
	_check(panel.position.x < view.size.x / 2.0 and panel.size.y > 0.0, "laid out as the left side panel: %s %s" % [panel.position, panel.size])
	btn.pressed.emit()
	_check(not panel.is_open() and (btn.get_theme_stylebox("normal") as StyleBoxFlat).bg_color != UiTheme.TEAL,
		"the button closes it and goes dark")
	_check(ViewChrome.handle_key(view, _key(KEY_L)) and panel.is_listing(), "L opens the list")
	_check(view.get_viewport().gui_get_focus_owner() == _open_button(panel.list, 0), "L puts focus on the nearest landmark")
	_check(ViewChrome.handle_key(view, _key(KEY_L)) and not panel.is_open(), "L closes it")
	# One bare press only: not a held key repeating, not a shortcut.
	var held := _key(KEY_L)
	held.echo = true
	_check(not ViewChrome.handle_key(view, held) and not panel.is_open(), "a held L does not repeat")
	for modifier in ["ctrl_pressed", "meta_pressed", "alt_pressed"]:
		var chord := _key(KEY_L)
		chord.set(modifier, true)
		_check(not ViewChrome.handle_key(view, chord) and not panel.is_open(), "%s + L is left to the system" % modifier)
	ViewChrome.handle_key(view, _key(KEY_L))
	_open_button(panel.list, 0).pressed.emit()
	_check(str(panel.card.site.get("name", "")) == "Old tower", "a row opens its landmark in the panel")
	_check(ViewChrome.handle_key(view, _key(KEY_ESCAPE)) and not panel.is_open(), "Esc closes the panel")
	# Articles that arrive after the list opened join it.
	ViewChrome.handle_key(view, _key(KEY_L))
	view._callouts.add_sites([LandmarkVisit.site("Late castle", flat.latitude - 0.004, flat.longitude, "Castle")])
	ViewChrome.refresh_nearby(view)
	_check(panel.list.row_count() == 3, "a late article joins the open list: %d" % panel.list.row_count())
	# Nothing new: the rows (and keyboard focus on one) are left alone.
	var row0 := _open_button(panel.list, 0)
	row0.grab_focus()
	ViewChrome.refresh_nearby(view)
	_check(_open_button(panel.list, 0) == row0 and row0.has_focus(), "a refresh that adds nothing leaves the rows alone")
	# Articles that arrive while a card is up are there when Back returns.
	_open_button(panel.list, 0).pressed.emit()
	view._callouts.add_sites([LandmarkVisit.site("Hill fort", flat.latitude, flat.longitude - 0.02, "Fort")])
	ViewChrome.refresh_nearby(view)
	_check(panel.card.visible and panel.list.row_count() == 3, "a card stays up while rows arrive")
	panel._back.pressed.emit()
	_check(panel.is_listing() and panel.list.row_count() == 4, "Back shows the article that arrived meanwhile: %d" % panel.list.row_count())
	_check(ViewChrome.handle_key(view, _key(KEY_ESCAPE)) and not panel.is_open(), "Esc closes it")
	# Get closer stands nearer the landmark than Go there does.
	var was := UiPrefs.reduce_motion
	UiPrefs.reduce_motion = true
	var tower: Dictionary = LandmarkVisit.site("Old tower", flat.latitude + 0.002, flat.longitude, "Tower")
	view.visit(tower)
	await create_timer(0.2).timeout
	var go_range := _range_to(view, tower, flat)
	view.visit(tower, true)
	await create_timer(0.2).timeout
	var close_range := _range_to(view, tower, flat)
	_check(absf(go_range - LandmarkVisit.standoff_m(tower)) < 2.0, "Go there stands at the standoff: %.0f m" % go_range)
	_check(absf(close_range - LandmarkVisit.close_standoff_m(tower)) < 2.0, "Get closer stands at the close standoff: %.0f m" % close_range)
	view.visit(tower, true)
	await create_timer(0.2).timeout
	_check(absf(_range_to(view, tower, flat) - close_range) < 2.0, "Get closer again does not back off")
	UiPrefs.reduce_motion = was
	view.queue_free()
	await process_frame

func _range_to(view: View360, site: Dictionary, data: LocationData) -> float:
	var lp := WorldScale.xz_from_latlon(float(site["lat"]), float(site["lon"]), data.latitude, data.longitude)
	return lp.distance_to(Vector2(view._rig.position.x, view._rig.position.z))
