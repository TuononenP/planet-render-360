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
## Overpass prints in id order, not by distance, so in a dense city
## (Shibuya: ~3× the cap within 1200 m) one capped statement thins the
## whole disc evenly, the blocks around the viewer included, and the
## gaps render as lawn. The core disc is therefore fetched first with
## its own cap, complete, and the ring beyond it fills the rest.
const CORE_RADIUS_M := 500
const CAP_BUILDINGS_CORE := 4500
const CAP_PARTS := 2200
const CAP_HIGHWAYS := 13000
const CAP_WATERWAYS := 880
const CAP_NATURAL := 1600
const CAP_LANDUSE := 1600
const CAP_LEISURE := 700
const CAP_BARRIERS := 1600
const CAP_TREE_NODES := 8000
## Street furniture nodes (benches, bins, bollards, signals, bus stops)
## near the viewpoint only: desktop Ultra dresses the streets it shows up
## close (StreetFurniture.RADIUS_M).
const CAP_FURNITURE := 4000
const FURNITURE_RADIUS_M := 450
## Railway track ways (a city terminus yard is ~400 within 1200 m) and
## squares mapped outside the highway statement (place=square,
## area:highway, multipolygon squares).
const CAP_RAILWAYS := 2500
const CAP_SQUARES := 400
## Marks a response as this query's (an Overpass `make` element): a
## cached detailed payload without it predates the current statements
## (q3 railways and squares, q4 street furniture), so it is refetched
## (and still served if the network fails).
const QUERY_MARK := "pr360_q4"
## Multipolygon relations per land/water key (T2.4): areas are rarely
## relations (measured: 8 MPs in a Big Sur coastal response), so one
## shared cap bounds the byte-heavy tail while covering dense cities.
const CAP_RELATIONS := 220
## Building multipolygon relations (courtyard blocks mapped as an outer
## ring with inner-ring holes — common in central Paris). Own cap so
## they never compete with the land/water relation budget. Not 900:
## "out geom 900" is the retired v1 cap the query tests guard against.
const CAP_BUILDING_RELATIONS := 1000
## Parts within LANDMARK_PARTS_M of a landmark-type building (churches,
## mosques, temples, castles, towers): the general CAP_PARTS prints in id
## order and thins a dense city's parts evenly, so a cathedral could lose
## its dome. Own statement in the same request (no extra Overpass call);
## parse dedups the overlap. 80 m: `around.set` measures to the outline,
## and a central dome sits that far in from a big cathedral's walls.
const CAP_LANDMARK_PARTS := 800
const LANDMARK_PARTS_M := 80
const LANDMARK_KINDS := "cathedral|church|chapel|mosque|temple|synagogue|castle|tower"
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
	var core := mini(CORE_RADIUS_M, radius_m / 2)
	var clauses: Array[String] = [
		# The mark prints first, so a payload the timeout cut short still
		# reads as this query's (it is cached either way).
		"make %s;out;" % QUERY_MARK,
		'way["building"](around:%d,%.6f,%.6f);out geom %d;'
			% [core, lat, lon, CAP_BUILDINGS_CORE],
		'(way["building"](around:%d,%.6f,%.6f); - way["building"](around:%d,%.6f,%.6f););out geom %d;'
			% [radius_m, lat, lon, core, lat, lon, CAP_BUILDINGS],
		'relation["building"]["type"="multipolygon"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_BUILDING_RELATIONS],
		'way["building:part"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_PARTS],
		('(way["building"~"^(%s)$"](around:%d,%.6f,%.6f);'
			+ 'relation["building"~"^(%s)$"]["type"="multipolygon"](around:%d,%.6f,%.6f);)->.lm;'
			+ '(way["building:part"](around.lm:%d);'
			+ 'relation["building:part"]["type"="multipolygon"](around.lm:%d););out geom %d;')
			% [LANDMARK_KINDS, radius_m, lat, lon, LANDMARK_KINDS, radius_m, lat, lon,
				LANDMARK_PARTS_M, LANDMARK_PARTS_M, CAP_LANDMARK_PARTS],
		'way["highway"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_HIGHWAYS],
		# Track and squares straight after the streets: a dense city can hit
		# the server timeout, which drops the statements printed last.
		('way["railway"~"^(%s)$"](around:%d,%.6f,%.6f);out geom %d;')
			% ["|".join(PackedStringArray(OsmTags.RAIL_CLASSES)), radius_m, lat, lon, CAP_RAILWAYS],
		('(way["area:highway"="pedestrian"](around:%d,%.6f,%.6f);'
			+ 'way["place"="square"](around:%d,%.6f,%.6f);'
			+ 'relation["highway"]["type"="multipolygon"](around:%d,%.6f,%.6f);'
			+ 'relation["place"="square"]["type"="multipolygon"](around:%d,%.6f,%.6f););out geom %d;')
			% [radius_m, lat, lon, radius_m, lat, lon, radius_m, lat, lon,
				radius_m, lat, lon, CAP_SQUARES],
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
		'node["natural"="tree"](around:%d,%.6f,%.6f);out %d;'
			% [radius_m, lat, lon, CAP_TREE_NODES],
		'node["man_made"~"^(tower|lighthouse|windmill)$"](around:%d,%.6f,%.6f);out 100;'
			% [radius_m, lat, lon],
		# The country the viewpoint stands in (ISO 3166-1 alpha-2), so the
		# building style follows the real border, not a lat/lon box.
		'is_in(%.6f,%.6f)->.ci;area.ci["admin_level"="2"]["ISO3166-1"];out tags 4;'
			% [lat, lon],
		# Street furniture last: a timeout drops it before anything else.
		('(node["amenity"~"^(bench|waste_basket)$"](around:%d,%.6f,%.6f);'
			+ 'node["highway"~"^(traffic_signals|bus_stop)$"](around:%d,%.6f,%.6f);'
			+ 'node["barrier"="bollard"](around:%d,%.6f,%.6f););out %d;')
			% [FURNITURE_RADIUS_M, lat, lon, FURNITURE_RADIUS_M, lat, lon,
				FURNITURE_RADIUS_M, lat, lon, CAP_FURNITURE],
	]
	return head + "".join(PackedStringArray(clauses))

## Whether a cached detailed payload came from the current query.
static func is_current(text: String) -> bool:
	return text.contains(QUERY_MARK)

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

