class_name LandmarkSgCivicModern
extends RefCounted

## Modern & monumental Civic District icons around the Padang:
## - `supreme_court` (46 m, SG-3.2): Foster + Partners marble/glass block + flying-saucer Court of Appeal disc.
## - `arts_house_parliament` (28 m, SG-3.5): 1827 Arts House + elephant statue + modern Parliament House.
## - `padang_ensemble` (18 m, SG-3.6): Cricket Club, Recreation Club, Cenotaph, Lim Bo Seng Memorial.
## - `civilian_war_memorial` (67 m, SG-3.7): Four identical tapering white concrete pillars ("Chopsticks").

static func supreme_court(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#ECE8DF", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#7AA0B4"))
	lm.use("Disc", LandmarkMaterials.pbr("sheet_metal", "#D6DCE2", 2.0, 0.28, 0.78))
	lm.use("DarkSteel", LandmarkMaterials.pbr("sheet_metal", "#4C535C", 2.0, 0.35, 0.72))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE6B4", 1.7))

	# Main translucent Portuguese-marble & glass courtroom atrium block (118 x 86 m, y=0..33 m).
	lm.box("Glass", Vector3(0.0, 16.5, 0.0), Vector3(114.0, 33.0, 82.0))
	for i in 12:
		var fx := -52.0 + float(i) * 9.4
		lm.box("Marble", Vector3(fx, 16.5, 41.3), Vector3(3.2, 33.0, 1.2))
		lm.box("Marble", Vector3(fx, 16.5, -41.3), Vector3(3.2, 33.0, 1.2))
	lm.box("Marble", Vector3(0.0, 33.6, 0.0), Vector3(118.0, 1.4, 86.0))
	# Cantilevered circular perforated-aluminium "Flying Saucer" Court of Appeal disc (y=34..46 m).
	lm.frustum("DarkSteel", Vector3(0.0, 33.8, 0.0), 16.0, 22.0, 2.6, 20)
	lm.frustum("Disc", Vector3(0.0, 36.2, 0.0), 22.0, 31.0, 4.4, 28)
	lm.frustum("Disc", Vector3(0.0, 40.6, 0.0), 31.0, 18.0, 4.6, 28)
	lm.frustum("Glass", Vector3(0.0, 44.8, 0.0), 18.0, 14.0, 1.2, 24)
	lm.frustum("WarmLamp", Vector3(0.0, 36.0, 0.0), 24.0, 24.0, 0.6, 24)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 52.0), Vector3(0.0, 28.0, 20.0), 65.0, 1.2],
	])

static func arts_house_parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F2EFE8", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#CFC9BC", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4832", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#5E4F40", 2.0, 0.35, 0.72))
	lm.use("Glass", LandmarkMaterials.glass("#58788C"))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE0A2", 1.6))

	# 1. The Arts House (Old Parliament House, 1827 white neoclassical, front +Z).
	lm.box("White", Vector3(24.0, 6.2, 22.0), Vector3(43.0, 12.4, 27.0))
	lm.box("Stone", Vector3(24.0, 6.4, 22.0), Vector3(43.8, 0.55, 27.8))
	lm.box("Stone", Vector3(24.0, 12.6, 22.0), Vector3(44.4, 0.8, 28.4))
	LandmarkSgKit.hipped_roof(lm, "Roof", Vector3(24.0, 13.0, 22.0), 45.6, 29.6, 4.4, 9.0)
	LandmarkSgKit.colonnade(lm, "White", Vector3(12.0, 0.0, 36.6), Vector3(36.0, 0.0, 36.6), 11.2, 0.45, 6)
	LandmarkSgKit.pediment_prism(lm, "White", "Roof", Vector3(24.0, 12.2, 35.4), 25.0, 3.8, 4.4, true)
	for fz: float in [-1.0, 1.0]:
		for i in 7:
			var wx := 6.0 + float(i) * 6.0
			lm.box("Glass", Vector3(wx, 3.6, 22.0 + fz * 13.65), Vector3(2.1, 3.2, 0.4))
			lm.box("Glass", Vector3(wx, 9.4, 22.0 + fz * 13.65), Vector3(2.1, 3.2, 0.4))
	for fx: float in [-1.0, 1.0]:
		for j in 4:
			var wz := 13.0 + float(j) * 6.0
			lm.box("Glass", Vector3(24.0 + fx * 21.65, 3.6, wz), Vector3(0.4, 3.2, 2.1))
			lm.box("Glass", Vector3(24.0 + fx * 21.65, 9.4, wz), Vector3(0.4, 3.2, 2.1))
	# Bronze elephant statue gifted by King Chulalongkorn on plinth in front.
	lm.box("Stone", Vector3(24.0, 1.4, 43.0), Vector3(2.8, 2.8, 2.2))
	lm.box("Bronze", Vector3(24.0, 3.4, 43.0), Vector3(1.8, 1.4, 1.1))

	# 2. Modern Parliament House behind (-Z) with distinctive bronze prism-topped roof pavilion (28 m).
	lm.box("Stone", Vector3(-18.0, 9.5, -16.0), Vector3(72.0, 19.0, 44.0))
	lm.box("Glass", Vector3(-18.0, 9.5, 6.3), Vector3(62.0, 13.0, 0.5))
	lm.spire("Bronze", Vector3(-18.0, 19.0, -16.0), 16.0, 9.0, 2.5, 4)
	lm.box("WarmLamp", Vector3(-18.0, 18.8, 6.2), Vector3(64.0, 0.4, 0.4))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(24.0, 2.0, 48.0), Vector3(24.0, 10.0, 24.0), 60.0, 1.2],
	])

static func padang_ensemble(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F4F1EA", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#CFC9BC", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A84A32", 2.0))
	lm.use("Shutter", LandmarkMaterials.pbr("wood", "#2E5840", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B5566"))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#5A4C3E", 2.0, 0.35, 0.72))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE0A4", 1.7))

	# 1. Singapore Cricket Club (1884 Victorian colonial clubhouse, south end of Padang, x = -195 m).
	var scc := Vector3(-195.0, 0.0, 0.0)
	lm.box("White", scc + Vector3(0.0, 5.2, 0.0), Vector3(33.0, 10.4, 65.0))
	lm.box("Stone", scc + Vector3(0.0, 5.4, 0.0), Vector3(34.2, 0.55, 66.2))
	lm.box("Stone", scc + Vector3(0.0, 10.6, 0.0), Vector3(35.0, 0.8, 67.0))
	LandmarkSgKit.hipped_roof(lm, "Roof", scc + Vector3(0.0, 11.0, 0.0), 37.6, 69.6, 4.8, 12.0)
	# Central gabled Victorian pavilion with verandah balustrade on both front (+X Padang) and rear (-X).
	for fx: float in [-1.0, 1.0]:
		LandmarkSgKit.colonnade(lm, "White", scc + Vector3(fx * 17.8, 0.0, -29.0), scc + Vector3(fx * 17.8, 0.0, 29.0), 9.8, 0.38, 11)
		lm.box("White", scc + Vector3(fx * 17.8, 5.2, 0.0), Vector3(0.55, 1.1, 61.0))
		LandmarkSgKit.pediment_prism(lm, "White", "Roof", scc + Vector3(fx * 16.5, 10.8, 0.0), 20.0, 4.4, 5.6, false)
		for j in 10:
			var wz := -27.0 + float(j) * 6.0
			lm.box("Glass", scc + Vector3(fx * 16.65, 3.0, wz), Vector3(0.4, 3.0, 2.2))
			lm.box("Shutter", scc + Vector3(fx * 16.65, 8.0, wz), Vector3(0.4, 3.0, 2.2))
	# Short end facades (±Z) with windows & shutters so side views are fully articulated.
	for fz: float in [-1.0, 1.0]:
		for i in 5:
			var wx := -12.0 + float(i) * 6.0
			lm.box("Glass", scc + Vector3(wx, 3.0, fz * 32.65), Vector3(2.2, 3.0, 0.4))
			lm.box("Shutter", scc + Vector3(wx, 8.0, fz * 32.65), Vector3(2.2, 3.0, 0.4))
		LandmarkSgKit.pediment_prism(lm, "White", "Roof", scc + Vector3(0.0, 10.8, fz * 32.5), 14.0, 3.0, 3.6, true)

	# 2. Singapore Recreation Club (north end of Padang, x = +195 m).
	var src := Vector3(195.0, 0.0, 0.0)
	lm.box("White", src + Vector3(0.0, 5.6, 0.0), Vector3(36.0, 11.2, 71.0))
	lm.box("Stone", src + Vector3(0.0, 5.8, 0.0), Vector3(37.2, 0.55, 72.2))
	lm.box("Stone", src + Vector3(0.0, 11.4, 0.0), Vector3(38.0, 0.8, 73.0))
	LandmarkSgKit.hipped_roof(lm, "Roof", src + Vector3(0.0, 11.8, 0.0), 40.4, 75.4, 4.6, 13.0)
	for fx: float in [-1.0, 1.0]:
		LandmarkSgKit.colonnade(lm, "White", src + Vector3(fx * 19.2, 0.0, -31.0), src + Vector3(fx * 19.2, 0.0, 31.0), 10.6, 0.4, 11)
		LandmarkSgKit.pediment_prism(lm, "White", "Roof", src + Vector3(fx * 18.0, 11.6, 0.0), 22.0, 4.4, 5.6, false)
		for j in 11:
			var wz := -30.0 + float(j) * 6.0
			lm.box("Glass", src + Vector3(fx * 18.15, 3.2, wz), Vector3(0.4, 3.2, 2.2))
			lm.box("Shutter", src + Vector3(fx * 18.15, 8.6, wz), Vector3(0.4, 3.2, 2.2))
	for fz: float in [-1.0, 1.0]:
		for i in 5:
			var wx := -12.0 + float(i) * 6.0
			lm.box("Glass", src + Vector3(wx, 3.2, fz * 35.65), Vector3(2.2, 3.2, 0.4))
			lm.box("Shutter", src + Vector3(wx, 8.6, fz * 35.65), Vector3(2.2, 3.2, 0.4))

	# 3. The Cenotaph (Esplanade Park east of Padang, z = +122 m, 18.0 m stepped stone obelisk).
	var cen := Vector3(-24.0, 0.0, 122.0)
	lm.box("Stone", cen + Vector3(0.0, 1.2, 0.0), Vector3(14.0, 2.4, 14.0))
	lm.box("Stone", cen + Vector3(0.0, 3.5, 0.0), Vector3(8.5, 2.2, 8.5))
	lm.frustum("Stone", cen + Vector3(0.0, 4.6, 0.0), 3.4, 1.8, 12.2, 4)
	lm.box("Bronze", cen + Vector3(0.0, 17.4, 0.0), Vector3(2.4, 1.2, 2.4))
	lm.box("WarmLamp", cen + Vector3(0.0, 4.8, 0.0), Vector3(5.4, 0.35, 5.4))

	# 4. Lim Bo Seng Memorial (octagonal bronze-roofed pagoda in Esplanade Park, z = +125 m).
	var lbs := Vector3(52.0, 0.0, 125.0)
	lm.frustum("Stone", lbs, 5.8, 5.0, 2.0, 8)
	lm.frustum("White", lbs + Vector3(0.0, 2.0, 0.0), 3.2, 2.8, 5.5, 8)
	lm.spire("Bronze", lbs + Vector3(0.0, 7.5, 0.0), 4.6, 4.2, 0.4, 8)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[cen + Vector3(0.0, 2.0, 12.0), cen + Vector3(0.0, 12.0, 0.0), 50.0, 1.4],
	])

static func civilian_war_memorial(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#F2F1EC", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C8C4BA", 3.0))
	lm.use("Pool", LandmarkMaterials.pool_water())
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#5E5042", 2.0, 0.35, 0.72))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFF0CE", 1.8))

	# Terraced park podium & reflecting pool.
	lm.box("Stone", Vector3(0.0, 0.9, 0.0), Vector3(38.0, 1.8, 38.0))
	lm.box("Pool", Vector3(0.0, 1.9, 0.0), Vector3(24.0, 0.3, 24.0))
	lm.frustum("Bronze", Vector3(0.0, 2.0, 0.0), 2.4, 1.8, 2.8, 12)
	# Four identical slender tapering 67 m white concrete pillars ("The Four Chopsticks").
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var px := sx * 3.8
			var pz := sz * 3.8
			lm.frustum("White", Vector3(px, 1.8, pz), 2.1, 1.05, 65.2, 4)
			lm.box("WarmLamp", Vector3(px, 2.4, pz), Vector3(2.8, 0.4, 2.8))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.0, 2.5, 16.0), Vector3(0.0, 38.0, 0.0), 50.0, 1.5],
		[Vector3(-16.0, 2.5, -16.0), Vector3(0.0, 38.0, 0.0), 50.0, 1.5],
	])
