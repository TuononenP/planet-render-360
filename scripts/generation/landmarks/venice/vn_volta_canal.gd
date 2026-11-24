class_name VnVoltaCanal
extends RefCounted

## Iconic Volta de Canal Grand Canal palaces (`VN-5.1`–`VN-5.3`):
## - Ca' Rezzonico (Longhena's grand Baroque white Istrian palazzo)
## - Palazzo Grassi (Massari's crisp Neoclassical white Istrian palazzo)
## - Ca' Foscari (1452 Venetian Gothic brick-and-marble focal point of the Grand Canal bend)

static func ca_rezzonico(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#EEEAE0", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE1A2", 1.9))

	# Longhena's grand Baroque Istrian palazzo (30 x 42 m, height 25.0 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(30.4, 0.6, 42.4))
	lm.box("Stone", Vector3(0.0, 11.4, 0.0), Vector3(30.0, 22.0, 42.0))
	for sy in [6.8, 14.2, 21.8]:
		lm.box("Trim", Vector3(0.0, float(sy), 0.0), Vector3(30.8, 0.65, 42.8))
	# Rusticated ground water-gate arcade (+Z)
	for sx in [-4.0, 0.0, 4.0]:
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 3.1, 21.08), Vector3(0, 0, 1), 2.8, 5.4, true, 0.28)
	# Two bold Baroque columned piano-nobile tiers with projecting balconies & arched bays
	for sy in [7.2, 14.6]:
		for i in 7:
			var x := -12.0 + 4.0 * float(i)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, float(sy) + 3.2, 21.06), Vector3(0, 0, 1), 2.0, 4.8, true, 0.22)
		for i in 8:
			var cx := -14.0 + 4.0 * float(i)
			LandmarkDetail.column(lm, "Trim", Vector3(cx, float(sy), 21.25), 0.30, 6.4, "corinthian", 8)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(-13.8, float(sy) + 0.1, 21.65),
			Vector3(13.8, float(sy) + 0.1, 21.65), 0.95, 3.0)
	lm.gable("Roof", Vector3(0.0, 22.4, 0.0), 30.6, 42.4, 2.6, Basis(), 0.3, "Stone")
	lm.box("Lamp", Vector3(0.0, 10.4, 20.9), Vector3(12.0, 2.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 30.0, 42.0, 25.0, 0.9)

static func palazzo_grassi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1EDE2", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B5F49", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE3A6", 1.85))

	LandmarkVnKit.palazzo_block(lm, "Stone", "Trim", "Roof", "Glass", "Algae",
		Vector3.ZERO, 32.0, 44.0, 23.0, 3, 3, 2.6)
	# Massari's grand triple-arch Neoclassical water portico & pedimented piano-nobile windows
	for x in [-4.0, 0.0, 4.0]:
		LandmarkDetail.column(lm, "Trim", Vector3(float(x) - 1.6, 0.4, 22.35), 0.34, 5.2, "doric", 8)
	lm.box("Lamp", Vector3(0.0, 8.8, 21.95), Vector3(10.0, 2.2, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 32.0, 44.0, 23.0, 0.85)

static func ca_foscari(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B85942", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian("#EEE9DC", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E9", 1.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#985D47", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242B30"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.9))

	# Majestic 4-storey Venetian Gothic Volta de Canal palazzo (30 x 26 m, height 24.0 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(30.4, 0.6, 26.4))
	lm.box("Stone", Vector3(0.0, 2.6, 0.0), Vector3(30.2, 4.4, 26.2))
	lm.box("Brick", Vector3(0.0, 13.0, 0.0), Vector3(30.0, 16.6, 26.0))
	for sy in [4.8, 10.2, 15.8, 21.2]:
		lm.box("Trim", Vector3(0.0, float(sy), 0.0), Vector3(30.6, 0.42, 26.6))
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(0.0, 2.4, 13.12), Vector3(0, 0, 1), 3.4, 4.2, true, 0.24)
	# Famous 8-bay central Venetian Gothic marble polifore with pierced quatrefoils on levels 2 & 3
	LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(0.0, 5.4, 13.02), Vector3.RIGHT, Vector3(0, 0, 1), 8, 1.65, 4.2, true)
	LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(0.0, 10.8, 13.02), Vector3.RIGHT, Vector3(0, 0, 1), 8, 1.65, 4.4, true)
	LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(0.0, 16.4, 13.02), Vector3.RIGHT, Vector3(0, 0, 1), 4, 1.85, 3.8, false)
	# Flanking pointed Gothic windows
	for sy in [7.4, 12.8, 18.2]:
		for sx in [-11.5, 11.5]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), float(sy), 13.05), Vector3(0, 0, 1), 1.6, 3.6, true, 0.18)
	lm.gable("Roof", Vector3(0.0, 21.4, 0.0), 26.4, 30.4, 2.6, Basis(Vector3.UP, PI * 0.5), 0.3, "Brick")
	LandmarkVnKit.bell_chimney(lm, "Brick", Vector3(-9.0, 22.0, -4.0), 2.1)
	LandmarkVnKit.bell_chimney(lm, "Brick", Vector3(9.0, 22.0, -4.0), 2.1)
	lm.box("Lamp", Vector3(0.0, 12.6, 12.95), Vector3(11.6, 2.6, 0.25))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 30.0, 26.0, 24.0, 0.9)
