class_name LandmarkRegistryAngkorOuter
extends RefCounted

## Siem Reap batch D: the Roluos group, Beng Mealea, Phnom Krom and West
## Mebon. See LandmarkSetAngkorOuter for the builders. Coordinates are the
## temple centres (OSM, Wikipedia); Beng Mealea is placed from the OSM ruin
## outline and moat, 1 km west of the Wikipedia point.

static func entries() -> Array:
	return [
		{"type": "bakong_temple", "name": "Bakong",
			"lat": 13.3359, "lon": 103.9741, "radius_m": 5000.0,
			"wiki_title": "Bakong", "height_m": 27.5, "clear_m": 210.0, "tree_clear_m": 60.0,
			"kind": "Temple mountain",
			"aliases": ["bakong", "prasat bakong", "bakong temple", "roluos bakong", "ប្រាសាទបាគង"]},
		{"type": "preah_ko_temple", "name": "Preah Ko",
			"lat": 13.3439, "lon": 103.9729, "radius_m": 5000.0,
			"wiki_title": "Preah Ko", "height_m": 14.5, "clear_m": 60.0, "tree_clear_m": 40.0,
			"kind": "Temple",
			"aliases": ["preah ko", "preah ko temple", "preah koh", "sacred bull temple", "ប្រាសាទព្រះគោ"]},
		{"type": "lolei_temple", "name": "Lolei",
			"lat": 13.3526, "lon": 103.9740, "radius_m": 5000.0,
			"wiki_title": "Lolei", "height_m": 14.6, "clear_m": 45.0, "tree_clear_m": 35.0,
			"kind": "Temple",
			"aliases": ["lolei", "lolei temple", "prasat lolei", "ប្រាសាទលលៃ"]},
		{"type": "beng_mealea", "name": "Beng Mealea",
			"lat": 13.4756, "lon": 104.2293, "radius_m": 5000.0,
			"wiki_title": "Beng Mealea", "height_m": 14.0, "clear_m": 200.0,
			"kind": "Temple ruin",
			"aliases": ["beng mealea", "beng melea", "bung mealea", "prasat beng mealea", "ប្រាសាទបឹងមាលា"]},
		{"type": "phnom_krom", "name": "Phnom Krom",
			"lat": 13.2856, "lon": 103.8122, "radius_m": 4000.0,
			"wiki_title": "Prasat Phnom Krom", "height_m": 11.2, "clear_m": 40.0,
			"kind": "Hilltop temple",
			"aliases": ["phnom krom", "prasat phnom krom", "phnom kraom", "ប្រាសាទភ្នំក្រោម"]},
		{"type": "west_mebon", "name": "West Mebon",
			"lat": 13.4342, "lon": 103.8003, "radius_m": 4000.0,
			"wiki_title": "West Mebon", "height_m": 7.8, "clear_m": 65.0,
			"kind": "Island temple",
			"aliases": ["west mebon", "western mebon", "prasat mebon khang lech", "មេបុណ្យខាងលិច"]},
	]
