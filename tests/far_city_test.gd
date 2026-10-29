extends SceneTree

## T5.4 far city + T4.5 absence-only infill + T7.3 far bands:
## godot --headless --script tests/far_city_test.gd
## Fixture-only (no fetches): a synthetic far drape (west = busy grey
## roofscape, centre = flat beige field, east = forest) drives
## SettlementMap; FarCityBuilder must build only on the roofscape (and
## inside OSM built-up landuse that is not vegetation), never on the
## field/forest, with textured shared materials, towers only from
## far_towers, identical geometry on every preset, and LodRing hiding
## the outer bands on Fast. InfillPlanner: 0 infill in a fully mapped
## tile, matched heights next to a real village, none in forest.

const ZOOM := 13

func _init() -> void:
	_run()

func _px_hash(x: int, y: int) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)

func _data(preset: int = 2) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.seed_value = 5
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.far_grid_size = 16
	data.far_heights.resize(16 * 16)
	data.far_heights.fill(3.0)
	# Drape: 1024 px around the viewpoint at z13 (~10 m/px here).
	var origin := FarSurface.global_px(data, -6500.0, -6500.0, ZOOM)
	var far_c := FarSurface.global_px(data, 6500.0, 6500.0, ZOOM)
	var size := Vector2i(int(far_c.x - origin.x), int(far_c.y - origin.y))
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var west_px := FarSurface.global_px(data, -800.0, 0.0, ZOOM).x - origin.x
	var east_px := FarSurface.global_px(data, 800.0, 0.0, ZOOM).x - origin.x
	for y in size.y:
		for x in size.x:
			var c := Color(0.5, 0.48, 0.42)  # flat beige field
			if float(x) < west_px:
				var v := 0.22 + 0.4 * _px_hash(x, y)
				c = Color(v, v, v * 0.97)  # busy grey roofscape
			elif float(x) > east_px:
				c = Color(0.14, 0.28, 0.12)  # forest
			img.set_pixel(x, y, c)
	data.far_drapes = [{"zoom": ZOOM, "origin_px": origin, "size_px": size,
		"texture": null, "image": img, "reach_m": 9500.0}]
	return data

func _far_nodes(root: Node) -> Array:
	var out: Array = []
	for c in root.get_children():
		if c is MeshInstance3D and str(c.get_meta("lod_layer", "")) == "FarCity":
			out.append(c)
	return out

func _verts(nodes: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mi in nodes:
		var arr := (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		out.append_array(arr[Mesh.ARRAY_VERTEX])
	return out

func _run() -> void:
	var failures: Array[String] = []
	_settlement_checks(failures)
	_far_city_checks(failures)
	_parse_checks(failures)
	_infill_checks(failures)
	if failures.is_empty():
		print("FAR CITY OK: settlement map, real-data far city (no field/forest/water), towers only from OSM, preset-invariant, far bands ranged, absence-only matched infill")
		quit(0)
	else:
		for f in failures:
			printerr("FAR CITY FAIL: ", f)
		quit(1)

func _settlement_checks(failures: Array[String]) -> void:
	var data := _data()
	var m := SettlementMap.build(data)
	if m.source != "drape":
		failures.append("drape-only map source should be 'drape', got '%s'" % m.source)
	if m.score_at(-3000.0, 500.0) < 0.5:
		failures.append("roofscape cell should score built, got %.2f" % m.score_at(-3000.0, 500.0))
	if m.blocked_at(3000.0, 500.0) != 1:
		failures.append("forest cell should be blocked as vegetation")
	if m.score_at(0.0, 3000.0) > 0.1:
		failures.append("flat field should not score built, got %.2f" % m.score_at(0.0, 3000.0))
	# OSM landuse lifts the field (class industrial) but never the forest.
	data.far_landuse = [
		{"class": "industrial", "points": PackedVector2Array([Vector2(-500, 2000),
			Vector2(500, 2000), Vector2(500, 3000), Vector2(-500, 3000)]), "holes": []},
		{"class": "residential", "points": PackedVector2Array([Vector2(2500, 2000),
			Vector2(3500, 2000), Vector2(3500, 3000), Vector2(2500, 3000)]), "holes": []}]
	var m2 := SettlementMap.build(data)
	if m2.class_at(0.0, 2500.0) != SettlementMap.Cls.INDUSTRIAL or m2.score_at(0.0, 2500.0) < 0.5:
		failures.append("industrial landuse should mark the field built/industrial")
	if m2.score_at(3000.0, 2500.0) > 0.0:
		failures.append("landuse over imagery forest must stay open")
	if m2.score_at(0.0, -3000.0) > 0.1:
		failures.append("field outside landuse should stay open with OSM present")
	var empty := LocationData.new()
	if not SettlementMap.build(empty).is_empty():
		failures.append("no drape + no landuse should give an empty map")

func _far_city_checks(failures: Array[String]) -> void:
	var data := _data()
	data.far_towers = [{"footprint": PackedVector2Array([Vector2(-5020, 1980),
		Vector2(-4980, 1980), Vector2(-4980, 2020), Vector2(-5020, 2020)]),
		"x": -5000.0, "z": 2000.0, "height": 150.0, "levels": 0, "kind": "office"}]
	var root := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
	var nodes := _far_nodes(root)
	var stats := BuildingBuilder.last_stats
	if int(stats.get("far_blocks", 0)) < 100:
		failures.append("roofscape should continue as far blocks, got %s" % str(stats))
	if int(stats.get("far_towers", 0)) != 1:
		failures.append("exactly the one OSM tower should be built, got %s" % str(stats))
	if int(stats.get("infill", -1)) != 0:
		failures.append("no infill over a flat field / forest, got %s" % str(stats))
	var tower_top := 0.0
	var other_top := 0.0
	for v in _verts(nodes):
		var r := Vector2(v.x, v.z).length()
		if r < FarCityBuilder.R_IN - 60.0:
			failures.append("far city inside the detailed extent at %s" % str(v))
			break
		if v.x > -700.0:
			failures.append("far city on the field/forest at %s" % str(v))
			break
		if Vector2(v.x + 5000.0, v.z - 2000.0).length() < 40.0:
			tower_top = maxf(tower_top, v.y)
		else:
			other_top = maxf(other_top, v.y)
	if tower_top < 150.0:
		failures.append("OSM tower should rise to its 150 m, got %.1f" % tower_top)
	if other_top > 60.0:
		failures.append("no invented towers: generic fabric topped %.1f m" % other_top)
	for mi in nodes:
		var mat := (mi as MeshInstance3D).material_override as StandardMaterial3D
		if mat == null or mat.albedo_texture == null:
			failures.append("far city material must be textured, got %s" % str(mat))
			break
		if not (mi as MeshInstance3D).has_meta("far_r0"):
			failures.append("far city band missing far_r0")
			break
		if (mi as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			failures.append("far city should not cast shadows")
			break
	if nodes.size() > 8 * 4 * 7:
		failures.append("far city draw calls unbounded: %d meshes" % nodes.size())
	# LodRing: Fast hides bands past its reach, High shows all.
	var hidden := 0
	LodRing.apply(root, RenderSettings.Preset.FAST)
	for mi in nodes:
		var r0 := float((mi as Node).get_meta("far_r0"))
		var end := (mi as GeometryInstance3D).visibility_range_end
		if r0 >= LodRing.far_city_m(0):
			hidden += 1
			if end != 1.0:
				failures.append("Fast should hide the %.0f m band" % r0)
				break
		elif end != 0.0:
			failures.append("Fast should show the %.0f m band" % r0)
			break
	if hidden == 0:
		failures.append("expected Fast to hide some outer far-city bands")
	LodRing.apply(root, RenderSettings.Preset.HIGH)
	for mi in nodes:
		if (mi as GeometryInstance3D).visibility_range_end != 0.0:
			failures.append("High should show every far-city band")
			break
	# Same geometry on every preset (AC-12): positions never depend on it.
	var base := _verts(nodes)
	root.free()
	for p in [0, 3]:
		var d2 := _data(p)
		d2.far_towers = data.far_towers
		var r2 := BuildingBuilder.build_buildings(d2, GroundTruth.new(d2))
		var v2 := _verts(_far_nodes(r2))
		if v2.size() != base.size():
			failures.append("preset %d far city vertex count %d != %d" % [p, v2.size(), base.size()])
		else:
			var a := AABB(base[0], Vector3.ZERO)
			var b := AABB(v2[0], Vector3.ZERO)
			for v in base:
				a = a.expand(v)
			for v in v2:
				b = b.expand(v)
			if not a.is_equal_approx(b):
				failures.append("preset %d far city extent moved %s -> %s" % [p, a, b])
		r2.free()

func _parse_checks(failures: Array[String]) -> void:
	var lat := 48.8566
	var lon := 2.3522
	var d := 0.01
	var sq := [{"lat": lat, "lon": lon + d}, {"lat": lat, "lon": lon + 2 * d},
		{"lat": lat + d, "lon": lon + 2 * d}, {"lat": lat + d, "lon": lon + d},
		{"lat": lat, "lon": lon + d}]
	var fixture := {"elements": [
		{"type": "way", "id": 1, "tags": {"landuse": "residential"}, "geometry": sq},
		{"type": "way", "id": 1, "tags": {"landuse": "residential"}, "geometry": sq},
		{"type": "relation", "id": 2, "tags": {"landuse": "industrial", "type": "multipolygon"},
			"members": [{"type": "way", "role": "outer", "geometry": sq}]},
		{"type": "way", "id": 3, "tags": {"building": "office", "height": "187"},
			"geometry": sq}]}
	var out := FarCityFetcher.parse(JSON.stringify(fixture), lat, lon)
	var lu: Array = out["landuse"]
	var tw: Array = out["towers"]
	if lu.size() != 2:
		failures.append("parse: expected 2 landuse polygons (dedup), got %d" % lu.size())
	elif str(lu[1]["class"]) != "industrial":
		failures.append("parse: relation landuse class lost")
	if tw.size() != 1 or absf(float(tw[0]["height"]) - 187.0) > 0.01:
		failures.append("parse: tower height should be 187, got %s" % str(tw))
	elif (tw[0]["footprint"] as PackedVector2Array).size() != 4:
		failures.append("parse: tower footprint should drop the closing node")
	if not FarCityFetcher.build_query(lat, lon).contains("around:12000"):
		failures.append("query should cover the 12 km ring")
	var empty := FarCityFetcher.parse("", lat, lon)
	if not (empty["landuse"] as Array).is_empty():
		failures.append("parse of an absent payload should be empty")

func _bld(x: float, z: float, h: float) -> Dictionary:
	return {"x": x, "z": z, "size_x": 14.0, "size_z": 10.0, "height": h,
		"height_source": "tag_height", "levels": 0, "kind": "house",
		"footprint": PackedVector2Array([Vector2(x - 7, z - 5), Vector2(x + 7, z - 5),
			Vector2(x + 7, z + 5), Vector2(x - 7, z + 5)])}

func _urban_cover(half: float, cls: String = "urban") -> Array:
	return [{"class": cls, "points": PackedVector2Array([Vector2(-half, -half),
		Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]), "holes": []}]

func _infill_checks(failures: Array[String]) -> void:
	# 1) Fully OSM-mapped tile: every infill site has a real building
	#    within reach → 0 procedural buildings (T4.5 toggle test).
	var full := _data()
	full.far_drapes = []
	full.land_polygons = _urban_cover(1100.0)
	for gx in range(-9, 10):
		for gz in range(-9, 10):
			full.buildings.append(_bld(float(gx) * 50.0, float(gz) * 50.0, 18.0))
	BuildingBuilder.build_buildings(full, GroundTruth.new(full)).free()
	if int(BuildingBuilder.last_stats.get("infill", -1)) != 0:
		failures.append("fully mapped tile should get 0 infill, got %s" % str(BuildingBuilder.last_stats))
	# 2) A real village (tagged 6-9 m) beside an unmapped urban area:
	#    infill only in the gap, heights from the village distribution.
	var vil := _data()
	vil.far_drapes = []
	vil.land_polygons = _urban_cover(1100.0)
	var hs: Array = []
	for i in 30:
		var h := 6.0 + 3.0 * float(i % 7) / 6.0
		hs.append(h)
		vil.buildings.append(_bld(-300.0 + float(i % 6) * 22.0, -60.0 + float(i / 6) * 24.0, h))
	var ground := GroundTruth.new(vil)
	var plan := InfillPlanner.new(vil, ground, SettlementMap.build(vil),
		BuildingBuilder._height_context(vil))
	if plan.fallback:
		failures.append("village planner must not use the no-data fallback")
	if plan.allows(-250.0, -10.0):
		failures.append("infill allowed inside the mapped village")
	if not plan.allows(250.0, 0.0):
		failures.append("infill refused in an unmapped urban gap")
	for k in 40:
		var st := plan.style(200.0, 0.0, float(k) / 40.0)
		var t := float(st["total_m"])
		if t < 6.0 * 0.9 or t > 9.0 * 1.1:
			failures.append("infill height %.1f outside the village's 6-9 m" % t)
			break
	BuildingBuilder.build_buildings(vil, ground).free()
	if int(BuildingBuilder.last_stats.get("infill", 0)) <= 0:
		failures.append("unmapped urban gap should get infill, got %s" % str(BuildingBuilder.last_stats))
	# 3) Rural forest (Big Sur): a few real houses, forest cover → none.
	var rural := _data()
	rural.far_drapes = []
	rural.land_polygons = _urban_cover(1100.0, "forest")
	for i in 4:
		rural.buildings.append(_bld(-500.0 + float(i) * 30.0, 400.0, 7.0))
	BuildingBuilder.build_buildings(rural, GroundTruth.new(rural)).free()
	if int(BuildingBuilder.last_stats.get("infill", -1)) != 0:
		failures.append("forest should get 0 infill, got %s" % str(BuildingBuilder.last_stats))
