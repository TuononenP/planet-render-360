class_name LandmarkRegistryItalyHistoric
extends RefCounted

## Registry entries for the italy_historic landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetItalyHistoric.
## San Gimignano and Bologna are built in the true compass frame (no yaw);
## the others carry yaw_deg = the real bearing of the model's +Z (front or
## forum axis) minus 180.

static func entries() -> Array:
	return [
		{"type": "pompeii_forum", "name": "Forum of Pompeii", "lat": 40.74941, "lon": 14.48476,
			"radius_m": 3000.0, "wiki_title": "Pompeii", "height_m": 10.6, "kind": "Ruins",
			"clear_m": 92.0, "yaw_deg": -20.0,
			"aliases": ["forum of pompeii", "pompeii forum", "foro di pompei", "temple of jupiter pompeii",
				"tempio di giove pompei", "pompeii archaeological site", "scavi di pompei"]},
		{"type": "verona_arena", "name": "Verona Arena", "lat": 45.43900, "lon": 10.99440,
			"radius_m": 3000.0, "wiki_title": "Verona Arena", "height_m": 31.0, "kind": "Amphitheatre",
			"clear_m": 82.0, "yaw_deg": 54.0,
			"aliases": ["verona arena", "arena di verona", "arena of verona", "verona amphitheatre",
				"verona amphitheater"]},
		{"type": "palazzo_vecchio", "name": "Palazzo Vecchio", "lat": 43.76929, "lon": 11.25619,
			"radius_m": 3000.0, "wiki_title": "Palazzo Vecchio", "height_m": 94.0, "kind": "Palace",
			"clear_m": 72.0, "yaw_deg": 102.0,
			"aliases": ["palazzo vecchio", "torre di arnolfo", "arnolfo tower", "piazza della signoria",
				"palazzo della signoria"]},
		{"type": "torre_del_mangia", "name": "Torre del Mangia", "lat": 43.31809, "lon": 11.33191,
			"radius_m": 3500.0, "wiki_title": "Torre del Mangia", "height_m": 102.0, "kind": "Tower",
			"clear_m": 70.0, "yaw_deg": 138.0,
			"aliases": ["torre del mangia", "mangia tower", "palazzo pubblico siena", "palazzo pubblico di siena",
				"palazzo pubblico, siena", "piazza del campo"]},
		{"type": "san_gimignano_towers", "name": "San Gimignano Towers", "lat": 43.46763, "lon": 11.04290,
			"radius_m": 2500.0, "wiki_title": "San Gimignano", "height_m": 54.0, "kind": "Towers",
			"clear_m": 62.0,
			"aliases": ["san gimignano towers", "towers of san gimignano", "torri di san gimignano", "torre grossa",
				"san gimignano"]},
		{"type": "bologna_two_towers", "name": "Two Towers of Bologna", "lat": 44.49418, "lon": 11.34674,
			"radius_m": 3000.0, "wiki_title": "Two Towers, Bologna", "height_m": 97.2, "kind": "Towers",
			"clear_m": 32.0,
			"aliases": ["two towers of bologna", "two towers, bologna", "due torri", "le due torri",
				"torre degli asinelli", "asinelli tower", "torre garisenda", "garisenda tower", "torri di bologna"]},
		{"type": "mole_antonelliana", "name": "Mole Antonelliana", "lat": 45.06889, "lon": 7.69306,
			"radius_m": 4000.0, "wiki_title": "Mole Antonelliana", "height_m": 167.5, "kind": "Tower",
			"clear_m": 48.0, "yaw_deg": 28.0,
			"aliases": ["mole antonelliana", "museo nazionale del cinema", "national museum of cinema turin"]},
		{"type": "st_marks_basilica_venice", "name": "St Mark's Basilica", "lat": 45.43452, "lon": 12.33970,
			"radius_m": 3000.0, "wiki_title": "St Mark's Basilica", "height_m": 43.0, "kind": "Basilica",
			"clear_m": 58.0, "yaw_deg": 73.0,
			"aliases": ["st mark's basilica", "st marks basilica", "saint mark's basilica", "saint marks basilica",
				"basilica di san marco", "basilica san marco", "san marco basilica"]},
		{"type": "bridge_of_sighs", "name": "Bridge of Sighs", "lat": 45.43406, "lon": 12.34086,
			"radius_m": 2000.0, "wiki_title": "Bridge of Sighs", "height_m": 11.85, "kind": "Bridge",
			"clear_m": 20.0, "yaw_deg": -14.0,
			"aliases": ["bridge of sighs", "ponte dei sospiri", "ponte dei sospiri venezia", "bridge of sighs venice"]},
		{"type": "basilica_st_francis_assisi", "name": "Basilica of St Francis of Assisi", "lat": 43.07480,
			"lon": 12.60565, "radius_m": 3000.0, "wiki_title": "Basilica of Saint Francis of Assisi",
			"height_m": 62.0, "kind": "Basilica", "clear_m": 66.0, "yaw_deg": -73.0,
			"aliases": ["basilica of st francis of assisi", "basilica of saint francis of assisi",
				"basilica of st. francis of assisi", "basilica di san francesco", "basilica di san francesco d'assisi",
				"basilica papale di san francesco", "san francesco d'assisi"]},
	]
