class_name LandmarkAtChurches
extends RefCounted

## The Chapel of St George on Mount Lycabettus and the Metropolitan
## Cathedral of Athens in true metres.

# --- Chapel of St George, Lycabettus -----------------------------------

## Origin at the middle of the summit platform (the hill's 277 m top is
## the ground, y = 0); front and bell tower toward +Z, apse toward -Z
## (yaw_deg turns the front west). The whitewashed single-nave chapel
## under a terracotta gable, the half-round apse, the corner bell tower
## with its arched belfry, tiled pyramid and cross (11.3 m), the low
## courtyard wall and the rock below.
static func lycabettus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#F1EEE6", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B5643A", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8E8878", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 2.0))
	lm.box("Rock", Vector3(0, -2.5, 0), Vector3(19.0, 5.0, 22.0))
	lm.box("Render", Vector3(0, 2.5, 0), Vector3(6.2, 5.0, 7.6))
	lm.gable("Tile", Vector3(0, 5.0, 0), 6.2, 7.6, 1.9, Basis(), 0.4, "Render")
	lm.frustum("Render", Vector3(0, 0, -3.8), 2.3, 2.3, 4.2, 16)
	lm.frustum("Tile", Vector3(0, 4.2, -3.8), 2.5, 0.0, 1.8, 12)
	# Bell tower on the front left corner.
	var tc := Vector3(-2.2, 0, 5.0)
	lm.box("Render", tc + Vector3(0, 4.2, 0), Vector3(3.2, 8.4, 3.2))
	lm.box("Render", tc + Vector3(0, 8.55, 0), Vector3(3.6, 0.3, 3.6))
	lm.spire("Tile", tc + Vector3(0, 8.7, 0), 1.8, 1.6)
	lm.box("Render", tc + Vector3(0, 10.8, 0), Vector3(0.14, 1.0, 0.14))
	lm.box("Render", tc + Vector3(0, 11.0, 0), Vector3(0.6, 0.12, 0.14))
	SEuUtil.face_row(lm, "Shadow", Vector3(-2.2, 0, 6.6), Vector3.RIGHT, Vector3(0, 0, 1), 5.8, 1, 0.0, 1.2, 2.2)
	SEuUtil.face_row(lm, "Shadow", Vector3(-3.8, 0, 5.0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 5.8, 1, 0.0, 1.2, 2.2)
	SEuUtil.face_row(lm, "Shadow", Vector3(-0.6, 0, 5.0), Vector3(0, 0, 1), Vector3(1, 0, 0), 5.8, 1, 0.0, 1.2, 2.2)
	# Door, side windows.
	SEuUtil.face_row(lm, "Shadow", Vector3(1.2, 0, 3.8), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 1, 0.0, 1.3, 2.6)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 3.1, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 1.8, 2, 3.0, 0.8, 1.7)
	# Low whitewashed courtyard wall with a gap at the entrance.
	lm.box("Render", Vector3(0, 0.5, -10.0), Vector3(17.0, 1.0, 0.35))
	for s in [-1.0, 1.0]:
		lm.box("Render", Vector3(s * 8.5, 0.5, 0), Vector3(0.35, 1.0, 20.0))
		lm.box("Render", Vector3(s * 5.9, 0.5, 10.0), Vector3(5.2, 1.0, 0.35))
	lm.commit(model)

# --- Metropolitan Cathedral of Athens --------------------------------------

## Origin at the crossing, front toward +Z (yaw_deg turns it west onto
## Mitropoleos Square). The 1842-62 three-aisled domed basilica: raised
## nave under a tiled gable with clerestory windows, lower aisles, the
## apse, the tetrastyle Ionic porch with its pediment, two corner bell
## towers and the drum, grey dome and cross (24 m).
static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CDB2", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E9E0CC", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A9573A", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7F8689", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Stone", Vector3(0, 7.25, -2.0), Vector3(11.0, 16.5, 36.0))
	lm.gable("Tile", Vector3(0, 15.5, -2.0), 11.0, 36.0, 3.2, Basis(), 0.5, "Stone")
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 8.25, 4.5, -2.0), Vector3(5.5, 11.0, 36.0))
		lm.quad("Tile", Vector3(s * 11.3, 10.0, -20.3), Vector3(s * 11.3, 10.0, 16.3),
			Vector3(s * 5.5, 12.0, 16.3), Vector3(s * 5.5, 12.0, -20.3), Vector3(s * 0.3, 1.0, 0.0).normalized())
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 11.0, 0, -2.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 3.0, 8, 4.2, 1.5, 4.0)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 5.5, 0, -2.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 13.0, 8, 4.2, 1.5, 2.2)
	# Apse and the dome on its drum over the crossing.
	lm.frustum("Stone", Vector3(0, 0, -20.0), 5.5, 5.5, 14.0, 16)
	lm.frustum("Tile", Vector3(0, 14.0, -20.0), 5.7, 0.0, 3.5, 12)
	lm.frustum("Stone", Vector3(0, 12.0, -2.0), 5.4, 5.4, 8.0, 16)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 12.0, -2.0), 5.4, 16, 8, 6.6, 1.4, 1.4, false, 0.2)
	lm.frustum("Marble", Vector3(0, 20.0, -2.0), 5.8, 5.8, 0.4, 16)
	lm.lathe("Dome", Vector3(0, 20.4, -2.0), SEuUtil.dome(5.7, 2.4, 8), 16)
	lm.frustum("Stone", Vector3(0, 22.8, -2.0), 1.0, 0.9, 0.5, 10)
	lm.box("Gold", Vector3(0, 23.65, -2.0), Vector3(0.14, 0.7, 0.14))
	lm.box("Gold", Vector3(0, 23.8, -2.0), Vector3(0.6, 0.12, 0.14))
	# Front: tetrastyle Ionic porch on steps, doors, bell towers.
	var y0 := 0.9
	AtUtil.steps(lm, "Marble", Vector3(0, y0, 17.8), 16.0, 4.0, 3, 0.3, 0.4, 2.0)
	for x in [-5.7, -1.9, 1.9, 5.7]:
		AtUtil.ionic(lm, "Marble", Vector3(x, y0, 19.5), 8.5, 0.55, 16, 0.0)
	lm.box("Marble", Vector3(0, y0 + 8.85, 19.5), Vector3(16.4, 0.7, 1.4))
	lm.box("Stone", Vector3(0, y0 + 9.55, 19.5), Vector3(16.3, 0.7, 1.3))
	lm.box("Marble", Vector3(0, y0 + 10.1, 19.5), Vector3(16.8, 0.4, 2.0))
	AtUtil.roof(lm, "Tile", "Marble", "Stone", Vector3(0, y0 + 10.3, 17.8), 16.4, 5.4, 2.2, 0.2)
	lm.box("Stone", Vector3(0, y0 + 5.0, 17.0), Vector3(16.0, 10.0, 2.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, y0, 18.0), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 1, 0.0, 3.0, 5.5)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, y0, 18.0), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 2, 11.4, 1.8, 4.0)
	for s in [-1.0, 1.0]:
		var tc := Vector3(s * 9.0, 0, 14.0)
		lm.box("Stone", tc + Vector3(0, 8.5, 0), Vector3(4.0, 17.0, 4.0))
		lm.box("Marble", tc + Vector3(0, 17.2, 0), Vector3(4.5, 0.4, 4.5))
		lm.spire("Tile", tc + Vector3(0, 17.4, 0), 2.0, 3.2)
		lm.box("Gold", tc + Vector3(0, 21.1, 0), Vector3(0.12, 0.9, 0.12))
		lm.box("Gold", tc + Vector3(0, 21.3, 0), Vector3(0.5, 0.1, 0.12))
		SEuUtil.face_row(lm, "Shadow", tc + Vector3(0, 0, 2.0), Vector3.RIGHT, Vector3(0, 0, 1), 12.6, 1, 0.0, 1.4, 3.6)
		SEuUtil.face_row(lm, "Shadow", tc + Vector3(s * 2.0, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 12.6, 1, 0.0, 1.4, 3.6)
	lm.commit(model)
