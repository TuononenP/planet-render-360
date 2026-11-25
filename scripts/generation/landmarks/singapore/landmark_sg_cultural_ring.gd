class_name LandmarkSgCulturalRing
extends RefCounted

## Civic Cultural Ring & Kallang Outer Icon (SG-3.17–3.18):
## - `chijmes` (36 m, way 97666818): 1904 crisp white neo-Gothic convent chapel & spire.
## - `armenian_church` (20 m, way 172368093): 1835 white neoclassical Doric rotunda chapel.
## - `central_fire_station` (34 m, way 172368086): 1908 "Blood & Bandage" red-brick/white-plaster
##   firehouse with arched red appliance bay doors & 34 m striped hose/lookout tower.
## - `national_museum` (30 m, way 32342169): 1887 neo-Palladian museum crowned by silver fish-scale dome.
## - `national_stadium` (82 m): 310 m free-spanning white/silver retractable dome (Singapore Sports Hub).

static func chijmes(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F6F5F0", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4C525A", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B5C78"))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE2A6", 1.8))

	lm.box("White", Vector3(0.0, 7.5, 0.0), Vector3(44.0, 15.0, 16.0))
	lm.box("Roof", Vector3(0.0, 17.5, 0.0), Vector3(45.0, 5.0, 13.0))
	for i in 5:
		var bx := -16.0 + float(i) * 8.0
		for s: float in [-1.0, 1.0]:
			lm.box("White", Vector3(bx, 7.5, s * 8.6), Vector3(1.2, 15.0, 1.4))
			lm.spire("White", Vector3(bx, 15.0, s * 8.6), 0.55, 2.8, 0.06, 4)
	# Slender Gothic flèche/spire reaching 36.0 m.
	lm.box("White", Vector3(-16.0, 14.0, 0.0), Vector3(7.0, 12.0, 7.0))
	lm.spire("White", Vector3(-16.0, 20.0, 0.0), 3.0, 16.0, 0.14, 8)
	lm.box("Glass", Vector3(-22.2, 9.5, 0.0), Vector3(0.4, 6.0, 5.5))
	lm.box("WarmLamp", Vector3(-16.0, 19.5, 0.0), Vector3(7.4, 0.4, 7.4))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-28.0, 2.0, 12.0), Vector3(-16.0, 22.0, 0.0), 55.0, 1.4],
	])

static func armenian_church(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F6F5F0", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4630", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE2A6", 1.7))

	lm.box("White", Vector3(0.0, 4.5, 0.0), Vector3(24.0, 9.0, 18.0))
	LandmarkSgKit.colonnade(lm, "White", Vector3(-7.0, 0.0, 10.5), Vector3(7.0, 0.0, 10.5), 8.2, 0.38, 4)
	lm.box("Roof", Vector3(0.0, 10.2, 0.0), Vector3(25.0, 2.4, 19.0))
	lm.frustum("White", Vector3(0.0, 11.0, 0.0), 4.2, 3.8, 4.5, 12)
	lm.spire("White", Vector3(0.0, 15.5, 0.0), 2.4, 3.8, 0.12, 8)
	lm.box("Gold", Vector3(0.0, 19.6, 0.0), Vector3(0.2, 0.8, 0.2))
	lm.box("WarmLamp", Vector3(0.0, 11.2, 0.0), Vector3(6.5, 0.35, 6.5))
	lm.commit(model)

static func central_fire_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("RedBrick", LandmarkMaterials.pbr("brick", "#A83A2C", 2.0))
	lm.use("WhiteBand", LandmarkMaterials.pbr("limestone", "#F2EFE8", 2.0))
	lm.use("RedDoor", LandmarkMaterials.paint("#B82420", 0.35, 0.2))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9C4430", 2.0))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD890", 1.8))

	# Iconic "Blood and Bandage" alternating red-brick & white-plaster Edwardian firehouse.
	lm.box("RedBrick", Vector3(0.0, 7.0, 0.0), Vector3(76.0, 14.0, 32.0))
	for by: float in [2.6, 5.8, 9.0, 12.2]:
		lm.box("WhiteBand", Vector3(0.0, by, 0.0), Vector3(76.6, 0.9, 32.6))
	lm.box("Roof", Vector3(0.0, 15.6, 0.0), Vector3(78.0, 3.2, 34.0))
	# Red appliance bay doors on front (+Z).
	for i in 5:
		lm.box("RedDoor", Vector3(-24.0 + float(i) * 12.0, 2.8, 16.4), Vector3(6.8, 5.2, 0.5))
	# 34 m striped hose & lookout tower.
	lm.box("RedBrick", Vector3(26.0, 17.0, 6.0), Vector3(9.5, 30.0, 9.5))
	for ty: float in [16.0, 20.0, 24.0, 28.0]:
		lm.box("WhiteBand", Vector3(26.0, ty, 6.0), Vector3(9.9, 0.9, 9.9))
	lm.box("WhiteBand", Vector3(26.0, 32.6, 6.0), Vector3(10.6, 1.4, 10.6))
	lm.spire("Roof", Vector3(26.0, 33.2, 6.0), 4.6, 0.8, 2.2, 4)
	lm.box("WarmLamp", Vector3(26.0, 31.4, 6.0), Vector3(10.2, 0.4, 10.2))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(26.0, 2.5, 24.0), Vector3(26.0, 22.0, 6.0), 58.0, 1.3],
	])

static func national_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F4F1EA", 3.0))
	lm.use("SilverDome", LandmarkMaterials.pbr("sheet_metal", "#CFD4DA", 2.0, 0.25, 0.85))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4632", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#5A8296"))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE2A4", 1.8))

	# 1887 neo-Palladian wings flanking the central rotunda (way 32342169).
	lm.box("White", Vector3(0.0, 7.5, 0.0), Vector3(142.0, 15.0, 36.0))
	lm.box("Roof", Vector3(0.0, 16.8, 0.0), Vector3(144.0, 3.6, 38.0))
	LandmarkSgKit.colonnade(lm, "White", Vector3(-62.0, 0.0, 19.5), Vector3(62.0, 0.0, 19.5), 13.5, 0.55, 18)
	# Iconic silver-plated fish-scale rotunda dome & stained-glass drum (reaches 30.0 m).
	lm.frustum("White", Vector3(0.0, 15.0, 2.0), 11.5, 10.8, 5.2, 20)
	lm.frustum("Glass", Vector3(0.0, 16.0, 2.0), 11.2, 11.0, 3.2, 20)
	LandmarkAsiaSouthUtil.dome(lm, "SilverDome", Vector3(0.0, 20.2, 2.0), 10.5, 8.2, 20, 10)
	lm.spire("SilverDome", Vector3(0.0, 28.2, 2.0), 0.9, 1.8, 0.1, 8)
	# Modern Glass Rotunda behind (-Z).
	lm.frustum("Glass", Vector3(0.0, 0.0, -34.0), 16.0, 16.0, 18.0, 20)
	lm.frustum("WarmLamp", Vector3(0.0, 19.8, 2.0), 11.4, 11.4, 0.45, 20)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 32.0), Vector3(0.0, 20.0, 4.0), 65.0, 1.4],
	])

static func national_stadium(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shell", LandmarkMaterials.pbr("sheet_metal", "#E6E8EC", 3.0, 0.28, 0.72))
	lm.use("Rib", LandmarkMaterials.pbr("sheet_metal", "#C6CCD2", 2.0, 0.32, 0.78))
	lm.use("Bowl", LandmarkMaterials.pbr("concrete", "#D0CCC2", 3.0))
	lm.use("RimLamp", LandmarkMaterials.lit("#FF4C4C", 2.4))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFF0D0", 1.8))

	# 310 m diameter concrete stadium bowl + world's largest free-spanning white/silver dome (82 m).
	lm.frustum("Bowl", Vector3(0.0, 0.0, 0.0), 152.0, 146.0, 18.0, 32)
	LandmarkSgKit.loft_shell(lm, "Shell", Vector3(0.0, 17.5, 0.0), 154.0, 134.0, 64.0, 14, 32, 0.76)
	LandmarkSgKit.shell_arch_ribs(lm, "Rib", Vector3(0.0, 17.5, 0.0), 154.0, 134.0, 64.0, 6, 0.8, 2.4, 18, 0.76)
	lm.frustum("RimLamp", Vector3(0.0, 18.0, 0.0), 155.0, 155.0, 1.4, 32)
	lm.frustum("WarmLamp", Vector3(0.0, 74.0, 0.0), 42.0, 24.0, 2.0, 20)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 8.0, 168.0), Vector3(0.0, 56.0, 0.0), 70.0, 1.5],
	])
