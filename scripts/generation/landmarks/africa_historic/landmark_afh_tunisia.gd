class_name LandmarkAfhTunisia
extends RefCounted

## Two Tunisian monuments in true metres: the Great Mosque of Kairouan
## and the Roman amphitheatre of El Jem (Thysdrus).

# --- Great Mosque of Kairouan ---

const KA_HW := 36.5
const KA_HD := 63.0

## Fortress-like limestone complex 73 x 126 m, qibla (mihrab) wall to the
## south (+Z), origin at its centre: buttressed and crenellated outer
## walls, the arcaded court (x +-26, z -52..14), the 17-aisle prayer hall
## under terracotta gables with the ribbed domes over the mihrab and the
## entrance to the nave, and the 31.5 m three-tier minaret in the middle
## of the north side.
static func kairouan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D0BA8F", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B4673F", 3.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#DCCFB4", 5.0))
	lm.use("Dark", LandmarkMaterials.glass("#2A241C"))
	lm.box("Court", Vector3(0, -0.3, 0), Vector3(76, 0.6, 128))
	_kairouan_walls(lm)
	_kairouan_hall(lm)
	_kairouan_domes(lm)
	_kairouan_minaret(lm, Vector3(0, 0, -57.65))
	lm.commit(model)

static func _kairouan_walls(lm: LandmarkMesh) -> void:
	var hw := KA_HW - 0.8
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * hw, 4.25, 0), Vector3(1.6, 8.5, KA_HD * 2.0))
		# Court galleries and the arcades on their faces.
		lm.box("Stone", Vector3(s * 30.85, 3.0, -19), Vector3(9.7, 6.0, 66))
		SEuUtil.face_row(lm, "Dark", Vector3(s * 26.0, 0, -19), Vector3(0, 0, 1),
			Vector3(-s, 0, 0), 0.0, 11, 6.0, 3.0, 4.8)
		SEuUtil.crenels(lm, "Stone", Vector3(s * 36.0, 8.5, -KA_HD), Vector3(s * 36.0, 8.5, KA_HD), 0.7, 0.9, 0.8)
		for z in range(-58, 59, 8):
			lm.frustum("Stone", Vector3(s * (KA_HW + 0.3), -0.3, float(z)), 1.5, 1.3, 9.2, 8)
	lm.box("Stone", Vector3(0, 4.25, -KA_HD + 0.8), Vector3(KA_HW * 2.0, 8.5, 1.6))
	lm.box("Stone", Vector3(0, 5.25, KA_HD - 0.8), Vector3(KA_HW * 2.0, 10.5, 1.6))
	lm.box("Stone", Vector3(0, 3.25, -57.1), Vector3(71.4, 6.5, 10.2))
	lm.box("Stone", Vector3(0, 3.75, 19.5), Vector3(71.4, 7.5, 11.0))
	SEuUtil.crenels(lm, "Stone", Vector3(-36, 8.5, -62.2), Vector3(36, 8.5, -62.2), 0.7, 0.9, 0.8)
	SEuUtil.crenels(lm, "Stone", Vector3(-36, 10.5, 62.2), Vector3(36, 10.5, 62.2), 0.7, 0.9, 0.8)
	for x in range(-32, 33, 8):
		lm.frustum("Stone", Vector3(float(x), -0.3, -KA_HD - 0.3), 1.5, 1.3, 9.2, 8)
		lm.frustum("Stone", Vector3(float(x), -0.3, KA_HD + 0.3), 1.5, 1.3, 11.2, 8)
	# Court arcades on the north and south galleries (the minaret fills the middle).
	for k in 4:
		for s in [-1.0, 1.0]:
			SEuUtil.opening(lm, "Dark", Vector3(s * (10.5 + 4.6 * float(k)), 0, -51.94),
				Vector3(1, 0, 0), Vector3.UP, 3.0, 4.6)
	SEuUtil.face_row(lm, "Dark", Vector3(0, 0, 14), Vector3(1, 0, 0), Vector3(0, 0, -1),
		0.0, 17, 4.1, 2.6, 5.2)

## 17 aisles of gabled terracotta roof (the central nave wider and
## higher) over the prayer hall, with the hall's windowed facade above the
## south gallery.
static func _kairouan_hall(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 5.25, 43.2), Vector3(71.4, 10.5, 36.4))
	lm.gable("Roof", Vector3(0, 10.5, 43.2), 6.0, 36.4, 2.2, Basis(), 0.0, "Stone")
	for k in range(1, 9):
		for s in [-1.0, 1.0]:
			var x: float = s * (3.0 + 4.09 * (float(k) - 0.5))
			lm.gable("Roof", Vector3(x, 10.5, 43.2), 4.09, 36.4, 1.0, Basis(), 0.0, "Stone")
	SEuUtil.face_row(lm, "Dark", Vector3(0, 0, 25), Vector3(1, 0, 0), Vector3(0, 0, -1),
		8.2, 12, 5.6, 1.1, 1.9)

## Octagonal ribbed domes: over the mihrab at the qibla wall and over the
## entrance of the central nave (the Bab el Bahou, the larger of the two).
static func _kairouan_domes(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 5.25, KA_HD + 1.3), Vector3(7.6, 10.5, 2.6))
	_ribbed_dome(lm, Vector3(0, 10.5, 58.5), 3.5, 2.5)
	_ribbed_dome(lm, Vector3(0, 7.5, 24.0), 4.2, 5.0)

## Square base `base_h` high, octagonal drum and a ribbed dome of radius r.
static func _ribbed_dome(lm: LandmarkMesh, at: Vector3, r: float, base_h: float) -> void:
	lm.box("Stone", at + Vector3(0, base_h * 0.5, 0), Vector3(r * 2.3, base_h, r * 2.3))
	var top := at + Vector3(0, base_h, 0)
	lm.frustum("Stone", top, r * 1.03, r * 1.03, 2.6, 8, PI / 8.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.box("Dark", top + Vector3(sin(a), 1.3, cos(a)) * Vector3(r * 0.96, 1.0, r * 0.96),
			Vector3(0.9, 1.5, 0.9), Basis(Vector3.UP, a))
	lm.lathe("Stone", top + Vector3(0, 2.6, 0), LandmarkMaParts.dome_profile(r, r * 0.85, 5), 16,
		1.0, 1.0, 0.0, false)

## Square minaret: tier 1 to 19.2 m (10.7 m wide at the foot), tier 2 to
## 27.3 m, tier 3 (the lantern) topped by a small ribbed dome at 31.5 m.
static func _kairouan_minaret(lm: LandmarkMesh, b: Vector3) -> void:
	var xf := Transform3D(Basis(), b)
	LandmarkAfhParts.tapered(lm, "Stone", xf, 0.0, 19.2, 10.7, 10.7, 9.4, 9.4)
	lm.box("Stone", b + Vector3(0, 19.5, 0), Vector3(10.0, 0.6, 10.0))
	LandmarkAfhParts.merlon_ring(lm, "Stone", b + Vector3(0, 19.8, 0), 4.9, 4.9, 0.7, 1.0)
	LandmarkAfhParts.tapered(lm, "Stone", xf, 19.8, 27.0, 6.6, 6.6, 5.8, 5.8)
	lm.box("Stone", b + Vector3(0, 27.15, 0), Vector3(6.4, 0.5, 6.4))
	LandmarkAfhParts.merlon_ring(lm, "Stone", b + Vector3(0, 27.4, 0), 3.0, 3.0, 0.6, 0.8)
	lm.box("Stone", b + Vector3(0, 28.6, 0), Vector3(3.8, 2.4, 3.8))
	lm.lathe("Stone", b + Vector3(0, 29.8, 0), LandmarkMaParts.dome_profile(2.3, 1.7, 5), 12,
		1.0, 1.0, 0.0, false)
	var faces: Array[Vector3] = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for f in 4:
		var out: Vector3 = faces[f]
		for y in [6.5, 13.0]:
			var hw := lerpf(5.35, 4.7, float(y) / 19.2)
			LandmarkAfhParts.face_quad(lm, "Dark", b + out * hw, out, 0.0, y, 1.1, 2.4, 0.06)
		LandmarkAfhParts.face_quad(lm, "Dark", b + out * lerpf(3.3, 2.9, 0.39), out, 0.0, 22.6, 1.0, 2.2, 0.06)
		LandmarkAfhParts.face_quad(lm, "Dark", b + out * 1.9, out, 0.0, 28.0, 0.9, 1.4, 0.05)

# --- Amphitheatre of El Jem ---

const EJ_A := 73.8
const EJ_B := 61.2
const EJ_BAYS := 64
const EJ_TIERS := [[0.0, 11.5], [11.5, 23.0], [23.0, 33.5]]

## Three-tier limestone amphitheatre, 148 x 122 m and 36 m high, the long
## axis along X. 64 bays of arches with engaged half-columns, a partly
## surviving attic, the great breach in the north-west (bays 18-28), the
## inner corridor ring and the ruined stepped cavea round the arena.
static func el_djem(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDB48A", 3.0))
	lm.use("Seats", LandmarkMaterials.pbr("limestone", "#BCA37B", 3.0))
	lm.use("Shade", LandmarkMaterials.pbr("stone", "#5A4A38", 4.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#CDB68E", 6.0))
	_el_djem_outer(lm)
	_el_djem_inner(lm)
	_el_djem_cavea(lm)
	var arena := PackedVector2Array()
	for i in 40:
		var t := TAU * float(i) / 40.0
		arena.append(Vector2(cos(t) * 32.5, -sin(t) * 19.5))
	lm.poly_prism("Sand", arena, -1.0, 0.1)
	lm.commit(model)

static func _ej_pt(a: float, b: float, i: float, y: float = 0.0) -> Vector3:
	var t := TAU * i / float(EJ_BAYS)
	return Vector3(cos(t) * a, y, -sin(t) * b)

## Storeys of the outer wall left standing at bay i (3 = full height).
static func _ej_tiers(i: int) -> int:
	if i >= 22 and i <= 24:
		return 0
	if (i >= 20 and i <= 21) or (i >= 25 and i <= 26):
		return 1
	if (i >= 18 and i <= 19) or (i >= 27 and i <= 28):
		return 2
	return 3

static func _el_djem_outer(lm: LandmarkMesh) -> void:
	for i in EJ_BAYS:
		var keep := _ej_tiers(i)
		var p0 := _ej_pt(EJ_A, EJ_B, float(i))
		var p1 := _ej_pt(EJ_A, EJ_B, float(i + 1))
		var out := Vector3(p0.x / (EJ_A * EJ_A), 0, p0.z / (EJ_B * EJ_B)).normalized()
		var out1 := Vector3(p1.x / (EJ_A * EJ_A), 0, p1.z / (EJ_B * EJ_B)).normalized()
		for t in keep:
			var y0: float = EJ_TIERS[t][0]
			var y1: float = EJ_TIERS[t][1]
			LandmarkColosseum.arch_bay(lm, "Stone", "Shade", p0, p1, y0, y1 - y0, 0.56, 0.52, 2.6)
			# Engaged column on the pier and the storey's entablature.
			lm.frustum("Stone", p0 + out * 0.5 + Vector3(0, y0 + 0.3, 0), 0.62, 0.52, y1 - y0 - 1.6, 8)
			lm.box("Stone", p0 + out * 0.5 + Vector3(0, y1 - 1.0, 0), Vector3(1.5, 0.7, 1.5),
				Basis(Vector3.UP, atan2(out.x, out.z)))
			lm.beam("Stone", p0 + out * 0.6 + Vector3(0, y1 - 0.65, 0),
				p1 + out1 * 0.6 + Vector3(0, y1 - 0.65, 0), 1.3, 1.4, Vector3.UP)
		# The attic survives only round the south and east.
		if keep == 3 and i >= 38 and i <= 62:
			lm.beam("Stone", p0 + out * 0.4 + Vector3(0, 34.75, 0), p1 + out1 * 0.4 + Vector3(0, 34.75, 0),
				2.5, 1.8, Vector3.UP)
			if i % 2 == 0:
				var m := (p0 + p1) * 0.5 + out * 1.3
				lm.box("Shade", m + Vector3(0, 34.6, 0), Vector3(1.6, 1.6, 0.1),
					Basis(Vector3.UP, atan2(out.x, out.z)))

## Inner corridor wall: two arcaded storeys all round.
static func _el_djem_inner(lm: LandmarkMesh) -> void:
	for i in EJ_BAYS:
		var p0 := _ej_pt(EJ_A - 11.0, EJ_B - 11.0, float(i))
		var p1 := _ej_pt(EJ_A - 11.0, EJ_B - 11.0, float(i + 1))
		var tiers := 2 if i < 22 or i > 26 else 1
		for t in tiers:
			var y0: float = EJ_TIERS[t][0]
			var y1: float = EJ_TIERS[t][1]
			LandmarkColosseum.arch_bay(lm, "Stone", "Shade", p0, p1, y0, y1 - y0, 0.5, 0.52, 2.0)

## Stepped seating from the arena wall up to the inner ring, with the
## breach and random missing blocks.
static func _el_djem_cavea(lm: LandmarkMesh) -> void:
	var k_steps := 7
	for i in EJ_BAYS:
		if i >= 21 and i <= 25:
			continue
		for k in k_steps:
			if LandmarkAfhParts.hash01(i, k) < 0.1 * float(k) / 3.0:
				continue
			var f0 := float(k) / float(k_steps)
			var f1 := float(k + 1) / float(k_steps)
			var a0 := lerpf(32.5, EJ_A - 13.0, f0)
			var b0 := lerpf(19.5, EJ_B - 13.0, f0)
			var a1 := lerpf(32.5, EJ_A - 13.0, f1)
			var b1 := lerpf(19.5, EJ_B - 13.0, f1)
			var y := 2.0 + 3.2 * float(k + 1)
			lm.quad("Seats", _ej_pt(a0, b0, float(i), y), _ej_pt(a0, b0, float(i + 1), y),
				_ej_pt(a1, b1, float(i + 1), y), _ej_pt(a1, b1, float(i), y), Vector3.UP)
			var q0 := _ej_pt(a0, b0, float(i), y - 3.2)
			var q1 := _ej_pt(a0, b0, float(i + 1), y - 3.2)
			var inward := -Vector3(q0.x / (a0 * a0), 0, q0.z / (b0 * b0)).normalized()
			lm.quad("Seats", q0, q1, q1 + Vector3(0, 3.2, 0), q0 + Vector3(0, 3.2, 0), inward)
