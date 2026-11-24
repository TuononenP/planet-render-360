class_name VnRialtoEnsemble
extends RefCounted

## Rialto Bridge Grand Canal historic commercial ensemble (`VN-5.4`–`VN-5.6`):
## - Fondaco dei Tedeschi (massive ochre Renaissance palazzo, 5 water-gate arches, crenellated parapet)
## - Palazzo dei Camerlenghi (pentagonal Istrian-stone Renaissance treasury at Rialto foot)
## - Rialto Market Fabbriche & 1907 Neo-Gothic Pescheria fish-market loggia

static func fondaco_dei_tedeschi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkVnKit.stucco("#DFB77E", 3.0))
	lm.use("Stone", LandmarkVnKit.istrian("#EDE7DA", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E8", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.6))
	lm.use("Wood", LandmarkVnKit.dark_wood("#6D4E35", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.9))

	# Massive courtyard quadrangle (48 x 46 m, height 24.0 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(48.4, 0.6, 46.4))
	lm.box("Stone", Vector3(0.0, 2.8, 0.0), Vector3(48.2, 4.8, 46.2))
	lm.box("Wall", Vector3(0.0, 12.8, 0.0), Vector3(48.0, 15.6, 46.0))
	for sy in [5.2, 10.4, 15.6, 20.6]:
		lm.box("Trim", Vector3(0.0, float(sy), 0.0), Vector3(48.6, 0.44, 46.6))
	# Five wide Istrian-stone water-gate portico arches along the Grand Canal (+Z)
	for i in 5:
		var x := -11.2 + 5.6 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 2.6, 23.14), Vector3(0, 0, 1), 4.0, 4.4, true, 0.28)
		lm.box("Lamp", Vector3(x, 4.8, 22.8), Vector3(0.36, 0.42, 0.36))
	# Regular Renaissance window grid on 3 upper stories
	for sy in [7.6, 12.8, 17.8]:
		for i in 9:
			var x := -19.2 + 4.8 * float(i)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, float(sy), 23.06), Vector3(0, 0, 1), 1.7, 3.2, false, 0.16)
	# Iconic Venetian crenellated marble merlons along all four eaves + rooftop wooden terrace
	for i in 22:
		var x := -22.5 + 2.14 * float(i)
		lm.box("Trim", Vector3(x, 21.35, 23.0), Vector3(1.1, 1.1, 0.45))
		lm.box("Trim", Vector3(x, 21.35, -23.0), Vector3(1.1, 1.1, 0.45))
	lm.gable("Roof", Vector3(0.0, 20.8, 0.0), 46.2, 48.2, 2.8, Basis(Vector3.UP, PI * 0.5), 0.3, "Wall")
	lm.box("Wood", Vector3(0.0, 23.6, 0.0), Vector3(22.0, 0.6, 16.0))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 48.0, 46.0, 24.0, 0.9)

static func palazzo_camerlenghi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#EFEAE0", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 1.8))
	lm.use("Porphyry", LandmarkMaterials.pbr("stone", "#863434", 1.5))
	lm.use("Roof", LandmarkVnKit.terracotta("#9D614B", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.8))

	# Pentagonal/prow Istrian-stone Renaissance treasury right beside Rialto Bridge (height 17.5 m)
	var pent := PackedVector2Array([
		Vector2(-15.0, -9.5), Vector2(10.0, -9.5), Vector2(15.5, 0.0),
		Vector2(10.0, 9.5), Vector2(-15.0, 9.5),
	])
	lm.poly_prism("Algae", pent, -0.2, 0.55)
	lm.poly_prism("Stone", pent, 0.55, 15.2)
	lm.poly_prism("Trim", pent, 5.2, 5.6)
	lm.poly_prism("Trim", pent, 10.2, 10.6)
	lm.poly_prism("Trim", pent, 14.9, 15.5)
	for sy in [2.8, 7.8, 12.6]:
		for sx in [-10.0, -4.0, 2.0, 7.5]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), float(sy), 9.56), Vector3(0, 0, 1), 2.1, 3.6, true, 0.20)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), float(sy), -9.56), Vector3(0, 0, -1), 2.1, 3.6, true, 0.20)
			if sy > 6.0:
				lm.disc("Porphyry", Vector3(float(sx) + 2.8, float(sy) + 1.4, 9.60), Vector3(0, 0, 1), 0.42, 10)
		# Decorate the angled prow faces (+X) & west rear (-X) so Rialto canal approach shows full Renaissance arches
		for sz_p: float in [-4.5, 4.5]:
			var nrm := Vector3(9.5, 0.0, signf(sz_p) * 5.5).normalized()
			var prow_x := 10.0 + (9.5 - absf(sz_p)) / 9.5 * 5.5
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(prow_x, float(sy), sz_p) + nrm * 0.06, nrm, 2.0, 3.5, true, 0.20)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-15.06, float(sy), sz_p), Vector3(-1, 0, 0), 2.0, 3.5, true, 0.20)
	lm.gable("Roof", Vector3(-1.5, 15.4, 0.0), 19.2, 27.5, 2.1, Basis(Vector3.UP, PI * 0.5), 0.25, "Stone")
	lm.box("Lamp", Vector3(0.0, 4.8, 9.5), Vector3(6.0, 0.45, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 30.0, 20.0, 17.5, 0.85)

static func rialto_mercato_pescheria(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B85840", 2.6))
	lm.use("Wall", LandmarkVnKit.stucco("#E2C69E", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F4EB", 1.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.9))

	# West half (-X): 1907 Neo-Gothic Pescheria open brick-and-Istrian fish-market loggia (height 15.0 m)
	lm.box("Algae", Vector3(-16.0, 0.2, 0.0), Vector3(32.4, 0.5, 18.4))
	lm.box("Stone", Vector3(-16.0, 0.9, 0.0), Vector3(32.0, 1.0, 18.0))
	# Open ground loggia of pointed stone columns supporting red-brick upper gallery
	for i in 8:
		var x := -30.0 + 4.0 * float(i)
		for z in [-8.2, 8.2]:
			LandmarkDetail.column(lm, "Trim", Vector3(x, 1.4, float(z)), 0.34, 5.2, "corinthian", 8)
	lm.box("Brick", Vector3(-16.0, 9.2, 0.0), Vector3(31.4, 5.2, 17.4))
	LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(-16.0, 7.6, 8.75), Vector3.RIGHT, Vector3(0, 0, 1), 7, 2.0, 3.4, false)
	lm.gable("Roof", Vector3(-16.0, 11.8, 0.0), 18.2, 32.0, 3.2, Basis(Vector3.UP, PI * 0.5), 0.3, "Brick")
	for lx in [-24.0, -16.0, -8.0]:
		lm.box("Lamp", Vector3(float(lx), 5.8, 7.4), Vector3(0.42, 0.48, 0.42))

	# East half (+X): Sansovino's Fabbriche Nuove arcaded market colonnade (height 18.0 m)
	lm.box("Algae", Vector3(17.5, 0.2, 0.0), Vector3(33.4, 0.5, 20.4))
	lm.box("Stone", Vector3(17.5, 3.2, 0.0), Vector3(33.0, 5.6, 20.0))
	lm.box("Wall", Vector3(17.5, 10.8, 0.0), Vector3(33.0, 9.6, 20.0))
	lm.gable("Roof", Vector3(17.5, 15.6, 0.0), 20.4, 33.4, 2.4, Basis(Vector3.UP, PI * 0.5), 0.25, "Wall")
	for i in 7:
		var x := 4.0 + 4.5 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 3.0, 10.08), Vector3(0, 0, 1), 2.8, 4.6, true, 0.24)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 9.0, 10.06), Vector3(0, 0, 1), 1.6, 3.2, false, 0.16)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 13.4, 10.06), Vector3(0, 0, 1), 1.4, 2.4, false, 0.16)
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 66.0, 20.0, 18.0, 0.85)
