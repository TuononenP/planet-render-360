extends SceneTree

## Stream leak & static-cache audit:
##   tools/godot_bg.sh --headless --path . --script tests/stream_leak_test.gd
## Verifies off-tree Node3Ds in WorldHandoff / ParkedWorlds are freed on
## clear()/forget(), StaticCaches.release_all() and trim_for_pressure() run
## cleanly, and high-RAM desktops cap at DESKTOP_MAX_LIMIT.

const GB := 1 << 30
var _failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _run() -> void:
	# 1. WorldHandoff.clear() must free detached retiring & staged worlds.
	var wh := WorldHandoff.new()
	var detached_retiring := Node3D.new()
	detached_retiring.add_child(Node3D.new())
	var detached_staged := Node3D.new()
	wh.staged = detached_staged
	wh.retire(detached_retiring)
	wh.clear()
	_check(not is_instance_valid(detached_retiring), "WorldHandoff.clear frees detached retiring world")
	_check(not is_instance_valid(detached_staged), "WorldHandoff.clear frees detached staged world")

	# 2. ParkedWorlds.forget() must free detached parked worlds (not leak them).
	MemoryBudget.tier_override = MemoryBudget.Tier.T3
	MemoryGuard.reset()
	var pw := ParkedWorlds.new(func(w: Node3D) -> void:
		if is_instance_valid(w):
			w.free())
	var parked_detached := Node3D.new()
	pw.park(parked_detached, LocationData.new(), GroundTruth.new(null), Vector2(60.17, 24.94))
	pw.forget()
	_check(not is_instance_valid(parked_detached), "ParkedWorlds.forget frees detached parked world")
	_check(pw.size() == 0, "ParkedWorlds.forget empties list")

	# 3. High-RAM desktop cap keeps MemoryGuard responsive on 64-128 GB Macs.
	_check(MemoryBudget.limit_for("desktop", 4 * GB, -1, 128 * GB) == MemoryBudget.DESKTOP_MAX_LIMIT,
		"128 GB desktop caps at DESKTOP_MAX_LIMIT")
	_check(MemoryBudget.limit_for("desktop", 4 * GB, -1, 16 * GB) == 12 * GB,
		"16 GB desktop still plans on 12 GB")

	# 4. SharedShader & StaticCaches trim / release run cleanly and empty caches.
	var sh := SharedShader.of("shader_type spatial;")
	_check(sh != null, "SharedShader caches shader")
	StaticCaches.trim_for_pressure(MemoryGuard.Level.TIGHT)
	StaticCaches.trim_for_pressure(MemoryGuard.Level.CRITICAL)
	StaticCaches.release_all()
	_check(SharedShader._by_code.is_empty(), "StaticCaches.release_all clears SharedShader")
	_check(TreeMeshLibrary._meshes.is_empty(), "StaticCaches.release_all clears TreeMeshLibrary")
	_check(LandmarkShader._swapped.is_empty(), "StaticCaches.release_all clears LandmarkShader")
	_check(FarSurface._shader == null, "StaticCaches.release_all clears FarSurface._shader")

	MemoryBudget.tier_override = -1
	MemoryGuard.reset()
	if _failures.is_empty():
		print("STREAM LEAK PASS")
		quit(0)
	else:
		for f in _failures:
			printerr("STREAM LEAK FAIL: ", f)
		quit(1)
