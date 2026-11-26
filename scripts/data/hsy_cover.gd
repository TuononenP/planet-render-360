class_name HsyCover
extends RefCounted

## HSY's land cover 2024 surface classes for the capital region (2 m,
## laser scanning and aerial imagery, CC BY 4.0) as a ground class map
## over the detailed extent: bare rock, sealed yards and car parks, paved
## and unpaved roads, bare soil, fields, low vegetation and buildings.
## OSM says "residential block" for whole Helsinki blocks; HSY says which
## part of it is courtyard lawn, granite outcrop or asphalt.
## GroundMaterial.class_map lays it over the map's land polygons, under
## its roads and footprints. Water and trees are left out: the shoreline
## owns the water, HsyCanopy the trees.

const CREDIT := "Land cover: © HSY, land cover 2024 (CC BY 4.0)"
## Bump when LAYERS or GroundMaterial.ID change: cached rasters hold ids.
const VERSION := 1
## Layer suffix → GroundMaterial class, painted in this order (later
## wins where layers overlap at their edges).
const LAYERS := [
	["rakennus", "building"],
	["avokalliot", "rock"],
	["pellot", "field"],
	["paljas_maa", "path"],
	["paallystamaton_tie", "path"],
	["muu_avoin_matala_kasvillisuus", "grass"],
	["muu_vetta_lapaisematon_pinta", "urban"],
	["paallystetty_tie", "urban"],
]
const PREFIX := "asuminen_ja_maankaytto:maanpeite_"
const SUFFIX := "_2024"

static func covers(lat: float, lon: float) -> bool:
	return HsyCanopy.covers(lat, lon)

static func layer_name(i: int) -> String:
	return PREFIX + str(LAYERS[i][0]) + SUFFIX

static func band_url(i: int, lat: float, lon: float, size: int) -> String:
	return HsyCanopy.layer_url(layer_name(i), lat, lon, size)

## R8 class ids from the band images (alpha = present), `size` a side;
## 0 where no layer has the texel. null when a band is missing or the
## wrong size.
static func compose(bands: Array, size: int) -> Image:
	if bands.size() != LAYERS.size():
		return null
	var out := Image.create(size, size, false, Image.FORMAT_R8)
	out.fill(Color(0, 0, 0))
	var solid := Image.create(size, size, false, Image.FORMAT_R8)
	var rect := Rect2i(0, 0, size, size)
	for i in LAYERS.size():
		var b: Variant = bands[i]
		if not (b is Image) or (b as Image).get_size() != Vector2i(size, size):
			return null
		var mask := (b as Image).duplicate() as Image
		mask.convert(Image.FORMAT_RGBA8)
		solid.fill(Color(float(GroundMaterial.ID[str(LAYERS[i][1])]) / 255.0, 0, 0))
		# Native: copies the class where the band is drawn (alpha set).
		out.blit_rect_mask(solid, mask, rect, Vector2i.ZERO)
	return out

static func usable(img: Image) -> bool:
	return img != null and not img.is_empty() and img.get_format() == Image.FORMAT_R8

## Whether `data`'s class maps take its HSY classes: High / Ultra only,
## so Fast and Balanced build as they always did.
static func applies(data: LocationData) -> bool:
	return data.quality_preset >= RenderSettings.Preset.HIGH and usable(data.hsy_cover_image)

## `top` (R8, any size over the same extent, 0 = nothing) laid over
## `base`: with `replace` empty everywhere `top` has a class, else only on
## base texels whose class is in `replace`. Nearest sampling.
static var _native := ClassDB.class_exists("ImageKernels")

static func overlay(base: Image, top: Image, replace: Array) -> Image:
	if _native:
		return ClassDB.class_call_static("ImageKernels", "r8_overlay", base, top, replace) as Image
	var w := base.get_width()
	var h := base.get_height()
	var tw := top.get_width()
	var th := top.get_height()
	var out := base.get_data()
	var src := top.get_data()
	var mask := PackedByteArray()
	mask.resize(256)
	for id in replace:
		mask[int(id)] = 1
	var any := replace.is_empty()
	if tw == w and th == h:
		# Same grid (the class map's): texel for texel.
		for i in w * h:
			var v := src[i]
			if v != 0 and (any or mask[out[i]] == 1):
				out[i] = v
		return Image.create_from_data(w, h, false, Image.FORMAT_R8, out)
	for y in h:
		var sy := mini(int((float(y) + 0.5) * th / h), th - 1) * tw
		var row := y * w
		for x in w:
			var v := src[sy + mini(int((float(x) + 0.5) * tw / w), tw - 1)]
			if v != 0 and (any or mask[out[row + x]] == 1):
				out[row + x] = v
	return Image.create_from_data(w, h, false, Image.FORMAT_R8, out)
