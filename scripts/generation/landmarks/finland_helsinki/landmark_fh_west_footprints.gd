class_name LandmarkFhWestFootprints
extends RefCounted

## Outlines of the Keilaniemi, Tapiola, Lauttasaari and Niittykumpu landmarks from
## OpenStreetMap (2026-11-12; ways in docs/espoo-landmark-sources.md and
## docs/helsinki-landmark-sources.md), Douglas-Peucker simplified to
## 0.5–1 m. Flat x, z pairs in metres about the registry entry's lat/lon:
## +X east, +Z south, the entry's yaw_deg 0. Also the facade helpers the
## outline-built models share: edge-following ribs and window rows.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const OUTLINES := {
	"finago_tower": [
		-12.5, -20.7, -18.9, -18.2, -2.6, 21.4, 3.7, 18.9, 7.2, 27.4, 15.8, 23.9, 12.3, 15.5,
		18.7, 12.9, 2.5, -26.8, -3.9, -24.2, -7.4, -32.7, -16.0, -29.2],
	"kone_building": [-13.6, -6.8, -1.4, 22.9, 14.8, 16.3, 2.6, -13.4],
	"keilalampi": [
		-2.0, 28.8, 2.7, 40.4, 18.4, 30.5, 38.0, 22.7, 62.0, 16.5, 55.0, 0.0, 56.8, -0.7,
		34.9, -55.0, -26.0, -30.8, -23.8, -25.5, -26.8, -24.3, -17.5, -1.1, -22.9, 1.0,
		-21.4, 4.6, -16.1, 2.5, -15.2, 5.0, -20.2, 7.0, -17.3, 14.2, -12.2, 12.2, -7.1, 25.0,
		-4.0, 23.8],
	"espoo_cultural_centre": [
		29.1, -10.6, 25.4, -9.6, 26.6, -5.4, 32.6, -7.1, 34.5, -0.3, 27.5, 1.7, 26.5, -1.6,
		23.4, -0.7, 25.5, 6.6, 9.9, 10.9, 7.8, 3.6, 5.5, 4.3, 7.5, 15.6, 0.6, 17.6, 2.2, 23.0,
		8.3, 21.3, 11.2, 31.7, 13.8, 31.0, 18.6, 47.9, 9.9, 50.3, 11.7, 56.8, -4.9, 61.4,
		-4.4, 63.4, -16.5, 66.7, -28.4, 24.1, -25.7, 23.4, -27.6, 16.5, -24.7, 15.7, -30.1, -3.6,
		-34.7, -2.3, -36.9, -10.3, -31.5, -11.8, -42.5, -50.9, -36.6, -52.5, -37.4, -55.1,
		-34.1, -56.0, -33.4, -53.5, -7.2, -60.7, -4.2, -50.0, 11.3, -54.3, 14.5, -42.9,
		18.2, -44.0, 20.9, -34.3, 19.1, -33.8, 20.4, -29.4, 23.6, -30.3],
	"mantytorni": [-3.7, 15.7, -14.8, -6.6, -1.8, -12.9, 1.4, -6.6, -0.7, -5.5, 4.0, 3.9, 6.2, 2.8, 9.4, 9.2],
	"lauttasaari_church": [
		19.2, 43.0, -41.0, 30.6, -25.1, -45.5, -9.8, -42.7, -8.8, -47.9, 14.2, -43.2, 13.0, -37.6,
		23.5, -35.5, 20.0, -18.9, -17.2, -26.6, -25.3, 12.1, -12.2, 14.8, -9.9, 4.1, 26.7, 12.4],
	"lauttasaari_manor": [5.0, -16.8, 15.9, -7.4, 1.6, 8.9, 0.3, 7.8, -1.9, 10.3, -9.7, 3.6, -7.5, 1.1, -9.3, -0.5],
	"niittyhuippu": [-19.0, -3.3, -14.0, 5.8, -11.6, 4.5, -6.4, 13.9, 23.8, -2.6, 17.7, -13.8, 11.5, -10.4, 7.5, -17.7],
	"niittytori_tower": [7.5, 14.5, 15.9, -16.7, 4.1, -15.6, 3.4, -12.9, -9.0, -16.4, -16.4, 10.2, -4.1, 13.7, -3.5, 11.6],
	"niittytaival_tower": [
		-2.5, -11.3, -1.4, -10.4, -0.5, -11.4, 17.8, 4.0, 16.9, 5.1, 19.8, 7.4, 4.6, 21.5, 1.7, 18.2,
		0.8, 19.1, -16.8, -0.2, -15.9, -1.0, -20.3, -5.8, -7.3, -9.8, -6.1, -8.4],
	"olari_church": [
		-29.1, -1.5, -19.3, -2.5, -19.3, -6.3, -7.9, -6.8, -7.6, -4.7, 1.4, -5.1, 1.3, -8.0, 10.1, -11.6,
		10.7, -10.7, 17.5, -13.0, 18.9, -8.8, 17.6, -8.5, 20.0, -4.1, 24.9, -4.4, 25.6, 8.9, 26.5, 12.0,
		8.0, 20.1, 6.9, 17.8, -20.3, 19.1, -20.9, 11.6, -26.8, 11.8, -27.5, 3.0, -28.8, 3.0],
}

## Revell's four hip-flask houses about the entry (OSM way 129693702):
## ways 129693702, 129693693, 129693699 and 129693710.
const FLASKS := [
	[-4.4, -16.9, -8.6, 0.0, -4.3, 16.9, 0.1, 16.0, 4.4, 16.9, 8.6, 0.0, 4.3, -16.9, -0.1, -16.0],
	[-28.5, 45.9, -32.7, 62.8, -28.4, 79.6, -24.4, 78.7, -20.3, 79.6, -16.1, 62.7, -20.5, 45.9, -24.5, 46.8],
	[-16.5, -139.4, -20.8, -122.6, -16.9, -105.7, -12.5, -106.8, -8.3, -105.7, -4.1, -122.6, -7.9, -139.3, -12.4, -138.6],
	[20.9, -85.4, 16.7, -68.5, 21.0, -51.6, 25.4, -52.5, 29.7, -51.6, 33.9, -68.5, 29.6, -85.4, 25.2, -84.5],
]

## Every footprint polygon of `type` (one, or several for a group).
static func outlines(type: String) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	if type == "tapiola_hip_flask_houses":
		for flat in FLASKS:
			out.append(_poly(flat))
	elif OUTLINES.has(type):
		out.append(_poly(OUTLINES[type]))
	elif not F.outline(type).is_empty():
		out.append(F.outline(type))
	return out

static func outline(type: String) -> PackedVector2Array:
	var all := outlines(type)
	return all[0] if all.size() == 1 else PackedVector2Array()

static func _poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out

## Outward unit normal of edge a..b of `poly`.
static func outward(poly: PackedVector2Array, a: Vector2, b: Vector2) -> Vector2:
	var along := (b - a).normalized()
	var out := Vector2(along.y, -along.x)
	if Geometry2D.is_point_in_polygon((a + b) * 0.5 + out * 0.3, poly):
		out = -out
	return out

## Vertical ribs `w` wide standing `depth` proud of every edge, about
## `step` apart, y0..y1: pier bands of a stone or mullioned facade.
static func ribs(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float, y1: float,
		step: float, w: float, depth: float) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := int(a.distance_to(b) / step)
		if n < 1:
			continue
		var along := (b - a).normalized()
		var out := outward(poly, a, b)
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(n)) + out * (depth * 0.5)
			lm.box(key, Vector3(p.x, (y0 + y1) * 0.5, p.y), Vector3(w, y1 - y0, depth), basis, 0.0)

## Window rows on every edge of `poly` at least `spacing` long, one window
## per `spacing` metres, `rows` rows `pitch` apart from y0. With `frame`,
## each window also gets a surround of that material (a rail for a French
## balcony when `rail` is true, else a sill and lintel).
static func edge_windows(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float,
		rows: int, pitch: float, spacing: float, w: float, h: float, frame: String = "",
		rail: bool = false) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := int(a.distance_to(b) / spacing)
		if n < 1:
			continue
		var out := outward(poly, a, b)
		var along := (b - a).normalized()
		var inset := along * 0.6
		var p0 := a + inset
		var p1 := b - inset
		U.window_grid(lm, key, Vector3(p0.x, 0, p0.y), Vector3(p1.x, 0, p1.y),
			Vector3(out.x, 0, out.y), y0, rows, pitch, n, w, h)
		if frame == "":
			continue
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		for r in rows:
			var y := y0 + pitch * float(r)
			for k in n:
				var c := p0.lerp(p1, (float(k) + 0.5) / float(n)) + out * 0.12
				if rail:
					lm.box(frame, Vector3(c.x, y + 0.5, c.y) + Vector3(out.x, 0, out.y) * 0.1,
						Vector3(w + 0.2, 0.06, 0.05), basis, 0.0)
					for s: float in [-0.5, 0.5]:
						var q := c + along * (w * s) + out * 0.1
						lm.box(frame, Vector3(q.x, y + 0.25, q.y), Vector3(0.04, 0.5, 0.04), basis, 0.0)
				else:
					lm.box(frame, Vector3(c.x, y - 0.06, c.y), Vector3(w + 0.3, 0.12, 0.16), basis, 0.0)
					lm.box(frame, Vector3(c.x, y + h + 0.12, c.y), Vector3(w + 0.4, 0.24, 0.12), basis, 0.0)

## Ribbon bands: a skin slightly proud of `poly` from y to y + h on every
## storey `pitch` apart (`rows` of them), open top and bottom.
static func ribbons(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float, h: float,
		rows: int, pitch: float, proud: float = 0.06) -> void:
	var skin := F.offset(poly, proud)
	for r in rows:
		var y0 := y + float(r) * pitch
		lm.poly_prism(key, skin, y0, y0 + h, false)

## Hipped roof over the rectangle with corners c0, c1, c2, c3 (in order),
## eaves at `y`, rising `h`; the ridge runs along the longer side.
static func hip_rect(lm: LandmarkMesh, key: String, c0: Vector2, c1: Vector2, c2: Vector2,
		c3: Vector2, y: float, h: float) -> void:
	var corners := [c0, c1, c2, c3]
	if c0.distance_to(c1) < c1.distance_to(c2):
		corners = [c1, c2, c3, c0]
	var a: Vector2 = corners[0]
	var b: Vector2 = corners[1]
	var c: Vector2 = corners[2]
	var d: Vector2 = corners[3]
	var centre := (a + b + c + d) * 0.25
	var along := (b - a).normalized()
	var run := maxf(a.distance_to(b) - b.distance_to(c), 0.0) * 0.5
	var r0 := Vector3(centre.x - along.x * run, y + h, centre.y - along.y * run)
	var r1 := Vector3(centre.x + along.x * run, y + h, centre.y + along.y * run)
	var pa := Vector3(a.x, y, a.y)
	var pb := Vector3(b.x, y, b.y)
	var pc := Vector3(c.x, y, c.y)
	var pd := Vector3(d.x, y, d.y)
	_face(lm, key, [pa, pb, r1, r0], centre, y)
	_face(lm, key, [pc, pd, r0, r1], centre, y)
	_face(lm, key, [pb, pc, r1], centre, y)
	_face(lm, key, [pd, pa, r0], centre, y)

static func _face(lm: LandmarkMesh, key: String, pts: Array, centre: Vector2, y: float) -> void:
	var p0: Vector3 = pts[0]
	var p1: Vector3 = pts[1]
	var p2: Vector3 = pts[2]
	var n := (p1 - p0).cross(p2 - p0).normalized()
	var mid := (p0 + p1) * 0.5
	if n.dot(Vector3(mid.x - centre.x, 1.0, mid.z - centre.y)) < 0.0:
		n = -n
	var z := Vector2.ZERO
	if pts.size() == 4:
		lm.quad(key, p0, p1, p2, pts[3], n)
	else:
		lm.tri(key, p0, p1, p2, n, n, n, z, Vector2(p0.distance_to(p1), 0), Vector2(0, 1))

## Butterfly roof over `poly`: two planes falling from its ends (along X)
## `rise` metres above y0 to a valley at the middle of its X extent, with
## the walls filled up to the planes.
static func butterfly(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float, rise: float) -> void:
	var lo := INF
	var hi := -INF
	var zlo := INF
	var zhi := -INF
	for p in poly:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
		zlo = minf(zlo, p.y)
		zhi = maxf(zhi, p.y)
	var mid := (lo + hi) * 0.5
	var half := maxf((hi - lo) * 0.5, 0.1)
	for side: float in [-1.0, 1.0]:
		var x0 := mid if side > 0.0 else lo - 1.0
		var x1 := hi + 1.0 if side > 0.0 else mid
		var rect := PackedVector2Array([Vector2(x0, zlo - 1.0), Vector2(x1, zlo - 1.0),
			Vector2(x1, zhi + 1.0), Vector2(x0, zhi + 1.0)])
		for piece in Geometry2D.intersect_polygons(poly, rect):
			var idx := Geometry2D.triangulate_polygon(piece)
			var n := Vector3(-side * rise / half, 1.0, 0.0).normalized()
			for t in range(0, idx.size(), 3):
				var v: Array[Vector3] = []
				for k in 3:
					var q := piece[idx[t + k]]
					v.append(Vector3(q.x, _valley_y(q.x, y0, rise, mid, half), q.y))
				lm.tri(key, v[0], v[1], v[2], n, n, n, Vector2(v[0].x, v[0].z), Vector2(v[1].x, v[1].z), Vector2(v[2].x, v[2].z))
			for i in piece.size():
				var a := piece[i]
				var b := piece[(i + 1) % piece.size()]
				if absf(a.x - mid) < 0.01 and absf(b.x - mid) < 0.01:
					continue
				var out := outward(piece, a, b)
				lm.quad(key, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y),
					Vector3(b.x, _valley_y(b.x, y0, rise, mid, half), b.y), Vector3(a.x, _valley_y(a.x, y0, rise, mid, half), a.y), Vector3(out.x, 0.0, out.y))

static func _valley_y(x: float, y0: float, rise: float, mid: float, half: float) -> float:
	return y0 + rise * absf(x - mid) / half
