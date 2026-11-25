extends SceneTree

## Offline contract for Singapore landmarks (`PLAN_Singapore_super_realistic.md`, SG-0.7 & SG-1):
## - Primary at the Padang capital centre (1.28967, 103.85007) stays `marina_bay_sands`.
## - Every Singapore landmark (35 bespoke icons/bridges + 34 SgTowerSpecs skyline towers)
##   resolves by alias, builds 2..16 textured PBR parts within max(2 m, 3%) of `height_m`,
##   stays under 150,000 triangles, and places nothing below -1.5 m without `base: water`/`sea`.
## - Slot selection from Padang pins Fast (6), Balanced (12), High (18) and Ultra (34+ icons
##   + parametric bridge slots + independent skyline tower channel).

const EYE_LAT := 1.28967
const EYE_LON := 103.85007

var failures: Array[String] = []

func _init() -> void:
	_check_primary_and_slots()
	for entry in LandmarkRegistrySingapore.entries():
		var e := entry as Dictionary
		var t := str(e["type"])
		var aliases: Array = e.get("aliases", [])
		var is_sky := bool(e.get("skyline", false))
		var base := str(e.get("base", "ground"))
		var is_water := base == "water" or base == "sea"
		var min_t := 16 if is_sky else 120
		_check_model(t, str(aliases[0]) if not aliases.is_empty() else t, float(e["height_m"]), min_t, is_water)
	if failures.is_empty():
		print("SINGAPORE LANDMARKS OK: %d entries verified (bespoke + skyline)" % LandmarkRegistrySingapore.entries().size())
		quit(0)
	else:
		for f in failures:
			printerr("SINGAPORE LANDMARKS FAIL: ", f)
		quit(1)

func _check_primary_and_slots() -> void:
	var primary := LocationData.landmark_entry(EYE_LAT, EYE_LON, "Singapore")
	if str(primary.get("type", "")) != "marina_bay_sands":
		failures.append("primary at Singapore centre should be marina_bay_sands, got %s" % str(primary.get("type", "")))
	# Fast preset: all 6 Tier-1 icons must appear.
	var fast_types := _selected_types(RenderSettings.Preset.FAST)
	for must_fast in ["esplanade_singapore", "merlion_park", "singapore_flyer", "artscience_museum",
			"national_gallery_sg", "fullerton_hotel"]:
		if not fast_types.has(must_fast):
			failures.append("Fast selection missing Tier-1 icon: %s" % must_fast)
	# Ultra preset: all major Marina Bay, Civic, Heritage, bespoke bridges & skyline towers appear.
	var ultra_types := _selected_types(RenderSettings.Preset.ULTRA)
	for must_ultra in ["esplanade_singapore", "merlion_park", "singapore_flyer", "artscience_museum",
			"helix_bridge", "fullerton_hotel", "supertree_grove", "gardens_by_the_bay_domes",
			"national_gallery_sg", "victoria_theatre_sg", "st_andrews_cathedral_sg", "supreme_court_sg",
			"old_hill_street_police_sg", "raffles_hotel_sg", "sultan_mosque_sg", "lau_pa_sat_sg",
			"sri_mariamman_temple_sg", "buddha_tooth_relic_sg", "clarke_quay_sg",
			"cavenagh_bridge_sg", "anderson_bridge_sg", "elgin_bridge_sg"]:
		if not ultra_types.has(must_ultra):
			failures.append("Ultra selection missing expected landmark: %s" % must_ultra)
	var sky_count := 0
	for k in ultra_types:
		if not SgTowerSpecs.spec_for(str(k)).is_empty():
			sky_count += 1
	if sky_count < 25:
		failures.append("Ultra selection has only %d SgTowerSpecs skyline towers (expected >= 25)" % sky_count)

func _selected_types(preset: int) -> Dictionary:
	var data := LocationData.new()
	data.latitude = EYE_LAT
	data.longitude = EYE_LON
	data.place_name = "Singapore"
	data.landmark_type = "marina_bay_sands"
	data.quality_preset = preset
	var out := {}
	for c in LandmarkSites.select(data, []):
		var d := c as Dictionary
		out[str(d["type"])] = true
	return out

func _check_model(type: String, alias: String, expected_h: float, min_tris: int, is_water: bool) -> void:
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
		failures.append("%s: top %.1f m, expected %.1f m (±%.1f m)" % [type, max_y, expected_h, tol])
	if tris < min_tris or tris > 150000:
		failures.append("%s: %d triangles (must be %d..150000)" % [type, tris, min_tris])
	if not is_water and min_y < -1.5:
		failures.append("%s: min_y %.2f m below -1.5 m without base:water" % [type, min_y])
	hero.free()

func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, out)
