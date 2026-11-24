class_name PaTowerSpecs
extends RefCounted

## Paris skyline towers (`PA-5`) through the `skyline: true` `TowerSpec` channel
## (12 / 30 / 60 / 110 skyline slots per preset, independent of icon & bridge slots).
## Covers Tour Montparnasse, the Front de Seine 1970s cluster (15e), and the
## La Défense CBD skyline (west along the Axe Historique).
## Sources: `docs/paris-landmark-sources.md` §4 & decoded `paris_far.osmb`.

static var _rows: Array = []
static var _by_type: Dictionary = {}

static func _row(type: String, name: String, lat: float, lon: float, height: float, yaw: float,
		clear: float, radius: float, wiki: String, priority: int, aliases: Array, spec: Dictionary) -> Dictionary:
	return {
		"type": type, "name": name, "lat": lat, "lon": lon,
		"radius_m": radius, "wiki_title": wiki, "height_m": height,
		"clear_m": clear, "yaw_deg": yaw, "kind": "Skyscraper",
		"skyline": true, "skyline_priority": priority,
		"aliases": aliases, "tower_spec": spec,
	}

static func entries() -> Array:
	if not _rows.is_empty():
		return _rows
	_rows = [
		# --- Tour Montparnasse (3.3 km SE on Eiffel axis) ---
		_row("tour_montparnasse", "Tour Montparnasse", 48.84209, 2.32193, 210.0, 29.0, 34.0, 9000.0,
			"Tour Montparnasse", 5, ["tour montparnasse", "montparnasse tower"], {
				"finish": "intl_bronze", "bay": 2.4, "floor": 3.55, "trim": "#3B3530", "rib": 3.0,
				"mats": {"RoofDeck": ["paint", "#48443F", 0.55, 0.45]},
				"ops": [
					["shape", "chamfer", 0.0, 12.0, 62.0, 38.0, 10.0],
					["shape", "chamfer", 12.0, 202.0, 58.0, 34.0, 11.0],
					["louvre", 202.0, 208.0, 52.0, 28.0],
					["box", "RoofDeck", 0.0, 208.0, 0.0, 30.0, 2.0, 18.0],
				]}),

		_row("pullman_montparnasse", "Pullman Paris Montparnasse", 48.83841, 2.32090, 116.0, 29.0, 28.0, 7500.0,
			"Pullman Paris Montparnasse Hotel", 2, ["pullman montparnasse", "pullman paris montparnasse"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.4, "trim": "#B8B2A8",
				"ops": [
					["tier", 0.0, 18.0, 62.0, 42.0],
					["tier", 18.0, 110.0, 52.0, 24.0],
					["louvre", 110.0, 116.0, 40.0, 18.0],
				]}),

		# --- Front de Seine 1970s Cluster (1.19–1.75 km SSW of Trocadéro) ---
		_row("tour_totem", "Tour Totem", 48.84905, 2.28305, 98.0, 42.0, 20.0, 5500.0,
			"Tour Totem", 3, ["tour totem", "totem front de seine"], {
				"finish": "warm_concrete", "bay": 2.6, "floor": 3.1, "trim": "#CFCBC2",
				"ops": [
					["tier", 0.0, 18.0, 20.0, 20.0],
					["tier", 18.0, 46.0, 32.0, 24.0],
					["tier", 46.0, 74.0, 34.0, 26.0],
					["tier", 74.0, 94.0, 28.0, 22.0],
					["louvre", 94.0, 98.0, 22.0, 16.0],
				]}),

		_row("tour_cristal", "Tour Cristal", 48.84852, 2.28148, 98.0, 42.0, 20.0, 5500.0,
			"Tour Cristal", 3, ["tour cristal", "tour cristal paris"], {
				"finish": "lowe_blue", "bay": 2.8, "floor": 3.3, "trim": "#8C9CA8",
				"ops": [
					["shape", "chamfer", 0.0, 92.0, 38.0, 26.0, 5.0],
					["louvre", 92.0, 98.0, 30.0, 18.0],
				]}),

		_row("novotel_tour_eiffel", "Hôtel Novotel Paris Tour Eiffel", 48.84968, 2.28369, 98.0, 42.0, 22.0, 5500.0,
			"Front de Seine", 3, ["novotel paris tour eiffel", "novotel tour eiffel"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.0, "trim": "#D0CCC4",
				"ops": [
					["tier", 0.0, 14.0, 44.0, 28.0],
					["tier", 14.0, 93.0, 40.0, 22.0],
					["louvre", 93.0, 98.0, 32.0, 16.0],
				]}),

		_row("adagio_tour_eiffel", "Adagio Paris Tour Eiffel", 48.84979, 2.28526, 98.0, 42.0, 20.0, 5500.0,
			"Front de Seine", 2, ["adagio paris tour eiffel", "tour avant-seine"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.0, "trim": "#B6BCC2",
				"ops": [
					["tier", 0.0, 93.0, 34.0, 24.0],
					["louvre", 93.0, 98.0, 26.0, 18.0],
				]}),

		_row("tour_seine", "Tour Seine", 48.85166, 2.28585, 98.0, 42.0, 20.0, 5500.0,
			"Front de Seine", 2, ["tour seine", "tour seine paris"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.0, "trim": "#CBC6BC",
				"ops": [
					["tier", 0.0, 93.0, 34.0, 24.0],
					["louvre", 93.0, 98.0, 26.0, 18.0],
				]}),

		_row("tour_panorama", "Tour Panorama", 48.84845, 2.28450, 98.0, 42.0, 20.0, 5500.0,
			"Front de Seine", 2, ["tour panorama", "tour panorama paris"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 2.95, "trim": "#C2C6CA",
				"ops": [
					["tier", 0.0, 93.0, 32.0, 24.0],
					["louvre", 93.0, 98.0, 24.0, 18.0],
				]}),

		_row("tour_beaugrenelle", "Tour Beaugrenelle", 48.84786, 2.28318, 98.0, 42.0, 20.0, 5500.0,
			"Front de Seine", 2, ["tour beaugrenelle"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.0, "trim": "#C8C3B9",
				"ops": [
					["tier", 0.0, 93.0, 34.0, 24.0],
					["louvre", 93.0, 98.0, 26.0, 18.0],
				]}),

		_row("tour_keller", "Tour Keller", 48.84782, 2.28176, 98.0, 42.0, 22.0, 5500.0,
			"Front de Seine", 2, ["tour keller"], {
				"finish": "intl_bronze", "bay": 2.8, "floor": 3.0, "trim": "#8A847C",
				"ops": [
					["tier", 0.0, 93.0, 38.0, 24.0],
					["louvre", 93.0, 98.0, 28.0, 18.0],
				]}),

		_row("tour_mars", "Tour Mars", 48.85050, 2.28480, 98.0, 42.0, 19.0, 5500.0,
			"Front de Seine", 2, ["tour mars paris", "tour mars"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.0, "trim": "#D2CEC6",
				"ops": [
					["tier", 0.0, 93.0, 32.0, 22.0],
					["louvre", 93.0, 98.0, 24.0, 16.0],
				]}),

		_row("tour_evasion_2000", "Tour Évasion 2000", 48.85095, 2.28620, 98.0, 42.0, 19.0, 5500.0,
			"Front de Seine", 2, ["tour evasion 2000", "tour évasion 2000"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.0, "trim": "#BFC4CA",
				"ops": [
					["tier", 0.0, 93.0, 32.0, 22.0],
					["louvre", 93.0, 98.0, 24.0, 16.0],
				]}),

		# --- La Défense CBD Skyline (4.0–5.4 km NW along Axe Historique) ---
		_row("tour_the_link", "Tour The Link", 48.88727, 2.24790, 241.0, 26.0, 34.0, 9500.0,
			"The Link (skyscraper)", 5, ["tour the link", "the link la defense", "the link paris"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.2, "trim": "#CBD2D8",
				"ops": [
					["tier", 0.0, 28.0, 54.0, 34.0],
					["tier", 28.0, 178.0, 24.0, 26.0, -14.0, 0.0],
					["tier", 28.0, 232.0, 26.0, 28.0, 14.0, 0.0],
					["box", "Trim", 0.0, 90.0, 0.0, 12.0, 8.0, 18.0],
					["box", "Trim", 0.0, 152.0, 0.0, 12.0, 8.0, 18.0],
					["louvre", 232.0, 241.0, 22.0, 24.0],
				]}),

		_row("tour_first", "Tour First", 48.88877, 2.25161, 231.0, 28.0, 30.0, 9500.0,
			"Tour First", 5, ["tour first", "tour first la defense", "tour axa"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.9, "trim": "#C6CFD8",
				"mats": {"Spire": ["paint", "#D4DCE4", 0.3, 0.8]},
				"ops": [
					["shape", "tri", 0.0, 120.0, 52.0, 52.0, 4.0, 48.0, 48.0],
					["shape", "tri", 120.0, 186.0, 48.0, 48.0, 4.0, 36.0, 36.0],
					["shape", "tri", 186.0, 210.0, 36.0, 36.0, 3.0, 24.0, 24.0],
					["spire", "Spire", 206.0, 1.4, 25.0, 0.15, 6],
				]}),

		_row("tour_hekla", "Tour Hekla", 48.88900, 2.23508, 220.0, 24.0, 28.0, 9500.0,
			"Tour Hekla", 4, ["tour hekla", "hekla la defense"], {
				"finish": "intl_bronze", "bay": 2.8, "floor": 4.1, "trim": "#B58D64", "rib": 3.4,
				"ops": [
					["shape", "chamfer", 0.0, 182.0, 46.0, 34.0, 7.0, 42.0, 30.0],
					["slope", 182.0, 220.0, 42.0, 30.0],
				]}),

		_row("tour_majunga", "Tour Majunga", 48.88885, 2.24363, 194.0, 26.0, 26.0, 9000.0,
			"Tour Majunga", 4, ["tour majunga", "majunga la defense"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 4.0, "trim": "#D6D8DC", "rib": 4.0,
				"ops": [
					["tier", 0.0, 26.0, 44.0, 36.0],
					["shape", "chamfer", 26.0, 184.0, 40.0, 32.0, 4.0],
					["louvre", 184.0, 194.0, 34.0, 26.0],
				]}),

		_row("tour_total_coupole", "Tour Total (Coupole)", 48.89290, 2.24280, 190.0, 26.0, 28.0, 9000.0,
			"Tour Total", 4, ["tour total", "tour coupole", "tour totalenergies"], {
				"finish": "lowe_blue", "bay": 2.8, "floor": 3.85, "trim": "#8FA2B2",
				"ops": [
					["shape", "hex", 0.0, 128.0, 52.0, 44.0, 0.0],
					["shape", "hex", 128.0, 162.0, 42.0, 36.0, 0.0],
					["shape", "hex", 162.0, 184.0, 32.0, 28.0, 0.0],
					["louvre", 184.0, 190.0, 24.0, 22.0],
				]}),

		_row("tour_areva", "Tour Areva (Tour Engie)", 48.89252, 2.24198, 184.0, 26.0, 26.0, 9000.0,
			"Tour Areva", 3, ["tour areva", "tour framatome", "tour engie"], {
				"finish": "intl_bronze", "bay": 2.8, "floor": 4.0, "trim": "#2D3035",
				"ops": [
					["tier", 0.0, 178.0, 46.0, 46.0],
					["louvre", 178.0, 184.0, 40.0, 40.0],
				]}),

		_row("tour_granite", "Tour Granite", 48.89167, 2.22980, 184.0, 24.0, 26.0, 9000.0,
			"Tour Granite", 3, ["tour granite", "societe generale granite"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 4.1, "trim": "#B8C4CE",
				"ops": [
					["shape", "tri", 0.0, 154.0, 48.0, 48.0, 3.0, 40.0, 40.0],
					["slope", 154.0, 184.0, 38.0, 36.0],
				]}),

		_row("tour_cb21", "Tour CB21", 48.88890, 2.24986, 179.0, 26.0, 26.0, 9000.0,
			"Tour CB21", 3, ["tour cb21", "tour gan"], {
				"finish": "lowe_blue", "bay": 2.8, "floor": 3.9, "trim": "#B0BCC6",
				"ops": [
					["notch", 0.0, 172.0, 44.0, 44.0, 10.0],
					["louvre", 172.0, 179.0, 30.0, 30.0],
				]}),

		_row("tour_saint_gobain", "Tour Saint-Gobain", 48.88972, 2.24929, 178.0, 26.0, 26.0, 9000.0,
			"Tour Saint-Gobain", 3, ["tour saint-gobain", "tour saint gobain", "tour m2"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.0, "trim": "#D6DCE0",
				"ops": [
					["tier", 0.0, 62.0, 44.0, 34.0],
					["tier", 62.0, 124.0, 40.0, 32.0, 3.0, 0.0],
					["tier", 124.0, 166.0, 36.0, 30.0, -2.0, 0.0],
					["slope", 166.0, 178.0, 34.0, 28.0],
				]}),

		_row("tour_d2", "Tour D2", 48.89050, 2.24797, 175.0, 26.0, 24.0, 9000.0,
			"Tour D2", 4, ["tour d2", "tour d2 la defense"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 4.0, "trim": "#C8D0D8",
				"mats": {"Steel": ["paint", "#D4D8DC", 0.32, 0.78]},
				"ops": [
					["shape", "ellipse", 0.0, 168.0, 46.0, 32.0, 0.0, 40.0, 28.0],
					["diagrid", "Steel", 8.0, 168.0, 42.0, 30.0, 18.0, 3],
					["dome", "Steel", 168.0, 13.0, 7.0],
				]}),

		_row("tour_carpe_diem", "Tour Carpe Diem", 48.89145, 2.24563, 166.0, 26.0, 24.0, 9000.0,
			"Tour Carpe Diem", 3, ["tour carpe diem", "carpe diem la defense"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 4.0, "trim": "#D0D6DC",
				"ops": [
					["shape", "chamfer", 0.0, 146.0, 42.0, 34.0, 6.0, 38.0, 30.0],
					["slope", 146.0, 166.0, 38.0, 30.0],
				]}),

		_row("tour_legende", "Tour Légende", 48.88978, 2.24153, 165.0, 26.0, 24.0, 9000.0,
			"Tour Légende", 2, ["tour legende", "tour légende", "tour edf"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.9, "trim": "#BFC7CE",
				"ops": [
					["shape", "ellipse", 0.0, 158.0, 46.0, 30.0],
					["louvre", 158.0, 165.0, 34.0, 22.0],
				]}),

		# Fixes OSM relation 3071676 `height=1.0` bug!
		_row("coeur_defense", "Cœur Défense", 48.89060, 2.24420, 161.0, 26.0, 32.0, 9000.0,
			"Cœur Défense", 4, ["coeur defense", "cœur défense", "coeur défense"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 3.9, "trim": "#CFD5DA",
				"ops": [
					["tier", 0.0, 22.0, 68.0, 44.0],
					["shape", "round", 22.0, 155.0, 28.0, 36.0, 6.0, 28.0, 36.0, -17.0, 0.0],
					["shape", "round", 22.0, 155.0, 28.0, 36.0, 6.0, 28.0, 36.0, 17.0, 0.0],
					["louvre", 155.0, 161.0, 22.0, 28.0],
				]}),

		_row("tour_alto", "Tour Alto", 48.88938, 2.25116, 160.0, 26.0, 24.0, 9000.0,
			"Tour Alto", 4, ["tour alto", "alto la defense"], {
				"finish": "clear_fin", "bay": 2.6, "floor": 4.0, "trim": "#D2DAE0",
				"ops": [
					["shape", "ellipse", 0.0, 56.0, 28.0, 24.0, 0.0, 36.0, 30.0],
					["shape", "ellipse", 56.0, 150.0, 36.0, 30.0, 0.0, 46.0, 36.0],
					["louvre", 150.0, 160.0, 38.0, 28.0],
				]}),

		# Fixes OSM way 82486351 missing height (`lv=40`)!
		_row("tour_egee", "Tour Égée", 48.89519, 2.23817, 155.0, 26.0, 24.0, 8500.0,
			"Tour Égée", 2, ["tour egee", "tour égée"], {
				"finish": "lowe_blue", "bay": 2.8, "floor": 3.8, "trim": "#B8C4CC",
				"ops": [
					["shape", "chamfer", 0.0, 148.0, 40.0, 36.0, 5.0],
					["louvre", 148.0, 155.0, 30.0, 26.0],
				]}),

		_row("tour_ariane", "Tour Ariane", 48.88939, 2.24363, 152.0, 26.0, 22.0, 8500.0,
			"Tour Ariane", 2, ["tour ariane"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.65, "trim": "#D2CEC4",
				"ops": [
					["tier", 0.0, 146.0, 40.0, 34.0],
					["louvre", 146.0, 152.0, 32.0, 26.0],
				]}),

		_row("tour_trinity", "Tour Trinity", 48.89288, 2.24111, 151.0, 26.0, 24.0, 8500.0,
			"Tour Trinity", 3, ["tour trinity", "trinity la defense"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 4.2, "trim": "#D4DCE2",
				"ops": [
					["tier", 0.0, 74.0, 48.0, 26.0],
					["tier", 74.0, 145.0, 44.0, 24.0, 4.0, 0.0],
					["louvre", 145.0, 151.0, 34.0, 18.0],
				]}),

		_row("tour_les_poissons", "Tour Les Poissons", 48.89458, 2.25166, 150.0, 26.0, 22.0, 8500.0,
			"Tour Les Poissons", 2, ["tour les poissons", "tour ciel"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 3.4, "trim": "#CFCBC4",
				"ops": [
					["tier", 0.0, 128.0, 40.0, 30.0],
					["louvre", 128.0, 150.0, 18.0, 18.0],
				]}),

		_row("tour_dexia", "Tour CBX (Dexia)", 48.89115, 2.24660, 142.0, 26.0, 22.0, 8500.0,
			"Tour CBX", 2, ["tour cbx", "tour dexia"], {
				"finish": "lowe_blue", "bay": 2.8, "floor": 3.8, "trim": "#A8B8C4",
				"ops": [
					["shape", "round", 0.0, 134.0, 42.0, 30.0, 6.0],
					["slope", 134.0, 142.0, 38.0, 26.0],
				]}),

		_row("tour_europlaza", "Tour Europlaza", 48.89162, 2.24513, 135.0, 26.0, 22.0, 8000.0,
			"Tour Europlaza", 2, ["tour europlaza", "europlaza la defense"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 4.0, "trim": "#C2CAD0",
				"ops": [
					["tier", 0.0, 129.0, 44.0, 34.0],
					["louvre", 129.0, 135.0, 34.0, 26.0],
				]}),

		_row("tour_defense_2000", "Tour Défense 2000", 48.88751, 2.23667, 134.0, 26.0, 22.0, 8000.0,
			"Tour Défense 2000", 2, ["tour defense 2000", "tour défense 2000"], {
				"finish": "warm_concrete", "bay": 2.6, "floor": 2.85, "trim": "#D6D0C6",
				"ops": [
					["shape", "chamfer", 0.0, 128.0, 36.0, 36.0, 6.0],
					["louvre", 128.0, 134.0, 24.0, 24.0],
				]}),

		_row("tour_eqho", "Tour Eqho", 48.89120, 2.24850, 131.0, 26.0, 22.0, 8000.0,
			"Tour Eqho", 2, ["tour eqho", "tour descartes"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.8, "trim": "#C8D0D6",
				"ops": [
					["shape", "round", 0.0, 125.0, 42.0, 32.0, 6.0],
					["louvre", 125.0, 131.0, 32.0, 24.0],
				]}),

		_row("tour_franklin", "Tour Franklin", 48.88905, 2.24047, 120.0, 26.0, 22.0, 8000.0,
			"Tour Franklin", 2, ["tour franklin"], {
				"finish": "intl_bronze", "bay": 2.8, "floor": 3.55, "trim": "#706A64",
				"ops": [
					["tier", 0.0, 114.0, 42.0, 30.0],
					["louvre", 114.0, 120.0, 32.0, 22.0],
				]}),

		_row("tour_sequoia", "Tour Séquoia", 48.89412, 2.24023, 119.0, 26.0, 22.0, 8000.0,
			"Tour Séquoia", 2, ["tour sequoia", "tour séquoia"], {
				"finish": "lowe_blue", "bay": 2.8, "floor": 3.6, "trim": "#9AA8B4",
				"ops": [
					["tier", 0.0, 113.0, 44.0, 34.0],
					["louvre", 113.0, 119.0, 34.0, 26.0],
				]}),

		_row("tour_manhattan", "Tour Manhattan", 48.88986, 2.24844, 110.0, 26.0, 22.0, 8000.0,
			"Tour Manhattan", 2, ["tour manhattan", "tour manhattan paris"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.8, "trim": "#C4CCD4",
				"ops": [
					["shape", "round", 0.0, 104.0, 46.0, 28.0, 8.0],
					["louvre", 104.0, 110.0, 36.0, 20.0],
				]}),
	]
	for r in _rows:
		var d := r as Dictionary
		_by_type[str(d["type"])] = d["tower_spec"]
	return _rows

static func spec_for(type: String) -> Dictionary:
	if _by_type.is_empty():
		entries()
	return _by_type.get(type, {})
