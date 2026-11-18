class_name CityOpenData
extends Node

## City open-data layers beside the OSM fetch, for places that publish
## them (Helsinki: the building register, HelsinkiRegister; the tree
## register, HelsinkiTrees; the surveyed street areas, HelsinkiStreets;
## and the bundled LoD2 roofs, HelsinkiLod2). Each answer is cached raw under
## user://cache per place, decoded on the worker pool, and `land` merges
## both into the map data before GroundTruth reads it. Any failure leaves
## the place on its map data, as before. No key, no account.

const TIMEOUT_S := 15.0
## How long `land` waits past the map data for a cold answer.
const LAND_WAIT_S := 20.0
const STREAM_LAND_WAIT_S := 6.0

## No network: cached answers only (OsmFetcher.offline_mode).
var offline := false

var _layers := {}  # name -> {http, path, rows, task, done}
var _land_task := -1
## Test hook: when set, a merge waits on it before it starts.
var _merge_gate: Semaphore = null
const LAYER_NAMES := ["register", "trees", "carriageway", "walkways"]
const PREFIX := {"register": "hkireg_v1", "trees": "hkitree_v1",
	"carriageway": "hkistreet_car_v1", "walkways": "hkistreet_walk_v1"}

func _ready() -> void:
	for name in LAYER_NAMES:
		var http := HTTPRequest.new()
		http.timeout = TIMEOUT_S
		add_child(http)
		var layer := {"http": http, "path": "", "rows": [], "task": -1, "done": true, "bytes": PackedByteArray()}
		_layers[name] = layer
		http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			_on_completed(name, result, code, body))

static func cache_path(name: String, lat: float, lon: float) -> String:
	return "%s/%s_%d_%d.json" % [CacheStore.base_dir(), PREFIX[name], CacheStore.quant(lat), CacheStore.quant(lon)]

static func request_url(name: String, lat: float, lon: float) -> String:
	match name:
		"register":
			return HelsinkiRegister.request_url(lat, lon)
		"trees":
			return HelsinkiTrees.request_url(lat, lon)
	return HelsinkiStreets.request_url(name, lat, lon)

static func decode(name: String, text: String) -> Variant:
	match name:
		"register":
			return HelsinkiRegister.decode(text)
		"trees":
			return HelsinkiTrees.decode(text)
	return HelsinkiStreets.decode(text)

## Starts every layer that covers (lat, lon); the rest finish at once.
func fetch(lat: float, lon: float) -> void:
	cancel()
	var covered := HelsinkiRegister.covers(lat, lon)
	for name in _layers:
		var layer: Dictionary = _layers[name]
		layer["rows"] = []
		layer["done"] = not covered
		if not covered:
			continue
		layer["path"] = cache_path(name, lat, lon)
		if FileAccess.file_exists(layer["path"]):
			CacheStore.note_read(layer["path"])
			_decode(name, FileAccess.get_file_as_bytes(layer["path"]), false)
			continue
		if offline:
			layer["done"] = true
			continue
		var err := (layer["http"] as HTTPRequest).request(request_url(name, lat, lon),
			["User-Agent: " + Brand.USER_AGENT])
		if err != OK:
			layer["done"] = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for name in _layers:
			_join(_layers[name])
		_join_land()

func _join_land() -> void:
	if _land_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_land_task)
		_land_task = -1

func cancel() -> void:
	_join_land()
	for name in _layers:
		var layer: Dictionary = _layers[name]
		(layer["http"] as HTTPRequest).cancel_request()
		_join(layer)
		layer["done"] = true

func _on_completed(name: String, result: int, code: int, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("City open data (%s) unavailable (result=%d code=%d)" % [name, result, code])
		_layers[name]["done"] = true
		return
	_decode(name, body, true)

## Decodes on the worker pool; a valid fresh answer is cached raw.
func _decode(name: String, body: PackedByteArray, fresh: bool) -> void:
	var layer: Dictionary = _layers[name]
	layer["bytes"] = body
	layer["fresh"] = fresh
	# The worker writes only its own result dict, read after the join.
	var out := {}
	layer["out"] = out
	layer["task"] = WorkerThreadPool.add_task(func() -> void:
		var text := body.get_string_from_utf8()
		var rows: Variant = CityOpenData.decode(name, text)
		out["rows"] = rows if rows is Array else []
		out["valid"] = rows is Array, false, "CityOpenData")

func _process(_delta: float) -> void:
	for name in _layers:
		var layer: Dictionary = _layers[name]
		if int(layer["task"]) >= 0 and WorkerThreadPool.is_task_completed(int(layer["task"])):
			_join(layer)
			var out: Dictionary = layer.get("out", {})
			layer["rows"] = out.get("rows", [])
			if layer.get("fresh", false) and out.get("valid", false):
				var f := FileAccess.open(str(layer["path"]), FileAccess.WRITE)
				if f != null:
					f.store_buffer(layer["bytes"])
					f.close()
					CacheStore.note_written(str(layer["path"]))
			layer["bytes"] = PackedByteArray()
			layer["done"] = true

func _join(layer: Dictionary) -> void:
	if int(layer["task"]) >= 0:
		WorkerThreadPool.wait_for_task_completion(int(layer["task"]))
		layer["task"] = -1

func is_done() -> bool:
	for name in _layers:
		if not _layers[name]["done"]:
			return false
	return true

## Waits (bounded) for the layers, then merges them into `data`: the
## register into data.buildings (every preset), the tree register into
## data.trees (register-only trees on High / Ultra). Returns the credits
## of the layers that landed.
func land(data: LocationData, budget_s: float = LAND_WAIT_S) -> Array[String]:
	var waited := 0.0
	while not is_done() and waited < budget_s and is_inside_tree():
		await get_tree().process_frame
		waited += get_process_delta_time()
	var reg: Array = _layers["register"]["rows"] if _layers["register"]["done"] else []
	var trees: Array = _layers["trees"]["rows"] if _layers["trees"]["done"] else []
	var car: Array = _layers["carriageway"]["rows"] if _layers["carriageway"]["done"] else []
	var walk: Array = _layers["walkways"]["rows"] if _layers["walkways"]["done"] else []
	var extra_trees := CityDetail.extra_trees(data)
	# Thousands of footprints, points, polygons and probes: off the main
	# thread. Nothing else reads this data's buildings, trees or roads
	# until the ground build starts after this returns.
	var out := {}
	# One merge at a time: a land() still waiting on an older one has it
	# joined here (and returns without credits, below).
	_join_land()
	var gate := _merge_gate
	var task := WorkerThreadPool.add_task(func() -> void:
		if gate != null:
			gate.wait()
		out.merge(merge(data, reg, trees, car, walk, extra_trees)), false, "CityOpenData")
	_land_task = task
	# cancel() (or a newer run) joins and forgets the task: stop then.
	while _land_task == task and not WorkerThreadPool.is_task_completed(task) and is_inside_tree():
		await get_tree().process_frame
	var credits: Array[String] = []
	if _land_task != task:
		return credits
	_join_land()
	for line in out.get("log", []):
		print(line)
	credits.assign(out.get("credits", []))
	return credits

## Merges the landed layers into `data` (any thread): the bundled LoD2
## roofs, then the register, the tree register and the street areas.
## Returns {log: [lines], credits: [strings]}.
static func merge(data: LocationData, reg: Array, trees: Array, car: Array, walk: Array,
		extra_trees: bool) -> Dictionary:
	var log: Array = []
	var credits: Array = []
	# Measured heights and roofs first: the register only fills a height
	# still estimated.
	var lod2 := HelsinkiLod2.rows_for(data.latitude, data.longitude)
	if not lod2.is_empty() and not data.buildings.is_empty():
		var st := HelsinkiLod2.apply(data.buildings, data.latitude, data.longitude, lod2)
		log.append("LOD2: %d rows / %d matched / %d filled" % [st["rows"], st["matched"], st["filled"]])
		if int(st["matched"]) > 0:
			credits.append(HelsinkiLod2.CREDIT)
	if not reg.is_empty() and not data.buildings.is_empty():
		var st := HelsinkiRegister.apply(data.buildings, data.latitude, data.longitude, reg)
		log.append("REGISTER: %d rows / %d matched / %d filled" % [st["rows"], st["matched"], st["filled"]])
		credits.append(HelsinkiRegister.CREDIT)
	if not trees.is_empty():
		var st := {}
		data.trees = HelsinkiTrees.merge(data.trees, data.latitude, data.longitude, trees, extra_trees, st)
		log.append("TREE REGISTER: %d rows / %d matched / %d added" % [st["rows"], st["matched"], st["added"]])
		credits.append(HelsinkiTrees.CREDIT)
	if not car.is_empty() or not walk.is_empty():
		var st := HelsinkiStreets.apply(data, car, walk)
		log.append("STREETS: %s" % str(st))
		if int(st["widths"]) > 0 or int(st["paved"]) > 0:
			credits.append(HelsinkiStreets.CREDIT)
	return {"log": log, "credits": credits}
