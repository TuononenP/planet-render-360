extends SceneTree

## Focused parser test (offline): godot --headless --script tests/osm_test.gd
## Feeds recorded-shape Overpass JSON through OsmFetcher.parse_features:
## the v1 fixture (back-compat) plus a v2 fixture (footprints, rotation,
## rich tags, parts, attributed roads, waterways, trees, barriers).

const FIXTURE := """
{"elements":[
 {"type":"way","tags":{"building":"yes","building:levels":"5","name":"Test Hall"},
  "geometry":[{"lat":48.8570,"lon":2.3520},{"lat":48.8570,"lon":2.3530},
              {"lat":48.8566,"lon":2.3530},{"lat":48.8566,"lon":2.3520}]},
 {"type":"way","tags":{"highway":"primary","name":"Rue Test"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8570,"lon":2.3540}]},
 {"type":"way","tags":{"landuse":"forest"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8560,"lon":2.3540},
              {"lat":48.8570,"lon":2.3540},{"lat":48.8560,"lon":2.3510}]},
 {"type":"way","tags":{"natural":"water"},
  "geometry":[{"lat":48.8590,"lon":2.3510},{"lat":48.8590,"lon":2.3540},
              {"lat":48.8600,"lon":2.3540},{"lat":48.8590,"lon":2.3510}]},
 {"type":"way","tags":{"building":"church","building:levels":"3","name":"Old Church"},
  "geometry":[{"lat":48.8580,"lon":2.3510},{"lat":48.8580,"lon":2.3520},
              {"lat":48.8576,"lon":2.3520},{"lat":48.8576,"lon":2.3510}]},
 {"type":"node","tags":{"man_made":"lighthouse","name":"Test Light","height":"28"},"lat":48.8590,"lon":2.3550},
 {"type":"node","tags":{"name":"No geometry"},"lat":48.8566,"lon":2.3522}
]}
"""

## v2 fixture (frame centre 48.8566, 2.3522): a 20×10 m block rotated
## 30° with every rich tag, an L-shaped block, an untagged shed, a
## zero-height fall-through, nested + orphan building:parts, attributed
## roads (incl. an id-duplicate), a river, a riverbank polygon, a
## coastline, two tree nodes, a fence, and an unmapped garden.
const FIXTURE_V2 := """
{"elements":[
 {"type":"way","id":1,"tags":{"building":"apartments","height":"24","building:levels":"7","building:colour":"beige","building:material":"brick","roof:shape":"mansard","roof:colour":"grey","roof:material":"slate","roof:height":"3.5","min_height":"2.5","name":"Rotated Hall"},
  "geometry":[{"lat":48.8569156,"lon":2.3524159},{"lat":48.8570061,"lon":2.3526524},
              {"lat":48.8570844,"lon":2.3525841},{"lat":48.8569939,"lon":2.3523476},
              {"lat":48.8569156,"lon":2.3524159}]},
 {"type":"way","id":2,"tags":{"building":"house","building:levels":"4","name":"L House"},
  "geometry":[{"lat":48.8559276,"lon":2.3533908},{"lat":48.8559276,"lon":2.3536092},
              {"lat":48.8560000,"lon":2.3536092},{"lat":48.8560000,"lon":2.3535000},
              {"lat":48.8560724,"lon":2.3535000},{"lat":48.8560724,"lon":2.3533908},
              {"lat":48.8559276,"lon":2.3533908}]},
 {"type":"way","id":3,"tags":{"building":"shed"},
  "geometry":[{"lat":48.8549819,"lon":2.3529659},{"lat":48.8549819,"lon":2.3530341},
              {"lat":48.8550181,"lon":2.3530341},{"lat":48.8550181,"lon":2.3529659},
              {"lat":48.8549819,"lon":2.3529659}]},
 {"type":"way","id":4,"tags":{"building":"yes","height":"0","building:levels":"2"},
  "geometry":[{"lat":48.8554729,"lon":2.3514590},{"lat":48.8554729,"lon":2.3515410},
              {"lat":48.8555271,"lon":2.3515410},{"lat":48.8555271,"lon":2.3514590},
              {"lat":48.8554729,"lon":2.3514590}]},
 {"type":"way","id":5,"tags":{"building:part":"yes","building:levels":"2","building:colour":"white"},
  "geometry":[{"lat":48.8569955,"lon":2.3525000},{"lat":48.8569955,"lon":2.3525546},
              {"lat":48.8570226,"lon":2.3525546},{"lat":48.8570226,"lon":2.3525000},
              {"lat":48.8569955,"lon":2.3525000}]},
 {"type":"way","id":6,"tags":{"building:part":"yes"},
  "geometry":[{"lat":48.8560317,"lon":2.3534113},{"lat":48.8560317,"lon":2.3534522},
              {"lat":48.8560588,"lon":2.3534522},{"lat":48.8560588,"lon":2.3534113},
              {"lat":48.8560317,"lon":2.3534113}]},
 {"type":"way","id":7,"tags":{"building:part":"yes","height":"9"},
  "geometry":[{"lat":48.8589774,"lon":2.3559659},{"lat":48.8589774,"lon":2.3560341},
              {"lat":48.8590226,"lon":2.3560341},{"lat":48.8590226,"lon":2.3559659},
              {"lat":48.8589774,"lon":2.3559659}]},
 {"type":"way","id":101,"tags":{"highway":"residential","width":"7","lanes":"2","surface":"sett","bridge":"yes","layer":"1","name":"Rue Test"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8565,"lon":2.3525},{"lat":48.8570,"lon":2.3540}]},
 {"type":"way","id":101,"tags":{"highway":"residential","width":"7","lanes":"2","surface":"sett","bridge":"yes","layer":"1","name":"Rue Test"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8565,"lon":2.3525},{"lat":48.8570,"lon":2.3540}]},
 {"type":"way","id":102,"tags":{"highway":"primary","lanes":"4","tunnel":"yes"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8570,"lon":2.3540}]},
 {"type":"way","id":103,"tags":{"highway":"footway"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8561,"lon":2.3511}]},
 {"type":"way","id":201,"tags":{"waterway":"river","name":"Test River"},
  "geometry":[{"lat":48.8558,"lon":2.3515},{"lat":48.8563,"lon":2.3530},{"lat":48.8568,"lon":2.3545}]},
 {"type":"way","id":202,"tags":{"waterway":"riverbank"},
  "geometry":[{"lat":48.8550,"lon":2.3510},{"lat":48.8550,"lon":2.3515},{"lat":48.8555,"lon":2.3515},
              {"lat":48.8555,"lon":2.3510},{"lat":48.8550,"lon":2.3510}]},
 {"type":"way","id":203,"tags":{"natural":"coastline"},
  "geometry":[{"lat":48.8600,"lon":2.3500},{"lat":48.8605,"lon":2.3510}]},
 {"type":"node","id":301,"tags":{"natural":"tree"},"lat":48.8566,"lon":2.3522},
 {"type":"node","id":302,"tags":{"natural":"tree"},"lat":48.8575,"lon":2.3535},
 {"type":"way","id":401,"tags":{"barrier":"fence"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8562,"lon":2.3512},{"lat":48.8564,"lon":2.3514}]},
 {"type":"way","id":501,"tags":{"leisure":"garden","name":"Test Garden"},
  "geometry":[{"lat":48.8560,"lon":2.3510},{"lat":48.8560,"lon":2.3515},
              {"lat":48.8565,"lon":2.3515},{"lat":48.8565,"lon":2.3510}]}
]}
"""

## T2.4 land-cover fixture (same frame centre): one way per new §2.6
## class (wetland/sand/rock/glacier/orchard/cemetery/pitch/quarry),
## a garden (grass) and a reservoir (water), a forest multipolygon
## whose outer arrives as two open halves plus an inner hole, a
## riverbank multipolygon, and a route + a boundary relation that
## must both be skipped (not areas).
const FIXTURE_LAND := """
{"elements":[
 {"type":"way","id":601,"tags":{"natural":"wetland"},
  "geometry":[{"lat":48.8540,"lon":2.3500},{"lat":48.8540,"lon":2.3502},
              {"lat":48.8542,"lon":2.3502},{"lat":48.8542,"lon":2.3500},
              {"lat":48.8540,"lon":2.3500}]},
 {"type":"way","id":602,"tags":{"natural":"beach"},
  "geometry":[{"lat":48.8543,"lon":2.3500},{"lat":48.8543,"lon":2.3502},
              {"lat":48.8545,"lon":2.3502},{"lat":48.8545,"lon":2.3500},
              {"lat":48.8543,"lon":2.3500}]},
 {"type":"way","id":603,"tags":{"natural":"scree"},
  "geometry":[{"lat":48.8546,"lon":2.3500},{"lat":48.8546,"lon":2.3502},
              {"lat":48.8548,"lon":2.3502},{"lat":48.8548,"lon":2.3500},
              {"lat":48.8546,"lon":2.3500}]},
 {"type":"way","id":604,"tags":{"natural":"glacier"},
  "geometry":[{"lat":48.8549,"lon":2.3500},{"lat":48.8549,"lon":2.3502},
              {"lat":48.8551,"lon":2.3502},{"lat":48.8551,"lon":2.3500},
              {"lat":48.8549,"lon":2.3500}]},
 {"type":"way","id":605,"tags":{"landuse":"vineyard"},
  "geometry":[{"lat":48.8552,"lon":2.3500},{"lat":48.8552,"lon":2.3502},
              {"lat":48.8554,"lon":2.3502},{"lat":48.8554,"lon":2.3500},
              {"lat":48.8552,"lon":2.3500}]},
 {"type":"way","id":606,"tags":{"landuse":"cemetery"},
  "geometry":[{"lat":48.8555,"lon":2.3500},{"lat":48.8555,"lon":2.3502},
              {"lat":48.8557,"lon":2.3502},{"lat":48.8557,"lon":2.3500},
              {"lat":48.8555,"lon":2.3500}]},
 {"type":"way","id":607,"tags":{"leisure":"pitch","sport":"soccer"},
  "geometry":[{"lat":48.8558,"lon":2.3500},{"lat":48.8558,"lon":2.3502},
              {"lat":48.8560,"lon":2.3502},{"lat":48.8560,"lon":2.3500},
              {"lat":48.8558,"lon":2.3500}]},
 {"type":"way","id":608,"tags":{"landuse":"quarry"},
  "geometry":[{"lat":48.8561,"lon":2.3500},{"lat":48.8561,"lon":2.3502},
              {"lat":48.8563,"lon":2.3502},{"lat":48.8563,"lon":2.3500},
              {"lat":48.8561,"lon":2.3500}]},
 {"type":"way","id":609,"tags":{"leisure":"garden"},
  "geometry":[{"lat":48.8564,"lon":2.3500},{"lat":48.8564,"lon":2.3502},
              {"lat":48.8566,"lon":2.3502},{"lat":48.8566,"lon":2.3500},
              {"lat":48.8564,"lon":2.3500}]},
 {"type":"way","id":610,"tags":{"landuse":"reservoir"},
  "geometry":[{"lat":48.8567,"lon":2.3500},{"lat":48.8567,"lon":2.3502},
              {"lat":48.8569,"lon":2.3502},{"lat":48.8569,"lon":2.3500},
              {"lat":48.8567,"lon":2.3500}]},
 {"type":"relation","id":701,"tags":{"type":"multipolygon","natural":"wood","name":"Holed Wood"},
  "members":[
   {"type":"way","ref":7011,"role":"outer",
    "geometry":[{"lat":48.8570,"lon":2.3520},{"lat":48.8570,"lon":2.3530},
                {"lat":48.8575,"lon":2.3530}]},
   {"type":"way","ref":7012,"role":"outer",
    "geometry":[{"lat":48.8575,"lon":2.3530},{"lat":48.8575,"lon":2.3520},
                {"lat":48.8570,"lon":2.3520}]},
   {"type":"way","ref":7013,"role":"inner",
    "geometry":[{"lat":48.8572,"lon":2.3524},{"lat":48.8572,"lon":2.3526},
                {"lat":48.8574,"lon":2.3526},{"lat":48.8574,"lon":2.3524},
                {"lat":48.8572,"lon":2.3524}]}]},
 {"type":"relation","id":702,"tags":{"type":"multipolygon","waterway":"riverbank"},
  "members":[
   {"type":"way","ref":7021,"role":"outer",
    "geometry":[{"lat":48.8540,"lon":2.3540},{"lat":48.8540,"lon":2.3544},
                {"lat":48.8543,"lon":2.3542},{"lat":48.8540,"lon":2.3540}]}]},
 {"type":"relation","id":703,"tags":{"type":"route","waterway":"river"},
  "members":[
   {"type":"way","ref":7031,"role":"",
    "geometry":[{"lat":48.8558,"lon":2.3515},{"lat":48.8563,"lon":2.3530},
                {"lat":48.8568,"lon":2.3545}]}]},
 {"type":"relation","id":704,"tags":{"type":"boundary","leisure":"nature_reserve"},
  "members":[
   {"type":"way","ref":7041,"role":"",
    "geometry":[{"lat":48.8580,"lon":2.3560},{"lat":48.8580,"lon":2.3564},
                {"lat":48.8584,"lon":2.3564},{"lat":48.8584,"lon":2.3560},
                {"lat":48.8580,"lon":2.3560}]}]}
]}
"""

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	_v1_checks(failures)
	_v2_checks(failures)
	_land_checks(failures)
	_query_checks(failures)
	_chain_checks(failures)
	await _busy_checks(failures)
	_null_node_checks(failures)
	_tree_tag_checks(failures)

	if failures.is_empty():
		print("OSM OK: parser, footprints, tags, land cover, query, retry chain")
		quit(0)
	else:
		for f in failures:
			printerr("OSM FAIL: ", f)
		quit(1)

## v1 fixture: back-compat — same buildings/landmarks/land as before,
## roads now in the §2.5 attributed shape.
func _v1_checks(failures: Array[String]) -> void:
	var result := OsmFetcher.parse_features(FIXTURE, 48.8566, 2.3522)
	var buildings: Array = result["buildings"]
	var roads: Array = result["roads"]
	# Any-place landmarks: the church way and lighthouse node must be
	# extracted as archetype candidates at their true positions.
	var landmarks: Array = result.get("landmarks", [])
	var archetypes: Array = landmarks.map(func(c: Dictionary) -> String: return str(c["archetype"]))
	if not archetypes.has("church") or not archetypes.has("lighthouse"):
		failures.append("expected church+lighthouse candidates, got %s" % [archetypes])
	if OsmFetcher.archetype_for({"building": "yes"}) != "":
		failures.append("ordinary buildings must not become landmarks")
	if buildings.size() != 2:
		failures.append("expected 2 buildings, got %d" % buildings.size())
	else:
		var b: Dictionary = buildings[0]
		if str(b["name"]) != "Test Hall":
			failures.append("building name lost: %s" % b)
		if absf(float(b["height"]) - 16.0) > 0.01:
			failures.append("levels->height wrong: %s" % b["height"])
		if str(b["height_source"]) != "levels":
			failures.append("height_source should be levels: %s" % b)
		if float(b["size_x"]) < 3.0 or float(b["size_z"]) < 3.0:
			failures.append("building footprint too small: %s" % b)
		if (b["footprint"] as PackedVector2Array).size() != 4:
			failures.append("v1 building must keep its 4-pt footprint: %s" % b)
	if roads.size() != 1:
		failures.append("expected 1 road, got %d" % roads.size())
	else:
		var r0: Dictionary = roads[0]
		if (r0["points"] as PackedVector2Array).size() != 2:
			failures.append("expected road with 2 points, got %s" % [roads])
		if str(r0["class"]) != "primary" or absf(float(r0["width_m"]) - 10.0) > 0.01:
			failures.append("road class/width wrong: %s" % r0)
	var land: Array = result["land"]
	if land.size() != 2:
		failures.append("expected 2 land polygons, got %d" % land.size())
	else:
		var classes: Array = land.map(func(p: Dictionary) -> String: return str(p["class"]))
		if not classes.has("forest") or not classes.has("water"):
			failures.append("land classes wrong: %s" % [classes])
		var forest_poly: PackedVector2Array = land[0]["points"]
		var centroid := (forest_poly[0] + forest_poly[1] + forest_poly[2]) / 3.0
		if not TerrainBuilder.point_in_polygon(centroid, forest_poly):
			failures.append("point-in-polygon failed at forest centroid")
		if TerrainBuilder.land_color(Vector2(9999, 9999), land, Color.RED) != Color.RED:
			failures.append("land_color must fall back outside polygons")

func _by_name(buildings: Array, bname: String) -> Dictionary:
	for b in buildings:
		if str(b["name"]) == bname:
			return b
	return {}

func _v2_checks(failures: Array[String]) -> void:
	var result := OsmFetcher.parse_features(FIXTURE_V2, 48.8566, 2.3522)
	var buildings: Array = result["buildings"]
	# 4 tagged buildings + the orphan part promoted to a building.
	if buildings.size() != 5:
		failures.append("expected 5 v2 buildings, got %d" % buildings.size())
		return
	var rot := _by_name(buildings, "Rotated Hall")
	if rot.is_empty():
		failures.append("Rotated Hall missing")
		return
	# Type tags ArchitectureStyle keys off ride along on every building.
	if str(rot["kind"]) != "apartments" or str(_by_name(buildings, "L House")["kind"]) != "house":
		failures.append("building kind lost: %s / %s" % [rot.get("kind"), _by_name(buildings, "L House").get("kind")])
	var typed := OsmFetcher.parse_features("""{"elements":[
	 {"type":"way","id":91,"tags":{"building":"yes","amenity":"place_of_worship","religion":"muslim","denomination":"sunni"},
	  "geometry":[{"lat":48.8570,"lon":2.3520},{"lat":48.8570,"lon":2.3530},{"lat":48.8566,"lon":2.3530},{"lat":48.8566,"lon":2.3520}]},
	 {"type":"way","id":92,"tags":{"building":"yes","shop":"bakery"},
	  "geometry":[{"lat":48.8560,"lon":2.3520},{"lat":48.8560,"lon":2.3530},{"lat":48.8556,"lon":2.3530},{"lat":48.8556,"lon":2.3520}]},
	 {"type":"way","id":93,"tags":{"building":"warehouse","industrial":"logistics"},
	  "geometry":[{"lat":48.8550,"lon":2.3520},{"lat":48.8550,"lon":2.3530},{"lat":48.8546,"lon":2.3530},{"lat":48.8546,"lon":2.3520}]}
	]}""", 48.8566, 2.3522)["buildings"] as Array
	var uses: Array = typed.map(func(t: Dictionary) -> String: return "%s/%s/%s" % [t["kind"], t["use"], t["religion"]])
	for want in ["yes/place_of_worship/muslim", "yes/shop/", "warehouse/industrial/"]:
		if not uses.has(want):
			failures.append("building type tags: expected %s in %s" % [want, uses])
	# Footprint: all 5 raw vertices (4 + closing), rotation preserved.
	var fp: PackedVector2Array = rot["footprint"]
	if fp.size() != 5:
		failures.append("rotated footprint should keep 5 vertices, got %d" % fp.size())
	var edge := fp[1] - fp[0]
	var ang := rad_to_deg(atan2(edge.y, edge.x))
	if absf(absf(ang) - 30.0) > 1.5:
		failures.append("rotated footprint edge should sit at |30deg|, got %.1f" % ang)
	# Centroid in internal units (≈ +21.97 m E, −44.22 m N from frame;
	# 1 unit = 1 m since the T7.0 cutover).
	var mu := WorldScale.metres_to_units()
	if absf(float(rot["x"]) - 21.97 * mu) > 0.6 * mu or absf(float(rot["z"]) + 44.22 * mu) > 0.6 * mu:
		failures.append("rotated centroid wrong: (%s, %s)" % [rot["x"], rot["z"]])
	# Every rich tag round-trips; the height tag beats levels.
	if absf(float(rot["height"]) - 24.0) > 0.01 or str(rot["height_source"]) != "tag_height":
		failures.append("height tag must win with tag_height: %s" % rot)
	if int(rot["levels"]) != 7:
		failures.append("levels lost: %s" % rot)
	if absf(float(rot["min_height_m"]) - 2.5) > 0.01:
		failures.append("min_height lost: %s" % rot)
	if str(rot["colour"]) != "beige" or str(rot["material"]) != "brick":
		failures.append("colour/material lost: %s" % rot)
	if str(rot["roof_shape"]) != "mansard" or str(rot["roof_colour"]) != "grey" \
			or str(rot["roof_material"]) != "slate" \
			or absf(float(rot["roof_height_m"]) - 3.5) > 0.01:
		failures.append("roof tags lost: %s" % rot)
	# Nested part with its own tags: own height, own colour.
	var rparts: Array = rot["parts"]
	if rparts.size() != 1:
		failures.append("Rotated Hall should nest 1 part, got %d" % rparts.size())
	else:
		var rp: Dictionary = rparts[0]
		if absf(float(rp["height"]) - 6.4) > 0.01 or str(rp["colour"]) != "white":
			failures.append("nested part wrong: %s" % rp)
		if (rp["footprint"] as PackedVector2Array).size() != 5:
			failures.append("nested part must keep its footprint: %s" % rp)
	# L-shape: 7 vertices, levels-resolved height, inheriting part.
	var ell := _by_name(buildings, "L House")
	if (ell["footprint"] as PackedVector2Array).size() != 7:
		failures.append("L footprint should keep 7 vertices: %s" % ell)
	if absf(float(ell["height"]) - 12.8) > 0.01 or str(ell["height_source"]) != "levels":
		failures.append("L height should be 4 levels: %s" % ell)
	var lparts: Array = ell["parts"]
	if lparts.size() != 1:
		failures.append("L House should nest 1 part, got %d" % lparts.size())
	elif absf(float(lparts[0]["height"]) - 12.8) > 0.01 \
			or str(lparts[0]["height_source"]) != "levels":
		failures.append("tagless part must inherit the parent height: %s" % lparts[0])
	# Untagged shed: v1 default, flagged for T4.2 regional inference.
	var shed := _by_name(buildings, "")
	if shed.is_empty():
		failures.append("untagged shed missing")
	elif absf(float(shed["height"]) - 10.0) > 0.01 \
			or str(shed["height_source"]) != "default" or int(shed["levels"]) != 0:
		failures.append("shed should be 10 m default: %s" % shed)
	# height=0 falls through to levels (never a silent 0 m).
	var zero_ok := false
	for b in buildings:
		if str(b.get("name", "")) == "" and int(b["levels"]) == 2 \
				and absf(float(b["height"]) - 6.4) < 0.01 \
				and str(b["height_source"]) == "levels":
			zero_ok = true
	if not zero_ok:
		failures.append("height=0 must fall through to levels")
	# Orphan part: promoted to a building, never dropped.
	var orphan_ok := false
	for b in buildings:
		if (b["footprint"] as PackedVector2Array).size() == 5 \
				and absf(float(b["height"]) - 9.0) < 0.01 \
				and str(b["height_source"]) == "tag_height":
			orphan_ok = true
	if not orphan_ok:
		failures.append("orphan part must be promoted to a building")
	# Attributed roads (§2.5): width tag → lanes×3 → class default.
	var roads: Array = result["roads"]
	if roads.size() != 3:
		failures.append("expected 3 roads (id-duplicate merged), got %d" % roads.size())
	else:
		var r1: Dictionary = roads[0]
		if (r1["points"] as PackedVector2Array).size() != 3 \
				or absf(float(r1["width_m"]) - 7.0) > 0.01 \
				or int(r1["lanes"]) != 2 or str(r1["surface"]) != "sett" \
				or not bool(r1["bridge"]) or bool(r1["tunnel"]) \
				or int(r1["layer"]) != 1 or str(r1["class"]) != "residential":
			failures.append("R1 attributes wrong: %s" % r1)
		var r2: Dictionary = roads[1]
		if absf(float(r2["width_m"]) - 12.0) > 0.01 \
				or not bool(r2["tunnel"]) or bool(r2["bridge"]):
			failures.append("R2 should be lanes×3 with a tunnel: %s" % r2)
		if absf(float(roads[2]["width_m"]) - 2.0) > 0.01 \
				or str(roads[2]["class"]) != "footway":
			failures.append("R3 should be class-default footway: %s" % roads[2])
	# V1 downgrade for the pipeline/RoadBuilder (deleted T4.4).
	var v1 := OsmFetcher.roads_to_v1(roads)
	if v1.size() != 3 or not (v1[0] is PackedVector2Array) \
			or (v1[0] as PackedVector2Array).size() != 3:
		failures.append("roads_to_v1 must yield bare centrelines: %s" % [v1])
	# Waterways (§2.6): river line + coastline; riverbank → land water.
	var waters: Array = result["waterways"]
	if waters.size() != 2:
		failures.append("expected 2 waterways, got %d" % waters.size())
	else:
		if str(waters[0]["class"]) != "river" \
				or absf(float(waters[0]["width_m"]) - 12.0) > 0.01 \
				or (waters[0]["points"] as PackedVector2Array).size() != 3:
			failures.append("river wrong: %s" % waters[0])
		if str(waters[1]["class"]) != "coastline" \
				or absf(float(waters[1]["width_m"])) > 0.001:
			failures.append("coastline wrong: %s" % waters[1])
	var v2land: Array = result["land"]
	var v2classes: Array = v2land.map(func(p: Dictionary) -> String: return str(p["class"]))
	if v2land.size() != 2 or not v2classes.has("water") or not v2classes.has("grass"):
		failures.append("riverbank should land as water + the T2.3-deferred garden as grass: %s" % [v2land])
	# Trees (§2.6): both nodes, the first exactly on the frame centre.
	var trees: Array = result["trees"]
	if trees.size() != 2:
		failures.append("expected 2 trees, got %d" % trees.size())
	elif absf(float(trees[0]["x"])) > 0.01 or absf(float(trees[0]["z"])) > 0.01:
		failures.append("frame-centre tree should sit at origin: %s" % trees[0])
	# Barriers: parsed (no LocationData field yet — contract gap).
	var barriers: Array = result["barriers"]
	if barriers.size() != 1 or str(barriers[0]["class"]) != "fence" \
			or (barriers[0]["points"] as PackedVector2Array).size() != 3:
		failures.append("fence barrier wrong: %s" % [barriers])
	# No archetypes in this fixture.
	if not (result["landmarks"] as Array).is_empty():
		failures.append("v2 fixture must yield no landmarks: %s" % [result["landmarks"]])
	# Payload merge: detailed + ring concatenate; garbage never kills
	# the good side.
	var m := OsmFetcher.merge_payloads('{"elements":[{"type":"node","id":1}]}',
		'{"elements":[{"type":"node","id":2}]}')
	if (JSON.parse_string(m) as Dictionary)["elements"].size() != 2:
		failures.append("merge_payloads must concatenate: %s" % m)
	var m2 := OsmFetcher.merge_payloads('{"elements":[{"type":"node","id":1}]}', "garbage{{{")
	if (JSON.parse_string(m2) as Dictionary)["elements"].size() != 1:
		failures.append("merge_payloads must survive a bad side: %s" % m2)
	# LocationData round-trip: every parsed layer assigns and reads back.
	var data := LocationData.new()
	data.buildings = buildings
	data.roads = roads
	data.land_polygons = v2land
	data.waterways = waters
	data.trees = trees
	if data.buildings.size() != 5 or data.roads.size() != 3 \
			or data.land_polygons.size() != 2 or data.waterways.size() != 2 \
			or data.trees.size() != 2:
		failures.append("LocationData round-trip lost a layer")
	if str(data.buildings[0]["height_source"]) != "tag_height" \
			or str(data.roads[0]["surface"]) != "sett" \
			or str(data.waterways[0]["class"]) != "river":
		failures.append("LocationData round-trip lost tags")

## T2.4: every new §2.6 class parses end to end, multipolygon
## relations stitch outer halves and keep inner holes, and route /
## boundary relations are skipped.
func _land_checks(failures: Array[String]) -> void:
	var result := OsmFetcher.parse_features(FIXTURE_LAND, 48.8566, 2.3522)
	var land: Array = result["land"]
	var classes: Array = land.map(func(p: Dictionary) -> String: return str(p["class"]))
	var want := ["wetland", "sand", "rock", "glacier", "orchard",
		"cemetery", "pitch", "quarry", "grass", "forest"]
	for c in want:
		if not classes.has(c):
			failures.append("land fixture missing class %s: %s" % [c, classes])
	if classes.count("water") != 2:
		failures.append("expected reservoir + riverbank waters, got %s" % [classes])
	if land.size() != 12:
		failures.append("expected 12 land polygons, got %d (%s)" % [land.size(), classes])
	# Contract §2.6: every entry carries `holes` (ways: empty).
	for p in land:
		if not (p as Dictionary).has("holes"):
			failures.append("land entry missing holes key: %s" % [p])
	# The forest multipolygon: two open halves stitched into one
	# closed 5-pt outer, one 5-pt hole sitting inside it.
	var woods: Array = land.filter(func(p: Dictionary) -> bool: return str(p["class"]) == "forest")
	if woods.size() != 1:
		failures.append("expected 1 forest multipolygon, got %d" % woods.size())
	else:
		var outer: PackedVector2Array = woods[0]["points"]
		var holes: Array = woods[0]["holes"]
		if outer.size() != 5 or outer[0].distance_to(outer[4]) > 0.001:
			failures.append("outer halves should stitch into a closed 5-pt ring: %s" % [outer])
		if holes.size() != 1 or (holes[0] as PackedVector2Array).size() != 5:
			failures.append("forest should keep its 1 inner hole: %s" % [holes])
		elif not TerrainBuilder.point_in_polygon(
				(holes[0] as PackedVector2Array)[0], outer):
			failures.append("hole should sit inside the outer ring")
	# The riverbank multipolygon lands as water.
	var rb: Array = land.filter(func(p: Dictionary) -> bool:
		return str(p["class"]) == "water" \
			and ((p["points"] as PackedVector2Array).size() == 4))
	if rb.size() != 1:
		failures.append("riverbank multipolygon should land as a 4-pt water: %s" % [land])
	# Route + boundary relations yield no land, no waterways, no landmarks.
	if not (result["waterways"] as Array).is_empty():
		failures.append("route relation must not yield waterways: %s" % [result["waterways"]])
	if not (result["landmarks"] as Array).is_empty():
		failures.append("land fixture must yield no landmarks: %s" % [result["landmarks"]])
	# Full mapping table, incl. synonyms and multi-key precedence.
	var table := [
		[{"natural": "sand"}, "sand"], [{"natural": "dune"}, "sand"],
		[{"natural": "bare_rock"}, "rock"], [{"natural": "rock"}, "rock"],
		[{"natural": "shingle"}, "rock"], [{"natural": "mud"}, "wetland"],
		[{"landuse": "orchard"}, "orchard"], [{"natural": "heath"}, "grass"],
		[{"landuse": "recreation_ground"}, "grass"], [{"natural": "bay"}, "water"],
		[{"landuse": "basin"}, "water"], [{"natural": "scrub", "water": "pond"}, "water"],
		[{"leisure": "pitch", "landuse": "meadow"}, "pitch"],
		[{"landuse": "forest", "leisure": "nature_reserve"}, "forest"],
	]
	for row in table:
		var got := OsmFetcher.land_class(row[0])
		if got != row[1]:
			failures.append("land_class(%s) should be %s, got %s" % [row[0], row[1], got])
	# Deliberately unmapped (register): peaks, rails, reserves, graves.
	for tags in [{"natural": "peak"}, {"landuse": "railway"},
			{"leisure": "nature_reserve"}, {"amenity": "grave_yard"},
			{"leisure": "sports_centre"}, {"natural": "tree"}]:
		if OsmFetcher.land_class(tags) != "":
			failures.append("land_class(%s) should stay unmapped" % [tags])

func _query_checks(failures: Array[String]) -> void:
	# Preset maps: the detailed query reaches the 1200 m half-extent on
	# every preset (T7.0); the ring reaches past it on Balanced+.
	for p in [0, 1, 2, 3]:
		if OsmFetcher.radius_for_preset(p) < WorldScale.DETAILED_EXTENT_M * 0.5:
			failures.append("preset %d detailed radius must cover the 1200 m half-extent" % p)
	var rings := [0, 1600, 1600, 2500]
	for p in [0, 1, 2, 3]:
		if OsmFetcher.ring_radius_for_preset(p) != rings[p]:
			failures.append("preset %d ring radius wrong" % p)
	# Detailed query: 15 tiered around-clauses (11 T2.3 + 4 T2.4
	# multipolygon-relation statements), per-layer caps, no v1 cap.
	var q := OsmFetcher.build_query(48.8566, 2.3522)
	for clause in ['way["building"]', 'way["building:part"]', 'way["highway"]',
			'way["waterway"]', 'way["natural"]', 'way["landuse"]', 'way["leisure"]',
			'relation["waterway"]["type"="multipolygon"]',
			'relation["natural"]["type"="multipolygon"]',
			'relation["landuse"]["type"="multipolygon"]',
			'relation["leisure"]["type"="multipolygon"]',
			'way["barrier"]', 'node["natural"="tree"]', "man_made"]:
		if not q.contains(clause):
			failures.append("query missing clause %s" % clause)
	if q.contains("out geom 900"):
		failures.append("query must not carry the v1 out-geom-900 cap")
	if not q.contains("out geom %d" % OsmFetcher.CAP_BUILDINGS) or not q.contains("[timeout:30]"):
		failures.append("query missing tiered caps / [timeout:30]")
	# Regression: 15 around clauses need 15 radius/lat/lon triplets. A
	# short % argument list leaves raw placeholders in the query and
	# Godot prints "not enough arguments for format string".
	if q.contains("%"):
		failures.append("query still has unformatted placeholders: %s" % q)
	if q.count("(around:%d,48.856600,2.352200)" % OsmFetcher.DETAILED_RADIUS_M) != 15:
		failures.append("expected 15 formatted around clauses, got %s" % q)
	# Explicit radius still threads through (compat for callers/tests).
	var q420 := OsmFetcher.build_query(48.8566, 2.3522, 420)
	if q420.count("420,48.856600,2.352200") != 15:
		failures.append("explicit radius must thread into all clauses")
	# Ring query: majors + waterways + coastline, 3 clauses.
	var qr := OsmFetcher.build_ring_query(48.8566, 2.3522, 1600)
	if not qr.contains("motorway|trunk|primary|secondary|tertiary") \
			or not qr.contains('way["waterway"]') \
			or not qr.contains('natural"="coastline'):
		failures.append("ring query missing majors/water/coastline: %s" % qr)
	if qr.contains("%") or qr.count("1600,48.856600,2.352200") != 3:
		failures.append("ring query clauses malformed: %s" % qr)
	# Width tables: spot-check ends and the default.
	if absf(OsmFetcher.road_class_width("motorway") - 15.0) > 0.01 \
			or absf(OsmFetcher.road_class_width("footway") - 2.0) > 0.01 \
			or absf(OsmFetcher.road_class_width("residential") - 6.0) > 0.01:
		failures.append("road_class_width table wrong")
	if absf(OsmFetcher.waterway_class_width("river") - 12.0) > 0.01 \
			or absf(OsmFetcher.waterway_class_width("coastline")) > 0.001 \
			or absf(OsmFetcher.waterway_class_width("stream") - 3.0) > 0.01:
		failures.append("waterway_class_width table wrong")

## A new fetch (or the pipeline's cancel) must abandon a request still
## in flight: HTTPRequest answers ERR_BUSY to a second one, which used to
## burn every retry on error 44 after a cancelled generation. The
## stand-in request targets loopback, so nothing leaves the machine.
## Runs after a frame so the fetcher's _ready has wired its HTTPRequest.
func _busy_checks(failures: Array[String]) -> void:
	var busy := OsmFetcher.new()
	root.add_child(busy)
	await process_frame
	busy.offline_mode = true
	if busy._http.request("http://127.0.0.1:9/") != OK:
		failures.append("test precondition: loopback request should start")
	busy.fetch(48.8566, 2.3522)
	if busy._http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		failures.append("fetch() must cancel the in-flight request")
	if busy._http.request("http://127.0.0.1:9/") != OK:
		failures.append("HTTPRequest should be idle (not ERR_BUSY) after fetch()")
	busy.cancel()
	if busy._http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		failures.append("cancel() must stop the in-flight request")
	busy.free()

func _chain_checks(failures: Array[String]) -> void:
	# Transient Overpass failures (client timeout, 502 from an
	# overloaded instance) must fall through to another endpoint;
	# a client error such as 400 must not.
	if OsmFetcher.ENDPOINTS.size() < 2:
		failures.append("expected fallback Overpass endpoints")
	# Distinct instances, not just a repeat of the first: when the
	# main instance answers 502 (overloaded) a same-instance retry
	# rarely rescues the fetch, so at least 3 distinct hosts are needed.
	var distinct: Dictionary = {}
	for ep in OsmFetcher.ENDPOINTS:
		distinct[ep] = true
	if distinct.size() < 3:
		failures.append("expected >=3 distinct Overpass endpoints, got %d" % distinct.size())
	# The pipeline's OSM wait must outlast both phases (detailed, then
	# the best-effort ring: one ATTEMPT_TIMEOUT per endpoint per phase),
	# or a late rescue is dropped. Bounded above too: slack beyond one
	# extra attempt per phase is dead wait.
	var n := float(OsmFetcher.ENDPOINTS.size())
	var t := OsmFetcher.ATTEMPT_TIMEOUT
	if OsmFetcher.retry_budget_seconds() < 2.0 * n * t:
		failures.append("retry budget %ss must cover 2 phases × %d attempts" % [OsmFetcher.retry_budget_seconds(), OsmFetcher.ENDPOINTS.size()])
	if OsmFetcher.retry_budget_seconds() >= 2.0 * (n + 1.0) * t:
		failures.append("retry budget %ss has more than one attempt of slack per phase" % OsmFetcher.retry_budget_seconds())
	# _ready must wire the same constant into the HTTP timeout.
	var fetcher := OsmFetcher.new()
	fetcher._ready()
	if fetcher._http == null or fetcher._http.timeout != OsmFetcher.ATTEMPT_TIMEOUT:
		failures.append("HTTP timeout should be ATTEMPT_TIMEOUT (%s), got %s" % [OsmFetcher.ATTEMPT_TIMEOUT, fetcher._http.timeout if fetcher._http != null else -1])
	fetcher.free()
	# Retry chain: a retryable failure (including a 200 with no
	# buildings from one instance) advances; the last attempt or a
	# non-retryable failure gives up.
	var last := OsmFetcher.ENDPOINTS.size() - 1
	if OsmFetcher.next_attempt(0, true) != 1:
		failures.append("retryable failure on attempt 0 should advance to 1")
	if OsmFetcher.next_attempt(last, true) != -1:
		failures.append("retryable failure on the last attempt should give up")
	if OsmFetcher.next_attempt(0, false) != -1:
		failures.append("non-retryable failure should give up immediately")
	if not OsmFetcher.is_retryable(HTTPRequest.RESULT_TIMEOUT, 0):
		failures.append("timeout (result=13 code=0) must be retryable")
	if not OsmFetcher.is_retryable(HTTPRequest.RESULT_SUCCESS, 502):
		failures.append("502 must be retryable")
	if not OsmFetcher.is_retryable(HTTPRequest.RESULT_SUCCESS, 429):
		failures.append("429 must be retryable")
	if OsmFetcher.is_retryable(HTTPRequest.RESULT_SUCCESS, 400):
		failures.append("400 must not be retryable")
	if OsmFetcher.is_retryable(HTTPRequest.RESULT_SUCCESS, 200):
		failures.append("200 must not be retryable")

## Overpass clips way geometry to the query area with null entries; one
## such way must not discard the whole response (lost Turku's OSM data:
## the payload parsed to nothing and every endpoint was retried).
func _null_node_checks(failures: Array[String]) -> void:
	var text := """{"elements":[
	{"type":"way","id":1,"tags":{"highway":"residential"},"geometry":[null,{"lat":60.4518,"lon":22.2666},{"lat":60.4520,"lon":22.2670},null]},
	{"type":"way","id":2,"tags":{"building":"yes"},"geometry":[{"lat":60.4518,"lon":22.2666},{"lat":60.4518,"lon":22.2668},{"lat":60.4519,"lon":22.2668},{"lat":60.4519,"lon":22.2666},{"lat":60.4518,"lon":22.2666}]}
	]}"""
	# Fail-closed: a script error inside the parser aborts this function
	# before it could append a failure, so the sentinel stays.
	var sentinel := "parsing a payload with null way nodes raised a script error"
	failures.append(sentinel)
	var got: Variant = OsmFetcher.parse_features(text, 60.4518, 22.2666)
	if not (got is Dictionary) or not (got as Dictionary).has("buildings"):
		return
	failures.erase(sentinel)
	var f: Dictionary = got
	if (f["buildings"] as Array).size() != 1:
		failures.append("a way with null (clipped) nodes must not drop the response's buildings: %d" % (f["buildings"] as Array).size())
	if (f["roads"] as Array).is_empty():
		failures.append("the clipped road itself should keep its in-area nodes")

## Mapped tree detail reaches vegetation: tree node genus/leaf tags, a
## natural=tree_row expanded into trees, forest leaf_type on the polygon.
func _tree_tag_checks(failures: Array[String]) -> void:
	var text := """{"elements":[
	{"type":"node","id":1,"lat":48.8566,"lon":2.3522,"tags":{"natural":"tree","genus":"Platanus","leaf_cycle":"deciduous"}},
	{"type":"way","id":2,"tags":{"natural":"tree_row","leaf_type":"broadleaved"},"geometry":[{"lat":48.8566,"lon":2.3522},{"lat":48.8566,"lon":2.3530}]},
	{"type":"way","id":3,"tags":{"landuse":"forest","leaf_type":"needleleaved"},"geometry":[{"lat":48.857,"lon":2.352},{"lat":48.857,"lon":2.353},{"lat":48.858,"lon":2.353},{"lat":48.857,"lon":2.352}]}
	]}"""
	var f := OsmFetcher.parse_features(text, 48.8566, 2.3522)
	var trees: Array = f["trees"]
	if trees.is_empty() or str(trees[0].get("genus", "")) != "platanus":
		failures.append("tree node genus should reach LocationData.trees: %s" % str(trees.slice(0, 1)))
	var row := 0
	for t in trees:
		if bool(t.get("row", false)):
			row += 1
			if str(t.get("leaf_type", "")) != "broadleaved":
				failures.append("tree_row trees should carry the row's leaf_type")
	# 0.0008° of longitude at 48.86° ≈ 58.6 m → a tree every 8 m: 8 trees.
	if row < 7 or row > 9:
		failures.append("a 58 m tree_row should place ~8 trees, got %d" % row)
	var forest := false
	for l in f["land"]:
		if str(l["class"]) == "forest" and str(l.get("leaf_type", "")) == "needleleaved":
			forest = true
	if not forest:
		failures.append("forest polygons should carry leaf_type")
	if TreeSpecies.species_from_tags({"genus": "platanus"}, "temperate") != "plane" \
			or TreeSpecies.species_from_tags({"species": "pinus pinea"}, "temperate") != "stone_pine" \
			or TreeSpecies.species_from_tags({"leaf_type": "needleleaved"}, "boreal") != "spruce" \
			or TreeSpecies.species_from_tags({"leaf_type": "broadleaved", "leaf_cycle": "evergreen"}, "dry_coast") != "olive" \
			or TreeSpecies.species_from_tags({}, "temperate") != "":
		failures.append("genus / species / leaf tags should name the modelled species")
	for e in TreeSpecies.mix_for_leaf("temperate", "forest", "needleleaved"):
		if str(e[0]) not in ["spruce", "scots_pine", "stone_pine", "cypress"]:
			failures.append("a needleleaved forest mix must hold conifers only, got %s" % e[0])
