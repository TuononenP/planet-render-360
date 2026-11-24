class_name VnOuterCastelloLagoon
extends RefCounted

## Outer Castello, Cannaregio & Northern Lagoon landmarks (`VN-6.11`–`VN-6.14`):
## - Basilica dei Santi Giovanni e Paolo (Zanipolo) + Scuola Grande di San Marco + Colleoni equestrian monument
## - Arsenale di Venezia (1460 Porta Magna triumphal arch + Twin crenellated red-brick Water-Gate Towers)
## - San Pietro di Castello (Palladian cathedral + dome + Venice's leaning all-white Istrian campanile 48 m)
## - Madonna dell'Orto & Gesuiti (Gothic brick church + 56 m cupola campanile)
## - San Michele Cemetery Island (Codussi's white church + cypresses + brick perimeter walls)
## - Murano Lighthouse (Faro di Murano, 35 m fluted white Istrian-stone column)

static func zanipolo_san_marco(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B3533C", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian("#F1ECE1", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 1.8))
	lm.use("Marble", LandmarkVnKit.verona_rose("#D8B0A0", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4A4335", 1.8, 0.36, 0.78))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 2.0))

	# Massive Gothic red-brick Basilica dei Santi Giovanni e Paolo (-X wing, height 42.0 m to dome)
	lm.box("Brick", Vector3(-12.0, 12.6, 0.0), Vector3(24.0, 25.2, 84.0))
	lm.box("Brick", Vector3(-12.0, 7.6, 4.0), Vector3(38.0, 15.2, 70.0))
	lm.gable("Roof", Vector3(-12.0, 25.2, 0.0), 24.6, 84.6, 4.6, Basis(), 0.3, "Brick")
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-12.0, 4.4, 42.1), Vector3(0, 0, 1), 4.2, 7.8, true, 0.3)
	lm.disc("Trim", Vector3(-12.0, 19.6, 42.1), Vector3(0, 0, 1), 3.0, 14)
	lm.disc("Glass", Vector3(-12.0, 19.6, 42.16), Vector3(0, 0, 1), 2.3, 14)
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(-12.0, 25.2, -16.0), 7.6, 5.2, 7.2, 3.0, 1.4)

	# Scuola Grande di San Marco (Pietro Lombardo & Codussi's luminous trompe-l'oeil marble facade at +X)
	lm.box("Stone", Vector3(19.0, 9.2, 24.0), Vector3(26.0, 18.4, 34.0))
	for sx in [10.0, 16.0, 22.0, 28.0]:
		lm.disc("Stone", Vector3(float(sx), 18.4, 41.05), Vector3(0, 0, 1), 3.0, 12)
		lm.disc("Marble", Vector3(float(sx), 18.4, 41.12), Vector3(0, 0, 1), 2.2, 12)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 11.4, 41.08), Vector3(0, 0, 1), 2.0, 4.6, true, 0.2)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 3.6, 41.08), Vector3(0, 0, 1), 2.2, 5.0, true, 0.24)

	# Verrocchio's bronze Bartolomeo Colleoni equestrian statue on tall Corinthian marble pedestal in the campo (+Z)
	var cp := Vector3(12.0, 0.0, 50.0)
	lm.box("Trim", cp + Vector3(0, 0.7, 0), Vector3(5.2, 1.4, 5.2))
	lm.box("Stone", cp + Vector3(0, 4.4, 0), Vector3(3.2, 6.2, 4.0))
	lm.box("Trim", cp + Vector3(0, 7.8, 0), Vector3(3.8, 0.65, 4.6))
	lm.box("Bronze", cp + Vector3(0, 9.6, 0), Vector3(1.1, 1.4, 2.8))
	LandmarkKits.statue_figure(lm, "Bronze", cp + Vector3(0, 10.2, 0.1), 2.4, true)
	lm.box("Lamp", Vector3(19.0, 6.2, 41.3), Vector3(4.0, 0.45, 0.35))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 60.0, 88.0, 42.0, 0.9)

static func arsenale_venezia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#A64935", 2.6))
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 1.8))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242B30"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.9))

	# Twin monumental crenellated red-brick Water-Gate Towers flanking the Rio dell'Arsenale canal mouth (height 26.0 m)
	for sx: float in [-1.0, 1.0]:
		var tx := sx * 12.0
		lm.box("Algae", Vector3(tx, 0.25, 0.0), Vector3(9.4, 0.65, 9.4))
		lm.box("Brick", Vector3(tx, 12.2, 0.0), Vector3(9.0, 23.6, 9.0))
		# White Istrian stone string courses & corner quoins
		for sy in [6.0, 13.0, 19.5, 23.8]:
			lm.box("Trim", Vector3(tx, float(sy), 0.0), Vector3(9.4, 0.45, 9.4))
		# Crenellated brick battlements rising to 26.0 m
		for i in 4:
			var o := -3.3 + 2.2 * float(i)
			lm.box("Brick", Vector3(tx + o, 25.0, 4.3), Vector3(1.1, 2.0, 0.6))
			lm.box("Brick", Vector3(tx + o, 25.0, -4.3), Vector3(1.1, 2.0, 0.6))
			lm.box("Brick", Vector3(tx + 4.3, 25.0, o), Vector3(0.6, 2.0, 1.1))
			lm.box("Brick", Vector3(tx - 4.3, 25.0, o), Vector3(0.6, 2.0, 1.1))
		# Flanking crenellated Arsenal brick curtain walls
		lm.box("Brick", Vector3(tx + sx * 11.5, 5.2, -2.0), Vector3(14.0, 10.4, 2.4))
		lm.box("Trim", Vector3(tx + sx * 11.5, 10.5, -2.0), Vector3(14.2, 0.4, 2.6))

	# 1460 Porta Magna classical Istrian triumphal land gate (-X beside west tower) with marble Greek Lions
	var pm := Vector3(-22.0, 0.0, 8.0)
	lm.box("Stone", pm + Vector3(-4.2, 6.2, 0), Vector3(3.2, 12.4, 4.0))
	lm.box("Stone", pm + Vector3(4.2, 6.2, 0), Vector3(3.2, 12.4, 4.0))
	lm.box("Stone", pm + Vector3(0.0, 11.4, 0), Vector3(12.4, 3.8, 4.0))
	for sx in [-4.8, -3.2, 3.2, 4.8]:
		LandmarkDetail.column(lm, "Trim", pm + Vector3(float(sx), 0.6, 2.3), 0.34, 9.4, "corinthian", 8)
	lm.gable("Trim", pm + Vector3(0.0, 13.3, 0.2), 12.6, 4.2, 2.8, Basis(), 0.25, "Stone")
	LandmarkKits.statue_figure(lm, "Trim", pm + Vector3(0.0, 16.1, 0.2), 2.2, true)
	# Marble Piraeus Lions flanking the entrance terrace
	for sx in [-6.8, 6.8]:
		lm.box("Trim", pm + Vector3(float(sx), 1.1, 4.5), Vector3(1.6, 1.8, 2.6))
		lm.box("Stone", pm + Vector3(float(sx), 2.6, 4.5), Vector3(1.1, 1.3, 2.1))
	lm.box("Lamp", pm + Vector3(0.0, 8.8, 2.2), Vector3(1.4, 0.45, 0.35))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 56.0, 32.0, 26.0, 0.9)

static func san_pietro_castello(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1EDE2", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B3573E", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.9))

	# Venice's former Cathedral: white Palladian facade + dome + leaning all-white Istrian campanile (48.0 m)
	lm.box("Brick", Vector3(-4.0, 9.4, -2.0), Vector3(28.0, 18.8, 52.0))
	lm.gable("Roof", Vector3(-4.0, 18.8, -2.0), 28.6, 52.6, 3.8, Basis(), 0.25, "Brick")
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(-4.0, 0.0, 24.4), Vector3.RIGHT, Vector3(0, 0, 1),
		28.4, 17.5, 18.2, 11.4, 4.4, 4)
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(-4.0, 18.8, -10.0), 6.8, 5.2, 7.6, 3.4, 1.8)
	# Venice's unique all-white Istrian-stone leaning campanile (48.0 m, visible ~1.4 m tilt!)
	LandmarkVnKit.campanile(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(17.5, 0.0, 12.0), 7.6, 48.0, 1.4, true)
	lm.box("Lamp", Vector3(18.8, 33.4, 12.0), Vector3(4.6, 5.0, 4.6))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 44.0, 56.0, 48.0, 0.85)

static func chiesa_gesuiti_orto(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B2543C", 2.8))
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 1.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.9))

	# Madonna dell'Orto: Gothic red-brick tripartite facade with white marble statues & 56.0 m onion-cupola campanile
	lm.box("Brick", Vector3(-4.0, 10.6, 0.0), Vector3(28.0, 21.2, 48.0))
	lm.gable("Roof", Vector3(-4.0, 21.2, 0.0), 28.6, 48.6, 4.2, Basis(), 0.3, "Brick")
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(-4.0, 3.8, 24.1), Vector3(0, 0, 1), 3.6, 6.8, true, 0.28)
	lm.disc("Trim", Vector3(-4.0, 16.5, 24.1), Vector3(0, 0, 1), 2.8, 14)
	lm.disc("Glass", Vector3(-4.0, 16.5, 24.16), Vector3(0, 0, 1), 2.1, 14)
	# Signature 56.0 m brick campanile crowned with white bulbous cupola
	LandmarkVnKit.campanile(lm, "Brick", "Trim", "Lead", "Glass", "Gold",
		Vector3(15.0, 0.0, -8.0), 7.4, 56.0, 0.0, true)
	lm.box("Lamp", Vector3(15.0, 38.6, -8.0), Vector3(4.6, 5.2, 4.6))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 38.0, 50.0, 56.0, 0.85)

static func san_michele_island(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1ECE1", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#AD523B", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.4))
	lm.use("Cypress", LandmarkMaterials.pbr("grass", "#294426", 1.8))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.7))

	# Mauro Codussi's 1469 white Istrian church of San Michele in Isola + brick cemetery perimeter wall + cypresses
	lm.box("Stone", Vector3(0.0, 7.6, 0.0), Vector3(18.0, 15.2, 26.0))
	lm.disc("Stone", Vector3(0.0, 15.2, 13.0), Vector3(0, 0, 1), 6.8, 18)
	lm.gable("Roof", Vector3(0.0, 15.2, 0.0), 18.4, 26.4, 3.2, Basis(), 0.25, "Stone")
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(0.0, 3.2, 13.1), Vector3(0, 0, 1), 2.6, 5.0, true, 0.22)
	# Brick walled perimeter wings & dark Italian cypress spire grove
	for sx in [-1.0, 1.0]:
		lm.box("Brick", Vector3(sx * 24.0, 3.2, 8.0), Vector3(30.0, 6.4, 2.2))
		for k in 5:
			lm.frustum("Cypress", Vector3(sx * (14.0 + 4.5 * float(k)), 0.0, -4.0 - 2.0 * float(k % 2)),
				1.35, 0.18, 13.5, 8)
	lm.box("Lamp", Vector3(0.0, 6.0, 13.25), Vector3(1.0, 0.4, 0.3))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 24.0, 28.0, 22.0, 0.75)

static func murano_faro(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1EDE2", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#FAF7EF", 1.8))
	lm.use("Lead", LandmarkVnKit.lead_dome("#5A6268", 2.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF8E0", 3.0))

	# 1934 35.0 m fluted white Istrian-stone cylindrical lagoon lighthouse on Murano
	lm.box("Stone", Vector3(0.0, 1.6, 0.0), Vector3(8.4, 3.2, 8.4))
	lm.frustum("Stone", Vector3(0.0, 3.2, 0.0), 2.9, 2.25, 25.4, 16)
	lm.frustum("Trim", Vector3(0.0, 28.6, 0.0), 2.75, 2.95, 1.2, 16)
	lm.frustum("Lamp", Vector3(0.0, 29.8, 0.0), 1.65, 1.65, 3.0, 12)
	lm.lathe("Lead", Vector3(0.0, 32.8, 0.0), LandmarkVnKit.dome_profile(1.8, 1.5), 12)
	lm.frustum("Trim", Vector3(0.0, 34.3, 0.0), 0.14, 0.04, 0.7, 6)
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(0.0, 31.3, 0.0), 2.2, Color(1.0, 0.96, 0.82)]])
	LandmarkVnKit.set_warm_floods(model, 9.0, 9.0, 35.0, 0.9, true)
