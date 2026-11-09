class_name GroundModel
extends RefCounted

## National bare-earth elevation models that replace the Terrarium heights
## of a world inside their country. Terrarium is SRTM / EU-DEM class data
## away from US lidar: a surface model with roofs and tree crowns in it
## (Shibuya: +10 m on average and up to +62 m against the GSI bare-earth
## DEM, every block a hill the streets run between). Each source here is
## keyless and answers in a form that reduces to one raster in Web
## Mercator metres, {size, values, origin, cell}: `origin` is the top-left
## corner, `cell` the cell size (both positive, y down), NAN where the
## source has no height. GroundModelFetcher downloads and decodes; `apply`
## resamples a raster onto the heights grid GroundTruth reads, so the
## datum, shoreline, roads and buildings work on it unchanged.
## HelsinkiDem does the same for Helsinki in its own projection.

## Elevation sources by id: the credit shown in the app.
const SOURCES := {
	"gsi": "Elevation: Geospatial Information Authority of Japan, DEM5A / DEM10B",
	"ign": "Elevation: © IGN, RGE ALTI (Licence Ouverte)",
	"ahn": "Elevation: AHN DTM, Rijkswaterstaat (CC0)",
	"swisstopo": "Elevation: © swisstopo, swissALTI3D (Open Government Data)",
}
## Ground half-width of the window requested around the viewpoint: the
## 2.4 km detailed extent with a margin, like HelsinkiDem.HALF_M.
const HALF_M := 1450.0
## Cells across a window of the sources that answer one raster.
const CELLS := 300
## A raster missing more of its cells than this has no data here (outside
## the country, open sea). AHN leaves holes under every building and over
## water, so dense city centres are 40–50 % missing and still usable.
const MAX_MISSING := 0.75
const MERC_R := 6378137.0
## Source heights outside this range are no-data markers.
const MIN_VALID := -1000.0
const MAX_VALID := 9000.0

## Coarse country outlines (lon, lat). The fetcher still checks the answer,
## so an edge city only costs a request.
const _JAPAN: Array = [
	[129.45, 30.0, 146.0, 45.7],
	[122.9, 24.0, 131.5, 28.6],
]
const _CORSICA := [8.4, 41.3, 9.7, 43.1]
const _FRANCE := [Vector2(-4.8, 48.5), Vector2(-1.3, 49.7), Vector2(2.5, 51.1),
	Vector2(4.2, 50.0), Vector2(5.8, 49.5), Vector2(8.2, 49.0), Vector2(7.6, 47.6),
	Vector2(6.9, 47.3), Vector2(6.1, 46.3), Vector2(7.0, 45.9), Vector2(7.7, 44.1),
	Vector2(7.5, 43.7), Vector2(3.2, 42.4), Vector2(1.7, 42.5), Vector2(-1.8, 43.3),
	Vector2(-1.3, 45.5), Vector2(-2.2, 47.2)]
const _NETHERLANDS := [Vector2(3.30, 51.55), Vector2(3.35, 51.30), Vector2(3.85, 51.20),
	Vector2(4.25, 51.40), Vector2(4.45, 51.48), Vector2(5.0, 51.45), Vector2(5.05, 51.30),
	Vector2(5.55, 51.30), Vector2(5.80, 51.10), Vector2(5.75, 50.75), Vector2(6.05, 50.75),
	Vector2(6.10, 50.90), Vector2(6.40, 51.15), Vector2(6.15, 51.85), Vector2(6.85, 51.97),
	Vector2(7.10, 52.25), Vector2(7.05, 52.65), Vector2(7.25, 53.2), Vector2(6.9, 53.4),
	Vector2(5.0, 53.55), Vector2(4.7, 53.1), Vector2(4.5, 52.6), Vector2(3.9, 52.0)]

## Test hook: false leaves every place on Terrarium (a truth comparison
## builds both worlds).
static var enabled := true

# England, where Terrarium already carries the Environment Agency's lidar
# terrain model, and Switzerland.
const _ENGLAND := [Vector2(-5.75, 49.95), Vector2(-4.2, 50.3), Vector2(-3.5, 50.2),
	Vector2(-2.5, 50.55), Vector2(-1.5, 50.7), Vector2(-0.8, 50.7), Vector2(0.8, 50.8),
	Vector2(1.5, 51.1), Vector2(1.45, 51.4), Vector2(1.75, 52.0), Vector2(1.8, 52.7),
	Vector2(0.3, 52.95), Vector2(0.15, 53.6), Vector2(-0.1, 54.1), Vector2(-0.8, 54.5),
	Vector2(-1.4, 54.9), Vector2(-1.6, 55.6), Vector2(-2.0, 55.82), Vector2(-2.6, 55.3),
	Vector2(-3.05, 55.05), Vector2(-3.5, 54.9), Vector2(-3.6, 54.4), Vector2(-3.3, 54.0),
	Vector2(-3.1, 53.6), Vector2(-3.1, 53.3), Vector2(-2.95, 53.0), Vector2(-3.1, 52.5),
	Vector2(-3.05, 52.0), Vector2(-2.8, 51.6), Vector2(-3.0, 51.3), Vector2(-3.2, 51.2),
	Vector2(-4.2, 51.2), Vector2(-5.2, 50.2)]
const _SWITZERLAND := [Vector2(5.95, 46.15), Vector2(6.1, 46.6), Vector2(6.9, 47.35),
	Vector2(7.55, 47.6), Vector2(8.4, 47.62), Vector2(9.5, 47.55), Vector2(9.6, 47.1),
	Vector2(10.5, 46.9), Vector2(10.45, 46.5), Vector2(9.3, 46.3), Vector2(9.05, 45.82),
	Vector2(8.4, 45.9), Vector2(7.0, 45.95)]

## True in England: Terrarium's heights there are the Environment Agency's
## bare-earth lidar DTM (roads within about 1 m of it in London, Manchester
## and Birmingham), so no building filter or replacement is wanted.
static func in_england(lat: float, lon: float) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(lon, lat), PackedVector2Array(_ENGLAND))

## The source id covering (lat, lon), "" where Terrarium stays.
static func source_for(lat: float, lon: float) -> String:
	if not enabled:
		return ""
	for box in _JAPAN:
		if lon >= box[0] and lat >= box[1] and lon <= box[2] and lat <= box[3]:
			return "gsi"
	var p := Vector2(lon, lat)
	# Before France: Geneva sits inside France's coarse outline.
	if Geometry2D.is_point_in_polygon(p, PackedVector2Array(_SWITZERLAND)):
		return "swisstopo"
	if lon >= _CORSICA[0] and lat >= _CORSICA[1] and lon <= _CORSICA[2] and lat <= _CORSICA[3] \
			or Geometry2D.is_point_in_polygon(p, PackedVector2Array(_FRANCE)):
		return "ign"
	if Geometry2D.is_point_in_polygon(p, PackedVector2Array(_NETHERLANDS)):
		return "ahn"
	return ""

## Web Mercator metres of lat/lon.
static func merc(lat: float, lon: float) -> Vector2:
	return Vector2(MERC_R * deg_to_rad(lon), MERC_R * asinh(tan(deg_to_rad(lat))))

## Half width, in Mercator metres, of the window around a viewpoint at
## `lat`: the ground half width stretched by the projection.
static func half_merc(lat: float) -> float:
	return ceilf(HALF_M / cos(deg_to_rad(lat)))

## The raster of a national-grid source resampled to the Web Mercator
## window every other source answers in (`window`: {"c": centre, "half":
## half width}, `cells` across). `src` is {size, values, origin, cell} in the
## grid's own units (NAN for no data); `native` maps (lat, lon) to the
## grid's (x, y).
static func reproject(src: Dictionary, native: Callable, window: Dictionary, cells: int = CELLS) -> Dictionary:
	var c: Vector2 = window["c"]
	var half: float = window["half"]
	var cell := 2.0 * half / float(cells)
	var values := PackedFloat32Array()
	values.resize(cells * cells)
	for r in cells:
		var y := c.y + half - (float(r) + 0.5) * cell
		var lat := rad_to_deg(atan(sinh(y / MERC_R)))
		for q in cells:
			var x := c.x - half + (float(q) + 0.5) * cell
			var at: Vector2 = native.call(lat, rad_to_deg(x / MERC_R))
			values[r * cells + q] = sample_raw(src, at.x, at.y)
	return {"size": Vector2i(cells, cells), "values": values,
		"origin": Vector2(c.x - half, c.y + half), "cell": Vector2(cell, cell)}

## Bilinear height at (x, y) in the raster's own units, NAN outside it or
## where the corners have no data (some corners missing: the mean of the
## others). Cell values sit at cell centres.
static func sample_raw(raster: Dictionary, x: float, y: float) -> float:
	var size: Vector2i = raster["size"]
	var origin: Vector2 = raster["origin"]
	var cell: Vector2 = raster["cell"]
	var fx := (x - origin.x) / cell.x - 0.5
	var fy := (origin.y - y) / cell.y - 0.5
	if fx < -0.5 or fy < -0.5 or fx > float(size.x) - 0.5 or fy > float(size.y) - 0.5:
		return NAN
	fx = clampf(fx, 0.0, float(size.x - 1))
	fy = clampf(fy, 0.0, float(size.y - 1))
	var x0 := mini(int(fx), size.x - 2)
	var y0 := mini(int(fy), size.y - 2)
	var tx := fx - float(x0)
	var ty := fy - float(y0)
	var v: PackedFloat32Array = raster["values"]
	var a := v[y0 * size.x + x0]
	var b := v[y0 * size.x + x0 + 1]
	var d := v[(y0 + 1) * size.x + x0]
	var e := v[(y0 + 1) * size.x + x0 + 1]
	if is_nan(a) or is_nan(b) or is_nan(d) or is_nan(e):
		var sum := 0.0
		var have := 0
		for q in [a, b, d, e]:
			if not is_nan(q):
				sum += q
				have += 1
		return sum / float(have) if have > 0 else NAN
	return lerpf(lerpf(a, b, tx), lerpf(d, e, tx), ty)

## One height of a WMS BIL answer (little-endian float32) or NAN.
static func decode_bil(bytes: PackedByteArray, size: int, origin: Vector2, cell: float) -> Dictionary:
	if bytes.size() != size * size * 4:
		return {}
	var values := PackedFloat32Array()
	values.resize(size * size)
	for i in size * size:
		values[i] = valid_height(bytes.decode_float(i * 4))
	return {"size": Vector2i(size, size), "values": values, "origin": origin,
		"cell": Vector2(cell, cell)}

## Heights of one GSI DEM PNG tile (256 × 256): 24 bits in R, G, B in
## centimetres, 2^23 = no data, two's complement below zero. Empty when
## the bytes are not that PNG.
static func decode_gsi_png(bytes: PackedByteArray) -> PackedFloat32Array:
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK or img.get_width() != 256 or img.get_height() != 256:
		return PackedFloat32Array()
	img.convert(Image.FORMAT_RGB8)
	var px := img.get_data()
	var out := PackedFloat32Array()
	out.resize(256 * 256)
	for i in 256 * 256:
		var v: int = (px[i * 3] << 16) | (px[i * 3 + 1] << 8) | px[i * 3 + 2]
		if v == 0x800000:
			out[i] = NAN
		else:
			out[i] = valid_height(float(v if v < 0x800000 else v - 0x1000000) * 0.01)
	return out

## `h`, or NAN when it is a source's no-data marker.
static func valid_height(h: float) -> float:
	return h if h >= MIN_VALID and h <= MAX_VALID else NAN

## Share of the raster's cells without a height.
static func missing_share(raster: Dictionary) -> float:
	var v: PackedFloat32Array = raster["values"]
	var missing := 0
	for h in v:
		if is_nan(h):
			missing += 1
	return float(missing) / float(maxi(v.size(), 1))

## Gives every missing cell the mean of its resolved 4-neighbours, a ring
## at a time, so a hole under a block or a canal takes the ground around
## it. False when no cell has a height.
static func fill_missing(raster: Dictionary) -> bool:
	var size: Vector2i = raster["size"]
	var v: PackedFloat32Array = raster["values"]
	var todo := PackedInt32Array()
	for i in v.size():
		if is_nan(v[i]):
			todo.append(i)
	if todo.size() == v.size():
		return false
	while not todo.is_empty():
		var rest := PackedInt32Array()
		var got := PackedFloat32Array()
		var at := PackedInt32Array()
		for i in todo:
			var x := i % size.x
			@warning_ignore("integer_division")
			var y := i / size.x
			var sum := 0.0
			var n := 0
			for j in [i - 1 if x > 0 else -1, i + 1 if x < size.x - 1 else -1,
					i - size.x if y > 0 else -1, i + size.x if y < size.y - 1 else -1]:
				if j >= 0 and not is_nan(v[j]):
					sum += v[j]
					n += 1
			if n > 0:
				at.append(i)
				got.append(sum / float(n))
			else:
				rest.append(i)
		for k in at.size():
			v[at[k]] = got[k]
		todo = rest
	raster["values"] = v
	return true

## Bilinear height at Mercator (x, y), clamped to the raster; cell values
## sit at cell centres. Expects a filled raster.
static func sample(raster: Dictionary, x: float, y: float) -> float:
	var size: Vector2i = raster["size"]
	var origin: Vector2 = raster["origin"]
	var cell: Vector2 = raster["cell"]
	var fx := clampf((x - origin.x) / cell.x - 0.5, 0.0, float(size.x - 1))
	var fy := clampf((origin.y - y) / cell.y - 0.5, 0.0, float(size.y - 1))
	var x0 := mini(int(fx), size.x - 2)
	var y0 := mini(int(fy), size.y - 2)
	var tx := fx - float(x0)
	var ty := fy - float(y0)
	var v: PackedFloat32Array = raster["values"]
	return lerpf(lerpf(v[y0 * size.x + x0], v[y0 * size.x + x0 + 1], tx),
		lerpf(v[(y0 + 1) * size.x + x0], v[(y0 + 1) * size.x + x0 + 1], tx), ty)

## Replaces `data.heights` with the raster's heights, in place and only
## when the raster has data; BareEarth then leaves the bare-earth model
## alone. Run after CoastalDem.correct, which still needs the Terrarium
## heights to register the far rings against the sea.
static func apply(data: LocationData) -> bool:
	var raster: Dictionary = data.ground_model
	if raster.is_empty() or not SOURCES.has(str(data.dem_source.get("ground_model", ""))) \
			or not DemRegistration.applies(data) or not fill_missing(raster):
		return false
	var grid := data.grid_size
	var heights := PackedFloat32Array()
	heights.resize(grid * grid)
	var mn := INF
	var mx := -INF
	for z in grid:
		for x in grid:
			var ll := HelsinkiDem.grid_latlon(data, float(x), float(z))
			var m := merc(ll.x, ll.y)
			var h := sample(raster, m.x, m.y)
			heights[z * grid + x] = h
			mn = minf(mn, h)
			mx = maxf(mx, h)
	data.heights = heights
	data.centre_elevation_m = heights[(grid / 2) * grid + grid / 2]
	data.relief_metres = mx - mn
	if not is_equal_approx(data.water_level, -3.0):
		data.water_level = WaterBuilder.SEA_LEVEL_M
	return true
