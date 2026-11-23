class_name LandmarkBkWatSuthat
extends RefCounted

## Wat Suthat Thepwararam (วัดสุทัศนเทพวราราม) — Bangkok BK-2.2
## Site: compound centroid 13.750680, 100.500990, yaw_deg 7.0 (local -Z faces NNE 7 deg
## directly toward the Giant Swing across Bamrung Mueang Rd):
##   - Viharn Luang (`way:88335184`): local (+3.8, -41.3), 47.6 x 31.8 m along N-S,
##     two-level marble/stone terrace with 28 hexagonal Chinese granite ballast pagodas
##     (`K2.chinese_pagoda`), Chinese stone guardians, 4 corner bronze horse pavilions,
##     soaring double/four-tier orange-and-green roof reaching 34.0 m.
##   - Phra Rabiang cloister (`way:1320430710`): 64 x 52 m gallery around Viharn Luang
##     lined with gilded seated Buddhas and four axial gabled entrance gates.
##   - Phra Ubosot (`way:88335204`): local (-4.2, +40.6), 73.7 x 23.0 m oriented E-W
##     (longest ordination hall in Thailand), surrounded by 8 double bai sema shrines.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 34.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F2EDE0", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9D2C3", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8F908C", 2.2))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D9661F", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2E7D58", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#261F1C", 0.9, 0.05))

	var vc := Vector3(3.8, 0.0, -41.3)
	var uc := Vector3(-4.2, 0.0, 40.6)

	_viharn_luang(lm, vc)
	_phra_rabiang(lm, vc)
	_phra_ubosot(lm, uc)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[vc + Vector3(0.0, 2.0, -40.0), vc + Vector3(0.0, 20.0, 0.0), 50.0, 1.2, 48.0, Color(1.0, 0.90, 0.68)],
		[vc + Vector3(28.0, 2.0, 0.0), vc + Vector3(0.0, 20.0, 0.0), 50.0, 1.1, 46.0, Color(1.0, 0.90, 0.68)],
		[vc + Vector3(-28.0, 2.0, 0.0), vc + Vector3(0.0, 20.0, 0.0), 50.0, 1.1, 46.0, Color(1.0, 0.90, 0.68)],
		[uc + Vector3(0.0, 2.0, -24.0), uc + Vector3(0.0, 14.0, 0.0), 55.0, 1.1, 48.0, Color(1.0, 0.90, 0.68)],
		[uc + Vector3(0.0, 2.0, 24.0), uc + Vector3(0.0, 14.0, 0.0), 55.0, 1.1, 48.0, Color(1.0, 0.90, 0.68)],
	])

static func _hall_keys() -> Dictionary:
	return {"wall": "Wall", "stone": "Stone", "tile": "Orange", "border": "Green",
		"gold": "Gold", "dark": "Dark", "col": "Wall"}

static func _viharn_luang(lm: LandmarkMesh, vc: Vector3) -> void:
	# Lower & upper marble-paved courtyard terraces around Viharn Luang
	K.plinth(lm, "Stone", vc, Basis(), 36.0, 52.0, 1.5)
	K.plinth(lm, "Stone", vc + Vector3(0, 1.5, 0), Basis(), 30.0, 46.0, 1.5)
	# Perimeter stone balustrade & axial stairs on N (-Z) and S (+Z)
	for sz in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, PI if sz < 0.0 else 0.0)
		U.stairs(lm, "Stone", vc + Vector3(0, 3.0, sz * 23.2), sb, 5.4, 10, 0.34, 0.30)
		K2.chinese_guardian(lm, "Granite", vc + Vector3(-3.6, 0.0, sz * 27.0), sb, 2.8)
		K2.chinese_guardian(lm, "Granite", vc + Vector3(3.6, 0.0, sz * 27.0), sb, 2.8)
	# Viharn Luang standing on y = 3.0 m terrace:
	# plinth_h=1.2 + wall_h=15.4 + peri_lift=0.4 + rise(11.6 * 1.2) = 3.0 + 1.2 + 15.4 + 0.4 + 13.92 = 33.92 m (~34.0 m!)
	var viharn_b := Basis(Vector3.UP, PI) # front faces -Z toward Giant Swing
	K.thai_hall(lm, _hall_keys(), vc + Vector3(0, 3.0, 0), viharn_b,
		17.5, 36.0, 15.4, 7, 3.2, 3, 2, 11.6, 1.2)
	# Four corner small roofed horse/guardian salas on the upper terrace
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var sc := vc + Vector3(sx * 12.8, 3.0, sz * 20.2)
			for cx in [-1.1, 1.1]:
				for cz in [-1.1, 1.1]:
					lm.box("Wall", sc + Vector3(cx, 1.3, cz), Vector3(0.24, 2.6, 0.24), Basis(), 0.0)
			K.roof_piece(lm, "Orange", "Green", "Gold", "Wall", sc + Vector3(0, 2.6, 0),
				viharn_b, 2.8, 3.2, 1.5, 0.35, 0.45, 0.7)

static func _phra_rabiang(lm: LandmarkMesh, vc: Vector3) -> void:
	# Square covered gallery (62 x 74 m outer) enclosing Viharn Luang + 28 Chinese stone pagodas
	var hx := 31.0
	var hz := 37.0
	var thick := 4.4
	U.cloister(lm, "Wall", "Orange", vc, hx, hz, thick, 4.2, 2.4)
	# Inner open colonnade & seated gilt Buddhas along the gallery
	for sz in [-1.0, 1.0]:
		var z: float = float(sz) * (hz - thick)
		U.posts(lm, "Wall", vc + Vector3(-hx + thick, 0, z), vc + Vector3(hx - thick, 0, z), 20, 4.0, 0.42, 0.0)
		var bb := Basis(Vector3.UP, PI if float(sz) > 0.0 else 0.0)
		for i in 9:
			var bx := -hx + thick + 3.0 + (hx * 2.0 - thick * 2.0 - 6.0) * float(i) / 8.0
			K.seated_buddha(lm, "Gold", vc + Vector3(bx, 0.4, float(sz) * (hz - thick * 0.55)), bb, 1.65)
	for sx in [-1.0, 1.0]:
		var x: float = float(sx) * (hx - thick)
		U.posts(lm, "Wall", vc + Vector3(x, 0, -hz + thick), vc + Vector3(x, 0, hz - thick), 24, 4.0, 0.42, 0.0)
	# Four axial Thai entrance gate pavilions on the cloister
	for side in 4:
		var gb := Basis(Vector3.UP, PI * 0.5 * float(side))
		var dist := hz if side % 2 == 0 else hx
		var gc := vc + gb * Vector3(0, 0, dist - thick * 0.5)
		lm.box("Wall", gc + Vector3(0, 2.6, 0), Vector3(6.2, 5.2, 5.4), gb)
		lm.box("Dark", gc + Vector3(0, 1.8, 0), Vector3(2.4, 3.6, 5.6), gb, 0.0)
		K.roof_piece(lm, "Orange", "Green", "Gold", "Wall", gc + Vector3(0, 5.2, 0), gb, 6.4, 6.2, 3.2, 0.7, 0.8, 1.3)

	# 28 hexagonal Chinese stone ballast pagodas (thao) built once and instanced around the outer wall
	var pag := LandmarkMesh.new()
	pag.use("Granite", LandmarkMaterials.pbr("stone", "#8F908C", 2.2))
	K2.chinese_pagoda(pag, "Granite", Vector3.ZERO, 5.0, 6)
	for i in 7:
		var t := (float(i) + 0.5) / 7.0
		lm.merge(pag, Transform3D(Basis(), vc + Vector3(lerpf(-hx + 3.0, hx - 3.0, t), 0, -hz - 1.8)))
		lm.merge(pag, Transform3D(Basis(), vc + Vector3(lerpf(-hx + 3.0, hx - 3.0, t), 0, hz + 1.8)))
		lm.merge(pag, Transform3D(Basis(), vc + Vector3(-hx - 1.8, 0, lerpf(-hz + 3.0, hz - 3.0, t))))
		lm.merge(pag, Transform3D(Basis(), vc + Vector3(hx + 1.8, 0, lerpf(-hz + 3.0, hz - 3.0, t))))

static func _phra_ubosot(lm: LandmarkMesh, uc: Vector3) -> void:
	# Long E-W ordination hall (72 m total terrace length, ridge along local X -> Basis rotated 90 deg)
	var ub := Basis(Vector3.UP, PI * 0.5)
	K.plinth(lm, "Stone", uc, ub, 28.0, 75.0, 1.4)
	K.thai_hall(lm, _hall_keys(), uc + Vector3(0, 1.4, 0), ub,
		15.5, 64.0, 11.2, 13, 2.8, 3, 2, 8.8, 1.0)
	for sx in [-1.0, 1.0]:
		var eb := Basis(Vector3.UP, PI * 0.5 * sx)
		U.stairs(lm, "Stone", uc + Vector3(sx * 37.8, 1.4, 0), eb, 4.6, 6, 0.32, 0.233)
	# Eight bai sema boundary stone niches around the ubosot terrace
	var sema_mesh := LandmarkMesh.new()
	for key in ["Stone", "Wall", "Orange", "Gold"]:
		sema_mesh.use(key, LandmarkMaterials.gold())
	K2.bai_sema(sema_mesh, "Stone", "Wall", "Orange", "Gold", Vector3.ZERO, Basis(), 4.8)
	for dx in [-36.5, 0.0, 36.5]:
		for dz in [-15.2, 15.2]:
			lm.merge(sema_mesh, Transform3D(Basis(), uc + Vector3(dx, 0.0, dz)))
	for sx in [-39.0, 39.0]:
		lm.merge(sema_mesh, Transform3D(Basis(), uc + Vector3(sx, 0.0, 0.0)))
