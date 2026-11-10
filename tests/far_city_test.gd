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

## The far blocks carry paint families (FarCityBuilder._paint) and the native
## kernel must tint them exactly as the script path does: the same mesh count
## and the same per-vertex colours, and the colours must really vary.
func _paint_parity_checks(failures: Array[String]) -> void:
	var data := _data()
	var smap := SettlementMap.build(data)
	var script_cols := _far_colours(data, smap, false)
	if script_cols.is_empty():
		failures.append("paint parity: the script far city built no coloured meshes")
		return
	var distinct := {}
	for cols in script_cols:
		for c in (cols as PackedColorArray):
			distinct["%.2f|%.2f|%.2f" % [c.r, c.g, c.b]] = true
	if distinct.size() < 12:
		failures.append("paint parity: far block colours barely vary (%d distinct)" % distinct.size())
	if not FarCityBuilder._native:
		return  # no native library here: the script path is the only one
	var native_cols := _far_colours(data, smap, true)
	if native_cols.size() != script_cols.size():
		failures.append("paint parity: native built %d meshes, script %d" % [native_cols.size(), script_cols.size()])
		return
	var worst := 0.0
	for i in script_cols.size():
		var a: PackedColorArray = script_cols[i]
		var b: PackedColorArray = native_cols[i]
		if a.size() != b.size():
			failures.append("paint parity: mesh %d has %d script colours, %d native" % [i, a.size(), b.size()])
			return
		for k in a.size():
			worst = maxf(worst, maxf(absf(a[k].r - b[k].r), maxf(absf(a[k].g - b[k].g), absf(a[k].b - b[k].b))))
	if worst > 0.01:
		failures.append("paint parity: native and script far-block colours differ by %.3f" % worst)

## The vertex colours of every far-city mesh (in build order), built on the
## native path or the script path.
func _far_colours(data: LocationData, smap: SettlementMap, native: bool) -> Array:
	var out: Array = []
	for arr in _far_arrays(data, smap, native):
		if arr[Mesh.ARRAY_COLOR] != null:
			out.append(arr[Mesh.ARRAY_COLOR])
	return out

## The surface arrays of every far-city mesh (in build order).
func _far_arrays(data: LocationData, smap: SettlementMap, native: bool) -> Array:
	var was := FarCityBuilder._native
	FarCityBuilder._native = native and was
	var root := Node3D.new()
	FarCityBuilder.build(root, data, GroundTruth.new(data), smap)
	FarCityBuilder._native = was
	var out: Array = []
	for n in _far_nodes(root):
		var mesh := (n as MeshInstance3D).mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		out.append(MeshArrays.surface(mesh, 0))
	root.free()
	return out

## Mapped buildings in the outer extent band (700 m+) set the far fabric's
## edge height (FarCityBuilder._h_edge), which the near apartments blend from.
func _with_edge_buildings(data: LocationData, height_m: float) -> void:
	for i in 12:
		var a := TAU * float(i) / 12.0
		data.buildings.append({"x": cos(a) * 900.0, "z": sin(a) * 900.0, "height": height_m,
			"height_source": "levels", "kind": "apartments"})

func _top_y(arrays: Array) -> float:
	var top := -INF
	for arr in arrays:
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			top = maxf(top, v.y)
	return top

## The far fabric's lot pairing (PAIR_*), footprint offsets and the near-edge
## height blend are written twice, in FarCityBuilder and in the native
## CityKernels. The same fixture, with and without mapped edge buildings
## (which switch the blend on), must build the same meshes with the same
## vertices on both paths; and the blend must really move the skyline.
func _geometry_parity_checks(failures: Array[String]) -> void:
	var plain := _data()
	var plain_smap := SettlementMap.build(plain)
	var edged := _data()
	_with_edge_buildings(edged, 45.0)
	var edged_smap := SettlementMap.build(edged)
	var script_plain := _far_arrays(plain, plain_smap, false)
	var script_edged := _far_arrays(edged, edged_smap, false)
	if script_plain.is_empty() or script_edged.is_empty():
		failures.append("geometry parity: the script far city built no meshes")
		return
	if absf(_top_y(script_plain) - _top_y(script_edged)) < 0.5:
		failures.append("geometry parity: mapped edge buildings did not change the far skyline (the near-edge blend is not exercised)")
	if not FarCityBuilder._native:
		return  # no native library here: the script path is the only one
	for case in [["no edge", plain, plain_smap, script_plain], ["edge 45 m", edged, edged_smap, script_edged]]:
		var native := _far_arrays(case[1], case[2], true)
		var script: Array = case[3]
		if native.size() != script.size():
			failures.append("geometry parity (%s): native built %d meshes, script %d" % [case[0], native.size(), script.size()])
			continue
		var worst := 0.0
		for i in script.size():
			var a: PackedVector3Array = script[i][Mesh.ARRAY_VERTEX]
			var b: PackedVector3Array = native[i][Mesh.ARRAY_VERTEX]
			if a.size() != b.size():
				failures.append("geometry parity (%s): mesh %d has %d script vertices, %d native" % [case[0], i, a.size(), b.size()])
				worst = 0.0
				break
			for k in a.size():
				worst = maxf(worst, a[k].distance_to(b[k]))
		if worst > 0.05:
			failures.append("geometry parity (%s): native and script vertices differ by %.3f m" % [case[0], worst])

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
	_tower_parts_checks(failures)
	_paint_parity_checks(failures)
	_geometry_parity_checks(failures)
	_district_checks(failures)
	_parse_checks(failures)
	await _offline_cache_checks(failures)
	_infill_checks(failures)
	if failures.is_empty():
		print("FAR CITY OK: settlement map, real-data far city (no field/forest/water), towers only from OSM, preset-invariant, far bands ranged, absence-only matched infill")
		quit(0)
	else:
		for f in failures:
			printerr("FAR CITY FAIL: ", f)
		quit(1)

## Every district character occurs, and older patches lean toward the centre.
func _district_checks(failures: Array[String]) -> void:
	var seen := {}
	var inner := [0, 0]
	var outer := [0, 0]
	for iz in range(-20, 20):
		for ix in range(-20, 20):
			var c := Vector2((float(ix) + 0.5) * FarCityBuilder.DISTRICT_M, (float(iz) + 0.5) * FarCityBuilder.DISTRICT_M)
			var district := FarCityBuilder._district(c)
			seen[district] = true
			var ring: Array = inner if c.length() < 4000.0 else outer
			ring[0] = int(ring[0]) + (1 if district < 0 else 0)
			ring[1] = int(ring[1]) + 1
	if seen.size() != 3:
		failures.append("far districts should be older, mixed and newer, got %s" % seen.keys())
	if float(inner[0]) / float(inner[1]) <= float(outer[0]) / float(outer[1]):
		failures.append("older far districts should lean to the centre: inner %s outer %s" % [inner, outer])

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
	if SettlementMap._native:
		SettlementMap._native = false
		var script_map := SettlementMap.build(data)
		SettlementMap._native = true
		if m2.score != script_map.score or m2.cls != script_map.cls \
				or m2.blocked != script_map.blocked or m2.source != script_map.source:
			failures.append("native settlement sampling differs from the script map")
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

func _tower_parts_checks(failures: Array[String]) -> void:
	var builder := FarCityBuilder.new()
	var glass := StandardMaterial3D.new()
	var brick := StandardMaterial3D.new()
	builder._glass = glass
	builder._dfs = [brick]
	builder._height_ctx = BuildingHeights._height_context(_data())
	if builder._tower_material({"material": "mirror"}, brick, Vector2.ZERO) != glass \
			or str(builder._tower_material({"material": "brick"}, glass, Vector2.ZERO).get_meta("facade_set", "")) != "brick" \
			or builder._tower_material({}, glass, Vector2.ZERO) != glass:
		failures.append("far tower parts must honour mapped glass and masonry materials")
	var data := _data()
	var foot := PackedVector2Array([Vector2(-5040, 1960), Vector2(-4960, 1960),
		Vector2(-4960, 2040), Vector2(-5040, 2040)])
	var crown := PackedVector2Array([Vector2(-5010, 1990), Vector2(-4990, 1990),
		Vector2(-4990, 2010), Vector2(-5010, 2010)])
	data.far_towers = [{"footprint": foot, "x": -5000.0, "z": 2000.0, "height": 90.0,
		"kind": "office", "parts": [
			{"footprint": foot, "height": 60.0},
			{"footprint": crown, "height": 90.0, "min_height_m": 60.0,
				"roof_shape": "pyramidal", "roof_height_m": 12.0}]}]
	var root := Node3D.new()
	FarCityBuilder.build(root, data, GroundTruth.new(data), null)
	var verts := _verts(_far_nodes(root))
	var top := -INF
	var wide_above_setback := false
	var roof_slope := false
	for v in verts:
		top = maxf(top, v.y)
		if v.y > 65.0 and absf(v.x + 5000.0) > 15.0:
			wide_above_setback = true
		if v.y > 80.0 and v.y < 90.0:
			roof_slope = true
	if top < 89.0 or top > 94.0 or wide_above_setback or not roof_slope:
		failures.append("far parts must preserve a 60 m setback and pyramidal 90 m crown: top %.1f wide %s slope %s" \
			% [top, wide_above_setback, roof_slope])
	root.free()

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
			"geometry": sq},
		{"type": "way", "id": 4, "tags": {"building": "construction", "height": "373.7", "opening_date": "2031"},
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
	elif str(tw[0].get("osm_id", "")) != "way:3":
		failures.append("far tower identity must match the detailed parser's integer OSM id")
	var near := [{"osm_id": "way:3", "parts": [{"osm_id": "way:4", "material": "stone"}]}]
	var far := [{"osm_id": "way:3", "parts": [{"osm_id": "way:4", "material": "glass"},
		{"osm_id": "way:5", "height": 250.0}]}]
	var complete := FarCityFetcher.complete_buildings(near, far)
	if complete[0]["parts"].size() != 2 or complete[0]["parts"][0]["material"] != "stone" \
			or near[0]["parts"].size() != 1:
		failures.append("edge towers must gain missing far parts without replacing detailed tags or mutating the input")
	var detailed: Array = OsmFetcher.parse_features(JSON.stringify(fixture), lat, lon)["buildings"]
	if detailed.size() != 1 or absf(float(detailed[0]["height"]) - 187.0) > 0.01:
		failures.append("planned construction height must not appear as a completed building: %s" % str(detailed))
	if not FarCityFetcher.build_query(lat, lon).contains("around:12000"):
		failures.append("query should cover the 12 km ring")
	var query := FarCityFetcher.build_query(lat, lon)
	if not query.contains('number(t["height"])*0.3048>=50') \
			or not query.contains('["height"!~"([fF][tT]|\u0027) *$"]'):
		failures.append("query must convert feet before applying the tower threshold")
	if not FarCityFetcher.cache_path(lat, lon).contains("farcity12000_q3.json"):
		failures.append("far-city query change needs a layer-specific cache version")
	var feet_fixture := {"elements": [
		{"type": "way", "id": 4, "tags": {"building": "office", "height": "600 ft"}, "geometry": sq},
		{"type": "way", "id": 5, "tags": {"building": "office", "height": "600'"}, "geometry": sq}]}
	var feet: Array = FarCityFetcher.parse(JSON.stringify(feet_fixture), lat, lon)["towers"]
	if feet.size() != 2 or absf(float(feet[0]["height"]) - 182.88) > 0.01 \
			or absf(float(feet[1]["height"]) - 182.88) > 0.01:
		failures.append("feet-tagged far towers must retain their height: %s" % str(feet))
	if not query.contains('relation["building"]') or not query.contains('way["building:part"](around:4000') \
			or not query.contains('relation["building:part"]["type"="multipolygon"]'):
		failures.append("far query must include relation outlines and their parts")
	var ring := [{"lat": lat, "lon": lon + 0.02}, {"lat": lat, "lon": lon + 0.021},
		{"lat": lat + 0.001, "lon": lon + 0.021}, {"lat": lat + 0.001, "lon": lon + 0.02},
		{"lat": lat, "lon": lon + 0.02}]
	var part := [{"lat": lat + 0.0002, "lon": lon + 0.0202}, {"lat": lat + 0.0002, "lon": lon + 0.0208},
		{"lat": lat + 0.0008, "lon": lon + 0.0208}, {"lat": lat + 0.0008, "lon": lon + 0.0202},
		{"lat": lat + 0.0002, "lon": lon + 0.0202}]
	var rich := {"elements": [
		{"type": "relation", "id": 44, "tags": {"type": "multipolygon", "building": "office", "height": "18"},
			"members": [{"type": "way", "role": "outer", "geometry": ring}]},
		{"type": "way", "id": 45, "tags": {"building:part": "yes", "height": "120", "min_height": "90",
			"roof:shape": "pyramidal", "roof:height": "15"}, "geometry": part}]}
	var rich_towers: Array = FarCityFetcher.parse(JSON.stringify(rich), lat, lon)["towers"]
	if rich_towers.size() != 1 or (rich_towers[0].get("parts", []) as Array).size() != 1:
		failures.append("relation tower must retain its building part: %s" % rich_towers)
	else:
		var crown: Dictionary = rich_towers[0]["parts"][0]
		if crown["roof_shape"] != "pyramidal" or float(crown["roof_height_m"]) != 15.0 or float(crown["min_height_m"]) != 90.0:
			failures.append("far part must retain roof and lift tags: %s" % crown)
	if rich_towers.size() == 1 and FarCityFetcher._tower_height(rich_towers[0]) != 120.0:
		failures.append("a low podium must be ranked by its tall mapped crown")
	var ranked := FarCityFetcher.select_towers([
		{"x": 10000.0, "z": 0.0, "height": 70.0}, {"x": 1200.0, "z": 0.0, "height": 100.0},
		{"x": 2000.0, "z": 0.0, "height": 300.0}], 2)
	if ranked.size() != 2 or float(ranked[0]["height"]) != 300.0 or float(ranked[1]["height"]) != 100.0:
		failures.append("tower cap must keep taller nearby candidates independent of input order: %s" % ranked)
	var empty := FarCityFetcher.parse("", lat, lon)
	if not (empty["landuse"] as Array).is_empty():
		failures.append("parse of an absent payload should be empty")

func _offline_cache_checks(failures: Array[String]) -> void:
	var previous := CacheStore.dir_override
	CacheStore.dir_override = "user://far-city-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.dir_override))
	var legacy := FarCityFetcher.legacy_cache_path(48.0, 2.0)
	var fresh := FarCityFetcher.cache_path(48.0, 2.0)
	var points := [{"lat": 48.0, "lon": 2.0}, {"lat": 48.0, "lon": 2.001},
		{"lat": 48.001, "lon": 2.001}, {"lat": 48.001, "lon": 2.0}]
	var old_payload := {"elements": [{"type": "way", "id": 1,
		"tags": {"building": "office", "height": "600 ft"}, "geometry": points}]}
	var new_payload := {"elements": [{"type": "way", "id": 2,
		"tags": {"building": "office", "height": "200"}, "geometry": points}]}
	var f := FileAccess.open(legacy, FileAccess.WRITE)
	f.store_string(JSON.stringify(old_payload))
	f.close()
	var fetcher := FarCityFetcher.new()
	root.add_child(fetcher)
	fetcher.offline_mode = true
	var results: Array = []
	fetcher.finished.connect(func(_land: Array, towers: Array) -> void: results.append(towers))
	fetcher.fetch(48.0, 2.0)
	var deadline := Time.get_ticks_msec() + 5000
	while results.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	if results.is_empty() or (results[0] as Array).size() != 1 \
			or absf(float(results[0][0]["height"]) - 182.88) > 0.01:
		failures.append("offline fetch must use the older far-city cache")
	f = FileAccess.open(fresh, FileAccess.WRITE)
	f.store_string(JSON.stringify(new_payload))
	f.close()
	fetcher.fetch(48.0, 2.0)
	deadline = Time.get_ticks_msec() + 5000
	while results.size() < 2 and Time.get_ticks_msec() < deadline:
		await process_frame
	if results.size() < 2 or (results[1] as Array).size() != 1 \
			or absf(float(results[1][0]["height"]) - 200.0) > 0.01:
		failures.append("offline fetch must prefer the current far-city cache")
	fetcher.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fresh))
	CacheStore.dir_override = previous

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
