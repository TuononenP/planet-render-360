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
	lm.box("White", Vector3(24.0, 6.5, 22.0), Vector3(44.0, 13.0, 28.0))
	lm.box("Roof", Vector3(24.0, 14.8, 22.0), Vector3(46.0, 3.6, 30.0))
	LandmarkSgKit.colonnade(lm, "White", Vector3(12.0, 0.0, 37.0), Vector3(36.0, 0.0, 37.0), 11.0, 0.45, 6)
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
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C8C2B6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A84A32", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#5A4C3E", 2.0, 0.35, 0.72))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE0A4", 1.7))

	# 1. Singapore Cricket Club (south end of Padang, x = -195 m).
	var scc := Vector3(-195.0, 0.0, 0.0)
	lm.box("White", scc + Vector3(0.0, 5.5, 0.0), Vector3(36.0, 11.0, 68.0))
	lm.box("Roof", scc + Vector3(0.0, 13.0, 0.0), Vector3(38.0, 4.0, 70.0))
	LandmarkSgKit.colonnade(lm, "White", scc + Vector3(19.0, 0.0, -28.0), scc + Vector3(19.0, 0.0, 28.0), 9.5, 0.42, 10)

	# 2. Singapore Recreation Club (north end of Padang, x = +195 m).
	var src := Vector3(195.0, 0.0, 0.0)
	lm.box("White", src + Vector3(0.0, 6.0, 0.0), Vector3(38.0, 12.0, 74.0))
	lm.box("Roof", src + Vector3(0.0, 13.8, 0.0), Vector3(40.0, 3.6, 76.0))
	LandmarkSgKit.colonnade(lm, "White", src + Vector3(-20.0, 0.0, -30.0), src + Vector3(-20.0, 0.0, 30.0), 10.5, 0.45, 10)

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
