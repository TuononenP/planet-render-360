class_name NationalGrids
extends RefCounted

## Forward projection of the Swiss LV95 grid (EPSG:2056), which swissALTI3D
## answers in. swisstopo's published approximation, about 1 m: enough for a
## 5-10 m elevation grid.

## Swiss LV95 (E, N) of a WGS84 position.
static func lv95(lat: float, lon: float) -> Vector2:
	var p := (lat * 3600.0 - 169028.66) / 10000.0
	var l := (lon * 3600.0 - 26782.5) / 10000.0
	return Vector2(
		2600072.37 + 211455.93 * l - 10938.51 * l * p - 0.36 * l * p * p - 44.54 * l * l * l,
		1200147.07 + 308807.95 * p + 3745.25 * l * l + 76.63 * p * p - 194.56 * l * l * p + 119.79 * p * p * p)

## Finnish ETRS-TM35FIN (EPSG:3067) (E, N) of a WGS84 position: GRS80
## Transverse Mercator, central meridian 27°E, scale 0.9996, false easting
## 500 000 m (Krüger series, same ellipsoid as Gk25).
static func tm35fin(lat: float, lon: float) -> Vector2:
	var n := Gk25._F / (2.0 - Gk25._F)
	var n2 := n * n
	var n3 := n2 * n
	var big_a := Gk25._A / (1.0 + n) * (1.0 + n2 / 4.0 + n2 * n2 / 64.0)
	var alpha := [n / 2.0 - 2.0 * n2 / 3.0 + 5.0 * n3 / 16.0,
		13.0 * n2 / 48.0 - 3.0 * n3 / 5.0, 61.0 * n3 / 240.0]
	var phi := deg_to_rad(lat)
	var dl := deg_to_rad(lon - 27.0)
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
	return Vector2(500000.0 + 0.9996 * big_a * e, 0.9996 * big_a * nn)

## JHS 180 TM35 1:10 000 map sheet relative path (e.g. "L3/L33/L3324B.tif")
## for ETRS-TM35FIN (e, n), or "" outside the Finnish map-sheet grid.
static func tm35_sheet(e: float, n: float) -> String:
	const ROWS := "KLMNPQRSTUVWX"
	const LETTERS := "ABCDEFGH"
	var ri := floori((n - 6570000.0) / 96000.0)
	var ci := floori((e + 76000.0) / 192000.0) + 2
	if ri < 0 or ri >= ROWS.length() or ci < 2 or ci > 6:
		return ""
	var re := e - (-76000.0 + float(ci - 2) * 192000.0)
	var rn := n - (6570000.0 + float(ri) * 96000.0)
	var q := ""
	for pair in [[96000.0, 48000.0], [48000.0, 24000.0], [24000.0, 12000.0]]:
		var ew: float = pair[0]
		var nw: float = pair[1]
		var qx := 1 if re >= ew else 0
		var qy := 1 if rn >= nw else 0
		q += str(1 + qx * 2 + qy)
		re -= float(qx) * ew
		rn -= float(qy) * nw
	var cx := clampi(floori(re / 6000.0), 0, 3)
	var cy := clampi(floori(rn / 6000.0), 0, 1)
	var s200 := "%s%d" % [ROWS[ri], ci]
	var s100 := s200 + q[0]
	var s10 := s100 + q.substr(1, 2) + LETTERS[cx * 2 + cy]
	return "%s/%s/%s.tif" % [s200, s100, s10]
