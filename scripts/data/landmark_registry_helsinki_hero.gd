class_name LandmarkRegistryHelsinkiHero
extends RefCounted

## Additional Helsinki landmarks. Coordinates follow the municipal service
## map / OSM; rounded model envelopes are approximations except the owner-
## documented heights of Kamppi (11.5 m), SkyWheel (40 m), Havis (5 m).

static func entries() -> Array:
	return [
		{"type": "kamppi_chapel", "name": "Kamppi Chapel", "lat": 60.16945, "lon": 24.93592,
			"radius_m": 5000.0, "wiki_title": "Kamppi Chapel", "height_m": 11.5, "clear_m": 18.0,
			"yaw_deg": -18.0, "kind": "Chapel", "aliases": ["kamppi chapel", "kampin kappeli", "kampens kapell"]},
		{"type": "amos_rex", "name": "Amos Rex", "lat": 60.17008, "lon": 24.93604,
			"radius_m": 5000.0, "wiki_title": "Amos Rex", "height_m": 6.35, "clear_m": 43.0,
			"yaw_deg": -3.0, "kind": "Museum", "aliases": ["amos rex", "amos rex museum", "amos rex museo"]},
		{"type": "havis_amanda", "name": "Havis Amanda", "lat": 60.16749, "lon": 24.95134,
			"radius_m": 5000.0, "wiki_title": "Havis Amanda", "height_m": 5.0, "clear_m": 7.0,
			"kind": "Fountain", "aliases": ["havis amanda", "havis amanda fountain", "manta helsinki"]},
		{"type": "kappeli", "name": "Restaurant Kappeli", "lat": 60.16731, "lon": 24.94950,
			"radius_m": 5000.0, "wiki_title": "Kappeli", "height_m": 10.8, "clear_m": 29.0,
			"yaw_deg": -3.0, "kind": "Restaurant", "aliases": ["restaurant kappeli", "ravintola kappeli", "esplanadikappeli"]},
		{"type": "skywheel_helsinki", "name": "SkyWheel Helsinki", "lat": 60.1667282, "lon": 24.9594489,
			"radius_m": 5000.0, "wiki_title": "SkyWheel Helsinki", "height_m": 40.0, "clear_m": 22.0,
			"yaw_deg": -90.4, "kind": "Observation wheel", "aliases": ["skywheel helsinki", "helsinki skywheel", "finnair skywheel"]},
		{"type": "allas_sea_pool", "name": "Allas Sea Pool", "lat": 60.16696, "lon": 24.95722,
			"radius_m": 5000.0, "wiki_title": "Allas Sea Pool", "height_m": 7.05, "clear_m": 105.0,
			"yaw_deg": -93.0, "base": "sea", "kind": "Sea pool", "aliases": ["allas sea pool", "allas seapool", "allas merikylpyla"]},
		{"type": "stockmann_helsinki", "name": "Stockmann Helsinki", "lat": 60.16840, "lon": 24.94225,
			"radius_m": 5000.0, "wiki_title": "Stockmann, Helsinki centre", "height_m": 35.0, "clear_m": 54.0,
			"yaw_deg": -3.0, "kind": "Department store", "aliases": ["stockmann helsinki", "stockmann department store helsinki", "helsingin keskustan stockmann"]},
		{"type": "hakaniemi_market_hall", "name": "Hakaniemi Market Hall", "lat": 60.180073, "lon": 24.951208,
			"radius_m": 5000.0, "wiki_title": "Hakaniemi market hall", "height_m": 17.0, "clear_m": 34.0,
			"yaw_deg": -22.0, "kind": "Market hall", "aliases": ["hakaniemi market hall", "hakaniemen kauppahalli", "hagnas saluhall"]},
		{"type": "government_palace_helsinki", "name": "Government Palace, Helsinki", "lat": 60.16956, "lon": 24.95400,
			"radius_m": 5000.0, "wiki_title": "Government Palace, Helsinki", "height_m": 26.0, "clear_m": 73.0,
			"yaw_deg": 87.0, "kind": "Palace", "aliases": ["government palace, helsinki", "valtioneuvoston linna", "statsradsborgen"]},
		{"type": "helsinki_university_main", "name": "University of Helsinki Main Building", "lat": 60.169487, "lon": 24.94960,
			"radius_m": 5000.0, "wiki_title": "University of Helsinki Main Building", "height_m": 22.0, "clear_m": 72.0,
			"yaw_deg": -93.0, "kind": "University", "aliases": ["university of helsinki main building", "helsingin yliopiston paarakennus", "helsingin yliopiston päärakennus"]},
	]
