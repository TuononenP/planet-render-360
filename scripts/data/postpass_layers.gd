class_name PostpassLayers
extends RefCounted

## Postpass bodies for the wider layers that Overpass used to serve alone:
## the low-detail ring (OsmQuery.build_ring_query), the far city
## (FarCityFetcher.build_query) and the horizon names
## (HorizonFetcher.build_query). Each selects what its Overpass query does,
## nearest first under the same caps, and PostpassFallback.to_overpass_json
## turns the answer into the Overpass JSON their parsers read.

## A height in metres from the `height` tag: its leading number, in feet
## when the value ends in ft or ' (Overpass: number(t["height"])*0.3048).
const HEIGHT_M := ("(CASE WHEN tags->>'height' ~* '(ft|'')[[:space:]]*$' THEN 0.3048 ELSE 1 END"
	+ " * substring(tags->>'height' from '^[[:space:]]*([0-9]+(\\.[0-9]+)?)')::float)")
const LEVELS := "substring(tags->>'building:levels' from '^[[:space:]]*([0-9]+)')::float"

static func _body(parts: PackedStringArray) -> String:
	return "data=" + " UNION ALL ".join(parts).uri_encode()

## Major roads, waterways and coastline out to ring_m.
static func build_ring_body(lat: float, lon: float, ring_m: int) -> String:
	var near := PostpassFallback._near(lat, lon, ring_m) + " AND osm_type = 'W' AND "
	return _body([
		PostpassFallback._part(near + "tags->>'highway' IN ('motorway','trunk','primary','secondary','tertiary')",
			lat, lon, OsmQuery.CAP_RING_HIGHWAYS),
		PostpassFallback._part(near + "tags ? 'waterway'", lat, lon, OsmQuery.CAP_RING_WATERWAYS),
		PostpassFallback._part(near + "tags->>'natural' = 'coastline'", lat, lon, OsmQuery.CAP_RING_COASTLINE),
	])

## Whether a building or part counts as tall (FarCityFetcher.TOWER_MIN_M,
## TOWER_MIN_LEVELS).
static func _tall() -> String:
	return "(%s >= %d OR %s >= %d)" % [HEIGHT_M, FarCityFetcher.TOWER_MIN_M,
		LEVELS, FarCityFetcher.TOWER_MIN_LEVELS]

## Built-up landuse, the tall buildings and parts, and the building parts,
## to radius_m. Overpass keeps only the parts within PARTS_REACH_M of a tall
## one; that test made Postpass run past a minute (2026-11-16, Helsinki), so
## every part comes, nearest first, and FarCityFetcher._nest_parts keeps the
## ones it can place (about 3 MB more in Helsinki).
static func build_far_body(lat: float, lon: float, radius_m: int = FarCityFetcher.RADIUS_M) -> String:
	var near := PostpassFallback._near(lat, lon, radius_m)
	var landuse := " AND tags->>'landuse' IN ('residential','commercial','industrial','retail')"
	var building := " AND osm_type <> 'N' AND tags ?| ARRAY['building','building:part']" \
		+ " AND tags->>'building' IS DISTINCT FROM 'construction'"
	return _body([
		PostpassFallback._part(near + " AND osm_type = 'W'" + landuse, lat, lon, FarCityFetcher.CAP_LANDUSE),
		PostpassFallback._part(near + " AND osm_type = 'R'" + landuse, lat, lon, FarCityFetcher.CAP_RELATIONS),
		PostpassFallback._part(near + building + " AND " + _tall(), lat, lon,
			FarCityFetcher.CAP_TOWER_CANDIDATES),
		PostpassFallback._part(near + " AND osm_type <> 'N' AND tags ? 'building:part'", lat, lon,
			FarCityFetcher.CAP_NEAR_PARTS + FarCityFetcher.CAP_TOWER_PARTS),
	])

## Named peaks, towns and lakes, each at one point (Overpass `out center`),
## nearest first; the three groups share HorizonFetcher.CAP.
static func build_horizon_body(lat: float, lon: float) -> String:
	var at := "(SELECT 'N' AS osm_type, osm_id, tags, ST_PointOnSurface(geom) AS geom" \
		+ " FROM postpass_pointlinepolygon WHERE %s AND tags ? 'name' AND %s ORDER BY geom <-> %s LIMIT %d)"
	var point := PostpassFallback._point(lat, lon)
	var cap := floori(HorizonFetcher.CAP / 3.0)
	return _body([
		at % [PostpassFallback._near(lat, lon, HorizonFetcher.RADIUS_PEAK_M),
			"osm_type = 'N' AND tags->>'natural' = 'peak'", point, cap],
		at % [PostpassFallback._near(lat, lon, HorizonFetcher.RADIUS_TOWN_M),
			"osm_type = 'N' AND tags->>'place' IN ('city','town','village')", point, cap],
		at % [PostpassFallback._near(lat, lon, HorizonFetcher.RADIUS_LAKE_M),
			"tags->>'natural' = 'water' AND tags->>'water' IN ('lake','reservoir')", point, cap],
	])
