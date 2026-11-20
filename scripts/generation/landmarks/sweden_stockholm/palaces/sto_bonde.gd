extends RefCounted

## Bondeska palatset (Bonde Palace, 1662-73, Tessin the Elder), Riddarholmen
## side of Gamla stan, now the Supreme Court. Origin at the OSM footprint
## centre (35.0 x 72.7 m), long axis along Z, the street front toward -Z
## (registry yaw -39.1; +Z is the garden).
##
## H plan: two 10 m wings run the whole 72.7 m and a 24 m cross block joins
## them in the middle, so each end has a court 15 m wide open to the street
## (front, behind an iron fence and gate) and to the garden (rear).
## - Plastered cream walls with grey string courses and a granite base. The
##   wings are three storeys under a cornice at 14.5 m: small base windows,
##   arched piano nobile windows on the wing ends, plain upper windows.
## - The cross block (front.jpg, quarter.jpg) is taller: a base with the
##   arched door and a stair, then two storeys between giant Ionic pilasters
##   (five bays of 3 m), a stucco festoon under every upper window, an
##   entablature at 16.5 m, a low attic with small windows, and a triangular
##   pediment with a clock over the three centre bays.
## - The roofs are copper behind an iron balustrade on the cornices; the
##   cross block's hip rises to 22.8 m under a small cupola (23.5 m).
##
## Sources: docs/stockholm-landmark-sources.md (way 16095343, 72.7 x 35.0 m,
## 23.5 m, built 1673) and the three Commons photos in
## visual-plan/refs/landmarks/bonde_palace/ (street front, garden front,
## festoon detail). Only those three exist; the wing depths and the number of
## bays on the long sides are approximate.

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const HX := 17.5
const HZ := 36.35
const WING_IN := 7.5
const CROSS_Z := 12.0
const BASE_H := 1.2
const WING_TOP := 14.5
const CROSS_TOP := 16.5
const ATTIC_TOP := 19.4
const PIL_TOP := 14.4

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := Kit.fresh(mats)
	var parts := {
		"base": Kit.window(mats, "Frame", 1.2, 1.5),
		"arch": Kit.window(mats, "Frame", 1.6, 3.4, true),
		"mid": Kit.window(mats, "Frame", 1.5, 2.9),
		"up": Kit.window(mats, "Frame", 1.4, 2.8),
		"cmid": Kit.window(mats, "Frame", 1.5, 2.9),
		"cup": Kit.window(mats, "Frame", 1.5, 3.2),
		"attic": Kit.window(mats, "Frame", 1.1, 1.3),
		"door": Kit.window(mats, "Frame", 1.9, 3.4, true, 0.28),
		"pil": Kit.pilaster(mats, "Wall", PIL_TOP - 4.4, 0.8, 0.3, "ionic"),
		"fest": Kit.festoon(mats, "Band", 2.0, 0.6),
	}
	_walls(lm)
	_wing_windows(lm, parts)
	_cross_front(lm, parts, -1.0)
	_cross_front(lm, parts, 1.0)
	_roofs(lm)
	_rails(lm)
	_forecourt(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr("render", "#E6E0D2", 3.0),
		"Band": LandmarkMaterials.pbr("render", "#9E9C90", 3.0),
		"Base": LandmarkMaterials.pbr("stone", "#9A8C78", 2.5),
		"Frame": LandmarkMaterials.pbr("render", "#7F8669", 2.5),
		"Copper": LandmarkMaterials.pbr("copper", "#5A8670", 2.0),
		"Glass": LandmarkMaterials.glass("#2A3236"),
		"Iron": LandmarkMaterials.paint("#26282A", 0.5, 0.5),
		"Gold": LandmarkMaterials.gold(),
		"Paving": LandmarkMaterials.pbr("pavement", "#8F8B82", 3.0),
		"Lamp": LandmarkMaterials.lit("#FFE2A8", 0.8),
	}

# --- Walls -----------------------------------------------------------------

## Wings, cross block and attic, granite base, string courses, cornices.
static func _walls(lm: LandmarkMesh) -> void:
	var wing_w := HX - WING_IN
	for s in [-1.0, 1.0]:
		var cx: float = float(s) * (HX + WING_IN) * 0.5
		FhU.blk(lm, "Wall", cx, 0.0, 0.0, wing_w, WING_TOP, HZ * 2.0)
		FhP.box_band(lm, "Base", cx, 0.0, wing_w, HZ * 2.0, 0.0, BASE_H, 0.12)
		FhP.box_band(lm, "Band", cx, 0.0, wing_w, HZ * 2.0, 4.3, 0.35, 0.1)
		FhP.box_band(lm, "Band", cx, 0.0, wing_w, HZ * 2.0, 9.2, 0.25, 0.08)
		FhP.box_band(lm, "Wall", cx, 0.0, wing_w, HZ * 2.0, WING_TOP - 0.9, 0.9, 0.45)
		FhP.box_band(lm, "Copper", cx, 0.0, wing_w, HZ * 2.0, WING_TOP, 0.08, 0.5)
	# Cross block: walls to the entablature, the attic above it.
	FhU.blk(lm, "Wall", 0.0, 0.0, 0.0, WING_IN * 2.0, CROSS_TOP, CROSS_Z * 2.0)
	FhP.box_band(lm, "Base", 0.0, 0.0, WING_IN * 2.0, CROSS_Z * 2.0, 0.0, BASE_H, 0.12)
	FhP.box_band(lm, "Band", 0.0, 0.0, WING_IN * 2.0, CROSS_Z * 2.0, 4.3, 0.35, 0.1)
	FhP.box_band(lm, "Band", 0.0, 0.0, WING_IN * 2.0, CROSS_Z * 2.0, PIL_TOP, 0.9, 0.18)
	FhP.box_band(lm, "Wall", 0.0, 0.0, WING_IN * 2.0, CROSS_Z * 2.0, CROSS_TOP - 0.9, 0.9, 0.4)
	FhU.blk(lm, "Wall", 0.0, CROSS_TOP, 0.0, WING_IN * 2.0, ATTIC_TOP - CROSS_TOP, CROSS_Z * 2.0 - 0.8)
	FhP.box_band(lm, "Wall", 0.0, 0.0, WING_IN * 2.0, CROSS_Z * 2.0 - 0.8, ATTIC_TOP - 0.5, 0.5, 0.25)
	# Pediments over the three centre bays, front and rear, with a clock.
	for s in [-1.0, 1.0]:
		var z: float = float(s) * (CROSS_Z - 0.4)
		lm.gable("Wall", Vector3(0, ATTIC_TOP, z), 9.0, 0.8, 1.9, Basis(), 0.0, "Wall")
		lm.disc("Gold", Vector3(0, ATTIC_TOP + 0.85, z + float(s) * 0.45), Vector3(0, 0, float(s)), 0.7, 14)

## Windows on the wings: ends, outer sides, inner court faces.
static func _wing_windows(lm: LandmarkMesh, parts: Dictionary) -> void:
	var wing_c := (HX + WING_IN) * 0.5
	# Ends (street and garden), three bays on each wing.
	for s in [-1.0, 1.0]:
		for e in [-1.0, 1.0]:
			var a := Vector3(float(s) * wing_c - 4.5, 0, float(e) * HZ)
			var b := Vector3(float(s) * wing_c + 4.5, 0, float(e) * HZ)
			var out := Vector3(0, 0, float(e))
			Kit.row(lm, parts["base"], a, b, out, 1.4, 3)
			Kit.row(lm, parts["arch"], a, b, out, 5.3, 3)
			Kit.row(lm, parts["up"], a, b, out, 9.8, 3)
	# Long outer sides, 14 bays; inner faces, 5 bays on each court.
	for s in [-1.0, 1.0]:
		var xo: float = float(s) * HX
		var out := Vector3(float(s), 0, 0)
		var a := Vector3(xo, 0, -HZ + 2.0)
		var b := Vector3(xo, 0, HZ - 2.0)
		Kit.row(lm, parts["base"], a, b, out, 1.4, 14)
		Kit.row(lm, parts["mid"], a, b, out, 5.3, 14)
		Kit.row(lm, parts["up"], a, b, out, 9.8, 14)
		var xi: float = float(s) * WING_IN
		var iout := Vector3(-float(s), 0, 0)
		for e in [-1.0, 1.0]:
			var ia := Vector3(xi, 0, float(e) * (CROSS_Z + 1.5))
			var ib := Vector3(xi, 0, float(e) * (HZ - 1.5))
			Kit.row(lm, parts["base"], ia, ib, iout, 1.4, 5)
			Kit.row(lm, parts["mid"], ia, ib, iout, 5.3, 5)
			Kit.row(lm, parts["up"], ia, ib, iout, 9.8, 5)
	# The attic walls above the wing cornices face the courts.
	for s in [-1.0, 1.0]:
		var iout := Vector3(-float(s), 0, 0)
		Kit.row(lm, parts["attic"], Vector3(float(s) * WING_IN, 0, -CROSS_Z + 2.0),
			Vector3(float(s) * WING_IN, 0, CROSS_Z - 2.0), iout, 17.3, 3)

## One long facade of the cross block (the street at -1, the garden at +1):
## door, five bays between six giant pilasters, festoons, attic windows.
static func _cross_front(lm: LandmarkMesh, parts: Dictionary, sgn: float) -> void:
	var z := sgn * CROSS_Z
	var out := Vector3(0, 0, sgn)
	for k in 6:
		Kit.put(lm, parts["pil"], Vector3((float(k) - 2.5) * 3.0, 4.4, z), out)
	for k in 5:
		var x := (float(k) - 2.0) * 3.0
		if k == 2:
			Kit.put(lm, parts["door"], Vector3(x, BASE_H, z), out)
		else:
			Kit.put(lm, parts["base"], Vector3(x, 1.4, z), out)
		Kit.put(lm, parts["cmid"], Vector3(x, 5.2, z), out)
		Kit.put(lm, parts["cup"], Vector3(x, 9.5, z), out)
		Kit.put(lm, parts["fest"], Vector3(x, 8.6, z), out)
		Kit.put(lm, parts["attic"], Vector3(x, 17.2, z + sgn * -0.4), out)
	if sgn < 0.0:
		FhU.steps(lm, "Base", Vector3(0, 0, z), out, 5.0, 0.4, 0.15, 8)

# --- Roofs, rails, forecourt ----------------------------------------------

## Copper hips behind the balustrades, chimneys and the cupola.
static func _roofs(lm: LandmarkMesh) -> void:
	var wing_prof := [[0.0, 0.0], [0.7, 0.6], [2.0, 1.8], [3.4, 2.6]]
	for s in [-1.0, 1.0]:
		var cx: float = float(s) * (HX + WING_IN) * 0.5
		Kit.hip(lm, "Copper", Vector3(cx, WING_TOP + 0.08, 0.0), (HX - WING_IN) * 0.5 + 0.05, HZ + 0.05, wing_prof)
		for z in [-30.0, -20.0, 20.0, 30.0]:
			FhU.blk(lm, "Wall", cx, WING_TOP + 1.9, float(z), 1.3, 1.9, 1.3)
			FhU.blk(lm, "Band", cx, WING_TOP + 3.8, float(z), 1.6, 0.2, 1.6)
	Kit.hip(lm, "Copper", Vector3(0, ATTIC_TOP, 0.0), WING_IN + 0.3, CROSS_Z - 0.4 + 0.3,
		[[0.0, 0.0], [0.7, 0.8], [2.0, 2.4], [3.6, 3.4]])
	# Cupola on the cross-block ridge reaches the 23.5 m of the registry.
	lm.frustum("Copper", Vector3(0, ATTIC_TOP + 3.4, 0), 1.5, 0.8, 0.7, 12)

## Iron balustrade on the wing cornices and round the attic.
static func _rails(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var x0: float = float(s) * WING_IN + float(s) * 0.25
		var x1: float = float(s) * HX - float(s) * 0.25
		var y := WING_TOP + 0.08
		Kit.railing(lm, "Iron", Vector3(x1, y, -HZ + 0.25), Vector3(x1, y, HZ - 0.25), 0.9)
		Kit.railing(lm, "Iron", Vector3(x0, y, -HZ + 0.25), Vector3(x0, y, HZ - 0.25), 0.9)
		for e in [-1.0, 1.0]:
			Kit.railing(lm, "Iron", Vector3(x0, y, float(e) * (HZ - 0.25)), Vector3(x1, y, float(e) * (HZ - 0.25)), 0.9)

## Paving and the iron fence and gate of the street court, lamps, garden
## paving.
static func _forecourt(lm: LandmarkMesh) -> void:
	var zf := -HZ - 0.4
	FhU.blk(lm, "Paving", 0.0, 0.0, (zf - CROSS_Z) * 0.5 - 0.6, WING_IN * 2.0, 0.08, -zf - CROSS_Z - 0.4)
	FhU.blk(lm, "Paving", 0.0, 0.0, (HZ + CROSS_Z) * 0.5 + 0.2, WING_IN * 2.0, 0.08, HZ - CROSS_Z)
	Kit.railing(lm, "Iron", Vector3(-WING_IN, 0.08, zf), Vector3(-1.6, 0.08, zf), 1.7)
	Kit.railing(lm, "Iron", Vector3(1.6, 0.08, zf), Vector3(WING_IN, 0.08, zf), 1.7)
	for x in [-1.6, 1.6, -WING_IN, WING_IN]:
		FhU.blk(lm, "Base", float(x), 0.08, zf, 0.6, 2.0, 0.6)
		lm.lathe("Gold", Vector3(float(x), 2.08, zf), PackedVector2Array([Vector2(0.0, 0), Vector2(0.2, 0.05),
			Vector2(0.22, 0.25), Vector2(0.0, 0.4)]), 8)
	for x in [-1.6, 1.6]:
		lm.lathe("Lamp", Vector3(float(x), 2.5, zf), PackedVector2Array([Vector2(0.0, 0), Vector2(0.22, 0.1),
			Vector2(0.26, 0.4), Vector2(0.18, 0.55), Vector2(0.0, 0.6)]), 8)
