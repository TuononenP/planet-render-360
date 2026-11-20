class_name FtMaariaChurch
extends RefCounted

## Maaria Church (Maarian kirkko, 15th c.) in Räntämäki, Turku.
## Origin at 60.473350 N, 22.293100 E, yaw_deg 10.0.
##
## Architectural & facade spec:
## - Medieval grey-fieldstone parish church (32.0 x 16.0 m), towering 59°
##   steep dark-shingle saddle roof rising to 24.3 m (matching LoD2 24.3 m).
## - Ornate red-brick west & east gables featuring Maaria's famous whitewashed
##   blind star, cross & stepped lancet niches.
## - Medieval south weapon-house porch, north sacristy, and fieldstone
##   churchyard gatehouse with shingled hipped roof.

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Fieldstone", LandmarkMaterials.pbr("stone", "#7C7870", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#964632", 2.2))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFECE2", 2.0))
	lm.use("Shingle", LandmarkMaterials.pbr("slate", "#2C2926", 2.5))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.9))
	lm.use("Gilt", LandmarkMaterials.gold())

	# Medieval fieldstone nave (32.0 x 15.6 m, eaves 10.2 m).
	LandmarkFrKit.rect(lm, "Fieldstone", -16.2, 16.2, -8.0, 8.0, FOUND, 10.2)
	# Steep 59° dark shingled saddle roof rising from 10.2 m to 23.2 m.
	LandmarkFrKit.gable(lm, "Shingle", (0.0) - (32.8) * 0.5, (0.0) + (32.8) * 0.5, (0.0) - (16.6) * 0.5, (0.0) + (16.6) * 0.5, 10.2, 13.0, 0.0, "", 1)

	# Ornate red-brick gable walls with rich whitewashed blind cross & stepped lancets.
	for sx: float in [-1.0, 1.0]:
		var gx := sx * 16.05
		LandmarkFrKit.gable(lm, "Brick", (gx) - (0.80) * 0.5, (gx) + (0.80) * 0.5, (0.0) - (15.8) * 0.5, (0.0) + (15.8) * 0.5, 10.2, 12.9, 0.0, "", 1)
		lm.box("Plaster", Vector3(gx + sx * 0.42, 16.8, 0.0), Vector3(0.08, 5.2, 0.85), Basis(), 0.0)
		lm.box("Plaster", Vector3(gx + sx * 0.42, 17.6, 0.0), Vector3(0.08, 0.78, 3.4), Basis(), 0.0)
		for oz: float in [-4.0, -2.0, 2.0, 4.0]:
			var h := 3.8 if absf(oz) < 3.0 else 2.4
			lm.box("Plaster", Vector3(gx + sx * 0.42, 12.2 + h * 0.4, oz), Vector3(0.08, h, 0.72), Basis(), 0.0)
		# Peak cross reaching 24.3 m.
		lm.frustum("Gilt", Vector3(gx, 23.1, 0.0), 0.07, 0.05, 1.2, 6)
		lm.box("Gilt", Vector3(gx, 23.85, 0.0), Vector3(0.09, 0.09, 0.65), Basis(), 0.0)

	# Pointed medieval nave windows.
	for i in 4:
		var wx := lerpf(-11.0, 11.0, float(i) / 3.0)
		for sz: float in [-1.0, 1.0]:
			if sz > 0.0 and absf(wx + 6.0) < 3.4:
				continue
			if sz < 0.0 and absf(wx - 7.0) < 3.8:
				continue
			LandmarkFrParts.opening(lm, "Brick", "WarmGlow", Vector3(wx, 3.2, sz * 8.02), Vector3(0, 0, sz),
				1.75, 4.8, LandmarkFrParts.HEAD_POINTED, 0.26, 0.14, 1)

	# South porch (+Z at x = -6.0) & north vaulted sacristy (-Z at x = 7.0).
	LandmarkFrKit.rect(lm, "Fieldstone", -9.4, -2.6, 7.8, 12.8, FOUND, 6.0)
	LandmarkFrKit.gable(lm, "Shingle", (-6.0) - (7.2) * 0.5, (-6.0) + (7.2) * 0.5, (10.3) - (5.4) * 0.5, (10.3) + (5.4) * 0.5, 6.0, 4.2, 0.0, "", 0)
	LandmarkFrParts.opening(lm, "Brick", "WarmGlow", Vector3(-6.0, 0.2, 12.82), Vector3(0, 0, 1),
		2.2, 3.5, LandmarkFrParts.HEAD_ROUND, 0.26, 0.14, 1)
	LandmarkFrKit.rect(lm, "Fieldstone", 3.0, 11.0, -13.0, -7.8, FOUND, 6.2)
	LandmarkFrKit.gable(lm, "Shingle", (7.0) - (8.4) * 0.5, (7.0) + (8.4) * 0.5, (-10.4) - (5.6) * 0.5, (-10.4) + (5.6) * 0.5, 6.2, 4.4, 0.0, "", 0)

	# Medieval fieldstone churchyard gatehouse (+Z = 18.5, -X = -14.0).
	LandmarkFrKit.rect(lm, "Fieldstone", -17.5, -10.5, 16.5, 20.5, FOUND, 4.0)
	LandmarkFrKit.hip(lm, "Shingle", (-14.0) - (7.6) * 0.5, (-14.0) + (7.6) * 0.5, (18.5) - (4.6) * 0.5, (18.5) + (4.6) * 0.5, 4.0, 2.8, 0.0)
	LandmarkFrParts.opening(lm, "Brick", "WarmGlow", Vector3(-14.0, 0.1, 20.52), Vector3(0, 0, 1),
		2.4, 3.0, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 0.8, 0.0), Vector3(-16.0, 14.0, 0.0), 32.0, 0.95, 55.0, warm],
		[Vector3(22.0, 0.8, 0.0), Vector3(16.0, 14.0, 0.0), 32.0, 0.9, 55.0, warm],
		[Vector3(0.0, 0.8, 17.5), Vector3(0.0, 8.0, 8.0), 28.0, 0.85, 60.0, warm],
	])
