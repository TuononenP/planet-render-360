class_name LandmarkBkWatRatchabophit
extends RefCounted

## Wat Ratchabophit Sathitmahasimaram (`วัดราชบพิธสถิตมหาสีมาราม`) — Bangkok BK-5.2
## Site: OSM way 138947464, centroid 13.749209, 100.497129 (`height_m: 43.0`, `yaw_deg: 3.0`).
## Spec (King Rama V 1869 royal temple, Commons `front.jpg` & `aerial.jpg`):
##   - Central 43.0 m gilded Sri Lankan-style bell chedi (`Phra Maha Chedi`) on an octagonal/round
##     *Benjarong* porcelain pedestal, topped by a gilded lotus bud.
##   - Unique **circular *phra rabiang* cloister** (`R = 25.5 m` outer, `R = 19.5 m` inner) clad in
##     five-colour *Benjarong* porcelain bands (gold, teal, coral, cream) under a circular orange-and-green
##     tiled gallery roof (`aerial.jpg`).
##   - Four cardinal Thai halls (`Phra Ubosot` north `-Z`, `Phra Viharn` south `+Z`, east & west gate halls)
##     piercing the circular cloister on a raised white marble terrace ringed by `K2.chinese_pagoda`s (`front.jpg`).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 43.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F3EFE4", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DFD4", 3.0))
	lm.use("Benjarong", LandmarkMaterials.pbr("terracotta", "#C69D48", 4.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D9641E", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2E7D58", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8B82", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#26201C", 0.88, 0.0))

	_terrace_and_pagodas(lm)
	_central_gold_chedi(lm)
	_circular_benjarong_cloister(lm)
	_cardinal_halls(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 3.0, -18.0), Vector3(0.0, 26.0, 0.0), 48.0, 1.45, 48.0, Color(1.0, 0.86, 0.46)],
		[Vector3(18.0, 3.0, 18.0), Vector3(0.0, 26.0, 0.0), 48.0, 1.45, 48.0, Color(1.0, 0.86, 0.46)],
		[Vector3(0.0, 2.5, -46.0), Vector3(0.0, 14.0, -26.0), 50.0, 1.15, 36.0, Color(1.0, 0.90, 0.65)],
	])

static func _terrace_and_pagodas(lm: LandmarkMesh) -> void:
	# Compound wall (`104 × 104 m`) + raised marble upper platform (`76 × 76 m`, `y = 1.6 m`)
	var ring := [Vector3(-52, 0, -52), Vector3(52, 0, -52), Vector3(52, 0, 52), Vector3(-52, 0, 52)]
	for i in 4:
		K.sema_wall(lm, "Wall", ring[i], ring[(i + 1) % 4], 2.6, 0.9, 2.6)
	K.plinth(lm, "Marble", Vector3.ZERO, Basis(), 76.0, 76.0, 1.6)

	var pag := LandmarkMesh.new()
	pag.use("Granite", LandmarkMaterials.gold())
	K2.chinese_pagoda(pag, "Granite", Vector3.ZERO, 4.8, 6)
	for i in 12:
		var a := TAU * (float(i) + 0.5) / 12.0
		lm.merge(pag, Transform3D(Basis(), Vector3(cos(a) * 33.0, 1.6, sin(a) * 33.0)))

static func _central_gold_chedi(lm: LandmarkMesh) -> void:
	# Benjarong porcelain drum base (`y = 1.6..8.2 m`) + gilded bell chedi rising to `43.0 m` (`aerial.jpg`)
	lm.lathe("Benjarong", Vector3(0, 1.6, 0), PackedVector2Array([
		Vector2(10.8, 0.0), Vector2(10.6, 4.8), Vector2(11.1, 5.2), Vector2(10.2, 6.6)]), 28, 1.0, 1.0, 0.0, false)
	lm.lathe("Green", Vector3(0, 6.4, 0), PackedVector2Array([
		Vector2(11.15, 0.0), Vector2(11.15, 0.55)]), 28, 1.0, 1.0, 0.0, false)
	U.bell_chedi(lm, "Gold", "Benjarong", "Gold", Vector3(0, 8.2, 0), 7.4, HEIGHT_M - 8.2)

static func _circular_benjarong_cloister(lm: LandmarkMesh) -> void:
	# Circular Phra Rabiang gallery (`R_in = 19.2 m`, `R_out = 25.4 m`, eaves `y = 1.6 + 6.2 = 7.8 m`)
	var y0 := 1.6
	lm.lathe("Benjarong", Vector3(0, y0, 0), PackedVector2Array([
		Vector2(25.4, 0.0), Vector2(25.4, 6.0)]), 36, 1.0, 1.0, 0.0, false)
	lm.lathe("Wall", Vector3(0, y0, 0), PackedVector2Array([
		Vector2(19.2, 6.0), Vector2(19.2, 0.0)]), 36, 1.0, 1.0, 0.0, false)
	# Circular pitched orange-tile cloister roof with green eave borders
	lm.lathe("Green", Vector3(0, y0 + 5.9, 0), PackedVector2Array([
		Vector2(26.2, 0.0), Vector2(25.6, 0.45), Vector2(18.6, 0.45), Vector2(18.2, 0.0)]), 36, 1.0, 1.0, 0.0, false)
	lm.lathe("Orange", Vector3(0, y0 + 6.2, 0), PackedVector2Array([
		Vector2(25.8, 0.0), Vector2(22.3, 2.5), Vector2(18.8, 0.0)]), 36, 1.0, 1.0, 0.0, false)
	lm.lathe("Gold", Vector3(0, y0 + 8.65, 0), PackedVector2Array([
		Vector2(22.45, 0.0), Vector2(22.3, 0.28), Vector2(22.15, 0.0)]), 36, 1.0, 1.0, 0.0, false)

static func _cardinal_halls(lm: LandmarkMesh) -> void:
	# Four axial Thai halls (`Phra Ubosot` N `-Z`, `Phra Viharn` S `+Z`, E/W viharns) straddling the circular gallery
	var hk := {"wall": "Wall", "stone": "Marble", "tile": "Orange", "border": "Green",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var main_axis := (side % 2 == 0)
		var w := 13.5 if main_axis else 11.0
		var l := 24.0 if main_axis else 18.0
		var wh := 9.6 if main_axis else 8.0
		K.thai_hall(lm, hk, b * Vector3(0, 1.6, 23.5), b, w, l, wh, 5, 1.8, 2, 1 if main_axis else 0, 5.2, 0.6)
