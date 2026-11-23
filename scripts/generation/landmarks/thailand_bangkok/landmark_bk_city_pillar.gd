class_name LandmarkBkCityPillar
extends RefCounted

## Bangkok City Pillar Shrine — San Lak Mueang (`ศาลหลักเมืองกรุงเทพมหานคร`) — BK-5.1
## Site: OSM way 127290889, centroid 13.752564, 100.494031 (`height_m: 27.0`, `yaw_deg: -1.0`).
## Spec (Rama I 1782 foundation, 1982 prasat reconstruction, Commons `front.jpg`):
##   - Gleaming whitewashed cruciform Thai *prasat* sanctuary (`16.5 × 16.5 m`) on a 1.4 m
##     stepped white marble terrace, four portico arms with grey-white glazed tile 2-tier roofs,
##     crimson eave soffits, and ornate gilded multi-tiered gables with *chofa* finials.
##   - Central Ayutthaya-style whitewashed ribbed redented *prang* spire rising from the
##     crossing (`10.2..25.2 m`) crowned by a gilded *naphalai* bud & Vajra finial at `27.0 m`.
##   - Secondary deity pavilion (`San Thepharak`) beside the main shrine inside a low white
##     `sema_wall` courtyard with corner chedi posts & ceremonial flagstaffs.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const HEIGHT_M := 27.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F4F2EC", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E7E4DC", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#CECEC8", 2.4))
	lm.use("RedTrim", LandmarkMaterials.pbr("terracotta", "#8E2622", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#251F1C", 0.88, 0.0))

	_courtyard_and_deity_hall(lm)
	_cruciform_sanctuary(lm)
	_central_white_prang(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.8, 12.0), Vector3(0.0, 16.0, 0.0), 48.0, 1.35, 34.0, Color(1.0, 0.92, 0.72)],
		[Vector3(12.0, 1.8, -12.0), Vector3(0.0, 16.0, 0.0), 48.0, 1.25, 34.0, Color(1.0, 0.92, 0.72)],
	])

static func _courtyard_and_deity_hall(lm: LandmarkMesh) -> void:
	lm.box("Marble", Vector3(2.5, 0.15, 0.0), Vector3(36.0, 0.3, 30.0))
	var ring := [Vector3(-15.0, 0.0, -14.5), Vector3(20.0, 0.0, -14.5),
		Vector3(20.0, 0.0, 14.5), Vector3(-15.0, 0.0, 14.5)]
	for i in 4:
		K.sema_wall(lm, "Wall", ring[i], ring[(i + 1) % 4], 1.8, 0.65, 2.2)
	# Secondary San Thepharak pavilion (`+X = +12.5 m`) with white-grey roof & gilded gables
	var dc := Vector3(12.6, 0.3, -2.0)
	lm.box("Wall", dc + Vector3(0, 2.4, 0), Vector3(7.2, 4.8, 11.4))
	K.thai_roof(lm, "Tile", "RedTrim", "Gold", "Wall", dc + Vector3(0, 4.8, 0),
		Basis(), 8.2, 12.4, 3.2, 0.85, 1, 1, 1.2)

static func _cruciform_sanctuary(lm: LandmarkMesh) -> void:
	K.plinth(lm, "Marble", Vector3(0, 0.3, 0), Basis(), 18.8, 18.8, 1.3)
	var y0 := 1.6
	for arm in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(arm))
		lm.box("Wall", Vector3(0, y0 + 3.6, 0), Vector3(7.4, 7.2, 16.2), b)
		lm.box("RedTrim", Vector3(0, y0 + 7.05, 0), Vector3(7.8, 0.35, 16.6), b)
		K.thai_roof(lm, "Tile", "RedTrim", "Gold", "Wall", Vector3(0, y0 + 7.2, 0),
			b, 8.2, 17.0, 3.4, 0.9, 1, 1, 1.35)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		K.thai_window(lm, "Wall", "Dark", "Gold", b * Vector3(0, y0, 8.12), b, 2.1, 4.4)
		for sx in [-1.0, 1.0]:
			K.thai_column(lm, "Wall", "Gold", b * Vector3(float(sx) * 2.7, y0, 9.2), 0.42, 6.8)

static func _central_white_prang(lm: LandmarkMesh) -> void:
	# Stepped square crossing neck + ribbed whitewashed Ayutthaya prang rising to 27.0 m
	var y0 := 9.8
	lm.box("Wall", Vector3(0, y0 + 0.9, 0), Vector3(7.6, 1.8, 7.6))
	lm.box("Gold", Vector3(0, y0 + 1.9, 0), Vector3(8.0, 0.3, 8.0))
	K.redent_prang(lm, "Wall", "Gold", "Gold", Vector3(0, y0 + 2.0, 0), 3.1, 13.6, 7, false)
	lm.beam("Gold", Vector3(0, 25.0, 0), Vector3(0, HEIGHT_M, 0), 0.16, 0.16)
	lm.frustum("Gold", Vector3(0, 25.5, 0), 0.34, 0.08, 0.9, 8)
