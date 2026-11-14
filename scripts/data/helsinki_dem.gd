class_name HelsinkiDem
extends RefCounted

## The City of Helsinki elevation model (Korkeusmalli 2021, a 1 m bare-earth
## model from airborne laser scanning, N2000 heights, CC BY 4.0), read from
## the city's open WCS. It replaces the Terrarium heights of a world inside
## Helsinki: Terrarium is ArcticDEM there, a surface model in ellipsoidal
## heights (roofs and tree crowns in the terrain, the sea 17 m up), which
## BareEarth and CoastalDem can only approximate away.
##
## A window around the viewpoint comes back as one GeoTIFF (big-endian,
## float32, uncompressed) resampled by the server to ~4.8 m cells.
## HelsinkiDemFetcher downloads it; `decode` reads it, `apply` resamples it
## onto the heights grid GroundTruth reads, so everything else (datum,
## shoreline, buildings) works on the data unchanged.

const URL := "https://kartta.hel.fi/ws/geoserver/avoindata/wcs"
const COVERAGE := "avoindata__Korkeusmalli_2021_1m"
const CREDIT := "Elevation: © City of Helsinki, Elevation model 2021 (CC BY 4.0)"
## The coverage's extent in EPSG:3879 (ETRS-GK25), metres.
const MIN_E := 25487000.0
const MAX_E := 25516000.0
const MIN_N := 6655000.0
const MAX_N := 6690000.0
## Half width of the requested window: past the z14 heights window
## (576 px, ~2.75 km) and the 2.4 km detailed extent.
const HALF_M := 1450.0
const CELLS := 600
const NODATA := -32767.0
## A window with more missing cells than this is mostly outside the city's
## data (Espoo, Vantaa, open sea): Terrarium stays. Smaller gaps (a window
## reaching over the city border) take the Terrarium heights (apply).
const MAX_MISSING := 0.25

## ETRS-GK25 (E, N) of a WGS84 position (Gk25).
static func gk25(lat: float, lon: float) -> Vector2:
	return Gk25.from_latlon(lat, lon)

## Whether the whole request window around (lat, lon) lies in the coverage.
static func covers(lat: float, lon: float) -> bool:
	if lat < 60.0 or lat > 60.4 or lon < 24.5 or lon > 25.3:
		return false
	var p := gk25(lat, lon)
	return p.x - HALF_M >= MIN_E and p.x + HALF_M <= MAX_E \
		and p.y - HALF_M >= MIN_N and p.y + HALF_M <= MAX_N

## The GetCoverage URL for the window around (lat, lon), grid-snapped to
## whole metres so the same place always asks for the same bytes.
## `half_m` / `cells` size the window (DemRelief asks for a finer one).
static func request_url(lat: float, lon: float, half_m: float = HALF_M, cells: int = CELLS) -> String:
	var c := window_centre(lat, lon)
	return "%s?service=WCS&version=2.0.1&request=GetCoverage&coverageId=%s&format=image/tiff" \
		% [URL, COVERAGE] + "&subset=E(%d,%d)&subset=N(%d,%d)&scaleSize=i(%d),j(%d)" % [
		int(c.x - half_m), int(c.x + half_m), int(c.y - half_m), int(c.y + half_m), cells, cells]

## The whole-metre (E, N) a window round (lat, lon) is centred on.
static func window_centre(lat: float, lon: float) -> Vector2i:
	var p := gk25(lat, lon)
	return Vector2i(int(roundf(p.x)), int(roundf(p.y)))

## Reads a GeoServer GeoTIFF (big-endian or little-endian, float32,
## uncompressed, tiled or in strips) into {size, values, origin, cell}:
## `origin` is the (E, N) of the top-left corner, `cell` the (E, N) size of
## one cell with N positive down. {} when the bytes are anything else.
static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < 16:
		return {}
	var big := bytes[0] == 0x4D and bytes[1] == 0x4D
	if not big and not (bytes[0] == 0x49 and bytes[1] == 0x49):
		return {}
	var sp := StreamPeerBuffer.new()
	sp.data_array = bytes
	sp.big_endian = big
	sp.seek(4)
	var ifd := sp.get_u32()
	if ifd < 8 or ifd + 2 > bytes.size():
		return {}
	sp.seek(ifd)
	var count := sp.get_u16()
	var tags := {}
	for i in count:
		sp.seek(ifd + 2 + i * 12)
		var tag := sp.get_u16()
		var type := sp.get_u16()
		var n := sp.get_u32()
		var width := {3: 2, 4: 4, 12: 8}.get(type, 0) as int
		if width == 0 or n > 100000:
			continue
		var at := ifd + 2 + i * 12 + 8
		if width * n > 4:
			sp.seek(at)
			at = sp.get_u32()
		if at + width * n > bytes.size():
			return {}
		sp.seek(at)
		var vals: Array = []
		for k in n:
			vals.append(sp.get_u16() if type == 3 else (sp.get_u32() if type == 4 else sp.get_double()))
		tags[tag] = vals
	var w := int(_one(tags, 256))
	var h := int(_one(tags, 257))
	if w <= 0 or h <= 0 or w * h > 4000000 or int(_one(tags, 258)) != 32 \
			or int(_one(tags, 339)) != 3 or int(_one(tags, 259, 1)) != 1 \
			or int(_one(tags, 277, 1)) != 1 or not (tags.has(34264) or (tags.has(33550) and tags.has(33922))):
		return {}
	var out := PackedFloat32Array()
	out.resize(w * h)
	var tiled := tags.has(324)
	var offsets: Array = tags.get(324 if tiled else 273, [])
	var tw := int(_one(tags, 322)) if tiled else w
	var th := int(_one(tags, 323)) if tiled else int(_one(tags, 278, h))
	if offsets.is_empty() or tw <= 0 or th <= 0:
		return {}
	var across := ceili(float(w) / float(tw))
	for idx in offsets.size():
		var x0 := (idx % across) * tw if tiled else 0
		var y0 := (idx / across) * th if tiled else idx * th
		var rows := mini(th, h - y0)
		if rows <= 0:
			continue
		var start := int(offsets[idx])
		if start + tw * (th if tiled else rows) * 4 > bytes.size():
			return {}
		sp.seek(start)
		for r in rows:
			for c in tw:
				var v := sp.get_float()
				if x0 + c < w:
					out[(y0 + r) * w + x0 + c] = v
	# GeoServer writes a ModelTransformation matrix; other writers a pixel
	# scale and a tiepoint.
	if tags.has(34264) and (tags[34264] as Array).size() >= 8:
		var m: Array = tags[34264]
		if float(m[0]) <= 0.0 or float(m[5]) >= 0.0:
			return {}
		return {"size": Vector2i(w, h), "values": out,
			"origin": Vector2(float(m[3]), float(m[7])), "cell": Vector2(float(m[0]), -float(m[5]))}
	var scale: Array = tags[33550]
	var tie: Array = tags[33922]
	if scale.size() < 2 or tie.size() < 6 or float(scale[0]) <= 0.0 or float(scale[1]) <= 0.0:
		return {}
	return {"size": Vector2i(w, h), "values": out,
		"origin": Vector2(float(tie[3]) - float(tie[0]) * float(scale[0]),
			float(tie[4]) + float(tie[1]) * float(scale[1])),
		"cell": Vector2(float(scale[0]), float(scale[1]))}

static func _one(tags: Dictionary, tag: int, fallback: float = 0.0) -> float:
	var v: Array = tags.get(tag, [])
	return float(v[0]) if not v.is_empty() else fallback

## Bilinear height (metres, N2000) at (E, N), NAN outside the raster or on
## a missing cell. Cell values sit at cell centres.
static func sample(raster: Dictionary, e: float, n: float) -> float:
	var size: Vector2i = raster["size"]
	var origin: Vector2 = raster["origin"]
	var cell: Vector2 = raster["cell"]
	var fx := (e - origin.x) / cell.x - 0.5
	var fy := (origin.y - n) / cell.y - 0.5
	if fx < 0.0 or fy < 0.0 or fx > float(size.x - 1) or fy > float(size.y - 1):
		return NAN
	var x0 := mini(int(fx), size.x - 2)
	var y0 := mini(int(fy), size.y - 2)
	var tx := fx - float(x0)
	var ty := fy - float(y0)
	var v: PackedFloat32Array = raster["values"]
	var a := v[y0 * size.x + x0]
	var b := v[y0 * size.x + x0 + 1]
	var c := v[(y0 + 1) * size.x + x0]
	var d := v[(y0 + 1) * size.x + x0 + 1]
	if a <= NODATA + 1.0 or b <= NODATA + 1.0 or c <= NODATA + 1.0 or d <= NODATA + 1.0:
		# A missing corner: the mean of the others, NAN when all are missing.
		var sum := 0.0
		var have := 0
		for q in [a, b, c, d]:
			if q > NODATA + 1.0:
				sum += q
				have += 1
		return sum / float(have) if have > 0 else NAN
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)

## Share of the raster's cells without a height.
static func missing_share(raster: Dictionary) -> float:
	var v: PackedFloat32Array = raster["values"]
	var missing := 0
	for h in v:
		if h <= NODATA + 1.0:
			missing += 1
	return float(missing) / float(maxi(v.size(), 1))

## Lat/lon of heights-grid index (gx, gz): the inverse of
## DemRegistration.grid_index, at the heights window DemFetcher sampled.
static func grid_latlon(data: LocationData, gx: float, gz: float) -> Vector2:
	var zoom := int(data.dem_source.get("source_zoom", 0))
	var grid := data.grid_size
	var step_px := DemRegistration.window_px(data) / float(maxi(grid, 1))
	var centre := DemRegistration._px(data.latitude, data.longitude, zoom)
	var px := centre + Vector2((gx - float(grid) * 0.5) * step_px + 0.5,
		(gz - float(grid) * 0.5) * step_px + 0.5)
	var n := float(1 << zoom) * 256.0
	return Vector2(rad_to_deg(atan(sinh(PI * (1.0 - 2.0 * px.y / n)))), px.x / n * 360.0 - 180.0)

## Replaces `data.heights` with the model's heights, in place and only when
## the whole grid resolves; marks `dem_source` so BareEarth leaves a
## bare-earth model alone. Run after CoastalDem.correct, which still needs
## the Terrarium heights to register the far rings against the sea.
static func apply(data: LocationData) -> bool:
	var raster: Dictionary = data.ground_model
	if raster.is_empty() or data.dem_source.get("ground_model", "") == "" \
			or not DemRegistration.applies(data):
		return false
	var grid := data.grid_size
	var heights := PackedFloat32Array()
	heights.resize(grid * grid)
	var mn := INF
	var mx := -INF
	for z in grid:
		for x in grid:
			var ll := grid_latlon(data, float(x), float(z))
			var p := gk25(ll.x, ll.y)
			var h := sample(raster, p.x, p.y)
			if is_nan(h):
				# Past the raster (the corners of a wide window): the nearest
				# resolved value, never the Terrarium datum.
				h = sample(raster, clampf(p.x, float(raster["origin"].x) + 5.0,
						float(raster["origin"].x) + float(raster["size"].x) * float(raster["cell"].x) - 5.0),
					clampf(p.y, float(raster["origin"].y) - float(raster["size"].y) * float(raster["cell"].y) + 5.0,
						float(raster["origin"].y) - 5.0))
				if is_nan(h):
					# A gap inside the window (past the city border): the
					# Terrarium height there, already sea-corrected.
					h = data.heights[z * grid + x] if data.heights.size() == grid * grid else NAN
				if is_nan(h):
					return false
			heights[z * grid + x] = h
			mn = minf(mn, h)
			mx = maxf(mx, h)
	data.heights = heights
	data.centre_elevation_m = heights[(grid / 2) * grid + grid / 2]
	data.relief_metres = mx - mn
	if not is_equal_approx(data.water_level, -3.0):
		data.water_level = WaterBuilder.SEA_LEVEL_M
	return true
