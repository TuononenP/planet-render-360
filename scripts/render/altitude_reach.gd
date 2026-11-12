class_name AltitudeReach
extends RefCounted

## More distant detail while the drone flies high. From ON_AGL_M up the
## camera sees far past the detailed extent, so, while the GPU has
## headroom, the view:
##  - widens the LOD rings (LodRing.altitude_boost: roofline detail,
##    trees and far-city bands about one tier further), re-ranging the
##    world a few subtrees a frame;
##  - after BUILD_AFTER_S, rebuilds the far terrain off the main thread
##    with denser rings (FarTerrainBuilder.ALT_RING_SEGS; Balanced also
##    gets High's DEM relief normals) and swaps it in for the built one,
##    which is kept detached so dropping back is instant.
## It drops back below OFF_AGL_M, when the drone lands, on a slow window
## (held off for a doubling HOLD_S, as QualityGovernor holds its steps)
## and on a preset change. The boosted far terrain is never cached.
## One instance per view (View360._reach); the rules are static or pure
## state so tests can drive them.

const ON_AGL_M := 300.0
const OFF_AGL_M := 250.0
## Healthy governor windows (at its ceiling, >= UP_FPS) before boosting.
const UP_WINDOWS := 2
const HOLD_S := 30.0
const HOLD_MAX_S := 240.0
## Seconds the boost must hold before the far terrain is rebuilt.
const BUILD_AFTER_S := 3.0
## Top-level world subtrees re-ranged per frame after a toggle.
const RANGE_SLICES := 16

## Whether a drone `agl` metres up wants the boost, given whether it
## has it (`was_on`): the gap between the two heights stops flicker.
static func wants_boost(agl: float, was_on: bool) -> bool:
	return agl >= (OFF_AGL_M if was_on else ON_AGL_M)

## Ring density of the boosted far terrain for base `preset`.
static func far_segs(preset: int) -> int:
	return FarTerrainBuilder.ALT_RING_SEGS[RenderSettings.clamp_preset(preset)]

## Preset the boosted far terrain is built at: Balanced gains High's
## relief normals; High and Ultra keep their own textures (Ultra-desktop
## 2048 px layers would cost far more memory than the rings).
static func far_preset(preset: int) -> int:
	return maxi(RenderSettings.clamp_preset(preset), RenderSettings.Preset.HIGH)

## A shallow copy of `data` (arrays and dictionaries shared, read-only
## to the far builders) at `preset`.
static func data_at(data: LocationData, preset: int) -> LocationData:
	var out := LocationData.new()
	for p in data.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.set(p["name"], data.get(p["name"]))
	out.quality_preset = preset
	return out

## True while the GPU gate is open (enough healthy windows, no hold).
var gpu_ok := false
## Whether the boost is on now.
var on := false

var _healthy := 0
var _clock := 0.0
var _hold_until := 0.0
var _hold_s := HOLD_S
var _gov: QualityGovernor
var _on_clock := 0.0
var _world_id := 0
## The boost toggled since the world was last replaced: a streamed world
## ranged meanwhile may hold either ring set, so it is re-ranged.
var _toggled := false
var _range_world: Node
var _range_cursor := 0
var _range_preset := 0
# Far rebuild: the build in flight, the swapped-in node and the
# original it replaced (detached, kept for the drop back).
var _thread: Thread
var _abort: BuildAbort
var _build_world_id := 0
var _boosted: Node3D
var _base: Node3D

## One governor window of `window_s` seconds averaging `fps`, with the
## governor `at_ceiling` (not stepping down). Pure gate state machine.
func window(fps: float, at_ceiling: bool, window_s: float = QualityGovernor.WINDOW_S) -> void:
	_clock += window_s
	if fps < QualityGovernor.DOWN_FPS or not at_ceiling:
		_healthy = 0
		if gpu_ok:
			gpu_ok = false
			_hold_until = _clock + _hold_s
			_hold_s = minf(_hold_s * 2.0, HOLD_MAX_S)
		return
	if fps >= QualityGovernor.UP_FPS:
		_healthy += 1
		if _healthy >= UP_WINDOWS and _clock >= _hold_until:
			gpu_ok = true

## Once a frame from View360._process.
func tick(v: View360, delta: float) -> void:
	if v._governor != null and v._governor != _gov:
		_gov = v._governor
		_gov.quality_changed.connect(func(_label: String, fps: float) -> void:
			window(fps, _gov.step >= _gov.ceiling_step))
	var world := v._generated.get_instance_id() if is_instance_valid(v._generated) else 0
	if world != _world_id:
		_world_id = world
		_drop_far()
		if (on or _toggled) and world != 0:
			_begin_ranging(v._generated, v._quality_preset)
		_toggled = false
	var agl := v._drone._agl if v._drone.on else 0.0
	var want := v._drone.on and gpu_ok and wants_boost(agl, on)
	if want != on:
		_set_on(v, want)
	_on_clock = _on_clock + delta if on else 0.0
	_pump_ranging()
	_tick_far(v)

## Drops the boost at once (preset change, view closing). `rerange`
## false when the caller re-ranges the whole world itself.
func reset(v: View360, rerange: bool = true) -> void:
	if on:
		_set_on(v, false, rerange)

func _set_on(v: View360, value: bool, rerange: bool = true) -> void:
	on = value
	_toggled = true
	LodRing.altitude_boost = value
	if not value:
		_revert_far(v)
	if rerange and is_instance_valid(v._generated):
		_begin_ranging(v._generated, v._quality_preset)
	else:
		_range_world = null

func _begin_ranging(world: Node, preset: int) -> void:
	_range_world = world
	_range_cursor = 0
	_range_preset = preset

func _pump_ranging() -> void:
	if _range_world == null:
		return
	if not is_instance_valid(_range_world):
		_range_world = null
		return
	var stop := mini(_range_world.get_child_count(), _range_cursor + RANGE_SLICES)
	while _range_cursor < stop:
		LodRing.apply_child(_range_world, _range_cursor, _range_preset)
		_range_cursor += 1
	if _range_cursor >= _range_world.get_child_count():
		_range_world = null

# --- Far terrain rebuild ---

func _tick_far(v: View360) -> void:
	if _thread != null:
		if _thread.is_alive():
			return
		v._threads.erase(_thread)
		var far: Node3D = _thread.wait_to_finish()
		_thread = null
		var stale := _abort.requested or not on or _build_world_id != _world_id \
			or not is_instance_valid(v._generated)
		_abort = null
		if far != null and stale:
			far.free()
		elif far != null:
			_swap_in(v, far)
		return
	if not on or _boosted != null or _on_clock < BUILD_AFTER_S:
		return
	if v._quality_preset < RenderSettings.Preset.BALANCED or v._data == null or v._ground == null:
		return
	# The far build shares static caches with world builds: never beside one.
	if v._season_building or v.has_running_threads() \
			or v._streamer.state in [WorldStreamer.State.FETCHING, WorldStreamer.State.READY]:
		return
	if _find_far(v._generated) == null:
		return
	_start_build(v)

func _start_build(v: View360) -> void:
	var preset := far_preset(v._quality_preset)
	var data := data_at(v._data, preset)
	var ground := v._ground
	var segs := far_segs(v._quality_preset)
	var abort := BuildAbort.new()
	# Loaded here: a worker would wait on the main thread for the arrays.
	TerrainTextures.arrays(TerrainTextures.size_for(preset))
	_abort = abort
	_build_world_id = _world_id
	_thread = Thread.new()
	v._threads.append(_thread)
	_thread.start(func() -> Node3D:
		var far := FarTerrainBuilder.build_far(data, ground, abort, segs)
		if abort.requested:
			far.free()
			return null
		return far)

func _swap_in(v: View360, far: Node3D) -> void:
	var base := _find_far(v._generated)
	if base == null:
		far.free()
		return
	var world := v._generated
	var index := base.get_index()
	world.remove_child(base)
	world.add_child(far)
	world.move_child(far, index)
	LodRing.apply_child(world, index, v._quality_preset)
	_base = base
	_boosted = far

## The built far terrain back in place of the boosted one; a build in
## flight is stopped (its result is freed when the thread ends).
func _revert_far(v: View360) -> void:
	if _abort != null:
		_abort.requested = true
	if _boosted == null:
		return
	if is_instance_valid(_boosted) and is_instance_valid(_base) and _boosted.get_parent() != null:
		var world := _boosted.get_parent()
		var index := _boosted.get_index()
		world.remove_child(_boosted)
		_boosted.free()
		world.add_child(_base)
		world.move_child(_base, index)
		LodRing.apply_child(world, index, v._quality_preset)
		_base = null
	_boosted = null
	_drop_far()

## Forgets the far swap of a replaced world: the boosted node went with
## it; the detached original is freed here.
func _drop_far() -> void:
	if _abort != null:
		_abort.requested = true
	if _base != null and is_instance_valid(_base):
		_base.free()
	_base = null
	_boosted = null

static func _find_far(world: Node) -> Node3D:
	if world == null or not is_instance_valid(world):
		return null
	return world.get_node_or_null("FarTerrain") as Node3D

func _notification(what: int) -> void:
	# Inline: a RefCounted's methods are gone by PREDELETE.
	if what == NOTIFICATION_PREDELETE:
		if on:
			LodRing.altitude_boost = false
		if _base != null and is_instance_valid(_base):
			_base.free()
