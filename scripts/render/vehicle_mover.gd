class_name VehicleMover
extends RefCounted

## Drives the trams, and the trains standing at platforms, along their
## track. The built world only carries the meshes (it is cached as a
## scene, TransitVehicles / StationTrains name them); the mover plans the
## same trains again from the same data, finds their nodes by name and
## moves them, each accelerating to a cruising speed and keeping clear
## of the train ahead.
## * A tram never stops on the line: only at a mapped tram stop (it
##   dwells) and at a red traffic light. Each track runs one way (the
##   driving side against its twin track), so trams never meet head-on;
##   at the end of its run (a tunnel mouth, the edge of the data, the
##   route's end) a tram leaves and comes back in at the start of its
##   track once that is clear.
## * A platform train brakes to a stop at its stops (or every few hundred
##   metres where none are mapped), dwells, and carries on, turning round
##   at the end of its run; a terminus train keeps standing at its buffers.
##
## Time is the sum of the deltas given to tick(), so a test or a capture
## steps it exactly. Traffic is the world going about its day, like the
## clouds' drift: reduced motion (camera flights and UI springs) leaves
## it running.

const CRUISE_MS := 8.0
const TRAIN_CRUISE_MS := 10.0
const ACCEL_MS2 := 0.9
const BRAKE_MS2 := 1.1
## How far a platform train runs from where it stands (metres, each way).
const TRAIN_RUN_M := 220.0
## A platform train's pseudo stops where none are mapped, and the dwell
## at any stop.
const STOP_EVERY_M := 180.0
const DWELL_S := Vector2(10.0, 28.0)
const TRAIN_DWELL_S := Vector2(30.0, 80.0)
## Clear gap kept to the train ahead (metres), and how long a platform
## train held up this way waits before it turns round.
const FOLLOW_M := 10.0
const BLOCKED_S := 6.0
## Twin tracks of one line lie at most this far apart (metres), running
## alongside (within TWIN_DEG); a track nearer than TramRoute.SAME_RAIL_M
## is the same rail (a switch). Which side the twin is on is voted at
## DIR_SAMPLES points along a track.
const TWIN_M := 8.0
const TWIN_DEG := 25.0
const DIR_SAMPLES := 7
## A traffic light stops a tram when it stands this close to the track
## (metres); its cycle (s) and the share of it that is red, and how close
## two lights stand to count as one junction (metres).
const SIGNAL_SNAP_M := 10.0
const SIGNAL_CYCLE_S := 60.0
const SIGNAL_RED := 0.45
const SIGNAL_MERGE_M := 20.0
## The trams on the tracks over a registry bridge's deck (one each way,
## TransitVehicles) keep a timetable: they pass each other mid-span this
## many seconds after the world appears, and again every cycle.
const MEET_AT_S := 30.0
## Countries driving on the left (ISO 3166-1 alpha-2): their trams keep
## left too.
const LEFT_HAND := ["GB", "IE", "JP", "HK", "MO", "AU", "NZ", "ZA", "IN", "PK", "BD", "LK", "TH",
	"MY", "SG", "ID", "KE", "MT", "CY"]
## Trains farther than this from the eye are moved at a lower rate.
const NEAR_M := 400.0
const FAR_STEP_S := 0.5
## Longest step simulated at once.
const MAX_STEP_S := 0.1
## Nearest moving trams/trains that carry live headlight + taillight pools at night.
const MAX_HEADLIGHT_TRAINS := 8
const HEADLIGHT_ENERGY := 3.2
const TAILLIGHT_ENERGY := 0.9

var _trains: Array = []
var _m2u := 1.0
var _clock := 0.0
## The deck trams' shared cycle (s): the longest of their runs at cruise.
var _deck_cycle := 0.0
var _night_lights := false
var _lights_holder: Node3D
var _lights_source: Node3D

## A mover for the trams and platform trains under `world`, planned from
## `data` as the world was built; null when there are none to move.
static func attach(world: Node, data: LocationData, ground: GroundTruth) -> VehicleMover:
	if world == null or data == null or ground == null or not TransitVehicles.enabled(data.quality_preset):
		return null
	var mover := VehicleMover.new()
	mover._m2u = WorldScale.metres_to_units()
	mover._night_lights = RenderQuality.ultra_desktop(data.quality_preset)
	var planned: Dictionary = data.get_meta(PLANS_META, {}) if data.has_meta(PLANS_GROUND) \
		and data.get_meta(PLANS_GROUND) == ground \
		else {}
	var trams := world.find_child("Trams", true, false)
	if trams != null and not data.railways.is_empty():
		var plan: Array = planned["Tram"] if planned.has("Tram") else TransitVehicles.plan(data, ground, mover._m2u)
		mover._adopt(trams, "Tram", plan, data, ground, false)
		mover._share(planned["TramZones"] if planned.has("TramZones") else zones_of(plan))
	var trains := world.find_child("Trains", true, false)
	if trains != null and not data.railways.is_empty():
		mover._adopt(trains, "Train", planned["Train"] if planned.has("Train")
			else StationTrains.plan(data, ground, mover._m2u), data, ground, true)
	mover._time_deck()
	return mover if not mover._trains.is_empty() else null

## The tram and train plans attach() needs, worked out ahead (pure, so a
## worker may run it: the streamer does while a world waits to swap in,
## sparing the first frames after the swap ~70 ms). Kept on `data` as
## meta for the `ground` they were planned on.
const PLANS_META := &"vehicle_plans"
const PLANS_GROUND := &"vehicle_plans_ground"

static func compute_plans(data: LocationData, ground: GroundTruth) -> Dictionary:
	if data == null or ground == null or data.railways.is_empty() \
			or not TransitVehicles.enabled(data.quality_preset):
		return {}
	var m2u := WorldScale.metres_to_units()
	var trams := TransitVehicles.plan(data, ground, m2u)
	var trains := StationTrains.plan(data, ground, m2u)
	# Each train's run, stops, direction and signals, so attach() on the main
	# thread only adopts them (they walked every route in 5 m steps there).
	var mouths := TramRoute.mouths(data, func(_rail: Dictionary) -> bool: return true)
	var dirs := {}
	for k in trams.size():
		(trams[k] as Dictionary)["motion"] = motion(trams[k], k, trams, data, ground, false, mouths, dirs, m2u)
	for k in trains.size():
		if str((trains[k] as Dictionary).get("at", "")) == "platform":
			(trains[k] as Dictionary)["motion"] = motion(trains[k], k, trains, data, ground, true, mouths, dirs, m2u)
	return {"Tram": trams, "TramZones": zones_of(trams), "Train": trains}

## Where the tracks of the trams of `plan` come close enough for two of
## them to touch (TramRails).
static func zones_of(plan: Array) -> Array:
	var routes: Array = []
	for train: Dictionary in plan:
		if not routes.has(train["route"]):
			routes.append(train["route"])
	return TramRails.zones(routes, WorldScale.metres_to_units())

static func store_plans(data: LocationData, ground: GroundTruth, plans: Dictionary) -> void:
	if data == null or ground == null or plans.is_empty():
		return
	data.set_meta(PLANS_META, plans)
	data.set_meta(PLANS_GROUND, ground)

static func plan_ahead(data: LocationData, ground: GroundTruth) -> void:
	store_plans(data, ground, compute_plans(data, ground))

## How many trains this mover drives.
func count() -> int:
	return _trains.size()

## Each train as a walker solid (building-shaped dict, 3 m wide over
## its whole length at where it stands now): a walker must not pass
## through a tram or a train standing at its platform.
func walker_solids() -> Array:
	var out: Array = []
	for t: Dictionary in _trains:
		if bool(t["hidden"]):
			continue
		var route: TramRoute = t["route"]
		var s := float(t["s"])
		var mid := route.xz_at(s)
		var ahead := route.xz_at(minf(s + 2.0, route.length_m))
		var behind := route.xz_at(maxf(s - 2.0, 0.0))
		var f := (ahead - behind)
		if f == Vector2.ZERO:
			f = Vector2(1, 0)
		f = f.normalized()
		var side := Vector2(-f.y, f.x)
		var hl := f * float(t["length"]) * 0.5
		var hw := side * 1.5
		out.append({"footprint": PackedVector2Array([mid - hl - hw, mid + hl - hw,
			mid + hl + hw, mid - hl + hw]), "x": mid.x, "z": mid.y, "kind": "tram"})
	return out

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
	if _trains.is_empty():
		return
	var left := maxf(delta, 0.0)
	while left > 0.0:
		var dt := minf(left, MAX_STEP_S)
		left -= dt
		_clock += dt
		for t: Dictionary in _trains:
			_step(t, dt)
	var night := StreetGlow.night
	for t: Dictionary in _trains:
		var near := (t["mid"] as Vector2).distance_to(eye) < NEAR_M * _m2u
		t["age"] = float(t["age"]) + delta
		if bool(t["moved"]) and (near or float(t["age"]) >= FAR_STEP_S):
			_pose(t)
			t["age"] = 0.0
		_sync_vehicle_lights(t, night)

func stop() -> void:
	_trains.clear()
	if _lights_holder != null and is_instance_valid(_lights_holder):
		_lights_holder.queue_free()
	_lights_holder = null
	_lights_source = null

## What a train's motion needs of the map, worked out from the plan and the
## data alone (so compute_plans can do it on a worker, ahead of the swap):
## "span" its run (_span), "salt", "stops" (sorted: a tram's mapped stops it
## snaps to, a platform train's every STOP_EVERY_M), "dir", "deck_mid" and
## "signals". `dirs` keeps each route's way (_track_dir) across the trains of
## one plan.
static func motion(train: Dictionary, k: int, plan: Array, data: LocationData, ground: GroundTruth,
		platform_only: bool, mouths: PackedVector2Array, dirs: Dictionary, m2u: float) -> Dictionary:
	var route: TramRoute = train["route"]
	var s0 := float(train["s"])
	var reach := float(train["length"]) * 0.5 + 1.0
	var run := TRAIN_RUN_M if platform_only else INF
	var span := span_of(route, s0, reach, run, mouths, ground, m2u)
	var salt := TransitVehicles._hash(float(k), s0, 41.0 if platform_only else 17.0)
	var stops := PackedFloat32Array()
	if not platform_only:
		for stop in data.tram_stops:
			if not (stop is Dictionary):
				continue
			var at := route.nearest(Vector2(float(stop.get("x", 0.0)), float(stop.get("z", 0.0))))
			if at.y < TransitVehicles.SNAP_M and at.x > span.x and at.x < span.y:
				stops.append(at.x)
	else:
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
	if not platform_only and not dirs.has(route):
		dirs[route] = _track_dir(route, plan, data.country)
	return {"span": span, "salt": salt, "stops": sorted,
		"dir": (1.0 if salt < 0.5 else -1.0) if platform_only else float(dirs[route]),
		"deck_mid": NAN if platform_only else _deck_mid(route),
		"signals": PackedFloat32Array() if platform_only else _signals(route, span, data)}

## Takes the trains of `plan` whose nodes `holder` has (named `prefix`
## + train + "_" + section + "_near" / "_far" / "_shadow").
func _adopt(holder: Node, prefix: String, plan: Array, data: LocationData, ground: GroundTruth,
		platform_only: bool) -> void:
	var mouths := TramRoute.mouths(data, func(_rail: Dictionary) -> bool: return true)
	var dirs := {}
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
		# Worked out ahead on a worker (compute_plans) when there is a plan for
		# this world, else here.
		var mo: Dictionary = train["motion"] if train.has("motion") \
			else motion(train, k, plan, data, ground, platform_only, mouths, dirs, _m2u)
		var span: Vector2 = mo["span"]
		var salt: float = mo["salt"]
		var sorted: Array = mo["stops"]
		# A tram starts off at once unless it stands at a stop.
		var at_stop := platform_only
		for stop: float in sorted:
			at_stop = at_stop or absf(stop - s0) < 3.0
		_trains.append({
			"route": route, "sections": sections, "nodes": nodes, "length": float(train["length"]),
			"s": s0, "v": 0.0, "lo": span.x, "hi": span.y,
			"dir": mo["dir"],
			"stops": sorted, "dwell": (TRAIN_DWELL_S if platform_only else DWELL_S).x * salt if at_stop else 0.0,
			"dwell_range": TRAIN_DWELL_S if platform_only else DWELL_S,
			"cruise": TRAIN_CRUISE_MS if platform_only else CRUISE_MS,
			"loop": not platform_only, "hidden": false,
			"deck_mid": mo["deck_mid"],
			"signals": mo["signals"],
			"salt": salt, "target": NAN, "blocked": 0.0, "moved": false, "age": 0.0, "mid": route.xz_at(s0), "n": 0,
			"zones": [], "claims": {},
			"headlight": null, "taillight": null})
		if _night_lights and _trains.size() <= MAX_HEADLIGHT_TRAINS:
			_attach_vehicle_lights(holder, _trains[_trains.size() - 1])

## Hands each tram the zones of `zones` (TramRails) its track is in.
func _share(zones: Array) -> void:
	for t: Dictionary in _trains:
		if bool(t["loop"]):
			t["zones"] = TramRails.of(t["route"], zones)

## The way trams run along `route` (1 with its points, -1 against them):
## the driving side of `country` against its twin track (the nearest
## other route of `plan` alongside it within TWIN_M, voted at DIR_SAMPLES
## points along the route; one nearer than TramRoute.SAME_RAIL_M there is
## on the same rail, not its twin, and one crossing it is no twin), or one
## hashed way for a single track; every tram on the track runs the same way.
static func _track_dir(route: TramRoute, plan: Array, country: String) -> float:
	var others: Array = []
	var boxes: Array[Rect2] = []
	for o: Dictionary in plan:
		var other: TramRoute = o["route"]
		if other != route and not others.has(other):
			others.append(other)
			var box := Rect2(other.points[0], Vector2.ZERO)
			for q in other.points:
				box = box.expand(q)
			boxes.append(box.grow(TWIN_M * WorldScale.metres_to_units()))
	var vote := 0
	var mid_vote := 0
	for k in DIR_SAMPLES:
		var at := route.length_m * (float(k) + 0.5) / float(DIR_SAMPLES)
		var p := route.xz_at(at)
		var f := route.xz_at(at + 2.0) - route.xz_at(at - 2.0)
		var best := INF
		var side := 0.0
		for n in others.size():
			if not boxes[n].has_point(p):
				continue
			var other: TramRoute = others[n]
			var near := other.nearest(p)
			var g := other.xz_at(near.x + 2.0) - other.xz_at(near.x - 2.0)
			if near.y >= TramRoute.SAME_RAIL_M and near.y < TWIN_M and near.y < best \
					and absf(f.normalized().dot(g.normalized())) > cos(deg_to_rad(TWIN_DEG)):
				best = near.y
				# > 0: the twin lies to the right of the route's own direction.
				side = (other.xz_at(near.x) - p).dot(Vector2(-f.y, f.x))
		if best < INF:
			vote += 1 if side > 0.0 else -1
			if k == DIR_SAMPLES >> 1:
				mid_vote = 1 if side > 0.0 else -1
	# A tie goes the way the twin lies at the middle.
	vote = vote if vote != 0 else mid_vote
	if vote == 0:
		var p := route.xz_at(route.length_m * 0.5)
		return 1.0 if TransitVehicles._hash(p.x, p.y, 23.0) < 0.5 else -1.0
	var keep_right := not (country in LEFT_HAND)
	# Driving on the right, a track with its twin on its left runs forward.
	var forward := vote < 0 if keep_right else vote > 0
	return 1.0 if forward else -1.0

## Where traffic lights stand along `route` within `span` (metres): one
## per junction, from the mapped signals close to the track.
static func _signals(route: TramRoute, span: Vector2, data: LocationData) -> PackedFloat32Array:
	var found: Array = []
	for f in data.street_furniture:
		if not (f is Dictionary) or str(f.get("kind", "")) != "signals":
			continue
		var at := route.nearest(Vector2(float(f.get("x", 0.0)), float(f.get("z", 0.0))))
		if at.y < SIGNAL_SNAP_M and at.x > span.x and at.x < span.y:
			found.append(at.x)
	found.sort()
	var out := PackedFloat32Array()
	for s: float in found:
		if out.is_empty() or s - out[out.size() - 1] > SIGNAL_MERGE_M:
			out.append(s)
	return out

## Whether the light at `s` metres along `route` shows red now (each
## junction on its own hashed phase of SIGNAL_CYCLE_S).
func _red(route: TramRoute, s: float) -> bool:
	var p := route.xz_at(s)
	var phase := fposmod(_clock + TransitVehicles._hash(p.x, p.y, 31.0) * SIGNAL_CYCLE_S, SIGNAL_CYCLE_S)
	return phase < SIGNAL_CYCLE_S * SIGNAL_RED

## The run [low, high] (metres along `route`) a train standing at `s0`
## may use: up to `run` each way, and not past a tunnel mouth, the edge
## of the data, a bridge with no known deck or the route's own ends.
static func span_of(route: TramRoute, s0: float, reach: float, run: float, mouths: PackedVector2Array,
		ground: GroundTruth, m2u: float) -> Vector2:
	var lo := s0
	var hi := s0
	for dir in [-1.0, 1.0]:
		var s := s0
		while absf(s - s0) < run:
			var next: float = s + dir * 5.0
			if next < reach or next > route.length_m - reach:
				break
			var p := route.xz_at(next)
			# Never onto a bridge whose deck height is unknown.
			var ok := (ground == null or ground.is_inside(p.x, p.y)) \
				and not route.unsupported(next - reach, next + reach)
			for m in mouths:
				if m.distance_to(p) < (TransitVehicles.TUNNEL_CLEAR_M + reach) * m2u:
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

func _span(route: TramRoute, s0: float, reach: float, run: float, mouths: PackedVector2Array,
		ground: GroundTruth) -> Vector2:
	return span_of(route, s0, reach, run, mouths, ground, _m2u)

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
	if not is_nan(float(t["deck_mid"])) and _deck_cycle > 0.0:
		_keep_time(t)
		return
	if bool(t["hidden"]):
		_enter(t)
		return
	if float(t["dwell"]) > 0.0:
		t["dwell"] = float(t["dwell"]) - dt
		return
	var s := float(t["s"])
	var v := float(t["v"])
	var loop := bool(t["loop"])
	if is_nan(float(t["target"])):
		t["target"] = _next_stop(t) if loop else _next(t)
	var dir := float(t["dir"])
	var ahead := (float(t["target"]) - s) * dir
	# A tram runs on through the end of its run (it leaves there).
	var limit := INF if loop and is_inf(ahead) else sqrt(2.0 * BRAKE_MS2 * maxf(ahead, 0.0))
	# The train ahead on this route, dwelling or not.
	var gap := INF
	for o: Dictionary in _trains:
		if o != t and o["route"] == t["route"] and not bool(o["hidden"]):
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
	if loop:
		limit = minf(limit, _light_limit(t, s, v, dir))
		# Another route's tram where the tracks meet: wait for it to pass.
		limit = minf(limit, TramRails.limit(t, _trains, dt, BRAKE_MS2, limit))
	var target_v := minf(float(t["cruise"]), limit)
	if v < target_v:
		v = minf(v + ACCEL_MS2 * dt, target_v)
	else:
		v = maxf(v - BRAKE_MS2 * 1.5 * dt, target_v)
	if not loop and gap < INF and gap <= 0.5 and v < 0.05:
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
	# Out at the end of its run: it leaves, and comes back in at the start.
	if loop and (s <= float(t["lo"]) + 0.01 if dir < 0.0 else s >= float(t["hi"]) - 0.01):
		t["hidden"] = true
		t["moved"] = true
		t["target"] = NAN
		return
	# Arrived at the stop: stand and dwell.
	ahead = (float(t["target"]) - s) * dir if not is_nan(float(t["target"])) else 1e9
	if ahead <= 0.3 or (ahead < 1.0 and v < 0.3):
		t["s"] = float(t["target"])
		t["v"] = 0.0
		t["moved"] = true
		TramRails.release(t)
		var n := int(t["n"]) + 1
		t["n"] = n
		var dwell: Vector2 = t["dwell_range"]
		t["dwell"] = lerpf(dwell.x, dwell.y, TransitVehicles._hash(s, float(n), float(t["salt"]) * 10.0))
		t["target"] = NAN

## The next mapped stop ahead of tram `t`, or INF past the end of its run
## when there is none (it never turns round).
func _next_stop(t: Dictionary) -> float:
	var s := float(t["s"])
	var dir := float(t["dir"])
	var best := INF
	var found := INF * dir
	for stop: float in t["stops"]:
		var d := (stop - s) * dir
		if d > 0.5 and d < best:
			best = d
			found = stop
	return found

## Speed limit (m/s) for tram `t` at `s`, `v`, heading `dir` from the next
## traffic light ahead: brake to stand at it while it shows red, unless
## too close to stop (it goes through on amber); INF otherwise.
func _light_limit(t: Dictionary, s: float, v: float, dir: float) -> float:
	var front := s + dir * float(t["length"]) * 0.5
	var d := INF
	var sig := 0.0
	for at: float in t["signals"]:
		var ahead := (at - front) * dir
		if ahead >= -0.5 and ahead < d:
			d = ahead
			sig = at
	if d > CRUISE_MS * CRUISE_MS / (2.0 * BRAKE_MS2) + 20.0:
		return INF
	if not _red(t["route"], sig) or v * v / (2.0 * BRAKE_MS2) > d + 0.5:
		return INF
	return sqrt(2.0 * BRAKE_MS2 * maxf(d - 0.5, 0.0))

## A tram that left at the end of its run comes back in at its start,
## running, once that stretch is clear of the tram before it.
func _enter(t: Dictionary) -> void:
	var dir := float(t["dir"])
	var start := float(t["lo"]) if dir > 0.0 else float(t["hi"])
	for o: Dictionary in _trains:
		if o != t and o["route"] == t["route"] and not bool(o["hidden"]):
			var room := (float(o["s"]) - start) * dir - (float(o["length"]) + float(t["length"])) * 0.5 - FOLLOW_M
			if room < float(t["cruise"]) * float(t["cruise"]) / (2.0 * BRAKE_MS2):
				return
	if not TramRails.can_enter(t, _trains, start, dir, float(t["cruise"]), BRAKE_MS2, MAX_STEP_S):
		return
	t["hidden"] = false
	t["s"] = start
	t["v"] = float(t["cruise"])
	t["target"] = NAN
	t["moved"] = true

## Where `route` crosses the middle of a registry bridge's deck (metres
## along it), or NAN off every deck: the middle of its stretch with deck
## heights (BridgeTramDeck).
static func _deck_mid(route: TramRoute) -> float:
	var lo := INF
	var hi := -INF
	for k in route.heights.size():
		if not is_nan(route.heights[k]):
			lo = minf(lo, route.cum[k])
			hi = maxf(hi, route.cum[k])
	return (lo + hi) * 0.5 / WorldScale.metres_to_units() if lo < INF else NAN

## The deck trams' shared cycle: the longest of their runs at cruise, so
## each is back at the deck's middle in step with the others.
func _time_deck() -> void:
	_deck_cycle = 0.0
	for t: Dictionary in _trains:
		if not is_nan(float(t["deck_mid"])):
			_deck_cycle = maxf(_deck_cycle, (float(t["hi"]) - float(t["lo"])) / float(t["cruise"]) + 2.0)

## A deck tram on the timetable: at the deck's middle at MEET_AT_S and
## every _deck_cycle after, running at cruise either side of it; off its
## run (it has left) for the rest of the cycle.
func _keep_time(t: Dictionary) -> void:
	var u := fposmod(_clock - MEET_AT_S + _deck_cycle * 0.5, _deck_cycle) - _deck_cycle * 0.5
	var s := float(t["deck_mid"]) + float(t["dir"]) * float(t["cruise"]) * u
	var gone := s < float(t["lo"]) or s > float(t["hi"])
	t["hidden"] = gone
	t["v"] = 0.0 if gone else float(t["cruise"])
	t["s"] = clampf(s, float(t["lo"]), float(t["hi"]))
	t["moved"] = true

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
			node.visible = not bool(t["hidden"])
	_pose_vehicle_lights(t, placed, sections)

func _attach_vehicle_lights(holder: Node, t: Dictionary) -> void:
	if _lights_holder == null or not is_instance_valid(_lights_holder):
		_lights_holder = Node3D.new()
		_lights_holder.name = "VehicleLights"
		# Attach outside the cached world subtree (onto world_root when
		# present) so cached vs live world node counts match exactly.
		var world_parent := holder.get_parent().get_parent() if holder.get_parent() != null else null
		(world_parent if world_parent != null else holder).add_child(_lights_holder)
		_lights_source = holder as Node3D
		if world_parent != null:
			# By id, not by node: stop() frees the lights before an old world's
			# holder leaves the tree, and a freed capture is an engine error.
			var lh_id := _lights_holder.get_instance_id()
			holder.tree_exited.connect(func() -> void:
				var lh := instance_from_id(lh_id) as Node
				if lh == null:
					return
				lh.queue_free()
				if _lights_holder == lh:
					_lights_holder = null
			, Object.CONNECT_ONE_SHOT)
	var lights := _lights_holder
	var head := SpotLight3D.new()
	head.light_color = Color(1.0, 0.94, 0.82)
	head.light_energy = 0.0
	head.light_volumetric_fog_energy = 1.8
	head.spot_range = 26.0 * _m2u
	head.spot_angle = 40.0
	head.spot_attenuation = 1.1
	head.shadow_enabled = false
	head.distance_fade_enabled = true
	head.distance_fade_begin = 160.0 * _m2u
	head.distance_fade_length = 50.0 * _m2u
	head.visible = false
	lights.add_child(head)
	var tail := OmniLight3D.new()
	tail.light_color = Color(1.0, 0.14, 0.10)
	tail.light_energy = 0.0
	tail.omni_range = 5.0 * _m2u
	tail.omni_attenuation = 1.4
	tail.shadow_enabled = false
	tail.distance_fade_enabled = true
	tail.distance_fade_begin = 160.0 * _m2u
	tail.distance_fade_length = 50.0 * _m2u
	tail.visible = false
	lights.add_child(tail)
	t["headlight"] = head
	t["taillight"] = tail
	var placed := (t["route"] as TramRoute).place_train(float(t["s"]), t["sections"] as Array)
	_pose_vehicle_lights(t, placed, t["sections"] as Array)
	_sync_vehicle_lights(t, StreetGlow.night)

func _pose_vehicle_lights(t: Dictionary, placed: Array, sections: Array) -> void:
	var head := t["headlight"] as SpotLight3D
	var tail := t["taillight"] as OmniLight3D
	if head == null or tail == null or placed.is_empty():
		return
	if _lights_holder != null and is_instance_valid(_lights_holder) \
			and _lights_source != null and is_instance_valid(_lights_source) \
			and _lights_holder.is_inside_tree() and _lights_source.is_inside_tree() \
			and _lights_holder.get_parent() != _lights_source:
		_lights_holder.global_transform = _lights_source.global_transform
	var forward := float(t["dir"]) >= 0.0
	var lead_i := 0 if forward else sections.size() - 1
	var rear_i := sections.size() - 1 if forward else 0
	var lead_pose: Transform3D = placed[lead_i]
	var rear_pose: Transform3D = placed[rear_i]
	var lead_half := float((sections[lead_i] as Dictionary)["len"]) * 0.5 * _m2u
	var rear_half := float((sections[rear_i] as Dictionary)["len"]) * 0.5 * _m2u
	var lead_fwd := (lead_pose.basis.x if forward else -lead_pose.basis.x).normalized()
	var rear_back := (-rear_pose.basis.x if forward else rear_pose.basis.x).normalized()
	var up := lead_pose.basis.y.normalized()
	var head_pos := lead_pose.origin + lead_fwd * (lead_half + 0.15 * _m2u) + up * 1.15 * _m2u
	# SpotLight3D shines along -Z; aim along lead_fwd pitched slightly down onto the track.
	var aim := (lead_fwd - up * 0.18).normalized()
	var right := aim.cross(up).normalized()
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	head.transform = Transform3D(Basis(right, right.cross(aim).normalized(), -aim), head_pos)
	tail.position = rear_pose.origin + rear_back * (rear_half + 0.2 * _m2u) + rear_pose.basis.y.normalized() * 1.15 * _m2u

func _sync_vehicle_lights(t: Dictionary, night: float) -> void:
	var head := t["headlight"] as SpotLight3D
	var tail := t["taillight"] as OmniLight3D
	if head == null or tail == null:
		return
	var on := night > 0.02 and not bool(t["hidden"])
	head.visible = on
	tail.visible = on
	if on:
		head.light_energy = HEADLIGHT_ENERGY * night
		tail.light_energy = TAILLIGHT_ENERGY * night
