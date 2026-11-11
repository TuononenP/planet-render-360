class_name LandmarkRegistryWestMetro
extends RefCounted

## Keilaniemi, Tapiola-centre, Lauttasaari and Niittykumpu landmarks, extruded from
## OSM outlines (LandmarkFhWestFootprints). Entry lat/lon is the outline
## origin; outline-built models clear their footprint through
## clear_offsets_m ([x east, z south] about the entry, yaw 0). Sources:
## docs/espoo-landmark-sources.md and docs/helsinki-landmark-sources.md.
static func entries() -> Array:
	return [
		{"type": "finago_tower", "skyline_priority": 1, "name": "Finago Tower", "lat": 60.174882, "lon": 24.830781,
			"radius_m": 6000.0, "wiki_title": "Finago Tower", "height_m": 83.6, "clear_m": 36.0,
			"kind": "Tower", "aliases": ["finago tower", "fortum tower", "neste tower", "accountor tower",
				"fortumin pääkonttori", "keilaniemen torni", "raaden hammas"]},
		{"type": "kone_building", "name": "KONE Building", "lat": 60.172155, "lon": 24.828705,
			"radius_m": 5000.0, "wiki_title": "Keilaniemi", "height_m": 72.6, "clear_m": 25.0,
			"kind": "Tower", "aliases": ["kone building", "kone-talo", "kone headquarters", "kone keilaniemi"]},
		{"type": "keilalampi", "name": "Keilalampi", "lat": 60.174005, "lon": 24.829972,
			"radius_m": 3000.0, "wiki_title": "Finago Tower", "height_m": 22.4, "clear_m": 30.0,
			"clear_offsets_m": [[29.0, -15.0], [25.0, 13.0], [5.0, -39.0]],
			"kind": "Office", "aliases": ["keilalampi", "valovirta", "keilalampi office"]},
		{"type": "espoo_cultural_centre", "name": "Espoo Cultural Centre", "lat": 60.177892, "lon": 24.804577,
			"radius_m": 4500.0, "wiki_title": "Espoo Cultural Centre", "height_m": 21.0, "clear_m": 30.0,
			"clear_offsets_m": [[-10.0, -33.0], [-14.0, 31.0], [-6.0, -33.0]],
			"kind": "Arts centre", "aliases": ["espoo cultural centre", "espoon kulttuurikeskus",
				"esbo kulturcentrum", "tapiola cultural centre", "tapiolasali"]},
		{"type": "mantytorni", "name": "Mäntytorni", "lat": 60.179173, "lon": 24.811752,
			"radius_m": 4000.0, "wiki_title": "Tapiola", "height_m": 31.0, "clear_m": 18.0,
			"kind": "Apartment tower", "aliases": ["mäntytorni", "mantytorni", "talltornet", "tapiola pine tower"]},
		{"type": "tapiola_hip_flask_houses", "name": "Hip Flask Houses", "lat": 60.175407, "lon": 24.795376,
			"radius_m": 4000.0, "wiki_title": "Hip flask houses", "height_m": 30.0, "clear_m": 20.0,
			"clear_offsets_m": [[-24.4, 62.8], [-12.4, -122.5], [25.3, -68.5]],
			"kind": "Apartment blocks", "aliases": ["hip flask houses", "taskumattitalot", "fickpluntshusen",
				"revell hip flask houses"]},
		{"type": "lauttasaari_church", "name": "Lauttasaari Church", "lat": 60.158735, "lon": 24.869437,
			"radius_m": 5000.0, "wiki_title": "Lauttasaari Church", "height_m": 61.0, "clear_m": 24.0,
			"clear_offsets_m": [[-5.0, 24.0], [-5.0, -28.0], [-37.0, 12.0], [-1.0, 8.0]],
			"kind": "Church", "aliases": ["lauttasaari church", "lauttasaaren kirkko", "drumsö kyrka"]},
		{"type": "lauttasaari_manor", "name": "Lauttasaari Manor", "lat": 60.159028, "lon": 24.879080,
			"radius_m": 3500.0, "wiki_title": "Lauttasaari Manor", "height_m": 12.5, "clear_m": 19.0,
			"kind": "Manor", "aliases": ["lauttasaari manor", "lauttasaaren kartano", "drumsö gård"]},
		{"type": "niittyhuippu", "skyline_priority": 1, "name": "Niittyhuippu", "lat": 60.170240, "lon": 24.764026,
			"radius_m": 6000.0, "wiki_title": "Niittykumpu", "height_m": 90.0, "clear_m": 26.0,
			"kind": "Tower", "aliases": ["niittyhuippu", "niittyhuippu tower", "niittykumpu tower", "ängskullen torn"]},
		{"type": "niittytori_tower", "name": "Niittytori Tower", "lat": 60.170501, "lon": 24.762190,
			"radius_m": 4000.0, "wiki_title": "Niittykumpu", "height_m": 38.0, "clear_m": 25.0,
			"kind": "Tower", "aliases": ["niittytori tower", "niittytori", "niittytorni"]},
		{"type": "niitty_shopping_centre", "name": "Niitty Shopping Centre", "lat": 60.170331, "lon": 24.763399,
			"radius_m": 4000.0, "wiki_title": "Niittykumpu metro station", "height_m": 14.0, "clear_m": 30.0,
			"clear_offsets_m": [[40.6, 34.5], [-47.4, -21.5], [12.6, -13.5], [44.6, 46.5], [-39.4, -33.5], [24.6, -5.5]],
			"kind": "Shopping centre", "aliases": ["niitty shopping centre", "kauppakeskus niitty", "niittykummun metrokeskus",
				"niittykumpu metro centre"]},
		{"type": "niittytaival_tower", "name": "Niittytaival Tower", "lat": 60.170304, "lon": 24.772865,
			"radius_m": 3500.0, "wiki_title": "Niittykumpu", "height_m": 50.5, "clear_m": 24.0,
			"kind": "Tower", "aliases": ["niittytaival tower", "niittytaival 5", "niittykumpu dark tower"]},
		{"type": "olari_church", "name": "Olari Church", "lat": 60.172126, "lon": 24.759892,
			"radius_m": 4500.0, "wiki_title": "Olari Church", "height_m": 13.0, "clear_m": 31.0,
			"kind": "Church", "aliases": ["olari church", "olarin kirkko", "olars kyrka"]},
	]
