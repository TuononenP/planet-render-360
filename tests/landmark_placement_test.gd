extends SceneTree

## Offline placement guards: sea versus inland rivers, absent water data,
## authored relief, absolute datums, secondary landmarks and camera aim.

const SEA_TYPES := ["alcatraz", "burj_al_arab", "allas_sea_pool", "golden_gate", "tower_bridge", "brooklyn_bridge",
	"sydney_harbour_bridge", "oresund_bridge", "akashi_kaikyo_bridge", "forth_bridge", "erasmus_bridge",
	"ponte_25_abril", "rialto_bridge", "bosphorus_bridge", "lions_gate_bridge", "verrazzano_bridge",
	"tsing_ma_bridge", "itsukushima_torii", "bay_bridge_west", "bay_bridge_east"]
const RIVER_TYPES := ["chain_bridge", "charles_bridge", "ponte_vecchio", "stari_most", "lumberjacks_candle_bridge"]
var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _data(type: String, height: float, water: float) -> LocationData:
	var d := LocationData.new()
	var e := LocationData.entry_for_type(type)
	d.latitude = float(e["lat"])
	d.longitude = float(e["lon"])
	d.landmark_type = type
	d.has_landmark_site = true
	d.landmark_lat = d.latitude
	d.landmark_lon = d.longitude
	d.grid_size = 49
	d.heights.resize(49 * 49)
	d.heights.fill(height)
	d.centre_elevation_m = 80.0
	d.water_level = water
	return d

func _run() -> void:
	for e in LocationData.landmarks():
		var base := str(e.get("base", "ground"))
		_check(base in ["ground", "water", "sea", "absolute"], "%s: unknown base %s" % [e["type"], base])
		if base == "absolute":
			_check(e.has("base_asl_m") and is_finite(float(e.get("base_asl_m", NAN))), "%s: absolute base needs a finite ASL elevation" % e["type"])
	for type in SEA_TYPES:
		var e := LocationData.entry_for_type(type)
		_check(str(e.get("base", "")) == "sea", "%s must use sea level, not the DEM fallback water datum" % type)
		var d := _data(type, -70.0, -600.0)
		var g := GroundTruth.new(d)
		_check(absf(g.asl_y(TerrainBuilder._hero_y(d, g, 0, 0, e, 20))) < 0.001, "%s: sea base must be ASL zero" % type)
		_check(g.asl_y(View360.eye_y(d, g, View360.spawn_xz(d))) >= 30.0, "%s: an offline coastal arrival must not be underwater" % type)
		var focus := LandmarkVisit.from_registry(e)
		_check(absf(g.asl_y(View360.focus_point(d, g, focus).y) - maxf(float(e["height_m"]), 30.0) * 0.5) < 0.01,
			"%s: focus must be measured from the model origin" % type)
	# Water presence is known from the registry even when OSM failed.
	var coastal := _data("golden_gate", -70.0, -600.0)
	var sea := WaterBuilder.build_water(coastal, GroundTruth.new(coastal))
	_check(sea.get_child_count() > 0, "a coastal landmark still needs its ocean when OSM is absent")
	sea.free()
	var tidal := _data("itsukushima_torii",110.0,20.0)
	tidal.land_polygons = [{"class":"water","tidal":true,"points":PackedVector2Array([
		Vector2(-150,-150),Vector2(150,-150),Vector2(150,150),Vector2(-150,150)])}]
	var tidal_ground := GroundTruth.new(tidal)
	_check(absf(tidal_ground.asl_y(tidal_ground.water_level_at(0,0))-WaterBuilder.SEA_LEVEL_M)<0.01,
		"tidal bays must retain the sea datum even when their DEM banks are high")
	coastal.waterways = [{"class": "coastline", "points": PackedVector2Array([
		Vector2(0,-2000), Vector2(0,2000)])}]
	coastal.landmark_candidates = [{"type": "alcatraz", "base": "sea", "x": 2500.0, "z": 0.0}]
	var shore_ground := GroundTruth.new(coastal)
	sea = WaterBuilder.build_water(coastal, shore_ground)
	_check(sea.has_node("IslandSea"), "canonical shoreline water must also fill the distant island terrain opening")
	var measured_swell := false
	for child in sea.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			var lift: Variant = child.material_override.get_shader_parameter("swell_lift")
			if lift != null:
				measured_swell = measured_swell or is_zero_approx(float(lift))
	if shore_ground.shoreline != null and shore_ground.shoreline.ready:
		_check(measured_swell, "carved shoreline water must not retain the legacy 1.3 m upward wave offset")
	sea.free()
	var small := _data("itsukushima_torii", -70.0, -600.0)
	_check(WorldScale.xz_from_latlon(34.297297, 132.318135, small.latitude, small.longitude).length() < 1.0,
		"the torii belongs at its offshore gate footprint, not inside the shrine")
	_check(absf(View360.spawn_xz(small).length() - 180.0) < 0.01, "small torii arrival must stay close enough to see it")
	var tall := _data("eiffel", 110.0, 20.0)
	_check(absf(View360.spawn_xz(tall).length() - 800.0) < 0.01, "Eiffel retains its established 800 m framing")
	var bare := _data("golden_gate", -70.0, -600.0)
	var bare_ground := GroundTruth.new(bare)
	var square := PackedVector2Array([Vector2(-5,-5), Vector2(5,-5), Vector2(5,5), Vector2(-5,5)])
	_check(bare_ground.asl_y(BuildingBuilder._mass_base(bare_ground, square, Vector2.ZERO, bare_ground.render_y(0))) >= 2.8 - 0.01,
		"coastal building floors clear the legacy wave crest without water polygons")
	# Low pier land can be dry at the static datum yet covered by waves.
	for height in [0.5,0.67,1.22]:
		var pier := _data("golden_gate",height,0.5)
		pier.land_polygons = [{"class":"water","tidal":true,"points":PackedVector2Array([
			Vector2(100,100),Vector2(200,100),Vector2(200,200),Vector2(100,200)])}]
		var pg := GroundTruth.new(pier)
		var foundation := BuildingFoundation.sample(pg,square,Vector2.ZERO,pg.render_y(WaterBuilder.SEA_LEVEL_M))
		_check(bool(foundation["raised"]) and pg.asl_y(foundation["floor"]) >= 1.99,
			"a low pier above static sea must still clear the visible wave crest")
	var sloped := _data("golden_gate",0.0,0.5)
	for z in 49:
		for x in 49:
			sloped.heights[z*49+x] = 1.6 + (float(x)-24.5)*0.3
	var sg := GroundTruth.new(sloped)
	var pier_ring := PackedVector2Array([Vector2(-150,-150),Vector2(150,-150),Vector2(150,150),Vector2(-150,150)])
	var slab := BuildingFoundation.sample(sg,pier_ring,Vector2.ZERO,sg.render_y(0.5))
	for corner in pier_ring:
		_check(float(slab["floor"]) >= sg.height_at_world(corner.x,corner.y)-0.001,
			"a low pier slab must clear its higher dry corners instead of burying the lower storey")
	var waterfront := Node3D.new()
	var ctx := BuildingBuilder._height_context(bare)
	ctx["sea_y"] = bare_ground.render_y(0.5)
	var building := {"kind": "retail", "levels": 3, "name": "Waterfront shop"}
	var look := BuildingBuilder._look_for(building, ctx)
	BuildingBuilder._extrude_polygon(waterfront, bare, bare_ground, square, 12.0,
		Vector2.ZERO, "flat", 0.0, building, ctx, 3, look, false)
	var vertices := 0
	for child in waterfront.get_children():
		if child is MeshInstance3D and not bool(child.get_meta("water_foundation", false)):
			for surface in child.mesh.get_surface_count():
				for vertex in child.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
					vertices += 1
					_check(bare_ground.asl_y(vertex.y) >= 3.3 - 0.01,
						"occupied walls must clear the visible wave crest, without a buried ground-storey or facade relief")
	_check(vertices > 0, "waterfront fixture must generate walls and a roof")
	_check(waterfront.has_node("WaterFoundationDeck") and waterfront.has_node("WaterFoundationPiles"),
		"raised waterfront buildings need a platform and supports, not floating walls")
	waterfront.free()
	bare = _data("chain_bridge", -10.0, -3.0)
	bare_ground = GroundTruth.new(bare)
	_check(absf(BuildingBuilder._mass_base(bare_ground, square, Vector2.ZERO) + 10.0) < 0.01,
		"a dry depression must not be lifted to an unobserved fallback water datum")
	for type in RIVER_TYPES:
		var e := LocationData.entry_for_type(type)
		_check(str(e.get("base", "")) == "water", "%s must retain its inland river elevation" % type)
		var d := _data(type, 110.0, 20.0)
		var g := GroundTruth.new(d)
		_check(not LandmarkTerrain.has_sea(d), "%s is not an ocean site" % type)
		_check(absf(g.asl_y(TerrainBuilder._hero_y(d, g, 0, 0, e, 15)) - 110.0) < 0.01,
			"%s: missing water polygons use local DEM, not the low global datum" % type)
		_check(absf(g.asl_y(TerrainBuilder._hero_y(d, g, 2500, 0, e, 15)) - 110.0) < 0.01,
			"%s: a distant river bridge uses its own site elevation" % type)
		d.far_grid_size = 4
		d.far_heights.resize(16)
		d.far_heights.fill(140.0)
		_check(absf(g.asl_y(TerrainBuilder._hero_y(d, g, 2500, 0, e, 15)) - 140.0) < 0.01,
			"%s: available distant DEM must replace the city's clamped edge height" % type)
		d.land_polygons = [{"class": "water", "points": PackedVector2Array([
			Vector2(-150,-150), Vector2(150,-150), Vector2(150,150), Vector2(-150,150)])}]
		g = GroundTruth.new(d)
		_check(absf(TerrainBuilder._hero_y(d, g, 0, 0, e, 15) - g.water_level_at(0, 0)) < 0.01,
			"%s: mapped bank-levelled water wins over DEM fallback" % type)
		var footprint := PackedVector2Array([Vector2(-10,-10), Vector2(10,-10), Vector2(10,10), Vector2(-10,10)])
		_check(BuildingBuilder._mass_base(g, footprint, Vector2.ZERO) - g.water_level_at(0, 0) >= 1.5 - 0.01,
			"%s: accepted waterfront floors must clear waves above the static water level" % type)
	# Deliberately steep ground exposes differences in the primary and
	# candidate footprint sampling. Candidates carry only copied fields.
	for type in ["mont_saint_michel", "edinburgh_castle", "monks_mound", "hoover_dam", "burj_al_arab"]:
		var d := _data(type, 110.0, 20.0)
		for z in 49:
			for x in 49:
				d.heights[z * 49 + x] += float(x + z)
		var g := GroundTruth.new(d)
		var e := LocationData.entry_for_type(type)
		var primary := TerrainBuilder._landmark(d, g)
		var extra := Node3D.new()
		d.landmark_candidates = [{"type": type, "x": 0.0, "z": 0.0,
			"base": e.get("base", "ground"), "clear_m": e.get("clear_m", 68.0)}]
		TerrainBuilder._landmark_candidates(extra, d, g)
		_check(extra.get_child_count() == 1 and absf((extra.get_child(0) as Node3D).position.y - primary.position.y) < 0.01,
			"%s: primary and secondary placement must agree" % type)
		var focus := LandmarkVisit.from_registry(e)
		_check(absf(View360.focus_point(d, g, focus).y - primary.position.y - maxf(float(e["height_m"]), 30.0) * 0.5) < 0.01,
			"%s: camera aim must include the model's placement offset" % type)
		if type == "hoover_dam":
			_check(absf(g.asl_y(primary.position.y) - 375.5) < 0.01, "Hoover crest must not gain an extra 221 m")
		if type == "monks_mound":
			_check(absf(g.asl_y(primary.position.y) - 130.0) < 0.01, "Monks Mound starts at its 130 m base contour")
			var low_ground := GroundTruth.new(_data(type, 110.0, 20.0))
			var mound := TerrainBuilder._landmark(_data(type, 110.0, 20.0), low_ground)
			_check(mound.has_node("Model/GroundSkirt"), "the mound must join lower surrounding terrain without a floating rim")
			mound.free()
		primary.free()
		extra.free()
	# Only covered terrain may disappear; surrounding ground must remain.
	for type in LandmarkTerrain.RELIEFS:
		var d := _data(type, 110.0, 20.0)
		var verts := PackedVector3Array([Vector3(-5,180,-5), Vector3(5,180,-5), Vector3(0,180,5),
			Vector3(500,110,500), Vector3(510,110,500), Vector3(500,110,510)])
		_check(LandmarkTerrain.cut_indices(d, verts, PackedInt32Array([0,1,2,3,4,5])) == PackedInt32Array([3,4,5]),
			"%s: authored relief must replace interior DEM without cutting surrounding land" % type)
		var g := GroundTruth.new(d)
		_check(View360.eye_y(d,g,Vector2.ZERO) > LandmarkTerrain.ground_y(d,g,Vector2.ZERO), "%s: camera stays above its authored ground" % type)
	if failures.is_empty():
		print("LANDMARK PLACEMENT OK: %d sea sites, %d inland bridges, authored relief, absolute datums, candidates and aim" % [SEA_TYPES.size(), RIVER_TYPES.size()])
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK PLACEMENT FAIL: ", f)
		quit(1)
