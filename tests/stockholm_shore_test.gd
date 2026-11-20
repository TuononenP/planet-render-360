extends SceneTree

## Offline Stockholm shore contracts: the unmapped-bank colour, the rail on a
## non-tidal Mälaren hard edge and the granite skerry colour, with other
## cities unchanged. Always run with --headless.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _place(lat: float, lon: float) -> LocationData:
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.grid_size = 32
	data.heights.resize(32 * 32)
	data.heights.fill(3.0)
	data.water_level = -3.0
	# Mälaren: mapped water that is not tidal, with a mapped quay on its bank.
	data.land_polygons = [{"class": "water", "tidal": false, "points": PackedVector2Array([
		Vector2(0, -600), Vector2(600, -600), Vector2(600, 600), Vector2(0, 600)]), "holes": []}]
	data.shore_structures = [{"points": PackedVector2Array([Vector2(0, -500), Vector2(0, 500)]),
		"kind": "quay", "id": "way:quay"}]
	return data

## The apron colour of a bank with no mapped cover, as the builder paints it.
func _bank(data: LocationData, ground: GroundTruth) -> Color:
	ShoreApron._shore_aprons(Node3D.new(), data, ground, [])
	var colors: Array = []
	var k := ShoreApron._apron_append([], [], colors, [], Vector2(-1, 0), Vector2(-8, 0), ground, 1000.0)
	_check(k >= 0, "a dry bank station should be appended")
	return colors[1] if colors.size() == 2 else Color.BLACK

func _ashlar_luma(data: LocationData) -> float:
	var img := (QuayBuilder.stone_material(data).albedo_texture as Texture2D).get_image()
	var sum := 0.0
	for i in 64:
		sum += img.get_pixel((i * 37) % img.get_width(), (i * 91) % img.get_height()).get_luminance()
	return sum / 64.0

func _run() -> void:
	var sto := _place(59.3293, 18.0686)
	var paris := _place(48.8566, 2.3522)
	var hel := _place(60.1699, 24.9384)
	var sto_ground := GroundTruth.new(sto)
	_check(ShoreApron.stockholm(sto) and not ShoreApron.stockholm(paris) and not ShoreApron.stockholm(hel),
		"only Stockholm's zones take the Stockholm shore treatment")
	_check(sto_ground.shoreline != null and sto_ground.shoreline.hard_count() > 0, "the quay fixture should give hard edges")
	# Unknown shore: granite quay stone in Stockholm, the pale sand elsewhere.
	_check(_bank(sto, sto_ground).is_equal_approx(ShoreApron.STOCKHOLM_BANK), "Stockholm's unmapped bank should be dark quay stone")
	_check(ShoreApron.STOCKHOLM_BANK.get_luminance() < WaterBuilder._UNKNOWN_SHORE.get_luminance() * 0.75,
		"the Stockholm bank should be darker than the pale sand fallback")
	_check(_bank(paris, GroundTruth.new(paris)).is_equal_approx(WaterBuilder._UNKNOWN_SHORE), "Paris keeps the sand fallback")
	_check(_bank(hel, GroundTruth.new(hel)).is_equal_approx(WaterBuilder._UNKNOWN_SHORE), "Helsinki keeps the sand fallback")
	_check(_bank(sto, sto_ground).is_equal_approx(ShoreApron.STOCKHOLM_BANK), "the bank colour should not leak between builds")
	# Railings: a non-tidal hard edge is railed in Stockholm only.
	var body: Dictionary = sto_ground.shoreline.domains.bodies[0]
	_check(not bool(body.get("tidal", false)), "the Mälaren fixture is not tidal")
	_check(ShoreRailings.railed_body(body, sto), "a non-tidal Mälaren hard edge should take a rail in Stockholm")
	_check(not ShoreRailings.railed_body(body, paris) and not ShoreRailings.railed_body(body, hel),
		"a non-tidal edge keeps no rail outside Stockholm")
	_check(ShoreRailings.railed_body({"tidal": true}, paris), "a tidal edge keeps its rail everywhere")
	# Bank paint and quay faces: Stockholm's paving and ashlar are darker grey
	# granite; the palette and the generic granite ashlar elsewhere are unchanged.
	_check(ShoreApron.palette_overrides(paris).is_empty() and ShoreApron.palette_overrides(hel).is_empty(),
		"no ground-paint override outside Stockholm")
	var base := GroundMaterial.palette(sto.season)
	var dark := GroundMaterial.palette(sto.season, Color(0, 0, 0, 0), ShoreApron.palette_overrides(sto))
	var urban: int = GroundMaterial.ID["urban"]
	_check(dark.get_pixel(urban, 1).get_luminance() < base.get_pixel(urban, 1).get_luminance() * 0.9,
		"Stockholm's bank and square paving should be darker than the shared pale paving")
	_check(absf(dark.get_pixel(urban, 1).r - ShoreApron.STOCKHOLM_PAVING.r) < 1.5 / 255.0,
		"the Stockholm paving override should reach the palette")
	# The road finishes (quay-side walks, squares) take the same granite.
	RoadBuilder._roads(Node3D.new(), sto, sto_ground)
	_check(RoadBuilder._sett_hex == ShoreApron.STOCKHOLM_SETT.to_html(false) and RoadBuilder._paving_hex == ShoreApron.STOCKHOLM_PAVING.to_html(false),
		"Stockholm's paving and sett finishes should be grey granite")
	RoadBuilder._roads(Node3D.new(), paris, GroundTruth.new(paris))
	_check(RoadBuilder._sett_hex == RoadBuilder.FINISH_HEX["sett"] and RoadBuilder._paving_hex == RoadBuilder.FINISH_HEX["paving"],
		"Paris keeps the shared paving and sett finishes")
	var hamburg := _place(53.5511, 9.9937)
	_check(QuayBuilder.granite_quays(sto) and QuayBuilder.granite_quays(hamburg), "Stockholm and Hamburg quays are granite ashlar")
	_check(_ashlar_luma(sto) < _ashlar_luma(hamburg) * 0.85, "Stockholm's quay ashlar should be darker than the generic granite")
	_check(_ashlar_luma(hamburg) > 0.4 and QuayBuilder.stone_material(hamburg) == QuayBuilder.stone_material(hamburg),
		"another city keeps the generic ashlar")
	# Rounded water corners: Stockholm's mapped water ring is bevelled once (the
	# GroundTruth above did it), never twice, and other cities keep their corners.
	var ring: PackedVector2Array = (sto.land_polygons[0]["points"] as PackedVector2Array)
	_check(bool(sto.land_polygons[0].get("rounded", false)) and ring.size() > 4 and not ring.has(Vector2(0, -600)),
		"Stockholm's water corners should be cut back")
	GroundTruth.new(sto)
	_check((sto.land_polygons[0]["points"] as PackedVector2Array).size() == ring.size(), "rounding must not repeat")
	_check((paris.land_polygons[0]["points"] as PackedVector2Array).size() == 4 and (hel.land_polygons[0]["points"] as PackedVector2Array).size() == 4,
		"other cities' water polygons stay as mapped")
	var circle := PackedVector2Array()
	for i in 12:
		circle.append(Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * 100.0)
	_check(ShoreApron.round_ring(circle, 3.0, 1000.0).size() == 12, "gentle polylines are not rounded")
	# Cliff paint and outcrops: steep ground takes granite in Stockholm only.
	var cliff_sto := GroundMaterial.build(sto, null, Rect2(), false)
	var cliff_par := GroundMaterial.build(paris, null, Rect2(), false)
	_check(cliff_sto.get_shader_parameter("cliff_set") != null and (cliff_sto.get_shader_parameter("cliff_set") as Vector4).x > 0.8,
		"Stockholm's ground shader should take rock on gentler slopes")
	_check(cliff_par.get_shader_parameter("cliff_set") == null, "Paris keeps the default cliff onset")
	var steep_sto := _place(59.3293, 18.0686)
	var steep_par := _place(48.8566, 2.3522)
	for d in [steep_sto, steep_par]:
		d.land_polygons = []
		d.shore_structures = []
		for i in d.heights.size():
			d.heights[i] = float(i % 32) * 60.0
	var n_sto := RockOutcrops.build(Node3D.new(), steep_sto, GroundTruth.new(steep_sto))
	var n_par := RockOutcrops.build(Node3D.new(), steep_par, GroundTruth.new(steep_par))
	_check(n_sto > 5, "Stockholm's steep faces should carry granite mounds, got %d" % n_sto)
	_check(n_par == 0, "other cities raise no scatter mounds, got %d" % n_par)
	# Skerries: Stockholm's granite, Helsinki's unchanged, a neutral grey elsewhere.
	_check(RockOutcrops.rock_hex(sto) != RockOutcrops.ROCK_HEX and RockOutcrops.rock_hex(sto) != RockOutcrops.rock_hex(hel),
		"Stockholm's skerries should have their own granite colour")
	_check(RockOutcrops.rock_hex(hel) == "#8c7e78" and RockOutcrops.rock_hex(paris) == RockOutcrops.ROCK_HEX,
		"Helsinki and Paris rock colours should be unchanged")
	_banks(sto, sto_ground, paris, hel)
	_locks()
	_cliff()
	_plinths()
	_gates()
	if failures.is_empty():
		print("stockholm_shore_test: ok")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: ", f)
		quit(1)

## Quay walls: the waterline courses and the sett strip, Stockholm only.
func _banks(sto: LocationData, sto_ground: GroundTruth, paris: LocationData, hel: LocationData) -> void:
	_check(StockholmQuay.applies(sto) and not StockholmQuay.applies(paris) and not StockholmQuay.applies(hel),
		"the waterline courses are Stockholm's only (Helsinki's granite quays keep their plain face)")
	var root := Node3D.new()
	var n := StockholmQuay.build(root, sto_ground.shoreline, sto)
	_check(n > 0, "Stockholm's hard banks should take the waterline courses, got %d" % n)
	var node := root.get_node_or_null("StockholmQuay") as MeshInstance3D
	_check(node != null and node.mesh.get_surface_count() == 3, "the courses are three surfaces: weed foot, wet granite, setts")
	if node != null and node.mesh.get_surface_count() == 3:
		var weed := node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var top := node.mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var seg: Dictionary = {}
		for candidate in sto_ground.shoreline.segments:
			if str(candidate["kind"]) == "hard":
				seg = candidate
				break
		var water := float(seg["water_a"])
		_check(weed.size() >= 4 and top.size() >= 4, "each wall gets a weed foot and a wet course")
		var weed_top := -INF
		for v in weed:
			weed_top = maxf(weed_top, v.y)
		var wet_top := -INF
		for v in top:
			wet_top = maxf(wet_top, v.y)
		_check(wet_top > weed_top and wet_top < water + 0.7, "the wet course stands over the weed foot, under 0.7 m: %.2f %.2f" % [weed_top, wet_top])
	_check(StockholmQuay.build(Node3D.new(), GroundTruth.new(paris).shoreline, paris) == 0, "Paris gets no waterline courses")
	var sett := StockholmQuay.sett_texture()
	_check(sett != null and sett.get_width() == 128, "the sett texture is generated")
	_check(StockholmQuay.material("wet").roughness < StockholmQuay.material("sett").roughness
		and StockholmQuay.material("weed").albedo_color.get_luminance() < StockholmQuay.material("wet").albedo_color.get_luminance(),
		"the foot is darker than the wet course, and the wet course glossier than the setts")

func _water(x0: float, x1: float, z0: float, z1: float) -> Dictionary:
	return {"class": "water", "tidal": false, "holes": [], "points": PackedVector2Array([
		Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])}

## Riddarholmen and Slussen: edges walled, locks marked, one court, one level.
func _locks() -> void:
	var data := LocationData.new()
	data.latitude = 59.3207
	data.longitude = 18.0604
	# Two lock panes at Slussen (about 680 m east, 80 m north of the centre), a
	# water ring edge on Riddarholmen (about 120 m north-east of the centre box).
	data.land_polygons = [_water(650, 700, -100, -50), _water(710, 770, -110, -40),
		{"class": "grass", "holes": [], "points": PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])}]
	var island := WorldScale.xz_from_latlon(59.3250, 18.0640, 59.3207, 18.0604)
	data.land_polygons.append(_water(island.x, island.x + 80, island.y - 20, island.y + 20))
	StockholmShore.prepare(data)
	var panes := 0
	for poly in data.land_polygons:
		panes += 1 if StockholmShore.lock_site(poly) else 0
	_check(panes == 2, "both Slussen panes are marked lock water, got %d" % panes)
	_check(not StockholmShore.lock_site(data.land_polygons[3]), "an island ring is no lock pane")
	_check(data.shore_structures.size() >= 12, "each pane and island edge is mapped as a wall, got %d" % data.shore_structures.size())
	for st in data.shore_structures:
		_check(str(st["kind"]) == "embankment", "the mended banks are walls that open no low quay")
	var courts := 0
	var wide := false
	for poly in data.land_polygons:
		if poly.has(StockholmShore.MARKER):
			courts += 1
			wide = wide or (str(poly["class"]) == "sett" and (poly["points"] as PackedVector2Array)[0].x < 650.0 - 30.0)
	_check(courts == 2 and wide, "stone-paved courts lie under the locks and the island, got %d" % courts)
	_check(str(data.land_polygons[data.land_polygons.size() - 1]["class"]) == "sett",
		"the courts come last in the list, so mapped cover wins")
	var polys := data.land_polygons.size()
	var walls := data.shore_structures.size()
	StockholmShore.prepare(data)
	_check(data.land_polygons.size() == polys and data.shore_structures.size() == walls, "prepare must not repeat")
	var paris := LocationData.new()
	paris.latitude = 48.8566
	paris.longitude = 2.3522
	paris.land_polygons = [_water(650, 700, -100, -50)]
	StockholmShore.prepare(paris)
	_check(paris.shore_structures.is_empty() and paris.land_polygons.size() == 1, "other cities' banks are not mended")
	# One level for the locks.
	var domains := ShoreDomains.new()
	domains.bodies = [{"source": 0, "level": 1.2}, {"source": 1, "level": 0.4}, {"source": 3, "level": 0.9}, {"source": -1, "level": 5.0}]
	StockholmShore.level_locks(domains, data)
	_check(is_equal_approx(float(domains.bodies[0]["level"]), 0.4) and is_equal_approx(float(domains.bodies[1]["level"]), 0.4),
		"the lock panes share their lowest level")
	_check(is_equal_approx(float(domains.bodies[2]["level"]), 0.9) and is_equal_approx(float(domains.bodies[3]["level"]), 5.0),
		"other water keeps its level")

## The Mariaberget stair.
func _cliff() -> void:
	var data := LocationData.new()
	data.latitude = 59.3207
	data.longitude = 18.0604
	data.grid_size = 32
	data.heights.resize(32 * 32)
	for i in data.heights.size():
		data.heights[i] = float(i / 32) * 40.0
	data.water_level = -3.0
	var ground := GroundTruth.new(data)
	var stations := StockholmCliff._column(ground, null, 0.0, -300.0, 200.0, 1.0)
	_check(stations.size() > 20, "a steep face gives a stair column, got %d stations" % stations.size())
	var rising := true
	for i in range(1, stations.size()):
		rising = rising and float(stations[i]["y"]) >= float(stations[i - 1]["y"]) - 0.001
	_check(rising, "the stair climbs from its foot")
	var lm := LandmarkMesh.new()
	lm.use("Granite", StandardMaterial3D.new())
	lm.use("Iron", StandardMaterial3D.new())
	StockholmCliff._stair(lm, stations, ground)
	_check(lm.triangle_count() > 100, "the stair has treads and rails")
	# Switchbacks: flights alternate across the fall line, foot to head, risers add up.
	var path := StockholmCliff.plan(stations, 1.0)
	var flights: Array = path.get("flights", [])
	_check(flights.size() >= 3 and (path["landings"] as Array).size() == flights.size() - 1,
		"the stair zigzags: %d flights, landings between them" % flights.size())
	if flights.size() >= 3:
		var c: Vector2 = path["c"]
		var f: Vector2 = path["f"]
		var turns := true
		for i in range(1, flights.size()):
			var a0: Vector2 = flights[i - 1]["a"]
			var b0: Vector2 = flights[i - 1]["b"]
			var a1: Vector2 = flights[i]["a"]
			var b1: Vector2 = flights[i]["b"]
			turns = turns and (b0 - a0).dot(c) * (b1 - a1).dot(c) < 0.0 and b0.is_equal_approx(a1) \
				and float(flights[i]["ya"]) >= float(flights[i - 1]["yb"]) - 0.001 and (b1 - a1).dot(f) > 0.0
		_check(turns, "each flight turns back across the face, meets the last at a landing and climbs")
		var risers := 0
		for flight: Dictionary in flights:
			risers += int(flight["n"])
		var climb := float(stations[stations.size() - 1]["y"]) - float(stations[0]["y"])
		_check(absf(float(risers) * StockholmCliff.RISE_M - climb) < 1.0, "the risers add up to the climb: %d for %.1f m" % [risers, climb])
	# Mapped steps and houses keep the corridor clear.
	var steps := [PackedVector2Array([Vector2(0, -100), Vector2(0, 100)])]
	_check(not StockholmCliff._corridor_clear(null, stations, steps, 1.0), "a stair corridor across mapped steps is refused")
	_check(StockholmCliff._corridor_clear(null, stations, [PackedVector2Array([Vector2(300, -100), Vector2(300, 100)])], 1.0),
		"steps well off the corridor leave it clear")
	var paris := _place(48.8566, 2.3522)
	_check(StockholmCliff.build(Node3D.new(), paris, GroundTruth.new(paris), null) == 0, "no stair outside Stockholm")

## Plinth aprons: a ramp up to a footprint is levelled, the rest and other cities stay.
func _plinths() -> void:
	var data := LocationData.new()
	data.latitude = 59.3250
	data.longitude = 18.0640
	var ring := PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 20), Vector2(0, 20)])
	data.buildings = [{"footprint": ring}]
	var size := 64
	var step := 8.0
	var surface := PackedFloat32Array()
	surface.resize(size * size)
	for z in size:
		for x in size:
			var p := Vector2((float(x) - 32.0) * step, (float(z) - 32.0) * step)
			var d := StockholmShore._ring_distance(p, ring)
			surface[z * size + x] = 3.0 + (2.0 * (1.0 - d / 9.0) if d < 9.0 else 0.0)
	var raw := surface.duplicate()
	var n := StockholmShore.flatten_plinths(surface, size, step, data)
	_check(n > 0, "the ramp posts are lowered, got %d" % n)
	var worst := 0.0
	var raised := false
	var far_same := true
	for z in size:
		for x in size:
			var p := Vector2((float(x) - 32.0) * step, (float(z) - 32.0) * step)
			var d := StockholmShore._ring_distance(p, ring)
			var i := z * size + x
			if d <= StockholmShore.APRON_FULL_M:
				worst = maxf(worst, surface[i] - 3.0)
			raised = raised or surface[i] > raw[i] + 0.0001
			if d > StockholmShore.APRON_M and not is_equal_approx(surface[i], raw[i]):
				far_same = false
	_check(worst < 0.6, "within 4 m of the wall the ground is levelled to its plinth, %.2f m left" % worst)
	_check(not raised and far_same, "an apron never raises a post, and leaves the ground past 9 m")
	var paris := LocationData.new()
	paris.latitude = 48.8566
	paris.longitude = 2.3522
	paris.buildings = data.buildings
	var untouched := raw.duplicate()
	_check(StockholmShore.flatten_plinths(untouched, size, step, paris) == 0 and untouched == raw, "other cities' ground is not levelled")

## Lock gates at the ends of a marked chamber.
func _gates() -> void:
	var rect := PackedVector2Array([Vector2(0, 0), Vector2(60, 0), Vector2(60, 140), Vector2(0, 140)])
	var axes := StockholmLocks.frame(rect)
	_check(not axes.is_empty() and absf(((axes["hi"] as Vector2).x - (axes["lo"] as Vector2).x) - 140.0) < 0.01
		and absf(((axes["hi"] as Vector2).y - (axes["lo"] as Vector2).y) - 60.0) < 0.01, "the chamber's long axis is found: %s" % axes)
	var data := LocationData.new()
	data.latitude = 59.3207
	data.longitude = 18.0604
	data.grid_size = 32
	data.heights.resize(32 * 32)
	data.heights.fill(3.0)
	data.water_level = -3.0
	# A chamber and, beside it, a basin too big to be a lock pane (460 m), walled by hand.
	data.land_polygons = [_water(600, 660, -200, -60), _water(560, 1020, 0, 60)]
	data.shore_structures = [{"points": PackedVector2Array([Vector2(560, 0), Vector2(1020, 0)]), "kind": "embankment", "id": "t:basin"}]
	var ground := GroundTruth.new(data)
	var root := Node3D.new()
	var n := StockholmLocks.build(root, ground.shoreline, data)
	_check(n == 2, "a chamber has a gate at each end, got %d" % n)
	var node := root.get_node_or_null("StockholmLocks")
	_check(node != null and node.get_child_count() >= 3, "gate leaves, granite piers and steel walkway are built")
	# Battered lock walls: a sill on every wall over 1.2 m and no sheer drop over 2 m.
	for h in [1.25, 2.0, 3.0, 4.5, 6.0, 8.0]:
		var plan := StockholmQuay.tier_plan(h)
		_check(float((plan[0] as Array)[1]) >= 1.2 and float((plan[0] as Array)[0]) <= 0.5, "the sill is 1.2 m+ wide just over the water at %.2f m" % h)
		var worst := float((plan[0] as Array)[0]) + 0.4
		for i in range(1, plan.size()):
			worst = maxf(worst, float((plan[i] as Array)[0]) - float((plan[i - 1] as Array)[0]))
		worst = maxf(worst, h - float((plan[plan.size() - 1] as Array)[0]))
		_check(worst <= 2.0, "a %.2f m lock wall has a %.2f m sheer run" % [h, worst])
		for i in range(1, plan.size()):
			_check(float((plan[i] as Array)[1]) < float((plan[i - 1] as Array)[1]), "each course steps back")
	_check(StockholmQuay.tier_plan(1.0).size() == 1, "a low wall keeps the sill only")
	# Built walls: every hard wall in the Slussen box (chambers and basins), made 3 m tall, gets its sill.
	var expected := {}
	var box := StockholmShore._xz_box(data, StockholmShore.SLUSSEN)
	var basin_walls := 0
	for seg in ground.shoreline.segments:
		var bi := int(seg.get("body", -1))
		var mid := ((seg["a"] as Vector2) + (seg["b"] as Vector2)) * 0.5
		if str(seg["kind"]) == "hard" and (box.has_point(mid) or (bi >= 0 and bool(ground.shoreline.domains.bodies[bi].get("lock_site", false)))):
			seg["top_a"] = float(seg["water_a"]) + 3.0
			seg["top_b"] = float(seg["water_b"]) + 3.0
			expected[str([seg["a"], seg["b"]]) if (seg["a"] as Vector2).x < (seg["b"] as Vector2).x else str([seg["b"], seg["a"]])] = true
			if bi >= 0 and not bool(ground.shoreline.domains.bodies[bi].get("lock_site", false)):
				basin_walls += 1
			# No wall there stands in a sheer drop over 2 m once battered.
			var plan := StockholmQuay.tier_plan(3.0)
			var worst := 0.0
			for i in range(1, plan.size()):
				worst = maxf(worst, float((plan[i] as Array)[0]) - float((plan[i - 1] as Array)[0]))
			worst = maxf(worst, 3.0 - float((plan[plan.size() - 1] as Array)[0]))
			_check(worst <= 2.0, "a Slussen wall has a %.2f m sheer run" % worst)
	_check(basin_walls > 0, "the fixture has walls beside the chambers that are not lock panes, got %d" % basin_walls)
	var lock_root := Node3D.new()
	StockholmQuay.build(lock_root, ground.shoreline, data)
	var quay := lock_root.get_node_or_null("StockholmQuay") as MeshInstance3D
	_check(quay != null and expected.size() > 0 and int(quay.get_meta("sills", 0)) >= expected.size() * 9 / 10,
		"each of %d lock walls over 1.2 m has a sill, got %d" % [expected.size(), int(quay.get_meta("sills", 0)) if quay != null else -1])
	_check(quay != null and quay.mesh.get_surface_count() >= 5, "sill, joint line and fine lock ashlar are built")
	# Transition caps in the box (masonry that is no shore segment) are battered and skinned too.
	var caps_in_box := 0
	for cap: Dictionary in ShoreBankMesh.transition_caps(ground.shoreline):
		var f: PackedVector3Array = cap["face"]
		var cm := Vector2((f[0].x + f[1].x + f[2].x + f[3].x) * 0.25, (f[0].z + f[1].z + f[2].z + f[3].z) * 0.25)
		var ch := minf(absf(f[0].y - f[3].y), absf(f[1].y - f[2].y))
		if box.has_point(cm) and ch > 0.05 and ch <= StockholmQuay.CAP_MAX_M:
			caps_in_box += 1
	_check(quay != null and int(quay.get_meta("caps", -1)) == caps_in_box, "every cap in the Slussen box is battered: %d of %d" % [int(quay.get_meta("caps", -1)) if quay != null else -1, caps_in_box])
	var paris := _place(48.8566, 2.3522)
	_check(StockholmLocks.build(Node3D.new(), GroundTruth.new(paris).shoreline, paris) == 0, "no lock gates outside Stockholm")
