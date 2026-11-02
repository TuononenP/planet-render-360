class_name LandmarkSaoBrasilia
extends RefCounted

## Oscar Niemeyer's Brasília: the hyperboloid Cathedral and the National
## Congress, in true metres.

# --- Cathedral of Brasília ---

const CROWN_H := 30.0
const COLUMNS := 16
const TWIST := 0.35
## Hyperboloid profile as (height, radius): 70 m across the base,
## pinching in below the crown and flaring again at the top.
static var HYPERBOLOID := PackedVector2Array([Vector2(0, 35.0), Vector2(6, 28.5),
	Vector2(14, 22.0), Vector2(22, 19.0), Vector2(30, 23.5)])

## Sixteen curved concrete columns leaning together into the crown, the
## tinted-glass walls between them, the sunken plaza ring and the
## detached bell tower.
static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D9D5CB", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C5C86"))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#B5B0A6", 4.0))
	var prof := PackedVector2Array()
	for i in 9:
		var y := 1.0 + (CROWN_H - 1.0) * float(i) / 8.0
		prof.append(Vector2(LandmarkMesh.profile_at(HYPERBOLOID, y) - 0.5, y))
	lm.lathe("Glass", Vector3.ZERO, prof, 48)
	for c in COLUMNS:
		var a0 := TAU * float(c) / float(COLUMNS)
		var prev := _column_point(a0, 0.0)
		for s in range(1, 11):
			var p := _column_point(a0, CROWN_H * float(s) / 10.0)
			lm.beam("Concrete", prev, p, 2.0, 1.5)
			prev = p
	lm.frustum("Concrete", Vector3(0, CROWN_H - 0.6, 0), 24.0, 24.0, 0.6, 32)
	# Plaza ring around the base and the descending entrance ramp.
	lm.frustum("Plaza", Vector3(0, -0.5, 0), 48.0, 46.0, 0.5, 40)
	lm.box("Plaza", Vector3(0, 0.1, 44.0), Vector3(12.0, 0.3, 24.0))
	# Campanile: four concrete piers carrying the bells.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Concrete", Vector3(-58.0 + sx * 2.6, 10.0, -22.0 + sz * 2.6), Vector3(1.6, 20.0, 1.6))
	lm.box("Concrete", Vector3(-58.0, 20.0, -22.0), Vector3(7.4, 1.2, 7.4))
	lm.commit(model)

## Column centreline at height y: twisting around the axis as it rises.
static func _column_point(a0: float, y: float) -> Vector3:
	var a := a0 + TWIST * y / CROWN_H
	var r := LandmarkMesh.profile_at(HYPERBOLOID, y)
	return Vector3(cos(a) * r, y, sin(a) * r)

# --- National Congress of Brazil ---

const TOWER_H := 100.0
const ROOF_Y := 10.0

## The long horizontal slab with the Senate dome (north) and the
## Chamber of Deputies bowl (south) on its roof, the twin 100 m office
## towers behind joined by two bridges, and the entrance ramp facing
## the Esplanada (west).
static func congress(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#E2DFD8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#1F3340"))
	lm.use("Pool", LandmarkMaterials.pbr("pavement", "#A9A59B", 4.0))
	lm.box("Concrete", Vector3(0, ROOF_Y * 0.5 - 1.0, 0), Vector3(84.0, ROOF_Y + 2.0, 232.0))
	lm.box("Glass", Vector3(-42.05, 5.0, 0), Vector3(0.2, 6.0, 200.0))
	lm.quad("Pool", Vector3(-40, ROOF_Y, -34), Vector3(-40, ROOF_Y, 34), Vector3(-72, 0, 34),
		Vector3(-72, 0, -34), Vector3(-ROOF_Y, 32.0, 0).normalized())
	LandmarkKits.dome_on_drum(lm, "Concrete", "Concrete", Vector3(-5, ROOF_Y, -50.0), 22.0, 1.0, 11.0)
	_bowl(lm, Vector3(-5, ROOF_Y, 50.0), 34.0)
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(40.0, 0, s * 25.0))
	for y in [42.0, 78.0]:
		lm.box("Concrete", Vector3(40.0, y, 0), Vector3(9.0, 3.5, 16.0))
	lm.commit(model)

## The Chamber's open saucer: lit top face and outer underside.
static func _bowl(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	lm.lathe("Concrete", c, PackedVector2Array([Vector2(r, 8.0), Vector2(r - 2.0, 6.4),
		Vector2(r - 12.0, 3.0), Vector2(r - 24.0, 0.7), Vector2(0.0, 0.2)]), 40, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Concrete", c + Vector3(0, -0.6, 0), PackedVector2Array([Vector2(0.0, 0.0),
		Vector2(r - 24.0, 0.3), Vector2(r - 12.0, 2.3), Vector2(r - 2.0, 5.7), Vector2(r, 7.2),
		Vector2(r, 8.6)]), 40, 1.0, 1.0, 0.0, true, false)

## One office slab: concrete frame, glazed faces and floor bands.
static func _tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Concrete", c + Vector3(0, TOWER_H * 0.5, 0), Vector3(12.0, TOWER_H, 36.0))
	for side in [-1.0, 1.0]:
		lm.box("Glass", c + Vector3(side * 6.05, TOWER_H * 0.5, 0), Vector3(0.2, TOWER_H - 6.0, 32.0))
	for k in 14:
		lm.box("Concrete", c + Vector3(0, 4.0 + 6.8 * float(k), 0), Vector3(12.6, 1.0, 36.6))
