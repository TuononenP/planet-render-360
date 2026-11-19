class_name StreamDetail
extends RefCounted

## Endless walk & fly: the detail layer of a streamed stretch (street
## props, ground cover, rocks: WorldBuildGraph.build_detail), built on
## its own thread once the stretch's core world is ready, and handed to
## that world wherever it is by then: still detached (being ranged),
## staged hidden, parked, or already live. So the detail never holds a
## swap the camera needs now; when the camera can wait, the swap waits
## for it (holds) and nothing is seen arriving late.
##
## One pass at a time, and never beside a world build or the altitude far
## rebuild: they share static caches. View360.build_location brackets its
## build with enter_build / exit_build: no pass starts in between, and a
## pass already on its thread is waited for, or stopped and queued again
## when the build cannot wait (a place opening, a stretch the camera is
## about to run out of ground for). AltitudeReach sees the thread in
## View360._threads. Driven by tick(), never awaited, so a view going
## away joins the thread itself (View360._notification).

## Stretches whose detail is still to build, next first:
## {world, data, ground, keep, gen}.
var _queue: Array = []
## The pass on its thread ({} none), its thread and stop request.
var _job: Dictionary = {}
var _thread: Thread
var _abort: BuildAbort
## Stopped for a build that could not wait: queued again once joined.
var _again := false
## World builds entered and not left yet.
var _builds := 0
var _t0 := 0
var _last_us := 0
## Worlds in the tree whose late pieces are still joining. Once they are
## all in, the shown world's trams and trains go to a new VehicleMover
## and its night lights look for the new lamps.
var _joining: Array = []
## Fades late pieces into a world already shown, and the world it last
## did so for.
var _reveal := RevealWave.new()
var _faded: Node3D

## Whether a pass is on its thread or waiting for one.
func busy() -> bool:
	return _thread != null or not _queue.is_empty()

## Whether `world`'s detail is still to build, building, or joining it.
func holds(world: Node3D, handoff: WorldHandoff) -> bool:
	if world == null:
		return false
	return is_same(_job.get("world"), world) or handoff.late_pending(world) \
		or _queue.any(func(j: Dictionary) -> bool: return is_same(j["world"], world))

## Queues the detail `abort` kept for `world` (BuildAbort.detail; none when
## its build made everything at once), to build for `data` on `ground`.
func start(world: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort, gen: int) -> void:
	if abort == null or abort.detail.is_empty() or world == null:
		return
	_queue.append({"world": world, "data": data, "ground": ground, "keep": abort.detail, "gen": gen})
	abort.detail = {}

## Drops every pass but `keep`'s (the shown world's: it stays up through
## a season change, and keeps its detail if that rebuild is given up).
## The pass on its thread is stopped and tick() still joins it; with
## `forget` (the view is going away and joins the thread itself) it is
## let go here.
func cancel(forget := false, keep: Node3D = null) -> void:
	_queue = _queue.filter(func(j: Dictionary) -> bool: return keep != null and is_same(j["world"], keep))
	if _abort != null and not (keep != null and is_same(_job.get("world"), keep)):
		_abort.requested = true
		_again = false
	if forget:
		_reveal.finish(_reveal._preset)
		_joining.clear()
		_faded = null
		_thread = null
		_abort = null
		_job = {}

## A build is starting on the main thread right now and cannot wait a
## frame (View360._rebuild_world without a prebuilt world): the pass on
## its thread is stopped and outwaited here, the main thread answering
## its rendering-server calls meanwhile; tick() joins it and queues it
## again.
func halt() -> void:
	if _thread == null:
		return
	if not _abort.requested:
		_abort.requested = true
		_again = true
	while _thread.is_alive():
		RenderingServer.force_sync()
		OS.delay_msec(1)

## A world build is about to start on `v` (View360.build_location, with
## its `abort`): from here to exit_build no pass starts, the one on its
## thread ends first, and so does an altitude far build that began
## meanwhile. A build that cannot wait (not the streamer's, or one the
## camera is about to run out of ground for) stops the pass; it is built
## again after the build.
func enter_build(v: View360, abort: BuildAbort) -> void:
	_builds += 1
	while is_instance_valid(v) and v.is_inside_tree() and (_thread != null or v._reach.building()):
		v._reach.abort_build()
		if _thread != null and not _abort.requested \
				and (abort == null or not abort.background or abort.urgent):
			_abort.requested = true
			_again = true
		await v.get_tree().process_frame

func exit_build() -> void:
	_builds = maxi(_builds - 1, 0)

## The queued pass to build next: the shown world's, then the ready one's
## (its swap waits for it), then a parked world's, oldest first.
func _next(v: View360, s: WorldStreamer) -> int:
	var best := 0
	var best_rank := 3
	for i in _queue.size():
		var world: Variant = _queue[i]["world"]
		var rank := 0 if is_same(world, v._generated) \
			else (1 if s._ready.size() > 1 and is_same(world, s._ready[1]) else 2)
		if rank < best_rank:
			best = i
			best_rank = rank
	return best

## Whether `world` will never show its detail: freed, or leaving.
static func _gone(world: Variant, handoff: WorldHandoff) -> bool:
	return not is_instance_valid(world) or handoff.retiring(world)

## Per frame: starts the next pass, answers its rendering-server calls
## while it runs, hands its pieces over when it ends, and grows the late
## wave.
func tick(v: View360, s: WorldStreamer, delta: float) -> void:
	for world: Variant in _joining.duplicate():
		if is_instance_valid(world) and s._handoff.late_pending(world):
			# Swapped in before they were all in (the edge was near): the
			# ones still off fade in too.
			if not is_same(_faded, world):
				_fade(v, world, s._handoff.late_nodes(world))
			continue
		_joining.erase(world)
		# Every late piece is in. In the shown world (now, or since a swap
		# that did not wait for them) the trams and trains among them were
		# not there when the mover attached (View360._tick_near_ground),
		# nor the lamps when the night lights last looked for them.
		if is_instance_valid(world) and is_same(v._generated, world):
			if v._atmos != null and v._rig != null:
				StreetLights.update_shadows(v._generated, v._rig.position, CityLights.amount_for(
					v._atmos.night_amount, v._atmos.twilight_amount), v._quality_preset)
			if v._near_step > 2:
				if v._mover != null:
					v._mover.stop()
				v._mover = VehicleMover.attach(v._generated, v._data, v._ground)
	if _joining.is_empty():
		# The wave waits for its pieces: one it passed while still off would
		# pop in when added.
		_reveal.tick(Vector2.ZERO, delta, v._quality_preset)
	if _thread == null:
		_queue = _queue.filter(func(j: Dictionary) -> bool: return not _gone(j["world"], s._handoff))
		if _queue.is_empty() or _builds > 0:
			return
		v._reach.abort_build()
		if v._reach.building():
			return
		_job = _queue.pop_at(_next(v, s))
		_abort = BuildAbort.new()
		_abort.background = true
		_again = false
		var data: LocationData = _job["data"]
		var ground: GroundTruth = _job["ground"]
		var keep: Dictionary = _job["keep"]
		var abort := _abort
		_t0 = Time.get_ticks_msec()
		_last_us = Time.get_ticks_usec()
		_thread = Thread.new()
		v._threads.append(_thread)
		_thread.start(func() -> Node3D: return WorldBuildGraph.build_detail(data, ground, keep, abort),
			Thread.PRIORITY_LOW)
		return
	if _thread.is_alive():
		if _gone(_job["world"], s._handoff):
			_abort.requested = true
			_again = false
		# The main thread answers the build's rendering-server calls, in a
		# background build's share of the frame, a bigger one while a build
		# waits for the pass or the camera is past the edge.
		_last_us = WorldCache.pump_thread(_thread, _last_us, true, s.slowed or _builds > 0)
		return
	v._threads.erase(_thread)
	var node: Node3D = _thread.wait_to_finish()
	var job := _job
	var again := _again
	_thread = null
	_abort = null
	_job = {}
	_again = false
	if _gone(job["world"], s._handoff):
		if node != null:
			node.free()
	elif node != null:
		_hand_over(v, s, job, node)
	elif again:
		_queue.append(job)  # _next() picks by who needs it, not by place in line

## Dresses one late piece (in WorldHandoff's holder) as it joins a world
## in the tree: its LOD range (the late wave's hidden pieces keep theirs
## until it passes), and the per-piece part of ViewConditions.dress; the
## world-wide parts belong to the world's own pieces.
func _dress(holder: Node, _top: bool, v: View360, data: LocationData, layer: String) -> void:
	if not is_instance_valid(v):
		return
	# The piece is the holder's last child: it may hold helpers of its own
	# (AmbientLife's, from a staged piece dressed in it).
	LodRing.apply_node(holder.get_child(holder.get_child_count() - 1), v._quality_preset, layer)
	ViewConditions.dress(holder, false, v, data)

## Starts the late wave over `pieces` (still detached) when `world` is the
## one shown; false when it is not.
func _fade(v: View360, world: Node3D, pieces: Array) -> bool:
	if not is_same(v._generated, world) or not world.visible or v._rig == null:
		return false
	_faded = world
	_reveal.prepare_nodes(world, pieces)
	_reveal.start(world, Vector2(v._rig.position.x, v._rig.position.z), v._quality_preset)
	return true

## `node`'s children (tagged with its layer) join the job's world: at once
## while it is still detached (ranged, staged and dressed with the rest
## later), else a slice a frame through WorldHandoff; into a world already
## shown they fade in from the camera outward.
func _hand_over(v: View360, s: WorldStreamer, job: Dictionary, node: Node3D) -> void:
	var world: Node3D = job["world"]
	var layer := str(node.name)
	var pieces: Array = node.get_children()
	for c: Node in pieces:
		node.remove_child(c)
	node.free()
	var where := "before staging"
	if not world.is_inside_tree():
		for c: Node in pieces:
			world.add_child(c)
		s.range_more(world)
	else:
		where = "staged or parked"
		if _fade(v, world, pieces):
			where = "after the swap"
		if not world in _joining:
			_joining.append(world)
		var dress := _dress.bind(v, job["data"], layer)
		for c: Node in pieces:
			s._handoff.add_late(world, c, dress)
	WorldStreamer._log("STREAM detail gen %d: %d pieces in %.1f s, landed %s" % [job["gen"], pieces.size(),
		(Time.get_ticks_msec() - _t0) / 1000.0, where])
