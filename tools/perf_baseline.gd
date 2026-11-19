extends SceneTree

## Perf baseline (roadmap 1.0): the numbers every later speed change is
## measured against. Windowed (the dummy renderer draws nothing), off-screen,
## never on top, one preset per run so each run's data cache starts cold:
##   for p in 0 2 3; do tools/godot_bg.sh --path . --script tools/perf_baseline.gd \
##     --position 4000,4000 -- --preset=$p [--places=helsinki,paris,new_york,turku] \
##     [--fly_s=90] [--speed=40] [--tag=perf] [--memory_limit_mb=3300]; done
## --memory_limit_mb plans under a phone's limit (MemoryBudget.limit_override:
## its tier, preset ceiling and MemoryGuard levels); add --rendering-method
## mobile before `--` for the phones' renderer. Guard level changes and the
## peak share of the limit are recorded per place.
##
## Runs the real app flow (Main -> pipeline -> View360) in an isolated empty
## cache (user://perf-<pid>), and per place:
##   cold     open with nothing cached: fetch + build
##   save     the world cache save that follows (time, peak memory)
##   cached   reopen from the world cache
##   settle   5 s standing at the opening look: frame times, draw calls,
##            primitives, mesh nodes in the world, memory
##   build    reopen with the world cache removed (data cache warm)
##   fly      fly east at --speed m/s, 120 m up, for --fly_s seconds with
##            streaming on: frame times, plus the STREAM gen/swap lines the
##            streamer writes to the stream log meanwhile
## Writes visual-plan/reviews/<tag>-<date>/perf_p<preset>.json and prints
## one PERF line per place. In-process caches (prewarmed textures, shaders)
## stay warm between places and opens: the first place is the truest cold.

const PLACE_TIMEOUT_S := 600.0
const SAVE_TIMEOUT_S := 240.0
const SETTLE_S := 5.0
const FLY_UP_M := 120.0
const SLOW_MS := 33.4
const SPIKE_MS := 250.0
const MB := 1 << 20
const CONTROLS := [
	{"id": "turku", "name": "Turku, Finland", "lat": 60.4518, "lon": 22.2666},
]

var _out := ""
## --fly_only=1: from the first open straight to the flight (a release
## export overflows the reflection probe atlas when a place is reopened).
var _fly_only := false
## --heading=DEG: the flight's direction, 0 = east, 90 = south (XZ plane).
var _heading_deg := 0.0
var _peak := 0
var _levels: Array = []

func _init() -> void:
	_run.call_deferred()

func _args() -> Dictionary:
	var a := {"tag": "perf", "preset": "2", "places": "helsinki,paris,new_york,turku",
		"fly_s": "90", "speed": "40"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	return a

func _places(filter: String) -> Array:
	var all: Array = []
	for row in PresetViews.ROWS:
		all.append({"id": row["id"], "name": row["name"], "lat": row["lat"], "lon": row["lon"]})
	all.append_array(CONTROLS)
	var out: Array = []
	for id in filter.split(",", false):
		for p in all:
			if str(p["id"]) == id:
				out.append(p)
	return out

func _run() -> void:
	var a := _args()
	_fly_only = str(a.get("fly_only", "0")) == "1"
	_heading_deg = float(a.get("heading", "0"))
	var preset := int(a["preset"])
	var limit_mb := int(a.get("memory_limit_mb", "0"))
	if limit_mb > 0:
		MemoryBudget.limit_override = limit_mb * MemoryBudget.MB
	_out = ProjectSettings.globalize_path("res://").path_join("visual-plan/reviews/%s-%s" % [
		a["tag"], Time.get_date_string_from_system()])
	DirAccess.make_dir_recursive_absolute(_out)
	CacheStore.eviction_suppressed = true
	CacheStore.dir_override = "user://perf-%d" % OS.get_process_id()
	WorldCache.dir_override = CacheStore.dir_override.path_join("worlds")
	DirAccess.make_dir_recursive_absolute(CacheStore.base_dir())
	RenderSettings.path_override = "user://perf-settings-%d.json" % OS.get_process_id()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.capture_mode = true
	main._store.entries.clear()
	root.size = Vector2i(1280, 800)
	await create_timer(0.5).timeout
	root.size = Vector2i(1280, 800)
	for child in main.get_children():
		if child is OnboardingScreen:
			child.queue_free()
	UiPrefs.reduce_motion = true
	# In memory only, never saved; held to the simulated phone's ceiling.
	if limit_mb > 0:
		preset = MemoryBudget.cap_preset(preset)
	main._settings.preset = preset
	main._memory_guard.level_changed.connect(func(l: int) -> void:
		_levels.append([snappedf(Time.get_ticks_msec() / 1000.0, 0.1), MemoryGuard.NAMES[l]]))
	var view: View360 = main._view
	view._governor.set_process(false)  # the preset stays pinned
	var report := {"preset": preset, "date": Time.get_datetime_string_from_system(),
		"platform": OS.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"cache_dir": ProjectSettings.globalize_path(CacheStore.base_dir()), "places": {},
		"limit_mb": MemoryBudget.limit_bytes() / MemoryBudget.MB, "tier": MemoryBudget.tier()}
	for place in _places(str(a["places"])):
		var r := await _measure(main, view, place, float(a["fly_s"]), float(a["speed"]))
		report["places"][place["id"]] = r
		print("PERF p%d %s %s" % [preset, place["id"], JSON.stringify(_headline(r))])
		_write(preset, report)
	_write(preset, report)
	print("PERF DONE -> ", _out)
	quit(0)

func _write(preset: int, report: Dictionary) -> void:
	var f := FileAccess.open(_out.path_join("perf_p%d.json" % preset), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()

func _headline(r: Dictionary) -> Dictionary:
	var h := {}
	for k in ["cold_s", "save_s", "cached_s", "cached_hit", "build_s"]:
		if r.has(k):
			h[k] = r[k]
	if r.has("settle"):
		h["settle_p95_ms"] = r["settle"]["p95_ms"]
		h["meshes"] = r["settle"]["mesh_nodes"]
	if r.has("fly"):
		h["fly_p95_ms"] = r["fly"]["p95_ms"]
		h["fly_max_ms"] = r["fly"]["max_ms"]
		h["swaps"] = r["fly"]["swaps"].size()
		h["slowed_s"] = r["fly"]["slowed_s"]
		h["badge_s"] = r["fly"]["badge_s"]
	h["peak_mb"] = r.get("peak_mb", 0)
	h["peak_share"] = r.get("peak_share", 0)
	h["guard"] = (r.get("guard", []) as Array).map(func(e: Array) -> String: return str(e[1]))
	return h

func _measure(main: Node, view: View360, place: Dictionary, fly_s: float, speed: float) -> Dictionary:
	var r := {"name": place["name"]}
	var lat := float(place["lat"])
	var lon := float(place["lon"])
	_peak = 0
	_levels = []
	var cold := await _open(main, view, place)
	if cold < 0.0:
		r["error"] = "no view (cold)"
		return r
	r["cold_s"] = cold
	var save := await _await_save(view, lat, lon)
	r["save_s"] = save[0]
	r["save_peak_mb"] = save[1]
	r["cold_key"] = WorldCache.key(view._data) if view._data != null else ""
	if _fly_only:
		if fly_s > 0.0:
			r["fly"] = await _fly(view, fly_s, speed)
		r["peak_mb"] = _peak / MB
		return r
	var saved := Array(DirAccess.get_files_at(WorldCache.base_dir()))
	var cached := await _open(main, view, place)
	if cached >= 0.0:
		r["cached_s"] = cached
		# A changed fingerprint rebuilds instead of loading: say so, so a
		# slow "cached" open is never mistaken for a slow cache load.
		r["cached_key"] = WorldCache.key(view._data)
		r["cached_hit"] = saved.has(str(r["cached_key"]) + ".scn")
		r["settle"] = await _settle(view)
	WorldCache.remove_for_place(lat, lon)
	var built := await _open(main, view, place)
	if built >= 0.0:
		r["build_s"] = built
		await _await_save(view, lat, lon)
		if fly_s > 0.0:
			r["fly"] = await _fly(view, fly_s, speed)
	r["peak_mb"] = _peak / MB
	r["peak_share"] = snappedf(float(_peak) / float(MemoryBudget.limit_bytes()), 0.01)
	r["guard"] = _levels.duplicate()
	return r

## Seconds from asking for the place to its world on screen, -1 on timeout.
func _open(main: Node, view: View360, place: Dictionary) -> float:
	view._streamer.enabled = false
	main._picker.selected_name = str(place["name"])
	var start := Time.get_ticks_usec()
	main._start_generation(float(place["lat"]), float(place["lon"]))
	while (main._generating or not view.visible) \
			and Time.get_ticks_usec() - start < int(PLACE_TIMEOUT_S * 1e6):
		await process_frame
		_note_mem()
	if main._generating or not view.visible:
		printerr("PERF SKIP %s: no view" % place["id"])
		return -1.0
	main._notice.visible = false
	return snappedf((Time.get_ticks_usec() - start) / 1e6, 0.01)

## [seconds until the world is saved (-1 on timeout), peak MB meanwhile].
func _await_save(view: View360, lat: float, lon: float) -> Array:
	var start := Time.get_ticks_usec()
	var peak := 0
	while Time.get_ticks_usec() - start < int(SAVE_TIMEOUT_S * 1e6):
		await process_frame
		peak = maxi(peak, MemoryLog.footprint())
		_note_mem()
		if view._data != null and WorldCache.has_world(view._data) \
				and not WorldCache.is_place_busy(lat, lon):
			return [snappedf((Time.get_ticks_usec() - start) / 1e6, 0.01), peak / MB]
	return [-1.0, peak / MB]

func _settle(view: View360) -> Dictionary:
	var times := await _frames(SETTLE_S, Callable())
	var s := _stats(times)
	var fs := LodRing.frame_stats()
	s["draw_calls"] = fs["draw_calls"]
	s["primitives"] = fs["primitives"]
	s["objects"] = fs["objects"]
	s["mesh_nodes"] = _count_meshes(view._world_root)
	s["memory_mb"] = MemoryLog.footprint() / MB
	s["video_mb"] = int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / MB
	return s

func _fly(view: View360, seconds: float, speed: float) -> Dictionary:
	var log_path := StreamLog.LOG_PATH
	var log_from := _file_len(log_path)
	view._streamer.enabled = true
	var rig := view._rig
	var dir := Vector2(cos(deg_to_rad(_heading_deg)), sin(deg_to_rad(_heading_deg)))
	rig.yaw = atan2(-dir.x, -dir.y)  # look the way it flies (east: -PI/2)
	rig.pitch = -0.15
	# Seconds the person waited: held at the edge by the interim speed cap
	# (`slowed`), and with the "Preparing the way ahead" badge up (a build
	# in flight that the edge is closer to than its time left).
	var waited := {"slowed_s": 0.0, "badge_s": 0.0}
	var streamer := view._streamer
	var step := func(dt: float) -> void:
		var here := Vector2(rig.position.x, rig.position.z)
		var vel := WorldStreamer.capped_velocity(dir * speed, here)
		if streamer.slowed:
			waited["slowed_s"] += dt
		if streamer.state == WorldStreamer.State.FETCHING and streamer.urgent():
			waited["badge_s"] += dt
		var next := view.stream_roam(here, here + vel * dt)
		var ground := view._ground.height_at_world(next.x, next.y) if view._ground != null else 0.0
		rig.position = Vector3(next.x, ground + FLY_UP_M, next.y)
	var times := await _frames(seconds, step)
	view._streamer.enabled = false
	var s := _stats(times)
	s["slowed_s"] = snappedf(waited["slowed_s"], 0.1)
	s["badge_s"] = snappedf(waited["badge_s"], 0.1)
	var lines := _read_from(log_path, log_from)
	s["gens"] = lines.filter(func(l: String) -> bool: return l.contains("STREAM gen") and l.contains("total"))
	s["swaps"] = lines.filter(func(l: String) -> bool: return l.contains("STREAM swap:"))
	s["mem"] = lines.filter(func(l: String) -> bool: return l.contains(" MEM "))
	return s

## Frame times (ms) over `seconds`, calling `each` with every frame's delta.
func _frames(seconds: float, each: Callable) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	var begin := Time.get_ticks_usec()
	var end := begin + int(seconds * 1e6)
	var last := begin
	while Time.get_ticks_usec() < end:
		await process_frame
		var now := Time.get_ticks_usec()
		var dt := (now - last) / 1e6
		last = now
		times.append(dt * 1000.0)
		if dt * 1000.0 >= SPIKE_MS:
			# Inline with the app's own output, to see what ran just before.
			# Script time vs the rest (render, GPU sync) of the slow frame.
			print("PERF SPIKE %.0f ms at %.1f s (process %.0f ms, physics %.0f ms, objects %d)" % [
				dt * 1000.0, (now - begin) / 1e6,
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				int(Performance.get_monitor(Performance.OBJECT_COUNT))])
		if each.is_valid():
			each.call(dt)
		_note_mem()
	return times

static func _stats(times: PackedFloat32Array) -> Dictionary:
	if times.is_empty():
		return {"frames": 0}
	var sorted := times.duplicate()
	sorted.sort()
	var slow := 0
	for t in times:
		if t > SLOW_MS:
			slow += 1
	var at := func(q: float) -> float:
		return snappedf(sorted[clampi(int(q * (sorted.size() - 1)), 0, sorted.size() - 1)], 0.1)
	return {"frames": times.size(), "p50_ms": at.call(0.5), "p95_ms": at.call(0.95),
		"p99_ms": at.call(0.99), "max_ms": snappedf(sorted[-1], 0.1), "over_33ms": slow}

static func _count_meshes(n: Node) -> int:
	if n == null:
		return 0
	var c := 1 if n is MeshInstance3D or n is MultiMeshInstance3D else 0
	for child in n.get_children():
		c += _count_meshes(child)
	return c

func _note_mem() -> void:
	_peak = maxi(_peak, MemoryLog.footprint())

static func _file_len(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_length() if f != null else 0

static func _read_from(path: String, offset: int) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	f.seek(offset)
	var text := f.get_buffer(f.get_length() - offset).get_string_from_utf8()
	return Array(text.split("\n", false))
