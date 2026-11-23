class_name LandmarkBkWatKalayanamit
extends RefCounted

## Wat Kalayanamit Woramahawihan (`วัดกัลยาณมิตรวรมหาวิหาร`) — Thonburi Bank, Bangkok BK-5.4
## Site: OSM way 783759507 / way 342355805, centroid 13.740050, 100.491350 (`height_m: 42.0`, `yaw_deg: 39.0`).
## Spec (Chao Phraya Nikorabodin 1825, towering riverside Viharn Luang, Commons `front.jpg`):
##   - Colossal riverside `Viharn Luang` (`30 × 38 m`, `42.0 m` ridge — among the tallest traditional
##     Thai temple halls in Bangkok, housing the 15 m seated `Luang Pho To` Buddha): towering whitewashed
##     walls & battered square peristyle pillars under a steep 3-tier orange-and-green glazed roof.
##   - Flanking Chinese-Thai porcelain-gabled `Phra Ubosot` (`left -X`) and `Viharn Luang Pho Sothon`
##     (`right +X`), white foreground stupa, `K2.chinese_pagoda` stone pagodas, and green-tiled
##     courtyard balustrade (`front.jpg`).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 42.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F4F1E8", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DFDBD0", 3.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D8621E", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2E7D58", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8B8880", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#251E1B", 0.88, 0.0))

	_riverside_court_and_pagodas(lm)
	_colossal_viharn_luang(lm)
	_flanking_halls_and_chedi(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 2.5, 32.0), Vector3(0.0, 24.0, 0.0), 54.0, 1.45, 56.0, Color(1.0, 0.88, 0.56)],
		[Vector3(18.0, 2.5, 32.0), Vector3(0.0, 24.0, 0.0), 54.0, 1.45, 56.0, Color(1.0, 0.88, 0.56)],
	])

static func _riverside_court_and_pagodas(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 0.16, 4.0), Vector3(84.0, 0.32, 74.0))
	# Low white-and-green ceramic balustrade enclosing the sacred courtyard (`front.jpg`)
	var ring := [Vector3(-38, 0.32, -28), Vector3(38, 0.32, -28), Vector3(38, 0.32, 28), Vector3(-38, 0.32, 28)]
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		var mid := (a + b) * 0.5
		var d := a.distance_to(b)
		var basis := Basis((b - a).normalized(), Vector3.UP, (b - a).normalized().cross(Vector3.UP))
		lm.box("Wall", mid + Vector3(0, 0.55, 0), Vector3(d, 1.1, 0.42), basis)
		lm.box("Green", mid + Vector3(0, 0.55, 0), Vector3(d - 1.2, 0.45, 0.48), basis, 0.0)

	var pag := LandmarkMesh.new()
	pag.use("Granite", LandmarkMaterials.gold())
	K2.chinese_pagoda(pag, "Granite", Vector3.ZERO, 6.2, 7)
	for p in [Vector3(-16, 0.32, 24), Vector3(16, 0.32, 24), Vector3(-22, 0.32, 12), Vector3(22, 0.32, 12)]:
		lm.merge(pag, Transform3D(Basis(), p))

static func _colossal_viharn_luang(lm: LandmarkMesh) -> void:
	# Monumental Viharn Luang: `2.4 m` plinth + `19.6 m` walls + `18.2 m` 3-step/3-layer steep Thai roof
	# + `chofa` finial reaching cleanly ~`41.8 m` (`HEIGHT_M = 42.0 m`)!
	var hk := {"wall": "Wall", "stone": "Stone", "tile": "Orange", "border": "Green",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}
	K.thai_hall(lm, hk, Vector3(0.0, 0.32, -2.0), Basis(),
		24.0, 34.0, 19.6, 6, 3.4, 2, 2, 15.2, 2.5)

static func _flanking_halls_and_chedi(lm: LandmarkMesh) -> void:
	var hk := {"wall": "Wall", "stone": "Stone", "tile": "Orange", "border": "Green",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}
	# Flanking Phra Ubosot (`-X = -26 m`) & Viharn Noi (`+X = +26 m`) + foreground white chedi (`front.jpg`)
	K.thai_hall(lm, hk, Vector3(-26.5, 0.32, 2.0), Basis(), 13.5, 22.0, 9.6, 5, 1.8, 1, 0, 5.8, 1.0)
	K.thai_hall(lm, hk, Vector3(26.5, 0.32, -2.0), Basis(), 13.5, 22.0, 9.6, 5, 1.8, 1, 0, 5.8, 1.0)
	K.plinth(lm, "Wall", Vector3(-6.0, 0.32, 21.0), Basis(), 7.6, 7.6, 2.2)
	U.bell_chedi(lm, "Wall", "Wall", "Gold", Vector3(-6.0, 2.52, 21.0), 3.1, 15.8)
