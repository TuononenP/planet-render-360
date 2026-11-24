class_name TurkuLod2Meshes
extends RefCounted

## Multi-city true-3D LoD2 building mesh bundles (Helsinki, Espoo, Turku),
## stored as compact zstd-compressed binary PackedInt32Array (.lod2m v2) 1 km
## grid cells with uncompressed size + SHA-256 pinned in manifest.json.
##
## Binary v2 layout (little-endian int32 stream):
##   Header (3 ints): [MAGIC (0x324D444C), VERSION (2), building_count]
##   Per building (14 ints fixed + geometry):
##     [0] e_dm, [1] n_dm, [2] area_dm2, [3] h_cm, [4] storeys, [5] start_year,
##     [6] roof_mat_id, [7] roof_rgb, [8] wall_mat_id, [9] wall_rgb,
##     [10] n_wall_verts, [11] n_wall_idx, [12] n_roof_verts, [13] n_roof_idx,
##     followed by wv (3*nwv), wu (2*nwv), wi (nwi), rv (3*nrv), ru (2*nrv), ri (nri).

const MAGIC := 0x324D444C
const VERSION := 2
const HEADER_INTS := 3
const BLDG_HEADER_INTS := 14
const HALF_M := 1450.0

## Key prefix -> [directory, credit, is_gk23].
const BUNDLES := {
	"": ["res://assets/city_models/helsinki_lod2_meshes/",
		"3D building meshes: © City of Helsinki & HSY (CC BY 4.0); facade samples: Mapillary contributors (CC BY-SA 4.0)", false],
	"espoo:": ["res://assets/city_models/espoo_lod2_meshes/",
		"3D building meshes: © City of Espoo & HSY (CC BY 4.0); facade samples: Mapillary contributors (CC BY-SA 4.0)", false],
	"turku:": ["res://assets/city_models/turku_lod2_meshes/",
		"3D building meshes: © City of Turku (CC BY 4.0); facade samples: Mapillary & Panoramax contributors (CC BY-SA 4.0)", true],
	"amsterdam:": ["res://assets/city_models/amsterdam_lod2_meshes/",
		"3D building meshes: © 3DBAG by TU Delft & 3DGI (CC BY 4.0); roof samples: PDOK Luchtfoto (CC BY 4.0)", false],
}

const ROOF_MATS: Array[String] = ["", "metal", "terracotta", "copper", "bitumen"]
const WALL_MATS: Array[String] = ["", "render", "brick", "concrete", "wood", "stone", "glass"]
const MAX_CACHED_CELLS := 64

static var _manifest: Dictionary = {}
static var _decoded: Dictionary = {}
static var _decoded_order: Array[String] = []
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

static func covers(lat: float, lon: float) -> bool:
	return not cell_keys(lat, lon).is_empty()

static func is_gk23(lat: float, lon: float) -> bool:
	return lat >= 60.34 and lat <= 60.62 and lon >= 22.05 and lon <= 22.52

static func is_rd_new(lat: float, lon: float) -> bool:
	return lat >= 52.28 and lat <= 52.45 and lon >= 4.74 and lon <= 5.04

static func cell_keys(lat: float, lon: float) -> Array:
	var cells := _cells()
	if cells.is_empty():
		return []
	var keys: Array = []
	if lat >= 60.0 and lat <= 60.4 and lon >= 24.5 and lon <= 25.3:
		var c := Gk25.forward(lat, lon)
		for ek in range(floori((c[0] - HALF_M) / 1000.0), floori((c[0] + HALF_M) / 1000.0) + 1):
			for nk in range(floori((c[1] - HALF_M) / 1000.0), floori((c[1] + HALF_M) / 1000.0) + 1):
				for prefix in ["", "espoo:"]:
					var key := "%s%d_%d" % [prefix, ek, nk]
					if cells.has(key):
						keys.append(key)
	elif is_gk23(lat, lon):
		var c := Gk23.forward(lat, lon)
		for ek in range(floori((c[0] - HALF_M) / 1000.0), floori((c[0] + HALF_M) / 1000.0) + 1):
			for nk in range(floori((c[1] - HALF_M) / 1000.0), floori((c[1] + HALF_M) / 1000.0) + 1):
				var key := "turku:%d_%d" % [ek, nk]
				if cells.has(key):
					keys.append(key)
	elif is_rd_new(lat, lon):
		var c := RdNew.forward(lat, lon)
		for ek in range(floori((c[0] - HALF_M) / 1000.0), floori((c[0] + HALF_M) / 1000.0) + 1):
			for nk in range(floori((c[1] - HALF_M) / 1000.0), floori((c[1] + HALF_M) / 1000.0) + 1):
				var key := "amsterdam:%d_%d" % [ek, nk]
				if cells.has(key):
					keys.append(key)
	return keys

static func _prefix(key: String) -> String:
	var i := key.find(":")
	return key.substr(0, i + 1) if i >= 0 else ""

## The credits of the bundles whose cells meet the window.
static func credits_for(lat: float, lon: float) -> Array:
	var out: Array = []
	for key: String in cell_keys(lat, lon):
		var credit := str(BUNDLES[_prefix(key)][1])
		if not out.has(credit):
			out.append(credit)
	return out

## Returns Array[PackedInt32Array] of binary v2 cell buffers for the window.
static func cells_for(lat: float, lon: float) -> Array[PackedInt32Array]:
	var out: Array[PackedInt32Array] = []
	for key: String in cell_keys(lat, lon):
		_lock.lock()
		var cached: Variant = _decoded.get(key)
		_lock.unlock()
		if cached == null:
			cached = read_cell(key)
			_lock.lock()
			if not _decoded.has(key):
				if _decoded_order.size() >= MAX_CACHED_CELLS:
					_decoded.erase(_decoded_order.pop_front())
				_decoded_order.append(key)
			_decoded[key] = cached
			_lock.unlock()
		var arr := cached as PackedInt32Array
		if arr.size() >= HEADER_INTS:
			out.append(arr)
	return out

static func read_cell(key: String) -> PackedInt32Array:
	var entry: Variant = _cells().get(key)
	if not (entry is Array) or (entry as Array).size() < 2:
		return PackedInt32Array()
	var prefix := _prefix(key)
	var f := FileAccess.open(str(BUNDLES[prefix][0]) + key.substr(prefix.length()) + ".lod2m", FileAccess.READ)
	if f == null:
		return PackedInt32Array()
	var size := int(entry[0])
	var payload := f.get_buffer(f.get_length()).decompress(size, FileAccess.COMPRESSION_ZSTD)
	if payload.size() != size:
		return PackedInt32Array()
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(payload)
	if hash.finish().hex_encode() != str(entry[1]):
		return PackedInt32Array()
	var ints := payload.to_int32_array()
	if ints.size() < HEADER_INTS or ints[0] != MAGIC or ints[1] != VERSION:
		return PackedInt32Array()
	return ints

static func hex_rgb(rgb: int) -> String:
	if rgb <= 0:
		return ""
	return "#%06x" % (rgb & 0xFFFFFF)

static func roof_mat_name(id: int) -> String:
	return ROOF_MATS[id] if id >= 0 and id < ROOF_MATS.size() else ""

static func wall_mat_name(id: int) -> String:
	return WALL_MATS[id] if id >= 0 and id < WALL_MATS.size() else ""
