class_name FtKivikukkaro
extends RefCounted

## Kivikukkaro (Aarne Ehojoki, 1975) — Yliopistonkatu / Kristiinankatu
## commercial palace on Turku's pedestrian boulevard (Kävelykatu).
## Origin at OSM way 100310223 centroid (60.450623 N, 22.260911 E), yaw_deg -35.3:
##   -Z bears 324.7° (NW, Yliopistonkatu Kävelykatu recessed street arcade)
##   +X bears 54.7° (NE, Kristiinankatu flank toward Hansakortteli)
##   +Z bears 144.7° (SE, Eerikinkatu rear facade)
##   -X bears 234.7° (SW, Humalistonkatu side)
##
## Architectural & facade spec (OSM way 100310223 48.7 x 66.4 m, 4-5 lv,
## turku_lod2 height 21.2 m):
## - Precast pale-stone / quartzite modular grid commercial palace (48 x 64 m)
##   seated on a dark granite plinth (FOUND = -1.6 m):
##   * Deeply recessed pedestrian street arcade along Yliopistonkatu (-Z) &
##     Kristiinankatu (+X) with massive precast concrete/quartzite columns and
##     warmly illuminated continuous ground-floor shopfronts (y = 0.6..4.8 m).
##   * Three bold precast modular upper commercial storeys (y = 4.8..16.2 m)
##     with deep coffered quartzite window bays and dark bronze frames.
##   * Stepped-back 5th-storey office penthouse & rooftop skylight monitors
##     peaking at 21.2 m (matching LoD2 21.2 m).
## - Night illumination: glowing recessed street arcade, lit modular windows,
##   and upward modernist facade floodlights (LandmarkLights.FLOOD_META).

const FOUND := -1.6
const MAIN_H := 16.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Quartzite", LandmarkMaterials.pbr("limestone", "#DDD8CE", 2.8))
	lm.use("QuartzShade", LandmarkMaterials.pbr("concrete", "#BEB9AE", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#5E6064", 2.5))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2A2E33", 0.45, 0.55))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4A4E52", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#202D36"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A6", 0.90))

	_build_arcade_and_grid(lm)
	_build_stepped_penthouse(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.93, 0.80)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.0, 1.0, -39.0), Vector3(-6.0, 10.0, -28.0), 38.0, 0.95, 65.0, warm],
		[Vector3(14.0, 1.0, -39.0), Vector3(12.0, 10.0, -28.0), 38.0, 0.95, 65.0, warm],
		[Vector3(31.0, 1.0, -4.0), Vector3(22.0, 10.0, -4.0), 38.0, 0.90, 65.0, warm],
	])

static func _build_arcade_and_grid(lm: LandmarkMesh) -> void:
	# Granite plinth (-24..24 x -32..32 m).
	LandmarkFrKit.rect(lm, "Granite", -24.3, 24.3, -32.3, 32.3, FOUND, 0.6)
	# Recessed ground-floor pedestrian arcade & glowing shopfronts (y = 0.6..4.8 m).
	LandmarkFrKit.rect(lm, "Glass", -21.2, 21.2, -29.2, 29.2, 0.6, 4.8)
	LandmarkFrKit.rect(lm, "WarmGlow", -20.8, 20.8, -28.8, 28.8, 0.9, 4.35)
	# Heavy precast quartzite arcade columns along all 4 street edges.
	for i in 9:
		var cx := lerpf(-23.2, 23.2, float(i) / 8.0)
		lm.box("Quartzite", Vector3(cx, 2.7, -31.2), Vector3(0.85, 4.2, 0.85), Basis(), 0.0)
		lm.box("Quartzite", Vector3(cx, 2.7, 31.2), Vector3(0.85, 4.2, 0.85), Basis(), 0.0)
	for j in 11:
		var cz := lerpf(-31.2, 31.2, float(j) / 10.0)
		lm.box("Quartzite", Vector3(-23.2, 2.7, cz), Vector3(0.85, 4.2, 0.85), Basis(), 0.0)
		lm.box("Quartzite", Vector3(23.2, 2.7, cz), Vector3(0.85, 4.2, 0.85), Basis(), 0.0)
	# Main 3-storey precast quartzite modular volume (y = 4.8..16.4 m).
	LandmarkFrKit.rect(lm, "Quartzite", -24.0, 24.0, -32.0, 32.0, 4.8, MAIN_H)
	LandmarkFrKit.rect(lm, "Roof", -23.4, 23.4, -31.4, 31.4, MAIN_H, MAIN_H + 0.35)
	# Deep coffered precast modular grid (3 storeys x rhythmic bays) on all 4 elevations.
	LandmarkFrParts.facade(lm, "Quartzite", "Glass", Vector3(-22.8, 5.4, -32.0), Vector3(22.8, 5.4, -32.0),
		Vector3.FORWARD, 10.4, 12, 3, Vector2(2.6, 2.15), 0.65, 3.45, 0.36)
	LandmarkFrParts.facade(lm, "Quartzite", "Glass", Vector3(-22.8, 5.4, 32.0), Vector3(22.8, 5.4, 32.0),
		Vector3.BACK, 10.4, 12, 3, Vector2(2.6, 2.15), 0.65, 3.45, 0.36)
	LandmarkFrParts.facade(lm, "Quartzite", "Glass", Vector3(24.0, 5.4, -30.5), Vector3(24.0, 5.4, 30.5),
		Vector3.RIGHT, 10.4, 15, 3, Vector2(2.6, 2.15), 0.65, 3.45, 0.36)
	LandmarkFrParts.facade(lm, "Quartzite", "Glass", Vector3(-24.0, 5.4, 30.5), Vector3(-24.0, 5.4, -30.5),
		Vector3.LEFT, 10.4, 15, 3, Vector2(2.6, 2.15), 0.65, 3.45, 0.36)
	# Projecting precast horizontal module ribs & vertical fins emphasizing Ehojoki's grid.
	for fl in 4:
		var ry := 4.8 + float(fl) * 3.55
		LandmarkFrParts.band(lm, "QuartzShade", -24.0, 24.0, -32.0, 32.0, ry, 0.42, 0.24)
	# Warm lit accent bays facing Kävelykatu (-Z) & Kristiinankatu (+X).
	for k in 6:
		var gx := lerpf(-18.0, 18.0, float(k) / 5.0)
		var gy := 6.8 + float(k % 3) * 3.45
		lm.box("WarmGlow", Vector3(gx, gy, -32.04), Vector3(2.1, 1.75, 0.04), Basis(), 0.0)

static func _build_stepped_penthouse(lm: LandmarkMesh) -> void:
	# Stepped-back upper office level & rooftop skylight monitors peaking at 21.2 m.
	LandmarkFrKit.rect(lm, "Quartzite", -18.5, 18.5, -24.0, 24.0, MAIN_H, 20.4)
	LandmarkFrKit.rect(lm, "Roof", -18.7, 18.7, -24.2, 24.2, 20.4, 20.75)
	LandmarkFrParts.facade(lm, "Quartzite", "Glass", Vector3(-17.0, 17.0, -24.0), Vector3(17.0, 17.0, -24.0),
		Vector3.FORWARD, 3.2, 9, 1, Vector2(2.4, 1.9), 0.5, 3.0, 0.24)
	LandmarkFrParts.facade(lm, "Quartzite", "Glass", Vector3(18.5, 17.0, -22.5), Vector3(18.5, 17.0, 22.5),
		Vector3.RIGHT, 3.2, 11, 1, Vector2(2.4, 1.9), 0.5, 3.0, 0.24)
	# Low rooftop mechanical / skylight lantern peaking at 21.2 m.
	LandmarkFrKit.rect(lm, "DarkMetal", -9.0, 9.0, -10.0, 10.0, 20.75, 21.20)
	LandmarkFrKit.rect(lm, "Glass", -8.6, 8.6, -9.6, 9.6, 20.80, 21.15)
