class_name CityOpenData
extends Node

## City open-data layers beside the OSM fetch, for places that publish
## them (Helsinki: the building register, HelsinkiRegister, and the tree
## register, HelsinkiTrees). Each answer is cached raw under
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

func _ready() -> void:
	for name in ["register", "trees"]:
		var http := HTTPRequest.new()
		http.timeout = TIMEOUT_S
		add_child(http)
		var layer := {"http": http, "path": "", "rows": [], "task": -1, "done": true, "bytes": PackedByteArray()}
		_layers[name] = layer
		http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			_on_completed(name, result, code, body))

static func cache_path(name: String, lat: float, lon: float) -> String:
	var prefix := "hkireg_v1" if name == "register" else "hkitree_v1"
	return "%s/%s_%d_%d.json" % [CacheStore.base_dir(), prefix, CacheStore.quant(lat), CacheStore.quant(lon)]

static func request_url(name: String, lat: float, lon: float) -> String:
	return HelsinkiRegister.request_url(lat, lon) if name == "register" else HelsinkiTrees.request_url(lat, lon)

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

func cancel() -> void:
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
		var rows: Variant = HelsinkiRegister.decode(text) if name == "register" else HelsinkiTrees.decode(text)
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
	var credits: Array[String] = []
	var reg: Array = _layers["register"]["rows"] if _layers["register"]["done"] else []
	if not reg.is_empty() and not data.buildings.is_empty():
		var stats := HelsinkiRegister.apply(data.buildings, data.latitude, data.longitude, reg)
		print("REGISTER: %d rows / %d matched / %d filled" % [stats["rows"], stats["matched"], stats["filled"]])
		credits.append(HelsinkiRegister.CREDIT)
	var trees: Array = _layers["trees"]["rows"] if _layers["trees"]["done"] else []
	if not trees.is_empty():
		var stats := {}
		data.trees = HelsinkiTrees.merge(data.trees, data.latitude, data.longitude, trees,
			CityDetail.extra_trees(data), stats)
		print("TREE REGISTER: %d rows / %d matched / %d added" % [stats["rows"], stats["matched"], stats["added"]])
		credits.append(HelsinkiTrees.CREDIT)
	return credits
