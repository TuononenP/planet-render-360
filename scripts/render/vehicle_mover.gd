class_name VehicleMover
extends RefCounted

## Drives the trams, and the trains standing at platforms, along their
## track. The built world only carries the meshes (it is cached as a
## scene, TransitVehicles / StationTrains name them); the mover plans the
## same trains again from the same data, finds their nodes by name and
## moves them: each train accelerates to a cruising speed, brakes to a
## stop at its stops (or every few hundred metres where none are
## mapped), dwells, and carries on, turning round at the end of its run.
## It keeps clear of the train ahead and of a tunnel mouth or the edge
## of the data. A terminus train keeps standing at its buffers.
##
## Time is the sum of the deltas given to tick(), so a test or a capture
## steps it exactly; reduced motion leaves every train where it stands.

const CRUISE_MS := 8.0
const TRAIN_CRUISE_MS := 10.0
const ACCEL_MS2 := 0.9
const BRAKE_MS2 := 1.1
## How far a train runs from where it stands (metres, each way).
const TRAM_RUN_M := 600.0
const TRAIN_RUN_M := 220.0
## Pseudo stops where none are mapped, and the dwell at any stop.
const STOP_EVERY_M := 180.0
const DWELL_S := Vector2(10.0, 28.0)
const TRAIN_DWELL_S := Vector2(30.0, 80.0)
## Clear gap kept to the train ahead (metres), and how long a train
## held up this way waits before it turns round.
const FOLLOW_M := 10.0
const BLOCKED_S := 6.0
## Trains farther than this from the eye are moved at a lower rate.
const NEAR_M := 400.0
const FAR_STEP_S := 0.5
## Longest step simulated at once.
const MAX_STEP_S := 0.1

var _trains: Array = []
var _m2u := 1.0
var _clock := 0.0

## A mover for the trams and platform trains under `world`, planned from
## `data` as the world was built; null when there are none to move.
static func attach(world: Node, data: LocationData, ground: GroundTruth) -> VehicleMover:
	if world == null or data == null or ground == null or not TransitVehicles.enabled(data.quality_preset):
		return null
	var mover := VehicleMover.new()
	mover._m2u = WorldScale.metres_to_units()
	var trams := world.find_child("Trams", true, false)
	if trams != null and not data.railways.is_empty():
		mover._adopt(trams, "Tram", TransitVehicles.plan(data, ground, mover._m2u), data, ground, false)
	var trains := world.find_child("Trains", true, false)
	if trains != null and not data.railways.is_empty():
		mover._adopt(trains, "Train", StationTrains.plan(data, ground, mover._m2u), data, ground, true)
	return mover if not mover._trains.is_empty() else null

## How many trains this mover drives.
func count() -> int:
	return _trains.size()

## Position (metres along its route) of train `i`.
func position_of(i: int) -> float:
	return float((_trains[i] as Dictionary)["s"])

## The route of train `i`, and its allowed run [low, high] in metres.
func run_of(i: int) -> Array:
	var t: Dictionary = _trains[i]
	return [t["route"], t["lo"], t["hi"]]

## Moves every train on by `delta` seconds; `eye` is the camera (world
## XZ), which sets how often far trains are posed.
func tick(delta: float, eye: Vector2) -> void:
	if UiPrefs.reduce_motion or _trains.is_empty():
		return
	var left := maxf(delta, 0.0)
	while left > 0.0:
		var dt := minf(left, MAX_STEP_S)
		left -= dt
		_clock += dt
		for t: Dictionary in _trains:
			_step(t, dt)
	for t: Dictionary in _trains:
		var near := (t["mid"] as Vector2).distance_to(eye) < NEAR_M * _m2u
		t["age"] = float(t["age"]) + delta
		if bool(t["moved"]) and (near or float(t["age"]) >= FAR_STEP_S):
			_pose(t)
			t["age"] = 0.0

func stop() -> void:
	_trains.clear()

## Takes the trains of `plan` whose nodes `holder` has (named `prefix`
## + train + "_" + section + "_near" / "_far" / "_shadow").
func _adopt(holder: Node, prefix: String, plan: Array, data: LocationData, ground: GroundTruth,
		platform_only: bool) -> void:
	var mouths := TramRoute.mouths(data, func(_rail: Dictionary) -> bool: return true)
	for k in plan.size():
		var train: Dictionary = plan[k]
		if platform_only and str(train.get("at", "")) != "platform":
			continue
		var sections: Array = train["sections"]
		var nodes: Array = []
		var whole := true
		for i in sections.size():
			var row: Array = []
			for part in ["near", "far", "shadow"]:
				var node := holder.get_node_or_null("%s%d_%d_%s" % [prefix, k, i, part]) as Node3D
				whole = whole and node != null
				row.append(node)
			nodes.append(row)
		if not whole:
			continue
		var route: TramRoute = train["route"]
		var s0 := float(train["s"])
		var reach := float(train["length"]) * 0.5 + 1.0
		var run := TRAIN_RUN_M if platform_only else TRAM_RUN_M
		var span := _span(route, s0, reach, run, mouths, ground)
		var salt := TransitVehicles._hash(float(k), s0, 41.0 if platform_only else 17.0)
		var stops := PackedFloat32Array()
		if not platform_only:
			for stop in data.tram_stops:
				if not (stop is Dictionary):
					continue
				var at := route.nearest(Vector2(float(stop.get("x", 0.0)), float(stop.get("z", 0.0))))
				if at.y < TransitVehicles.SNAP_M and at.x > span.x and at.x < span.y:
					stops.append(at.x)
		var x := s0 + STOP_EVERY_M * (0.5 + salt)
		while x < span.y:
			stops.append(x)
			x += STOP_EVERY_M * (0.8 + 0.4 * TransitVehicles._hash(x, salt, 5.0))
		x = s0 - STOP_EVERY_M * (0.5 + salt)
		while x > span.x:
			stops.append(x)
			x -= STOP_EVERY_M * (0.8 + 0.4 * TransitVehicles._hash(x, salt, 6.0))
		stops.append(s0)
		stops.append(span.x)
		stops.append(span.y)
		var sorted := Array(stops)
		sorted.sort()
		_trains.append({
			"route": route, "sections": sections, "nodes": nodes, "length": float(train["length"]),
			"s": s0, "v": 0.0, "dir": 1.0 if salt < 0.5 else -1.0, "lo": span.x, "hi": span.y,
			"stops": sorted, "dwell": (TRAIN_DWELL_S if platform_only else DWELL_S).x * salt,
			"dwell_range": TRAIN_DWELL_S if platform_only else DWELL_S,
			"cruise": TRAIN_CRUISE_MS if platform_only else CRUISE_MS,
			"salt": salt, "target": NAN, "blocked": 0.0, "moved": false, "age": 0.0, "mid": route.xz_at(s0), "n": 0})

## The run [low, high] (metres along `route`) a train standing at `s0`
## may use: up to `run` each way, and not past a tunnel mouth, the edge
## of the data or the route's own ends.
func _span(route: TramRoute, s0: float, reach: float, run: float, mouths: PackedVector2Array,
		ground: GroundTruth) -> Vector2:
	var lo := s0
	var hi := s0
	for dir in [-1.0, 1.0]:
		var s := s0
		while absf(s - s0) < run:
			var next: float = s + dir * 5.0
			if next < reach or next > route.length_m - reach:
				break
			var p := route.xz_at(next)
			var ok := ground == null or ground.is_inside(p.x, p.y)
			for m in mouths:
				if m.distance_to(p) < (TransitVehicles.TUNNEL_CLEAR_M + reach) * _m2u:
					ok = false
					break
			if not ok:
				break
			s = next
		if dir < 0.0:
			lo = s
		else:
			hi = s
	return Vector2(lo, hi)

## The next stop `t` runs to from where it stands, in its direction
## (turning it round at the end of its run); `s` itself when there is none.
func _next(t: Dictionary) -> float:
	var s := float(t["s"])
	for attempt in 2:
		var dir := float(t["dir"])
		var best := INF
		var found := s
		for stop: float in t["stops"]:
			var d := (stop - s) * dir
			if d > 0.5 and d < best:
				best = d
				found = stop
		if best < INF:
			return found
		t["dir"] = -dir
	return s

## One simulation step of train `t`.
func _step(t: Dictionary, dt: float) -> void:
	if float(t["dwell"]) > 0.0:
		t["dwell"] = float(t["dwell"]) - dt
		return
	var s := float(t["s"])
	var v := float(t["v"])
	if is_nan(float(t["target"])):
		t["target"] = _next(t)
	var dir := float(t["dir"])
	var ahead := (float(t["target"]) - s) * dir
	var limit := sqrt(2.0 * BRAKE_MS2 * maxf(ahead, 0.0))
	# The train ahead on this route, dwelling or not.
	var gap := INF
	for o: Dictionary in _trains:
		if o != t and o["route"] == t["route"]:
			var ds := (float(o["s"]) - s) * dir
			if ds > 0.0:
				var room := ds - (float(o["length"]) + float(t["length"])) * 0.5 - FOLLOW_M
				# One coming the other way closes the gap from both ends:
				# each brakes for half of it.
				if float(o["dir"]) * dir < 0.0 and float(o["v"]) > 0.1:
					room *= 0.5
				gap = minf(gap, room)
	if gap < INF:
		limit = minf(limit, sqrt(2.0 * BRAKE_MS2 * maxf(gap, 0.0)))
	var target_v := minf(float(t["cruise"]), limit)
	if v < target_v:
		v = minf(v + ACCEL_MS2 * dt, target_v)
	else:
		v = maxf(v - BRAKE_MS2 * 1.5 * dt, target_v)
	if gap < INF and gap <= 0.5 and v < 0.05:
		t["blocked"] = float(t["blocked"]) + dt
		if float(t["blocked"]) > BLOCKED_S:
			t["dir"] = -dir
			t["target"] = NAN
			t["blocked"] = 0.0
	else:
		t["blocked"] = 0.0
	if v > 0.0:
		s = clampf(s + v * dt * dir, float(t["lo"]), float(t["hi"]))
		t["s"] = s
		t["moved"] = true
	t["v"] = v
	# Arrived at the stop: stand and dwell.
	ahead = (float(t["target"]) - s) * dir if not is_nan(float(t["target"])) else 1e9
	if ahead <= 0.3 or (ahead < 1.0 and v < 0.3):
		t["s"] = float(t["target"])
		t["v"] = 0.0
		t["moved"] = true
		var n := int(t["n"]) + 1
		t["n"] = n
		var dwell: Vector2 = t["dwell_range"]
		t["dwell"] = lerpf(dwell.x, dwell.y, TransitVehicles._hash(s, float(n), float(t["salt"]) * 10.0))
		t["target"] = NAN

## Puts every section of train `t` where its route says (as
## TransitVehicles._train poses a standing train).
func _pose(t: Dictionary) -> void:
	var route: TramRoute = t["route"]
	var s := float(t["s"])
	var sections: Array = t["sections"]
	var placed := route.place_train(s, sections)
	t["mid"] = route.xz_at(s)
	t["moved"] = false
	var rows: Array = t["nodes"]
	for i in sections.size():
		var pose := placed[i]
		if bool((sections[i] as Dictionary)["flip"]):
			pose.basis = pose.basis * Basis(Vector3.UP, PI)
		pose.basis = pose.basis.scaled(Vector3.ONE * _m2u)
		for node: Node3D in rows[i]:
			node.transform = pose
