extends RefCounted

## Stockholm towers and lifts (plan S-1). Built by
## sweden_stockholm/towers/sto_set_towers.gd. Skyline items keep
## `skyline_priority`; Hötorgsskraporna are one grouped entry (the five
## slabs stand in one model, `clear_offsets_m` clears each footprint).

static func entries() -> Array:
	return [
		{"type": "hotorgsskraporna", "skyline_priority": 1, "name": "Hötorgsskraporna", "lat": 59.333896, "lon": 18.064068,
			"radius_m": 4000.0, "wiki_title": "Hötorget buildings", "height_m": 61.0, "clear_m": 17.0,
			"yaw_deg": -25.2, "kind": "Office",
			"clear_offsets_m": [[-23.9, -83.4], [-11.6, -42.7], [14.3, 40.0], [26.0, 83.1]],
			"aliases": ["hötorgsskraporna", "hötorgsskrapa 1", "hötorgsskrapa 2", "hötorgsskrapa 3",
				"hötorgsskrapa 4", "hötorgsskrapa 5", "hotorget buildings"]},
		{"type": "katarinahissen", "name": "Katarinahissen", "lat": 59.319919, "lon": 18.073170,
			"radius_m": 4000.0, "wiki_title": "Katarina Elevator", "height_m": 42.5, "clear_m": 12.0,
			"yaw_deg": 96.5, "kind": "Elevator", "aliases": ["katarinahissen", "katarina elevator"]},
		{"type": "kastellet_stockholm", "name": "Kastellet, Stockholm", "lat": 59.322625, "lon": 18.090165,
			"radius_m": 4000.0, "wiki_title": "Kastellet, Stockholm", "height_m": 20.0, "clear_m": 19.0,
			"kind": "Castle", "aliases": ["kastellet, stockholm", "kastellet stockholm", "kastellholmen kastellet"]},
		{"type": "soder_torn", "skyline_priority": 1, "name": "Söder Torn", "lat": 59.315003, "lon": 18.069673,
			"radius_m": 4000.0, "wiki_title": "Söder Torn", "height_m": 86.0, "clear_m": 16.0,
			"yaw_deg": -13.3, "kind": "Tower", "aliases": ["söder torn", "soder torn"]},
	]
