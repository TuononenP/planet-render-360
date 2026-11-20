class_name FtTurkuCityHall
extends RefCounted

## Turku City Hall (Turun kaupungintalo, 1811 / 1885 Frans Sjöström):
## Aurakatu 2 at Auransilta in true metres (+X ENE along Aurajoki, +Z SE
## toward Aurajoki river, turned by yaw_deg = -28.3°, height_m = 15.0):
##   - Rich yellow-ochre Neo-Renaissance riverfront palace (44 x 28 m U-plan
##     wrapping an inner courtyard on -Z, eaves 11.4 m, hipped slate roof
##     14.9 m with central gilded pediment cresting).
##   - Rusticated stone ground floor with arched portal & horizontal courses,
##     Corinthian pilaster order on the tall piano nobile (9 bays facing river),
##     central projecting avant-corps with triangular pediment & gilded Turku
##     coat-of-arms relief, wrought-iron ceremonial balcony over the entrance.
## Surfaces: 8 merged PBR parts (Ochre, Base, Trim, Roof, Iron, Gold, Glass, Lamp).

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#DFB35E", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#A99A7E", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4EFE2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3F44", 2.2))
	lm.use("Iron", LandmarkMaterials.paint("#24282C", 0.45, 0.65))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B8", 1.4))

	# Main riverside Neo-Renaissance palace front (44 x 15 m, eaves 11.4 m, hipped roof 14.9 m).
	LandmarkFrKit.rect(lm, "Base", -22.3, 22.3, -4.3, 10.8, FOUND, 4.2)
	LandmarkFrKit.rect(lm, "Ochre", -22.0, 22.0, -4.0, 10.5, 4.2, 11.4)
	for k in 4:
		var ry := 1.0 + float(k) * 0.78
		lm.box("Trim", Vector3(0.0, ry, 10.84), Vector3(44.5, 0.10, 0.08))
	LandmarkFrParts.band(lm, "Trim", -22.0, 22.0, -4.0, 10.5, 4.15, 0.45, 0.18)
	LandmarkFrParts.cornice_ring(lm, "Trim", -22.0, 22.0, -4.0, 10.5, 10.75, 0.65)
	LandmarkFrKit.hip(lm, "Roof", -22.0, 22.0, -4.0, 10.5, 11.4, 3.5, 0.50)
	# Rear U-plan courtyard wings (-Z, z = -17.5..-4.0).
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 16.5 - 5.5
		var x1 := sx * 16.5 + 5.5
		LandmarkFrKit.rect(lm, "Base", x0 - 0.15, x1 + 0.15, -17.6, -4.0, FOUND, 3.8)
		LandmarkFrKit.rect(lm, "Ochre", x0, x1, -17.5, -4.0, 3.8, 10.2)
		LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, -17.5, -4.0, 9.7, 0.50)
		LandmarkFrKit.hip(lm, "Roof", x0, x1, -17.5, -4.0, 10.2, 3.2, 0.40)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 22.0, 4.9, -15.5),
			Vector3(sx * 22.0, 4.9, -5.5), Vector3(sx, 0, 0), 4, 1.35, 2.8, LandmarkFrParts.HEAD_ROUND, 0.16, 0.12, 1)
	# Central projecting 3-bay avant-corps (+Z facing Aurajoki) with pediment & gilded crest.
	LandmarkFrKit.rect(lm, "Ochre", -6.4, 6.4, 10.4, 11.35, 4.2, 11.6)
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 11.6, 11.35), Vector3.RIGHT, Vector3.BACK, 13.0, 2.75, 0.65)
	lm.disc("Gold", Vector3(0.0, 12.65, 11.46), Vector3.BACK, 0.72, 12)
	lm.spire("Gold", Vector3(0.0, 14.35, 11.15), 0.16, 0.65, 0.0, 6)
	# Corinthian pilaster order along the piano nobile front (+Z).
	for k in 10:
		var px := lerpf(-20.5, 20.5, float(k) / 9.0)
		var pz := 11.44 if absf(px) < 6.6 else 10.60
		lm.box("Trim", Vector3(px, 7.6, pz), Vector3(0.54, 6.4, 0.28))
		lm.box("Trim", Vector3(px, 10.75, pz + 0.06), Vector3(0.76, 0.36, 0.36))
	# Ground arched entrance portal & flanking windows (+Z).
	LandmarkFrParts.opening(lm, "Trim", "Iron", Vector3(0.0, 0.0, 10.8), Vector3.BACK, 3.2, 3.7,
		LandmarkFrParts.HEAD_ROUND, 0.34, 0.22)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 4.8, 1.15, 10.8),
			Vector3(sx * 19.6, 1.15, 10.8), Vector3.BACK, 4, 1.4, 2.35, LandmarkFrParts.HEAD_ROUND, 0.18, 0.14, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 8.2, 5.1, 10.52),
			Vector3(sx * 19.6, 5.1, 10.52), Vector3.BACK, 3, 1.5, 3.55, LandmarkFrParts.HEAD_ROUND, 0.20, 0.14, 1)
	# Central piano nobile arched ceremonial windows & wrought-iron balcony (+Z).
	for bx: float in [-3.4, 0.0, 3.4]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(bx, 4.9, 11.35), Vector3.BACK, 1.65, 3.85,
			LandmarkFrParts.HEAD_ROUND, 0.22, 0.16, 1)
	lm.box("Trim", Vector3(0.0, 4.55, 12.25), Vector3(9.4, 0.34, 1.85))
	for cx: float in [-3.8, -1.3, 1.3, 3.8]:
		lm.beam("Trim", Vector3(cx, 3.7, 11.2), Vector3(cx, 4.45, 12.95), 0.26, 0.24, Vector3.RIGHT)
	lm.box("Iron", Vector3(0.0, 5.65, 13.12), Vector3(9.4, 0.09, 0.09))
	for k in 19:
		var px := lerpf(-4.6, 4.6, float(k) / 18.0)
		lm.box("Iron", Vector3(px, 5.18, 13.12), Vector3(0.05, 0.94, 0.05))
	# Entry lanterns flanking the Aurajoki portal.
	for lx: float in [-2.6, 2.6]:
		lm.box("Iron", Vector3(lx, 3.1, 11.15), Vector3(0.24, 0.32, 0.44))
		lm.box("Lamp", Vector3(lx, 2.95, 11.28), Vector3(0.20, 0.28, 0.20))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.5, 19.0), Vector3(-10.0, 8.0, 10.5), 56.0, 0.85, 38.0, Color(1.0, 0.86, 0.64)],
		[Vector3(12.0, 1.5, 19.0), Vector3(10.0, 8.0, 10.5), 56.0, 0.85, 38.0, Color(1.0, 0.86, 0.64)],
		[Vector3(0.0, 1.5, 20.0), Vector3(0.0, 11.0, 11.3), 48.0, 0.90, 38.0, Color(1.0, 0.88, 0.66)],
	])
