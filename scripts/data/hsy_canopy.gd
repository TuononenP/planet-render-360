class_name HsyCanopy
extends RefCounted

## HSY's land cover 2024 tree-canopy layers for the capital region
## (Helsinki, Espoo, Vantaa, Kauniainen; laser scanning and aerial
## imagery, CC BY 4.0): four height bands (2–10, 10–15, 15–20, >20 m)
## read from the open WMS as transparent PNGs on LandcoverFetcher's
## canopy grid. `compose` turns them into its L8 canopy-height raster
## (metres; 0 = measured open ground): HSY says where trees stand and
## how tall a band, Meta's CHM (when present) the height within it.

const URL := "https://kartta.hsy.fi/geoserver/wms"
const LAYERS := [
	"asuminen_ja_maankaytto:maanpeite_puusto_2_10m_2024",
	"asuminen_ja_maankaytto:maanpeite_puusto_10_15m_2024",
	"asuminen_ja_maankaytto:maanpeite_puusto_15_20m_2024",
	"asuminen_ja_maankaytto:maanpeite_puusto_yli20m_2024",
]
## Band limits (m) and the height used when no CHM refines it.
const BAND_LO := [2, 10, 15, 20]
const BAND_HI := [10, 15, 20, 32]
const BAND_MID := [6, 12, 17, 24]
## Layer extent (lat_min, lat_max, lon_min, lon_max).
const BBOX := [59.926, 60.516, 24.286, 25.255]
const CREDIT := "Tree canopy: © HSY, land cover 2024 (CC BY 4.0)"
const NO_DATA := 255

## Whether the whole canopy window round (lat, lon) lies in the layer.
static func covers(lat: float, lon: float) -> bool:
	var half := LandcoverFetcher.EXTENT_M * 0.5
	var dlat := half / 110540.0
	var dlon := half / (111320.0 * cos(deg_to_rad(lat)))
	return lat - dlat >= float(BBOX[0]) and lat + dlat <= float(BBOX[1]) \
		and lon - dlon >= float(BBOX[2]) and lon + dlon <= float(BBOX[3])

## GetMap URL of band `i` over LandcoverFetcher's window (WMS 1.3.0
## EPSG:4326 axes are lat, lon), `size` pixels a side: the same edges, so
## pixel centres match plan_window's.
static func band_url(i: int, lat: float, lon: float, size: int) -> String:
	var half := LandcoverFetcher.EXTENT_M * 0.5
	var dlat := half / 110540.0
	var dlon := half / (111320.0 * cos(deg_to_rad(lat)))
	return "%s?service=WMS&version=1.3.0&request=GetMap&layers=%s&styles=&crs=EPSG:4326&format=image/png&transparent=true&width=%d&height=%d&bbox=%.7f,%.7f,%.7f,%.7f" % [
		URL, LAYERS[i], size, size, lat - dlat, lon - dlon, lat + dlat, lon + dlon]

## L8 canopy heights from the four band images (any format, `size` a
## side, alpha = canopy) and an optional CHM (L8 metres, 255 no data).
## null when a band is missing or the wrong size.
static func compose(bands: Array, chm: Image, size: int) -> Image:
	if bands.size() != LAYERS.size():
		return null
	var alpha: Array = []
	for b in bands:
		if not (b is Image) or (b as Image).get_size() != Vector2i(size, size):
			return null
		var img := (b as Image).duplicate() as Image
		img.convert(Image.FORMAT_RGBA8)
		alpha.append(img.get_data())
	var refine := PackedByteArray()
	if chm != null and chm.get_size() == Vector2i(size, size) and chm.get_format() == Image.FORMAT_L8:
		refine = chm.get_data()
	var out := PackedByteArray()
	out.resize(size * size)
	for p in size * size:
		var band := -1
		for i in range(LAYERS.size() - 1, -1, -1):
			if (alpha[i] as PackedByteArray)[p * 4 + 3] > 127:
				band = i
				break
		if band < 0:
			out[p] = 0
			continue
		var h: int = BAND_MID[band]
		if not refine.is_empty() and refine[p] != NO_DATA and refine[p] > 0:
			h = clampi(refine[p], BAND_LO[band], BAND_HI[band])
		out[p] = h
	return Image.create_from_data(size, size, false, Image.FORMAT_L8, out)
