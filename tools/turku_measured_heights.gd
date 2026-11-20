extends SceneTree

## Registry height and roof parameters against the City of Turku LoD2 model
## for every registry landmark the turku_lod2 bundle covers, plus planned
## Turku Tier 1 buildings in PLANNED.
## For each row it takes the LoD2 buildings whose centroid lies within reach
## (min(clear_m, 75 m) or 55 m for planned) of the entry and reports the
## nearest, tallest, roof height, pitch, ridge azimuth, shape, storeys, and
## footprint area.
## Run headlessly:
## tools/godot_bg.sh --headless --path . --script tools/turku_measured_heights.gd

## Planned Turku landmarks / major buildings (Phase T-3A..T-3D) for LoD2 audit:
## [type, name, lat, lon, reach_m]
const PLANNED := [
	# T-3A: Kauppatori, Yliopistonkatu & Commercial Core
	["hamburger_bors_turku", "Scandic Hamburger Börs (Uusi+Vanha)", 60.451003, 22.268695, 50.0],
	["wiklund_turku", "Sokos Wiklund", 60.451915, 22.268961, 50.0],
	["hansakortteli", "Hansakortteli (Kultatalo/Antintalo)", 60.451114, 22.265069, 65.0],
	["abo_svenska_teater", "Åbo Svenska Teater", 60.450751, 22.265913, 35.0],
	["kop_kolmio_turku", "KOP-kolmio", 60.450129, 22.266445, 40.0],
	["turun_sanomat_building", "Turun Sanomat Building (Kauppiaskatu 5)", 60.450500, 22.269900, 35.0],
	["kivikukkaro", "Kivikukkaro", 60.450635, 22.260871, 45.0],
	["turku_synagogue", "Turku Synagogue", 60.455739, 22.266577, 30.0],
	["puutori_ensemble", "Puutori & Puutorin Vessa", 60.455219, 22.269088, 45.0],
	["betel_church_turku", "Betel Church", 60.451191, 22.261149, 35.0],
	["prima_albatross_aurakatu", "Albatross & Prima (Aurakatu)", 60.453550, 22.262750, 50.0],
	["pantern_hjelt_kaskenkatu", "Pantern (Kaskenkatu 2)", 60.448800, 22.271800, 40.0],
	["humalistonkatu_jugend", "Humalistonkatu Jugend Row", 60.451750, 22.259150, 50.0],
	["turku_fire_station", "Turku Central Fire Station", 60.448350, 22.258250, 45.0],
	# T-3B: Aurajoki Waterfront
	["turku_city_hall", "Turku City Hall", 60.448815, 22.268519, 35.0],
	["qwensel_house", "Qwensel House", 60.448595, 22.267682, 35.0],
	["verdandi_house", "Verdandi House", 60.449565, 22.268936, 40.0],
	["chappe_art_house", "Art House Chappe", 60.450050, 22.271600, 35.0],
	["aboa_vetus_rettig", "Aboa Vetus Ars Nova (Rettig Palace)", 60.449744, 22.273596, 45.0],
	["pinella_porthan", "Pinella & Porthan Monument", 60.451471, 22.274998, 35.0],
	["sibelius_museum", "Sibelius Museum", 60.453687, 22.277556, 35.0],
	["abo_akademi_main", "Åbo Akademi Main / Academy Building", 60.451192, 22.278324, 55.0],
	["abo_akademi_book_tower", "Åbo Akademi Book Tower", 60.453050, 22.276800, 35.0],
	["wam_museum", "Wäinö Aaltonen Museum (WAM)", 60.444952, 22.260236, 45.0],
	["turku_state_office", "State Office Building", 60.445066, 22.262381, 50.0],
	["fuuga_music_hall", "Turku Music Hall Fuuga", 60.445684, 22.262024, 50.0],
	["samppalinna_windmill", "Samppalinna Windmill & Restaurant", 60.443996, 22.260161, 45.0],
	["forum_marinum", "Forum Marinum", 60.436800, 22.236150, 55.0],
	["crichton_vulcan_crane", "Aurajoki Harbour Crane", 60.435750, 22.238350, 35.0],
	# T-3C: Universities, TYKS Hospital Area, Kupittaa & Cultural Hills
	["utu_main_campus", "University of Turku Main Hill", 60.454162, 22.284697, 65.0],
	["utu_agora_quantum", "Agora & Quantum (UTU)", 60.455393, 22.285383, 60.0],
	["turku_school_economics", "Turku School of Economics", 60.455250, 22.287750, 50.0],
	["turku_concert_hall", "Turku Concert Hall", 60.455720, 22.270634, 50.0],
	["tyks_majakka", "TYKS Majakkasairaala", 60.452580, 22.293950, 70.0],
	["tyks_t_hospital", "TYKS T-sairaala", 60.451750, 22.292150, 70.0],
	["tyks_a_u_hospitals", "TYKS A-sairaala & U-sairaala", 60.453506, 22.289779, 65.0],
	["tyks_medisiina_dentalia", "Medisiina D & Dentalia", 60.450950, 22.290950, 55.0],
	["tyks_kantasairaala_pavilions", "Kantasairaala Pavilions", 60.450400, 22.287900, 60.0],
	["kupittaa_biocity_electro", "BioCity & ElectroCity", 60.449400, 22.292200, 65.0],
	["intelligate_ict_kupittaa", "Intelligate & ICT-City", 60.449150, 22.296600, 65.0],
	["veritas_stadion", "Veritas Stadion", 60.442600, 22.291350, 75.0],
	["kupittaan_puisto_pavilions", "Kupittaa Park Pools & Pavilions", 60.444650, 22.287600, 60.0],
	["resurrection_chapel", "Resurrection Chapel", 60.433750, 22.307500, 45.0],
	["st_catherine_church_turku", "St. Catherine's Church", 60.462250, 22.293450, 40.0],
	["maaria_church_turku", "Maaria Church", 60.473350, 22.293100, 40.0],
	# T-3D: Stations, Logomo, Port, Skyline Towers & Arenas
	["logomo_and_bridge", "Logomo", 60.456985, 22.258005, 70.0],
	["turku_central_station", "Turku Central Railway Station", 60.455677, 22.260744, 50.0],
	["turku_bus_station", "Turku Bus Station", 60.457073, 22.268170, 45.0],
	["kupittaa_station", "Kupittaa Railway Station", 60.450350, 22.297450, 45.0],
	["port_of_turku_terminals", "Port of Turku Terminals", 60.434800, 22.221500, 75.0],
	["if_torni_turku", "If-torni", 60.447850, 22.302750, 50.0],
	["ikituuri_turku", "Ikituuri", 60.458150, 22.294350, 40.0],
	["airiston_tahti", "Airiston Tähti", 60.427970, 22.237072, 45.0],
	["telakkaranta_linnanfaltti", "Telakkaranta & Linnanfältti", 60.436600, 22.241200, 60.0],
	["paaskyvuori_tower", "Pääskyvuori Link Tower", 60.447051, 22.332216, 50.0],
	["turku_water_towers", "Vesilinna / Juhannuskukkula Water Tower", 60.459139, 22.256609, 45.0],
	["gatorade_center_turku", "Gatorade Center", 60.456200, 22.186950, 75.0],
	["ruissalo_villas_spa", "Ruissalo Spa / Botanical Garden", 60.433150, 22.173850, 60.0],
]

func _query_site(lat: float, lon: float, reach: float) -> Dictionary:
	var at := Gk23.forward(lat, lon)
	var nearest_row: Array = []
	var nearest_d := INF
	var tallest_row: Array = []
	var tallest := 0.0
	var largest_row: Array = []
	var largest_area := 0.0
	var hits: Array = []
	for r in HelsinkiLod2.rows_for(lat, lon):
		var row := r as Array
		var d := Vector2(float(row[1]) - at[0], float(row[2]) - at[1]).length()
		if d > reach:
			continue
		hits.append([d, row])
		var h := float(row[4])
		var area := float(row[3])
		if h > tallest:
			tallest = h
			tallest_row = row
		if area > largest_area:
			largest_area = area
			largest_row = row
		if d < nearest_d:
			nearest_d = d
			nearest_row = row
	hits.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	return {
		"count": hits.size(),
		"nearest_d": nearest_d if hits.size() > 0 else -1.0,
		"nearest": nearest_row,
		"tallest": tallest_row,
		"largest": largest_row,
		"hits": hits,
	}

func _fmt_row(row: Array) -> String:
	if row.is_empty():
		return "0.0\t0.0\t0.0\t-\t0\t0"
	return "%.1f\t%.1f\t%.0f\t%s\t%d\t%.0f" % [
		float(row[4]), float(row[5]), float(row[6]), str(row[8]), int(row[9]), float(row[3])
	]

func _init() -> void:
	print("HEIGHTS type\tmodel_m\tnearest_m\tnearest_d\ttallest_m\tdiff_m\troof_h\tpitch\tshape\tstoreys\tarea_m2\tcount")
	for e in LocationData.landmarks():
		var entry := e as Dictionary
		var lat := float(entry["lat"])
		var lon := float(entry["lon"])
		if lat < 60.34 or lat > 60.62 or lon < 22.05 or lon > 22.52:
			continue
		if str(entry.get("kind", "")) == "Bridge" or bool(entry.get("secondary", false)):
			continue
		var reach := clampf(LandmarkSites.clear_m(entry), 30.0, 75.0)
		var res := _query_site(lat, lon, reach)
		var model := float(entry.get("height_m", 0.0))
		var nearest_h := float(res["nearest"][4]) if not (res["nearest"] as Array).is_empty() else 0.0
		var tallest_h := float(res["tallest"][4]) if not (res["tallest"] as Array).is_empty() else 0.0
		var main: Array = res["largest"] if not (res["largest"] as Array).is_empty() else res["nearest"]
		var roof_h := float(main[5]) if not main.is_empty() else 0.0
		var pitch := float(main[6]) if not main.is_empty() else 0.0
		var shape := str(main[8]) if not main.is_empty() else "-"
		var storeys := int(main[9]) if not main.is_empty() else 0
		var area := float(main[3]) if not main.is_empty() else 0.0
		var cnt := int(res["count"])
		print("HEIGHTS %s\t%.1f\t%.1f\t%.0f\t%.1f\t%+.1f\t%.1f\t%.0f\t%s\t%d\t%.0f\t%d" % [
			entry["type"], model, nearest_h, float(res["nearest_d"]), tallest_h,
			model - tallest_h if cnt > 0 else 0.0, roof_h, pitch, shape, storeys, area, cnt
		])
		# Print sub-buildings for multi-building sites
		var hits: Array = res["hits"]
		for i in range(mini(hits.size(), 6)):
			var hd: float = float(hits[i][0])
			var r: Array = hits[i][1]
			if float(r[3]) >= 120.0:
				print("  SUB %s[%d]\td=%.0fm\t%s\tprt=%s\taz=%.0f" % [
					entry["type"], i, hd, _fmt_row(r), str(r[0]), float(r[7])
				])

	print("")
	print("PLANNED type\tname\tnearest_m\tnearest_d\ttallest_m\troof_h\tpitch\tshape\tstoreys\tarea_m2\tcount")
	for p in PLANNED:
		var res := _query_site(float(p[2]), float(p[3]), float(p[4]))
		var nearest_h := float(res["nearest"][4]) if not (res["nearest"] as Array).is_empty() else 0.0
		var tallest_h := float(res["tallest"][4]) if not (res["tallest"] as Array).is_empty() else 0.0
		var main: Array = res["largest"] if not (res["largest"] as Array).is_empty() else res["nearest"]
		var roof_h := float(main[5]) if not main.is_empty() else 0.0
		var pitch := float(main[6]) if not main.is_empty() else 0.0
		var shape := str(main[8]) if not main.is_empty() else "-"
		var storeys := int(main[9]) if not main.is_empty() else 0
		var area := float(main[3]) if not main.is_empty() else 0.0
		print("PLANNED %s\t%s\t%.1f\t%.0f\t%.1f\t%.1f\t%.0f\t%s\t%d\t%.0f\t%d" % [
			p[0], p[1], nearest_h, float(res["nearest_d"]), tallest_h,
			roof_h, pitch, shape, storeys, area, int(res["count"])
		])
	quit(0)
