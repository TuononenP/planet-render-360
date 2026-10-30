class_name FacadePaint
extends RefCounted

## Layers of a composed facade (FacadeComposer / StoreyComposer):
## - base: the photographic wall plus anything that belongs to the wall
##   material itself (boards, ribs, grout, grime, rain streaks). The
##   building's tint multiplies only this layer.
## - paint: frames, glass, shutters, cornices, rails, signs — drawn in
##   their own absolute colours over the tinted wall (StandardMaterial3D
##   detail layer, MIX by alpha). A light stone tint of ~2x used to lift
##   white frames past albedo 1 and wash every facade out.
## - emit: rooms lit at night (emission map, energy from CityLights).
## Names no other project class; colours are linear like the photos.

## Share of panes lit at night, and the warm / cool interior lights.
const NIGHT_LIT := 0.42
const WARM := Color(1.0, 0.62, 0.30)
const COOL := Color(0.62, 0.72, 1.0)
## A lit room by day: a slightly warm, dim interior behind the glass.
const DAY_ROOM := Color(0.075, 0.062, 0.050)

## Transparent paint layer over `base`. Its clear pixels carry the base's
## mean colour, so mip levels blend frame edges toward the wall rather
## than toward black.
static func layer(base: Image) -> Image:
	var m := mean(base)
	var p := Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
	p.fill(Color(m.r, m.g, m.b, 0.0))
	return p

static func emit_layer(base: Image) -> Image:
	var e := Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
	e.fill(Color(0, 0, 0, 1))
	return e

## Box-average colour of `img` (repeated halving; exact for powers of 2).
static func mean(img: Image) -> Color:
	var s := img.duplicate() as Image
	s.clear_mipmaps()
	while s.get_width() > 1 or s.get_height() > 1:
		s.resize(maxi(s.get_width() / 2, 1), maxi(s.get_height() / 2, 1), Image.INTERPOLATE_BILINEAR)
	return s.get_pixel(0, 0)

## Lights a pane in the emission map when its hash falls in the lit
## share: mostly warm, some cool (screens, LEDs), dimmer toward the top.
static func pane(emit: Image, r: Rect2i, hv: float) -> void:
	if emit == null or hv < 1.0 - NIGHT_LIT:
		return
	var k := fmod(hv * 37.0, 1.0)
	var c := WARM.lerp(COOL, 0.8) if k > 0.82 else WARM.lerp(Color(1.0, 0.82, 0.55), k)
	var e := 0.55 + 0.45 * fmod(hv * 113.0, 1.0)
	emit.fill_rect(r, Color(c.r * e, c.g * e, c.b * e))
	# Curtains / ceiling: the upper part of the window glows less.
	var top := maxi(r.size.y / 4, 1)
	emit.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, top), Color(c.r * e * 0.45, c.g * e * 0.45, c.b * e * 0.45))

## Stone relief on the wall itself (cornice faces, string courses,
## rustication grooves): light or shadow blended into the base, so the
## moulding is the wall's own stone under the building's tint.
const LIGHT := Color(1.0, 0.98, 0.94, 0.30)
const SHADOW := Color(0.0, 0.0, 0.0, 0.42)

static func shade(base: Image, r: Rect2i, c: Color) -> void:
	r = r.intersection(Rect2i(0, 0, base.get_width(), base.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	var s := Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
	s.fill(c)
	base.blend_rect(s, Rect2i(Vector2i.ZERO, r.size), r.position)

## Rain streaks under a sill or ledge: soft dark runs on the wall.
static func streaks(base: Image, x0: int, x1: int, y: int, h: int, seed_v: float, strength: float = 0.16) -> void:
	h = mini(h, base.get_height() - y)
	if h <= 1 or x1 <= x0:
		return
	var run := Image.create(1, h, false, Image.FORMAT_RGBA8)
	for x in range(x0, x1, 2):
		var hv := fmod(absf(sin(float(x) * 12.9898 + seed_v * 78.233) * 43758.5453), 1.0)
		if hv < 0.45:
			continue
		var len_px := int(float(h) * (0.35 + 0.65 * hv))
		for yy in h:
			var t := float(yy) / float(len_px)
			run.set_pixel(0, yy, Color(0.06, 0.05, 0.04, strength * hv * maxf(1.0 - t, 0.0)))
		base.blend_rect(run, Rect2i(0, 0, 1, h), Vector2i(x, y))

## Final textures: albedo (base), paint (detail layer), emit, normal,
## rough and the Ultra reveal depth (from `depth_fn` over rough).
static func finish(base: Image, paint: Image, emit: Image, nor: Image, rgh: Image,
		depth_fn: Callable = Callable()) -> Dictionary:
	# Composed in linear; encode once for the sRGB-decoding samplers.
	base.linear_to_srgb()
	base.generate_mipmaps()
	var d := {"albedo": ImageTexture.create_from_image(base), "normal": null, "rough": null}
	if paint != null:
		paint.linear_to_srgb()
		paint.generate_mipmaps()
		d["paint"] = ImageTexture.create_from_image(paint)
	if emit != null:
		emit.linear_to_srgb()
		emit.generate_mipmaps()
		d["emit"] = ImageTexture.create_from_image(emit)
	if depth_fn.is_valid() and rgh != null:
		d["depth"] = depth_fn.call(rgh)
	if nor != null and rgh != null:
		nor.generate_mipmaps(true)
		rgh.generate_mipmaps()
		d["normal"] = ImageTexture.create_from_image(nor)
		d["rough"] = ImageTexture.create_from_image(rgh)
	return d
