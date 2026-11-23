class_name LandmarkRegistryFinlandHelsinki
extends RefCounted

## Registry entries for the finland_helsinki landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetFinlandHelsinki.

const CentreModels = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_centre_models.gd")

static func entries() -> Array:
	return [
		{"type": "parliament_house_helsinki", "name": "Parliament House, Helsinki", "lat": 60.17258, "lon": 24.93294,
			"radius_m": 5000.0, "wiki_title": "Parliament House, Helsinki", "height_m": 35.0, "clear_m": 76.0,
			"yaw_deg": 73.0, "kind": "Parliament", "aliases": ["parliament house, helsinki", "eduskuntatalo",
				"finnish parliament house", "riksdagshuset helsingfors"]},
		{"type": "dipoli", "name": "Dipoli", "lat": 60.18513, "lon": 24.83249,
			"radius_m": 4000.0, "wiki_title": "Dipoli", "height_m": 11.0, "clear_m": 62.0,
			"yaw_deg": 17.0, "kind": "Congress centre", "aliases": ["dipoli", "dipoli otaniemi", "dipoli espoo",
				"dipoli aalto university"]},
		{"type": "heureka_science_centre", "name": "Heureka Science Centre", "lat": 60.28750, "lon": 25.04047,
			"radius_m": 4000.0, "wiki_title": "Heureka", "height_m": 22.0, "clear_m": 85.0,
			"yaw_deg": 15.0, "kind": "Science centre", "aliases": ["heureka science centre", "tiedekeskus heureka",
				"heureka vantaa", "finnish science centre heureka"]},
		{"type": "lasipalatsi", "name": "Lasipalatsi", "lat": 60.170231, "lon": 24.936695,
			"radius_m": 5000.0, "wiki_title": "Lasipalatsi", "height_m": 24.0, "clear_m": 20.0,
			"clear_rect_m": [-6.0, -3.0, 58.0, 62.0], "kind": "Commercial building",
			"aliases": ["lasipalatsi", "glass palace", "glaspalatset"]},
		{"type": "suomenlinna_fortress", "name": "Suomenlinna Fortress", "lat": 60.14786, "lon": 24.98637,
			"radius_m": 4500.0, "wiki_title": "Suomenlinna", "height_m": 42.0, "clear_m": 27.0,
			"yaw_deg": -62.0, "kind": "Fortress", "aliases": ["suomenlinna fortress", "suomenlinna", "sveaborg",
				"suomenlinnan kirkko", "king's gate, suomenlinna"]},
		{"type": "hanko_water_tower", "name": "Hanko Water Tower", "lat": 59.82486, "lon": 22.97052,
			"radius_m": 3500.0, "wiki_title": "Hanko, Finland", "height_m": 48.0, "clear_m": 22.0,
			"kind": "Tower", "aliases": ["hanko water tower", "hangon vesitorni", "hangö vattentorn"]},
		{"type": "espoo_cathedral", "name": "Espoo Cathedral", "lat": 60.20938, "lon": 24.65229,
			"radius_m": 4000.0, "wiki_title": "Espoo Cathedral", "height_m": 24.0, "clear_m": 46.0,
			"kind": "Cathedral", "aliases": ["espoo cathedral", "espoon tuomiokirkko", "esbo domkyrka"]},
		{"type": "porvoo_cathedral", "name": "Porvoo Cathedral", "lat": 60.39718, "lon": 25.65785,
			"radius_m": 4000.0, "wiki_title": "Porvoo Cathedral", "height_m": 20.5, "clear_m": 50.0,
			"yaw_deg": -7.0, "kind": "Cathedral", "aliases": ["porvoo cathedral", "porvoon tuomiokirkko", "borgå domkyrka"]},
		# Built along its mapped curve at yaw 0: `clear_path_m` (not the
		# straight `span_m`) is the corridor its model replaces. Framed
		# side-on from the open water south-south-west of it, far enough
		# for all 1.2 km to fit the view (it runs WNW-ESE, so the default
		# WSW eye looked along it), the afternoon sun behind the eye.
		{"type": "kruunuvuorensilta", "name": "Kruunuvuorensilta", "lat": 60.1736, "lon": 25.0022,
			"radius_m": 6000.0, "wiki_title": "Crown Bridges", "height_m": 135.0, "clear_m": 15.0,
			"yaw_deg": 0.0, "span_m": 1195.0, "base": "sea", "kind": "Bridge",
			"frame_m": 700.0, "frame_bearing_deg": 215.0,
			"clear_path_m": KruunuvuorensiltaLine.clear_path(),
			"aliases": ["kruunuvuorensilta", "kruunuvuori bridge", "crown bridge helsinki", "kronbergsbron",
				"kruunusillat"]},
		{"type": "itis_shopping_centre", "name": "Itis Shopping Centre", "lat": 60.212044, "lon": 25.082692,
			"radius_m": 4000.0, "wiki_title": "Itis (shopping centre)", "height_m": 25.0, "clear_m": 40.0,
			"clear_offsets_m": [
				[-1.0, 33.0], [39.0, -37.0], [99.0, -87.0], [-71.0, 128.0], [-146.0, 188.0], [69.0, 3.0],
				[-46.0, 73.0], [134.0, -127.0], [19.0, 73.0], [-186.0, 208.0], [114.0, -52.0],
				[-96.0, 158.0], [79.0, -102.0], [-11.0, 8.0], [24.0, -57.0], [-86.0, 113.0], [34.0, 28.0],
				[-61.0, 138.0], [4.0, 88.0], [124.0, -102.0], [-16.0, 28.0], [64.0, -82.0], [79.0, -27.0],
				[129.0, -127.0], [-56.0, 78.0], [59.0, -82.0], [-91.0, 108.0]],
			"kind": "Shopping centre", "aliases": ["itis shopping centre", "kauppakeskus itis", "itis itakeskus"]},
		{"type": "iso_omena", "name": "Iso Omena", "lat": 60.161240, "lon": 24.738512,
			"radius_m": 4000.0, "wiki_title": "Iso Omena", "height_m": 24.0, "clear_m": 40.0,
			"clear_offsets_m": [
				[-91.0, -113.0], [-36.0, -28.0], [-11.0, 47.0], [14.0, 122.0], [34.0, 2.0], [59.0, 77.0],
				[-36.0, -98.0], [-66.0, -153.0], [14.0, -43.0], [69.0, 117.0], [-56.0, -8.0],
				[-11.0, 132.0], [-31.0, 62.0], [-111.0, -118.0], [-76.0, -93.0], [49.0, 57.0],
				[4.0, 147.0], [-36.0, 2.0], [-101.0, -108.0], [-51.0, -23.0], [79.0, 107.0],
				[-61.0, -133.0], [24.0, 117.0], [-91.0, -128.0], [24.0, 122.0], [-36.0, -73.0]],
			"kind": "Shopping centre", "aliases": ["iso omena", "kauppakeskus iso omena", "iso omena espoo"]},
		{"type": "sello_shopping_centre", "name": "Sello Shopping Centre", "lat": 60.217948, "lon": 24.812562,
			"radius_m": 4000.0, "wiki_title": "Sello", "height_m": 22.0, "clear_m": 40.0,
			"clear_offsets_m": [
				[-52.0, -54.0], [18.0, -14.0], [23.0, -69.0], [-52.0, 1.0], [-52.0, -79.0], [23.0, 6.0],
				[-57.0, -34.0], [23.0, -39.0], [-17.0, -59.0], [38.0, 6.0], [-27.0, -9.0], [-67.0, -69.0],
				[33.0, -69.0], [-62.0, -4.0], [43.0, 16.0]],
			"kind": "Shopping centre", "aliases": ["sello shopping centre", "kauppakeskus sello", "sello leppavaara"]},
		{"type": "jumbo_shopping_centre", "name": "Jumbo Shopping Centre", "lat": 60.291594, "lon": 24.965678,
			"radius_m": 4000.0, "wiki_title": "Jumbo (shopping centre)", "height_m": 18.0, "clear_m": 40.0,
			"clear_offsets_m": [
				[-144.0, -105.0], [-24.0, 5.0], [-24.0, 85.0], [-29.0, -75.0], [26.0, 135.0],
				[36.0, -35.0], [36.0, 45.0], [-84.0, -95.0], [-34.0, 145.0], [36.0, 95.0], [-44.0, 45.0],
				[11.0, -60.0], [-149.0, -85.0], [-149.0, -125.0], [-34.0, -25.0], [31.0, 0.0],
				[-34.0, -95.0], [26.0, 150.0], [-29.0, 110.0], [-119.0, -100.0], [31.0, -45.0],
				[36.0, 140.0], [-39.0, 145.0], [-159.0, -120.0]],
			"kind": "Shopping centre", "aliases": ["jumbo shopping centre", "kauppakeskus jumbo", "jumbo flamingo vantaa"]},
	] + LandmarkRegistryHelsinkiHero.entries() + LandmarkRegistryEspooHero.entries() \
		+ LandmarkRegistryWestMetro.entries() + LandmarkRegistryInnerHelsinki.entries() \
		+ CentreModels.entries()
