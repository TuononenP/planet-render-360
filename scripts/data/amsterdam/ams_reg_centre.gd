class_name AmsRegCentre
extends RefCounted

## Central Amsterdam landmark registry entries (0–1,150 m from Singel/Torensluis
## capital centre 52.37403, 4.88969): Dam Square, Grachtengordel churches &
## towers, Beurs van Berlage, Amsterdam Centraal, and East Waterfront historic
## ensemble. Measured from `capital_nl_14237403_18488969_detailed.osmb`.

static func entries() -> Array:
	return [
		# --- Tier 1: Primary & Dam / Canal Ring Core Icons ---
		{"type": "royal_palace_amsterdam", "name": "Royal Palace of Amsterdam",
			"lat": 52.37314, "lon": 4.89136, "radius_m": 6000.0,
			"wiki_title": "Royal Palace of Amsterdam", "height_m": 51.75, "yaw_deg": -88.5,
			"skyline_priority": 9, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 78.0, 62.0],
			"model_rects_m": [[0.0, 0.0, 78.0, 62.0]], "kind": "Palace",
			"aliases": ["royal palace amsterdam", "koninklijk paleis", "paleis op de dam",
				"royal palace of amsterdam"]},

		{"type": "westerkerk", "name": "Westerkerk & Westertoren",
			"lat": 52.37448, "lon": 4.88402, "radius_m": 6000.0,
			"wiki_title": "Westerkerk", "height_m": 86.0, "yaw_deg": 18.0,
			"skyline_priority": 9, "clear_m": 30.0, "clear_rect_m": [0.0, 0.0, 60.0, 34.0],
			"model_rects_m": [[0.0, 0.0, 60.0, 34.0]], "kind": "Church",
			"aliases": ["westerkerk", "westertoren", "westerkerk amsterdam"]},

		{"type": "amsterdam_centraal", "name": "Amsterdam Centraal",
			"lat": 52.379001, "lon": 4.900698, "radius_m": 6000.0,
			"wiki_title": "Amsterdam Centraal station", "height_m": 45.0, "yaw_deg": 30.1,
			"skyline_priority": 9, "clear_m": 20.0, "clear_rect_m": [0.0, -45.0, 148.0, 68.0],
			"model_rects_m": [[0.0, -45.0, 148.0, 68.0]], "kind": "Station", "capital": "NL",
			"aliases": ["amsterdam centraal", "amsterdam central station", "amsterdam centraal station"]},

		{"type": "nieuwe_kerk_amsterdam", "name": "De Nieuwe Kerk",
			"lat": 52.37390, "lon": 4.89175, "radius_m": 5000.0,
			"wiki_title": "Nieuwe Kerk (Amsterdam)", "height_m": 60.0, "yaw_deg": -18.6,
			"skyline_priority": 9, "clear_m": 22.0, "clear_rect_m": [0.0, 0.0, 64.0, 28.0],
			"model_rects_m": [[0.0, 0.0, 64.0, 28.0]], "kind": "Church",
			"aliases": ["nieuwe kerk", "de nieuwe kerk", "nieuwe kerk amsterdam"]},

		{"type": "magna_plaza", "name": "Magna Plaza",
			"lat": 52.37359, "lon": 4.89008, "radius_m": 4500.0,
			"wiki_title": "Magna Plaza", "height_m": 38.0, "yaw_deg": 20.8,
			"skyline_priority": 9, "clear_m": 22.0, "clear_rect_m": [0.0, 0.0, 38.0, 76.0],
			"model_rects_m": [[0.0, 0.0, 38.0, 76.0]], "kind": "Civic",
			"aliases": ["magna plaza", "hoofdpostkantoor amsterdam"]},

		{"type": "oude_kerk_amsterdam", "name": "Oude Kerk",
			"lat": 52.37436, "lon": 4.89794, "radius_m": 5000.0,
			"wiki_title": "Oude Kerk, Amsterdam", "height_m": 67.0, "yaw_deg": -4.0,
			"skyline_priority": 9, "clear_m": 30.0, "clear_rect_m": [0.0, 0.0, 76.0, 56.0],
			"model_rects_m": [[0.0, 0.0, 76.0, 56.0]], "kind": "Church",
			"aliases": ["oude kerk", "oude kerk amsterdam"]},

		# --- Tier 2: Dam Square Ensemble, Damrak & Major Towers ---
		{"type": "beurs_van_berlage", "name": "Beurs van Berlage",
			"lat": 52.37513, "lon": 4.89622, "radius_m": 5000.0,
			"wiki_title": "Beurs van Berlage", "height_m": 40.0, "yaw_deg": 45.1,
			"skyline_priority": 7, "clear_m": 24.0, "clear_rect_m": [0.0, 0.0, 56.0, 140.0],
			"model_rects_m": [[0.0, 0.0, 56.0, 140.0]], "kind": "Civic",
			"aliases": ["beurs van berlage", "berlage exchange"]},

		{"type": "nationaal_monument_dam", "name": "Nationaal Monument",
			"lat": 52.37282, "lon": 4.89369, "radius_m": 4500.0,
			"wiki_title": "National Monument (Amsterdam)", "height_m": 22.0, "yaw_deg": 91.5,
			"skyline_priority": 7, "clear_m": 16.0, "tree_clear_m": 22.0, "kind": "Monument",
			"aliases": ["nationaal monument", "national monument amsterdam", "dam monument"]},

		{"type": "de_bijenkorf_amsterdam", "name": "De Bijenkorf",
			"lat": 52.37368, "lon": 4.89418, "radius_m": 4500.0,
			"wiki_title": "De Bijenkorf", "height_m": 34.0, "yaw_deg": 39.2,
			"skyline_priority": 7, "clear_m": 22.0, "clear_rect_m": [0.0, 0.0, 40.0, 106.0],
			"model_rects_m": [[0.0, 0.0, 40.0, 106.0]], "kind": "Commercial",
			"aliases": ["de bijenkorf", "bijenkorf amsterdam"]},

		{"type": "sint_nicolaasbasiliek", "name": "Basilica of Saint Nicholas",
			"lat": 52.37637, "lon": 4.90123, "radius_m": 5000.0,
			"wiki_title": "Basilica of Saint Nicholas, Amsterdam", "height_m": 58.0, "yaw_deg": 150.3,
			"skyline_priority": 7, "clear_m": 20.0, "clear_rect_m": [0.0, 0.0, 24.0, 50.0],
			"model_rects_m": [[0.0, 0.0, 24.0, 50.0]], "kind": "Church",
			"aliases": ["sint-nicolaasbasiliek", "basilica of saint nicholas", "st nicholas church amsterdam"]},

		{"type": "zuiderkerk", "name": "Zuiderkerk",
			"lat": 52.37029, "lon": 4.89975, "radius_m": 5000.0,
			"wiki_title": "Zuiderkerk", "height_m": 61.2, "yaw_deg": 32.0,
			"skyline_priority": 7, "clear_m": 26.0, "clear_rect_m": [0.0, 0.0, 44.0, 44.0],
			"model_rects_m": [[0.0, 0.0, 44.0, 44.0]], "kind": "Church",
			"aliases": ["zuiderkerk", "zuiderkerkstoren"]},

		{"type": "munttoren", "name": "Munttoren",
			"lat": 52.36706, "lon": 4.89322, "radius_m": 4500.0,
			"wiki_title": "Munttoren", "height_m": 40.0, "yaw_deg": 18.0,
			"skyline_priority": 7, "clear_m": 12.0, "kind": "Tower",
			"aliases": ["munttoren", "mint tower amsterdam"]},

		# --- Tier 3 & 4: Historic Canal Towers, Churches & East Waterfront ---
		{"type": "waag_amsterdam", "name": "De Waag",
			"lat": 52.37277, "lon": 4.90032, "radius_m": 4500.0,
			"wiki_title": "Waag (Amsterdam)", "height_m": 28.0, "yaw_deg": 12.0,
			"skyline_priority": 5, "clear_m": 18.0, "tree_clear_m": 22.0, "kind": "Castle",
			"aliases": ["waag", "de waag", "waag amsterdam", "nieuwmarkt waag"]},

		{"type": "koepelkerk_amsterdam", "name": "Koepelkerk (Ronde Lutherse Kerk)",
			"lat": 52.37794, "lon": 4.89383, "radius_m": 4500.0,
			"wiki_title": "Ronde Lutherse Kerk", "height_m": 36.0, "yaw_deg": 24.0,
			"skyline_priority": 5, "clear_m": 24.0, "kind": "Church",
			"aliases": ["koepelkerk", "ronde lutherse kerk", "round lutheran church"]},

		{"type": "montelbaanstoren", "name": "Montelbaanstoren",
			"lat": 52.37204, "lon": 4.90566, "radius_m": 4500.0,
			"wiki_title": "Montelbaanstoren", "height_m": 48.0, "yaw_deg": 22.0,
			"skyline_priority": 5, "clear_m": 14.0, "kind": "Tower",
			"aliases": ["montelbaanstoren", "silly jack tower"]},

		{"type": "scheepvaarthuis", "name": "Scheepvaarthuis",
			"lat": 52.37432, "lon": 4.90413, "radius_m": 4500.0,
			"wiki_title": "Scheepvaarthuis", "height_m": 35.0, "yaw_deg": 18.0,
			"skyline_priority": 5, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 62.0, 86.0],
			"model_rects_m": [[0.0, 0.0, 62.0, 86.0]], "kind": "Palace",
			"aliases": ["scheepvaarthuis", "grand hotel amrath", "shipping house amsterdam"]},

		{"type": "noorderkerk", "name": "Noorderkerk",
			"lat": 52.37964, "lon": 4.88643, "radius_m": 4500.0,
			"wiki_title": "Noorderkerk", "height_m": 34.0, "yaw_deg": 18.0,
			"skyline_priority": 3, "clear_m": 24.0, "kind": "Church",
			"aliases": ["noorderkerk", "noorderkerk amsterdam"]},

		{"type": "de_krijtberg", "name": "De Krijtberg",
			"lat": 52.36889, "lon": 4.88783, "radius_m": 4500.0,
			"wiki_title": "De Krijtberg", "height_m": 53.0, "yaw_deg": 14.0,
			"skyline_priority": 3, "clear_m": 18.0, "kind": "Church",
			"aliases": ["de krijtberg", "krijtberg", "franciscus xaveriuskerk"]},

		{"type": "schreierstoren", "name": "Schreierstoren",
			"lat": 52.37636, "lon": 4.90224, "radius_m": 4500.0,
			"wiki_title": "Schreierstoren", "height_m": 20.0, "yaw_deg": 26.0,
			"skyline_priority": 3, "clear_m": 12.0, "kind": "Tower",
			"aliases": ["schreierstoren", "weepers tower"]},
	]
