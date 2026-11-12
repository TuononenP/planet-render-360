class_name WorldStreamer
extends RefCounted

## Endless walk & fly: keeps detailed ground ahead of the camera by
## recentring the one-centred world before the camera reaches its edge.
## Pure rules are static so tests can drive them; one instance per view
## holds the centre, the pending generation and its state. View360 owns
## the actual pipeline/build and performs the swap (apply_streamed_world);
## this class only decides where the next centre goes, whether a step may
## be taken, and whether a finished generation is still the wanted one.
##
## The detailed world is a square of half-extent HALF_EXTENT_M around its
## centre (WorldScale.DETAILED_EXTENT_M / 2). Walking was fenced to a
## 600 m circle and the drone to 1100 m inside it; with streaming those
## fences are gone: any ground the streamer can see is enterable, the
## area ahead is fetched once the camera is TRIGGER_M out (or predicted
## to run out of detailed ground), and past the detailed edge — only
## while the next world is still building — speed is capped, visibly,
## instead of stopping at a line.

## Half the detailed square, and the radius that arms a recentre: with
## STEP_M of new ground ahead, a camera TRIGGER_M out still has at
## least HALF_EXTENT_M - TRIGGER_M of detailed ground in front of it
## while the next centre builds (about 9 s even sprinting at 83 m/s;
## the interim cap covers a build that takes longer).
const HALF_EXTENT_M := WorldScale.DETAILED_EXTENT_M * 0.5
const TRIGGER_M := 480.0
## How far ahead of the camera's predicted position the next centre sits.
const STEP_M := 900.0
## Seconds of travel the trigger looks ahead (velocity prediction).
const LOOKAHEAD_S := 18.0
## Detailed metres that must remain ahead before a recentre is armed
## on prediction alone (a still camera never arms one).
const AHEAD_MIN_M := 600.0
## The only outer bound while streaming: recentring rebases the camera
## long before this, so reaching it means streaming has stalled.
const STREAM_LIMIT_M := 20000.0
## Speed cap (m/s) past the detailed edge while the next world builds:
## a gentle pace, never a stop, and never applied heading back inside.
const INTERIM_MPS := 10.0
## A failed ahead-fetch retries no sooner than this after the failure.
const RETRY_S := 20.0

enum State { IDLE, FETCHING, READY, DEGRADED }

var state: int = State.IDLE
## Movement may cross the old fences only while this is set (Main sets
## it for the live app; tests and captures keep the bounded behaviour).
var enabled := false
## The centre the live world is built around, and the season / preset
## it was built for (a change invalidates a pending build).
var centre_lat := 0.0
var centre_lon := 0.0
var centre_season := -1
var centre_preset := -1
## Bumped on every begin/invalidate: a finished generation whose number
## no longer matches is stale and must be dropped, never swapped in.
var generation := 0
var pending_latlon := Vector2.ZERO
var pending_target_xz := Vector2.ZERO
var last_error := ""
var retry_at_msec := 0

# --- Pure rules ---

## Metres of detailed ground ahead of `pos` looking along `dir` before
## the square's edge (0 at or past it). `dir` need not be normalised.
static func detailed_ahead(pos: Vector2, dir: Vector2) -> float:
	var d := dir.normalized()
	if d == Vector2.ZERO:
		return INF
	var best := INF
	if d.x > 0.0001:
		best = minf(best, (HALF_EXTENT_M - pos.x) / d.x)
	elif d.x < -0.0001:
		best = minf(best, (-HALF_EXTENT_M - pos.x) / d.x)
	if d.y > 0.0001:
		best = minf(best, (HALF_EXTENT_M - pos.y) / d.y)
	elif d.y < -0.0001:
		best = minf(best, (-HALF_EXTENT_M - pos.y) / d.y)
	return maxf(best, 0.0) if inside_detailed(pos) else 0.0

## Whether `pos` lies in the detailed square.
static func inside_detailed(pos: Vector2) -> bool:
	return absf(pos.x) <= HALF_EXTENT_M and absf(pos.y) <= HALF_EXTENT_M

static func _travel_dir(vel: Vector2, look_dir: Vector2) -> Vector2:
	return vel.normalized() if vel.length() > 0.5 else look_dir.normalized()

## Whether the camera at `pos` (metres from the centre) travelling at
## `vel` needs the next centre started now.
static func needs_recentre(pos: Vector2, vel: Vector2, look_dir: Vector2) -> bool:
	if pos.length() > TRIGGER_M:
		return true
	var dir := _travel_dir(vel, look_dir)
	if dir == Vector2.ZERO or vel.length() <= 0.5:
		return false
	var predicted := pos + vel * LOOKAHEAD_S
	return detailed_ahead(predicted, dir) < AHEAD_MIN_M

## The next centre, in the current centre's XZ frame: STEP_M ahead of
## where the camera is heading (itself when standing still, which the
## trigger never asks for).
static func step_target(pos: Vector2, vel: Vector2, look_dir: Vector2) -> Vector2:
	var dir := _travel_dir(vel, look_dir)
	return pos + dir * STEP_M if dir != Vector2.ZERO else pos

## `xz` re-expressed from the old centre's frame in the new one's, via
## the lat/lon both frames share.
static func remap_xz(xz: Vector2, old_lat: float, old_lon: float,
		new_lat: float, new_lon: float) -> Vector2:
	var ll := WorldScale.latlon_from_xz(xz.x, xz.y, old_lat, old_lon)
	return WorldScale.xz_from_latlon(ll.x, ll.y, new_lat, new_lon)

## Whether streaming movement may enter `xz`: any ground inside the
## stream limit. There is no smaller fence — that is the point.
static func enterable(xz: Vector2, ground: GroundTruth) -> bool:
	return ground != null and xz.length() <= STREAM_LIMIT_M

## Ground a single tap-glide may cross to: inside the detailed square
## (past the old 600 m circle, never a 5 km leap — that stays Go there).
static func glide_enterable(xz: Vector2, ground: GroundTruth) -> bool:
	return ground != null and ground.is_inside(xz.x, xz.y)

## Speed cap at `pos` heading along `dir`: INTERIM_MPS only while past
## the detailed edge and still heading out; INF (no cap) elsewhere.
static func interim_cap_mps(pos: Vector2, dir: Vector2) -> float:
	if inside_detailed(pos):
		return INF
	var outward := dir.normalized().dot(-pos.normalized()) < 0.0 if pos != Vector2.ZERO else false
	return INTERIM_MPS if outward else INF

## `vel` capped by the interim rule at `pos`.
static func capped_velocity(vel: Vector2, pos: Vector2) -> Vector2:
	if vel == Vector2.ZERO:
		return vel
	var cap := interim_cap_mps(pos, vel)
	return vel if is_inf(cap) else vel.limit_length(cap)

# --- State machine ---

## The live world now stands at this centre (opening a place, or a swap).
## A generation still in flight for the previous centre is cancelled
## first, so its pipeline can never race the new place's fetchers.
func arm(lat: float, lon: float, season: int, preset: int) -> void:
	if state == State.FETCHING:
		_cancel_pending()
	centre_lat = lat
	centre_lon = lon
	centre_season = season
	centre_preset = preset
	state = State.IDLE
	last_error = ""
	pending_target_xz = Vector2.ZERO

## Starts watching a generation for the centre at `latlon` (XZ target in
## the current frame). Returns its generation number.
func begin(latlon: Vector2, target_xz: Vector2) -> int:
	generation += 1
	pending_latlon = latlon
	pending_target_xz = target_xz
	state = State.FETCHING
	last_error = ""
	return generation

## Generation `gen` finished building: true when it is still wanted.
func mark_ready(gen: int) -> bool:
	if gen != generation or state != State.FETCHING:
		return false
	state = State.READY
	return true

## Generation `gen` failed: degrade (far ground stays walkable) and arm
## the retry clock. Stale failures change nothing.
func mark_failed(gen: int, error: String) -> void:
	if gen != generation:
		return
	state = State.DEGRADED
	last_error = error
	retry_at_msec = Time.get_ticks_msec() + int(RETRY_S * 1000.0)

## Drops any pending or ready world (direction reversed, season or
## preset changed, a new place opened). Returns the new generation.
func invalidate(_reason: String) -> int:
	generation += 1
	state = State.IDLE
	pending_target_xz = Vector2.ZERO
	return generation

## Whether the streamer is degraded (View360 also honours retry_at_msec
## before actually starting the retry).
func should_retry() -> bool:
	return state == State.DEGRADED

## Whether the pending target is still ahead of a camera at `pos`: the
## swap is wanted once the camera is closer to it than to the centre,
## and unwanted (dropped) once it is back inside the trigger's inner
## half with the target behind it.
func swap_wanted(pos: Vector2) -> bool:
	if state != State.READY:
		return false
	return pos.distance_to(pending_target_xz) < pos.length()

func swap_stale(pos: Vector2) -> bool:
	if state != State.READY:
		return false
	return pos.length() < TRIGGER_M * 0.5 \
		and pos.distance_to(pending_target_xz) > STEP_M

# --- Live driving (View360 delegates here, so View360 stays lean) ---

var _pipeline: GenerationPipeline
var _abort: BuildAbort
var _ready: Array = []
## The ready world is ranged subtree by subtree while it waits (see
## _pump_ranging), so the swap frame need not re-range it. The flag
## only counts for the world node it names.
var _ready_ranged := false
var _ranged_world: Node3D
var _range_world: Node3D
var _range_cursor := 0
var _range_preset := -1
var _ready_data: LocationData
var _last_pos := Vector2.INF
var _vel := Vector2.ZERO
var _notified_gen := -1
var _view: View360

## Records where the camera spawned (or swapped to) so velocity starts clean.
func note_spawn(pos: Vector2) -> void:
	_last_pos = pos
	_vel = Vector2.ZERO

func _drop_ready() -> void:
	if _ready.size() > 1 and _ready[1] is Node3D:
		(_ready[1] as Node3D).free()
	_ready = []
	_ready_data = null
	_ready_ranged = false
	_ranged_world = null
	_range_world = null
	_range_cursor = 0

## Starts ranging `world` a subtree at a time (LodRing.apply_child per
## tick in _pump_ranging); a world with no children is already ranged.
func begin_ranging(world: Node3D, preset: int) -> void:
	_range_world = world
	_ranged_world = null
	_range_cursor = 0
	_range_preset = preset
	_ready_ranged = world == null or world.get_child_count() == 0
	if _ready_ranged:
		_ranged_world = world
		_range_world = null

## Ranges up to `slices` more subtrees of the pending world; on the
## last one the world becomes the ranged one.
func _pump_ranging(slices: int = 2) -> void:
	if _range_world == null or _ready_ranged:
		return
	var stop := mini(_range_world.get_child_count(), _range_cursor + slices)
	while _range_cursor < stop:
		LodRing.apply_child(_range_world, _range_cursor, _range_preset)
		_range_cursor += 1
	if _range_cursor >= _range_world.get_child_count():
		_ranged_world = _range_world
		_range_world = null
		_ready_ranged = true

## Ranges whatever is left of the pending world at once (a swap that
## arrived before the slices did).
func _finish_ranging() -> void:
	_pump_ranging(1 << 30)

func _cancel_pending() -> void:
	_drop_ready()
	if _abort != null:
		_abort.requested = true
	if _pipeline != null:
		_pipeline.cancel()

## Cancels any pending generation and drops its world (a season change,
## a new place, teardown). The next begin() starts from a clean slate.
func cancel_pending() -> void:
	_cancel_pending()
	invalidate("cancelled")

## A new place is opening: nothing for the old centre may land, leak, or
## claim the new place's first generation.
func reset_for_new_place() -> void:
	cancel_pending()
	_vel = Vector2.ZERO
	_last_pos = Vector2.INF

## The view is going away: stop fetchers and builds, drop the ready
## world, and forget the view so late callbacks touch nothing.
func shutdown() -> void:
	cancel_pending()
	_view = null

## Installs a world built for a new centre without reopening the place:
## the camera stays over the same lat/lon at the same height over the
## ground, look and mode untouched, the old world leaves the tree in
## the same frame (View360._rebuild_world removes it before adding).
func apply_swap(v: View360, data: LocationData, built: Array) -> void:
	var ranged: bool = _ready_ranged and built.size() > 1 and built[1] == _ranged_world
	_ready_ranged = false
	_ranged_world = null
	_range_world = null
	_range_cursor = 0
	if data == null or built.size() < 2 or v._data == null or v._rig == null:
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return
	if built[1] == v._generated or data.season != v._data.season:
		# Already live, or built for a season the view has left: never
		# install it (re-installing the live world would free it in-tree).
		if built[1] != v._generated:
			(built[1] as Node3D).free()
		invalidate("swap refused")
		return
	# An in-flight glide still lerps in the old frame: it must not drag
	# the remapped camera back across the swap.
	if v._visit_tween != null:
		v._visit_tween.kill()
	var old_xz := Vector2(v._rig.position.x, v._rig.position.z)
	var agl := v._rig.position.y - v._ground.height_at_world(old_xz.x, old_xz.y) \
		if v._ground != null else ViewWalk.EYE_M
	var new_xz := remap_xz(old_xz, v._data.latitude, v._data.longitude,
		data.latitude, data.longitude)
	v._data = data
	v._ground = built[0]
	v._rebuild_world(built[1], ranged)
	var y := v._ground.height_at_world(new_xz.x, new_xz.y) + agl
	if not v._drone.on:
		# Keep the walker's height when the new centre's floor agrees
		# with it (ViewWalk lerps the small rest while moving); snap
		# when it does not — a set-down from flight, an authored
		# island or quay floor — so the eye is right even standing
		# still, where no lerp runs.
		var foot := ViewWalk.foot_y(data, v._ground, new_xz)
		if absf(foot - y) > 0.5:
			y = foot
	v._rig.position = Vector3(new_xz.x, y, new_xz.y)
	v._atmos.ground_at = func(x: float, z: float) -> float: return v._ground.height_at_world(x, z)
	v._atmos.set_place(data.latitude, data.longitude)
	v._atmos.set_coast(v._ground.render_y(0.0), data.waterways.any(func(w: Variant) -> bool:
		return w is Dictionary and str((w as Dictionary).get("class", "")) == "coastline"))
	v._atmos.set_probe_origin(v._rig.position)
	if v._horizon != null:
		v._horizon.set_place(data, v._ground)
	if v._minimap != null:
		v._minimap.set_place(data)
	v._walk._spans_for = null
	v._walk._near_at = Vector2.INF
	v._walk._near.clear()
	v._drone._spans_for = null
	v._drone._near_at = Vector2.INF
	v._drone._near.clear()
	if v._drone.on:
		# Momentum is frame-relative and survives the recentre: only
		# the height-over-ground and floor caches are re-derived. A
		# resync left pending by a glide the swap just killed must
		# not eat the first frame's momentum either.
		v._drone._resync = false
		v._drone._agl = clampf(agl, ViewDrone.AGL_MIN_M, ViewDrone.AGL_MAX_M)
	else:
		v._drone._resync = true
	v._drone._floor_clock = 0.0
	v._drone._floor_here = -INF
	v._drone._floor_target = -INF
	ViewChrome.show_place(v, data)
	var vel := _vel
	arm(data.latitude, data.longitude, data.season, data.quality_preset)
	note_spawn(new_xz)
	_vel = vel

## Per-frame: track velocity, swap a ready centre in (or drop it when
## the camera turned back), and start the next centre early enough that
## detailed ground is always ahead. Silent while all is well; the one
## notice comes when the interim cap first bites.
func tick(v: View360, delta: float) -> void:
	_view = v
	if not enabled or v._data == null or v._ground == null or v._rig == null \
			or not v.is_visible_in_tree():
		return
	var pos := Vector2(v._rig.position.x, v._rig.position.z)
	if _last_pos != Vector2.INF and delta > 0.0:
		var inst := (pos - _last_pos) / delta
		_vel = _vel.lerp(inst, 1.0 - exp(-3.0 * delta)) \
			if _last_pos != pos else _vel * exp(-3.0 * delta)
	_last_pos = pos
	if v._data.season != centre_season or v._quality_preset != centre_preset:
		_cancel_pending()
		invalidate("season or preset changed")
		arm(v._data.latitude, v._data.longitude, v._data.season, v._quality_preset)
	if state == State.READY:
		if v._season_building:
			return  # hold: the season rebuild owns _data until it lands
		_pump_ranging()
		if swap_wanted(pos):
			_finish_ranging()
			var data := _ready_data
			var built := _ready
			_ready = []
			_ready_data = null
			apply_swap(v, data, built)
			return
		if swap_stale(pos):
			_cancel_pending()
			invalidate("camera turned back")
			return
	if state == State.FETCHING or state == State.READY:
		if not inside_detailed(pos) and _notified_gen != generation:
			_notified_gen = generation
			ViewTools.say(v, "Preparing the way ahead",
				"The next stretch is building as you go.", "neutral")
		return
	if state == State.DEGRADED and Time.get_ticks_msec() < retry_at_msec:
		return
	var look := Vector2(-sin(v._rig.yaw), -cos(v._rig.yaw))
	if needs_recentre(pos, _vel, look):
		_start_generation(v, pos, look)

func _start_generation(v: View360, pos: Vector2, look: Vector2) -> void:
	var target := step_target(pos, _vel, look)
	var ll := WorldScale.latlon_from_xz(target.x, target.y, v._data.latitude, v._data.longitude)
	var gen := begin(ll, target)
	_notified_gen = -1
	WorldCache.prefetch(ll.x, ll.y, v._quality_preset, v._data.season)
	_abort = BuildAbort.new()
	# A fresh pipeline per generation: a reused one aliases runs (its
	# cancel flag and stage counters are shared), so a stale finish
	# could claim the next generation. The token guards it regardless.
	if _pipeline != null:
		_pipeline.cancel()
		_pipeline.queue_free()
	_pipeline = GenerationPipeline.new()
	v.add_child(_pipeline)
	var pipe := _pipeline
	pipe.finished.connect(func(d: LocationData) -> void:
		if is_instance_valid(_view):
			_on_finished(_view, d, gen, pipe))
	pipe.cancelled.connect(func() -> void:
		if state == State.FETCHING and gen == generation:
			mark_failed(gen, "cancelled"))
	pipe.run(ll.x, ll.y, "", v._quality_preset)

func _on_finished(v: View360, data: LocationData, gen: int, pipe: GenerationPipeline) -> void:
	if _pipeline == pipe:
		_pipeline = null
	pipe.queue_free()
	if gen != generation or state != State.FETCHING or v._data == null:
		return
	# The streamed centre inherits the live view's season and carries no
	# opening view of its own: the camera, not the data, says where we are.
	data.season = v._data.season
	data.view = {}
	data.focus = {}
	var built := await v.build_location(data, null, _abort)
	if gen != generation:
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return
	if built.is_empty():
		mark_failed(gen, "build stopped")
		ViewTools.say(v, "Couldn't prepare the way ahead",
			"Still exploring on distant ground; will try again as you go.", "caution")
		return
	if not mark_ready(gen):
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return
	# Range the LOD rings while the world waits to swap in, a few
	# subtrees per tick, so neither this frame nor the swap frame
	# pays for the whole walk.
	begin_ranging(built[1] as Node3D, v._quality_preset)
	_ready = built
	_ready_data = data
