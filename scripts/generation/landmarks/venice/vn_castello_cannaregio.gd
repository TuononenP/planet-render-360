class_name VnCastelloCannaregio
extends RefCounted

## Cannaregio & Castello interior heritage churches (`VN-6.8`–`VN-6.10`):
## - Santa Maria dei Miracoli (Lombardo's veined polychrome marble jewel-box church & curved pediment)
## - Chiesa di San Zaccaria (Codussi's towering 5-tier Istrian Renaissance arched facade)
## - Chiesa di San Moisè (Tremignon's richly sculpted Baroque stone facade)
## - Santa Maria Formosa (white Renaissance church + 40 m Baroque onion-domed campanile)

static func santa_maria_miracoli(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkVnKit.istrian_trim("#F3EFE6", 2.0))
	lm.use("Vein", LandmarkVnKit.verona_rose("#D8B8AB", 2.2))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#BDB8AE", 2.0))
	lm.use("Porphyry", LandmarkMaterials.pbr("stone", "#863434", 1.5))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.9))

	# Jewel-box rectangular polychrome-marble church (15 x 32 m, height 22.5 m)
	lm.box("Algae", Vector3(0.0, 0.2, 0.0), Vector3(15.4, 0.5, 32.4))
	lm.box("Marble", Vector3(0.0, 7.4, 0.0), Vector3(15.0, 14.4, 32.0))
	# Recessed veined marble panels & pilasters along flanks & front
	for sy in [3.6, 10.6]:
		lm.box("Grey", Vector3(0.0, float(sy) + 3.4, 0.0), Vector3(15.5, 0.45, 32.5))
		for sx in [-5.2, -1.8, 1.8, 5.2]:
			lm.box("Vein", Vector3(float(sx), float(sy), 16.06), Vector3(2.4, 5.0, 0.14))
	# Signature semicircular arched Renaissance pediment crowning the facade (+Z) studded with marble roundels
	lm.disc("Marble", Vector3(0.0, 14.6, 16.0), Vector3(0, 0, 1), 7.6, 20)
	lm.disc("Grey", Vector3(0.0, 14.6, 16.08), Vector3(0, 0, 1), 6.8, 20)
	lm.disc("Porphyry", Vector3(0.0, 18.6, 16.14), Vector3(0, 0, 1), 1.4, 12)
	for sx in [-3.4, 3.4]:
		lm.disc("Porphyry", Vector3(float(sx), 16.4, 16.14), Vector3(0, 0, 1), 0.85, 10)
	LandmarkDetail.window(lm, "Marble", "Glass", Vector3(0.0, 3.0, 16.10), Vector3(0, 0, 1), 2.8, 5.2, true, 0.24)
	# Lead barrel-vaulted nave roof + delicate choir cupola reaching 22.5 m
	lm.gable("Lead", Vector3(0.0, 14.6, 1.0), 15.2, 28.0, 4.2, Basis(), 0.25, "Marble")
	LandmarkVnKit.venetian_dome(lm, "Marble", "Grey", "Lead", "Glass", "Gold",
		Vector3(0.0, 14.4, -12.0), 3.6, 2.2, 3.4, 1.6, 0.9)
	lm.box("Lamp", Vector3(0.0, 6.2, 16.25), Vector3(1.2, 0.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 16.0, 32.0, 22.5, 0.9)

static func san_zaccaria(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F0ECE1", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 1.8))
	lm.use("Brick", LandmarkVnKit.brick("#B25740", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C604A", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.9))

	# Mauro Codussi's soaring 5-tier Istrian Renaissance facade (height 28.0 m) fronting Gothic brick nave
	lm.box("Brick", Vector3(0.0, 9.8, -4.0), Vector3(30.0, 19.6, 44.0))
	lm.gable("Roof", Vector3(0.0, 19.6, -4.0), 30.6, 44.6, 4.4, Basis(), 0.25, "Brick")
	lm.box("Stone", Vector3(0.0, 11.4, 19.0), Vector3(31.0, 22.8, 3.2))
	for sy in [5.0, 10.6, 16.4, 22.4]:
		lm.box("Trim", Vector3(0.0, float(sy), 19.3), Vector3(31.6, 0.55, 3.4))
	# Paired classical columns & deep arched Renaissance niches across tiers 2–4 (+Z)
	for sy in [5.4, 11.0, 16.8]:
		for i in 5:
			var x := -11.2 + 5.6 * float(i)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, float(sy) + 2.4, 20.66), Vector3(0, 0, 1), 2.1, 4.2, true, 0.22)
		for i in 6:
			var cx := -14.0 + 5.6 * float(i)
			LandmarkDetail.column(lm, "Trim", Vector3(cx, float(sy), 20.85), 0.24, 5.0, "corinthian", 8)
	# Semicircular crowning Codussi lunette + side quadrants + apex statue (top = 28.0 m)
	lm.disc("Stone", Vector3(0.0, 22.6, 20.2), Vector3(0, 0, 1), 7.2, 20)
	lm.disc("Trim", Vector3(0.0, 22.6, 20.32), Vector3(0, 0, 1), 6.4, 20)
	LandmarkKits.statue_figure(lm, "Trim", Vector3(0.0, 25.8, 20.3), 2.2, true)
	lm.box("Lamp", Vector3(0.0, 4.8, 20.8), Vector3(2.2, 0.45, 0.35))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 32.0, 48.0, 28.0, 0.9)

static func chiesa_san_moise(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#E6DFD0", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F3EEE2", 1.8))
	lm.use("Brick", LandmarkVnKit.brick("#B05840", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE1A0", 1.85))

	# Alessandro Tremignon's exuberantly sculpted Baroque facade (height 24.0 m)
	lm.box("Brick", Vector3(0.0, 8.6, -2.0), Vector3(24.0, 17.2, 30.0))
	lm.gable("Roof", Vector3(0.0, 17.2, -2.0), 24.4, 30.4, 3.6, Basis(), 0.25, "Brick")
	lm.box("Stone", Vector3(0.0, 10.6, 13.8), Vector3(25.0, 21.2, 2.8))
	# Three deeply sculpted sculptural Baroque tiers with projecting coupled columns & busts
	for tier_y in [0.4, 10.8]:
		for i in 4:
			var cx := -9.6 + 6.4 * float(i)
			for dx in [-0.45, 0.45]:
				LandmarkDetail.column(lm, "Trim", Vector3(cx + float(dx), float(tier_y), 15.55), 0.34, 9.2, "corinthian", 8)
		for sx in [-6.4, 0.0, 6.4]:
			LandmarkKits.statue_figure(lm, "Trim", Vector3(float(sx), float(tier_y) + 5.2, 15.45), 2.4)
	lm.gable("Trim", Vector3(0.0, 20.6, 14.8), 16.0, 2.2, 3.4, Basis(), 0.25, "Stone")
	lm.box("Lamp", Vector3(0.0, 5.4, 15.5), Vector3(2.2, 0.45, 0.35))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 25.0, 32.0, 24.0, 0.85)

static func santa_maria_formosa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F0ECE1", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B3573E", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B5F48", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.9))

	lm.box("Stone", Vector3(-3.0, 8.6, 0.0), Vector3(26.0, 17.2, 34.0))
	lm.gable("Roof", Vector3(-3.0, 17.2, 0.0), 26.4, 34.4, 3.4, Basis(), 0.25, "Stone")
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(-3.0, 0.0, 17.2), Vector3.RIGHT, Vector3(0, 0, 1),
		26.0, 15.0, 16.0, 10.0, 3.6, 4)
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(-3.0, 17.2, 0.0), 5.6, 3.6, 5.8, 2.4, 1.2)
	# Baroque 40.0 m white-stone & brick campanile with onion cupola
	LandmarkVnKit.campanile(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(14.0, 0.0, -8.0), 6.8, 40.0, 0.0, true)
	lm.box("Lamp", Vector3(14.0, 27.6, -8.0), Vector3(4.0, 4.4, 4.0))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 34.0, 36.0, 40.0, 0.85)
