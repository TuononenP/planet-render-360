class_name SgTowerSpecs
extends RefCounted

## Singapore skyline towers (`PLAN_Singapore_super_realistic.md`, SG-3C) through the
## independent `skyline: true` `TowerSpec` channel (12 / 30 / 60 / 110 slots per preset).
## Covers Raffles Place, Marina Bay Financial District, Tanjong Pagar, Shenton Way,
## Marina Centre, Beach Road, and River Valley, fixing all OSM `height=0` & under-height
## anomalies documented in `docs/singapore-landmark-sources.md` §4.

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
		# --- Raffles Place Waterfront Wall ---
		_row("uob_plaza_one_sg", "UOB Plaza One", 1.28548, 103.85021, 280.0, -49.9, 24.0, 6000.0,
			"UOB Plaza", 5, ["uob plaza one", "uob plaza"], {
				"finish": "white_granite", "bay": 3.0, "floor": 4.2, "trim": "#D6D2C8",
				"walls": {"Glass": ["lowe_blue", 3.0, 4.2]},
				"ops": [
					["tier", 0.0, 28.0, 44.0, 44.0],
					["shape", "chamfer", 28.0, 195.0, 42.0, 42.0, 8.0, 40.0, 40.0],
					["use", "Glass"],
					["shape", "chamfer", 195.0, 256.0, 34.0, 34.0, 7.0, 30.0, 30.0],
					["louvre", 256.0, 280.0, 26.0, 26.0],
				]}),
		_row("uob_plaza_two_sg", "UOB Plaza Two", 1.28543, 103.85117, 162.0, -88.8, 20.0, 5000.0,
			"UOB Plaza", 2, ["uob plaza two"], {
				"finish": "white_granite", "bay": 3.0, "floor": 4.0, "trim": "#D2CEC4",
				"ops": [
					["tier", 0.0, 20.0, 36.0, 34.0],
					["shape", "chamfer", 20.0, 152.0, 34.0, 32.0, 5.0, 34.0, 32.0],
					["louvre", 152.0, 162.0, 26.0, 24.0],
				]}),
		_row("republic_plaza_sg", "Republic Plaza", 1.28290, 103.85110, 280.0, -25.0, 24.0, 6000.0,
			"Republic Plaza (Singapore)", 5, ["republic plaza", "republic plaza singapore"], {
				"finish": "pink_granite", "bay": 3.0, "floor": 4.2, "trim": "#C8B8A8",
				"ops": [
					["tier", 0.0, 36.0, 44.0, 44.0],
					["shape", "chamfer", 36.0, 180.0, 40.0, 40.0, 7.0, 36.0, 36.0],
					["shape", "chamfer", 180.0, 262.0, 34.0, 34.0, 8.0, 26.0, 26.0],
					["pyramid", "Slope", 262.0, 24.0, 24.0, 18.0, 0.35],
				]}),
		_row("capitaspring_sg", "CapitaSpring", 1.28390, 103.85010, 280.0, -25.0, 24.0, 6000.0,
			"CapitaSpring", 5, ["capitaspring"], {
				"finish": "intl_bronze", "bay": 2.8, "floor": 4.4, "trim": "#6B5E52", "rib": 3.2,
				"mats": {"Oasis": ["forest", "#2F6B36", 3.0], "Core": ["glass", "#3A5A6C"]},
				"ops": [
					["tier", 0.0, 82.0, 42.0, 38.0],
					["gap", 82.0, 106.0, 36.0, 32.0],
					["box", "Oasis", 0.0, 83.0, 0.0, 40.0, 20.0, 36.0],
					["tier", 106.0, 268.0, 42.0, 38.0],
					["box", "Oasis", 0.0, 268.0, 0.0, 36.0, 5.0, 32.0],
					["louvre", 268.0, 280.0, 34.0, 30.0],
				]}),
		_row("one_raffles_place_1_sg", "One Raffles Place Tower 1", 1.28471, 103.85108, 280.0, 15.0, 22.0, 6000.0,
			"One Raffles Place", 5, ["one raffles place", "oub centre", "one raffles place tower 1"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 4.2, "trim": "#CFD6DC",
				"ops": [
					["shape", "tri", 0.0, 215.0, 46.0, 42.0, 2.0, 44.0, 40.0],
					["shape", "tri", 215.0, 272.0, 34.0, 32.0, 2.0, 30.0, 28.0],
					["louvre", 272.0, 280.0, 22.0, 20.0],
				]}),
		_row("one_raffles_place_2_sg", "One Raffles Place Tower 2", 1.28476, 103.85079, 209.0, 15.0, 20.0, 5500.0,
			"One Raffles Place", 3, ["one raffles place tower 2"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.4, "trim": "#B8C4CC",
				"ops": [
					["shape", "chamfer", 0.0, 179.0, 42.0, 36.0, 6.0, 40.0, 34.0],
					["shape", "chamfer", 179.0, 209.0, 38.0, 32.0, 6.0, 32.0, 26.0],
				]}),
		_row("ocbc_centre_sg", "OCBC Centre", 1.28526, 103.84932, 198.0, 26.0, 24.0, 5500.0,
			"OCBC Centre", 4, ["ocbc centre", "the calculator singapore"], {
				"finish": "warm_concrete", "bay": 3.2, "floor": 3.8, "trim": "#B8AE9E",
				"mats": {"Core": ["concrete", "#BEB5A6", 3.0]},
				"ops": [
					["box", "Core", -22.0, 0.0, 0.0, 12.0, 198.0, 16.0],
					["box", "Core", 22.0, 0.0, 0.0, 12.0, 198.0, 16.0],
					["tier", 14.0, 72.0, 42.0, 22.0],
					["gap", 72.0, 82.0, 34.0, 18.0],
					["tier", 82.0, 134.0, 42.0, 22.0],
					["gap", 134.0, 144.0, 34.0, 18.0],
					["tier", 144.0, 194.0, 42.0, 22.0],
				]}),
		_row("ocean_financial_centre_sg", "Ocean Financial Centre", 1.28323, 103.85206, 245.0, -70.0, 26.0, 6000.0,
			"Ocean Financial Centre", 4, ["ocean financial centre"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 4.4, "trim": "#9CB8C8",
				"ops": [
					["tier", 0.0, 22.0, 58.0, 38.0],
					["shape", "ellipse", 22.0, 230.0, 56.0, 34.0, 0.0, 52.0, 30.0],
					["slope", 230.0, 245.0, 48.0, 26.0],
				]}),
		_row("capitagreen_sg", "CapitaGreen", 1.28185, 103.85013, 242.0, -65.0, 24.0, 6000.0,
			"CapitaGreen", 4, ["capitagreen"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.4, "trim": "#78947A", "rib": 3.6,
				"mats": {"Green": ["forest", "#3B7A40", 3.0], "Funnel": ["paint", "#D84232", 0.35, 0.25]},
				"ops": [
					["tier", 0.0, 220.0, 44.0, 40.0],
					["box", "Green", 0.0, 18.0, 0.0, 44.8, 196.0, 40.8],
					["box", "Funnel", 0.0, 220.0, 0.0, 26.0, 22.0, 22.0],
				]}),
		_row("six_battery_road_sg", "Six Battery Road", 1.28540, 103.85181, 174.0, -31.5, 20.0, 5000.0,
			"Six Battery Road", 3, ["six battery road", "6 battery road"], {
				"finish": "red_granite", "bay": 3.0, "floor": 4.0, "trim": "#8A5E4E",
				"ops": [
					["tier", 0.0, 166.0, 38.0, 34.0],
					["louvre", 166.0, 174.0, 32.0, 28.0],
				]}),
		_row("maybank_tower_sg", "Maybank Tower", 1.28584, 103.85255, 175.0, 68.0, 18.0, 5000.0,
			"Maybank Tower (Singapore)", 3, ["maybank tower", "maybank singapore"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.2, "trim": "#D0D4D8",
				"ops": [
					["shape", "chamfer", 0.0, 145.0, 36.0, 24.0, 4.0, 34.0, 22.0],
					["shape", "chamfer", 145.0, 175.0, 30.0, 20.0, 4.0, 22.0, 16.0],
				]}),
		_row("bank_of_china_sg", "Bank of China Building", 1.28569, 103.85228, 168.0, 56.0, 18.0, 5000.0,
			"Bank of China Building, Singapore", 3, ["bank of china singapore", "boc singapore"], {
				"finish": "limestone_pier", "bay": 3.0, "floor": 4.0, "trim": "#D6CEC0",
				"ops": [
					["tier", 0.0, 74.0, 38.0, 34.0],
					["tier", 74.0, 160.0, 30.0, 26.0, -3.0, 0.0],
					["louvre", 160.0, 168.0, 24.0, 22.0],
				]}),
		_row("one_george_street_sg", "One George Street", 1.28580, 103.84776, 153.0, -64.0, 22.0, 4500.0,
			"One George Street", 2, ["one george street"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.4, "trim": "#B0BCC4",
				"ops": [
					["tier", 0.0, 76.0, 46.0, 36.0],
					["gap", 76.0, 84.0, 40.0, 30.0],
					["tier", 84.0, 153.0, 44.0, 34.0],
				]}),

		# --- Marina Bay Financial District ---
		_row("mbfc_tower_1_sg", "Marina Bay Financial Centre Tower 1", 1.28025, 103.85418, 192.0, 75.0, 22.0, 6000.0,
			"Marina Bay Financial Centre", 4, ["mbfc tower 1", "marina bay financial centre tower 1"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 4.4, "trim": "#9CB4C4",
				"ops": [
					["tier", 0.0, 184.0, 44.0, 40.0],
					["louvre", 184.0, 192.0, 38.0, 34.0],
				]}),
		_row("mbfc_tower_2_sg", "Marina Bay Financial Centre Tower 2", 1.27955, 103.85389, 239.0, 27.0, 22.0, 6000.0,
			"Marina Bay Financial Centre", 4, ["mbfc tower 2", "marina bay financial centre tower 2"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 4.4, "trim": "#98B2C4",
				"ops": [
					["tier", 0.0, 230.0, 46.0, 38.0],
					["louvre", 230.0, 239.0, 40.0, 32.0],
				]}),
		_row("mbfc_tower_3_sg", "Marina Bay Financial Centre Tower 3", 1.27895, 103.85443, 245.0, 27.0, 24.0, 6000.0,
			"Marina Bay Financial Centre", 4, ["mbfc tower 3", "marina bay financial centre tower 3"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.4, "trim": "#A4BCC8",
				"ops": [
					["tier", 0.0, 236.0, 48.0, 42.0],
					["louvre", 236.0, 245.0, 42.0, 36.0],
				]}),
		_row("the_sail_t1_sg", "The Sail @ Marina Bay (Marina Bay Tower)", 1.28120, 103.85295, 245.0, -65.0, 22.0, 6000.0,
			"The Sail @ Marina Bay", 5, ["the sail", "the sail at marina bay", "the sail singapore"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.5, "trim": "#C2D0D8",
				"ops": [
					["shape", "ellipse", 0.0, 225.0, 46.0, 24.0, 0.0, 40.0, 20.0],
					["slope", 225.0, 245.0, 36.0, 18.0],
				]}),
		_row("the_sail_t2_sg", "The Sail @ Marina Bay (Central Park Tower)", 1.28090, 103.85235, 215.0, -65.0, 20.0, 6000.0,
			"The Sail @ Marina Bay", 4, ["the sail tower 2"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.5, "trim": "#C2D0D8",
				"ops": [
					["shape", "ellipse", 0.0, 198.0, 42.0, 22.0, 0.0, 36.0, 18.0],
					["slope", 198.0, 215.0, 32.0, 16.0],
				]}),
		_row("marina_bay_residences_sg", "Marina Bay Residences", 1.27966, 103.85521, 227.0, 27.0, 20.0, 5500.0,
			"Marina Bay Financial Centre", 3, ["marina bay residences"], {
				"finish": "balcony_aqua", "bay": 3.0, "floor": 3.8, "trim": "#D4DCE0",
				"ops": [
					["tier", 0.0, 220.0, 40.0, 34.0],
					["louvre", 220.0, 227.0, 34.0, 28.0],
				]}),
		_row("marina_bay_suites_sg", "Marina Bay Suites", 1.28023, 103.85231, 239.0, 27.0, 22.0, 5500.0,
			"Marina Bay Financial Centre", 3, ["marina bay suites"], {
				"finish": "balcony_white", "bay": 3.0, "floor": 3.6, "trim": "#E2E0DA",
				"ops": [
					["tier", 0.0, 232.0, 42.0, 36.0],
					["louvre", 232.0, 239.0, 36.0, 30.0],
				]}),
		_row("one_raffles_quay_n_sg", "One Raffles Quay North Tower", 1.28147, 103.85206, 245.0, -65.0, 22.0, 6000.0,
			"One Raffles Quay", 4, ["one raffles quay", "one raffles quay north"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 4.4, "trim": "#8FAEC2",
				"ops": [
					["tier", 0.0, 237.0, 44.0, 40.0],
					["louvre", 237.0, 245.0, 38.0, 34.0],
				]}),
		_row("marina_one_sg", "Marina One", 1.27700, 103.85343, 141.0, 27.0, 36.0, 5500.0,
			"Marina One", 4, ["marina one", "marina one singapore"], {
				"finish": "intl_bronze", "bay": 3.0, "floor": 4.0, "trim": "#7A6A58", "rib": 3.2,
				"mats": {"GreenHeart": ["forest", "#2D6B35", 3.0]},
				"ops": [
					["tier", 0.0, 141.0, 44.0, 36.0, -34.0, 0.0],
					["tier", 0.0, 141.0, 44.0, 36.0, 34.0, 0.0],
					["box", "GreenHeart", 0.0, 12.0, 0.0, 28.0, 96.0, 28.0],
				]}),
		_row("asia_square_1_sg", "Asia Square Tower 1", 1.27904, 103.85134, 229.0, 50.0, 24.0, 5500.0,
			"Asia Square", 3, ["asia square", "asia square tower 1"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.5, "trim": "#C8D0D6",
				"ops": [
					["tier", 0.0, 218.0, 54.0, 46.0],
					["louvre", 218.0, 229.0, 48.0, 40.0],
				]}),
		_row("ioi_central_boulevard_sg", "IOI Central Boulevard Towers", 1.27977, 103.85155, 230.0, 33.0, 28.0, 5500.0,
			"IOI Central Boulevard Towers", 3, ["ioi central boulevard", "ioi central boulevard towers"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.4, "trim": "#8FA0AE",
				"mats": {"Garden": ["forest", "#34723A", 3.0]},
				"ops": [
					["tier", 0.0, 32.0, 88.0, 48.0],
					["box", "Garden", 0.0, 32.0, 0.0, 82.0, 4.0, 42.0],
					["tier", 32.0, 230.0, 42.0, 38.0, -22.0, 0.0],
					["tier", 32.0, 155.0, 38.0, 36.0, 24.0, 0.0],
				]}),

		# --- Tanjong Pagar & Shenton Way ---
		_row("guoco_tower_sg", "Guoco Tower (Tanjong Pagar Centre)", 1.27707, 103.84565, 283.7, -65.0, 26.0, 6500.0,
			"Guoco Tower", 5, ["guoco tower", "tanjong pagar centre", "wallich residence"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.3, "trim": "#C4CCD4",
				"ops": [
					["tier", 0.0, 165.0, 48.0, 38.0],
					["tier", 165.0, 242.0, 42.0, 34.0, 3.0, 0.0],
					["shape", "chamfer", 242.0, 276.0, 36.0, 28.0, 5.0, 30.0, 24.0],
					["louvre", 276.0, 283.7, 26.0, 22.0],
				]}),
		_row("capital_tower_sg", "Capital Tower", 1.27764, 103.84759, 254.0, -65.0, 24.0, 6000.0,
			"Capital Tower, Singapore", 4, ["capital tower", "capital tower singapore"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.5, "trim": "#B8C2CA",
				"ops": [
					["tier", 0.0, 190.0, 48.0, 44.0],
					["tier", 190.0, 229.0, 42.0, 38.0],
					["gap", 229.0, 238.0, 36.0, 32.0],
					["tier", 238.0, 254.0, 38.0, 34.0],
				]}),
		_row("oasia_hotel_downtown_sg", "Oasia Hotel Downtown", 1.27588, 103.84436, 191.0, -65.0, 22.0, 5500.0,
			"Oasia Hotel Downtown", 4, ["oasia hotel downtown", "oasia downtown"], {
				"finish": "brick_punched", "bay": 3.0, "floor": 4.0, "trim": "#B84232",
				"mats": {"Mesh": ["paint", "#C24634", 0.55, 0.35], "Vines": ["forest", "#3B7A3E", 3.0]},
				"ops": [
					["tier", 0.0, 54.0, 38.0, 34.0],
					["gap", 54.0, 68.0, 30.0, 26.0],
					["box", "Vines", 0.0, 55.0, 0.0, 36.0, 11.0, 32.0],
					["tier", 68.0, 124.0, 38.0, 34.0],
					["gap", 124.0, 138.0, 30.0, 26.0],
					["box", "Vines", 0.0, 125.0, 0.0, 36.0, 11.0, 32.0],
					["tier", 138.0, 184.0, 38.0, 34.0],
					["box", "Mesh", 0.0, 184.0, 0.0, 38.0, 7.0, 34.0],
				]}),
		_row("v_on_shenton_sg", "V on Shenton (UIC Building)", 1.27815, 103.84955, 237.0, -65.0, 22.0, 5500.0,
			"V on Shenton", 3, ["v on shenton", "uic building"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.0, "trim": "#B8C4CC",
				"mats": {"Hex": ["paint", "#C6CED4", 0.4, 0.6]},
				"ops": [
					["tier", 0.0, 228.0, 44.0, 34.0],
					["diagrid", "Hex", 0.0, 228.0, 44.6, 34.6, 16.0, 4],
					["louvre", 228.0, 237.0, 38.0, 28.0],
				]}),
		_row("altez_sg", "Altez", 1.27457, 103.84434, 250.0, -65.0, 20.0, 5500.0,
			"Altez", 3, ["altez"], {
				"finish": "balcony_white", "bay": 3.0, "floor": 3.7, "trim": "#DCDCD6",
				"ops": [
					["tier", 0.0, 242.0, 34.0, 28.0],
					["louvre", 242.0, 250.0, 28.0, 22.0],
				]}),
		_row("pinnacle_at_duxton_sg", "The Pinnacle@Duxton", 1.27689, 103.84124, 156.0, 25.0, 38.0, 5500.0,
			"The Pinnacle@Duxton", 4, ["pinnacle at duxton", "the pinnacle@duxton", "pinnacle duxton"], {
				"finish": "white_panel", "bay": 3.0, "floor": 3.1, "trim": "#D8D6D0",
				"mats": {"Bridge": ["concrete", "#CFD0CC", 3.0], "SkyGarden": ["forest", "#3B7A3E", 3.0]},
				"ops": [
					["tier", 0.0, 152.0, 24.0, 22.0, -60.0, 0.0],
					["tier", 0.0, 152.0, 24.0, 22.0, -20.0, 0.0],
					["tier", 0.0, 152.0, 24.0, 22.0, 20.0, 0.0],
					["tier", 0.0, 152.0, 24.0, 22.0, 60.0, 0.0],
					["box", "Bridge", 0.0, 75.0, 0.0, 146.0, 3.2, 12.0],
					["box", "Bridge", 0.0, 152.0, 0.0, 146.0, 4.0, 14.0],
					["box", "SkyGarden", 0.0, 154.0, 0.0, 140.0, 2.0, 10.0],
				]}),
		_row("eighteen_robinson_sg", "18 Robinson", 1.28188, 103.85059, 180.0, -74.0, 18.0, 5000.0,
			"18 Robinson", 2, ["18 robinson"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.4, "trim": "#BCC6CE",
				"ops": [
					["shape", "chamfer", 0.0, 62.0, 36.0, 28.0, 6.0, 40.0, 32.0],
					["shape", "chamfer", 62.0, 168.0, 40.0, 32.0, 8.0, 34.0, 26.0],
					["slope", 168.0, 180.0, 32.0, 24.0],
				]}),
		_row("hong_leong_building_sg", "Hong Leong Building", 1.28140, 103.85092, 158.0, -65.0, 20.0, 4800.0,
			"Hong Leong Building", 2, ["hong leong building"], {
				"finish": "granite_strip", "bay": 3.0, "floor": 3.6, "trim": "#9C968E",
				"ops": [
					["tier", 0.0, 150.0, 46.0, 38.0],
					["louvre", 150.0, 158.0, 38.0, 30.0],
				]}),

		# --- Marina Centre, City Hall & Beach Road ---
		_row("swissotel_stamford_sg", "Swissôtel The Stamford", 1.29327, 103.85337, 226.0, -48.0, 24.0, 6000.0,
			"Swissôtel The Stamford", 5, ["swissotel the stamford", "swissôtel the stamford", "westin stamford"], {
				"finish": "white_panel", "bay": 2.8, "floor": 3.1, "trim": "#E2E4E6",
				"ops": [
					["shape", "ellipse", 0.0, 218.0, 44.0, 44.0, 0.0, 44.0, 44.0],
					["louvre", 218.0, 226.0, 30.0, 30.0],
				]}),
		_row("raffles_city_tower_sg", "Raffles City Tower", 1.29419, 103.85298, 158.0, -48.0, 20.0, 5000.0,
			"Raffles City, Singapore", 3, ["raffles city tower"], {
				"finish": "white_panel", "bay": 3.0, "floor": 3.8, "trim": "#DEDEE0",
				"ops": [
					["tier", 0.0, 152.0, 38.0, 38.0],
					["louvre", 152.0, 158.0, 32.0, 32.0],
				]}),
		_row("suntec_city_towers_sg", "Suntec City Towers 1–5 & Fountain of Wealth", 1.29510, 103.85895, 177.0, -20.0, 32.0, 5500.0,
			"Suntec City", 4, ["suntec city", "suntec towers", "fountain of wealth"], {
				"finish": "steel_panel", "bay": 3.0, "floor": 3.9, "trim": "#C2C6CA",
				"mats": {"Bronze": ["paint", "#7A5A3A", 0.35, 0.75], "Pool": ["paint", "#3B7A8C", 0.12, 0.1]},
				"ops": [
					["tier", 0.0, 177.0, 36.0, 34.0, -68.0, -48.0],
					["tier", 0.0, 177.0, 36.0, 34.0, -20.0, -68.0],
					["tier", 0.0, 177.0, 36.0, 34.0, 42.0, -52.0],
					["tier", 0.0, 177.0, 36.0, 34.0, 68.0, 14.0],
					["tier", 0.0, 78.0, 38.0, 34.0, -78.0, 22.0],
					["box", "Pool", 0.0, 0.0, 0.0, 34.0, 1.5, 34.0],
					["dome", "Bronze", 1.5, 13.0, 13.8],
				]}),
		_row("south_beach_tower_sg", "South Beach Tower & Residences", 1.29490, 103.85620, 192.0, -60.0, 28.0, 5500.0,
			"South Beach, Singapore", 4, ["south beach tower", "south beach singapore"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.2, "trim": "#C8D0D6", "rib": 3.4,
				"ops": [
					["tier", 0.0, 190.0, 42.0, 32.0, -45.0, 0.0],
					["tier", 0.0, 192.0, 44.0, 28.0, 48.0, 0.0],
				]}),
		_row("duo_towers_sg", "DUO Tower & DUO Residences", 1.29960, 103.85845, 199.0, -52.0, 30.0, 5500.0,
			"DUO (building)", 4, ["duo tower", "duo residences", "duo singapore"], {
				"finish": "intl_bronze", "bay": 3.0, "floor": 4.0, "trim": "#7A6A56",
				"mats": {"Honeycomb": ["paint", "#8E7A64", 0.4, 0.55]},
				"ops": [
					["shape", "ellipse", 0.0, 199.0, 42.0, 34.0, 0.0, 38.0, 30.0, -34.0, 0.0],
					["diagrid", "Honeycomb", 0.0, 199.0, 42.6, 34.6, 14.0, 4, -34.0, 0.0],
					["shape", "ellipse", 0.0, 186.0, 44.0, 34.0, 0.0, 40.0, 30.0, 34.0, 0.0],
					["diagrid", "Honeycomb", 0.0, 186.0, 44.6, 34.6, 14.0, 4, 34.0, 0.0],
				]}),
		_row("parkview_square_sg", "Parkview Square", 1.30010, 103.85775, 144.0, -52.0, 24.0, 5000.0,
			"Parkview Square", 3, ["parkview square", "gotham building singapore"], {
				"finish": "red_granite", "bay": 2.8, "floor": 4.6, "trim": "#6B5242",
				"mats": {"Bronze": ["paint", "#8C7046", 0.35, 0.75]},
				"ops": [
					["tier", 0.0, 26.0, 48.0, 44.0],
					["notch", 26.0, 126.0, 44.0, 40.0, 6.0],
					["steps", "Bronze", 126.0, 36.0, 32.0, 3, 6.0, 3.0],
				]}),
		_row("the_gateway_sg", "The Gateway East & West", 1.29945, 103.86025, 150.0, -52.0, 28.0, 5000.0,
			"The Gateway (Singapore)", 3, ["the gateway", "gateway east", "gateway west"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.0, "trim": "#BCC2C8",
				"ops": [
					["poly", 0.0, 150.0, [[-55.0, -14.0], [-10.0, -14.0], [-24.0, 14.0], [-69.0, 14.0]]],
					["poly", 0.0, 150.0, [[10.0, -14.0], [55.0, -14.0], [69.0, 14.0], [24.0, 14.0]]],
				]}),
		_row("the_concourse_sg", "The Concourse", 1.30040, 103.86235, 175.0, -52.0, 24.0, 5000.0,
			"The Concourse, Singapore", 3, ["the concourse"], {
				"finish": "white_panel", "bay": 3.0, "floor": 4.2, "trim": "#D6D6D2",
				"ops": [
					["shape", "chamfer", 0.0, 36.0, 32.0, 32.0, 6.0, 32.0, 32.0],
					["shape", "chamfer", 36.0, 166.0, 42.0, 42.0, 8.0, 42.0, 42.0],
					["louvre", 166.0, 175.0, 34.0, 34.0],
				]}),

		# --- Chinatown, Clarke Quay & River Valley ---
		_row("parkroyal_pickering_sg", "PARKROYAL COLLECTION Pickering", 1.28565, 103.84625, 89.0, -65.0, 26.0, 4500.0,
			"Parkroyal Collection Pickering", 4, ["parkroyal pickering", "parkroyal collection pickering"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 3.8, "trim": "#C2B8A8",
				"mats": {"Contour": ["concrete", "#BEB29E", 3.0], "Garden": ["forest", "#327238", 3.0]},
				"ops": [
					["box", "Contour", 0.0, 0.0, 0.0, 74.0, 20.0, 32.0],
					["box", "Garden", 0.0, 18.0, 0.0, 76.0, 4.5, 34.0],
					["tier", 22.0, 89.0, 64.0, 22.0],
					["box", "Garden", 0.0, 44.0, 9.0, 66.0, 4.0, 8.0],
					["box", "Garden", 0.0, 66.0, 9.0, 66.0, 4.0, 8.0],
				]}),
		_row("state_courts_towers_sg", "State Courts Towers", 1.28690, 103.84340, 178.0, -56.0, 26.0, 4800.0,
			"State Courts Towers", 3, ["state courts towers", "state courts singapore"], {
				"finish": "white_panel", "bay": 3.0, "floor": 4.8, "trim": "#D6D4CE",
				"mats": {"Bridge": ["glass", "#7EA4B8"]},
				"ops": [
					["tier", 0.0, 178.0, 52.0, 18.0, 0.0, -14.0],
					["tier", 0.0, 178.0, 52.0, 18.0, 0.0, 14.0],
					["box", "Bridge", 0.0, 62.0, 0.0, 34.0, 8.0, 12.0],
					["box", "Bridge", 0.0, 118.0, 0.0, 34.0, 8.0, 12.0],
				]}),
		_row("canninghill_piers_sg", "CanningHill Piers", 1.29147, 103.84463, 192.0, -75.0, 26.0, 4800.0,
			"CanningHill Piers", 3, ["canninghill piers"], {
				"finish": "balcony_white", "bay": 3.0, "floor": 3.8, "trim": "#E2DED6",
				"ops": [
					["tier", 0.0, 192.0, 34.0, 28.0, -24.0, 0.0],
					["tier", 0.0, 100.0, 32.0, 26.0, 24.0, 0.0],
					["box", "Trim", 0.0, 92.0, 0.0, 52.0, 6.0, 14.0],
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
