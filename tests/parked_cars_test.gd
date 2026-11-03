extends SceneTree

## Headless: godot --headless --script tests/parked_cars_test.gd
## Kerb widths and parked cars: parking tags parse to sides and widen an
## untagged-width road; a road between two mapped sidewalks takes their
## kerb-to-kerb width (RoadWidths) and parks both kerbs; a road with no
## room or a no-parking tag parks none; cars keep clear of junctions,
## pitch with a sloping street, and only on desktop Ultra.

func _init() -> void:
	_run()

func _data(slope: float = 0.0) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	var step := WorldScale.DETAILED_EXTENT_M / float(n - 1)
	for z in n:
		for x in n:
			data.heights[z * n + x] = 3.0 + slope * (float(z) - float(n - 1) * 0.5) * step
	data.water_level = -3.0
	data.latitude = 37.80
	data.longitude = -122.42
	data.buildings = []
	return data

func _line(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b])

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	# Parking tags.
	for row in [[{"parking:both": "lane"}, 3], [{"parking:left": "no", "parking:right": "lane"}, 2],
			[{"parking:lane:both": "parallel"}, 3], [{"parking:both": "no"}, 0], [{}, -1]]:
		var got := OsmTags.parking_sides(row[0])
		if got != int(row[1]):
			failures.append("parking sides of %s: %d, expected %d" % [row[0], got, row[1]])
	var tagged := OsmTags._road_entry({"highway": "residential", "lanes": "2", "parking:both": "lane"},
		_line(Vector2.ZERO, Vector2(50, 0)))
	if absf(float(tagged["width_m"]) - (6.0 + 2.0 * OsmTags.PARKING_LANE_M)) > 0.01:
		failures.append("two lanes and parking both sides should be 10.4 m: %s" % tagged["width_m"])
	# Hyde St: 2 lanes between sidewalks mapped 7.5 m either side of it.
	var hyde := OsmTags._road_entry({"highway": "tertiary", "lanes": "2", "sidewalk:both": "separate"},
		_line(Vector2(0, -150), Vector2(0, 150)))
	var roads: Array = [hyde,
		OsmTags._road_entry({"highway": "footway", "footway": "sidewalk"}, _line(Vector2(-7.5, -150), Vector2(-7.5, 150))),
		OsmTags._road_entry({"highway": "footway", "footway": "sidewalk"}, _line(Vector2(7.5, -150), Vector2(7.5, 150))),
		OsmTags._road_entry({"highway": "residential", "sidewalk": "both"}, _line(Vector2(40, -150), Vector2(40, 150)))]
	RoadWidths.from_sidewalks(roads)
	if absf(float(hyde["width_m"]) - 12.0) > 0.3 or float(hyde.get("parking_m", 0.0)) < 5.0:
		failures.append("Hyde St should measure 12 m kerb to kerb, 6 m of it parking: %s" % hyde)
	if float((roads[3] as Dictionary)["width_m"]) != OsmTags.road_class_width("residential"):
		failures.append("a road without its own sidewalk lines keeps its width: %s" % roads[3])
	if ParkedCars.sides_of(hyde) != 3 or ParkedCars.sides_of(roads[3]) != 0 \
			or ParkedCars.sides_of({"parking": 0, "parking_m": 6.0}) != 0:
		failures.append("parked sides: measured room parks both, no room none, a no-parking tag wins")
	_width_barriers(failures)
	_directions_and_obstacles(failures)
	var yellow := Color(0.95, 0.62, 0.02)
	var taxi_count := 0
	for i in 500:
		var p := Vector2(float(i) * 7.0, 31.0)
		if ParkedCars.paint_for(p, "sedan", true) == yellow:
			taxi_count += 1
		if ParkedCars.paint_for(p, "sedan", false) == yellow:
			failures.append("taxi paint must stay in New York")
	if taxi_count < 20 or taxi_count > 100:
		failures.append("New York should have a modest share of yellow sedans: %d" % taxi_count)
	# Placement on a slope (5 %, z down the street).
	var data := _data(0.05)
	data.roads = roads
	var ground := GroundTruth.new(data)
	var cars := ParkedCars.plan(data, ground, WorldScale.metres_to_units())
	if cars != ParkedCars.plan(data, ground, WorldScale.metres_to_units()):
		failures.append("parking, vehicle types and colors must be deterministic")
	if cars.size() < 40:
		failures.append("300 m of Hyde St should park both kerbs: %d cars" % cars.size())
	var sides := {}
	var pitched := true
	for c in cars:
		var p: Vector3 = c[0]
		sides[signf(p.x)] = true
		if absf(absf(p.x) - (6.0 - ParkedCars.KERB_IN_M)) > 0.05 or absf(p.x - 40.0) < 5.0:
			failures.append("a car off Hyde's kerbs at %s" % p)
			break
		var fwd: Vector3 = (c[1] as Basis).x.normalized()
		pitched = pitched and absf(fwd.y) > 0.03
	if sides.size() != 2:
		failures.append("cars should line both kerbs: %s" % [sides.keys()])
	if not pitched:
		failures.append("cars on a 5 % street should pitch with it")
	# Junctions (a node shared with a cross street) stay clear.
	var hyde_x := hyde.duplicate()
	hyde_x["points"] = PackedVector2Array([Vector2(0, -150), Vector2(0, 0), Vector2(0, 150)])
	data.roads = [hyde_x, OsmTags._road_entry({"highway": "residential"}, _line(Vector2(-60, 0), Vector2(0, 0)))]
	for c in ParkedCars.plan(data, ground, WorldScale.metres_to_units()):
		if Vector2((c[0] as Vector3).x, (c[0] as Vector3).z).distance_to(Vector2(0, 0)) < ParkedCars.CUT_M - 1.5:
			failures.append("a car parked in the junction at %s" % c[0])
			break
	# Ultra only; every kind builds.
	var high := _data()
	RenderSettings.apply_preset(high, RenderSettings.Preset.HIGH)
	high.roads = roads
	if ParkedCars.build(Node3D.new(), high, GroundTruth.new(high)) != 0:
		failures.append("parked cars are desktop Ultra only")
	var ultra := _data()
	ultra.roads = roads
	var holder := Node3D.new()
	var built := ParkedCars.build(holder, ultra, GroundTruth.new(ultra))
	if built == 0 or holder.get_child_count() == 0:
		failures.append("Ultra should build parked car batches")
	else:
		var batches := holder.get_child(0)
		var pairs := 0
		for node in batches.get_children():
			if not node.name.ends_with("_near"):
				continue
			var near := node as MultiMeshInstance3D
			var far := batches.get_node_or_null(str(near.name).trim_suffix("_near") + "_far") as MultiMeshInstance3D
			if far == null:
				failures.append("%s must have a distant batch" % near.name)
				continue
			pairs += 1
			if near.multimesh.custom_aabb != far.multimesh.custom_aabb \
					or near.multimesh.custom_aabb.size == Vector3.ZERO \
					or near.visibility_range_end != far.visibility_range_begin:
				failures.append("%s and its distant batch must share bounds and a switch distance" % near.name)
		if pairs == 0:
			failures.append("Ultra should have detailed and distant car batches")
	holder.free()
	# The headless renderer does not retain MultiMesh instance transforms,
	# so check the bounds calculation using known placements directly.
	var placements := [[Vector3(20, 3, -40), Basis.IDENTITY],
		[Vector3(35, 4, -30), Basis(Vector3.UP, 0.8)]]
	var near_box := ParkedCars.CarModels.mesh("sedan").get_aabb()
	var far_box := ParkedCars.mesh("sedan").get_aabb()
	var bounds := ParkedCars._batch_bounds(placements, near_box.merge(far_box)).grow(0.001)
	for car in placements:
		for box in [near_box, far_box]:
			if not bounds.encloses(Transform3D(car[1], car[0]) * box):
				failures.append("shared batch bounds must contain both LODs at every car")
	for kind in ["sedan", "hatch", "wagon", "suv", "van"]:
		var mesh := ParkedCars.mesh(kind)
		if mesh.get_surface_count() < 3:
			failures.append("%s should build body, glass and tyres" % kind)
		# Front faces as Godot winds them (BoxMesh): clockwise about the
		# outward normal, so cull_back keeps the outside.
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for t in range(0, ix.size(), 3):
				if (v[ix[t + 1]] - v[ix[t]]).cross(v[ix[t + 2]] - v[ix[t]]).dot(nn[ix[t]]) > 0.0:
					failures.append("%s surface %d has a back-facing triangle" % [kind, si])
					break
	failures.remove_at(0)
	if failures.is_empty():
		print("PARKED CARS OK: parking tags, kerb widths from sidewalks, both kerbs, slope pitch, junctions clear, Ultra only")
		quit(0)
	else:
		for f in failures:
			printerr("PARKED CARS FAIL: ", f)
		quit(1)

func _width_barriers(failures: Array[String]) -> void:
	var line := _line(Vector2(0, -100), Vector2(0, 100))
	for kind in ["both", "cycleway", "cycleway_one_side", "tree", "path", "wide"]:
		var tags := {"highway": "residential", "lanes": "2", "sidewalk": "separate"}
		if kind == "both":
			tags["sidewalk"] = "both"
		if kind == "wide":
			tags["lanes"] = "10"
		var road := OsmTags._road_entry(tags, line)
		var roads: Array = [road]
		for side in [-1, 1]:
			roads.append(OsmTags._road_entry({"highway": "footway", "footway": "sidewalk"},
				_line(Vector2(side * 9, -100), Vector2(side * 9, 100))))
		if kind in ["cycleway", "cycleway_one_side", "path"]:
			for side in ([-1] if kind == "cycleway_one_side" else [-1, 1]):
				roads.append(OsmTags._road_entry({"highway": "cycleway" if kind == "cycleway_one_side" else kind},
					_line(Vector2(side * 4, -100), Vector2(side * 4, 100))))
		var trees: Array = []
		if kind == "tree":
			for z in range(-100, 101, 4):
				for side in [-1, 1]:
					trees.append({"x": side * 4.0, "z": float(z)})
		RoadWidths.from_sidewalks(roads, trees)
		var expected := 30.0 if kind == "wide" else 6.0
		if absf(float(road["width_m"]) - expected) > 0.1:
			failures.append("%s should preserve %.1f m of lanes, got %s" % [kind, expected, road["width_m"]])

func _directions_and_obstacles(failures: Array[String]) -> void:
	for value in ["yes", "-1", "no"]:
		var direction := OsmTags.oneway({"oneway": value})
		for side in [-1.0, 1.0]:
			for left in [false, true]:
				var got := ParkedCars.facing(Vector2.RIGHT, side, direction, left)
				var expected := float(direction) if direction != 0 else (1.0 if (side < 0.0) != left else -1.0)
				if got != Vector2.RIGHT * expected:
					failures.append("traffic direction mismatch for %s / %s / %s" % [value, side, left])
	var data := _data()
	data.country = "GB"
	if not RoadSurface.left_traffic(data):
		failures.append("GB uses left-hand traffic")
	data.trees = [{"x": 2.0, "z": 4.0}]
	data.street_furniture = [{"x": 6.0, "z": 4.0, "kind": "bus_stop"}]
	data.railways = [{"class": "tram", "points": _line(Vector2(-20, 10), Vector2(20, 10)), "gauge_m": 1.0}]
	var obstacles := ParkedCars.obstacle_grid(data, 1.0)
	for p in [Vector2(2, 4), Vector2(6, 4), Vector2(0, 10)]:
		if not ParkedCars.blocked(p, obstacles, 1.0):
			failures.append("mapped obstacle did not exclude parking at %s" % p)
	if ParkedCars.blocked(Vector2(-10, -10), obstacles, 1.0):
		failures.append("clear parking slot falsely excluded")
