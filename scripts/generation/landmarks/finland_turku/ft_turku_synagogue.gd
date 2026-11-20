class_name FtTurkuSynagogue
extends RefCounted

## Turku Synagogue (Turun synagoga, August Krook & J. Eskil Hindersson, 1912)
## at Brahenkatu 17 / Puutori.
## Origin at OSM way:90081643 centroid (60.455739 N, 22.266577 E), yaw_deg 54.8.
##
## Architectural & facade spec:
## - Footprint 23.0 x 15.5 m, peak height 16.2 m (matching turku_lod2 16.2 m).
## - Rough grey-granite plinth (y = -1.6..1.8 m), red-brick Art Nouveau /
##   Byzantine walls with cream-plaster cornice bands & blind arcades.
## - Projecting arched entrance portico (+Z) with granite steps, triple
##   semicircular portal and Star of David tympanum medallion.
## - Four corner turrets with pyramidal green-copper caps.
## - Central octagonal brick drum pierced by 8 arched clerestory windows,
##   crowned by a prominent ribbed green-copper dome and gilt finial at 16.2 m.
## - Night illumination: warm upward floodlights + glowing sanctuary windows.

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86827B", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#964634", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E8E0D0", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4A7866"))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFDFA0", 0.9))
	lm.use("Gilt", LandmarkMaterials.gold())

	# Granite plinth & main red-brick hall (23.0 x 15.5 m).
	LandmarkFrKit.rect(lm, "Granite", -11.7, 11.7, -7.9, 7.9, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Brick", -11.4, 11.4, -7.6, 7.6, 1.8, 8.8)
	LandmarkFrKit.rect(lm, "Trim", -11.6, 11.6, -7.8, 7.8, 8.6, 9.15)
	# Low hipped copper roof around the central drum.
	LandmarkFrKit.hip(lm, "Copper", (0.0) - (23.6) * 0.5, (0.0) + (23.6) * 0.5, (0.0) - (16.0) * 0.5, (0.0) + (16.0) * 0.5, 9.15, 2.2, 0.0)

	# Four corner turrets with copper caps.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var tx := sx * 10.6
			var tz := sz * 6.8
			LandmarkFrKit.rect(lm, "Granite", tx - 1.4, tx + 1.4, tz - 1.4, tz + 1.4, FOUND, 1.8)
			LandmarkFrKit.rect(lm, "Brick", tx - 1.3, tx + 1.3, tz - 1.3, tz + 1.3, 1.8, 10.2)
			LandmarkFrKit.rect(lm, "Trim", tx - 1.45, tx + 1.45, tz - 1.45, tz + 1.45, 10.0, 10.45)
			lm.frustum("Copper", Vector3(tx, 10.45, tz), 1.85, 0.12, 2.3, 4)

	# Projecting arched entrance portico (+Z) with granite steps.
	LandmarkFrKit.rect(lm, "Granite", -4.4, 4.4, 7.6, 10.4, FOUND, 1.8)
	for s in 4:
		var z1 := 10.4 + float(s + 1) * 0.45
		var y1 := lerpf(1.4, 0.25, float(s) / 3.0)
		LandmarkFrKit.rect(lm, "Granite", -4.2, 4.2, 10.2, z1, FOUND, y1)
	LandmarkFrKit.rect(lm, "Brick", -4.1, 4.1, 7.5, 9.8, 1.8, 8.4)
	LandmarkFrKit.rect(lm, "Trim", -4.3, 4.3, 7.4, 10.0, 8.2, 8.65)
	LandmarkFrKit.gable(lm, "Copper", (0.0) - (8.6) * 0.5, (0.0) + (8.6) * 0.5, (8.7) - (2.8) * 0.5, (8.7) + (2.8) * 0.5, 8.65, 1.8, 0.0, "", 0)
	LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(0.0, 2.0, 9.82), Vector3(0, 0, 1),
		2.8, 4.2, LandmarkFrParts.HEAD_ROUND, 0.3, 0.18, 2)
	for sx: float in [-2.6, 2.6]:
		LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(sx, 2.4, 9.82), Vector3(0, 0, 1),
			1.2, 3.0, LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 1)

	# Side rhythmic arched sanctuary windows (5 bays per flank, 3 per end).
	for i in 5:
		var x := lerpf(-7.6, 7.6, float(i) / 4.0)
		for sz: float in [-1.0, 1.0]:
			if sz > 0.0 and absf(x) < 4.5:
				continue
			LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(x, 3.4, sz * 7.62), Vector3(0, 0, sz),
				1.6, 3.8, LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 1)
			lm.box("Trim", Vector3(x, 7.8, sz * 7.66), Vector3(1.8, 0.28, 0.12), Basis(), 0.0)
	for i in 3:
		var z := lerpf(-3.8, 3.8, float(i) / 2.0)
		for sx: float in [-1.0, 1.0]:
			LandmarkFrParts.opening(lm, "Trim", "WarmGlow", Vector3(sx * 11.42, 3.4, z), Vector3(sx, 0, 0),
				1.5, 3.8, LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 1)

	# Central octagonal drum (r = 5.4 m, y = 9.0..12.2 m) with 8 arched windows.
	lm.frustum("Brick", Vector3(0.0, 9.0, 0.0), 5.5, 5.4, 3.1, 8)
	lm.frustum("Trim", Vector3(0.0, 11.95, 0.0), 5.7, 5.75, 0.35, 8)
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		var n := Vector3(cos(a), 0.0, sin(a))
		LandmarkFrParts.opening(lm, "Trim", "WarmGlow", n * 5.05 + Vector3(0.0, 9.5, 0.0), n,
			1.25, 2.0, LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)

	# Prominent green-copper Byzantine dome (y = 12.2..15.2 m) + gilt finial to 16.2 m.
	lm.lathe("Copper", Vector3(0.0, 12.2, 0.0), PackedVector2Array([
		Vector2(5.45, 0.0), Vector2(5.35, 0.6), Vector2(4.85, 1.4),
		Vector2(3.80, 2.2), Vector2(2.25, 2.75), Vector2(0.85, 3.0), Vector2(0.25, 3.1),
	]), 24, 1.0, 1.0, 0.0, false)
	lm.frustum("Gilt", Vector3(0.0, 15.2, 0.0), 0.12, 0.07, 1.0, 8)
	lm.box("Gilt", Vector3(0.0, 15.85, 0.0), Vector3(0.65, 0.55, 0.10), Basis(), 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 0.8, 14.5), Vector3(0.0, 6.0, 9.0), 26.0, 0.95, 55.0, warm],
		[Vector3(6.0, 0.8, 14.5), Vector3(0.0, 6.0, 9.0), 26.0, 0.95, 55.0, warm],
		[Vector3(0.0, 1.2, -14.0), Vector3(0.0, 13.5, 0.0), 26.0, 0.85, 60.0, warm],
	])
