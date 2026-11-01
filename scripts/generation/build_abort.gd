class_name BuildAbort
extends RefCounted

## Stop request and progress for ONE world build. Set from the main thread
## (generation timeout or cancel); TerrainBuilder.build_world checks it at
## each stage boundary on the build thread, and marks the phase it enters
## there so the loading screen can show how far along the build is. Per
## build, not global: a season rebuild running beside the generation build
## must neither clear nor trip it.

## Build phases in order. Each one's `weight` is its rough share of the
## wait (sums to 1.0): buildings dominate on a dense city.
enum Step { FAR, GROUND, BUILDINGS, ROADS, VEGETATION, MERGE }
const STEPS: Array[Dictionary] = [
	{"label": "Distant terrain", "weight": 0.12},
	{"label": "Ground & water", "weight": 0.2},
	{"label": "Buildings", "weight": 0.33},
	{"label": "Roads & landmarks", "weight": 0.1},
	{"label": "Vegetation", "weight": 0.15},
	{"label": "Finishing", "weight": 0.1},
]

var requested := false
## The phase the build thread is in (a Step); read by the main thread.
var step := 0

## Marks the build as entering `s`. `abort` may be null (no listener).
static func mark(abort: BuildAbort, s: Step) -> void:
	if abort != null:
		abort.step = s

## Share of the whole build finished before phase `index` starts.
static func fraction_before(index: int) -> float:
	var f := 0.0
	for i in mini(index, STEPS.size()):
		f += float(STEPS[i]["weight"])
	return f

static func label_of(index: int) -> String:
	return str(STEPS[clampi(index, 0, STEPS.size() - 1)]["label"])
