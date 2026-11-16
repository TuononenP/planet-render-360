extends SceneTree

## Headless: godot --headless --script tests/postpass_layers_test.gd
## The ring, far-city and horizon layers ask Postpass first (LayerRequest,
## PostpassLayers): their bodies select what the Overpass queries do, and
## a Postpass answer, converted, reads like Overpass's in each parser.
## No network: LayerRequest's fallbacks are driven by hand.

var _fails := 0

## Records a Postpass run instead of sending it.
class StubPostpass extends PostpassRequest:
	var ran := false
	func run(_body: String, _check: Callable = Callable()) -> void:
		ran = true

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_bodies()
	_answers()
	_order()
	await _converts()
	if _fails == 0:
		print("postpass_layers_test: PASS")
	quit(1 if _fails > 0 else 0)

func _sql(body: String) -> String:
	return body.trim_prefix("data=").uri_decode()

func _bodies() -> void:
	var ring := _sql(PostpassLayers.build_ring_body(60.17, 24.94, 2500))
	_check(ring.contains("'motorway','trunk','primary','secondary','tertiary'") and ring.contains("'waterway'")
		and ring.contains("'coastline'") and ring.contains("2500)"), "the ring asks roads, waterways and coast to its radius")
	_check(ring.contains("LIMIT %d" % OsmQuery.CAP_RING_COASTLINE), "the ring keeps the Overpass caps")
	var far := _sql(PostpassLayers.build_far_body(60.17, 24.94))
	_check(far.split(" UNION ALL ").size() == 4, "far city: landuse ways, relations, towers, parts")
	_check(far.contains("'residential','commercial','industrial','retail'") and far.contains(">= 50")
		and far.contains(">= 15") and far.contains("0.3048"), "far city keeps the landuse kinds and the tall test")
	_check(not far.contains("::int"), "no integer cast an odd levels tag could overflow")
	var horizon := _sql(PostpassLayers.build_horizon_body(60.17, 24.94))
	_check(horizon.contains("'peak'") and horizon.contains("'city','town','village'") and horizon.contains("'lake','reservoir'")
		and horizon.contains("ST_PointOnSurface"), "horizon asks peaks, towns and lakes at a point each")
	for body in [ring, far, horizon]:
		_check(body.count("(") == body.count(")"), "balanced SQL")

func _answers() -> void:
	# A named lake answered at a point (as a node) is a horizon site.
	var lake := {"type": "FeatureCollection", "features": [
		{"type": "Feature", "geometry": {"type": "Point", "coordinates": [25.0, 60.3]},
			"properties": {"osm_type": "N", "osm_id": 7, "tags": {"natural": "water", "water": "lake", "name": "Tuusulanjärvi"}}}]}
	var sites := HorizonFetcher.parse(str(PostpassFallback.to_overpass_json(JSON.stringify(lake).to_utf8_buffer())["json"]))
	_check(sites.size() == 1 and sites[0]["kind"] == "Lake" and is_equal_approx(float(sites[0]["lat"]), 60.3),
		"a Postpass lake is a horizon site")
	# A tall outline is a far tower; a residential way is far landuse.
	var d := 0.001
	var square := [[[24.95, 60.17], [24.95 + d, 60.17], [24.95 + d, 60.17 + d], [24.95, 60.17 + d], [24.95, 60.17]]]
	var far := {"type": "FeatureCollection", "features": [
		{"type": "Feature", "geometry": {"type": "MultiPolygon", "coordinates": [square]},
			"properties": {"osm_type": "W", "osm_id": 1, "tags": {"building": "yes", "height": "80"}}},
		{"type": "Feature", "geometry": {"type": "MultiPolygon", "coordinates": [square]},
			"properties": {"osm_type": "W", "osm_id": 2, "tags": {"landuse": "residential"}}}]}
	var text := str(PostpassFallback.to_overpass_json(JSON.stringify(far).to_utf8_buffer())["json"])
	var parsed := FarCityFetcher.parse(text, 60.17, 24.94)
	_check((parsed["towers"] as Array).size() == 1 and (parsed["landuse"] as Array).size() == 1,
		"a Postpass far-city answer gives its tower and landuse: %s" % [parsed])
	_check(FarCityFetcher._usable(text), "a Postpass far-city answer is cached as complete")

func _order() -> void:
	var req := LayerRequest.new(1.0)
	root.add_child(req)
	var stub := StubPostpass.new()
	req.add_child(stub)
	req._postpass = stub
	var got := []
	req.exhausted.connect(func(reason: String, _a: int) -> void: got.append(reason))
	# No Overpass to ask (iOS, Android): a Postpass failure ends the layer.
	var none: Array[String] = []
	req._endpoints = none
	req._on_postpass_failed("Postpass down")
	_check(got == ["Postpass down"], "without Overpass a Postpass failure ends the layer: %s" % [got])
	# With Overpass to ask, a run goes to Postpass first; its failure asks
	# Overpass, and Overpass out ends the layer with both reasons.
	got.clear()
	stub.ran = false
	var some: Array[String] = ["https://overpass.example/api/interpreter"]
	req.run("pp", "op", func(_t: String) -> String: return "", some)
	_check(stub.ran and not req._overpass_tried, "Postpass is always asked first")
	req.overpass.cancel()
	req._overpass_tried = true
	req._reason = "Postpass down"
	req._on_overpass_exhausted("Overpass 504", 1)
	_check(got == ["Postpass down; Overpass 504"], "both out: one failure with both reasons: %s" % [got])
	req.free()

## A Postpass answer is converted and checked on a worker; the check's
## verdict comes back as a failure, a usable answer as Overpass JSON.
func _converts() -> void:
	var req := PostpassRequest.new()
	root.add_child(req)
	var got := []
	req.answered.connect(func(text: String) -> void: got.append(["ok", text]))
	req.failed.connect(func(why: String) -> void: got.append(["fail", why]))
	var body := JSON.stringify({"type": "FeatureCollection", "features": [
		{"type": "Feature", "geometry": {"type": "Point", "coordinates": [24.9, 60.2]},
			"properties": {"osm_type": "N", "osm_id": 1, "tags": {"natural": "peak", "name": "X"}}}]}).to_utf8_buffer()
	req._check = func(_t: String) -> String: return "too small"
	req._on_done(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), body)
	for i in 60:
		if not got.is_empty():
			break
		await process_frame
	_check(got == [["fail", "Postpass too small"]], "a failed check is a Postpass failure: %s" % [got])
	got.clear()
	req._check = Callable()
	req._on_done(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), body)
	req.cancel()  # a cancelled run reports nothing
	req._on_done(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), body)
	for i in 60:
		if not got.is_empty():
			break
		await process_frame
	await process_frame
	_check(got.size() == 1 and got[0][0] == "ok" and str(got[0][1]).contains('"peak"'),
		"only the live conversion reports, as Overpass JSON: %s" % [got])
	req.free()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)
