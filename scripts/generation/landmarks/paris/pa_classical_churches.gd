class_name LandmarkPaClassicalChurches
extends RefCounted

## Major Parisian temples & churches (`PA-4`):
## - Église de la Madeleine (Pierre-Alexandre Vignon, 1842; 30 m 52-column Corinthian Greek temple)
## - Église Saint-Sulpice (Servandoni, 1777; 73 m classical loggia & asymmetrical twin towers)
## - Église Saint-Eustache (Les Halles, 1637; 45 m Gothic-Renaissance basilica, fixes OSM h=10!)

## Église de la Madeleine (30 m; 108 x 43 m):
## Peripteral Corinthian Roman-Greek temple closing Rue Royale from Place de la Concorde:
## 52 twenty-metre fluted columns on a 7 m podium, grand staircase, sculpted Last Judgement pediment.
static func eglise_madeleine(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD0B4", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C4B79C", 3.2))
	lm.use("Copper", LandmarkPaKit.verdigris("#507B6B"))
	lm.use("Bronze", LandmarkPaKit.bronze("#3B4239"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# 7 m classical stylobate podium & broad front staircase facing Rue Royale (+Z)
	lm.box("Ashlar", Vector3(0.0, 3.5, 0.0), Vector3(44.0, 7.0, 102.0))
	for k in 10:
		var t := float(k) / 9.0
		lm.box("Ashlar", Vector3(0.0, 0.35 * float(k + 1), 59.0 - t * 8.0), Vector3(42.0 - t * 2.0, 0.7, 1.4))
	# Inner blind cella nave walls (31 x 78 m) + bronze doors
	lm.box("Stone", Vector3(0.0, 15.0, 0.0), Vector3(31.0, 16.5, 76.0))
	lm.box("Bronze", Vector3(0.0, 12.5, 38.2), Vector3(6.8, 10.5, 0.4))
	# 52 giant 17 m Corinthian columns encircling the entire temple (8 front/back, 18 per long flank)
	LandmarkPaKit.colonnade_x(lm, "Stone", -18.5, 18.5, 7.0, 48.0, 8, 15.2, 0.76)
	LandmarkPaKit.colonnade_x(lm, "Stone", -18.5, 18.5, 7.0, -48.0, 8, 15.2, 0.76)
	LandmarkPaKit.colonnade_z(lm, "Stone", -18.5, 7.0, -42.5, 42.5, 16, 15.2, 0.76)
	LandmarkPaKit.colonnade_z(lm, "Stone", 18.5, 7.0, -42.5, 42.5, 16, 15.2, 0.76)
	# Entablature & shallow copper gable roof + sculpted Last Judgement triangular pediments (30.0 m)
	lm.box("Stone", Vector3(0.0, 23.0, 0.0), Vector3(42.0, 2.2, 100.0))
	lm.gable("Copper", Vector3(0.0, 24.1, 0.0), 40.5, 98.0, 5.9, Basis(), 0.5, "Stone")
	LandmarkPaKit.pediment_z(lm, "Stone", 0.0, 24.1, 49.0, 41.5, 5.8, 2.2)
	LandmarkPaKit.pediment_z(lm, "Stone", 0.0, 24.1, -49.0, 41.5, 5.8, 2.2)
	for lx in [-22.0, 22.0]:
		LandmarkPaKit.paris_lamp(lm, "Bronze", "Lamp", Vector3(float(lx), 0.0, 60.0), 4.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 2.0, 66.0), Vector3(-14.0, 18.0, 48.0), 58.0, 1.05, 65.0],
		[Vector3(18.0, 2.0, 66.0), Vector3(14.0, 18.0, 48.0), 58.0, 1.05, 65.0],
		[Vector3(-32.0, 2.0, 0.0), Vector3(-18.0, 16.0, 0.0), 66.0, 0.9, 68.0],
		[Vector3(32.0, 2.0, 0.0), Vector3(18.0, 16.0, 0.0), 66.0, 0.9, 68.0],
	])

## Église Saint-Sulpice (73 m north tower, 68 m south tower; 118 x 57 m):
## Servandoni's classical two-tier Doric & Ionic columned west loggia, unmistakable mismatched
## twin bell towers, and Fontaine Saint-Sulpice in the square.
static func saint_sulpice(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#D7CBB0", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#BDB096", 3.2))
	lm.use("Slate", LandmarkPaKit.slate("#46505A", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Massive classical nave & transepts (nave along Z, west loggia facade at -Z)
	lm.box("Stone", Vector3(0.0, 16.0, 14.0), Vector3(44.0, 32.0, 86.0))
	lm.box("Stone", Vector3(0.0, 16.0, 18.0), Vector3(58.0, 32.0, 22.0))
	lm.gable("Slate", Vector3(0.0, 32.0, 14.0), 26.0, 86.0, 9.0, Basis(), 0.6, "Stone")
	# Monumental two-tier classical west facade loggia (-Z, 56 m wide, 38 m tall)
	lm.box("Stone", Vector3(0.0, 18.5, -34.0), Vector3(56.0, 37.0, 16.0))
	LandmarkPaKit.colonnade_x(lm, "Stone", -24.0, 24.0, 1.5, -42.5, 10, 16.0, 0.72)
	lm.box("Stone", Vector3(0.0, 18.4, -41.5), Vector3(55.0, 2.0, 4.5))
	LandmarkPaKit.colonnade_x(lm, "Stone", -24.0, 24.0, 19.4, -42.5, 10, 15.0, 0.62)
	lm.box("Stone", Vector3(0.0, 36.2, -41.5), Vector3(57.0, 2.2, 4.8))
	# Iconic ASYMMETRICAL twin towers: taller ornate North Tower (-X, 73.0 m) vs shorter South Tower (+X, 68.0 m)
	# North tower (Chalgrin, cylindrical upper colonnade & dome reaching 73.0 m)
	lm.box("Stone", Vector3(-21.5, 45.0, -34.0), Vector3(12.5, 16.0, 12.5))
	lm.frustum("Stone", Vector3(-21.5, 53.0, -34.0), 5.4, 5.2, 13.0, 16)
	lm.lathe("Stone", Vector3(-21.5, 66.0, -34.0), LandmarkWestKit.dome_prof(5.2, 5.2, 8, 1.1), 16)
	lm.frustum("Stone", Vector3(-21.5, 71.0, -34.0), 0.7, 0.15, 2.0, 8)
	# South tower (Maclaurin, octagonal uncompleted top reaching 68.0 m)
	lm.box("Stone", Vector3(21.5, 45.0, -34.0), Vector3(12.5, 16.0, 12.5))
	lm.frustum("Stone", Vector3(21.5, 53.0, -34.0), 5.0, 4.8, 11.5, 8)
	lm.frustum("Ashlar", Vector3(21.5, 64.5, -34.0), 4.6, 3.2, 3.5, 8)
	LandmarkPaKit.win_grid_x(lm, "Glass", -22.15, -18.0, 48.0, [11.0, 23.0], 8, 2.4, 5.2)
	LandmarkPaKit.win_grid_x(lm, "Glass", 22.15, -18.0, 48.0, [11.0, 23.0], 8, 2.4, 5.2)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 2.0, -58.0), Vector3(-20.0, 38.0, -38.0), 62.0, 1.05, 85.0],
		[Vector3(22.0, 2.0, -58.0), Vector3(20.0, 36.0, -38.0), 62.0, 1.05, 85.0],
	])

## Église Saint-Eustache (Les Halles; way 53762963, fixes OSM `height=10` bug!; 45 m; 105 x 44 m):
## Towering Gothic-structure / Renaissance-detail basilica with flying buttresses, steep slate
## gable roof, classical pedimented west facade with single finished belfry tower, and crossing flèche.
static func saint_eustache(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#D5C8AC", 3.4))
	lm.use("Slate", LandmarkPaKit.slate("#465058", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Double-aisle body (20 m) + towering clerestory (33 m) + steep slate roof (42 m) along X
	lm.box("Stone", Vector3(0.0, 10.0, 0.0), Vector3(96.0, 20.0, 42.0))
	lm.box("Stone", Vector3(0.0, 26.5, 0.0), Vector3(96.0, 13.0, 19.0))
	lm.gable("Slate", Vector3(0.0, 33.0, 0.0), 19.4, 96.0, 9.5, Basis(Vector3.UP, PI * 0.5), 0.7, "Stone")
	# Transept cross-wing
	lm.box("Stone", Vector3(8.0, 16.5, 0.0), Vector3(18.0, 33.0, 48.0))
	lm.gable("Slate", Vector3(8.0, 33.0, 0.0), 18.4, 48.0, 9.5, Basis(), 0.7, "Stone")
	# Flying buttresses & pinnacles down both nave flanks
	for k in 9:
		var bx := -38.0 + float(k) * 9.5
		if absf(bx - 8.0) < 9.5:
			continue
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(bx, 13.0, float(sz) * 21.5), Vector3(2.0, 26.0, 2.2))
			lm.beam("Stone", Vector3(bx, 24.0, float(sz) * 20.5), Vector3(bx, 29.0, float(sz) * 9.6), 1.0, 0.9)
	# Classical 18th-c. west facade (-X) with pediment & single completed southwest belfry (45.0 m!)
	lm.box("Stone", Vector3(-49.0, 16.0, 0.0), Vector3(6.0, 32.0, 38.0))
	LandmarkPaKit.colonnade_z(lm, "Stone", -52.6, 1.5, -14.0, 14.0, 6, 14.0, 0.6)
	LandmarkPaKit.colonnade_z(lm, "Stone", -52.6, 16.5, -10.0, 10.0, 4, 12.0, 0.52)
	lm.box("Stone", Vector3(-49.0, 38.0, 12.0), Vector3(8.5, 12.0, 8.5))
	lm.frustum("Stone", Vector3(-49.0, 43.2, 12.0), 4.0, 1.0, 1.8, 8)
	# Crossing copper/slate lantern flèche
	lm.frustum("Slate", Vector3(8.0, 40.0, 0.0), 2.4, 0.2, 5.0, 8)
	LandmarkPaKit.win_grid_z(lm, "Glass", -40.0, 40.0, 21.1, [10.0], 8, 3.0, 8.5)
	LandmarkPaKit.win_grid_z(lm, "Glass", -40.0, 40.0, -21.1, [10.0], 8, 3.0, 8.5)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-68.0, 2.0, 0.0), Vector3(-50.0, 24.0, 0.0), 62.0, 1.0, 68.0],
		[Vector3(0.0, 2.0, 36.0), Vector3(0.0, 22.0, 18.0), 68.0, 0.9, 68.0],
	])
