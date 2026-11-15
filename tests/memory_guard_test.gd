extends SceneTree

## Memory guard: godot --headless --script tests/memory_guard_test.gd
## Levels rise at once and fall one at a time after a hold; the OS warning
## jumps to CRITICAL; each level closes what it should (parking, scouts,
## saves, streaming, the preset).

const L := MemoryGuard.Level

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	# Pure decision: thresholds.
	_check(MemoryGuard.decide(0.50, L.OK, 0.0) == L.OK, "50% stays OK")
	_check(MemoryGuard.decide(0.72, L.OK, 0.0) == L.TIGHT, "72% is TIGHT")
	_check(MemoryGuard.decide(0.85, L.OK, 0.0) == L.CRITICAL, "85% jumps straight to CRITICAL")
	_check(MemoryGuard.decide(0.95, L.TIGHT, 0.0) == L.EMERGENCY, "95% is EMERGENCY")
	# Release: one level at a time, only after the hold, only well below.
	_check(MemoryGuard.decide(0.50, L.CRITICAL, 5.0) == L.CRITICAL, "no release before the hold")
	_check(MemoryGuard.decide(0.50, L.CRITICAL, MemoryGuard.RELEASE_HOLD_S) == L.TIGHT,
		"after the hold a level falls by one, not to OK")
	_check(MemoryGuard.releasing(0.75, L.CRITICAL) == false, "75% is not far enough under CRITICAL")
	_check(MemoryGuard.releasing(0.65, L.CRITICAL), "65% counts towards releasing CRITICAL")
	_check(not MemoryGuard.releasing(0.10, L.OK), "OK has nothing to release")

	# A guard driven through readings.
	MemoryGuard.reset()
	var g := MemoryGuard.new()
	var levels: Array[int] = []
	g.level_changed.connect(func(l: int) -> void: levels.append(l))
	g.poll(0.82, 1.0)
	_check(MemoryGuard.level == L.CRITICAL, "a reading at 82% sets CRITICAL")
	for i in 19:
		g.poll(0.60, 1.0)
	_check(MemoryGuard.level == L.CRITICAL, "19 s under the margin is not yet a release")
	g.poll(0.60, 1.0)
	_check(MemoryGuard.level == L.TIGHT, "20 s under the margin releases one level")
	g.poll(0.75, 1.0)
	g.poll(0.55, 1.0)
	_check(MemoryGuard.level == L.TIGHT, "the hold restarts on the new level")
	_check(levels == [L.CRITICAL, L.TIGHT], "level_changed reports each change once: %s" % str(levels))
	# The OS warning: CRITICAL at once, held while readings look fine.
	MemoryGuard.reset()
	g.warn()
	_check(MemoryGuard.level == L.CRITICAL, "a memory warning jumps to CRITICAL")
	for i in 25:
		g.poll(0.30, 1.0)
	_check(MemoryGuard.level == L.CRITICAL, "the warning holds CRITICAL while it lasts")

	# What each level closes.
	MemoryBudget.tier_override = MemoryBudget.Tier.T2
	MemoryGuard.reset()
	_check(MemoryGuard.save_allowed() and MemoryGuard.stream_allowed(), "OK allows saves and streaming")
	_check(ParkedWorlds.cap() == 2 and StreamScout.warm_max() == 2, "T2 parks 2 and warms 2")
	MemoryGuard.level = L.TIGHT
	_check(not MemoryGuard.save_allowed() and not MemoryGuard.save_dropped(), "TIGHT makes saves wait")
	_check(ParkedWorlds.cap() == 0, "TIGHT parks nothing")
	_check(StreamScout.warm_max() == 0, "TIGHT warms nothing ahead")
	_check(MemoryGuard.stream_allowed(), "TIGHT still streams")
	MemoryGuard.level = L.EMERGENCY
	_check(MemoryGuard.save_dropped(), "EMERGENCY drops saves")
	_check(not MemoryGuard.stream_allowed(), "EMERGENCY starts no new stretch")
	MemoryBudget.tier_override = MemoryBudget.Tier.T1
	MemoryGuard.reset()
	_check(ParkedWorlds.cap() == 1 and StreamScout.warm_max() == 1, "T1 parks 1 and warms 1")
	MemoryBudget.tier_override = MemoryBudget.Tier.T0
	_check(ParkedWorlds.cap() == 0 and StreamScout.warm_max() == 0, "T0 parks and warms nothing")

	# EMERGENCY asks once for a lower preset.
	MemoryGuard.reset()
	g.poll(0.95, 1.0)
	_check(MemoryGuard.take_preset_drop(), "EMERGENCY asks for a preset drop")
	_check(not MemoryGuard.take_preset_drop(), "the preset drop is taken once")

	# Parked worlds: oldest leave past the cap, all leave when memory is short.
	MemoryBudget.tier_override = MemoryBudget.Tier.T3
	MemoryGuard.reset()
	var retired: Array = []
	var parked := ParkedWorlds.new(func(w: Node3D) -> void: retired.append(w))
	var data := LocationData.new()
	var ground := GroundTruth.new(null)  # an empty ground: only its presence counts
	var worlds: Array[Node3D] = [Node3D.new(), Node3D.new(), Node3D.new()]
	for i in worlds.size():
		parked.park(worlds[i], data, ground, Vector2(60.0 + i * 0.01, 25.0))
	_check(parked.size() == 2 and retired == [worlds[0]], "the oldest leaves past the cap")
	_check(not worlds[1].visible, "a parked world is hidden")
	parked.park(Node3D.new(), null, ground, Vector2.ZERO)
	_check(retired.size() == 2 and parked.size() == 2, "a world without its data is not parked")
	var took := parked.take(func(e: Dictionary) -> bool: return e["world"] == worlds[1])
	_check(took.get("world") == worlds[1] and parked.size() == 1, "take() returns the matching entry")
	_check(parked.take(func(_e: Dictionary) -> bool: return false).is_empty(), "take() with no match is empty")
	MemoryGuard.level = L.TIGHT
	parked.trim()
	_check(parked.size() == 0, "TIGHT frees every parked world")
	MemoryGuard.level = L.OK
	var near := Node3D.new()
	parked.park(near, data, ground, Vector2(60.0, 25.0))
	parked.park(worlds[1], data, ground, Vector2(60.5, 25.0))
	parked.prune(60.0, 25.0, 1000.0)
	_check(parked.size() == 1 and retired.has(worlds[1]) and not retired.has(near),
		"prune frees only the world too far from the centre")
	near.free()

	for w in worlds:
		if is_instance_valid(w):
			w.free()
	for w in retired:
		if is_instance_valid(w):
			w.free()
	g.free()
	MemoryGuard.reset()
	MemoryBudget.tier_override = -1
	if _failures.is_empty():
		print("MEMORY GUARD PASS")
		quit(0)
	else:
		for f in _failures:
			printerr("MEMORY GUARD FAIL: ", f)
		quit(1)
