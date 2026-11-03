class_name ClimateFetcher
extends Node

## CHELSA V2.1 climatology (1981–2010, 30 arc-second ≈ 1 km; Karger et
## al., CC BY 4.0) read straight from the public object store with HTTP
## range requests — no server, key or account. Each variable is one
## global GeoTIFF (43200 × 20880, uint16, one row per deflate strip,
## horizontal predictor), so a place needs only: the first IFD (≤ 16 KB),
## three 4-byte entries of the strip offset/size tables, and three
## compressed rows (≈ 10–45 KB each). A 3 × 3 cell window around the
## viewpoint is decoded and its median kept per variable. The table
## entries and the rows go out together, so a variable is three round
## trips (the object store answers in ~2–3 s each). When CHELSA fails or
## runs over CHELSA_BUDGET_S, the same normals are worked out from
## Open-Meteo's daily ERA5 archive instead (~25 km, coarser). Results
## are cached per place (climate layer); when both fail, or offline, an
## empty Dictionary is emitted and the latitude fallbacks stay in charge.

signal finished(climate: Dictionary)

const BASE := "https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/1981-2010/bio/CHELSA_%s_1981-2010_V.2.1.tif"
const SOURCE := "CHELSA V2.1 1981–2010 (Karger et al., CC BY 4.0)"
const CREDIT := "Climate: CHELSA V2.1 (Karger et al.)"
const FALLBACK_URL := "https://archive-api.open-meteo.com/v1/archive?latitude=%.4f&longitude=%.4f&start_date=2001-01-01&end_date=2010-12-31&daily=temperature_2m_mean,precipitation_sum&timezone=GMT"
const FALLBACK_SOURCE := "ERA5 2001–2010 via Open-Meteo (Copernicus, CC BY 4.0)"
const FALLBACK_CREDIT := "Climate: ERA5 (Copernicus) via Open-Meteo"
const USER_AGENT := Brand.USER_AGENT
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
## CHELSA's share of the pipeline's climate wait; the ERA5 fallback gets
## the rest (Pipeline.CLIMATE_WAIT_S).
const CHELSA_BUDGET_S := 14.0
const FALLBACK_TIMEOUT_S := 10.0

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
	get_tree().create_timer(CHELSA_BUDGET_S).timeout.connect(func() -> void:
		if gen == _gen and _pending > 0:
			cancel()
			_fetch_fallback())

## The credit line for a fetched climate Dictionary.
static func credit_for(climate: Dictionary) -> String:
	return FALLBACK_CREDIT if climate.get("source", "") == FALLBACK_SOURCE else CREDIT

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
	var so := int(ifd["strip_offsets"]) + 4 * r0
	var sb := int(ifd["strip_bytes"]) + 4 * r0
	var tables := await _ranges(url, [[so, so + 11], [sb, sb + 11]], gen)
	var offs: PackedByteArray = tables[0]
	var sizes: PackedByteArray = tables[1]
	if offs.size() != 12 or sizes.size() != 12:
		_done(v, NAN, gen)
		return
	var spans := []
	for k in 3:
		var o := offs.decode_u32(4 * k)
		spans.append([o, o + sizes.decode_u32(4 * k) - 1])
	var strips := await _ranges(url, spans, gen)
	var cells: Array[float] = []
	var row: Array = VARS[v]
	for k in 3:
		var raw := decode_row(strips[k], cell.x - 1, 3, int(ifd["predictor"]))
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
	if _values.size() != VARS.size():
		_fetch_fallback()
		return
	var out := _values.duplicate()
	out["source"] = SOURCE
	_store(out)
	timings = {"ms": Time.get_ticks_msec() - _t0, "cached": false, "vars": _values.size()}
	_gen += 1
	finished.emit(out)

## ERA5 normals from Open-Meteo when CHELSA failed or ran over budget.
func _fetch_fallback() -> void:
	var gen := _gen
	var http := HTTPRequest.new()
	http.timeout = FALLBACK_TIMEOUT_S
	add_child(http)
	var out := {}
	if http.request(FALLBACK_URL % [_lat, _lon], ["User-Agent: " + USER_AGENT, "Accept: application/json"]) == OK:
		var res: Array = await http.request_completed
		if gen != _gen:
			return
		if int(res[0]) == HTTPRequest.RESULT_SUCCESS and int(res[1]) == 200:
			out = normals_from_daily(JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8()))
	http.queue_free()
	if not out.is_empty():
		out["source"] = FALLBACK_SOURCE
		_store(out)
	timings = {"ms": Time.get_ticks_msec() - _t0, "cached": false, "vars": _values.size(),
		"fallback": not out.is_empty()}
	_gen += 1
	finished.emit(out)

func _store(out: Dictionary) -> void:
	var f := FileAccess.open(cache_path(_lat, _lon), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out))
		f.close()
		CacheStore.note_written(cache_path(_lat, _lon))

## CHELSA's variables from an Open-Meteo daily archive response: the
## warmest / coldest 3-month means of the monthly temperatures, annual
## and warmest-quarter precipitation, and snow days estimated as days
## with a mean at or below freezing. {} when the response is unusable.
static func normals_from_daily(parsed: Variant) -> Dictionary:
	if not (parsed is Dictionary and (parsed as Dictionary).get("daily") is Dictionary):
		return {}
	var daily: Dictionary = parsed["daily"]
	var days: Array = daily.get("time", [])
	var temps: Array = daily.get("temperature_2m_mean", [])
	var precs: Array = daily.get("precipitation_sum", [])
	if days.is_empty() or temps.size() != days.size() or precs.size() != days.size():
		return {}
	var t_sum := PackedFloat64Array()
	var t_n := PackedInt32Array()
	var p_sum := PackedFloat64Array()
	t_sum.resize(12)
	t_n.resize(12)
	p_sum.resize(12)
	var years := {}
	var frost := 0
	for i in days.size():
		var day := str(days[i])
		var m := int(day.substr(5, 2)) - 1
		if m < 0 or m > 11:
			continue
		years[day.left(4)] = true
		if temps[i] != null:
			t_sum[m] += float(temps[i])
			t_n[m] += 1
			if float(temps[i]) <= 0.0:
				frost += 1
		if precs[i] != null:
			p_sum[m] += float(precs[i])
	for m in 12:
		if t_n[m] == 0:
			return {}
	var n_years := float(years.size())
	var warm := 0
	var cold := 0
	var q_t := PackedFloat64Array()
	q_t.resize(12)
	for m in 12:
		for k in 3:
			q_t[m] += t_sum[(m + k) % 12] / t_n[(m + k) % 12] / 3.0
		if q_t[m] > q_t[warm]:
			warm = m
		if q_t[m] < q_t[cold]:
			cold = m
	var monthly: Array = []
	for m in 12:
		monthly.append(t_sum[m] / t_n[m])
	var precip := 0.0
	for m in 12:
		precip += p_sum[m]
	return {
		"t_monthly_c": monthly,
		"t_warm_c": q_t[warm],
		"t_cold_c": q_t[cold],
		"precip_mm": precip / n_years,
		"precip_warm_mm": (p_sum[warm] + p_sum[(warm + 1) % 12] + p_sum[(warm + 2) % 12]) / n_years,
		"snow_days": frost / n_years,
	}

## Byte ranges [[a, b], …] of `url`, requested together; each entry
## is empty on failure, and all are once superseded.
func _ranges(url: String, spans: Array, gen: int) -> Array:
	var out := []
	out.resize(spans.size())
	out.fill(PackedByteArray())
	var left := [spans.size()]
	for i in spans.size():
		var span: Array = spans[i]
		(func() -> void:
			out[i] = await _range(url, int(span[0]), int(span[1]), gen)
			left[0] -= 1).call()
	while left[0] > 0 and gen == _gen:
		await get_tree().process_frame
	return out

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
