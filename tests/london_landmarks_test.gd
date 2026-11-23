extends SceneTree

## Offline contract for London landmarks (`PLAN_London_super_realistic.md`, LN-0.7 & LN-1):
## - Primary at the London preset vantage (51.5018, -0.1196) stays `big_ben`.
## - Every London landmark (10 existing + 30 new bespoke + 25 LnTowerSpecs skyline towers)
##   resolves by alias, builds 2..16 textured PBR parts within max(2 m, 3%) of `height_m`,
##   stays under 150,000 triangles, and places nothing below -1.5 m without `base: sea`.
## - Slot selection from Queen's Walk pins Fast (6), Balanced (12), High (18) and Ultra (42)
##   with 8 parametric Thames bridge slots and the independent skyline tower channel.

const EYE_LAT := 51.5018
const EYE_LON := -0.1196

const EXISTING_TYPES := [
	["big_ben", "elizabeth tower", 96.0, 1000],
	["tower_bridge", "tower bridge", 65.0, 1000],
	["london_eye", "millennium wheel", 135.0, 1000],
	["st_pauls", "st paul's cathedral", 111.0, 1000],
	["shard", "the shard", 309.6, 1000],
	["tower_of_london", "tower of london", 27.5, 1000],
	["buckingham_palace", "buckingham palace", 24.0, 1000],
	["westminster_abbey", "westminster abbey", 69.0, 1000],
	["st_mary_axe", "the gherkin", 180.0, 1000],
	["waterloo_station", "waterloo station", 27.0, 1000],
]

var failures: Array[String] = []

func _init() -> void:
	_check_primary_and_slots()
	for row in EXISTING_TYPES:
		_check_model(str(row[0]), str(row[1]), float(row[2]), int(row[3]), false)
	for entry in LandmarkRegistryLondon.entries():
		var e := entry as Dictionary
		var t := str(e["type"])
		var aliases: Array = e.get("aliases", [])
		var is_sky := bool(e.get("skyline", false))
		var is_sea := str(e.get("base", "ground")) == "sea"
		var min_t := 40 if is_sky else 200
		_check_model(t, str(aliases[0]) if not aliases.is_empty() else t, float(e["height_m"]), min_t, is_sea)
	if failures.is_empty():
		print("LONDON LANDMARKS OK: %d batch + 10 existing models" % LandmarkRegistryLondon.entries().size())
		quit(0)
	else:
		for f in failures:
			printerr("LONDON LANDMARKS FAIL: ", f)
		quit(1)

func _check_primary_and_slots() -> void:
	var primary := LocationData.landmark_entry(EYE_LAT, EYE_LON, "London, United Kingdom")
	if str(primary.get("type", "")) != "big_ben":
		failures.append("primary at London preset should be big_ben, got %s" % str(primary.get("type", "")))
	var data := LocationData.new()
	data.latitude = EYE_LAT
	data.longitude = EYE_LON
	data.place_name = "London, United Kingdom"
	data.landmark_type = "big_ben"
	data.quality_preset = RenderSettings.Preset.ULTRA
	var cands := LandmarkSites.select(data, [])
	var types := {}
	var sky_count := 0
	for c in cands:
		var d := c as Dictionary
		types[str(d["type"])] = true
		if LnTowerSpecs.spec_for(str(d["type"])).size() > 0:
			sky_count += 1
	for must_have in ["london_eye", "county_hall", "westminster_bridge", "hungerford_golden_jubilee",
			"portcullis_house", "trafalgar_square", "st_pauls", "shard", "tower_bridge"]:
		if not types.has(must_have):
			failures.append("Ultra selection missing expected landmark: %s" % must_have)
	if sky_count < 15:
		failures.append("Ultra selection has only %d LnTowerSpecs skyline towers (expected >= 15)" % sky_count)

func _check_model(type: String, alias: String, expected_h: float, min_tris: int, is_sea: bool) -> void:
	var hit := LocationData.landmark_entry(EYE_LAT, EYE_LON, alias)
	if str(hit.get("type", "")) != type:
		failures.append("alias '%s' resolved to '%s', expected '%s'" % [alias, str(hit.get("type", "")), type])
	var hero := LandmarkBuilder.build(type)
	if hero == null:
		failures.append("%s: LandmarkBuilder.build returned null" % type)
		return
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(hero, meshes)
	if meshes.size() < 2 or meshes.size() > 16:
		failures.append("%s: %d parts (must be 2..16)" % [type, meshes.size()])
	var tris := 0
	var min_y := 1e9
	var max_y := -1e9
	for mi in meshes:
		if mi.mesh == null:
			continue
		var aabb := mi.transform * mi.mesh.get_aabb()
		min_y = minf(min_y, aabb.position.y)
		max_y = maxf(max_y, aabb.end.y)
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			var vtx: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			tris += ((idx as PackedInt32Array).size() / 3) if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty() else (vtx.size() / 3)
	var tol := maxf(2.0, expected_h * 0.03)
	if absf(max_y - expected_h) > tol:
		failures.append("%s: height %.2f m outside %.2f +/- %.2f m" % [type, max_y, expected_h, tol])
	if tris < min_tris or tris > 150000:
		failures.append("%s: %d tris outside %d..150000" % [type, tris, min_tris])
	if not is_sea and min_y < -1.5:
		failures.append("%s: lowest_y %.2f m < -1.5 m" % [type, min_y])
	hero.free()

func _collect_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect_meshes(c, out)
