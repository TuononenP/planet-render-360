class_name FtQwenselHouse
extends RefCounted

## Qwensel House & Pharmacy Museum (Qwenselin talo ja Apteekkimuseo, ~1700):
## Turku's oldest surviving wooden bourgeois manor on Läntinen Rantakatu 13
## beside City Hall (+X ENE along river, +Z SE toward Aurajoki, yaw_deg =
## -29.4°, height_m = 9.0):
##   - Pre-Great-Fire Finnish punamulta (deep red-ochre #7E231D) vertical
##     timber main manor (22 x 11 m, rough fieldstone granite plinth, steep
##     terracotta-tiled hipped roof to 8.9 m, twin brick chimneys, pale grey-
##     white 6-pane windows with paired hinged shutters & timber entry stoop).
##   - Red-ochre timber courtyard outbuildings (Pharmacy wing & carriage barn,
##     dark slate roofs) enclosing the cobbled inner courtyard (-Z) & fence.
## Surfaces: 9 merged PBR parts (TimberWall, Trim, Stone, TileRoof, Roof,
## Brick, Cobble, Glass, Lamp).

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("TimberWall", LandmarkMaterials.pbr("wood", "#7E231D", 2.2, 0.80))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#D8DEE2", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7A7670", 2.4))
	lm.use("TileRoof", LandmarkMaterials.pbr("terracotta", "#A45238", 2.2))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#35383B", 2.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8B4230", 2.2))
	lm.use("Cobble", LandmarkMaterials.pbr("pavement", "#78746D", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#20282E"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B4", 1.3))

	# Main ~1700 punamulta red timber manor facing Aurajoki (+Z, 22 x 11 m, eaves 4.65 m, roof 8.9 m).
	LandmarkFrKit.rect(lm, "Stone", -11.3, 11.3, -2.3, 8.8, FOUND, 1.15)
	LandmarkFrKit.rect(lm, "TimberWall", -11.0, 11.0, -2.0, 8.5, 1.15, 4.65)
	# Corner red timber vertical corner boards & eaves fascia.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("TimberWall", Vector3(sx * 10.95, 2.9, sz * 5.25 + 3.25), Vector3(0.32, 3.55, 0.32))
	LandmarkFrParts.cornice_ring(lm, "TimberWall", -11.0, 11.0, -2.0, 8.5, 4.35, 0.32)
	# Steep weathered terracotta-tile hipped roof (4.65 -> 8.9 m) + twin brick chimneys.
	LandmarkFrKit.hip(lm, "TileRoof", -11.0, 11.0, -2.0, 8.5, 4.65, 3.2, 0.45)
	LandmarkFrKit.hip(lm, "TileRoof", -9.2, 9.2, -0.4, 6.9, 6.75, 2.15, 0.25)
	for cx: float in [-4.5, 4.5]:
		LandmarkFrKit.rect(lm, "Brick", cx - 0.55, cx + 0.55, 2.7, 3.8, 7.6, 9.05)
		LandmarkFrKit.rect(lm, "Trim", cx - 0.65, cx + 0.65, 2.6, 3.9, 8.95, 9.12)
	# Historic riverside windows (+Z) with pale grey-white frames & paired hinged shutters.
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.2, 1.75, 8.5), Vector3(9.2, 1.75, 8.5),
		Vector3.BACK, 6, 1.2, 1.95, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
	for i in 6:
		var wx := lerpf(-9.2, 9.2, (float(i) + 0.5) / 6.0)
		for side: float in [-1.0, 1.0]:
			lm.box("Trim", Vector3(wx + side * 0.96, 2.72, 8.58), Vector3(0.56, 1.92, 0.08))
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-9.2, 1.75, -2.0), Vector3(9.2, 1.75, -2.0),
		Vector3.FORWARD, 6, 1.15, 1.85, LandmarkFrParts.HEAD_FLAT, 0.14, 0.10, 1)
	# Timber-railed entrance stoop on the riverside front (+Z).
	LandmarkFrKit.rect(lm, "Stone", -2.2, 2.2, 8.5, 9.8, FOUND, 1.05)
	LandmarkFrKit.rect(lm, "Stone", -2.5, 2.5, 9.8, 10.6, FOUND, 0.52)
	for sx: float in [-2.1, 2.1]:
		lm.beam("Trim", Vector3(sx, 2.1, 8.6), Vector3(sx, 1.45, 10.5), 0.10, 0.10)
		lm.box("Trim", Vector3(sx, 1.55, 8.6), Vector3(0.12, 1.15, 0.12))
		lm.box("Trim", Vector3(sx, 0.98, 10.5), Vector3(0.12, 1.0, 0.12))
	# Courtyard cobbles & flanking 18th-century wooden Pharmacy & carriage outbuildings (-Z).
	LandmarkFrKit.rect(lm, "Cobble", -11.5, 11.5, -18.5, -2.0, -1.0, 0.10)
	# West Pharmacy wing (-X, x = -14.5..-8.5, z = -18.5..-2.0).
	LandmarkFrKit.rect(lm, "Stone", -14.6, -8.4, -18.6, -2.0, FOUND, 0.75)
	LandmarkFrKit.rect(lm, "TimberWall", -14.4, -8.6, -18.4, -2.0, 0.75, 3.85)
	LandmarkFrKit.gable(lm, "Roof", -14.4, -8.6, -18.4, -2.0, 3.85, 2.45, 0.35, "TimberWall", 0)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-8.6, 1.35, -16.5), Vector3(-8.6, 1.35, -4.0),
		Vector3.RIGHT, 5, 1.05, 1.6, LandmarkFrParts.HEAD_FLAT, 0.14, 0.10, 1)
	# Rear timber carriage barn (-Z, x = -14.4..10.5, z = -23.5..-18.0).
	LandmarkFrKit.rect(lm, "Stone", -14.5, 10.6, -23.6, -17.9, FOUND, 0.65)
	LandmarkFrKit.rect(lm, "TimberWall", -14.3, 10.4, -23.4, -18.0, 0.65, 3.55)
	LandmarkFrKit.gable(lm, "Roof", -14.3, 10.4, -23.4, -18.0, 3.55, 2.2, 0.35, "TimberWall", 1)
	# Historic wooden courtyard fence & lantern along east side (+X).
	LandmarkFrKit.rect(lm, "TimberWall", 10.1, 10.5, -18.0, -2.0, 0.0, 2.3)
	lm.box("Trim", Vector3(0.0, 3.2, 8.75), Vector3(0.24, 0.34, 0.34))
	lm.box("Lamp", Vector3(0.0, 3.1, 8.88), Vector3(0.18, 0.26, 0.18))
	lm.frustum("Stone", Vector3(2.0, 0.10, -10.0), 0.14, 0.08, 3.0, 6)
	lm.lathe("Lamp", Vector3(2.0, 3.1, -10.0), LandmarkFrKit.ball(0.16), 6)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.2, 15.0), Vector3(0.0, 4.5, 8.5), 62.0, 0.75, 26.0, Color(1.0, 0.86, 0.62)],
		[Vector3(0.0, 1.2, -10.0), Vector3(-9.0, 3.0, -10.0), 65.0, 0.60, 22.0, Color(1.0, 0.86, 0.62)],
	])
