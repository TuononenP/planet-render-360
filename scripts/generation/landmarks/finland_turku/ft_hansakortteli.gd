class_name FtHansakortteli
extends RefCounted

## Hansa Shopping Centre Block (Hansakortteli: Kultatalo, Antintalo 1891,
## St. Erik's corner & skylit interior mall roofs) forming the entire SW
## frontage of Turku Market Square (Kauppatori) along Aurakatu & Yliopistonkatu.
## Origin at OSM way 315581388 centroid (60.451115 N, 22.265093 E), yaw_deg -35.3:
##   +X bears 54.7° (NE, Aurakatu front facing directly onto Kauppatori)
##   +Z bears 144.7° (SE, Eerikinkatu / Antintalo 1891 Neo-Renaissance front)
##   -Z bears 324.7° (NW, Yliopistonkatu pedestrian Kävelykatu mall front)
##   -X bears 234.7° (SW, Kristiinankatu flank)
##
## Architectural & facade spec (OSM way 315581388 59.6 x 32.9 m + way 733547251
## 59.5 x 26.3 m + way 315581385 45.0 x 29.6 m; turku_lod2 height 29.7 m):
## - Multi-era urban block seated on a dark granite plinth (FOUND = -1.6 m):
##   1. Kultatalo / St. Erik's corner (Kauppatori +X & Yliopistonkatu -Z):
##      6-storey modernist pale-stone & bronze-mullioned commercial block
##      (y = 0..24.5 m) with recessed glazed Hansa main entrance portal facing
##      Kauppatori and rooftop penthouse rising to 29.7 m (matching LoD2 29.7 m).
##   2. Antintalo (1891, Karl Viktor Reinius, Eerikinkatu +Z wing): ornate
##      3.5-storey Neo-Renaissance warm yellow-ochre & cream-plaster palace
##      with rusticated ground floor, arched upper windows, triangular window
##      pediments, cornice, and pitched dark-slate/copper roof with dormers.
##   3. Interior Hansa mall court: glazed barrel/gable clerestory atrium
##      skylights spanning between the wings, glowing warmly at night!
## - Night illumination: warm glazed Hansa entrances, glowing skylit mall
##   atrium roofs, Antintalo facade floodlights (LandmarkLights.FLOOD_META).

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("StoneLight", LandmarkMaterials.pbr("limestone", "#DDD6C8", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#DEC288", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F2EDE2", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6C6964", 2.5))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2E3236", 0.45, 0.55))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3D4245", 2.0))
	lm.use("Copper", LandmarkFrKit.copper("#4D7866"))
	lm.use("Glass", LandmarkMaterials.glass("#23303A"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.90))

	_build_kultatalo_wing(lm)
	_build_antintalo_wing(lm)
	_build_mall_skylights(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(38.0, 1.0, -4.0), Vector3(28.0, 12.0, -4.0), 38.0, 1.00, 70.0, warm],
		[Vector3(2.0, 1.0, 37.0), Vector3(2.0, 10.0, 26.0), 38.0, 1.00, 65.0, warm],
		[Vector3(-2.0, 1.0, -34.0), Vector3(-2.0, 12.0, -24.0), 38.0, 0.90, 65.0, warm],
	])

static func _build_kultatalo_wing(lm: LandmarkMesh) -> void:
	# Kultatalo & Yliopistonkatu / Kauppatori 6-storey commercial wing (x = -30..30, z = -26..4).
	LandmarkFrKit.rect(lm, "Granite", -30.5, 30.5, -26.5, 27.0, FOUND, 0.8)
	LandmarkFrKit.rect(lm, "StoneLight", -30.0, 30.0, -26.0, 4.0, 0.8, 24.4)
	LandmarkFrParts.band(lm, "Trim", -30.0, 30.0, -26.0, 4.0, 4.8, 0.40, 0.18)
	LandmarkFrParts.band(lm, "Trim", -30.0, 30.0, -26.0, 4.0, 23.8, 0.60, 0.22)
	# Recessed glazed ground-floor Hansa shopfronts & grand Kauppatori entrance (+X).
	LandmarkFrKit.rect(lm, "Glass", 29.7, 30.15, -24.0, 2.5, 0.8, 4.8)
	LandmarkFrKit.rect(lm, "WarmGlow", 29.55, 29.95, -23.6, 2.1, 1.0, 4.4)
	LandmarkFrKit.rect(lm, "Glass", -28.0, 28.0, -26.15, -25.7, 0.8, 4.8)
	LandmarkFrKit.rect(lm, "WarmGlow", -27.5, 27.5, -25.95, -25.55, 1.0, 4.4)
	# Glazed cantilevered Hansa entrance canopies on Aurakatu (+X) & Yliopistonkatu (-Z).
	LandmarkFrKit.rect(lm, "DarkMetal", 30.0, 33.2, -14.5, -6.5, 4.6, 5.05)
	LandmarkFrKit.rect(lm, "Glass", 30.1, 33.0, -14.2, -6.8, 4.95, 5.15)
	LandmarkFrKit.rect(lm, "DarkMetal", -8.0, 8.0, -29.0, -26.0, 4.6, 5.05)
	# Upper 5-storey rhythmic commercial window grid.
	LandmarkFrParts.facade(lm, "StoneLight", "Glass", Vector3(30.0, 5.6, -24.5), Vector3(30.0, 5.6, 2.5),
		Vector3.RIGHT, 18.0, 8, 5, Vector2(2.1, 2.1), 0.65, 3.55, 0.24)
	LandmarkFrParts.facade(lm, "StoneLight", "Glass", Vector3(-28.5, 5.6, -26.0), Vector3(28.5, 5.6, -26.0),
		Vector3.FORWARD, 18.0, 15, 5, Vector2(2.2, 2.1), 0.65, 3.55, 0.24)
	LandmarkFrParts.facade(lm, "StoneLight", "Glass", Vector3(-30.0, 5.6, 2.5), Vector3(-30.0, 5.6, -24.5),
		Vector3.LEFT, 18.0, 8, 5, Vector2(2.1, 2.1), 0.65, 3.55, 0.24)
	# Stepped rooftop mechanical & office penthouse rising to 29.7 m.
	LandmarkFrKit.rect(lm, "StoneLight", -22.0, 22.0, -20.0, -6.0, 24.4, 29.3)
	LandmarkFrKit.rect(lm, "Roof", -22.2, 22.2, -20.2, -5.8, 29.3, 29.7)
	LandmarkFrParts.facade(lm, "StoneLight", "Glass", Vector3(-20.0, 25.2, -20.0), Vector3(20.0, 25.2, -20.0),
		Vector3.FORWARD, 3.8, 10, 1, Vector2(2.4, 2.1), 0.5, 3.2, 0.18)

static func _build_antintalo_wing(lm: LandmarkMesh) -> void:
	# Antintalo (1891 Neo-Renaissance wing along Eerikinkatu +Z, x = -28..28, z = 12..26.5).
	var x0 := -28.0
	var x1 := 28.0
	var z0 := 12.0
	var z1 := 26.5
	LandmarkFrKit.rect(lm, "Granite", x0 - 0.3, x1 + 0.3, z0, z1 + 0.3, FOUND, 1.2)
	LandmarkFrKit.rect(lm, "Ochre", x0, x1, z0, z1, 1.2, 15.0)
	LandmarkFrParts.band(lm, "Trim", x0, x1, z0, z1, 5.0, 0.42, 0.18)
	LandmarkFrParts.band(lm, "Trim", x0, x1, z0, z1, 10.2, 0.32, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, z0, z1, 14.3, 0.70)
	LandmarkFrKit.hip(lm, "Copper", x0, x1, z0, z1, 15.0, 4.4, 0.50)
	# Ground-floor arched shopfront arcade + two upper ornate Neo-Renaissance storeys (+Z).
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x0 + 3.0, 1.2, z1), Vector3(x1 - 3.0, 1.2, z1),
		Vector3.BACK, 10, 3.0, 3.4, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x0 + 3.0, 6.2, z1), Vector3(x1 - 3.0, 6.2, z1),
		Vector3.BACK, 10, 1.85, 3.0, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x0 + 3.0, 10.9, z1), Vector3(x1 - 3.0, 10.9, z1),
		Vector3.BACK, 10, 1.75, 2.5, LandmarkFrParts.HEAD_FLAT, 0.22, 0.12, 1)
	# Central projecting Neo-Renaissance pedimented gable on Antintalo (+Z).
	LandmarkFrKit.rect(lm, "Ochre", -7.5, 7.5, z1 - 0.5, z1 + 0.9, 1.2, 15.8)
	LandmarkFrKit.gable(lm, "Copper", -7.5, 7.5, z1 - 2.0, z1 + 0.9, 15.8, 3.6, 0.35, "Trim", 0)
	# Roof dormers along Antintalo's Eerikinkatu roof slope.
	for dx: float in [-20.0, -12.0, 12.0, 20.0]:
		LandmarkFrParts.dormer(lm, "Trim", "Copper", "Glass", Vector3(dx, 16.0, z1 - 1.2), Vector3.BACK, 1.8, 1.8, 1.6)

static func _build_mall_skylights(lm: LandmarkMesh) -> void:
	# Interior Hansa shopping arcade linking Kultatalo & Antintalo (z = 4.0..12.0).
	LandmarkFrKit.rect(lm, "StoneLight", -28.0, 28.0, 4.0, 12.0, 0.8, 13.5)
	LandmarkFrKit.rect(lm, "Glass", -26.0, 26.0, 5.2, 10.8, 13.5, 14.8)
	LandmarkFrKit.rect(lm, "WarmGlow", -25.5, 25.5, 5.5, 10.5, 13.6, 14.6)
	LandmarkFrKit.gable(lm, "Glass", -26.0, 26.0, 5.2, 10.8, 14.8, 2.2, 0.20, "DarkMetal", 1)
	for i in 13:
		var rx := lerpf(-26.0, 26.0, float(i) / 12.0)
		lm.beam("DarkMetal", Vector3(rx, 14.8, 5.2), Vector3(rx, 17.0, 8.0), 0.14, 0.16)
		lm.beam("DarkMetal", Vector3(rx, 14.8, 10.8), Vector3(rx, 17.0, 8.0), 0.14, 0.16)
