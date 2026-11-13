class_name OsmbCodec
extends RefCounted

## Decodes a bundled snapshot's .osmb payload (the format is documented in
## tools/osmb.py, which writes it) back to Overpass JSON text, so every
## reader of snapshot text (OsmParser, FarCityFetcher, HorizonFetcher, the
## header and freshness checks) works unchanged. The text is compact JSON
## with coordinates to 1e-6 degrees; way node-id lists and bounds are not
## in the format.
##
## Native SnapshotKernels decodes the same payload to the same text when
## the library is loaded; the script below is the fallback and the
## reference the native test compares against. Pure data: worker-safe.

const MAGIC := "PROB"
const VERSION := 1
const F_TAGS := 1
const F_GEOM := 2
const F_LATLON := 4
const F_MEMBERS := 8
const F_CENTER := 16
const M_GEOM := 1
const M_LATLON := 2

static var _native := ClassDB.class_exists("SnapshotKernels")

var _b: PackedByteArray
var _p := 0
var _bad := false
var _lat := 0
var _lon := 0
var _strings := PackedStringArray()
var _parts := PackedStringArray()

## The Overpass JSON text, or "" for a payload that is not a whole .osmb.
static func decode(payload: PackedByteArray) -> String:
	if _native:
		return ClassDB.class_call_static("SnapshotKernels", "decode_osmb", payload)
	return decode_script(payload)

## decode() in GDScript, whether or not the native library is loaded.
static func decode_script(payload: PackedByteArray) -> String:
	if payload.size() < 5 or payload.slice(0, 4).get_string_from_ascii() != MAGIC:
		return ""
	var r := OsmbCodec.new()
	r._b = payload
	r._p = 4
	if r._varint() != VERSION:
		return ""
	var header := r._bytes(r._varint()).get_string_from_utf8().strip_edges()
	var count := r._varint()
	if r._bad or count < 0 or count > payload.size():
		return ""
	r._strings.resize(count)
	for i in count:
		r._strings[i] = '"' + r._bytes(r._varint()).get_string_from_utf8().json_escape() + '"'
	if header.length() < 2 or not header.begins_with("{"):
		return ""
	r._parts.append('{"elements":[' if header == "{}" else header.substr(0, header.length() - 1) + ',"elements":[')
	var elements := r._varint()
	if r._bad or elements > payload.size():
		return ""
	var id := 0
	for i in elements:
		if r._bad:
			return ""
		r._parts.append('{"type":' if i == 0 else ',{"type":')
		r._parts.append(r._string())
		id += r._svarint()
		r._parts.append(',"id":' + str(id))
		var flags := r._varint()
		if flags & F_TAGS:
			r._tags()
		if flags & F_LATLON:
			r._parts.append("," + r._coord())
		if flags & F_CENTER:
			r._parts.append(',"center":{' + r._coord() + "}")
		if flags & F_GEOM:
			r._parts.append(',"geometry":')
			r._points()
		if flags & F_MEMBERS:
			r._members()
		r._parts.append("}")
	r._parts.append("]}")
	if r._bad or r._p != payload.size():
		return ""
	return "".join(r._parts)

func _varint() -> int:
	var result := 0
	var shift := 0
	while true:
		if _p >= _b.size() or shift > 63:
			_bad = true
			return 0
		var byte := _b[_p]
		_p += 1
		result |= (byte & 0x7f) << shift
		if byte < 0x80:
			return result
		shift += 7
	return result

func _svarint() -> int:
	var n := _varint()
	return (n >> 1) ^ -(n & 1)

func _bytes(n: int) -> PackedByteArray:
	if n < 0 or _p + n > _b.size():
		_bad = true
		return PackedByteArray()
	var out := _b.slice(_p, _p + n)
	_p += n
	return out

func _string() -> String:
	var i := _varint()
	if i < 0 or i >= _strings.size():
		_bad = true
		return '""'
	return _strings[i]

static func _micro(v: int) -> String:
	var a := absi(v)
	return ("-" if v < 0 else "") + str(a / 1000000) + "." + str(a % 1000000).pad_zeros(6)

## '"lat":..,"lon":..' for the next coordinate.
func _coord() -> String:
	_lat += _svarint()
	_lon += _svarint()
	return '"lat":' + _micro(_lat) + ',"lon":' + _micro(_lon)

func _points() -> void:
	var count := _varint()
	var nulls := {}
	var n := _varint()
	if _bad or count > _b.size() or n > count:
		_bad = true
		return
	for i in n:
		nulls[_varint()] = true
	_parts.append("[")
	for i in count:
		if i > 0:
			_parts.append(",")
		_parts.append("null" if nulls.has(i) else "{" + _coord() + "}")
	_parts.append("]")

func _tags() -> void:
	var n := _varint()
	if _bad or n > _b.size():
		_bad = true
		return
	_parts.append(',"tags":{')
	for i in n:
		if i > 0:
			_parts.append(",")
		_parts.append(_string())
		_parts.append(":")
		_parts.append(_string())
	_parts.append("}")

func _members() -> void:
	var n := _varint()
	if _bad or n > _b.size():
		_bad = true
		return
	_parts.append(',"members":[')
	var ref := 0
	for i in n:
		_parts.append('{"type":' if i == 0 else ',{"type":')
		_parts.append(_string())
		ref += _svarint()
		_parts.append(',"ref":' + str(ref) + ',"role":')
		_parts.append(_string())
		var flags := _varint()
		if flags & M_LATLON:
			_parts.append("," + _coord())
		if flags & M_GEOM:
			_parts.append(',"geometry":')
			_points()
		_parts.append("}")
	_parts.append("]")
