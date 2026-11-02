class_name LandmarkRegistryCentralHistoric
extends RefCounted

## Registry entries for the central_historic landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetCentralHistoric.

static func entries() -> Array:
	return [
		# Prague
		{"type": "prague_orloj_tower", "name": "Prague Astronomical Clock Tower", "lat": 50.0870, "lon": 14.4208,
			"radius_m": 3000.0, "wiki_title": "Prague Astronomical Clock", "height_m": 69.5, "clear_m": 40.0,
			"kind": "Tower", "aliases": ["prague astronomical clock", "prague orloj", "pražský orloj", "prazsky orloj",
				"prague old town hall", "staroměstská radnice", "staromestska radnice"]},
		{"type": "powder_tower_prague", "name": "Prague Powder Tower", "lat": 50.0875, "lon": 14.4286,
			"radius_m": 3000.0, "wiki_title": "Powder Tower", "height_m": 65.0, "clear_m": 30.0, "yaw_deg": 90.0,
			"kind": "Tower", "aliases": ["prague powder tower", "powder tower prague", "prašná brána", "prasna brana",
				"powder gate prague"]},
		# Poland
		{"type": "wawel_castle", "name": "Wawel Royal Castle", "lat": 50.0542, "lon": 19.9356, "radius_m": 3000.0,
			"wiki_title": "Wawel Castle", "height_m": 56.0, "clear_m": 78.0, "kind": "Castle",
			"aliases": ["wawel royal castle", "wawel castle", "wawel cathedral", "wawel", "zamek królewski na wawelu",
				"zamek krolewski na wawelu", "katedra wawelska"]},
		{"type": "st_marys_basilica_krakow", "name": "St Mary's Basilica", "lat": 50.0617, "lon": 19.9394,
			"radius_m": 3000.0, "wiki_title": "St. Mary's Basilica, Kraków", "height_m": 81.0, "clear_m": 62.0,
			"kind": "Basilica", "aliases": ["st mary's basilica", "st. mary's basilica", "saint mary's basilica",
				"st marys basilica", "mariacki", "bazylika mariacka", "kościół mariacki", "kosciol mariacki"]},
		{"type": "palace_of_culture_warsaw", "name": "Palace of Culture and Science", "lat": 52.2318, "lon": 21.0060,
			"radius_m": 5000.0, "wiki_title": "Palace of Culture and Science", "height_m": 237.0, "clear_m": 108.0,
			"yaw_deg": -20.0, "kind": "Skyscraper", "aliases": ["palace of culture and science",
				"pałac kultury i nauki", "palac kultury i nauki", "pałac kultury", "palac kultury"]},
		# Germany
		{"type": "frauenkirche_munich", "name": "Munich Frauenkirche", "lat": 48.1386, "lon": 11.5736,
			"radius_m": 3000.0, "wiki_title": "Frauenkirche, Munich", "height_m": 98.6, "clear_m": 70.0,
			"kind": "Church", "aliases": ["munich frauenkirche", "frauenkirche münchen", "frauenkirche muenchen",
				"frauenkirche munchen", "dom zu unserer lieben frau"]},
		{"type": "dresden_frauenkirche", "name": "Dresden Frauenkirche", "lat": 51.0517, "lon": 13.7415,
			"radius_m": 3000.0, "wiki_title": "Dresden Frauenkirche", "height_m": 91.2, "clear_m": 50.0,
			"kind": "Church", "aliases": ["dresden frauenkirche", "frauenkirche dresden", "church of our lady dresden"]},
		{"type": "heidelberg_castle", "name": "Heidelberg Castle", "lat": 49.4106, "lon": 8.7157, "radius_m": 3000.0,
			"wiki_title": "Heidelberg Castle", "height_m": 34.5, "clear_m": 66.0, "kind": "Castle",
			"aliases": ["heidelberg castle", "heidelberger schloss", "schloss heidelberg"]},
		{"type": "porta_nigra", "name": "Porta Nigra", "lat": 49.7597, "lon": 6.6440, "radius_m": 2500.0,
			"wiki_title": "Porta Nigra", "height_m": 29.6, "clear_m": 32.0, "yaw_deg": 30.0, "kind": "Gate",
			"aliases": ["porta nigra", "porta nigra trier"]},
		{"type": "berlin_cathedral", "name": "Berlin Cathedral", "lat": 52.5193, "lon": 13.4010, "radius_m": 4000.0,
			"wiki_title": "Berlin Cathedral", "height_m": 114.0, "clear_m": 85.0, "kind": "Cathedral",
			"aliases": ["berlin cathedral", "berliner dom", "berliner domkirche"]},
		# Austria and Hungary
		{"type": "hohensalzburg_fortress", "name": "Hohensalzburg Fortress", "lat": 47.7948, "lon": 13.0476,
			"radius_m": 3000.0, "wiki_title": "Hohensalzburg Fortress", "height_m": 48.0, "clear_m": 80.0,
			"kind": "Fortress", "aliases": ["hohensalzburg fortress", "festung hohensalzburg", "hohensalzburg castle",
				"hohensalzburg"]},
		{"type": "fishermans_bastion_budapest", "name": "Fisherman's Bastion", "lat": 47.5020, "lon": 19.0344,
			"radius_m": 3000.0, "wiki_title": "Fisherman's Bastion", "height_m": 80.0, "clear_m": 80.0,
			"kind": "Monument", "aliases": ["fisherman's bastion", "fishermans bastion", "halászbástya", "halaszbastya",
				"matthias church", "mátyás-templom", "matyas-templom"]},
	]
