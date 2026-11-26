class_name StreamSteering
extends RefCounted

## Heading-stability, hysteresis, build-phase abort protection, and drop
## cooldown for WorldStreamer. Prevents casual banking turns or brief
## look-backs from cancelling 10-20 s streamed builds in a thrash cascade.

## Seconds a reverse near the centre must hold before dropping a READY world.
const STALE_HOLD_S := 1.2
## Seconds off-heading must hold before dropping a READY or FETCHING stretch.
const VEER_READY_HOLD_S := 3.0
const VEER_FETCH_HOLD_S := 4.0
## Minimum angular divergence (degrees) from the pending target before a
## heading counts as a veer (gentle curves keep the stretch).
const VEER_CONE_DEG := 55.0
## Cooldown after a heading-induced drop before starting a fresh build
## (bypassed when already near the detailed edge).
const DROP_COOLDOWN_S := 2.0

var stale_s := 0.0
var cooldown_s := 0.0

func reset() -> void:
	stale_s = 0.0
	cooldown_s = 0.0

func tick_cooldown(delta: float) -> void:
	cooldown_s = maxf(cooldown_s - delta, 0.0)

func note_drop() -> void:
	stale_s = 0.0
	cooldown_s = DROP_COOLDOWN_S

func cooling_down(near_edge: bool) -> bool:
	return cooldown_s > 0.0 and not near_edge

## True when `vel` diverges from `to_target` by more than VEER_CONE_DEG.
static func diverged(vel: Vector2, to_target: Vector2) -> bool:
	if vel.length_squared() < 1e-4 or to_target.length_squared() < 1e-4:
		return false
	var cos_ang := vel.normalized().dot(to_target.normalized())
	return cos_ang < cos(deg_to_rad(VEER_CONE_DEG))

## Advances the stale-turn hold timer; returns true once held for STALE_HOLD_S
## (or immediately if `off_both` is true — camera already left both squares).
func check_stale(is_stale: bool, off_both: bool, delta: float) -> bool:
	if not is_stale:
		stale_s = 0.0
		return false
	if off_both:
		stale_s = 0.0
		return true
	stale_s += delta
	if stale_s >= STALE_HOLD_S:
		stale_s = 0.0
		return true
	return false

## Whether a veered heading should drop a build in flight: never cancel once
## the fetch has already finished and worker threads are in the BUILD phase.
static func allow_veer_drop(miss_s: float, is_fetching: bool, in_build: bool,
		vel: Vector2, to_target: Vector2) -> bool:
	if is_fetching and in_build:
		return false
	var hold := VEER_FETCH_HOLD_S if is_fetching else VEER_READY_HOLD_S
	return miss_s >= hold and diverged(vel, to_target)
