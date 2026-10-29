class_name OsmFetcher
extends Node

## Real buildings + roads + water + trees from OpenStreetMap via Overpass.
## Free, no key, direct from device; responses cached in user://cache.
## v2 (T2.3): tiered per-layer queries (800 m detailed + a preset-scaled
## low-detail ring), full footprint polygons, and rich tags normalised
## into the LocationData §2.4–§2.6 shapes — generation never sees raw
## OSM JSON. See docs/data-source-register.md.

signal succeeded(buildings: Array, roads: Array, land: Array, landmarks: Array)
## Closure W2 companion: extras the frozen 4-arg signal cannot carry.
signal succeeded_v2(roads_v2: Array, waterways: Array, trees: Array, barriers: Array)
signal failed(reason: String)

## Overpass endpoints, tried in order. The main instance regularly
## times out (result=13) or returns 502 when overloaded; a transient
## failure must not lose the whole fetch. Only full-planet instances
## belong here — regional ones (osm.ch, maprva.org, ...) silently
## return zero buildings outside their extract. The main instance
## is repeated last: overload is usually a busy slot, so a later
## retry often succeeds where the first attempt timed out. The OSM-FR
## instance (global data, free fair-use) answered a live probe while the
## main one reported "at capacity" (HTTP 502), so it is the first fallback.
const ENDPOINTS: Array[String] = [
	"https://overpass-api.de/api/interpreter",
	"https://overpass.openstreetmap.fr/api/interpreter",
	"https://maps.mail.ru/osm/tools/overpass/api/interpreter",
	"https://overpass.private.coffee/api/interpreter",
	"https://overpass-api.de/api/interpreter",
]

## Per-attempt HTTP timeout. The query's own [timeout:30] fires
## first on a healthy connection; this only bounds a hung one.
## Single source for the retry budget below and for _http.timeout,
## so the two can never drift apart. Raised 35→60 s in T2.3: a full
## Paris 800 m response is ≈8 MB and measured 25–47 s end to end.
const ATTEMPT_TIMEOUT := 60.0

## Worst-case seconds for both fetch phases (detailed, then the
## best-effort ring): one attempt timeout per endpoint per phase, plus
## slack each. Callers waiting on succeeded/failed must wait at least
## this long or a late rescue is dropped. Typical is far lower (a fast
## 502 moves on in ~1 s); only hung connections pay the full budget.
static func retry_budget_seconds() -> float:
	return 2.0 * (float(ENDPOINTS.size()) * ATTEMPT_TIMEOUT + 5.0)

const CACHE_DIR := "user://cache"

## Server-side statement timeout, pinned by the register's Overpass
## rate discipline (docs/data-source-register.md): keep [timeout:30].
const OVERPASS_TIMEOUT_S := 30

## Detailed-query radius in metres (contract §7 V12: RADIUS_M=420 is
## gone). T7.0 metre cutover: the detailed extent is 2400 m across, so
## the query reaches its 1200 m half-width on every preset (one shared
## cache entry per place; presets differ by LOD, never by data — AC-12).
## T2.3 measured 800 m Paris at ≈6 MB / 25–40 s; 1200 m is ≈2.25× the
## area. If every endpoint fails, a cached FALLBACK_RADIUS_M payload is
## served (register fallback order: smaller radius → cache).
const DETAILED_RADIUS_M := 1200
const FALLBACK_RADIUS_M := 800
static func radius_for_preset(_preset: int) -> int:
	return DETAILED_RADIUS_M

## Low-detail ring radius per preset (RenderSettings.Preset order Fast,
## Balanced, High, Ultra): a second query with major roads + waterways +
## coastline only, merged over the detailed response. Fast is near-ring
## only per §3.1; 0 disables the ring phase entirely.
static func ring_radius_for_preset(preset: int) -> int:
	match preset:
		0:
			return 0
		1:
			return 1600
		2:
			return 1600
		3:
			return 2500
		_:
			return 1600

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
## Multipolygon relations per land/water key (T2.4): areas are rarely
## relations (measured: 8 MPs in a Big Sur coastal response), so one
## shared cap bounds the byte-heavy tail while covering dense cities.
const CAP_RELATIONS := 220
## Ring (low-detail majors) caps: small payload by construction; the
## 1600 m Paris ring carries ≈630 elements (≈590 highways) in ≈0.8 MB.
const CAP_RING_HIGHWAYS := 800
const CAP_RING_WATERWAYS := 150
const CAP_RING_COASTLINE := 100

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = ATTEMPT_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_done)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

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
static func build_query(lat: float, lon: float, radius_m: int = DETAILED_RADIUS_M) -> String:
	var head := "[out:json][timeout:%d];" % OVERPASS_TIMEOUT_S
	var clauses: Array[String] = [
		'way["building"](around:%d,%.6f,%.6f);out geom %d;'
			% [radius_m, lat, lon, CAP_BUILDINGS],
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

## Any notable feature, anywhere: OSM tags decide the archetype, and
## LandmarkBuilder renders that archetype on the fly at the feature's
## true position. This is what makes landmarks work for any place the
## user can pick, not just the curated registry in LocationData.
static func archetype_for(tags: Dictionary) -> String:
	var b := str(tags.get("building", ""))
	var mm := str(tags.get("man_made", ""))
	if mm == "lighthouse" or b == "lighthouse":
		return "lighthouse"
	if mm == "windmill":
		return "windmill"
	if mm == "tower" or b == "tower":
		return "tower"
	if b == "cathedral":
		return "cathedral"
	if b in ["church", "chapel"]:
		return "church"
	if b == "mosque":
		return "mosque"
	if b in ["temple", "synagogue"]:
		return "temple"
	if b == "castle" or str(tags.get("historic", "")) == "castle":
		return "castle"
	if b == "stadium" or str(tags.get("leisure", "")) == "stadium":
		return "stadium"
	return ""

## Contract-§2.6 land cover class (T2.4): the v1 set
## (water/forest/grass/field/urban) plus wetland/sand/rock/glacier/
## orchard/cemetery/pitch/quarry. "" = unmapped — documented in the
## register (docs/data-source-register.md, "Land-cover tag mapping"),
## never silently defaulted to a wrong class. Order is most-specific
## first so multi-key combos (e.g. leisure=pitch on landuse=meadow)
## resolve to the specific class.
static func land_class(tags: Dictionary) -> String:
	var natural := str(tags.get("natural", ""))
	var landuse := str(tags.get("landuse", ""))
	var leisure := str(tags.get("leisure", ""))
	if natural == "water" or natural == "bay" or tags.has("water") \
			or landuse in ["reservoir", "basin"]:
		return "water"
	if natural in ["wetland", "mud"]:
		return "wetland"
	if natural == "glacier":
		return "glacier"
	if natural in ["beach", "sand", "dune"]:
		return "sand"
	if natural in ["bare_rock", "rock", "scree", "shingle"]:
		return "rock"
	if natural == "wood" or landuse == "forest":
		return "forest"
	if landuse in ["orchard", "vineyard"]:
		return "orchard"
	if leisure == "pitch":
		return "pitch"
	if natural in ["grassland", "scrub", "heath"] \
			or landuse in ["meadow", "grass", "recreation_ground"] \
			or leisure in ["park", "garden"]:
		return "grass"
	if landuse in ["farmland", "farmyard"]:
		return "field"
	if landuse == "cemetery":
		return "cemetery"
	if landuse == "quarry":
		return "quarry"
	if landuse in ["residential", "commercial", "industrial", "retail"]:
		return "urban"
	return ""

## v1 shim over WorldScale (contract §7 V4/V7): true-metre XZ (1 unit =
## 1 m since the T7.0 cutover); new code calls WorldScale directly.
static func local_xz(lat: float, lon: float, c_lat: float, c_lon: float) -> Vector2:
	return WorldScale.xz_from_latlon(lat, lon, c_lat, c_lon)

## Metres from a raw OSM tag value ("12", "12m", "12 m", "3.5"):
## NAN when missing, unparseable, or outside [lo, hi] (callers fall
## through to their next source — never a silent 0).
static func _tag_metres(raw: Variant, lo: float, hi: float) -> float:
	var s := str(raw).strip_edges().trim_suffix("m").strip_edges()
	if not s.is_valid_float():
		return NAN
	var v := s.to_float()
	return v if v >= lo and v <= hi else NAN

## Clamped int from a raw tag value; 0 when missing/unparseable.
static func _tag_int(raw: Variant, lo: int, hi: int) -> int:
	var s := str(raw).strip_edges()
	if not s.is_valid_int():
		return 0
	return clampi(s.to_int(), lo, hi)

## OSM boolean tags: anything present except explicit no/false/0.
static func _tag_truthy(raw: Variant) -> bool:
	var s := str(raw).strip_edges().to_lower()
	return s != "" and s != "no" and s != "false" and s != "0"

## Default carriageway width per highway class (contract §2.5: the
## `width` tag wins, then `lanes` × 3.0, then this table).
static func road_class_width(road_class: String) -> float:
	match road_class:
		"motorway":
			return 15.0
		"trunk":
			return 12.0
		"primary":
			return 10.0
		"secondary":
			return 8.0
		"tertiary":
			return 7.0
		"living_street":
			return 5.0
		"service":
			return 4.0
		"track":
			return 3.5
		"cycleway":
			return 2.5
		"path", "footway", "steps", "corridor", "elevator", "bridleway":
			return 2.0
		_:
			return 6.0

## Default channel width per waterway class (contract §2.6); the
## `width` tag wins when present. Coastline is a boundary, not a
## channel, so it carries 0.
static func waterway_class_width(water_class: String) -> float:
	match water_class:
		"river":
			return 12.0
		"canal":
			return 10.0
		"fairway":
			return 20.0
		"stream":
			return 3.0
		"ditch", "drain":
			return 2.0
		"coastline":
			return 0.0
		_:
			return 4.0

## Resolved {height, height_source, levels} per contract §2.4: `height`
## tag → `building:levels` × 3.2 (v1 factor; regional floor heights are
## T4.2) → inherit (building parts only) → 10.0 v1 default. `estimate`
## never fires here — the fetcher holds no regional table; T4.2 refines
## `default` into regional inference.
static func _resolve_height(tags: Dictionary, inherit: Dictionary = {}) -> Dictionary:
	var levels := _tag_int(tags.get("building:levels", 0), 0, 200)
	var h := _tag_metres(tags.get("height", ""), 0.5, 400.0)
	if not is_nan(h):
		return {"height": h, "height_source": "tag_height", "levels": levels}
	if levels > 0:
		return {"height": maxf(6.0, float(levels) * 3.2),
			"height_source": "levels", "levels": levels}
	if not inherit.is_empty():
		return {"height": float(inherit["height"]),
			"height_source": str(inherit["height_source"]), "levels": 0}
	return {"height": 10.0, "height_source": "default", "levels": 0}

## Area-weighted polygon centroid; the AABB centre for degenerate rings.
static func _polygon_centroid(pts: PackedVector2Array, fallback: Vector2) -> Vector2:
	var area2 := 0.0
	var cx := 0.0
	var cz := 0.0
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var cross := a.x * b.y - b.x * a.y
		area2 += cross
		cx += (a.x + b.x) * cross
		cz += (a.y + b.y) * cross
	if absf(area2) < 0.000001:
		return fallback
	return Vector2(cx / (3.0 * area2), cz / (3.0 * area2))

## Ray-cast point-in-ring for nesting building:parts in parents.
static func _point_in_ring(p: Vector2, ring: PackedVector2Array) -> bool:
	var inside := false
	var j := ring.size() - 1
	for i in ring.size():
		var a := ring[i]
		var b := ring[j]
		if (a.y > p.y) != (b.y > p.y) \
				and p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
			inside = not inside
		j = i
	return inside

## One contract-§2.4 building dict: full footprint polygon (rotation and
## L/T/courtyard shapes preserved — no AABB reduction), centroid XZ,
## and every rich tag. The AABB size keys stay as the corrupt-geometry
## fallback with their v1 clamp (3–34 units, now 12–136 m).
static func _building_entry(tags: Dictionary, pts: PackedVector2Array,
		aabb: Rect2) -> Dictionary:
	var res := _resolve_height(tags)
	var centre := _polygon_centroid(pts, aabb.get_center())
	var roof_h := _tag_metres(tags.get("roof:height", ""), 0.5, 100.0)
	var min_h := _tag_metres(tags.get("min_height", ""), 0.0, 400.0)
	return {
		"footprint": pts,
		"x": centre.x, "z": centre.y,
		"size_x": clampf(aabb.size.x, 12.0, 136.0),
		"size_z": clampf(aabb.size.y, 12.0, 136.0),
		"height": res["height"], "height_source": res["height_source"],
		"levels": res["levels"],
		"min_height_m": 0.0 if is_nan(min_h) else min_h,
		"colour": str(tags.get("building:colour", "")),
		"material": str(tags.get("building:material", tags.get("material", ""))),
		"roof_shape": str(tags.get("roof:shape", "")),
		"roof_colour": str(tags.get("roof:colour", "")),
		"roof_material": str(tags.get("roof:material", "")),
		"roof_height_m": 0.0 if is_nan(roof_h) else roof_h,
		"parts": [],
		"name": str(tags.get("name", "")),
		# Type tags ArchitectureStyle keys off: the raw `building` value
		# (house, apartments, warehouse, ...), a use hint for the untyped
		# `yes`, and religion/denomination for places of worship.
		"kind": str(tags.get("building", "yes")),
		"use": _building_use(tags),
		"religion": str(tags.get("religion", "")),
		"denomination": str(tags.get("denomination", "")),
	}

## What a building is used for, from the first of amenity / shop /
## office / tourism / craft / industrial / man_made that is present
## ("" when none). A shop reads as "shop"; the rest keep their value
## (place_of_worship, school, hotel, works, ...).
static func _building_use(tags: Dictionary) -> String:
	if tags.has("shop"):
		return "shop"
	if tags.has("office"):
		return "office"
	if tags.has("industrial") or tags.has("craft"):
		return "industrial"
	for key in ["amenity", "tourism", "man_made"]:
		if tags.has(key):
			return str(tags[key])
	return ""

## One contract-§2.5 attributed road dict.
static func _road_entry(tags: Dictionary, pts: PackedVector2Array) -> Dictionary:
	var road_class := str(tags.get("highway", "unclassified"))
	var lanes := _tag_int(tags.get("lanes", 0), 0, 20)
	var width_m := road_class_width(road_class)
	var w := _tag_metres(tags.get("width", ""), 0.5, 100.0)
	if not is_nan(w):
		width_m = w
	elif lanes > 0:
		width_m = float(lanes) * 3.0
	return {"points": pts, "width_m": width_m, "lanes": lanes,
		"surface": str(tags.get("surface", "")),
		"bridge": _tag_truthy(tags.get("bridge", "")),
		"tunnel": _tag_truthy(tags.get("tunnel", "")),
		"layer": _tag_int(tags.get("layer", 0), -10, 10),
		"class": road_class}

## Member segments of a multipolygon relation for one role side:
## role "outer" (or "" — single-outer members often leave it blank)
## vs. role "inner". Members without geometry (outside the response
## bbox) are skipped; the ring join below tolerates the gap.
static func _member_segments(members: Array, want_outer: bool,
		c_lat: float, c_lon: float) -> Array:
	var segs: Array = []
	for m in members:
		if not (m is Dictionary):
			continue
		var role := str((m as Dictionary).get("role", ""))
		var is_outer := role == "outer" or role == ""
		if is_outer != want_outer:
			continue
		var geom: Array = (m as Dictionary).get("geometry", [])
		if geom.size() < 2:
			continue
		var pts := PackedVector2Array()
		for node in geom:
			if not (node is Dictionary):
				continue
			pts.append(local_xz(float((node as Dictionary).get("lat", c_lat)),
				float((node as Dictionary).get("lon", c_lon)), c_lat, c_lon))
		if pts.size() >= 2:
			segs.append(pts)
	return segs

## Stitch member segments into rings by greedy endpoint matching
## (shared end nodes decode to identical XZ, so the epsilon only
## absorbs float dust). Grows at both ends, flipping segments as
## needed. Open chains with ≥3 posts still emit — consumers close
## rings implicitly — so a partial response degrades, never drops.
static func _join_rings(segs: Array) -> Array:
	var rings: Array = []
	var pool: Array = segs.duplicate()
	while not pool.is_empty():
		var ring: PackedVector2Array = pool.pop_back()
		var grown := true
		while grown and not pool.is_empty():
			grown = false
			if ring.size() >= 3 \
					and ring[0].distance_to(ring[ring.size() - 1]) < 0.001:
				break
			var tail := ring[ring.size() - 1]
			var head := ring[0]
			for i in pool.size():
				var s: PackedVector2Array = pool[i]
				if tail.distance_to(s[0]) < 0.001:
					ring.append_array(s.slice(1))
					pool.remove_at(i)
					grown = true
					break
				if tail.distance_to(s[s.size() - 1]) < 0.001:
					for k in range(s.size() - 2, -1, -1):
						ring.append(s[k])
					pool.remove_at(i)
					grown = true
					break
				if head.distance_to(s[s.size() - 1]) < 0.001:
					var nr := PackedVector2Array(s.slice(0, s.size() - 1))
					nr.append_array(ring)
					ring = nr
					pool.remove_at(i)
					grown = true
					break
				if head.distance_to(s[0]) < 0.001:
					var nr2 := PackedVector2Array()
					for k in range(s.size() - 1, 0, -1):
						nr2.append(s[k])
					nr2.append_array(ring)
					ring = nr2
					pool.remove_at(i)
					grown = true
					break
		if ring.size() >= 3:
			rings.append(ring)
	return rings

## Contract-§2.6 land entries for one multipolygon relation: one entry
## per outer ring, each with its `holes` (inner rings attached to
## their containing outer; all inners when there is a single outer).
## waterway=riverbank relations land as water; anything without a
## mapped class (incl. coastline/boundary/route relations, which are
## not areas) yields no entry.
static func _relation_land(tags: Dictionary, members: Array,
		c_lat: float, c_lon: float) -> Array:
	var outers := _join_rings(_member_segments(members, true, c_lat, c_lon))
	if outers.is_empty():
		return []
	var cls := ""
	if str(tags.get("waterway", "")) == "riverbank":
		cls = "water"
	elif str(tags.get("natural", "")) == "coastline":
		return []
	else:
		cls = land_class(tags)
		if cls == "":
			return []
	var inners := _join_rings(_member_segments(members, false, c_lat, c_lon))
	var entries: Array = []
	for o in outers:
		var holes: Array = []
		for h in inners:
			if outers.size() == 1 or _point_in_ring((h as PackedVector2Array)[0], o):
				holes.append(h)
		entries.append({"class": cls, "points": o, "holes": holes})
	return entries

## One contract-§2.6 waterway dict (river/stream/canal lines, plus
## coastline ways via forced_class).
static func _waterway_entry(tags: Dictionary, pts: PackedVector2Array,
		forced_class: String = "") -> Dictionary:
	var wc := forced_class if forced_class != "" \
		else str(tags.get("waterway", "stream"))
	var width_m := waterway_class_width(wc)
	var w := _tag_metres(tags.get("width", ""), 0.5, 500.0)
	if not is_nan(w):
		width_m = w
	if wc == "coastline":
		width_m = 0.0
	return {"points": pts, "width_m": width_m, "class": wc}

static func parse_features(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var buildings: Array = []
	var roads: Array = []
	var land: Array = []
	var landmarks: Array = []
	var waterways: Array = []
	var trees: Array = []
	var barriers: Array = []
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"buildings": buildings, "roads": roads, "land": land,
			"landmarks": landmarks, "waterways": waterways, "trees": trees,
			"barriers": barriers}
	# Tiered statements print some elements twice (measured: 23 dupes in
	# a Paris 800 m response); first occurrence wins.
	var seen := {}
	var part_ways: Array = []
	for el in parsed.get("elements", []):
		if not (el is Dictionary):
			continue
		if el.has("id"):
			var key := str(el.get("type", "")) + ":" + str(el["id"])
			if seen.has(key):
				continue
			seen[key] = true
		var raw_tags: Variant = el.get("tags", {})
		var el_tags: Dictionary = raw_tags if raw_tags is Dictionary else {}
		# Point features (lighthouses, towers are often single nodes).
		if str(el.get("type", "")) == "node" and el.has("lat") and el.has("lon"):
			var node_arch := archetype_for(el_tags)
			if node_arch != "":
				var np := local_xz(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				landmarks.append({
					"x": np.x, "z": np.y, "archetype": node_arch,
					"name": str(el_tags.get("name", "")),
					"height": float(str(el_tags.get("height", "30")).replace("m", "")),
					"size_x": 8.0, "size_z": 8.0})
			if str(el_tags.get("natural", "")) == "tree":
				var tp := local_xz(float(el["lat"]), float(el["lon"]), c_lat, c_lon)
				trees.append({"x": tp.x, "z": tp.y})
			continue
		# Multipolygon relations (fetched via the nwr land/water
		# statements): stitched outer rings with inner-ring holes.
		# Boundary/route relations are not areas and are skipped.
		if str(el.get("type", "")) == "relation":
			if str(el_tags.get("type", "")) == "multipolygon" \
					and el.has("members"):
				var members: Array = el.get("members", [])
				for entry in _relation_land(el_tags, members, c_lat, c_lon):
					land.append(entry)
				var rel_arch := archetype_for(el_tags)
				if rel_arch != "":
					var outs := _join_rings(
						_member_segments(members, true, c_lat, c_lon))
					if not outs.is_empty():
						var box := _ring_aabb(outs[0])
						landmarks.append({
							"x": box.get_center().x, "z": box.get_center().y,
							"archetype": rel_arch,
							"name": str(el_tags.get("name", "")),
							"height": 30.0,
							"size_x": clampf(box.size.x, 6.0, 240.0),
							"size_z": clampf(box.size.y, 6.0, 240.0)})
			continue
		if not el.has("geometry"):
			continue
		var geom: Array = el.get("geometry", [])
		if geom.size() < 2:
			continue
		var pts: Array[Vector2] = []
		var min_x := INF
		var max_x := -INF
		var min_z := INF
		var max_z := -INF
		for node in geom:
			var p := local_xz(float(node.get("lat", c_lat)),
				float(node.get("lon", c_lon)), c_lat, c_lon)
			pts.append(p)
			min_x = minf(min_x, p.x)
			max_x = maxf(max_x, p.x)
			min_z = minf(min_z, p.y)
			max_z = maxf(max_z, p.y)
		var poly := PackedVector2Array(pts)
		var aabb := Rect2(min_x, min_z, max_x - min_x, max_z - min_z)
		if el_tags.has("building"):
			var entry := _building_entry(el_tags, poly, aabb)
			buildings.append(entry)
			var arch := archetype_for(el_tags)
			if arch != "":
				landmarks.append({
					"x": entry["x"], "z": entry["z"], "archetype": arch,
					"name": str(el_tags.get("name", "")),
					"height": entry["height"],
					"size_x": entry["size_x"], "size_z": entry["size_z"]})
		elif el_tags.has("building:part"):
			part_ways.append({"tags": el_tags, "points": poly, "aabb": aabb})
		elif el_tags.has("highway"):
			roads.append(_road_entry(el_tags, poly))
		elif el_tags.has("waterway"):
			if str(el_tags.get("waterway", "")) == "riverbank" \
					and _is_closed(poly):
				land.append({"class": "water", "points": poly, "holes": []})
			else:
				waterways.append(_waterway_entry(el_tags, poly))
		elif str(el_tags.get("natural", "")) == "coastline":
			waterways.append(_waterway_entry(el_tags, poly, "coastline"))
		elif el_tags.has("barrier"):
			barriers.append({"points": poly,
				"class": str(el_tags.get("barrier", "yes"))})
		else:
			var arch2 := archetype_for(el_tags)
			if arch2 != "":
				landmarks.append({
					"x": (min_x + max_x) / 2.0, "z": (min_z + max_z) / 2.0,
					"archetype": arch2, "name": str(el_tags.get("name", "")),
					"height": 30.0,
					"size_x": clampf(max_x - min_x, 6.0, 240.0),
					"size_z": clampf(max_z - min_z, 6.0, 240.0)})
			var cls := land_class(el_tags)
			if cls != "" and geom.size() >= 3:
				land.append({"class": cls, "points": poly, "holes": []})
	_nest_parts(buildings, part_ways)
	return {"buildings": buildings, "roads": roads, "land": land,
		"landmarks": landmarks, "waterways": waterways, "trees": trees,
		"barriers": barriers}

## A ring is closed when its ends meet (4 cm in internal units).
static func _is_closed(poly: PackedVector2Array) -> bool:
	return poly.size() >= 3 and poly[0].distance_to(poly[poly.size() - 1]) < 0.01

## Nest building:part ways into their parents by centroid containment
## (smallest containing footprint wins; AABB pre-filter keeps the
## Paris case — 807 parts × 2504 buildings — cheap). A part without
## its own height tags inherits the parent mass height. Parts with no
## containing parent are real masses the payload left orphaned, so
## they are emitted as buildings rather than dropped.
static func _nest_parts(buildings: Array, part_ways: Array) -> void:
	var boxes: Array[Rect2] = []
	for b in buildings:
		var fp: PackedVector2Array = b["footprint"]
		boxes.append(_ring_aabb(fp))
	for pw in part_ways:
		var tags: Dictionary = pw["tags"]
		var pts: PackedVector2Array = pw["points"]
		var paabb: Rect2 = pw["aabb"]
		var centre := _polygon_centroid(pts, paabb.get_center())
		var best := -1
		var best_area := INF
		for i in buildings.size():
			if not boxes[i].has_point(centre):
				continue
			var fp: PackedVector2Array = buildings[i]["footprint"]
			if not _point_in_ring(centre, fp):
				continue
			var area := boxes[i].size.x * boxes[i].size.y
			if area < best_area:
				best = i
				best_area = area
		if best < 0:
			buildings.append(_building_entry(tags, pts, paabb))
			boxes.append(paabb)
			continue
		var parent: Dictionary = buildings[best]
		var res := _resolve_height(tags, {
			"height": parent["height"],
			"height_source": parent["height_source"]})
		(parent["parts"] as Array).append({
			"footprint": pts, "x": centre.x, "z": centre.y,
			"size_x": clampf(paabb.size.x, 12.0, 136.0),
			"size_z": clampf(paabb.size.y, 12.0, 136.0),
			"height": res["height"], "height_source": res["height_source"],
			"levels": res["levels"],
			"colour": str(tags.get("building:colour", "")),
			"material": str(tags.get("building:material", tags.get("material", ""))),
		})

static func _ring_aabb(ring: PackedVector2Array) -> Rect2:
	var min_p := ring[0]
	var max_p := ring[0]
	for p in ring:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)

## Concatenate two Overpass responses' element lists, detailed first so
## the parse-time id-dedup keeps the detailed copy. Either side may be
## "" or invalid — the other side still parses.
static func merge_payloads(first: String, second: String) -> String:
	var els: Array = []
	var a: Variant = JSON.parse_string(first) if first != "" else {}
	if a is Dictionary:
		els.append_array(a.get("elements", []))
	var b: Variant = JSON.parse_string(second) if second != "" else {}
	if b is Dictionary:
		els.append_array(b.get("elements", []))
	return JSON.stringify({"elements": els})

## TRANSITIONAL (deleted with V13 in T4.4): bare-centreline roads for
## RoadBuilder, which still speaks v1 (the pipeline moved to §2.5 dicts
## in closure W2); _finish downgrades at the frozen signal edge.
static func roads_to_v1(roads: Array) -> Array:
	var out: Array = []
	for r in roads:
		if r is Dictionary:
			out.append((r as Dictionary).get("points", PackedVector2Array()))
		else:
			out.append(r)
	return out

## Test hook (DEM/Satellite T2.1/T2.2 precedent): when true, fetch()
## serves the on-device cache or fails immediately — never the network.
var offline_mode := false

enum { _PHASE_DETAILED, _PHASE_RING }

## Abandon any request still in flight. HTTPRequest serves one request at
## a time and answers ERR_BUSY (44) to a second one; a cancelled or
## restarted generation left its Overpass request running, so the next
## fetch burned every retry on 44 and then lost the real response's
## state. cancel_request() emits no request_completed, so nothing stale
## reaches _on_done.
func cancel() -> void:
	if _http != null:
		_http.cancel_request()

func fetch(lat: float, lon: float, preset: int = 2) -> void:
	cancel()
	# Default preset 2 is RenderSettings.Preset.HIGH (the app default);
	# out-of-range presets fall back to it, not to Fast.
	var p := preset if preset >= 0 and preset <= 3 else 2
	var radius := radius_for_preset(p)
	var ring := ring_radius_for_preset(p)
	_pending_lat = lat
	_pending_lon = lon
	# Cache key v2 (contract §5): radius suffix keeps preset queries
	# from colliding; the ring keeps its own _ring marker (a different
	# query shape, not the detailed query at a larger radius).
	# Legacy osm3_/osm4_ files are ignored, never migrated (V18).
	_pending_cache = CacheStore.osm_path(lat, lon, radius)
	_pending_body = "data=" + build_query(lat, lon, radius).uri_encode()
	_pending_ring_cache = ""
	_pending_ring_body = ""
	_detailed_text = ""
	_ring_text = ""
	var want_ring := ring > radius
	if want_ring:
		_pending_ring_cache = CacheStore.osm_ring_path(lat, lon, ring)
		_pending_ring_body = "data=" + build_ring_query(lat, lon, ring).uri_encode()
	# Each phase serves from its own cache entry independently; a phase
	# with no usable cache goes live while the other stays cached.
	var dcached := _read_cache(_pending_cache)
	if dcached != "" and _payload_has_buildings(dcached, lat, lon):
		_detailed_text = dcached
	if want_ring:
		_ring_text = _read_cache(_pending_ring_cache)
	if offline_mode:
		if _detailed_text != "":
			_finish()
		else:
			_phase = _PHASE_DETAILED
			_attempt = 0
			_fail_or_retry("OSM not cached (offline mode)", false)
		return
	if _detailed_text != "" and (not want_ring or _ring_text != ""):
		_finish()
		return
	_phase = _PHASE_DETAILED if _detailed_text == "" else _PHASE_RING
	_attempt = 0
	_start_attempt()

var _pending_lat := 0.0
var _pending_lon := 0.0
var _pending_cache := ""
var _pending_body := ""
var _pending_ring_cache := ""
var _pending_ring_body := ""
var _detailed_text := ""
var _ring_text := ""
var _phase := _PHASE_DETAILED
var _attempt := 0

static func _read_cache(path: String) -> String:
	if path == "" or not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	CacheStore.note_read(path)
	return f.get_as_text()

static func _write_cache(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		CacheStore.note_written(path)

## A cached/live detailed payload is usable when it parses to a
## non-empty building set (the cached path pays one extra parse here;
## ≈0.2 s on a 6 MB Paris response, inside the ≤5 s revisit budget).
static func _payload_has_buildings(text: String, lat: float, lon: float) -> bool:
	var probe := parse_features(text, lat, lon)
	return not (probe["buildings"] as Array).is_empty()

## A ring payload is usable when it is valid JSON with an element list
## (empty is fine — the ring carries majors only, never buildings).
static func _payload_usable(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and parsed.get("elements", null) is Array

## Transient failures are worth another instance: any transport
## error (timeout, cannot connect, ...) or a 429/5xx from an
## overloaded server. A 4xx means the query itself is rejected.
static func is_retryable(result: int, code: int) -> bool:
	if result != HTTPRequest.RESULT_SUCCESS:
		return true
	return code in [429, 500, 502, 503, 504]

func _start_attempt() -> void:
	var headers := ["Content-Type: application/x-www-form-urlencoded",
		"User-Agent: PlanetRender360/0.1"]
	var body := _pending_body if _phase == _PHASE_DETAILED else _pending_ring_body
	var err := _http.request(ENDPOINTS[_attempt], headers,
		HTTPClient.METHOD_POST, body)
	if err != OK:
		_fail_or_retry("Overpass request failed to start: %s" % err, true)

## Next attempt index for a failed attempt, or -1 to give up.
static func next_attempt(attempt: int, retryable: bool) -> int:
	return attempt + 1 if retryable and attempt + 1 < ENDPOINTS.size() else -1

func _fail_or_retry(reason: String, retryable: bool) -> void:
	var next := next_attempt(_attempt, retryable)
	if next >= 0:
		_attempt = next
		_start_attempt()
	elif _phase == _PHASE_RING:
		# The ring is best-effort garnish: its failure degrades to the
		# detailed data, never to a failed fetch.
		push_warning("OsmFetcher: ring query failed (%s); detailed data only" % reason)
		_ring_text = ""
		_finish()
	else:
		# Register fallback order: a cached smaller-radius payload
		# (pre-T7.0 800 m) beats procedural dressing.
		var fb := _read_cache(CacheStore.osm_path(_pending_lat, _pending_lon,
			FALLBACK_RADIUS_M))
		if fb != "" and _payload_has_buildings(fb, _pending_lat, _pending_lon):
			print("OsmFetcher: %s; using cached %d m data" % [reason, FALLBACK_RADIUS_M])
			_detailed_text = fb
			_finish()
			return
		failed.emit("%s (tried %d endpoint(s))" % [reason, _attempt + 1])

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail_or_retry("Overpass failed (result=%d code=%d)" % [result, code],
			is_retryable(result, code))
		return
	var text := body.get_string_from_utf8()
	if _phase == _PHASE_DETAILED:
		if not _payload_has_buildings(text, _pending_lat, _pending_lon):
			# One instance returning no buildings is not authoritative:
			# it may lag replication or hold a partial extract. Try the
			# next instance before giving up (a genuinely empty area
			# just pays a few fast empty responses). This also covers
			# corrupt payloads, which parse to nothing.
			_fail_or_retry("Overpass returned no buildings", true)
			return
		_detailed_text = text
		_write_cache(_pending_cache, text)
		if _pending_ring_body != "" and _ring_text == "":
			_phase = _PHASE_RING
			_attempt = 0
			_start_attempt()
		else:
			_finish()
	else:
		if not _payload_usable(text):
			_fail_or_retry("Overpass ring query returned an unusable payload", true)
			return
		_ring_text = text
		_write_cache(_pending_ring_cache, text)
		_finish()

## Merge the detailed + ring payloads, parse once, and emit both signals:
## v1 shapes on the frozen 4-arg signal, §2.5/§2.6 extras on succeeded_v2.
func _finish() -> void:
	var parsed := parse_features(
		merge_payloads(_detailed_text, _ring_text), _pending_lat, _pending_lon)
	succeeded_v2.emit(parsed["roads"], parsed["waterways"],
		parsed["trees"], parsed["barriers"])
	succeeded.emit(parsed["buildings"], roads_to_v1(parsed["roads"]),
		parsed["land"], parsed.get("landmarks", []))
