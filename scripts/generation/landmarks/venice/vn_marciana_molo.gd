class_name VnMarcianaMolo
extends RefCounted

## Piazzetta, Molo & Riva degli Schiavoni monumental landmarks (`VN-4.2`–`VN-4.5`):
## - Biblioteca Nazionale Marciana & La Zecca (Sansovino's two-tier classical arcade + roof statues)
## - Torre dell'Orologio (deep-blue & gold astronomical zodiac clock + winged lion + bronze Mori)
## - Colonne di San Marco e San Todaro (twin granite Piazzetta columns + bronze Lion & St Theodore)
## - Palazzo delle Prigioni Nuove & Hotel Danieli (Palazzo Dandolo pink Venetian Gothic)

static func biblioteca_marciana(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 2.0))
	lm.use("Rustic", LandmarkVnKit.istrian("#DCD5C4", 2.4))
	lm.use("Roof", LandmarkVnKit.lead_dome("#858B90", 2.2))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE1A0", 1.9))

	# Biblioteca Marciana facing Doge's Palace (+X, length 78 m along Z, width 19 m, height 22.0 m to statues)
	var eave := 17.6
	lm.box("Stone", Vector3(8.5, eave * 0.5, 0.0), Vector3(18.0, eave, 78.0))
	lm.box("Trim", Vector3(8.5, 7.6, 0.0), Vector3(19.0, 0.75, 79.0))
	lm.box("Trim", Vector3(8.5, eave - 0.5, 0.0), Vector3(19.6, 1.1, 79.6))
	lm.gable("Roof", Vector3(8.5, eave, 0.0), 18.4, 78.4, 2.2, Basis(), 0.25, "Stone")
	# 17 bays of Doric ground & Ionic upper classical arcades along the Piazzetta (+X)
	var bays := 17
	for i in bays:
		var z := -35.0 + 70.0 * (float(i) + 0.5) / float(bays)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(17.56, 3.6, z), Vector3(1, 0, 0), 2.3, 5.6, true, 0.24)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(17.56, 12.0, z), Vector3(1, 0, 0), 2.2, 5.8, true, 0.24)
		if i % 3 == 1:
			lm.box("Lamp", Vector3(17.0, 6.4, z), Vector3(0.36, 0.44, 0.36))
	for i in bays + 1:
		var z := -35.0 + 70.0 * float(i) / float(bays)
		LandmarkDetail.column(lm, "Trim", Vector3(17.75, 0.0, z), 0.32, 7.2, "doric", 8)
		LandmarkDetail.column(lm, "Trim", Vector3(17.75, 8.0, z), 0.28, 7.8, "ionic", 8)
		# Iconic rooftop balustrade lined with classical statues & obelisks (top = 22.0 m)
		if i % 2 == 0:
			LandmarkKits.statue_figure(lm, "Trim", Vector3(17.5, eave + 1.2, z), 3.1)
		else:
			lm.spire("Trim", Vector3(17.5, eave + 1.2, z), 0.36, 2.6, 0.0, 4)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(17.5, eave + 0.05, -38.5), Vector3(17.5, eave + 0.05, 38.5), 1.15, 3.5)
	# South Molo facade (+Z facing the Bacino di San Marco): 3-bay Sansovino classical arcade + roof statues
	for i in 3:
		var mx := 2.8 + 5.6 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(mx, 3.6, 39.06), Vector3(0, 0, 1), 2.4, 5.6, true, 0.24)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(mx, 12.0, 39.06), Vector3(0, 0, 1), 2.3, 5.8, true, 0.24)
		LandmarkKits.statue_figure(lm, "Trim", Vector3(mx, eave + 1.2, 38.8), 3.0)
	for i in 4:
		var cx := 0.0 + 5.6 * float(i)
		LandmarkDetail.column(lm, "Trim", Vector3(cx, 0.0, 39.25), 0.32, 7.2, "doric", 8)
		LandmarkDetail.column(lm, "Trim", Vector3(cx, 8.0, 39.25), 0.28, 7.8, "ionic", 8)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-0.2, eave + 0.05, 38.8), Vector3(17.4, eave + 0.05, 38.8), 1.15, 2.6)

	# Adjoining La Zecca (Old Venetian Mint, heavy banded rustication on -X / Molo south +Z)
	lm.box("Rustic", Vector3(-10.0, 9.2, 14.0), Vector3(19.0, 18.4, 46.0))
	lm.box("Trim", Vector3(-10.0, 18.6, 14.0), Vector3(19.8, 0.7, 46.8))
	for i in 7:
		var z := -6.0 + 6.5 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-19.55, 11.4, z), Vector3(-1, 0, 0), 2.0, 4.4, false, 0.22)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-19.55, 4.0, z), Vector3(-1, 0, 0), 2.2, 5.2, true, 0.24)
	# La Zecca Molo south front (+Z facing Bacino)
	for i in 4:
		var zx := -16.8 + 4.5 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(zx, 3.6, 37.08), Vector3(0, 0, 1), 2.3, 5.4, true, 0.24)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(zx, 11.4, 37.08), Vector3(0, 0, 1), 2.0, 4.4, false, 0.22)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(27.0, 1.5, -20.0), Vector3(17.5, 12.0, -20.0), 54.0, 0.95],
		[Vector3(27.0, 1.5, 20.0), Vector3(17.5, 12.0, 20.0), 54.0, 0.95],
		[Vector3(0.0, 1.5, 48.0), Vector3(0.0, 12.0, 38.0), 54.0, 0.85],
	])

static func torre_orologio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E9", 1.8))
	lm.use("Blue", LandmarkMaterials.pbr("stone", "#1E3C7A", 1.8, 0.35, 0.25))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#484032", 1.8, 0.38, 0.76))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242B30"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE39C", 2.3))

	# Flanking side wings connecting to Procuratie Vecchie + central 25.5 m clock tower body
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 7.8, 9.6, 0.0), Vector3(5.6, 19.2, 8.2))
		lm.box("Trim", Vector3(sx * 7.8, 19.4, 0.0), Vector3(6.0, 0.5, 8.6))
		for sy in [7.2, 13.8]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(sx * 7.8, float(sy), 4.15), Vector3(0, 0, 1), 1.8, 3.6, true, 0.16)
	# Central tower shaft with wide Mercerie ground archway (+Z faces Piazza San Marco)
	lm.box("Stone", Vector3(-3.6, 4.2, 0.0), Vector3(2.8, 8.4, 9.0))
	lm.box("Stone", Vector3(3.6, 4.2, 0.0), Vector3(2.8, 8.4, 9.0))
	lm.box("Stone", Vector3(0.0, 16.8, 0.0), Vector3(10.0, 16.8, 9.0))
	LandmarkDetail.arch(lm, "Trim", Vector3(0.0, 5.4, 4.55), Vector3(0, 0, 1), 4.4, 0.65, 0.45)
	lm.box("Trim", Vector3(0.0, 25.4, 0.0), Vector3(10.8, 0.8, 9.8))
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-5.0, 25.8, 4.5), Vector3(5.0, 25.8, 4.5), 1.0, 2.5)

	# Dazzling deep-blue & gold astronomical zodiac clock dial (y = 12.6 m)
	lm.disc("Trim", Vector3(0.0, 12.6, 4.58), Vector3(0, 0, 1), 3.35, 24)
	lm.disc("Blue", Vector3(0.0, 12.6, 4.64), Vector3(0, 0, 1), 2.95, 24)
	lm.disc("Gold", Vector3(0.0, 12.6, 4.70), Vector3(0, 0, 1), 1.15, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.disc("Gold", Vector3(cos(a) * 2.25, 12.6 + sin(a) * 2.25, 4.72), Vector3(0, 0, 1), 0.24, 8)
	lm.box("Lamp", Vector3(0.0, 12.6, 4.68), Vector3(0.22, 2.6, 0.10))
	# Madonna & Child golden balcony tier (y = 18.2 m)
	lm.box("Trim", Vector3(0.0, 16.8, 5.1), Vector3(8.8, 0.4, 1.4))
	LandmarkKits.statue_figure(lm, "Gold", Vector3(0.0, 17.0, 4.85), 2.4, true)
	# Starred lapis-blue Winged Lion of St Mark attic panel (y = 22.4 m)
	lm.box("Blue", Vector3(0.0, 22.4, 4.58), Vector3(7.6, 3.6, 0.20))
	lm.box("Gold", Vector3(0.0, 22.4, 4.72), Vector3(3.4, 1.4, 0.25))
	# Rooftop bronze bell flanked by the two bronze Mori bell-ringers (top = 31.0 m)
	lm.box("Trim", Vector3(0.0, 26.2, 0.0), Vector3(5.6, 0.9, 5.6))
	lm.lathe("Bronze", Vector3(0.0, 26.7, 0.0), PackedVector2Array([
		Vector2(1.45, 0.0), Vector2(1.15, 0.7), Vector2(0.82, 2.4), Vector2(0.45, 3.2), Vector2(0.0, 3.5)]), 16)
	lm.frustum("Gold", Vector3(0.0, 30.1, 0.0), 0.22, 0.08, 0.9, 6)
	for sx in [-2.1, 2.1]:
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(float(sx), 26.7, 0.0), 3.4)
		lm.beam("Bronze", Vector3(float(sx), 28.4, 0.4), Vector3(float(sx) * 0.52, 28.8, 0.2), 0.14, 0.14)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.8, 14.0), Vector3(0.0, 16.0, 4.6), 46.0, 1.05],
		[Vector3(0.0, 22.0, 10.0), Vector3(0.0, 28.5, 0.0), 40.0, 0.9],
	])

static func colonne_san_marco(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.2))
	lm.use("GraniteG", LandmarkMaterials.pbr("stone", "#86847E", 2.2))
	lm.use("GraniteP", LandmarkMaterials.pbr("stone", "#A68B82", 2.2))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4A4335", 1.8, 0.38, 0.78))
	lm.use("Marble", LandmarkVnKit.istrian_trim("#F6F3EA", 1.8))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.8))

	# Two monumental granite columns spaced 24 m apart across the Molo Piazzetta entrance
	for idx in 2:
		var sx := -12.0 if idx == 0 else 12.0
		var col_mat := "GraniteP" if idx == 0 else "GraniteG"
		# Octagonal stepped Istrian pedestal
		for k in 5:
			var r := 3.6 - 0.35 * float(k)
			lm.frustum("Stone", Vector3(sx, 0.35 * float(k), 0.0), r, r, 0.36, 8, PI / 8.0)
		lm.box("Stone", Vector3(sx, 2.9, 0.0), Vector3(2.8, 2.4, 2.8))
		# Monolithic 11 m granite shaft + ornate Veneto-Byzantine capital + abacus
		lm.frustum(col_mat, Vector3(sx, 4.1, 0.0), 0.92, 0.80, 10.2, 16)
		lm.frustum("Stone", Vector3(sx, 14.3, 0.0), 0.85, 1.35, 1.25, 12)
		lm.box("Stone", Vector3(sx, 15.8, 0.0), Vector3(2.6, 0.55, 2.6))
		if idx == 1:
			# East column: Bronze Winged Lion of St Mark (top = 18.0 m)
			lm.box("Bronze", Vector3(sx, 16.75, 0.0), Vector3(2.3, 0.95, 0.85))
			lm.box("Bronze", Vector3(sx + 1.05, 17.35, 0.0), Vector3(0.75, 0.75, 0.72))
			for sw in [-1.0, 1.0]:
				lm.beam("Bronze", Vector3(sx - 0.2, 17.0, sw * 0.35),
					Vector3(sx - 1.15, 18.0, sw * 0.65), 0.65, 0.16)
		else:
			# West column: Marble St Theodore standing on crocodile/dragon (top = 18.0 m)
			lm.box("Marble", Vector3(sx, 16.3, 0.0), Vector3(1.8, 0.45, 0.75))
			LandmarkKits.statue_figure(lm, "Marble", Vector3(sx, 16.45, 0.0), 1.55, true)
		lm.box("Lamp", Vector3(sx, 2.2, 1.55), Vector3(0.32, 0.32, 0.22))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.2, 7.5), Vector3(-12.0, 14.0, 0.0), 38.0, 0.95],
		[Vector3(12.0, 1.2, 7.5), Vector3(12.0, 14.0, 0.0), 38.0, 0.95],
	])

static func prigioni_danieli(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rustic", LandmarkVnKit.istrian("#DCD5C6", 2.6))
	lm.use("Rose", LandmarkVnKit.stucco("#D99482", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F6F2E8", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B5F48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.8))

	# West block (-X): Palazzo delle Prigioni Nuove (rusticated grey-white Istrian stone, 18.5 m)
	lm.box("Algae", Vector3(-24.0, 0.2, 0.0), Vector3(44.4, 0.5, 42.4))
	lm.box("Rustic", Vector3(-24.0, 8.2, 0.0), Vector3(44.0, 15.8, 42.0))
	lm.box("Trim", Vector3(-24.0, 7.4, 0.0), Vector3(44.8, 0.55, 42.8))
	lm.box("Trim", Vector3(-24.0, 16.2, 0.0), Vector3(45.2, 0.75, 43.2))
	lm.gable("Roof", Vector3(-24.0, 16.5, 0.0), 42.4, 44.4, 2.2, Basis(Vector3.UP, PI * 0.5), 0.25, "Rustic")
	for i in 7:
		var x := -42.0 + 6.0 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 3.6, 21.08), Vector3(0, 0, 1), 2.8, 5.4, true, 0.24)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 11.4, 21.08), Vector3(0, 0, 1), 2.0, 4.0, false, 0.20)

	# East block (+X): Hotel Danieli / Palazzo Dandolo (iconic pink Venetian Gothic on Riva degli Schiavoni, 22.0 m)
	LandmarkVnKit.palazzo_block(lm, "Rose", "Trim", "Roof", "Glass", "Algae",
		Vector3(24.0, 0.0, 0.0), 44.0, 38.0, 22.0, 6, 4, 2.5)
	lm.box("Lamp", Vector3(24.0, 7.8, 19.0), Vector3(12.0, 2.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 90.0, 42.0, 22.0, 0.85)
