class_name MvtReader
extends RefCounted

## Mapbox Vector Tile (protobuf) decoder for the vector map: just enough
## of the spec (v2) for OpenMapTiles tiles. Pure data, so it runs on a
## worker thread. Only the layers listed in `wanted` are decoded, and only
## the tag keys listed for each, which keeps a dense city tile (≈0.5 MB
## inflated) affordable in GDScript.
##
## read() returns { layer name: { "extent": int, "features": [feature] } }
## where a feature is { "type": POINT|LINE|POLYGON, "tags": {key: value},
## "geom": Array } and geom holds:
##   POINT   – one PackedVector2Array of points
##   LINE    – PackedVector2Array per line
##   POLYGON – [outer, hole, hole...] per polygon (Array of rings)
## in tile units (0..extent, y down).

enum { UNKNOWN, POINT, LINE, POLYGON }

const WIRE_VARINT := 0
const WIRE_64 := 1
const WIRE_LEN := 2
const WIRE_32 := 5

var _b: PackedByteArray
var _p := 0

## `wanted`: layer name -> Array of tag keys to keep (empty: keep none).
static func read(bytes: PackedByteArray, wanted: Dictionary) -> Dictionary:
	var r := MvtReader.new()
	r._b = bytes
	r._p = 0
	var out: Dictionary = {}
	while r._p < bytes.size():
		var key := r._varint()
		var field := key >> 3
		var wire := key & 7
		if field == 3 and wire == WIRE_LEN:
			var length := r._len()
			var end := mini(r._p + length, bytes.size())
			var layer := r._layer(end, wanted)
			r._p = end
			if not layer.is_empty():
				out[layer["name"]] = layer
		else:
			r._skip(wire)
	return out

## Past the end it returns 0 and moves _p past the end, so every
## `while _p < end` loop terminates on a truncated buffer.
func _varint() -> int:
	if _p >= _b.size():
		_p = _b.size() + 1
		return 0
	var result := 0
	var shift := 0
	while _p < _b.size():
		var byte := _b[_p]
		_p += 1
		result |= (byte & 0x7f) << shift
		if byte < 0x80:
			break
		shift += 7
	return result

## A length prefix. A corrupt one (negative after a 10-byte varint) ends
## the read instead of moving _p backwards.
func _len() -> int:
	var n := _varint()
	if n < 0:
		_p = _b.size() + 1
		return 0
	return n

static func _zigzag(n: int) -> int:
	return (n >> 1) ^ -(n & 1)

func _skip(wire: int) -> void:
	match wire:
		WIRE_VARINT:
			_varint()
		WIRE_64:
			_p += 8
		WIRE_LEN:
			var length := _len()
			_p += length
		WIRE_32:
			_p += 4
		_:
			_p = _b.size()  # unknown wire type: stop rather than misread

func _string(length: int) -> String:
	var s := _b.slice(_p, mini(_p + length, _b.size())).get_string_from_utf8()
	_p += length
	return s

## A layer, or {} when it is not wanted. Keys and values may follow the
## features, so features keep raw tag indices until the layer ends.
func _layer(end: int, wanted: Dictionary) -> Dictionary:
	var name := ""
	var extent := 4096
	var keys: Array[String] = []
	var values: Array[Vector2i] = []  # byte ranges, decoded on first use
	var raw: Array = []  # [type, PackedInt32Array tags, PackedInt32Array geometry]
	var start := _p
	# Pass 1: the name decides whether the rest is worth decoding.
	while _p < end:
		var key := _varint()
		if key >> 3 == 1 and key & 7 == WIRE_LEN:
			name = _string(_len())
			break
		_skip(key & 7)
	if not wanted.has(name):
		return {}
	_p = start
	while _p < end:
		var key := _varint()
		var field := key >> 3
		var wire := key & 7
		if wire != WIRE_LEN:
			if field == 5 and wire == WIRE_VARINT:
				extent = _varint()
			else:
				_skip(wire)
			continue
		var length := _len()
		var sub_end := mini(_p + length, end)
		match field:
			2:
				raw.append(_feature(sub_end))
			3:
				keys.append(_string(length))
			4:
				values.append(Vector2i(_p, sub_end))
			_:
				_p = sub_end
		_p = sub_end
	var keep: Array = wanted[name]
	# Only keys the style reads; their values decode once, on first use, so
	# the dozens of name:xx translations in a city tile never become strings.
	var kept_key: Array[bool] = []
	for k in keys:
		kept_key.append(k in keep)
	var decoded: Dictionary = {}  # value index -> Variant
	var features: Array = []
	for f in raw:
		var tags: Dictionary = {}
		var t: PackedInt32Array = f[1]
		for i in range(0, t.size() - 1, 2):
			var ki := t[i]
			var vi := t[i + 1]
			if ki < 0 or ki >= keys.size() or vi < 0 or vi >= values.size() or not kept_key[ki]:
				continue
			if not decoded.has(vi):
				_p = values[vi].x
				decoded[vi] = _value(values[vi].y)
			tags[keys[ki]] = decoded[vi]
		var geom := decode_geometry(int(f[0]), f[2])
		if not geom.is_empty():
			features.append({"type": int(f[0]), "tags": tags, "geom": geom})
	return {"name": name, "extent": extent, "features": features}

func _feature(end: int) -> Array:
	var type := UNKNOWN
	var tags := PackedInt32Array()
	var geometry := PackedInt32Array()
	while _p < end:
		var key := _varint()
		var field := key >> 3
		var wire := key & 7
		if field == 3 and wire == WIRE_VARINT:
			type = _varint()
		elif (field == 2 or field == 4) and wire == WIRE_LEN:
			var packed_len := _len()  # read first: it advances _p
			var packed_end := mini(_p + packed_len, end)
			var arr := PackedInt32Array()
			while _p < packed_end:
				arr.append(_varint())
			if field == 2:
				tags = arr
			else:
				geometry = arr
		else:
			_skip(wire)
	return [type, tags, geometry]

func _value(end: int) -> Variant:
	var v: Variant = null
	while _p < end:
		var key := _varint()
		var field := key >> 3
		var wire := key & 7
		match field:
			1:
				v = _string(_len())
			2:
				if _p + 4 <= _b.size():
					v = _b.decode_float(_p)
				_p += 4
			3:
				if _p + 8 <= _b.size():
					v = _b.decode_double(_p)
				_p += 8
			4, 5:
				v = _varint()
			6:
				v = _zigzag(_varint())
			7:
				v = _varint() != 0
			_:
				_skip(wire)
	return v

## Command stream -> geometry (see the class doc). Exterior rings have a
## positive surveyor's area in tile space (spec 4.3.4.4); negative rings
## are holes of the polygon before them.
static func decode_geometry(type: int, cmds: PackedInt32Array) -> Array:
	var parts: Array = []
	var current := PackedVector2Array()
	var cx := 0
	var cy := 0
	var i := 0
	while i < cmds.size():
		var cmd := cmds[i] & 7
		var count := cmds[i] >> 3
		i += 1
		if cmd == 7:  # ClosePath
			if current.size() >= 3:
				parts.append(current)
			current = PackedVector2Array()
			continue
		for _n in count:
			if i + 1 >= cmds.size():
				break
			cx += _zigzag(cmds[i])
			cy += _zigzag(cmds[i + 1])
			i += 2
			if cmd == 1 and type != POINT and current.size() > 0:
				if type == LINE and current.size() >= 2:
					parts.append(current)
				current = PackedVector2Array()
			current.append(Vector2(cx, cy))
	if type == POINT:
		return [current] if current.size() > 0 else []
	if type == LINE:
		if current.size() >= 2:
			parts.append(current)
		return parts
	if type != POLYGON:
		return []
	var polygons: Array = []
	for ring in parts:
		var area := ring_area(ring)
		if area > 0.0 or polygons.is_empty():
			polygons.append([ring])
		elif area < 0.0:
			(polygons[polygons.size() - 1] as Array).append(ring)
	return polygons

## Surveyor's formula as the MVT spec defines it (tile space, y down).
static func ring_area(ring: PackedVector2Array) -> float:
	var a := 0.0
	for k in ring.size():
		var p := ring[k]
		var q := ring[(k + 1) % ring.size()]
		a += p.x * q.y - q.x * p.y
	return a / 2.0
