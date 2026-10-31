extends SceneTree

## Headless: godot --headless --script tests/building_fabric_test.gd
## Continuous street fabric and facade relief: abutting parcels share
## their party wall (no windowed wall on it, a firewall only above a lower
## neighbour), street roofs keep gables on party edges, levels-tagged
## heights stand the roof on top of the storeys, courtyard relations get
## inward walls and a holed roof, the new roof shapes mesh, and near
## buildings carry 3D relief tagged as near detail.

func _init() -> void:
	_run()

func _data() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.seed_value = 5
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.buildings = []
	data.roads = []
	return data

func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

func _bldg(fp: PackedVector2Array, levels: int, extra: Dictionary = {}) -> Dictionary:
	var c := RingGeometry.centroid(fp)
	var b := {"x": c.x, "z": c.y, "size_x": 12.0, "size_z": 12.0, "footprint": fp,
		"height": float(levels) * 3.2, "height_source": "levels", "levels": levels,
		"kind": "apartments", "roof_shape": "mansard", "parts": [], "holes": []}
	b.merge(extra, true)
	return b

## Wall quads (vertical faces) whose centre lies on the segment x = x0.
func _faces_on_x(root: Node, x0: float) -> Array:
	var out: Array = []
	for c in root.get_children():
		if not (c is MeshInstance3D) or not (c.mesh is ArrayMesh):
			continue
		var mi := c as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var arr := MeshArrays.surface(mi.mesh, s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var mat := mi.get_active_material(s)
			for i in range(0, v.size() - 3, 4):
				if absf(nn[i].y) > 0.1 or absf(nn[i].x) < 0.9:
					continue
				var cx := (v[i].x + v[i + 1].x + v[i + 2].x + v[i + 3].x) * 0.25
				if absf(cx - x0) < 0.05:
					out.append({"mat": mat, "y0": minf(v[i].y, v[i + 2].y),
						"y1": maxf(v[i].y, v[i + 2].y), "wall": WallVariety.is_wall(mat),
						"facade": mat != null and mat.has_meta("fc_uv")})
	return out

func _run() -> void:
	var failures: Array[String] = []
	var m2u := WorldScale.metres_to_units()

	# --- Party walls: a 6-level and a 4-level parcel sharing x = 10. ---
	var data := _data()
	data.buildings = [_bldg(_rect(-2, 0, 10, 14), 6), _bldg(_rect(10, 0, 22, 14), 4)]
	var root := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
	var shared := _faces_on_x(root, 10.0)
	var facade_on_party := 0
	var fire := 0
	for f in shared:
		if f["facade"]:
			facade_on_party += 1
		elif f["wall"]:
			fire += 1
			var nb := BuildingMasses.plan(data.buildings[1], BuildingHeights._height_context(data))
			if f["y0"] < 3.0 + float(nb[0]["wall_m"]) - 0.05:
				failures.append("firewall starts at %.2f, below the 4-level neighbour's top" % f["y0"])
	if facade_on_party > 0:
		failures.append("%d windowed facade quads drawn on the shared party wall" % facade_on_party)
	if fire == 0:
		failures.append("no firewall above the lower neighbour on the party wall")
	var outer := _faces_on_x(root, -2.0)
	if outer.filter(func(f: Dictionary) -> bool: return f["facade"]).is_empty():
		failures.append("exposed end wall lost its facade")
	root.free()

	# Partition: half-covered edge splits in two pieces.
	var pw := PartyWalls.new()
	var ground := GroundTruth.new(_data())
	pw.add_mass({"ring": _rect(10, 0, 22, 7), "holes": [], "key": "n", "wall_m": 9.0}, ground)
	var pieces := pw.partition(Vector2(10, 14), Vector2(10, 0), Vector2(1, 0), "me")
	if pieces.size() != 2 or is_inf(float(pieces[1][2])) == is_inf(float(pieces[0][2])):
		failures.append("half-covered edge partition wrong: %s" % str(pieces))

	# --- Street roofs: party flags keep a gable on shared edges. ---
	var ring := _rect(0, 0, 12, 16)
	var party := PackedByteArray([0, 1, 0, 1])  # x = 12 and x = 0 edges shared
	var mesh := RoofGeometry.form_mesh(ring, 10.0, 4.0, "hipped", party)
	if mesh == null:
		failures.append("party-aware hipped roof did not mesh")
	else:
		var arr := MeshArrays.surface(mesh, 0)
		for nrm in (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array):
			if absf(nrm.x) > 0.35 and nrm.y > 0.2:
				failures.append("roof slopes toward a party wall (normal %s)" % str(nrm))
				break
	for shape in ["gambrel", "skillion", "half-hipped", "saltbox", "round", "mansard"]:
		var sm := RoofGeometry.form_mesh(ring, 10.0, 3.0, shape)
		if sm == null or (MeshArrays.surface(sm, 0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
			failures.append("roof shape %s produced no mesh" % shape)

	# --- Heights: levels count storeys under the roof. ---
	var ctx := BuildingHeights._height_context(_data())
	var plan := BuildingMasses.plan(_bldg(_rect(0, 0, 12, 14), 6), ctx)
	var fh := float((plan[0]["look"] as Dictionary)["floor_h"])
	if absf(float(plan[0]["wall_m"]) - 6.0 * fh) > 0.01 or float(plan[0]["rh_m"]) <= 0.0:
		failures.append("6 levels + mansard: wall %.2f (want %.2f), roof %.2f on top"
			% [plan[0]["wall_m"], 6.0 * fh, plan[0]["rh_m"]])
	var rl := BuildingMasses.plan(_bldg(_rect(30, 0, 42, 14), 6, {"roof_levels": 2}), ctx)
	if float(rl[0]["rh_m"]) < 2.0 * fh * 0.9:
		failures.append("roof:levels=2 gave a %.2f m roof" % rl[0]["rh_m"])

	# --- Courtyard: inner ring walls face into the hole; cap avoids it. ---
	var bridged := RingGeometry.bridge_holes(_rect(0, 0, 40, 40), [_rect(12, 12, 28, 28)])
	var tri := Geometry2D.triangulate_polygon(bridged)
	if tri.size() < 3:
		failures.append("keyhole courtyard ring did not triangulate")
	data = _data()
	data.buildings = [_bldg(_rect(-20, -20, 20, 20), 5, {"holes": [_rect(-8, -8, 8, 8)], "roof_shape": "flat"})]
	root = BuildingBuilder.build_buildings(data, GroundTruth.new(data))
	var inward := 0
	for f in _faces_on_x(root, -8.0):
		if f["facade"]:
			inward += 1
	if inward == 0:
		failures.append("courtyard has no inward facade walls")
	root.free()

	# --- Chamfered roofs: no face over the courtyard or off a concave
	# footprint, and no near-vertical shard (mansard lower slope < 75°). ---
	var l_ring := PackedVector2Array([Vector2(0, 0), Vector2(60, 0), Vector2(60, 14),
		Vector2(14, 14), Vector2(14, 50), Vector2(0, 50)])
	var cases := [[_rect(0, 0, 40, 40), [_rect(12, 12, 28, 28)]], [l_ring, []]]
	for cs in cases:
		var c_ring: PackedVector2Array = cs[0]
		var cm := RoofGeometry.form_mesh(c_ring, 10.0, 4.0, "mansard", PackedByteArray(), false, cs[1])
		if cm == null:
			failures.append("chamfered roof did not mesh")
			continue
		var cv: PackedVector3Array = MeshArrays.surface(cm, 0)[Mesh.ARRAY_VERTEX]
		for k in range(0, cv.size(), 3):
			var mid := (cv[k] + cv[k + 1] + cv[k + 2]) / 3.0
			var m2 := Vector2(mid.x, mid.z)
			var nrm := (cv[k + 2] - cv[k]).cross(cv[k + 1] - cv[k]).normalized()
			if not Geometry2D.is_point_in_polygon(m2, c_ring) or (not (cs[1] as Array).is_empty()
					and Geometry2D.is_point_in_polygon(m2, (cs[1] as Array)[0])):
				failures.append("chamfered roof face off the footprint at %s" % str(m2))
				break
			if absf(nrm.y) < 0.26:
				failures.append("chamfered roof has a near-vertical shard at %s" % str(m2))
				break

	# --- Relief: a near Paris block carries 3D balconies/rails. ---
	data = _data()
	data.buildings = [_bldg(_rect(-6, 20, 18, 34), 6, {"roof_shape": ""})]
	data.roads = [{"points": PackedVector2Array([Vector2(-40, 40), Vector2(40, 40)]), "width_m": 10.0,
		"class": "residential", "tunnel": false}]
	root = BuildingBuilder.build_buildings(data, GroundTruth.new(data))
	var relief: MeshInstance3D = null
	for c in root.get_children():
		if c.name.begins_with("Relief"):
			relief = c
	if relief == null:
		failures.append("near Paris building has no Relief mesh")
	elif not bool(relief.get_meta("lod_detail", false)):
		failures.append("Relief mesh is not tagged lod_detail")
	else:
		var iron := false
		for s in relief.mesh.get_surface_count():
			iron = iron or relief.mesh.surface_get_material(s) == ReliefKit.iron()
		if not iron:
			failures.append("Paris relief has no wrought-iron railing")
	root.free()

	# Paris rows: painted balcony rows match the relief layout.
	var rows := StoreyComposer.paris_rows(7, 0)
	var balconies := rows.filter(func(r: Dictionary) -> bool: return r["balcony"]).size()
	if balconies < 2:
		failures.append("7-storey Paris facade has %d balcony rows (want 2nd and 5th)" % balconies)

	if failures.is_empty():
		print("BUILDING FABRIC OK: party walls + firewalls, street roofs, roof shapes, levels heights, courtyards, relief")
	else:
		for f in failures:
			print("BUILDING FABRIC FAIL: ", f)
	quit(0 if failures.is_empty() else 1)
