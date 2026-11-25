class_name SgRegBay
extends RefCounted

## Primary and Marina Bay hero landmark registry entries (`PLAN_Singapore_super_realistic.md`, SG-2).
## Coordinates & bearings verified from `capital_sg_*_detailed.osmb` / `far.osmb` and `docs/singapore-landmark-sources.md`.
## `yaw_deg = bearing_deg - 90.0` (model +X turns clockwise from East).

static func entries() -> Array:
	return [
		# Primary Singapore landmark: Tower 2 centroid (1.28368, 103.86071), chord T1->T3 ~22.5° -> yaw -67.5°.
		# `ultra_registry_limit: 42 / ultra_total_limit: 50` gives Ultra 42 icons + 8 bridges + 110 skyline towers.
		{"type": "marina_bay_sands", "icon": true, "name": "Marina Bay Sands",
			"lat": 1.28368, "lon": 103.86071, "radius_m": 5000.0,
			"wiki_title": "Marina Bay Sands", "height_m": 207.0, "yaw_deg": -67.5,
			"clear_m": 95.0,
			"clear_offsets_m": [[-116.0, 0.0], [0.0, 0.0], [105.0, -6.0], [0.0, -140.0], [-95.0, -140.0], [95.0, -140.0]],
			"ultra_registry_limit": 42, "ultra_total_limit": 50,
			"kind": "Resort", "aliases": ["marina bay sands", "mbs", "skypark", "sands skypark"]},

		# --- Tier 1 (skyline_priority 9 — visible on Fast+) ---
		{"type": "esplanade_singapore", "name": "Esplanade – Theatres on the Bay",
			"lat": 1.28966, "lon": 103.85568, "radius_m": 4500.0,
			"wiki_title": "Esplanade – Theatres on the Bay", "height_m": 35.0, "yaw_deg": -33.0,
			"skyline_priority": 9, "clear_m": 72.0, "clear_rect_m": [0.0, 0.0, 102.0, 72.0],
			"model_rects_m": [[0.0, 0.0, 102.0, 72.0]],
			"kind": "Arts centre", "aliases": ["esplanade", "esplanade singapore", "the esplanade", "durian theatre"]},
		{"type": "merlion_park", "name": "Merlion Park",
			"lat": 1.28678, "lon": 103.85450, "radius_m": 4000.0,
			"wiki_title": "Merlion", "height_m": 8.6, "yaw_deg": 5.0,
			"skyline_priority": 9, "clear_m": 22.0, "base": "water", "tree_clear_m": 24.0,
			"kind": "Monument", "aliases": ["merlion", "merlion park", "merlion statue"]},
		{"type": "singapore_flyer", "name": "Singapore Flyer",
			"lat": 1.28930, "lon": 103.86313, "radius_m": 5000.0,
			"wiki_title": "Singapore Flyer", "height_m": 165.0, "yaw_deg": -58.0,
			"skyline_priority": 9, "clear_m": 62.0,
			"kind": "Observation wheel", "aliases": ["singapore flyer", "flyer"]},
		{"type": "artscience_museum", "name": "ArtScience Museum",
			"lat": 1.28627, "lon": 103.85927, "radius_m": 4500.0,
			"wiki_title": "ArtScience Museum", "height_m": 60.0, "yaw_deg": -20.0,
			"skyline_priority": 9, "clear_m": 48.0,
			"kind": "Museum", "aliases": ["artscience museum", "art science museum"]},
		{"type": "fullerton_hotel", "name": "The Fullerton Hotel Singapore",
			"lat": 1.28612, "lon": 103.85312, "radius_m": 4000.0,
			"wiki_title": "The Fullerton Hotel Singapore", "height_m": 37.0, "yaw_deg": -87.0,
			"skyline_priority": 9, "clear_m": 54.0, "clear_rect_m": [0.0, 0.0, 62.0, 38.0],
			"model_rects_m": [[0.0, 0.0, 62.0, 38.0]],
			"kind": "Hotel", "aliases": ["fullerton hotel", "the fullerton hotel", "fullerton building"]},

		# --- Tier 2 (skyline_priority 7 — visible on Balanced+) ---
		{"type": "helix_bridge", "name": "Helix Bridge",
			"lat": 1.28765, "lon": 103.86052, "radius_m": 4500.0,
			"wiki_title": "Helix Bridge", "height_m": 14.0, "yaw_deg": -88.5,
			"span_m": 280.0, "base": "water", "skyline_priority": 7, "clear_m": 16.0,
			"clear_path_m": [[-140.0, -10.0], [-70.0, 8.0], [0.0, 14.0], [70.0, 8.0], [140.0, -10.0]],
			"kind": "Bridge", "aliases": ["helix bridge", "double helix bridge", "the helix"]},
		{"type": "supertree_grove", "name": "Supertree Grove (Gardens by the Bay)",
			"lat": 1.28200, "lon": 103.86390, "radius_m": 5000.0,
			"wiki_title": "Gardens by the Bay", "height_m": 50.0, "yaw_deg": 15.0,
			"skyline_priority": 7, "clear_m": 40.0, "tree_clear_m": 75.0,
			"kind": "Garden", "aliases": ["supertree grove", "supertrees", "gardens by the bay", "ocbc skyway"]},
		{"type": "gardens_by_the_bay_domes", "name": "Flower Dome & Cloud Forest",
			"lat": 1.28395, "lon": 103.86560, "radius_m": 5000.0,
			"wiki_title": "Gardens by the Bay", "height_m": 58.0, "yaw_deg": -25.0,
			"skyline_priority": 7, "clear_m": 75.0, "clear_rect_m": [0.0, 0.0, 96.0, 56.0],
			"kind": "Conservatory", "aliases": ["flower dome", "cloud forest", "gardens domes"]},

		# --- Tier 4 (skyline_priority 3 — Ultra hero set) ---
		{"type": "fullerton_waterfront", "name": "Fullerton Heritage Waterfront (One Fullerton & Clifford Pier)",
			"lat": 1.28480, "lon": 103.85395, "radius_m": 3500.0,
			"wiki_title": "Clifford Pier", "height_m": 18.0, "yaw_deg": -71.0,
			"skyline_priority": 3, "clear_m": 42.0, "base": "water",
			"clear_offsets_m": [[0.0, 0.0], [95.0, 2.0], [-75.0, -4.0]],
			"kind": "Waterfront", "aliases": ["clifford pier", "one fullerton", "customs house singapore", "waterboat house"]},
		{"type": "marina_barrage", "name": "Marina Barrage",
			"lat": 1.28050, "lon": 103.87100, "radius_m": 5500.0,
			"wiki_title": "Marina Barrage", "height_m": 24.0, "yaw_deg": -52.0,
			"skyline_priority": 3, "clear_m": 60.0, "base": "water",
			"kind": "Dam", "aliases": ["marina barrage"]},
	]
