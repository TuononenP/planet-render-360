extends SceneTree

## Headless: godot --headless --script tests/liner_passages_test.gd
## Moving cruise ferries and liners (HarbourFerries LINER_ROUTES): each
## approach fairway carries its companies' ships in open water, the ships
## build as detailed cruise ferries, wear their line liveries, and travel
## under the RouteBoatDriver with slow liner handling. Far-away cities get
## none, and non-Ultra presets build none.

var failures: Array[String] = []

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _data(at: Vector2, height: float) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(height)
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = at.x
	d.longitude = at.y
	return d

func _lake(d: LocationData, half_m: float) -> void:
	var m := half_m
	d.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])}]

func _terminal(route: Dictionary) -> Vector2:
	var pts: Array = route["points"]
	var end: Array = pts[pts.size() - 1]
	return Vector2(float(end[0]), float(end[1]))

func _init() -> void:
	var m := WorldScale.metres_to_units()
	_check(HarbourFerries.LINER_ROUTES.size() >= 7, "liner passages cover Helsinki, Stockholm, Turku and a major port, got %d" % HarbourFerries.LINER_ROUTES.size())
	var ids := {}
	for route: Dictionary in HarbourFerries.LINER_ROUTES:
		ids[str(route["id"])] = true
	for want in ["helsinki_silja", "helsinki_viking", "helsinki_west", "stockholm_viking",
			"stockholm_silja", "turku_approach", "miami_cruise"]:
		_check(ids.has(want), "liner passages include %s" % want)
	# Each fairway carries its ships in open water with the right livery.
	# The world is centred at the terminal (as a city viewpoint would be);
	# the ships ride the approach inside the detailed ground.
	for route: Dictionary in HarbourFerries.LINER_ROUTES:
		var d := _data(_terminal(route), -8.0)
		_lake(d, 2400.0 * m)
		var g := GroundTruth.new(d)
		var mask := VegetationMask.new(d, g)
		var boats := HarbourFerries.liner_boats(d, g, mask).filter(
			func(b: Dictionary) -> bool: return str(b["route"]) == str(route["id"]))
		_check(boats.size() == (route["boats"] as Array).size(),
			"%s should carry %d moving ships, got %d" % [route["id"], (route["boats"] as Array).size(), boats.size()])
		for b: Dictionary in boats:
			var length := float(route["length"])
			var beam := float(route["beam"])
			_check(HarbourFerries._open(g, mask, b["centre"], b["axis"],
					(length + 2.0 * HarbourFerries.LINER_MARGIN_M) * m,
					(beam + 2.0 * HarbourFerries.LINER_MARGIN_M) * m),
				"%s stands in open water" % route["id"])
			_check(float(b["hi"]) > float(b["lo"]), "%s has open water to travel" % route["id"])
			var lm := HarbourFerries.liner_model(route, b)
			var holder := Node3D.new()
			_check(lm.commit(holder, "L_").size() >= 8, "%s builds a detailed cruise ferry" % route["id"])
			holder.free()
	# Listed lines resolve to CruiseLivery rows; Stockholm ships carry the port colours.
	for route: Dictionary in HarbourFerries.LINER_ROUTES:
		for entry: Dictionary in route["boats"]:
			var line_id := str(entry.get("line", route.get("line", "")))
			if line_id != "":
				_check(not FerryLivery.row(line_id).is_empty(), "%s line %s resolves" % [route["id"], line_id])
	var viking := HarbourFerries.LINER_ROUTES.filter(
		func(r: Dictionary) -> bool: return str(r["id"]) == "stockholm_viking")
	_check(viking.size() == 1 and str(viking[0].get("hull", "")) == "#c21f2c",
		"the moving Stadsgården ferry is Viking red")
	# Helsinki West Harbour and Turku fairways each carry two companies.
	var west := HarbourFerries.LINER_ROUTES.filter(func(r: Dictionary) -> bool: return str(r["id"]) == "helsinki_west")
	var turku := HarbourFerries.LINER_ROUTES.filter(func(r: Dictionary) -> bool: return str(r["id"]) == "turku_approach")
	_check(west.size() == 1 and (west[0]["boats"] as Array).size() == 2, "West Harbour carries Tallink and Eckerö")
	_check(turku.size() == 1 and (turku[0]["boats"] as Array).size() == 2, "Turku carries Viking and Silja")
	# They travel: slow liner handling, hulls and wakes follow the driver.
	var d := _data(Vector2(59.3195, 18.1200), -8.0)
	_lake(d, 2400.0 * m)
	var g := GroundTruth.new(d)
	var root := Node3D.new()
	var count := HarbourFerries.build(root, d, g, VegetationMask.new(d, g))
	_check(count >= 1, "the Saltsjön world should embark a moving liner")
	var driver := root.get_node_or_null("RouteBoats") as RouteBoatDriver
	_check(driver != null and not driver.boats.is_empty(), "moving liners are driven")
	if driver != null and not driver.boats.is_empty():
		var liner_rows := driver.boats.filter(func(b: Dictionary) -> bool: return b.has("turn"))
		_check(not liner_rows.is_empty(), "liners carry slow-turn handling")
		for b: Dictionary in liner_rows:
			_check(absf(float(b["turn"]) - HarbourFerries.LINER_TURN_RAD_S) < 0.001,
				"a liner turns slowly, got %.2f rad/s" % float(b["turn"]))
		var start: Array[Vector2] = []
		for b: Dictionary in driver.boats:
			start.append(driver.position_of(int(b["id"])))
		driver.advance(60.0)
		var moved := 0
		for i in driver.boats.size():
			if driver.position_of(int(driver.boats[i]["id"])).distance_to(start[i]) > 10.0 * m:
				moved += 1
		_check(moved >= 1, "a liner travels over a minute")
		var ok_stretch := true
		for step in 300:
			driver.advance(1.0)
			for b: Dictionary in driver.boats:
				if not b.has("turn"):
					continue
				if float(b["s"]) < float(b["lo"]) - 0.01 or float(b["s"]) > float(b["hi"]) + 0.01:
					ok_stretch = false
		_check(ok_stretch, "a liner stays on its stretch")
	root.free()
	# A berthed static ferry keeps the moving liner off its hull.
	_static_separation_checks(m)
	# Nowhere else, and Ultra only.
	var away := _data(Vector2(-33.8688, 151.2093), -8.0)
	_lake(away, 2400.0 * m)
	var ag := GroundTruth.new(away)
	_check(HarbourFerries.liner_boats(away, ag, VegetationMask.new(away, ag)).is_empty(),
		"Sydney gets no Baltic or Miami liner")
	var high := _data(Vector2(59.3195, 18.1200), -8.0)
	high.quality_preset = RenderSettings.Preset.HIGH
	_lake(high, 2400.0 * m)
	var hg := GroundTruth.new(high)
	var hroot := Node3D.new()
	_check(HarbourFerries.build(hroot, high, hg, VegetationMask.new(high, hg)) == 0,
		"liners are Ultra only")
	hroot.free()
	if failures.is_empty():
		print("LINER PASSAGES OK: Helsinki, Stockholm, Turku and Miami approaches carry moving cruise ferries")
		quit(0)
	else:
		for f in failures:
			printerr("LINER PASSAGES FAIL: ", f)
		quit(1)

## A static ferry berthed across the Saltsjön fairway blocks the moving
## Viking liner: the open fairway carries it, a taken hull on its site
## moves it aside, a distant hull leaves it on its site, and the built
## world never shares the berthed hull's rectangle (the liner squeezes
## past while under way, even though neither hull moves once placed).
func _static_separation_checks(m: float) -> void:
	var d := _data(Vector2(59.3195, 18.1200), 3.0)
	d.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-2400.0, 133.0), Vector2(2400.0, 133.0),
			Vector2(2400.0, 2400.0), Vector2(-2400.0, 2400.0)])}]
	d.shore_structures = [{"kind": "quay",
		"points": PackedVector2Array([Vector2(-1060.0, 133.0), Vector2(-560.0, 133.0)])}]
	d.buildings = [{"name": "Test Ferry Terminal", "use": "ferry_terminal", "x": -810.0, "z": -100.0}]
	var g := GroundTruth.new(d)
	var mask := VegetationMask.new(d, g)
	var nominal := HarbourFerries.liner_boats(d, g, mask).filter(
		func(b: Dictionary) -> bool: return str(b["route"]) == "stockholm_viking")
	_check(nominal.size() == 1, "the open fairway should carry the Viking liner, got %d" % nominal.size())
	if nominal.is_empty():
		return
	var centre: Vector2 = nominal[0]["centre"]
	QuayMoorings.begin_plan(d, m)
	var stat := QuayMoorings.liners(d, g, {}, m, mask)
	QuayMoorings.end_plan()
	_check(not stat.is_empty(), "a static ferry should berth at the test quay")
	if stat.is_empty():
		return
	var nearest := INF
	for s in stat:
		nearest = minf(nearest,
			Vector2((s[0] as Vector3).x, (s[0] as Vector3).z).distance_to(centre) / m)
	_check(nearest < HarbourFerries.hull_gap(200.0, 200.0, HarbourFerries.LINER_TAKEN_GAP_M),
		"the test berth should sit on the liner's site, got %.0f m away" % nearest)
	var gap := HarbourFerries.hull_gap(200.0, 200.0, HarbourFerries.LINER_TAKEN_GAP_M)
	var squeezed := HarbourFerries.liner_boats(d, g, mask,
		[{"centre": centre, "length": 200.0}]).filter(
		func(b: Dictionary) -> bool: return str(b["route"]) == "stockholm_viking")
	_check(squeezed.size() == 1, "a taken hull on the site should move the liner aside, not drop it")
	if squeezed.size() == 1:
		_check((squeezed[0]["centre"] as Vector2).distance_to(centre) > gap * m,
			"the liner squeezes past the hull instead of sharing it")
	var clear := HarbourFerries.liner_boats(d, g, mask,
		[{"centre": centre + Vector2(2000.0 * m, 0.0), "length": 200.0}]).filter(
		func(b: Dictionary) -> bool: return str(b["route"]) == "stockholm_viking")
	_check(clear.size() == 1 and (clear[0]["centre"] as Vector2).distance_to(centre) < 0.01 * m,
		"a distant hull should leave the liner on its site")
	var root := Node3D.new()
	HarbourFerries.build(root, d, g, mask)
	var driver := root.get_node_or_null("RouteBoats") as RouteBoatDriver
	var ok := true
	var seen_liner := false
	if driver != null:
		for b: Dictionary in driver.boats:
			if not b.has("turn"):
				continue
			for s in stat:
				var hull_gap := HarbourFerries.hull_gap(float(b["length"]), float(s[2]),
					HarbourFerries.LINER_TAKEN_GAP_M)
				if Vector2((s[0] as Vector3).x, (s[0] as Vector3).z).distance_to(
						driver.position_of(int(b["id"]))) <= hull_gap * m:
					ok = false
			if str(b["route"]) == "stockholm_viking":
				seen_liner = true
				if (driver.position_of(int(b["id"]))).distance_to(centre) < 0.01 * m:
					ok = false
	_check(ok, "a built liner never shares the berthed hull's rectangle")
	_check(seen_liner, "the squeezed liner still sails in the built world")
	root.free()
