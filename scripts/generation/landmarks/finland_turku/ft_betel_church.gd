class_name FtBetelChurch
extends RefCounted

## Betel Church (Betel-kirkko, Frithiof Strandell, 1906) off Yliopistonkatu 29a.
## Origin at OSM way:28190211 centroid (60.451191 N, 22.261149 E), yaw_deg -35.6.
##
## Architectural & facade spec:
## - Footprint 33.5 x 22.7 m, tower spire peaking at 30.7 m (matching LoD2 30.7 m).
## - Rough grey-granite plinth (y = -1.8..2.2 m), whitewashed Jugendstil
##   castle-like nave with buttressed flanks & arched nave windows.
## - Steep terracotta-tile gable roof (ridge 18.5 m) with stepped/curved Jugend
##   end gables and rose/lancet window compositions.
## - Asymmetric square corner bell tower (+X/-Z) with tall belfry lancets,
##   flared dark-copper/slate spire and gilt finial cross reaching 30.7 m.
## - Arched stone-and-plaster entrance arcade approaching from Yliopistonkatu.

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#848078", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFECE2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#DAD4C6", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4832", 2.2))
	lm.use("Copper", LandmarkFrKit.copper("#3C564E"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.9))
	lm.use("Gilt", LandmarkMaterials.gold())

	# Granite plinth & whitewashed nave (26.0 x 16.4 m, eaves 11.4 m).
	LandmarkFrKit.rect(lm, "Granite", -13.4, 13.4, -8.5, 8.5, FOUND, 2.2)
	LandmarkFrKit.rect(lm, "Wall", -13.0, 13.0, -8.2, 8.2, 2.2, 11.4)
	LandmarkFrKit.rect(lm, "Trim", -13.2, 13.2, -8.4, 8.4, 11.2, 11.65)
	# Steep red-tile nave roof (ridge at 18.6 m).
	LandmarkFrKit.gable(lm, "Tile", (0.0) - (26.8) * 0.5, (0.0) + (26.8) * 0.5, (0.0) - (17.0) * 0.5, (0.0) + (17.0) * 0.5, 11.4, 7.2, 0.0, "", 1)
	# Stepped Jugend gable parapets at -X and +X ends.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Wall", sx * 13.0 - 0.45, sx * 13.0 + 0.45, -8.3, 8.3, 11.2, 13.4)
		LandmarkFrKit.rect(lm, "Wall", sx * 13.0 - 0.45, sx * 13.0 + 0.45, -5.2, 5.2, 13.4, 16.4)
		LandmarkFrKit.rect(lm, "Wall", sx * 13.0 - 0.45, sx * 13.0 + 0.45, -2.4, 2.4, 16.4, 19.2)
		LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(sx * 13.46, 5.2, 0.0), Vector3(sx, 0, 0),
			3.2, 5.4, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 2)

	# Side nave buttresses & 5 arched clerestory windows on both flanks.
	for i in 5:
		var x := lerpf(-9.2, 9.2, float(i) / 4.0)
		for sz: float in [-1.0, 1.0]:
			LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(x, 4.4, sz * 8.22), Vector3(0, 0, sz),
				1.8, 4.6, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	for i in 6:
		var bx := lerpf(-11.6, 11.6, float(i) / 5.0)
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Granite", bx - 0.45, bx + 0.45, sz * 8.2, sz * 8.95, FOUND, 3.4)
			LandmarkFrKit.rect(lm, "Wall", bx - 0.38, bx + 0.38, sz * 8.2, sz * 8.75, 3.4, 10.6)

	# Asymmetric square bell tower (+X = 11.8, -Z = -7.6, width 6.4 m, spire to 30.7 m).
	var tx := 11.8
	var tz := -7.6
	LandmarkFrKit.rect(lm, "Granite", tx - 3.4, tx + 3.4, tz - 3.4, tz + 3.4, FOUND, 2.8)
	LandmarkFrKit.rect(lm, "Wall", tx - 3.2, tx + 3.2, tz - 3.2, tz + 3.2, 2.8, 20.6)
	LandmarkFrKit.rect(lm, "Trim", tx - 3.45, tx + 3.45, tz - 3.45, tz + 3.45, 20.3, 20.9)
	# Belfry twin arched openings on all 4 faces.
	for d in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var n: Vector3 = d
		var side := Vector3(-n.z, 0.0, n.x)
		for s: float in [-1.1, 1.1]:
			LandmarkFrParts.opening(lm, "Trim", "WarmGlow",
				Vector3(tx, 15.8, tz) + n * 3.22 + side * s, n,
				1.15, 3.2, LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 1)
	# Flared dark-copper Jugend spire (y = 20.9..29.5 m) + gilt cross to 30.7 m.
	lm.lathe("Copper", Vector3(tx, 20.9, tz), PackedVector2Array([
		Vector2(4.2, 0.0), Vector2(3.1, 1.8), Vector2(2.1, 4.4), Vector2(0.95, 7.2), Vector2(0.16, 8.6),
	]), 4, 1.0, 1.0, PI * 0.25, false)
	lm.frustum("Gilt", Vector3(tx, 29.4, tz), 0.10, 0.06, 1.3, 8)
	lm.box("Gilt", Vector3(tx, 30.25, tz), Vector3(0.85, 0.12, 0.12), Basis(), 0.0)

	# Arched Yliopistonkatu entrance porch (+Z wing).
	LandmarkFrKit.rect(lm, "Granite", -4.6, 4.6, 8.2, 11.4, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Wall", -4.4, 4.4, 8.2, 11.2, 1.8, 7.6)
	LandmarkFrKit.gable(lm, "Tile", (0.0) - (9.2) * 0.5, (0.0) + (9.2) * 0.5, (9.7) - (3.4) * 0.5, (9.7) + (3.4) * 0.5, 7.6, 2.6, 0.0, "", 0)
	LandmarkFrParts.opening(lm, "Granite", "WarmGlow", Vector3(0.0, 1.8, 11.22), Vector3(0, 0, 1),
		2.8, 4.0, LandmarkFrParts.HEAD_ROUND, 0.30, 0.18, 2)
	lm.commit(model)

	var warm := Color(1.0, 0.91, 0.75)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.5, 1.0, -13.0), Vector3(11.8, 18.0, -7.6), 34.0, 1.05, 55.0, warm],
		[Vector3(0.0, 0.8, 15.5), Vector3(0.0, 7.0, 9.0), 26.0, 0.9, 55.0, warm],
		[Vector3(-17.5, 1.0, 0.0), Vector3(-12.0, 9.0, 0.0), 24.0, 0.8, 55.0, warm],
	])
