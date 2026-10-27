class_name LocationData
extends RefCounted

## Internal contracts between fetchers, generation, and rendering.
## Generation code never parses raw provider payloads; fetchers normalise
## into these shapes first (architecture plan: data contracts before visuals).

var place_name: String = "Unknown place"
var latitude: float = 0.0
var longitude: float = 0.0

## TerrainData equivalent, kept as typed fields for the MVP.
var grid_size: int = 48
var heights: PackedFloat32Array = PackedFloat32Array()
var water_level: float = 0.0
var landmark_type: String = "none"  # none | eiffel | tower
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
	# Paris (Notre Dame) gets its real OSM buildings instead.
	if abs(lat - 48.8584) < 0.01 and abs(lon - 2.2945) < 0.01:
		return "eiffel"
	if abs(lat) > 0.01 or abs(lon) > 0.01:
		return "tower"
	return "none"
