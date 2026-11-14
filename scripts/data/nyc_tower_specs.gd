class_name NycTowerSpecs
extends RefCounted

## New York's (and Jersey City's) skyline towers as TowerSpec rows, one area
## per class. Each row is a registry entry with `skyline: true`, so
## LandmarkSites gives it a skyline slot (not an icon's), plus its spec.
## Positions and yaw_deg are the centroid and long axis of the building's
## OSM outline in the bundled snapshots; the massing ops follow its mapped
## parts. height_m is the model's top (Wikidata P2048 unless noted). clear_m
## stops short of the nearest other tall building (nyc_skyscraper_sites_test).

static var _rows: Array = []
static var _by_type: Dictionary = {}

## A registry row with its spec. A tower is seen from radius_m: farther for
## a taller one.
static func row(type: String, name: String, lat: float, lon: float, height: float, yaw: float, clear: float,
		wiki: String, priority: int, aliases: Array, spec: Dictionary) -> Dictionary:
	return {"type": type, "name": name, "lat": lat, "lon": lon, "radius_m": clampf(height * 22.0, 3000.0, 8000.0),
		"wiki_title": wiki, "height_m": height, "clear_m": clear, "yaw_deg": yaw, "kind": "Skyscraper",
		"skyline": true, "skyline_priority": priority, "aliases": aliases, "tower_spec": spec}

static func entries() -> Array:
	if _rows.is_empty():
		var all: Array = []
		for batch in [NycTowerSpecsDowntown.entries(), NycTowerSpecsMidtown.entries(), NycTowerSpecsWest.entries(),
				NycTowerSpecsJersey.entries(), NycTowerSpecsOuter.entries()]:
			all.append_array(batch)
		for e in all:
			_by_type[str(e["type"])] = e
		_rows = all
	return _rows

## The spec of `type`, or {} for a type that is not a spec tower.
static func spec_for(type: String) -> Dictionary:
	entries()
	return (_by_type.get(type, {}) as Dictionary).get("tower_spec", {})
