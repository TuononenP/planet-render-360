class_name LandmarkBkNationalMuseum
extends RefCounted

## Bangkok National Museum — Front Palace (`พิพิธภัณฑสถานแห่งชาติ พระนคร / วังหน้า`) — BK-5.1
## Site: OSM way 83608613 (Siwamokhaphiman Hall) & way 190739714 (Buddhaisawan Chapel),
## centroid 13.757735, 100.492112 (`height_m: 26.0`, `yaw_deg: 24.0`).
## Spec (Prince Maha Sura Singhanat 1782 Front Palace complex, Commons `front.jpg`):
##   - Siwamokhaphiman Throne Hall (`50 × 24 m`, `26.0 m` ridge): monumental whitewashed
##     audience hall on stepped terrace with square peristyle columns and 3-tier orange-and-green
##     Thai roof with gilded *chofa* gables.
##   - Buddhaisawan Chapel (`38 × 18 m`, `21.0 m` ridge) in front (`+Z`), housing Phra Phuttha Sihing.
##   - Sala Samranmukhamat (`15 × 10 m` open crimson-and-gold carved wooden royal pavilion,
##     `front.jpg` centrepiece) & Tamnak Daeng red teak house inside a white crenellated palace court.

const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const HEIGHT_M := 26.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F4F0E6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD6C6", 3.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D9661F", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2F7F5A", 2.0))
	lm.use("Crimson", LandmarkMaterials.pbr("wood", "#7C201D", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#261E1A", 0.88, 0.0))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#4B7839", 4.0))

	_palace_courtyard(lm)
	_siwamokhaphiman_and_buddhaisawan(lm)
	_sala_samranmukhamat(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 12.0), Vector3(0.0, 16.0, -14.0), 54.0, 1.30, 48.0, Color(1.0, 0.90, 0.65)],
		[Vector3(-24.0, 2.0, 36.0), Vector3(0.0, 14.0, 18.0), 50.0, 1.25, 42.0, Color(1.0, 0.88, 0.58)],
	])

static func _palace_courtyard(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 0.12, 6.0), Vector3(76.0, 0.24, 92.0))
	lm.box("Grass", Vector3(-22.0, 0.16, 22.0), Vector3(24.0, 0.08, 44.0))
	lm.box("Grass", Vector3(22.0, 0.16, 22.0), Vector3(24.0, 0.08, 44.0))
	var ring := [Vector3(-39.0, 0.0, -41.0), Vector3(39.0, 0.0, -41.0),
		Vector3(39.0, 0.0, 53.0), Vector3(-39.0, 0.0, 53.0)]
	for i in 4:
		K.sema_wall(lm, "Wall", ring[i], ring[(i + 1) % 4], 2.8, 1.0, 2.8)

static func _siwamokhaphiman_and_buddhaisawan(lm: LandmarkMesh) -> void:
	var hk := {"wall": "Wall", "stone": "Stone", "tile": "Orange", "border": "Green",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}
	# Siwamokhaphiman Throne Hall (`z = -14 m`, 20 × 48 m, ridge cleanly at 25.8 m ~ HEIGHT_M = 26.0 m)
	K.thai_hall(lm, hk, Vector3(0.0, 0.24, -14.0), Basis(Vector3.UP, PI * 0.5),
		19.0, 46.0, 11.4, 9, 2.6, 2, 2, 7.6, 2.2)
	# Buddhaisawan Chapel (`z = +18 m`, 16 × 36 m, ~21.2 m ridge)
	K.thai_hall(lm, hk, Vector3(4.0, 0.24, 18.0), Basis(Vector3.UP, PI * 0.5),
		15.0, 34.0, 9.6, 7, 2.2, 2, 1, 6.0, 1.6)

static func _sala_samranmukhamat(lm: LandmarkMesh) -> void:
	# Ornate open crimson-and-gold carved wooden royal Sala (`front.jpg`) at `(-18, 0.24, 34)`
	var sc := Vector3(-18.0, 0.24, 34.0)
	K.plinth(lm, "Wall", sc, Basis(), 11.6, 15.6, 1.1)
	var y0 := 1.1
	for ix in [-4.4, -1.5, 1.5, 4.4]:
		for iz in [-6.4, -2.1, 2.1, 6.4]:
			if absf(ix) < 3.0 and absf(iz) < 5.0:
				continue
			lm.box("Crimson", sc + Vector3(ix, y0 + 2.4, iz), Vector3(0.36, 4.8, 0.36))
			lm.box("Gold", sc + Vector3(ix, y0 + 4.3, iz), Vector3(0.52, 0.75, 0.52))
	lm.box("Gold", sc + Vector3(0, y0 + 4.65, 0), Vector3(9.4, 0.55, 13.4))
	K.thai_roof(lm, "Crimson", "Gold", "Gold", "Crimson", sc + Vector3(0, y0 + 4.9, 0),
		Basis(), 10.6, 14.8, 4.4, 1.1, 2, 1, 1.2)
