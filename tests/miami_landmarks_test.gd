extends SceneTree

## Miami landmarks, bridges, aliases and Ultra selection tests (offline):
## tools/godot_bg.sh --headless --path . --script tests/miami_landmarks_test.gd

var failures: Array[String] = []

const EXPECTED_TYPES: Array[String] = [
	# Centre A — Downtown & Edgewater
	"freedom_tower_miami",
	"kaseya_center",
	"pamm_miami",
	"frost_science_miami",
	"adrienne_arsht_center",
	"skyviews_miami_wheel",
	"bacardi_building_miami",
	"one_thousand_museum",
	"miamicentral_station",
	"miami_dade_cultural_center",
	# Centre B — Brickell & Neighbourhood Icons
	"brickell_city_centre_ribbon",
	"atlantis_condominium",
	"loandepot_park",
	"wynwood_walls",
	"tower_theater_miami",
	"museum_garage_miami",
	# PortMiami
	"portmiami_terminal_a",
	"portmiami_terminal_b",
	"portmiami_terminal_v",
	"portmiami_carnival_msc",
	# Centre C — Miami Beach (Ocean Drive & South Beach)
	"ocean_drive_colony_starlite",
	"ocean_drive_breakwater_edison",
	"art_deco_welcome_center",
	"casa_casuarina_versace",
	"ocean_drive_carlyle_cardozo",
	"lincoln_road_1111",
	"new_world_center_miami",
	"miami_beach_convention_center",
	"holocaust_memorial_miami_beach",
	"old_city_hall_miami_beach",
	"south_pointe_pier_park",
	# Centre D — Mid-Beach
	"fontainebleau_miami_beach",
	"faena_forum_miami_beach",
	"flagler_memorial_monument",
	# Centre E & F — Vizcaya, Coconut Grove & Coral Gables
	"vizcaya_museum_gardens",
	"miami_city_hall_dinner_key",
	"ermita_de_la_caridad",
	"biltmore_hotel_coral_gables",
	"venetian_pool_coral_gables",
	"coral_gables_city_hall",
	"alhambra_water_tower",
	"douglas_entrance_coral_gables",
	# Far — Signature Bridge, Key Biscayne & Metro
	"i395_signature_bridge",
	"cape_florida_lighthouse",
	"miami_marine_stadium",
	"stiltsville_biscayne_bay",
	"seaquarium_golden_dome",
	"hard_rock_stadium",
	"nu_stadium_freedom_park",
	"ancient_spanish_monastery",
	"opa_locka_city_hall",
]
const EXPECTED_BRIDGES: Array[String] = [
	"br_miami_macarthur_west",
	"br_miami_macarthur_east",
	"br_miami_port_boulevard",
	"br_miami_venetian_west",
	"br_miami_venetian_east",
	"br_miami_brickell_ave",
	"br_miami_south_miami_ave",
	"br_miami_sw_2nd_ave",
	"br_miami_sw_1st_st",
	"br_miami_west_flagler",
	"br_miami_brickell_key",
	"br_miami_william_powell",
	"br_miami_julia_tuttle",
]

const LAT_MIN := 25.60
const LAT_MAX := 26.00
const LON_MIN := -80.45
const LON_MAX := -80.05

func _init() -> void:
	# Verify Miami batch is wired into LocationData.landmarks() with no duplicate types.
	var seen := {}
	for e in LocationData.landmarks():
		var t := str(e["type"])
		_check(not seen.has(t), "duplicate landmark type: %s" % t)
		seen[t] = true

	# Verify One WTC keeps the bare "freedom tower" alias globally.
	_check(LocationData.landmark_for(40.7130, -74.0132, "Freedom Tower") == "one_wtc",
		"Bare 'Freedom Tower' in NYC resolves to one_wtc")

	for t in EXPECTED_TYPES:
		var e := LocationData.entry_for_type(t)
		_check(not e.is_empty(), "Registry entry present for %s" % t)
		if e.is_empty():
			continue
		var lat := float(e.get("lat", 0.0))
		var lon := float(e.get("lon", 0.0))
		_check(lat >= LAT_MIN and lat <= LAT_MAX and lon >= LON_MIN and lon <= LON_MAX,
			"%s coordinates inside Miami box: %.5f, %.5f" % [t, lat, lon])
		var root := LandmarkBuilder.build(t)
		var parts := LandmarkBuilder.parts(root)
		_check(parts.size() >= 2 and parts.size() <= 16,
			"%s has %d surface parts (expected 2..16)" % [t, parts.size()])
		var bounds := AABB()
		var tris := 0
		var first := true
		for m in parts:
			var box := m.mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			tris += m.mesh.surface_get_array_len(0) / 3
		root.free()
		_check(not first, "%s built non-empty geometry" % t)
		if not first:
			var hm := float(e.get("height_m", 0.0))
			var tol := maxf(2.0, hm * 0.03)
			_check(absf(bounds.end.y - hm) <= tol,
				"%s top %.2f m within %.2f m of height_m %.2f m" % [t, bounds.end.y, tol, hm])
			_check(bounds.position.y >= -6.0,
				"%s foundation %.2f m within plinth allowance" % [t, bounds.position.y])
			_check(tris >= 100 and tris <= 150000,
				"%s triangles %d in 100..150000" % [t, tris])

	if seen.has("freedom_tower_miami"):
		_check(LocationData.landmark_for(25.7802, -80.1896, "Freedom Tower Miami") == "freedom_tower_miami",
			"'Freedom Tower Miami' resolves to freedom_tower_miami")
		_check(LocationData.landmark_for(25.7802, -80.1896, "Miami News Tower") == "freedom_tower_miami",
			"'Miami News Tower' resolves to freedom_tower_miami")
		_check(LocationData.landmark_for(40.7130, -74.0132, "Freedom Tower") == "one_wtc",
			"Bare 'Freedom Tower' still resolves to one_wtc")

	for bid in EXPECTED_BRIDGES:
		var row := BridgeSpecs.row_for(bid)
		_check(not row.is_empty(), "BridgeSpec present for %s" % bid)
		if not row.is_empty():
			_check(int(row.get("conf", 0)) >= BridgeSpec.MIN_BUILT_CONF, "%s conf >= 2" % bid)
			var b := LandmarkBuilder.build_bridge(bid, float(row.get("clear", 6.0)))
			_check(LandmarkBuilder.parts(b).size() > 0, "%s bridge built geometry" % bid)
			b.free()

	_check_centre_selection(25.7743, -80.1855, "freedom_tower_miami",
		["kaseya_center", "one_thousand_museum", "pamm_miami", "frost_science_miami",
			"skyviews_miami_wheel", "br_miami_port_boulevard", "br_miami_macarthur_west",
			"miami_tower", "southeast_financial_center", "aston_martin_residences"])
	_check_centre_selection(25.7670, -80.1900, "brickell_city_centre_ribbon",
		["freedom_tower_miami", "miami_tower", "atlantis_condominium",
			"br_miami_brickell_ave", "br_miami_south_miami_ave", "panorama_tower",
			"four_seasons_miami", "brickell_flatiron"])
	_check_centre_selection(25.7810, -80.1300, "ocean_drive_breakwater_edison",
		["ocean_drive_colony_starlite", "art_deco_welcome_center", "casa_casuarina_versace",
			"ocean_drive_carlyle_cardozo", "lincoln_road_1111", "new_world_center_miami",
			"south_pointe_pier_park", "portofino_tower", "continuum_south_tower"])
	_check_centre_selection(25.8180, -80.1220, "fontainebleau_miami_beach",
		["faena_forum_miami_beach", "eden_roc_miami_beach", "blue_diamond_miami_beach"])
	_check_centre_selection(25.7444, -80.2105, "vizcaya_museum_gardens",
		["ermita_de_la_caridad", "miami_city_hall_dinner_key"])
	_check_centre_selection(25.7410, -80.2790, "biltmore_hotel_coral_gables",
		["venetian_pool_coral_gables", "coral_gables_city_hall", "alhambra_water_tower"])

	if failures.is_empty():
		print("MIAMI LANDMARKS OK: %d icons, %d bridges" % [EXPECTED_TYPES.size(), EXPECTED_BRIDGES.size()])
		quit(0)
	else:
		for msg in failures:
			printerr("MIAMI LANDMARKS FAIL: ", msg)
		quit(1)

func _check_centre_selection(lat: float, lon: float, want_primary: String, want_extras: Array) -> void:
	var d := LocationData.new()
	d.latitude = lat
	d.longitude = lon
	d.quality_preset = 3
	d.landmark_type = LocationData.landmark_for(lat, lon, "")
	_check(d.landmark_type == want_primary,
		"Centre (%.4f, %.4f) primary is %s (got %s)" % [lat, lon, want_primary, d.landmark_type])
	var selected := {}
	for c in LandmarkSites.select(d, []):
		selected[str((c as Dictionary).get("type", ""))] = true
	for t in want_extras:
		_check(selected.has(str(t)),
			"Centre (%.4f, %.4f) Ultra selection includes %s" % [lat, lon, str(t)])

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
