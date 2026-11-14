extends SceneTree

## BuildingFoundation slope seating (offline): godot --headless --script tests/building_foundation_test.gd
## A building on a slope raises its floor toward the uphill ground and
## builds a plinth for the gap: the hill never stands more than
## BURY_MAX_M up a wall until the plinth is PLINTH_TALL_M. Flat ground
## gets none and the plinth mesh stays in range.

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

func _material(mi: MeshInstance3D) -> Material:
	if mi.material_override != null:
		return mi.material_override
	return mi.mesh.surface_get_material(0)

func _square(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r),
		c + Vector2(r, r), c + Vector2(-r, r)])

func _quay_ground(slope: float) -> GroundTruth:
	var d := LocationData.new()
	d.grid_size = 256
	d.heights.resize(256 * 256)
	var step := 2400.0 / 255.0
	for z in 256:
		for x in 256:
			var wx := (float(x) - 128.0) * step
			d.heights[z * 256 + x] = 3.0 + slope * maxf(wx, 0.0)
	d.centre_elevation_m = 3.0
	d.water_level = 0.5
	d.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array([
		Vector2(-1200, -1200), Vector2(-5, -1200), Vector2(-5, 1200), Vector2(-1200, 1200)]), "holes": []}]
	return GroundTruth.new(d)

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
	if relief > BuildingFoundation.PLINTH_TALL_M + 0.001:
		failures.append("floor lifted %.2f m, over the %.1f m cap" % [relief, BuildingFoundation.PLINTH_TALL_M])
	# No wall is buried past a window sill, whatever the slope, until the
	# plinth is as tall as it gets.
	var steepest := 0.0
	for slope: float in [0.5, 2.0, 5.0, 8.0, 12.0]:
		var hill := _ground(slope)
		var seat := BuildingFoundation.sample(hill, ring, Vector2.ZERO)
		var high := -INF
		var low := INF
		for p in ring:
			high = maxf(high, hill.height_at_world(p.x, p.y))
			low = minf(low, hill.height_at_world(p.x, p.y))
		steepest = maxf(steepest, (high - low) / m)
		var buried := (high - float(seat["floor"])) / m
		if (high - low) / m <= BuildingFoundation.PLINTH_TALL_M + BuildingFoundation.BURY_MAX_M \
				and buried > BuildingFoundation.BURY_MAX_M + 0.01:
			failures.append("%.1f m/post slope (%.1f m relief) buries the uphill wall %.2f m" % [slope, (high - low) / m, buried])
		# Under PLINTH_MIN_M of relief the walls just sink into it.
		if (high - low) / m <= BuildingFoundation.PLINTH_MAX_M and buried > BuildingFoundation.PLINTH_MIN_M:
			failures.append("%.1f m/post slope: a gentle hill should not bury the wall, got %.2f m" % [slope, buried])
	if steepest <= BuildingFoundation.PLINTH_MAX_M:
		failures.append("the test slopes never pass the plain plinth cap: %.2f m relief" % steepest)
	# Reading the ground along a long wall finds no relief on flat ground.
	var crown := _ground(0.0)
	var long_ring := PackedVector2Array([Vector2(-30, -4) * m, Vector2(30, -4) * m, Vector2(30, 4) * m, Vector2(-30, 4) * m])
	if float(BuildingFoundation.sample(crown, long_ring, Vector2.ZERO)["plinth"]) != 0.0:
		failures.append("flat ground under a long building got a plinth")
	var root := Node3D.new()
	BuildingFoundation.plinth(root, ring, [], s, steep)
	var body: MeshInstance3D = null
	var coping: MeshInstance3D = null
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mat := _material(mi as MeshInstance3D)
		if mat == PlinthStyle.body_material():
			body = mi
		elif mat == PlinthStyle.coping_material():
			coping = mi
	var y1 := float(s["floor"]) - BuildingFoundation.SINK_M * m
	if body == null:
		failures.append("plinth built no granite body mesh")
	else:
		var box := body.mesh.get_aabb()
		var y0 := float(s["low"]) - BuildingFoundation.SINK_M * m
		if absf(box.position.y - y0) > 0.01 or absf(box.end.y - y1) > 0.01:
			failures.append("plinth spans %.2f..%.2f, expected %.2f..%.2f" % [box.position.y, box.end.y, y0, y1])
	# This plinth shows under 0.6 m of wall: plain granite, no coping.
	if coping != null:
		failures.append("a shallow plinth got a coping course")
	# A taller plinth carries a granite coping proud of the wall at its top.
	var hill := _ground(6.0)
	var hs := BuildingFoundation.sample(hill, ring, Vector2.ZERO)
	var hroot := Node3D.new()
	BuildingFoundation.plinth(hroot, ring, [], hs, hill)
	coping = null
	for mi in hroot.find_children("*", "MeshInstance3D", true, false):
		if _material(mi as MeshInstance3D) == PlinthStyle.coping_material():
			coping = mi
	var hy1 := float(hs["floor"]) - BuildingFoundation.SINK_M * m
	if coping == null:
		failures.append("a tall plinth got no granite coping: %s" % [hs])
	else:
		var cbox := coping.mesh.get_aabb()
		if absf(cbox.end.y - hy1) > 0.01 or absf(cbox.position.y - (hy1 - PlinthStyle.COPING_DEPTH_M * m)) > 0.01:
			failures.append("coping spans %.2f..%.2f, expected the top %.2f m under %.2f" % [cbox.position.y, cbox.end.y, PlinthStyle.COPING_DEPTH_M, hy1])
		if cbox.position.x > -10.0 * m - PlinthStyle.COPING_PROUD_M * m * 0.5:
			failures.append("coping does not stand proud of the downhill wall: x %.2f" % cbox.position.x)
	hroot.free()
	root.free()
	var none := Node3D.new()
	BuildingFoundation.plinth(none, ring, [], f, flat)
	if none.get_child_count() != 0:
		failures.append("flat ground built a plinth mesh")
	none.free()
	# Quayside straddle: the water polygon clips the west edge, the centre
	# and east side stand on dry quay. The carved bed is not the ground:
	# the building seats dry, with no piles.
	var quay := _quay_ground(0.0)
	var qring := _square(Vector2.ZERO, 12.0 * m)
	qring = PackedVector2Array([Vector2(-12, -8) * m, Vector2(12, -8) * m,
		Vector2(12, 8) * m, Vector2(-12, 8) * m])
	var qf := BuildingFoundation.sample(quay, qring, Vector2.ZERO,
		quay.render_y(WaterBuilder.SEA_LEVEL_M))
	if bool(qf["raised"]):
		failures.append("quayside building on dry centre was raised on piles: %s" % [qf])
	if absf(float(qf["floor"]) - float(qf["low"])) > 0.01:
		failures.append("flat quay floor %.2f should seat at dry low %.2f" % [float(qf["floor"]), float(qf["low"])])
	var qroot := Node3D.new()
	BuildingFoundation.build(qroot, qring, [], qf, {"kind": "residential"}, quay)
	if qroot.get_child_count() != 0:
		failures.append("dry-seated quay building built a water foundation (%d children)" % qroot.get_child_count())
	qroot.free()
	# Same straddle on a bank rising inland: a solid plinth, not stilts.
	var bank := _quay_ground(0.2)
	var bf := BuildingFoundation.sample(bank, qring, Vector2.ZERO,
		bank.render_y(WaterBuilder.SEA_LEVEL_M))
	if bool(bf["raised"]) or float(bf["plinth"]) <= 0.0:
		failures.append("bank straddle should seat dry on a plinth: %s" % [bf])
	var broot := Node3D.new()
	BuildingFoundation.build(broot, qring, [], bf, {"kind": "residential"}, bank)
	BuildingFoundation.plinth(broot, qring, [], bf, bank)
	var pile_nodes := 0
	for child in broot.find_children("*", "MeshInstance3D", true, false):
		if bool(child.get_meta("water_foundation", false)):
			pile_nodes += 1
	if pile_nodes != 0:
		failures.append("bank straddle built %d pile meshes instead of a plinth" % pile_nodes)
	if broot.find_children("*", "MeshInstance3D", true, false).is_empty():
		failures.append("bank straddle built no plinth wall")
	var plinth_min := INF
	for child in broot.find_children("*", "MeshInstance3D", true, false):
		plinth_min = minf(plinth_min, (child as MeshInstance3D).mesh.get_aabb().position.y)
	var bed := bank.height_at_world(-12.0 * m, 0.0)
	if absf(plinth_min - (bed - BuildingFoundation.SINK_M * m)) > 0.05:
		failures.append("quayside plinth bottom %.2f should reach the carved bed %.2f" % [plinth_min, bed])
	broot.free()
	# A footprint wholly over water keeps its deck and piles.
	var pring := PackedVector2Array([Vector2(-112, -8) * m, Vector2(-88, -8) * m,
		Vector2(-88, 8) * m, Vector2(-112, 8) * m])
	var pf := BuildingFoundation.sample(quay, pring, Vector2(-100, 0) * m,
		quay.render_y(WaterBuilder.SEA_LEVEL_M))
	if not bool(pf["raised"]):
		failures.append("building wholly over water should stay raised: %s" % [pf])
	var proot := Node3D.new()
	BuildingFoundation.build(proot, pring, [], pf, {"kind": "boathouse"}, quay)
	if proot.get_child_count() == 0:
		failures.append("over-water building built no deck/piles")
	proot.free()
	# Mixed raised: centre over water, east edge on dry quay. Piles only
	# on the wet stretch, none standing on the dry east ground.
	var mring := PackedVector2Array([Vector2(-26, -8) * m, Vector2(-2, -8) * m,
		Vector2(-2, 8) * m, Vector2(-26, 8) * m])
	var mf := BuildingFoundation.sample(quay, mring, Vector2(-14, 0) * m,
		quay.render_y(WaterBuilder.SEA_LEVEL_M))
	if not bool(mf["raised"]):
		failures.append("centre-wet straddle should stay raised: %s" % [mf])
	var mroot := Node3D.new()
	BuildingFoundation.build(mroot, mring, [], mf, {"kind": "retail"}, quay)
	if not mroot.has_node("WaterFoundationPiles"):
		failures.append("mixed raised building built no piles")
	else:
		var pile_mesh := (mroot.get_node("WaterFoundationPiles") as MeshInstance3D).mesh
		var max_x := -INF
		for v in pile_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			max_x = maxf(max_x, v.x)
		if max_x > -4.0 * m:
			failures.append("piles stand on dry quay ground (max pile x %.2f)" % max_x)
	mroot.free()
	# Low dry pier: no wet stretch, but the freeboard lifts the floor off
	# the dry ground, so the deck still needs its piles.
	var ld := LocationData.new()
	ld.grid_size = 49
	ld.heights.resize(49 * 49)
	ld.heights.fill(0.67)
	ld.centre_elevation_m = 80.0
	ld.water_level = 0.5
	ld.land_polygons = [{"class": "water", "tidal": true, "points": PackedVector2Array([
		Vector2(100, 100), Vector2(200, 100), Vector2(200, 200), Vector2(100, 200)]), "holes": []}]
	var low_ground := GroundTruth.new(ld)
	var lring := _square(Vector2.ZERO, 5.0 * m)
	var lf := BuildingFoundation.sample(low_ground, lring, Vector2.ZERO,
		low_ground.render_y(WaterBuilder.SEA_LEVEL_M))
	if not bool(lf["raised"]):
		failures.append("low dry pier should stay raised: %s" % [lf])
	var lroot := Node3D.new()
	BuildingFoundation.build(lroot, lring, [], lf, {"kind": "retail"}, low_ground)
	if not lroot.has_node("WaterFoundationPiles"):
		failures.append("low dry pier built a deck without piles (floating deck)")
	lroot.free()
	# Pile depth cap: a bad deep ground sample must not grow a pile
	# hundreds of metres under the water.
	var droot := Node3D.new()
	BuildingFoundation.build(droot, _square(Vector2.ZERO, 5.0 * m), [],
		{"raised": true, "floor": 45.0 * m, "water": 40.0 * m, "plinth": 0.0},
		{"kind": "retail"}, flat)
	if not droot.has_node("WaterFoundationPiles"):
		failures.append("deep-water footing built no piles")
	else:
		var deep_min := (droot.get_node("WaterFoundationPiles") as MeshInstance3D).mesh.get_aabb().position.y
		if absf(deep_min - (40.0 - BuildingFoundation.PILE_DEPTH_M) * m) > 0.05:
			failures.append("pile bottom %.2f should stop %.1f m under the water" % [deep_min, BuildingFoundation.PILE_DEPTH_M])
	droot.free()
	if failures.is_empty():
		print("BUILDING FOUNDATION PASS")
		quit(0)
	else:
		for message in failures:
			printerr("BUILDING FOUNDATION FAIL: ", message)
		quit(1)
