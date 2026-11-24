extends SceneTree

## Offline contract for Paris landmarks (`PLAN_Paris_super_realistic.md`, PA-0.7 & PA-1):
## - Primary at the Paris preset vantage (48.8622, 2.2887, Trocadéro) stays `eiffel`.
## - Every Paris landmark (10 existing + 35 new bespoke & bridges + 37 PaTowerSpecs skyline towers)
##   resolves by alias, builds 2..16 textured PBR parts within max(2 m, 3%) of `height_m`,
##   stays under 150,000 triangles, and places nothing below -1.5 m without `base: sea`.
## - Slot selection from Trocadéro pins Ultra (46 extras + 8 bridges + independent skyline channel)
##   and verifies key skyline icons (Notre-Dame, Sacré-Cœur, Louvre, Grand Palais, Invalides,
##   Arc de Triomphe, Grande Arche, Pont de Bir-Hakeim, Pont Alexandre III, Tour Montparnasse).

const EYE_LAT := 48.8622
const EYE_LON := 2.2887

const EXISTING_TYPES := [
	["eiffel", "tour eiffel", 330.0, 1000],
	["arc_de_triomphe", "arc de triomphe", 50.0, 1000],
	["les_invalides", "les invalides", 107.0, 1000],
	["louvre_pyramid", "louvre pyramid", 21.6, 500],
	["notre_dame", "notre-dame de paris", 96.0, 1000],
	["sacre_coeur", "sacre-coeur", 83.0, 1000],
	["pantheon_paris", "pantheon, paris", 83.0, 1000],
	["sainte_chapelle", "sainte-chapelle", 75.5, 1000],
	["palais_garnier", "palais garnier", 56.0, 1000],
	["gare_du_nord", "gare du nord", 39.4, 500],
]

var failures: Array[String] = []

func _init() -> void:
	_check_primary_and_slots()
	for row in EXISTING_TYPES:
		_check_model(str(row[0]), str(row[1]), float(row[2]), int(row[3]), false)
	for entry in LandmarkRegistryParis.entries():
		var e := entry as Dictionary
		var t := str(e["type"])
		var aliases: Array = e.get("aliases", [])
		var is_sky := bool(e.get("skyline", false))
		var is_sea := str(e.get("base", "ground")) == "sea"
		var min_t := 20 if is_sky else 200
		_check_model(t, str(aliases[0]) if not aliases.is_empty() else t, float(e["height_m"]), min_t, is_sea)
	if failures.is_empty():
		print("PARIS LANDMARKS OK: %d batch + 10 existing models" % LandmarkRegistryParis.entries().size())
		quit(0)
	else:
		for f in failures:
			printerr("PARIS LANDMARKS FAIL: ", f)
		quit(1)

func _check_primary_and_slots() -> void:
	var primary := LocationData.landmark_entry(EYE_LAT, EYE_LON, "Paris, France")
	if str(primary.get("type", "")) != "eiffel":
		failures.append("primary at Paris preset should be eiffel, got %s" % str(primary.get("type", "")))
	var data := LocationData.new()
	data.latitude = EYE_LAT
	data.longitude = EYE_LON
	data.place_name = "Paris, France"
	data.landmark_type = "eiffel"
	data.quality_preset = RenderSettings.Preset.ULTRA
	var cands := LandmarkSites.select(data, [])
	var types := {}
	var sky_count := 0
	for c in cands:
		var d := c as Dictionary
		types[str(d["type"])] = true
		if PaTowerSpecs.spec_for(str(d["type"])).size() > 0:
			sky_count += 1
	for must_have in ["palais_de_chaillot", "arc_de_triomphe", "les_invalides", "ecole_militaire",
			"pont_de_bir_hakeim", "pont_alexandre_iii", "pont_d_iena", "grand_palais",
			"louvre_pyramid", "palais_du_louvre", "notre_dame", "sacre_coeur", "grande_arche",
			"tour_montparnasse", "tour_first", "coeur_defense"]:
		if not types.has(must_have):
			failures.append("Ultra selection missing expected landmark: %s" % must_have)
	if sky_count < 25:
		failures.append("Ultra selection has only %d PaTowerSpecs skyline towers (expected >= 25)" % sky_count)

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
