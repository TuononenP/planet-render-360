class_name MapPack
extends RefCounted

## Map tiles bundled with the app (res://assets/map/*.tilepack): the
## zoomed-out levels of the picker map, its hillshade DEM and the globe's
## world image, so those draw at once and offline. Deeper zooms still
## stream and cache (VectorTileFetcher, TileFetcher); a tile missing from
## the pack falls through to them. Built by tools/build_map_pack.sh.
##
## Format (little-endian): magic "PRTP", u32 version, u32 count, then
## count index entries (u16 z, u16 x, u16 y, u32 offset, u32 length;
## offset from the start of the file), then the tile bodies. A zero
## length is a real, empty tile (open sea).

const MAGIC := "PRTP"
const VERSION := 1
const HEADER_BYTES := 12
const ENTRY_BYTES := 14
const OMT := "res://assets/map/omt.tilepack"
const DEM := "res://assets/map/dem.tilepack"
const OSM := "res://assets/map/osm.tilepack"

static var _shared := {}  # path -> MapPack

var _file: FileAccess
var _index := {}  # Vector3i(z, x, y) -> Vector2i(offset, length)

## One open pack per path, opened on first use. A missing or unreadable
## pack is an empty one: every lookup misses.
static func shared(path: String) -> MapPack:
	if not _shared.has(path):
		_shared[path] = MapPack.open(path)
	return _shared[path]

static func open(path: String) -> MapPack:
	var pack := MapPack.new()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() < HEADER_BYTES:
		return pack
	if f.get_buffer(4).get_string_from_ascii() != MAGIC or f.get_32() != VERSION:
		push_warning("MapPack: %s is not a version %d tile pack" % [path, VERSION])
		return pack
	var count := f.get_32()
	var index := f.get_buffer(count * ENTRY_BYTES)
	if index.size() != count * ENTRY_BYTES:
		return pack
	for i in count:
		var at := i * ENTRY_BYTES
		var key := Vector3i(index.decode_u16(at), index.decode_u16(at + 2), index.decode_u16(at + 4))
		pack._index[key] = Vector2i(index.decode_u32(at + 6), index.decode_u32(at + 10))
	pack._file = f
	return pack

## Write `tiles` (Vector3i z/x/y -> PackedByteArray) as a pack at `path`.
static func write(path: String, tiles: Dictionary) -> Error:
	var keys: Array = tiles.keys()
	keys.sort()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(MAGIC.to_ascii_buffer())
	f.store_32(VERSION)
	f.store_32(keys.size())
	var offset := HEADER_BYTES + keys.size() * ENTRY_BYTES
	for k in keys:
		var key: Vector3i = k
		var body: PackedByteArray = tiles[key]
		f.store_16(key.x)
		f.store_16(key.y)
		f.store_16(key.z)
		f.store_32(offset)
		f.store_32(body.size())
		offset += body.size()
	for k in keys:
		var body: PackedByteArray = tiles[k]
		f.store_buffer(body)
	return OK

func size() -> int:
	return _index.size()

func has_tile(z: int, x: int, y: int) -> bool:
	return _index.has(Vector3i(z, x, y))

## The tile's bytes, or empty when it is not in the pack (or is an empty
## tile: ask has_tile to tell the two apart).
func get_tile(z: int, x: int, y: int) -> PackedByteArray:
	var entry: Variant = _index.get(Vector3i(z, x, y))
	if entry == null:
		return PackedByteArray()
	var at: Vector2i = entry
	if at.y == 0:
		return PackedByteArray()
	_file.seek(at.x)
	return _file.get_buffer(at.y)
