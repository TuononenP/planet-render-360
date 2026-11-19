extends SceneTree

## Headless: godot --headless --script tests/vehicle_mover_test.gd
## VehicleMover: trams planned and built as the world has them are found
## by name and driven along their track: a step moves them, they never
## close on the train ahead or run into a tunnel mouth, and keep running
## under reduced motion. A tram stands only at a mapped stop, at a red
## light or queued behind another tram: each track of a pair runs one way
## (driving on the right), and at the end of its run a tram leaves and
## comes back in at the start. Where tracks of different routes meet (a
## crossing, a switch, a rail mapped twice) no two trams ever touch, and
## trams sharing a rail run the same way.

func _init() -> void:
	_run()

func _data() -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = 60.17
	data.longitude = 24.94
	data.buildings = []
	return data

func _rail(tags: Dictionary, pts: Array) -> Dictionary:
	var all := {"railway": "tram"}
	all.merge(tags, true)
	return OsmTags._rail_entry(all, PackedVector2Array(pts))

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var data := _data()
	data.railways = [
		_rail({"gauge": "1000"}, [Vector2(-500, -200), Vector2(300, -200)]),
		_rail({"gauge": "1000", "tunnel": "yes"}, [Vector2(300, -200), Vector2(500, -200)]),
	]
	for i in 8:
		data.tram_stops.append({"x": -450.0 + 100.0 * float(i), "z": -198.0, "name": "Stop %d" % i})
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var world := Node3D.new()
	var built := TransitVehicles.build(world, data, ground)
	if built < 2:
		failures.append("the world should stand trams to move: %d" % built)
	var mover := VehicleMover.attach(world, data, ground)
	if mover == null:
		failures.append("a world with trams gets a mover")
		_finish(failures, world)
		return
	var start: Array = []
	var holder := world.get_node("Trams")
	var nodes_start := {}
	for node in holder.get_children():
		nodes_start[node.name] = (node as Node3D).transform
	for i in mover.count():
		start.append(mover.position_of(i))
	# Everything stays inside its run, clear of the tunnel and of each other.
	var moved := false
	var stood := 0
	var reversed := false
	var last_dir := []
	for i in mover.count():
		last_dir.append(0.0)
	var bad := false
	for step in 6000:
		if bad:
			break
		mover.tick(0.1, Vector2.ZERO)
		for i in mover.count():
			var run := mover.run_of(i)
			var s := mover.position_of(i)
			if s < float(run[1]) - 0.01 or s > float(run[2]) + 0.01:
				failures.append("train %d left its run: %s not in %s..%s" % [i, s, run[1], run[2]])
				bad = true
				break
			var p: Vector2 = (run[0] as TramRoute).xz_at(s)
			if p.x > 300.0 - TransitVehicles.TUNNEL_CLEAR_M + 1.0 and absf(p.y + 200.0) < 1.0 and p.x > 270.0:
				failures.append("train %d ran into the tunnel mouth at %s" % [i, p])
				bad = true
				break
			moved = moved or absf(s - float(start[i])) > 1.0
			var dir := signf(s - float(start[i]))
			for j in range(i + 1, mover.count()):
				if run[0] == mover.run_of(j)[0]:
					var apart := absf(s - mover.position_of(j)) - 0.5 * (TramSpecs.length_m("modern3") + TramSpecs.length_m("modern3"))
					if apart < 0.0:
						failures.append("trains %d and %d overlap along the track" % [i, j])
						bad = true
						break
	if not moved:
		failures.append("trains should have moved after 10 minutes")
	# The moved nodes follow the trains.
	var shifted := 0
	for node in holder.get_children():
		if not (node as Node3D).transform.origin.is_equal_approx(nodes_start[node.name].origin):
			shifted += 1
	if shifted == 0:
		failures.append("moving a train should move its section nodes")
	# Deterministic for equal inputs.
	var again := VehicleMover.attach(world, data, ground)
	var other := VehicleMover.attach(world, data, ground)
	for step in 300:
		again.tick(0.1, Vector2.ZERO)
		other.tick(0.1, Vector2.ZERO)
	for i in again.count():
		if again.position_of(i) != other.position_of(i):
			failures.append("two movers stepped alike must agree")
			break
	# Reduced motion (camera flights, UI springs) leaves the traffic running.
	UiPrefs.reduce_motion = true
	var before := again.position_of(0)
	for step in 600:
		again.tick(0.1, Vector2.ZERO)
	if again.position_of(0) == before:
		failures.append("reduced motion should leave the trams running")
	UiPrefs.reduce_motion = false
	# A world without the nodes is left alone.
	if VehicleMover.attach(Node3D.new(), data, ground) != null:
		failures.append("no trams in the world, no mover")
	_check_planned_motion(failures, world, data, ground)
	_check_never_stops(failures)
	_check_junctions(failures)
	_finish(failures, world)

## The motion facts compute_plans works out ahead (on a worker) give the same
## trains as attach() working them out itself: runs, stops, ways, signals.
func _check_planned_motion(failures: Array[String], world: Node, data: LocationData, ground: GroundTruth) -> void:
	var own := VehicleMover.attach(world, data, ground)
	var plans := VehicleMover.compute_plans(data, ground)
	var motions := 0
	for key in ["Tram", "Train"]:
		for train: Dictionary in plans[key]:
			motions += 1 if train.has("motion") else 0
	if motions == 0:
		failures.append("compute_plans should plan the trains' motion")
	VehicleMover.store_plans(data, ground, plans)
	var ahead := VehicleMover.attach(world, data, ground)
	data.remove_meta(VehicleMover.PLANS_META)
	data.remove_meta(VehicleMover.PLANS_GROUND)
	if own == null or ahead == null or own.count() != ahead.count():
		failures.append("a mover with planned motion drives the same trains")
		return
	for i in own.count():
		var a: Dictionary = own._trains[i]
		var b: Dictionary = ahead._trains[i]
		for field in ["lo", "hi", "dir", "stops", "dwell", "signals", "salt", "s"]:
			if var_to_bytes(a[field]) != var_to_bytes(b[field]):
				failures.append("train %d: planned %s differs (%s against %s)" % [i, field, a[field], b[field]])
		if var_to_bytes(a["deck_mid"]) != var_to_bytes(b["deck_mid"]):
			failures.append("train %d: planned deck_mid differs" % i)

## Twin tracks 3.6 m apart with mapped stops and a traffic light: for
## 20 minutes no tram stands on the line except at a stop, at the red
## light or queued behind another tram; each track runs one way, the
## pair opposite ways on the right; trams leave at the end and come back.
func _check_never_stops(failures: Array[String]) -> void:
	var data := _data()
	data.country = "FI"
	# Driving on the right: eastbound (+x) on the south track (+z).
	data.railways = [_rail({"gauge": "1000"}, [Vector2(-500, -196.4), Vector2(400, -196.4)]),
		_rail({"gauge": "1000"}, [Vector2(-500, -200), Vector2(400, -200)])]
	for i in 9:
		data.tram_stops.append({"x": -450.0 + 100.0 * float(i), "z": -198.2, "name": "Stop %d" % i})
	data.street_furniture = [{"x": 0.0, "z": -203.0, "kind": "signals"}]
	var ground := GroundTruth.new(data)
	var world := Node3D.new()
	TransitVehicles.build(world, data, ground)
	var mover := VehicleMover.attach(world, data, ground)
	if mover == null or mover.count() < 2:
		failures.append("twin tracks should carry moving trams")
		world.free()
		return
	var east := {}
	for i in mover.count():
		var t: Dictionary = mover._trains[i]
		var route: TramRoute = t["route"]
		var fwd := float(t["dir"]) * signf(route.xz_at(route.length_m).x - route.xz_at(0.0).x)
		var south := route.xz_at(route.length_m * 0.5).y > -198.2
		if (fwd > 0.0) != south:
			failures.append("tram %d runs %s on the %s track: trams keep right" % [
				i, "east" if fwd > 0.0 else "west", "south" if south else "north"])
			break
	var left := false
	var back := false
	var gone := {}
	for step in 12000:
		mover.tick(0.1, Vector2.ZERO)
		for i in mover.count():
			var t: Dictionary = mover._trains[i]
			if bool(t["hidden"]):
				left = true
				gone[i] = true
				continue
			if gone.has(i):
				back = true
			if float(t["v"]) >= 0.05 or float(t["dwell"]) > 0.0:
				continue
			var route: TramRoute = t["route"]
			var s := float(t["s"])
			var why := ""
			for stop: float in t["stops"]:
				if absf(stop - s) < 1.0:
					why = "stop"
			var front := s + float(t["dir"]) * float(t["length"]) * 0.5
			for sig: float in t["signals"]:
				var d := (sig - front) * float(t["dir"])
				if d > -0.5 and d < 2.0 and mover._red(route, sig):
					why = "light"
			for j in mover.count():
				var o: Dictionary = mover._trains[j]
				if j != i and o["route"] == route and not bool(o["hidden"]):
					var ds := (float(o["s"]) - s) * float(t["dir"])
					if ds > 0.0 and ds < (float(o["length"]) + float(t["length"])) * 0.5 + VehicleMover.FOLLOW_M + 3.0:
						why = "queue"
			if why == "":
				failures.append("tram %d stood on the line at %.0f m after %.0f s" % [i, s, step * 0.1])
				world.free()
				return
	if not left:
		failures.append("a tram at the end of its run should leave the track")
	elif not back:
		failures.append("a tram that left should come back in at the start of its track")
	var signals := 0
	for i in mover.count():
		signals += ((mover._trains[i] as Dictionary)["signals"] as PackedFloat32Array).size()
	if signals == 0:
		failures.append("the traffic light beside the tracks should be on the trams' runs")
	world.free()

## Twin tracks with a single line crossing both, a branch leaving the
## south track at a shallow switch and a way mapped over part of the north
## track: for 20 minutes no two trams' bodies come within a car's width,
## none stands still (off a stop) for two minutes waiting for another,
## and trams on one rail all run the same way.
func _check_junctions(failures: Array[String]) -> void:
	var data := _data()
	data.country = "FI"
	data.railways = [_rail({"gauge": "1000"}, [Vector2(-500, -196.4), Vector2(400, -196.4)]),
		_rail({"gauge": "1000"}, [Vector2(-500, -200), Vector2(400, -200)]),
		_rail({"gauge": "1000"}, [Vector2(0, -450), Vector2(0, 60)]),
		_rail({"gauge": "1000"}, [Vector2(-150, -196.4), Vector2(-100, -192), Vector2(-70, -170), Vector2(-60, -140),
			Vector2(-60, 60)]),
		_rail({"gauge": "1000"}, [Vector2(250, -200.3), Vector2(-250, -200.3), Vector2(-260, -230), Vector2(-260, -440)]),
	]
	for i in 9:
		data.tram_stops.append({"x": -450.0 + 100.0 * float(i), "z": -198.2, "name": "Main %d" % i})
	for z: float in [-400.0, -330.0, -260.0, -120.0, -50.0, 20.0]:
		data.tram_stops.append({"x": 2.0, "z": z, "name": "Cross %d" % z})
		data.tram_stops.append({"x": -58.0, "z": z, "name": "Branch %d" % z})
	var ground := GroundTruth.new(data)
	var world := Node3D.new()
	TransitVehicles.build(world, data, ground)
	var mover := VehicleMover.attach(world, data, ground)
	var routes := {}
	if mover != null:
		for t: Dictionary in mover._trains:
			routes[t["route"]] = true
	if mover == null or routes.size() < 3:
		failures.append("the junction should carry trams on at least three tracks: %d" % routes.size())
		world.free()
		return
	var m2u := WorldScale.metres_to_units()
	# Routes sharing a rail (within 1 m for 20 m or more) run the same way.
	for t: Dictionary in mover._trains:
		for o: Dictionary in mover._trains:
			var a: TramRoute = t["route"]
			var b: TramRoute = o["route"]
			if a == b:
				continue
			var shared := 0.0
			var same := 0.0
			var s := 1.0
			while s < a.length_m - 1.0:
				var near := b.nearest(a.xz_at(s))
				if near.y < 1.0:
					shared += 2.0
					var fa := (a.xz_at(s + 1.0) - a.xz_at(s - 1.0)) * float(t["dir"])
					var fb := (b.xz_at(near.x + 1.0) - b.xz_at(near.x - 1.0)) * float(o["dir"])
					same += 2.0 * signf(fa.dot(fb))
				s += 2.0
			if shared >= 20.0 and same < shared * 0.5:
				failures.append("trams sharing %.0f m of one rail run opposite ways" % shared)
				world.free()
				return
	var still: Array = []
	still.resize(mover.count())
	still.fill(0.0)
	for step in 12000:
		mover.tick(0.1, Vector2.ZERO)
		for i in mover.count():
			var t: Dictionary = mover._trains[i]
			var standing := not bool(t["hidden"]) and float(t["v"]) < 0.05 and float(t["dwell"]) <= 0.0
			still[i] = float(still[i]) + 0.1 if standing else 0.0
			if float(still[i]) > 120.0:
				failures.append("tram %d has stood at %s for two minutes: trams at a junction wait for each other" % [
					i, (t["route"] as TramRoute).xz_at(float(t["s"]))])
				world.free()
				return
		if step % 5 != 0:
			continue
		for i in mover.count():
			var t: Dictionary = mover._trains[i]
			if bool(t["hidden"]):
				continue
			for j in range(i + 1, mover.count()):
				var o: Dictionary = mover._trains[j]
				if bool(o["hidden"]):
					continue
				var gap := _body_gap(t, o, m2u)
				if gap < TramSpecs.width_m("modern3"):
					failures.append("trams %d and %d touch (%.2f m between their tracks) at %s after %.0f s" % [
						i, j, gap, (t["route"] as TramRoute).xz_at(float(t["s"])), step * 0.1])
					world.free()
					return
	world.free()

## Closest distance (metres) between the track lines under two trams.
func _body_gap(t: Dictionary, o: Dictionary, m2u: float) -> float:
	var a: TramRoute = t["route"]
	var b: TramRoute = o["route"]
	var reach := (float(t["length"]) + float(o["length"])) * 0.5 + 3.0
	if a.xz_at(float(t["s"])).distance_to(b.xz_at(float(o["s"]))) > reach * m2u:
		return INF
	var best := INF
	var x := -float(t["length"]) * 0.5
	while x <= float(t["length"]) * 0.5:
		var p := a.xz_at(float(t["s"]) + x)
		var y := -float(o["length"]) * 0.5
		while y <= float(o["length"]) * 0.5:
			best = minf(best, p.distance_to(b.xz_at(float(o["s"]) + y)))
			y += 1.0
		x += 1.0
	return best / m2u

func _finish(failures: Array[String], world: Node) -> void:
	world.free()
	failures.remove_at(0)
	if failures.is_empty():
		print("VEHICLE MOVER OK: trams move along their track, stay in their run, clear of tunnels and each other and of other routes' trams, deterministic, running under reduced motion")
		quit(0)
	else:
		for f in failures:
			printerr("VEHICLE MOVER FAIL: ", f)
		quit(1)
