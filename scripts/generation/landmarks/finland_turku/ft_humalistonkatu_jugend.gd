class_name FtHumalistonkatuJugend
extends RefCounted

## Humalistonkatu Jugend Row — signature National Romantic / Art Nouveau
## stone-and-plaster apartment palaces along Humalistonkatu leading toward
## Turku Central Railway Station.
## Origin at 60.451750 N, 22.259150 E, yaw_deg 55.0.
##
## Architectural & facade spec:
## - Joined 58.0 x 20.0 m streetfront block, peak turret 22.0 m.
## - West palace (warm ochre-sand plaster + rough granite plinth + corner turret
##   with green-copper cap) and East palace (terracotta-tinted plaster + stepped
##   curved Jugend gable + arched stone portal).
## - Steep red-tile and dark-metal roofs with dormers and masonry chimneys.

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#827E78", 2.5))
	lm.use("WallA", LandmarkMaterials.pbr("render", "#D8C6A2", 3.0))
	lm.use("WallB", LandmarkMaterials.pbr("render", "#CEB49A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0E8DA", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#924632", 2.2))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3B4046", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#487262"))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A2", 0.8))

	# West Jugend palace (x = -29..0, z = -10..10, eaves 16.8 m).
	LandmarkFrKit.rect(lm, "Granite", -29.2, 0.2, -10.2, 10.2, FOUND, 3.6)
	LandmarkFrKit.rect(lm, "WallA", -29.0, 0.0, -10.0, 10.0, 3.6, 16.8)
	LandmarkFrKit.rect(lm, "Trim", -29.2, 0.1, -10.2, 10.2, 16.55, 17.05)
	LandmarkFrKit.hip(lm, "Tile", (-14.5) - (29.6) * 0.5, (-14.5) + (29.6) * 0.5, (0.0) - (20.6) * 0.5, (0.0) + (20.6) * 0.5, 17.05, 4.2, 0.0)

	# East Jugend palace (x = 0..29, z = -9.6..9.6, eaves 16.2 m).
	LandmarkFrKit.rect(lm, "Granite", -0.2, 29.2, -9.8, 9.8, FOUND, 3.5)
	LandmarkFrKit.rect(lm, "WallB", 0.0, 29.0, -9.6, 9.6, 3.5, 16.2)
	LandmarkFrKit.rect(lm, "Trim", -0.1, 29.2, -9.8, 9.8, 15.95, 16.45)
	LandmarkFrKit.hip(lm, "Roof", (14.5) - (29.6) * 0.5, (14.5) + (29.6) * 0.5, (0.0) - (19.8) * 0.5, (0.0) + (19.8) * 0.5, 16.45, 4.0, 0.0)

	# Corner turret (-28.6, 9.6) with copper cap reaching 22.0 m.
	lm.frustum("Granite", Vector3(-28.6, FOUND, 9.6), 2.8, 2.75, 3.7 - FOUND, 16)
	lm.frustum("WallA", Vector3(-28.6, 3.7, 9.6), 2.65, 2.65, 14.3, 16)
	lm.lathe("Copper", Vector3(-28.6, 18.0, 9.6), PackedVector2Array([
		Vector2(2.85, 0.0), Vector2(2.0, 1.5), Vector2(0.9, 3.0), Vector2(0.12, 4.0),
	]), 16, 1.0, 1.0, 0.0, false)

	# Asymmetric projecting gables on street front (+Z).
	for gx: float in [-14.0, 14.5]:
		var wm := "WallA" if gx < 0.0 else "WallB"
		LandmarkFrKit.rect(lm, wm, gx - 3.6, gx + 3.6, 9.5, 11.0, 3.6, 17.6)
		LandmarkFrKit.gable(lm, "Tile" if gx < 0.0 else "Roof", (gx) - (7.6) * 0.5, (gx) + (7.6) * 0.5, (10.1) - (2.4) * 0.5, (10.1) + (2.4) * 0.5, 17.6, 3.2, 0.0, "", 0)
		LandmarkFrParts.opening(lm, "Granite", "WarmGlow", Vector3(gx, 0.2, 10.22), Vector3(0, 0, 1),
			2.6, 3.0, LandmarkFrParts.HEAD_ROUND, 0.26, 0.16, 2)

	# Rhythmic windows along both street and courtyard facades.
	for i in 14:
		var x := lerpf(-24.5, 25.5, float(i) / 13.0)
		var fz := 11.02 if (absf(x + 14.0) < 3.2 or absf(x - 14.5) < 3.2) else (10.02 if x < 0.0 else 9.62)
		var bz := -10.02 if x < 0.0 else -9.62
		for fl in 4:
			var wy := 4.5 + float(fl) * 3.0
			var g := "WarmGlow" if ((i + fl) % 4 == 0) else "Glass"
			LandmarkFrParts.opening(lm, "Trim", g, Vector3(x, wy, fz), Vector3(0, 0, 1),
				1.35, 1.95, LandmarkFrParts.HEAD_FLAT, 0.15, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, wy, bz), Vector3(0, 0, -1),
				1.35, 1.95, LandmarkFrParts.HEAD_FLAT, 0.15, 0.10, 1)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-28.0, 1.0, 15.5), Vector3(-28.6, 14.0, 9.6), 28.0, 0.85, 55.0, warm],
		[Vector3(14.5, 1.0, 15.5), Vector3(14.5, 12.0, 10.0), 28.0, 0.8, 55.0, warm],
	])
