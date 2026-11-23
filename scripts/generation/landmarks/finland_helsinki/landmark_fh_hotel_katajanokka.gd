extends RefCounted

## Hotel Katajanokka, the former Helsinki County Prison (Katajanokan vankila,
## Carl Ludvig Engel's cross plan, 1837; closed 2002), Merikasarminkatu.
## The registry yaw (-39.5) puts the model on OSM way 23192861 (a 62.8 x 63.8 m
## outline, 18 nodes). The model's +Z is its south-east side.
##
## From the Commons photos in visual-plan/refs/landmarks/hotel_katajanokka/:
## - a cross of four wings, each about 15 m wide and 25-33 m long, joined in
##   the middle; the wings meet at a polygon with chamfered re-entrant
##   corners, as the OSM outline shows;
## - warm orange-red machine brick, four storeys on a rock-faced granite
##   base: three rows of small segmental-arched windows in dark frames with
##   cream-painted stone sills, narrow stair windows between, small blind
##   arched windows at the basement;
## - flat-pitched grey sheet-metal roofs, hipped at the wing ends, a tall
##   brick chimney stack with a stone cap (and a smaller one) per wing and
##   black ventilation pipes, a spiral black steel fire stair on one wall;
## - the gabled brick wing ends with stepped brick pilasters;
## - a 4 m brick perimeter wall with a stone coping and a gate, in a loose
##   ring round the cross (OSM ways 37931152 and 37931154), and a small
##   white two-storey annex near the south-west wing.
##
## Measured: cross outline, wall and annex position (OSM). Estimated from the
## photos: 4 levels, eave 13.4 m, roof 2.6 m, the 1.8 m granite base, window
## sizes (1.2 x 1.7 m), the 4.0 m wall height and the stack sizes. Registry
## height_m 16.5 m is the stack tops, estimated; LoD2 was not read here.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const ENTRY := {"type": "hotel_katajanokka", "name": "Hotel Katajanokka", "lat": 60.166651, "lon": 24.969248,
	"radius_m": 1500.0, "wiki_title": "Hotel Katajanokka", "height_m": 16.5, "clear_m": 45.0,
	"yaw_deg": -39.5, "kind": "Hotel", "aliases": ["hotel katajanokka", "katajanokan vankila", "skatuddens fängelse", "helsinki county prison"]}

const POLY := [Vector2(-1.9, 14.5), Vector2(-21.5, 31.9), Vector2(-31.4, 20.7), Vector2(-6.8, -1.1), Vector2(-9.3, -4.0),
	Vector2(-13.8, 0.0), Vector2(-31.4, -19.8), Vector2(-17.8, -31.9), Vector2(2.2, -9.4), Vector2(21.2, -26.4),
	Vector2(31.4, -14.9), Vector2(13.2, 1.3), Vector2(12.8, 5.2), Vector2(26.7, 20.6), Vector2(15.7, 30.5), Vector2(1.7, 14.9)]
## Perimeter wall as two open polylines (OSM 37931154, 37931152).
const WALL_A := [Vector2(-39.4, -27.8), Vector2(-19.6, -45.1), Vector2(5.3, -67.3), Vector2(19.7, -50.8),
	Vector2(25.4, -44.6), Vector2(47.4, -19.9), Vector2(58.2, -7.9), Vector2(52.5, 8.7), Vector2(40.6, 44.3),
	Vector2(33.4, 51.1), Vector2(22.5, 56.3), Vector2(12.8, 59.1), Vector2(5.5, 60.0), Vector2(-6.4, 58.6),
	Vector2(-18.8, 54.3), Vector2(-26.2, 48.7), Vector2(-30.2, 44.4), Vector2(-41.7, 31.4), Vector2(-47.8, 24.5)]
const WALL_B := [Vector2(-51.7, 19.9), Vector2(-65.8, 4.4), Vector2(-60.5, -3.3), Vector2(-49.7, -19.1), Vector2(-44.7, -23.5)]
const BASE := 1.8
const EAVE := 13.4
const RISE := 2.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8452F", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7B746C", 2.5))
	lm.use("Roof", LandmarkMaterials.paint("#6F757C", 0.55, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#262B2F"))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CFC4AE", 2.0))
	lm.use("Black", LandmarkMaterials.paint("#1E2022", 0.6, 0.5))
	lm.use("White", LandmarkMaterials.pbr("render", "#EEE9DD", 3.0))
	var poly := PackedVector2Array(POLY)
	lm.poly_prism("Granite", F.offset(poly, 0.12), 0.0, BASE)
	lm.poly_prism("Brick", poly, BASE, EAVE)
	lm.poly_prism("Trim", F.offset(poly, 0.1), BASE, BASE + 0.3, false)
	lm.poly_prism("Trim", F.offset(poly, 0.3), EAVE - 0.6, EAVE, false)
	# Three storeys of segmental-arched windows with sills; basement slits.
	W.edge_windows(lm, "Glass", poly, 3.3, 3, 3.3, 3.0, 1.2, 1.7, "Trim")
	W.edge_windows(lm, "Glass", poly, 0.5, 1, 3.0, 3.0, 0.9, 0.9)
	_roofs(lm)
	_stacks(lm)
	_stair(lm)
	_wall(lm, WALL_A)
	_wall(lm, WALL_B)
	_annex(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.64)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-2.0, 1.5, -38.0), Vector3(-2.0, 9.0, -14.0), 50.0, 0.85, 50.0, warm],
		[Vector3(2.0, 1.5, 42.0), Vector3(2.0, 9.0, 16.0), 50.0, 0.85, 50.0, warm],
		[Vector3(-40.0, 1.5, 2.0), Vector3(-15.0, 9.0, 2.0), 50.0, 0.85, 50.0, warm],
		[Vector3(40.0, 1.5, -2.0), Vector3(15.0, 9.0, -2.0), 50.0, 0.85, 50.0, warm],
	])

## Hipped sheet-metal roofs over the two bars of the cross (each 15 m
## wide): one from the north-west end to the south-east one, one across it.
static func _roofs(lm: LandmarkMesh) -> void:
	var bars := [[Vector2(-24.6, -25.9), Vector2(21.2, 25.5)], [Vector2(-26.5, 26.3), Vector2(26.2, -20.6)]]
	for bar: Array in bars:
		var a: Vector2 = bar[0]
		var b: Vector2 = bar[1]
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		a -= dir * 0.6
		b += dir * 0.6
		var hw := 7.9
		W.hip_rect(lm, "Roof", a + side * hw, a - side * hw, b - side * hw, b + side * hw, EAVE, RISE)

## Tall brick stacks with stone caps, one on each wing's ridge, and small
## black ventilators.
static func _stacks(lm: LandmarkMesh) -> void:
	for p: Vector2 in [Vector2(-14.0, 14.5), Vector2(-14.0, -13.0), Vector2(11.0, -12.0), Vector2(11.5, 13.0)]:
		U.blk(lm, "Brick", p.x, EAVE + 0.5, p.y, 1.9, 3.0, 1.9)
		U.blk(lm, "Trim", p.x, EAVE + 3.4, p.y, 2.5, 0.3, 2.5)
	for p: Vector2 in [Vector2(-9.0, 8.0), Vector2(-3.0, -4.0), Vector2(8.0, 4.0), Vector2(-20.0, 2.0), Vector2(-2.0, 12.0)]:
		lm.frustum("Black", Vector3(p.x, EAVE + 1.5, p.y), 0.25, 0.25, 1.2, 8)

## The black spiral fire stair against one wing.
static func _stair(lm: LandmarkMesh) -> void:
	lm.frustum("Black", Vector3(-8.0, 0.0, 28.2), 1.6, 1.6, EAVE - 1.0, 14)

## A 4 m brick wall with a stone coping along an open polyline.
static func _wall(lm: LandmarkMesh, pts: Array) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ln := a.distance_to(b)
		var m := (a + b) * 0.5
		var basis := Basis(Vector3.UP, atan2(-(b.y - a.y), b.x - a.x))
		lm.box("Brick", Vector3(m.x, 2.0, m.y), Vector3(ln + 0.2, 4.0, 0.8), basis, 0.0)
		lm.box("Granite", Vector3(m.x, 4.1, m.y), Vector3(ln + 0.3, 0.25, 1.1), basis, 0.0)
		lm.box("Granite", Vector3(m.x, 0.5, m.y), Vector3(ln + 0.2, 1.0, 1.0), basis, 0.0)

## The small white annex south-west of the cross.
static func _annex(lm: LandmarkMesh) -> void:
	var yaw := -0.846
	U.blk(lm, "White", -7.5, 0.0, 32.7, 13.9, 6.8, 11.4, yaw)
	lm.box("Roof", Vector3(-7.5, 7.2, 32.7), Vector3(14.6, 0.8, 12.1), Basis(Vector3.UP, yaw), 0.0)
	lm.box("Roof", Vector3(-7.5, 7.7, 32.7), Vector3(9.0, 0.6, 7.0), Basis(Vector3.UP, yaw), 0.0)
