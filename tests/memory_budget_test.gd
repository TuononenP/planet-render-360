extends SceneTree

## Memory budget: godot --headless --script tests/memory_budget_test.gd
## The limit each platform plans under, the tier it falls in, and what a
## tier lets a world hold.

const MB := 1 << 20
const GB := 1 << 30

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	# iOS: the kill line is the footprint plus what the OS still gives.
	_check(MemoryBudget.limit_for("ios", 1200 * MB, 2100 * MB, 6 * GB) == 3300 * MB,
		"iOS limit is footprint + os_proc_available_memory")
	_check(MemoryBudget.limit_for("ios", -1, -1, 6 * GB) == 3 * GB,
		"iOS without the counter plans on half the RAM")
	# Android: a share of RAM, lower when the system has less to give.
	_check(MemoryBudget.limit_for("android", -1, -1, 6 * GB) == int(6 * GB * MemoryBudget.ANDROID_SHARE),
		"Android plans on its share of RAM")
	var squeezed := MemoryBudget.limit_for("android", 1000 * MB, 1500 * MB, 6 * GB)
	_check(squeezed == 2500 * MB - MemoryBudget.ANDROID_RESERVE,
		"Android takes the lower of its share and footprint + MemAvailable - reserve")
	# Desktop: a share of RAM.
	_check(MemoryBudget.limit_for("desktop", 4 * GB, -1, 16 * GB) == 12 * GB,
		"desktop plans on 75% of RAM")
	# Never planned below the floor, whatever the counters say.
	_check(MemoryBudget.limit_for("ios", 100 * MB, 0, 0) == MemoryBudget.MIN_LIMIT,
		"a misread counter never plans below MIN_LIMIT")
	# Tiers.
	_check(MemoryBudget.tier_for(2 * GB) == MemoryBudget.Tier.T0, "2 GB limit is T0")
	_check(MemoryBudget.tier_for(3300 * MB) == MemoryBudget.Tier.T1, "a 6 GB iPhone (3.3 GB) is T1")
	_check(MemoryBudget.tier_for(int(6 * GB * MemoryBudget.ANDROID_SHARE)) == MemoryBudget.Tier.T1,
		"a 6 GB Android phone is T1")
	_check(MemoryBudget.tier_for(int(8 * GB * MemoryBudget.ANDROID_SHARE)) == MemoryBudget.Tier.T2,
		"an 8 GB Android phone (4.4 GB share) is T2")
	_check(MemoryBudget.tier_for(5 * GB) == MemoryBudget.Tier.T2, "5 GB limit is T2")
	_check(MemoryBudget.tier_for(int(11 * GB * MemoryBudget.ANDROID_SHARE)) == MemoryBudget.Tier.T3,
		"a 12 GB Android phone (~11 GB reported) is T3")
	_check(MemoryBudget.tier_for(12 * GB) == MemoryBudget.Tier.T3, "a 16 GB desktop is T3")
	# Each per-tier table covers every tier and never grows downward.
	for table in [MemoryBudget.PARK_MAX, MemoryBudget.WARM_MAX, MemoryBudget.BUILDING_SCALE,
			MemoryBudget.CEILING_PRESET, MemoryBudget.TERRAIN_TEXTURE_MAX]:
		_check(table.size() == MemoryBudget.Tier.size(), "a tier table misses a tier")
		for i in range(1, table.size()):
			_check(table[i] >= table[i - 1], "a tier table shrinks with more memory: %s" % str(table))
	# The override drives limit, tier and caps (a phone tried on a desktop).
	MemoryBudget.limit_override = 3300 * MB
	_check(MemoryBudget.limit_bytes() == 3300 * MB, "limit_override sets the limit")
	MemoryBudget.tier_override = MemoryBudget.Tier.T1
	_check(MemoryBudget.ceiling_preset() == RenderSettings.Preset.HIGH, "T1 runs at most High")
	_check(MemoryBudget.cap_preset(RenderSettings.Preset.ULTRA) == RenderSettings.Preset.HIGH,
		"Ultra is held to High on T1")
	_check(MemoryBudget.cap_preset(RenderSettings.Preset.FAST) == RenderSettings.Preset.FAST,
		"a preset under the ceiling stays")
	MemoryBudget.tier_override = MemoryBudget.Tier.T0
	_check(MemoryBudget.ceiling_preset() == RenderSettings.Preset.BALANCED, "T0 runs at most Balanced")
	MemoryBudget.limit_override = -1
	MemoryBudget.tier_override = -1
	# The live read gives something sane on this machine.
	_check(MemoryBudget.limit_bytes() >= MemoryBudget.MIN_LIMIT, "the live limit is at least the floor")
	if MemoryBudget.platform() == "desktop":
		_check(MemoryBudget.tier() == MemoryBudget.Tier.T3, "a desktop is T3 whatever its RAM")
	# One footprint reading serves the limit, usage and the summary.
	_check(MemoryBudget.usage(2 * GB) > 0.0 and MemoryBudget.headroom_bytes(2 * GB) >= 0,
		"usage and headroom take a footprint already read")
	_check(MemoryBudget.summary().contains("tier T"), "the summary names the tier")
	if _failures.is_empty():
		print("MEMORY BUDGET PASS")
		quit(0)
	else:
		for f in _failures:
			printerr("MEMORY BUDGET FAIL: ", f)
		quit(1)
