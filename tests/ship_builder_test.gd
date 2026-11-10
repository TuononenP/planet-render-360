extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var d := LocationData.new()
	d.grid_size = 33
	d.heights.resize(33 * 33)
	d.heights.fill(3.0)
	d.centre_elevation_m = 20.0
	d.water_level = 0.5
	d.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-1200,0),Vector2(1200,0),Vector2(1200,1200),Vector2(-1200,1200)])}]
	var ring := PackedVector2Array()
	for p in [Vector2(-20,-3),Vector2(13,-3),Vector2(20,0),Vector2(13,3),Vector2(-20,3)]:
		ring.append((p as Vector2).rotated(0.4) + Vector2(100,60))
	var b := {"kind":"ship", "name":"Mapped test ship", "x":100.0, "z":60.0,
		"size_x":40.0, "size_z":30.0, "footprint":ring, "height":8.0, "height_source":"tag_height", "colour":"red"}
	var f := ShipBuilder.frame(b)
	_check(absf(float(f["length"]) - 40) < 0.01 and absf(float(f["beam"]) - 6) < 0.01,
		"Vessel envelope must use the rotated footprint, not its clamped AABB")
	_check((f["axis"] as Vector2).dot(Vector2.RIGHT.rotated(0.4)) > 0.99, "Narrow mapped end must be the bow")
	var ground := GroundTruth.new(d)
	var expected := ground.water_level_at(100,60)
	for preset in [RenderSettings.Preset.FAST, RenderSettings.Preset.ULTRA]:
		d.quality_preset = preset
		var root := Node3D.new()
		_check(ShipBuilder.build(root,b,d,ground), "Mapped ship must build")
		var top := -INF
		var bottom := INF
		for part in root.get_children():
			_check(part.has_meta("mapped_vessel"), "All vessel parts need their source marker")
			_check(absf(part.position.y - expected) < 0.01, "Ship must use local rendered water datum")
			var arrays: Array = part.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices := PackedInt32Array()
			if arrays[Mesh.ARRAY_INDEX] != null:
				indices = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				indices.resize(vertices.size())
				for i in indices.size():indices[i] = i
			for p in vertices:
				top = maxf(top,p.y)
				bottom = minf(bottom,p.y)
			for i in range(0,indices.size(),3):
				var a := indices[i]
				var c := indices[i+1]
				var e := indices[i+2]
				_check((vertices[e]-vertices[a]).cross(vertices[c]-vertices[a]).dot(normals[a]+normals[c]+normals[e]) >= -0.0001,
					"Vessel surfaces must face their intended normals")
			var material := part.mesh.surface_get_material(0) as StandardMaterial3D
			if preset == RenderSettings.Preset.FAST:
				_check(material.normal_texture == null, "Fast vessels must avoid detail normal maps")
		_check(absf(top-8.0)<0.01 and bottom<0.0, "Tagged top height and immersed hull must survive every tier")
		root.free()
	d.quality_preset = RenderSettings.Preset.HIGH
	d.buildings = [b]
	var built := BuildingBuilder.build_buildings(d,ground)
	_check(built.find_children("MappedShip_*","MeshInstance3D",true,false).size() >= 4,
		"Building pipeline must route ships through the hull builder")
	built.free()
	var untagged := b.duplicate()
	untagged["height_source"] = "default"
	_check(ShipBuilder.height(untagged,40)<10, "An untagged vessel must not inherit apartment heights")
	_check(not ShipBuilder.accepts({"kind":"boathouse"}), "A boathouse remains a building")
	var parsed := OsmTags._building_entry({"building":"ship", "ship:type":" Tall-Ship "}, ring,
		OsmGeometry._ring_aabb(ring))
	_check(parsed.get("vessel_kind") == "tall_ship", "Mapped vessel types must normalize at the parser boundary")
	var ordinary := OsmTags._building_entry({"building":"boathouse"}, ring, OsmGeometry._ring_aabb(ring))
	_check(not ordinary.has("vessel_kind"), "Ordinary buildings must not gain vessel defaults")
	_check(ShipBuilder.model_for(b, 40.0) == "passenger", "A mapped 40 m ship is a passenger vessel")
	_check(ShipBuilder.model_for(b, 150.0) == "liner", "A mapped 150 m ship is a cruise liner")
	_check(ShipBuilder.height(untagged, 150.0) >= 22.0, "An untagged liner needs liner-scale height")
	_check(ShipBuilder.model_for({"kind":"boat","vessel_kind":"motor"}, 12.0) == "motor_yacht", "A 12 m boat is a motor yacht")
	_check(ShipBuilder.model_for({"kind":"boat","vessel_kind":"motor"}, 6.0) == "runabout", "A 6 m boat is a day boat")
	_check(ShipBuilder.model_for({"kind":"ship","vessel_kind":"sailing"}, 12.0) == "sail_yacht", "A sailing 12 m vessel is a yacht")
	_check(ShipBuilder.model_for({"kind":"ship","vessel_kind":"tall_ship"}, 60.0) == "tall_ship", "A sailing 60 m vessel is a tall ship")
	for row in [["container_ship", "container"], ["bulk_carrier", "bulk"], ["general_cargo", "general"], ["oil_tanker", "tanker"]]:
		var cargo := {"kind":"ship", "vessel_kind": row[0]}
		_check(ShipBuilder.model_for(cargo, 180.0) == "cargo" and ShipBuilder.variant_for(cargo) == row[1],
			"A mapped %s is a %s cargo ship" % row)
	_check(ShipBuilder.model_for({"kind":"ship","vessel_kind":"ro_pax"}, 180.0) == "cruise_ferry", "A mapped ro-pax is a cruise ferry")
	_check(ShipBuilder.model_for({"kind":"ship","vessel_kind":"ferry"}, 60.0) == "passenger", "A short ferry stays a passenger ship")
	_check(ShipBuilder.variant_for(b) == "", "Untyped vessels are no cargo ships")
	var town := LocationData.new()
	var mast := b.duplicate()
	mast["height"] = 120.0
	town.buildings = [mast,mast,mast]
	_check(int(BuildingHeights._height_context(town)["tagged_n"]) == 0, "Masts must not pollute town height estimates")
	if failures.is_empty():
		print("SHIP BUILDER OK: map envelope, bow, water datum, heights, normals, tiers and pipeline")
		quit(0)
	else:
		for failure in failures:printerr("SHIP BUILDER FAIL: ",failure)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):failures.append(message)
