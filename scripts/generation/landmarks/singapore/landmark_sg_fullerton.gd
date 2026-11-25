class_name LandmarkSgFullerton
extends RefCounted

## The Fullerton Hotel (37 m, way 46595395) & Fullerton Heritage Waterfront (18 m, SG-2.7):
## - Fullerton Hotel: 1928 monumental Aberdeen-grey granite neoclassical palazzo wrapping
##   its trapezoidal river-mouth footprint (126 x 76 m), giant fluted Doric colonnades on all
##   four facades, rusticated ground plinth, recessed pedimented porticoes, roof balustrade,
##   rooftop lighthouse pavilion, and warm architectural floodlighting.
## - Fullerton Waterfront: One Fullerton curved promenade pavilion, Art Deco Waterboat House,
##   arched vaulted Clifford Pier with hanging red lanterns, and Customs House.

static func fullerton_hotel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#C6C1B8", 3.0))
	lm.use("Rustic", LandmarkMaterials.pbr("stone", "#ACA69C", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#DCD8CE", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8E8A82", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B505E"))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD58C", 1.8))

	# Rusticated ground plinth (y=0..8.5 m).
	lm.box("Rustic", Vector3(0.0, 4.25, 0.0), Vector3(124.0, 8.5, 74.0))
	lm.box("Trim", Vector3(0.0, 8.75, 0.0), Vector3(126.0, 0.8, 76.0))
	# Recessed core palazzo body behind giant Doric colonnades (y=8.5..29.5 m).
	lm.box("Granite", Vector3(0.0, 19.0, 0.0), Vector3(114.0, 21.0, 64.0))
	# Recessed window bands on all 4 faces.
	for fl: float in [12.0, 17.0, 22.0, 26.5]:
		lm.box("Glass", Vector3(0.0, fl, 32.2), Vector3(106.0, 2.6, 0.5))
		lm.box("Glass", Vector3(0.0, fl, -32.2), Vector3(106.0, 2.6, 0.5))
		lm.box("Glass", Vector3(57.2, fl, 0.0), Vector3(0.5, 2.6, 56.0))
		lm.box("Glass", Vector3(-57.2, fl, 0.0), Vector3(0.5, 2.6, 56.0))

	# Giant fluted Doric colonnades ringing all four facades (y=8.5..28.5 m).
	LandmarkSgKit.colonnade(lm, "Trim", Vector3(-54.0, 8.5, 35.0), Vector3(54.0, 8.5, 35.0), 19.5, 0.95, 16)
	LandmarkSgKit.colonnade(lm, "Trim", Vector3(-54.0, 8.5, -35.0), Vector3(54.0, 8.5, -35.0), 19.5, 0.95, 16)
	LandmarkSgKit.colonnade(lm, "Trim", Vector3(59.5, 8.5, -28.0), Vector3(59.5, 8.5, 28.0), 19.5, 0.95, 10)
	LandmarkSgKit.colonnade(lm, "Trim", Vector3(-59.5, 8.5, -28.0), Vector3(-59.5, 8.5, 28.0), 19.5, 0.95, 10)

	# Heavy neoclassical entablature, cornice, attic storey & roof balustrade (y=28.0..34.0 m).
	lm.box("Trim", Vector3(0.0, 29.2, 0.0), Vector3(124.0, 2.4, 74.0))
	lm.box("Granite", Vector3(0.0, 32.0, 0.0), Vector3(118.0, 3.2, 68.0))
	lm.box("Roof", Vector3(0.0, 33.8, 0.0), Vector3(114.0, 0.8, 64.0))
	# Central classical pedimented porticoes on long facades.
	for side: float in [-1.0, 1.0]:
		lm.box("Trim", Vector3(0.0, 31.8, side * 36.2), Vector3(32.0, 3.6, 3.2))
		lm.box("WarmLamp", Vector3(0.0, 28.4, side * 35.8), Vector3(112.0, 0.35, 0.35))
	# Iconic Fullerton Rooftop Lighthouse pavilion (reaches 37.0 m).
	lm.frustum("Trim", Vector3(44.0, 33.8, 0.0), 4.2, 3.8, 2.2, 12)
	lm.frustum("WarmLamp", Vector3(44.0, 36.0, 0.0), 2.4, 2.2, 1.0, 12)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-38.0, 2.0, 46.0), Vector3(-38.0, 24.0, 34.0), 58.0, 1.3],
		[Vector3(38.0, 2.0, 46.0), Vector3(38.0, 24.0, 34.0), 58.0, 1.3],
		[Vector3(-38.0, 2.0, -46.0), Vector3(-38.0, 24.0, -34.0), 58.0, 1.2],
		[Vector3(38.0, 2.0, -46.0), Vector3(38.0, 24.0, -34.0), 58.0, 1.2],
	])

static func fullerton_waterfront(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("limestone", "#EAE4D6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B8B2A6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A64A32", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#4A6E82"))
	lm.use("DarkSteel", LandmarkMaterials.pbr("sheet_metal", "#3A4048", 2.0, 0.35, 0.7))
	lm.use("RedLamp", LandmarkMaterials.lit("#FF4C28", 2.4))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD890", 1.8))

	# Clifford Pier (centre, 1933 arched concrete & glass vaulted ferry pier over water).
	lm.box("Stone", Vector3(0.0, 1.0, 0.0), Vector3(56.0, 3.2, 34.0))
	lm.box("Cream", Vector3(0.0, 7.5, -10.0), Vector3(48.0, 11.0, 10.0))
	# Three vaulted arched roof bays projecting over Marina Bay (+Z).
	for i in 3:
		var bx := -16.0 + float(i) * 16.0
		LandmarkSgKit.loft_shell(lm, "Cream", Vector3(bx, 9.5, 4.0), 7.8, 12.0, 6.2, 6, 12, 0.8)
		lm.box("Glass", Vector3(bx, 6.2, 14.5), Vector3(12.0, 7.2, 0.5))
		lm.frustum("RedLamp", Vector3(bx, 11.5, 15.2), 0.75, 0.75, 1.4, 8)
	# Rooftop lantern cupola on Clifford Pier (reaches 18.0 m).
	lm.box("Cream", Vector3(0.0, 15.5, -8.0), Vector3(14.0, 3.0, 8.0))
	lm.box("Roof", Vector3(0.0, 17.5, -8.0), Vector3(15.0, 1.0, 9.0))

	# One Fullerton curved promenade wing (north, +X).
	lm.box("Stone", Vector3(92.0, 1.0, 2.0), Vector3(96.0, 2.8, 28.0))
	lm.box("Glass", Vector3(92.0, 6.5, 2.0), Vector3(90.0, 8.2, 22.0))
	lm.box("Cream", Vector3(92.0, 11.2, 2.0), Vector3(96.0, 1.4, 26.0))
	lm.box("WarmLamp", Vector3(92.0, 10.4, 14.2), Vector3(88.0, 0.35, 0.35))

	# Customs House & Waterboat House pavilion (south, -X).
	lm.box("Cream", Vector3(-74.0, 5.5, -2.0), Vector3(54.0, 11.0, 20.0))
	lm.box("Roof", Vector3(-74.0, 12.0, -2.0), Vector3(56.0, 2.2, 22.0))
	lm.box("Glass", Vector3(-74.0, 5.5, 8.2), Vector3(48.0, 7.5, 0.5))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 3.0, 24.0), Vector3(0.0, 12.0, 4.0), 65.0, 1.3],
		[Vector3(92.0, 3.0, 22.0), Vector3(92.0, 8.0, 2.0), 65.0, 1.0],
	])
