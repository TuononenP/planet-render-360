class_name VnAccademiaCorridor
extends RefCounted

## Immediate Ponte dell'Accademia foreground landmarks (`VN-3.3`–`VN-3.6`, `VN-3.13`):
## - Palazzo Cavalli-Franchetti (Neo-Gothic pink-ochre Grand Canal jewel)
## - Palazzo Barbaro (twin Gothic + Baroque palazzi right beside it)
## - Palazzo Contarini Polignac (early Renaissance marble-roundel palazzo)
## - Gallerie dell'Accademia (former Gothic brick Santa Maria della Carità)
## - Chiesa di San Vidal (Tirali's white Istrian Palladian facade)

static func cavalli_franchetti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkVnKit.stucco("#D99E85", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian_trim("#F3EEE2", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("PoleR", LandmarkMaterials.pbr("wood", "#8E2824", 1.5))
	lm.use("PoleW", LandmarkMaterials.pbr("wood", "#EFECE4", 1.5))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFDF9E", 1.8))

	# Main Venetian Gothic palazzo mass (30 x 34 m, height 21.0 m)
	LandmarkVnKit.palazzo_block(lm, "Wall", "Stone", "Roof", "Glass", "Algae",
		Vector3.ZERO, 30.0, 32.0, 21.0, 5, 4, 2.6)
	# Ornate Neo-Gothic trefoil parapet crest along Grand Canal front (+Z)
	for i in 12:
		var x := -13.5 + 2.45 * float(i)
		lm.spire("Stone", Vector3(x, 18.4, 16.05), 0.35, 1.1, 0.0, 4)
	# Garden terrace & balustrade to the west (-X) + striped red/white paline
	lm.box("Stone", Vector3(-19.5, 1.6, 6.0), Vector3(9.0, 3.2, 16.0))
	LandmarkDetail.balustrade(lm, "Stone", Vector3(-23.8, 3.2, 13.8), Vector3(-15.2, 3.2, 13.8), 1.0, 2.2)
	for x in [-10.0, -5.0, 5.0, 10.0]:
		LandmarkVnKit.palina(lm, "PoleR", "PoleW", Vector3(float(x), 0.0, 18.2), 3.4)
	# Warm piano-nobile chandelier glow
	lm.box("Lamp", Vector3(0.0, 7.2, 15.8), Vector3(9.2, 2.6, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 30.0, 32.0, 21.0, 0.8)

static func palazzo_barbaro(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("GothicWall", LandmarkVnKit.stucco("#DFAC88", 2.8))
	lm.use("BaroqueStone", LandmarkVnKit.istrian("#EEEAE0", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E8", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#262E34"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE0A0", 1.7))

	# Older 1425 Gothic wing (-X, warm salmon-ochre, height 19.0 m)
	LandmarkVnKit.palazzo_block(lm, "GothicWall", "Trim", "Roof", "Glass", "Algae",
		Vector3(-6.5, 0.0, 0.0), 14.0, 20.0, 19.0, 4, 4, 2.4)
	# 1694 Baroque wing (+X, white Istrian stone with pedimented central bay, height 18.2 m)
	LandmarkVnKit.palazzo_block(lm, "BaroqueStone", "Trim", "Roof", "Glass", "Algae",
		Vector3(7.0, 0.0, 0.0), 13.0, 20.0, 18.2, 3, 4, 2.2)
	lm.gable("Trim", Vector3(7.0, 15.6, 10.2), 7.4, 0.8, 1.8, Basis(), 0.2, "BaroqueStone")
	lm.box("Lamp", Vector3(-6.5, 6.8, 9.9), Vector3(5.8, 2.2, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 27.0, 20.0, 19.0, 0.75)

static func contarini_polignac(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkVnKit.istrian("#ECE5D6", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E8", 2.0))
	lm.use("Porphyry", LandmarkMaterials.pbr("stone", "#7E3234", 1.6))
	lm.use("Verde", LandmarkMaterials.pbr("stone", "#385B4A", 1.6))
	lm.use("Roof", LandmarkVnKit.terracotta("#9E624A", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFDF9C", 1.7))

	LandmarkVnKit.palazzo_block(lm, "Wall", "Trim", "Roof", "Glass", "Algae",
		Vector3.ZERO, 26.0, 30.0, 19.0, 5, 3, 2.5)
	# Signature Lombardo circular porphyry & verde antico marble medallions across the front (+Z)
	for sy in [6.8, 12.2]:
		for sx in [-9.8, -6.4, 6.4, 9.8]:
			var mat := "Porphyry" if int(absf(float(sx))) % 2 == 0 else "Verde"
			lm.disc("Trim", Vector3(float(sx), float(sy), 15.08), Vector3(0, 0, 1), 0.72, 12)
			lm.disc(mat, Vector3(float(sx), float(sy), 15.13), Vector3(0, 0, 1), 0.54, 12)
	lm.box("Lamp", Vector3(0.0, 7.6, 14.9), Vector3(8.0, 2.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 26.0, 30.0, 19.0, 0.75)

static func gallerie_accademia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B2543D", 2.6))
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F6F2E8", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#995D47", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#262D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE0A0", 1.8))

	# Former Gothic red-brick Chiesa di Santa Maria della Carità (-X wing, height 22.0 m)
	lm.box("Brick", Vector3(-6.0, 9.2, 0.0), Vector3(22.0, 18.4, 24.0))
	lm.gable("Roof", Vector3(-6.0, 18.4, 0.0), 22.4, 24.4, 3.6, Basis(), 0.25, "Brick")
	# Three Gothic Istrian-stone pinnacles & tall lancet windows on Campo della Carità front (+Z)
	for sx in [-10.8, 0.0, 10.8]:
		lm.spire("Trim", Vector3(-6.0 + float(sx), 18.4 if absf(float(sx)) > 1.0 else 20.6, 12.1), 0.55, 1.4, 0.0, 4)
	for sx in [-6.0, 0.0, 6.0]:
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-6.0 + float(sx), 10.0, 12.05), Vector3(0, 0, 1), 2.0, 7.2, true, 0.22)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-6.0, 3.0, 12.08), Vector3(0, 0, 1), 3.4, 5.4, true, 0.28)
	# Adjacent Scuola Grande & Palladian museum wing (+X, cream-white stone)
	lm.box("Stone", Vector3(13.0, 7.8, 0.0), Vector3(16.0, 15.6, 22.0))
	lm.gable("Roof", Vector3(13.0, 15.6, 0.0), 16.4, 22.4, 2.4, Basis(), 0.25, "Stone")
	for i in 3:
		var wx := 8.5 + 4.5 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(wx, 10.4, 11.05), Vector3(0, 0, 1), 1.6, 3.4, true, 0.16)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(wx, 4.4, 11.05), Vector3(0, 0, 1), 1.6, 3.2, true, 0.16)
	lm.box("Lamp", Vector3(-6.0, 5.8, 12.2), Vector3(1.6, 0.5, 0.4))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 38.0, 24.0, 22.0, 0.8)

static func san_vidal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F0ECE2", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B45C44", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE1A2", 1.7))

	lm.box("Brick", Vector3(0.0, 8.2, -2.0), Vector3(22.0, 16.4, 24.0))
	lm.gable("Roof", Vector3(0.0, 16.4, -2.0), 22.4, 24.4, 3.2, Basis(), 0.25, "Brick")
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(0.0, 0.0, 10.2), Vector3.RIGHT, Vector3(0, 0, 1),
		22.4, 13.6, 14.4, 9.6, 3.4, 4)
	lm.box("Lamp", Vector3(0.0, 6.2, 10.7), Vector3(1.2, 0.4, 0.35))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 22.0, 24.0, 20.0, 0.75)
