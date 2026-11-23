class_name BkTowerSpecs
extends RefCounted

## Bangkok skyline towers (`BK-11`) through the `skyline: true` `TowerSpec` channel
## (12 / 30 / 60 / 110 skyline slots per preset, independent of the 22 icon & 4 bridge slots).
## Positions, long-axis bearings, and footprints are measured from OSM & CTBUH in
## `docs/bangkok-landmark-sources.md` §5. Note: King Power MahaNakhon (`w4446511xx`) keeps
## its 14+ mapped helical pixel-cutout `building:part` ways in OSM (`PLAN` line 121 & 549),
## while the 9 signature towers below supply bespoke crowns, tapers, domes, and bare-concrete
## ghost-tower massing across Khlong San, Bang Rak, Silom/Sathorn, Pratunam, and Phloen Chit.

static var _rows: Array = []
static var _by_type: Dictionary = {}

static func _row(type: String, name: String, lat: float, lon: float, height: float, yaw: float,
		clear: float, wiki: String, priority: int, aliases: Array, spec: Dictionary) -> Dictionary:
	return {
		"type": type, "name": name, "lat": lat, "lon": lon,
		"radius_m": 6500.0, "wiki_title": wiki, "height_m": height,
		"clear_m": clear, "yaw_deg": yaw, "kind": "Skyscraper",
		"skyline": true, "skyline_priority": priority,
		"aliases": aliases, "tower_spec": spec,
	}

static func entries() -> Array:
	if not _rows.is_empty():
		return _rows
	_rows = [
		# 1. Magnolias Waterfront Residences at ICONSIAM (way:680736465, 318.0 m, 3,105 m @ 162°)
		_row("magnolias_iconsiam", "Magnolias Waterfront Residences at ICONSIAM",
			13.727514, 100.510502, 318.0, 79.0, 38.0,
			"Magnolias Waterfront Residences at Iconsiam", 3,
			["magnolias waterfront", "iconsiam tower"], {
				"finish": "clear_fin", "bay": 3.2, "floor": 3.8, "trim": "#E6E2D8",
				"mats": {"White": ["render", "#F2EFE8", 3.0]},
				"ops": [
					["tier", 0.0, 36.0, 56.0, 38.0],
					["shape", "chamfer", 36.0, 232.0, 42.0, 28.0, 6.0, 34.0, 23.0],
					["shape", "chamfer", 232.0, 278.0, 32.0, 21.5, 5.5, 22.0, 15.0],
					["louvre", 278.0, 290.0, 17.0, 12.0],
					["spire", "White", 290.0, 2.2, 28.0, 0.15, 8],
				]}),

		# 2. The Residences at Mandarin Oriental Bangkok (way:680739268, 272.2 m, 3,079 m @ 161°)
		_row("mandarin_oriental_residences_bk", "The Residences at Mandarin Oriental Bangkok",
			13.727901, 100.510937, 272.2, -46.0, 32.0,
			"Iconsiam", 2,
			["residences at mandarin oriental bangkok"], {
				"finish": "intl_bronze", "bay": 3.2, "floor": 3.9, "trim": "#D6C39E",
				"ops": [
					["tier", 0.0, 32.0, 48.0, 32.0],
					["shape", "chamfer", 32.0, 238.0, 38.0, 25.0, 5.0, 32.0, 21.0],
					["tier", 238.0, 258.0, 24.0, 16.5],
					["pyramid", "Gold", 258.0, 22.0, 15.0, 14.2, 0.18],
				]}),

		# 3. The River South Tower (way:445340031, 265.6 m, 3,762 m @ 165°)
		_row("the_river_bangkok", "The River South Tower",
			13.721318, 100.510374, 265.6, 11.0, 46.0,
			"The River (skyscraper)", 2,
			["the river bangkok", "the river south tower"], {
				"finish": "lowe_blue", "bay": 3.0, "floor": 3.5, "trim": "#C8D0D8",
				"ops": [
					["tier", 0.0, 24.0, 72.0, 38.0],
					["shape", "round", 24.0, 252.0, 46.0, 24.0, 8.0, 40.0, 20.0, -10.0, 0.0],
					["shape", "round", 24.0, 152.0, 34.0, 20.0, 6.0, 32.0, 18.0, 22.0, 4.0],
					["louvre", 252.0, 265.6, 30.0, 15.0],
				]}),

		# 4. State Tower / Lebua Golden Dome (way:25805374, 247.2 m, 3,969 m @ 155°)
		_row("state_tower_bangkok", "State Tower",
			13.721650, 100.516923, 247.2, -71.0, 52.0,
			"State Tower", 3,
			["state tower", "lebua at state tower"], {
				"finish": "warm_concrete", "bay": 3.6, "floor": 3.5, "trim": "#EAE2CE", "rib": 7.2,
				"mats": {"Cream": ["limestone", "#EFE8D5", 3.5]},
				"ops": [
					["tier", 0.0, 42.0, 86.0, 52.0],
					["notch", 42.0, 198.0, 68.0, 38.0, 6.5],
					["tier", 198.0, 217.0, 48.0, 30.0],
					["box", "Cream", 0.0, 217.0, 0.0, 24.0, 9.2, 24.0],
					["dome", "Gold", 226.2, 13.5, 21.0, 0.0, 0.0],
				]}),

		# 5. Jewelry Trade Center (way:342271323, 220.7 m, 3,994 m @ 150°)
		_row("jewelry_trade_center_bk", "Jewelry Trade Center",
			13.723000, 100.520079, 220.7, 80.0, 36.0,
			"Jewelry Trade Center", 1,
			["jewelry trade center bangkok"], {
				"finish": "silver_reflective", "bay": 3.0, "floor": 3.7, "trim": "#BFC7CE",
				"ops": [
					["tier", 0.0, 34.0, 66.0, 28.0],
					["shape", "chamfer", 34.0, 186.0, 52.0, 25.0, 5.0],
					["shape", "chamfer", 186.0, 208.0, 38.0, 20.0, 4.5],
					["pyramid", "Slope", 208.0, 34.0, 18.0, 12.7, 0.15],
				]}),

		# 6. Baiyoke Tower II (rel:18728185, 304.0 m roof / 328 m spire, 4,228 m @ 89°)
		_row("baiyoke_tower_ii", "Baiyoke Tower II",
			13.754634, 100.540535, 304.0, -68.0, 44.0,
			"Baiyoke Tower II", 3,
			["baiyoke tower ii", "baiyoke sky hotel"], {
				"finish": "warm_concrete", "bay": 3.2, "floor": 3.5, "trim": "#E6DFCE",
				"walls": {"GlassTop": ["lowe_blue", 3.0, 3.6]},
				"ops": [
					["tier", 0.0, 46.0, 68.0, 46.0],
					["shape", "chamfer", 46.0, 224.0, 44.0, 38.0, 9.0],
					["use", "GlassTop"],
					["shape", "chamfer", 224.0, 276.0, 36.0, 32.0, 8.0],
					["shape", "round", 276.0, 294.0, 26.0, 26.0, 9.0],
					["box", "Gold", 0.0, 294.0, 0.0, 18.0, 3.5, 18.0],
					["spire", "Gold", 297.5, 1.4, 6.5, 0.2, 8],
				]}),

		# 7. Sathorn Unique Ghost Tower (way:321722223, 185.0 m, 4,343 m @ 160°)
		_row("sathorn_unique_tower", "Sathorn Unique Tower",
			13.717310, 100.515152, 185.0, 20.0, 34.0,
			"Sathorn Unique Tower", 2,
			["sathorn unique", "bangkok ghost tower"], {
				"finish": "warm_concrete", "bay": 3.8, "floor": 3.6, "trim": "#6C6B66", "rib": 3.8,
				"mats": {"RawConcrete": ["concrete", "#686762", 3.0]},
				"ops": [
					["tier", 0.0, 28.0, 56.0, 32.0],
					["notch", 28.0, 168.0, 48.0, 28.0, 5.0],
					["gap", 92.0, 96.0, 47.0, 27.0],
					["gap", 142.0, 146.0, 47.0, 27.0],
					["box", "RawConcrete", -11.0, 168.0, 0.0, 15.0, 8.0, 15.0],
					["dome", "RawConcrete", 176.0, 7.2, 9.0, -11.0, 0.0],
					["box", "RawConcrete", 11.0, 168.0, 0.0, 15.0, 8.0, 15.0],
					["dome", "RawConcrete", 176.0, 7.2, 9.0, 11.0, 0.0],
				]}),

		# 8. Empire Tower Sathorn (way:32004527, 226.8 m, 4,865 m @ 140°)
		_row("empire_tower_bangkok", "Empire Tower",
			13.720330, 100.530145, 226.8, -25.0, 54.0,
			"Empire Tower (Bangkok)", 1,
			["empire tower bangkok"], {
				"finish": "white_granite", "bay": 3.4, "floor": 3.9, "trim": "#AEB4BA",
				"walls": {"BlueBay": ["lowe_blue", 3.0, 3.9]},
				"ops": [
					["tier", 0.0, 36.0, 92.0, 46.0],
					["tier", 36.0, 178.0, 68.0, 38.0],
					["use", "BlueBay"],
					["tier", 178.0, 214.0, 48.0, 30.0],
					["louvre", 214.0, 226.8, 34.0, 20.0],
				]}),

		# 9. One City Centre Phloen Chit (way:1222766567, 275.8 m, 5,022 m @ 105°)
		_row("one_city_centre_bk", "One City Centre",
			13.741961, 100.546209, 275.8, -80.0, 32.0,
			"One City Centre", 2,
			["one city centre bangkok", "occ bangkok"], {
				"finish": "clear_fin", "bay": 3.0, "floor": 4.2, "trim": "#DCE3EA",
				"ops": [
					["tier", 0.0, 28.0, 46.0, 42.0],
					["tier", 28.0, 218.0, 42.0, 38.0],
					["diagrid", "Trim", 28.0, 218.0, 42.4, 38.4, 16.8, 5],
					["tier", 218.0, 260.0, 36.0, 32.0],
					["slope", 260.0, 275.8, 36.0, 32.0],
				]}),
	]
	for e in _rows:
		_by_type[str(e["type"])] = e
	return _rows

static func spec_for(type: String) -> Dictionary:
	entries()
	return (_by_type.get(type, {}) as Dictionary).get("tower_spec", {})
