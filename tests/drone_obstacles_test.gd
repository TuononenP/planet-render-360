extends SceneTree

## Drone ground landing & 3D obstacle collision:
##   tools/godot_bg.sh --headless --script tests/drone_obstacles_test.gd
## Verifies that the drone can descend and land all the way to the ground
## (even in narrow streets beside tall towers and inside courtyards), while
## never passing through terrain, water, buildings, overhangs, landmarks,
## statues, parked cars, moving trams/boats/aircraft, ships, barriers,
## street furniture or tree trunks.

const CACHE := "user://drone_obstacles_test_cache"

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
	await _live_flight()
	_clean(CACHE)
	CacheStore.dir_override = ""
	PlaceThumb.dir_override = ""
	WorldCache.dir_override = ""
	if failures.is_empty():
		print("drone_obstacles_test: PASS")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)

static func _clean(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for f in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_clean(dir_path.path_join(d))
	DirAccess.remove_absolute(dir_path)

func _flat(lat: float, lon: float, name: String) -> LocationData:
	var flat := LocationData.new()
	flat.grid_size = 16
	flat.heights.resize(256)
	for i in 256:
		flat.heights[i] = 4.0
	flat.place_name = name
	flat.latitude = lat
	flat.longitude = lon
	return flat

func _maths() -> void:
	var r := DroneObstacles.RADIUS_M
	_check(r <= 0.6 and r >= 0.4, "minimum drone clearance allows ground landing outside near plane: %.2f" % r)

	# 1. Terrain slope & water surface.
	var hilly := LocationData.new()
	hilly.grid_size = 16
	hilly.heights.resize(256)
	for z in 16:
		for x in 16:
			hilly.heights[z * 16 + x] = float(16 - z) * 6.0
	hilly.latitude = 60.0
	hilly.longitude = 25.0
	var hilly_ground := GroundTruth.new(hilly)
	var hilly_obs := DroneObstacles.from_data(hilly, hilly_ground)
	var low_start := Vector3(0, hilly_ground.height_at_world(0, 200) + r, 200)
	var into_hill := hilly_obs.sweep_standalone(low_start, Vector3(0, low_start.y, -200))
	var hill_pos: Vector3 = into_hill["pos"]
	_check(hill_pos.y >= hilly_ground.height_at_world(hill_pos.x, hill_pos.z) + r - 0.01,
		"sweeping into rising terrain never goes underground: %s" % hill_pos)

	var lake := _flat(60.0, 25.0, "Lake")
	lake.land_polygons = [{"class": "water", "points": PackedVector2Array([
		Vector2(-40, -80), Vector2(40, -80), Vector2(40, -20), Vector2(-40, -20)])}]
	var lake_ground := GroundTruth.new(lake)
	var lake_obs := DroneObstacles.from_data(lake, lake_ground)
	var water_surf := DroneObstacles.surface_y(lake, lake_ground, Vector2(0, -50))
	var dive := lake_obs.sweep_standalone(Vector3(0, water_surf + 5.0, -50), Vector3(0, water_surf - 5.0, -50))
	_check((dive["pos"] as Vector3).y >= water_surf + r - 0.01,
		"drone never dives below a water surface: %s vs %.2f" % [dive["pos"], water_surf])

	# 2. Buildings: wall block, angled slide, roof landing, courtyard & skybridge overhang.
	var city := _flat(60.0, 25.0, "City")
	var gy := GroundTruth.new(city).height_at_world(0, 0)
	# Courtyard block at z = -60..-20, x = -20..20, with open inner yard -10..10 x -50..-30.
	city.buildings = [
		{
			"x": 0.0, "z": -40.0, "height": 30.0,
			"footprint": PackedVector2Array([
				Vector2(-20, -60), Vector2(20, -60), Vector2(20, -20), Vector2(-20, -20)]),
			"holes": [PackedVector2Array([
				Vector2(-10, -50), Vector2(10, -50), Vector2(10, -30), Vector2(-10, -30)])],
		},
		# Skybridge / overhang spanning x = 30..50, z = -45..-35, raised 10..18 m above ground.
		{
			"x": 40.0, "z": -40.0, "height": 18.0, "min_height_m": 10.0,
			"footprint": PackedVector2Array([
				Vector2(30, -45), Vector2(50, -45), Vector2(50, -35), Vector2(30, -35)]),
		},
		# Mapped equestrian statue at (-35, -40).
		{
			"x": -35.0, "z": -40.0, "statue": "equestrian",
			"footprint": PackedVector2Array([
				Vector2(-37, -41.5), Vector2(-33, -41.5), Vector2(-33, -38.5), Vector2(-37, -38.5)]),
		},
		# Mapped ship on water/harbour at (80, -40).
		{
			"x": 80.0, "z": -40.0, "kind": "ship", "height": 14.0, "height_source": "tag_height",
			"footprint": PackedVector2Array([
				Vector2(65, -44), Vector2(95, -44), Vector2(95, -36), Vector2(65, -36)]),
		},
	]
	city.quality_preset = RenderSettings.Preset.ULTRA
	city.roads = [{"points": PackedVector2Array([Vector2(-120, 30), Vector2(120, 30)]),
		"width_m": 9.0, "class": "residential", "parking": 3}]
	city.barriers = [{"points": PackedVector2Array([Vector2(-20, 60), Vector2(20, 60)]), "class": "wall"}]
	city.trees = [{"x": -55.0, "z": -40.0, "height": 9.0}]
	city.street_furniture = [{"x": -65.0, "z": -40.0, "kind": "bus_stop", "shelter": true}]
	var city_ground := GroundTruth.new(city)
	var obs := DroneObstacles.from_data(city, city_ground)

	# Street right beside the 30 m building (2 m south of z = -20): floor is ground, NOT roof!
	_check(absf(ViewDrone.floor_y(city.buildings, city_ground, Vector2(0, -18)) - (gy + r)) < 0.05,
		"street right beside a 30 m building allows landing to ground")
	# Inside the courtyard (0, -40): floor is ground, NOT roof!
	_check(absf(ViewDrone.floor_y(city.buildings, city_ground, Vector2(0, -40)) - (gy + r)) < 0.05,
		"open courtyard inside a building allows landing to ground")
	# Over the wall mass itself (0, -25): floor is the 30 m roof.
	_check(ViewDrone.floor_y(city.buildings, city_ground, Vector2(0, -25)) >= gy + 30.0 + r - 0.05,
		"over the building ring the floor clears its 30 m roof")

	# Fast boosted sweep (10 m in one frame!) straight at the south wall at z = -20 stops outside.
	var wall_hit := obs.sweep_standalone(Vector3(0, gy + 2.0, -15), Vector3(0, gy + 2.0, -25))
	var wp: Vector3 = wall_hit["pos"]
	_check(wp.z >= -20.0 + r - 0.02 and bool(wall_hit["hit_wall"]),
		"fast sweep into building wall stops outside without tunneling: %s" % wp)

	# Angled sweep slides along the south wall.
	var wall_slide := obs.sweep_standalone(Vector3(-5, gy + 2.0, -19.2), Vector3(0, gy + 2.0, -21.0))
	var sp: Vector3 = wall_slide["pos"]
	_check(sp.x > -4.0 and sp.z >= -20.0 + r - 0.02,
		"angled sweep slides along the building wall: %s" % sp)

	# Descending onto the building roof stops on top of the roof.
	var roof_land := obs.sweep_standalone(Vector3(0, gy + 35.0, -25), Vector3(0, gy + 20.0, -25))
	_check(absf((roof_land["pos"] as Vector3).y - (gy + 30.0 + r)) < 0.05 and bool(roof_land["hit_floor"]),
		"descending onto a roof lands on top of it: %s" % roof_land["pos"])

	# Inside the courtyard: inner wall at z = -30 stops horizontal flight out through the building.
	var yard_wall := obs.sweep_standalone(Vector3(0, gy + 1.5, -35), Vector3(0, gy + 1.5, -26))
	_check((yard_wall["pos"] as Vector3).z <= -30.0 - r + 0.02,
		"courtyard inner wall stops drone from flying into the building: %s" % yard_wall["pos"])

	# Skybridge overhang (min_height_m = 10, height = 18): open underneath, solid above 10 m.
	var under_pass := obs.sweep_standalone(Vector3(40, gy + 3.0, -30), Vector3(40, gy + 3.0, -50))
	_check(absf((under_pass["pos"] as Vector3).z - (-50.0)) < 0.05,
		"drone flies freely underneath a raised skybridge overhang: %s" % under_pass["pos"])
	var climb_into_overhang := obs.sweep_standalone(Vector3(40, gy + 6.0, -40), Vector3(40, gy + 14.0, -40))
	_check((climb_into_overhang["pos"] as Vector3).y <= gy + 10.0 - r + 0.05 and bool(climb_into_overhang["hit_ceil"]),
		"climbing beneath an overhang stops at its underside: %s" % climb_into_overhang["pos"])

	# 3. Statue: blocks horizontally at pedestal & rider height, stops descent from above, open beside.
	var statue_hit_low := obs.sweep_standalone(Vector3(-35, gy + 1.5, -35), Vector3(-35, gy + 1.5, -40))
	_check((statue_hit_low["pos"] as Vector3).z > -38.5,
		"statue pedestal blocks horizontal flight: %s" % statue_hit_low["pos"])
	var statue_hit_rider := obs.sweep_standalone(Vector3(-35, gy + 5.0, -35), Vector3(-35, gy + 5.0, -40))
	_check((statue_hit_rider["pos"] as Vector3).z > -38.5,
		"statue bronze figure blocks horizontal flight: %s" % statue_hit_rider["pos"])
	var statue_beside := obs.sweep_standalone(Vector3(-30, gy + 5.0, -40), Vector3(-30, gy + r, -40))
	_check(absf((statue_beside["pos"] as Vector3).y - (gy + r)) < 0.05,
		"ground right beside a statue is open for landing: %s" % statue_beside["pos"])

	# 4. Ship, parked cars, wall barrier, bus shelter & tree trunk.
	var ship_hit := obs.sweep_standalone(Vector3(80, gy + 4.0, -30), Vector3(80, gy + 4.0, -40))
	_check((ship_hit["pos"] as Vector3).z > -36.0,
		"mapped ship hull/superstructure blocks horizontal flight: %s" % ship_hit["pos"])

	var cars := ParkedCars.plan(city, city_ground, WorldScale.metres_to_units())
	_check(not cars.is_empty(), "test street has parked cars")
	if not cars.is_empty():
		var cpos: Vector3 = cars[0][0]
		var car_hit := obs.sweep_standalone(cpos + Vector3(0, 0.8, 4.0), cpos + Vector3(0, 0.8, 0.0))
		_check((car_hit["pos"] as Vector3).distance_to(cpos + Vector3(0, 0.8, 0.0)) > 0.9,
			"parked car blocks low drone flight: %s -> %s" % [cpos, car_hit["pos"]])
		var car_over := obs.sweep_standalone(cpos + Vector3(0, 3.2, 4.0), cpos + Vector3(0, 3.2, -4.0))
		_check(absf((car_over["pos"] as Vector3).z - (cpos.z - 4.0)) < 0.05,
			"drone flies cleanly above a parked car: %s" % car_over["pos"])

	var wall_br := obs.sweep_standalone(Vector3(0, gy + 1.0, 56), Vector3(0, gy + 1.0, 64))
	_check((wall_br["pos"] as Vector3).z < 60.0,
		"mapped stone wall barrier blocks low flight: %s" % wall_br["pos"])

	var shelter_hit := obs.sweep_standalone(Vector3(-65, gy + 1.2, -36), Vector3(-65, gy + 1.2, -40))
	_check((shelter_hit["pos"] as Vector3).z > -39.0,
		"bus shelter blocks low flight: %s" % shelter_hit["pos"])

	var trunk_hit := obs.sweep_standalone(Vector3(-55, gy + 1.2, -37), Vector3(-55, gy + 1.2, -40))
	_check((trunk_hit["pos"] as Vector3).z > -39.6,
		"tree trunk blocks low flight: %s" % trunk_hit["pos"])
	var under_canopy := obs.sweep_standalone(Vector3(-53.8, gy + 1.2, -37), Vector3(-53.8, gy + 1.2, -43))
	_check(absf((under_canopy["pos"] as Vector3).z - (-43.0)) < 0.05,
		"space under tree branches beside the trunk stays open: %s" % under_canopy["pos"])

	# 5. Review regressions: level-only building height, open-water skip, and _mesh_grids cleanup.
	var lv_data := _flat(60.0, 25.0, "Levels")
	lv_data.buildings = [{"x": 0.0, "z": -30.0, "levels": 6, "footprint": PackedVector2Array([
		Vector2(-10, -35), Vector2(10, -35), Vector2(10, -25), Vector2(-10, -25)])}]
	var lv_ground := GroundTruth.new(lv_data)
	var lv_gy := lv_ground.height_at_world(0, -30)
	var lv_obs := DroneObstacles.from_data(lv_data, lv_ground)
	var lv_hit := lv_obs.sweep_standalone(Vector3(0, lv_gy + 15.0, -20), Vector3(0, lv_gy + 15.0, -30))
	_check((lv_hit["pos"] as Vector3).z >= -25.0 + r - 0.02,
		"level-only 6-storey building blocks at upper floor height: %s" % lv_hit["pos"])
	_check(ViewDrone.floor_y(lv_data.buildings, lv_ground, Vector2(0, -30)) >= lv_gy + 19.8 + r - 0.05,
		"level-only 6-storey building floor clears inferred roof")

	var wet_bldg := _flat(60.0, 25.0, "Canal")
	wet_bldg.land_polygons = [{"class": "water", "points": PackedVector2Array([
		Vector2(-40, -80), Vector2(40, -80), Vector2(40, -20), Vector2(-40, -20)])}]
	wet_bldg.buildings = [{"x": 0.0, "z": -50.0, "size_x": 10.0, "size_z": 10.0, "height": 12.0,
		"footprint": PackedVector2Array([Vector2(-5, -55), Vector2(5, -55), Vector2(5, -45), Vector2(-5, -45)])}]
	var wet_ground := GroundTruth.new(wet_bldg)
	var dummy_w1 := Node3D.new()
	var dummy_w2 := Node3D.new()
	var wet_obs := DroneObstacles.from_data(wet_bldg, wet_ground, dummy_w1)
	var wet_surf := DroneObstacles.surface_y(wet_bldg, wet_ground, Vector2(0, -50))
	var over_canal := wet_obs.sweep_standalone(Vector3(0, wet_surf + 3.0, -40), Vector3(0, wet_surf + 3.0, -60))
	_check(absf((over_canal["pos"] as Vector3).z - (-60.0)) < 0.05,
		"skipped open-water building leaves no phantom obstacle over canal: %s" % over_canal["pos"])
	wet_obs._mesh_grids[12345] = {"verts": PackedVector3Array(), "cells": {}}
	wet_obs._rebuild(wet_bldg, wet_ground, dummy_w2, null)
	_check(wet_obs._mesh_grids.is_empty(), "_rebuild clears stale _mesh_grids on world change")
	dummy_w1.free()
	dummy_w2.free()

func _live_flight() -> void:
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

	# Build a scene with a hero landmark gate (Gwanghwamun: real 3D mesh with
	# stone piers, open centre arch and gate roof) plus two 50 m street-wall
	# buildings flanking a narrow 14 m canyon street, a moving tram and a helicopter.
	var data := _flat(37.575928, 126.976817, "Seoul Gate")
	data.landmark_type = "gwanghwamun"
	data.has_landmark_site = true
	data.landmark_lat = data.latitude
	data.landmark_lon = data.longitude
	data.buildings = [
		{"x": -15.0, "z": 120.0, "height": 50.0, "footprint": PackedVector2Array([
			Vector2(-23, 100), Vector2(-7, 100), Vector2(-7, 140), Vector2(-23, 140)])},
		{"x": 15.0, "z": 120.0, "height": 50.0, "footprint": PackedVector2Array([
			Vector2(7, 100), Vector2(23, 100), Vector2(23, 140), Vector2(7, 140)])},
	]
	view.show_location(data)
	await process_frame
	await process_frame

	var gy := view._ground.height_at_world(0, 120)
	var dt := 1.0 / 30.0
	view._drone.enter(view)

	# 1. Land between two 50 m buildings on the 14 m street (x = 0, z = 120).
	view._rig.position = Vector3(0, gy + 25.0, 120)
	view._drone._agl = 25.0
	view._drone.stick_aux = Vector2(0, 1)
	for i in 30 * 6:
		view._drone.process(view, dt)
	view._drone.stick_aux = Vector2.ZERO
	var street_agl := view._rig.position.y - gy
	_check(street_agl <= ViewDrone.AGL_MIN_M + 0.08 and street_agl >= ViewDrone.AGL_MIN_M - 0.02,
		"drone lands all the way to the street between 50 m towers: %.2f m" % street_agl)
	# Hover bob settles to zero while landed on the street.
	var y_settled := view._rig.position.y
	for i in 45:
		view._drone.process(view, dt)
	_check(absf(view._rig.position.y - y_settled) < 0.02,
		"landed drone rests steady on the ground without bobbing: %.3f -> %.3f" % [y_settled, view._rig.position.y])
	# Taking off again with E / climb stick lifts smoothly off the street.
	view._drone.stick_aux = Vector2(0, -1)
	for i in 30:
		view._drone.process(view, dt)
	view._drone.stick_aux = Vector2.ZERO
	_check(view._rig.position.y - gy > 4.0,
		"climb lifts the drone cleanly back off the ground: %.2f m" % (view._rig.position.y - gy))

	# 2. Real 3D landmark mesh (Gwanghwamun at origin): pier blocks, arch passes, arch roof blocks climb.
	var g0 := view._ground.height_at_world(0, 0)
	view._rig.set_look(0.0, 0.0)
	view._rig.position = Vector3(-14.0, g0 + 2.2, 16.0)
	view._drone._agl = 2.2
	view._drone._vel = Vector2.ZERO
	view._drone.stick_move = Vector2(0, -1)
	for i in 60:
		view._drone.process(view, dt)
	view._drone.stick_move = Vector2.ZERO
	_check(view._rig.position.z > 4.0,
		"real 3D landmark stone pier blocks the drone: %s" % view._rig.position)

	# Fly through the centre arch at (x = 0, y = g0 + 2.0) from z = 14 past z = -8.
	view._rig.position = Vector3(0.0, g0 + 2.0, 14.0)
	view._drone._agl = 2.0
	view._drone._vel = Vector2.ZERO
	view._drone.stick_move = Vector2(0, -1)
	for i in 105:
		view._drone.process(view, dt)
	view._drone.stick_move = Vector2.ZERO
	_check(view._rig.position.z < -8.0,
		"open 3D landmark arch allows low drone flight through it: %s" % view._rig.position)

	# Inside the centre arch (0, 0), climbing stops at the arch ceiling instead of passing through the roof.
	view._rig.position = Vector3(0.0, g0 + 2.0, 0.0)
	view._drone._agl = 2.0
	view._drone._vel = Vector2.ZERO
	view._drone.stick_aux = Vector2(0, -1)
	for i in 90:
		view._drone.process(view, dt)
	view._drone.stick_aux = Vector2.ZERO
	_check(view._rig.position.y < g0 + 10.0,
		"arch ceiling stops the drone from climbing through the gate roof: %.2f" % (view._rig.position.y - g0))

	# 3. Live moving tram (VehicleMover): blocks flight AND pushes a low-hovering drone clear as it passes.
	var route := TramRoute.new()
	route.points = PackedVector2Array([Vector2(-40, 180), Vector2(40, 180)])
	route.cum = PackedFloat32Array([0.0, 80.0])
	route.length_m = 80.0
	var mover := VehicleMover.new()
	mover._trains = [{"route": route, "s": 20.0, "length": 24.0, "hidden": false}]
	view._mover = mover
	# Hover low on the track ahead of the tram at x = 0, z = 180 while the tram advances into it.
	var gt := view._ground.height_at_world(0, 180)
	view._rig.position = Vector3(0.0, gt + 1.5, 180.0)
	view._drone._agl = 1.5
	view._drone._vel = Vector2.ZERO
	for step in 40:
		mover._trains[0]["s"] = 20.0 + float(step) * 0.6
		view._drone.process(view, dt)
		var tram_x := float(mover._trains[0]["s"]) - 40.0
		var inside_tram := absf(view._rig.position.x - tram_x) < 12.0 \
			and absf(view._rig.position.z - 180.0) < 1.4 \
			and view._rig.position.y < gt + 3.8
		_check(not inside_tram, "moving tram never overlaps the hovering drone at step %d: %s" % [step, view._rig.position])
	view._mover = null

	# 4. Live aircraft/helicopter (AircraftDriver): blocks low drone flight on the pad.
	var air_holder := Node3D.new()
	air_holder.name = "AirTraffic"
	var air_drv := AircraftDriver.new()
	air_drv.name = "AircraftDriver"
	air_drv.flights = [{
		"id": 1, "kind": "helicopter", "mode": "helicopter",
		"pad_pos": Vector3(60.0, gy, 180.0), "heading": 0.0, "out_dir": Vector2(0.0, -1.0),
	}]
	air_holder.add_child(air_drv)
	view._generated.add_child(air_holder)
	air_drv.advance(0.0)
	view._drone._obstacles.invalidate()
	view._rig.position = Vector3(60.0, gy + 1.8, 192.0)
	view._drone._agl = 1.8
	view._drone._vel = Vector2.ZERO
	view._rig.set_look(0.0, 0.0)
	view._drone.stick_move = Vector2(0, -1)
	for i in 45:
		view._drone.process(view, dt)
	view._drone.stick_move = Vector2.ZERO
	# Helicopter at z = 180 facing +X has fuselage half-width 1.6 m + 0.5 m drone radius = 182.1 m.
	_check(view._rig.position.z >= 182.0,
		"helicopter on pad blocks low drone flight: %s" % view._rig.position)

	view.queue_free()
	await process_frame
