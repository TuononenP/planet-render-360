extends SceneTree

var failures: Array[String] = []
const FIXTURE := "res://tests/fixtures/helsinki_mint.json"

func _init() -> void:
	var raw := FileAccess.get_file_as_string(FIXTURE)
	var parsed := OsmParser.parse_features(raw, 60.168, 24.953)
	var mint := _mint(parsed)
	_check(mint.get("height_source") == "reference" and is_equal_approx(float(mint["height"]), 11.5),
		"Missing Mint height must use the documented reference estimate")
	_check(mint.get("levels") == 2.0 and mint.get("roof_shape") == "gabled",
		"Reference elevations must supply two storeys and the pitched roof")
	_check(mint.get("roof_material") == "metal" and mint.get("roof_colour") == "#484c48",
		"Reference roof must use a dark grey metal finish")
	_check(mint.get("colour") == "#ff9e6b" and mint.get("material") == "plaster",
		"Reference facts must preserve mapped paint and wall material")
	var provenance: Dictionary = mint.get("reference", {})
	_check(provenance.get("height_method") == "scaled_elevation" and provenance.get("height_uncertainty_m") == 1.0
		and str(provenance.get("source", "")).begins_with("https://www.senaatti.fi/"),
		"Drawing estimates must retain method, uncertainty and primary source")
	var original: Dictionary = JSON.parse_string(raw)
	var original_mint: Dictionary = (original["elements"] as Array).filter(func(e: Dictionary) -> bool: return int(e["id"]) == 23192814)[0]
	var plain := OsmTags._building_entry(original_mint["tags"], mint["footprint"],
		OsmGeometry._ring_aabb(mint["footprint"]))
	_check(mint["footprint"] == plain["footprint"] and mint["x"] == plain["x"] and mint["z"] == plain["z"],
		"Reference enrichment must retain the map envelope and position")
	var data := LocationData.new()
	data.latitude = 60.168
	data.longitude = 24.953
	data.country = "FI"
	data.buildings = parsed["buildings"]
	data.landmark_candidates = LandmarkSites.select(data, [])
	for preset in [RenderSettings.Preset.FAST, RenderSettings.Preset.ULTRA]:
		data.quality_preset = preset
		BuildingMasses.begin_build()
		var ctx := BuildingHeights._height_context(data)
		var masses := BuildingMasses.plan(mint, ctx)
		_check(masses.size() == 1 and int(masses[0]["storeys"]) == 2
			and absf(float(masses[0]["wall_m"]) + float(masses[0]["rh_m"]) - 11.5) < 0.001,
			"Every tier must render the reference total with two facade rows")
		_check(float(masses[0]["rh_m"]) == 2.5 and str(masses[0]["shape"]) == "gabled",
			"The total must include the reference roof rise")
		BuildingMasses.end_build()
	_check(BuildingBuilder._accepted(data, mint, Vector2.ZERO, 1176.0), "Mint must remain a real mapped building")
	var office: Dictionary = (data.buildings as Array).filter(func(b: Dictionary) -> bool: return b.get("osm_id") == "way:23192809")[0]
	# Retained as a mapped building, or drawn by its own landmark
	# (enso_gutzeit_hq), which takes the building's place.
	var drawn := BuildingBuilder._accepted(data, office, Vector2.ZERO, 1176.0) \
		or BuildingBuilder._near_landmark_candidate(data, float(office["x"]), float(office["z"]))
	_check(office.get("height_source") == "levels" and not office.has("reference") and drawn,
		"Adjacent Enso office must remain unchanged and retained")
	var marble_set := FacadeMaterials._wall_set(office, {}, "helsinki")
	var marble_tint := FacadeMaterials._wall_tint(office, {}, marble_set, 0.0)
	var mean: Color = MaterialLibrary.PBR_SETS[marble_set]["mean"]
	var result := Color(mean.r * marble_tint.r, mean.g * marble_tint.g, mean.b * marble_tint.b)
	_check(marble_set == "limestone" and result.r > 0.6 and absf(result.r-result.b) < 0.03,
		"Mapped white marble must render as pale neutral stone, not yellow sandstone")
	var cream := office.duplicate()
	cream["colour"] = "#ded0c0"
	var office_look := BuildingHeights._look_for(office, BuildingHeights._height_context(data))
	FacadeMaterials.begin_build()
	var cream_mat := FacadeMaterials.facade_for_building(cream, "helsinki", 6, 3, false, 0.0, office_look)
	var white_mat := FacadeMaterials.facade_for_building(office, "helsinki", 6, 3, false, 0.0, office_look)
	_check(cream_mat != white_mat, "Pale mapped marble colours must not collide in the material cache")
	var explicit := original.duplicate(true)
	for element in explicit["elements"]:
		if int(element["id"]) == 23192814:
			element["tags"].merge({"height":"18", "building:levels":"3", "start_date":"2000",
				"roof:shape":"flat", "roof:height":"1", "roof:material":"copper", "roof:colour":"green"}, true)
	var tagged := _mint(OsmParser.parse_features(JSON.stringify(explicit), 60.168, 24.953))
	_check(tagged.get("height_source") == "tag_height" and tagged.get("height") == 18.0
		and tagged.get("levels") == 3.0 and tagged.get("start_year") == 2000 and not tagged.has("reference")
		and tagged.get("roof_shape") == "flat" and tagged.get("roof_material") == "copper", "Explicit map facts must win")
	var levels_only := original.duplicate(true)
	for element in levels_only["elements"]:
		if int(element["id"]) == 23192814:element["tags"]["building:levels"] = "4"
	var levels := _mint(OsmParser.parse_features(JSON.stringify(levels_only), 60.168, 24.953))
	_check(levels.get("height_source") == "levels" and levels.get("levels") == 4.0,
		"Mapped storeys must win over the reference total and storeys")
	var part_model := plain.duplicate(true)
	part_model["osm_id"] = "way:23192814"
	part_model["parts"] = [{"height":18.0,"height_source":"tag_height"}]
	var unrelated := plain.duplicate(true)
	unrelated["osm_id"] = "way:999999"
	BuildingReferences.apply([part_model, unrelated])
	_check(not part_model.has("reference") and not unrelated.has("reference"),
		"Mapped parts and buildings sharing only a name must not receive overrides")
	var again := mint.duplicate(true)
	BuildingReferences.apply([again])
	_check(again == mint, "Enrichment must be idempotent")
	if failures.is_empty():
		print("BUILDING REFERENCES OK: identity, provenance, footprint, height/roof/storeys, tag/part priority and tiers")
		quit(0)
	else:
		for failure in failures:printerr("BUILDING REFERENCES FAIL: ", failure)
		quit(1)

func _mint(parsed: Dictionary) -> Dictionary:
	return (parsed["buildings"] as Array).filter(func(b: Dictionary) -> bool: return b.get("osm_id") == "way:23192814")[0]

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):failures.append(message)
