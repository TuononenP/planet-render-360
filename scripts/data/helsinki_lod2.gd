class_name HelsinkiLod2
extends RefCounted

## Measured heights and roof forms from the City of Helsinki's LoD2
## building model (3D city model, CC BY 4.0), reduced offline by
## tools/prepare_helsinki_lod2.py into 1 km GK25 cells bundled under
## assets/city_models/helsinki_lod2/ (zstd JSON, size + SHA-256 pinned in
## its manifest, as BundledOsm pins its snapshots). Each row is one
## building: [vtj_prt, e, n, area_m2, height_m, roof_h_m, pitch_deg,
## ridge_az_deg, shape, storeys].
##
## `apply` joins rows to OSM footprints (FootprintMatcher) before the
## register runs: a measured height replaces an estimated one (default,
## estimate or storeys × 3.2 m) and the roof's shape and pitch fill what
## the map leaves out; the footprint sets the roof's rise and ridge. A
## mapped `height` or roof tag always wins. Every preset (data only).

const DIRECTORY := "res://assets/city_models/helsinki_lod2/"
const MANIFEST := DIRECTORY + "manifest.json"
const CREDIT := "Building heights and roofs: © City of Helsinki, 3D city model (CC BY 4.0)"
const PROVENANCE := "hel_lod2"
## The window read round a viewpoint (HelsinkiRegister's).
const HALF_M := 1450.0
const SHAPES := ["flat", "gabled", "hipped", "skillion", "mansard"]
## Smaller records are kiosks, canopies and roof clutter, not buildings.
const MIN_AREA_M2 := 10.0
const MIN_HEIGHT_M := 2.0
## Height sources a measured height replaces.
const ESTIMATED := ["default", "estimate", "levels"]

static var _manifest: Dictionary = {}
## Decoded cells by key: a streamed world reads the same cells again.
## Merges run on worker threads (CityOpenData.merge), two at once while
## streaming: the caches are shared under one lock.
static var _decoded: Dictionary = {}
static var _lock := Mutex.new()

static func _cells() -> Dictionary:
	_lock.lock()
	if _manifest.is_empty():
		var f := FileAccess.open(MANIFEST, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and (parsed as Dictionary).get("cells") is Dictionary:
				_manifest = (parsed as Dictionary)["cells"]
	var cells := _manifest
	_lock.unlock()
	return cells

## Whether bundled cells cover any of the window round (lat, lon).
static func covers(lat: float, lon: float) -> bool:
	return not cell_keys(lat, lon).is_empty()

## Bundled cell keys ("<E km>_<N km>") meeting the window.
static func cell_keys(lat: float, lon: float) -> Array:
	if lat < 60.0 or lat > 60.4 or lon < 24.5 or lon > 25.3:
		return []
	var cells := _cells()
	var c := Gk25.forward(lat, lon)
	var keys: Array = []
	for ek in range(floori((c[0] - HALF_M) / 1000.0), floori((c[0] + HALF_M) / 1000.0) + 1):
		for nk in range(floori((c[1] - HALF_M) / 1000.0), floori((c[1] + HALF_M) / 1000.0) + 1):
			var key := "%d_%d" % [ek, nk]
			if cells.has(key):
				keys.append(key)
	return keys

## The rows of every bundled cell meeting the window; cells that fail
## their size or hash check are skipped.
static func rows_for(lat: float, lon: float) -> Array:
	var rows: Array = []
	for key in cell_keys(lat, lon):
		_lock.lock()
		var cached: Variant = _decoded.get(key)
		_lock.unlock()
		if cached == null:
			cached = read_cell(key)
			_lock.lock()
			_decoded[key] = cached
			_lock.unlock()
		rows.append_array(cached)
	return rows

static func read_cell(key: String) -> Array:
	var entry: Variant = _cells().get(key)
	if not (entry is Array) or (entry as Array).size() < 2:
		return []
	var f := FileAccess.open(DIRECTORY + key + ".lod2", FileAccess.READ)
	if f == null:
		return []
	var size := int(entry[0])
	var payload := f.get_buffer(f.get_length()).decompress(size, FileAccess.COMPRESSION_ZSTD)
	if payload.size() != size:
		return []
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(payload)
	if hash.finish().hex_encode() != str(entry[1]):
		return []
	var parsed: Variant = JSON.parse_string(payload.get_string_from_utf8())
	if not (parsed is Dictionary) or not ((parsed as Dictionary).get("rows") is Array):
		return []
	return (parsed as Dictionary)["rows"]

## Fills `buildings` (local metre footprints round c_lat, c_lon) from LoD2
## `rows`, in place. Returns {rows, matched, filled}.
static func apply(buildings: Array, c_lat: float, c_lon: float, rows: Array) -> Dictionary:
	var kept := rows.filter(func(r: Variant) -> bool:
		return r is Array and (r as Array).size() >= 10 and float(r[3]) >= MIN_AREA_M2 and float(r[4]) >= MIN_HEIGHT_M)
	var stats := {"rows": rows.size(), "matched": 0, "filled": 0}
	var hits := FootprintMatcher.match(buildings, c_lat, c_lon, kept)
	for i in hits:
		stats["matched"] = int(stats["matched"]) + (hits[i] as Array).size()
		if not _enrich(buildings[i], hits[i]).is_empty():
			stats["filled"] = int(stats["filled"]) + 1
	return stats

## One building from its rows (an OSM outline can hold several city
## buildings, or one building's wings): the tallest height, the roof of
## the largest. Returns the filled keys.
static func _enrich(b: Dictionary, rows: Array) -> Array:
	var tallest := 0.0
	var main: Array = rows[0]
	for r in rows:
		tallest = maxf(tallest, float(r[4]))
		if float(r[3]) > float(main[3]):
			main = r
	var fields: Array = []
	if str(b.get("height_source", "")) in ESTIMATED:
		b["height"] = tallest
		b["height_source"] = "tag_height"
		b["lod2"] = true
		fields.append("height")
	var values := {}
	var shape := str(main[8])
	if shape in SHAPES:
		values["roof_shape"] = shape
		var pitch := float(main[6])
		if shape != "flat" and pitch >= 5.0 and pitch <= 70.0:
			values["roof_angle"] = snappedf(pitch, 0.5)
	if int(main[9]) > 0:
		values["levels"] = float(int(main[9]))
	fields.append_array(BuildingReferences.fill(b, values))
	if not fields.is_empty():
		var enriched: Dictionary = b.get("enriched", {})
		enriched[PROVENANCE] = fields
		b["enriched"] = enriched
	return fields
