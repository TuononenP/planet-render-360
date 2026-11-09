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
