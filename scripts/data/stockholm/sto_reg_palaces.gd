extends RefCounted

## Stockholm palaces, theatres and museums on the Norrström waterfront
## (plan S-1). Built by sweden_stockholm/palaces/sto_set_palaces.gd.

static func entries() -> Array:
	return [
		{"type": "royal_opera_stockholm", "name": "Royal Swedish Opera", "lat": 59.329699, "lon": 18.070551,
			"radius_m": 4000.0, "wiki_title": "Royal Swedish Opera", "height_m": 41.5, "clear_m": 45.0,
			"yaw_deg": -25.2, "kind": "Theatre", "aliases": ["royal swedish opera", "kungliga operan"]},
		{"type": "grand_hotel_stockholm", "name": "Grand Hôtel Stockholm", "lat": 59.329835, "lon": 18.075627,
			"radius_m": 4000.0, "wiki_title": "Grand Hôtel (Stockholm)", "height_m": 42.5, "clear_m": 40.0,
			"clear_offsets_m": [[55.0, 22.0]], "yaw_deg": 37.5, "kind": "Hotel", "aliases": ["grand hôtel stockholm", "grand hotel stockholm"]},
		{"type": "riddarhuset_stockholm", "name": "Riddarhuset", "lat": 59.32595, "lon": 18.06579,
			"radius_m": 4000.0, "wiki_title": "House of Nobility (Sweden)", "height_m": 25.5, "clear_m": 32.0, "clear_rect_m": [0.0, -3.0, 33.0, 20.0],
			"yaw_deg": -39.3, "kind": "Palace", "aliases": ["riddarhuset", "house of nobility stockholm"]},
		{"type": "wrangel_palace", "name": "Wrangel Palace", "lat": 59.32512, "lon": 18.06282,
			"radius_m": 4000.0, "wiki_title": "Wrangel Palace", "height_m": 32.5, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 30.0, 27.0],
			"yaw_deg": -12.5, "kind": "Palace", "aliases": ["wrangel palace", "wrangelska palatset"]},
		{"type": "bonde_palace", "name": "Bonde Palace", "lat": 59.32625, "lon": 18.06646,
			"radius_m": 4000.0, "wiki_title": "Bonde Palace", "height_m": 23.5, "clear_m": 30.0, "clear_rect_m": [0.0, -2.0, 18.0, 40.0],
			"yaw_deg": -39.1, "kind": "Palace", "aliases": ["bonde palace", "bondeska palatset"]},
		{"type": "nationalmuseum_stockholm", "name": "Nationalmuseum", "lat": 59.328481, "lon": 18.078183,
			"radius_m": 4000.0, "wiki_title": "Nationalmuseum", "height_m": 33.5, "clear_m": 42.0,
			"yaw_deg": -39.1, "kind": "Museum", "aliases": ["nationalmuseum stockholm", "nationalmuseum"]},
	]
