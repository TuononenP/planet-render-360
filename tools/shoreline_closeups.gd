extends "res://tools/shoreline_capture.gd"

## Inspection views of the nearest real bank, using the finalized full
## model. Only nearby buildings/roads are drawn; the opening views in
## shoreline_capture.gd retain the complete production world and camera.
func _capture(main: Node, view: View360, place: Dictionary, _times: PackedStringArray,
		_audit: bool, settle_s: float = SETTLE_S) -> void:
	var id := str(place["id"])
	var file := FileAccess.open(str(_args()["inputs"]).path_join(id + ".snap"), FileAccess.READ)
	var saved: Dictionary = file.get_var()
	file.close()
	var data := LocationData.new()
	for property in data.get_property_list():
		var key: String = property["name"]
		if saved.has(key):
			data.set(key, _thaw(saved[key], data.get(key)))
	view.set_quality_preset(data.quality_preset)
	var thread := Thread.new()
	thread.start(func() -> Array: return _local_world(data))
	while thread.is_alive():
		await process_frame
	var built: Array = thread.wait_to_finish()
	if built.is_empty():
		printerr("SHORE CLOSEUP missing bank ", id)
		return
	var segment: Dictionary = built.pop_back()
	_weather_in = false
	view.show_location(data, built)
	main._show(view)
	main._notice.visible = false
	view._governor.set_process(false)
	var start := Time.get_ticks_msec()
	while not _weather_in and Time.get_ticks_msec() - start < 5000:
		await process_frame
	view._atmos.set_weather(0, 15.0)
	ViewConditions._apply_precip(view, 0)
	ViewConditions.apply_surface_state(view)
	ViewConditions.spawn_golden_hour(view)
	var ground: GroundTruth = built[0]
	var mid: Vector2 = (segment["a"] + segment["b"]) * 0.5
	var land: Vector2 = segment["land"]
	var direction: Vector2 = (segment["b"] - segment["a"]).normalized()
	var eye := mid - land * 10.0 + direction * 4.0
	for distance in [10.0, 6.0, 3.0, 1.0, 0.25]:
		var p: Vector2 = mid - land * distance + direction * minf(distance * 0.4, 4.0)
		if ground.shoreline.domains.at(p) >= 0:
			eye = p
			break
	var level: float = ground.shoreline.domains.level(int(segment["body"]), mid)
	var dry := mid + land * 5.0
	var top := maxf(level, ground.height_at_world(dry.x, dry.y))
	view._rig.position = Vector3(eye.x, top + 2.0, eye.y)
	var target := Vector3(mid.x, lerpf(level, top, 0.5), mid.y)
	var look := View360.aim(view._rig.position, target)
	view._rig.set_look(look.x, look.y)
	view._rig.set_zoom(1.0)
	view._atmos.set_probe_origin(view._rig.position)
	await _settle(settle_s, SETTLE_FRAMES)
	await _snap(view, id, "edge")
	_stats[id + "_edge"]["shore_segment"] = segment
	_stats[id + "_edge"]["local_context_m"] = 70.0

func _local_world(data: LocationData) -> Array:
	var ground := GroundTruth.new(data)
	if ground.shoreline == null or not ground.shoreline.ready:
		return []
	var spawn := View360.spawn_xz(data)
	var closest := {}
	var distance := INF
	for segment in ground.shoreline.segments:
		var p := Geometry2D.get_closest_point_to_segment(spawn, segment["a"], segment["b"])
		var d := spawn.distance_squared_to(p)
		if d < distance:
			distance = d
			closest = segment
	if closest.is_empty():
		return []
	var mid: Vector2 = (closest["a"] + closest["b"]) * 0.5
	var root := Node3D.new()
	root.name = "ShoreInspection"
	root.add_child(TerrainBuilder._terrain_mesh(data, ground))
	TerrainBuilder._adopt_flat(root, WaterBuilder.build_water(data, ground))
	var original := [data.buildings, data.roads, data.far_landuse, data.far_towers]
	var buildings: Array = []
	for building in data.buildings:
		var p := Vector2(float(building["x"]), float(building["z"]))
		if p.distance_to(mid) <= 70.0 + maxf(float(building.get("size_x", 0)), float(building.get("size_z", 0))):
			buildings.append(building)
	var roads: Array = []
	var box := Rect2(mid - Vector2.ONE * 70.0, Vector2.ONE * 140.0)
	for road in data.roads:
		if road is Dictionary and RingGeometry.aabb(road.get("points", PackedVector2Array())).grow(10.0).intersects(box):
			roads.append(road)
	data.buildings = buildings
	data.roads = roads
	data.far_landuse = []
	data.far_towers = []
	TerrainBuilder._adopt_flat(root, BuildingBuilder.build_buildings(data, ground))
	TerrainBuilder._adopt_flat(root, RoadBuilder.build_roads(data, ground))
	data.buildings = original[0]
	data.roads = original[1]
	data.far_landuse = original[2]
	data.far_towers = original[3]
	return [ground, root, closest]
