class_name RoofMetalMaps
extends RefCounted

## Standing folds over the bundled metal grain. RoofGeometry puts U along
## the eave and V down the slope, so the folds run from ridge to gutter.
## One 3.6 m repeat holds six 0.6 m pans; no extra roof mesh or draw call.
const REPEAT_M := 3.6
const PANS := 6
const FOLD_HEIGHT_M := 0.018
const FOLD_SIGMA_M := 0.006

## Paint covers the source metal's blue oxidation patches; retain a
## little grain as weathering rather than tinting a mottled bare plate.
static func paint(img: Image) -> void:
	img.adjust_bcs(1.0, 0.25, 0.0)

static func normals(source: Image) -> Image:
	var img := source.duplicate() as Image
	if img.get_width() > 1024:
		img.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	var pitch := REPEAT_M / float(PANS)
	for x in img.get_width():
		var u := float(x) / float(img.get_width() - 1) * REPEAT_M
		var d := wrapf(u, -pitch * 0.5, pitch * 0.5)
		var slope := -FOLD_HEIGHT_M * d / (FOLD_SIGMA_M * FOLD_SIGMA_M) \
			* exp(-0.5 * d * d / (FOLD_SIGMA_M * FOLD_SIGMA_M))
		if absf(slope) < 0.001:
			continue
		for y in img.get_height():
			var c := img.get_pixel(x, y)
			var n := Vector3(c.r * 2.0 - 1.0, c.g * 2.0 - 1.0, maxf(c.b * 2.0 - 1.0, 0.1))
			n.x -= slope * n.z
			n = n.normalized()
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return img
