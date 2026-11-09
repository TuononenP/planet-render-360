class_name GroundTiff
extends RefCounted

## Reads the float32 GeoTIFFs national elevation services answer with
## (AHN's WCS: strips, Adobe deflate, floating-point predictor; the
## Environment Agency's WCS: uncompressed 304-px tiles; swisstopo's
## swissALTI3D: 128-px LZW tiles) into {size, values, origin, cell}:
## `origin` is the top-left corner and `cell` the cell size, both in the
## file's own units. {} for anything else (other sample types, other
## compressions or predictors). HelsinkiDem.decode reads the uncompressed
## GeoServer files.

static func decode(bytes: PackedByteArray, threaded: bool = false) -> Dictionary:
	if bytes.size() < 16:
		return {}
	var big := bytes[0] == 0x4D and bytes[1] == 0x4D
	if not big and not (bytes[0] == 0x49 and bytes[1] == 0x49):
		return {}
	var sp := StreamPeerBuffer.new()
	sp.data_array = bytes
	sp.big_endian = big
	sp.seek(4)
	var ifd := sp.get_u32()
	if ifd < 8 or ifd + 2 > bytes.size():
		return {}
	sp.seek(ifd)
	var tags := _tags(sp, ifd, bytes.size())
	var w := _one(tags, 256)
	var h := _one(tags, 257)
	var compression := _one(tags, 259, 1)
	var predictor := _one(tags, 317, 1)
	var tiled := tags.has(324)
	var offsets: Array = tags.get(324 if tiled else 273, [])
	var counts: Array = tags.get(325 if tiled else 279, [])
	var bw := _one(tags, 322) if tiled else w
	var bh := _one(tags, 323) if tiled else _one(tags, 278, h)
	if w <= 0 or h <= 0 or w * h > 16000000 or _one(tags, 258) != 32 or _one(tags, 339) != 3 \
			or _one(tags, 277, 1) != 1 or bw <= 0 or bh <= 0 \
			or not (compression in [1, 5, 8, 32946]) or not (predictor in [1, 3]) \
			or offsets.is_empty() or offsets.size() != counts.size() \
			or not ((tags.has(33550) and tags.has(33922)) or tags.has(34264)):
		return {}
	var across := ceili(float(w) / float(bw))
	var blocks: Array = []
	blocks.resize(offsets.size())
	var args := {"bytes": bytes, "offsets": offsets, "counts": counts, "bw": bw, "bh": bh,
		"compression": compression, "predictor": predictor, "big": big, "tiled": tiled, "h": h}
	var job := func(i: int) -> void:
		blocks[i] = _block(args, i)
	if threaded and offsets.size() > 4:
		var group := WorkerThreadPool.add_group_task(job, offsets.size(), -1, true, "GroundTiff")
		WorkerThreadPool.wait_for_group_task_completion(group)
	else:
		for i in offsets.size():
			job.call(i)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in blocks.size():
		var vals: PackedFloat32Array = blocks[i]
		if vals.size() != bw * bh:
			return {}
		var x0 := (i % across) * bw
		@warning_ignore("integer_division")
		var y0 := (i / across) * bh
		for r in mini(bh, h - y0):
			for c in mini(bw, w - x0):
				out[(y0 + r) * w + x0 + c] = vals[r * bw + c]
	# GeoServer writes a ModelTransformation matrix; other writers a pixel
	# scale and a tiepoint.
	if tags.has(34264):
		var m: Array = tags[34264]
		if m.size() < 8 or float(m[0]) <= 0.0 or float(m[5]) >= 0.0:
			return {}
		return {"size": Vector2i(w, h), "values": out,
			"origin": Vector2(float(m[3]), float(m[7])), "cell": Vector2(float(m[0]), -float(m[5]))}
	var scale: Array = tags[33550]
	var tie: Array = tags[33922]
	if scale.size() < 2 or tie.size() < 6 or float(scale[0]) <= 0.0 or float(scale[1]) <= 0.0:
		return {}
	return {"size": Vector2i(w, h), "values": out,
		"origin": Vector2(float(tie[3]) - float(tie[0]) * float(scale[0]),
			float(tie[4]) + float(tie[1]) * float(scale[1])),
		"cell": Vector2(float(scale[0]), float(scale[1]))}

## The bw × bh floats of block `i` (a strip or tile, edge blocks padded), or
## an empty array when its bytes are bad.
static func _block(a: Dictionary, i: int) -> PackedFloat32Array:
	var bytes: PackedByteArray = a["bytes"]
	var bw: int = a["bw"]
	var bh: int = a["bh"]
	var start := int(a["offsets"][i])
	var length := int(a["counts"][i])
	if start < 0 or start + length > bytes.size():
		return PackedFloat32Array()
	# The last strip of a strip file holds only the rows that remain.
	var rows := bh if bool(a["tiled"]) else mini(bh, int(a["h"]) - i * bh)
	var raw := bytes.slice(start, start + length)
	match int(a["compression"]):
		5:
			raw = _lzw(raw, bw * rows * 4)
		8, 32946:
			raw = raw.decompress(bw * rows * 4, FileAccess.COMPRESSION_DEFLATE)
	if rows <= 0 or raw.size() < bw * rows * 4:
		return PackedFloat32Array()
	raw.resize(bw * bh * 4)
	var planes: bool = int(a["predictor"]) == 3
	var big: bool = a["big"]
	var out := PackedFloat32Array()
	out.resize(bw * bh)
	var b := PackedByteArray()
	b.resize(4)
	for r in rows:
		var row_at := r * bw * 4
		if planes:
			for k in range(1, bw * 4):
				raw[row_at + k] = (raw[row_at + k] + raw[row_at + k - 1]) & 0xFF
		for c in bw:
			for k in 4:
				if planes:
					b[3 - k] = raw[row_at + k * bw + c]
				elif big:
					b[3 - k] = raw[row_at + c * 4 + k]
				else:
					b[k] = raw[row_at + c * 4 + k]
			out[r * bw + c] = b.decode_float(0)
	return out

## TIFF LZW (most significant bit first, codes widening one code early).
static func _lzw(src: PackedByteArray, expected: int) -> PackedByteArray:
	var out := PackedByteArray()
	var table: Array = []
	table.resize(4096)
	for i in 256:
		table[i] = PackedByteArray([i])
	var next := 258
	var width := 9
	var acc := 0
	var bits := 0
	var pos := 0
	var prev := PackedByteArray()
	while pos < src.size() or bits >= width:
		while bits < width and pos < src.size():
			acc = (acc << 8) | src[pos]
			pos += 1
			bits += 8
		if bits < width:
			break
		var code := (acc >> (bits - width)) & ((1 << width) - 1)
		bits -= width
		acc &= (1 << bits) - 1
		if code == 257:
			break
		if code == 256:
			next = 258
			width = 9
			prev = PackedByteArray()
			continue
		var entry: PackedByteArray
		if code < next and code != 256 and code != 257:
			entry = table[code]
		elif code == next and not prev.is_empty():
			entry = prev.duplicate()
			entry.append(prev[0])
		else:
			return PackedByteArray()
		out.append_array(entry)
		if not prev.is_empty() and next < 4096:
			var added := prev.duplicate()
			added.append(entry[0])
			table[next] = added
			next += 1
			if next == 511:
				width = 10
			elif next == 1023:
				width = 11
			elif next == 2047:
				width = 12
		prev = entry
		if out.size() >= expected:
			break
	return out

static func _tags(sp: StreamPeerBuffer, ifd: int, size: int) -> Dictionary:
	var count := sp.get_u16()
	var tags := {}
	for i in count:
		sp.seek(ifd + 2 + i * 12)
		var tag := sp.get_u16()
		var type := sp.get_u16()
		var n := sp.get_u32()
		var width := {3: 2, 4: 4, 12: 8}.get(type, 0) as int
		if width == 0 or n > 100000:
			continue
		var at := ifd + 2 + i * 12 + 8
		if width * n > 4:
			sp.seek(at)
			at = sp.get_u32()
		if at + width * n > size:
			return {}
		sp.seek(at)
		var vals: Array = []
		for k in n:
			vals.append(sp.get_u16() if type == 3 else (sp.get_u32() if type == 4 else sp.get_double()))
		tags[tag] = vals
	return tags

static func _one(tags: Dictionary, tag: int, fallback: int = 0) -> int:
	var v: Array = tags.get(tag, [])
	return int(v[0]) if not v.is_empty() else fallback
