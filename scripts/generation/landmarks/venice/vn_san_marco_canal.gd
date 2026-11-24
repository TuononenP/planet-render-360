class_name VnSanMarcoCanal
extends RefCounted

## San Marco north-bank Grand Canal palaces (`VN-3.8`, `VN-3.11`, `VN-3.12`):
## - Palazzo Corner della Ca' Granda (Sansovino's monumental white Istrian-stone palazzo)
## - The Gritti Palace / Palazzo Pisani Gritti (burnt-terracotta Gothic + floating dining terrace)
## - Palazzo Ferro Fini & Contarini Fasan (twin Gothic/Renaissance palaces opposite Salute)

static func corner_ca_granda(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#EEEAE0", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F4EB", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9D604A", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A6", 1.9))

	# Sansovino's massive rusticated Istrian-stone High Renaissance palazzo (33 x 42 m, height 26.0 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(33.4, 0.6, 42.4))
	lm.box("Stone", Vector3(0.0, 11.8, 0.0), Vector3(33.0, 22.8, 42.0))
	# Heavy rusticated ground storey with triple monumental water-gate arches (+Z)
	lm.box("Trim", Vector3(0.0, 7.4, 0.0), Vector3(33.6, 0.55, 42.6))
	lm.box("Trim", Vector3(0.0, 15.2, 0.0), Vector3(33.6, 0.55, 42.6))
	lm.box("Trim", Vector3(0.0, 23.0, 0.0), Vector3(34.2, 0.85, 43.2))
	for sx in [-4.4, 0.0, 4.4]:
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 3.4, 21.08), Vector3(0, 0, 1), 3.2, 5.8, true, 0.30)
	# Two majestic upper tiers of paired Ionic & Corinthian columns framing 7 arched bays
	for tier in [7.7, 15.5]:
		for i in 7:
			var bx := -13.2 + 4.4 * float(i)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(bx, float(tier) + 3.4, 21.06),
				Vector3(0, 0, 1), 2.1, 4.8, true, 0.22)
		for i in 8:
			var cx := -15.4 + 4.4 * float(i)
			for dx in [-0.36, 0.36]:
				LandmarkDetail.column(lm, "Trim", Vector3(cx + float(dx), float(tier), 21.25), 0.26, 6.8, "corinthian", 8)
		# Arched side windows along west (-X) and east (+X) stone flanks
		for sx_f: float in [-1.0, 1.0]:
			for j in 7:
				var wz := -15.6 + 5.2 * float(j)
				LandmarkDetail.window(lm, "Trim", "Glass", Vector3(sx_f * 16.56, float(tier) + 3.4, wz),
					Vector3(sx_f, 0, 0), 1.9, 4.4, true, 0.18)
	lm.gable("Roof", Vector3(0.0, 23.4, 0.0), 33.6, 42.4, 2.6, Basis(), 0.3, "Stone")
	lm.box("Lamp", Vector3(0.0, 10.6, 20.9), Vector3(14.0, 2.6, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 33.0, 42.0, 26.0, 0.9)

static func gritti_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkVnKit.stucco("#C97C63", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian_trim("#F4EFE3", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#985C46", 2.4))
	lm.use("Wood", LandmarkVnKit.dark_wood("#6C4C34", 2.0))
	lm.use("Canvas", LandmarkMaterials.pbr("render", "#F4EFE2", 1.8))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 2.0))

	LandmarkVnKit.palazzo_block(lm, "Wall", "Stone", "Roof", "Glass", "Algae",
		Vector3.ZERO, 34.0, 20.0, 18.5, 5, 3, 2.3)
	# Floating Grand Canal timber dining terrace (+Z) with cream umbrellas & warm table lanterns
	lm.box("Wood", Vector3(0.0, 0.55, 12.6), Vector3(24.0, 0.65, 5.2))
	LandmarkDetail.balustrade(lm, "Wood", Vector3(-11.8, 0.88, 15.1), Vector3(11.8, 0.88, 15.1), 0.9, 3.0)
	for ux in [-8.0, -2.8, 2.8, 8.0]:
		lm.frustum("Wood", Vector3(float(ux), 0.88, 12.6), 0.08, 0.07, 2.5, 6)
		lm.frustum("Canvas", Vector3(float(ux), 3.1, 12.6), 1.85, 0.15, 0.65, 8)
		lm.box("Lamp", Vector3(float(ux), 2.85, 12.6), Vector3(0.28, 0.28, 0.28))
	lm.box("Lamp", Vector3(0.0, 7.4, 9.95), Vector3(9.0, 2.2, 0.25))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 34.0, 20.0, 18.5, 0.85)

static func ferro_fini_bauer(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Ochre", LandmarkVnKit.stucco("#DEC196", 2.8))
	lm.use("Rose", LandmarkVnKit.stucco("#CE8E76", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian_trim("#F3EEE2", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B5F48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.8))

	# Palazzo Ferro Fini (west wing, ochre Renaissance, height 20.0 m)
	LandmarkVnKit.palazzo_block(lm, "Ochre", "Stone", "Roof", "Glass", "Algae",
		Vector3(-9.5, 0.0, 0.0), 22.0, 30.0, 20.0, 5, 4, 2.4)
	# Palazzo Contarini Fasan ("Desdemona's House", east wing, rose Gothic with lacy balconies, height 18.8 m)
	LandmarkVnKit.palazzo_block(lm, "Rose", "Stone", "Roof", "Glass", "Algae",
		Vector3(11.0, 0.0, 2.0), 17.0, 26.0, 18.8, 3, 4, 2.2)
	lm.box("Lamp", Vector3(-9.5, 7.6, 14.9), Vector3(7.6, 2.2, 0.25))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 40.0, 30.0, 20.0, 0.8)
