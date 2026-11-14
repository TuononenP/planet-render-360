extends SceneTree

## Headless: godot --headless --script tests/bus_stop_test.gd
## Buses at stops (TransitVehicles): a share of the mapped stops hold a
## bus at the kerb on the stop's side, facing with the traffic and clear
## of one another; parked cars leave the bus its kerb; the build is
## gated by quality and keeps its own near/far switch.

func _init() -> void:
	var failures: Array[String] = []
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = 60.17
	data.longitude = 24.94
	data.country = "FI"
	data.buildings = []
	var road := OsmTags._road_entry({"highway": "tertiary", "lanes": "2", "parking:both": "lane"},
		PackedVector2Array([Vector2(0, -400), Vector2(0, 400)]))
	data.roads = [road]
	for z in range(-380, 381, 20):
		data.bus_stops.append({"x": 7.0, "z": float(z), "name": ""})
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var half := float(road["width_m"]) * 0.5
	var buses := TransitVehicles.plan_buses(data, ground, m2u, [])
	if buses != TransitVehicles.plan_buses(data, ground, m2u, []):
		failures.append("bus placement must be deterministic")
	if buses.size() < 4 or buses.size() > TransitVehicles.MAX_BUSES:
		failures.append("about a third of 39 stops should hold a bus: %d" % buses.size())
	for i in buses.size():
		var bus: Array = buses[i]
		var p: Vector3 = bus[0]
		if absf(p.x / m2u - (half - TransitVehicles.BUS_KERB_IN_M)) > 0.05:
			failures.append("a bus off its stop's kerb at %s" % p)
			break
		var fw := Vector2((bus[1] as Basis).x.x, (bus[1] as Basis).x.z).normalized()
		if fw.distance_to(ParkedCars.facing(Vector2(0, 1), 1.0, 0, false)) > 0.01:
			failures.append("a bus facing against the traffic: %s" % fw)
			break
		for j in i:
			if (buses[j][0] as Vector3).distance_to(p) < (CarSpecs.length_m("bus") + TransitVehicles.BUS_CLEAR_M) * m2u - 0.01:
				failures.append("two buses share a stop")
	var cars := ParkedCars.plan(data, ground, m2u)
	if cars.size() < 20:
		failures.append("the street should still park cars: %d" % cars.size())
	for c in cars:
		var q := Vector2((c[0] as Vector3).x, (c[0] as Vector3).z)
		for bus: Array in buses:
			if Geometry2D.get_closest_point_to_segment(q, bus[6], bus[7]).distance_to(q) < 1.5 * m2u:
				failures.append("a car parked in a bus at %s" % q)
				break
	var holder := Node3D.new()
	TransitVehicles.build(holder, data, ground)
	var depot := holder.get_node_or_null("Buses")
	if depot == null or depot.get_child_count() != buses.size() * 3:
		failures.append("each bus builds a near, a far and a shadow batch")
	else:
		var far := depot.get_node("Cars_Bus0_far") as MultiMeshInstance3D
		if not far.has_meta("lod_own") or far.visibility_range_begin <= 0.0:
			failures.append("buses keep their own near/far switch")
	holder.free()
	var low := Node3D.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.BALANCED)
	TransitVehicles.build(low, data, ground)
	if low.get_child_count() != 0:
		failures.append("no buses below High")
	low.free()
	if failures.is_empty():
		print("BUS STOP OK: buses at their kerbs with the traffic, spaced, cars clear, gated")
		quit(0)
	else:
		for failure in failures:
			printerr("BUS STOP FAIL: ", failure)
		quit(1)
