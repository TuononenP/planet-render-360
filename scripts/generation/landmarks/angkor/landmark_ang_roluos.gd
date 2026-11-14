class_name LandmarkAngRoluos
extends RefCounted

## The Roluos group (Hariharalaya, 879-893) in true metres: the Bakong
## temple-mountain, the Preah Ko brick towers and Lolei on its baray island.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const K = preload("res://scripts/generation/landmarks/angkor/landmark_ang_outer_kit.gd")

## Bakong (27.5 m): Indravarman I's state temple-mountain (881). A five-tier
## pyramid 67 x 65 m at the foot and 14 m high (sandstone below, laterite
## above) with a steep stair up the middle of every face, twelve elephants
## at the corners of the lower three tiers, twelve small sandstone towers
## and the 12th-century lotus sanctuary with four porches on top; eight
## brick towers round the foot inside the 160 x 120 m laterite enclosure
## with its libraries, the 400 x 300 m wall with four gopuras, the
## naga-railed causeway east and the 22 brick shrines of the moat island.
## The moats are terrain. Built facing +X (east).
static func bakong(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C8068", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#A09378", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E5039", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	var hxs: Array[float] = [33.5, 28.0, 23.0, 18.0, 13.0]
	var hzs: Array[float] = [32.5, 27.0, 22.0, 17.0, 12.5]
	var ths: Array[float] = [3.2, 3.0, 2.8, 2.6, 2.4]
	var ys: Array[float] = []
	var y := 0.0
	for j in 5:
		ys.append(y)
		var key := "Stone" if j < 3 else "Laterite"
		lm.box(key, Vector3(0, y + ths[j] * 0.5, 0), Vector3(hxs[j] * 2.0, ths[j], hzs[j] * 2.0))
		lm.box("Trim", Vector3(0, y + 0.2, 0), Vector3(hxs[j] * 2.0 + 0.6, 0.4, hzs[j] * 2.0 + 0.6))
		lm.box("Trim", Vector3(0, y + ths[j] - 0.15, 0),
			Vector3(hxs[j] * 2.0 + 0.5, 0.3, hzs[j] * 2.0 + 0.5))
		y += ths[j]
	# Stairs up the middle of every face of every tier, with cheek walls.
	for j in 5:
		var n := int(round(ths[j] / 0.4))
		var riser := ths[j] / float(n)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			var half := hzs[j] if side % 2 == 0 else hxs[j]
			U.stair(lm, "Trim", b * Vector3(0, ys[j], half), b, 5.6, n, 0.55, riser)
			for sx in [-1.0, 1.0]:
				U.stair(lm, "Stone", b * Vector3(sx * 3.25, ys[j], half - 0.55), b, 0.9, n + 1, 0.55, riser)
	# Twelve elephants on the corners of the lower three tiers.
	for j in 3:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				K.elephant(lm, "Stone", Vector3(sx * (hxs[j] + 2.4), ys[j], sz * (hzs[j] + 2.4)),
					atan2(sx, sz))
	# Twelve small sandstone towers: the corners and flanking every stair.
	var tx: float = hxs[3] + 2.6
	var tz: float = hzs[3] + 2.6
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.small_tower(lm, "Trim", Vector3(sx * tx, ys[3], sz * tz), 0.9, 3.4)
		for s2 in [-1.0, 1.0]:
			U.small_tower(lm, "Trim", Vector3(sx * tx, ys[3], s2 * 6.6), 0.9, 3.4)
			U.small_tower(lm, "Trim", Vector3(s2 * 6.6, ys[3], sx * tz), 0.9, 3.4)
	# Summit: the lotus sanctuary with a porch on every face.
	var top := y
	U.prasat(lm, "Stone", "Trim", "Dark", Vector3(0, top, 0), 3.6, 13.5, 4, 0.3, 0.8)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Stone", b * Vector3(0, top + 2.2, 5.5), Vector3(4.4, 4.4, 3.4), b)
		lm.gable("Trim", b * Vector3(0, top + 4.4, 5.5), 4.6, 3.6, 1.6, b, 0.2, "Stone")
		lm.box("Dark", b * Vector3(0, top + 1.7, 7.22), Vector3(1.6, 3.2, 0.1), b, 0.0)
	# Eight brick towers round the foot (two a side) and two libraries.
	for s in [-1.0, 1.0]:
		for s2 in [-1.0, 1.0]:
			K.light_tower(lm, "Brick", "Dark", Vector3(s * 52.0, 0, s2 * 9.0), 2.1, 9.5, 3)
			K.light_tower(lm, "Brick", "Dark", Vector3(s2 * 14.0, 0, s * 47.0), 2.1, 9.5, 3)
		K.library(lm, "Brick", "Trim", "Dark", Vector3(62.0, 0, s * 34.0), Basis(Vector3.UP, -PI * 0.5),
			4.4, 8.0, 3.2)
	# Inner enclosure 160 x 120 m with east and west gopuras.
	K.ring(lm, "Laterite", "Trim", 80.0, 60.0, 2.4, 1.2, 3.0)
	for s in [-1.0, 1.0]:
		K.gopura_roofed(lm, "Laterite", "Trim", "Dark", Vector3(s * 80.0, 0, 0),
			Basis(Vector3.UP, PI * 0.5), 7.0, 10.0, 3.6, 2.2)
	# Outer enclosure 400 x 300 m with four cruciform gopuras.
	K.ring(lm, "Laterite", "Trim", 200.0, 150.0, 3.2, 1.4, 8.0, 8.0)
	for s in [-1.0, 1.0]:
		K.gopura_roofed(lm, "Laterite", "Trim", "Dark", Vector3(s * 200.0, 0, 0),
			Basis(Vector3.UP, PI * 0.5), 12.0, 16.0, 5.0, 3.0)
		K.gopura_roofed(lm, "Laterite", "Trim", "Dark", Vector3(0, 0, s * 150.0), Basis(), 12.0, 14.0,
			5.0, 3.0)
	# East causeway across the moats, a laterite bank with seven-headed nagas.
	var east := Basis(Vector3.UP, PI * 0.5)
	lm.box("Laterite", Vector3(168.0, 0.25, 0), Vector3(176.0, 0.5, 11.0))
	for s in [-1.0, 1.0]:
		U.naga_rail(lm, "Trim", Vector3(84.0, 0.4, s * 5.0), east, 168.0, 0.3, 0.3, 0.55, 7)
	# The 22 brick shrines of the island between the moats.
	var hx := 300.0
	var hz := 235.0
	var perim := 4.0 * (hx + hz)
	for i in 22:
		var u := fposmod(perim * (float(i) + 0.5) / 22.0, perim)
		var p := Vector3.ZERO
		if u < hz:
			p = Vector3(hx, 0, u)
		elif u < hz + 2.0 * hx:
			p = Vector3(hx - (u - hz), 0, hz)
		elif u < 3.0 * hz + 2.0 * hx:
			p = Vector3(-hx, 0, hz - (u - hz - 2.0 * hx))
		elif u < 3.0 * hz + 4.0 * hx:
			p = Vector3(-hx + (u - 3.0 * hz - 2.0 * hx), 0, -hz)
		else:
			p = Vector3(hx, 0, -hz + (u - 3.0 * hz - 4.0 * hx))
		K.shrine(lm, "Brick", "Dark", p, 1.2, 5.5)
	lm.commit(model)

## Brick tower of the Roluos temples: the redented prasat in brick with the
## sandstone-framed doorway and lintel on its east face. h is the total
## height above `base`.
static func brick_tower(lm: LandmarkMesh, base: Vector3, hw: float, h: float, tiers: int = 3) -> void:
	U.prasat(lm, "Brick", "Brick", "Dark", base, hw, h, tiers, 0.26, 0.82)
	var body_h := h * 0.74
	var plinth_h := body_h * 0.12
	var wall_h := (body_h - plinth_h) / float(tiers) * 0.62
	var dw := hw * 0.42
	var dh := wall_h * 0.56
	var fx := hw * 1.12 + 0.14
	var y := plinth_h + wall_h * 0.05
	for s in [-1.0, 1.0]:
		lm.box("Stone", base + Vector3(fx, y + dh * 0.5, s * (dw * 0.5 + 0.2)), Vector3(0.32, dh, 0.32),
			Basis(), 0.0)
	lm.box("Stone", base + Vector3(fx + 0.02, y + dh + 0.18, 0), Vector3(0.4, 0.36, dw + 0.9), Basis(), 0.0)

## Preah Ko (14.5 m): the six brick towers of 879 in two rows of three on a
## low sandstone platform, all facing east, the front central tower the
## tallest; the three Nandi bulls that give the temple its name kneel before
## the front towers. Inside the 97 x 80 m laterite wall with its east
## gopura and two brick libraries, and the 500 x 400 m outer wall with
## laterite gopuras east and west. Built facing +X (east).
static func preah_ko(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E5039", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A8C72", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	lm.box("Stone", Vector3(0, 0.1, 0), Vector3(26.0, 0.2, 40.0))
	lm.box("Stone", Vector3(0, 0.55, 0), Vector3(24.4, 0.7, 38.4))
	lm.box("Stone", Vector3(0, 0.88, 0), Vector3(25.2, 0.12, 39.2), Basis(), 0.0)
	U.stair(lm, "Stone", Vector3(12.2, 0, 0), Basis(Vector3.UP, PI * 0.5), 5.0, 3, 0.4, 0.3)
	# Total heights above ground (front row east, rear row west).
	var rows: Array = [[7.0, [13.0, 14.5, 13.0]], [-7.0, [11.5, 12.5, 11.5]]]
	for row in rows:
		var x: float = row[0]
		var hs: Array = row[1]
		for k in 3:
			brick_tower(lm, Vector3(x, 0.9, (float(k) - 1.0) * 13.0), 2.4, float(hs[k]) - 0.9, 3)
	# The three Nandi before the front towers, facing west.
	for k in 3:
		K.nandi(lm, "Stone", Vector3(18.5, 0, (float(k) - 1.0) * 13.0), Basis(Vector3.UP, -PI * 0.5))
	# Inner enclosure with the east gopura and the libraries.
	K.ring(lm, "Laterite", "Stone", 48.5, 40.0, 2.4, 1.2, 2.5)
	K.gopura_roofed(lm, "Brick", "Stone", "Dark", Vector3(48.5, 0, 0), Basis(Vector3.UP, PI * 0.5),
		6.0, 9.0, 3.3, 2.0)
	for s in [-1.0, 1.0]:
		K.library(lm, "Brick", "Stone", "Dark", Vector3(32.0, 0, s * 24.0), Basis(Vector3.UP, -PI * 0.5),
			4.2, 7.5, 3.0)
	# Outer enclosure 500 x 400 m with laterite gopuras east and west.
	K.ring(lm, "Laterite", "Stone", 250.0, 200.0, 2.6, 1.4, 6.0)
	for s in [-1.0, 1.0]:
		K.gopura_roofed(lm, "Laterite", "Stone", "Dark", Vector3(s * 250.0, 0, 0),
			Basis(Vector3.UP, PI * 0.5), 9.0, 12.0, 4.0, 2.4)
	lm.commit(model)

## Lolei (14.6 m): Yasovarman I's four brick towers (893) in two rows on a
## stepped terrace, facing east: the taller northern pair for the king's
## grandparents, the shorter southern pair for his parents, the front row
## male and the rear row female. The ruined enclosure wall and east gopura
## of the island in the Indratataka baray. Built facing +X (east).
static func lolei(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E5039", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A8C72", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0))
	lm.box("Laterite", Vector3(0, 0.35, 0), Vector3(28.0, 0.7, 30.0))
	lm.box("Stone", Vector3(0, 1.05, 0), Vector3(26.0, 0.7, 28.0))
	lm.box("Stone", Vector3(0, 1.34, 0), Vector3(26.6, 0.12, 28.6), Basis(), 0.0)
	U.stair(lm, "Stone", Vector3(13.0, 0, 0), Basis(Vector3.UP, PI * 0.5), 4.0, 4, 0.45, 0.35)
	# Total heights: [x, z, height].
	var towers: Array = [[6.5, -7.5, 14.6], [-6.5, -7.5, 14.0], [6.5, 7.5, 12.8], [-6.5, 7.5, 12.4]]
	for t in towers:
		brick_tower(lm, Vector3(float(t[0]), 1.4, float(t[1])), 2.3, float(t[2]) - 1.4, 3)
	# Ruined enclosure wall and the east gopura.
	K.ring(lm, "Laterite", "Stone", 40.0, 33.0, 1.8, 1.1, 2.0)
	K.gopura_roofed(lm, "Stone", "Stone", "Dark", Vector3(40.0, 0, 0), Basis(Vector3.UP, PI * 0.5),
		5.0, 7.0, 2.8, 1.6)
	lm.commit(model)
