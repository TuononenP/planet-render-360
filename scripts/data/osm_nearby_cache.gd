class_name OsmNearbyCache
extends RefCounted

## Cached detailed OSM payloads near a place, for when every live source
## failed. Cache keys quantise to ~110 m, and a payload at any radius
## still covers most of a neighbouring view, so real data from a cached
## spot a few hundred metres away beats procedural dressing. Payloads
## converted from the OSM API ("api" keys) are lossy, so a real Overpass
## payload at the same distance goes first.

static func _regex() -> RegEx:
	var rx := RegEx.new()
	rx.compile("^osm_v%d_(-?\\d+)_(-?\\d+)_(r|api)(\\d+)(?:_q(\\d+))?\\.json$" % CacheStore.DATA_VERSION)
	return rx

## Metres from the place to the spot a detailed cache file was keyed at,
## or -1 when the name is not a detailed OSM payload.
static func distance_m(path: String, lat: float, lon: float) -> float:
	var m := _regex().search(path.get_file())
	if m == null:
		return -1.0
	return _metres(m, lat, lon)

static func _metres(m: RegExMatch, lat: float, lon: float) -> float:
	var c_lat := int(m.get_string(1)) / 1000.0
	var c_lon := int(m.get_string(2)) / 1000.0
	return WorldScale.xz_from_latlon(c_lat, c_lon, lat, lon).length() \
		/ WorldScale.metres_to_units()

## The cache directory holds thousands of imagery and DEM tiles: listing
## and matching all of them took ~190 ms of the main thread at every
## streamed fetch. The OSM names of the app's own cache are listed once,
## then kept: OsmFetcher adds each payload it writes (note), and a worker
## lists the directory again after LIST_TTL_MS while the old names serve.
## An overridden directory (tests) is listed every time.
const LIST_TTL_MS := 300000
static var _listed: PackedStringArray = []
static var _listed_dir := ""
static var _listed_at := -LIST_TTL_MS
static var _relist_task := -1
static var _relisted: PackedStringArray = []

## A detailed payload was just written at `path`.
static func note(path: String) -> void:
	var f := path.get_file()
	if path.get_base_dir() == _listed_dir and f.begins_with("osm_") and not f in _listed:
		_listed.append(f)

static func _osm_files() -> PackedStringArray:
	var dir := CacheStore.base_dir()
	var now := Time.get_ticks_msec()
	if not CacheStore.dir_override.is_empty() or dir != _listed_dir:
		_listed = _list(dir)
		_listed_dir = dir
		_listed_at = now
	elif _relist_task >= 0 and WorkerThreadPool.is_task_completed(_relist_task):
		WorkerThreadPool.wait_for_task_completion(_relist_task)
		_relist_task = -1
		for f in _listed:
			if not f in _relisted:
				_relisted.append(f)  # noted while the worker listed
		_listed = _relisted
		_listed_at = now
	elif _relist_task < 0 and now - _listed_at >= LIST_TTL_MS:
		_relist_task = WorkerThreadPool.add_task(func() -> void: _relisted = _list(dir),
			false, "List OSM cache")
		_hook_exit()
	return _listed

## The relisting task is joined when the tree quits, never left running.
static var _exit_hooked := false

static func _hook_exit() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if _exit_hooked or tree == null or tree.root == null:
		return
	_exit_hooked = true
	tree.root.tree_exiting.connect(func() -> void:
		if _relist_task >= 0:
			WorkerThreadPool.wait_for_task_completion(_relist_task)
			_relist_task = -1)

static func _list(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("osm_"):
			out.append(f)
	return out

## Cache-file paths within max_m of the place, nearest first (Overpass
## before API, then larger radius first, on a tie). Ring payloads and
## other layers are ignored.
static func candidates(lat: float, lon: float, max_m: float) -> Array[String]:
	var rx := _regex()
	var found: Array = []
	for f in _osm_files():
		var m := rx.search(f)
		if m == null:
			continue
		var d := _metres(m, lat, lon)
		if d <= max_m:
			found.append({"path": "%s/%s" % [CacheStore.base_dir(), f], "d": d,
				"api": m.get_string(3) == "api", "r": int(m.get_string(4)), "q": int(m.get_string(5))})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(a["d"], b["d"]):
			return a["d"] < b["d"]
		if a["api"] != b["api"]:
			return not a["api"]
		if a["r"] != b["r"]:
			return a["r"] > b["r"]
		return a["q"] > b["q"])
	var out: Array[String] = []
	for e in found:
		out.append(e["path"])
	return out
