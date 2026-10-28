class_name LocationData
extends RefCounted

## Internal contracts between fetchers, generation, and rendering.
## Generation code never parses raw provider payloads; fetchers normalise
## into these shapes first (architecture plan: data contracts before visuals).

var place_name: String = "Unknown place"
var latitude: float = 0.0
var longitude: float = 0.0

## RenderSettings.Preset value (0 Fast, 1 Balanced, 2 High) chosen for
## this render; TerrainBuilder reads its budgets from it.
var quality_preset: int = 2

## Real-world relief across the detailed grid, in metres (0 = unknown).
## The pipeline's adaptive vertical scale maps every place to ~30
## world units, so world relief cannot tell a plain from the Alps;
## TerrainBuilder uses this to pick pavement vs meadow ground.
var relief_metres: float = 0.0

## TerrainData equivalent, kept as typed fields for the MVP.
var grid_size: int = 64
var heights: PackedFloat32Array = PackedFloat32Array()
## Mesh-ready heights (smoothed/flattened/water-carved), filled lazily
## by TerrainBuilder so meshes, buildings, roads, and trees all sample
## exactly the same ground. Empty means "not computed yet".
var display_heights: PackedFloat32Array = PackedFloat32Array()
var water_level: float = 0.0
## Real low-resolution far terrain (zoom-8 DEM), already converted to
## world heights with the same centre/scale as the detailed grid, so
## the two meshes align. Empty means "no far data" (apron only).
var far_heights: PackedFloat32Array = PackedFloat32Array()
var far_grid_size: int = 64
var far_extent: float = 9000.0  # world units spanned by the far tile
var far_centre_frac: Vector2 = Vector2(0.5, 0.5)  # viewpoint inside far tile
## Satellite mosaic draped on the detailed terrain (SatelliteFetcher).
## Null means "no imagery": vertex colours dress the terrain instead.
var satellite_texture: Texture2D
## CPU copy of the same mosaic, for per-building roof colour sampling.
var satellite_image: Image
## Global-pixel coordinates (at satellite_zoom) of the mosaic's
## top-left corner; TerrainBuilder turns world XZ into UVs from it.
var satellite_origin_px: Vector2 = Vector2.ZERO
var satellite_zoom: int = 16
var landmark_type: String = "none"  # see landmarks() for the types
## True site of the landmark (landmarks() entry), so TerrainBuilder
## can place the model at its real bearing from the viewpoint instead
## of a fixed offset. has_landmark_site distinguishes "no site" from
## a legitimate site near 0,0.
var has_landmark_site: bool = false
var landmark_lat: float = 0.0
var landmark_lon: float = 0.0

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
## Season chosen in the 360 view; TerrainBuilder bakes its ground and
## leaf colours from it (snow line, autumn canopy, spring grass).
var season: int = Season.SUMMER

static func clamp_season(value: int) -> int:
	return clampi(value, Season.SPRING, Season.WINTER)
var seed_value: int = 0
var attribution: String = ""
## Real OSM features in world XZ space; empty means procedural dressing.
## Any notable OSM feature near the viewpoint (church, lighthouse,
## castle, stadium...), rendered on the fly as its archetype model
## at its true position. Dicts: {x, z, archetype, name, height,
## size_x, size_z} in world units / metres, from OsmFetcher.
var landmark_candidates: Array = []
var buildings: Array = []
var roads: Array = []
## Land-cover polygons: {class: water|forest|grass|field|urban, points}
var land_polygons: Array = []

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

static func known_place(lat: float, lon: float) -> String:
	for place in known_places():
		if abs(lat - float(place["lat"])) < 0.4 and abs(lon - float(place["lon"])) < 0.4:
			return str(place["name"])
	return "%.4f°, %.4f°" % [lat, lon]

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
		{"type": "turku_cathedral", "lat": 60.4524, "lon": 22.2781, "radius_m": 2500.0,
			"aliases": ["turun tuomiokirkko", "turku cathedral", "åbo domkyrka"]},
		{"type": "helsinki_cathedral", "lat": 60.1704, "lon": 24.9522, "radius_m": 5000.0,
			"aliases": ["helsingin tuomiokirkko", "helsinki cathedral", "helsingfors domkyrka"]},
		{"type": "eiffel", "lat": 48.8584, "lon": 2.2945, "radius_m": 6500.0,
			"aliases": ["eiffel", "tour eiffel"]},
		{"type": "tokyo", "lat": 35.6586, "lon": 139.7454, "radius_m": 9500.0,
			"aliases": ["tokyo tower", "tokyo tawā"]},
		{"type": "big_ben", "lat": 51.5007, "lon": -0.1246, "radius_m": 6000.0,
			"aliases": ["big ben", "elizabeth tower"]},
		{"type": "colosseum", "lat": 41.8902, "lon": 12.4922, "radius_m": 6000.0,
			"aliases": ["colosseum", "colosseo", "coliseum"]},
		{"type": "sagrada", "lat": 41.4036, "lon": 2.1744, "radius_m": 5000.0,
			"aliases": ["sagrada", "sagrada familia", "sagrada família"]},
		{"type": "pyramid", "lat": 29.9792, "lon": 31.1342, "radius_m": 13000.0,
			"aliases": ["pyramid", "giza", "khufu", "cheops"]},
		{"type": "statue_liberty", "lat": 40.6892, "lon": -74.0445, "radius_m": 7000.0,
			"aliases": ["statue of liberty", "lady liberty"]},
		{"type": "sydney_opera", "lat": -33.8568, "lon": 151.2153, "radius_m": 5000.0,
			"aliases": ["sydney opera", "opera house, sydney"]},
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
