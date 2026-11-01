class_name WorldBuildGraph
extends RefCounted

## The world build with its stages running at once on WorkerThreadPool.
## Each builder reads only `data` and `ground` and returns a detached
## subtree; nothing writes either while they run. The builders couple
## only through static caches: those shared across stages are locked
## and keyed by content. PbrTextures' keys round tint and repeat, so it
## resolves each key's values by serial stage rank; its 64-entry cap
## falls back by insertion order, so a build that crosses it is rebuilt
## serially. Buildings and the far city stay one task (the
## facade caches, also capped, keep their serial order). Subtrees are
## adopted in the serial order, so the world is the same either way.

## True builds serially (tests and the bench compare the two). The
## parallel world matched the serial one byte for byte on Paris,
## Venice, Zermatt and Big Sur at every preset (tools/build_bench.gd).
static var force_serial := false

class Stage extends RefCounted:
	var step: int
	var fn: Callable
	var node: Node3D = null
	var ms := 0
	var task := -1
	var finished := false

## Called from the build thread (View360.build_location). On the main
## thread it builds serially: its tasks' RenderingServer calls would
## wait on a main thread that is blocked joining them.
static func build(data: LocationData, ground: GroundTruth, abort: BuildAbort = null) -> Node3D:
	if force_serial or OS.get_thread_caller_id() == OS.get_main_thread_id():
		return TerrainBuilder._build_serial(data, ground, abort)
	var t0 := Time.get_ticks_msec()
	# Caches the serial build clears or fills at a stage boundary are
	# prepared once here, before any task can race on them.
	# The far, ground and water stages run before the serial build clears
	# the PBR cache (at Buildings), so they see the last build's cache;
	# the later stages share the cleared one.
	var before_clear: Dictionary = MaterialLibrary._pbr_mats.duplicate()
	BuildingBuilder._suppress_begin_build = true
	FacadeMaterials.begin_build()
	BuildingMasses.begin_build()
	PbrTextures.begin_stages()
	TerrainTextures.arrays(TerrainTextures.size_for(data.quality_preset))
	TerrainBuilder._box_mesh()
	ArchitectureStyle._box_regions()
	var hide := TerrainBuilder.debug_hide_buildings
	var stages: Array[Stage] = [
		_stage(BuildAbort.Step.FAR, func() -> Node3D:
			return FarTerrainBuilder.build_far(data, ground, abort)),
		_stage(BuildAbort.Step.GROUND, func() -> Node3D:
			return TerrainBuilder._terrain_mesh(data, ground, abort)),
		_stage(BuildAbort.Step.GROUND, func() -> Node3D:
			return WaterBuilder.build_water(data, ground, abort)),
		_stage(BuildAbort.Step.BUILDINGS, func() -> Node3D:
			return null if hide else BuildingBuilder.build_buildings(data, ground, abort)),
		_stage(BuildAbort.Step.ROADS, func() -> Node3D:
			return null if data.buildings.is_empty() else RoadBuilder.build_roads(data, ground, abort)),
		_stage(BuildAbort.Step.ROADS, func() -> Node3D:
			var lm := Node3D.new()
			if data.landmark_type != "none":
				lm.add_child(TerrainBuilder._landmark(data, ground))
			TerrainBuilder._landmark_candidates(lm, data, ground)
			return lm),
		_stage(BuildAbort.Step.VEGETATION, func() -> Node3D:
			return VegetationBuilder.build_vegetation(data, ground, abort)),
	]
	var mutex := Mutex.new()
	for i in stages.size():
		var st := stages[i]
		var cache: Dictionary = before_clear if i <= 2 else MaterialLibrary._pbr_mats
		var run := func() -> void:
			var s0 := Time.get_ticks_msec()
			if abort == null or not abort.requested:
				PbrTextures.push_stage(cache, i)  # rank = serial stage order
				st.node = st.fn.call()
				PbrTextures.pop_stage()
			st.ms = Time.get_ticks_msec() - s0
			mutex.lock()
			st.finished = true
			_progress(abort, stages, st.step)
			mutex.unlock()
		st.task = WorkerThreadPool.add_task(run, true, "WorldBuild")
	for st in stages:
		WorkerThreadPool.wait_for_task_completion(st.task)
	BuildingBuilder._suppress_begin_build = false
	if (abort != null and abort.requested) or PbrTextures.cap_reached:
		for st in stages:
			if st.node != null:
				st.node.free()
		if abort != null and abort.requested:
			return Node3D.new()  # dropped by the caller
		print("WORLD BUILD: PBR material cap reached; rebuilding serially for exact order")
		return TerrainBuilder._build_serial(data, ground, abort)
	var root := Node3D.new()
	root.name = "GeneratedWorld"
	for i in stages.size():
		var n := stages[i].node
		if n == null:
			continue
		if i <= 2:
			root.add_child(n)  # FarTerrain, terrain mesh, Water
		elif i == 5:
			for c in n.get_children():  # landmark + candidates, as built
				n.remove_child(c)
				root.add_child(c)
			n.free()
		else:
			TerrainBuilder._adopt_flat(root, n)
	if abort != null:
		var ms := {}
		for st in stages:
			ms[st.step] = maxi(int(ms.get(st.step, 0)), st.ms)
		for s in ms:
			abort.set_ms(s, ms[s])
		print("%s total=%d parallel" % [abort.timings_line(), Time.get_ticks_msec() - t0])
	return root

static func _stage(step: int, fn: Callable) -> Stage:
	var s := Stage.new()
	s.step = step
	s.fn = fn
	return s

## Marks `step` done once all its stages have finished; BuildAbort keeps
## its `step` at the first unfinished one, so the bar never goes back.
static func _progress(abort: BuildAbort, stages: Array[Stage], step: int) -> void:
	if abort == null:
		return
	for st in stages:
		if st.step == step and not st.finished:
			return
	abort.mark_done(step)
