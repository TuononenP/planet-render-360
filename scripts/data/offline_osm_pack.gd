class_name OfflineOsmPack
extends Node

## Warm and verify the same five OSM layers as a bundled preset for any
## selected coordinate. Requests run serially to respect public servers.
signal finished(complete: bool, missing: Array)

const ATTEMPT_TIMEOUT := 40.0
## Mirror pairs by name, so reordering OsmFetcher.ENDPOINTS cannot change them.
## z.overpass-api.de refuses connections (2026-11-11), so the pairs leave
## it out and each starts on a different instance.
const PRIMARY_HOSTS: Array[String] = ["//overpass-api.de", "private.coffee"]
const ALTERNATE_HOSTS: Array[String] = ["private.coffee", "//overpass-api.de"]
## A cooldown this short is waited out; a longer one lets the layer fail.
const COOLDOWN_WAIT_S := 60.0
var request_override: OverpassRequest  # test transport
var _request: OverpassRequest
var _jobs: Array[Dictionary] = []
var _missing: Array[String] = []
var _index := 0
var _running := false
var _retry_round := 0
## Once the first two mirrors have failed a layer, later layers start on the
## other two, so one silent pair cannot use up the whole save budget.
var _primary_failed := false
## Bumped by start and cancel, so a verification still running stops there.
var _run_id := 0
var _verify_task := -1

func _ready() -> void:
	_request = request_override if request_override != null else OverpassRequest.new(ATTEMPT_TIMEOUT)
	_request.max_attempts = 2
	add_child(_request)
	_request.answered.connect(_answered)
	_request.exhausted.connect(_exhausted)

## The validation task must not outlive the node it reports back to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_verify()

func _join_verify() -> void:
	if _verify_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_verify_task)
		_verify_task = -1

func is_running() -> bool:
	return _running

func cancel() -> void:
	_running = false
	_run_id += 1
	if _request != null:
		_request.cancel()

func start(lat: float, lon: float) -> void:
	cancel()
	DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())
	_missing.clear()
	_index = 0
	_retry_round = 0
	_primary_failed = false
	_jobs = [
		_job("detailed", OsmQuery.QUERY_VERSION, CacheStore.osm_path(lat, lon, 1200),
			OsmQuery.build_query(lat, lon, 1200), OsmFetcher._detailed_check(lat, lon)),
		_job("ring1600", OsmQuery.RING_VERSION, CacheStore.osm_ring_path(lat, lon, 1600),
			OsmQuery.build_ring_query(lat, lon, 1600), _check_optional),
		_job("ring2500", OsmQuery.RING_VERSION, CacheStore.osm_ring_path(lat, lon, 2500),
			OsmQuery.build_ring_query(lat, lon, 2500), _check_optional),
		_job("poi", OsmQuery.POI_VERSION, CacheStore.osm_poi_path(lat, lon),
			OsmQuery.build_poi_query(lat, lon), _check_optional),
		_job("far", FarCityFetcher.QUERY_VERSION, FarCityFetcher.cache_path(lat, lon),
			FarCityFetcher.build_query(lat, lon), _check_optional),
	]
	for job in _jobs:
		job["snapshot"] = BundledOsm.entry_for(lat, lon, job["layer"], job["version"])
	_running = true
	_next.call_deferred()

static func _job(layer: String, version: int, path: String, query: String, check: Callable) -> Dictionary:
	return {"layer": layer, "version": version, "path": path, "query": query, "check": check}

static func _check_optional(text: String) -> String:
	return "" if OsmFetcher._payload_usable(text) else "Invalid or incomplete OSM response"

static func _check(job: Dictionary, text: String) -> bool:
	if text == "" or not OsmFetcher._payload_usable(text):
		return false
	if job["layer"] == "detailed" and not OsmQuery.is_current(text):
		return false
	return str((job["check"] as Callable).call(text)) == ""

## Cheap fingerprint of a cache file, so an unchanged file is validated once.
## Empty when the file is missing (e.g. evicted).
static func _stamp(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return "%d:%d" % [FileAccess.get_modified_time(path), f.get_length()]

## Validation decompresses, hashes and parses up to tens of megabytes, so a
## layer is fully checked once: a bundled snapshot never changes, and a cache
## file is rechecked only when its fingerprint changes. Safe on a worker: it
## must not call CacheStore.note_read, whose index is main-thread only.
static func _available(job: Dictionary) -> bool:
	var stamp := _stamp(job["path"])
	if stamp != "" and job.get("verified_stamp", "") == stamp:
		return true
	if stamp != "" and _check(job, FileAccess.get_file_as_string(job["path"])):
		job["verified_stamp"] = stamp
		return true
	if job.get("bundled_ok", false):
		return true
	if BundledOsm.read(job["snapshot"]) != "":
		job["bundled_ok"] = true
		return true
	return false

## _available on a worker thread, keeping frames running during the save.
func _verified(job: Dictionary) -> bool:
	_join_verify()
	var box := {}
	var task := WorkerThreadPool.add_task(func() -> void: box["ok"] = _available(job))
	_verify_task = task
	while _verify_task == task and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _verify_task == task:
		_join_verify()
	# A saved layer counts as used, so it is not the first to be evicted.
	if job.get("verified_stamp", "") != "":
		CacheStore.note_read(job["path"])
	return bool(box.get("ok", false))

func missing_layers() -> Array[String]:
	_join_verify()
	var missing: Array[String] = []
	for job in _jobs:
		if not _available(job):
			missing.append(str(job["layer"]))
	return missing

func _next() -> void:
	if not _running:
		return
	var run := _run_id
	while _index < _jobs.size():
		var usable: bool = await _verified(_jobs[_index])
		if run != _run_id:
			return
		if not usable:
			break
		_index += 1
	if _index >= _jobs.size():
		# Cache eviction can occur while fetching later layers.
		_missing = missing_layers()
		if not _missing.is_empty() and _retry_round == 0:
			_retry_round = 1
			_index = 0
			_next.call_deferred()
			return
		_running = false
		finished.emit(_missing.is_empty(), _missing.duplicate())
		return
	var job := _jobs[_index]
	var validate := func(text: String) -> String:
		return "" if _check(job, text) else "Invalid or incomplete OSM response"
	var alternates := _retry_round > 0 or _primary_failed
	var endpoints := OsmFetcher.endpoint_order(ALTERNATE_HOSTS if alternates else PRIMARY_HOSTS).slice(0, 2)
	# With both mirrors asking for a pause, failing now would burn every
	# remaining layer and the retry round within a second.
	var pause := OverpassRequest.cooldown_left(endpoints)
	if pause > 0.0 and pause <= COOLDOWN_WAIT_S:
		await get_tree().create_timer(pause + 0.1).timeout
		if run != _run_id:
			return
	_request.run("data=" + str(job["query"]).uri_encode(), validate, endpoints)

func _answered(text: String) -> void:
	if not _running:
		return
	var job := _jobs[_index]
	# OverpassRequest has just validated this text on a worker. If the write
	# failed, whatever older file is still there has not been validated.
	if OsmFetcher._write_cache(job["path"], text):
		job["verified_stamp"] = _stamp(job["path"])
	else:
		job.erase("verified_stamp")
	_index += 1
	_next.call_deferred()

func _exhausted(_reason: String, _attempts: int) -> void:
	if not _running:
		return
	_missing.append(str(_jobs[_index]["layer"]))
	_primary_failed = true
	_index += 1
	_next.call_deferred()
