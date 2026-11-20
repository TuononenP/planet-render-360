class_name FtRuissaloVillasSpa
extends RefCounted

## Ruissalo Spa & Historic Seaside Villa Ensemble on Ruissalo Island
## overlooking the Airisto archipelago strait.
## Origin at 60.433150 N, 22.173850 E, yaw_deg -20.0.
##
## Architectural & facade spec:
## - Two-part coastal ensemble (48.0 x 24.0 m), villa turret peaking at 14.1 m
##   (matching turku_lod2 14.1 m):
##   (1) 19th-century ornate Ruissalo timber seaside villa (-X): cream-ochre
##       clapboard walls, granite plinth, wraparound glazed veranda with white
##       balustrade & fretwork posts, steep 35° dark-metal gable roof, and
##       octagonal belvedere corner turret to 14.1 m.
##   (2) Contemporary glazed Ruissalo Spa waterfront wing (+X) with warm
##       timber eaves, panoramic archipelago lounge windows & sea terrace.

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86827A", 2.5))
	lm.use("Clapboard", LandmarkMaterials.pbr("wood", "#E6D6AE", 2.2))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F1E8", 2.0))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#9E7248", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#383E44", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#487262"))
	lm.use("Glass", LandmarkMaterials.glass("#22303A"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A4", 0.9))

	# Historic Ruissalo timber seaside villa (-22..-2, -10..10).
	LandmarkFrKit.rect(lm, "Granite", -22.5, -1.5, -10.5, 10.5, FOUND, 1.3)
	LandmarkFrKit.rect(lm, "Clapboard", -21.0, -3.0, -8.5, 8.5, 1.3, 8.4)
	LandmarkFrKit.rect(lm, "Trim", -21.2, -2.8, -8.7, 8.7, 8.2, 8.6)
	# Steep 35° gable roof + cross-gable dormer (ridge 12.6 m).
	LandmarkFrKit.gable(lm, "Roof", (-12.0) - (18.8) * 0.5, (-12.0) + (18.8) * 0.5, (0.0) - (17.8) * 0.5, (0.0) + (17.8) * 0.5, 8.6, 4.0, 0.0, "", 1)
	LandmarkFrKit.gable(lm, "Roof", (-12.0) - (9.6) * 0.5, (-12.0) + (9.6) * 0.5, (1.5) - (19.6) * 0.5, (1.5) + (19.6) * 0.5, 8.6, 3.6, 0.0, "", 0)

	# Wraparound white timber veranda on seaside front (+Z = 8.5..11.5).
	LandmarkFrKit.rect(lm, "Timber", -22.2, -1.8, 8.5, 11.6, FOUND, 1.35)
	LandmarkFrKit.rect(lm, "Trim", -22.2, -1.8, 11.3, 11.6, 1.35, 2.35)
	LandmarkFrKit.rect(lm, "Roof", -22.4, -1.6, 8.4, 11.8, 4.75, 5.15)
	for i in 7:
		var px := lerpf(-21.6, -2.4, float(i) / 6.0)
		lm.frustum("Trim", Vector3(px, 1.35, 11.4), 0.14, 0.12, 3.45, 8)

	# Octagonal seaside belvedere turret (-21.2, 9.2) peaking at 14.1 m.
	lm.frustum("Granite", Vector3(-21.2, FOUND, 9.2), 2.5, 2.4, 1.3 - FOUND, 8)
	lm.frustum("Clapboard", Vector3(-21.2, 1.3, 9.2), 2.35, 2.35, 9.4, 8)
	lm.frustum("Trim", Vector3(-21.2, 10.5, 9.2), 2.55, 2.6, 0.35, 8)
	lm.frustum("Copper", Vector3(-21.2, 10.85, 9.2), 2.75, 0.10, 3.25, 8)

	# Villa casement windows with white surrounds.
	for i in 5:
		var wx := lerpf(-18.5, -5.5, float(i) / 4.0)
		for fl in 2:
			var wy := 2.2 + float(fl) * 3.2
			var g := "WarmGlow" if (i + fl) % 2 == 0 else "Glass"
			LandmarkFrParts.opening(lm, "Trim", g, Vector3(wx, wy, 8.52), Vector3(0, 0, 1),
				1.4, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, wy, -8.52), Vector3(0, 0, -1),
				1.4, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)

	# Contemporary glazed Ruissalo Spa waterfront wing (+X = -1.5..24.0, -9..10).
	LandmarkFrKit.rect(lm, "Granite", -1.5, 24.5, -9.5, 11.8, FOUND, 1.1)
	LandmarkFrKit.rect(lm, "Trim", -1.0, 23.5, -8.5, 8.5, 1.1, 8.8)
	LandmarkFrKit.rect(lm, "Timber", -1.8, 24.4, -9.2, 10.4, 8.6, 9.2)
	# Panoramic sea-view spa lounge glazing (+Z).
	LandmarkFrKit.rect(lm, "WarmGlow", 0.5, 22.0, 8.45, 8.65, 1.4, 7.8)
	for i in 8:
		var mx := lerpf(0.5, 22.0, float(i) / 7.0)
		lm.box("Timber", Vector3(mx, 4.6, 8.68), Vector3(0.24, 6.6, 0.18), Basis(), 0.0)
		lm.frustum("Timber", Vector3(mx, 1.1, 10.0), 0.16, 0.16, 7.6, 8)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 0.9, 16.5), Vector3(-12.0, 6.0, 9.0), 28.0, 0.9, 60.0, warm],
		[Vector3(11.0, 0.9, 16.5), Vector3(11.0, 5.5, 9.0), 28.0, 0.85, 65.0, warm],
	])
