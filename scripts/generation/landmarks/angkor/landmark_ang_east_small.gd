class_name LandmarkAngEastSmall
extends RefCounted

## The smaller east-Angkor temples in true metres: Prasat Kravan, Banteay
## Samre and the Srah Srang landing terrace. Built facing +X (east).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const E = preload("res://scripts/generation/landmarks/angkor/landmark_ang_east.gd")

## Prasat Kravan (15 m): the Cardamom Sanctuary of 921: five reddish brick
## towers in a north-south row on one low terrace, all facing east; the
## central one tallest with its receding false storeys, the south one next
## with the same stepped roof, the northern pair lower; each with a
## sandstone stair to its east door, the whole inside a small moat curb.
## Built facing +X (east).
static func prasat_kravan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A05B40", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8472", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2420", 2.0))
	# Terrace: laterite body under a sandstone coping, 14 x 52 m.
	lm.box("Laterite", Vector3(0, 0.4, 0), Vector3(14.0, 0.8, 52.0))
	lm.box("Stone", Vector3(0, 0.9, 0), Vector3(14.4, 0.2, 52.4))
	# Five towers: south end is +Z. Width of each, and its total height.
	var zs: Array[float] = [-19.0, -9.5, 0.0, 9.5, 19.0]
	var hws: Array[float] = [2.4, 2.5, 2.9, 2.6, 2.4]
	var hs: Array[float] = [9.0, 11.0, 15.0, 12.5, 9.0]
	var tiers: Array[int] = [2, 3, 4, 3, 2]
	for i in 5:
		if i >= 1 and i <= 3:
			U.prasat(lm, "Brick", "Brick", "Dark", Vector3(0, 1.0, zs[i]), hws[i], hs[i] - 1.0, tiers[i], 0.28)
		else:
			E.tower(lm, "Brick", "Brick", "Dark", Vector3(0, 1.0, zs[i]), hws[i], hs[i] - 1.0, tiers[i], 0.28)
		U.stair(lm, "Stone", Vector3(7.0, 0, zs[i]), Basis(Vector3.UP, PI * 0.5), 2.6, 3, 0.45, 1.0 / 3.0)
	# The small moat, shown as its raised curb.
	for s in [-1.0, 1.0]:
		lm.box("Laterite", Vector3(0, 0.25, s * 30.0), Vector3(26.0, 0.5, 0.9))
		lm.box("Laterite", Vector3(s * 13.0, 0.25, 0), Vector3(0.9, 0.5, 59.1))
	lm.commit(model)

## Banteay Samre (21 m): the Angkor Wat-style temple of Suryavarman II: the
## outer laterite wall (90 x 66 m, 6 m high) and the sandstone gallery
## enclosure inside it (45 x 40 m), a gopura on all four sides of each, the
## sanctuary tower on its raised cruciform platform with the mandapa and
## antarala east of it and a chapel on every other side, the two libraries
## in the court, corner towers, and the cruciform terrace and naga
## causeway running out east. Built facing +X (east).
static func banteay_samre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A39378", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#B3A488", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	var eb := Basis(Vector3.UP, PI * 0.5)
	var lat: Array[String] = ["Laterite", "Stone", "Dark"]
	var sand: Array[String] = ["Stone", "Trim", "Dark"]
	E.gallery(lm, lat, Vector3.ZERO, 45.0, 33.0, 6.0, 1.6, 5.0, 5.0, false, false)
	E.gallery(lm, sand, Vector3.ZERO, 22.5, 20.0, 4.5, 1.4, 4.0, 4.0, true, true)
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var odd := i % 2 == 1
		E.gopura(lm, "Laterite", "Stone", "Dark", "Stone", b * Vector3(0, 0, 45.0 if odd else 33.0), b,
			14.0, 8.0, 7.5, 6.0)
		E.gopura(lm, "Stone", "Trim", "Dark", "Stone", b * Vector3(0, 0, 22.5 if odd else 20.0), b,
			9.0, 5.5, 5.5, 5.5)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			E.tower(lm, "Stone", "Trim", "Dark", Vector3(sx * 22.5, 4.8, sz * 20.0), 1.5, 6.5, 2, 0.3)
	# Cruciform platform with the sanctuary, antarala, mandapa and chapels.
	lm.box("Trim", Vector3(4.0, 0.3, 0), Vector3(26.0, 0.6, 16.0))
	lm.box("Stone", Vector3(4.0, 1.2, 0), Vector3(24.6, 1.6, 14.6))
	lm.box("Trim", Vector3(4.0, 1.9, 0), Vector3(25.0, 0.2, 15.0), Basis(), 0.0)
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, 2.0, 0), 3.4, 19.0, 4, 0.26)
	lm.box("Stone", Vector3(5.0, 2.0 + 1.6, 0), Vector3(3.4, 3.2, 3.6))
	U.hall(lm, "Stone", "Trim", "Stone", "Trim", Vector3(10.5, 2.0, 0), eb, 4.4, 7.0, 0.0, 3.3, 2.0, 2, 0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, 2.0 + 2.0, s * 5.8), Vector3(3.8, 4.0, 3.2))
		lm.box("Dark", Vector3(0, 2.0 + 1.4, s * 7.45), Vector3(1.2, 2.2, 0.1), Basis(), 0.0)
		lm.gable("Stone", Vector3(0, 2.0 + 4.0, s * 5.8), 3.8, 3.2, 1.4, Basis(), 0.3, "Stone")
	lm.box("Stone", Vector3(-5.8, 2.0 + 2.0, 0), Vector3(3.2, 4.0, 3.8))
	lm.box("Dark", Vector3(-7.45, 2.0 + 1.4, 0), Vector3(0.1, 2.2, 1.2), Basis(), 0.0)
	lm.gable("Stone", Vector3(-5.8, 2.0 + 4.0, 0), 3.8, 3.2, 1.4, eb, 0.3, "Stone")
	for s in [-1.0, 1.0]:
		U.hall(lm, "Stone", "Trim", "Stone", "Trim", Vector3(12.0, 0, s * 12.0), eb, 3.6, 6.5, 0.8, 3.0,
			1.8, 2, 0)
	# Cruciform terrace and the naga causeway running out east.
	lm.box("Stone", Vector3(57.0, 0.55, 0), Vector3(16.0, 1.1, 8.0))
	lm.box("Stone", Vector3(57.0, 0.55, 0), Vector3(8.0, 1.1, 18.0))
	lm.box("Trim", Vector3(57.0, 1.15, 0), Vector3(16.4, 0.2, 8.4), Basis(), 0.0)
	lm.box("Trim", Vector3(57.0, 1.15, 0), Vector3(8.4, 0.2, 18.4), Basis(), 0.0)
	lm.box("Laterite", Vector3(84.5, 0.5, 0), Vector3(39.0, 1.0, 5.6))
	for s in [-1.0, 1.0]:
		U.naga_rail(lm, "Stone", Vector3(65.0, 1.0, s * 2.5), eb, 39.0, 0.0, 0.0, 0.6, 5)
	lm.commit(model)

## Srah Srang (4.5 m): the landing terrace of the Bath Pool baray on its
## west bank: a cruciform sandstone-and-laterite platform 1.8 m above the
## water, the great stair down to the pool flanked by naga balustrades
## ending in upright hoods with a garuda over each, two crouching lions
## guarding the stair head, side stairs on the porch flanks, and the
## stepped laterite embankment of the pool edge running north and south.
## The pool lies east, at the model's ground level. Built facing +X (east).
static func srah_srang(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A8D74", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#AA9D84", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	var eb := Basis(Vector3.UP, PI * 0.5)
	# Cruciform platform: the long arm along the bank, the porch to the pool.
	lm.box("Laterite", Vector3(-6.0, 0.9, 0), Vector3(16.0, 1.8, 48.0))
	lm.box("Stone", Vector3(7.0, 0.9, 0), Vector3(10.0, 1.8, 18.0))
	lm.box("Trim", Vector3(-6.0, 1.7, 0), Vector3(16.4, 0.2, 48.4), Basis(), 0.0)
	lm.box("Trim", Vector3(7.0, 1.7, 0), Vector3(10.4, 0.2, 18.4), Basis(), 0.0)
	# Great stair to the water and a stair on each flank of the porch.
	U.stair(lm, "Stone", Vector3(12.0, 0, 0), eb, 12.0, 6, 0.5, 0.3)
	for s in [-1.0, 1.0]:
		var fb := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		U.stair(lm, "Stone", Vector3(7.0, 0, s * 9.0), fb, 6.0, 6, 0.5, 0.3)
		# Naga balustrade down the great stair, a garuda on its hood.
		U.naga_rail(lm, "Stone", Vector3(12.0, 0, s * 6.9), eb, 3.0, 1.8, 0.0, 0.8, 5)
		_garuda(lm, "Trim", Vector3(15.0, 2.6, s * 6.9), eb, 1.9)
		_lion(lm, "Stone", Vector3(10.5, 1.8, s * 8.0), eb)
	# The stepped laterite embankment of the pool edge, north and south.
	for s in [-1.0, 1.0]:
		lm.box("Laterite", Vector3(0.5, 0.3, s * 44.0), Vector3(3.0, 0.6, 40.0))
		lm.box("Laterite", Vector3(-2.5, 0.6, s * 44.0), Vector3(3.0, 1.2, 40.0))
		lm.box("Laterite", Vector3(-9.0, 0.9, s * 44.0), Vector3(10.0, 1.8, 40.0))
		lm.box("Trim", Vector3(0.5, 0.65, s * 44.0), Vector3(3.2, 0.1, 40.4), Basis(), 0.0)
		lm.box("Trim", Vector3(-9.0, 1.75, s * 44.0), Vector3(10.4, 0.1, 40.4), Basis(), 0.0)
	lm.commit(model)

## Crouching lion on its plinth (about 2.3 m tall), facing basis +Z.
static func _lion(lm: LandmarkMesh, key: String, base: Vector3, b: Basis) -> void:
	lm.box(key, base + b * Vector3(0, 0.3, 0), Vector3(1.1, 0.6, 2.4), b)
	lm.box(key, base + b * Vector3(0, 0.95, -0.15), Vector3(0.8, 0.7, 1.4), b)
	lm.box(key, base + b * Vector3(0, 1.3, 0.55), Vector3(0.55, 1.0, 0.5), b)
	lm.box(key, base + b * Vector3(0, 1.85, 0.6), Vector3(0.95, 0.9, 0.45), b)
	lm.box(key, base + b * Vector3(0, 1.8, 0.95), Vector3(0.55, 0.55, 0.4), b)
	lm.box(key, base + b * Vector3(0, 1.7, 1.25), Vector3(0.3, 0.25, 0.3), b)

## Garuda with spread wings, facing basis +Z, standing on `base`, height h.
static func _garuda(lm: LandmarkMesh, key: String, base: Vector3, b: Basis, h: float) -> void:
	lm.box(key, base + b * Vector3(0, h * 0.35, 0), Vector3(h * 0.3, h * 0.5, h * 0.18), b)
	lm.box(key, base + b * Vector3(0, h * 0.72, h * 0.03), Vector3(h * 0.2, h * 0.2, h * 0.18), b)
	lm.box(key, base + b * Vector3(0, h * 0.68, h * 0.16), Vector3(h * 0.07, h * 0.1, h * 0.14), b)
	lm.spire(key, base + b * Vector3(0, h * 0.8, 0), h * 0.08, h * 0.2, 0.0)
	for s in [-1.0, 1.0]:
		lm.beam(key, base + b * Vector3(s * h * 0.12, h * 0.4, -h * 0.04),
			base + b * Vector3(s * h * 0.52, h * 0.8, -h * 0.04), h * 0.18, h * 0.06, b * Vector3.BACK)
		lm.box(key, base + b * Vector3(s * h * 0.08, h * 0.05, 0), Vector3(h * 0.08, h * 0.1, h * 0.08), b)
