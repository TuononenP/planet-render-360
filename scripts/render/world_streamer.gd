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
## Adaptive trigger: the next centre starts once the camera would reach
## the detailed edge, at its speed, within LEAD_FACTOR × the expected
## build time plus LEAD_MARGIN_S — so a fast drone starts earlier and a
## walker still waits for TRIGGER_M.
const LEAD_FACTOR := 1.25
const LEAD_MARGIN_S := 6.0
## Expected seconds from start to ready per RenderSettings.Preset before
## any streamed build has been timed this session: about a network
## build's measured time. Too high a guess centres each stretch the most
## ahead, where a turning drone soon leaves it unused.
const DEFAULT_BUILD_S: Array[float] = [10.0, 12.0, 14.0, 16.0]
## Longest step ahead: a fast camera gets a centre about one build's
## travel ahead, never so far that the squares stop overlapping.
const MAX_STEP_M := 1700.0

## Main-thread microseconds a frame for ranging and staging a world whose
## swap is already wanted (it landed late).
const HURRY_US := 6000
## A late world also waits this long staged before it shows (its first
## frames then skip the uploads), unless the edge is nearer than
## SETTLE_AHEAD_M along the way the camera is going.
const SETTLE_MS := 400
const SETTLE_AHEAD_M := 250.0
## The slice a frame once the edge is that near or passed (the camera is
## slowed past it, so a few frames more cost nothing visible).
const EDGE_US := 12000
## Seconds after a place opens in the drone before its first stretch
## starts unasked (the opening view settles first).
const WARM_S := 3.0
## How fast the planning pace falls back once the camera slows (m/s²).
const PACE_DECAY_MPS2 := 2.0
## How far off the way of travel a centre planned ahead may lie and still
## be built (see use_plan).
const PLAN_CONE_DEG := 35.0
## Faster than a walker: moving away from a ready world at this pace near
## the centre means the camera turned back (swap_stale).
const TURN_BACK_MPS := 6.0
## Seconds the camera must hold a heading that leaves the live square
## outside the pending one before that pending world is given up for
## one where it is going (see heading_misses): a glance or a short
## swerve keeps it.
const MISS_HOLD_S := 3.0
## Built worlds kept hidden for a turn back (see _park), at most: each
## holds a whole stretch in memory.
const PARK_MAX := 2
## Seconds standing still before a streamed world is written to the
## world cache (never while moving: the save stalls frames).
const SAVE_STILL_S := 2.0

## Measured build seconds per preset (session-wide, see blend_build_s).
static var _build_s := {}

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
## Set when a build in flight was abandoned for a turn (should_redirect);
## cleared when a build finishes or fails, or a centre is armed.
var redirected := false

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

## Seconds of lead the next centre needs when a build is expected to
## take `expected_s`.
static func lead_s(expected_s: float) -> float:
	return expected_s * LEAD_FACTOR + LEAD_MARGIN_S

## The expected build time for `preset`: measured, or the default.
static func expected_build_s(preset: int) -> float:
	return float(_build_s.get(preset,
		DEFAULT_BUILD_S[clampi(preset, 0, DEFAULT_BUILD_S.size() - 1)]))

## Folds a measured build into the estimate: a slower build raises it
## quickly, a faster (cached) one lowers it only a little, so one cache
## hit never sets up the next network build to start too late.
static func blend_build_s(estimate: float, sample: float) -> float:
	return lerpf(estimate, sample, 0.6 if sample > estimate else 0.25)

static func note_build_s(preset: int, seconds: float) -> void:
	_build_s[preset] = blend_build_s(expected_build_s(preset), seconds)

## Whether the camera at `pos` (metres from the centre) travelling at
## `vel` needs the next centre started now. `expected_s` (the expected
## build time; 0 = unknown) starts it once the edge is nearer in time
## than the build's lead.
static func needs_recentre(pos: Vector2, vel: Vector2, look_dir: Vector2,
		expected_s := 0.0) -> bool:
	if pos.length() > TRIGGER_M:
		return true
	var dir := _travel_dir(vel, look_dir)
	var speed := vel.length()
	if dir == Vector2.ZERO or speed <= 0.5:
		return false
	if expected_s > 0.0 and detailed_ahead(pos, dir) / speed < lead_s(expected_s):
		return true
	var predicted := pos + vel * LOOKAHEAD_S
	return detailed_ahead(predicted, dir) < AHEAD_MIN_M

## How far ahead the next centre goes: about one build's travel at
## `speed`, at least STEP_M and at most MAX_STEP_M.
static func step_m(speed: float, expected_s: float) -> float:
	return clampf(speed * expected_s, STEP_M, MAX_STEP_M)

## The next centre, in the current centre's XZ frame: step_m ahead of
## where the camera is heading (itself when standing still, which the
## trigger never asks for).
static func step_target(pos: Vector2, vel: Vector2, look_dir: Vector2,
		expected_s := 0.0) -> Vector2:
	var dir := _travel_dir(vel, look_dir)
	return pos + dir * step_m(vel.length(), expected_s) if dir != Vector2.ZERO else pos

## Whether a centre planned ahead (`plan`, in the live frame) still suits
## a camera at `pos` travelling along `dir`: ahead within PLAN_CONE_DEG,
## far enough to be worth a stretch, and near enough to the live centre
## that the squares overlap.
static func use_plan(plan: Vector2, pos: Vector2, dir: Vector2) -> bool:
	var to := plan - pos
	if dir == Vector2.ZERO or to.length() < STEP_M * 0.6 or plan.length() > MAX_STEP_M + 1.0:
		return false
	return dir.normalized().dot(to.normalized()) >= cos(deg_to_rad(PLAN_CONE_DEG))

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
	redirected = false

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
	redirected = false
	return true

## Generation `gen` failed: degrade (far ground stays walkable) and arm
## the retry clock. Stale failures change nothing.
func mark_failed(gen: int, error: String) -> void:
	if gen != generation:
		return
	state = State.DEGRADED
	last_error = error
	redirected = false
	retry_at_msec = Time.get_ticks_msec() + int(RETRY_S * 1000.0)

## Drops any pending or ready world (direction reversed, season or
## preset changed, a new place opened). Returns the new generation.
func invalidate(reason: String) -> int:
	if state == State.FETCHING or state == State.READY:
		_log("STREAM drop gen %d: %s" % [generation, reason])
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
## or past the live edge over the pending square; unwanted (dropped)
## once it is back inside the trigger's inner half heading away from
## the target, or off both squares (a turn after the trigger).
func swap_wanted(pos: Vector2) -> bool:
	if state != State.READY:
		return false
	return pos.distance_to(pending_target_xz) < pos.length() \
		or (not inside_detailed(pos) and inside_detailed(pos - pending_target_xz))

## A camera standing still near the centre keeps its ready world: an
## early build lands before the camera has gone anywhere. So does one
## stepping back at walking pace (looking around): only a turn faster
## than TURN_BACK_MPS drops it (a walker off both squares is
## pending_misses).
func swap_stale(pos: Vector2, vel := Vector2.ZERO) -> bool:
	if state != State.READY:
		return false
	return (pos.length() < TRIGGER_M * 0.5 and vel.length() > TURN_BACK_MPS
			and vel.dot(pending_target_xz - pos) < 0.0) \
		or pending_misses(pos)

## Whether the camera at `pos` is past the live detailed edge and outside
## the ready centre's square too. Unless it is nearer than the live one
## (swap_wanted, checked first), that centre would wait forever: drop it
## so the next tick builds one where the camera went.
func pending_misses(pos: Vector2) -> bool:
	return state == State.READY and _off_both_squares(pos)

## Whether the build in flight should be abandoned for one aimed where
## the camera went: it is past the live edge and outside the pending
## square. Only once per finished build (`redirected`), so turning out
## there costs at most one restart and can never starve every build.
func should_redirect(pos: Vector2) -> bool:
	return state == State.FETCHING and not redirected and _off_both_squares(pos)

## Whether the camera at `pos` flying along `vel` leaves the live square
## somewhere the pending square does not cover: holding that heading it
## never reaches the swap, only the edge. Walking pace never counts.
func heading_misses(pos: Vector2, vel: Vector2) -> bool:
	return (state == State.FETCHING or state == State.READY) \
		and exit_missed(pos, vel, pending_target_xz)

## Whether a camera at `pos` flying along `vel` (faster than a walker)
## leaves the live square outside the square centred on `target`.
static func exit_missed(pos: Vector2, vel: Vector2, target: Vector2) -> bool:
	if vel.length() <= TURN_BACK_MPS or not inside_detailed(pos):
		return false
	var dir := vel.normalized()
	var exit := pos + dir * (detailed_ahead(pos, dir) + 1.0)
	return not inside_detailed(exit - target)

func _off_both_squares(pos: Vector2) -> bool:
	return not inside_detailed(pos) and not inside_detailed(pos - pending_target_xz)

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
## Stages the ready world into the scene and frees the old one, a slice
## a frame (WorldHandoff), so the swap frame does neither wholesale.
var _handoff := WorldHandoff.new()
## Fades the new ground in from the camera outward after a swap.
var _reveal := RevealWave.new()
var _last_pos := Vector2.INF
var _vel := Vector2.ZERO
## Recent peak speed, decaying PACE_DECAY_MPS2: steps and leads are sized
## by it, not by the speed of a camera still easing back from the cap.
var _pace := 0.0
## Past the live detailed edge while the next world builds: the interim
## pace applies, and the way-ahead badge says so (StreamBadge).
var slowed := false
## Seconds until the camera reaches the live detailed edge at its pace
## (INF standing still), for urgent().
var _edge_s := INF
## How long the camera has held a heading the pending world misses
## (heading_misses).
var _miss_s := 0.0
var _view: View360
## How far the generation in flight has come, for the HUD's StreamBadge:
## the pipeline's data stages, then the build (null before the first).
var progress: SaveProgress
## Which of GenerationPipeline.STAGES have landed for `progress`.
var stages_done: Array[bool] = []
## When the generation in flight started and its data landed (msec).
var _started_msec := 0
var _fetched_msec := 0
## Worst frame (ms) per phase of the current generation, for the one
## STREAM log line per build and swap; `_after_swap` counts the frames
## after a swap still charged to it.
var _worst := {}
var _after_swap := 0
## Seconds from start to each data stage landing (the STREAM log line).
var _stage_s := {}
## The latest streamed world's held-back cache save, and how long the
## camera has stood still (it is written only then; see BuildAbort).
var _unsaved: Array = []
var _still_s := 0.0
## Fetches the centres ahead and around before they are wanted, and
## remembers which have their data on disk (StreamScout).
var _scout := StreamScout.new()
## Built worlds not shown, kept hidden in the tree for a turn back:
## {world, data, ground, ll}, oldest first. A ready world given up for a
## new heading, and the world each swap leaves, park here; a centre
## started towards one swaps it in again with no build at all.
var _parked: Array[Dictionary] = []
## When the place opened, and whether its first stretch has started.
var _opened_msec := 0
var _warmed := true

## Whether the build in flight may land after the camera reaches the
## edge (or already has): the way-ahead badge shows only then.
func urgent() -> bool:
	if slowed:
		return true
	var left := expected_build_s(centre_preset) - (Time.get_ticks_msec() - _started_msec) / 1000.0
	return _edge_s < maxf(left, 0.0) + LEAD_MARGIN_S

## The build phase the generation in flight is in (a BuildAbort.Step).
func build_step() -> int:
	return _abort.step if _abort != null else 0

## The measured velocity at the recent peak pace (see _pace).
func _planned_vel() -> Vector2:
	return _vel.normalized() * _pace if _vel.length() > 0.5 else _vel

## Records where the camera spawned (or swapped to) so velocity starts clean.
func note_spawn(pos: Vector2) -> void:
	_last_pos = pos
	_vel = Vector2.ZERO

func _drop_ready() -> void:
	if _ready.size() > 1 and _ready[1] is Node3D:
		_free_world(_ready[1] as Node3D)
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

## Ranges at least one more subtree of the pending world, and more while
## `budget_us` lasts; on the last one the world becomes the ranged one.
func _pump_ranging(budget_us: int = 1000) -> void:
	if _range_world == null or _ready_ranged:
		return
	var t := Time.get_ticks_usec()
	var first := _range_cursor
	var stop := _range_world.get_child_count()
	while _range_cursor < stop and (_range_cursor == first or Time.get_ticks_usec() - t < budget_us):
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
	_free_parked()
	_scout.stop()
	invalidate("cancelled")

## Frees a world that will not be shown: a staged one leaves a slice a
## frame like an old world; a detached one goes at once.
func _free_world(world: Node3D) -> void:
	if world == _handoff.staged:
		_reveal.forget(world)
		_handoff.drop_staged()
	elif is_instance_valid(world) and not world.is_inside_tree():
		world.free()

## A new place is opening: nothing for the old centre may land, leak, or
## claim the new place's first generation.
func reset_for_new_place() -> void:
	cancel_pending()
	_opened_msec = Time.get_ticks_msec()
	_warmed = false
	_unsaved = []
	_scout.clear()
	_vel = Vector2.ZERO
	_pace = 0.0
	_last_pos = Vector2.INF

## The view is going away: stop fetchers and builds, drop the ready
## world, and forget the view so late callbacks touch nothing.
func shutdown() -> void:
	cancel_pending()
	_reveal.stop()
	_handoff.clear()
	_parked.clear()  # in the world root, which frees them
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
			_free_world(built[1] as Node3D)
		return
	if built[1] == v._generated or data.season != v._data.season:
		# Already live, or built for a season the view has left: never
		# install it (re-installing the live world would free it in-tree).
		if built[1] != v._generated:
			_free_world(built[1] as Node3D)
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
	var old_centre := remap_xz(Vector2.ZERO, v._data.latitude, v._data.longitude,
		data.latitude, data.longitude)
	var old_data := v._data
	var old_ground := v._ground
	v._data = data
	v._ground = built[0]
	if ranged:
		# Staged while it waited (or now, if the swap came first): show
		# it, hide the old world, and let both finish over the next frames.
		if _handoff.staged != built[1]:
			_handoff.dress = Callable()
			_handoff.stage(v._world_root, built[1])
		var dressed := _handoff.dressed
		var old_world := v._generated
		_handoff.swap_in(v, true)
		if is_instance_valid(old_world) and old_world != built[1]:
			_park(old_world, old_data, old_ground, Vector2(centre_lat, centre_lon))
		ViewConditions.apply_surface_state(v, not dressed)
		if not _reveal.prepared(built[1]):
			_reveal.prepare(built[1], old_centre)
		_reveal.start(built[1], new_xz, v._quality_preset)
	else:
		v._rebuild_world(built[1], false)
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
	_prune_parked()
	_scout.survey(data.latitude, data.longitude, vel)

## Per-frame: track velocity, swap a ready centre in (or drop it when
## the camera turned back), and start the next centre early enough that
## detailed ground is always ahead. The way-ahead badge (StreamBadge)
## shows each build, and says when the interim cap bites (`slowed`).
func tick(v: View360, delta: float) -> void:
	_view = v
	if not enabled or v._data == null or v._ground == null or v._rig == null \
			or not v.is_visible_in_tree():
		# Retired and dropped worlds still leave (hidden, in the tree).
		if _handoff.busy():
			_handoff.pump()
		return
	_note_frame(delta)
	if state == State.READY and _ready_ranged and _ranged_world != null \
			and _handoff.staged != _ranged_world and not _ranged_world.is_inside_tree():
		_handoff.dress = ViewConditions.dress.bind(v, _ready_data)
		_handoff.stage(v._world_root, _ranged_world)
		_reveal.prepare(_ranged_world, remap_xz(Vector2.ZERO, centre_lat, centre_lon,
			_ready_data.latitude, _ready_data.longitude))
	var pos := Vector2(v._rig.position.x, v._rig.position.z)
	# A world landing after its swap point stages in bigger slices: still
	# no single-frame install, but no long wait either.
	var hurry := state == State.READY and swap_wanted(pos)
	# Near or past the edge the camera needs it now: bigger slices still.
	var near_edge := detailed_ahead(pos, _vel) <= SETTLE_AHEAD_M
	var hurry_us := EDGE_US if near_edge else HURRY_US
	if _handoff.busy():
		_handoff.pump(hurry_us if hurry else WorldHandoff.BUDGET_US)
	# Not held behind an old world still being freed (busy() above).
	if _handoff.ready_for(_handoff.staged):
		_reveal.pump(hurry_us if hurry else 1000)
	if _last_pos != Vector2.INF and delta > 0.0:
		var inst := (pos - _last_pos) / delta
		_vel = _vel.lerp(inst, 1.0 - exp(-3.0 * delta)) \
			if _last_pos != pos else _vel * exp(-3.0 * delta)
	_last_pos = pos
	# The pace to plan for: a camera just eased past an edge (or turning)
	# is still on its way back to full speed.
	_pace = maxf(_vel.length(), _pace - PACE_DECAY_MPS2 * delta)
	_still_s = _still_s + delta if _vel.length() < 1.0 else 0.0
	if not _unsaved.is_empty() and _still_s >= SAVE_STILL_S:
		WorldCache.save_async(v, v._threads, _unsaved[0], [_unsaved[1]], _unsaved[2], true)
		_unsaved = []
	_reveal.tick(pos, delta, v._quality_preset)
	# Ring fetches wait while the build's own data is on the network.
	_scout.pump(v, state == State.FETCHING and _fetched_msec == 0)
	slowed = (state == State.FETCHING or state == State.READY) and not inside_detailed(pos)
	_edge_s = detailed_ahead(pos, _vel) / _vel.length() if _vel.length() > 0.5 else INF
	_miss_s = _miss_s + delta if heading_misses(pos, _vel) else 0.0
	var look := Vector2(-sin(v._rig.yaw), -cos(v._rig.yaw))
	# Heading somewhere the pending world does not cover, with the edge
	# within a build's lead: rebuild for the new heading now, not once
	# the camera is past the edge.
	var veered := _miss_s >= MISS_HOLD_S \
		and needs_recentre(pos, _vel, look, expected_build_s(v._quality_preset))
	if v._data.season != centre_season or v._quality_preset != centre_preset:
		_cancel_pending()
		_free_parked()
		invalidate("season or preset changed")
		arm(v._data.latitude, v._data.longitude, v._data.season, v._quality_preset)
	if state == State.READY:
		if v._season_building:
			return  # hold: the season rebuild owns _data until it lands
		_pump_ranging(hurry_us if hurry else 1000)
		# Swap only once staged (never the whole world in one frame), and
		# settled too unless the edge is near.
		if hurry and not (_ready.size() > 1 and _handoff.ready_for(_ready[1])
				and _reveal.prepared(_ready[1])
				and (near_edge or _handoff.staged_ms(_ready[1]) >= SETTLE_MS)):
			return
		if swap_wanted(pos):
			_finish_ranging()
			var data := _ready_data
			var built := _ready
			_ready = []
			_ready_data = null
			var t0 := Time.get_ticks_usec()
			apply_swap(v, data, built)
			_worst["swap call"] = (Time.get_ticks_usec() - t0) / 1000.0
			_after_swap = 4
			return
		if swap_stale(pos, _vel):
			_park_ready()
			_cancel_pending()
			invalidate("camera turned back")
			return
		if veered:
			_park_ready()
			_cancel_pending()
			invalidate("camera heading off the ready stretch")
			_miss_s = 0.0
			_start_generation(v, pos, look)
			return
	if should_redirect(pos) or (veered and state == State.FETCHING and not redirected):
		# Turned away mid-build: aim the build where the camera went now,
		# not after the stale one lands.
		_cancel_pending()
		invalidate("camera turned away mid-build")
		_miss_s = 0.0
		_start_generation(v, pos, look)
		redirected = true
		return
	if state == State.FETCHING or state == State.READY:
		return
	if state == State.DEGRADED and Time.get_ticks_msec() < retry_at_msec:
		return
	if needs_recentre(pos, _planned_vel(), look, expected_build_s(v._quality_preset)):
		_start_generation(v, pos, look)
	elif not _warmed and v.start_flying and v._drone.on \
			and Time.get_ticks_msec() - _opened_msec >= int(WARM_S * 1000.0):
		# A place opens in the drone with every cache cold: the first
		# stretch, built before any flying, would land after the drone had
		# crossed the edge. Start it where the camera looks.
		_start_generation(v, pos, look)

## Parks `world` (built for `ll`, lat/lon) hidden for a turn back; the
## oldest leaves beyond PARK_MAX.
func _park(world: Node3D, data: LocationData, ground: GroundTruth, ll: Vector2) -> void:
	if data == null or ground == null:
		_handoff.retire(world)
		return
	world.visible = false
	_parked.append({"world": world, "data": data, "ground": ground, "ll": ll})
	while _parked.size() > PARK_MAX:
		_handoff.retire(_parked.pop_front()["world"])

## Parks the ready world rather than dropping it, once fully staged.
func _park_ready() -> void:
	if _ready.size() < 2 or not (_ready[1] is Node3D) or _ready_data == null \
			or not _handoff.ready_for(_ready[1]):
		return
	var world := _handoff.release()
	_reveal.forget(world)
	_park(world, _ready_data, _ready[0], pending_latlon)
	_ready = []
	_ready_data = null

## Frees parked worlds too far from the live centre to be picked again.
func _prune_parked() -> void:
	for i in range(_parked.size() - 1, -1, -1):
		var ll: Vector2 = _parked[i]["ll"]
		if WorldScale.xz_from_latlon(ll.x, ll.y, centre_lat, centre_lon).length() > MAX_STEP_M + 1.0:
			_handoff.retire(_parked[i]["world"])
			_parked.remove_at(i)

func _free_parked() -> void:
	for p in _parked:
		_handoff.retire(p["world"])
	_parked.clear()

## Swaps a parked world back in as the ready one when it lies where a
## camera at `pos` heading `dir` is going: no fetch, no build.
func _revive(v: View360, pos: Vector2, dir: Vector2) -> bool:
	for i in range(_parked.size() - 1, -1, -1):
		var p: Dictionary = _parked[i]
		var ll: Vector2 = p["ll"]
		var xz := WorldScale.xz_from_latlon(ll.x, ll.y, v._data.latitude, v._data.longitude)
		if not is_instance_valid(p["world"]) or xz.length() <= STEP_M * 0.5 \
				or not use_plan(xz, pos, dir) or exit_missed(pos, _vel, xz):
			continue
		_parked.remove_at(i)
		var world: Node3D = p["world"]
		var data: LocationData = p["data"]
		var gen := begin(ll, xz)
		mark_ready(gen)
		_started_msec = Time.get_ticks_msec()
		_ready = [p["ground"], world]
		_ready_data = data
		_ready_ranged = true
		_ranged_world = world
		_range_world = null
		_handoff.adopt(world)
		_reveal.prepare(world, remap_xz(Vector2.ZERO, centre_lat, centre_lon,
			data.latitude, data.longitude))
		_log("STREAM gen %d: revived a built stretch %.0f m ahead at %.1f m/s" % [
			gen, xz.distance_to(pos), _vel.length()])
		_scout.plan(v, pos, xz, step_m(_pace, expected_build_s(v._quality_preset)))
		return true
	return false

## Charges this frame to the phase it belongs to (see _worst), and logs
## the swap's frames once they have passed.
func _note_frame(delta: float) -> void:
	var phase: String = "swap+%d" % (4 - _after_swap) if _after_swap > 0 else \
		["idle", "fetch", "ready", "degraded"][state]
	if phase == "fetch" and _fetched_msec > 0:
		phase = "build"
	_worst[phase] = maxf(float(_worst.get(phase, 0.0)), delta * 1000.0)
	if _after_swap > 0:
		_after_swap -= 1
		if _after_swap == 0:
			_log("STREAM swap: %s" % _worst_line(["swap call", "swap+0", "swap+1", "swap+2", "swap+3"]))
			_worst.clear()

## Prints `line` and keeps it in LOG_PATH too: Godot keeps only its last
## few session logs, so a flight's timings were gone by the time anyone
## looked. The file starts over past LOG_MAX_BYTES.
const LOG_PATH := "user://logs/stream.log"
const LOG_MAX_BYTES := 1 << 20

static func _log(line: String) -> void:
	print(line)
	if DisplayServer.get_name() == "headless":
		return  # tests and tools keep their own output
	DirAccess.make_dir_recursive_absolute(LOG_PATH.get_base_dir())
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE) if FileAccess.file_exists(LOG_PATH) \
		else FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		return
	if f.get_length() > LOG_MAX_BYTES:
		f.close()
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if f == null:
			return
	f.seek_end()
	f.store_line("%s %s" % [Time.get_datetime_string_from_system(), line])
	f.close()

func _worst_line(phases: Array) -> String:
	var parts: Array[String] = []
	for p in phases:
		if _worst.has(p):
			parts.append("%s %.1f ms" % [p, _worst[p]])
	return "worst frame " + ", ".join(parts)

func _start_generation(v: View360, pos: Vector2, look: Vector2) -> void:
	_warmed = true
	var expected := expected_build_s(v._quality_preset)
	var target := step_target(pos, _planned_vel(), look, expected)
	if _revive(v, pos, target - pos):
		return
	# A centre fetched ahead or around (or built a moment ago, a turn
	# then a U-turn): build that one, its data already on disk.
	var planned := false
	var reused := false
	var ll := _scout.pick(pos, target - pos, v._data.latitude, v._data.longitude)
	if ll != Vector2.INF:
		planned = ll == _scout.plan_ll
		reused = not planned
		target = WorldScale.xz_from_latlon(ll.x, ll.y, v._data.latitude, v._data.longitude)
	else:
		ll = WorldScale.latlon_from_xz(target.x, target.y, v._data.latitude, v._data.longitude)
	_scout.plan_ll = Vector2.INF
	_scout.note(ll)
	var gen := begin(ll, target)
	_scout.plan(v, pos, target, step_m(_pace, expected))
	_started_msec = Time.get_ticks_msec()
	_fetched_msec = 0
	for p in ["fetch", "build", "ready"]:
		_worst.erase(p)
	_log("STREAM gen %d: start %.0f m ahead at %.1f m/s (expect %.1f s)%s" % [gen,
		target.distance_to(pos), _vel.length(), expected, ", fetched ahead" if planned else (", reused" if reused else "")])
	_abort = BuildAbort.new()
	_abort.background = true
	# A fresh pipeline per generation: a reused one aliases runs (its
	# cancel flag and stage counters are shared), so a stale finish
	# could claim the next generation. The token guards it regardless.
	if _pipeline != null:
		_pipeline.cancel()
		_pipeline.queue_free()
	_pipeline = GenerationPipeline.new()
	_pipeline.background = true
	v.add_child(_pipeline)
	var pipe := _pipeline
	var p := SaveProgress.new()
	p.rows = GenerationPipeline.STAGES.size()
	progress = p
	stages_done.resize(p.rows)
	stages_done.fill(false)
	_stage_s = {}
	pipe.stage_changed.connect(func(i: int, _label: String, st: String) -> void:
		if p == progress and st == "done" and not stages_done[i]:
			stages_done[i] = true
			_stage_s[i] = (Time.get_ticks_msec() - _started_msec) / 1000.0
			p.stage_done(i))
	pipe.stage_progress.connect(func(i: int, done: int, total: int) -> void:
		if p == progress and not stages_done[i]:
			p.stage_progress(i, done, total))
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
	# The pipeline built this centre's ground already: take it (frame by
	# frame) rather than build it again, and before freeing the pipeline,
	# whose predelete would otherwise block on that task.
	var ground: GroundTruth = null
	if gen == generation and state == State.FETCHING:
		ground = await pipe.ground_for(data)
	if is_instance_valid(pipe):
		pipe.queue_free()
	if not is_instance_valid(v) or gen != generation or state != State.FETCHING \
			or v._data == null:
		return
	_fetched_msec = Time.get_ticks_msec()
	# The streamed centre inherits the live view's season and carries no
	# opening view of its own: the camera, not the data, says where we are.
	data.season = v._data.season
	data.view = {}
	data.focus = {}
	if progress != null:
		progress.phase = SaveProgress.Phase.BUILD
	var built := await v.build_location(data, ground, _abort)
	if gen != generation:
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return
	if built.is_empty():
		mark_failed(gen, "build stopped")
		ViewTools.say(v, "Couldn't prepare the way ahead",
			"Still exploring on distant ground; will try again as you go.", "caution")
		return
	# The vehicle plans, ahead and off the main thread (VehicleMover).
	var plan_ground: GroundTruth = built[0] if built.size() > 0 else null
	await FrameTask.run(VehicleMover.plan_ahead.bind(data, plan_ground), "Vehicle plans", v.get_tree())
	if not is_instance_valid(v) or gen != generation:
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return
	if not mark_ready(gen):
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return
	var now := Time.get_ticks_msec()
	var took := (now - _started_msec) / 1000.0
	note_build_s(v._quality_preset, took)
	if not _abort.deferred_save.is_empty():
		_unsaved = _abort.deferred_save  # the newer stretch replaces it
	var stages: Array[String] = []
	for i in _stage_s:
		stages.append("%s %.1f s" % [GenerationPipeline.STAGES[i], _stage_s[i]])
	_log("STREAM gen %d: fetch %.1f s (%s), build %.1f s, total %.1f s (expect next %.1f s); %s" % [
		gen, (_fetched_msec - _started_msec) / 1000.0, ", ".join(stages),
		(now - _fetched_msec) / 1000.0, took, expected_build_s(v._quality_preset),
		_worst_line(["fetch", "build"])])
	# Range the LOD rings while the world waits to swap in, a few
	# subtrees per tick, so neither this frame nor the swap frame
	# pays for the whole walk.
	begin_ranging(built[1] as Node3D, v._quality_preset)
	_ready = built
	_ready_data = data
