class_name FtPanternHjeltKaskenkatu
extends RefCounted

## Pantern (Frithiof Strandell, 1910) at Kaskenkatu 2 overlooking
## Vartiovuori and Auransilta.
## Origin at 60.448800 N, 22.271800 E, yaw_deg -35.0.
##
## Architectural & facade spec:
## - Footprint 42.0 x 24.0 m, corner polygonal towers peaking at 24.0 m.
## - Rough-dressed grey-granite plinth (y = -2.4..3.8 m) with arched
##   commercial shopfronts & carved entrance arch on Kaskenkatu.
## - Pale cream-putty late-Jugend / Classicist upper storeys (eaves 17.5 m)
##   with twin polygonal bay towers crowned by patinated copper domes,
##   steep dark-metal mansard roof, dormers & wrought-iron balconies.

const FOUND := -2.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#88837C", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E2DAC8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F2ECE0", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3A4046", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4A7464"))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A2", 0.8))

	# Granite ground plinth + pale-plaster main block (42 x 24 m).
	LandmarkFrKit.rect(lm, "Granite", -21.2, 21.2, -12.2, 12.2, FOUND, 3.8)
	LandmarkFrKit.rect(lm, "Trim", -21.4, 21.4, -12.4, 12.4, 3.65, 4.05)
	LandmarkFrKit.rect(lm, "Wall", -21.0, 21.0, -12.0, 12.0, 4.05, 17.5)
	LandmarkFrKit.rect(lm, "Trim", -21.35, 21.35, -12.35, 12.35, 17.25, 17.8)
	# Steep mansard roof (lower steep skirt + upper hipped cap to 22.0 m).
	LandmarkFrKit.hip(lm, "Roof", (0.0) - (42.8) * 0.5, (0.0) + (42.8) * 0.5, (0.0) - (24.8) * 0.5, (0.0) + (24.8) * 0.5, 17.8, 4.2, 0.0)

	# Twin polygonal corner bay towers (+X/+Z and -X/+Z) with copper domes to 24.0 m.
	for sx: float in [-1.0, 1.0]:
		var tx := sx * 20.6
		var tz := 11.6
		lm.frustum("Granite", Vector3(tx, FOUND, tz), 3.3, 3.25, 3.9 - FOUND, 8)
		lm.frustum("Wall", Vector3(tx, 3.9, tz), 3.15, 3.15, 15.2, 8)
		lm.frustum("Trim", Vector3(tx, 18.9, tz), 3.35, 3.4, 0.38, 8)
		lm.lathe("Copper", Vector3(tx, 19.28, tz), PackedVector2Array([
			Vector2(3.45, 0.0), Vector2(3.1, 1.3), Vector2(2.1, 2.7), Vector2(0.8, 3.9), Vector2(0.14, 4.72),
		]), 8, 1.0, 1.0, 0.0, false)

	# Central pedimented gable risalit on Kaskenkatu front (+Z).
	LandmarkFrKit.rect(lm, "Wall", -5.2, 5.2, 11.9, 13.0, 4.05, 18.4)
	LandmarkFrKit.gable(lm, "Roof", (0.0) - (10.8) * 0.5, (0.0) + (10.8) * 0.5, (12.2) - (2.6) * 0.5, (12.2) + (2.6) * 0.5, 18.4, 3.0, 0.0, "", 0)
	LandmarkFrParts.opening(lm, "Granite", "WarmGlow", Vector3(0.0, 0.2, 12.22), Vector3(0, 0, 1),
		3.0, 3.2, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 2)

	# Rhythmic upper windows on all 4 facades.
	for i in 10:
		var x := lerpf(-16.2, 16.2, float(i) / 9.0)
		var fz := 13.02 if absf(x) < 4.8 else 12.02
		for fl in 4:
			var wy := 4.9 + float(fl) * 3.15
			var g := "WarmGlow" if ((i + fl) % 4 == 0) else "Glass"
			LandmarkFrParts.opening(lm, "Trim", g, Vector3(x, wy, fz), Vector3(0, 0, 1),
				1.45, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, wy, -12.02), Vector3(0, 0, -1),
				1.45, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
	for i in 5:
		var z := lerpf(-8.2, 8.2, float(i) / 4.0)
		for fl in 4:
			var wy := 4.9 + float(fl) * 3.15
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-21.02, wy, z), Vector3(-1, 0, 0),
				1.45, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(21.02, wy, z), Vector3(1, 0, 0),
				1.45, 2.0, LandmarkFrParts.HEAD_FLAT, 0.16, 0.10, 1)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 1.0, 17.5), Vector3(-20.6, 15.0, 11.6), 28.0, 0.85, 55.0, warm],
		[Vector3(18.0, 1.0, 17.5), Vector3(20.6, 15.0, 11.6), 28.0, 0.85, 55.0, warm],
	])
