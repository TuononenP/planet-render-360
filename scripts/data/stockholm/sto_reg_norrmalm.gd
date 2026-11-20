extends RefCounted

## Stockholm Tier A landmarks in Norrmalm, Helgeandsholmen and the Södermalm skyline (plan S-3).
## Built by sweden_stockholm/norrmalm/sto_set_norrmalm.gd.

static func entries() -> Array:
	return [
		{"type": "dramaten", "name": "Royal Dramatic Theatre", "lat": 59.333280, "lon": 18.077007,
			"radius_m": 4000.0, "wiki_title": "Royal Dramatic Theatre", "height_m": 37.0, "clear_m": 38.0,
			"yaw_deg": 22.6, "kind": "Theatre", "aliases": ["dramaten", "royal dramatic theatre",
				"kungliga dramatiska teatern", "dramatiska teatern"]},
		{"type": "kungstornen", "skyline_priority": 1, "name": "Kungstornen", "lat": 59.336072, "lon": 18.065625,
			"radius_m": 4000.0, "wiki_title": "Kungstornen", "height_m": 61.0, "clear_m": 14.0,
			"yaw_deg": -7.1, "kind": "Office", "clear_offsets_m": [[2.0, 44.0]],
			"aliases": ["kungstornen", "kungsgatan towers", "norra kungstornet", "södra kungstornet",
				"sodra kungstornet", "kings towers stockholm"]},
		{"type": "kulturhuset_sergels_torg", "name": "Kulturhuset and Sergels torg", "lat": 59.332017,
			"lon": 18.064954, "radius_m": 4000.0, "wiki_title": "Kulturhuset", "height_m": 37.5,
			"clear_m": 12.0, "yaw_deg": -26.0, "clear_rect_m": [0.0, -27.0, 84.0, 43.0],
			"kind": "Cultural centre", "aliases": ["kulturhuset", "kulturhuset stockholm", "sergels torg",
				"kristallvertikalaccent", "stockholm cultural centre"]},
		{"type": "rosenbad", "name": "Rosenbad", "lat": 59.328566, "lon": 18.065800,
			"radius_m": 4000.0, "wiki_title": "Rosenbad", "height_m": 38.0, "clear_m": 47.0,
			"clear_rect_m": [0.0, 0.0, 44.0, 35.0], "yaw_deg": -27.4, "kind": "Government",
			"aliases": ["rosenbad", "rosenbad stockholm", "swedish government offices", "regeringskansliet"]},
		{"type": "sagerska_huset", "name": "Sagerska huset", "lat": 59.328762, "lon": 18.067287,
			"radius_m": 4000.0, "wiki_title": "Sagerska palatset", "height_m": 17.4, "clear_m": 17.0,
			"clear_rect_m": [0.0, 0.0, 13.0, 10.8], "yaw_deg": 62.5, "kind": "Palace",
			"aliases": ["sagerska huset", "sagerska palatset", "sagerska house"]},
		{"type": "arvfurstens_palats", "name": "Arvfurstens palats", "lat": 59.329033, "lon": 18.067575,
			"radius_m": 4000.0, "wiki_title": "Arvfurstens palats", "height_m": 25.0, "clear_m": 38.0,
			"clear_rect_m": [0.0, 0.0, 34.0, 20.5], "yaw_deg": 61.9, "kind": "Palace",
			"aliases": ["arvfurstens palats", "arvfurstens palace", "heir apparent's palace", "arvfurstens"]},
		{"type": "stockholm_waterfront", "name": "Stockholm Waterfront", "lat": 59.329677, "lon": 18.055838,
			"radius_m": 4000.0, "wiki_title": "Stockholm Waterfront Congress Centre", "height_m": 42.0,
			"clear_m": 95.0, "clear_rect_m": [0.0, 0.0, 92.0, 38.0], "yaw_deg": 57.5,
			"kind": "Congress centre", "aliases": ["stockholm waterfront", "stockholm waterfront congress centre",
				"radisson blu waterfront", "waterfront congress centre"]},
	]
