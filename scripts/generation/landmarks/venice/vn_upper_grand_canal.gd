class_name VnUpperGrandCanal
extends RefCounted

## Upper Grand Canal masterpieces & Ferrovia railhead (`VN-5.7`–`VN-5.10`):
## - Ca' d'Oro (supreme Flamboyant Gothic marble lacework + pink Verona marble + scalloped cresting)
## - Ca' Pesaro (Longhena's diamond-rusticated Baroque palazzo)
## - Fontego dei Turchi (Veneto-Byzantine 10/18-arch marble arcade & twin crenellated towers)
## - Ca' Vendramin Calergi / Casinò (Codussi's luminous Renaissance Istrian facade)
## - San Simeone Piccolo (tall patinated green-copper elongated dome + Corinthian portico)
## - Stazione Venezia Santa Lucia (travertine modernist rail terminus & arrival canopy)

static func ca_doro(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkVnKit.istrian_trim("#F7F3EA", 1.8))
	lm.use("Rose", LandmarkVnKit.verona_rose("#DFB3A3", 2.0))
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D8", 2.4))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242C32"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.9))

	# Asymmetric Flamboyant Gothic jewel (28 x 24 m, height 20.5 m to scalloped marble cresting)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(28.4, 0.6, 24.4))
	# Recessed dark portico core behind left (-X) lacy marble loggias + full right (+X) pink Verona wing
	lm.box("Stone", Vector3(-4.0, 9.0, -1.6), Vector3(17.6, 17.6, 20.8))
	lm.box("Rose", Vector3(9.4, 9.0, 0.0), Vector3(9.2, 17.6, 24.0))
	for sy in [5.4, 11.4, 17.4]:
		lm.box("Marble", Vector3(0.0, float(sy), 0.0), Vector3(28.6, 0.42, 24.6))
	# Left wing (-X): 5-arch ground water portico + two supreme lacy Flamboyant Gothic marble loggias
	for i in 5:
		var x := -11.4 + 3.6 * float(i)
		LandmarkDetail.window(lm, "Marble", "Glass", Vector3(x, 2.7, 12.02), Vector3(0, 0, 1), 2.5, 4.6, true, 0.26)
	LandmarkVnKit.polifora(lm, "Marble", "Glass", Vector3(-4.2, 5.8, 12.04), Vector3.RIGHT, Vector3(0, 0, 1), 6, 2.65, 5.0, true)
	LandmarkVnKit.polifora(lm, "Marble", "Glass", Vector3(-4.2, 11.8, 12.04), Vector3.RIGHT, Vector3(0, 0, 1), 6, 2.65, 5.0, true)
	# Right wing (+X): pink Verona marble with stacked paired Gothic windows & gilt roundel accents
	for sy in [8.2, 14.2]:
		for sx in [7.2, 11.6]:
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(float(sx), float(sy), 12.06), Vector3(0, 0, 1), 1.8, 4.0, true, 0.18)
		lm.disc("Gold", Vector3(9.4, float(sy) + 1.8, 12.10), Vector3(0, 0, 1), 0.45, 10)
	# Iconic Venetian scalloped/lacy marble cresting crowning the facade (up to 20.5 m)
	for i in 14:
		var x := -13.0 + 2.0 * float(i)
		lm.box("Marble", Vector3(x, 18.2, 12.0), Vector3(0.95, 1.0, 0.35))
		lm.spire("Marble", Vector3(x, 18.7, 12.0), 0.45, 1.8, 0.0, 4)
	lm.gable("Roof", Vector3(0.0, 17.8, -1.0), 22.0, 28.0, 2.2, Basis(Vector3.UP, PI * 0.5), 0.25, "Stone")
	lm.box("Lamp", Vector3(-4.2, 8.6, 11.2), Vector3(12.0, 2.2, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 28.0, 24.0, 20.5, 0.95)

static func ca_pesaro(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E8", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242B30"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE1A0", 1.9))

	# Longhena's bold Baroque Istrian palace (34 x 42 m, height 26.0 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(34.4, 0.6, 42.4))
	lm.box("Stone", Vector3(0.0, 11.8, 0.0), Vector3(34.0, 22.8, 42.0))
	for sy in [7.4, 15.2, 23.0]:
		lm.box("Trim", Vector3(0.0, float(sy), 0.0), Vector3(34.8, 0.72, 42.8))
	# Diamond-rusticated twin central water portals + paired Baroque columns & balconies (+Z)
	for sx in [-2.6, 2.6]:
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 3.4, 21.10), Vector3(0, 0, 1), 3.0, 5.8, true, 0.30)
	for sy in [7.8, 15.6]:
		for i in 7:
			var x := -13.2 + 4.4 * float(i)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, float(sy) + 3.4, 21.08), Vector3(0, 0, 1), 2.1, 4.8, true, 0.24)
			LandmarkDetail.balustrade(lm, "Trim", Vector3(x - 1.3, float(sy) + 0.15, 21.65),
				Vector3(x + 1.3, float(sy) + 0.15, 21.65), 0.9, 1.3)
		for i in 8:
			var cx := -15.4 + 4.4 * float(i)
			for dx in [-0.34, 0.34]:
				LandmarkDetail.column(lm, "Trim", Vector3(cx + float(dx), float(sy), 21.30), 0.25, 6.6, "corinthian", 8)
	lm.gable("Roof", Vector3(0.0, 23.4, 0.0), 34.4, 42.4, 2.6, Basis(), 0.3, "Stone")
	lm.box("Lamp", Vector3(0.0, 11.0, 20.9), Vector3(14.0, 2.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 34.0, 42.0, 26.0, 0.9)

static func fontego_dei_turchi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#E6E0D2", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F3EEE2", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B5F48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.8))

	# Veneto-Byzantine 10-arch ground arcade + 18-arch upper loggia flanked by twin crenellated towers (16.5 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(44.4, 0.6, 36.4))
	lm.box("Stone", Vector3(0.0, 6.2, -1.0), Vector3(44.0, 11.4, 34.0))
	lm.box("Trim", Vector3(0.0, 6.0, 17.0), Vector3(44.4, 0.45, 2.6))
	lm.box("Trim", Vector3(0.0, 12.0, 17.0), Vector3(44.4, 0.55, 2.6))
	# Ground 10-arch portico + upper 18-arch Veneto-Byzantine loggia along Grand Canal (+Z)
	for i in 10:
		var x := -13.5 + 3.0 * float(i)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 2.8, 17.1), Vector3(0, 0, 1), 2.2, 4.8, true, 0.22)
	LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(0.0, 6.3, 17.1), Vector3.RIGHT, Vector3(0, 0, 1), 14, 2.1, 4.8, false)
	# Twin crenellated square corner towers rising to 16.5 m
	for sx: float in [-1.0, 1.0]:
		var tx := sx * 18.5
		lm.box("Stone", Vector3(tx, 7.6, 13.0), Vector3(7.4, 14.8, 10.0))
		lm.box("Trim", Vector3(tx, 15.2, 13.0), Vector3(7.8, 0.45, 10.4))
		for m in 4:
			var mx := tx - 2.7 + 1.8 * float(m)
			lm.box("Trim", Vector3(mx, 15.9, 17.9), Vector3(0.95, 1.1, 0.45))
			lm.box("Trim", Vector3(mx, 15.9, 8.1), Vector3(0.95, 1.1, 0.45))
	lm.gable("Roof", Vector3(0.0, 12.2, -1.0), 34.0, 44.0, 2.4, Basis(Vector3.UP, PI * 0.5), 0.25, "Stone")
	lm.box("Lamp", Vector3(0.0, 8.5, 16.6), Vector3(16.0, 1.8, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 44.0, 36.0, 16.5, 0.85)

static func vendramin_calergi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F2EDE2", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#FAF7EF", 1.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9D614B", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE3A4", 1.9))

	# Mauro Codussi's luminous white Istrian-stone Renaissance facade (38 x 34 m, height 22.0 m)
	LandmarkVnKit.palazzo_block(lm, "Stone", "Trim", "Roof", "Glass", "Algae",
		Vector3.ZERO, 38.0, 34.0, 22.0, 6, 3, 2.6)
	# Coupled classical columns dividing the bays
	for sy in [6.8, 13.2]:
		for sx in [-15.0, -7.8, 7.8, 15.0]:
			LandmarkDetail.column(lm, "Trim", Vector3(float(sx), float(sy), 17.25), 0.28, 5.6, "corinthian", 8)
	lm.box("Lamp", Vector3(0.0, 9.2, 16.95), Vector3(12.0, 2.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 38.0, 34.0, 22.0, 0.9)

static func san_simeone_piccolo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F4EB", 2.0))
	lm.use("Copper", LandmarkVnKit.copper_patina("#568D7A", 2.2))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242B30"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 2.0))

	# Neoclassical Pantheon-inspired rotunda + broad Grand Canal steps + Corinthian portico (+Z)
	lm.box("Algae", Vector3(0.0, 0.22, 2.0), Vector3(24.0, 0.6, 30.0))
	lm.frustum("Stone", Vector3(0.0, 0.5, -2.0), 11.4, 11.4, 15.0, 28)
	lm.frustum("Trim", Vector3(0.0, 15.2, -2.0), 11.9, 12.1, 0.8, 28)
	# Broad canal steps & projecting 4-column Corinthian pronaos with sculptural pediment (+Z)
	for k in 5:
		lm.box("Stone", Vector3(0.0, 0.4 + 0.3 * float(k), 14.5 - 0.8 * float(k)), Vector3(16.0, 0.36, 1.0))
	lm.box("Stone", Vector3(0.0, 7.6, 9.6), Vector3(15.0, 14.2, 5.2))
	for x in [-6.0, -2.0, 2.0, 6.0]:
		LandmarkDetail.column(lm, "Trim", Vector3(float(x), 1.8, 12.6), 0.52, 11.8, "corinthian", 10)
	lm.box("Trim", Vector3(0.0, 14.3, 10.6), Vector3(16.0, 1.4, 5.6))
	lm.gable("Trim", Vector3(0.0, 15.0, 10.6), 16.2, 5.6, 3.8, Basis(), 0.25, "Stone")
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(0.0, 5.6, 12.24), Vector3(0, 0, 1), 3.4, 6.4, true, 0.25)

	# Unmistakable tall elongated patinated green-copper dome + open lantern + cross (top = 44.0 m)
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Copper", "Glass", "Gold",
		Vector3(0.0, 16.0, -2.0), 10.2, 6.5, 14.2, 5.0, 2.3)
	lm.frustum("Lamp", Vector3(0.0, 36.8, -2.0), 1.8, 1.8, 2.6, 8)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.8, 20.0), Vector3(0.0, 14.0, 11.0), 48.0, 0.95],
		[Vector3(-14.0, 16.0, 6.0), Vector3(-2.0, 30.0, -2.0), 46.0, 0.9],
		[Vector3(14.0, 16.0, 6.0), Vector3(2.0, 30.0, -2.0), 46.0, 0.9],
	])

static func stazione_santa_lucia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkVnKit.istrian("#ECE8DE", 3.0))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F4EC", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#5A7886"))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8B8D8C", 2.8))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#564936", 2.0, 0.42, 0.72))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFF2D6", 2.2))

	# Clean modernist travertine-marble terminus facade (92 x 38 m, height 18.5 m) facing Grand Canal (+Z)
	lm.box("Marble", Vector3(0.0, 7.8, -4.0), Vector3(90.0, 15.6, 32.0))
	lm.box("Trim", Vector3(0.0, 15.8, -4.0), Vector3(91.0, 0.65, 32.8))
	# Broad arrival steps down to Fondamenta Santa Lucia (+Z)
	for k in 5:
		lm.box("Trim", Vector3(0.0, 0.3 + 0.24 * float(k), 17.5 - 0.9 * float(k)), Vector3(84.0, 0.3, 1.0))
	# Signature cantilevered thin concrete/marble concourse canopy + tall vertical glazed bays
	lm.box("Trim", Vector3(0.0, 7.6, 14.8), Vector3(84.0, 0.85, 6.8))
	lm.box("Lamp", Vector3(0.0, 7.1, 14.6), Vector3(80.0, 0.25, 0.8))
	lm.box("Glass", Vector3(0.0, 4.0, 12.06), Vector3(76.0, 6.4, 0.25))
	for i in 15:
		var x := -38.5 + 5.5 * float(i)
		lm.box("Trim", Vector3(x, 7.8, 12.22), Vector3(0.55, 14.8, 0.45))
	# Upper horizontal clerestory window ribbon & bronze Winged Lion reliefs on end wings
	lm.box("Glass", Vector3(0.0, 12.0, 12.08), Vector3(72.0, 3.6, 0.22))
	for sx in [-40.0, 40.0]:
		lm.box("Bronze", Vector3(float(sx), 11.6, 12.18), Vector3(4.2, 2.2, 0.22))
	# Low barrel-arched train-shed roof crest rising behind facade to 18.5 m
	lm.gable("Roof", Vector3(0.0, 16.0, -8.0), 24.0, 86.0, 2.5, Basis(Vector3.UP, PI * 0.5), 0.25, "Marble")
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 88.0, 34.0, 18.5, 0.85)
