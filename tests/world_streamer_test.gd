extends SceneTree

## Endless walk & fly: godot --headless --script tests/world_streamer_test.gd
## The WorldStreamer maths (trigger, step, remap, enterable, interim cap),
## its generation state machine, then a real View360: walking and flying
## cross the old IN_PLACE_M / EDGE_M circles when streaming is enabled, a
## centre swap keeps the camera over the same lat/lon, and a stale
## generation never swaps. Offline: no pipeline is auto-started here.

const CACHE := "user://world_streamer_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	CacheStore.dir_override = CACHE
	PlaceThumb.dir_override = CACHE + "/thumbs"
	WorldCache.dir_override = CACHE + "/worlds"
	DirAccess.make_dir_recursive_absolute(CACHE)
	_maths()
	_state_machine()
	_handoff()
	_reveal()
	await _badge()
	await _movement_and_swap()
	_clean(CACHE)
	CacheStore.dir_override = ""
	PlaceThumb.dir_override = ""
	WorldCache.dir_override = ""
	if failures.is_empty():
		print("world_streamer_test: PASS")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)

static func _clean(dir_path: String) -> void:
	for f in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_clean(dir_path.path_join(d))
	DirAccess.remove_absolute(dir_path)

func _flat(lat: float, lon: float, name: String) -> LocationData:
	var flat := LocationData.new()
	flat.grid_size = 8
	flat.heights.resize(64)
	for i in 64:
		flat.heights[i] = 3.0
	flat.place_name = name
	flat.latitude = lat
	flat.longitude = lon
	return flat

func _maths() -> void:
	var ground := GroundTruth.new(_flat(60.0, 25.0, "Flat"))
	# Detailed ground ahead: centre has the whole half-extent, the east
	# edge has none left eastward and plenty westward.
	_check(absf(WorldStreamer.detailed_ahead(Vector2.ZERO, Vector2(1, 0))
		- WorldStreamer.HALF_EXTENT_M) < 0.01, "centre looks at a full half-extent ahead")
	_check(WorldStreamer.detailed_ahead(Vector2(1190, 0), Vector2(1, 0)) < 11.0,
		"near the east edge little detailed ground remains ahead")
	_check(WorldStreamer.detailed_ahead(Vector2(1190, 0), Vector2(-1, 0)) > 2000.0,
		"looking back across the world there is plenty")

	# Trigger: still at spawn, firing when predicted to cross, and the
	# step lands STEP_M ahead in the direction of travel.
	_check(not WorldStreamer.needs_recentre(Vector2.ZERO, Vector2.ZERO, Vector2(0, -1)),
		"standing at the centre needs no recentre")
	_check(WorldStreamer.needs_recentre(Vector2(0, -500), Vector2.ZERO, Vector2(0, -1)),
		"past the trigger radius needs a recentre")
	_check(WorldStreamer.needs_recentre(Vector2.ZERO, Vector2(0, -45), Vector2(0, -1)),
		"a boosted drone at the centre already needs the area ahead")
	var step := WorldStreamer.step_target(Vector2(0, -500), Vector2(0, -45), Vector2(0, -1))
	_check(absf(step.distance_to(Vector2(0, -500 + -WorldStreamer.STEP_M))) < 1.0
		or step.y < -1000.0, "the new centre steps ahead of travel: %s" % step)

	# Adaptive trigger: a cruising drone at the centre starts at once
	# when a build takes 40 s (43 s to the edge < 56 s of lead), not
	# when it takes 10 s; a walker waits for the trigger radius.
	var cruise := Vector2(0, -ViewDrone.CRUISE_MPS)
	_check(WorldStreamer.needs_recentre(Vector2.ZERO, cruise, Vector2(0, -1), 40.0),
		"a slow build starts a cruising drone's next centre early")
	_check(not WorldStreamer.needs_recentre(Vector2.ZERO, cruise, Vector2(0, -1), 10.0),
		"a quick build lets the cruising drone go on")
	_check(not WorldStreamer.needs_recentre(Vector2(0, -300), Vector2(0, -4), Vector2(0, -1), 60.0),
		"a walker inside the trigger radius waits")
	_check(WorldStreamer.needs_recentre(Vector2(0, -500), Vector2(0, -4), Vector2(0, -1), 60.0),
		"the trigger radius still starts a walker's next centre")
	_check(not WorldStreamer.needs_recentre(Vector2.ZERO, Vector2.ZERO, Vector2(0, -1), 60.0),
		"standing still never starts one, however slow builds are")
	# Step: about one build's travel ahead, within bounds that keep the
	# squares overlapping along travel.
	_check(WorldStreamer.step_m(4.0, 30.0) == WorldStreamer.STEP_M, "a walker steps STEP_M")
	_check(absf(WorldStreamer.step_m(27.8, 40.0) - 1112.0) < 0.5, "a drone steps a build's travel")
	_check(WorldStreamer.step_m(83.0, 60.0) == WorldStreamer.MAX_STEP_M, "a boost steps the most")
	var far := WorldStreamer.step_target(Vector2(0, -WorldStreamer.TRIGGER_M), Vector2(0, -83),
		Vector2(0, -1), 60.0)
	var both := Vector2(0, -WorldStreamer.HALF_EXTENT_M + 1.0)
	_check(WorldStreamer.inside_detailed(both) and WorldStreamer.inside_detailed(both - far),
		"squares a longest step apart still overlap: %s" % far)
	_check(WorldStreamer.step_target(Vector2.ZERO, cruise, Vector2(0, -1)).distance_to(
		Vector2(0, -WorldStreamer.STEP_M)) < 0.5, "no expected time keeps the old STEP_M")
	# A centre planned ahead is built only while it still lies ahead, far
	# enough to be worth it and near enough for the squares to overlap.
	_check(WorldStreamer.use_plan(Vector2(0, -1500), Vector2(0, -200), Vector2(0, -1)),
		"a plan straight ahead is used")
	_check(WorldStreamer.use_plan(Vector2(400, -1500), Vector2(0, -200), Vector2(0, -1)),
		"a plan a little off the heading is used")
	_check(not WorldStreamer.use_plan(Vector2(1300, -600), Vector2(0, -200), Vector2(0, -1)),
		"a plan the camera turned away from is not")
	_check(not WorldStreamer.use_plan(Vector2(0, -400), Vector2(0, -200), Vector2(0, -1)),
		"a plan already underfoot is not")
	_check(not WorldStreamer.use_plan(Vector2(0, -2500), Vector2(0, -200), Vector2(0, -1)),
		"a plan too far for the squares to overlap is not")
	# Build time: defaults per preset, raised fast by a slow build and
	# lowered gently by a quick one.
	WorldStreamer._build_s.clear()
	_check(WorldStreamer.expected_build_s(RenderSettings.Preset.HIGH)
		== WorldStreamer.DEFAULT_BUILD_S[RenderSettings.Preset.HIGH], "unmeasured uses the default")
	var up := WorldStreamer.blend_build_s(30.0, 50.0) - 30.0
	var down := 30.0 - WorldStreamer.blend_build_s(30.0, 10.0)
	_check(up > down * 2.0, "slow builds count more than quick ones (%.1f vs %.1f)" % [up, down])
	WorldStreamer.note_build_s(RenderSettings.Preset.HIGH, 60.0)
	_check(WorldStreamer.expected_build_s(RenderSettings.Preset.HIGH) > 45.0
		and WorldStreamer.expected_build_s(RenderSettings.Preset.FAST)
		== WorldStreamer.DEFAULT_BUILD_S[0], "a measured build sets only its own preset")
	WorldStreamer._build_s.clear()

	# Remap: the same lat/lon seen from a centre 900 m north.
	var lat0 := 60.0
	var lon0 := 25.0
	var north := WorldScale.latlon_from_xz(0.0, -900.0, lat0, lon0)
	var moved := WorldStreamer.remap_xz(Vector2(10, -100), lat0, lon0, north.x, north.y)
	_check(moved.distance_to(Vector2(10, 800)) < 2.0,
		"remap keeps the point, shifts the frame: %s" % moved)
	var back := WorldStreamer.remap_xz(moved, north.x, north.y, lat0, lon0)
	_check(back.distance_to(Vector2(10, -100)) < 1.0, "remap round-trips within a metre: %s" % back)

	# No hidden wall: far past the old circles is enterable, the interim
	# cap only bites past the detailed edge, and backtracking is free.
	_check(WorldStreamer.enterable(Vector2(0, -5000), ground),
		"5 km out is enterable while streaming (no IN_PLACE_M wall)")
	_check(not WorldStreamer.enterable(Vector2(0, -5000), null), "no ground, no entry")
	_check(not WorldStreamer.enterable(Vector2(0, -WorldStreamer.STREAM_LIMIT_M - 1.0), ground),
		"the stream limit is the only outer bound")
	_check(is_inf(WorldStreamer.interim_cap_mps(Vector2(0, -100), Vector2(0, -1))),
		"inside the detailed ground there is no speed cap")
	_check(WorldStreamer.interim_cap_mps(Vector2(0, -2000), Vector2(0, -1))
		== WorldStreamer.INTERIM_MPS, "past the detailed edge the interim cap applies")
	_check(is_inf(WorldStreamer.interim_cap_mps(Vector2(0, -2000), Vector2(0, 1))),
		"flying back toward the centre is never capped")
	_check(is_inf(WorldStreamer.interim_cap_mps(Vector2(0, -2000), Vector2(1, 0))),
		"flying along the edge is never capped either")

func _state_machine() -> void:
	var s := WorldStreamer.new()
	_check(s.state == WorldStreamer.State.IDLE, "starts idle")
	s.arm(60.0, 25.0, 1, 2)
	var gen := s.begin(Vector2(60.01, 25.0), Vector2(0, -900))
	_check(s.state == WorldStreamer.State.FETCHING and gen == s.generation, "begin fetches")
	_check(not s.mark_ready(gen + 1), "a stale generation cannot become ready")
	_check(s.mark_ready(gen) and s.state == WorldStreamer.State.READY, "the live generation is ready")
	var gen2 := s.invalidate("season changed")
	_check(gen2 > gen and s.state == WorldStreamer.State.IDLE, "invalidate drops the pending world")
	_check(not s.mark_ready(gen), "the invalidated generation stays dropped")
	var gen3 := s.begin(Vector2(60.01, 25.0), Vector2(0, -900))
	s.mark_failed(gen3, "offline")
	_check(s.state == WorldStreamer.State.DEGRADED and s.should_retry(),
		"a failed fetch degrades and may retry")
	var gen4 := s.begin(Vector2(60.01, 25.0), Vector2(0, -900))
	_check(s.mark_ready(gen4), "a retry can become ready")
	# Turned after the trigger: the pending centre lies west, the camera
	# left the live square northward while still nearer the old centre.
	var west := Vector2(-1200, 0)
	var north_edge := Vector2(-300, -1250)
	var gen5 := s.begin(Vector2(60.0, 24.98), west)
	_check(not s.pending_misses(north_edge), "a ready-world drop never cancels a build in flight")
	_check(s.should_redirect(north_edge), "a build the camera turned away from is redirected")
	_check(not s.should_redirect(Vector2(-300, -1100)), "inside the live square no redirect")
	_check(not s.should_redirect(Vector2(-1250, -400)), "over the pending square no redirect")
	s.redirected = true
	_check(not s.should_redirect(north_edge), "only one redirect per finished build")
	var gen_fail := s.begin(Vector2(60.0, 24.98), west)
	s.mark_failed(gen_fail, "offline")
	_check(not s.redirected, "a failed build allows the retry to be redirected")
	gen5 = s.begin(Vector2(60.0, 24.98), west)
	_check(s.mark_ready(gen5), "a westward world is ready")
	_check(not s.redirected, "a finished build allows the next redirect")
	_check(not s.should_redirect(north_edge), "a ready world is dropped, not redirected")
	_check(not s.swap_wanted(north_edge), "it never covers the northward camera")
	_check(s.swap_stale(north_edge),
		"a ready world the camera turned away from is dropped, not held forever")
	var over_west := Vector2(-1250, -400)
	_check(s.swap_wanted(over_west) and not s.pending_misses(over_west),
		"past the edge over the pending square it still swaps in")
	_check(not s.pending_misses(Vector2(-300, -1100)), "inside the live square nothing is dropped")
	# An early (adaptive) build ready while the camera is near the centre.
	var ahead := Vector2(0, -1600)
	var gen6 := s.begin(Vector2(60.015, 25.0), ahead)
	_check(s.mark_ready(gen6), "a far-ahead world is ready")
	_check(not s.swap_stale(Vector2(0, -50), Vector2(0, -27)),
		"heading for an early-ready world keeps it")
	_check(not s.swap_stale(Vector2(0, -50)), "standing still keeps it too")
	_check(s.swap_stale(Vector2(0, -50), Vector2(0, 27)), "turning back from it drops it")
	# Sideways: past the live edge over the pending square, though still
	# nearer the old centre than the new one.
	var side := Vector2(-200, -1100)
	var gen7 := s.begin(Vector2(60.01, 24.996), side)
	_check(s.mark_ready(gen7), "a sideways world is ready")
	var edge := Vector2(-1210, 0)
	_check(edge.distance_to(side) > edge.length() and s.swap_wanted(edge),
		"past the edge over the pending square it swaps even when nearer the old centre")
	# A camera still easing back from the interim cap plans at its recent
	# peak pace, so the next step is not sized for the cap.
	s._vel = Vector2(0, -20)
	s._pace = 80.0
	_check(absf(s._planned_vel().length() - 80.0) < 0.01 and s._planned_vel().y < 0.0,
		"steps are planned at the recent peak pace, along the way of travel")
	s.reset_for_new_place()
	_check(s._pace == 0.0 and not s._warmed, "a new place forgets the pace and warms up again")
	_check(s.state == WorldStreamer.State.IDLE and s.generation > gen4,
		"a new place drops a ready world and bumps the generation")

## WorldHandoff: a world staged hidden comes back a subtree per pump,
## keeps its children's order and owners, and a dropped one leaves.
func _handoff() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var world := Node3D.new()
	for i in 4:
		var c := Node3D.new()
		c.name = "Part%d" % i
		world.add_child(c)
		c.owner = world
	var h := WorldHandoff.new()
	h.stage(holder, world)
	_check(world.get_parent() == holder and not world.visible and world.get_child_count() == 0,
		"staging parents the world hidden and takes its subtrees off")
	_check(not h.ready_for(world), "a world with subtrees still off is not staged yet")
	h.pump(0)
	_check(world.get_child_count() == 1, "a spent budget still adds one subtree a pump")
	while h.busy():
		h.pump()
	_check(h.ready_for(world) and world.get_child(3).name == "Part3"
		and world.get_child(3).owner == world, "every subtree is back, in order, owned")
	h.drop_staged()
	_check(h.staged == null and not world.visible and h.busy(), "a dropped world leaves")
	while h.busy():
		h.pump()
	_check(not is_instance_valid(world), "the dropped world is freed")
	# A big subtree comes back child by child, in order, under its parent.
	var big_world := Node3D.new()
	var layer := Node3D.new()
	layer.name = "Buildings"
	big_world.add_child(layer)
	for i in WorldHandoff.SPLIT_CHILDREN + 8:
		var cell := Node3D.new()
		cell.name = "Cell%d" % i
		layer.add_child(cell)
	var h2 := WorldHandoff.new()
	h2.stage(holder, big_world)
	h2.pump(0)
	_check(layer.get_parent() == big_world and layer.get_child_count() == 0,
		"a big subtree's parent comes back first, its children after")
	while h2.busy():
		h2.pump(0)
	_check(h2.ready_for(big_world) and layer.get_child_count() == WorldHandoff.SPLIT_CHILDREN + 8
		and layer.get_child(5).name == "Cell5", "every child is back under it, in order")
	holder.free()

## RevealWave: only new pieces (past the old square) fade in, from the
## camera outward, and each gets its LodRing range back once passed.
func _reveal() -> void:
	var world := Node3D.new()
	var group := Node3D.new()
	group.name = "Buildings"
	world.add_child(group)
	var near := MeshInstance3D.new()
	near.mesh = BoxMesh.new()
	near.position = Vector3(0, 0, -100)
	group.add_child(near)
	var fresh := MeshInstance3D.new()
	fresh.mesh = BoxMesh.new()
	fresh.position = Vector3(0, 0, -1500)
	group.add_child(fresh)
	var w := RevealWave.new()
	w.prepare(world, Vector2.ZERO)
	w.pump()
	_check(w.prepared(world), "a small world is walked in one pump")
	w.start(world, Vector2(0, -500), RenderSettings.Preset.HIGH)
	_check(w.active() and fresh.visibility_range_end > 0.0
		and fresh.visibility_range_end < 1000.0 + 1.0, "a new piece waits for the wave: %.0f"
			% fresh.visibility_range_end)
	_check(near.visibility_range_end == 0.0, "ground the old world had shows at once")
	w.tick(Vector2(0, -500), 0.1, RenderSettings.Preset.HIGH)
	_check(w.active(), "the wave takes time to pass")
	w.tick(Vector2(0, -500), 5.0, RenderSettings.Preset.HIGH)
	_check(not w.active() and fresh.visibility_range_end == 0.0,
		"once passed, a piece has its own range back")
	world.free()

## The way-ahead badge: hidden for a quick (cached) stretch, then the
## data stage still on its way, the build step, a steady never-100 %
## percent, a brief "ready" and gone.
func _badge() -> void:
	var s := WorldStreamer.new()
	s.enabled = true
	var b := StreamBadge.new()
	root.add_child(b)
	s.arm(60.0, 25.0, 1, 2)
	var gen := s.begin(Vector2(60.01, 25.0), Vector2(0, -900))
	var p := SaveProgress.new()
	p.rows = GenerationPipeline.STAGES.size()
	s.progress = p
	s.stages_done.resize(p.rows)
	s.stages_done.fill(false)
	for i in 4:
		b.follow(s, 1.0)
	_check(not b.visible, "a build with time to spare before the edge stays quiet")
	s._edge_s = 0.0  # the camera is at the edge: the badge is wanted
	_check(not b.follow(s, 0.2) and not b.visible, "the badge waits before showing")
	s.mark_ready(gen)
	b.follow(s, 0.2)
	_check(not b.visible, "a stretch ready within the delay never shows")
	gen = s.begin(Vector2(60.01, 25.0), Vector2(0, -900))
	p = SaveProgress.new()
	p.rows = GenerationPipeline.STAGES.size()
	s.progress = p
	s.stages_done.fill(false)
	s.stages_done[0] = true
	p.rows_done = 1
	b.follow(s, 0.5)
	_check(b.follow(s, 0.5) and b.visible, "a slow stretch shows the badge")
	_check(b._detail.text == "Imagery", "the first stage still on its way is named")
	for i in 120:
		b.follow(s, 0.25)
	p.phase = SaveProgress.Phase.BUILD
	p.rows_done = p.rows
	for i in 40:
		b.follow(s, 0.25)
	_check(b._detail.text.begins_with("Building the scene · "), "the build step shows")
	var pct := int(b._percent.text.trim_suffix("%"))
	_check(pct >= 30 and pct < 100, "the percent moves on but never reaches 100 mid-build")
	s.mark_ready(gen)
	b.follow(s, 0.1)
	_check(b.visible and b._title.text == "Way ahead ready", "a landed stretch says so")
	for i in 20:
		b.follow(s, 0.1)
	await create_timer(0.4).timeout
	_check(not b.visible, "the ready badge leaves on its own")
	b.free()

func _movement_and_swap() -> void:
	var view := View360.new()
	root.add_child(view)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280, 800)
	await process_frame
	view._wiki.offline_mode = true
	if view._horizon != null and view._horizon._fetcher != null:
		view._horizon._fetcher.offline_mode = true
	view._weather.queue_free()
	view._weather = null
	var data := _flat(60.4518, 22.2666, "Testville")
	view.show_location(data)
	await process_frame
	# Streaming on (movement only; tests never auto-start a pipeline).
	view._streamer.arm(data.latitude, data.longitude, data.season, data.quality_preset)
	view._streamer.enabled = true

	# Walk north past the old 600 m walking circle in one held-key run.
	view._rig.position = Vector3(0, ViewWalk.foot_y(data, view._ground, Vector2(0, -590)), -590)
	view._rig.set_look(0.0, 0.0)
	var north_key := InputEventKey.new()
	north_key.keycode = KEY_W
	north_key.pressed = true
	Input.parse_input_event(north_key)
	Input.flush_buffered_events()
	for i in 40:
		view._walk.process_keys(view, 0.25)
	var release_north := InputEventKey.new()
	release_north.keycode = KEY_W
	Input.parse_input_event(release_north)
	Input.flush_buffered_events()
	var walked := Vector2(view._rig.position.x, view._rig.position.z)
	_check(walked.length() > View360.IN_PLACE_M + 20.0,
		"walking crosses the old walking circle: %s" % walked.length())

	# A glide well past the old circle but inside the detailed square is
	# allowed; 5 km remains a Go-there trip, not a tap.
	_check(view._walk.walk_to(view, Vector2(0, -900)), "a tap past 600 m glides while streaming")
	if view._visit_tween != null:
		view._visit_tween.kill()
	_check(not view._walk.walk_to(view, Vector2(0, -5000)), "5 km is still not a tap-walk")

	# Fly: the drone crosses the old 1100 m roam edge.
	view._drone.enter(view)
	view._rig.position = Vector3(0, view._ground.height_at_world(0, -1000) + 30.0, -1000)
	view._rig.set_look(0.0, 0.0)
	view._drone.stick_move = Vector2(0, -1)
	for i in 700:
		view._drone.process(view, 1.0 / 30.0)
	view._drone.stick_move = Vector2.ZERO
	var flown := Vector2(view._rig.position.x, view._rig.position.z)
	_check(flown.length() > ViewDrone.EDGE_M + 20.0,
		"flying crosses the old roam edge: %s" % flown.length())
	view._drone.exit(view, false)

	# Swap: a new centre 900 m north keeps the camera over the same place.
	var before_ll := WorldScale.latlon_from_xz(flown.x, flown.y, data.latitude, data.longitude)
	var north := WorldScale.latlon_from_xz(0.0, -900.0, data.latitude, data.longitude)
	var data2 := _flat(north.x, north.y, "Testville North")
	var ground2 := GroundTruth.new(data2)
	var world2 := View360.make_world(data2, ground2)
	var agl_before := view._rig.position.y - view._ground.height_at_world(flown.x, flown.y)
	view.apply_streamed_world(data2, [ground2, world2])
	var after_xz := Vector2(view._rig.position.x, view._rig.position.z)
	var after_ll := WorldScale.latlon_from_xz(after_xz.x, after_xz.y, data2.latitude, data2.longitude)
	_check(after_ll.distance_to(before_ll) < 0.0001,
		"the swap keeps the camera over the same lat/lon: %s vs %s" % [after_ll, before_ll])
	_check(view._data == data2 and view._ground == ground2, "the swap installs the new centre")
	var agl_after := view._rig.position.y - view._ground.height_at_world(after_xz.x, after_xz.y)
	# On foot (the drone landed above) the swap restores the walking eye;
	# in flight it would keep the drone's height over ground instead.
	_check(absf(agl_after - ViewWalk.EYE_M) < 1.5,
		"the swap restores the walking eye on foot: %.1f (was %.1f in flight)" % [agl_after, agl_before])
	_check(view._streamer.centre_lat == data2.latitude, "the streamer re-arms on the new centre")

	# Re-applying the same built world must not free the live one.
	var live := view._generated
	view.apply_streamed_world(data2, [ground2, world2])
	_check(view._generated == live and is_instance_valid(live),
		"re-applying the live world leaves it in the tree")

	# A stale ready generation must not swap a second time.
	var gen := view._streamer.generation
	view._streamer.invalidate("test")
	_check(view._streamer.generation > gen and view._data == data2,
		"invalidate after the swap leaves the live world alone")

	# Live tick: a ready world the camera turned away from (west target,
	# camera past the north edge) is dropped, not held forever. The tick
	# that drops it returns before starting a pipeline.
	var s := view._streamer
	s.arm(data2.latitude, data2.longitude, data2.season, view._quality_preset)
	var gen_turned := s.begin(Vector2(data2.latitude, data2.longitude - 0.02), Vector2(-1200, 0))
	s.mark_ready(gen_turned)
	var keep_pos := view._rig.position
	view._rig.position = Vector3(-300, keep_pos.y, -1250)
	s.note_spawn(Vector2(-300, -1250))
	s.tick(view, 1.0 / 30.0)
	_check(s.state == WorldStreamer.State.IDLE and s.generation > gen_turned and view._data == data2,
		"tick drops a ready world the camera turned away from")
	view._rig.position = keep_pos
	s.note_spawn(after_xz)
	await _swap_continuity(view, data2, after_xz)
	view.queue_free()
	await process_frame

func _first_geo(node: Node) -> GeometryInstance3D:
	if node is GeometryInstance3D:
		return node as GeometryInstance3D
	for c in node.get_children():
		var hit := _first_geo(c)
		if hit != null:
			return hit
	return null

## Swap continuity: drone momentum, streamer velocity and pre-ranged LOD
## survive a centre swap; walking never steps backward across one.
func _swap_continuity(view: View360, data2: LocationData, at: Vector2) -> void:
	# Drone at cruise, then swap to a centre ahead of it (as the
	# streamer would pick): the camera lands inside the new detailed
	# ground, not past its edge.
	view._drone.enter(view)
	view._rig.position = Vector3(at.x,
		view._ground.height_at_world(at.x, at.y) + 30.0, at.y)
	view._rig.set_look(0.0, 0.0)
	view._drone.stick_move = Vector2(0, -1)
	for i in 120:
		view._drone.process(view, 1.0 / 30.0)
	var vel_before: Vector2 = view._drone._vel
	_check(vel_before.length() > 20.0,
		"drone reaches cruise before the continuity swap: %.1f" % vel_before.length())
	view._streamer._vel = Vector2(0, -20)
	var ahead := WorldScale.latlon_from_xz(0.0, -900.0, data2.latitude, data2.longitude)
	var data3 := _flat(ahead.x, ahead.y, "Testville Far North")
	var ground3 := GroundTruth.new(data3)
	var world3 := View360.make_world(data3, ground3)
	# Range the waiting world in slices, as tick does, and prove a
	# sentinel range then survives the swap (no re-range on its frame).
	view._streamer.begin_ranging(world3, view._quality_preset)
	_check(not view._streamer._ready_ranged, "ranging starts unfinished")
	view._streamer._pump_ranging(0)
	_check(view._streamer._range_cursor == 1, "a spent budget still ranges one subtree a tick")
	while not view._streamer._ready_ranged:
		view._streamer._pump_ranging()
	_check(view._streamer._ranged_world == world3, "the ranged world is the named one")
	var geo := _first_geo(world3)
	_check(geo != null, "the built world has geometry to range")
	if geo != null:
		geo.visibility_range_end = 12345.0
	var here := Vector2(view._rig.position.x, view._rig.position.z)
	var agl_before := view._rig.position.y - view._ground.height_at_world(here.x, here.y)
	var old_world := view._generated
	view.apply_streamed_world(data3, [ground3, world3])
	_check(view._generated == world3 and world3.visible and world3.is_inside_tree(),
		"the swap shows the new world in the scene")
	_check(is_instance_valid(old_world) and not old_world.visible,
		"the old world hides at the swap and leaves over the next frames")
	var pumps := 0
	while view._streamer._handoff.busy() and pumps < 10000:
		view._streamer._handoff.pump(0)
		pumps += 1
	_check(not is_instance_valid(old_world) and pumps > 1,
		"the old world is freed a subtree at a time (%d pumps)" % pumps)
	_check(view._drone._vel.length() >= vel_before.length() * 0.9,
		"the swap keeps drone momentum: %.1f -> %.1f"
			% [vel_before.length(), view._drone._vel.length()])
	_check(not view._drone._resync, "the swap leaves no resync pending in flight")
	var after := Vector2(view._rig.position.x, view._rig.position.z)
	var agl_after := view._rig.position.y - view._ground.height_at_world(after.x, after.y)
	_check(absf(agl_after - agl_before) < 1.5,
		"the swap keeps the drone's height over ground: %.1f -> %.1f" % [agl_before, agl_after])
	_check(absf(view._drone._agl - clampf(agl_before, ViewDrone.AGL_MIN_M, ViewDrone.AGL_MAX_M)) < 1.5,
		"the swap re-derives the drone's target height: %.1f" % view._drone._agl)
	_check(view._streamer._vel == Vector2(0, -20),
		"the swap keeps the streamer's velocity estimate: %s" % view._streamer._vel)
	_check(not view._streamer._ready_ranged, "the swap consumes the pre-ranged flag")
	if geo != null:
		_check(absf(geo.visibility_range_end - 12345.0) < 0.01,
			"a pre-ranged world is not re-ranged on the swap frame: %.1f"
				% geo.visibility_range_end)
	var frame_from := Vector2(view._rig.position.x, view._rig.position.z)
	view._drone.process(view, 1.0 / 30.0)
	var frame_to := Vector2(view._rig.position.x, view._rig.position.z)
	_check(frame_from.distance_to(frame_to) > vel_before.length() / 30.0 * 0.5,
		"the first post-swap drone frame advances at speed: %.2f m"
			% frame_from.distance_to(frame_to))
	view._drone.stick_move = Vector2.ZERO
	view._drone.exit(view, false)

	# Walk north through a swap to the previous centre (data2, south
	# of where the walker now stands): latitude never goes backward.
	view._rig.position = Vector3(0,
		ViewWalk.foot_y(view._data, view._ground, Vector2(0, -590)), -590)
	view._rig.set_look(0.0, 0.0)
	var north_key := InputEventKey.new()
	north_key.keycode = KEY_W
	north_key.pressed = true
	Input.parse_input_event(north_key)
	Input.flush_buffered_events()
	var prev_lat := -1.0
	var worst_step := 0.0
	for i in 80:
		if i == 40:
			var ground4 := GroundTruth.new(data2)
			var world4 := View360.make_world(data2, ground4)
			view.apply_streamed_world(data2, [ground4, world4])
		view._walk.process_keys(view, 1.0 / 30.0)
		var p := Vector2(view._rig.position.x, view._rig.position.z)
		var ll := WorldScale.latlon_from_xz(p.x, p.y,
			view._data.latitude, view._data.longitude)
		if prev_lat > -1.0:
			worst_step = minf(worst_step, ll.x - prev_lat)
		prev_lat = ll.x
	var release_north := InputEventKey.new()
	release_north.keycode = KEY_W
	Input.parse_input_event(release_north)
	Input.flush_buffered_events()
	_check(worst_step > -0.000001,
		"walking never steps backward across a swap (worst lat step %.7f)" % worst_step)
