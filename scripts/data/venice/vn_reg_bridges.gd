class_name VnRegBridges
extends RefCounted

## Bespoke Grand Canal bridges (`VN-7`: Ponte dell'Accademia, Ponte degli Scalzi,
## and Ponte della Costituzione / Calatrava). Rialto Bridge stays in
## LandmarkRegistryBridges under its existing type ID `rialto_bridge`.

static func entries() -> Array:
	return [
		{"type": "ponte_accademia", "name": "Ponte dell'Accademia",
			"lat": 45.43168, "lon": 12.32894, "radius_m": 3200.0,
			"wiki_title": "Ponte dell'Accademia", "height_m": 7.6, "yaw_deg": -60.9,
			"span_m": 56.0, "base": "sea", "skyline_priority": 7, "clear_m": 14.0,
			"kind": "Bridge",
			"aliases": ["ponte dell'accademia", "ponte dell accademia", "accademia bridge"]},
		{"type": "ponte_scalzi", "name": "Ponte degli Scalzi",
			"lat": 45.44116, "lon": 12.32272, "radius_m": 3200.0,
			"wiki_title": "Ponte degli Scalzi", "height_m": 8.8, "yaw_deg": 59.0,
			"span_m": 52.0, "base": "sea", "skyline_priority": 3, "clear_m": 16.0,
			"kind": "Bridge",
			"aliases": ["ponte degli scalzi", "scalzi bridge"]},
		{"type": "ponte_costituzione", "name": "Ponte della Costituzione (Calatrava Bridge)",
			"lat": 45.43902, "lon": 12.31964, "radius_m": 3200.0,
			"wiki_title": "Ponte della Costituzione", "height_m": 10.2, "yaw_deg": -52.3,
			"span_m": 81.0, "base": "sea", "skyline_priority": 3, "clear_m": 18.0,
			"kind": "Bridge",
			"aliases": ["ponte della costituzione", "calatrava bridge venice", "constitution bridge venice"]},
		{"type": "ponte_paglia", "name": "Ponte della Paglia",
			"lat": 45.43363, "lon": 12.34086, "radius_m": 2600.0,
			"wiki_title": "Ponte della Paglia", "height_m": 5.4, "yaw_deg": -14.0,
			"span_m": 16.0, "base": "sea", "skyline_priority": 3, "clear_m": 8.0,
			"kind": "Bridge",
			"aliases": ["ponte della paglia", "straw bridge venice"]},
		{"type": "ponte_guglie", "name": "Ponte delle Guglie",
			"lat": 45.44415, "lon": 12.32482, "radius_m": 3200.0,
			"wiki_title": "Ponte delle Guglie", "height_m": 7.6, "yaw_deg": 58.0,
			"span_m": 24.0, "base": "sea", "skyline_priority": 0, "clear_m": 10.0,
			"kind": "Bridge",
			"aliases": ["ponte delle guglie", "bridge of spires venice"]},
		{"type": "ponte_tre_archi", "name": "Ponte dei Tre Archi",
			"lat": 45.44606, "lon": 12.32042, "radius_m": 3400.0,
			"wiki_title": "Ponte dei Tre Archi", "height_m": 6.4, "yaw_deg": 56.0,
			"span_m": 30.0, "base": "sea", "skyline_priority": 0, "clear_m": 12.0,
			"kind": "Bridge",
			"aliases": ["ponte dei tre archi", "ponte di san giobbe"]},
	]
