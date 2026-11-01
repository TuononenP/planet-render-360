extends SceneTree

## Headless: godot --headless --script tests/landmark_fidelity_test.gd
## Landmark fidelity in any city: lathed dome/onion/cone roofs, a dome
## part that is only roof keeps its lift on the drum, well-mapped OSM
## landmarks are flagged to draw from their own parts and keep their
## building, every other candidate builds a model, and LandmarkSites
## drops OSM duplicates of registry sites.

const LAT := 48.8566
const LON := 2.3522

func _init() -> void:
	_run()

func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / n
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out

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

func _lathe(ring: PackedVector2Array, top: float, rh: float, shape: String) -> PackedVector3Array:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	if not RoofDomes.faces(ring, RingGeometry.interior_point(ring), top, rh, shape,
			verts, normals, uvs):
		return PackedVector3Array()
	return verts

func _run() -> void:
	var failures: Array[String] = []
	_roof_form_checks(failures)
	_roof_only_part_checks(failures)
	_mapped_checks(failures)
	_candidate_checks(failures)
	_site_checks(failures)
	if failures.is_empty():
		print("LANDMARK FIDELITY OK: lathed roofs, roof-only parts, mapped landmarks, candidates, sites")
	else:
		for f in failures:
			print("LANDMARK FIDELITY FAIL: ", f)
	quit(0 if failures.is_empty() else 1)

func _roof_form_checks(failures: Array[String]) -> void:
	var disc := _circle(Vector2.ZERO, 10.0, 24)
	var dome := _lathe(disc, 20.0, 10.0, "dome")
	if dome.is_empty():
		failures.append("24-gon dome produced no faces")
	else:
		var levels := {}
		var top_y := -INF
		for v in dome:
			levels[snappedf(v.y, 0.01)] = true
			top_y = maxf(top_y, v.y)
		if levels.size() < RoofDomes.DOME_STEPS + 1:
			failures.append("dome has %d rings (want >= %d)" % [levels.size(), RoofDomes.DOME_STEPS + 1])
		if absf(top_y - 30.0) > 0.01:
			failures.append("dome apex at %.2f (want 30)" % top_y)
		# A true dome: half way up the rise the radius is still cos(30°).
		for v in dome:
			if absf(v.y - 25.0) < 0.01 and Vector2(v.x, v.z).length() < 8.0:
				failures.append("dome at half rise is radius %.2f (want ~8.66)" % Vector2(v.x, v.z).length())
				break
	var onion := _lathe(disc, 20.0, 12.0, "onion")
	var bulge := 0.0
	for v in onion:
		if v.y > 20.0 + 12.0 * 0.15 and v.y < 20.0 + 12.0 * 0.45:
			bulge = maxf(bulge, Vector2(v.x, v.z).length())
	if bulge < 12.0:
		failures.append("onion bulges to %.2f (want >= 1.2 x base radius 10)" % bulge)
	var cone := _lathe(disc, 20.0, 16.0, "cone")
	if cone.is_empty():
		failures.append("cone produced no faces")
	for v in cone:
		if v.y > 20.0 + 16.0 - 0.01 and Vector2(v.x, v.z).length() > 0.1:
			failures.append("cone has a plateau at its apex (%s)" % str(v))
			break
	# A square drum takes a cloister dome (subdivided to MIN_SIDES).
	var square := PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)])
	if _lathe(square, 0.0, 5.0, "dome").size() < RoofDomes.MIN_SIDES * 3:
		failures.append("square dome was not subdivided")
	# A U-shaped ring is not star-shaped about its interior point.
	var u_ring := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 20),
		Vector2(22, 20), Vector2(22, 6), Vector2(8, 6), Vector2(8, 20), Vector2(0, 20)])
	if not _lathe(u_ring, 0.0, 5.0, "dome").is_empty():
		failures.append("U-shaped ring should fall back, not lathe")
	# Through RoofGeometry: tall round spires are pointed, not inset hats.
	var mesh := RoofGeometry.form_mesh(disc, 20.0, 16.0, "cone")
	if mesh == null:
		failures.append("form_mesh cone produced no mesh")
	else:
		var top_y := -INF
		for v in (MeshArrays.surface(mesh, 0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			top_y = maxf(top_y, v.y)
		if absf(top_y - 36.0) > 0.01:
			failures.append("form_mesh cone tops out at %.2f (want 36)" % top_y)
	# Tag parsing keeps the forms; the rise defaults scale with the span.
	for row in [["onion", "onion"], ["cone", "cone"], ["dome", "dome"]]:
		if BuildingHeights._effective_shape(row[0], "hipped", false) != row[1]:
			failures.append("roof:shape=%s should stay %s" % [row[0], row[1]])
	if absf(BuildingHeights._roof_height_m("dome", 30.0, 0.0, 1.3) - 15.0) > 0.01:
		failures.append("untagged 30 m dome should rise 15 m (half span, no pitch)")

func _roof_only_part_checks(failures: Array[String]) -> void:
	var m2u := WorldScale.metres_to_units()
	var drum := _circle(Vector2(0, 0), 8.0 * m2u, 24)
	var nave := PackedVector2Array([Vector2(-12, -30), Vector2(12, -30), Vector2(12, 12),
		Vector2(-12, 12)])
	for i in nave.size():
		nave[i] *= m2u
	# A slender belfry tower (6 m) under its spire part.
	var tower := PackedVector2Array([Vector2(5, -30), Vector2(11, -30), Vector2(11, -24), Vector2(5, -24)])
	for i in tower.size():
		tower[i] *= m2u
	var b := {"x": 0.0, "z": -9.0 * m2u, "size_x": 24.0, "size_z": 42.0, "footprint": nave,
		"height": 48.0, "height_source": "tag_height", "levels": 0, "kind": "church",
		"religion": "christian", "roof_shape": "gabled", "holes": [], "parts": [
			{"footprint": drum, "x": 0.0, "z": 0.0, "height": 40.0,
				"height_source": "tag_height", "levels": 0, "roof_shape": ""},
			{"footprint": drum, "x": 0.0, "z": 0.0, "height": 48.0,
				"height_source": "tag_height", "levels": 0, "roof_shape": "dome",
				"roof_height_m": 8.0, "min_height_m": 40.0},
			{"footprint": tower, "x": 8.0 * m2u, "z": -27.0 * m2u, "height": 40.0,
				"height_source": "tag_height", "levels": 0, "roof_shape": ""},
			{"footprint": tower, "x": 8.0 * m2u, "z": -27.0 * m2u, "height": 70.0,
				"height_source": "tag_height", "levels": 0, "roof_shape": "cone",
				"roof_height_m": 30.0, "min_height_m": 40.0}]}
	var ctx := BuildingHeights._height_context(_data())
	var plan := BuildingMasses.plan(b, ctx)
	if plan.size() != 4:
		failures.append("drum, dome, tower and spire plan has %d masses (want 4)" % plan.size())
		return
	if str((plan[2] as Dictionary)["shape"]) != "flat" or str((plan[3] as Dictionary)["shape"]) != "cone":
		failures.append("a slender tower under its spire should be flat (got %s), the spire a cone (got %s)"
			% [plan[2]["shape"], plan[3]["shape"]])
	if str((plan[0] as Dictionary)["shape"]) != "flat":
		failures.append("an untagged drum under its dome should be flat, got %s" % plan[0]["shape"])
	var dm := plan[1] as Dictionary
	if str(dm["shape"]) != "dome" or absf(float(dm["min_m"]) - 40.0) > 0.01 \
			or absf(float(dm["wall_m"]) - 40.0) > 0.01 or absf(float(dm["rh_m"]) - 8.0) > 0.01:
		failures.append("roof-only dome part: shape %s min %.2f wall %.2f roof %.2f (want dome 40/40/8)"
			% [dm["shape"], dm["min_m"], dm["wall_m"], dm["rh_m"]])

## An Overpass way from [east, north] metre offsets around LAT/LON.
func _way(id: int, tags: Dictionary, pts_m: Array) -> Dictionary:
	var geom: Array = []
	for p in pts_m:
		var v := p as Vector2
		geom.append({"lat": LAT + v.y / 111320.0,
			"lon": LON + v.x / (111320.0 * cos(deg_to_rad(LAT)))})
	geom.append(geom[0])
	return {"type": "way", "id": id, "tags": tags, "geometry": geom}

func _rect_m(e0: float, n0: float, e1: float, n1: float) -> Array:
	return [Vector2(e0, n0), Vector2(e1, n0), Vector2(e1, n1), Vector2(e0, n1)]

func _circle_m(r: float, n: int) -> Array:
	var out: Array = []
	for v in _circle(Vector2.ZERO, r, n):
		out.append(v)
	return out

func _parse(elements: Array) -> Dictionary:
	return OsmFetcher.parse_features(JSON.stringify({"elements": elements}), LAT, LON)

func _cathedral(f: Dictionary) -> Dictionary:
	for b in f["buildings"]:
		if str((b as Dictionary).get("kind", "")) == "cathedral":
			return b
	return {}

func _mapped_checks(failures: Array[String]) -> void:
	var outline := _way(1, {"building": "cathedral", "name": "Test Cathedral"},
		_rect_m(-12, -30, 12, 12))
	var nave := _way(2, {"building:part": "yes", "height": "30", "roof:shape": "gabled"},
		_rect_m(-12, -30, 12, -8))
	var drum := _way(3, {"building:part": "yes", "height": "40"}, _circle_m(8.0, 24))
	var dome := _way(4, {"building:part": "yes", "height": "55", "min_height": "40",
		"roof:shape": "dome", "roof:height": "15"}, _circle_m(8.0, 24))
	var spire := _way(5, {"building:part": "yes", "height": "70", "roof:shape": "cone",
		"roof:height": "30"}, _rect_m(-3, 6, 3, 12))
	var f := _parse([outline, nave, drum, dome, spire])
	var b := _cathedral(f)
	if b.is_empty() or (b["parts"] as Array).size() != 4:
		failures.append("mapped cathedral should nest 4 parts: %s" % [b.get("parts", [])])
	elif not bool(b.get("mapped_landmark", false)):
		failures.append("cathedral with nave, drum, dome and spire should be mapped")
	var lms: Array = f["landmarks"]
	if lms.size() != 1 or not bool((lms[0] as Dictionary).get("mapped", false)):
		failures.append("its cathedral candidate should carry mapped: %s" % [lms])
	# Unmapped: the bare outline, and parts covering only a fifth of it.
	var bare := _parse([outline])
	if bool(_cathedral(bare).get("mapped_landmark", false)) \
			or bool(((bare["landmarks"] as Array)[0] as Dictionary).get("mapped", false)):
		failures.append("a bare cathedral outline should keep its archetype")
	var thin := _parse([outline, drum, dome])
	if bool(_cathedral(thin).get("mapped_landmark", false)):
		failures.append("parts covering 20% of the outline should not count as mapped")
	# A single tagged rotunda under a dome is mapped; a gabled one is not.
	var rotunda := {"footprint": PackedVector2Array(_circle(Vector2.ZERO, 12.0, 16)),
		"height": 30.0, "height_source": "tag_height", "roof_shape": "dome", "parts": []}
	if not LandmarkFidelity.well_mapped(rotunda, "church"):
		failures.append("a tagged domed rotunda should be mapped")
	rotunda["roof_shape"] = "gabled"
	if LandmarkFidelity.well_mapped(rotunda, "church"):
		failures.append("a gabled rotunda should keep its archetype")
	if LandmarkFidelity.well_mapped(b, "stadium"):
		failures.append("stadiums keep their archetype")
	# A building:part multipolygon nests into its building with its hole.
	var rel := {"type": "relation", "id": 9,
		"tags": {"type": "multipolygon", "building:part": "yes", "height": "20"},
		"members": [
			{"type": "way", "ref": 91, "role": "outer",
				"geometry": _way(0, {}, _rect_m(-10, -28, 10, -10))["geometry"]},
			{"type": "way", "ref": 92, "role": "inner",
				"geometry": _way(0, {}, _rect_m(-4, -22, 4, -16))["geometry"]}]}
	var cb := _cathedral(_parse([outline, rel]))
	var cparts: Array = cb.get("parts", [])
	if cparts.size() != 1 or ((cparts[0] as Dictionary).get("holes", []) as Array).size() != 1:
		failures.append("building:part relation should nest as one part with one hole: %s" % [cparts])

func _landmark_nodes(root: Node) -> int:
	var n := 0
	for c in root.get_children():
		# Siblings sharing a name are renamed, so count the layer meta.
		if str(c.get_meta("lod_layer", "")) == "Landmarks":
			n += 1
	return n

func _candidate_checks(failures: Array[String]) -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	var cands: Array = []
	for i in 8:
		cands.append({"x": -300.0 + 80.0 * i, "z": -200.0, "archetype": "church",
			"name": "C%d" % i, "height": 40.0, "size_x": 20.0, "size_z": 30.0})
	data.landmark_candidates = cands
	var root := Node3D.new()
	TerrainBuilder._landmark_candidates(root, data, ground)
	if _landmark_nodes(root) != 8:
		failures.append("8 candidates should build 8 models, got %d" % _landmark_nodes(root))
	root.free()
	data.landmark_candidates = [{"x": 0.0, "z": -200.0, "archetype": "church",
		"name": "M", "height": 40.0, "size_x": 20.0, "size_z": 30.0, "mapped": true}]
	root = Node3D.new()
	TerrainBuilder._landmark_candidates(root, data, ground)
	if _landmark_nodes(root) != 0:
		failures.append("a mapped candidate should build no archetype")
	root.free()
	# The mapped cathedral and a house beside it stand; unmapped, the
	# archetype clears both.
	var f := _parse([_way(1, {"building": "cathedral", "name": "Test Cathedral"}, _rect_m(-12, -30, 12, 12)),
		_way(2, {"building:part": "yes", "height": "30", "roof:shape": "gabled"}, _rect_m(-12, -30, 12, -8)),
		_way(3, {"building:part": "yes", "height": "40"}, _circle_m(8.0, 24)),
		_way(4, {"building:part": "yes", "height": "55", "min_height": "40", "roof:shape": "dome",
			"roof:height": "15", "roof:material": "copper"}, _circle_m(8.0, 24)),
		_way(5, {"building:part": "yes", "height": "70", "roof:shape": "cone"}, _rect_m(-3, 6, 3, 12)),
		_way(6, {"building": "house", "height": "9"}, _rect_m(18, -4, 28, 4))])
	data.buildings = f["buildings"]
	data.landmark_candidates = f["landmarks"]
	BuildingBuilder.build_buildings(data, ground).free()
	if int(BuildingBuilder.last_stats.get("real", 0)) != 2:
		failures.append("mapped cathedral + house should both stand, got %d" % int(BuildingBuilder.last_stats.get("real", 0)))
	var unmapped: Array = []
	for c in f["landmarks"]:
		var u := (c as Dictionary).duplicate()
		u.erase("mapped")
		unmapped.append(u)
	data.landmark_candidates = unmapped
	BuildingBuilder.build_buildings(data, ground).free()
	if int(BuildingBuilder.last_stats.get("real", 0)) != 0:
		failures.append("an archetype candidate should clear its building and the house, got %d"
			% int(BuildingBuilder.last_stats.get("real", 0)))
	# Copper domes on mapped landmarks weather green, gold stays gold.
	var copper := HeroLook.roof({"roof_material": "copper"}, null) as StandardMaterial3D
	if copper == null or copper.albedo_color.g <= copper.albedo_color.r:
		failures.append("a mapped copper roof should be verdigris")
	if HeroLook.roof({"roof_material": "gilded"}, null) != LandmarkMaterials.gold():
		failures.append("a gilded roof should be gold")
	if HeroLook.roof({"roof_material": "tiles"}, null) != null:
		failures.append("an untagged-colour tile roof keeps the fabric material")

func _site_checks(failures: Array[String]) -> void:
	var data := _data()
	data.latitude = 51.5030
	data.longitude = -0.1200
	data.quality_preset = RenderSettings.Preset.FAST
	var e := LocationData.landmark_entry(data.latitude, data.longitude, "")
	data.landmark_type = str(e.get("type", "none"))
	data.has_landmark_site = true
	data.landmark_lat = float(e["lat"])
	data.landmark_lon = float(e["lon"])
	var site := TerrainBuilder.landmark_site_xz(data)
	var osm: Array = [{"x": site.x + 10.0, "z": site.y, "archetype": "tower", "name": "Clock Tower"}]
	for i in 10:
		osm.append({"x": 200.0 + 50.0 * i, "z": 300.0, "archetype": "church", "name": "C%d" % i})
	var picked := LandmarkSites.select(data, osm)
	for c in picked:
		if str((c as Dictionary).get("name", "")) == "Clock Tower":
			failures.append("an OSM tower on the Big Ben site should be dropped")
	if picked.size() != LandmarkSites.MAX_BY_PRESET[RenderSettings.Preset.FAST]:
		failures.append("FAST should keep %d candidates, got %d"
			% [LandmarkSites.MAX_BY_PRESET[RenderSettings.Preset.FAST], picked.size()])
	# New York: One WTC is the primary, the other icons come first as
	# registry candidates that build their own models and clear their
	# grounds (an OSM building inside clear_m goes, one beyond stays).
	var ny := _data()
	ny.latitude = 40.7128
	ny.longitude = -74.0060
	var ne := LocationData.landmark_entry(ny.latitude, ny.longitude, "")
	ny.landmark_type = str(ne["type"])
	ny.has_landmark_site = true
	ny.landmark_lat = float(ne["lat"])
	ny.landmark_lon = float(ne["lon"])
	var reg := LandmarkSites.select(ny, osm)
	var types: Array = reg.filter(func(c: Dictionary) -> bool: return c.has("type")).map(
		func(c: Dictionary) -> String: return str(c["type"]))
	if not types.has("empire_state") or not types.has("statue_liberty") or types.has("one_wtc"):
		failures.append("New York candidates should lead with the other registry icons, got %s" % [types])
	ny.landmark_candidates = reg.filter(func(c: Dictionary) -> bool: return c.has("type"))
	# The test data has no far DEM: stand the 4-5 km icons inside the
	# detailed extent for the build.
	var near: Array = []
	for i in ny.landmark_candidates.size():
		var nc := (ny.landmark_candidates[i] as Dictionary).duplicate()
		nc["x"] = -300.0 + 300.0 * i
		nc["z"] = 200.0
		near.append(nc)
	ny.landmark_candidates = near
	var root := Node3D.new()
	TerrainBuilder._landmark_candidates(root, ny, GroundTruth.new(ny))
	var esb_built := false
	for c in root.get_children():
		esb_built = esb_built or str(c.name).begins_with("Landmark_empire_state")
	root.free()
	if not esb_built:
		failures.append("the Empire State Building candidate should build its own model")
	var esb := (ny.landmark_candidates.filter(func(c: Dictionary) -> bool:
		return str(c["type"]) == "empire_state")[0] as Dictionary).duplicate()
	esb["x"] = 300.0
	esb["z"] = 0.0
	ny.landmark_candidates = [esb]
	if not BuildingBuilder._near_landmark_candidate(ny, 300.0 + float(esb["clear_m"]) - 5.0, 0.0):
		failures.append("a building inside the Empire State Building's grounds should be cleared")
	if BuildingBuilder._near_landmark_candidate(ny, 300.0 + float(esb["clear_m"]) + 10.0, 0.0):
		failures.append("a building beyond the Empire State Building's grounds should stand")
	_bridge_checks(failures)

## Bridges clear along their span, take over the OSM deck there, and
## stand on the water.
func _bridge_checks(failures: Array[String]) -> void:
	var gg := LocationData.entry_for_type("golden_gate")
	var ax := LandmarkSites.axis(gg)
	var half := float(gg["span_m"]) * 0.5
	if LandmarkSites.span_dist(ax * (half - 100.0), Vector2.ZERO, gg) > 0.01:
		failures.append("a point on the Golden Gate deck should be on its span")
	if absf(LandmarkSites.span_dist(ax * (half + 80.0), Vector2.ZERO, gg) - 80.0) > 0.01:
		failures.append("a point 80 m past the span end should be 80 m from it")
	var side := Vector2(-ax.y, ax.x)
	if absf(LandmarkSites.span_dist(side * 50.0, Vector2.ZERO, gg) - 50.0) > 0.01:
		failures.append("a point 50 m off the axis should be 50 m from the span")
	var road := PackedVector2Array()
	var t := -half - 500.0
	while t <= half + 500.0:
		road.append(ax * t)
		t += 50.0
	var pieces := LandmarkSites.outside_spans(road, [[Vector2.ZERO, gg]])
	if pieces.size() != 2:
		failures.append("the OSM deck should split into the two approaches, got %d pieces" % pieces.size())
	for piece in pieces:
		for q in (piece as PackedVector2Array):
			if absf(q.dot(ax)) < half:
				failures.append("an OSM deck point inside the modelled span survived: %s" % str(q))
				break
	if LandmarkSites.outside_spans(road, []).size() != 1:
		failures.append("with no bridge the OSM deck stays whole")
	var data := _data()
	var ground := GroundTruth.new(data)
	var y := TerrainBuilder._hero_y(data, ground, 0.0, 0.0, {"base": "water"}, 10.0)
	if absf(y - ground.water_level_at(0.0, 0.0)) > 0.001:
		failures.append("a bridge on the water should stand on the water surface")
