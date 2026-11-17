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
	_check_moving(failures, m2u)
	_check_meeting(failures, m2u)
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
			# Past an end of the deck the mapped way runs on to its
			# abutment at that end's rail height (BridgeTramDeck._past_end).
			var end_s := -1.0
			for e: float in [0.0, LandmarkFhCrownBridge.length_m()]:
				var c := LandmarkFhCrownBridge.at(e)
				if Vector2(c.x, c.y).distance_to(p) <= BridgeTramDeck.END_REACH_M:
					end_s = e
			if end_s < 0.0:
				failures.append("deck point %d is %.2f m off the model's rails" % [i, best])
				return
			want_y = LandmarkFhCrownBridge.deck_y(end_s) + LandmarkFhCrownBridge.RAIL_TOP_M
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
	# One tram each way: a track over the deck carries a single tram.
	var per_route := {}
	for t: Dictionary in trains:
		var route: TramRoute = t["route"]
		if not route.heights.is_empty():
			per_route[route] = int(per_route.get(route, 0)) + 1
	for route: TramRoute in per_route:
		if int(per_route[route]) != 1:
			failures.append("a track over the deck should carry one tram, got %d" % per_route[route])

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

## Street track up to the deck, the mapped bridge way running on a few
## metres past both ends of the model's deck (to its abutments), street
## beyond: the route is supported throughout, a tram's run crosses the
## whole deck, no stop is invented on it, and over 20 minutes the trams
## keep moving on the deck instead of standing there.
func _check_moving(failures: Array[String], m2u: float) -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	var total := LandmarkFhCrownBridge.length_m()
	var west := _offset(0.0, -1.2) - LandmarkFhCrownBridge.heading(0.0) * 10.0
	var east := _offset(total, -1.2) + LandmarkFhCrownBridge.heading(total) * 10.0
	var deck: Array = [west]
	var k := 30.0
	while k < total:
		deck.append(_offset(k, -1.2))
		k += 30.0
	deck.append(east)
	var lines: Array = [[west - LandmarkFhCrownBridge.heading(0.0) * 300.0, west], deck,
		[east, east + LandmarkFhCrownBridge.heading(total) * 300.0]]
	var tags: Array = [{"railway": "light_rail", "gauge": "1000"},
		{"railway": "light_rail", "gauge": "1000", "bridge": "yes"}, {"railway": "light_rail", "gauge": "1000"}]
	data.railways = []
	for i in 3:
		data.railways.append(OsmTags._rail_entry(tags[i],
			PackedVector2Array((lines[i] as Array).map(func(p: Vector2) -> Vector2: return p * m2u))))
	var routes := TramRoute.chains(data, ground, m2u, func(r: Dictionary) -> bool:
		return TramSpecs.carries("helsinki", r))
	if routes.size() != 1:
		failures.append("street, bridge and street should make one route, got %d" % routes.size())
		return
	var route: TramRoute = routes[0]
	if route.unsupported(0.0, route.length_m):
		failures.append("the bridge way running a few metres past the deck's ends should be supported")
		return
	var lo := INF
	var hi := -INF
	var s := 0.0
	while s <= route.length_m:
		if route.bridged(s, s):
			lo = minf(lo, s)
			hi = maxf(hi, s)
		s += 1.0
	var mover := VehicleMover.new()
	mover._m2u = m2u
	var span := mover._span(route, (lo + hi) * 0.5, 16.0, INF, PackedVector2Array(), ground)
	if span.x > lo or span.y < hi:
		failures.append("a tram's run should cross the whole bridge [%.0f, %.0f], got [%.0f, %.0f]" % [lo, hi, span.x, span.y])
	# The planned trams, adopted with stand-in nodes, then 20 minutes run.
	var plan := TransitVehicles.plan(data, ground, m2u)
	var holder := Node3D.new()
	for t in plan.size():
		for i in ((plan[t] as Dictionary)["sections"] as Array).size():
			for part in ["near", "far", "shadow"]:
				var n := Node3D.new()
				n.name = "Tram%d_%d_%s" % [t, i, part]
				holder.add_child(n)
	mover._adopt(holder, "Tram", plan, data, ground, false)
	if mover.count() == 0:
		failures.append("the bridge line should carry a moving tram")
		holder.free()
		return
	for i in mover.count():
		for stop: float in (mover._trains[i] as Dictionary)["stops"]:
			if stop > lo + 16.0 and stop < hi - 16.0:
				failures.append("tram %d has a stop on the bridge at %.0f m" % [i, stop])
				break
	var on := 0.0
	var standing := 0.0
	for n in 2400:
		mover.tick(0.5, Vector2.ZERO)
		for i in mover.count():
			var at := mover.position_of(i)
			if at > lo + 20.0 and at < hi - 20.0:
				on += 0.5
				if float((mover._trains[i] as Dictionary)["v"]) < 0.05:
					standing += 0.5
	if on <= 0.0:
		failures.append("no tram crossed the bridge in 20 minutes")
	elif standing > on * 0.05:
		failures.append("trams stood %.0f s of %.0f s on the bridge: they should keep moving" % [standing, on])
	holder.free()

## Both tracks over the deck, each with street track at either end: the
## two trams (one each way) keep in step, the same distance from the
## middle of the deck whenever both are out, and pass each other there.
func _check_meeting(failures: Array[String], m2u: float) -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	var total := LandmarkFhCrownBridge.length_m()
	data.railways = []
	for across: float in [-1.2, -5.0]:
		var west := _offset(0.0, across) - LandmarkFhCrownBridge.heading(0.0) * 10.0
		var east := _offset(total, across) + LandmarkFhCrownBridge.heading(total) * 10.0
		var deck: Array = [west]
		var k := 30.0
		while k < total:
			deck.append(_offset(k, across))
			k += 30.0
		deck.append(east)
		var lines: Array = [[west - LandmarkFhCrownBridge.heading(0.0) * 300.0, west], deck,
			[east, east + LandmarkFhCrownBridge.heading(total) * 300.0]]
		for i in 3:
			var tags := {"railway": "light_rail", "gauge": "1000"}
			if i == 1:
				tags["bridge"] = "yes"
			data.railways.append(OsmTags._rail_entry(tags,
				PackedVector2Array((lines[i] as Array).map(func(p: Vector2) -> Vector2: return p * m2u))))
	var plan := TransitVehicles.plan(data, ground, m2u)
	var holder := Node3D.new()
	for t in plan.size():
		for i in ((plan[t] as Dictionary)["sections"] as Array).size():
			for part in ["near", "far", "shadow"]:
				var n := Node3D.new()
				n.name = "Tram%d_%d_%s" % [t, i, part]
				holder.add_child(n)
	var mover := VehicleMover.new()
	mover._m2u = m2u
	mover._adopt(holder, "Tram", plan, data, ground, false)
	mover._time_deck()
	if mover.count() != 2:
		failures.append("two tracks over the deck should carry two trams, got %d" % mover.count())
		holder.free()
		return
	var a: Dictionary = mover._trains[0]
	var b: Dictionary = mover._trains[1]
	if is_nan(float(a["deck_mid"])) or is_nan(float(b["deck_mid"])):
		failures.append("both trams should keep the deck's timetable")
		holder.free()
		return
	var met := false
	for n in 12000:
		mover.tick(0.1, Vector2.ZERO)
		if bool(a["hidden"]) or bool(b["hidden"]):
			continue
		var da := (float(a["s"]) - float(a["deck_mid"])) * float(a["dir"])
		var db := (float(b["s"]) - float(b["deck_mid"])) * float(b["dir"])
		if absf(da - db) > 3.0:
			failures.append("the deck trams should keep in step: %.0f m and %.0f m from mid-span" % [da, db])
			break
		if absf(da) < 5.0:
			var pa := (a["route"] as TramRoute).xz_at(float(a["s"]))
			var pb := (b["route"] as TramRoute).xz_at(float(b["s"]))
			met = met or pa.distance_to(pb) < 15.0 * m2u
	if not met:
		failures.append("the two trams should pass each other mid-span")
	holder.free()

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("BRIDGE TRAM DECK OK: onto the model's rails at deck height, trams up on the deck, undecked bridges kept clear")
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE TRAM DECK FAIL: ", f)
		quit(1)
