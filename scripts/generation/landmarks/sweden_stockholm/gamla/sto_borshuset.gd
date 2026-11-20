extends RefCounted

## Börshuset (Stock Exchange Building, Erik Palmstedt, 1776-78) on the north
## side of Stortorget, built into the Stortorget model's frame (+X along the
## square at bearing 71.9, +Z toward the south-south-east, so the front faces
## +Z over the square). OSM relation 255059: 53.5 x 34.7 m block, x -21.0 to
## 32.5, front wall on z = -17.8, `building:levels=2`, gabled copper roof,
## `height=29`.
##
## From the photos (visual-plan/refs/landmarks/stortorget_stockholm/side.jpg,
## front.jpg: the pale pink-cream block at the right edge):
## - Two tall storeys under a cornice and a stone balustrade with urns: a
##   rusticated ground floor of tall round-arched windows (14 bays of 3.8 m)
##   and an upper floor of tall rectangular windows with simple surrounds.
## - The five centre bays stand slightly proud under pilasters.
## - A low copper gable roof along the long axis, with the small square
##   lantern tower (open arches, copper dome, gilt finial) on its ridge: the
##   model top, 29 m.
## The Nobel Library inside and the inner court (7.5 x 6.5 m) are not
## visible; the flanks and rear carry plain window rows.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_gamla_kit.gd")

const X0 := -21.0
const X1 := 32.5
const ZF := -17.8
const ZB := -52.5
const CX := (X0 + X1) * 0.5
const ZC := (ZF + ZB) * 0.5
const EAVE := 16.5
const BASE_H := 7.0
const BAYS := 14
const PITCH := (X1 - X0) / float(BAYS)
const RISE := 4.6
const TOP := 29.0

static func build(lm: LandmarkMesh, mats: Dictionary) -> void:
	_mass(lm)
	_front(lm, mats)
	_flanks(lm)
	_roof(lm)
	_tower(lm)

static func _mass(lm: LandmarkMesh) -> void:
	K.Pal.rb(lm, "Pink", X0, X1, 0.0, EAVE, ZB, ZF, 0.0)
	# Rusticated ground floor: horizontal joints as thin bands.
	var y := 1.1
	while y < BASE_H - 0.2:
		K.Pal.rb(lm, "Stone", X0 - 0.04, X1 + 0.04, y, y + 0.1, ZB - 0.04, ZF + 0.06, 0.0)
		y += 1.1
	K.Pal.rb(lm, "Trim", X0 - 0.15, X1 + 0.15, BASE_H - 0.15, BASE_H + 0.3, ZB - 0.15, ZF + 0.3, 0.0)
	K.Pal.rb(lm, "Trim", X0 - 0.5, X1 + 0.5, EAVE - 0.7, EAVE + 0.2, ZB - 0.5, ZF + 0.6, 0.0)
	# Balustrade with urns at the corners and over the centre.
	var a := Vector3(X0 - 0.4, EAVE + 0.2, ZF + 0.5)
	var b := Vector3(X1 + 0.4, EAVE + 0.2, ZF + 0.5)
	LandmarkDetail.balustrade(lm, "Trim", a, b, 1.1, 1.8)
	for x in [X0 + 0.5, CX, X1 - 0.5]:
		K.Pal.urn(lm, "Trim", Vector3(float(x), EAVE + 0.2, ZF + 0.5), 1.5)

static func _front(lm: LandmarkMesh, mats: Dictionary) -> void:
	var out := Vector3(0, 0, 1)
	var offs := K.Pal.evenly(BAYS, PITCH)
	var p := Vector3(CX, 0, ZF)
	# Ground floor: tall arched windows, a door in the middle bays.
	K.Pal.wins(lm, "Trim", "Glass", p, out, offs, 1.2, 2.0, 4.6, true, 0.3)
	# Upper floor: tall windows with surrounds.
	K.Pal.wins(lm, "Trim", "Glass", p, out, offs, BASE_H + 1.5, 1.8, 4.2, false, 0.3)
	# Centre risalit: five bays proud, pilasters between the upper windows.
	var hw := PITCH * 2.5
	K.Pal.rb(lm, "Pink", CX - hw, CX + hw, BASE_H, EAVE - 0.7, ZF, ZF + 0.5, 0.0)
	var pil := K.Baro.pilaster(mats, "Trim", EAVE - 0.7 - BASE_H - 0.3, 0.7, 0.3, "ionic")
	for i in 6:
		var x := CX - hw + float(i) * (hw * 2.0 / 5.0)
		K.place(lm, pil, Vector3(x, BASE_H, ZF + 0.5))
	# Door: the central pair of bays.
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(CX, 2.21, ZF + 0.35), out, 2.4, 4.4, true, 0.35)
	K.Pal.rb(lm, "Stone", CX - 2.0, CX + 2.0, 0.0, 0.35, ZF + 0.2, ZF + 2.0, 0.0)

static func _flanks(lm: LandmarkMesh) -> void:
	var ends := [[Vector3(X1, 0, ZF), Vector3(X1, 0, ZB), Vector3(1, 0, 0)],
		[Vector3(X0, 0, ZB), Vector3(X0, 0, ZF), Vector3(-1, 0, 0)]]
	for e in ends:
		LandmarkFhParts.pierce(lm, "Pink", "Glass", e[0], e[1], e[2], 0.0, EAVE - 0.7, 9, 2,
			Vector2(1.5, 3.4), 1.6, 7.0, 0.25)
	LandmarkFhParts.pierce(lm, "Pink", "Glass", Vector3(X1, 0, ZB), Vector3(X0, 0, ZB), Vector3(0, 0, -1), 0.0,
		EAVE - 0.7, BAYS, 2, Vector2(1.5, 3.4), 1.6, 7.0, 0.25)

static func _roof(lm: LandmarkMesh) -> void:
	# Ridge along X: the roof's width axis turned onto the depth.
	lm.gable("Copper", Vector3(CX, EAVE + 0.2, ZC), ZF - ZB + 0.4, X1 - X0 + 0.4, RISE,
		Basis(Vector3.UP, PI * 0.5), 0.3, "Pink")

static func _tower(lm: LandmarkMesh) -> void:
	var zt := ZC
	var y0 := EAVE + 0.2 + RISE - 1.6
	var h := 5.2
	K.Pal.rb(lm, "Pink", CX - 2.9, CX + 2.9, y0, y0 + h, zt - 2.9, zt + 2.9, 0.0)
	K.Pal.rb(lm, "Trim", CX - 3.2, CX + 3.2, y0 + h, y0 + h + 0.35, zt - 3.2, zt + 3.2, 0.0)
	for s in [[Vector3(0, 0, 1), 2.9], [Vector3(0, 0, -1), 2.9], [Vector3(1, 0, 0), 2.9], [Vector3(-1, 0, 0), 2.9]]:
		var n: Vector3 = s[0]
		var c := Vector3(CX, y0 + 2.5, zt) + n * float(s[1])
		LandmarkDetail.window(lm, "Trim", "Glass", c, n, 1.5, 3.2, true, 0.25)
	var base := Vector3(CX, y0 + h + 0.35, zt)
	lm.lathe("Copper", base, PackedVector2Array([Vector2(3.2, 0.0), Vector2(2.9, 0.5), Vector2(2.1, 1.4),
		Vector2(1.0, 2.2), Vector2(0.4, 2.7), Vector2(0.3, 2.9)]), 16)
	var tip := base + Vector3(0, 2.9, 0)
	lm.lathe("Gold", tip, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.34, 0.12), Vector2(0.36, 0.38),
		Vector2(0.22, 0.6), Vector2(0.0, 0.66)]), 10)
	lm.frustum("Gold", tip + Vector3(0, 0.62, 0), 0.07, 0.015, TOP - (tip.y + 0.62), 6)
