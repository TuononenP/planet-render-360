class_name CacheStore
extends RefCounted

## On-device history + versioned tile/area cache index (contract §5).
## No server, no account: a JSON file in user:// is the history store,
## and user://cache holds the fetch payloads. Generated terrain is
## reproducible from the stored coordinates + quality tier; cache paths
## are computed when needed so history survives a data-directory move.
##
## Cache key v2 grammar (all under user://cache/):
##   dem_v<V>_<z>_<x>_<y>.png        one Terrarium tile
##   sat_v<V>_<z>_<x>_<y>.jpg        one Esri tile
##   osm_v<V>_<lat_q>_<lon_q>_r<radius_m>_q<Q>.json  one detailed response
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
## cache hit/write. There is no size limit and nothing is evicted
## automatically; the index only accounts for what is on the device so
## Settings can show per-place sizes. The person frees space explicitly
## per place (clear_place_cache) or all at once (OfflineDownloader).

const PATH := "user://history.json"
const MAX_ENTRIES := 50
## Layout of history.json: {"version", "entries"}. Version 0 was a bare array.
const HISTORY_VERSION := 1
## Contract §5: the cache data version. Bump to invalidate everything.
const DATA_VERSION := 2
## Raster windows have independent versions; leave DATA_VERSION untouched.
const LANDCOVER_VERSION := 2
const CACHE_DIR := "user://cache"
const LRU_FILE := "lru.json"
## The index is written at most this often while the cache is in use.
const SAVE_EVERY_S := 2.0
## Marks a folder discard_dir moved aside for deletion.
const TRASH_MARK := ".trash-"

## Test hook (offline_mode precedent): when non-empty, all cache paths
## resolve under this directory instead of CACHE_DIR, so accounting and
## key tests never touch the real on-device cache.
static var dir_override := ""
## Tests can isolate history without discarding the reusable data cache.
static var history_override := ""
## Deprecated no-op, kept for the capture/windowed tests that set it:
## nothing is evicted automatically any more, so there is nothing to
## suppress. Do not add new readers.
static var eviction_suppressed := false
## Set on quit: a scan running on a worker gives up, its result dropped.
static var stop_scans := false

var entries: Array[Dictionary] = []

static var _lru: Dictionary = {}  # relpath -> {"bytes": int, "atime": float}
static var _lru_loaded := false
## 404 answers per tile path this session. One may be a server hiccup; a
## second, on the save's own retry, means the source does not have it.
static var _absent: Dictionary = {}
const ABSENT_AFTER := 2
static var _lru_pending := ""  # index path a coalesced save is queued for
static var _tracked_bytes := -1  # -1 = unknown, summed from the index on next use
## A scan has counted the whole directory this session (map tiles too).
static var _reconciled := false
static var _load_task := -1
static var _loaded: Variant = null  # the index preload_index parsed
static var _index_waiters: Array[Callable] = []  # called when the preload lands
static var _save_task := -1
static var _save_armed := false
static var _scan_task := -1
static var _scan_gen := 0  # bumped per scan and reset: a stale result is dropped
static var _scan_joined := false  # finish() already waited for _scan_task
static var _scan_again := false  # asked for while one was running
static var _touched: Dictionary = {}  # rel -> true, noted while a scan runs
static var _cleared: Dictionary = {}  # rel -> true, cleared while a scan runs
static var _trash_tasks: Array[int] = []  # discard_dir deletions
## One [done] box per task _spawn started and busy() has not seen finish.
static var _working: Array = []
static var _exit_hooked := false

static func base_dir() -> String:
	return dir_override if dir_override != "" else CACHE_DIR

static func quant(v: float) -> int:
	return int(round(v * 1000.0))

static func dem_path(z: int, x: int, y: int) -> String:
	return "%s/dem_v%d_%d_%d_%d.png" % [base_dir(), DATA_VERSION, z, x, y]

static func sat_path(z: int, x: int, y: int) -> String:
	return "%s/sat_v%d_%d_%d_%d.jpg" % [base_dir(), DATA_VERSION, z, x, y]

static func osm_path(lat: float, lon: float, radius_m: int) -> String:
	return "%s/osm_v%d_%d_%d_r%d_q%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), radius_m, OsmQuery.QUERY_VERSION]

static func osm_legacy_path(lat: float, lon: float, radius_m: int) -> String:
	return "%s/osm_v%d_%d_%d_r%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), radius_m]

## Payload converted from the OSM API when Overpass was down: lossy, so it
## never sits under osm_path (the key a fresh Overpass answer is read from).
static func osm_api_path(lat: float, lon: float, radius_m: int) -> String:
	return "%s/osm_v%d_%d_%d_api%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), radius_m]

## Marker that Overpass and the OSM API both found nothing here (open sea,
## wilderness), so the next load within OsmFetcher.EMPTY_TTL_S does not
## ask either again. Not a detailed payload: OsmNearbyCache skips it.
static func osm_empty_path(lat: float, lon: float) -> String:
	return "%s/osm_v%d_%d_%d_empty_q%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), OsmQuery.QUERY_VERSION]

static func osm_ring_path(lat: float, lon: float, ring_m: int) -> String:
	return "%s/osm_v%d_%d_%d_ring%d.json" % [base_dir(), DATA_VERSION,
		quant(lat), quant(lon), ring_m]

static func osm_poi_path(lat: float, lon: float) -> String:
	return "%s/osm_v%d_%d_%d_poi_q1.json" % [base_dir(), DATA_VERSION, quant(lat), quant(lon)]

## The bridge outline layer (OsmQuery.build_bridge_area_query).
static func osm_bridge_path(lat: float, lon: float) -> String:
	return "%s/osm_v%d_%d_%d_bridges_q%d.json" % [base_dir(), DATA_VERSION, quant(lat), quant(lon),
		OsmQuery.BRIDGE_AREA_VERSION]

static func landcover_path(kind: String, lat: float, lon: float) -> String:
	return "%s/%s_v%d_%d_%d.png" % [base_dir(), kind, LANDCOVER_VERSION,
		roundi(lat * 1000000.0), roundi(lon * 1000000.0)]

## Landmark lookups (WikiFetcher): nearby articles per 0.01° cell and
## radius, one summary per article, one photo per Commons file. Not a
## world layer: they ride the LRU like search results.
static func wiki_near_path(lat: float, lon: float, radius_m: int) -> String:
	return "%s/wiki_near_%d_%d_r%d.json" % [base_dir(),
		int(round(lat * 100.0)), int(round(lon * 100.0)), radius_m]

static func wiki_summary_path(lang: String, title: String) -> String:
	return "%s/wiki_sum_%s_%s.json" % [base_dir(), lang,
		title.sha1_text().substr(0, 16)]

static func wiki_photo_path(file: String) -> String:
	return "%s/wiki_img_%s.json" % [base_dir(), file.sha1_text().substr(0, 16)]

static func wiki_photo_bytes_path(file: String) -> String:
	return "%s/wiki_img_%s.bin" % [base_dir(), file.sha1_text().substr(0, 16)]

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
	if base.begins_with("climate_v"):
		return "climate"
	if base.begins_with("landcover_v") or base.begins_with("canopy_v"):
		return "landcover"
	return ""

static func is_v2_name(file_name: String) -> bool:
	var base := file_name.get_file()
	var tag := "_v%d_" % DATA_VERSION
	return base.begins_with("dem" + tag) or base.begins_with("sat" + tag) \
		or base.begins_with("osm" + tag) or base.begins_with("climate" + tag) \
		or base.begins_with("landcover_v%d_" % LANDCOVER_VERSION) \
		or base.begins_with("canopy_v%d_" % LANDCOVER_VERSION)

## Records a 404 for a tile; a save stops counting it missing once the
## source has said so twice.
static func note_absent(path: String) -> void:
	_absent[path] = int(_absent.get(path, 0)) + 1

static func is_absent(path: String) -> bool:
	return int(_absent.get(path, 0)) >= ABSENT_AFTER

## Current key set warming/covering a place at a preset (High default):
## {"dem": [...], "sat": [...], "osm": [...], "landcover": [...]}.
## DEM keys are preset-independent (grid resamples the same tiles);
## satellite zoom/span and the OSM ring follow the preset maps.
## History computes it on demand; OfflineDownloader warms it.
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
	if p > RenderSettings.Preset.FAST:
		osm.append(osm_poi_path(lat, lon))
	var landcover: Array[String] = []
	if p > RenderSettings.Preset.FAST:
		landcover.append(landcover_path("landcover", lat, lon))
		landcover.append(landcover_path("canopy", lat, lon))
	return {"dem": dem, "sat": sat, "osm": osm, "landcover": landcover}

## Per-layer presence of a key set: {"dem": {"cached": a, "total": b},
## ...}. A layer is fully cached when cached == total.
static func keys_cached_status(keys: Dictionary) -> Dictionary:
	var out := {}
	for layer in ["dem", "sat", "osm", "landcover"]:
		var total := 0
		var cached := 0
		for k in keys.get(layer, []):
			total += 1
			if FileAccess.file_exists(str(k)):
				cached += 1
		out[layer] = {"cached": cached, "total": total}
	return out

static func keys_fully_cached(keys: Dictionary) -> bool:
	for layer in ["dem", "sat", "osm", "landcover"]:
		for k in keys.get(layer, []):
			if not FileAccess.file_exists(str(k)):
				return false
	return true

## The History file: under dir_override in tests, never the real one.
static func store_path() -> String:
	if not history_override.is_empty():
		return history_override
	return dir_override.path_join("history.json") if dir_override != "" else PATH

func load_store() -> void:
	entries.clear()
	if not FileAccess.file_exists(store_path()):
		return
	var f := FileAccess.open(store_path(), FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	# Files written before HISTORY_VERSION are a bare array of entries.
	var items: Variant = parsed.get("entries") if parsed is Dictionary else parsed
	if not items is Array:
		# Unreadable: keep a copy, because the next save replaces the file.
		if AtomicFile.keep_backup(store_path()):
			push_warning("CacheStore: %s is unreadable, kept as %s.bak" % [store_path(), store_path()])
		return
	for item in items:
		if item is Dictionary:
			entries.append(item)

func save_store() -> void:
	if not AtomicFile.write_text(store_path(),
			JSON.stringify({"version": HISTORY_VERSION, "entries": entries})):
		push_warning("CacheStore: cannot write %s" % store_path())

## History entry. The retired cache_keys argument remains for callers
## using the older signature; keys are now computed from coordinates/tier.
func add_entry(place_name: String, lat: float, lon: float,
		_cache_keys: Dictionary = {}, quality_preset: int = RenderSettings.Preset.HIGH) -> void:
	var favourite := false
	var camera := {}
	for e in entries:
		if abs(float(e.get("lat", 999.0)) - lat) < 0.0001 and abs(float(e.get("lon", 999.0)) - lon) < 0.0001:
			favourite = favourite or bool(e.get("favourite", false))
			if camera.is_empty():
				camera = e.get("camera", {})
	entries = entries.filter(func(e: Dictionary) -> bool:
		return not (abs(float(e.get("lat", 999.0)) - lat) < 0.0001 \
			and abs(float(e.get("lon", 999.0)) - lon) < 0.0001))
	var entry := {
		"name": place_name, "lat": lat, "lon": lon,
		"cached": true, "timestamp": Time.get_unix_time_from_system(),
		"quality_preset": RenderSettings.clamp_preset(quality_preset), "favourite": favourite,
	}
	if not camera.is_empty():
		entry["camera"] = camera
	entries.push_front(entry)
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	save_store()

## Where the person was looking when they left the place (ViewLink
## state: yaw as bearing, pitch, eye position and height, zoom), kept
## on its History entry so reopening restores it. {} for none.
func camera_for(lat: float, lon: float) -> Dictionary:
	for e in entries:
		if abs(float(e.get("lat", 999.0)) - lat) < 0.0001 and abs(float(e.get("lon", 999.0)) - lon) < 0.0001:
			var cam: Variant = e.get("camera", {})
			return cam if cam is Dictionary else {}
	return {}

func set_camera(lat: float, lon: float, camera: Dictionary) -> void:
	for e in entries:
		if abs(float(e.get("lat", 999.0)) - lat) < 0.0001 and abs(float(e.get("lon", 999.0)) - lon) < 0.0001:
			e["camera"] = camera
			save_store()
			return

## Per-layer presence for a history entry (see keys_cached_status).
## Older entries without a saved tier use the High default.
func entry_cache_status(entry: Dictionary) -> Dictionary:
	return keys_cached_status(entry_cache_keys(entry))

## Preserve the exact coverage of entries saved before quality_preset was
## recorded. Rebase filenames so they still work after a data-directory move.
static func entry_cache_keys(entry: Dictionary) -> Dictionary:
	var saved: Variant = entry.get("cache_keys", {})
	if not entry.has("quality_preset") and saved is Dictionary and not saved.is_empty():
		var keys := {}
		for layer in saved:
			if saved[layer] is Array:
				keys[layer] = []
				for path in saved[layer]:
					var name := str(path).get_file()
					if not name.is_empty() and name != "." and name != "..":
						keys[layer].append(base_dir().path_join(name))
		return keys
	if not entry.has("lat") or not entry.has("lon"):
		return {}
	return place_cache_keys(float(entry["lat"]), float(entry["lon"]),
		int(entry.get("quality_preset", RenderSettings.Preset.HIGH)))

func clear() -> void:
	for e in entries:
		PlaceThumb.remove(float(e.get("lat", 0.0)), float(e.get("lon", 0.0)))
	entries.clear()
	save_store()

## History favourites pin to the top (HistoryScreen).
func set_favourite(entry: Dictionary, on: bool) -> void:
	entry["favourite"] = on
	save_store()

## Every data-cache path that may hold this place's downloads: the
## entry's own key set (legacy saved keys included) plus the key sets of
## all four presets, since satellite zoom/span and the OSM radius follow
## the preset the place was opened or warmed at. Deduplicated.
static func place_cache_keys_all_presets(lat: float, lon: float) -> Array:
	var seen := {}
	var out: Array = []
	for p in 4:
		var keys := place_cache_keys(lat, lon, p)
		for layer in keys:
			for k in keys[layer]:
				if not seen.has(str(k)):
					seen[str(k)] = true
					out.append(str(k))
	return out

static func _entry_data_paths(entry: Dictionary, layered: Dictionary = {}) -> Array:
	var seen := {}
	var out: Array = []
	var keys := layered if not layered.is_empty() else entry_cache_keys(entry)
	for layer in keys:
		for k in keys[layer]:
			if not seen.has(str(k)):
				seen[str(k)] = true
				out.append(str(k))
	if entry.has("lat") and entry.has("lon"):
		for k in place_cache_keys_all_presets(float(entry["lat"]), float(entry["lon"])):
			if not seen.has(k):
				seen[k] = true
				out.append(k)
	return out

## A cache file's size from the LRU index when it is loaded (the index
## is written on every note_written), else by opening the file. Sizing
## a whole History must not open hundreds of files per place.
static func _stored_bytes(path: String) -> int:
	if _lru_loaded:
		var row: Variant = _lru.get(_rel(path), null)
		if row is Dictionary:
			return int(row.get("bytes", 0))
	return _file_bytes(path)

## Bytes the entry's cached files take on the device: downloaded data
## plus its built worlds, so History and Settings agree on a place.
static func entry_bytes(entry: Dictionary) -> int:
	var total := 0
	for k in _entry_data_paths(entry):
		if FileAccess.file_exists(k):
			total += _stored_bytes(k)
	if entry.has("lat") and entry.has("lon"):
		total += WorldCache.bytes_for_place(float(entry["lat"]), float(entry["lon"]))
	return total

## Per-place inventory for Settings → Storage: one row per entry
## (largest first, then name), plus the bytes no entry can claim
## (map tiles, search/Wikipedia files, streamed or orphan worlds) as
## "other_bytes". Row sizes count shared tiles for each place that uses
## them, so rows may sum past the true total in "total_bytes".
static func place_cache_report(entries_in: Array) -> Dictionary:
	_ensure_lru()
	var by_place := WorldCache.bytes_by_place()
	var sizes := {}  # path -> bytes, for files counted once as attributed
	var rows: Array = []
	var attributed_worlds := {}
	var attributed_world_bytes := 0
	for e in entries_in:
		if not e is Dictionary:
			continue
		var entry: Dictionary = e
		var data_bytes := 0
		var layered := entry_cache_keys(entry)
		var paths := _entry_data_paths(entry, layered)
		for k in paths:
			if FileAccess.file_exists(k):
				if not sizes.has(k):
					sizes[k] = _stored_bytes(k)
				data_bytes += int(sizes[k])
		var world_bytes := 0
		if entry.has("lat") and entry.has("lon"):
			var pk := "%d_%d" % [quant(float(entry["lat"])), quant(float(entry["lon"]))]
			world_bytes = int(by_place.get(pk, 0))
			if not attributed_worlds.has(pk):
				attributed_worlds[pk] = true
				attributed_world_bytes += world_bytes
		# Cached state is judged at the entry's own preset (as History's
		# badge is), not against the all-preset union used for sizing:
		# a place fully downloaded at its tier is "full".
		var status := keys_cached_status(layered)
		var want := 0
		var have := 0
		for layer in status:
			want += int(status[layer]["total"])
			have += int(status[layer]["cached"])
		var state := "none"
		if data_bytes + world_bytes > 0:
			state = "full" if want > 0 and have >= want else "partial"
		rows.append({"entry": entry, "name": str(entry.get("name", "Place")),
			"lat": float(entry.get("lat", 0.0)), "lon": float(entry.get("lon", 0.0)),
			"data_bytes": data_bytes, "world_bytes": world_bytes,
			"bytes": data_bytes + world_bytes, "state": state})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["bytes"]) != int(b["bytes"]):
			return int(a["bytes"]) > int(b["bytes"])
		return str(a["name"]) < str(b["name"]))
	var unique_data := 0
	for k in sizes:
		unique_data += int(sizes[k])
	var data_total := data_bytes()
	var world_total := WorldCache.total_bytes()
	var other := maxi(0, data_total - unique_data) \
		+ maxi(0, world_total - attributed_world_bytes)
	return {"rows": rows, "other_bytes": other,
		"total_bytes": data_total + world_total}

## Clear one place's cache: deletes its downloaded data (all presets)
## and its built worlds, and nothing else. The History entry, its
## favourite, camera and thumbnail all stay (Settings → Storage).
## Tiles shared with a nearby place are deleted too, so that place
## downloads them again when it opens. Refuses while a world for this
## place is being saved or prefetched.
func clear_place_cache(entry: Dictionary) -> Dictionary:
	var res := {"ok": false, "busy": false, "files": 0, "bytes": 0,
		"data_bytes": 0, "world_bytes": 0}
	if not entry.has("lat") or not entry.has("lon"):
		return res
	var lat := float(entry["lat"])
	var lon := float(entry["lon"])
	if WorldCache.is_place_busy(lat, lon):
		res["busy"] = true
		return res
	_ensure_lru()
	var files := 0
	var freed := 0
	for k in _entry_data_paths(entry):
		if FileAccess.file_exists(k):
			var size := _stored_bytes(k)
			DirAccess.remove_absolute(k)
			var rel := _rel(k)
			_lru.erase(rel)
			if _scan_task >= 0:
				_cleared[rel] = true
			files += 1
			freed += size
	res["data_bytes"] = freed
	var worlds := WorldCache.remove_for_place(lat, lon)
	files += int(worlds.get("files", 0))
	freed += int(worlds.get("bytes", 0))
	res["world_bytes"] = int(worlds.get("bytes", 0))
	res["files"] = files
	res["bytes"] = freed
	res["ok"] = true
	_tracked_bytes = _index_bytes()
	_queue_lru_save()
	return res

## Remove from cache: clears the place's cache (clear_place_cache),
## deletes its thumbnail and drops it from History. When the place is
## still being saved the clear is refused, so nothing is dropped and
## the result says busy — the caller can say so instead of claiming
## the place was removed while its files remain.
func remove_place(entry: Dictionary) -> Dictionary:
	var res := clear_place_cache(entry)
	if bool(res.get("busy", false)):
		return res
	PlaceThumb.remove(float(entry.get("lat", 0.0)), float(entry.get("lon", 0.0)))
	entries.erase(entry)
	save_store()
	return res

# --- LRU accounting + per-layer invalidation (all static) ---
#
# Work that grows with the number of cache files runs on worker tasks: a
# 20 GB cache holds ~250k files, one disk scan of them takes seconds and
# one JSON pass of the index ~0.4 s. The index itself lives in memory and
# is only touched on the main thread; tasks get a copy.

static func _lru_path() -> String:
	return base_dir() + "/" + LRU_FILE

## Starts reading the index on a worker (Main calls it at startup), so
## the first cache hit does not parse it on the main thread.
static func preload_index() -> void:
	if _lru_loaded or _load_task >= 0:
		return
	var path := _lru_path()
	_hook_exit()
	_load_task = _spawn(func() -> void:
		_loaded = JSON.parse_string(FileAccess.get_file_as_string(path)) \
			if FileAccess.file_exists(path) else null
		_index_loaded.call_deferred())

static func _index_loaded() -> void:
	if _load_task >= 0 and not _lru_loaded:
		_ensure_lru()
	var waiters := _index_waiters
	_index_waiters = []
	for w in waiters:
		w.call()

## Whether the index is in memory. Screens that only need sizes check
## this before place_cache_report, whose _ensure_lru would otherwise
## join the preload parse on the main thread (see ensure_index_async).
static func index_ready() -> bool:
	return _lru_loaded

## Calls `done` when the index is in memory, without ever joining the
## preload on the main thread: at once when it already is, else when
## preload_index's deferred completion lands. For a screen opening in
## the first moments after launch, which builds without sizes and
## refreshes itself from `done`.
static func ensure_index_async(done: Callable) -> void:
	if _lru_loaded:
		done.call()
		return
	if not _index_waiters.has(done):
		_index_waiters.append(done)
	preload_index()

## The index, loaded: waits for preload_index's task if it is still
## parsing, else reads it here.
static func _ensure_lru() -> void:
	if _lru_loaded:
		return
	if _load_task < 0:
		preload_index()
	_lru_loaded = true
	WorkerThreadPool.wait_for_task_completion(_load_task)
	_load_task = -1
	_lru = _loaded if _loaded is Dictionary else {}
	_loaded = null

static func _write_index(path: String, index: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(index))

## Hits and writes save the index at most every SAVE_EVERY_S, on a
## worker. The queued save keeps the index path it was queued for, so a
## test switching dir_override cannot land it in the other directory.
static func _queue_lru_save() -> void:
	var path := _lru_path()
	if _lru_pending != "" and _lru_pending != path:
		flush_lru()
	_lru_pending = path
	if _save_armed:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		flush_lru()
		return
	_save_armed = true
	tree.create_timer(SAVE_EVERY_S, true, false, true).timeout.connect(func() -> void:
		_save_armed = false
		flush_lru())

## Starts writing a queued index save now (Main calls it on quit, then
## waits while busy()). A write still running is joined first.
static func flush_lru() -> void:
	if _lru_pending == "":
		return
	_join_save()
	var path := _lru_pending
	var index := _lru.duplicate()
	_lru_pending = ""
	_hook_exit()
	_save_task = _spawn(func() -> void: _write_index(path, index))

static func _join_save() -> void:
	if _save_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_save_task)
		_save_task = -1

## An index read, write, scan or deletion is still pending or running.
## Reads the tasks' own done flags: asking the pool about an ID that was
## already joined fails with "Invalid Task ID" (seen at quit).
static func busy() -> bool:
	_working = _working.filter(func(box: Array) -> bool: return not box[0])
	return not _working.is_empty() or _lru_pending != ""

## Starts `work` on a worker (from the main thread) and tracks it for busy().
static func _spawn(work: Callable) -> int:
	var box := [false]
	_working.append(box)
	return WorkerThreadPool.add_task(func() -> void:
		work.call()
		box[0] = true)

## Joins every task; the store's teardown backstop (Main waits on busy()
## first, frame by frame, so this rarely blocks).
## A scan joined here still lands through its deferred _scan_done.
static func finish() -> void:
	_join_save()
	for t in _trash_tasks:
		WorkerThreadPool.wait_for_task_completion(t)
	_trash_tasks.clear()
	if _scan_task >= 0 and not _scan_joined:
		WorkerThreadPool.wait_for_task_completion(_scan_task)
		_scan_joined = true
	if _load_task >= 0 and not _lru_loaded:
		_ensure_lru()

## The tasks must not outlive the store (Main's is freed at quit).
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		finish()

## Nor the engine: a scan started without a store (Settings, tests)
## still runs when the tree quits. The root leaves the tree first.
static func _hook_exit() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if _exit_hooked or tree == null:
		return
	_exit_hooked = true
	tree.root.tree_exiting.connect(func() -> void:
		stop_scans = true
		finish())

## Drop the in-memory LRU state (used after clear_cache deletes the
## directory out from under it, and by tests for a clean slate).
static func reset_lru() -> void:
	finish()
	_scan_gen += 1
	_scan_task = -1
	_scan_joined = false
	_lru = {}
	_lru_loaded = false
	_loaded = null
	_load_task = -1
	_index_waiters.clear()
	_lru_pending = ""
	_tracked_bytes = -1
	_reconciled = false
	_touched.clear()
	_cleared.clear()
	_scan_again = false

static func _rel(path: String) -> String:
	return _rel_to(path, base_dir())

static func _rel_to(path: String, base: String) -> String:
	if path.begins_with(base + "/"):
		return path.substr(base.length() + 1)
	return path.get_file()

static func _file_bytes(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return int(f.get_length()) if f != null else 0

## Record a cache hit. atime_override is a test hook (default: now);
## `bytes` spares reopening a file the caller has just read.
static func note_read(path: String, atime_override: float = -1.0, bytes: int = -1) -> void:
	_ensure_lru()
	var now := Time.get_unix_time_from_system() \
		if atime_override < 0.0 else atime_override
	var rel := _rel(path)
	_lru[rel] = {"bytes": bytes if bytes >= 0 else _file_bytes(path), "atime": now}
	_touch(rel)
	_queue_lru_save()

## Record a cache write. Nothing is evicted; the first write in a
## session also reconciles the index against the files on disk.
## atime_override is a test hook (default: now).
static func note_written(path: String, atime_override: float = -1.0) -> void:
	_ensure_lru()
	if _tracked_bytes < 0:
		_tracked_bytes = _index_bytes()
	var now := Time.get_unix_time_from_system() \
		if atime_override < 0.0 else atime_override
	var rel := _rel(path)
	var old := int((_lru.get(rel, {}) as Dictionary).get("bytes", 0))
	var size := _file_bytes(path)
	_lru[rel] = {"bytes": size, "atime": now}
	_touch(rel)
	_tracked_bytes += size - old
	_queue_lru_save()
	if not _reconciled:
		reconcile_index()

## A row noted while a scan works on a copy wins over the scan's.
static func _touch(rel: String) -> void:
	if _scan_task >= 0:
		_touched[rel] = true

static func _index_bytes() -> int:
	var total := 0
	for rel in _lru:
		total += int((_lru[rel] as Dictionary).get("bytes", 0))
	return total

## Bytes downloaded data holds, from the index, no disk scan: exact once
## the session's first scan has also counted the files the index does
## not track (map tiles). Backs the Settings storage readout.
static func data_bytes() -> int:
	_ensure_lru()
	if _tracked_bytes < 0:
		_tracked_bytes = _index_bytes()
	if not _reconciled:
		reconcile_index()
	return _tracked_bytes

## Every cache file except the LRU index itself: {"path", "rel",
## "bytes", "atime"} (atime from the index, else the file mtime).
## Synchronous: only for invalidate_layer and cache_stats.
static func _scan_files() -> Array:
	_ensure_lru()
	var out: Array = []
	_scan_dir(base_dir(), base_dir(), _lru_path(), _lru, out)
	return out

## Pure (no static state), so worker tasks can run it on a copy.
static func _scan_dir(dir_path: String, base: String, lru_path: String,
		index: Dictionary, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path + "/" + name
		if stop_scans:
			break
		if dir.current_is_dir():
			if name != "." and name != "..":
				_scan_dir(full, base, lru_path, index, out)
		elif full != lru_path:
			var rel := _rel_to(full, base)
			var row := index.get(rel, {}) as Dictionary
			var atime := float(row.get("atime",
				FileAccess.get_modified_time(full)))
			# A stat, not an open: this runs over every cache file.
			out.append({"path": full, "rel": rel,
				"bytes": maxi(FileAccess.get_size(full), 0), "atime": atime})
		name = dir.get_next()
	dir.list_dir_end()

## Reconcile the index against the files on disk: count what the index
## does not track (map tiles) and drop index rows for files that are
## gone. Never deletes a cache file — there is no size limit. The scan
## runs on a worker; the session's first accounting call starts it.
static func reconcile_index() -> void:
	_ensure_lru()
	if _tracked_bytes < 0:
		_tracked_bytes = _index_bytes()
	if not _reconciled:
		_start_scan()

static func _start_scan() -> void:
	# Never once the tree is quitting: a scan started by a write during
	# teardown ran GDScript on a worker while the engine shut down.
	if stop_scans:
		return
	if _scan_task >= 0:
		_scan_again = true
		return
	_touched.clear()
	_cleared.clear()
	_scan_gen += 1
	var gen := _scan_gen
	var base := base_dir()
	var lru_path := _lru_path()
	var index := _lru.duplicate()
	_hook_exit()
	_scan_task = _spawn(func() -> void:
		var r := _scan_and_count(base, lru_path, index)
		_scan_done.call_deferred(gen, r))

## On a worker: the whole directory, counted, nothing removed.
## {"rows": rel -> {bytes, atime} for every file found, "total"}.
static func _scan_and_count(base: String, lru_path: String, index: Dictionary) -> Dictionary:
	var files: Array = []
	_scan_dir(base, base, lru_path, index, files)
	if stop_scans:
		return {"stopped": true}
	var total := 0
	var rows := {}
	for e in files:
		total += int(e["bytes"])
		rows[str(e["rel"])] = {"bytes": int(e["bytes"]), "atime": float(e["atime"])}
	return {"rows": rows, "total": total}

static func _scan_done(gen: int, r: Dictionary) -> void:
	if gen != _scan_gen or _scan_task < 0:
		return  # reset (or a newer scan) since it started
	if not _scan_joined:
		WorkerThreadPool.wait_for_task_completion(_scan_task)
	_scan_joined = false
	_scan_task = -1
	if r.has("stopped"):
		_touched.clear()
		_cleared.clear()
		return
	var rows: Dictionary = r["rows"]
	var total := int(r["total"])
	for rel in _cleared:
		# Deleted by a per-place clear while the scan ran: the scan's copy
		# still lists them, so drop them again instead of resurrecting.
		if rows.has(rel):
			total -= int((rows[rel] as Dictionary).get("bytes", 0))
			rows.erase(rel)
	_cleared.clear()
	for rel in _touched:
		if _lru.has(rel):
			total += int(_lru[rel]["bytes"]) - int((rows.get(rel, {}) as Dictionary).get("bytes", 0))
			rows[rel] = _lru[rel]
	_touched.clear()
	_lru = rows
	_tracked_bytes = total
	_reconciled = true
	_queue_lru_save()
	if _scan_again:
		_scan_again = false

## Moves a directory aside (one rename) and deletes it on a worker:
## clearing a 20 GB cache removes ~250k files. Trash an earlier quit left
## half-deleted goes in the same pass.
static func discard_dir(path: String) -> void:
	var full := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(full):
		DirAccess.rename_absolute(full, "%s%s%d" % [full, TRASH_MARK, Time.get_ticks_usec()])
	var parent := full.get_base_dir()
	_hook_exit()
	_trash_tasks.append(_spawn(func() -> void:
		for d in DirAccess.get_directories_at(parent):
			if d.contains(TRASH_MARK):
				_remove_tree(parent.path_join(d))))

static func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for d in dir.get_directories():
		_remove_tree(path.path_join(d))
	for f in dir.get_files():
		dir.remove(f)
	DirAccess.remove_absolute(path)

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
	_queue_lru_save()
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
