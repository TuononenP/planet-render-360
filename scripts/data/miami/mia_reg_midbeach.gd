class_name MiaRegMidbeach
extends RefCounted

## Registry entries for Mid-Beach icons: Fontainebleau, Faena Forum and Flagler Memorial Monument (MI-4D).
## Coordinates, yaw_deg and height_m follow OpenStreetMap footprints recorded in
## docs/miami-landmark-sources.md (§2).

static func entries() -> Array:
	return [
		{
			"type": "fontainebleau_miami_beach",
			"name": "Fontainebleau Miami Beach",
			"lat": 25.817904,
			"lon": -80.122330,
			"radius_m": 6000.0,
			"wiki_title": "Fontainebleau Miami Beach",
			"height_m": 110.0,
			"yaw_deg": 7.6,
			"skyline_priority": 3,
			"clear_m": 82.0,
			"clear_rect_m": [0.0, 0.0, 82.0, 110.0],
			"model_rects_m": [[0.0, 0.0, 80.0, 108.0]],
			"tree_rect": false,
			"tree_clear_m": 52.0,
			"kind": "Resort hotel",
			"aliases": [
				"fontainebleau miami beach",
				"fontainebleau hotel",
				"fontainebleau hotel miami beach",
				"the fontainebleau",
			],
		},
		{
			"type": "faena_forum_miami_beach",
			"name": "Faena Forum",
			"lat": 25.808134,
			"lon": -80.124057,
			"radius_m": 5500.0,
			"wiki_title": "Faena Forum",
			"height_m": 22.0,
			"yaw_deg": 8.8,
			"clear_m": 26.0,
			"clear_rect_m": [0.0, 0.0, 26.0, 15.5],
			"model_rects_m": [[0.0, 0.0, 25.5, 15.0]],
			"tree_rect": false,
			"tree_clear_m": 18.0,
			"kind": "Cultural center",
			"aliases": [
				"faena forum",
				"faena forum miami beach",
				"faena district",
			],
		},
		{
			"type": "flagler_memorial_monument",
			"name": "Flagler Memorial Monument",
			"lat": 25.783600,
			"lon": -80.153600,
			"radius_m": 5500.0,
			"wiki_title": "Flagler Monument Island",
			"height_m": 33.5,
			"yaw_deg": 0.0,
			"skyline_priority": 1,
			"clear_m": 16.0,
			"clear_rect_m": [0.0, 0.0, 11.0, 11.0],
			"model_rects_m": [[0.0, 0.0, 10.0, 10.0]],
			"tree_clear_m": 12.0,
			"kind": "Monument",
			"aliases": [
				"flagler memorial monument",
				"flagler monument island",
				"flagler memorial island",
				"henry flagler monument",
			],
		},
	]
