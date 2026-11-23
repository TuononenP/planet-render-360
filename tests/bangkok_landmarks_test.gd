extends SceneTree

## Offline contract for Bangkok landmarks (`PLAN_Bangkok_super_realistic.md`, BK-0.3 & BK-1):
## - Primary at the capital coordinates (13.75398, 100.50144) stays `grand_palace_bangkok`.
## - Every Bangkok landmark is registered inside the Bangkok bounding box, resolves by alias,
##   and builds 2..16 textured PBR parts with 1,000..150,000 triangles (small gates/statues >= 300),
##   within max(2 m, 3%) of `height_m`, and nothing below -1.0 m without `base_drop_m`.
## - Slot selection from the City Hall eye pins the Fast (6) centre/skyline set (and Balanced/High/Ultra
##   as second-ring and outer landmarks land) while leaving 4 bridge slots on Balanced..Ultra.
## - Mapped OSM footprints inside a site's `clear_rect_m` / `model_rects_m` / `clear_path_m` are cleared
##   while a named neighbour outside (`Bangkok City Hall`) is kept.

const EYE_LAT := 13.75398
const EYE_LON := 100.50144

const EXISTING_TYPES := [
	["grand_palace_bangkok", "grand palace bangkok", 45.0, 1000],
	["wat_pho", "wat pho", 42.0, 1000],
	["wat_arun", "temple of dawn", 70.0, 1000],
	["hua_lamphong", "bangkok railway station", 26.2, 1000],
]

const BK2_TYPES := [
	["giant_swing", "sao chingcha", 21.15, 300],
	["wat_suthat", "wat suthat", 34.0, 1000],
	["democracy_monument", "democracy monument bangkok", 24.0, 1000],
	["loha_prasat", "wat ratchanatdaram", 36.0, 1000],
	["golden_mount", "phu khao thong", 77.0, 1000],
	["mahakan_fort", "mahakan fort", 19.0, 1000],
]

const FAST_EXPECTED := [
	"golden_mount", "wat_arun", "giant_swing",
	"democracy_monument", "loha_prasat", "wat_suthat",
]

const BALANCED_EXPECTED := [
	"golden_mount", "wat_arun", "giant_swing",
	"democracy_monument", "loha_prasat", "wat_suthat",
	"mahakan_fort", "wat_ratchabophit", "wat_bowonniwet",
	"ministry_of_defence_bangkok", "bangkok_city_pillar", "wat_pho",
]

const HIGH_EXPECTED := [
	"golden_mount", "wat_arun", "giant_swing",
	"democracy_monument", "loha_prasat", "wat_suthat",
	"mahakan_fort", "wat_ratchabophit", "wat_bowonniwet",
	"ministry_of_defence_bangkok", "bangkok_city_pillar", "wat_pho",
	"wat_ratchapradit", "national_museum_bangkok", "phra_sumen_fort",
	"thammasat_dome", "santa_cruz_church", "wat_kalayanamit",
]

const ULTRA_EXPECTED := [
	"golden_mount", "wat_arun", "giant_swing",
	"democracy_monument", "loha_prasat", "wat_suthat",
	"mahakan_fort", "wat_ratchabophit", "wat_bowonniwet",
	"ministry_of_defence_bangkok", "bangkok_city_pillar", "wat_pho",
	"wat_ratchapradit", "national_museum_bangkok", "phra_sumen_fort",
	"thammasat_dome", "santa_cruz_church", "wat_kalayanamit",
	"wat_benchamabophit", "wat_prayun", "chinatown_gate_wat_traimit",
	"ananta_samakhom",
]

var failures: Array[String] = []

func _init() -> void:
	_check_primary_and_slots()
	for row in EXISTING_TYPES + BK2_TYPES:
		_check_model(str(row[0]), str(row[1]), float(row[2]), int(row[3]))
	for entry in LandmarkRegistryThailandBangkok.entries():
		var t := str((entry as Dictionary)["type"])
		var already := false
		for row in BK2_TYPES:
			if str(row[0]) == t:
				already = true
				break
		if not already:
			var aliases: Array = (entry as Dictionary).get("aliases", [])
			var min_t := 40 if bool((entry as Dictionary).get("skyline", false)) else 400
			_check_model(t, str(aliases[0]) if not aliases.is_empty() else t, float((entry as Dictionary)["height_m"]), min_t)
	_check_clearance()
	if failures.is_empty():
		print("BANGKOK LANDMARKS OK: %d batch + 4 existing models" % LandmarkRegistryThailandBangkok.entries().size())
		quit(0)
	else:
		for f in failures:
			printerr("BANGKOK LANDMARKS FAIL: ", f)
		quit(1)

func _check_primary_and_slots() -> void:
	var primary := LocationData.landmark_for(EYE_LAT, EYE_LON, "")
	if primary != "grand_palace_bangkok":
		failures.append("Bangkok primary should stay grand_palace_bangkok, got %s" % primary)
	var gp := LocationData.entry_for_type("grand_palace_bangkok")
	if gp.has("ultra_registry_limit"):
		failures.append("grand_palace_bangkok should keep ultra_registry_limit unset so 4 bridge slots remain")

	# Fast preset (0) must select the exact 6 icons of the BK-0.3 budget table
	var data := LocationData.new()
	data.latitude = EYE_LAT
	data.longitude = EYE_LON
	data.landmark_type = primary
	data.quality_preset = 0
	var fast_sel := LandmarkSites.select(data, [])
	var fast_icons: Array[String] = []
	for c in fast_sel:
		var cd := c as Dictionary
		var t := str(cd["type"])
		if str(cd.get("archetype", "")) != "Bridge" and not bool(LocationData.entry_for_type(t).get("skyline", false)):
			fast_icons.append(t)
	if fast_icons != FAST_EXPECTED:
		failures.append("Fast (6) icons expected %s, got %s" % [FAST_EXPECTED, fast_icons])

	# Balanced (1), High (2) & Ultra (3) presets must match the BK-0.3 12/18/22-icon sets
	for check in [[1, BALANCED_EXPECTED, "Balanced (12)"], [2, HIGH_EXPECTED, "High (18)"], [3, ULTRA_EXPECTED, "Ultra (22)"]]:
		data.quality_preset = int(check[0])
		var sel := LandmarkSites.select(data, [])
		var got_icons: Array[String] = []
		var got_skyline := 0
		for c in sel:
			var cd := c as Dictionary
			var t := str(cd["type"])
			if bool(LocationData.entry_for_type(t).get("skyline", false)):
				got_skyline += 1
			elif str(cd.get("archetype", "")) != "Bridge":
				got_icons.append(t)
		if got_icons != (check[1] as Array):
			failures.append("%s icons expected %s, got %s" % [str(check[2]), check[1], got_icons])
		if got_skyline < 9:
			failures.append("%s should select all 9 Bangkok skyline towers, got %d" % [str(check[2]), got_skyline])

	# Ultra preset (3) must select the exact 4 Chao Phraya bridges in nearest-first order (`BK-0.3` & `BK-6`)
	data.quality_preset = 3
	var ultra_sel := LandmarkSites.select(data, [])
	var bridges: Array[String] = []
	for c in ultra_sel:
		var cd := c as Dictionary
		if str(cd.get("archetype", "")) == "Bridge":
			bridges.append(str(cd["type"]))
	var expected_bridges: Array[String] = [
		"br_bangkok_pinklao_bridge",
		"br_bangkok_memorial_bridge",
		"br_bangkok_pok_klao_bridge",
		"br_bangkok_rama_viii_bridge",
	]
	var sorted_got := bridges.duplicate()
	sorted_got.sort()
	var sorted_exp := expected_bridges.duplicate()
	sorted_exp.sort()
	if sorted_got != sorted_exp:
		failures.append("Ultra 4 bridge slots expected %s, got %s" % [expected_bridges, bridges])
	if bridges.size() >= 4 and bridges[3] != "br_bangkok_rama_viii_bridge":
		failures.append("Rama VIII Bridge should be the 4th river bridge slot, got %s" % [bridges])

func _check_model(type: String, alias: String, height_m: float, min_tris: int) -> void:
	var entry := LocationData.entry_for_type(type)
	if entry.is_empty():
		failures.append("%s missing from LocationData.landmarks()" % type)
		return
	var lat := float(entry.get("lat", 0.0))
	var lon := float(entry.get("lon", 0.0))
	if lat < 13.60 or lat > 13.90 or lon < 100.40 or lon > 100.65:
		failures.append("%s (%f, %f) outside Bangkok box" % [type, lat, lon])
	if LocationData.landmark_for(lat, lon, alias) != type:
		failures.append("%s alias '%s' did not resolve" % [type, alias])
	if not is_equal_approx(float(entry.get("height_m", 0.0)), height_m):
		failures.append("%s registry height_m expected %.2f, got %.2f" % [type, height_m, float(entry.get("height_m", 0.0))])
	if not LandmarkBuilder.is_bespoke(type):
		failures.append("%s has no bespoke builder" % type)
		return
	var root := LandmarkBuilder.build(type)
	var parts := LandmarkBuilder.parts(root)
	if parts.size() < 2 or parts.size() > 16:
		failures.append("%s should have 2..16 parts, got %d" % [type, parts.size()])
	var top := 0.0
	var low := INF
	var tris := 0
	for p in parts:
		var mat := p.mesh.surface_get_material(0) as StandardMaterial3D
		if mat == null or mat.albedo_texture == null:
			failures.append("%s part %s lacks textured StandardMaterial3D" % [type, p.name])
		var aabb := p.transform * p.mesh.get_aabb()
		top = maxf(top, aabb.end.y)
		low = minf(low, aabb.position.y)
		tris += p.mesh.surface_get_array_len(0) / 3
	if tris < min_tris or tris > 150000:
		failures.append("%s triangle count %d outside [%d, 150000]" % [type, tris, min_tris])
	if absf(top - height_m) > maxf(2.0, height_m * 0.03):
		failures.append("%s top %.2f m outside tolerance of %.2f m" % [type, top, height_m])
	if not entry.has("base_drop_m") and low < -1.0:
		failures.append("%s extends %.2f m below ground without base_drop_m" % [type, low])
	root.free()

func _check_clearance() -> void:
	var data := LocationData.new()
	data.latitude = EYE_LAT
	data.longitude = EYE_LON
	data.landmark_type = "grand_palace_bangkok"
	data.has_landmark_site = true
	var gp := LocationData.entry_for_type("grand_palace_bangkok")
	data.landmark_lat = float(gp["lat"])
	data.landmark_lon = float(gp["lon"])
	data.quality_preset = 3
	data.landmark_candidates = LandmarkSites.select(data, [])
	var rects := LandmarkSites.model_rect_sites(data)

	# Loha Prasat footprint (13.754813, 100.504163) must fall inside model_rects_m,
	# while Bangkok City Hall (13.753684, 100.501717) must stay outside every clear/model rect!
	var loha_xz := WorldScale.xz_from_latlon(13.754813, 100.504163, EYE_LAT, EYE_LON)
	var hall_xz := WorldScale.xz_from_latlon(13.753684, 100.501717, EYE_LAT, EYE_LON)
	if not LandmarkSites.in_model_rects(loha_xz, rects):
		failures.append("Loha Prasat OSM footprint should be covered by model_rects_m")
	if LandmarkSites.in_model_rects(hall_xz, rects):
		failures.append("Bangkok City Hall neighbour should NOT be inside any landmark model_rect")
	var audit_xz := WorldScale.xz_from_latlon(13.75654, 100.49197, EYE_LAT, EYE_LON)
	if LandmarkSites.in_model_rects(audit_xz, rects):
		failures.append("Thammasat Auditorium neighbour (w83608615) should NOT be inside thammasat_dome model_rect")
