class_name StreamScout
extends RefCounted

## Fetches the data of centres WorldStreamer may build next, so their
## builds skip the network: the centre planned straight ahead first,
## then a ring around the live centre one at a time, nearest the heading
## first, so a turn finds its stretch fetched too. Every centre fetched
## or built is remembered (`known`): a later turn towards one builds it
## again from the disk caches. Fetch-only pipelines (warm_only) write
## those caches; the real build reads them.

## Ring centres around the live one, and how far out they sit: inside
## the step range WorldStreamer.use_plan accepts.
const RING_DIRS := 8
const RING_M := 1100.0
## Ring centres fetched per live centre, at most (nearest the heading):
## each costs a round of Overpass queries, and a U-turn is covered by
## WorldStreamer's parked worlds instead.
const RING_FETCH_MAX := 4
## Faster than this, no ring is fetched: it is insurance for a turn, its
## five Postpass requests a centre would hold the one slot the build and
## the plan ahead need, and a fast camera is past it before it lands.
const RING_MAX_MPS := 15.0
## Ring centres this close to the heading are left to the plan ahead.
const RING_SKIP_DEG := 30.0
## A ring centre this near a known one is not fetched again.
const NEAR_KNOWN_M := 400.0
## Known centres remembered (lat/lon, newest last), and how far from the
## live centre one may lie and still be kept.
const KNOWN_MAX := 24
const KNOWN_REACH_M := 3000.0

## Centres whose data is on disk or being fetched (lat/lon), newest last.
var known: Array[Vector2] = []
## The centre planned after the one building (lat/lon; INF = none).
var plan_ll := Vector2.INF
## Second step ahead along the same heading on high-memory devices (warm_max >= 2).
var plan2_ll := Vector2.INF
## Centres whose fetch-ahead ran to its end with its map data in hand
## (lat/lon, newest last): only these have it on disk (`known` holds a
## centre from the moment its fetch starts, given up or not).
var fetched: Array[Vector2] = []
var _warms: Array[GenerationPipeline] = []
## Coordinates (lat/lon) of each active warm pipeline, and its bound callbacks
## so take_warm() can promote and detach it cleanly.
var _warm_ll: Dictionary = {}
var _warm_cbs: Dictionary = {}
## Ring centres still to fetch (lat/lon), next first.
var _ring: Array[Vector2] = []

## Ring centres around (`lat`, `lon`) for a camera heading `heading`
## (XZ; zero = no preference), nearest the heading first, without those
## straight ahead or near a known centre.
func ring_around(lat: float, lon: float, heading: Vector2) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	var h := heading.normalized()
	for i in RING_DIRS:
		var a := TAU * float(i) / float(RING_DIRS)
		var d := Vector2(sin(a), -cos(a))
		if h != Vector2.ZERO and h.dot(d) > cos(deg_to_rad(RING_SKIP_DEG)):
			continue
		dirs.append(d)
	if h != Vector2.ZERO:
		dirs.sort_custom(func(a: Vector2, b: Vector2) -> bool: return h.dot(a) > h.dot(b))
	var out: Array[Vector2] = []
	for d in dirs:
		var xz := d * RING_M
		if not _near_known(xz, lat, lon):
			out.append(WorldScale.latlon_from_xz(xz.x, xz.y, lat, lon))
	return out.slice(0, RING_FETCH_MAX)

func _near_known(xz: Vector2, lat: float, lon: float) -> bool:
	for k in known:
		if WorldScale.xz_from_latlon(k.x, k.y, lat, lon).distance_to(xz) < NEAR_KNOWN_M:
			return true
	return false

## Remembers `ll` as known (newest), forgetting the oldest beyond KNOWN_MAX.
func note(ll: Vector2) -> void:
	_ring.erase(ll)  # built or fetched: not fetched again
	known.erase(ll)
	known.append(ll)
	while known.size() > KNOWN_MAX:
		known.pop_front()

## The known centre (lat/lon) best suited to a camera at `pos` heading
## `dir`, in the frame of the live centre (`lat`, `lon`): the plan
## first, then the newest known one WorldStreamer.use_plan accepts, never
## the live centre itself. INF when none suits.
func pick(pos: Vector2, dir: Vector2, lat: float, lon: float) -> Vector2:
	var order: Array[Vector2] = []
	if plan_ll != Vector2.INF:
		order.append(plan_ll)
	for i in range(known.size() - 1, -1, -1):
		order.append(known[i])
	for ll in order:
		var xz := WorldScale.xz_from_latlon(ll.x, ll.y, lat, lon)
		if xz.length() > WorldStreamer.STEP_M * 0.5 and WorldStreamer.use_plan(xz, pos, dir):
			return ll
	return Vector2.INF

## Plans the centre after `target` (one more step the same way, `step`
## metres, on the StreamLattice) and queues its data first: `pump`
## fetches it once the build's own data is in, never beside it (one
## Postpass request runs at a time, and the build's come first).
func plan(v: View360, pos: Vector2, target: Vector2, step: float) -> void:
	var dir := (target - pos).normalized()
	if dir == Vector2.ZERO:
		return
	var next := target + dir * step
	_ring.erase(plan_ll)  # the plan it replaces is no longer wanted
	_ring.erase(plan2_ll)
	plan_ll = StreamLattice.snap(
		WorldScale.latlon_from_xz(next.x, next.y, v._data.latitude, v._data.longitude))
	plan2_ll = Vector2.INF
	if warm_max() >= 2:
		var next2 := next + dir * step
		var ll2 := StreamLattice.snap(
			WorldScale.latlon_from_xz(next2.x, next2.y, v._data.latitude, v._data.longitude))
		if ll2 != plan_ll and not ll2 in known:
			plan2_ll = ll2
			_ring.erase(plan2_ll)
			_ring.push_front(plan2_ll)
	_ring.erase(plan_ll)
	_ring.push_front(plan_ll)

## A new live centre (`lat`, `lon`): queue its ring, nearest `heading`
## first, and forget known centres too far to be picked again.
func survey(lat: float, lon: float, heading: Vector2) -> void:
	for i in range(known.size() - 1, -1, -1):
		if WorldScale.xz_from_latlon(known[i].x, known[i].y, lat, lon).length() > KNOWN_REACH_M:
			known.remove_at(i)
	_ring = []
	if plan_ll != Vector2.INF and not plan_ll in known:
		_ring.append(plan_ll)  # still to fetch: ahead of the ring
	if plan2_ll != Vector2.INF and plan2_ll != plan_ll and not plan2_ll in known:
		_ring.append(plan2_ll)
	for ll in ring_around(lat, lon, heading) if heading.length() <= RING_MAX_MPS else []:
		var s := StreamLattice.snap(ll)
		if not s in _ring and not s in known:
			_ring.append(s)

## Starts the plan ahead, then the next ring fetch while a pipeline slot is
## free and the streamer's own build is not on the network (`net_busy`).
## Throttles warm concurrency under memory pressure so scouts never push
## dense city flights into MemoryGuard TIGHT/EMERGENCY.
func pump(v: View360, net_busy: bool, urgent_busy: bool = false) -> void:
	var cap := warm_max()
	if cap == 0 and not _warms.is_empty():
		# Memory is short: each holds a stretch's data. The ring stays,
		# to be fetched once there is room again.
		for w in _warms.duplicate():
			_end_warm(w, true)
	if _ring.is_empty() or cap == 0 or net_busy or urgent_busy or WorldCache.saving_any():
		return
	var ll: Vector2 = _ring[0]
	var is_plan := ll == plan_ll or ll == plan2_ll
	if (not is_plan and not _warms.is_empty()) or (is_plan and _warms.size() >= cap):
		return
	_ring.pop_front()
	if ll in known:
		return
	while _warms.size() >= cap:
		_end_warm(_warms[0], true)
	_warm(v, ll, "a stretch ahead" if is_plan else "a stretch around")

## Adopts an in-flight warm pipeline for `ll`, promoting it to a live streamed
## run so WorldStreamer keeps its in-flight network progress instead of
## re-fetching from scratch. Returns null when none is running for `ll`.
func take_warm(ll: Vector2, fallback_far: Dictionary = {}) -> GenerationPipeline:
	for w in _warms:
		if is_instance_valid(w) and _warm_ll.get(w, Vector2.INF) == ll:
			if not w.promote_to_live(fallback_far):
				return null
			var cbs: Array = _warm_cbs.get(w, [])
			if cbs.size() == 2:
				if w.finished.is_connected(cbs[0]):
					w.finished.disconnect(cbs[0])
				if w.cancelled.is_connected(cbs[1]):
					w.cancelled.disconnect(cbs[1])
			_warms.erase(w)
			_warm_ll.erase(w)
			_warm_cbs.erase(w)
			return w
	return null

func _warm(v: View360, ll: Vector2, what: String) -> void:
	note(ll)
	var warm := GenerationPipeline.new()
	warm.background = true
	warm.warm_only = true
	v.add_child(warm)
	_warms.append(warm)
	_warm_ll[warm] = ll
	var t0 := Time.get_ticks_msec()
	var on_done := func(_d: LocationData) -> void:
		WorldStreamer._log("STREAM warm: %s fetched in %.1f s" % [what,
			(Time.get_ticks_msec() - t0) / 1000.0])
		if warm.map_landed():
			fetched.erase(ll)
			fetched.append(ll)
			while fetched.size() > KNOWN_MAX:
				fetched.pop_front()
		_end_warm(warm, false)
	var on_cancel := func() -> void: _end_warm(warm, false)
	_warm_cbs[warm] = [on_done, on_cancel]
	warm.finished.connect(on_done)
	warm.cancelled.connect(on_cancel)
	warm.run(ll.x, ll.y, "", v._quality_preset)

func _end_warm(warm: GenerationPipeline, stop_it: bool) -> void:
	_warms.erase(warm)
	_warm_ll.erase(warm)
	_warm_cbs.erase(warm)
	if is_instance_valid(warm):
		if stop_it:
			warm.cancel()
		warm.queue_free()

## What the streamer's start line says of a centre picked from here:
## `planned` it was the plan ahead, else one known from before.
func start_note(ll: Vector2, planned: bool, reused: bool, adopted := false) -> String:
	if adopted:
		return ", adopted fetch ahead"
	if planned:
		return ", fetched ahead" if ll in fetched else ", fetch ahead not landed"
	return ", reused" if reused else ""

## Fetch-only pipelines at once, at most (the oldest stops for a newer
## plan, so a twisting flight cannot pile them up): the device's tier
## (MemoryBudget.WARM_MAX), throttled early under memory pressure so scouts
## never trip MemoryGuard TIGHT/EMERGENCY during dense city builds.
static func warm_max() -> int:
	if MemoryGuard.level >= MemoryGuard.Level.TIGHT:
		return 0
	var base: int = MemoryBudget.WARM_MAX[MemoryBudget.tier()]
	if DisplayServer.get_name() == "headless":
		return base
	var u := MemoryBudget.usage()
	if u >= 0.65:
		return mini(base, 1)
	return base

## Stops every fetch and the ring (the plan is forgotten too).
func stop() -> void:
	for w in _warms.duplicate():
		_end_warm(w, true)
	_ring.clear()
	plan_ll = Vector2.INF
	plan2_ll = Vector2.INF

## A new place: nothing known carries over.
func clear() -> void:
	stop()
	known.clear()
	fetched.clear()
