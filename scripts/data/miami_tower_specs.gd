class_name MiamiTowerSpecs
extends RefCounted

## Greater Miami's skyline towers as TowerSpec rows, one area per class.
## Each row is a registry entry with `skyline: true`, so LandmarkSites gives
## it a skyline slot (not an icon's), plus its spec. Positions and yaw_deg are
## the centroid and long axis of the building's OSM outline; massing ops follow
## mapped parts and published architectural heights (docs/miami-landmark-sources.md).

static var _rows: Array = []
static var _by_type: Dictionary = {}

static func row(type: String, name: String, lat: float, lon: float, height: float, yaw: float, clear: float,
		wiki: String, priority: int, aliases: Array, spec: Dictionary) -> Dictionary:
	var all_aliases: Array = aliases.duplicate()
	var own := name.to_lower()
	if not all_aliases.has(own):
		all_aliases.append(own)
	return {
		"type": type, "name": name, "lat": lat, "lon": lon,
		"radius_m": clampf(height * 22.0, 3000.0, 8000.0),
		"wiki_title": wiki, "height_m": height, "clear_m": clear, "yaw_deg": yaw,
		"kind": "Skyscraper", "skyline": true, "secondary": true,
		"skyline_priority": priority, "aliases": all_aliases, "tower_spec": spec,
	}

static func entries() -> Array:
	if _rows.is_empty():
		var all: Array = []
		for batch in [
			MiamiTowerSpecsDowntown.entries(),
			MiamiTowerSpecsEdgewater.entries(),
			MiamiTowerSpecsBrickell.entries(),
			MiamiTowerSpecsBeach.entries(),
			MiamiTowerSpecsFar.entries(),
		]:
			all.append_array(batch)
		for e in all:
			_by_type[str(e["type"])] = e
		_rows = all
	return _rows

## The spec of `type`, or {} for a type that is not a Miami spec tower.
static func spec_for(type: String) -> Dictionary:
	entries()
	return (_by_type.get(type, {}) as Dictionary).get("tower_spec", {})
