class_name LandcoverFetcher
extends Node

## Per-place WorldCover and canopy windows. Each source is optional; any
## missing/corrupt tile makes that whole source unavailable for this place.
## Fetches use anonymous range reads and PNGs in the normal data cache.
signal finished(cover: Image, canopy: Image)
signal layer_finished(kind: String, image: Image)

const EXTENT_M := 2400.0
const COVER_SIZE := 256
const CANOPY_SIZE := 768
const MAX_GROUPS := 64

var offline_mode := false
var timings: Dictionary = {}
var _generation := 0
var _workers: Array[int] = []
var _cover_fetcher: CogFetcher
var _canopy_fetcher: CogFetcher
var _remaining := 0
var _images := {}
var _abort: BuildAbort = null
var _started_ms := 0

func _ready() -> void:
	_cover_fetcher = CogFetcher.new()
	_canopy_fetcher = CogFetcher.new()
	add_child(_cover_fetcher)
	add_child(_canopy_fetcher)

func cancel() -> void:
	_generation += 1
	if _abort != null:
		_abort.requested = true
	if is_instance_valid(_cover_fetcher):
		_cover_fetcher.cancel()
	if is_instance_valid(_canopy_fetcher):
		_canopy_fetcher.cancel()
	for task in _workers:
		WorkerThreadPool.wait_for_task_completion(task)
	_workers.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		cancel()

static func cache_path(kind: String, lat: float, lon: float) -> String:
	return CacheStore.landcover_path(kind, lat, lon)

static func accessed_date(kind: String, lat: float, lon: float) -> String:
	var path := cache_path(kind, lat, lon)
	var timestamp := FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0
	return Time.get_date_string_from_unix_time(timestamp) if timestamp > 0 else Time.get_date_string_from_system()

func fetch(lat: float, lon: float) -> void:
	cancel()
	_abort = BuildAbort.new()
	_remaining = 2
	_images = {}
	timings = {}
	_started_ms = Time.get_ticks_msec()
	_fetch_one("landcover", lat, lon, _cover_fetcher, _generation)
	_fetch_one("canopy", lat, lon, _canopy_fetcher, _generation)

func _fetch_one(kind: String, lat: float, lon: float, reader: CogFetcher, gen: int) -> void:
	var size := COVER_SIZE if kind == "landcover" else CANOPY_SIZE
	var path := cache_path(kind, lat, lon)
	if FileAccess.file_exists(path):
		var cached := Image.load_from_file(path)
		if cached != null and not cached.is_empty() and cached.get_size() == Vector2i(size, size):
			CacheStore.note_read(path)
			_done(kind, cached, gen)
			return
	if offline_mode:
		_done(kind, null, gen)
		return
	var box := {}
	var abort := _abort
	var task := WorkerThreadPool.add_task(func() -> void:
		box["plan"] = plan_window(kind, lat, lon, size, abort))
	_workers.append(task)
	while _workers.has(task) and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _workers.has(task):
		WorkerThreadPool.wait_for_task_completion(task)
		_workers.erase(task)
	if gen != _generation:
		return
	var plan: Dictionary = box.get("plan", {})
	if plan.is_empty() or (plan["groups"] as Array).size() > MAX_GROUPS:
		_done(kind, null, gen)
		return
	var tiles: Array = []
	for group in plan["groups"]:
		var state := {"done": false, "result": {}}
		var callback := func(result: Dictionary) -> void:
			state["done"] = true
			state["result"] = result
		reader.finished.connect(callback, CONNECT_ONE_SHOT)
		reader.fetch_tile(group["url"], group["x"], group["y"], group["reduction"])
		while not state["done"] and gen == _generation:
			await get_tree().process_frame
		if gen != _generation:
			if reader.finished.is_connected(callback):
				reader.finished.disconnect(callback)
			return
		var tile: Dictionary = state["result"]
		if tile.is_empty() or int(tile.get("index", -1)) != int(group["index"]) \
				or int(tile.get("ifd", {}).get("width", 0)) != int(group["width"]) \
				or int(tile.get("ifd", {}).get("tile_width", 0)) != int(plan["tile_size"]):
			_done(kind, null, gen)
			return
		tiles.append(tile["pixels"])
	box = {}
	task = WorkerThreadPool.add_task(func() -> void: box["bytes"] = assemble(plan, tiles, abort))
	_workers.append(task)
	while _workers.has(task) and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _workers.has(task):
		WorkerThreadPool.wait_for_task_completion(task)
		_workers.erase(task)
	if gen != _generation:
		return
	var bytes: PackedByteArray = box.get("bytes", PackedByteArray())
	if bytes.size() != size * size:
		_done(kind, null, gen)
		return
	var image := Image.create_from_data(size, size, false, Image.FORMAT_L8, bytes)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.base_dir()))
	var temp := path + ".tmp-%d-%d" % [OS.get_process_id(), get_instance_id()]
	if image.save_png(temp) == OK \
			and DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK:
		CacheStore.note_written(path)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	_done(kind, image, gen)

func _done(kind: String, image: Image, gen: int) -> void:
	if gen != _generation:
		return
	_images[kind] = image
	timings[kind] = {"ms": Time.get_ticks_msec() - _started_ms, "available": image != null}
	layer_finished.emit(kind, image)
	_remaining -= 1
	if _remaining == 0:
		print("LANDCOVER fetch: ", timings)
		finished.emit(_images.get("landcover"), _images.get("canopy"))

## Row-major output samples mapped to source tiles. Encoding stores a
## one-based group index plus 10-bit in-tile x/y; 0 means unavailable.
static func plan_window(kind: String, lat: float, lon: float, size: int, abort: BuildAbort = null) -> Dictionary:
	if kind not in ["landcover", "canopy"] or size <= 0 or size > 1024 \
			or not is_finite(lat) or not is_finite(lon) or absf(lat) >= 89.9:
		return {}
	var factor := 1 if kind == "landcover" else 4
	var full := LandcoverSource.WORLDCOVER_SIZE if kind == "landcover" else LandcoverSource.CANOPY_SIZE
	var width := full / factor
	var tile_size := 1024 if kind == "landcover" else 512
	var columns := ceili(float(width) / float(tile_size))
	var groups: Array = []
	var ids := {}
	var mapping := PackedInt32Array()
	mapping.resize(size * size)
	var lon_scale := 111320.0 * cos(deg_to_rad(lat))
	for z in size:
		if abort != null and abort.requested:
			return {}
		var latitude := lat - ((float(z) + 0.5) / float(size) - 0.5) * EXTENT_M / 110540.0
		for x in size:
			var longitude := fposmod(lon + ((float(x) + 0.5) / float(size) - 0.5) * EXTENT_M / lon_scale + 180.0, 360.0) - 180.0
			var source := LandcoverSource.worldcover(latitude, longitude) if kind == "landcover" \
				else LandcoverSource.canopy(latitude, longitude)
			if source.is_empty():
				return {}
			var pixel: Vector2i = source["pixel"]
			var px := pixel.x / factor
			var py := pixel.y / factor
			var tx := px / tile_size
			var ty := py / tile_size
			var tile_index := ty * columns + tx
			var key := str(source["tile"]) + ":" + str(tile_index)
			if not ids.has(key):
				if groups.size() >= MAX_GROUPS:
					return {}
				ids[key] = groups.size()
				groups.append({"url": source["url"], "x": pixel.x, "y": pixel.y,
					"reduction": float(factor), "index": tile_index, "width": width})
			var group := int(ids[key]) + 1
			mapping[z * size + x] = (group << 20) | ((py % tile_size) << 10) | (px % tile_size)
	return {"groups": groups, "mapping": mapping, "tile_size": tile_size}

static func assemble(plan: Dictionary, tiles: Array, abort: BuildAbort = null) -> PackedByteArray:
	var mapping: PackedInt32Array = plan.get("mapping", PackedInt32Array())
	var tile_size := int(plan.get("tile_size", 0))
	if mapping.is_empty() or tile_size <= 0:
		return PackedByteArray()
	var out := PackedByteArray()
	out.resize(mapping.size())
	for i in mapping.size():
		if i % 4096 == 0 and abort != null and abort.requested:
			return PackedByteArray()
		var code := mapping[i]
		var group := (code >> 20) - 1
		var x := code & 1023
		var y := (code >> 10) & 1023
		if group < 0 or group >= tiles.size() or x >= tile_size or y >= tile_size:
			return PackedByteArray()
		var tile: PackedByteArray = tiles[group]
		if tile.size() != tile_size * tile_size:
			return PackedByteArray()
		out[i] = tile[y * tile_size + x]
	return out
