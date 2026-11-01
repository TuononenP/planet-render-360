class_name TimeLapse
extends RefCounted

## Time-lapse of the sun arc: the day's daylight (sunrise to sunset) runs
## in DAY_S seconds at 1×, looping, at 1×, 2× or 4×. Polar day and night
## (no real sunrise or sunset) run the whole 24 h in the same time.
## Under Reduce motion the clock does not glide: it jumps one step per
## STEP_S (shortened by the speed), the same pace in coarse frames.
## Pure state and arithmetic; View360 feeds it frame deltas
## (ViewConditions.lapse_tick) and applies the minute it returns.

const DAY_S := 20.0
const SPEEDS: Array[int] = [1, 2, 4]
const STEP_S := 1.0
## Below this many daylight minutes the day is polar: run the full 24 h.
const MIN_DAYLIGHT := 60.0
## Frames are applied at most this often: the sky, city lights and the
## arc redraw on every applied minute.
const APPLY_S := 0.05

var playing := false
var speed_index := 0
var _idle := 0.0

func speed() -> int:
	return SPEEDS[speed_index]

## 1× -> 2× -> 4× -> 1×.
func cycle_speed() -> int:
	speed_index = (speed_index + 1) % SPEEDS.size()
	return speed()

func play() -> void:
	playing = true
	_idle = 0.0

func stop() -> void:
	playing = false

## The window of the day that plays, in minutes: sunrise to sunset, or the
## whole day when the sun never rises or never sets.
static func window(rise: float, set_m: float) -> Vector2:
	if set_m - rise < MIN_DAYLIGHT:
		return Vector2(0.0, 1440.0)
	return Vector2(rise, set_m)

## `minutes` after `dt` seconds at `speed`×: moved along the window and
## wrapped to its start, a minute outside it joining at the start.
static func advance(minutes: float, dt: float, rise: float, set_m: float, speed_x: int) -> float:
	var w := window(rise, set_m)
	var span := w.y - w.x
	var m := fposmod(minutes, 1440.0)
	if m < w.x or m >= w.y:
		m = w.x
	m += span / DAY_S * float(speed_x) * dt
	if m >= w.y:
		m = w.x + fmod(m - w.x, span)
	return m

## Seconds of play to apply after a frame of `delta`, or -1 when nothing
## should change yet (between applied frames, or between reduced-motion
## steps). The caller advances the clock by them (advance), so the sun's
## day is only looked up on frames that apply.
func tick(delta: float, reduced: bool) -> float:
	if not playing:
		return -1.0
	_idle += delta
	var every := STEP_S / float(speed()) if reduced else APPLY_S
	if _idle < every:
		return -1.0
	var dt := _idle
	_idle = 0.0
	return dt
