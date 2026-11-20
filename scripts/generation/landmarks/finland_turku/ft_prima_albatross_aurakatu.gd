class_name FtPrimaAlbatrossAurakatu
extends RefCounted

## Aurakatu Jugend Palaces — Albatross (Frithiof Strandell, 1910) & Prima
## climbing Aurakatu 14-16 toward Puolalanmäki and the Turku Art Museum.
## Origin at 60.453550 N, 22.262750 E, yaw_deg -35.0.
##
## Architectural & facade spec:
## - Footprint 46.0 x 26.0 m, corner turret peaking at 24.6 m (matching LoD2 24.6 m).
## - Heavy rusticated grey-granite plinth (y = -2.2..3.6 m) with arched
##   National Romantic granite entrance portals & shopfront arches.
## - Warm sand/cream Jugendstil rendered upper storeys (5 floors, eaves 18.0 m)
##   with asymmetric projecting bay oriels, string courses & curved gables.
## - Prominent cylindrical corner bay tower (+X/+Z) crowned by a patinated
##   copper conical turret roof peaking at 24.6 m.
## - Steep hipped dark-metal roof with dormers and rendered chimneys.

const FOUND := -2.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86817A", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DCCBA8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0E8D8", 2.2))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3C4248", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#487262"))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A4", 0.8))

	# Rusticated granite ground floor + 4 rendered upper storeys (44 x 24 m).
	LandmarkFrKit.rect(lm, "Granite", -22.2, 22.2, -12.2, 12.2, FOUND, 3.8)
	LandmarkFrKit.rect(lm, "Trim", -22.4, 22.4, -12.4, 12.4, 3.65, 4.05)
	LandmarkFrKit.rect(lm, "Wall", -22.0, 22.0, -12.0, 12.0, 4.05, 18.0)
	LandmarkFrKit.rect(lm, "Trim", -22.35, 22.35, -12.35, 12.35, 17.75, 18.3)
	LandmarkFrKit.hip(lm, "Roof", (0.0) - (44.8) * 0.5, (0.0) + (44.8) * 0.5, (0.0) - (24.8) * 0.5, (0.0) + (24.8) * 0.5, 18.3, 4.6, 0.0)

	# Projecting asymmetric Jugend bay oriels + curved gable crowns on street front (+Z).
	for bx: float in [-13.5, 0.5, 13.0]:
		LandmarkFrKit.rect(lm, "Wall", bx - 3.0, bx + 3.0, 11.8, 13.4, 4.2, 18.4)
		LandmarkFrKit.rect(lm, "Trim", bx - 3.15, bx + 3.15, 11.8, 13.55, 18.1, 18.55)
		LandmarkFrKit.gable(lm, "Roof", (bx) - (6.4) * 0.5, (bx) + (6.4) * 0.5, (12.5) - (2.4) * 0.5, (12.5) + (2.4) * 0.5, 18.55, 3.2, 0.0, "", 0)
		LandmarkFrKit.rect(lm, "Wall", bx - 2.4, bx + 2.4, 13.2, 13.55, 18.55, 20.6)

	# Cylindrical corner bay tower (+X = 21.8, +Z = 11.8) with copper turret to 24.6 m.
	var tx := 21.8
	var tz := 11.8
	lm.frustum("Granite", Vector3(tx, FOUND, tz), 3.4, 3.35, 3.9 - FOUND, 20)
	lm.frustum("Wall", Vector3(tx, 3.9, tz), 3.25, 3.25, 15.6, 20)
	lm.frustum("Trim", Vector3(tx, 19.3, tz), 3.45, 3.50, 0.40, 20)
	lm.lathe("Copper", Vector3(tx, 19.7, tz), PackedVector2Array([
		Vector2(3.55, 0.0), Vector2(2.6, 1.5), Vector2(1.4, 3.2), Vector2(0.15, 4.9),
	]), 20, 1.0, 1.0, 0.0, false)

	# Street-level arched granite portals & rhythmic upper casement windows.
	for i in 10:
		var x := lerpf(-18.5, 17.5, float(i) / 9.0)
		var front_z := 13.42 if (absf(x + 13.5) < 2.8 or absf(x - 0.5) < 2.8 or absf(x - 13.0) < 2.8) else 12.02
		if i % 3 == 1:
			LandmarkFrParts.opening(lm, "Granite", "WarmGlow", Vector3(x, 0.3, 12.22), Vector3(0, 0, 1),
				2.6, 3.0, LandmarkFrParts.HEAD_ROUND, 0.26, 0.16, 2)
		for fl in 4:
			var wy := 5.0 + float(fl) * 3.25
			var glass_mat := "WarmGlow" if ((i + fl) % 3 == 0) else "Glass"
			LandmarkFrParts.opening(lm, "Trim", glass_mat, Vector3(x, wy, front_z), Vector3(0, 0, 1),
				1.45, 2.05, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, wy, -12.02), Vector3(0, 0, -1),
				1.45, 2.05, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
	for i in 5:
		var z := lerpf(-8.5, 8.5, float(i) / 4.0)
		for fl in 4:
			var wy := 5.0 + float(fl) * 3.25
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-22.02, wy, z), Vector3(-1, 0, 0),
				1.45, 2.05, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(22.02, wy, z), Vector3(1, 0, 0),
				1.45, 2.05, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)

	# Roof dormers & rendered chimneys.
	for dx: float in [-14.0, -5.0, 5.0, 14.0]:
		LandmarkFrKit.rect(lm, "Wall", dx - 1.1, dx + 1.1, 8.2, 10.6, 18.3, 20.6)
		LandmarkFrKit.gable(lm, "Roof", (dx) - (2.5) * 0.5, (dx) + (2.5) * 0.5, (9.4) - (2.6) * 0.5, (9.4) + (2.6) * 0.5, 20.6, 1.0, 0.0, "", 0)
	for cx: float in [-12.0, 0.0, 12.0]:
		LandmarkFrKit.rect(lm, "Wall", cx - 0.7, cx + 0.7, -1.2, 1.2, 21.5, 24.0)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(26.0, 1.0, 17.0), Vector3(21.8, 16.0, 11.8), 30.0, 0.9, 55.0, warm],
		[Vector3(0.0, 1.0, 18.0), Vector3(0.0, 12.0, 12.0), 28.0, 0.8, 60.0, warm],
	])
