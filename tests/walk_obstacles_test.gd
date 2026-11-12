extends SceneTree

## Walking into objects: godot --headless --script tests/walk_obstacles_test.gd
## Buildings were already solid; a walker must also not pass through
## parked cars, tree trunks, street furniture or a tram standing on its
## track. The solid shapes are static so the maths is driven here, then
## a real View360 walks at a trunk and is stopped by it.

const CACHE := "user://walk_obstacles_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	CacheStore.dir_override = CACHE
	PlaceThumb.dir_override = CACHE + "/thumbs"
	WorldCache.dir_override = CACHE + "/worlds"
	DirAccess.make_dir_recursive_absolute(CACHE)
	_maths()
	await _walking()
	_clean(CACHE)
	CacheStore.dir_override = ""
	PlaceThumb.dir_override = ""
	WorldCache.dir_override = ""
	if failures.is_empty():
		print("walk_obstacles_test: PASS")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)

static func _clean(dir_path: String) -> void:
	for f in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_clean(dir_path.path_join(d))
	DirAccess.remove_absolute(dir_path)

func _flat(lat: float, lon: float, name: String) -> LocationData:
	var flat := LocationData.new()
	flat.grid_size = 8
	flat.heights.resize(64)
	for i in 64:
		flat.heights[i] = 3.0
	flat.place_name = name
	flat.latitude = lat
	flat.longitude = lon
	return flat

func _maths() -> void:
	# A parked car across the path (4.6 m long, 1.8 m wide, facing east).
	var car := ViewWalk.rect_solid(Vector2(0, -10), Vector2(1, 0), 4.6, 1.8, "car")
	_check(ViewWalk.blocked([car], Vector2(0, -10)), "inside a parked car is blocked")
	_check(ViewWalk.blocked([car], Vector2(0, -8.8)), "brushing a car is blocked")
	_check(not ViewWalk.blocked([car], Vector2(0, -7.0)), "the road beside a car is open")
	_check(not ViewWalk.blocked([car], Vector2(4.0, -10)), "past the car's nose is open")
	var stopped := ViewWalk.step([car], Vector2(0, -7.6), Vector2(0, -8.8))
	_check(stopped.distance_to(Vector2(0, -10)) > 2.0, "walking straight at a car stops short: %s" % stopped)
	var slid := ViewWalk.step([car], Vector2(-1.0, -7.6), Vector2(-0.4, -8.6))
	_check(slid.x > -1.0 and not ViewWalk.blocked([car], slid), "walking at an angle slides along the car: %s" % slid)

	# A tree trunk: small, but not walk-through.
	var trunk := ViewWalk.point_solid(5.0, -20.0, ViewWalk.TREE_M, "tree")
	_check(ViewWalk.blocked([trunk], Vector2(5, -20)), "a tree trunk is blocked")
	_check(not ViewWalk.blocked([trunk], Vector2(7, -20)), "beside the trunk is open")

	# A set-down spot inside a car moves to open ground.
	var out := ViewWalk.free_spot([car], Vector2(0, -10))
	_check(not ViewWalk.blocked([car], out) and out.distance_to(Vector2(0, -10)) < 6.0,
		"a set-down inside a car finds the road beside it: %s" % out)

	# Static solids gathered from a place's data: mapped trees and
	# furniture are there without any buildings at all.
	var data := _flat(60.0, 25.0, "Solids")
	data.trees = [{"x": 0.0, "z": -620.0}]
	data.street_furniture = [{"x": 3.0, "z": -620.0, "kind": "bench"}]
	var ground := GroundTruth.new(data)
	var solids := ViewWalk.static_solids(data, ground)
	_check(solids.size() == 2, "trees and furniture become solids: %d" % solids.size())
	_check(ViewWalk.blocked(solids, Vector2(0, -620)), "the gathered trunk blocks")
	_check(ViewWalk.blocked(solids, Vector2(3, -620)), "the gathered bench blocks")

	# Parked cars: on Ultra, the same plan the world is built from.
	var street := _flat(60.0, 25.0, "Street")
	street.quality_preset = RenderSettings.Preset.ULTRA
	street.roads = [{"points": PackedVector2Array([Vector2(-200, -100), Vector2(200, -100)]),
		"width_m": 8.0, "class": "residential", "parking": 3}]
	var street_ground := GroundTruth.new(street)
	var with_cars := ViewWalk.static_solids(street, street_ground)
	var cars_only: Array = with_cars.filter(func(s: Dictionary) -> bool: return str(s.get("kind", "")) == "car")
	_check(not cars_only.is_empty(), "an Ultra street parks solid cars: %d" % cars_only.size())
	if not cars_only.is_empty():
		var c0: Dictionary = cars_only[0]
		_check(ViewWalk.blocked(cars_only, Vector2(float(c0["x"]), float(c0["z"]))),
			"a parked car's centre is blocked")

	# Gates, rails and walls: a mapped barrier line is solid along it.
	var fenced := _flat(60.0, 25.0, "Fenced")
	fenced.barriers = [{"points": PackedVector2Array([Vector2(-20, -30), Vector2(20, -30)]),
		"class": "fence"}]
	var fenced_ground := GroundTruth.new(fenced)
	var fence_solids := ViewWalk.static_solids(fenced, fenced_ground)
	_check(ViewWalk.blocked(fence_solids, Vector2(0, -30)), "a fence line blocks")
	_check(not ViewWalk.blocked(fence_solids, Vector2(0, -25)), "beside the fence is open")
	_check(ViewWalk.blocked(fence_solids, Vector2(21, -30)) == false, "past the fence end is open")

	# Water: a step into deep water is refused or slides along the shore.
	var pond := _flat(60.0, 25.0, "Pond")
	pond.land_polygons = [{"class": "water", "points": PackedVector2Array([
		Vector2(-10, -60), Vector2(10, -60), Vector2(10, -40), Vector2(-10, -40)])}]
	var pond_ground := GroundTruth.new(pond)
	_check(pond_ground.water_at(0, -50) > ViewWalk.DRY_M, "the pond is deep water: %.2f" % pond_ground.water_at(0, -50))
	_check(ViewWalk.dry_step(pond_ground, Vector2(0, -35), Vector2(0, -45)) == Vector2(0, -35),
		"walking into the pond stays on shore")
	_check(ViewWalk.dry_step(pond_ground, Vector2(0, -50), Vector2(0, -35)) == Vector2(0, -35),
		"a walker already in the water can walk out")

	# Tunnels: the corridor under a building is walkable along it.
	var under := _flat(60.0, 25.0, "Under")
	under.roads = [{"points": PackedVector2Array([Vector2(0, -80), Vector2(0, 80)]),
		"width_m": 7.0, "class": "primary", "tunnel": true}]
	_check(ViewWalk.in_tunnel(under, Vector2(1, 0)), "on the tunnel road is in the tunnel")
	_check(not ViewWalk.in_tunnel(under, Vector2(30, 0)), "beside it is not")

	# Seoul's gate: Gwanghwamun's piers are solid, its arches are open.
	var seoul := _flat(37.575928, 126.976817, "Seoul")
	seoul.landmark_type = "gwanghwamun"
	seoul.has_landmark_site = true
	seoul.landmark_lat = seoul.latitude
	seoul.landmark_lon = seoul.longitude
	var seoul_ground := GroundTruth.new(seoul)
	var gate_solids := ViewWalk.static_solids(seoul, seoul_ground)
	_check(not gate_solids.is_empty(), "the gate contributes solids")
	_check(ViewWalk.blocked(gate_solids, Vector2(-14, 0)), "a gate pier blocks: %s" % [gate_solids])
	_check(not ViewWalk.blocked(gate_solids, Vector2(0, 0)), "the centre arch is walk-through")
	_check(not ViewWalk.blocked(gate_solids, Vector2(-9, 0)), "a side arch is walk-through")
	_check(not ViewWalk.blocked(gate_solids, Vector2(0, 20)), "the plaza south of the gate is open")

func _walking() -> void:
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280, 800)
	await process_frame
	view._wiki.offline_mode = true
	if view._horizon != null and view._horizon._fetcher != null:
		view._horizon._fetcher.offline_mode = true
	view._weather.queue_free()
	view._weather = null
	var data := _flat(60.4518, 22.2666, "Testville")
	data.trees = [{"x": 0.0, "z": -500.0}]
	view.show_location(data)
	await process_frame

	# Walk north into the trunk at (0, -620): never through it.
	view._rig.position = Vector3(0, ViewWalk.foot_y(data, view._ground, Vector2(0, -494)), -494)
	view._rig.set_look(0.0, 0.0)
	var north_key := InputEventKey.new()
	north_key.keycode = KEY_W
	north_key.pressed = true
	Input.parse_input_event(north_key)
	Input.flush_buffered_events()
	for i in 30:
		view._walk.process_keys(view, 0.25)
	var release_north := InputEventKey.new()
	release_north.keycode = KEY_W
	Input.parse_input_event(release_north)
	Input.flush_buffered_events()
	var walked := Vector2(view._rig.position.x, view._rig.position.z)
	_check(walked.distance_to(Vector2(0, -500)) > 0.8,
		"the walker stops at the trunk, not inside it: %s" % walked)
	_check(walked.y < -496.0, "and did walk up to it: %s" % walked)

	# A tram on its route is a long solid across the walker's ground.
	var route := TramRoute.new()
	route.points = PackedVector2Array([Vector2(-50, -630), Vector2(50, -630)])
	route.cum = PackedFloat32Array([0.0, 100.0])
	route.length_m = 100.0
	var mover := VehicleMover.new()
	mover._trains = [{"route": route, "s": 50.0, "length": 30.0}]
	var tram_solids: Array = mover.walker_solids()
	_check(tram_solids.size() == 1 and ViewWalk.blocked(tram_solids, Vector2(0, -630)),
		"a standing tram blocks its track")
	_check(not ViewWalk.blocked(tram_solids, Vector2(0, -620)),
		"beside the tram is open")
	view.queue_free()
	await process_frame
