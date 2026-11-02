class_name LandmarkRegistryCentralEurope
extends RefCounted

## Registry entries for the central europe landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetCentralEurope.

static func entries() -> Array:
	return [
		# Germany
		{"type": "brandenburg_gate", "name": "Brandenburg Gate", "lat": 52.5163, "lon": 13.3777, "radius_m": 3000.0,
			"wiki_title": "Brandenburg Gate", "height_m": 26.0, "clear_m": 55.0, "kind": "Gate",
			"aliases": ["brandenburg gate", "brandenburger tor"]},
		{"type": "reichstag", "name": "Reichstag Building", "lat": 52.5186, "lon": 13.3762, "radius_m": 3000.0,
			"wiki_title": "Reichstag building", "height_m": 47.0, "clear_m": 95.0, "kind": "Parliament",
			"aliases": ["reichstag", "reichstagsgebäude"]},
		{"type": "berlin_tv_tower", "name": "Berliner Fernsehturm", "lat": 52.5208, "lon": 13.4094, "radius_m": 4000.0,
			"wiki_title": "Berliner Fernsehturm", "height_m": 368.0, "clear_m": 60.0, "kind": "TV tower",
			"aliases": ["fernsehturm", "berlin tv tower", "berliner fernsehturm"]},
		{"type": "cologne_cathedral", "icon": true, "name": "Cologne Cathedral", "lat": 50.9413, "lon": 6.9583, "radius_m": 4000.0,
			"wiki_title": "Cologne Cathedral", "height_m": 157.4, "clear_m": 90.0, "kind": "Cathedral",
			"aliases": ["cologne cathedral", "kölner dom", "kolner dom", "koelner dom", "hohe domkirche"]},
		{"type": "neuschwanstein", "name": "Neuschwanstein Castle", "lat": 47.5576, "lon": 10.7498, "radius_m": 3000.0,
			"wiki_title": "Neuschwanstein Castle", "height_m": 65.0, "clear_m": 50.0, "kind": "Castle",
			"aliases": ["neuschwanstein", "schloss neuschwanstein"]},
		# Czechia, Hungary, Austria
		{"type": "st_vitus_cathedral", "icon": true, "name": "St Vitus Cathedral", "lat": 50.0909, "lon": 14.4005, "radius_m": 3000.0,
			"wiki_title": "St. Vitus Cathedral", "height_m": 96.5, "clear_m": 80.0, "kind": "Cathedral",
			"aliases": ["st vitus cathedral", "st. vitus cathedral", "saint vitus cathedral", "katedrála svatého víta"]},
		{"type": "hungarian_parliament", "icon": true, "name": "Hungarian Parliament Building", "lat": 47.5073, "lon": 19.0456,
			"radius_m": 4000.0, "wiki_title": "Hungarian Parliament Building", "height_m": 96.0, "clear_m": 150.0,
			"kind": "Parliament", "aliases": ["hungarian parliament", "országház", "orszaghaz", "parliament of budapest"]},
		{"type": "schonbrunn_palace", "name": "Schönbrunn Palace", "lat": 48.1845, "lon": 16.3122, "radius_m": 3000.0,
			"wiki_title": "Schönbrunn Palace", "height_m": 27.0, "clear_m": 110.0, "yaw_deg": 27.0, "kind": "Palace",
			"aliases": ["schönbrunn", "schonbrunn", "schoenbrunn", "schloss schönbrunn"]},
		{"type": "st_stephens_vienna", "icon": true, "name": "St Stephen's Cathedral", "lat": 48.2084, "lon": 16.3731, "radius_m": 3000.0,
			"wiki_title": "St. Stephen's Cathedral, Vienna", "height_m": 136.4, "clear_m": 70.0, "kind": "Cathedral",
			"aliases": ["st stephen's cathedral", "st. stephen's cathedral", "saint stephen's cathedral", "stephansdom"]},
		# Russia
		{"type": "saint_basils", "icon": true, "name": "Saint Basil's Cathedral", "lat": 55.7525, "lon": 37.6231, "radius_m": 3000.0,
			"wiki_title": "Saint Basil's Cathedral", "height_m": 47.2, "clear_m": 55.0, "kind": "Cathedral",
			"aliases": ["saint basil's cathedral", "st basil's cathedral", "st. basil's cathedral", "saint basil's",
				"st basil's", "pokrovsky cathedral", "покровский собор"]},
		{"type": "spasskaya_tower", "name": "Spasskaya Tower", "lat": 55.7528, "lon": 37.6217, "radius_m": 2500.0,
			"wiki_title": "Spasskaya Tower", "height_m": 71.0, "clear_m": 30.0, "yaw_deg": 90.0, "kind": "Tower",
			"aliases": ["spasskaya tower", "spasskaya", "spassky tower", "saviour tower", "спасская башня"]},
		{"type": "msu_main_building", "name": "Moscow State University", "lat": 55.7033, "lon": 37.5307, "radius_m": 4000.0,
			"wiki_title": "Main Building of Moscow State University", "height_m": 240.0, "clear_m": 170.0,
			"kind": "University", "aliases": ["moscow state university", "lomonosov moscow state", "главное здание мгу",
				"msu main building"]},
		{"type": "ostankino_tower", "name": "Ostankino Tower", "lat": 55.8196, "lon": 37.6117, "radius_m": 4000.0,
			"wiki_title": "Ostankino Tower", "height_m": 540.1, "clear_m": 60.0, "kind": "TV tower",
			"aliases": ["ostankino tower", "ostankino", "останкинская башня"]},
		{"type": "motherland_calls", "name": "The Motherland Calls", "lat": 48.7423, "lon": 44.5371, "radius_m": 3000.0,
			"wiki_title": "The Motherland Calls", "height_m": 85.0, "clear_m": 30.0, "kind": "Monument",
			"aliases": ["the motherland calls", "motherland calls", "mamayev kurgan", "mamaev kurgan",
				"родина-мать зовёт"]},
		# Istanbul
		{"type": "hagia_sophia", "icon": true, "name": "Hagia Sophia", "lat": 41.0086, "lon": 28.9802, "radius_m": 3500.0,
			"wiki_title": "Hagia Sophia", "height_m": 60.0, "clear_m": 85.0, "yaw_deg": 35.0, "kind": "Mosque",
			"aliases": ["hagia sophia", "ayasofya", "aya sofya", "sancta sophia"]},
		{"type": "blue_mosque", "name": "Blue Mosque", "lat": 41.0054, "lon": 28.9768, "radius_m": 3500.0,
			"wiki_title": "Sultan Ahmed Mosque", "height_m": 64.0, "clear_m": 105.0, "yaw_deg": -45.0, "kind": "Mosque",
			"aliases": ["blue mosque", "sultan ahmed mosque", "sultan ahmet mosque", "sultanahmet camii", "sultanahmet mosque"]},
		{"type": "galata_tower", "name": "Galata Tower", "lat": 41.0256, "lon": 28.9742, "radius_m": 3000.0,
			"wiki_title": "Galata Tower", "height_m": 66.9, "clear_m": 25.0, "kind": "Tower",
			"aliases": ["galata tower", "galata kulesi"]},
	]
