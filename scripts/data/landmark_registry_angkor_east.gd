class_name LandmarkRegistryAngkorEast
extends RefCounted

## Siem Reap batch C: see LandmarkSetAngkorEast for the builders. The
## temples east and north-east of Angkor Thom: Preah Khan, Ta Keo, Prasat
## Kravan, Banteay Samre and the Srah Srang landing terrace. Every model
## is built facing +X (east), the way each of these sites faces.

static func entries() -> Array:
	return [
		{"type": "preah_khan_angkor", "name": "Preah Khan (Angkor)",
			"lat": 13.4620, "lon": 103.8716, "radius_m": 4500.0,
			"wiki_title": "Preah Khan", "height_m": 17.0, "clear_m": 125.0,
			"kind": "Temple",
			"aliases": ["preah khan (angkor)", "preah khan angkor", "preah khan temple",
				"prasat preah khan", "preah khan of angkor", "ប្រាសាទព្រះខ័ន"]},
		{"type": "ta_keo", "name": "Ta Keo",
			"lat": 13.4447, "lon": 103.8826, "radius_m": 4500.0,
			"wiki_title": "Ta Keo", "height_m": 45.0, "clear_m": 85.0,
			"kind": "Temple",
			"aliases": ["ta keo", "ta keo temple", "prasat ta keo", "ប្រាសាទតាកែវ"]},
		{"type": "prasat_kravan", "name": "Prasat Kravan",
			"lat": 13.4197, "lon": 103.8999, "radius_m": 4000.0,
			"wiki_title": "Prasat Kravan", "height_m": 15.0, "clear_m": 40.0,
			"kind": "Temple",
			"aliases": ["prasat kravan", "kravan temple", "cardamom sanctuary", "ប្រាសាទក្រវ៉ាន់"]},
		{"type": "banteay_samre", "name": "Banteay Samre",
			"lat": 13.4422, "lon": 103.9592, "radius_m": 4000.0,
			"wiki_title": "Banteay Samré", "height_m": 21.0, "clear_m": 60.0,
			"kind": "Temple",
			"aliases": ["banteay samre", "banteay samré", "banteay samre temple", "citadel of the samre",
				"ប្រាសាទបន្ទាយសំរែ"]},
		{"type": "srah_srang", "name": "Srah Srang",
			"lat": 13.4303, "lon": 103.9033, "radius_m": 4000.0,
			"wiki_title": "Srah Srang", "height_m": 4.5, "clear_m": 70.0,
			"kind": "Terrace",
			"aliases": ["srah srang", "srah srang baray", "pool of ablutions", "bath pool angkor",
				"ស្រះស្រង់"]},
	]
