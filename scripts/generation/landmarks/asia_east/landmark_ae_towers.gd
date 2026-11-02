class_name LandmarkAeTowers
extends RefCounted

## Skyscrapers of China and Taiwan in true metres: CCTV Headquarters
## (234 m, the leaning loop), Canton Tower (600 m, twisted lattice
## hyperboloid), Bank of China Tower in Hong Kong (367.4 m, four
## triangular prisms of different heights with X bracing) and Taipei 101
## (508 m, eight flared pagoda segments).

# --- CCTV Headquarters ---

const CCTV_M := 234.0
const CCTV_HALF_D := 23.0

static func cctv(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#4E6672"))
	lm.use("Frame", LandmarkMaterials.paint("#9AA2A8", 0.4, 0.6))
	var z := CCTV_HALF_D + 0.1
	# Base: the two towers rise from one podium and lean toward each other.
	lm.box("Glass", Vector3(0, 17.0, 0), Vector3(128.0, 34.0, CCTV_HALF_D * 2.0))
	var legs := [[-44.0, -22.0, 234.0], [46.0, 24.0, 194.0]]
	for leg in legs:
		var x0 := float(leg[0])
		var x1 := float(leg[1])
		var top := float(leg[2])
		lm.beam("Glass", Vector3(x0, 0, 0), Vector3(x1, top - 8.0, 0), 34.0, CCTV_HALF_D * 2.0, Vector3.RIGHT)
		lm.box("Glass", Vector3(x1, top - 4.0, 0), Vector3(34.0, 8.0, CCTV_HALF_D * 2.0))
		for s in [-1.0, 1.0]:
			lm.lattice_panel("Frame", Vector3(x0 - 17.0, 0, s * z), Vector3(x0 + 17.0, 0, s * z),
				Vector3(x1 - 17.0, top - 8.0, s * z), Vector3(x1 + 17.0, top - 8.0, s * z), 1.2, 8)
	# Top overhang joining the two tower heads and cantilevering past the lower one.
	lm.box("Glass", Vector3(15.5, 212.0, 0), Vector3(109.0, 44.0, CCTV_HALF_D * 2.0))
	for s in [-1.0, 1.0]:
		for p in 3:
			var x := -39.0 + 36.33 * p
			lm.lattice_panel("Frame", Vector3(x, 190.0, s * z), Vector3(x + 36.33, 190.0, s * z),
				Vector3(x, 234.0, s * z), Vector3(x + 36.33, 234.0, s * z), 1.2, 1)
		lm.lattice_panel("Frame", Vector3(-64.0, 0, s * z), Vector3(64.0, 0, s * z),
			Vector3(-64.0, 34.0, s * z), Vector3(64.0, 34.0, s * z), 1.2, 2)
	lm.commit(model)

# --- Canton Tower ---

const CANTON_M := 600.0
const CANTON_BODY := 454.0
static var CANTON_SCALE := PackedVector2Array([Vector2(0, 1.0), Vector2(0.3, 0.62),
	Vector2(0.62, 0.34), Vector2(0.82, 0.4), Vector2(1, 0.56)])

static func canton(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.paint("#E4E3DE", 0.4, 0.5))
	lm.use("Core", LandmarkMaterials.pbr("concrete", "#BDBAB2", 4.0))
	lm.use("Deck", LandmarkMaterials.glass("#7E95A3"))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CCC8BE", 4.0))
	var levels := 30
	var cols := 24
	var prev := _canton_ring(0.0, cols)
	for k in range(1, levels + 1):
		var cur := _canton_ring(float(k) / levels, cols)
		for j in cols:
			lm.beam("Frame", prev[j], cur[j], 1.5, 1.5)
			lm.beam("Frame", cur[j], cur[(j + 1) % cols], 1.0, 1.0)
		prev = cur
	lm.frustum("Core", Vector3(0, -2.0, 0), 7.0, 6.5, CANTON_BODY + 2.0, 16)
	for d in [[100.0, 0.5], [168.0, 0.4], [300.0, 0.34], [CANTON_BODY - 6.0, 0.55]]:
		var f := float(d[0]) / CANTON_BODY
		var s := LandmarkMesh.profile_at(CANTON_SCALE, f)
		lm.frustum("Deck", Vector3(0, float(d[0]), 0), 38.0 * s, 38.0 * s, 6.0, 20, 0.0, 1.0, 0.72)
	lm.lathe("Frame", Vector3(0, CANTON_BODY, 0), PackedVector2Array([Vector2(6.0, 0),
		Vector2(4.2, 55.0), Vector2(2.0, 105.0), Vector2(0.3, CANTON_M - CANTON_BODY)]), 12)
	lm.box("Podium", Vector3(0, 3.0, 0), Vector3(110.0, 8.0, 80.0))
	lm.commit(model)

## The ellipse at height fraction f, turned through 135 degrees overall.
static func _canton_ring(f: float, cols: int) -> Array[Vector3]:
	var s := LandmarkMesh.profile_at(CANTON_SCALE, f)
	var out: Array[Vector3] = []
	for j in cols:
		var a := TAU * float(j) / cols
		var p := Vector3(40.0 * s * cos(a), CANTON_BODY * f, 29.0 * s * sin(a))
		out.append(p.rotated(Vector3.UP, deg_to_rad(135.0) * f))
	return out

# --- Bank of China Tower, Hong Kong ---

const BOC_M := 367.4
## Prism heights N, E, S, W (floors 70, 52, 38 and 25).
const BOC_H := [315.0, 234.0, 171.0, 113.0]

static func bank_of_china(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#6F8A98"))
	lm.use("Frame", LandmarkMaterials.paint("#D2D6D8", 0.3, 0.8))
	var hw := 26.0
	var corners := [Vector2(-hw, -hw), Vector2(hw, -hw), Vector2(hw, hw), Vector2(-hw, hw)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var h := float(BOC_H[i])
		lm.poly_prism("Glass", PackedVector2Array([a, b, Vector2.ZERO]), -2.0, h)
		# Great X braces on the outer face; sloped prism faces above their neighbours.
		var n := maxi(int(round(h / 52.0)), 1)
		lm.lattice_panel("Frame", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y),
			Vector3(a.x, h, a.y), Vector3(b.x, h, b.y), 2.0, n)
		for side in 2:
			var edge: Vector2 = a if side == 0 else b
			var nb := float(BOC_H[(i + 3) % 4] if side == 0 else BOC_H[(i + 1) % 4])
			if h > nb + 10.0:
				lm.lattice_panel("Frame", Vector3(edge.x, nb, edge.y), Vector3(0, nb, 0),
					Vector3(edge.x, h, edge.y), Vector3(0, h, 0), 1.6, maxi(int((h - nb) / 40.0), 1))
	for x in [-9.0, 9.0]:
		lm.lathe("Frame", Vector3(x, BOC_H[0], -17.0), PackedVector2Array([Vector2(1.0, 0),
			Vector2(0.6, 30.0), Vector2(0.12, BOC_M - float(BOC_H[0]))]), 8)
	lm.commit(model)

# --- Taipei 101 ---

const T101_M := 508.0
const T101_ROOF := 449.2

static func taipei_101(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#5E8F86"))
	lm.use("Frame", LandmarkMaterials.paint("#37464A", 0.4, 0.5))
	lm.use("Podium", LandmarkMaterials.pbr("limestone", "#C9C1B2", 4.0))
	lm.use("Mast", LandmarkMaterials.paint("#CDD1D4", 0.35, 0.7))
	lm.box("Podium", Vector3(0, 7.0, 0), Vector3(72.0, 16.0, 72.0))
	lm.spire("Glass", Vector3(0, 0, 0), 31.0, 96.0, 25.0)
	var y := 96.0
	for i in 8:
		# Each pagoda segment flares outward, then necks in at the belt.
		lm.spire("Glass", Vector3(0, y, 0), 21.0, 32.0, 27.0)
		lm.box("Frame", Vector3(0, y + 34.0, 0), Vector3(43.0, 4.0, 43.0))
		y += 36.0
	# Crown: four set-backs below the pinnacle.
	for step in [[22.0, 24.0], [20.0, 18.0], [17.0, 13.0], [13.6, T101_ROOF - 384.0 - 55.0]]:
		lm.box("Glass", Vector3(0, y + float(step[1]) * 0.5, 0), Vector3(float(step[0]) * 2.0,
			float(step[1]), float(step[0]) * 2.0))
		y += float(step[1])
	lm.lathe("Mast", Vector3(0, y, 0), PackedVector2Array([Vector2(4.5, 0), Vector2(4.0, 25.0),
		Vector2(2.0, 40.0), Vector2(0.4, T101_M - y)]), 12)
	lm.commit(model)
