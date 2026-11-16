extends SceneTree

## Headless: godot --headless --script tests/bridge_tram_deck_test.gd
## Trams over Kruunuvuorensilta (BridgeTramDeck): the mapped light rail
## over the deck is moved onto the model's own rails at their rail-head
## height, the ground either side keeps the mapped line, trams stand on
## the deck at that height, and a bridge with no known deck still keeps
## trams off it, standing or moving. Offline.

const LAT := 60.1736
const LON := 25.0022

func _init() -> void:
	var failures: Array[String] = []
	var m2u := WorldScale.metres_to_units()
	var data := _data()
	var ground := GroundTruth.new(data)
	data.railways = [_line(m2u)]
	var routes := TramRoute.chains(data, ground, m2u, func(r: Dictionary) -> bool:
		return TramSpecs.carries("helsinki", r))
	if routes.size() != 1:
		_finish(["the bridge line should make one route, got %d" % routes.size()])
		return
	var route: TramRoute = routes[0]
	_check_deck(failures, route, ground, m2u)
	_check_standing(failures, data, ground, m2u)
	_check_unknown_bridge(failures, ground, m2u)
	_finish(failures)

func _data() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = LAT
	data.longitude = LON
	data.buildings = []
	data.landmark_type = "kruunuvuorensilta"
	data.has_landmark_site = true
	data.landmark_lat = LAT
	data.landmark_lon = LON
	return data

## The mapped north track (as OSM has it, 1.2 m north of the deck centre,
## the model's track is 1.8 m), bridge=yes, with ground track at both ends.
func _line(m2u: float) -> Dictionary:
	var pts: Array = []
	var total := LandmarkFhCrownBridge.length_m()
	var first := _offset(0.0, -1.2)
	var last := _offset(total, -1.2)
	pts.append(first - LandmarkFhCrownBridge.heading(0.0) * 60.0)
	var k := 0.0
	while k <= total:
		pts.append(_offset(k, -1.2))
		k += 30.0
	pts.append(last)
	var rail := OsmTags._rail_entry({"railway": "light_rail", "gauge": "1000", "bridge": "yes"},
		PackedVector2Array(pts.map(func(p: Vector2) -> Vector2: return p * m2u)))
	return rail

func _offset(s: float, across: float) -> Vector2:
	var c := LandmarkFhCrownBridge.at(s)
	var t := LandmarkFhCrownBridge.heading(s)
	return Vector2(c.x, c.y) + Vector2(-t.y, t.x) * across

func _check_deck(failures: Array[String], route: TramRoute, ground: GroundTruth, m2u: float) -> void:
	var sea := ground.render_y(0.0)
	var on := 0
	var crest := -INF
	for i in route.points.size():
		var h := route.heights[i] if i < route.heights.size() else NAN
		if is_nan(h):
			continue
		on += 1
		var p := route.points[i] / m2u
		# Nearest model rail point on the track it was snapped to.
		var best := INF
		var want_y := 0.0
		var s := 0.0
		while s <= LandmarkFhCrownBridge.length_m():
			for track: float in LandmarkFhCrownBridge.TRACKS:
				var r := LandmarkFhCrownBridge.rail_point(s, track)
				var d := Vector2(r.x, r.z).distance_to(p)
				if d < best:
					best = d
					want_y = r.y
			s += 0.5
		if best > 0.3:
			failures.append("deck point %d is %.2f m off the model's rails" % [i, best])
			return
		if absf((h - sea) / m2u - want_y) > 0.1:
			failures.append("deck point %d stands at %.2f m, the rails at %.2f m" % [i, (h - sea) / m2u, want_y])
			return
		crest = maxf(crest, (h - sea) / m2u)
	if on < 200:
		failures.append("the deck should be resampled every few metres: %d points" % on)
	if crest < 22.0 or crest > 26.0:
		failures.append("the rails should crest near 24 m over the sea, got %.1f" % crest)
	if not is_nan(route.heights[0]):
		failures.append("the ground track before the bridge keeps no deck height")
	# The snapped track is the model's -1.8 m one, not the mapped -1.2 m:
	# mid-span, the route passes within a few cm of that rail line.
	var half := LandmarkFhCrownBridge.length_m() * 0.5
	var r18 := LandmarkFhCrownBridge.rail_point(half, -1.8)
	var near := route.nearest(Vector2(r18.x, r18.z) * m2u)
	if near.y > 0.1:
		failures.append("mid-span the tram should ride the model's -1.8 m track: %.2f m off" % near.y)
	# Over the deck the route is supported; the bridge-tagged lead-in off
	# the deck (no height known) is not.
	var on_deck := near.x
	if route.unsupported(on_deck - 100.0, on_deck + 100.0):
		failures.append("a bridge with its deck known is not unsupported")
	if not route.unsupported(0.0, 20.0):
		failures.append("bridge-tagged track off the deck stays unsupported")

func _check_standing(failures: Array[String], data: LocationData, ground: GroundTruth, m2u: float) -> void:
	var trains := TransitVehicles.plan(data, ground, m2u)
	var high := 0
	for t: Dictionary in trains:
		for pose: Transform3D in t["poses"]:
			if (pose.origin.y - ground.render_y(0.0)) / m2u > 8.0:
				high += 1
	if high == 0:
		failures.append("trams should stand on the bridge deck: %d trains, none up on it" % trains.size())

func _check_unknown_bridge(failures: Array[String], ground: GroundTruth, m2u: float) -> void:
	var line := PackedVector2Array([Vector2(-600, 900) * m2u, Vector2(-300, 900) * m2u,
		Vector2(-200, 900) * m2u, Vector2(200, 900) * m2u])
	var street := OsmTags._rail_entry({"railway": "tram", "gauge": "1000"}, line)
	var bridge := OsmTags._rail_entry({"railway": "tram", "gauge": "1000", "bridge": "yes"}, line)
	var route := TramRoute.of(line, [street, bridge, street], ground, m2u)
	if not route.unsupported(250.0, 350.0) or route.unsupported(0.0, 250.0):
		failures.append("an undecked bridge is unsupported, the street before it is not")
	var mover := VehicleMover.new()
	mover._m2u = m2u
	var span := mover._span(route, 100.0, 15.0, 600.0, PackedVector2Array(), ground)
	if span.y > 300.0 - 15.0 + 0.01:
		failures.append("a moving tram must stop short of an undecked bridge: run ends at %.1f m" % span.y)

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("BRIDGE TRAM DECK OK: onto the model's rails at deck height, trams up on the deck, undecked bridges kept clear")
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE TRAM DECK FAIL: ", f)
		quit(1)
