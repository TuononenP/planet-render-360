class_name LandmarkRmLPaul
extends RefCounted

## St Paul Outside the Walls and Santa Maria in Trastevere, two of Rome's
## early Christian basilicas, in true metres.

# --- St Paul Outside the Walls -----------------------------------------------

## Origin at the middle of the whole complex, facade facing +Z (west by the
## Via Ostiense; yaw_deg turns it): the 65 m mosaic facade under its gold
## gable (38 m), the arcaded quadriporticus of granite columns with the
## statue of St Paul in its garden in front of it, the 112 m nave with its
## clerestory and tiled roof, the transept and the apse behind.
static func paul(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C2A47C", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C8A7", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DFC8", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C8B87", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	# Nave: aisles, clerestory, tiled ridge; transept and apse behind.
	lm.box("Wall", Vector3(0, 11.0, -16.0), Vector3(65.0, 22.0, 112.0))
	lm.box("Wall", Vector3(0, 26.5, -16.0), Vector3(26.0, 9.0, 112.0))
	lm.gable("Tile", Vector3(0, 31.0, -16.0), 26.0, 112.0, 4.5, Basis(), 0.5, "Wall")
	lm.box("Wall", Vector3(0, 15.0, -84.5), Vector3(94.0, 30.0, 25.0))
	lm.gable("Tile", Vector3(0, 30.0, -84.5), 25.0, 94.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Wall")
	lm.frustum("Wall", Vector3(0, 0, -97.0), 14.0, 14.0, 26.0, 24)
	lm.lathe("Tile", Vector3(0, 26.0, -97.0), SEuUtil.dome(14.3, 5.0, 5), 24)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 13.0, 0, -16.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			22.5, 10, 11.0, 2.2, 5.0)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 32.5, 0, -16.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			8.0, 9, 12.0, 2.0, 5.0)
	# Facade: wall, mosaic panels, gable with the Christ mosaic.
	lm.box("Stone", Vector3(0, 16.0, 41.5), Vector3(65.0, 32.0, 3.0))
	lm.box("Gold", Vector3(0, 21.5, 43.1), Vector3(44.0, 9.0, 0.3))
	lm.box("Gold", Vector3(0, 12.5, 43.1), Vector3(60.0, 2.4, 0.3))
	lm.box("Trim", Vector3(0, 32.4, 41.5), Vector3(66.5, 0.8, 3.8))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(0, 32.8, 41.5), 66.5, 5.2, 3.0, "Gold")
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 43.0), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 5, 11.0, 4.2, 8.5)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 43.0), Vector3.RIGHT, Vector3(0, 0, 1), 26.0, 5, 11.0, 2.0, 3.6)
	# Quadriporticus: outer walls, inner granite colonnades, lean-to roofs.
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 35.0, 6.0, 77.0), Vector3(1.0, 12.0, 66.0))
		lm.box("Tile", Vector3(s * 31.0, 10.6, 77.0), Vector3(8.0, 0.5, 66.0))
		lm.box("Trim", Vector3(s * 27.0, 9.3, 77.0), Vector3(1.0, 0.8, 50.0))
		SEuUtil.column_row(lm, "Granite", Vector3(s * 27.0, 0, 52.0), Vector3(s * 27.0, 0, 102.0), 15, 8.9, 0.55, 10)
	lm.box("Wall", Vector3(0, 6.0, 110.0), Vector3(70.0, 12.0, 1.0))
	lm.box("Tile", Vector3(0, 10.6, 106.0), Vector3(54.0, 0.5, 8.0))
	lm.box("Tile", Vector3(0, 10.6, 48.0), Vector3(54.0, 0.5, 8.0))
	lm.box("Trim", Vector3(0, 9.3, 102.0), Vector3(54.0, 0.8, 1.0))
	lm.box("Trim", Vector3(0, 9.3, 52.0), Vector3(54.0, 0.8, 1.0))
	SEuUtil.column_row(lm, "Granite", Vector3(-27.0, 0, 102.0), Vector3(27.0, 0, 102.0), 17, 8.9, 0.55, 10)
	SEuUtil.column_row(lm, "Granite", Vector3(-27.0, 0, 52.0), Vector3(27.0, 0, 52.0), 17, 8.9, 0.55, 10)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 109.5), Vector3.RIGHT, Vector3(0, 0, -1), 0.0, 1, 4.0, 4.0, 7.0)
	lm.box("Marble", Vector3(0, 2.0, 77.0), Vector3(4.0, 4.0, 4.0))
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, 4.0, 77.0), 6.0, true)
	lm.commit(model)

# --- Santa Maria in Trastevere ----------------------------------------------------

## Origin at the middle of the church, facade facing +Z (east onto the
## piazza; yaw_deg turns it): Fontana's five-arched portico with its
## balustrade and statues over the 12th-century facade with the gold
## mosaic band, the nave and aisles under tile, the apse, and the brick
## Romanesque campanile (31 m) beside the right aisle.
static func trastevere(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#C9A877", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C8A7", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DFC8", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A06C4C", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Plaster", Vector3(0, 8.0, -3.0), Vector3(38.0, 16.0, 68.0))
	lm.box("Plaster", Vector3(0, 18.0, -3.0), Vector3(20.0, 8.0, 68.0))
	lm.gable("Tile", Vector3(0, 22.0, -3.0), 20.0, 68.0, 4.0, Basis(), 0.5, "Plaster")
	lm.box("Trim", Vector3(0, 16.2, -3.0), Vector3(39.0, 0.6, 69.0))
	lm.frustum("Plaster", Vector3(0, 0, -37.0), 7.5, 7.5, 16.0, 16)
	lm.lathe("Tile", Vector3(0, 16.0, -37.0), SEuUtil.dome(7.7, 3.0, 4), 16)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 10.0, 0, -3.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			17.0, 7, 9.0, 1.6, 4.0)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 19.0, 0, -3.0), Vector3(0, 0, 1), Vector3(s, 0, 0),
			6.0, 6, 10.0, 1.6, 4.4)
	# Romanesque facade with the gold mosaic frieze, Fontana's portico.
	lm.box("Plaster", Vector3(0, 11.5, 31.0), Vector3(38.0, 23.0, 2.0))
	lm.box("Trim", Vector3(0, 23.2, 31.0), Vector3(38.6, 0.8, 2.8))
	LandmarkRmLUtil.pediment(lm, "Trim", Vector3(0, 23.6, 31.0), 38.6, 4.2, 2.4, "Plaster")
	lm.box("Gold", Vector3(0, 16.5, 32.15), Vector3(33.0, 4.4, 0.3))
	lm.box("Gold", Vector3(0, 20.4, 32.15), Vector3(14.0, 2.2, 0.3))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 32.0), Vector3.RIGHT, Vector3(0, 0, 1), 13.0, 3, 9.0, 1.4, 3.0)
	lm.box("Stone", Vector3(0, 4.8, 34.0), Vector3(26.0, 9.6, 6.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 37.0), Vector3.RIGHT, Vector3(0, 0, 1), 0.0, 5, 4.8, 3.6, 6.4)
	lm.box("Trim", Vector3(0, 9.9, 34.0), Vector3(27.0, 0.6, 7.0))
	lm.box("Trim", Vector3(0, 10.8, 36.6), Vector3(26.0, 1.2, 0.5))
	for i in 4:
		LandmarkKits.statue_figure(lm, "Trim", Vector3(-9.6 + 6.4 * float(i), 11.4, 36.6), 3.0)
	# Brick campanile with white cornice bands and a tiled spire.
	var tiers := PackedVector2Array([Vector2(9.0, 3.7), Vector2(3.8, 3.6), Vector2(3.8, 3.5),
		Vector2(3.8, 3.4), Vector2(3.4, 3.3)])
	LandmarkRmLUtil.tower(lm, "Brick", Vector3(20.5, 0, 19.0), tiers, 29.7, "Tile")
	SEuUtil.finial(lm, "Gold", Vector3(20.5, 29.7, 19.0), 1.3)
	lm.commit(model)
