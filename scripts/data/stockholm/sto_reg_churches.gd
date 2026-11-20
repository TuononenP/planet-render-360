extends RefCounted

## Stockholm churches rebuilt from photos (plan S-1): Klara, Sofia and
## Tyska kyrkan. Built by sweden_stockholm/churches/sto_set_churches.gd.

static func entries() -> Array:
	return [
		{"type": "klara_church", "skyline_priority": 1, "name": "Klara Church", "lat": 59.33120, "lon": 18.06157,
			"radius_m": 4000.0, "wiki_title": "Klara Church", "height_m": 116.0, "clear_m": 35.0,
			"yaw_deg": 8.7, "kind": "Church", "aliases": ["klara church", "klara kyrka", "sankta clara kyrka"]},
		{"type": "sofia_church_stockholm", "skyline_priority": 1, "name": "Sofia Church", "lat": 59.31230, "lon": 18.08834,
			"radius_m": 4000.0, "wiki_title": "Sofia Church", "height_m": 78.0, "clear_m": 30.0,
			"yaw_deg": -14.3, "kind": "Church", "aliases": ["sofia church", "sofia kyrka", "sofia church stockholm", "sofia kyrka stockholm"]},
		{"type": "tyska_kyrkan", "skyline_priority": 1, "name": "German Church", "lat": 59.32417, "lon": 18.07167,
			"radius_m": 4000.0, "wiki_title": "German Church, Stockholm", "height_m": 96.0, "clear_m": 30.0, "yaw_deg": -43.0,
			"kind": "Church", "aliases": ["tyska kyrkan", "german church", "german church stockholm", "sankta gertruds kyrka"]},
	]
