extends RefCounted

## Stockholm Södermalm and station landmarks: Münchenbryggeriet, Högalidskyrkan, Fotografiska,
## Engelbrektskyrkan (plan S-3) and Stockholm Central (plan S-1). Built by sweden_stockholm/inner/sto_set_inner.gd
## and sweden_stockholm/stations/sto_set_stations.gd.

static func entries() -> Array:
	return [
		{"type": "stockholm_central_station", "name": "Stockholm Central Station", "lat": 59.330126, "lon": 18.058081,
			"radius_m": 6000.0, "wiki_title": "Stockholm Central Station", "height_m": 33.0, "kind": "Station",
			"capital": "SE", "yaw_deg": -120.7, "clear_m": 16.0,
			"clear_rect_m": [0.0, -24.5, 91.0, 72.0],
			"aliases": ["stockholm central station", "stockholms centralstation", "stockholm c"]},
		{"type": "munchenbryggeriet", "name": "Münchenbryggeriet", "lat": 59.320733, "lon": 18.053756,
			"radius_m": 4000.0, "wiki_title": "Münchenbryggeriet", "height_m": 45.0, "kind": "Brewery",
			"yaw_deg": 1.6, "clear_m": 14.0, "clear_rect_m": [-17.5, 3.0, 158.0, 38.0],
			"clear_offsets_m": [[-87.0, 49.7]], "base_at_m": [0.0, -24.0],
			"aliases": ["münchenbryggeriet", "munchenbryggeriet", "münchen brewery"]},
		{"type": "hogalid_church", "skyline_priority": 1, "name": "Högalid Church", "lat": 59.317473, "lon": 18.037510,
			"radius_m": 4000.0, "wiki_title": "Högalid Church", "height_m": 68.5, "kind": "Church",
			"yaw_deg": -8.0, "clear_m": 40.0, "base_at_m": [0.0, 0.0],
			"aliases": ["högalid church", "högalidskyrkan", "hogalid church", "hogalidskyrkan"]},
		{"type": "fotografiska", "name": "Fotografiska", "lat": 59.317890, "lon": 18.085745,
			"radius_m": 4000.0, "wiki_title": "Fotografiska", "height_m": 23.5, "kind": "Museum",
			"yaw_deg": 10.5, "clear_m": 20.0, "clear_rect_m": [0.0, 0.0, 68.0, 13.0], "base_at_m": [0.0, -4.0],
			"aliases": ["fotografiska", "fotografiska stockholm", "stora tullhuset"]},
		{"type": "engelbrektskyrkan", "skyline_priority": 1, "name": "Engelbrekt Church", "lat": 59.344109, "lon": 18.067626,
			"radius_m": 4000.0, "wiki_title": "Engelbrekt Church", "height_m": 65.0, "kind": "Church",
			"yaw_deg": -13.5, "clear_m": 34.0, "base_at_m": [0.0, 0.0],
			"aliases": ["engelbrekt church", "engelbrektskyrkan", "engelbrekts kyrka"]},
	]
