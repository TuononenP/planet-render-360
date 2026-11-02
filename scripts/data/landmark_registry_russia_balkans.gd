class_name LandmarkRegistryRussiaBalkans
extends RefCounted

## Registry entries for the russia_balkans landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetRussiaBalkans.

static func entries() -> Array:
	return [
		# Saint Petersburg
		{"type": "winter_palace", "icon": true, "name": "Winter Palace", "lat": 59.9404, "lon": 30.3139, "radius_m": 3500.0,
			"wiki_title": "Winter Palace", "height_m": 30.0, "clear_m": 145.0, "yaw_deg": -36.0, "kind": "Palace",
			"aliases": ["winter palace", "state hermitage", "hermitage museum", "зимний дворец", "эрмитаж", "winterpalast",
				"palais d'hiver"]},
		{"type": "peter_paul_cathedral", "name": "Peter and Paul Cathedral", "lat": 59.9502, "lon": 30.3164, "radius_m": 3500.0,
			"wiki_title": "Peter and Paul Cathedral, Saint Petersburg", "height_m": 122.5, "clear_m": 55.0, "yaw_deg": -25.5,
			"kind": "Cathedral", "aliases": ["peter and paul cathedral", "peter and paul fortress",
				"петропавловский собор", "петропавловская крепость", "petropavlovskaya"]},
		{"type": "church_savior_on_blood", "name": "Church of the Savior on Spilled Blood", "lat": 59.9400, "lon": 30.3289,
			"radius_m": 3500.0, "wiki_title": "Church of the Savior on Blood", "height_m": 81.0, "clear_m": 42.0,
			"yaw_deg": 11.8, "kind": "Church", "aliases": ["church of the savior on spilled blood",
				"church of the saviour on spilled blood", "savior on spilled blood", "saviour on spilled blood",
				"church on spilled blood", "спас на крови", "храм воскресения христова"]},
		{"type": "st_isaacs_cathedral", "name": "Saint Isaac's Cathedral", "lat": 59.9341, "lon": 30.3061, "radius_m": 3500.0,
			"wiki_title": "Saint Isaac's Cathedral", "height_m": 101.5, "clear_m": 75.0, "yaw_deg": 53.4,
			"kind": "Cathedral", "aliases": ["saint isaac's cathedral", "st isaac's cathedral", "st. isaac's cathedral",
				"saint isaacs cathedral", "isaakievskiy sobor", "isaakiyevsky cathedral", "исаакиевский собор"]},
		# Moscow
		{"type": "ivan_the_great_bell_tower", "name": "Ivan the Great Bell Tower", "lat": 55.7507, "lon": 37.6182,
			"radius_m": 3500.0, "wiki_title": "Ivan the Great Bell Tower", "height_m": 81.0, "clear_m": 110.0, "yaw_deg": -15.0,
			"kind": "Bell tower", "aliases": ["ivan the great bell tower", "ivan the great", "ivan veliky",
				"колокольня ивана великого", "assumption cathedral, moscow", "dormition cathedral, moscow"]},
		{"type": "christ_the_saviour_cathedral", "name": "Cathedral of Christ the Saviour", "lat": 55.7446, "lon": 37.6056,
			"radius_m": 3500.0, "wiki_title": "Cathedral of Christ the Saviour", "height_m": 103.0, "clear_m": 75.0,
			"kind": "Cathedral", "aliases": ["cathedral of christ the saviour", "christ the saviour cathedral",
				"church of christ the saviour", "храм христа спасителя"]},
		# Kyiv and Bucharest
		{"type": "kyiv_st_sophia", "name": "Saint Sophia Cathedral, Kyiv", "lat": 50.4529, "lon": 30.5143, "radius_m": 3500.0,
			"wiki_title": "Saint Sophia Cathedral, Kyiv", "height_m": 76.0, "clear_m": 95.0, "yaw_deg": 55.7,
			"kind": "Cathedral", "aliases": ["saint sophia cathedral", "st sophia cathedral", "st. sophia cathedral",
				"sophia cathedral in kyiv", "sophia of kyiv", "sophia of kiev", "софійський собор", "софия киевская"]},
		{"type": "palace_of_parliament_bucharest", "name": "Palace of the Parliament", "lat": 44.4275, "lon": 26.0874,
			"radius_m": 4000.0, "wiki_title": "Palace of the Parliament", "height_m": 84.0, "clear_m": 190.0,
			"yaw_deg": -86.5, "kind": "Parliament", "aliases": ["palace of the parliament", "palace of parliament",
				"palatul parlamentului", "casa poporului", "people's house bucharest"]},
	]
