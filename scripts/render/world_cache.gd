class_name WorldCache
extends RefCounted

## Built-world cache (T7.5): a cached revisit loads the finished world and
## its GroundTruth instead of rebuilding them (Paris High: ~31 s of build
## → ~1.5 s threaded load on the capture machine). The first visit pays a
## background save after the view opens. Worlds live apart from the data
## cache (user://worlds, oldest-first eviction) but share the settings size
## limit: they keep at most half of it, so a ~200 MB world can never push
## out every DEM/OSM/satellite tile.
##
## Key: place (quantized lat/lon) + preset + season + a fingerprint of the
## LocationData the world was built from + BUILD_VERSION. Bump
## BUILD_VERSION whenever a generation builder changes its output; debug
## builds also hash the generator sources, so a stale world can never be
## shown while developing. Headless runs (dummy renderer, no mesh data to
## save) bypass the cache entirely.

const BUILD_VERSION := 223
const DIR := "user://worlds"
## Sources whose output a cached world freezes (debug-build fingerprint).
const SOURCE_DIRS := ["res://scripts/generation", "res://scripts/render", "res://scripts/data"]

static var _source_hash := ""
static var _bytes := -1  # -1 = unknown, rescan on next total_bytes()
## Only one worker may write a given scene and its ground file at a time.
static var _save_threads: Dictionary = {}
## Test hook: keep cache eviction checks away from the person's worlds.
static var dir_override := ""

static func base_dir() -> String:
	return dir_override if not dir_override.is_empty() else DIR

static func enabled() -> bool:
	return DisplayServer.get_name() != "headless" and OS.get_environment("PR360_DISABLE_WORLD_CACHE") != "1"

static func key(data: LocationData) -> String:
	var fp := [BUILD_VERSION, data.quality_preset, data.season, data.grid_size,
		data.heights.size(), data.buildings.size(), data.roads.size(),
		data.land_polygons.size(), data.waterways.size(), data.trees.size(),
		data.landmark_type, data.has_landmark_site, data.landmark_lat, data.landmark_lon,
		data.seed_value, data.country, str(data.dem_source), str(data.satellite_source),
		data.focus.is_empty(), _view_eye(data),
		hash(var_to_bytes(data.landmark_candidates)),
		hash(var_to_bytes([data.shore_structures, data.land_polygons, data.waterways, data.buildings, data.roads])),
		hash(var_to_bytes([data.trees, data.barriers, data.railways, data.street_furniture, data.piers, data.pois])),
		hash(var_to_bytes(data.far_landuse)), hash(var_to_bytes(data.far_towers)),
		FarCityFetcher.QUERY_VERSION, str(data.climate),
		CacheStore.LANDCOVER_VERSION, LandcoverSource.WORLDCOVER_BASE, LandcoverSource.CANOPY_BASE,
		_image_fingerprint(data.landcover_image), _image_fingerprint(data.canopy_image),
		data.far_heights.size(), data.dem_rings.size(), data.far_drapes.size(), _sources()]
	return "world_%d_%d_p%d_s%d_%08x" % [CacheStore.quant(data.latitude),
		CacheStore.quant(data.longitude), data.quality_preset, data.season,
		hash(str(fp)) & 0xffffffff]

## Some world layers (cars, boats, wires and ground cover) are centred on
## the opening eye. Bearing and pitch do not change their placement.
static func _view_eye(data: LocationData) -> int:
	if data.view.is_empty():
		return 0
	return hash(var_to_bytes([float(data.view.get("eye_lat", data.view.get("lat", data.latitude))),
		float(data.view.get("eye_lon", data.view.get("lon", data.longitude)))]))

static func _image_fingerprint(img: Image) -> int:
	return hash(var_to_bytes([img.get_width(), img.get_height(), img.get_format(), img.get_data()])) \
		if img != null and not img.is_empty() else 0

static func _sources() -> String:
	if not OS.is_debug_build():
		return ""
	if _source_hash == "":
		var acc := ""
		for d in SOURCE_DIRS:
			for f in _source_files(d):
				acc += f + ":" + str(hash(FileAccess.get_file_as_string(f)))
		_source_hash = str(hash(acc))
	return _source_hash

static func _source_files(dir: String) -> Array[String]:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			files.append(dir.path_join(file))
	for child in DirAccess.get_directories_at(dir):
		files.append_array(_source_files(dir.path_join(child)))
	files.sort()
	return files

## Scene path a threaded load was started for ahead of time ("" none).
static var _prefetched := ""

## Starts loading the newest cached world for this place, preset and
## season while the pipeline still reads its data: the full key needs
## the finished LocationData, but its prefix is known up front. When
## load_world later asks for the same file it is already loading (or
## loaded); a different key just drops it. True when a world was found.
static func prefetch(lat: float, lon: float, preset: int, season: int) -> bool:
	var dir := base_dir()
	if not enabled() or not DirAccess.dir_exists_absolute(dir):
		return false
	var prefix := "world_%d_%d_p%d_s%d_" % [CacheStore.quant(lat), CacheStore.quant(lon),
		preset, season]
	var best := ""
	var best_t := -1
	for f in DirAccess.get_files_at(dir):
		if f.begins_with(prefix) and f.ends_with(".scn") and not f.ends_with(".tmp.scn"):
			var t := FileAccess.get_modified_time(dir + "/" + f)
			if t > best_t:
				best = dir + "/" + f
				best_t = t
	if best == "":
		return false
	if best == _prefetched or best in _dropped:
		return true
	_drop_prefetch()
	if ResourceLoader.load_threaded_request(best, "PackedScene", true,
			ResourceLoader.CACHE_MODE_IGNORE) == OK:
		_prefetched = best
	return true

## Unused prefetches still loading; collected once done, so their
## scenes are released without blocking the main thread on them.
static var _dropped: Array[String] = []

static func _drop_prefetch() -> void:
	if _prefetched != "":
		_dropped.append(_prefetched)
		_prefetched = ""
	for path in _dropped.duplicate():
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(path)
			_dropped.erase(path)

static func _paths(data: LocationData) -> Dictionary:
	var k := key(data)
	return {"scene": "%s/%s.scn" % [base_dir(), k], "ground": "%s/%s.ground" % [base_dir(), k]}

## Whether a world for exactly this data is already saved.
static func has_world(data: LocationData) -> bool:
	if not enabled():
		return false
	var p := _paths(data)
	return FileAccess.file_exists(p["scene"]) and FileAccess.file_exists(p["ground"])

## [ground, world] from the cache, or [] when absent/unreadable. Loads on
## a worker thread while `view` keeps drawing; a known `ground` (season
## rebuild) is reused instead of the saved one. The world is instanced
## on a Thread too (detached nodes), tracked in `threads` so the view
## joins it if it is freed meanwhile.
static func load_world(view: Node, threads: Array, data: LocationData,
		ground: GroundTruth) -> Array:
	if not enabled():
		return []
	var p := _paths(data)
	if not FileAccess.file_exists(p["scene"]) or not FileAccess.file_exists(p["ground"]):
		_drop_prefetch()
		return []
	var t0 := Time.get_ticks_msec()
	if _prefetched == p["scene"]:
		_prefetched = ""  # already loading: collect it below
	elif p["scene"] in _dropped:
		_dropped.erase(p["scene"])  # an earlier prefetch of this file: reuse it
		_drop_prefetch()
	else:
		_drop_prefetch()
		if ResourceLoader.load_threaded_request(p["scene"], "PackedScene", true,
				ResourceLoader.CACHE_MODE_IGNORE) != OK:
			return []
	while ResourceLoader.load_threaded_get_status(p["scene"]) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await view.get_tree().process_frame
	var ps := ResourceLoader.load_threaded_get(p["scene"]) as PackedScene
	var g := ground if ground != null else _load_ground(p["ground"], data)
	if ps == null or g == null:
		push_warning("WorldCache: unreadable entry %s; rebuilding" % p["scene"])
		_remove(p)
		return []
	var th := Thread.new()
	threads.append(th)
	th.start(func() -> Node3D: return ps.instantiate() as Node3D)
	while th.is_alive():
		await view.get_tree().process_frame
	threads.erase(th)
	var world: Node3D = th.wait_to_finish()
	if world == null:
		_remove(p)
		return []
	_touch(p)
	print("WORLD CACHE hit %s in %d ms" % [p["scene"].get_file(), Time.get_ticks_msec() - t0])
	return [g, world]

## Saves a freshly built [ground, world] in the background. The scene is
## packed now (cheap, before the world enters the tree). Writing it reads
## every mesh back from the server, and each read from a worker thread
## waits for a main-thread flush (one per frame: minutes for a city), so
## while the save runs the main thread services the queue each frame.
## A mesh costs the main thread ~1.2 ms of servicing whatever the frame
## rate, so a fixed slice made the save last frames / fps (Helsinki on
## Ultra: 5 s at 135 fps, 18 s at 35, 56 s at 9). The slice is PUMP_US at
## least, and PUMP_FRAME_SHARE of the frame when frames are slow, up to
## PUMP_MAX_US; while quitting nothing is drawn, so it takes HURRY_US.
## The view joins the thread on exit like its build threads.
const PUMP_US := 4000
const PUMP_FRAME_SHARE := 0.25
const PUMP_MAX_US := 33000
const HURRY_US := 40000
## Set when the app is quitting: finish the save as fast as possible.
static var hurry := false

## Main-thread microseconds to service the save's mesh reads in a frame
## that took `frame_us`.
static func pump_budget_us(frame_us: int) -> int:
	if hurry:
		return HURRY_US
	return clampi(int(frame_us * PUMP_FRAME_SHARE), PUMP_US, PUMP_MAX_US)

static func _save_in_progress(path: String) -> bool:
	var previous: Variant = _save_threads.get(path)
	if previous is Thread and previous.is_alive():
		return true
	_save_threads.erase(path)
	return false

static func save_async(view: Node, threads: Array, data: LocationData, built: Array,
		packed: PackedScene = null) -> void:
	if not enabled() or built.size() < 2 or not (built[1] is Node3D):
		return
	var p := _paths(data)
	if _save_in_progress(p["scene"]):
		return
	var ps := packed if packed != null else pack(built[1])
	if ps == null:
		return
	var ground_bytes := var_to_bytes(_ground_state(built[0] as GroundTruth))
	var th := Thread.new()
	threads.append(th)
	var err := th.start(func() -> Array:
		DirAccess.make_dir_recursive_absolute(p["scene"].get_base_dir())
		var tmp: String = p["scene"] + ".tmp.scn"
		var t0 := Time.get_ticks_msec()
		if ResourceSaver.save(ps, tmp, ResourceSaver.FLAG_COMPRESS) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
			return []
		var f := FileAccess.open(p["ground"], FileAccess.WRITE)
		if f == null:
			return []
		f.store_buffer(ground_bytes)
		f.close()
		DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),
			ProjectSettings.globalize_path(p["scene"]))
		print("WORLD CACHE saved %s in %d ms" % [p["scene"].get_file(), Time.get_ticks_msec() - t0])
		return [])
	if err != OK:
		threads.erase(th)
		push_warning("WorldCache: could not start save thread: %s" % err)
		return
	_save_threads[p["scene"]] = th
	var tree := view.get_tree()
	var last_us := [Time.get_ticks_usec()]
	var pump := func() -> void:
		var t := Time.get_ticks_usec()
		var budget := pump_budget_us(t - last_us[0])
		while th.is_alive() and Time.get_ticks_usec() - t < budget:
			RenderingServer.force_sync()
		last_us[0] = t
	tree.process_frame.connect(pump)
	while th.is_alive():
		await tree.process_frame
	tree.process_frame.disconnect(pump)
	if threads.has(th):
		threads.erase(th)
		th.wait_to_finish()
	if _save_threads.get(p["scene"]) == th:
		_save_threads.erase(p["scene"])
	# On the main thread: CacheStore's LRU state is not thread-safe.
	_bytes = -1
	if dir_override.is_empty():
		CacheStore.enforce_size_cap()  # trims worlds, then the data's share

## The world packed for saving, or null (cache off, or pack failed).
## Packing walks every node, so build_location runs it on the build
## thread while the world is still detached and pristine, not on the
## main thread before the view can show.
static func pack(world: Node3D) -> PackedScene:
	if not enabled() or world == null:
		return null
	_own(world, world)
	var ps := PackedScene.new()
	return ps if ps.pack(world) == OK else null

static func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)

## GroundTruth state (everything _init computes; the polygon/building
## arrays come back from `data`).
const GROUND_FIELDS := ["extent_m", "water_level_m", "surface_min", "surface_max",
	"datum_m", "_y_scale", "_surface", "_size", "_step_units", "_half_units", "_level"]

static func _ground_state(g: GroundTruth) -> Dictionary:
	var out := {}
	for k in GROUND_FIELDS:
		out[k] = g.get(k)
	out["shoreline"] = g.shoreline.state() if g.shoreline != null and g.shoreline.ready else {}
	out["shoreline_empty"] = g.shoreline != null and g.shoreline.empty()
	return out

static func _load_ground(path: String, data: LocationData) -> GroundTruth:
	var state: Variant = bytes_to_var(FileAccess.get_file_as_bytes(path))
	if not (state is Dictionary) or not (state as Dictionary).has_all(GROUND_FIELDS) \
			or not (state.get("shoreline") is Dictionary):
		return null
	var g := GroundTruth.new(null)
	for k in GROUND_FIELDS:
		g.set(k, state[k])
	g._buildings = data.buildings
	g.set_land(data.land_polygons)
	if not (state["shoreline"] as Dictionary).is_empty():
		g.shoreline = ShorelineModel.from_state(state["shoreline"])
		if g.shoreline == null:
			return null
	elif bool(state.get("shoreline_empty", false)):
		# Explicit absence is authoritative too: a cached dry valley must
		# not revert to the old below-global-datum flooding heuristic.
		g.shoreline = ShorelineModel.new()
	else:
		return null
	return g

static func _remove(p: Dictionary) -> void:
	_bytes = -1
	for k in p:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p[k]))

## Marks an entry used (eviction is oldest-modified first).
static func _touch(p: Dictionary) -> void:
	var f := FileAccess.open(p["ground"], FileAccess.READ_WRITE)
	if f != null and f.get_length() > 0:
		var b := f.get_8()
		f.seek(0)
		f.store_8(b)  # same byte back: refreshes the mtime only

## Bytes the built worlds hold (cached; rescanned after a change).
static func total_bytes() -> int:
	if _bytes < 0:
		enforce_budget(1 << 62)
	return _bytes

## Evicts the least recently used worlds until the directory fits
## max_bytes (default: half the settings size limit). `keep_newest`
## spares the most recent world (the one just saved or opened) even when
## it alone is over the share, so a big place is not rebuilt every visit.
static func enforce_budget(max_bytes: int = -1, keep_newest: bool = true) -> int:
	if max_bytes < 0:
		max_bytes = CacheStore.max_cache_bytes / 2
	var dir := base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		_bytes = 0
		return 0
	var entries: Array = []
	var total := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".scn") or f.ends_with(".tmp.scn"):
			continue
		var k := f.get_basename()
		var scene := dir + "/" + f
		var ground := dir + "/" + k + ".ground"
		var bytes := _size(scene) + _size(ground)
		total += bytes
		entries.append({"p": {"scene": scene, "ground": ground}, "bytes": bytes,
			"t": FileAccess.get_modified_time(ground if FileAccess.file_exists(ground) else scene)})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	if keep_newest and not entries.is_empty():
		entries.pop_back()
	var removed := 0
	for e in entries:
		if total <= max_bytes:
			break
		_remove(e["p"])
		total -= int(e["bytes"])
		removed += 1
	_bytes = total
	return removed

static func _size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_length() if f != null else 0
