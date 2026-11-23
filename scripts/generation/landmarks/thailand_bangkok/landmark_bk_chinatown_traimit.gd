class_name LandmarkBkChinatownTraimit
extends RefCounted

## Wat Traimit (Temple of the Golden Buddha) & Odeon Circle Chinatown Gate — BK-11
## Grouped row (`chinatown_gate_wat_traimit`) so both Chinatown icons share one Ultra slot:
##   1. Origin (`13.737746, 100.513646`, `yaw_deg: -9.0`, OSM way 342811168):
##      *Phra Maha Mondop* of Wat Traimit (`58 × 35 m`, 2009), a gleaming 4-storey white
##      marble & gold stepped royal mondop housing the 5.5-tonne Sukhothai Golden Buddha,
##      with corner *mondop* pavilions, colonnaded upper sanctuary, and 9-tier gilded spire
##      reaching `52.0 m` (`aerial.jpg`), paired with the cream-and-gold Phra Ubosot (`front.jpg`).
##   2. Odeon Circle **Chinatown Gate** (*King's Birthday Celebration Arch* / `ซุ้มประตูเฉลิมพระเกียรติ`,
##      OSM way 342812020 at `13.73718, 100.51298` -> local offset `(-72.0, 0.0, 62.0)` m):
##      crimson four-pillar Chinese ceremonial *paifang* arch (`15.8 m` tall) on a circular
##      planted roundabout island, three orange-gold ceramic roofs with twin ceramic dragons,
##      blue-and-gold imperial plaque (`圣寿无疆`), stone lions & glowing red silk lanterns (`aerial.jpg`).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 52.0
const GATE_OFFSET := Vector3(-72.0, 0.0, 62.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F3F1EB", 3.2))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#F4EAD2", 2.8))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D8821C", 2.0))
	lm.use("Crimson", LandmarkMaterials.pbr("concrete", "#C41E1E", 2.2, 0.42))
	lm.use("PlaqueBlue", LandmarkMaterials.pbr("slate", "#1E3A6E", 1.8))
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#B8B4A8", 2.5))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#426C2C", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#241D18", 0.85, 0.05))
	lm.use("LanternLamp", LandmarkMaterials.lit("#FF4228", 2.6))

	_phra_maha_mondop(lm)
	_wat_traimit_ubosot(lm)
	_odeon_chinatown_gate(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-26.0, 3.0, 26.0), Vector3(0.0, 30.0, 0.0), 82.0, 1.55, 44.0, Color(1.0, 0.90, 0.64)],
		[Vector3(26.0, 3.0, -24.0), Vector3(0.0, 30.0, 0.0), 82.0, 1.35, 44.0, Color(1.0, 0.90, 0.64)],
		[GATE_OFFSET + Vector3(0.0, 1.8, 16.0), GATE_OFFSET + Vector3(0.0, 10.5, 0.0), 42.0, 1.45, 36.0, Color(1.0, 0.86, 0.62)],
		[GATE_OFFSET + Vector3(0.0, 1.8, -16.0), GATE_OFFSET + Vector3(0.0, 10.5, 0.0), 42.0, 1.35, 36.0, Color(1.0, 0.86, 0.62)],
	])

static func _phra_maha_mondop(lm: LandmarkMesh) -> void:
	# 3-level stepped white marble podium (`48 × 34 m`, `0..15.5 m`) with axial grand stairs
	K.plinth(lm, "Marble", Vector3.ZERO, Basis(), 48.0, 34.0, 4.8)
	K.plinth(lm, "Marble", Vector3(0, 4.8, 0), Basis(), 40.0, 28.0, 5.2)
	K.plinth(lm, "Marble", Vector3(0, 10.0, 0), Basis(), 32.0, 23.0, 5.2)
	U.stairs(lm, "Marble", Vector3(-24.0, 15.2, 0.0), Basis(Vector3.UP, -PI * 0.5), 7.6, 18, 0.42, 0.84)
	K2.naga_rail(lm, "Marble", "Gold", Vector3(-31.6, 0.0, -4.1), Vector3(-24.0, 15.2, -4.1), 0.85)
	K2.naga_rail(lm, "Marble", "Gold", Vector3(-31.6, 0.0, 4.1), Vector3(-24.0, 15.2, 4.1), 0.85)

	# Four corner white-and-gold *mondop* pavilions on the upper terrace (`aerial.jpg`)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cp := Vector3(float(sx) * 12.2, 15.2, float(sz) * 8.4)
			lm.box("Marble", cp + Vector3(0, 2.3, 0), Vector3(5.2, 4.6, 5.2))
			K.thai_roof(lm, "Orange", "Gold", "Gold", "Marble", cp + Vector3(0, 4.6, 0),
				Basis(), 6.2, 6.2, 2.8, 0.7, 2, 1, 1.1)

	# Tall white marble & fluted-pilaster Golden Buddha sanctuary (`15.2..28.6 m`) + 4-face gables
	var sy := 15.2
	lm.box("Marble", Vector3(0, sy + 6.7, 0), Vector3(17.6, 13.4, 15.6))
	K.peristyle(lm, "Marble", "Gold", Vector3(0, sy, 0), Basis(), 19.6, 17.6, 13.0, 0.56, 3.8)
	# Golden Buddha visible inside the west entrance portal (`-X`)
	K.thai_window(lm, "Gold", "Dark", "Gold", Vector3(-8.85, sy + 0.8, 0.0), Basis(Vector3.UP, -PI * 0.5), 3.6, 7.6)
	K.seated_buddha(lm, "Gold", Vector3(-2.5, sy + 1.4, 0.0), Basis(Vector3.UP, -PI * 0.5), 4.6)
	for arm in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(arm))
		K.thai_roof(lm, "Orange", "Gold", "Gold", "PlaqueBlue", Vector3(0, sy + 9.2, 0),
			b, 9.6, 22.4, 4.6, 1.0, 2, 2, 1.5)

	# Stepped gilded *Phra Maha Mondop* pyramidal crown & spire (`28.6..52.0 m`, `aerial.jpg`)
	var py := 28.6
	for i in 5:
		var t := float(i) / 5.0
		var w := lerpf(15.2, 5.6, t)
		var d := lerpf(14.0, 5.2, t)
		var h := 1.85
		lm.box("Gold", Vector3(0, py + h * 0.5, 0), Vector3(w, h, d))
		lm.box("Orange", Vector3(0, py + h - 0.25, 0), Vector3(w + 1.1, 0.45, d + 1.1))
		py += h
	U.prasat_spire(lm, "Marble", "Orange", "Gold", Vector3(0, py, 0), 2.5, HEIGHT_M - py, 4)

static func _wat_traimit_ubosot(lm: LandmarkMesh) -> void:
	# Cream-and-gold ordination hall (`front.jpg` & `quarter.jpg`) set immediately south-east
	var uc := Vector3(18.0, 0.0, -24.0)
	K.plinth(lm, "Stone", uc, Basis(), 28.0, 16.0, 1.2)
	lm.box("Cream", uc + Vector3(0, 5.2, 0), Vector3(24.0, 8.0, 12.6))
	K.thai_roof(lm, "Orange", "Gold", "Gold", "PlaqueBlue", uc + Vector3(0, 9.2, 0),
		Basis(Vector3.UP, PI * 0.5), 13.8, 26.2, 5.6, 1.15, 2, 2, 1.6)

static func _odeon_chinatown_gate(lm: LandmarkMesh) -> void:
	# Odeon Circle planted concrete roundabout island (`r = 12.5 m`) + crimson 4-pillar *paifang* (`aerial.jpg`)
	var c := GATE_OFFSET
	var gb := Basis(Vector3.UP, deg_to_rad(32.0))
	lm.frustum("Stone", c, 12.6, 12.2, 0.95, 20)
	lm.frustum("Grass", c + Vector3(0, 0.95, 0), 11.6, 11.2, 0.35, 20)

	# Four vermilion-crimson round columns (`x = -6.4, -3.2, +3.2, +6.4`, central portal tallest)
	for px_h in [[-6.4, 9.6], [-3.2, 12.4], [3.2, 12.4], [6.4, 9.6]]:
		var px := float((px_h as Array)[0])
		var ph := float((px_h as Array)[1])
		var col_p := c + gb * Vector3(px, 1.2, 0.0)
		lm.frustum("Marble", col_p, 0.72, 0.62, 0.85, 10)
		lm.frustum("Crimson", col_p + Vector3(0, 0.85, 0), 0.52, 0.48, ph, 12)
	# Guardian marble lions at the main pillars
	for sx in [-3.2, 3.2]:
		for sz in [-1.4, 1.4]:
			lm.box("Marble", c + gb * Vector3(float(sx), 1.65, float(sz)), Vector3(0.75, 0.95, 0.85), gb)

	# Imperial blue-and-gold inscribed lintel plaque (`圣寿无疆`) + crimson carved beams
	lm.box("Crimson", c + gb * Vector3(0.0, 10.6, 0.0), Vector3(7.4, 2.8, 1.25), gb)
	lm.box("Gold", c + gb * Vector3(0.0, 10.6, 0.0), Vector3(5.6, 1.9, 1.38), gb)
	lm.box("PlaqueBlue", c + gb * Vector3(0.0, 10.6, 0.0), Vector3(5.1, 1.45, 1.46), gb)
	# Flanking side-bay lintels & orange-gold upturned Chinese roofs (`y = 9.8 m` side, `13.2 m` centre)
	for sx in [-4.9, 4.9]:
		lm.box("Crimson", c + gb * Vector3(float(sx), 8.6, 0.0), Vector3(3.6, 1.6, 1.05), gb)
		_paifang_roof(lm, c + gb * Vector3(float(sx), 9.6, 0.0), gb, 4.6, 3.0, 1.15)
		# Giant hanging red silk lanterns on outer eaves (`aerial.jpg`)
		var lp := c + gb * Vector3(float(sx) * 1.48, 8.2, 0.0)
		lm.lathe("LanternLamp", lp, PackedVector2Array([
			Vector2(0.18, 0.0), Vector2(0.78, 0.35), Vector2(0.82, 0.72),
			Vector2(0.22, 1.05)]), 10)
	_paifang_roof(lm, c + gb * Vector3(0.0, 12.8, 0.0), gb, 9.6, 4.2, 1.75)
	# Twin golden ceramic dragons facing central royal emblem (`y = 14.6..16.2 m`)
	lm.lathe("Gold", c + gb * Vector3(0.0, 14.6, 0.0), PackedVector2Array([
		Vector2(0.55, 0.0), Vector2(0.68, 0.65), Vector2(0.08, 1.45)]), 10)
	for sx in [-2.2, 2.2]:
		lm.box("Gold", c + gb * Vector3(float(sx), 14.85, 0.0), Vector3(2.4, 0.62, 0.42), gb)

static func _paifang_roof(lm: LandmarkMesh, base: Vector3, gb: Basis, w: float, d: float, h: float) -> void:
	lm.box("PlaqueBlue", base + Vector3(0, 0.22, 0), Vector3(w * 0.92, 0.44, d * 0.78), gb)
	lm.gable("Orange", base + Vector3(0, 0.44, 0), d, w, h, gb * Basis(Vector3.UP, PI * 0.5), 0.35, "Gold")
	for sx in [-1.0, 1.0]:
		var tip := base + gb * Vector3(float(sx) * w * 0.52, 0.55, 0.0)
		lm.beam("Gold", tip, tip + gb * Vector3(float(sx) * 0.65, 0.68, 0.0), 0.22, 0.22)
