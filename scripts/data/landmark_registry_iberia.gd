class_name LandmarkRegistryIberia
extends RefCounted

## Registry entries for the iberia landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetIberia.
## Each model is built front toward +Z (south); yaw_deg turns it onto the
## real bearing (the bearing of its +Z front = 180 + yaw_deg). The Segovia
## aqueduct is built along +X (yaw_deg = bearing of the run - 90) with its
## origin at the Plaza del Azoguejo, where the arches stand tallest.

static func entries() -> Array:
	return [
		{"type": "royal_palace_madrid", "icon": true, "name": "Royal Palace of Madrid", "lat": 40.41780,
			"lon": -3.71425, "radius_m": 4000.0, "wiki_title": "Royal Palace of Madrid", "height_m": 34.5,
			"kind": "Palace", "clear_m": 100.0, "yaw_deg": 4.5,
			"aliases": ["royal palace of madrid", "palacio real de madrid", "palacio de oriente",
				"madrid royal palace"]},
		{"type": "almudena_cathedral", "name": "Almudena Cathedral", "lat": 40.41568, "lon": -3.71455,
			"radius_m": 4000.0, "wiki_title": "Almudena Cathedral", "height_m": 73.0, "kind": "Cathedral",
			"clear_m": 75.0, "yaw_deg": 185.0,
			"aliases": ["almudena cathedral", "catedral de la almudena", "santa maria la real de la almudena",
				"cathedral of the almudena"]},
		{"type": "toledo_alcazar", "name": "Alcázar of Toledo", "lat": 39.85803, "lon": -4.02055,
			"radius_m": 3500.0, "wiki_title": "Alcázar of Toledo", "height_m": 60.0, "kind": "Fortress",
			"clear_m": 70.0, "yaw_deg": 181.6,
			"aliases": ["alcázar of toledo", "alcazar of toledo", "alcázar de toledo", "alcazar de toledo"]},
		{"type": "segovia_aqueduct", "name": "Aqueduct of Segovia", "lat": 40.9480, "lon": -4.1178,
			"radius_m": 3500.0, "wiki_title": "Aqueduct of Segovia", "height_m": 28.5, "kind": "Aqueduct",
			"clear_m": 14.0, "yaw_deg": 58.0, "span_m": 180.0,
			"aliases": ["aqueduct of segovia", "acueducto de segovia", "segovia aqueduct",
				"roman aqueduct of segovia", "puente del diablo segovia"]},
		{"type": "mezquita_cordoba", "name": "Mosque-Cathedral of Córdoba", "lat": 37.87905, "lon": -4.77953,
			"radius_m": 4000.0, "wiki_title": "Mosque–Cathedral of Córdoba", "height_m": 54.0, "kind": "Mosque",
			"clear_m": 85.0, "yaw_deg": -29.3,
			"aliases": ["mosque-cathedral of córdoba", "mosque–cathedral of córdoba", "mosque-cathedral of cordoba",
				"mezquita-catedral de córdoba", "mezquita-catedral de cordoba", "mezquita de córdoba",
				"mezquita de cordoba", "great mosque of córdoba", "great mosque of cordoba"]},
		{"type": "seville_alcazar", "name": "Alcázar of Seville", "lat": 37.38355, "lon": -5.99128,
			"radius_m": 4000.0, "wiki_title": "Alcázar of Seville", "height_m": 25.8, "kind": "Palace",
			"clear_m": 115.0, "yaw_deg": 130.0,
			"aliases": ["alcázar of seville", "alcazar of seville", "real alcázar de sevilla",
				"real alcazar de sevilla", "alcázar de sevilla", "alcazar de sevilla", "seville alcázar",
				"seville alcazar", "palacio de pedro i sevilla"]},
		{"type": "santiago_cathedral", "name": "Santiago de Compostela Cathedral", "lat": 42.88062,
			"lon": -8.54450, "radius_m": 3500.0, "wiki_title": "Santiago de Compostela Cathedral",
			"height_m": 75.0, "kind": "Cathedral", "clear_m": 70.0, "yaw_deg": 83.5,
			"aliases": ["santiago de compostela cathedral", "catedral de santiago de compostela",
				"catedral de santiago", "santiago cathedral", "catedral de compostela", "obradoiro facade"]},
		{"type": "pena_palace", "name": "Pena Palace", "lat": 38.78758, "lon": -9.39049, "radius_m": 3000.0,
			"wiki_title": "Pena Palace", "height_m": 36.0, "kind": "Palace", "clear_m": 75.0, "yaw_deg": 15.0,
			"aliases": ["pena palace", "palácio da pena", "palacio da pena", "palácio nacional da pena",
				"palacio nacional da pena"]},
		{"type": "jeronimos_monastery", "name": "Jerónimos Monastery", "lat": 38.69786, "lon": -9.20663,
			"radius_m": 4000.0, "wiki_title": "Jerónimos Monastery", "height_m": 56.0, "kind": "Monastery",
			"clear_m": 140.0, "yaw_deg": -15.0,
			"aliases": ["jerónimos monastery", "jeronimos monastery", "mosteiro dos jerónimos",
				"mosteiro dos jeronimos", "hieronymites monastery"]},
	]
