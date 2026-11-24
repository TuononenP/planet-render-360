class_name VnSanPoloDorsoduro
extends RefCounted

## San Polo & Dorsoduro icons (`VN-6.4`–`VN-6.7`):
## - Basilica dei Frari (huge Gothic red-brick church + Venice's 2nd-tallest 70 m campanile)
## - Scuola Grande di San Rocco (sumptuous Renaissance Istrian & polychrome marble facade)
## - Chiesa di Santo Stefano & its famously leaning 66 m red-brick campanile
## - Chiesa dei Gesuati (Zattere white Palladian facade + dome + twin small campanili)
## - Squero di San Trovaso (Venice's dark-timber Alpine gondola boatyard & slipway)

static func basilica_dei_frari(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B2533B", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F2EDE0", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#985C46", 2.6))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 2.0))

	# Monumental Gothic brick cruciform basilica (42 x 86 m) + tripartite curved-gable front (+Z)
	lm.box("Brick", Vector3(0.0, 12.6, 0.0), Vector3(22.0, 25.2, 82.0))
	lm.box("Brick", Vector3(0.0, 7.8, 4.0), Vector3(38.0, 15.6, 70.0))
	lm.gable("Roof", Vector3(0.0, 25.2, 0.0), 22.8, 82.6, 4.8, Basis(), 0.3, "Brick")
	# Transept & polygonal Gothic brick apse (-Z)
	lm.box("Brick", Vector3(0.0, 12.4, -22.0), Vector3(44.0, 24.8, 18.0))
	lm.gable("Roof", Vector3(0.0, 24.8, -22.0), 18.6, 44.6, 4.2, Basis(Vector3.UP, PI * 0.5), 0.3, "Brick")
	lm.frustum("Brick", Vector3(0.0, 0.0, -40.0), 9.5, 9.5, 23.0, 7)
	lm.frustum("Roof", Vector3(0.0, 23.0, -40.0), 9.9, 0.5, 3.8, 7)
	# Iconic Venetian Gothic tripartite curved-gable facade with three white Istrian aedicule pinnacles & rose oculi (+Z)
	lm.box("Trim", Vector3(0.0, 25.6, 41.15), Vector3(22.6, 0.65, 0.5))
	for sx in [-18.5, -10.8, 0.0, 10.8, 18.5]:
		var py := 29.8 if absf(float(sx)) < 1.0 else (25.4 if absf(float(sx)) < 12.0 else 16.0)
		lm.spire("Trim", Vector3(float(sx), py, 41.1), 0.72, 3.0, 0.0, 4)
	# Rose oculi & Gothic sculptural main portal
	lm.disc("Trim", Vector3(0.0, 20.6, 41.12), Vector3(0, 0, 1), 3.1, 16)
	lm.disc("Glass", Vector3(0.0, 20.6, 41.18), Vector3(0, 0, 1), 2.4, 16)
	for sx in [-14.0, 14.0]:
		lm.disc("Trim", Vector3(float(sx), 11.4, 39.12), Vector3(0, 0, 1), 2.0, 12)
		lm.disc("Glass", Vector3(float(sx), 11.4, 39.18), Vector3(0, 0, 1), 1.5, 12)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(0.0, 4.2, 41.12), Vector3(0, 0, 1), 4.2, 7.6, true, 0.30)

	# Venice's second-tallest campanile: 70.0 m red-brick shaft + Istrian belfry + octagonal drum & conical spire
	LandmarkVnKit.campanile(lm, "Brick", "Trim", "Roof", "Glass", "Gold",
		Vector3(21.5, 0.0, -8.0), 9.2, 70.0, 0.0, true)
	lm.box("Lamp", Vector3(21.5, 48.0, -8.0), Vector3(5.4, 6.0, 5.4))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.8, 52.0), Vector3(0.0, 16.0, 41.0), 54.0, 0.95],
		[Vector3(34.0, 1.8, -8.0), Vector3(21.5, 44.0, -8.0), 42.0, 1.0],
	])

static func scuola_grande_san_rocco(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.4))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 1.8))
	lm.use("Marble", LandmarkVnKit.verona_rose("#D9B2A2", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.85))

	# Sumptuous two-storey High Renaissance confraternity hall (42 x 30 m, height 22.0 m)
	lm.box("Stone", Vector3(0.0, 9.4, 0.0), Vector3(42.0, 18.8, 30.0))
	lm.box("Trim", Vector3(0.0, 9.2, 0.0), Vector3(43.0, 0.75, 31.0))
	lm.box("Trim", Vector3(0.0, 18.8, 0.0), Vector3(43.6, 0.95, 31.6))
	lm.gable("Roof", Vector3(0.0, 19.2, 0.0), 30.4, 42.4, 2.8, Basis(Vector3.UP, PI * 0.5), 0.25, "Stone")
	# Projecting fluted Corinthian columns on pedestals & paired bifore windows with polychrome marble inlays (+Z)
	for i in 5:
		var x := -16.0 + 8.0 * float(i)
		LandmarkDetail.column(lm, "Trim", Vector3(x, 0.6, 15.6), 0.44, 8.2, "corinthian", 10)
		LandmarkDetail.column(lm, "Trim", Vector3(x, 9.6, 15.6), 0.42, 8.6, "corinthian", 10)
		if i < 4:
			var xm := x + 4.0
			LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(xm, 2.2, 15.05), Vector3.RIGHT, Vector3(0, 0, 1), 2, 1.9, 5.2, false)
			LandmarkVnKit.polifora(lm, "Trim", "Glass", Vector3(xm, 11.2, 15.05), Vector3.RIGHT, Vector3(0, 0, 1), 2, 1.9, 5.4, false)
			lm.disc("Marble", Vector3(xm, 17.4, 15.10), Vector3(0, 0, 1), 0.85, 12)
	lm.box("Lamp", Vector3(0.0, 6.4, 15.3), Vector3(8.0, 0.5, 0.4))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 42.0, 30.0, 22.0, 0.9)

static func santo_stefano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B3533C", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F2EDE0", 2.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9B5F48", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09C", 1.9))

	# Gothic red-brick church with keel-shaped roof & sculpted Istrian portal (30 x 56 m)
	lm.box("Brick", Vector3(0.0, 9.5, 0.0), Vector3(28.0, 19.0, 54.0))
	lm.gable("Roof", Vector3(0.0, 19.0, 0.0), 28.6, 54.6, 4.4, Basis(), 0.3, "Brick")
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(0.0, 3.8, 27.1), Vector3(0, 0, 1), 3.6, 6.8, true, 0.28)
	lm.disc("Trim", Vector3(0.0, 14.5, 27.1), Vector3(0, 0, 1), 2.5, 14)
	lm.disc("Glass", Vector3(0.0, 14.5, 27.16), Vector3(0, 0, 1), 1.9, 14)
	# Famous visibly leaning (~2.0 m top horizontal tilt!) 66.0 m red-brick campanile
	LandmarkVnKit.campanile(lm, "Brick", "Trim", "Roof", "Glass", "Gold",
		Vector3(16.0, 0.0, -18.0), 7.8, 66.0, 2.0, true)
	lm.box("Lamp", Vector3(18.0, 45.2, -18.0), Vector3(4.8, 5.4, 4.8))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.6, 36.0), Vector3(0.0, 12.0, 27.0), 50.0, 0.8],
		[Vector3(26.0, 1.6, -18.0), Vector3(17.5, 42.0, -18.0), 42.0, 0.95],
	])

static func chiesa_gesuati(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1EDE2", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B86048", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9E614A", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.9))

	# Giorgio Massari's bright white Palladian church dominating the Zattere promenade (+Z)
	lm.box("Brick", Vector3(0.0, 9.2, -2.0), Vector3(28.0, 18.4, 44.0))
	lm.gable("Roof", Vector3(0.0, 18.4, -2.0), 28.6, 44.6, 3.6, Basis(), 0.25, "Brick")
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(0.0, 0.0, 20.4), Vector3.RIGHT, Vector3(0, 0, 1),
		28.4, 18.6, 18.4, 11.4, 4.6, 4)
	# Ribbed lead dome + lantern (top = 34.0 m) + twin rear small campanili
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(0.0, 18.4, -10.0), 6.2, 4.4, 6.8, 3.0, 1.4)
	for sx in [-1.0, 1.0]:
		LandmarkVnKit.campanile(lm, "Brick", "Trim", "Lead", "Glass", "Gold",
			Vector3(sx * 11.0, 0.0, -21.0), 3.6, 28.0, 0.0, false)
	lm.box("Lamp", Vector3(0.0, 7.6, 20.9), Vector3(2.4, 0.5, 0.4))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 28.0, 44.0, 34.0, 0.9)

static func squero_san_trovaso(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkVnKit.dark_wood("#5A3D28", 1.8))
	lm.use("Plank", LandmarkVnKit.dark_wood("#745238", 1.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9A5E48", 2.2))
	lm.use("Brick", LandmarkVnKit.brick("#B25A42", 2.6))
	lm.use("Gondola", LandmarkMaterials.pbr("wood", "#1A1B1E", 1.6, 0.22, 0.12))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFDD94", 1.7))

	# Iconic 17th-c. Cadore Alpine dark-timber gondola boatyard & wooden slipway sloping to Rio di San Trovaso (+Z)
	lm.box("Plank", Vector3(0.0, 0.45, 4.0), Vector3(26.0, 0.9, 14.0), Basis(Vector3.RIGHT, deg_to_rad(5.0)))
	# Dark-timber Alpine gabled workshop houses with overhanging wooden eaves & upper balcony (height 10.5 m)
	lm.box("Timber", Vector3(-4.0, 3.8, -5.5), Vector3(14.0, 7.2, 10.0))
	lm.gable("Roof", Vector3(-4.0, 7.4, -5.5), 11.8, 16.0, 3.1, Basis(Vector3.UP, PI * 0.5), 0.7, "Timber")
	lm.box("Timber", Vector3(8.5, 3.4, -5.5), Vector3(9.0, 6.4, 9.0))
	lm.gable("Roof", Vector3(8.5, 6.6, -5.5), 10.6, 10.8, 2.6, Basis(Vector3.UP, PI * 0.5), 0.6, "Timber")
	# Wooden shed portico & two black gondola hulls resting on trestles in the open yard
	lm.box("Plank", Vector3(-4.0, 3.4, 0.4), Vector3(13.6, 0.25, 2.0))
	for gx in [-6.0, 3.5]:
		lm.box("Gondola", Vector3(float(gx), 1.25, 4.5), Vector3(1.3, 0.65, 9.6))
	lm.box("Lamp", Vector3(-4.0, 4.6, -0.3), Vector3(0.4, 0.45, 0.4))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 26.0, 22.0, 10.5, 0.75)
