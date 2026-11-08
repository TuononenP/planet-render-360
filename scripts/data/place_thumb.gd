class_name PlaceThumb
extends RefCounted

## The picture History and Recents show for a place: the 360 view as it
## looked when it opened or when the person left it, shrunk to card size
## and kept as a small JPEG per place (user://thumbs/<lat>_<lon>.jpg,
## the same quantised key as the world cache). Not part of the cache
## budget: ~15 KB each, kept for as long as the place is in History.
## A place without one shows the stand-in sky and ridge.

const DIR := "user://thumbs"
const BUNDLED_DIR := "res://assets/preset_thumbs"
## Capital pictures, keyed by the quantised coordinates of the catalog point.
const CAPITAL_DIR := "res://assets/capital_thumbs"
const WIDTH := 320
const HEIGHT := 200
const QUALITY := 0.82
## Brightest channel a frame may peak at and still count as blank.
const BLANK_MAX := 0.03

## Test hook (CacheStore.dir_override precedent): thumbnails resolve
## under this directory instead of DIR.
static var dir_override := ""

static var _textures := {}  # path -> [mtime, Texture2D]

static func path(lat: float, lon: float) -> String:
	var dir := dir_override if dir_override != "" else DIR
	return "%s/%d_%d.jpg" % [dir, CacheStore.quant(lat), CacheStore.quant(lon)]

## `img` centre-cropped to the card's aspect and shrunk to WIDTH x HEIGHT,
## null for an empty image (a headless renderer reads back nothing) or a
## blank one (a viewport read back in the frame after a resize is black).
## A blank frame never replaces a place's picture.
static func shrink(img: Image) -> Image:
	if img == null or img.is_empty() or img.get_width() < 2 or img.get_height() < 2:
		return null
	var out := img.duplicate() as Image
	if out.is_compressed():
		out.decompress()
	var want := float(WIDTH) / float(HEIGHT)
	var w := out.get_width()
	var h := out.get_height()
	if float(w) / float(h) > want:
		var cw := roundi(float(h) * want)
		out = out.get_region(Rect2i((w - cw) / 2, 0, cw, h))
	else:
		var ch := roundi(float(w) / want)
		out = out.get_region(Rect2i(0, (h - ch) / 2, w, ch))
	out.convert(Image.FORMAT_RGB8)
	out.resize(WIDTH, HEIGHT, Image.INTERPOLATE_LANCZOS)
	return null if is_blank(out) else out

## No pixel brighter than BLANK_MAX: nothing was drawn. Even a night scene
## has its sky glow, moon or lit windows above that; sampled on a grid.
static func is_blank(img: Image) -> bool:
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			if maxf(c.r, maxf(c.g, c.b)) > BLANK_MAX:
				return false
	return true

## Shrinks and writes `img` for the place; false when nothing was saved.
static func save(img: Image, lat: float, lon: float) -> bool:
	var small := shrink(img)
	if small == null:
		return false
	var p := path(lat, lon)
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	return small.save_jpg(p, QUALITY) == OK

static func exists(lat: float, lon: float) -> bool:
	return FileAccess.file_exists(path(lat, lon))

## The place's picture, null when it has none.
static func load_texture(lat: float, lon: float) -> Texture2D:
	var p := path(lat, lon)
	if not FileAccess.file_exists(p):
		return null
	var mtime := FileAccess.get_modified_time(p)
	var hit: Array = _textures.get(p, [])
	if not hit.is_empty() and int(hit[0]) == mtime:
		return hit[1]
	var img := Image.load_from_file(p)
	if img == null or img.is_empty():
		return null
	var tex := ImageTexture.create_from_image(img)
	_textures[p] = [mtime, tex]
	return tex

## A preset's picture: the daytime render shipped in
## res://assets/preset_thumbs/<id>.jpg (baked by tools/capture_presets.gd
## --bake-thumbs), null when it has none. Never the person's own snapshot,
## so the shelf stays one consistent daylight set.
static func load_preset(id: String) -> Texture2D:
	return _load_shipped(bundled_path(id))

static func _load_shipped(p: String) -> Texture2D:
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	# Not imported (the editor never scanned it): read the shipped JPEG as is.
	var hit: Array = _textures.get(p, [])
	if not hit.is_empty():
		return hit[1]
	var img := Image.load_from_file(p)
	if img == null or img.is_empty():
		return null
	var tex := ImageTexture.create_from_image(img)
	_textures[p] = [0, tex]
	return tex

## A capital's picture, shipped in res://assets/capital_thumbs (baked by
## tools/capture_presets.gd --capital-thumbs), null when it has none.
static func load_capital(lat: float, lon: float) -> Texture2D:
	return _load_shipped(capital_path(lat, lon))

static func capital_path(lat: float, lon: float) -> String:
	return "%s/%d_%d.jpg" % [CAPITAL_DIR, CacheStore.quant(lat), CacheStore.quant(lon)]

static func bundled_path(id: String) -> String:
	return "%s/%s.jpg" % [BUNDLED_DIR, id]

static func remove(lat: float, lon: float) -> void:
	var p := path(lat, lon)
	_textures.erase(p)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(p)
