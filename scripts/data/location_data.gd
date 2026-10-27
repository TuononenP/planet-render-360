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
var quality_preset: int = 1

## Real-world relief across the detailed grid, in metres (0 = unknown).
## The pipeline's adaptive vertical scale maps every place to ~30
## world units, so world relief cannot tell a plain from the Alps;
## TerrainBuilder uses this to pick pavement vs meadow ground.
var relief_metres: float = 0.0

## TerrainData equivalent, kept as typed fields for the MVP.
var grid_size: int = 48
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

static func landmark_for(lat: float, lon: float, name: String) -> String:
	# Eiffel Tower only when the viewpoint is actually near it; central
	# Paris (Notre Dame) gets its real OSM buildings instead. No generic
	# placeholder tower: a fake landmark in every town reads worse than
	# the real skyline, and the camera now opens facing landmarks.
	if abs(lat - 48.8584) < 0.01 and abs(lon - 2.2945) < 0.01:
		return "eiffel"
	return "none"
