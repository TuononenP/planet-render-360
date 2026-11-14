class_name LandmarkRegistryAsiaSouth
extends RefCounted

## Registry entries for the south and south-east Asia landmark batch, in
## the format of LocationData.landmarks(). Types are built by
## LandmarkSetAsiaSouth. Petronas stands for both towers (the registry
## point is the midpoint between them).

static func entries() -> Array:
	return [
		{"type": "taj_mahal", "icon": true, "name": "Taj Mahal", "lat": 27.1751, "lon": 78.0421, "radius_m": 3000.0,
			"wiki_title": "Taj Mahal", "height_m": 73.0, "clear_m": 170.0,
			"kind": "Mausoleum", "aliases": ["taj mahal", "tajmahal", "ताजमहल"]},
		{"type": "india_gate", "name": "India Gate", "lat": 28.6129, "lon": 77.2295, "radius_m": 3000.0,
			"wiki_title": "India Gate", "height_m": 42.0, "clear_m": 50.0, "yaw_deg": 90.0,
			"kind": "War memorial", "aliases": ["india gate", "all india war memorial", "इंडिया गेट"]},
		{"type": "qutub_minar", "name": "Qutub Minar", "lat": 28.5245, "lon": 77.1855, "radius_m": 2500.0,
			"wiki_title": "Qutb Minar", "height_m": 72.5, "clear_m": 45.0,
			"kind": "Minaret", "aliases": ["qutub minar", "qutb minar", "qutab minar", "kutub minar", "कुतुब मीनार"]},
		{"type": "gateway_of_india", "name": "Gateway of India", "lat": 18.922, "lon": 72.8347, "radius_m": 2500.0,
			"wiki_title": "Gateway of India", "height_m": 26.0, "clear_m": 50.0, "yaw_deg": -75.0,
			"kind": "Monumental arch", "aliases": ["gateway of india", "गेटवे ऑफ इंडिया"]},
		{"type": "lotus_temple", "name": "Lotus Temple", "lat": 28.5535, "lon": 77.2588, "radius_m": 2500.0,
			"wiki_title": "Lotus Temple", "height_m": 34.3, "clear_m": 65.0,
			"kind": "Bahá'í temple", "aliases": ["lotus temple", "bahai temple", "kamal mandir", "लोटस टेम्पल"]},
		{"type": "hawa_mahal", "name": "Hawa Mahal", "lat": 26.9239, "lon": 75.8267, "radius_m": 2000.0,
			"wiki_title": "Hawa Mahal", "height_m": 15.0, "clear_m": 35.0, "yaw_deg": -90.0,
			"kind": "Palace", "aliases": ["hawa mahal", "palace of winds", "हवा महल"]},
		{"type": "golden_temple", "name": "Golden Temple (Harmandir Sahib)", "lat": 31.62, "lon": 74.8765, "radius_m": 2500.0,
			"wiki_title": "Golden Temple", "height_m": 20.0, "clear_m": 100.0,
			"kind": "Gurdwara", "aliases": ["harmandir sahib", "golden temple amritsar", "darbar sahib", "स्वर्ण मंदिर"]},
		{"type": "charminar", "name": "Charminar", "lat": 17.3616, "lon": 78.4747, "radius_m": 2000.0,
			"wiki_title": "Charminar", "height_m": 56.0, "clear_m": 40.0,
			"kind": "Mosque and gateway", "aliases": ["charminar", "చార్మినార్", "चारमीनार"]},
		{"type": "boudhanath", "name": "Boudhanath Stupa", "lat": 27.7215, "lon": 85.362, "radius_m": 2500.0,
			"wiki_title": "Boudhanath", "height_m": 36.0, "clear_m": 60.0,
			"kind": "Stupa", "aliases": ["boudhanath", "bouddhanath", "boudha stupa", "बौद्धनाथ"]},
		{"type": "angkor_wat", "icon": true, "name": "Angkor Wat", "lat": 13.41249, "lon": 103.86684, "radius_m": 4000.0,
			"wiki_title": "Angkor Wat", "height_m": 65.0, "clear_m": 90.0,
			# The precinct west of the temple to the gopura: avenue, libraries,
			# ponds and the Terrace of Honour stand in open lawn.
			"clear_rect_m": [-210.0, 0.0, 340.0, 105.0], "tree_clear_m": 25.0,
			"kind": "Temple", "aliases": ["angkor wat", "angkor vat", "អង្គរវត្ត"]},
		{"type": "petronas_towers", "name": "Petronas Towers", "lat": 3.15785, "lon": 101.71165, "radius_m": 4000.0,
			"wiki_title": "Petronas Towers", "height_m": 451.9, "clear_m": 110.0,
			"kind": "Skyscraper", "aliases": ["petronas twin towers", "petronas towers", "menara berkembar petronas", "menara petronas"]},
		{"type": "marina_bay_sands", "name": "Marina Bay Sands", "lat": 1.2834, "lon": 103.8607, "radius_m": 4000.0,
			"wiki_title": "Marina Bay Sands", "height_m": 207.0, "clear_m": 190.0, "yaw_deg": -75.0,
			"kind": "Resort", "aliases": ["marina bay sands"]},
		{"type": "wat_arun", "name": "Wat Arun", "lat": 13.7437, "lon": 100.4889, "radius_m": 2500.0,
			"wiki_title": "Wat Arun", "height_m": 70.0, "clear_m": 55.0,
			"kind": "Temple", "aliases": ["wat arun", "วัดอรุณ"]},
		{"type": "shwedagon", "name": "Shwedagon Pagoda", "lat": 16.7983, "lon": 96.1495, "radius_m": 3000.0,
			"wiki_title": "Shwedagon Pagoda", "height_m": 99.4, "clear_m": 85.0,
			"kind": "Pagoda", "aliases": ["shwedagon", "ရွှေတိဂုံ"]},
		{"type": "borobudur", "name": "Borobudur", "lat": -7.6079, "lon": 110.2038, "radius_m": 3000.0,
			"wiki_title": "Borobudur", "height_m": 35.0, "clear_m": 85.0,
			"kind": "Temple", "aliases": ["borobudur", "candi borobudur"]},
		{"type": "monas", "name": "National Monument (Monas)", "lat": -6.1754, "lon": 106.8272, "radius_m": 3000.0,
			"wiki_title": "National Monument (Indonesia)", "height_m": 132.0, "clear_m": 50.0,
			"kind": "Monument", "aliases": ["monas", "tugu monas", "monumen nasional"]},
	]
