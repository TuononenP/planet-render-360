class_name LandmarkBkWatBowonniwet
extends RefCounted

## Wat Bowonniwet Vihara (`วัดบวรนิเวศวิหาร`) — Bangkok BK-5.2
## Site: OSM way 1401843958 (Phra Chedi) & way 134003265 (T-plan Phra Ubosot),
## centroid 13.760357, 100.499845 (`height_m: 50.0`, `yaw_deg: -11.0`).
## Spec (Rama III & King Mongkut Dhammayuttika royal temple, Commons `front.jpg`):
##   - Monumental **50.0 m gilded round bell chedi** (`Phra Suwannakhet`) standing on a raised
##     square white marble balustrade terrace (`28 × 28 m`, `3.2 m` high) with 4 corner shrines.
##   - Unique **T-plan `Phra Ubosot`** in front (`+Z = +26 m`): whitewashed walls with battered
##     square pilasters, gilded window frames (`front.jpg`), pale-grey & orange glazed roofs,
##     and Chinese-porcelain royal crown gables.
##   - `Viharn Phra Satsada` behind the great chedi (`-Z = -28 m`) + whitewashed boundary shrines.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 50.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F4F1E8", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E1D8", 3.0))
	lm.use("GreyTile", LandmarkMaterials.pbr("slate", "#B9B8B0", 2.4))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#CF5E20", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#327A56", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#231E1B", 0.88, 0.0))

	_compound_wall(lm)
	_great_gold_chedi(lm)
	_t_plan_ubosot_and_viharn(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 3.0, 14.0), Vector3(0.0, 30.0, 0.0), 48.0, 1.50, 56.0, Color(1.0, 0.85, 0.44)],
		[Vector3(18.0, 3.0, -14.0), Vector3(0.0, 30.0, 0.0), 48.0, 1.45, 56.0, Color(1.0, 0.85, 0.44)],
		[Vector3(0.0, 2.5, 48.0), Vector3(0.0, 13.0, 26.0), 50.0, 1.15, 36.0, Color(1.0, 0.90, 0.68)],
	])

static func _compound_wall(lm: LandmarkMesh) -> void:
	var ring := [Vector3(-34, 0, -48), Vector3(34, 0, -48), Vector3(34, 0, 48), Vector3(-34, 0, 48)]
	for i in 4:
		K.sema_wall(lm, "Wall", ring[i], ring[(i + 1) % 4], 2.6, 0.9, 2.6)
	lm.box("Marble", Vector3(0, 0.14, 0), Vector3(66.0, 0.28, 94.0))

static func _great_gold_chedi(lm: LandmarkMesh) -> void:
	# Square balustraded terrace (`28 × 28 m`, `y = 3.2 m`) + 4 corner shrines + 50.0 m gilded bell chedi
	K.plinth(lm, "Marble", Vector3(0, 0.28, 0), Basis(), 28.0, 28.0, 2.92)
	var y0 := 3.2
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.posts(lm, "Marble", b * Vector3(-12.5, y0, 13.4), b * Vector3(12.5, y0, 13.4), 14, 0.9, 0.26)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K2.bai_sema(lm, "Marble", "Wall", "Orange", "Gold",
				Vector3(float(sx) * 11.4, y0, float(sz) * 11.4), Basis(), 5.4)
	U.bell_chedi(lm, "Gold", "Marble", "Gold", Vector3(0, y0, 0), 8.6, HEIGHT_M - y0)

static func _t_plan_ubosot_and_viharn(lm: LandmarkMesh) -> void:
	# T-plan Phra Ubosot (`z = +26 m`, `front.jpg` grey-white roof + gilded windows & sema niches)
	var hk_t := {"wall": "Wall", "stone": "Marble", "tile": "GreyTile", "border": "Orange",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}
	K.thai_hall(lm, hk_t, Vector3(0.0, 0.28, 25.0), Basis(), 14.0, 24.0, 9.0, 6, 2.0, 2, 0, 5.0, 1.1)
	K.thai_hall(lm, hk_t, Vector3(0.0, 0.28, 19.0), Basis(Vector3.UP, PI * 0.5), 11.5, 28.0, 8.4, 7, 1.6, 1, 0, 4.4, 1.1)
	for sx in [-1.0, 1.0]:
		K2.bai_sema(lm, "Marble", "Wall", "GreyTile", "Gold",
			Vector3(float(sx) * 16.5, 0.28, 25.0), Basis(), 5.2)

	# Viharn Phra Satsada behind the chedi (`z = -29 m`) with orange-and-green roof
	var hk_v := {"wall": "Wall", "stone": "Marble", "tile": "Orange", "border": "Green",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}
	K.thai_hall(lm, hk_v, Vector3(0.0, 0.28, -29.0), Basis(Vector3.UP, PI), 13.5, 24.0, 8.8, 6, 1.8, 2, 1, 4.8, 1.1)
