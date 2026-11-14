class_name LandmarkRegistryCentralPark
extends RefCounted

## Central Park's built landmarks, in the format of LocationData.landmarks().
## Positions are the OSM features' centroids (the bridges' deck midpoints,
## Bethesda Fountain's pool) in the 2026-11-14 Central Park snapshot;
## Cleopatra's Needle, a node the detailed query does not fetch, is at its
## published position and keeps its paved clearing on Greywacke Knoll free
## of trees (tree_clear_m). A bridge's yaw_deg is its deck bearing - 90 and
## span_m its mapped deck, which the model replaces. Bow Bridge stands on
## its west deck end (base_at_m) with its model's origin at deck level: the
## DEM's banks round the Lake are higher than its water, so a water base
## would bury it. skyline_priority 3 keeps them ahead of the skyline's
## towers in the icon budget.

static func _row(type: String, name: String, lat: float, lon: float, height: float, clear: float, kind: String,
		wiki: String, aliases: Array, extra: Dictionary = {}) -> Dictionary:
	var row := {"type": type, "name": name, "lat": lat, "lon": lon, "radius_m": 2500.0, "wiki_title": wiki,
		"height_m": height, "clear_m": clear, "kind": kind, "skyline_priority": 3, "aliases": aliases}
	row.merge(extra)
	return row

static func entries() -> Array:
	return [
		_row("bethesda_fountain", "Bethesda Fountain", 40.7743152, -73.9708251, 7.9, 6.0, "Fountain",
			"Bethesda Terrace and Fountain", ["bethesda fountain", "bethesda terrace", "angel of the waters", "central park"]),
		_row("bow_bridge", "Bow Bridge", 40.7757594, -73.9717707, 4.7, 6.0, "Bridge", "Bow Bridge",
			["bow bridge"], {"yaw_deg": 58.6, "span_m": 44.3, "base_at_m": [-20.0, 0.0]}),
		_row("gapstow_bridge", "Gapstow Bridge", 40.7669277, -73.9738305, 5.7, 6.0, "Bridge", "Gapstow Bridge",
			["gapstow bridge"], {"yaw_deg": -26.9, "span_m": 22.4, "base": "water"}),
		_row("belvedere_castle", "Belvedere Castle", 40.779303, -73.9688745, 18.5, 13.0, "Castle",
			"Belvedere Castle", ["belvedere castle"], {"yaw_deg": 59.0}),
		_row("cleopatras_needle", "Cleopatra's Needle", 40.77972, -73.96528, 24.7, 6.0, "Obelisk",
			"Cleopatra's Needle (New York City)", ["cleopatra's needle", "cleopatras needle"],
			{"tree_clear_m": 18.0}),
	]
