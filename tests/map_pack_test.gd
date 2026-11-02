extends SceneTree

## Bundled map tiles: godot --headless --script tests/map_pack_test.gd
## Offline: a pack round-trips its tiles byte for byte, keeps empty (sea)
## tiles apart from misses, and the fetchers serve bundled tiles at once
## without opening a connection, falling through on a miss.

const PATH := "user://map_pack_test.tilepack"

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var big := PackedByteArray()
	for i in 70000:
		big.append(i % 251)
	var gz := PackedByteArray([1, 2, 3]).compress(FileAccess.COMPRESSION_GZIP)
	var png := Image.create(4, 4, false, Image.FORMAT_RGB8).save_png_to_buffer()
	var tiles := {
		Vector3i(3, 4, 2): big,
		Vector3i(0, 0, 0): gz,
		Vector3i(6, 63, 1): PackedByteArray(),
		Vector3i(2, 1, 3): png,
	}
	if MapPack.write(PATH, tiles) != OK:
		_finish(["could not write %s" % PATH])
		return
	var pack := MapPack.open(PATH)
	if pack.size() != tiles.size():
		failures.append("pack holds %d tiles, wrote %d" % [pack.size(), tiles.size()])
	for k in tiles:
		var key: Vector3i = k
		if not pack.has_tile(key.x, key.y, key.z) or pack.get_tile(key.x, key.y, key.z) != tiles[key]:
			failures.append("tile %s did not round-trip" % key)
	if pack.has_tile(7, 0, 0) or not pack.get_tile(7, 0, 0).is_empty():
		failures.append("a tile outside the pack should miss")
	if MapPack.open("user://no_such.tilepack").size() != 0:
		failures.append("a missing pack should be empty")

	var omt := VectorTileFetcher.new(VectorTileFetcher.Kind.VECTOR)
	omt.pack = pack
	var got: Array = []
	omt.tile_ready.connect(func(z: int, x: int, y: int, body: PackedByteArray) -> void:
		got.append([Vector3i(z, x, y), body]))
	omt.request_tile(3, 4, 2)
	omt.request_tile(6, 63, 1)
	if got.size() != 2 or got[0][1] != big or not (got[1][1] as PackedByteArray).is_empty():
		failures.append("bundled vector tiles should arrive at once, sea tile empty: %d" % got.size())
	omt.request_tile(13, 1, 1)
	if got.size() != 2 or not omt._pending.has(Vector3i(13, 1, 1)):
		failures.append("a tile outside the pack should queue for the network")
	omt.free()

	var osm := TileFetcher.new()
	osm.pack = pack
	var textures: Array = []
	osm.tile_ready.connect(func(_z: int, _x: int, _y: int, tex: Texture2D) -> void:
		textures.append(tex))
	osm.request_tile(2, 1, 3)
	if textures.size() != 1 or (textures[0] as Texture2D).get_width() != 4:
		failures.append("bundled globe tile should arrive at once as a texture")
	osm.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	_check_bundled(failures)
	_finish(failures)

## The shipped packs cover every tile of their zooms (so the picker's
## zoomed-out levels and the globe never need the network), and a bundled
## vector tile decodes and builds.
func _check_bundled(failures: Array[String]) -> void:
	for spec in [[MapPack.OMT, 0, 6], [MapPack.DEM, 0, 5], [MapPack.OSM, 2, 2]]:
		var pack := MapPack.shared(spec[0])
		var want := 0
		for z in range(int(spec[1]), int(spec[2]) + 1):
			want += 1 << (2 * z)
			for x in 1 << z:
				for y in 1 << z:
					if not pack.has_tile(z, x, y):
						failures.append("%s lacks %d/%d/%d" % [spec[0], z, x, y])
						return
		if pack.size() != want:
			failures.append("%s holds %d tiles, want %d" % [spec[0], pack.size(), want])
	# Western Europe at data zoom 6, as picker zoom 7 asks for it.
	var body := MapPack.shared(MapPack.OMT).get_tile(6, 32, 21)
	var decoded := MvtReader.read(VectorTileFetcher.inflate(body), MapStyle.wanted(6.0))
	var built := VectorTileBuilder.build(decoded, 6.0, MapStyle.colors(), 512.0, [false])
	if decoded.is_empty() or built.is_empty():
		failures.append("bundled z6 tile did not decode and build")

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("MAP_PACK OK: round trip, sea vs miss, missing pack, fetchers serve bundled tiles, shipped packs cover their zooms and build")
		quit(0)
	else:
		for f in failures:
			printerr("MAP_PACK FAIL: ", f)
		quit(1)
