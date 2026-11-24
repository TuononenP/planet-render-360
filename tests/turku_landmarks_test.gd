extends SceneTree

## Turku landmarks, bridges and architecture tests (offline):
## tools/godot_bg.sh --headless --path . --script tests/turku_landmarks_test.gd

var failures: Array[String] = []

const EXPECTED_TYPES := [
	# Original 17 Turku landmarks
	"turku_cathedral", "turku_castle", "mikaelinkirkko", "martinkirkko",
	"turku_orthodox_church", "turku_art_museum", "vartiovuori_observatory",
	"turku_market_hall", "turku_main_library", "turku_city_theatre",
	"kakola_prison", "vanha_suurtori", "suomen_joutsen", "fori_ferry",
	"samppalinnan_maauimala", "paavo_nurmen_stadion", "turku_kauppatori",
	# Phase T-3A: Kauppatori, Yliopistonkatu & Commercial Core (14)
	"hamburger_bors_turku", "wiklund_turku", "hansakortteli", "abo_svenska_teater",
	"kop_kolmio_turku", "turun_sanomat_building", "kivikukkaro", "turku_synagogue",
	"puutori_ensemble", "betel_church_turku", "prima_albatross_aurakatu",
	"pantern_hjelt_kaskenkatu", "humalistonkatu_jugend", "turku_fire_station",
	# Phase T-3B: Aurajoki Waterfront & Maritime (16)
	"turku_city_hall", "qwensel_house", "verdandi_house", "chappe_art_house",
	"aboa_vetus_rettig", "pinella_porthan", "sibelius_museum", "abo_akademi_main",
	"abo_akademi_book_tower", "wam_museum", "turku_state_office", "fuuga_music_hall",
	"samppalinna_windmill", "forum_marinum", "sigyn_bore_ships", "crichton_vulcan_crane",
	# Phase T-3C: TYKS Hospital Area, Universities, Kupittaa & Cultural Hills (16)
	"tyks_majakka", "tyks_t_hospital", "tyks_a_u_hospitals", "tyks_medisiina_dentalia",
	"tyks_kantasairaala_pavilions", "utu_main_campus", "utu_agora_quantum",
	"turku_school_economics", "turku_concert_hall", "kupittaa_biocity_electro",
	"intelligate_ict_kupittaa", "veritas_stadion", "kupittaan_puisto_pavilions",
	"resurrection_chapel", "st_catherine_church_turku", "maaria_church_turku",
	# Phase T-3D & T-5.5: Stations, Logomo, Port, Skyline Towers, Arenas & Funicular (15)
	"kakola_funicular", "logomo_and_bridge", "turku_central_station", "turku_bus_station",
	"kupittaa_station", "port_of_turku_terminals", "if_torni_turku", "ikituuri_turku",
	"airiston_tahti", "paaskyvuori_tower", "luolavuori_water_tower", "iso_heikkila_water_tower",
	"gatorade_center_turku", "telakkaranta_linnanfaltti", "ruissalo_villas_spa",
	"meyer_gantry_cranes",
]

const EXPECTED_BRIDGES := [
	"br_turku_tuomiokirkkosilta", "br_turku_kirjastosilta", "br_turku_auransilta",
	"br_turku_teatterisilta", "br_turku_myllysilta", "br_turku_martinsilta",
	"br_turku_tuomaansilta", "br_turku_halistensilta", "br_turku_aurajoen_rautatiesilta",
	"br_turku_hirvensalonsilta", "br_turku_aninkaistensilta", "br_turku_ukko_pekan_silta",
]

func _init() -> void:
	# 1. All 78 Turku landmarks exist, have non-empty meshes, and sit inside Turku.
	for t in EXPECTED_TYPES:
		var e := LocationData.entry_for_type(t)
		_check(not e.is_empty(), "Registry entry present for %s" % t)
		if e.is_empty():
			continue
		var lat := float(e.get("lat", 0.0))
		var lon := float(e.get("lon", 0.0))
		_check(lat > 60.41 and lat < 60.49 and lon > 22.11 and lon < 22.35,
			"%s coordinates inside Turku: %s, %s" % [t, lat, lon])
		var root := LandmarkBuilder.build(t)
		var meshes := _count_meshes(root)
		_check(meshes > 0, "%s built %d meshes" % [t, meshes])
		LandmarkLights.dress(root, t)
		root.free()
	# 2. All 12 Turku bridges exist with conf >= 2 and build cleanly.
	for bid in EXPECTED_BRIDGES:
		var row := BridgeSpecs.row_for(bid)
		_check(not row.is_empty(), "BridgeSpec present for %s" % bid)
		if not row.is_empty():
			_check(int(row.get("conf", 0)) >= BridgeSpec.MIN_BUILT_CONF, "%s conf >= 2" % bid)
			var b := LandmarkBuilder.build_bridge(bid, float(row.get("clear", 4.5)))
			_check(_count_meshes(b) > 0, "%s bridge built geometry" % bid)
			LandmarkLights.dress(b, bid)
			b.free()
	# 3. Turku architecture districts & Föli bus livery.
	var z := CityStyles.zone_at(60.4518, 22.2666)
	_check(not z.is_empty() and str(z[0]) == "turku", "Turku centre resolves to city 'turku'")
	var f_ports := CityStyles.local_frame("turku", 60.4480, 22.2480)
	var ports := BuildingEra.refine("turku", "house", {"x": 0.0, "z": 0.0, "levels": 2}, f_ports, 0.5, 140.0)
	_check(ports == "turku_wood", "Port Arthur house resolves to turku_wood (got %s)" % ports)
	var f_ruissalo := CityStyles.local_frame("turku", 60.4290, 22.1500)
	var ruissalo := BuildingEra.refine("turku", "house", {"x": 0.0, "z": 0.0, "levels": 2}, f_ruissalo, 0.5, 180.0)
	_check(ruissalo == "turku_villa", "Ruissalo house resolves to turku_villa (got %s)" % ruissalo)
	_check(TransitVehicles.BUS_PAINT.has("turku"), "Föli bus paint present for turku")
	# 4. Samppalinnan maauimala & Paavo Nurmen Stadion aliases, dimensions, SEAT_META, clearance & terrain cut.
	_check_sports_venues()
	# 5. Turku Kauppatori model, walker breezeway, slope conform & Orthodox church tree keep-out.
	_check_kauppatori()
	# 6. Föri animated vessel shuttling between stationary riverbank landing stages.
	_check_fori()
	if failures.is_empty():
		print("TURKU LANDMARKS OK: %d landmarks, %d bridges, districts & Föli livery" % [
			EXPECTED_TYPES.size(), EXPECTED_BRIDGES.size()])
		quit(0)
	else:
		for msg in failures:
			printerr("TURKU LANDMARKS FAIL: ", msg)
		quit(1)

func _check_sports_venues() -> void:
	var alias_cases := {
		"Samppalinnan maauimala": "samppalinnan_maauimala",
		"Samppis": "samppalinnan_maauimala",
		"Paavo Nurmen stadion": "paavo_nurmen_stadion",
		"Paavo Nurmi Stadium": "paavo_nurmen_stadion",
	}
	for query in alias_cases:
		var got := LocationData.landmark_for(60.444, 22.263, query)
		_check(got == alias_cases[query], "Alias '%s' resolves to %s (got %s)" % [query, alias_cases[query], got])
	_check(LocationData.landmark_for(60.4518, 22.2666, "Turku, Finland") == "turku_cathedral",
		"Turku centre still resolves to turku_cathedral")

	var s_root := LandmarkBuilder.build("samppalinnan_maauimala")
	var s_box := _full_aabb(s_root)
	_check(s_box.end.y >= 10.5 and s_box.end.y <= 13.0,
		"Samppalinna diving tower top 10.5..13.0 m (got %.2f)" % s_box.end.y)
	_check(maxf(s_box.size.x, s_box.size.z) >= 85.0,
		"Samppalinna span >= 85 m (got %.2f x %.2f)" % [s_box.size.x, s_box.size.z])
	_check(_has_seated_child(s_root, "ChildrensPool"), "Samppalinna has SEAT_META ChildrensPool")
	s_root.free()

	var p_root := LandmarkBuilder.build("paavo_nurmen_stadion")
	var p_box := _full_aabb(p_root)
	_check(p_box.end.y >= 19.0 and p_box.end.y <= 21.5,
		"Paavo Nurmi canopy top 19.0..21.5 m (got %.2f)" % p_box.end.y)
	_check(p_box.size.x >= 190.0 and p_box.size.z >= 120.0,
		"Paavo Nurmi span >= 190x120 m (got %.2f x %.2f)" % [p_box.size.x, p_box.size.z])
	for cname in ["WestRearPavilion", "NorthServiceBuilding", "EntranceKiosks"]:
		_check(_has_seated_child(p_root, cname), "Paavo Nurmi has SEAT_META %s" % cname)
	p_root.free()

	# Clearance & Karikon huvila preservation at Paavo Nurmen Stadion.
	var p_entry := LocationData.entry_for_type("paavo_nurmen_stadion")
	var p_lat := float(p_entry["lat"])
	var p_lon := float(p_entry["lon"])
	var clear := LandmarkSites.clear_m(p_entry)
	for osm_pt in [[60.442758, 22.260556, "way 24206308"], [60.442985, 22.260117, "way 777857700"]]:
		var xz := WorldScale.xz_from_latlon(float(osm_pt[0]), float(osm_pt[1]), p_lat, p_lon)
		_check(LandmarkSites.span_dist(xz, Vector2.ZERO, p_entry) < clear,
			"Paavo Nurmi clears %s" % osm_pt[2])
	var karikko := WorldScale.xz_from_latlon(60.443600, 22.261451, p_lat, p_lon)
	_check(LandmarkSites.span_dist(karikko, Vector2.ZERO, p_entry) >= clear
		and not LandmarkSites.in_model_rect(karikko, Vector2.ZERO, p_entry),
		"Karikon huvila preserved outside Paavo Nurmi clearance")

	# Terrain terrace cuts preserve datum at base_at_m while lowering basin/track bumps.
	_check_terrace_cut("samppalinnan_maauimala", Vector2(-38.0, 0.0), Vector2(0.0, 0.0), -1.0)
	_check_terrace_cut("paavo_nurmen_stadion", Vector2(0.0, 0.0), Vector2(30.0, 10.0), 0.0)

func _check_kauppatori() -> void:
	for q in ["Turun kauppatori", "Turku Market Square"]:
		_check(LocationData.landmark_for(60.4517, 22.2669, q) == "turku_kauppatori",
			"Kauppatori alias '%s' resolves to turku_kauppatori" % q)
	var k_root := LandmarkBuilder.build("turku_kauppatori")
	var parts := LandmarkBuilder.parts(k_root)
	_check(parts.size() >= 2 and parts.size() <= 16,
		"Kauppatori parts in 2..16 (got %d)" % parts.size())
	var k_box := _full_aabb(k_root)
	_check(k_box.size.x >= 110.0 and k_box.size.z >= 110.0,
		"Kauppatori span >= 110 m (got %.1f x %.1f)" % [k_box.size.x, k_box.size.z])
	_check(k_box.end.y >= 10.5 and k_box.end.y <= 11.5,
		"Kauppatori mast top 10.5..11.5 m (got %.2f)" % k_box.end.y)
	k_root.free()

	var orth := LocationData.entry_for_type("turku_orthodox_church")
	_check(float(orth.get("tree_clear_m", 99.0)) <= 18.0,
		"Orthodox church tree_clear_m tightened <= 18 m")
	var k_entry := LocationData.entry_for_type("turku_kauppatori")
	var d := LocationData.new()
	d.latitude = float(k_entry["lat"])
	d.longitude = float(k_entry["lon"])
	d.landmark_type = "turku_kauppatori"
	d.has_landmark_site = true
	d.landmark_lat = d.latitude
	d.landmark_lon = d.longitude
	d.landmark_candidates = LandmarkSites.select(d, [])
	var cherry := WorldScale.xz_from_latlon(60.45190, 22.26640, d.latitude, d.longitude)
	_check(not LandmarkSites.tree_cleared(cherry, LandmarkSites.tree_clears(d)),
		"Kauppatori cherry grove not cleared by Orthodox church")

	var solids := ViewWalk._landmark_solids(d)
	var ax := LandmarkSites.axis(k_entry)
	var side := Vector2(-ax.y, ax.x)
	var aura_core := ax * -57.0 + side * -15.7
	var breezeway := ax * -3.3 + side * 58.2
	_check(ViewWalk.blocked(solids, aura_core), "Aurakatu pavilion glass core blocks walkers")
	_check(not ViewWalk.blocked(solids, breezeway), "Eerikinkatu 6.3 m central breezeway is walkable")

func _check_terrace_cut(type: String, base_local: Vector2, probe_local: Vector2, want_rel: float) -> void:
	var entry := LocationData.entry_for_type(type)
	var d := LocationData.new()
	d.latitude = float(entry["lat"])
	d.longitude = float(entry["lon"])
	d.landmark_type = type
	d.has_landmark_site = true
	d.landmark_lat = d.latitude
	d.landmark_lon = d.longitude
	var size := 241
	var step := WorldScale.detailed_extent_units() / float(size - 1)
	var surf := PackedFloat32Array()
	surf.resize(size * size)
	surf.fill(26.0)
	# Put a 2 m mound at probe_local so we confirm the hold lowers bumps while leaving base_local untouched.
	var axis := LandmarkSites.axis(entry)
	var side := Vector2(-axis.y, axis.x)
	var base_w := (axis * base_local.x + side * base_local.y) * WorldScale.metres_to_units()
	var probe_w := (axis * probe_local.x + side * probe_local.y) * WorldScale.metres_to_units()
	var half := float(size) * 0.5
	for z in size:
		for x in size:
			var wp := Vector2((float(x) - half) * step, (float(z) - half) * step)
			if wp.distance_to(probe_w) < 14.0:
				surf[z * size + x] = 28.0
	LandmarkStairCut.cut(surf, size, step, d)
	var base_after := LandmarkStairCut._sample(surf, size, step, base_w)
	var probe_after := LandmarkStairCut._sample(surf, size, step, probe_w)
	_check(absf(base_after - 26.0) < 0.05, "%s cut keeps base_at_m datum untouched (got %.3f)" % [type, base_after])
	_check(probe_after <= 26.0 + want_rel + 0.15,
		"%s cut holds probe <= %.2f (got %.3f)" % [type, 26.0 + want_rel, probe_after])

func _has_seated_child(root: Node3D, child_name: String) -> bool:
	var model := root.get_node_or_null("Model")
	if model == null:
		return false
	var c := model.get_node_or_null(child_name)
	return c != null and bool(c.get_meta(LandmarkTerrain.SEAT_META, false))

func _full_aabb(root: Node3D) -> AABB:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for part in LandmarkBuilder.parts(root):
		var xf := part.transform
		var p := part.get_parent() as Node3D
		while p != null and p != root:
			xf = p.transform * xf
			p = p.get_parent() as Node3D
		var b := xf * part.mesh.get_aabb()
		lo = lo.min(b.position)
		hi = hi.max(b.end)
	return AABB(lo, hi - lo)

func _count_meshes(node: Node) -> int:
	var n := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for c in node.get_children():
		n += _count_meshes(c)
	return n

func _check_fori() -> void:
	var root := LandmarkBuilder.build("fori_ferry")
	var model := root.get_node_or_null("Model") as Node3D
	var vessel := model.get_node_or_null("ForiVessel") as ForiShuttle if model != null else null
	var landings := model.get_node_or_null("ForiLandings") as Node3D if model != null else null
	_check(vessel != null and _count_meshes(vessel) > 0, "Föri has animated ForiVessel child with meshes")
	_check(landings != null and _count_meshes(landings) > 0, "Föri has stationary ForiLandings child with meshes")
	if vessel != null:
		_check(absf(vessel.sample_x(0.0)) < 0.01, "Föri starts centred at mid-river on frame 0")
		_check(absf(vessel.sample_x(vessel.cross_sec * 0.5) - vessel.travel_half_m) < 0.05,
			"Föri docks at east landing stage after half crossing")
		_check(absf(vessel.sample_x(vessel.cross_sec * 1.5 + vessel.pause_sec) + vessel.travel_half_m) < 0.05,
			"Föri docks at west landing stage on return leg")
		# Real operating schedule: Summer (May–Sep) 06:15–23:00, Winter (Oct–Apr) 06:15–21:00.
		_check(ForiShuttle.is_operating(22.5, 7), "Föri active summer 22:30")
		_check(not ForiShuttle.is_operating(23.25, 7), "Föri off summer 23:15")
		_check(ForiShuttle.is_operating(20.5, 1), "Föri active winter 20:30")
		_check(not ForiShuttle.is_operating(21.25, 1), "Föri off winter 21:15")
		_check(not ForiShuttle.is_operating(6.0, 7) and not ForiShuttle.is_operating(6.0, 1), "Föri off at 06:00")
		# Night lights ON when operating at night, OFF & moored when outside schedule.
		var lamp_node := vessel.get_node_or_null("ForiLamp") as MeshInstance3D
		var deck_light := vessel.get_node_or_null("ForiDeckLight") as OmniLight3D
		vessel.apply_state(0.0, 22.5, 7, 1.0)
		var mat_on := lamp_node.get_surface_override_material(0) as StandardMaterial3D if lamp_node != null else null
		_check(absf(vessel.position.x) < 0.05 and mat_on != null and mat_on.emission_energy_multiplier > 1.0
			and deck_light != null and deck_light.visible and deck_light.light_energy > 0.5,
			"Föri summer 22:30 night: moving mid-river with cabin/mast/deck lights ON")
		vessel.apply_state(0.0, 23.25, 7, 1.0)
		_check(absf(vessel.position.x + vessel.travel_half_m) < 0.05 and mat_on != null
			and mat_on.emission_energy_multiplier == 0.0 and deck_light != null and not deck_light.visible,
			"Föri summer 23:15 night: moored at dock with ALL vessel lights OFF")
		vessel.apply_state(0.0, 21.25, 1, 1.0)
		_check(absf(vessel.position.x + vessel.travel_half_m) < 0.05 and mat_on != null
			and mat_on.emission_energy_multiplier == 0.0 and deck_light != null and not deck_light.visible,
			"Föri winter 21:15 night: moored at dock with ALL vessel lights OFF")
	root.free()
	# Föri must be selected from the Turku preset on High and Ultra (not dropped by registry cap).
	for preset in [2, 3]:
		var d := LocationData.new()
		d.latitude = 60.4518
		d.longitude = 22.2666
		d.quality_preset = preset
		d.landmark_type = LocationData.landmark_for(d.latitude, d.longitude, "")
		var has_fori := false
		for c in LandmarkSites.select(d, []):
			if str((c as Dictionary).get("type", "")) == "fori_ferry":
				has_fori = true
				break
		_check(has_fori, "Föri selected from Turku preset at quality %d" % preset)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
