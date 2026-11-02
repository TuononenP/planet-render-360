class_name LandmarkSaoRio
extends RefCounted

## Rio de Janeiro: Christ the Redeemer and the Metropolitan Cathedral of
## Saint Sebastian, in true metres.

# --- Christ the Redeemer ---

const STATUE_Y := 8.0
const ARM_SPAN := 28.0

## Art Deco soapstone statue (30 m, arms 28 m wide) on its 8 m granite
## chapel pedestal: robed body, neck and head, level outstretched arms
## with draped sleeves. Built facing -Z; the registry yaw turns it to
## face Guanabara Bay.
static func christ(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Soapstone", LandmarkMaterials.pbr("limestone", "#C7CBBE", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#908A80", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	_pedestal(lm)
	_body(lm)
	_arms(lm)
	lm.commit(model)

## Footing, tapering chapel block and the capping slab, to y = 8.
static func _pedestal(lm: LandmarkMesh) -> void:
	lm.box("Granite", Vector3(0, -2.0, 0), Vector3(16.0, 4.0, 16.0))
	lm.box("Granite", Vector3(0, 0.75, 0), Vector3(14.0, 1.5, 14.0))
	lm.spire("Granite", Vector3(0, 1.5, 0), 5.2, 6.5, 3.7)
	lm.box("Granite", Vector3(0, 7.75, 0), Vector3(8.4, 0.5, 8.4))
	# Chapel door and slit windows on the front (-Z) face.
	lm.box("Windows", Vector3(0, 3.6, -4.46), Vector3(1.6, 3.2, 0.2))
	for x in [-2.4, 2.4]:
		lm.box("Windows", Vector3(x, 5.2, -4.2), Vector3(0.5, 1.8, 0.2))

## Robe, neck and head as surfaces of revolution (slimmer front to back).
static func _body(lm: LandmarkMesh) -> void:
	var robe := PackedVector2Array([Vector2(2.7, 0.0), Vector2(2.4, 5.0), Vector2(2.0, 11.0),
		Vector2(1.65, 16.5), Vector2(1.75, 20.5), Vector2(2.1, 22.8), Vector2(1.8, 24.6),
		Vector2(0.95, 25.6), Vector2(0.65, 26.2), Vector2(0.6, 27.0)])
	lm.lathe("Soapstone", Vector3(0, STATUE_Y, 0), robe, 16, 1.0, 0.8)
	var head := PackedVector2Array([Vector2(0.55, 0.0), Vector2(1.0, 0.7), Vector2(1.2, 1.8),
		Vector2(1.0, 2.8), Vector2(0.45, 3.2), Vector2(0.0, 3.2)])
	lm.lathe("Soapstone", Vector3(0, STATUE_Y + 26.8, 0), head, 14, 1.0, 0.9)

## Both arms: upper arm, forearm, a hand, and the sleeve fold hanging below.
static func _arms(lm: LandmarkMesh) -> void:
	var half := ARM_SPAN * 0.5
	for s in [-1.0, 1.0]:
		var sh := Vector3(s * 1.4, STATUE_Y + 23.0, 0)
		var el := Vector3(s * 8.0, STATUE_Y + 22.7, 0)
		var wr := Vector3(s * (half - 0.6), STATUE_Y + 22.3, 0)
		lm.beam("Soapstone", sh, el, 2.0, 1.6)
		lm.beam("Soapstone", el, wr, 1.5, 1.2)
		lm.box("Soapstone", Vector3(s * half, STATUE_Y + 22.2, 0), Vector3(1.2, 0.7, 0.9))
		# Draped cloth under the arm, deepest at the shoulder.
		for k in 4:
			var t := float(k) / 4.0
			var x: float = s * lerpf(2.4, 11.0, t)
			var d := lerpf(3.4, 0.6, t)
			lm.box("Soapstone", Vector3(x, STATUE_Y + 22.0 - d * 0.5, 0), Vector3(2.2, d, 1.1))

# --- Metropolitan Cathedral of Rio de Janeiro ---

const CONE_HEIGHT := 96.0
## Concrete cone profile as (height, radius): 106 m across the base.
static var CONE := PackedVector2Array([Vector2(0, 53.0), Vector2(12, 48.0), Vector2(30, 42.0),
	Vector2(55, 36.0), Vector2(80, 30.0), Vector2(96, 27.0)])

## The truncated concrete cone (96 m high, 106 m across), four tall
## stained-glass strips meeting in a cross at the roof, and the
## separate concrete bell tower beside it.
static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9C968C", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F5A6B"))
	var prof := PackedVector2Array()
	prof.append(Vector2(56.0, -3.0))
	for i in 13:
		var y := CONE_HEIGHT * float(i) / 12.0
		prof.append(Vector2(LandmarkMesh.profile_at(CONE, y), y))
	lm.lathe("Concrete", Vector3.ZERO, prof, 40)
	for k in 4:
		_glass_strip(lm, PI * 0.5 * float(k))
	# Skylight cross across the flat roof.
	lm.box("Glass", Vector3(0, CONE_HEIGHT + 0.1, 0), Vector3(46.0, 0.2, 5.0))
	lm.box("Glass", Vector3(0, CONE_HEIGHT + 0.1, 0), Vector3(5.0, 0.2, 46.0))
	# Campanile: a slab tower with a belfry slot, standing in the plaza.
	lm.box("Concrete", Vector3(-72.0, 11.0, 26.0), Vector3(9.0, 25.0, 9.0))
	lm.box("Glass", Vector3(-72.0, 21.0, 21.4), Vector3(3.0, 6.0, 0.2))
	lm.commit(model)

## One vertical window strip up the cone flank at azimuth `a`, 6 m wide.
static func _glass_strip(lm: LandmarkMesh, a: float) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var t := Vector3(-sin(a), 0, cos(a))
	var steps := 10
	for j in steps:
		var y0 := 6.0 + (CONE_HEIGHT - 6.0) * float(j) / steps
		var y1 := 6.0 + (CONE_HEIGHT - 6.0) * float(j + 1) / steps
		var c0 := d * (LandmarkMesh.profile_at(CONE, y0) + 0.25) + Vector3(0, y0, 0)
		var c1 := d * (LandmarkMesh.profile_at(CONE, y1) + 0.25) + Vector3(0, y1, 0)
		lm.quad("Glass", c0 - t * 3.0, c0 + t * 3.0, c1 + t * 3.0, c1 - t * 3.0,
			(d + Vector3.UP * 0.3).normalized())
