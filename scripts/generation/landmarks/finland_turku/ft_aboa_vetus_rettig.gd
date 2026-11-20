class_name FtAboaVetusRettig
extends RefCounted

## Aboa Vetus Ars Nova / Rettig Palace (Rettigin palatsi, 1928, Valter &
## Bertel Jung): baroque-classicist walled villa-palace on Itäinen Rantakatu
## (+X ENE along river, -Z NNW facing Aurajoki, turned by yaw_deg = -33.0°,
## height_m = 19.5):
##   - High granite-and-plaster street wall along Itäinen Rantakatu (-Z) with
##     rusticated stone piers, grand wrought-iron gates & lanterns opening into
##     the gravel/cobble honour court (cour d'honneur).
##   - Symmetrical U-plan pale-plaster baroque-classicist palace (38 x 24 m,
##     eaves 12.2 m, steep 2-tier dark copper/slate mansard roof to 19.4 m)
##     with central pedimented portico, oval oculus, corner pavilions & dormers.
##   - Contemporary glazed museum entrance wing flanking the courtyard (+X).
## Surfaces: 9 merged PBR parts (Plaster, Trim, Stone, Roof, Copper, Iron,
## Cobble, Glass, Lamp).

const FOUND := -2.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E6DFCE", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F1E8", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#86827B", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#373C41", 2.2))
	lm.use("Copper", LandmarkFrKit.copper("#4E7A68"))
	lm.use("Iron", LandmarkMaterials.paint("#23272B", 0.45, 0.65))
	lm.use("Cobble", LandmarkMaterials.pbr("pavement", "#7B7770", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#24333C"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BA", 1.4))

	# Honour court cobble terrace & high street wall along Itäinen Rantakatu (-Z = -21).
	LandmarkFrKit.rect(lm, "Cobble", -22.5, 22.5, -21.0, 2.0, -1.2, 0.12)
	LandmarkFrKit.rect(lm, "Stone", -23.0, -4.5, -21.6, -20.6, FOUND, 1.35)
	LandmarkFrKit.rect(lm, "Plaster", -22.8, -4.7, -21.4, -20.8, 1.35, 3.6)
	LandmarkFrKit.rect(lm, "Trim", -23.0, -4.5, -21.5, -20.7, 3.55, 3.85)
	LandmarkFrKit.rect(lm, "Stone", 4.5, 23.0, -21.6, -20.6, FOUND, 1.35)
	LandmarkFrKit.rect(lm, "Plaster", 4.7, 22.8, -21.4, -20.8, 1.35, 3.6)
	LandmarkFrKit.rect(lm, "Trim", 4.5, 23.0, -21.5, -20.7, 3.55, 3.85)
	# Grand rusticated gate piers, urn finials, wrought-iron gates & lanterns.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Stone", sx * 4.5 - 0.85, sx * 4.5 + 0.85, -22.0, -20.2, FOUND, 4.6)
		LandmarkFrKit.rect(lm, "Trim", sx * 4.5 - 1.0, sx * 4.5 + 1.0, -22.15, -20.05, 4.5, 4.85)
		lm.lathe("Lamp", Vector3(sx * 4.5, 4.85, -21.1), LandmarkFrKit.ball(0.28), 8)
	lm.box("Iron", Vector3(0.0, 3.35, -21.1), Vector3(7.4, 0.12, 0.12))
	lm.box("Iron", Vector3(0.0, 1.25, -21.1), Vector3(7.4, 0.12, 0.12))
	for k in 15:
		var gx := lerpf(-3.5, 3.5, float(k) / 14.0)
		lm.box("Iron", Vector3(gx, 1.9, -21.1), Vector3(0.06, 3.2, 0.06))
	# Main Baroque-Classicist Palace (38 x 16 m, z = 2..18, eaves 12.2 m, mansard to 19.4 m).
	LandmarkFrKit.rect(lm, "Stone", -19.4, 19.4, 1.6, 18.4, FOUND, 2.2)
	LandmarkFrKit.rect(lm, "Plaster", -19.0, 19.0, 2.0, 18.0, 2.2, 12.2)
	LandmarkFrParts.band(lm, "Trim", -19.0, 19.0, 2.0, 18.0, 6.8, 0.36, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -19.0, 19.0, 2.0, 18.0, 11.6, 0.62)
	# Steep 2-tier Baroque mansard roof (12.2 -> 16.4 -> 19.4 m) with copper ridge & dormers.
	LandmarkFrKit.hip(lm, "Roof", -19.0, 19.0, 2.0, 18.0, 12.2, 5.2, 0.55)
	LandmarkFrKit.hip(lm, "Roof", -15.2, 15.2, 4.6, 15.4, 15.8, 3.6, 0.30)
	lm.beam("Copper", Vector3(-11.0, 19.42, 10.0), Vector3(11.0, 19.42, 10.0), 0.20, 0.24)
	for dx: float in [-11.5, -5.8, 5.8, 11.5]:
		LandmarkFrKit.rect(lm, "Trim", dx - 1.0, dx + 1.0, 2.3, 4.0, 12.4, 14.7)
		LandmarkFrKit.hip(lm, "Copper", dx - 1.1, dx + 1.1, 2.2, 4.1, 14.7, 1.1, 0.2)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(dx, 12.7, 2.3), Vector3.FORWARD, 1.1, 1.65,
			LandmarkFrParts.HEAD_ROUND, 0.12, 0.10, 1)
	# Central projecting portico with stone steps, paired columns & pediment (-Z honour court).
	LandmarkFrKit.rect(lm, "Stone", -5.8, 5.8, -0.4, 2.2, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Plaster", -5.4, 5.4, 0.6, 2.2, 1.8, 12.4)
	for cx: float in [-4.2, -1.6, 1.6, 4.2]:
		lm.frustum("Trim", Vector3(cx, 1.8, 0.45), 0.36, 0.32, 9.8, 10)
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 12.4, 0.45), Vector3.RIGHT, Vector3.FORWARD, 11.2, 2.6, 0.55)
	# Tall Baroque-Classicist windows across the 9-bay palace facade (-Z).
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 7.2, 2.9, 2.0), Vector3(sx * 17.2, 2.9, 2.0),
			Vector3.FORWARD, 3, 1.45, 2.8, LandmarkFrParts.HEAD_ROUND, 0.18, 0.14, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 7.2, 7.6, 2.0), Vector3(sx * 17.2, 7.6, 2.0),
			Vector3.FORWARD, 3, 1.45, 3.0, LandmarkFrParts.HEAD_FLAT, 0.18, 0.14, 1)
	# Flanking courtyard wings (-X historic gallery wing, +X modern glazed museum entrance wing).
	LandmarkFrKit.rect(lm, "Stone", -22.5, -13.5, -14.0, 2.2, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Plaster", -22.2, -13.8, -13.8, 2.2, 1.8, 8.6)
	LandmarkFrKit.hip(lm, "Roof", -22.2, -13.8, -13.8, 2.2, 8.6, 3.6, 0.40)
	LandmarkFrKit.rect(lm, "Stone", 13.5, 22.5, -14.0, 2.2, FOUND, 0.6)
	LandmarkFrKit.rect(lm, "Glass", 13.7, 22.2, -13.8, 2.0, 0.6, 6.2)
	LandmarkFrKit.rect(lm, "Copper", 13.4, 22.6, -14.2, 2.3, 6.2, 6.9)
	LandmarkFrKit.rect(lm, "Lamp", 14.8, 21.0, -12.5, 0.8, 1.0, 5.4)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, -12.0), Vector3(0.0, 9.0, 1.0), 58.0, 0.90, 42.0, Color(1.0, 0.88, 0.66)],
		[Vector3(-12.0, 1.5, -10.0), Vector3(-13.0, 8.0, 2.0), 54.0, 0.70, 36.0, Color(1.0, 0.88, 0.66)],
		[Vector3(12.0, 1.5, -10.0), Vector3(13.0, 8.0, 2.0), 54.0, 0.70, 36.0, Color(1.0, 0.88, 0.66)],
	])
