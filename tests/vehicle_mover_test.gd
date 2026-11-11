extends SceneTree

## Headless: godot --headless --script tests/vehicle_mover_test.gd
## VehicleMover: trams planned and built as the world has them are found
## by name and driven along their track: a step moves them, they stand at
## their stops and turn at the run's end, never close on the train ahead
## or run into a tunnel mouth, and keep running under reduced motion.

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
	_finish(failures, world)

func _finish(failures: Array[String], world: Node) -> void:
	world.free()
	failures.remove_at(0)
	if failures.is_empty():
		print("VEHICLE MOVER OK: trams move along their track, stay in their run, clear of tunnels and each other, deterministic, running under reduced motion")
		quit(0)
	else:
		for f in failures:
			printerr("VEHICLE MOVER FAIL: ", f)
		quit(1)
