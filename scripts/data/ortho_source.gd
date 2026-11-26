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
		"format": "image/jpeg",
		# Layer extent (lat_min, lat_max, lon_min, lon_max).
		"bbox": [59.905, 60.605, 24.253, 25.373],
		"credit": "Aerial imagery: © HSY, orthophoto 2023 (CC BY 4.0)",
	},
	"turku_2025": {
		"url": "https://turku.asiointi.fi/TeklaOGCWeb/WMS.ashx",
		"layer": "Ilmakuva 2025",
		"format": "image/png",
		# Layer extent (lat_min, lat_max, lon_min, lon_max) covering Turku.
		"bbox": [60.36, 60.54, 22.08, 22.42],
		"credit": "Aerial imagery: © City of Turku, orthophoto 2025 (CC BY 4.0)",
	},
}
const DEFAULT := "hsy_2023"
## Largest WMS GetMap side asked for (GeoServer's default cap is 2048).
const MAX_PART_PX := 1920
const TILE_PX := 256
## Spherical-mercator half circumference (m).
const HALF_C := PI * 6378137.0
## A part whose sRGB channels vary less than this across point samples is
## the server's flat nodata fill past coverage, not dark water imagery.
const BLANK_SRGB_STD := 1.2 / 255.0

## The source for a mosaic at (lat, lon) of span tiles at zoom, "" none.
static func source_for(lat: float, lon: float, zoom: int, span: int) -> String:
	# The mosaic's half width in degrees, so the whole of it is covered.
	var half_m := SatelliteFetcher.metres_per_px(lat, zoom) * float(span * TILE_PX) * 0.5
	var dlat := half_m / 110540.0
	var dlon := half_m / (111320.0 * cos(deg_to_rad(lat)))
	for key in SOURCES:
		var src: Dictionary = SOURCES[key]
		var bb: Array = src["bbox"]
		if lat - dlat >= float(bb[0]) and lat + dlat <= float(bb[1]) \
				and lon - dlon >= float(bb[2]) and lon + dlon <= float(bb[3]):
			return str(key)
	return ""

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
	var layer := str(s["layer"]).replace(" ", "%20")
	var fmt := str(s.get("format", "image/jpeg"))
	return "%s?service=WMS&version=1.3.0&request=GetMap&layers=%s&styles=&crs=EPSG:3857&format=%s&width=%d&height=%d&bbox=%.3f,%.3f,%.3f,%.3f" % [
		s["url"], layer, fmt, part_px, part_px, bb[0], bb[1], bb[2], bb[3]]

static func credit(src: String) -> String:
	return str((SOURCES.get(src, {}) as Dictionary).get("credit", ""))

## Whether `img` is blank fill (no data there): flat in every sRGB channel.
## Point-sampled in sRGB without box-blurring or linearising, so dark coastal
## water ripples are never mistaken for pure white/black WMS nodata fill.
static func is_blank(img: Image) -> bool:
	if img == null or img.is_empty():
		return true
	var w := img.get_width()
	var h := img.get_height()
	var sx := maxi(1, w / 64)
	var sy := maxi(1, h / 64)
	var sum := Vector3.ZERO
	var sq := Vector3.ZERO
	var n := 0
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			var c := img.get_pixel(x, y)
			var v := Vector3(c.r, c.g, c.b)
			sum += v
			sq += v * v
			n += 1
			x += sx
		y += sy
	if n <= 1:
		return true
	var mean := sum / float(n)
	var var3 := sq / float(n) - mean * mean
	return sqrt(maxf(var3.x, 0.0)) < BLANK_SRGB_STD \
		and sqrt(maxf(var3.y, 0.0)) < BLANK_SRGB_STD \
		and sqrt(maxf(var3.z, 0.0)) < BLANK_SRGB_STD

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
