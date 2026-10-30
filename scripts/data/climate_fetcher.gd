class_name ClimateFetcher
extends Node

## CHELSA V2.1 climatology (1981–2010, 30 arc-second ≈ 1 km; Karger et
## al., CC BY 4.0) read straight from the public object store with HTTP
## range requests — no server, key or account. Each variable is one
## global GeoTIFF (43200 × 20880, uint16, one row per deflate strip,
## horizontal predictor), so a place needs only: the first IFD (≤ 16 KB),
## three 4-byte entries of the strip offset/size tables, and three
## compressed rows (≈ 10–45 KB each). A 3 × 3 cell window around the
## viewpoint is decoded and its median kept per variable. Results are
## cached per place (climate layer); a failed or offline fetch emits an
## empty Dictionary and the latitude fallbacks stay in charge.

signal finished(climate: Dictionary)

const BASE := "https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/1981-2010/bio/CHELSA_%s_1981-2010_V.2.1.tif"
const SOURCE := "CHELSA V2.1 1981–2010 (Karger et al., CC BY 4.0)"
const USER_AGENT := "PlanetRender360/0.1"
## Fixed CHELSA 30" grid (identical in every bio file).
const WIDTH := 43200
const HEIGHT := 20880
const ORIGIN_LON := -180.00013888885
const ORIGIN_LAT := 83.99986041515
const STEP_DEG := 0.0083333333
## var → [result key, scale, offset, valid raw max].
const VARS := {
	"bio10": ["t_warm_c", 0.1, -273.15, 4000],   # mean temperature, warmest quarter
	"bio11": ["t_cold_c", 0.1, -273.15, 4000],   # mean temperature, coldest quarter
	"bio12": ["precip_mm", 0.1, 0.0, 60000],     # annual precipitation
	"bio18": ["precip_warm_mm", 0.1, 0.0, 60000],  # precipitation, warmest quarter
	"scd": ["snow_days", 1.0, 0.0, 366],         # snow cover days
}
const TIMEOUT_S := 20.0

var offline_mode := false
## {ms, cached, vars} of the last fetch.
var timings: Dictionary = {}

var _lat := 0.0
var _lon := 0.0
var _gen := 0
var _pending := 0
var _values := {}
var _t0 := 0

static func cache_path(lat: float, lon: float) -> String:
	return "%s/climate_v%d_%d_%d.json" % [CacheStore.base_dir(), CacheStore.DATA_VERSION,
		CacheStore.quant(lat), CacheStore.quant(lon)]

## Grid cell (column, row) holding lat/lon.
static func cell_of(lat: float, lon: float) -> Vector2i:
	return Vector2i(clampi(int(floor((lon - ORIGIN_LON) / STEP_DEG)), 1, WIDTH - 2),
		clampi(int(floor((ORIGIN_LAT - lat) / STEP_DEG)), 1, HEIGHT - 2))

func cancel() -> void:
	_gen += 1
	for c in get_children():
		if c is HTTPRequest:
			(c as HTTPRequest).cancel_request()
			c.queue_free()

func fetch(lat: float, lon: float) -> void:
	cancel()
	_lat = lat
	_lon = lon
	_t0 = Time.get_ticks_msec()
	_values = {}
	var path := cache_path(lat, lon)
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and (parsed as Dictionary).has("t_warm_c"):
			CacheStore.note_read(path)
			timings = {"ms": Time.get_ticks_msec() - _t0, "cached": true}
			finished.emit.call_deferred(parsed)
			return
	if offline_mode:
		timings = {"ms": 0, "cached": false, "error": "offline"}
		finished.emit.call_deferred({})
		return
	_pending = VARS.size()
	var gen := _gen
	for v in VARS:
		_fetch_var(str(v), gen)
	get_tree().create_timer(TIMEOUT_S).timeout.connect(func() -> void:
		if gen == _gen and _pending > 0:
			cancel()
			timings = {"ms": Time.get_ticks_msec() - _t0, "cached": false, "error": "timeout"}
			finished.emit({}))

## One variable: IFD → strip table entries → rows → median of 3 × 3.
func _fetch_var(v: String, gen: int) -> void:
	var url := BASE % v
	var head := await _range(url, 0, 16383, gen)
	var ifd := parse_ifd(head)
	if ifd.is_empty():
		_done(v, NAN, gen)
		return
	var cell := cell_of(_lat, _lon)
	var r0 := cell.y - 1
	var offs := await _range(url, int(ifd["strip_offsets"]) + 4 * r0, int(ifd["strip_offsets"]) + 4 * r0 + 11, gen)
	var sizes := await _range(url, int(ifd["strip_bytes"]) + 4 * r0, int(ifd["strip_bytes"]) + 4 * r0 + 11, gen)
	if offs.size() != 12 or sizes.size() != 12:
		_done(v, NAN, gen)
		return
	var cells: Array[float] = []
	var row: Array = VARS[v]
	for k in 3:
		var o := offs.decode_u32(4 * k)
		var n := sizes.decode_u32(4 * k)
		var strip := await _range(url, o, o + n - 1, gen)
		var raw := decode_row(strip, cell.x - 1, 3, int(ifd["predictor"]))
		for x in raw:
			if x <= int(row[3]):
				cells.append(float(x) * float(row[1]) + float(row[2]))
	cells.sort()
	_done(v, cells[cells.size() / 2] if not cells.is_empty() else NAN, gen)

func _done(v: String, value: float, gen: int) -> void:
	if gen != _gen:
		return
	if not is_nan(value):
		_values[(VARS[v] as Array)[0]] = value
	_pending -= 1
	if _pending > 0:
		return
	var out := {}
	if _values.size() == VARS.size():
		out = _values.duplicate()
		out["source"] = SOURCE
		var f := FileAccess.open(cache_path(_lat, _lon), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(out))
			f.close()
			CacheStore.note_written(cache_path(_lat, _lon))
	timings = {"ms": Time.get_ticks_msec() - _t0, "cached": false, "vars": _values.size()}
	_gen += 1
	finished.emit(out)

## Byte range [a, b] of `url`; empty on failure or when superseded.
func _range(url: String, a: int, b: int, gen: int) -> PackedByteArray:
	if gen != _gen:
		return PackedByteArray()
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_S
	add_child(http)
	if http.request(url, ["User-Agent: " + USER_AGENT, "Range: bytes=%d-%d" % [a, b]]) != OK:
		http.queue_free()
		return PackedByteArray()
	var res: Array = await http.request_completed
	http.queue_free()
	if gen != _gen or int(res[0]) != HTTPRequest.RESULT_SUCCESS or int(res[1]) != 206:
		return PackedByteArray()
	return res[3] as PackedByteArray

## The classic-TIFF first IFD fields this reader needs, or {} when the
## file is not the expected CHELSA layout (uint16, deflate, one row per
## strip, full-width grid).
static func parse_ifd(head: PackedByteArray) -> Dictionary:
	if head.size() < 16 or head[0] != 0x49 or head[1] != 0x49 or head.decode_u16(2) != 42:
		return {}
	var off := head.decode_u32(4)
	if off + 2 > head.size():
		return {}
	var n := head.decode_u16(off)
	var tags := {}
	for i in n:
		var e := off + 2 + i * 12
		if e + 12 > head.size():
			return {}
		var typ := head.decode_u16(e + 2)
		tags[head.decode_u16(e)] = head.decode_u16(e + 8) if typ == 3 else head.decode_u32(e + 8)
	if int(tags.get(256, 0)) != WIDTH or int(tags.get(257, 0)) != HEIGHT \
			or int(tags.get(258, 0)) != 16 or int(tags.get(259, 0)) != 8 \
			or int(tags.get(278, 0)) != 1 or not tags.has(273) or not tags.has(279):
		return {}
	return {"strip_offsets": tags[273], "strip_bytes": tags[279],
		"predictor": int(tags.get(317, 1))}

## `count` uint16 samples from column `col` of one deflate strip, with
## the TIFF horizontal predictor undone (running sum mod 2^16).
static func decode_row(strip: PackedByteArray, col: int, count: int, predictor: int) -> Array[int]:
	var out: Array[int] = []
	if strip.is_empty():
		return out
	var row := strip.decompress(WIDTH * 2, FileAccess.COMPRESSION_DEFLATE)
	if row.size() != WIDTH * 2:
		return out
	var acc := 0
	for i in col + count:
		var v := row.decode_u16(i * 2)
		if predictor == 2:
			acc = (acc + v) & 0xffff
			v = acc
		if i >= col:
			out.append(v)
	return out
