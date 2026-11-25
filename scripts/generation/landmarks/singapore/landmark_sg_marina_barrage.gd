class_name LandmarkSgMarinaBarrage
extends RefCounted

## Marina Barrage (24 m, SG-2.10):
## - 350 m dam crest across Marina Channel separating fresh Marina Reservoir from Singapore Strait,
##   with 9 steel crest-gate bays, concrete piers, pedestrian bridge deck, and the iconic
##   sweeping spiral Green Roof lawn ramp & Sustainable Singapore Gallery pavilion.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D8D4CC", 3.0))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#5E6872", 2.0, 0.32, 0.74))
	lm.use("Lawn", LandmarkMaterials.pbr("forest", "#4C8C3A", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#6C9CB2"))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE2A4", 1.8))

	# 350 m barrage deck & 9 steel crest-gate bays across Marina Channel.
	lm.box("Concrete", Vector3(0.0, 4.5, 0.0), Vector3(340.0, 2.2, 16.0))
	for i in 10:
		var px := -153.0 + float(i) * 34.0
		lm.box("Concrete", Vector3(px, 2.0, 0.0), Vector3(5.0, 12.0, 20.0))
		lm.box("WarmLamp", Vector3(px, 8.2, 0.0), Vector3(2.2, 0.5, 16.0))
		if i < 9:
			lm.box("Steel", Vector3(px + 17.0, 1.5, 0.0), Vector3(29.0, 5.5, 2.4))

	# Sculptural spiral Green Roof lawn ramp & visitor gallery at the west end (-125 m).
	var gx := -122.0
	lm.frustum("Concrete", Vector3(gx, 0.0, 0.0), 42.0, 38.0, 14.0, 20)
	lm.frustum("Glass", Vector3(gx, 2.0, 0.0), 40.5, 39.0, 9.5, 20)
	lm.frustum("Lawn", Vector3(gx, 14.0, 0.0), 39.0, 22.0, 7.5, 20)
	# Rooftop viewing pavilion crest (reaches 24.0 m).
	lm.box("Concrete", Vector3(gx, 22.4, 0.0), Vector3(22.0, 2.8, 14.0))
	lm.box("WarmLamp", Vector3(gx, 23.6, 0.0), Vector3(18.0, 0.5, 10.0))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(gx, 4.0, 46.0), Vector3(gx, 16.0, 0.0), 65.0, 1.2],
	])
