class_name MiaRegGroveGables
extends RefCounted

## Registry entries for Vizcaya, Coconut Grove and Coral Gables icons (MI-10).
## Coordinates and yaw_deg follow docs/miami-landmark-sources.md.

static func entries() -> Array:
	return [
		# --- Centre E: Vizcaya & Coconut Grove ---
		{"type": "vizcaya_museum_gardens", "name": "Vizcaya Museum and Gardens",
			"lat": 25.744391, "lon": -80.210480, "radius_m": 5500.0,
			"wiki_title": "Vizcaya Museum and Gardens", "height_m": 21.5, "yaw_deg": 52.3,
			"clear_m": 58.0, "tree_rect": true, "tree_clear_m": 62.0, "kind": "Museum",
			"aliases": ["vizcaya museum and gardens", "vizcaya museum", "vizcaya"]},
		{"type": "miami_city_hall_dinner_key", "name": "Miami City Hall",
			"lat": 25.728200, "lon": -80.233800, "radius_m": 5000.0,
			"wiki_title": "Miami City Hall", "height_m": 14.5, "yaw_deg": 42.5,
			"clear_m": 26.0, "kind": "Civic",
			"aliases": ["miami city hall", "dinner key terminal", "pan am seaplane base"]},
		{"type": "ermita_de_la_caridad", "name": "Ermita de la Caridad",
			"lat": 25.740879, "lon": -80.211352, "radius_m": 5000.0,
			"wiki_title": "Ermita de la Caridad", "height_m": 29.5, "yaw_deg": -48.2,
			"skyline_priority": 1, "clear_m": 24.0, "kind": "Shrine",
			"aliases": ["ermita de la caridad", "shrine of our lady of charity"]},
		# --- Centre F: Coral Gables ---
		{"type": "biltmore_hotel_coral_gables", "name": "Biltmore Hotel",
			"lat": 25.740792, "lon": -80.278457, "radius_m": 7000.0,
			"wiki_title": "Biltmore Hotel (Coral Gables)", "height_m": 96.0, "yaw_deg": -30.7,
			"skyline_priority": 3, "clear_m": 68.0,
			"model_rects_m": [[0.0, 0.0, 78.0, 56.0]],
			"tree_clear_m": 56.0, "kind": "Hotel",
			"aliases": ["biltmore hotel", "biltmore hotel coral gables", "miami biltmore"]},
		{"type": "venetian_pool_coral_gables", "name": "Venetian Pool",
			"lat": 25.745779, "lon": -80.273177, "radius_m": 5000.0,
			"wiki_title": "Venetian Pool", "height_m": 11.0, "yaw_deg": 67.1,
			"clear_m": 30.0, "kind": "Pool",
			"aliases": ["venetian pool", "venetian pool coral gables"]},
		{"type": "coral_gables_city_hall", "name": "Coral Gables City Hall",
			"lat": 25.749252, "lon": -80.263457, "radius_m": 5000.0,
			"wiki_title": "Coral Gables City Hall", "height_m": 22.0, "yaw_deg": 41.0,
			"clear_m": 26.0, "kind": "Civic",
			"aliases": ["coral gables city hall", "city hall coral gables"]},
		{"type": "alhambra_water_tower", "name": "Alhambra Water Tower",
			"lat": 25.750237, "lon": -80.281568, "radius_m": 5500.0,
			"wiki_title": "Alhambra Water Tower", "height_m": 40.0, "yaw_deg": 87.9,
			"skyline_priority": 1, "clear_m": 18.0, "kind": "Tower",
			"aliases": ["alhambra water tower", "alhambra tower"]},
		{"type": "douglas_entrance_coral_gables", "name": "Douglas Entrance",
			"lat": 25.764887, "lon": -80.255528, "radius_m": 5000.0,
			"wiki_title": "Douglas Entrance", "height_m": 24.0, "yaw_deg": -2.6,
			"clear_m": 28.0, "kind": "Gateway",
			"aliases": ["douglas entrance", "la puerta del sol", "douglas entrance coral gables"]},
	]
