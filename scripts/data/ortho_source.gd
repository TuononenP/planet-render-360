class_name OrthoSource
extends RefCounted

## City aerial orthophotos for the inner ground mosaic (InnerImagery):
## HSY's capital-region orthophoto 2023 (Helsinki, Espoo, Vantaa,
## Kauniainen; CC BY 4.0) from its open WMS, asked for in web mercator
## on the slippy-tile pixel grid so GroundMaterial.inner_map stays exact.
## Up to z19 (≈0.15 m/px at 60°N) where Esri stops at z18.

const SOURCES := {
	"hsy_2023": {
		"url": "https://kartta.hsy.fi/geoserver/wms",
		"layer": "taustakartat_ja_aluejaot:Ortoilmakuva_2023",
		# Layer extent (lat_min, lat_max, lon_min, lon_max).
		"bbox": [59.905, 60.605, 24.253, 25.373],
		"credit": "Aerial imagery: © HSY, orthophoto 2023 (CC BY 4.0)",
	},
}
const DEFAULT := "hsy_2023"
## Largest WMS GetMap side asked for (GeoServer's default cap is 2048).
const MAX_PART_PX := 1920
const TILE_PX := 256
## Spherical-mercator half circumference (m).
const HALF_C := PI * 6378137.0
## A part whose every channel varies less than this is the server's
## blank fill past the data, not imagery.
const BLANK_STD := 2.0 / 255.0

## The source for a mosaic at (lat, lon) of span tiles at zoom, "" none.
static func source_for(lat: float, lon: float, zoom: int, span: int) -> String:
	var src: Dictionary = SOURCES[DEFAULT]
	var bb: Array = src["bbox"]
	# The mosaic's half width in degrees, so the whole of it is covered.
	var half_m := SatelliteFetcher.metres_per_px(lat, zoom) * float(span * TILE_PX) * 0.5
	var dlat := half_m / 110540.0
	var dlon := half_m / (111320.0 * cos(deg_to_rad(lat)))
	if lat - dlat < float(bb[0]) or lat + dlat > float(bb[1]) \
			or lon - dlon < float(bb[2]) or lon + dlon > float(bb[3]):
		return ""
	return DEFAULT

## Parts per side for a mosaic of `size_px` (each ≤ MAX_PART_PX).
static func parts_for(size_px: int) -> int:
	return ceili(float(size_px) / float(MAX_PART_PX))

## EPSG:3857 (min x, min y, max x, max y) of a global-pixel rectangle at
## `zoom` (slippy-tile pixels, y down).
static func bbox_3857(origin_px: Vector2, size_px: Vector2, zoom: int) -> PackedFloat64Array:
	var world := float(TILE_PX) * pow(2.0, float(zoom))
	var x0 := origin_px.x / world * 2.0 * HALF_C - HALF_C
	var x1 := (origin_px.x + size_px.x) / world * 2.0 * HALF_C - HALF_C
	var y0 := HALF_C - (origin_px.y + size_px.y) / world * 2.0 * HALF_C
	var y1 := HALF_C - origin_px.y / world * 2.0 * HALF_C
	return PackedFloat64Array([x0, y0, x1, y1])

## GetMap URL of one part (WMS 1.3.0; EPSG:3857 axes are x, y).
static func part_url(src: String, origin_px: Vector2, part_px: int, zoom: int) -> String:
	var s: Dictionary = SOURCES[src]
	var bb := bbox_3857(origin_px, Vector2(part_px, part_px), zoom)
	return "%s?service=WMS&version=1.3.0&request=GetMap&layers=%s&styles=&crs=EPSG:3857&format=image/jpeg&width=%d&height=%d&bbox=%.3f,%.3f,%.3f,%.3f" % [
		s["url"], s["layer"], part_px, part_px, bb[0], bb[1], bb[2], bb[3]]

static func credit(src: String) -> String:
	return str((SOURCES.get(src, {}) as Dictionary).get("credit", ""))

## Whether `img` is blank fill (no data there): flat in every channel.
static func is_blank(img: Image) -> bool:
	if img == null or img.is_empty():
		return true
	var small := img.duplicate() as Image
	small.resize(32, 32, Image.INTERPOLATE_BILINEAR)
	var stats := channel_stats(small)
	var std: Vector3 = stats[1]
	return std.x < BLANK_STD and std.y < BLANK_STD and std.z < BLANK_STD

## Per-channel (mean, std) of an image's pixels, in linear colour.
static func channel_stats(img: Image) -> Array:
	var sum := Vector3.ZERO
	var sq := Vector3.ZERO
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y).srgb_to_linear()
			var v := Vector3(c.r, c.g, c.b)
			sum += v
			sq += v * v
			n += 1
	if n == 0:
		return [Vector3.ZERO, Vector3.ZERO]
	var mean := sum / float(n)
	var var3 := sq / float(n) - mean * mean
	return [mean, Vector3(sqrt(maxf(var3.x, 0.0)), sqrt(maxf(var3.y, 0.0)), sqrt(maxf(var3.z, 0.0)))]

## Gain / bias (linear, per channel) taking `inner`'s colour statistics
## onto `reference`'s (the main mosaic over the same ground), so the
## sharper photo blends in at its edge. Gain clamps to 0.7–1.4.
static func colour_match(inner: Image, reference: Image) -> Dictionary:
	var a := channel_stats(inner)
	var b := channel_stats(reference)
	var gain := Vector3.ONE
	var bias := Vector3.ZERO
	for i in 3:
		var sa: float = (a[1] as Vector3)[i]
		var sb: float = (b[1] as Vector3)[i]
		var g := clampf(sb / sa if sa > 1e-4 else 1.0, 0.7, 1.4)
		gain[i] = g
		bias[i] = clampf((b[0] as Vector3)[i] - g * (a[0] as Vector3)[i], -0.15, 0.15)
	return {"gain": gain, "bias": bias}
