class_name OsmNearbyCache
extends RefCounted

## Cached detailed OSM payloads near a place, for when every live source
## failed. Cache keys quantise to ~110 m, and a payload at any radius
## still covers most of a neighbouring view, so real data from a cached
## spot a few hundred metres away beats procedural dressing.

## Cache-file paths within max_m of the place, nearest first (larger
## radius first on a tie). Ring payloads and other layers are ignored.
static func candidates(lat: float, lon: float, max_m: float) -> Array[String]:
	var rx := RegEx.new()
	rx.compile("^osm_v%d_(-?\\d+)_(-?\\d+)_r(\\d+)\\.json$" % CacheStore.DATA_VERSION)
	var found: Array = []
	for f in DirAccess.get_files_at(CacheStore.base_dir()):
		var m := rx.search(f)
		if m == null:
			continue
		var c_lat := int(m.get_string(1)) / 1000.0
		var c_lon := int(m.get_string(2)) / 1000.0
		var d := WorldScale.xz_from_latlon(c_lat, c_lon, lat, lon).length() \
			/ WorldScale.metres_to_units()
		if d <= max_m:
			found.append({"path": "%s/%s" % [CacheStore.base_dir(), f],
				"d": d, "r": int(m.get_string(3))})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(a["d"], b["d"]):
			return a["d"] < b["d"]
		return a["r"] > b["r"])
	var out: Array[String] = []
	for e in found:
		out.append(e["path"])
	return out
