class_name LandmarkSgVictoria
extends RefCounted

## Victoria Theatre & Concert Hall (54 m clock tower, SG-3.3) and
## Asian Civilisations Museum / Empress Place (22 m, SG-3.10).

static func victoria_theatre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("limestone", "#F0ECE2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#D8D2C6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4630", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B5060"))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#3E3832", 2.0, 0.35, 0.72))
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF2C8", 2.6))

	# Twin Palladian neoclassical wings (Theatre west, Concert Hall east) linked by central colonnade.
	for sx: float in [-26.0, 26.0]:
		lm.box("Cream", Vector3(sx, 9.5, 0.0), Vector3(34.0, 19.0, 44.0))
		lm.box("Roof", Vector3(sx, 20.6, 0.0), Vector3(35.0, 3.2, 45.0))
		lm.box("Glass", Vector3(sx, 11.0, 22.3), Vector3(26.0, 7.5, 0.5))
		LandmarkSgKit.colonnade(lm, "Cream", Vector3(sx - 12.0, 0.0, 24.0), Vector3(sx + 12.0, 0.0, 24.0), 15.0, 0.65, 6)
		lm.box("Trim", Vector3(sx, 16.0, 24.0), Vector3(28.0, 1.8, 3.6))
		# Pediment over wing portico.
		LandmarkSgKit.flat_tri(lm, "Cream", Vector3(sx - 13.0, 16.9, 25.5), Vector3(sx + 13.0, 16.9, 25.5), Vector3(sx, 21.2, 25.5))
	# Central linking wing.
	lm.box("Cream", Vector3(0.0, 8.5, 2.0), Vector3(24.0, 17.0, 32.0))
	LandmarkSgKit.colonnade(lm, "Cream", Vector3(-10.0, 0.0, 20.0), Vector3(10.0, 0.0, 20.0), 14.0, 0.6, 5)

	# Iconic 54 m Central Clock Tower with 4 glowing clock faces, open belfry & cupola dome.
	lm.box("Cream", Vector3(0.0, 18.0, 6.0), Vector3(11.5, 36.0, 11.5))
	lm.box("Trim", Vector3(0.0, 36.5, 6.0), Vector3(12.6, 1.2, 12.6))
	# 4 glowing clock faces at y=31 m.
	for side: float in [-1.0, 1.0]:
		lm.box("ClockLamp", Vector3(0.0, 31.0, 6.0 + side * 5.9), Vector3(4.2, 4.2, 0.35))
		lm.box("ClockLamp", Vector3(side * 5.9, 31.0, 6.0), Vector3(0.35, 4.2, 4.2))
	# Open belfry lantern & dome reaching 54.0 m.
	lm.box("Cream", Vector3(0.0, 41.0, 6.0), Vector3(8.4, 8.0, 8.4))
	lm.box("ClockLamp", Vector3(0.0, 41.5, 6.0), Vector3(6.2, 5.0, 6.2))
	LandmarkAsiaSouthUtil.dome(lm, "Trim", Vector3(0.0, 45.0, 6.0), 4.4, 6.0, 14, 7)
	lm.frustum("Bronze", Vector3(0.0, 50.8, 6.0), 0.35, 0.08, 3.2, 8)

	# Sir Stamford Raffles bronze statue on marble plinth in forecourt (+Z).
	lm.box("Trim", Vector3(0.0, 2.2, 33.0), Vector3(3.6, 4.4, 3.6))
	lm.frustum("Bronze", Vector3(0.0, 4.4, 33.0), 0.55, 0.42, 2.6, 8)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 38.0), Vector3(0.0, 36.0, 8.0), 58.0, 1.5],
		[Vector3(-26.0, 2.0, 36.0), Vector3(-26.0, 16.0, 20.0), 60.0, 1.2],
		[Vector3(26.0, 2.0, 36.0), Vector3(26.0, 16.0, 20.0), 60.0, 1.2],
	])

static func asian_civilisations_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F2EEE5", 3.0))
	lm.use("Shutter", LandmarkMaterials.pbr("wood", "#2D5A42", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A64B32", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#5A8094"))
	lm.use("Titanium", LandmarkMaterials.pbr("sheet_metal", "#B8BEC4", 2.0, 0.32, 0.78))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD996", 1.7))

	# 1867 Palladian neoclassical main riverfront block (way 46595390).
	lm.box("White", Vector3(-8.0, 7.5, 0.0), Vector3(92.0, 15.0, 44.0))
	lm.box("Roof", Vector3(-8.0, 17.5, 0.0), Vector3(94.0, 5.0, 46.0))
	# Projecting central entrance portico & green shuttered window rows.
	lm.box("White", Vector3(-8.0, 8.5, 24.0), Vector3(28.0, 17.0, 8.0))
	LandmarkSgKit.colonnade(lm, "White", Vector3(-19.0, 0.0, 28.5), Vector3(3.0, 0.0, 28.5), 14.5, 0.55, 6)
	LandmarkSgKit.flat_tri(lm, "White", Vector3(-21.0, 17.0, 28.8), Vector3(5.0, 17.0, 28.8), Vector3(-8.0, 21.8, 28.8))
	for i in 12:
		var wx := -48.0 + float(i) * 7.2
		lm.box("Shutter", Vector3(wx, 10.5, 22.3), Vector3(2.4, 3.6, 0.45))
		lm.box("Shutter", Vector3(wx, 10.5, -22.3), Vector3(2.4, 3.6, 0.45))
	# Modern Kwek Hong Png reflective titanium & glass river wing (+X).
	lm.box("Glass", Vector3(48.0, 6.5, 4.0), Vector3(26.0, 13.0, 32.0))
	lm.box("Titanium", Vector3(48.0, 14.0, 4.0), Vector3(28.0, 2.2, 34.0))
	lm.box("WarmLamp", Vector3(-8.0, 14.8, 23.0), Vector3(88.0, 0.35, 0.35))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.0, 2.0, 36.0), Vector3(-8.0, 14.0, 18.0), 62.0, 1.3],
		[Vector3(-8.0, 2.0, -34.0), Vector3(-8.0, 14.0, -18.0), 62.0, 1.2],
	])
