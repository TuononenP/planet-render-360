class_name LandmarkBkWatMangkon
extends RefCounted

## Wat Mangkon Kamalawat — Wat Leng Noei Yi (`วัดมังกรกมลาวาส` / 龍蓮寺) — Bangkok BK-11
## Site: OSM way 301157259 on Charoen Krung Rd, centroid 13.743447, 100.509436
## (`height_m: 15.0`, `yaw_deg: -61.0`, `radius_m: 1400.0`).
## Spec (founded 1871 under Phra Archan Chin Wang Samathiwat, Commons `front.jpg`):
##   - Largest Chinese Mahayana Buddhist courtyard monastery in Bangkok (`72 × 42 m` core
##     compound), built in classic Southern Chinese / Teochew layout: mountain gate (`Shanmen`),
##     Hall of the Four Heavenly Kings (`Si Thao`), paved incense courtyard, and Main Shrine
##     Hall (`Daxiong Baodian` / Ubosot) rising to `15.0 m` at its central dragon ridge pearl.
##   - Grey granite & rose-terracotta stucco walls (`front.jpg`), crimson pillars hung with
##     vertical gilded Chinese calligraphy couplets, carved stone guardian lions, sweeping
##     emerald-green & gold glazed ceramic tile roofs (`#287654`) with upturned swallowtail
##     ridges & twin green-and-gold ceramic dragons flanking a flaming pearl, and rows of
##     glowing red temple lanterns (`LanternLamp`).

const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 15.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#989288", 2.5))
	lm.use("RoseWall", LandmarkMaterials.pbr("render", "#B98E7E", 2.6))
	lm.use("Crimson", LandmarkMaterials.pbr("concrete", "#B82220", 2.0, 0.45))
	lm.use("GreenTile", LandmarkMaterials.pbr("slate", "#277452", 1.8))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#1F1A16", 0.86, 0.05))
	lm.use("LanternLamp", LandmarkMaterials.lit("#FF3E24", 2.5))

	_compound_walls_and_gate(lm)
	_heavenly_kings_and_main_hall(lm)
	_courtyard_wings_and_lanterns(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.2, 34.0), Vector3(0.0, 9.5, 16.0), 46.0, 1.35, 36.0, Color(1.0, 0.86, 0.62)],
		[Vector3(0.0, 2.5, 8.0), Vector3(0.0, 11.5, -10.0), 48.0, 1.30, 38.0, Color(1.0, 0.88, 0.66)],
	])

static func _compound_walls_and_gate(lm: LandmarkMesh) -> void:
	# Paved granite courtyard (`40 × 64 m`) + Charoen Krung mountain gate (`+Z = +30 m`)
	lm.box("Granite", Vector3(0, 0.20, 0), Vector3(40.0, 0.40, 64.0))
	var gz := 30.0
	lm.box("Granite", Vector3(0, 2.4, gz), Vector3(38.0, 4.2, 1.2))
	lm.box("RoseWall", Vector3(0, 3.2, gz), Vector3(14.6, 5.8, 3.6))
	# Portal doorway, crimson couplet boards & carved stone guardian lions (`front.jpg`)
	lm.box("Dark", Vector3(0, 2.2, gz + 1.65), Vector3(3.4, 3.8, 0.4))
	lm.box("Crimson", Vector3(0, 4.5, gz + 1.82), Vector3(1.6, 2.2, 0.14))
	for sx in [-1.0, 1.0]:
		var x := float(sx) * 2.8
		lm.frustum("Crimson", Vector3(x, 0.4, gz + 1.75), 0.26, 0.24, 4.8, 10)
		lm.box("Crimson", Vector3(x, 2.6, gz + 2.02), Vector3(0.55, 3.2, 0.08))
		lm.box("Gold", Vector3(x, 2.6, gz + 2.07), Vector3(0.28, 2.6, 0.06))
		lm.box("Granite", Vector3(float(sx) * 3.9, 0.85, gz + 2.45), Vector3(1.1, 0.9, 1.2))
		K2.chinese_guardian(lm, "Granite", Vector3(float(sx) * 3.9, 1.30, gz + 2.45), Basis(), 1.25)
	_chinese_dragon_roof(lm, Vector3(0, 6.1, gz), 16.8, 5.8, 2.6, 1.2)

static func _heavenly_kings_and_main_hall(lm: LandmarkMesh) -> void:
	# 1. Hall of the Four Heavenly Kings (`z = +13 m`, `22 × 12 m`)
	var hc := Vector3(0, 0.4, 13.0)
	lm.box("RoseWall", hc + Vector3(0, 3.2, 0), Vector3(22.0, 6.4, 11.8))
	for sx in [-7.5, -2.5, 2.5, 7.5]:
		lm.frustum("Crimson", hc + Vector3(float(sx), 0.0, 6.0), 0.28, 0.26, 6.2, 10)
	_chinese_dragon_roof(lm, hc + Vector3(0, 6.4, 0), 24.4, 14.0, 3.4, 1.5)

	# 2. Main Shrine Hall (`Daxiong Baodian`, `z = -10 m`, double-eave roof rising to `15.0 m`)
	var mc := Vector3(0, 0.4, -10.0)
	lm.box("Granite", mc + Vector3(0, 0.45, 0), Vector3(28.0, 0.90, 18.4))
	lm.box("RoseWall", mc + Vector3(0, 4.6, 0), Vector3(25.0, 7.4, 15.6))
	for sx in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		lm.frustum("Crimson", mc + Vector3(float(sx), 0.9, 8.0), 0.30, 0.28, 7.2, 10)
	# Lower perimeter eave skirt + tall upper emerald-green ceramic gable & twin dragons (`15.0 m`)
	lm.gable("GreenTile", mc + Vector3(0, 7.4, 0), 18.2, 27.8, 1.8, Basis(Vector3.UP, PI * 0.5), 0.6, "Gold")
	lm.box("RoseWall", mc + Vector3(0, 9.1, 0), Vector3(20.6, 1.8, 12.4))
	_chinese_dragon_roof(lm, mc + Vector3(0, 10.0, 0), 23.2, 14.8, 3.55, 1.45)

static func _courtyard_wings_and_lanterns(lm: LandmarkMesh) -> void:
	# Side ancestral & Kuan Yin cloister wings (`x = ±15.5 m`) + bronze incense鼎 & red lanterns
	for sx in [-1.0, 1.0]:
		var wc := Vector3(float(sx) * 15.5, 0.4, 0.0)
		lm.box("Granite", wc + Vector3(0, 2.7, 0), Vector3(6.8, 5.4, 48.0))
		lm.gable("GreenTile", wc + Vector3(0, 5.4, 0), 8.2, 49.6, 2.1, Basis(), 0.45, "Gold")
	# Central bronze/gold incense cauldron + glowing red lantern rows across the incense court
	lm.frustum("Gold", Vector3(0, 0.4, 1.5), 0.95, 1.15, 1.45, 10)
	for lx in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		for lz in [-1.5, 4.5, 21.5]:
			lm.lathe("LanternLamp", Vector3(float(lx), 4.2, float(lz)), PackedVector2Array([
				Vector2(0.08, 0.0), Vector2(0.32, 0.18), Vector2(0.32, 0.42), Vector2(0.08, 0.58)]), 8)

static func _chinese_dragon_roof(lm: LandmarkMesh, eave: Vector3, w: float, d: float,
		rise: float, dragon_h: float) -> void:
	lm.gable("GreenTile", eave, d, w, rise, Basis(Vector3.UP, PI * 0.5), 0.55, "Gold")
	var ridge_y := eave.y + rise
	# Upturned swallowtail ridge horns (`front.jpg`) + twin dragons flanking central flaming pearl
	for sx in [-1.0, 1.0]:
		var end_p := Vector3(eave.x + float(sx) * w * 0.48, ridge_y - 0.1, eave.z)
		lm.beam("GreenTile", end_p, end_p + Vector3(float(sx) * 1.15, dragon_h * 0.88, 0.0), 0.34, 0.34)
		lm.box("Gold", Vector3(eave.x + float(sx) * 2.4, ridge_y + dragon_h * 0.38, eave.z),
			Vector3(2.8, dragon_h * 0.56, 0.38))
	lm.lathe("Gold", Vector3(eave.x, ridge_y, eave.z), PackedVector2Array([
		Vector2(0.32, 0.0), Vector2(0.46, dragon_h * 0.48), Vector2(0.04, dragon_h)]), 10)
