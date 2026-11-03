class_name CogReader
extends RefCounted

## Classic, little-endian, single-band tiled TIFF metadata and tile decoder.
## Offset and byte-count tables can be range-read separately; no full raster
## download is required. Unsupported layouts fail closed.

const TIFF_MAGIC := 42

## Parse a complete IFD from a byte range beginning at `base`, returning
## {} for truncated or unsupported data. `next` can point outside the range.
static func parse_ifd(bytes: PackedByteArray, base: int, offset: int) -> Dictionary:
	var at := offset - base
	if at < 0 or at + 2 > bytes.size():
		return {}
	var count := bytes.decode_u16(at)
	var end := at + 2 + count * 12
	if end + 4 > bytes.size():
		return {}
	var tags := {}
	for i in count:
		var pos := at + 2 + i * 12
		var tag := bytes.decode_u16(pos)
		var type := bytes.decode_u16(pos + 2)
		var n := bytes.decode_u32(pos + 4)
		if type not in [3, 4] or n < 1:
			continue
		var value := bytes.decode_u16(pos + 8) if type == 3 and n == 1 else bytes.decode_u32(pos + 8)
		tags[tag] = {"type": type, "count": n, "value": value}
	var result := {"next": bytes.decode_u32(end)}
	var fields := {256: "width", 257: "height", 258: "bits", 259: "compression",
			277: "samples", 284: "planar", 317: "predictor", 322: "tile_width",
			323: "tile_height", 254: "subfile_type"}
	for key in fields:
		if tags.has(key) and int(tags[key]["count"]) == 1:
			result[fields[key]] = int(tags[key]["value"])
	for pair in [[324, "offsets"], [325, "sizes"]]:
		if tags.has(pair[0]):
			result[pair[1]] = tags[pair[0]]
	return result

static func first_ifd(header: PackedByteArray) -> int:
	if header.size() < 8 or header[0] != 0x49 or header[1] != 0x49 \
			or header.decode_u16(2) != TIFF_MAGIC:
		return -1
	return int(header.decode_u32(4))

## Walk all IFDs contained in this byte range. An out-of-range `next`
## tells the caller where to fetch the next range; a cycle fails closed.
static func parse_ifds(bytes: PackedByteArray, base: int, offset: int) -> Dictionary:
	var found: Array = []
	var seen := {}
	var next := offset
	while next > 0:
		if seen.has(next):
			return {"ifds": found, "next": -1}
		seen[next] = true
		var ifd := parse_ifd(bytes, base, next)
		if ifd.is_empty():
			return {"ifds": found, "next": next}
		found.append(ifd)
		next = int(ifd["next"])
	return {"ifds": found, "next": 0}

## WorldCover and canopy tiles are unsigned 8-bit, one sample per pixel.
static func supported(ifd: Dictionary) -> bool:
	if int(ifd.get("width", 0)) <= 0 or int(ifd.get("height", 0)) <= 0 \
			or int(ifd.get("tile_width", 0)) <= 0 or int(ifd.get("tile_height", 0)) <= 0:
		return false
	if int(ifd.get("bits", 0)) != 8 or int(ifd.get("compression", 0)) not in [8, 32946] \
			or int(ifd.get("samples", 1)) != 1 or int(ifd.get("planar", 1)) != 1 \
			or int(ifd.get("predictor", 1)) not in [1, 2]:
		return false
	if not ifd.has("offsets") or not ifd.has("sizes"):
		return false
	if int(ifd["offsets"].get("type", 0)) != 4 or int(ifd["sizes"].get("type", 0)) != 4:
		return false
	var cols := ceili(float(ifd["width"]) / float(ifd["tile_width"]))
	var rows := ceili(float(ifd["height"]) / float(ifd["tile_height"]))
	return int(ifd["offsets"]["count"]) == cols * rows \
		and int(ifd["sizes"]["count"]) == cols * rows

## Pick the coarsest valid overview no coarser than the requested reduction.
static func overview(ifds: Array, desired_reduction: float) -> Dictionary:
	var base_width := 0
	for ifd in ifds:
		if supported(ifd):
			base_width = maxi(base_width, int(ifd["width"]))
	var best := {}
	var best_reduction := 0.0
	for ifd in ifds:
		if not supported(ifd):
			continue
		var reduction := float(base_width) / float(ifd["width"])
		if reduction <= maxf(1.0, desired_reduction) and reduction > best_reduction:
			best = ifd
			best_reduction = reduction
	return best

## Return a LONG tile-table entry from a supplied byte range, or -1 when
## the entry is outside the range. TIFF stores a single entry inline.
static func table_value(table: Dictionary, index: int, bytes: PackedByteArray, base: int) -> int:
	var count := int(table.get("count", 0))
	if int(table.get("type", 0)) != 4 or index < 0 or index >= count:
		return -1
	if count == 1:
		return int(table.get("value", -1))
	var pos := int(table.get("value", -1)) + index * 4 - base
	return int(bytes.decode_u32(pos)) if pos >= 0 and pos + 4 <= bytes.size() else -1

## Row-major TIFF tile index for a pixel, or -1 outside the image.
static func tile_index(ifd: Dictionary, x: int, y: int) -> int:
	if not supported(ifd) or x < 0 or y < 0 \
			or x >= int(ifd["width"]) or y >= int(ifd["height"]):
		return -1
	var tw := int(ifd["tile_width"])
	var th := int(ifd["tile_height"])
	var cols := ceili(float(ifd["width"]) / float(tw))
	return (y / th) * cols + x / tw

## Decode one deflated byte tile and undo horizontal differencing per row.
static func decode_tile(compressed: PackedByteArray, width: int, height: int,
		predictor: int = 1) -> PackedByteArray:
	if compressed.is_empty() or width <= 0 or height <= 0 or width > 4096 or height > 4096 \
			or predictor not in [1, 2]:
		return PackedByteArray()
	var raw := compressed.decompress(width * height, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != width * height:
		return PackedByteArray()
	if predictor == 2:
		for y in height:
			var row := y * width
			for x in range(1, width):
				raw[row + x] = (int(raw[row + x]) + int(raw[row + x - 1])) & 255
	return raw
