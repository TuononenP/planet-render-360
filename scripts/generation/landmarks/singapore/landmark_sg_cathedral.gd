class_name LandmarkSgCathedral
extends RefCounted

## St Andrew's Cathedral (63 m spire, way 155980025, SG-3.4):
## - Gleaming madras-chunam white neo-Gothic Anglican cathedral standing in its open green
##   lawns beside the Padang (fixes OSM `height=0`!):
##   cruciform nave & transepts, pointed lancet windows, rhythmic side buttresses & pinnacles,
##   and its iconic slender 63 m white steeple tower & octagonal spire with cross finial.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Chunam", LandmarkMaterials.pbr("limestone", "#F6F5F0", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#E0DDD4", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#565B62", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B5C78"))
	lm.use("Cross", LandmarkMaterials.gold())
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE2A8", 1.8))

	# Cruciform nave (68 m along X) + crossing transepts (38 m along Z).
	lm.box("Chunam", Vector3(4.0, 9.5, 0.0), Vector3(66.0, 19.0, 21.0))
	lm.box("Chunam", Vector3(8.0, 9.5, 0.0), Vector3(19.0, 19.0, 38.0))
	# Steep pitched slate nave & transept roofs.
	var r_pts := PackedVector2Array([Vector2(-10.8, 19.0), Vector2(10.8, 19.0), Vector2(0.0, 27.5)])
	lm.box("Roof", Vector3(4.0, 22.8, 0.0), Vector3(67.0, 7.6, 15.0))
	lm.box("Roof", Vector3(8.0, 22.8, 0.0), Vector3(15.0, 7.6, 39.0))
	var _unused := r_pts
	# Rhythmic Gothic buttresses, pinnacles & pointed lancet windows along nave flanks.
	for i in 7:
		var bx := -22.0 + float(i) * 9.0
		for side: float in [-1.0, 1.0]:
			lm.box("Chunam", Vector3(bx, 8.5, side * 11.4), Vector3(1.6, 17.0, 2.2))
			lm.spire("Chunam", Vector3(bx, 17.0, side * 11.4), 0.75, 4.2, 0.08, 4)
			if i < 6:
				lm.box("Glass", Vector3(bx + 4.5, 10.0, side * 10.7), Vector3(2.4, 8.5, 0.4))
	# West porte-cochère entrance & tall bell tower (x = -29 m).
	lm.box("Chunam", Vector3(-37.0, 5.5, 0.0), Vector3(11.0, 11.0, 13.0))
	lm.box("Chunam", Vector3(-28.0, 17.5, 0.0), Vector3(11.5, 35.0, 11.5))
	# Four corner Gothic turret pinnacles at top of bell tower.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.spire("Chunam", Vector3(-28.0 + sx * 5.2, 34.5, sz * 5.2), 1.1, 7.5, 0.12, 4)
	# Slender octagonal neo-Gothic white spire rising from y=34.5 m to 61.5 m + gilded cross to 63.0 m.
	lm.spire("Chunam", Vector3(-28.0, 34.5, 0.0), 4.6, 27.0, 0.25, 8)
	lm.box("Cross", Vector3(-28.0, 62.2, 0.0), Vector3(0.25, 1.6, 0.25))
	lm.box("Cross", Vector3(-28.0, 62.4, 0.0), Vector3(0.25, 0.25, 1.1))
	# Subtle warm lantern glow inside belfry & west lancets.
	lm.box("WarmLamp", Vector3(-28.0, 28.0, 0.0), Vector3(11.8, 4.2, 4.2))
	lm.box("WarmLamp", Vector3(-28.0, 28.0, 0.0), Vector3(4.2, 4.2, 11.8))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.0, 18.0), Vector3(-28.0, 42.0, 0.0), 55.0, 1.6],
		[Vector3(-42.0, 2.0, -18.0), Vector3(-28.0, 42.0, 0.0), 55.0, 1.6],
		[Vector3(8.0, 2.0, 28.0), Vector3(8.0, 16.0, 0.0), 62.0, 1.2],
	])
