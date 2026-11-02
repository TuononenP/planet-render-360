class_name LandmarkRegistrySouthAmericaOceania
extends RefCounted

## Registry entries for the south america oceania landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetSouthAmericaOceania.

static func entries() -> Array:
	return [
		# Statue and pedestal only (38 m); the Corcovado summit is not modelled.
		# The statue faces east-north-east over Guanabara Bay.
		{"type": "christ_redeemer", "name": "Christ the Redeemer", "lat": -22.9519, "lon": -43.2105,
			"radius_m": 6000.0, "wiki_title": "Christ the Redeemer (statue)", "height_m": 38.0,
			"clear_m": 25.0, "yaw_deg": 70.0, "kind": "Statue",
			"aliases": ["christ the redeemer", "cristo redentor", "corcovado"]},
		# 75 m high and 106 m across outside (64 m / 96 m inside): Riotur.
		{"type": "rio_cathedral", "name": "Metropolitan Cathedral of Rio de Janeiro", "lat": -22.9111,
			"lon": -43.1808, "radius_m": 5000.0, "wiki_title": "Metropolitan Cathedral of Saint Sebastian, Rio de Janeiro",
			"height_m": 75.0, "clear_m": 75.0, "kind": "Cathedral",
			"aliases": ["metropolitan cathedral of rio", "catedral metropolitana do rio", "catedral de são sebastião"]},
		{"type": "machu_picchu", "name": "Machu Picchu", "lat": -13.1631, "lon": -72.5450,
			"radius_m": 4000.0, "wiki_title": "Machu Picchu", "height_m": 27.0,
			"clear_m": 80.0, "kind": "Inca citadel", "aliases": ["machu picchu", "machupicchu"]},
		# The sixteen columns rise about 40 m over a 60 m floor ring (UnB / CILAMCE papers).
		{"type": "brasilia_cathedral", "name": "Cathedral of Brasília", "lat": -15.7983, "lon": -47.8751,
			"radius_m": 4000.0, "wiki_title": "Cathedral of Brasília", "height_m": 40.0,
			"clear_m": 55.0, "kind": "Cathedral",
			"aliases": ["cathedral of brasília", "cathedral of brasilia", "catedral de brasília", "catedral metropolitana de brasília"]},
		{"type": "brazil_congress", "name": "National Congress of Brazil", "lat": -15.7998, "lon": -47.8644,
			"radius_m": 4000.0, "wiki_title": "National Congress of Brazil", "height_m": 100.0,
			"clear_m": 150.0, "kind": "Parliament",
			"aliases": ["national congress of brazil", "congresso nacional do brasil", "brazilian congress"]},
		{"type": "obelisco_buenos_aires", "name": "Obelisco de Buenos Aires", "lat": -34.6037, "lon": -58.3816,
			"radius_m": 5000.0, "wiki_title": "Obelisco de Buenos Aires", "height_m": 67.5,
			"clear_m": 20.0, "kind": "Obelisk",
			"aliases": ["obelisco de buenos aires", "buenos aires obelisk", "obelisco porteño"]},
		{"type": "gran_torre_santiago", "name": "Gran Torre Santiago", "lat": -33.4177, "lon": -70.6067,
			"radius_m": 8000.0, "wiki_title": "Gran Torre Santiago", "height_m": 300.0,
			"clear_m": 100.0, "kind": "Skyscraper",
			"aliases": ["gran torre santiago", "costanera center", "gran torre costanera"]},
		{"type": "teatro_amazonas", "name": "Teatro Amazonas", "lat": -3.1303, "lon": -60.0233,
			"radius_m": 3500.0, "wiki_title": "Amazon Theatre", "height_m": 36.0,
			"clear_m": 55.0, "kind": "Opera house",
			"aliases": ["teatro amazonas", "amazon theatre", "amazon theater"]},
		{"type": "moai_tongariki", "name": "Moai at Ahu Tongariki", "lat": -27.1257, "lon": -109.2766,
			"radius_m": 5000.0, "wiki_title": "Ahu Tongariki", "height_m": 9.2,
			"clear_m": 90.0, "kind": "Moai",
			"aliases": ["ahu tongariki", "tongariki", "easter island moai"]},
		{"type": "auckland_sky_tower", "name": "Sky Tower, Auckland", "lat": -36.8485, "lon": 174.7622,
			"radius_m": 8000.0, "wiki_title": "Sky Tower (Auckland)", "height_m": 328.0,
			"clear_m": 70.0, "kind": "Tower",
			"aliases": ["sky tower, auckland", "auckland sky tower", "skytower auckland"]},
		{"type": "sydney_tower", "name": "Sydney Tower", "lat": -33.8705, "lon": 151.2089,
			"radius_m": 8000.0, "wiki_title": "Sydney Tower", "height_m": 309.0,
			"clear_m": 60.0, "kind": "Tower",
			"aliases": ["sydney tower", "centrepoint tower", "sydney tower eye"]},
		# The station fronts Flinders Street (east-west), dome at the Swanston Street corner.
		{"type": "flinders_street_station", "name": "Flinders Street Station", "lat": -37.8183, "lon": 144.9671,
			"radius_m": 5000.0, "wiki_title": "Flinders Street railway station", "height_m": 40.0,
			"clear_m": 130.0, "kind": "Railway station",
			"aliases": ["flinders street station", "flinders street railway station"]},
		# Capitol Hill: the building faces north-east up the land axis to the War Memorial.
		# The 81 m flag mast stands on the roof terrace (RL617); its tip is 107 m above
		# the forecourt (Structurae, Wikipedia infobox).
		{"type": "parliament_house_canberra", "name": "Parliament House, Canberra", "lat": -35.3081,
			"lon": 149.1245, "radius_m": 6000.0, "wiki_title": "Parliament House, Canberra",
			"height_m": 107.0, "clear_m": 150.0, "yaw_deg": 38.0, "kind": "Parliament",
			"aliases": ["parliament house, canberra", "australian parliament house", "parliament house canberra"]},
	]
