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
		failures.append("cars should line both kerbs: %s" % sides.keys())
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
