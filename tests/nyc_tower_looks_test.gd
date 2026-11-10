extends SceneTree

## New York's tall buildings read as the tower types of their time, and the
## glazing types cost a fixed number of distant materials.

var failures: Array[String] = []

func _init() -> void:
	_selection()
	_application()
	_materials()
	_plant_floors()
	_setbacks()
	_tops()
	_other_cities()
	for f in failures:
		printerr("NYC TOWER LOOKS FAIL: ", f)
	print("nyc_tower_looks_test: %s" % ("FAIL" if not failures.is_empty() else "PASS"))
	quit(1 if not failures.is_empty() else 0)

func _look(era: String, wall: String) -> Dictionary:
	return {"city": "new_york", "kind": "commercial", "era": era, "wall_set": wall,
		"pattern": "curtain" if wall == "glass" else "punched", "storeys": 40, "floor_h": 3.8,
		"bay_m": 3.0}

func _expect(b: Dictionary, look: Dictionary, area: float, want: String, why: String) -> void:
	var got := NycTowerLooks.pick(b, look, area, 0.42)
	if got != want:
		failures.append("%s: got '%s', want '%s'" % [why, got, want])

func _selection() -> void:
	var glass := _look("nyc_glass", "glass")
	var prewar := _look("nyc_prewar", "limestone")
	_expect({"material": "metal", "levels": 70}, glass, 1200.0, "silver_reflective", "mapped metal")
	_expect({"material": "glass", "start_year": 1958}, glass, 1200.0, "intl_aluminium", "1958 glass")
	if NycTowerLooks._glass_of(1968, 0.2) != "intl_bronze" or NycTowerLooks._glass_of(1968, 0.8) != "intl_aluminium":
		failures.append("1960s glass splits between bronze and the aluminium grid")
	_expect({"material": "glass", "start_year": 1980}, glass, 1200.0, "silver_reflective", "1980 glass")
	_expect({"material": "glass", "start_year": 2005}, glass, 1200.0, "lowe_blue", "2005 glass")
	_expect({"material": "glass", "start_year": 2018}, glass, 1200.0, "clear_fin", "2018 glass")
	_expect({"material": "limestone", "start_year": 1930}, prewar, 1200.0, "prewar_lime", "1930 limestone")
	_expect({"material": "limestone", "start_year": 2016, "levels": 80}, glass, 600.0, "pencil_limestone", "pencil limestone")
	_expect({"material": "concrete", "start_year": 2015, "levels": 85}, glass, 500.0, "pencil_concrete", "pencil concrete")
	_expect({"material": "brick"}, _look("nyc_prewar", "brick"), 900.0, "prewar_buff", "prewar brick")
	_expect({"material": "brick", "start_year": 1985}, glass, 900.0, "", "modern brick keeps its era's finish")
	_expect({}, _look("nyc_glass", "concrete"), 900.0, "", "undated concrete keeps its era's finish")

func _application() -> void:
	var look := _look("nyc_glass", "glass")
	var low := NycTowerLooks.apply({"levels": 5, "height": 18.0}, look, 400.0, 0.3)
	if low.has("tower_look"):
		failures.append("a five-storey building is not a tower")
	var other := look.duplicate()
	other["city"] = "san_francisco"
	if NycTowerLooks.apply({"levels": 40}, other, 900.0, 0.3).has("tower_look"):
		failures.append("the tower looks are New York's only")
	if NycTowerLooks.apply({"levels": 40, "mapped_landmark": true}, look, 900.0, 0.3).has("tower_look"):
		failures.append("a landmark keeps its own look")
	var solid := NycTowerLooks.apply({"material": "limestone", "start_year": 1930, "levels": 40},
		_look("nyc_prewar", "limestone"), 900.0, 0.3)
	if str(solid.get("pattern", "")) != "pier" or solid.has("curtain"):
		failures.append("a prewar limestone tower takes the pier front")
	# 120 Wall Street: a bare footprint outline (default height) over parts.
	var parted := NycTowerLooks.apply({"start_year": 1930, "height": 10.0,
		"parts": [{"height": 10.0, "levels": 3}, {"height": 115.2, "levels": 34}]},
		_look("nyc_prewar", "limestone"), 900.0, 0.3)
	if str(parted.get("tower_look", "")) != "prewar_lime":
		failures.append("a part-mapped tower is a tower by its tallest part")
	var metal := NycTowerLooks.apply({"material": "metal", "levels": 70}, look, 900.0, 0.3)
	if str(metal.get("wall_set", "")) != "glass" or str(metal.get("curtain", "")) != "silver_reflective":
		failures.append("mapped metal cladding is a reflective wall")
	if str(FacadeMaterials._wall_set({"material": "metal"}, metal, "north_america")) != "glass":
		failures.append("the tower look decides the wall set over the raw tag")

func _plant_floors() -> void:
	if not BuildingWalls.mech_floors(20, 0.3, true).is_empty():
		failures.append("a 20-storey tower has no plant floors")
	var floors := BuildingWalls.mech_floors(70, 0.3, true)
	if floors.size() < 3 or floors[-1] != 69 or floors[-2] != 68 or floors[0] < 20 or floors[0] > 30:
		failures.append("70 storeys need shaft plant floors and a top plant level, got %s" % [floors])
	if 69 in BuildingWalls.mech_floors(70, 0.3, false):
		failures.append("a mass below the roofline has no top plant level")
	var root := Node3D.new()
	var ring := PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)])
	FacadeMaterials.begin_build()
	var facade := FacadeTextures.curtain_distant(1, {"curtain": "lowe_blue"})
	var louvre := FacadeTextures.louvre(1, true)
	BuildingWalls.upper_walls(root, ring, 0.0, 266.0, facade, null, 70,
		{"mech": floors, "louvre": louvre}, [], null, 1.0)
	var band_h := 0.0
	var max_v := 0.0
	for child in root.get_children():
		var mi := child as MeshInstance3D
		var aabb := mi.mesh.get_aabb()
		if mi.material_override == louvre:
			band_h += aabb.size.y
		for uv in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]:
			max_v = maxf(max_v, (uv as Vector2).y)
	if absf(band_h - 3.8 * float(floors.size())) > 3.8 * 2.0:
		failures.append("each plant floor is one storey tall, got %.1f m for %d" % [band_h, floors.size()])
	if max_v > 31.0:
		failures.append("a run between plant floors must count only its own storeys, got v=%.0f" % max_v)
	root.free()

func _tops() -> void:
	var ring := PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)])
	if absf(TowerTop.height_m(100.0) - 4.5) > 0.01 or absf(TowerTop.height_m(600.0) - 14.0) > 0.01:
		failures.append("the penthouse scales with the tower within 4.5-14 m")
	var box := TowerTop.footprint(ring, 0.3)
	var share := absf(RingGeometry.signed_area(box)) / absf(RingGeometry.signed_area(ring))
	if share < 0.34 or share > 0.61:
		failures.append("the penthouse covers 35-60%% of the roof, got %.2f" % share)
	var mat := StandardMaterial3D.new()
	var low := Node3D.new()
	if TowerTop.penthouse(low, ring, 40.0, 40.0, 0.3, mat, mat) or low.get_child_count() != 0:
		failures.append("a 40 m building has no skyline penthouse")
	low.free()
	var root := Node3D.new()
	TowerTop.add(root, ring, 150.0, 150.0, 0.3, mat, mat)
	var top := 0.0
	for child in root.get_children():
		var aabb := (child as MeshInstance3D).mesh.get_aabb()
		top = maxf(top, aabb.position.y + aabb.size.y)
		if child.has_meta("lod_detail"):
			failures.append("a tower top is skyline shape, not near detail")
	if top < 150.0 + TowerTop.height_m(150.0):
		failures.append("the penthouse must stand above the roof")
	root.free()
	var parts := [{"footprint": PackedVector2Array([Vector2(-50, -50), Vector2(50, -50), Vector2(50, 50), Vector2(-50, 50)]), "height": 30.0},
		{"footprint": ring, "height": 260.0}]
	if BuildingMasses._tower_main(parts, {"kind": "commercial"}) != 1:
		failures.append("a mapped tower's roofline is on its shaft, not its podium")
	if BuildingMasses._tower_main(parts, {"kind": "religious"}) != 0:
		failures.append("non-towers keep the largest mass")

func _other_cities() -> void:
	var dubai := {"city": "dubai", "region": "dubai", "kind": "commercial", "era": "dubai_modern",
		"wall_set": "glass", "pattern": "curtain", "storeys": 50, "floor_h": 3.8, "bay_m": 3.0}
	var seen := {}
	for i in 60:
		var out := TowerLooks.apply({"levels": 50}, dubai, float(i) / 60.0)
		if not out.has("curtain"):
			failures.append("a glazed tower abroad takes a glazing type")
			return
		seen[out["curtain"]] = true
	if not seen.has("gold_reflective") or seen.has("green_glass") or seen.size() < 3:
		failures.append("Dubai's glazing mix is the Gulf palette, got %s" % [seen.keys()])
	var tokyo := dubai.duplicate()
	tokyo["city"] = "tokyo"
	tokyo["region"] = "tokyo"
	var asia := {}
	for i in 60:
		asia[TowerLooks.apply({"levels": 50}, tokyo, float(i) / 60.0)["curtain"]] = true
	if not asia.has("green_glass") or asia.has("gold_reflective"):
		failures.append("Tokyo's glazing mix is the East Asian palette, got %s" % [asia.keys()])
	if TowerLooks.apply({"levels": 50, "material": "brick"}, tokyo, 0.3).has("tower_look"):
		failures.append("a mapped brick tower keeps its brick")
	if TowerLooks.apply({"levels": 6, "height": 20.0}, tokyo, 0.3).has("tower_look"):
		failures.append("a six-storey block is not a tower")
	var concrete := tokyo.duplicate()
	concrete["wall_set"] = "concrete"
	concrete["pattern"] = "balcony"
	var slab := TowerLooks.apply({"levels": 40}, concrete, 0.3)
	if str(slab.get("tower_look", "")) != "solid" or slab.has("curtain") or str(slab["wall_set"]) != "concrete":
		failures.append("a concrete tower keeps its finish and earns the tower top")
	var landmark := TowerLooks.apply({"levels": 50, "mapped_landmark": true}, dubai, 0.3)
	if landmark.has("tower_look"):
		failures.append("a landmark keeps its own look")

func _setbacks() -> void:
	var ring := PackedVector2Array([Vector2(-40, -35), Vector2(40, -35), Vector2(40, 35), Vector2(-40, 35)])
	var b := {"footprint": ring, "height_source": "tag_height", "start_year": 1931, "x": 0.0, "z": 0.0}
	var look := {"kind": "commercial", "wall_set": "limestone", "pattern": "pier", "floor_h": 3.6}
	var parts := TowerMassing.stack(b, look, {"total_m": 260.0}, {"fidelity": 3}, "flat")
	if parts.size() < 4:
		failures.append("a 260 m prewar tower needs at least four tiers, got %d" % parts.size())
		return
	if float(parts[0]["height"]) > 40.01:
		failures.append("the street wall stops at about 40 m, got %.0f" % float(parts[0]["height"]))
	var lot := absf(RingGeometry.signed_area(ring))
	var top: Dictionary = parts[-1]
	if absf(RingGeometry.signed_area(top["footprint"])) < lot * TowerMassing.MIN_TOWER_SHARE:
		failures.append("the tower keeps a quarter of the lot")
	if absf(float(top["height"]) - 260.0) > 0.01 or (260.0 - float(top["min_height_m"])) < 0.4 * 220.0:
		failures.append("the top tier keeps the height and the upper shaft")
	var pencil := {"footprint": PackedVector2Array([Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)]),
		"height_source": "tag_height", "levels": 80, "start_year": 2015, "x": 3.0, "z": 9.0}
	if not TowerMassing.stack(pencil, {"kind": "commercial", "wall_set": "glass", "pattern": "curtain", "floor_h": 3.6},
			{"total_m": 300.0}, {"fidelity": 3}, "flat").is_empty():
		failures.append("a pencil tower rises straight from its lot")

func _materials() -> void:
	FacadeMaterials.begin_build()
	var look := _look("nyc_glass", "glass")
	var seen := {}
	for id in FacadeCurtainKit.LOOKS:
		look["curtain"] = id
		look["tower_look"] = id
		for i in 40:
			var m := FacadeMaterials.facade_for_building({"levels": 40}, "north_america", 40, 3, true,
				float(i) / 40.0, look)
			seen[m] = true
			if FacadeMaterials.facade_uv(m).x <= 0.0:
				failures.append("%s distant glass lost its real bays" % id)
				return
	if seen.size() != FacadeCurtainKit.LOOKS.size():
		failures.append("distant glazing must cost one material per type, got %d" % seen.size())
	for pattern in ["pier"]:
		if not FacadeComposer.is_tiled(pattern):
			failures.append("%s must tile by bay and storey" % pattern)
	var pier := NycTowerLooks.apply({"material": "limestone", "start_year": 1930, "levels": 40},
		_look("nyc_prewar", "limestone"), 900.0, 0.3)
	pier["frame"] = Color(0.3, 0.3, 0.3)
	var near := FacadeMaterials.facade_for_building({"levels": 40}, "north_america", 40, 3, false, 0.3, pier)
	if str(near.get_meta("facade_pattern", "")) != "pier":
		failures.append("the pier front must reach the composed tile")
