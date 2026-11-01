extends SceneTree

## Curated preset vantages and the generic eye: godot --headless --script tests/preset_views_test.gd
## Offline: rows, pin resolution, gazetteer, spawn, eye height, clearance
## and the generic opening heading run on fixture data only.

var failures: Array[String] = []

func _init() -> void:
	_rows()
	_pins()
	_spawn_and_eye()
	_clearance()
	_heading()
	_water_datum()
	_view_clearance()
	_opening_look()
	if failures.is_empty():
		print("PRESET VIEWS OK: rows, pins, gazetteer, spawn, eye, clearance, heading, water datum, look clearance, opening pitch")
		quit(0)
	else:
		for f in failures:
			printerr("PRESET VIEWS FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _rows() -> void:
	var ids := {}
	var picks := LocationData.quick_picks()
	_check(picks.size() == PresetViews.ROWS.size(), "one quick pick per preset row")
	for i in PresetViews.ROWS.size():
		var row: Dictionary = PresetViews.ROWS[i]
		var id := str(row["id"])
		_check(not ids.has(id), "unique id %s" % id)
		ids[id] = true
		_check(PlaceCard.SKY_FOR.has(str(row["label"])), "%s label has a chip sky" % id)
		var eye := PresetViews.eye_xz(row, float(row["lat"]), float(row["lon"]))
		_check(absf(eye.x) < 1100.0 and absf(eye.y) < 1100.0,
			"%s eye inside the detailed extent: %s" % [id, eye])
		_check(float(row["eye_m"]) >= 4.0, "%s eye at least 4 m over the ground" % id)
		_check(float(row["bearing"]) >= 0.0 and float(row["bearing"]) < 360.0, "%s bearing in range" % id)
		_check(absf(float(row.get("pitch", 0.0))) <= 15.0, "%s pitch gentle" % id)
		if i < picks.size():
			var pick: Array = picks[i]
			_check(pick == [str(row["label"]), str(row["name"]), float(row["lat"]), float(row["lon"])],
				"%s quick pick is its row: %s" % [id, pick])

func _pins() -> void:
	for row in PresetViews.ROWS:
		var id := str(row["id"])
		var lat := float(row["lat"])
		var lon := float(row["lon"])
		_check(str(PresetViews.for_pin(lat, lon).get("id", "")) == id, "%s pin resolves its view" % id)
		var near := WorldScale.latlon_from_xz(10.0, 0.0, lat, lon)
		_check(str(PresetViews.for_pin(near.x, near.y).get("id", "")) == id, "%s 10 m off still resolves" % id)
		var off := WorldScale.latlon_from_xz(30.0, 0.0, lat, lon)
		_check(PresetViews.for_pin(off.x, off.y).is_empty(), "%s 30 m off is a plain pin" % id)
		_check(LocationData.known_place(lat, lon) == str(row["name"]), "%s reverse lookup names it" % id)
		var found := false
		for place in LocationData.known_places():
			if str(place["name"]) == str(row["name"]):
				found = is_equal_approx(float(place["lat"]), lat) and is_equal_approx(float(place["lon"]), lon)
		_check(found, "%s search resolves to the curated origin" % id)
	_check(PresetViews.for_pin(35.6762, 139.6503).is_empty(), "the old Setagaya pin is not a preset")
	_check(PresetViews.origin_for_name("Turku, Finland") == Vector2.INF, "non-preset names keep their own coordinates")

func _data_at(lat: float, lon: float) -> LocationData:
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.heights.resize(data.grid_size * data.grid_size)
	return data

func _spawn_and_eye() -> void:
	var tokyo: Dictionary = PresetViews.ROWS.filter(func(r: Dictionary) -> bool: return r["id"] == "tokyo")[0]
	var data := _data_at(float(tokyo["lat"]), float(tokyo["lon"]))
	data.view = tokyo
	data.landmark_type = "tokyo"
	var spawn := View360.spawn_xz(data)
	var want := WorldScale.xz_from_latlon(float(tokyo["eye_lat"]), float(tokyo["eye_lon"]),
		data.latitude, data.longitude)
	_check(spawn.distance_to(want) < 0.01, "a view spawns at its eye, no landmark step-back: %s" % spawn)
	var ground := GroundTruth.new(data)
	var y := View360.eye_y(data, ground, spawn)
	_check(is_equal_approx(y, ground.height_at_world(spawn.x, spawn.y) + 15.0), "eye_m over the ground: %.2f" % y)
	var monaco: Dictionary = PresetViews.ROWS.filter(func(r: Dictionary) -> bool: return r["id"] == "monaco")[0]
	var md := _data_at(float(monaco["lat"]), float(monaco["lon"]))
	md.view = monaco
	var mg := GroundTruth.new(md)
	var my := View360.eye_y(md, mg, Vector2.ZERO)
	_check(is_equal_approx(my, maxf(mg.height_at_world(0, 0) + 4.0, mg.render_y(62.0))),
		"a clifftop eye never drops below its ASL floor: %.2f" % my)
	var plain := _data_at(48.8566, 2.3522)
	_check(View360.spawn_xz(plain) == Vector2.ZERO, "no view, no landmark: spawn at the pin")

func _square(cx: float, cz: float, half: float, height: float) -> Dictionary:
	return {"footprint": PackedVector2Array([Vector2(cx - half, cz - half), Vector2(cx + half, cz - half),
		Vector2(cx + half, cz + half), Vector2(cx - half, cz + half)]),
		"x": cx, "z": cz, "size_x": half * 2.0, "size_z": half * 2.0, "height": height}

func _clearance() -> void:
	var data := _data_at(40.7580, -73.9855)
	var ground := GroundTruth.new(data)
	var g := ground.height_at_world(0, 0)
	_check(is_equal_approx(View360.eye_y(data, ground, Vector2.ZERO), g + View360.EYE_HEIGHT_M),
		"open ground keeps the default eye")
	data.buildings = [_square(0, 0, 10, 120.0), _square(100, 0, 10, 300.0)]
	var y := View360.eye_y(data, ground, Vector2.ZERO)
	_check(absf(y - (g + 120.0 + View360.CLEAR_ABOVE_M)) < 0.5, "inside a 120 m tower the eye clears its roof: %.1f" % (y - g))
	data.buildings = [_square(30, 0, 10, 80.0)]
	y = View360.eye_y(data, ground, Vector2.ZERO)
	_check(absf(y - (g + 80.0 + View360.CLEAR_ABOVE_M)) < 0.5, "a tower 20 m away still counts: %.1f" % (y - g))
	var part := _square(0, 0, 4, 200.0)
	var base := _square(0, 0, 10, 20.0)
	base["parts"] = [part]
	data.buildings = [base]
	y = View360.eye_y(data, ground, Vector2.ZERO)
	_check(absf(y - (g + 200.0 + View360.CLEAR_ABOVE_M)) < 0.5, "a tall part lifts the eye: %.1f" % (y - g))
	_check(is_equal_approx(View360.eye_y(data, ground, Vector2(400, 0), false), ground.height_at_world(400, 0) + View360.EYE_HEIGHT_M),
		"far from any roof the default eye holds")

func _heading() -> void:
	var data := _data_at(51.5, 0.0)
	var ground := GroundTruth.new(data)
	_check(is_equal_approx(View360.default_yaw(data, ground, Vector2.ZERO), 0.6),
		"no buildings and no water keeps the v1 heading")
	data.buildings = [_square(300, 0, 20, 40.0), _square(320, 40, 20, 30.0), _square(-200, 0, 10, 6.0)]
	var yaw := View360.default_yaw(data, ground, Vector2.ZERO)
	_check(absf(wrapf(yaw + PI / 2.0, -PI, PI)) < 0.2, "faces the built mass to the east: %.2f" % yaw)

func _water_datum() -> void:
	# A hilltop pin: centre 60 m over a 26 m river valley (v1 rule would
	# put the datum at 60 − 6/0.35 ≈ 43 m and flood the valley).
	var raw := PackedFloat32Array()
	for z in 9:
		for x in 9:
			raw.append(26.0 + 34.0 * (1.0 - absf(float(x) - 4.0) / 4.0))
	var conv: Dictionary = GenerationPipeline.convert_dem_heights(raw, 9, false)
	_check(float(conv["water_level"]) <= 26.0, "the water datum never rises above the lowest ground: %.1f" % float(conv["water_level"]))
	var flat := PackedFloat32Array()
	flat.resize(81)
	flat.fill(35.0)
	flat[0] = 20.0
	var cf: Dictionary = GenerationPipeline.convert_dem_heights(flat, 9, false)
	_check(is_equal_approx(float(cf["water_level"]), 35.0 - 6.0 / DemConversion.legacy_vscale_for(15.0)),
		"a low pin keeps the v1 datum: %.1f" % float(cf["water_level"]))

func _view_clearance() -> void:
	var data := _data_at(51.5, 0.0)
	var ground := GroundTruth.new(data)
	var g := ground.height_at_world(0, 0)
	_check(View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, 0.0) == -INF, "nothing in front, no lift")
	# A 20 m block whose near wall is 40 m due north (yaw 0 faces north).
	data.buildings = [_square(0, -50, 10, 20.0)]
	var y := View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, 0.0)
	_check(absf(y - (g + 20.0 + View360.CLEAR_ABOVE_M)) < 0.5, "a level look clears a roof 40 m ahead: %.1f" % (y - g))
	y = View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, -0.1)
	_check(absf(y - (g + 26.0 + 40.0 * tan(0.1))) < 0.5, "a downward look needs the roof under its line: %.1f" % (y - g))
	_check(View360.view_clearance_y(data, ground, Vector2.ZERO, PI, 0.0) == -INF, "the same block behind the look is ignored")
	_check(View360.view_clearance_y(data, ground, Vector2.ZERO, -PI / 2.0, 0.0) == -INF, "and beside it (look east)")
	data.buildings = [_square(0, -150, 10, 20.0)]
	_check(View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, 0.0) == -INF, "a block 140 m ahead is the view, not a blocker")
	# A wide slab across the look whose corners lie outside the wedge.
	data.buildings = [{"footprint": PackedVector2Array([Vector2(-200, -30), Vector2(200, -30), Vector2(200, -40), Vector2(-200, -40)]),
		"x": 0.0, "z": -35.0, "size_x": 400.0, "size_z": 10.0, "height": 15.0}]
	y = View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, 0.0)
	_check(absf(y - (g + 15.0 + View360.CLEAR_ABOVE_M)) < 0.5, "a wall across the look counts without corners in view: %.1f" % (y - g))
	data.buildings = [_square(0, -50, 10, 400.0)]
	y = View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, 0.0)
	_check(is_equal_approx(y, g + View360.VIEW_LIFT_MAX_M), "the lift is capped: %.1f" % (y - g))
	data.view = {"clear": false}
	_check(View360.view_clearance_y(data, ground, Vector2.ZERO, 0.0, 0.0) == -INF, "a row with clear=false is never lifted")

func _opening_look() -> void:
	var down := View360.opening_look(Vector2(1.2, -0.35))
	_check(is_equal_approx(down.y, View360.OPEN_PITCH_MIN) and is_equal_approx(down.x, 1.2),
		"an aim below the horizon opens level, heading kept: %s" % down)
	_check(is_equal_approx(View360.opening_look(Vector2(0.0, -0.1)).y, View360.OPEN_PITCH_MIN),
		"a slight dip opens level")
	_check(is_equal_approx(View360.opening_look(Vector2(0.0, 0.21)).y, 0.21), "a rising look is kept")
	_check(View360.OPEN_PITCH_MIN >= 0.0, "the opening pitch floor is not downward")
