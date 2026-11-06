class_name OfflineOsmPack
extends Node

## Warm and verify the same five OSM layers as a bundled preset for any
## selected coordinate. Requests run serially to respect public servers.
signal finished(complete: bool, missing: Array)

const ATTEMPT_TIMEOUT := 40.0
var request_override: OverpassRequest  # test transport
var _request: OverpassRequest
var _jobs: Array[Dictionary] = []
var _missing: Array[String] = []
var _index := 0
var _running := false
var _retry_round := 0

func _ready() -> void:
	_request = request_override if request_override != null else OverpassRequest.new(ATTEMPT_TIMEOUT)
	add_child(_request)
	_request.answered.connect(_answered)
	_request.exhausted.connect(_exhausted)

func is_running() -> bool:
	return _running

func cancel() -> void:
	_running = false
	if _request != null:
		_request.cancel()

func start(lat: float, lon: float) -> void:
	cancel()
	DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())
	_missing.clear()
	_index = 0
	_retry_round = 0
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
## file is rechecked only when its fingerprint changes.
func _available(job: Dictionary) -> bool:
	var stamp := _stamp(job["path"])
	if stamp != "" and job.get("verified_stamp", "") == stamp:
		return true
	if stamp != "" and _check(job, OsmFetcher._read_cache(job["path"])):
		job["verified_stamp"] = stamp
		return true
	if job.get("bundled_ok", false):
		return true
	if BundledOsm.read(job["snapshot"]) != "":
		job["bundled_ok"] = true
		return true
	return false

func missing_layers() -> Array[String]:
	var missing: Array[String] = []
	for job in _jobs:
		if not _available(job):
			missing.append(str(job["layer"]))
	return missing

func _next() -> void:
	if not _running:
		return
	while _index < _jobs.size() and _available(_jobs[_index]):
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
	var endpoints := OsmFetcher.ENDPOINTS.slice(0, 2) if _retry_round == 0 else OsmFetcher.ENDPOINTS.slice(2, 4)
	_request.run("data=" + str(job["query"]).uri_encode(), validate, endpoints)

func _answered(text: String) -> void:
	if not _running:
		return
	var job := _jobs[_index]
	OsmFetcher._write_cache(job["path"], text)
	_index += 1
	_next.call_deferred()

func _exhausted(_reason: String, _attempts: int) -> void:
	if not _running:
		return
	_missing.append(str(_jobs[_index]["layer"]))
	_index += 1
	_next.call_deferred()
