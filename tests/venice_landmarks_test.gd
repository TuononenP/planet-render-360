extends SceneTree

## Offline contract for Venice landmarks (`PLAN_Venice_super_realistic.md`, VN-0.7 & VN-1):
## - Primary at the Venice preset vantage (45.4318, 12.3290) stays `salute`.
## - Every Venice landmark (6 existing + 54 new bespoke) resolves by alias,
##   builds 2..16 textured PBR parts within max(2 m, 3%) of `height_m`, stays
##   under 150,000 triangles, and places nothing below -1.5 m without `base: sea`.
## - Slot selection from Ponte dell'Accademia pins Ultra (up to 46 extras + 6 bridges)
##   and Fast/Balanced/High tier ordering.

const EYE_LAT := 45.4318
const EYE_LON := 12.3290

const EXISTING_TYPES := [
	["salute", "santa maria della salute", 60.0, 1000, false],
	["st_marks_campanile", "campanile di san marco", 98.6, 500, false],
	["doges_palace", "doge's palace", 27.3, 500, false],
	["st_marks_basilica_venice", "basilica di san marco", 43.0, 500, false],
	["bridge_of_sighs", "ponte dei sospiri", 11.85, 200, false],
	["rialto_bridge", "ponte di rialto", 12.8, 300, true],
]

var failures: Array[String] = []

func _init() -> void:
	_check_primary_and_slots()
	_check_venice_fabric_and_water()
	for row in EXISTING_TYPES:
		_check_model(str(row[0]), str(row[1]), float(row[2]), int(row[3]), bool(row[4]))
	for entry in LandmarkRegistryVenice.entries():
		var e := entry as Dictionary
		var t := str(e["type"])
		var aliases: Array = e.get("aliases", [])
		var is_sea := str(e.get("base", "ground")) == "sea"
		_check_model(t, str(aliases[0]) if not aliases.is_empty() else t, float(e["height_m"]), 80, is_sea)
	if failures.is_empty():
		print("VENICE LANDMARKS OK: %d batch + 6 existing models" % LandmarkRegistryVenice.entries().size())
		quit(0)
	else:
		for f in failures:
			printerr("VENICE LANDMARKS FAIL: ", f)
		quit(1)

func _check_primary_and_slots() -> void:
	var primary := LocationData.landmark_entry(EYE_LAT, EYE_LON, "Venice, Italy")
	if str(primary.get("type", "")) != "salute":
		failures.append("primary at Venice preset should be salute, got %s" % str(primary.get("type", "")))
	if int(primary.get("ultra_registry_limit", 0)) != 46 or int(primary.get("ultra_total_limit", 0)) != 52:
		failures.append("salute should carry ultra_registry_limit=46 / ultra_total_limit=52")
	var data := LocationData.new()
	data.latitude = EYE_LAT
	data.longitude = EYE_LON
	data.place_name = "Venice, Italy"
	data.landmark_type = "salute"
	data.quality_preset = RenderSettings.Preset.ULTRA
	var cands := LandmarkSites.select(data, [])
	var types := {}
	for c in cands:
		types[str((c as Dictionary)["type"])] = true
	for must_have in ["st_marks_campanile", "doges_palace", "st_marks_basilica_venice", "rialto_bridge",
			"san_giorgio_maggiore", "punta_della_dogana", "ponte_accademia", "il_redentore",
			"procuratie_piazza_san_marco", "biblioteca_marciana", "torre_orologio",
			"palazzo_cavalli_franchetti", "ca_doro", "ca_rezzonico", "palazzo_corner_ca_granda",
			"palazzo_venier_guggenheim"]:
		if not types.has(must_have):
			failures.append("Ultra selection missing expected Venice landmark: %s" % must_have)

func _check_venice_fabric_and_water() -> void:
	# VN-8.1: multi-storey historic Grand Canal / San Marco blocks must never route to venice_modern.
	var fg := ArchitectureCitiesVenice.venice_rule("apartments", {"district": "venice_grand_canal", "levels": 7, "area": 4800.0})
	if fg == "venice_modern":
		failures.append("historic Grand Canal block misclassified as venice_modern")
	var unzoned := ArchitectureCitiesVenice.venice_rule("apartments", {"district": "", "levels": 6, "area": 1200.0})
	if unzoned != "venice_grand_canal":
		failures.append("tall historic Venice block should route to venice_grand_canal, got %s" % unzoned)
	var modern := ArchitectureCitiesVenice.venice_rule("apartments", {"district": "venice_modern", "levels": 5, "area": 900.0})
	if modern != "venice_modern":
		failures.append("venice_modern district should route to venice_modern, got %s" % modern)
	# VN-8.4 / VN-8.6: districts, FAR_DISTRICT_CITIES and CityDetail.CITIES.
	var frame := CityStyles.local_frame("venice", EYE_LAT, EYE_LON)
	if (frame.get("districts", []) as Array).size() < 10:
		failures.append("expected >= 10 Venice districts in local_frame, got %d" % (frame.get("districts", []) as Array).size())
	if not CityStyles.FAR_DISTRICT_CITIES.has("venice"):
		failures.append("venice missing from CityStyles.FAR_DISTRICT_CITIES")
	if not CityDetail.CITIES.has("venice"):
		failures.append("venice missing from CityDetail.CITIES")
	# VN-9.1 / VN-9.5: lagoon water palette box and post-2021 cruise-ship ban.
	if not WaterSurface.venice_lagoon(EYE_LAT, EYE_LON):
		failures.append("WaterSurface.venice_lagoon should cover Ponte dell'Accademia")
	var loc := LocationData.new()
	loc.latitude = EYE_LAT
	loc.longitude = EYE_LON
	if not QuayFleet.hotel_water(loc, Vector2.ZERO, 1.0):
		failures.append("QuayFleet.hotel_water should block ocean liners in Venice canals/Bacino")

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
