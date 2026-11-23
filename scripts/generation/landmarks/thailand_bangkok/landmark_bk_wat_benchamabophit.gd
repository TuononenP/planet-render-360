class_name LandmarkBkWatBenchamabophit
extends RefCounted

## Wat Benchamabophit Dusitvanaram — The Marble Temple (`วัดเบญจมบพิตรดุสิตวนาราม`) — BK-11
## Site: OSM way 31987500, centroid 13.766575, 100.514040 (`height_m: 28.0`, `yaw_deg: -66.0`).
## Spec (Prince Narisara Nuwattiwong 1899–1911, Commons `front.jpg`):
##   - Cruciform white Italian Carrara marble ordination hall (`Phra Ubosot`, `44 × 40 m`)
##     standing on a white marble balustraded terrace guarded by two carved white marble
##     *singha* lions flanking the front portico steps.
##   - Four-tiered cascading golden-orange Chinese glazed tile roofs (`#DA7B1E`) with
##     crimson-and-gold eave friezes, ornate gilded *chofa* gables over each of the four
##     arms, and a central crossing finial reaching `28.0 m`.
##   - White Carrara marble courtyard paving (`front.jpg`) enclosed at the rear (`-X`) by
##     the square *Phra Rabiang* gallery cloister housing 52 bronze Buddha images, flanked
##     by two Victorian white lantern standards & two crimson-and-cream cast-iron canal
##     footbridges with ornate filigree arches.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 28.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F1F0EB", 3.0))
	lm.use("CourtStone", LandmarkMaterials.pbr("pavement", "#5C5B57", 2.5))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#DA7B1E", 2.0))
	lm.use("Crimson", LandmarkMaterials.pbr("terracotta", "#9A2824", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#221C18", 0.85, 0.05))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#436B2E", 4.0))
	lm.use("CourtLamp", LandmarkMaterials.lit("#FFF2CE", 2.2))

	_marble_court_and_bridges(lm)
	_cruciform_marble_ubosot(lm)
	_rear_buddha_cloister(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(28.0, 2.5, 16.0), Vector3(4.0, 14.0, 0.0), 68.0, 1.45, 42.0, Color(1.0, 0.90, 0.68)],
		[Vector3(28.0, 2.5, -16.0), Vector3(4.0, 14.0, 0.0), 68.0, 1.45, 42.0, Color(1.0, 0.90, 0.68)],
		[Vector3(-32.0, 2.5, 0.0), Vector3(-12.0, 12.0, 0.0), 62.0, 1.10, 40.0, Color(1.0, 0.88, 0.66)],
	])

static func _marble_court_and_bridges(lm: LandmarkMesh) -> void:
	# Dark-stone forecourt paving (`front.jpg`) + lawn strips + Victorian white lamp standards
	lm.box("CourtStone", Vector3(24.0, 0.12, 0.0), Vector3(28.0, 0.24, 44.0))
	for sz in [-1.0, 1.0]:
		var z := float(sz) * 18.0
		lm.box("Grass", Vector3(24.0, 0.16, z), Vector3(22.0, 0.28, 7.0))
		# Ornate white cast-iron Victorian lamp standard (`front.jpg`)
		var lp := Vector3(19.5, 0.24, float(sz) * 12.8)
		lm.frustum("Marble", lp, 0.42, 0.28, 1.2, 8)
		lm.frustum("Marble", lp + Vector3(0, 1.2, 0), 0.16, 0.11, 5.4, 8)
		lm.lathe("CourtLamp", lp + Vector3(0, 6.6, 0), PackedVector2Array([
			Vector2(0.14, 0.0), Vector2(0.36, 0.34), Vector2(0.08, 0.64)]), 8)
		lm.lathe("Marble", lp + Vector3(0, 7.18, 0), PackedVector2Array([
			Vector2(0.42, 0.0), Vector2(0.04, 0.32)]), 8)
		# Signature arched red-and-cream cast-iron canal footbridge on N & S sides
		var bc := Vector3(8.0, 0.2, float(sz) * 26.5)
		lm.box("Crimson", bc + Vector3(0, 1.15, 0), Vector3(4.2, 0.42, 9.6))
		lm.box("Marble", bc + Vector3(0, 1.42, 0), Vector3(4.0, 0.14, 9.6))
		for rail_x in [-1.9, 1.9]:
			lm.beam("Crimson", bc + Vector3(float(rail_x), 1.48, -4.8),
				bc + Vector3(float(rail_x), 2.25, 0.0), 0.12, 0.12)
			lm.beam("Crimson", bc + Vector3(float(rail_x), 2.25, 0.0),
				bc + Vector3(float(rail_x), 1.48, 4.8), 0.12, 0.12)
			lm.box("Gold", bc + Vector3(float(rail_x), 2.45, 0.0), Vector3(0.22, 0.38, 0.22))

static func _cruciform_marble_ubosot(lm: LandmarkMesh) -> void:
	# Raised white Carrara marble terrace (`38 × 36 m`) with pierced marble balustrade
	var cx := 4.0
	K.plinth(lm, "Marble", Vector3(cx, 0.2, 0.0), Basis(), 36.0, 38.0, 1.45)
	var ring := [Vector3(cx - 17.5, 1.65, -18.5), Vector3(cx + 17.5, 1.65, -18.5),
		Vector3(cx + 17.5, 1.65, 18.5), Vector3(cx - 17.5, 1.65, 18.5)]
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		lm.beam("Marble", a + Vector3(0, 0.85, 0), b + Vector3(0, 0.85, 0), 0.26, 0.18)
		var np := int(a.distance_to(b) / 1.8)
		for k in np + 1:
			var pp := a.lerp(b, float(k) / float(maxi(np, 1)))
			lm.box("Marble", pp + Vector3(0, 0.42, 0), Vector3(0.20, 0.82, 0.20))

	# Front east stairs (`+X`) flanked by two carved white marble *singha* guardian lions
	U.stairs(lm, "Marble", Vector3(cx + 17.5, 1.65, 0.0), Basis(Vector3.UP, PI * 0.5), 6.2, 6, 0.34, 0.24)
	for sz in [-1.0, 1.0]:
		var sp := Vector3(cx + 15.8, 1.65, float(sz) * 3.6)
		lm.box("Marble", sp + Vector3(0, 0.45, 0), Vector3(1.4, 0.9, 1.1))
		K2.chinese_guardian(lm, "Marble", sp + Vector3(0, 0.9, 0), Basis(Vector3.UP, PI * 0.5), 1.95)

	# Cruciform Carrara marble walls + stepped side wings (`front.jpg` cascading 4-tier profile)
	var y0 := 1.65
	# E-W main nave (`32 m` along X, `11.6 m` wide) + N-S transept (`34 m` along Z, `11.2 m` wide)
	lm.box("Marble", Vector3(cx, y0 + 5.2, 0.0), Vector3(31.0, 10.4, 11.4))
	lm.box("Marble", Vector3(cx, y0 + 5.2, 0.0), Vector3(11.4, 10.4, 33.0))
	# Lower flanking chapel wings giving the signature wide 5-gable front silhouette (`front.jpg`)
	lm.box("Marble", Vector3(cx, y0 + 3.4, 0.0), Vector3(18.5, 6.8, 25.0))
	for sz in [-1.0, 1.0]:
		var wing_z := float(sz) * 14.5
		K.thai_roof(lm, "Orange", "Crimson", "Gold", "Marble", Vector3(cx, y0 + 6.8, wing_z),
			Basis(Vector3.UP, PI * 0.5), 7.2, 19.5, 3.4, 0.9, 1, 2, 1.3)

	# 4-column white marble front & rear porticos + gilded multi-arch doorway & windows
	for sx in [-1.0, 1.0]:
		var face_x := cx + float(sx) * 15.55
		var fb := Basis(Vector3.UP, PI * 0.5 if sx > 0 else -PI * 0.5)
		K.thai_window(lm, "Gold", "Dark", "Gold", Vector3(face_x, y0 + 0.4, 0.0), fb, 2.8, 5.8)
		for kz in [-4.2, -1.6, 1.6, 4.2]:
			K.thai_column(lm, "Marble", "Gold", Vector3(cx + float(sx) * 16.6, y0, float(kz)), 0.46, 9.8)
	for sz in [-1.0, 1.0]:
		var face_z := float(sz) * 16.55
		var sb := Basis(Vector3.UP, 0.0 if sz > 0 else PI)
		K.thai_window(lm, "Gold", "Dark", "Gold", Vector3(cx, y0 + 0.4, face_z), sb, 2.5, 5.2)
		for kx in [-6.8, 6.8]:
			K.thai_window(lm, "Gold", "Dark", "Gold", Vector3(cx + float(kx), y0 + 1.2, float(sz) * 12.55), sb, 1.9, 3.8)

	# Four-tiered golden-orange glazed cruciform roofs + crossing ridge finial to `28.0 m`
	K.thai_roof(lm, "Orange", "Crimson", "Gold", "Gold", Vector3(cx, y0 + 10.4, 0.0),
		Basis(Vector3.UP, PI * 0.5), 12.4, 33.4, 9.8, 1.25, 3, 2, 2.1)
	K.thai_roof(lm, "Orange", "Crimson", "Gold", "Gold", Vector3(cx, y0 + 10.4, 0.0),
		Basis(), 12.0, 35.0, 9.4, 1.20, 3, 2, 2.0)
	# Central gilded crossing pinnacle reaching 28.0 m
	lm.frustum("Gold", Vector3(cx, 22.0, 0.0), 1.35, 0.42, 3.2, 8)
	lm.spire("Gold", Vector3(cx, 25.2, 0.0), 0.36, HEIGHT_M - 25.2, 0.0, 8)

static func _rear_buddha_cloister(lm: LandmarkMesh) -> void:
	# Square white marble *Phra Rabiang* gallery attached behind (`-X`) the ubosot
	U.cloister(lm, "Marble", "Orange", Vector3(-19.5, 0.3, 0.0), 14.0, 17.0, 3.6, 4.4, 1.8)
	for i in 8:
		var z := -12.0 + float(i) * 3.4
		K.seated_buddha(lm, "Dark", Vector3(-31.2, 0.9, z), Basis(Vector3.UP, PI * 0.5), 1.35)
