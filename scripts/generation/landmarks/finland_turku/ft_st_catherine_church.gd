class_name FtStCatherineChurch
extends RefCounted

## St. Catherine's Church (Pyhän Katariinan kirkko, 14th c.) in Nummi, Turku.
## Origin at 60.462250 N, 22.293450 E, yaw_deg 5.0.
##
## Architectural & facade spec:
## - Medieval grey-fieldstone hall church (28.0 x 14.0 m), steep 58° dark
##   shingled saddle roof rising to 20.5 m (matching turku_lod2 20.5 m).
## - Red-brick ornamented west & east gables with whitewashed blind crosses
##   and lancet niches (classic Finnish medieval brick-gable craft).
## - Medieval south weapon-house porch (+Z), north vaulted sacristy (-Z),
##   and detached traditional timber/stone churchyard belfry (+X = 21 m).

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Fieldstone", LandmarkMaterials.pbr("stone", "#7E7A72", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#944634", 2.2))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFECE2", 2.0))
	lm.use("Shingle", LandmarkMaterials.pbr("slate", "#2E2B28", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#7A3426", 2.2))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.9))
	lm.use("Gilt", LandmarkMaterials.gold())

	# Medieval fieldstone nave (28.0 x 13.6 m, eaves 8.8 m).
	LandmarkFrKit.rect(lm, "Fieldstone", -14.2, 14.2, -7.0, 7.0, FOUND, 8.8)
	# Steep 58° dark shingled saddle roof rising from 8.8 m to 19.6 m.
	LandmarkFrKit.gable(lm, "Shingle", (0.0) - (28.8) * 0.5, (0.0) + (28.8) * 0.5, (0.0) - (14.6) * 0.5, (0.0) + (14.6) * 0.5, 8.8, 10.8, 0.0, "", 1)

	# Red-brick ornamented gable walls at -X (west) and +X (east) with whitewashed blind crosses.
	for sx: float in [-1.0, 1.0]:
		var gx := sx * 14.05
		LandmarkFrKit.gable(lm, "Brick", (gx) - (0.75) * 0.5, (gx) + (0.75) * 0.5, (0.0) - (13.8) * 0.5, (0.0) + (13.8) * 0.5, 8.8, 10.7, 0.0, "", 1)
		# Whitewashed blind cross & flanking vertical lancet niches on gable face.
		lm.box("Plaster", Vector3(gx + sx * 0.40, 14.2, 0.0), Vector3(0.08, 4.4, 0.75), Basis(), 0.0)
		lm.box("Plaster", Vector3(gx + sx * 0.40, 14.8, 0.0), Vector3(0.08, 0.70, 2.8), Basis(), 0.0)
		for oz: float in [-3.0, 3.0]:
			lm.box("Plaster", Vector3(gx + sx * 0.40, 11.4, oz), Vector3(0.08, 2.8, 0.70), Basis(), 0.0)
		# Gable peak iron/gilt cross reaching 20.5 m.
		lm.frustum("Gilt", Vector3(gx, 19.5, 0.0), 0.06, 0.04, 1.0, 6)
		lm.box("Gilt", Vector3(gx, 20.15, 0.0), Vector3(0.08, 0.08, 0.55), Basis(), 0.0)

	# Gothic pointed nave windows along south (+Z) and north (-Z) flanks.
	for i in 4:
		var wx := lerpf(-9.5, 9.5, float(i) / 3.0)
		for sz: float in [-1.0, 1.0]:
			if sz > 0.0 and absf(wx + 5.0) < 3.2:
				continue
			if sz < 0.0 and absf(wx - 6.0) < 3.5:
				continue
			LandmarkFrParts.opening(lm, "Brick", "WarmGlow", Vector3(wx, 2.8, sz * 7.02), Vector3(0, 0, sz),
				1.6, 4.2, LandmarkFrParts.HEAD_POINTED, 0.24, 0.14, 1)

	# South weapon-house porch (+Z at x = -5.0) & north vaulted sacristy (-Z at x = 6.0).
	LandmarkFrKit.rect(lm, "Fieldstone", -8.0, -2.0, 6.8, 11.4, FOUND, 5.4)
	LandmarkFrKit.gable(lm, "Shingle", (-5.0) - (6.4) * 0.5, (-5.0) + (6.4) * 0.5, (9.1) - (4.8) * 0.5, (9.1) + (4.8) * 0.5, 5.4, 3.8, 0.0, "", 0)
	LandmarkFrParts.opening(lm, "Brick", "WarmGlow", Vector3(-5.0, 0.2, 11.42), Vector3(0, 0, 1),
		2.0, 3.2, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	LandmarkFrKit.rect(lm, "Fieldstone", 2.5, 9.5, -11.6, -6.8, FOUND, 5.6)
	LandmarkFrKit.gable(lm, "Shingle", (6.0) - (7.4) * 0.5, (6.0) + (7.4) * 0.5, (-9.2) - (5.0) * 0.5, (-9.2) + (5.0) * 0.5, 5.6, 4.0, 0.0, "", 0)

	# Detached medieval/baroque timber-and-stone belfry (+X = 21.0, +Z = 4.0, h = 15.5 m).
	var bx := 21.0
	var bz := 4.0
	LandmarkFrKit.rect(lm, "Fieldstone", bx - 3.6, bx + 3.6, bz - 3.6, bz + 3.6, FOUND, 4.2)
	LandmarkFrKit.rect(lm, "Wood", bx - 3.2, bx + 3.2, bz - 3.2, bz + 3.2, 4.2, 9.6)
	lm.frustum("Shingle", Vector3(bx, 9.6, bz), 4.8, 2.2, 2.8, 4)
	lm.frustum("Wood", Vector3(bx, 12.4, bz), 1.9, 1.9, 1.2, 8)
	lm.frustum("Shingle", Vector3(bx, 13.6, bz), 2.1, 0.10, 1.9, 8)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-19.0, 0.8, 0.0), Vector3(-14.0, 12.0, 0.0), 28.0, 0.95, 55.0, warm],
		[Vector3(19.0, 0.8, 0.0), Vector3(14.0, 12.0, 0.0), 28.0, 0.9, 55.0, warm],
		[Vector3(0.0, 0.8, 15.5), Vector3(0.0, 7.0, 7.0), 26.0, 0.85, 60.0, warm],
	])
