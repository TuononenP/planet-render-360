class_name LandmarkSgSultanLauClarke
extends RefCounted

## Kampong Glam, CBD Heritage Market & Singapore River Nightlife Icons (SG-3.14–3.16):
## - `sultan_mosque` (32 m): Twin massive golden onion domes with dark glass-bottle base bands,
##   four corner minarets with crescent finials, cream-white Indo-Saracenic walls facing Bussorah St.
## - `lau_pa_sat` (24 m, way 45098520): 1894 Victorian octagonal cast-iron filigree market,
##   central clock tower with lantern cupola, radiating pitched terracotta roof bays (fixes OSM h=0).
## - `clarke_quay` (18 m): Pastel-painted 19th-century riverfront godowns sheltered beneath
##   glowing translucent blue/white ETFE umbrella tensile canopies ("jellyfish" roofs).

static func sultan_mosque(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("limestone", "#F4EFE2", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#DFD6C2", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("BottleBand", LandmarkMaterials.glass("#1E3A2A"))
	lm.use("Glass", LandmarkMaterials.glass("#3B5C6E"))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFE29A", 2.0))

	# Main cream Indo-Saracenic prayer hall (68 x 44 m, y=0..15.5 m).
	lm.box("Cream", Vector3(0.0, 7.75, 0.0), Vector3(66.0, 15.5, 42.0))
	lm.box("Trim", Vector3(0.0, 16.1, 0.0), Vector3(68.0, 1.2, 44.0))
	# Arched entrance portico facing Bussorah St (+Z).
	LandmarkSgKit.colonnade(lm, "Cream", Vector3(-16.0, 0.0, 23.0), Vector3(16.0, 0.0, 23.0), 12.0, 0.55, 7)
	lm.box("Glass", Vector3(0.0, 7.5, 21.2), Vector3(54.0, 6.5, 0.5))

	# Twin massive golden onion domes with their famous dark-green glass-bottle base bands (32 m top).
	for dx: float in [-15.0, 15.0]:
		lm.frustum("Cream", Vector3(dx, 16.5, 0.0), 10.6, 10.0, 3.2, 20)
		lm.frustum("BottleBand", Vector3(dx, 19.6, 0.0), 10.4, 10.2, 1.5, 20)
		LandmarkAsiaSouthUtil.onion(lm, "Gold", Vector3(dx, 21.0, 0.0), 9.8, 9.2, 20)
		lm.spire("Gold", Vector3(dx, 29.8, 0.0), 0.35, 2.2, 0.06, 8)
		lm.frustum("WarmLamp", Vector3(dx, 19.4, 0.0), 10.6, 10.6, 0.45, 20)

	# Four corner minarets with onion cupolas.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var mx := sx * 31.5
			var mz := sz * 19.5
			lm.frustum("Cream", Vector3(mx, 0.0, mz), 2.3, 1.9, 24.0, 10)
			lm.frustum("Trim", Vector3(mx, 23.5, mz), 2.7, 2.7, 0.8, 10)
			LandmarkAsiaSouthUtil.onion(lm, "Gold", Vector3(mx, 24.3, mz), 2.1, 3.2, 12)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 32.0), Vector3(0.0, 24.0, 0.0), 66.0, 1.5],
		[Vector3(-15.0, 16.5, 16.0), Vector3(-15.0, 26.0, 0.0), 55.0, 1.3],
		[Vector3(15.0, 16.5, 16.0), Vector3(15.0, 26.0, 0.0), 55.0, 1.3],
	])

static func lau_pa_sat(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("limestone", "#EFECE4", 3.0))
	lm.use("Iron", LandmarkMaterials.pbr("sheet_metal", "#2D5A46", 2.0, 0.35, 0.68))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E4632", 2.0))
	lm.use("ClockLamp", LandmarkMaterials.lit("#FFF0C2", 2.2))

	# Iconic 1894 Victorian octagonal cast-iron hawker market (70 m across, way 45098520).
	lm.frustum("Cream", Vector3(0.0, 0.0, 0.0), 35.0, 35.0, 1.0, 8)
	# 8 radiating pitched market pavilion wings around the octagonal centre.
	for k in 8:
		var a := TAU * float(k) / 8.0
		var b := Basis(Vector3.UP, -a)
		var c := Vector3(cos(a) * 18.0, 0.0, sin(a) * 18.0)
		lm.box("Iron", c + Vector3(0.0, 4.5, 0.0), Vector3(28.0, 7.2, 12.0), b)
		lm.box("Roof", c + Vector3(0.0, 9.6, 0.0), Vector3(30.0, 3.2, 13.5), b)
		lm.box("WarmLamp" if false else "ClockLamp", c + Vector3(0.0, 7.6, 0.0), Vector3(24.0, 0.35, 9.0), b)
	# Central octagonal clerestory & slender Victorian clock tower (reaches 24.0 m).
	lm.frustum("Cream", Vector3(0.0, 10.5, 0.0), 11.5, 10.5, 3.5, 8)
	lm.frustum("Cream", Vector3(0.0, 14.0, 0.0), 3.6, 3.0, 6.2, 8)
	lm.frustum("ClockLamp", Vector3(0.0, 17.4, 0.0), 3.2, 3.2, 1.8, 8)
	lm.spire("Iron", Vector3(0.0, 20.2, 0.0), 3.4, 3.8, 0.15, 8)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 36.0), Vector3(0.0, 16.0, 0.0), 66.0, 1.3],
	])

static func clarke_quay(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Mint", LandmarkMaterials.pbr("concrete", "#B8DFD0", 3.0))
	lm.use("Coral", LandmarkMaterials.pbr("concrete", "#E8A698", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("concrete", "#E8CB8C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A64A32", 2.0))
	lm.use("ETFE", LandmarkMaterials.glass("#8CD2EE"))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#DCE0E4", 2.0, 0.28, 0.78))
	lm.use("CanopyLamp", LandmarkMaterials.lit("#56CCFF", 2.2))

	var pastels := ["Mint", "Coral", "Ochre"]
	# Two rows of pastel 19th-century riverfront godown warehouses framing the central mall street.
	for row: float in [-1.0, 1.0]:
		for i in 5:
			var gx := -52.0 + float(i) * 26.0
			var gz := row * 22.0
			var key: String = pastels[(i + (1 if row > 0 else 0)) % pastels.size()]
			lm.box(key, Vector3(gx, 5.5, gz), Vector3(22.0, 11.0, 16.0))
			lm.box("Roof", Vector3(gx, 12.2, gz), Vector3(23.0, 2.6, 17.0))

	# Iconic translucent blue/white ETFE "jellyfish" tensile umbrella canopies spanning the central street (18 m).
	for i in 4:
		var cx := -39.0 + float(i) * 26.0
		lm.frustum("Steel", Vector3(cx, 0.0, 0.0), 0.75, 0.55, 13.5, 8)
		LandmarkSgKit.loft_shell(lm, "ETFE", Vector3(cx, 12.2, 0.0), 13.5, 13.5, 5.8, 6, 16, 0.65)
		lm.frustum("CanopyLamp", Vector3(cx, 13.0, 0.0), 10.5, 6.0, 2.2, 12)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 3.0, 34.0), Vector3(0.0, 12.0, 0.0), 70.0, 1.3],
	])
