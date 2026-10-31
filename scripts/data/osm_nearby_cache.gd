class_name OsmNearbyCache
extends RefCounted

## Cached detailed OSM payloads near a place, for when every live source
## failed. Cache keys quantise to ~110 m, and a payload at any radius
## still covers most of a neighbouring view, so real data from a cached
## spot a few hundred metres away beats procedural dressing. Payloads
## converted from the OSM API ("api" keys) are lossy, so a real Overpass
## payload at the same distance goes first.

static func _regex() -> RegEx:
	var rx := RegEx.new()
	rx.compile("^osm_v%d_(-?\\d+)_(-?\\d+)_(r|api)(\\d+)\\.json$" % CacheStore.DATA_VERSION)
	return rx

## Metres from the place to the spot a detailed cache file was keyed at,
## or -1 when the name is not a detailed OSM payload.
static func distance_m(path: String, lat: float, lon: float) -> float:
	var m := _regex().search(path.get_file())
	if m == null:
		return -1.0
	return _metres(m, lat, lon)

static func _metres(m: RegExMatch, lat: float, lon: float) -> float:
	var c_lat := int(m.get_string(1)) / 1000.0
	var c_lon := int(m.get_string(2)) / 1000.0
	return WorldScale.xz_from_latlon(c_lat, c_lon, lat, lon).length() \
		/ WorldScale.metres_to_units()

## Cache-file paths within max_m of the place, nearest first (Overpass
## before API, then larger radius first, on a tie). Ring payloads and
## other layers are ignored.
static func candidates(lat: float, lon: float, max_m: float) -> Array[String]:
	var rx := _regex()
	var found: Array = []
	for f in DirAccess.get_files_at(CacheStore.base_dir()):
		var m := rx.search(f)
		if m == null:
			continue
		var d := _metres(m, lat, lon)
		if d <= max_m:
			found.append({"path": "%s/%s" % [CacheStore.base_dir(), f], "d": d,
				"api": m.get_string(3) == "api", "r": int(m.get_string(4))})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(a["d"], b["d"]):
			return a["d"] < b["d"]
		if a["api"] != b["api"]:
			return not a["api"]
		return a["r"] > b["r"])
	var out: Array[String] = []
	for e in found:
		out.append(e["path"])
	return out
