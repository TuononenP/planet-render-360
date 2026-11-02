class_name OfflineDownloader
extends Node

## "Download for offline": warms every on-device cache for a place
## (DEM + far DEM, OSM features, satellite mosaic) without rendering
## it, so opening it later works with networking disabled. The
## fetchers already write user://cache under v2 keys; this just drives
## them all and reports progress. The warmed set matches
## CacheStore.place_cache_keys(lat, lon, preset): satellite zoom/span
## and the OSM ring follow the preset maps, exactly what the pipeline
## fetches at that preset (the pipeline's own OSM preset plumbing is
## T7.4 — until then it fetches the High ring whatever the preset, so
## a non-High warmup's ring may differ from what the pipeline reads;
## the detailed phase, the required one, is preset-independent).
## Map-picker tiles cache themselves as the user pans; they are not
## bulk-prefetched (tile usage policy).

signal progress(done: int, total: int)
signal finished(ok_count: int, total: int)

const JOBS := 4  # detailed DEM, far DEM, OSM, satellite

var _done := 0
var _ok := 0
var _running := false

func is_running() -> bool:
	return _running

func download(lat: float, lon: float, quality_preset: int = 2) -> void:
	if _running:
		return
	_running = true
	_done = 0
	_ok = 0
	var dem := DemFetcher.new()
	add_child(dem)
	dem.succeeded.connect(func(_h: PackedFloat32Array, _g: int) -> void: _job(true))
	dem.failed.connect(func(_r: String) -> void: _job(false))
	dem.fetch(lat, lon, RenderSettings.grid_size_for(quality_preset))
	var far := DemFetcher.new()
	add_child(far)
	far.succeeded.connect(func(_h: PackedFloat32Array, _g: int) -> void: _job(true))
	far.failed.connect(func(_r: String) -> void: _job(false))
	far.fetch_far(lat, lon, RenderSettings.far_grid_size_for(quality_preset))
	var osm := OsmFetcher.new()
	add_child(osm)
	osm.succeeded.connect(func(_b: Array, _r: Array, _l: Array, _lm: Array) -> void: _job(true))
	osm.failed.connect(func(_r: String) -> void: _job(false))
	osm.fetch(lat, lon, quality_preset)
	var sat := SatelliteFetcher.new()
	add_child(sat)
	sat.succeeded.connect(func(_t: Texture2D, _i: Image, _o: Vector2, _z: int) -> void: _job(true))
	sat.failed.connect(func(_r: String) -> void: _job(false))
	if quality_preset > RenderSettings.Preset.FAST:
		sat.fetch(lat, lon, RenderSettings.satellite_zoom_for(quality_preset),
			RenderSettings.satellite_span_for(quality_preset, lat))
	else:
		# Fast skips satellite (pipeline parity): count the job done.
		_job(true)
		sat.queue_free()

func _job(ok: bool) -> void:
	if ok:
		_ok += 1
	_done += 1
	progress.emit(_done, JOBS)
	if _done >= JOBS:
		_running = false
		finished.emit(_ok, JOBS)
		for child in get_children():
			child.queue_free()

## Total bytes held in the offline cache (DEM/OSM/satellite/tiles).
## Downloaded data plus built worlds (WorldCache, user://worlds), from
## their running totals: walking a large cache would hold the main
## thread for seconds.
static func cache_size_bytes() -> int:
	return CacheStore.data_bytes() + WorldCache.total_bytes()

## Delete the whole offline cache (history entries stay; their
## places simply re-download on next open). Resets the LRU index too.
## The folders are moved aside at once and deleted on a worker.
static func clear_cache() -> void:
	CacheStore.reset_lru()
	CacheStore.discard_dir("user://cache")
	CacheStore.discard_dir("user://worlds")
	DirAccess.make_dir_recursive_absolute("user://cache")
	WorldCache.enforce_budget()  # recount the now-empty worlds
