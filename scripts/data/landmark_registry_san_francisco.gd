class_name LandmarkRegistrySanFrancisco
extends RefCounted

## Registry entries for the San Francisco landmark batch, in the format
## of LocationData.landmarks(). Types are built by LandmarkSetSanFrancisco.
## The Golden Gate Bridge is core and the Transamerica Pyramid is in the
## north america batch. The Bay Bridge spans and Alcatraz are built along
## +X with y = 0 at sea level (`base: sea`, fixed ASL zero); yaw_deg = true bearing of
## +X - 90 (axis = cos, sin in x east, z south). City Hall and the Palace
## of Fine Arts sit on the Western Addition / Marina grid, turned 9
## degrees anticlockwise: City Hall's Polk Street front (+X) bears 81,
## the Palace's long axis (+X, the span) bears 351.

static func entries() -> Array:
	return [
		{"type": "salesforce_tower", "name": "Salesforce Tower", "lat": 37.78978, "lon": -122.39696,
			"radius_m": 6000.0, "wiki_title": "Salesforce Tower", "height_m": 326.0, "clear_m": 45.0,
			"yaw_deg": -38.0, "kind": "Skyscraper", "aliases": ["salesforce tower", "transbay tower"]},
		{"type": "coit_tower", "name": "Coit Tower", "lat": 37.80238, "lon": -122.40584,
			"radius_m": 4000.0, "wiki_title": "Coit Tower", "height_m": 64.0, "clear_m": 40.0,
			"kind": "Tower", "aliases": ["coit tower", "lillian coit memorial tower"]},
		{"type": "ferry_building", "name": "San Francisco Ferry Building", "lat": 37.79551, "lon": -122.39336,
			"radius_m": 4000.0, "wiki_title": "San Francisco Ferry Building", "height_m": 75.0, "clear_m": 60.0,
			"yaw_deg": 55.0, "span_m": 201.0, "kind": "Terminal",
			"aliases": ["san francisco ferry building", "ferry building", "ferry building marketplace"]},
		{"type": "alcatraz", "name": "Alcatraz Island", "lat": 37.82680, "lon": -122.42322,
			"radius_m": 6000.0, "wiki_title": "Alcatraz Island", "height_m": 69.0, "clear_m": 110.0,
			"yaw_deg": 35.0, "span_m": 540.0, "base": "sea", "kind": "Prison",
			"aliases": ["alcatraz island", "alcatraz", "alcatraz penitentiary", "alcatraz federal penitentiary"]},
		{"type": "sutro_tower", "name": "Sutro Tower", "lat": 37.75528, "lon": -122.45278,
			"radius_m": 8000.0, "wiki_title": "Sutro Tower", "height_m": 298.0, "clear_m": 50.0,
			"kind": "Tower", "aliases": ["sutro tower", "sutro broadcasting tower"]},
		{"type": "bay_bridge_west", "name": "Bay Bridge (West Span)", "lat": 37.79812, "lon": -122.37788,
			"radius_m": 8000.0, "wiki_title": "San Francisco–Oakland Bay Bridge", "height_m": 160.0,
			"clear_m": 30.0, "yaw_deg": -49.6, "span_m": 3070.0, "base": "sea", "kind": "Bridge",
			"aliases": ["bay bridge west span", "oakland bay bridge", "san francisco-oakland bay bridge",
				"san francisco–oakland bay bridge", "sf-oakland bay bridge"]},
		{"type": "bay_bridge_east", "name": "Bay Bridge (East Span)", "lat": 37.81737, "lon": -122.35478,
			"radius_m": 8000.0, "wiki_title": "San Francisco–Oakland Bay Bridge", "height_m": 160.0,
			"clear_m": 30.0, "yaw_deg": -35.5, "span_m": 1300.0, "base": "sea", "kind": "Bridge",
			"aliases": ["bay bridge east span", "eastern span of the bay bridge", "self-anchored suspension bridge"]},
		{"type": "sf_city_hall", "name": "San Francisco City Hall", "lat": 37.77928, "lon": -122.41924,
			"radius_m": 4000.0, "wiki_title": "San Francisco City Hall", "height_m": 93.7, "clear_m": 70.0,
			"yaw_deg": -9.0, "kind": "City hall",
			"aliases": ["san francisco city hall", "sf city hall", "city hall san francisco"]},
		{"type": "palace_of_fine_arts", "name": "Palace of Fine Arts", "lat": 37.80292, "lon": -122.44840,
			"radius_m": 4000.0, "wiki_title": "Palace of Fine Arts", "height_m": 49.4, "clear_m": 65.0,
			"yaw_deg": -99.0, "span_m": 270.0, "kind": "Monument",
			"aliases": ["palace of fine arts", "palace of fine arts rotunda", "maybeck rotunda"]},
	]
