class_name LandmarkItlChurches
extends RefCounted

## The Mole Antonelliana of Turin and the Basilica of St Francis of Assisi
## in true metres: a stone cube under a pavilion dome, colonnaded
## tempietto and needle spire; a double Romanesque-Gothic church on the
## arched substructure of its hillside.

# --- Mole Antonelliana ------------------------------------------------------

const MOLE_HW := 21.3
const CUBE_TOP := 46.0

## Origin at the centre of the cube. 167.5 m: the stepped plinth and the
## 43 m cube (giant pilasters, a tier of tall arches, a tier of arched
## windows and a square-headed attic on each face, strong cornice), the
## 37 m concave pavilion dome, two colonnaded tiers of the tempietto,
## the 39 m stepped spire and the 4 m copper star on top.
static func mole_antonelliana(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D3BE92", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EBE1C6", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("limestone", "#C2AE86", 3.0))
	lm.use("Spire", LandmarkMaterials.pbr("limestone", "#B9B8AE", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#463D33", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Trim", Vector3(0, 1.0, 0), Vector3(50.0, 2.0, 50.0))
	lm.box("Trim", Vector3(0, 2.7, 0), Vector3(47.0, 1.4, 47.0))
	lm.box("Wall", Vector3(0, (3.4 + CUBE_TOP) * 0.5, 0), Vector3(MOLE_HW * 2.0, CUBE_TOP - 3.4, MOLE_HW * 2.0))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := b * Vector3(0, 0, 1)
		var right := b * Vector3(1, 0, 0)
		var face := out * MOLE_HW
		for i in 5:
			lm.box("Trim", face + out * 0.35 + right * (-17.0 + 8.5 * float(i)) + Vector3(0, 18.0, 0),
				Vector3(1.8, 28.0, 0.7), b)
		SEuUtil.face_row(lm, "Shadow", face + out * 0.06, right, out, 4.5, 4, 8.5, 5.0, 12.0)
		SEuUtil.face_row(lm, "Shadow", face + out * 0.06, right, out, 19.0, 4, 8.5, 4.0, 8.0)
		SEuUtil.face_row(lm, "Shadow", face + out * 0.06, right, out, 30.5, 4, 8.5, 3.0, 5.0)
		for y in [17.6, 29.0]:
			lm.box("Trim", face + out * 0.3 + Vector3(0, y, 0), Vector3(MOLE_HW * 2.0 + 1.0, 0.8, 0.7), b)
	lm.box("Trim", Vector3(0, CUBE_TOP + 1.0, 0), Vector3(MOLE_HW * 2.0 + 2.4, 2.0, MOLE_HW * 2.0 + 2.4))
	# Pavilion dome: a square concave vault, hw -> radius for a 4-sided lathe.
	var dome := PackedVector2Array()
	for p in [[20.0, 0.0], [18.0, 6.0], [15.0, 14.0], [11.8, 23.0], [9.4, 31.0], [8.0, 37.0]]:
		dome.append(Vector2(float(p[0]) * sqrt(2.0), float(p[1])))
	lm.lathe("Dome", Vector3(0, CUBE_TOP + 2.0, 0), dome, 4, 1.0, 1.0, PI * 0.25, false)
	# Tempietto: two colonnaded tiers.
	_tier(lm, 85.0, 8.0, 5.2, 6.8, 5, 0.5, 14.8)
	_tier(lm, 102.4, 6.0, 3.6, 5.0, 5, 0.38, 13.8)
	var cap := PackedVector2Array()
	for p in [[5.4, 0.0], [4.2, 1.5], [2.8, 3.2], [1.4, 4.6], [0.9, 5.2]]:
		cap.append(Vector2(float(p[0]) * sqrt(2.0), float(p[1])))
	lm.lathe("Dome", Vector3(0, 118.8, 0), cap, 4, 1.0, 1.0, PI * 0.25, false)
	# Spire: eight-sided shaft with stepped ledges.
	var sp := PackedVector2Array()
	for p in [[2.4, 0.0], [1.9, 6.0], [2.5, 6.0], [2.5, 6.6], [1.8, 7.2], [1.4, 15.0], [2.0, 15.0], [2.0, 15.6],
			[1.3, 16.2], [1.0, 24.0], [1.5, 24.0], [1.5, 24.5], [0.9, 25.0], [0.7, 32.0], [1.0, 32.0],
			[1.0, 32.5], [0.5, 33.0], [0.3, 39.5]]:
		sp.append(Vector2(float(p[0]), float(p[1])))
	lm.lathe("Spire", Vector3(0, 124.0, 0), sp, 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Gold", Vector3(0, 163.4, 0), 0.2, 0.15, 2.3, 6)
	LandmarkItlUtil.star(lm, "Gold", Vector3(0, 165.5, 0), 2.0)
	lm.commit(model)

## One colonnaded tier of the tempietto: slab, cell, ring of columns, entablature.
static func _tier(lm: LandmarkMesh, y0: float, slab_hw: float, cell_hw: float, ring_hw: float, per_side: int,
		col_r: float, col_h: float) -> void:
	lm.box("Trim", Vector3(0, y0 + 0.6, 0), Vector3(slab_hw * 2.0, 1.2, slab_hw * 2.0))
	lm.box("Wall", Vector3(0, y0 + 1.2 + col_h * 0.5, 0), Vector3(cell_hw * 2.0, col_h, cell_hw * 2.0))
	for i in per_side:
		var s := -ring_hw + 2.0 * ring_hw * float(i) / float(per_side - 1)
		for p in [Vector3(s, 0, ring_hw), Vector3(s, 0, -ring_hw)]:
			lm.frustum("Trim", p + Vector3(0, y0 + 1.2, 0), col_r, col_r * 0.85, col_h, 10)
		if i > 0 and i < per_side - 1:
			for p in [Vector3(ring_hw, 0, s), Vector3(-ring_hw, 0, s)]:
				lm.frustum("Trim", p + Vector3(0, y0 + 1.2, 0), col_r, col_r * 0.85, col_h, 10)
	lm.box("Trim", Vector3(0, y0 + 1.2 + col_h + 0.7, 0), Vector3(ring_hw * 2.0 + 1.6, 1.4, ring_hw * 2.0 + 1.6))

# --- Basilica of St Francis -------------------------------------------------

## Origin on the nave axis in the middle of the church, the upper church
## facade facing +Z (uphill onto the Piazza Superiore), the apse toward
## the valley, the friary on the +X flank, y = 0 at the lower piazza with
## masonry running down to -14. The lower church (a vast crypt) carries
## the upper church with its steep gable, rose window, Gothic portal and
## semicircular buttresses, a transept and a round apse; the friary's
## arcaded tiers and buttress piers hold the slope; the Romanesque
## campanile stands at the left (-X), beside the lower church entrance.
static func assisi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDC9B3", 3.0))
	lm.use("Stone2", LandmarkMaterials.pbr("limestone", "#E2CDBB", 3.0))
	lm.use("Facade", LandmarkMaterials.pbr("limestone", "#EDE6D8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DFCF", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A4604A", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#40382F", 3.0))
	var along := Basis(Vector3.UP, PI * 0.5)
	# Lower church, upper church, transept and apse.
	lm.box("Stone", Vector3(0, 0.75, 0), Vector3(33.0, 21.5, 76.0))
	lm.box("Stone", Vector3(0, 0.75, -22.0), Vector3(54.0, 21.5, 12.0))
	lm.box("Facade", Vector3(0, 21.75, 1.0), Vector3(27.0, 20.5, 70.0))
	lm.gable("Tile", Vector3(0, 32.0, 1.0), 27.0, 70.0, 8.0, Basis(), 0.5, "Facade")
	lm.box("Facade", Vector3(0, 21.75, -22.0), Vector3(54.0, 20.5, 12.0))
	lm.gable("Tile", Vector3(0, 32.0, -22.0), 12.0, 54.0, 6.0, along, 0.4, "Facade")
	lm.frustum("Stone", Vector3(0, -10.0, -36.0), 8.4, 7.8, 42.0, 14)
	lm.frustum("Tile", Vector3(0, 32.0, -36.0), 8.6, 0.0, 6.0, 14)
	for k in 8:
		for sx in [-1.0, 1.0]:
			lm.frustum("Facade", Vector3(sx * 13.5, 11.5, -27.0 + 8.0 * float(k)), 2.2, 1.8, 20.5, 12)
	for sx in [-1.0, 1.0]:
		var out := Vector3(sx, 0, 0)
		SEuUtil.face_row(lm, "Shadow", out * 13.55 + Vector3(0, 0, 1.0), Vector3(0, 0, 1), out, 18.0, 7, 8.0, 2.2, 10.0, true)
		SEuUtil.face_row(lm, "Shadow", out * 16.55 + Vector3(0, 0, 1.0), Vector3(0, 0, 1), out, 3.0, 7, 8.0, 1.6, 4.4, true)
	# Upper facade: Gothic portal, small and great rose windows, gable eye.
	var fz := 36.06
	SEuUtil.opening(lm, "Shadow", Vector3(0, 11.5, fz), Vector3.RIGHT, Vector3.UP, 6.0, 8.0, true)
	lm.box("Trim", Vector3(0, 22.0, fz - 0.1), Vector3(27.4, 0.6, 0.6))
	lm.disc("Shadow", Vector3(0, 20.0, fz), Vector3(0, 0, 1), 1.4, 16)
	lm.disc("Trim", Vector3(0, 27.0, fz - 0.03), Vector3(0, 0, 1), 4.0, 24)
	lm.disc("Shadow", Vector3(0, 27.0, fz), Vector3(0, 0, 1), 3.3, 24)
	lm.disc("Shadow", Vector3(0, 34.6, fz), Vector3(0, 0, 1), 0.9, 12)
	for sx in [-1.0, 1.0]:
		lm.frustum("Facade", Vector3(sx * 13.5, 0.0, 36.0), 1.8, 1.5, 32.0, 10)
	# Lower church: Gothic double portal under the Renaissance portico (north).
	lm.box("Trim", Vector3(-17.8, 5.0, 8.0), Vector3(3.6, 10.0, 12.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(-19.62, 0, 8.0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 0.0, 3, 3.8, 3.0, 5.8)
	# Friary: the arched substructure along the north flank and past the apse.
	lm.box("Stone2", Vector3(25.25, 4.0, -24.0), Vector3(17.5, 36.0, 64.0))
	lm.gable("Tile", Vector3(25.25, 22.0, -24.0), 17.5, 64.0, 3.2, Basis(), 0.5, "Stone2")
	var north := Vector3(34.0, 0, -24.0)
	SEuUtil.face_row(lm, "Shadow", north, Vector3(0, 0, -1), Vector3(1, 0, 0), 0.4, 4, 14.0, 9.0, 9.6)
	SEuUtil.face_row(lm, "Shadow", north, Vector3(0, 0, -1), Vector3(1, 0, 0), 11.0, 8, 7.0, 3.8, 6.5)
	SEuUtil.face_row(lm, "Shadow", north, Vector3(0, 0, -1), Vector3(1, 0, 0), 19.0, 8, 7.0, 1.6, 2.2)
	var west := Vector3(25.25, 0, -56.0)
	SEuUtil.face_row(lm, "Shadow", west, Vector3(1, 0, 0), Vector3(0, 0, -1), 0.4, 2, 8.4, 5.4, 8.6)
	SEuUtil.face_row(lm, "Shadow", west, Vector3(1, 0, 0), Vector3(0, 0, -1), 11.0, 3, 5.4, 3.2, 6.0)
	SEuUtil.face_row(lm, "Shadow", west, Vector3(1, 0, 0), Vector3(0, 0, -1), 19.0, 3, 5.4, 1.6, 2.2)
	for i in 5:
		lm.box("Stone2", Vector3(35.4, -2.0, -52.0 + 14.0 * float(i)), Vector3(2.8, 24.0, 2.4))
	lm.box("Trim", Vector3(34.5, 10.3, -24.0), Vector3(1.6, 0.6, 64.0))
	# The campanile, foundations to -10.
	var c := Vector3(-21.5, 0, 24.0)
	var rows := [[3.0, 0.8, 2.8, 1, 0.0, false], [14.0, 0.8, 2.8, 1, 0.0, false], [25.0, 1.0, 3.2, 1, 0.0, false],
		[34.0, 1.2, 3.6, 2, 2.6, false], [43.5, 1.3, 5.4, 3, 2.3, false]]
	LandmarkItlUtil.tower(lm, "Stone", "Shadow", c + Vector3(0, -10.0, 0), 4.3, c + Vector3(0, 55.0, 0), 3.8, 0.0, rows)
	for y in [12.0, 22.0, 32.0, 41.0, 55.5]:
		lm.box("Trim", c + Vector3(0, y, 0), Vector3(9.0, 0.6, 9.0))
	lm.spire("Tile", c + Vector3(0, 55.8, 0), 4.0, 3.6)
	SEuUtil.finial(lm, "Trim", c + Vector3(0, 59.4, 0), 2.6)
	lm.commit(model)
