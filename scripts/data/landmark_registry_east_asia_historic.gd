class_name LandmarkRegistryEastAsiaHistoric
extends RefCounted

## Registry entries for the east_asia_historic landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetEastAsiaHistoric.

static func entries() -> Array:
	return [
		{"type": "terracotta_army_pit1", "name": "Terracotta Army (Pit 1)", "lat": 34.3851, "lon": 109.2732,
			"radius_m": 5000.0, "wiki_title": "Terracotta Army", "height_m": 22.0, "clear_m": 50.0,
			"span_m": 230.0, "kind": "Museum hall", "aliases": ["terracotta army", "terracotta warriors",
				"terracotta soldiers", "bingmayong", "兵马俑一号坑", "秦始皇兵马俑", "秦兵马俑博物馆"]},
		{"type": "big_wild_goose_pagoda", "name": "Big Wild Goose Pagoda", "lat": 34.2198, "lon": 108.9594,
			"radius_m": 4000.0, "wiki_title": "Giant Wild Goose Pagoda", "height_m": 64.5, "clear_m": 55.0,
			"kind": "Pagoda", "aliases": ["big wild goose pagoda", "giant wild goose pagoda", "dayan pagoda",
				"dayanta", "大慈恩寺大雁塔", "西安大雁塔"]},
		{"type": "summer_palace_buddhist_incense", "name": "Tower of Buddhist Incense (Summer Palace)",
			"lat": 39.9990, "lon": 116.2740, "radius_m": 4000.0, "wiki_title": "Summer Palace",
			"height_m": 61.0, "clear_m": 55.0, "kind": "Pagoda tower", "aliases": ["tower of buddhist incense",
				"summer palace", "foxiangge", "foxiang ge", "颐和园佛香阁", "万寿山佛香阁"]},
		{"type": "tiananmen_gate", "name": "Tiananmen (Gate of Heavenly Peace)", "lat": 39.9074, "lon": 116.3913,
			"radius_m": 4000.0, "wiki_title": "Tiananmen", "height_m": 33.7, "clear_m": 62.0,
			"kind": "Gate", "aliases": ["tiananmen", "gate of heavenly peace", "天安门城楼", "北京天安门城楼"]},
		{"type": "leshan_giant_buddha", "name": "Leshan Giant Buddha", "lat": 29.5447, "lon": 103.7733,
			"radius_m": 4000.0, "wiki_title": "Leshan Giant Buddha", "height_m": 71.0, "clear_m": 40.0,
			"yaw_deg": 90.0, "kind": "Statue", "aliases": ["leshan giant buddha", "leshan buddha",
				"leshan dafo", "lingyun buddha", "乐山大佛景区", "凌云山大佛"]},
		{"type": "todaiji_daibutsuden", "name": "Todai-ji Great Buddha Hall (Daibutsuden)", "lat": 34.6890,
			"lon": 135.8398, "radius_m": 4000.0, "wiki_title": "Tōdai-ji", "height_m": 48.7, "clear_m": 55.0,
			"kind": "Temple hall", "aliases": ["todai-ji", "todaiji", "daibutsuden", "great buddha hall",
				"東大寺大仏殿", "東大寺金堂"]},
		{"type": "kiyomizu_dera", "name": "Kiyomizu-dera (Main Hall)", "lat": 34.9949, "lon": 135.7850,
			"radius_m": 4000.0, "wiki_title": "Kiyomizu-dera", "height_m": 30.0, "clear_m": 40.0,
			"kind": "Temple", "aliases": ["kiyomizu-dera", "kiyomizudera", "kiyomizu temple", "清水寺本堂",
				"清水の舞台"]},
		{"type": "osaka_castle", "name": "Osaka Castle", "lat": 34.6874, "lon": 135.5259,
			"radius_m": 4000.0, "wiki_title": "Osaka Castle", "height_m": 55.0, "clear_m": 55.0,
			"kind": "Castle", "aliases": ["osaka castle", "osaka-jo", "osakajo", "大阪城天守閣", "大阪城公園"]},
		{"type": "matsumoto_castle", "name": "Matsumoto Castle", "lat": 36.2386, "lon": 137.9688,
			"radius_m": 3500.0, "wiki_title": "Matsumoto Castle", "height_m": 29.4, "clear_m": 60.0,
			"kind": "Castle", "aliases": ["matsumoto castle", "matsumoto-jo", "matsumotojo", "karasu-jo",
				"crow castle", "松本城天守"]},
		{"type": "senso_ji", "name": "Senso-ji (Asakusa Kannon Temple)", "lat": 35.71301, "lon": 139.79629,
			"radius_m": 4000.0, "wiki_title": "Sensō-ji", "height_m": 53.0, "clear_m": 55.0,
			"yaw_deg": -85.15, "span_m": 425.0, "kind": "Temple", "aliases": ["senso-ji", "sensoji",
				"asakusa temple", "kaminarimon", "hozomon", "nakamise", "浅草寺五重塔", "浅草寺雷門"]},
	]
