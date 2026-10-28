class_name OsmFetcher
extends Node

## Real buildings + roads from OpenStreetMap via the Overpass API.
## Free, no key, direct from device; responses cached in user://cache.
## Normalises into LocationData buildings/roads — generation never sees
## raw OSM JSON. See docs/data-source-register.md.

signal succeeded(buildings: Array, roads: Array, land: Array, landmarks: Array)
signal failed(reason: String)

## Overpass endpoints, tried in order. The main instance regularly
## times out (result=13) or returns 502 when overloaded; a transient
## failure must not lose the whole fetch. Only full-planet instances
## belong here — regional ones (osm.ch, maprva.org, ...) silently
## return zero buildings outside their extract. The main instance
## is repeated last: overload is usually a busy slot, so a later
## retry often succeeds where the first attempt timed out.
const ENDPOINTS: Array[String] = [
	"https://overpass-api.de/api/interpreter",
	"https://overpass.private.coffee/api/interpreter",
	"https://overpass-api.de/api/interpreter",
]
const CACHE_DIR := "user://cache"
const WORLD_SCALE := 0.25  # 220 world units cover ~880 m
const RADIUS_M := 420

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	# Per attempt; the query's own [timeout:30] fires first on a
	# healthy connection, this only bounds a hung one.
	_http.timeout = 35.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)

static func build_query(lat: float, lon: float) -> String:
	return "[out:json][timeout:30];(way[\"building\"](around:%d,%.6f,%.6f);way[\"highway\"](around:%d,%.6f,%.6f);way[\"natural\"](around:%d,%.6f,%.6f);way[\"landuse\"](around:%d,%.6f,%.6f);way[\"leisure\"=\"park\"](around:%d,%.6f,%.6f);way[\"man_made\"~\"^(tower|lighthouse|windmill)$\"](around:%d,%.6f,%.6f);node[\"man_made\"~\"^(tower|lighthouse|windmill)$\"](around:%d,%.6f,%.6f););out geom 900;" \
		% [RADIUS_M, lat, lon, RADIUS_M, lat, lon, RADIUS_M, lat, lon,
			RADIUS_M, lat, lon, RADIUS_M, lat, lon, RADIUS_M, lat, lon,
			RADIUS_M, lat, lon]

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
	var landmarks: Array = []
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"buildings": buildings, "roads": roads, "land": land, "landmarks": landmarks}
	for el in parsed.get("elements", []):
		if not (el is Dictionary):
			continue
		var el_tags: Dictionary = el.get("tags", {})
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
			continue
		if not el.has("geometry"):
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
			var bx := (min_x + max_x) / 2.0
			var bz := (min_z + max_z) / 2.0
			var sx := clampf(max_x - min_x, 3.0, 34.0)
			var sz := clampf(max_z - min_z, 3.0, 34.0)
			buildings.append({
				"x": bx, "z": bz, "size_x": sx, "size_z": sz,
				"height": height,
				"name": str(tags.get("name", "")),
				"roof_shape": str(tags.get("roof:shape", "")),
			})
			var arch := archetype_for(tags)
			if arch != "":
				landmarks.append({
					"x": bx, "z": bz, "archetype": arch,
					"name": str(tags.get("name", "")),
					"height": height, "size_x": sx, "size_z": sz})
		elif tags.has("highway"):
			var line := PackedVector2Array(pts)
			roads.append(line)
		else:
			var arch2 := archetype_for(tags)
			if arch2 != "":
				landmarks.append({
					"x": (min_x + max_x) / 2.0, "z": (min_z + max_z) / 2.0,
					"archetype": arch2, "name": str(tags.get("name", "")),
					"height": 30.0,
					"size_x": clampf(max_x - min_x, 6.0, 60.0),
					"size_z": clampf(max_z - min_z, 6.0, 60.0)})
			var cls := land_class(tags)
			if cls != "" and geom.size() >= 3:
				land.append({"class": cls, "points": PackedVector2Array(pts)})
	return {"buildings": buildings, "roads": roads, "land": land, "landmarks": landmarks}

func fetch(lat: float, lon: float) -> void:
	var cache_path := "%s/osm3_%d_%d.json" % [CACHE_DIR,
		int(round(lat * 1000.0)), int(round(lon * 1000.0))]
	if FileAccess.file_exists(cache_path):
		var f := FileAccess.open(cache_path, FileAccess.READ)
		if f != null:
			var result := parse_features(f.get_as_text(), lat, lon)
			if not result["buildings"].is_empty():
				succeeded.emit(result["buildings"], result["roads"], result["land"], result.get("landmarks", []))
				return
	_pending_lat = lat
	_pending_lon = lon
	_pending_cache = cache_path
	_pending_body = "data=" + build_query(lat, lon).uri_encode()
	_attempt = 0
	_start_attempt()

var _pending_lat := 0.0
var _pending_lon := 0.0
var _pending_cache := ""
var _pending_body := ""
var _attempt := 0

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
	var err := _http.request(ENDPOINTS[_attempt], headers,
		HTTPClient.METHOD_POST, _pending_body)
	if err != OK:
		_fail_or_retry("Overpass request failed to start: %s" % err, true)

func _fail_or_retry(reason: String, retryable: bool) -> void:
	if retryable and _attempt + 1 < ENDPOINTS.size():
		_attempt += 1
		_start_attempt()
	else:
		failed.emit("%s (tried %d endpoint(s))" % [reason, _attempt + 1])

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail_or_retry("Overpass failed (result=%d code=%d)" % [result, code],
			is_retryable(result, code))
		return
	var text := body.get_string_from_utf8()
	var f := FileAccess.open(_pending_cache, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
	var parsed := parse_features(text, _pending_lat, _pending_lon)
	if parsed["buildings"].is_empty():
		failed.emit("Overpass returned no buildings")
		return
	succeeded.emit(parsed["buildings"], parsed["roads"], parsed["land"], parsed.get("landmarks", []))
