class_name OsmFetcher
extends Node

## Real buildings + roads from OpenStreetMap via the Overpass API.
## Free, no key, direct from device; responses cached in user://cache.
## Normalises into LocationData buildings/roads — generation never sees
## raw OSM JSON. See docs/data-source-register.md.

signal succeeded(buildings: Array, roads: Array, land: Array)
signal failed(reason: String)

const ENDPOINT := "https://overpass-api.de/api/interpreter"
const CACHE_DIR := "user://cache"
const WORLD_SCALE := 0.25  # 220 world units cover ~880 m
const RADIUS_M := 420

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 30.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

static func build_query(lat: float, lon: float) -> String:
	return "[out:json][timeout:25];(way[\"building\"](around:%d,%.6f,%.6f);way[\"highway\"](around:%d,%.6f,%.6f);way[\"natural\"](around:%d,%.6f,%.6f);way[\"landuse\"](around:%d,%.6f,%.6f);way[\"leisure\"=\"park\"](around:%d,%.6f,%.6f););out geom 900;" \
		% [RADIUS_M, lat, lon, RADIUS_M, lat, lon, RADIUS_M, lat, lon,
			RADIUS_M, lat, lon, RADIUS_M, lat, lon]

static func land_class(tags: Dictionary) -> String:
	var natural := str(tags.get("natural", ""))
	var landuse := str(tags.get("landuse", ""))
	if natural == "water" or tags.has("water"):
		return "water"
	if natural == "wood" or landuse == "forest":
		return "forest"
	if natural in ["grassland", "scrub"] or landuse in ["meadow", "grass"] \
			or str(tags.get("leisure", "")) == "park":
		return "grass"
	if landuse in ["farmland", "farmyard"]:
		return "field"
	if landuse in ["residential", "commercial", "industrial", "retail"]:
		return "urban"
	return ""

static func local_xz(lat: float, lon: float, c_lat: float, c_lon: float) -> Vector2:
	var east_m := (lon - c_lon) * 111320.0 * cos(deg_to_rad(c_lat))
	var north_m := (lat - c_lat) * 110540.0
	return Vector2(east_m * WORLD_SCALE, -north_m * WORLD_SCALE)

static func parse_features(text: String, c_lat: float, c_lon: float) -> Dictionary:
	var buildings: Array = []
	var roads: Array = []
	var land: Array = []
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"buildings": buildings, "roads": roads, "land": land}
	for el in parsed.get("elements", []):
		if not (el is Dictionary) or not el.has("geometry"):
			continue
		var geom: Array = el.get("geometry", [])
		if geom.size() < 2:
			continue
		var tags: Dictionary = el.get("tags", {})
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
		if tags.has("building"):
			var height := 10.0
			if tags.has("building:levels"):
				height = maxf(6.0, float(tags["building:levels"]) * 3.2)
			elif tags.has("height"):
				height = clampf(float(str(tags["height"]).replace("m", "")), 5.0, 80.0)
			buildings.append({
				"x": (min_x + max_x) / 2.0, "z": (min_z + max_z) / 2.0,
				"size_x": clampf(max_x - min_x, 3.0, 34.0),
				"size_z": clampf(max_z - min_z, 3.0, 34.0),
				"height": height,
				"name": str(tags.get("name", "")),
			})
		elif tags.has("highway"):
			var line := PackedVector2Array(pts)
			roads.append(line)
		else:
			var cls := land_class(tags)
			if cls != "" and geom.size() >= 3:
				land.append({"class": cls, "points": PackedVector2Array(pts)})
	return {"buildings": buildings, "roads": roads, "land": land}

func fetch(lat: float, lon: float) -> void:
	var cache_path := "%s/osm3_%d_%d.json" % [CACHE_DIR,
		int(round(lat * 1000.0)), int(round(lon * 1000.0))]
	if FileAccess.file_exists(cache_path):
		var f := FileAccess.open(cache_path, FileAccess.READ)
		if f != null:
			var result := parse_features(f.get_as_text(), lat, lon)
			if not result["buildings"].is_empty():
				succeeded.emit(result["buildings"], result["roads"], result["land"])
				return
	var body := "data=" + build_query(lat, lon).uri_encode()
	var headers := ["Content-Type: application/x-www-form-urlencoded",
		"User-Agent: PlanetRender360/0.1"]
	_pending_lat = lat
	_pending_lon = lon
	_pending_cache = cache_path
	var err := _http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		failed.emit("Overpass request failed to start: %s" % err)

var _pending_lat := 0.0
var _pending_lon := 0.0
var _pending_cache := ""

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Overpass failed (result=%d code=%d)" % [result, code])
		return
	var text := body.get_string_from_utf8()
	var f := FileAccess.open(_pending_cache, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
	var parsed := parse_features(text, _pending_lat, _pending_lon)
	if parsed["buildings"].is_empty():
		failed.emit("Overpass returned no buildings")
		return
	succeeded.emit(parsed["buildings"], parsed["roads"], parsed["land"])
