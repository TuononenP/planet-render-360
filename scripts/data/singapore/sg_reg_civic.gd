class_name SgRegCivic
extends RefCounted

## Civic District & Padang core landmark registry entries (`PLAN_Singapore_super_realistic.md`, SG-3A).
## All sites sit within 110–600 m of Singapore's capital view centre (1.28967, 103.85007).

static func entries() -> Array:
	return [
		# --- Tier 1 (skyline_priority 9 — Fast+) ---
		{"type": "national_gallery_sg", "name": "National Gallery Singapore",
			"lat": 1.29015, "lon": 103.85150, "radius_m": 4000.0,
			"wiki_title": "National Gallery Singapore", "height_m": 60.0, "yaw_deg": -62.0,
			"skyline_priority": 9, "clear_m": 72.0, "clear_rect_m": [0.0, 0.0, 122.0, 48.0],
			"model_rects_m": [[0.0, 0.0, 122.0, 48.0]],
			"kind": "Museum", "aliases": ["national gallery singapore", "old supreme court singapore", "former city hall singapore"]},

		# --- Tier 2 (skyline_priority 7 — Balanced+) ---
		{"type": "victoria_theatre_sg", "name": "Victoria Theatre and Concert Hall",
			"lat": 1.28824, "lon": 103.85155, "radius_m": 3800.0,
			"wiki_title": "Victoria Theatre and Concert Hall", "height_m": 54.0, "yaw_deg": -60.0,
			"skyline_priority": 7, "clear_m": 48.0, "clear_rect_m": [0.0, 0.0, 48.0, 44.0],
			"model_rects_m": [[0.0, 0.0, 48.0, 44.0]],
			"kind": "Concert hall", "aliases": ["victoria theatre", "victoria concert hall", "victoria theatre and concert hall"]},
		{"type": "st_andrews_cathedral_sg", "name": "St Andrew's Cathedral",
			"lat": 1.29230, "lon": 103.85225, "radius_m": 4000.0,
			"wiki_title": "St Andrew's Cathedral, Singapore", "height_m": 63.0, "yaw_deg": -62.0,
			"skyline_priority": 7, "clear_m": 42.0, "clear_rect_m": [0.0, 0.0, 42.0, 32.0],
			"tree_rect": [0.0, 0.0, 68.0, 52.0],
			"kind": "Cathedral", "aliases": ["st andrew's cathedral", "saint andrew's cathedral", "st andrews cathedral singapore"]},
		{"type": "supreme_court_sg", "name": "Supreme Court of Singapore",
			"lat": 1.29060, "lon": 103.85080, "radius_m": 3500.0,
			"wiki_title": "Supreme Court of Singapore", "height_m": 46.0, "yaw_deg": -74.0,
			"skyline_priority": 7, "clear_m": 58.0, "clear_rect_m": [0.0, 0.0, 68.0, 50.0],
			"model_rects_m": [[0.0, 0.0, 68.0, 50.0]],
			"kind": "Courthouse", "aliases": ["supreme court singapore", "new supreme court singapore"]},

		# --- Tier 3 (skyline_priority 5 — High+) ---
		{"type": "old_hill_street_police_sg", "name": "Old Hill Street Police Station",
			"lat": 1.29075, "lon": 103.84805, "radius_m": 3500.0,
			"wiki_title": "Old Hill Street Police Station", "height_m": 30.0, "yaw_deg": -58.0,
			"skyline_priority": 5, "clear_m": 56.0, "clear_rect_m": [0.0, 0.0, 68.0, 48.0],
			"model_rects_m": [[0.0, 0.0, 68.0, 48.0]],
			"kind": "Civic", "aliases": ["old hill street police station", "mica building"]},
		{"type": "raffles_hotel_sg", "name": "Raffles Hotel",
			"lat": 1.29490, "lon": 103.85445, "radius_m": 3800.0,
			"wiki_title": "Raffles Hotel", "height_m": 24.0, "yaw_deg": -52.0,
			"skyline_priority": 5, "clear_m": 58.0, "clear_rect_m": [0.0, 0.0, 66.0, 46.0],
			"model_rects_m": [[0.0, 0.0, 66.0, 46.0]],
			"kind": "Hotel", "aliases": ["raffles hotel", "raffles singapore"]},
		{"type": "padang_ensemble_sg", "name": "The Padang, Cricket Club & Cenotaph",
			"lat": 1.29055, "lon": 103.85293, "radius_m": 3500.0,
			"wiki_title": "Padang, Singapore", "height_m": 18.0, "yaw_deg": -61.0,
			"skyline_priority": 5, "clear_m": 30.0,
			"clear_offsets_m": [[-200.0, 0.0], [200.0, 0.0], [0.0, 125.0]],
			"tree_rect": [0.0, 0.0, 185.0, 65.0],
			"kind": "Park", "aliases": ["padang", "singapore cricket club", "singapore recreation club", "the cenotaph singapore", "lim bo seng memorial"]},
		{"type": "arts_house_parliament_sg", "name": "The Arts House & Parliament House",
			"lat": 1.28885, "lon": 103.85060, "radius_m": 3500.0,
			"wiki_title": "The Arts House", "height_m": 28.0, "yaw_deg": -60.0,
			"skyline_priority": 5, "clear_m": 44.0, "clear_rect_m": [0.0, 0.0, 58.0, 48.0],
			"kind": "Civic", "aliases": ["the arts house", "old parliament house singapore", "parliament house singapore"]},

		# --- Tier 4 (skyline_priority 3 — Ultra hero set) ---
		{"type": "civilian_war_memorial_sg", "name": "Civilian War Memorial",
			"lat": 1.29320, "lon": 103.85465, "radius_m": 4000.0,
			"wiki_title": "Civilian War Memorial", "height_m": 67.0, "yaw_deg": -52.0,
			"skyline_priority": 3, "clear_m": 28.0, "tree_clear_m": 32.0,
			"kind": "Monument", "aliases": ["civilian war memorial", "war memorial park singapore"]},
		{"type": "asian_civilisations_museum_sg", "name": "Asian Civilisations Museum",
			"lat": 1.28744, "lon": 103.85139, "radius_m": 3500.0,
			"wiki_title": "Asian Civilisations Museum", "height_m": 22.0, "yaw_deg": 42.0,
			"skyline_priority": 3, "clear_m": 54.0, "clear_rect_m": [0.0, 0.0, 68.0, 38.0],
			"model_rects_m": [[0.0, 0.0, 68.0, 38.0]],
			"kind": "Museum", "aliases": ["asian civilisations museum", "empress place building"]},
	]
