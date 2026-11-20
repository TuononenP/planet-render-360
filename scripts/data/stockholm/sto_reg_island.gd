extends RefCounted

## Stockholm Skeppsholmen (af Chapman, Skeppsholmskyrkan, Moderna Museet; plan S-3) and the
## Riddarholmen island set beside the church (Birger Jarls torn, Norstedtshuset, Evert Taubes terrass; plan S-2).
## Built by sweden_stockholm/island/sto_set_island.gd.

static func entries() -> Array:
	return [
		{"type": "af_chapman", "name": "af Chapman", "lat": 59.325287, "lon": 18.080226,
			"radius_m": 3500.0, "wiki_title": "Af Chapman", "height_m": 44.0,
			"kind": "Museum ship", "clear_m": 42.0, "yaw_deg": 79.0, "base": "water", "icon": true,
			"aliases": ["af chapman", "af chapman ship", "full-rigged ship af chapman"]},
		{"type": "skeppsholmen_church", "name": "Skeppsholmen Church", "lat": 59.326383, "lon": 18.082465,
			"radius_m": 3500.0, "wiki_title": "Skeppsholm Church", "height_m": 36.5,
			"kind": "Church", "clear_m": 26.0, "yaw_deg": -82.1,
			"aliases": ["skeppsholmen church", "skeppsholmskyrkan", "eric ericsonhallen", "carl johans kyrka"]},
		{"type": "moderna_museet", "name": "Moderna Museet", "lat": 59.326221, "lon": 18.084287,
			"radius_m": 3500.0, "wiki_title": "Moderna Museet", "height_m": 14.0,
			"kind": "Museum", "clear_m": 60.0, "clear_rect_m": [0.0, 0.0, 142.0, 48.0], "yaw_deg": 56.5,
			"aliases": ["moderna museet", "moderna museet stockholm", "museum of modern art stockholm"]},
		{"type": "birger_jarls_torn", "name": "Birger Jarls torn", "lat": 59.325883, "lon": 18.061631,
			"radius_m": 3000.0, "wiki_title": "Birger Jarls torn", "height_m": 19.5,
			"kind": "Tower", "clear_m": 10.0,
			"aliases": ["birger jarls torn", "birger jarl tower", "birger jarls tower"]},
		{"type": "norstedts_building", "name": "Norstedtshuset", "lat": 59.326017, "lon": 18.063129,
			"radius_m": 3000.0, "wiki_title": "Norstedtshuset", "height_m": 39.0,
			"kind": "Office building", "clear_m": 38.0,
			"aliases": ["norstedtshuset", "norstedts building", "norstedts"]},
		{"type": "evert_taubes_terrass", "name": "Evert Taubes terrass", "lat": 59.32493, "lon": 18.061899,
			"radius_m": 3000.0, "wiki_title": "Evert Taubes terrass", "height_m": 4.7,
			"kind": "Terrace", "clear_m": 12.0,
			"aliases": ["evert taubes terrass", "evert taube terrace", "evert taube statue"]},
	]
