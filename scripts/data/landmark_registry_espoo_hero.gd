class_name LandmarkRegistryEspooHero
extends RefCounted

## Espoo hero additions. Source/measurement notes in docs/espoo-landmark-sources.md.
static func entries() -> Array:
	return [
		{"type": "otaniemi_chapel", "name": "Otaniemi Chapel", "lat": 60.18939, "lon": 24.83731,
			"radius_m": 4500.0, "wiki_title": "Otaniemi Chapel", "height_m": 8.0, "clear_m": 32.0,
			"yaw_deg": 163.6, "kind": "Chapel", "aliases": ["otaniemi chapel", "otaniemen kappeli", "otnäs kapell"]},
		# Pinned at the centre of the auditorium fan; the model follows the
		# whole OSM outline, so clearance subsites cover every wing.
		{"type": "aalto_university_main", "name": "Aalto University Undergraduate Centre", "lat": 60.185614, "lon": 24.827572,
			"radius_m": 5000.0, "wiki_title": "Aalto University Undergraduate Center", "height_m": 21.1, "clear_m": 24.0,
			"clear_offsets_m": [
				[-22.0, -21.0], [-32.0, 8.0], [-36.0, 31.0], [7.0, -80.0], [10.0, -53.0], [10.0, -22.0],
				[49.0, -179.0], [42.0, -149.0], [42.0, -117.0], [42.0, -85.0], [42.0, -53.0], [41.0, -23.0],
				[74.0, -181.0], [74.0, -149.0], [67.0, -122.0], [86.0, -84.0], [74.0, -53.0], [71.0, -26.0],
				[96.0, -153.0], [109.0, -53.0], [136.0, -81.0], [145.0, -57.0]],
			"kind": "University", "aliases": ["aalto university undergraduate centre", "kandidaattikeskus",
				"aalto university main building", "helsinki university of technology main building"]},
		{"type": "tapiola_church", "name": "Tapiola Church", "lat": 60.17774, "lon": 24.80959,
			"radius_m": 4500.0, "wiki_title": "Tapiola Church", "height_m": 16.7, "clear_m": 45.0,
			"yaw_deg": 15.8, "kind": "Church", "aliases": ["tapiola church", "tapiolan kirkko", "hagalunds kyrka"]},
		{"type": "tapiola_central_tower", "name": "Tapiola Central Tower", "lat": 60.17700, "lon": 24.80464,
			"radius_m": 6000.0, "wiki_title": "Tapiola Central Tower", "height_m": 49.0, "clear_m": 20.0,
			"yaw_deg": -74.6, "icon": true, "kind": "Tower", "aliases": ["tapiola central tower", "tapiolan keskustorni", "hagalunds centraltorn"]},
		{"type": "weegee", "name": "WeeGee Exhibition Centre", "lat": 60.17861, "lon": 24.79417,
			"radius_m": 4500.0, "wiki_title": "WeeGee house", "height_m": 14.08, "clear_m": 62.0,
			"yaw_deg": -131.6, "kind": "Museum", "aliases": ["weegee", "weegee exhibition centre", "weegee-talo", "weegee-huset"]},
	]
