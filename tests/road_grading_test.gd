extends SceneTree

## Headless: godot --headless --script tests/road_grading_test.gd
## RoadGrading.grade_areas: a mapped square (pedestrian area) lies on the
## best-fit plane of its own posts, so a surface-model DEM's mounds go
## (Gwanghwamun's square and woldae), a sloping square keeps its slope,
## posts well outside are untouched, and no post moves more than
## AREA_MAX_SHIFT_M.

const SIZE := 41
const STEP_M := 10.0

var _fails := 0

func _init() -> void:
	_run()
	if _fails == 0:
		print("road_grading_test: PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _post(x: int, z: int) -> Vector2:
	var m := WorldScale.metres_to_units()
	return Vector2((float(x) - SIZE * 0.5) * STEP_M * m, (float(z) - SIZE * 0.5) * STEP_M * m)

## A square area way covering posts [a, b] in both axes (half a post out).
func _square(a: int, b: int, cls: String = "pedestrian") -> Dictionary:
	var m := WorldScale.metres_to_units()
	var lo := _post(a, a) - Vector2.ONE * STEP_M * 0.5 * m
	var hi := _post(b, b) + Vector2.ONE * STEP_M * 0.5 * m
	return {"class": cls, "area": true, "points": PackedVector2Array([lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y)])}

func _surface(fn: Callable) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(SIZE * SIZE)
	for z in SIZE:
		for x in SIZE:
			s[z * SIZE + x] = fn.call(x, z)
	return s

func _dry() -> PackedFloat32Array:
	var l := PackedFloat32Array()
	l.resize(SIZE * SIZE)
	l.fill(-INF)
	return l

func _std(s: PackedFloat32Array, a: int, b: int, plane: Callable) -> float:
	var sum := 0.0
	var sq := 0.0
	var n := 0.0
	for z in range(a, b + 1):
		for x in range(a, b + 1):
			var d: float = s[z * SIZE + x] - float(plane.call(x, z))
			sum += d
			sq += d * d
			n += 1.0
	var mean := sum / n
	return sqrt(maxf(sq / n - mean * mean, 0.0))

func _run() -> void:
	var step := STEP_M * WorldScale.metres_to_units()
	# Mounds of ±2.5 m over a 30 m ground (a surface-model DEM's blocks).
	var bumpy := func(x: int, z: int) -> float: return 30.0 + 2.5 * sin(float(x) * 1.3) * cos(float(z) * 0.9)
	var s := _surface(bumpy)
	var before := s.duplicate()
	RoadGrading.grade_areas(s, _dry(), SIZE, step, [_square(14, 26)])
	var flat := func(_x: int, _z: int) -> float: return 0.0
	_check(_std(s, 14, 26, flat) < 0.3, "a bumpy square lies flat (std %.2f m)" % _std(s, 14, 26, flat))
	_check(is_equal_approx(s[3 * SIZE + 3], before[3 * SIZE + 3]), "posts well outside the square are untouched")
	var moved := 0.0
	for i in s.size():
		moved = maxf(moved, absf(s[i] - before[i]))
	_check(moved <= RoadGrading.AREA_MAX_SHIFT_M + 1e-4, "no post moves more than the cap (%.2f m)" % moved)
	# A square on a 6 % hillside keeps its slope.
	var slope := func(x: int, _z: int) -> float: return 20.0 + 0.6 * float(x)
	var hill := _surface(func(x: int, z: int) -> float: return float(slope.call(x, z)) + 0.8 * sin(float(x * 7 + z * 3)))
	RoadGrading.grade_areas(hill, _dry(), SIZE, step, [_square(10, 30)])
	_check(_std(hill, 10, 30, slope) < 0.3, "a sloping square keeps its slope (std %.2f m off it)" % _std(hill, 10, 30, slope))
	# A 6 m spike inside is cut by at most the cap.
	var spike := _surface(func(x: int, z: int) -> float: return 30.0 + (6.0 if x == 20 and z == 20 else 0.0))
	RoadGrading.grade_areas(spike, _dry(), SIZE, step, [_square(14, 26)])
	_check(spike[20 * SIZE + 20] >= 36.0 - RoadGrading.AREA_MAX_SHIFT_M - 1e-4, "a spike is cut by at most the cap")
	# Only pedestrian and footway areas: a residential street ring is not a square.
	var street := _surface(bumpy)
	var street_before := street.duplicate()
	RoadGrading.grade_areas(street, _dry(), SIZE, step, [_square(14, 26, "residential")])
	_check(street == street_before, "a non-square area is left alone")
	# A nested forecourt takes its own plane after the larger square.
	var nested := _surface(bumpy)
	RoadGrading.grade_areas(nested, _dry(), SIZE, step, [_square(18, 22), _square(10, 30)])
	_check(_std(nested, 18, 22, flat) < 0.3, "a forecourt inside a square lies flat")
	# grade_network (coarse DEMs): Sajik-ro's two carriageways and the shorter
	# slip road between them, over mounds that differ across the roadway,
	# end up on one surface; the per-road grade creases between them.
	var m := WorldScale.metres_to_units()
	var lanes: Array = [
		{"class": "primary", "width_m": 10.0, "points": PackedVector2Array([_post(2, 19), _post(38, 19)])},
		{"class": "primary", "width_m": 10.0, "points": PackedVector2Array([_post(2, 21), _post(38, 21)])},
		{"class": "tertiary_link", "width_m": 10.0, "points": PackedVector2Array([_post(12, 20), _post(28, 20)])}]
	# Within the cap, as UrbanSmooth leaves them before the grade.
	var mounds := func(x: int, z: int) -> float: return 30.0 + 1.2 * sin(float(x) * 0.9) + 0.7 * sin(float(z) * 1.7)
	var crease := func(s: PackedFloat32Array) -> float:
		var worst := 0.0
		for x in range(14, 27):
			var a19: float = s[19 * SIZE + x]
			var a20: float = s[20 * SIZE + x]
			var a21: float = s[21 * SIZE + x]
			worst = maxf(worst, maxf(absf(a19 - a20), maxf(absf(a21 - a20), absf(a19 - a21))))
		return worst
	var along := func(s: PackedFloat32Array) -> float:
		var lo := INF
		var hi := -INF
		for x in range(12, 29):
			lo = minf(lo, s[20 * SIZE + x])
			hi = maxf(hi, s[20 * SIZE + x])
		return hi - lo
	var per_road := _surface(mounds)
	RoadGrading.grade(per_road, _dry(), SIZE, step, lanes, m)
	var net := _surface(mounds)
	var net_before := net.duplicate()
	RoadGrading.grade_network(net, _dry(), SIZE, step, lanes, m)
	_check(float(crease.call(net)) < 0.3, "parallel ways share one surface (crease %.2f m)" % crease.call(net))
	_check(float(crease.call(net)) < float(crease.call(per_road)),
		"the network grade creases less than per-road grading (%.2f vs %.2f m)" % [crease.call(net), crease.call(per_road)])
	_check(float(along.call(net)) < 0.4 * float(along.call(net_before)),
		"the network grade levels block mounds (%.2f m from %.2f m)" % [along.call(net), along.call(net_before)])
	_check(is_equal_approx(net[3 * SIZE + 20], net_before[3 * SIZE + 20]), "ground off the roads is untouched")
	var net_moved := 0.0
	for i in net.size():
		net_moved = maxf(net_moved, absf(net[i] - net_before[i]))
	_check(net_moved <= RoadGrading.NETWORK_MAX_SHIFT_M + 1e-4, "the network grade respects its cap (%.2f m)" % net_moved)
	var road := {"class": "residential", "width_m": 8.0,
		"points": PackedVector2Array([_post(2, 20), _post(38, 20)])}
	var ramp := _surface(func(x: int, _z: int) -> float: return 10.0 + 0.8 * float(x))
	var ramp_before := ramp.duplicate()
	RoadGrading.grade_network(ramp, _dry(), SIZE, step, [road], m)
	var drift := 0.0
	for x in range(10, 31):
		drift = maxf(drift, absf(ramp[20 * SIZE + x] - ramp_before[20 * SIZE + x]))
	_check(drift < 0.1, "a straight ramp keeps its grade on the network (moved %.3f m)" % drift)
	var wet_net := _dry()
	wet_net[20 * SIZE + 20] = 25.0
	var lake := _surface(mounds)
	var lake_before := lake.duplicate()
	RoadGrading.grade_network(lake, wet_net, SIZE, step, [road], m)
	_check(is_equal_approx(lake[20 * SIZE + 20], lake_before[20 * SIZE + 20]), "a water-carved post on the network is left alone")
	# A road ending at a road bridge keeps its embankment: never cut there.
	var bridge := {"class": "primary", "width_m": 8.0, "bridge": true,
		"points": PackedVector2Array([_post(30, 20), _post(38, 20)])}
	var to_bridge := {"class": "primary", "width_m": 8.0, "points": PackedVector2Array([_post(4, 20), _post(30, 20)])}
	var bank := _surface(func(x: int, _z: int) -> float: return 30.0 + (4.0 if x >= 27 else 0.0))
	var bank_before := bank.duplicate()
	RoadGrading.grade_network(bank, _dry(), SIZE, step, [to_bridge, bridge], m)
	_check(bank[20 * SIZE + 29] >= bank_before[20 * SIZE + 29] - 1e-4, "the embankment at a bridge head is not cut")
	var arctic := LocationData.new()
	arctic.latitude = 60.45
	arctic.longitude = 22.27
	_check(not RoadGrading.coarse(arctic), "ArcticDEM north of 60°N is not graded as coarse")
	# UrbanSmooth: block mounds under a city flatten, ground far from any
	# building (past the 60 m reach and the ~90 m feather) is untouched, and
	# no post moves more than its cap.
	var city: Array = []
	for z in range(24, 39, 2):
		for x in range(24, 39, 2):
			var c := _post(x, z)
			city.append({"x": c.x, "z": c.y})
	var blocks := func(x: int, z: int) -> float: return 30.0 + 2.5 * sin(float(x) * 1.1) * cos(float(z) * 1.3) + (4.0 if x < 3 and z < 3 else 0.0)
	var urb := _surface(blocks)
	var urb_before := urb.duplicate()
	UrbanSmooth.apply(urb, SIZE, step, SIZE * 0.5, city)
	var mound := func(s: PackedFloat32Array) -> float:
		var lo := INF
		var hi := -INF
		for z in range(26, 37):
			for x in range(26, 37):
				lo = minf(lo, s[z * SIZE + x])
				hi = maxf(hi, s[z * SIZE + x])
		return hi - lo
	_check(float(mound.call(urb)) < 0.4 * float(mound.call(urb_before)),
		"urban smoothing levels block mounds (%.2f m from %.2f m)" % [mound.call(urb), mound.call(urb_before)])
	_check(is_equal_approx(urb[0], urb_before[0]), "ground far from the city is untouched")
	var urb_moved := 0.0
	for i in urb.size():
		urb_moved = maxf(urb_moved, absf(urb[i] - urb_before[i]))
	_check(urb_moved <= UrbanSmooth.MAX_SHIFT_M + 1e-4, "urban smoothing respects its cap (%.2f m)" % urb_moved)
	var city_hill := _surface(func(x: int, _z: int) -> float: return 20.0 + 0.5 * float(x))
	var hill_before := city_hill.duplicate()
	UrbanSmooth.apply(city_hill, SIZE, step, SIZE * 0.5, city)
	_check(absf(city_hill[31 * SIZE + 31] - hill_before[31 * SIZE + 31]) < 0.05,
		"a city on an even slope keeps it")
	# Water-carved posts are never moved.
	var wet := _dry()
	wet[20 * SIZE + 20] = 29.0
	var w := _surface(bumpy)
	var w_before := w.duplicate()
	RoadGrading.grade_areas(w, wet, SIZE, step, [_square(14, 26)])
	_check(is_equal_approx(w[20 * SIZE + 20], w_before[20 * SIZE + 20]), "a water-carved post is left alone")
	# Paved waterfront cycleways are graded smooth without pulling down into
	# adjacent carved waterbed posts, while unpaved park footways stay ungraded.
	var shore_lvl := _dry()
	for x in SIZE:
		shore_lvl[21 * SIZE + x] = 28.0
	var shore_surf := _surface(func(x: int, z: int) -> float:
		return 10.0 if z == 21 else 30.0 + 0.9 * sin(float(x) * 1.4))
	var shore_before := shore_surf.duplicate()
	var cycleway := {"class": "cycleway", "surface": "asphalt", "width_m": 3.5,
		"points": PackedVector2Array([_post(2, 20) + Vector2(0.0, step * 0.4),
			_post(38, 20) + Vector2(0.0, step * 0.4)])}
	var dirt_path := {"class": "footway", "surface": "dirt", "width_m": 2.0,
		"points": PackedVector2Array([_post(2, 8), _post(38, 8)])}
	RoadGrading.grade(shore_surf, shore_lvl, SIZE, step, [cycleway, dirt_path], m)
	var cyc_lo := INF
	var cyc_hi := -INF
	for x in range(8, 33):
		cyc_lo = minf(cyc_lo, shore_surf[20 * SIZE + x])
		cyc_hi = maxf(cyc_hi, shore_surf[20 * SIZE + x])
	_check(cyc_lo > 29.5 and cyc_hi - cyc_lo < 0.5,
		"paved waterfront cycleway smooths mounds without dipping into carved water (%.2f..%.2f)" % [cyc_lo, cyc_hi])
	_check(is_equal_approx(shore_surf[8 * SIZE + 15], shore_before[8 * SIZE + 15]),
		"unpaved dirt footway stays ungraded")
