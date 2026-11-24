class_name OsmAerowayLayer
extends Node

## Best-effort auxiliary OSM layer for aeroways (runways, taxiways, aprons,
## parking positions, gates, helipads, aerodromes). Kept in its own node so
## OsmFetcher stays under the 1,000-line class limit and existing detailed
## OSM caches are never invalidated.

signal settled

var text := ""
var pending := false
var _started := false
var _cache := ""
var _lat := 0.0
var _lon := 0.0
var _radius := 1200
var _postpass: PostpassRequest
var _overpass: OverpassRequest

func _ready() -> void:
	_postpass = PostpassRequest.new(PostpassFallback.LAYER_TIMEOUT_S)
	add_child(_postpass)
	_postpass.answered.connect(_on_answered)
	_postpass.failed.connect(_on_postpass_failed)
	_overpass = OverpassRequest.new(OsmFetcher.ATTEMPT_TIMEOUT)
	add_child(_overpass)
	_overpass.answered.connect(_on_answered)
	_overpass.exhausted.connect(_on_overpass_exhausted)

func reset(lat: float, lon: float, radius_m: int) -> void:
	cancel()
	_lat = lat
	_lon = lon
	_radius = radius_m
	text = ""
	_started = false
	pending = false
	_cache = CacheStore.osm_aeroway_path(lat, lon)

func cancel() -> void:
	pending = false
	if _postpass != null:
		_postpass.cancel()
	if _overpass != null:
		_overpass.cancel()

func start_if_needed(offline: bool, already_settled: bool) -> void:
	if _started:
		return
	_started = true
	text = OsmFetcher._read_cache(_cache)
	if text != "" and not OsmFetcher._payload_usable(text):
		text = ""
	if text == "" and not offline and not already_settled:
		pending = true
		_postpass.run(PostpassFallback.build_aeroway_body(_lat, _lon, _radius))

func _on_answered(body: String) -> void:
	text = body
	OsmFetcher._write_cache(_cache, body)
	pending = false
	settled.emit()

func _on_postpass_failed(why: String) -> void:
	if not pending:
		return
	var eps := OsmFetcher.ring_endpoints().slice(0, 1)
	if eps.is_empty():
		_give_up(why)
	else:
		_overpass.run("data=" + OsmQuery.build_aeroway_query(_lat, _lon, _radius).uri_encode(),
			OsmFetcher._check_ring, eps)

func _on_overpass_exhausted(reason: String, _attempts: int) -> void:
	_give_up(reason)

func _give_up(reason: String) -> void:
	print("OsmFetcher: aeroways unavailable (%s); continuing without them" % reason)
	pending = false
	settled.emit()
