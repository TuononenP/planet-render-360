class_name MemoryGuard
extends Node

## Keeps the app under its memory limit (MemoryBudget) by shedding what
## it can rebuild, in a fixed order, as the footprint nears the limit:
##   TIGHT      no parked stretches, no scouts warming stretches ahead,
##              world-cache saves wait (each copies the whole world)
##   CRITICAL   a held-back streamed save is let go, the QualityGovernor
##              is held at its lowest step (smaller render targets)
##   EMERGENCY  saves are skipped, no new stretch starts while streaming,
##              and the next world is built one preset lower (with a note)
## Each level includes those above it. A level is taken at once and given
## back one at a time, only after the footprint has stayed RELEASE_MARGIN
## under it for RELEASE_HOLD_S. iOS's memory warning (main.gd) jumps to
## CRITICAL for WARN_HOLD_S. Consumers read the static `level`; one guard
## runs (main.gd). Off in headless runs, where the counters mean nothing.

signal level_changed(level: int)

enum Level { OK, TIGHT, CRITICAL, EMERGENCY }
## Share of the limit at which each level starts.
const THRESHOLDS: Array[float] = [0.0, 0.70, 0.80, 0.90]
const RELEASE_MARGIN := 0.10
const RELEASE_HOLD_S := 20.0
const WARN_HOLD_S := 30.0
const POLL_S := 1.0
const NAMES := ["ok", "tight", "critical", "emergency"]

## The level now, read by WorldStreamer, StreamScout, ParkedWorlds,
## WorldCache and QualityGovernor.
static var level: int = Level.OK
## Set on reaching EMERGENCY; the next world build takes it (take_preset_drop).
static var _drop_preset := false

var _below_s := 0.0
var _warn_left := 0.0
var _wait := 0.0

func _ready() -> void:
	set_process(DisplayServer.get_name() != "headless")

## The level for a footprint at `usage` of the limit, from `current`, when
## usage has been low enough to release `current` for `below_s`. Pure.
static func decide(usage: float, current: int, below_s: float) -> int:
	var target: int = Level.OK
	for i in THRESHOLDS.size():
		if usage >= THRESHOLDS[i]:
			target = i
	if target >= current:
		return target
	return current - 1 if below_s >= RELEASE_HOLD_S else current

## Whether `usage` sits low enough under `current` to count towards
## releasing it. Pure.
static func releasing(usage: float, current: int) -> bool:
	return current > Level.OK and usage < THRESHOLDS[current] - RELEASE_MARGIN

func _process(delta: float) -> void:
	_warn_left = maxf(_warn_left - delta, 0.0)
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = POLL_S
	poll(MemoryBudget.usage(), POLL_S)

## One reading: `usage` of the limit, `dt` seconds since the last.
func poll(usage: float, dt: float) -> void:
	_below_s = _below_s + dt if releasing(usage, level) else 0.0
	var next := decide(usage, level, _below_s)
	if _warn_left > 0.0:
		next = maxi(next, Level.CRITICAL)
	_apply_level(next, usage)

## The OS says memory is low (iOS didReceiveMemoryWarning).
func warn() -> void:
	_warn_left = WARN_HOLD_S
	_apply_level(maxi(level, Level.CRITICAL), MemoryBudget.usage())

func _apply_level(next: int, usage: float) -> void:
	if next == level:
		return
	_below_s = 0.0
	level = next
	if next >= Level.EMERGENCY:
		_drop_preset = true
	WorldStreamer._log("MEM guard %s at %d%% of the limit: %s" % [NAMES[next],
		roundi(usage * 100.0), MemoryLog.summary()])
	level_changed.emit(next)

## Whether a world-cache save may start now (it copies the whole world).
static func save_allowed() -> bool:
	return level < Level.TIGHT

## Whether a save should be dropped rather than wait (the world rebuilds
## next time instead).
static func save_dropped() -> bool:
	return level >= Level.EMERGENCY

## Whether a new streamed stretch may start.
static func stream_allowed() -> bool:
	return level < Level.EMERGENCY

## True once after EMERGENCY: the next world is built a preset lower.
static func take_preset_drop() -> bool:
	var d := _drop_preset
	_drop_preset = false
	return d

## Back to OK (tests; a new session).
static func reset() -> void:
	level = Level.OK
	_drop_preset = false
