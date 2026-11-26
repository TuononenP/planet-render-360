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
## The capital region's canopy (HsyCanopy) instead of Meta's alone.
var _hsy := false
## HSY band requests in flight (HsyCanopy, HsyCover), BAND_PARALLEL per
## layer: the canopy and surface classes load beside each other.
var _band_http: Array[HTTPRequest] = []
const BAND_PARALLEL := 4
const COG_PARALLEL := 6
## Where the last canopy came from: "meta", "hsy", "hsy+meta" or "".
var canopy_source := ""
## In-flight window fetches keyed by cache path so warm + live runs never
## download the same canopy or land-cover window twice concurrently.
static var _inflight := {}  # path -> Array[Callable]
var _owned_paths: Array[String] = []

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
	for http in _band_http:
		if is_instance_valid(http):
			http.cancel_request()
			http.queue_free()
	_band_http.clear()
	for task in _workers:
		WorkerThreadPool.wait_for_task_completion(task)
	_workers.clear()
	for p in _owned_paths:
		_finish_inflight(p, null, "", true)
	_owned_paths.clear()

func _release_inflight(path: String, img: Image, src: String, cancelled := false) -> void:
	if _owned_paths.has(path):
		_owned_paths.erase(path)
		_finish_inflight(path, img, src, cancelled)

static func _finish_inflight(path: String, img: Image, src: String, cancelled := false) -> void:
	var waiters: Array = _inflight.get(path, [])
	_inflight.erase(path)
	for cb: Callable in waiters:
		if cb.is_valid():
			cb.call(img, src, cancelled)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		cancel()

static func cache_path(kind: String, lat: float, lon: float) -> String:
	return CacheStore.landcover_path(kind, lat, lon)

static func accessed_date(kind: String, lat: float, lon: float) -> String:
	var path := cache_path(kind, lat, lon)
	var timestamp := FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0
	return Time.get_date_string_from_unix_time(timestamp) if timestamp > 0 else Time.get_date_string_from_system()

## `hsy`: use HSY's canopy where it covers the place (CityDetail, High /
## Ultra in Helsinki and Espoo).
func fetch(lat: float, lon: float, hsy: bool = false) -> void:
	cancel()
	_hsy = hsy and HsyCanopy.covers(lat, lon)
	canopy_source = ""
	_abort = BuildAbort.new()
	_remaining = 3 if _hsy else 2
	_images = {}
	timings = {}
	_started_ms = Time.get_ticks_msec()
	_fetch_one("landcover", lat, lon, _cover_fetcher, _generation)
	_fetch_one("canopy", lat, lon, _canopy_fetcher, _generation)
	if _hsy:
		_fetch_hsy_cover(lat, lon, _generation)

func _fetch_one(kind: String, lat: float, lon: float, reader: CogFetcher, gen: int) -> void:
	if kind == "canopy" and _hsy:
		var hsy: Image = await _fetch_hsy(lat, lon, reader, gen)
		if gen != _generation:
			return
		if hsy != null:
			_done(kind, hsy, gen)
			return
	var image: Image = await _fetch_cog(kind, lat, lon, reader, gen)
	if gen != _generation:
		return
	if kind == "canopy" and image != null:
		canopy_source = "meta"
	_done(kind, image, gen)

## The cached or freshly read COG window of `kind`; null when unavailable
## (or superseded: the caller checks the generation).
func _fetch_cog(kind: String, lat: float, lon: float, reader: CogFetcher, gen: int) -> Image:
	var size := COVER_SIZE if kind == "landcover" else CANOPY_SIZE
	var path := cache_path(kind, lat, lon)
	if FileAccess.file_exists(path):
		var cached := Image.load_from_file(path)
		if cached != null and not cached.is_empty() and cached.get_size() == Vector2i(size, size):
			CacheStore.note_read(path)
			return cached
	if offline_mode:
		return null
	while _inflight.has(path):
		var shared := {"done": false, "img": null, "cancelled": false}
		(_inflight[path] as Array).append(func(img: Image, _src: String, cancelled: bool) -> void:
			shared["img"] = img
			shared["cancelled"] = cancelled
			shared["done"] = true)
		while not shared["done"] and gen == _generation and is_inside_tree():
			await get_tree().process_frame
		if gen != _generation:
			return null
		if shared["img"] != null:
			return shared["img"]
		if not bool(shared["cancelled"]) or not is_inside_tree():
			return null
	_inflight[path] = []
	_owned_paths.append(path)
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
		_release_inflight(path, null, "", true)
		return null
	var plan: Dictionary = box.get("plan", {})
	var groups: Array = plan.get("groups", []) if not plan.is_empty() else []
	if plan.is_empty() or groups.size() > MAX_GROUPS:
		_release_inflight(path, null, "")
		return null
	var tiles: Array = []
	tiles.resize(groups.size())
	var gstate := {"next": 0, "pending": 0, "failed": false}
	while (int(gstate["next"]) < groups.size() or int(gstate["pending"]) > 0) \
			and gen == _generation and not bool(gstate["failed"]) and is_inside_tree():
		while int(gstate["next"]) < groups.size() and int(gstate["pending"]) < COG_PARALLEL \
				and not bool(gstate["failed"]):
			var gi := int(gstate["next"])
			gstate["next"] = gi + 1
			gstate["pending"] = int(gstate["pending"]) + 1
			var group: Dictionary = groups[gi]
			(func() -> void:
				var tile := await reader.read_tile(group["url"], group["x"], group["y"], group["reduction"])
				gstate["pending"] = int(gstate["pending"]) - 1
				if gen != _generation:
					return
				if tile.is_empty() or int(tile.get("index", -1)) != int(group["index"]) \
						or int(tile.get("ifd", {}).get("width", 0)) != int(group["width"]) \
						or int(tile.get("ifd", {}).get("tile_width", 0)) != int(plan["tile_size"]):
					gstate["failed"] = true
				else:
					tiles[gi] = tile["pixels"]).call()
		if int(gstate["pending"]) > 0:
			await get_tree().process_frame
	if bool(gstate["failed"]):
		reader.cancel()
	if gen != _generation or bool(gstate["failed"]):
		_release_inflight(path, null, "", gen != _generation)
		return null
	box = {}
	task = WorkerThreadPool.add_task(func() -> void: box["bytes"] = assemble(plan, tiles, abort))
	_workers.append(task)
	while _workers.has(task) and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _workers.has(task):
		WorkerThreadPool.wait_for_task_completion(task)
		_workers.erase(task)
	if gen != _generation:
		_release_inflight(path, null, "", true)
		return null
	var bytes: PackedByteArray = box.get("bytes", PackedByteArray())
	if bytes.size() != size * size:
		_release_inflight(path, null, "")
		return null
	var image := Image.create_from_data(size, size, false, Image.FORMAT_L8, bytes)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CacheStore.base_dir()))
	var temp := path + ".tmp-%d-%d" % [OS.get_process_id(), get_instance_id()]
	if image.save_png(temp) == OK \
			and DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK:
		CacheStore.note_written(path)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	_release_inflight(path, image, "meta")
	return image

## HSY's canopy bands composed over Meta's CHM (HsyCanopy), cached as
## its own raster; null when a band is unavailable (Meta's alone then).
func _fetch_hsy(lat: float, lon: float, reader: CogFetcher, gen: int) -> Image:
	for kind in ["canopy_hsym", "canopy_hsy"]:
		var path := cache_path(kind, lat, lon)
		if FileAccess.file_exists(path):
			var cached := Image.load_from_file(path)
			if cached != null and cached.get_size() == Vector2i(CANOPY_SIZE, CANOPY_SIZE):
				CacheStore.note_read(path)
				canopy_source = "hsy+meta" if kind == "canopy_hsym" else "hsy"
				return cached
	if offline_mode:
		return null
	var hsy_key := cache_path("canopy_hsym", lat, lon)
	while _inflight.has(hsy_key):
		var shared := {"done": false, "img": null, "src": "", "cancelled": false}
		(_inflight[hsy_key] as Array).append(func(img: Image, src: String, cancelled: bool) -> void:
			shared["img"] = img
			shared["src"] = src
			shared["cancelled"] = cancelled
			shared["done"] = true)
		while not shared["done"] and gen == _generation and is_inside_tree():
			await get_tree().process_frame
		if gen != _generation:
			return null
		if shared["img"] != null:
			canopy_source = str(shared["src"])
			return shared["img"]
		if not bool(shared["cancelled"]) or not is_inside_tree():
			return null
	_inflight[hsy_key] = []
	_owned_paths.append(hsy_key)
	var urls: Array = []
	for i in HsyCanopy.LAYERS.size():
		urls.append(HsyCanopy.band_url(i, lat, lon, CANOPY_SIZE))
	# Overlap HSY WMS bands and Meta CHM COG tiles instead of awaiting sequentially.
	var both := {"bands_done": false, "bodies": null, "chm_done": false, "chm": null}
	(func() -> void:
		both["bodies"] = await _fetch_bands(urls, gen)
		both["bands_done"] = true).call()
	(func() -> void:
		both["chm"] = await _fetch_cog("canopy", lat, lon, reader, gen)
		both["chm_done"] = true).call()
	while (not bool(both["bands_done"]) or not bool(both["chm_done"])) \
			and gen == _generation and is_inside_tree():
		await get_tree().process_frame
	if gen != _generation:
		_release_inflight(hsy_key, null, "", true)
		return null
	var bodies: Variant = both["bodies"]
	var chm: Image = both["chm"]
	if not (bodies is Array):
		_release_inflight(hsy_key, null, "")
		print("HSY canopy bands unavailable; Meta canopy instead")
		return null
	var box := {}
	var task := WorkerThreadPool.add_task(func() -> void:
		var bands: Variant = decode_bands(bodies)
		box["image"] = HsyCanopy.compose(bands, chm, CANOPY_SIZE) if bands is Array else null)
	_workers.append(task)
	while _workers.has(task) and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _workers.has(task):
		WorkerThreadPool.wait_for_task_completion(task)
		_workers.erase(task)
	if gen != _generation or box.get("image") == null:
		_release_inflight(hsy_key, null, "", gen != _generation)
		return null
	var image: Image = box["image"]
	var kind := "canopy_hsym" if chm != null else "canopy_hsy"
	var path := cache_path(kind, lat, lon)
	if image.save_png(path) == OK:
		CacheStore.note_written(path)
	canopy_source = "hsy+meta" if chm != null else "hsy"
	_release_inflight(hsy_key, image, canopy_source)
	return image

## The PNG bodies of `urls`, BAND_PARALLEL at a time, in order; null
## when any is unavailable or the fetch was superseded.
func _fetch_bands(urls: Array, gen: int) -> Variant:
	var bodies: Array = []
	bodies.resize(urls.size())
	var state := {"pending": 0, "failed": false}
	var next := 0
	while (next < urls.size() or int(state["pending"]) > 0) and gen == _generation \
			and not state["failed"]:
		while next < urls.size() and int(state["pending"]) < BAND_PARALLEL:
			var http := HTTPRequest.new()
			http.timeout = 20.0
			add_child(http)
			_band_http.append(http)
			var index := next
			http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
				state["pending"] = int(state["pending"]) - 1
				if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not body.is_empty():
					bodies[index] = body
				else:
					state["failed"] = true
				_band_http.erase(http)
				http.queue_free(), CONNECT_ONE_SHOT)
			next += 1
			if http.request(str(urls[index]), ["User-Agent: " + Brand.USER_AGENT]) != OK:
				state["failed"] = true
				_band_http.erase(http)
				http.queue_free()
				break
			state["pending"] = int(state["pending"]) + 1
		await get_tree().process_frame
	if gen != _generation or state["failed"]:
		return null
	return bodies

## The band images of PNG `bodies` (any thread); null when one is not a PNG.
static func decode_bands(bodies: Array) -> Variant:
	var bands: Array = []
	for body: Variant in bodies:
		var img := Image.new()
		if not (body is PackedByteArray) or (body as PackedByteArray).is_empty() \
				or img.load_png_from_buffer(body) != OK:
			return null
		bands.append(img)
	return bands

## HSY's surface classes over the extent (HsyCover), as the class map's
## size, cached per place; emits layer_finished("hsy_cover", ...), null
## when unavailable.
func _fetch_hsy_cover(lat: float, lon: float, gen: int) -> void:
	var size := GroundMaterial.CLASS_TEXELS
	var path := cache_path("hsy_cover%d" % HsyCover.VERSION, lat, lon)
	if FileAccess.file_exists(path):
		var cached := Image.load_from_file(path)
		if cached != null and cached.get_size() == Vector2i(size, size):
			if cached.get_format() != Image.FORMAT_R8:
				cached.convert(Image.FORMAT_R8)
			CacheStore.note_read(path)
			_done("hsy_cover", cached, gen)
			return
	if offline_mode:
		_done("hsy_cover", null, gen)
		return
	var urls: Array = []
	for i in HsyCover.LAYERS.size():
		urls.append(HsyCover.band_url(i, lat, lon, size))
	var bodies: Variant = await _fetch_bands(urls, gen)
	if gen != _generation:
		return
	if not (bodies is Array):
		print("HSY land cover unavailable; map and WorldCover classes only")
		_done("hsy_cover", null, gen)
		return
	var box := {}
	var task := WorkerThreadPool.add_task(func() -> void:
		var bands: Variant = decode_bands(bodies)
		box["image"] = HsyCover.compose(bands, size) if bands is Array else null)
	_workers.append(task)
	while _workers.has(task) and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _workers.has(task):
		WorkerThreadPool.wait_for_task_completion(task)
		_workers.erase(task)
	if gen != _generation:
		return
	var image: Image = box.get("image")
	if image != null and image.save_png(path) == OK:
		CacheStore.note_written(path)
	_done("hsy_cover", image, gen)

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
