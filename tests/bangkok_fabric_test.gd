extends SceneTree

## Bangkok old-town fabric, height caps, Thai temple halls & mapped chedis (BK-3):
##   tools/godot_bg.sh --headless --path . --script tests/bangkok_fabric_test.gd
## Pins:
##   1. CityStyles districts at City Hall plaza, Ratchadamnoen Klang, Grand Palace,
##      Khao San, Yaowarat, Thonburi, Silom; and far_districts carry-over.
##   2. `bangkok_rule` keeps untagged/low buildings in old-town districts out of
##      `bangkok_condo` / `bangkok_tower`, while 8+ mapped levels reach condos/towers.
##   3. Conservation height cap: every untagged building inside the bundled Bangkok
##      snapshot within 700 m of the City Hall eye resolves <= 20 m (<= 16 m in
##      `bangkok_oldtown` / `bangkok_civic`), while mapped 8+ level buildings
##      (Queen's Gallery 8 lv, Krung Thai Bank 27 lv) keep their mapped heights.
##   4. `building=temple` resolves to steep orange-tiled gabled `thai_wat` with
##      `tower == ""` (no East Asian `pagoda`), while mosques keep `minaret`,
##      Hindu Devasathan keeps `shikhara`, and Christian churches keep `spire`.
##   5. `man_made=stupa` is queried by `OsmQuery.build_query`, parsed as `"stupa": true`,
##      and built by `StupaBuilder` (`mapped_stupa` meta) from the bundled snapshot
##      while skipping stupas inside bespoke landmark clear zones.

var failures: Array[String] = []

func _init() -> void:
	_check_districts()
	_check_temple_and_religions()
	_check_query_and_stupas()
	_check_bundled_heights_and_stupas()
	_check_trees_streets_and_sky()
	if failures.is_empty():
		print("BANGKOK FABRIC OK: districts, height caps, Thai wat halls, religion towers and mapped chedis")
		quit(0)
	else:
		for f in failures:
			printerr("BANGKOK FABRIC FAIL: ", f)
		quit(1)

func _check_districts() -> void:
	_expect(ArchitectureStyle.region_for(13.75398, 100.50144, "TH") == "bangkok",
		"Bangkok City Hall pin resolves to region bangkok")
	var frame := CityStyles.local_frame("bangkok", 13.75398, 100.50144)
	_expect(str(frame.get("city", "")) == "bangkok", "local_frame city is bangkok")
	var far := CityStyles.far_districts("bangkok", 13.75398, 100.50144, 6000.0)
	_expect(far.size() >= 8, "Bangkok exports district circles to FarCityBuilder, got %d" % far.size())

	# Plaza shophouse (at origin -> Sao Chingcha / bangkok_oldtown)
	var ctx := {"region": "bangkok", "density": "dense"}
	ctx.merge(frame)
	var shop_b := {"x": 0.0, "z": 120.0 * WorldScale.metres_to_units(), "kind": "commercial",
		"levels": 0, "height_source": "default"}
	var shop_look := ArchitectureStyle.resolve(shop_b, "bangkok", "dense", 0.35, 140.0, ctx)
	_expect(str(shop_look["era"]) == "bangkok_oldtown",
		"Sao Chingcha commercial building resolves to bangkok_oldtown, got %s" % str(shop_look["era"]))
	_expect(int(shop_look["storeys"]) <= 3,
		"bangkok_oldtown shophouse stays <= 3 storeys, got %d" % int(shop_look["storeys"]))

	# Ratchadamnoen Klang block (north of plaza ~280 m -> bangkok_ratchadamnoen fixed 4 storeys)
	var ratch_xz := WorldScale.xz_from_latlon(13.7565, 100.5015, 13.75398, 100.50144)
	var ratch_b := {"x": ratch_xz.x, "z": ratch_xz.y, "kind": "commercial",
		"levels": 0, "height_source": "default"}
	var ratch_look := ArchitectureStyle.resolve(ratch_b, "bangkok", "dense", 0.42, 600.0, ctx)
	_expect(str(ratch_look["era"]) == "bangkok_ratchadamnoen",
		"Ratchadamnoen Klang block resolves to bangkok_ratchadamnoen, got %s" % str(ratch_look["era"]))
	_expect(int(ratch_look["storeys"]) == 4 and str(ratch_look["roof_shape"]) == "flat",
		"Ratchadamnoen Klang block is fixed 4 storeys flat-roofed, got %s" % str(ratch_look))

	# Bangkok City Hall / large civic footprint in oldtown -> bangkok_civic
	var hall_b := {"x": 20.0 * WorldScale.metres_to_units(), "z": 30.0 * WorldScale.metres_to_units(),
		"kind": "civic", "levels": 4, "height_source": "levels"}
	var hall_look := ArchitectureStyle.resolve(hall_b, "bangkok", "dense", 0.2, 6000.0, ctx)
	_expect(str(hall_look["era"]) == "bangkok_civic",
		"Bangkok City Hall civic footprint resolves to bangkok_civic, got %s" % str(hall_look["era"]))

	# Tall mapped apartment (16 levels) still reaches bangkok_condo
	var condo_b := {"x": 0.0, "z": 0.0, "kind": "apartments", "levels": 16, "height_source": "levels"}
	var condo_look := ArchitectureStyle.resolve(condo_b, "bangkok", "dense", 0.5, 800.0, ctx)
	_expect(str(condo_look["era"]) == "bangkok_condo",
		"16-level mapped apartment resolves to bangkok_condo, got %s" % str(condo_look["era"]))

func _check_temple_and_religions() -> void:
	var wat := ArchitectureStyle.resolve({"kind": "temple", "religion": "buddhist"}, "bangkok", "dense", 0.4, 320.0)
	_expect(str(wat["kind"]) == "religious", "building=temple maps to kind religious")
	_expect(str(wat["roof_shape"]) == "gabled" and float(wat["pitch"]) >= 1.2,
		"Thai wat hall gets steep gabled roof, got %s pitch=%.2f" % [str(wat["roof_shape"]), float(wat["pitch"])])
	_expect(str(wat["tower"]) == "",
		"Thai Buddhist temple hall has no pagoda tower, got '%s'" % str(wat["tower"]))
	_expect(bool((wat["relief"] as Dictionary).get("thai_wat", false)),
		"Thai wat hall carries thai_wat roofline relief")

	var untagged_wat := ArchitectureStyle.resolve({"kind": "temple"}, "bangkok", "dense", 0.4, 260.0)
	_expect(str(untagged_wat["tower"]) == "",
		"Untagged building=temple in Bangkok has no pagoda tower, got '%s'" % str(untagged_wat["tower"]))

	var mosque := ArchitectureStyle.resolve({"kind": "mosque", "religion": "muslim"}, "bangkok", "dense", 0.4, 260.0)
	_expect(str(mosque["tower"]) == "minaret", "Bangkok mosque keeps minaret")
	var hindu := ArchitectureStyle.resolve({"kind": "temple", "religion": "hindu"}, "bangkok", "dense", 0.4, 260.0)
	_expect(str(hindu["tower"]) == "shikhara", "Bangkok Hindu Devasathan keeps shikhara")
	var church := ArchitectureStyle.resolve({"kind": "church", "religion": "christian"}, "bangkok", "dense", 0.4, 260.0)
	_expect(str(church["tower"]) == "spire", "Bangkok Christian church keeps spire")

func _check_query_and_stupas() -> void:
	var q := OsmQuery.build_query(13.75398, 100.50144, 1200)
	_expect(q.contains("stupa"), "OsmQuery.build_query includes man_made=stupa")

func _check_bundled_heights_and_stupas() -> void:
	var key := BundledOsm.entry_for(13.75398, 100.50144, "detailed", OsmQuery.QUERY_VERSION)
	var raw := BundledOsm.read(key)
	_expect(raw != "", "Bundled Bangkok capital detailed snapshot loads (%s)" % key)
	if raw == "":
		return
	var snap := OsmParser.parse_features(raw, 13.75398, 100.50144)
	var data := LocationData.new()
	data.latitude = 13.75398
	data.longitude = 100.50144
	data.country = "TH"
	data.quality_preset = RenderSettings.Preset.ULTRA
	data.grid_size = 16
	data.heights.resize(256)
	data.heights.fill(2.0)
	data.water_level = -3.0
	data.buildings = snap.get("buildings", [])
	data.landmark_type = "grand_palace_bangkok"
	data.has_landmark_site = true
	data.landmark_lat = 13.75101
	data.landmark_lon = 100.49188
	data.landmark_candidates = LandmarkSites.select(data, [])

	var ctx := BuildingHeights._height_context(data)
	var m2u := WorldScale.metres_to_units()
	var r700 := 700.0 * m2u
	var over_cap := 0
	var untagged_checked := 0
	var mapped_tall := 0
	var stupa_entries := 0
	for b in data.buildings:
		var bd := b as Dictionary
		if StupaBuilder.accepts(bd):
			stupa_entries += 1
			continue
		if BuildingBuilder._solid_free(bd):
			continue
		var d_u := Vector2(float(bd["x"]), float(bd["z"])).length()
		var look := BuildingHeights._look_for(bd, ctx)
		var res := BuildingHeights._resolve_total(bd, bd, ctx, {}, look)
		var total_m := float(res["total_m"])
		var src := str(res["source"])
		if src in ["levels", "tag_height", "reference"] and total_m > 22.0:
			mapped_tall += 1
		if d_u <= r700 and src not in ["levels", "tag_height", "reference"]:
			untagged_checked += 1
			var cap_m := 16.01 if str(look.get("era", "")) in ["bangkok_civic", "bangkok_oldtown"] else 20.01
			if total_m > cap_m:
				over_cap += 1
	_expect(untagged_checked >= 1000, "Checked >= 1000 untagged buildings within 700 m, got %d" % untagged_checked)
	_expect(over_cap == 0, "Zero untagged buildings within 700 m exceed 16/20 m cap, got %d" % over_cap)
	_expect(mapped_tall >= 8, "Mapped 8+ level buildings (Queen's Gallery, Krung Thai Bank) keep mapped heights, got %d" % mapped_tall)
	_expect(stupa_entries >= 60, "Bundled Bangkok snapshot parses >= 60 man_made=stupa entries, got %d" % stupa_entries)

	# Build stupa meshes outside bespoke landmark clear zones and verify mapped_stupa parts
	var ground := GroundTruth.new(data)
	var holder := Node3D.new()
	var built_stupas := 0
	var cleared_stupas := 0
	var site := TerrainBuilder.landmark_site_xz(data)
	var edge := WorldScale.detailed_extent_units() * 0.5 * 0.98
	for b in data.buildings:
		var bd := b as Dictionary
		if not StupaBuilder.accepts(bd):
			continue
		if not BuildingBuilder._accepted(data, bd, site, edge):
			cleared_stupas += 1
			continue
		if StupaBuilder.build(holder, bd, ground):
			built_stupas += 1
	_expect(built_stupas >= 2, "StupaBuilder builds standing chedis outside landmark clear zones, got %d" % built_stupas)
	_expect(cleared_stupas >= 50, "Stupas inside Grand Palace / Wat Pho / royal wat clear zones are skipped, got %d" % cleared_stupas)
	_expect(built_stupas + cleared_stupas == stupa_entries, "Every mapped stupa is either built or skipped by a bespoke landmark (%d + %d vs %d)" % [built_stupas, cleared_stupas, stupa_entries])
	holder.free()

func _check_trees_streets_and_sky() -> void:
	# BK-8.1: Bangkok street tree mix keeps palms <= 5% and Sanam Luang ring tamarind
	var street_mix := TreeSpecies.bangkok_mix("street", "avenue", "bangkok_oldtown")
	var palm_share := 0.0
	for r in street_mix:
		if str(TreeSpecies.spec(str(r[0])).get("gen", "")) == "palm":
			palm_share += float(r[1])
	_expect(palm_share <= 0.051, "Bangkok street tree mix keeps palms <= 5%%, got %.2f" % palm_share)
	var park_mix := TreeSpecies.bangkok_mix("park", "", "bangkok_civic")
	_expect(park_mix.size() >= 4, "Bangkok park mix includes rain tree, golden shower & palms")

	# BK-8.2: Tropical monsoon sky has warmer dry-season haze & towering wet-season cumulus
	var wet := SkyPalette.season_sky(LocationData.Season.SUMMER, 13.75398)
	var dry := SkyPalette.season_sky(LocationData.Season.WINTER, 13.75398)
	_expect(float(wet["stretch"]) < 1.0 and float(dry["haze"]) > 1.2,
		"Bangkok tropical sky has towering wet cumulus (%.2f) and warm dry haze (%.2f)" % [float(wet["stretch"]), float(dry["haze"])])

	# BK-9.1/9.2/9.4/9.5/9.7: Thai fleet, multi-colour taxis, tuk-tuk, BMTA buses, TH poles & yellow centre
	var fleet := CarFleet.profile_for("bangkok_oldtown", "TH")
	_expect((fleet["kinds"] as Array).has("tuk_tuk") and (fleet["kinds"] as Array).has("pickup"),
		"Bangkok fleet includes tuk_tuk and pickup")
	var taxi: Dictionary = fleet["taxi"]
	_expect((taxi["paint"] as Array).size() >= 5 and float(taxi["share"]) >= 0.10,
		"Bangkok taxis have >= 5 liveries and >= 10%% share")
	var tt_mesh := TukTukModel.mesh(false)
	_expect(tt_mesh != null and tt_mesh.get_surface_count() >= 5, "TukTukModel builds textured multi-surface mesh")
	_expect(TransitVehicles.BUS_PAINT.get("bangkok", []) is Array and (TransitVehicles.BUS_PAINT["bangkok"] as Array).size() >= 4,
		"Bangkok BUS_PAINT carries multi-colour BMTA / Thai Smile Bus liveries")
	_expect("TH" in UtilityPoles.COUNTRIES, "UtilityPoles enables TH square concrete poles")
	var th_data := LocationData.new()
	th_data.country = "TH"
	_expect(RoadSurface.yellow_centre(th_data), "Thailand roads use yellow opposing centre lines")

	# BK-11: TowerLooks region fix (southeast_asia & kuala_lumpur)
	_expect(TowerLooks._family("southeast_asia", "") == "asia" and TowerLooks._family("kuala_lumpur", "") == "asia",
		"TowerLooks maps southeast_asia and kuala_lumpur to asia family")

func _expect(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
