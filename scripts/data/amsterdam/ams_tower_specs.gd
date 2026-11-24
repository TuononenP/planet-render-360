class_name AmsTowerSpecs
extends RefCounted

## Amsterdam skyline towers (`AMS-3.6`) through the `skyline: true` `TowerSpec`
## channel (12 / 30 / 60 / 110 skyline slots per preset, consuming zero icon or
## bridge slots). Covers the Amstel / Omval cluster (Rembrandttoren, Mondriaantoren,
## Breitnertoren, Amstel Tower, Okura), the Zuidas business district (Valley,
## Symphony Towers, ITO, Viñoly, ABN AMRO, The Rock, WTC, New Amsterdam), and
## Overhoeks / IJdock / Zuidoost towers.

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
		# --- Amstel / Omval Cluster (~3.7 km SE, dominant southern skyline) ---
		_row("rembrandttoren", "Rembrandttoren", 52.34512, 4.91706, 150.0, 22.0, 28.0, 9000.0,
			"Rembrandt Tower", 4, ["rembrandttoren", "rembrandt tower"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 3.8, "trim": "#B5BDC4",
				"mats": {"Stone": ["limestone", "#B8B4AC", 3.0],
					"Steel": ["paint", "#C8CFD6", 0.3, 0.8]},
				"ops": [
					["tier", 0.0, 22.0, 44.0, 44.0],
					["tier", 22.0, 114.0, 34.0, 34.0],
					["tier", 114.0, 128.0, 24.0, 24.0],
					["tier", 128.0, 135.0, 14.0, 14.0],
					["spire", "Steel", 135.0, 1.4, 15.0, 0.12, 8],
				]}),

		_row("mondriaantoren", "Mondriaantoren", 52.34405, 4.91759, 123.0, 22.0, 24.0, 9000.0,
			"Mondriaan Tower", 3, ["mondriaantoren", "mondriaan tower"], {
				"finish": "silver_reflective", "bay": 2.8, "floor": 3.7, "trim": "#C2C8CC",
				"ops": [
					["tier", 0.0, 18.0, 34.0, 28.0],
					["tier", 18.0, 98.0, 30.0, 24.0],
					["tier", 98.0, 115.0, 22.0, 20.0],
					["louvre", 115.0, 123.0, 18.0, 16.0],
				]}),

		_row("amstel_tower", "Amstel Tower", 52.34567, 4.91887, 103.0, 22.0, 24.0, 9000.0,
			"Amstel Tower", 3, ["amstel tower"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 3.3, "trim": "#D6D2CA",
				"ops": [
					["tier", 0.0, 20.0, 52.0, 38.0],
					["tier", 20.0, 99.0, 24.0, 26.0],
					["louvre", 99.0, 103.0, 22.0, 22.0],
				]}),

		_row("breitnertoren", "Breitnertoren", 52.34440, 4.91655, 95.0, 22.0, 22.0, 9000.0,
			"Breitner Center", 2, ["breitnertoren", "breitner center", "breitner tower"], {
				"finish": "granite_strip", "bay": 3.0, "floor": 3.7, "trim": "#4A525A",
				"ops": [
					["tier", 0.0, 16.0, 32.0, 24.0],
					["shape", "chamfer", 16.0, 91.0, 30.0, 22.0, 4.0, 28.0, 20.0],
					["louvre", 91.0, 95.0, 24.0, 16.0],
				]}),

		_row("hotel_okura_amsterdam", "Hotel Okura Amsterdam", 52.34890, 4.89385, 78.0, 12.0, 24.0, 8000.0,
			"Hotel Okura Amsterdam", 2, ["hotel okura", "okura amsterdam"], {
				"finish": "limestone_pier", "bay": 3.2, "floor": 3.3, "trim": "#DDD8CE",
				"ops": [
					["tier", 0.0, 12.0, 52.0, 36.0],
					["tier", 12.0, 74.0, 36.0, 20.0],
					["louvre", 74.0, 78.0, 32.0, 16.0],
				]}),

		# --- Zuidas Business District Cluster (~3.9–4.3 km S) ---
		_row("zuidas_valley", "Valley Amsterdam", 52.33750, 4.87120, 100.0, 0.0, 34.0, 9500.0,
			"Valley, Amsterdam", 4, ["valley amsterdam", "valley zuidas", "mvrdv valley"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 3.4, "trim": "#CFC6B6",
				"mats": {"Stone": ["limestone", "#C8BEA8", 3.0]},
				"ops": [
					["tier", 0.0, 24.0, 66.0, 56.0],
					["tier", 24.0, 67.0, 56.0, 44.0],
					["shape", "chamfer", 67.0, 84.0, 42.0, 32.0, 6.0, 34.0, 24.0],
					["shape", "chamfer", 84.0, 100.0, 26.0, 22.0, 5.0, 18.0, 16.0],
				]}),

		_row("zuidas_symphony", "Symphony Towers", 52.33730, 4.87480, 105.0, 0.0, 28.0, 9500.0,
			"Symphony, Amsterdam", 3, ["symphony amsterdam", "symphony towers", "symphony zuidas"], {
				"finish": "brick_punched", "bay": 2.6, "floor": 3.6, "trim": "#B55D3C",
				"ops": [
					["tier", 0.0, 16.0, 48.0, 38.0],
					["tier", 16.0, 96.0, 42.0, 32.0],
					["tier", 96.0, 105.0, 34.0, 24.0],
				]}),

		_row("zuidas_ito", "ITO Tower", 52.33740, 4.87580, 100.0, 0.0, 24.0, 9500.0,
			"ITO Tower", 3, ["ito tower", "ito zuidas"], {
				"finish": "limestone_pier", "bay": 3.0, "floor": 3.8, "trim": "#D0CCC2",
				"ops": [
					["tier", 0.0, 20.0, 36.0, 34.0],
					["tier", 20.0, 96.0, 32.0, 30.0],
					["louvre", 96.0, 100.0, 28.0, 26.0],
				]}),

		_row("zuidas_vinoly", "Viñoly Tower", 52.33790, 4.87680, 95.0, 0.0, 24.0, 9500.0,
			"Viñoly (building)", 2, ["vinoly tower", "viñoly tower", "mahler 4"], {
				"finish": "granite_strip", "bay": 2.8, "floor": 3.8, "trim": "#3B4046",
				"ops": [
					["tier", 0.0, 16.0, 34.0, 32.0],
					["tier", 16.0, 91.0, 30.0, 28.0],
					["louvre", 91.0, 95.0, 26.0, 24.0],
				]}),

		_row("zuidas_abn_amro", "ABN AMRO Headquarters", 52.33810, 4.87780, 105.0, 0.0, 30.0, 9500.0,
			"ABN AMRO", 3, ["abn amro headquarters", "abn amro zuidas"], {
				"finish": "limestone_pier", "bay": 3.0, "floor": 3.9, "trim": "#C2BCB0",
				"ops": [
					["tier", 0.0, 26.0, 56.0, 42.0],
					["tier", 26.0, 82.0, 40.0, 32.0],
					["tier", 82.0, 105.0, 28.0, 24.0],
				]}),

		_row("zuidas_the_rock", "The Rock", 52.33670, 4.87380, 91.0, 0.0, 24.0, 9500.0,
			"The Rock (Amsterdam)", 2, ["the rock amsterdam", "the rock zuidas"], {
				"finish": "limestone_pier", "bay": 3.2, "floor": 3.8, "trim": "#9C968E",
				"ops": [
					["tier", 0.0, 28.0, 30.0, 28.0],
					["tier", 28.0, 62.0, 36.0, 34.0],
					["tier", 62.0, 91.0, 32.0, 26.0],
				]}),

		_row("zuidas_wtc", "World Trade Center Amsterdam", 52.34010, 4.87320, 105.0, 0.0, 30.0, 9500.0,
			"World Trade Center (Amsterdam)", 3, ["wtc amsterdam", "world trade center amsterdam"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 3.8, "trim": "#A2B2C2",
				"ops": [
					["tier", 0.0, 22.0, 54.0, 34.0],
					["tier", 22.0, 86.0, 40.0, 28.0],
					["tier", 86.0, 105.0, 28.0, 22.0],
				]}),

		_row("zuidas_new_amsterdam", "New Amsterdam", 52.33760, 4.87260, 92.0, 0.0, 22.0, 9500.0,
			"New Amsterdam (building)", 2, ["new amsterdam zuidas", "new amsterdam tower"], {
				"finish": "granite_strip", "bay": 2.8, "floor": 3.6, "trim": "#565B62",
				"ops": [
					["tier", 0.0, 14.0, 32.0, 26.0],
					["tier", 14.0, 88.0, 28.0, 24.0],
					["louvre", 88.0, 92.0, 24.0, 20.0],
				]}),

		# --- Overhoeks / Zuidoost ---
		_row("overhoeks_ytowers", "Y-Towers / Maritim Amsterdam", 52.38530, 4.90450, 110.0, -32.0, 28.0, 8000.0,
			"Overhoeks", 3, ["y-towers", "maritim amsterdam", "overhoeks towers"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 3.4, "trim": "#C4C9CE",
				"ops": [
					["tier", 0.0, 16.0, 46.0, 36.0],
					["tier", 16.0, 106.0, 34.0, 26.0],
					["louvre", 106.0, 110.0, 30.0, 22.0],
				]}),

		_row("dreeftoren_two", "Dreeftoren II", 52.31032, 4.94235, 132.0, 15.0, 26.0, 10000.0,
			"Amsterdam-Zuidoost", 2, ["dreeftoren", "dreeftoren ii"], {
				"finish": "clear_fin", "bay": 2.8, "floor": 3.4, "trim": "#D2CEC6",
				"ops": [
					["tier", 0.0, 16.0, 44.0, 38.0],
					["tier", 16.0, 128.0, 30.0, 28.0],
					["louvre", 128.0, 132.0, 26.0, 24.0],
				]}),
	]
	for r in _rows:
		_by_type[str(r["type"])] = r["tower_spec"]
	return _rows

static func spec_for(type: String) -> Dictionary:
	if _by_type.is_empty():
		entries()
	return _by_type.get(type, {}) as Dictionary
