class_name CacheStore
extends RefCounted

## On-device history + versioned tile/area cache index (contract §5).
## No server, no account: a JSON file in user:// is the history store,
## and user://cache holds the fetch payloads. Generated terrain is
## reproducible from the stored coordinates + seed, so history entries
## double as cache keys — each entry carries its v2 key set.
##
## Cache key v2 grammar (all under user://cache/):
##   dem_v<V>_<z>_<x>_<y>.png        one Terrarium tile
##   sat_v<V>_<z>_<x>_<y>.jpg        one Esri tile
##   osm_v<V>_<lat_q>_<lon_q>_r<radius_m>.json      one detailed response
##   osm_v<V>_<lat_q>_<lon_q>_ring<ring_m>.json    one low-detail ring query
## <V> is DATA_VERSION below — the single source. Fetchers format keys
## through the path helpers here, never inline. The ring key keeps the
## T2.3 `_ring` marker (not the plain `_r` form) because the ring is a
## different query shape (majors only), not the detailed query at a
## larger radius: a plain radius suffix would collide if T7.4 ever
## scales the detailed radius onto a ring radius.
##
## Area quantisation is round(deg x 1000), shared via quant().
## Invalidation: bump DATA_VERSION (global) or invalidate_layer() for
## one layer prefix (per-layer refresh). Legacy files (v1 dem_/sat_/
## osm3_, transitional osm4_) are IGNORED, never migrated — a v2
## client missing a v2 key refetches (contract §7 V18). Under cap
## pressure the LRU reaps legacy files first (dead weight).
##
## LRU bookkeeping lives in user://cache/lru.json (path -> bytes +
## last-access time), updated via note_read()/note_written() on every
## cache hit/write. Cap enforcement runs whenever a write pushes the
## tracked total over max_cache_bytes, oldest-atime first.

const PATH := "user://history.json"
const MAX_ENTRIES := 50
## Contract §5: the cache data version. Bump to invalidate everything.
const DATA_VERSION := 2
const CACHE_DIR := "user://cache"
const LRU_FILE := "lru.json"

## LRU size cap in bytes (default 512 MB: an Ultra place holds ~50 MB,
## so ~10 places stay cached). Static var (not const) so tests can
## shrink it; production never changes it at runtime.
static var max_cache_bytes := 512 * 1024 * 1024
## Test hook (offline_mode precedent): when non-empty, all cache paths
## resolve under this directory instead of CACHE_DIR, so eviction and
## key tests never touch the real on-device cache.
static var dir_override := ""

var entries: Array[Dictionary] = []

static var _lru: Dictionary = {}  # relpath -> {"bytes": int, "atime": float}
static var _lru_loaded := false
static var _tracked_bytes := -1  # -1 = unknown, rescan on next write

static func base_dir() -> String:
	return dir_override if dir_override != "" else CACHE_DIR

static func quant(v: float) -> int:
	return int(round(v * 1000.0))

static func dem_path(z: int, x: int, y: int) -> String:
	return "%s/dem_v%d_%d_%d_%d.png" % [base_dir(), DATA_VERSION, z, x, y]

static func sat_path(z: int, x: int, y: int) -> String:
	return "%s/sat_v%d_%d_%d_%d.jpg" % [base_dir(), DATA_VERSION, z, x, y]

static func osm_path(lat: float, lon: float, radius_m: int) -> String:
	return "%s/osm_v%d_%d_%d_r%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), radius_m]

static func osm_ring_path(lat: float, lon: float, ring_m: int) -> String:
	return "%s/osm_v%d_%d_%d_ring%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), ring_m]

## Layer owning a cache file name: "dem", "sat", "osm", or "" for
## anything else (map tiles, search results, the LRU index itself).
## Legacy prefixes map to their layer too, so per-layer accounting
## covers the whole directory.
static func layer_of(file_name: String) -> String:
	var base := file_name.get_file()
	if base.begins_with("dem_v") or base.begins_with("dem_"):
		return "dem"
	if base.begins_with("sat_v") or base.begins_with("sat_"):
		return "sat"
	if base.begins_with("osm_v") or base.begins_with("osm4_") \
			or base.begins_with("osm3_"):
		return "osm"
	return ""

static func is_v2_name(file_name: String) -> bool:
	var base := file_name.get_file()
	var tag := "_v%d_" % DATA_VERSION
	return base.begins_with("dem" + tag) or base.begins_with("sat" + tag) \
		or base.begins_with("osm" + tag)

## Full v2 key set warming/covering a place at a preset (High default,
## the app default): {"dem": [...], "sat": [...], "osm": [...]}.
## DEM keys are preset-independent (grid resamples the same tiles);
## satellite zoom/span and the OSM ring follow the preset maps.
## History entries store this; OfflineDownloader warms exactly it.
static func place_cache_keys(lat: float, lon: float, preset: int = 2) -> Dictionary:
	var p := clampi(preset, 0, 3)
	var dem: Array[String] = []
	for t in DemFetcher.mosaic_tiles(lat, lon, DemFetcher.ZOOM_NEAR):
		dem.append(dem_path(DemFetcher.ZOOM_NEAR, t.x, t.y))
	var mid := DemFetcher.tile_xy(lat, lon, DemFetcher.ZOOM_MID)
	dem.append(dem_path(DemFetcher.ZOOM_MID, mid.x, mid.y))
	var far := DemFetcher.tile_xy(lat, lon, DemFetcher.FAR_ZOOM)
	dem.append(dem_path(DemFetcher.FAR_ZOOM, far.x, far.y))
	var sat: Array[String] = []
	if p > RenderSettings.Preset.FAST:
		var zoom := RenderSettings.satellite_zoom_for(p)
		var span := RenderSettings.satellite_span_for(p, lat)
		for t in SatelliteFetcher.mosaic_tiles(lat, lon, zoom, span):
			sat.append(sat_path(zoom, t.x, t.y))
	var osm: Array[String] = []
	var radius := OsmFetcher.radius_for_preset(p)
	osm.append(osm_path(lat, lon, radius))
	var ring := OsmFetcher.ring_radius_for_preset(p)
	if ring > radius:
		osm.append(osm_ring_path(lat, lon, ring))
	return {"dem": dem, "sat": sat, "osm": osm}

## Per-layer presence of a key set: {"dem": {"cached": a, "total": b},
## ...}. A layer is fully cached when cached == total.
static func keys_cached_status(keys: Dictionary) -> Dictionary:
	var out := {}
	for layer in ["dem", "sat", "osm"]:
		var total := 0
		var cached := 0
		for k in keys.get(layer, []):
			total += 1
			if FileAccess.file_exists(str(k)):
				cached += 1
		out[layer] = {"cached": cached, "total": total}
	return out

static func keys_fully_cached(keys: Dictionary) -> bool:
	for layer in ["dem", "sat", "osm"]:
		for k in keys.get(layer, []):
			if not FileAccess.file_exists(str(k)):
				return false
	return true

func load_store() -> void:
	entries.clear()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				entries.append(item)

func save_store() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("CacheStore: cannot write %s" % PATH)
		return
	f.store_string(JSON.stringify(entries))

## History entry + its v2 key set. cache_keys defaults to the full
## High-preset key set for the coordinates (the app default; callers
## that generated at another preset pass place_cache_keys(lat, lon, p)).
func add_entry(place_name: String, lat: float, lon: float,
		cache_keys: Dictionary = {}) -> void:
	entries = entries.filter(func(e: Dictionary) -> bool:
		return not (abs(float(e.get("lat", 999.0)) - lat) < 0.0001 \
			and abs(float(e.get("lon", 999.0)) - lon) < 0.0001))
	var keys := cache_keys if not cache_keys.is_empty() \
		else place_cache_keys(lat, lon)
	entries.push_front({
		"name": place_name, "lat": lat, "lon": lon,
		"cached": true, "timestamp": Time.get_unix_time_from_system(),
		"cache_version": DATA_VERSION, "cache_keys": keys,
	})
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	save_store()

## Per-layer presence for a history entry (see keys_cached_status).
## Entries written before cache v2 carry no keys and report empty.
func entry_cache_status(entry: Dictionary) -> Dictionary:
	return keys_cached_status(entry.get("cache_keys", {}))

func clear() -> void:
	entries.clear()
	save_store()

# --- LRU size cap + per-layer invalidation (all static) ---

static func _lru_path() -> String:
	return base_dir() + "/" + LRU_FILE

static func _ensure_lru() -> void:
	if _lru_loaded:
		return
	_lru_loaded = true
	_lru = {}
	if not FileAccess.file_exists(_lru_path()):
		return
	var f := FileAccess.open(_lru_path(), FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_lru = parsed

static func _save_lru() -> void:
	DirAccess.make_dir_recursive_absolute(base_dir())
	var f := FileAccess.open(_lru_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_lru))

## Drop the in-memory LRU state (used after clear_cache deletes the
## directory out from under it, and by tests for a clean slate).
static func reset_lru() -> void:
	_lru = {}
	_lru_loaded = false
	_tracked_bytes = -1

static func _rel(path: String) -> String:
	var base := base_dir()
	if path.begins_with(base + "/"):
		return path.substr(base.length() + 1)
	return path.get_file()

static func _file_bytes(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return int(f.get_length()) if f != null else 0

## Record a cache hit. atime_override is a test hook (default: now).
static func note_read(path: String, atime_override: float = -1.0) -> void:
	_ensure_lru()
	var now := Time.get_unix_time_from_system() \
		if atime_override < 0.0 else atime_override
	_lru[_rel(path)] = {"bytes": _file_bytes(path), "atime": now}
	_save_lru()

## Record a cache write, enforcing the size cap when the tracked
## total exceeds it. atime_override is a test hook (default: now).
static func note_written(path: String, atime_override: float = -1.0) -> void:
	_ensure_lru()
	if _tracked_bytes < 0:
		_tracked_bytes = _scan_bytes()
	var now := Time.get_unix_time_from_system() \
		if atime_override < 0.0 else atime_override
	var rel := _rel(path)
	var old := int((_lru.get(rel, {}) as Dictionary).get("bytes", 0))
	var size := _file_bytes(path)
	_lru[rel] = {"bytes": size, "atime": now}
	_tracked_bytes += size - old
	_save_lru()
	if _tracked_bytes > max_cache_bytes:
		enforce_size_cap()

static func _scan_bytes() -> int:
	var total := 0
	for e in _scan_files():
		total += int(e["bytes"])
	return total

## Every cache file except the LRU index itself: {"path", "rel",
## "bytes", "atime"} (atime from the index, else the file mtime).
static func _scan_files() -> Array:
	_ensure_lru()
	var out: Array = []
	_scan_dir(base_dir(), out)
	return out

static func _scan_dir(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path + "/" + name
		if dir.current_is_dir():
			if name != "." and name != "..":
				_scan_dir(full, out)
		elif full != _lru_path():
			var rel := _rel(full)
			var row := _lru.get(rel, {}) as Dictionary
			var atime := float(row.get("atime",
				FileAccess.get_modified_time(full)))
			out.append({"path": full, "rel": rel,
				"bytes": _file_bytes(full), "atime": atime})
		name = dir.get_next()
	dir.list_dir_end()

## Evict oldest-atime-first until the cache fits max_cache_bytes.
## Legacy (non-v2) files go first — they are dead weight no fetcher
## reads. The LRU index itself is never evicted. Returns bytes freed.
static func enforce_size_cap() -> int:
	var files := _scan_files()
	var total := 0
	for e in files:
		total += int(e["bytes"])
	if total <= max_cache_bytes:
		_tracked_bytes = total
		return 0
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var la := is_v2_name(str(a["rel"]))
		var lb := is_v2_name(str(b["rel"]))
		if la != lb:
			return lb  # legacy first
		if float(a["atime"]) != float(b["atime"]):
			return float(a["atime"]) < float(b["atime"])
		return str(a["rel"]) < str(b["rel"]))
	var freed := 0
	var kept := {}
	for e in files:
		if total <= max_cache_bytes:
			kept[str(e["rel"])] = {"bytes": int(e["bytes"]),
				"atime": float(e["atime"])}
		else:
			DirAccess.remove_absolute(str(e["path"]))
			total -= int(e["bytes"])
			freed += int(e["bytes"])
	_lru = kept
	_tracked_bytes = total
	_save_lru()
	return freed

## Delete one layer's v2 files ("dem", "sat", or "osm") so that layer
## — and only that layer — refetches on next open. Legacy files are
## left alone (never read; the LRU reaps them first). Returns the
## number of files removed.
static func invalidate_layer(layer: String) -> int:
	_ensure_lru()
	var removed := 0
	for e in _scan_files():
		var rel := str(e["rel"])
		if layer_of(rel) == layer and is_v2_name(rel):
			DirAccess.remove_absolute(str(e["path"]))
			_lru.erase(rel)
			_tracked_bytes = _tracked_bytes - int(e["bytes"]) \
				if _tracked_bytes >= 0 else -1
			removed += 1
	_save_lru()
	return removed

## Whole-cache accounting: {"bytes", "files", "by_layer": {layer:
## {"bytes", "files"}}}. Backs the settings storage readout.
static func cache_stats() -> Dictionary:
	var by_layer := {}
	var total_bytes := 0
	var total_files := 0
	for e in _scan_files():
		var layer := layer_of(str(e["rel"]))
		if layer == "":
			layer = "other"
		var row: Dictionary = by_layer.get(layer, {"bytes": 0, "files": 0})
		row["bytes"] = int(row["bytes"]) + int(e["bytes"])
		row["files"] = int(row["files"]) + 1
		by_layer[layer] = row
		total_bytes += int(e["bytes"])
		total_files += 1
	return {"bytes": total_bytes, "files": total_files,
		"by_layer": by_layer}
