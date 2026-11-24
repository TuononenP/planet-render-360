class_name AmsRegWaterfront
extends RefCounted

## IJ Waterfront, Oosterdok, Overhoeks, Harbour, Stadiums & Bespoke Monumental
## Bridges registry entries for Amsterdam (`AMS-3.4`, `AMS-3.5`, `AMS-4.1`).

static func entries() -> Array:
	return [
		# --- IJ Waterfront & Oosterdok ---
		{"type": "nemo_amsterdam", "name": "NEMO Science Museum",
			"lat": 52.37417, "lon": 4.91233, "radius_m": 6000.0,
			"wiki_title": "NEMO (museum)", "height_m": 32.0, "yaw_deg": 18.0,
			"skyline_priority": 7, "clear_m": 44.0, "clear_rect_m": [0.0, 0.0, 44.0, 92.0],
			"model_rects_m": [[0.0, 0.0, 44.0, 92.0]], "kind": "Museum",
			"aliases": ["nemo", "nemo science museum", "nemo amsterdam"]},

		{"type": "scheepvaartmuseum", "name": "National Maritime Museum & VOC Amsterdam",
			"lat": 52.37161, "lon": 4.91478, "radius_m": 6000.0,
			"wiki_title": "National Maritime Museum, Amsterdam", "height_m": 30.0, "yaw_deg": 18.0,
			"skyline_priority": 3, "clear_m": 42.0, "clear_rect_m": [0.0, 0.0, 68.0, 68.0],
			"model_rects_m": [[0.0, 0.0, 68.0, 68.0]], "kind": "Museum",
			"aliases": ["scheepvaartmuseum", "het scheepvaartmuseum", "national maritime museum amsterdam"]},

		{"type": "eye_filmmuseum", "name": "EYE Filmmuseum",
			"lat": 52.38436, "lon": 4.90092, "radius_m": 6000.0,
			"wiki_title": "Eye Film Museum", "height_m": 22.0, "yaw_deg": 30.0,
			"skyline_priority": 5, "clear_m": 38.0, "clear_rect_m": [0.0, 0.0, 96.0, 46.0],
			"model_rects_m": [[0.0, 0.0, 96.0, 46.0]], "kind": "Museum",
			"aliases": ["eye filmmuseum", "eye film museum", "eye amsterdam"]},

		{"type": "adam_toren", "name": "A'DAM Toren",
			"lat": 52.38396, "lon": 4.90226, "radius_m": 6500.0,
			"wiki_title": "A'DAM Tower", "height_m": 100.0, "yaw_deg": 75.0,
			"skyline_priority": 5, "clear_m": 30.0, "clear_rect_m": [0.0, 0.0, 44.0, 44.0],
			"model_rects_m": [[0.0, 0.0, 44.0, 44.0]], "kind": "Tower",
			"aliases": ["adam toren", "a'dam toren", "adam tower", "a'dam lookout", "overhoeks tower"]},

		{"type": "muziekgebouw_bimhuis", "name": "Muziekgebouw aan 't IJ & Bimhuis",
			"lat": 52.37828, "lon": 4.91303, "radius_m": 6000.0,
			"wiki_title": "Muziekgebouw aan 't IJ", "height_m": 24.0, "yaw_deg": 28.0,
			"skyline_priority": 3, "clear_m": 46.0, "clear_rect_m": [0.0, 0.0, 108.0, 62.0],
			"model_rects_m": [[0.0, 0.0, 108.0, 62.0]], "kind": "Concert hall",
			"aliases": ["muziekgebouw", "muziekgebouw aan 't ij", "bimhuis"]},

		{"type": "oba_oosterdok", "name": "OBA Oosterdok",
			"lat": 52.37590, "lon": 4.90802, "radius_m": 5000.0,
			"wiki_title": "Openbare Bibliotheek Amsterdam", "height_m": 42.0, "yaw_deg": 26.0,
			"skyline_priority": 3, "clear_m": 36.0, "clear_rect_m": [0.0, 0.0, 64.0, 72.0],
			"model_rects_m": [[0.0, 0.0, 64.0, 72.0]], "kind": "Library",
			"aliases": ["oba", "oba oosterdok", "openbare bibliotheek amsterdam"]},

		# --- Harbour, Amsterdam School & Outer Stadiums ---
		{"type": "het_schip", "name": "Museum Het Schip",
			"lat": 52.38910, "lon": 4.87584, "radius_m": 6000.0,
			"wiki_title": "Het Schip", "height_m": 28.0, "yaw_deg": 36.0,
			"skyline_priority": 3, "clear_m": 32.0, "clear_rect_m": [0.0, 0.0, 82.0, 44.0],
			"model_rects_m": [[0.0, 0.0, 82.0, 44.0]], "kind": "Museum",
			"aliases": ["het schip", "museum het schip"]},

		{"type": "pontsteiger", "name": "Pontsteiger",
			"lat": 52.39178, "lon": 4.88914, "radius_m": 6500.0,
			"wiki_title": "Pontsteiger", "height_m": 90.0, "yaw_deg": 30.0,
			"skyline_priority": 3, "clear_m": 42.0, "clear_rect_m": [0.0, 0.0, 96.0, 44.0],
			"model_rects_m": [[0.0, 0.0, 96.0, 44.0]], "kind": "Tower",
			"aliases": ["pontsteiger", "pontsteiger amsterdam"]},

		{"type": "silodam", "name": "Silodam",
			"lat": 52.39128, "lon": 4.89390, "radius_m": 6000.0,
			"wiki_title": "Silodam", "height_m": 34.0, "yaw_deg": 32.0,
			"skyline_priority": 3, "clear_m": 30.0, "clear_rect_m": [0.0, 0.0, 120.0, 24.0],
			"model_rects_m": [[0.0, 0.0, 120.0, 24.0]], "kind": "Apartments",
			"aliases": ["silodam", "silodam amsterdam"]},

		{"type": "gashouder_amsterdam", "name": "Gashouder (Westergas)",
			"lat": 52.38690, "lon": 4.86985, "radius_m": 6000.0,
			"wiki_title": "Westergasfabriek", "height_m": 24.0, "yaw_deg": 0.0,
			"skyline_priority": 3, "clear_m": 32.0, "kind": "Hall",
			"aliases": ["gashouder", "westergas", "westergasfabriek"]},

		{"type": "olympisch_stadion_amsterdam", "name": "Olympic Stadium Amsterdam",
			"lat": 52.34340, "lon": 4.85420, "radius_m": 7500.0,
			"wiki_title": "Olympic Stadium (Amsterdam)", "height_m": 46.0, "yaw_deg": 18.0,
			"skyline_priority": 3, "clear_m": 95.0, "kind": "Stadium",
			"aliases": ["olympisch stadion", "olympic stadium amsterdam"]},

		{"type": "johan_cruijff_arena", "name": "Johan Cruijff ArenA",
			"lat": 52.31437, "lon": 4.94196, "radius_m": 10000.0,
			"wiki_title": "Johan Cruyff Arena", "height_m": 75.0, "yaw_deg": 24.0,
			"skyline_priority": 3, "clear_m": 118.0, "kind": "Stadium",
			"aliases": ["johan cruijff arena", "johan cruyff arena", "amsterdam arena"]},

		# --- Bespoke Monumental Bridges (AMS-4.1) ---
		{"type": "magere_brug", "name": "Magere Brug",
			"lat": 52.36358, "lon": 4.90236, "radius_m": 5500.0,
			"wiki_title": "Magere Brug", "height_m": 10.5, "yaw_deg": 73.0,
			"span_m": 68.0, "base": "water", "skyline_priority": 7, "clear_m": 12.0,
			"deck_ends": true, "deck_m": 3.0, "deck_width_m": 4.5, "kind": "Bridge",
			"aliases": ["magere brug", "skinny bridge", "skinny bridge amsterdam"]},

		{"type": "blauwbrug", "name": "Blauwbrug",
			"lat": 52.36634, "lon": 4.90093, "radius_m": 5000.0,
			"wiki_title": "Blauwbrug", "height_m": 12.0, "yaw_deg": 66.0,
			"span_m": 62.0, "base": "water", "skyline_priority": 7, "clear_m": 18.0,
			"deck_ends": true, "deck_m": 3.8, "deck_width_m": 20.0, "kind": "Bridge",
			"aliases": ["blauwbrug", "blue bridge amsterdam"]},

		{"type": "torensluis", "name": "Torensluis",
			"lat": 52.37453, "lon": 4.88968, "radius_m": 4500.0,
			"wiki_title": "Torensluis", "height_m": 6.5, "yaw_deg": 104.0,
			"span_m": 42.0, "base": "water", "skyline_priority": 5, "clear_m": 16.0,
			"deck_ends": true, "deck_m": 2.6, "deck_width_m": 26.0, "kind": "Bridge",
			"aliases": ["torensluis", "torensluis amsterdam"]},

		{"type": "python_bridge", "name": "Python Bridge (Hoge Brug)",
			"lat": 52.37305, "lon": 4.94888, "radius_m": 6500.0,
			"wiki_title": "Python Bridge", "height_m": 13.5, "yaw_deg": 169.6,
			"span_m": 92.0, "base": "water", "skyline_priority": 3, "clear_m": 12.0,
			"deck_ends": true, "deck_m": 6.5, "deck_width_m": 4.5, "kind": "Bridge",
			"aliases": ["python bridge", "pythonbrug", "hoge brug amsterdam"]},
	]
