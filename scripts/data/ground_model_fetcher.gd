class_name GroundModelFetcher
extends Node

## Downloads and decodes the GroundModel raster for a viewpoint: GSI's
## DEM5A PNG tiles (DEM10B where 5 m is missing) in Japan, IGN's RGE ALTI
## and the AHN DTM as one window each. Answers are cached under
## user://cache (CacheStore.base_dir) so a revisit works offline. No key,
## no account; see docs/data-source-register.md.

signal finished(raster: Dictionary)

const TIMEOUT_S := 25.0
## Whole fetch: up to 16 GSI tiles in two batches, then the 10 m patch.
const TOTAL_TIMEOUT_S := 75.0
## swissALTI3D: a tile list, up to 16 one-megabyte tiles, their LZW decode.
const SWISS_TIMEOUT_S := 180.0
## Requests in flight at once.
const BATCH := 8
const GSI_URL := "https://cyberjapandata.gsi.go.jp/xyz"
const GSI_ZOOM := 15
const GSI_FALLBACK_ZOOM := 14
## A GSI tile missing more than this share of its cells asks for the 10 m
## model; fewer holes are filled from their neighbours.
const GSI_PATCH_SHARE := 0.05
const IGN_URL := "https://data.geopf.fr/wms-r/wms"
const IGN_LAYER := "ELEVATION.ELEVATIONGRIDCOVERAGE.HIGHRES"
const STAC_URL := "https://data.geo.admin.ch/api/stac/v0.9/collections/ch.swisstopo.swissalti3d/items"
const AHN_URL := "https://service.pdok.nl/rws/ahn/wcs/v1_0"
const AHN_COVERAGE := "dtm_05m"
const EPSG_3857 := "http://www.opengis.net/def/crs/EPSG/0/3857"

## Emits `finished` with the decoded raster, {} when the window is
## unavailable (network, format, or mostly outside the country's data).
func fetch(source: String, lat: float, lon: float, offline: bool = false) -> void:
	var raster := {}
	match source:
		"gsi":
			raster = await _gsi(lat, lon, offline)
		"ign":
			raster = await _ign(lat, lon, offline)
		"ahn":
			raster = await _ahn(lat, lon, offline)
		"swisstopo":
			raster = await _swiss(lat, lon, offline)
	if not raster.is_empty() and GroundModel.missing_share(raster) > GroundModel.MAX_MISSING:
		raster = {}
	finished.emit(raster)

## Seconds the whole fetch of `source` may take.
static func timeout_for(source: String) -> float:
	return SWISS_TIMEOUT_S if source == "swisstopo" else TOTAL_TIMEOUT_S

static func cache_path(source: String, lat: float, lon: float, ext: String) -> String:
	return "%s/gmodel_v1_%s_%d_%d.%s" % [CacheStore.base_dir(), source,
		CacheStore.quant(lat), CacheStore.quant(lon), ext]

static func gsi_tile_path(layer: String, zoom: int, x: int, y: int) -> String:
	return "%s/gmodel_v1_%s_%d_%d_%d.png" % [CacheStore.base_dir(), layer, zoom, x, y]

## The Mercator window around a viewpoint, snapped to whole metres so the
## same place always asks for the same bytes: {c: centre, half}.
static func window(lat: float, lon: float) -> Dictionary:
	var c := GroundModel.merc(lat, lon)
	return {"c": Vector2(roundf(c.x), roundf(c.y)), "half": GroundModel.half_merc(lat)}

static func ign_url(lat: float, lon: float) -> String:
	var w := window(lat, lon)
	var c: Vector2 = w["c"]
	var h: float = w["half"]
	return "%s?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=%s&STYLES=&CRS=EPSG:3857" % [IGN_URL, IGN_LAYER] \
		+ "&BBOX=%d,%d,%d,%d&WIDTH=%d&HEIGHT=%d&FORMAT=image/x-bil;bits=32" % [
			int(c.x - h), int(c.y - h), int(c.x + h), int(c.y + h), GroundModel.CELLS, GroundModel.CELLS]

static func ahn_url(lat: float, lon: float) -> String:
	var w := window(lat, lon)
	var c: Vector2 = w["c"]
	var h: float = w["half"]
	return "%s?SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=%s&FORMAT=image/tiff" % [AHN_URL, AHN_COVERAGE] \
		+ "&SUBSETTINGCRS=%s&OUTPUTCRS=%s" % [EPSG_3857, EPSG_3857] \
		+ "&SUBSET=x(%d,%d)&SUBSET=y(%d,%d)&SCALESIZE=x(%d),y(%d)" % [
			int(c.x - h), int(c.x + h), int(c.y - h), int(c.y + h), GroundModel.CELLS, GroundModel.CELLS]

func _ign(lat: float, lon: float, offline: bool) -> Dictionary:
	var path := cache_path("ign", lat, lon, "bil")
	var got := await _get_many([{"url": ign_url(lat, lon), "path": path}], offline, _is_bil)
	var bytes: PackedByteArray = got[0]
	var w := window(lat, lon)
	var c: Vector2 = w["c"]
	var h: float = w["half"]
	return GroundModel.decode_bil(bytes, GroundModel.CELLS, Vector2(c.x - h, c.y + h),
		2.0 * h / float(GroundModel.CELLS))

func _ahn(lat: float, lon: float, offline: bool) -> Dictionary:
	var path := cache_path("ahn", lat, lon, "tif")
	var got := await _get_many([{"url": ahn_url(lat, lon), "path": path}], offline, _is_tiff)
	var bytes: PackedByteArray = got[0]
	var raster := GroundTiff.decode(bytes)
	if raster.is_empty():
		return {}
	var cell: Vector2 = raster["cell"]
	if cell.x < 1.0 or cell.x > 40.0 or cell.y < 1.0 or cell.y > 40.0:
		return {}
	var values: PackedFloat32Array = raster["values"]
	for i in values.size():
		values[i] = GroundModel.valid_height(values[i])
	raster["values"] = values
	return raster

## lat/lon box of the Mercator window.
static func latlon_box(lat: float, lon: float) -> Rect2:
	var w := window(lat, lon)
	var c: Vector2 = w["c"]
	var h: float = w["half"]
	var lo := Vector2(rad_to_deg((c.x - h) / GroundModel.MERC_R), rad_to_deg(atan(sinh((c.y - h) / GroundModel.MERC_R))))
	var hi := Vector2(rad_to_deg((c.x + h) / GroundModel.MERC_R), rad_to_deg(atan(sinh((c.y + h) / GroundModel.MERC_R))))
	return Rect2(lo, hi - lo)

static func stac_url(lat: float, lon: float) -> String:
	var b := latlon_box(lat, lon)
	return "%s?bbox=%.5f,%.5f,%.5f,%.5f&limit=100" % [STAC_URL, b.position.x, b.position.y, b.end.x, b.end.y]

## Runs `work` on a worker thread and returns its result, a frame at a time.
func _in_thread(work: Callable) -> Variant:
	var box := [null]
	var task := WorkerThreadPool.add_task(func() -> void: box[0] = work.call(), false, "GroundModel")
	_tasks.append(task)
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	_tasks.erase(task)
	return box[0]

## Tasks still running; they must not outlive the node.
var _tasks: Array[int] = []

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for task in _tasks:
			WorkerThreadPool.wait_for_task_completion(task)
		_tasks.clear()

static func _bil_raster(bytes: PackedByteArray, w: Dictionary) -> Dictionary:
	if w.is_empty():
		return {}
	var c: Vector2 = w["c"]
	var h: float = w["half"]
	return GroundModel.decode_bil(bytes, GroundModel.CELLS, Vector2(c.x - h, c.y + h),
		2.0 * h / float(GroundModel.CELLS))

func _save_raster(path: String, raster: Dictionary) -> void:
	var bytes := PackedByteArray()
	var v: PackedFloat32Array = raster["values"]
	bytes.resize(v.size() * 4)
	for i in v.size():
		bytes.encode_float(i * 4, v[i])
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(bytes)
		f.close()
		CacheStore.note_written(path)

## swissALTI3D: the 2 m tiles covering the window (the STAC API names
## them), decoded and mosaicked in LV95, resampled to Mercator and cached
## in that form (the tiles are a megabyte each, so they are not kept).
func _swiss(lat: float, lon: float, offline: bool) -> Dictionary:
	var win := window(lat, lon)
	var cache := cache_path("swisstopo", lat, lon, "bil")
	if FileAccess.file_exists(cache):
		var bytes := FileAccess.get_file_as_bytes(cache)
		if _is_bil(bytes):
			CacheStore.note_read(cache)
			return _bil_raster(bytes, win)
	if offline:
		return {}
	var listing := await _get_many([{"url": stac_url(lat, lon), "path": ""}], false, _is_json)
	var hrefs := swiss_tile_hrefs(listing[0])
	if hrefs.is_empty():
		return {}
	var jobs: Array = []
	for href in hrefs:
		jobs.append({"url": href, "path": ""})
	var tiles := await _get_many(jobs, false, _is_tiff)
	var raster: Dictionary = await _in_thread(func() -> Dictionary:
		var rasters: Array = []
		for blob in tiles:
			var r := GroundTiff.decode(blob, true)
			if not r.is_empty():
				rasters.append(r)
		var mosaic := mosaic_rasters(rasters)
		if mosaic.is_empty():
			return {}
		return GroundModel.reproject(mosaic, NationalGrids.lv95, win))
	if not raster.is_empty() and GroundModel.missing_share(raster) <= GroundModel.MAX_MISSING:
		_save_raster(cache, raster)
	return raster

## The 2 m GeoTIFF links of a STAC listing, the newest survey of each tile.
static func swiss_tile_hrefs(listing: PackedByteArray) -> PackedStringArray:
	var json: Variant = JSON.parse_string(listing.get_string_from_utf8())
	if not (json is Dictionary) or not (json as Dictionary).has("features"):
		return PackedStringArray()
	var best := {}  # tile key (id without its year) -> [year, href]
	for f in (json as Dictionary)["features"]:
		var id := str(f.get("id", ""))
		var parts := id.split("_")
		if parts.size() != 3:
			continue
		var href := ""
		for asset in (f.get("assets", {}) as Dictionary).values():
			var url := str(asset.get("href", ""))
			if url.ends_with(".tif") and url.contains("_2_2056"):
				href = url
		if href.is_empty() or not url_allowed(href):
			continue
		var year := int(parts[1])
		if not best.has(parts[2]) or year > int(best[parts[2]][0]):
			best[parts[2]] = [year, href]
	var out := PackedStringArray()
	for key in best:
		out.append(str(best[key][1]))
	return out

static func url_allowed(url: String) -> bool:
	return url.begins_with("https://data.geo.admin.ch/") and not HostPolicy.is_blocked(url)

## One raster from equally spaced rasters (tiles of one grid), NAN where
## no tile reaches.
static func mosaic_rasters(rasters: Array) -> Dictionary:
	if rasters.is_empty():
		return {}
	var cell: Vector2 = rasters[0]["cell"]
	var lo := Vector2(INF, -INF)
	var hi := Vector2(-INF, INF)
	for r in rasters:
		var o: Vector2 = r["origin"]
		var s: Vector2i = r["size"]
		if not (r["cell"] as Vector2).is_equal_approx(cell):
			return {}
		lo.x = minf(lo.x, o.x)
		lo.y = maxf(lo.y, o.y)
		hi.x = maxf(hi.x, o.x + float(s.x) * cell.x)
		hi.y = minf(hi.y, o.y - float(s.y) * cell.y)
	var width := roundi((hi.x - lo.x) / cell.x)
	var height := roundi((lo.y - hi.y) / cell.y)
	if width * height > 16000000:
		return {}
	var values := PackedFloat32Array()
	values.resize(width * height)
	values.fill(NAN)
	for r in rasters:
		var o: Vector2 = r["origin"]
		var s: Vector2i = r["size"]
		var src: PackedFloat32Array = r["values"]
		var x0 := roundi((o.x - lo.x) / cell.x)
		var y0 := roundi((lo.y - o.y) / cell.y)
		for row in s.y:
			for col in s.x:
				values[(y0 + row) * width + x0 + col] = GroundModel.valid_height(src[row * s.x + col])
	return {"size": Vector2i(width, height), "values": values, "origin": lo, "cell": cell}

## One raster from the GSI z15 tiles covering the window.
func _gsi(lat: float, lon: float, offline: bool) -> Dictionary:
	var w := window(lat, lon)
	var c: Vector2 = w["c"]
	var h: float = w["half"]
	var span := 2.0 * PI * GroundModel.MERC_R / float(1 << GSI_ZOOM)
	var edge := PI * GroundModel.MERC_R
	var x0 := floori((c.x - h + edge) / span)
	var x1 := floori((c.x + h + edge) / span)
	var y0 := floori((edge - (c.y + h)) / span)
	var y1 := floori((edge - (c.y - h)) / span)
	var nx := x1 - x0 + 1
	var ny := y1 - y0 + 1
	var jobs: Array = []
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			jobs.append({"url": "%s/dem5a_png/%d/%d/%d.png" % [GSI_URL, GSI_ZOOM, tx, ty],
				"path": gsi_tile_path("gsi5a", GSI_ZOOM, tx, ty)})
	var tiles := await _get_many(jobs, offline, _is_png)
	var width := nx * 256
	var values := PackedFloat32Array()
	values.resize(width * ny * 256)
	values.fill(NAN)
	var coarse := {}  # parent tile -> true, for the tiles that need the 10 m model
	var have := 0
	for k in tiles.size():
		var tx := x0 + k % nx
		@warning_ignore("integer_division")
		var ty := y0 + k / nx
		var px := GroundModel.decode_gsi_png(tiles[k])
		var missing := 256 * 256
		if not px.is_empty():
			have += 1
			missing = 0
			for row in 256:
				var dst := ((ty - y0) * 256 + row) * width + (tx - x0) * 256
				for col in 256:
					values[dst + col] = px[row * 256 + col]
					if is_nan(px[row * 256 + col]):
						missing += 1
		if float(missing) > GSI_PATCH_SHARE * 65536.0:
			coarse[Vector2i(tx >> 1, ty >> 1)] = true
	if not coarse.is_empty():
		_patch_coarse(await _coarse_tiles(coarse.keys(), offline), values, width, x0, y0, nx, ny)
		have += 1
	if have == 0:
		return {}
	return {"size": Vector2i(width, ny * 256), "values": values,
		"origin": Vector2(-edge + float(x0) * span, edge - float(y0) * span),
		"cell": Vector2(span / 256.0, span / 256.0)}

## DEM10B z14 tiles for the given parent tiles: {Vector2i: PackedFloat32Array}.
func _coarse_tiles(parents: Array, offline: bool) -> Dictionary:
	var jobs: Array = []
	for p in parents:
		jobs.append({"url": "%s/dem_png/%d/%d/%d.png" % [GSI_URL, GSI_FALLBACK_ZOOM, p.x, p.y],
			"path": gsi_tile_path("gsi10", GSI_FALLBACK_ZOOM, p.x, p.y)})
	var got := await _get_many(jobs, offline, _is_png)
	var out := {}
	for k in parents.size():
		var px := GroundModel.decode_gsi_png(got[k])
		if not px.is_empty():
			out[parents[k]] = px
	return out

## Fills the mosaic's missing cells from the 10 m parent tiles (one 10 m
## cell covers 2 × 2 of the 5 m ones).
@warning_ignore("integer_division")
static func _patch_coarse(coarse: Dictionary, values: PackedFloat32Array, width: int,
		x0: int, y0: int, nx: int, ny: int) -> void:
	for ty in range(y0, y0 + ny):
		for tx in range(x0, x0 + nx):
			var parent := Vector2i(tx >> 1, ty >> 1)
			if not coarse.has(parent):
				continue
			var px: PackedFloat32Array = coarse[parent]
			for row in 256:
				var dst := ((ty - y0) * 256 + row) * width + (tx - x0) * 256
				var src_row := ((ty & 1) * 256 + row) / 2
				for col in 256:
					if is_nan(values[dst + col]):
						values[dst + col] = px[src_row * 256 + ((tx & 1) * 256 + col) / 2]

static func _is_bil(b: PackedByteArray) -> bool:
	return b.size() == GroundModel.CELLS * GroundModel.CELLS * 4

static func _is_tiff(b: PackedByteArray) -> bool:
	return b.size() > 16 and (b[0] == 0x49 or b[0] == 0x4D) and b[0] == b[1]

static func _is_json(b: PackedByteArray) -> bool:
	return b.size() > 2 and b[0] == 0x7B

static func _is_png(b: PackedByteArray) -> bool:
	return b.size() > 8 and b[0] == 0x89 and b[1] == 0x50 and b[2] == 0x4E and b[3] == 0x47

## The bytes of each job ({url, path}), the cached file when there is one,
## else downloaded (and cached once `valid` accepts them); empty where
## unavailable. Runs BATCH requests at a time.
func _get_many(jobs: Array, offline: bool, valid: Callable) -> Array:
	var out: Array = []
	out.resize(jobs.size())
	for i in jobs.size():
		out[i] = PackedByteArray()
	var remaining := [0]
	var first := 0
	while first < jobs.size():
		var last := mini(first + BATCH, jobs.size())
		remaining[0] = 0
		for k in range(first, last):
			var path: String = jobs[k]["path"]
			if FileAccess.file_exists(path):
				var cached := FileAccess.get_file_as_bytes(path)
				if valid.call(cached):
					CacheStore.note_read(path)
					out[k] = cached
					continue
			if offline or CacheStore.is_absent(path):
				continue
			remaining[0] += 1
			_download(str(jobs[k]["url"]), path, k, out, remaining, valid)
		var waited := 0.0
		while remaining[0] > 0 and waited < TIMEOUT_S:
			await get_tree().process_frame
			waited += get_process_delta_time()
		first = last
	return out

func _download(url: String, path: String, k: int, out: Array, remaining: Array,
		valid: Callable) -> void:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_S
	add_child(http)
	var done := func(result: int, code: int, _h: PackedStringArray,
			body: PackedByteArray) -> void:
		if result == HTTPRequest.RESULT_SUCCESS and code == 200 and valid.call(body):
			out[k] = body
			var f := FileAccess.open(path, FileAccess.WRITE) if not path.is_empty() else null
			if f != null:
				f.store_buffer(body)
				f.close()
				CacheStore.note_written(path)
		elif result == HTTPRequest.RESULT_SUCCESS and code == 404:
			CacheStore.note_absent(path)
		remaining[0] -= 1
		http.queue_free()
	http.request_completed.connect(done, CONNECT_ONE_SHOT)
	if http.request(url, ["User-Agent: " + Brand.USER_AGENT]) != OK:
		remaining[0] -= 1
		http.queue_free()
