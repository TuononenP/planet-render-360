class_name RdNew
extends RefCounted

## Amersfoort / RD New (EPSG:28992), the national metric plane grid of the
## Netherlands (3DBAG LoD2.2, AHN DTM, PDOK orthophoto).
## Uses the standard Schreutelkamp & Strang van Hees polynomial approximation
## around Onze Lieve Vrouwetoren in Amersfoort (52.15517440° N, 5.38720621° E,
## X0 = 155000 m, Y0 = 463000 m), accurate to ~0.1 m across the Netherlands.

const _LAT0 := 52.15517440
const _LON0 := 5.38720621
const _X0 := 155000.0
const _Y0 := 463000.0

## (X, Y) in RD New metres (float64) for WGS84 (lat, lon).
static func forward(lat: float, lon: float) -> PackedFloat64Array:
	var dp := 0.36 * (lat - _LAT0)
	var dl := 0.36 * (lon - _LON0)
	var dp2 := dp * dp
	var dp3 := dp2 * dp
	var dl2 := dl * dl
	var dl3 := dl2 * dl
	var x := _X0 + 190094.945 * dl - 11832.228 * dp * dl - 114.221 * dp2 * dl \
		- 32.391 * dl3 - 0.705 * dp - 2.340 * dp3 * dl - 0.608 * dp * dl3 \
		- 0.008 * dl2 + 0.148 * dp2 * dl3
	var y := _Y0 + 309056.544 * dp + 3638.893 * dl2 + 73.077 * dp2 \
		- 157.984 * dp * dl2 + 59.788 * dp3 + 0.433 * dl - 6.439 * dp2 * dl2 \
		- 0.032 * dp * dl + 0.092 * dl2 * dl2 - 0.054 * dp * dl2 * dl2
	return PackedFloat64Array([x, y])

## WGS84 (lat, lon) in float64 for RD New (x, y) metres.
static func to_latlon(x: float, y: float) -> PackedFloat64Array:
	var dx := (x - _X0) * 1e-5
	var dy := (y - _Y0) * 1e-5
	var dx2 := dx * dx
	var dx3 := dx2 * dx
	var dx4 := dx2 * dx2
	var dy2 := dy * dy
	var dy3 := dy2 * dy
	var dy4 := dy2 * dy2
	var lat := _LAT0 + (3235.65389 * dy - 32.58297 * dx2 - 0.24750 * dy2 \
		- 0.84978 * dx2 * dy - 0.06550 * dy3 - 0.01709 * dx2 * dy2 - 0.00738 * dx \
		+ 0.00530 * dx4 - 0.00039 * dx2 * dy3 + 0.00033 * dx4 * dy - 0.00012 * dx * dy) / 3600.0
	var lon := _LON0 + (5260.52916 * dx + 105.94684 * dx * dy + 2.45656 * dx * dy2 \
		- 0.81885 * dx3 + 0.05594 * dx * dy3 - 0.05607 * dx3 * dy + 0.01199 * dy \
		- 0.00256 * dx3 * dy2 + 0.00128 * dx * dy4 + 0.00022 * dy2 - 0.00022 * dx2 \
		+ 0.00026 * dx4 * dx) / 3600.0
	return PackedFloat64Array([lat, lon])

## Local metre XZ (WorldScale frame) of an RD New (x, y) around (c_lat, c_lon).
static func to_xz(x: float, y: float, c_lat: float, c_lon: float) -> Vector2:
	var ll := to_latlon(x, y)
	return WorldScale.xz_from_latlon(ll[0], ll[1], c_lat, c_lon)

## Per-place quadratic map (X, Y) -> local XZ round (c_lat, c_lon), matching Gk25.frame.
static func frame(c_lat: float, c_lon: float) -> PackedFloat64Array:
	var c := forward(c_lat, c_lon)
	var h := 1000.0
	var s := {}
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			s[Vector2i(i, j)] = to_xz(c[0] + h * i, c[1] + h * j, c_lat, c_lon)
	var out := PackedFloat64Array([c[0], c[1]])
	for axis in 2:
		var f := func(i: int, j: int) -> float: return float((s[Vector2i(i, j)] as Vector2)[axis])
		out.append_array([f.call(0, 0),
			(f.call(1, 0) - f.call(-1, 0)) / (2.0 * h),
			(f.call(0, 1) - f.call(0, -1)) / (2.0 * h),
			(f.call(1, 0) + f.call(-1, 0) - 2.0 * f.call(0, 0)) / (2.0 * h * h),
			(f.call(0, 1) + f.call(0, -1) - 2.0 * f.call(0, 0)) / (2.0 * h * h),
			(f.call(1, 1) - f.call(1, -1) - f.call(-1, 1) + f.call(-1, -1)) / (4.0 * h * h)])
	return out

## Local XZ of RD New (e, n) through a `frame`.
static func frame_xz(f: PackedFloat64Array, e: float, n: float) -> Vector2:
	var de := e - f[0]
	var dn := n - f[1]
	return Vector2(
		f[2] + f[3] * de + f[4] * dn + f[5] * de * de + f[6] * dn * dn + f[7] * de * dn,
		f[8] + f[9] * de + f[10] * dn + f[11] * de * de + f[12] * dn * dn + f[13] * de * dn)
