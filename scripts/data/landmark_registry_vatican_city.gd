class_name LandmarkRegistryVatican
extends RefCounted

## Registry entries for the Vatican City landmark batch (the palaces,
## hall, gardens and walls round St Peter's), in the format of
## LocationData.landmarks(). Types are built by LandmarkSetVatican. The
## positions come from OpenStreetMap footprints; yaw_deg turns each model
## (front facing +Z, south) onto its real bearing.

static func entries() -> Array:
	return [
		{"type": "apostolic_palace", "name": "Apostolic Palace", "lat": 41.90437, "lon": 12.45619,
			"radius_m": 3500.0, "wiki_title": "Apostolic Palace", "height_m": 35.8, "kind": "Palace",
			"clear_m": 150.0,
			"aliases": ["apostolic palace", "palazzo apostolico", "vatican museums", "musei vaticani",
				"cortile della pigna", "belvedere courtyard", "cortile del belvedere", "pigna courtyard"]},
		{"type": "paul_vi_audience_hall", "name": "Paul VI Audience Hall", "lat": 41.90062, "lon": 12.45468,
			"radius_m": 3500.0, "wiki_title": "Paul VI Audience Hall", "height_m": 20.0, "kind": "Hall",
			"clear_m": 135.0, "yaw_deg": -11.2,
			"aliases": ["paul vi audience hall", "paul vi hall", "aula paolo vi", "nervi hall", "sala nervi",
				"casa santa marta", "domus sanctae marthae"]},
		{"type": "governorate_palace", "name": "Palace of the Governorate", "lat": 41.90231, "lon": 12.45118,
			"radius_m": 3500.0, "wiki_title": "Palace of the Governorate", "height_m": 30.6, "kind": "Palace",
			"clear_m": 80.0, "yaw_deg": -80.6,
			"aliases": ["palace of the governorate", "palazzo del governatorato", "governatorato",
				"governorate of vatican city"]},
		{"type": "vatican_gardens", "name": "Vatican Gardens", "lat": 41.90417, "lon": 12.45257,
			"radius_m": 3500.0, "wiki_title": "Vatican Gardens", "height_m": 14.0, "kind": "Gardens",
			"clear_m": 155.0, "yaw_deg": -31.5,
			"aliases": ["vatican gardens", "giardini vaticani", "casina pio iv", "casina of pius iv",
				"villa pia", "pontifical academy of sciences"]},
		{"type": "leonine_wall", "name": "Leonine Wall and Torre San Giovanni", "lat": 41.90154, "lon": 12.44753,
			"radius_m": 3500.0, "wiki_title": "Leonine Wall", "height_m": 30.0, "kind": "Fortification",
			"clear_m": 160.0,
			"aliases": ["leonine wall", "leonine walls", "mura leonine", "torre san giovanni",
				"torre di san giovanni", "leonine city wall"]},
	]
