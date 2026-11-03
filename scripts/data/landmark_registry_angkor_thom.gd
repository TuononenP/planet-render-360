class_name LandmarkRegistryAngkorThom
extends RefCounted

## Siem Reap batch A: the temples of the Royal Palace and Royal Square of
## Angkor Thom, and the small sanctuaries by the Victory Gate road. See
## LandmarkSetAngkorThom for the builders. Coordinates are WGS84 of the
## model origin (Baphuon: its pyramid, not its 375 m enclosure).

static func entries() -> Array:
	return [
		{"type": "baphuon", "name": "Baphuon",
			"lat": 13.4436, "lon": 103.8558, "radius_m": 4500.0,
			"wiki_title": "Baphuon", "height_m": 34.0, "clear_m": 190.0,
			"kind": "Temple mountain",
			"aliases": ["baphuon", "baphuon temple", "prasat baphuon", "golden mountain angkor", "ប្រាសាទបាពួន"]},
		{"type": "phimeanakas", "name": "Phimeanakas",
			"lat": 13.4456, "lon": 103.8558, "radius_m": 4500.0,
			"wiki_title": "Phimeanakas", "height_m": 21.0, "clear_m": 35.0,
			"kind": "Temple",
			"aliases": ["phimeanakas", "phimeanakas temple", "vimean akas", "prasat phimeanakas", "ប្រាសាទភិមានអាកាស"]},
		{"type": "terrace_of_the_elephants", "name": "Terrace of the Elephants",
			"lat": 13.4456, "lon": 103.8586, "radius_m": 4500.0,
			"wiki_title": "Terrace of the Elephants", "height_m": 4.2, "clear_m": 185.0,
			"kind": "Terrace",
			"aliases": ["terrace of the elephants", "elephant terrace", "elephants terrace angkor thom",
				"terrace of elephants", "ទីលានដំរី"]},
		{"type": "terrace_of_the_leper_king", "name": "Terrace of the Leper King",
			"lat": 13.4476, "lon": 103.8587, "radius_m": 4500.0,
			"wiki_title": "Terrace of the Leper King", "height_m": 7.6, "clear_m": 30.0,
			"kind": "Terrace",
			"aliases": ["terrace of the leper king", "leper king terrace", "leper king", "dharmaraja terrace",
				"ទីលានស្តេចឃ្លង់"]},
		{"type": "preah_palilay", "name": "Preah Palilay",
			"lat": 13.4489, "lon": 103.8550, "radius_m": 4500.0,
			"wiki_title": "Preah Palilay", "height_m": 15.0, "clear_m": 45.0,
			"kind": "Temple",
			"aliases": ["preah palilay", "preah pali lay", "prasat preah palilay", "ប្រាសាទព្រះបាលីឡៃយ៍"]},
		{"type": "thommanon", "name": "Thommanon",
			"lat": 13.4468, "lon": 103.8774, "radius_m": 4500.0,
			"wiki_title": "Thommanon", "height_m": 13.0, "clear_m": 45.0,
			"kind": "Temple",
			"aliases": ["thommanon", "thommanon temple", "prasat thommanon", "tommanon", "ប្រាសាទធម្មនន្ទ"]},
		{"type": "chau_say_tevoda", "name": "Chau Say Tevoda",
			"lat": 13.4454, "lon": 103.8777, "radius_m": 4500.0,
			"wiki_title": "Chau Say Tevoda", "height_m": 12.5, "clear_m": 45.0,
			"kind": "Temple",
			"aliases": ["chau say tevoda", "chau say tevoda temple", "prasat chau say tevoda", "chao say tevoda",
				"ប្រាសាទចៅសាយទេវតា"]},
	]
