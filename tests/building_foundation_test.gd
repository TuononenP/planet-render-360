extends SceneTree

## BuildingFoundation slope seating (offline): godot --headless --script tests/building_foundation_test.gd
## A building on a slope raises its floor toward the uphill ground, by at
## most PLINTH_MAX_M over the lowest footprint ground, and builds a plinth
## for the gap; flat ground gets none and the plinth mesh stays in range.

func _init() -> void:
	_run()

func _ground(slope_m_per_post: float) -> GroundTruth:
	var d := LocationData.new()
	d.grid_size = 64
	d.heights.resize(64 * 64)
	for z in 64:
		for x in 64:
			d.heights[z * 64 + x] = 20.0 + slope_m_per_post * float(x)
	d.water_level = -3.0
	return GroundTruth.new(d)

func _square(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r),
		c + Vector2(r, r), c + Vector2(-r, r)])

func _run() -> void:
	var failures: Array[String] = []
	var m := WorldScale.metres_to_units()
	var flat := _ground(0.0)
	var ring := _square(Vector2.ZERO, 10.0 * m)
	var f := BuildingFoundation.sample(flat, ring, Vector2.ZERO)
	if float(f["plinth"]) != 0.0 or not is_equal_approx(float(f["floor"]), float(f["low"])):
		failures.append("flat ground got a plinth: %s" % [f])
	# A steep hillside: a 20 m footprint spans several metres of relief.
	var steep := _ground(2.0)
	var s := BuildingFoundation.sample(steep, ring, Vector2.ZERO)
	var relief := (float(s["floor"]) - float(s["low"])) / m
	if float(s["plinth"]) <= 0.0:
		failures.append("steep ground got no plinth: %s" % [s])
	if relief > BuildingFoundation.PLINTH_MAX_M + 0.001:
		failures.append("floor lifted %.2f m, over the %.1f m cap" % [relief, BuildingFoundation.PLINTH_MAX_M])
	var root := Node3D.new()
	BuildingFoundation.plinth(root, ring, [], s, steep)
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if meshes.size() != 1:
		failures.append("plinth built %d meshes, expected 1" % meshes.size())
	else:
		var box := (meshes[0] as MeshInstance3D).mesh.get_aabb()
		var y0 := float(s["low"]) - BuildingFoundation.SINK_M * m
		var y1 := float(s["floor"]) - BuildingFoundation.SINK_M * m
		if absf(box.position.y - y0) > 0.01 or absf(box.end.y - y1) > 0.01:
			failures.append("plinth spans %.2f..%.2f, expected %.2f..%.2f" % [box.position.y, box.end.y, y0, y1])
	root.free()
	var none := Node3D.new()
	BuildingFoundation.plinth(none, ring, [], f, flat)
	if none.get_child_count() != 0:
		failures.append("flat ground built a plinth mesh")
	none.free()
	if failures.is_empty():
		print("BUILDING FOUNDATION PASS")
		quit(0)
	else:
		for message in failures:
			printerr("BUILDING FOUNDATION FAIL: ", message)
		quit(1)
