class_name Brand
extends RefCounted

## The logo files from the design system, copied as-is into
## assets/brand/: the mark alone where the name is already on screen
## (loading), the horizontal wordmark in the picker. Never retype the
## name next to the mark; the lockups are outlined files.

const MARK := "res://assets/brand/pr360-mark-dark.svg"
const WORDMARK := "res://assets/brand/pr360-wordmark-dark.svg"

static var _cache := {}

## The logo rasterised for `height` logical points, at 2x so it stays
## crisp on Retina and phone screens. Reads the raw SVG when present
## (dev checkouts before the first editor import), else the imported
## texture (exported builds ship only the import).
static func texture(path: String, height: int) -> Texture2D:
	var key := "%s@%d" % [path, height]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var svg := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var m := RegEx.create_from_string("<svg[^>]*\\sheight=\"([0-9.]+)\"").search(svg)
	if m != null:
		var img := Image.new()
		if img.load_svg_from_string(svg, height * 2.0 / float(m.get_string(1))) == OK:
			tex = ImageTexture.create_from_image(img)
	if tex == null and ResourceLoader.exists(path):
		tex = load(path)
	_cache[key] = tex
	return tex

## A TextureRect showing the logo `height` points tall, aspect kept.
static func rect(path: String, height: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture(path, height)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aspect := 1.0
	if r.texture != null and r.texture.get_height() > 0:
		aspect = float(r.texture.get_width()) / float(r.texture.get_height())
	r.custom_minimum_size = Vector2(roundf(height * aspect), height)
	return r
