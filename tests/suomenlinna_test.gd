extends SceneTree

## Offline regression: source identity, defensive parts, inhabited fabric,
## holes, mapped dimensions, unique wall ownership and the real gate site.
var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _find(buildings: Array, id: String) -> Dictionary:
	for b in buildings:
		if str(b.get("osm_id", "")) == id:
			return b
		var part := _find(b.get("parts", []), id)
		if not part.is_empty():
			return part
	return {}

func _run() -> void:
	var data := LocationData.new()
	data.latitude = 60.1458
	data.longitude = 24.9873
	data.country = "FI"
	data.grid_size = 49
	data.heights.resize(49 * 49)
	data.heights.fill(4.0)
	data.water_level = -3.0
	data.quality_preset = RenderSettings.Preset.HIGH
	var parsed := OsmParser.parse_features(FileAccess.get_file_as_string("res://tests/fixtures/suomenlinna.json"), data.latitude, data.longitude)
	data.buildings = parsed["buildings"]
	data.barriers = parsed["barriers"]
	var bastion := _find(data.buildings, "way:24916984")
	var bunker := _find(data.buildings, "way:1258416267")
	var part := _find(data.buildings, "way:1258416265")
	var orphan := _find(data.buildings, "way:1258400727")
	var occupied := _find(data.buildings, "way:170492948")
	var home := _find(data.buildings, "way:24907663")
	var outside := _find(data.buildings, "way:810458465")
	var court := _find(data.buildings, "relation:2268361")
	var beacon := _find(data.buildings, SuomenlinnaSite.BEACON)
	_check(str(beacon.get("fortress_form", "")) == "beacon", "southern beacon must use the small white navigation model")
	_check(not (parsed["landmarks"] as Array).any(func(c: Dictionary) -> bool:
		return str(c.get("archetype", "")) == "lighthouse" and Vector2(float(c["x"]), float(c["z"])).distance_to(Vector2(float(beacon["x"]), float(beacon["z"]))) < 3.0), "southern beacon must not duplicate a generic striped lighthouse")
	var gate := _find(data.buildings, SuomenlinnaSite.GATE)
	_check(str(bastion.get("defensive_works", "")) == "bastion" and SuomenlinnaFortress.accepts(bastion), "mapped bastion needs fortress geometry")
	_check(str(bunker.get("casemate", "")) == "yes" and str(bunker.get("bunker_type", "")) == "gun_emplacement", "casemate metadata must survive")
	_check(SuomenlinnaFortress.accepts(part), "nested defensive part must retain its identity and classification")
	_check(SuomenlinnaFortress.accepts(orphan) and bool(orphan.get("orphan_part", false)), "orphaned bastion must remain a defensive mass")
	_check(not SuomenlinnaFortress.accepts(occupied), "occupied Tenalji hall retains its building fabric")
	_check(not SuomenlinnaFortress.accepts(home) and is_equal_approx(float(home.get("height", 0.0)), 12.4), "actual homes retain explicit dimensions")
	_check(not SuomenlinnaFortress.accepts(outside) and not bool(outside.get("suomenlinna", false)), "Vallisaari stays outside the correction")
	_check(not (court.get("holes", []) as Array).is_empty() and SuomenlinnaFortress.accepts(court), "ravelin courtyard must survive relation parsing")
	_check(str(gate.get("fortress_form", "")) == "gate", "King's Gate is identified at its mapped site")
	_check(SuomenlinnaSite.query(48.85, 2.35, 1200) == "" and SuomenlinnaSite.query(data.latitude, data.longitude, 1200).contains('"defensive_works"'), "extra query is geographically bounded")
	var ground := GroundTruth.new(data)
	var surface := PackedFloat32Array()
	surface.resize(401 * 401)
	surface.fill(9.0)
	SuomenlinnaSite.grade_gate(surface, 401, 6.0, data.buildings, data.latitude, data.longitude)
	var gate_point := WorldScale.xz_from_latlon(60.1395806, 24.9899411, data.latitude, data.longitude)
	var gx := roundi((gate_point.x + 1200.0) / 6.0)
	var gz := roundi((gate_point.y + 1200.0) / 6.0)
	_check(surface[gz * 401 + gx] < 3.0 and is_equal_approx(surface[0], 9.0), "gate clearance must lower only its terrace and apron")
	var ctx := BuildingHeights._height_context(data)
	BuildingMasses.begin_build()
	var ordinary_look := BuildingHeights._look_for(occupied, ctx)
	_check(int(ordinary_look["storeys"]) <= 2 and str(ordinary_look["pattern"]) == "punched", "untyped occupied halls use restrained historic defaults")
	var home_mass: Dictionary = BuildingMasses.plan(home, ctx)[0]
	_check(absf(float(home_mass["wall_m"]) + float(home_mass["rh_m"]) - 12.4) < 0.01, "tagged residential height wins")
	_check(str(home_mass["shape"]) == "hipped" and str(home_mass["b_eff"]["colour"]) == "#d4c2a0", "mapped roofs and colours win")
	var lm := SuomenlinnaFortress.accumulator()
	var original_ring: PackedVector2Array = bastion["footprint"].duplicate()
	var built := 0
	for b in data.buildings:
		for mass in BuildingMasses.plan(b, ctx):
			var did_build := SuomenlinnaFortress.build_mass(lm, mass, data, ground)
			_check(did_build == SuomenlinnaFortress.accepts(mass["b_eff"]), "every defensive mass must bypass generic apartment rendering")
			if did_build:
				built += 1
				print("DEFENSE ", mass["b_eff"].get("osm_id", ""), " ", mass["b_eff"].get("fortress_form", ""))
	_check(built >= 6, "fixture must build defenses across standalone, nested and orphaned masses")
	_check(bastion["footprint"] == original_ring, "renderer must not mutate mapped footprints")
	var holder := Node3D.new()
	SuomenlinnaFortress.finish(lm, holder, data.quality_preset)
	_check(holder.has_node("SuomenlinnaFortress/Fortress_Grass") and holder.has_node("SuomenlinnaFortress/Fortress_Stone"), "defenses need grass and masonry surfaces")
	var centre := RingGeometry.interior_point(court["holes"][0])
	_check(not _hits(holder, centre, "Fortress_Grass"), "grass roof must not fill the courtyard")
	var court_roof := false
	var court_box := RingGeometry.aabb(court["footprint"])
	for x in 12:
		for z in 12:
			var probe := court_box.position + court_box.size * Vector2((float(x) + 0.5) / 12.0, (float(z) + 0.5) / 12.0)
			if SuomenlinnaFortress._inside(probe, court["footprint"], court["holes"]):
				court_roof = court_roof or _hits(holder, probe, "Fortress_Grass")
	_check(court_roof, "narrow courtyard defenses must still have a grass roof")
	var gate_at := Vector2(float(gate["x"]), float(gate["z"]))
	_check(_hits(holder, gate_at, "Fortress_Path"), "terrace must occupy the mapped gate site")
	var triangles := 0
	for node in holder.get_child(0).get_children():
		triangles += (node as MeshInstance3D).mesh.surface_get_array_len(0) / 3
	_check(triangles < 150000, "fortress fixture exceeds the triangle budget")
	var outlines := SuomenlinnaSite.rings(data.buildings)
	_check(SuomenlinnaFortress.owns_bank(original_ring[0], original_ring[1], outlines), "coincident shore faces must yield to the bastion")
	_check(not SuomenlinnaFortress.owns_bank(Vector2(1000, 1000), Vector2(1010, 1000), outlines), "unrelated shoreline must remain")
	var tagged := bunker.duplicate()
	tagged["height"] = 7.2
	tagged["height_source"] = "tag_height"
	_check(is_equal_approx(SuomenlinnaFortress.height(tagged), 7.2), "mapped fortification heights win")
	var church := LandmarkBuilder.build("suomenlinna_fortress")
	var bounds := AABB()
	var first := true
	for mesh in LandmarkBuilder.parts(church):
		var box: AABB = mesh.transform * mesh.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	_check(bounds.size.x < 45.0 and bounds.size.z < 40.0 and absf(bounds.end.y - 42.0) < 0.1, "church must retain its lighthouse height without the fake adjacent fortress")
	church.free()
	holder.free()
	BuildingMasses.end_build()
	if failures.is_empty():
		print("SUOMENLINNA OK: metadata, inhabited fabric, courtyards, mapped heights, gate, ownership; %d masses / %d triangles" % [built, triangles])
		quit(0)
	else:
		for failure in failures:
			printerr("SUOMENLINNA FAIL: ", failure)
		quit(1)

func _hits(root_node: Node, at: Vector2, mesh_name: String) -> bool:
	for child in root_node.get_children():
		if child is MeshInstance3D and str(child.name) == mesh_name:
			var arrays: Array = child.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for i in range(0, vertices.size(), 3):
				var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3(at.x, 200.0, at.y), Vector3.DOWN,
					vertices[i], vertices[i + 1], vertices[i + 2])
				if hit is Vector3:
					return true
		elif _hits(child, at, mesh_name):
			return true
	return false
