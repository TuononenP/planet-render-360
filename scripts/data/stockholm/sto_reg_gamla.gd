extends RefCounted

## Stockholm Tier A landmarks round Gamla stan, Slussen and Skeppsholmen (plan S-3).
## Built by sweden_stockholm/gamla/sto_set_gamla.gd. Low buildings: none of
## these carries `skyline_priority` (they are chosen nearest-first).

static func entries() -> Array:
	return [
		# Guldbron (OSM relation 15753921) with Stadsmuseet 200 m west of it
		# (clear_offsets_m); y = 0 at the water, the bridge's +X along bearing 25.7.
		{"type": "slussen_guldbron", "name": "Slussen and the Guldbron", "lat": 59.320992, "lon": 18.073648,
			"radius_m": 3000.0, "wiki_title": "Slussen", "height_m": 17.9, "clear_m": 26.0,
			"yaw_deg": -64.3, "span_m": 141.0, "base": "water", "kind": "Bridge",
			"clear_offsets_m": [[-192.5, -67.5]],
			"aliases": ["slussen", "guldbron", "slussen guldbron", "slussbron", "stadsmuseet", "stockholm city museum"]},
		# The square plus the west row (nos. 18-22 and their neighbours) and
		# Börshuset; the model replaces exactly those mapped buildings
		# (model_rects_m cover their centres), neighbours stay.
		{"type": "stortorget_stockholm", "name": "Stortorget", "lat": 59.325020, "lon": 18.070806,
			"radius_m": 3000.0, "wiki_title": "Stortorget", "height_m": 29.0, "clear_m": 3.0,
			"yaw_deg": -18.1, "kind": "Square", "base_at_m": [0.0, 0.0],
			"model_rects_m": [
				[-39.9, 15.35, 12.8, 4.65], [-33.7, 5.45, 6.7, 4.65], [-32.25, -2.1, 5.25, 3.7],
				[-42.85, -10.85, 15.65, 4.35], [-43.6, -18.1, 16.1, 4.8], [-44.35, -26.6, 16.55, 6.0],
				[5.25, -34.45, 27.55, 18.25]],
			"aliases": ["stortorget", "stortorget stockholm", "stortorget gamla stan", "borshuset", "börshuset",
				"stockholm stock exchange building", "stortorgsbrunnen"]},
		# The seven merchant houses Thuenska to Hobelinska; the houses between
		# Brandenburgska and Pauliska stay mapped.
		{"type": "skeppsbron_stockholm", "name": "Skeppsbron", "lat": 59.324041, "lon": 18.074956,
			"radius_m": 3000.0, "wiki_title": "Skeppsbron", "height_m": 24.5, "clear_m": 3.0,
			"yaw_deg": -79.6, "kind": "Quay row", "base_at_m": [0.0, 20.0],
			"model_rects_m": [
				[-63.85, -1.1, 7.25, 13.65], [-50.9, -2.6, 9.4, 15.2], [-31.35, -0.95, 8.35, 13.85],
				[-16.75, -3.0, 6.65, 15.9], [28.9, 1.75, 9.1, 10.85], [52.6, 2.9, 9.0, 10.1],
				[72.2, -0.6, 8.1, 13.4]],
			"aliases": ["skeppsbron", "skeppsbron stockholm", "skeppsbron quay", "skeppsbron merchant houses",
				"brandenburgska huset"]},
	]
