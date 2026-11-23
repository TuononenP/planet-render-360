class_name LnTowerSpecs
extends RefCounted

## London skyline towers (`LN-5`) through the `skyline: true` `TowerSpec` channel
## (12 / 30 / 60 / 110 skyline slots per preset, independent of icon & bridge slots).
## Covers the City of London Eastern Cluster, Barbican, South Bank / Blackfriars /
## Nine Elms, and Canary Wharf. Sources: `docs/london-landmark-sources.md` §4.

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
		# --- City of London Eastern Cluster (~2.7–3.1 km) ---
		_row("twenty_two_bishopsgate", "22 Bishopsgate", 51.5146, -0.0828, 278.0, 12.0, 32.0, 9000.0,
			"22 Bishopsgate", 4, ["22 bishopsgate", "22 bishopsgate tower"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.2, "trim": "#B8C0C8",
				"ops": [
					["tier", 0.0, 26.0, 52.0, 44.0],
					["shape", "chamfer", 26.0, 224.0, 48.0, 40.0, 5.5, 45.0, 37.0],
					["shape", "chamfer", 224.0, 262.0, 44.0, 34.0, 5.0, 38.0, 28.0],
					["louvre", 262.0, 278.0, 34.0, 24.0],
				]}),

		_row("heron_tower", "110 Bishopsgate (Heron Tower)", 51.5162, -0.0810, 230.1, 14.0, 26.0, 9000.0,
			"Heron Tower", 3, ["heron tower", "110 bishopsgate", "salesforce tower london"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.2, "trim": "#C5CCD2",
				"mats": {"Steel": ["paint", "#C8CFD6", 0.35, 0.75]},
				"ops": [
					["tier", 0.0, 18.0, 42.0, 34.0],
					["tier", 18.0, 202.0, 38.0, 30.0],
					["diagrid", "Steel", 18.0, 202.0, 38.6, 30.6, 16.0, 3],
					["spire", "Steel", 202.0, 0.9, 28.1, 0.12, 8],
				]}),

		_row("leadenhall_building", "The Leadenhall Building", 51.5138, -0.0822, 224.5, 8.0, 28.0, 9000.0,
			"122 Leadenhall Street", 4, ["leadenhall building", "122 leadenhall street", "the cheesegrater", "cheesegrater"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.2, "trim": "#9AA2AA",
				"mats": {"Steel": ["paint", "#A8B0B8", 0.35, 0.75], "Core": ["paint", "#484E54", 0.5, 0.4]},
				"ops": [
					["tier", 0.0, 28.0, 46.0, 44.0],
					["shape", "rect", 28.0, 214.0, 46.0, 44.0, 0.0, 46.0, 14.0],
					["diagrid", "Steel", 28.0, 214.0, 46.6, 30.0, 26.0, 3],
					["box", "Core", 0.0, 28.0, -14.0, 44.0, 196.5, 11.0],
				]}),

		_row("eight_bishopsgate", "8 Bishopsgate", 51.5137, -0.0837, 204.0, 10.0, 24.0, 9000.0,
			"8 Bishopsgate", 3, ["8 bishopsgate"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 4.0, "trim": "#B0B8C0",
				"ops": [
					["tier", 0.0, 68.0, 40.0, 34.0],
					["tier", 68.0, 140.0, 44.0, 32.0, 2.0, 0.0],
					["tier", 140.0, 196.0, 38.0, 28.0, 4.0, 0.0],
					["louvre", 196.0, 204.0, 34.0, 24.0],
				]}),

		_row("the_scalpel", "52 Lime Street (The Scalpel)", 51.5130, -0.0816, 190.0, 6.0, 24.0, 9000.0,
			"The Scalpel", 3, ["the scalpel", "52 lime street"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 4.2, "trim": "#D0D4D8",
				"ops": [
					["tier", 0.0, 22.0, 40.0, 38.0],
					["shape", "chamfer", 22.0, 145.0, 38.0, 36.0, 4.0, 34.0, 30.0],
					["slope", 145.0, 190.0, 34.0, 30.0],
				]}),

		_row("tower_42", "Tower 42", 51.5153, -0.0840, 183.0, 15.0, 26.0, 9000.0,
			"Tower 42", 3, ["tower 42", "natwest tower"], {
				"finish": "intl_bronze", "bay": 2.8, "floor": 3.8, "trim": "#7E7870", "rib": 3.6,
				"ops": [
					["tier", 0.0, 24.0, 34.0, 34.0],
					["notch", 24.0, 152.0, 44.0, 44.0, 9.0],
					["notch", 152.0, 175.0, 36.0, 36.0, 7.0],
					["louvre", 175.0, 183.0, 28.0, 28.0],
				]}),

		_row("walkie_talkie", "20 Fenchurch Street (Walkie-Talkie)", 51.5112, -0.0836, 160.0, 12.0, 28.0, 9000.0,
			"20 Fenchurch Street", 4, ["20 fenchurch street", "walkie-talkie", "walkie talkie", "sky garden london"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.1, "trim": "#D2D6DA", "rib": 6.0,
				"mats": {"Crown": ["glass", "#8FB4C8"], "Rib": ["paint", "#D6D8DC", 0.35, 0.7]},
				"ops": [
					["shape", "round", 0.0, 50.0, 42.0, 28.0, 6.0, 48.0, 34.0],
					["shape", "round", 50.0, 134.0, 48.0, 34.0, 7.0, 58.0, 42.0],
					["shape", "round", 134.0, 154.0, 58.0, 42.0, 8.0, 54.0, 38.0],
					["dome", "Crown", 154.0, 20.0, 6.0],
				]}),

		_row("willis_building", "Willis Building", 51.5132, -0.0812, 125.0, 10.0, 22.0, 8000.0,
			"Willis Building (London)", 2, ["willis building", "51 lime street"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 4.0, "trim": "#B8C0C8",
				"ops": [
					["shape", "round", 0.0, 70.0, 44.0, 34.0, 8.0, 44.0, 34.0],
					["shape", "round", 70.0, 100.0, 36.0, 28.0, 6.0, 36.0, 28.0, -4.0, 0.0],
					["shape", "round", 100.0, 125.0, 28.0, 24.0, 5.0, 28.0, 24.0, -7.0, 0.0],
				]}),

		# --- Barbican Brutalist Concrete Towers (~2.6 km) ---
		_row("barbican_cromwell", "Cromwell Tower (Barbican)", 51.5205, -0.0928, 123.0, 0.0, 20.0, 7500.0,
			"Cromwell Tower", 2, ["cromwell tower", "barbican cromwell tower"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 2.9, "trim": "#9C978E", "rib": 4.5,
				"ops": [
					["shape", "tri", 0.0, 118.0, 30.0, 30.0, 3.0],
					["louvre", 118.0, 123.0, 18.0, 18.0],
				]}),

		_row("barbican_lauderdale", "Lauderdale Tower (Barbican)", 51.5198, -0.0965, 123.0, 0.0, 20.0, 7500.0,
			"Lauderdale Tower", 2, ["lauderdale tower", "barbican lauderdale tower"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 2.9, "trim": "#9C978E", "rib": 4.5,
				"ops": [
					["shape", "tri", 0.0, 118.0, 30.0, 30.0, 3.0],
					["louvre", 118.0, 123.0, 18.0, 18.0],
				]}),

		_row("barbican_shakespeare", "Shakespeare Tower (Barbican)", 51.5208, -0.0947, 123.0, 0.0, 20.0, 7500.0,
			"Shakespeare Tower", 2, ["shakespeare tower", "barbican shakespeare tower"], {
				"finish": "warm_concrete", "bay": 2.8, "floor": 2.9, "trim": "#9C978E", "rib": 4.5,
				"ops": [
					["shape", "tri", 0.0, 118.0, 30.0, 30.0, 3.0],
					["louvre", 118.0, 123.0, 18.0, 18.0],
				]}),

		# --- South Bank, Blackfriars, Westminster & Nine Elms (0.3–2.5 km) ---
		_row("one_blackfriars", "One Blackfriars", 51.5078, -0.1047, 163.0, 5.0, 24.0, 8000.0,
			"One Blackfriars", 4, ["one blackfriars", "the boomerang", "the vase london"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 3.2, "trim": "#D6DCE0",
				"ops": [
					["shape", "ellipse", 0.0, 48.0, 26.0, 36.0, 0.0, 34.0, 42.0],
					["shape", "ellipse", 48.0, 120.0, 34.0, 42.0, 0.0, 28.0, 34.0],
					["shape", "ellipse", 120.0, 163.0, 28.0, 34.0, 0.0, 20.0, 24.0],
				]}),

		_row("south_bank_tower", "South Bank Tower", 51.5077, -0.1072, 155.0, 8.0, 24.0, 7500.0,
			"South Bank Tower", 2, ["south bank tower", "king's reach tower"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 3.6, "trim": "#C2C8CE",
				"ops": [
					["tier", 0.0, 24.0, 42.0, 32.0],
					["tier", 24.0, 148.0, 34.0, 26.0],
					["louvre", 148.0, 155.0, 30.0, 22.0],
				]}),

		_row("shell_centre", "Shell Centre Tower", 51.5037, -0.1167, 107.0, -24.0, 26.0, 6000.0,
			"Shell Centre", 3, ["shell centre", "shell centre tower"], {
				"finish": "limestone_pier", "bay": 3.2, "floor": 3.8, "trim": "#DDD6C5", "rib": 3.2,
				"ops": [
					["tier", 0.0, 16.0, 48.0, 24.0],
					["tier", 16.0, 100.0, 44.0, 20.0],
					["louvre", 100.0, 107.0, 34.0, 16.0],
				]}),

		_row("millbank_tower", "Millbank Tower", 51.4923, -0.1257, 118.0, 10.0, 22.0, 6500.0,
			"Millbank Tower", 2, ["millbank tower"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.5, "trim": "#C8CFD4",
				"ops": [
					["tier", 0.0, 14.0, 40.0, 26.0],
					["shape", "chamfer", 14.0, 112.0, 32.0, 22.0, 3.0],
					["louvre", 112.0, 118.0, 24.0, 16.0],
				]}),

		_row("strata_se1", "Strata SE1", 51.4930, -0.0998, 148.0, 18.0, 22.0, 7500.0,
			"Strata SE1", 2, ["strata se1", "the razor london"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.3, "trim": "#C8CCD0",
				"mats": {"Crown": ["paint", "#D4D8DC", 0.35, 0.7]},
				"ops": [
					["shape", "chamfer", 0.0, 132.0, 30.0, 26.0, 4.0, 24.0, 22.0],
					["box", "Crown", -7.0, 132.0, 0.0, 3.0, 16.0, 8.0],
					["box", "Crown", 0.0, 132.0, 0.0, 3.0, 16.0, 8.0],
					["box", "Crown", 7.0, 132.0, 0.0, 3.0, 16.0, 8.0],
				]}),

		_row("st_george_wharf", "St George Wharf Tower", 51.4851, -0.1277, 181.0, 0.0, 24.0, 8000.0,
			"St George Wharf Tower", 3, ["st george wharf tower", "vauxhall tower"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 3.4, "trim": "#D6DCE0",
				"mats": {"Steel": ["paint", "#DCE0E4", 0.35, 0.7]},
				"ops": [
					["shape", "ellipse", 0.0, 164.0, 28.0, 28.0],
					["slope", 164.0, 174.0, 24.0, 24.0],
					["spire", "Steel", 172.0, 1.0, 9.0, 0.2, 8],
				]}),

		_row("one_nine_elms", "One Nine Elms (City Tower)", 51.4835, -0.1292, 200.0, 12.0, 26.0, 8000.0,
			"One Nine Elms", 3, ["one nine elms", "city tower nine elms"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 3.4, "trim": "#C8D0D8",
				"ops": [
					["tier", 0.0, 22.0, 46.0, 34.0],
					["tier", 22.0, 192.0, 34.0, 28.0],
					["louvre", 192.0, 200.0, 30.0, 24.0],
				]}),

		# --- Canary Wharf Cluster (~6.9–7.3 km, bearing 87°–90°) ---
		_row("one_canada_square", "One Canada Square", 51.5049, -0.0195, 235.0, 0.0, 30.0, 10500.0,
			"One Canada Square", 5, ["one canada square", "canary wharf tower"], {
				"finish": "steel_panel", "bay": 3.2, "floor": 4.0, "trim": "#D4D8DC", "rib": 3.2,
				"mats": {"Steel": ["paint", "#D4D8DC", 0.32, 0.8], "Lamp": ["lit", "#FF2418", 2.8]},
				"ops": [
					["tier", 0.0, 196.0, 48.0, 48.0],
					["pyramid", "Steel", 196.0, 48.0, 48.0, 38.0, 0.05],
					["box", "Lamp", 0.0, 233.5, 0.0, 1.6, 1.5, 1.6],
				]}),

		_row("landmark_pinnacle", "Landmark Pinnacle", 51.5030, -0.0258, 233.0, 0.0, 24.0, 10500.0,
			"Landmark Pinnacle", 3, ["landmark pinnacle"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 3.1, "trim": "#CED4DA",
				"ops": [
					["tier", 0.0, 24.0, 36.0, 32.0],
					["tier", 24.0, 188.0, 32.0, 28.0],
					["tier", 188.0, 224.0, 31.0, 27.0],
					["louvre", 224.0, 233.0, 29.0, 25.0],
				]}),

		_row("newfoundland_cw", "Newfoundland (Canary Wharf)", 51.5047, -0.0250, 220.0, 0.0, 26.0, 10500.0,
			"Newfoundland (building)", 3, ["newfoundland canary wharf", "newfoundland tower"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 3.6, "trim": "#B8C0C8",
				"mats": {"Steel": ["paint", "#A8B0B6", 0.38, 0.72]},
				"ops": [
					["shape", "chamfer", 0.0, 214.0, 38.0, 30.0, 5.0],
					["diagrid", "Steel", 8.0, 214.0, 38.6, 30.6, 18.0, 3],
					["louvre", 214.0, 220.0, 30.0, 22.0],
				]}),

		_row("one_park_drive", "One Park Drive", 51.5016, -0.0151, 205.0, 0.0, 24.0, 10500.0,
			"One Park Drive", 2, ["one park drive"], {
				"finish": "warm_concrete", "bay": 3.0, "floor": 3.4, "trim": "#C2B8AA",
				"ops": [
					["shape", "ellipse", 0.0, 200.0, 36.0, 36.0],
					["louvre", 200.0, 205.0, 28.0, 28.0],
				]}),

		_row("citigroup_cw", "25 Canada Square (Citigroup)", 51.5042, -0.0182, 200.0, 0.0, 28.0, 10500.0,
			"25 Canada Square", 3, ["25 canada square", "citigroup centre london"], {
				"finish": "clear_fin", "bay": 3.2, "floor": 4.2, "trim": "#C4CCD2",
				"ops": [
					["tier", 0.0, 22.0, 52.0, 48.0],
					["tier", 22.0, 165.0, 48.0, 44.0],
					["tier", 165.0, 192.0, 46.0, 42.0],
					["louvre", 192.0, 200.0, 42.0, 38.0],
				]}),

		_row("hsbc_cw", "8 Canada Square (HSBC)", 51.5054, -0.0175, 199.5, 0.0, 28.0, 10500.0,
			"8 Canada Square", 3, ["8 canada square", "hsbc tower london"], {
				"finish": "silver_reflective", "bay": 3.2, "floor": 4.2, "trim": "#C8CFD6",
				"ops": [
					["tier", 0.0, 22.0, 54.0, 48.0],
					["tier", 22.0, 168.0, 50.0, 44.0],
					["tier", 168.0, 192.0, 48.0, 42.0],
					["louvre", 192.0, 199.5, 44.0, 38.0],
				]}),

		_row("barclays_cw", "1 Churchill Place (Barclays)", 51.5056, -0.0145, 156.0, 0.0, 26.0, 10500.0,
			"One Churchill Place", 2, ["1 churchill place", "one churchill place", "barclays tower"], {
				"finish": "lowe_blue", "bay": 3.2, "floor": 4.4, "trim": "#B8C2CC",
				"ops": [
					["tier", 0.0, 20.0, 56.0, 46.0],
					["tier", 20.0, 126.0, 52.0, 42.0],
					["tier", 126.0, 148.0, 49.0, 39.0],
					["louvre", 148.0, 156.0, 45.0, 35.0],
				]}),
	]
	_by_type.clear()
	for r in _rows:
		_by_type[str((r as Dictionary)["type"])] = (r as Dictionary)["tower_spec"]
	return _rows

static func spec_for(type: String) -> Dictionary:
	if _rows.is_empty():
		entries()
	return _by_type.get(type, {})
