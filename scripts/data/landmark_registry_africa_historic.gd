class_name LandmarkRegistryAfricaHistoric
extends RefCounted

## Registry entries for the africa_historic landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetAfricaHistoric.
## Origins: the Hassan Tower at the foot of the tower, Lalibela at the
## centre of the church (its rock mass stands 15 m above the trench floor), the Axum obelisk at its base (the Great Stele lies
## to the south), the others at the centre of the monument.

static func entries() -> Array:
	return [
		{"type": "koutoubia_mosque", "name": "Koutoubia Mosque", "lat": 31.6237, "lon": -7.9936, "radius_m": 4000.0,
			"wiki_title": "Koutoubia", "height_m": 77.0, "clear_m": 66.0, "yaw_deg": -22.0,
			"kind": "Mosque", "aliases": ["koutoubia mosque", "koutoubia", "kutubiyya", "masjid al-kutubiyya",
				"mosquée de la koutoubia", "جامع الكتبية"]},
		{"type": "hassan_tower_rabat", "name": "Hassan Tower", "lat": 34.0241, "lon": -6.8228, "radius_m": 4000.0,
			"wiki_title": "Hassan Tower", "height_m": 44.0, "clear_m": 135.0, "yaw_deg": -24.0,
			"kind": "Minaret", "aliases": ["hassan tower", "tour hassan", "hassan minaret", "صومعة حسان"]},
		{"type": "great_mosque_kairouan", "name": "Great Mosque of Kairouan", "lat": 35.6816, "lon": 10.104,
			"radius_m": 3500.0, "wiki_title": "Great Mosque of Kairouan", "height_m": 31.5, "clear_m": 75.0,
			"yaw_deg": -31.0, "kind": "Mosque", "aliases": ["great mosque of kairouan", "mosque of uqba",
				"uqba ibn nafi mosque", "sidi okba mosque", "grande mosquée de kairouan", "جامع عقبة بن نافع"]},
		{"type": "el_djem_amphitheatre", "name": "Amphitheatre of El Jem", "lat": 35.2964, "lon": 10.7069,
			"radius_m": 3500.0, "wiki_title": "Amphitheatre of El Djem", "height_m": 36.0, "clear_m": 85.0,
			"yaw_deg": -5.0, "kind": "Amphitheatre", "aliases": ["amphitheatre of el jem", "amphitheater of el jem",
				"el djem amphitheatre", "el jem amphitheatre", "el djem amphitheater", "el jem amphitheater",
				"colosseum of el jem", "thysdrus", "amphithéâtre d'el jem", "amphithéâtre d'el djem"]},
		{"type": "lalibela_st_george", "name": "Church of St George, Lalibela", "lat": 12.0315, "lon": 39.0412,
			"radius_m": 3000.0, "wiki_title": "Church of Saint George, Lalibela", "height_m": 15.0, "clear_m": 52.0,
			"kind": "Rock-hewn church", "aliases": ["church of st george, lalibela",
				"church of saint george, lalibela", "bete giyorgis", "bete giorgis", "beta giyorgis",
				"st george lalibela", "saint george lalibela", "ቤተ ጊዮርጊስ"]},
		{"type": "aksum_obelisk", "name": "Obelisk of Axum", "lat": 14.1321, "lon": 38.7193, "radius_m": 3000.0,
			"wiki_title": "Obelisk of Axum", "height_m": 24.6, "clear_m": 60.0,
			"kind": "Stela", "aliases": ["obelisk of axum", "obelisk of aksum", "axum obelisk", "aksum obelisk",
				"great stele of axum", "rome stele", "ሐውልተ አክሱም"]},
		{"type": "great_zimbabwe_enclosure", "name": "Great Zimbabwe (Great Enclosure)", "lat": -20.2729,
			"lon": 30.9343, "radius_m": 3500.0, "wiki_title": "Great Zimbabwe", "height_m": 11.0, "clear_m": 58.0,
			"kind": "Ruins", "aliases": ["great zimbabwe", "great enclosure", "zimbabwe ruins",
				"great zimbabwe national monument", "dzimba dza mabwe"]},
		{"type": "ait_benhaddou", "name": "Aït Benhaddou", "lat": 31.047, "lon": -7.1293, "radius_m": 3000.0,
			"wiki_title": "Aït Benhaddou", "height_m": 49.0, "clear_m": 100.0, "yaw_deg": 30.0,
			"kind": "Fortified village", "aliases": ["aït benhaddou", "ait benhaddou", "aït ben haddou",
				"ait ben haddou", "ait-ben-haddou", "ksar of ait benhaddou", "ksar ait benhaddou"]},
	]
