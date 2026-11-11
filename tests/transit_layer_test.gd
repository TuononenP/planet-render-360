extends SceneTree

## The bundled transit layer (tools/prepare_transit_layer.py): tram and bus
## stops, station nodes and train platforms that the detailed snapshots lack.
## Cities that have no layer, and live answers, must load as before.

var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _run() -> void:
	_merge_checks()
	_layer_checks()
	await _offline_checks()
	print("transit_layer_test: %d failure(s)" % failures)
	quit(1 if failures else 0)

## A detailed-like payload without stops plus a transit payload gives every
## stop list, and an element both carry is counted once.
func _merge_checks() -> void:
	var lat := 60.168
	var lon := 24.953
	var detailed := JSON.stringify({"elements": [
		{"type": "node", "id": 1, "lat": lat, "lon": lon, "tags": {"highway": "bus_stop", "name": "Both"}},
		{"type": "way", "id": 9, "geometry": [{"lat": lat, "lon": lon}, {"lat": lat, "lon": lon + 0.0001}],
			"tags": {"railway": "platform"}}]})
	var transit := JSON.stringify({"elements": [
		{"type": "node", "id": 1, "lat": lat, "lon": lon, "tags": {"highway": "bus_stop", "name": "Both"}},
		{"type": "node", "id": 2, "lat": lat + 0.0001, "lon": lon, "tags": {"highway": "bus_stop"}},
		{"type": "node", "id": 3, "lat": lat, "lon": lon + 0.0002, "tags": {"railway": "tram_stop"}},
		{"type": "node", "id": 4, "lat": lat, "lon": lon + 0.0003, "tags": {"public_transport": "stop_position", "tram": "yes"}},
		{"type": "node", "id": 5, "lat": lat, "lon": lon + 0.0004, "tags": {"railway": "station", "name": "Central"}},
		{"type": "way", "id": 9, "geometry": [{"lat": lat, "lon": lon}, {"lat": lat, "lon": lon + 0.0001}],
			"tags": {"railway": "platform"}},
		{"type": "way", "id": 10, "geometry": [{"lat": lat, "lon": lon}, {"lat": lat, "lon": lon + 0.0001}],
			"tags": {"public_transport": "platform", "train": "yes"}}]})
	var bare := OsmFetcher.parse_features(detailed, lat, lon)
	check((bare["tram_stops"] as Array).is_empty() and (bare["rail_stations"] as Array).is_empty(),
		"a payload without the layer has no tram stops or stations")
	var parsed := OsmFetcher.parse_features(OsmFetcher.merge_payloads(detailed, transit), lat, lon)
	check((parsed["bus_stops"] as Array).size() == 2, "bus stops merge once each")
	check((parsed["tram_stops"] as Array).size() == 2, "tram stops and tram stop positions merge")
	check((parsed["rail_stations"] as Array).size() == 1, "the station node merges")
	check((parsed["rail_platforms"] as Array).size() == 2, "platforms merge once each")

## Every transit row reads (size and hash checked) and holds stops.
func _layer_checks() -> void:
	var rows := 0
	for key in BundledOsm._entries():
		var entry: Array = BundledOsm._entries()[key]
		if entry[2] != "transit":
			continue
		rows += 1
		check(str(key).ends_with("_transit"), "%s: transit rows are named <place>_transit" % key)
		var text := BundledOsm.read(key)
		check(text != "", "%s: unreadable" % key)
		check(BundledOsm.entry_for(float(entry[0]), float(entry[1]), "transit", OsmQuery.TRANSIT_VERSION) == key,
			"%s: lookup by point and version" % key)
		check(BundledOsm.entry_for(float(entry[0]), float(entry[1]), "transit", OsmQuery.TRANSIT_VERSION + 1) == "",
			"%s: wrong version must not match" % key)
		var parsed := OsmFetcher.parse_features(text, float(entry[0]), float(entry[1]))
		var found: int = (parsed["tram_stops"] as Array).size() + (parsed["bus_stops"] as Array).size() \
			+ (parsed["rail_stations"] as Array).size() + (parsed["rail_platforms"] as Array).size()
		check(found > 0, "%s: no stops, stations or platforms" % key)
	print("transit_layer_test: %d transit layer(s)" % rows)

func _fetch(lat: float, lon: float) -> OsmFetcher:
	var osm := OsmFetcher.new()
	root.add_child(osm)
	osm.offline_mode = true
	var done := [false]
	osm.succeeded.connect(func(_b: Array, _r: Array, _l: Array, _m: Array) -> void: done[0] = true)
	osm.failed.connect(func(_reason: String) -> void: done[0] = true)
	var origin := Vector2(lat, lon)
	osm.fetch(origin.x, origin.y, 2)
	var deadline := Time.get_ticks_msec() + 30000
	while not done[0] and Time.get_ticks_msec() < deadline:
		await process_frame
	check(done[0], "offline fetch must finish")
	return osm

func _offline_checks() -> void:
	var dir := "user://transit_layer_test"
	DirAccess.make_dir_recursive_absolute(dir)
	CacheStore.dir_override = dir
	CacheStore.eviction_suppressed = true
	var helsinki := await _fetch(60.1680, 24.9530)
	check(not helsinki.tram_stops.is_empty(), "offline Helsinki has tram stops")
	check(not helsinki.bus_stops.is_empty(), "offline Helsinki has bus stops")
	check(not helsinki.rail_stations.is_empty() or not helsinki.rail_platforms.is_empty(),
		"offline Helsinki has a station or platform")
	helsinki.queue_free()
	var sf := await _fetch(37.8040, -122.4195)
	check(sf.bus_stops.size() > 20, "offline San Francisco has bus stops beyond the eye's 450 m")
	sf.queue_free()
	var london := await _fetch(51.5018, -0.1196)
	check(not london.bus_stops.is_empty(), "offline London has bus stops")
	check(not london.rail_stations.is_empty(), "offline London has station nodes")
	london.queue_free()
	# A city without the layer is unchanged: no layer text, still loads.
	for key in BundledOsm._entries():
		if not str(key).begins_with("capital_") or not str(key).ends_with("_detailed"):
			continue
		var entry: Array = BundledOsm._entries()[key]
		var capital := await _fetch(float(entry[0]), float(entry[1]))
		check(capital._transit_text == "", "%s: a capital has no transit layer" % key)
		check(not capital.pois.is_empty() or not capital._detailed_text.is_empty(), "%s: still loads" % key)
		capital.queue_free()
		break
	CacheStore.finish()
	CacheStore.dir_override = ""
	CacheStore.eviction_suppressed = false
	DirAccess.remove_absolute(dir)
