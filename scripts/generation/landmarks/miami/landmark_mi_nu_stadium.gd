class_name LandmarkMiNuStadium
extends RefCounted

## Nu Stadium at Miami Freedom Park — Inter Miami CF (MI-10), opened Apr 4, 2026 (MI-0.3).
## Footprint 215 x 175 m, elliptical plan (semi-axes 100 x 82 m bowl, palm plaza to the footprint edge).
##   - Steep raked concrete seating bowl (26,700 seats) around a striped green pitch (105 x 68 m).
##   - Continuous sweeping white PTFE/ETFE wraparound canopy y = 28..40.0 m rising to the outer rim.
##   - Flamingo-pink (#F7B5CD / #FF5C93) LED inner-rim fins (PinkLamp) and facade fins.
##   - Palm-lined fan plaza.

const HEIGHT_M := 40.0
const SZ := 0.82

static func _ell(r: float, a: float, y: float) -> Vector3:
	return Vector3(cos(a) * r, y, sin(a) * r * SZ)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D9D8D4", 4.0))
	lm.use("White", LandmarkMaterials.paint("#F6F6F3", 0.55, 0.12))
	lm.use("PinkLamp", LandmarkMaterials.lit("#FF5C93", 1.8))
	lm.use("PinkSoft", LandmarkMaterials.paint("#F7B5CD", 0.5, 0.1))
	lm.use("GrassA", LandmarkMaterials.pbr("grass", "#3F8A3A", 3.0))
	lm.use("GrassB", LandmarkMaterials.pbr("grass", "#4E9C45", 3.0))
	lm.use("Seat", LandmarkMaterials.paint("#2A2D34", 0.7, 0.05))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#386B2E", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A5666"))

	_build_bowl(lm)
	_build_pitch(lm)
	_build_canopy(lm)
	_build_facade(lm)
	_build_plaza(lm)
	lm.commit(model)

	var halos: Array = []
	for k: int in 6:
		var a := float(k) / 6.0 * TAU
		halos.append([_ell(62.0, a, 31.0), 7.0, Color(1.0, 0.36, 0.58)])
	model.set_meta(LandmarkLights.HALO_META, halos)

static func _build_bowl(lm: LandmarkMesh) -> void:
	# Raked lower/upper tiers (stepped profile), dark seat shell over concrete
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([
		Vector2(56.0, 0.5), Vector2(60.0, 4.0), Vector2(70.0, 10.0), Vector2(72.0, 13.5),
		Vector2(80.0, 18.0), Vector2(96.0, 27.0), Vector2(96.0, 0.5)]),
		72, 1.0, SZ, 0.0, false, false)
	lm.lathe("Seat", Vector3(0.0, 0.12, 0.0), PackedVector2Array([
		Vector2(56.6, 0.9), Vector2(60.4, 4.2), Vector2(70.2, 10.2), Vector2(72.4, 13.7),
		Vector2(80.2, 18.2), Vector2(95.0, 26.6)]),
		72, 1.0, SZ, 0.0, false, false)
	# Aisle stairs radiating through the seating
	for k: int in 24:
		var a := float(k) / 24.0 * TAU
		var p0 := _ell(58.0, a, 2.6)
		var p1 := _ell(94.0, a, 26.2)
		lm.beam("Concrete", p0, p1, 0.5, 0.2, Vector3.UP.cross(p1 - p0).normalized())

static func _build_pitch(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(0.0, 0.1, 0.0), Vector3(112.0, 0.4, 92.0), Basis(), 0.0)
	for i: int in 14:
		var key := "GrassA" if i % 2 == 0 else "GrassB"
		lm.box(key, Vector3(-48.75 + float(i) * 7.5, 0.35, 0.0), Vector3(7.5, 0.2, 68.0), Basis(), 0.0)
	# Goals
	for sx: float in [-1.0, 1.0]:
		lm.box("White", Vector3(sx * 52.5, 1.2, 0.0), Vector3(0.2, 2.4, 7.3), Basis(), 0.0)

static func _build_canopy(lm: LandmarkMesh) -> void:
	# Sweeping wraparound roof: low inner lip (y = 28) climbing to the outer rim (y = 40.0)
	lm.lathe("White", Vector3.ZERO, PackedVector2Array([
		Vector2(62.0, 28.0), Vector2(62.0, 29.5), Vector2(80.0, 35.0), Vector2(100.0, 40.0),
		Vector2(100.0, 38.0), Vector2(80.0, 33.0)]),
		72, 1.0, SZ, 0.0, false, false)
	# Pink LED inner-rim fins
	for i: int in 96:
		var a := float(i) / 96.0 * TAU
		var pos := _ell(61.6, a, 29.0)
		var tang := Vector3(-sin(a), 0.0, cos(a) * SZ).normalized()
		var basis := Basis(Vector3(cos(a), 0.0, sin(a) * SZ).normalized(), Vector3.UP, tang)
		lm.box("PinkLamp", pos, Vector3(0.3, 2.0, 1.4), basis, 0.0)
	# Radial canopy ribs and lamp-lit rim line
	for i: int in 36:
		var a := float(i) / 36.0 * TAU
		lm.beam("White", _ell(61.0, a, 27.7), _ell(99.0, a, 37.6), 0.7, 0.5, Vector3.UP.cross(_ell(1.0, a, 0.0)).normalized())

static func _build_facade(lm: LandmarkMesh) -> void:
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([
		Vector2(96.5, 0.0), Vector2(96.5, 27.6)]), 72, 1.0, SZ, 0.0, false, false)
	lm.lathe("Glass", Vector3(0.0, 0.0, 0.0), PackedVector2Array([
		Vector2(96.8, 1.0), Vector2(96.8, 7.0)]), 72, 1.0, SZ, 0.0, false, false)
	# Vertical white fins with flamingo-pink accent fins
	for i: int in 60:
		var a := (float(i) + 0.5) / 60.0 * TAU
		var pos := _ell(97.4, a, 14.0)
		var basis := Basis(Vector3(cos(a), 0.0, sin(a) * SZ).normalized(), Vector3.UP,
			Vector3(-sin(a), 0.0, cos(a) * SZ).normalized())
		var key := "PinkSoft" if i % 3 == 0 else "White"
		lm.box(key, pos, Vector3(1.0, 26.0, 0.5), basis, 0.0)
		if i % 6 == 0:
			lm.box("PinkLamp", _ell(98.0, a, 27.0), Vector3(0.4, 1.2, 0.9), basis, 0.0)

static func _build_plaza(lm: LandmarkMesh) -> void:
	lm.lathe("Concrete", Vector3(0.0, -0.3, 0.0), PackedVector2Array([
		Vector2(96.0, 0.0), Vector2(104.0, 0.0), Vector2(104.0, 0.4), Vector2(96.0, 0.4)]),
		72, 1.0, SZ, 0.0, false, false)
	for i: int in 20:
		var a := (float(i) + 0.25) / 20.0 * TAU
		var p := _ell(104.0, a, 0.1)
		LandmarkMiKit.royal_palm(lm, "Concrete", "PalmFrond", p, 9.0 + float(i % 3) * 1.2, a)
