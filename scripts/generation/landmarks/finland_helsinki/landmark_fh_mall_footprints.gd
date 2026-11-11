class_name LandmarkFhMallFootprints
extends RefCounted

## Outlines of the Redi lot and the biggest capital-region malls from
## OpenStreetMap (2026-11-11; ways and relation in
## docs/helsinki-landmark-sources.md), Douglas-Peucker simplified to
## 2.5 m. Each outline is flat x, z pairs in metres about the registry
## entry's lat/lon: +X east, +Z south, the entry's yaw_deg 0.

const OUTLINES := {
	"redi_shopping_centre": [
		-10.1, -90.4, -74.6, -105.1, -87.2, -52.7, -84.2, -37.6, -90.6, -37.4, -108.8, 45.3,
		-15.9, 96.1, 7.2, 64.6, 12.3, 69.1, 93.6, -9.3, 108.8, -63.7],
	"mall_of_tripla": [
		121.2, -18.9, 128.1, 10.3, 145.0, 6.4, 140.1, -14.1, 209.5, -30.3, 214.5, -10.1,
		231.3, -13.9, 208.4, -110.6, 191.4, -106.6, 196.3, -85.6, 127.2, -69.5, 122.3, -90.4,
		105.3, -86.4, 115.3, -45.0, 101.6, -41.8, 91.7, -83.3, -119.5, -33.7, -110.2, 5.5,
		-93.3, 1.6, -88.9, 20.4, -105.7, 24.5, -96.6, 63.3, -60.8, 54.9, -48.9, 107.9, 6.2, 94.6,
		5.1, 90.4, 82.2, 71.9, 86.2, 66.2, 76.0, 22.7, 114.8, 13.6, 108.1, -14.2],
	"itis_shopping_centre": [
		42.1, -99.1, 30.5, -98.8, 26.1, -108.9, 29.1, -114.4, 37.8, -117.0, 44.9, -112.0,
		48.0, -101.6, 55.3, -110.4, 45.8, -129.8, 81.4, -147.9, 92.6, -125.5, 100.0, -129.6,
		104.4, -151.1, 114.5, -167.2, 122.9, -172.6, 136.0, -171.3, 153.7, -153.2, 163.6, -117.7,
		157.6, -82.7, 151.6, -73.5, 138.9, -67.7, 145.2, -42.5, 2.2, 134.2, -7.6, 121.6, -5.2, 118.2,
		-17.2, 108.8, -14.8, 105.9, -30.0, 93.5, -40.6, 106.6, -33.8, 119.1, -30.0, 117.1,
		-14.7, 149.6, -101.8, 194.5, -100.6, 200.2, -104.9, 198.4, -201.2, 250.6, -231.6, 199.6,
		-105.0, 130.0, -130.3, 85.6, -120.8, 80.8, -118.2, 85.3, -108.5, 80.2, -104.6, 87.9,
		-93.8, 82.5, -92.1, 85.0, -87.6, 81.8, -94.2, 68.4, -67.2, 40.4, -63.0, 43.4, -60.8, 40.5,
		-51.5, 48.1, -47.1, 42.0, -60.5, 31.7, -4.7, -39.0, -15.4, -44.8, -6.0, -60.6, -2.5, -59.7,
		0.4, -64.6, -3.3, -65.1, 6.2, -81.3, 9.8, -80.2, 12.5, -84.9, 9.2, -85.8, 18.3, -100.8,
		27.8, -94.8, 25.4, -90.6, 32.0, -83.9],
	"iso_omena": [
		-134.2, -134.3, -143.6, -150.0, -41.7, -193.6, -34.5, -177.0, -37.8, -175.6, -34.2, -167.4,
		-30.6, -168.8, 10.7, -69.9, 35.8, -80.5, 40.7, -69.4, 35.1, -67.0, 46.2, -41.7, 53.7, -43.6,
		55.9, -38.5, 58.2, -28.9, 53.5, -25.2, 63.0, -3.0, 70.1, -4.8, 72.3, 0.2, 74.5, 9.7,
		70.0, 13.5, 79.4, 35.6, 86.9, 33.7, 89.1, 38.9, 89.1, 51.2, 74.0, 57.5, 92.9, 76.4,
		106.1, 106.7, 115.2, 102.9, 122.5, 120.3, 90.7, 131.3, 93.1, 137.0, 79.5, 144.6,
		-22.2, 183.9, -46.8, 124.8, -35.8, 124.3, -35.7, 115.5, -67.5, 42.0, -62.2, 39.6,
		-66.2, 30.6, -71.3, 32.7, -86.4, -1.9, -81.0, -4.1, -83.5, -9.8, -86.8, -8.4, -96.3, -30.7,
		-90.3, -33.3, -93.7, -41.2, -76.6, -48.3, -86.1, -69.9, -114.8, -63.9, -116.7, -68.0,
		-121.3, -66.0, -146.4, -124.2, -132.4, -130.2],
	"sello_shopping_centre": [
		56.7, -99.9, 65.5, -97.6, 62.0, 35.6, 51.1, 32.8, 55.6, 45.1, 51.2, 53.9, 43.2, 57.7,
		31.6, 54.2, 26.7, 43.4, 31.6, 32.5, -93.5, 30.1, -92.6, -13.8, -97.6, -13.9, -95.7, -104.4],
	"jumbo_shopping_centre": [
		-187.9, -155.1, -151.5, -154.0, -129.5, -148.4, -98.3, -133.8, -69.9, -134.4, -28.0, -125.1,
		71.4, -68.7, 69.6, 167.3, 61.9, 177.7, -69.1, 179.1, -67.7, -57.6, -183.8, -57.6,
		-183.7, -62.2, -189.1, -62.2],
}

## The outline of `type` as an XZ polygon, empty when none is recorded.
static func outline(type: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	var flat: Array = OUTLINES.get(type, [])
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out

## `poly` grown (delta > 0) or shrunk (delta < 0) by `delta` metres: the
## largest resulting piece, empty when the polygon vanishes.
static func offset(poly: PackedVector2Array, delta: float) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := 0.0
	for piece in Geometry2D.offset_polygon(poly, delta, Geometry2D.JOIN_MITER):
		var area := absf(area_of(piece))
		if area > best_area:
			best_area = area
			best = piece
	return best

## Signed shoelace area of `poly`.
static func area_of(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5

## True when the axis-aligned rectangle (centre `c`, full size `size`)
## lies wholly inside `poly`.
static func rect_inside(poly: PackedVector2Array, c: Vector2, size: Vector2) -> bool:
	var h := size * 0.5
	var rect := PackedVector2Array([c - h, Vector2(c.x + h.x, c.y - h.y), c + h, Vector2(c.x - h.x, c.y + h.y)])
	var hit := Geometry2D.intersect_polygons(poly, rect)
	return hit.size() == 1 and absf(absf(area_of(hit[0])) - size.x * size.y) < 0.5
