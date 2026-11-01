class_name LocationData
extends RefCounted

## Internal contracts between fetchers, generation, and rendering.
## Generation code never parses raw provider payloads; fetchers normalise
## into these shapes first (architecture plan: data contracts before visuals).
##
## v2 direction (docs/world-model-contract.md, frozen in T0.3 — comments
## only here, no behaviour change): all XZ/size fields become true metres
## via WorldScale (T1.2), heights/water/far become metres ASL with identity
## vertical scale (T1.3), buildings gain full footprint polygons + rich tags
## and roads gain attributes (T2.3), and every builder samples GroundTruth
## (T1.4) instead of heights (display_heights removed in T2.3, §7 V8).
## v1 deprecations are marked with "v2:" notes on the fields below; see
## the contract §7 schedule.

var place_name: String = "Unknown place"
var latitude: float = 0.0
var longitude: float = 0.0

## RenderSettings.Preset value (0 Fast, 1 Balanced, 2 High) chosen for
## this render; TerrainBuilder reads its budgets from it.
var quality_preset: int = 2

## Real-world relief across the detailed grid, in metres (0 = unknown).
## True source-tile metres in both vertical modes; TerrainBuilder uses
## this to pick pavement vs meadow ground and snow-line thresholds.
var relief_metres: float = 0.0

## v2 (T1.3): metres ASL at the viewpoint (DEM centre sample); render-Y
## datum for the WorldScale origin (contract §1.3/§2.2). Recorded in
## both vertical modes, even under GenerationPipeline.legacy_squash.
var centre_elevation_m: float = 0.0

## TerrainData equivalent, kept as typed fields for the MVP.
var grid_size: int = 64
## Absolute metres ASL as decoded, identity vertical scale (T1.3) —
## no squash, except under GenerationPipeline.legacy_squash (A/B only).
var heights: PackedFloat32Array = PackedFloat32Array()
## Metres ASL since T1.3 (the un-squashed v1 plane, so flood extent is
## unchanged); per-point GroundTruth.water_at wins from T1.4.
var water_level: float = 0.0
## Real low-resolution far terrain (zoom-8 DEM), already converted to
## world heights with the same centre/scale as the detailed grid, so
## the two meshes align. Empty means "no far data" (apron only).
## Metres ASL since T1.3 (identity mapping, same as heights).
var far_heights: PackedFloat32Array = PackedFloat32Array()
var far_grid_size: int = 64
## v2 (T3.3, deprecated): replaced by far_extent_m (metres).
var far_extent: float = 9000.0  # world units spanned by the far tile
## v2 (T1.3): metres spanned by the far tile; replaces far_extent (T3.3).
var far_extent_m: float = 36000.0
var far_centre_frac: Vector2 = Vector2(0.5, 0.5)  # viewpoint inside far tile
## v2 (T2.1, closure W1): DemFetcher provenance for the detailed grid —
## {zoom_near, zoom_mid, zoom_far, span_near, metres_per_px, tile_count,
## source_zoom}, or {source_zoom: 0, procedural: true} when the procedural
## fallback built the grid (contract §2.2). Scorecard (F) reads this.
var dem_source: Dictionary = {}
## v2 (T3.7): far-field DEM rings for FarTerrainBuilder, finest first
## (contract §2.2) — {zoom, origin_px: Vector2 (global px at zoom of the
## window's top-left pixel corner), width, height, heights:
## PackedFloat32Array (m ASL, row-major Mercator pixels), reach_m}.
## FarFieldFetcher via pipeline; empty = no rings (z8 far grid only).
var dem_rings: Array = []
## v2 (T3.7): far-field imagery drapes, finest first (contract §2.3) —
## {zoom, origin_px: Vector2, size_px: Vector2i, texture: Texture2D,
## reach_m}. Empty = colour-ramp fallback on the far rings.
var far_drapes: Array = []
## Satellite mosaic draped on the detailed terrain (SatelliteFetcher).
## Null means "no imagery": vertex colours dress the terrain instead.
var satellite_texture: Texture2D
## CPU copy of the same mosaic, for per-building roof colour sampling.
var satellite_image: Image
## Global-pixel coordinates (at satellite_zoom) of the mosaic's
## top-left corner; TerrainBuilder turns world XZ into UVs from it.
var satellite_origin_px: Vector2 = Vector2.ZERO
## v2 (T2.2): preset-mapped zoom — 16 Fast/Balanced, 17 High, 18 Ultra —
## plus satellite_metres_per_px for UV/alignment math (contract §2.3).
var satellite_zoom: int = 16
## v2 (T2.2, closure W1): SatelliteFetcher provenance for the drape —
## {zoom/span requested, tile_count, metres_per_px, source_zoom/source_span
## actually stitched}; empty when the fetch failed or Fast skipped it
## (contract §2.3 amendment 2026-10-28). Scorecard (F) reads this.
var satellite_source: Dictionary = {}
## v2 (T2.2, closure W1): metres per mosaic pixel at the viewpoint,
## derived from zoom + latitude (contract §2.3). UV/alignment math uses
## this, not magic spans. 0.0 means "no imagery this run".
var satellite_metres_per_px: float = 0.0
var landmark_type: String = "none"  # see landmarks() for the types
## True site of the landmark (landmarks() entry), so TerrainBuilder
## can place the model at its real bearing from the viewpoint instead
## of a fixed offset. has_landmark_site distinguishes "no site" from
## a legitimate site near 0,0.
var has_landmark_site: bool = false
var landmark_lat: float = 0.0
var landmark_lon: float = 0.0
## Landmark the viewer came to see (LandmarkVisit site), {} for none.
## The viewpoint already stands off from it; View360 only aims at it.
## Camera-only, so it is not part of the WorldCache key.
var focus: Dictionary = {}

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
## Season chosen in the 360 view; TerrainBuilder bakes its ground and
## leaf colours from it (snow line, autumn canopy, spring grass).
var season: int = Season.SUMMER

static func clamp_season(value: int) -> int:
	return clampi(value, Season.SPRING, Season.WINTER)
var seed_value: int = 0
var attribution: String = ""
## Live layers that fell back to estimates, as DataNotes rows
## {layer, effect, glyph} in plain words; empty when everything arrived.
## The 360 view shows them as a notice (design system DataNotice).
var data_notes: Array = []
## Real OSM features in world XZ space; empty means procedural dressing.
## Any notable OSM feature near the viewpoint (church, lighthouse,
## castle, stadium...), rendered on the fly as its archetype model
## at its true position. Dicts: {x, z, archetype, name, height,
## size_x, size_z} in world units / metres, from OsmFetcher.
## v2 (T1.2): x/z/size_x/size_z become true metres (contract §2.7).
var landmark_candidates: Array = []
## v2 (T2.3 LANDED): full footprint polygon + rich tags per contract
## §2.4 (height_source, levels, colour/material, roof_*, parts, ...);
## footprint/x/z/size in current internal units (true metres once T3.1
## clears the T1.2 equivalence flag). AABB keys stay as the fallback.
var buildings: Array = []
## v2 (§2.5): attributed dicts {points, width_m, lanes, surface, bridge,
## tunnel, layer, class} — carried by the pipeline since closure W2 and
## consumed by RoadBuilder (tunnels skipped, width_m via WorldScale);
## v1 bare centrelines are still accepted. OsmFetcher.roads_to_v1 +
## the frozen 4-arg signal keep the v1 shape available for older
## consumers/caches.
var roads: Array = []
## Land-cover polygons: {class: water|forest|grass|field|urban, points}
## v2 (T1.2/T2.4): metre XZ, extended class set
## (+wetland/sand/rock/glacier/orchard/cemetery/pitch/quarry) and
## optional holes (contract §2.6). Mapping frozen until T2.4; the new
## siblings waterways + trees (fields below) landed in T2.3.
var land_polygons: Array = []
## v2 (T2.3): waterway lines + coastline ways, contract §2.6 —
## {points: PackedVector2Array, width_m: float, class: String} in
## current internal units. Parsed by OsmFetcher; carried by the pipeline
## since closure W2; meshed T3.4.
var waterways: Array = []
## v2 (T2.3): real natural=tree nodes, contract §2.6 —
## {x: float, z: float} in current internal units. Parsed by OsmFetcher;
## carried by the pipeline since closure W2; planted T5.1.
var trees: Array = []
## v2 (T2.3, closure W1): linear barrier features, contract §2.6
## (amendment 2026-10-28) — {points: PackedVector2Array, class: String}
## in current internal units, class = raw `barrier` tag value (fence,
## wall, hedge, ...). Parsed by OsmFetcher; carried by the pipeline since
## closure W2; meshed by a Phase-4/5 consumer (no builder claims it).
var barriers: Array = []
## v2 (T5.4, contract §2.6 amendment 2026-10-28): far built-up landuse
## past the detailed extent — {class: residential|commercial|industrial|
## retail, points: PackedVector2Array, holes: Array} in metre XZ, from
## FarCityFetcher's one cached ring query. Empty = imagery-only far city.
var far_landuse: Array = []
## v2 (T5.4): real tall buildings (height ≥ 50 m or ≥ 15 levels) in the
## same ring — {footprint: PackedVector2Array, x, z, height} metres. The
## only source of far modern-tower clusters (La Défense); never invented.
var far_towers: Array = []
## v2 (contract §2.7 amendment 2026-10-30): CHELSA V2.1 1981–2010 climate
## normals at the viewpoint (3 × 3 km median) — t_warm_c / t_cold_c (mean
## of the warmest / coldest quarter, °C), precip_mm / precip_warm_mm
## (annual / warmest quarter), snow_days, source. Empty = unavailable;
## ClimateModel then keeps its latitude fallbacks.
var climate: Dictionary = {}

func is_valid() -> bool:
	return latitude >= -90.0 and latitude <= 90.0 \
		and longitude >= -180.0 and longitude <= 180.0 \
		and heights.size() == grid_size * grid_size

func height_at(x: int, z: int) -> float:
	var cx := clampi(x, 0, grid_size - 1)
	var cz := clampi(z, 0, grid_size - 1)
	return heights[cz * grid_size + cx]

static func known_places() -> Array:
	# On-device gazetteer: instant search predictions with no network,
	# and reverse lookup for the place card. Coordinates remain the truth.
	return [
		{"name": "Paris, France", "lat": 48.8566, "lon": 2.3522},
		{"name": "Interlaken, Switzerland", "lat": 46.6863, "lon": 7.8632},
		{"name": "Banff, Canada", "lat": 51.1789, "lon": -115.5708},
		{"name": "Big Sur, United States", "lat": 36.2704, "lon": -121.8081},
		{"name": "London, United Kingdom", "lat": 51.5074, "lon": -0.1278},
		{"name": "Rome, Italy", "lat": 41.9028, "lon": 12.4964},
		{"name": "Venice, Italy", "lat": 45.4375, "lon": 12.3358},
		{"name": "Barcelona, Spain", "lat": 41.3874, "lon": 2.1686},
		{"name": "Athens, Greece", "lat": 37.9838, "lon": 23.7275},
		{"name": "Reykjavik, Iceland", "lat": 64.1466, "lon": -21.9426},
		{"name": "Cairo, Egypt", "lat": 30.0444, "lon": 31.2357},
		{"name": "Cape Town, South Africa", "lat": -33.9249, "lon": 18.4241},
		{"name": "New York, United States", "lat": 40.7128, "lon": -74.0060},
		{"name": "San Francisco, United States", "lat": 37.7749, "lon": -122.4194},
		{"name": "Rio de Janeiro, Brazil", "lat": -22.9068, "lon": -43.1729},
		{"name": "Tokyo, Japan", "lat": 35.6762, "lon": 139.6503},
		{"name": "Sydney, Australia", "lat": -33.8688, "lon": 151.2093},
		{"name": "Turku, Finland", "lat": 60.4518, "lon": 22.2666},
		{"name": "Helsinki, Finland", "lat": 60.1699, "lon": 24.9384},
		{"name": "Stockholm, Sweden", "lat": 59.3293, "lon": 18.0686},
		{"name": "Monaco", "lat": 43.7384, "lon": 7.4246},
		{"name": "Dubai, United Arab Emirates", "lat": 25.2048, "lon": 55.2708},
		{"name": "Seoul, South Korea", "lat": 37.5665, "lon": 126.9780},
	]

## One-tap presets for the map picker: [chip label, place name, lat, lon].
## Chosen to contrast (Haussmann Paris, neon Tokyo, Gulf towers, Nordic
## waterfront, alpine, coast) so they double as test scenarios.
static func quick_picks() -> Array:
	return [
		["Paris", "Paris, France", 48.8566, 2.3522],
		["Alps", "Interlaken, Switzerland", 46.6863, 7.8632],
		["Banff", "Banff, Canada", 51.1789, -115.5708],
		["Big Sur", "Big Sur, United States", 36.2704, -121.8081],
		["Tokyo", "Tokyo, Japan", 35.6762, 139.6503],
		["New York", "New York, United States", 40.7128, -74.0060],
		["Stockholm", "Stockholm, Sweden", 59.3293, 18.0686],
		["Monaco", "Monaco", 43.7384, 7.4246],
		["Dubai", "Dubai, United Arab Emirates", 25.2048, 55.2708],
		["London", "London, United Kingdom", 51.5074, -0.1278],
		["Rome", "Rome, Italy", 41.9028, 12.4964],
		["Venice", "Venice, Italy", 45.4375, 12.3358],
		["Seoul", "Seoul, South Korea", 37.5665, 126.9780],
	]

static func suggestions_for(query: String) -> Array:
	var q := query.strip_edges().to_lower()
	var out: Array = []
	if q.length() < 2:
		return out
	var prefix: Array = []
	var contains: Array = []
	for place in known_places():
		var name := str(place["name"]).to_lower()
		if name.begins_with(q):
			prefix.append(place)
		elif name.contains(q):
			contains.append(place)
	out.append_array(prefix)
	out.append_array(contains)
	return out.slice(0, 5)

## Display name of a curated landmark type ("eiffel" -> "Eiffel Tower").
static func landmark_name(type: String) -> String:
	for entry in landmarks():
		if str(entry["type"]) == type:
			return str(entry.get("name", type.capitalize()))
	return type.capitalize()

static func known_place(lat: float, lon: float) -> String:
	for place in known_places():
		if abs(lat - float(place["lat"])) < 0.4 and abs(lon - float(place["lon"])) < 0.4:
			return str(place["name"])
	return UiTheme.coords(lat, lon)

## Curated landmark registry: the places users actually search for by
## name. Each entry renders on the fly as a procedural model
## (LandmarkBuilder) at its true bearing from the viewpoint, clamped
## into the detailed terrain. radius_m is how far the viewpoint may be
## from the site and still get the landmark as its skyline icon (a
## city-centre search for Paris still shows the Eiffel Tower, to the
## south-west where it really is). Aliases match the searched name,
## which is the strongest signal: "Turun tuomiokirkko, 1" is the
## cathedral whatever pin the geocoder returned.
static func landmarks() -> Array:
	return [
		{"type": "turku_cathedral", "name": "Turku Cathedral", "lat": 60.4524, "lon": 22.2781, "radius_m": 2500.0,
			"wiki_title": "Turku Cathedral", "height_m": 101.0,
			"aliases": ["turun tuomiokirkko", "turku cathedral", "åbo domkyrka"]},
		{"type": "helsinki_cathedral", "name": "Helsinki Cathedral", "lat": 60.1704, "lon": 24.9522, "radius_m": 5000.0,
			"wiki_title": "Helsinki Cathedral", "height_m": 62.0,
			"aliases": ["helsingin tuomiokirkko", "helsinki cathedral", "helsingfors domkyrka"]},
		{"type": "eiffel", "name": "Eiffel Tower", "lat": 48.8584, "lon": 2.2945, "radius_m": 6500.0,
			"wiki_title": "Eiffel Tower", "height_m": 330.0,
			"aliases": ["eiffel", "tour eiffel"]},
		{"type": "tokyo", "name": "Tokyo Tower", "lat": 35.6586, "lon": 139.7454, "radius_m": 9500.0,
			"wiki_title": "Tokyo Tower", "height_m": 333.0,
			"aliases": ["tokyo tower", "tokyo tawā"]},
		{"type": "big_ben", "name": "Big Ben", "lat": 51.5007, "lon": -0.1246, "radius_m": 6000.0,
			"wiki_title": "Big Ben", "height_m": 96.0,
			"aliases": ["big ben", "elizabeth tower"]},
		{"type": "colosseum", "name": "Colosseum", "lat": 41.8902, "lon": 12.4922, "radius_m": 6000.0,
			"wiki_title": "Colosseum", "height_m": 48.0,
			"aliases": ["colosseum", "colosseo", "coliseum"]},
		{"type": "sagrada", "name": "Sagrada Família", "lat": 41.4036, "lon": 2.1744, "radius_m": 5000.0,
			"wiki_title": "Sagrada Família", "height_m": 172.0,
			"aliases": ["sagrada", "sagrada familia", "sagrada família"]},
		{"type": "pyramid", "name": "Great Pyramid of Giza", "lat": 29.9792, "lon": 31.1342, "radius_m": 13000.0,
			"wiki_title": "Great Pyramid of Giza", "height_m": 139.0,
			"aliases": ["pyramid", "giza", "khufu", "cheops"]},
		{"type": "statue_liberty", "name": "Statue of Liberty", "lat": 40.6892, "lon": -74.0445, "radius_m": 7000.0,
			"wiki_title": "Statue of Liberty", "height_m": 93.0,
			"aliases": ["statue of liberty", "lady liberty"]},
		{"type": "sydney_opera", "name": "Sydney Opera House", "lat": -33.8568, "lon": 151.2153, "radius_m": 5000.0,
			"wiki_title": "Sydney Opera House", "height_m": 65.0,
			"aliases": ["sydney opera", "opera house, sydney"]},
		# Preset skylines (yaw_deg turns the model onto its real bearing).
		{"type": "burj_khalifa", "name": "Burj Khalifa", "lat": 25.1972, "lon": 55.2744, "radius_m": 8000.0,
			"wiki_title": "Burj Khalifa", "height_m": 828.0, "clear_m": 90.0, "kind": "Skyscraper",
			"aliases": ["burj khalifa", "burj dubai"]},
		# Lower Manhattan's streets run close to the Midtown grid (29°).
		{"type": "one_wtc", "name": "One World Trade Center", "lat": 40.7130, "lon": -74.0132, "radius_m": 6000.0,
			"wiki_title": "One World Trade Center", "height_m": 541.3, "clear_m": 50.0, "yaw_deg": 29.0,
			"kind": "Skyscraper", "aliases": ["one world trade", "one wtc", "freedom tower"]},
		{"type": "empire_state", "name": "Empire State Building", "lat": 40.7484, "lon": -73.9857, "radius_m": 6000.0,
			"wiki_title": "Empire State Building", "height_m": 443.2, "clear_m": 70.0, "yaw_deg": 29.0,
			"kind": "Skyscraper", "aliases": ["empire state"]},
		{"type": "salute", "name": "Santa Maria della Salute", "lat": 45.4309, "lon": 12.3346, "radius_m": 3000.0,
			"wiki_title": "Santa Maria della Salute", "height_m": 60.0, "clear_m": 45.0, "yaw_deg": 150.0,
			"kind": "Basilica", "aliases": ["santa maria della salute", "basilica della salute"]},
		{"type": "monte_carlo_casino", "name": "Monte Carlo Casino", "lat": 43.7393, "lon": 7.4283, "radius_m": 2500.0,
			"wiki_title": "Monte Carlo Casino", "height_m": 34.0, "clear_m": 60.0, "yaw_deg": -30.0,
			"kind": "Casino", "aliases": ["monte carlo casino", "casino de monte-carlo", "casino de monte carlo"]},
		{"type": "gwanghwamun", "name": "Gwanghwamun", "lat": 37.5760, "lon": 126.9769, "radius_m": 3000.0,
			"wiki_title": "Gwanghwamun", "height_m": 19.0, "clear_m": 30.0, "kind": "Palace gate",
			"aliases": ["gwanghwamun", "광화문"]},
		{"type": "banff_springs", "name": "Banff Springs Hotel", "lat": 51.1643, "lon": -115.5618, "radius_m": 3000.0,
			"wiki_title": "Banff Springs Hotel", "height_m": 59.5, "clear_m": 120.0, "yaw_deg": 225.0,
			"kind": "Hotel", "aliases": ["banff springs"]},
		{"type": "stockholm_city_hall", "name": "Stockholm City Hall", "lat": 59.3275, "lon": 18.0543, "radius_m": 4000.0,
			"wiki_title": "Stockholm City Hall", "height_m": 106.0, "clear_m": 75.0, "kind": "City hall",
			"aliases": ["stockholm city hall", "stadshuset"]},
		# Bridges: built along their axis (span_m long, yaw_deg turning the
		# model's +X onto it) on the water surface (base: water).
		{"type": "golden_gate", "name": "Golden Gate Bridge", "lat": 37.8197, "lon": -122.4786, "radius_m": 8000.0,
			"wiki_title": "Golden Gate Bridge", "height_m": 227.0, "clear_m": 20.0, "yaw_deg": 85.0,
			"span_m": 2040.0, "base": "water", "kind": "Bridge", "aliases": ["golden gate bridge"]},
		{"type": "tower_bridge", "name": "Tower Bridge", "lat": 51.5055, "lon": -0.0754, "radius_m": 5000.0,
			"wiki_title": "Tower Bridge", "height_m": 65.0, "clear_m": 30.0, "yaw_deg": 95.0,
			"span_m": 256.0, "base": "water", "kind": "Bridge", "aliases": ["tower bridge"]},
		{"type": "brooklyn_bridge", "name": "Brooklyn Bridge", "lat": 40.7056, "lon": -73.9964, "radius_m": 5000.0,
			"wiki_title": "Brooklyn Bridge", "height_m": 84.3, "clear_m": 22.0, "yaw_deg": 46.0,
			"span_m": 1132.0, "base": "water", "kind": "Bridge", "aliases": ["brooklyn bridge"]},
		{"type": "sydney_harbour_bridge", "name": "Sydney Harbour Bridge", "lat": -33.8523, "lon": 151.2106,
			"radius_m": 5000.0, "wiki_title": "Sydney Harbour Bridge", "height_m": 134.0, "clear_m": 40.0,
			"yaw_deg": -73.0, "span_m": 1149.0, "base": "water", "kind": "Bridge",
			"aliases": ["sydney harbour bridge", "harbour bridge"]},
		{"type": "bixby_creek_bridge", "name": "Bixby Creek Bridge", "lat": 36.3714, "lon": -121.9019, "radius_m": 2000.0,
			"wiki_title": "Bixby Creek Bridge", "height_m": 79.0, "clear_m": 12.0, "yaw_deg": 52.0,
			"span_m": 218.0, "kind": "Bridge", "aliases": ["bixby creek bridge", "bixby bridge"]},
	]

static func distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var east := (lon2 - lon1) * 111320.0 * cos(deg_to_rad(lat1))
	var north := (lat2 - lat1) * 110540.0
	return Vector2(east, north).length()

## Registry entry for this viewpoint/search, or {} for none. A name
## match wins outright; otherwise the nearest site inside its radius.
static func landmark_entry(lat: float, lon: float, name: String) -> Dictionary:
	var lowered := name.to_lower()
	for entry in landmarks():
		for alias in entry["aliases"]:
			if lowered.contains(str(alias)):
				return entry
	var best: Dictionary = {}
	var best_dist := INF
	for entry in landmarks():
		var d := distance_m(lat, lon, float(entry["lat"]), float(entry["lon"]))
		if d <= float(entry["radius_m"]) and d < best_dist:
			best = entry
			best_dist = d
	return best

static func landmark_for(lat: float, lon: float, name: String) -> String:
	var entry := landmark_entry(lat, lon, name)
	return str(entry.get("type", "none")) if not entry.is_empty() else "none"

## Registry entry of `type`, {} when unknown. Optional fields: yaw_deg
## (the model turned clockwise from its built frame, +X east and −Z
## north; default 0), clear_m (cleared grounds, default 68) and kind
## (the callout label when it stands beside the primary).
static func entry_for_type(type: String) -> Dictionary:
	for entry in landmarks():
		if str(entry["type"]) == type:
			return entry
	return {}

## Every other registry landmark whose radius covers the viewpoint: the
## second and third icons of a skyline (LandmarkSites builds them as
## candidates beside the primary).
static func registry_extras(lat: float, lon: float, primary_type: String) -> Array:
	var out: Array = []
	for entry in landmarks():
		if str(entry["type"]) != primary_type \
				and distance_m(lat, lon, float(entry["lat"]), float(entry["lon"])) <= float(entry["radius_m"]):
			out.append(entry)
	return out
