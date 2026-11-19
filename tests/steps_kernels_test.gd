extends SceneTree

## Native stairs ground: godot --headless --path . --script tests/steps_kernels_test.gd
## StepsGround through StepsKernels (native/, tools/build_native.sh) must
## hold the ground to exactly what the script does: random hilly grids with
## water posts, flights (ways and areas) with parks, squares and buildings
## (some corners on the post lattice, some with courtyards) at their feet and
## terraces at their tops, streets and bridges touching their ends. Surface and flights are compared byte for byte, and
## the ways touching a flight's ends one by one. Skips, passing, when the
## library is not built.

const SIZE := 129
const STEP_M := 2.0
const CASES := 24

var _fails := 0
var _levelled := 0
var _flights := 0

func _init() -> void:
	if not ClassDB.class_exists("StepsKernels"):
		print("STEPS_KERNELS SKIP: StepsKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for t in CASES:
		_case(t, rng)
	StepsGround._native = true
	_check(_levelled >= 6, "the parks were levelled in %d cases, want at least 6" % _levelled)
	_check(_flights >= 40, "%d flights kept in all, want at least 40" % _flights)
	if _fails == 0:
		print("STEPS_KERNELS PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("STEPS_KERNELS FAIL: ", what)

## A closed outline round `c`, `n` corners, radius between 0.6 and 1 of `r`.
func _blob(rng: RandomNumberGenerator, c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a0 := rng.randf() * TAU
	for k in n:
		var a := a0 + TAU * float(k) / float(n)
		out.append(c + Vector2(cos(a), sin(a)) * r * rng.randf_range(0.6, 1.0))
	return out

## An axis-aligned box with its corners on the post lattice (odd metres).
func _lattice_box(rng: RandomNumberGenerator, c: Vector2, half: int) -> PackedVector2Array:
	var cx := int(c.x) | 1
	var cz := int(c.y) | 1
	var w := rng.randi_range(1, half) * 2
	var h := rng.randi_range(1, half) * 2
	return PackedVector2Array([Vector2(cx, cz), Vector2(cx + w, cz), Vector2(cx + w, cz + h), Vector2(cx, cz + h)])

func _scaled(ring: PackedVector2Array, m: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in ring:
		out.append(p * m)
	return out

func _case(t: int, rng: RandomNumberGenerator) -> void:
	var m := WorldScale.metres_to_units()
	var step := STEP_M * m
	var dem := PackedFloat32Array()
	var level := PackedFloat32Array()
	var phase := rng.randf() * TAU
	for z in SIZE:
		for x in SIZE:
			var wx := (float(x) - float(SIZE) * 0.5) * STEP_M
			var wz := (float(z) - float(SIZE) * 0.5) * STEP_M
			dem.append(12.0 + 7.0 * sin(wx / 23.0 + phase) + 5.0 * cos(wz / 31.0) + 0.02 * wx)
			level.append(rng.randf_range(0.0, 6.0) if rng.randf() < 0.04 else -INF)
	var roads: Array = []
	var feet: Array = []
	for k in rng.randi_range(2, 6):
		var top := Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70))
		var run := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(5, 30)
		var count := rng.randi_range(4, 45) if rng.randf() < 0.85 else 0
		if rng.randf() < 0.2:
			roads.append({"class": "steps", "area": true, "bridge": false, "tunnel": false, "layer": 0,
				"points": _scaled(_blob(rng, top, rng.randf_range(4, 9), 6), m), "holes": [],
				"width_m": 4.0, "step_count": count, "incline": "", "handrail": false})
		else:
			roads.append({"class": "steps", "points": _scaled(PackedVector2Array([top, top + run]), m),
				"width_m": rng.randf_range(1.0, 3.0), "step_count": count,
				"incline": ["", "down", "up", ""][rng.randi_range(0, 3)], "handrail": rng.randf() < 0.5,
				"bridge": false, "tunnel": false, "layer": 0})
		feet.append(top + run)
		# The terrace a flight comes down from.
		if rng.randf() < 0.3:
			roads.append({"class": "pedestrian", "area": true, "bridge": false, "tunnel": false, "layer": 0,
				"points": _scaled(_blob(rng, top - run.normalized() * 6.0, 6.5, 6), m), "holes": [], "width_m": 0.0})
		# A street, a footway or a bridge touching an end.
		if rng.randf() < 0.7:
			var at := top if rng.randf() < 0.5 else top + run
			roads.append({"class": ["residential", "primary", "footway", "service", "motorway", "path"][rng.randi_range(0, 5)],
				"points": _scaled(PackedVector2Array([at + Vector2(rng.randf_range(-0.6, 0.6), 0.3), at + Vector2(25, 6)]), m),
				"width_m": 6.0, "bridge": rng.randf() < 0.1, "tunnel": rng.randf() < 0.05,
				"layer": 1 if rng.randf() < 0.05 else 0, "area": false})
	for k in rng.randi_range(5, 40):
		var a := Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))
		roads.append({"class": ["residential", "service", "pedestrian", "tertiary"][rng.randi_range(0, 3)],
			"points": _scaled(PackedVector2Array([a, a + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))]), m),
			"width_m": 5.0, "bridge": false, "tunnel": false, "layer": 0, "area": false})
	roads.append("not a road")
	var lands: Array = []
	var buildings: Array = []
	var parks: Array = []
	for foot: Vector2 in feet:
		var c := foot + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6))
		if rng.randf() < 0.8:
			var ring := _scaled(_blob(rng, c, rng.randf_range(8, 24), rng.randi_range(5, 9)), m)
			var holes: Array = []
			if rng.randf() < 0.4:
				holes.append(_scaled(_blob(rng, c, 3.0, 4), m))
			if rng.randf() < 0.5:
				lands.append({"class": "grass", "points": ring, "holes": holes})
			else:
				roads.append({"class": ["pedestrian", "footway"][rng.randi_range(0, 1)], "area": true,
					"bridge": false, "tunnel": false, "layer": 0, "points": ring, "holes": holes, "width_m": 0.0})
			parks.append(c)
		for b in rng.randi_range(2, 7):
			var at := c + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
			var fp := _lattice_box(rng, at, 5) if rng.randf() < 0.5 else _blob(rng, at, rng.randf_range(2, 7), rng.randi_range(4, 9))
			var ring := _scaled(fp, m)
			var mid := Vector2.ZERO
			for p in ring:
				mid += p
			mid /= float(ring.size())
			var yards: Array = []
			if rng.randf() < 0.3:
				yards.append(_scaled(_blob(rng, mid / m, 1.5, 5), m))
			buildings.append({"x": mid.x, "z": mid.y, "footprint": ring, "holes": yards})
	buildings.append({"x": 0.0, "z": 0.0})
	buildings.append("not a building")
	lands.append({"class": "wood", "points": _scaled(_blob(rng, Vector2.ZERO, 30.0, 6), m), "holes": []})
	var data := LocationData.new()
	data.roads = roads
	data.land_polygons = lands
	data.buildings = buildings

	var out := {}
	for native in [true, false]:
		StepsGround._native = native
		var surface := dem.duplicate()
		out[native] = [surface, StepsGround.apply(surface, level, SIZE, step, data, m)]
	_check(var_to_bytes(out[true][0]) == var_to_bytes(out[false][0]), "case %d: surfaces differ%s" % [t,
		_diff(out[true][0], out[false][0])])
	_check(var_to_bytes(out[true][1]) == var_to_bytes(out[false][1]), "case %d: flights differ" % t)
	_flights += (out[false][1] as Array).size()

	# Without its parks and squares the ground comes out different: they were levelled.
	var bare := LocationData.new()
	bare.roads = roads.filter(func(r: Variant) -> bool:
		return not (r is Dictionary and bool((r as Dictionary).get("area", false)) and str((r as Dictionary)["class"]) != "steps"))
	bare.buildings = buildings
	StepsGround._native = false
	var no_parks := dem.duplicate()
	StepsGround.apply(no_parks, level, SIZE, step, bare, m)
	if var_to_bytes(no_parks) != var_to_bytes(out[false][0]):
		_levelled += 1

	_touch_check(t, data, m)

## " (n posts; first at x,z: native a, script b)" for two surfaces.
func _diff(a: PackedFloat32Array, b: PackedFloat32Array) -> String:
	var n := 0
	var first := ""
	for i in a.size():
		if a[i] != b[i]:
			n += 1
			if first == "":
				first = "%d,%d: %s vs %s" % [i % SIZE, i / SIZE, a[i], b[i]]
	return " (%d posts; first at %s)" % [n, first] if n > 0 else ""

## Canonical form of a node dictionary: its sorted pairs.
func _pairs(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort()
	return keys.map(func(k: Variant) -> Array: return [k, d[k]])

## StepsGround._touch over the ends of the steps in `data`, both ways.
func _touch_check(t: int, data: LocationData, m: float) -> void:
	var nets := {}
	for native in [true, false]:
		var net := StepsGround._Net.new(m)
		for r: Variant in data.roads:
			if r is Dictionary and str((r as Dictionary).get("class", "")) == "steps":
				var pts: PackedVector2Array = (r as Dictionary)["points"]
				net.node(pts[0], StepsGround.MERGE_M * m)
				net.node(pts[pts.size() - 1], StepsGround.MERGE_M * m)
		StepsGround._native = native
		StepsGround._touch(data, net, m)
		nets[native] = net
	_check(_pairs(nets[true].bridged) == _pairs(nets[false].bridged), "case %d: bridged nodes differ" % t)
	_check(_pairs(nets[true].anchor_rank) == _pairs(nets[false].anchor_rank), "case %d: anchor ranks differ" % t)
