class_name LandmarkMiHolocaustMemorial
extends RefCounted

## Holocaust Memorial Miami Beach (Kenneth Treister, 1990) - MI-4C.
## Site: way 588999178 (25.795187, -80.136413, yaw_deg 89.6), 46 x 46 m, height_m = 14.0.
## Circular black-granite lily pond with lily-pad clusters, a curved coral-limestone keystone
## colonnade and meditation pergola (y = 0..4.8 m), black-granite memorial wall panels, and
## from the central island the patinated dark-bronze outstretched arm and hand with climbing
## figures, reaching exactly 14.0 m. BronzeLamp uplights glow warmly at night.

const HEIGHT_M := 14.0
const ARC_A0 := PI * 1.1
const ARC_A1 := PI * 1.9

static func _arm(t: float) -> Vector3:
	return Vector3(sin(t * PI * 0.6) * 1.6, 0.8 + t * 8.8, 0.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#1A1B1E", 3.0, 0.3))
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#CDBB98", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#2F3B34", 0.55, 0.6))
	lm.use("Water", LandmarkMaterials.pool_water("#0B1E24", 0.06))
	lm.use("LilyPad", LandmarkMaterials.paint("#3F7A3A", 0.8, 0.0))
	lm.use("BronzeLamp", LandmarkMaterials.lit("#FFB060", 0.9))
	_pool(lm)
	_arm_and_hand(lm)
	_colonnade(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.72, 0.42)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(8.0, 0.5, 6.0), Vector3(0.0, 10.0, 0.0), 40.0, 1.2, 30.0, warm],
		[Vector3(-8.0, 0.5, 6.0), Vector3(0.0, 10.0, 0.0), 40.0, 1.2, 30.0, warm],
		[Vector3(0.0, 0.5, -8.0), Vector3(0.0, 11.0, 0.0), 40.0, 1.0, 30.0, warm],
	])

static func _pool(lm: LandmarkMesh) -> void:
	lm.poly_prism("Limestone", TowerSpec.plan("ellipse", 46.0, 46.0, 36.0), -0.3, 0.0)
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([
		Vector2(13.2, -0.1), Vector2(13.2, 0.5), Vector2(12.0, 0.5), Vector2(12.0, -0.1)]),
		40, 1.0, 1.0, 0.0, true, false)
	lm.disc("Water", Vector3(0.0, 0.12, 0.0), Vector3.UP, 12.0, 40)
	lm.frustum("Granite", Vector3.ZERO, 4.6, 4.0, 0.8, 24)
	for i in 20:
		var a: float = 2.399 * float(i)
		var r: float = 5.2 + 6.0 * float((i * 7) % 20) / 20.0
		var rad: float = 0.5 + 0.1 * float(i % 4)
		lm.disc("LilyPad", Vector3(cos(a) * r, 0.14, sin(a) * r), Vector3.UP, rad, 10)
	for i in 6:
		var a: float = TAU * float(i) / 6.0
		lm.box("BronzeLamp", Vector3(cos(a) * 3.6, 0.85, sin(a) * 3.6), Vector3(0.4, 0.2, 0.4), Basis(), 0.0)

static func _arm_and_hand(lm: LandmarkMesh) -> void:
	var segs := 6
	for k in segs:
		var t0: float = float(k) / float(segs)
		var t1: float = float(k + 1) / float(segs)
		lm.beam("Bronze", _arm(t0), _arm(t1), lerpf(3.4, 1.9, t0), lerpf(3.0, 1.7, t0), Vector3.BACK, true)
	var wrist: Vector3 = _arm(1.0)
	var xe: float = wrist.x
	lm.box("Bronze", Vector3(xe, 10.9, 0.0), Vector3(3.2, 2.6, 1.0), Basis(), 0.0)
	# Four fingers and a thumb; the middle finger tip reaches exactly 14.0 m
	var offs: Array[float] = [-1.2, -0.4, 0.4, 1.2]
	var tips: Array[float] = [12.9, 13.0, 12.8, 12.2]
	for i in 4:
		var o: float = offs[i]
		lm.beam("Bronze", Vector3(xe + o, 12.0, 0.0), Vector3(xe + o * 1.5, tips[i], 0.0), 0.5, 0.45)
	lm.frustum("Bronze", Vector3(xe - 0.6, 13.0, 0.0), 0.28, 0.0, 1.0, 8)
	lm.beam("Bronze", Vector3(xe - 1.6, 10.6, 0.0), Vector3(xe - 3.2, 12.4, 0.2), 0.55, 0.5)
	# Climbing relief figures along the arm
	for i in 16:
		var t: float = 0.05 + 0.9 * float(i) / 15.0
		var p: Vector3 = _arm(t)
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var base := p + Vector3(side * 0.7, 0.0, 0.9 * (1.0 if i % 3 != 0 else -1.0))
		lm.beam("Bronze", base, base + Vector3(side * 0.25, 1.0, 0.1), 0.35, 0.3)
		lm.frustum("Bronze", base + Vector3(side * 0.25, 1.0, 0.1), 0.2, 0.12, 0.3, 6)

static func _colonnade(lm: LandmarkMesh) -> void:
	var n := 13
	var prev := Vector3.ZERO
	for i in n:
		var a: float = lerpf(ARC_A0, ARC_A1, float(i) / float(n - 1))
		var p := Vector3(cos(a) * 19.0, 0.0, sin(a) * 19.0)
		lm.box("Limestone", p + Vector3(0.0, 2.2, 0.0), Vector3(0.9, 4.4, 1.4), Basis(Vector3.UP, -a), 0.0)
		var inner := Vector3(cos(a) * 15.5, 4.45, sin(a) * 15.5)
		lm.beam("Limestone", Vector3(p.x, 4.45, p.z), inner, 0.3, 0.3)
		if i > 0:
			lm.beam("Limestone", Vector3(prev.x, 4.35, prev.z), Vector3(p.x, 4.35, p.z), 0.9, 0.8)
		prev = p
	# Black-granite memorial wall panels inside the colonnade
	for i in 12:
		var a: float = lerpf(ARC_A0 + 0.05, ARC_A1 - 0.05, float(i) / 11.0)
		lm.box("Granite", Vector3(cos(a) * 15.2, 1.5, sin(a) * 15.2), Vector3(0.4, 3.0, 3.0),
			Basis(Vector3.UP, -a), 0.0)
