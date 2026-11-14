class_name Gk25
extends RefCounted

## ETRS-GK25 (EPSG:3879), the plane grid of the City of Helsinki's open
## data: the elevation model (HelsinkiDem), the building register
## (HelsinkiRegister) and the tree register come back in it. Transverse
## Mercator on GRS80, central meridian 25°E, scale 1, false easting
## 25 500 000 m (Krüger series, sub-millimetre over the metro area).

const _A := 6378137.0
const _F := 1.0 / 298.257222101
const _LON0 := 25.0
const _E0 := 25500000.0

## (E, N) of a WGS84 position. A Vector2 is float32 (~2 m at GK25's
## 25.5e6 m eastings): fine for a DEM sample, not for a round trip; use
## `forward` where metres matter.
static func from_latlon(lat: float, lon: float) -> Vector2:
	var f := forward(lat, lon)
	return Vector2(f[0], f[1])

## (E, N) of a WGS84 position in float64.
static func forward(lat: float, lon: float) -> PackedFloat64Array:
	var n := _F / (2.0 - _F)
	var n2 := n * n
	var n3 := n2 * n
	var big_a := _A / (1.0 + n) * (1.0 + n2 / 4.0 + n2 * n2 / 64.0)
	var alpha := [n / 2.0 - 2.0 * n2 / 3.0 + 5.0 * n3 / 16.0,
		13.0 * n2 / 48.0 - 3.0 * n3 / 5.0, 61.0 * n3 / 240.0]
	var phi := deg_to_rad(lat)
	var dl := deg_to_rad(lon - _LON0)
	var c := 2.0 * sqrt(n) / (1.0 + n)
	var t := sinh(atanh(sin(phi)) - c * atanh(c * sin(phi)))
	var xi := atan2(t, cos(dl))
	var eta := atanh(sin(dl) / sqrt(1.0 + t * t))
	var e := eta
	var nn := xi
	for j in 3:
		var k := 2.0 * float(j + 1)
		e += float(alpha[j]) * cos(k * xi) * sinh(k * eta)
		nn += float(alpha[j]) * sin(k * xi) * cosh(k * eta)
	return PackedFloat64Array([_E0 + big_a * e, big_a * nn])

## WGS84 (lat, lon) of an (E, N): Newton on the forward series, which
## converges to well under a millimetre in a few steps near Helsinki.
static func to_latlon(e: float, n: float) -> PackedFloat64Array:
	# Start from the local plane approximation around 60.17N 25E.
	var lat := 60.17 + (n - 6673000.0) / 111400.0
	var lon := _LON0 + (e - _E0) / (111320.0 * cos(deg_to_rad(lat)))
	for _i in 5:
		var p := forward(lat, lon)
		var d := 1e-6
		var pl := forward(lat + d, lon)
		var po := forward(lat, lon + d)
		# Jacobian columns: d(E,N)/dlat, d(E,N)/dlon.
		var a := (pl[0] - p[0]) / d
		var b := (po[0] - p[0]) / d
		var c := (pl[1] - p[1]) / d
		var dd := (po[1] - p[1]) / d
		var det := a * dd - b * c
		if absf(det) < 1e-9:
			break
		var re := e - p[0]
		var rn := n - p[1]
		lat += (dd * re - b * rn) / det
		lon += (-c * re + a * rn) / det
	return PackedFloat64Array([lat, lon])

## Local metre XZ (WorldScale frame) of an (E, N) around (c_lat, c_lon).
static func to_xz(e: float, n: float, c_lat: float, c_lon: float) -> Vector2:
	var ll := to_latlon(e, n)
	return WorldScale.xz_from_latlon(ll[0], ll[1], c_lat, c_lon)

## A per-place quadratic map (E, N) → local XZ round (c_lat, c_lon),
## fitted by finite differences over ±1 km: within centimetres of `to_xz`
## across a 3 km window (the flat frame's longitude scale follows
## latitude, a cross term an affine fit misses by ~0.6 m), at a fraction
## of its cost (thousands of register rows per place).
## [e0, n0, then per axis x, z: c, d/de, d/dn, d²/de²/2, d²/dn²/2, d²/dedn].
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

## Local XZ of (E, N) through a `frame`.
static func frame_xz(f: PackedFloat64Array, e: float, n: float) -> Vector2:
	var de := e - f[0]
	var dn := n - f[1]
	return Vector2(
		f[2] + f[3] * de + f[4] * dn + f[5] * de * de + f[6] * dn * dn + f[7] * de * dn,
		f[8] + f[9] * de + f[10] * dn + f[11] * de * de + f[12] * dn * dn + f[13] * de * dn)
