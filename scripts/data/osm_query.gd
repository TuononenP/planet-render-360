class_name OsmQuery
extends RefCounted


## Server-side statement timeout, pinned by the register's Overpass
## rate discipline (docs/data-source-register.md): keep [timeout:30].
const OVERPASS_TIMEOUT_S := 30
## Overpass `out` verbosity limits per detailed-query layer (contract
## §7 V12: the single `out geom 900` cap is replaced by tiered
## per-layer caps). Values cover Paris-centre at 800 m with margin
## (measured live T2.3: 2613 buildings, 5256 highways, 819 parts,
## 588 barriers, 2748 trees, 211 landuse, 103 natural ways, 103 leisure;
## highways are node-sparse — median 3 nodes/way — so the full set
## costs only ≈1.2 MB over the truncated one) while keeping the
## response ≈9 MB / <60 s per phase.
## T7.0: scaled ×2.25 with the 800 → 1200 m radius (area ratio).
const CAP_BUILDINGS := 7000
const CAP_PARTS := 2200
const CAP_HIGHWAYS := 13000
const CAP_WATERWAYS := 880
const CAP_NATURAL := 1600
const CAP_LANDUSE := 1600
const CAP_LEISURE := 700
const CAP_BARRIERS := 1600
const CAP_TREE_NODES := 8000
## Railway track + platform ways, and station / subway-entrance nodes.
## A dense rail hub (a terminus throat, a yard) is a few hundred ways;
## Midtown Manhattan carries ≈250 subway entrances within 1200 m.
const CAP_RAIL := 2500
const CAP_RAIL_NODES := 800
## Multipolygon relations per land/water key (T2.4): areas are rarely
## relations (measured: 8 MPs in a Big Sur coastal response), so one
## shared cap bounds the byte-heavy tail while covering dense cities.
const CAP_RELATIONS := 220
## Building multipolygon relations (courtyard blocks mapped as an outer
## ring with inner-ring holes — common in central Paris). Own cap so
## they never compete with the land/water relation budget. Not 900:
## "out geom 900" is the retired v1 cap the query tests guard against.
const CAP_BUILDING_RELATIONS := 1000
## Ring (low-detail majors) caps: small payload by construction; the
## 1600 m Paris ring carries ≈630 elements (≈590 highways) in ≈0.8 MB.
const CAP_RING_HIGHWAYS := 800
const CAP_RING_WATERWAYS := 150
const CAP_RING_COASTLINE := 100
## Overpass query construction for OsmFetcher: the tiered detailed
## query and the low-detail ring query, plus their `out` caps.
## Pure string building — no HTTP, no parsing.
## Detailed area query: one request, one tiered statement per layer,
## each with its own `out` cap (contract §7 V12). `out geom` already
## returns every tag (register), so richer tags ride free — the query
## only adds key selectors (building:part, waterway, barrier, leisure,
## tree nodes, multipolygon relations). Land/water layers add a
## relation statement each (T2.4) filtered to type=multipolygon, so
## polygons with holes arrive with member geometry while boundary /
## route relations stay server-side (measured: an unfiltered coastal
## query dragged two 300–700-member nature-reserve boundaries, 2.8 MB
## total, that parse skips — pure payload waste). Same element may
## print twice across statements; parse_features dedups by (type, id).
## radius_m defaults to OsmFetcher.DETAILED_RADIUS_M (1200).
static func build_query(lat: float, lon: float, radius_m: int = 1200) -> String:
	var head := "[out:json][timeout:%d];" % OVERPASS_TIMEOUT_S
	var clauses: Array[String] = [
		'way["building"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_BUILDINGS],
		'relation["building"]["type"="multipolygon"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_BUILDING_RELATIONS],
		'way["building:part"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_PARTS],
		'way["highway"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_HIGHWAYS],
		'way["waterway"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_WATERWAYS],
		'relation["waterway"]["type"="multipolygon"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_RELATIONS],
		'way["natural"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_NATURAL],
		'relation["natural"]["type"="multipolygon"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_RELATIONS],
		'way["landuse"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_LANDUSE],
		'relation["landuse"]["type"="multipolygon"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_RELATIONS],
		'way["leisure"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_LEISURE],
		'relation["leisure"]["type"="multipolygon"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_RELATIONS],
		'way["barrier"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_BARRIERS],
		'way["man_made"~"^(tower|lighthouse|windmill)$"](around:%d,%.6f,%.6f);out geom 100;'
			% [radius_m, lat, lon],
		'way["railway"~"^(rail|subway|light_rail|tram|narrow_gauge|monorail|funicular|preserved|platform)$"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_RAIL],
		'node["railway"~"^(station|halt|subway_entrance|train_station_entrance|tram_stop)$"](around:%d,%.6f,%.6f);out %d;'
			% [radius_m, lat, lon, CAP_RAIL_NODES],
		'node["natural"="tree"](around:%d,%.6f,%.6f);out %d;'
			% [radius_m, lat, lon, CAP_TREE_NODES],
		'node["man_made"~"^(tower|lighthouse|windmill)$"](around:%d,%.6f,%.6f);out 100;'
			% [radius_m, lat, lon],
	]
	return head + "".join(PackedStringArray(clauses))

## Second, low-detail ring query (plan §3.1 Ultra budget): major roads
## + waterways + coastline out to ring_m. Best-effort — merged over the
## detailed response when it succeeds, skipped when it does not.
static func build_ring_query(lat: float, lon: float, ring_m: int) -> String:
	var head := "[out:json][timeout:%d];" % OVERPASS_TIMEOUT_S
	return head \
		+ 'way["highway"~"^(motorway|trunk|primary|secondary|tertiary)$"](around:%d,%.6f,%.6f);out geom %d;' \
			% [ring_m, lat, lon, CAP_RING_HIGHWAYS] \
		+ 'way["waterway"](around:%d,%.6f,%.6f);out geom %d;' \
			% [ring_m, lat, lon, CAP_RING_WATERWAYS] \
		+ 'way["natural"="coastline"](around:%d,%.6f,%.6f);out geom %d;' \
			% [ring_m, lat, lon, CAP_RING_COASTLINE]

