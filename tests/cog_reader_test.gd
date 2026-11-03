extends SceneTree

const Reader = preload("res://scripts/data/cog_reader.gd")

func _init() -> void:
	var failures: Array[String] = []
	var bytes := PackedByteArray()
	bytes.resize(256)
	bytes[0] = 0x49
	bytes[1] = 0x49
	bytes.encode_u16(2, 42)
	bytes.encode_u32(4, 8)
	var entries := [
		[256, 3, 1, 2048], [257, 3, 1, 1024], [258, 3, 1, 8],
		[259, 3, 1, 8], [277, 3, 1, 1], [317, 3, 1, 2],
		[322, 3, 1, 1024], [323, 3, 1, 1024],
		[324, 4, 2, 220], [325, 4, 2, 228]]
	bytes.encode_u16(8, entries.size())
	for i in entries.size():
		var p := 10 + i * 12
		bytes.encode_u16(p, entries[i][0])
		bytes.encode_u16(p + 2, entries[i][1])
		bytes.encode_u32(p + 4, entries[i][2])
		bytes.encode_u32(p + 8, entries[i][3])
	bytes.encode_u32(10 + entries.size() * 12, 4096)
	bytes.encode_u32(220, 10000)
	bytes.encode_u32(224, 11000)
	var ifd: Dictionary = Reader.parse_ifd(bytes, 0, Reader.first_ifd(bytes))
	if not Reader.supported(ifd) or int(ifd.get("next", 0)) != 4096 \
			or int(ifd.get("offsets", {}).get("value", 0)) != 220:
		failures.append("valid tiled IFD or table offset lost: %s" % ifd)
	var chain: Dictionary = Reader.parse_ifds(bytes, 0, 8)
	if (chain["ifds"] as Array).size() != 1 or int(chain["next"]) != 4096:
		failures.append("IFD traversal must return the next offset outside the byte range")
	var cycle := bytes.duplicate()
	cycle.encode_u32(10 + entries.size() * 12, 8)
	if int(Reader.parse_ifds(cycle, 0, 8)["next"]) != -1:
		failures.append("cyclic IFD chain must fail closed")
	if not Reader.parse_ifd(bytes.slice(0, 30), 0, 8).is_empty() \
			or Reader.first_ifd(PackedByteArray([77, 77, 0, 42, 0, 0, 0, 8])) != -1:
		failures.append("truncated and unsupported headers must fail closed")
	if Reader.table_value(ifd["offsets"], 1, bytes.slice(224, 228), 224) != 11000 \
			or Reader.table_value(ifd["offsets"], 1, bytes.slice(220, 224), 220) != -1:
		failures.append("tile table reads must respect the supplied byte range")
	if Reader.tile_index(ifd, 1023, 100) != 0 or Reader.tile_index(ifd, 1024, 100) != 1 \
			or Reader.tile_index(ifd, 2048, 100) != -1:
		failures.append("tile index must be row-major and reject out-of-bounds pixels")
	var reduced := ifd.duplicate(true)
	reduced["width"] = 1024
	reduced["height"] = 512
	reduced["offsets"]["count"] = 1
	reduced["sizes"]["count"] = 1
	if int(Reader.overview([ifd, reduced], 2.0).get("width", 0)) != 1024 \
			or int(Reader.overview([ifd, reduced], 1.5).get("width", 0)) != 2048:
		failures.append("overview selection must not exceed requested reduction")
	var values := PackedByteArray([250, 2, 7, 1, 3, 6])
	var deltas := PackedByteArray([250, 8, 5, 1, 2, 3])
	var decoded: PackedByteArray = Reader.decode_tile(deltas.compress(FileAccess.COMPRESSION_DEFLATE), 3, 2, 2)
	if decoded != values:
		failures.append("horizontal predictor must reset each row and wrap: %s" % decoded)
	if not Reader.decode_tile(PackedByteArray([1, 2, 3]), 3, 2).is_empty():
		failures.append("corrupt compressed tile must fail closed")
	for variable in ["COG_WORLDCOVER_HEADER", "COG_CANOPY_HEADER"]:
		var path := OS.get_environment(variable)
		if not path.is_empty():
			var head := FileAccess.get_file_as_bytes(path)
			if not Reader.supported(Reader.parse_ifd(head, 0, Reader.first_ifd(head))):
				failures.append("sample source header not supported: %s" % path)
	for sample in [["COG_WORLDCOVER_TILE", 1024], ["COG_CANOPY_TILE", 512]]:
		var path := OS.get_environment(sample[0])
		if not path.is_empty():
			var width: int = sample[1]
			if Reader.decode_tile(FileAccess.get_file_as_bytes(path), width, width).size() != width * width:
				failures.append("sample source tile could not be decoded: %s" % path)
	var overview_header := OS.get_environment("COG_CANOPY_OVERVIEW_HEADER")
	if not overview_header.is_empty():
		var header := FileAccess.get_file_as_bytes(overview_header)
		var actual: Dictionary = Reader.parse_ifds(header, 0, Reader.first_ifd(header))
		if int(Reader.overview(actual["ifds"], 4.0).get("width", 0)) != 8192:
			failures.append("canopy overview selection must skip one-bit mask IFDs")
	var overview_tile := OS.get_environment("COG_CANOPY_OVERVIEW_TILE")
	if not overview_tile.is_empty() \
			and Reader.decode_tile(FileAccess.get_file_as_bytes(overview_tile), 512, 512).size() != 512 * 512:
		failures.append("canopy overview tile could not be decoded")
	if failures.is_empty():
		print("COG READER OK: tiled IFD, overview, predictor and corrupt input")
		quit(0)
	else:
		for failure in failures:
			printerr("COG READER FAIL: ", failure)
		quit(1)
