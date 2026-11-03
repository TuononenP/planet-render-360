class_name LandmarkRegistryIndiaHistoric
extends RefCounted

## Registry entries for the india_historic landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetIndiaHistoric.

static func entries() -> Array:
	return [
		{"type": "red_fort_delhi", "name": "Red Fort", "lat": 28.6558, "lon": 77.2410, "radius_m": 5000.0,
			"wiki_title": "Red Fort", "height_m": 33.0, "clear_m": 330.0, "yaw_deg": 3.5,
			"kind": "Fort", "aliases": ["red fort", "lal qila", "lal qilah", "लाल किला"]},
		{"type": "humayuns_tomb", "name": "Humayun's Tomb", "lat": 28.5933, "lon": 77.2507, "radius_m": 6000.0,
			"wiki_title": "Humayun's Tomb", "height_m": 47.0, "clear_m": 190.0,
			"kind": "Mausoleum", "aliases": ["humayun's tomb", "humayuns tomb", "humayun tomb", "maqbara-i humayun",
				"हुमायूँ का मकबरा"]},
		{"type": "jama_masjid_delhi", "name": "Jama Masjid, Delhi", "lat": 28.6507, "lon": 77.2335, "radius_m": 4500.0,
			"wiki_title": "Jama Masjid, Delhi", "height_m": 51.0, "clear_m": 100.0, "yaw_deg": -4.0,
			"kind": "Mosque", "aliases": ["jama masjid, delhi", "jama masjid delhi", "jama masjid, old delhi",
				"jami masjid delhi", "masjid-i jahan-numa", "जामा मस्जिद"]},
		{"type": "konark_sun_temple", "name": "Konark Sun Temple", "lat": 19.8876, "lon": 86.0945, "radius_m": 3000.0,
			"wiki_title": "Konark Sun Temple", "height_m": 30.0, "clear_m": 75.0,
			"kind": "Temple", "aliases": ["konark sun temple", "konark temple", "konarak sun temple",
				"sun temple konark", "black pagoda konark", "कोणार्क सूर्य मंदिर"]},
		{"type": "brihadisvara_temple", "name": "Brihadisvara Temple", "lat": 10.7826, "lon": 79.1314, "radius_m": 4000.0,
			"wiki_title": "Brihadisvara Temple, Thanjavur", "height_m": 66.0, "clear_m": 235.0, "yaw_deg": -20.0,
			"kind": "Temple", "aliases": ["brihadisvara temple", "brihadeeswarar temple", "brihadeshwara temple",
				"peruvudaiyar kovil", "thanjavur big temple", "big temple thanjavur", "rajarajeswaram",
				"பிரகதீஸ்வரர் கோயில்", "बृहदीश्वर मंदिर"]},
		{"type": "meenakshi_temple", "name": "Meenakshi Amman Temple", "lat": 9.9195, "lon": 78.1193, "radius_m": 4000.0,
			"wiki_title": "Meenakshi Temple", "height_m": 52.0, "clear_m": 180.0,
			"kind": "Temple", "aliases": ["meenakshi amman temple", "meenakshi temple", "meenakshi sundareswarar",
				"madurai meenakshi", "மீனாட்சி அம்மன் கோவில்", "मीनाक्षी मंदिर"]},
		{"type": "khajuraho_kandariya_mahadeva", "name": "Kandariya Mahadeva Temple", "lat": 24.8530, "lon": 79.9196,
			"radius_m": 3000.0, "wiki_title": "Kandariya Mahadeva Temple", "height_m": 31.0, "clear_m": 45.0,
			"yaw_deg": 12.0, "kind": "Temple", "aliases": ["kandariya mahadeva temple", "kandariya mahadev",
				"kandariya mahadeo", "khajuraho kandariya", "कंदरिया महादेव मंदिर"]},
		{"type": "mysore_palace", "name": "Mysore Palace", "lat": 12.3052, "lon": 76.6550, "radius_m": 4000.0,
			"wiki_title": "Mysore Palace", "height_m": 44.0, "clear_m": 150.0, "yaw_deg": -86.0,
			"kind": "Palace", "aliases": ["mysore palace", "mysuru palace", "amba vilas palace", "amba vilas",
				"ಮೈಸೂರು ಅರಮನೆ", "मैसूर पैलेस"]},
		{"type": "victoria_memorial_kolkata", "name": "Victoria Memorial, Kolkata", "lat": 22.5449, "lon": 88.3425,
			"radius_m": 3500.0, "wiki_title": "Victoria Memorial, Kolkata", "height_m": 56.0, "clear_m": 85.0,
			"yaw_deg": 10.0, "kind": "Memorial", "aliases": ["victoria memorial, kolkata", "victoria memorial kolkata",
				"victoria memorial hall", "victoria memorial calcutta", "ভিক্টোরিয়া মেমোরিয়াল"]},
		{"type": "amber_fort", "name": "Amber Fort", "lat": 26.9855, "lon": 75.8513, "radius_m": 4000.0,
			"wiki_title": "Amer Fort", "height_m": 36.0, "clear_m": 95.0, "yaw_deg": -26.0,
			"kind": "Fort", "aliases": ["amber fort", "amer fort", "amber palace", "amer palace", "आमेर किला",
				"आमेर का किला"]},
	]
