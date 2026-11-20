class_name HelsinkiLod2
extends RefCounted

## Measured heights and roof forms from the City of Helsinki's LoD2
## building model (3D city model, CC BY 4.0), reduced offline by
## tools/prepare_helsinki_lod2.py into 1 km GK25 cells bundled under
## assets/city_models/helsinki_lod2/ (zstd JSON, size + SHA-256 pinned in
## its manifest, as BundledOsm pins its snapshots), and Espoo's (city
## model, CC BY 4.0) by tools/prepare_espoo_lod2.py under espoo_lod2/,
## Each row is one building: [vtj_prt, e, n, area_m2, height_m, roof_h_m,
## pitch_deg, ridge_az_deg, shape, storeys] plus optional [start_year,
## use_code] (Turku's CityGML bundle).
##
## `apply` joins rows to OSM footprints (FootprintMatcher) before the
## register runs: a measured height replaces an estimated one (default,
## estimate or storeys × 3.2 m) and the roof's shape and pitch fill what
## the map leaves out; the footprint sets the roof's rise and ridge. A
## mapped `height` or roof tag always wins. Every preset (data only).

const DIRECTORY := "res://assets/city_models/helsinki_lod2/"
const MANIFEST := DIRECTORY + "manifest.json"
const CREDIT := "Building heights and roofs: © City of Helsinki, 3D city model (CC BY 4.0)"
## The bundles: key prefix → [directory, credit].
const BUNDLES := {
	"": [DIRECTORY, CREDIT],
	"espoo:": ["res://assets/city_models/espoo_lod2/",
		"Building heights and roofs: © City of Espoo, city model (CC BY 4.0)"],
	"turku:": ["res://assets/city_models/turku_lod2/",
		"Building heights and roofs: © City of Turku, 3D city model (CC BY 4.0)"],
}
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
		for prefix in BUNDLES:
			var f := FileAccess.open(str(BUNDLES[prefix][0]) + "manifest.json", FileAccess.READ)
			if f == null:
				continue
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and (parsed as Dictionary).get("cells") is Dictionary:
				var cells: Dictionary = (parsed as Dictionary)["cells"]
				for key in cells:
					_manifest[str(prefix) + str(key)] = cells[key]
	var cells := _manifest
	_lock.unlock()
	return cells

## Whether bundled cells cover any of the window round (lat, lon).
static func covers(lat: float, lon: float) -> bool:
	return not cell_keys(lat, lon).is_empty()

## Bundled cell keys ("<prefix><E km>_<N km>") meeting the window.
static func cell_keys(lat: float, lon: float) -> Array:
	var cells := _cells()
	var keys: Array = []
	if lat >= 60.0 and lat <= 60.4 and lon >= 24.5 and lon <= 25.3:
		var c := Gk25.forward(lat, lon)
		for ek in range(floori((c[0] - HALF_M) / 1000.0), floori((c[0] + HALF_M) / 1000.0) + 1):
			for nk in range(floori((c[1] - HALF_M) / 1000.0), floori((c[1] + HALF_M) / 1000.0) + 1):
				for prefix in ["", "espoo:"]:
					var key := "%s%d_%d" % [prefix, ek, nk]
					if cells.has(key):
						keys.append(key)
	elif lat >= 60.34 and lat <= 60.62 and lon >= 22.05 and lon <= 22.52:
		var c := Gk23.forward(lat, lon)
		for ek in range(floori((c[0] - HALF_M) / 1000.0), floori((c[0] + HALF_M) / 1000.0) + 1):
			for nk in range(floori((c[1] - HALF_M) / 1000.0), floori((c[1] + HALF_M) / 1000.0) + 1):
				var key := "turku:%d_%d" % [ek, nk]
				if cells.has(key):
					keys.append(key)
	return keys

## The credits of the bundles whose cells meet the window.
static func credits_for(lat: float, lon: float) -> Array:
	var out: Array = []
	for key: String in cell_keys(lat, lon):
		var credit := str(BUNDLES[_prefix(key)][1])
		if not out.has(credit):
			out.append(credit)
	return out

static func _prefix(key: String) -> String:
	var i := key.find(":")
	return key.substr(0, i + 1) if i >= 0 else ""

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
	var prefix := _prefix(key)
	var f := FileAccess.open(str(BUNDLES[prefix][0]) + key.substr(prefix.length()) + ".lod2", FileAccess.READ)
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
	var gk23 := not kept.is_empty() and float((kept[0] as Array)[1]) < 24500000.0
	var hits := FootprintMatcher.match(buildings, c_lat, c_lon, kept, gk23)
	for i in hits:
		stats["matched"] = int(stats["matched"]) + (hits[i] as Array).size()
		if not _enrich(buildings[i], hits[i]).is_empty():
			stats["filled"] = int(stats["filled"]) + 1
	return stats

## A measured ridge this far off the footprint's long side turns the
## roof; nearer, the footprint's own axis (and the native roof batch)
## stands (degrees).
const OFF_AXIS_DEG := 25.0

## The roof:direction (compass bearing the slope faces) LoD2's ridge or
## fall bearing `az` gives `b` (local metres, z south): a skillion that
## falls the other way from its footprint's default, or a ridge clearly
## across the footprint's long side on a parcel-like ring; -1 to keep the
## footprint's axis (most roofs: they stay in the native batch).
static func roof_dir(b: Dictionary, shape: String, az: float) -> float:
	if float(b.get("roof_dir", -1.0)) >= 0.0 or str(b.get("roof_orient", "")) != "":
		return -1.0
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if ring.size() < 3:
		return -1.0
	var u := RingGeometry.dominant_axis(ring)
	var bearing := Vector2(sin(deg_to_rad(az)), -cos(deg_to_rad(az)))
	if shape == "skillion":
		# The default rises along (-u.y, u.x): it falls toward (u.y, -u.x).
		return fposmod(az, 360.0) if bearing.dot(Vector2(u.y, -u.x)) < 0.7 else -1.0
	if not shape in ["gabled", "hipped", "mansard"] or not RoofForms.boxy(ring):
		return -1.0
	var off := rad_to_deg(acos(clampf(absf(bearing.dot(u)), 0.0, 1.0)))
	return fposmod(az + 90.0, 360.0) if off > OFF_AXIS_DEG else -1.0

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
	if main.size() >= 11:
		var year := int(main[10])
		if year >= 1700 and year <= 2100:
			values["start_year"] = year
	fields.append_array(BuildingReferences.fill(b, values))
	if main.size() >= 12:
		var kind := RegisterCodes.kind_for(str(main[11]), "")
		if kind != "" and str(b.get("kind", "yes")) in ["yes", "residential", "building"]:
			b["kind"] = kind
			fields.append("kind")
	var dir := roof_dir(b, str(b.get("roof_shape", "")), float(main[7])) if rows.size() == 1 else -1.0
	if dir >= 0.0:
		b["roof_dir"] = dir
		fields.append("roof_dir")
	if not fields.is_empty():
		var enriched: Dictionary = b.get("enriched", {})
		enriched[PROVENANCE] = fields
		b["enriched"] = enriched
	return fields
