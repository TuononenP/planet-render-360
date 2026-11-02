class_name LandmarkRegistryMainlandSeAsia
extends RefCounted

## Registry entries for the mainland south-east Asia landmark batch, in the
## format of LocationData.landmarks(). Types are built by
## LandmarkSetMainlandSeAsia. Bangkok: the Grand Palace is the icon of a
## city-centre search; Wat Pho and Wat Arun appear beside it. The Hue gate
## and the Saigon cathedral are turned onto the real bearings of their sites
## (Ngo Mon faces about 143 degrees, the cathedral facade about 138).
## The cathedral stands 60.5 m to the top of its tower crosses (57.6 m
## towers, 3.5 m crosses; Vietnamese Wikipedia).

static func entries() -> Array:
	return [
		{"type": "grand_palace_bangkok", "name": "Grand Palace (Bangkok)",
			"lat": 13.75101, "lon": 100.49188, "radius_m": 5000.0,
			"wiki_title": "Grand Palace", "height_m": 45.0, "clear_m": 220.0,
			"kind": "Palace", "icon": true,
			"aliases": ["grand palace (bangkok)", "grand palace bangkok", "grand palace, bangkok",
				"phra borom maha ratcha wang", "chakri maha prasat", "temple of the emerald buddha",
				"wat phra si rattana satsadaram", "พระบรมมหาราชวัง", "วัดพระศรีรัตนศาสดาราม"]},
		{"type": "wat_pho", "name": "Wat Pho (Temple of the Reclining Buddha)",
			"lat": 13.74668, "lon": 100.49237, "radius_m": 5000.0,
			"wiki_title": "Wat Pho", "height_m": 42.0, "clear_m": 135.0,
			"kind": "Temple",
			"aliases": ["wat pho (temple of the reclining buddha)", "wat pho", "wat phra chetuphon",
				"wat phra chetuphon vimolmangklararm", "temple of the reclining buddha", "วัดโพธิ์",
				"วัดพระเชตุพนวิมลมังคลาราม"]},
		{"type": "wat_chaiwatthanaram", "name": "Wat Chaiwatthanaram",
			"lat": 14.3431, "lon": 100.5417, "radius_m": 4000.0,
			"wiki_title": "Wat Chaiwatthanaram", "height_m": 35.0, "clear_m": 95.0,
			"kind": "Temple",
			"aliases": ["wat chaiwatthanaram", "wat chaiwattanaram", "wat chai watthanaram", "วัดไชยวัฒนาราม"]},
		{"type": "wat_rong_khun", "name": "Wat Rong Khun (White Temple)",
			"lat": 19.8247, "lon": 99.7633, "radius_m": 3000.0,
			"wiki_title": "Wat Rong Khun", "height_m": 30.0, "clear_m": 75.0,
			"kind": "Temple",
			"aliases": ["wat rong khun (white temple)", "wat rong khun", "white temple chiang rai", "วัดร่องขุ่น"]},
		{"type": "temple_of_literature_hanoi", "name": "Temple of Literature (Hanoi)",
			"lat": 21.02858, "lon": 105.83589, "radius_m": 4500.0,
			"wiki_title": "Temple of Literature, Hanoi", "height_m": 13.3, "clear_m": 150.0,
			"kind": "Temple",
			"aliases": ["temple of literature (hanoi)", "temple of literature hanoi", "temple of literature, hanoi",
				"van mieu quoc tu giam", "văn miếu quốc tử giám", "khue van cac", "khuê văn các"]},
		{"type": "one_pillar_pagoda", "name": "One Pillar Pagoda",
			"lat": 21.03584, "lon": 105.83361, "radius_m": 4500.0,
			"wiki_title": "One Pillar Pagoda", "height_m": 9.4, "clear_m": 32.0,
			"kind": "Pagoda",
			"aliases": ["one pillar pagoda", "chùa một cột", "chua mot cot", "dien huu pagoda", "diên hựu"]},
		{"type": "hue_ngo_mon_gate", "name": "Ngo Mon Gate (Hue)",
			"lat": 16.46773, "lon": 107.57915, "radius_m": 4000.0,
			"wiki_title": "Meridian Gate (Huế)", "height_m": 17.0, "clear_m": 45.0, "yaw_deg": -37.0,
			"kind": "Gate",
			"aliases": ["ngo mon gate (hue)", "ngo mon gate", "ngọ môn", "noon gate hue", "meridian gate hue",
				"five phoenix pavilion", "lầu ngũ phụng"]},
		{"type": "saigon_notre_dame", "name": "Notre-Dame Cathedral Basilica of Saigon",
			"lat": 10.77977, "lon": 106.69904, "radius_m": 4500.0,
			"wiki_title": "Saigon Notre-Dame Basilica", "height_m": 60.5, "clear_m": 62.0, "yaw_deg": -42.0,
			"kind": "Cathedral",
			"aliases": ["notre-dame cathedral basilica of saigon", "saigon notre-dame basilica",
				"saigon notre dame cathedral", "notre dame cathedral saigon", "notre-dame cathedral saigon",
				"nhà thờ đức bà sài gòn", "basilica of our lady of the immaculate conception"]},
		{"type": "pha_that_luang", "name": "Pha That Luang",
			"lat": 17.97666, "lon": 102.63649, "radius_m": 4000.0,
			"wiki_title": "Pha That Luang", "height_m": 45.0, "clear_m": 70.0,
			"kind": "Stupa",
			"aliases": ["pha that luang", "that luang stupa", "great stupa vientiane", "ພະທາດຫຼວງ"]},
		{"type": "ananda_temple_bagan", "name": "Ananda Temple (Bagan)",
			"lat": 21.17084, "lon": 94.86769, "radius_m": 3500.0,
			"wiki_title": "Ananda Temple", "height_m": 51.0, "clear_m": 58.0,
			"kind": "Temple",
			"aliases": ["ananda temple (bagan)", "ananda temple bagan", "ananda temple, bagan", "ananda pahto",
				"ananda phaya", "အာနန္ဒာဘုရား"]},
	]
