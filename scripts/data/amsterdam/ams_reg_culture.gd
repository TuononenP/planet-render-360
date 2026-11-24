class_name AmsRegCulture
extends RefCounted

## Cultural, Museumplein, South Canal Ring, Amstel & Jewish Quarter landmark
## registry entries for Amsterdam (`AMS-3.1`–`AMS-3.3`).

static func entries() -> Array:
	return [
		# --- Museumplein Ensemble ---
		{"type": "rijksmuseum", "name": "Rijksmuseum",
			"lat": 52.36000, "lon": 4.88522, "radius_m": 6000.0,
			"wiki_title": "Rijksmuseum", "height_m": 60.0, "yaw_deg": 32.0,
			"skyline_priority": 9, "clear_m": 58.0, "clear_rect_m": [0.0, 0.0, 152.0, 96.0],
			"model_rects_m": [[0.0, 0.0, 152.0, 96.0]], "tree_clear_m": 42.0, "kind": "Museum",
			"aliases": ["rijksmuseum", "rijksmuseum amsterdam"]},

		{"type": "van_gogh_museum", "name": "Van Gogh Museum",
			"lat": 52.35842, "lon": 4.88108, "radius_m": 5500.0,
			"wiki_title": "Van Gogh Museum", "height_m": 20.0, "yaw_deg": 32.0,
			"skyline_priority": 3, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 74.0, 48.0],
			"model_rects_m": [[0.0, 0.0, 74.0, 48.0]], "kind": "Museum",
			"aliases": ["van gogh museum", "van gogh museum amsterdam"]},

		{"type": "stedelijk_museum", "name": "Stedelijk Museum Amsterdam",
			"lat": 52.35802, "lon": 4.87976, "radius_m": 5500.0,
			"wiki_title": "Stedelijk Museum Amsterdam", "height_m": 22.0, "yaw_deg": 32.0,
			"skyline_priority": 3, "clear_m": 34.0, "clear_rect_m": [0.0, 0.0, 86.0, 56.0],
			"model_rects_m": [[0.0, 0.0, 86.0, 56.0]], "kind": "Museum",
			"aliases": ["stedelijk museum", "stedelijk museum amsterdam"]},

		{"type": "concertgebouw", "name": "Het Concertgebouw",
			"lat": 52.35627, "lon": 4.87907, "radius_m": 5500.0,
			"wiki_title": "Concertgebouw, Amsterdam", "height_m": 26.0, "yaw_deg": 32.0,
			"skyline_priority": 3, "clear_m": 38.0, "clear_rect_m": [0.0, 0.0, 72.0, 68.0],
			"model_rects_m": [[0.0, 0.0, 72.0, 68.0]], "kind": "Concert hall",
			"aliases": ["concertgebouw", "het concertgebouw", "royal concertgebouw"]},

		# --- South Canal Ring & Leidseplein ---
		{"type": "pathe_tuschinski", "name": "Pathé Tuschinski",
			"lat": 52.36647, "lon": 4.89445, "radius_m": 4500.0,
			"wiki_title": "Tuschinski Theatre", "height_m": 36.0, "yaw_deg": 14.0,
			"skyline_priority": 3, "clear_m": 22.0, "clear_rect_m": [0.0, 0.0, 34.0, 54.0],
			"model_rects_m": [[0.0, 0.0, 34.0, 54.0]], "kind": "Theatre",
			"aliases": ["pathe tuschinski", "pathé tuschinski", "tuschinski theatre"]},

		{"type": "de_bazel", "name": "De Bazel",
			"lat": 52.36458, "lon": 4.89221, "radius_m": 4500.0,
			"wiki_title": "De Bazel", "height_m": 37.5, "yaw_deg": 12.0,
			"skyline_priority": 3, "clear_m": 34.0, "clear_rect_m": [0.0, 0.0, 48.0, 102.0],
			"model_rects_m": [[0.0, 0.0, 48.0, 102.0]], "kind": "Civic",
			"aliases": ["de bazel", "stadsarchief amsterdam"]},

		{"type": "stadsschouwburg_amsterdam", "name": "Stadsschouwburg & American Hotel",
			"lat": 52.36436, "lon": 4.88195, "radius_m": 4500.0,
			"wiki_title": "Stadsschouwburg, Amsterdam", "height_m": 28.0, "yaw_deg": 34.0,
			"skyline_priority": 3, "clear_m": 34.0, "clear_rect_m": [0.0, 0.0, 74.0, 88.0],
			"model_rects_m": [[0.0, 0.0, 74.0, 88.0]], "kind": "Theatre",
			"aliases": ["stadsschouwburg", "stadsschouwburg amsterdam", "internationaal theater amsterdam",
				"american hotel amsterdam"]},

		{"type": "heineken_experience", "name": "Heineken Experience",
			"lat": 52.35783, "lon": 4.89183, "radius_m": 5000.0,
			"wiki_title": "Heineken Experience", "height_m": 26.0, "yaw_deg": 20.0,
			"skyline_priority": 3, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 78.0, 56.0],
			"model_rects_m": [[0.0, 0.0, 78.0, 56.0]], "kind": "Museum",
			"aliases": ["heineken experience", "heineken brewery amsterdam"]},

		{"type": "vondelkerk", "name": "Vondelkerk",
			"lat": 52.36048, "lon": 4.87380, "radius_m": 5000.0,
			"wiki_title": "Vondelkerk", "height_m": 50.0, "yaw_deg": 32.0,
			"skyline_priority": 3, "clear_m": 24.0, "kind": "Church",
			"aliases": ["vondelkerk"]},

		# --- Amstel River & Jewish Cultural Quarter ---
		{"type": "stopera_amsterdam", "name": "Stopera (National Opera & Ballet)",
			"lat": 52.36765, "lon": 4.90125, "radius_m": 5000.0,
			"wiki_title": "Stopera", "height_m": 28.0, "yaw_deg": 38.0,
			"skyline_priority": 5, "clear_m": 52.0, "clear_rect_m": [0.0, 0.0, 118.0, 124.0],
			"model_rects_m": [[0.0, 0.0, 118.0, 124.0]], "kind": "Opera house",
			"aliases": ["stopera", "nationale opera en ballet", "dutch national opera"]},

		{"type": "hart_amstelhof", "name": "H'ART Museum (Amstelhof)",
			"lat": 52.36522, "lon": 4.90244, "radius_m": 5000.0,
			"wiki_title": "H'ART Museum", "height_m": 20.0, "yaw_deg": 24.0,
			"skyline_priority": 3, "clear_m": 38.0, "clear_rect_m": [0.0, 0.0, 100.0, 68.0],
			"model_rects_m": [[0.0, 0.0, 100.0, 68.0]], "kind": "Museum",
			"aliases": ["hart museum", "h'art museum", "hermitage amsterdam", "amstelhof"]},

		{"type": "theater_carre", "name": "Koninklijk Theater Carré",
			"lat": 52.36220, "lon": 4.90440, "radius_m": 5000.0,
			"wiki_title": "Carré Theatre", "height_m": 26.0, "yaw_deg": 24.0,
			"skyline_priority": 3, "clear_m": 30.0, "clear_rect_m": [0.0, 0.0, 56.0, 64.0],
			"model_rects_m": [[0.0, 0.0, 56.0, 64.0]], "kind": "Theatre",
			"aliases": ["theater carre", "koninklijk theater carré", "carre theatre"]},

		{"type": "amstel_hotel", "name": "InterContinental Amstel Hotel",
			"lat": 52.36000, "lon": 4.90555, "radius_m": 5000.0,
			"wiki_title": "Amstel Hotel", "height_m": 28.0, "yaw_deg": 24.0,
			"skyline_priority": 3, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 72.0, 42.0],
			"model_rects_m": [[0.0, 0.0, 72.0, 42.0]], "kind": "Palace",
			"aliases": ["amstel hotel", "intercontinental amstel"]},

		{"type": "portugese_synagoge", "name": "Portuguese Synagogue",
			"lat": 52.36767, "lon": 4.90392, "radius_m": 4500.0,
			"wiki_title": "Portuguese Synagogue (Amsterdam)", "height_m": 24.0, "yaw_deg": 42.0,
			"skyline_priority": 3, "clear_m": 24.0, "clear_rect_m": [0.0, 0.0, 38.0, 44.0],
			"model_rects_m": [[0.0, 0.0, 38.0, 44.0]], "kind": "Synagogue",
			"aliases": ["portugese synagoge", "portuguese synagogue amsterdam", "esnoga"]},

		{"type": "tropenmuseum", "name": "Wereldmuseum (Tropenmuseum)",
			"lat": 52.36270, "lon": 4.92252, "radius_m": 6000.0,
			"wiki_title": "Tropenmuseum", "height_m": 48.0, "yaw_deg": 32.0,
			"skyline_priority": 3, "clear_m": 44.0, "clear_rect_m": [0.0, 0.0, 104.0, 72.0],
			"model_rects_m": [[0.0, 0.0, 104.0, 72.0]], "kind": "Museum",
			"aliases": ["tropenmuseum", "wereldmuseum amsterdam"]},

		{"type": "molen_de_gooyer", "name": "Molen De Gooyer",
			"lat": 52.36675, "lon": 4.92634, "radius_m": 6000.0,
			"wiki_title": "De Gooyer", "height_m": 33.8, "yaw_deg": 24.0,
			"skyline_priority": 3, "clear_m": 16.0, "kind": "Windmill",
			"aliases": ["molen de gooyer", "de gooyer", "de gooyer windmill"]},
	]
