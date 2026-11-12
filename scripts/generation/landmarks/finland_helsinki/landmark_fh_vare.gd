class_name LandmarkFhVare
extends RefCounted

## The Väre block in Otaniemi (OSM building relation 12696772; Verstas
## Architects, 2018–2019) about Väre's registry point, +X east, +Z south:
## Väre, the School of Business and the A Bloc mall with the Aalto
## University metro station's main entrance, after their OSM building:parts
## and street photographs. Also the station's Tietotie entrance pavilion
## (a registry entry of its own). Sources and estimates:
## docs/espoo-landmark-sources.md.
##
## Parts by type, flat x, z pairs:
## GLASS_TOPS, the parts tagged three levels (Väre L, E, K, J, G, M, R, Q;
## School of Business T, V, Y; A Bloc N and way 815467161): red-brown
## brick with a close rhythm of tall slots under a two-storey silver glass
## box. TALL, block-sized parts with no level tag (F, O, P, U) and A Bloc's
## way 815467162: all-brick blocks over a glazed or perforated-metal ground
## storey, the last with a band of brick louvres. HALLS: the School of
## Business atrium (X), A Bloc's mall hall (way 522627432) and its link
## (way 815467164), dark curtain walls. LINKS, the two-storey parts between
## the blocks (ways 522627431, 941553970, 522627430). LOW, A Bloc's
## two-storey block A on the square. STATION, the metro entrance hall
## (way 402618641). PAVILION, Väre's glass part S; STAIR, the black metal
## skillion (way 941553972); BRIDGE, the glass part over the School of
## Business entrance (way 941553973).

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const GLASS_TOPS := [
	[2.1, 30.7, 10.7, 22.8, -7.6, 3.0, -16.2, 10.9],
	[61.4, -6.6, 58.1, 3.8, 57.6, 5.2, 31.8, -3.1, 35.4, -14.2, 35.6, -14.9],
	[23.2, -5.3, 19.3, 7.2, -6.1, -0.5, -2.3, -13.1],
	[14.6, -35.1, 5.4, -26.2, 24.9, -6.5, 33.7, -15.0, 34.3, -15.3],
	[6.1, 32.0, 30.7, 39.9, 27.3, 50.4, 2.7, 42.5],
	[-25.2, 22.3, 0.1, 30.5, -3.2, 40.6, -28.5, 32.4],
	[-45.6, 0.0, -27.5, 19.9, -36.2, 27.7, -43.6, 19.6, -54.3, 7.9],
	[-41.2, -9.4, -15.4, -2.2, -18.5, 8.5, -44.1, 0.9],
	[-53.6, -44.9, -64.0, -34.7, -44.0, -14.6, -33.2, -24.7],
	[-59.8, -48.8, -63.7, -36.1, -88.9, -43.8, -85.0, -56.5],
	[-123.9, -53.8, -97.6, -45.6, -100.4, -36.8, -102.5, -37.5, -126.7, -45.0, -126.4, -45.9, -124.6, -51.5],
	[-40.4, 45.3, -38.7, 43.7, -31.3, 36.6, -12.1, 56.6, -21.3, 65.2],
	[-21.3, 65.2, -1.3, 86.1, -11.3, 95.6, -25.3, 81.0, -31.3, 74.7, -25.3, 69.0],
]
const TALL := [
	[21.2, 9.0, 30.2, 0.8, 48.0, 20.0, 39.1, 28.2],
	[7.3, -40.2, 3.6, -28.5, -22.5, -36.8, -22.0, -38.2, -18.6, -48.5],
	[-23.3, -34.3, -3.5, -14.0, -13.4, -4.4, -33.2, -24.7, -31.3, -26.6],
	[-69.0, -20.5, -44.3, -12.7, -47.3, -2.9, -72.1, -10.5, -71.7, -11.7],
	[12.6, 55.0, 20.8, 63.3, 22.3, 64.9, 43.1, 86.1, 32.5, 96.3, 2.0, 65.2],
]
## Tops of the TALL blocks, and which have a perforated-metal ground storey
## or the louvre band.
const TALL_M := [21.5, 20.5, 21.0, 20.0, 21.5]
const TALL_PERF := [false, true, false, true, true]
const TALL_LOUVRE := [false, false, false, false, true]
const HALLS := [
	[-78.0, -13.9, -76.3, -15.5, -70.7, -21.1, -88.9, -41.4, -89.0, -41.6, -97.0, -34.3],
	[43.1, 86.1, 46.6, 89.6, 48.4, 90.2, 54.2, 92.3, 50.1, 104.7, 29.9, 98.1, 28.1, 97.5, 16.2, 107.3, 14.1, 105.4,
		17.9, 93.8, 0.9, 88.2, -3.0, 99.8, -7.2, 98.2, -11.3, 95.6, -1.3, 86.1, -21.3, 65.2, -12.1, 56.6, -31.3, 36.6,
		-28.5, 32.4, -3.2, 40.6, 2.7, 42.5, 27.3, 50.4, 21.0, 62.9, 20.8, 63.3, 12.6, 55.0, 2.0, 65.2, 32.5, 96.3],
	[0.9, 88.2, 17.9, 93.8, 14.1, 105.4, -3.0, 99.8],
]
const HALLS_M := [19.0, 11.5, 11.5]
const LINKS := [
	[5.4, -26.2, 14.6, -35.1, 7.3, -40.2, 3.6, -28.5, -22.5, -36.8, -23.3, -34.3, -3.5, -14.0, -13.4, -4.4,
		-33.2, -24.7, -44.0, -14.6, -44.3, -12.7, -47.3, -2.9, -45.6, 0.0, -27.5, 19.9, -36.2, 27.7, -28.5, 32.4,
		-25.2, 22.3, -16.2, 10.9, -7.6, 3.0, -6.1, -0.5, -2.3, -13.1],
	[33.7, -15.0, 24.9, -6.5, 5.4, -26.2, -2.3, -13.1, 23.2, -5.3, 19.3, 7.2, -6.1, -0.5, -7.6, 3.0, 10.7, 22.8,
		2.1, 30.7, -16.2, 10.9, -25.2, 22.3, 0.1, 30.5, -3.2, 40.6, 2.7, 42.5, 6.1, 32.0, 30.7, 39.9, 34.3, 32.4,
		36.4, 30.4, 39.1, 28.2, 21.2, 9.0, 30.2, 0.8, 48.0, 20.0, 57.6, 5.2, 31.8, -3.1, 35.4, -14.2, 34.1, -14.8],
	[-76.3, -15.5, -70.7, -21.1, -88.9, -41.4, -97.0, -34.3, -100.4, -36.8, -97.6, -45.6, -123.9, -53.8,
		-123.6, -54.3, -114.8, -70.7, -100.9, -55.9, -98.6, -56.3, -87.9, -58.5, -85.0, -56.5, -88.9, -43.8,
		-63.7, -36.1, -59.8, -48.8, -53.6, -44.9, -64.0, -34.7, -44.0, -14.6, -44.1, -14.0, -44.2, -13.2,
		-44.3, -12.7, -69.0, -20.5, -71.7, -11.7],
]
const LOW := [54.2, 92.3, 76.8, 99.8, 72.7, 112.1, 67.9, 110.6, 64.9, 109.5, 50.1, 104.7]
const STATION := [16.2, 107.3, 28.1, 97.5, 29.9, 98.1, 50.1, 104.7, 48.4, 107.9, 46.6, 110.8, 41.4, 119.4, 33.9, 126.2]
const PAVILION := [-46.0, -56.8, -18.6, -48.5, -22.0, -38.2, -22.5, -36.8, -49.8, -46.4, -52.5, -49.0]
const STAIR := [-52.5, -49.0, -67.9, -63.9, -67.4, -64.5, -64.2, -68.1, -46.0, -56.8]
const BRIDGE := [-76.3, -15.5, -78.0, -13.9, -72.1, -10.5, -71.7, -11.7]
## Metro entrance A on the mall hall's face to the square (OSM node
## 4050038154) and the Otaniementie door of the station hall (node 5026528602).
const METRO_A := Vector2(48.4, 90.2)
const METRO_SOUTH := Vector2(48.4, 107.9)

const BRICK_M := 9.0
const GLASS_M := 17.5
const LINK_M := 10.0
const LOW_M := 10.5
const STATION_M := 6.2
## The Tietotie pavilion's eaves and ridge.
const PAVILION_EAVE := 4.4
const PAVILION_M := 7.5
## The corner the glazed diamond cuts away, and how far back along each wall.
const DIAMOND_CORNER := 5
const DIAMOND_SIDE := 7.0

static func vare(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	for flat in GLASS_TOPS:
		_glass_top(lm, W._poly(flat))
	for i in TALL.size():
		_tall(lm, W._poly(TALL[i]), float(TALL_M[i]), bool(TALL_PERF[i]), bool(TALL_LOUVRE[i]))
	for i in HALLS.size():
		_hall(lm, W._poly(HALLS[i]), float(HALLS_M[i]))
	for flat in LINKS:
		var poly := W._poly(flat)
		lm.poly_prism("Glass", poly, 0.0, LINK_M, false)
		W.ribs(lm, "Black", poly, 0.0, LINK_M, 1.5, 0.1, 0.14)
		W.ribbons(lm, "Black", poly, 4.6, 0.25, 1, 4.6, 0.1)
		lm.poly_prism("Black", F.offset(poly, 0.1), LINK_M - 0.7, LINK_M + 0.1, false)
		lm.poly_prism("Roof", poly, LINK_M - 0.05, LINK_M)
	_low(lm, W._poly(LOW))
	var bridge := W._poly(BRIDGE)
	lm.poly_prism("Glass", bridge, 4.6, HALLS_M[0] - 0.5)
	W.ribs(lm, "Black", bridge, 4.6, HALLS_M[0] - 0.5, 1.5, 0.08, 0.1)
	var pavilion := W._poly(PAVILION)
	lm.poly_prism("Glass", pavilion, 0.0, 4.6, false)
	W.ribs(lm, "Black", pavilion, 0.0, 4.6, 1.5, 0.1, 0.12)
	lm.poly_prism("Black", F.offset(pavilion, 0.4), 4.6, 5.2)
	_stair(lm, W._poly(STAIR))
	_station_hall(lm, W._poly(STATION))
	_mall_front(lm)
	lm.commit(model, "Vare_")

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Glass", LandmarkMaterials.glass("#2F3E46"))
	lm.use("Silver", LandmarkMaterials.pbr("concrete", "#B3BDC3", 3.0, 0.2, 0.55))
	lm.use("Pane", LandmarkMaterials.pbr("concrete", "#7D8E98", 3.0, 0.12, 0.6))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#74382A", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#4F5253", 0.8))
	lm.use("Alu", LandmarkMaterials.paint("#9EA4A7", 0.45, 0.5))
	lm.use("Black", LandmarkMaterials.paint("#1E1F20", 0.6, 0.4))
	lm.use("Soffit", LandmarkMaterials.pbr("sheet_metal", "#8A5236", 1.5, 0.5, 0.5))
	lm.use("Sign", LandmarkMaterials.lit("#E5322D", 0.5))

## Brick base with two rows of tall slots, the silver glass box above it.
static func _glass_top(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	lm.poly_prism("Brick", poly, 0.0, BRICK_M, false)
	W.edge_windows(lm, "Glass", poly, 0.6, 1, 0.0, 1.35, 0.62, 3.6)
	W.edge_windows(lm, "Glass", poly, 4.9, 1, 0.0, 1.35, 0.62, 3.0)
	var box := F.offset(poly, 0.15)
	lm.poly_prism("Silver", box, BRICK_M, GLASS_M - 0.3, false)
	W.ribbons(lm, "Pane", box, BRICK_M + 1.2, 2.2, 2, 4.0, 0.04)
	W.ribs(lm, "Alu", box, BRICK_M, GLASS_M - 0.3, 1.35, 0.07, 0.1)
	W.ribbons(lm, "Alu", box, BRICK_M, 0.25, 3, 4.0, 0.08)
	lm.poly_prism("Alu", F.offset(box, 0.08), GLASS_M - 0.4, GLASS_M)
	lm.poly_prism("Roof", box, GLASS_M, GLASS_M + 0.02)

## Tall brick block: glazed or perforated-metal ground storey, rows of
## slots, a solid brick top; with `louvre`, a band of vertical brick fins
## over a dark recess below the top.
static func _tall(lm: LandmarkMesh, poly: PackedVector2Array, top: float, perf: bool, louvre: bool) -> void:
	var ground := 6.5
	var inset := F.offset(poly, -0.2)
	lm.poly_prism("Silver" if perf else "Glass", inset, 0.0, ground, false)
	W.ribs(lm, "Black" if not perf else "Alu", inset, 0.0, ground, 1.5, 0.1, 0.12)
	lm.poly_prism("Brick", poly, ground, top)
	var slots_top := top - (6.5 if louvre else 2.6)
	var rows := maxi(int((slots_top - ground - 0.8) / 3.4), 1)
	W.edge_windows(lm, "Glass", poly, ground + 0.8, rows, 3.4, 1.35, 0.62, 2.7)
	if louvre:
		lm.poly_prism("Black", F.offset(poly, 0.02), top - 6.0, top - 1.4, false)
		W.ribs(lm, "Brick", poly, top - 6.0, top - 1.4, 0.45, 0.14, 0.25)
	lm.poly_prism("Alu", F.offset(poly, 0.05), top - 0.15, top, false)

## Dark curtain-wall volume: tall glass in black frames, a floor line every
## 4.5 m and a black fascia.
static func _hall(lm: LandmarkMesh, poly: PackedVector2Array, top: float) -> void:
	lm.poly_prism("Glass", poly, 0.0, top - 1.0, false)
	W.ribs(lm, "Black", poly, 0.0, top - 1.0, 1.8, 0.1, 0.14)
	W.ribbons(lm, "Black", poly, 4.5, 0.3, maxi(int((top - 2.0) / 4.5), 1), 4.5, 0.1)
	lm.poly_prism("Black", F.offset(poly, 0.12), top - 1.2, top)
	lm.poly_prism("Roof", poly, top - 0.02, top + 0.02)

## A Bloc's block on the square: brick piers under a band of silver glass.
static func _low(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var glass_y := 5.6
	lm.poly_prism("Glass", F.offset(poly, -0.3), 0.0, glass_y, false)
	lm.poly_prism("Brick", F.offset(poly, -0.3), glass_y - 0.9, glass_y, false)
	W.ribs(lm, "Brick", poly, 0.0, glass_y, 2.4, 0.7, 0.3)
	var box := F.offset(poly, 0.1)
	lm.poly_prism("Silver", box, glass_y, LOW_M - 0.3, false)
	W.ribbons(lm, "Pane", box, glass_y + 0.6, 2.4, 1, 4.0, 0.04)
	W.ribs(lm, "Alu", box, glass_y, LOW_M - 0.3, 1.35, 0.07, 0.1)
	lm.poly_prism("Alu", F.offset(box, 0.08), LOW_M - 0.4, LOW_M)
	lm.poly_prism("Roof", box, LOW_M, LOW_M + 0.02)

## The black metal wedge: steps climbing from its far end to the
## pavilion roof.
static func _stair(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var low := (poly[1] + poly[2]) * 0.5
	var high := (poly[0] + poly[4]) * 0.5
	var along := (high - low).normalized()
	var span := low.distance_to(high)
	var across := Vector2(-along.y, along.x)
	var steps := 14
	for k in steps:
		var d0 := span * float(k) / float(steps)
		var d1 := span * float(k + 1) / float(steps) + 0.05
		var band := PackedVector2Array([low + along * d0 - across * 40.0, low + along * d1 - across * 40.0,
			low + along * d1 + across * 40.0, low + along * d0 + across * 40.0])
		for piece in Geometry2D.intersect_polygons(poly, band):
			lm.poly_prism("Black", piece, 0.0, 0.4 + 4.8 * float(k + 1) / float(steps))

## The station's entrance hall: glass in black frames under a deep black
## metal canopy with a warm perforated soffit, the red station sign over
## the Otaniementie doors and the metro sign on its pole.
static func _station_hall(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var eave := STATION_M - 1.4
	lm.poly_prism("Glass", poly, 0.0, eave, false)
	W.ribs(lm, "Black", poly, 0.0, eave, 1.6, 0.1, 0.12)
	var canopy := F.offset(poly, 2.4)
	_underside(lm, "Soffit", canopy, eave)
	lm.poly_prism("Black", canopy, eave, STATION_M)
	_sign(lm, poly, METRO_SOUTH, eave - 0.9)
	_metro_pole(lm, poly, METRO_SOUTH, 5.0)

## The mall hall's face to the square: the yellow graphic on its glass,
## the canopy and red sign over metro entrance A and the metro sign pole.
static func _mall_front(lm: LandmarkMesh) -> void:
	var hall := W._poly(HALLS[1])
	var a := Vector2(43.1, 86.1)
	var b := Vector2(54.2, 92.3)
	var out := W.outward(hall, a, b)
	var along := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	var mid := a.lerp(b, 0.45) + out * 0.2
	lm.use("Yellow", LandmarkMaterials.paint("#E8C619", 0.5, 0.1))
	for bar in [[-2.6, 7.6, 3.4, 0.5], [-0.6, 8.6, 2.6, -0.6], [1.4, 7.0, 3.0, 0.3], [0.2, 9.6, 2.2, 0.9]]:
		var c := mid + along * float(bar[0])
		lm.box("Yellow", Vector3(c.x, float(bar[1]), c.y), Vector3(float(bar[2]), 0.9, 0.06),
			basis * Basis(Vector3.BACK, float(bar[3])), 0.0)
	var cc := METRO_A + out * 1.6
	lm.box("Black", Vector3(cc.x, 4.4, cc.y), Vector3(9.0, 0.7, 3.2), basis, 0.0)
	lm.box("Soffit", Vector3(cc.x, 4.03, cc.y), Vector3(8.8, 0.04, 3.0), basis, 0.0)
	_sign(lm, hall, METRO_A, 3.2)
	_metro_pole(lm, hall, METRO_A, 9.0)

## The red station-name band over a door at `at` on the edge of `poly`.
static func _sign(lm: LandmarkMesh, poly: PackedVector2Array, at: Vector2, y: float) -> void:
	var best := 0
	var dist := INF
	for i in poly.size():
		var d := Geometry2D.get_closest_point_to_segment(at, poly[i], poly[(i + 1) % poly.size()]).distance_to(at)
		if d < dist:
			dist = d
			best = i
	var a := poly[best]
	var b := poly[(best + 1) % poly.size()]
	var along := (b - a).normalized()
	var out := W.outward(poly, a, b)
	var p := Geometry2D.get_closest_point_to_segment(at, a, b) + out * 0.25
	lm.box("Sign", Vector3(p.x, y, p.y), Vector3(4.8, 0.55, 0.12), Basis(Vector3.UP, atan2(-along.y, along.x)), 0.0)

## The red metro "M" sign on its steel pole, `away` metres out from a door.
static func _metro_pole(lm: LandmarkMesh, poly: PackedVector2Array, at: Vector2, away: float) -> void:
	var best := Vector2.ZERO
	var dist := INF
	var out := Vector2.ZERO
	for i in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(at, poly[i], poly[(i + 1) % poly.size()])
		if q.distance_to(at) < dist:
			dist = q.distance_to(at)
			best = q
			out = W.outward(poly, poly[i], poly[(i + 1) % poly.size()])
	var p := best + out * away
	lm.frustum("Alu", Vector3(p.x, 0.0, p.y), 0.07, 0.07, 4.2, 8)
	lm.box("Sign", Vector3(p.x, 4.75, p.y), Vector3(0.9, 1.1, 0.9), Basis(), 0.0)

## Downward-facing cap of `poly` at height y (seen from below).
static func _underside(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(c.x, y, c.y), Vector3(b.x, y, b.y),
			Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, c, b)

## Aalto University metro station's Tietotie entrance (OSM way 408595707,
## node 4104851062), about the outline centroid: a granite plinth, full-
## height glazing in black frames, a black wall of standing-seam metal on
## its long back, and a steep black standing-seam roof folded over it. One
## corner is cut away by the glazed diamond: a glass plane sloping from the
## eaves down to a low tip at the corner, and the glazed roof facet above.
static func station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#5E5F5D", 3.0))
	lm.use("Sky", LandmarkMaterials.pbr("concrete", "#D3DEE4", 3.0, 0.25, 0.15))
	var poly := W.outline("aalto_university_metro_station")
	lm.poly_prism("Granite", F.offset(poly, 0.2), 0.0, 0.5)
	var cut := _chamfer(poly, DIAMOND_CORNER, DIAMOND_SIDE)
	lm.poly_prism("Glass", cut, 0.5, PAVILION_EAVE, false)
	W.ribs(lm, "Black", cut, 0.5, PAVILION_EAVE, 1.6, 0.1, 0.12)
	# The long back (edge 6 -> 0) is black metal to the eaves.
	var a := poly[6]
	var b := poly[0]
	var out := W.outward(poly, a, b)
	var a3 := Vector3(a.x, 0.5, a.y) + Vector3(out.x, 0.0, out.y) * 0.2
	var b3 := Vector3(b.x, 0.5, b.y) + Vector3(out.x, 0.0, out.y) * 0.2
	lm.quad("Black", a3, b3, b3 + Vector3.UP * (PAVILION_EAVE - 0.5), a3 + Vector3.UP * (PAVILION_EAVE - 0.5),
		Vector3(out.x, 0.0, out.y))
	_diamond(lm, poly, cut)
	var eaves := F.offset(cut, 0.3)
	lm.poly_prism("Black", eaves, PAVILION_EAVE - 0.3, PAVILION_EAVE, false)
	_folded_roof(lm, eaves, _centre(eaves), _chord_mid(poly))
	_metro_pole(lm, poly, Vector2(-17.8, 11.2), 4.0)
	_sign(lm, poly, Vector2(-17.8, 11.2), PAVILION_EAVE - 0.6)
	lm.commit(model, "Aalto_metro_")

static func _centre(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	return c / float(poly.size())

## `poly` with corner k cut off `side` metres back along both edges.
static func _chamfer(poly: PackedVector2Array, k: int, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		if i == k:
			out.append(poly[k] + (poly[(k + n - 1) % n] - poly[k]).normalized() * side)
			out.append(poly[k] + (poly[(k + 1) % n] - poly[k]).normalized() * side)
		else:
			out.append(poly[i])
	return out

static func _chord_mid(poly: PackedVector2Array) -> Vector2:
	var cut := _chamfer(poly, DIAMOND_CORNER, DIAMOND_SIDE)
	return (cut[DIAMOND_CORNER] + cut[DIAMOND_CORNER + 1]) * 0.5

## Steep standing-seam roof from the eaves ring up to a flat crown at
## PAVILION_M, seams every 0.6 m; the facet over the cut corner (nearest
## `glazed`) is glass in black frames.
static func _folded_roof(lm: LandmarkMesh, eaves: PackedVector2Array, cen: Vector2, glazed: Vector2) -> void:
	var s := 0.45
	var y0 := PAVILION_EAVE
	var glass_edge := 0
	var best := INF
	for i in eaves.size():
		var d := ((eaves[i] + eaves[(i + 1) % eaves.size()]) * 0.5).distance_to(glazed)
		if d < best:
			best = d
			glass_edge = i
	for i in eaves.size():
		var j := (i + 1) % eaves.size()
		var p0 := Vector3(eaves[i].x, y0, eaves[i].y)
		var p1 := Vector3(eaves[j].x, y0, eaves[j].y)
		var q0v := cen + (eaves[i] - cen) * s
		var q1v := cen + (eaves[j] - cen) * s
		var q0 := Vector3(q0v.x, PAVILION_M, q0v.y)
		var q1 := Vector3(q1v.x, PAVILION_M, q1v.y)
		var n := (p1 - p0).cross(q0 - p0).normalized()
		if n.y < 0.0:
			n = -n
		var glass := i == glass_edge
		lm.quad("Sky" if glass else "Black", p0, p1, q1, q0, n)
		var count := int(p0.distance_to(p1) / (1.6 if glass else 0.6))
		for k in range(1, count):
			var t := float(k) / float(count)
			lm.beam("Black" if glass else "Roof", p0.lerp(p1, t) + n * 0.03, q0.lerp(q1, t) + n * 0.03, 0.04, 0.05)
	var crown := PackedVector2Array()
	for p in eaves:
		crown.append(cen + (p - cen) * s)
	lm.poly_prism("Black", crown, PAVILION_M - 0.02, PAVILION_M)

## The sloped glass of the diamond under the cut corner: from the chord at
## the eaves down to a low tip at the corner, closed by glass triangles
## along both walls, with black frames on its edges.
static func _diamond(lm: LandmarkMesh, poly: PackedVector2Array, cut: PackedVector2Array) -> void:
	var c := poly[DIAMOND_CORNER]
	var l2 := cut[DIAMOND_CORNER]
	var r2 := cut[DIAMOND_CORNER + 1]
	var tip := Vector3(c.x, 1.0, c.y)
	var left := Vector3(l2.x, PAVILION_EAVE, l2.y)
	var right := Vector3(r2.x, PAVILION_EAVE, r2.y)
	var away := (c - (l2 + r2) * 0.5).normalized()
	var n := (left - tip).cross(right - tip).normalized()
	if n.dot(Vector3(away.x, 0.0, away.y)) < 0.0:
		n = -n
	lm.tri("Sky", tip, left, right, n, n, n, Vector2.ZERO, Vector2(6, 0), Vector2(0, 6))
	for side in [[l2, left], [r2, right]]:
		var foot: Vector2 = side[0]
		var top: Vector3 = side[1]
		var o := W.outward(poly, foot, c)
		var o3 := Vector3(o.x, 0.0, o.y)
		lm.tri("Sky", Vector3(foot.x, 0.5, foot.y), Vector3(c.x, 0.5, c.y), tip, o3, o3, o3,
			Vector2.ZERO, Vector2(6, 0), Vector2(0, 1))
		lm.tri("Sky", Vector3(foot.x, 0.5, foot.y), tip, top, o3, o3, o3,
			Vector2.ZERO, Vector2(6, 0), Vector2(0, 4))
	for e in [[tip, left], [tip, right], [left, right], [tip, Vector3(c.x, 0.5, c.y)]]:
		lm.beam("Black", e[0], e[1], 0.1, 0.12)
