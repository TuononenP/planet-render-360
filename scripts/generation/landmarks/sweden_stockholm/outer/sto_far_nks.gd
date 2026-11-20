extends RefCounted

## Nya Karolinska Solna (NKS, 2018) with the Elite Hotel Carolina Tower
## beside it, Hagastaden. Origin at 59.3490, 18.0322, long axis +X along
## bearing 61 (registry yaw -29), front +Z. All outlines are OSM building
## and building:part ways in the model frame:
##
## - the hospital: a wide five-to-nine-storey comb (ways 1242351060,
##   1242557868, 1242351061 and two connector cores, 6 / 9 / 5 levels and
##   9 / 13 levels) with the eight-storey rear wing (way 359402595) and a low
##   annex (way 1298725816). White enamelled panels with continuous blue
##   glass ribbons, glazed ground storeys under the raised blocks, bands of
##   rusty orange cladding;
## - the Carolina Tower (way 401767667 and parts 1243231504-06, 17 / 16 / 7
##   levels): a white-panelled slab with narrow blue-glass windows in an
##   irregular chequer, the top two storeys fully glazed, 60 m;
## - a grey 17-level block (way 1242681652) to the south-east.
##
## Sources: docs/stockholm-landmark-sources.md (Tier C), the OSM ways above,
## Commons photos in visual-plan/refs/landmarks/nya_karolinska/ (front.jpg:
## the hospital's ribbons, orange cladding and the tower; side.jpg: the
## tower's chequered white and blue facade, glazed crown). Hospital storeys
## are 3.9 m and the hotel's 3.5 m, scaled from front.jpg against the 60 m
## tower; OSM gives levels only, so heights are estimates.

const Far = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_kit.gd")

const FLOOR_HOSP := 3.9
const FLOOR_HOTEL := 3.5
const TOWER_LEVELS := 17
const TOWER_H := 60.0

## [outline, levels, glazed ground storey?]
const BLOCKS := [
	[[Vector2(65.7, 9.8), Vector2(65.6, 29.2), Vector2(-20.2, 27.8), Vector2(-19.9, 8.9), Vector2(17.8, 9.5),
		Vector2(17.9, 4.0), Vector2(32.1, 4.3), Vector2(32.0, 9.6)], 6, true],
	[[Vector2(34.4, -46.5), Vector2(34.1, -57.7), Vector2(66.2, -57.9), Vector2(65.7, 21.4),
		Vector2(34.3, 20.3)], 9, false],
	[[Vector2(66.2, -46.7), Vector2(31.6, -46.5), Vector2(31.6, -44.4), Vector2(17.8, -44.3),
		Vector2(17.8, -46.7), Vector2(-19.3, -46.8), Vector2(-19.2, -67.5), Vector2(66.3, -66.9)], 5, true],
	[[Vector2(17.7, -59.0), Vector2(31.5, -59.0), Vector2(31.6, -44.4), Vector2(17.8, -44.3)], 9, false],
	[[Vector2(17.9, 4.0), Vector2(32.1, 4.3), Vector2(31.8, 20.2), Vector2(17.6, 19.9)], 13, false],
	[[Vector2(-13.8, -88.0), Vector2(68.2, -97.8), Vector2(63.5, -135.0), Vector2(-18.5, -125.2)], 8, false],
	[[Vector2(22.2, -92.3), Vector2(21.7, -67.2), Vector2(-19.2, -67.5), Vector2(-19.4, -85.8),
		Vector2(-13.7, -85.7), Vector2(-13.8, -88.0)], 3, false],
]
## The tower's three volumes: outline, levels.
const TOWER_PARTS := [
	[[Vector2(-55.6, 52.6), Vector2(-71.0, 52.3), Vector2(-71.0, 81.2), Vector2(-55.7, 81.4)], 17],
	[[Vector2(-34.7, 68.9), Vector2(-55.8, 68.8), Vector2(-55.7, 80.1), Vector2(-34.8, 80.4)], 16],
	[[Vector2(-35.8, 52.8), Vector2(-55.6, 52.6), Vector2(-55.8, 68.8), Vector2(-35.9, 68.8)], 7],
]
const GREY := [Vector2(1.4, 91.0), Vector2(0.7, 113.9), Vector2(-13.9, 110.3), Vector2(-13.5, 90.8)]

static func build(model: Node3D) -> void:
	var lm := Far.fresh(_materials())
	for b in BLOCKS:
		_hospital(lm, PackedVector2Array(b[0]), int(b[1]), bool(b[2]))
	for p in TOWER_PARTS:
		_hotel_part(lm, PackedVector2Array(p[0]), int(p[1]))
	_grey_block(lm, PackedVector2Array(GREY), 17)
	_crown(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Panel": LandmarkMaterials.pbr("concrete", "#E7E8E6", 3.0),
		"Grey": LandmarkMaterials.pbr("concrete", "#8A8D90", 3.0),
		"Glass": LandmarkMaterials.glass("#233B58"),
		"Accent": LandmarkMaterials.pbr("terracotta", "#A9552F", 3.0),
		"Roof": LandmarkMaterials.pbr("concrete", "#6A6E72", 3.0),
		"BeaconLamp": LandmarkMaterials.lit("#FF2A1A", 1.2),
	}

## A hospital block: white panel walls, a continuous glass ribbon per
## storey (the ground storey fully glazed under a raised block), an orange
## cladding band two thirds up, flat roof with plant.
static func _hospital(lm: LandmarkMesh, poly: PackedVector2Array, levels: int, glazed_base: bool) -> void:
	var h := float(levels) * FLOOR_HOSP
	lm.poly_prism("Panel", poly, 0.0, h, false)
	var first := 1 if glazed_base else 0
	for k in range(first, levels):
		Far.windows(lm, "Glass", poly, FLOOR_HOSP * float(k) + 1.0, 1, FLOOR_HOSP, 3.1, 2.7, FLOOR_HOSP - 1.7, 6.0)
	if glazed_base:
		Far.band(lm, "Glass", poly, 0.3, FLOOR_HOSP - 0.8, 0.1)
	if levels >= 5:
		Far.band(lm, "Accent", poly, FLOOR_HOSP * float(levels - 2), FLOOR_HOSP * 0.55, 0.25)
	Far.band(lm, "Panel", poly, h - 0.6, 0.6, 0.2)
	lm.poly_prism("Roof", poly, h - 0.02, h + 0.05, true)
	var c := Far.centre(poly)
	lm.box("Roof", Vector3(c.x, h + 1.2, c.y), Vector3(minf(12.0, 6.0 + float(levels)), 2.2, 6.0), Basis(), 0.0)

## One volume of the Carolina Tower: white panel walls with the chequer of
## narrow glass windows.
static func _hotel_part(lm: LandmarkMesh, poly: PackedVector2Array, levels: int) -> void:
	var h := float(levels) * FLOOR_HOTEL
	if levels == TOWER_LEVELS:
		h = TOWER_H - 0.5
	lm.poly_prism("Panel", poly, 0.0, h, false)
	lm.poly_prism("Roof", poly, h - 0.02, h + 0.05, true)
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var len := a.distance_to(b)
		if len < 6.0:
			continue
		var o := Far.out2(poly, i)
		var cols := int(len / 1.7)
		for r in levels - 1:
			for k in cols:
				# An irregular chequer: about 55 % of the cells glazed.
				var hsh := int(absf(sin(float(r) * 12.9898 + float(k) * 78.233 + float(i) * 3.7) * 43758.5453)) % 100
				if hsh > 55 and r > 1:
					continue
				var p := a.lerp(b, (float(k) + 0.5) / float(cols))
				var y := 1.0 + FLOOR_HOTEL * float(r) + 0.4
				Far.FhU.opening(lm, "Glass", Vector3(p.x, y, p.y) + Vector3(o.x, 0, o.y) * 0.08,
					Vector3(o.x, 0, o.y), 1.0, FLOOR_HOTEL - 0.9, false)

## The glazed top two storeys of the tall tower volume and its beacons.
static func _crown(lm: LandmarkMesh) -> void:
	var p := PackedVector2Array(TOWER_PARTS[0][0])
	var top := TOWER_H - 0.5
	lm.poly_prism("Glass", Far.inset(p, -0.12), top - FLOOR_HOTEL * 2.0, top - 0.05, false)
	var c := Far.centre(p)
	for corner in p:
		var q: Vector2 = corner + (c - corner).normalized() * 1.2
		lm.box("BeaconLamp", Vector3(q.x, TOWER_H + 0.2, q.y), Vector3(0.6, 0.4, 0.6), Basis(), 0.0)

## The grey 17-level block: plain ribbon windows on grey panels.
static func _grey_block(lm: LandmarkMesh, poly: PackedVector2Array, levels: int) -> void:
	var h := float(levels) * FLOOR_HOTEL
	lm.poly_prism("Grey", poly, 0.0, h, false)
	Far.windows(lm, "Glass", poly, 1.2, levels - 1, FLOOR_HOTEL, 2.6, 1.6, 1.8, 6.0)
	lm.poly_prism("Roof", poly, h - 0.02, h + 0.05, true)
