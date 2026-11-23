extends RefCounted

## Turku harbour, Forum Marinum & maritime landmark entries.
## Built by LandmarkSetFinlandTurku; aggregated by LandmarkRegistryFinlandTurku.

static func entries() -> Array:
	return [
		{"type": "suomen_joutsen", "name": "Suomen Joutsen", "lat": 60.436330, "lon": 22.237154,
			"radius_m": 3000.0, "wiki_title": "Suomen Joutsen", "height_m": 44.0,
			"kind": "Museum ship", "clear_m": 48.0, "yaw_deg": 146.1, "base": "water", "icon": true,
			"aliases": ["suomen joutsen", "swan of finland"]},
		{"type": "port_of_turku_terminals", "name": "Port of Turku Terminals", "lat": 60.434800, "lon": 22.221500,
			"radius_m": 4500.0, "wiki_title": "Port of Turku", "height_m": 15.6,
			"kind": "Harbour", "clear_m": 16.0, "clear_rect_m": [0.0, 0.0, 162.0, 64.0], "yaw_deg": -21.0,
			"aliases": ["port of turku terminals", "port of turku", "turun satama", "linnansatama"]},
		{"type": "forum_marinum", "name": "Forum Marinum", "lat": 60.436800, "lon": 22.236150,
			"radius_m": 3200.0, "wiki_title": "Forum Marinum", "height_m": 15.8,
			"kind": "Museum", "clear_m": 14.0, "clear_rect_m": [0.0, 0.0, 98.0, 38.0], "yaw_deg": -34.0,
			"aliases": ["forum marinum", "kruununmakasiini", "linnanpuomi"]},
		{"type": "sigyn_bore_ships", "name": "Museum Ships Sigyn and Bore", "lat": 60.435500, "lon": 22.235500,
			"radius_m": 3500.0, "wiki_title": "Sigyn (barque)", "height_m": 32.0,
			"kind": "Ship", "clear_m": 16.0, "clear_rect_m": [0.0, 0.0, 175.0, 22.0], "yaw_deg": -34.0,
			"base": "water",
			"aliases": ["museum ships sigyn and bore", "sigyn barque", "s/s bore", "hostel ship bore"]},
		{"type": "telakkaranta_linnanfaltti", "name": "Telakkaranta and Linnanfältti", "lat": 60.436600, "lon": 22.241200,
			"radius_m": 2500.0, "wiki_title": "Turku", "height_m": 27.0,
			"kind": "Waterfront", "clear_m": 12.0, "clear_rect_m": [0.0, 0.0, 23.0, 13.0], "yaw_deg": -34.0,
			"aliases": ["telakkaranta and linnanfältti", "telakkaranta turku", "linnanfältti"]},
		{"type": "ruissalo_villas_spa", "name": "Ruissalo Spa and Villas", "lat": 60.433150, "lon": 22.173850,
			"radius_m": 3500.0, "wiki_title": "Ruissalo", "height_m": 14.1,
			"kind": "Historic", "clear_m": 14.0, "clear_rect_m": [0.0, 0.0, 25.0, 12.5], "yaw_deg": -20.0,
			"aliases": ["ruissalo spa and villas", "ruissalon kylpylä", "ruissalo villas"]},
	]
