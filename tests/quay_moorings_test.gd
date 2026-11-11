extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var d := LocationData.new()
	d.grid_size = 49
	d.heights.resize(49*49)
	d.heights.fill(3.0)
	d.water_level = 0.5
	d.country = "FI"
	d.quality_preset = RenderSettings.Preset.ULTRA
	d.land_polygons = [{"class":"water","tidal":true,
		"points":PackedVector2Array([Vector2(-1200,0),Vector2(1200,0),Vector2(1200,1200),Vector2(-1200,1200)])}]
	d.shore_structures = [{"kind":"quay","points":PackedVector2Array([Vector2(-450,0),Vector2(50,0)])}]
	var g := GroundTruth.new(d)
	var first := MarinaBuilder.plan(d,g,1.0)
	var boats: Array = first["boats"]
	_check(boats.size() >= 4 and boats.size() <= QuayMoorings.MAX_BOATS, "Mapped quay should get a bounded alongside fleet")
	for boat in boats:
		var p: Vector3 = boat[0]
		_check(p.z>0 and absf(sin(float(boat[1])))<0.001, "Quay boats must lie parallel on the wet side")
		_check(str(boat[3]) in ["steam","houseboat","yacht"], "Quay-side fleet must use steamer, houseboat or yacht silhouettes")
		_check(g.water_at(p.x,p.z)>0.3, "A berth must be in mapped water")
	_check(QuayMoorings._liner_deep(1.9999998, 1.0), "Rounding at the two-metre depth must not reject a berth")
	_check(not QuayMoorings._liner_deep(1.99, 1.0), "Water measurably below the depth requirement must reject a berth")
	var liners: Array = first["liners"]
	_check(liners.size() == 1, "A long straight tidal quay should berth one cruise liner, got %d" % liners.size())
	for l in liners:
		var lp: Vector3 = l[0]
		_check(float(l[2]) >= QuayMoorings.LINER_MIN_M and float(l[2]) <= QuayMoorings.LINER_MAX_M, "Liner length must stay in range")
		_check(absf(sin(float(l[1]))) < 0.001 and lp.z > 0.0, "Liner must lie parallel to the quay on the wet side")
		for boat in boats:
			var bp: Vector3 = boat[0]
			_check(Vector2(bp.x - lp.x, bp.z - lp.z).length() > float(l[2]) * 0.5 * 0.5, "Small craft must not overlap the liner")
	_check(not liners.is_empty() and liners[0][6] == "liner", "A sea quay without a terminal gets a liner")
	d.pois = [{"kind": "ferry_terminal", "x": -200.0, "z": -20.0}]
	var ferry_plan: Array = MarinaBuilder.plan(d, g, 1.0)["liners"]
	_check(ferry_plan.size() == 1 and ferry_plan[0][6] == "ferry", "A nearby terminal selects a passenger ferry")
	_check(ferry_plan == MarinaBuilder.plan(d, g, 1.0)["liners"], "Ferry berths must be deterministic")
	d.shore_structures = [
		{"kind":"quay", "points":PackedVector2Array([Vector2(-450,0), Vector2(-220,0)])},
		{"kind":"quay", "points":PackedVector2Array([Vector2(-215,0), Vector2(50,0)])}]
	_check((MarinaBuilder.plan(d, g, 1.0)["liners"] as Array).size() == 1, "Aligned quay fragments should join into a berth")
	d.shore_structures = [{"kind":"quay","points":PackedVector2Array([Vector2(-450,0),Vector2(50,0)])}]
	if not ferry_plan.is_empty():
		var fp: Vector3 = ferry_plan[0][0]
		d.buildings = [{"kind":"ship", "x":fp.x, "z":fp.z, "size_x":200.0, "size_z":25.0}]
		_check((MarinaBuilder.plan(d, g, 1.0)["liners"] as Array).is_empty(), "Mapped vessels must prevent duplicate large ships")
		d.buildings = [{"name": "Staten Island Ferry Whitehall Terminal", "use": "ferry_terminal", "x": fp.x, "z": fp.z}]
		_check(QuayMoorings._mapped_ship_near(d, Vector2(fp.x, fp.z), 200.0, 1.0), "Existing Staten Island ferry scenery keeps its own berth")
		d.buildings = []
	d.pois = []
	var coast := PackedVector2Array([Vector2(-450,0), Vector2(50,0)])
	d.shore_structures = []
	d.waterways = [{"class": "coastline", "points": coast}]
	_check(QuayMoorings._quay_lines(d, 1.0).is_empty(), "Natural coast without a terminal must not become a berth")
	d.pois = [{"kind": "ferry_terminal", "x": -200.0, "z": -20.0}]
	_check(not QuayMoorings._quay_lines(d, 1.0).is_empty(), "Terminal shoreline supplies berths when no quay is mapped")
	d.waterways = []
	d.pois = []
	d.shore_structures = [{"kind":"quay","points":coast}]
	var again: Array = MarinaBuilder.plan(d,g,1.0)["boats"]
	_check(again==boats, "Same map must produce the same berths")
	var root := Node3D.new()
	MarinaBuilder.build(root,d,g)
	var calls := 0
	for node in root.find_children("Boats_*","MultiMeshInstance3D",true,false):
		calls += node.multimesh.mesh.get_surface_count()
	_check(calls>0 and calls<=MarinaBuilder.MAX_DRAW_CALLS, "Merged boat surfaces must meet the draw budget")
	# Every kind strung along 1.6 km of quay: fixed 120 m cells would break
	# the budget, so the batching coarsens until it fits.
	var spread: Array = []
	for i in 160:
		spread.append([Vector3(-800.0 + float(i) * 10.0, 0.0, 50.0), 0.0, 1.0,
			VesselPrototypes.KINDS[i % VesselPrototypes.KINDS.size()], Color.WHITE])
	var surfaces := func(groups: Dictionary) -> int:
		var n := 0
		for key in groups:
			var kind: String = groups[key][0][3]
			n += MarinaBuilder.mesh(kind).get_surface_count() + MarinaBuilder.mesh(kind + "_far").get_surface_count()
		return n
	var fine := CellBatches.group(spread, MarinaBuilder.BATCH_M, func(b: Array) -> Vector3: return b[0],
		func(b: Array) -> String: return b[3])
	_check(int(surfaces.call(fine)) > MarinaBuilder.MAX_DRAW_CALLS - 1, "A long mixed quay must overflow fixed 120 m cells")
	_check(int(surfaces.call(MarinaBuilder._cells(spread, MarinaBuilder.MAX_DRAW_CALLS - 1, 1.0)))
		<= MarinaBuilder.MAX_DRAW_CALLS - 1, "Boat batches must coarsen to meet the draw budget")
	_check(QuayDetails.build(root,d,g)>0, "Final hard quay should get mooring bollards")
	root.free()
	var ring_root := Node3D.new()
	var ring_mesh := LandmarkMesh.new()
	ring_mesh.use("Iron", LandmarkMaterials.paint("#343b3e", 0.7, 0.5))
	QuayDetails._mooring_ring(ring_mesh, Vector3(0, 2, 0), Vector3.RIGHT)
	ring_mesh.commit(ring_root)
	var ring_parts := LandmarkBuilder.parts(ring_root)
	_check(not ring_parts.is_empty(), "Mooring ring must produce geometry")
	if not ring_parts.is_empty():
		var size := ring_parts[0].mesh.get_aabb().size
		_check(size.x > 0.3 and size.y > 0.3 and size.z < 0.1, "Ring should hang vertically in the quay wall plane")
	ring_root.free()
	d.quality_preset = RenderSettings.Preset.HIGH
	root = Node3D.new()
	_check(MarinaBuilder.build(root,d,g)==0 and QuayDetails.build(root,d,g)==0, "Quay dressing must be Ultra only")
	root.free()
	d.quality_preset = RenderSettings.Preset.ULTRA
	d.shore_structures = [{"kind":"quay","points":PackedVector2Array([Vector2(-60,0),Vector2(60,0)])}]
	_check((MarinaBuilder.plan(d,g,1.0)["liners"] as Array).is_empty(), "A short quay must not berth a liner")
	d.shore_structures = [{"kind":"quay","points":PackedVector2Array([Vector2(-250,0),Vector2(-100,40),Vector2(0,0),Vector2(100,40),Vector2(250,0)])}]
	_check((MarinaBuilder.plan(d,g,1.0)["liners"] as Array).is_empty(), "A zig-zag quay must not berth a liner")
	d.shore_structures = [{"kind":"quay","points":PackedVector2Array([Vector2(-450,0),Vector2(50,0)])}]
	d.land_polygons[0]["tidal"] = false
	_check((MarinaBuilder.plan(d,GroundTruth.new(d),1.0)["liners"] as Array).is_empty(), "Lake water must not berth a liner")
	d.land_polygons[0]["tidal"] = true
	d.land_polygons[0]["still_pool"] = true
	var pool := GroundTruth.new(d)
	_check((MarinaBuilder.plan(d,pool,1.0)["boats"] as Array).is_empty(), "Ornamental pools must not get ships")
	d.land_polygons = []
	var dry := GroundTruth.new(d)
	_check((MarinaBuilder.plan(d,dry,1.0)["boats"] as Array).is_empty(), "Dry retaining walls must not get berths")
	var fi := QuayBuilder.stone_material(d)
	var us := LocationData.new()
	us.latitude = 40.7
	us.longitude = -74.0
	us.country = "US"
	var concrete := QuayBuilder.stone_material(us)
	_check(fi!=concrete and QuayBuilder.stone_material(d)==fi, "Regional quay materials must remain separate across visits")
	if failures.is_empty():
		print("QUAY MOORINGS OK: alongside, wet side, pools/dry veto, deterministic, bollards, tier and draw budget")
		quit(0)
	else:
		for failure in failures:printerr("QUAY MOORINGS FAIL: ",failure)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):failures.append(message)
