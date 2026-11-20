class_name FtAboSvenskaTeater
extends RefCounted

## Åbo Svenska Teater (P.J. Gylich & C.L. Engel, 1839; renovated Chiewitz 1850s)
## — Finland's oldest theatre, on the Eerikinkatu / Aurakatu corner of Kauppatori.
## Origin at OSM way 1043097294 centroid (60.450751 N, 22.265932 E), yaw_deg -35.3:
##   +X bears 54.7° (NE, Aurakatu front facing Kauppatori)
##   +Z bears 144.7° (SE, Eerikinkatu front)
##   -Z bears 324.7° (NW, Hansakortteli glazed canopy link)
##   -X bears 234.7° (SW, stage/backstage wing)
##
## Architectural & facade spec (OSM way 1043097294 36.6 x 33.8 m, 2.5 lv,
## turku_lod2 nearest 18.3 m, 36° hipped/complex roof):
## - Pale Empire yellow neoclassical theatre block (36.0 x 33.0 m, eaves
##   12.8 m) on a grey-granite base (FOUND = -1.6 m):
##   * Rusticated ground-floor arcade base (y = 0.8..4.6 m) with round-arched
##     theatre lobby entrances & warm foyer glow along Aurakatu (+X) and
##     Eerikinkatu (+Z).
##   * Monumental piano nobile (y = 4.6..12.8 m) articulated by giant white
##     fluted Ionic pilasters framing tall round-arched ballroom/foyer windows
##     with moulded pediments and warm illuminated interiors.
##   * Crisp white entablature, dentil cornice, and patinated green-copper
##     hipped roof peaking at 18.3 m (matching LoD2 18.3 m) with central
##     pedimented theatre frontispiece facing Aurakatu / Kauppatori.
##   * Contemporary Hansakortteli glass-and-steel entrance canopy link on the
##     NW (-Z) side.
## - Night illumination: warm lobby/ballroom glow and upward Empire facade
##   floodlights (LandmarkLights.FLOOD_META).

const FOUND := -1.6
const BASE_H := 4.6
const EAVE_Y := 12.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E7CE82", 3.0))
	lm.use("Rustic", LandmarkMaterials.pbr("render", "#DDD2B4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F0E6", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8B8780", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4A7664"))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2E3338", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3624", 1.5))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A6", 0.90))

	_build_body(lm)
	_build_facades(lm)
	_build_hansa_link(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(24.5, 1.0, -5.0), Vector3(17.5, 8.5, -2.0), 34.0, 1.05, 55.0, warm],
		[Vector3(24.5, 1.0, 8.0), Vector3(17.5, 8.5, 5.0), 34.0, 1.05, 55.0, warm],
		[Vector3(2.0, 1.0, 24.0), Vector3(2.0, 8.5, 16.0), 36.0, 1.00, 55.0, warm],
	])

static func _build_body(lm: LandmarkMesh) -> void:
	# Granite plinth & rusticated ground-floor arcade base (-18..18 x -16.5..16.5).
	LandmarkFrKit.rect(lm, "Stone", -18.4, 18.4, -16.9, 16.9, FOUND, 0.85)
	LandmarkFrKit.rect(lm, "Rustic", -18.1, 18.1, -16.6, 16.6, 0.85, BASE_H)
	LandmarkFrParts.band(lm, "Trim", -18.1, 18.1, -16.6, 16.6, BASE_H - 0.35, 0.40, 0.20)
	# Empire yellow piano nobile & attic (y = 4.6..12.8 m).
	LandmarkFrKit.rect(lm, "Wall", -17.8, 17.8, -16.3, 16.3, BASE_H, EAVE_Y)
	LandmarkFrParts.cornice_ring(lm, "Trim", -17.8, 17.8, -16.3, 16.3, EAVE_Y - 0.75, 0.75)
	# Patinated green-copper hipped roof rising to 18.3 m (matching LoD2 18.3 m).
	LandmarkFrKit.hip(lm, "Copper", -17.8, 17.8, -16.3, 16.3, EAVE_Y, 5.5, 0.65)
	# Central shallow pedimented frontispiece facing Aurakatu / Kauppatori (+X).
	LandmarkFrKit.rect(lm, "Wall", 17.5, 18.35, -8.2, 8.2, BASE_H, EAVE_Y)
	LandmarkFrKit.gable(lm, "Copper", 16.0, 18.45, -8.4, 8.4, EAVE_Y, 2.5, 0.25, "Wall", 1)
	lm.beam("Trim", Vector3(18.52, EAVE_Y, -8.55), Vector3(18.52, EAVE_Y + 2.55, 0.0), 0.28, 0.28, Vector3.RIGHT)
	lm.beam("Trim", Vector3(18.52, EAVE_Y, 8.55), Vector3(18.52, EAVE_Y + 2.55, 0.0), 0.28, 0.28, Vector3.RIGHT)
	# Pair of Empire chimneys.
	for cz: float in [-9.0, 9.0]:
		LandmarkFrParts.chimney(lm, "Wall", Vector3(-6.0, 14.5, cz), 18.1, 1.3, 1.1)

static func _build_facades(lm: LandmarkMesh) -> void:
	# Aurakatu / Kauppatori front (+X): rusticated ground arches + 6 Ionic pilasters + tall arched ballroom windows.
	for i in 5:
		var z := lerpf(-12.0, 12.0, float(i) / 4.0)
		var is_door := i >= 1 and i <= 3
		LandmarkFrParts.opening(lm, "Trim", "Door" if is_door else "Glass",
			Vector3(18.1, 0.9, z), Vector3.RIGHT, 2.3, 3.3, LandmarkFrParts.HEAD_ROUND, 0.26, 0.16, 0)
		lm.box("WarmGlow", Vector3(18.12, 2.7, z), Vector3(0.04, 1.8, 1.6), Basis(), 0.0)
		var wx := 18.35 if absf(z) < 8.0 else 17.8
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 6.2, z), Vector3.RIGHT,
			2.1, 4.4, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 1)
		lm.box("WarmGlow", Vector3(wx + 0.03, 8.2, z), Vector3(0.04, 2.8, 1.5), Basis(), 0.0)
	for j in 6:
		var pz := lerpf(-14.8, 14.8, float(j) / 5.0)
		var px := 18.42 if absf(pz) < 8.4 else 17.88
		lm.box("Trim", Vector3(px, 8.4, pz), Vector3(0.24, 7.2, 0.62), Basis(), 0.0)
		lm.box("Trim", Vector3(px + 0.05, 11.95, pz), Vector3(0.34, 0.40, 0.85), Basis(), 0.0)
	# Eerikinkatu facade (+Z): 7 bays of rusticated arcade + Ionic pilasters & tall arched ballroom windows.
	for i in 7:
		var x := lerpf(-13.8, 13.8, float(i) / 6.0)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, 0.9, 16.6), Vector3.BACK,
			2.2, 3.2, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, 6.2, 16.3), Vector3.BACK,
			2.0, 4.4, LandmarkFrParts.HEAD_ROUND, 0.26, 0.15, 1)
		lm.box("WarmGlow", Vector3(x, 8.2, 16.32), Vector3(1.4, 2.6, 0.04), Basis(), 0.0)
	for j in 8:
		var px := lerpf(-16.1, 16.1, float(j) / 7.0)
		lm.box("Trim", Vector3(px, 8.4, 16.38), Vector3(0.58, 7.2, 0.22), Basis(), 0.0)
		lm.box("Trim", Vector3(px, 11.95, 16.42), Vector3(0.80, 0.38, 0.30), Basis(), 0.0)
	# Backstage (-X) simple rhythmic windows.
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-17.8, 6.4, -12.0), Vector3(-17.8, 6.4, 12.0),
		Vector3.LEFT, 5, 1.6, 3.2, LandmarkFrParts.HEAD_FLAT, 0.20, 0.12, 1)

static func _build_hansa_link(lm: LandmarkMesh) -> void:
	# Modern glazed Hansakortteli canopy & link passage along NW (-Z) flank.
	LandmarkFrKit.rect(lm, "Glass", -14.0, 14.0, -19.8, -16.3, 0.85, 6.2)
	LandmarkFrKit.rect(lm, "WarmGlow", -13.5, 13.5, -19.5, -16.6, 1.2, 5.8)
	LandmarkFrKit.rect(lm, "DarkMetal", -14.4, 14.4, -20.2, -16.2, 6.15, 6.55)
	for k in 8:
		var mx := lerpf(-14.0, 14.0, float(k) / 7.0)
		lm.beam("DarkMetal", Vector3(mx, 0.85, -19.8), Vector3(mx, 6.2, -19.8), 0.16, 0.16)
