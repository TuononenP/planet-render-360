class_name Hillshade
extends RefCounted

## Map style hillshade, baked once per Terrarium DEM tile on a worker
## thread: a 256px RGBA image of shadow and highlight colours whose alpha
## carries the shading, drawn as a plain filtered texture between the
## ground fills and the roads. Baking it beats a per-pixel shader, which
## sampled the DEM 32 times per screen pixel every frame.
##
## Lit from the north-west at 45° (Horn gradient, Lambert minus flat
## ground), as in the reference style; `strength` is the map-hillshade
## opacity at the tile's zoom.

const SIZE := 256
const GAIN := 2.5
const LIGHT := Vector3(-0.5, -0.5, 0.70710678)
const FLAT := 0.70710678

## Image (RGBA8) or null when `png` is not a Terrarium tile.
static func bake(png: PackedByteArray, mpp: float, strength: float, dark: Color, light: Color) -> Image:
	var dem := Image.new()
	if png.size() < 8 or dem.load_png_from_buffer(png) != OK:
		return null
	if dem.get_width() != SIZE or dem.get_height() != SIZE:
		return null
	dem.convert(Image.FORMAT_RGB8)
	var rgb := dem.get_data()
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	for i in SIZE * SIZE:
		h[i] = rgb[i * 3] * 256.0 + rgb[i * 3 + 1] + rgb[i * 3 + 2] / 256.0 - 32768.0
	var out := PackedByteArray()
	out.resize(SIZE * SIZE * 4)
	var d8 := [int(dark.r8), int(dark.g8), int(dark.b8)]
	var l8 := [int(light.r8), int(light.g8), int(light.b8)]
	var scale := 1.0 / (8.0 * mpp)
	for y in SIZE:
		var ym := maxi(y - 1, 0) * SIZE
		var y0 := y * SIZE
		var yp := mini(y + 1, SIZE - 1) * SIZE
		for x in SIZE:
			var xm := maxi(x - 1, 0)
			var xp := mini(x + 1, SIZE - 1)
			var dzdx := ((h[ym + xp] + 2.0 * h[y0 + xp] + h[yp + xp])
				- (h[ym + xm] + 2.0 * h[y0 + xm] + h[yp + xm])) * scale
			var dzdy := ((h[yp + xm] + 2.0 * h[yp + x] + h[yp + xp])
				- (h[ym + xm] + 2.0 * h[ym + x] + h[ym + xp])) * scale
			var s := Vector3(-dzdx, -dzdy, 1.0).normalized().dot(LIGHT) - FLAT
			var o := (y0 + x) * 4
			if s < 0.0:
				out[o] = d8[0]
				out[o + 1] = d8[1]
				out[o + 2] = d8[2]
				out[o + 3] = int(clampf(-s * GAIN, 0.0, 1.0) * strength * 255.0)
			else:
				out[o] = l8[0]
				out[o + 1] = l8[1]
				out[o + 2] = l8[2]
				out[o + 3] = int(clampf(s * GAIN, 0.0, 1.0) * strength * 0.6 * 255.0)
	return Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGBA8, out)
