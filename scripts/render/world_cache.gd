class_name WorldCache
extends RefCounted

## Built-world cache (T7.5): a cached revisit loads the finished world and
## its GroundTruth instead of rebuilding them (Paris High: ~31 s of build
## → ~1.5 s threaded load on the capture machine). The first visit pays a
## background save after the view opens. Worlds live apart from the data
## cache (user://worlds, own MAX_BYTES budget, oldest-first eviction) so a
## ~200 MB world never evicts DEM/OSM/satellite tiles.
##
## Key: place (quantized lat/lon) + preset + season + a fingerprint of the
## LocationData the world was built from + BUILD_VERSION. Bump
## BUILD_VERSION whenever a generation builder changes its output; debug
## builds also hash the generator sources, so a stale world can never be
## shown while developing. Headless runs (dummy renderer, no mesh data to
## save) bypass the cache entirely.

const BUILD_VERSION := 5
const DIR := "user://worlds"
const MAX_BYTES := 1024 * 1024 * 1024
## Sources whose output a cached world freezes (debug-build fingerprint).
const SOURCE_DIRS := ["res://scripts/generation", "res://scripts/render", "res://scripts/data"]

static var _source_hash := ""

static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"

static func key(data: LocationData) -> String:
	var fp := [BUILD_VERSION, data.quality_preset, data.season, data.grid_size,
		data.heights.size(), data.buildings.size(), data.roads.size(),
		data.land_polygons.size(), data.waterways.size(), data.trees.size(),
		data.landmark_type, str(data.dem_source), str(data.satellite_source),
		data.far_landuse.size(), data.far_towers.size(), str(data.climate), _sources()]
	return "world_%d_%d_p%d_s%d_%08x" % [CacheStore.quant(data.latitude),
		CacheStore.quant(data.longitude), data.quality_preset, data.season,
		hash(str(fp)) & 0xffffffff]

static func _sources() -> String:
	if not OS.is_debug_build():
		return ""
	if _source_hash == "":
		var acc := ""
		for d in SOURCE_DIRS:
			for f in DirAccess.get_files_at(d):
				if f.ends_with(".gd"):
					acc += str(hash(FileAccess.get_file_as_string(d + "/" + f)))
		_source_hash = str(hash(acc))
	return _source_hash

static func _paths(data: LocationData) -> Dictionary:
	var k := key(data)
	return {"scene": "%s/%s.scn" % [DIR, k], "ground": "%s/%s.ground" % [DIR, k]}

## [ground, world] from the cache, or [] when absent/unreadable. Loads on
## a worker thread while `view` keeps drawing; a known `ground` (season
## rebuild) is reused instead of the saved one.
static func load_world(view: Node, data: LocationData, ground: GroundTruth) -> Array:
	if not enabled():
		return []
	var p := _paths(data)
	if not FileAccess.file_exists(p["scene"]) or not FileAccess.file_exists(p["ground"]):
		return []
	var t0 := Time.get_ticks_msec()
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
	var world := ps.instantiate() as Node3D
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
## while the save runs the main thread services the queue for PUMP_US
## each frame. The view joins the thread on exit like its build threads.
const PUMP_US := 4000

static func save_async(view: Node, threads: Array, data: LocationData, built: Array) -> void:
	if not enabled() or built.size() < 2 or not (built[1] is Node3D):
		return
	var world: Node3D = built[1]
	_own(world, world)
	var ps := PackedScene.new()
	if ps.pack(world) != OK:
		return
	var p := _paths(data)
	var ground_bytes := var_to_bytes(_ground_state(built[0] as GroundTruth))
	var th := Thread.new()
	threads.append(th)
	th.start(func() -> Array:
		DirAccess.make_dir_recursive_absolute(DIR)
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
		enforce_budget()
		return [])
	var tree := view.get_tree()
	var pump := func() -> void:
		var t := Time.get_ticks_usec()
		while th.is_alive() and Time.get_ticks_usec() - t < PUMP_US:
			RenderingServer.force_sync()
	tree.process_frame.connect(pump)
	while th.is_alive():
		await tree.process_frame
	tree.process_frame.disconnect(pump)
	if threads.has(th):
		threads.erase(th)
		th.wait_to_finish()

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
	return out

static func _load_ground(path: String, data: LocationData) -> GroundTruth:
	var state: Variant = bytes_to_var(FileAccess.get_file_as_bytes(path))
	if not (state is Dictionary) or not (state as Dictionary).has_all(GROUND_FIELDS):
		return null
	var g := GroundTruth.new(null)
	for k in GROUND_FIELDS:
		g.set(k, state[k])
	g._land = data.land_polygons
	g._buildings = data.buildings
	return g

static func _remove(p: Dictionary) -> void:
	for k in p:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p[k]))

## Marks an entry used (eviction is oldest-modified first).
static func _touch(p: Dictionary) -> void:
	var f := FileAccess.open(p["ground"], FileAccess.READ_WRITE)
	if f != null and f.get_length() > 0:
		var b := f.get_8()
		f.seek(0)
		f.store_8(b)  # same byte back: refreshes the mtime only

## Evicts the least recently used worlds until the directory fits.
static func enforce_budget(max_bytes: int = MAX_BYTES) -> int:
	var entries: Array = []
	var total := 0
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".scn") or f.ends_with(".tmp.scn"):
			continue
		var k := f.get_basename()
		var scene := DIR + "/" + f
		var ground := DIR + "/" + k + ".ground"
		var bytes := _size(scene) + _size(ground)
		total += bytes
		entries.append({"p": {"scene": scene, "ground": ground}, "bytes": bytes,
			"t": FileAccess.get_modified_time(ground if FileAccess.file_exists(ground) else scene)})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	var removed := 0
	for e in entries:
		if total <= max_bytes:
			break
		_remove(e["p"])
		total -= int(e["bytes"])
		removed += 1
	return removed

static func _size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_length() if f != null else 0
