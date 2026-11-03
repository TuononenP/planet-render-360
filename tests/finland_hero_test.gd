extends SceneTree

## Offline regression coverage for Finland era/district rules, facade
## relief, Ultra wires and their draw budget, March, ice, and street snow.
var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _data() -> LocationData:
	var data := LocationData.new()
	data.latitude = 60.176
	data.longitude = 24.805
	data.country = "FI"
	data.grid_size = 32
	data.heights.resize(1024)
	data.heights.fill(5.0)
	data.water_level = -3.0
	data.climate = {"t_warm_c": 16.5, "t_cold_c": -4.0, "precip_mm": 650.0}
	data.quality_preset = RenderSettings.Preset.ULTRA
	return data

func _run() -> void:
	_eras()
	_relief()
	_climate()
	_wires_and_snow()
	if failures.is_empty():
		print("FINLAND HERO OK: eras, districts, relief, March, partial ice, wires <=12 calls, street snow")
		quit(0)
	else:
		for f in failures:
			printerr("FINLAND HERO FAIL: ", f)
		quit(1)

func _eras() -> void:
	for row in [[60.206, 24.872, "helsinki"], [60.1757, 24.805, "espoo"], [60.185, 24.828, "espoo"],
			[60.21, 25.083, "helsinki"], [60.237, 25.083, "helsinki"], [60.1694, 24.9522, "helsinki"]]:
		_check(CityStyles.region_at(row[0], row[1]) == row[2], "zone at %s" % [row])
	var base := {"lv": 6, "year": 0, "roof": "hipped", "area": 700.0,
		"heritage": false, "dist": 4.0, "district": "", "arch": ""}
	for row in [["house", "", "helsinki_suburb"], ["house", "helsinki_wood", "helsinki_wood"],
			["apartments", "helsinki_classicism", "helsinki_classicism"],
			["apartments", "helsinki", "helsinki"], ["apartments", "helsinki_midrise", "helsinki_midrise"],
			["apartments", "helsinki_element", "helsinki_element"]]:
		var cues := base.duplicate()
		cues["district"] = row[1]
		_check(BuildingEra._rules("helsinki", row[0], cues) == row[2], "Helsinki era %s" % [row])
	for row in [["tapiola", "tapiola"], ["otaniemi", "otaniemi"], ["espoo_modern", "espoo_modern"]]:
		var cues := base.duplicate()
		cues["district"] = row[0]
		_check(BuildingEra._rules("espoo", "apartments", cues) == row[1], "Espoo era %s" % [row])
	var ctx := {"cores": [Vector2.ZERO], "districts": []}
	for row in [[1925, "helsinki_classicism"], [1975, "helsinki_element"], [2005, "helsinki_midrise"]]:
		var b := {"x": 4000.0, "z": 0.0, "levels": 6, "start_year": row[0]}
		_check(BuildingEra.refine("helsinki", "apartments", b, ctx, 0.4, 600.0) == row[1], "dated Finnish era %s" % [row])
	var recent_shop := {"x": 200.0, "z": 0.0, "levels": 0, "start_year": 2016}
	_check(BuildingEra.refine("helsinki", "commercial", recent_shop, ctx, 0.4, 200.0) == "helsinki_midrise",
		"recent unheighted shop must not become a tower")
	var suburban := {"x": 4000.0, "z": 0.0, "levels": 2, "start_year": 1850}
	_check(BuildingEra.refine("helsinki", "house", suburban, ctx, 0.4, 100.0) != "helsinki_empire", "suburban house is not Empire")
	var core := {"x": 100.0, "z": 0.0, "levels": 3, "start_year": 1840, "heritage": true}
	_check(BuildingEra.refine("helsinki", "apartments", core, ctx, 0.4, 400.0) == "helsinki_empire", "historic core is Empire")

func _relief() -> void:
	var sp := {"a": Vector2.ZERO, "b": Vector2(12, 0), "dir": Vector2.RIGHT,
		"n": Vector2(0, -1), "first": true, "last": true, "len_m": 12.0}
	var kit := ReliefKit.new()
	var stone := ReliefKit.flat("#999088")
	FinlandRelief.turret(kit, sp, {"top": 20.0}, stone)
	FinlandRelief.plinth(kit, sp, [{"y0": 0.0, "y1": 3.0}], 0.4)
	FacadeRelief._deep_balcony(kit, Vector2(5, 0), Vector3.RIGHT, Vector3.BACK, 2.4, 3.0, stone, true, true)
	var root_node := Node3D.new()
	kit.flush(root_node, "TestRelief")
	_check(root_node.get_child_count() == 1, "relief merges into one mesh")
	var mesh := (root_node.get_child(0) as MeshInstance3D).mesh
	_check(mesh.get_surface_count() >= 4, "granite, tower roof, balcony glass and frames")
	_check(mesh.get_aabb().end.y >= 26.4, "turret rises above eaves")
	root_node.free()
	var dome_kit := ReliefKit.new()
	FinlandRelief.corner_dome(dome_kit, sp, {"top": 20.0}, stone)
	var dome_root := Node3D.new()
	dome_kit.flush(dome_root, "CornerDome")
	_check(dome_root.get_child_count() == 1, "corner dome creates relief geometry")
	if dome_root.get_child_count() > 0:
		var dome_mesh := (dome_root.get_child(0) as MeshInstance3D).mesh
		_check(dome_mesh.get_surface_count() == 2 and dome_mesh.get_aabb().end.y > 23.0,
			"corner drum and copper dome rise above the eaves")
	dome_root.free()

func _climate() -> void:
	var data := _data()
	data.climate["t_cold_c"] = -2.5
	_check(ClimateModel.biome(data) == "boreal", "Nordic threshold margin stays boreal")
	data.climate["t_cold_c"] = -4.0
	_check(ViewLink.season_for_date({"month": 3}, data.latitude, data) == LocationData.Season.WINTER, "freezing March remains winter")
	data.climate["t_monthly_c"] = [0.0, 0.0, 2.0, 5.0, 10.0, 15.0, 18.0, 17.0, 12.0, 7.0, 3.0, 1.0]
	_check(ViewLink.season_for_date({"month": 3}, data.latitude, data) == LocationData.Season.SPRING, "warm March is spring")
	data.season = LocationData.Season.WINTER
	var a := ClimateModel.ice_amount(data)
	_check(a > 0.0 and a < 1.0, "normal Finnish winter has partial freeze potential")
	data.climate["t_cold_c"] = -8.0
	_check(ClimateModel.ice_amount(data) > a, "colder winter increases ice")
	_check(WaterShader.CODE.contains("local_ice(seav") and WaterShader.CODE.contains("ice_cover"), "ice varies locally with shore/depth proxy")
	_check(WaterSurface.baltic(60.17, 24.95) and WaterSurface.baltic(59.32, 18.06)
		and not WaterSurface.baltic(59.9, 10.7), "Baltic colour includes Stockholm and Helsinki but excludes Oslo")
	for pair in TreeSpecies.mix("boreal", "street"):
		_check(str(pair[0]) in ["lime", "birch", "maple", "rowan"], "boreal street species %s" % str(pair[0]))
	for name in ["maple", "rowan"]:
		_check(TreeSpecies.spec(name).has("trunk_r"), "complete %s tree row" % name)

func _wires_and_snow() -> void:
	var data := _data()
	data.railways = [OsmTags._rail_entry({"railway": "tram", "electrified": "contact_line"},
		PackedVector2Array([Vector2(-80, 0), Vector2(80, 0)]))]
	var ground := GroundTruth.new(data)
	var node := Node3D.new()
	var stats := OverheadWires.build(node, data, ground)
	_check(int(stats["spans"]) > 0 and int(stats["poles"]) > 0, "electrified tram has wires and fallback poles")
	_check(int(stats["draw_calls"]) <= OverheadWires.MAX_DRAW_CALLS, "wire draw-call budget")
	node.free()
	data.quality_preset = RenderSettings.Preset.HIGH
	_check(OverheadWires.plan(data, ground).is_empty(), "wires Ultra only")
	data.quality_preset = RenderSettings.Preset.ULTRA
	data.railways[0]["electrified"] = "no"
	_check(OverheadWires.plan(data, ground).is_empty(), "non-electrified track has no wire")
	data.railways = []
	data.roads = [OsmTags._road_entry({"highway": "residential", "width": "8"},
		PackedVector2Array([Vector2(-70, 20), Vector2(70, 20)]))]
	data.country = "SE"
	data.buildings = [{"x": 0.0, "z": 20.0, "height": 12.0}]
	_check(OverheadWires.plan(data, ground).any(func(span: Dictionary) -> bool: return bool(span["lamp"])), "Swedish urban roads have span lamps")
	data.country = "FI"
	data.season = LocationData.Season.WINTER
	node = Node3D.new()
	_check(Snowbanks.build(node, data, ground) > 0, "snowy roads have ploughed ridges")
	node.free()
	data.season = LocationData.Season.SUMMER
	node = Node3D.new()
	_check(Snowbanks.build(node, data, ground) == 0, "summer has no snowbanks")
	node.free()
	_check((ParkedCars._material("body") as ShaderMaterial).shader.code.contains("snow_cover"), "snow on car roofs")
	_check((StreetFurniture._material("wood") as ShaderMaterial).shader.code.contains("snow_cover"), "snow on benches")
	_check(StreetProps.lamp_family("nordic", "FI") == "span", "Finnish span lamps")
	_check(StreetFurniture.furniture_family("nordic", "FI") == "nordic", "Nordic furniture")
