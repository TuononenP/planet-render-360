class_name LandmarkLpLevant
extends RefCounted

## Roman monuments of the Levant in true metres: the Temple of Bel at
## Palmyra, the Temples of Jupiter and Bacchus at Baalbek, the Oval Plaza
## and Cardo of Jerash and Hadrian's Arch. Ruins are built as they stand.

# --- Palmyra, Temple of Bel ---

## The temple as it stood before its destruction in August 2015 (the
## cella and most of the peristyle were blown up by ISIL). Built in
## compass frame: the cella runs north-south inside a peristyle of 8 x 15
## Corinthian columns on a podium; its entrance and the steps face west
## into the court. Cella parapet with stepped merlons, 22 m at the corner
## stair blocks; the temenos wall and the west propylaeum frame the court.
static func palmyra_bel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCC393", 4.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CDB88F", 6.0))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#1C1712", 3.0, 0.92))
	var pw := 15.4
	var pl := 30.8
	var y0 := 2.6
	lm.box("Court", Vector3(0, -0.2, 0), Vector3(124, 0.4, 134))
	lm.box("Stone", Vector3(0, y0 * 0.5, 0), Vector3(pw * 2.0 + 4.0, y0, pl * 2.0 + 4.0))
	LandmarkLpParts.steps(lm, "Stone", Vector3(-pw - 9.0, 0, 0), Vector3(1, 0, 0), 14.0, 7.0, y0, 5)
	# Peristyle: 15 columns along each long side (the west entrance bay open),
	# 8 along each end; 15 m Corinthian shafts under a 3 m entablature.
	LandmarkLpParts.colonnade(lm, "Stone", Vector3(-pw, y0, -pl), Vector3(-pw, y0, pl), 15,
		0.85, 15.0, 1.9, 3.0, 1.9, [7], 10)
	LandmarkLpParts.colonnade(lm, "Stone", Vector3(pw, y0, -pl), Vector3(pw, y0, pl), 15,
		0.85, 15.0, 1.9, 3.0, 1.9, [], 10)
	for z in [-pl, pl]:
		LandmarkLpParts.colonnade(lm, "Stone", Vector3(-pw, y0, z), Vector3(pw, y0, z), 8,
			0.85, 15.0, 1.9, 3.0, 1.9, [0, 7], 10)
	lm.box("Stone", Vector3(0, y0 + 17.75, 0), Vector3(pw * 2.0 + 1.8, 0.5, pl * 2.0 + 1.8))
	# Cella (10.2 x 25.6 m half-extents) with its parapet, merlons and stair blocks.
	var cw := 10.2
	var cl := 25.6
	var top := 20.4
	lm.box("Stone", Vector3(0, (y0 + top) * 0.5, 0), Vector3(cw * 2.0, top - y0, cl * 2.0))
	var corners := [Vector3(-cw, top, -cl), Vector3(cw, top, -cl), Vector3(cw, top, cl),
		Vector3(-cw, top, cl)]
	for i in 4:
		LandmarkLpParts.merlons(lm, "Stone", corners[i], corners[(i + 1) % 4], 1.0, 1.0, 0.8, 2.0)
	for i in [0, 1, 3]:
		var c: Vector3 = corners[i]
		lm.box("Stone", c + Vector3(-signf(c.x) * 1.8, 0.8, -signf(c.z) * 1.8), Vector3(3.2, 1.6, 3.2))
	# West portal: dark door in a tall jamb-and-lintel frame; high windows.
	lm.box("Door", Vector3(-cw - 0.1, y0 + 5.6, 0), Vector3(0.5, 11.2, 5.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(-cw - 0.4, y0 + 6.2, s * 3.2), Vector3(1.0, 12.4, 1.4))
		for z in [-9.0, 9.0]:
			lm.box("Door", Vector3(s * (cw + 0.05), y0 + 13.5, z), Vector3(0.4, 3.2, 1.4))
	lm.box("Stone", Vector3(-cw - 0.4, y0 + 12.8, 0), Vector3(1.2, 1.6, 8.0))
	# Court: altar, temenos wall and the west propylaeum (four-column portico).
	lm.box("Stone", Vector3(-38, 0.8, 0), Vector3(5, 1.6, 4))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 61.0, 3.5, 0), Vector3(2.0, 7.0, 134))
		lm.box("Stone", Vector3(0, 3.5, s * 66.0), Vector3(124, 7.0, 2.0))
	LandmarkLpParts.colonnade(lm, "Stone", Vector3(-65.0, 0, -5.4), Vector3(-65.0, 0, 5.4), 4,
		0.7, 11.0, 1.5, 1.8, 1.6, [], 10)
	lm.gable("Stone", Vector3(-65.0, 12.5, 0), 12.0, 4.0, 2.2,
		Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	lm.commit(model)

# --- Baalbek, Temples of Jupiter and Bacchus ---

## Baalbek in compass frame, both temples facing east. The Jupiter
## podium (47.7 x 87.75 m on megalith courses, 13 m high) carries the six
## surviving 19.9 m columns of the south flank with their entablature
## (37.5 m); the Temple of Bacchus (66 x 35 m, 30 m) stands to the south-east
## with its full cella walls, the north colonnade and four south columns.
static func baalbek(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6BC8C", 5.0))
	lm.use("Megalith", LandmarkMaterials.pbr("stone", "#BFA076", 8.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#BAA67E", 6.0))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#1C1712", 3.0, 0.92))
	var j := Vector3(-27, 0, -30)
	var b := Vector3(38, 0, 35)
	lm.box("Court", Vector3(0, -0.2, 2), Vector3(170, 0.4, 130))
	# Jupiter: megalith base, temple podium, east stair, column stumps, six standing columns.
	lm.box("Megalith", j + Vector3(0, 3.25, 0), Vector3(94, 6.5, 54))
	lm.box("Stone", j + Vector3(0, 9.75, 0), Vector3(87.75, 6.5, 47.7))
	LandmarkLpParts.steps(lm, "Megalith", j + Vector3(67, 0, 0), Vector3(-1, 0, 0), 28.0, 23.1, 13.0, 10)
	for i in 19:
		var x := j.x - 40.5 + 4.5 * i
		for s in [-1.0, 1.0]:
			if not (s > 0.0 and i >= 4 and i <= 9):
				lm.frustum("Stone", Vector3(x, 13.0, j.z + s * 18.5), 1.5, 1.3, 1.6, 8)
	for i in range(1, 9):
		lm.frustum("Stone", Vector3(j.x - 40.5, 13.0, j.z - 18.5 + 4.11 * i), 1.5, 1.3, 1.6, 8)
		lm.frustum("Stone", Vector3(j.x + 40.5, 13.0, j.z - 18.5 + 4.11 * i), 1.5, 1.3, 1.6, 8)
	LandmarkLpParts.colonnade(lm, "Stone", Vector3(j.x - 22.5, 13.0, j.z + 18.5),
		Vector3(j.x, 13.0, j.z + 18.5), 6, 1.2, 19.9, 2.4, 4.6, 3.4, [], 14)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", j + Vector3(sx * 20.0, 14.8, 0), Vector3(1.8, 3.6, 22))
	for sz in [-1.0, 1.0]:
		lm.box("Stone", j + Vector3(0, 14.8, sz * 10.0), Vector3(40, 3.6, 1.8))
	# Bacchus: podium and stair, cella walls to the full 25 m, 15-column north
	# colonnade with entablature, four south columns, stumps elsewhere.
	var py := 6.0
	lm.box("Stone", b + Vector3(0, py * 0.5, 0), Vector3(66, py, 35))
	LandmarkLpParts.steps(lm, "Stone", b + Vector3(43, 0, 0), Vector3(-1, 0, 0), 9.0, 10.0, py, 6)
	lm.box("Stone", b + Vector3(0, py + 9.5, 0), Vector3(49, 19.0, 21.2))
	lm.box("Stone", b + Vector3(0, py + 19.5, 0), Vector3(50, 1.0, 22.2))
	lm.box("Door", b + Vector3(24.6, py + 6.5, 0), Vector3(0.5, 13.0, 6.2))
	for s in [-1.0, 1.0]:
		lm.box("Stone", b + Vector3(25.0, py + 7.0, s * 4.0), Vector3(1.0, 14.0, 1.6))
	lm.box("Stone", b + Vector3(25.0, py + 14.4, 0), Vector3(1.2, 1.4, 9.0))
	for s in [-1.0, 1.0]:
		for i in 15:
			var p := b + Vector3(-28.5 + 4.07 * i, py, s * 14.8)
			if s < 0.0 or i < 4:
				LandmarkLpParts.column(lm, "Stone", p, 1.0, 19.6, 2.3, 12)
			else:
				lm.frustum("Stone", p, 1.4, 1.2, 1.4, 8)
	lm.beam("Stone", b + Vector3(-28.5, py + 19.6 + 2.3, -14.8), b + Vector3(28.5, py + 19.6 + 2.3, -14.8),
		4.6, 2.2, Vector3.UP)
	for sx in [-1.0, 1.0]:
		for i in range(1, 7):
			lm.frustum("Stone", b + Vector3(sx * 28.5, py, -14.8 + 4.23 * i), 1.4, 1.2, 1.4, 8)
	lm.commit(model)

# --- Jerash, Oval Plaza and Cardo ---

## Plaza centre (0, 0, 20): the 90 x 80 m oval paved forum ringed by 56
## Ionic columns (5.8 m, entablature to 7.3 m) with the Cardo Maximus
## leaving north (-Z) between two Corinthian colonnades (11.5 m) and
## shopfronts. Built along the Cardo axis; yaw turns it onto its NNW bearing.
static func jerash_plaza(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCC9A2", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C9B791", 5.0))
	lm.use("Rubble", LandmarkMaterials.pbr("stone", "#B49A72", 5.0))
	var cz := 20.0
	var ea := 40.0
	var eb := 45.0
	var floor_poly := PackedVector2Array()
	for i in 56:
		var t := TAU * float(i) / 56.0
		floor_poly.append(Vector2(cos(t) * (ea + 3.0), cz + sin(t) * (eb + 3.0)))
	lm.poly_prism("Paving", floor_poly, -0.5, 0.0)
	lm.box("Paving", Vector3(0, -0.25, -47.0), Vector3(14, 0.5, 44))
	lm.box("Stone", Vector3(0, 0.7, cz), Vector3(4.5, 1.4, 4.5))
	var pos := PackedVector3Array()
	var keep: Array[bool] = []
	for i in 56:
		var t := TAU * float(i) / 56.0
		var p := Vector3(cos(t) * ea, 0, cz + sin(t) * eb)
		var gap := p.z < cz - eb * 0.86 and absf(p.x) < 14.0
		pos.append(p)
		keep.append(not gap)
		if not gap:
			LandmarkLpParts.column(lm, "Stone", p, 0.4, 5.8, 0.7, 10)
	for i in 56:
		if keep[i] and keep[(i + 1) % 56]:
			lm.beam("Stone", pos[i] + Vector3(0, 6.55, 0), pos[(i + 1) % 56] + Vector3(0, 6.55, 0),
				1.5, 1.0, Vector3.UP)
	# Cardo: two Corinthian colonnades of eight 10 m columns and a row of shopfronts each.
	for s in [-1.0, 1.0]:
		LandmarkLpParts.colonnade(lm, "Stone", Vector3(s * 7.5, 0, -30.0), Vector3(s * 7.5, 0, -68.0), 8,
			0.5, 10.0, 1.4, 1.5, 1.2, [], 10)
		lm.box("Rubble", Vector3(s * 13.0, 2.6, -49.0), Vector3(6.0, 5.2, 40.0))
		lm.box("Paving", Vector3(s * 10.0, 0.15, -49.0), Vector3(5.0, 0.3, 40.0))
	lm.commit(model)

# --- Jerash, Hadrian's Arch ---

## Triple-arched gateway of AD 129-130 as restored (37.45 x 9.25 m, 11 m):
## three vaulted passages, four engaged Corinthian columns on 2.2 m
## pedestals on each face, niches over the side arches, attic with the
## triangular cornice over the centre. Faces the road (north-south).
static func hadrians_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9C49A", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2218", 3.0, 0.92))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#BFAE8A", 5.0))
	lm.box("Paving", Vector3(0, -0.2, 0), Vector3(46, 0.4, 20))
	var arches := [[-12.5, 2.2, 3.2, 2.2], [0.0, 3.3, 5.0, 3.3], [12.5, 2.2, 3.2, 2.2]]
	var wall := LandmarkLpParts.arcade_outline(37.45, 9.8, arches)
	LandmarkLpParts.slab(lm, "Stone", wall, Vector3(0, 0, 4.625), 0.0, 9.25)
	for fz in [-1.0, 1.0]:
		for x in [-8.4, -4.7, 4.7, 8.4]:
			lm.box("Stone", Vector3(x, 1.1, fz * 5.0), Vector3(2.25, 2.2, 1.2))
			LandmarkLpParts.column(lm, "Stone", Vector3(x, 2.2, fz * 5.0), 0.55, 7.0, 1.3, 10)
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(s * 12.5, 6.6, fz * 4.75), Vector3(3.2, 2.2, 0.5))
			lm.box("Dark", Vector3(s * 12.5, 6.6, fz * 5.05), Vector3(1.6, 1.8, 0.12))
		lm.box("Stone", Vector3(0, 9.4, fz * 4.9), Vector3(25.5, 1.0, 1.5))
	lm.box("Stone", Vector3(0, 10.1, 0), Vector3(15.5, 0.6, 9.4))
	lm.gable("Stone", Vector3(0, 10.4, 0), 15.5, 9.4, 1.0, Basis(), 0.0, "Stone")
	lm.commit(model)
