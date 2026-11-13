extends SceneTree

## Headless: godot --headless --script tests/osmb_codec_test.gd
## Bundled snapshots in .osmb (tools/osmb.py): every manifest row's file
## decompresses, matches its size and SHA-256, decodes to Overpass JSON
## that parses, and the native and script decoders write the same text.
## Damaged payloads decode to "".

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	failures.clear()
	var keys := BundledOsm._entries().keys()
	var compared := 0
	var largest := 0
	for key: String in keys:
		var text := BundledOsm.read(key)
		if text == "":
			failures.append("%s does not load" % key)
			continue
		largest = maxi(largest, text.length())
		var parsed: Variant = JSON.parse_string(text)
		if not (parsed is Dictionary) or not ((parsed as Dictionary).get("elements", null) is Array):
			failures.append("%s does not parse as Overpass JSON" % key)
			continue
		# The script decoder is slow on the big layers: compare a spread of
		# small ones byte for byte, plus one large one.
		if ClassDB.class_exists("SnapshotKernels") and (compared < 40 and text.length() < 2_000_000 \
				or key == "berlin_detailed"):
			var payload := _payload(key)
			if OsmbCodec.decode_script(payload) != text:
				failures.append("%s: native and script decoders differ" % key)
			compared += 1
	if not ClassDB.class_exists("SnapshotKernels"):
		print("osmb_codec_test: native library not loaded; script decoder only")
	_damage_checks()
	_known_payload()
	if failures.is_empty():
		print("OSMB CODEC OK: %d snapshots load and parse, %d compared native/script, largest %.1f MB of JSON"
			% [keys.size(), compared, largest / 1e6])
		quit(0)
	else:
		for f in failures.slice(0, 40):
			printerr("OSMB CODEC FAIL: ", f)
		quit(1)

func _payload(key: String) -> PackedByteArray:
	var bytes := FileAccess.get_file_as_bytes(BundledOsm.DIRECTORY + key + ".osmb")
	return bytes.decompress(int(BundledOsm._entries()[key][5]), FileAccess.COMPRESSION_ZSTD)

func _damage_checks() -> void:
	var payload := _payload("berlin_poi")
	for decoder in ["native", "script"]:
		if decoder == "native" and not ClassDB.class_exists("SnapshotKernels"):
			continue
		var decode := func(p: PackedByteArray) -> String:
			return OsmbCodec.decode(p) if decoder == "native" else OsmbCodec.decode_script(p)
		if decode.call(payload.slice(0, payload.size() - 7)) != "":
			failures.append("%s: a truncated payload must not decode" % decoder)
		var wrong := payload.duplicate()
		wrong[0] = 0x58
		if decode.call(wrong) != "":
			failures.append("%s: a wrong magic must not decode" % decoder)
		var longer := payload.duplicate()
		longer.append(0)
		if decode.call(longer) != "":
			failures.append("%s: trailing bytes must not decode" % decoder)
		if decode.call(PackedByteArray()) != "":
			failures.append("%s: an empty payload must not decode" % decoder)

## A hand-built payload: header, string table (with characters JSON must
## escape), a node, a way with a null geometry entry and a relation.
func _known_payload() -> void:
	var p := PackedByteArray("PROB".to_ascii_buffer())
	_varint(p, OsmbCodec.VERSION)
	var header := '{"version":0.6,"osm3s":{"timestamp_osm_base":"2026-11-03T00:00:00Z"}}'.to_utf8_buffer()
	_varint(p, header.size())
	p.append_array(header)
	var strings := ["node", "way", "relation", "name", 'Café "Q"\\x', "building", "yes", "outer", "type", "multipolygon"]
	_varint(p, strings.size())
	for s: String in strings:
		var b := s.to_utf8_buffer()
		_varint(p, b.size())
		p.append_array(b)
	_varint(p, 3)
	# node 100 at (60.168, -0.5) named Café "Q"\x
	_varint(p, 0)
	_svarint(p, 100)
	_varint(p, OsmbCodec.F_TAGS | OsmbCodec.F_LATLON)
	_varint(p, 1)
	_varint(p, 3)
	_varint(p, 4)
	_svarint(p, 601680000)
	_svarint(p, -5000000)
	# way 101: building, three points, the second null
	_varint(p, 1)
	_svarint(p, 1)
	_varint(p, OsmbCodec.F_TAGS | OsmbCodec.F_GEOM)
	_varint(p, 1)
	_varint(p, 5)
	_varint(p, 6)
	_varint(p, 3)
	_varint(p, 1)
	_varint(p, 1)
	_svarint(p, 1)
	_svarint(p, 0)
	_svarint(p, 0)
	_svarint(p, -1)
	# relation 50: multipolygon, one outer way member 101 with one point
	_varint(p, 2)
	_svarint(p, -51)
	_varint(p, OsmbCodec.F_TAGS | OsmbCodec.F_MEMBERS)
	_varint(p, 1)
	_varint(p, 8)
	_varint(p, 9)
	_varint(p, 1)
	_varint(p, 1)
	_svarint(p, 101)
	_varint(p, 7)
	_varint(p, OsmbCodec.M_GEOM)
	_varint(p, 1)
	_varint(p, 0)
	_svarint(p, 0)
	_svarint(p, 0)
	var want := '{"version":0.6,"osm3s":{"timestamp_osm_base":"2026-11-03T00:00:00Z"},"elements":[' \
		+ '{"type":"node","id":100,"tags":{"name":"Café \\"Q\\"\\\\x"},"lat":60.1680000,"lon":-0.5000000},' \
		+ '{"type":"way","id":101,"tags":{"building":"yes"},"geometry":[{"lat":60.1680001,"lon":-0.5000000},null,{"lat":60.1680001,"lon":-0.5000001}]},' \
		+ '{"type":"relation","id":50,"tags":{"type":"multipolygon"},"members":[{"type":"way","ref":101,"role":"outer","geometry":[{"lat":60.1680001,"lon":-0.5000001}]}]}]}'
	var script := OsmbCodec.decode_script(p)
	if script != want:
		failures.append("script decode of the known payload:\n%s\nwant\n%s" % [script, want])
	if ClassDB.class_exists("SnapshotKernels") and OsmbCodec.decode(p) != want:
		failures.append("native decode of the known payload:\n%s" % OsmbCodec.decode(p))
	var parsed: Variant = JSON.parse_string(script)
	if not (parsed is Dictionary) or str((parsed["elements"][0] as Dictionary)["tags"]["name"]) != 'Café "Q"\\x':
		failures.append("escaped strings must parse back unchanged")
	if BundledOsm.header_stamp(script) != "2026-11-03T00:00:00":
		failures.append("the header keeps the timestamp at the head of the text")

func _varint(out: PackedByteArray, v: int) -> void:
	while v >= 0x80:
		out.append((v & 0x7f) | 0x80)
		v >>= 7
	out.append(v)

func _svarint(out: PackedByteArray, v: int) -> void:
	_varint(out, (v << 1) if v >= 0 else ((-v << 1) - 1))
