extends SceneTree

class FakeRequest extends OverpassRequest:
	var replies: Array[String] = []
	var requests := 0
	var bodies: Array[String] = []
	var endpoint_sets: Array = []
	func run(body: String, validate: Callable, endpoints: Array[String]) -> void:
		bodies.append(body)
		endpoint_sets.append(endpoints)
		var payload := replies[requests]
		requests += 1
		if str(validate.call(payload)) == "":
			answered.emit.call_deferred(payload)
		else:
			exhausted.emit.call_deferred("fixture error", 1)

const LAT := 10.0
const LON := 20.0
const EMPTY := '{"elements": []}'
const BAD := '{"elements": [], "remark":"runtime error"}'
const DETAIL := '''{"elements":[{"type":"pr360_q12"},
 {"type":"way","id":1,"tags":{"building":"yes"},"geometry":[
 {"lat":10.0,"lon":20.0},{"lat":10.0,"lon":20.0001},
 {"lat":10.0001,"lon":20.0001},{"lat":10.0,"lon":20.0}]}]}'''

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var errors: Array[String] = []
	var dir := "user://offline-osm-pack-test-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	CacheStore.eviction_suppressed = true
	await _case([DETAIL, EMPTY, EMPTY, EMPTY, EMPTY], true, errors)
	await _offline_reopen(errors)
	await _bundled_case(errors)
	for path in [CacheStore.osm_path(LAT, LON, 1200), CacheStore.osm_ring_path(LAT, LON, 1600),
			CacheStore.osm_ring_path(LAT, LON, 2500), CacheStore.osm_poi_path(LAT, LON), FarCityFetcher.cache_path(LAT, LON)]:
		if not FileAccess.file_exists(path):
			errors.append("complete pack did not write %s" % path)
		DirAccess.remove_absolute(path)
	await _case([DETAIL, EMPTY, BAD, EMPTY, EMPTY, BAD], false, errors)
	if FileAccess.file_exists(CacheStore.osm_ring_path(LAT, LON, 2500)):
		errors.append("invalid response was cached")
	for path in [CacheStore.osm_path(LAT, LON, 1200), CacheStore.osm_ring_path(LAT, LON, 1600),
			CacheStore.osm_poi_path(LAT, LON), FarCityFetcher.cache_path(LAT, LON)]:
		DirAccess.remove_absolute(path)
	await _case([DETAIL, EMPTY, BAD, EMPTY, EMPTY, EMPTY], true, errors, 6)
	CacheStore.finish()
	for name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(name))
	DirAccess.remove_absolute(dir)
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	if errors.is_empty():
		print("OFFLINE OSM PACK OK: complete layers, partial failures, no invalid cache")
		quit(0)
	else:
		for error in errors:
			printerr("OFFLINE OSM PACK FAIL: ", error)
		quit(1)

func _case(replies: Array[String], expected: bool, errors: Array[String], expected_requests := 5) -> void:
	var pack := OfflineOsmPack.new()
	var fake := FakeRequest.new()
	fake.replies = replies
	pack.request_override = fake
	root.add_child(pack)
	var result: Array = []
	pack.finished.connect(func(ok: bool, missing: Array) -> void: result.append([ok, missing]))
	pack.start(LAT, LON)
	var deadline := Time.get_ticks_msec() + 30000
	while result.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	if result.is_empty() or bool(result[0][0]) != expected:
		errors.append("pack result was %s, expected %s" % [result, expected])
	if not expected:
		expected_requests = 6
	if fake.requests != expected_requests:
		errors.append("expected %d requests, got %d" % [expected_requests, fake.requests])
	if expected_requests == 6 and (fake.bodies[2] != fake.bodies[5] or fake.endpoint_sets[0] == fake.endpoint_sets[5]):
		errors.append("retry should target only the failed layer using alternate endpoints")
	if expected_requests == 6 and fake.endpoint_sets[3] != fake.endpoint_sets[5]:
		errors.append("layers after a failure should start on the alternate endpoints")
	if not expected and not result.is_empty() and not result[0][1].has("ring2500"):
		errors.append("failed layer not reported")
	if not expected:
		var path := CacheStore.osm_ring_path(LAT, LON, 2500)
		OsmFetcher._write_cache(path, EMPTY)
		if not pack.missing_layers().is_empty():
			errors.append("a subsequently recovered layer should no longer be missing")
		DirAccess.remove_absolute(path)
	pack.queue_free()
	await process_frame

func _offline_reopen(errors: Array[String]) -> void:
	var fetcher := OsmFetcher.new()
	root.add_child(fetcher)
	fetcher.offline_mode = true
	var got: Array = []
	fetcher.succeeded.connect(func(b: Array, _r: Array, _l: Array, _lm: Array) -> void: got.append(b.size()))
	fetcher.fetch(LAT, LON, 3)
	var deadline := Time.get_ticks_msec() + 10000
	while got.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	if got.is_empty() or got[0] != 1 or fetcher._ring_text == "" or fetcher._poi_text == "":
		errors.append("offline reopen did not use downloaded detail, ring and POIs")
	fetcher.queue_free()
	var far := FarCityFetcher.new()
	root.add_child(far)
	far.offline_mode = true
	var done: Array = []
	far.finished.connect(func(_land: Array, _towers: Array) -> void: done.append(true))
	far.fetch(LAT, LON)
	deadline = Time.get_ticks_msec() + 10000
	while done.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	if done.is_empty() or not bool(far.timings.get("cached", false)):
		errors.append("offline reopen did not use downloaded far-city data")
	far.queue_free()
	await process_frame

func _bundled_case(errors: Array[String]) -> void:
	var pack := OfflineOsmPack.new()
	var fake := FakeRequest.new()
	pack.request_override = fake
	root.add_child(pack)
	var result: Array = []
	pack.finished.connect(func(ok: bool, _missing: Array) -> void: result.append(ok))
	pack.start(40.7060, -74.0040)
	var deadline := Time.get_ticks_msec() + 30000
	while result.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	if result != [true] or fake.requests != 0:
		errors.append("complete bundled layers should not trigger requests")
	pack.queue_free()
	await process_frame
