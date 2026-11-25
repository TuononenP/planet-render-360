class_name LandmarkSgVictoria
extends RefCounted

## Victoria Theatre & Concert Hall (54 m clock tower, SG-3.3) and
## Asian Civilisations Museum / Empress Place (22 m, SG-3.10).

static func victoria_theatre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("limestone", "#F2EFE6", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#DCD6C8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4630", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#324554"))
	lm.use("Shutter", LandmarkMaterials.pbr("wood", "#344E42", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#3E3832", 2.0, 0.35, 0.72))
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF4D2", 2.6))

	# Twin Palladian neoclassical wings (Theatre west, Concert Hall east) with pitched hipped roofs,
	# classical entablatures, pilasters, pediments, and two storeys of arched/shuttered openings on all 4 sides.
	for sx: float in [-26.0, 26.0]:
		# Rusticated plinth, main body, horizontal stringcourse & projecting roof cornice.
		lm.box("Trim", Vector3(sx, 1.2, 0.0), Vector3(34.8, 2.4, 44.8))
		lm.box("Cream", Vector3(sx, 9.2, 0.0), Vector3(33.6, 16.8, 43.6))
		lm.box("Trim", Vector3(sx, 9.6, 0.0), Vector3(34.4, 0.7, 44.4))
		lm.box("Trim", Vector3(sx, 17.5, 0.0), Vector3(35.0, 1.1, 45.0))
		# Pitched hipped terracotta roof + raised ridge ventilator.
		LandmarkSgKit.hipped_roof(lm, "Roof", Vector3(sx, 18.1, 0.0), 35.6, 45.6, 5.2, 11.5)
		lm.box("Trim", Vector3(sx, 23.4, 0.0), Vector3(1.2, 0.5, 22.0))

		# Front (+Z, Empress Place) & rear (-Z, High Street) projecting porticos with 3D pediments.
		for fz: float in [-1.0, 1.0]:
			var z_wall := fz * 21.9
			var z_port := fz * 24.0
			LandmarkSgKit.colonnade(lm, "Cream", Vector3(sx - 11.5, 0.0, z_port), Vector3(sx + 11.5, 0.0, z_port), 15.6, 0.55, 6)
			lm.box("Trim", Vector3(sx, 16.4, z_port - fz * 0.4), Vector3(26.8, 1.6, 4.2))
			LandmarkSgKit.pediment_prism(lm, "Cream", "Roof", Vector3(sx, 17.2, z_port - fz * 1.2), 26.2, 4.6, 5.2, true)
			# Two storeys of tall neoclassical windows behind the portico.
			for wi in 5:
				var wx := sx - 11.2 + float(wi) * 5.6
				lm.box("Glass", Vector3(wx, 5.4, z_wall), Vector3(2.4, 4.2, 0.45))
				lm.box("Glass", Vector3(wx, 13.4, z_wall), Vector3(2.4, 4.4, 0.45))
				lm.box("Trim", Vector3(wx, 15.9, z_wall + fz * 0.15), Vector3(2.9, 0.45, 0.5))

		# Outer & inner side facades (±X) with rhythmic pilasters and two storeys of arched windows.
		for fx: float in [-1.0, 1.0]:
			var x_wall := sx + fx * 16.9
			for wj in 7:
				var wz := -16.5 + float(wj) * 5.5
				lm.box("Glass", Vector3(x_wall, 5.4, wz), Vector3(0.45, 4.0, 2.3))
				lm.box("Shutter", Vector3(x_wall, 13.2, wz), Vector3(0.45, 4.2, 2.3))
				lm.box("Trim", Vector3(x_wall + fx * 0.18, 9.2, wz + 2.75), Vector3(0.55, 16.2, 0.85))
			# Central projecting side gable bay.
			lm.box("Cream", Vector3(sx + fx * 17.4, 9.2, 0.0), Vector3(1.6, 16.6, 14.0))
			LandmarkSgKit.pediment_prism(lm, "Cream", "Roof", Vector3(sx + fx * 17.2, 17.5, 0.0), 14.6, 3.6, 3.6, false)

	# Central linking colonnade block between Theatre & Concert Hall.
	lm.box("Cream", Vector3(0.0, 8.2, 2.0), Vector3(22.0, 16.4, 30.0))
	lm.box("Trim", Vector3(0.0, 16.6, 2.0), Vector3(22.8, 1.0, 30.8))
	LandmarkSgKit.hipped_roof(lm, "Roof", Vector3(0.0, 17.1, 2.0), 22.8, 30.8, 3.2, 7.0)
	for fz: float in [-1.0, 1.0]:
		var zc := 2.0 + fz * 16.4
		LandmarkSgKit.colonnade(lm, "Cream", Vector3(-9.0, 0.0, zc), Vector3(9.0, 0.0, zc), 14.2, 0.52, 5)
		lm.box("Trim", Vector3(0.0, 14.8, zc), Vector3(20.0, 1.2, 2.6))
		for wi in 3:
			var wx := -5.4 + float(wi) * 5.4
			lm.box("Glass", Vector3(wx, 5.2, 2.0 + fz * 15.1), Vector3(2.4, 4.2, 0.45))
			lm.box("Glass", Vector3(wx, 12.2, 2.0 + fz * 15.1), Vector3(2.4, 3.8, 0.45))

	# Iconic 54 m Central Clock Tower: rusticated base, corner pilasters, 4 framed clock dials,
	# balustraded gallery, 8-column open belfry & ribbed cupola dome + finial spire.
	var tx := 0.0
	var tz := 6.0
	lm.box("Cream", Vector3(tx, 18.0, tz), Vector3(11.4, 36.0, 11.4))
	# Corner pilasters & mid-shaft cornices.
	for cx: float in [-5.5, 5.5]:
		for cz: float in [-5.5, 5.5]:
			lm.box("Trim", Vector3(tx + cx, 24.0, tz + cz), Vector3(1.1, 24.0, 1.1))
	lm.box("Trim", Vector3(tx, 25.5, tz), Vector3(12.4, 1.0, 12.4))
	lm.box("Trim", Vector3(tx, 35.8, tz), Vector3(13.0, 1.3, 13.0))
	lm.box("Cream", Vector3(tx, 37.2, tz), Vector3(12.2, 1.4, 12.2))
	# 4 clock faces at y=31.0 m with bronze bezel, glowing white dial & dark clock hands.
	for side: float in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(tx, 31.0, tz + side * 5.82), Vector3(4.9, 4.9, 0.35))
		lm.box("ClockLamp", Vector3(tx, 31.0, tz + side * 6.02), Vector3(4.1, 4.1, 0.25))
		lm.box("Bronze", Vector3(tx, 31.6, tz + side * 6.18), Vector3(0.22, 1.5, 0.14))
		lm.box("Bronze", Vector3(tx + 0.55, 31.0, tz + side * 6.18), Vector3(1.2, 0.22, 0.14))
		lm.box("Bronze", Vector3(tx + side * 5.82, 31.0, tz), Vector3(0.35, 4.9, 4.9))
		lm.box("ClockLamp", Vector3(tx + side * 6.02, 31.0, tz), Vector3(0.25, 4.1, 4.1))
		lm.box("Bronze", Vector3(tx + side * 6.18, 31.6, tz), Vector3(0.14, 1.5, 0.22))
		lm.box("Bronze", Vector3(tx + side * 6.18, 31.0, tz + 0.55), Vector3(0.14, 0.22, 1.2))
	# Open octagonal belfry with 8 slender columns around a warm glowing bell chamber.
	lm.frustum("ClockLamp", Vector3(tx, 37.9, tz), 2.5, 2.5, 6.2, 8)
	for bi in 8:
		var ba := TAU * float(bi) / 8.0 + PI * 0.125
		var bp := Vector3(tx + cos(ba) * 4.1, 37.9, tz + sin(ba) * 4.1)
		lm.frustum("Cream", bp, 0.42, 0.36, 6.6, 8)
	lm.frustum("Trim", Vector3(tx, 44.4, tz), 4.8, 4.6, 1.0, 8)
	# Cupola dome & bronze finial spire reaching 54.0 m.
	LandmarkAsiaSouthUtil.dome(lm, "Trim", Vector3(tx, 45.3, tz), 4.3, 5.5, 16, 8)
	lm.frustum("Bronze", Vector3(tx, 50.8, tz), 0.35, 0.08, 3.2, 8)

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
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F4F0E6", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#DBD5C7", 3.0))
	lm.use("Shutter", LandmarkMaterials.pbr("wood", "#2D5A42", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A64B32", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#486C80"))
	lm.use("Titanium", LandmarkMaterials.pbr("sheet_metal", "#B8BEC4", 2.0, 0.32, 0.78))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD996", 1.7))

	# 1867 Palladian neoclassical main riverfront block (Empress Place Building).
	var bx := -8.0
	lm.box("Trim", Vector3(bx, 1.0, 0.0), Vector3(92.8, 2.0, 44.8))
	lm.box("White", Vector3(bx, 7.6, 0.0), Vector3(91.6, 14.0, 43.6))
	lm.box("Trim", Vector3(bx, 7.8, 0.0), Vector3(92.4, 0.65, 44.4))
	lm.box("Trim", Vector3(bx, 14.6, 0.0), Vector3(93.2, 1.0, 45.2))
	# Pitched hipped terracotta roof with deep overhanging tropical eaves (ridge reaches 20.8 m).
	LandmarkSgKit.hipped_roof(lm, "Roof", Vector3(bx, 15.1, 0.0), 94.4, 46.4, 5.6, 15.5)

	# Projecting central Palladian portico pavilions & 3D pediments on BOTH long facades (±Z).
	for fz: float in [-1.0, 1.0]:
		lm.box("White", Vector3(bx, 7.8, fz * 23.0), Vector3(26.0, 14.8, 5.2))
		lm.box("Trim", Vector3(bx, 15.1, fz * 23.8), Vector3(27.2, 1.0, 6.2))
		LandmarkSgKit.colonnade(lm, "White", Vector3(bx - 10.5, 0.0, fz * 26.2), Vector3(bx + 10.5, 0.0, fz * 26.2), 14.2, 0.5, 6)
		LandmarkSgKit.pediment_prism(lm, "White", "Roof", Vector3(bx, 15.6, fz * 23.8), 26.6, 6.2, 7.2, true)
		# Flanking end pavilions with shallow projections.
		for ex: float in [-37.0, 37.0]:
			lm.box("White", Vector3(bx + ex, 7.6, fz * 22.4), Vector3(16.0, 14.2, 2.0))
			LandmarkSgKit.pediment_prism(lm, "White", "Roof", Vector3(bx + ex, 15.1, fz * 22.0), 15.6, 3.4, 4.4, true)
		# Two storeys of arched ground openings & green louvred shutters along long facades.
		for i in 13:
			var wx := bx - 42.0 + float(i) * 7.0
			lm.box("Glass", Vector3(wx, 4.4, fz * 21.95), Vector3(2.4, 3.8, 0.45))
			lm.box("Shutter", Vector3(wx, 11.2, fz * 21.95), Vector3(2.4, 3.8, 0.45))
			lm.box("Trim", Vector3(wx + 3.5, 7.6, fz * 22.05), Vector3(0.75, 13.8, 0.55))

	# Short end facades (±X) — fully detailed with pilasters, ground arcade windows & upper green shutters.
	for fx: float in [-1.0, 1.0]:
		var xw := bx + fx * 45.95
		for j in 6:
			var wz := -17.5 + float(j) * 7.0
			lm.box("Glass", Vector3(xw, 4.4, wz), Vector3(0.45, 3.8, 2.4))
			lm.box("Shutter", Vector3(xw, 11.2, wz), Vector3(0.45, 3.8, 2.4))
			lm.box("Trim", Vector3(xw + fx * 0.12, 7.6, wz + 3.5), Vector3(0.55, 13.8, 0.75))

	# Modern Kwek Hong Png reflective titanium & glass riverfront wing (+X).
	lm.box("Glass", Vector3(48.0, 6.5, 4.0), Vector3(26.0, 13.0, 32.0))
	for mi in 6:
		var mz := -10.0 + float(mi) * 4.0
		lm.box("Titanium", Vector3(61.1, 6.5, mz + 4.0), Vector3(0.45, 13.0, 0.45))
	LandmarkSgKit.hipped_roof(lm, "Titanium", Vector3(48.0, 13.1, 4.0), 29.0, 35.0, 2.4, 4.0)
	lm.box("WarmLamp", Vector3(bx, 14.3, 22.8), Vector3(88.0, 0.35, 0.35))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(bx, 2.0, 36.0), Vector3(bx, 14.0, 18.0), 62.0, 1.3],
		[Vector3(bx, 2.0, -34.0), Vector3(bx, 14.0, -18.0), 62.0, 1.2],
	])
