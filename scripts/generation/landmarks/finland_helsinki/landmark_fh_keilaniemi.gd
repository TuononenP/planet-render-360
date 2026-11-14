class_name LandmarkFhKeilaniemi
extends RefCounted

## Keilaniemi's waterfront offices, true metres, extruded from their
## OpenStreetMap outlines (LandmarkFhWestFootprints): Finago Tower (CJN
## 1976, 83.6 m, white Sipoo limestone piers and blue-tinted glass,
## end parts projecting from the slab), the KONE Building (2001, 72.6 m
## glass tower) and the low Keilalampi extension with its glass cone.
## Sources and estimates: docs/espoo-landmark-sources.md.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

static func _materials() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	# Concrete-grain finish: the stone texture warms Sipoo limestone to cream.
	lm.use("Limestone", LandmarkMaterials.pbr("concrete", "#F1F0EC", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#38546E"))
	lm.use("Steel", LandmarkMaterials.paint("#6E7579", 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#4C5052", 0.7))
	return lm

## 20 storeys of narrow limestone piers between blue glass, a solid plant
## storey on top and a recessed glazed entrance floor.
static func finago(model: Node3D) -> void:
	var lm := _materials()
	var poly := W.outline("finago_tower")
	var top := 83.6
	lm.poly_prism("Glass", F.offset(poly, -0.6), 0.0, 4.2)
	lm.poly_prism("Limestone", F.offset(poly, -0.4), 4.2, 79.0)
	lm.poly_prism("Glass", F.offset(poly, -0.1), 4.6, 78.6, false)
	W.ribs(lm, "Limestone", poly, 4.2, 79.0, 1.6, 0.7, 0.45)
	# Floor-edge lines read faintly across the piers.
	for i in 19:
		var y := 4.2 + 3.92 * float(i + 1)
		lm.poly_prism("Limestone", F.offset(poly, 0.05), y - 0.12, y + 0.12, false)
	lm.poly_prism("Limestone", F.offset(poly, 0.25), 79.0, top - 0.5)
	lm.poly_prism("Roof", F.offset(poly, -0.8), top - 0.5, top)
	lm.commit(model, "Finago_")

## Dark glass shaft with steel floor bands and mullions, a steel parapet.
static func kone(model: Node3D) -> void:
	var lm := _materials()
	var poly := W.outline("kone_building")
	var top := 72.6
	lm.poly_prism("Glass", poly, 0.0, top - 2.6)
	W.ribs(lm, "Steel", poly, 0.0, top - 2.6, 1.5, 0.12, 0.2)
	# Entrance canopy across the long south-west face.
	U.blk(lm, "Steel", -9.0, 4.2, 8.7, 3.2, 0.4, 14.0, atan2(12.2, 29.7))
	for i in 16:
		var y := 4.6 + 4.1 * float(i)
		lm.poly_prism("Steel", F.offset(poly, 0.2), y, y + 0.35, false)
	lm.poly_prism("Steel", F.offset(poly, 0.3), top - 2.6, top)
	lm.poly_prism("Roof", F.offset(poly, -0.5), top - 2.6, top - 1.0)
	U.blk(lm, "Steel", 2.0, top - 1.0, 4.0, 9.0, 0.8, 6.0)
	lm.commit(model, "Kone_")

## Three glazed storeys on a steel frame, the cone glass roof rising from
## the middle of the plan.
static func keilalampi(model: Node3D) -> void:
	var lm := _materials()
	var poly := W.outline("keilalampi")
	var eave := 13.0
	lm.poly_prism("Limestone", poly, 0.0, eave)
	W.ribbons(lm, "Glass", poly, 1.0, 2.8, 3, 4.0)
	W.ribs(lm, "Steel", poly, 0.0, eave, 6.0, 0.25, 0.3)
	lm.poly_prism("Roof", F.offset(poly, 0.3), eave, eave + 0.6)
	var c := cone_centre()
	lm.frustum("Steel", Vector3(c.x, eave + 0.6, c.y), 13.0, 12.6, 0.6, 32)
	lm.frustum("Glass", Vector3(c.x, eave + 1.2, c.y), 12.6, 0.8, 7.8, 32)
	lm.frustum("Steel", Vector3(c.x, eave + 9.0, c.y), 0.8, 0.0, 0.4, 12)
	lm.commit(model, "Keilalampi_")

## Centre of the cone: the middle of the plan's deepest part.
static func cone_centre() -> Vector2:
	var inner := F.offset(W.outline("keilalampi"), -16.0)
	var sum := Vector2.ZERO
	for p in inner:
		sum += p
	return sum / float(maxi(inner.size(), 1))
