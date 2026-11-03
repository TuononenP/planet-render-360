class_name LandmarkRegistrySwedenStockholm
extends RefCounted

## Registry entries for the sweden_stockholm landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetSwedenStockholm.

static func entries() -> Array:
	return [
		{"type": "royal_palace_stockholm", "name": "Stockholm Palace", "lat": 59.32680, "lon": 18.07169,
			"radius_m": 4000.0, "wiki_title": "Stockholm Palace", "height_m": 36.5, "clear_m": 110.0, "yaw_deg": -31.5,
			"kind": "Palace", "aliases": ["stockholm palace", "royal palace stockholm", "kungliga slottet",
				"stockholms slott"]},
		{"type": "storkyrkan", "name": "Storkyrkan", "lat": 59.32577, "lon": 18.07040,
			"radius_m": 4000.0, "wiki_title": "Storkyrkan", "height_m": 63.0, "clear_m": 45.0, "yaw_deg": -15.0,
			"kind": "Cathedral", "aliases": ["storkyrkan", "stockholm cathedral", "sankt nikolai kyrka",
				"stockholms domkyrka"]},
		{"type": "katarina_church", "name": "Katarina Church", "lat": 59.31706, "lon": 18.07813,
			"radius_m": 4000.0, "wiki_title": "Katarina Church", "height_m": 72.0, "clear_m": 40.0, "yaw_deg": -15.0,
			"kind": "Church", "aliases": ["katarina church", "katarina kyrka", "katarinakyrkan"]},
		{"type": "hedvig_eleonora_church", "name": "Hedvig Eleonora Church", "lat": 59.33522, "lon": 18.08056,
			"radius_m": 4000.0, "wiki_title": "Hedvig Eleonora Church", "height_m": 59.0, "clear_m": 35.0, "yaw_deg": 22.5,
			"kind": "Church", "aliases": ["hedvig eleonora church", "hedvig eleonora kyrka", "hedvig eleonora kyrkan"]},
		{"type": "ericsson_globe", "name": "Avicii Arena", "lat": 59.29361, "lon": 18.08321,
			"radius_m": 5500.0, "wiki_title": "Avicii Arena", "height_m": 85.0, "clear_m": 70.0,
			"kind": "Arena", "aliases": ["avicii arena", "ericsson globe", "globen", "stockholm globe arena"]},
		{"type": "kaknas_tower", "name": "Kaknäs Tower", "lat": 59.33504, "lon": 18.12675,
			"radius_m": 5500.0, "wiki_title": "Kaknäs Tower", "height_m": 170.0, "clear_m": 40.0,
			"kind": "Tower", "aliases": ["kaknas tower", "kaknästornet", "kaknäs tower"]},
		{"type": "vasa_museum", "name": "Vasa Museum", "lat": 59.32798, "lon": 18.09134,
			"radius_m": 4000.0, "wiki_title": "Vasa Museum", "height_m": 52.5, "clear_m": 75.0,
			"kind": "Museum", "aliases": ["vasa museum", "vasamuseet", "vasa museet"]},
		{"type": "nordic_museum", "name": "Nordic Museum", "lat": 59.32915, "lon": 18.09385,
			"radius_m": 4000.0, "wiki_title": "Nordic Museum", "height_m": 81.0, "clear_m": 85.0, "yaw_deg": -121.0,
			"kind": "Museum", "aliases": ["nordic museum", "nordiska museet", "nordiska museum stockholm"]},
		{"type": "stockholm_public_library", "name": "Stockholm Public Library", "lat": 59.34335, "lon": 18.05475,
			"radius_m": 4000.0, "wiki_title": "Stockholm Public Library", "height_m": 31.0, "clear_m": 55.0,
			"yaw_deg": -112.0, "kind": "Library", "aliases": ["stockholm public library", "stockholms stadsbibliotek",
				"stadsbiblioteket stockholm", "stockholm city library"]},
		{"type": "stockholm_concert_hall", "name": "Stockholm Concert Hall", "lat": 59.33509, "lon": 18.06315,
			"radius_m": 4000.0, "wiki_title": "Stockholm Concert Hall", "height_m": 22.2, "clear_m": 48.0,
			"yaw_deg": 63.0, "kind": "Concert hall", "aliases": ["stockholm concert hall", "konserthuset stockholm",
				"stockholms konserthus"]},
		{"type": "riksdag_building", "name": "Riksdag Building", "lat": 59.32755, "lon": 18.06787,
			"radius_m": 4000.0, "wiki_title": "Riksdag building", "height_m": 35.0, "clear_m": 70.0,
			"yaw_deg": -117.5, "kind": "Parliament", "aliases": ["riksdag building", "riksdagshuset", "swedish parliament building"]},
	]
