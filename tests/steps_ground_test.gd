extends SceneTree

## Headless: godot --headless --script tests/steps_ground_test.gd
## StepsGround: a flight of steps holds the ground to its own levels. A
## 40 m plaza at 10 m, a 33-step flight (incline=down) from its edge to a
## park the elevation model puts at 7 m, and a second 12-step flight: the
## top keeps the plaza's level, the foot and the park take the foot's
## (33 risers down), the posts under a flight stay under its treads and
## fall monotonically, a mistagged count cannot dig more than DEM_CLAMP_M
## under the DEM, and steps inside a landmark model's rect are untouched.
## (The plan's 2 m clamp would hold the 33-step foot 0.45 m above its
## 33 risers over a DEM at 7 m; DEM_CLAMP_M is 2.5.)

const SIZE := 129
const STEP_M := 2.0

var _fails := 0

func _init() -> void:
	_run()
	if _fails == 0:
		print("steps_ground_test: PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _near(a: float, b: float, tol: float, what: String) -> void:
	_check(absf(a - b) <= tol, "%s: %.3f, want %.3f ± %.2f" % [what, a, b, tol])

## World position of post (x, z), units.
func _post(x: int, z: int) -> Vector2:
	var m := WorldScale.metres_to_units()
	return Vector2((float(x) - float(SIZE) * 0.5) * STEP_M * m, (float(z) - float(SIZE) * 0.5) * STEP_M * m)

func _index(p: Vector2) -> int:
	var m := WorldScale.metres_to_units()
	var x := roundi(p.x / (STEP_M * m) + float(SIZE) * 0.5)
	var z := roundi(p.y / (STEP_M * m) + float(SIZE) * 0.5)
	return z * SIZE + x

## The elevation model: the plaza (x < -1) at 10 m, the ramp the stairs go
## down over the next 10 m, the park (x > 9) at 7 m.
func _dem() -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(SIZE * SIZE)
	for z in SIZE:
		for x in SIZE:
			var wx := _post(x, z).x / WorldScale.metres_to_units()
			s[z * SIZE + x] = 10.0 - 3.0 * clampf((wx + 1.0) / 10.0, 0.0, 1.0)
	return s

func _dry() -> PackedFloat32Array:
	var l := PackedFloat32Array()
	l.resize(SIZE * SIZE)
	l.fill(-INF)
	return l

func _steps(points: Array, count: int, incline: String = "down", id: int = 0) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var pts := PackedVector2Array()
	for p: Vector2 in points:
		pts.append(p * m)
	return {"class": "steps", "points": pts, "width_m": 2.0, "step_count": count, "incline": incline,
		"handrail": false, "bridge": false, "tunnel": false, "layer": 0}

func _park() -> Dictionary:
	var m := WorldScale.metres_to_units()
	return {"class": "grass", "holes": [], "points": PackedVector2Array([
		Vector2(9, -15) * m, Vector2(40, -15) * m, Vector2(40, 15) * m, Vector2(9, 15) * m])}

func _data(roads: Array) -> LocationData:
	var data := LocationData.new()
	data.roads = roads
	data.land_polygons = [_park()]
	return data

func _run() -> void:
	var m := WorldScale.metres_to_units()
	var step := STEP_M * m
	var dem := _dem()
	var surface := dem.duplicate()
	var level := _dry()
	var data := _data([_steps([Vector2(-1, 0), Vector2(9, 0)], 33),
		_steps([Vector2(-20, -30), Vector2(-16, -30)], 12)])
	var flights := StepsGround.apply(surface, level, SIZE, step, data, m)
	_check(flights.size() == 2, "two flights kept, got %d" % flights.size())
	if flights.size() != 2:
		return
	var big: Dictionary = flights[0]
	var small: Dictionary = flights[1]
	_near(float(big["y_top"]), 10.0, 0.01, "33-step flight top")
	_near(float(big["y_bot"]), 10.0 - 33.0 * StepsGround.RISER_M, 0.01, "33-step flight foot")
	_check(int(big["n"]) == 33, "33 risers, got %d" % int(big["n"]))
	# On a plaza the DEM shows no drop on, the 12 steps dig nothing: the foot
	# stays at the DEM and the stair rises from it, by no more than DEM_RISE_M.
	_near(float(small["y_bot"]), 10.0, 0.01, "12 steps on a flat plaza keep their foot at the DEM")
	_check(float(small["y_top"]) <= 10.0 + StepsGround.DEM_RISE_M + 0.01, "and their top is no higher than DEM_RISE_M over it")
	_check((big["points"] as PackedVector2Array)[0].x < (big["points"] as PackedVector2Array)[1].x,
		"points run from the top node down")

	# The plaza behind the top keeps its level, the foot's disc holds the foot's.
	_near(surface[_index(Vector2(-5, 0) * m)], 10.0, 0.2, "plaza behind the top")
	var foot := 10.0 - 33.0 * StepsGround.RISER_M
	_near(surface[_index(Vector2(13, 0) * m)], foot, 0.2, "ground a few metres past the foot")
	# The park at the foot lies at the foot's level, not the ramp's.
	var sum := 0.0
	var n := 0
	for z in range(-12, 13, 2):
		for x in range(15, 38, 2):
			sum += surface[_index(Vector2(x, z) * m)]
			n += 1
	_near(sum / float(n), foot, 0.3, "park mean")
	# Under the flight: never above the treads' line less the clearance, falling.
	var prev := INF
	for x in range(-1, 10, 2):
		var h := surface[_index(Vector2(x, 0) * m)]
		var line := lerpf(10.0, foot, float(x + 1) / 10.0)
		_check(h <= line - StepsGround.CLEAR_M + 0.001, "post at %d m is %.2f, under the treads' %.2f" % [x, h, line])
		_check(h <= prev + 0.001, "ground under the flight falls (%d m: %.2f after %.2f)" % [x, h, prev])
		prev = h
	# Far from every flight nothing moved.
	_check(surface[_index(Vector2(-90, 60) * m)] == dem[_index(Vector2(-90, 60) * m)], "far ground untouched")

	# A mistagged count digs no deeper than the clamp under the DEM.
	var bad_surface := dem.duplicate()
	var bad := StepsGround.apply(bad_surface, _dry(), SIZE, step,
		_data([_steps([Vector2(-1, 0), Vector2(5, 0)], 400)]), m)
	_check(bad.size() == 1, "mistagged flight kept")
	var deepest := 0.0
	for i in bad_surface.size():
		deepest = maxf(deepest, dem[i] - bad_surface[i])
	_check(deepest <= StepsGround.DEM_CLAMP_M + StepsGround.RISER_M + StepsGround.CLEAR_M + 0.05,
		"mistagged count dug %.2f m under the DEM" % deepest)

	# Carved water is left alone.
	var wet := dem.duplicate()
	var wet_level := _dry()
	var wet_i := _index(Vector2(13, 0) * m)
	wet_level[wet_i] = 5.0
	StepsGround.apply(wet, wet_level, SIZE, step, data, m)
	_check(wet[wet_i] == dem[wet_i], "a water post is not held")

	# A flight with no incline on ground the DEM cannot tell apart is left alone.
	_check(StepsGround.apply(dem.duplicate(), _dry(), SIZE, step,
		_data([_steps([Vector2(-40, 20), Vector2(-34, 20)], 7, "")]), m).is_empty(),
		"a flight whose direction nothing tells is left to its ribbon")

	# With no incline the DEM must show the drop: 33 steps down the DEM's 3 m
	# ramp stand, whichever way round the way is mapped; 7 steps over the
	# 0.6 m the ramp drops in 2 m do not.
	for pts: Array in [[Vector2(-1, 0), Vector2(9, 0)], [Vector2(9, 0), Vector2(-1, 0)]]:
		var found := StepsGround.apply(dem.duplicate(), _dry(), SIZE, step, _data([_steps(pts, 33, "")]), m)
		_check(found.size() == 1 and absf(float((found[0] as Dictionary)["y_top"]) - 10.0) < 0.01,
			"33 steps with no incline stand with their top at the high end (%s)" % [pts])
	_check(StepsGround.apply(dem.duplicate(), _dry(), SIZE, step,
		_data([_steps([Vector2(-1, 0), Vector2(1, 0)], 7, "")]), m).is_empty(),
		"7 steps over 0.6 m of DEM are left to their ribbon")

	# A ring of flights (the steps round a statue's pedestal) stacks no mound
	# over the DEM, whichever way round the levels run.
	var ring_surface := dem.duplicate()
	var corners: Array[Vector2] = [Vector2(-40, 30), Vector2(-34, 30), Vector2(-34, 36), Vector2(-40, 36)]
	var ring_roads: Array = []
	for k in 4:
		ring_roads.append(_steps([corners[k], corners[(k + 1) % 4]], 7))
	StepsGround.apply(ring_surface, _dry(), SIZE, step, _data(ring_roads), m)
	var raised := 0.0
	for i in ring_surface.size():
		raised = maxf(raised, ring_surface[i] - dem[i])
	_check(raised <= StepsGround.HOLD_RAISE_M + 0.01, "a ring of flights raised the ground %.2f m over the DEM" % raised)

	# A ring of flights that a flight the DEM cannot place joins to another
	# flight is still a ring: it is dropped, the other flight stands alone.
	var split_roads: Array = []
	var sq: Array[Vector2] = [Vector2(20, 30), Vector2(26, 30), Vector2(26, 36), Vector2(20, 36)]
	for k in 4:
		split_roads.append(_steps([sq[k], sq[(k + 1) % 4]], 7))
	split_roads.append(_steps([Vector2(26, 36), Vector2(32, 36)], 7, ""))
	split_roads.append(_steps([Vector2(32, 36), Vector2(32, 42)], 7))
	split_roads.append({"class": "residential", "points": PackedVector2Array([Vector2(20, 20) * m, Vector2(20, 30) * m]),
		"width_m": 6.0, "bridge": false, "tunnel": false})
	var split_surface := dem.duplicate()
	var split := StepsGround.apply(split_surface, _dry(), SIZE, step, _data(split_roads), m)
	_check(split.size() == 1 and int((split[0] as Dictionary)["road"]) == 5,
		"a split system keeps the flight off the ring alone, got %s" % [split.map(func(f: Dictionary) -> int: return int(f["road"]))])
	var split_raised := 0.0
	for i in split_surface.size():
		split_raised = maxf(split_raised, split_surface[i] - dem[i])
	_check(split_raised <= StepsGround.HOLD_RAISE_M + 0.01, "a split ring raised the ground %.2f m" % split_raised)

	# The terrace a short flight comes down from keeps its level: only the
	# park at a foot is levelled to it.
	var terrace := {"class": "pedestrian", "area": true, "bridge": false, "tunnel": false, "layer": 0, "holes": [],
		"width_m": 0.0, "points": PackedVector2Array([Vector2(-30, -15) * m, Vector2(-1, -15) * m,
			Vector2(-1, 15) * m, Vector2(-30, 15) * m])}
	var terrace_surface := dem.duplicate()
	var short := StepsGround.apply(terrace_surface, _dry(), SIZE, step,
		_data([_steps([Vector2(-1, 0), Vector2(1, 0)], 6), terrace]), m)
	_check(short.size() == 1, "the short flight off the terrace kept, got %d" % short.size())
	_near(terrace_surface[_index(Vector2(-21, 7) * m)], 10.0, 0.001, "terrace a short flight comes down from")

	# The park keeps the buildings in it, a building's courtyard is levelled
	# with it, and a building counts by its footprint, not its centre.
	var built := _data([_steps([Vector2(-1, 0), Vector2(9, 0)], 33)])
	built.buildings = [
		{"x": 26.0 * m, "z": -8.0 * m, "footprint": PackedVector2Array([Vector2(14, -14) * m, Vector2(38, -14) * m,
			Vector2(38, -2) * m, Vector2(14, -2) * m]), "holes": [PackedVector2Array([Vector2(17, -11) * m,
			Vector2(35, -11) * m, Vector2(35, -5) * m, Vector2(17, -5) * m])]},
		{"x": 120.0 * m, "z": 120.0 * m, "footprint": PackedVector2Array([Vector2(28, 4) * m, Vector2(38, 4) * m,
			Vector2(38, 12) * m, Vector2(28, 12) * m])},
	]
	var built_surface := dem.duplicate()
	StepsGround.apply(built_surface, _dry(), SIZE, step, built, m)
	_near(built_surface[_index(Vector2(21, 7) * m)], foot, 0.001, "open park at the foot")
	_near(built_surface[_index(Vector2(25, -7) * m)], foot, 0.001, "a courtyard in the park")
	_near(built_surface[_index(Vector2(15, -13) * m)], 7.0, 0.001, "ground under a building in the park")
	_near(built_surface[_index(Vector2(33, 7) * m)], 7.0, 0.001, "ground under a building centred far off")

	# A bridge keeps its plain ways, and so does a system touching one.
	var on_bridge := _steps([Vector2(-1, 0), Vector2(9, 0)], 33)
	on_bridge["bridge"] = true
	_check(StepsGround.apply(dem.duplicate(), _dry(), SIZE, step, _data([on_bridge]), m).is_empty(),
		"steps on a bridge are left alone")
	var deck := {"class": "footway", "points": PackedVector2Array([Vector2(-21, 0) * m, Vector2(-1, 0) * m]),
		"bridge": true, "layer": 1, "width_m": 3.0}
	_check(StepsGround.apply(dem.duplicate(), _dry(), SIZE, step,
		_data([_steps([Vector2(-1, 0), Vector2(9, 0)], 33), deck]), m).is_empty(),
		"a system touching a bridge is left alone")
	# A flight under the minimum drop keeps its ribbon.
	_check(StepsGround.apply(dem.duplicate(), _dry(), SIZE, step,
		_data([_steps([Vector2(-1, 0), Vector2(1, 0)], 1)]), m).is_empty(),
		"a one-step flight keeps the plain ribbon")

	# A street at the foot anchors the system: the foot stays at the street's
	# level and the top rises from it.
	var street := {"class": "residential", "points": PackedVector2Array([Vector2(9, -20) * m, Vector2(9, 0) * m]),
		"width_m": 6.0, "bridge": false, "tunnel": false}
	var anchored := StepsGround.apply(dem.duplicate(), _dry(), SIZE, step,
		_data([_steps([Vector2(-1, 0), Vector2(9, 0)], 10), street]), m)
	_check(anchored.size() == 1, "anchored flight kept")
	if anchored.size() == 1:
		_near(float((anchored[0] as Dictionary)["y_bot"]), 7.0, 0.01, "the street's node keeps the DEM level")
		_near(float((anchored[0] as Dictionary)["y_top"]), 7.0 + 10.0 * StepsGround.RISER_M, 0.01,
			"the top rises 10 risers from the street")

	# Steps inside a landmark model's rect keep the model's own stairs.
	var e := LocationData.entry_for_type("helsinki_cathedral")
	var site := LocationData.new()
	site.latitude = float(e["lat"])
	site.longitude = float(e["lon"])
	site.landmark_type = "helsinki_cathedral"
	site.has_landmark_site = true
	site.landmark_lat = site.latitude
	site.landmark_lon = site.longitude
	var axis := LandmarkSites.axis(e)
	var statue := axis * 0.6 + Vector2(-axis.y, axis.x) * 97.0
	for at: Vector2 in [statue, statue + Vector2(0, 40)]:
		site.roads = [_steps([at - Vector2(5, 0), at + Vector2(5, 0)], 33)]
		var fresh := dem.duplicate()
		var kept := StepsGround.apply(fresh, _dry(), SIZE, step, site, m)
		var inside: bool = at == statue
		_check(kept.is_empty() == inside, "steps at %s: kept %d, inside a model rect %s" % [at, kept.size(), inside])
		_check((fresh == dem) == inside, "ground at %s %s" % [at, "untouched inside the rect" if inside else "held outside it"])
