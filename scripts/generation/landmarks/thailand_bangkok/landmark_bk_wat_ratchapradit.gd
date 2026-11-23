class_name LandmarkBkWatRatchapradit
extends RefCounted

## Wat Ratchapradit Sathitmahasimaram (`วัดราชประดิษฐสถิตมหาสีมาราม`) — Bangkok BK-5.2
## Site: OSM way 342337807, centroid 13.749658, 100.495571 (`height_m: 35.0`, `yaw_deg: -2.0`).
## Spec (King Rama IV 1864 Dhammayuttika royal temple, Commons `front.jpg`):
##   - High grey-white marble balustrade upper terrace (`56 × 38 m`, `2.6 m` high) accessed by
##     axial marble staircases.
##   - Grey-white marble-clad `Phra Ubosot` (`15 × 28 m`) with 2-tier orange-and-blue/green
##     glazed tile roof and richly gilded Indra-on-Erawan gables (`front.jpg`).
##   - Central 35.0 m grey-white marble bell chedi (`Phra Wiharot Pasana Chedi`) directly behind
##     the ubosot, flanked on the terrace corners by two carved grey-stone Khmer `prang` towers
##     (`Pasana Prang`, `20 m` top) housing the royal boundary stones.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const HEIGHT_M := 35.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DFDDD6", 3.0))
	lm.use("GreyStone", LandmarkMaterials.pbr("stone", "#9E9C95", 3.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#CF5B20", 2.0))
	lm.use("BlueTrim", LandmarkMaterials.pbr("slate", "#2F5678", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#241F1D", 0.88, 0.0))

	_marble_terrace_and_walls(lm)
	_marble_ubosot_and_prangs(lm)
	_pasana_chedi(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-24.0, 2.5, 18.0), Vector3(-6.0, 18.0, 0.0), 50.0, 1.30, 42.0, Color(1.0, 0.90, 0.65)],
		[Vector3(24.0, 2.5, -18.0), Vector3(14.0, 22.0, 0.0), 48.0, 1.35, 42.0, Color(1.0, 0.88, 0.56)],
	])

static func _marble_terrace_and_walls(lm: LandmarkMesh) -> void:
	var ring := [Vector3(-42, 0, -28), Vector3(42, 0, -28), Vector3(42, 0, 28), Vector3(-42, 0, 28)]
	for i in 4:
		K.sema_wall(lm, "Marble", ring[i], ring[(i + 1) % 4], 2.4, 0.8, 2.4)
	# High grey-white marble upper terrace (`58 × 36 m`, `y = 2.6 m`) + balustrade posts
	K.plinth(lm, "Marble", Vector3(2.0, 0.0, 0.0), Basis(), 58.0, 36.0, 2.6)
	for sz in [-1.0, 1.0]:
		U.posts(lm, "Marble", Vector3(-26.0, 2.6, float(sz) * 17.4),
			Vector3(30.0, 2.6, float(sz) * 17.4), 24, 0.95, 0.28)
	U.stairs(lm, "Marble", Vector3(-28.5, 2.6, 0.0), Basis(Vector3.UP, -PI * 0.5), 5.6, 10, 0.38, 0.26)

static func _marble_ubosot_and_prangs(lm: LandmarkMesh) -> void:
	var y0 := 2.6
	var hk := {"wall": "Marble", "stone": "GreyStone", "tile": "Orange", "border": "BlueTrim",
		"gold": "Gold", "dark": "Dark", "col": "Gold"}
	K.thai_hall(lm, hk, Vector3(-6.0, y0, 0.0), Basis(Vector3.UP, -PI * 0.5),
		14.0, 26.0, 9.2, 6, 2.2, 2, 1, 5.2, 1.2)
	# Twin carved grey-stone Khmer Pasana Prang towers (`y = 2.6..20.6 m`) flanking the terrace
	for sz in [-1.0, 1.0]:
		K.redent_prang(lm, "GreyStone", "Dark", "Gold",
			Vector3(-18.0, y0, float(sz) * 13.0), 2.6, 18.0, 6, true)
	# Ho Trai library pavilion on opposite end (`+X = +25 m`)
	K.thai_hall(lm, hk, Vector3(25.0, y0, 0.0), Basis(Vector3.UP, PI * 0.5),
		8.8, 14.0, 6.4, 4, 1.4, 1, 0, 3.8, 0.8)

static func _pasana_chedi(lm: LandmarkMesh) -> void:
	# Central grey-white marble bell chedi rising from `y = 2.6 m` to `35.0 m`
	U.bell_chedi(lm, "Marble", "Marble", "Gold", Vector3(11.5, 2.6, 0.0), 6.2, HEIGHT_M - 2.6)
