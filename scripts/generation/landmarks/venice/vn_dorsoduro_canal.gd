class_name VnDorsoduroCanal
extends RefCounted

## Dorsoduro south-bank Grand Canal corridor (`VN-3.7`, `VN-3.9`, `VN-3.10`, `VN-3.14`):
## - Palazzo Barbarigo (gleaming 1886 Murano gold-and-polychrome glass mosaic facade)
## - Palazzo Venier dei Leoni / Peggy Guggenheim Collection (unfinished single-storey white stone)
## - Ca' Dario (subtly leaning polychrome marble-roundel Renaissance jewel)
## - Abbazia di San Gregorio (Gothic brick abbey & cloister immediately west of Salute)

static func palazzo_barbarigo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkVnKit.stucco("#E2C6A0", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian_trim("#F3EEE2", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Cobalt", LandmarkMaterials.pbr("stone", "#284B84", 1.8, 0.35, 0.20))
	lm.use("Crimson", LandmarkMaterials.pbr("stone", "#8E2E2C", 1.8, 0.40, 0.12))
	lm.use("Roof", LandmarkVnKit.terracotta("#9E624B", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09A", 1.9))

	LandmarkVnKit.palazzo_block(lm, "Wall", "Stone", "Roof", "Glass", "Algae",
		Vector3.ZERO, 20.0, 22.0, 18.0, 3, 4, 2.2)
	# Iconic Murano gold-and-polychrome mosaic fresco panels across upper facade (+Z)
	for sy in [5.4, 9.6, 13.6]:
		for sx in [-6.8, 6.8]:
			lm.box("Gold", Vector3(float(sx), float(sy), 11.08), Vector3(4.2, 2.6, 0.14))
			lm.box("Cobalt", Vector3(float(sx), float(sy) + 0.4, 11.16), Vector3(3.2, 1.0, 0.08))
			lm.box("Crimson", Vector3(float(sx), float(sy) - 0.5, 11.16), Vector3(2.8, 0.8, 0.08))
	lm.box("Gold", Vector3(0.0, 15.2, 11.08), Vector3(18.0, 1.0, 0.16))
	lm.box("Lamp", Vector3(0.0, 6.2, 11.1), Vector3(6.2, 2.0, 0.25))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 20.0, 22.0, 18.0, 0.85)

static func venier_guggenheim(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 1.8))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242B30"))
	lm.use("Garden", LandmarkMaterials.pbr("grass", "#3E5D36", 2.2))
	lm.use("Cypress", LandmarkMaterials.pbr("grass", "#2B4628", 1.8))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE3A8", 1.8))

	# Unfinished single-storey rusticated Istrian palazzo (36 x 16 m, height 9.5 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(36.4, 0.6, 16.4))
	lm.box("Stone", Vector3(0.0, 4.1, 0.0), Vector3(36.0, 7.2, 15.6))
	lm.box("Trim", Vector3(0.0, 7.9, 0.0), Vector3(36.8, 0.55, 16.4))
	# Deeply rusticated canal arches & projecting Grand Canal white marble terrace (+Z)
	lm.box("Stone", Vector3(0.0, 1.3, 9.6), Vector3(16.0, 2.6, 4.0))
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-7.8, 2.6, 11.5), Vector3(7.8, 2.6, 11.5), 1.0, 2.2)
	for i in 7:
		var x := -14.4 + 4.8 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 4.2, 7.86), Vector3(0, 0, 1), 2.1, 4.2, true, 0.24)
		# Rusticated ashlar piers between arches
		if i < 6:
			lm.box("Trim", Vector3(x + 2.4, 4.1, 7.92), Vector3(1.2, 6.8, 0.36))
	# Rooftop sculpture-terrace parapet & garden cypresses rising behind the unfinished white wall
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-17.8, 8.2, 7.9), Vector3(17.8, 8.2, 7.9), 1.1, 3.2)
	lm.box("Garden", Vector3(0.0, 8.25, -2.5), Vector3(32.0, 0.3, 9.0))
	for sx in [-12.0, -5.0, 4.0, 11.0]:
		lm.frustum("Cypress", Vector3(float(sx), 3.0, -5.2), 1.25, 0.18, 6.5, 8)
	lm.box("Lamp", Vector3(0.0, 3.2, 8.0), Vector3(1.8, 0.45, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 36.0, 16.0, 9.5, 0.85)

static func ca_dario(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkVnKit.istrian("#ECE4D5", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E9", 1.8))
	lm.use("Porphyry", LandmarkMaterials.pbr("stone", "#863434", 1.4))
	lm.use("Verde", LandmarkMaterials.pbr("stone", "#3B604C", 1.4))
	lm.use("Roof", LandmarkVnKit.terracotta("#A0644C", 2.2))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFDF9C", 1.8))

	# Subtle real-life tilt (~1.6 degrees) of Ca' Dario's slender 10.6 x 22 m Renaissance facade
	var tilt := Basis(Vector3.BACK, deg_to_rad(1.6))
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(11.0, 0.6, 22.4))
	lm.box("Wall", Vector3(0.22, 8.1, 0.0), Vector3(10.6, 15.2, 22.0), tilt)
	for sy in [3.8, 7.6, 11.4, 15.2]:
		lm.box("Trim", Vector3(0.22 * (float(sy) / 8.0), float(sy), 0.0), Vector3(11.0, 0.34, 22.5), tilt)
	# Asymmetric stacked 4-bay round-arched loggias on the left (-X) + marble medallions on the right (+X)
	for sy in [4.3, 8.1, 11.9]:
		LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(-1.4, float(sy), 11.0), Vector3.RIGHT, Vector3(0, 0, 1),
			4, 1.45, 2.9, sy < 11.0)
		# Polychrome marble roundels on the right wall
		for rx in [3.2, 4.4]:
			var mat := "Porphyry" if int(sy) % 2 == 0 else "Verde"
			lm.disc("Trim", Vector3(float(rx), float(sy) + 1.5, 11.1), Vector3(0, 0, 1), 0.68, 12)
			lm.disc(mat, Vector3(float(rx), float(sy) + 1.5, 11.15), Vector3(0, 0, 1), 0.50, 12)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-1.4, 1.9, 11.06), Vector3(0, 0, 1), 2.4, 3.4, true, 0.22)
	lm.gable("Roof", Vector3(0.42, 15.7, 0.0), 11.0, 22.4, 2.1, Basis(), 0.25, "Wall")
	LandmarkVnKit.bell_chimney(lm, "Wall", Vector3(-3.0, 16.0, 6.0), 2.0)
	LandmarkVnKit.bell_chimney(lm, "Wall", Vector3(3.0, 16.0, -4.0), 2.0)
	lm.box("Lamp", Vector3(-1.4, 5.8, 10.9), Vector3(4.5, 1.8, 0.25))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 11.0, 22.0, 18.0, 0.85)

static func san_gregorio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B0533C", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#EFEBE0", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE0A0", 1.6))

	# Gothic red-brick abbey hall + polygonal apse + walled cloister immediately west of Salute
	lm.box("Algae", Vector3(0.0, 0.2, 0.0), Vector3(36.0, 0.55, 18.4))
	lm.box("Brick", Vector3(-5.0, 7.2, 0.0), Vector3(24.0, 14.0, 17.6))
	lm.gable("Roof", Vector3(-5.0, 14.2, 0.0), 18.0, 24.4, 3.3, Basis(Vector3.UP, PI * 0.5), 0.25, "Brick")
	# Gothic canal gate & stepped brick gable (+Z)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(11.0, 2.8, 8.9), Vector3(0, 0, 1), 2.6, 4.8, true, 0.25)
	lm.box("Brick", Vector3(12.0, 4.2, 0.0), Vector3(11.0, 8.0, 17.6))
	lm.box("Trim", Vector3(12.0, 8.4, 0.0), Vector3(11.4, 0.45, 18.0))
	for sx in [-12.0, -5.0, 2.0]:
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 8.2, 8.86), Vector3(0, 0, 1), 1.6, 5.4, true, 0.2)
	lm.box("Lamp", Vector3(11.0, 5.5, 9.0), Vector3(0.8, 0.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 36.0, 18.0, 17.5, 0.7)
