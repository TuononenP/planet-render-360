class_name LandmarkRegistryTokyoSeoul
extends RefCounted

## Registry entries for the Tokyo (Shibuya Crossing) and Seoul (Gwanghwamun
## Square) preset surroundings, in the format of LocationData.landmarks().
## Types are built by LandmarkSetTokyoSeoul. Sites, footprints, heights and
## bearings come from the bundled OSM snapshots (assets/osm_snapshots/
## {tokyo,seoul}_detailed.json.gz and seoul_poi.json.gz); see
## docs/tokyo-seoul-landmark-sources.md. A site is the area centroid of the
## OSM footprint the model replaces; yaw_deg = true bearing of the model's
## +X - 90 (axis = cos, sin in x east, z south). The palace grid of
## Gyeongbokgung runs 2 degrees clockwise of north (+X bears 92); the
## Shibuya towers follow their footprints' long edges. Statues face south
## (+Z) as OSM `direction=180` gives.

static func entries() -> Array:
	return [
		# Shibuya, round the scramble crossing.
		{"type": "shibuya_scramble_square", "name": "Shibuya Scramble Square", "lat": 35.658367, "lon": 139.702221,
			"radius_m": 5000.0, "wiki_title": "Shibuya Scramble Square", "height_m": 229.7, "clear_m": 30.0,
			"yaw_deg": -21.0, "kind": "Skyscraper",
			"aliases": ["shibuya scramble square", "scramble square", "shibuya sky", "渋谷スクランブルスクエア"]},
		{"type": "shibuya_hikarie", "name": "Shibuya Hikarie", "lat": 35.659115, "lon": 139.703760,
			"radius_m": 4000.0, "wiki_title": "Shibuya Hikarie", "height_m": 182.5, "clear_m": 38.0,
			"yaw_deg": -20.0, "kind": "Skyscraper", "aliases": ["shibuya hikarie", "hikarie", "渋谷ヒカリエ"]},
		{"type": "shibuya_stream", "name": "Shibuya Stream", "lat": 35.657190, "lon": 139.703151,
			"radius_m": 4000.0, "wiki_title": "Shibuya Stream", "height_m": 180.0, "clear_m": 25.0,
			"yaw_deg": 44.0, "kind": "Skyscraper", "aliases": ["shibuya stream", "渋谷ストリーム"]},
		{"type": "shibuya_109", "name": "Shibuya 109", "lat": 35.659589, "lon": 139.698717,
			"radius_m": 1500.0, "wiki_title": "109 (department store)", "height_m": 33.6, "clear_m": 15.0,
			"kind": "Department store", "aliases": ["shibuya 109", "shibuya109", "ichi-maru-kyu", "渋谷109"]},
		{"type": "qfront", "name": "QFRONT", "lat": 35.659880, "lon": 139.700363,
			"radius_m": 1500.0, "wiki_title": "Q-Front", "height_m": 45.9, "clear_m": 12.0,
			"kind": "Video screen", "aliases": ["qfront", "q-front", "q front shibuya"]},
		# Gwanghwamun Square and Gyeongbokgung, north of it.
		{"type": "king_sejong_statue", "name": "Statue of King Sejong", "lat": 37.5729184, "lon": 126.9769125,
			"radius_m": 1500.0, "wiki_title": "Statue of King Sejong (Gwanghwamun)", "height_m": 10.4, "clear_m": 8.0,
			"kind": "Statue", "aliases": ["statue of king sejong", "king sejong statue", "sejong the great statue",
				"세종대왕동상", "세종대왕 동상"]},
		{"type": "yi_sun_sin_statue", "name": "Statue of Admiral Yi Sun-sin", "lat": 37.5709682, "lon": 126.9769505,
			"radius_m": 1500.0, "wiki_title": "Statue of Admiral Yi Sun-sin", "height_m": 17.0, "clear_m": 8.0,
			"kind": "Statue", "aliases": ["statue of admiral yi sun-sin", "admiral yi sun-sin statue",
				"yi sun-sin statue", "이순신장군 동상", "이순신 동상"]},
		{"type": "gyeongbokgung_walls", "name": "Gyeongbokgung Palace Walls", "lat": 37.575937, "lon": 126.9769,
			"radius_m": 2000.0, "wiki_title": "Gyeongbokgung", "height_m": 4.0, "clear_m": 1.0,
			"kind": "Palace wall", "aliases": ["gyeongbokgung palace walls", "gyeongbokgung walls", "경복궁 궁장"]},
		{"type": "heungnyemun", "name": "Heungnyemun", "lat": 37.576954, "lon": 126.976905,
			"radius_m": 2500.0, "wiki_title": "Gyeongbokgung", "height_m": 15.0, "clear_m": 14.0,
			"yaw_deg": 2.0, "kind": "Palace gate", "aliases": ["heungnyemun", "heungnyemun gate", "경복궁 흥례문"]},
		{"type": "geunjeongjeon", "name": "Geunjeongjeon", "lat": 37.578334, "lon": 126.976958,
			"radius_m": 3000.0, "wiki_title": "Geunjeongjeon", "height_m": 27.8, "clear_m": 14.0,
			"yaw_deg": 2.0, "kind": "Throne hall",
			"clear_offsets_m": [
				[2.0, -23.0], [-10.0, -32.0], [14.0, -32.0], [-10.0, -14.0], [14.0, -14.0],
				[1.0, 67.0], [1.5, -60.0]],
			"aliases": ["geunjeongjeon", "geunjeongjeon hall", "gyeongbokgung throne hall", "gyeongbokgung palace",
				"gyeongbokgung", "경복궁 근정전"]},
	]
