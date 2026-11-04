class_name BuildAbort
extends RefCounted

## Stop request and progress for ONE world build. Set from the main thread
## (generation timeout or cancel); TerrainBuilder.build_world checks it at
## each stage boundary on the build thread, and marks the phase it enters
## there so the loading screen can show how far along the build is. Per
## build, not global: a season rebuild running beside the generation build
## must neither clear nor trip it.

## Build phases in order. Each one's `weight` is its rough share of the
## wait (sums to 1.0). The stages run at once (WorldBuildGraph) and the
## bar shows the first unfinished one: on Paris High distant terrain
## ends at ~3 s, ground, roads and vegetation inside the buildings'
## ~11.6 s, then the merge.
enum Step { FAR, GROUND, BUILDINGS, ROADS, VEGETATION, MERGE }
const STEPS: Array[Dictionary] = [
	{"label": "Distant terrain", "weight": 0.22},
	{"label": "Ground & water", "weight": 0.04},
	{"label": "Buildings", "weight": 0.6},
	{"label": "Roads & landmarks", "weight": 0.03},
	{"label": "Vegetation", "weight": 0.03},
	{"label": "Finishing", "weight": 0.08},
]

var requested := false
## The built world is being written to the world cache (set by
## View360.build_location when the caller waits for the save).
var saving := false
## The phase the build thread is in (a Step); read by the main thread.
var step := 0
## Per-step wall-clock ms (filled by the build). Key = Step int.
var ms: Dictionary = {}
## Steps finished (the parallel build ends them out of order).
var _done: Array[bool] = [false, false, false, false, false, false]
var _mutex := Mutex.new()

## Marks the build as entering `s`. `abort` may be null (no listener).
static func mark(abort: BuildAbort, s: Step) -> void:
	if abort != null:
		abort.step = s

## Thread-safe: marks step `s` done and moves `step` to the first step
## not done yet, so the shown phase never goes backwards.
func mark_done(s: Step) -> void:
	_mutex.lock()
	_done[int(s)] = true
	var first := _done.find(false)
	step = first if first >= 0 else Step.MERGE
	_mutex.unlock()

func set_ms(key: int, val: int) -> void:
	_mutex.lock()
	ms[key] = val
	_mutex.unlock()

func timings_line() -> String:
	_mutex.lock()
	var snap: Dictionary = ms.duplicate()
	_mutex.unlock()
	var keys: Array = snap.keys()
	keys.sort()
	var parts: Array[String] = []
	for k in keys:
		parts.append("%s=%d" % [label_of(int(k)), int(snap[k])])
	return "BUILD timings {%s}" % ", ".join(parts)

## Share of the whole build finished before phase `index` starts.
static func fraction_before(index: int) -> float:
	var f := 0.0
	for i in mini(index, STEPS.size()):
		f += float(STEPS[i]["weight"])
	return f

static func label_of(index: int) -> String:
	return str(STEPS[clampi(index, 0, STEPS.size() - 1)]["label"])
